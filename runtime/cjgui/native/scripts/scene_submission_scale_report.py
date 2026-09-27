#!/usr/bin/env python3
"""Run the native scale probe and report non-overlapping timing percentiles.

The probe can sample three mode families:

* legacy scene mutations -- ``local_color`` / ``component_add_remove`` /
  ``reorder`` / ``image_replace`` / ``resize``;
* effect comparison -- ``no_effect`` / ``effect_static`` (identical node tree,
  only the shadow/gradient declarations differ);
* ``animation_active`` -- ``effect_static`` plus a live paint-alpha animation,
  followed by a stop-and-converge idleness record.

The modes can be selected with the same ``CJGUI_SCENE_SCALE_MODES`` environment
variable the shell runner forwards to the probe, so the legacy baseline and the
new comparison can be run and reported separately.  Samples within a group are
split into a cold prefix and a warm remainder (``CJGUI_SCENE_SUBMISSION_SCALE_COLD_SAMPLES``,
default 1) because the first scene commit carries build/layout costs the later
paint updates do not.
"""

from __future__ import annotations

import hashlib
import json
import os
import subprocess

from collections import defaultdict
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
RUNNER = ROOT / "native" / "scripts" / "verify_scene_submission_scale.sh"
DEFAULT_ARTIFACT_DIR = Path("/private/tmp/cjgui-scene-submission-scale-evidence")
SOURCES = (
    ROOT / "src" / "composable_ui_window.cj",
    ROOT / "src" / "composable_ui_animation.cj",
    ROOT / "src" / "composable_ui.cj",
    ROOT / "native" / "cjgui_internal_renderer.m",
    ROOT / "native" / "cjgui_internal_renderer.h",
    ROOT / "probe" / "scene_submission_scale_probe.cj",
)
DEFAULT_MODES = (
    "local_color",
    "component_add_remove",
    "reorder",
    "image_replace",
    "resize",
    "no_effect",
    "effect_static",
    "animation_active",
)
SIZES = (32, 256, 960)
SAMPLE_COUNT = 30
# Per-sample scalars summarised with percentiles.  ``metal_gpu_us`` is kept as a
# raw list instead: -1 means Metal gave no usable completion timestamp, and
# folding it into a percentile would invent a GPU number from a CPU-only path.
NUMERIC_FIELDS = (
    "clone_delta",
    "allocation_delta",
    "configure_us",
    "setter_us",
    "commit_us",
    "build_ms",
    "layout_ms",
    "stage_submit_ms",
    "shape_nodes",
    "shape_batches",
    "texture_draws",
    "shape_vertex_bytes",
    "vertex_stride",
    "max_shape_batch_vertex_bytes",
    "anim_bound",
    "anim_active",
)


def selected_modes() -> tuple[str, ...]:
    raw = os.environ.get("CJGUI_SCENE_SCALE_MODES")
    if raw is None:
        return DEFAULT_MODES
    return tuple(part for part in raw.split(",") if part)


def fields(line: str) -> dict[str, str]:
    return dict(piece.split("=", 1) for piece in line.split()[1:] if "=" in piece)


def as_int(row: dict[str, str], name: str, fallback: int = 0) -> int:
    try:
        return int(row.get(name, str(fallback)))
    except ValueError:
        return fallback


def percentile(values: list[int], fraction: float) -> int:
    ordered = sorted(values)
    return ordered[min(len(ordered) - 1, round((len(ordered) - 1) * fraction))]


def summary(records: list[dict[str, str]]) -> dict[str, object]:
    result: dict[str, object] = {
        "count": len(records),
        "committed_nodes": sorted({as_int(row, "committed_nodes", -1) for row in records}),
    }
    for name in NUMERIC_FIELDS:
        values = [as_int(row, name) for row in records]
        result[name] = {"p50": percentile(values, 0.50), "p95": percentile(values, 0.95), "min": min(values),
                        "max": max(values)}
    # Frame identity and the GPU-completion facts are not durations: keep the
    # raw per-sample values so an absent (-1) Metal completion stays visible
    # instead of being averaged away.
    for name in ("submitted_frame", "metal_completed"):
        result[name] = [as_int(row, name, -1) for row in records]
    result["metal_gpu_us_raw"] = [as_int(row, "metal_gpu_us", -1) for row in records]
    return result


def source_digest() -> str:
    digest = hashlib.sha256()
    for source in SOURCES:
        digest.update(source.name.encode())
        digest.update(source.read_bytes())
    return digest.hexdigest()


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def group_keys(rows: list[dict[str, str]]) -> set[tuple[str, str]]:
    return {(row.get("requested_nodes", ""), row.get("mode", "")) for row in rows}


def complete_idle(rows: list[dict[str, str]], expected: set[tuple[str, str]]) -> bool:
    return len(rows) == len(expected) and group_keys(rows) == expected and all(
        row.get("accepted") == "true" and all(as_int(row, name) == 0 for name in (
            "clone_delta", "allocation_delta", "configure_us", "setter_us", "commit_us",
            "build_delta", "layout_delta", "submit_delta",
        ))
        for row in rows
    )


def complete_recovery(rows: list[dict[str, str]], expected: set[tuple[str, str]]) -> bool:
    return len(rows) == len(expected) and group_keys(rows) == expected and all(
        row.get("forced") == "true" and row.get("failed") == "false" and
        row.get("retained") == "true" and row.get("recovered") == "true"
        for row in rows
    )


def complete_animation_stop(rows: list[dict[str, str]], expected: set[tuple[str, str]]) -> bool:
    """Stop-and-converge record: no active channel, no next animation frame, and
    no build/layout/submission/allocation delta after the channels are
    cancelled."""
    return len(rows) == len(expected) and group_keys(rows) == expected and all(
        as_int(row, "active_pre_stop") > 0 and as_int(row, "cancelled") == 1 and
        as_int(row, "active_after_cancel") == 0 and as_int(row, "advanced_return") == 0 and
        as_int(row, "active_after_advance") == 0 and row.get("accepted") == "true" and all(
            as_int(row, name) == 0 for name in (
                "clone_delta", "allocation_delta", "configure_us", "setter_us", "commit_us",
                "build_delta", "layout_delta", "submit_delta", "submitted_frame_delta",
            ))
        for row in rows
    )


def complete_text_work(rows: list[dict[str, str]], expected: set[tuple[str, str]]) -> bool:
    """Every animated frame after the first is a paint-alpha change only, so the
    text raster/upload counters must not advance; the probe reports that as
    ``text_ok=1`` per group."""
    if not expected:
        return True
    return len(rows) == len(expected) and group_keys(rows) == expected and all(
        row.get("text_ok") == "1" and as_int(row, "frames") > 0 and
        as_int(row, "raster_delta") == 0 and as_int(row, "upload_delta") == 0
        for row in rows
    )


def main() -> int:
    modes = selected_modes()
    cold_sample_count = max(1, int(os.environ.get("CJGUI_SCENE_SUBMISSION_SCALE_COLD_SAMPLES", "1")))
    artifact_dir = Path(os.environ.get("CJGUI_SCENE_SUBMISSION_SCALE_ARTIFACT_DIR", DEFAULT_ARTIFACT_DIR))
    artifact_dir.mkdir(parents=True, exist_ok=True)
    binary_dir = artifact_dir / "binary"
    source_before = source_digest()
    run_environment = os.environ.copy()
    run_environment["CJGUI_SCENE_SUBMISSION_SCALE_TMPDIR"] = str(binary_dir)
    run_environment["CJGUI_SCENE_SCALE_MODES"] = ",".join(modes)
    completed = subprocess.run(["zsh", str(RUNNER)], cwd=ROOT.parent.parent, text=True, capture_output=True,
                               check=False, env=run_environment)
    output = completed.stdout + completed.stderr
    raw_log = artifact_dir / "scene_submission_scale.raw.log"
    raw_log.write_text(output)
    source_after = source_digest()
    binary = binary_dir / "scene_submission_scale_probe"
    binary_sha256 = sha256_file(binary) if binary.is_file() else ""
    sample_rows = [fields(line) for line in output.splitlines() if line.startswith("CJGUI_SCENE_SCALE_SAMPLE ")]
    idle_rows = [fields(line) for line in output.splitlines() if line.startswith("CJGUI_SCENE_SCALE_IDLE ")]
    recovery_rows = [fields(line) for line in output.splitlines() if line.startswith("CJGUI_SCENE_SCALE_RECOVERY ")]
    animation_stop_rows = [fields(line) for line in output.splitlines()
                           if line.startswith("CJGUI_SCENE_SCALE_ANIMATION_STOP ")]
    text_work_rows = [fields(line) for line in output.splitlines()
                      if line.startswith("CJGUI_SCENE_SCALE_TEXT_WORK ")]
    grouped: dict[tuple[str, str], list[dict[str, str]]] = defaultdict(list)
    for row in sample_rows:
        grouped[(row["requested_nodes"], row["mode"])].append(row)
    expected = {(str(nodes), mode) for nodes in SIZES for mode in modes}
    all_samples_complete = len(grouped) == len(expected) and set(grouped) == expected and all(
        len(rows) == SAMPLE_COUNT for rows in grouped.values()
    )
    samples_split: dict[str, object] = {}
    for (nodes, mode), rows in sorted(grouped.items()):
        cold = rows[:cold_sample_count]
        warm = rows[cold_sample_count:]
        samples_split[f"nodes_{nodes}:{mode}"] = {
            "cold_samples": len(cold),
            "cold": summary(cold) if cold else None,
            "warm": summary(warm) if warm else None,
        }
    animation_stop_expected = {(str(nodes), "animation_active") for nodes in SIZES if "animation_active" in modes}
    text_work_expected = {(str(nodes), "animation_active") for nodes in SIZES if "animation_active" in modes}
    report = {
        "schema": "cjgui_scene_submission_scale_v2",
        "runner_exit": completed.returncode,
        "source_sha256": source_after,
        "modes": list(modes),
        "evidence": {
            "source_sha256_before": source_before,
            "source_sha256_after": source_after,
            "raw_log": str(raw_log),
            "binary": str(binary),
            "binary_sha256": binary_sha256,
        },
        "samples": {f"nodes_{nodes}:{mode}": summary(rows) for (nodes, mode), rows in sorted(grouped.items())},
        "samples_split": samples_split,
        "idle": idle_rows,
        "failure_recovery": recovery_rows,
        "animation_stop": animation_stop_rows,
        "text_work": text_work_rows,
        "completed_marker": "cjgui scene submission scale probe: passed" in output,
        "timing_boundary": "configure_us, setter_us and commit_us are independent native intervals; build_ms/layout_ms/stage_submit_ms are Cangjie wall intervals and are not summed",
        "observability_boundary": "shape_nodes/shape_batches/shape_vertex_bytes are per-frame encoder scalars for the latest submitted frame; metal_gpu_us = -1 names an unavailable Metal completion and is never derived from CPU/RSS; parsed shadows have no offscreen cache, so their cost is reported as real shape vertex/pass work",
        "coverage": {
            "expected_groups": len(expected),
            "actual_groups": len(grouped),
            "all_groups_have_30_samples": all_samples_complete,
            "idle_complete": complete_idle(idle_rows, expected),
            "recovery_complete": complete_recovery(recovery_rows, expected),
            "animation_stop_expected_groups": len(animation_stop_expected),
            "animation_stop_complete": complete_animation_stop(animation_stop_rows, animation_stop_expected)
            if animation_stop_expected else True,
            "text_work_expected_groups": len(text_work_expected),
            "text_work_complete": complete_text_work(text_work_rows, text_work_expected),
        },
    }
    print(json.dumps(report, ensure_ascii=False, sort_keys=True))
    evidence_complete = source_before == source_after and binary_sha256 != "" and raw_log.is_file()
    return 0 if completed.returncode == 0 and report["completed_marker"] and all_samples_complete and \
        report["coverage"]["idle_complete"] and report["coverage"]["recovery_complete"] and \
        report["coverage"]["animation_stop_complete"] and report["coverage"]["text_work_complete"] and \
        evidence_complete else 1


if __name__ == "__main__":
    raise SystemExit(main())

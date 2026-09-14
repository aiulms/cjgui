#!/usr/bin/env python3
"""Run the native scale probe and report non-overlapping timing percentiles."""

from __future__ import annotations

import hashlib
import json
import os
import subprocess
import sys
from collections import defaultdict
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
RUNNER = ROOT / "native" / "scripts" / "verify_scene_submission_scale.sh"
DEFAULT_ARTIFACT_DIR = Path("/private/tmp/cjgui-scene-submission-scale-evidence")
SOURCES = (
    ROOT / "src" / "composable_ui_window.cj",
    ROOT / "src" / "composable_ui.cj",
    ROOT / "native" / "cjgui_internal_renderer.m",
    ROOT / "native" / "cjgui_internal_renderer.h",
    ROOT / "probe" / "scene_submission_scale_probe.cj",
)


def fields(line: str) -> dict[str, str]:
    return dict(piece.split("=", 1) for piece in line.split()[1:] if "=" in piece)


def percentile(values: list[int], fraction: float) -> int:
    ordered = sorted(values)
    return ordered[min(len(ordered) - 1, round((len(ordered) - 1) * fraction))]


def summary(records: list[dict[str, str]]) -> dict[str, object]:
    numeric = (
        "clone_delta",
        "allocation_delta",
        "configure_us",
        "setter_us",
        "commit_us",
        "build_ms",
        "layout_ms",
        "stage_submit_ms",
    )
    result: dict[str, object] = {"count": len(records), "committed_nodes": sorted({int(row["committed_nodes"]) for row in records})}
    for name in numeric:
        values = [int(row[name]) for row in records]
        result[name] = {"p50": percentile(values, 0.50), "p95": percentile(values, 0.95), "min": min(values), "max": max(values)}
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


def complete_idle(rows: list[dict[str, str]], expected: set[tuple[str, str]]) -> bool:
    return len(rows) == len(expected) and {
        (row.get("requested_nodes", ""), row.get("mode", "")) for row in rows
    } == expected and all(
        row.get("accepted") == "true" and all(row.get(name) == "0" for name in (
            "clone_delta", "allocation_delta", "configure_us", "setter_us", "commit_us",
            "build_delta", "layout_delta", "submit_delta",
        ))
        for row in rows
    )


def complete_recovery(rows: list[dict[str, str]], expected: set[tuple[str, str]]) -> bool:
    return len(rows) == len(expected) and {
        (row.get("requested_nodes", ""), row.get("mode", "")) for row in rows
    } == expected and all(
        row.get("forced") == "true" and row.get("failed") == "false" and
        row.get("retained") == "true" and row.get("recovered") == "true"
        for row in rows
    )


def main() -> int:
    artifact_dir = Path(os.environ.get("CJGUI_SCENE_SUBMISSION_SCALE_ARTIFACT_DIR", DEFAULT_ARTIFACT_DIR))
    artifact_dir.mkdir(parents=True, exist_ok=True)
    binary_dir = artifact_dir / "binary"
    source_before = source_digest()
    run_environment = os.environ.copy()
    run_environment["CJGUI_SCENE_SUBMISSION_SCALE_TMPDIR"] = str(binary_dir)
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
    grouped: dict[tuple[str, str], list[dict[str, str]]] = defaultdict(list)
    for row in sample_rows:
        grouped[(row["requested_nodes"], row["mode"])].append(row)
    expected = {(str(nodes), mode) for nodes in (32, 256, 960) for mode in (
        "local_color", "component_add_remove", "reorder", "image_replace", "resize",
    )}
    all_samples_complete = len(grouped) == len(expected) and set(grouped) == expected and all(
        len(rows) == 30 for rows in grouped.values()
    )
    report = {
        "schema": "cjgui_scene_submission_scale_v1",
        "runner_exit": completed.returncode,
        "source_sha256": source_after,
        "evidence": {
            "source_sha256_before": source_before,
            "source_sha256_after": source_after,
            "raw_log": str(raw_log),
            "binary": str(binary),
            "binary_sha256": binary_sha256,
        },
        "samples": {f"nodes_{nodes}:{mode}": summary(rows) for (nodes, mode), rows in sorted(grouped.items())},
        "idle": idle_rows,
        "failure_recovery": recovery_rows,
        "completed_marker": "cjgui scene submission scale probe: passed" in output,
        "timing_boundary": "configure_us, setter_us and commit_us are independent native intervals; build_ms/layout_ms/stage_submit_ms are Cangjie wall intervals and are not summed",
        "coverage": {
            "expected_groups": len(expected),
            "actual_groups": len(grouped),
            "all_groups_have_30_samples": all_samples_complete,
            "idle_complete": complete_idle(idle_rows, expected),
            "recovery_complete": complete_recovery(recovery_rows, expected),
        },
    }
    print(json.dumps(report, ensure_ascii=False, sort_keys=True))
    evidence_complete = source_before == source_after and binary_sha256 != "" and raw_log.is_file()
    return 0 if completed.returncode == 0 and report["completed_marker"] and all_samples_complete and \
        report["coverage"]["idle_complete"] and report["coverage"]["recovery_complete"] and evidence_complete else 1


if __name__ == "__main__":
    raise SystemExit(main())

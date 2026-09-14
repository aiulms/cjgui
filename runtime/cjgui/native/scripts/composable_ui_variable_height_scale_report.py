#!/usr/bin/env python3
"""Run the variable-height scale probe and emit evidence-backed percentiles."""

from __future__ import annotations

import hashlib
import json
import os
import subprocess
import sys
from collections import defaultdict
from pathlib import Path


RUNTIME = Path(__file__).resolve().parents[2]
ROOT = RUNTIME.parent.parent
RUNNER = RUNTIME / "native" / "scripts" / "verify_composable_ui_variable_height_scale.sh"
DEFAULT_ARTIFACT_DIR = Path("/private/tmp/cjgui-variable-height-scale-evidence")
SOURCES = (
    RUNTIME / "src" / "composable_ui.cj",
    RUNTIME / "probe" / "composable_ui_variable_height_scale_probe.cj",
    RUNNER,
)
EXPECTED = {(count, kind) for count in (1000, 10000) for kind in (
    "cold_startup", "warm_back_and_forth", "single_row_change", "screen_off_batch", "width_invalidation",
)}


def digest_sources() -> str:
    digest = hashlib.sha256()
    for path in SOURCES:
        digest.update(path.name.encode())
        digest.update(path.read_bytes())
    return digest.hexdigest()


def digest_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for block in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def fields(line: str) -> dict[str, str]:
    return dict(piece.split("=", 1) for piece in line.split()[1:] if "=" in piece)


def percentile(values: list[int], fraction: float) -> int:
    ordered = sorted(values)
    return ordered[min(len(ordered) - 1, round((len(ordered) - 1) * fraction))]


def stats(rows: list[dict[str, str]]) -> dict[str, object]:
    result: dict[str, object] = {"count": len(rows)}
    for name in ("setup_ms", "elapsed_ms", "item_reads", "row_builds", "measurements", "materialized", "scene_nodes"):
        values = [int(row[name]) for row in rows]
        result[name] = {"p50": percentile(values, 0.50), "p95": percentile(values, 0.95), "max": max(values)}
    return result


def main() -> int:
    artifact_dir = Path(os.environ.get("CJGUI_VARIABLE_HEIGHT_SCALE_ARTIFACT_DIR", DEFAULT_ARTIFACT_DIR))
    artifact_dir.mkdir(parents=True, exist_ok=True)
    binary_dir = artifact_dir / "binary"
    before = digest_sources()
    env = os.environ.copy()
    env["CJGUI_VARIABLE_HEIGHT_SCALE_TMPDIR"] = str(binary_dir)
    completed = subprocess.run(["zsh", str(RUNNER)], cwd=ROOT, env=env, text=True, capture_output=True, check=False)
    output = completed.stdout + completed.stderr
    raw = artifact_dir / "variable_height_scale.raw.log"
    raw.write_text(output)
    after = digest_sources()
    binary = binary_dir / "composable_ui_variable_height_scale_probe"
    rows = [fields(line) for line in output.splitlines() if line.startswith("CJGUI_VARIABLE_HEIGHT_SAMPLE ")]
    groups: dict[tuple[int, str], list[dict[str, str]]] = defaultdict(list)
    for row in rows:
        groups[(int(row["count"]), row["kind"])].append(row)
    samples_complete = set(groups) == EXPECTED and all(len(group) == 30 for group in groups.values())
    bounded = samples_complete and all(
        int(row["row_builds"]) <= 128 and int(row["measurements"]) <= 512 and
        int(row["materialized"]) <= 128 and int(row["scene_nodes"]) <= 1024
        for row in rows
    )
    report = {
        "schema": "cjgui_variable_height_scale_v1",
        "runner_exit": completed.returncode,
        "source_sha256": after,
        "evidence": {
            "source_sha256_before": before,
            "source_sha256_after": after,
            "raw_log": str(raw),
            "binary": str(binary),
            "binary_sha256": digest_file(binary) if binary.is_file() else "",
        },
        "samples": {f"rows_{count}:{kind}": stats(group) for (count, kind), group in sorted(groups.items())},
        "coverage": {
            "expected_groups": len(EXPECTED),
            "actual_groups": len(groups),
            "samples_per_group": 30,
            "all_groups_have_30_samples": samples_complete,
            "bounded_materialization_and_measurement": bounded,
        },
        "timing_boundary": "elapsed_ms measures this platform-free layout probe only; setup_ms is separately reported source key-index construction, and it does not establish GUI, renderer, provider, or human-perception latency.",
    }
    print(json.dumps(report, ensure_ascii=False, sort_keys=True))
    return 0 if completed.returncode == 0 and "composable variable-height scale probe: passed" in output and \
        before == after and report["evidence"]["binary_sha256"] and samples_complete and bounded else 1


if __name__ == "__main__":
    raise SystemExit(main())

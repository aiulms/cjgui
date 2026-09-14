#!/usr/bin/env python3
"""Report same-process, interleaved incremental-layout work and timings.

The probe emits one record for each condition/mode/sample pair from a single
process. It uses Cangjie's MonoTime around construction and layout separately;
process startup, validation, and printing are outside the timed region.
Counters are retained per sample so a cache hit cannot be reported as zero
work, and optional signature counters remain forward-compatible with the
production metrics contract.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import math
import subprocess
from pathlib import Path
from typing import Any


MODES = ("canonical_no_cache", "default_signature", "opt_in_reuse")
CONDITIONS = ("warm", "local", "resize", "font", "scroll", "full_invalidation")
ROW_COUNTS = (24, 248, 760)
REQUIRED_METRICS = (
    "build_ns", "layout_ns", "total_ns",
    "nodes", "recursive_nodes", "vertical_solves", "horizontal_solves", "layer_solves", "scroll_solves",
    "measurement_requests", "measurer_calls", "measurement_hits", "region_hits", "region_misses",
    "revalidation_nodes", "replayed_nodes", "cache_entries",
    "retained_nodes", "retained_string_bytes", "retained_bytes",
    "pending_nodes", "pending_string_bytes", "pending_bytes", "budget_skips",
)
OPTIONAL_METRICS = (
    "signature_access_count", "signature_byte_count", "signature_accesses", "signature_bytes",
)


def require(condition: bool, message: str) -> None:
    if not condition:
        raise RuntimeError(message)


def percentile(values: list[int], fraction: float) -> int:
    ordered = sorted(values)
    require(bool(ordered), "cannot calculate percentile of no samples")
    return ordered[max(0, math.ceil(len(ordered) * fraction) - 1)]


def parse_records(output: str, samples: int) -> dict[tuple[str, int, str], list[dict[str, int]]]:
    records: dict[tuple[str, int, str], list[dict[str, int]]] = {}
    order: dict[tuple[int, str, int], list[str]] = {}
    lines = [line for line in output.splitlines() if line.startswith("CJGUI_INCREMENTAL_LAYOUT_BENCHMARK_SAMPLE ")]
    expected = samples * len(CONDITIONS) * len(ROW_COUNTS) * len(MODES)
    require(len(lines) == expected, f"expected {expected} benchmark records, got {len(lines)}")
    for line in lines:
        fields = dict(token.split("=", 1) for token in line.split()[1:] if "=" in token)
        try:
            sample = int(fields.pop("sample"))
            rows = int(fields.pop("rows"))
            mode = fields.pop("mode")
            condition = fields.pop("condition")
            metrics = {name: int(value) for name, value in fields.items()}
        except (KeyError, ValueError) as error:
            raise RuntimeError(f"invalid benchmark sample: {line!r}") from error
        require(0 <= sample < samples, f"sample index out of range: {sample}")
        require(mode in MODES, f"unexpected benchmark mode: {mode!r}")
        require(condition in CONDITIONS, f"unexpected benchmark condition: {condition!r}")
        require(rows in ROW_COUNTS, f"unexpected benchmark row count: {rows}")
        for name in REQUIRED_METRICS:
            require(name in metrics, f"benchmark sample omitted required metric {name}")
        for name, value in metrics.items():
            require(value >= 0, f"benchmark metric {name} is negative")
        key = (condition, rows, mode)
        records.setdefault(key, []).append({name: metrics[name] for name in REQUIRED_METRICS} | {
            name: metrics[name] for name in OPTIONAL_METRICS if name in metrics
        })
        order.setdefault((sample, condition, rows), []).append(mode)

    expected_keys = {(condition, rows, mode) for condition in CONDITIONS for rows in ROW_COUNTS for mode in MODES}
    require(set(records) == expected_keys, "benchmark condition/mode matrix is incomplete")
    for key, values in records.items():
        require(len(values) == samples, f"{key} has {len(values)} samples, expected {samples}")
    for sample in range(samples):
        for condition in CONDITIONS:
            for rows in ROW_COUNTS:
                sequence = order.get((sample, condition, rows), [])
                expected_sequences = (
                    ["canonical_no_cache", "default_signature", "opt_in_reuse"],
                    ["opt_in_reuse", "canonical_no_cache", "default_signature"],
                    ["default_signature", "opt_in_reuse", "canonical_no_cache"],
                )
                expected_sequence = expected_sequences[sample % 3]
                require(sequence == expected_sequence,
                        f"modes are not interleaved for sample={sample} condition={condition} rows={rows}: {sequence}")
    return records


def summarize(values: list[dict[str, int]], metric: str) -> dict[str, Any]:
    observed = [sample[metric] for sample in values if metric in sample]
    if not observed:
        return {"availability": "not_reported"}
    return {
        "availability": "reported", "p50": percentile(observed, 0.50), "p95": percentile(observed, 0.95),
        "min": min(observed), "max": max(observed), "samples": observed,
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--binary", type=Path, required=True)
    parser.add_argument("--samples", type=int, default=30)
    parser.add_argument("--output", type=Path, required=True)
    arguments = parser.parse_args()
    require(arguments.samples >= 30, "at least 30 valid samples are required")
    binary = arguments.binary.resolve()
    require(binary.is_file(), f"missing binary: {binary}")

    completed = subprocess.run([str(binary), "--incremental-layout-benchmark"], text=True, capture_output=True, check=False)
    require(completed.returncode == 0,
            f"benchmark exited {completed.returncode}: {completed.stderr[-2000:]}")
    marker = f"CJGUI_INCREMENTAL_LAYOUT_BENCHMARK_TOTAL samples={arguments.samples} conditions=18 modes=3 samples_per_condition_mode={arguments.samples} records={arguments.samples * 54}"
    require(marker in completed.stdout, "benchmark omitted same-process total marker")
    records = parse_records(completed.stdout, arguments.samples)

    conditions: dict[str, Any] = {}
    for condition in CONDITIONS:
        for rows in ROW_COUNTS:
            key = f"{condition}:rows={rows}"
            conditions[key] = {
                "condition": condition, "rows": rows,
                "modes": {
                    mode: {
                        "samples": records[(condition, rows, mode)],
                        "metrics": {
                            metric: summarize(records[(condition, rows, mode)], metric)
                            for metric in REQUIRED_METRICS + OPTIONAL_METRICS
                        },
                    } for mode in MODES
                },
            }

    report = {
        "schema": "cjgui_incremental_layout_reuse_v4",
        "binary": str(binary),
        "binary_sha256": hashlib.sha256(binary.read_bytes()).hexdigest(),
        "sampling": {
            "same_process": True, "interleaved_modes": True,
            "valid_samples_per_condition_mode": arguments.samples,
            "conditions": list(CONDITIONS), "row_counts": list(ROW_COUNTS), "modes": list(MODES),
            "policies": {
                "canonical_no_cache": "cross-pass reuse cache disabled; reuseMeasurements remains enabled",
                "default_signature": "diagnostic structural signatures explicitly enabled",
                "opt_in_reuse": "production default; explicit layoutReuseKey required",
            },
            "timer": "Cangjie MonoTime nanosecond deltas around build and layout; process startup, validation, and printing excluded",
        },
        "conditions": conditions,
        "scope": {
            "includes": "component construction and canonical Cangjie layout timings plus layout work counters",
            "excludes": "process startup timing, native scene COW, FFI node writes, Metal submit and human-visible presentation",
            "limitations": "nanosecond counter resolution is not a latency guarantee; this is an in-process microbenchmark and reports p50/p95 without claiming a target speedup",
            "optional_metrics": "signature counters are reported when supplied by the production metrics API; missing fields stay not_reported",
        },
    }
    arguments.output.parent.mkdir(parents=True, exist_ok=True)
    arguments.output.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"report": str(arguments.output), "binary_sha256": report["binary_sha256"],
                      "same_process": True, "valid_samples_per_condition_mode": arguments.samples}, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, RuntimeError, ValueError, subprocess.SubprocessError) as error:
        print(f"incremental layout reuse report failed: {error}")
        raise SystemExit(1)

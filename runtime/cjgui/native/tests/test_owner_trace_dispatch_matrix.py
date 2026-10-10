#!/usr/bin/env python3
"""Assertions for real native dispatch attribution in the normal-macro fixture."""
from __future__ import annotations

import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[4] /
                       "artifacts/e-macos-large-visual-20261002/tools"))
from parse_owner_turn_trace import summarize


def check(mode: str, path: Path) -> None:
    raw = path.read_text(encoding="utf-8", errors="strict")
    summary = summarize(raw)
    assert "fixture_status workload=0 timing=0 measure=0 multiline=0 matrix=complete" in raw, raw[-2000:]
    assert len(summary["turns"]) == 1 and summary["turns"][0]["complete"], summary["turns"]
    dispatches = summary["dispatches"]
    assert len(dispatches) >= 20, dispatches
    assert all(row["complete"] for row in dispatches), dispatches
    assert all(row["dispatch_submit_tid"] != row["main_enter_tid"] and
               row["main_enter_tid"] == row["main_exit_tid"] and
               row["dispatch_submit_tid"] == row["owner_return_tid"] for row in dispatches), dispatches
    phases = [int(match.group(1)) for match in re.finditer(
        r"kind=dispatch_submit\b[^\n]*\bphase_id=(\d+)", raw)]
    expected_prefix = [37, 38, 39, 40]
    expected_native = [41, 42, 43, 44, 45, 46, 47, 48, 49, 51, 52, 53, 54, 55, 56, 57, 58, 59]
    if "fixture_position_sync named=1" in raw:
        assert phases[0] == 156, phases
        phases = phases[1:]
    if "fixture_diagnostic_getters " in raw:
        assert phases[:3] == [75, 76, 77], phases
        phases = phases[3:]
    if "fixture_input_sync named=5" in raw:
        assert phases[:5] == [113, 114, 115, 116, 117], phases
        phases = phases[5:]
    assert phases[:4] == expected_prefix, phases
    assert phases[4:] == expected_native + [166, 163], phases
    destroy = [row for row in dispatches if row["phase_id"] == 163]
    assert len(destroy) == 1 and destroy[0]["complete"] and destroy[0]["exact_call_identity_known"], destroy
    assert destroy[0]["request_generation_matches_main_entry"] is True, destroy
    assert destroy[0]["main_exit_live_generation"] == "unknown" and \
           destroy[0]["owner_return_live_generation"] == "unknown", destroy
    rejected_close = [row for row in dispatches if row["phase_id"] == 166]
    assert len(rejected_close) == 1 and rejected_close[0]["request_generation"] == "unknown" and \
           rejected_close[0]["request_generation_matches_main_entry"] == "unknown", rejected_close
    assert all(row["exact_call_identity_known"] for row in dispatches), dispatches
    assert all(isinstance(row["main_service_ns"], int) and
               isinstance(row["main_service_cpu_ns"], int) for row in dispatches), dispatches
    if mode == "blocked":
        assert dispatches[0]["queue_wait_ns"] >= 35_000_000, dispatches[0]
        assert dispatches[0]["main_service_ns"] < dispatches[0]["queue_wait_ns"], dispatches[0]
        assert summary["turns"][0]["work_wall_ns"] >= 45_000_000, summary["turns"][0]
    elif mode == "idle":
        # The real AppKit startup/control path can itself enqueue unrelated
        # work before the first query. It remains decisively below the 50 ms
        # injected blocker and is retained as measured queue time.
        assert max(row["queue_wait_ns"] for row in dispatches) < 35_000_000, dispatches
    else:
        raise AssertionError(f"unknown mode: {mode}")


if __name__ == "__main__":
    if len(sys.argv) != 3:
        raise SystemExit("usage: test_owner_trace_dispatch_matrix.py MODE TRACE")
    check(sys.argv[1], Path(sys.argv[2]))

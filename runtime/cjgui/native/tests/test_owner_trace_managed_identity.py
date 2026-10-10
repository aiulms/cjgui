#!/usr/bin/env python3
"""Verify managed-ID sideband, unknown native identity, and EndWatch retirement."""
from __future__ import annotations

import re
import sys
from pathlib import Path


def main(path: Path) -> None:
    raw = path.read_text(encoding="utf-8", errors="strict")
    records = [line for line in raw.splitlines() if line.startswith("CJGUI_OWNER_TRACE v=1 seq=")]
    assert "fixture managed_sideband_id=424242 watch_count_before=0 watch_count_after=0" in raw
    assert any("phase=build_diag_format" in line and "managed_tid=424242" in line for line in records)
    assert any("phase=build_diag_format" in line and "managed_tid=0" in line for line in records)
    assert any("phase=build_diag_write" in line and "managed_tid=unknown" in line for line in records)
    assert "end_returned_before_sampling_release=1" in raw
    assert not any("phase=trace_watch_reclaim" in line and "dispatch=900 " in line for line in records)
    retired = [line for line in records if "phase=trace_watch_retire" in line]
    tails = [line for line in records if "phase=trace_watch_tail" in line]
    assert retired and tails

    registration = [line for line in records if "phase=trace_watch_register" in line]
    register_begin = [line for line in registration if "kind=phase_begin" in line]
    register_end = [line for line in registration if "kind=phase_end" in line]
    assert len(register_begin) == 1 and len(register_end) == 1, registration
    for line in registration:
        assert "session=77" in line and "turn=123" in line and "request=456" in line
        assert "generation=8" in line and "managed_tid=424242" in line
        assert re.search(r"tid=[1-9][0-9]*", line), line
    start = re.search(r"\bmono_ns=(\d+)", register_begin[0])
    end = re.search(r"\bmono_ns=(\d+)", register_end[0])
    assert start and end and int(end.group(1)) - int(start.group(1)) >= 10_000_000, registration
    cleanup = [line for line in records if "phase=trace_watch_cleanup" in line]
    assert len([line for line in cleanup if "kind=phase_begin" in line]) == 2, cleanup
    assert len([line for line in cleanup if "kind=phase_end" in line]) == 2, cleanup


if __name__ == "__main__":
    if len(sys.argv) != 2:
        raise SystemExit("usage: test_owner_trace_managed_identity.py TRACE")
    main(Path(sys.argv[1]))

#!/usr/bin/env python3
"""Actual socket acceptance for the reusable shared-document core consumer."""

from __future__ import annotations

import os
import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parent
CORE = ROOT.parents[1] / "shared_operation_core"
CLIENT = CORE / "client.py"
CONSUMER = ROOT / "target/release/bin/main"
PRIMARY = 8101
ARCHIVE = 8199


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def main() -> int:
    require(CONSUMER.exists(), "build shared-document second consumer before acceptance")
    environment = dict(os.environ)
    runtime = Path(environment.get("CANGJIE_HOME", "/Users/jiangxuanyang/cangjie-toolchains/cangjie")) / "runtime/lib/darwin_aarch64_cjnative"
    require(runtime.exists(), "Cangjie runtime is unavailable")
    environment["DYLD_LIBRARY_PATH"] = f"{runtime}:{environment['DYLD_LIBRARY_PATH']}" if environment.get("DYLD_LIBRARY_PATH") else str(runtime)
    process = subprocess.Popen(
        # `describe` only reads the descriptor. The five protocol exchanges
        # below are get, authorized read, replacement, stale replacement, and
        # denied read.
        [str(CONSUMER), "--max-clients", "5"], cwd=ROOT, env=environment,
        text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
    )
    assert process.stdout is not None
    ready = process.stdout.readline().strip()
    prefix = "CJGUI_SHARED_DOCUMENT_READY DESCRIPTOR_PATH "
    require(ready.startswith(prefix), f"consumer was not ready: {ready!r}")
    descriptor = Path(ready[len(prefix) :])
    require(descriptor.exists(), "consumer did not issue a descriptor")

    def client(*args: str, expected_codes: tuple[int, ...] = (0,)) -> str:
        completed = subprocess.run([sys.executable, str(CLIENT), str(descriptor), *args], text=True, capture_output=True, check=False)
        require(completed.returncode in expected_codes,
                f"generic client returned {completed.returncode}, expected {expected_codes}: {completed.stderr}")
        return completed.stdout

    try:
        description = client("describe")
        require("ACTION READ_RANGE PARAMETERS 3 TARGETS 1 1" in description, "range read was not discovered")
        require("ACTION UNDO" not in description, "human-only history leaked to external discovery")
        initial = client("get")
        require("RESOURCE 8101" in initial and "RESOURCE 8199" in initial, "document resource discovery was incomplete")
        require("FIELD 8101 positionUnit STRING 9 555446385F42595445" in initial, "UTF-8 byte position unit was not declared")
        require("CONTENT_UTF8_HEX" not in initial, "full document content leaked from context")
        range_before = client("read-range", str(PRIMARY), "0", "3", "0")
        require("AVAILABLE true" in range_before and "CONTENT_UTF8_HEX 3 E7ACAC" in range_before, "bounded initial range read failed")
        applied = client("invoke", "0", "REPLACE_RANGE", "--target", str(PRIMARY), "--arg", "start=INTEGER:0", "--arg", "end=INTEGER:3", "--arg", "text=STRING:外部")
        require("APPLIED true" in applied and "VERSION_AFTER 1" in applied, "versioned external replacement did not apply")
        stale = client("invoke", "0", "REPLACE_RANGE", "--target", str(PRIMARY), "--arg", "start=INTEGER:0", "--arg", "end=INTEGER:6", "--arg", "text=STRING:过期", expected_codes=(4,))
        require("CONFLICT true" in stale and "VERSION_AFTER 1" in stale, "stale replacement did not fail closed")
        denied = client("read-range", str(ARCHIVE), "0", "3", "0", expected_codes=(5,))
        require("ERROR unauthorized_resource" in denied, "read-only archive leaked through range scope")
        require(process.wait(timeout=5) == 0, "consumer did not exit after the expected clients")
    finally:
        if process.poll() is None:
            process.terminate()
            process.wait(timeout=5)
    require(not descriptor.exists(), "descriptor survived consumer cleanup")
    print("shared_document_second_consumer acceptance passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

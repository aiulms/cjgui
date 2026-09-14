#!/usr/bin/env python3
"""Independent public-consumer acceptance for the multi-record rule-set domain."""

from __future__ import annotations

import os
import re
import stat
import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parent
CORE = ROOT.parents[1] / "shared_operation_core"
CLIENT = CORE / "client.py"
CONSUMER = ROOT / "target/release/bin/main"
CAPABILITY = "rule-set-second-consumer-acceptance"
RULE_SET_ID = 8000


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def launch(max_clients: int) -> tuple[subprocess.Popen[str], Path]:
    environment = dict(os.environ)
    environment["CJGUI_RULE_SET_SECOND_CONSUMER_CAPABILITY"] = CAPABILITY
    runtime = Path(environment.get("CANGJIE_HOME", "/Users/jiangxuanyang/cangjie-toolchains/cangjie")) / "runtime/lib/darwin_aarch64_cjnative"
    environment["DYLD_LIBRARY_PATH"] = f"{runtime}:{environment['DYLD_LIBRARY_PATH']}" if environment.get("DYLD_LIBRARY_PATH") else str(runtime)
    process = subprocess.Popen([str(CONSUMER), "--max-clients", str(max_clients)], cwd=ROOT, env=environment, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    assert process.stdout is not None
    ready = process.stdout.readline().strip()
    prefix = "CJGUI_RULE_SET_READY_V1 DESCRIPTOR_PATH_UTF8_HEX "
    require(ready.startswith(prefix), f"consumer was not ready: {ready!r}")
    size, encoded = ready[len(prefix):].split(" ", 1)
    descriptor = Path(bytes.fromhex(encoded).decode("utf-8"))
    require(len(str(descriptor).encode("utf-8")) == int(size), "descriptor byte count mismatch")
    require(stat.S_IMODE(descriptor.stat().st_mode) == 0o600, "descriptor is not private")
    return process, descriptor


def client(descriptor: Path, *args: str) -> str:
    complete = subprocess.run([sys.executable, str(CLIENT), str(descriptor), *args], text=True, capture_output=True, check=False)
    require(complete.returncode == 0, f"client failed: {complete.stderr}")
    return complete.stdout


def main() -> int:
    require(CONSUMER.exists(), "build rule-set second consumer before acceptance")
    process, descriptor = launch(6)
    try:
        description = client(descriptor, "describe")
        require("ACTION GET_CHANGES" in description and "ACTION CREATE_RECORD PARAMETERS 5 TARGETS 1 1" in description, "descriptor does not expose the independent rule-set contract")
        initial = client(descriptor, "get")
        require("VERSION 0" in initial and "RESOURCE 8000" in initial, "initial rule-set context missing")
        require("WINDOW_PROJECTION NONE" in initial and "rule-set-root" not in initial,
                "headless rule-set consumer invented a window projection")
        created = client(descriptor, "invoke", "0", "CREATE_RECORD", "--target", str(RULE_SET_ID), "--arg", "label=STRING:独立消费者规则", "--arg", "enabled=BOOLEAN:true", "--arg", "retentionCount=INTEGER:21", "--arg", "excludedType=STRING:logs", "--arg", "requestId=STRING:consumer-create-1")
        require("APPLIED true" in created and "VERSION_AFTER 1" in created, "record creation did not use public action contract")
        snapshot = client(descriptor, "get")
        record_match = re.search(r"RESOURCE (\d+) \d+ [0-9A-F]+ 6\n", snapshot)
        require(record_match is not None and int(record_match.group(1)) != RULE_SET_ID, "new stable record ID was not discoverable")
        record_id = record_match.group(1)
        require(f"RELATION selection currentRule SELECTS resource rule{record_id}" in snapshot and
                f"RELATION resource rule{record_id} HAS draft selectedRuleDraft" in snapshot,
                "current selected record was not connected to its actual draft relationship")
        edited = client(descriptor, "invoke", "1", "EDIT_DRAFT_TEXT", "--target", record_id, "--arg", "fieldId=STRING:retentionCount", "--arg", "text=STRING:30", "--arg", "expectedDraftVersion=INTEGER:0")
        require("APPLIED true" in edited and "VERSION_AFTER 2" in edited, "draft edit failed")
        applied = client(descriptor, "invoke", "2", "APPLY_DRAFT", "--target", record_id, "--arg", "expectedDraftVersion=INTEGER:1")
        require("APPLIED true" in applied and "VERSION_AFTER 3" in applied, "draft application failed")
        changes = client(descriptor, "changes", "0")
        require("KIND CHANGES" in changes and "RESYNC_REQUIRED false" in changes and "CHANGES 2" in changes, "incremental changes did not expose content commits")
        require(process.wait(timeout=5) == 0, f"consumer exited {process.returncode}: {process.stderr.read() if process.stderr else ''}")
    finally:
        if process.poll() is None:
            process.terminate(); process.wait(timeout=5)
        require(not descriptor.exists(), "descriptor survived consumer shutdown")
    print("rule_set_second_consumer acceptance passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

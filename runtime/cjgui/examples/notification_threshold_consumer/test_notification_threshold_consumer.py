#!/usr/bin/env python3
"""Acceptance for a public-core consumer with notification, not rule-set, fields."""

from __future__ import annotations

import os
import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parent
CLIENT = ROOT.parents[1] / "shared_operation_core" / "client.py"
CONSUMER = ROOT / "target/release/bin/main"


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def main() -> int:
    require(CONSUMER.exists(), "build notification-threshold consumer before acceptance")
    environment = dict(os.environ)
    environment["CJGUI_NOTIFICATION_CONSUMER_CAPABILITY"] = "notification-consumer-acceptance"
    runtime = Path(environment.get("CANGJIE_HOME", "/Users/jiangxuanyang/cangjie-toolchains/cangjie")) / "runtime/lib/darwin_aarch64_cjnative"
    environment["DYLD_LIBRARY_PATH"] = f"{runtime}:{environment['DYLD_LIBRARY_PATH']}" if environment.get("DYLD_LIBRARY_PATH") else str(runtime)
    process = subprocess.Popen([str(CONSUMER), "--max-clients", "8"], cwd=ROOT, env=environment, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    assert process.stdout is not None
    descriptor = Path(process.stdout.readline().strip())
    require(descriptor.exists(), "consumer did not issue a private descriptor")

    def client(*args: str) -> str:
        completed = subprocess.run([sys.executable, str(CLIENT), str(descriptor), *args], text=True, capture_output=True, check=False)
        require(completed.returncode == 0, f"generic client failed: {completed.stderr}")
        return completed.stdout

    try:
        description = client("describe")
        require("ACTION EDIT_DRAFT_TEXT" in description and "ACTION APPLY_DRAFT" in description,
                "notification shared-draft actions were not discovered from the public descriptor")
        before = client("get")
        require("RESOURCE 9100" in before and "draftChannel" in before and "VERSION 0" in before, "notification context omitted shared draft")
        require("WINDOW_PROJECTION NONE" in before and "notification-root" not in before,
                "headless notification consumer invented a window projection")
        drafted = client("invoke", "0", "EDIT_DRAFT_TEXT", "--target", "9100", "--arg", "fieldId=STRING:deliveryChannel", "--arg", "text=STRING:短信", "--arg", "expectedDraftVersion=INTEGER:0")
        require("APPLIED true" in drafted and "VERSION_AFTER 1" in drafted, "external draft edit did not apply")
        draft_context = client("get")
        require("FIELD 9100 draftChannel STRING" in draft_context and "FIELD 9100 baseAppliedVersion INTEGER 0" in draft_context,
                "external reader cannot see the current notification draft and baseline")
        configured = client("invoke", "1", "CONFIGURE_NOTIFICATION_THRESHOLD", "--target", "9100", "--arg", "channel=STRING:邮件", "--arg", "threshold=INTEGER:85", "--arg", "enabled=BOOLEAN:true")
        require("APPLIED true" in configured and "VERSION_AFTER 2" in configured, "independent notification action did not apply")
        stale_apply = client("invoke", "2", "APPLY_DRAFT", "--target", "9100", "--arg", "expectedDraftVersion=INTEGER:1")
        require("APPLIED false" in stale_apply and "stale_draft" in stale_apply, "external applied config silently overwrote a stale human/external draft")
        invalid = client("invoke", "2", "CONFIGURE_NOTIFICATION_THRESHOLD", "--target", "9100", "--arg", "channel=STRING:短信", "--arg", "threshold=INTEGER:101", "--arg", "enabled=BOOLEAN:true")
        require("APPLIED false" in invalid and "threshold_out_of_range" in invalid, "notification constraint was not enforced")
        changes = client("changes", "0")
        require("KIND CHANGES" in changes and "STREAM_ID notification_stream_" in changes and "CHANGES 2" in changes, "notification change stream did not use the public incremental contract")
        stale = client("changes", "2", "--stream-id", "other_stream")
        require("RESYNC_REQUIRED true" in stale, "foreign stream identity did not require resync")
        require(process.wait(timeout=5) == 0, "consumer did not exit after the expected clients")
    finally:
        if process.poll() is None:
            process.terminate()
            process.wait(timeout=5)
    require(not descriptor.exists(), "descriptor survived notification consumer shutdown")
    print("notification threshold consumer acceptance passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

#!/usr/bin/env python3
"""Two-process acceptance for the shared backup-rule editable form domain."""
from __future__ import annotations

import os
import re
import stat
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
CONSUMER = Path(__file__).resolve().parent / "target/release/bin/main"
CLIENT = ROOT / "shared_operation_core/client.py"
CAPABILITY = "backup-rule-form-acceptance-capability"
CONFIG, LABEL, ENABLED, RETENTION = 4201, 42011, 42012, 42013


def require(value: bool, message: str) -> None:
    if not value:
        raise AssertionError(message)


def ready_process(max_clients: int, grants_apply: bool) -> tuple[subprocess.Popen[str], Path]:
    env = dict(os.environ)
    env["CJGUI_BACKUP_RULE_CAPABILITY"] = CAPABILITY
    runtime = Path(env.get("CANGJIE_HOME", "/Users/jiangxuanyang/cangjie-toolchains/cangjie")) / "runtime/lib/darwin_aarch64_cjnative"
    env["DYLD_LIBRARY_PATH"] = f"{runtime}:{env.get('DYLD_LIBRARY_PATH', '')}".rstrip(":")
    args = [str(CONSUMER), "--human-label", "应用侧确认", "--max-clients", str(max_clients)]
    if grants_apply:
        args.append("--grant-apply")
    process = subprocess.Popen(args, cwd=CONSUMER.parents[3], env=env, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    assert process.stdout
    line = process.stdout.readline().strip()
    prefix = "CJGUI_BACKUP_RULE_READY DESCRIPTOR_PATH_UTF8_HEX "
    require(line.startswith(prefix), f"consumer did not become ready: {line!r}")
    byte_count, encoded = line[len(prefix):].split(" ", 1)
    descriptor = Path(bytes.fromhex(encoded).decode())
    require(len(str(descriptor).encode()) == int(byte_count), "descriptor byte count mismatch")
    require(stat.S_IMODE(descriptor.stat().st_mode) == 0o600, "descriptor is not 0600")
    return process, descriptor


def client(descriptor: Path, *args: str) -> str:
    result = subprocess.run([sys.executable, str(CLIENT), str(descriptor), *args], text=True, capture_output=True, check=False)
    require(result.returncode == 0, f"generic client failed: {result.stderr}")
    return result.stdout


def version(snapshot: str) -> int:
    match = re.search(r"^VERSION (\d+)$", snapshot, re.M)
    require(match is not None, "snapshot lacks version")
    return int(match.group(1))


def integer_field(snapshot: str, resource: int, name: str) -> int:
    match = re.search(rf"^FIELD {resource} {re.escape(name)} INTEGER (-?\d+)$", snapshot, re.M)
    require(match is not None, f"missing integer field {resource}/{name}")
    return int(match.group(1))


def wait_ok(process: subprocess.Popen[str]) -> None:
    code = process.wait(timeout=5)
    require(code == 0, f"consumer exited {code}: {process.stderr.read() if process.stderr else ''}")


def main() -> int:
    require(CONSUMER.exists(), "run build.sh before acceptance")
    writer, writer_descriptor = ready_process(9, True)
    reader, reader_descriptor = ready_process(2, False)
    try:
        reader_description = client(reader_descriptor, "describe")
        require("ACTION EDIT_DRAFT_TEXT PARAMETERS 2 TARGETS 1 1" in reader_description, "form action is not discoverable")
        require("ACTION APPLY_DRAFT" not in reader_description, "apply leaked into non-applying descriptor")
        reader_snapshot = client(reader_descriptor, "get", "--target", str(LABEL))
        require("FIELD 42011 appliedValue STRING" in reader_snapshot, "field-level projection missing")
        denied_apply = client(reader_descriptor, "invoke", "1", "APPLY_DRAFT", "--target", str(CONFIG), "--arg", "expectedDraftVersion=INTEGER:0", "--arg", "expectedBaseAppliedConfigVersion=INTEGER:1")
        require("KIND ERROR" in denied_apply and "ERROR unauthorized_action" in denied_apply, "apply scope was bypassed")
        wait_ok(reader)

        description = client(writer_descriptor, "describe")
        require("PARAMETER APPLY_DRAFT expectedBaseAppliedConfigVersion INTEGER REQUIRED" in description, "apply conflict contract missing")
        initial = client(writer_descriptor, "--fragment-bytes", "3", "get")
        current, base = version(initial), integer_field(initial, CONFIG, "baseAppliedConfigVersion")
        label_revision = integer_field(initial, LABEL, "draftFieldVersion")
        unicode_edit = client(writer_descriptor, "invoke", str(current), "EDIT_DRAFT_TEXT", "--target", str(LABEL), "--arg", "text=STRING:规则甲", "--arg", f"expectedFieldVersion=INTEGER:{label_revision}")
        require("APPLIED true" in unicode_edit and "REASON draft_updated" in unicode_edit, "UTF-8 label draft failed")
        after_unicode = client(writer_descriptor, "get", "--target", str(LABEL), "--target", str(RETENTION), "--target", str(CONFIG))
        require("FIELD 42011 draftText STRING 9 E8A784E58899E794B2" in after_unicode, "UTF-8 label did not round-trip")
        current = version(after_unicode)
        field_revision = integer_field(initial, RETENTION, "draftFieldVersion")
        edited = client(writer_descriptor, "invoke", str(current), "EDIT_DRAFT_TEXT", "--target", str(RETENTION), "--arg", "text=STRING:30", "--arg", f"expectedFieldVersion=INTEGER:{field_revision}")
        require("APPLIED true" in edited and "REASON draft_updated" in edited, "external field edit failed")
        after_edit = client(writer_descriptor, "get")
        require("FIELD 42013 draftText STRING 2 3330" in after_edit, "raw integer draft was not retained")
        draft_version, context = integer_field(after_edit, CONFIG, "draftVersion"), version(after_edit)
        stale = client(writer_descriptor, "invoke", str(context), "EDIT_DRAFT_TEXT", "--target", str(RETENTION), "--arg", "text=STRING:31", "--arg", f"expectedFieldVersion=INTEGER:{field_revision}")
        require("APPLIED false" in stale and "CONFLICT true" in stale and "field_version_conflict" in stale, "stale field write was not rejected")
        applied = client(writer_descriptor, "invoke", str(context), "APPLY_DRAFT", "--target", str(CONFIG), "--arg", f"expectedDraftVersion=INTEGER:{draft_version}", "--arg", f"expectedBaseAppliedConfigVersion=INTEGER:{base}")
        require("APPLIED true" in applied and "REASON draft_applied" in applied, "authorized explicit apply failed")
        final = client(writer_descriptor, "get", "--target", str(CONFIG), "--target", str(RETENTION))
        require("FIELD 42013 appliedValue INTEGER 30" in final, "applied value did not converge")
        require(integer_field(final, CONFIG, "appliedConfigVersion") == base + 1, "config version did not advance")
        denied_field = client(writer_descriptor, "invoke", str(version(final)), "EDIT_DRAFT_TEXT", "--target", str(ENABLED), "--arg", "text=STRING:true", "--arg", "expectedFieldVersion=INTEGER:0")
        require("KIND ERROR" in denied_field and "ERROR unauthorized_resource" in denied_field, "field-level scope was bypassed")
        wait_ok(writer)
    finally:
        for process in (writer, reader):
            if process.poll() is None:
                process.terminate(); process.wait(timeout=5)
        require(not writer_descriptor.exists(), "writer descriptor remained after close")
        require(not reader_descriptor.exists(), "reader descriptor remained after close")
    print("backup_rule_config_consumer editable-form acceptance passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

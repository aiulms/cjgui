#!/usr/bin/env python3
"""Non-restarting system selection replacement on the *current normal* OHOS HAP.

The caller supplies a build/run identity containing target, PID, HAP SHA-256 and
build_variant=normal. This probe never builds, installs, starts/stops an app or clears
hilog. It creates only a fresh, target-bound TCP forward owned by this invocation.
Example (use a new output path and the currently installed HAP/identity):

  python3 verify_current_normal_selection_replace.py \
    --target 127.0.0.1:5555 --run-dir /tmp/h-selection-settings-unique \
    --hap /path/to/entry-default-unsigned.hap --identity /path/to/h_input_runtime_identity.txt \
    --port 17932 --bundle com.example.cjguiapp --field name \
    --auth cjgui-settings-counter-agent-20260925 --x 660 --y 600 \
    --replacement '选区替换H🚀'

Screenshots are evidence for later visual review; image contents are not inferred
from logs. The actual IME marked-range and cancel callbacks are outside this probe.
"""

import argparse
import hashlib
import json
import re
import shlex
import subprocess
import sys
import time
import uuid
from pathlib import Path

from ohos_transport_probe_lib import BoundedExchange


DEFAULT_HDC = ("/Applications/DevEco-Studio.app/Contents/sdk/default/"
               "openharmony/toolchains/hdc")
PROTOCOL = "CJGUI_SHARED_OPERATION/2"
BUNDLES = {
    "com.example.cjguiapp": ("name", "cjgui-settings-counter-agent-20260925",
                                9700, 7856, "counter-name"),
    "com.example.cjguithermo": ("note", "cjgui-thermo-agent-20260926",
                                   9801, 7857, "thermo-note"),
}
APP_ROW = re.compile(r"^\S+\s+\S+\s+(\d+)\s+\d+\s+.*?/CjguiApp: (.*)$")
MAP_ROW = re.compile(r"(?:^|\s)(\S+)\s+tcp:(\d+)\s+(\S+)\s+\[Forward\]")


def assert_bundle_contract(bundle, field, auth):
    expected = BUNDLES.get(bundle)
    if expected is None or (field, auth) != expected[:2]:
        raise AssertionError("bundle/field/auth does not match a normal HAP consumer")
    return expected[2:]


def assert_identity(raw, target, hap, expected_pid=None):
    entries = {}
    for line in raw.splitlines():
        if not line.strip():
            continue
        key, sep, value = line.partition("=")
        if not sep or key in entries:
            raise AssertionError("invalid or repeated run identity key")
        entries[key] = value
    digest = hashlib.sha256(Path(hap).read_bytes()).hexdigest()
    pid = entries.get("pid", "")
    if (entries.get("target") != target or entries.get("hap_sha256") != digest
            or entries.get("build_variant") != "normal"
            or not re.fullmatch(r"[1-9]\d*", pid)
            or (expected_pid is not None and pid != expected_pid)):
        raise AssertionError("run identity does not bind target/PID/current normal HAP")
    return pid


def assert_same_pid(expected, pidof_output):
    actual = pidof_output.strip()
    if not re.fullmatch(r"[1-9]\d*", actual) or actual != expected:
        raise AssertionError(f"PID changed or ambiguous: expected {expected}, got {actual!r}")
    return actual


def assert_forward_map(listing, target, local_port, remote_port, *, present):
    matches = [(m.group(1), m.group(3)) for line in listing.splitlines()
               if (m := MAP_ROW.search(line)) and int(m.group(2)) == local_port]
    expected = [(target, f"tcp:{remote_port}")]
    if (present and matches != expected) or (not present and matches):
        raise AssertionError(f"forward mapping mismatch for {local_port}: {matches!r}")


def forward_create_succeeded(rc, stdout, stderr):
    return (rc == 0 and "Forwardport result:OK" in stdout
            and "[Fail]" not in stdout and "[Fail]" not in stderr)


def target_command(hdc, target, *args):
    return [hdc, "-t", target, *args]


def parse_owner(raw, resource_id, field):
    lines = raw.splitlines()
    if not lines or lines[0] != f"PROTOCOL {PROTOCOL}" or "KIND SNAPSHOT" not in lines:
        raise AssertionError("owner response is not a protocol snapshot")
    if not lines or lines[-1] != "END":
        raise AssertionError("owner snapshot has no END")
    versions = [line.split(" ", 1)[1] for line in lines if line.startswith("VERSION ")]
    matches = [line.split(" ") for line in lines
               if line.startswith(f"FIELD {resource_id} {field} ")]
    if len(versions) != 1 or not versions[0].isdigit() or len(matches) != 1:
        raise AssertionError("missing or ambiguous owner version/field")
    parts = matches[0]
    if len(parts) != 6 or parts[3] != "STRING" or not parts[4].isdigit():
        raise AssertionError("owner field is not a valid STRING")
    try:
        data = b"" if parts[5] == "-" else bytes.fromhex(parts[5])
        value = data.decode("utf-8")
    except (ValueError, UnicodeDecodeError) as exc:
        raise AssertionError("invalid owner UTF-8 field") from exc
    if len(data) != int(parts[4]):
        raise AssertionError("owner field byte count does not match")
    return {"version": int(versions[0]), "value": value, "raw": raw}


def assert_draft_unchanged(before, during):
    if (before["version"], before["value"]) != (during["version"], during["value"]):
        raise AssertionError("uncommitted draft changed the public owner")


def assert_exact_commit(before, after, replacement):
    if after["version"] != before["version"] + 1 or after["value"] != replacement:
        raise AssertionError("selection replacement did not commit exact owner value/version")


def app_rows(raw, pid):
    out = []
    for line in raw.splitlines():
        match = APP_ROW.match(line)
        if match and match.group(1) == pid:
            out.append(line)
    return out


def fresh_rows(before, after):
    if not before:
        raise AssertionError("no same-PID app log baseline")
    overlap = next((n for n in range(min(len(before), len(after)), 0, -1)
                    if before[-n:] == after[:n]), 0)
    if overlap < min(3, len(before)):
        raise AssertionError("hilog baseline missing/rotated; freshness unprovable")
    return after[overlap:]


def assert_fresh_focus(before, after, pid, field):
    matches = []
    for line in fresh_rows(app_rows("\n".join(before), pid),
                           app_rows("\n".join(after), pid)):
        match = re.search(r"ime proxy FOCUSED field=" + re.escape(field)
                          + r" mount=(\S+)$", line)
        if match:
            matches.append(match.group(1))
    if len(matches) != 1:
        raise AssertionError(f"expected one fresh focus for {field}; got {matches!r}")
    return matches[0]


def assert_fresh_selection(before, after, pid, mount):
    rows = fresh_rows(app_rows("\n".join(before), pid), app_rows("\n".join(after), pid))
    selected = []
    for line in rows:
        match = re.search(r"ime select \[(\d+),(\d+)\) rc=0 mount="
                          + re.escape(mount) + r"$", line)
        if match and int(match.group(2)) > int(match.group(1)):
            selected.append((int(match.group(1)), int(match.group(2))))
    if not selected:
        raise AssertionError("no fresh nonempty selection from current PID/mount")
    return selected[-1]


def assert_fresh_draft(before, after, pid, mount):
    rows = fresh_rows(app_rows("\n".join(before), pid), app_rows("\n".join(after), pid))
    lengths = []
    for line in rows:
        event = re.search(r"ime proxy onChange len=(\d+) verdict=(\S+) mount=(\S+)$", line)
        if event:
            if event.group(2) != "ok" or event.group(3) != mount:
                raise AssertionError("draft event belongs to a different/rejected mount")
            lengths.append(int(event.group(1)))
    if not lengths or 0 not in lengths or lengths[-1] <= 0:
        raise AssertionError(f"selected deletion and new visible draft missing: {lengths}")
    return lengths


def assert_fresh_submit(before, after, pid, mount):
    rows = fresh_rows(app_rows("\n".join(before), pid), app_rows("\n".join(after), pid))
    submits = [m.groups() for line in rows
               if (m := re.search(r"ime proxy submit verdict=(\S+) mount=(\S+)$", line))]
    if submits != [("ok", mount)]:
        raise AssertionError("no fresh successful submit from selected mount")


def menu_point(tree, label="全选"):
    found = []

    def visit(node):
        attrs = node.get("attributes", {})
        if attrs.get("text") == label:
            match = re.fullmatch(r"\[(\d+),(\d+)\]\[(\d+),(\d+)\]",
                                 attrs.get("bounds", ""))
            if match:
                x1, y1, x2, y2 = map(int, match.groups())
                if x2 > x1 and y2 > y1:
                    found.append(((x1 + x2) // 2, (y1 + y2) // 2))
        for child in node.get("children", []):
            visit(child)

    visit(tree)
    if len(found) != 1:
        raise AssertionError(f"expected one visible system {label} item, got {found!r}")
    return found[0]


class Hdc:
    def __init__(self, binary, target):
        self.binary, self.target, self.records = binary, target, []

    def run(self, *args, global_list=False, timeout=30, check=True):
        cmd = [self.binary, *args] if global_list else target_command(
            self.binary, self.target, *args)
        completed = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout)
        self.records.append({"cmd": cmd, "rc": completed.returncode,
                             "stdout": completed.stdout[:2000],
                             "stderr": completed.stderr[:2000]})
        if check and completed.returncode:
            raise AssertionError(f"hdc failed rc={completed.returncode}: {cmd!r} "
                                 f"{completed.stderr[:200]!r}")
        return completed

    def shell(self, command, *, timeout=30):
        return self.run("shell", command, timeout=timeout).stdout


class ForwardLease:
    def __init__(self, hdc, local_port, remote_port):
        self.hdc, self.local_port, self.remote_port = hdc, local_port, remote_port
        self.owned = False

    def listing(self):
        return self.hdc.run("fport", "ls", global_list=True).stdout

    def acquire(self):
        assert_forward_map(self.listing(), self.hdc.target, self.local_port,
                           self.remote_port, present=False)
        result = self.hdc.run("fport", f"tcp:{self.local_port}",
                              f"tcp:{self.remote_port}", check=False)
        if not forward_create_succeeded(result.returncode, result.stdout, result.stderr):
            raise AssertionError("target-bound forward has no successful creation receipt")
        self.owned = True
        assert_forward_map(self.listing(), self.hdc.target, self.local_port,
                           self.remote_port, present=True)

    def close(self):
        if not self.owned:
            return
        # A successful create receipt is necessary but not enough to remove a later
        # replacement by another owner; recheck target and both ports at cleanup.
        assert_forward_map(self.listing(), self.hdc.target, self.local_port,
                           self.remote_port, present=True)
        self.hdc.run("fport", "rm", f"tcp:{self.local_port}",
                     f"tcp:{self.remote_port}")
        assert_forward_map(self.listing(), self.hdc.target, self.local_port,
                           self.remote_port, present=False)
        self.owned = False


def write_new(path, content):
    with Path(path).open("x", encoding="utf-8") as out:
        out.write(content)


def run_probe(args, out, hdc):
    resource, remote_port, ime_field = assert_bundle_contract(
        args.bundle, args.field, args.auth)
    identity = Path(args.identity).read_text(encoding="utf-8")
    expected_pid = assert_identity(identity, args.target, args.hap)
    def same_pid():
        return assert_same_pid(expected_pid, hdc.shell(f"pidof {args.bundle}"))

    same_pid()
    lease = ForwardLease(hdc, args.port, remote_port)
    exchange = BoundedExchange("127.0.0.1", args.port,
                               str(out / "owner_frames.json"))
    remote_prefix = "/data/local/tmp/cjgui-h-selection-" + uuid.uuid4().hex
    remote_files = []

    def owner(label):
        assert_forward_map(lease.listing(), hdc.target, args.port, remote_port,
                           present=True)
        _, raw = exchange.exchange_strict(
            [f"PROTOCOL {PROTOCOL}", f"AUTH {args.auth}", "GET_CONTEXT 0"], 8)
        state = parse_owner(raw, resource, args.field)
        write_new(out / f"owner_{label}.txt", raw + "\n")
        return state

    def capture_log(label):
        raw = hdc.shell("hilog -x 2>/dev/null | grep -a 'CjguiApp:'", timeout=45)
        write_new(out / f"hilog_{label}.txt", raw)
        rows = app_rows(raw, expected_pid)
        if not rows:
            raise AssertionError(f"no current-PID app hilog rows for {label}")
        return rows

    def action(command, wait=0.8):
        hdc.shell(command, timeout=45)
        time.sleep(wait)
        same_pid()

    def pull(remote, local):
        remote_files.append(remote)
        hdc.run("file", "recv", remote, str(out / local), timeout=45)
        if not (out / local).is_file():
            raise AssertionError(f"device capture missing: {local}")

    def screenshot(label):
        remote = f"{remote_prefix}-{label}.jpeg"
        action(f"snapshot_display -f {remote}", wait=0)
        pull(remote, f"{label}.jpeg")

    result = {"target": args.target, "bundle": args.bundle, "field": args.field,
              "pid": expected_pid, "hap_sha256": hashlib.sha256(
                  Path(args.hap).read_bytes()).hexdigest(),
              "build_variant": "normal", "local_port": args.port,
              "device_port": remote_port, "replacement": args.replacement}
    try:
        lease.acquire()
        before = owner("before")
        before_focus = capture_log("before_focus")
        action(f"uitest uiInput click {args.x} {args.y}", wait=1.2)
        after_focus = capture_log("after_focus")
        mount = assert_fresh_focus(before_focus, after_focus, expected_pid, ime_field)
        result["mount"] = mount

        action(f"uitest uiInput longClick {args.x} {args.y}", wait=1.5)
        menu_remote = remote_prefix + "-menu.json"
        action(f"uitest dumpLayout -p {menu_remote}", wait=0.3)
        pull(menu_remote, "selection_menu.json")
        x, y = menu_point(json.loads((out / "selection_menu.json").read_text()))
        action(f"uitest uiInput click {x} {y}", wait=1.0)
        selected_log = capture_log("selected")
        result["selection_utf16"] = assert_fresh_selection(
            after_focus, selected_log, expected_pid, mount)
        screenshot("selected")

        action("uitest uiInput keyEvent 2055", wait=0.7)
        action(f"uitest uiInput inputText {args.x} {args.y} "
               + shlex.quote(args.replacement), wait=1.5)
        draft_log = capture_log("draft")
        result["draft_change_lengths"] = assert_fresh_draft(
            selected_log, draft_log, expected_pid, mount)
        during = owner("draft")
        assert_draft_unchanged(before, during)
        screenshot("draft")

        action("uitest uiInput keyEvent 2054", wait=1.2)
        submitted_log = capture_log("submitted")
        assert_fresh_submit(draft_log, submitted_log, expected_pid, mount)
        after = owner("after")
        assert_exact_commit(before, after, args.replacement)
        screenshot("after")
        same_pid()
        result.update({"result": "PASS", "owner_before": before["value"],
                       "owner_after": after["value"],
                       "version_before": before["version"],
                       "version_after": after["version"]})
        return result
    finally:
        exchange.flush_archive()
        cleanup_error = None
        for remote in remote_files:
            try:
                hdc.shell("rm -f " + shlex.quote(remote))
            except (AssertionError, subprocess.TimeoutExpired) as exc:
                cleanup_error = str(exc)
        try:
            lease.close()
        except (AssertionError, subprocess.TimeoutExpired) as exc:
            cleanup_error = str(exc)
        if cleanup_error:
            raise AssertionError("probe cleanup failed: " + cleanup_error)


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    for name in ("target", "run-dir", "hap", "identity", "bundle", "field", "auth",
                 "replacement"):
        parser.add_argument("--" + name, required=True)
    parser.add_argument("--port", type=int, required=True)
    parser.add_argument("--x", type=int, required=True)
    parser.add_argument("--y", type=int, required=True)
    parser.add_argument("--hdc", default=DEFAULT_HDC)
    args = parser.parse_args(argv)
    if not (1024 <= args.port <= 65535 and 0 <= args.x < 5000 and 0 <= args.y < 5000
            and args.replacement and "\n" not in args.replacement
            and "\x00" not in args.replacement):
        parser.error("invalid port, point, or replacement")
    assert_bundle_contract(args.bundle, args.field, args.auth)
    out = Path(args.run_dir)
    out.mkdir(parents=True, exist_ok=False)
    hdc = Hdc(args.hdc, args.target)
    try:
        result = run_probe(args, out, hdc)
        rc = 0
    except Exception as exc:  # retain the exact failure; no false PASS on partial chain
        result = {"result": "FAIL", "reason": type(exc).__name__ + ": " + str(exc)}
        rc = 1
    write_new(out / "commands.json", json.dumps(hdc.records, ensure_ascii=False, indent=2))
    write_new(out / "summary.json", json.dumps(result, ensure_ascii=False, indent=2))
    print(f"{result['result']} evidence={out} {result.get('reason', '')}")
    return rc


if __name__ == "__main__":
    sys.exit(main())

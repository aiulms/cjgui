#!/usr/bin/env python3
"""Current real-backend STOP -> full zero -> same-PID RESTART probe.

Run only against an already built, launched verify-transport HAP and an owned
target-bound forward to device port 7856. This script does not install, launch,
force-stop, clear hilog, create a forward, or borrow earlier run evidence.

Example:
  python3 verify_same_pid_restart_probe.py --target 127.0.0.1:5555 \
    --run-dir /absolute/path/to/artifacts/cjgui-backend/run/RUN_ID \
    --hap /absolute/path/to/entry-default-unsigned.hap --port 17856

STOP HOST and RESTART HOST are the test-seam ArkUI buttons. A normal HAP has
neither button, so this is an instrumented lifecycle proof, not a normal-app
interaction claim. Its public INCREMENT write/read uses the same authorized
business endpoint as the ordinary app.
"""

import argparse
import hashlib
import json
import re
import subprocess
import sys
import time
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
sys.path.insert(0, str(HERE.parents[2] / "shared_operation_core"))
from ohos_transport_probe_lib import BoundedExchange, parse_business_terminal_strict  # noqa: E402
from client import parse_response  # noqa: E402

BUNDLE = "com.example.cjguiapp"
PROTOCOL = "CJGUI_SHARED_OPERATION/2"
CAPABILITY = "cjgui-settings-counter-agent-20260925"
RESOURCE_ID = 9700
DEFAULT_HDC = ("/Applications/DevEco-Studio.app/Contents/sdk/default/"
               "openharmony/toolchains/hdc")
PID_LINE = re.compile(r"^\S+\s+\S+\s+(\d+)\s+\d+\s+[A-Z]\s+")


def own_lines(lines, pid):
    if not re.fullmatch(r"\d+", str(pid)):
        raise AssertionError(f"invalid PID {pid!r}")
    return [line for line in lines if (m := PID_LINE.match(line)) and m.group(1) == str(pid)]


def app_trace_lines(lines, pid):
    # `hilog -x` can reorder framework/accessibility rows from the same PID
    # between reads. Only our app markers participate in the append-only
    # boundary; keep PID binding and reject loss/reordering of those markers.
    return [line for line in own_lines(lines, pid) if " A00000/Cjgui" in line]


def find_after(lines, start, predicate, label):
    for index in range(start + 1, len(lines)):
        if predicate(lines[index]):
            return index
    raise AssertionError(f"{label} absent or out of order")


def field_is(line, name, value):
    return re.search(r"(?<!\w)" + re.escape(name) + "=" + re.escape(str(value)) + r"\b", line) is not None


def initial_proof(lines, pid, app_instance, token):
    """Bind current launch to its real native reference and subsequent frame."""
    own = own_lines(lines, pid)
    accepted = find_after(own, -1, lambda s: "startHost accepted:" in s and
                          field_is(s, "appInstance", app_instance), "launch instance")
    token_index = find_after(own, accepted, lambda s: f"verify seam armed token={token}" in s,
                             "launch verify token")
    if any("startHost accepted:" in s for s in own[accepted + 1:]) or any(
            "verify seam armed token=" in s for s in own[token_index + 1:]):
        raise AssertionError("this launch is no longer the current app instance/token")
    publication = find_after(
        own, accepted,
        lambda s: "surface created id=" in s and field_is(s, "app", app_instance)
        and "nativeref rc=0" in s and "published=1" in s,
        "current-instance native-ref publication")
    frame = find_after(own, publication, lambda s: "present frame ok" in s,
                       "real first frame")
    find_after(own, accepted, lambda s: "host started; pumping turns" in s,
               "Cangjie owner start")
    return {"pid": str(pid), "appInstance": app_instance, "token": token,
            "accepted": own[accepted], "publication": own[publication], "frame": own[frame]}


def stop_proof(lines, pid, app_instance):
    """Check only post-tap lines: UI stop, production tail, and all zero fields."""
    own = own_lines(lines, pid)
    ui = find_after(own, -1, lambda s: "verify stop host requested from UI" in s,
                    "UI STOP HOST request")
    requested = find_after(
        own, ui, lambda s: "stopHost requested" in s and
        field_is(s, "appInstance", app_instance), "same-instance stop request")
    stopping = find_after(
        own, requested, lambda s: "stopHost: host phase=stopping" in s and
        field_is(s, "appInstance", app_instance), "same-instance stopping transition")
    transport = find_after(
        own, stopping, lambda s: "transport closing:" in s and all(
            field_is(s, key, value) for key, value in
            {"closed": "true", "queued": 0, "conns": 0, "inflight": 0}.items()),
        "transport full zero")
    closed = find_after(
        own, transport, lambda s: "host closed;" in s and
        field_is(s, "render_shutdown_status", 0) and field_is(s, "shutdown_done", 1),
        "renderer shutdown")
    settled = find_after(
        own, closed, lambda s: "stop settled" in s and all(
            field_is(s, key, value) for key, value in {
                "appInstance": app_instance, "ownerJoined": 1, "rendererDone": 1,
                "sessions": 0, "unacked": 0, "pending": 0,
                "refsUnclosed": 0, "activeSurfaces": 0, "phase": "stopped",
            }.items()), "same-instance full-zero settlement")
    if any("startHost accepted:" in s for s in own[ui:settled]):
        raise AssertionError("new app instance interposed before full-zero settlement")
    return {"pid": str(pid), "appInstance": app_instance, "ui": own[ui],
            "request": own[requested], "transport": own[transport],
            "closed": own[closed], "settled": own[settled]}


def restart_proof(lines, pid, old_instance, old_token):
    """Check only post-settlement lines; an old publication/frame cannot count."""
    own = own_lines(lines, pid)
    ui = find_after(own, -1, lambda s: "verify restart host requested from UI" in s,
                    "UI RESTART HOST request")
    accepted = find_after(own, ui, lambda s: "startHost accepted:" in s,
                          "restart acceptance")
    match = re.search(r"\bappInstance=(\d+)\b", own[accepted])
    if not match or int(match.group(1)) <= old_instance:
        raise AssertionError("restart did not allocate a new appInstance")
    new_instance = int(match.group(1))
    token_index = find_after(own, accepted, lambda s: "verify seam armed token=" in s,
                             "new verify token")
    token_match = re.search(r"verify seam armed token=(\S+)", own[token_index])
    token = token_match.group(1) if token_match else ""
    if not token or token == old_token:
        raise AssertionError("restart reused old or empty verify token")
    ready = find_after(
        own, accepted, lambda s: "owner declared ready: host phase=running" in s
        and field_is(s, "appInstance", new_instance), "new owner ready")
    direct = next((i for i in range(accepted + 1, len(own))
                   if "surface created id=" in own[i] and field_is(own[i], "app", new_instance)
                   and "nativeref rc=0" in own[i] and "published=1" in own[i]), None)
    if direct is not None:
        publication = direct
        reference = own[direct]
    else:
        # A still-mounted XComponent may be republished through the host's
        # current mount fact. Require a fresh system reference plus its new
        # generation, not the old instance's `surface created` line.
        ref = find_after(
            own, accepted,
            lambda s: "ref abi probe" in s and field_is(s, "rc", 0)
            and field_is(s, "held", 1) and "libsurface.z.so" in s,
            "restart system native reference")
        publication = find_after(own, ref, lambda s: "simulate surface created gen=" in s,
                                 "restart live-mount publication")
        reference = own[ref]
    # A real frame can finish just before the owner emits its ready marker;
    # both must belong to the new instance, but their mutual order is not a
    # lifecycle requirement.
    frame = find_after(own, publication, lambda s: "present frame ok" in s,
                       "new-instance real first frame")
    settled = max(frame, ready)
    if any("startHost accepted:" in s for s in own[accepted + 1:settled]):
        raise AssertionError("another app instance interposed before new first frame")
    if any("stopHost requested" in s for s in own[accepted:settled]):
        raise AssertionError("new instance stopped before first frame")
    return {"pid": str(pid), "appInstance": new_instance, "token": token,
            "ui": own[ui], "accepted": own[accepted], "ready": own[ready],
            "reference": reference, "publication": own[publication], "frame": own[frame]}


def tail_since(before, after):
    if len(after) < len(before) or after[:len(before)] != before:
        raise AssertionError("hilog prefix changed or rolled over; cannot borrow old events")
    return after[len(before):]


def bootstrap_proof(run_dir, hap, pid, target):
    """Use only the build/launch record of this run, then bind live PID/token."""
    run_dir, hap = Path(run_dir), Path(hap)
    run_id = run_dir.name
    if not re.fullmatch(r"[A-Za-z0-9._-]+", run_id) or not run_dir.is_dir():
        raise AssertionError("invalid or missing run directory")
    def read(name):
        return (run_dir / name).read_text(encoding="utf-8")
    digest = read("hap_sha256.txt").splitlines()[0].strip()
    if not re.fullmatch(r"[0-9a-f]{64}", digest) or hashlib.sha256(hap.read_bytes()).hexdigest() != digest:
        raise AssertionError("current local HAP differs from this run's frozen hash")
    install = read(f"install_{run_id}.txt")
    if f"App install path:{hap}" not in install or "install bundle successfully" not in install.lower():
        raise AssertionError("this run lacks the current HAP install receipt")
    if read(f"pid_{run_id}.txt").strip() != f"pid={pid}":
        raise AssertionError("live PID differs from this run's launch PID")
    variant = read(f"variant_{run_id}.txt").strip()
    if "verify-transport" not in variant:
        raise AssertionError("UI STOP/RESTART requires a verify-transport HAP")
    assertion = read(f"startup_assert_{run_id}.txt")
    required = (f"run_id={run_id}", f"hap_sha256={digest}", f"build_variant={variant}",
                "log_cleared=ok", f"launch_pid={pid}")
    if any(item not in assertion.splitlines() for item in required) or "  FAIL " in assertion:
        raise AssertionError("this run's startup assertion is incomplete or failed")
    if not re.search(r"(?m)^launch_id=\S+$", assertion):
        raise AssertionError("this run lacks a launch ID")
    request = run_dir / "requested_identity.txt"
    if request.exists() and (f"target={target}" not in request.read_text(encoding="utf-8").splitlines()):
        raise AssertionError("requested target differs from this run")
    runlog = read(f"runlog_{run_id}.txt").splitlines()
    own = own_lines(runlog, pid)
    accepted = [m.group(1) for s in own if "startHost accepted:" in s
                if (m := re.search(r"\bappInstance=(\d+)\b", s))]
    tokens = [m.group(1) for s in own if (m := re.search(r"verify seam armed token=(\S+)", s))]
    if len(accepted) != 1 or len(tokens) != 1:
        raise AssertionError("this launch log lacks one PID-bound appInstance/token")
    proof = initial_proof(runlog, pid, int(accepted[0]), tokens[0])
    proof.update({"run_id": run_id, "target": target, "hap_sha256": digest,
                  "variant": variant, "launch_id": re.search(r"(?m)^launch_id=(\S+)$", assertion).group(1)})
    return proof


def owner_state_of(body):
    parsed = parse_response(body)
    if parsed.kind != "SNAPSHOT":
        raise AssertionError(f"GET_CONTEXT returned {parsed.kind!r}")
    versions = [int(parts[0]) for key, parts in parsed.entries if key == "VERSION"]
    counts = [int(parts[3]) for key, parts in parsed.entries if key == "FIELD"
              and len(parts) == 4 and parts[:3] == (str(RESOURCE_ID), "count", "INTEGER")]
    if len(versions) != 1 or len(counts) != 1:
        raise AssertionError("owner snapshot lacks one exact count and version")
    return {"version": versions[0], "count": counts[0]}


def assert_authorized_write_readback(before_body, result_body, after_body):
    before = owner_state_of(before_body)
    result = parse_business_terminal_strict(result_body)
    after = owner_state_of(after_body)
    if (result.get("KIND") != "RESULT" or result.get("APPLIED") != "true"
            or result.get("CONFLICT") != "false"
            or result.get("VERSION_BEFORE") != before["version"]
            or result.get("VERSION_AFTER") != before["version"] + 1
            or after != {"version": before["version"] + 1,
                         "count": before["count"] + 1}):
        raise AssertionError(f"authorized write/read diverged: before={before} "
                             f"result={result} after={after}")
    return {"before": before, "result": {k: result[k] for k in
            ("APPLIED", "CONFLICT", "VERSION_BEFORE", "VERSION_AFTER")}, "after": after}


def assert_forward_target(listing, target, port):
    matches = []
    for line in listing.splitlines():
        match = re.search(r"(?:^|\s)(\S+)\s+tcp:(\d+)\s+(\S+)\s+\[Forward\]", line)
        if match and int(match.group(2)) == port:
            matches.append((match.group(1), match.group(3)))
    if matches != [(target, "tcp:7856")]:
        raise AssertionError(f"forward is not uniquely target-bound: {matches!r}")


def ui_button_center(layout, label):
    hits = []
    def walk(node):
        if not isinstance(node, dict):
            return
        attrs = node.get("attributes", {})
        if isinstance(attrs, dict) and attrs.get("text") == label and all(
                attrs.get(k) == v for k, v in
                {"type": "Button", "visible": "true", "enabled": "true",
                 "clickable": "true"}.items()):
            hits.append(attrs.get("bounds", ""))
        for child in node.get("children", []):
            walk(child)
    walk(layout)
    if len(hits) != 1:
        raise AssertionError(f"unique visible {label!r} button absent")
    match = re.fullmatch(r"\[(\d+),(\d+)\]\[(\d+),(\d+)\]", str(hits[0]))
    if not match:
        raise AssertionError(f"invalid {label!r} bounds")
    x1, y1, x2, y2 = map(int, match.groups())
    if x2 <= x1 or y2 <= y1:
        raise AssertionError(f"nonpositive {label!r} bounds")
    return (x1 + x2) // 2, (y1 + y2) // 2


class Device:
    def __init__(self, hdc, target, run_dir, pid):
        self.hdc = hdc
        self.target = target
        self.run_dir = run_dir
        self.pid = pid

    def command(self, *args, targeted=True):
        command = [self.hdc]
        if targeted:
            command += ["-t", self.target]
        result = subprocess.run(command + list(args), capture_output=True, text=True, timeout=35)
        if result.returncode != 0:
            raise AssertionError(f"hdc {args[:2]!r} failed rc={result.returncode}: {result.stderr.strip()}")
        return result.stdout

    def assert_pid(self):
        current = self.command("shell", f"pidof {BUNDLE}").strip()
        if current != self.pid:
            raise AssertionError(f"same-PID requirement failed: launch={self.pid} current={current!r}")

    def hilog(self, label):
        self.assert_pid()
        lines = app_trace_lines(self.command("shell", "hilog -x").splitlines(), self.pid)
        (self.run_dir / "verification" / f"same_pid_restart_{label}.hilog").write_text(
            "\n".join(lines) + "\n", encoding="utf-8")
        return lines

    def layout(self, label):
        remote = f"/data/local/tmp/cjgui_{self.run_dir.name}_same_pid_{label}.json"
        local = self.run_dir / "verification" / f"same_pid_restart_{label}_layout.json"
        self.command("shell", f"uitest dumpLayout -p {remote}")
        self.command("file", "recv", remote, str(local))
        return json.loads(local.read_text(encoding="utf-8"))

    def button(self, label, key, timeout=5):
        deadline = time.monotonic() + timeout
        last = ""
        while time.monotonic() < deadline:
            self.assert_pid()
            try:
                return ui_button_center(self.layout(key), label)
            except AssertionError as exc:
                last = str(exc)
                time.sleep(0.25)
        raise AssertionError(f"{label} unavailable: {last}")

    def tap(self, center):
        self.assert_pid()
        x, y = center
        self.command("shell", f"uitest uiInput click {x} {y}")
        self.assert_pid()


def poll_proof(device, baseline, label, proof, timeout):
    deadline = time.monotonic() + timeout
    last = ""
    while time.monotonic() < deadline:
        lines = device.hilog(label)
        delta = tail_since(baseline, lines)
        try:
            return lines, proof(delta)
        except AssertionError as exc:
            last = str(exc)
            time.sleep(0.4)
    raise AssertionError(f"{label} proof timed out: {last}")


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--target", required=True, help="explicit HDC connectkey")
    parser.add_argument("--run-dir", type=Path, required=True, help="this build_and_run run directory")
    parser.add_argument("--hap", type=Path, required=True, help="HAP built for this run")
    parser.add_argument("--port", type=int, required=True, help="owned local forward to device 7856")
    parser.add_argument("--hdc", default=DEFAULT_HDC, help="HDC binary (not a target wrapper)")
    args = parser.parse_args(argv)
    if not re.fullmatch(r"[A-Za-z0-9._:-]+", args.target) or not 1 <= args.port <= 65535:
        parser.error("invalid explicit target or local port")
    if not re.fullmatch(r"[A-Za-z0-9._-]+", args.run_dir.name):
        parser.error("unsafe run-id")
    verification = args.run_dir / "verification"
    verification.mkdir(exist_ok=True)
    evidence_path = verification / "same_pid_restart_evidence.json"
    if evidence_path.exists():
        parser.error(f"same-run evidence already exists: {evidence_path}")
    evidence = {"status": "FAIL", "run_id": args.run_dir.name, "target": args.target,
                "local_port": args.port, "device_port": 7856, "checks": [], "error": ""}
    exchange = BoundedExchange("127.0.0.1", args.port,
                               str(verification / "same_pid_restart_raw.json"))
    device = Device(args.hdc, args.target, args.run_dir, "")
    try:
        listing = device.command("fport", "ls", targeted=False)
        assert_forward_target(listing, args.target, args.port)
        evidence["checks"].append("exact target-bound forward")
        pid = device.command("shell", f"pidof {BUNDLE}").strip()
        if not re.fullmatch(r"\d+", pid):
            raise AssertionError(f"target app PID absent or ambiguous: {pid!r}")
        device.pid = pid
        bootstrap = bootstrap_proof(args.run_dir, args.hap, pid, args.target)
        evidence["bootstrap"] = bootstrap
        initial = device.hilog("initial")
        initial_live = initial_proof(initial, pid, bootstrap["appInstance"], bootstrap["token"])
        if initial_live["accepted"] != bootstrap["accepted"]:
            raise AssertionError("launch marker differs from this run's startup log")
        evidence["initial"] = initial_live
        evidence["checks"].append("current HAP/PID/token and real initial reference/frame")

        def business(lines):
            _, body = exchange.exchange_strict(
                [f"PROTOCOL {PROTOCOL}", f"AUTH {CAPABILITY}"] + lines, 8)
            return body

        evidence["before_stop_owner"] = owner_state_of(business(["GET_CONTEXT 0"]))
        device.tap(device.button("STATE", "state"))
        stop_button = device.button("STOP HOST", "stop")
        # State refresh may have added log lines. Freeze the exact pre-stop
        # boundary immediately before the UI tap; old settlement cannot count.
        before_stop = device.hilog("before_stop")
        device.tap(stop_button)
        stopped_lines, stopped = poll_proof(
            device, before_stop, "stopped",
            lambda delta: stop_proof(delta, pid, bootstrap["appInstance"]), 30)
        evidence["stopped"] = stopped
        evidence["checks"].append("UI STOP HOST same-instance full zero")

        restart_button = device.button("RESTART HOST", "restart")
        before_restart = device.hilog("before_restart")
        device.tap(restart_button)
        restarted_lines, restarted = poll_proof(
            device, before_restart, "restarted",
            lambda delta: restart_proof(delta, pid, bootstrap["appInstance"],
                                        bootstrap["token"]), 35)
        evidence["restarted"] = restarted
        evidence["checks"].append("UI RESTART HOST new appInstance and real first frame")

        before_body = business(["GET_CONTEXT 0"])
        before = owner_state_of(before_body)
        result_body = business([f"INVOKE {before['version']} INCREMENT 1 0",
                                f"ID {RESOURCE_ID}"])
        after_body = business(["GET_CONTEXT 0"])
        evidence["authorized_write_read"] = assert_authorized_write_readback(
            before_body, result_body, after_body)
        device.assert_pid()
        evidence["checks"].append("new-instance public authorized write and exact owner readback")
        evidence["status"] = "PASS"
        return 0
    except Exception as exc:  # noqa: BLE001 - preserve named FAIL evidence
        evidence["error"] = f"{type(exc).__name__}: {exc}"
        return 1
    finally:
        exchange.flush_archive()
        evidence_path.write_text(json.dumps(evidence, ensure_ascii=False, indent=2) + "\n",
                                 encoding="utf-8")
        print(f"SAME_PID_RESTART {evidence['status']} run_id={args.run_dir.name} "
              f"target={args.target} evidence={evidence_path} {evidence['error']}")


if __name__ == "__main__":
    sys.exit(main())

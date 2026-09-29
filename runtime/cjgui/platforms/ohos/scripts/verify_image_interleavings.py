#!/usr/bin/env python3
"""Controlled image interleavings through the real settings test HAP.

Requires an already launched test-gates settings HAP, current-PID verify token
in hilog and an owned target-bound forward. Uses CONTROL only to hold/release a
native decode completion, evict idle cache entries, read native counters and
inject the existing present rejection. Candidate/owner/state reads use the
normal typed public client. STOP/RESTART are real ArkUI test-seam buttons.

This is an instrumented timing proof; normal HAP consumption is separately
checked by verify_normal_image_consumption.py.
"""

from __future__ import annotations

import argparse
from dataclasses import asdict
import hashlib
import json
from pathlib import Path
import re
import shlex
import sys
import time
import uuid

import verify_normal_generated_consumption as normal
import verify_normal_image_consumption as image_normal
import verify_normal_generated_gui_consumption as gui
import verify_same_pid_restart_probe as restart
from cjgui_generated_client import GeneratedUiSession
from ohos_transport_probe_lib import BoundedExchange, gate_command


STATS = ("decodeStarts", "encodedReadBytes", "decodeMicros", "cacheHits",
         "inFlight", "queued", "awaiting", "readyRecords", "residentBytes",
         "bitmapCreates", "bitmapDestroys", "staleDiscards")
STATS_EXT = ("encodedReadMicros", "decoderActiveBytes", "decoderPeakBytes",
             "reservationBytes", "peakTrackedBytes", "bitmapCreateMicros",
             "bitmapDestroyMicros", "idleCacheBytes")
IMAGE_IDLE_BYTES = 16 * 1024 * 1024
IMAGE_PROCESS_BYTES = 128 * 1024 * 1024
IMAGE_MAX_RECORDS = 64
IMAGE_DECODED_BYTES = 16 * 1024 * 1024
IMAGE_RUNNING_RESERVATION_BYTES = 4 * 1024 * 1024 + 2 * IMAGE_DECODED_BYTES


def test_hap_identity(raw: str, target: str, pid: str, hap: Path) -> str:
    fields: dict[str, str] = {}
    for line in raw.splitlines():
        if not line.strip():
            continue
        key, separator, value = line.partition("=")
        if not separator or key in fields:
            raise ValueError("test HAP identity has an invalid or repeated key")
        fields[key] = value
    digest = hashlib.sha256(hap.read_bytes()).hexdigest()
    if (fields.get("target") != target or fields.get("pid") != pid or
            fields.get("build_variant") != "verify-transport+test-gates" or
            fields.get("hap_sha256") != digest or not re.fullmatch(r"[1-9]\d*", pid)):
        raise ValueError("test HAP identity does not bind target/PID/digest/variant")
    return digest


def image_candidate(version: int | None, *, nodes: int = 1) -> str:
    if nodes not in (0, 1, 2) or (nodes and version not in (1, 2)):
        raise ValueError("candidate image node count/version is invalid")
    lines = ["GENERATED_UI_STRUCTURE 1", "NODE 0 board vertical"]
    for index in range(nodes):
        key = "icon" if index == 0 else "icon2"
        lines += [f"NODE 1 {key} image", f"PROPERTY 1 {key} resource settings-beacon",
                  f"PROPERTY 1 {key} resourceVersion {version}",
                  f"PROPERTY 1 {key} contentMode fill",
                  f"PROPERTY 1 {key} fixedWidth 160", f"PROPERTY 1 {key} fixedHeight 72"]
    lines += ["NODE 1 editor textInput field=name", "PROPERTY 1 editor label 名称", "END"]
    return "\n".join(lines)


def parse_stats(result: str, *, extended: bool = False) -> dict[str, int]:
    expected = STATS_EXT if extended else STATS
    values = dict(token.split("=", 1) for token in result.split() if "=" in token)
    if values.get("image_stats_rc") != "0":
        raise ValueError(f"native image stats returned an error: {result}")
    if any(key not in values or not values[key].lstrip("-").isdigit() for key in expected):
        raise ValueError(f"native image stats lack one or more slots: {result}")
    return {key: int(values[key]) for key in expected}


class Gate:
    def __init__(self, port: int, token: str, out: Path):
        self.token = token
        self.archive_file = out / f"control_raw_{uuid.uuid4().hex}.json"
        self.exchange = BoundedExchange("127.0.0.1", port, str(self.archive_file))
        self.rows: list[dict[str, object]] = []

    def call(self, op: str, success: str | None = None) -> str:
        started = time.perf_counter_ns()
        try:
            result = gate_command(self.exchange, self.token, op,
                                  expect_tokens=((success,) if success else ()))
        finally:
            self.exchange.flush_archive()
        self.rows.append({"op": op, "result": result, "utc": normal.utc_now(),
                          "control_request_ms": normal.elapsed_ms(started)})
        return result

    def stats(self) -> dict[str, int]:
        return parse_stats(self.call("GATE_IMAGE_STATS", "image_stats_rc=0"))

    def stats_ext(self) -> dict[str, int]:
        return parse_stats(self.call("GATE_IMAGE_STATS_EXT", "image_stats_rc=0"),
                           extended=True)


def current_token(hdc: gui.GuiHdc, pid: str) -> str:
    rows = hdc.shell("hilog -x").splitlines()
    tokens = []
    for line in rows:
        match = restart.PID_LINE.match(line)
        token = re.search(r"verify seam armed token=(\S+)", line)
        if match and match.group(1) == pid and token:
            tokens.append(token.group(1))
    if not tokens:
        raise ValueError("current-PID verify token is absent")
    return tokens[-1]


def stable_app_hilog(hdc: gui.GuiHdc, pid: str) -> list[str]:
    """Use only this PID's CJGUI tags for append-only lifecycle boundaries."""
    return restart.app_trace_lines(hdc.shell("hilog -x").splitlines(), pid)


def new_lifecycle_marker_tail(before: list[str], after: list[str],
                              marker: str) -> list[str]:
    """Anchor a new UI action when older same-PID hilog lines have rolled out.

    The complete timestamped marker must be absent before and unique afterward.
    A rolled ring cannot recover an older line, so this cannot borrow a prior
    STOP or RESTART while still allowing the earlier prefix to disappear.
    """
    previous = set(before)
    positions = [index for index, line in enumerate(after)
                 if marker in line and line not in previous]
    if len(positions) != 1:
        raise AssertionError(f"expected one newly observed lifecycle marker: {marker}")
    return after[positions[0]:]


def connect(args: argparse.Namespace, out: Path) -> tuple[GeneratedUiSession,
                                                             normal.ExchangeRecorder]:
    recorder = normal.ExchangeRecorder(out / f"public_{uuid.uuid4().hex}.jsonl")
    session = GeneratedUiSession.connect_forwarded_tcp(
        target=args.target, local_port=args.local_port, device_port=7856,
        capability=args.capability, caller=args.caller)
    session.client = normal.RecordingClient(session.client.descriptor,
                                            session.client.fragment_bytes,
                                            session.client, recorder)
    return session, recorder


def submit(session: GeneratedUiSession, recorder: normal.ExchangeRecorder,
           out: Path, label: str, version: int | None, *, nodes: int = 1,
           accepted: bool = True) -> dict[str, object]:
    recorder.phase = label
    payload = image_candidate(version, nodes=nodes)
    (out / f"candidate_{label}.txt").write_text(payload, encoding="utf-8")
    before = session.structure()
    posted = session.submit_text(payload, before.version)
    wait = session.wait_for_candidate_result(posted.ticket(), timeout_ms=8000, poll_ms=30)
    state = wait.last_state
    after = session.structure()
    if state is None or wait.outcome != "terminal":
        raise ValueError(f"{label}: candidate did not reach a terminal state")
    actual = state.terminal_state == "ACCEPTED" and posted.candidate_accepted
    if actual != accepted:
        raise ValueError(f"{label}: unexpected candidate state {state.terminal_state}: {state.reason}")
    if accepted and after.version != state.accepted_version:
        raise ValueError(f"{label}: accepted structure version disagrees with ticket")
    row = {"submit": asdict(posted), "ticket": asdict(state),
           "structure": asdict(after), "snapshot": asdict(session.snapshot())}
    normal.write_json(out / f"candidate_{label}.json", row)
    return row


def require_native_image_rejection(ticket, before_structure, after_structure,
                                   owner_before: dict[str, object],
                                   owner_after: dict[str, object]) -> str:
    """A rejected ticket proves this leg only when native presentation rejected it."""
    if (ticket is None or ticket.terminal_state != "REJECTED" or
            ticket.reason != "layout_or_native" or
            after_structure.version != before_structure.version or
            owner_after != owner_before):
        raise ValueError("native image rejection did not preserve structure and owner")
    return ticket.reason


def require_held_image_completion(before: dict[str, int],
                                  after: dict[str, int]) -> str:
    """The one held completion must leave waiting and reach one native terminal."""
    realized = after["bitmapCreates"] - before["bitmapCreates"]
    discarded = after["staleDiscards"] - before["staleDiscards"]
    if (before["awaiting"] != 1 or after["awaiting"] != 0 or
            (realized, discarded) not in ((1, 0), (0, 1))):
        raise ValueError("held v1 lacked an exact bitmap or stale-discard terminal")
    return "bitmap_realized" if realized == 1 else "stale_discarded"


def require_shared_image_reuse(before: dict[str, int], two: dict[str, int],
                               one: dict[str, int]) -> dict[str, int]:
    """Two references and then one must reuse the already ready native image."""
    if (before["residentBytes"] <= 0 or one["residentBytes"] <= 0 or
            any(row["decodeStarts"] != before["decodeStarts"] or
                row["bitmapCreates"] != before["bitmapCreates"] or
                row["residentBytes"] > before["residentBytes"]
                for row in (two, one))):
        raise ValueError("shared image nodes caused another decode, bitmap, or allocation")
    return {key: one[key] for key in ("decodeStarts", "bitmapCreates", "residentBytes")}


def require_bounded_image_idle(stats: dict[str, int],
                               extended: dict[str, int]) -> dict[str, int]:
    """A settled scene may retain its live image and up to 16 MiB idle cache."""
    needed = ("inFlight", "queued", "awaiting", "readyRecords", "residentBytes",
              "bitmapCreates", "bitmapDestroys")
    extra = ("decoderActiveBytes", "reservationBytes", "peakTrackedBytes",
             "idleCacheBytes")
    if (any(stats[key] < 0 for key in needed) or
            any(extended[key] < 0 for key in extra)):
        raise ValueError("image counters contain a negative value")
    live_bitmaps = stats["bitmapCreates"] - stats["bitmapDestroys"]
    if (stats["inFlight"] != 0 or stats["queued"] != 0 or
            stats["awaiting"] != 0 or extended["decoderActiveBytes"] != 0 or
            extended["reservationBytes"] != 0 or
            stats["readyRecords"] > IMAGE_MAX_RECORDS or
            stats["residentBytes"] > IMAGE_PROCESS_BYTES or
            extended["peakTrackedBytes"] > IMAGE_PROCESS_BYTES or
            extended["idleCacheBytes"] > IMAGE_IDLE_BYTES or
            extended["idleCacheBytes"] > stats["residentBytes"] or
            live_bitmaps < 0 or live_bitmaps > stats["readyRecords"]):
        raise ValueError("image queue, native references, or idle cache did not converge")
    return {**stats, **extended, "liveBitmaps": live_bitmaps}


def wait_for_bounded_image_idle(gate: Gate, timeout: float = 8.0) -> dict[str, int]:
    deadline = time.monotonic() + timeout
    while True:
        stats, extended = gate.stats(), gate.stats_ext()
        try:
            return require_bounded_image_idle(stats, extended)
        except ValueError as exc:
            if time.monotonic() >= deadline:
                raise TimeoutError(f"image resources did not converge: {exc}") from exc
            time.sleep(0.05)


def parse_stop_image_snapshot(lines: list[str]) -> dict[str, int]:
    """Read one same-PID STOP pair from the already bounded lifecycle tail."""
    pending: dict[str, int] | None = None
    pairs: list[dict[str, int]] = []
    for line in lines:
        if "image-cost stage=stop " not in line:
            continue
        values = {key: int(value) for key, value in image_normal.COST_VALUE.findall(line)}
        if "starts" in values:
            pending = values
        elif "resident" in values and pending is not None:
            pairs.append({**pending, **values})
            pending = None
    if len(pairs) != 1:
        raise ValueError("expected one current-instance native image STOP snapshot")
    return pairs[0]


def require_bounded_stop_image(snapshot: dict[str, int]) -> dict[str, int]:
    """STOP releases bitmaps and queues; one SDK decode may finish afterward."""
    keys = ("resident", "idle", "activeBytes", "reservations", "peakTracked",
            "running", "queued", "bitmapCreates", "bitmapDestroys")
    if any(key not in snapshot or snapshot[key] < 0 for key in keys):
        raise ValueError("native image STOP snapshot is incomplete")
    if (snapshot["queued"] != 0 or snapshot["running"] > 1 or
            snapshot["reservations"] > IMAGE_RUNNING_RESERVATION_BYTES or
            snapshot["activeBytes"] > IMAGE_DECODED_BYTES or
            snapshot["resident"] > IMAGE_PROCESS_BYTES or
            snapshot["peakTracked"] > IMAGE_PROCESS_BYTES or
            snapshot["idle"] > IMAGE_IDLE_BYTES or
            snapshot["idle"] > snapshot["resident"] or
            snapshot["bitmapCreates"] != snapshot["bitmapDestroys"]):
        raise ValueError("STOP retained image queue, bitmap, or unbounded decode memory")
    return snapshot


def switch(session: GeneratedUiSession, wanted: int) -> dict[str, object]:
    before = image_normal._owner(session, "settings")
    previous_image = image_normal._image_version(session, "settings")
    if previous_image == wanted:
        raise ValueError("switch requested the already active image version")
    result = session.invoke_action("SWITCH_IMAGE", [9700],
                                   expected_version=before["version"])
    applied = [tokens[0] for label, tokens in result.entries
               if label == "APPLIED" and len(tokens) == 1]
    if result.kind != "RESULT" or applied != ["true"]:
        raise ValueError("public SWITCH_IMAGE did not apply")
    deadline = time.monotonic() + 8
    while time.monotonic() < deadline:
        snapshot = session.snapshot()
        if (image_normal._image_version(session, "settings") == wanted and
                session.capabilities(refresh=True).image_resource("settings-beacon", wanted) and
                not snapshot.owner_pending_scene and
                snapshot.window_accepted_scene_version > 0):
            return {"before": before, "after": image_normal._owner(session, "settings"),
                    "raw_response": result.raw, "new_image_version": wanted,
                    "settled_scene": asdict(snapshot)}
        time.sleep(0.03)
    raise TimeoutError("SWITCH_IMAGE did not publish the expected resource version")


def wait_image(session: GeneratedUiSession, version: int, state: str,
               timeout: float = 8.0, key: str = "icon"):
    deadline = time.monotonic() + timeout
    observed = []
    while time.monotonic() < deadline:
        instance = session.instances().instance(key)
        if instance is not None:
            observed.append((instance.resource_version, instance.resource_state))
            if (instance.resource == "settings-beacon" and
                    instance.resource_version == version and
                    instance.resource_state == state):
                return instance
        time.sleep(0.03)
    raise TimeoutError(f"{key} never reached image v{version} {state}: {observed[-8:]!r}")


def forget_idle(gate: Gate, version: int) -> list[str]:
    attempts = []
    deadline = time.monotonic() + 5
    while time.monotonic() < deadline:
        result = gate.call(f"GATE_IMAGE_FORGET {version}",
                           f"image_forget_version={version}")
        attempts.append(result)
        if "rc=1" in result:
            return attempts
        if "rc=0" not in result:
            raise ValueError(f"forget returned unexpected status: {result}")
        time.sleep(0.1)
    # A 0 also means the entry was already absent. The subsequent fresh-decode
    # counter and loading state are the authority; do not fabricate eviction.
    return attempts


def system_edit_while_loading(session: GeneratedUiSession, hdc: gui.GuiHdc,
                              out: Path, origin: tuple[int, int], pid: str) -> dict[str, object]:
    instance = gui.accepted_editor(session.instances(), "editor", "name")
    point = gui.click_point(argparse.Namespace(
        screen_x=None, screen_y=None, xcomponent_offset_x=origin[0],
        xcomponent_offset_y=origin[1]), instance)
    before = image_normal._owner(session, "settings")
    replacement = "加载中验证" + uuid.uuid4().hex[:6]
    actions = []

    def action(command: str) -> None:
        hdc.shell(command)
        actions.append(command)
        time.sleep(1.0)

    loading_before = wait_image(session, 1, "loading")
    before_screen = image_normal._capture(hdc, out, "loading_before_edit", pid, "settings")
    action(f"uitest uiInput click {point['x']} {point['y']}")
    if before["value"]:
        action(f"uitest uiInput longClick {point['x']} {point['y']}")
        remote = f"/data/local/tmp/cjgui-image-menu-{uuid.uuid4().hex}.json"
        try:
            hdc.shell("uitest dumpLayout -p " + shlex.quote(remote))
            local = out / "loading_selection_menu.json"
            hdc.pull(remote, local)
            menu_x, menu_y = gui.selection.menu_point(
                json.loads(local.read_text(encoding="utf-8")))
            action(f"uitest uiInput click {menu_x} {menu_y}")
            action("uitest uiInput keyEvent 2055")
        finally:
            hdc.shell("rm -f " + shlex.quote(remote))
    action(f"uitest uiInput inputText {point['x']} {point['y']} " + shlex.quote(replacement))
    action("uitest uiInput keyEvent 2054")
    after = image_normal._owner(session, "settings")
    loading_after = wait_image(session, 1, "loading")
    after_screen = image_normal._capture(hdc, out, "loading_after_edit", pid, "settings")
    if after["value"] != replacement or after["version"] != before["version"] + 1:
        raise ValueError("loading-period system edit did not commit exact owner text")
    return {"before": before, "after": after, "click": point, "actions": actions,
            "screenshots": [before_screen.name, after_screen.name],
            "resource_before": asdict(loading_before),
            "resource_after": asdict(loading_after)}


def _stop_reopen(hdc: gui.GuiHdc, args: argparse.Namespace, out: Path,
                 old_token: str) -> dict[str, object]:
    baseline = stable_app_hilog(hdc, args.pid)
    own = restart.own_lines(baseline, args.pid)
    starts = [line for line in own if "startHost accepted:" in line]
    if not starts:
        raise ValueError("current test HAP has no startHost app instance")
    found = re.search(r"\bappInstance=(\d+)\b", starts[-1])
    if found is None:
        raise ValueError("current app instance id is missing")
    old_instance = int(found.group(1))
    hdc.shell(f"uitest uiInput click {args.stop_x} {args.stop_y}")
    deadline = time.monotonic() + 30
    last = ""
    while time.monotonic() < deadline:
        current = stable_app_hilog(hdc, args.pid)
        try:
            stop_tail = new_lifecycle_marker_tail(
                baseline, current, "verify stop host requested from UI")
            stop = restart.stop_proof(stop_tail, args.pid, old_instance)
            break
        except AssertionError as exc:
            last = str(exc)
            time.sleep(0.3)
    else:
        raise TimeoutError(f"loading STOP did not reach full zero: {last}")
    image_stop = require_bounded_stop_image(parse_stop_image_snapshot(stop_tail))
    if hdc.pidof("com.example.cjguiapp").strip() != args.pid:
        raise ValueError("STOP changed PID; same-PID restart cannot be claimed")
    stopped_lines = stable_app_hilog(hdc, args.pid)
    hdc.shell(f"uitest uiInput click {args.restart_x} {args.restart_y}")
    deadline = time.monotonic() + 30
    while time.monotonic() < deadline:
        current = stable_app_hilog(hdc, args.pid)
        try:
            restart_tail = new_lifecycle_marker_tail(
                stopped_lines, current, "verify restart host requested from UI")
            restarted = restart.restart_proof(
                restart_tail, args.pid, old_instance, old_token)
            break
        except AssertionError as exc:
            last = str(exc)
            time.sleep(0.3)
    else:
        raise TimeoutError(f"same-PID restart did not reach new first frame: {last}")
    if hdc.pidof("com.example.cjguiapp").strip() != args.pid:
        raise ValueError("RESTART changed PID")
    normal.write_json(out / "stop_reopen_proof.json",
                      {"stop": stop, "image_stop": image_stop, "restart": restarted})
    return {"stop": stop, "image_stop": image_stop, "restart": restarted}


def run(args: argparse.Namespace, hdc: gui.GuiHdc) -> dict[str, object]:
    out = Path(args.run_dir)
    out.mkdir(parents=True, exist_ok=False)
    try:
        result = _run(args, hdc, out)
        normal.write_json(out / "result.json", result)
        return result
    except Exception as exc:
        normal.write_json(out / "failure.json", {"error_type": type(exc).__name__,
                                                  "error": str(exc), "utc": normal.utc_now()})
        raise
    finally:
        normal.write_json(out / "hdc_commands.json", hdc.commands)


def _run(args: argparse.Namespace, hdc: gui.GuiHdc, out: Path) -> dict[str, object]:
    identity_raw = Path(args.identity).read_text(encoding="utf-8")
    hap = Path(args.hap)
    hap_sha = test_hap_identity(identity_raw, args.target, args.pid, hap)
    (out / "identity.raw.txt").write_text(identity_raw, encoding="utf-8")
    if hdc.pidof("com.example.cjguiapp").strip() != args.pid:
        raise ValueError("test HAP PID changed before probe")
    receipt = json.loads(Path(args.forward_receipt_json).read_text(encoding="utf-8"))
    normal._receipt(receipt, args.target, args.local_port, 7856)
    normal._forward_map(hdc.listing(), args.target, args.local_port, 7856)
    token = current_token(hdc, args.pid)
    gate = Gate(args.local_port, token, out)
    session, recorder = connect(args, out)
    first_endpoint = session.snapshot().endpoint
    if session.capabilities().image_resource("settings-beacon", 1) is None:
        raise ValueError("settings image v1 is absent from public capabilities")
    evidence = {"pid": args.pid, "target": args.target, "token": token,
                "hap": str(hap), "hap_sha256": hap_sha,
                "build_variant": "verify-transport+test-gates",
                "control_archive": gate.archive_file.name,
                "forward_receipt": receipt, "first_endpoint": asdict(first_endpoint)}

    # Exact stale-completion ordering: remove accepted v1 references, evict its
    # idle cache, arm native hold, begin a fresh v1 decode, accept ready v2, then
    # release the old v1 completion. The decoder remains free to process v2.
    submit(session, recorder, out, "initial_no_image", None, nodes=0)
    evidence["switch_to_v2_for_eviction"] = switch(session, 2)
    evidence["forget_v1"] = forget_idle(gate, 1)
    baseline = gate.stats()
    gate.call("GATE_IMAGE_HOLD 1", "held=1 rc=1")
    evidence["switch_back_to_v1"] = switch(session, 1)
    submit(session, recorder, out, "v1_held", 1)
    loading = wait_image(session, 1, "loading")
    awaiting = gate.stats()
    if (awaiting["decodeStarts"] <= baseline["decodeStarts"] or
            awaiting["awaiting"] < 1):
        raise ValueError("v1 was not freshly decoded and held in native completion")
    evidence["loading_edit"] = system_edit_while_loading(
        session, hdc, out, (args.xcomponent_screen_x, args.xcomponent_screen_y), args.pid)
    evidence["twenty_loading_reads"] = image_normal._twenty_contexts(
        session, "settings", out)
    evidence["switch_to_v2_while_old_held"] = switch(session, 2)
    submit(session, recorder, out, "v2_before_old_release", 2)
    ready_v2 = wait_image(session, 2, "ready")
    pre_release = gate.stats()
    gate.call("GATE_IMAGE_RELEASE 1", "held=0 rc=1")
    deadline = time.monotonic() + 8
    while time.monotonic() < deadline and gate.stats()["awaiting"] > 0:
        time.sleep(0.05)
    after_release = gate.stats()
    completion = require_held_image_completion(pre_release, after_release)
    still_v2 = wait_image(session, 2, "ready")
    image_normal._instance(session.instances(), "settings", 2)
    screen = image_normal._capture(hdc, out, "v2_after_v1_completion", args.pid, "settings")
    rect = (args.xcomponent_screen_x + still_v2.bounds[0],
            args.xcomponent_screen_y + still_v2.bounds[1], 160, 72)
    pixels = image_normal.inspect_palette(screen, rect, "settings", 2, "fill")
    if not pixels["pass"]:
        raise ValueError("late v1 completion changed accepted v2 pixels")
    evidence["late_completion"] = {"loading_v1": asdict(loading),
        "v2_before_release": asdict(ready_v2), "v2_after_release": asdict(still_v2),
        "stats_held": awaiting, "stats_before_release": pre_release,
        "stats_after_release": after_release, "completion_terminal": completion,
        "pixels": pixels}

    # Native candidate rejection keeps the old accepted image. A flush hold
    # binds the fail-next instruction to this candidate's real present ticket.
    old_structure = session.structure()
    old_image = wait_image(session, 2, "ready")
    owner_before_reject = image_normal._owner(session, "settings")
    gate.call("GATE_FLUSH_HOLD_30000", "flush_hold=0")
    rejected_payload = image_candidate(2, nodes=2)
    rejected_submit = session.submit_text(rejected_payload, old_structure.version)
    gate.call("GATE_REJECT_NEXT", "armed_now=1")
    gate.call("GATE_CLEAR", "cleared=")
    rejected_wait = session.wait_for_candidate_result(rejected_submit.ticket(),
                                                       timeout_ms=8000, poll_ms=30)
    rejected = rejected_wait.last_state
    if rejected_wait.outcome != "terminal":
        raise ValueError("native candidate rejection did not reach a terminal ticket")
    owner_after_reject = image_normal._owner(session, "settings")
    require_native_image_rejection(rejected, old_structure, session.structure(),
                                   owner_before_reject, owner_after_reject)
    retained = wait_image(session, 2, "ready")
    if (retained.resource != old_image.resource or
            retained.resource_version != old_image.resource_version or
            retained.bounds != old_image.bounds):
        raise ValueError("native rejection changed the accepted image binding")
    reject_screen = image_normal._capture(hdc, out, "native_reject_retained",
                                          args.pid, "settings")
    reject_rect = (args.xcomponent_screen_x + retained.bounds[0],
                   args.xcomponent_screen_y + retained.bounds[1], 160, 72)
    reject_pixels = image_normal.inspect_palette(reject_screen, reject_rect,
                                                 "settings", 2, "fill")
    if not reject_pixels["pass"]:
        raise ValueError("native rejection did not retain the old image pixels")
    evidence["native_reject"] = {"ticket": asdict(rejected),
                                 "accepted_version": old_structure.version,
                                 "owner_before": owner_before_reject,
                                 "owner_after": owner_after_reject,
                                 "accepted_image_before": asdict(old_image),
                                 "accepted_image_after": asdict(retained),
                                 "screenshot": reject_screen.name,
                                 "pixels": reject_pixels}
    reuse_baseline = gate.stats()
    recovered = submit(session, recorder, out, "two_shared_images", 2, nodes=2)
    first = wait_image(session, 2, "ready", key="icon")
    second = wait_image(session, 2, "ready", key="icon2")
    shared_stats = gate.stats()
    submit(session, recorder, out, "one_shared_image", 2, nodes=1)
    remaining = wait_image(session, 2, "ready", key="icon")
    one_stats = gate.stats()
    one_screen = image_normal._capture(hdc, out, "one_shared_image", args.pid, "settings")
    one_rect = (args.xcomponent_screen_x + remaining.bounds[0],
                args.xcomponent_screen_y + remaining.bounds[1], 160, 72)
    one_pixels = image_normal.inspect_palette(one_screen, one_rect, "settings", 2, "fill")
    if not one_pixels["pass"] or one_stats["residentBytes"] <= 0:
        raise ValueError("removing one shared node released the remaining image")
    reuse_proof = require_shared_image_reuse(reuse_baseline, shared_stats, one_stats)
    submit(session, recorder, out, "remove_both_shared_images", None, nodes=0)
    removed_instances = session.instances()
    if (removed_instances.instance("icon") is not None or
            removed_instances.instance("icon2") is not None):
        raise ValueError("removed generated image nodes remain publicly visible")
    removed_resources = wait_for_bounded_image_idle(gate)
    evidence["shared_nodes"] = {"accepted": recovered, "first": asdict(first),
        "second": asdict(second), "remaining": asdict(remaining),
        "reuse_baseline": reuse_baseline, "reuse_proof": reuse_proof,
        "two_stats": shared_stats, "one_stats": one_stats,
        "after_removal_bounded": removed_resources, "one_pixels": one_pixels}

    # Loading -> STOP -> same PID reopen: no old held completion may be
    # published into the new owner/Surface generation.
    evidence["forget_v1_before_stop"] = forget_idle(gate, 1)
    gate.call("GATE_IMAGE_HOLD 1", "held=1 rc=1")
    evidence["switch_to_v1_before_stop"] = switch(session, 1)
    submit(session, recorder, out, "loading_before_stop", 1)
    wait_image(session, 1, "loading")
    old_endpoint = session.snapshot().endpoint
    evidence["stop_reopen"] = _stop_reopen(hdc, args, out, token)
    new_token = current_token(hdc, args.pid)
    if new_token == token:
        raise ValueError("same-PID restart reused old verify token")
    new_session, new_recorder = connect(args, out)
    new_endpoint = new_session.snapshot().endpoint
    if new_endpoint == old_endpoint:
        raise ValueError("same-PID restart reused old public endpoint")
    submit(new_session, new_recorder, out, "after_reopen", 1)
    reopened = wait_image(new_session, 1, "ready")
    evidence["new_owner_image"] = {"new_token": new_token,
        "old_endpoint": asdict(old_endpoint), "new_endpoint": asdict(new_endpoint),
        "accepted_image": asdict(reopened)}
    new_gate = Gate(args.local_port, new_token, out)
    bounded_after_reopen = wait_for_bounded_image_idle(new_gate)
    evidence["native_stats_final"] = {key: bounded_after_reopen[key] for key in STATS}
    evidence["native_stats_ext_final"] = {key: bounded_after_reopen[key] for key in STATS_EXT}
    evidence["bounded_after_reopen"] = bounded_after_reopen
    evidence["new_control_archive"] = new_gate.archive_file.name
    normal.write_json(out / "gate_dispatches.json", gate.rows)
    return {"status": "passed", **evidence}


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--target", required=True)
    parser.add_argument("--local-port", type=int, required=True)
    parser.add_argument("--capability", required=True)
    parser.add_argument("--caller", default="image-interleaving-probe")
    parser.add_argument("--pid", required=True)
    parser.add_argument("--hap", type=Path, required=True)
    parser.add_argument("--identity", type=Path, required=True)
    parser.add_argument("--forward-receipt-json", type=Path, required=True)
    parser.add_argument("--xcomponent-screen-x", type=int, required=True)
    parser.add_argument("--xcomponent-screen-y", type=int, required=True)
    parser.add_argument("--stop-x", type=int, required=True)
    parser.add_argument("--stop-y", type=int, required=True)
    parser.add_argument("--restart-x", type=int, required=True)
    parser.add_argument("--restart-y", type=int, required=True)
    parser.add_argument("--run-dir", type=Path, required=True)
    parser.add_argument("--hdc", default=normal.DEFAULT_HDC)
    return parser.parse_args(argv)


def main(argv: list[str]) -> int:
    args = parse_args(argv)
    try:
        result = run(args, gui.GuiHdc(args.hdc, args.target))
    except Exception as exc:
        print(f"image interleavings failed: {type(exc).__name__}: {exc}", file=sys.stderr)
        return 2
    print(json.dumps({"status": result["status"], "run_dir": str(args.run_dir)},
                     ensure_ascii=False))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))

#!/usr/bin/env python3
"""Thermo normal-HAP same-key rebind across one observed held touch.

Requires a running isolated .htouch normal HAP and an owned forward. Never
installs, launches, restarts, or creates a forward. Missing phase evidence is
not_observed, never successful cancellation.
"""
from __future__ import annotations

import argparse
from dataclasses import asdict
import hashlib
import json
from pathlib import Path
import subprocess
import sys
import time

import verify_normal_generated_consumption as normal
import verify_normal_generated_viewport_continuity as gen
import verify_normal_touch_interleaving as touch
from cjgui_generated_client import GeneratedUiSession

RESOURCE = 9801
BUNDLE = "com.example.cjguithermo.htouch"
OLD_LINE = "NODE 3 trigger action action=TEMP_UP\n"
NEW_LINE = "NODE 3 trigger action action=TEMP_DOWN\n"


def rebind_candidate(v1: str) -> str:
    if v1.count(OLD_LINE) != 1:
        raise ValueError("candidate needs exactly one depth-3 TEMP_UP trigger")
    before = normal.candidate_nodes(v1)
    if len({n.key for n in before}) != len(before):
        raise ValueError("duplicate candidate key")
    if len([n for n in before if n.key == "trigger" and n.kind == "action" and
            n.action == "TEMP_UP" and n.depth == 3]) != 1:
        raise ValueError("trigger binding is ambiguous")
    if len([n for n in before if n.key == "editor" and n.kind == "textInput" and
            n.field_id == "note" and n.depth == 3]) != 1:
        raise ValueError("thermo note editor is absent")
    if len([n for n in before if n.key == "viewport" and n.kind == "scrollArea"]) != 1:
        raise ValueError("scroll viewport is absent")
    changed = v1.replace(OLD_LINE, NEW_LINE)
    after = normal.candidate_nodes(changed)
    left = [(n.depth, n.key, n.kind, n.field_id, n.action) for n in before]
    right = [(n.depth, n.key, n.kind, n.field_id, n.action) for n in after]
    expected = [(d, k, kind, field, "TEMP_DOWN" if k == "trigger" else action)
                for d, k, kind, field, action in left]
    if right != expected:
        raise ValueError("candidate changed another node binding")
    return changed


def exact_touch(stage: dict, pid: str, previous_epoch: int | None = None) -> bool:
    begin, terminal = stage.get("begin"), stage.get("terminal")
    if not isinstance(begin, dict) or not isinstance(terminal, dict):
        return False
    try:
        epoch = int(begin["epoch"])
        return (str(begin["pid"]) == pid == str(terminal["pid"]) and
                epoch > 0 and epoch == int(terminal["epoch"]) and
                epoch != previous_epoch and begin["action"] == 37 and
                terminal["action"] == 39 and
                ("at_ns" not in begin or "at_ns" not in terminal or
                 begin["at_ns"] <= terminal["at_ns"]))
    except (KeyError, TypeError, ValueError):
        return False


def evaluate(evidence: dict) -> dict:
    pid = str(evidence["pid"])
    positive, old, new = evidence["positive"], evidence["rebind"], evidence["new"]
    def result(status, reason):
        return {"status": status, "reason": reason}
    if not exact_touch(positive, pid):
        return result("not_observed", "positive_exact_touch")
    p0, p1 = positive["before"], positive["after"]
    if (p1["version"] != p0["version"] + 1 or p1["temp"] != p0["temp"] + 1 or
            p1["note"] != p0["note"]):
        return result("not_observed", "positive_control_did_not_activate_once")
    if (old.get("ticket_terminal_state") != "ACCEPTED" or
            old.get("scene_state") != "scene_accepted" or
            not isinstance(old.get("candidate_version"), int) or
            old["candidate_version"] <= 0 or
            old.get("candidate_version") != old.get("accepted_version")):
        return result("not_observed", "rebind_not_scene_accepted")
    if (not old.get("begin_before_submit") or
            not old.get("terminal_absent_at_acceptance") or
            not old.get("process_running_at_acceptance") or
            not exact_touch(old, pid, int(positive["begin"]["epoch"]))):
        return result("not_observed", "begin_accept_end_crossing")
    if old["before"] != p1:
        return result("not_observed", "owner_baseline_changed_before_rebind")
    if old["after"] != old["before"]:
        return result("fail", "old_gesture_changed_owner_after_rebind")
    if new["before"] != old["after"]:
        return result("not_observed", "owner_baseline_changed_before_new_click")
    if not exact_touch(new, pid, int(old["begin"]["epoch"])):
        return result("not_observed", "new_exact_touch")
    n0, n1 = new["before"], new["after"]
    if (n1["version"] != n0["version"] + 1 or n1["temp"] != n0["temp"] - 1 or
            n1["note"] != n0["note"]):
        return result("fail", "new_temp_down_not_exactly_once")
    return result("pass", "observed_same_pid_begin_accept_end_and_exact_owner")


def save(path: Path, value: object) -> None:
    normal.write_json(path, value)


def owner(session, out: Path, label: str) -> dict:
    response = session.client.get_context([RESOURCE])
    note = normal.parse_owner(response, "note", RESOURCE)
    value = {"version": note["version"], "temp": gen.public_integer(response, RESOURCE, "targetTemp"),
             "note": note["value"]}
    save(out / f"owner_{label}.json", {"parsed": value, "raw": response.raw})
    return value


def stage_state(session, hdc, checked, out: Path, label: str) -> None:
    save(out / f"binding_{label}.json", checked())
    snapshot = session.snapshot()
    instances = session.instances()
    interaction = session.client.get_window_interaction()
    save(out / f"scene_{label}.json", {"snapshot": asdict(snapshot),
         "instances": asdict(instances), "window_interaction_raw": interaction.raw})


def touch_rows(hdc, out: Path, label: str, pid: str) -> list[dict]:
    raw = touch.capture_hilog(hdc, pid, "raw touch action=")
    (out / f"touch_{label}.raw.txt").write_text(raw, encoding="utf-8")
    return touch.parse_touch_rows(raw, pid, time.monotonic_ns())


def fresh_begin(rows: list[dict], known: set[int]) -> dict | None:
    fresh = [r for r in rows if r["action"] == 37 and r["epoch"] not in known]
    return fresh[0] if len(fresh) == 1 else None


def terminal(rows: list[dict], begin: dict | None) -> dict | None:
    if begin is None:
        return None
    matches = [r for r in rows if r["pid"] == begin["pid"] and
               r["epoch"] == begin["epoch"] and r["action"] in (39, 40)]
    return matches[0] if len(matches) == 1 else None


def point(session, hdc, out, args, pid, checked, label, action):
    action_args = argparse.Namespace(**vars(args))
    action_args.action = action
    trigger, viewport, origin, history = gen._scroll_trigger_into_view(
        session, hdc, out, action_args, pid, checked, label)
    if not trigger.visible or gen._vertical_overflow(trigger, viewport):
        raise ValueError("accepted trigger outside viewport")
    xy = gen._screen_point(trigger, origin)
    save(out / f"point_{label}.json", {"action": action, "point": xy,
         "trigger": asdict(trigger), "viewport": asdict(viewport),
         "origin": origin, "scroll_history": history})
    return xy


def submit(session, out, label, payload, args):
    value = gen._submit(session, None, payload, args.wait_ms, args.poll_ms, expect_accept=True)
    save(out / f"submit_{label}.json", value)
    return value


def observed_input(hdc, out, args, pid, checked, label, command):
    before = touch_rows(hdc, out, f"{label}_before", pid)
    stdout = gen._ui_input(hdc, out, args, pid, checked, label, command)
    save(out / f"uitest_{label}.json", {"command": command, "stdout": stdout})
    after = touch_rows(hdc, out, f"{label}_after", pid)
    begin = fresh_begin(after, {r["epoch"] for r in before})
    return begin, terminal(after, begin)


def held_rebind(hdc, session, out, args, pid, checked, candidate, xy, recorder, known):
    command = [args.hdc, "-t", args.target, "shell",
               f"uitest uiInput longClick {xy[0]} {xy[1]}"]
    checked()
    gen._layout(hdc, out, "pre_ui_rebind_long_click", pid, args.bundle)
    process = {"command": command, "started_ns": time.monotonic_ns()}
    proc = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    begin = None
    acceptance = None
    at_acceptance = []
    running_at_acceptance = False
    submit_started_ns = None
    try:
        deadline = time.monotonic() + args.begin_timeout_seconds
        while time.monotonic() < deadline and proc.poll() is None:
            rows = touch_rows(hdc, out, "rebind_poll", pid)
            begin = fresh_begin(rows, known)
            if begin:
                break
            time.sleep(args.poll_seconds)
        if begin is not None and proc.poll() is None:
            checked()
            submit_started_ns = time.monotonic_ns()
            recorder.phase = "rebind_after_observed_begin"
            try:
                acceptance = submit(session, out, "rebind", candidate, args)
            except Exception as exc:
                save(out / "submit_rebind_error.json", {"error_type": type(exc).__name__,
                     "error": str(exc)})
            finally:
                at_acceptance = touch_rows(hdc, out, "rebind_acceptance", pid)
                running_at_acceptance = proc.poll() is None
        try:
            stdout, stderr = proc.communicate(timeout=args.long_click_timeout_seconds)
        except subprocess.TimeoutExpired:
            proc.terminate()
            stdout, stderr = proc.communicate(timeout=2)
            process["timed_out"] = True
        process.update({"returncode": proc.returncode, "stdout": stdout,
                        "stderr": stderr, "ended_ns": time.monotonic_ns()})
    finally:
        if proc.poll() is None:
            proc.terminate()
            stdout, stderr = proc.communicate(timeout=2)
            process.update({"returncode": proc.returncode, "stdout": stdout,
                            "stderr": stderr, "ended_ns": time.monotonic_ns()})
        save(out / "uitest_rebind_long_click.json", process)
    final = touch_rows(hdc, out, "rebind_final", pid)
    waited = (acceptance or {}).get("wait", {}).get("last_state") or {}
    ticket = (acceptance or {}).get("ticket", {})
    record = {"begin": begin, "terminal": terminal(final, begin),
              "begin_before_submit": bool(begin and submit_started_ns and begin["at_ns"] < submit_started_ns),
              "terminal_absent_at_acceptance": bool(begin and
                  any(r["epoch"] == begin["epoch"] and r["action"] == 37 for r in at_acceptance) and
                  terminal(at_acceptance, begin) is None),
              "process_running_at_acceptance": running_at_acceptance,
              "ticket_terminal_state": waited.get("terminal_state"),
              "scene_state": waited.get("scene_state"),
              "candidate_version": ticket.get("candidate_version"),
              "accepted_version": waited.get("accepted_version"),
              "process": process}
    save(out / "rebind_timing.json", record)
    return record


def run(args, hdc):
    if args.bundle != BUNDLE:
        raise ValueError("this business probe requires the isolated thermo .htouch bundle")
    if not (0.05 <= args.begin_timeout_seconds <= 5 and
            1 <= args.long_click_timeout_seconds <= 10 and 0.01 <= args.poll_seconds <= 0.5):
        raise ValueError("held-touch bounds invalid")
    if hashlib.sha256(args.hap.read_bytes()).hexdigest() != args.hap_sha256:
        raise ValueError("HAP SHA mismatch")
    identity_raw = args.identity.read_text(encoding="utf-8")
    pid = normal._identity(identity_raw, args.target, args.hap)
    if pid != args.pid:
        raise ValueError("explicit PID differs from normal HAP identity")
    receipt_raw = args.forward_receipt_json.read_text(encoding="utf-8")
    receipt = json.loads(receipt_raw)
    v1 = args.candidate.read_text(encoding="utf-8")
    changed = rebind_candidate(v1)
    args.run_dir.mkdir(parents=True, exist_ok=False)
    out = args.run_dir
    (out / "identity.raw.txt").write_text(identity_raw, encoding="utf-8")
    (out / "forward_receipt.raw.json").write_text(receipt_raw, encoding="utf-8")
    (out / "candidate_v1.raw.txt").write_text(v1, encoding="utf-8")
    (out / "candidate_rebound.raw.txt").write_text(changed, encoding="utf-8")
    save(out / "input.json", {k: str(v) for k, v in vars(args).items() if k != "capability"})
    def checked():
        return gen._check_binding(args, hdc, pid, receipt)
    try:
        save(out / "binding_preflight.json", checked())
        recorder = normal.ExchangeRecorder(out / "exchanges.jsonl")
        session = GeneratedUiSession.connect_forwarded_tcp(
            target=args.target, local_port=args.local_port, device_port=args.device_port,
            capability=args.capability, caller=args.caller)
        session.client = normal.RecordingClient(session.client.descriptor,
            session.client.fragment_bytes, session.client, recorder)
        caps = session.capabilities()
        if caps.action("TEMP_UP") is None or caps.action("TEMP_DOWN") is None:
            raise ValueError("thermo actions unavailable")
        field = caps.field("note")
        if field is None or field.resource_id != RESOURCE or not field.callable:
            raise ValueError("thermo note public field unavailable")
        start = owner(session, out, "start")
        if not 16 <= start["temp"] <= 29:
            raise ValueError("targetTemp outside safe positive-control range 16..29")
        recorder.phase = "candidate_v1"
        submit(session, out, "v1", v1, args)
        stage_state(session, hdc, checked, out, "v1")
        xy = point(session, hdc, out, args, pid, checked, "positive", "TEMP_UP")
        p0 = owner(session, out, "positive_before")
        stage_state(session, hdc, checked, out, "positive_before")
        recorder.phase = "positive_long_click"
        begin, end = observed_input(hdc, out, args, pid, checked, "positive",
                                    f"uitest uiInput longClick {xy[0]} {xy[1]}")
        p1 = owner(session, out, "positive_after")
        stage_state(session, hdc, checked, out, "positive_after")
        positive = {"before": p0, "after": p1, "begin": begin, "terminal": end}
        save(out / "positive.json", positive)
        if not exact_touch(positive, pid) or p1 != {"version": p0["version"] + 1,
                                                  "temp": p0["temp"] + 1, "note": p0["note"]}:
            result = {"status": "not_observed", "reason": "positive_control_did_not_activate_once"}
            save(out / "result.json", result)
            return result
        xy = point(session, hdc, out, args, pid, checked, "rebind", "TEMP_UP")
        old_before = owner(session, out, "rebind_before")
        stage_state(session, hdc, checked, out, "rebind_before")
        known = {r["epoch"] for r in touch_rows(hdc, out, "rebind_before", pid)}
        old = held_rebind(hdc, session, out, args, pid, checked, changed, xy, recorder, known)
        old["before"] = old_before
        old["after"] = owner(session, out, "rebind_after")
        stage_state(session, hdc, checked, out, "rebind_after")
        timing = {"pid": pid, "positive": positive, "rebind": old,
                  "new": {"before": old["after"], "after": old["after"]}}
        temporal = evaluate(timing)
        if old["ticket_terminal_state"] != "ACCEPTED":
            result = temporal
        elif old["after"] != old_before:
            result = temporal
        else:
            xy = point(session, hdc, out, args, pid, checked, "new", "TEMP_DOWN")
            n0 = owner(session, out, "new_before")
            stage_state(session, hdc, checked, out, "new_before")
            recorder.phase = "new_temp_down_click"
            begin, end = observed_input(hdc, out, args, pid, checked, "new",
                                        f"uitest uiInput click {xy[0]} {xy[1]}")
            new = {"before": n0, "after": owner(session, out, "new_after"),
                   "begin": begin, "terminal": end}
            stage_state(session, hdc, checked, out, "new_after")
            save(out / "new.json", new)
            result = evaluate({"pid": pid, "positive": positive, "rebind": old, "new": new})
        save(out / "result.json", result)
        return result
    except Exception as exc:
        save(out / "failure.json", {"error_type": type(exc).__name__, "error": str(exc)})
        raise
    finally:
        save(out / "commands.json", hdc.commands)


def parse_args(argv):
    p = argparse.ArgumentParser(description=__doc__)
    for name in ("target", "bundle", "pid", "hap_sha256", "capability", "caller"):
        p.add_argument("--" + name.replace("_", "-"), required=True)
    for name in ("hap", "identity", "forward_receipt_json", "candidate", "run_dir"):
        p.add_argument("--" + name.replace("_", "-"), type=Path, required=True)
    p.add_argument("--local-port", type=int, required=True)
    p.add_argument("--device-port", type=int, required=True)
    p.add_argument("--hdc", default=normal.DEFAULT_HDC)
    p.add_argument("--wait-ms", type=int, default=3000)
    p.add_argument("--poll-ms", type=int, default=20)
    p.add_argument("--begin-timeout-seconds", type=float, default=2.0)
    p.add_argument("--long-click-timeout-seconds", type=float, default=5.0)
    p.add_argument("--poll-seconds", type=float, default=0.05)
    p.add_argument("--settle-seconds", type=float, default=0.2)
    return p.parse_args(argv)


def main(argv):
    args = parse_args(argv)
    try:
        result = run(args, gen.Hdc(args.hdc, args.target))
    except Exception as exc:
        print(f"normal touch rebind failed: {type(exc).__name__}: {exc}", file=sys.stderr)
        return 2
    print(json.dumps({"status": result["status"], "reason": result["reason"],
                      "run_dir": str(args.run_dir)}))
    return 0 if result["status"] == "pass" else 1


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))

#!/usr/bin/env python3
"""One normal-HAP, real-swipe/public-write interleaving acceptance probe.

The caller supplies a running normal application, exact HAP/PID identity and a
forward creation receipt. This probe only reads the forward and drives one
bounded UITest swipe. It never installs, launches, restarts or owns a forward.
Every failed or unobservable gate remains visible in result.json.
"""

from __future__ import annotations

import argparse
from dataclasses import asdict
import hashlib
import json
import math
from pathlib import Path
import re
import shlex
import subprocess
import sys
import threading
import time
import uuid

import verify_normal_generated_consumption as normal
import verify_normal_image_consumption as image
from cjgui_generated_client import GeneratedUiSession


TOUCH = re.compile(r"raw touch action=(\d+) .*?ep=(\d+)")
SCROLL_TERMINAL = re.compile(
    r"gesture-scroll-terminal terminal=(END|CANCEL) app=(\d+) comp=(\d+) "
    r"surface=(\d+) pointer=(-?\d+) epoch=(\d+) samples=(\d+) "
    r"rawDy=(\S+) whole=(-?\d+) remainder=(\S+)")
VIEWPORT = re.compile(r"^WINDOW_VIEWPORT (\S+) offset=(-?\d+) accepted=(-?\d+) "
                      r"content=(\d+) viewport=(\d+) pending=([01]) solves=(\d+)$")
SAFE = {
    "settings": ("com.example.cjguiapp", "INCREMENT", 9700, "count", "name", 99),
    "thermo": ("com.example.cjguithermo", "TEMP_UP", 9801, "targetTemp", "note", 30),
}
IMAGE_KEYS = {"settings": "settings-beacon", "thermo": "thermo-heat-map"}


def matches_safe_contract(args) -> bool:
    expected = SAFE[args.app]
    allowed_bundles = (expected[0], expected[0] + ".htouch")
    return (args.bundle in allowed_bundles and
            (args.action, args.resource_id, args.numeric_field, args.field) == expected[1:5])


def generated_readiness(ready: bool | None, resource_count: int | None) -> str:
    if resource_count == 0 and ready is None:
        return "not_applicable"
    if ready is True:
        return "ready"
    if ready is False:
        return "not_ready"
    return "not_observed"


def evaluate(evidence: dict) -> dict:
    """Pure gate. Touch times are monotonic observation times, not device timestamps."""
    failures: list[str] = []
    missing: list[str] = []
    readiness: list[dict[str, str]] = []
    pid, epoch = str(evidence["pid"]), int(evidence["gesture_epoch"])
    touches = [row for row in evidence["touch"]
               if str(row["pid"]) == pid and int(row["epoch"]) == epoch]
    begins = [row["at_ns"] for row in touches if row["action"] == 37]
    ends = [row["at_ns"] for row in touches if row["action"] in (39, 40)]
    clocks_known = (len(begins) == 1 and len(ends) == 1 and
                    isinstance(begins[0], int) and isinstance(ends[0], int))
    if len(begins) != 1 or len(ends) != 1:
        failures.append("exact_pid_epoch_begin_terminal")
    elif not clocks_known:
        missing.append("touch_observation_clock")
    elif begins[0] >= ends[0]:
        failures.append("exact_pid_epoch_begin_terminal")
    for index, row in enumerate(evidence["writes"]):
        prefix = f"write_{index + 1}"
        if (not row["swipe_running_at_start"] or
                (clocks_known and not
                 (begins[0] < row["started_ns"] <= row["ended_ns"] < ends[0]))):
            failures.append(prefix + "_outside_live_swipe")
        before, after = row["before_owner"], row["after_owner"]
        try:
            delta = int(after["value"]) - int(before["value"])
        except (ValueError, KeyError, TypeError):
            delta = None
        if (row["result_kind"] != "RESULT" or row["applied"] is not True or
                after["version"] != before["version"] + 1 or delta != 1):
            failures.append(prefix + "_owner_exact_delta")
        old, new = row["before_scene"], row["after_scene"]
        if (old["endpoint"] != new["endpoint"] or
                old["structure"] != new["structure"] or
                new["accepted"] <= old["accepted"] or
                new["pending"] is not False):
            failures.append(prefix + "_accepted_scene")
        renderer_ready = row.get("renderer_image_settled", {})
        if renderer_ready.get("status") == "fail":
            failures.append(prefix + "_renderer_image_settled")
        elif renderer_ready.get("status") != "observed":
            missing.append(prefix + "_renderer_image_settled")
        before_ready = generated_readiness(
            row["ready_before"], row.get("generated_image_resource_count_before"))
        after_ready = generated_readiness(
            row["ready_after"], row.get("generated_image_resource_count_after"))
        readiness.append({"before": before_ready, "after": after_ready})
        if "not_ready" in (before_ready, after_ready):
            failures.append(prefix + "_generated_image_ready")
        elif "not_observed" in (before_ready, after_ready):
            missing.append(prefix + "_generated_image_ready")
        left, right = row["before_viewport"], row["after_viewport"]
        if left is None or right is None:
            missing.append(prefix + "_viewport")
        elif (right["pending"] != 0 or right["offset"] != right["accepted"] or
              right["solves"] < left["solves"] or
              right["offset"] == left["offset"]):
            failures.append(prefix + "_offset_or_idle")
        # Absolute same-PID frame counters remain valid when the bounded hilog
        # window lost the before frame; deltas in that case stay unobserved.
        cost = row.get("image_cost_absolute") or row.get("image_cost") or {}
        for key, limit in (("peak_tracked_bytes", 128 * 1024 * 1024),
                           ("idle_cache_bytes", 16 * 1024 * 1024),
                           ("in_flight", 8)):
            measured = cost.get(key)
            if not isinstance(measured, int):
                missing.append(prefix + "_" + key)
            elif measured > limit:
                failures.append(prefix + "_" + key + "_budget")
    final = evidence.get("final_viewport")
    if final is None:
        missing.append("final_viewport")
    elif final["pending"] != 0 or final["offset"] != final["accepted"]:
        failures.append("terminal_idle")
    final_scene = evidence.get("final_scene")
    if final_scene is None:
        missing.append("final_scene")
    elif final_scene["pending"] is not False:
        failures.append("terminal_scene_pending")
    final_renderer = evidence.get("final_renderer_image_settled", {})
    if final_renderer.get("status") == "fail":
        failures.append("terminal_renderer_image_settled")
    elif final_renderer.get("status") != "observed":
        missing.append("terminal_renderer_image_settled")
    final_ready = generated_readiness(
        evidence.get("final_ready"), evidence.get("final_generated_image_resource_count"))
    if final_ready == "not_ready":
        failures.append("terminal_generated_image_not_ready")
    elif final_ready == "not_observed":
        missing.append("terminal_generated_image_ready")
    terminal = evidence.get("scroll_terminal") or {"status": "not_observed"}
    scroll_failures: list[str] = []
    sample_assessment = assess_swipe_samples(
        evidence.get("swipe_samples", []), pid, epoch,
        baseline_image_frame_lines=evidence.get("image_cost_baseline_lines"))
    lease = evidence.get("image_lease") or {"status": "not_observed"}
    sampling_missing = []
    sampling_failures: list[str] = []
    if lease.get("status") == "fail":
        sampling_failures.extend("image_lease_" + reason for reason in lease.get("failures", []))
        if not lease.get("failures"):
            sampling_failures.append("image_lease_failed")
    elif lease.get("status") != "observed":
        sampling_missing.append("exact_image_lease")
    sampling_missing.extend(sample_assessment["not_observed"])
    float_remainder: float | str = "not_observed"
    displacement = {"requested_delta": "not_observed",
                    "accepted_delta": "not_observed",
                    "comparison": "not_observed"}
    if terminal.get("status") == "observed":
        key = terminal.get("gesture_key", {})
        if (str(terminal.get("pid")) != pid or key.get("epoch") != epoch or
                any(not isinstance(key.get(field), int) or key[field] <= 0
                    for field in ("app", "comp", "surface")) or
                not isinstance(key.get("pointer"), int) or key["pointer"] < 0):
            scroll_failures.append("scroll_terminal_exact_gesture_key")
        raw_dy, remainder = terminal.get("raw_dy"), terminal.get("remainder")
        whole, samples = terminal.get("whole"), terminal.get("samples")
        if (terminal.get("terminal") != "END" or
                not isinstance(samples, int) or samples <= 0):
            scroll_failures.append("scroll_terminal_end_and_samples")
        if (not isinstance(raw_dy, (int, float)) or not math.isfinite(raw_dy) or
                not isinstance(remainder, (int, float)) or not math.isfinite(remainder) or
                not isinstance(whole, int) or abs(remainder) >= 1.000001):
            scroll_failures.append("scroll_terminal_finite_remainder")
        else:
            float_remainder = remainder
            if isinstance(samples, int) and samples > 0 and abs(raw_dy - whole - remainder) > max(0.0001, samples * 0.00001):
                scroll_failures.append("scroll_terminal_raw_whole_remainder")
            initial = evidence["writes"][0]["before_viewport"] if evidence["writes"] else None
            if initial is not None and final is not None:
                accepted_delta = final["accepted"] - initial["accepted"]
                requested_delta = -whole  # renderer scroll intent reverses raw Y
                comparison = "not_applicable_clamp_or_unproven_path"
                if evidence.get("unclipped_monotonic_swipe") is True:
                    comparison = ("matched_unclipped" if accepted_delta == requested_delta
                                  else "mismatch_unclipped")
                    if comparison == "mismatch_unclipped":
                        scroll_failures.append("scroll_terminal_unclipped_offset")
                displacement = {"requested_delta": requested_delta,
                                "accepted_delta": accepted_delta,
                                "comparison": comparison}
    else:
        sampling_missing.insert(0, "float_remainder")
    failures.extend(scroll_failures)
    sampling_failures.extend(scroll_failures)
    return {"status": "fail" if failures else "incomplete" if missing else "pass",
            "failures": failures, "not_observed": missing,
            "generated_image_readiness": readiness,
            "final_generated_image_readiness": final_ready,
            "scroll_terminal": terminal, "scroll_displacement": displacement,
            "swipe_sample_assessment": sample_assessment,
            "float_remainder": float_remainder,
            "exact_image_lease": lease if evidence.get("image_lease") is not None else "not_observed",
            # The interleaving gate above is narrower than D's per-sample cost
            # requirement. Keep its result, but expose the missing measurements.
            "sampling_status": "fail" if sampling_failures else
                "incomplete" if sampling_missing else "pass",
            "sampling_failures": sampling_failures,
            "sampling_not_observed": sampling_missing}


def parse_viewport(raw: str, semantic: str) -> dict | None:
    matches = [match for line in raw.splitlines()
               if (match := VIEWPORT.fullmatch(line[line.find("WINDOW_VIEWPORT "):])
                   if "WINDOW_VIEWPORT " in line else None) and match.group(1) == semantic]
    if not matches:
        return None
    _, offset, accepted, content, viewport, pending, solves = matches[-1].groups()
    return {"offset": int(offset), "accepted": int(accepted), "content": int(content),
            "viewport": int(viewport), "pending": int(pending), "solves": int(solves)}


def parse_touch_rows(raw: str, pid: str, observed_ns: int) -> list[dict]:
    rows = []
    for line in raw.splitlines():
        match = image.PID_LINE.match(line)
        touch = TOUCH.search(line)
        if match and match.group(1) == pid and touch:
            rows.append({"pid": pid, "action": int(touch.group(1)),
                         "epoch": int(touch.group(2)), "at_ns": observed_ns,
                         "raw": line})
    return rows


def sample_swipe_once(pid: str, epoch: int, viewport_key: str,
                      read_touch, read_public_viewport, read_image_cost, *,
                      hand_semantic: str | None = None, read_hand_viewport=None,
                      read_image_lease=None,
                      clock_ns=time.monotonic_ns) -> dict:
    """One bounded host observation; each source remains raw and separately timed."""
    started = clock_ns()
    errors = {}

    def read(name, source):
        try:
            return source()
        except Exception as exc:
            errors[name] = f"{type(exc).__name__}: {exc}"
            return ""

    touch_raw = read("touch", read_touch)
    touch_ns = clock_ns()
    viewport_raw = read("public_viewport", read_public_viewport)
    viewport = parse_viewport(viewport_raw, viewport_key)
    hand_raw = ""
    if viewport is None and hand_semantic is not None and read_hand_viewport is not None:
        hand_raw = read("hand_viewport", read_hand_viewport)
        viewport = parse_viewport(hand_raw, hand_semantic)
    viewport_ns = clock_ns()
    cost_raw = read("image_cost", read_image_cost)
    lease_raw = read("image_lease", read_image_lease) if read_image_lease else ""
    finished = clock_ns()
    phases = [row for row in parse_touch_rows(touch_raw, str(pid), touch_ns)
              if row["epoch"] == epoch]
    frame = same_pid_image_frame_evidence(cost_raw, str(pid))
    return {"host_start_ns": started, "touch_observed_ns": touch_ns,
            "viewport_observed_ns": viewport_ns, "image_cost_observed_ns": finished,
            "host_finish_ns": finished,
            "touch_phase": phases[-1] if phases else None,
            "viewport": viewport, "image_cost_frame": frame["frame"] if frame else None,
            "image_cost_frame_lines": frame["lines"] if frame else None,
            "image_lease_raw": lease_raw,
            "touch_raw": touch_raw, "viewport_raw": viewport_raw,
            "hand_viewport_raw": hand_raw, "image_cost_raw": cost_raw,
            "errors": errors}


def assess_swipe_samples(rows: list[dict], pid: str, epoch: int, *,
                         baseline_image_frame_lines: list[str] | None = None) -> dict:
    """Require fresh live gesture, settled viewport, and same-PID frames per sample."""
    if not rows:
        return {"status": "incomplete", "not_observed":
                ["per_sample_live_touch_phase", "per_sample_viewport",
                 "per_sample_image_cost"], "fresh_count": 0}
    missing: list[str] = []
    candidate_missing: list[str] = []
    valid_samples: list[dict] = []
    previous_raw = None
    previous_finish = None
    previous_frame = tuple(baseline_image_frame_lines or ())
    live_move_count = 0

    def valid_frame(lines: tuple[str, ...]) -> dict[str, int] | None:
        if len(lines) != 2:
            return None
        pids = []
        for line in lines:
            match = image.PID_LINE.match(line)
            if match is None or "image-cost stage=frame " not in line:
                return None
            pids.append(match.group(1))
        if pids != [str(pid), str(pid)] or " starts=" not in lines[0] or " resident=" not in lines[1]:
            return None
        return image.parse_cost_snapshot(list(lines))

    if not previous_frame or valid_frame(previous_frame) is None:
        candidate_missing.append("per_sample_image_cost_baseline")
    for row in rows:
        started, finished = row.get("host_start_ns"), row.get("host_finish_ns")
        sample_missing: list[str] = []
        if (not isinstance(started, int) or not isinstance(finished, int) or
                started >= finished or
                (previous_finish is not None and started <= previous_finish)):
            sample_missing.append("per_sample_host_clock")
        previous_finish = finished if isinstance(finished, int) else previous_finish
        phase = row.get("touch_phase")
        if (phase is None or str(phase.get("pid")) != str(pid) or
                phase.get("epoch") != epoch):
            candidate_missing.append("per_sample_exact_pid_epoch")
            continue
        elif phase.get("action") != 38:
            # BEGIN and terminal rows are useful context, but are not movement
            # samples and cannot establish work observed during the swipe.
            continue
        if phase.get("raw") == previous_raw:
            continue
        previous_raw = phase.get("raw")
        live_move_count += 1
        if row.get("viewport") is None:
            sample_missing.append("per_sample_viewport")
        elif (row["viewport"].get("pending") != 0 or
              row["viewport"].get("offset") != row["viewport"].get("accepted")):
            sample_missing.append("per_sample_viewport_settled")
        frame_lines = row.get("image_cost_frame_lines")
        if not isinstance(frame_lines, list) and isinstance(row.get("image_cost_raw"), str):
            archived_frame = same_pid_image_frame_evidence(row["image_cost_raw"], str(pid))
            frame_lines = archived_frame["lines"] if archived_frame else None
        frame = tuple(frame_lines) if isinstance(frame_lines, list) else ()
        parsed_frame = valid_frame(frame)
        if (parsed_frame is None or frame == previous_frame or
                parsed_frame != row.get("image_cost_frame")):
            sample_missing.append("per_sample_image_cost")
        if sample_missing:
            candidate_missing.extend(sample_missing)
            continue
        previous_frame = frame
        valid_samples.append(row)
    if len(valid_samples) < 2:
        missing.extend(candidate_missing)
        if live_move_count == 0:
            missing.append("per_sample_live_touch_phase")
        if live_move_count < 2:
            missing.append("per_sample_fresh_phase")
        if not any(item in missing for item in (
                "per_sample_viewport", "per_sample_viewport_settled")):
            missing.append("per_sample_viewport")
        if "per_sample_image_cost" not in missing:
            missing.append("per_sample_image_cost")
    if len(valid_samples) >= 2 and len({row["viewport"]["accepted"]
                                        for row in valid_samples}) < 2:
        missing.append("per_sample_offset_progress")
    return {"status": "incomplete" if missing else "observed",
            "not_observed": list(dict.fromkeys(missing)), "fresh_count": len(valid_samples)}


def collect_swipe_samples(pid: str, epoch: int, viewport_key: str,
                          read_touch, read_public_viewport, read_image_cost,
                          stop: threading.Event, *, hand_semantic: str | None = None,
                          read_hand_viewport=None, read_image_lease=None,
                          max_samples: int = 16,
                          max_seconds: float = 5.0, interval_seconds: float = 0.05) -> list[dict]:
    """Poll only during the owned swipe, with both count and wall-time bounds."""
    if max_samples < 1 or max_seconds <= 0 or interval_seconds < 0:
        raise ValueError("invalid swipe sampler bounds")
    deadline = time.monotonic() + max_seconds
    rows = []
    while not stop.is_set() and len(rows) < max_samples and time.monotonic() < deadline:
        row = sample_swipe_once(pid, epoch, viewport_key,
                                read_touch, read_public_viewport, read_image_cost,
                                hand_semantic=hand_semantic,
                                read_hand_viewport=read_hand_viewport,
                                read_image_lease=read_image_lease)
        rows.append(row)
        if row["touch_phase"] is not None and row["touch_phase"]["action"] in (39, 40):
            break
        stop.wait(min(interval_seconds, max(0.0, deadline - time.monotonic())))
    return rows


def parse_scroll_terminal(raw: str, pid: str, epoch: int) -> dict:
    """Select one complete GestureKey from the exact PID and gesture epoch."""
    matches = []
    for line in raw.splitlines():
        source = image.PID_LINE.match(line)
        index = line.find("gesture-scroll-terminal ")
        if source is None or source.group(1) != str(pid) or index < 0:
            continue
        match = SCROLL_TERMINAL.fullmatch(line[index:])
        if match is None or int(match.group(6)) != epoch:
            continue
        terminal, app, comp, surface, pointer, found_epoch, samples, raw_dy, whole, remainder = match.groups()
        try:
            raw_value, remainder_value = float(raw_dy), float(remainder)
        except ValueError:
            return {"status": "invalid", "reason": "non_numeric_terminal", "raw": line}
        matches.append({"status": "observed", "pid": str(pid), "terminal": terminal,
                        "gesture_key": {"app": int(app), "comp": int(comp),
                                        "surface": int(surface), "pointer": int(pointer),
                                        "epoch": int(found_epoch)},
                        "samples": int(samples), "raw_dy": raw_value,
                        "whole": int(whole), "remainder": remainder_value,
                        "raw": line})
    if not matches:
        return {"status": "not_observed", "reason": "exact_pid_epoch_terminal_missing"}
    if len(matches) != 1:
        return {"status": "ambiguous", "reason": "multiple_exact_pid_epoch_terminals",
                "raw": [row["raw"] for row in matches]}
    return matches[0]


def assess_exact_image_lease(raw: str, pid: str, key: str, version: int, *,
                             baseline_raw: str | None = None) -> dict:
    """Check the native accepted owner across every observed scene transaction.

    The two captures are from one freshly launched PID. A baseline before the
    swipe is required by the real probe; accepting a later appearance as the
    baseline would let a resource disappear during the public write.
    """
    wanted_hex = key.encode("utf-8").hex()

    def parse(source: str) -> tuple[dict[int, dict], dict[int, list[dict]], list[dict]]:
        summaries: dict[int, dict] = {}
        entries: dict[int, list[dict]] = {}
        other: list[dict] = []
        for line_index, line in enumerate(dict.fromkeys(source.splitlines())):
            match = image.PID_LINE.match(line)
            marker = line.find("image-lease ")
            if match is None or match.group(1) != str(pid) or marker < 0:
                continue
            fields = dict(re.findall(r"\b([A-Za-z][A-Za-z0-9]*)=([^\s]+)",
                                     line[marker + len("image-lease "):]))
            stage = fields.get("stage")
            fields["raw"] = line
            fields["line_index"] = line_index
            try:
                if stage == "accepted-swap":
                    seq = int(fields["seq"])
                    if seq in summaries and summaries[seq] != fields:
                        summaries[seq] = {"conflict": True, "raw": line}
                    else:
                        summaries[seq] = fields
                elif stage == "accepted-entry":
                    entries.setdefault(int(fields["seq"]), []).append(fields)
                elif stage in ("bitmap-create", "bitmap-destroy", "draw"):
                    other.append(fields)
            except (KeyError, ValueError):
                other.append({"stage": "malformed", "raw": line})
        return summaries, entries, other

    summaries, entries, other = parse(raw)
    before, before_entries, _ = parse(baseline_raw if baseline_raw is not None else raw)
    missing: list[str] = []
    failures: list[str] = []
    if not summaries or not before:
        missing.append("image_lease_transaction_log")
    if any(row.get("stage") == "malformed" for row in other):
        missing.append("image_lease_malformed_log")
    envelope_fields = ("session", "ticket", "oldProjection", "newProjection")
    valid_transactions: set[int] = set()
    for seq, summary in summaries.items():
        if (summary.get("conflict") or summary.get("wrapped") != "0" or
                summary.get("omitted") != "0"):
            missing.append("image_lease_transaction_incomplete")
            continue
        try:
            if len(entries.get(seq, [])) != int(summary["rows"]):
                missing.append("image_lease_entry_rows")
                continue
            if any(any(row.get(field) != summary.get(field)
                       for field in envelope_fields) for row in entries.get(seq, [])):
                missing.append("image_lease_entry_envelope")
                continue
            valid_transactions.add(seq)
        except (KeyError, ValueError):
            missing.append("image_lease_transaction_incomplete")
    for rows in entries.values():
        for row in rows:
            try:
                encoded = row["keyHex"]
                if (row["keyTruncated"] != "0" or len(bytes.fromhex(encoded)) !=
                        int(row["keyBytes"])):
                    missing.append("image_lease_key_truncated")
            except (KeyError, ValueError):
                missing.append("image_lease_key_invalid")

    def target_rows(items: dict[int, list[dict]], seq: int) -> list[dict]:
        return [row for row in items.get(seq, [])
                if row.get("keyHex") == wanted_hex and row.get("version") == str(version)]

    baseline: tuple[int, dict] | None = None
    for seq in sorted(before, reverse=True):
        if seq not in valid_transactions:
            continue
        rows = target_rows(before_entries, seq)
        if rows:
            if len(rows) != 1:
                failures.append("image_lease_baseline_ambiguous")
            else:
                baseline = (seq, rows[0])
            break
    if baseline is None:
        missing.append("image_lease_pre_swipe_accepted")
    elif int(baseline[1].get("newCount", "0")) <= 0:
        failures.append("image_lease_baseline_not_accepted")

    identity = None
    last_seq = max(summaries) if summaries else None
    committed = 0
    post_baseline_projections: list[tuple[int, int, int]] = []
    if baseline is not None and last_seq is not None:
        base_seq, base = baseline
        identity = {field: int(base[field]) for field in ("epoch", "entry", "version")}
        identity["keyHex"] = base["keyHex"]
        session = base.get("session")
        baseline_summary = summaries.get(base_seq, {})
        try:
            expected_projection = int(baseline_summary["newProjection"])
            previous_summary_line = int(baseline_summary["line_index"])
        except (KeyError, ValueError):
            expected_projection = None
            previous_summary_line = -1
            missing.append("image_lease_baseline_projection")
        post_baseline = [seq for seq, summary in summaries.items()
                         if seq > base_seq and summary.get("session") == session]
        for seq in sorted(post_baseline):
            summary = summaries[seq]
            if seq not in valid_transactions:
                continue
            committed += 1
            try:
                old_projection = int(summary["oldProjection"])
                new_projection = int(summary["newProjection"])
                summary_line = int(summary["line_index"])
                if expected_projection is None or old_projection != expected_projection:
                    missing.append("image_lease_projection_chain_gap")
                    expected_projection = new_projection
                else:
                    expected_projection = new_projection
            except (KeyError, ValueError):
                missing.append("image_lease_projection_chain_gap")
                continue
            rows = target_rows(entries, seq)
            if not rows:
                failures.append("image_lease_accepted_hold_broken")
                previous_summary_line = summary_line
                continue
            exact = [row for row in rows if row.get("epoch") == str(identity["epoch"])
                     and row.get("entry") == str(identity["entry"])]
            if len(exact) != 1:
                if rows:
                    failures.append("image_lease_identity_changed")
                else:
                    missing.append("image_lease_accepted_entry_missing")
                continue
            row = exact[0]
            try:
                if int(row["newCount"]) <= 0 or int(row["oldCount"]) <= 0:
                    failures.append("image_lease_accepted_hold_broken")
                else:
                    post_baseline_projections.append(
                        (new_projection, previous_summary_line, summary_line))
            except (KeyError, ValueError):
                missing.append("image_lease_count_invalid")
            previous_summary_line = summary_line
        if committed == 0:
            missing.append("image_lease_no_post_baseline_commit")
    matching = [row for row in other if identity is not None and
                all(row.get(field) == str(identity[field]) for field in ("epoch", "entry", "version"))
                and row.get("keyHex") == identity["keyHex"]]
    bitmap_creates = [row for row in matching if row.get("stage") == "bitmap-create" and
                      row.get("ok") == "1" and row.get("published") == "1"]
    bitmap_destroys = [row for row in matching if row.get("stage") == "bitmap-destroy" and
                       row.get("published") == "1"]
    draws = [row for row in matching if row.get("stage") == "draw"]
    matched_draws = [row for row in draws if any(
        row.get("projection") == str(projection) and
        previous_line < int(row.get("line_index", -1)) < accepted_line
        for projection, previous_line, accepted_line in post_baseline_projections)]
    if not matched_draws:
        missing.append("image_lease_post_baseline_draw")
    if bitmap_destroys:
        failures.append("image_lease_bitmap_destroyed")
    return {"status": "fail" if failures else "incomplete" if missing else "observed",
            "failures": list(dict.fromkeys(failures)),
            "not_observed": list(dict.fromkeys(missing)),
            "identity": identity, "baseline_seq": baseline[0] if baseline else None,
            "last_seq": last_seq, "commits": committed,
            "bitmap_create_count": len(bitmap_creates),
            "bitmap_destroy_count": len(bitmap_destroys), "draw_count": len(matched_draws)}


def exact_touch_evidence(begin: dict | None, final_rows: list[dict],
                         pid: str, epoch: int) -> list[dict]:
    """Keep the first observed BEGIN across later hilog buffer rollover."""
    same = [row for row in final_rows
            if str(row["pid"]) == str(pid) and int(row["epoch"]) == epoch]
    first = begin if (begin is not None and str(begin["pid"]) == str(pid) and
                      int(begin["epoch"]) == epoch and begin["action"] == 37) else None
    if first is None:
        first = next((row for row in same if row["action"] == 37), None)
    terminal = next((row for row in same if row["action"] in (39, 40)), None)
    return [row for row in (first, terminal) if row is not None]


def image_absolute_budget(frame: dict[str, int] | None) -> dict[str, int | str]:
    if frame is None:
        return {"peak_tracked_bytes": "not_observed",
                "idle_cache_bytes": "not_observed", "in_flight": "not_observed"}
    return {"peak_tracked_bytes": frame.get("peakTracked", "not_observed"),
            "idle_cache_bytes": frame.get("idle", "not_observed"),
            "in_flight": frame.get("running", "not_observed")}


def parse_public_image_version(raw_context: str, resource_id: int) -> int | None:
    response = normal.parse_response(raw_context)
    if response.kind != "SNAPSHOT":
        raise ValueError("imageVersion context is not SNAPSHOT")
    rows = [tokens for label, tokens in response.entries if label == "FIELD" and
            len(tokens) >= 2 and tokens[0] == str(resource_id) and tokens[1] == "imageVersion"]
    if not rows:
        return None
    if len(rows) != 1 or len(rows[0]) != 4 or rows[0][2] != "INTEGER" or not rows[0][3].isdigit():
        raise ValueError("public imageVersion field is ambiguous or malformed")
    return int(rows[0][3])


def same_pid_image_frame_evidence(raw: str, pid: str) -> dict | None:
    """Return the exact latest complete same-PID frame pair and its parsed values."""
    rows = [line for line in raw.splitlines()
            if (match := image.PID_LINE.match(line)) and match.group(1) == pid and
            "image-cost stage=frame " in line]
    pending: str | None = None
    latest: tuple[str, str] | None = None
    for line in rows:
        if " starts=" in line:
            pending = line
        elif " resident=" in line and pending is not None:
            latest = (pending, line)
            pending = None
    if latest is None:
        return None
    parsed = image.parse_cost_snapshot(list(latest))
    if parsed is None:
        return None
    return {"frame": parsed, "lines": list(latest)}


def same_pid_image_frame(raw: str, pid: str) -> dict[str, int] | None:
    evidence = same_pid_image_frame_evidence(raw, pid)
    return evidence["frame"] if evidence else None


def renderer_image_settled(before_raw: str, after_raw: str, pid: str,
                           before_version: int | None, after_version: int | None) -> dict:
    """Derive global renderer image settlement, never an exact image lease."""
    before = same_pid_image_frame(before_raw, pid)
    after = same_pid_image_frame(after_raw, pid)
    base = {"scope": "same_pid_renderer_global", "exact_image_lease": "not_observed",
            "image_version_before": before_version, "image_version_after": after_version,
            "frame_before": before, "frame_after": after}
    if before_version is None or after_version is None or before is None or after is None:
        return {**base, "status": "not_observed", "reason": "version_or_frame_missing"}
    if before_version != after_version:
        return {**base, "status": "fail", "reason": "public_image_version_changed"}
    for name, frame in (("before", before), ("after", after)):
        required = ("resident", "bitmapCreates", "running", "queued", "peakTracked", "idle")
        if any(key not in frame for key in required):
            return {**base, "status": "not_observed", "reason": name + "_frame_incomplete"}
        if (frame["resident"] <= 0 or frame["bitmapCreates"] <= 0 or
                frame["running"] != 0 or frame["queued"] != 0 or
                frame["peakTracked"] > 128 * 1024 * 1024 or
                frame["idle"] > 16 * 1024 * 1024):
            return {**base, "status": "fail", "reason": name + "_unsettled_or_over_budget"}
    return {**base, "status": "observed", "reason": "same_pid_frames_and_stable_public_version"}


class ProbeHdc(normal.ReadOnlyHdc):
    def shell(self, command: str, timeout: float = 30) -> str:
        argv = [self.binary, "-t", self.target, "shell", command]
        started = time.perf_counter_ns()
        result = subprocess.run(argv, capture_output=True, text=True, timeout=timeout)
        self.commands.append({"command": argv, "returncode": result.returncode,
                              "stdout": result.stdout, "stderr": result.stderr,
                              "duration_ms": round((time.perf_counter_ns() - started) / 1_000_000, 3)})
        if result.returncode:
            raise ValueError(f"read-only hdc command failed ({result.returncode}): {argv!r}")
        return result.stdout

    def pull(self, remote: str, local: Path) -> None:
        self._run([self.binary, "-t", self.target, "file", "recv", remote, str(local)])


def capture_hilog(hdc: ProbeHdc, pid: str, needle: str, *,
                  timeout_seconds: float = 30) -> str:
    # Device-side grep narrows binary hilog; the PID check is host-side.
    raw = hdc.shell(f"hilog -x 2>/dev/null | grep -a '{needle}' || true",
                    timeout=timeout_seconds)
    return "\n".join(line for line in raw.splitlines()
                     if (match := image.PID_LINE.match(line)) and match.group(1) == pid)


def owner(client, resource_id: int, numeric_field: str) -> tuple[dict, str]:
    response = client.get_context([resource_id])
    if response.kind != "SNAPSHOT":
        raise ValueError("public owner readback is not SNAPSHOT")
    versions = [tokens for label, tokens in response.entries if label == "VERSION"]
    fields = [tokens for label, tokens in response.entries
              if label == "FIELD" and len(tokens) == 4 and tokens[0] == str(resource_id)
              and tokens[1] == numeric_field and tokens[2] == "INTEGER"]
    if (len(versions) != 1 or len(versions[0]) != 1 or
            not versions[0][0].isdigit() or len(fields) != 1 or
            not fields[0][3].lstrip("-").isdigit()):
        raise ValueError("owner numeric field/version is absent or ambiguous")
    return {"version": int(versions[0][0]), "value": fields[0][3],
            "field": numeric_field, "resource_id": resource_id}, response.raw


def state(session: GeneratedUiSession, viewport_key: str, *, hand_semantic: str | None,
          hand_rows: str) -> dict:
    snapshot = session.snapshot()
    instances = session.instances()
    interaction = session.client.get_window_interaction()
    view = parse_viewport(interaction.raw, viewport_key)
    if view is None and hand_semantic:
        view = parse_viewport(hand_rows, hand_semantic)
    resources = [item for item in instances.instances if item.resource]
    ready = all(item.resource_state == "ready" for item in resources) if resources else None
    return {
        "scene": {"accepted": snapshot.window_accepted_scene_version,
                  "pending": snapshot.owner_pending_scene or snapshot.structure_candidate_pending,
                  "structure": snapshot.accepted_structure_version,
                  "endpoint": snapshot.endpoint.describe()},
        "viewport": view, "ready": ready,
        "generated_image_resource_count": len(resources),
        "snapshot": asdict(snapshot), "instances": asdict(instances),
        "window_interaction_raw": interaction.raw,
        "hand_viewport_rows": hand_rows,
    }


def _save(path: Path, value: object) -> None:
    normal.write_json(path, value)


def capture_prewrite_image_baseline(pid: str, resource_id: int, read_context,
                                    read_cost, archive_path: Path, *,
                                    timeout_seconds: float = 0.25, max_samples: int = 6,
                                    clock=time.monotonic, pause=time.sleep) -> dict:
    """Bounded same-PID frame and public-version read before one public write."""
    deadline = clock() + timeout_seconds
    samples = []
    required = ("resident", "bitmapCreates", "running", "queued", "peakTracked", "idle")
    for _ in range(max_samples):
        context_raw = read_context()
        version = parse_public_image_version(context_raw, resource_id)
        cost_raw = read_cost()
        frame = same_pid_image_frame(cost_raw, pid)
        settled = (frame is not None and all(key in frame for key in required) and
                   frame["resident"] > 0 and frame["bitmapCreates"] > 0 and
                   frame["running"] == 0 and frame["queued"] == 0 and
                   frame["peakTracked"] <= 128 * 1024 * 1024 and
                   frame["idle"] <= 16 * 1024 * 1024)
        samples.append({"context_raw": context_raw, "image_version": version,
                        "image_cost_raw": cost_raw, "frame": frame, "settled": settled})
        if version is not None and settled:
            result = {"status": "observed", "reason": "same_pid_settled_frame_and_public_version",
                      "image_version": version, "context_raw": context_raw,
                      "image_cost_raw": cost_raw, "attempts": len(samples), "samples": samples}
            _save(archive_path, result)
            return result
        remaining = deadline - clock()
        if remaining <= 0 or len(samples) == max_samples:
            break
        pause(min(0.04, remaining))
    last = samples[-1]
    result = {"status": "not_observed", "reason": "version_or_settled_frame_missing",
              "image_version": last["image_version"], "context_raw": last["context_raw"],
              "image_cost_raw": "", "attempts": len(samples), "samples": samples}
    _save(archive_path, result)
    return result


def foreground_root_bundle(tree: object, expected_bundle: str) -> str:
    """Reject every missing, foreign, or ambiguous visible UITest root."""
    roots: list[str] = []

    def visit(node: object) -> None:
        if not isinstance(node, dict):
            return
        attrs = node.get("attributes", {})
        if (isinstance(attrs, dict) and attrs.get("type") == "root" and
                attrs.get("visible") == "true"):
            roots.append(str(attrs.get("bundleName", "")))
        children = node.get("children", [])
        if isinstance(children, list):
            for child in children:
                visit(child)

    visit(tree)
    allowed = [expected_bundle]
    if roots == [expected_bundle, "com.huawei.hmos.inputmethod"] or roots == [
            "com.huawei.hmos.inputmethod", expected_bundle]:
        return expected_bundle
    if roots != allowed:
        raise ValueError(f"fresh foreground root differs from exact bundle: {roots!r}")
    return roots[0]


def require_fresh_foreground(hdc: ProbeHdc, out: Path, bundle: str, pid: str) -> str:
    """Take a new system layout immediately before any UITest input."""
    if hdc.pidof(bundle).strip() != pid:
        raise ValueError("PID changed before foreground layout")
    remote = f"/data/local/tmp/cjgui-interleave-{uuid.uuid4().hex}.json"
    local = out / "foreground_layout.json"
    try:
        hdc.shell("uitest dumpLayout -p " + shlex.quote(remote))
        hdc.pull(remote, local)
    finally:
        hdc.shell("rm -f " + shlex.quote(remote))
    if not local.is_file() or local.stat().st_size == 0:
        raise ValueError("fresh foreground layout is missing")
    return foreground_root_bundle(json.loads(local.read_text(encoding="utf-8")), bundle)


def swipe_plan(args) -> tuple[list[str], float]:
    """UITest swipe's last argument is velocity in px/s, not duration."""
    if not 200 <= args.velocity <= 40000:
        raise ValueError("UITest swipe velocity must be in 200..40000 px/s")
    travel = math.hypot(args.end_x - args.start_x, args.end_y - args.start_y)
    seconds = travel / args.velocity
    if seconds < 0.5 or seconds > 20:
        raise ValueError("viewport travel/velocity must yield a 0.5..20 s swipe")
    return ([args.hdc, "-t", args.target, "shell", "uitest", "uiInput", "swipe",
             str(args.start_x), str(args.start_y), str(args.end_x), str(args.end_y),
             str(args.velocity)], seconds)


def archive_swipe_process(out: Path, hdc: ProbeHdc, pid: str, command: list[str],
                          proc, timeout_seconds: float,
                          begin_observed: dict | None = None) -> dict:
    """Archive own UITest process and same-PID raw touch even on early abort."""
    try:
        stdout, stderr = proc.communicate(timeout=timeout_seconds)
    except subprocess.TimeoutExpired:
        proc.terminate()
        stdout, stderr = proc.communicate(timeout=2)
        stderr += "\nprobe terminated its timed-out UITest swipe"
    record = {"command": command, "returncode": proc.returncode,
              "stdout": stdout, "stderr": stderr,
              "begin_observed": begin_observed}
    try:
        record["touch_raw"] = capture_hilog(hdc, pid, "raw touch action=")
    except Exception as exc:
        record["touch_error"] = f"{type(exc).__name__}: {exc}"
        record["touch_raw"] = ""
    try:
        record["scroll_terminal_raw"] = capture_hilog(hdc, pid, "gesture-scroll-terminal ")
    except Exception as exc:
        record["scroll_terminal_error"] = f"{type(exc).__name__}: {exc}"
        record["scroll_terminal_raw"] = ""
    _save(out / "swipe_process.json", record)
    return record


def run(args, hdc: ProbeHdc) -> dict:
    expected = SAFE[args.app]
    if not matches_safe_contract(args):
        raise ValueError("action/resource/fields must match the normal app safe contract")
    if args.writes not in (1, 2):
        raise ValueError("one or two writes are required")
    if not 2 <= args.sample_max_count <= 32 or not 20 <= args.sample_interval_ms <= 500:
        raise ValueError("sample max count must be 2..32 and interval 20..500 ms")
    command, estimated_seconds = swipe_plan(args)
    if args.owner_max is None or args.owner_max > expected[5]:
        raise ValueError("caller must provide a business upper bound at or below the normal app limit")
    digest = hashlib.sha256(args.hap.read_bytes()).hexdigest()
    if digest != args.hap_sha256:
        raise ValueError("HAP SHA mismatch")
    identity_pid = normal._identity(args.identity.read_text(encoding="utf-8"),
                                    args.target, args.hap)
    if identity_pid != args.pid:
        raise ValueError("explicit PID differs from normal HAP identity")
    receipt = json.loads(args.forward_receipt_json.read_text(encoding="utf-8"))
    normal._receipt(receipt, args.target, args.local_port, args.device_port)
    normal._forward_map(hdc.listing(), args.target, args.local_port, args.device_port)
    if hdc.pidof(args.bundle).strip() != args.pid:
        raise ValueError("PID changed before probe")
    args.run_dir.mkdir(parents=True, exist_ok=False)
    _save(args.run_dir / "input.json", {key: str(value) for key, value in vars(args).items()
                                       if key != "capability"})
    session = GeneratedUiSession.connect_forwarded_tcp(
        target=args.target, local_port=args.local_port, device_port=args.device_port,
        capability=args.capability, caller=args.caller)
    numeric, raw = owner(session.client, args.resource_id, args.numeric_field)
    accepted = session.instances()
    if not any(item.field_id == args.field for item in accepted.instances):
        raise ValueError("explicit generated field absent from accepted instances")
    if int(numeric["value"]) + args.writes > args.owner_max:
        raise ValueError("increment would exceed caller supplied business bound")
    _save(args.run_dir / "owner_preflight.json", {"parsed": numeric, "raw": raw})
    initial_touch = parse_touch_rows(capture_hilog(hdc, args.pid, "raw touch action="),
                                     args.pid, 0)
    initial_lease_raw = capture_hilog(hdc, args.pid, "image-lease ")
    (args.run_dir / "image_lease_before.raw.txt").write_text(initial_lease_raw, encoding="utf-8")
    old_epochs = {row["epoch"] for row in initial_touch}
    hand_baseline = set(capture_hilog(hdc, args.pid, "WINDOW_VIEWPORT ").splitlines())

    def new_hand_rows(*, timeout_seconds: float = 30) -> str:
        return "\n".join(line for line in capture_hilog(
            hdc, args.pid, "WINDOW_VIEWPORT ",
            timeout_seconds=timeout_seconds).splitlines() if line not in hand_baseline)

    # Collect the first write's before state before UITest takes the pointer.
    # At the platform minimum 200 px/s, a short viewport travel may last <1 s.
    before_owner, before_raw = numeric, raw
    before = state(session, args.viewport_key, hand_semantic=args.hand_viewport_semantic,
                   hand_rows=new_hand_rows())
    pre_swipe_image_cost_raw = capture_hilog(hdc, args.pid, "image-cost stage=frame")
    baseline_frame = same_pid_image_frame_evidence(pre_swipe_image_cost_raw, args.pid)
    _save(args.run_dir / "image_cost_before_swipe.json", {
        "pid": args.pid, "frame": baseline_frame, "raw": pre_swipe_image_cost_raw})
    require_fresh_foreground(hdc, args.run_dir, args.bundle, args.pid)
    proc = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    writes = []
    gesture_epoch = None
    gesture_begin = None
    sample_stop = None
    sample_thread = None
    sample_output = {"samples": []}
    try:
        deadline = time.monotonic() + min(2.0, max(0.3, estimated_seconds * 0.75))
        while time.monotonic() < deadline and proc.poll() is None:
            rows = parse_touch_rows(capture_hilog(hdc, args.pid, "raw touch action="),
                                    args.pid, time.monotonic_ns())
            beginnings = [row for row in rows if row["action"] == 37 and row["epoch"] not in old_epochs]
            if len(beginnings) == 1:
                gesture_epoch = beginnings[0]["epoch"]
                gesture_begin = beginnings[0]
                break
            time.sleep(0.04)
        if gesture_epoch is None:
            raise ValueError("new exact-PID touch BEGIN not observed during swipe")
        # Use an independent typed client. The writer's session is never called
        # from the sampling thread, and each read has its own bounded timeout.
        sample_session = GeneratedUiSession.connect_forwarded_tcp(
            target=args.target, local_port=args.local_port, device_port=args.device_port,
            capability=args.capability, caller=args.caller)
        sample_stop = threading.Event()

        def sample_during_swipe() -> None:
            try:
                sample_output["samples"] = collect_swipe_samples(
                    args.pid, gesture_epoch, args.viewport_key,
                    lambda: capture_hilog(hdc, args.pid, "raw touch action=",
                                          timeout_seconds=1.25),
                    lambda: sample_session.client.get_window_interaction(
                        timeout_seconds=1.0).raw,
                    lambda: capture_hilog(hdc, args.pid, "image-cost stage=frame",
                                          timeout_seconds=1.25),
                    sample_stop, hand_semantic=args.hand_viewport_semantic,
                    read_hand_viewport=lambda: new_hand_rows(timeout_seconds=1.25),
                    read_image_lease=lambda: capture_hilog(
                        hdc, args.pid, "image-lease ", timeout_seconds=1.25),
                    max_samples=args.sample_max_count,
                    max_seconds=min(5.0, estimated_seconds + 1.0),
                    interval_seconds=args.sample_interval_ms / 1000.0)
            except Exception as exc:
                sample_output["error"] = f"{type(exc).__name__}: {exc}"

        sample_thread = threading.Thread(target=sample_during_swipe,
                                         name="cjgui-touch-sampler", daemon=True)
        sample_thread.start()
        for number in range(args.writes):
            if proc.poll() is not None:
                raise ValueError("swipe ended before public write")
            label = f"write_{number + 1}"
            baseline = capture_prewrite_image_baseline(
                args.pid, args.resource_id,
                lambda: owner(session.client, args.resource_id, args.numeric_field)[1],
                lambda: capture_hilog(hdc, args.pid, "image-cost stage="),
                args.run_dir / f"{label}_prewrite.json",
                timeout_seconds=min(0.25, max(0.08, estimated_seconds * 0.20)))
            current_owner, _ = owner(session.client, args.resource_id, args.numeric_field)
            if current_owner != before_owner:
                raise ValueError("public owner changed before intended write")
            before_raw = baseline["context_raw"]
            before_cost_raw = baseline["image_cost_raw"]
            if hdc.pidof(args.bundle).strip() != args.pid or proc.poll() is not None:
                raise ValueError("PID or swipe changed before public write")
            began = time.monotonic_ns()
            # The generated typed client sends the same public INVOKE, with no replay.
            response = session.client.invoke(before_owner["version"], args.action,
                                             [args.resource_id])
            ended = time.monotonic_ns()
            during_rows = parse_touch_rows(capture_hilog(hdc, args.pid, "raw touch action="),
                                           args.pid, ended)
            live = (proc.poll() is None and not any(
                row["epoch"] == gesture_epoch and row["action"] in (39, 40)
                for row in during_rows))
            if hdc.pidof(args.bundle).strip() != args.pid:
                raise ValueError("PID changed during public write")
            after_owner, after_raw = owner(session.client, args.resource_id, args.numeric_field)
            settled_deadline = time.monotonic() + 2.0
            after = state(session, args.viewport_key,
                          hand_semantic=args.hand_viewport_semantic,
                          hand_rows=new_hand_rows())
            while after["scene"]["pending"] and time.monotonic() < settled_deadline:
                time.sleep(0.04)
                after = state(session, args.viewport_key,
                              hand_semantic=args.hand_viewport_semantic,
                              hand_rows=new_hand_rows())
            after_cost_raw = capture_hilog(hdc, args.pid, "image-cost stage=")
            before_frame = same_pid_image_frame(before_cost_raw, args.pid)
            after_frame = same_pid_image_frame(after_cost_raw, args.pid)
            cost = image.phase_cost(before_frame, after_frame)
            absolute_cost = image_absolute_budget(after_frame)
            before_image_version = parse_public_image_version(before_raw, args.resource_id)
            after_image_version = parse_public_image_version(after_raw, args.resource_id)
            renderer_ready = renderer_image_settled(
                before_cost_raw, after_cost_raw, args.pid,
                before_image_version, after_image_version)
            applied = [tokens[0] for name, tokens in response.entries if name == "APPLIED"]
            row = {"started_ns": began, "ended_ns": ended,
                   "swipe_running_at_start": live,
                   "before_owner": before_owner, "after_owner": after_owner,
                   "result_kind": response.kind, "applied": applied == ["true"],
                   "before_scene": before["scene"], "after_scene": after["scene"],
                   "before_viewport": before["viewport"], "after_viewport": after["viewport"],
                   "ready_before": before["ready"], "ready_after": after["ready"],
                   "generated_image_resource_count_before": before["generated_image_resource_count"],
                   "generated_image_resource_count_after": after["generated_image_resource_count"],
                   "renderer_image_settled": renderer_ready,
                   "image_cost": cost, "image_cost_absolute": absolute_cost,
                   "image_cost_delta": cost if before_frame is not None else "not_observed"}
            _save(args.run_dir / f"{label}.json", {"gate": row,
                "request_redacted": f"PROTOCOL {normal.PROTOCOL}\nAUTH [REDACTED]\nINVOKE {before_owner['version']} {args.action} 1 0\nID {args.resource_id}",
                "request_sha256": hashlib.sha256(
                    f"PROTOCOL {normal.PROTOCOL}\nAUTH {args.capability}\nINVOKE {before_owner['version']} {args.action} 1 0\nID {args.resource_id}".encode()).hexdigest(),
                "result_raw": response.raw, "get_context_before_raw": before_raw,
                "get_context_after_raw": after_raw, "before": before, "after": after,
                "prewrite_baseline": baseline,
                "image_cost_before_raw": before_cost_raw,
                "image_cost_after_raw": after_cost_raw,
                "image_cost_absolute": absolute_cost,
                "image_cost_delta": row["image_cost_delta"],
                "renderer_image_settled": renderer_ready,
                "touch_during": during_rows})
            writes.append(row)
            if not live or not row["applied"]:
                break  # Never retry or send a second write after an ambiguous result.
            before_owner, before_raw = after_owner, after_raw
            before_cost_raw, before = after_cost_raw, after
    finally:
        try:
            process_evidence = archive_swipe_process(
                args.run_dir, hdc, args.pid, command, proc, estimated_seconds + 5,
                begin_observed=gesture_begin)
        finally:
            if sample_stop is not None and sample_thread is not None:
                sample_stop.set()
                sample_thread.join(timeout=6)
                if sample_thread.is_alive():
                    sample_output["error"] = "sampler_join_timeout"
            _save(args.run_dir / "swipe_samples.json",
                  {"pid": args.pid, "gesture_epoch": gesture_epoch,
                   "clock": "host_monotonic_observation_ns_not_device_time",
                   "max_samples": args.sample_max_count,
                   "interval_ms": args.sample_interval_ms, **sample_output})
    if process_evidence["returncode"]:
        raise ValueError(f"UITest swipe failed {process_evidence['returncode']}: "
                         f"{process_evidence['stderr']}")
    try:
        final_rows = parse_touch_rows(process_evidence["touch_raw"],
                                      args.pid, time.monotonic_ns())
        touch = exact_touch_evidence(gesture_begin, final_rows, args.pid, gesture_epoch)
        scroll_terminal = parse_scroll_terminal(
            process_evidence["scroll_terminal_raw"], args.pid, gesture_epoch)
        final = state(session, args.viewport_key,
                      hand_semantic=args.hand_viewport_semantic,
                      hand_rows=new_hand_rows())
        _, final_context_raw = owner(session.client, args.resource_id, args.numeric_field)
        final_image_version = parse_public_image_version(final_context_raw, args.resource_id)
        final_cost_raw = capture_hilog(hdc, args.pid, "image-cost stage=")
        final_lease_raw = capture_hilog(hdc, args.pid, "image-lease ")
        (args.run_dir / "image_lease_after.raw.txt").write_text(final_lease_raw, encoding="utf-8")
        complete_lease_raw = "\n".join(dict.fromkeys(
            (initial_lease_raw + "\n" + "\n".join(
                row.get("image_lease_raw", "") for row in sample_output["samples"])
             + "\n" + final_lease_raw).splitlines()))
        lease = assess_exact_image_lease(
            complete_lease_raw, args.pid, IMAGE_KEYS[args.app], final_image_version,
            baseline_raw=initial_lease_raw) if final_image_version is not None else {
                "status": "incomplete", "not_observed": ["public_image_version"]}
        final_renderer_ready = renderer_image_settled(
            after_cost_raw, final_cost_raw, args.pid,
            after_image_version, final_image_version)
        evidence = {"pid": args.pid, "gesture_epoch": gesture_epoch,
                    "touch": touch, "writes": writes,
                    "scroll_terminal": scroll_terminal,
                    "image_lease": lease,
                    "swipe_samples": sample_output["samples"],
                    "image_cost_baseline_lines": baseline_frame["lines"] if baseline_frame else None,
                    "final_viewport": final["viewport"],
                    "final_scene": final["scene"], "final_ready": final["ready"],
                    "final_generated_image_resource_count": final["generated_image_resource_count"],
                    "final_renderer_image_settled": final_renderer_ready}
        result = evaluate(evidence)
        result.update({"gesture_epoch": gesture_epoch, "uitest_command": command,
                       "uitest_stdout": process_evidence["stdout"],
                       "uitest_stderr": process_evidence["stderr"],
                       "estimated_swipe_seconds": estimated_seconds,
                       "touch_raw": [row["raw"] for row in touch],
                       "touch_exact": touch,
                       "swipe_samples_path": str(args.run_dir / "swipe_samples.json"),
                       "swipe_sample_count": len(sample_output["samples"]),
                       "swipe_sample_error": sample_output.get("error"),
                       "final_state": final,
                       "final_context_raw": final_context_raw,
                       "final_image_cost_raw": final_cost_raw,
                       "final_renderer_image_settled": final_renderer_ready,
                       "hap_sha256": digest, "pid": args.pid,
                       "writes_observed": len(writes), "writes_requested": args.writes})
        if len(writes) != args.writes:
            result["status"] = "fail"
            result["failures"].append("requested_write_count")
        _save(args.run_dir / "result.json", result)
        return result
    except Exception:
        # swipe_process.json remains available beside failure.json.
        raise


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--app", choices=sorted(SAFE), required=True)
    parser.add_argument("--target", required=True)
    parser.add_argument("--bundle", required=True)
    parser.add_argument("--hap", type=Path, required=True)
    parser.add_argument("--hap-sha256", required=True)
    parser.add_argument("--identity", type=Path, required=True)
    parser.add_argument("--pid", required=True)
    parser.add_argument("--forward-receipt-json", type=Path, required=True)
    parser.add_argument("--local-port", type=int, required=True)
    parser.add_argument("--device-port", type=int, required=True)
    parser.add_argument("--capability", required=True)
    parser.add_argument("--caller", required=True)
    parser.add_argument("--resource-id", type=int, required=True)
    parser.add_argument("--action", required=True)
    parser.add_argument("--numeric-field", required=True)
    parser.add_argument("--field", required=True, help="Visible generated field identity")
    parser.add_argument("--owner-max", type=int, required=True)
    parser.add_argument("--viewport-key", required=True, help="Accepted viewport semantic ID")
    parser.add_argument("--hand-viewport-semantic")
    parser.add_argument("--start-x", type=int, required=True)
    parser.add_argument("--start-y", type=int, required=True)
    parser.add_argument("--end-x", type=int, required=True)
    parser.add_argument("--end-y", type=int, required=True)
    parser.add_argument("--velocity", type=int, default=200,
                        help="UITest swipe speed in px/s (200..40000), not duration")
    parser.add_argument("--writes", type=int, default=1)
    parser.add_argument("--sample-max-count", type=int, default=16,
                        help="Bounded host observation samples per swipe (2..32)")
    parser.add_argument("--sample-interval-ms", type=int, default=50,
                        help="Minimum host polling interval in ms (20..500)")
    parser.add_argument("--run-dir", type=Path, required=True)
    parser.add_argument("--hdc", default=normal.DEFAULT_HDC)
    return parser.parse_args(argv)


def main(argv: list[str]) -> int:
    args = parse_args(argv)
    try:
        result = run(args, ProbeHdc(args.hdc, args.target))
    except Exception as exc:
        if args.run_dir.is_dir():
            _save(args.run_dir / "failure.json", {"status": "fail",
                  "error_type": type(exc).__name__, "error": str(exc)})
        print(f"normal touch interleaving failed: {type(exc).__name__}: {exc}", file=sys.stderr)
        return 2
    print(json.dumps({"status": result["status"], "run_dir": str(args.run_dir)}))
    return 0 if result["status"] == "pass" else 1


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))

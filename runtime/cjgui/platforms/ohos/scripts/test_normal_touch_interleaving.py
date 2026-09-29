#!/usr/bin/env python3
"""Controlled counterexamples for the normal touch/public owner interleaving gate."""

import unittest
import json
import threading
from types import SimpleNamespace
from pathlib import Path
from tempfile import TemporaryDirectory

import verify_normal_touch_interleaving as probe
from client import parse_response


class InterleavingEvidenceTest(unittest.TestCase):
    def lease_log(self, *, second_entry=17, second_old=1, second_new=1,
                  second_seq=2, include_bitmap=True, second_ticket=2,
                  second_session=9, second_old_projection=1,
                  second_new_projection=2, summary_new_projection=2,
                  summary_old_projection=1,
                  draw_projection=2, first_seq=1,
                  draw_before_second=True, include_create=True):
        key = "settings-beacon".encode().hex()
        prefix = "09-28 12:00:00.001 123 1 I CJGUI image-lease "
        rows = [
            f"stage=accepted-swap seq={first_seq} session=9 ticket=1 cause=commit oldProjection=0 newProjection=1 rows=1 omitted=0 wrapped=0",
            f"stage=accepted-entry seq={first_seq} epoch=1 entry=17 keyHex={key} version=1 oldCount=0 newCount=1 session=9 ticket=1 oldProjection=0 newProjection=1 keyBytes=15 keyTruncated=0",
            f"stage=accepted-swap seq={second_seq} session=9 ticket=2 cause=commit oldProjection={summary_old_projection} newProjection={summary_new_projection} rows=1 omitted=0 wrapped=0",
            f"stage=accepted-entry seq={second_seq} epoch=1 entry={second_entry} keyHex={key} version=1 oldCount={second_old} newCount={second_new} session={second_session} ticket={second_ticket} oldProjection={second_old_projection} newProjection={second_new_projection} keyBytes=15 keyTruncated=0",
        ]
        if include_bitmap:
            if include_create:
                rows.append(f"stage=bitmap-create epoch=1 entry=17 keyHex={key} version=1 ok=1 published=1 keyBytes=15 keyTruncated=0")
            draw = f"stage=draw epoch=1 entry=17 keyHex={key} version=1 projection={draw_projection} node=31 keyBytes=15 keyTruncated=0"
            if draw_before_second:
                rows.insert(2, draw)
            else:
                rows.append(draw)
        return "\n".join(prefix + row for row in rows)

    def test_exact_image_lease_requires_continuous_accepted_identity(self):
        def assess(raw):
            baseline = "\n".join(raw.splitlines()[:2])
            return probe.assess_exact_image_lease(
                raw, "123", "settings-beacon", 1, baseline_raw=baseline)

        good = assess(self.lease_log())
        self.assertEqual(good["status"], "observed")
        self.assertEqual(good["identity"]["entry"], 17)
        self.assertEqual(assess(self.lease_log(second_new=0))["status"], "fail")
        self.assertEqual(assess(self.lease_log(second_entry=18, second_old=0))["status"], "fail")
        gap = assess(self.lease_log(second_seq=3))
        self.assertEqual(gap["status"], "observed")
        chain_gap = assess(self.lease_log(summary_old_projection=5, summary_new_projection=6,
                                         second_old_projection=5, second_new_projection=6))
        self.assertEqual(chain_gap["status"], "incomplete")
        self.assertIn("image_lease_projection_chain_gap", chain_gap["not_observed"])
        self.assertEqual(assess(self.lease_log(first_seq=88, second_seq=89))["status"], "observed")
        self.assertEqual(assess(self.lease_log(include_bitmap=False))["status"], "incomplete")
        self.assertEqual(assess(self.lease_log().replace(" 123 1 I ", " 456 1 I "))["status"], "incomplete")

    def test_exact_lease_requires_matching_transaction_envelopes(self):
        for raw in (self.lease_log(second_ticket=99),
                    self.lease_log(second_session=10),
                    self.lease_log(second_new_projection=3)):
            with self.subTest(raw=raw):
                result = probe.assess_exact_image_lease(
                    raw, "123", "settings-beacon", 1,
                    baseline_raw="\n".join(raw.splitlines()[:2]))
                self.assertEqual(result["status"], "incomplete")
                self.assertIn("image_lease_entry_envelope", result["not_observed"])

    def test_exact_lease_requires_post_baseline_draw_for_accepted_projection(self):
        baseline = "\n".join(self.lease_log().splitlines()[:2])
        for raw in (self.lease_log(draw_projection=99),
                    self.lease_log(second_new_projection=3, summary_new_projection=3),
                    self.lease_log(draw_projection=1),
                    self.lease_log(draw_before_second=False)):
            result = probe.assess_exact_image_lease(
                raw, "123", "settings-beacon", 1, baseline_raw=baseline)
            self.assertEqual(result["status"], "incomplete")
            self.assertIn("image_lease_post_baseline_draw", result["not_observed"])

    def test_post_baseline_draw_suffices_when_bitmap_create_rolled_off(self):
        full = self.lease_log(include_create=False)
        lines = full.splitlines()
        raw = "\n".join(line for line in lines if "stage=bitmap-create" not in line)
        result = probe.assess_exact_image_lease(
            raw, "123", "settings-beacon", 1,
            baseline_raw="\n".join(lines[:2]))
        self.assertEqual(result["status"], "observed")
        self.assertEqual(result["bitmap_create_count"], 0)
        self.assertEqual(result["draw_count"], 1)

    def test_complete_sampling_requires_lease_remainder_and_fresh_rows(self):
        evidence = self.evidence()
        evidence["image_lease"] = {"status": "observed", "identity": {"entry": 17}}
        evidence["scroll_terminal"] = probe.parse_scroll_terminal(
            self.terminal_line(), "123", 42)
        evidence["swipe_samples"] = [self.sample_sources(action=38, tick=100),
                                      self.sample_sources(action=38, tick=200)]
        evidence["image_cost_baseline_lines"] = self.sample_sources(
            action=37, tick=1)["image_cost_frame_lines"]
        result = probe.evaluate(evidence)
        self.assertEqual(result["sampling_status"], "pass")
        self.assertEqual(result["exact_image_lease"]["identity"]["entry"], 17)
        evidence["image_lease"] = {"status": "fail", "failures": ["accepted_hold_broken"]}
        self.assertEqual(probe.evaluate(evidence)["sampling_status"], "fail")

    def test_only_normal_or_explicit_isolated_bundle_uses_safe_contract(self):
        args = SimpleNamespace(app="settings", bundle="com.example.cjguiapp.htouch",
                               action="INCREMENT", resource_id=9700,
                               numeric_field="count", field="name")
        self.assertTrue(probe.matches_safe_contract(args))
        args.bundle = "com.example.cjguiapp.htouch.other"
        self.assertFalse(probe.matches_safe_contract(args))

    def evidence(self):
        return {
            "pid": "123", "gesture_epoch": 42,
            "touch": [
                {"pid": "123", "epoch": 42, "action": 37, "at_ns": 10},
                {"pid": "123", "epoch": 42, "action": 39, "at_ns": 90},
            ],
            "writes": [
                {"started_ns": 30, "ended_ns": 40, "swipe_running_at_start": True,
                 "before_owner": {"version": 7, "value": "3"},
                 "after_owner": {"version": 8, "value": "4"},
                 "result_kind": "RESULT", "applied": True,
                 "before_scene": {"accepted": 5, "pending": False, "structure": 2,
                                  "endpoint": "e1"},
                 "after_scene": {"accepted": 6, "pending": False, "structure": 2,
                                 "endpoint": "e1"},
                 "before_viewport": {"offset": 10, "accepted": 10, "pending": 0,
                                     "solves": 3},
                 "after_viewport": {"offset": 30, "accepted": 30, "pending": 0,
                                    "solves": 4},
                 "ready_before": True, "ready_after": True,
                 "renderer_image_settled": {"status": "observed"},
                 "image_cost": {"peak_tracked_bytes": 1024,
                                "idle_cache_bytes": 512, "in_flight": 1}},
            ],
            "final_viewport": {"offset": 30, "accepted": 30, "pending": 0},
            "final_scene": {"pending": False}, "final_ready": True,
            "final_renderer_image_settled": {"status": "observed"},
        }

    def test_real_overlap_and_owner_attribution_pass(self):
        result = probe.evaluate(self.evidence())
        self.assertEqual(result["status"], "pass")
        self.assertEqual(result["float_remainder"], "not_observed")
        self.assertEqual(result["exact_image_lease"], "not_observed")

    def test_sequential_write_fails_even_with_owner_delta(self):
        value = self.evidence()
        value["writes"][0]["started_ns"] = 100
        self.assertEqual(probe.evaluate(value)["status"], "fail")

    def test_other_pid_terminal_does_not_close_gesture(self):
        value = self.evidence()
        value["touch"][1]["pid"] = "456"
        self.assertEqual(probe.evaluate(value)["status"], "fail")

    def test_other_epoch_terminal_does_not_close_gesture(self):
        value = self.evidence()
        value["touch"][1]["epoch"] = 43
        self.assertEqual(probe.evaluate(value)["status"], "fail")

    def test_wrong_owner_delta_fails(self):
        value = self.evidence()
        value["writes"][0]["after_owner"]["value"] = "5"
        self.assertEqual(probe.evaluate(value)["status"], "fail")

    def test_absent_viewport_is_incomplete(self):
        value = self.evidence()
        value["writes"][0]["after_viewport"] = None
        self.assertEqual(probe.evaluate(value)["status"], "incomplete")

    def test_busy_final_viewport_fails(self):
        value = self.evidence()
        value["writes"][0]["after_viewport"]["pending"] = 1
        self.assertEqual(probe.evaluate(value)["status"], "fail")

    def test_terminal_pending_does_not_pass(self):
        value = self.evidence()
        value["final_viewport"]["pending"] = 1
        self.assertEqual(probe.evaluate(value)["status"], "fail")

    def test_image_budget_excess_fails(self):
        value = self.evidence()
        value["writes"][0]["image_cost"]["peak_tracked_bytes"] = 128 * 1024 * 1024 + 1
        self.assertEqual(probe.evaluate(value)["status"], "fail")

    def test_public_integer_owner_is_parsed_exactly(self):
        class Client:
            def get_context(self, targets):
                self_targets = targets
                assert self_targets == [9700]
                return parse_response("PROTOCOL CJGUI_SHARED_OPERATION/2\nKIND SNAPSHOT\n"
                                      "VERSION 7\nFIELD 9700 count INTEGER 3\nEND")

        owner, raw = probe.owner(Client(), 9700, "count")
        self.assertEqual(owner, {"version": 7, "value": "3",
                                 "field": "count", "resource_id": 9700})
        self.assertIn("FIELD 9700 count INTEGER 3", raw)

    def test_viewport_requires_matching_semantic(self):
        raw = "WINDOW_INTERACTION\nWINDOW_VIEWPORT old offset=10 accepted=10 content=99 viewport=30 pending=0 solves=2\nEND"
        self.assertIsNone(probe.parse_viewport(raw, "new"))
        self.assertEqual(probe.parse_viewport(raw, "old")["offset"], 10)

    def test_hilog_pid_filter_keeps_only_current_touch(self):
        raw = ("09-28 12:00:00.000 456 1 I CJGUI raw touch action=37 x=1 y=2 ep=42\n"
               "09-28 12:00:00.001 123 1 I CJGUI raw touch action=37 x=1 y=2 ep=43")
        self.assertEqual([(row["pid"], row["epoch"])
                          for row in probe.parse_touch_rows(raw, "123", 10)], [("123", 43)])

    def terminal_line(self, *, pid="123", epoch=42, comp=7, terminal="END",
                      samples=3, raw_dy="-20.500000", whole=-20,
                      remainder="-0.500000"):
        return (f"09-28 12:00:00.001 {pid} 1 I CJGUI gesture-scroll-terminal "
                f"terminal={terminal} app=5 comp={comp} surface=9 pointer=0 "
                f"epoch={epoch} samples={samples} rawDy={raw_dy} whole={whole} "
                f"remainder={remainder}")

    def test_scroll_terminal_requires_exact_pid_epoch_and_unique_full_key(self):
        exact = self.terminal_line()
        raw = "\n".join([self.terminal_line(pid="456"),
                         self.terminal_line(epoch=43), exact])
        parsed = probe.parse_scroll_terminal(raw, "123", 42)
        self.assertEqual(parsed["status"], "observed")
        self.assertEqual(parsed["raw"], exact)
        self.assertEqual(parsed["gesture_key"],
                         {"app": 5, "comp": 7, "surface": 9, "pointer": 0, "epoch": 42})
        ambiguous = probe.parse_scroll_terminal(
            exact + "\n" + self.terminal_line(comp=8), "123", 42)
        self.assertEqual(ambiguous["status"], "ambiguous")

    def test_terminal_remainder_and_unclipped_offset_are_checked(self):
        value = self.evidence()
        value["scroll_terminal"] = probe.parse_scroll_terminal(self.terminal_line(), "123", 42)
        value["unclipped_monotonic_swipe"] = True
        result = probe.evaluate(value)
        self.assertEqual(result["status"], "pass")
        self.assertEqual(result["float_remainder"], -0.5)
        self.assertEqual(result["scroll_displacement"]["requested_delta"], 20)
        self.assertEqual(result["scroll_displacement"]["accepted_delta"], 20)
        self.assertEqual(result["scroll_displacement"]["comparison"], "matched_unclipped")
        self.assertEqual(result["sampling_status"], "incomplete")
        self.assertNotIn("float_remainder", result["sampling_not_observed"])
        self.assertIn("exact_image_lease", result["sampling_not_observed"])
        value["final_viewport"]["offset"] = 29
        value["final_viewport"]["accepted"] = 29
        result = probe.evaluate(value)
        self.assertEqual(result["status"], "fail")
        self.assertIn("scroll_terminal_unclipped_offset", result["failures"])

    def test_clamped_or_unproven_path_does_not_equate_whole_to_accepted_delta(self):
        value = self.evidence()
        value["scroll_terminal"] = probe.parse_scroll_terminal(self.terminal_line(), "123", 42)
        value["final_viewport"]["offset"] = 15
        value["final_viewport"]["accepted"] = 15
        result = probe.evaluate(value)
        self.assertEqual(result["status"], "pass")
        self.assertEqual(result["scroll_displacement"]["comparison"],
                         "not_applicable_clamp_or_unproven_path")
        self.assertEqual(result["scroll_displacement"]["accepted_delta"], 5)

    def test_terminal_numeric_invariant_and_end_are_required(self):
        for line in (self.terminal_line(remainder="0.250000"),
                     self.terminal_line(raw_dy="nan"),
                     self.terminal_line(samples=0),
                     self.terminal_line(terminal="CANCEL")):
            with self.subTest(line=line):
                value = self.evidence()
                value["scroll_terminal"] = probe.parse_scroll_terminal(line, "123", 42)
                self.assertEqual(probe.evaluate(value)["status"], "fail")

    def sample_sources(self, *, pid="123", action=38, epoch=42,
                       viewport=True, cost_pid="123", tick=100, y=None):
        raw_touch = (f"09-28 12:00:00.001 {pid} 1 I CJGUI "
                     f"raw touch action={action} x=1 y={tick if y is None else y} ep={epoch}")
        offset = 0 if action == 37 else tick
        raw_viewport = (f"WINDOW_INTERACTION\nWINDOW_VIEWPORT feed offset={offset} "
                        f"accepted={offset} content=838 viewport=420 pending=0 solves=5\nEND"
                        if viewport else "WINDOW_INTERACTION\nEND")
        prefix = f"09-28 12:00:00.001 {cost_pid} 1 I CJGUI "
        raw_cost = (prefix + f"image-cost stage=frame starts=1 frame={tick}\n" + prefix +
                    f"image-cost stage=frame resident={61440 + tick} idle=0 peakTracked=37748736 "
                    "running=0 queued=0 bitmapCreates=1")
        ticks = iter((tick * 10, tick * 10 + 1, tick * 10 + 2, tick * 10 + 3))
        return probe.sample_swipe_once(
            "123", 42, "feed", lambda: raw_touch, lambda: raw_viewport,
            lambda: raw_cost, read_image_lease=lambda: "sampled lease log",
            clock_ns=lambda: next(ticks))

    def test_bounded_sample_preserves_exact_raw_and_monotonic_host_observation(self):
        first = self.sample_sources(action=38, tick=100)
        second = self.sample_sources(action=38, tick=200)
        self.assertEqual(first["touch_phase"]["pid"], "123")
        self.assertEqual(first["touch_phase"]["epoch"], 42)
        self.assertIn("raw touch action=38", first["touch_raw"])
        self.assertIn("WINDOW_VIEWPORT feed", first["viewport_raw"])
        self.assertIn("resident=61540", first["image_cost_raw"])
        self.assertEqual(first["image_lease_raw"], "sampled lease log")
        self.assertLess(first["host_start_ns"], first["host_finish_ns"])
        baseline = self.sample_sources(action=37, tick=1)["image_cost_frame_lines"]
        report = probe.assess_swipe_samples(
            [first, second], "123", 42, baseline_image_frame_lines=baseline)
        self.assertEqual(report["status"], "observed")
        value = self.evidence()
        value["swipe_samples"] = [first, second]
        value["image_cost_baseline_lines"] = baseline
        result = probe.evaluate(value)
        self.assertNotIn("per_sample_viewport", result["sampling_not_observed"])
        self.assertNotIn("per_sample_image_cost", result["sampling_not_observed"])
        self.assertIn("exact_image_lease", result["sampling_not_observed"])

    def test_terminal_rows_are_ignored_after_two_live_move_samples(self):
        rows = [self.sample_sources(action=38, tick=100),
                self.sample_sources(action=38, tick=200),
                self.sample_sources(action=39, tick=300)]
        baseline = self.sample_sources(action=37, tick=1)["image_cost_frame_lines"]
        report = probe.assess_swipe_samples(
            rows, "123", 42, baseline_image_frame_lines=baseline)
        self.assertEqual(report["status"], "observed")
        self.assertEqual(report["fresh_count"], 2)

    def test_sample_missing_viewport_stale_phase_or_wrong_pid_is_incomplete(self):
        good = self.sample_sources(action=38, tick=100)
        for rows, missing in (
                ([good, self.sample_sources(action=38, viewport=False, tick=200)],
                 "per_sample_viewport"),
                ([good, self.sample_sources(action=38, tick=200, y=100)],
                 "per_sample_fresh_phase"),
                ([good, self.sample_sources(pid="456", action=38, tick=200)],
                 "per_sample_exact_pid_epoch"),
                ([good, self.sample_sources(cost_pid="456", action=38, tick=200)],
                 "per_sample_image_cost")):
            with self.subTest(missing=missing):
                report = probe.assess_swipe_samples(rows, "123", 42)
                self.assertEqual(report["status"], "incomplete")
                self.assertIn(missing, report["not_observed"])

    def test_terminal_touch_phases_do_not_count_as_live_samples(self):
        rows = [self.sample_sources(action=37, tick=100),
                self.sample_sources(action=39, tick=200)]
        report = probe.assess_swipe_samples(rows, "123", 42)
        self.assertEqual(report["status"], "incomplete")
        self.assertIn("per_sample_live_touch_phase", report["not_observed"])

    def test_per_sample_frames_must_be_fresh_and_viewport_settled(self):
        baseline = self.sample_sources(action=37, tick=10)["image_cost_frame_lines"]
        rows = [self.sample_sources(action=38, tick=100),
                self.sample_sources(action=38, tick=200)]
        self.assertEqual(probe.assess_swipe_samples(
            rows, "123", 42, baseline_image_frame_lines=baseline)["status"], "observed")
        stale = [rows[0], dict(rows[1], image_cost_frame_lines=rows[0]["image_cost_frame_lines"])]
        report = probe.assess_swipe_samples(
            stale, "123", 42, baseline_image_frame_lines=baseline)
        self.assertEqual(report["status"], "incomplete")
        self.assertIn("per_sample_image_cost", report["not_observed"])
        forged = [rows[0], dict(rows[1], image_cost_frame_lines=["same PID frame", "frame done"])]
        report = probe.assess_swipe_samples(
            forged, "123", 42, baseline_image_frame_lines=baseline)
        self.assertEqual(report["status"], "incomplete")
        self.assertIn("per_sample_image_cost", report["not_observed"])
        unsettled = [dict(rows[0], viewport={"accepted": 100, "offset": 99, "pending": 1}), rows[1]]
        report = probe.assess_swipe_samples(
            unsettled, "123", 42, baseline_image_frame_lines=baseline)
        self.assertEqual(report["status"], "incomplete")
        self.assertIn("per_sample_viewport_settled", report["not_observed"])

    def test_repeated_hilog_phase_is_ignored_when_two_fresh_samples_exist(self):
        rows = [self.sample_sources(action=38, tick=100, y=100),
                self.sample_sources(action=38, tick=200, y=100),
                self.sample_sources(action=38, tick=300, y=200)]
        baseline = self.sample_sources(action=37, tick=1)["image_cost_frame_lines"]
        report = probe.assess_swipe_samples(
            rows, "123", 42, baseline_image_frame_lines=baseline)
        self.assertEqual(report["status"], "observed")
        self.assertEqual(report["fresh_count"], 2)

    def test_swipe_sampler_has_a_hard_sample_count_and_hilog_timeout(self):
        raw = self.sample_sources(action=37, tick=100)
        self.assertIsNotNone(raw["touch_phase"])
        touch = "09-28 12:00:00.001 123 1 I CJGUI raw touch action=38 x=1 y=20 ep=42"
        viewport = ("WINDOW_INTERACTION\nWINDOW_VIEWPORT feed offset=20 accepted=20 "
                    "content=838 viewport=420 pending=0 solves=5\nEND")
        prefix = "09-28 12:00:00.001 123 1 I CJGUI "
        cost = (prefix + "image-cost stage=frame starts=1\n" + prefix +
                "image-cost stage=frame resident=61440 idle=0 peakTracked=37748736 "
                "running=0 queued=0 bitmapCreates=1")
        rows = probe.collect_swipe_samples(
            "123", 42, "feed", lambda: touch, lambda: viewport, lambda: cost,
            threading.Event(), read_image_lease=lambda: "lease snapshot",
            max_samples=2, max_seconds=2, interval_seconds=0)
        self.assertEqual(len(rows), 2)
        self.assertTrue(all(row["image_lease_raw"] == "lease snapshot" for row in rows))

        class Hdc:
            def __init__(self):
                self.timeout = None
            def shell(self, command, timeout=30):
                self.timeout = timeout
                return touch
        hdc = Hdc()
        self.assertEqual(probe.capture_hilog(hdc, "123", "raw touch action=",
                                             timeout_seconds=1.25), touch)
        self.assertEqual(hdc.timeout, 1.25)

    def test_handwritten_sample_uses_scoped_hilog_viewport_when_public_has_none(self):
        touch = "09-28 12:00:00.001 123 1 I CJGUI raw touch action=38 x=1 y=20 ep=42"
        hand = ("09-28 12:00:00.001 123 1 I CJGUI WINDOW_VIEWPORT handwritten "
                "offset=20 accepted=20 content=838 viewport=420 pending=0 solves=5")
        row = probe.sample_swipe_once(
            "123", 42, "generated", lambda: touch,
            lambda: "WINDOW_INTERACTION\nEND", lambda: "",
            hand_semantic="handwritten", read_hand_viewport=lambda: hand)
        self.assertEqual(row["viewport"]["accepted"], 20)
        self.assertEqual(row["hand_viewport_raw"], hand)
        self.assertEqual(row["image_cost_frame"], None)

    def test_swipe_final_argument_is_velocity_and_window_uses_real_travel(self):
        args = SimpleNamespace(hdc="hdc", target="127.0.0.1:5555",
                               start_x=158, start_y=450, end_x=158, end_y=310,
                               velocity=200)
        command, seconds = probe.swipe_plan(args)
        self.assertEqual(command[-1], "200")
        self.assertAlmostEqual(seconds, 0.7)
        args.velocity = 3600
        with self.assertRaises(ValueError):
            probe.swipe_plan(args)

    def test_early_abort_archives_process_and_same_pid_touch(self):
        class Process:
            returncode = 0
            def communicate(self, timeout):
                return "UITest done", ""

        class Hdc:
            def shell(self, command, timeout=30):
                return ("09-28 12:00:00.000 456 1 I CJGUI raw touch action=37 x=1 y=2 ep=1\n"
                        "09-28 12:00:00.001 123 1 I CJGUI raw touch action=37 x=1 y=2 ep=2")

        with TemporaryDirectory() as directory:
            output = probe.archive_swipe_process(Path(directory), Hdc(), "123",
                                                  ["hdc", "swipe", "200"], Process(), 1.0)
            self.assertEqual(output["returncode"], 0)
            self.assertIn("ep=2", output["touch_raw"])
            self.assertNotIn("ep=1", output["touch_raw"])
            self.assertTrue((Path(directory) / "swipe_process.json").is_file())

    def test_foreground_guard_rejects_other_or_ambiguous_visible_root(self):
        def root(bundle):
            return {"attributes": {"type": "root", "visible": "true",
                                    "bundleName": bundle, "bounds": "[0,0][400,600]"},
                    "children": []}
        expected = "com.example.cjguiapp.htouch"
        self.assertEqual(probe.foreground_root_bundle(
            {"children": [root(expected)]}, expected), expected)
        self.assertEqual(probe.foreground_root_bundle(
            {"children": [root(expected), root("com.huawei.hmos.inputmethod")]}, expected),
            expected)
        with self.assertRaises(ValueError):
            probe.foreground_root_bundle({"children": [root("com.example.cjguiapp")]}, expected)
        with self.assertRaises(ValueError):
            probe.foreground_root_bundle(
                {"children": [root(expected), root("com.example.cjguiapp")]}, expected)
        with self.assertRaises(ValueError):
            probe.foreground_root_bundle(
                {"children": [root(expected), root("com.huawei.hmos.inputmethod"),
                              root("com.huawei.hmos.inputmethod")]}, expected)

    def test_fresh_layout_guard_fails_before_any_swipe_on_wrong_root(self):
        class Hdc:
            def __init__(self):
                self.commands = []
            def pidof(self, bundle):
                return "123"
            def shell(self, command, timeout=30):
                self.commands.append(command)
                return ""
            def pull(self, remote, local):
                self.commands.append("pull")
                local.write_text(json.dumps({"children": [{"attributes": {
                    "type": "root", "visible": "true",
                    "bundleName": "com.example.cjguiapp", "bounds": "[0,0][400,600]"}}]}))

        with TemporaryDirectory() as directory:
            hdc = Hdc()
            with self.assertRaises(ValueError):
                probe.require_fresh_foreground(
                    hdc, Path(directory), "com.example.cjguiapp.htouch", "123")
            self.assertTrue((Path(directory) / "foreground_layout.json").is_file())
            self.assertTrue(any("dumpLayout -p" in command for command in hdc.commands))

    def test_begin_survives_final_hilog_buffer_rollover(self):
        begin = {"pid": "123", "epoch": 42, "action": 37,
                 "at_ns": 10, "raw": "first observed BEGIN"}
        final = [{"pid": "123", "epoch": 42, "action": 39,
                  "at_ns": 90, "raw": "terminal after rollover"}]
        touch = probe.exact_touch_evidence(begin, final, "123", 42)
        value = self.evidence()
        value["touch"] = touch
        self.assertEqual(probe.evaluate(value)["status"], "pass")
        self.assertEqual(touch[0]["raw"], "first observed BEGIN")

    def test_missing_before_cost_uses_after_absolute_budget(self):
        frame = {"peakTracked": 37748736, "idle": 0, "running": 0}
        absolute = probe.image_absolute_budget(frame)
        value = self.evidence()
        value["writes"][0]["image_cost"] = {"peak_tracked_bytes": "not_observed",
                                              "idle_cache_bytes": "not_observed",
                                              "in_flight": "not_observed"}
        value["writes"][0]["image_cost_absolute"] = absolute
        value["writes"][0]["image_cost_delta"] = "not_observed"
        self.assertEqual(probe.evaluate(value)["status"], "pass")
        self.assertEqual(value["writes"][0]["image_cost_delta"], "not_observed")
        value["writes"][0]["ready_before"] = None
        value["writes"][0]["ready_after"] = None
        value["final_ready"] = None
        value["writes"][0]["generated_image_resource_count_before"] = 0
        value["writes"][0]["generated_image_resource_count_after"] = 0
        value["final_generated_image_resource_count"] = 0
        self.assertEqual(probe.evaluate(value)["status"], "pass")
        value["writes"][0]["renderer_image_settled"] = {"status": "not_observed"}
        self.assertEqual(probe.evaluate(value)["status"], "incomplete")

    def test_missing_ready_for_present_generated_resource_is_incomplete(self):
        value = self.evidence()
        value["writes"][0]["ready_before"] = None
        value["writes"][0]["generated_image_resource_count_before"] = 1
        result = probe.evaluate(value)
        self.assertEqual(result["status"], "incomplete")
        self.assertIn("write_1_generated_image_ready", result["not_observed"])

    def test_empty_generated_resource_scope_is_named_and_sampling_remains_incomplete(self):
        value = self.evidence()
        value["writes"][0]["ready_before"] = None
        value["writes"][0]["ready_after"] = None
        value["final_ready"] = None
        value["writes"][0]["generated_image_resource_count_before"] = 0
        value["writes"][0]["generated_image_resource_count_after"] = 0
        value["final_generated_image_resource_count"] = 0
        result = probe.evaluate(value)
        self.assertEqual(result["status"], "pass")
        self.assertEqual(result["generated_image_readiness"],
                         [{"before": "not_applicable", "after": "not_applicable"}])
        self.assertEqual(result["final_generated_image_readiness"], "not_applicable")
        self.assertEqual(result["sampling_status"], "incomplete")
        self.assertEqual(result["sampling_not_observed"],
                         ["float_remainder", "exact_image_lease",
                          "per_sample_live_touch_phase", "per_sample_viewport",
                          "per_sample_image_cost"])

    def test_archived_begin_without_observation_clock_is_incomplete_not_false_fail(self):
        value = self.evidence()
        value["touch"][0]["at_ns"] = None
        result = probe.evaluate(value)
        self.assertEqual(result["status"], "incomplete")
        self.assertNotIn("exact_pid_epoch_begin_terminal", result["failures"])

    def test_handwritten_renderer_settled_requires_same_pid_frames_and_stable_version(self):
        def frame(pid):
            prefix = f"09-28 12:00:00.001 {pid} 1 I CJGUI "
            return (prefix + "image-cost stage=frame starts=1 encoded=511 readUs=22 decodeUs=921 hits=20\n" +
                    prefix + "image-cost stage=frame resident=61440 idle=0 activeBytes=0 "
                    "peakActiveBytes=61951 reservations=0 peakTracked=37748736 running=0 queued=0 "
                    "bitmapCreates=1 bitmapDestroys=0 bitmapCreateUs=3 bitmapDestroyUs=0")
        raw = frame(123)
        self.assertEqual(probe.renderer_image_settled(raw, raw, "123", 1, 1)["status"], "observed")
        self.assertEqual(probe.renderer_image_settled(raw, raw, "123", None, 1)["status"], "not_observed")
        self.assertEqual(probe.renderer_image_settled(raw, raw, "123", 1, 2)["status"], "fail")
        self.assertEqual(probe.renderer_image_settled(raw, frame(456), "123", 1, 1)["status"],
                         "not_observed")
        self.assertEqual(probe.renderer_image_settled("", raw, "123", 1, 1)["status"],
                         "not_observed")

    def test_public_image_version_missing_is_not_observed(self):
        raw = "PROTOCOL CJGUI_SHARED_OPERATION/2\nKIND SNAPSHOT\nVERSION 7\nEND"
        self.assertIsNone(probe.parse_public_image_version(raw, 9700))
        present = raw.replace("END", "FIELD 9700 imageVersion INTEGER 2\nEND")
        self.assertEqual(probe.parse_public_image_version(present, 9700), 2)

    def test_prewrite_baseline_waits_for_same_pid_settled_frame_and_archives(self):
        self.assertTrue(hasattr(probe, "capture_prewrite_image_baseline"))
        context = ("PROTOCOL CJGUI_SHARED_OPERATION/2\nKIND SNAPSHOT\nVERSION 7\n"
                   "FIELD 9801 imageVersion INTEGER 1\nEND")
        prefix = "09-28 12:00:00.001 123 1 I CJGUI "
        settled = (prefix + "image-cost stage=frame starts=1\n" + prefix +
                   "image-cost stage=frame resident=61440 idle=0 peakTracked=37748736 "
                   "running=0 queued=0 bitmapCreates=1")
        samples = iter(["", settled.replace(" 123 ", " 456 "), settled])
        with TemporaryDirectory() as directory:
            path = Path(directory) / "write_1_prewrite.json"
            baseline = probe.capture_prewrite_image_baseline(
                "123", 9801, lambda: context, lambda: next(samples), path,
                timeout_seconds=1.0, max_samples=3, pause=lambda _: None)
            self.assertEqual(baseline["status"], "observed")
            self.assertEqual(baseline["image_version"], 1)
            self.assertEqual(baseline["attempts"], 3)
            self.assertEqual(probe.same_pid_image_frame(baseline["image_cost_raw"], "123")["resident"], 61440)
            self.assertEqual(json.loads(path.read_text())["samples"][1]["frame"], None)

    def test_prewrite_baseline_timeout_is_archived_and_remains_incomplete(self):
        self.assertTrue(hasattr(probe, "capture_prewrite_image_baseline"))
        context = "PROTOCOL CJGUI_SHARED_OPERATION/2\nKIND SNAPSHOT\nVERSION 7\nEND"
        ticks = iter([0.0, 0.11, 0.22])
        with TemporaryDirectory() as directory:
            path = Path(directory) / "write_1_prewrite.json"
            baseline = probe.capture_prewrite_image_baseline(
                "123", 9801, lambda: context, lambda: "", path,
                timeout_seconds=0.1, max_samples=6,
                clock=lambda: next(ticks), pause=lambda _: None)
            self.assertEqual(baseline["status"], "not_observed")
            self.assertEqual(baseline["reason"], "version_or_settled_frame_missing")
            self.assertEqual(baseline["image_cost_raw"], "")
            self.assertEqual(json.loads(path.read_text())["status"], "not_observed")
            self.assertEqual(probe.renderer_image_settled(
                baseline["image_cost_raw"], "", "123", baseline["image_version"], None)["status"],
                "not_observed")
            evidence = self.evidence()
            evidence["writes"][0]["renderer_image_settled"] = {"status": baseline["status"]}
            self.assertEqual(probe.evaluate(evidence)["status"], "incomplete")


if __name__ == "__main__":
    unittest.main()

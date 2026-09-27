#!/usr/bin/env python3
"""A held real generation must be the one retired and released."""

import os
from pathlib import Path
import sys
import tempfile
import unittest
from types import SimpleNamespace
from unittest.mock import patch

os.environ.setdefault("CJGUI_OHOS_VERIFICATION_DIR", tempfile.mkdtemp(prefix="cjgui-trace-unit-"))
sys.path.insert(0, str(Path(__file__).resolve().parent))

import verify_surface_lifecycle_probe as probe  # noqa: E402

create_hold_retirement_proof = probe.create_hold_retirement_proof
flush_hold_retirement_proof = probe.flush_hold_retirement_proof


class CreateHoldTraceTest(unittest.TestCase):
    def setUp(self):
        self.good = [
            "surface created id=cjgui gen=8 nativeref rc=0 published=1",
            "create_before hold enter gen=8",
            "surface destroyed gen=8: teardown requested rc=0",
            "create_before hold exit gen=8",
            "surface create skipped: permit denied before create gen=8",
            "surface ref released on UI thread gen=8 rc=0 unrefs=1 pending=0",
        ]

    def test_same_generation_and_order_proves_retirement(self):
        ok, proof = create_hold_retirement_proof(self.good)
        self.assertTrue(ok)
        self.assertEqual(proof["generation"], 8)

    def test_old_destroy_and_wrong_generation_cannot_prove_race(self):
        stale = [self.good[2], *self.good[:2], *self.good[3:]]
        self.assertFalse(create_hold_retirement_proof(stale)[0])
        wrong = self.good.copy()
        wrong[2] = "surface destroyed gen=9: teardown requested rc=0"
        self.assertFalse(create_hold_retirement_proof(wrong)[0])

    def test_missing_or_duplicate_unref_is_not_safe_completion(self):
        self.assertFalse(create_hold_retirement_proof(self.good[:-1])[0])
        self.assertFalse(create_hold_retirement_proof(self.good + [self.good[-1]])[0])

    def test_committing_retirement_requires_abort_before_unref(self):
        good = [
            "flush hold enter gen=12",
            "surface destroyed gen=12: teardown requested rc=0",
            "flush hold exit gen=12",
            "present flush aborted on retired lease gen=12",
            "surface ref released on UI thread gen=12 rc=0 unrefs=2 pending=0",
        ]
        self.assertTrue(flush_hold_retirement_proof(good)[0])
        wrong = good.copy()
        wrong[1] = "surface destroyed gen=13: teardown requested rc=0"
        self.assertFalse(flush_hold_retirement_proof(wrong)[0])
        early_release = good.copy()
        early_release[3], early_release[4] = early_release[4], early_release[3]
        self.assertFalse(flush_hold_retirement_proof(early_release)[0])


class StopTerminalTraceTest(unittest.TestCase):
    def evaluate(self, lines, pid="24049", app_instance=1):
        def old_global_tail(pattern, _n=1):
            return next((line for line in reversed(lines) if pattern in line), "")
        with (patch.object(probe, "bind_identity", return_value={"pid": pid,
                                                                  "appInstance": app_instance}),
              patch.object(probe, "instance_hilog_lines", return_value=lines),
              patch.object(probe, "hilog_tail", side_effect=old_global_tail)):
            return probe.stop_terminal_ok()

    def test_rev3_c7_status_99_cannot_borrow_next_pid_success(self):
        # sim_real_lifecycle_rev3 C7 recorded status=99/done=0 for PID 24049.
        # A later C8 PID's successful tail must not turn that C7 stop green.
        c7 = [
            "09-27 18:16:20.000 24049 24297 I A00000/CjguiHost: CLOSE_WINDOW: host phase=stopping appInstance=1",
            "09-27 18:16:39.260 24049 24297 I A00000/CjguiApp: transport closing: closed=true queued=0 conns=0 inflight=0 lifecycle=2",
            "09-27 18:16:39.270 24049 24297 I A00000/CjguiApp: host closed; stop_requested=false render_shutdown_status=99 shutdown_done=0 ticks=9",
        ]
        stale_success = (
            "09-27 18:16:47.750 24251 25390 I A00000/CjguiApp: "
            "host closed; stop_requested=false render_shutdown_status=0 shutdown_done=1 ticks=130"
        )
        with (patch.object(probe, "bind_identity", return_value={"pid": "24049", "appInstance": 1}),
              patch.object(probe, "instance_hilog_lines", return_value=c7),
              patch.object(probe, "hilog_tail", side_effect=lambda pat, _n=1:
                           stale_success if pat == "host closed" else
                           "09-27 18:16:47.740 24251 25390 I A00000/CjguiApp: "
                           "transport closing: closed=true queued=0 conns=0 inflight=0 lifecycle=2")):
            self.assertFalse(probe.stop_terminal_ok()[0])

    def test_status_zero_without_same_instance_settled_is_incomplete(self):
        lines = [
            "09-27 18:16:20.000 24049 24297 I A00000/CjguiHost: CLOSE_WINDOW: host phase=stopping appInstance=1",
            "09-27 18:16:39.260 24049 24297 I A00000/CjguiApp: transport closing: closed=true queued=0 conns=0 inflight=0 lifecycle=2",
            "09-27 18:16:39.270 24049 24297 I A00000/CjguiApp: host closed; render_shutdown_status=0 shutdown_done=1",
        ]
        self.assertFalse(self.evaluate(lines)[0])
        wrong_app = lines + [
            "09-27 18:16:39.300 24049 24297 I A00000/CjguiHost: stop settled appInstance=2 ownerJoined=1 rendererDone=1 sessions=0 unacked=0 pending=0 refsUnclosed=0 activeSurfaces=0 (phase=stopped)"
        ]
        self.assertFalse(self.evaluate(wrong_app)[0])

    def test_same_instance_full_zero_terminal_passes(self):
        lines = [
            "09-27 18:16:20.000 24049 24297 I A00000/CjguiHost: CLOSE_WINDOW: host phase=stopping appInstance=1",
            "09-27 18:16:39.260 24049 24297 I A00000/CjguiApp: transport closing: closed=true queued=0 conns=0 inflight=0 lifecycle=2",
            "09-27 18:16:39.270 24049 24297 I A00000/CjguiApp: host closed; render_shutdown_status=0 shutdown_done=1",
            "09-27 18:16:39.300 24049 24297 I A00000/CjguiHost: stop settled appInstance=1 ownerJoined=1 rendererDone=1 sessions=0 unacked=0 pending=0 refsUnclosed=0 activeSurfaces=0 (phase=stopped)",
        ]
        ok, detail = self.evaluate(lines)
        self.assertTrue(ok, detail)
        bad_status = lines.copy()
        bad_status[2] = bad_status[2].replace("status=0 shutdown_done=1",
                                               "status=99 shutdown_done=0")
        self.assertFalse(self.evaluate(bad_status)[0])
        interposed = lines[:3] + [
            "09-27 18:16:39.290 24049 24297 I A00000/CjguiHost: startHost accepted: phase=starting appInstance=2"
        ] + lines[3:]
        self.assertFalse(self.evaluate(interposed)[0])


class RenderTicketTraceTest(unittest.TestCase):
    @staticmethod
    def row(message, pid="24049"):
        return f"09-27 18:16:20.000 {pid} 24297 W A00000/CjguiRenderer: {message}"

    def test_queued_needs_named_active_ticket_then_one_terminal(self):
        held = getattr(probe, "ticket_stage_at_close", None)
        terminal = getattr(probe, "ticket_terminal_after_close", None)
        self.assertIsNotNone(held)
        self.assertIsNotNone(terminal)
        generic = [self.row("test gate holding dequeue ms=30000")]
        self.assertFalse(held(generic, "24049", "queued")[0])
        before = [self.row("test gate holding dequeue session=7 ticket=12 gen=42")]
        ok, witness = held(before, "24049", "queued")
        self.assertTrue(ok, witness)
        after = before + [
            self.row("verify stop host requested from UI"),
            self.row("stopHost requested (started=1 phase=running appInstance=1)"),
            self.row("stopHost: host phase=stopping appInstance=1; requesting application stop"),
            self.row("test gate dequeue released session=7 ticket=12 gen=42"),
            self.row("present terminal session=7 ticket=12 status=6 phase=4"),
        ]
        self.assertTrue(terminal(after, "24049", "queued", witness, 1)[0])
        self.assertFalse(held(after, "24049", "queued")[0])
        late_close = before + [
            self.row("present terminal session=7 ticket=12 status=6 phase=4"),
            self.row("verify stop host requested from UI"),
            self.row("stopHost requested (started=1 phase=running appInstance=1)"),
            self.row("stopHost: host phase=stopping appInstance=1; requesting application stop"),
            self.row("test gate dequeue released session=7 ticket=12 gen=42"),
        ]
        self.assertFalse(terminal(late_close, "24049", "queued", witness, 1)[0])
        wrong_pid = before + [row.replace(" 24049 ", " 24251 ") for row in after[1:4]] + after[4:]
        self.assertFalse(terminal(wrong_pid, "24049", "queued", witness, 1)[0])
        wrong_app = before + [after[1], after[2].replace("appInstance=1", "appInstance=2"),
                              after[3].replace("appInstance=1", "appInstance=2"), *after[4:]]
        self.assertFalse(terminal(wrong_app, "24049", "queued", witness, 1)[0])

    def test_committing_requires_same_ticket_settlement_and_ack_once(self):
        held = getattr(probe, "ticket_stage_at_close", None)
        terminal = getattr(probe, "ticket_terminal_after_close", None)
        self.assertIsNotNone(held)
        self.assertIsNotNone(terminal)
        before = [
            self.row("flush hold enter gen=42 session=7 ticket=12"),
            self.row("present pending ticket=12 (committing timeout)"),
        ]
        ok, witness = held(before, "24049", "committing")
        self.assertTrue(ok, witness)
        after = before + [
            self.row("verify stop host requested from UI"),
            self.row("stopHost requested (started=1 phase=running appInstance=1)"),
            self.row("stopHost: host phase=stopping appInstance=1; requesting application stop"),
            self.row("flush hold exit gen=42 session=7 ticket=12"),
            self.row("pending settlement aborted ticket=12 status=6"),
            self.row("present ticket acknowledged id=12"),
        ]
        self.assertTrue(terminal(after, "24049", "committing", witness, 1)[0])
        duplicate = after + [self.row("pending settlement aborted ticket=12 status=6")]
        self.assertFalse(terminal(duplicate, "24049", "committing", witness, 1)[0])
        wrong_pid = before + [
            self.row("flush hold exit gen=42 session=7 ticket=12", pid="24251"),
            self.row("pending settlement aborted ticket=12 status=6", pid="24251"),
            self.row("present ticket acknowledged id=12", pid="24251"),
        ]
        self.assertFalse(terminal(wrong_pid, "24049", "committing", witness, 1)[0])
        stale_close = before + [self.row("verify close: host.close() via production path"),
                                *after[4:]]
        self.assertFalse(terminal(stale_close, "24049", "committing", witness, 1)[0])

    def test_startup_flush_hold_before_new_arm_cannot_be_target(self):
        lines = [
            self.row("flush hold enter gen=1 session=1 ticket=1"),
            self.row("present pending ticket=1 (committing timeout)"),
            self.row("verify gate GATE_FLUSH_HOLD_30000 -> flush_hold=0"),
        ]
        self.assertFalse(probe.ticket_stage_at_close(lines, "24049", "committing")[0])

    def test_startup_ticket_must_exit_settle_and_ack_before_new_gate(self):
        startup = [
            self.row("flush hold enter gen=1 session=1 ticket=1"),
            self.row("present pending ticket=1 (committing timeout)"),
            self.row("flush hold exit gen=1 session=1 ticket=1"),
            self.row("present frame ok (nodes=22)"),
            self.row("pending settlement committed ticket=1 frame=1"),
            self.row("present ticket acknowledged id=1"),
        ]
        self.assertFalse(probe.startup_ticket_settled(startup[:2], "24049")[0])
        self.assertFalse(probe.startup_ticket_settled(startup[:5], "24049")[0])
        self.assertTrue(probe.startup_ticket_settled(startup, "24049")[0])
        self.assertFalse(probe.startup_ticket_settled(
            startup + [self.row("flush hold enter gen=1 session=1 ticket=2")], "24049")[0])
        self.assertFalse(probe.startup_ticket_settled(
            [row.replace(" 24049 ", " 24251 ") for row in startup], "24049")[0])

    def test_business_ticket_must_be_next_ticket_after_settled_startup(self):
        rows = [
            self.row("verify gate GATE_FLUSH_HOLD_30000 -> flush_hold=0"),
            self.row("flush hold enter gen=1 session=1 ticket=3"),
            self.row("present pending ticket=3 (committing timeout)"),
        ]
        self.assertTrue(probe.ticket_stage_at_close(rows, "24049", "committing")[0])
        self.assertFalse(probe.ticket_stage_at_close(
            rows, "24049", "committing", expected_ticket=2)[0])


class StopHostUiDriverTest(unittest.TestCase):
    @staticmethod
    def node(text, bounds="[990,2489][1320,2629]", **attributes):
        return {"attributes": {"text": text, "type": "Button", "bounds": bounds,
                               "visible": "true", "enabled": "true", "clickable": "true",
                               **attributes}, "children": []}

    def test_layout_button_center_is_exact_unique_visible_button(self):
        layout = {"attributes": {}, "children": [self.node("STATE"),
                  {"attributes": {}, "children": [self.node("STOP HOST")]}]}
        self.assertEqual(probe.ui_button_center(layout, "STOP HOST"), (1155, 2559))
        with self.assertRaises(AssertionError):
            probe.ui_button_center(layout, "STOP")
        duplicate = {"children": [self.node("STOP HOST"), self.node("STOP HOST")]}
        with self.assertRaises(AssertionError):
            probe.ui_button_center(duplicate, "STOP HOST")
        hidden = {"children": [self.node("STOP HOST", visible="false")]}
        with self.assertRaises(AssertionError):
            probe.ui_button_center(hidden, "STOP HOST")
        malformed = {"children": [self.node("STOP HOST", bounds="[0,0][0,10]")]}
        with self.assertRaises(AssertionError):
            probe.ui_button_center(malformed, "STOP HOST")

    def test_hdc_ui_command_is_target_bound_and_failure_is_not_click(self):
        with patch.object(probe, "TARGET", "127.0.0.1:5555"), patch.object(
                probe, "RAW_HDC", ""), patch.object(
                probe.subprocess, "run", return_value=SimpleNamespace(
                    returncode=0, stdout="", stderr="")) as run:
            probe.targeted_hdc("shell", "uitest uiInput click 1155 2559")
        self.assertEqual(run.call_args.args[0][:4],
                         [probe.HDC, "-t", "127.0.0.1:5555", "shell"])
        with (patch.object(probe, "TARGET", "127.0.0.1:5555"),
              patch.object(probe, "HDC", "/tmp/hdc-target.sh"),
              patch.object(probe, "RAW_HDC", "/sdk/toolchains/hdc"),
              patch.object(probe.subprocess, "run", return_value=SimpleNamespace(
                  returncode=0, stdout="", stderr="")) as run):
            probe.targeted_hdc("shell", "uitest uiInput click 1155 2559")
        self.assertEqual(run.call_args.args[0][:4],
                         ["/sdk/toolchains/hdc", "-t", "127.0.0.1:5555", "shell"])
        with patch.object(probe, "TARGET", ""):
            with self.assertRaises(AssertionError):
                probe.targeted_hdc("shell", "uitest uiInput click 1155 2559")

    def test_state_refresh_precedes_stop_host_discovery(self):
        state = {"children": [self.node("STATE")]}
        stop = {"children": [self.node("STATE"), self.node("STOP HOST")]}
        with (patch.object(probe, "targeted_pid", return_value="24049"),
              patch.object(probe, "dump_target_layout", side_effect=[state, stop]),
              patch.object(probe, "tap_target_button") as tap):
            center = probe.prepare_stop_host_ui("24049", "C7", {})
        self.assertEqual(center, (1155, 2559))
        tap.assert_called_once_with((1155, 2559))


if __name__ == "__main__":
    unittest.main()

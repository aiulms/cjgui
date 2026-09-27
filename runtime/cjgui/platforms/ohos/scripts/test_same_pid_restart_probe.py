#!/usr/bin/env python3
"""Offline counterexamples for the current real-backend same-PID restart probe."""

import importlib.util
import tempfile
import unittest
from pathlib import Path


SCRIPT = Path(__file__).with_name("verify_same_pid_restart_probe.py")


def load_probe():
    if not SCRIPT.is_file():
        return None
    spec = importlib.util.spec_from_file_location("verify_same_pid_restart_probe", SCRIPT)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


probe = load_probe()


def row(message, pid="5700"):
    return f"09-27 19:20:01.123 {pid} 5701 I A00000/CjguiHost: {message}"


def initial_rows(token="tfresh"):
    return [
        row("startHost accepted: phase=starting appInstance=1"),
        row(f"verify seam armed token={token}"),
        row("surface created id=cjgui_surface 1320x1838 gen=1 comp=1 app=1 "
            "nativeref rc=0 published=1 refs=1"),
        row("host started; pumping turns"),
        row("present frame ok (nodes=22)"),
    ]


def stop_rows():
    return [
        row("verify stop host requested from UI"),
        row("stopHost requested (started=1 phase=running appInstance=1)"),
        row("stopHost: host phase=stopping appInstance=1; requesting application stop"),
        row("transport closing: closed=true queued=0 conns=0 inflight=0 lifecycle=2"),
        row("host closed; render_shutdown_status=0 shutdown_done=1"),
        row("stop settled appInstance=1 ownerJoined=1 rendererDone=1 "
            "rendererNotStarted=0 sessions=0 unacked=0 pending=0 refsUnclosed=0 "
            "activeSurfaces=0 (phase=stopped)"),
    ]


def restart_rows():
    return [
        row("verify restart host requested from UI"),
        row("startHost accepted: phase=starting appInstance=2"),
        row("verify seam armed token=tnew"),
        row("surface created id=cjgui_surface 1320x1838 gen=2 comp=1 app=2 "
            "nativeref rc=0 published=1 refs=1"),
        row("owner declared ready: host phase=running (appInstance=2)"),
        row("present frame ok (nodes=22)"),
    ]


class SamePidTraceTest(unittest.TestCase):
    def setUp(self):
        self.assertIsNotNone(probe, "the focused probe must exist")

    def test_current_launch_real_ref_and_frame(self):
        proof = probe.initial_proof(initial_rows(), "5700", 1, "tfresh")
        self.assertEqual(proof["appInstance"], 1)
        self.assertIn("nativeref rc=0", proof["publication"])
        for rows in (
            initial_rows("told"),
            [*initial_rows()[:-1], row("present frame ok", pid="6336")],
            [row("present frame ok"), *initial_rows()[:-1]],
            [line.replace("app=1 ", "app=2 ") for line in initial_rows()],
        ):
            with self.assertRaises(AssertionError):
                probe.initial_proof(rows, "5700", 1, "tfresh")
        with self.assertRaises(AssertionError):
            probe.initial_proof(initial_rows() + [
                row("startHost accepted: phase=starting appInstance=2"),
                row("verify seam armed token=tnew")], "5700", 1, "tfresh")

    def test_stop_requires_ui_request_and_ordered_full_zero_for_old_instance(self):
        self.assertEqual(probe.stop_proof(stop_rows(), "5700", 1)["appInstance"], 1)
        for rows in (
            stop_rows()[1:],
            [*stop_rows()[:3], stop_rows()[-1], *stop_rows()[3:-1]],
            [line.replace("appInstance=1", "appInstance=2") for line in stop_rows()],
            [line.replace("refsUnclosed=0", "refsUnclosed=1") for line in stop_rows()],
            [line.replace("rendererDone=1", "rendererDone=0") for line in stop_rows()],
            [line.replace(" 5700 ", " 6336 ") for line in stop_rows()],
        ):
            with self.assertRaises(AssertionError):
                probe.stop_proof(rows, "5700", 1)

    def test_restart_requires_ui_new_identity_native_ref_and_first_frame(self):
        proof = probe.restart_proof(restart_rows(), "5700", 1, "tfresh")
        self.assertEqual(proof["appInstance"], 2)
        self.assertEqual(proof["token"], "tnew")
        bad = [
            restart_rows()[1:],
            [line.replace("appInstance=2", "appInstance=1").replace("app=2 ", "app=1 ")
             for line in restart_rows()],
            [line.replace("token=tnew", "token=tfresh") for line in restart_rows()],
            [line.replace("nativeref rc=0", "nativeref rc=-1") for line in restart_rows()],
            [*restart_rows()[:-1], row("present frame ok", pid="6336")],
        ]
        for rows in bad:
            with self.assertRaises(AssertionError):
                probe.restart_proof(rows, "5700", 1, "tfresh")
        interposed = restart_rows()[:-1] + [
            row("startHost accepted: phase=starting appInstance=3"),
            row("present frame ok (nodes=22)"),
        ]
        with self.assertRaises(AssertionError):
            probe.restart_proof(interposed, "5700", 1, "tfresh")

    def test_restart_accepts_live_mount_republish_with_real_reference(self):
        rows = restart_rows()
        rows[3:4] = [
            row("ref abi probe obj=123 rc=0 rcIsObjLow32=0 "
                "provider=/system/lib64/chipset-pub-sdk/libsurface.z.so held=1 degradedActive=0"),
            row("simulate surface created gen=2 1320x1838 refs=2"),
        ]
        self.assertEqual(probe.restart_proof(rows, "5700", 1, "tfresh")["appInstance"], 2)
        with self.assertRaises(AssertionError):
            probe.restart_proof([line.replace("held=1", "held=0") for line in rows],
                                "5700", 1, "tfresh")

    def test_new_first_frame_may_precede_owner_ready(self):
        rows = restart_rows()
        rows[-2], rows[-1] = rows[-1], rows[-2]
        proof = probe.restart_proof(rows, "5700", 1, "tfresh")
        self.assertIn("present frame ok", proof["frame"])

    def test_delta_rejects_hilog_rollover_or_old_tail(self):
        before = initial_rows()
        self.assertEqual(probe.tail_since(before, before + stop_rows()), stop_rows())
        with self.assertRaises(AssertionError):
            probe.tail_since(before, before[1:] + stop_rows())

    def test_app_trace_ignores_reordered_system_lines_in_same_pid(self):
        old_system = "09-27 19:20:01.123 5700 5701 I C01d02/accessibility: old"
        new_system = "09-27 19:20:01.124 5700 5701 I C01d02/accessibility: new"
        before = probe.app_trace_lines(initial_rows() + [old_system], "5700")
        after = probe.app_trace_lines(initial_rows() + [new_system] + stop_rows(), "5700")
        self.assertEqual(probe.tail_since(before, after), stop_rows())


class RunAndOwnerTest(unittest.TestCase):
    def setUp(self):
        self.assertIsNotNone(probe, "the focused probe must exist")

    def test_bootstrap_binds_fresh_hap_pid_token_and_target(self):
        import hashlib
        with tempfile.TemporaryDirectory() as tmp:
            run = Path(tmp) / "probe-run"
            run.mkdir()
            hap = Path(tmp) / "entry.hap"
            hap.write_bytes(b"current-hap")
            digest = hashlib.sha256(hap.read_bytes()).hexdigest()
            (run / "hap_sha256.txt").write_text(digest + "\n")
            (run / "pid_probe-run.txt").write_text("pid=5700\n")
            (run / "variant_probe-run.txt").write_text("verify-transport+test-gates\n")
            (run / "startup_assert_probe-run.txt").write_text(
                f"run_id=probe-run\nhap_sha256={digest}\nbuild_variant=verify-transport+test-gates\n"
                "log_cleared=ok\nlaunch_pid=5700\nlaunch_id=unique-launch\n")
            (run / "runlog_probe-run.txt").write_text("\n".join(initial_rows()) + "\n")
            (run / "requested_identity.txt").write_text(
                "run_id=probe-run\ntarget=127.0.0.1:5555\n")
            (run / "install_probe-run.txt").write_text(
                f"[Info]App install path:{hap} msg:install bundle successfully.\n")
            proof = probe.bootstrap_proof(run, hap, "5700", "127.0.0.1:5555")
            self.assertEqual(proof["token"], "tfresh")
            self.assertEqual(proof["appInstance"], 1)
            (run / "install_probe-run.txt").write_text("install failed\n")
            with self.assertRaises(AssertionError):
                probe.bootstrap_proof(run, hap, "5700", "127.0.0.1:5555")
            (run / "install_probe-run.txt").write_text(
                f"[Info]App install path:{hap} msg:install bundle successfully.\n")
            (run / "pid_probe-run.txt").write_text("pid=6336\n")
            with self.assertRaises(AssertionError):
                probe.bootstrap_proof(run, hap, "5700", "127.0.0.1:5555")
            (run / "pid_probe-run.txt").write_text("pid=5700\n")
            (run / "startup_assert_probe-run.txt").write_text("log_cleared=failed\n")
            with self.assertRaises(AssertionError):
                probe.bootstrap_proof(run, hap, "5700", "127.0.0.1:5555")

    def test_owner_read_and_authorized_result_are_exact(self):
        before = ("PROTOCOL CJGUI_SHARED_OPERATION/2\nKIND SNAPSHOT\nVERSION 4\n"
                  "FIELD 9700 count INTEGER 7\nEND")
        after = before.replace("VERSION 4", "VERSION 5").replace("INTEGER 7", "INTEGER 8")
        result = ("PROTOCOL CJGUI_SHARED_OPERATION/2\nKIND RESULT\nAPPLIED true\n"
                  "CONFLICT false\nVERSION_BEFORE 4\nVERSION_AFTER 5\nEND")
        self.assertEqual(probe.owner_state_of(before), {"version": 4, "count": 7})
        probe.assert_authorized_write_readback(before, result, after)
        with self.assertRaises(AssertionError):
            probe.assert_authorized_write_readback(before, result, after.replace("INTEGER 8", "INTEGER 7"))
        with self.assertRaises(AssertionError):
            probe.assert_authorized_write_readback(before, result.replace("APPLIED true", "APPLIED false"), after)

    def test_forward_target_must_match_exact_device_port(self):
        listing = "127.0.0.1:5555 tcp:17856 tcp:7856 [Forward]\n"
        probe.assert_forward_target(listing, "127.0.0.1:5555", 17856)
        for target, port, text in (
            ("other:5555", 17856, listing),
            ("127.0.0.1:5555", 17857, listing),
            ("127.0.0.1:5555", 17856, listing.replace("7856", "7857")),
        ):
            with self.assertRaises(AssertionError):
                probe.assert_forward_target(text, target, port)


if __name__ == "__main__":
    unittest.main()

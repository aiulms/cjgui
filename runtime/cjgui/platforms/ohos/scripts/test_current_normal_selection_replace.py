#!/usr/bin/env python3
"""Offline counterexamples for the current normal-HAP selection probe."""

import hashlib
import importlib.util
import tempfile
import unittest
from pathlib import Path
from types import SimpleNamespace


SCRIPT = Path(__file__).with_name("verify_current_normal_selection_replace.py")


def load_probe():
    if not SCRIPT.is_file():
        return None
    spec = importlib.util.spec_from_file_location("current_normal_selection", SCRIPT)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


probe = load_probe()


def row(message, pid="25754"):
    return f"09-27 19:42:48.787 {pid} {pid} I A00000/CjguiApp: {message}"


def snapshot(version, value, resource=9700, field="name"):
    encoded = value.encode("utf-8")
    return ("PROTOCOL CJGUI_SHARED_OPERATION/2\nKIND SNAPSHOT\n"
            f"VERSION {version}\nFIELD {resource} {field} STRING "
            f"{len(encoded)} {encoded.hex().upper() if encoded else '-'}\nEND")


class CurrentNormalSelectionTests(unittest.TestCase):
    def setUp(self):
        self.assertIsNotNone(probe, "current normal-HAP probe must exist")

    def test_identity_and_pid_are_bound_to_current_normal_hap(self):
        with tempfile.TemporaryDirectory() as tmp:
            hap = Path(tmp) / "current.hap"
            hap.write_bytes(b"normal-hap")
            digest = hashlib.sha256(hap.read_bytes()).hexdigest()
            identity = (f"target=127.0.0.1:5555\npid=25754\n"
                        f"hap_sha256={digest}\nbuild_variant=normal\n")
            self.assertEqual(probe.assert_identity(identity, "127.0.0.1:5555", hap), "25754")
            for bad in (identity.replace("pid=25754", "pid=28981"),
                        identity.replace("build_variant=normal", "build_variant=verify-transport"),
                        identity.replace("127.0.0.1:5555", "other:5555"),
                        identity.replace(digest, "0" * 64)):
                with self.assertRaises(AssertionError):
                    probe.assert_identity(bad, "127.0.0.1:5555", hap,
                                          expected_pid="25754")
            self.assertEqual(probe.assert_same_pid("25754", "25754\n"), "25754")
            for actual in ("28981\n", "25754 28981\n", "", "not-a-pid"):
                with self.assertRaises(AssertionError):
                    probe.assert_same_pid("25754", actual)

    def test_selection_is_fresh_nonempty_same_pid_and_mount(self):
        mount = "app1/s1/c3/e1/m3"
        before = [row(f"ime proxy FOCUSED field=counter-name mount={mount}"),
                  row(f"ime select [6,6) rc=0 mount={mount}")]
        after = before + [row(f"ime select [0,10) rc=0 mount={mount}")]
        self.assertEqual(probe.assert_fresh_selection(before, after, "25754", mount), (0, 10))
        bad_suffixes = [
            [],
            [row(f"ime select [0,0) rc=0 mount={mount}")],
            [row(f"ime select [0,10) rc=0 mount={mount}", "28981")],
            [row("ime select [0,10) rc=0 mount=app1/s1/c2/e1/m2")],
            [row(f"ime select [0,10) rc=-1 mount={mount}")],
        ]
        for suffix in bad_suffixes:
            with self.assertRaises(AssertionError):
                probe.assert_fresh_selection(before, before + suffix, "25754", mount)
        with self.assertRaises(AssertionError):
            probe.assert_fresh_selection(before, before[1:] + after[-1:], "25754", mount)

    def test_draft_stays_out_of_owner_then_exact_commit_advances_one_version(self):
        before = probe.parse_owner(snapshot(7, "旧值😀"), 9700, "name")
        draft = probe.parse_owner(snapshot(7, "旧值😀"), 9700, "name")
        after = probe.parse_owner(snapshot(8, "替换后文本🚀"), 9700, "name")
        probe.assert_draft_unchanged(before, draft)
        probe.assert_exact_commit(before, after, "替换后文本🚀")
        for bad in (snapshot(8, "旧值😀"), snapshot(7, "改了")):
            with self.assertRaises(AssertionError):
                probe.assert_draft_unchanged(before, probe.parse_owner(bad, 9700, "name"))
        for bad in (snapshot(8, "替换后文本"), snapshot(9, "替换后文本🚀"),
                    snapshot(7, "替换后文本🚀")):
            with self.assertRaises(AssertionError):
                probe.assert_exact_commit(before, probe.parse_owner(bad, 9700, "name"),
                                          "替换后文本🚀")
        with self.assertRaises(AssertionError):
            probe.parse_owner(snapshot(7, "旧值😀").replace("STRING 10", "STRING 9"),
                              9700, "name")

    def test_target_bound_forward_requires_fresh_port_and_success_receipt(self):
        listing = "127.0.0.1:5555 tcp:17932 tcp:7856 [Forward]\n"
        probe.assert_forward_map("", "127.0.0.1:5555", 17932, 7856, present=False)
        probe.assert_forward_map(listing, "127.0.0.1:5555", 17932, 7856, present=True)
        for bad in (listing.replace("5555", "5556"),
                    listing.replace("7856", "7857"), listing + listing):
            with self.assertRaises(AssertionError):
                probe.assert_forward_map(bad, "127.0.0.1:5555", 17932, 7856,
                                         present=True)
        with self.assertRaises(AssertionError):
            probe.assert_forward_map(listing, "127.0.0.1:5555", 17932, 7856,
                                     present=False)
        self.assertTrue(probe.forward_create_succeeded(0, "Forwardport result:OK\r\n", ""))
        for rc, stdout, stderr in ((32, "Forwardport result:OK", ""),
                                   (0, "", ""), (0, "Forwardport result:OK", "[Fail]")):
            self.assertFalse(probe.forward_create_succeeded(rc, stdout, stderr))
        self.assertEqual(
            probe.target_command("/sdk/hdc", "127.0.0.1:5555", "fport",
                                 "tcp:17932", "tcp:7856"),
            ["/sdk/hdc", "-t", "127.0.0.1:5555", "fport", "tcp:17932", "tcp:7856"])

    def test_bundle_contract_rejects_cross_consumer_configuration(self):
        self.assertEqual(probe.assert_bundle_contract("com.example.cjguiapp", "name",
                                                     "cjgui-settings-counter-agent-20260925"),
                         (9700, 7856, "counter-name"))
        self.assertEqual(probe.assert_bundle_contract("com.example.cjguithermo", "note",
                                                     "cjgui-thermo-agent-20260926"),
                         (9801, 7857, "thermo-note"))
        with self.assertRaises(AssertionError):
            probe.assert_bundle_contract("com.example.cjguithermo", "name",
                                         "cjgui-settings-counter-agent-20260925")

    def test_focus_draft_submit_and_system_menu_use_fresh_current_mount(self):
        mount = "app1/s1/c3/e1/m3"
        before = [row("ime proxy onChange len=6 verdict=ok mount=" + mount)]
        focused = before + [row("ime proxy FOCUSED field=counter-name mount=" + mount)]
        self.assertEqual(probe.assert_fresh_focus(before, focused, "25754",
                                                 "counter-name"), mount)
        selected = focused + [row("ime select [0,6) rc=0 mount=" + mount)]
        draft = selected + [row("ime proxy onChange len=0 verdict=ok mount=" + mount),
                            row("ime proxy onChange len=5 verdict=ok mount=" + mount)]
        self.assertEqual(probe.assert_fresh_draft(selected, draft, "25754", mount), [0, 5])
        submitted = draft + [row("ime proxy submit verdict=ok mount=" + mount)]
        probe.assert_fresh_submit(draft, submitted, "25754", mount)
        for bad in (draft[:-1], draft + [row("ime proxy onChange len=7 verdict=ok "
                                           "mount=app1/s1/c2/e1/m2")]):
            with self.assertRaises(AssertionError):
                probe.assert_fresh_draft(selected, bad, "25754", mount)
        with self.assertRaises(AssertionError):
            probe.assert_fresh_submit(draft, draft + [row("ime proxy submit verdict=ok "
                                                         "mount=app1/s1/c2/e1/m2")],
                                      "25754", mount)
        tree = {"attributes": {}, "children": [
            {"attributes": {"text": "全选", "bounds": "[322,464][421,521]"},
             "children": []}]}
        self.assertEqual(probe.menu_point(tree), (371, 492))
        with self.assertRaises(AssertionError):
            probe.menu_point({"attributes": {}, "children": []})

    def test_forward_lease_only_removes_its_confirmed_exact_mapping(self):
        class FakeHdc:
            target = "127.0.0.1:5555"

            def __init__(self, *, creation_rc=0):
                self.calls = []
                self.mapping = ""
                self.creation_rc = creation_rc

            def run(self, *args, global_list=False, check=True):
                self.calls.append((args, global_list))
                if args == ("fport", "ls"):
                    return SimpleNamespace(returncode=0, stdout=self.mapping, stderr="")
                if args == ("fport", "tcp:17932", "tcp:7856"):
                    if self.creation_rc == 0:
                        self.mapping = "127.0.0.1:5555 tcp:17932 tcp:7856 [Forward]\n"
                    return SimpleNamespace(returncode=self.creation_rc,
                                           stdout="Forwardport result:OK" if self.creation_rc == 0 else "",
                                           stderr="")
                if args == ("fport", "rm", "tcp:17932", "tcp:7856"):
                    self.mapping = ""
                    return SimpleNamespace(returncode=0, stdout="", stderr="")
                raise AssertionError(f"unexpected command: {args!r}")

        failed = FakeHdc(creation_rc=32)
        lease = probe.ForwardLease(failed, 17932, 7856)
        with self.assertRaises(AssertionError):
            lease.acquire()
        lease.close()
        self.assertFalse(any(call[0][1:2] == ("rm",) for call in failed.calls))

        good = FakeHdc()
        lease = probe.ForwardLease(good, 17932, 7856)
        lease.acquire()
        self.assertTrue(lease.owned)
        good.mapping = "other:5555 tcp:17932 tcp:7856 [Forward]\n"
        with self.assertRaises(AssertionError):
            lease.close()
        self.assertFalse(any(call[0][1:2] == ("rm",) for call in good.calls))
        good.mapping = "127.0.0.1:5555 tcp:17932 tcp:7856 [Forward]\n"
        lease.close()
        self.assertFalse(lease.owned)
        self.assertEqual(good.mapping, "")


if __name__ == "__main__":
    unittest.main()

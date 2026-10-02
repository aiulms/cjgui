#!/usr/bin/env python3
"""Offline acceptance-identity and focus-continuity tests for the viewport verifier."""
from __future__ import annotations

from pathlib import Path
import json
import sys
import tempfile
from types import SimpleNamespace
import unittest

HERE = Path(__file__).resolve().parent
if str(HERE) not in sys.path:
    sys.path.insert(0, str(HERE))
import verify_normal_generated_viewport_continuity as verifier  # noqa: E402


def candidate_pair(field: str, action: str):
    header = ("GENERATED_UI_STRUCTURE 1\nNODE 0 panel vertical\n"
              "NODE 1 viewport scrollArea\nNODE 2 content vertical\n"
              f"NODE 3 trigger action action={action}\nNODE 3 row label\n"
              f"NODE 3 editor textInput field={field}\nEND\n")
    reordered = ("GENERATED_UI_STRUCTURE 1\nNODE 0 panel vertical\n"
                 "NODE 1 viewport scrollArea\nNODE 2 content vertical\n"
                 f"NODE 3 trigger action action={action}\nNODE 3 editor textInput field={field}\n"
                 "NODE 3 row label\nEND\n")
    return header, reordered


class FakeLayoutHdc:
    def __init__(self, tree):
        self.tree = tree
        self.commands = []

    def pidof(self, _bundle):
        # The clone PID remains alive even when an unrelated root is foreground.
        return "29352"

    def shell(self, command):
        self.commands.append(command)
        if command == 'hidumper -s WindowManagerService -a -a':
            return 'Focus window: 213\nDisplayId: 0 WindowId: 213\n'
        if command == 'hidumper -s 4606 -a "-w 213 -a"':
            return ('WindowName: htouch0\nWinId: 213\nPid: 29352\n'
                    'IsVisible: true\nisRSVisible: true\n'
                    'bundleName:com.example.cjguiapp.htouch\n')
        return ""

    def pull(self, _remote, local):
        Path(local).write_text(json.dumps(self.tree), encoding="utf-8")


def layout_tree(bundle: str, *, duplicate_root: bool = False):
    def root(bundle_name):
        return {"attributes": {"type": "root", "visible": "true", "bundleName": bundle_name,
            "bounds": "[0,137][1320,2856]"}, "children": [
                {"attributes": {"type": "XComponent", "visible": "true",
                    "bounds": "[0,137][1320,1842]"}, "children": []}]}
    roots = [root(bundle)]
    if duplicate_root:
        roots.append(root("com.example.other"))
    return {"attributes": {}, "children": roots}


def layout_tree_with_ime(app_bundle: str):
    app = layout_tree(app_bundle)["children"][0]
    ime = {"attributes": {"type": "root", "visible": "true",
        "bundleName": "com.huawei.hmos.inputmethod", "bounds": "[0,137][1320,2856]"},
        "children": []}
    return {"attributes": {}, "children": [app, ime]}


class GeneratedViewportContinuityTests(unittest.TestCase):
    @staticmethod
    def interaction_with_selection(start: int, end: int) -> str:
        return ("PROTOCOL CJGUI_SHARED_OPERATION/2\nKIND WINDOW_INTERACTION\n"
                "WINDOW_FOCUS_STATE valid\nWINDOW_FOCUS component-8-1\n"
                f"WINDOW_SELECTION component-8-1 {start} {end}\nEND\n")

    def test_pre_action_guard_rejects_wrong_foreground_bundle_while_clone_pid_lives(self):
        hdc = FakeLayoutHdc(layout_tree("com.example.cjguiapp"))
        with tempfile.TemporaryDirectory() as directory:
            args = SimpleNamespace(bundle="com.example.cjguiapp.htouch")
            with self.assertRaisesRegex(ValueError, "foreground UITest root bundle mismatch"):
                verifier._ui_input(hdc, Path(directory), args, "29352", lambda: None,
                    "must_not_click", "uitest uiInput click 603 1500")
        self.assertFalse(any("uitest uiInput click" in command for command in hdc.commands))

    def test_pre_action_guard_rejects_ambiguous_visible_roots(self):
        hdc = FakeLayoutHdc(layout_tree("com.example.cjguiapp.htouch", duplicate_root=True))
        with tempfile.TemporaryDirectory() as directory:
            args = SimpleNamespace(bundle="com.example.cjguiapp.htouch")
            with self.assertRaisesRegex(ValueError, "one visible UITest root"):
                verifier._ui_input(hdc, Path(directory), args, "29352", lambda: None,
                    "ambiguous_root", "uitest uiInput keyEvent 2055")
        self.assertFalse(any("uitest uiInput keyEvent" in command for command in hdc.commands))

    def test_text_action_allows_only_the_explicit_system_ime_overlay(self):
        hdc = FakeLayoutHdc(layout_tree_with_ime("com.example.cjguiapp.htouch"))
        with tempfile.TemporaryDirectory() as directory:
            args = SimpleNamespace(bundle="com.example.cjguiapp.htouch")
            with self.assertRaisesRegex(ValueError, "foreground UITest root bundle mismatch|system IME root"):
                verifier._ui_input(hdc, Path(directory), args, "29352", lambda: None,
                    "action_without_ime_permission", "uitest uiInput click 603 1500")
            verifier._ui_input(hdc, Path(directory), args, "29352", lambda: None,
                "text_operation", "uitest uiInput keyEvent 2054", allow_system_ime_overlay=True)
        self.assertIn("uitest uiInput keyEvent 2054", hdc.commands)

    def test_original_app_plus_ime_is_rejected_even_for_text_operation(self):
        hdc = FakeLayoutHdc(layout_tree_with_ime("com.example.cjguiapp"))
        with tempfile.TemporaryDirectory() as directory:
            args = SimpleNamespace(bundle="com.example.cjguiapp.htouch")
            with self.assertRaisesRegex(ValueError, "foreground UITest root bundle mismatch"):
                verifier._ui_input(hdc, Path(directory), args, "29352", lambda: None,
                    "wrong_app_with_ime", "uitest uiInput keyEvent 2054", allow_system_ime_overlay=True)
        self.assertFalse(any("uitest uiInput keyEvent" in command for command in hdc.commands))

    def test_ime_only_key_guard_requires_current_public_focus_and_rejects_clicks(self):
        ime = layout_tree_with_ime("com.example.cjguiapp.htouch")["children"][1]
        hdc = FakeLayoutHdc({"attributes": {}, "children": [ime]})
        args = SimpleNamespace(bundle="com.example.cjguiapp.htouch")
        with tempfile.TemporaryDirectory() as directory:
            with self.assertRaisesRegex(ValueError, "keyEvent only"):
                verifier._ui_input(hdc, Path(directory), args, "29352", lambda: None,
                    "blocked_click", "uitest uiInput click 100 100",
                    allow_ime_only_key=True, app_window_id="213",
                    checked_public_focus=lambda: None)
            with self.assertRaisesRegex(ValueError, "public focus"):
                verifier._ui_input(hdc, Path(directory), args, "29352", lambda: None,
                    "blocked_key", "uitest uiInput keyEvent 2072 2017",
                    allow_ime_only_key=True, app_window_id="213",
                    checked_public_focus=lambda: (_ for _ in ()).throw(ValueError("public focus lost")))
            verifier._ui_input(hdc, Path(directory), args, "29352", lambda: None,
                "ctrl_a", "uitest uiInput keyEvent 2072 2017",
                allow_ime_only_key=True, app_window_id="213",
                checked_public_focus=lambda: None)
        self.assertEqual([c for c in hdc.commands if c.startswith("uitest uiInput")],
                         ["uitest uiInput keyEvent 2072 2017"])

    def test_ime_only_key_guard_rejects_wrong_window_manager_identity(self):
        ime = layout_tree_with_ime("com.example.cjguiapp.htouch")["children"][1]
        args = SimpleNamespace(bundle="com.example.cjguiapp.htouch")
        for wrong in ("Focus window: 999", "Pid: 999", "IsVisible: false",
                      "bundleName:com.example.other"):
            class WrongWindowHdc(FakeLayoutHdc):
                def shell(self, command):
                    result = super().shell(command)
                    if wrong.startswith("Focus window") and command.startswith("hidumper -s WindowManagerService"):
                        return result.replace("Focus window: 213", wrong)
                    if command.startswith("hidumper -s 4606"):
                        original = {
                            "Pid": "Pid: 29352", "IsVisible": "IsVisible: true",
                            "bundleName": "bundleName:com.example.cjguiapp.htouch",
                        }.get(wrong.split(":")[0], "")
                        return result.replace(original, wrong) if original else result
                    return result
            hdc = WrongWindowHdc({"attributes": {}, "children": [ime]})
            with tempfile.TemporaryDirectory() as directory:
                with self.assertRaisesRegex(ValueError, "focused window|identity or visibility"):
                    verifier._ui_input(hdc, Path(directory), args, "29352", lambda: None,
                        "wrong_wm", "uitest uiInput keyEvent 2072 2017",
                        allow_ime_only_key=True, app_window_id="213",
                        checked_public_focus=lambda: None)
            self.assertFalse(any(c.startswith("uitest uiInput") for c in hdc.commands))

    def test_app_window_id_comes_from_current_visible_app_root(self):
        tree = layout_tree_with_ime("com.example.cjguiapp.htouch")
        tree["children"][0]["attributes"]["hostWindowId"] = "527"
        self.assertEqual(verifier._app_window_id(tree, "com.example.cjguiapp.htouch"), "527")
        with self.assertRaisesRegex(ValueError, "hostWindowId"):
            verifier._app_window_id(tree, "com.example.other")

    def test_ime_surface_resize_requires_live_height_change_and_both_revisions(self):
        before = SimpleNamespace(window_geometry_revision=10,
            window_accepted_scene_version=20, owner_pending_scene=False)
        after = SimpleNamespace(window_geometry_revision=11,
            window_accepted_scene_version=21, owner_pending_scene=False)
        self.assertEqual(verifier.assert_ime_surface_resize(
            (0, 137, 1320, 1660), (0, 137, 1320, 1620), before, after),
            {"before_bounds": (0, 137, 1320, 1660), "after_bounds": (0, 137, 1320, 1620),
             "before_geometry_revision": 10, "after_geometry_revision": 11,
             "before_accepted_scene_version": 20, "after_accepted_scene_version": 21})
        # Accepted geometry revisions are fingerprints, so a different value
        # can be numerically lower even when the real Surface became smaller.
        descending = SimpleNamespace(window_geometry_revision=9,
            window_accepted_scene_version=21, owner_pending_scene=False)
        self.assertEqual(verifier.assert_ime_surface_resize(
            (0, 137, 1320, 1660), (0, 137, 1320, 1620), before, descending)["after_geometry_revision"], 9)
        with self.assertRaisesRegex(ValueError, "height"):
            verifier.assert_ime_surface_resize((0, 137, 1320, 1660),
                (0, 137, 1320, 1660), before, after)
        with self.assertRaisesRegex(ValueError, "geometry"):
            verifier.assert_ime_surface_resize((0, 137, 1320, 1660),
                (0, 137, 1320, 1620), before,
                SimpleNamespace(window_geometry_revision=10,
                    window_accepted_scene_version=21, owner_pending_scene=False))
        with self.assertRaisesRegex(ValueError, "scene"):
            verifier.assert_ime_surface_resize((0, 137, 1320, 1660),
                (0, 137, 1320, 1620), before,
                SimpleNamespace(window_geometry_revision=11,
                    window_accepted_scene_version=20, owner_pending_scene=False))

    def test_ctrl_a_selection_requires_fresh_same_mount_full_range(self):
        hdc = FakeLayoutHdc(layout_tree_with_ime("com.example.cjguiapp.htouch"))
        args = SimpleNamespace(bundle="com.example.cjguiapp.htouch")
        mount = "app1/s1/c1/e1/m1"
        baseline = "09-28 22:00:00.000 29352 29352 I A00000/CjguiApp: before"
        selected = baseline + (f"\n09-28 22:00:00.100 29352 29352 I A00000/CjguiApp: "
                               f"ime select [0,6) rc=0 mount={mount}")
        with tempfile.TemporaryDirectory() as directory:
            result = verifier.select_full_text_keyboard(
                hdc, Path(directory), args, "29352", lambda: None, lambda: None,
                "213", "ctrl_a", baseline, lambda: selected,
                lambda: self.interaction_with_selection(0, 6), mount,
                "component-8-1", "abcdef", 0.2)
            self.assertEqual(result[0], (0, 6))
            with self.assertRaisesRegex(ValueError, "not_full"):
                verifier.select_full_text_keyboard(
                    hdc, Path(directory), args, "29352", lambda: None, lambda: None,
                    "213", "partial", baseline, lambda: selected,
                    lambda: self.interaction_with_selection(0, 6), mount,
                    "component-8-1", "abcdefgh", 0.2)
        self.assertEqual([c for c in hdc.commands if c.startswith("uitest uiInput")],
                         ["uitest uiInput keyEvent 2072 2017"] * 2)

    def test_settings_same_key_reorder_keeps_action_and_editor_bindings(self):
        v1, reorder = candidate_pair("name", "INCREMENT")
        first, second = verifier.validate_candidate_pair(v1, reorder, "name", "INCREMENT")
        self.assertEqual({(n.key, n.kind, n.field_id, n.action) for n in first},
                         {(n.key, n.kind, n.field_id, n.action) for n in second})
        self.assertNotEqual([n.key for n in first], [n.key for n in second])

    def test_thermo_same_key_reorder_keeps_action_and_editor_bindings(self):
        v1, reorder = candidate_pair("note", "TEMP_UP")
        first, second = verifier.validate_candidate_pair(v1, reorder, "note", "TEMP_UP")
        self.assertEqual({(n.key, n.kind, n.field_id, n.action) for n in first},
                         {(n.key, n.kind, n.field_id, n.action) for n in second})

    def test_reorder_cannot_change_binding(self):
        v1, _ = candidate_pair("name", "INCREMENT")
        changed = v1.replace("field=name", "field=other")
        with self.assertRaisesRegex(ValueError, "preserve every accepted"):
            verifier.validate_candidate_pair(v1, changed, "name", "INCREMENT")

    def test_interaction_requires_same_focus_and_nonempty_selection(self):
        raw = ("PROTOCOL CJGUI_SHARED_OPERATION/2\nKIND WINDOW_INTERACTION\n"
               "WINDOW_FOCUS_STATE valid\nWINDOW_FOCUS generated-editor-mount\n"
               "WINDOW_SELECTION generated-editor-mount 2 9\nEND\n")
        state = verifier.parse_interaction(raw)
        self.assertEqual(verifier.assert_live_selection(state, "generated-editor-mount", (2, 9)), (2, 9))
        with self.assertRaisesRegex(ValueError, "nonempty"):
            verifier.assert_live_selection(
                verifier.parse_interaction(raw.replace("2 9", "2 2")), "generated-editor-mount")

    def test_selection_wait_requires_fresh_same_mount_event_and_matching_public_range(self):
        mount = "app1/s1/c1/e1/m1"
        before = f"09-28 22:00:00.000 29352 29352 I A00000/CjguiApp: ime proxy FOCUSED field=component-8-1 mount={mount}\n"
        logs = iter((before,
            before + f"09-28 22:00:00.100 29352 29352 I A00000/CjguiApp: ime select [0,6) rc=0 mount={mount}\n",
            before + f"09-28 22:00:00.100 29352 29352 I A00000/CjguiApp: ime select [0,6) rc=0 mount={mount}\n"))
        interactions = iter((self.interaction_with_selection(0, 0),
            self.interaction_with_selection(0, 0), self.interaction_with_selection(0, 6)))
        now = [0.0]
        result = verifier.wait_for_matching_selection(before, lambda: next(logs),
            lambda: next(interactions), "29352", mount, "component-8-1",
            timeout_seconds=1, poll_seconds=0.1,
            monotonic=lambda: now[0], sleep=lambda seconds: now.__setitem__(0, now[0] + seconds))
        self.assertEqual(result[0], (0, 6))
        self.assertEqual(verifier.parse_interaction(result[3]["raw"])["selection"],
                         ("component-8-1", 0, 6))

    def test_selection_wait_times_out_with_both_latest_observations_when_ranges_disagree(self):
        mount = "app1/s1/c1/e1/m1"
        before = f"09-28 22:00:00.000 29352 29352 I A00000/CjguiApp: ime proxy FOCUSED field=component-8-1 mount={mount}\n"
        latest_log = before + f"09-28 22:00:00.100 29352 29352 I A00000/CjguiApp: ime select [0,8) rc=0 mount={mount}\n"
        now = [0.0]
        with self.assertRaises(verifier.SelectionAcceptanceTimeout) as caught:
            verifier.wait_for_matching_selection(before, lambda: latest_log,
                lambda: self.interaction_with_selection(0, 6), "29352", mount,
                "component-8-1", timeout_seconds=0.25, poll_seconds=0.1,
                monotonic=lambda: now[0], sleep=lambda seconds: now.__setitem__(0, now[0] + seconds))
        self.assertEqual(caught.exception.event_range, (0, 8))
        self.assertEqual(caught.exception.public_range, (0, 6))
        self.assertIn("WINDOW_SELECTION component-8-1 0 6", caught.exception.latest_interaction_raw)

    def test_full_text_selection_confirmation_rejects_partial_range(self):
        with self.assertRaisesRegex(ValueError, 'draft_selection_not_full'):
            verifier.assert_full_text_selection((1, 24), 'TouchDraft23TouchFinal23', 'draft')
        self.assertEqual(verifier.assert_full_text_selection(
            (0, 24), 'TouchDraft23TouchFinal23', 'draft'), (0, 24))
        self.assertEqual(verifier.utf16_length('A🚀B'), 4)

    def test_selection_freshness_uses_later_same_pid_mount_event_after_log_rotation(self):
        mount = 'app1/s1/c2/e1/m2'
        before = ['09-28 23:28:40.000 25783 25783 I A00000/CjguiApp: baseline line']
        after = [f'09-28 23:28:42.284 25783 25783 I A00000/CjguiApp: ime select [0,24) rc=0 mount={mount}']
        self.assertEqual(verifier.assert_fresh_selection_state(before, after, '25783', mount), (0, 24))
        accepted = verifier.wait_for_matching_selection(
            '\n'.join(before), lambda: '\n'.join(after),
            lambda: self.interaction_with_selection(0, 24), '25783', mount,
            'component-8-1', timeout_seconds=1, poll_seconds=0.1,
            monotonic=lambda: 1.0, sleep=lambda _seconds: None)
        self.assertEqual(accepted[0], (0, 24))
        stale = [f'09-28 23:28:39.999 25783 25783 I A00000/CjguiApp: ime select [0,24) rc=0 mount={mount}']
        with self.assertRaisesRegex(AssertionError, 'no later same-PID hilog event after rotation'):
            verifier.assert_fresh_selection_state(before, stale, '25783', mount)

    def test_draft_freshness_uses_later_same_pid_mount_events_after_log_rotation(self):
        mount = 'app1/s1/c2/e1/m2'
        before = ['09-28 23:28:40.000 25783 25783 I A00000/CjguiApp: baseline line']
        after = [
            f'09-28 23:28:42.284 25783 25783 I A00000/CjguiApp: ime proxy onChange len=0 verdict=ok mount={mount}',
            f'09-28 23:28:42.500 25783 25783 I A00000/CjguiApp: ime proxy onChange len=24 verdict=ok mount={mount}',
        ]
        self.assertEqual(verifier.assert_fresh_draft_change(
            before, after, '25783', mount, require_empty_transition=True), [0, 24])

    def test_continuation_must_delete_selected_draft_before_replacement_input(self):
        mount = 'app1/s1/c1/e1/m1'
        selected = [f'09-28 23:00:00.000 17421 17421 I A00000/CjguiApp: ime select [0,12) rc=0 mount={mount}']
        appended = [
            f'09-28 23:00:00.100 17421 17421 I A00000/CjguiApp: ime proxy onChange len={length} verdict=ok mount={mount}'
            for length in range(13, 25)
        ]
        # This was the r12 false positive: positive onChange events alone said
        # "continuation" even though the old 12-character draft was appended.
        self.assertEqual(verifier.assert_fresh_positive_draft(selected, appended, '17421', mount)[-1], 24)
        with self.assertRaisesRegex(ValueError, 'expected final length 0'):
            verifier.assert_fresh_draft_change(
                selected, appended, '17421', mount,
                require_empty_transition=True, expected_final_length=0)

    def test_continuation_reset_and_replacement_have_exact_draft_lengths(self):
        mount = 'app1/s1/c1/e1/m1'
        selected = [f'09-28 23:00:00.000 17421 17421 I A00000/CjguiApp: ime select [0,12) rc=0 mount={mount}']
        deleted = [f'09-28 23:00:00.100 17421 17421 I A00000/CjguiApp: ime proxy onChange len=0 verdict=ok mount={mount}']
        typed = [
            f'09-28 23:00:01.{length:03d} 17421 17421 I A00000/CjguiApp: ime proxy onChange len={length} verdict=ok mount={mount}'
            for length in range(1, 13)
        ]
        self.assertEqual(verifier.assert_fresh_draft_change(
            selected, deleted, '17421', mount,
            require_empty_transition=True, expected_final_length=0), [0])
        self.assertEqual(verifier.assert_fresh_draft_change(
            deleted, typed, '17421', mount, expected_final_length=12), list(range(1, 13)))

    def test_generated_fields_keep_owner_projection_separate_from_native_empty_proxy(self):
        raw = ("PROTOCOL CJGUI_SHARED_OPERATION/2\nKIND GENERATED_UI_FIELDS\n"
               "FIELD name 9700 DRAFT_HEX 6F6C64 APPLIED_HEX 6F6C64 ERROR none "
               "FOCUS 1 SELECTION 0 0 AVAILABLE 1 REASON_HEX - TARGET 9700 "
               "STATE_VERSION 4 DRAFT_SOURCE owner_applied VERSION 4\nEND\nEND\n")
        self.assertEqual(verifier.assert_owner_backed_field_projection(raw, 'name', 'old'),
                         'owner_applied')
        with self.assertRaisesRegex(ValueError, 'owner-backed draft/applied projection'):
            verifier.assert_owner_backed_field_projection(raw.replace('DRAFT_HEX 6F6C64',
                'DRAFT_HEX -'), 'name', 'old')
        with self.assertRaisesRegex(ValueError, 'explicitly owner-backed'):
            verifier.assert_owner_backed_field_projection(raw.replace('owner_applied',
                'platform_proxy'), 'name', 'old')

    def test_post_delete_native_proxy_is_checked_by_fresh_same_mount_layout(self):
        mount = 'app1/s1/c1/e1/m1'
        log = f'09-28 23:00:00.100 17421 17421 I A00000/CjguiApp: ime proxy FOCUSED field=component-8-1 mount={mount}'
        def tree(text):
            return {'attributes': {}, 'children': [{'attributes': {
                'id': 'cjguiImeProxy', 'type': 'TextInput', 'visible': 'true',
                'focused': 'true', 'text': text}, 'children': []}]}
        self.assertEqual(verifier.assert_continuation_proxy_empty(
            tree(''), 'component-8-1', mount, log), '')
        with self.assertRaisesRegex(ValueError, 'continuation_empty_proxy_not_retained'):
            verifier.assert_continuation_proxy_empty(
                tree('owner value'), 'component-8-1', mount, log)
        with self.assertRaisesRegex(ValueError, 'current focused semantic mount'):
            verifier.assert_continuation_proxy_empty(
                tree(''), 'component-8-1', 'app1/s1/c2/e1/m2', log)

    def test_generated_draft_helper_checks_owner_value_and_selection_separately(self):
        field = SimpleNamespace(field_id='name', draft='owner', applied='owner',
            focused=True, selection_start=0, selection_end=0)
        self.assertIs(verifier.assert_generated_draft(
            (field,), 'name', 'owner', expected_selection=(0, 0)), field)
        with self.assertRaisesRegex(ValueError, 'owner-backed draft/applied'):
            verifier.assert_generated_draft(
                (SimpleNamespace(**{**field.__dict__, 'draft': 'proxy text'}),),
                'name', 'owner')

    def test_selection_wait_can_observe_exact_collapsed_state_after_delete(self):
        mount = 'app1/s1/c1/e1/m1'
        before = f'09-28 22:00:00.000 29352 29352 I A00000/CjguiApp: ime proxy FOCUSED field=component-8-1 mount={mount}\n'
        selected_log = before + f'09-28 22:00:00.100 29352 29352 I A00000/CjguiApp: ime select [24,24) rc=0 mount={mount}\n'
        now = [0.0]
        result = verifier.wait_for_matching_selection(
            before, lambda: selected_log, lambda: self.interaction_with_selection(24, 24),
            '29352', mount, 'component-8-1', timeout_seconds=1, poll_seconds=0.1,
            monotonic=lambda: now[0], sleep=lambda seconds: now.__setitem__(0, now[0] + seconds),
            allow_empty=True)
        self.assertEqual(result[0], (24, 24))

    def test_default_selection_wait_still_rejects_collapsed_ime_and_public_ranges(self):
        mount = 'app1/s1/c1/e1/m1'
        before = f'09-28 22:00:00.000 29352 29352 I A00000/CjguiApp: ime proxy FOCUSED field=component-8-1 mount={mount}\\n'
        selected_log = before + f'09-28 22:00:00.100 29352 29352 I A00000/CjguiApp: ime select [24,24) rc=0 mount={mount}\\n'
        now = [0.0]
        with self.assertRaises(verifier.SelectionAcceptanceTimeout):
            verifier.wait_for_matching_selection(
                before, lambda: selected_log, lambda: self.interaction_with_selection(24, 24),
                '29352', mount, 'component-8-1', timeout_seconds=0.2, poll_seconds=0.1,
                monotonic=lambda: now[0], sleep=lambda seconds: now.__setitem__(0, now[0] + seconds))

    def test_action_business_field_is_explicit_and_directional(self):
        self.assertEqual(verifier.action_counter_field("INCREMENT"), "count")
        self.assertEqual(verifier.action_counter_field("TEMP_UP"), "targetTemp")
        with self.assertRaisesRegex(ValueError, "unsupported"):
            verifier.action_counter_field("UNRELATED")

    def test_below_viewport_editor_is_accepted_before_scroll_but_not_clickable(self):
        hidden = SimpleNamespace(key="editor", kind="textInput", field_id="name", action=None,
            visible=False, bounds=(28, 1748, 1150, 64), semantic_id="mount-editor")
        instances = SimpleNamespace(instances=(hidden,))
        self.assertIs(verifier.accepted_instance(instances, "editor", kind="textInput",
            field="name", require_visible=False), hidden)
        with self.assertRaisesRegex(ValueError, "wrong binding"):
            verifier.accepted_instance(instances, "editor", kind="textInput", field="name")

    def test_accepted_instance_center_adds_measured_xcomponent_origin_once(self):
        # R4 XComponent layout was [0,137][1320,1842]. At density 1 the accepted
        # bounds are already physical px, so the generated action's UITest screen
        # point is (28+1150/2, 137+1333+60/2) = (603,1500). Omitting the origin
        # lands 137 px above the visible action; adding it twice lands at 1637.
        trigger = SimpleNamespace(bounds=(28, 1333, 1150, 60))
        point = verifier._screen_point(trigger, (0, 137), 1.0)
        self.assertEqual(point, (603, 1500))
        self.assertNotEqual(point, (603, 1363))
        self.assertNotEqual(point, (603, 1637))

    def test_accepted_instance_center_scales_vp_to_physical_px(self):
        # Accepted bounds became vp after the density fix, so on the 3.5 emulator
        # the same trigger at vp (12,380,353,40) must be injected at physical px
        # (round(188.5*3.5), 137+round(400*3.5)) = (660,1537), not at its vp
        # centre (188,537) which would land far above the real action.
        trigger = SimpleNamespace(bounds=(12, 380, 353, 40))
        point = verifier._screen_point(trigger, (0, 137), 3.5)
        self.assertEqual(point, (660, 1537))
        self.assertNotEqual(point, (188, 537))

    def test_focused_os_proxy_point_uses_fresh_visible_same_mount_layout(self):
        proxy = {"attributes": {"id": "cjguiImeProxy", "type": "TextInput",
            "visible": "true", "focused": "true", "bounds": "[28,1617][1178,1701]"},
            "children": []}
        root = {"attributes": {"type": "root", "bundleName": "com.example.cjguiapp.htouch",
            "visible": "true",
            "bounds": "[0,137][1320,1757]"}, "children": [proxy]}
        tree = {"attributes": {}, "children": [root]}
        log = "CjguiApp: ime proxy FOCUSED field=component-8-1 mount=mount-17"
        # The proxy extends below the resized XComponent [0,137]-[1320,1664],
        # but remains in the foreground app root window [0,137]-[1320,1757].
        proxy_bounds = (28, 1617, 1178, 1701)
        component_bounds = (0, 137, 1320, 1527)
        self.assertGreater(proxy_bounds[3], component_bounds[1] + component_bounds[3])
        window = verifier._visible_root_bounds(tree, "com.example.cjguiapp.htouch")
        self.assertEqual(window, (0, 137, 1320, 1620))
        # RED: the former XComponent containment gate rejects this real,
        # focused OS proxy because the IME overlay extends below the surface.
        with self.assertRaisesRegex(ValueError, "outside the current app window"):
            verifier.focused_ime_proxy_point(
                tree, component_bounds, "component-8-1", "mount-17", log)
        # GREEN: app-window containment accepts it without weakening identity.
        point = verifier.focused_ime_proxy_point(
            tree, window, "component-8-1", "mount-17", log)
        self.assertEqual(point, (603, 1659))
        with self.assertRaisesRegex(ValueError, "current focused semantic mount"):
            verifier.focused_ime_proxy_point(
                tree, window, "component-8-1", "old-mount", log)
        hidden = {"attributes": dict(proxy["attributes"], visible="false"), "children": []}
        with self.assertRaisesRegex(ValueError, "one visible focused"):
            verifier.focused_ime_proxy_point(
                {"attributes": {}, "children": [dict(root, children=[hidden])]}, window,
                "component-8-1", "mount-17", log)

    def test_focused_os_proxy_must_stay_inside_visible_app_window(self):
        proxy = {"attributes": {"id": "cjguiImeProxy", "type": "TextInput",
            "visible": "true", "focused": "true", "bounds": "[28,1617][1178,1701]"},
            "children": []}
        tree = {"attributes": {}, "children": [proxy]}
        with self.assertRaisesRegex(ValueError, "one visible UITest root"):
            verifier._visible_root_bounds(tree, "com.example.cjguiapp.htouch")
        root = {"attributes": {"type": "root", "bundleName": "com.example.cjguiapp.htouch",
            "visible": "true",
            "bounds": "[0,137][1320,1690]"}, "children": [proxy]}
        with self.assertRaisesRegex(ValueError, "outside the current app window"):
            verifier.focused_ime_proxy_point(
                {"attributes": {}, "children": [root]},
                verifier._visible_root_bounds({"attributes": {}, "children": [root]},
                    "com.example.cjguiapp.htouch"),
                "component-8-1", "mount-17",
                "ime proxy FOCUSED field=component-8-1 mount=mount-17")


if __name__ == "__main__":
    unittest.main()

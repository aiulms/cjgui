#!/usr/bin/env python3
"""Controlled tests for normal-HAP handwritten scroll/navigation consumption."""

from __future__ import annotations

import importlib.util
from pathlib import Path
import tempfile
import unittest
import json

import verify_current_normal_selection_replace as selection


SCRIPT = Path(__file__).with_name("verify_normal_handwritten_scroll_nav.py")
SPEC = importlib.util.spec_from_file_location("handwritten_scroll_nav", SCRIPT)
assert SPEC is not None and SPEC.loader is not None
verify = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(verify)

NAV_NODE = 71
VIEWPORT_NODE = 72
NOTE_NODE = 88


def batch_rows(timestamp, ticket, entries):
    head = f"{timestamp} 4321 4321 I A00000/CjguiRenderer: "
    rects = [head + "node-rect id=1 x=0 y=0 w=400 h=600 clip=(0,0,400,600)"]
    accepted = [head + f"accepted node=1 semantic=root kind=1 label=root value= v={ticket}"]
    for semantic, node_id, rect, clip in entries:
        pair = frame_rows(timestamp, semantic, node_id, rect, clip)
        rects.append(pair[0])
        accepted.append(pair[1].rsplit(" v=", 1)[0] + f" v={ticket}")
    return rects + accepted + [head + f"present terminal session=1 ticket={ticket} status=0 phase=3"]


class AcceptedBatchGeometryTests(unittest.TestCase):
    def setUp(self):
        self.before = [f"09-28 12:00:0{i} 4321 4321 I /CjguiApp: baseline {i}" for i in range(3)]
        self.fence = (9, 28, 12, 0, 3, 0)
        self.viewport = ("view", VIEWPORT_NODE, (0, 100, 340, 220), (0, 100, 340, 220))

    def pair(self, after):
        return verify.fresh_nav_viewport_geometry(self.before, after, "nav", "view", self.fence)

    def test_motion_consumes_latest_complete_matching_ticket(self):
        after = list(self.before)
        for ticket, y in [(21, 150), (22, 149), (23, 148)]:
            after += batch_rows(f"09-28 12:00:04.{ticket:03d}", ticket,
                                [("nav", NAV_NODE, (12, y, 110, 30), (0, 100, 340, 220)), self.viewport])
        nav, viewport = self.pair(after)
        self.assertEqual(nav["y"], 148)
        self.assertEqual(nav["accepted_ticket"], 23)
        self.assertEqual(viewport["accepted_ticket"], 23)

    def test_latest_missing_nav_cannot_pair_with_older_ticket(self):
        after = self.before + batch_rows("09-28 12:00:04", 21,
            [("nav", NAV_NODE, (12, 150, 110, 30), (0, 100, 340, 220))])
        after += batch_rows("09-28 12:00:05", 22, [self.viewport])
        with self.assertRaises(ValueError):
            self.pair(after)

    def test_mixed_version_within_one_terminal_is_refused(self):
        after = batch_rows("09-28 12:00:04", 21,
            [("nav", NAV_NODE, (12, 150, 110, 30), (0, 100, 340, 220)), self.viewport])
        after = [x.replace("value= v=21", "value= v=22") if "semantic=nav " in x else x for x in after]
        with self.assertRaises(ValueError):
            self.pair(self.before + after)

    def test_incomplete_tail_never_falls_back_to_prior_batch(self):
        entries = [("nav", NAV_NODE, (12, 150, 110, 30), (0, 100, 340, 220)), self.viewport]
        after = self.before + batch_rows("09-28 12:00:04", 21, entries)
        after += batch_rows("09-28 12:00:05", 22, entries)[:-1]
        with self.assertRaisesRegex(ValueError, "incomplete"):
            self.pair(after)

    def test_one_ticket_still_refuses_conflicting_rects(self):
        entries = [("nav", NAV_NODE, (12, 150, 110, 30), (0, 100, 340, 220)), self.viewport]
        batch = batch_rows("09-28 12:00:04", 21, entries)
        batch.insert(2, batch[1].replace("y=150", "y=151"))
        with self.assertRaises(ValueError):
            self.pair(self.before + batch)

    def test_latest_failed_terminal_never_uses_older_success(self):
        entries = [("nav", NAV_NODE, (12, 150, 110, 30), (0, 100, 340, 220)), self.viewport]
        after = self.before + batch_rows("09-28 12:00:04", 21, entries)
        failed = batch_rows("09-28 12:00:05", 22, entries)
        failed[-1] = failed[-1].replace("status=0", "status=-1")
        with self.assertRaises(verify.AcceptedGeometryInvalid):
            self.pair(after + failed)

    def test_latest_semantic_with_two_nodes_is_still_ambiguous(self):
        entries = [("nav", NAV_NODE, (12, 150, 110, 30), (0, 100, 340, 220)),
                   ("nav", NAV_NODE + 100, (12, 150, 110, 30), (0, 100, 340, 220)), self.viewport]
        with self.assertRaisesRegex(ValueError, "ambiguous"):
            self.pair(self.before + batch_rows("09-28 12:00:04", 21, entries))

    def test_terminal_fence_is_the_commit_fence(self):
        entries = [("nav", NAV_NODE, (12, 150, 110, 30), (0, 100, 340, 220)), self.viewport]
        batch = batch_rows("09-28 12:00:03", 21, entries)
        with self.assertRaises(verify.AcceptedGeometryPending):
            self.pair(self.before + batch)
        # Rects may precede END, but their exact batch must commit after END.
        batch[-1] = batch[-1].replace("12:00:03", "12:00:04")
        nav, view = self.pair(self.before + batch)
        self.assertEqual(nav["accepted_ticket"], view["accepted_ticket"])

    def test_new_batch_from_other_pid_cannot_pass_freshness(self):
        entries = [("nav", NAV_NODE, (12, 150, 110, 30), (0, 100, 340, 220)), self.viewport]
        batch = [row.replace("4321 4321", "7654 7654")
                 for row in batch_rows("09-28 12:00:04", 21, entries)]
        with self.assertRaisesRegex(ValueError, "single-PID|PID changed"):
            self.pair(self.before + batch)

    def test_editor_and_viewport_consume_one_latest_complete_batch(self):
        rows = []
        for ticket, y in [(21, 450), (22, 180)]:
            rows += batch_rows(f"09-28 12:00:04.{ticket:03d}", ticket,
                [("note", NOTE_NODE, (12, y, 110, 30), (0, 100, 340, 220)), self.viewport])
        viewport = {"x": 0, "y": 500, "w": 340, "h": 220,
                    "clip": (0, 500, 340, 220), "accepted_semantic": "view"}
        self.assertTrue(verify.editor_visible_in_fenced_geometry(rows, "note", viewport, self.fence))
        pending = batch_rows("09-28 12:00:05", 23,
            [("note", NOTE_NODE, (12, 190, 110, 30), (0, 100, 340, 220)), self.viewport])[:-1]
        self.assertIsNone(verify.editor_visible_in_fenced_geometry(rows + pending, "note", viewport, self.fence))

    def test_focus_reveal_never_pairs_different_tickets(self):
        before = self.before + batch_rows("09-28 12:00:04", 20,
            [("note", NOTE_NODE, (12, 450, 110, 30), (12, 450, 110, 0)), self.viewport])
        head = "09-28 12:00:05."
        events = [
            head + "100 4321 4321 I /CjguiRenderer: raw touch action=37 x=50 y=150 ep=3",
            head + "200 4321 4321 I /CjguiRenderer: raw touch action=39 x=50 y=150 ep=3",
            head + "300 4321 4321 I /CjguiRenderer: focus api enter node=88 accepted=21",
            head + "310 4321 4321 I /CjguiRenderer: platform focus node=88 ctx=1 field=note",
            head + '320 4321 4321 I /CjguiApp: ime focus payload={"context":1,"field":"note"}',
            head + "400 4321 4321 I /CjguiApp: ime proxy mounted ctx=1 field=note node=88 gen=1",
            head + "500 4321 4321 I /CjguiApp: ime proxy FOCUSED field=note mount=m-1",
        ]
        after = before + events + batch_rows("09-28 12:00:05.700", 21,
            [("note", NOTE_NODE, (12, 150, 110, 30), (0, 100, 340, 220))])
        after += batch_rows("09-28 12:00:05.800", 22, [self.viewport])
        with self.assertRaises(ValueError):
            verify._assert_fresh_reveal_then_focus(before, after, "4321", "note", "view")


def frame_rows(day_time: str, semantic_id: str, node_id: int,
               rect: tuple[int, int, int, int], clip: tuple[int, int, int, int],
               pid: str = "4321") -> list[str]:
    """The accepted-frame pair a normal build commits for one node.

    A semantic id must keep a single node id inside one fixture, otherwise the probe
    reports it as ambiguous instead of resolving its geometry. The visible label is
    deliberately *not* the semantic id: geometry keyed on it would still pass if the
    probe silently fell back to matching text.
    """
    head = f"{day_time} {pid} {pid} I A00000/CjguiRenderer: "
    x, y, width, height = rect
    clip_x, clip_y, clip_width, clip_height = clip
    return [f"{head}node-rect id={node_id} x={x} y={y} w={width} h={height} "
            f"clip=({clip_x},{clip_y},{clip_width},{clip_height})",
            f"{head}accepted node={node_id} semantic={semantic_id} kind=9 "
            f"label=可见文本-{node_id} value= v=1"]


class AcceptedBoundsTests(unittest.TestCase):
    def test_accepted_vp_geometry_becomes_physical_px_screen_points(self):
        # Emulator density 3.5 with the app XComponent at px (0, 137): the nav
        # rect is vp, the injected click must be physical px.
        nav = {"x": 12, "y": 120, "w": 110, "h": 30, "clip": (0, 100, 340, 220)}
        viewport = {"x": 0, "y": 100, "w": 340, "h": 220, "clip": (0, 100, 340, 220)}
        self.assertEqual(
            verify.nav_screen_point(nav, (24, 48), 3.5, viewport), (258, 520))
        self.assertEqual(
            verify._point_from_clipped_rect((12, 240, 352, 292), (0, 137), 3.5),
            (637, 1068))

    def test_density_one_keeps_the_integer_vp_identity(self):
        nav = {"x": 12, "y": 121, "w": 110, "h": 30, "clip": (0, 100, 340, 220)}
        viewport = {"x": 0, "y": 100, "w": 340, "h": 220, "clip": (0, 100, 340, 220)}
        self.assertEqual(
            verify.nav_screen_point(nav, (24, 48), 1.0, viewport), (24 + 67, 48 + 136))

    def test_initial_offset_delta_is_computed_in_vp_from_a_px_anchor(self):
        nav = {"x": 12, "y": 200, "w": 110, "h": 30, "clip": (0, 100, 340, 220)}
        viewport = {"x": 0, "y": 100, "w": 340, "h": 220, "clip": (0, 100, 340, 220)}
        delta = verify.nav_offset_to_initial_y(nav, viewport, (258, 520), (24, 48), 3.5)
        # The px anchor only round-trips to within one device pixel of 135 vp.
        self.assertAlmostEqual(delta, 472 / 3.5 - 215, places=9)
        self.assertEqual(
            verify.viewport_scroll_delta_swipe(delta, viewport, (24, 48), 3.5),
            (24 + 595, 48 + 735, 24 + 595, 48 + 454))

    def test_editor_geometry_waits_for_delayed_post_terminal_same_pid_row(self):
        viewport = {"x": 28, "y": 666, "w": 1264, "h": 420,
                    "clip": [28, 666, 1264, 420]}
        fence = (9, 29, 1, 47, 46, 421000000)
        earlier = frame_rows("09-29 01:47:46.420", "hand-scroll-note", NOTE_NODE,
                             (48, 1195, 1224, 64), (48, 1195, 1224, 0), pid="30318")
        later = earlier + frame_rows("09-29 01:47:46.746", "hand-scroll-note", NOTE_NODE,
                                     (48, 1344, 1224, 64), (48, 1344, 1224, 0), pid="30318")
        snapshots = iter([earlier, later])
        visible, rows, polls = verify.poll_editor_visible_in_fenced_geometry(
            earlier, "hand-scroll-note", viewport, fence,
            lambda: next(snapshots), timeout_seconds=0.1,
            poll_interval_seconds=0.01, pause=lambda _: None)
        self.assertFalse(visible)
        self.assertEqual(rows, later)
        self.assertEqual(polls, 3)

    def test_editor_geometry_wait_does_not_accept_only_preterminal_rows(self):
        viewport = {"x": 28, "y": 666, "w": 1264, "h": 420,
                    "clip": [28, 666, 1264, 420]}
        fence = (9, 29, 1, 47, 46, 421000000)
        prior = frame_rows("09-29 01:47:46.420", "hand-scroll-note", NOTE_NODE,
                           (48, 700, 1224, 64), (48, 700, 1224, 64), pid="30318")
        visible, _, polls = verify.poll_editor_visible_in_fenced_geometry(
            prior, "hand-scroll-note", viewport, fence, lambda: prior,
            timeout_seconds=0.01, poll_interval_seconds=0.01, pause=lambda _: None)
        self.assertIsNone(visible)
        self.assertGreaterEqual(polls, 1)

    def test_foreground_layout_requires_one_visible_root_matching_explicit_bundle(self):
        root = {"attributes": {"type": "root", "visible": "true",
                               "bundleName": "org.example.app"}, "children": []}
        self.assertEqual(verify.assert_foreground_root_bundle(
            {"attributes": {}, "children": [root]}, "org.example.app"),
            ["org.example.app"])
        ime = {"attributes": {"type": "root", "visible": "true",
                              "bundleName": "com.huawei.hmos.inputmethod"}, "children": []}
        self.assertEqual(verify.assert_foreground_root_bundle(
            {"attributes": {}, "children": [root, ime]}, "org.example.app",
            allow_ime_root=True),
            ["org.example.app", "com.huawei.hmos.inputmethod"])
        with self.assertRaisesRegex(ValueError, "exactly one visible app UITest root"):
            verify.assert_foreground_root_bundle(
                {"attributes": {}, "children": [root, ime]}, "org.example.app")
        wrong = {"attributes": {"type": "root", "visible": "true",
                                "bundleName": "com.example.cjguiapp"}, "children": []}
        with self.assertRaisesRegex(ValueError, "foreground UITest root bundle mismatch"):
            verify.assert_foreground_root_bundle(
                {"attributes": {}, "children": [wrong]}, "org.example.app")
        with self.assertRaisesRegex(ValueError, "exactly one visible app UITest root"):
            verify.assert_foreground_root_bundle(
                {"attributes": {}, "children": [root, wrong]}, "org.example.app")
        with self.assertRaisesRegex(ValueError, "exactly one visible app UITest root"):
            verify.assert_foreground_root_bundle(
                {"attributes": {}, "children": [root, ime, wrong]},
                "org.example.app", allow_ime_root=True)

    def test_maps_semantic_id_to_same_node_rect_and_xcomponent_origin(self):
        raw = """accepted node=71 semantic=settings-focus-note-nav kind=9 label=定位滚动备注 value= v=13
node-rect id=71 x=40 y=620 w=280 h=52 clip=(0,0,400,720)
accepted node=72 semantic=settings-other kind=7 label=其他 value= v=13
node-rect id=72 x=2 y=3 w=4 h=5 clip=(0,0,400,720)
"""
        self.assertEqual(verify.nav_point_from_accepted_log(
            raw, "settings-focus-note-nav", (24, 48), 1.0), (204, 694))

    def test_rejects_geometry_from_another_node_or_ambiguous_semantic_id(self):
        raw = """accepted node=71 semantic=settings-focus-note-nav kind=9 label=定位滚动备注 value= v=13
node-rect id=72 x=40 y=620 w=280 h=52 clip=(0,0,400,720)
"""
        with self.assertRaisesRegex(ValueError, "no accepted bounds"):
            verify.nav_point_from_accepted_log(raw, "settings-focus-note-nav", (0, 0), 1.0)
        repeated = raw + ("accepted node=73 semantic=settings-focus-note-nav kind=9 "
                          "label=定位滚动备注 value= v=14\n")
        with self.assertRaisesRegex(ValueError, "ambiguous"):
            verify.nav_point_from_accepted_log(repeated, "settings-focus-note-nav", (0, 0), 1.0)

    def test_field_point_uses_fresh_clip_intersection_and_rejects_stale_bounds(self):
        before = [
            "09-28 12:00:00 4321 4321 I /CjguiApp: baseline one",
            "09-28 12:00:01 4321 4321 I /CjguiApp: baseline two",
        ] + frame_rows("09-28 12:00:02", "hand-scroll-note", NOTE_NODE,
                       (10, 20, 60, 40), (0, 0, 400, 720))
        after = before + [
            "09-28 12:00:03 4321 4321 I /CjguiApp: ime proxy FOCUSED "
            "field=hand-scroll-note mount=m-1",
        ] + frame_rows("09-28 12:00:04", "hand-scroll-note", NOTE_NODE,
                       (130, 580, 80, 44), (150, 590, 400, 720))
        # Visible intersection is x=150..210, y=590..624, then origin (24,48).
        point = verify.field_point_from_fresh_logs(before, after,
                                                   "hand-scroll-note", (24, 48), 1.0)
        self.assertEqual(point, (204, 655))
        # The leading-glyph inset is vp now; 25 vp keeps the long press inside
        # the fresh clip intersection x=150..210.
        self.assertEqual(verify.field_text_hit_point_from_fresh_logs(
            before, after, "hand-scroll-note", (24, 48), 1.0, left_inset=25), (179, 655))
        with self.assertRaisesRegex(ValueError, "accepted semantic id"):
            verify.field_point_from_fresh_logs(before, before,
                                               "hand-scroll-note", (24, 48), 1.0)
        # A negative clip is a malformed diagnostic; a zero clip height is the
        # legitimate "clipped away" case other fixtures rely on.
        malformed = before + frame_rows("09-28 12:00:04", "hand-scroll-note", NOTE_NODE,
                                        (48, 834, 1224, 64), (48, 834, 1224, -1))
        with self.assertRaisesRegex(ValueError, "non-positive bounds or clip"):
            verify.field_point_from_fresh_logs(before, malformed,
                                               "hand-scroll-note", (24, 48), 1.0)
        accepted_after = before + [
            "09-28 12:00:03 4321 4321 I A00000/CjguiRenderer: "
            "accepted node=92 semantic=hand-scroll-note kind=7 label=滚动备注 value= v=17",
            "09-28 12:00:04 4321 4321 I A00000/CjguiRenderer: "
            "node-rect id=92 x=200 y=300 w=100 h=50 clip=(180,280,400,720)",
        ]
        self.assertEqual(verify.field_point_from_fresh_logs(
            before, accepted_after, "hand-scroll-note", (24, 48), 1.0), (274, 373))

    def test_text_hit_point_must_remain_inside_fresh_clip(self):
        before = [
            "09-28 12:00:00 4321 4321 I /CjguiApp: prior one",
            "09-28 12:00:01 4321 4321 I /CjguiApp: prior two",
            "09-28 12:00:02 4321 4321 I /CjguiApp: prior three",
        ]
        after = before + frame_rows("09-28 12:00:03", "hand-scroll-note", NOTE_NODE,
                                    (48, 512, 1224, 64), (110, 512, 10, 64))
        with self.assertRaisesRegex(ValueError, "leading text hit is outside"):
            verify.field_text_hit_point_from_fresh_logs(
                before, after, "hand-scroll-note", (0, 137), 1.0)

    def test_public_window_selection_requires_matching_full_utf16_range(self):
        raw = ("PROTOCOL CJGUI_SHARED_OPERATION/2\nKIND WINDOW_INTERACTION\n"
               "WINDOW_FOCUS_STATE valid\nWINDOW_FOCUS component-note\n"
               "WINDOW_SELECTION_POSITION_UNIT UTF16_CODE_UNIT\n"
               "WINDOW_SELECTION component-note 0 10\nEND")
        self.assertEqual(verify.public_full_window_selection(raw, 10),
                         ("component-note", (0, 10)))
        for broken in (
                raw.replace("component-note 0 10", "component-note 0 9"),
                raw.replace("WINDOW_FOCUS component-note", "WINDOW_FOCUS other-control"),
                raw.replace("WINDOW_SELECTION_POSITION_UNIT UTF16_CODE_UNIT\n", ""),
                raw.replace("component-note 0 10", "component-note 0 0")):
            with self.subTest(broken=broken), self.assertRaises(ValueError):
                verify.public_full_window_selection(broken, 10)

    def test_field_point_survives_hilog_rotation_from_recent_overlapping_baseline(self):
        # A long gesture sequence can rotate the device's bounded hilog buffer.
        # The original pre-swipe snapshot is then too old to overlap after_nav,
        # while the immediately preceding accepted-geometry snapshot still does.
        early = [
            "09-28 12:00:00 4321 4321 I /CjguiApp: old baseline one",
            "09-28 12:00:01 4321 4321 I /CjguiApp: old baseline two",
            "09-28 12:00:02 4321 4321 I /CjguiApp: old baseline three",
        ]
        latest_geometry = [
            "09-28 12:01:00 4321 4321 I /CjguiApp: recent baseline one",
            "09-28 12:01:01 4321 4321 I /CjguiApp: recent baseline two",
        ] + frame_rows("09-28 12:01:02", "hand-scroll-note", NOTE_NODE,
                       (48, 834, 1224, 64), (48, 834, 1224, 0))
        after_nav = latest_geometry + [
            "09-28 12:01:03 4321 4321 I /CjguiRenderer: raw touch action=37 x=158 y=263 ep=4",
            "09-28 12:01:04 4321 4321 I /CjguiApp: ime proxy FOCUSED "
            "field=hand-scroll-note mount=m-1",
        ] + frame_rows("09-28 12:01:05", "hand-scroll-note", NOTE_NODE,
                       (48, 512, 1224, 64), (48, 512, 1224, 64))
        # The new timestamp fence also lets the early snapshot prove freshness
        # when the entire rotated ring is strictly newer than it.
        self.assertEqual(verify.field_point_from_fresh_logs(
            early, after_nav, "hand-scroll-note", (0, 137), 1.0), (660, 681))
        self.assertEqual(verify.field_point_from_fresh_logs(
            latest_geometry, after_nav, "hand-scroll-note", (0, 137), 1.0), (660, 681))

    def test_nav_click_rejects_clipped_fresh_geometry_and_restores_inside_viewport(self):
        before = ["09-28 12:00:00 4321 4321 I /CjguiApp: baseline"]
        after = before + frame_rows(
            "09-28 12:00:01", "settings-focus-note-nav", NAV_NODE,
            (130, 85, 80, 44), (0, 100, 400, 600)) + frame_rows(
            "09-28 12:00:01", "settings-hand-scroll", VIEWPORT_NODE,
            (20, 100, 360, 400), (20, 100, 360, 400))
        nav, viewport = verify.fresh_nav_viewport_geometry(
            before, after, "settings-focus-note-nav", "settings-hand-scroll")
        with self.assertRaisesRegex(ValueError, "fully inside.*clip"):
            verify.nav_screen_point(nav, (24, 48), 1.0)
        swipe = verify.viewport_restore_swipe(nav, viewport, (24, 48), 1.0)
        # Reverse the finger direction within the viewport's visible intersection.
        self.assertEqual(swipe, (224, 348, 224, 364))

        restored = after + frame_rows(
            "09-28 12:00:02", "settings-focus-note-nav", NAV_NODE,
            (130, 101, 80, 44), (0, 100, 400, 600)) + frame_rows(
            "09-28 12:00:02", "settings-hand-scroll", VIEWPORT_NODE,
            (20, 100, 360, 400), (20, 100, 360, 400))
        nav2, _ = verify.fresh_nav_viewport_geometry(
            after, restored, "settings-focus-note-nav", "settings-hand-scroll")
        self.assertEqual(verify.nav_screen_point(nav2, (24, 48), 1.0), (194, 171))

    def test_zero_height_nav_clip_still_restores_directionally_inside_viewport(self):
        before = ["09-28 12:00:00 4321 4321 I /CjguiApp: baseline"]
        after = before + frame_rows(
            "09-28 12:00:01", "settings-focus-note-nav", NAV_NODE,
            (48, 85, 220, 44), (48, 156, 220, 0)) + frame_rows(
            "09-28 12:00:01", "settings-hand-scroll", VIEWPORT_NODE,
            (48, 156, 220, 400), (48, 156, 220, 400))
        nav, viewport = verify.fresh_nav_viewport_geometry(
            before, after, "settings-focus-note-nav", "settings-hand-scroll")
        with self.assertRaisesRegex(ValueError, "fully inside.*clip"):
            verify.nav_screen_point(nav, (0, 137), 1.0, viewport)
        self.assertEqual(
            verify.viewport_restore_swipe(nav, viewport, (0, 137), 1.0),
            (158, 493, 158, 565))

    def test_clickable_nav_at_77px_offset_is_restored_to_initial_position(self):
        # r8 made the nav clickable at y=157, but that left a 77px scroll
        # offset and exposed the note at y=512..576. Return to the initial
        # accepted nav center before claiming that navigation reveals it.
        nav = {"x": 48, "y": 157, "w": 220, "h": 56,
               "clip": (48, 157, 220, 56)}
        viewport = {"x": 48, "y": 156, "w": 220, "h": 420,
                    "clip": (48, 156, 220, 420)}
        origin = (0, 137)
        initial_nav_center = (158, 399)  # local center y=262
        delta = verify.nav_offset_to_initial_y(
            nav, viewport, initial_nav_center, origin, 1.0)
        self.assertEqual(delta, 77)
        self.assertEqual(verify.viewport_scroll_delta_swipe(delta, viewport, origin, 1.0),
                         (158, 503, 158, 580))

        visible_note = frame_rows("09-28 12:00:01.300", "hand-scroll-note", NOTE_NODE,
                                  (48, 512, 220, 64), (48, 512, 220, 64))
        self.assertTrue(verify.editor_visible_in_fenced_geometry(
            visible_note, "hand-scroll-note", viewport, (9, 28, 12, 0, 1, 200_000_000)))
        restored_nav = {**nav, "y": 234, "clip": (48, 156, 220, 420)}
        self.assertEqual(verify.nav_offset_to_initial_y(
            restored_nav, viewport, initial_nav_center, origin, 1.0), 0)
        hidden_note = frame_rows("09-28 12:00:02.300", "hand-scroll-note", NOTE_NODE,
                                 (48, 589, 220, 64), (48, 576, 220, 0))
        self.assertFalse(verify.editor_visible_in_fenced_geometry(
            hidden_note, "hand-scroll-note", viewport, (9, 28, 12, 0, 2, 200_000_000)))

    def test_initial_nav_target_rejects_excessive_or_illegal_baseline_points(self):
        nav = {"x": 48, "y": 157, "w": 220, "h": 56,
               "clip": (48, 157, 220, 56)}
        viewport = {"x": 48, "y": 156, "w": 220, "h": 420,
                    "clip": (48, 156, 220, 420)}
        with self.assertRaisesRegex(ValueError, "outside the visible hand viewport"):
            verify.nav_offset_to_initial_y(nav, viewport, (158, 900), (0, 137), 1.0)
        with self.assertRaisesRegex(ValueError, "horizontally inconsistent"):
            verify.nav_offset_to_initial_y(nav, viewport, (420, 399), (0, 137), 1.0)
        with self.assertRaisesRegex(ValueError, "too small"):
            verify.viewport_scroll_delta_swipe(10000, {
                "x": 48, "y": 156, "w": 220, "h": 1,
                "clip": (48, 156, 220, 1)}, (0, 137), 1.0)

    def test_nav_geometry_requires_fresh_unique_labeled_nav_and_viewport(self):
        baseline = ["09-28 12:00:00 4321 4321 I /CjguiApp: baseline"]
        stale = baseline + frame_rows(
            "09-28 12:00:01", "settings-focus-note-nav", NAV_NODE,
            (130, 106, 80, 44), (0, 100, 400, 600)) + frame_rows(
            "09-28 12:00:01", "settings-hand-scroll", VIEWPORT_NODE,
            (20, 100, 360, 400), (20, 100, 360, 400))
        with self.assertRaisesRegex(ValueError, "fresh"):
            verify.fresh_nav_viewport_geometry(baseline, baseline,
                "settings-focus-note-nav", "settings-hand-scroll")
        conflicting = stale + frame_rows(
            "09-28 12:00:02", "settings-focus-note-nav", NAV_NODE,
            (130, 107, 80, 44), (0, 100, 400, 600))
        with self.assertRaisesRegex(ValueError, "exactly one"):
            verify.fresh_nav_viewport_geometry(baseline, conflicting,
                "settings-focus-note-nav", "settings-hand-scroll")
        # One label resolving to two committed node ids cannot pick a geometry.
        relabeled = stale + frame_rows(
            "09-28 12:00:02", "settings-focus-note-nav", 111,
            (130, 106, 80, 44), (0, 100, 400, 600))
        with self.assertRaisesRegex(ValueError, "ambiguous"):
            verify.fresh_nav_viewport_geometry(baseline, relabeled,
                "settings-focus-note-nav", "settings-hand-scroll")

    def test_nav_geometry_poll_waits_for_delayed_periodic_diagnostics(self):
        with tempfile.TemporaryDirectory() as temp:
            before = ["09-28 12:00:00 4321 4321 I /CjguiApp: baseline"]
            fake = DelayedGeometryHdc("4321", delay_polls=3)
            nav, viewport, final_rows, poll_count, fence = verify.poll_fresh_nav_viewport_geometry(
                fake, Path(temp), before, "after_swipe", "4321",
                "settings-focus-note-nav", "settings-hand-scroll", timeout_seconds=8,
                pause=lambda _: None)
            self.assertEqual(fake.hilog_polls, 4)
            self.assertEqual(poll_count, 4)
            self.assertEqual(nav["y"], 101)
            self.assertEqual(viewport["y"], 100)
            self.assertEqual(fence["epoch"], 42)
            self.assertIn(f"node-rect id={NAV_NODE}", "\n".join(final_rows))
            self.assertIn(f"accepted node={NAV_NODE} semantic=settings-focus-note-nav kind=",
                          "\n".join(final_rows))
            self.assertTrue((Path(temp) / "hilog_after_swipe_poll_001.txt").is_file())
            self.assertTrue((Path(temp) / "hilog_after_swipe_poll_004.txt").is_file())

    def test_nav_geometry_must_follow_current_gesture_terminal_event(self):
        with tempfile.TemporaryDirectory() as temp:
            before = ["09-28 21:53:28.000 4321 4321 I /CjguiApp: baseline"]
            fake = EventOrderedGeometryHdc("4321")
            nav, _, _, poll_count, fence = verify.poll_fresh_nav_viewport_geometry(
                fake, Path(temp), before, "after_swipe", "4321",
                "settings-focus-note-nav", "settings-hand-scroll", timeout_seconds=8,
                pause=lambda _: None)
            self.assertEqual(poll_count, 2)
            self.assertEqual(nav["y"], 85)
            self.assertEqual(fence["timestamp_text"], "09-28 21:53:29.557000000")
            archived = (Path(temp) / "hilog_after_swipe.txt").read_text(encoding="utf-8")
            self.assertIn("21:53:29.557", archived)
            self.assertIn("21:53:32.475", archived)

    def test_rotated_same_pid_touch_and_geometry_use_strictly_newer_device_time(self):
        before = [
            "09-28 23:31:11.900 4321 4321 I /CjguiApp: prior one",
            "09-28 23:31:12.100 4321 4321 I /CjguiApp: prior two",
            "09-28 23:31:12.295 4321 4321 I /CjguiApp: prior latest",
        ]
        # r2's rotated ring begins after the prior snapshot's maximum time and
        # no longer carries the three-line overlap required by the old helper.
        after = [
            "09-28 23:31:13.793 4321 4321 I A00000/CjguiRenderer: "
            "raw touch action=37 x=224 y=348 ep=51",
            "09-28 23:31:13.900 4321 4321 I A00000/CjguiRenderer: "
            "raw touch action=39 x=224 y=364 ep=51",
        ] + frame_rows("09-28 23:31:14.010", "settings-focus-note-nav", NAV_NODE,
                       (130, 101, 80, 44), (0, 100, 400, 600)) + frame_rows(
            "09-28 23:31:14.010", "settings-hand-scroll", VIEWPORT_NODE,
            (20, 100, 360, 400), (20, 100, 360, 400))
        fence = verify.gesture_terminal_fence(before, after)
        self.assertEqual(fence["epoch"], 51)
        self.assertEqual(fence["timestamp_text"], "09-28 23:31:13.900000000")
        nav, viewport = verify.fresh_nav_viewport_geometry(
            before, after, "settings-focus-note-nav", "settings-hand-scroll",
            strictly_after_timestamp=fence["timestamp"])
        self.assertEqual(nav["y"], 101)
        self.assertEqual(viewport["y"], 100)

    def test_rotated_freshness_rejects_clock_rollback_old_or_unparseable_evidence(self):
        before = [
            "09-28 23:31:12.100 4321 4321 I /CjguiApp: prior one",
            "09-28 23:31:12.200 4321 4321 I /CjguiApp: prior two",
            "09-28 23:31:12.295 4321 4321 I /CjguiApp: prior latest",
        ]
        cases = (
            ["09-28 23:31:12.295 4321 4321 I /CjguiApp: only old/equal evidence"],
            ["09-28 23:31:12.200 4321 4321 I /CjguiApp: clock rollback"],
            ["not-a-hilog-row 4321 /CjguiApp: unparseable"],
            ["09-28 23:31:13.793 9999 9999 I /CjguiApp: wrong PID"],
            ["09-28 23:31:13.900 4321 4321 I /CjguiApp: later",
             "09-28 23:31:13.800 4321 4321 I /CjguiApp: out of order"],
        )
        for after in cases:
            with self.subTest(after=after), self.assertRaisesRegex(
                    ValueError, "rotated hilog freshness"):
                verify.fresh_hilog_rows(before, after)

    def test_rotated_business_action_is_detected_from_same_pid_newer_rows(self):
        before = [
            "09-28 23:31:12.100 4321 4321 I /CjguiApp: prior one",
            "09-28 23:31:12.200 4321 4321 I /CjguiApp: prior two",
            "09-28 23:31:12.295 4321 4321 I /CjguiApp: prior latest",
        ]
        after = [
            "09-28 23:31:13.793 4321 4321 I /CjguiApp: action invoke resource=7",
        ]
        with self.assertRaisesRegex(ValueError, "rotated swipe produced a fresh business action"):
            verify._assert_no_fresh_business_action(before, after, "4321", "rotated swipe")

    def test_nav_geometry_poll_times_out_with_each_snapshot_archived(self):
        with tempfile.TemporaryDirectory() as temp:
            before = ["09-28 12:00:00 4321 4321 I /CjguiApp: baseline"]
            fake = DelayedGeometryHdc("4321", delay_polls=100)
            with self.assertRaisesRegex(ValueError, "within 1s"):
                verify.poll_fresh_nav_viewport_geometry(
                    fake, Path(temp), before, "after_swipe", "4321",
                    "settings-focus-note-nav", "settings-hand-scroll",
                    timeout_seconds=1, pause=lambda _: None)
            self.assertEqual(fake.hilog_polls, 3)
            self.assertTrue((Path(temp) / "hilog_after_swipe_poll_001.txt").is_file())
            self.assertTrue((Path(temp) / "hilog_after_swipe_poll_003.txt").is_file())

    def test_nav_geometry_poll_accepts_controlled_ring_rotation_by_same_pid_time(self):
        with tempfile.TemporaryDirectory() as temp:
            before = [
                "09-28 23:31:11.900 4321 4321 I /CjguiApp: prior one",
                "09-28 23:31:12.100 4321 4321 I /CjguiApp: prior two",
                "09-28 23:31:12.295 4321 4321 I /CjguiApp: prior latest",
            ]
            fake = RotatedGeometryHdc("4321")
            nav, viewport, rows, poll_count, fence = verify.poll_fresh_nav_viewport_geometry(
                fake, Path(temp), before, "after_restore", "4321",
                "settings-focus-note-nav", "settings-hand-scroll", timeout_seconds=2,
                pause=lambda _: None)
            self.assertEqual(poll_count, 1)
            self.assertEqual(fence["epoch"], 51)
            self.assertEqual(nav["y"], 101)
            self.assertEqual(viewport["y"], 100)
            self.assertEqual(verify.fresh_hilog_rows(before, rows), rows)
            self.assertTrue((Path(temp) / "hilog_after_restore.txt").exists())

    def test_system_focus_must_follow_a_fresh_same_pid_reveal(self):
        before = ["09-28 12:00:00 4321 4321 I /CjguiApp: baseline " + str(i)
                  for i in range(3)] + frame_rows(
            "09-28 12:00:01.000", "settings-hand-scroll", VIEWPORT_NODE,
            (20, 100, 360, 400), (20, 100, 360, 400)) + frame_rows(
            "09-28 12:00:01.000", "hand-scroll-note", NOTE_NODE,
            (20, 520, 360, 44), (20, 500, 360, 0))
        good = before + [
            "09-28 12:00:02.100 4321 4321 I A00000/CjguiRenderer: "
            "raw touch action=37 x=158 y=263 ep=22",
            "09-28 12:00:02.200 4321 4321 I A00000/CjguiRenderer: "
            "raw touch action=39 x=158 y=263 ep=22",
            "09-28 12:00:02.300 4321 4321 I A00000/CjguiRenderer: "
            "focus api enter node=88 accepted=21",
            "09-28 12:00:02.300 4321 4321 I A00000/CjguiRenderer: "
            "platform focus reveal requested node=88 ctx=21",
            '09-28 12:00:02.300 4321 4321 I /CjguiApp: '
            'ime focus payload={"action":"focus","context":21,"field":"hand-scroll-note"}',
            "09-28 12:00:02.350 4321 4321 I /CjguiApp: "
            "ime proxy mounted ctx=21 field=hand-scroll-note node=88 gen=1",
            "09-28 12:00:02.400 4321 4321 I /CjguiApp: ime proxy FOCUSED "
            "field=hand-scroll-note mount=m-1",
        ] + frame_rows("09-28 12:00:02.500", "settings-hand-scroll", VIEWPORT_NODE,
                       (20, 100, 360, 400), (20, 100, 360, 400)) + frame_rows(
            "09-28 12:00:02.500", "hand-scroll-note", NOTE_NODE,
            (130, 300, 80, 44), (20, 100, 360, 400))
        self.assertEqual(verify._assert_fresh_reveal_then_focus(
            before, good, "4321", "hand-scroll-note"), ("88", "m-1"))
        focus_only = before + good[-2:]
        with self.assertRaisesRegex(ValueError, "END/CANCEL fence"):
            verify._assert_fresh_reveal_then_focus(
                before, focus_only, "4321", "hand-scroll-note")
        with self.assertRaisesRegex(ValueError, "fresh accepted editor geometry"):
            verify._assert_fresh_reveal_then_focus(
                before, good[:-2], "4321", "hand-scroll-note")
        wrong_order = before + good[len(before):len(before) + 3] + [
            good[len(before) + 4], good[len(before) + 3], *good[len(before) + 5:]]
        with self.assertRaisesRegex(ValueError, "out of order"):
            verify._assert_fresh_reveal_then_focus(
                before, wrong_order, "4321", "hand-scroll-note")

    def test_accepted_editor_reveal_proves_geometry_transition_without_reveal_literal(self):
        # The focused renderer node and the accepted editor node are the same id.
        note_node = 942
        before = frame_rows(
            "09-28 22:49:14.554", "settings-hand-scroll", VIEWPORT_NODE,
            (28, 156, 1264, 420), (28, 156, 1264, 420)) + frame_rows(
            "09-28 22:49:17.862", "settings-focus-note-nav", NAV_NODE,
            (48, 234, 220, 56), (48, 234, 220, 56)) + frame_rows(
            "09-28 22:49:17.862", "settings-hand-scroll", VIEWPORT_NODE,
            (28, 156, 1264, 420), (28, 156, 1264, 420)) + frame_rows(
            "09-28 22:49:17.862", "hand-scroll-note", note_node,
            (48, 834, 1224, 64), (48, 834, 1224, 0))
        after = before + [
            "09-28 22:49:18.715 4321 4321 I A00000/CjguiRenderer: "
            "raw touch action=37 x=158 y=263 ep=4",
            "09-28 22:49:18.819 4321 4321 I A00000/CjguiRenderer: "
            "raw touch action=39 x=158 y=263 ep=4",
            "09-28 22:49:18.835 4321 4321 I A00000/CjguiRenderer: "
            "focus api enter node=942 accepted=43",
            "09-28 22:49:18.835 4321 4321 I A00000/CjguiRenderer: "
            "platform focus node=942 ctx=1 field=hand-scroll-note",
            "09-28 22:49:18.835 4321 4321 I /CjguiApp: "
            'ime focus payload={"action":"focus","context":1,"field":"hand-scroll-note"}',
            "09-28 22:49:18.900 4321 4321 I /CjguiApp: "
            "ime proxy mounted ctx=1 field=hand-scroll-note node=942 gen=1",
            "09-28 22:49:19.133 4321 4321 I /CjguiApp: "
            "ime proxy FOCUSED field=hand-scroll-note mount=app1/s1/c1/e1/m1",
        ] + frame_rows("09-28 22:49:22.140", "settings-focus-note-nav", NAV_NODE,
                       (48, 234, 220, 56), (48, 234, 220, 56)) + frame_rows(
            "09-28 22:49:22.140", "settings-hand-scroll", VIEWPORT_NODE,
            (28, 156, 1264, 420), (28, 156, 1264, 420)) + frame_rows(
            "09-28 22:49:22.140", "hand-scroll-note", note_node,
            (48, 512, 1224, 64), (48, 512, 1224, 64))
        self.assertEqual(verify._assert_fresh_reveal_then_focus(
            before, after, "4321", "hand-scroll-note"),
            ("942", "app1/s1/c1/e1/m1"))

    def test_reveal_frame_settling_before_ime_focus_still_proves_reveal(self):
        # Device shape 2026-09-30: the reveal settle commits before the IME proxy
        # reports mount/FOCUSED, so the reveal proof is fenced by the click terminal
        # and by the clipped pre-click premise, not by the FOCUSED row.
        note_node = 942
        before = frame_rows(
            "09-30 08:33:55.100", "settings-hand-scroll", VIEWPORT_NODE,
            (12, 82, 353, 150), (12, 82, 353, 150)) + frame_rows(
            "09-30 08:33:55.100", "hand-scroll-note", note_node,
            (20, 468, 337, 32), (20, 468, 337, 0))
        focus_chain = [
            "09-30 08:33:56.310 4321 4321 I A00000/CjguiRenderer: "
            "raw touch action=37 x=262 y=588 ep=7",
            "09-30 08:33:56.390 4321 4321 I A00000/CjguiRenderer: "
            "raw touch action=39 x=262 y=588 ep=7",
            "09-30 08:33:56.394 4321 4321 I A00000/CjguiRenderer: "
            "focus api enter node=942 accepted=51",
            "09-30 08:33:56.395 4321 4321 I A00000/CjguiRenderer: "
            "platform focus reveal requested node=942 ctx=51",
            '09-30 08:33:56.395 4321 4321 I /CjguiApp: '
            'ime focus payload={"action":"focus","context":51,"field":"hand-scroll-note"}',
        ]
        reveal = frame_rows("09-30 08:33:56.396", "settings-hand-scroll", VIEWPORT_NODE,
                            (12, 82, 353, 150), (12, 82, 353, 150)) + frame_rows(
            "09-30 08:33:56.396", "hand-scroll-note", note_node,
            (20, 180, 337, 32), (20, 180, 337, 32))
        ime_tail = [
            "09-30 08:33:56.397 4321 4321 I /CjguiApp: "
            "ime proxy mounted ctx=51 field=hand-scroll-note node=942 gen=1",
            "09-30 08:33:56.680 4321 4321 I /CjguiApp: "
            "ime proxy FOCUSED field=hand-scroll-note mount=app1/s1/c1/e1/m1",
        ]
        self.assertEqual(verify._assert_fresh_reveal_then_focus(
            before, before + focus_chain + reveal + ime_tail, "4321",
            "hand-scroll-note"), ("942", "app1/s1/c1/e1/m1"))
        still_clipped = before + focus_chain + frame_rows(
            "09-30 08:33:56.396", "settings-hand-scroll", VIEWPORT_NODE,
            (12, 82, 353, 150), (12, 82, 353, 150)) + frame_rows(
            "09-30 08:33:56.396", "hand-scroll-note", note_node,
            (20, 468, 337, 32), (20, 468, 337, 0)) + ime_tail
        with self.assertRaisesRegex(ValueError, "not fully visible"):
            verify._assert_fresh_reveal_then_focus(
                before, still_clipped, "4321", "hand-scroll-note")


class ControlledWorkflowTests(unittest.TestCase):
    def test_nonempty_owner_long_press_direct_full_selection_skips_absent_menu(self):
        with tempfile.TemporaryDirectory() as temp:
            out = Path(temp) / "run"
            args = fixture_args(Path(temp), out)
            args.nav_x, args.nav_y = 194, 220
            fake = FakeWorkflowHdc("sim-1", "org.example.app", "4321")
            fake.direct_full_select_on_long_click = True
            fake.direct_selection_range = (0, 10)
            fake.menu_selection_range = (0, 10)
            fake.menu_visible = False
            exchange = FakeOwnerExchange(
                field="scrollNote", resource=9700,
                values=[(4, "HtouchBase"), (4, "HtouchBase"), (4, "HtouchBase"),
                        (4, "HtouchBase"), (4, "HtouchBase"), (4, "HtouchBase"),
                        (5, "连续消费新值")])
            exchange.window_selection = ("component-note", 0, 10)

            result = verify.run_probe(args, fake, exchange, pause=lambda _: None)

            self.assertEqual(result["selection_utf16"], (0, 10))
            evidence = json.loads((out / "system_selection.json").read_text(encoding="utf-8"))
            self.assertEqual(evidence["method"], "long_press_direct_full_selection")
            self.assertIsNone(evidence["menu_point"])
            self.assertEqual(evidence["owner_selection_utf16_length"], 10)
            self.assertNotIn("uitest uiInput click 130 120", fake.commands)

    def test_empty_owner_fails_with_prefill_requirement_before_any_touch(self):
        with tempfile.TemporaryDirectory() as temp:
            out = Path(temp) / "run"
            args = fixture_args(Path(temp), out)
            args.nav_x, args.nav_y = 194, 220
            fake = FakeWorkflowHdc("sim-1", "org.example.app", "4321")
            exchange = FakeOwnerExchange(
                field="scrollNote", resource=9700,
                values=[(4, ""), (4, ""), (4, ""), (4, ""), (4, ""),
                        (4, ""), (5, "连续消费新值")])
            with self.assertRaisesRegex(ValueError, "prefill.*non-empty"):
                verify.run_probe(args, fake, exchange, pause=lambda _: None)
            self.assertFalse(any(command.startswith("uitest uiInput")
                                 for command in fake.commands))

    def test_direct_ime_range_without_matching_public_selection_falls_back_to_menu(self):
        with tempfile.TemporaryDirectory() as temp:
            out = Path(temp) / "run"
            args = fixture_args(Path(temp), out)
            args.nav_x, args.nav_y = 194, 220
            fake = FakeWorkflowHdc("sim-1", "org.example.app", "4321")
            fake.direct_full_select_on_long_click = True
            fake.direct_selection_range = (0, 10)
            fake.menu_selection_range = (0, 10)
            exchange = FakeOwnerExchange(
                field="scrollNote", resource=9700,
                values=[(4, "HtouchBase"), (4, "HtouchBase"), (4, "HtouchBase"),
                        (4, "HtouchBase"), (4, "HtouchBase"), (4, "HtouchBase"),
                        (5, "连续消费新值")])
            exchange.window_selection_values = [
                ("component-note", 0, 9), ("component-note", 0, 10)]

            result = verify.run_probe(args, fake, exchange, pause=lambda _: None)

            self.assertEqual(result["selection_utf16"], (0, 10))
            evidence = json.loads((out / "system_selection.json").read_text(encoding="utf-8"))
            self.assertEqual(evidence["method"], "system_select_all_menu")
            self.assertIn("full non-empty UTF-16 range", evidence["direct_selection_fallback_reason"])
            self.assertIn("uitest uiInput click 130 120", fake.commands)

    def test_wrong_foreground_bundle_blocks_gesture_and_archives_layout(self):
        with tempfile.TemporaryDirectory() as temp:
            out = Path(temp) / "run"
            args = fixture_args(Path(temp), out)
            fake = FakeWorkflowHdc("sim-1", "org.example.app", "4321")
            fake.visible_roots = ["com.example.cjguiapp"]
            exchange = FakeOwnerExchange("scrollNote", 9700,
                [(4, "初始备注"), (4, "初始备注")])
            with self.assertRaisesRegex(ValueError, "foreground UITest root bundle mismatch"):
                verify.run_probe(args, fake, exchange, pause=lambda _: None)
            self.assertFalse(any(command.startswith("uitest uiInput ")
                                 for command in fake.commands))
            self.assertTrue((out / "failure.json").is_file())
            self.assertTrue((out / "uitest_layout_before_initial_swipe.json").is_file())

    def test_ambiguous_foreground_roots_block_gesture(self):
        with tempfile.TemporaryDirectory() as temp:
            out = Path(temp) / "run"
            args = fixture_args(Path(temp), out)
            fake = FakeWorkflowHdc("sim-1", "org.example.app", "4321")
            fake.visible_roots = ["org.example.app", "com.example.cjguiapp"]
            exchange = FakeOwnerExchange("scrollNote", 9700,
                [(4, "初始备注"), (4, "初始备注")])
            with self.assertRaisesRegex(ValueError, "exactly one visible app UITest root"):
                verify.run_probe(args, fake, exchange, pause=lambda _: None)
            self.assertFalse(any(command.startswith("uitest uiInput ")
                                 for command in fake.commands))

    def test_swipe_preserves_owner_then_nav_selects_replaces_and_reads_exact_owner(self):
        # This test uses a fake HDC and owner endpoint. It never touches a device.
        with tempfile.TemporaryDirectory() as temp:
            out = Path(temp) / "run"
            args = verify.parse_args([
                "--target", "sim-1", "--bundle", "org.example.app",
                "--hap", str(Path(temp) / "normal.hap"), "--hap-sha256", "a" * 64,
                "--pid", "4321", "--forward-receipt-json", str(Path(temp) / "receipt.json"),
                "--local-port", "17441", "--device-port", "7856", "--field", "scrollNote",
                "--resource-id", "9700", "--auth", "capability-token", "--ime-field", "hand-scroll-note",
                "--nav-x", "194", "--nav-y", "220",
                "--nav-semantic-id", "settings-focus-note-nav",
                "--viewport-semantic-id", "settings-hand-scroll",
                "--field-semantic-id", "hand-scroll-note", "--xcomponent-origin-x", "24",
                "--xcomponent-origin-y", "48", "--density", "1",
                "--swipe-start-x", "120", "--swipe-start-y", "500",
                "--swipe-end-x", "120", "--swipe-end-y", "240",
                "--replacement", "连续消费新值", "--run-dir", str(out),
            ])
            args.hap.write_bytes(b"normal-hap-fixture")
            args.forward_receipt_json.write_text(json.dumps({
                "target": "sim-1", "local_port": 17441, "device_port": 7856,
                "returncode": 0,
                "command": ["hdc", "-t", "sim-1", "fport", "tcp:17441", "tcp:7856"],
                "stdout": "Forwardport result:OK", "stderr": "",
            }), encoding="utf-8")
            args.hap_sha256 = verify.hash_file(args.hap)
            fake = FakeWorkflowHdc("sim-1", "org.example.app", "4321")
            fake.delay_geometry_polls = 3
            fake.delay_reveal_geometry_polls = 4
            fake.rotate_hilog_after_nav = True
            exchange = FakeOwnerExchange(
                field="scrollNote", resource=9700,
                values=[(4, "初始备注"), (4, "初始备注"), (4, "初始备注"),
                        (4, "初始备注"), (4, "初始备注"), (4, "初始备注"),
                        (5, "连续消费新值")])

            result = verify.run_probe(args, fake, exchange, pause=lambda _: None)

            self.assertEqual(result["status"], "passed")
            self.assertEqual(result["nav_geometry"]["final_nav"]["y"], 150)
            commands = [row for row in fake.commands if row.startswith("uitest uiInput")]
            self.assertEqual(commands[0], "uitest uiInput swipe 120 500 120 240 700")
            self.assertIn("uitest uiInput swipe 224 348 224 364 700", commands)
            self.assertIn("uitest uiInput swipe 224 348 224 397 700", commands)
            self.assertIn("uitest uiInput click 194 220", commands)
            self.assertNotIn("uitest uiInput click 220 680", commands)
            self.assertIn("uitest uiInput keyEvent 2055", commands)
            self.assertIn("uitest uiInput click 194 370", commands)
            self.assertIn("uitest uiInput inputText 194 370 '连续消费新值'", commands)
            self.assertNotIn("uitest uiInput click 180 680", commands)
            self.assertLess(commands.index("uitest uiInput swipe 224 348 224 397 700"),
                            commands.index("uitest uiInput click 194 220"))
            self.assertLess(commands.index("uitest uiInput click 194 220"),
                            commands.index("uitest uiInput keyEvent 2055"))
            nav_geometry = json.loads((out / "nav_geometry.json").read_text(encoding="utf-8"))
            self.assertEqual(nav_geometry["initial_offset_alignment_delta"], 0)
            self.assertEqual(len(nav_geometry["initial_offset_restore_steps"]), 1)
            self.assertFalse(nav_geometry["editor_visible_before_nav"])
            self.assertEqual(nav_geometry["reveal_poll_count"], 4)
            self.assertGreaterEqual(fake.hilog_polls, 5)
            foreground_checks = json.loads(
                (out / "foreground_root_checks.json").read_text(encoding="utf-8"))
            self.assertTrue(any(
                check["stage"] == "before_field_click" and
                "com.huawei.hmos.inputmethod" in check["observed_root_bundles"]
                for check in foreground_checks))
            self.assertFalse(any(" fport tcp:" in command for command in fake.commands))
            self.assertTrue((out / "owner_before.txt").is_file())
            self.assertTrue((out / "owner_after.txt").is_file())

    def test_failed_owner_readback_is_archived_with_hdc_and_exchange_evidence(self):
        with tempfile.TemporaryDirectory() as temp:
            out = Path(temp) / "run"
            args = fixture_args(Path(temp), out)
            fake = FakeWorkflowHdc("sim-1", "org.example.app", "4321")
            exchange = FakeOwnerExchange("scrollNote", 9700,
                [(4, "初始备注"), (4, "被意外写入"), (4, "初始备注"),
                 (4, "草稿不应改变 owner"), (5, "错误值")])
            with self.assertRaisesRegex(ValueError, "owner changed during initial swipe"):
                verify.run_probe(args, fake, exchange, pause=lambda _: None)
            self.assertTrue((out / "failure.json").is_file())
            self.assertTrue((out / "hdc_commands.json").is_file())
            self.assertTrue((out / "exchanges.json").is_file())


class FakeWorkflowHdc:
    def __init__(self, target, bundle, pid):
        self.target, self.bundle, self._pid = target, bundle, pid
        self.commands = []
        self.visible_roots = [bundle]
        self.offset_restored = False
        self.keep_editor_visible_after_offset = False
        self.hilog_polls = 0
        self.delay_geometry_polls = 0
        self._pending_geometry = []
        self.delay_reveal_geometry_polls = 0
        self._pending_reveal_geometry = []
        self.rotate_hilog_after_nav = False
        self._rotation_anchor_count = None
        self._rotation_prefix = []
        self.direct_full_select_on_long_click = False
        self.direct_selection_range = (0, 4)
        self.menu_selection_range = (0, 4)
        self.menu_visible = True
        self.touch_epoch = 13
        self.rows = [self._row("baseline one"), self._row("baseline two"),
                     self._row("baseline three")]

    def _row(self, message):
        return f"09-28 12:00:00 {self._pid} {self._pid} I /CjguiApp: {message}"

    def _renderer_row(self, message):
        return f"09-28 12:00:00 {self._pid} {self._pid} I A00000/CjguiRenderer: {message}"

    def _row_at(self, timestamp, message, component="CjguiApp"):
        tag = "/CjguiApp" if component == "CjguiApp" else "A00000/CjguiRenderer"
        return f"09-28 {timestamp} {self._pid} {self._pid} I {tag}: {message}"

    def _frame_at(self, timestamp, semantic_id, node_id, rect, clip):
        """The accepted-frame pair one committed frame emits for a node (vp)."""
        x, y, width, height = rect
        clip_x, clip_y, clip_width, clip_height = clip
        return [
            self._row_at(timestamp,
                         f"node-rect id={node_id} x={x} y={y} w={width} h={height} "
                         f"clip=({clip_x},{clip_y},{clip_width},{clip_height})",
                         "CjguiRenderer"),
            self._row_at(timestamp,
                         f"accepted node={node_id} semantic={semantic_id} kind=9 "
                         f"label=可见文本-{node_id} value= v=1",
                         "CjguiRenderer"),
        ]

    def listing(self):
        self.commands.append("fport ls")
        return f"{self.target} tcp:17441 tcp:7856 [Forward]"

    def pidof(self, bundle):
        self.commands.append(f"pidof {bundle}")
        return self._pid

    def shell(self, command, *, timeout=45):
        self.commands.append(command)
        if command.startswith("pidof "):
            return self._pid
        if command.startswith("hilog "):
            self.hilog_polls += 1
            if self._rotation_anchor_count is not None:
                suffix = self.rows[self._rotation_anchor_count:]
                self.rows = self._rotation_prefix + suffix
                self._rotation_anchor_count = None
                self._rotation_prefix = []
            if self._pending_geometry:
                self.delay_geometry_polls -= 1
                if self.delay_geometry_polls <= 0:
                    self.rows.extend(self._pending_geometry)
                    self._pending_geometry = []
            if self._pending_reveal_geometry:
                self.delay_reveal_geometry_polls -= 1
                if self.delay_reveal_geometry_polls <= 0:
                    self.rows.extend(self._pending_reveal_geometry)
                    self._pending_reveal_geometry = []
            return "\n".join(self.rows)
        if command.startswith("uitest uiInput swipe 120 500 120 240"):
            self.touch_epoch += 1
            epoch = self.touch_epoch
            self.rows.extend((
                self._row_at("12:00:01.100", f"raw touch action=37 x=120 y=500 ep={epoch}",
                             "CjguiRenderer"),
                self._row_at("12:00:01.200", f"raw touch action=39 x=120 y=240 ep={epoch}",
                             "CjguiRenderer"),
            ))
            geometry = [
                *self._frame_at("12:00:01.300", "settings-focus-note-nav", NAV_NODE,
                                (130, 85, 80, 44), (0, 100, 400, 600)),
                *self._frame_at("12:00:01.300", "settings-hand-scroll", VIEWPORT_NODE,
                                (20, 100, 360, 400), (20, 100, 360, 400)),
            ]
            if self.delay_geometry_polls > 0:
                self._pending_geometry = list(geometry)
            else:
                self.rows.extend(geometry)
        elif command.startswith("uitest uiInput swipe 224 348 224 364"):
            self.touch_epoch += 1
            epoch = self.touch_epoch
            self.rows.extend((
                self._row_at("12:00:02.100", f"raw touch action=37 x=224 y=348 ep={epoch}",
                             "CjguiRenderer"),
                self._row_at("12:00:02.200", f"raw touch action=39 x=224 y=364 ep={epoch}",
                             "CjguiRenderer"),
            ))
            self.rows.extend(
                self._frame_at("12:00:02.300", "settings-focus-note-nav", NAV_NODE,
                               (130, 101, 80, 44), (0, 100, 400, 600)))
            self.rows.extend(
                self._frame_at("12:00:02.300", "settings-hand-scroll", VIEWPORT_NODE,
                               (20, 100, 360, 400), (20, 100, 360, 400)))
        elif command.startswith("uitest uiInput swipe 224 348 224 397"):
            self.touch_epoch += 1
            epoch = self.touch_epoch
            self.offset_restored = True
            self.rows.extend((
                self._row_at("12:00:03.100", f"raw touch action=37 x=224 y=348 ep={epoch}",
                             "CjguiRenderer"),
                self._row_at("12:00:03.200", f"raw touch action=39 x=224 y=397 ep={epoch}",
                             "CjguiRenderer"),
            ))
            self.rows.extend(
                self._frame_at("12:00:03.300", "settings-focus-note-nav", NAV_NODE,
                               (130, 150, 80, 44), (20, 100, 360, 400)))
            self.rows.extend(
                self._frame_at("12:00:03.300", "settings-hand-scroll", VIEWPORT_NODE,
                               (20, 100, 360, 400), (20, 100, 360, 400)))
            if self.keep_editor_visible_after_offset:
                note_rect, note_clip = (20, 480, 360, 44), (20, 480, 360, 20)
            else:
                note_rect, note_clip = (20, 520, 360, 44), (20, 500, 360, 0)
            self.rows.extend(
                self._frame_at("12:00:03.300", "hand-scroll-note", NOTE_NODE,
                               note_rect, note_clip))
        elif command.startswith("uitest uiInput click 194 "):
            self.visible_roots = [self.bundle, "com.huawei.hmos.inputmethod"]
            if self.offset_restored:
                if self.rotate_hilog_after_nav:
                    self._rotation_anchor_count = len(self.rows)
                    self._rotation_prefix = self.rows[-3:]
                self.rows.extend((
                    self._row_at("12:00:04.100", f"raw touch action=37 x=194 y=198 ep={self.touch_epoch + 1}",
                                 "CjguiRenderer"),
                    self._row_at("12:00:04.200", f"raw touch action=39 x=194 y=198 ep={self.touch_epoch + 1}",
                                 "CjguiRenderer"),
                    self._row_at("12:00:04.300", "focus api enter node=88 accepted=21",
                                 "CjguiRenderer"),
                    self._row_at("12:00:04.300", "platform focus node=88 ctx=21 field=hand-scroll-note",
                                 "CjguiRenderer"),
                    self._row_at("12:00:04.300", 'ime focus payload={"action":"focus","context":21,"field":"hand-scroll-note"}'),
                    self._row_at("12:00:04.350", "ime proxy mounted ctx=21 field=hand-scroll-note node=88 gen=1"),
                    self._row_at("12:00:04.400", "ime proxy FOCUSED field=hand-scroll-note mount=m-1"),
            ))
                geometry = [
                    *self._frame_at("12:00:04.500", "settings-hand-scroll", VIEWPORT_NODE,
                                    (20, 100, 360, 400), (20, 100, 360, 400)),
                    *self._frame_at("12:00:04.500", "hand-scroll-note", NOTE_NODE,
                                    (130, 300, 80, 44), (20, 100, 360, 400)),
                ]
                if self.delay_reveal_geometry_polls > 0:
                    self._pending_reveal_geometry = geometry
                else:
                    self.rows.extend(geometry)
            else:
                self.rows.append(self._row(
                    "ime proxy FOCUSED field=hand-scroll-note mount=m-1"))
        # x 130 vp + the 15 vp leading text inset, offset by the XComponent origin.
        elif command.startswith("uitest uiInput longClick 169 "):
            if self.direct_full_select_on_long_click:
                self.rows.append(self._row(
                    f"ime select [{self.direct_selection_range[0]},"
                    f"{self.direct_selection_range[1]}) rc=0 mount=m-1"))
        elif command == "uitest uiInput click 130 120":
            self.rows.append(self._row(
                f"ime select [{self.menu_selection_range[0]},"
                f"{self.menu_selection_range[1]}) rc=0 mount=m-1"))
        elif command == "uitest uiInput keyEvent 2055":
            self.rows.extend((self._row("ime proxy onChange len=0 verdict=ok mount=m-1"),
                              self._row("ime proxy onChange len=6 verdict=ok mount=m-1")))
        elif command.startswith("uitest uiInput inputText "):
            self.rows.append(self._row("ime proxy onChange len=6 verdict=ok mount=m-1"))
        elif command == "uitest uiInput keyEvent 2054":
            self.rows.append(self._row("ime proxy submit verdict=ok mount=m-1"))
        return ""

    def pull(self, remote, local):
        roots = []
        for index, bundle in enumerate(self.visible_roots):
            roots.append({"attributes": {"type": "root", "visible": "true",
                                          "bundleName": bundle},
                          "children": ([{"attributes": {"text": "全选",
                                                         "bounds": "[100,100][160,140]"},
                                         "children": []}] if index == 0 and self.menu_visible else [])})
        Path(local).write_text(json.dumps({"attributes": {}, "children": roots}),
                               encoding="utf-8")


class DelayedGeometryHdc:
    def __init__(self, pid: str, delay_polls: int):
        self.pid = pid
        self.delay_polls = delay_polls
        self.hilog_polls = 0
        self.commands = []
        self.rows = [f"09-28 12:00:00 {pid} {pid} I /CjguiApp: baseline"]

    def shell(self, command, *, timeout=45):
        self.commands.append(command)
        self.hilog_polls += 1
        if self.hilog_polls > self.delay_polls:
            self.rows.extend((
                f"09-28 12:00:01.000 {self.pid} {self.pid} I /CjguiRenderer: "
                "raw touch action=37 x=120 y=500 ep=42",
                f"09-28 12:00:01.050 {self.pid} {self.pid} I /CjguiRenderer: "
                "raw touch action=39 x=120 y=240 ep=42",
            ))
            self.rows.extend(
                frame_rows("09-28 12:00:01.100", "settings-focus-note-nav", NAV_NODE,
                           (130, 101, 80, 44), (0, 100, 400, 600), pid=self.pid))
            self.rows.extend(
                frame_rows("09-28 12:00:01.100", "settings-hand-scroll", VIEWPORT_NODE,
                           (20, 100, 360, 400), (20, 100, 360, 400), pid=self.pid))
        return "\n".join(self.rows)


class RotatedGeometryHdc:
    """A fresh same-PID ring snapshot with no overlap to the prior capture."""

    def __init__(self, pid: str):
        self.pid = pid
        self.polls = 0
        self.commands = []

    def shell(self, command, *, timeout=45):
        self.commands.append(command)
        self.polls += 1
        return "\n".join((
            f"09-28 23:31:13.793 {self.pid} {self.pid} I A00000/CjguiRenderer: "
            "raw touch action=37 x=224 y=348 ep=51",
            f"09-28 23:31:13.900 {self.pid} {self.pid} I A00000/CjguiRenderer: "
            "raw touch action=39 x=224 y=364 ep=51",
            *frame_rows("09-28 23:31:14.010", "settings-focus-note-nav", NAV_NODE,
                        (130, 101, 80, 44), (0, 100, 400, 600), pid=self.pid),
            *frame_rows("09-28 23:31:14.010", "settings-hand-scroll", VIEWPORT_NODE,
                        (20, 100, 360, 400), (20, 100, 360, 400), pid=self.pid),
        ))


class EventOrderedGeometryHdc:
    def __init__(self, pid: str):
        self.pid = pid
        self.polls = 0
        self.commands = []
        self.rows = [f"09-28 21:53:28.000 {pid} {pid} I /CjguiApp: baseline"]

    def row(self, timestamp, message):
        return f"09-28 {timestamp} {self.pid} {self.pid} I /CjguiApp: {message}"

    def shell(self, command, *, timeout=45):
        self.commands.append(command)
        self.polls += 1
        if self.polls == 1:
            self.rows.extend(
                frame_rows("09-28 21:53:29.157", "settings-focus-note-nav", NAV_NODE,
                           (130, 234, 80, 44), (0, 0, 400, 600), pid=self.pid))
            self.rows.extend(
                frame_rows("09-28 21:53:29.157", "settings-hand-scroll", VIEWPORT_NODE,
                           (20, 0, 360, 600), (20, 0, 360, 600), pid=self.pid))
            self.rows.extend((
                self.row("21:53:29.300", "raw touch action=37 x=158 y=399 ep=14"),
                self.row("21:53:29.557", "raw touch action=39 x=158 y=250 ep=14"),
            ))
        elif self.polls == 2:
            self.rows.extend(
                frame_rows("09-28 21:53:32.475", "settings-focus-note-nav", NAV_NODE,
                           (130, 85, 80, 44), (0, 0, 400, 600), pid=self.pid))
            self.rows.extend(
                frame_rows("09-28 21:53:32.475", "settings-hand-scroll", VIEWPORT_NODE,
                           (20, 0, 360, 600), (20, 0, 360, 600), pid=self.pid))
        return "\n".join(self.rows)


class FakeOwnerExchange:
    def __init__(self, field, resource, values):
        self.field, self.resource = field, resource
        self.values = list(values)
        self.raw_log = []
        self.window_selection = ("component-note", 0, 4)
        self.window_selection_values = []

    def exchange_strict(self, payload, timeout):
        if any(line == "GET_WINDOW_INTERACTION" for line in payload):
            observed_selection = (self.window_selection_values.pop(0)
                                  if self.window_selection_values else self.window_selection)
            focus = "component-note" if observed_selection else "none"
            selection_line = ""
            if observed_selection is not None:
                control, start, end = observed_selection
                selection_line = ("WINDOW_SELECTION_POSITION_UNIT UTF16_CODE_UNIT\n"
                                  f"WINDOW_SELECTION {control} {start} {end}\n")
            raw = ("PROTOCOL CJGUI_SHARED_OPERATION/2\nKIND WINDOW_INTERACTION\n"
                   "WINDOW_FOCUS_STATE valid\nWINDOW_FOCUS " + focus + "\n"
                   + selection_line + "END")
            self.raw_log.extend(({"dir": "request", "raw": "\n".join(payload)},
                                 {"dir": "response", "raw": raw}))
            return "\n".join(payload), raw
        version, value = self.values.pop(0)
        encoded = value.encode("utf-8").hex() or "-"
        raw = (f"PROTOCOL {selection.PROTOCOL}\nKIND SNAPSHOT\nVERSION {version}\n"
               f"FIELD {self.resource} {self.field} STRING {len(value.encode('utf-8'))} "
               f"{encoded}\nEND")
        self.raw_log.extend(({"dir": "request", "raw": "\n".join(payload)},
                             {"dir": "response", "raw": raw}))
        return "\n".join(payload), raw

    def flush_archive(self):
        pass


def fixture_args(temp, out):
    hap = Path(temp) / "normal.hap"
    hap.write_bytes(b"normal-hap-fixture")
    receipt = Path(temp) / "receipt.json"
    receipt.write_text(json.dumps({
        "target": "sim-1", "local_port": 17441, "device_port": 7856,
        "returncode": 0,
        "command": ["hdc", "-t", "sim-1", "fport", "tcp:17441", "tcp:7856"],
        "stdout": "Forwardport result:OK", "stderr": "",
    }), encoding="utf-8")
    return verify.parse_args([
        "--target", "sim-1", "--bundle", "org.example.app", "--hap", str(hap),
        "--hap-sha256", verify.hash_file(hap), "--pid", "4321",
        "--forward-receipt-json", str(receipt), "--local-port", "17441",
        "--device-port", "7856", "--field", "scrollNote", "--resource-id", "9700",
        "--auth", "capability-token", "--ime-field", "hand-scroll-note",
        "--nav-x", "220", "--nav-y", "680",
        "--nav-semantic-id", "settings-focus-note-nav",
        "--viewport-semantic-id", "settings-hand-scroll",
        "--field-semantic-id", "hand-scroll-note", "--xcomponent-origin-x", "24",
        "--xcomponent-origin-y", "48", "--density", "1",
        "--swipe-start-x", "120", "--swipe-start-y", "500",
        "--swipe-end-x", "120", "--swipe-end-y", "240",
        "--replacement", "连续消费新值",
        "--run-dir", str(out),
    ])


if __name__ == "__main__":
    unittest.main(verbosity=2)

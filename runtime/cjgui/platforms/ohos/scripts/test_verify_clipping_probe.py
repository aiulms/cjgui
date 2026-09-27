#!/usr/bin/env python3
"""Offline counterexamples for the OHOS clipping verifier."""

import importlib.util
import tempfile
import unittest
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import patch

from PIL import Image, ImageDraw


SCRIPT = Path(__file__).with_name("verify_clipping_probe.py")
SPEC = importlib.util.spec_from_file_location("verify_clipping_probe_under_test", SCRIPT)
probe = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(probe)


class FakeExchange:
    def __init__(self, responses):
        self.responses = iter(responses)
        self.calls = []

    def exchange_strict(self, lines, timeout):
        self.calls.append((lines, timeout))
        return "", next(self.responses)


def geometry(out_height=40, next_box_y=784, noclip_box_y=912):
    rects = {
        40: (52, 636, 400, 50),
        42: (52, 676, 400, 40),
        43: (52, 716, 400, out_height),
        44: (52, next_box_y, 400, 50),
        45: (52, next_box_y, 380, 80),
        46: (52, noclip_box_y, 400, 50),
        47: (52, noclip_box_y, 380, 80),
    }
    clips = {
        42: (52, 676, 400, 10),
        43: (52, 716, 400, 0),
        45: (52, next_box_y, 380, 50),
        47: (52, noclip_box_y, 380, 80),
    }
    return rects, clips


class ClippingProbeTests(unittest.TestCase):
    def test_touch_waits_for_its_own_result_id(self):
        responses = [
            "CONTROL CJGUI_VERIFY/1\nKIND OK\nOP TOUCH_37_10_20\nPUBLISHED 2\nEND",
            "CONTROL CJGUI_VERIFY/1\nKIND OK\nOP GATE_STATE\nLAST_COMMAND 2\nRESULT_ID 1\nRESULT touch=0\nEND",
            "CONTROL CJGUI_VERIFY/1\nKIND OK\nOP GATE_STATE\nLAST_COMMAND 2\nRESULT_ID 2\nRESULT touch=0\nEND",
        ]
        fake = FakeExchange(responses)
        with patch.object(probe, "EXCHANGE", fake), patch.object(probe, "TOKEN", "test-token"):
            self.assertEqual(probe.gate_command_and_wait("TOUCH_37_10_20"), "touch=0")
        self.assertEqual(len(fake.calls), 3)

    def test_touch_rejects_negative_native_result(self):
        responses = [
            "CONTROL CJGUI_VERIFY/1\nKIND OK\nOP TOUCH_37_10_20\nPUBLISHED 2\nEND",
            "CONTROL CJGUI_VERIFY/1\nKIND OK\nOP GATE_STATE\nLAST_COMMAND 2\nRESULT_ID 2\nRESULT touch=-1\nEND",
        ]
        with patch.object(probe, "EXCHANGE", FakeExchange(responses)), \
                patch.object(probe, "TOKEN", "test-token"):
            with self.assertRaises(Exception):
                probe.gate_command_and_wait("TOUCH_37_10_20")

    def test_pixel_regions_require_positive_unoccluded_outside_node(self):
        rects, clips = geometry(out_height=0)
        with self.assertRaises(ValueError):
            probe.pixel_regions(rects, clips, (1320, 2856))
        rects, clips = geometry(next_box_y=700)
        with self.assertRaises(ValueError):
            probe.pixel_regions(rects, clips, (1320, 2856))
        rects, clips = geometry()
        regions = probe.pixel_regions(rects, clips, (1320, 2856))
        self.assertEqual(regions["cross_visible"], (52, 676, 452, 686))
        self.assertEqual(regions["cross_hidden"], (52, 686, 452, 716))
        self.assertEqual(regions["fully_out"], (52, 716, 452, 756))

    def test_screenshot_registration_finds_surface_translation(self):
        image = Image.new("RGB", (500, 160), (10, 20, 30))
        draw = ImageDraw.Draw(image)
        draw.rectangle((57, 27, 456, 76), fill=(77, 31, 31))
        draw.rectangle((57, 67, 456, 76), fill=(10, 209, 191))
        self.assertEqual(probe.register_scene_to_screenshot(
            image, (52, 20, 400, 50), (77, 31, 31)), (5, 7))

    def test_clipped_hit_point_requires_uncovered_negative_location(self):
        old_rects, old_clips = geometry(noclip_box_y=848)
        with self.assertRaises(ValueError):
            probe.tap_points(old_rects, old_clips)
        rects, clips = geometry()
        points = probe.tap_points(rects, clips)
        self.assertEqual(points["clip_visible"], (242, 809))
        self.assertEqual(points["clip_hidden"], (242, 849))

    def test_pixel_metrics_remain_inside_a_classified_check(self):
        evidence = []
        with patch.object(probe, "EVIDENCE", evidence):
            self.assertEqual(probe.check("visible pixels", True, True,
                                         details={"cross_visible_px": 100}), 0)
        self.assertEqual(len(evidence), 1)
        self.assertIs(evidence[0]["pass"], True)
        self.assertEqual(evidence[0]["details"]["cross_visible_px"], 100)

    def test_owner_snapshot_requires_count_as_well_as_version(self):
        response = ("PROTOCOL CJGUI_SHARED_OPERATION/2\nKIND SNAPSHOT\n"
                    "VERSION 3\nRESOURCE 9700 9 E8AEA1E695B0E599A8 1\n"
                    "FIELD 9700 count INTEGER 11\nWINDOW_PROJECTION NONE\nEND")
        self.assertEqual(probe.owner_state_of(response), {
            "version": 3, "count": 11, "window_projection": "NONE"})
        with self.assertRaises(AssertionError):
            probe.owner_state_of(response.replace("FIELD 9700 count INTEGER 11\n", ""))

    def test_geometry_log_uses_only_current_pid_and_last_batch(self):
        lines = (
            "09-27 18:00:00.000 123 77 I CjguiRenderer: node-rect id=1 x=0 y=0 w=100 h=100 clip=(0,0,100,100)\n"
            "09-27 18:00:00.000 123 77 I CjguiRenderer: node-rect id=43 x=1 y=2 w=3 h=0 clip=(1,2,3,0)\n"
            "09-27 18:00:01.000 999 77 I CjguiRenderer: node-rect id=43 x=1 y=2 w=3 h=99 clip=(1,2,3,99)\n"
            "09-27 18:00:02.000 123 77 I CjguiRenderer: node-rect id=1 x=0 y=0 w=100 h=100 clip=(0,0,100,100)\n"
            "09-27 18:00:02.000 123 77 I CjguiRenderer: node-rect id=43 x=1 y=2 w=3 h=40 clip=(1,2,3,0)\n")
        result = SimpleNamespace(returncode=0, stdout=lines, stderr="")
        with patch.object(probe.subprocess, "run", return_value=result):
            rects, clips = probe.node_rects_from_hilog("123")
        self.assertEqual(rects[43], (1.0, 2.0, 3.0, 40.0))
        self.assertEqual(clips[43], (1.0, 2.0, 3.0, 0.0))

    def test_failed_snapshot_cannot_reuse_an_old_local_image(self):
        with tempfile.TemporaryDirectory() as temp:
            old = Path(temp) / "d_screenshot_clip.jpeg"
            old.write_bytes(b"old screenshot")
            with patch.object(probe, "EVIDENCE_DIR", Path(temp)), \
                    patch.object(probe, "current_pid", return_value="12345"), \
                    patch.object(probe.subprocess, "run", return_value=SimpleNamespace(
                        returncode=1, stdout="", stderr="capture failed")):
                with self.assertRaises(RuntimeError):
                    probe.screenshot("clip", "12345")


if __name__ == "__main__":
    unittest.main()

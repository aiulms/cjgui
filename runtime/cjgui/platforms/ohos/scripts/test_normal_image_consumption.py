"""Offline contracts for the normal-HAP image evidence workflow."""

import sys
from dataclasses import dataclass
from pathlib import Path
import tempfile
import unittest
from types import SimpleNamespace
from unittest.mock import patch

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
import verify_normal_image_consumption as image_probe  # noqa: E402


class NormalImageEvidenceTests(unittest.TestCase):
    @staticmethod
    def claim_line(request_id: int, operation: str, *, pid: str = "4321",
                   instance: str = "ohos_transport_17", queue_us: int = 125) -> str:
        return (f"09-28 12:34:56.123 {pid} 99 I CjguiTransport: "
                f"transport-cost stage=owner-claim instance={instance} "
                f"requestId={request_id} op={operation} queueUs={queue_us}")

    def test_twenty_reads_require_exact_owner_claim_transcript(self) -> None:
        before = [self.claim_line(100, "OTHER")]
        batch = [self.claim_line(101 + index,
                 "GET_CONTEXT_0" if index % 2 == 0 else "GET_GENERATED_UI_INSTANCES",
                 queue_us=125 + index) for index in range(40)]
        attributed = image_probe.correlate_owner_claims(before, before + batch, "4321")
        self.assertEqual(len(attributed), 20)
        self.assertEqual([row["request_id"] for row in attributed],
                         list(range(101, 141, 2)))
        self.assertEqual([row["owner_queue_us"] for row in attributed],
                         [125 + index for index in range(0, 40, 2)])
        self.assertEqual(attributed[0]["instance"], "ohos_transport_17")

    def test_owner_claim_attribution_fails_closed(self) -> None:
        before = [self.claim_line(100, "OTHER")]
        batch = [self.claim_line(101 + index,
                 "GET_CONTEXT_0" if index % 2 == 0 else "GET_GENERATED_UI_INSTANCES")
                 for index in range(40)]
        cases = {
            "missing_claim": before + batch[:13] + batch[14:],
            "extra_client": before + batch[:12] + [self.claim_line(141, "OTHER")] + batch[12:],
            "request_gap": before + batch[:12] + [self.claim_line(155, "GET_CONTEXT_0")] + batch[13:],
            "wrong_operation": before + batch[:12] + [self.claim_line(113, "OTHER")] + batch[13:],
            "wrong_instance": before + batch[:12] + [self.claim_line(113, "GET_CONTEXT_0",
                                                              instance="ohos_transport_18")] + batch[13:],
            "wrong_pid": before + batch[:12] + [self.claim_line(113, "GET_CONTEXT_0",
                                                         pid="9999")] + batch[13:],
            "duplicate_claim": before + batch[:12] + [batch[12]] + batch[12:],
            "hilog_gap": before[:-1] + batch,
        }
        for reason, after in cases.items():
            with self.subTest(reason=reason), self.assertRaisesRegex(ValueError, "owner_claim_"):
                image_probe.correlate_owner_claims(before, after, "4321")

    def test_script_resolves_current_repo_and_host_source(self) -> None:
        script = Path(image_probe.__file__).resolve()
        self.assertTrue((script.parents[5] / "labs/ohos_cjgui_app").is_dir())
        self.assertTrue((script.parents[1] / "host/ohos_renderer.cpp").is_file())

    def test_candidates_keep_editor_and_use_registered_image_identity(self) -> None:
        empty = image_probe.candidate("settings", None)
        pictured = image_probe.candidate("settings", 2)
        self.assertIn("NODE 1 editor textInput field=name", empty)
        self.assertNotIn("NODE 1 icon image", empty)
        self.assertIn("PROPERTY 1 icon resource settings-beacon", pictured)
        self.assertIn("PROPERTY 1 icon resourceVersion 2", pictured)
        self.assertIn("PROPERTY 1 icon contentMode fill", pictured)
        self.assertNotIn("/data/", pictured)

    def test_clipped_candidate_keeps_editor_outside_real_scroll_parent(self) -> None:
        pictured = image_probe.candidate("settings", 2, clipped=True)
        self.assertIn("NODE 1 crop scrollArea", pictured)
        self.assertIn("PROPERTY 1 crop fixedWidth 100", pictured)
        self.assertIn("PROPERTY 1 crop fixedHeight 60", pictured)
        self.assertIn("NODE 2 canvas vertical", pictured)
        self.assertIn("NODE 3 icon image", pictured)
        self.assertIn("PROPERTY 3 icon resourceVersion 2", pictured)
        self.assertIn("NODE 1 editor textInput field=name", pictured)
        self.assertLess(pictured.index("NODE 3 icon image"),
                        pictured.index("NODE 1 editor textInput field=name"))

    def test_parent_clip_pixels_reject_unclipped_right_fringe(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            path = Path(temporary) / "clip.jpg"
            canvas = Image.new("RGB", (220, 120), (28, 32, 38))
            main, aux = image_probe.IMAGE["settings"][5][2]
            for y in range(10, 70):
                for x in range(20, 120):
                    canvas.putpixel((x, y), main if x < 65 else aux)
            canvas.save(path, quality=95)
            clipped = image_probe.inspect_parent_clip(
                path, (20, 10, 160, 72), (20, 10, 100, 60), "settings", 2)
            self.assertTrue(clipped["pass"])
            for y in range(20, 55):
                for x in range(130, 175):
                    canvas.putpixel((x, y), main)
            canvas.save(path, quality=95)
            leaking = image_probe.inspect_parent_clip(
                path, (20, 10, 160, 72), (20, 10, 100, 60), "settings", 2)
            self.assertFalse(leaking["pass"])

    def test_resize_requires_real_surface_bounds_and_geometry_epoch(self) -> None:
        before = SimpleNamespace(window_geometry_revision=10,
                                 window_accepted_scene_version=20, owner_pending_scene=False)
        after = SimpleNamespace(window_geometry_revision=7,
                                window_accepted_scene_version=21, owner_pending_scene=False)
        proof = image_probe.assess_resize(before, after, (0, 135, 1320, 1705),
                                          (0, 135, 792, 1705), target_ratio=0.6)
        self.assertTrue(proof["pass"])
        with self.assertRaises(ValueError):
            image_probe.assess_resize(before, before, (0, 135, 1320, 1705),
                                      (0, 135, 792, 1705), target_ratio=0.6)
        with self.assertRaises(ValueError):
            image_probe.assess_resize(before, after, (0, 135, 1320, 1705),
                                      (0, 135, 1320, 1705), target_ratio=0.6)

    def test_jpeg_tolerant_palette_and_fit_margins(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            path = Path(temporary) / "screen.jpg"
            canvas = Image.new("RGB", (240, 120), (246, 246, 246))
            # 160x72 handwritten fit: 120x72 content, 20px side margins.
            for x in range(60, 180):
                for y in range(20, 92):
                    canvas.putpixel((x, y), (17, 132, 173) if x < 125 else (102, 241, 235))
            canvas.save(path, quality=90)
            evidence = image_probe.inspect_palette(path, (40, 20, 160, 72),
                                                   "settings", 1, "fit")
            self.assertTrue(evidence["pass"])
            self.assertGreater(evidence["main_pixels"], 1000)
            self.assertGreater(evidence["side_margin_other_fraction"], 0.9)

    def test_stats_cannot_invent_uninstrumented_cost(self) -> None:
        record = image_probe.cost_record(None)
        self.assertEqual(record["read_micros"], "not_observed")
        self.assertEqual(record["in_flight_bytes"], "not_observed")
        self.assertEqual(record["decode_starts"], "not_observed")

    def test_context_request_timing_excludes_followup_image_state_read(self) -> None:
        clock = [1_000_000_000]
        before = [self.claim_line(100, "OTHER")]
        batch = [self.claim_line(101 + index,
                 "GET_CONTEXT_0" if index % 2 == 0 else "GET_GENERATED_UI_INSTANCES")
                 for index in range(40)]

        class Client:
            def get_context(self):
                clock[0] += 1_000_000
                return SimpleNamespace(kind="SNAPSHOT", raw="SNAPSHOT\nEND", entries=[])

        class Session:
            client = Client()

            def instances(self):
                clock[0] += 100_000_000
                return SimpleNamespace(instance=lambda key:
                    SimpleNamespace(resource_state="loading"))

        with tempfile.TemporaryDirectory() as temporary, \
                patch.object(image_probe.time, "perf_counter_ns", side_effect=lambda: clock[0]), \
                patch.object(image_probe.normal, "utc_now", side_effect=lambda: f"t{clock[0]}"), \
                patch.object(image_probe.normal, "parse_owner", return_value={"value": "x"}), \
                patch.object(image_probe, "_capture_owner_claims", side_effect=[before, before + batch]):
            rows = image_probe._twenty_contexts(Session(), "settings", Path(temporary),
                                               object(), "4321")

        self.assertEqual(len(rows), 20)
        self.assertEqual(rows[0]["public_request_ms"], 1.0)
        self.assertEqual(rows[0]["response_utc"], "t1001000000")
        self.assertEqual(rows[0]["accepted_image_state_at_read"], "loading")
        self.assertEqual(rows[0]["owner_queue_us"], 125)
        self.assertEqual(rows[0]["scene_accept_ms"], "not_applicable_read")

    def test_owner_action_timing_excludes_followup_owner_and_scene_reads(self) -> None:
        clock = [1_000_000_000]
        versions = iter((5, 6, 6, 7))
        values = iter((10, 10, 11, 11, 10, 10))

        @dataclass
        class Snapshot:
            owner_pending_scene: bool = False
            structure_candidate_pending: bool = False
            window_accepted_scene_version: int = 1

        class Session:
            def invoke_action(self, *args, **kwargs):
                clock[0] += 1_000_000
                return SimpleNamespace(kind="RESULT", raw="RESULT\nAPPLIED true\nEND",
                                       entries=[("APPLIED", ["true"])])

            def snapshot(self):
                clock[0] += 100_000_000
                return Snapshot()

        def owner(*args):
            clock[0] += 100_000_000
            return {"version": next(versions)}

        def business(*args):
            clock[0] += 100_000_000
            return next(values)

        with tempfile.TemporaryDirectory() as temporary, \
                patch.object(image_probe, "_owner", side_effect=owner), \
                patch.object(image_probe, "_business_number", side_effect=business), \
                patch.object(image_probe.time, "perf_counter_ns", side_effect=lambda: clock[0]), \
                patch.object(image_probe.normal, "utc_now", side_effect=lambda: f"t{clock[0]}"):
            rows = image_probe._write_actions(Session(), "settings", Path(temporary))
        self.assertEqual([row["public_request_ms"] for row in rows], [1.0, 1.0])
        self.assertEqual(rows[0]["response_utc"], "t1301000000")

    def test_normal_hilog_frame_counters_are_deltas_not_tcp_time(self) -> None:
        before = image_probe.parse_cost_snapshot([
            "image-cost stage=frame starts=1 encoded=912 readUs=300 decodeUs=900 hits=0",
            "image-cost stage=frame resident=61440 idle=0 activeBytes=0 peakActiveBytes=61440 "
            "reservations=0 peakTracked=61440 running=0 queued=0 bitmapCreates=1 "
            "bitmapDestroys=0 bitmapCreateUs=35 bitmapDestroyUs=0",
        ])
        after = image_probe.parse_cost_snapshot([
            "image-cost stage=frame starts=2 encoded=1824 readUs=620 decodeUs=1810 hits=1",
            "image-cost stage=frame resident=122880 idle=61440 activeBytes=0 peakActiveBytes=122880 "
            "reservations=0 peakTracked=122880 running=0 queued=0 bitmapCreates=2 "
            "bitmapDestroys=0 bitmapCreateUs=74 bitmapDestroyUs=0",
        ])
        record = image_probe.phase_cost(before, after)
        self.assertEqual(record["decode_starts"], 1)
        self.assertEqual(record["read_micros"], 320)
        self.assertEqual(record["cache_hits"], 1)
        self.assertEqual(record["resident_bytes"], 122880)
        self.assertEqual(record["owner_queue_micros"], "not_observed")
        self.assertIsNone(image_probe.parse_cost_snapshot([
            "image-cost stage=frame starts=2 encoded=1824 readUs=620 decodeUs=1810 hits=1",
        ]))

    def test_startup_cold_cost_is_first_real_decode_before_public_candidates(self) -> None:
        lines = [
            "image-cost stage=decode entry=1 version=1 encoded=511 readUs=48 "
            "decodeUs=768 owned=61440 ok=1 resident=61440",
            "image-cost stage=bitmap-create entry=1 version=1 us=4 resident=61440",
            "image-cost stage=frame starts=1 encoded=511 readUs=48 decodeUs=768 hits=0",
            "image-cost stage=frame resident=61440 idle=0 activeBytes=0 peakActiveBytes=61951 "
            "reservations=0 peakTracked=37748736 running=0 queued=0 bitmapCreates=1 "
            "bitmapDestroys=0 bitmapCreateUs=4 bitmapDestroyUs=0",
            "image-cost stage=frame starts=2 encoded=1024 readUs=71 decodeUs=1074 hits=3",
            "image-cost stage=frame resident=122880 idle=0 activeBytes=0 peakActiveBytes=61953 "
            "reservations=0 peakTracked=37810176 running=0 queued=0 bitmapCreates=2 "
            "bitmapDestroys=0 bitmapCreateUs=7 bitmapDestroyUs=0",
        ]
        cold = image_probe.startup_cold_cost(lines, "settings")
        self.assertEqual(cold["status"], "observed")
        self.assertEqual(cold["decode_starts"], 1)
        self.assertEqual(cold["encoded_read_bytes"], 511)
        self.assertEqual(cold["bitmap_creates"], 1)
        self.assertEqual(cold["cache_hits"], 0)
        self.assertEqual(image_probe.startup_cold_cost(lines[2:], "settings")["status"],
                         "not_observed")

    def test_startup_bitmap_can_be_realized_after_first_decode_frame(self) -> None:
        lines = [
            "image-cost stage=decode entry=1 version=1 encoded=509 readUs=72 "
            "decodeUs=2671 owned=61440 ok=1 resident=61440",
            "image-cost stage=frame starts=1 encoded=509 readUs=72 decodeUs=2671 hits=0",
            "image-cost stage=frame resident=61440 idle=0 activeBytes=0 peakActiveBytes=61949 "
            "reservations=37748736 peakTracked=37748736 running=0 queued=0 "
            "bitmapCreates=0 bitmapDestroys=0 bitmapCreateUs=0 bitmapDestroyUs=0",
            "image-cost stage=bitmap-create entry=1 version=1 us=3 ok=1 resident=61440",
            "image-cost stage=frame starts=1 encoded=509 readUs=72 decodeUs=2671 hits=1",
            "image-cost stage=frame resident=61440 idle=0 activeBytes=0 peakActiveBytes=61949 "
            "reservations=0 peakTracked=37748736 running=0 queued=0 "
            "bitmapCreates=1 bitmapDestroys=0 bitmapCreateUs=3 bitmapDestroyUs=0",
        ]
        cold = image_probe.startup_cold_cost(lines, "thermo")
        self.assertEqual(cold["status"], "observed")
        self.assertEqual(cold["decode_starts"], 1)
        self.assertEqual(cold["encoded_read_bytes"], 509)
        self.assertEqual(cold["bitmap_creates"], 1)
        self.assertEqual(cold["bitmap_create_micros"], 3)
        self.assertEqual(cold["cache_hits"], 1)
        self.assertEqual(image_probe.startup_cold_cost(lines[:3], "thermo")["status"],
                         "not_observed")

    def test_cost_capture_filters_other_hilog_before_text_decoding(self) -> None:
        class Hdc:
            def shell(self, command, *, timeout):
                self_command = command
                self_timeout = timeout
                assert "grep -a 'image-cost stage='" in self_command
                assert self_timeout == 45
                return (
                    "09-28 01:20:56.028 21968 11497 I A00000/CjguiRenderer: "
                    "image-cost stage=frame starts=1 encoded=509 readUs=72 decodeUs=2671 hits=0\n"
                    "09-28 01:20:56.028 21968 11497 I A00000/CjguiRenderer: "
                    "image-cost stage=frame resident=61440 idle=0 activeBytes=0 "
                    "peakActiveBytes=61949 reservations=0 peakTracked=37748736 "
                    "running=0 queued=0 bitmapCreates=1 bitmapDestroys=0 "
                    "bitmapCreateUs=3 bitmapDestroyUs=0\n"
                )

        with tempfile.TemporaryDirectory() as temporary:
            snapshot, rows = image_probe._capture_cost(
                Hdc(), Path(temporary), "baseline", "21968")
            self.assertEqual(len(rows), 2)
            self.assertEqual(snapshot["bitmapCreates"], 1)


if __name__ == "__main__":
    unittest.main()

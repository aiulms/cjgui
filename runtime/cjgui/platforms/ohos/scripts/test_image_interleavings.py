"""Offline guards for the controlled native image timing probe."""

from pathlib import Path
import hashlib
import sys
import tempfile
import unittest
from types import SimpleNamespace

sys.path.insert(0, str(Path(__file__).resolve().parent))
import verify_image_interleavings as probe  # noqa: E402


class ImageInterleavingTests(unittest.TestCase):
    def test_new_lifecycle_marker_survives_hilog_ring_rollover_without_borrowing(self) -> None:
        before = ["old launch", "09-28 00:01:00.000 15526 15526 I A00000/CjguiApp: "
                  "verify stop host requested from UI"]
        after = ["09-28 01:00:32.395 15526 15526 I A00000/CjguiApp: "
                 "verify stop host requested from UI", "same-instance full-zero settlement"]
        self.assertEqual(probe.new_lifecycle_marker_tail(
            before, after, "verify stop host requested from UI"), after)
        with self.assertRaises(AssertionError):
            probe.new_lifecycle_marker_tail(after, after,
                                            "verify stop host requested from UI")
        with self.assertRaises(AssertionError):
            probe.new_lifecycle_marker_tail(before, after + [after[0]],
                                            "verify stop host requested from UI")

    def test_native_rejection_requires_native_reason_and_unchanged_owner(self) -> None:
        before = SimpleNamespace(version=7)
        after = SimpleNamespace(version=7)
        ticket = SimpleNamespace(terminal_state="REJECTED", reason="unknown_field")
        owner_before = {"version": 3, "value": "old"}
        owner_after = {"version": 4, "value": "changed"}
        # The old verifier accepted this terminal and unchanged structure.
        self.assertTrue(ticket.terminal_state == "REJECTED" and
                        after.version == before.version)
        self.assertTrue(hasattr(probe, "require_native_image_rejection"),
                        "native rejection must have a stronger production check")
        with self.assertRaises(ValueError):
            probe.require_native_image_rejection(ticket, before, after,
                                                 owner_before, owner_after)
        ticket.reason = "layout_or_native"
        with self.assertRaises(ValueError):
            probe.require_native_image_rejection(ticket, before, after,
                                                 owner_before, owner_after)
        self.assertEqual(probe.require_native_image_rejection(
            ticket, before, after, owner_before, owner_before), "layout_or_native")

    def test_held_release_requires_a_waiting_entry_and_a_terminal_transition(self) -> None:
        before = {"awaiting": 0, "bitmapCreates": 4, "staleDiscards": 2}
        after = {"awaiting": 0, "bitmapCreates": 4, "staleDiscards": 2}
        self.assertEqual(after["awaiting"], 0)  # Old verifier's only release check.
        self.assertTrue(hasattr(probe, "require_held_image_completion"))
        with self.assertRaises(ValueError):
            probe.require_held_image_completion(before, after)
        before["awaiting"] = 1
        with self.assertRaises(ValueError):
            probe.require_held_image_completion(before, after)
        after["staleDiscards"] = 3
        self.assertEqual(probe.require_held_image_completion(before, after),
                         "stale_discarded")
        after["staleDiscards"] = 2
        after["bitmapCreates"] = 5
        self.assertEqual(probe.require_held_image_completion(before, after),
                         "bitmap_realized")

    def test_stats_requires_all_native_slots(self) -> None:
        body = ("image_stats_rc=0 decodeStarts=2 encodedReadBytes=1024 decodeMicros=30 "
                "cacheHits=1 inFlight=0 queued=0 awaiting=1 readyRecords=1 "
                "residentBytes=61440 bitmapCreates=1 bitmapDestroys=0 staleDiscards=0")
        parsed = probe.parse_stats(body)
        self.assertEqual(parsed["awaiting"], 1)
        with self.assertRaises(ValueError):
            probe.parse_stats("image_stats_rc=0 decodeStarts=2")

    def test_two_nodes_keep_one_logical_resource(self) -> None:
        payload = probe.image_candidate(2, nodes=2)
        self.assertIn("NODE 1 icon image", payload)
        self.assertIn("NODE 1 icon2 image", payload)
        self.assertEqual(payload.count("resource settings-beacon"), 2)
        self.assertNotIn("/data/", payload)

    def test_two_ready_nodes_do_not_prove_decode_or_bitmap_reuse_by_themselves(self) -> None:
        before = {"decodeStarts": 2, "bitmapCreates": 2, "residentBytes": 61440}
        two = {"decodeStarts": 3, "bitmapCreates": 3, "residentBytes": 122880}
        one = dict(two)
        self.assertGreater(one["residentBytes"], 0)  # Old runtime assertion.
        self.assertTrue(hasattr(probe, "require_shared_image_reuse"))
        with self.assertRaises(ValueError):
            probe.require_shared_image_reuse(before, two, one)
        two = {"decodeStarts": 2, "bitmapCreates": 2, "residentBytes": 61440}
        one = dict(two)
        self.assertEqual(probe.require_shared_image_reuse(before, two, one),
                         {"decodeStarts": 2, "bitmapCreates": 2,
                          "residentBytes": 61440})

    def test_removed_nodes_allow_bounded_idle_cache_but_no_unsettled_work(self) -> None:
        stats = {"inFlight": 0, "queued": 1, "awaiting": 0, "readyRecords": 2,
                 "residentBytes": 16 * 1024 * 1024 + 61440,
                 "bitmapCreates": 2, "bitmapDestroys": 1}
        ext = {"decoderActiveBytes": 0, "reservationBytes": 0,
               "peakTrackedBytes": 18 * 1024 * 1024,
               "idleCacheBytes": 16 * 1024 * 1024}
        self.assertGreater(stats["residentBytes"], 0)  # Old removal check.
        self.assertTrue(hasattr(probe, "require_bounded_image_idle"))
        with self.assertRaises(ValueError):
            probe.require_bounded_image_idle(stats, ext)
        stats["queued"] = 0
        self.assertEqual(probe.require_bounded_image_idle(stats, ext)["idleCacheBytes"],
                         16 * 1024 * 1024)
        ext["idleCacheBytes"] += 1
        with self.assertRaises(ValueError):
            probe.require_bounded_image_idle(stats, ext)

    def test_idle_wait_observes_real_queue_drain_before_returning(self) -> None:
        settled = {"inFlight": 0, "queued": 0, "awaiting": 0, "readyRecords": 1,
                   "residentBytes": 61440, "bitmapCreates": 1, "bitmapDestroys": 0}
        ext = {"decoderActiveBytes": 0, "reservationBytes": 0,
               "peakTrackedBytes": 61440, "idleCacheBytes": 61440}

        class Gate:
            reads = 0

            def stats(self):
                self.reads += 1
                return {**settled, "queued": 1} if self.reads == 1 else settled

            def stats_ext(self):
                return ext

        gate = Gate()
        self.assertTrue(hasattr(probe, "wait_for_bounded_image_idle"))
        proof = probe.wait_for_bounded_image_idle(gate, timeout=1.0)
        self.assertEqual(gate.reads, 2)
        self.assertEqual(proof["idleCacheBytes"], 61440)

    def test_stop_requires_bitmap_release_and_bounded_decoder_tail(self) -> None:
        lines = [
            "09-27 12:00:01.000 321 322 I A00000/CjguiRenderer: "
            "image-cost stage=stop starts=2 encoded=1024 readUs=10 decodeUs=20 hits=1",
            "09-27 12:00:01.001 321 322 I A00000/CjguiRenderer: "
            "image-cost stage=stop resident=61440 idle=61440 activeBytes=0 "
            "peakActiveBytes=61440 reservations=0 peakTracked=61440 "
            "running=0 queued=0 bitmapCreates=2 bitmapDestroys=1 "
            "bitmapCreateUs=20 bitmapDestroyUs=10",
        ]
        self.assertTrue(hasattr(probe, "parse_stop_image_snapshot"))
        self.assertTrue(hasattr(probe, "require_bounded_stop_image"))
        stopped = probe.parse_stop_image_snapshot(lines)
        # Generic owner/Surface zero settlement did not inspect image bitmaps.
        with self.assertRaises(ValueError):
            probe.require_bounded_stop_image(stopped)
        stopped["bitmapDestroys"] = 2
        self.assertEqual(probe.require_bounded_stop_image(stopped)["idle"], 61440)
        stopped["queued"] = 1
        with self.assertRaises(ValueError):
            probe.require_bounded_stop_image(stopped)

    def test_stop_log_boundary_ignores_reordered_system_rows(self) -> None:
        app_before = "09-27 12:00:00.000 321 322 I A00000/CjguiHost: startHost accepted: appInstance=1"
        app_after = "09-27 12:00:01.000 321 322 I A00000/CjguiRenderer: image-cost stage=stop"
        system_a = "09-27 12:00:00.100 321 322 I A00000/Accessibility: refresh"
        system_b = "09-27 12:00:00.200 321 322 I A00000/ArkUI: layout"

        class Hdc:
            def __init__(self):
                self.rows = [app_before, system_a, system_b]

            def shell(self, command):
                self.assert_command = command
                return "\n".join(self.rows)

        hdc = Hdc()
        baseline = probe.stable_app_hilog(hdc, "321")
        hdc.rows = [system_b, app_before, system_a, app_after]
        after = probe.stable_app_hilog(hdc, "321")
        self.assertEqual(probe.restart.tail_since(baseline, after), [app_after])

    def test_test_hap_identity_requires_exact_variant_digest_and_pid(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            hap = Path(temporary) / "entry.hap"
            hap.write_bytes(b"test-hap")
            digest = hashlib.sha256(hap.read_bytes()).hexdigest()
            identity = (f"target=127.0.0.1:5555\npid=321\nhap_sha256={digest}\n"
                        "build_variant=verify-transport+test-gates\n")
            self.assertEqual(probe.test_hap_identity(identity, "127.0.0.1:5555",
                                                     "321", hap), digest)
            with self.assertRaises(ValueError):
                probe.test_hap_identity(identity.replace("test-gates", "normal"),
                                        "127.0.0.1:5555", "321", hap)
            with self.assertRaises(ValueError):
                probe.test_hap_identity(identity, "127.0.0.1:5555", "322", hap)


if __name__ == "__main__":
    unittest.main()

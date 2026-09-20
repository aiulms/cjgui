#!/usr/bin/env python3
"""Contract test for the complex-scene performance report.

This test is deliberately independent of the Cangjie target.  It proves the
report cannot silently omit stage samples or the explicit observability
boundary for stages not exported by the normal window projection.
"""

from __future__ import annotations

import json
import importlib
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parent
PROBE = ROOT / "complex_scene_performance_probe.py"
probe = importlib.import_module("complex_scene_performance_probe")


class ComplexScenePerformanceContractTest(unittest.TestCase):
    def test_contract_fixture_contains_stage_samples_and_boundaries(self) -> None:
        with tempfile.TemporaryDirectory(prefix="cjgui-complex-scene-contract-") as directory:
            report_path = Path(directory) / "report.json"
            completed = subprocess.run(
                [sys.executable, str(PROBE), "--contract-fixture", "--output", str(report_path)],
                cwd=ROOT,
                text=True,
                capture_output=True,
                check=False,
            )
            self.assertEqual(0, completed.returncode, completed.stderr)
            report = json.loads(report_path.read_text(encoding="utf-8"))
            self.assertEqual("cjgui_complex_scene_performance_v1", report["schema"])
            stages = report["stage_samples_ns"]
            self.assertEqual(
                {
                    "build",
                    "identity_reference",
                    "candidate_clone",
                    "layout",
                    "measure",
                    "native_staging_submission",
                },
                set(stages),
            )
            self.assertGreaterEqual(stages["build"]["valid_samples"], 30)
            self.assertEqual("not_exposed_by_normal_public_projection", stages["identity_reference"]["observability"])
            self.assertEqual("not_exposed_by_normal_public_projection", stages["candidate_clone"]["observability"])
            self.assertIn("source_fingerprint", report)
            self.assertIn("binary_fingerprint", report)

    def test_ms_projection_never_becomes_internal_ns(self) -> None:
        timings, metadata = probe.parse_timing({"WINDOW_WORK_TIMING_MS": "1 2 3 4"})
        self.assertEqual({}, timings)
        self.assertEqual("app_ms_projection", metadata["precision"])
        self.assertEqual(1, metadata["resolution_ms"])
        sample = probe.cycle_sample(
            {"name": "ms-only", "window_progress_from_read_only_get": {"WINDOW_WORK_TIMING_MS": "1 2 3 4"}},
            123,
        )
        self.assertEqual({}, sample["timing"])
        projection = probe.projection_ms([sample])
        self.assertEqual(0, probe.stage_samples([sample])["build"]["valid_samples"])
        self.assertEqual(1, projection["build"]["valid_samples"])
        self.assertEqual(1, projection["build"]["p50_ms"])
        self.assertEqual(1, projection["build"]["resolution_ms"])

    def test_incomplete_or_mixed_ns_fields_do_not_partially_fill(self) -> None:
        incomplete = {"WINDOW_WORK_TIMING_NS": "build_ns=10 layout_ns=20"}
        timings, metadata = probe.parse_timing(incomplete)
        self.assertEqual({}, timings)
        self.assertEqual("incomplete_ns_field_shape", metadata["reason"])
        mixed = {"WINDOW_WORK_TIMING_NS": "build_ns=10 layout_ns=20", "WINDOW_WORK_TIMING_MS": "1 2 3 4"}
        timings, metadata = probe.parse_timing(mixed)
        self.assertEqual({}, timings)
        self.assertEqual("incomplete_ns_field_shape", metadata["reason"])


if __name__ == "__main__":
    unittest.main()

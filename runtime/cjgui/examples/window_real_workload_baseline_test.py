#!/usr/bin/env python3
"""Small real-bundle regression for the baseline's authorized business load."""

from __future__ import annotations

import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parent
RUNNER = ROOT / "window_perf_baseline.py"


class RealWindowWorkloadBaselineTest(unittest.TestCase):
    def test_runs_versioned_rule_batch_and_document_edit_with_frame_progress(self) -> None:
        with tempfile.TemporaryDirectory(prefix="cjgui-window-workload-test-") as temporary:
            report_path = Path(temporary) / "report.json"
            completed = subprocess.run(
                [
                    sys.executable,
                    str(RUNNER),
                    "--duration-seconds",
                    "2",
                    "--warmup-seconds",
                    "0",
                    "--sample-seconds",
                    "0.2",
                    "--fixture-record-count",
                    "3",
                    "--cycles",
                    "rule_set_fixture_batch,rule_set_fixture_batch_idle_recovery,document_edit",
                    "--output",
                    str(report_path),
                ],
                cwd=ROOT,
                text=True,
                capture_output=True,
                timeout=30,
                check=False,
            )
            self.assertEqual(0, completed.returncode, completed.stderr)
            report = json.loads(report_path.read_text(encoding="utf-8"))
            cycles = {cycle["name"]: cycle for cycle in report["cycles"]}
            self.assertEqual(
                {"rule_set_fixture_batch", "rule_set_fixture_batch_idle_recovery", "document_edit"},
                set(cycles),
            )
            rule_workload = cycles["rule_set_fixture_batch"]["business_workload"]
            self.assertEqual(3, rule_workload["fixture_record_count"])
            self.assertTrue(rule_workload["batch_applied"])
            self.assertTrue(rule_workload["stale_version_conflict"])
            self.assertTrue(rule_workload["readback_all_enabled"])
            self.assertTrue(rule_workload["sparse_target_change_applied"])
            self.assertTrue(rule_workload["sparse_target_readback_disabled"])
            self.assertGreater(rule_workload["frame_progress_after_work"], rule_workload["frame_progress_before_work"])
            self.assertLessEqual(cycles["rule_set_fixture_batch"]["public_get_latency_ms"]["count"], 25)
            rule_recovery = cycles["rule_set_fixture_batch"]["business_recovery"]
            self.assertGreater(rule_recovery["sample_count"], 0)
            self.assertGreater(rule_recovery["post_work_observed_s"], 0)
            quiet_cycle = cycles["rule_set_fixture_batch_idle_recovery"]
            self.assertEqual(0, quiet_cycle["public_get_latency_ms"]["count"])
            self.assertEqual({}, quiet_cycle["public_get_outcomes"])
            self.assertTrue(quiet_cycle["business_workload"]["batch_applied"])
            self.assertGreater(quiet_cycle["business_recovery"]["sample_count"], 0)
            document_workload = cycles["document_edit"]["business_workload"]
            self.assertTrue(document_workload["replace_applied"])
            self.assertTrue(document_workload["stale_version_conflict"])
            self.assertTrue(document_workload["range_readback_matches"])
            self.assertGreater(document_workload["frame_progress_after_work"], document_workload["frame_progress_before_work"])
            document_recovery = cycles["document_edit"]["business_recovery"]
            self.assertGreater(document_recovery["sample_count"], 0)
            self.assertGreater(document_recovery["post_work_observed_s"], 0)


if __name__ == "__main__":
    unittest.main()

#!/usr/bin/env python3
"""Regression test for the scale report's current-run evidence envelope."""

from __future__ import annotations

import hashlib
import json
import subprocess
import sys
import unittest
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent
REPORTER = SCRIPT_DIR / "scene_submission_scale_report.py"


class SceneSubmissionScaleReportTest(unittest.TestCase):
    def test_current_run_evidence_is_complete_and_self_consistent(self) -> None:
        completed = subprocess.run([sys.executable, str(REPORTER)], cwd=SCRIPT_DIR.parents[2], text=True,
                                   capture_output=True, check=False)
        self.assertEqual(completed.returncode, 0, completed.stderr)
        report = json.loads(completed.stdout)
        self.assertEqual(report["runner_exit"], 0)
        self.assertTrue(report["completed_marker"])
        self.assertIn("evidence", report)
        evidence = report.get("evidence", {})
        self.assertEqual(evidence["source_sha256_before"], evidence["source_sha256_after"])
        self.assertEqual(report["source_sha256"], evidence["source_sha256_after"])
        raw_log = Path(evidence["raw_log"])
        binary = Path(evidence["binary"])
        self.assertTrue(raw_log.is_file())
        self.assertTrue(binary.is_file())
        self.assertIn("cjgui scene submission scale probe: passed", raw_log.read_text())
        self.assertEqual(evidence["binary_sha256"], hashlib.sha256(binary.read_bytes()).hexdigest())
        coverage = report["coverage"]
        self.assertEqual(coverage["expected_groups"], 15)
        self.assertEqual(coverage["actual_groups"], 15)
        self.assertTrue(coverage["all_groups_have_30_samples"])
        self.assertTrue(coverage["idle_complete"])
        self.assertTrue(coverage["recovery_complete"])


if __name__ == "__main__":
    unittest.main()

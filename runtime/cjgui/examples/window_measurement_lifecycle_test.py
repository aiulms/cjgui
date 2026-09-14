#!/usr/bin/env python3
"""Normal bundle contract for comparable window-baseline lifecycle markers."""

from __future__ import annotations

import subprocess
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parent
RULE = ROOT / "rule_set_window_app" / "target" / "release" / "CJGUIRuleSet.app" / "Contents" / "MacOS" / "CJGUIRuleSet"
DOCUMENT = ROOT / "shared_document_window_app" / "target" / "release" / "CJGUISharedDocument.app" / "Contents" / "MacOS" / "CJGUISharedDocument"


class NormalWindowMeasurementLifecycleTest(unittest.TestCase):
    def assert_lifecycle(self, executable: Path, marker: str, extra_args: list[str]) -> None:
        self.assertTrue(executable.is_file(), f"bundle is unavailable: {executable}")
        completed = subprocess.run(
            [
                str(executable),
                *extra_args,
                "--measurement-warmup-ms",
                "25",
                "--measurement-duration-ms",
                "250",
            ],
            cwd=executable.parent,
            text=True,
            capture_output=True,
            timeout=10,
            check=False,
        )
        self.assertEqual(0, completed.returncode, completed.stderr)
        lines = completed.stdout.splitlines()
        ready = next((line for line in lines if line.startswith(f"{marker} WINDOW_READY ")), None)
        self.assertIsNotNone(ready, completed.stdout)
        assert ready is not None
        parts = ready.split(" ")
        self.assertEqual(4, len(parts), ready)
        self.assertGreater(int(parts[3]), 0, ready)
        self.assertIn(f"{marker} MEASUREMENT_START {parts[2]}", lines)

    def test_document_no_connection_has_normal_window_ready_and_warmup(self) -> None:
        self.assert_lifecycle(DOCUMENT, "CJGUI_SHARED_DOCUMENT_READY", [])

    def test_document_connection_has_normal_window_ready_and_warmup(self) -> None:
        self.assert_lifecycle(DOCUMENT, "CJGUI_SHARED_DOCUMENT_READY", ["--with-connection"])

    def test_rule_set_has_normal_window_ready_and_warmup(self) -> None:
        self.assert_lifecycle(RULE, "CJGUI_RULE_SET_READY", [])


if __name__ == "__main__":
    unittest.main()

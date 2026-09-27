#!/usr/bin/env python3
"""Regression: a real surface may have used platform calls before stub checks."""

import os
from pathlib import Path
import sys
import tempfile
import unittest

os.environ.setdefault("CJGUI_OHOS_VERIFICATION_DIR", tempfile.mkdtemp(prefix="cjgui-lifecycle-unit-"))
sys.path.insert(0, str(Path(__file__).resolve().parent))

from verify_surface_lifecycle_probe import platform_call_triplet_unchanged  # noqa: E402


def packed(create: int, flush: int, destroy: int) -> int:
    return create | (flush << 32) | (destroy << 48)


class PlatformCallBaselineTest(unittest.TestCase):
    def test_existing_real_calls_do_not_fail_stub_isolation(self):
        before = packed(5, 6, 5)
        self.assertTrue(platform_call_triplet_unchanged(before, before))

    def test_new_real_call_during_stub_session_fails(self):
        before = packed(5, 6, 5)
        self.assertFalse(platform_call_triplet_unchanged(before, packed(6, 6, 5)))
        self.assertFalse(platform_call_triplet_unchanged(before, packed(5, 7, 5)))
        self.assertFalse(platform_call_triplet_unchanged(before, packed(5, 6, 6)))


if __name__ == "__main__":
    unittest.main()

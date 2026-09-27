#!/usr/bin/env python3
"""Exercise the actual build-and-run startup classifier with ordered logs."""

from pathlib import Path
import subprocess
import tempfile
import unittest


SCRIPT = Path(__file__).with_name("build_and_run.sh")


class StartupAssertionTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        source = SCRIPT.read_text()
        start = source.index("assert_started() {")
        end = source.index("\n}\n", start) + 2
        cls.function = source[start:end]
        variant_start = source.index("assert_variant() {")
        variant_end = source.index("\n}\n", variant_start) + 2
        cls.variant_function = source[variant_start:variant_end]

    def check_log(self, lines: str) -> subprocess.CompletedProcess[str]:
        with tempfile.NamedTemporaryFile(mode="w", encoding="utf-8") as log:
            log.write(lines)
            log.flush()
            return subprocess.run(
                ["bash", "-c", self.function + '\nassert_started "$1" "$2"',
                 "assert-started", log.name, "12631"],
                capture_output=True, text=True,
            )

    def test_real_surface_supersedes_initial_waiting_phase(self):
        result = self.check_log(
            "09-27 17:39:59 12631 12813 I CjguiApp: stand-in serving: surface not published (KnownShimNoRef)\n"
            "09-27 17:39:59 12631 12631 I CjguiHost: ref capability decided: capability=VerifiedNativeRef\n"
            "09-27 17:39:59 12631 12631 I CjguiHost: surface created published=1\n"
            "09-27 17:39:59 12631 12816 I CjguiRenderer: present frame ok\n"
            "09-27 17:39:59 12631 12813 I CjguiApp: host started; pumping turns\n"
            "09-27 17:39:59 12631 12813 I CjguiApp: app_main_cangjie: ingress registered\n"
        )
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("场景提交", result.stdout)

    def test_waiting_phase_alone_does_not_pass(self):
        result = self.check_log(
            "09-27 17:39:59 12631 12813 I CjguiApp: surface pending; owner service active\n"
            "09-27 17:39:59 12631 12813 I CjguiApp: app_main_cangjie: ingress registered\n"
        )
        self.assertNotEqual(result.returncode, 0)

    def test_confirmed_known_shim_still_serves_owner(self):
        result = self.check_log(
            "09-27 17:39:59 12631 12813 I CjguiApp: surface pending; owner service active\n"
            "09-27 17:39:59 12631 12631 I CjguiHost: ref capability decided: capability=KnownShimNoRef\n"
            "09-27 17:39:59 12631 12631 I CjguiHost: surface created published=0\n"
            "09-27 17:39:59 12631 12813 I CjguiApp: app_main_cangjie: ingress registered\n"
        )
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_test_gate_accepts_confirmed_no_surface_without_flush(self):
        with tempfile.NamedTemporaryFile(mode="w", encoding="utf-8") as log:
            log.write(
                "ref capability decided: capability=KnownShimNoRef\n"
                "surface created published=0\n"
                "surface pending; owner service active\n"
                "transport verify seam: absent (normal product)\n"
                "test gate set request ms=4000 count=1 rc=0\n"
            )
            log.flush()
            result = subprocess.run(
                ["bash", "-c", "BUILD_VARIANT=test-gates\n" +
                 self.variant_function + '\nassert_variant "$1"',
                 "assert-variant", log.name],
                capture_output=True, text=True,
            )
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)


if __name__ == "__main__":
    unittest.main()

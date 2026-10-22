"""Real clang/ar routing checks; tiny sources keep archive isolation inexpensive."""
from pathlib import Path
import hashlib
import os
import shutil
import subprocess
import tempfile
import unittest


RUNTIME = Path(__file__).resolve().parents[2]


class NativeSidecarModesTest(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory(prefix="cjgui-native-modes-")
        self.addCleanup(temporary.cleanup)
        self.native = Path(temporary.name) / "runtime/native"
        (self.native / "scripts").mkdir(parents=True)
        self.builder = self.native / "scripts/build_cjgui_internal_renderer_sidecar.sh"
        shutil.copy2(RUNTIME / "native/scripts" / self.builder.name, self.builder)
        stems = ("cjgui_internal_renderer", "cjgui_native_bridge",
                 "cjgui_async_multiline_measure", "cjgui_async_multiline_bridge")
        for index, stem in enumerate(stems):
            (self.native / (stem + ".m")).write_text(f"int fixture_{index}(void) {{ return {index}; }}\n")
        with (self.native / "cjgui_internal_renderer.m").open("a") as source:
            source.write("#ifdef CJGUI_INTERNAL_TESTING\nint cjgui_fixture_test_hook(void) { return 1; }\n#endif\n")
        for name in ("cjgui_internal_renderer.h", "cjgui_native_bridge.h",
                     "cjgui_async_multiline_measure.h", "cjgui_composable_font_snapshot.h"):
            (self.native / name).write_text("/* fixture header */\n")
        self.env = dict(os.environ)
        self.env.pop("CJGUI_NATIVE_CLANG_FLAGS_APPEND", None)
        self.env["CJ_GUI_SDKROOT"] = subprocess.check_output(
            ["xcrun", "--sdk", "macosx", "--show-sdk-path"], text=True).strip()

    def build(self, *arguments, testing_flag=False):
        env = dict(self.env)
        if testing_flag:
            env["CJGUI_NATIVE_CLANG_FLAGS_APPEND"] = "-DCJGUI_INTERNAL_TESTING"
        return subprocess.run(["zsh", str(self.builder), *arguments],
                              env=env, capture_output=True, text=True)

    def test_testing_and_production_archives_survive_each_other(self):
        normal = self.native / "lib/libcjgui_internal_renderer.a"
        testing = self.native / "testing/lib/libcjgui_internal_renderer.a"
        result = self.build()
        self.assertEqual(result.returncode, 0, result.stderr)
        normal_bytes = normal.read_bytes()
        result = self.build("--testing", testing_flag=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(normal.read_bytes(), normal_bytes, "testing overwrote the production archive")
        self.assertTrue(testing.is_file(), "testing mode must have its own archive")
        testing_bytes = testing.read_bytes()
        self.assertIn("_cjgui_fixture_test_hook", subprocess.check_output(["nm", "-gU", str(testing)], text=True))
        self.assertNotIn("_cjgui_fixture_test_hook", subprocess.check_output(["nm", "-gU", str(normal)], text=True))
        result = self.build()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(testing.read_bytes(), testing_bytes)
        self.assertEqual(hashlib.sha256(normal.read_bytes()).digest(), hashlib.sha256(normal_bytes).digest())

    def test_accidental_testing_flag_cannot_replace_production(self):
        self.assertEqual(self.build().returncode, 0)
        normal = self.native / "lib/libcjgui_internal_renderer.a"
        before = normal.read_bytes()
        result = self.build(testing_flag=True)
        self.assertEqual(result.returncode, 2, "testing macro without --testing must be rejected")
        self.assertEqual(normal.read_bytes(), before)


if __name__ == "__main__":
    unittest.main()

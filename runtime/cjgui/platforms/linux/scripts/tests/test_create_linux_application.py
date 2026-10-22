"""The Linux creator transports paths as data and copies no build products."""
from pathlib import Path
import os
import shutil
import subprocess
import tempfile
import tomllib
import unittest


class CreateLinuxApplicationTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="CJGUI Linux create with spaces ")
        self.root = Path(self.temp.name)
        self.runtime = Path(__file__).resolve().parents[4]
        self.framework = self.root / 'Framework $literal " quoted'
        self.framework.mkdir()
        (self.framework / "cjpm.toml").write_text('[package]\nname="cjgui"\nversion="0.0.0"\n'
                                                   'output-type="static"\nsrc-dir="src"\n')
        (self.framework / "src").mkdir()
        (self.framework / "src/core.cj").write_text("package cjgui\n")
        runner = self.framework / "platforms/linux/scripts/run_linux_application.sh"
        runner.parent.mkdir(parents=True)
        shutil.copy2(self.runtime / "platforms/linux/scripts/run_linux_application.sh", runner)
        runner.chmod(0o755)
        (self.framework / "platforms/linux/framework-sources.txt").write_text("core.cj\n")
        shutil.copytree(self.runtime / "templates/application/ui_only",
                        self.framework / "templates/application/ui_only")
        shutil.copytree(self.runtime / "templates/application/mixed_form",
                        self.framework / "templates/application/mixed_form")
        resources = self.framework / "resources"
        resources.mkdir()
        shutil.copy2(self.runtime / "resources/composable-beacon.png", resources / "composable-beacon.png")
        shutil.copy2(self.runtime / "resources/composable-beacon-coral.png",
                     resources / "composable-beacon-coral.png")
        self.script = self.runtime / "platforms/linux/scripts/create_linux_application.sh"

    def tearDown(self):
        self.temp.cleanup()

    def create(self, destination, *extra):
        return subprocess.run(["bash", str(self.script), "ui-only", str(destination),
                               "--framework", str(self.framework), *extra],
                              capture_output=True, text=True)

    def test_creates_portable_ui_only_in_literal_path(self):
        destination = self.root / 'new app $literal " quoted'
        result = self.create(destination)
        self.assertEqual(result.returncode, 0, result.stderr)
        manifest = tomllib.loads((destination / "cjpm.toml").read_text())
        self.assertEqual((destination / manifest["dependencies"]["cjgui"]["path"]).resolve(),
                         self.framework.resolve())
        self.assertTrue(os.access(destination / "run.sh", os.X_OK))
        source = (destination / "src/main.cj").read_text()
        self.assertIn("cjguiCreatePlatformApplicationHost", source)
        self.assertNotIn("CjguiMacosApplicationHost", source)
        self.assertNotIn("CjguiLinuxApplicationHost", source)
        self.assertTrue((destination / "composable-beacon.png").is_file())
        self.assertFalse((destination / ".cjgui").exists())
        self.assertFalse((destination / "target").exists())

        environment = dict(os.environ)
        environment.pop("CJGUI_CANGJIE_TOOLCHAIN", None)
        run = subprocess.run(["bash", str(destination / "run.sh")], env=environment,
                             capture_output=True, text=True)
        self.assertEqual(run.returncode, 2)
        self.assertIn("CJGUI_CANGJIE_TOOLCHAIN", run.stderr)

        marker = destination / "keep-user-file"
        marker.write_text("unchanged")
        again = self.create(destination)
        self.assertEqual(again.returncode, 2)
        self.assertEqual(marker.read_text(), "unchanged")

    def test_creates_opt_in_mixed_form_without_starter_images(self):
        destination = self.root / "mixed form app"
        result = subprocess.run(["bash", str(self.script), "mixed-form", str(destination),
                                 "--framework", str(self.framework)], capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        manifest = tomllib.loads((destination / "cjpm.toml").read_text())
        self.assertEqual((destination / manifest["dependencies"]["cjgui"]["path"]).resolve(),
                         self.framework.resolve())
        self.assertIn("cjgui_shared_operation_core", manifest["dependencies"])
        self.assertIn("cjgui_notification_threshold_application", manifest["dependencies"])
        self.assertIn("CjguiGeneratedUiWindowRegion", (destination / "src/main.cj").read_text())
        self.assertTrue((destination / "client.py").is_file())
        self.assertTrue(os.access(destination / "run.sh", os.X_OK))
        self.assertFalse((destination / "composable-beacon.png").exists())
        self.assertFalse((destination / ".cjgui").exists())
        self.assertFalse((destination / "target").exists())
        self.assertEqual(
            subprocess.run(["bash", str(self.script), "mixed-form", str(destination),
                            "--framework", str(self.framework)], capture_output=True).returncode, 2)

    def test_rejects_other_kinds_and_missing_runner(self):
        destination = self.root / "other kind"
        result = subprocess.run(["bash", str(self.script), "collaboration", str(destination),
                                 "--framework", str(self.framework)], capture_output=True, text=True)
        self.assertEqual(result.returncode, 2)
        self.assertIn("ui-only", result.stderr)
        self.assertFalse(destination.exists())

        runner = self.framework / "platforms/linux/scripts/run_linux_application.sh"
        runner.chmod(0o644)
        result = self.create(destination)
        self.assertEqual(result.returncode, 2)
        self.assertIn("runner missing", result.stderr)
        self.assertFalse(destination.exists())

    def test_linux_framework_source_list_is_explicit_and_existing(self):
        lines = (self.runtime / "platforms/linux/framework-sources.txt").read_text().splitlines()
        self.assertEqual(len(lines), 56)
        self.assertEqual(len(set(lines)), len(lines))
        for line in lines:
            self.assertTrue(line.endswith(".cj"), line)
            self.assertFalse(Path(line).is_absolute(), line)
            self.assertNotIn("..", Path(line).parts, line)
            self.assertTrue((self.runtime / "src" / line).is_file(), line)


if __name__ == "__main__":
    unittest.main()

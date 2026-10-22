"""The creator transports paths as data and never copies build products."""
from pathlib import Path
import ast
import os
import shutil
import subprocess
import tempfile
import tomllib
import unittest


class CreateApplicationTest(unittest.TestCase):
    def test_existing_kinds_and_mixed_form_in_literal_paths(self):
        runtime = Path(__file__).resolve().parents[2]
        script = runtime / "scripts/create_macos_application.sh"
        with tempfile.TemporaryDirectory(prefix="cjgui-create-contract-") as temporary:
            root = Path(temporary).resolve()
            framework = root / 'Framework $literal " quoted'
            framework.mkdir()
            shutil.copy2(runtime / "cjpm.toml", framework / "cjpm.toml")
            shutil.copytree(runtime / "templates/macos_application", framework / "templates/macos_application",
                            ignore=shutil.ignore_patterns("target", ".cjgui", "artifacts", "__pycache__", ".DS_Store"))
            (framework / "scripts").mkdir()
            shutil.copy2(runtime / "scripts/run_macos_application.sh", framework / "scripts/run_macos_application.sh")
            shutil.copy2(runtime / "scripts/macos_build_config.py", framework / "scripts/macos_build_config.py")
            for kind, folder in [("ui-only", "ui_only"), ("command-surface", "command_surface"),
                                 ("collaboration", "collaboration"), ("mixed-form", "mixed_form")]:
                with self.subTest(kind=kind):
                    template = framework / "templates/macos_application" / folder
                    for ignored in ["target", ".cjgui", "artifacts"]:
                        (template / ignored).mkdir()
                        (template / ignored / "must-not-copy").write_text("producer output")
                    destination = root / (kind + " app")
                    subprocess.run(["zsh", str(script), kind, str(destination), "--framework", str(framework)],
                                   check=True, capture_output=True, text=True)
                    manifest = tomllib.loads((destination / "cjpm.toml").read_text())
                    self.assertEqual((destination / manifest["dependencies"]["cjgui"]["path"]).resolve(), framework)
                    self.assertFalse(any((destination / name).exists() for name in ["target", ".cjgui", "artifacts"]))
                    environment = dict(os.environ)
                    environment.pop("CANGJIE_HOME", None)
                    environment.pop("CJGUI_CANGJIE_HOME", None)
                    # Resolve the literal framework path through the actual
                    # runner, then stop before compilation for these fixtures.
                    result = subprocess.run(["zsh", str(destination / "run.sh"), "--build-only"],
                                            env=environment, capture_output=True, text=True)
                    self.assertEqual(result.returncode, 2)
                    self.assertIn("no selected Cangjie toolchain", result.stderr)
                    if (destination / "client.py").exists():
                        ast.parse((destination / "client.py").read_text())
                    marker = destination / "keep-user-file"
                    marker.write_text("unchanged")
                    again = subprocess.run(["zsh", str(script), kind, str(destination), "--framework", str(framework)],
                                           capture_output=True, text=True)
                    self.assertEqual(again.returncode, 2)
                    self.assertEqual(marker.read_text(), "unchanged")


if __name__ == "__main__":
    unittest.main()

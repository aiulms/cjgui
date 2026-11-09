"""Installation preserves existing work and stays usable outside its source."""
from pathlib import Path
import json
import os
import shutil
import subprocess
import sys
import tempfile
import unittest


SKILL = Path(__file__).resolve().parents[2] / "skills/cjgui-app-dev"


class InstallTest(unittest.TestCase):
    def call(self, source, *args):
        return subprocess.run([sys.executable, "-B", str(source / "scripts/install.py"), *map(str, args)],
                              text=True, capture_output=True)

    def test_link_is_idempotent_but_conflicting_install_is_preserved(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            linked = root / "linked"
            result = self.call(SKILL, "--skills-dir", linked)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual((linked / "cjgui-app-dev").resolve(), SKILL.resolve())
            result = self.call(SKILL, "--skills-dir", linked)
            self.assertEqual(json.loads(result.stdout)["status"], "already-linked")
            conflict = root / "conflict/cjgui-app-dev"
            conflict.mkdir(parents=True)
            (conflict / "user.txt").write_text("keep this work")
            result = self.call(SKILL, "--skills-dir", conflict.parent, "--mode", "copy")
            self.assertEqual(result.returncode, 2)
            self.assertEqual((conflict / "user.txt").read_text(), "keep this work")

    def test_copy_runs_after_original_source_is_removed_and_records_origin(self):
        with tempfile.TemporaryDirectory(prefix="cjgui skill install ") as temporary:
            root = Path(temporary)
            source = root / "source/cjgui-app-dev"
            shutil.copytree(SKILL, source, ignore=shutil.ignore_patterns("__pycache__"))
            result = self.call(source, "--skills-dir", root / "installed", "--mode", "copy")
            self.assertEqual(result.returncode, 0, result.stderr)
            installed = root / "installed/cjgui-app-dev"
            receipt = json.loads((installed / ".cjgui-skill-install.json").read_text())
            self.assertEqual(receipt["source"], str(source.resolve()))
            self.assertIn("references/feedback.md", receipt["files"])
            shutil.rmtree(source)
            app = root / "App With Spaces"
            app.mkdir()
            (app / "cjpm.toml").write_text('[package]\nname="test_app"\n')
            result = subprocess.run([sys.executable, "-B", str(installed / "scripts/identify.py"),
                                     "--app", str(app)], text=True, capture_output=True,
                                    env={**os.environ, "PYTHONPATH": ""})
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(json.loads(result.stdout)["runtime"]["status"], "unknown")
            observation = root / "observation.json"
            observation.write_text(json.dumps({"goal": "test", "expected": "local feedback",
                                               "actual": "source unavailable; installed helper still works"}))
            result = subprocess.run([sys.executable, "-B", str(installed / "scripts/feedback.py"),
                                     "create", "--app", str(app), "--input", str(observation)],
                                    text=True, capture_output=True)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertTrue((Path(json.loads(result.stdout)["root"]) / "issues").is_dir())


if __name__ == "__main__":
    unittest.main()

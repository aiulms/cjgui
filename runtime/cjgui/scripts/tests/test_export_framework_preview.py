"""Small source-transport checks; no SDK, compiler, UI or author checkout dependency."""
from pathlib import Path
import hashlib
import json
import shutil
import subprocess
import tempfile
import unittest


RUNTIME = Path(__file__).resolve().parents[2]
IGNORED = shutil.ignore_patterns("target", ".cjgui", "artifacts", "__pycache__", ".DS_Store")


class ExportPreviewTest(unittest.TestCase):
    def test_package_sources_follow_new_modules_without_changing_probe_profile(self):
        library = RUNTIME / "native/scripts/lib_cjgui_source_set.sh"
        with tempfile.TemporaryDirectory(prefix="cjgui-source-set-") as temporary:
            package = Path(temporary)
            (package / "src").mkdir()
            (package / "cjpm.toml").write_text('[package]\nsrc-dir = "src"\n')
            for name in ["present.cj", "future_public.cj", "present_test.cj"]:
                (package / "src" / name).write_text("package fixture\n")
            result = subprocess.run(["zsh", "-c",
                                     'source "$1"; cjgui_package_source_paths "$2"',
                                     "--", str(library), str(package)],
                                    check=True, capture_output=True, text=True)
            self.assertEqual({Path(p).name for p in result.stdout.splitlines()},
                             {"present.cj", "future_public.cj"})

    def test_export_profiles_keep_sources_and_leave_outputs_behind(self):
        with tempfile.TemporaryDirectory(prefix="cjgui-export-contract-") as temporary:
            root = Path(temporary).resolve()
            runtime = root / "author/runtime/cjgui"
            runtime.mkdir(parents=True)
            repository = runtime.parents[1]
            for name in ["LICENSE", "NOTICE"]:
                (repository / name).write_text("fixture " + name + "\n")
            for folder in ["scripts", "native/scripts", "src", "shared_operation_core/src", "resources", "preview"]:
                (runtime / folder).mkdir(parents=True, exist_ok=True)
            for name in ["export_framework_preview.sh", "create_macos_application.sh", "run_macos_application.sh", "macos_build_config.py"]:
                shutil.copy2(RUNTIME / "scripts" / name, runtime / "scripts" / name)
            shutil.copy2(RUNTIME / "native/scripts/lib_cjgui_source_set.sh", runtime / "native/scripts/lib_cjgui_source_set.sh")
            shutil.copy2(RUNTIME / "build.cj", runtime / "build.cj")
            shutil.copy2(RUNTIME / "native/scripts/build_cjgui_internal_renderer_sidecar.sh",
                         runtime / "native/scripts/build_cjgui_internal_renderer_sidecar.sh")
            shutil.copytree(RUNTIME / "templates/macos_application", runtime / "templates/macos_application", ignore=IGNORED)
            for package in [runtime, runtime / "shared_operation_core"]:
                shutil.copy2(RUNTIME / ("shared_operation_core/cjpm.toml" if package.name == "shared_operation_core" else "cjpm.toml"), package / "cjpm.toml")
                (package / "src/current.cj").write_text("package fixture\n")
                (package / "src/future_public.cj").write_text("package fixture\n")
                (package / "src/current_test.cj").write_text("not production\n")
            for p in (RUNTIME / "native").iterdir():
                if p.suffix in [".m", ".h"]:
                    (runtime / "native" / p.name).write_text("// fixture\n")
            for p in (RUNTIME / "shared_operation_core").glob("*.py"):
                shutil.copy2(p, runtime / "shared_operation_core" / p.name)
            for p in (RUNTIME / "preview").glob("*.md"):
                shutil.copy2(p, runtime / "preview" / p.name)
            for name in ["README.md", "MACOS_APPLICATION_HOST.md", "LAYOUT_PRIMITIVES.md", "FIELD_CONTROLS.md", "CARD_GRID.md", "ACCESSIBILITY.md", "FONT_RESOURCES.md", "STYLED_TEXT.md"]:
                (runtime / name).write_text("# Fixture\n")
            (runtime / "FIELD_CONTROLS.md").write_text(
                '[consumer](examples/generated_collection/README.md)\n'
                '[historical proof](artifacts/unshipped.txt)\n')
            for name in ["composable-beacon.png", "composable-beacon-coral.png"]:
                (runtime / "resources" / name).write_bytes(b"fixture")
            for name in ["rule_set_application", "tree_outline_consumer", "generated_panel_consumer",
                         "adaptive_layout_public_consumer", "rule_set_window_app", "generated_collection"]:
                example = runtime / "examples" / name
                (example / "src").mkdir(parents=True)
                (example / "src/main.cj").write_text("package fixture\n")
                (example / "cjpm.toml").write_text('[dependencies]\ncjgui = { path = "../.." }\n')
                for script in ["run.sh", "cjgui_macos_app.sh"]:
                    (example / script).write_text("#!/usr/bin/env zsh\n")
                for p in (RUNTIME / "examples" / name).glob("*.py"):
                    (example / p.name).write_text("# fixture\n")
                (example / "README.md").write_text("# Consumer fixture\n")
            (runtime / "templates/macos_application/mixed_form/target").mkdir()
            (runtime / "templates/macos_application/mixed_form/target/must-not-copy").write_text("output")
            for profile in ["full", "macos-dev"]:
                destination = root / ("Preview " + profile)
                args = ["zsh", str(runtime / "scripts/export_framework_preview.sh"), str(destination)]
                if profile != "full":
                    args += ["--profile", profile]
                subprocess.run(args, check=True, capture_output=True, text=True)
                framework = destination / "framework/cjgui"
                self.assertTrue((framework / "src/future_public.cj").is_file())
                self.assertFalse((framework / "src/current_test.cj").exists())
                self.assertTrue((framework / "native/cjgui_async_multiline_bridge.m").is_file())
                self.assertTrue((framework / "templates/macos_application/mixed_form/client.py").is_file())
                self.assertTrue((framework / "scripts/macos_build_config.py").is_file())
                self.assertTrue((framework / "LAYOUT_PRIMITIVES.md").is_file())
                self.assertTrue((framework / "ACCESSIBILITY.md").is_file())
                self.assertTrue((framework / "FIELD_CONTROLS.md").is_file())
                documentation = (framework / "FIELD_CONTROLS.md").read_text()
                self.assertIn('../../consumers/generated_collection/README.md', documentation)
                self.assertIn('historical proof（仓库参考，未随包）', documentation)
                self.assertTrue((destination / "consumers/generated_collection/client.py").is_file())
                self.assertTrue((destination / "consumers/generated_collection/README.md").is_file())
                self.assertTrue((destination / "framework/rule_set_application/src/main.cj").is_file())
                # Transported example must resolve against this package, not
                # the author's original runtime tree.
                collection_toml = (destination / "consumers/generated_collection/cjpm.toml").read_text()
                self.assertIn('../../framework/cjgui', collection_toml)
                self.assertNotIn(str(RUNTIME), collection_toml)
                self.assertFalse(any(p.name in ["target", ".cjgui", "artifacts", "__pycache__"] for p in destination.rglob("*")))
                manifest = json.loads((destination / "source-manifest.json").read_text())
                files = {p.relative_to(destination).as_posix() for p in destination.rglob("*") if p.is_file()}
                self.assertEqual({entry["path"] for entry in manifest["files"]} | {"source-manifest.json"}, files)
                for entry in manifest["files"]:
                    self.assertEqual(hashlib.sha256((destination / entry["path"]).read_bytes()).hexdigest(), entry["sha256"])
                self.assertTrue((destination / "consumers").exists())
                again = subprocess.run(args, capture_output=True, text=True)
                self.assertEqual(again.returncode, 2)

            # Release integration pins its accepted source set while another
            # task may add leaf modules. New files must not enter that package.
            locked = {p.relative_to(runtime).as_posix(): hashlib.sha256(p.read_bytes()).hexdigest()
                      for p in runtime.rglob('*.cj') if 'target' not in p.parts}
            lock = root / 'accepted-sources.json'
            lock.write_text(json.dumps(locked))
            (runtime / 'src/parallel_next.cj').write_text('package future_phase\n')
            destination = root / 'Locked Preview'
            args = ['zsh', str(runtime / 'scripts/export_framework_preview.sh'), str(destination),
                    '--profile', 'macos-dev', '--source-lock', str(lock)]
            result = subprocess.run(args, capture_output=True, text=True)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertFalse((destination / 'framework/cjgui/src/parallel_next.cj').exists())
            self.assertTrue((destination / 'source-lock.json').is_file())
            incomplete = dict(locked)
            incomplete.pop('templates/macos_application/mixed_form/src/main.cj')
            incomplete_lock = root / 'incomplete-sources.json'
            incomplete_lock.write_text(json.dumps(incomplete))
            missing_args = list(args)
            missing_args[2] = str(root / 'Incomplete Template Preview')
            missing_args[-1] = str(incomplete_lock)
            refused = subprocess.run(missing_args, capture_output=True, text=True)
            self.assertNotEqual(refused.returncode, 0)
            self.assertIn('source lock omitted required template/application source', refused.stderr)
            self.assertFalse(Path(missing_args[2]).exists())
            (runtime / 'src/current.cj').write_text('package changed_accepted_source\n')
            args[2] = str(root / 'Changed Locked Preview')
            result = subprocess.run(args, capture_output=True, text=True)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn('source lock changed', result.stderr)
            self.assertFalse(Path(args[2]).exists())

    def test_delivery_closure_lock_freezes_every_shipped_input(self):
        """The release lock covers the DELIVERY CLOSURE, not a .cj scan.

        A second export driven by the written lock must reproduce the identical
        package; a native or script digest that moved is refused BY NAME (so a
        native/ABI drift cannot pass while only .cj files match), and an added or
        dropped input is refused instead of silently entering or leaving the
        package.
        """
        with tempfile.TemporaryDirectory(prefix="cjgui-closure-lock-") as temporary:
            root = Path(temporary).resolve()
            runtime = root / "author/runtime/cjgui"
            runtime.mkdir(parents=True)
            repository = runtime.parents[1]
            for name in ["LICENSE", "NOTICE"]:
                (repository / name).write_text("fixture " + name + "\n")
            for folder in ["scripts", "native/scripts", "src", "shared_operation_core/src", "resources", "preview"]:
                (runtime / folder).mkdir(parents=True, exist_ok=True)
            for name in ["export_framework_preview.sh", "create_macos_application.sh", "run_macos_application.sh",
                         "macos_build_config.py"]:
                shutil.copy2(RUNTIME / "scripts" / name, runtime / "scripts" / name)
            for name in ["lib_cjgui_source_set.sh", "build_cjgui_internal_renderer_sidecar.sh"]:
                shutil.copy2(RUNTIME / "native/scripts" / name, runtime / "native/scripts" / name)
            shutil.copy2(RUNTIME / "build.cj", runtime / "build.cj")
            shutil.copytree(RUNTIME / "templates/macos_application", runtime / "templates/macos_application",
                            ignore=IGNORED)
            for package in [runtime, runtime / "shared_operation_core"]:
                shutil.copy2(RUNTIME / ("shared_operation_core/cjpm.toml" if package.name == "shared_operation_core"
                                        else "cjpm.toml"), package / "cjpm.toml")
                (package / "src/source.cj").write_text("package fixture\n")
            # One native translation unit and one script are the two inputs a
            # .cj-only lock could never pin.
            (runtime / "native/renderer.m").write_text("// native fixture v1\n")
            (runtime / "native/scripts/build_cjgui_internal_renderer_sidecar.sh").write_text(
                "#!/usr/bin/env zsh\necho script v1\n")
            for p in (RUNTIME / "shared_operation_core").glob("*.py"):
                shutil.copy2(p, runtime / "shared_operation_core" / p.name)
            for p in (RUNTIME / "preview").glob("*.md"):
                shutil.copy2(p, runtime / "preview" / p.name)
            for name in ["README.md", "MACOS_APPLICATION_HOST.md", "LAYOUT_PRIMITIVES.md", "FIELD_CONTROLS.md",
                         "CARD_GRID.md", "ACCESSIBILITY.md", "FONT_RESOURCES.md", "STYLED_TEXT.md"]:
                (runtime / name).write_text("# Fixture\n")
            for name in ["composable-beacon.png"]:
                (runtime / "resources" / name).write_bytes(b"fixture")
            for name in ["rule_set_application", "tree_outline_consumer", "generated_collection",
                         "rule_set_window_app"]:
                example = runtime / "examples" / name
                (example / "src").mkdir(parents=True)
                (example / "src/main.cj").write_text("package fixture\n")
                (example / "cjpm.toml").write_text('[dependencies]\ncjgui = { path = "../.." }\n')
                for script in ["run.sh", "cjgui_macos_app.sh"]:
                    (example / script).write_text("#!/usr/bin/env zsh\n")
                (example / "README.md").write_text("# Consumer fixture\n")

            def export(destination, lock_args=()):
                return subprocess.run(["zsh", str(runtime / "scripts/export_framework_preview.sh"), str(destination),
                                       "--profile", "macos-dev", *lock_args], capture_output=True, text=True)

            lock = root / "accepted-closure.json"
            first = export(root / "SDK A", ["--write-source-lock", str(lock)])
            self.assertEqual(first.returncode, 0, first.stderr)
            payload = json.loads(lock.read_text())
            self.assertEqual(payload["format"], 2)
            inputs = payload["inputs"]
            # The closure really carries the native unit, the script, the build
            # script, the template source and the assets.
            self.assertIn("native/renderer.m", inputs)
            self.assertIn("native/scripts/build_cjgui_internal_renderer_sidecar.sh", inputs)
            self.assertIn("build.cj", inputs)
            self.assertIn("templates/macos_application/mixed_form/src/main.cj", inputs)
            self.assertIn("resources/composable-beacon.png", inputs)
            self.assertNotIn("README.md", inputs)
            manifest_a = json.loads((root / "SDK A" / "source-manifest.json").read_text())
            # A lock-driven export also SHIPS the lock, so two lock-driven exports
            # are the reproducible pair (the freeze export has no lock inside).
            self.assertFalse((root / "SDK A" / "source-lock.json").exists())
            second = export(root / "SDK B", ["--source-lock", str(lock)])
            self.assertEqual(second.returncode, 0, second.stderr)
            third = export(root / "SDK C", ["--source-lock", str(lock)])
            self.assertEqual(third.returncode, 0, third.stderr)
            manifest_b = json.loads((root / "SDK B" / "source-manifest.json").read_text())
            manifest_c = json.loads((root / "SDK C" / "source-manifest.json").read_text())
            self.assertEqual(manifest_b["exported_content_sha256"], manifest_c["exported_content_sha256"])
            self.assertEqual(manifest_b["delivery_closure"]["inputs"], len(inputs))
            self.assertEqual(manifest_b["delivery_closure"], manifest_c["delivery_closure"])
            self.assertEqual(manifest_b["source_lock"]["mode"], "closure")
            self.assertTrue((root / "SDK B" / "source-lock.json").is_file())
            # The freeze export was produced from the same frozen inputs.
            self.assertEqual(manifest_a["delivery_closure"]["closure_sha256"],
                             manifest_b["delivery_closure"]["closure_sha256"])

            def mutated(name, mutate):
                value = json.loads(json.dumps(payload))
                mutate(value)
                target = root / name
                target.write_text(json.dumps(value))
                destination = root / ("Refused " + name)
                return export(destination, ["--source-lock", str(target)]), destination

            def break_native(value):
                value["inputs"]["native/renderer.m"] = "0" * 64

            result, destination = mutated("native-drift.json", break_native)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("source lock changed: native/renderer.m (native)", result.stderr)
            self.assertFalse(destination.exists())

            def break_script(value):
                value["inputs"]["native/scripts/build_cjgui_internal_renderer_sidecar.sh"] = "0" * 64

            result, destination = mutated("script-drift.json", break_script)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("(script)", result.stderr)
            self.assertFalse(destination.exists())

            def drop_template(value):
                value["inputs"].pop("templates/macos_application/mixed_form/src/main.cj")

            result, destination = mutated("omitted.json", drop_template)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("source lock omitted a delivered input: "
                          "templates/macos_application/mixed_form/src/main.cj (template)", result.stderr)
            self.assertFalse(destination.exists())

            def add_unknown(value):
                value["inputs"]["native/not-shipped.m"] = "0" * 64

            result, destination = mutated("unknown.json", add_unknown)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("source lock names an input this export does not deliver", result.stderr)
            self.assertFalse(destination.exists())


if __name__ == "__main__":
    unittest.main()

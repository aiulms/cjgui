"""Configuration/cache checks; the separate real cjpm experiment proves linking."""
from pathlib import Path
import importlib.util
import json
import tempfile
import unittest
from unittest.mock import patch

SPEC = importlib.util.spec_from_file_location("macos_build_config", Path(__file__).parents[1] / "macos_build_config.py")
BUILD = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(BUILD)


class MacosBuildConfigTest(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix="cjgui-build-config-")
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name).resolve()
        self.framework = self.root / "Framework 源"
        self.app = self.root / 'App with $ and "quote"'
        self.native = self.app / ".cjgui/native/lib"
        self.cache = self.app / ".cjgui/macos-build"
        for path in [self.framework / "src", self.app / "src", self.native]:
            path.mkdir(parents=True)
        self.app_source = self.app / "src/main.cj"
        self.app_source.write_text("package fixture\nmain(): Unit {}\n")
        (self.framework / "src/library.cj").write_text("package cjgui\n")
        (self.framework / "src/ignored_test.cj").write_text("not a build input\n")
        (self.framework / "cjpm.toml").write_text('[package]\ncjc-version="1.1.3"\nname="cjgui"\nversion="0.0.0"\noutput-type="static"\n[ffi.c]\ncjgui_internal_renderer={path="native/lib"}\n')
        (self.app / "cjpm.toml").write_text('[package]\ncjc-version="1.1.3"\nname="fixture"\nversion="0.0.0"\noutput-type="executable"\n[dependencies]\ncjgui={path="../Framework 源"}\n[profile.build]\nincremental=true\n[profile.customized-option]\nrelease="-O2 -Woff all"\n')
        self.archive = self.native / "libcjgui_internal_renderer.a"
        self.archive.write_bytes(b"unit fixture archive")

    def prepare(self):
        return BUILD.prepare(self.app, self.framework, self.native, self.cache)

    def test_regular_snapshot_pins_both_metadata_and_reuses_equal_input(self):
        original = (self.app / "cjpm.toml").read_bytes()
        project = self.prepare()
        app_data = BUILD.read_manifest(project)
        dependency = BUILD.read_manifest(self.cache / "framework")
        self.assertEqual(dependency["ffi"]["c"]["cjgui_internal_renderer"]["path"], str(self.native))
        self.assertEqual(app_data["profile"]["customized-option"]["release"], "-O2 -Woff all")
        copied = project / "src/main.cj"
        self.assertFalse(copied.is_symlink())
        self.assertEqual(copied.read_bytes(), self.app_source.read_bytes())
        self.assertFalse(copied.stat().st_mode & 0o222)
        self.assertFalse((self.cache / "framework/src/ignored_test.cj").exists())
        self.assertEqual((project / "target").resolve(), self.app / "target")
        timestamp = copied.stat().st_mtime_ns
        key = json.loads((self.cache / "prepared.json").read_text())["build_key"]
        self.prepare()
        self.assertEqual(copied.stat().st_mtime_ns, timestamp)
        self.assertEqual(json.loads((self.cache / "prepared.json").read_text())["build_key"], key)
        self.assertEqual((self.app / "cjpm.toml").read_bytes(), original)

    def test_source_set_change_refuses_publication(self):
        self.prepare()
        (self.framework / "src/added.cj").write_text("package cjgui\n")
        with self.assertRaisesRegex(ValueError, "source files"):
            BUILD.verify(self.cache, self.app / "target/release/bin/main")

    def test_explicit_source_set_does_not_absorb_concurrent_leaf_modules(self):
        source = self.framework / 'src'
        (source / 'parallel_next.cj').write_text('package next_phase\n')
        selected = BUILD.snapshot_sources(source, self.cache / 'selected/src', include_tests=True,
                                          source_names={'library.cj'})
        self.assertEqual(set(selected), {str(self.cache / 'selected/src/library.cj')})
        self.assertFalse((self.cache / 'selected/src/parallel_next.cj').exists())
        self.assertEqual((source / 'parallel_next.cj').read_text(), 'package next_phase\n')

    def test_local_business_dependency_is_a_cjpm_table_not_inline_metadata(self):
        original = BUILD.read_manifest(self.app)
        original["dependencies"]["business_domain"] = {"path": "../Business 源"}
        BUILD.write_manifest(self.app / "cjpm.toml", original)
        # Source provenance recursively reads declared dependencies too.
        business = self.root / "Business 源"
        (business / "src").mkdir(parents=True)
        (business / "src/domain.cj").write_text("package business_domain\n")
        (business / "cjpm.toml").write_text('[package]\nname="business_domain"\nversion="0.0.0"\noutput-type="static"\n')
        project = self.prepare()
        text = (project / "cjpm.toml").read_text()
        self.assertIn('["dependencies"."business_domain"]', text)
        self.assertEqual(BUILD.read_manifest(project)["dependencies"]["business_domain"]["path"], str(business))

    def test_source_filename_at_filesystem_limit_needs_no_longer_suffix(self):
        name = "s" * 252 + ".cj"
        source = self.framework / "src" / name
        source.write_text("package cjgui\n")
        self.prepare()
        self.assertEqual((self.cache / "framework/src" / name).read_bytes(), source.read_bytes())
        self.assertFalse(list((self.cache / "framework/src").glob(".cjgui-source-*")))

    def test_actual_linker_choice_must_match_private_archive(self):
        project = self.prepare()
        shared = self.framework / "native/lib/libcjgui_internal_renderer.a"
        (self.cache / "current-link.log").write_text(str(shared) + "(flavor.o)\n")
        with self.assertRaisesRegex(ValueError, "unapproved native archive"):
            BUILD.verify(self.cache, project / "main")

    def test_cached_link_proof_cannot_be_used_for_another_executable(self):
        project = self.prepare()
        executable = self.app / "target/main"
        executable.write_bytes(b"first executable")
        (self.cache / "current-link.log").write_text(str(self.archive) + "(flavor.o)\n")
        (project / BUILD.MAP_NAME).write_text("# Object files:\n[ 5] flavor.o\n")
        class Members:
            stdout = "flavor.o\n"
        with patch.object(BUILD.subprocess, "run", return_value=Members()):
            BUILD.verify(self.cache, executable)
            (self.cache / "current-link.log").write_text("cjpm build success: cache hit\n")
            self.assertTrue(BUILD.verify(self.cache, executable)["verified"])
            executable.write_bytes(b"different executable")
            with self.assertRaisesRegex(ValueError, "identical verified executable"):
                BUILD.verify(self.cache, executable)

    def test_changed_compiler_options_refuse_existing_incremental_objects(self):
        self.prepare()
        old_record = (self.cache / "prepared.json").read_bytes()
        verified = json.loads(old_record)
        verified["verified"] = True
        (self.cache / "build-provenance.json").write_text(json.dumps(verified))
        stale = self.app / "target/release/cjgui/libcjgui.a"
        stale.parent.mkdir(parents=True)
        stale.write_bytes(b"old compiled dependency")
        manifest = self.app / "cjpm.toml"
        manifest.write_text(manifest.read_text().replace('name="fixture"',
                            'name="fixture"\noverride-compile-option="-O2"'))
        with self.assertRaisesRegex(ValueError, "compiler configuration.*target"):
            self.prepare()
        self.assertEqual(stale.read_bytes(), b"old compiled dependency")
        self.assertEqual((self.cache / "prepared.json").read_bytes(), old_record)
        stale.unlink()
        self.prepare()
        self.assertEqual(BUILD.read_manifest(self.cache / "application")["package"]["override-compile-option"], "-O2")
        verified = json.loads((self.cache / "prepared.json").read_text())
        verified["verified"] = True
        (self.cache / "build-provenance.json").write_text(json.dumps(verified))
        stale.write_bytes(b"optimized dependency")
        manifest.write_text(manifest.read_text().replace('\noverride-compile-option="-O2"', ''))
        with self.assertRaisesRegex(ValueError, "compiler configuration.*target"):
            self.prepare()
        self.assertEqual(stale.read_bytes(), b"optimized dependency")

    def test_unchanged_compiler_options_allow_source_edits_with_existing_objects(self):
        self.prepare()
        verified = json.loads((self.cache / "prepared.json").read_text())
        verified["verified"] = True
        (self.cache / "build-provenance.json").write_text(json.dumps(verified))
        stale = self.app / "target/release/cjgui/libcjgui.a"
        stale.parent.mkdir(parents=True)
        stale.write_bytes(b"previous dependency")
        self.app_source.write_text("package fixture\nmain(): Unit { println(1) }\n")
        self.prepare()
        self.assertEqual(stale.read_bytes(), b"previous dependency")

    def test_unknown_existing_target_rejects_new_configuration(self):
        stale = self.app / "target/release/cjgui/libcjgui.a"
        stale.parent.mkdir(parents=True)
        stale.write_bytes(b"unidentified dependency")
        with self.assertRaisesRegex(ValueError, "compiler configuration.*target"):
            self.prepare()
        self.assertEqual(stale.read_bytes(), b"unidentified dependency")

    def test_unverified_preparation_cannot_replace_verified_options(self):
        self.prepare()
        old = json.loads((self.cache / "prepared.json").read_text())
        old["verified"] = True
        (self.cache / "build-provenance.json").write_text(json.dumps(old))
        manifest = self.app / "cjpm.toml"
        manifest.write_text(manifest.read_text().replace('name="fixture"',
                            'name="fixture"\noverride-compile-option="-O2"'))
        self.prepare()  # empty target can start a new configuration
        stale = self.app / "target/release/cjgui/libcjgui.a"
        stale.parent.mkdir(parents=True)
        stale.write_bytes(b"old object survives a failed build")
        with self.assertRaisesRegex(ValueError, "compiler configuration.*target"):
            self.prepare()

    def test_failed_new_configuration_cannot_return_to_old_verified_target(self):
        self.prepare()
        old = json.loads((self.cache / "prepared.json").read_text())
        old["verified"] = True
        (self.cache / "build-provenance.json").write_text(json.dumps(old))
        manifest = self.app / "cjpm.toml"
        original = manifest.read_text()
        manifest.write_text(original.replace('name="fixture"',
                            'name="fixture"\noverride-compile-option="-O2"'))
        self.prepare()  # clean target, then the new build fails after one dependency
        partial = self.app / "target/release/cjgui/libcjgui.a"
        partial.parent.mkdir(parents=True)
        partial.write_bytes(b"partial O2 dependency")
        prepared = (self.cache / "prepared.json").read_bytes()
        manifest.write_text(original)
        with self.assertRaisesRegex(ValueError, "compiler configuration.*target"):
            self.prepare()
        self.assertEqual(partial.read_bytes(), b"partial O2 dependency")
        self.assertEqual((self.cache / "prepared.json").read_bytes(), prepared)
        partial.unlink()
        self.prepare()

    def test_legacy_unchanged_manifests_do_not_prove_dependency_flags(self):
        manifest = self.app / "cjpm.toml"
        manifest.write_text(manifest.read_text().replace('name="fixture"',
                            'name="fixture"\noverride-compile-option="-O2"'))
        self.prepare()
        old = json.loads((self.cache / "prepared.json").read_text())
        old.pop("compiler_configuration", None)
        old["verified"] = True
        (self.cache / "build-provenance.json").write_text(json.dumps(old))
        old.pop("verified")
        (self.cache / "prepared.json").write_text(json.dumps(old))
        stale = self.app / "target/release/cjgui/libcjgui.a"
        stale.parent.mkdir(parents=True)
        stale.write_bytes(b"legacy O0 dependency under verified O2 manifest")
        before = (self.cache / "prepared.json").read_bytes()
        with self.assertRaisesRegex(ValueError, "compiler configuration.*target"):
            self.prepare()
        self.assertEqual(stale.read_bytes(), b"legacy O0 dependency under verified O2 manifest")
        self.assertEqual((self.cache / "prepared.json").read_bytes(), before)
        stale.unlink()
        self.prepare()

    def test_dependency_compiler_options_are_part_of_configuration(self):
        self.prepare()
        verified = json.loads((self.cache / "prepared.json").read_text())
        verified["verified"] = True
        (self.cache / "build-provenance.json").write_text(json.dumps(verified))
        stale = self.app / "target/release/cjgui/libcjgui.a"
        stale.parent.mkdir(parents=True)
        stale.write_bytes(b"old dependency")
        framework_manifest = self.framework / "cjpm.toml"
        framework_manifest.write_text(framework_manifest.read_text().replace(
            'name="cjgui"', 'name="cjgui"\ncompile-option="-O2"'))
        with self.assertRaisesRegex(ValueError, "compiler configuration.*target"):
            self.prepare()
        self.assertEqual(stale.read_bytes(), b"old dependency")

    def test_isolated_testing_graph_keeps_existing_preparation_compatibility(self):
        BUILD.prepare(self.app, self.framework, self.native, self.cache, testing=True)
        stale = self.cache / "application/target/release/cjgui/libcjgui.a"
        stale.parent.mkdir(parents=True)
        stale.write_bytes(b"test dependency")
        BUILD.prepare(self.app, self.framework, self.native, self.cache, testing=True)
        self.assertEqual(stale.read_bytes(), b"test dependency")

    def test_legacy_testing_graph_with_unknown_compiler_flags_is_refused(self):
        BUILD.prepare(self.app, self.framework, self.native, self.cache, testing=True)
        prepared = json.loads((self.cache / "prepared.json").read_text())
        prepared.pop("compiler_configuration", None)
        (self.cache / "prepared.json").write_text(json.dumps(prepared))
        stale = self.cache / "application/target/release/cjgui/libcjgui.a"
        stale.parent.mkdir(parents=True)
        stale.write_bytes(b"unknown testing dependency")
        with self.assertRaisesRegex(ValueError, "compiler configuration.*target"):
            BUILD.prepare(self.app, self.framework, self.native, self.cache, testing=True)
        self.assertEqual(stale.read_bytes(), b"unknown testing dependency")


if __name__ == "__main__":
    unittest.main()

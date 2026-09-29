#!/usr/bin/env python3
"""The ImageKit and Drawing NDK link libraries must not shadow system runtimes."""

import os
from pathlib import Path
import subprocess
import tempfile
import unittest
import zipfile


SCRIPTS = Path(__file__).resolve().parent
NATIVE = Path(os.environ.get(
    "DEVECO_OH_NATIVE_HOME",
    "/Applications/DevEco-Studio.app/Contents/sdk/default/openharmony/native",
))
LIB_DIR = NATIVE / "sysroot/usr/lib/aarch64-linux-ohos"
CANGJIE_SDK = Path(os.environ.get(
    "DEVECO_CANGJIE_HOME",
    str(Path.home() / "cangjie-toolchains/harmonyos-cangjie-26.0.0.105/cangjie"),
))
OHOS_API_LIB_DIR = CANGJIE_SDK / "api/lib/linux_ohos_aarch64_cjnative/ohos"
CANGJIE_RUNTIME_LIB_DIR = CANGJIE_SDK / "build-tools/runtime/lib/linux_ohos_aarch64_cjnative"
LINK_LIBS = ("libimage_source.so", "libpixelmap.so", "libnative_drawing.so")
OWN_LIBS = (
    "libentry.so",
    "libcjgui_app.so",
    "libcjgui.so",
    "libcjgui_shared_operation_core.so",
    "libcjgui_settings_counter_application.so",
    "libcjgui_ohos_transport.so",
)


class ImageLinkPackagingTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.tmp = tempfile.TemporaryDirectory(prefix="cjgui-image-link-packaging-")
        cls.root = Path(cls.tmp.name)
        cls.elfs = {}
        source = cls.root / "entry.c"
        source.write_text("int cjgui_image_link_fixture(void) { return 1; }\n")
        for lib in OWN_LIBS:
            output = cls.root / lib
            subprocess.run([
                str(NATIVE / "llvm/bin/clang"), "--target=aarch64-linux-ohos",
                "-shared", "-fPIC", "-nostdlib", "-Wl,--no-as-needed",
                f"-Wl,-soname,{lib}", "-L", str(LIB_DIR), "-o", str(output),
                str(source), "-limage_source", "-lpixelmap", "-lnative_drawing",
            ], check=True, capture_output=True, text=True)
            cls.elfs[lib] = output
        kit_stub = cls.root / "libkit.PerformanceAnalysisKit.so"
        subprocess.run([
            str(NATIVE / "llvm/bin/clang"), "--target=aarch64-linux-ohos",
            "-shared", "-fPIC", "-nostdlib",
            "-Wl,-soname,libkit.PerformanceAnalysisKit.so",
            "-o", str(kit_stub), str(source),
        ], check=True, capture_output=True, text=True)
        cls.kit_app = cls.root / "kit-required-app.so"
        subprocess.run([
            str(NATIVE / "llvm/bin/clang"), "--target=aarch64-linux-ohos",
            "-shared", "-fPIC", "-nostdlib", "-Wl,--no-as-needed",
            "-Wl,-soname,libcjgui_app.so", "-L", str(cls.root),
            "-o", str(cls.kit_app), str(source),
            "-l:libkit.PerformanceAnalysisKit.so",
        ], check=True, capture_output=True, text=True)
        needed = subprocess.run([
            str(NATIVE / "llvm/bin/llvm-readobj"), "--needed-libs", str(cls.elfs["libentry.so"]),
        ], check=True, capture_output=True, text=True).stdout
        for lib in LINK_LIBS:
            if lib not in needed:
                raise AssertionError(f"fixture must retain DT_NEEDED {lib}")

    @classmethod
    def tearDownClass(cls):
        cls.tmp.cleanup()

    def hap(self, name: str, private_link_lib: str | None = None,
            require_kit: bool = False, packaged_ohos_mock: str | None = None) -> Path:
        hap = self.root / name
        with zipfile.ZipFile(hap, "w", zipfile.ZIP_DEFLATED) as archive:
            for lib in OWN_LIBS:
                elf = self.kit_app if require_kit and lib == "libcjgui_app.so" else self.elfs[lib]
                archive.write(elf, f"libs/arm64-v8a/{lib}")
            if private_link_lib:
                archive.write(LIB_DIR / private_link_lib, f"libs/arm64-v8a/{private_link_lib}")
            if packaged_ohos_mock:
                archive.write(OHOS_API_LIB_DIR / packaged_ohos_mock,
                              f"libs/arm64-v8a/{packaged_ohos_mock}")
        return hap

    def verify(self, hap: Path) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            ["bash", str(SCRIPTS / "verify_hap_closure.sh"), str(hap)],
            env={**os.environ, "CJGUI_DEVICE_PACKAGING": "0"},
            capture_output=True, text=True,
        )

    def test_system_image_libraries_satisfy_hap_closure(self):
        result = self.verify(self.hap("system-only.hap"))
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("RESULT: PASS", result.stdout)

    def test_missing_kit_mock_is_not_treated_as_system_runtime(self):
        result = self.verify(self.hap("kit-required.hap", require_kit=True))
        self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("UNSAT libcjgui_app.so -> libkit.PerformanceAnalysisKit.so", result.stdout)

    def test_packaged_ohos_sdk_mock_is_rejected(self):
        mock = "libohos.app.so"
        self.assertTrue((OHOS_API_LIB_DIR / mock).is_file())
        hap = self.hap("private-ohos-mock.hap", packaged_ohos_mock=mock)
        # Keep the injected SDK mock's own dependencies satisfied. The failure
        # must come from the product stub rule, not an unrelated missing .so.
        with zipfile.ZipFile(hap, "a", zipfile.ZIP_DEFLATED) as archive:
            for lib in ("libboundscheck.so", "libcangjie-runtime.so", "libcangjie-std-core.so"):
                archive.write(CANGJIE_RUNTIME_LIB_DIR / lib, f"libs/arm64-v8a/{lib}")
            archive.write(NATIVE / "llvm/lib/aarch64-linux-ohos/libc++_shared.so",
                          "libs/arm64-v8a/libc++.so")
        result = self.verify(hap)
        self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn(f"PRODUCT-FAIL HAP 携带 {mock}", result.stdout)

    def test_private_sdk_link_libraries_are_rejected(self):
        for lib in LINK_LIBS:
            with self.subTest(lib=lib):
                result = self.verify(self.hap(f"private-{lib}.hap", lib))
                self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
                self.assertIn(f"PRODUCT-FAIL HAP 携带 {lib}", result.stdout)

    def test_packager_removes_only_byte_identical_stale_link_libraries(self):
        lab = self.root / "lab"
        build_libs = lab / "entry/build/default/intermediates/libs/default/arm64-v8a"
        out = lab / "entry/libs/arm64-v8a"
        build_libs.mkdir(parents=True, exist_ok=True)
        out.mkdir(parents=True, exist_ok=True)
        (build_libs / "libentry.so").write_bytes(self.elfs["libentry.so"].read_bytes())
        for lib in LINK_LIBS:
            (out / lib).write_bytes((LIB_DIR / lib).read_bytes())
        (out / "libkeep.so").write_bytes(b"keep")
        result = subprocess.run(
            ["bash", str(SCRIPTS / "package_runtime_libs.sh"), str(lab)],
            env={**os.environ, "CJGUI_DEVICE_PACKAGING": "0"},
            capture_output=True, text=True,
        )
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        for lib in LINK_LIBS:
            self.assertFalse((out / lib).exists(), result.stdout)
        self.assertEqual((out / "libkeep.so").read_bytes(), b"keep")


if __name__ == "__main__":
    unittest.main()

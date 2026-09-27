#!/usr/bin/env python3
"""Check that the NDK link stub never shadows the system NativeWindow library."""

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
LINK_STUB = LIB_DIR / "libnative_window.so"
OWN_LIBS = (
    "libentry.so",
    "libcjgui_app.so",
    "libcjgui.so",
    "libcjgui_shared_operation_core.so",
    "libcjgui_settings_counter_application.so",
    "libcjgui_ohos_transport.so",
)


class NativeWindowPackagingTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.tmp = tempfile.TemporaryDirectory(prefix="cjgui-native-window-packaging-")
        cls.root = Path(cls.tmp.name)
        cls.elfs = {}
        source = cls.root / "entry.c"
        source.write_text(
            "extern int OH_NativeWindow_NativeObjectReference(void *);\n"
            "int cjgui_test_ref(void *window) {\n"
            "  return OH_NativeWindow_NativeObjectReference(window);\n"
            "}\n"
        )
        for lib in OWN_LIBS:
            cls.elfs[lib] = cls.root / lib
            subprocess.run([
                str(NATIVE / "llvm/bin/clang"), "--target=aarch64-linux-ohos",
                "-shared", "-fPIC", "-nostdlib", "-Wl,--no-as-needed",
                f"-Wl,-soname,{lib}", "-L", str(LIB_DIR),
                "-o", str(cls.elfs[lib]), str(source), "-lnative_window",
            ], check=True, capture_output=True, text=True)
        needed = subprocess.run([
            str(NATIVE / "llvm/bin/llvm-readobj"), "--needed-libs", str(cls.elfs["libentry.so"]),
        ], check=True, capture_output=True, text=True).stdout
        if "libnative_window.so" not in needed:
            raise AssertionError("fixture must retain DT_NEEDED libnative_window.so")

    @classmethod
    def tearDownClass(cls):
        cls.tmp.cleanup()

    def hap(self, name: str, include_stub: bool) -> Path:
        hap = self.root / name
        with zipfile.ZipFile(hap, "w", zipfile.ZIP_DEFLATED) as archive:
            for lib in OWN_LIBS:
                archive.write(self.elfs[lib], f"libs/arm64-v8a/{lib}")
            if include_stub:
                archive.write(LINK_STUB, "libs/arm64-v8a/libnative_window.so")
        return hap

    def verify(self, hap: Path) -> subprocess.CompletedProcess[str]:
        env = {**os.environ, "CJGUI_DEVICE_PACKAGING": "0"}
        return subprocess.run(
            ["bash", str(SCRIPTS / "verify_hap_closure.sh"), str(hap)],
            env=env, capture_output=True, text=True,
        )

    def test_closure_rejects_private_link_stub(self):
        result = self.verify(self.hap("with-stub.hap", True))
        self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("libnative_window.so", result.stdout)

    def test_closure_accepts_system_native_window_dependency(self):
        result = self.verify(self.hap("without-stub.hap", False))
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("RESULT: PASS", result.stdout)

    def test_package_removes_only_stale_native_window_stub(self):
        lab = self.root / "lab"
        build_libs = lab / "entry/build/default/intermediates/libs/default/arm64-v8a"
        out = lab / "entry/libs/arm64-v8a"
        build_libs.mkdir(parents=True, exist_ok=True)
        out.mkdir(parents=True, exist_ok=True)
        (build_libs / "libentry.so").write_bytes(self.elfs["libentry.so"].read_bytes())
        (out / "libnative_window.so").write_bytes(LINK_STUB.read_bytes())
        (out / "libkeep.so").write_bytes(b"keep")
        env = {**os.environ, "CJGUI_DEVICE_PACKAGING": "0"}
        result = subprocess.run(
            ["bash", str(SCRIPTS / "package_runtime_libs.sh"), str(lab)],
            env=env, capture_output=True, text=True,
        )
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertFalse((out / "libnative_window.so").exists(), result.stdout)
        self.assertEqual((out / "libkeep.so").read_bytes(), b"keep")


if __name__ == "__main__":
    unittest.main()

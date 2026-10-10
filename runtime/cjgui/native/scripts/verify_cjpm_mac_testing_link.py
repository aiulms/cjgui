#!/usr/bin/env python3
"""Link package tests against a private testing sidecar without changing normal artifacts.

The default only compiles/links tests. --filter runs the requested cjpm test
selection in the same isolated package. Logs and source hashes remain in --output.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import time


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path)
    parser.add_argument("--filter", help="Only execute this cjpm test selection; omitted means --no-run")
    args = parser.parse_args()
    runtime = Path(__file__).resolve().parents[2]
    output = (args.output or Path(tempfile.mkdtemp(prefix="cjgui-mac-test-link-"))).resolve()
    output.mkdir(parents=True, exist_ok=True)
    package = output / "package"
    if package.exists():
        parser.error("output already contains a package; use a fresh output directory")
    sdk = os.environ.get("CJ_GUI_SDKROOT")
    cangjie = os.environ.get("CANGJIE_HOME")
    if not sdk or not cangjie:
        parser.error("CJ_GUI_SDKROOT and CANGJIE_HOME must identify the installed SDK/toolchain")
    normal_archive = runtime / "native/lib/libcjgui_internal_renderer.a"
    normal_before = digest(normal_archive) if normal_archive.exists() else None
    inputs = [runtime / "cjpm.toml", runtime / "shared_operation_core/cjpm.toml",
              runtime / "native/cjgui_internal_renderer.m", runtime / "native/cjgui_native_bridge.m",
              runtime / "native/cjgui_internal_renderer.h", runtime / "native/cjgui_native_bridge.h"]
    inputs.extend(sorted((runtime / "src").rglob("*.cj")))
    inputs.extend(sorted((runtime / "shared_operation_core/src").rglob("*.cj")))
    fingerprints = {str(path.relative_to(runtime)): digest(path) for path in inputs}
    package.mkdir()
    shutil.copy2(runtime / "cjpm.toml", package / "cjpm.toml")
    shutil.copytree(runtime / "src", package / "src")
    core = package / "shared_operation_core"
    core.mkdir()
    shutil.copy2(runtime / "shared_operation_core/cjpm.toml", core / "cjpm.toml")
    shutil.copytree(runtime / "shared_operation_core/src", core / "src")
    native = package / "native/lib"
    native.mkdir(parents=True)
    env = dict(os.environ)
    env["DYLD_LIBRARY_PATH"] = str(Path(cangjie) / "runtime/lib/darwin_aarch64_cjnative")
    steps: list[dict] = []

    def run(label: str, command: list[str], cwd: Path = package) -> int:
        began = time.monotonic_ns()
        with (output / (label + ".log")).open("wb") as log:
            result = subprocess.run(command, cwd=cwd, env=env, stdout=log, stderr=subprocess.STDOUT)
        step = {"label": label, "command": command, "exit_code": result.returncode,
                "elapsed_ms": (time.monotonic_ns() - began) / 1e6}
        steps.append(step)
        print(json.dumps(step), flush=True)
        return result.returncode

    rc = 0
    flags = ["-fobjc-arc", "-fno-objc-msgsend-selector-stubs", "-fmodules",
             "-fstack-protector-strong", "-DCJGUI_INTERNAL_TESTING", "-isysroot", sdk,
             "-mmacosx-version-min=12.0"]
    for stem in ("cjgui_internal_renderer", "cjgui_native_bridge"):
        rc = run(stem, ["clang", *flags, "-c", str(runtime / "native" / (stem + ".m")),
                        "-o", str(native / (stem + ".o"))])
        if rc:
            break
    if not rc:
        rc = run("archive", ["ar", "rcs", str(native / "libcjgui_internal_renderer.a"),
                             str(native / "cjgui_internal_renderer.o"),
                             str(native / "cjgui_native_bridge.o")])
    if not rc:
        command = ["cjpm", "test", "--skip-script", "--target-dir", str(package / "target"),
                   "--no-color", "--no-progress"]
        command += ["--filter", args.filter] if args.filter else ["--no-run"]
        rc = run("cjpm-test", command)
    normal_after = digest(normal_archive) if normal_archive.exists() else None
    changed_inputs = [name for name, sha in fingerprints.items() if digest(runtime / name) != sha]
    result = {"exit_code": rc, "mode": "filtered_execution" if args.filter else "link_only",
              "steps": steps, "source_fingerprints": fingerprints,
              "source_changes_during_test": changed_inputs,
              "normal_archive_before": normal_before, "normal_archive_after": normal_after,
              "normal_archive_unchanged": normal_before == normal_after,
              "testing_macro_scope": "private output/package/native/lib only",
              "package": str(package), "normal_consumption_proven": False}
    (output / "result.json").write_text(json.dumps(result, indent=2) + "\n")
    return rc or (1 if changed_inputs or normal_before != normal_after else 0)


if __name__ == "__main__":
    raise SystemExit(main())

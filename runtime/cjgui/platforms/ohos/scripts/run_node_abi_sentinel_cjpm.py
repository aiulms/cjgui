#!/usr/bin/env python3
"""Host-side sentinel roundtrip for the H snapshot Node/Event ABI mirror.

Extracts the production @C structs verbatim from the H snapshot session source,
compiles the fixture C shim against the REAL snapshot header, and runs focused
Cangjie tests in a temporary cjpm package:

  Cangjie sentinel write -> C reads via the compiled header  (probe functions)
  C struct copy         -> Cangjie reads the copied struct  (field asserts)
  sizeOf<Cangjie mirror> == sizeof(C struct)                (layout lock)

This is the "仓颉→C→事件哨兵" gate the r10 review requires; it runs on the host
and never links a macOS renderer against the OHOS ABI.
"""

from __future__ import annotations

import argparse
import pathlib
import shutil
import subprocess
import sys
import tempfile


PLATFORM = pathlib.Path(__file__).resolve().parents[1]
SNAPSHOT = PLATFORM / "snapshot"
SESSION_SOURCE = SNAPSHOT / "src/runtime_renderer_session.cj"
HEADER = SNAPSHOT / "cjgui_internal_renderer.h"
SHIM_SOURCE = pathlib.Path(__file__).resolve().parent / "fixtures" / "node_abi_probe.c"
FIXTURE_TEST = pathlib.Path(__file__).resolve().parent / "fixtures" / "node_abi_sentinel_test.cj"

STRUCT_NAMES = ("CjguiInternalRendererComposableNode", "CjguiInternalRendererEvent")


def extract_struct(source: str, name: str) -> str:
    marker = f"@C\nstruct {name} {{"
    if source.count(marker) != 1:
        raise ValueError(f"expected one production struct: {name}")
    start = source.index(marker)
    depth = 0
    for offset in range(start + len(marker) - 1, len(source)):
        if source[offset] == "{":
            depth += 1
        elif source[offset] == "}":
            depth -= 1
            if depth == 0:
                return source[start:offset + 1]
    raise ValueError(f"production struct is incomplete: {name}")


def extracted_structs_source() -> str:
    text = SESSION_SOURCE.read_text(encoding="utf-8")
    blocks = [extract_struct(text, name) for name in STRUCT_NAMES]
    return "package cjgui\n\n" + "\n\n".join(blocks) + "\n"


def red_swap_semantic(source: str) -> str:
    """Test-only mutation: swap two adjacent same-width declarations while the
    named init still compiles — a silent layout drift the runtime sentinel
    probes must catch."""
    first = "    var semanticRole: UInt32 = 0\n"
    second = "    var semanticState: UInt32 = 0\n"
    if source.count(first) != 1 or source.count(second) != 1:
        raise ValueError("cannot apply semantic swap mutation exactly once")
    return source.replace(first + second, second + first)


def validate_sources() -> str:
    source = extracted_structs_source()
    for name in STRUCT_NAMES:
        if f"struct {name}" not in source:
            raise ValueError(f"struct extraction lost {name}")
    if "var acceptedBindingEpoch: UInt64 = 0" not in source:
        raise ValueError("node mirror lacks the binding tail field")
    fixture = FIXTURE_TEST.read_text(encoding="utf-8")
    for test_name in ("ohosNodeAbiMirrorSizeMatchesC",
                      "ohosNodeSentinelEpochAndNeighborFieldsPassThroughC",
                      "ohosNodeCopyThroughCReadsBackInCangjie",
                      "ohosEventAbiMirrorSizeAndGestureSentinel"):
        if f"func {test_name}(" not in fixture:
            raise ValueError(f"focused sentinel test missing: {test_name}")
    return source


def build_shim(work: pathlib.Path) -> pathlib.Path:
    libs = work / "libs"
    libs.mkdir(parents=True, exist_ok=True)
    if sys.platform == "darwin":
        lib_name = "libnode_abi_probe.dylib"
    elif sys.platform.startswith("linux"):
        lib_name = "libnode_abi_probe.so"
    else:
        raise SystemExit(f"unsupported host platform: {sys.platform}")
    completed = subprocess.run(
        ["clang", "-shared", "-fPIC", "-Wall", "-Wextra", "-Werror",
         "-I", str(HEADER.parent), str(SHIM_SOURCE), "-o", str(libs / lib_name)],
        capture_output=True,
        text=True,
    )
    if completed.returncode != 0:
        raise SystemExit(f"shim build failed:\n{completed.stderr}")
    return libs


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check-only", action="store_true",
                        help="validate source extraction without invoking cjpm")
    parser.add_argument("--red-swap-semantic", action="store_true",
                        help="test-only mutation: swap two adjacent declarations to prove the gate fails")
    args = parser.parse_args()
    structs = validate_sources()
    if args.red_swap_semantic:
        structs = red_swap_semantic(structs)
    if args.check_only:
        print("OK snapshot node/event structs extracted and focused sentinel tests present")
        return 0

    cjpm = shutil.which("cjpm")
    if cjpm is None:
        raise SystemExit("cjpm is unavailable; source the Cangjie 1.1.3 envsetup.sh first")
    with tempfile.TemporaryDirectory(prefix="cjgui-ohos-node-abi-") as tmp:
        work = pathlib.Path(tmp)
        project = work / "probe"
        project.mkdir()
        subprocess.run([cjpm, "init", "--name", "cjgui", "--type=static"], cwd=project, check=True)
        source_dir = project / "src"
        for sample in source_dir.glob("*.cj"):
            sample.unlink()
        (source_dir / "abi_mirror.cj").write_text(structs, encoding="utf-8")
        shutil.copy2(FIXTURE_TEST, source_dir / FIXTURE_TEST.name)
        libs = build_shim(work)
        toml = (project / "cjpm.toml").read_text(encoding="utf-8")
        toml += f'\n[ffi.c]\nnode_abi_probe = {{ path = "{libs}/" }}\n'
        (project / "cjpm.toml").write_text(toml, encoding="utf-8")
        subprocess.run([cjpm, "test", "--no-color", "--no-progress"], cwd=project, check=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

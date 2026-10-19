#!/usr/bin/env python3
"""Exercise the actual shared public submission and Windows ordinary restore.

The window methods are extracted verbatim. The macOS-only transfer branch is
constant-folded away using the production Windows capability predicates. Native
transport, scene storage and the owner are explicit boundary fixtures; no transfer
completion is constructed. This is a shared-function regression, not a window or
Windows/DWrite acceptance result. The archived normal fix25 run is the product RED.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
WINDOW = ROOT / "src/composable_ui_window.cj"
SESSION = ROOT / "src/runtime_renderer_session.cj"
SCENE = ROOT / "src/composable_ui.cj"
PAINT = ROOT / "src/composable_ui_selection_paint.cj"


def declaration(source: str, marker: str) -> str:
    assert source.count(marker) == 1, (marker, source.count(marker))
    start = source.index(marker)
    opening = source.index("{", start)
    depth = 0
    for i in range(opening, len(source)):
        depth += (source[i] == "{") - (source[i] == "}")
        if depth == 0:
            return source[start:i + 1]
    raise ValueError("incomplete declaration: " + marker)


def generate(withdraw: bool = False) -> tuple[str, dict]:
    window = WINDOW.read_text()
    if withdraw:
        wire = "this.freezeOrdinaryRestoreSelectionPaint(request, session, ordinaryPaintNative.value, ownerSelection)"
        assert window.count(wire) == 1
        window = window.replace(wire, "true /* Targeted withdrawal: ordinary restore -> paint basis only. */", 1)
    runtime = SESSION.read_text()
    scene = SCENE.read_text()
    methods = []
    for name, visibility in (
        ("submitAcceptedSourceSelection", "public"),
        ("advanceSelectionSubmission", "private"),
        ("stageSelectionSurface", "private"),
        ("publishSelectionSurface", "private"),
        ("pumpPendingSelectionRestore", "public"),
        ("freezeOrdinaryRestoreSelectionPaint", "private"),
        ("restageOrdinaryRestoreSelectionPaint", "private"),
        ("invalidateOrdinaryRestoreSelectionPaint", "private"),
    ):
        if name == "advanceSelectionSubmission" and f"    {visibility} func {name}(" not in window:
            continue
        text = declaration(window, f"    {visibility} func {name}(")
        if name == "submitAcceptedSourceSelection" and "let attempt =" in text:
            marker = "        if (cjguiUtf16Length(ticket.value) < 1024 && internalRendererSelectionTransferSupported())"
            text = text.replace(declaration(text, marker), "        // Production Windows transfer capability is false.", 1)
        if name == "pumpPendingSelectionRestore":
            marker = "        if ((request.commitSourceSelection || restoresOwnedSource) && ownerSelection.isSome() &&"
            branch = declaration(text, marker)
            assert "internalRendererInstalledRangeSupported()" in branch
            text = text.replace(branch, "        // Production Windows capability is false; transfer branch unreachable.", 1)
        methods.append(text.replace(f"    {visibility} func", "    func", 1))
    # Select the Windows overload, retaining the ordinary-restore branch only;
    # the old transfer route remains covered by its existing consumer tests.
    text = declaration(window, '    private func restageAcceptedPreviewSelectionDecoration(): Unit {\n        let publication')
    methods.append(text.replace('    private func', '    func', 1))
    paint = PAINT.read_text()
    declarations = [declaration(paint, marker) for marker in (
        'class CjguiSelectionPaintNativeRestore {',
        'class CjguiSelectionPaintNativeRestoreBox {',
        'public class CjguiAcceptedSelectionPaintBasis {',
        'public interface CjguiComposableUiSelectionPaintProvider {',
        'enum CjguiPreviewSelectionPaintPublication {',
    )]
    predicates = []
    for name, value in (("internalRendererInstalledRangeSupported", "false"),
                        ("internalRendererSelectionTransferSupported", "false"),
                        ("internalRendererSourceRangeSupported", "true")):
        pattern = rf"func {name}\(\): Bool \{{ {value} \}}"
        matches = re.findall(pattern, runtime)
        assert len(matches) == 1, (name, matches)
        predicates.append(matches[0])
    constants = []
    for name in ("CJGUI_COMPOSABLE_UI_TEXT", "CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT"):
        matches = re.findall(rf"public let {name}: Int64 = \d+", scene)
        assert len(matches) == 1, name
        constants.append(matches[0])
    fixture = (HERE / "fixture.cj.in").read_text()
    generated = fixture.replace("// @PRODUCTION_CONSTANTS@", "\n".join(constants + predicates))
    generated = generated.replace("// @PRODUCTION_PAINT_TYPES@", "\n\n".join(declarations))
    generated = generated.replace("    // @PRODUCTION_WINDOW_METHODS@", "\n\n".join(methods))
    return generated, {"WindowSha256": hashlib.sha256(WINDOW.read_bytes()).hexdigest(),
                       "RuntimeSha256": hashlib.sha256(SESSION.read_bytes()).hexdigest(),
                       "PaintSha256": hashlib.sha256(PAINT.read_bytes()).hexdigest(),
                       "Methods": [re.search(r"\bfunc (\w+)\(", method).group(1) for method in methods],
                       "WindowsTransferAndInstalledRange": False,
                       "BoundaryFixtures": ["native transport", "scene storage", "owner commit", "request admission"]}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--work-root", type=Path, required=True)
    parser.add_argument("--evidence", type=Path, required=True)
    parser.add_argument("--withdraw", action="store_true")
    parser.add_argument("--source-root", type=Path, default=ROOT)
    args = parser.parse_args()
    global WINDOW, SESSION, SCENE, PAINT
    WINDOW = args.source_root / "src/composable_ui_window.cj"
    SESSION = args.source_root / "src/runtime_renderer_session.cj"
    SCENE = args.source_root / "src/composable_ui.cj"
    PAINT = args.source_root / "src/composable_ui_selection_paint.cj"
    args.work_root.mkdir(parents=True, exist_ok=True)
    assert shutil.disk_usage(args.work_root).free > 20 * 1024**3, "host reserve below 20GiB"
    generated, identity = generate(args.withdraw)
    args.evidence.parent.mkdir(parents=True, exist_ok=True)
    args.evidence.with_suffix(".cj").write_text(generated)
    with tempfile.TemporaryDirectory(prefix="ordinary-restore-", dir=args.work_root) as temporary:
        work = Path(temporary)
        source = work / "main.cj"
        binary = work / "ordinary-restore"
        source.write_text(generated)
        compile_result = subprocess.run(["cjc", str(source), "-Woff", "unused", "-o", str(binary)], text=True, capture_output=True)
        run = None
        if compile_result.returncode == 0:
            run = subprocess.run([str(binary)], text=True, capture_output=True)
        record = {**identity, "TargetedWithdrawal": args.withdraw,
                  "GeneratedSha256": hashlib.sha256(generated.encode()).hexdigest(),
                  "CompilerExit": compile_result.returncode,
                  "CompilerOutput": compile_result.stdout + compile_result.stderr,
                  "Exit": None if run is None else run.returncode,
                  "Stdout": "" if run is None else run.stdout,
                  "Stderr": "" if run is None else run.stderr,
                  "Scope": "actual shared public submission and ordinary restore decisions; boundary fixtures",
                  "TemporaryWorkRetired": True}
        args.evidence.write_text(json.dumps(record, ensure_ascii=False, indent=2) + "\n")
        print(record["CompilerOutput"])
        print(record["Stdout"], end="")
        print(record["Stderr"], end="")
        return compile_result.returncode if run is None else run.returncode


if __name__ == "__main__":
    raise SystemExit(main())

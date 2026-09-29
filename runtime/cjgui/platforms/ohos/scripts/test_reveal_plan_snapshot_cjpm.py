#!/usr/bin/env python3
"""Run the actual HarmonyOS snapshot reveal and binding decisions on the host.

The temporary package contains the production planner file, the production
rectangle class and accepted-binding methods extracted verbatim from the H
snapshot, and focused Cangjie tests. It never links a macOS renderer against
the OHOS ABI or writes to either consumer's generated source tree.
"""

from __future__ import annotations

import argparse
from pathlib import Path
import re
import shutil
import subprocess
import tempfile


SNAPSHOT = Path(__file__).resolve().parents[1] / "snapshot" / "src"
RECT_SOURCE = SNAPSHOT / "composable_ui.cj"
PLAN_SOURCE = SNAPSHOT / "composable_ui_reveal_plan.cj"
TEST_SOURCE = SNAPSHOT / "composable_ui_reveal_plan_test.cj"
WINDOW_SOURCE = SNAPSHOT / "composable_ui_window.cj"
BINDING_TEST_SOURCE = Path(__file__).resolve().parent / "fixtures" / "binding_epoch_snapshot_test.cj"
FOCUS_RETRY_TEST_SOURCE = Path(__file__).resolve().parent / "fixtures" / "focus_retry_snapshot_test.cj"
RENDERER_SESSION_SOURCE = SNAPSHOT / "runtime_renderer_session.cj"


def production_rect_source() -> str:
    text = RECT_SOURCE.read_text(encoding="utf-8")
    marker = "public class CjguiComposableUiRect {"
    if text.count(marker) != 1:
        raise ValueError("expected one production CjguiComposableUiRect declaration")
    start = text.index(marker)
    depth = 0
    for offset in range(start + len(marker) - 1, len(text)):
        if text[offset] == "{":
            depth += 1
        elif text[offset] == "}":
            depth -= 1
            if depth == 0:
                return "package cjgui\n\n" + text[start:offset + 1] + "\n"
    raise ValueError("production CjguiComposableUiRect declaration is incomplete")


def production_method(source: str, name: str) -> str:
    marker = f"    private func {name}("
    if source.count(marker) != 1:
        raise ValueError(f"expected one snapshot window method: {name}")
    start = source.index(marker)
    opening = source.index("{", start)
    depth = 0
    for offset in range(opening, len(source)):
        if source[offset] == "{":
            depth += 1
        elif source[offset] == "}":
            depth -= 1
            if depth == 0:
                return source[start:offset + 1]
    raise ValueError(f"snapshot window method is incomplete: {name}")


def production_top_level_function(source: str, name: str) -> str:
    marker = f"func {name}("
    if source.count(marker) != 1:
        raise ValueError(f"expected one snapshot focus function: {name}")
    start = source.index(marker)
    opening = source.index("{", start)
    depth = 0
    for offset in range(opening, len(source)):
        if source[offset] == "{":
            depth += 1
        elif source[offset] == "}":
            depth -= 1
            if depth == 0:
                return source[start:offset + 1]
    raise ValueError(f"snapshot focus function is incomplete: {name}")


def production_binding_harness() -> str:
    window = WINDOW_SOURCE.read_text(encoding="utf-8")
    methods = "\n\n".join(production_method(window, name) for name in (
        "nativeSemanticBindingKey", "candidateBindingEpoch", "publishAcceptedBindingEpochs",
        "currentAcceptedBindingEpoch"))
    # These stand-ins only supply the records and accepted-scene storage the
    # extracted production methods read. Their comparison and epoch decisions
    # are compiled verbatim from the H snapshot above.
    return '''package cjgui

import std.collection.*

class CjguiComposableUiLayoutNode {
    public let nodeId: Int64
    public let identityKey: String
    public let semanticId: String
    public let actionName: String
    public let fieldId: String
    public let operationActionName: String
    public let resourceId: Int64
    public let operationResourceId: Int64
    public let nodeKind: Int64
    public let semanticIncarnation: Int64
    init(nodeId: Int64, identityKey: String, semanticId: String, actionName: String, fieldId: String,
        operationActionName: String, resourceId: Int64, operationResourceId: Int64, nodeKind: Int64,
        semanticIncarnation: Int64) {
        this.nodeId = nodeId
        this.identityKey = identityKey
        this.semanticId = semanticId
        this.actionName = actionName
        this.fieldId = fieldId
        this.operationActionName = operationActionName
        this.resourceId = resourceId
        this.operationResourceId = operationResourceId
        this.nodeKind = nodeKind
        this.semanticIncarnation = semanticIncarnation
    }
}

class CjguiComposableUiScene {
    let version: Int64
    private let values: ArrayList<CjguiComposableUiLayoutNode>
    init(version: Int64, values: ArrayList<CjguiComposableUiLayoutNode>) {
        this.version = version
        this.values = values
    }
    func nodes(): ArrayList<CjguiComposableUiLayoutNode> { return values }
}

class CjguiComposableUiWindow {
    private var nativeInputScene = CjguiComposableUiScene(0, ArrayList<CjguiComposableUiLayoutNode>())
    private var acceptedBindingKeys = ArrayList<String>()
    private var acceptedBindingEpochs = ArrayList<UInt64>()
''' + methods + '''

    func acceptScene(version: Int64, nodes: ArrayList<CjguiComposableUiLayoutNode>): Unit {
        let scene = CjguiComposableUiScene(version, nodes)
        publishAcceptedBindingEpochs(scene)
        nativeInputScene = scene
    }
    func epochFor(node: CjguiComposableUiLayoutNode): UInt64 {
        return currentAcceptedBindingEpoch(node)
    }
    func candidateEpochFor(node: CjguiComposableUiLayoutNode, version: Int64): UInt64 {
        return candidateBindingEpoch(node, version)
    }
}
'''


def production_focus_retry_harness() -> str:
    window = WINDOW_SOURCE.read_text(encoding="utf-8")
    renderer_session = RENDERER_SESSION_SOURCE.read_text(encoding="utf-8")
    constant_names = ("CJGUI_SEMANTIC_FOCUS_MAX_ATTEMPTS", "CJGUI_INTERNAL_RENDERER_NOT_MAIN_THREAD",
                      "CJGUI_INTERNAL_RENDERER_VIEW_INVALIDATED", "CJGUI_INTERNAL_RENDERER_GEOMETRY_EMPTY",
                      "CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR")
    constants = []
    for name in constant_names:
        source = window if name == "CJGUI_SEMANTIC_FOCUS_MAX_ATTEMPTS" else renderer_session
        matches = re.findall(rf"^(?:private )?let {name}: Int(?:32|64) = \d+", source, re.M)
        if len(matches) != 1:
            raise ValueError(f"expected one snapshot focus constant: {name}")
        constants.append(matches[0])
    methods = []
    for name in ("cjguiFocusRetryAllowed", "cjguiFocusNextAttemptCount",
                 "cjguiFocusNativeFailureIsRetryable"):
        methods.append(production_top_level_function(window, name))
    return "package cjgui\n\n" + "\n".join(constants) + "\n\n" + "\n\n".join(methods) + "\n"


def validate_sources() -> str:
    rect = production_rect_source()
    planner = PLAN_SOURCE.read_text(encoding="utf-8")
    tests = TEST_SOURCE.read_text(encoding="utf-8")
    window = WINDOW_SOURCE.read_text(encoding="utf-8")
    if "class CjguiComposableUiRevealPlanner" not in planner or not planner.startswith("package cjgui\n"):
        raise ValueError("snapshot production reveal planner is missing")
    if "CjguiComposableUiRevealPlanner.plan(" not in window:
        raise ValueError("snapshot window no longer consumes the production planner")
    for name in ("ohosRevealPlanReplacesIncompatiblePendingInnerRequest",
                 "ohosRevealPlanKeepsFeasiblePendingInnerRequest",
                 "ohosRevealPlanLeavesRequestsUntouchedWhenClipIsUnreachable"):
        if f"func {name}(" not in tests:
            raise ValueError(f"focused snapshot test missing: {name}")
    production_binding_harness()
    production_focus_retry_harness()
    if "func ohosAcceptedBindingEpochRejectsSameValueNewIncarnationAndAba(" not in BINDING_TEST_SOURCE.read_text():
        raise ValueError("focused snapshot binding test is missing")
    if "func ohosCheckedFocusGeometryRaceGetsBoundedRetry(" not in FOCUS_RETRY_TEST_SOURCE.read_text():
        raise ValueError("focused snapshot retry test is missing")
    return rect


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check-only", action="store_true", help="validate source wiring without invoking cjpm")
    parser.add_argument("--no-run", action="store_true", help="compile the isolated Cangjie tests only")
    parser.add_argument("--red-omit-incarnation", action="store_true",
                        help="test-only mutation of the extracted binding key to prove the ABA test fails")
    args = parser.parse_args()
    rect = validate_sources()
    if args.check_only:
        print("OK snapshot planner, rectangle, binding method extraction, window consumer, and focused tests")
        return 0

    cjpm = shutil.which("cjpm")
    if cjpm is None:
        raise SystemExit("cjpm is unavailable; source the Cangjie 1.1.3 envsetup.sh first")
    with tempfile.TemporaryDirectory(prefix="cjgui-ohos-reveal-plan-") as tmp:
        project = Path(tmp)
        subprocess.run([cjpm, "init", "--name", "cjgui", "--type=static"], cwd=project, check=True)
        source_dir = project / "src"
        for sample in source_dir.glob("*.cj"):
            sample.unlink()
        (source_dir / "composable_ui_rect.cj").write_text(rect, encoding="utf-8")
        binding_harness = production_binding_harness()
        if args.red_omit_incarnation:
            old = ":${node.nodeKind}:${node.semanticIncarnation}"
            if binding_harness.count(old) != 1:
                raise ValueError("cannot apply binding-key RED mutation exactly once")
            binding_harness = binding_harness.replace(old, ":${node.nodeKind}", 1)
        (source_dir / "binding_epoch_harness.cj").write_text(binding_harness, encoding="utf-8")
        (source_dir / "focus_retry_harness.cj").write_text(production_focus_retry_harness(), encoding="utf-8")
        shutil.copy2(PLAN_SOURCE, source_dir / PLAN_SOURCE.name)
        shutil.copy2(TEST_SOURCE, source_dir / TEST_SOURCE.name)
        shutil.copy2(BINDING_TEST_SOURCE, source_dir / BINDING_TEST_SOURCE.name)
        shutil.copy2(FOCUS_RETRY_TEST_SOURCE, source_dir / FOCUS_RETRY_TEST_SOURCE.name)
        command = [cjpm, "test", "--no-color", "--no-progress"]
        if args.no_run:
            command.append("--no-run")
        subprocess.run(command, cwd=project, check=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

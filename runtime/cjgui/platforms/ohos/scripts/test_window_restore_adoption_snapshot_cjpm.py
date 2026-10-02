#!/usr/bin/env python3
"""H1-R.c：在**生产窗口接缝**上跑恢复采纳的确定性反例（仓颉，不是 C++ 摘录）。

被测的两处窗口决策都从 H 快照逐字抽取，任何改名/改签名都会让本 harness 编译失败：

  1. kind-33（平台 selection）分支 —— `adoptOwnedTextSelection` 的三态结果决定要不要
     记账。`NAMED_STALE`（恢复期/镜像陈旧且不是人类锚）时窗口**不得**覆盖当前焦点、
     选区、页面书签，也不得把它当成一次选区变更交给消费者。实测后果（09-30 04:17）：
     隐藏代理在被拒绝期间自己往前走（`ime select [19,19)…[24,24)`），拒绝恢复把越界
     落点当规范值读走，在 bounds 守卫上白烧完 8 次有界重试预算，只签发 1 张票据，
     `PHAROS_OHOS_RESTORE_ADOPTED` 从未出现，13 笔输入全部具名拒绝。
  2. `onPlatformProxyRestoreReceipt` —— 只有 WindowAdopted 是成功终态。票据已结清、
     平台已实际安装，但会话按 owner 版本守卫拒绝采纳这份落点时（ACK(v1) 入队后 Agent
     把 owner 推到 v2），窗口不得记成功、不得回写焦点/书签，必须具名失败并请求新投影。

替身边界（明确记账，避免"测了个替身"）：数据记录（node/scene 存储/pump 事件/票据）、
FFI 入口、`setSelection16` 的钳制与字节映射、`refreshPageFocusBookmark` 的书签存储、
控制器派发都是最小替身；**决策文本全部逐字来自生产**，包括 scene 的 `nodeForId` /
`resolveSelection`、绑定代次四件套、会话的 `canAdoptNativeRestore` / `confirmProxyRestored`
/ `adoptNativeSelectionRestored` / `needsNativeSelectionRestore`。

`--selftest` 施加两处只影响被测守卫的变异，要求对应判据变红（证明判据非空转）。
"""

from __future__ import annotations

import argparse
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile


HERE = Path(__file__).resolve().parent
SNAPSHOT = HERE.parent / "snapshot" / "src"
WINDOW_SOURCE = SNAPSHOT / "composable_ui_window.cj"
SCENE_SOURCE = SNAPSHOT / "composable_ui.cj"
SESSION_SOURCE = SNAPSHOT / "text_session.cj"
TEST_SOURCE = HERE / "fixtures" / "window_restore_adoption_snapshot_test.cj"

WINDOW_METHODS = (
    "adoptOwnedTextSelection", "rememberInteraction", "onPlatformProxyRestoreReceipt",
    "noteOwnedTextSessionRestoreFailure", "nativeSemanticBindingKey", "candidateBindingEpoch",
    "publishAcceptedBindingEpochs", "currentAcceptedBindingEpoch", "restoreOwnedTextSelectionAfterAcceptedScene")
SCENE_METHODS = ("nodeForId", "resolveSelection")
SESSION_METHODS = ("needsNativeSelectionRestore", "canAdoptNativeRestore", "confirmProxyRestored",
                   "adoptNativeSelectionRestored")

KIND33_START = "} else if (nativeEvent.eventKind == 33u32) {"
KIND33_END = "} else if (nativeEvent.eventKind == 41u32) {"

RED_GUARDS = {
    "adoption-result": (
        "            if (!session.adoptNativeSelectionRestored(pending.sessionContentVersion, installedStart,\n"
        "                installedEnd)) {\n",
        "            if (!session.adoptNativeSelectionRestored(pending.sessionContentVersion, installedStart,\n"
        "                installedEnd) && false) {\n",
    ),
    "named-stale": (
        "                    if (adoption != CJGUI_OWNED_SELECTION_NAMED_STALE) {\n",
        "                    if (adoption != CJGUI_OWNED_SELECTION_NOT_OWNED) {\n",
    ),
}


def balanced(source: str, start: int, label: str) -> str:
    opening = source.index("{", start)
    depth = 0
    for offset in range(opening, len(source)):
        if source[offset] == "{":
            depth += 1
        elif source[offset] == "}":
            depth -= 1
            if depth == 0:
                return source[start:offset + 1]
    raise ValueError(f"declaration is incomplete: {label}")


def production_member(source: str, marker: str, label: str) -> str:
    if source.count(marker) != 1:
        raise ValueError(f"expected exactly one production member {label}, found {source.count(marker)}")
    return balanced(source, source.index(marker), label)


def private_method(name: str) -> str:
    source = WINDOW_SOURCE.read_text(encoding="utf-8")
    text = production_member(source, f"    private func {name}(", f"window method {name}")
    # 只做可见性改写（测试文件要直接驱动这两个接缝）；签名与函数体一个字符不改。
    return text.replace(f"    private func {name}(", f"    func {name}(", 1)


def public_method(path: Path, name: str) -> str:
    source = path.read_text(encoding="utf-8")
    return production_member(source, f"    public func {name}(", f"{path.name} method {name}")


def production_constants(path: Path, names: tuple[str, ...], visibility: str) -> str:
    source = path.read_text(encoding="utf-8")
    lines = []
    for name in names:
        matches = re.findall(rf"^{visibility} let {name}: Int64 = \d+$", source, re.M)
        if len(matches) != 1:
            raise ValueError(f"expected one production constant {name}, found {len(matches)}")
        lines.append(matches[0])
    return "\n".join(lines)


def production_pending_class() -> str:
    source = WINDOW_SOURCE.read_text(encoding="utf-8")
    text = production_member(source, "private class CjguiPendingPlatformRestore {",
                            "CjguiPendingPlatformRestore")
    # 生产里它是 private；harness 的测试文件要直接构造这张冻结票据。
    return text.replace("private class CjguiPendingPlatformRestore {",
                        "class CjguiPendingPlatformRestore {", 1)


def production_kind33_branch() -> str:
    source = WINDOW_SOURCE.read_text(encoding="utf-8")
    if source.count(KIND33_START) != 1 or source.count(KIND33_END) != 1:
        raise ValueError("expected exactly one kind-33 / kind-41 branch pair in the FIFO drain")
    start = source.index(KIND33_START)
    end = source.index(KIND33_END)
    if end <= start:
        raise ValueError("kind-33 branch markers are out of order")
    return source[start:end]


def production_harness(red: str | None) -> str:
    tri_state = production_constants(WINDOW_SOURCE, ("CJGUI_OWNED_SELECTION_NOT_OWNED",
                                                     "CJGUI_OWNED_SELECTION_ADOPTED",
                                                     "CJGUI_OWNED_SELECTION_NAMED_STALE"), "private")
    node_kinds = production_constants(SCENE_SOURCE, ("CJGUI_COMPOSABLE_UI_TEXT_INPUT",
                                                     "CJGUI_COMPOSABLE_UI_INTEGER_INPUT",
                                                     "CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT"),
                                      "public")
    window_methods = "\n\n".join(private_method(name) for name in WINDOW_METHODS)
    scene_methods = "\n\n".join(public_method(SCENE_SOURCE, name) for name in SCENE_METHODS)
    session_methods = "\n\n".join(public_method(SESSION_SOURCE, name) for name in SESSION_METHODS)
    pending_class = production_pending_class()
    branch = production_kind33_branch()
    if red is not None:
        old, new = RED_GUARDS[red]
        if window_methods.count(old) != 1 and branch.count(old) != 1:
            raise ValueError(f"cannot apply RED mutation exactly once: {red}")
        window_methods = window_methods.replace(old, new, 1)
        branch = branch.replace(old, new, 1)

    return f'''package cjgui

import std.collection.*

{node_kinds}

{tri_state}

// ---- 最小替身：字段名/类型逐字抄生产声明，改名即编译失败 ----

struct InternalRendererPumpResult {{
    let eventKind: UInt32
    let recordIndex: UInt32
    let selectionStart: UInt32
    let selectionEnd: UInt32
    let nodeId: UInt64
    let projectionVersion: UInt64
    let resourceId: Int64
    let nodeKind: UInt32
    let bindingEpoch: UInt64
    let acceptedBindingEpoch: UInt64
    init(eventKind: UInt32, recordIndex: UInt32, selectionStart: UInt32, selectionEnd: UInt32,
        nodeId: UInt64, projectionVersion: UInt64, resourceId: Int64, nodeKind: UInt32,
        bindingEpoch: UInt64, acceptedBindingEpoch: UInt64) {{
        this.eventKind = eventKind
        this.recordIndex = recordIndex
        this.selectionStart = selectionStart
        this.selectionEnd = selectionEnd
        this.nodeId = nodeId
        this.projectionVersion = projectionVersion
        this.resourceId = resourceId
        this.nodeKind = nodeKind
        this.bindingEpoch = bindingEpoch
        this.acceptedBindingEpoch = acceptedBindingEpoch
    }}
}}

struct InternalRendererProxyRestoreTicket {{
    let requestId: UInt64
    let contextId: Int64
    let contextGeneration: UInt64
    let acceptedBindingEpoch: UInt64
    let acceptedProjectionVersion: UInt64
    let canonicalStart: Int64
    let canonicalEnd: Int64
    init(requestId: UInt64, contextId: Int64, contextGeneration: UInt64, acceptedBindingEpoch: UInt64,
        acceptedProjectionVersion: UInt64, canonicalStart: Int64, canonicalEnd: Int64) {{
        this.requestId = requestId
        this.contextId = contextId
        this.contextGeneration = contextGeneration
        this.acceptedBindingEpoch = acceptedBindingEpoch
        this.acceptedProjectionVersion = acceptedProjectionVersion
        this.canonicalStart = canonicalStart
        this.canonicalEnd = canonicalEnd
    }}
}}

class CjguiComposableUiLayoutNode {{
    let nodeId: Int64
    let identityKey: String
    let semanticId: String
    let actionName: String
    let fieldId: String
    let operationActionName: String
    let resourceId: Int64
    let operationResourceId: Int64
    let nodeKind: Int64
    let semanticIncarnation: Int64
    let isEnabled: Bool
    let value: String
    init(nodeId: Int64, identityKey: String, semanticId: String, actionName: String, fieldId: String,
        operationActionName: String, resourceId: Int64, operationResourceId: Int64, nodeKind: Int64,
        semanticIncarnation: Int64, isEnabled!: Bool = true, value!: String = "") {{
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
        this.isEnabled = isEnabled
        this.value = value
    }}
    public static func missing(): CjguiComposableUiLayoutNode {{
        return CjguiComposableUiLayoutNode(-1, "", "", "", "", "", -1, -1, 0, 0)
    }}
}}

class CjguiComposableUiEvent {{
    let node: CjguiComposableUiLayoutNode
    let eventKind: Int64
    let text: String
    let selectionStart: Int64
    let selectionEnd: Int64
    let projectionVersion: Int64
    init(node: CjguiComposableUiLayoutNode, eventKind: Int64, text: String, selectionStart: Int64,
        selectionEnd: Int64, projectionVersion: Int64) {{
        this.node = node
        this.eventKind = eventKind
        this.text = text
        this.selectionStart = selectionStart
        this.selectionEnd = selectionEnd
        this.projectionVersion = projectionVersion
    }}
}}

class CjguiComposableUiDispatchResult {{
    let didApply: Bool
    let shouldClose: Bool
    init(didApply: Bool, shouldClose!: Bool = false) {{
        this.didApply = didApply
        this.shouldClose = shouldClose
    }}
}}

class CjguiComposableUiWindowPumpResult {{
    let isOpen: Bool
    let didApplyHumanAction: Bool
    init(isOpen: Bool, didApplyHumanAction: Bool) {{
        this.isOpen = isOpen
        this.didApplyHumanAction = didApplyHumanAction
    }}
}}

class CjguiComposableUiScene {{
    let version: Int64
    let resolvedNodes: ArrayList<CjguiComposableUiLayoutNode>
    let validValue: Bool
    init(version: Int64, nodes: ArrayList<CjguiComposableUiLayoutNode>, valid!: Bool = true) {{
        this.version = version
        this.resolvedNodes = nodes
        this.validValue = valid
    }}
    public func nodes(): ArrayList<CjguiComposableUiLayoutNode> {{
        return ArrayList<CjguiComposableUiLayoutNode>(resolvedNodes)
    }}

{scene_methods}
}}

class CjguiTextSessionMirrorSnapshot {{
    let contentVersion: Int64
    let sourceVersion: Int64
    let text: String
    let prepared: Bool
    init(contentVersion: Int64, sourceVersion: Int64, text: String, prepared!: Bool = true) {{
        this.contentVersion = contentVersion
        this.sourceVersion = sourceVersion
        this.text = text
        this.prepared = prepared
    }}
}}

/// owner 边界守卫的替身。生产里 `confirmContentVersion` 属于消费方文档；harness 用
/// "第 N 次成功提交之后把 owner 推到 v2" 确定性地复现 H1-R.c 的静态交织。
class HarnessSessionWindow {{
    var sourceVersion: Int64 = 1
    var prepared: Bool = true
    var confirmCalls: Int64 = 0
    var advanceAfterConfirmCalls: Int64 = 0
    var advanceToVersion: Int64 = 0
    func contentVersion(): Int64 {{
        return sourceVersion
    }}
    func isPrepared(): Bool {{
        return prepared
    }}
    func unpreparedReason(): String {{
        return if (prepared) {{ "" }} else {{ "owner_unprepared" }}
    }}
    func confirmContentVersion(action: () -> Bool): Bool {{
        confirmCalls += 1
        let committed = action()
        if (committed && advanceAfterConfirmCalls > 0 && confirmCalls >= advanceAfterConfirmCalls &&
            advanceToVersion != sourceVersion) {{
            sourceVersion = advanceToVersion
        }}
        return committed
    }}
}}

class CjguiTextSession {{
    let window = HarnessSessionWindow()
    var selectionNeedsNativeRestore: Bool = false
    var needsCalibration: Bool = false
    var calibrationRecalibrated: Bool = false
    var contextEpoch: Int64 = 1
    var mirrorRevision: Int64 = 2
    var mirrorUtf16Length: Int64 = 18
    var selStart16: Int64 = 0
    var selEnd16: Int64 = 0
    var selectionVersion: Int64 = 0
    var lastReason: String = ""
    /// 人类锚的会话侧能力由 native harness 与设备验收覆盖（12/12）；这里只做脚本化
    /// 替身，被测的是窗口拿到锚结果之后的三态决策。
    var scriptedCanAnchor: Bool = false
    var scriptedAnchorAdopted: Bool = true
    var setSelection16Calls: Int64 = 0
    var anchorAdoptCalls: Int64 = 0
    func contentVersion(): Int64 {{
        return window.contentVersion()
    }}
    func boundNode(): Int64 {{ return 107 }}
    func selection16(): (Int64, Int64) {{ return (selStart16, selEnd16) }}
    func contextEpochValue(): Int64 {{ return contextEpoch }}
    func mirrorSnapshot(): CjguiTextSessionMirrorSnapshot {{
        return CjguiTextSessionMirrorSnapshot(window.contentVersion(), window.sourceVersion, "mirror")
    }}
    func canAnchorHumanSelection16(start16: Int64, end16: Int64): Bool {{
        let _ = start16
        let _ = end16
        return scriptedCanAnchor
    }}
    func anchorHumanSelection16(anchorSeq: Int64, start16: Int64, end16: Int64): Bool {{
        anchorAdoptCalls += 1
        let _ = anchorSeq
        if (!scriptedAnchorAdopted) {{
            lastReason = "human_anchor_source_stale"
            return false
        }}
        selStart16 = start16
        selEnd16 = end16
        selectionNeedsNativeRestore = false
        lastReason = ""
        return true
    }}
    func setSelection16(start16: Int64, end16: Int64): Unit {{
        setSelection16Calls += 1
        selStart16 = start16
        selEnd16 = end16
        selectionVersion = window.contentVersion()
    }}

{session_methods}
}}

/// native FFI 的脚本化替身：锚一经取走即 consumed，票据消费结果由测试设定。
var harnessAnchorStatus: Int32 = 0
var harnessAnchorSeq: Int64 = 0
var harnessAnchorCalls: Int64 = 0
var harnessTicketConsumeResult: Bool = true
var harnessTicketConsumeCalls: Int64 = 0
var harnessRestoreIssueCalls: Int64 = 0
let CJGUI_INTERNAL_RENDERER_OK: Int32 = 0

func internalRendererRecoverTextProxyTicket(session: UInt64, nodeId: Int64, resourceId: Int64,
    nodeKind: Int64, version: Int64, text: String, start: Int64,
    end: Int64): (Int32, InternalRendererProxyRestoreTicket) {{
    let _ = (session, nodeId, resourceId, nodeKind, text)
    harnessRestoreIssueCalls += 1
    return (0, InternalRendererProxyRestoreTicket(UInt64(harnessRestoreIssueCalls), 7, 3u64,
        UInt64(version), UInt64(version), start, end))
}}

func internalRendererTakeHumanSelectionAnchor(session: UInt64, nodeId: Int64, resourceId: Int64,
    nodeKind: Int64, projectionVersion: Int64, acceptedBindingEpoch: Int64,
    start16: Int64, end16: Int64): (Int32, Int64) {{
    harnessAnchorCalls += 1
    let _ = (session, nodeId, resourceId, nodeKind, projectionVersion, acceptedBindingEpoch, start16, end16)
    return (harnessAnchorStatus, harnessAnchorSeq)
}}

func internalRendererConsumeProxyRestoreTicket(session: UInt64, requestId: UInt64,
    adoptedStart: Int64, adoptedEnd: Int64): Bool {{
    harnessTicketConsumeCalls += 1
    let _ = (session, requestId, adoptedStart, adoptedEnd)
    return harnessTicketConsumeResult
}}

class HarnessController {{
    let appliedKinds = ArrayList<Int64>()
    let appliedSelections = ArrayList<Int64>()
    var scriptedResult = CjguiComposableUiDispatchResult(true)
    func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {{
        appliedKinds.add(event.eventKind)
        appliedSelections.add(event.selectionStart)
        appliedSelections.add(event.selectionEnd)
        return scriptedResult
    }}
}}

{pending_class}

class CjguiComposableUiWindow {{
    let sessionToken: UInt64 = 4242u64
    var isWindowOpen: Bool = true
    var lastNativeStatus: Int32 = 0
    let controller = HarnessController()
    var nativeInputScene = CjguiComposableUiScene(0, ArrayList<CjguiComposableUiLayoutNode>())
    var acceptedBindingKeys = ArrayList<String>()
    var acceptedBindingEpochs = ArrayList<UInt64>()
    var ownedTextSession: ?CjguiTextSession = None
    var ownedTextSessionNodeId: Int64 = -1
    var ownedTextSessionResourceId: Int64 = -1
    var ownedTextSessionNodeKind: Int64 = 10
    var ownedSelectionRestoreAttempts: Int64 = 0
    var ownedSelectionRestoreEpoch: Int64 = -1
    var ownedSelectionRestoreVersion: Int64 = -1
    var ownedSelectionRestoreBinding: UInt64 = 0u64
    var ownedSelectionRestoreExhausted: Bool = false
    var humanSelectionAnchorsAdopted: Int64 = 0
    var staleOwnedSelectionEvents: Int64 = 0
    var focusedNodeId: Int64 = -1
    var focusedResourceId: Int64 = -1
    var focusedNodeKind: Int64 = -1
    var focusedSelectionStart: Int64 = 0
    var focusedSelectionEnd: Int64 = 0
    var interactionVersion: Int64 = 0
    var pendingPlatformRestore: ?CjguiPendingPlatformRestore = None
    var textSessionRestores: Int64 = 0
    var textSessionRestoreFailures: Int64 = 0
    var lastNativeFailure: String = ""
    var refusedRangeTextPending: Bool = false
    var refusedRangeTextNodeId: Int64 = -1
    var refusedRangeTextResourceId: Int64 = -1
    var refusedRangeTextNodeKind: Int64 = -1
    var refusedRangeTextRecoveries: Int64 = 0
    var refreshRequests: Int64 = 0
    var closeCalls: Int64 = 0
    let bookmarkRefreshes = ArrayList<Int64>()

    func requestRefresh() {{
        refreshRequests += 1
    }}
    func refreshPageFocusBookmark(node: CjguiComposableUiLayoutNode): Unit {{
        bookmarkRefreshes.add(node.nodeId)
    }}
    func close() {{
        closeCalls += 1
    }}
    func result(open: Bool, didApply: Bool): CjguiComposableUiWindowPumpResult {{
        return CjguiComposableUiWindowPumpResult(open, didApply)
    }}

    /// kind-33 分支的逐字生产文本注入点。生产里它内联在 FIFO 排空循环里；这里用
    /// 一个恒假的前置分支把它接成合法的 if/else-if 链，分支体一个字符都没改。
    func pumpSelectionEvent(nativeEvent: InternalRendererPumpResult): CjguiComposableUiWindowPumpResult {{
        var didApply = false
        if (nativeEvent.recordIndex == 4294967295u32) {{
        {branch}        }}
        return result(true, didApply)
    }}

    func acceptScene(version: Int64, nodes: ArrayList<CjguiComposableUiLayoutNode>): Unit {{
        let scene = CjguiComposableUiScene(version, nodes)
        publishAcceptedBindingEpochs(scene)
        nativeInputScene = scene
    }}

    func armRestore(nodeId: Int64, resourceId: Int64, nodeKind: Int64, acceptedVersion: Int64,
        sessionContentVersion: Int64, session: ?CjguiTextSession, requestId: UInt64,
        bindingEpoch: UInt64, projectionVersion: UInt64, canonicalStart: Int64, canonicalEnd: Int64,
        refusalRecovery!: Bool = false, receiptEpoch!: Int64 = 1, receiptMirror!: Int64 = 2): Unit {{
        pendingPlatformRestore = Some(CjguiPendingPlatformRestore(nodeId, resourceId, nodeKind,
            acceptedVersion, canonicalStart, canonicalEnd, receiptEpoch, receiptMirror, refusalRecovery,
            sessionContentVersion, session,
            InternalRendererProxyRestoreTicket(requestId, 7, 3u64, bindingEpoch, projectionVersion,
                canonicalStart, canonicalEnd)))
    }}

{window_methods}
}}
'''


def validate_sources() -> None:
    harness = production_harness(None)
    for required in ("CJGUI_OWNED_SELECTION_NAMED_STALE", "restore_adoption_source_stale",
                     "private class CjguiPendingPlatformRestore"[:0] + "class CjguiPendingPlatformRestore",
                     "func onPlatformProxyRestoreReceipt(", "func adoptOwnedTextSelection(",
                     "func rememberInteraction("):
        if required not in harness:
            raise ValueError(f"generated harness lost production text: {required}")
    if not TEST_SOURCE.exists():
        raise ValueError(f"missing fixture test source: {TEST_SOURCE}")
    tests = TEST_SOURCE.read_text(encoding="utf-8")
    for name in ("ohosNamedStalePlatformSelectionKeepsFocusAndBookmark",
                 "ohosAlignedPlatformSelectionStillRecordsFocus",
                 "ohosHumanAnchorSelectionStillUnlocksAfterReplace",
                 "ohosRestoreReceiptRefusedByOwnerVersionIsNotWindowAdopted",
                 "ohosRestoreReceiptAdoptedCountsSuccessOnce",
                 "ohosRestoreTerminalRequiresExactRequestIdentity"):
        if f"func {name}(" not in tests:
            raise ValueError(f"focused window-seam test missing: {name}")


def run_once(red: str | None) -> tuple[int, str]:
    cjpm = shutil.which("cjpm")
    if cjpm is None:
        raise SystemExit("cjpm is unavailable; source the Cangjie 1.1.3 envsetup.sh first")
    with tempfile.TemporaryDirectory(prefix="cjgui-ohos-window-restore-") as tmp:
        project = Path(tmp)
        subprocess.run([cjpm, "init", "--name", "cjgui", "--type=static"], cwd=project, check=True,
                       stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        source_dir = project / "src"
        for sample in source_dir.glob("*.cj"):
            sample.unlink()
        (source_dir / "window_restore_harness.cj").write_text(production_harness(red), encoding="utf-8")
        shutil.copy2(TEST_SOURCE, source_dir / TEST_SOURCE.name)
        command = [cjpm, "test", "--no-color", "--no-progress"]
        completed = subprocess.run(command, cwd=project, capture_output=True, text=True)
        sys.stdout.write(completed.stdout)
        sys.stderr.write(completed.stderr)
        return completed.returncode, completed.stdout


SUMMARY_RE = re.compile(r"Summary: TOTAL: (\d+)\s*\n\s*PASSED: (\d+), SKIPPED: (\d+), ERROR: (\d+)"
                        r"\s*\n\s*FAILED: (\d+)")


def clean_verdict(stdout: str) -> tuple[int, int, int]:
    """从 cjpm 自己的汇总取 (total, passed, failed+error)，不写死用例数。

    cjpm 会按测试点打印多份 Summary，最后一份是总账。取不到就判红：没有汇总
    等于没有证据，不能当通过。
    """
    hits = SUMMARY_RE.findall(stdout)
    if not hits:
        return 0, 0, 1
    total, passed, _skipped, error, failed = (int(v) for v in hits[-1])
    return total, passed, failed + error


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check-only", action="store_true",
                        help="validate extraction wiring without invoking cjpm")
    parser.add_argument("--selftest", action="store_true",
                        help="apply each RED mutation and require the guarded test to fail")
    args = parser.parse_args()
    validate_sources()
    if args.check_only:
        print("OK window/scene/session production extraction, kind-33 branch, pending class, fixture tests")
        return 0

    clean, clean_out = run_once(None)
    total, passed, bad = clean_verdict(clean_out)
    print(f"[clean] cjpm test exit={clean} total={total} passed={passed} failed_or_error={bad}")
    if clean != 0 or total == 0 or passed != total or bad != 0:
        print("FAIL production window seam does not satisfy the H1-R.c criteria")
        return 1
    if not args.selftest:
        print(f"SUMMARY {passed}/{total} PASS failed=[]")
        return 0

    failures = []
    for red in ("adoption-result", "named-stale"):
        code, _ = run_once(red)
        print(f"[red:{red}] cjpm test exit={code}")
        if code == 0:
            failures.append(red)
    if failures:
        print(f"FAIL negative controls stayed green: {failures}")
        return 1
    print(f"SUMMARY {passed}/{total} PASS failed=[] ({len(RED_GUARDS)} RED mutations correctly rejected)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

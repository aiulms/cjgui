#!/usr/bin/env python3
"""H2-1（N3）：在**生产窗口接缝**上跑滚动活动调度/接管/准入的确定性反例。

被测决策全部从 H 快照逐字抽取，任何改名/改签名/改判据文本都会让本 harness 编译失败：

  1. `applyViewportScrollStep` —— fling 是 END 的派生意图，只有携带**当前释放票据**
     （最近一次合法 BEGIN 冻结的 gestureEpoch）的释放才能启动活动；票据缺失/过期一律
     具名拒绝 `inertia_release_ticket_stale`。同手势 MOVE 保留票据；无手势的显式
     `by:`/step 接管活动并清票；成功 END 一次消费，旧 MOVE 不夺新释放权。
  2. kind-30 路由里的空白接管分支 —— 新触摸落在视口内（空白/只读内容根本不产生指针
     事件）时宿主入队 `takeover:` 意图；窗口按冻结绑定终结该视口活动、发放新票据，
     并且**不得**把这条意图当位移送进 step 解析。
  3. `revealAcceptedNodeIfNeeded` 的接管守卫 —— 目标与当前 accepted 相同（不产生新
     offset）时 reveal 仍要接管活动；同一 reveal 的重试（中间没有新 BEGIN/新接受）
     不重复接管，避免误杀新手势已启动的活动。
  4. `stopWindowActivities` / `takeOverScrollActivity` —— 停机与显式接管都使未启动的
     释放失去启动权（票据清零）。
  5. `validateCandidateViewStateOwnership` —— 同一 mutable viewport 被一个候选里的两个
     独立 scrollArea 绑定时，在**准入**处拒绝 `scroll_viewport_duplicate_binding`；
     拒绝后 `discardStagedViewStateOwnership` 什么都不留下（旧 accepted 与活动不受影响）。
  6. `stepWindowActivities` / `hasActiveWindowActivities` —— `changed` 与 `active` 是两件
     事：重复时刻 (false,true)、真实推进 (true,·)、停止后的末帧 active=false。

替身边界（明确记账，避免"测了个替身"）：声明节点 `CjguiComposableUiNode`、布局节点
`CjguiComposableUiLayoutNode`、场景存储、split/tabs 状态、指针事件记录都是最小替身，
只提供被测决策实际读到的成员；**滚动物理与全部判决文本逐字来自生产**，包括
`CjguiComposableUiScrollViewport`（483 行整类）、`CjguiComposableUiActivityStep`、
`CjguiComposableUiScrollBindingRecord`、`CjguiComposableUiViewStateAllocator` 与上述六个
窗口成员。reveal 只抽取接管守卫块（其后的 planner/offset 判决由
`test_reveal_plan_snapshot_cjpm.py` 与主树 `composable_ui_scroll_activity_test.cj` 覆盖）。

宿主接线（`CjguiMacosApplicationHost.pumpOneTurn` 推进窗口活动、样例不再各自步进）用
文本闸门校验，见 `--check-only` 输出：那是接线证据，不是行为证据，本文里分开记账。

`--selftest` 施加五处只影响被测守卫的变异，要求对应判据变红（证明判据非空转）。
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
PLATFORM = HERE.parent
SNAPSHOT = PLATFORM / "snapshot" / "src"
UI_SOURCE = SNAPSHOT / "composable_ui.cj"
WINDOW_SOURCE = SNAPSHOT / "composable_ui_window.cj"
HOST_SOURCE = SNAPSHOT / "macos_application_host.cj"
LAB_SOURCES = (
    Path("/Users/jiangxuanyang/Desktop/cangjie/labs/ohos_cjgui_app/entry/src/main/cangjie/ohos_app.cj"),
    Path("/Users/jiangxuanyang/Desktop/cangjie/labs/ohos_thermo_app/entry/src/main/cangjie/ohos_app.cj"),
)
TEST_SOURCE = HERE / "fixtures" / "scroll_activity_snapshot_test.cj"

WINDOW_METHODS = (
    "applyViewportScrollStep", "takeOverScrollActivity", "stopWindowActivities",
    "hasActiveWindowActivities", "stepWindowActivities", "viewportAncestorsForNode",
    "viewportNodeForIdentity", "validateCandidateViewStateOwnership",
    "commitCandidateViewStateOwnership", "discardStagedViewStateOwnership",
)
PUBLIC_WINDOW_METHODS = ("takeOverScrollActivity", "stopWindowActivities", "hasActiveWindowActivities",
                         "stepWindowActivities")
UI_CLASSES = (
    "public class CjguiComposableUiScrollViewport {",
    "public enum CjguiComposableUiScrollPhysicsPolicy {",
    "public struct CjguiComposableUiActivityStep {",
    "class CjguiComposableUiViewStateAllocator {",
)
WINDOW_CLASSES = ("class CjguiComposableUiScrollBindingRecord {",)

# 空白接管分支：从 takeover 判定到 viewportScrollApplied 赋值结束，逐字抽取。
ROUTING_START = ('                if (gestureBindingReady && nativeEvent.eventKind == 30u32 && '
                 'eventText == "takeover:" &&')
ROUTING_END = "applyViewportScrollStep(continuation, eventText, nativeEvent.gestureEpoch)"
# reveal 的接管守卫块（同一 reveal 重试不重复接管）。
REVEAL_GUARD_START = "        if (nodeId != lastRevealTakeoverNodeId) {"

RED_GUARDS = {
    "gesture-move-split": (
        "            if (releaseTicket != 0u64) {\n",
        "            if (false) {\n",
    ),
    "release-single-use": (
        "                    if (started) { scrollReleaseTicket = 0u64 }\n",
        "                    if (false) { scrollReleaseTicket = 0u64 }\n",
    ),
    # 去掉释放票据门：过期/缺失票据的 fling 会启动活动。
    "ticket-gate": (
        "                if (releaseTicket == 0u64 || releaseTicket != scrollReleaseTicket) {\n",
        "                if (false) {\n",
    ),
    # 显式定位不再清零票据：同一手势的迟后 END 能重启惯性。
    "takeover-ticket": (
        "        viewport.stopInertialScroll()\n"
        "        // 显式接管使所有未启动的释放失效：reveal/jump 之后的迟后 END 不得重启。\n"
        "        scrollReleaseTicket = 0u64\n",
        "        viewport.stopInertialScroll()\n"
        "        // 显式接管使所有未启动的释放失效：reveal/jump 之后的迟后 END 不得重启。\n",
    ),
    # 空白接管意图不再被识别：宿主入队的 takeover 变成一条不可解析的位移意图。
    "routing-takeover": (
        '                if (gestureBindingReady && nativeEvent.eventKind == 30u32 && '
        'eventText == "takeover:" &&\n',
        '                if (gestureBindingReady && nativeEvent.eventKind == 30u32 && '
        'eventText == "takeover-miss:" &&\n',
    ),
    # reveal 重试守卫失效：同一 reveal 的第二次执行会误杀新手势的活动。
    "reveal-retry-guard": (
        "        if (nodeId != lastRevealTakeoverNodeId) {\n",
        "        if (true) {\n",
    ),
    # 重复视口准入拒绝失效：一个候选里两个 scrollArea 共享同一 mutable viewport 被放过。
    "duplicate-admission": (
        "                if (seen == identity) {\n",
        "                if (seen == identity && false) {\n",
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


def production_method(name: str) -> str:
    source = WINDOW_SOURCE.read_text(encoding="utf-8")
    visibility = "public" if name in PUBLIC_WINDOW_METHODS else "private"
    text = production_member(source, f"    {visibility} func {name}(", f"window method {name}")
    # 只做可见性改写（测试文件要直接驱动这些接缝）；签名与函数体一个字符不改。
    return text.replace(f"    {visibility} func {name}(", f"    func {name}(", 1)


def production_routing_snippet() -> str:
    source = WINDOW_SOURCE.read_text(encoding="utf-8")
    if source.count(ROUTING_START) != 1 or source.count(ROUTING_END) != 1:
        raise ValueError("expected exactly one blank-area takeover routing snippet")
    start = source.index(ROUTING_START)
    end = source.index(ROUTING_END, start) + len(ROUTING_END)
    if end <= start:
        raise ValueError("routing snippet markers are out of order")
    return source[start:end]


def production_reveal_guard() -> str:
    source = WINDOW_SOURCE.read_text(encoding="utf-8")
    if source.count(REVEAL_GUARD_START) != 1:
        raise ValueError("expected exactly one reveal takeover guard")
    return balanced(source, source.index(REVEAL_GUARD_START), "reveal takeover guard")


def production_constant(name: str) -> str:
    source = UI_SOURCE.read_text(encoding="utf-8")
    matches = re.findall(rf"^public let {name}: Int64 = \d+$", source, re.M)
    if len(matches) != 1:
        raise ValueError(f"expected one production constant {name}, found {len(matches)}")
    return matches[0]


def production_harness(red: str | None) -> str:
    ui_text = UI_SOURCE.read_text(encoding="utf-8")
    ui_members = "\n\n".join(production_member(ui_text, marker, marker) for marker in UI_CLASSES)
    window_text = WINDOW_SOURCE.read_text(encoding="utf-8")
    window_classes = "\n\n".join(production_member(window_text, marker, marker)
                                 for marker in WINDOW_CLASSES)
    window_methods = "\n\n".join(production_method(name) for name in WINDOW_METHODS)
    routing = production_routing_snippet()
    reveal_guard = production_reveal_guard()
    constants = production_constant("CJGUI_COMPOSABLE_UI_SCROLL_AREA")
    if red is not None:
        old, new = RED_GUARDS[red]
        hits = sum(part.count(old) for part in (window_methods, routing, reveal_guard))
        if hits != 1:
            raise ValueError(f"cannot apply RED mutation exactly once: {red} (hits={hits})")
        window_methods = window_methods.replace(old, new, 1)
        routing = routing.replace(old, new, 1)
        reveal_guard = reveal_guard.replace(old, new, 1)

    return f'''package cjgui

import std.collection.*
import std.convert.*
import std.math.*
import std.overflow.*
import std.sync.*
import std.time.*

{constants}

{ui_members}

{window_classes}

// ---- 最小替身：只提供被测决策实际读到的成员，名字/类型逐字抄生产声明 ----

class CjguiComposableUiSplitState {{
    let identity: Int64
    var token: Int64 = 0
    init(identity: Int64) {{
        this.identity = identity
    }}
    public func viewStateIdentity(): Int64 {{
        return identity
    }}
    public func ownerWindowToken(): Int64 {{
        return token
    }}
    public func claimOwner(windowToken: Int64): Bool {{
        token = windowToken
        return true
    }}
}}

class CjguiComposableUiTabsState {{
    let identity: Int64
    var token: Int64 = 0
    init(identity: Int64) {{
        this.identity = identity
    }}
    public func viewStateIdentity(): Int64 {{
        return identity
    }}
    public func ownerWindowToken(): Int64 {{
        return token
    }}
    public func claimOwner(windowToken: Int64): Bool {{
        token = windowToken
        return true
    }}
}}

/// 声明树替身（准入走的是声明节点，不是布局节点）。
class CjguiComposableUiNode {{
    let scrollViewport: ?CjguiComposableUiScrollViewport
    let splitState: ?CjguiComposableUiSplitState
    let tabsState: ?CjguiComposableUiTabsState
    let kids: ArrayList<CjguiComposableUiNode>
    init(scrollViewport!: ?CjguiComposableUiScrollViewport = None,
        splitState!: ?CjguiComposableUiSplitState = None,
        tabsState!: ?CjguiComposableUiTabsState = None,
        children!: ArrayList<CjguiComposableUiNode> = ArrayList<CjguiComposableUiNode>()) {{
        this.scrollViewport = scrollViewport
        this.splitState = splitState
        this.tabsState = tabsState
        this.kids = children
    }}
    public func children(): ArrayList<CjguiComposableUiNode> {{
        return kids
    }}
}}

class CjguiComposableUiClipConstraint {{
    let ownerIdentity: String
    init(ownerIdentity: String) {{
        this.ownerIdentity = ownerIdentity
    }}
}}

/// accepted 布局节点替身：reveal 的祖先解析只读 nodeKind/identityKey/scrollViewport/
/// clipConstraints。
class CjguiComposableUiLayoutNode {{
    let nodeId: Int64
    let nodeKind: Int64
    let identityKey: String
    let scrollViewport: ?CjguiComposableUiScrollViewport
    let clips: ArrayList<CjguiComposableUiClipConstraint>
    init(nodeId: Int64, nodeKind: Int64, identityKey: String,
        scrollViewport!: ?CjguiComposableUiScrollViewport = None,
        clipOwners!: ArrayList<String> = ArrayList<String>()) {{
        this.nodeId = nodeId
        this.nodeKind = nodeKind
        this.identityKey = identityKey
        this.scrollViewport = scrollViewport
        this.clips = ArrayList<CjguiComposableUiClipConstraint>()
        for (owner in clipOwners) {{
            clips.add(CjguiComposableUiClipConstraint(owner))
        }}
    }}
    public func clipConstraints(): ArrayList<CjguiComposableUiClipConstraint> {{
        return clips
    }}
    public static func missing(): CjguiComposableUiLayoutNode {{
        return CjguiComposableUiLayoutNode(-1, 0, "")
    }}
}}

class CjguiComposableUiScene {{
    let layoutNodes: ArrayList<CjguiComposableUiLayoutNode>
    init(nodes: ArrayList<CjguiComposableUiLayoutNode>) {{
        this.layoutNodes = nodes
    }}
    public func nodes(): ArrayList<CjguiComposableUiLayoutNode> {{
        return layoutNodes
    }}
    public func nodeForId(nodeId: Int64): CjguiComposableUiLayoutNode {{
        for (node in layoutNodes) {{
            if (node.nodeId == nodeId) {{
                return node
            }}
        }}
        return CjguiComposableUiLayoutNode.missing()
    }}
}}

/// 指针事件替身：路由分支只读 eventKind 与 gestureEpoch。
class HarnessPointerEvent {{
    let eventKind: UInt32
    let gestureEpoch: UInt64
    init(eventKind: UInt32, gestureEpoch: UInt64) {{
        this.eventKind = eventKind
        this.gestureEpoch = gestureEpoch
    }}
}}

class CjguiComposableUiWindow {{
    let instanceToken: Int64 = 990011
    var nativeInputScene = CjguiComposableUiScene(ArrayList<CjguiComposableUiLayoutNode>())
    var acceptedScrollBindings = ArrayList<CjguiComposableUiScrollBindingRecord>()
    var scrollReleaseTicket: UInt64 = 0u64
    var lastRevealTakeoverNodeId: Int64 = -1
    var lastNativeFailure: String = ""
    var stagedViewStateViewports = ArrayList<CjguiComposableUiScrollViewport>()
    var stagedViewStateSplits = ArrayList<CjguiComposableUiSplitState>()
    var stagedViewStateTabs = ArrayList<CjguiComposableUiTabsState>()

    // ---- harness 驱动入口（不是生产 API）----

    func acceptScene(nodes: ArrayList<CjguiComposableUiLayoutNode>): Unit {{
        nativeInputScene = CjguiComposableUiScene(nodes)
    }}

    func sceneNode(nodeId: Int64): CjguiComposableUiLayoutNode {{
        return nativeInputScene.nodeForId(nodeId)
    }}

    func acceptBinding(viewport: CjguiComposableUiScrollViewport, nodeId: Int64): Unit {{
        acceptedScrollBindings.add(CjguiComposableUiScrollBindingRecord(viewport,
            viewport.viewStateIdentity(), nodeId, nodeId, CJGUI_COMPOSABLE_UI_SCROLL_AREA, 1u64))
    }}

    /// 生产里票据只在合法 BEGIN 与空白接管分支发放，两处都同时复位 reveal 重试守卫。
    func issueTicket(epoch: UInt64): Unit {{
        scrollReleaseTicket = epoch
        lastRevealTakeoverNodeId = -1
    }}

    func ticket(): UInt64 {{
        return scrollReleaseTicket
    }}

    func revealTakeoverNodeId(): Int64 {{
        return lastRevealTakeoverNodeId
    }}

    func stagedViewportCount(): Int64 {{
        return Int64(stagedViewStateViewports.size)
    }}

    /// `reconcileScrollActivitiesAfterAcceptance` 里对 reveal 重试守卫的复位。
    func noteAcceptedScene(): Unit {{
        lastRevealTakeoverNodeId = -1
    }}

    /// kind-30 路由片段的逐字生产文本注入点。生产里它内联在 FIFO 排空的
    /// 27..31/36/51 分支里；这里用同名的局部事实把它接成一个可调用接缝，
    /// 片段文本一个字符都没改。
    func routeScrollIntent(nativeEvent: HarnessPointerEvent, continuation: CjguiComposableUiLayoutNode,
        nodeId: Int64, eventText: String, gestureBindingReady: Bool): Bool {{
{routing}
        return viewportScrollApplied
    }}

    /// reveal 接管守卫的逐字生产文本注入点（其后的 planner 判决不在本 harness 范围内）。
    func revealTakeoverGuard(nodeId: Int64, target: CjguiComposableUiLayoutNode): Unit {{
{reveal_guard}
    }}

{window_methods}
}}
'''


HOST_WIRING = (
    "        let activity = composableWindow.stepWindowActivities(MonoTime.now())\n"
    "        if (activity.changed) {\n"
    "            composableWindow.requestRefresh()\n"
    "        }\n"
)


def validate_sources() -> None:
    harness = production_harness(None)
    for required in ("inertia_release_ticket_stale", "scroll_viewport_duplicate_binding",
                     "cross_window_view_state_shared:scroll", "func applyViewportScrollStep(",
                     "func takeOverScrollActivity(", "func stopWindowActivities(",
                     "func stepWindowActivities(", "func validateCandidateViewStateOwnership(",
                     'eventText == "takeover:"', "func viewportAncestorsForNode(",
                     "public func beginInertialScroll(", "public func stepInertialScroll("):
        if required not in harness:
            raise ValueError(f"generated harness lost production text: {required}")
    if not TEST_SOURCE.exists():
        raise ValueError(f"missing fixture test source: {TEST_SOURCE}")
    tests = TEST_SOURCE.read_text(encoding="utf-8")
    for name in ("ohosFlingAdmissionRequiresTheCurrentReleaseTicket",
                 "ohosCurrentGestureMovesPreserveTheReleaseForInertia",
                 "ohosOldGestureMoveCannotStealTheNewRelease",
                 "ohosExplicitScrollIntentTakesOverAndInvalidatesTheTicket",
                 "ohosStopAndExplicitTakeoverInvalidatePendingReleases",
                 "ohosBlankAreaTakeoverIntentStopsInertiaAndIssuesTheTicket",
                 "ohosRevealTakesOverSameValueActivityWithoutRekillingRetries",
                 "ohosDuplicateViewportBindingIsRefusedAtAdmission",
                 "ohosWindowStepSeparatesChangedFromActive"):
        if f"func {name}(" not in tests:
            raise ValueError(f"focused scroll-activity test missing: {name}")

    # 宿主接线闸门（文本证据，不是行为证据）：共同 host 的单窗口轮次必须推进窗口
    # 活动并按 changed 请求刷新；两款样例不得再各自步进（否则活动速率翻倍）。
    host = HOST_SOURCE.read_text(encoding="utf-8")
    if host.count(HOST_WIRING) != 1:
        raise ValueError("common host no longer advances window activities in pumpOneTurn")
    for lab in LAB_SOURCES:
        text = lab.read_text(encoding="utf-8")
        if "stepWindowActivities" in text:
            raise ValueError(f"sample still steps window activities locally: {lab}")


def run_once(red: str | None) -> tuple[int, str]:
    cjpm = shutil.which("cjpm")
    if cjpm is None:
        raise SystemExit("cjpm is unavailable; source the Cangjie 1.1.3 envsetup.sh first")
    with tempfile.TemporaryDirectory(prefix="cjgui-ohos-scroll-activity-") as tmp:
        project = Path(tmp)
        subprocess.run([cjpm, "init", "--name", "cjgui", "--type=static"], cwd=project, check=True,
                       stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        source_dir = project / "src"
        for sample in source_dir.glob("*.cj"):
            sample.unlink()
        (source_dir / "scroll_activity_harness.cj").write_text(production_harness(red),
                                                               encoding="utf-8")
        shutil.copy2(TEST_SOURCE, source_dir / TEST_SOURCE.name)
        command = [cjpm, "test", "--no-color", "--no-progress"]
        completed = subprocess.run(command, cwd=project, capture_output=True, text=True)
        sys.stdout.write(completed.stdout)
        sys.stderr.write(completed.stderr)
        return completed.returncode, completed.stdout


SUMMARY_RE = re.compile(r"Summary: TOTAL: (\d+)\s*\n\s*PASSED: (\d+), SKIPPED: (\d+), ERROR: (\d+)"
                        r"\s*\n\s*FAILED: (\d+)")


def clean_verdict(stdout: str) -> tuple[int, int, int]:
    """从 cjpm 自己的汇总取 (total, passed, failed+error)，不写死用例数。"""
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
        print("OK production extraction (viewport class, binding record, 10 window members, "
              "kind-30 takeover routing, reveal guard), fixture tests, host wiring gate")
        return 0

    clean, clean_out = run_once(None)
    total, passed, bad = clean_verdict(clean_out)
    print(f"[clean] cjpm test exit={clean} total={total} passed={passed} failed_or_error={bad}")
    if clean != 0 or total == 0 or passed != total or bad != 0:
        print("FAIL production scroll-activity seam does not satisfy the H2-1 criteria")
        return 1
    if not args.selftest:
        print(f"SUMMARY {passed}/{total} PASS failed=[]")
        return 0

    failures = []
    for red in RED_GUARDS:
        code, _ = run_once(red)
        print(f"[red:{red}] cjpm test exit={code}")
        if code == 0:
            failures.append(red)
    if failures:
        print(f"FAIL negative controls stayed green: {failures}")
        return 1
    print(f"SUMMARY {passed}/{total} PASS failed=[] "
          f"({len(RED_GUARDS)} RED mutations correctly rejected)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

#!/usr/bin/env python3
"""N1-R.a（H1-R.a）：人类锚（human selection anchor）的确定性反例。

被测机制：外部（Agent）换版后，会话置 `selectionNeedsNativeRestore` 挡住一切正文写入，
而窗口既有的两条解锁路径都要求"框架焦点 + accepted 对齐"，人第一次点击之前不可能触发；
与此同时隐藏输入代理挂载/换焦会自己产生一次落在正文末尾的选区回声（实测
`ime proxy mounted` → `ime select [44,44) rc=0`）。于是两种错误形状同时存在：

  * 把回声当权威 → 一个没人放过的落点被采纳成"人的导航"；
  * 把回声按 stale 丢掉（修复前的形状）→ 人点击正文后键入被
    `selection_native_alignment_required` 静默丢弃，owner 字节数原地不动。

native 的解法是把两类事实分开记账：只有**人亲手落点**（命中测试 / 原生长按全选）才在
同一临界区冻结一枚一次性锚（身份 + 单调序号 + UTF-16 落点），并就地终结在途恢复票据
（人的导航优先于恢复目标）；窗口消费 kind-33 时按身份与值**逐位**核验后取走，取走即
consumed。回声身份相同但值不同，取不走锚。

锚只是一半：窗口要能取走它，前提是平台那条"我已装好这个落点"的观测真的进了事件队列。
`ohos_renderer_ime_set_selection_ctx` 原本按 native 自己的 caret 判重（`changed`），而人
点击时命中测试**先**把 native 写成命中值，平台回声的正是同一个值 → 观测被吞、kind-33
不入队、锚只 recorded 不 taken（实测 09-30 03:49:28.822 `ime select [24,24) rc=0` 之后
窗口侧毫无记录，紧随的键入被对齐门禁拒掉）。转发判据因此改为"窗口已收到过哪个观测"
（`selForwarded*`），同值不重复入队以免自激，换绑/重挂使账本失效。

被摘掉任一守卫，同一套断言必须失败：值等式（回声冒名）、身份等式与"0 不是通配"、
一次性消费、票据就地终结、换绑/换焦清锚、accepted 绑定存在才冻结、转发判据退回按
native caret 判重。
"""
import pathlib
import subprocess
import sys
import tempfile
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]
SOURCE = ROOT / "host" / "ohos_renderer.cpp"
INGRESS = ROOT / "host" / "cjgui_ohos_ingress.h"

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import test_text_proxy_recovery_native as recovery  # noqa: E402

ANCHOR_FIELDS = "    HumanSelectionAnchor humanAnchor;\n    uint64_t humanAnchorSeq = 0;\n"

MAIN_BODY = r"""
static const std::string kAccepted = "# Pharos Mark\n\nAgentAgent";  // 25 个 UTF-16 单元
static int g_failures = 0;

#define EXPECT(cond, code) do { if (!(cond)) { fprintf(stderr, "FAIL %d (%s)\n", code, #cond); g_failures += 1; } } while (0)

static SceneNode acceptedNode(uint64_t nodeId, int64_t resourceId, uint32_t nodeKind,
                              uint64_t version, uint64_t epoch) {
  SceneNode n;
  n.pod.nodeId = nodeId;
  n.pod.resourceId = resourceId;
  n.pod.nodeKind = nodeKind;
  n.pod.projectionVersion = version;
  n.pod.acceptedBindingEpoch = epoch;
  n.pod.isInteractive = 1;
  n.pod.isReadOnly = 0;
  n.semanticId = "pharos-editor-body";
  n.value = kAccepted;
  return n;
}

// 外部换版之后、人还没点击的活上下文：编辑身份与 accepted 绑定同源，代理尚未把
// 新正文装上，选区仍是会话投影出来的旧落点（这里取 18，与实测 hilog 同形）。
static Session &armEditing(uint64_t epoch = 77) {
  for (Session &slot : g_sessions.sessions) { slot = Session(); }
  Session &s = g_sessions.sessions[0];
  s.inUse = true;
  s.token = g_sessionToken;
  s.editing = true;
  s.editorRetired = false;
  s.editingContextLive = true;
  s.editingContextId = 41;
  s.editingContextGeneration = 5;
  s.editingFieldName = "pharos-editor-body";
  s.editingNodeId = 107;
  s.editingResourceId = 1;
  s.editingNodeKind = 10;
  s.editingProjectionVersion = 9;
  s.editingContextBaseVersion = 9;
  s.caretUtf16 = 18;
  s.selStartUtf16 = 18;
  s.selEndUtf16 = 18;
  s.accepted.push_back(acceptedNode(107, 1, 10, 9, epoch));
  return s;
}

static int32_t take(uint64_t nodeId, int64_t resourceId, uint32_t nodeKind, uint64_t projection,
                    uint64_t epoch, uint32_t start, uint32_t end, uint64_t *outSeq) {
  return cjgui_internal_renderer_take_human_selection_anchor(g_sessionToken, nodeId, resourceId,
                                                             nodeKind, projection, epoch, start, end,
                                                             outSeq);
}

int main() {
  // 1) 人的落点冻结完整身份 + 值 + 单调序号，并在同一临界区终结在途恢复票据。
  {
    Session &s = armEditing();
    s.proxyRestore.requestId = 3;
    s.proxyRestore.armed = true;
    s.proxyRestore.nodeId = 107;
    s.proxyRestore.resourceId = 1;
    s.proxyRestore.nodeKind = 10;
    s.proxyRestore.acceptedProjectionVersion = 9;
    s.proxyRestore.acceptedBindingEpoch = 77;
    s.proxyRestore.contextId = 41;
    s.proxyRestore.contextGeneration = 5;
    recordHumanSelectionAnchorLocked(s, "caret_hit");
    EXPECT(s.humanAnchor.seq == 1 && s.humanAnchorSeq == 1, 11);
    EXPECT(s.humanAnchor.nodeId == 107 && s.humanAnchor.resourceId == 1 &&
           s.humanAnchor.nodeKind == 10, 12);
    EXPECT(s.humanAnchor.projectionVersion == 9 && s.humanAnchor.acceptedBindingEpoch == 77, 13);
    EXPECT(s.humanAnchor.start16 == 18 && s.humanAnchor.end16 == 18, 14);
    EXPECT(!s.humanAnchor.consumed, 15);
    // 未发送即终结 → recordIndex/code 1（平台安装从未执行），窗口必须收到终态事件。
    EXPECT(!s.proxyRestore.armed && s.proxyRestore.requestId == 0, 16);
    EXPECT(s.proxyRestoreTerminals.size() == 1 &&
           s.proxyRestoreTerminals[0].reason == "human_anchor_supersedes" &&
           s.proxyRestoreTerminals[0].code ==
               CJGUI_INTERNAL_RENDERER_PROXY_RESTORE_NOT_INSTALLED, 17);
    EXPECT(s.events.size() == 1 && s.events.back().kind == kEvTextProxyRestored &&
           s.events.back().recordIndex == 1u &&
           s.events.back().text == "human_anchor_supersedes", 18);
  }
  // 2) 反向选区（原生全选/拖选）按 min/max 归一，锚永远描述 [start,end)。
  {
    Session &s = armEditing();
    s.selStartUtf16 = 30;
    s.selEndUtf16 = 12;
    recordHumanSelectionAnchorLocked(s, "native_select_all");
    EXPECT(s.humanAnchor.start16 == 12 && s.humanAnchor.end16 == 30, 21);
  }
  // 3) 没有 accepted 绑定就没有可核验身份：不伪造锚，take 零改动返回 0。
  {
    Session &s = armEditing(/*epoch=*/0);
    recordHumanSelectionAnchorLocked(s, "caret_hit");
    EXPECT(s.humanAnchor.seq == 0 && s.humanAnchorSeq == 0, 31);
    uint64_t seq = 999;
    EXPECT(take(107, 1, 10, 9, 77, 18, 18, &seq) == 0 && seq == 0, 32);
  }
  // 4) 值等式：代理挂载/换焦的末尾回声身份相同、值不同 —— 不得冒名取走人的锚；
  //    人的落点全部命中才取走，且取走即 consumed（一次性）。
  {
    Session &s = armEditing();
    recordHumanSelectionAnchorLocked(s, "caret_hit");
    uint64_t seq = 0;
    EXPECT(take(107, 1, 10, 9, 77, 25, 25, &seq) == 0 && seq == 0, 41);   // [len,len) 回声
    EXPECT(!s.humanAnchor.consumed, 42);
    EXPECT(take(107, 1, 10, 9, 77, 18, 18, &seq) == 1 && seq == 1, 43);
    EXPECT(s.humanAnchor.consumed, 44);
    uint64_t again = 7;
    EXPECT(take(107, 1, 10, 9, 77, 18, 18, &again) == 0 && again == 0, 45);  // 不得二次采纳
  }
  // 5) 身份等式：节点/资源/类型/投影版本/绑定代次任一不符，或 epoch 为 0（不是通配），
  //    一律零改动拒绝 —— 迟到的旧事件不得贴到新绑定上。
  {
    Session &s = armEditing();
    recordHumanSelectionAnchorLocked(s, "caret_hit");
    uint64_t seq = 5;
    EXPECT(take(108, 1, 10, 9, 77, 18, 18, &seq) == 0, 51);
    EXPECT(take(107, 2, 10, 9, 77, 18, 18, &seq) == 0, 52);
    EXPECT(take(107, 1, 11, 9, 77, 18, 18, &seq) == 0, 53);
    EXPECT(take(107, 1, 10, 8, 77, 18, 18, &seq) == 0, 54);
    EXPECT(take(107, 1, 10, 9, 78, 18, 18, &seq) == 0, 55);
    EXPECT(take(107, 1, 10, 9, 0, 18, 18, &seq) == 0, 56);
    // 会话状态零改动（锚未被消费），出参一律清零：调用方不得看到上一次的序号。
    EXPECT(!s.humanAnchor.consumed && seq == 0, 57);
    EXPECT(take(107, 1, 10, 9, 77, 18, 18, &seq) == 1 && seq == 1, 58);
  }
  // 6) 换绑/换焦/退役清锚：旧落点不得贴到新节点；下一次人的落点重新武装、序号单调。
  {
    Session &s = armEditing();
    recordHumanSelectionAnchorLocked(s, "caret_hit");
    clearHumanSelectionAnchorLocked(s);
    EXPECT(!s.humanCaretNotificationPending, 60);
    uint64_t seq = 7;
    EXPECT(take(107, 1, 10, 9, 77, 18, 18, &seq) == 0 && seq == 0, 61);
    s.selStartUtf16 = 5;
    s.selEndUtf16 = 9;
    recordHumanSelectionAnchorLocked(s, "caret_hit");
    EXPECT(s.humanAnchor.seq == 2 && s.humanAnchor.start16 == 5 && s.humanAnchor.end16 == 9, 62);
    EXPECT(take(107, 1, 10, 9, 77, 5, 9, &seq) == 1 && seq == 2, 63);
  }
  // 7) 参数/会话无效：-1，且不动锚。
  {
    Session &s = armEditing();
    recordHumanSelectionAnchorLocked(s, "caret_hit");
    EXPECT(take(107, 1, 10, 9, 77, 18, 18, nullptr) == -1, 71);
    uint64_t seq = 3;
    EXPECT(cjgui_internal_renderer_take_human_selection_anchor(g_sessionToken + 1, 107, 1, 10, 9,
               77, 18, 18, &seq) == -1 && seq == 0, 72);
    EXPECT(!s.humanAnchor.consumed, 73);
  }
  // 8) 平台落点观测的转发判据（首字丢失的真正根因）。人点击正文时命中测试**先**把
  //    native 落点写成命中值，平台装好之后回声的就是同一个值；按 native caret 判重会
  //    把这条观测整个吞掉，窗口收不到 kind-33，锚只 recorded 不 taken，紧随的键入被
  //    对齐门禁拒掉（实测 09-30 03:49:28.822 `ime select [24,24) rc=0` 之后窗口侧无记录）。
  {
    Session &s = armEditing();
    s.caretUtf16 = 18;
    s.selStartUtf16 = 18;
    s.selEndUtf16 = 18;
    s.selPlatformStart = 18;
    s.selPlatformEnd = 18;
    s.selForwardedValid = true;
    s.selForwardedStart = 18;
    s.selForwardedEnd = 18;
    recordHumanSelectionAnchorLocked(s, "caret_hit");
    EXPECT(s.humanCaretNotificationPending && !s.selForwardedValid, 79);
    EXPECT(s.events.empty(), 80);   // 无在途票据：终结是空操作，不伪造终态事件
    // native 已经等于回声值，仍然必须转发。
    EXPECT(selectionObservationNeedsForwarding(s, 18, 18), 81);
    EXPECT(editorEnqueueSelectionChanged(s, 18, 18), 82);
    rememberForwardedSelectionLocked(s, 18, 18);
    EXPECT(s.events.size() == 1 && s.events.back().kind == kEvSelectionChanged &&
           s.events.back().nodeId == 107u && s.events.back().resourceId == 1 &&
           s.events.back().nodeKind == 10u && s.events.back().projectionVersion == 9u &&
           s.events.back().acceptedBindingEpoch == 77u &&
           s.events.back().selectionStart == 18u && s.events.back().selectionEnd == 18u, 83);
    // 窗口据此逐位核验并取走锚：这就是"人点一次即可续写"的机制闭合点。
    uint64_t seq = 0;
    EXPECT(take(107, 1, 10, 9, 77, 18, 18, &seq) == 1 && seq == 1, 84);
    // 同一值不重复入队：否则"平台装 → native 推 → 平台装"会自激。
    EXPECT(!selectionObservationNeedsForwarding(s, 18, 18), 85);
    // 换绑/重挂使转发账本失效：新上下文的第一条观测即使同值也是新事实。
    s.selForwardedValid = false;
    EXPECT(selectionObservationNeedsForwarding(s, 18, 18), 86);
    EXPECT(selectionObservationNeedsForwarding(s, 25, 25), 87);
  }
  return g_failures == 0 ? 0 : 1;
}
"""

FUNCTIONS = [
    ("static void terminateProxyRestoreRequestLocked(Session &s", "terminateProxyRestoreRequestLocked"),
    ("static void recordHumanSelectionAnchorLocked(Session &s, const char *origin)",
     "recordHumanSelectionAnchorLocked"),
    ("static void clearHumanSelectionAnchorLocked(Session &s)", "clearHumanSelectionAnchorLocked"),
    ("int32_t cjgui_internal_renderer_take_human_selection_anchor(uint64_t session",
     "cjgui_internal_renderer_take_human_selection_anchor"),
    ("static bool selectionObservationNeedsForwarding(const Session &s, uint32_t start, uint32_t end)",
     "selectionObservationNeedsForwarding"),
    ("static void rememberForwardedSelectionLocked(Session &s, uint32_t start, uint32_t end)",
     "rememberForwardedSelectionLocked"),
    ("bool editorEnqueueSelectionChanged(Session &s, uint32_t start, uint32_t end)",
     "editorEnqueueSelectionChanged"),
]


def production_anchor_struct(text: str) -> str:
    """把生产 Session 里的锚结构原文抽出来注入 replica。

    手抄一份副本会漂移（字段改名/改宽时 harness 仍然绿）；直接注入原文，漂移就
    变成编译错误，锚的语义因此始终由生产定义决定。
    """
    start = text.index("    struct HumanSelectionAnchor {")
    end = text.index("    };", start) + len("    };")
    return text[start:end]


def replica_with_anchor(source_text: str) -> str:
    """在 recovery 已经注入落点账本字段的 replica 上，再注入生产的锚结构与实例字段。"""
    base = recovery.replica_with_ledger(source_text)
    import test_touch_gesture_native as touch
    handles, selection_fields = touch.selection_declarations(source_text, include_menu_intent=False)
    injected = production_anchor_struct(source_text) + "\n" + ANCHOR_FIELDS + selection_fields + "bool editingTapPending=false;\n"
    base = handles + base
    return base.replace(recovery.REPLICA_SESSION_MARKER, injected + recovery.REPLICA_SESSION_MARKER, 1)


def build_harness(source_text: str) -> str:
    harness = '#include "cjgui_ohos_ingress.h"\n'
    harness += recovery.STUBS
    # 生产里 kEvSelectionChanged 与 kEvTextProxyRestored 同源（事件 kind 常量）；
    # STUBS 只带了后者，这里补齐前者，值取自生产定义。
    harness += "static const uint32_t kEvSelectionChanged = 33;\n"
    harness += replica_with_anchor(source_text)
    harness += recovery.extract_decl(source_text, "std::string utf16ToUtf8(const std::u16string &utf16)")
    harness += "static std::u16string composedBuffer(Session &s) { return s.editingText; }\n"
    harness += "\n".join(recovery.extract_decl(source_text, marker) for marker, _ in FUNCTIONS)
    harness += "\n" + MAIN_BODY
    return harness


# 负控：摘掉一个守卫，同一套断言必须失败（Astra §7 边界）。
def mutate(source: str, marker: str, replacement: str, name: str) -> str:
    if marker not in source:
        raise AssertionError(f"negative control {name} did not match the source")
    return source.replace(marker, replacement, 1)


def drop_value_equality(source: str) -> str:
    """回声冒名：只要身份命中就采纳 —— 没人放过的末尾落点会被当成人的导航。"""
    return mutate(source, "    if (anchor.start16 != selectionStart || anchor.end16 != selectionEnd) {",
                  "    if (false) {", "value_equality")


def drop_identity_equality(source: str) -> str:
    """身份不核验（含把 epoch==0 当通配）：迟到的旧事件可以贴到新绑定上。"""
    return mutate(source, """    if (acceptedBindingEpoch == 0 || anchor.nodeId != nodeId || anchor.resourceId != resourceId ||
        anchor.nodeKind != nodeKind || anchor.projectionVersion != projectionVersion ||
        anchor.acceptedBindingEpoch != acceptedBindingEpoch) {""",
                  "    if (false) {", "identity_equality")


def drop_single_consumption(source: str) -> str:
    """同一锚可反复取走：一次性语义消失，旧落点能再次解锁新的门禁。"""
    return mutate(source, "    s->humanAnchor.consumed = true;\n    *outAnchorSeq = anchor.seq;",
                  "    *outAnchorSeq = anchor.seq;", "single_consumption")


def drop_ticket_termination(source: str) -> str:
    """人的落点不终结在途票据：窗口继续等一张装不上的票，输入门保持关闭。"""
    return mutate(source, '    terminateProxyRestoreRequestLocked(s, "human_anchor_supersedes");',
                  "", "ticket_termination")


def drop_anchor_clear(source: str) -> str:
    """换绑/换焦不清锚：A 的落点会被贴到 B 的身份上（值恰好相同时还真的能取走）。"""
    return mutate(source, """static void clearHumanSelectionAnchorLocked(Session &s)
{
    s.textMenuIntent = 0;
    s.humanAnchor = Session::HumanSelectionAnchor{};
    s.humanCaretNotificationPending = false;""", """static void clearHumanSelectionAnchorLocked(Session &s)
{
    s.textMenuIntent = 0;
    // negative control: retain the obsolete human anchor and notify intent
    (void)s;""", "anchor_clear")


def drop_binding_epoch_requirement(source: str) -> str:
    """没有 accepted 绑定也冻结锚：身份无从核验，等于允许自签自认。"""
    return mutate(source, "            node.pod.acceptedBindingEpoch != 0) {",
                  "            true) {", "binding_epoch_requirement")


def drop_forwarding_ledger(source: str) -> str:
    """退回旧判据：按 native 自己的 caret/选区判重。

    人点击正文时命中测试先把 native 落点写成命中值，平台装好后回声的正是同一个值，
    于是这条"平台已安装人的落点"的观测被吞掉：窗口收不到 kind-33，锚只 recorded
    不 taken，人的第一个字符被对齐门禁拒掉（实测 09-30 03:49:28.822 之后窗口侧无记录）。
    """
    return mutate(source,
                  "    return !s.selForwardedValid || s.selForwardedStart != start || s.selForwardedEnd != end;",
                  "    return (s.selStartUtf16 != start) || (s.selEndUtf16 != end) || (s.caretUtf16 != end);",
                  "forwarding_ledger")


class HumanSelectionAnchorNativeTest(unittest.TestCase):
    def _compile_and_run(self, source_text: str, tmp: pathlib.Path) -> int:
        harness = tmp / "human_selection_anchor_harness.cpp"
        harness.write_text(build_harness(source_text))
        binary = tmp / "human_selection_anchor_harness"
        # 负控会摘掉守卫，被摘的 helper 可能变成"定义了但没人调"，参数也可能变成
        # "没人读"；共享的 STUBS 脚手架同样只有一部分被本 harness 抽到的函数用到。
        # 这些都是抽取式 harness 的产物，不是被测语义，所以关掉这四条告警，其余保持
        # -Werror（断言全部是运行期 EXPECT，不靠编译器）。
        compiled = subprocess.run(
            ["clang++", "-std=c++17", "-Wall", "-Wextra", "-Werror", "-Wno-unused-function",
             "-Wno-unused-variable", "-Wno-unused-const-variable", "-Wno-unused-parameter",
             f"-I{ROOT / 'host'}", f"-I{INGRESS.parent}", str(harness), "-o", str(binary)],
            capture_output=True, text=True)
        if compiled.returncode != 0:
            self.fail(f"harness compile failed:\n{compiled.stderr}")
        return subprocess.run([str(binary)], capture_output=True, text=True).returncode

    def test_human_anchor_freeze_and_one_shot_take(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            rc = self._compile_and_run(SOURCE.read_text(), pathlib.Path(tmpdir))
            self.assertEqual(rc, 0, f"human selection anchor harness failed with rc={rc}")

    def test_negative_control_without_value_equality(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            rc = self._compile_and_run(drop_value_equality(SOURCE.read_text()), pathlib.Path(tmpdir))
            self.assertNotEqual(rc, 0, "a proxy mount echo must not take the human anchor")

    def test_negative_control_without_identity_equality(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            rc = self._compile_and_run(drop_identity_equality(SOURCE.read_text()), pathlib.Path(tmpdir))
            self.assertNotEqual(rc, 0, "a late event for another binding must not take the anchor")

    def test_negative_control_without_single_consumption(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            rc = self._compile_and_run(drop_single_consumption(SOURCE.read_text()),
                                       pathlib.Path(tmpdir))
            self.assertNotEqual(rc, 0, "the same anchor taken twice must fail")

    def test_negative_control_without_ticket_termination(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            rc = self._compile_and_run(drop_ticket_termination(SOURCE.read_text()),
                                       pathlib.Path(tmpdir))
            self.assertNotEqual(rc, 0, "a human landing point must terminate the live ticket")

    def test_negative_control_without_anchor_clear(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            rc = self._compile_and_run(drop_anchor_clear(SOURCE.read_text()), pathlib.Path(tmpdir))
            self.assertNotEqual(rc, 0, "rebind/retire must drop the previous anchor")

    def test_negative_control_without_binding_epoch_requirement(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            rc = self._compile_and_run(drop_binding_epoch_requirement(SOURCE.read_text()),
                                       pathlib.Path(tmpdir))
            self.assertNotEqual(rc, 0, "an anchor without an accepted binding must fail")

    def test_negative_control_without_forwarding_ledger(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            rc = self._compile_and_run(drop_forwarding_ledger(SOURCE.read_text()),
                                       pathlib.Path(tmpdir))
            self.assertNotEqual(rc, 0, "deduping platform echoes against native's own caret "
                                       "swallows the human landing point and strands the anchor")


if __name__ == "__main__":
    sys.exit(0 if unittest.main(exit=False).result.wasSuccessful() else 1)

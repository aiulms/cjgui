"""Exercise the production OHOS IME selection setter without an HAP.

The harness extracts the setter and its production context/binding helpers from
ohos_renderer.cpp. It checks the native event that the OHOS snapshot window
already consumes, including stale context and stale accepted binding rejection.
"""

from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
RENDERER = ROOT / "host" / "ohos_renderer.cpp"
SNAPSHOT_WINDOW = ROOT / "snapshot" / "src" / "composable_ui_window.cj"

# H 线（可视编辑包 A1）给 Session 加的 owned 会话锚点身份字段。被测的
# editingBindingHealthyLocked 用它们算 ownedAnchor 门，替身必须有同名字段。
# 锚点是生产声明行本身：字段改名/删除会在这里 index() 抛错，而不是让那道门
# 因为手写副本落后而静默少判。
OWNED_ID_ANCHORS = ('    bool ownedTextSessionEnabled = false;',
                    '    uint64_t ownedTextSessionBindingEpoch = 0;')


def span(text: str, start_anchor: str, end_anchor: str) -> str:
    """生产原文切片（含两端）。"""
    start = text.index(start_anchor)
    return text[start:text.index(end_anchor, start) + len(end_anchor)]


def prefix() -> str:
    """Session 替身模板 + 生产原文注入的 owned 会话锚点身份字段。"""
    source = RENDERER.read_text(encoding="utf-8")
    assert SESSION_REPLICA.count('%OWNED_ID_FIELDS%') == 1, "owned 字段占位符不再唯一"
    return SESSION_REPLICA.replace('%OWNED_ID_FIELDS%', span(source, *OWNED_ID_ANCHORS))


SCENARIOS = ("valid", "stale_context", "wrong_binding", "echo_same_value", "repeat_same")
# 生产里唯一的转发判据。变异控制按它定位，锚点不再唯一时直接判失败，不静默改到别处。
FORWARD_ANCHOR = "const bool forward = selectionObservationNeedsForwarding(*s, a, b);"


def extract_function(source: str, signature: str) -> str:
    """按花括号配对摘出"一个"函数定义。

    旧写法是 slice 到下一段注释（例如 `// 焦点请求出口`）。N1 恢复事务在这两个
    标记之间插入了票据 ACK 机制，slice 于是把 ProxyRestoreRequest /
    terminateProxyRestoreRequestLocked 一并吞进来，harness 编译不过。本 harness 的
    被测面是 IME 选区事件链，票据由 test_text_proxy_recovery_native.py 覆盖。
    """
    start = source.index(signature)
    opening = source.index("{", start)
    depth = 0
    for index in range(opening, len(source)):
        depth += (source[index] == "{") - (source[index] == "}")
        if depth == 0:
            return source[start:index + 1]
    raise ValueError(f"native function is incomplete: {signature}")


def production_parts() -> str:
    source = RENDERER.read_text(encoding="utf-8")
    finding = extract_function(source, "Session *findEditingSessionLocked()")
    event = extract_function(source,
                             "bool editorEnqueueSelectionChanged(Session &s, uint32_t start, uint32_t end)")
    context = extract_function(source, "static Session *takeEditingContextLocked(int64_t contextId)")
    # 转发判重本身也是被测面：H1-R.a 首字丢失的根因就是"按 native caret/差分推送目标
    # 判重"，会把平台装好人之后的回声整个吞掉。所以原样摘出生产的判重与记账函数，
    # harness 不另写一份判重逻辑（另写就等于用自己的假设验自己）。
    forwarding = extract_function(
        source, "static bool selectionObservationNeedsForwarding(const Session &s, uint32_t start, uint32_t end)")
    remember = extract_function(
        source, "static void rememberForwardedSelectionLocked(Session &s, uint32_t start, uint32_t end)")
    setter = extract_function(source,
                              'extern "C" int32_t ohos_renderer_ime_set_selection_ctx(int32_t start, int32_t end, int64_t contextId)')
    queue_context = extract_function(source, "static bool queuedSelectionContextIsCurrent(const Session &s, const QueuedEvent &ev)")
    # round5-C 后生产转发判据经健康绑定守卫（editingBindingHealthyLocked）取当前
    # accepted 树核对，setter/takeEditingContext 都引用它——原样摘出，判据不复制。
    healthy = extract_function(source, "static bool editingBindingHealthyLocked(const Session &s, const std::vector<SceneNode> &tree)")
    # takeEditingContextLocked 引用 healthy：声明必须在前。
    return (queue_context + "\n" + finding + "\n" + event + "\n" + healthy + "\n" + context + "\n"
            + forwarding + "\n" + remember + "\n" + setter + "\n")


SESSION_REPLICA = r"""
#include <algorithm>
#include <cstdint>
#include <cstring>
#include <iostream>
#include <memory>
#include <mutex>
#include <string>
#include <vector>

constexpr uint32_t kEvSelectionChanged = 33;
constexpr size_t kMaxSessions = 1;
#define RLOGW(...) ((void)0)
#define RLOGI(...) ((void)0)
struct NodePod {
  uint64_t nodeId = 51;
  int64_t resourceId = 9700;
  uint32_t nodeKind = 5;
  uint64_t projectionVersion = 22;
  uint64_t acceptedBindingEpoch = 91;
  uint32_t isInteractive = 1;
  uint32_t isReadOnly = 0;
};
struct SceneNode { NodePod pod; };
struct QueuedEvent {
  uint32_t kind = 0, selectionStart = 0, selectionEnd = 0, nodeKind = 0;
  uint64_t nodeId = 0, projectionVersion = 0, acceptedBindingEpoch = 0;
  int64_t resourceId = -1, editingContextId = 0;
  uint64_t editingContextGeneration = 0;
  std::string text;
};
struct Session {
  uint32_t textMenuIntent=0;
  struct {bool active=false,anchorReady=false,terminal=false;} selectionDrag;
  bool caretBlinkResetPending=false;
  int32_t caretAffinity=0;
  bool humanCaretNotificationPending=false;
  bool inUse = true, editing = true, editorRetired = false;
  bool editingContextLive = true;
  int64_t editingContextId = 7;
  uint64_t editingContextGeneration = 3;
  uint64_t editingNodeId = 51, editingProjectionVersion = 22;
  int64_t editingResourceId = 9700;
  uint32_t editingNodeKind = 5, selStartUtf16 = 12, selEndUtf16 = 12, caretUtf16 = 12;
  // round5-C：完整绑定身份（健康守卫核对 epoch/kind/semantic 与 accepted 树）。
  uint64_t editingAcceptedBindingEpoch = 91;  // 与 NodePod 默认 epoch 一致（健康守卫正控）
  std::string editingFieldName;
  // H 线 owned 会话锚点身份：取 ohos_renderer.cpp 的生产原文（见 prefix()）。
  %OWNED_ID_FIELDS%
  // 生产 Session 的两组落点账本，默认值与 ohos_renderer.cpp 一致。base 会话把
  // caret/选区都放在 12（正文末尾），于是"平台回声同一落点"场景的 changed 必为
  // false：能不能入队只取决于 selForwarded*，正是判重口径要钉死的地方。
  uint32_t selPlatformStart = 0, selPlatformEnd = 0;
  uint32_t selForwardedStart = 0, selForwardedEnd = 0;
  bool selForwardedValid = false;
  std::vector<SceneNode> accepted{SceneNode{}};
  std::vector<QueuedEvent> events;
};
struct SessionTable { std::mutex lock; Session sessions[1]; };
static SessionTable g_sessions;
static std::string utf16ToUtf8(const std::u16string &text) { return std::string(text.begin(), text.end()); }
static std::u16string composedBuffer(const Session &) { return u"hello world!"; }
static bool isEditableTextKind(uint32_t kind) { (void)kind; return true; }
static uint32_t clampToCodePointBoundary(const std::u16string &, uint32_t index) { return index; }
static bool g_redrawPosted = false;
struct RedrawJob {};
struct RenderQueue { void post(std::shared_ptr<RedrawJob>) { g_redrawPosted = true; } };
static RenderQueue g_render;
"""

# 编译前的最后一步：把 owned 会话锚点身份字段按生产原文注入 Session 替身。
HARNESS_PREFIX = prefix()


HARNESS_SUFFIX = r"""
int main(int argc, char **argv) {
  if (argc != 2) return 2;
  Session &s = g_sessions.sessions[0];
  const std::string scenario(argv[1]);
  if(scenario=="moving_echo"||scenario=="terminal_echo"){
    s.selectionDrag.active=s.selectionDrag.anchorReady=true;s.selectionDrag.terminal=scenario=="terminal_echo";
    s.selStartUtf16=4;s.selEndUtf16=s.caretUtf16=9;
  }
  if (scenario == "wrong_binding") {
    s.accepted[0].pod.nodeId = 52;
  } else if (scenario != "valid" && scenario != "stale_context"
             && scenario != "echo_same_value" && scenario != "repeat_same"
             && scenario != "moving_echo" && scenario != "terminal_echo") {
    if (scenario.rfind("queued_", 0) != 0) return 3;
  }
  if (scenario == "queued_full_id") s.editingContextId = (int64_t(1) << 40) + 7;
  const int64_t context = scenario == "stale_context" ? 8 : s.editingContextId;
  // 回声场景刻意打在与 native caret 相同的落点（base 会话 caret=sel=12）：changed
  // 必为 false，redraw 也不会 post。此时只有"窗口还没收到过这个观测"能让它入队，
  // 正是 09-30 首字丢失的那条路径；repeat_same 再打一次同值，要求判重生效不自激。
  const bool echo = scenario == "echo_same_value" || scenario == "repeat_same";
  const int32_t start = echo ? 12 : 0;
  const int32_t rc = ohos_renderer_ime_set_selection_ctx(start, 12, context);
  const size_t events1 = s.events.size();
  if (scenario == "queued_refocus" || scenario == "queued_full_id") s.editingContextId += (int64_t(1) << 32);
  if (scenario == "queued_generation") s.editingContextGeneration += 1;
  if (scenario == "queued_retired") { s.editingContextLive = false; s.editorRetired = true; }
  int32_t rc2 = rc;
  if (scenario == "repeat_same") {
    rc2 = ohos_renderer_ime_set_selection_ctx(start, 12, context);
  }
  std::cout << "rc=" << rc << " rc2=" << rc2
            << " events1=" << events1 << " events=" << s.events.size()
            << " redraw=" << (g_redrawPosted ? 1 : 0)
            << " forwarded=" << (s.selForwardedValid ? 1 : 0)
            << ":" << s.selForwardedStart << ":" << s.selForwardedEnd
            << " platform=" << s.selPlatformStart << ":" << s.selPlatformEnd;
  std::cout << " native=" << s.selStartUtf16 << ":" << s.selEndUtf16;
  if (!s.events.empty()) {
    const QueuedEvent &ev = s.events.back();
    std::cout << " kind=" << ev.kind << " node=" << ev.nodeId
              << " resource=" << ev.resourceId << " node_kind=" << ev.nodeKind
              << " projection=" << ev.projectionVersion << " epoch=" << ev.acceptedBindingEpoch
              << " selection=" << ev.selectionStart << "," << ev.selectionEnd
              << " queue_current=" << queuedSelectionContextIsCurrent(s, ev)
              << " captured_context=" << ev.editingContextId
              << " captured_generation=" << ev.editingContextGeneration
              << " text=" << (ev.text == "hello world!");
  }
  std::cout << "\n";
  return 0;
}
"""


def compile_harness(parts: str, tag: str, *, allow_unused: bool = False):
    """把摘录文本编成可执行体，返回 (TemporaryDirectory, binary)；调用方负责 cleanup。

    编译失败必须带上 stderr 抛出：`check=True` + `capture_output=True` 只会得到一句
    "returned non-zero exit status 1"，本轮排查就是这么白跑一趟的。
    """
    compiler = shutil.which("clang++")
    if compiler is None:
        raise unittest.SkipTest("clang++ unavailable")
    # 变异体把唯一调用点改掉之后，生产判重函数就"没人用了"；-Werror 下编译不过，
    # 于是根本观测不到行为差异 —— 那只会让变异控制假绿，所以对变异体放宽这一项。
    flags = ["-std=c++17", "-Wall", "-Wextra"]
    flags += ["-Wno-unused-function"] if allow_unused else ["-Werror"]
    temp = tempfile.TemporaryDirectory(prefix=f"cjgui-ohos-ime-selection-{tag}-")
    root = Path(temp.name)
    source = root / "selection.cpp"
    binary = root / "selection"
    source.write_text(parts, encoding="utf-8")
    completed = subprocess.run([compiler, *flags, str(source), "-o", str(binary)],
                               capture_output=True, text=True)
    if completed.returncode != 0:
        temp.cleanup()
        raise RuntimeError(f"harness build failed ({tag}):\n{completed.stderr}")
    return temp, binary


def run_scenarios(binary) -> dict[str, dict[str, str]]:
    states = {}
    for scenario in SCENARIOS:
        result = subprocess.run([str(binary), scenario], check=True, capture_output=True, text=True)
        states[scenario] = dict(token.split("=", 1) for token in result.stdout.strip().split(" "))
    return states


class OhosImeSelectionEventTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.temp, cls.binary = compile_harness(
            HARNESS_PREFIX + production_parts() + HARNESS_SUFFIX, "clean")

    @classmethod
    def tearDownClass(cls) -> None:
        if hasattr(cls, "temp"):
            cls.temp.cleanup()

    def run_case(self, scenario: str) -> dict[str, str]:
        result = subprocess.run([str(self.binary), scenario], check=True, capture_output=True, text=True)
        return dict(token.split("=", 1) for token in result.stdout.strip().split(" "))

    def test_queued_context_key_rejects_refocus_generation_retirement_and_64bit_collision(self) -> None:
        live = self.run_case("valid")
        self.assertEqual(live["queue_current"], "1")
        self.assertEqual(live["captured_context"], "7")
        self.assertEqual(live["captured_generation"], "3")
        self.assertEqual(live["text"], "1")
        for name in ("queued_refocus", "queued_generation", "queued_retired", "queued_full_id"):
            with self.subTest(name=name):
                self.assertEqual(self.run_case(name)["queue_current"], "0")

    def test_context_negative_control_removing_full_id_admits_old_proxy(self) -> None:
        parts = prefix() + production_parts() + HARNESS_SUFFIX
        guard = "ev.editingContextId == s.editingContextId &&"
        self.assertEqual(parts.count(guard), 1)
        tmp, binary = compile_harness(parts.replace(guard, "true &&", 1), "context-red")
        try:
            result = subprocess.run([str(binary), "queued_full_id"], check=True, capture_output=True, text=True)
            state = dict(token.split("=", 1) for token in result.stdout.strip().split(" "))
            self.assertEqual(state["queue_current"], "1", "negative control must admit the old 64bit proxy")
        finally:
            tmp.cleanup()

    def test_context_negative_control_removing_live_guard_admits_retired_proxy(self) -> None:
        parts = prefix() + production_parts() + HARNESS_SUFFIX
        guard = "s.editingContextLive && !s.editorRetired &&"
        self.assertEqual(parts.count(guard), 1)
        tmp, binary = compile_harness(parts.replace(guard, "true &&", 1), "retired-red")
        try:
            result = subprocess.run([str(binary), "queued_retired"], check=True, capture_output=True, text=True)
            state = dict(token.split("=", 1) for token in result.stdout.strip().split(" "))
            self.assertEqual(state["queue_current"], "1", "negative control must admit the retired proxy")
        finally:
            tmp.cleanup()

    def test_current_context_queues_full_selection_identity_and_range(self) -> None:
        state = self.run_case("valid")
        self.assertEqual(state["rc"], "0")
        self.assertEqual(state["events"], "1")
        self.assertEqual(state["kind"], "33")
        self.assertEqual(state["node"], "51")
        self.assertEqual(state["resource"], "9700")
        self.assertEqual(state["node_kind"], "5")
        self.assertEqual(state["projection"], "22")
        self.assertEqual(state["epoch"], "91")
        self.assertEqual(state["selection"], "0,12")
        self.assertEqual(state["forwarded"], "1:0:12")
        self.assertEqual(state["platform"], "0:12")

    def test_initial_word_echo_cannot_move_active_visual_extent(self):
        moving=self.run_case('moving_echo')
        self.assertEqual(moving['native'],'4:9')
        self.assertEqual(moving['platform'],'0:12')
        self.assertEqual(moving['selection'],'0,12')
        self.assertEqual(moving['events'],'1')
        self.assertEqual(moving['redraw'],'0')
        terminal=self.run_case('terminal_echo')
        self.assertEqual(terminal['native'],'0:12')
        self.assertEqual(terminal['redraw'],'1')

    def test_platform_echo_of_native_caret_still_reaches_window(self) -> None:
        """平台装好人的落点后回声同一个值：native 侧 changed=0 也必须转发给窗口。

        判重口径是"窗口已经收到过哪个观测"，不是 native 自己的 caret 或差分推送目标。
        按后者判重就是 09-30 首字静默丢失的根因：命中测试先把 native 落点写成命中值，
        平台回声的正是同一个值，观测被吞掉，窗口永远不知道"平台已安装人的落点"，人类
        锚只 recorded 不 taken，紧随的键入被 selection_native_alignment_required 拒掉。
        redraw=0 同时钉住"纯视觉投影不 bump 场景版本"这条既有约定没有被顺手改掉。
        """
        state = self.run_case("echo_same_value")
        self.assertEqual(state["rc"], "0")
        self.assertEqual(state["events1"], "1")
        self.assertEqual(state["events"], "1")
        self.assertEqual(state["redraw"], "0")
        self.assertEqual(state["kind"], "33")
        self.assertEqual(state["selection"], "12,12")
        self.assertEqual(state["forwarded"], "1:12:12")
        self.assertEqual(state["platform"], "12:12")

    def test_repeat_of_already_forwarded_observation_is_deduped(self) -> None:
        """同值第二次不再入队：转发不能自激成"平台装→native 推→平台装"的回路。"""
        state = self.run_case("repeat_same")
        self.assertEqual((state["rc"], state["rc2"]), ("0", "0"))
        # 判据主体是增量（第二次不得再入队），同时钉住第一次确实入队过：前者咬住
        # "无条件转发"的自激变异，后者保证这条不会因为"什么都不转发"而假绿。
        self.assertEqual(state["events1"], "1")
        self.assertEqual(state["events"], state["events1"])
        self.assertEqual(state["redraw"], "0")
        self.assertEqual(state["selection"], "12,12")
        self.assertEqual(state["forwarded"], "1:12:12")

    def test_stale_context_and_rebound_accepted_node_do_not_enqueue(self) -> None:
        for scenario in ("stale_context", "wrong_binding"):
            with self.subTest(scenario=scenario):
                state = self.run_case(scenario)
                self.assertEqual(state["rc"], "1")
                self.assertEqual(state["events"], "0")
                self.assertEqual(state["redraw"], "0")

    def test_snapshot_consumes_only_current_binding_epoch_before_ledger_update(self) -> None:
        source = SNAPSHOT_WINDOW.read_text(encoding="utf-8")
        start = source.index("} else if (nativeEvent.eventKind == 33u32) {")
        end = source.index("} else if (nativeEvent.eventKind == 41u32) {", start)
        branch = source[start:end]
        self.assertIn("currentAcceptedBindingEpoch(resolved) == nativeEvent.acceptedBindingEpoch", branch)
        self.assertIn("rememberInteraction(resolved, 33", branch)
        self.assertIn("resolvePlatformSelectionEvent(nativeEvent", branch)
        resolver = extract_function(source, "    private func resolvePlatformSelectionEvent(")
        self.assertIn("nativeInputScene.resolveSelection", resolver)
        self.assertIn("resolveOwnedRangeContinuation", resolver)
        self.assertIn("nativeEvent.recordIndex != 0u32", resolver)
        self.assertIn("eventText != mirror.text", resolver)


class ForwardingMutationControlTest(unittest.TestCase):
    """非空跑控制：把摘录里的转发判据改掉，对应不变量必须当场翻。

    只改内存中的摘录文本，生产 `ohos_renderer.cpp` 一个字不动。没有这两条，上面
    "回声仍然转发"与"同值不自激"可能因为 harness 压根没编到生产判据而永远绿 ——
    本轮就真出现过：生产加了判重函数，harness 的 stand-in 没跟上，setUpClass 编译
    失败被 `check=True` 吞掉 stderr，只看得到 exit 1。
    """

    def mutate(self, replacement: str) -> dict[str, dict[str, str]]:
        parts = production_parts()
        self.assertEqual(parts.count(FORWARD_ANCHOR), 1,
                         "生产转发判据锚点不再唯一，变异控制已经指不到那条判据")
        temp, binary = compile_harness(
            HARNESS_PREFIX + parts.replace(FORWARD_ANCHOR, replacement) + HARNESS_SUFFIX,
            "red", allow_unused=True)
        self.addCleanup(temp.cleanup)
        return run_scenarios(binary)

    def test_dedup_by_native_changed_loses_platform_echo(self) -> None:
        """按 native `changed` 判重（H1-R.a 修复前的口径）必须丢掉平台回声。"""
        states = self.mutate("const bool forward = changed;")
        self.assertEqual(states["echo_same_value"]["events"], "0")
        self.assertNotIn("kind", states["echo_same_value"])
        # 变异是定向翻转，不是把整个 setter 弄坏：真实变更的场景照旧入队。
        self.assertEqual(states["valid"]["events"], "1")

    def test_unconditional_forwarding_self_excites(self) -> None:
        """无条件转发必须让同值第二次也入队（"装→推→装"自激）。"""
        states = self.mutate("const bool forward = true;")
        self.assertEqual(states["repeat_same"]["events1"], "1")
        self.assertEqual(states["repeat_same"]["events"], "2")
        self.assertEqual(states["valid"]["events"], "1")


if __name__ == "__main__":
    unittest.main()

"""Exercise the production OHOS accepted-scene editing reconcile without an HAP.

The C++ harness extracts the actual reconcile function from ohos_renderer.cpp;
only the platform types and redraw sink are replaced. This keeps the decisive
state transition under test while avoiding NDK headers and a device build.
"""

from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


RENDERER = Path(__file__).resolve().parents[1] / "host" / "ohos_renderer.cpp"
FUNCTION_START = "static void pushPendingEndLocked("
FUNCTION_SECOND = "static void syncEditingBufferAfterAcceptedSceneLocked(Session *s)"
FUNCTION_END = "// 一次性裁决一张未 ACK 的票据"

# H 线（可视编辑包 A1）：被测的 sync 在换绑 / 外部换版 / 认领三条路径上都读
# accepted 段镜像声明，owned 身份与镜像字段是它的判据来源。替身用**生产原文**
# 注入（锚点即生产声明行）：字段漂移会在这里抛错或让摘录编不过，而不是让那道
# 换绑借用门静默少判。
OWNED_ID_ANCHORS = ('    bool ownedTextSessionEnabled = false;',
                    '    uint64_t ownedTextSessionBindingEpoch = 0;')
MIRROR_ANCHORS = ('    struct OwnedMirrorDeclaration {',
                  '    int64_t editingMirrorOwnerVersion = -1;')
MIRROR_HELPER = ("static const Session::OwnedMirrorDeclaration *ownedMirrorDeclarationLocked(const Session &s,")
KIND_CONSTANTS = ("constexpr uint32_t kKindTextInput",
                  "constexpr uint32_t kKindIntegerInput",
                  "constexpr uint32_t kKindMultiline")


def span(text: str, start_anchor: str, end_anchor: str) -> str:
    """生产原文切片（含两端）。"""
    start = text.index(start_anchor)
    return text[start:text.index(end_anchor, start) + len(end_anchor)]


def constant_line(text: str, marker: str) -> str:
    start = text.index(marker)
    return text[start:text.index("\n", start)]


def harness_text() -> str:
    """Session 替身注入生产 owned/镜像字段，再接摘录的生产函数。"""
    source = RENDERER.read_text(encoding="utf-8")
    prefix = HARNESS_PREFIX
    for token, anchors in (("%OWNED_ID_FIELDS%", OWNED_ID_ANCHORS),
                           ("%MIRROR_FIELDS%", MIRROR_ANCHORS)):
        assert prefix.count(token) == 1, f"占位符 {token} 不再唯一"
        prefix = prefix.replace(token, span(source, *anchors))
    return prefix + production_function(source) + HARNESS_SUFFIX


def extract_braced(source: str, signature: str) -> str:
    start = source.index(signature)
    opening = source.index("{", start)
    depth = 0
    for index in range(opening, len(source)):
        depth += (source[index] == "{") - (source[index] == "}")
        if depth == 0:
            return source[start:index + 1]
    raise ValueError("unterminated method")


def production_function(source: str | None = None) -> str:
    source = source if source is not None else RENDERER.read_text(encoding="utf-8")
    push = extract_braced(source, FUNCTION_START)
    clamp = extract_braced(source,
        "uint32_t clampToCodePointBoundary(const std::u16string &text, uint32_t offset)")
    # 镜像声明就绪门与它依赖的可编辑 kind 集合都取真实生产函数：sync 的三条路径
    # （换绑 / 外部换版 / 认领）判据就在这道门里，桩掉它等于用自己的假设验自己。
    editable_kind = extract_braced(source, "bool isEditableTextKind(uint32_t kind)")
    mirror = extract_braced(source, MIRROR_HELPER)
    constants = "\n".join(constant_line(source, marker) for marker in KIND_CONSTANTS)
    start = source.index(FUNCTION_SECOND)
    end = source.index(FUNCTION_END, start)
    return (clamp + "\n\n" + constants + "\n" + editable_kind + "\n\n" + mirror + "\n\n"
            + push + "\n\n" + source[start:end])


HARNESS_PREFIX = r"""
#include <algorithm>
#include <atomic>
#include <cstdint>
#include <deque>
#include <memory>
#include <string>
#include <vector>
#include <iostream>

#define RLOGI(...) ((void)0)
#define RLOGW(...) ((void)0)

struct NodePod {
    uint64_t nodeId = 51;
    int64_t resourceId = 9700;
    uint32_t nodeKind = 5;
    uint32_t isReadOnly = 0;
    uint32_t isInteractive = 1;
    uint32_t preservesActiveLocalText = 0;
    uint64_t projectionVersion = 11;
    uint64_t acceptedBindingEpoch = 1;
};
struct SceneNode {
    NodePod pod;
    std::string semanticId = "generated-name";
    std::string value = "owner";
};
struct Session {
  uint32_t textMenuIntent=0;
  bool caretBlinkResetPending=false;
  int32_t caretAffinity=0;
  bool humanCaretNotificationPending=false;
    bool editing = true;
    bool ownsTextSession = false;
    std::vector<SceneNode> accepted{SceneNode{}};
    uint64_t editingNodeId = 51;
    int64_t editingResourceId = 9700;
    uint32_t editingNodeKind = 5;
    std::string editingFieldName = "generated-name";
    // R1（2026-10-02）：与生产对齐——完整绑定身份 + 出生票据 lineage + 待发
    // end 队列（旧 pendingImeDetach/pendingSettleOnDetach 单槽已退役）。
    uint64_t editingAcceptedBindingEpoch = 1;
    uint64_t editingBornTicketId = 0;
    uint64_t acceptedPaintTicketId = 0;
    uint64_t acceptedProjectionVersion = 0;
    struct PendingEnd {
        int64_t contextId = 0;
        std::string fieldName;
        bool settleOnDelivery = false;
    };
    std::deque<PendingEnd> pendingEnds;
    bool editorRetired = false;
    bool editingContextLive = true;
    bool previewActive = true;
    std::u16string previewText = u"preview";
    bool markedActive = false;
    bool reconcileNotifyPending = false;
    uint64_t editingContextBaseVersion = 10;
    uint64_t editingProjectionVersion = 10;
    int64_t editingContextId = 7;
    int64_t reconcileOldContextId = 0;
    std::u16string editingText = u"owner-draft";
    uint32_t markedStart = 0, markedEnd = 0;
    uint32_t caretUtf16 = 4, selStartUtf16 = 2, selEndUtf16 = 5;
    bool editingTapPending = false;
    bool focusNotifyPending = false;
    // H 线 owned 会话锚点身份 + A1 三段镜像声明（含 editingMirrorOwnerVersion）：
    // 由 harness_text() 用生产原文切片替换下面两个占位符（纯数据字段取原文，
    // 字段一改就编译失败，不会让镜像借用门静默少判）。
    %OWNED_ID_FIELDS%
    %MIRROR_FIELDS%
};

static bool editorOwnsTextSession(const Session &s) { return s.ownsTextSession; }

static std::u16string utf8ToUtf16(const std::string &value) {
    return std::u16string(value.begin(), value.end());
}
struct RedrawJob {};
struct RenderQueue {
    int posts = 0;
    void post(std::shared_ptr<RedrawJob>) { ++posts; }
};
static RenderQueue g_render;
static std::atomic<int64_t> g_nextEditingContextId{100};

// N1 之后，被测 reconcile 在换绑 / 外部换版 / 节点消失三条路径上都要取消在飞的
// 恢复票据。票据机制本身由 test_text_proxy_recovery_native.py 覆盖，这里用记录型
// 桩：取消理由进入输出，失败时可回看，不做静默 no-op。
static std::vector<std::string> g_cancelledRestoreReasons;
static void cancelProxyRestoreRequest(Session &s, const char *reason) {
    (void)s;
    g_cancelledRestoreReasons.push_back(reason == nullptr ? "" : reason);
}
"""


HARNESS_SUFFIX = r"""
int main(int argc, char **argv) {
    if (argc != 2) return 2;
    Session s;
    const std::string scenario = argv[1];
    if (scenario == "rebind") {
        s.accepted[0].semanticId = "another-field";
    } else if (scenario == "authorized_reorder") {
        s.accepted[0].pod.preservesActiveLocalText = 1;
    } else if (scenario == "owned_same_value_external") {
        s.ownsTextSession = true;
        s.previewActive = false;
        s.editingText = u"owner";
    } else if (scenario == "unowned_same_value") {
        s.previewActive = false;
        s.editingText = u"owner";
    } else if (scenario != "reorder" && scenario != "same_value_external") {
        return 3;
    }
    syncEditingBufferAfterAcceptedSceneLocked(&s);
    std::string draft(s.editingText.begin(), s.editingText.end());
    std::string preview(s.previewText.begin(), s.previewText.end());
    std::string cancelLog;
    for (const std::string &reason : g_cancelledRestoreReasons) {
        if (!cancelLog.empty()) cancelLog += "|";
        cancelLog += reason;
    }
    std::cout << "context=" << s.editingContextId
              << " base=" << s.editingContextBaseVersion
              << " projection=" << s.editingProjectionVersion
              << " draft=" << draft
              << " selection=" << s.selStartUtf16 << "," << s.selEndUtf16
              << " preview=" << (s.previewActive ? preview : "none")
              << " old_context=" << s.reconcileOldContextId
              << " reconcile=" << s.reconcileNotifyPending
              << " detach=" << (s.pendingEnds.empty() ? 0 : 1)
              << " cancel=" << (cancelLog.empty() ? "none" : cancelLog) << "\n";
}
"""


class GeneratedReorderEditingContextTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        compiler = shutil.which("clang++")
        if compiler is None:
            raise unittest.SkipTest("clang++ unavailable")
        cls.temp = tempfile.TemporaryDirectory(prefix="cjgui-ohos-editing-reconcile-")
        root = Path(cls.temp.name)
        source = root / "reconcile.cpp"
        cls.binary = root / "reconcile"
        source.write_text(harness_text(), encoding="utf-8")
        subprocess.run(
            [compiler, "-std=c++17", "-Wall", "-Wextra", "-Werror", str(source), "-o", str(cls.binary)],
            check=True,
            capture_output=True,
            text=True,
        )

    @classmethod
    def tearDownClass(cls) -> None:
        if hasattr(cls, "temp"):
            cls.temp.cleanup()

    def state(self, scenario: str) -> dict[str, str]:
        result = subprocess.run([str(self.binary), scenario], check=True, capture_output=True, text=True)
        return dict(token.split("=", 1) for token in result.stdout.strip().split(" "))

    def test_unflagged_scene_replacement_rotates_context_even_for_same_key(self) -> None:
        state = self.state("reorder")
        # RED before the Cangjie owner-revision handoff: a pure generated
        # reorder reached this native function without a preserve hint and
        # discarded the draft. The window now has to supply the hint; native
        # must stay conservative when it is absent.
        self.assertNotEqual(state["context"], "7")
        self.assertEqual(state["base"], "11")
        self.assertEqual(state["projection"], "11")
        self.assertEqual(state["draft"], "owner")
        # R3（2026-10-01 已并入生产）：上下文重建按新正文长度收敛并**保持**
        # 非空选区（原"重置为末尾 caret"正是中段选区双切换后折叠的根源）。
        self.assertEqual(state["selection"], "2,5")
        self.assertEqual(state["preview"], "none")
        self.assertEqual(state["reconcile"], "1")

    def test_same_value_external_owner_replacement_still_rotates_context(self) -> None:
        state = self.state("same_value_external")
        self.assertNotEqual(state["context"], "7")
        self.assertEqual(state["draft"], "owner")
        self.assertEqual(state["selection"], "2,5")  # 同上：重建保持非空选区
        self.assertEqual(state["preview"], "none")
        self.assertEqual(state["old_context"], "7")
        self.assertEqual(state["reconcile"], "1")

    def test_explicit_continuity_signal_already_preserves_reorder_draft(self) -> None:
        state = self.state("authorized_reorder")
        self.assertEqual(state["context"], "7")
        self.assertEqual(state["base"], "11")
        self.assertEqual(state["draft"], "owner-draft")
        self.assertEqual(state["selection"], "2,5")
        self.assertEqual(state["preview"], "preview")

    def test_owned_same_value_external_requires_explicit_local_admission(self) -> None:
        state = self.state("owned_same_value_external")
        self.assertNotEqual(state["context"], "7")
        self.assertEqual(state["reconcile"], "1")
        self.assertEqual(state["cancel"], "external_version")

    def test_unowned_same_value_legacy_continuation_is_preserved(self) -> None:
        state = self.state("unowned_same_value")
        self.assertEqual(state["context"], "7")
        self.assertEqual(state["reconcile"], "0")

    def test_same_key_changed_binding_retires_old_context(self) -> None:
        state = self.state("rebind")
        self.assertEqual(state["context"], "7")
        self.assertEqual(state["detach"], "1")
        self.assertEqual(state["preview"], "none")


if __name__ == "__main__":
    unittest.main()

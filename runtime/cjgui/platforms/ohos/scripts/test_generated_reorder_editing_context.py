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
FUNCTION_START = "static void syncEditingBufferAfterAcceptedSceneLocked(Session *s)"
FUNCTION_END = "// 一次性裁决一张未 ACK 的票据"


def production_function() -> str:
    source = RENDERER.read_text(encoding="utf-8")
    start = source.index(FUNCTION_START)
    end = source.index(FUNCTION_END, start)
    return source[start:end]


HARNESS_PREFIX = r"""
#include <algorithm>
#include <atomic>
#include <cstdint>
#include <memory>
#include <string>
#include <vector>
#include <iostream>

#define RLOGI(...) ((void)0)

struct NodePod {
    uint64_t nodeId = 51;
    int64_t resourceId = 9700;
    uint32_t nodeKind = 5;
    uint32_t isReadOnly = 0;
    uint32_t isInteractive = 1;
    uint32_t preservesActiveLocalText = 0;
    uint64_t projectionVersion = 11;
};
struct SceneNode {
    NodePod pod;
    std::string semanticId = "generated-name";
    std::string value = "owner";
};
struct Session {
    bool editing = true;
    std::vector<SceneNode> accepted{SceneNode{}};
    uint64_t editingNodeId = 51;
    int64_t editingResourceId = 9700;
    uint32_t editingNodeKind = 5;
    std::string editingFieldName = "generated-name";
    bool pendingImeDetach = false;
    bool pendingSettleOnDetach = false;
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
};

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
    } else if (scenario != "reorder" && scenario != "same_value_external") {
        return 3;
    }
    syncEditingBufferAfterAcceptedSceneLocked(&s);
    std::string draft(s.editingText.begin(), s.editingText.end());
    std::string preview(s.previewText.begin(), s.previewText.end());
    std::cout << "context=" << s.editingContextId
              << " base=" << s.editingContextBaseVersion
              << " projection=" << s.editingProjectionVersion
              << " draft=" << draft
              << " selection=" << s.selStartUtf16 << "," << s.selEndUtf16
              << " preview=" << (s.previewActive ? preview : "none")
              << " old_context=" << s.reconcileOldContextId
              << " reconcile=" << s.reconcileNotifyPending
              << " detach=" << s.pendingImeDetach << "\n";
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
        source.write_text(HARNESS_PREFIX + production_function() + HARNESS_SUFFIX, encoding="utf-8")
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
        self.assertEqual(state["selection"], "5,5")
        self.assertEqual(state["preview"], "none")
        self.assertEqual(state["reconcile"], "1")

    def test_same_value_external_owner_replacement_still_rotates_context(self) -> None:
        state = self.state("same_value_external")
        self.assertNotEqual(state["context"], "7")
        self.assertEqual(state["draft"], "owner")
        self.assertEqual(state["selection"], "5,5")
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

    def test_same_key_changed_binding_retires_old_context(self) -> None:
        state = self.state("rebind")
        self.assertEqual(state["context"], "7")
        self.assertEqual(state["detach"], "1")
        self.assertEqual(state["preview"], "none")


if __name__ == "__main__":
    unittest.main()

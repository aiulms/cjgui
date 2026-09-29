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


def extract(source: str, start: str, end: str) -> str:
    begin = source.index(start)
    finish = source.index(end, begin)
    return source[begin:finish]


def production_parts() -> str:
    source = RENDERER.read_text(encoding="utf-8")
    finding = extract(source, "Session *findEditingSessionLocked()", "// IME 视角的缓冲")
    context = extract(source, "static Session *takeEditingContextLocked(int64_t contextId)", "// 普通编辑变化（提交）")
    event = extract(source, "bool editorEnqueueSelectionChanged(Session &s, uint32_t start, uint32_t end)", "// 失焦结算")
    setter = extract(source, 'extern "C" int32_t ohos_renderer_ime_set_selection_ctx', "// 焦点请求出口")
    return finding + event + context + setter


HARNESS_PREFIX = r"""
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
  int64_t resourceId = -1;
};
struct Session {
  bool inUse = true, editing = true, editorRetired = false;
  bool editingContextLive = true;
  int64_t editingContextId = 7;
  uint64_t editingNodeId = 51, editingProjectionVersion = 22;
  int64_t editingResourceId = 9700;
  uint32_t editingNodeKind = 5, selStartUtf16 = 12, selEndUtf16 = 12, caretUtf16 = 12;
  std::vector<SceneNode> accepted{SceneNode{}};
  std::vector<QueuedEvent> events;
};
struct SessionTable { std::mutex lock; Session sessions[1]; };
static SessionTable g_sessions;
static std::u16string composedBuffer(const Session &) { return u"hello world!"; }
static uint32_t clampToCodePointBoundary(const std::u16string &, uint32_t index) { return index; }
static bool g_redrawPosted = false;
struct RedrawJob {};
struct RenderQueue { void post(std::shared_ptr<RedrawJob>) { g_redrawPosted = true; } };
static RenderQueue g_render;
"""


HARNESS_SUFFIX = r"""
int main(int argc, char **argv) {
  if (argc != 2) return 2;
  Session &s = g_sessions.sessions[0];
  const std::string scenario(argv[1]);
  if (scenario == "wrong_binding") {
    s.accepted[0].pod.nodeId = 52;
  } else if (scenario != "valid" && scenario != "stale_context") {
    return 3;
  }
  const int64_t context = scenario == "stale_context" ? 8 : 7;
  const int32_t rc = ohos_renderer_ime_set_selection_ctx(0, 12, context);
  std::cout << "rc=" << rc << " events=" << s.events.size()
            << " redraw=" << (g_redrawPosted ? 1 : 0);
  if (!s.events.empty()) {
    const QueuedEvent &ev = s.events.back();
    std::cout << " kind=" << ev.kind << " node=" << ev.nodeId
              << " resource=" << ev.resourceId << " node_kind=" << ev.nodeKind
              << " projection=" << ev.projectionVersion << " epoch=" << ev.acceptedBindingEpoch
              << " selection=" << ev.selectionStart << "," << ev.selectionEnd;
  }
  std::cout << "\n";
  return 0;
}
"""


class OhosImeSelectionEventTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        compiler = shutil.which("clang++")
        if compiler is None:
            raise unittest.SkipTest("clang++ unavailable")
        cls.temp = tempfile.TemporaryDirectory(prefix="cjgui-ohos-ime-selection-")
        root = Path(cls.temp.name)
        source = root / "selection.cpp"
        cls.binary = root / "selection"
        source.write_text(
            HARNESS_PREFIX + production_parts() + HARNESS_SUFFIX,
            encoding="utf-8",
        )
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

    def run_case(self, scenario: str) -> dict[str, str]:
        result = subprocess.run([str(self.binary), scenario], check=True, capture_output=True, text=True)
        return dict(token.split("=", 1) for token in result.stdout.strip().split(" "))

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
        self.assertIn("nativeInputScene.resolveSelection", branch)


if __name__ == "__main__":
    unittest.main()

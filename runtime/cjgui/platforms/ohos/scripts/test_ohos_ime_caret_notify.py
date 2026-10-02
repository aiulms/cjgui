"""native 落点 → 平台代理 的差分推送（H1-3）不装 HAP 的确定性验证。

反例来源（华为模拟器系统输入注入实测，run n2geo-20260930c）：命中把 native caret
移到 8，但已挂载的隐藏代理仍停在自己的旧偏移 1，人的下一次键入插到正文开头
（owner 变成 'aK1lpha one…'）。修复是 pump 按差分把 native 落点推给平台
（action=caret），并让平台回声/恢复 ACK/挂载通知同步账本，避免自激。

harness 只摘取 pump 里的三段通知（focus / reconcile / caret），用桩环境编译后
按场景驱动；两条负控按同一套源码做删除变异，证明断言确实区分机制。
"""

from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
RENDERER = ROOT / "host" / "ohos_renderer.cpp"

REGION_START = "    if (s->focusNotifyPending) {"
REGION_END = "    // Blink is visual work"
CARET_ANCHOR = "    // native 落点 → 平台代理（H1-3）"
LEDGER_SYNC = "            s->selPlatformStart = a;\n            s->selPlatformEnd = b;\n"


def notify_region(source: str) -> str:
    start = source.index(REGION_START)
    end = source.index(REGION_END, start)
    return source[start:end]


HARNESS_PREFIX = r"""
#include <algorithm>
#include <cstdint>
#include <iostream>
#include <string>
#include <vector>

#define RLOGI(...) ((void)0)

struct GlobalLock { void lock() {} void unlock() {} };
static GlobalLock g;
static std::vector<std::string> g_payloads;
static void captureSink(const char *payload) { g_payloads.emplace_back(payload); }
static void (*g_focusRequestSink)(const char *) = captureSink;
static void appendJsonEscaped(std::string &out, const std::string &value) { out += value; }

struct Session {
  struct {bool active=false,anchorReady=false,terminal=false;} selectionDrag;
  struct ProxyRestoreRequest {
    uint64_t requestId = 0;
    bool armed = false;
    bool awaitingAck = false;
    bool platformInstalled = false;
  };
  bool editing = true;
  bool editingContextLive = true;
  int64_t editingContextId = 7;
  std::string editingFieldName = "pharos-editor-body";
  bool humanCaretNotificationPending = false;
  bool focusNotifyPending = false;
  bool reconcileNotifyPending = false;
  int64_t reconcileOldContextId = 0;
  uint32_t caretUtf16 = 12;
  uint32_t selStartUtf16 = 12;
  uint32_t selEndUtf16 = 12;
  uint32_t selPlatformStart = 12;
  uint32_t selPlatformEnd = 12;
  // 窗口已收到过哪条落点观测（kind-33 判重用）。与 selPlatform* 不是一回事，
  // 生产在 focus/reconcile 重挂时会把它作废，让新上下文的首条观测必定转发。
  uint32_t selForwardedStart = 0;
  uint32_t selForwardedEnd = 0;
  bool selForwardedValid = false;
  ProxyRestoreRequest proxyRestore;
};

static void pumpNotify(Session *s) {
"""

HARNESS_SUFFIX = r"""
}

static void report() {
  std::cout << "payloads=" << g_payloads.size() << "\n";
  for (size_t i = 0; i < g_payloads.size(); ++i) {
    std::cout << "p" << i << "=" << g_payloads[i] << "\n";
  }
}

int main(int argc, char **argv) {
  if (argc != 2) return 2;
  const std::string scenario(argv[1]);
  Session session;
  Session *s = &session;
  // 先假设窗口已经收到过一条观测（值取 4,9，与下面任何 caret 账本值都不同）。
  // 不设这个前置，"重挂后作废判重账本"就只是 false→false，断言永远成立、什么也没验。
  s->selForwardedValid = true;
  s->selForwardedStart = 4;
  s->selForwardedEnd = 9;
  if (scenario == "same_human_anchor" || scenario == "human_no_sink") {
    s->humanCaretNotificationPending = true;
    s->selForwardedValid = false;
    if (scenario == "human_no_sink") g_focusRequestSink = nullptr;
  } else if (scenario == "moving" || scenario == "moving_initial" || scenario == "terminal") {
    s->selectionDrag.active=s->selectionDrag.anchorReady=true;
    s->selectionDrag.terminal=scenario=="terminal";
    s->humanCaretNotificationPending=scenario=="moving_initial";
    s->selStartUtf16=4;s->selEndUtf16=9;
  } else if (scenario == "hit_move" || scenario == "twice") {
    // 命中/长按全选把 native 落点挪走，账本仍是平台已知值
    s->selStartUtf16 = 0;
    s->selEndUtf16 = 44;
  } else if (scenario == "in_sync") {
    s->selStartUtf16 = 0;
    s->selEndUtf16 = 44;
    s->selPlatformStart = 0;
    s->selPlatformEnd = 44;
  } else if (scenario == "focus_resync") {
    s->focusNotifyPending = true;
    s->selStartUtf16 = 0;
    s->selEndUtf16 = 44;
  } else if (scenario == "reconcile_resync") {
    s->reconcileNotifyPending = true;
    s->reconcileOldContextId = 6;
    s->selStartUtf16 = 0;
    s->selEndUtf16 = 44;
  } else if (scenario == "restore_live") {
    s->proxyRestore.requestId = 5;
    s->proxyRestore.awaitingAck = true;
    s->selStartUtf16 = 0;
    s->selEndUtf16 = 44;
  } else if (scenario == "not_editing") {
    s->editing = false;
    s->selStartUtf16 = 0;
    s->selEndUtf16 = 44;
  } else if (scenario == "reversed") {
    s->selStartUtf16 = 44;
    s->selEndUtf16 = 0;
  } else {
    return 3;
  }
  pumpNotify(s);
  if (scenario == "human_no_sink") {
    std::cout << "pending_without_sink=" << s->humanCaretNotificationPending << "\n";
    g_focusRequestSink = captureSink;
    pumpNotify(s);
  }
  if (scenario == "twice" || scenario == "same_human_anchor") {
    pumpNotify(s);   // 自激检查：账本已同步，第二轮不得再推
  }
  report();
  std::cout << "ledger=" << s->selPlatformStart << "," << s->selPlatformEnd << "\n";
  std::cout << "forwarded=" << (s->selForwardedValid ? 1 : 0)
            << "," << s->selForwardedStart << "," << s->selForwardedEnd << "\n";
  return 0;
}
"""


def build(source_text: str, root: Path, name: str) -> Path:
    compiler = shutil.which("clang++")
    if compiler is None:
        raise unittest.SkipTest("clang++ unavailable")
    cpp = root / f"{name}.cpp"
    binary = root / name
    cpp.write_text(source_text, encoding="utf-8")
    completed = subprocess.run(
        [compiler, "-std=c++17", "-Wall", "-Wextra", "-Werror", str(cpp), "-o", str(binary)],
        capture_output=True, text=True,
    )
    if completed.returncode != 0:
        # `check=True` + `capture_output=True` 只会抛出"returned non-zero exit status 1"，
        # clang++ 的真实报错被吞掉，外面根本看不出是 harness 落后还是产品坏了。
        raise RuntimeError(f"harness build failed ({name}):\n{completed.stderr}")
    return binary


class OhosImeCaretNotifyTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.source = RENDERER.read_text(encoding="utf-8")
        cls.region = notify_region(cls.source)
        cls.temp = tempfile.TemporaryDirectory(prefix="cjgui-ohos-caret-notify-")
        root = Path(cls.temp.name)
        cls.binary = build(HARNESS_PREFIX + cls.region + HARNESS_SUFFIX, root, "caret_notify")
        # 负控 1：整段 caret 推送被删（只留 focus/reconcile）
        without_notify = cls.region[:cls.region.index(CARET_ANCHOR)]
        cls.binary_no_notify = build(
            HARNESS_PREFIX + without_notify + HARNESS_SUFFIX, root, "caret_notify_missing")
        # 负控 2：推送后不同步账本 → 每轮都重推（自激）
        if LEDGER_SYNC not in cls.region:
            raise AssertionError(f"ledger sync anchor missing from pump region:\n{LEDGER_SYNC!r}")
        cls.binary_no_ledger = build(
            HARNESS_PREFIX + cls.region.replace(LEDGER_SYNC, "") + HARNESS_SUFFIX,
            root, "caret_notify_no_ledger")

    def test_same_value_new_human_anchor_sends_one_install_notification(self):
        p = subprocess.run([str(self.binary), "same_human_anchor"], capture_output=True, text=True)
        self.assertEqual(p.returncode, 0, p.stderr)
        self.assertIn('payloads=1', p.stdout)
        self.assertIn('"action":"caret"', p.stdout)

    def test_unregistered_sink_does_not_consume_human_install_intent(self):
        state = self.run_case(self.binary, "human_no_sink")
        self.assertEqual(state["pending_without_sink"], "1")
        self.assertEqual(state["payloads"], "1")

    @classmethod
    def tearDownClass(cls) -> None:
        if hasattr(cls, "temp"):
            cls.temp.cleanup()

    def run_case(self, binary: Path, scenario: str) -> dict[str, str]:
        result = subprocess.run([str(binary), scenario], check=True, capture_output=True, text=True)
        # 负载是 JSON（含空格与 '='），只按行首的 key= 解析，其余原样保留为值。
        state: dict[str, str] = {}
        for line in result.stdout.strip().splitlines():
            key, sep, value = line.partition("=")
            if sep:
                state[key] = value
        return state

    def test_native_caret_move_pushes_context_selection(self) -> None:
        state = self.run_case(self.binary, "hit_move")
        self.assertEqual(state["payloads"], "1")
        self.assertEqual(state["p0"], '{"action":"caret","context":7,"selStart":0,"selEnd":44}')
        self.assertEqual(state["ledger"], "0,44")
        # caret 差分推送**不**作废判重账本：它不是重挂，窗口收到过的观测仍然算数。
        # 与下一条互为夹逼 —— 两边都断言"forwarded 保持 1,4,9"或都断言作废，就分不出
        # "重挂取初值"与"native 推落点"这两种语义了。
        self.assertEqual(state["forwarded"], "1,4,9")

    def test_reversed_session_selection_is_normalized(self) -> None:
        state = self.run_case(self.binary, "reversed")
        self.assertEqual(state["p0"], '{"action":"caret","context":7,"selStart":0,"selEnd":44}')

    def test_platform_known_selection_does_not_renotify(self) -> None:
        self.assertEqual(self.run_case(self.binary, "in_sync")["payloads"], "0")
        # 连续两轮 pump 只推一次：账本同步阻断"平台装→native 推"自激
        self.assertEqual(self.run_case(self.binary, "twice")["payloads"], "1")

    def test_focus_and_reconcile_snapshots_resync_ledger(self) -> None:
        for scenario, action in (("focus_resync", "focus"), ("reconcile_resync", "reconcile")):
            with self.subTest(scenario=scenario):
                state = self.run_case(self.binary, scenario)
                self.assertEqual(state["payloads"], "1")
                self.assertIn(f'"action":"{action}"', state["p0"])
                self.assertNotIn('"action":"caret"', state["p0"])
                self.assertEqual(state["ledger"], "0,44")
                # 重挂后平台按新上下文快照重新取初值，所以判重账本必须作废：
                # 新上下文的第一条落点观测对窗口是新事实，即使值与旧上下文最后一次
                # 转发值相同（否则窗口永远不知道"这个上下文已装好落点"，人类锚只
                # recorded 不 taken，H1-R.a 首字丢失就是这么来的）。
                self.assertEqual(state["forwarded"], "0,4,9")

    def test_restore_transaction_and_closed_session_stay_silent(self) -> None:
        for scenario in ("restore_live", "not_editing"):
            with self.subTest(scenario=scenario):
                self.assertEqual(self.run_case(self.binary, scenario)["payloads"], "0")

    def test_negative_controls_discriminate(self) -> None:
        # 删掉推送：命中后平台永远学不到新落点
        self.assertEqual(self.run_case(self.binary_no_notify, "hit_move")["payloads"], "0")
        # 删掉账本同步：每轮 pump 都重推同一落点
        self.assertEqual(self.run_case(self.binary_no_ledger, "twice")["payloads"], "2")

    def test_platform_echo_setter_syncs_ledger(self) -> None:
        setter = self.source[
            self.source.index('extern "C" int32_t ohos_renderer_ime_set_selection_ctx'):]
        setter = setter[:setter.index("\n}\n") + 3]
        self.assertIn("s->selPlatformStart = a;", setter)
        self.assertIn("s->selPlatformEnd = b;", setter)

    def test_move_suppresses_install_storm_and_terminal_releases(self):
        for case,expected in [('moving',0),('moving_initial',1),('terminal',1)]:
            with self.subTest(case=case):
                result=subprocess.run([str(self.binary),case],capture_output=True,text=True)
                self.assertEqual(result.returncode,0,result.stderr)
                self.assertIn('payloads='+str(expected),result.stdout)

    def test_caret_hit_test_requests_redraw(self) -> None:
        # 光标/选区是纯视觉投影：命中后不显式重绘，画面上的光标停在上一处
        # （实测点第二行 native caret=18、画面光标仍在第一行行首）。
        start = self.source.index("caret hit applied tap=")
        block = self.source[start:self.source.index("    if (s->focusNotifyPending)", start)]
        self.assertIn("applySelectionHitLocked(*s, hitOperation, hitMode, caret", block)
        start = self.source.index("bool applySelectionHitLocked(")
        apply = self.source[start:self.source.index("\n}\n", start)]
        self.assertIn("caret = std::min(caret", apply)
        self.assertIn("g_render.post(std::make_shared<RedrawJob>());", apply)


if __name__ == "__main__":
    unittest.main()

#!/usr/bin/env python3
"""R1 票据生命周期（present → 提交 → settle → ACK）的真实状态机重放
（2026-10-02 Astra h-r1-source-admission）。

只读裁决：artifacts/consultations/h-r1-source-admission-astra/answer.md
与 answer-followup-1.md。

Astra 两轮都指出：既有用例要么用替身 `Job`/手工 `PendingSettlement`（
`test_r1_source_admission_native.py`），要么只跑 `WaitableJob`（
`test_r1_commit_order_native.py`）；**没有**把「真实 `PendingSettlement` + 真实
`settlePendingTicketLocked` + 真实闸门谓词」串成 actual present→提交→settle/ACK
的确定性命中链。本文件补上那一环。

逐字抽取（非重写）
  * `struct PendingSettlement`（含 S1 冻结声明表、settled/ticketId 终态字段）
  * `static uint32_t settlePendingTicketLocked(...)` 真实函数
  * `struct WaitableJob` / `JobPhase` / `JobKind` / `kRenderWaitTimeout` /
    `CJGUI_INTERNAL_RENDERER_PENDING`
  * configure 的「在途票据」闸门谓词、present 的推迟谓词、acknowledge 的
    结算守卫与回收块——都从真实函数体内**按位置切片**注入（源码改动会使切片
    定位失败，迫使本文件同步，避免副本静默漂移）

驱动的确定性时序
  1. 无票据：configure 允许。
  2. 已投递未结算票据：configure **具名拒绝**（PENDING）、present **推迟**
     （PENDING 并回显原票号）。
  3. job 未完成的结算 → REJECTED、settled=true，但 valid 仍为真 → configure
     **仍拒绝**（A1「已结算未 ACK 的票仍在」，本包关键不变量）。
  4. job 已 Committing → settle 返回 PENDING 且不落终态；finish(OK) 后再
     settle → ACCEPTED、帧号 +1、accepted 切到该候选。
  5. 重复 settle → 返回同一决策、重复结算计数 +1、帧号不二次推进。
  6. 未结算就 ACK → 拒绝（UNRESOLVED）且票据保留；结算后 ACK → valid=false。
  7. ACK 后 configure 允许。

方向性变异负控：把 configure 的闸门谓词改成恒假（忽略在途票据），第 2 步必须
翻红——证明该断言能检出「结算前开新候选」。

边界（本文件不假装覆盖）：owner 线程身份与分发顺序、生成结构替换
（`scene_transaction_busy`）不在四个被抽取函数能证明的范围内；见
`test_r1_commit_order_native.py` 与设备重放 `verify_r1_pre_permission_replay.py`。
"""
import pathlib
import re
import subprocess
import tempfile
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]
SOURCE = ROOT / "host" / "ohos_renderer.cpp"
SOURCE_TEXT = SOURCE.read_text()


def function(text, signature):
    start = text.index(signature)
    opening = text.index('{', start)
    tokens = re.compile(r'//[^\n]*|/\*[\s\S]*?\*/|"(?:\\.|[^"\\])*"|\'(?:\\.|[^\'\\])*\'|[{}]')
    depth = 0
    for match in tokens.finditer(text, opening):
        if match.group() == '{':
            depth += 1
        elif match.group() == '}':
            depth -= 1
            if depth == 0:
                return text[start:match.end()]
    raise ValueError(signature)


def line_containing(text, needle):
    for line in text.splitlines():
        if needle in line:
            return line
    raise ValueError(needle)


def block_at(text, start):
    """从 start 处的 '{' 起做花括号配对（跳过注释/字符串），返回整块文本。"""
    opening = text.index('{', start)
    tokens = re.compile(r'//[^\n]*|/\*[\s\S]*?\*/|"(?:\\.|[^"\\])*"|\'(?:\\.|[^\'\\])*\'|[{}]')
    depth = 0
    for match in tokens.finditer(text, opening):
        if match.group() == '{':
            depth += 1
        elif match.group() == '}':
            depth -= 1
            if depth == 0:
                return text[start:match.end()]
    raise ValueError(start)


def guard_before(text, marker):
    """按 marked 行回溯到**该处**的 `if (slot >= 0 && g_pending[slot].valid)` 并取整块。"""
    idx = text.index(marker)
    start = text.rindex('if (slot >= 0 && g_pending[slot].valid)', 0, idx)
    return block_at(text, start)


def span(text, start_anchor, end_anchor):
    """按锚点对抽生产原文（含两端）：镜像声明字段用原文，漂移即编译错。"""
    start = text.index(start_anchor)
    return text[start:text.index(end_anchor, start) + len(end_anchor)] + "\n"


# ---- 逐字抽取 ----
C_PENDING = line_containing(SOURCE_TEXT, "CJGUI_INTERNAL_RENDERER_PENDING =")
C_TIMEOUT = line_containing(SOURCE_TEXT, "kRenderWaitTimeout =")
ENUM_KIND = function(SOURCE_TEXT, "enum class JobKind {") + ";"
ENUM_PHASE = function(SOURCE_TEXT, "enum class JobPhase {") + ";"
WAITABLE = function(SOURCE_TEXT, "struct WaitableJob {") + ";"
PENDING_SETTLEMENT = function(SOURCE_TEXT, "struct PendingSettlement {") + ";"
SETTLE_FN = function(SOURCE_TEXT, "static uint32_t settlePendingTicketLocked(")

CONFIGURE_GUARD = guard_before(SOURCE_TEXT, "configure refused: pending ticket=")
PRESENT_GUARD = guard_before(SOURCE_TEXT, "present deferred: unacknowledged ticket=")

_ack_idx = SOURCE_TEXT.index('RLOGW("acknowledge refused: ticket=')
_ack_start = SOURCE_TEXT.rindex('if (!p.settled) {', 0, _ack_idx)
_ack_end_marker = 'if (s->unackedTicketId == ticketId) s->unackedTicketId = 0;'
ACK_BLOCK = SOURCE_TEXT[_ack_start:SOURCE_TEXT.index(_ack_end_marker, _ack_idx) + len(_ack_end_marker)]

PREFIX = r'''
#include <atomic>
#include <chrono>
#include <condition_variable>
#include <cstdint>
#include <iostream>
#include <map>
#include <memory>
#include <mutex>
#include <string>
#include <vector>
#define RLOGI(...) do{}while(0)
#define RLOGW(...) do{}while(0)
using CjguiInternalRendererStatus = int32_t;
constexpr int32_t CJGUI_INTERNAL_RENDERER_OK = 0;
constexpr int32_t CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR = 3;
constexpr int32_t CJGUI_INTERNAL_RENDERER_METAL_DRAWABLE_UNAVAILABLE = 4;
constexpr int32_t CJGUI_INTERNAL_RENDERER_PENDING_SETTLEMENT_UNRESOLVED = 5;
constexpr uint32_t CJGUI_INTERNAL_RENDERER_PRESENT_DECISION_NONE = 0;
constexpr uint32_t CJGUI_INTERNAL_RENDERER_PRESENT_DECISION_PENDING = 1;
constexpr uint32_t CJGUI_INTERNAL_RENDERER_PRESENT_DECISION_ACCEPTED = 2;
constexpr uint32_t CJGUI_INTERNAL_RENDERER_PRESENT_DECISION_REJECTED = 3;
constexpr int32_t kSettlementNone = 0;
constexpr int32_t kSettlementCommitted = 1;
constexpr int32_t kSettlementAborted = 2;
constexpr int32_t kSettlementStillCommitting = 3;
std::atomic<int64_t> g_committedSettlements{0};
std::atomic<int64_t> g_abortedSettlements{0};
std::atomic<int32_t> g_lastSettlementVerdict{0};

struct Pod { uint64_t nodeId = 0; };
struct SceneNode { Pod pod; };
'''

SHIMS = r'''
struct Session {
  struct TextRunBinding {};
  std::vector<SceneNode> accepted;
  std::map<uint64_t, TextRunBinding> acceptedRunTable;
  // 生产 settle 逐字抽取里直接晋升 ownedMirrorAccepted（含 declaredBindingEpoch）：
  // 字段取**生产原文**注入，生产加/改字段时这里必须编译失败，而不是静默少晋升。
  %MIRROR_FIELDS%
  // 票据终态/结算发布 helper 的会话身份（cjguiOhosPublish*(s->token, ...)）。
  uint64_t token = 1;
  uint64_t acceptedProjectionVersion = 0, acceptedPaintTicketId = 0,
           submittedFrameIndex = 0, unackedTicketId = 0,
           surfaceWidth = 640, surfaceHeight = 480;
  double surfaceDensity = 1.0;
  int64_t ticketAcceptedCount = 0, ticketRejectedCount = 0,
          ticketDuplicateSettlementCount = 0;
  bool candidateOpen = false;
};
using JobRef = std::shared_ptr<WaitableJob>;
static void retireEditingContextIfUnhealthyLocked(Session *) {}
static void syncEditingBufferAfterAcceptedSceneLocked(Session *) {}
static bool reconcileAcceptedImagesLocked(Session *) { return false; }
static void cjguiOhosLogAcceptedFrame(const std::vector<SceneNode> &) {}
static void cjguiOhosLogAcceptedImageSwap(const Session &, const std::vector<SceneNode> &,
                                          uint64_t, uint64_t, const char *) {}
'''

# round9/10-D 的只读事实发布 helper：写票据事实环/结算快照供设备侧读回，不参与
# settle 的 commit/rollback 判定，因此替身化成空实现（本文件断言的是状态机决策）。
# 顺序约束：签名按引用接收 PendingSettlement，必须排在它的定义之后。
FACT_STUBS = r'''
void cjguiOhosLogAcceptedSummary(const std::vector<SceneNode> &, uint64_t, uint64_t) {}
void cjguiOhosPublishSettlement(uint64_t, const PendingSettlement &, const std::vector<SceneNode> &) {}
void cjguiOhosPublishTicketTerminal(uint64_t, const PendingSettlement &, int) {}
'''


def harness(conf_guard):
    return (
        PREFIX
        + "\n" + C_PENDING + "\n" + C_TIMEOUT + "\n"
        + ENUM_KIND + "\n" + ENUM_PHASE + "\n" + WAITABLE + "\n"
        + SHIMS
        + "\n" + PENDING_SETTLEMENT + "\n"
        + FACT_STUBS
        + "PendingSettlement g_pending[1];\n"
        + SETTLE_FN + "\n"
        + "struct CjguiInternalRendererFrameObservation { uint64_t ticketId = 0; };\n"
        + "static CjguiInternalRendererStatus configureGate(int slot, PendingSettlement *g_pending) {\n"
        + conf_guard + "\n    return CJGUI_INTERNAL_RENDERER_OK;\n}\n"
        + "static CjguiInternalRendererStatus presentDefer(int slot, PendingSettlement *g_pending,\n"
        + "        CjguiInternalRendererFrameObservation *outObservation) {\n"
        + PRESENT_GUARD + "\n    return CJGUI_INTERNAL_RENDERER_OK;\n}\n"
        + "static CjguiInternalRendererStatus ackTicket(Session *s, PendingSettlement &p, uint64_t ticketId) {\n"
        + ACK_BLOCK + "\n    return CJGUI_INTERNAL_RENDERER_OK;\n}\n"
        + MAIN
    ).replace("%MIRROR_FIELDS%", span(SOURCE_TEXT,
                                      "    struct OwnedMirrorDeclaration {",
                                      "    OwnedMirrorDeclaration ownedMirrorAccepted;"))


MAIN = r'''
int main() {
  Session s;
  PendingSettlement *gp = g_pending;

  // 1) 无票据：configure 允许。
  gp[0] = PendingSettlement{};
  if (configureGate(0, gp) != CJGUI_INTERNAL_RENDERER_OK) { std::cout << "L1-open\n"; return 1; }

  // 2) 已投递未结算票据：configure 具名拒绝、present 推迟并回显原票号。
  gp[0].valid = true; gp[0].settled = false; gp[0].ticketId = 7;
  CjguiInternalRendererFrameObservation obs;
  if (presentDefer(0, gp, &obs) != CJGUI_INTERNAL_RENDERER_PENDING) { std::cout << "L2-present\n"; return 1; }
  if (obs.ticketId != 7) { std::cout << "L2-echo\n"; return 1; }
  if (configureGate(0, gp) != CJGUI_INTERNAL_RENDERER_PENDING) { std::cout << "L2-configure\n"; return 1; }

  // 3) job 未完成的结算 → REJECTED、settled=true、valid 仍真 → configure 仍拒绝。
  {
    gp[0].job = std::make_shared<WaitableJob>(JobKind::Present);
    gp[0].nodes.push_back(SceneNode{});
    if (settlePendingTicketLocked(&s, 0, nullptr) != CJGUI_INTERNAL_RENDERER_PRESENT_DECISION_REJECTED) {
      std::cout << "L3-verdict\n"; return 1;
    }
    if (!gp[0].settled || !gp[0].valid) { std::cout << "L3-flags\n"; return 1; }
    if (configureGate(0, gp) != CJGUI_INTERNAL_RENDERER_PENDING) { std::cout << "L3-configure\n"; return 1; }
  }

  // 4) 结算后 ACK 回收 → configure 允许。
  if (ackTicket(&s, gp[0], 7) != CJGUI_INTERNAL_RENDERER_OK) { std::cout << "L4-ack\n"; return 1; }
  if (gp[0].valid) { std::cout << "L4-valid\n"; return 1; }
  if (configureGate(0, gp) != CJGUI_INTERNAL_RENDERER_OK) { std::cout << "L4-configure\n"; return 1; }

  // 5) 未结算就 ACK → 拒绝且票据保留。
  gp[0] = PendingSettlement{};
  gp[0].valid = true; gp[0].settled = false; gp[0].ticketId = 9;
  if (ackTicket(&s, gp[0], 9) != CJGUI_INTERNAL_RENDERER_PENDING_SETTLEMENT_UNRESOLVED) {
    std::cout << "L5-ack-guard\n"; return 1;
  }
  if (!gp[0].valid) { std::cout << "L5-valid-kept\n"; return 1; }

  // 6) Committing → settle PENDING（不落终态）；finish(OK) 后 settle ACCEPTED。
  {
    Session s2;
    gp[0] = PendingSettlement{};
    auto job = std::make_shared<WaitableJob>(JobKind::Present);
    job->markRunning();
    if (!job->acquireCommitPermission()) { std::cout << "L6-permit\n"; return 1; }
    gp[0].valid = true; gp[0].settled = false; gp[0].ticketId = 11;
    gp[0].projectionVersion = 6; gp[0].job = job;
    gp[0].nodes.push_back(SceneNode{});
    if (settlePendingTicketLocked(&s2, 0, nullptr) != CJGUI_INTERNAL_RENDERER_PRESENT_DECISION_PENDING) {
      std::cout << "L6-committing\n"; return 1;
    }
    if (gp[0].settled) { std::cout << "L6-premature-settle\n"; return 1; }
    job->finish(CJGUI_INTERNAL_RENDERER_OK);
    const uint64_t frameBefore = s2.submittedFrameIndex;
    if (settlePendingTicketLocked(&s2, 0, nullptr) != CJGUI_INTERNAL_RENDERER_PRESENT_DECISION_ACCEPTED) {
      std::cout << "L6-accept\n"; return 1;
    }
    if (!gp[0].settled || !gp[0].valid) { std::cout << "L6-flags\n"; return 1; }
    if (s2.submittedFrameIndex != frameBefore + 1) { std::cout << "L6-frame\n"; return 1; }
    if (s2.accepted.size() != 1 || s2.acceptedProjectionVersion != 6) { std::cout << "L6-accepted\n"; return 1; }

    // 7) 重复 settle → 同一决策、计数 +1、帧号不二次推进。
    const int64_t dupBefore = s2.ticketDuplicateSettlementCount;
    const uint64_t frameAfter = s2.submittedFrameIndex;
    if (settlePendingTicketLocked(&s2, 0, nullptr) != CJGUI_INTERNAL_RENDERER_PRESENT_DECISION_ACCEPTED) {
      std::cout << "L7-dup-verdict\n"; return 1;
    }
    if (s2.ticketDuplicateSettlementCount != dupBefore + 1) { std::cout << "L7-dup-count\n"; return 1; }
    if (s2.submittedFrameIndex != frameAfter) { std::cout << "L7-dup-frame\n"; return 1; }

    // 8) 结算后未 ACK：configure 仍拒绝。
    if (configureGate(0, gp) != CJGUI_INTERNAL_RENDERER_PENDING) { std::cout << "L8-configure\n"; return 1; }

    // 9) ACK 后开放。
    if (ackTicket(&s2, gp[0], 11) != CJGUI_INTERNAL_RENDERER_OK) { std::cout << "L9-ack\n"; return 1; }
    if (configureGate(0, gp) != CJGUI_INTERNAL_RENDERER_OK) { std::cout << "L9-configure\n"; return 1; }
  }

  std::cout << "ALL-OK\n";
  return 0;
}
'''


def run(conf_guard=CONFIGURE_GUARD):
    with tempfile.TemporaryDirectory(prefix="cjgui-h-r1-ticket-") as d:
        cpp = pathlib.Path(d) / "t.cpp"
        cpp.write_text(harness(conf_guard))
        exe = pathlib.Path(d) / "t"
        cp = subprocess.run(["clang++", "-std=c++17", "-Wall", "-Wextra", "-pthread",
                             str(cpp), "-o", str(exe)], capture_output=True, text=True)
        if cp.returncode != 0:
            raise AssertionError("compile failed:\n" + cp.stderr)
        r = subprocess.run([str(exe)], capture_output=True, text=True)
        return r.returncode, r.stdout, r.stderr


class TicketLifecycleNative(unittest.TestCase):
    def test_real_present_settle_ack_lifecycle(self):
        rc, out, err = run()
        self.assertEqual(rc, 0, f"stdout={out} stderr={err}")
        self.assertIn("ALL-OK", out)

    def test_mutation_gate_ignores_inflight_ticket_turns_red(self):
        # 变异：configure 闸门谓词恒假——忽略在途票据，第 2/3/8 步必须翻红。
        broken = CONFIGURE_GUARD.replace(
            "if (slot >= 0 && g_pending[slot].valid) {",
            "if (false) {  // mutation: ignore in-flight ticket", 1)
        self.assertNotEqual(broken, CONFIGURE_GUARD)
        rc, out, err = run(broken)
        self.assertNotEqual(rc, 0, f"mutation should be red; stdout={out}")
        self.assertIn("L2-configure", out)


if __name__ == "__main__":
    unittest.main(verbosity=2)

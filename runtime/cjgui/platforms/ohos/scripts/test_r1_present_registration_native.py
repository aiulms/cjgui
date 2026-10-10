#!/usr/bin/env python3
"""R1 提交入口的**实际登记**链（2026-10-02 复核：票据测试只覆盖片段）。

只读裁决：Pharos Mark/artifacts/consultations/h-r1-source-admission-astra/answer-followup-1.md。

复核指出：既有 `test_r1_ticket_lifecycle_native.py` 抽取结构、settle 与 guard，但 main
仍手设 `gp[0].valid/job/nodes`，用 wrapper 代替完整 present／ACK 入口——「不是手工
pending」这一说法不成立。本文件把**生产入口自己登记 pending** 接进同一条链：

逐字抽取（非重写）
  * 真实 `cjgui_internal_renderer_present_composable_scene`（生产 present）
  * 真实 `cjgui_internal_renderer_query_present` / `..._acknowledge_present`
  * 真实 `cjgui_internal_renderer_configure_composable_scene`（含在途票据闸门）
  * 真实 `settlePendingTicketLocked` / `struct PendingSettlement`
  * 真实 `WaitableJob` / `PresentJob` / `JobPhase` / `JobKind` / `kRenderWaitTimeout`

链（全部真实函数，paint/surface 边界明确替身化）
  1. present 投递后 `waitFor` 命中许可后 PENDING → **present 自己**写 `g_pending` 登记
     （`p.valid=true`、`p.ticketId=nextTicketId`、来源快照随票携带）——不是测试手设。
  2. 未 ACK 期间：`configure` 被真实闸门具名拒绝（PENDING），`accepted` 不变。
  3. `query_present` → 真实 settle：job 仍 Committing → PENDING 决策、不落终态。
  4. `finish(OK)` 后再 `query` → ACCEPTED、帧号 +1、accepted 切到候选。
  5. 未 ACK 时 `configure` 仍拒绝；`acknowledge_present` 后 `configure` 开放。

方向性变异负控（各自必须翻红）
  * 破坏生产 pending 登记：present 里 `p.valid = true;` → `false` → 断言 1 失败；
  * 提前放开未 ACK 门禁：configure 闸门谓词恒假 → 断言 2/5 失败。

边界：owner 线程身份与分发顺序、生成结构替换不在此列（见
`test_r1_commit_order_native.py` 与设备重放）。
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


def span(text, start_anchor, end_anchor):
    """按锚点对抽生产原文（含两端）。字段漂移时 index() 立刻抛错，而不是让
    harness 静默少一个字段（同 test_r1_source_admission_native.py 的做法）。"""
    start = text.index(start_anchor)
    return text[start:text.index(end_anchor, start) + len(end_anchor)] + "\n"


C_PENDING = line_containing(SOURCE_TEXT, "CJGUI_INTERNAL_RENDERER_PENDING =")
C_TIMEOUT = line_containing(SOURCE_TEXT, "kRenderWaitTimeout =")
ENUM_KIND = function(SOURCE_TEXT, "enum class JobKind {") + ";"
ENUM_PHASE = function(SOURCE_TEXT, "enum class JobPhase {") + ";"
WAITABLE = function(SOURCE_TEXT, "struct WaitableJob {") + ";"
PRESENT_JOB = function(SOURCE_TEXT, "struct PresentJob : WaitableJob {") + ";"
PENDING_SETTLEMENT = function(SOURCE_TEXT, "struct PendingSettlement {") + ";"
SETTLE_FN = function(SOURCE_TEXT, "static uint32_t settlePendingTicketLocked(")
PRESENT_FN = function(SOURCE_TEXT, "CjguiInternalRendererStatus cjgui_internal_renderer_present_composable_scene(")
QUERY_FN = function(SOURCE_TEXT, "CjguiInternalRendererStatus cjgui_internal_renderer_query_present(")
ACK_FN = function(SOURCE_TEXT, "CjguiInternalRendererStatus cjgui_internal_renderer_acknowledge_present(")
CONFIGURE_FN = function(SOURCE_TEXT, "CjguiInternalRendererStatus cjgui_internal_renderer_configure_composable_scene(")

PREFIX = r'''
#include <algorithm>
#include <atomic>
#include <cstdint>
#include <cstring>
#include <iostream>
#include <map>
#include <memory>
#include <mutex>
#include <string>
#include <utility>
#include <vector>
#define RLOGI(...) do{}while(0)
#define RLOGW(...) do{}while(0)
using CjguiInternalRendererStatus = int32_t;
constexpr int32_t CJGUI_INTERNAL_RENDERER_OK = 0;
constexpr int32_t CJGUI_INTERNAL_RENDERER_INVALID_SESSION = 2;
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

struct Pod {
  uint64_t nodeId = 0, resourceId = 0, nodeKind = 10, projectionVersion = 5,
    acceptedBindingEpoch = 7, preservesActiveLocalText = 0;
  uint32_t isReadOnly = 0, isInteractive = 1;
};
struct SceneNode { Pod pod; std::string semanticId, value; bool stagedThisCandidate = false; };
static bool isEditableTextKind(uint32_t k) { return k == 10 || k == 5 || k == 6; }

struct Session {
  struct TextRunBinding {};
  std::deque<int> pendingEnds;
  // 生产 Session 的镜像声明（staged→present 冻结→accepted 晋升）取**生产原文**：
  // 生产 present/settle 逐字抽取里直接读写 ownedMirrorStaged/ownedMirrorAccepted，
  // 字段漂移必须在这里编译失败，而不是让 harness 少搬一份声明。
  %MIRROR_FIELDS%
  // 结算/终态发布 helper 的会话身份参数（cjguiOhosPublish*(s->token, ...)）。
  uint64_t token = 1;
  bool editing = false, editorRetired = false, editingContextLive = false,
    candidateOpen = true, candidateFailed = false, previewActive = false;
  uint64_t editingNodeId = 0, editingResourceId = 0, editingNodeKind = 0,
    editingProjectionVersion = 0, editingAcceptedBindingEpoch = 0,
    editingContextGeneration = 0, editingContextBaseVersion = 0,
    surfaceGeneration = 1, acceptedPaintTicketId = 5, acceptedProjectionVersion = 5,
    candidateProjectionVersion = 6, nextTicketId = 1, submittedFrameIndex = 0,
    unackedTicketId = 0, ticketDuplicateSettlementCount = 0,
    ticketRejectedCount = 0, ticketAcceptedCount = 0, ticketQueryCount = 0,
    ticketAckCount = 0, surfaceGeometryRevision = 1, surfaceWidth = 640,
    surfaceHeight = 480;
  int64_t editingContextId = 0;
  std::string editingFieldName;
  std::u16string editingText;
  std::vector<SceneNode> accepted, candidate;
  std::map<uint64_t, Session::TextRunBinding> acceptedRunTable, buildingRunTable;
  double surfaceDensity = 1, clearR = 0, clearG = 0, clearB = 0, clearA = 1;
};
'''

SHIMS = r'''
using JobRef = std::shared_ptr<WaitableJob>;
struct CjguiInternalRendererFrameObservation {
  uint64_t ticketId = 0, frameIndex = 0;
  uint32_t drawableWidthPixels = 0, drawableHeightPixels = 0;
  double contentsScale = 1; int readbackAttempted = 0, readbackCompleted = 0, readbackColorMatched = 0;
};
struct CjguiInternalRendererPresentReceipt {
  uint64_t ticketId = 0, projectionVersion = 0;
  uint32_t decision = 0; int32_t terminalStatus = 0; int settled = 0, resyncRequired = 0;
  CjguiInternalRendererFrameObservation observation;
};
bool freezeCandidateRunTableLocked(Session *, std::map<uint64_t, Session::TextRunBinding> &) { return true; }
void cjguiOhosScheduleUnpostedImages() {}
void cjguiOhosPruneReleasedImages() {}
void cjguiOhosLogAcceptedImageSwap(Session &, const std::vector<SceneNode> &, uint64_t, uint64_t, const char *) {}
bool reconcileAcceptedImagesLocked(Session *) { return false; }
void cjguiOhosLogAcceptedFrame(const std::vector<SceneNode> &) {}
void cjguiOhosObserveSurfaceLocked(Session *, uint64_t, uint64_t, int, int, double) {}
void cjguiOhosLogImageSnapshot(const char *) {}
static void retireEditingContextIfUnhealthyLocked(Session *) {}
static void syncEditingBufferAfterAcceptedSceneLocked(Session *) {}
std::atomic<int64_t> g_nextEditingContextId{11};
static Session *active = nullptr;
static Session *lookupSessionLocked(uint64_t) { return active; }
static int sessionSlotLocked(uint64_t) { return 0; }
void cancelProxyRestoreRequest(Session &, const char *) {}
void clearHumanSelectionAnchorLocked(Session &) {}
bool settleComposedBufferOnBlurLocked(Session &) { return false; }
bool editorOwnsTextSession(Session &) { return false; }
std::u16string utf8ToUtf16(const std::string &v) { return std::u16string(v.begin(), v.end()); }
uint32_t clampToCodePointBoundary(const std::u16string &v, uint32_t p) {
  return std::min(p, static_cast<uint32_t>(v.size()));
}
struct { std::mutex lock; } g_sessions;
static int surface_probe(void **, uint64_t *, int32_t *, int32_t *, double *, uint64_t *) { return 1; }
struct { decltype(&surface_probe) surfaceActive = surface_probe; } g_ingress;
struct RedrawJob : WaitableJob { RedrawJob() : WaitableJob(JobKind::Redraw) {} };
'''

# round9/10-D 的账本与观测 helper：只发布只读事实、不参与 present 登记或 settle
# 判定，因此替身化（空实现）。真正的判定——p.valid/ticketId/来源快照的登记与
# ownedMirrorAccepted 的晋升——全部来自逐字抽取的生产函数体。
# 必须排在 `struct PendingSettlement` 之后：签名按引用接收结算记录。
FACT_STUBS = r'''
static uint64_t g_observationSeq = 0;
uint64_t cjgui_ohos_observation_seq() { return ++g_observationSeq; }
void cjguiOhosPublishInFlight(uint64_t, uint64_t, uint32_t, int32_t, uint64_t, uint64_t) {}
void cjguiOhosLogAcceptedSummary(const std::vector<SceneNode> &, uint64_t, uint64_t) {}
void cjguiOhosPublishSettlement(uint64_t, const PendingSettlement &, const std::vector<SceneNode> &) {}
void cjguiOhosPublishTicketTerminal(uint64_t, const PendingSettlement &, int) {}
'''

MAIN = r'''
static SceneNode node(uint64_t id, const char *field) {
  SceneNode n; n.pod.nodeId = id; n.pod.resourceId = id; n.semanticId = field; n.value = "body";
  return n;
}

int main() {
  Session s; active = &s;
  s.accepted = { node(107, "pharos-editor-body") };
  s.candidateOpen = true;
  s.candidate = { node(107, "pharos-editor-body"), node(313, "pharos-document-note") };
  s.candidateProjectionVersion = 6;
  s.editingContextId = 42; s.editingContextLive = true;
  s.acceptedPaintTicketId = 5;

  // 1) 生产 present 自己登记 pending（许可后 PENDING：waitFor 超时且已 Committing）。
  CjguiInternalRendererFrameObservation obs;
  int rc = cjgui_internal_renderer_present_composable_scene(1, &obs);
  if (rc != CJGUI_INTERNAL_RENDERER_PENDING) { std::cout << "G1-present-rc\n"; return 1; }
  if (!g_pending[0].valid) { std::cout << "G1-not-registered\n"; return 1; }
  if (g_pending[0].ticketId == 0 || g_pending[0].ticketId != obs.ticketId) {
    std::cout << "G1-ticket-identity\n"; return 1;
  }
  if (g_pending[0].sourceEditingContextId != 42 || !g_pending[0].sourceEditingLive) {
    std::cout << "G1-source-snapshot\n"; return 1;
  }
  if (s.unackedTicketId != g_pending[0].ticketId) { std::cout << "G1-unacked-ledger\n"; return 1; }
  const uint64_t ticket = g_pending[0].ticketId;

  // 2) 未 ACK 期间 configure 被真实闸门具名拒绝；accepted 不变。
  const size_t accepted_before = s.accepted.size();
  if (cjgui_internal_renderer_configure_composable_scene(1, 7, 3) !=
      static_cast<CjguiInternalRendererStatus>(CJGUI_INTERNAL_RENDERER_PENDING)) {
    std::cout << "G2-configure-open\n"; return 1;
  }
  if (s.accepted.size() != accepted_before) { std::cout << "G2-accepted-moved\n"; return 1; }

  // 3) query → 真实 settle：job 仍 Committing → PENDING、不落终态。
  CjguiInternalRendererPresentReceipt rec;
  if (cjgui_internal_renderer_query_present(1, ticket, &rec) != CJGUI_INTERNAL_RENDERER_OK) {
    std::cout << "G3-query-rc\n"; return 1;
  }
  if (rec.decision != CJGUI_INTERNAL_RENDERER_PRESENT_DECISION_PENDING || rec.settled) {
    std::cout << "G3-premature\n"; return 1;
  }

  // 4) Flush 成功 → 再 query → ACCEPTED、帧号 +1、accepted 切到候选。
  const uint64_t frame_before = s.submittedFrameIndex;
  g_pending[0].job->finish(CJGUI_INTERNAL_RENDERER_OK);
  if (cjgui_internal_renderer_query_present(1, ticket, &rec) != CJGUI_INTERNAL_RENDERER_OK) {
    std::cout << "G4-query-rc\n"; return 1;
  }
  if (rec.decision != CJGUI_INTERNAL_RENDERER_PRESENT_DECISION_ACCEPTED || !rec.settled) {
    std::cout << "G4-not-accepted\n"; return 1;
  }
  if (s.submittedFrameIndex != frame_before + 1) { std::cout << "G4-frame\n"; return 1; }
  if (s.accepted.size() != 2 || s.acceptedProjectionVersion != 6) { std::cout << "G4-accepted\n"; return 1; }

  // 5) 已结算但未 ACK：configure 仍拒绝；ACK 后开放。
  if (cjgui_internal_renderer_configure_composable_scene(1, 7, 3) !=
      static_cast<CjguiInternalRendererStatus>(CJGUI_INTERNAL_RENDERER_PENDING)) {
    std::cout << "G5-configure-open\n"; return 1;
  }
  if (cjgui_internal_renderer_acknowledge_present(1, ticket) != CJGUI_INTERNAL_RENDERER_OK) {
    std::cout << "G5-ack-rc\n"; return 1;
  }
  if (g_pending[0].valid) { std::cout << "G5-valid-kept\n"; return 1; }
  if (cjgui_internal_renderer_configure_composable_scene(1, 7, 3) != CJGUI_INTERNAL_RENDERER_OK) {
    std::cout << "G5-configure-still-refused\n"; return 1;
  }

  std::cout << "ALL-OK\n";
  return 0;
}
'''


def harness(present_fn, configure_fn):
    return (
        PREFIX
        + "\n" + C_PENDING + "\n" + C_TIMEOUT + "\n"
        + ENUM_KIND + "\n" + ENUM_PHASE + "\n" + WAITABLE + "\n"
        + SHIMS
        + "\n" + PENDING_SETTLEMENT + "\n"
        + FACT_STUBS
        + "PendingSettlement g_pending[1];\n"
        # post 替身：明确替身化渲染线程调度——投递即让渲染线程取得提交许可，
        # 于是生产 waitFor 走「许可后超时 → PENDING」的真路径。
        + "struct {\n"
        + "  void post(JobRef j) { j->markRunning(); j->acquireCommitPermission(); }\n"
        + "  void postIfRunning(JobRef) {}\n"
        + "} g_render;\n"
        + PRESENT_JOB + "\n"
        + SETTLE_FN + "\n"
        + present_fn + "\n"
        + QUERY_FN + "\n"
        + ACK_FN + "\n"
        + configure_fn + "\n"
        + MAIN
    ).replace("%MIRROR_FIELDS%", span(SOURCE_TEXT,
                                      "    struct OwnedMirrorDeclaration {",
                                      "    OwnedMirrorDeclaration ownedMirrorAccepted;"))


def run(present_fn=PRESENT_FN, configure_fn=CONFIGURE_FN):
    with tempfile.TemporaryDirectory(prefix="cjgui-h-r1-reg-") as d:
        cpp = pathlib.Path(d) / "t.cpp"
        cpp.write_text(harness(present_fn, configure_fn))
        exe = pathlib.Path(d) / "t"
        cp = subprocess.run(["clang++", "-std=c++17", "-Wall", "-Wextra", "-pthread",
                             str(cpp), "-o", str(exe)], capture_output=True, text=True)
        if cp.returncode != 0:
            raise AssertionError("compile failed:\n" + cp.stderr)
        r = subprocess.run([str(exe)], capture_output=True, text=True)
        return r.returncode, r.stdout, r.stderr


class PresentRegistrationNative(unittest.TestCase):
    def test_real_present_registers_and_unacked_gate_holds(self):
        rc, out, err = run()
        self.assertEqual(rc, 0, f"stdout={out} stderr={err}")
        self.assertIn("ALL-OK", out)

    def test_mutation_registration_dropped_turns_red(self):
        # 变异：present 不再登记 pending（p.valid 恒假）。
        anchor = "            p.valid = true;"
        self.assertIn(anchor, PRESENT_FN)
        broken = PRESENT_FN.replace(anchor, "            p.valid = false;  // mutation", 1)
        self.assertNotEqual(broken, PRESENT_FN)
        rc, out, err = run(present_fn=broken)
        self.assertNotEqual(rc, 0, f"mutation should be red; stdout={out}")
        self.assertIn("G1-not-registered", out)

    def test_mutation_unacked_gate_opened_turns_red(self):
        # 变异：configure 闸门恒假（提前放开未 ACK 门禁）。
        anchor = "        if (slot >= 0 && g_pending[slot].valid) {"
        self.assertIn(anchor, CONFIGURE_FN)
        broken = CONFIGURE_FN.replace(anchor, "        if (false) {  // mutation", 1)
        self.assertNotEqual(broken, CONFIGURE_FN)
        rc, out, err = run(configure_fn=broken)
        self.assertNotEqual(rc, 0, f"mutation should be red; stdout={out}")
        self.assertIn("G2-configure-open", out)


if __name__ == "__main__":
    unittest.main(verbosity=2)

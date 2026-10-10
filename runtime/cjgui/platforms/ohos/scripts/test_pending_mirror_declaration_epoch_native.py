#!/usr/bin/env python3
"""A1 返工：PENDING 结算必须运输**完整**镜像声明（含声明代），与同步路径同源。

抽取 ohos_renderer.cpp 的真实生产函数 settlePendingTicketLocked 与
ownedMirrorDeclarationLocked，在宿主 clang++ 下断言：

  * 延迟结算正控：票据冻结的声明（含声明代）被原样晋升，换绑后的当前查询可借用；
  * 延迟期间新声明：结算只晋升**本票据冻结的**声明，绝不回读提交后被改写的
    working 表；当前代已推进时查询具名拒绝（fail-closed），新代提交后恢复；
  * 同步整结构赋值与延迟逐字段晋升同源（两条路径晋升结果逐字段相等）。

变异负控证明判别力：删掉延迟路径的声明代运输，同一二进制必须失败。
"""
import pathlib
import subprocess
import tempfile
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]
SOURCE = ROOT / "host" / "ohos_renderer.cpp"

TRANSPORT_LINE = "s->ownedMirrorAccepted.declaredBindingEpoch = p.ownedMirrorDeclaredBindingEpoch;\n"


def extract(text, signature_start):
    start = text.index(signature_start)
    end = text.index("\n}\n", start) + 3
    return text[start:end]


PREFIX = r'''
#include <algorithm>
#include <atomic>
#include <cstdint>
#include <cstring>
#include <deque>
#include <iostream>
#include <map>
#include <memory>
#include <mutex>
#include <string>
#include <vector>
#define RLOGI(...) do {} while(0)
#define RLOGW(...) do {} while(0)
#define RLOGE(...) do {} while(0)
static int g_sessionsSettlements = 0;
static int g_sessionsTerminals = 0;
static int &g_sessions_publishedSettlements() { return g_sessionsSettlements; }
static int &g_sessions_publishedTerminals() { return g_sessionsTerminals; }
enum class JobPhase { Queued, Preparing, Committing, Done };
enum CjguiInternalRendererStatus {
  CJGUI_INTERNAL_RENDERER_OK = 0,
  CJGUI_INTERNAL_RENDERER_PENDING = 1,
  CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR = 2,
};
enum CjguiInternalRendererPresentDecision {
  CJGUI_INTERNAL_RENDERER_PRESENT_DECISION_NONE = 0,
  CJGUI_INTERNAL_RENDERER_PRESENT_DECISION_ACCEPTED = 1,
  CJGUI_INTERNAL_RENDERER_PRESENT_DECISION_REJECTED = 2,
  CJGUI_INTERNAL_RENDERER_PRESENT_DECISION_PENDING = 3,
};
constexpr int32_t kSettlementNone = 0;
constexpr int32_t kSettlementCommitted = 1;
constexpr int32_t kSettlementAborted = 2;
constexpr int32_t kSettlementStillCommitting = 3;
struct SceneNode { uint64_t nodeId = 0; };
struct WaitableJob {
  JobPhase p = JobPhase::Done;
  CjguiInternalRendererStatus st = CJGUI_INTERNAL_RENDERER_OK;
  JobPhase phaseSnapshot() const { return p; }
  CjguiInternalRendererStatus statusSnapshot() const { return st; }
};
using JobRef = std::shared_ptr<WaitableJob>;
struct Session {
  struct TextRunBinding { int dummy = 0; };
  struct OwnedMirrorDeclaration {
    bool valid = false;
    std::u16string text;
    int64_t ownerContentVersion = -1;
    uint64_t bindingEpoch = 0;
    uint64_t declaredBindingEpoch = 0;
  };
  OwnedMirrorDeclaration ownedMirrorStaged;
  OwnedMirrorDeclaration ownedMirrorAccepted;
  bool ownedTextSessionEnabled = true;
  uint64_t ownedTextSessionNodeId = 190;
  int64_t ownedTextSessionResourceId = -1;
  uint32_t ownedTextSessionNodeKind = 1;
  uint64_t ownedTextSessionBindingEpoch = 20;
  std::vector<SceneNode> accepted;
  std::vector<SceneNode> candidate;
  uint64_t acceptedProjectionVersion = 0;
  uint64_t acceptedPaintTicketId = 0;
  std::map<uint64_t, TextRunBinding> acceptedRunTable;
  uint64_t submittedFrameIndex = 0;
  uint64_t token = 1;
  bool candidateOpen = false;
  int32_t surfaceWidth = 100, surfaceHeight = 40;
  double surfaceDensity = 2.0;
  int64_t ticketAcceptedCount = 0;
  int64_t ticketRejectedCount = 0;
  int64_t ticketDuplicateSettlementCount = 0;
  int32_t publishedTerminals = 0;
  int32_t publishedSettlements = 0;
};
struct PendingSettlement {
  JobRef job;
  std::vector<SceneNode> nodes;
  std::map<uint64_t, Session::TextRunBinding> runTable;
  bool ownedMirrorValid = false;
  std::u16string ownedMirrorText;
  int64_t ownedMirrorOwnerVersion = -1;
  uint64_t ownedMirrorBindingEpoch = 0;
  uint64_t ownedMirrorDeclaredBindingEpoch = 0;
  uint64_t projectionVersion = 0;
  bool valid = false;
  uint64_t ticketId = 0;
  uint32_t decision = 0;
  int32_t terminalStatus = 0;
  uint64_t frameIndex = 0;
  int32_t drawableWidth = 0;
  int32_t drawableHeight = 0;
  double density = 0;
  bool settled = false;
};
static PendingSettlement g_pending[4];
static std::atomic<int32_t> g_lastSettlementVerdict{0};
static std::atomic<int64_t> g_committedSettlements{0};
static std::atomic<int64_t> g_abortedSettlements{0};
static void retireEditingContextIfUnhealthyLocked(Session *) {}
static bool reconcileAcceptedImagesLocked(Session *) { return false; }
static void cjguiOhosLogAcceptedImageSwap(Session &, const std::vector<SceneNode> &, uint64_t, uint64_t, const char *) {}
static void cjguiOhosLogAcceptedSummary(const std::vector<SceneNode> &, uint64_t, uint64_t) {}
static void cjguiOhosLogAcceptedFrame(const std::vector<SceneNode> &) {}
static void cjguiOhosPublishSettlement(uint64_t, PendingSettlement &, const std::vector<SceneNode> &)
{ ++g_sessions_publishedSettlements(); }
static void cjguiOhosPublishTicketTerminal(uint64_t, PendingSettlement &, int32_t)
{ ++g_sessions_publishedTerminals(); }
static void syncEditingBufferAfterAcceptedSceneLocked(Session *) {}
'''

MAIN = r'''
static Session::OwnedMirrorDeclaration decl(bool valid, const char16_t *text,
    int64_t ownerVersion, uint64_t bindingEpoch, uint64_t declaredEpoch) {
  Session::OwnedMirrorDeclaration d;
  d.valid = valid;
  d.text = text;
  d.ownerContentVersion = ownerVersion;
  d.bindingEpoch = bindingEpoch;
  d.declaredBindingEpoch = declaredEpoch;
  return d;
}
static bool sameDeclaration(const Session::OwnedMirrorDeclaration &a,
    const Session::OwnedMirrorDeclaration &b) {
  return a.valid == b.valid && a.text == b.text &&
      a.ownerContentVersion == b.ownerContentVersion &&
      a.bindingEpoch == b.bindingEpoch &&
      a.declaredBindingEpoch == b.declaredBindingEpoch;
}
int main() {
  const uint64_t kNode = 190;
  const int64_t kRes = -1;
  const uint32_t kKind = 1;

  // 1. 延迟结算正控：票据冻结的完整声明被晋升，换绑后的当前代可借用。
  {
    Session s;
    s.ownedTextSessionBindingEpoch = 20;
    s.ownedMirrorAccepted = decl(true, u"A", 1, 10, 10);
    PendingSettlement &p = g_pending[0];
    p = PendingSettlement();
    p.job = std::make_shared<WaitableJob>();
    p.job->p = JobPhase::Done;
    p.job->st = CJGUI_INTERNAL_RENDERER_OK;
    p.ownedMirrorValid = true;
    p.ownedMirrorText = u"B";
    p.ownedMirrorOwnerVersion = 2;
    p.ownedMirrorBindingEpoch = 20;
    p.ownedMirrorDeclaredBindingEpoch = 20;
    p.projectionVersion = 7;
    p.ticketId = 31;
    p.valid = true;
    s.candidateOpen = true;
    uint32_t d = settlePendingTicketLocked(&s, 0, nullptr);
    if (d != CJGUI_INTERNAL_RENDERER_PRESENT_DECISION_ACCEPTED) return 10;
    const Session::OwnedMirrorDeclaration *got =
        ownedMirrorDeclarationLocked(s, kNode, kRes, kKind);
    if (!got) return 11;
    if (!sameDeclaration(*got, p.ownedMirrorValid
            ? decl(true, u"B", 2, 20, 20) : s.ownedMirrorAccepted)) return 12;
    if (got->text != u"B") return 13;
    if (got->declaredBindingEpoch != 20) return 14;
    if (s.acceptedProjectionVersion != 7) return 15;
  }

  // 2. 延迟期间出现新声明：结算只晋升本票据冻结的声明，绝不回读 working 表。
  //    当前代已推进到 30 时查询必须具名拒绝；30 代提交后恢复。
  {
    Session s;
    s.ownedTextSessionBindingEpoch = 20;
    s.ownedMirrorAccepted = decl(true, u"A", 1, 10, 10);
    PendingSettlement &p = g_pending[0];
    p = PendingSettlement();
    p.job = std::make_shared<WaitableJob>();
    p.job->p = JobPhase::Done;
    p.job->st = CJGUI_INTERNAL_RENDERER_OK;
    p.ownedMirrorValid = true;
    p.ownedMirrorText = u"B";
    p.ownedMirrorOwnerVersion = 2;
    p.ownedMirrorBindingEpoch = 20;
    p.ownedMirrorDeclaredBindingEpoch = 20;
    p.projectionVersion = 7;
    p.ticketId = 32;
    p.valid = true;
    s.candidateOpen = true;
    // 提交返回 PENDING 之后、结算之前：owner 换绑到 30 并 stage 新声明。
    s.ownedTextSessionBindingEpoch = 30;
    s.ownedMirrorStaged = decl(true, u"C", 3, 30, 30);
    if (settlePendingTicketLocked(&s, 0, nullptr)
        != CJGUI_INTERNAL_RENDERER_PRESENT_DECISION_ACCEPTED) return 20;
    if (s.ownedMirrorAccepted.declaredBindingEpoch != 20) return 21;
    if (s.ownedMirrorAccepted.text != u"B") return 22;
    if (s.ownedMirrorAccepted.ownerContentVersion != 2) return 23;
    if (ownedMirrorDeclarationLocked(s, kNode, kRes, kKind) != nullptr) return 24;
    if (s.ownedMirrorStaged.text != u"C") return 25;
  }

  // 3. 同步整结构赋值与延迟逐字段晋升同源。
  {
    Session syncS;
    syncS.ownedTextSessionBindingEpoch = 20;
    Session::OwnedMirrorDeclaration frozen = decl(true, u"B", 2, 20, 20);
    syncS.ownedMirrorAccepted = frozen;
    Session delayed;
    delayed.ownedTextSessionBindingEpoch = 20;
    PendingSettlement &p = g_pending[0];
    p = PendingSettlement();
    p.job = std::make_shared<WaitableJob>();
    p.ownedMirrorValid = frozen.valid;
    p.ownedMirrorText = frozen.text;
    p.ownedMirrorOwnerVersion = frozen.ownerContentVersion;
    p.ownedMirrorBindingEpoch = frozen.bindingEpoch;
    p.ownedMirrorDeclaredBindingEpoch = frozen.declaredBindingEpoch;
    p.valid = true;
    delayed.candidateOpen = true;
    if (settlePendingTicketLocked(&delayed, 0, nullptr)
        != CJGUI_INTERNAL_RENDERER_PRESENT_DECISION_ACCEPTED) return 30;
    if (!sameDeclaration(syncS.ownedMirrorAccepted, delayed.ownedMirrorAccepted)) return 31;
  }

  // 4. 拒绝结算不晋升任何声明（accepted 保持旧值）。
  {
    Session s;
    s.ownedTextSessionBindingEpoch = 20;
    Session::OwnedMirrorDeclaration before = decl(true, u"A", 1, 10, 10);
    s.ownedMirrorAccepted = before;
    PendingSettlement &p = g_pending[0];
    p = PendingSettlement();
    p.job = std::make_shared<WaitableJob>();
    p.job->p = JobPhase::Done;
    p.job->st = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    p.ownedMirrorValid = true;
    p.ownedMirrorText = u"B";
    p.ownedMirrorOwnerVersion = 2;
    p.ownedMirrorBindingEpoch = 20;
    p.ownedMirrorDeclaredBindingEpoch = 20;
    p.valid = true;
    s.candidateOpen = true;
    if (settlePendingTicketLocked(&s, 0, nullptr)
        != CJGUI_INTERNAL_RENDERER_PRESENT_DECISION_REJECTED) return 40;
    if (!sameDeclaration(s.ownedMirrorAccepted, before)) return 41;
  }

  // 5. 重复结算不得二次晋升或推进帧号。
  {
    Session s;
    s.ownedTextSessionBindingEpoch = 20;
    PendingSettlement &p = g_pending[0];
    p = PendingSettlement();
    p.job = std::make_shared<WaitableJob>();
    p.ownedMirrorValid = true;
    p.ownedMirrorText = u"B";
    p.ownedMirrorOwnerVersion = 2;
    p.ownedMirrorBindingEpoch = 20;
    p.ownedMirrorDeclaredBindingEpoch = 20;
    p.valid = true;
    s.candidateOpen = true;
    if (settlePendingTicketLocked(&s, 0, nullptr)
        != CJGUI_INTERNAL_RENDERER_PRESENT_DECISION_ACCEPTED) return 50;
    uint64_t frameAfter = s.submittedFrameIndex;
    int64_t acceptedAfter = s.ticketAcceptedCount;
    if (settlePendingTicketLocked(&s, 0, nullptr)
        != CJGUI_INTERNAL_RENDERER_PRESENT_DECISION_ACCEPTED) return 51;
    if (s.submittedFrameIndex != frameAfter) return 52;
    if (s.ticketAcceptedCount != acceptedAfter) return 53;
  }

  std::cout << "pending_mirror_declaration_epoch_parity=ok" << std::endl;
  return 0;
}
'''

SIGNATURES = {
    'settle': 'static uint32_t settlePendingTicketLocked(Session *s, int slot, bool *outImageChanged)\n',
    'query': ('static const Session::OwnedMirrorDeclaration *ownedMirrorDeclarationLocked('
              'const Session &s,\n    uint64_t nodeId, int64_t resourceId, uint32_t nodeKind)\n'),
}


def build_source(host_text):
    parts = [PREFIX]
    for key in ('settle', 'query'):
        parts.append(extract(host_text, SIGNATURES[key]))
    parts.append(MAIN)
    return "".join(parts)


def compile_and_run(cxx_text):
    with tempfile.TemporaryDirectory() as tmp:
        src = pathlib.Path(tmp) / "harness.cpp"
        exe = pathlib.Path(tmp) / "harness"
        src.write_text(cxx_text)
        q = subprocess.run(['clang++', '-std=c++17', '-Wall', '-Wextra', '-Werror',
                            '-Wno-unused-parameter', '-Wno-unused-variable',
                            str(src), '-o', str(exe)],
                           capture_output=True, text=True)
        if q.returncode != 0:
            self_fail = "compile failed:\n" + q.stderr
            raise AssertionError(self_fail)
        return subprocess.run([str(exe)], capture_output=True, text=True)


class PendingMirrorDeclarationEpochTest(unittest.TestCase):
    def test_delayed_settlement_transports_full_declaration(self):
        host_text = SOURCE.read_text(encoding="utf-8")
        cxx = build_source(host_text)
        self.assertIn(TRANSPORT_LINE, cxx, "延迟晋升必须运输声明代")
        r = compile_and_run(cxx)
        self.assertEqual(r.returncode, 0,
                         "真实路径反例失败 rc=%d out=%r err=%r" % (r.returncode, r.stdout, r.stderr))
        self.assertIn("pending_mirror_declaration_epoch_parity=ok", r.stdout)

    def test_mutation_dropping_declared_epoch_transport_fails(self):
        host_text = SOURCE.read_text(encoding="utf-8")
        cxx = build_source(host_text)
        mutated = cxx.replace(TRANSPORT_LINE, "")
        self.assertNotEqual(mutated, cxx, "变异未生效")
        r = compile_and_run(mutated)
        self.assertNotEqual(r.returncode, 0,
                            "删掉声明代运输后仍通过 => 该判别没有证明力")


if __name__ == "__main__":
    unittest.main()
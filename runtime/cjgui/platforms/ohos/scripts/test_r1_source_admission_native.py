#!/usr/bin/env python3
"""R1 提交来源准入的真实链路反例（2026-10-02 Astra h-r1-source-admission）。

只读裁决：artifacts/consultations/h-r1-source-admission-astra/answer.md。

抽取 ohos_renderer.cpp 的真实生产函数（beginEditingOnNodeLocked /
pushPendingEndLocked / editingBindingHealthyLocked /
retireEditingContextIfUnhealthyLocked / syncEditingBufferAfterAcceptedSceneLocked /
takeEditingContextLocked / settlePendingTicketLocked /
present_composable_scene），在宿主 clang++ 下跑真实 present → 提交许可(job) →
settle → 收尾链；替身只控制调度与平台绘制结果，不替换来源判断、不手工安装
PendingSettlement。

覆盖 Astra case (e)（当前**不可**在 native 侧判别的两类历史之一）：

  * 焦点 A 时生成删除 B 的 V11 并在 A 时冻结 present；随后 begin(B)（B 仍在
    accepted）；来源一直有效；job 完成 Flush 后 settle：
    必须 **ACCEPTED**、ΔFlush=1、accepted=V11（B 缺席）、B 当次结算立即退役，
    队列恰为 end(A) 与 end(B)。
  * 只读化/不可交互变体同上：ACCEPTED、B 退役。
  * 第二个落点（Astra 要求）：同步成功路径（present 直接返回 OK、无 PENDING 窗口）
    删除当前绑定 B，同样必须发布并当次退役。
  * take 的完整绑定判据：live 但 accepted 中绑定已消失 → 拒绝旧输入。
  * 反例探针：把“结算时按焦点上下文差异整票拒绝”的旧实现加回同一函数，
    上面的用例必须翻红——证明该用例能检出“凡旧 context 票据都忽略”。

范围：本文件只证明 (e) 一侧；被判为**未闭合**的 (d)（过期来源的删除结果须在
提交许可前拒绝且零 Flush）需要尚未传入的“来源事实”，本文件不假装覆盖，见
answer.md 的两条候选路线。native 现有字段无法区分 (d)/(e)。

已知不判别项：发布点 `retireEditingContextIfUnhealthyLocked` 与随后 sync 内的
收场在本链上**终态相同**（二者都置 live=false/retired=true 并入队 end），因此
“删掉发布点退役调用”的变异不会翻红——不写这种假绿用例。真正需要发布点退役的
情形（准入拒绝时不执行 retire/sync、或旧草稿不得再按 blur 提交）依赖尚未接通的
来源准入，留待 (d) 接通后补测。
"""
import pathlib
import re
import subprocess
import tempfile
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]
SOURCE = ROOT / "host" / "ohos_renderer.cpp"


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


SIGNATURES = [
    # 声明就绪门先于 beginEditingOnNodeLocked 抽取（生产里它是文件级 static）。
    # B 组：镜像声明就绪门与 owned 身份字段用**生产原文**，换绑借用门不能是替身。
    'static const Session::OwnedMirrorDeclaration *ownedMirrorDeclarationLocked(const Session &s,',
    'void beginEditingOnNodeLocked(Session &s, const SceneNode &node)\n',
    'static void pushPendingEndLocked(',
    'static bool editingBindingHealthyLocked(',
    'static void retireEditingContextIfUnhealthyLocked(',
    'static void syncEditingBufferAfterAcceptedSceneLocked(',
    'static Session *takeEditingContextLocked(',
    'static uint32_t settlePendingTicketLocked(',
    'CjguiInternalRendererStatus cjgui_internal_renderer_present_composable_scene(',
]

PREFIX = r'''
#include <algorithm>
#include <atomic>
#include <cassert>
#include <cstdint>
#include <cstring>
#include <deque>
#include <iostream>
#include <map>
#include <memory>
#include <mutex>
#include <string>
#include <utility>
#include <vector>
#define RLOGI(...) do{}while(0)
#define RLOGW(...) do{}while(0)
using CjguiInternalRendererStatus = int;
constexpr int CJGUI_INTERNAL_RENDERER_OK=0, CJGUI_INTERNAL_RENDERER_PENDING=1,
  CJGUI_INTERNAL_RENDERER_INVALID_SESSION=2, CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR=3,
  CJGUI_INTERNAL_RENDERER_METAL_DRAWABLE_UNAVAILABLE=4;
constexpr uint32_t CJGUI_INTERNAL_RENDERER_PRESENT_DECISION_NONE=0,
  CJGUI_INTERNAL_RENDERER_PRESENT_DECISION_PENDING=1,
  CJGUI_INTERNAL_RENDERER_PRESENT_DECISION_ACCEPTED=2,
  CJGUI_INTERNAL_RENDERER_PRESENT_DECISION_REJECTED=3;
constexpr int kSettlementNone=0,kSettlementStillCommitting=1,kSettlementAborted=2,kSettlementCommitted=3;
std::atomic<int> g_lastSettlementVerdict{0},g_abortedSettlements{0},g_committedSettlements{0};

struct Pod {
  uint64_t nodeId=0, resourceId=0, nodeKind=10, projectionVersion=5,
    acceptedBindingEpoch=7, preservesActiveLocalText=0;
  uint32_t isReadOnly=0, isInteractive=1;
};
struct SceneNode { Pod pod; std::string semanticId, value; };
static bool isEditableTextKind(uint32_t k){return k==10||k==5||k==6;}

struct Session {
  struct TextRunBinding {};
  struct PendingEnd { int64_t contextId=0; std::string fieldName; bool settleOnDelivery=false; };
  struct ProxyRestore { bool armed=false, awaitingAck=false, platformInstalled=false; };
  std::deque<PendingEnd> pendingEnds;
  ProxyRestore proxyRestore;
  uint64_t token = 1;
  bool editing=false, editorRetired=false, editingContextLive=false,
    caretBlinkResetPending=false, editingContextRevealRequested=false,
    reconcileNotifyPending=false, selForwardedValid=false, previewActive=false,
    focusNotifyPending=false, markedActive=false, editingTapPending=false,
    candidateOpen=true, candidateFailed=false, humanCaretNotificationPending=false;
  uint64_t editingNodeId=0, editingResourceId=0, editingNodeKind=0,
    editingProjectionVersion=0, editingAcceptedBindingEpoch=0,
    editingContextGeneration=0, editingContextBaseVersion=0,
    surfaceGeneration=1, acceptedPaintTicketId=5, acceptedProjectionVersion=5,
    candidateProjectionVersion=6, nextTicketId=1, submittedFrameIndex=0,
    unackedTicketId=0, ticketDuplicateSettlementCount=0, ticketRejectedCount=0,
    ticketAcceptedCount=0, selectionOperationGeneration=0,
    surfaceGeometryRevision=1, surfaceWidth=640, surfaceHeight=480;
  int64_t editingContextId=0, reconcileOldContextId=0;
  uint32_t caretAffinity=0, caretUtf16=0, selStartUtf16=0, selEndUtf16=0,
    selPlatformStart=0, selPlatformEnd=0, markedStart=0, markedEnd=0, textMenuIntent=0;
  std::string editingFieldName;
  // owned 会话与镜像声明字段取**生产原文**（换绑借用门依赖 declaredBindingEpoch）。
  %OWNED_ID_FIELDS%
  %MIRROR_FIELDS%
  int64_t editingMirrorOwnerVersion = -1;
  std::u16string editingText, previewText;
  std::vector<SceneNode> accepted, candidate;
  std::map<uint64_t, Session::TextRunBinding> acceptedRunTable;
  double surfaceDensity=1, clearR=0, clearG=0, clearB=0, clearA=1;
};
static void pushPendingEndLocked(Session &s, int64_t contextId, const std::string &fieldName, bool settleOnDelivery);
static bool editingBindingHealthyLocked(const Session &s, const std::vector<SceneNode> &tree);

enum class JobPhase { Committing, Done, Cancelled };
struct Job {
  JobPhase phase=JobPhase::Committing; int status=CJGUI_INTERNAL_RENDERER_PENDING;
  virtual ~Job()=default;
  JobPhase phaseSnapshot(){return phase;}
  int statusSnapshot(){return status;}
  int waitFor();
};
struct PresentJob:Job {
  uint64_t session=0,ticketId=0,projectionVersion=0,generation=0,geometryRevision=0;
  int64_t sourceContextId=0; bool sourceLive=false; uint64_t parentAcceptedTicketId=0;
  void *window=nullptr; int width=0,height=0;
  double clearR=0,clearG=0,clearB=0,clearA=1;
  std::vector<SceneNode> nodes;
  %TICKET_MIRROR%
};
struct RedrawJob:Job{};
using JobRef=std::shared_ptr<Job>;
JobRef posted;
int flushCount=0, syncCalls=0, waitMode=0;
std::vector<SceneNode> submittedScene;
// 替身只决定调度结果：默认返回 PENDING（已登记票据），由 finishDrawing 落 Done/OK；
// waitMode=1 时直接落 Done/OK（同步成功路径，供 Astra 要求的第二个落点）。
int Job::waitFor(){
  if (waitMode == 1) {
    status = CJGUI_INTERNAL_RENDERER_OK; phase = JobPhase::Done; ++flushCount;
    submittedScene = static_cast<PresentJob*>(this)->nodes;
  }
  return status;
}
struct { void post(JobRef j){posted=j;} void postIfRunning(JobRef){} } g_render;
struct { std::mutex lock; } g_sessions;
static int surface(void**,uint64_t*,int32_t*,int32_t*,double*,uint64_t*){ return 1; }
struct { decltype(&surface) surfaceActive=surface; } g_ingress;
struct PendingSettlement {
  JobRef job; std::vector<SceneNode> nodes;
  std::map<uint64_t,Session::TextRunBinding> runTable;
  uint64_t projectionVersion=0,ticketId=0,frameIndex=0;
  uint32_t decision=0; int terminalStatus=0,drawableWidth=0,drawableHeight=0;
  double density=1; bool settled=false,valid=false,sourceEditingLive=false;
  int64_t sourceEditingContextId=0;
  %TICKET_MIRROR%
};
PendingSettlement g_pending[1];
struct CjguiInternalRendererFrameObservation {
  uint64_t ticketId=0,frameIndex=0; uint32_t drawableWidthPixels=0,drawableHeightPixels=0;
  double contentsScale=1; int readbackAttempted=0,readbackCompleted=0,readbackColorMatched=0;
};
bool freezeCandidateRunTableLocked(Session*,std::map<uint64_t,Session::TextRunBinding>&){return true;}
void cjguiOhosScheduleUnpostedImages(){} void cjguiOhosPruneReleasedImages(){}
void cjguiOhosLogAcceptedImageSwap(Session&,const std::vector<SceneNode>&,uint64_t,uint64_t,const char*){}
// 观测/账本类 helper：只记数，不参与来源准入判定。
static uint64_t g_observationSeq = 0;
uint64_t cjgui_ohos_observation_seq(){ return ++g_observationSeq; }
int publishInFlightCalls = 0;
void cjguiOhosPublishInFlight(uint64_t,uint64_t,uint32_t,int32_t,uint64_t,uint64_t){++publishInFlightCalls;}
void cjguiOhosLogAcceptedSummary(const std::vector<SceneNode>&,uint64_t,uint64_t){}
int settlementPublishCalls = 0, ticketTerminalPublishCalls = 0;
void cjguiOhosPublishSettlement(uint64_t, const PendingSettlement&,
                                const std::vector<SceneNode>&){++settlementPublishCalls;}
void cjguiOhosPublishTicketTerminal(uint64_t, const PendingSettlement&, int){
  ++ticketTerminalPublishCalls;}
bool reconcileAcceptedImagesLocked(Session*){return false;}
void cjguiOhosLogAcceptedFrame(const std::vector<SceneNode>&){}
void cjguiOhosObserveSurfaceLocked(Session*,uint64_t,uint64_t,int,int,double){}
void cjguiOhosLogImageSnapshot(const char*){}
static Session* active=nullptr;
static Session* lookupSessionLocked(uint64_t){return active;}
static Session* findEditingSessionLocked(){return active;}
static int sessionSlotLocked(uint64_t){return 0;}
std::atomic<int64_t> g_nextEditingContextId{11};
static int cancelCount=0;
void cancelProxyRestoreRequest(Session&,const char*){++cancelCount;}
void clearHumanSelectionAnchorLocked(Session&){}
bool settleComposedBufferOnBlurLocked(Session&){return false;}
bool editorOwnsTextSession(Session&){return false;}
std::u16string utf8ToUtf16(const std::string& v){return std::u16string(v.begin(),v.end());}
uint32_t clampToCodePointBoundary(const std::u16string& v,uint32_t p){return std::min(p,uint32_t(v.size()));}
'''

MAIN = r'''
static SceneNode node(uint64_t id, uint64_t epoch, const char *field, uint64_t version=5) {
  SceneNode n; n.pod.nodeId=id; n.pod.resourceId=id; n.pod.acceptedBindingEpoch=epoch;
  n.pod.projectionVersion=version; n.semanticId=field; n.value="abc"; return n;
}
static bool queueHas(Session &s, int64_t ctx) {
  for (const auto &e : s.pendingEnds) if (e.contextId == ctx) return true;
  return false;
}
static int queueCount(Session &s) { return static_cast<int>(s.pendingEnds.size()); }
// 完成一次真实渲染：替身把 job 落 Done/OK 并记账 Flush。
static void finishDrawing() {
  auto j = std::static_pointer_cast<PresentJob>(posted);
  submittedScene = j->nodes;
  ++flushCount;
  j->status = CJGUI_INTERNAL_RENDERER_OK;
  j->phase = JobPhase::Done;
}

static void reset() {
  flushCount = 0; syncCalls = 0; submittedScene.clear(); posted.reset();
  g_pending[0] = PendingSettlement{};
}

int main() {
  const SceneNode A = node(107,7,"A");
  const SceneNode B = node(313,8,"B");

  // (e) 焦点 A 时冻结 present 删除 B；随后 begin(B)；来源一直有效；Flush 后 settle。
  //     合法删除必须发布并退役 B —— “凡旧 context 票据都忽略”在此翻红。
  {
    reset();
    Session s; active=&s;
    s.accepted = { A, B };
    s.acceptedPaintTicketId = 5; s.acceptedProjectionVersion = 5;
    beginEditingOnNodeLocked(s, A);
    int64_t ctxA = s.editingContextId;
    s.candidateOpen = true; s.candidate = { A }; s.candidateProjectionVersion = 6;
    int rc = cjgui_internal_renderer_present_composable_scene(1, nullptr);
    if (rc != CJGUI_INTERNAL_RENDERER_PENDING) return 10;
    if (!g_pending[0].valid) return 11;
    if (g_pending[0].sourceEditingContextId != ctxA) return 12;
    if (g_pending[0].ticketId == 0) return 13;
    // 焦点移到 B（B 此刻仍在 accepted V10 中，begin 依据健康 accepted）。
    beginEditingOnNodeLocked(s, B);
    int64_t ctxB = s.editingContextId;
    if (ctxB == ctxA) return 14;
    finishDrawing();
    uint32_t verdict = settlePendingTicketLocked(&s, 0, nullptr);
    if (verdict != CJGUI_INTERNAL_RENDERER_PRESENT_DECISION_ACCEPTED) return 15;
    if (flushCount != 1) return 16;
    if (s.accepted.size() != 1 || s.accepted[0].pod.nodeId != 107) return 17;
    if (s.editingContextLive || !s.editorRetired) return 18;   // B 当次结算立即退役
    if (!queueHas(s, ctxA)) return 19;                          // end(A)：焦点切换
    if (!queueHas(s, ctxB)) return 20;                          // end(B)：真实撤销
    if (queueCount(s) != 2) return 21;
  }

  // (e 权限变体一) 只读化：ACCEPTED 且当次退役。
  {
    reset();
    Session s; active=&s;
    SceneNode ro = B; ro.pod.isReadOnly = 1;
    s.accepted = { A, B };
    beginEditingOnNodeLocked(s, A);
    int64_t ctxA = s.editingContextId;
    s.candidateOpen = true; s.candidate = { A, ro }; s.candidateProjectionVersion = 6;
    if (cjgui_internal_renderer_present_composable_scene(1, nullptr) != CJGUI_INTERNAL_RENDERER_PENDING) return 30;
    beginEditingOnNodeLocked(s, B);
    int64_t ctxB = s.editingContextId;
    finishDrawing();
    if (settlePendingTicketLocked(&s, 0, nullptr) != CJGUI_INTERNAL_RENDERER_PRESENT_DECISION_ACCEPTED) return 31;
    if (flushCount != 1) return 32;
    if (s.editingContextLive || !s.editorRetired) return 33;
    if (!queueHas(s, ctxA) || !queueHas(s, ctxB) || queueCount(s) != 2) return 34;
    (void)ctxA;
  }

  // (e 权限变体二) 不可交互：同上。
  {
    reset();
    Session s; active=&s;
    SceneNode ni = B; ni.pod.isInteractive = 0;
    s.accepted = { A, B };
    beginEditingOnNodeLocked(s, A);
    int64_t ctxA = s.editingContextId;
    s.candidateOpen = true; s.candidate = { A, ni }; s.candidateProjectionVersion = 6;
    if (cjgui_internal_renderer_present_composable_scene(1, nullptr) != CJGUI_INTERNAL_RENDERER_PENDING) return 40;
    beginEditingOnNodeLocked(s, B);
    int64_t ctxB = s.editingContextId;
    finishDrawing();
    if (settlePendingTicketLocked(&s, 0, nullptr) != CJGUI_INTERNAL_RENDERER_PRESENT_DECISION_ACCEPTED) return 41;
    if (s.editingContextLive || !s.editorRetired) return 42;
    if (!queueHas(s, ctxA) || !queueHas(s, ctxB)) return 43;
  }

  // (e 权限变体三) 同号换绑（epoch 更新）：B 的新身份出现，旧 B 退役；旧输入被拒。
  {
    reset();
    Session s; active=&s;
    SceneNode B2 = node(313,9,"B");
    s.accepted = { A, B };
    beginEditingOnNodeLocked(s, A);
    int64_t ctxA = s.editingContextId;
    s.candidateOpen = true; s.candidate = { A, B2 }; s.candidateProjectionVersion = 6;
    if (cjgui_internal_renderer_present_composable_scene(1, nullptr) != CJGUI_INTERNAL_RENDERER_PENDING) return 50;
    beginEditingOnNodeLocked(s, B);
    int64_t ctxB = s.editingContextId;
    finishDrawing();
    if (settlePendingTicketLocked(&s, 0, nullptr) != CJGUI_INTERNAL_RENDERER_PRESENT_DECISION_ACCEPTED) return 51;
    if (s.editingContextLive || !s.editorRetired) return 52;   // 旧 B(epoch8) 立即失效
    if (takeEditingContextLocked(ctxB) != nullptr) return 53;  // 旧输入被拒
    if (!queueHas(s, ctxA) || !queueHas(s, ctxB)) return 54;
  }

  // 正控：来源与焦点都不变，合法提交照常发布且不退役。
  {
    reset();
    Session s; active=&s;
    s.accepted = { A, B };
    beginEditingOnNodeLocked(s, A);
    int64_t ctxA = s.editingContextId;
    s.candidateOpen = true; s.candidate = { A, B }; s.candidateProjectionVersion = 6;
    if (cjgui_internal_renderer_present_composable_scene(1, nullptr) != CJGUI_INTERNAL_RENDERER_PENDING) return 60;
    finishDrawing();
    if (settlePendingTicketLocked(&s, 0, nullptr) != CJGUI_INTERNAL_RENDERER_PRESENT_DECISION_ACCEPTED) return 61;
    if (!s.editingContextLive || s.editorRetired) return 62;
    if (takeEditingContextLocked(ctxA) == nullptr) return 63;
    if (queueCount(s) != 0) return 64;
  }

  // take 的完整绑定判据（缓冲写入前授权）：live 但 accepted 中绑定已消失 → 拒绝旧输入。
  // 此例中 editingContextLive 仍为真，判别只依赖 takeEditingContextLocked 的健康判据。
  {
    reset();
    Session s; active=&s;
    s.accepted = { A };
    beginEditingOnNodeLocked(s, A);
    int64_t ctx = s.editingContextId;
    if (!s.editingContextLive) return 70;
    if (takeEditingContextLocked(ctx) != &s) return 71;
    s.accepted.clear();
    if (takeEditingContextLocked(ctx) != nullptr) return 72;
  }

  // Astra 要求的第二个落点：同步成功路径（waitFor 直接 OK，无 PENDING 窗口），
  // 删除当前绑定 B 同样必须发布并当次退役。
  {
    reset(); waitMode = 1;
    Session s; active=&s;
    s.accepted = { A, B };
    beginEditingOnNodeLocked(s, B);
    int64_t ctxB = s.editingContextId;
    s.candidateOpen = true; s.candidate = { A }; s.candidateProjectionVersion = 6;
    if (cjgui_internal_renderer_present_composable_scene(1, nullptr) != CJGUI_INTERNAL_RENDERER_OK) return 80;
    if (flushCount != 1) return 81;
    if (s.accepted.size() != 1 || s.accepted[0].pod.nodeId != 107) return 82;
    if (s.editingContextLive || !s.editorRetired) return 83;
    if (!queueHas(s, ctxB) || queueCount(s) != 1) return 84;
    reset(); waitMode = 0;
  }

  // B1（2026-10-06 设备根因，PID23342）：首绑缺声明 → 声明晋升 → 重新聚焦必须
  //     **重新认领** accepted 镜像。旧判据把 `editing==true` 当"正在编辑"，重入走
  //     wasEditing 早退，镜像与 editingMirrorOwnerVersion 永不初始化；成功激活的
  //     凭据是活上下文，不是 editing 旗标。
  {
    reset();
    Session s; active=&s;
    s.accepted = { A };
    s.ownedTextSessionEnabled = true;
    s.ownedTextSessionNodeId = A.pod.nodeId;
    s.ownedTextSessionResourceId = A.pod.resourceId;
    s.ownedTextSessionNodeKind = A.pod.nodeKind;
    s.ownedTextSessionBindingEpoch = 9;
    s.ownedMirrorAccepted.valid = true;
    s.ownedMirrorAccepted.text = utf8ToUtf16("mirror-v9");
    s.ownedMirrorAccepted.ownerContentVersion = 3;
    s.ownedMirrorAccepted.bindingEpoch = 9;
    s.ownedMirrorAccepted.declaredBindingEpoch = 7;   // 旧声明代：不得借给新绑定
    // (a) 首绑缺声明：输入准入关闭、缓冲不播种，但 editing 旗标已经为真——
    //     这正是旧判据会把下一次聚焦误判成"延续"的地方。
    beginEditingOnNodeLocked(s, A);
    const int64_t ctxRefused = s.editingContextId;
    if (!s.editing) return 90;
    if (s.editingContextLive || s.focusNotifyPending) return 91;
    if (!s.editingText.empty()) return 92;
    // (b) 声明晋升到当前绑定代后重新聚焦：完整激活 + 认领镜像正文与 owner 版本。
    s.ownedMirrorAccepted.declaredBindingEpoch = 9;
    beginEditingOnNodeLocked(s, A);
    if (s.editingContextId == ctxRefused) return 93;
    if (s.editingText != utf8ToUtf16("mirror-v9")) return 94;
    if (s.editingMirrorOwnerVersion != 3) return 95;
    if (!s.editingContextLive || !s.focusNotifyPending) return 96;
    if (s.caretUtf16 != 9 || s.selStartUtf16 != 9 || s.selEndUtf16 != 9) return 97;
    const int64_t ctxLive = s.editingContextId;
    // (c) 真实活跃延续：同绑定重聚焦幂等——上下文号不变，草稿与非空选区不重置。
    //     "把认领失败改成每次聚焦都重置"会在此翻红（指导：不得泛化重置草稿）。
    s.editingText = utf8ToUtf16("mirror-v9-draft");
    s.caretUtf16 = 14; s.selStartUtf16 = 6; s.selEndUtf16 = 14;
    s.focusNotifyPending = false;
    beginEditingOnNodeLocked(s, A);
    if (s.editingContextId != ctxLive) return 98;
    if (s.editingText != utf8ToUtf16("mirror-v9-draft")) return 99;
    if (s.selStartUtf16 != 6 || s.selEndUtf16 != 14) return 100;
    if (!s.focusNotifyPending) return 101;   // 幂等但仍要重发焦点通知
    // (d) 外部换绑（声明代与 owner 版本一起推进）后的下一次成功激活：认领**新**
    //     正文与新 owner 版本，同时保留同节点的非空选区（不折叠成末尾 caret）。
    s.ownedTextSessionBindingEpoch = 10;
    s.ownedMirrorAccepted.declaredBindingEpoch = 10;
    s.ownedMirrorAccepted.text = utf8ToUtf16("mirror-v10-longer");
    s.ownedMirrorAccepted.ownerContentVersion = 6;
    s.editingContextLive = false;            // 上下文已因外部推进失效＝尚未成功激活
    beginEditingOnNodeLocked(s, A);
    if (s.editingText != utf8ToUtf16("mirror-v10-longer")) return 102;
    if (s.editingMirrorOwnerVersion != 6) return 103;
    if (s.selEndUtf16 <= s.selStartUtf16) return 104;
    if (!s.editingContextLive) return 105;
  }

  std::cout << "ok\n";
  return 0;
}
'''


def span(text, start_anchor, end_anchor):
    start = text.index(start_anchor)
    return text[start:text.index(end_anchor, start) + len(end_anchor)]


def harness(source):
    body = (PREFIX + '\n'.join(function(source, s) for s in SIGNATURES) + '\n' + MAIN)
    return (body
            .replace('%OWNED_ID_FIELDS%', span(source,
                       '    bool ownedTextSessionEnabled = false;',
                       '    uint64_t ownedTextSessionBindingEpoch = 0;'))
            .replace('%MIRROR_FIELDS%', span(source,
                       '    struct OwnedMirrorDeclaration {',
                       '    OwnedMirrorDeclaration ownedMirrorAccepted;'))
            # 票据（PresentJob）与结算记录（PendingSettlement）上的镜像声明字段同名；
            # 取生产原文一份，注入两处替身，字段漂移即编译失败而不是静默少判。
            .replace('%TICKET_MIRROR%', span(source,
                       '    bool ownedMirrorValid = false;',
                       '    uint64_t ownedMirrorDeclaredBindingEpoch = 0;')))


class R1SourceAdmissionNativeTest(unittest.TestCase):
    def run_source(self, source):
        with tempfile.TemporaryDirectory(prefix='cjgui-h-r1-') as tmp:
            cpp = pathlib.Path(tmp) / 'source.cpp'
            cpp.write_text(harness(source))
            exe = pathlib.Path(tmp) / 'source'
            q = subprocess.run(['clang++', '-std=c++17', '-Wall', '-Wextra',
                                str(cpp), '-o', str(exe)], capture_output=True, text=True)
            self.assertEqual(q.returncode, 0, q.stderr)
            return subprocess.run([str(exe)], capture_output=True, text=True).returncode

    def test_case_e_valid_deletion_publishes_and_retires(self):
        self.assertEqual(self.run_source(SOURCE.read_text()), 0)

    def test_negative_post_flush_focus_rejection_reintroduced(self):
        # 变异：把“结算时按焦点上下文差异整票拒绝”的旧实现加回同一函数。
        # (e) 用例必须翻红——证明该用例能检出“凡旧 context 票据都忽略”。
        source = SOURCE.read_text()
        anchor = '    if (phase == JobPhase::Done && status == CJGUI_INTERNAL_RENDERER_OK) {'
        assert anchor in source
        broken = source.replace(anchor,
            '    if (phase == JobPhase::Done && s->editingContextLive && p.sourceEditingLive &&\n'
            '        s->editingContextId != p.sourceEditingContextId) { return CJGUI_INTERNAL_RENDERER_PRESENT_DECISION_REJECTED; }\n'
            + anchor, 1)
        self.assertNotEqual(broken, source)
        self.assertNotEqual(self.run_source(broken), 0)

    def test_negative_input_gate_dropped(self):        # 变异：去掉 takeEditingContextLocked 的完整绑定健康判据（只留 live/context）。
        # (e 变体三) 必须翻红——证明用例覆盖“缓冲写入前的 accepted 授权”（Astra 第 2–4 点）。
        source = SOURCE.read_text()
        anchor = '    if (!editingBindingHealthyLocked(*s, s->accepted)) return nullptr;\n'
        assert anchor in source, 'takeEditingContextLocked health gate anchor not found'
        broken = source.replace(anchor, '', 1)
        self.assertNotEqual(broken, source)
        self.assertNotEqual(self.run_source(broken), 0)

    WAS_EDITING_ANCHOR = ('    const bool wasEditing = s.editing && !s.editorRetired &&'
                          ' s.editingContextLive &&\n'
                          '        s.editingNodeId == node.pod.nodeId;\n')

    def test_negative_legacy_was_editing_criterion(self):
        """B1 变异：把"正在编辑"退回旧判据（只看 editing 旗标，不看激活凭据）。

        首绑失败留下的 editing=true 会被当成活跃延续，重入跳过镜像认领与
        editingMirrorOwnerVersion 初始化——(b)/(d) 必须翻红。"""
        source = SOURCE.read_text()
        assert self.WAS_EDITING_ANCHOR in source, 'B1 wasEditing criterion anchor not found'
        broken = source.replace(self.WAS_EDITING_ANCHOR,
                                '    const bool wasEditing ='
                                ' s.editing && s.editingNodeId == node.pod.nodeId;\n', 1)
        self.assertNotEqual(broken, source)
        self.assertNotEqual(self.run_source(broken), 0)

    def test_negative_blanket_reset_on_refocus(self):
        """B1 的另一侧：用"每次聚焦都当新激活"糊掉认领失败＝丢掉本地草稿与非空选区。

        (c) 必须翻红——真实活跃延续不得被泛化重置。"""
        source = SOURCE.read_text()
        assert self.WAS_EDITING_ANCHOR in source, 'B1 wasEditing criterion anchor not found'
        broken = source.replace(self.WAS_EDITING_ANCHOR,
                                '    const bool wasEditing = false;\n', 1)
        self.assertNotEqual(broken, source)
        self.assertNotEqual(self.run_source(broken), 0)


if __name__ == '__main__':
    unittest.main()

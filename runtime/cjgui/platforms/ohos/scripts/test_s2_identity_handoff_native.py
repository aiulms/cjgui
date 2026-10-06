#!/usr/bin/env python3
"""R1 回归（h-source-preview-followup 2026-10-02 补轮）：完整绑定身份与全部
收场入口的旧身份冻结。

抽取 ohos_renderer.cpp 的真实生产函数（beginEditingOnNodeLocked /
pushPendingEndLocked / takeEditingContextLocked /
ohos_renderer_ime_finish_editing_ctx / editingBindingHealthyLocked /
retireEditingContextIfUnhealthyLocked /
syncEditingBufferAfterAcceptedSceneLocked），在宿主 clang++ 下断言：

  * 正控：begin(A)→begin(B)，待发 end 属于旧 A；
  * finish(A=13)→bind(B=14)：end 仍属 13/A（finish 也是收场入口）；
  * 同 id 换 epoch / 换 semantic / 换 kind：完整绑定身份判定，必须换上下文；
  * 完整绑定幂等：同身份重复聚焦不换号、不排队 end；
  * 发布点退役：新 accepted 树里完整身份健康则不退役（焦点变化无关），
    删除/只读化/换 epoch 即不健康，首次发布立即退役；
  * 输入准入：takeEditingContextLocked 按完整绑定判据，绑定消失后拒绝旧输入；
  * sync 只在当前来源提交上运行，**没有任何宽限**：缺席/失配/版本回退都是
    真实撤销，首次发布立即退役。

范围边界（2026-10-02 Astra h-r1-source-admission，见
artifacts/consultations/h-r1-source-admission-astra/answer.md）：本文件**不**
覆盖提交来源准入。曾经的 pendingSettlementSourceStaleLocked（在 Flush 之后按
焦点 context 差异拒票）已随 R1 修复删除，且未在具备零 Flush 的时点补回——
仅在两个成功分支晋升前加判断无法保证拒绝时零 Flush，必须在提交许可
（acquireCommitPermission）之前完成准入。native 现有冻结字段（候选节点/epoch、
candidateProjectionVersion、parentAcceptedTicketId、editingContextId/live）
全部组合也无法区分「过期来源的删除结果(d)」与「仍有效、生成时焦点在别处的删除
(e)」；差异只存在于尚未传入的来源事实。本文件里的“B 删除”用例直接改写编辑
绑定并清空 accepted，走的是 begin/sync 入口，**不经过 present**，因此检不出
“凡旧 context 票据都一律忽略”的提交路径缺陷。该准入与 (d)/(e) 反例须在来源
事实接通后于真实 present→提交许可→query/settle/ACK 链上补测。

变异负控证明判别力：去掉 epoch 比较 / 去掉只读判定 / 重新引入版本阈值宽限 /
去掉幂等 epoch / 去掉 finish 冻结，同一二进制必须失败。
"""
import pathlib
import subprocess
import tempfile
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]
SOURCE = ROOT / "host" / "ohos_renderer.cpp"


def extract_method(text, signature_start):
    start = text.index(signature_start)
    end = text.index("\n}\n", start) + 3
    return text[start:end]


SIGNATURES = {
    'begin': 'void beginEditingOnNodeLocked(Session &s, const SceneNode &node)\n',
    'push_end': 'static void pushPendingEndLocked(',
    'take': 'static Session *takeEditingContextLocked(int64_t contextId)\n',
    'finish': 'extern "C" int32_t ohos_renderer_ime_finish_editing_ctx(int64_t contextId)\n',
    'healthy': 'static bool editingBindingHealthyLocked(const Session &s, const std::vector<SceneNode> &tree)\n',
    'retire': 'static void retireEditingContextIfUnhealthyLocked(Session *s)\n',
    'sync': 'static void syncEditingBufferAfterAcceptedSceneLocked(Session *s)\n',
    # A1：owned 镜像声明查询。begin/sync 的缺声明门都经它判"声明缺失/失效"，
    # 必须先于两者定义（生产里同样是这两个调用点依赖它）。
    'mirror_decl': ('static const Session::OwnedMirrorDeclaration *ownedMirrorDeclarationLocked('
                    'const Session &s,\n    uint64_t nodeId, int64_t resourceId, uint32_t nodeKind)\n'),
}

PREFIX = r'''
#include <algorithm>
#include <atomic>
#include <cstdint>
#include <deque>
#include <iostream>
#include <memory>
#include <mutex>
#include <string>
#include <utility>
#include <vector>
#define RLOGI(...) do {} while(0)
#define RLOGW(...) do {} while(0)
struct Pod {
  uint64_t nodeId=0, projectionVersion=5, acceptedBindingEpoch=7, preservesActiveLocalText=0;
  int64_t resourceId=0;
  uint32_t nodeKind=10, isReadOnly=0, isInteractive=1;
};
struct SceneNode { Pod pod; std::string semanticId, value; };
static bool isEditableTextKind(uint32_t k) { return k == 10 || k == 5 || k == 6; }
struct Session {
  struct PendingEnd {
    int64_t contextId = 0;
    std::string fieldName;
    bool settleOnDelivery = false;
  };
  std::deque<PendingEnd> pendingEnds;
  bool editing=false, editorRetired=false, editingContextLive=false,
       caretBlinkResetPending=false, editingContextRevealRequested=false,
       reconcileNotifyPending=false, selForwardedValid=false, previewActive=false,
       focusNotifyPending=false, markedActive=false, editingTapPending=false;
uint64_t editingNodeId=0, editingNodeKind=0,
         editingProjectionVersion=0, editingAcceptedBindingEpoch=0,
         editingContextGeneration=0, editingContextBaseVersion=0,
         surfaceGeneration=1, acceptedPaintTicketId=5, acceptedProjectionVersion=5;
  int64_t editingResourceId=0;
  int64_t editingContextId=0, reconcileOldContextId=0;
  uint32_t caretAffinity=0, caretUtf16=0, selStartUtf16=0, selEndUtf16=0,
           selPlatformStart=0, selPlatformEnd=0, markedStart=0, markedEnd=0,
           textMenuIntent=0;
  std::string editingFieldName;
  std::u16string editingText, previewText;
  std::vector<SceneNode> accepted;
  // A1：owned 会话镜像声明。生产 Session::OwnedMirrorDeclaration 的同型替身——
  // begin/sync 的缺声明门与 ownedMirrorDeclarationLocked 都读这些字段。
  struct OwnedMirrorDeclaration {
    bool valid=false; std::u16string text; int64_t ownerContentVersion=-1;
    uint64_t bindingEpoch=0; uint64_t declaredBindingEpoch=0;
  };
  bool ownedTextSessionEnabled=false;
  // 生产 editorOwnsTextSession 的完整输入：此前 harness 用恒 false 桩，
  // 覆盖了真实 owned 路径（指导明确禁用）。必须与生产同名同型。
  bool rangeEditDeltaRequested=true;
  uint64_t ownedTextSessionNodeId=0;
  int64_t ownedTextSessionResourceId=-1;
  uint32_t ownedTextSessionNodeKind=10;
  uint64_t ownedTextSessionBindingEpoch=0;
  OwnedMirrorDeclaration ownedMirrorStaged;
  OwnedMirrorDeclaration ownedMirrorAccepted;
  int64_t editingMirrorOwnerVersion=-1;
};
static bool editingBindingHealthyLocked(const Session &s, const std::vector<SceneNode> &tree);
// 与生产 PendingSettlement 的来源字段同名同型（helper 只读这两个字段）。
struct PendingSettlement {
  int64_t sourceEditingContextId = 0;
  bool sourceEditingLive = false;
};
struct {std::mutex lock;} g_sessions;
std::atomic<int64_t> g_nextEditingContextId{11};
static int cancelCount = 0;
void cancelProxyRestoreRequest(Session &, const char *) { ++cancelCount; }
void clearHumanSelectionAnchorLocked(Session &) {}
bool settleComposedBufferOnBlurLocked(Session &) {return false;}
// 生产 editorOwnsTextSession 原样（ohos_renderer.cpp:6767）：窗口声明拥有该节点
// 且开启范围增量投递时，精确范围增量是权威通道。harness 禁止用恒 false 桩。
bool editorOwnsTextSession(const Session &s)
{
    return s.ownedTextSessionEnabled && s.rangeEditDeltaRequested &&
        s.editingNodeId == s.ownedTextSessionNodeId &&
        s.editingResourceId == s.ownedTextSessionResourceId &&
        s.editingNodeKind == s.ownedTextSessionNodeKind;
}
std::u16string utf8ToUtf16(const std::string &v) {return std::u16string(v.begin(),v.end());}
uint32_t clampToCodePointBoundary(const std::u16string &v,uint32_t p) {return std::min(p,uint32_t(v.size()));}
static Session *active=nullptr;
static Session *findEditingSessionLocked() {return active;}
struct RedrawJob {};
struct { void post(std::shared_ptr<RedrawJob>) {} } g_render;
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
int main() {
  // 1. 正控：begin(A)→begin(B)，待发 end 属于旧 A。
  {
    Session control; active=&control;
    beginEditingOnNodeLocked(control, node(107,7,"A"));
    int64_t oldCtx=control.editingContextId;
    beginEditingOnNodeLocked(control, node(313,8,"B"));
    if (control.pendingEnds.size()!=1) return 10;
    if (control.pendingEnds.front().contextId!=oldCtx) return 11;
    if (control.pendingEnds.front().fieldName!="A") return 12;
    if (control.editingContextId==oldCtx) return 13;
  }
  // 2. finish(A)→bind(B)：end 仍属 A（生产反例：曾误寄 14/B）。
  {
    Session s; active=&s;
    beginEditingOnNodeLocked(s, node(107,7,"A"));
    // 绑定自健康 accepted 节点：生产 accepted 必含该节点，输入准入据此授权。
    s.accepted.clear(); s.accepted.push_back(node(107,7,"A"));
    int64_t oldCtx=s.editingContextId;
    if (ohos_renderer_ime_finish_editing_ctx(oldCtx)!=0) return 20;
    beginEditingOnNodeLocked(s, node(313,8,"B"));
    int64_t newCtx=s.editingContextId;
    if (newCtx==oldCtx) return 21;
    if (!queueHas(s, oldCtx)) return 22;
    if (queueHas(s, newCtx)) return 23;
    if (s.pendingEnds.front().fieldName!="A") return 24;
  }
  // 3. 同 id 换 epoch（7→99）：完整身份幂等——必须换上下文。
  {
    Session aba; active=&aba;
    beginEditingOnNodeLocked(aba, node(107,7,"A"));
    int64_t abaOld=aba.editingContextId;
    beginEditingOnNodeLocked(aba, node(107,99,"A"));
    if (aba.editingContextId==abaOld) return 30;
    if (aba.editingAcceptedBindingEpoch!=99) return 31;
    if (!queueHas(aba, abaOld)) return 32;
  }
  // 3b. 同 id 换 semantic / 换 kind 同样是换绑。
  {
    Session sk; active=&sk;
    beginEditingOnNodeLocked(sk, node(107,7,"A"));
    int64_t before=sk.editingContextId;
    beginEditingOnNodeLocked(sk, node(107,7,"B"));
    if (sk.editingContextId==before) return 34;
    Session sk2; active=&sk2;
    beginEditingOnNodeLocked(sk2, node(107,7,"A"));
    before=sk2.editingContextId;
    SceneNode otherKind = node(107,7,"A"); otherKind.pod.nodeKind=11;
    beginEditingOnNodeLocked(sk2, otherKind);
    if (sk2.editingContextId==before) return 35;
  }
  // 4. 完整绑定幂等：同身份重复聚焦不换号、不排队 end。
  {
    Session idem; active=&idem;
    beginEditingOnNodeLocked(idem, node(107,7,"A"));
    int64_t first=idem.editingContextId;
    beginEditingOnNodeLocked(idem, node(107,7,"A"));
    if (idem.editingContextId!=first) return 40;
    if (!idem.pendingEnds.empty()) return 41;
  }
  // 5. finish 的陈旧上下文被拒（rc=1），不排队。
  {
    Session st; active=&st;
    beginEditingOnNodeLocked(st, node(107,7,"A"));
    st.accepted.clear(); st.accepted.push_back(node(107,7,"A"));
    if (ohos_renderer_ime_finish_editing_ctx(9999)!=1) return 50;
    if (!st.pendingEnds.empty()) return 51;
  }
  // 6. R1补轮（Astra）：发布点按**完整绑定健康**判据退役；焦点变化**不**拒合法
  // 提交（旧的 post-flush 焦点差异拒票已退役，见生产注释）。
  {
    Session s; active=&s;
    beginEditingOnNodeLocked(s, node(107,7,"A"));
    int64_t ctxA=s.editingContextId;
    // 6a-1 新 accepted 树含同一完整身份 → 健康，不退役（合法提交；焦点无关）。
    s.accepted.clear(); s.accepted.push_back(node(107,7,"A"));
    retireEditingContextIfUnhealthyLocked(&s);
    if (!s.editingContextLive || s.editorRetired) return 60;
    if (!editingBindingHealthyLocked(s, s.accepted)) return 66;
    // 6a-2 有效 B 删除即使提交生成时焦点在 A（模拟：先切 B 焦点，再把绑定身份
    // 还原为 A 的删除提交），节点缺席 → 立即退役。负控：凡"旧 context 票据一律
    // 忽略"的实现在此翻红。
    beginEditingOnNodeLocked(s, node(313,8,"B"));
    if (s.editingContextId==ctxA) return 61;
    s.editingNodeId=107; s.editingResourceId=107; s.editingNodeKind=10;
    s.editingAcceptedBindingEpoch=7; s.editingContextLive=true; s.editorRetired=false;
    s.accepted.clear();
    retireEditingContextIfUnhealthyLocked(&s);
    if (s.editingContextLive || !s.editorRetired) return 62;
  }
  // 6a-3 只读化即不健康 → 退役。
  {
    Session s; active=&s;
    beginEditingOnNodeLocked(s, node(107,7,"A"));
    SceneNode ro = node(107,7,"A"); ro.pod.isReadOnly=1;
    s.accepted.clear(); s.accepted.push_back(ro);
    retireEditingContextIfUnhealthyLocked(&s);
    if (s.editingContextLive) return 67;
  }
  // 6a-4 换 epoch（ABA）即不健康 → 退役。
  {
    Session s; active=&s;
    beginEditingOnNodeLocked(s, node(107,7,"A"));
    s.accepted.clear(); s.accepted.push_back(node(107,99,"A"));
    retireEditingContextIfUnhealthyLocked(&s);
    if (s.editingContextLive) return 68;
  }
  // 6a-5 输入准入按**完整绑定**：健康时 take 接受，绑定消失后拒绝旧输入。
  {
    Session s; active=&s;
    beginEditingOnNodeLocked(s, node(107,7,"A"));
    int64_t ctx=s.editingContextId;
    s.accepted.clear(); s.accepted.push_back(node(107,7,"A"));
    if (takeEditingContextLocked(ctx)!=&s) return 69;
    s.accepted.clear();
    if (takeEditingContextLocked(ctx)!=nullptr) return 70;
  }
  // 6b. 当前来源提交缺席：真实移除，立即收场并冻结身份（无任何宽限）。
  {
    Session s; active=&s;
    beginEditingOnNodeLocked(s, node(107,7,"A"));
    int64_t ctx=s.editingContextId;
    s.acceptedPaintTicketId=6; s.acceptedProjectionVersion=6; s.accepted.clear();
    syncEditingBufferAfterAcceptedSceneLocked(&s);
    if (s.editingContextLive || !s.editorRetired) return 62;
    if (!queueHas(s, ctx)) return 63;
  }
  // 6c. 当前来源同 id 换 epoch：ABA 撤销立即生效。
  {
    Session s; active=&s;
    beginEditingOnNodeLocked(s, node(107,7,"A"));
    int64_t ctx=s.editingContextId;
    s.acceptedPaintTicketId=6; s.acceptedProjectionVersion=6;
    s.accepted.push_back(node(107,99,"A"));
    syncEditingBufferAfterAcceptedSceneLocked(&s);
    if (s.editingContextLive || !queueHas(s, ctx)) return 64;
  }
  // 6d. 判别点：版本回退的当前来源提交，缺席仍立即退役——任何阈值宽限的
  // 重新引入都会在这里翻红。
  {
    Session s; active=&s;
    beginEditingOnNodeLocked(s, node(107,7,"A",5));
    s.acceptedPaintTicketId=6; s.acceptedProjectionVersion=3; s.accepted.clear();
    syncEditingBufferAfterAcceptedSceneLocked(&s);
    if (s.editingContextLive) return 65;
  }
  // 7. 外部换版重建：上下文轮换、正文更新；随后同值当前来源提交（本地连续
  // 准入）不重建、不退役。
  {
    Session s; active=&s;
    beginEditingOnNodeLocked(s, node(107,7,"A"));
    int64_t first=s.editingContextId;
    s.acceptedPaintTicketId=6; s.acceptedProjectionVersion=7;
    SceneNode external = node(107,7,"A",7); external.value="xyz";
    s.accepted.push_back(external);
    syncEditingBufferAfterAcceptedSceneLocked(&s);
    if (!s.editingContextLive || s.editingContextId==first) return 70;
    if (s.editingText != utf8ToUtf16("xyz")) return 72;
    int64_t rebuilt=s.editingContextId;
    syncEditingBufferAfterAcceptedSceneLocked(&s);  // 同值同版：无变化
    if (!s.editingContextLive || s.editingContextId!=rebuilt || !s.pendingEnds.empty()) return 71;
  }
  // 8. A1/D2：owned 会话节点（**普通 owned INPUT**，nodeKind=10 可编辑）声明缺失时，
  //    begin 必须**关闭输入准入**并保留缓冲——不是只停发焦点通知。
  {
    Session s; active=&s;
    s.ownedTextSessionEnabled=true;
    s.ownedTextSessionNodeId=313; s.ownedTextSessionResourceId=313;
    s.ownedTextSessionNodeKind=10; s.ownedTextSessionBindingEpoch=8;
    s.ownedMirrorAccepted.valid=false;          // 声明缺失
    s.editingText = utf8ToUtf16("KEEP");
    SceneNode owned = node(313,8,"note"); owned.pod.resourceId=313; owned.value="";
    beginEditingOnNodeLocked(s, owned);
    // 旧实现：live 仍为 true（已分配新 ctx 却把输入门留着），且缓冲被空 carrier 覆盖。
    if (s.editingContextLive) return 80;
    if (s.focusNotifyPending) return 81;
    if (s.editingText != utf8ToUtf16("KEEP")) return 82;
  }
  // 8b. 正控：声明有效且属于当前绑定 ⇒ 播种镜像文本、准入保持开启。
  {
    Session s; active=&s;
    s.ownedTextSessionEnabled=true;
    s.ownedTextSessionNodeId=313; s.ownedTextSessionResourceId=313;
    s.ownedTextSessionNodeKind=10; s.ownedTextSessionBindingEpoch=8;
    s.ownedMirrorAccepted.valid=true; s.ownedMirrorAccepted.text=utf8ToUtf16("note-text");
    s.ownedMirrorAccepted.ownerContentVersion=5; s.ownedMirrorAccepted.bindingEpoch=8;
    s.ownedMirrorAccepted.declaredBindingEpoch=8;
    SceneNode owned = node(313,8,"note"); owned.pod.resourceId=313; owned.value="";
    beginEditingOnNodeLocked(s, owned);
    if (!s.editingContextLive) return 83;
    if (s.editingText != utf8ToUtf16("note-text")) return 84;
  }
  // 8c. 换绑代差（声明代 ≠ 当前绑定代）同样走具名等待，不得借用旧声明。
  {
    Session s; active=&s;
    s.ownedTextSessionEnabled=true;
    s.ownedTextSessionNodeId=313; s.ownedTextSessionResourceId=313;
    s.ownedTextSessionNodeKind=10; s.ownedTextSessionBindingEpoch=9;
    s.ownedMirrorAccepted.valid=true; s.ownedMirrorAccepted.text=utf8ToUtf16("old");
    s.ownedMirrorAccepted.bindingEpoch=8; s.ownedMirrorAccepted.declaredBindingEpoch=8;
    s.editingText = utf8ToUtf16("KEEP");
    SceneNode owned = node(313,9,"note"); owned.pod.resourceId=313; owned.value="";
    beginEditingOnNodeLocked(s, owned);
    if (s.editingContextLive) return 85;
    if (s.editingText != utf8ToUtf16("KEEP")) return 86;
  }
  // 8d. sync 侧同一条规则：普通 owned INPUT 声明缺失时保留 ctx 号、关闭准入，
  //    **不得**重建 editingContextId（旧实现把它当外部换版 → ctx16→17）。
  {
    Session s; active=&s;
    s.ownedTextSessionEnabled=true;
    s.ownedTextSessionNodeId=313; s.ownedTextSessionResourceId=313;
    s.ownedTextSessionNodeKind=10; s.ownedTextSessionBindingEpoch=8;
    s.ownedMirrorAccepted.valid=false;
    beginEditingOnNodeLocked(s, node(190,7,"body"));   // 先在别处建立上下文
    int64_t before=s.editingContextId;
    s.editingNodeId=313; s.editingResourceId=313; s.editingNodeKind=10;
    s.editingAcceptedBindingEpoch=8; s.editingContextLive=true; s.editorRetired=false;
    // semanticId 必须一并对齐：否则 sync 在完整绑定门（semanticId 比较）就
    // 走 S2 kill 分支——它同样把 live 置 false 且不动 ctx/缓冲，会让本例在
    // **任何**实现下都通过（伪绿）。对齐后才真正走到镜像声明判据。
    s.editingFieldName="note";
    s.editingText = utf8ToUtf16("KEEP");
    s.acceptedProjectionVersion=9;
    SceneNode owned = node(313,8,"note",9); owned.pod.resourceId=313;
    s.accepted.clear(); s.accepted.push_back(owned);
    syncEditingBufferAfterAcceptedSceneLocked(&s);
    if (s.editingContextLive) return 87;
    if (s.editingContextId != before) return 88;
    if (s.editingText != utf8ToUtf16("KEEP")) return 89;
  }
  // 9. 指导 RED-1（native-probe.cpp seed(10)）：普通 owned INPUT，同 owner
  //    刷新（scene29→30，ownerVersion 不变）必须保 ctx16，不得换号。
  {
    Session s; active=&s;
    s.editing=true; s.editingContextLive=true;
    s.editingNodeId=313; s.editingResourceId=1; s.editingNodeKind=10;
    s.editingFieldName="note"; s.editingAcceptedBindingEpoch=4;
    s.editingContextId=16; s.editingContextBaseVersion=29; s.editingProjectionVersion=29;
    s.editingText=utf8ToUtf16("abc"); s.editingMirrorOwnerVersion=1;
    s.ownedTextSessionEnabled=true;
    s.ownedTextSessionNodeId=313; s.ownedTextSessionResourceId=1; s.ownedTextSessionNodeKind=10;
    s.ownedTextSessionBindingEpoch=8;
    s.ownedMirrorAccepted.valid=true; s.ownedMirrorAccepted.declaredBindingEpoch=8;
    s.ownedMirrorAccepted.bindingEpoch=4; s.ownedMirrorAccepted.text=utf8ToUtf16("abc");
    s.ownedMirrorAccepted.ownerContentVersion=1;
    SceneNode n = node(313,4,"note",30); n.pod.resourceId=1;
    s.accepted.clear(); s.accepted.push_back(n);
    s.acceptedProjectionVersion=30;
    syncEditingBufferAfterAcceptedSceneLocked(&s);
    if (s.editingContextId != 16) return 90;
    if (!s.editingContextLive) return 91;
  }
  // 10. 指导 RED-2（native-probe.cpp seed(1)+ownerVersion=2）：presentation
  //     同字节外部新版本必须退役旧 ctx，不得保号。
  {
    Session s; active=&s;
    s.editing=true; s.editingContextLive=true;
    s.editingNodeId=313; s.editingResourceId=1; s.editingNodeKind=1;
    s.editingFieldName="note"; s.editingAcceptedBindingEpoch=4;
    s.editingContextId=16; s.editingContextBaseVersion=29; s.editingProjectionVersion=29;
    s.editingText=utf8ToUtf16("abc"); s.editingMirrorOwnerVersion=1;
    s.ownedTextSessionEnabled=true;
    s.ownedTextSessionNodeId=313; s.ownedTextSessionResourceId=1; s.ownedTextSessionNodeKind=1;
    s.ownedTextSessionBindingEpoch=8;
    s.ownedMirrorAccepted.valid=true; s.ownedMirrorAccepted.declaredBindingEpoch=8;
    s.ownedMirrorAccepted.bindingEpoch=4; s.ownedMirrorAccepted.text=utf8ToUtf16("abc");
    s.ownedMirrorAccepted.ownerContentVersion=2;
    SceneNode n = node(313,4,"note",30); n.pod.resourceId=1; n.pod.nodeKind=1;
    s.accepted.clear(); s.accepted.push_back(n);
    s.acceptedProjectionVersion=30;
    syncEditingBufferAfterAcceptedSceneLocked(&s);
    if (s.editingContextId == 16) return 92;
  }
  // 11. 设备实测（visual-edit-conv-final3）：presentation 锚点的本地接受
  //     （窗口暂存 preservesActiveLocalText 凭据 + 镜像带回同一段编辑缓冲）
  //     必须保 ctx 并认领声明推进；下一帧凭据已清，纯几何投影用已认领
  //     版本继续保 ctx（旧实现：接受推进无凭据识别 → reconcile，光标丢到
  //     文末，随后输入落错位置）。
  {
    Session s; active=&s;
    s.editing=true; s.editingContextLive=true;
    s.editingNodeId=313; s.editingResourceId=1; s.editingNodeKind=1;
    s.editingFieldName="body"; s.editingAcceptedBindingEpoch=4;
    s.editingContextId=16; s.editingContextBaseVersion=29; s.editingProjectionVersion=29;
    s.editingText=utf8ToUtf16("abc"); s.editingMirrorOwnerVersion=1;
    s.ownedTextSessionEnabled=true;
    s.ownedTextSessionNodeId=313; s.ownedTextSessionResourceId=1; s.ownedTextSessionNodeKind=1;
    s.ownedTextSessionBindingEpoch=8;
    s.ownedMirrorAccepted.valid=true; s.ownedMirrorAccepted.declaredBindingEpoch=8;
    s.ownedMirrorAccepted.bindingEpoch=4; s.ownedMirrorAccepted.text=utf8ToUtf16("abc");
    s.ownedMirrorAccepted.ownerContentVersion=2;
    SceneNode n = node(313,4,"body",30); n.pod.resourceId=1; n.pod.nodeKind=1;
    n.pod.preservesActiveLocalText=1;
    s.accepted.clear(); s.accepted.push_back(n);
    s.acceptedProjectionVersion=30;
    syncEditingBufferAfterAcceptedSceneLocked(&s);
    if (s.editingContextId != 16) return 93;
    if (!s.editingContextLive) return 94;
    if (s.editingMirrorOwnerVersion != 2) return 95;
    s.accepted[0].pod.projectionVersion=31;
    s.accepted[0].pod.preservesActiveLocalText=0;
    s.acceptedProjectionVersion=31;
    syncEditingBufferAfterAcceptedSceneLocked(&s);
    if (s.editingContextId != 16) return 96;
    if (!s.editingContextLive) return 97;
  }
  // 12. 同一身份规则覆盖普通 owned INPUT（可编辑 kind）：本地接受凭据 +
  //     声明推进 ⇒ 保 ctx 并认领；下一帧凭据已清仍用已认领版本保 ctx。
  {
    Session s; active=&s;
    s.editing=true; s.editingContextLive=true;
    s.editingNodeId=313; s.editingResourceId=1; s.editingNodeKind=10;
    s.editingFieldName="note"; s.editingAcceptedBindingEpoch=4;
    s.editingContextId=16; s.editingContextBaseVersion=29; s.editingProjectionVersion=29;
    s.editingText=utf8ToUtf16("abc"); s.editingMirrorOwnerVersion=1;
    s.ownedTextSessionEnabled=true;
    s.ownedTextSessionNodeId=313; s.ownedTextSessionResourceId=1; s.ownedTextSessionNodeKind=10;
    s.ownedTextSessionBindingEpoch=8;
    s.ownedMirrorAccepted.valid=true; s.ownedMirrorAccepted.declaredBindingEpoch=8;
    s.ownedMirrorAccepted.bindingEpoch=4; s.ownedMirrorAccepted.text=utf8ToUtf16("abc");
    s.ownedMirrorAccepted.ownerContentVersion=2;
    SceneNode n = node(313,4,"note",30); n.pod.resourceId=1;
    n.pod.preservesActiveLocalText=1;
    s.accepted.clear(); s.accepted.push_back(n);
    s.acceptedProjectionVersion=30;
    syncEditingBufferAfterAcceptedSceneLocked(&s);
    if (s.editingContextId != 16) return 98;
    if (!s.editingContextLive) return 99;
    if (s.editingMirrorOwnerVersion != 2) return 100;
    s.accepted[0].pod.projectionVersion=31;
    s.accepted[0].pod.preservesActiveLocalText=0;
    s.acceptedProjectionVersion=31;
    syncEditingBufferAfterAcceptedSceneLocked(&s);
    if (s.editingContextId != 16) return 101;
  }
  std::cout << "ok\n";
  return 0;
}
'''


def harness(source):
    parts = [PREFIX]
    for key in ('mirror_decl', 'push_end', 'take', 'begin', 'finish', 'healthy', 'retire', 'sync'):
        parts.append(extract_method(source, SIGNATURES[key]))
    return '\n'.join(parts) + '\n' + MAIN


class S2IdentityHandoffNativeTest(unittest.TestCase):
    def run_source(self, source):
        with tempfile.TemporaryDirectory() as tmp:
            p = pathlib.Path(tmp)
            cpp = p / 'identity.cpp'
            cpp.write_text(harness(source))
            exe = p / 'identity'
            q = subprocess.run(['clang++', '-std=c++17', '-Wall', '-Wextra', '-Werror',
                                str(cpp), '-o', str(exe)], capture_output=True, text=True)
            self.assertEqual(q.returncode, 0, q.stderr)
            return subprocess.run([str(exe)], capture_output=True, text=True).returncode

    def test_identity_source_and_lineage_gates(self):
        self.assertEqual(self.run_source(SOURCE.read_text()), 0)

    def test_negative_retire_ignores_binding_epoch(self):
        source = SOURCE.read_text()
        # 弱化变异：健康判据丢掉 bindingEpoch 比较——6a-4 的 ABA 退役立即翻红。
        broken = source.replace(
            'n.pod.nodeKind == s.editingNodeKind &&\n'
            '            n.pod.acceptedBindingEpoch == s.editingAcceptedBindingEpoch) {',
            'n.pod.nodeKind == s.editingNodeKind) {')
        self.assertNotEqual(broken, source)
        self.assertNotEqual(self.run_source(broken), 0)

    def test_negative_retire_ignores_readonly(self):
        source = SOURCE.read_text()
        # 弱化变异：丢掉只读判定——6a-3 翻红。
        broken = source.replace('n.pod.isInteractive != 0 && n.pod.isReadOnly == 0;',
                                'n.pod.isInteractive != 0;')
        self.assertNotEqual(broken, source)
        self.assertNotEqual(self.run_source(broken), 0)

    def test_negative_version_threshold_grace_reintroduced(self):
        source = SOURCE.read_text()
        anchor = 'static void syncEditingBufferAfterAcceptedSceneLocked(Session *s)\n{\n    if (!s->editing) return;\n'
        assert anchor in source
        broken = source.replace(anchor, anchor +
            '    if (s->acceptedPaintTicketId < 1000000) { return; }\n', 1)
        self.assertNotEqual(broken, source)
        self.assertNotEqual(self.run_source(broken), 0)

    def test_negative_idempotency_without_epoch(self):
        source = SOURCE.read_text()
        broken = source.replace(
            's.editingFieldName == node.semanticId &&\n'
            '        s.editingAcceptedBindingEpoch == node.pod.acceptedBindingEpoch;',
            's.editingFieldName == node.semanticId;')
        self.assertNotEqual(broken, source)
        self.assertNotEqual(self.run_source(broken), 0)

    def test_negative_finish_without_frozen_identity(self):
        source = SOURCE.read_text()
        broken = source.replace(
            'pushPendingEndLocked(*s, contextId, s->editingFieldName, false);\n'
            '    cancelProxyRestoreRequest(*s, "finished");',
            'cancelProxyRestoreRequest(*s, "finished");')
        self.assertNotEqual(broken, source)
        self.assertNotEqual(self.run_source(broken), 0)

    # ---- A1/D2：owned 缺声明门必须关输入准入，且普通 owned INPUT 同样消费 ----

    BEGIN_GUARD = ('        } else if (s.ownedTextSessionEnabled &&\n'
                   '                   node.pod.nodeId == s.ownedTextSessionNodeId &&\n'
                   '                   node.pod.resourceId == s.ownedTextSessionResourceId &&\n'
                   '                   node.pod.nodeKind == s.ownedTextSessionNodeKind) {')
    BEGIN_CLOSE = ('            s.editingContextLive = false;\n'
                   '            s.focusNotifyPending = false;\n'
                   '            return;')
    SYNC_GUARD = ('        } else if (s->ownedTextSessionEnabled &&\n'
                  '                   n.pod.nodeId == s->ownedTextSessionNodeId &&\n'
                  '                   n.pod.resourceId == s->ownedTextSessionResourceId &&\n'
                  '                   n.pod.nodeKind == s->ownedTextSessionNodeKind) {')

    def test_negative_missing_declaration_keeps_input_gate_open(self):
        source = SOURCE.read_text()
        assert self.BEGIN_CLOSE in source
        # 只停通知、不关输入准入（旧实现）：8 立刻翻红。
        broken = source.replace(self.BEGIN_CLOSE,
                                '            s.focusNotifyPending = false;\n'
                                '            return;')
        self.assertNotEqual(broken, source)
        self.assertNotEqual(self.run_source(broken), 0)

    def test_negative_missing_declaration_gate_excludes_plain_input(self):
        source = SOURCE.read_text()
        assert self.BEGIN_GUARD in source
        # 把门重新限定为 presentation 锚点（`!isEditableTextKind`）：普通 owned
        # INPUT 落不到具名等待，被当外部值播种并留下开着的输入门 ⇒ 8 翻红。
        broken = source.replace(
            self.BEGIN_GUARD,
            '        } else if (!isEditableTextKind(node.pod.nodeKind) &&\n'
            '                   s.ownedTextSessionEnabled &&\n'
            '                   node.pod.nodeId == s.ownedTextSessionNodeId &&\n'
            '                   node.pod.resourceId == s.ownedTextSessionResourceId &&\n'
            '                   node.pod.nodeKind == s.ownedTextSessionNodeKind) {')
        self.assertNotEqual(broken, source)
        self.assertNotEqual(self.run_source(broken), 0)

    def test_negative_sync_gate_excludes_plain_input(self):
        source = SOURCE.read_text()
        assert self.SYNC_GUARD in source
        # sync 侧退回"只比 nodeId 且排除可编辑 kind"：普通 owned INPUT 声明缺失
        # 时不再具名等待，被误判为外部换版并重建 ctx（实测 ctx16→17）⇒ 8d 翻红。
        broken = source.replace(
            self.SYNC_GUARD,
            '        } else if (!isEditableTextKind(n.pod.nodeKind) && s->ownedTextSessionEnabled &&\n'
            '                   n.pod.nodeId == s->ownedTextSessionNodeId) {')
        self.assertNotEqual(broken, source)
        self.assertNotEqual(self.run_source(broken), 0)

    def test_negative_local_accept_claim_removed(self):
        source = SOURCE.read_text()
        # 设备反例（visual-edit-conv-final3）：本地接受推进不被认领——下一帧
        # 纯几何投影按版本滞后把合法推进当外部换版重建 ctx（11/12 翻红）。
        anchor_claim = 's->editingMirrorOwnerVersion = syncMirror->ownerContentVersion;'
        self.assertEqual(source.count(anchor_claim), 2)
        broken = source.replace(anchor_claim, '/* claim removed */')
        generic = ('            if (const Session::OwnedMirrorDeclaration *claimMirror = ownedMirrorDeclarationLocked(*s,\n'
                   '                n.pod.nodeId, n.pod.resourceId, n.pod.nodeKind)) {\n'
                   '                s->editingMirrorOwnerVersion = claimMirror->ownerContentVersion;\n'
                   '            }\n')
        self.assertIn(generic, broken)
        broken = broken.replace(generic, '')
        self.assertNotEqual(broken, source)
        self.assertNotEqual(self.run_source(broken), 0)


if __name__ == '__main__':
    unittest.main()

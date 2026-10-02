#!/usr/bin/env python3
"""R1 回归（h-source-preview-followup 2026-10-02 补轮）：提交来源准入、完整
绑定身份与全部收场入口的旧身份冻结。

抽取 ohos_renderer.cpp 的真实生产函数（beginEditingOnNodeLocked /
pushPendingEndLocked / takeEditingContextLocked /
ohos_renderer_ime_finish_editing_ctx / pendingSettlementSourceStaleLocked /
syncEditingBufferAfterAcceptedSceneLocked），在宿主 clang++ 下断言：

  * 正控：begin(A)→begin(B)，待发 end 属于旧 A；
  * finish(A=13)→bind(B=14)：end 仍属 13/A（finish 也是收场入口）；
  * 同 id 换 epoch / 换 semantic / 换 kind：完整绑定身份判定，必须换上下文；
  * 完整绑定幂等：同身份重复聚焦不换号、不排队 end；
  * **提交来源（R1补轮）**：来源过期候选在结算入口按**来源上下文比较**整票
    拒绝（present 锁内冻结来源，结算时存在另一个活上下文 = 旧来源结果）——
    票号大小不构成来源关系证明；sync 只在当前来源提交上运行，**没有任何
    宽限**：缺席/失配/版本回退的当前来源提交都是真实撤销，首次发布立即退役。
    可达性（真实串行路径）：present 在锁内冻结候选与来源后解锁等待渲染 job；
    此窗口内 UI 线程可 begin(B)（同一把 g_sessions.lock 串行），job 完成返回
    PENDING 后 owner 结算——「present(来源A) → begin(B) → settle」在现有
    提交入口上串行可达，无需乱序假设。

变异负控证明判别力：来源比较恒假 / 换回版本阈值宽限 / 去掉 epoch 比较 /
去掉 finish 冻结，同一二进制必须失败。
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
    'stale': 'static bool pendingSettlementSourceStaleLocked(',
    'sync': 'static void syncEditingBufferAfterAcceptedSceneLocked(Session *s)\n',
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
  uint64_t nodeId=0, resourceId=0, nodeKind=10, projectionVersion=5,
    acceptedBindingEpoch=7, preservesActiveLocalText=0;
  uint32_t isReadOnly=0, isInteractive=1;
};
struct SceneNode { Pod pod; std::string semanticId, value; };
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
  uint64_t editingNodeId=0, editingResourceId=0, editingNodeKind=0,
           editingProjectionVersion=0, editingAcceptedBindingEpoch=0,
           editingContextGeneration=0, editingContextBaseVersion=0,
           surfaceGeneration=1, acceptedPaintTicketId=5, acceptedProjectionVersion=5;
  int64_t editingContextId=0, reconcileOldContextId=0;
  uint32_t caretAffinity=0, caretUtf16=0, selStartUtf16=0, selEndUtf16=0,
           selPlatformStart=0, selPlatformEnd=0, markedStart=0, markedEnd=0,
           textMenuIntent=0;
  std::string editingFieldName;
  std::u16string editingText, previewText;
  std::vector<SceneNode> accepted;
};
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
bool editorOwnsTextSession(Session &) {return false;}
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
    if (ohos_renderer_ime_finish_editing_ctx(9999)!=1) return 50;
    if (!st.pendingEnds.empty()) return 51;
  }
  // 6. 提交来源（R1补轮）：来源上下文比较在结算入口拒绝旧来源候选。
  {
    Session s; active=&s;
    beginEditingOnNodeLocked(s, node(107,7,"A"));
    int64_t ctxA=s.editingContextId;
    // 6a-1 同一上下文仍活着：候选是当前来源，不拒。
    PendingSettlement current; current.sourceEditingLive=true;
    current.sourceEditingContextId=ctxA;
    if (pendingSettlementSourceStaleLocked(s,current)) return 60;
    // 6a-2 present(来源A) 后 UI 线程 begin(B)（同一锁串行可达），结算时活
    // 上下文已是 B：旧来源候选必须判为陈旧——不可逆晋升前整票拒绝。
    beginEditingOnNodeLocked(s, node(313,8,"B"));
    if (s.editingContextId==ctxA) return 61;
    if (!pendingSettlementSourceStaleLocked(s,current)) return 62;
    // 6a-3 结算时上下文已退役（无活上下文）：无对象可保护，不拒（sync 随后
    // 按 !editing 直接返回）。
    s.editingContextLive=false;
    if (pendingSettlementSourceStaleLocked(s,current)) return 63;
    // 6a-4 候选冻结时无活上下文、结算时 B 活着：不是"旧来源"（没有来源可
    // 换），允许提交——若树缺节点即 owner 真实删除，sync 立即退役 B。
    PendingSettlement orphan; orphan.sourceEditingLive=false;
    orphan.sourceEditingContextId=0;
    s.editingContextLive=true;
    if (pendingSettlementSourceStaleLocked(s,orphan)) return 64;
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
  std::cout << "ok\n";
  return 0;
}
'''


def harness(source):
    parts = [PREFIX]
    for key in ('push_end', 'take', 'begin', 'finish', 'stale', 'sync'):
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

    def test_negative_stale_check_disabled(self):
        source = SOURCE.read_text()
        # 弱化变异：丢掉上下文比较（两个参数仍被使用，可编译）——6a-1 的
        # "同上下文不拒"立即翻红。
        broken = source.replace(
            'return s.editingContextLive && p.sourceEditingLive &&\n'
            '        s.editingContextId != p.sourceEditingContextId;',
            'return s.editingContextLive && p.sourceEditingLive;')
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


if __name__ == '__main__':
    unittest.main()

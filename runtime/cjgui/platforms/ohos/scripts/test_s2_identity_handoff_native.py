#!/usr/bin/env python3
"""R1 回归（h-source-preview-followup 2026-10-02）：提交来源、完整绑定身份与
全部收场入口的旧身份冻结。

抽取 ohos_renderer.cpp 的真实生产函数（beginEditingOnNodeLocked /
pushPendingEndLocked / takeEditingContextLocked /
ohos_renderer_ime_finish_editing_ctx / syncEditingBufferAfterAcceptedSceneLocked），
在宿主 clang++ 下断言（2026-10-02 指导复核的生产反例）：
  * 正控：begin(A)→begin(B)，待发 end 属于旧 A；
  * finish(A=13)→bind(B=14)：end 仍属 13/A——finish 也是收场入口，冻结将死
    身份，不得让投递端回读"当前"上下文；
  * 同 id 换 epoch（7→99）：不是同一绑定——必须换上下文并按完整身份
    （node/resource/kind/semantic/epoch）判定幂等；
  * 完整绑定幂等：同身份重复聚焦不换号、不排队 end；
  * 提交来源准入：结算票据 < 绑定出生票据的缺席/失配是旧模式结果，不杀
    上下文；出生票据之后的提交才可裁决撤销（票据 lineage 替代被 Astra 否定
    的 projectionVersion 阈值宽限——版本回退的提交只要是绑定后投递就必须
    仍能 kill，这是与旧实现的判别点）。

变异负控证明本测试可判别原缺陷：去掉 epoch 比较 / 换回版本阈值 / 去掉
finish 冻结，同一二进制必须失败。
"""
import pathlib
import subprocess
import tempfile
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]
SOURCE = ROOT / "host" / "ohos_renderer.cpp"


def extract_method(text, signature_start):
    """按列 0 的右花括号提取整个函数（多行签名安全）。"""
    start = text.index(signature_start)
    end = text.index("\n}\n", start) + 3
    return text[start:end]


SIGNATURES = {
    'begin': 'void beginEditingOnNodeLocked(Session &s, const SceneNode &node)\n',
    'push_end': 'static void pushPendingEndLocked(',
    'take': 'static Session *takeEditingContextLocked(int64_t contextId)\n',
    'finish': 'extern "C" int32_t ohos_renderer_ime_finish_editing_ctx(int64_t contextId)\n',
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
           surfaceGeneration=1, acceptedPaintTicketId=5, acceptedProjectionVersion=5,
           editingBornTicketId=0;
  int64_t editingContextId=0, reconcileOldContextId=0;
  uint32_t caretAffinity=0, caretUtf16=0, selStartUtf16=0, selEndUtf16=0,
           selPlatformStart=0, selPlatformEnd=0, markedStart=0, markedEnd=0,
           textMenuIntent=0;
  std::string editingFieldName;
  std::u16string editingText, previewText;
  std::vector<SceneNode> accepted;
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
  // 2. finish(A=13)→bind(B=14)：end 必须仍属 A（生产反例：曾误寄 14/B）。
  {
    Session s; active=&s;
    beginEditingOnNodeLocked(s, node(107,7,"A"));
    int64_t oldCtx=s.editingContextId;
    if (ohos_renderer_ime_finish_editing_ctx(oldCtx)!=0) return 20;
    beginEditingOnNodeLocked(s, node(313,8,"B"));
    int64_t newCtx=s.editingContextId;
    if (newCtx==oldCtx) return 21;
    if (!queueHas(s, oldCtx)) return 22;      // A 的收场通知仍在
    if (queueHas(s, newCtx)) return 23;       // 不得误寄新身份
    if (s.pendingEnds.front().fieldName!="A") return 24;
  }
  // 3. 同 id 换 epoch（7→99）：完整身份幂等——必须换上下文（生产反例：曾复用
    // context15/binding7）。
  {
    Session aba; active=&aba;
    beginEditingOnNodeLocked(aba, node(107,7,"A"));
    int64_t abaOld=aba.editingContextId;
    SceneNode rebound = node(107,99,"A");
    beginEditingOnNodeLocked(aba, rebound);
    if (aba.editingContextId==abaOld) return 30;
    if (aba.editingAcceptedBindingEpoch!=99) return 31;
    if (!queueHas(aba, abaOld)) return 32;    // 旧身份退场
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
  // 6. 提交来源准入（票据 lineage）：
  // 6a. 结算票据 < 出生票据：缺席是旧模式结果，不杀。
  {
    Session s; active=&s;
    beginEditingOnNodeLocked(s, node(107,7,"A"));  // born = acceptedPaintTicketId = 5
    if (s.editingBornTicketId!=5) return 60;
    s.acceptedPaintTicketId=4; s.acceptedProjectionVersion=4; s.accepted.clear();
    syncEditingBufferAfterAcceptedSceneLocked(&s);
    if (!s.editingContextLive || s.editorRetired || !s.pendingEnds.empty()) return 61;
  }
  // 6b. 出生票据之后的提交缺席：真实移除，立即收场并冻结身份。
  {
    Session s; active=&s;
    beginEditingOnNodeLocked(s, node(107,7,"A"));
    int64_t ctx=s.editingContextId;
    s.acceptedPaintTicketId=6; s.acceptedProjectionVersion=6; s.accepted.clear();
    syncEditingBufferAfterAcceptedSceneLocked(&s);
    if (s.editingContextLive || !s.editorRetired) return 62;
    if (!queueHas(s, ctx)) return 63;
  }
  // 6c. 出生票据之后同 id 换 epoch：ABA 撤销立即生效。
  {
    Session s; active=&s;
    beginEditingOnNodeLocked(s, node(107,7,"A"));
    int64_t ctx=s.editingContextId;
    s.acceptedPaintTicketId=6; s.acceptedProjectionVersion=6;
    s.accepted.push_back(node(107,99,"A"));
    syncEditingBufferAfterAcceptedSceneLocked(&s);
    if (s.editingContextLive || !queueHas(s, ctx)) return 64;
  }
  // 6d. 判别点：版本回退的提交只要是绑定**之后**投递（票据 >= 出生票据），
  // 缺席仍是真实撤销——版本阈值宽限（旧实现）会把它错误容忍。
  {
    Session s; active=&s;
    beginEditingOnNodeLocked(s, node(107,7,"A",5));  // base=5, born=5
    s.acceptedPaintTicketId=6; s.acceptedProjectionVersion=3; s.accepted.clear();
    syncEditingBufferAfterAcceptedSceneLocked(&s);
    if (s.editingContextLive) return 65;
  }
  // 7. 外部换版重建的上下文以本张结算票据为出生票据；更旧迟到结算不杀它。
  {
    Session s; active=&s;
    beginEditingOnNodeLocked(s, node(107,7,"A"));
    s.acceptedPaintTicketId=6; s.acceptedProjectionVersion=7;
    SceneNode external = node(107,7,"A",7); external.value="xyz";  // 外部换版
    s.accepted.push_back(external);
    syncEditingBufferAfterAcceptedSceneLocked(&s);   // 换版 → 重建，born=6
    if (!s.editingContextLive || s.editingBornTicketId!=6) return 70;
    if (s.editingText != utf8ToUtf16("xyz")) return 72;
    int64_t rebuilt=s.editingContextId;
    s.acceptedPaintTicketId=5; s.acceptedProjectionVersion=5; s.accepted.clear();
    syncEditingBufferAfterAcceptedSceneLocked(&s);
    if (!s.editingContextLive || !s.pendingEnds.empty()) return 71;
    (void)rebuilt;
  }
  std::cout << "ok\n";
  return 0;
}
'''


def harness(source):
    parts = [PREFIX]
    for key in ('push_end', 'take', 'begin', 'finish', 'sync'):
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

    def test_identity_and_lineage_gates(self):
        self.assertEqual(self.run_source(SOURCE.read_text()), 0)

    def test_negative_idempotency_without_epoch(self):
        source = SOURCE.read_text()
        broken = source.replace(
            's.editingFieldName == node.semanticId &&\n'
            '        s.editingAcceptedBindingEpoch == node.pod.acceptedBindingEpoch;',
            's.editingFieldName == node.semanticId;')
        self.assertNotEqual(broken, source)
        self.assertNotEqual(self.run_source(broken), 0)

    def test_negative_lineage_replaced_by_version_threshold(self):
        source = SOURCE.read_text()
        broken = source.replace(
            'if (s->acceptedPaintTicketId < s->editingBornTicketId) {',
            'if (s->acceptedProjectionVersion < s->editingContextBaseVersion) {')
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

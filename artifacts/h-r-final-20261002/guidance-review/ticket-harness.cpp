
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

static void pushPendingEndLocked(Session &s, int64_t contextId, const std::string &fieldName,
                                  bool settleOnDelivery)
{
    // 同一上下文的重复收场（多入口先后到达）只保留首条：结算语义恰好一次，
    // end 通知也只发一次。
    for (const Session::PendingEnd &e : s.pendingEnds) {
        if (e.contextId == contextId) return;
    }
    Session::PendingEnd entry;
    entry.contextId = contextId;
    entry.fieldName = fieldName;
    entry.settleOnDelivery = settleOnDelivery;
    s.pendingEnds.push_back(std::move(entry));
}

static Session *takeEditingContextLocked(int64_t contextId)
{
    Session *s = findEditingSessionLocked();
    if (!s || !s->editingContextLive) return nullptr;
    if (contextId != s->editingContextId) return nullptr;
    return s;
}

void beginEditingOnNodeLocked(Session &s, const SceneNode &node)
{
    const uint32_t kind = node.pod.nodeKind;
    const bool wasEditing = s.editing && !s.editorRetired && s.editingNodeId == node.pod.nodeId;
    // R1（Astra s2-identity-handoff）：幂等与换绑都按**完整绑定身份**判定
    // （node/resource/kind/semantic/acceptedBindingEpoch）。只比 node/resource
    // 会让「同 id 换 epoch（对象重声明）」复用旧上下文与旧绑定（离线反例：
    // epoch 7→99 仍 context15/binding7）——同值同号不是同一对象。
    const bool sameBindingAsBefore = s.editingNodeId == node.pod.nodeId &&
        s.editingResourceId == node.pod.resourceId &&
        s.editingNodeKind == node.pod.nodeKind &&
        s.editingFieldName == node.semanticId &&
        s.editingAcceptedBindingEpoch == node.pod.acceptedBindingEpoch;
    // 仅 node/resource 相等（不含 epoch/kind/semantic）的历史语义：局部缓冲延续
    // 与选区保持只在**同一对象**上允许，换 epoch 后不再沿用。
    const bool sameNodeAsBefore = s.editingNodeId == node.pod.nodeId &&
        s.editingResourceId == node.pod.resourceId && sameBindingAsBefore;
    // C：同一有效绑定重复聚焦幂等——不换上下文编号，系统代理继续持旧编号，
    // 后续输入不会因换号被 stale 拒绝；caret 重定位由调用方按需触发。
    if (wasEditing && sameBindingAsBefore && s.editingContextLive) {
        return;
    }
    // 换绑/换焦：旧上下文号、旧字段与旧节点identity都要退场，旧恢复请求连同其
    // 待发正文/选区一并作废——否则"A 的恢复"会被贴到 B 的身份上。
    cancelProxyRestoreRequest(s, "rebind");
    clearHumanSelectionAnchorLocked(s);
    // C：跨字段/跨绑定切换——先按旧身份落实失焦语义（组合草稿折进缓冲并以旧
    // 身份交付 owner 恰好一次），再发布新上下文；旧编号从此失效（stale 拒绝），
    // 旧回调不可写入新字段。end 通知的身份在切换时冻结进待发队列，pump 不得
    // 读新字段。
    if (s.editing && !s.editorRetired && s.editingContextLive && !sameBindingAsBefore) {
        settleComposedBufferOnBlurLocked(s);
        pushPendingEndLocked(s, s.editingContextId, s.editingFieldName, false);
    }
    s.editing = true;
    s.editorRetired = false;          // 新交互：重新成为绘制方与回调接收方
    s.editingNodeId = node.pod.nodeId;
    s.editingResourceId = node.pod.resourceId;
    s.editingNodeKind = kind;
    s.editingProjectionVersion = node.pod.projectionVersion;
    s.editingAcceptedBindingEpoch = node.pod.acceptedBindingEpoch;
    // 通用编辑上下文：每次绑定新节点/同一节点重新聚焦都分配新编号，
    // 旧上下文的延迟回调（提交/预览/失焦）从此失效，不得改写新焦点。
    s.editingContextId = g_nextEditingContextId.fetch_add(1);
    s.caretBlinkResetPending = true;
    s.caretAffinity = 0;
    s.editingFieldName = node.semanticId;
    s.editingContextGeneration = s.surfaceGeneration;
    s.editingContextBaseVersion = node.pod.projectionVersion;
    // R1：绑定出生票据——健康 accepted 树（调用方来源）的提交票号。此后
    // 「结算票据 < 出生票据」的提交是绑定前的旧模式结果，不参与退役判定。
    s.editingBornTicketId = s.acceptedPaintTicketId;
    s.editingContextLive = true;
    s.editingContextRevealRequested = false;  // 新上下文重置 reveal 请求
    s.reconcileNotifyPending = false;
    s.reconcileOldContextId = 0;
    if (!wasEditing) {
        // 编辑缓冲从已接受场景值起步（外部值即起点）。
        // 例外：核心的「本地文字延续」窗口会把 native 值置空，并约定由
        // 原生编辑器绘制该节点的可见文本。此时 accepted 里的空值不是
        // 业务空值；同一节点刚提交过的本地缓冲仍然权威，用空值重置会
        // 让重新聚焦得到一个空字段。
        std::u16string ownerValue = utf8ToUtf16(node.value);
        // C：重新聚焦只从 accepted 规范值初始化——空就是空。保留本地
        // 缓冲的唯一条件是节点带延续旗标（owner 接受了本地编辑且处于
        // 延续窗口），不得由空值推断。
        if (sameNodeAsBefore && ownerValue.empty() && !s.editingText.empty()
            && node.pod.preservesActiveLocalText != 0) {
            RLOGW("ime refocus keeps local buffer: continuation window node=%{public}llu",
                  static_cast<long long>(node.pod.nodeId));
        } else {
            s.editingText = ownerValue;
        }
        // R3：**同一节点**重新聚焦时不得把选区重置成末尾 caret。切回源码、
        // 重新点正文、页面往返都会走这里；无条件重置正是"中段非空选区在双切换
        // 后折叠"的最根上来源（2026-10-01 实测：拖选后 ctx=1 为 [101,104)，
        // 重建会话后变 [104,104)）。按新正文长度收敛原选区并保持非空；只有
        // 换到**不同节点**、或新区间无法表达时才退化为末尾 caret。
        const uint32_t focusSize = static_cast<uint32_t>(s.editingText.size());
        bool keptSelection = false;
        if (sameNodeAsBefore && s.selEndUtf16 > s.selStartUtf16) {
            uint32_t keepStart = clampToCodePointBoundary(s.editingText,
                std::min(s.selStartUtf16, s.selEndUtf16));
            uint32_t keepEnd = clampToCodePointBoundary(s.editingText,
                std::max(s.selStartUtf16, s.selEndUtf16));
            if (keepStart > focusSize) keepStart = focusSize;
            if (keepEnd > focusSize) keepEnd = focusSize;
            if (keepEnd > keepStart) {
                s.caretUtf16 = keepEnd;
                s.selStartUtf16 = keepStart;
                s.selEndUtf16 = keepEnd;
                keptSelection = true;
                RLOGI("ime refocus keeps non-empty selection node=%{public}llu sel=%{public}u:%{public}u",
                      static_cast<long long>(node.pod.nodeId), keepStart, keepEnd);
            }
        }
        if (!keptSelection) {
            s.caretUtf16 = focusSize;
            s.selStartUtf16 = s.caretUtf16;
            s.selEndUtf16 = s.caretUtf16;
        }
        // 挂载时平台按上下文快照取初值，落点账本随之对齐：不给刚挂载的代理
        // 再推一条与快照重复的 caret 通知。
        s.selPlatformStart = s.selStartUtf16;
        s.selPlatformEnd = s.selEndUtf16;
        // 新上下文的第一条落点观测必须转发给窗口，即使它的值与旧上下文最后一次
        // 转发值相同：窗口需要"这个上下文已经装好落点"这条事实本身。
        s.selForwardedValid = false;
        s.previewActive = false;
        s.previewText.clear();
        s.focusNotifyPending = true;   // ArkTS TextInput 代理路径
    }
}

extern "C" int32_t ohos_renderer_ime_finish_editing_ctx(int64_t contextId)
{
    std::lock_guard<std::mutex> g(g_sessions.lock);
    Session *s = takeEditingContextLocked(contextId);
    if (!s) {
        RLOGW("ime finish rejected: stale context=%{public}lld", static_cast<long long>(contextId));
        return 1;
    }
    RLOGI("ime finish ctx=%{public}lld", static_cast<long long>(contextId));
    s->editingContextLive = false;
    s->editorRetired = true;           // 逻辑结束；绘制与 accepted 同步保留到下次聚焦
    s->previewActive = false;
    s->previewText.clear();
    s->markedActive = false;
    // R1（生产反例 finish(A=13)→bind(B=14)）：finish 也是收场入口，必须在此
    // 冻结将死身份。此前不冻结，pump 回读"当前"上下文——finish 后再绑定 B 时
    // end 会误寄 14/B，A 的代理永远收不到收场通知。
    // 平台已提交，不再重复结算（settle=false）。
    pushPendingEndLocked(*s, contextId, s->editingFieldName, false);
    cancelProxyRestoreRequest(*s, "finished");
    return 0;
}

static void syncEditingBufferAfterAcceptedSceneLocked(Session *s)
{
    if (!s->editing) return;
    // R1（Astra s2-identity-handoff）：旧票据结算的识别**不用版本阈值**。
    // projectionVersion 是 configure 的场景准入版本（整棵候选连同未变化节点
    // 都改成它），不是对象出生/生命周期版本；Astra 明确否定「版本 < 基线即
    // 容忍」这类宽限。这里比较的是**提交票据 lineage**：acceptedPaintTicketId
    // 是本次结算晋升的提交票号（两条成功路径在调用本函数前已写入），
    // editingBornTicketId 是绑定建立时所依据 accepted 树的票号。票号由 native
    // 每次 present 单调分配，因此「结算票据 < 出生票据」= 这张票在绑定存在
    // **之前**就已投递——它携带的是绑定前的旧树，对编辑节点的缺席/退化是
    // 旧模式结果，不是本上下文的退役证据，整次容忍。
    if (s->acceptedPaintTicketId < s->editingBornTicketId) {
        RLOGW("editing sync defers kill (pre-binding settlement) node=%{public}llu "
              "settledTicket=%{public}llu bornTicket=%{public}llu",
              static_cast<unsigned long long>(s->editingNodeId),
              static_cast<unsigned long long>(s->acceptedPaintTicketId),
              static_cast<unsigned long long>(s->editingBornTicketId));
        return;
    }
    bool found = false;
    for (const SceneNode &n : s->accepted) {
        if (n.pod.nodeId != s->editingNodeId || n.pod.resourceId != s->editingResourceId) continue;
        found = true;
        if (n.pod.nodeKind != s->editingNodeKind ||
            n.pod.acceptedBindingEpoch != s->editingAcceptedBindingEpoch ||
            n.semanticId != s->editingFieldName ||
            n.pod.isReadOnly != 0 || n.pod.isInteractive == 0) {
            // S2（Astra 2026-10-02，consultations/s2-identity-handoff-astra）：
            // 生效绑定在**首张真实撤销提交**立即失效。到达这里的提交版本必
            // >= 绑定基线（更早的票据结算在函数顶部按版本容忍），失配即真
            // 实撤销/换绑，不再数帧。绑定随其提交成功才激活（platform focus
            // 只跟随已发布树）+ acceptedBindingEpoch 全量身份比较收 ABA。
            RLOGW("editing sync kills context node=%{public}llu "
                  "kind=%{public}u/%{public}u epoch=%{public}llu/%{public}llu "
                  "semantic=%{public}s/%{public}s ro=%{public}u live=%{public}u",
                  static_cast<unsigned long long>(n.pod.nodeId),
                  s->editingNodeKind, n.pod.nodeKind,
                  static_cast<unsigned long long>(s->editingAcceptedBindingEpoch),
                  static_cast<unsigned long long>(n.pod.acceptedBindingEpoch),
                  s->editingFieldName.c_str(),
                  n.semanticId.c_str(), n.pod.isReadOnly, n.pod.isInteractive);
            // S2（r18 实测）：kill 排队的 end 通知必须携带**将死上下文**的身份。
            // 不捕获时投递端回退读"当前"上下文——rebind 已把编号换成新的，
            // end 会误杀刚挂载的新代理（"end 贴着 mount"，旧两帧宽限靠时序
            // 侥幸掩盖了这一误寄）。R1：统一走待发队列，身份在冻结点入队。
            pushPendingEndLocked(*s, s->editingContextId, s->editingFieldName, false);
            s->editing = false;          // 节点不可编辑：连同绘制一起结束
            s->editorRetired = true;
            s->editingContextLive = false;
            s->textMenuIntent = 0;
            s->previewActive = false;
            s->previewText.clear();
            s->markedActive = false;
            s->reconcileNotifyPending = false;
            cancelProxyRestoreRequest(*s, "rebound_kind_or_field");
            break;
        }
        std::u16string ownerValue = utf8ToUtf16(n.value);
        // The core marks a locally accepted text event explicitly and stages an
        // empty native value so the active editor keeps drawing the event text.
        // Its scene version advances too: carry that admission version forward
        // without retiring this context or mistaking the staged empty value for
        // an external replacement (including a legitimate empty local edit).
        if (n.pod.preservesActiveLocalText != 0) {
            s->editingContextBaseVersion = n.pod.projectionVersion;
            s->editingProjectionVersion = n.pod.projectionVersion;
            break;
        }
        // H1-C：本地编辑被 owner 接受后，accepted 投影带回的就是屏幕上这段文本
        // （ownerValue == 编辑缓冲）。这是同一段本地连续的准入版本推进，不是外部
        // 换版：只推进版本并保留平台光标/组合态。否则每敲一个字都要重建编辑
        // 上下文并让页面重挂系统输入代理，光标与 preedit 全部丢失。
        if (s->editingContextLive && !s->previewActive && !editorOwnsTextSession(*s) &&
            n.pod.projectionVersion != s->editingContextBaseVersion &&
            ownerValue == s->editingText) {
            s->editingContextBaseVersion = n.pod.projectionVersion;
            s->editingProjectionVersion = n.pod.projectionVersion;
            break;
        }
        if (s->editingContextLive &&
            n.pod.projectionVersion != s->editingContextBaseVersion) {
            // projectionVersion 与 editingContextBaseVersion 均取本节点入场时
            // 的同一 scene.version；它是当前输入事件的准入版本。新 accepted
            // 版本使旧整值草稿失效，不以字符串相等推断事务仍有效。
            int64_t oldContext = s->editingContextId;
            if (!s->reconcileNotifyPending) s->reconcileOldContextId = oldContext;
            // 外部换版：新上下文编号即新身份，旧恢复请求（连同待发正文/选区）作废，
            // 否则旧恢复串会带着旧上下文号落到新上下文上。
            cancelProxyRestoreRequest(*s, "external_version");
            s->textMenuIntent = 0;
            s->editingContextId = g_nextEditingContextId.fetch_add(1);
            s->caretBlinkResetPending = true;
            s->caretAffinity = 0;
            s->editingContextBaseVersion = n.pod.projectionVersion;
            s->editingProjectionVersion = n.pod.projectionVersion;
            // R1：从本张结算树重建的上下文以本张票据为出生票据——后续更旧的
            // 迟到结算（票号更小）不得杀它。
            s->editingBornTicketId = s->acceptedPaintTicketId;
            s->editingFieldName = n.semanticId;
            s->editingText = ownerValue;
            s->previewActive = false;
            s->previewText.clear();
            s->markedActive = false;
            s->markedStart = 0;
            s->markedEnd = 0;
            // R3：上下文重建是**视图/会话**事件，不是"人的落点被丢弃"的理由。
            // 原实现无条件把选区重置为正文末尾的折叠 caret，于是"中段非空选区
            // → 双切换 → 切回"之后只剩末尾 caret，首笔系统输入变成插入而不是
            // 替换（2026-10-01 实测：ctx=1 已是 [101,104)，重建后变 [104,104)）。
            // 这里按新正文长度收敛原选区：两端 clamp 到合法标量边界，保持非空
            // 区间；只有在新正文里确实无法表达时才退化为 caret。
            const uint32_t newSize = static_cast<uint32_t>(ownerValue.size());
            uint32_t keepStart = clampToCodePointBoundary(ownerValue,
                std::min(s->selStartUtf16, s->selEndUtf16));
            uint32_t keepEnd = clampToCodePointBoundary(ownerValue,
                std::max(s->selStartUtf16, s->selEndUtf16));
            if (keepStart > newSize) keepStart = newSize;
            if (keepEnd > newSize) keepEnd = newSize;
            if (keepEnd < keepStart) keepEnd = keepStart;
            if (keepEnd > keepStart) {
                s->selStartUtf16 = keepStart;
                s->selEndUtf16 = keepEnd;
                s->caretUtf16 = keepEnd;
            } else {
                s->caretUtf16 = newSize;
                s->selStartUtf16 = s->caretUtf16;
                s->selEndUtf16 = s->caretUtf16;
            }
            s->editingTapPending = false;
            // 如果最初的 focus 还未送达，直接发送新 context 的 focus；
            // 否则发送 reconcile，供页面先卸旧 TextInput 再挂新实例。
            if (!s->focusNotifyPending) s->reconcileNotifyPending = true;
            RLOGI("ime context reconcile old=%{public}lld new=%{public}lld base=%{public}llu",
                  static_cast<long long>(oldContext),
                  static_cast<long long>(s->editingContextId),
                  static_cast<unsigned long long>(s->editingContextBaseVersion));
            g_render.post(std::make_shared<RedrawJob>());
            break;
        }
        if (s->previewActive) break;
        // 核心的「本地文字延续」窗口会把 native 值置空，约定由原生编辑器
        // 绘制可见文本（macOS 用输入代理字符串做同一件事）。这里的空值不是
        // 业务空值，用它同步会清掉本地缓冲，使随后任何纯重绘把字段画成空白。
        // C：延续窗口必须由显式旗标判定。owner 值为空且节点未打延续旗标 =
        // 业务空值（外部清空/合法空提交）——必须同步清空本地缓冲，
        // 不得凭「owner 空 + 缓冲非空」推断为延续。
        bool blankedByLocalContinuation = ownerValue.empty() && !s->editingText.empty()
            && n.pod.preservesActiveLocalText != 0;
        if (!blankedByLocalContinuation && ownerValue != s->editingText) {
            s->editingText = ownerValue;
        }
        s->caretUtf16 = std::min(s->caretUtf16, static_cast<uint32_t>(s->editingText.size()));
        s->selStartUtf16 = std::min(s->selStartUtf16, static_cast<uint32_t>(s->editingText.size()));
        s->selEndUtf16 = std::min(s->selEndUtf16, static_cast<uint32_t>(s->editingText.size()));
        s->editingProjectionVersion = n.pod.projectionVersion;
        break;
    }
    if (!found) {
        // S2：同上——出生票据之后的提交仍缺席即真实移除，立即收场；出生票据
        // 之前的结算已在函数顶部按票据 lineage 容忍（旧模式结果不得杀新绑定）。
        // R1：将死身份随通知冻结进待发队列。
        RLOGW("editing sync kills context (node absent) node=%{public}llu",
              static_cast<unsigned long long>(s->editingNodeId));
        pushPendingEndLocked(*s, s->editingContextId, s->editingFieldName, false);
        s->editing = false;
        s->editorRetired = true;
        s->editingContextLive = false;
        s->textMenuIntent = 0;
        s->previewActive = false;
        s->previewText.clear();
        s->markedActive = false;
        s->reconcileNotifyPending = false;
        cancelProxyRestoreRequest(*s, "node_removed");
    }
}


int main() {
  Session s; active=&s;
  SceneNode n; n.pod.nodeId=107; n.pod.resourceId=1;
  n.semanticId="body"; n.value="abc";
  s.accepted.push_back(n);
  beginEditingOnNodeLocked(s,n);
  const auto context=s.editingContextId;
  std::cout << "positive_healthy=" << (takeEditingContextLocked(context)!=nullptr) << "\n";
  // Exactly the state constructed by the current production test's case 6a.
  s.acceptedPaintTicketId=4; s.acceptedProjectionVersion=4; s.accepted.clear();
  syncEditingBufferAfterAcceptedSceneLocked(&s);
  std::cout << "after_old_ticket_accepted_nodes=" << s.accepted.size()
            << " live=" << s.editingContextLive
            << " input_context_accepted=" << (takeEditingContextLocked(context)!=nullptr) << "\n";
  return 0;
}

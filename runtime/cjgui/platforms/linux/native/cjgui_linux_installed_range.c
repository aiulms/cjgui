// runtime/cjgui/platforms/linux/native/cjgui_linux_installed_range.c
//
// Linux 的"来源范围生产者"（installed-range）状态机。
//
// 共同层的普通来源范围链在 macOS 与 Windows 上由各自 native 实现生产者侧。
// Linux 是单线程、无消息泵：本模块不复制 Windows 的线程/COM/消息结构，只照搬
// 它的状态机与判据，并把"最近一次真实泵出的 51 号事件"作为唯一的意图来源。
//
// 生命周期（与 Windows 同构）：
//   arm      —— 只保存候选并分配代理代次，不因文本相等就激活。
//   receipt  —— 由真实成功的代理安装/读回产生（arm 后即可读，供 owner 复核）。
//   activate —— owner 复核通过后才置位；active_receipt 只在激活后可读。
//   claim    —— 只对最近一次真实泵出的 51 号事件成立，且是一次性身份。
//   ack      —— 区分 accepted/rejected；rejected 不改动已接受版本，只关闭链。
//   release  —— 只在窗口实例与绑定代匹配时释放。
//
// 本模块只通过 cjgui_linux_installed_range.h / cjgui_linux_services.h 的只读访问器
// 取得事实，不触碰会话内部结构；三段正文在 claim 时复制进本模块自己的存储，
// 因此不受"借用到下一次泵"的限制。

#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#include "cjgui_linux_aux.h"             // cjgui_linux_session_slot / CJGUI_LINUX_MAX_SESSIONS
#include "cjgui_linux_installed_range.h"

// 与 Windows 的 CJGUI_WINDOWS_ONE_STRING_BYTE_CAPACITY 同值：单串字节上界。
// 调用方另有更紧的 64 KiB 源窗口门（text_session.cj freezeInstalledRangeBasis），
// 这里取宽上界，避免对合法候选误拒。
#define CJGUI_LINUX_RANGE_ONE_STRING_BYTE_CAPACITY (1024u * 1024u)

// 链关闭标记：ack(rejected) 之后后续捕获都带它，共同层据此拒绝而不是静默继续。
#define CJGUI_LINUX_RANGE_FLAG_CHAIN_CLOSED 1u

// 一笔已认领、尚未 ack 的意图。三段正文归本模块所有。
typedef struct CjguiLinuxRangeClaim {
    int live;                    // 已认领且未 ack
    uint64_t seq;
    uint64_t previousSeq;
    uint64_t observedAckSeq;
    int64_t observedAckVersion;
    uint64_t observedSourceStart;   // 捕获时观察到的来源起点
    uint64_t observedSourceEnd;     // 捕获时观察到的来源末端（ACK 边界）
    uint32_t flags;
    uint32_t rangeStart16;          // 被替换的 UTF-16 起点
    uint32_t rangeLength16;         // 被替换的 UTF-16 长度
    uint32_t selectionStart16;
    uint32_t selectionEnd16;
    uint64_t sceneVersion;          // 事件携带的已接受场景版本
    uint8_t *preBody;
    uint32_t preBodyLength;
    uint8_t *replacement;
    uint32_t replacementLength;
    uint8_t *postBody;
    uint32_t postBodyLength;
} CjguiLinuxRangeClaim;

// 一个槽位的生产者状态。槽位号即会话槽位号（token 活着时由
// cjgui_linux_session_slot 给出），on_create/on_destroy 保证槽位复用不继承旧状态。
typedef struct CjguiLinuxInstalledRange {
    uint64_t generation;            // 会话代次；on_create 分配，恒非零
    int armed;
    int activated;
    int closed;
    uint64_t nonce;
    uint64_t windowToken;
    uint64_t bindingEpoch;
    uint64_t contextEpoch;
    uint64_t mirrorRevision;
    int64_t ownerVersion;
    uint64_t sceneVersion;
    uint64_t nodeId;
    int64_t resourceId;
    uint64_t sourceStart;           // 已装来源起点（整个链固定）
    uint64_t sourceEnd;             // arm 时的来源末端
    uint64_t acceptedSourceEnd;     // 观察到的 ACK 边界，随 accepted ack 推进
    uint64_t proxyGeneration;       // 单调，跨 arm 递增，故意不被 disarm 清零
    uint64_t selectionRevision;     // 同上
    uint64_t acceptedSeq;
    int64_t acceptedVersion;
    uint64_t prevSeq;               // 上一笔已认领的 seq（下一笔的 previousSeq）
    uint64_t lastClaimedSeq;        // 一次性身份：任何已认领过的 seq
    uint64_t armSequence;           // arm 时刻的编辑序号：只接纳严格更新的泵出
    uint32_t selectionStart16;      // 最近一次认领的替换范围（receipt 用）
    uint32_t selectionEnd16;
    uint8_t *basisText;             // arm 候选的完整副本
    uint32_t basisTextLength;
    CjguiLinuxRangeClaim claim;
} CjguiLinuxInstalledRange;

static CjguiLinuxInstalledRange g_ranges[CJGUI_LINUX_MAX_SESSIONS];
static uint64_t g_rangeSessionGeneration = 0u;

// ---------------------------------------------------------------- 内部工具

static CjguiLinuxInstalledRange *range_for_token(uint64_t token) {
    int slot = cjgui_linux_session_slot(token);
    if (slot < 0 || (unsigned)slot >= CJGUI_LINUX_MAX_SESSIONS) return NULL;
    return &g_ranges[(unsigned)slot];
}

// 复制 length 字节并补 '\0'。length==0 是合法载荷（如删除），返回 1 且 *out=NULL。
// 返回 0 表示"非空载荷但没有源指针"或分配失败，两者都不产生部分写入。
static int range_dup_bytes(uint8_t **out, const uint8_t *source, uint32_t length) {
    *out = NULL;
    if (length == 0u) return 1;
    if (!source) return 0;
    uint8_t *copy = (uint8_t *)malloc((size_t)length + 1u);
    if (!copy) return 0;
    memcpy(copy, source, (size_t)length);
    copy[length] = '\0';
    *out = copy;
    return 1;
}

static void range_claim_clear(CjguiLinuxRangeClaim *claim) {
    if (!claim) return;
    free(claim->preBody);
    free(claim->replacement);
    free(claim->postBody);
    memset(claim, 0, sizeof(*claim));
}

// 释放本链的全部载荷与身份。proxyGeneration / selectionRevision 故意保留：
// 它们是本槽位的单调计数器，重装不得复用旧代次。
static void range_disarm(CjguiLinuxInstalledRange *range) {
    if (!range) return;
    range_claim_clear(&range->claim);
    free(range->basisText);
    range->basisText = NULL;
    range->basisTextLength = 0u;
    range->armed = 0;
    range->activated = 0;
    range->closed = 0;
    range->nonce = 0u;
    range->windowToken = 0u;
    range->bindingEpoch = 0u;
    range->contextEpoch = 0u;
    range->mirrorRevision = 0u;
    range->ownerVersion = 0;
    range->sceneVersion = 0u;
    range->nodeId = 0u;
    range->resourceId = -1;
    range->sourceStart = 0u;
    range->sourceEnd = 0u;
    range->acceptedSourceEnd = 0u;
    range->acceptedSeq = 0u;
    range->acceptedVersion = 0;
    range->prevSeq = 0u;
    range->lastClaimedSeq = 0u;
    range->armSequence = 0u;
    range->selectionStart16 = 0u;
    range->selectionEnd16 = 0u;
}

// receipt / active_receipt 共用填充。调用方已确认 armed 与 nonce。
static void range_fill_receipt(const CjguiLinuxInstalledRange *range,
                               CjguiInternalInstalledRangeReceipt *receipt) {
    memset(receipt, 0, sizeof(*receipt));
    receipt->nonce = range->nonce;
    receipt->rendererSessionGeneration = range->generation;
    receipt->windowInstanceToken = range->windowToken;
    receipt->bindingEpoch = range->bindingEpoch;
    receipt->contextEpoch = range->contextEpoch;
    receipt->mirrorRevision = range->mirrorRevision;
    receipt->ownerVersion = range->ownerVersion;
    receipt->installedSceneVersion = range->sceneVersion;
    receipt->nodeId = range->nodeId;
    receipt->resourceId = range->resourceId;
    receipt->sourceStartByte = range->sourceStart;
    receipt->sourceEndByte = range->sourceEnd;
    receipt->proxyGeneration = range->proxyGeneration;
    receipt->selectionRevision = range->selectionRevision;
    receipt->actualSelectionStart16 = range->selectionStart16;
    receipt->actualSelectionEnd16 = range->selectionEnd16;
    receipt->acceptedSequence = range->acceptedSeq;
    receipt->acceptedVersion = range->acceptedVersion;
}

// ---------------------------------------------------------------- 生命周期钩子

void cjgui_linux_installed_range_on_create(int slot) {
    if (slot < 0 || (unsigned)slot >= CJGUI_LINUX_MAX_SESSIONS) return;
    range_disarm(&g_ranges[(unsigned)slot]);
    memset(&g_ranges[(unsigned)slot], 0, sizeof(g_ranges[(unsigned)slot]));
    g_rangeSessionGeneration += 1u;
    if (g_rangeSessionGeneration == 0u) g_rangeSessionGeneration = 1u;
    g_ranges[(unsigned)slot].generation = g_rangeSessionGeneration;
}

void cjgui_linux_installed_range_on_destroy(int slot) {
    if (slot < 0 || (unsigned)slot >= CJGUI_LINUX_MAX_SESSIONS) return;
    range_disarm(&g_ranges[(unsigned)slot]);
    memset(&g_ranges[(unsigned)slot], 0, sizeof(g_ranges[(unsigned)slot]));
}

// ---------------------------------------------------------------- arm

CjguiInternalRendererStatus cjgui_internal_renderer_installed_range_arm(
    uint64_t session, const CjguiInternalInstalledRangeCandidate *candidate) {
    CjguiLinuxInstalledRange *range = range_for_token(session);
    if (!range) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    if (!candidate || candidate->nonce == 0u || candidate->bindingEpoch == 0u ||
        !candidate->sourceTextUtf8) {
        return CJGUI_INTERNAL_RENDERER_TEXT_RANGE_INVALID;
    }
    if (candidate->sourceTextUtf8Length > CJGUI_LINUX_RANGE_ONE_STRING_BYTE_CAPACITY) {
        return CJGUI_INTERNAL_RENDERER_TEXT_RESOURCE_BUDGET_EXCEEDED;
    }
    // 候选自带的来源窗口必须与它携带的载荷一致：sourceEnd-sourceStart 就是窗口字节数
    // （共同层按 start + utf8Length(body) 冻结）。不一致的报盘按搬运拒绝，不落成零。
    if (candidate->sourceEndByte < candidate->sourceStartByte ||
        candidate->sourceEndByte - candidate->sourceStartByte !=
            (uint64_t)candidate->sourceTextUtf8Length) {
        return CJGUI_INTERNAL_RENDERER_DATA_TRANSFER_REJECTED;
    }
    // 先复制再 disarm：分配失败不破坏既有状态，也不产生半装身份。
    uint8_t *basisCopy = NULL;
    if (!range_dup_bytes(&basisCopy, candidate->sourceTextUtf8,
                         candidate->sourceTextUtf8Length)) {
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    range_disarm(range);
    range->armed = 1;
    range->activated = 0;
    range->closed = 0;
    range->nonce = candidate->nonce;
    // rendererSessionGeneration 为 0 表示"绑定当前会话代次"。
    range->generation = candidate->rendererSessionGeneration
        ? candidate->rendererSessionGeneration : range->generation;
    range->windowToken = candidate->windowInstanceToken;
    range->bindingEpoch = candidate->bindingEpoch;
    range->contextEpoch = candidate->contextEpoch;
    range->mirrorRevision = candidate->mirrorRevision;
    range->ownerVersion = candidate->ownerVersion;
    range->sceneVersion = candidate->installedSceneVersion;
    range->nodeId = candidate->nodeId;
    range->resourceId = candidate->resourceId;
    range->sourceStart = candidate->sourceStartByte;
    range->sourceEnd = candidate->sourceEndByte;
    range->acceptedSourceEnd = candidate->sourceEndByte;
    range->basisText = basisCopy;
    range->basisTextLength = candidate->sourceTextUtf8Length;
    range->proxyGeneration += 1u;
    if (range->proxyGeneration == 0u) range->proxyGeneration = 1u;
    range->selectionRevision += 1u;
    range->acceptedSeq = 0u;
    range->acceptedVersion = candidate->ownerVersion;
    range->prevSeq = 0u;
    range->lastClaimedSeq = 0u;
    // Windows 的 claim 队列由 arm 建立，天然只含 arm 之后的捕获；Linux 的意图视图是
    // 单槽且不清零，因此在这里记下 arm 时刻的序号，把同一结构保证显式化。
    {
        CjguiLinuxRangeIntentView armView;
        memset(&armView, 0, sizeof(armView));
        cjgui_linux_session_range_intent_view(session, &armView);
        range->armSequence = armView.sequence;
    }
    range->selectionStart16 = 0u;
    range->selectionEnd16 = 0u;
    return CJGUI_INTERNAL_RENDERER_OK;
}

// ---------------------------------------------------------------- receipt

CjguiInternalRendererStatus cjgui_internal_renderer_installed_range_receipt(
    uint64_t session, uint64_t nonce, CjguiInternalInstalledRangeReceipt *outReceipt) {
    CjguiLinuxInstalledRange *range = range_for_token(session);
    if (!range) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    if (!outReceipt) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    if (!range->armed || range->nonce != nonce) return CJGUI_INTERNAL_RENDERER_SCENE_STALE;
    range_fill_receipt(range, outReceipt);
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus cjgui_internal_renderer_installed_range_active_receipt(
    uint64_t session, uint64_t nonce, CjguiInternalInstalledRangeReceipt *outReceipt) {
    CjguiLinuxInstalledRange *range = range_for_token(session);
    if (!range) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    if (!outReceipt) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    // 与 Windows 的退化别名不同：只有真正激活过的适配器才算"当前生效"。
    // 本阶段唯一的 active_receipt 消费者是选择搬运采用路径（Linux 尚未接线），
    // 因此这里收紧不会影响普通编辑链。
    if (!range->armed || !range->activated || range->nonce != nonce) {
        return CJGUI_INTERNAL_RENDERER_SCENE_STALE;
    }
    range_fill_receipt(range, outReceipt);
    return CJGUI_INTERNAL_RENDERER_OK;
}

// ---------------------------------------------------------------- activate / cancel

CjguiInternalRendererStatus cjgui_internal_renderer_installed_range_activate(
    uint64_t session, uint64_t nonce, uint64_t proxyGeneration, uint64_t selectionRevision) {
    CjguiLinuxInstalledRange *range = range_for_token(session);
    if (!range) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    if (!range->armed || range->nonce != nonce) return CJGUI_INTERNAL_RENDERER_SCENE_STALE;
    if (proxyGeneration != 0u && proxyGeneration != range->proxyGeneration) {
        return CJGUI_INTERNAL_RENDERER_SCENE_STALE;
    }
    (void)selectionRevision;   // owner 侧复核值，native 侧不据此改身份
    range->activated = 1;
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus cjgui_internal_renderer_installed_range_cancel(
    uint64_t session, uint64_t nonce) {
    CjguiLinuxInstalledRange *range = range_for_token(session);
    if (!range) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    if (!range->armed || range->nonce != nonce) return CJGUI_INTERNAL_RENDERER_SCENE_STALE;
    range_disarm(range);
    return CJGUI_INTERNAL_RENDERER_OK;
}

// ---------------------------------------------------------------- claim

CjguiInternalRendererStatus cjgui_internal_renderer_claim_last_pumped_range(
    uint64_t session, uint64_t nodeId, int64_t resourceId, uint64_t bindingEpoch,
    uint64_t sceneVersion, CjguiInternalInstalledRangeIntent *outIntent) {
    CjguiLinuxInstalledRange *range = range_for_token(session);
    if (!range) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    if (!outIntent) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    // NODE_NOT_FOUND 是"本链不拥有这一笔，交回普通路由（不消费）"的具名答复；
    // 下列全部前置不满足都归入它，绝不返回 OK + 零。
    if (!range->armed) return CJGUI_INTERNAL_RENDERER_NODE_NOT_FOUND;
    if (range->claim.live) return CJGUI_INTERNAL_RENDERER_NODE_NOT_FOUND;
    CjguiLinuxRangeIntentView view;
    memset(&view, 0, sizeof(view));
    cjgui_linux_session_range_intent_view(session, &view);
    if (!view.present || view.sequence == 0u) return CJGUI_INTERNAL_RENDERER_NODE_NOT_FOUND;
    // 只接纳 arm 之后新产生的编辑：arm 之前的意图不属于本链（对应 Windows 队列由
    // arm 建立的结构保证）。
    if (view.sequence <= range->armSequence) return CJGUI_INTERNAL_RENDERER_NODE_NOT_FOUND;
    // 一次性身份：同一 seq 认领过就不再认领（ack 之后同样不复活）。
    if (view.sequence == range->lastClaimedSeq) return CJGUI_INTERNAL_RENDERER_NODE_NOT_FOUND;
    if (view.nodeId != nodeId || view.resourceId != resourceId ||
        view.bindingEpoch != bindingEpoch || view.sceneVersion != sceneVersion) {
        return CJGUI_INTERNAL_RENDERER_NODE_NOT_FOUND;
    }
    // 意图必须属于当前已接受场景：accessor 与事件版本同一字段，读两次以证一致。
    if (view.sceneVersion != cjgui_linux_session_scene_version(session)) {
        return CJGUI_INTERNAL_RENDERER_NODE_NOT_FOUND;
    }
    // 被点名的节点必须仍在已接受场景里，否则这一笔没有可认领的对象。
    CjguiLinuxTextNodeView node;
    memset(&node, 0, sizeof(node));
    cjgui_linux_session_text_node_view(session, nodeId, &node);
    if (!node.found || node.nodeId != nodeId) return CJGUI_INTERNAL_RENDERER_NODE_NOT_FOUND;
    if (view.replacementLength16 > 0xFFFFFFFFu - view.replacementStart16) {
        return CJGUI_INTERNAL_RENDERER_TEXT_RANGE_INVALID;
    }
    const char *preText = view.preBody ? view.preBody : "";
    const char *replacementText = view.replacement ? view.replacement : "";
    const char *postText = view.postBody ? view.postBody : "";
    size_t preSize = strlen(preText);
    size_t replacementSize = strlen(replacementText);
    size_t postSize = strlen(postText);
    if (preSize > CJGUI_LINUX_RANGE_ONE_STRING_BYTE_CAPACITY ||
        replacementSize > CJGUI_LINUX_RANGE_ONE_STRING_BYTE_CAPACITY ||
        postSize > CJGUI_LINUX_RANGE_ONE_STRING_BYTE_CAPACITY) {
        return CJGUI_INTERNAL_RENDERER_TEXT_RESOURCE_BUDGET_EXCEEDED;
    }
    uint8_t *preCopy = NULL;
    uint8_t *replacementCopy = NULL;
    uint8_t *postCopy = NULL;
    if (!range_dup_bytes(&preCopy, (const uint8_t *)preText, (uint32_t)preSize) ||
        !range_dup_bytes(&replacementCopy, (const uint8_t *)replacementText,
                         (uint32_t)replacementSize) ||
        !range_dup_bytes(&postCopy, (const uint8_t *)postText, (uint32_t)postSize)) {
        free(preCopy);
        free(replacementCopy);
        free(postCopy);
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    CjguiLinuxRangeClaim *entry = &range->claim;
    entry->seq = view.sequence;
    entry->previousSeq = range->prevSeq;
    entry->observedAckSeq = range->acceptedSeq;
    entry->observedAckVersion = range->acceptedVersion;
    entry->observedSourceStart = range->sourceStart;
    entry->observedSourceEnd = range->acceptedSourceEnd;
    entry->flags = range->closed ? CJGUI_LINUX_RANGE_FLAG_CHAIN_CLOSED : 0u;
    entry->rangeStart16 = view.replacementStart16;
    entry->rangeLength16 = view.replacementLength16;
    // 会话只暴露"被替换的范围"，不暴露插入后的光标；按被替换范围如实登记，
    // 不替共同层臆造一个光标（共同层只把它当 preBody 内的一个自洽选区）。
    entry->selectionStart16 = view.replacementStart16;
    entry->selectionEnd16 = view.replacementStart16 + view.replacementLength16;
    entry->sceneVersion = view.sceneVersion;
    entry->preBody = preCopy;
    entry->preBodyLength = (uint32_t)preSize;
    entry->replacement = replacementCopy;
    entry->replacementLength = (uint32_t)replacementSize;
    entry->postBody = postCopy;
    entry->postBodyLength = (uint32_t)postSize;
    entry->live = 1;
    range->prevSeq = entry->seq;
    range->lastClaimedSeq = entry->seq;
    range->selectionStart16 = entry->selectionStart16;
    range->selectionEnd16 = entry->selectionEnd16;
    memset(outIntent, 0, sizeof(*outIntent));
    outIntent->nonce = range->nonce;
    outIntent->rendererSessionGeneration = range->generation;
    outIntent->windowInstanceToken = range->windowToken;
    outIntent->bindingEpoch = range->bindingEpoch;
    outIntent->contextEpoch = range->contextEpoch;
    outIntent->mirrorRevision = range->mirrorRevision;
    outIntent->ownerVersion = range->ownerVersion;
    outIntent->installedSceneVersion = range->sceneVersion;
    outIntent->nodeId = range->nodeId;
    outIntent->resourceId = range->resourceId;
    // 来源范围属于捕获时观察到的 ACK 边界，而不是本笔自己的范围：
    // 推测性的 preBody 可能已含更晚的排队编辑，更新的 ACK 不能倒改本笔出处。
    outIntent->sourceStartByte = entry->observedSourceStart;
    outIntent->sourceEndByte = entry->observedSourceEnd;
    outIntent->proxyGeneration = range->proxyGeneration;
    outIntent->selectionRevision = range->selectionRevision;
    outIntent->seq = entry->seq;
    outIntent->previousSeq = entry->previousSeq;
    outIntent->observedAckSeq = entry->observedAckSeq;
    outIntent->observedAckVersion = entry->observedAckVersion;
    outIntent->wholeChoiceNonce = 0u;            // 整篇选择只由真实捕获授予，不推断
    outIntent->wholeChoicePreviousSeq = 0u;
    outIntent->flags = entry->flags;
    outIntent->rangeStart16 = entry->rangeStart16;
    outIntent->rangeLength16 = entry->rangeLength16;
    outIntent->selectionStart16 = entry->selectionStart16;
    outIntent->selectionEnd16 = entry->selectionEnd16;
    outIntent->preBodyUtf8 = entry->preBody;
    outIntent->preBodyUtf8Length = entry->preBodyLength;
    outIntent->replacementUtf8 = entry->replacement;
    outIntent->replacementUtf8Length = entry->replacementLength;
    outIntent->postBodyUtf8 = entry->postBody;
    outIntent->postBodyUtf8Length = entry->postBodyLength;
    return CJGUI_INTERNAL_RENDERER_OK;
}

// ---------------------------------------------------------------- copy

CjguiInternalRendererStatus cjgui_internal_renderer_copy_claimed_range_bytes(
    uint64_t session, uint64_t seq,
    uint8_t *preBody, uint32_t preBodyCapacity,
    uint8_t *replacement, uint32_t replacementCapacity,
    uint8_t *postBody, uint32_t postBodyCapacity) {
    CjguiLinuxInstalledRange *range = range_for_token(session);
    if (!range) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    CjguiLinuxRangeClaim *entry = &range->claim;
    if (!entry->live) return CJGUI_INTERNAL_RENDERER_SCENE_STALE;
    if (seq != entry->seq) return CJGUI_INTERNAL_RENDERER_SCENE_STALE;
    // 容量不足是具名拒绝；容量足够（含刚好相等）即成功，三段逐一相符。
    if (preBodyCapacity < entry->preBodyLength ||
        replacementCapacity < entry->replacementLength ||
        postBodyCapacity < entry->postBodyLength) {
        return CJGUI_INTERNAL_RENDERER_TEXT_RANGE_INVALID;
    }
    if ((entry->preBodyLength && !preBody) ||
        (entry->replacementLength && !replacement) ||
        (entry->postBodyLength && !postBody)) {
        return CJGUI_INTERNAL_RENDERER_TEXT_RANGE_INVALID;
    }
    if (entry->preBodyLength) memcpy(preBody, entry->preBody, entry->preBodyLength);
    if (entry->replacementLength) {
        memcpy(replacement, entry->replacement, entry->replacementLength);
    }
    if (entry->postBodyLength) memcpy(postBody, entry->postBody, entry->postBodyLength);
    return CJGUI_INTERNAL_RENDERER_OK;
}

// ---------------------------------------------------------------- ack

CjguiInternalRendererStatus cjgui_internal_renderer_ack_installed_range(
    uint64_t session, const CjguiInternalInstalledRangeIntent *intent,
    uint32_t accepted, int64_t receiptVersionAfter) {
    CjguiLinuxInstalledRange *range = range_for_token(session);
    if (!range) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    if (!intent) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    CjguiLinuxRangeClaim *entry = &range->claim;
    if (!entry->live) return CJGUI_INTERNAL_RENDERER_SCENE_STALE;
    if (intent->seq != entry->seq || intent->nonce != range->nonce) {
        return CJGUI_INTERNAL_RENDERER_SCENE_STALE;
    }
    // 全部校验通过后才改动状态：失败重试时本函数不留下半结算。
    if (accepted) {
        range->acceptedSeq = entry->seq;
        range->acceptedVersion = receiptVersionAfter;
        range->acceptedSourceEnd = range->sourceStart + (uint64_t)entry->postBodyLength;
    } else {
        // 被拒的后缀：链按共享契约关闭，后续捕获带 closed 标记；已接受版本不动。
        range->closed = 1;
    }
    range_claim_clear(entry);
    return CJGUI_INTERNAL_RENDERER_OK;
}

// ---------------------------------------------------------------- release

CjguiInternalRendererStatus cjgui_internal_renderer_release_installed_range(
    uint64_t session, uint64_t windowInstanceToken, uint64_t bindingEpoch) {
    CjguiLinuxInstalledRange *range = range_for_token(session);
    if (!range) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    if (!range->armed) return CJGUI_INTERNAL_RENDERER_OK;
    if (windowInstanceToken != 0u && windowInstanceToken != range->windowToken) {
        return CJGUI_INTERNAL_RENDERER_SCENE_STALE;
    }
    if (bindingEpoch != 0u && bindingEpoch != range->bindingEpoch) {
        return CJGUI_INTERNAL_RENDERER_SCENE_STALE;
    }
    range_disarm(range);
    return CJGUI_INTERNAL_RENDERER_OK;
}

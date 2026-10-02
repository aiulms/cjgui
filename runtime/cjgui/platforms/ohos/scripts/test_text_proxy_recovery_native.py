#!/usr/bin/env python3
"""H1-R：代理恢复事务的确定性反例（票据版）。

一张逻辑恢复＝一张票据：`recover_text_proxy_ticket` 在同一临界区里验证 accepted 正文、
场景版本与**签发前确定的规范落点**，一次性重置缓冲并只登记一张票；`ime_restore_ack` 只
接受同票据、同上下文、当前身份仍等于冻结身份、且**观测落点精确等于规范目标**的回执；
窗口采纳前必须先 `consume` 票据（与 native 的截止/取消只有一个胜者）。

被摘掉任一守卫，同一套断言必须失败：请求号/相位核对、冻结身份重核、标量边界、
规范目标等式（合法的错误落点也采纳＝缺陷）、终态通知、票据唯一消费、签发登记。
deadline 的到期裁决在 pump 的限时等待里，本 harness 用 `terminate_*` 直接验证它的
两种终态（未安装 / 未确认）与事件码；到期路径由产品窗口探针覆盖。
"""
import pathlib
import subprocess
import sys
import tempfile
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]
SOURCE = ROOT / "host" / "ohos_renderer.cpp"
INGRESS = ROOT / "host" / "cjgui_ohos_ingress.h"

MAIN_BODY = r"""
static const std::string kRefused = "# Pharos Mark\n\nAgentH1C";
static const std::string kAccepted = "# Pharos Mark\n\nAgentAgent";
static const std::string kAcceptedEmoji = "# t\n\n" "hello \xF0\x9F\x98\x80";
static const uint32_t kAcceptedUnits = 25;
static const uint32_t kEmojiUnits = 13;
static int g_failures = 0;

#define EXPECT(cond, code) do { if (!(cond)) { fprintf(stderr, "FAIL %d (%s)\n", code, #cond); g_failures += 1; } } while (0)

static SceneNode acceptedNode(uint64_t nodeId, int64_t resourceId, uint32_t nodeKind,
                              uint64_t version, const std::string &value) {
  SceneNode n;
  n.pod.nodeId = nodeId;
  n.pod.resourceId = resourceId;
  n.pod.nodeKind = nodeKind;
  n.pod.projectionVersion = version;
  n.pod.acceptedBindingEpoch = 77;
  n.pod.isInteractive = 1;
  n.pod.isReadOnly = 0;
  n.semanticId = "pharos-editor-body";
  n.value = value;
  return n;
}

// 一个已聚焦、已声明会话所有权的活上下文，缓冲里是被 owner 拒绝的草稿。
static Session &armRefused(const std::string &accepted) {
  for (Session &slot : g_sessions.sessions) { slot = Session(); }
  Session &s = g_sessions.sessions[0];
  s.inUse = true;
  s.token = g_sessionToken;
  s.editing = true;
  s.editorRetired = false;
  s.editingContextLive = true;
  s.editingContextId = 41;
  s.editingContextGeneration = 5;
  s.editingFieldName = "pharos-editor-body";
  s.editingNodeId = 107;
  s.editingResourceId = 1;
  s.editingNodeKind = 10;
  s.editingProjectionVersion = 9;
  s.editingContextBaseVersion = 9;
  s.editingText = utf8ToUtf16(kRefused);
  s.caretUtf16 = static_cast<uint32_t>(s.editingText.size());
  s.selStartUtf16 = s.caretUtf16;
  s.selEndUtf16 = s.caretUtf16;
  s.previewActive = true;
  s.previewText = utf8ToUtf16("H1C");
  s.previewStart = 0;
  s.previewEnd = 3;
  s.markedActive = true;
  s.markedStart = 1;
  s.markedEnd = 3;
  s.accepted.push_back(acceptedNode(107, 1, 10, 9, accepted));
  g_redrawPosts = 0;
  return s;
}

static CjguiInternalRendererProxyRestoreTicket issue(Session &s, const std::string &accepted,
                                                    uint32_t start, uint32_t end) {
  (void)s;
  CjguiInternalRendererProxyRestoreTicket ticket{};
  const CjguiInternalRendererStatus st = cjgui_internal_renderer_recover_text_proxy_ticket(
      g_sessionToken, 107, 1, 10, 9, accepted.c_str(), start, end, &ticket);
  EXPECT(st == CJGUI_INTERNAL_RENDERER_OK, 1000 + static_cast<int>(ticket.requestId));
  return ticket;
}

static void sendRestore(Session &s) {  // 复现 pump 的发送跃迁
  if (s.proxyRestore.armed) {
    s.proxyRestore.armed = false;
    s.proxyRestore.awaitingAck = true;
    s.proxyRestore.sent = true;
  }
}

static int eventCount(Session &s) { return static_cast<int>(s.events.size()); }

int main() {
  // 1) 一次原子签发：一张票、规范落点、native 身份、单调截止。
  {
    Session &s = armRefused(kAccepted);
    const auto ticket = issue(s, kAccepted, 4, 9);
    EXPECT(ticket.requestId == 1, 11);
    EXPECT(ticket.contextId == 41 && ticket.contextGeneration == 5, 12);
    EXPECT(ticket.acceptedBindingEpoch == 77 && ticket.acceptedProjectionVersion == 9, 13);
    EXPECT(ticket.canonicalStart == 4 && ticket.canonicalEnd == 9, 14);
    EXPECT(ticket.deadlineMonoMs > 0, 15);
    EXPECT(s.proxyRestore.armed && !s.proxyRestore.awaitingAck, 16);
    EXPECT(!s.previewActive && !s.markedActive, 17);  // 缓冲被重置回 accepted
    EXPECT(utf16ToUtf8(s.editingText) == kAccepted, 18);
  }
  // 2) 相同目标重复签发 = 幂等，返回原票据，不消耗预算。
  {
    Session &s = armRefused(kAccepted);
    const auto first = issue(s, kAccepted, 4, 9);
    sendRestore(s);
    const auto again = issue(s, kAccepted, 4, 9);
    EXPECT(first.requestId == again.requestId, 21);
    EXPECT(s.proxyRestoreRequestSeq == 1, 22);
    // 目标改变：旧票必须有终态，新票新号。
    const auto second = issue(s, kAccepted, 0, 0);
    EXPECT(second.requestId == 2, 23);
    EXPECT(!s.proxyRestoreTerminals.empty() &&
           s.proxyRestoreTerminals.back().requestId == 1, 24);
  }
  // 3) 未发送就不得接受回执；发送后按票据号才接受。
  {
    Session &s = armRefused(kAccepted);
    issue(s, kAccepted, 4, 9);
    EXPECT(ohos_renderer_ime_restore_ack_ctx(41, 1, 4, 9, 1) == 1, 31);
    EXPECT(eventCount(s) == 0, 32);
    sendRestore(s);
    EXPECT(ohos_renderer_ime_restore_ack_ctx(41, 2, 4, 9, 1) == 1, 33);  // 陌生请求号
    EXPECT(eventCount(s) == 0, 34);
  }
  // 4) 合法的错误落点不采纳（目标 4:9，平台报 0:0）。
  {
    Session &s = armRefused(kAccepted);
    issue(s, kAccepted, 4, 9);
    sendRestore(s);
    EXPECT(ohos_renderer_ime_restore_ack_ctx(41, 1, 0, 0, 1) == 1, 41);
    EXPECT(!s.proxyRestore.platformInstalled, 42);
    EXPECT(s.proxyRestoreTerminals.size() == 1 &&
           s.proxyRestoreTerminals[0].code == CJGUI_INTERNAL_RENDERER_PROXY_RESTORE_UNCONFIRMED, 43);
    EXPECT(!s.events.empty() && s.events.back().recordIndex == 2u, 44);
    // 迟到的重复回执返回既有裁决，不重复计终态。
    const size_t before = s.proxyRestoreTerminals.size();
    EXPECT(ohos_renderer_ime_restore_ack_ctx(41, 1, 4, 9, 1) == 1, 45);
    EXPECT(s.proxyRestoreTerminals.size() == before, 46);
  }
  // 5) 观测等于规范目标才算平台安装；票据消费只有一个胜者。
  {
    Session &s = armRefused(kAccepted);
    issue(s, kAccepted, 4, 9);
    sendRestore(s);
    EXPECT(ohos_renderer_ime_restore_ack_ctx(41, 1, 4, 9, 1) == 0, 51);
    EXPECT(s.proxyRestore.platformInstalled, 52);
    EXPECT(!s.events.empty() && s.events.back().recordIndex == 0u &&
               s.events.back().bindingEpoch == 1, 53);
    int consumed = 0;
    EXPECT(cjgui_internal_renderer_consume_proxy_restore_ticket(g_sessionToken, 1, 4, 9, &consumed)
               == CJGUI_INTERNAL_RENDERER_OK && consumed == 1, 54);
    EXPECT(cjgui_internal_renderer_consume_proxy_restore_ticket(g_sessionToken, 1, 4, 9, &consumed)
               == CJGUI_INTERNAL_RENDERER_OK && consumed == 0, 55);  // 不可重复消费
    EXPECT(s.proxyRestoreTerminals.back().code ==
               CJGUI_INTERNAL_RENDERER_PROXY_RESTORE_ADOPTED, 56);
  }
  // 6) 未安装的票据不能被窗口消费；落点不符也不能。
  {
    Session &s = armRefused(kAccepted);
    issue(s, kAccepted, 4, 9);
    int consumed = 1;
    EXPECT(cjgui_internal_renderer_consume_proxy_restore_ticket(g_sessionToken, 1, 4, 9, &consumed)
               == CJGUI_INTERNAL_RENDERER_OK && consumed == 0, 61);
    sendRestore(s);
    EXPECT(ohos_renderer_ime_restore_ack_ctx(41, 1, 4, 9, 1) == 0, 62);
    consumed = 1;
    EXPECT(cjgui_internal_renderer_consume_proxy_restore_ticket(g_sessionToken, 1, 0, 0, &consumed)
               == CJGUI_INTERNAL_RENDERER_OK && consumed == 0, 63);
  }
  // 7) 平台明确失败：终态 code=2（已发送），事件带原因，锁不解。
  {
    Session &s = armRefused(kAccepted);
    issue(s, kAccepted, 4, 9);
    sendRestore(s);
    EXPECT(ohos_renderer_ime_restore_ack_ctx(41, 1, 0, 0, 0) == 0, 71);
    EXPECT(!s.proxyRestore.platformInstalled && s.proxyRestoreTerminals.size() == 1, 72);
    EXPECT(s.proxyRestoreTerminals[0].code ==
               CJGUI_INTERNAL_RENDERER_PROXY_RESTORE_UNCONFIRMED, 73);
    EXPECT(!s.events.empty() && s.events.back().recordIndex == 2u &&
               s.events.back().text == "platform_install_failed", 74);
  }
  // 8) 未发送即终结 = code 1（平台安装从未执行），与 code 2 可区分。
  {
    Session &s = armRefused(kAccepted);
    issue(s, kAccepted, 4, 9);
    terminateProxyRestoreRequestLocked(s, "no_sink");
    EXPECT(s.proxyRestoreTerminals.size() == 1 &&
           s.proxyRestoreTerminals[0].code ==
               CJGUI_INTERNAL_RENDERER_PROXY_RESTORE_NOT_INSTALLED, 81);
    EXPECT(s.events.back().recordIndex == 1u, 82);
  }
  // 9) 换焦/换绑后到达的旧回执：不改身份、不解锁、不投递安装事件。
  {
    Session &s = armRefused(kAccepted);
    issue(s, kAccepted, 4, 9);
    sendRestore(s);
    s.editingNodeId = 108;
    EXPECT(ohos_renderer_ime_restore_ack_ctx(41, 1, 4, 9, 1) == 1, 91);
    EXPECT(s.proxyRestoreTerminals.back().reason == "identity_changed", 92);
    EXPECT(!s.proxyRestore.platformInstalled, 93);
  }
  // 10) 非标量边界落点必须拒绝，且状态零改动。
  {
    Session &s = armRefused(kAcceptedEmoji);
    const uint64_t seqBefore = s.proxyRestoreRequestSeq;
    CjguiInternalRendererProxyRestoreTicket ticket{};
    const CjguiInternalRendererStatus st = cjgui_internal_renderer_recover_text_proxy_ticket(
        g_sessionToken, 107, 1, 10, 9, kAcceptedEmoji.c_str(), kEmojiUnits - 1, kEmojiUnits, &ticket);
    EXPECT(st != CJGUI_INTERNAL_RENDERER_OK && ticket.requestId == 0, 101);
    EXPECT(s.proxyRestoreRequestSeq == seqBefore, 102);
    EXPECT(s.previewActive && s.markedActive &&
               s.previewText == utf8ToUtf16("H1C"), 103);  // 拒绝是零改动：草稿/组字事实原样保留
  }
  // 11) 越界与值不符同样零签发。
  {
    Session &s = armRefused(kAccepted);
    CjguiInternalRendererProxyRestoreTicket ticket{};
    EXPECT(cjgui_internal_renderer_recover_text_proxy_ticket(g_sessionToken, 107, 1, 10, 9,
               kAccepted.c_str(), 0, kAcceptedUnits + 1, &ticket) != CJGUI_INTERNAL_RENDERER_OK, 111);
    EXPECT(ticket.requestId == 0 && s.proxyRestoreRequestSeq == 0, 112);
    EXPECT(cjgui_internal_renderer_recover_text_proxy_ticket(g_sessionToken, 107, 1, 10, 9,
               kRefused.c_str(), 0, 1, &ticket) != CJGUI_INTERNAL_RENDERER_OK, 113);
    EXPECT(s.proxyRestoreRequestSeq == 0, 114);
    // 场景版本不符（窗口拿着旧投影来签发）
    EXPECT(cjgui_internal_renderer_recover_text_proxy_ticket(g_sessionToken, 107, 1, 10, 8,
               kAccepted.c_str(), 0, 1, &ticket) != CJGUI_INTERNAL_RENDERER_OK, 115);
    EXPECT(s.proxyRestoreRequestSeq == 0, 116);
  }
  // 12) 哨兵落点：签发前决定规范值，票据把它回传给窗口（窗口此后只信票据）。
  {
    Session &s = armRefused(kAccepted);
    const auto ticket = issue(s, kAccepted, CJGUI_INTERNAL_RENDERER_PROXY_RESTORE_END_OF_TEXT,
                              CJGUI_INTERNAL_RENDERER_PROXY_RESTORE_END_OF_TEXT);
    EXPECT(ticket.canonicalStart == kAcceptedUnits && ticket.canonicalEnd == kAcceptedUnits, 121);
  }
  // 13) 查询票据：进行中与已终结都能按号取回，未知号返回 NONE。
  {
    Session &s = armRefused(kAccepted);
    issue(s, kAccepted, 4, 9);
    CjguiInternalRendererProxyRestoreTicket q{};
    EXPECT(cjgui_internal_renderer_query_proxy_restore_ticket(g_sessionToken, 1, &q)
               == CJGUI_INTERNAL_RENDERER_OK &&
           q.state == CJGUI_INTERNAL_RENDERER_PROXY_RESTORE_QUEUED, 131);
    sendRestore(s);
    cjgui_internal_renderer_query_proxy_restore_ticket(g_sessionToken, 1, &q);
    EXPECT(q.state == CJGUI_INTERNAL_RENDERER_PROXY_RESTORE_SENT, 132);
    EXPECT(ohos_renderer_ime_restore_ack_ctx(41, 1, 4, 9, 1) == 0, 133);
    cjgui_internal_renderer_query_proxy_restore_ticket(g_sessionToken, 1, &q);
    EXPECT(q.state == CJGUI_INTERNAL_RENDERER_PROXY_RESTORE_INSTALLED && q.canonicalStart == 4, 134);
    cjgui_internal_renderer_query_proxy_restore_ticket(g_sessionToken, 99, &q);
    EXPECT(q.state == CJGUI_INTERNAL_RENDERER_PROXY_RESTORE_NONE && q.requestId == 0, 135);
  }
  // 14) 旧共享 ABI 的委托仍只签发一张票（不存在孤儿请求）。
  {
    Session &s = armRefused(kAccepted);
    uint32_t start = 0, end = 0;
    EXPECT(cjgui_internal_renderer_recover_active_text_proxy(g_sessionToken, 107, 1, 10,
               kAccepted.c_str(), &start, &end) == CJGUI_INTERNAL_RENDERER_OK, 141);
    EXPECT(s.proxyRestoreRequestSeq == 1 && start == kAcceptedUnits, 142);
    uint32_t s2 = 0, e2 = 0;
    EXPECT(cjgui_internal_renderer_restore_composable_selection(g_sessionToken, 107, 1, 10, 9,
               kAccepted.c_str(), 4, 9, &s2, &e2) == CJGUI_INTERNAL_RENDERER_OK, 143);
    EXPECT(s.proxyRestoreRequestSeq == 2, 144);  // 目标改变 → 旧票有终态、新票新号
    EXPECT(s.proxyRestoreTerminals.size() == 1, 145);
  }
  return g_failures == 0 ? 0 : 1;
}
"""

STUBS = r'''
#include <algorithm>
#include <cstdint>
#include <cstdio>
#include <cstddef>
#include <deque>
#include <cstring>
#include <memory>
#include <mutex>
#include <string>
#include <vector>
template <class... Args> static void cjguiLogSinkStub(Args&&...) {}
#define RLOGI(...) cjguiLogSinkStub(__VA_ARGS__)
#define RLOGW(...) cjguiLogSinkStub(__VA_ARGS__)
typedef enum CjguiInternalRendererStatus {
  CJGUI_INTERNAL_RENDERER_OK = 0,
  CJGUI_INTERNAL_RENDERER_INVALID_SESSION = 11,
  CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR = 99
} CjguiInternalRendererStatus;
struct RedrawJob {};
static int g_redrawPosts = 0;
struct RenderStub { void post(const std::shared_ptr<RedrawJob> &) { g_redrawPosts += 1; } };
static RenderStub g_render;
static const uint32_t kEvTextProxyRestored = 55;
static const uint32_t kProxyRestoreEndOfText = 0xFFFFFFFFu;
static const int64_t kProxyRestoreDeadlineMs = 2500;
static const uint32_t CJGUI_INTERNAL_RENDERER_PROXY_RESTORE_END_OF_TEXT = 0xFFFFFFFFu;
enum CjguiInternalRendererProxyRestoreState {
    CJGUI_INTERNAL_RENDERER_PROXY_RESTORE_NONE = 0,
    CJGUI_INTERNAL_RENDERER_PROXY_RESTORE_QUEUED = 1,
    CJGUI_INTERNAL_RENDERER_PROXY_RESTORE_SENT = 2,
    CJGUI_INTERNAL_RENDERER_PROXY_RESTORE_INSTALLED = 3,
    CJGUI_INTERNAL_RENDERER_PROXY_RESTORE_ADOPTED = 4,
    CJGUI_INTERNAL_RENDERER_PROXY_RESTORE_NOT_INSTALLED = 5,
    CJGUI_INTERNAL_RENDERER_PROXY_RESTORE_UNCONFIRMED = 6,
};
struct CjguiInternalRendererProxyRestoreTicket {
    uint64_t requestId;
    int64_t contextId;
    uint64_t contextGeneration;
    uint64_t acceptedBindingEpoch;
    uint64_t acceptedProjectionVersion;
    int64_t deadlineMonoMs;
    uint32_t canonicalStart;
    uint32_t canonicalEnd;
    int32_t state;
};
'''

REPLICA = r'''
struct QueuedEvent {
  int64_t editingContextId = 0;
  uint64_t editingContextGeneration = 0;
  uint32_t kind = 0;
  uint32_t recordIndex = 0;
  uint32_t selectionStart = 0;
  uint32_t selectionEnd = 0;
  uint64_t nodeId = 0;
  uint64_t projectionVersion = 0;
  int64_t resourceId = -1;
  uint32_t nodeKind = 0;
  uint64_t acceptedBindingEpoch = 0;
  uint64_t bindingEpoch = 0;
  std::string text;
};
struct SceneNodePod {
  uint64_t nodeId = 0;
  int64_t resourceId = -1;
  uint32_t nodeKind = 0;
  uint64_t projectionVersion = 0;
  uint64_t acceptedBindingEpoch = 0;
  uint8_t isInteractive = 0;
  uint8_t isReadOnly = 0;
};
struct SceneNode {
  SceneNodePod pod;
  std::string semanticId;
  std::string value;
};
struct Session {
  uint32_t textMenuIntent=0;
  bool editing = false;
  bool editorRetired = false;
  bool editingContextLive = false;
  int64_t editingContextId = 0;
  uint64_t editingContextGeneration = 0;
  std::string editingFieldName;
  uint64_t editingNodeId = 0;
  int64_t editingResourceId = -1;
  uint32_t editingNodeKind = 0;
  uint64_t editingProjectionVersion = 0;
  uint64_t editingContextBaseVersion = 0;
  std::u16string editingText;
  uint32_t caretUtf16 = 0;
  uint32_t selStartUtf16 = 0;
  uint32_t selEndUtf16 = 0;
  std::u16string previewText;
  uint32_t previewStart = 0;
  uint32_t previewEnd = 0;
  bool previewActive = false;
  bool markedActive = false;
  uint32_t markedStart = 0;
  uint32_t markedEnd = 0;
  bool inUse = false;
  uint64_t token = 0;
  struct ProxyRestoreRequest {
    uint64_t requestId = 0;
    bool armed = false;
    bool awaitingAck = false;
    bool sent = false;
    bool received = false;
    bool platformInstalled = false;
    bool reported = false;
    int64_t deadlineMonoMs = 0;
    uint64_t nodeId = 0;
    int64_t resourceId = -1;
    uint32_t nodeKind = 0;
    uint64_t acceptedProjectionVersion = 0;
    uint64_t acceptedBindingEpoch = 0;
    int64_t contextId = 0;
    uint64_t contextGeneration = 0;
    std::string fieldName;
    std::u16string text;
    uint32_t selStart = 0;
    uint32_t selEnd = 0;
    uint32_t observedStart = 0;
    uint32_t observedEnd = 0;
    std::string terminalReason;
  };
  struct ProxyRestoreTerminal {
    uint64_t requestId = 0;
    int32_t code = 0;
    std::string reason;
    bool platformInstalled = false;
    uint32_t observedStart = 0;
    uint32_t observedEnd = 0;
  };
  std::deque<ProxyRestoreTerminal> proxyRestoreTerminals;
  ProxyRestoreRequest proxyRestore;
  uint64_t proxyRestoreRequestSeq = 0;
  std::vector<SceneNode> accepted;
  std::vector<QueuedEvent> events;
};
struct SessionTable {
  std::mutex lock;
  Session sessions[4];
};
static constexpr size_t kMaxSessions = 4;
static SessionTable g_sessions;
static const uint64_t g_sessionToken = 7;
static Session *lookupSessionLocked(uint64_t token) {
  if (token == 0) return nullptr;
  for (size_t i = 0; i < kMaxSessions; ++i) {
    if (g_sessions.sessions[i].inUse && g_sessions.sessions[i].token == token) {
      return &g_sessions.sessions[i];
    }
  }
  return nullptr;
}
'''

FUNCTIONS = [
    ("static void terminateProxyRestoreRequestLocked(Session &s", "terminateProxyRestoreRequestLocked"),
    ("static void cancelProxyRestoreRequest(Session &s", "cancelProxyRestoreRequest"),
    ("static int64_t proxyRestoreNowMs()", "proxyRestoreNowMs"),
    ("static void armProxyRestoreRequestLocked(Session &s", "armProxyRestoreRequestLocked"),
    ("static const SceneNode *acceptedEditingNodeLocked(const Session &s", "acceptedEditingNodeLocked"),
    # 前向声明与定义同名；marker 带上函数头的 `{`，只取定义，避免重复抽取。
    ("static void fillProxyRestoreTicketLocked(const Session &s, uint64_t requestId,\n"
     "    CjguiInternalRendererProxyRestoreTicket *outTicket)\n{",
     "fillProxyRestoreTicketLocked"),
    ("static CjguiInternalRendererStatus recoverTextProxyTicketLocked(Session &s",
     "recoverTextProxyTicketLocked"),
    ("CjguiInternalRendererStatus cjgui_internal_renderer_recover_text_proxy_ticket(uint64_t session",
     "cjgui_internal_renderer_recover_text_proxy_ticket"),
    ("CjguiInternalRendererStatus cjgui_internal_renderer_query_proxy_restore_ticket(uint64_t session",
     "cjgui_internal_renderer_query_proxy_restore_ticket"),
    ("CjguiInternalRendererStatus cjgui_internal_renderer_consume_proxy_restore_ticket(uint64_t session",
     "cjgui_internal_renderer_consume_proxy_restore_ticket"),
    ("static Session *findSessionByRestoreContextLocked(int64_t contextId", "findSessionByRestoreContextLocked"),
    ("CjguiInternalRendererStatus cjgui_internal_renderer_recover_active_text_proxy(uint64_t session",
     "cjgui_internal_renderer_recover_active_text_proxy"),
    ("CjguiInternalRendererStatus cjgui_internal_renderer_restore_composable_selection(uint64_t session",
     "cjgui_internal_renderer_restore_composable_selection"),
    ("extern \"C\" int32_t ohos_renderer_ime_restore_ack_ctx(", "ohos_renderer_ime_restore_ack_ctx"),
]

SUPPORT = [
    "std::u16string utf8ToUtf16(const std::string &utf8)",
    "std::string utf16ToUtf8(const std::u16string &utf16)",
    "uint32_t clampToCodePointBoundary(const std::u16string &text, uint32_t offset)",
    "bool utf16IsHighSurrogate(uint16_t unit)",
    "bool utf16IsLowSurrogate(uint16_t unit)",
    "bool utf16IsScalarBoundary(const std::u16string &text, size_t offset)",
]


def extract_decl(text: str, marker: str) -> str:
    start = text.index(marker)
    opening = text.index("{", start)
    depth = 0
    for index in range(opening, len(text)):
        depth += (text[index] == "{") - (text[index] == "}")
        if depth == 0:
            return text[start:index + 1]
    raise ValueError(f"unterminated declaration: {marker}")


# 生产 Session 里的落点账本字段：`selPlatform*`（native→平台 差分推送目标）与
# `selForwarded*`（已转发给窗口的平台观测）。恢复 ACK 路径直接写 selPlatform*，而
# REPLICA 是手抄的 Session 副本 —— H1-3 加这些字段时没同步过来，本 harness 从此
# 编译不过（no member named 'selPlatformEnd'），而且是静默的：没人跑就没人知道。
# 改为抽生产原文注入，字段再改名/改宽立刻变成编译错误。
LEDGER_FIRST = "    uint32_t selPlatformStart = 0;"
LEDGER_LAST = "    int32_t caretAffinity = 0;"
REPLICA_SESSION_MARKER = "  std::deque<ProxyRestoreTerminal> proxyRestoreTerminals;"


def production_ledger_fields(text: str) -> str:
    start = text.index(LEDGER_FIRST)
    end = text.index(LEDGER_LAST, start) + len(LEDGER_LAST)
    return text[start:end] + "\n"


def replica_with_ledger(source_text: str) -> str:
    if REPLICA_SESSION_MARKER not in REPLICA:
        raise AssertionError("replica Session marker not found; harness scaffolding drifted")
    return REPLICA.replace(REPLICA_SESSION_MARKER,
                           production_ledger_fields(source_text) + REPLICA_SESSION_MARKER, 1)


def build_harness(source_text: str) -> str:
    harness = '#include "cjgui_ohos_ingress.h"\n'
    harness += STUBS
    harness += replica_with_ledger(source_text)
    harness += "\n".join(extract_decl(source_text, sig) for sig in SUPPORT)
    harness += "\n".join(extract_decl(source_text, marker) for marker, _ in FUNCTIONS)
    harness += "\n" + MAIN_BODY
    return harness


# 负控按 Astra §7 的边界逐条注入：去掉一个守卫，同一套断言必须失败。
def mutate(source: str, marker: str, replacement: str, name: str) -> str:
    if marker not in source:
        raise AssertionError(f"negative control {name} did not match the source")
    return source.replace(marker, replacement, 1)


def drop_ack_request_identity(source: str) -> str:
    return mutate(source, """    if (!req.awaitingAck) {
        RLOGW("proxy restore ack rejected: not awaiting ctx=%{public}lld req=%{public}llu",""",
              """    if (false) {
        RLOGW("proxy restore ack rejected: not awaiting ctx=%{public}lld req=%{public}llu",""",
              "ack_request_identity")


def drop_ack_identity_recheck(source: str) -> str:
    return mutate(source, """    if (s->editingContextId != req.contextId ||
        s->editingContextGeneration != req.contextGeneration ||
        s->editingNodeId != req.nodeId || s->editingResourceId != req.resourceId ||
        s->editingNodeKind != req.nodeKind || s->editingFieldName != req.fieldName) {""",
              """    if (false) {""", "ack_identity_recheck")


# 回执里的标量边界核验**不再单列负控**：规范目标在签发前已按同一份 accepted 正文
# 验过标量边界，而采纳又要求观测精确等于该目标，所以这条守卫在公开入口上被
# `drop_canonical_equality` 蕴含（摘掉它测试仍然全绿，等于一条不可能失败的反例）。
# 代码里保留它是平台回写值的纵深防御，但测试账本不把它算作独立边界。


def drop_canonical_equality(source: str) -> str:
    """a4：只要落点合法就采纳——把"观测必须等于规范目标"的守卫摘掉。"""
    return mutate(source, """    if (static_cast<uint32_t>(selStart) != req.selStart || static_cast<uint32_t>(selEnd) != req.selEnd) {""",
          "    if (false) {", "canonical_equality")


def drop_terminal_notification(source: str) -> str:
    return mutate(source, "    if (cancelled.requestId != 0 && !cancelled.reported) {",
                  "    if (false) {", "terminal_notification")


def drop_consume_single_winner(source: str) -> str:
    """票据可被重复消费：窗口与 native 的截止裁决就不再是唯一胜者。"""
    return mutate(source, """    if (requestId == 0 || req.requestId != requestId || !req.platformInstalled ||
        req.observedStart != adoptedStart || req.observedEnd != adoptedEnd) {""",
                  "    if (requestId == 0) {", "consume_single_winner")


def drop_ticket_arm(source: str) -> str:
    """签发不登记票据：窗口永远等不到回执，等于没有恢复事务。"""
    return mutate(source, "    armProxyRestoreRequestLocked(s, *accepted, start, end);", "", "ticket_arm")


def drop_ticket_boundary(source: str) -> str:
    """签发前不校验标量边界：把切进代理对内部的落点交给系统选择手柄。"""
    return mutate(source, """    if (clampToCodePointBoundary(text, start) != start ||
        clampToCodePointBoundary(text, end) != end) {""", "    if (false) {", "ticket_boundary")


class TextProxyRecoveryNativeTest(unittest.TestCase):
    def _compile_and_run(self, source_text: str, tmp: pathlib.Path) -> int:
        harness = tmp / "text_proxy_recovery_harness.cpp"
        harness.write_text(build_harness(source_text))
        binary = tmp / "text_proxy_recovery_harness"
                # 负控会摘掉某个守卫，被摘的那个 helper 就成了"定义了但没人调"——那不是被测
        # 语义，只是抽取式 harness 的产物，所以只关掉这一条告警，其余保持 -Werror。
        compile_cmd = ["clang++", "-std=c++17", "-Wall", "-Wextra", "-Werror",
                       "-Wno-unused-function",
                       f"-I{ROOT / 'host'}", f"-I{INGRESS.parent}",
                       str(harness), "-o", str(binary)]
        compiled = subprocess.run(compile_cmd, capture_output=True, text=True)
        if compiled.returncode != 0:
            self.fail(f"harness compile failed:\n{compiled.stderr}")
        return subprocess.run([str(binary)], capture_output=True, text=True).returncode

    def test_freeze_and_receipt_transaction(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            rc = self._compile_and_run(SOURCE.read_text(), pathlib.Path(tmpdir))
            self.assertEqual(rc, 0, f"text proxy recovery harness failed with rc={rc}")

    def test_negative_control_without_ack_awaiting_state(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            rc = self._compile_and_run(drop_ack_request_identity(SOURCE.read_text()),
                                       pathlib.Path(tmpdir))
            self.assertNotEqual(rc, 0, "accepting a stale/foreign receipt must fail")

    def test_negative_control_without_identity_recheck(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            rc = self._compile_and_run(drop_ack_identity_recheck(SOURCE.read_text()),
                                       pathlib.Path(tmpdir))
            self.assertNotEqual(rc, 0, "accepting a receipt after a focus change must fail")

    def test_negative_control_without_canonical_equality(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            rc = self._compile_and_run(drop_canonical_equality(SOURCE.read_text()),
                                       pathlib.Path(tmpdir))
            self.assertNotEqual(rc, 0, "adopting a legal-but-wrong landing point must fail")

    def test_negative_control_without_terminal_notification(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            rc = self._compile_and_run(drop_terminal_notification(SOURCE.read_text()),
                                       pathlib.Path(tmpdir))
            self.assertNotEqual(rc, 0, "terminating without notifying the window must fail")

    def test_negative_control_without_consume_single_winner(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            rc = self._compile_and_run(drop_consume_single_winner(SOURCE.read_text()),
                                       pathlib.Path(tmpdir))
            self.assertNotEqual(rc, 0, "a ticket consumed twice must fail")

    def test_negative_control_without_ticket_arm(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            rc = self._compile_and_run(drop_ticket_arm(SOURCE.read_text()), pathlib.Path(tmpdir))
            self.assertNotEqual(rc, 0, "issuing without registering a ticket must fail")

    def test_negative_control_without_ticket_boundary(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            rc = self._compile_and_run(drop_ticket_boundary(SOURCE.read_text()), pathlib.Path(tmpdir))
            self.assertNotEqual(rc, 0, "issuing a non-scalar canonical target must fail")



if __name__ == "__main__":
    sys.exit(0 if unittest.main(exit=False).result.wasSuccessful() else 1)

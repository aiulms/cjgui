#!/usr/bin/env python3
"""H-caret：系统 IME 整值回调不得把暂态文尾变成平台选择写回指令。

r26 实证：中段输入 ZWJ（66 units 文 caret10 → 71 units caret15）后，
`editorCommitPlainChangeLocked` 把会话落点无条件设成文尾 71；pump 差分回推
在真实 onSelection 之前把 71 安装回平台（IMC 15/15→71/71，setter71）。

抽取 host 真实生产函数（commit + 差分回推准入 + 差分/边界/会话闭包），
在宿主 clang++ 下断言确定性交错：
  * RED 形 `onSelection(15) → onChange(71文) → pump`：落点保持 15，回推静默，
    范围增量仍精确（10:10＋11B）。撤回修复时落点变 71 且回推触发 → 翻红。
  * 反序正控 `onChange → pump → onSelection → pump`：全程无 71 写回。
  * 收缩钳位：删至 20 units 后落点保持 15（边界合法），不跳文尾。

  r30 实证：71 units 正文 → 真实 selectAll → 平台观测[0,71) →
  真实整值 onChange("Q") → pump。`editorCommitPlainChangeLocked` 清资格并钳位
  0:1，但旧 `humanCaretNotificationPending` 若留存，会令 helper 在资格门之前
  放行、pump 把当前钳位 0:1 发出（正确后像 1:1 由后续观测确认）。修复在正文
  实际推进后退役旧 pending；新正文之后的新显式菜单仍有效，同值 echo 不误退役。

平台 onSelection 的账本同步（set_selection_ctx 对会话＋账本的同值写入，
其转发/核验路径由既有套件覆盖）在此建模为同值同步并明确标注；断言的
commit/pump 判定均为真实抽取函数。负控：把钳位改回文尾直设，同一二进制
必须失败。
"""
import pathlib
import subprocess
import sys
import tempfile
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]
SOURCE = ROOT / "host" / "ohos_renderer.cpp"
INGRESS = ROOT / "host" / "cjgui_ohos_ingress.h"

MAIN_BODY = r'''
// --- r26 镜像：66 units 正文，caret 10；中段插入 👩‍🚀（5 units/11B）→ 71 units，caret 15。
static const std::u16string kWoman = u"\xD83D\xDC69";
static const std::u16string kZwJoin = u"\u200D";
static const std::u16string kRocket = u"\xD83D\xDE80";
static std::u16string base66() {
  std::u16string t = u"0123456789";
  for (int i = 0; i < 56; ++i) t += u"x";
  return t;
}
static void arm(Session &s, const std::u16string &text, uint32_t caret) {
  s.ownedTextSessionEnabled = true;
  s.rangeEditDeltaRequested = true;
  s.editingNodeId = 190;
  s.ownedTextSessionNodeId = 190;
  s.editingResourceId = -1;
  s.ownedTextSessionResourceId = -1;
  s.editingNodeKind = 1;
  s.ownedTextSessionNodeKind = 1;
  s.editingProjectionVersion = 6;
  s.ownedTextSessionBindingEpoch = 1;
  s.editorRetired = false;
  s.editingContextGeneration = 4;
  s.editingContextBaseVersion = 7;
  s.editing = true;
  s.editingContextLive = true;
  s.editingText = text;
  s.caretUtf16 = caret;
  s.selStartUtf16 = caret;
  s.selEndUtf16 = caret;
  s.selPlatformStart = caret;
  s.selPlatformEnd = caret;
  s.previewActive = false;
  s.markedActive = false;
  s.previewText.clear();
  s.humanCaretNotificationPending = false;
  s.proxyRestore = Session::ProxyRestoreRequest{};
  s.selectionDrag = Session::SelectionDrag{};
  s.events.clear();
}
// 建模 set_selection_ctx 对会话＋平台账本的同值同步及其资格置位（其 kind-33
// 转发与身份核验由既有 IME 套件覆盖，此处只复现“平台已确认值”这一事实）。
static void modelOnSelection(Session &s, uint32_t a, uint32_t b) {
  s.selStartUtf16 = a;
  s.selEndUtf16 = b;
  s.caretUtf16 = b;
  s.selPlatformStart = a;
  s.selPlatformEnd = b;
  s.selectionIntentConfirmed = true;
}
static bool offersEndOfText(const Session &s) {
  const uint32_t eot = static_cast<uint32_t>(s.editingText.size());
  return editorCaretPushBackNeededLocked(s) &&
      (std::min(s.selStartUtf16, s.selEndUtf16) == eot ||
       std::max(s.selStartUtf16, s.selEndUtf16) == eot);
}

int main() {
  const std::u16string base = base66();
  if (base.size() != 66) return 1;
  const std::u16string zwj = kWoman + kZwJoin + kRocket;
  if (zwj.size() != 5 || utf16ToUtf8(zwj).size() != 11) return 2;
  const std::u16string grown = base.substr(0, 10) + zwj + base.substr(10);
  if (grown.size() != 71) return 3;
  // RED 形：onSelection(15) → onChange(71文) → pump。落点保持 15，回推静默。
  {
    Session s;
    arm(s, base, 10);
    modelOnSelection(s, 15, 15);
    if (!editorCommitPlainChangeLocked(s, grown)) return 10;
    if (s.editingText != grown) return 11;
    if (s.caretUtf16 != 15 || s.selStartUtf16 != 15 || s.selEndUtf16 != 15) return 12;
    if (!utf16IsScalarBoundary(grown, s.caretUtf16)) return 13;
    if (editorCaretPushBackNeededLocked(s)) return 14;
    if (offersEndOfText(s)) return 15;
    bool saw51 = false;
    for (const QueuedEvent &ev : s.events) {
      if (ev.kind != kEvTextRangeChanged) continue;
      saw51 = true;
      if (ev.selectionStart != 10 || ev.selectionEnd != 10) return 16;
      if (ev.text != utf16ToUtf8(zwj)) return 17;
    }
    if (!saw51) return 18;
  }
  // 反序正控：onChange → pump → onSelection → pump。全程无文尾写回。
  {
    Session s;
    arm(s, base, 10);
    if (!editorCommitPlainChangeLocked(s, grown)) return 20;
    if (s.caretUtf16 == 71 || s.selStartUtf16 == 71 || s.selEndUtf16 == 71) return 21;
    if (editorCaretPushBackNeededLocked(s)) return 22;
    if (offersEndOfText(s)) return 23;
    modelOnSelection(s, 15, 15);
    if (s.caretUtf16 != 15) return 24;
    if (editorCaretPushBackNeededLocked(s)) return 25;
    if (offersEndOfText(s)) return 26;
  }
  // 收缩钳位：删至 20 units，落点保持 15 不跳文尾，回推静默。
  {
    Session s;
    arm(s, grown, 15);
    modelOnSelection(s, 15, 15);
    const std::u16string shrunk = grown.substr(0, 20);
    if (!editorCommitPlainChangeLocked(s, shrunk)) return 30;
    if (s.caretUtf16 != 15 || s.selStartUtf16 != 15 || s.selEndUtf16 != 15) return 31;
    if (editorCaretPushBackNeededLocked(s)) return 32;
    if (offersEndOfText(s)) return 33;
  }
  // 收缩交错（r27）：71 units 已选 [10,60)，平台用 Q 替换 → 22 units。
  // onChange 先到时钳位 10:22 不得成为回推命令（账本仍 10:60）；正确 caret11
  // 由后续观测确认。增量仍精确 10:60 + Q。
  {
    std::u16string text71(71, u'x');
    Session s;
    arm(s, text71, 10);
    modelOnSelection(s, 10, 60);
    const std::u16string shrunk = text71.substr(0, 10) + u"Q" + text71.substr(60);
    if (shrunk.size() != 22) return 40;
    if (!editorCommitPlainChangeLocked(s, shrunk)) return 41;
    if (s.editingText != shrunk) return 42;
    bool saw51 = false;
    for (const QueuedEvent &ev : s.events) {
      if (ev.kind != kEvTextRangeChanged) continue;
      saw51 = true;
      if (ev.selectionStart != 10 || ev.selectionEnd != 60) return 43;
      if (ev.text != "Q") return 44;
    }
    if (!saw51) return 45;
    if (s.selStartUtf16 != 10 || s.selEndUtf16 != 22) return 46;
    if (editorCaretPushBackNeededLocked(s)) return 47;
    if (offersEndOfText(s)) return 48;
    modelOnSelection(s, 11, 11);
    if (s.caretUtf16 != 11) return 49;
    if (editorCaretPushBackNeededLocked(s)) return 50;
    // 显式人类路径不受资格门影响（pending 由真实命中代码置位，此处只验证门控）。
    s.humanCaretNotificationPending = true;
    if (!editorCaretPushBackNeededLocked(s)) return 51;
    s.humanCaretNotificationPending = false;
  }
  // 前缀删除交错：71 units caret 60，前 50 units 被删 → 21 units；钳位 21 不得
  // 回推（账本 60:60）；正确 caret 10 由后续观测确认。
  {
    std::u16string text71(71, u'y');
    Session s;
    arm(s, text71, 60);
    modelOnSelection(s, 60, 60);
    const std::u16string shrunk = text71.substr(50);
    if (shrunk.size() != 21) return 60;
    if (!editorCommitPlainChangeLocked(s, shrunk)) return 61;
    if (s.caretUtf16 != 21) return 62;
    if (editorCaretPushBackNeededLocked(s)) return 63;
    modelOnSelection(s, 10, 10);
    if (s.caretUtf16 != 10) return 64;
    if (editorCaretPushBackNeededLocked(s)) return 65;
  }
  // r30 菜单旁路：71 units 正文 → 真实 selectAll → 平台观测[0,71) →
  // 真实整值 onChange("Q") → pump。旧 pending 已被正文推进退役，回推静默；
  // 落点为当前钳位 0:1（正确后像 1:1 由后续同源观测确认）。撤回退役则 push=1。
  {
    std::u16string text71(71, u'x');
    Session s;
    arm(s, text71, 10);
    const bool menuOk = editorApplyMenuCommandLocked(s, "selectAll", text71, u"", 4, 7, 10, 10);
    if (!menuOk) return 70;
    if (!s.humanCaretNotificationPending) return 71;
    modelOnSelection(s, 0, 71);
    if (!editorCommitPlainChangeLocked(s, u"Q")) return 72;
    if (s.editingText.size() != 1) return 73;
    if (s.selStartUtf16 != 0 || s.selEndUtf16 != 1) return 74;
    if (s.selPlatformStart != 0 || s.selPlatformEnd != 71) return 75;
    if (s.selectionIntentConfirmed) return 76;
    if (s.humanCaretNotificationPending) return 77;
    if (editorCaretPushBackNeededLocked(s)) return 78;
    modelOnSelection(s, 1, 1);
    if (s.caretUtf16 != 1) return 79;
    if (editorCaretPushBackNeededLocked(s)) return 80;
  }
  // 正控：正文推进后，新的显式菜单意图仍有效；同值 echo 不误退役旧 pending。
  {
    std::u16string text71(71, u'x');
    Session s;
    arm(s, text71, 10);
    const bool menuOk = editorApplyMenuCommandLocked(s, "selectAll", text71, u"", 4, 7, 10, 10);
    if (!menuOk) return 90;
    modelOnSelection(s, 0, 71);
    if (!editorCommitPlainChangeLocked(s, u"Q")) return 91;
    if (s.humanCaretNotificationPending) return 92;
    if (editorCaretPushBackNeededLocked(s)) return 93;
    // 新正文之后的新显式菜单：全选当前 1 unit 正文，取得发送权。
    const std::u16string cur = u"Q";
    const bool menuOk2 = editorApplyMenuCommandLocked(s, "selectAll", cur, u"", 4, 7, 0, 1);
    if (!menuOk2) return 94;
    if (!s.humanCaretNotificationPending) return 95;
    if (!editorCaretPushBackNeededLocked(s)) return 96;
    // 同值 echo：不推进正文，不退役新 pending，发送权保留。
    if (!editorCommitPlainChangeLocked(s, u"Q")) return 97;
    if (!s.humanCaretNotificationPending) return 98;
    if (!editorCaretPushBackNeededLocked(s)) return 99;
  }
  return 0;
}
'''

REPLICA = r'''
struct Session {
  bool editorRetired=false; uint64_t editingContextGeneration=4,editingContextBaseVersion=7;
  uint32_t textMenuIntent=0;
  bool caretBlinkResetPending=false;
  int32_t caretAffinity=0;
  bool humanCaretNotificationPending=false;
  bool ownedTextSessionEnabled = false;
  bool rangeEditDeltaRequested = false;
  uint64_t editingNodeId = 0;
  uint64_t ownedTextSessionNodeId = 0;
  int64_t editingResourceId = -1;
  int64_t ownedTextSessionResourceId = -1;
  uint32_t editingNodeKind = 0;
  uint32_t ownedTextSessionNodeKind = 0;
  uint64_t editingProjectionVersion = 0;
  uint64_t ownedTextSessionBindingEpoch = 0;
  std::u16string editingText;
  uint32_t caretUtf16 = 0;
  uint32_t selStartUtf16 = 0;
  uint32_t selEndUtf16 = 0;
  uint32_t selPlatformStart = 0;
  uint32_t selPlatformEnd = 0;
  bool selectionIntentConfirmed = false;
  bool editing = false;
  bool editingContextLive = false;
  bool previewActive = false;
  bool markedActive = false;
  std::u16string previewText;
  uint32_t previewStart = 0;
  uint32_t previewEnd = 0;
  struct ProxyRestoreRequest {
    uint64_t requestId=0; int64_t contextId=0;
    bool armed=false; bool awaitingAck=false; bool platformInstalled=false;
    bool sent=false; bool reported=false;
    uint64_t nodeId=0; int64_t resourceId=-1; uint32_t nodeKind=0;
    uint64_t acceptedProjectionVersion=0; uint64_t acceptedBindingEpoch=0;
    uint32_t observedStart=0; uint32_t observedEnd=0;
  };
  struct ProxyRestoreTerminal {
    uint64_t requestId=0; uint32_t code=0; std::string reason;
    bool platformInstalled=false; uint32_t observedStart=0; uint32_t observedEnd=0;
  };
  struct SelectionDrag { bool active=false; bool anchorReady=false; bool terminal=false; };
  ProxyRestoreRequest proxyRestore;
  std::deque<ProxyRestoreTerminal> proxyRestoreTerminals;
  SelectionDrag selectionDrag;
  std::deque<QueuedEvent> events;
};
'''

STUBS = r'''
#include <algorithm>
#include <cstdint>
#include <cstddef>
#include <deque>
#include <string>
template <class... Args> static void cjguiLogSinkStub(Args&&...) {}
#define RLOGI(...) cjguiLogSinkStub(__VA_ARGS__)
#define RLOGW(...) cjguiLogSinkStub(__VA_ARGS__)
constexpr uint32_t kEvTextChanged = 28;
constexpr uint32_t kEvTextRangeChanged = 51;
constexpr uint32_t kEvTextProxyRestored = 55;
constexpr int32_t CJGUI_INTERNAL_RENDERER_PROXY_RESTORE_UNCONFIRMED = 6;
constexpr int32_t CJGUI_INTERNAL_RENDERER_PROXY_RESTORE_NOT_INSTALLED = 5;
struct QueuedEvent {
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
'''

SIGNATURES = [
    "std::u16string utf8ToUtf16(const std::string &utf8)",
    "std::string utf16ToUtf8(const std::u16string &utf16)",
    "uint32_t clampToCodePointBoundary(const std::u16string &text, uint32_t offset)",
    "bool utf16IsHighSurrogate(uint16_t unit)",
    "bool utf16IsLowSurrogate(uint16_t unit)",
    "bool utf16IsScalarBoundary(const std::u16string &text, size_t offset)",
    "bool utf16IsWellFormed(const std::u16string &text)",
    "bool editorOwnsTextSession(const Session &s)",
    "std::u16string composedBuffer(const Session &s)\n{",
    "void editorEnqueueTextChanged(Session &s)",
    "bool editorEnqueueTextCommit(Session &s, const std::u16string &previous, const std::u16string &next)",
    "static void terminateProxyRestoreRequestLocked(Session &s, const char *reason)",
    "static void cancelProxyRestoreRequest(Session &s, const char *reason)",
    "bool editorCommitPlainChangeLocked(Session &s, const std::u16string &next)",
    "static bool editorCaretPushBackNeededLocked(const Session &s)",
    "bool editorApplyMenuCommandLocked(Session &s",
]


def extract_method(text: str, signature: str) -> str:
    if text.count(signature) != 1:
        raise ValueError(f"signature must occur exactly once: {signature!r} "
                         f"(found {text.count(signature)})")
    start = text.index(signature)
    if signature.endswith("{"):
        start_body = start + len(signature) - 1
        depth = 0
        for index in range(start_body, len(text)):
            depth += (text[index] == "{") - (text[index] == "}")
            if depth == 0:
                return text[start:start_body] + text[start_body:index + 1]
        raise ValueError(f"unterminated method: {signature}")
    opening = text.index("{", start)
    depth = 0
    for index in range(opening, len(text)):
        depth += (text[index] == "{") - (text[index] == "}")
        if depth == 0:
            return text[start:index + 1]
    raise ValueError(f"unterminated method: {signature}")


# 负控：把落点钳位改回文尾直设（撤回本次修复），同一二进制必须失败。
def revert_to_end_of_text(source: str) -> str:
    anchor = ("    // 整值回调不携带选择意图：正文更新，但落点保持上一次已确认值并钳到新文\n"
              "    // 标量边界，不移到文尾。")
    if source.count(anchor) != 1:
        raise AssertionError("negative control anchor must occur exactly once")
    start = source.index(anchor)
    end_marker = "    s.selEndUtf16 = clampToCodePointBoundary(s.editingText, s.selEndUtf16);\n"
    end = source.index(end_marker, start) + len(end_marker)
    reverted = (source[:start] +
                "    s.caretUtf16 = static_cast<uint32_t>(s.editingText.size());\n"
                "    s.selStartUtf16 = s.caretUtf16;\n"
                "    s.selEndUtf16 = s.caretUtf16;\n" + source[end:])
    return reverted


def build_harness(source_text: str) -> str:
    harness = '#include "cjgui_ohos_ingress.h"\n'
    harness += STUBS
    harness += REPLICA
    harness += "\n".join(extract_method(source_text, sig) for sig in SIGNATURES)
    harness += "\n" + MAIN_BODY
    return harness


# 负控 2：去掉回推资格门（钳位仍在），收缩交错必须失败——证明仅钳位不够，
# 非空钳位范围同样须被拦。
def revert_pushback_gate(source: str) -> str:
    anchor = "    if (!s.selectionIntentConfirmed) return false;\n"
    if source.count(anchor) != 1:
        raise AssertionError("negative control anchor must occur exactly once")
    return source.replace(anchor, "", 1)


# 负控 3：去掉正文推进对旧 pending 的退役（恢复 r30 漏口），菜单旁路必须失败——
# 证明旧通知不能借当前钳位值发送。
def revert_pending_retire(source: str) -> str:
    anchor = "    if (s.editingText != previous) s.humanCaretNotificationPending = false;\n"
    if source.count(anchor) != 1:
        raise AssertionError("negative control anchor must occur exactly once")
    return source.replace(anchor, "", 1)


class ImeWholeValueCaretNativeTest(unittest.TestCase):
    def _compile_and_run(self, source_text: str, tmp: pathlib.Path) -> int:
        harness = tmp / "ime_whole_value_caret_harness.cpp"
        harness.write_text(build_harness(source_text))
        binary = tmp / "ime_whole_value_caret_harness"
        compile_cmd = ["clang++", "-std=c++17", "-Wall", "-Wextra", "-Werror",
                       f"-I{ROOT / 'host'}", f"-I{INGRESS.parent}",
                       str(harness), "-o", str(binary)]
        compiled = subprocess.run(compile_cmd, capture_output=True, text=True)
        if compiled.returncode != 0:
            self.fail(f"harness compile failed:\n{compiled.stderr}")
        return subprocess.run([str(binary)], capture_output=True, text=True).returncode

    def test_interleave_no_end_of_text_pushback(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            rc = self._compile_and_run(SOURCE.read_text(), pathlib.Path(tmpdir))
            self.assertEqual(rc, 0, f"whole-value caret harness failed with rc={rc}")

    def test_negative_control_end_of_text_jump(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            rc = self._compile_and_run(revert_to_end_of_text(SOURCE.read_text()),
                                       pathlib.Path(tmpdir))
            self.assertNotEqual(rc, 0, "reverting to end-of-text caret must fail")

    def test_negative_control_without_pushback_gate(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            rc = self._compile_and_run(revert_pushback_gate(SOURCE.read_text()),
                                       pathlib.Path(tmpdir))
            self.assertNotEqual(rc, 0, "removing the pushback license must fail")

    def test_negative_control_without_pending_retire(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            rc = self._compile_and_run(revert_pending_retire(SOURCE.read_text()),
                                       pathlib.Path(tmpdir))
            self.assertNotEqual(rc, 0, "keeping the superseded pending must fail")


if __name__ == "__main__":
    sys.exit(0 if unittest.main(exit=False).result.wasSuccessful() else 1)

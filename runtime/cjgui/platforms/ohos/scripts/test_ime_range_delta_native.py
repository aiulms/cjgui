#!/usr/bin/env python3
"""H1：系统 IME 全文回调 → 精确 UTF-16 范围增量的差分必须落在合法标量边界。

反例（指导复核）：`editorEnqueueTextCommit` 逐码元取公共前后缀。`😀→😁` 会得到
`[1,2)` 加一个孤立低代理，重放不是 next，而且 `utf16ToUtf8` 会把孤立代理编码成
非法 UTF-8（ED B8 81 型）。

抽取 `ohos_renderer.cpp` 的真实差分/编码/边界函数，在宿主 clang++ 下断言：
  * 一次 kind-51 增量的重放 `previous[0,p) + inserted + previous[pe,end)`
    逐字节等于 next（对合法与非合法边界场景都成立）；
  * `inserted` 的 UTF-8 合法且可逆（编码回来的 UTF-16 没有不成对代理）；
  * 两端偏移都是两串的合法标量边界；
  * 畸形 UTF-16（不成对代理）具名拒绝：不产生事件、编辑缓冲保持 previous。

负控：去掉边界合法化（回到逐码元行为）或让 well-formed 判定恒真，同一二进制
必须失败——证明本测试能判别原缺陷。
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
// --- 断言脚手架 ----------------------------------------------------------
static bool replayEquals(const std::u16string &prev, const QueuedEvent &ev,
                         const std::u16string &next) {
  std::u16string replay = prev.substr(0, ev.selectionStart);
  replay += utf8ToUtf16(ev.text);
  replay += prev.substr(ev.selectionEnd);
  return replay == next;
}
static bool insertedIsLegal(const QueuedEvent &ev) {
  const std::string &u8 = ev.text;
  std::u16string back = utf8ToUtf16(u8);
  if (!utf16IsWellFormed(back)) return false;          // 不成对代理（含代理编码）
  return utf16ToUtf8(back) == u8;                       // 规范可逆编码
}
static bool boundariesAreScalar(const std::u16string &prev, const QueuedEvent &ev) {
  return utf16IsScalarBoundary(prev, ev.selectionStart) &&
         utf16IsScalarBoundary(prev, ev.selectionEnd);
}
static void arm(Session &s, const std::u16string &current) {
  s.ownedTextSessionEnabled = true;
  s.rangeEditDeltaRequested = true;
  s.editingNodeId = 107;
  s.ownedTextSessionNodeId = 107;
  s.editingResourceId = 1;
  s.ownedTextSessionResourceId = 1;
  s.editingNodeKind = 10;
  s.ownedTextSessionNodeKind = 10;
  s.editingProjectionVersion = 3;
  s.ownedTextSessionBindingEpoch = 9;
  s.editingText = current;
  s.caretUtf16 = static_cast<uint32_t>(current.size());
  s.selStartUtf16 = s.caretUtf16;
  s.selEndUtf16 = s.caretUtf16;
}
// 一对代理的构造：U+1F600 😀 / U+1F601 😁 / U+1F900（与 😀 共享低代理）。
static const std::u16string kGrin = u"\xD83D\xDE00";
static const std::u16string kBeam = u"\xD83D\xDE01";
static const std::u16string kSharedLow = u"\xD83E\xDE00";
static const std::u16string kLoneLow = u"\xDE00";
static const std::u16string kLoneHigh = u"\xD83D";

static int checkPair(const std::u16string &prev, const std::u16string &next,
                     int fail) {
  Session s;
  arm(s, prev);
  const bool committed = editorEnqueueTextCommit(s, prev, next);
  if (!committed) return fail;
  if (s.events.size() != 1) return fail + 1;
  const QueuedEvent &ev = s.events.back();
  if (ev.kind != kEvTextRangeChanged) return fail + 2;
  if (!replayEquals(prev, ev, next)) return fail + 3;
  if (!insertedIsLegal(ev)) return fail + 4;
  if (!boundariesAreScalar(prev, ev)) return fail + 5;
  return 0;
}

int main() {
  // 1. 代理对整对替换：不能切出孤立代理。
  if (int rc = checkPair(kGrin, kBeam, 10)) return rc;
  // 2. 前缀后跟代理对，且替换落在对内。
  if (int rc = checkPair(u"a" + kGrin, u"a" + kBeam, 20)) return rc;
  // 3. 代理对后跟普通字符（后缀命中）。
  if (int rc = checkPair(kGrin + u"x", kBeam + u"x", 30)) return rc;
  // 4. 两侧都有普通字符。
  if (int rc = checkPair(u"x" + kGrin + u"y", u"x" + kBeam + u"y", 40)) return rc;
  // 5. 共享低代理：只有高代理变化。
  if (int rc = checkPair(kGrin, kSharedLow, 50)) return rc;
  // 6. 追加一个代理对（inserted 是整对）。
  if (int rc = checkPair(kGrin, kGrin + kGrin, 60)) return rc;
  // 7. 删除一个代理对（removed 是整对）。
  if (int rc = checkPair(kGrin + kGrin, kGrin, 70)) return rc;
  // 8. 空串插入代理对。
  if (int rc = checkPair(u"", kGrin, 80)) return rc;
  // 9. 纯 ASCII 插入仍是最小区间：[1,1) 插入 "c"（'b' 作为后缀保留）。
  {
    Session s; arm(s, u"ab");
    if (!editorEnqueueTextCommit(s, u"ab", u"acb") || s.events.size() != 1) return 90;
    const QueuedEvent &ev = s.events.back();
    if (ev.kind != kEvTextRangeChanged || ev.selectionStart != 1 || ev.selectionEnd != 1 ||
        ev.text != "c") return 91;
  }
  // 10. 畸形：新文本里出现孤立低代理 → 具名拒绝、零事件、缓冲保持 previous。
  {
    Session s; arm(s, u"a" + kGrin);
    const std::u16string malformed = u"a" + kLoneLow;
    if (editorEnqueueTextCommit(s, u"a" + kGrin, malformed)) return 100;
    if (!s.events.empty()) return 101;
    if (s.editingText != u"a" + kGrin) return 102;
    if (s.caretUtf16 > s.editingText.size()) return 103;
    if (!utf16IsScalarBoundary(s.editingText, s.caretUtf16)) return 104;
  }
  // 11. 畸形：previous 以孤立高代理开头（平台回读被截断）→ 同样拒绝。
  {
    Session s; arm(s, kLoneHigh);
    if (editorEnqueueTextCommit(s, kLoneHigh, kGrin)) return 110;
    if (!s.events.empty()) return 111;
    if (s.editingText != kLoneHigh) return 112;
  }
  // 12. 未声明拥有的节点：不产生范围增量（仍是整值事件），行为不变。
  {
    Session s; arm(s, u"ab");
    s.ownedTextSessionEnabled = false;
    if (!editorEnqueueTextCommit(s, u"ab", u"a\u00e9b")) return 120;
    if (s.events.size() != 1 || s.events.back().kind != kEvTextChanged) return 121;
  }
  return 0;
}
'''

REPLICA = r'''
struct SceneNode { struct { uint64_t nodeId=0,projectionVersion=0,acceptedBindingEpoch=0; int64_t resourceId=-1; uint32_t nodeKind=0; } pod; };
struct Session {
  bool selectionIntentConfirmed=false;
  int64_t editingContextId=0,editingMirrorOwnerVersion=-1;
  uint64_t editingContextGeneration=0;
  std::vector<SceneNode> accepted;
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
  std::deque<QueuedEvent> events;
};
static std::u16string composedBuffer(Session &s) { return s.editingText; }
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
struct QueuedEvent {
  uint32_t kind = 0;
  uint32_t selectionStart = 0;
  uint32_t selectionEnd = 0;
  uint64_t nodeId = 0;
  uint64_t projectionVersion = 0;
  int64_t resourceId = -1;
  uint32_t nodeKind = 0;
  uint64_t bindingEpoch = 0, acceptedBindingEpoch = 0, editingContextGeneration = 0;
  int64_t editingContextId = 0;
  CjguiOhosEditTickets::Ticket inputTicket;
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
    "void editorEnqueueTextChanged(Session &s)",
    ("bool editorEnqueueTextCommit(Session &s, const std::u16string &previous, "
     "const std::u16string &next"),
]


def extract_method(text: str, signature: str) -> str:
    start = text.index(signature)
    opening = text.index("{", start)
    depth = 0
    for index in range(opening, len(text)):
        depth += (text[index] == "{") - (text[index] == "}")
        if depth == 0:
            return text[start:index + 1]
    raise ValueError(f"unterminated method: {signature}")


def build_harness(source_text: str) -> str:
    harness = '#include "cjgui_ohos_ingress.h"\n#include "cjgui_ohos_edit_ticket.h"\n'
    harness += STUBS
    harness += REPLICA
    harness += "\n".join(extract_method(source_text, sig) for sig in SIGNATURES)
    harness += "\n" + MAIN_BODY
    return harness


# 负控：把边界合法化去掉（回到逐码元前缀/后缀），或让 well-formed 判定恒真。
def drop_boundary_legalization(source: str) -> str:
    dropped = source.replace(
        "    if (prefix > 0 && !utf16IsScalarBoundary(previous, prefix)) prefix -= 1;\n", "")
    dropped = dropped.replace(
        """    while (suffix > 0 &&
           (!utf16IsScalarBoundary(previous, previousEnd) || !utf16IsScalarBoundary(next, nextEnd))) {
        suffix -= 1;
        previousEnd = previous.size() - suffix;
        nextEnd = next.size() - suffix;
    }
""", "")
    if dropped == source:
        raise AssertionError("negative control did not change the source")
    return dropped


def always_well_formed(source: str) -> str:
    marker = "bool utf16IsWellFormed(const std::u16string &text)\n{\n"
    replaced = source.replace(marker, marker + "    return true;  // negative control\n")
    if replaced == source:
        raise AssertionError("negative control did not change the source")
    return replaced


class ImeRangeDeltaNativeTest(unittest.TestCase):
    def _compile_and_run(self, source_text: str, tmp: pathlib.Path) -> int:
        harness = tmp / "ime_range_delta_harness.cpp"
        harness.write_text(build_harness(source_text))
        binary = tmp / "ime_range_delta_harness"
        compile_cmd = ["clang++", "-std=c++17", "-Wall", "-Wextra", "-Werror",
                       f"-I{ROOT / 'host'}", f"-I{INGRESS.parent}",
                       str(harness), "-o", str(binary)]
        compiled = subprocess.run(compile_cmd, capture_output=True, text=True)
        if compiled.returncode != 0:
            self.fail(f"harness compile failed:\n{compiled.stderr}")
        return subprocess.run([str(binary)], capture_output=True, text=True).returncode

    def test_legal_delta_boundaries(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            rc = self._compile_and_run(SOURCE.read_text(), pathlib.Path(tmpdir))
            self.assertEqual(rc, 0, f"ime range delta harness failed with rc={rc}")

    def test_negative_control_without_boundary_legalization(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            rc = self._compile_and_run(drop_boundary_legalization(SOURCE.read_text()),
                                       pathlib.Path(tmpdir))
            self.assertNotEqual(rc, 0, "removing scalar-boundary legalization must fail")

    def test_negative_control_without_wellformed_refusal(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            rc = self._compile_and_run(always_well_formed(SOURCE.read_text()),
                                       pathlib.Path(tmpdir))
            self.assertNotEqual(rc, 0, "accepting malformed UTF-16 must fail")


if __name__ == "__main__":
    sys.exit(0 if unittest.main(exit=False).result.wasSuccessful() else 1)

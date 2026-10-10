#!/usr/bin/env python3
"""A2：presentation 命中必须消费 paintedLayoutUsable 失效门（真实生产函数）。

抽取 ohos_renderer.cpp 的真实生产函数 runPresentationHitLocked，在宿主 clang++
下断言「原命中成功 → 同几何 Flush 失败 → 拒绝 → 成功重绘恢复」这条链：

  * 正控：租约已发布（paintedLayoutUsable=true）且身份逐项相符 ⇒ 命中成功；
  * **反例**：同几何、同票据、条目仍在表里，但 Flush 失败已把
    paintedLayoutUsable 置 false ⇒ 必须具名拒绝，不得消费从未被接受绘制的排版；
  * 恢复：下一次成功帧把 usable 置回 true ⇒ 命中重新成功（门不是单向闩）；
  * 身份门仍在：usable=true 但票据/文本不符 ⇒ 仍按 retained_layout_stale 拒绝。

变异负控证明判别力：删掉失效门后，同一二进制必须失败。
"""
import pathlib
import subprocess
import tempfile
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]
SOURCE = ROOT / "host" / "ohos_renderer.cpp"

GATE = """        if (!paintedLayoutUsable) {
            RLOGW("presentation hit refused: painted_layout_unusable retained=%{public}zu",
                  publishedPresentationLease.size());
            return CJGUI_INTERNAL_RENDERER_GEOMETRY_EMPTY;
        }
"""

SIGNATURE = ('CjguiInternalRendererStatus runPresentationHitLocked(CaretHitTestJob *job)\n')

PREFIX = r'''
#include <algorithm>
#include <cstdint>
#include <cstring>
#include <iostream>
#include <map>
#include <memory>
#include <mutex>
#include <string>
#include <vector>
#define RLOGI(...) do {} while(0)
#define RLOGW(...) do {} while(0)

enum CjguiInternalRendererStatus {
  CJGUI_INTERNAL_RENDERER_OK = 0,
  CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR = 2,
  CJGUI_INTERNAL_RENDERER_VIEW_INVALIDATED = 5,
  CJGUI_INTERNAL_RENDERER_PRESENT_PENDING = 20,
  CJGUI_INTERNAL_RENDERER_GEOMETRY_EMPTY = 7,
};
enum CjguiInternalRendererComposableNodeKind { kKindText = 3 };

struct OH_Drawing_PositionAndAffinity { int unused; };
struct OH_Drawing_Typography { int unused; };
static OH_Drawing_PositionAndAffinity *OH_Drawing_TypographyGetGlyphPositionAtCoordinateWithCluster(
    OH_Drawing_Typography *, float, float) {
  static OH_Drawing_PositionAndAffinity pos;
  return &pos;
}
static size_t OH_Drawing_GetPositionFromPositionAndAffinity(OH_Drawing_PositionAndAffinity *) {
  return 2;
}
static int OH_Drawing_GetAffinityFromPositionAndAffinity(OH_Drawing_PositionAndAffinity *) { return 0; }
static void OH_Drawing_DestroyPositionAndAffinity(OH_Drawing_PositionAndAffinity *) {}
static bool cjguiOhosGraphemeRange16(const std::u16string &, uint32_t pos, uint32_t &lo, uint32_t &hi) {
  lo = pos; hi = pos; return true;   // "abc" 每字符自成一个簇
}

struct CjguiInternalRendererComposableNode {
  uint64_t nodeId = 0, projectionVersion = 0;
  int64_t resourceId = -1, x = 0, y = 0, width = 0, height = 0;
  uint32_t nodeKind = kKindText;
  double fontSize = 13.0;
  uint32_t fontWeight = 400;
  uint64_t acceptedBindingEpoch = 0;
};
struct PaintedSelectionHandles { bool valid = false; };
struct PaintedTextLayout {
  std::shared_ptr<OH_Drawing_Typography> typography;
  CjguiInternalRendererComposableNode node{};
  std::u16string text;
  uint64_t session = 0, renderEpoch = 0, basePresentTicket = 0, projectionVersion = 0, serial = 0;
  uint64_t generation = 0, geometryRevision = 0;
  void *window = nullptr;
  int32_t width = 0, height = 0;
  int64_t paintContext = 0;
  double density = 1.0, relativeOriginX = 0.0, relativeOriginY = 0.0;
  PaintedSelectionHandles handles;
};
struct CaretHitTestJob {
  std::u16string text;
  double fontSize = 13.0;
  uint32_t fontWeight = 400;
  double nodeWidth = 0, nodeHeight = 0, tapX = 0, tapY = 0;
  uint32_t nodeKind = 0;
  uint32_t caretUtf16 = 0;
  int32_t caretAffinity = 0;
  uint64_t session = 0, nodeId = 0, bindingEpoch = 0, projectionVersion = 0;
  int64_t resourceId = -1, nodeX = 0, nodeY = 0;
  uint64_t paintSerial = 0, sourcePaintTicket = 0;
  bool presentation = false;
};
struct Session {
  uint64_t acceptedPaintTicketId = 0;
};
static Session g_theSession;
struct { std::mutex lock; } g_sessions;
static Session *lookupSessionLocked(uint64_t) { return &g_theSession; }

static std::map<uint64_t, std::shared_ptr<PaintedTextLayout>> publishedPresentationLease;
static bool paintedLayoutUsable = false;
static uint64_t renderEpoch = 7;
static void *boundWindow = reinterpret_cast<void *>(0xABCD);
static uint64_t boundGeneration = 3;
static bool leaseValid(uint64_t g) { return g == boundGeneration; }
static bool geometryMatches(void *w, uint64_t g, int, int, uint64_t rev) {
  return w == boundWindow && g == boundGeneration && rev == 11;
}
'''

MAIN = r'''
static CaretHitTestJob makeJob() {
  CaretHitTestJob j;
  j.nodeId = 190;
  j.resourceId = -1;
  j.nodeKind = kKindText;
  j.session = 42;
  j.sourcePaintTicket = 5;
  j.projectionVersion = 9;
  j.bindingEpoch = 7;
  j.text = u"abc";
  j.nodeWidth = 100;
  j.nodeHeight = 20;
  j.nodeX = 0;
  j.nodeY = 0;
  j.fontSize = 13.0;
  j.fontWeight = 400;
  j.tapX = 3.0;
  j.tapY = 1.0;
  return j;
}
static void publishFrame() {
  auto e = std::make_shared<PaintedTextLayout>();
  e->typography = std::make_shared<OH_Drawing_Typography>();
  e->node.nodeId = 190;
  e->node.resourceId = -1;
  e->node.nodeKind = kKindText;
  e->node.projectionVersion = 9;
  e->node.acceptedBindingEpoch = 7;
  e->node.x = 0; e->node.y = 0; e->node.width = 100; e->node.height = 20;
  e->node.fontSize = 13.0; e->node.fontWeight = 400;
  e->text = u"abc";
  e->session = 42;
  e->renderEpoch = renderEpoch;
  e->basePresentTicket = 5;
  e->projectionVersion = 9;
  e->generation = boundGeneration;
  e->geometryRevision = 11;
  e->window = boundWindow;
  e->width = 800; e->height = 600;
  e->serial = 3;
  publishedPresentationLease[190] = e;
  g_theSession.acceptedPaintTicketId = 5;
}
int main() {
  // 1. 正控：已发布帧 ⇒ 命中成功。
  publishFrame();
  paintedLayoutUsable = true;
  {
    CaretHitTestJob j = makeJob();
    if (runPresentationHitLocked(&j) != CJGUI_INTERNAL_RENDERER_OK) return 10;
    if (j.caretUtf16 != 2) return 11;
  }
  // 2. 反例：同几何、同票据、条目仍在表中，仅 Flush 失败置 unusable ⇒ 必须拒绝。
  publishedPresentationLease.clear();
  publishFrame();
  paintedLayoutUsable = false;   // invalidatePaintedLayout 的效果
  {
    CaretHitTestJob j = makeJob();
    CjguiInternalRendererStatus st = runPresentationHitLocked(&j);
    if (st == CJGUI_INTERNAL_RENDERER_OK) return 20;   // 旧实现：消费未发布排版
    if (st != CJGUI_INTERNAL_RENDERER_GEOMETRY_EMPTY) return 21;
    if (publishedPresentationLease.size() != 1) return 22;  // 表仍在（未整表替换）
  }
  // 3. 恢复：成功重绘后 usable 置回 true ⇒ 命中重新成功（门不是单向闩）。
  paintedLayoutUsable = true;
  {
    CaretHitTestJob j = makeJob();
    if (runPresentationHitLocked(&j) != CJGUI_INTERNAL_RENDERER_OK) return 30;
  }
  // 4. 身份门仍在：usable=true 但票据不符 ⇒ retained_layout_stale。
  {
    CaretHitTestJob j = makeJob();
    j.sourcePaintTicket = 6;
    if (runPresentationHitLocked(&j) != CJGUI_INTERNAL_RENDERER_PRESENT_PENDING) return 40;
  }
  // 5. 缺条目仍是 layout_not_retained（未退化为现场重排）。
  publishedPresentationLease.clear();
  paintedLayoutUsable = true;
  {
    CaretHitTestJob j = makeJob();
    if (runPresentationHitLocked(&j) != CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR) return 50;
  }
  std::cout << "presentation_hit_invalidation_gate=ok" << std::endl;
  return 0;
}
'''


def extract(text, signature_start):
    start = text.index(signature_start)
    end = text.index("\n    }\n", start) + len("\n    }\n")
    return text[start:end]


def build_source(host_text):
    return PREFIX + extract(host_text, SIGNATURE) + MAIN


def compile_and_run(cxx_text):
    with tempfile.TemporaryDirectory() as tmp:
        src = pathlib.Path(tmp) / "harness.cpp"
        exe = pathlib.Path(tmp) / "harness"
        src.write_text(cxx_text)
        q = subprocess.run(['clang++', '-std=c++17', '-Wall', '-Wextra', '-Werror',
                            '-Wno-unused-parameter', '-Wno-unused-variable',
                            '-Wno-unused-but-set-variable',
                            str(src), '-o', str(exe)],
                           capture_output=True, text=True)
        if q.returncode != 0:
            raise AssertionError("compile failed:\n" + q.stderr)
        return subprocess.run([str(exe)], capture_output=True, text=True)


class PresentationHitInvalidationGateTest(unittest.TestCase):
    def test_painted_layout_invalidation_closes_presentation_hit(self):
        cxx = build_source(SOURCE.read_text(encoding="utf-8"))
        self.assertIn(GATE, cxx, "presentation 命中必须读 paintedLayoutUsable")
        r = compile_and_run(cxx)
        self.assertEqual(r.returncode, 0,
                         "rc=%d out=%r err=%r" % (r.returncode, r.stdout, r.stderr))
        self.assertIn("presentation_hit_invalidation_gate=ok", r.stdout)

    def test_mutation_removing_invalidation_gate_fails(self):
        cxx = build_source(SOURCE.read_text(encoding="utf-8"))
        mutated = cxx.replace(GATE, "")
        self.assertNotEqual(mutated, cxx, "变异未生效")
        r = compile_and_run(mutated)
        self.assertNotEqual(r.returncode, 0, "删掉失效门仍通过 => 判别无证明力")


if __name__ == "__main__":
    unittest.main()
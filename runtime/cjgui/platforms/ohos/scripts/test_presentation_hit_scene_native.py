#!/usr/bin/env python3
"""消费者包 B 组反例：公共命中入口必须在查询**内部**核对调用方冻结的预期场景。

调用方先冻结 `acceptedSceneVersion` 再查询；查询在同一会话锁下核对当前代际，
不等即具名 `SCENE_STALE`，绝不返回混代偏移。本测试抽取**真实**的公共入口
（含场景门），只把渲染线程派发器换成记录器：

  1 冷会话镜像锚 ⇒ 内联（既有语义，不得回归）；
  2 活编辑镜像锚 ⇒ 内联（**本次修复**；修复前走队列 ⇒ 具名拒）；
  3 镜像声明代 ≠ 当前绑定代（换绑借旧镜像）⇒ 不得内联，仍走编辑分支；
  4 无镜像绑定（setter 未启用）⇒ 走编辑分支（不变）；
  5 活编辑镜像锚但租约缺失 ⇒ 仍走内联且具名失败，**不得**回退 candidate 或现排；
  6 可编辑 kind（多行 10）活编辑 ⇒ 走编辑分支（Pharos 正文路径逐字不变）。

  1 场景一致（冷会话）⇒ OK + 内联，caret 来自已画排版；
  2 场景不一致（一次提交之后）⇒ `SCENE_STALE`，零派发（内联/队列均为 0）；
  3 场景不一致且节点亦未知 ⇒ 仍是 `SCENE_STALE`（先核场景，后解节点）；
  4 编辑缓冲路径在场景一致时仍走队列（分支路由不受场景门影响）。

变异负控：删掉场景门 ⇒ 第 2、3 例返回 OK（必须失败）。
"""
import pathlib
import subprocess
import tempfile
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]
SOURCE = ROOT / "host" / "ohos_renderer.cpp"

ENTRY_START = ('CjguiInternalRendererStatus cjgui_internal_renderer_hit_test_composable_text('
               'uint64_t session, uint64_t nodeId,')
MIRROR_START = ('static const Session::OwnedMirrorDeclaration *ownedMirrorDeclarationLocked('
                'const Session &s,')
HIT_START = 'CjguiInternalRendererStatus runPresentationHitLocked(CaretHitTestJob *job)'

# 修复本身：公共入口在同一会话锁下先核对调用方冻结的预期场景代际。
SCENE_GATE = 'if (expectedSceneVersion != s->acceptedSceneVersion) {'

PREFIX = r'''
#include <algorithm>
#include <cmath>
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
  CJGUI_INTERNAL_RENDERER_INVALID_SESSION = 1,
  CJGUI_INTERNAL_RENDERER_NODE_NOT_FOUND = 8,
  CJGUI_INTERNAL_RENDERER_SCENE_STALE = 33,
};
enum CjguiInternalRendererComposableNodeKind {
  kKindText = 3, kKindTextInput = 5, kKindMultiline = 10,
};

struct OH_Drawing_PositionAndAffinity { int unused; };
struct OH_Drawing_Typography { int unused; };
static OH_Drawing_PositionAndAffinity *OH_Drawing_TypographyGetGlyphPositionAtCoordinateWithCluster(
    OH_Drawing_Typography *, float, float) {
  static OH_Drawing_PositionAndAffinity pos;
  return &pos;
}
static size_t OH_Drawing_GetPositionFromPositionAndAffinity(OH_Drawing_PositionAndAffinity *) {
  return 2;                                    // "AB" 的尾字节
}
static int OH_Drawing_GetAffinityFromPositionAndAffinity(OH_Drawing_PositionAndAffinity *) { return 0; }
static void OH_Drawing_DestroyPositionAndAffinity(OH_Drawing_PositionAndAffinity *) {}
static bool cjguiOhosGraphemeRange16(const std::u16string &, uint32_t pos, uint32_t &lo, uint32_t &hi) {
  lo = pos; hi = pos; return true;
}

struct CjguiInternalRendererComposableNode {
  uint64_t nodeId = 0, projectionVersion = 0;
  int64_t resourceId = -1, x = 0, y = 0, width = 0, height = 0;
  uint32_t nodeKind = kKindText;
  double fontSize = 13.0;
  uint32_t fontWeight = 400;
  uint64_t acceptedBindingEpoch = 0;
  int isInteractive = 1, isReadOnly = 0;
};
struct SceneNode {
  CjguiInternalRendererComposableNode pod{};
  std::string value;
  std::vector<int> textStyleRuns;              // 类型对本路由判别不可见
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
  std::vector<int> runs;
  double fontSize = 13.0;
  uint32_t fontWeight = 400;
  double nodeWidth = 0, nodeHeight = 0, tapX = 0, tapY = 0;
  uint32_t nodeKind = 0;
  uint32_t caretUtf16 = 0;
  int32_t caretAffinity = 0;
  uint64_t session = 0, nodeId = 0, bindingEpoch = 0, projectionVersion = 0;
  int64_t resourceId = -1, nodeX = 0, nodeY = 0, contextId = 0;
  uint64_t paintSerial = 0, sourcePaintTicket = 0;
  bool presentation = false;
  CjguiInternalRendererStatus waitFor() { return CJGUI_INTERNAL_RENDERER_GEOMETRY_EMPTY; }
};
struct Session {
  struct OwnedMirrorDeclaration {
    bool valid = false;
    std::u16string text;
    int64_t ownerContentVersion = -1;
    uint64_t bindingEpoch = 0, declaredBindingEpoch = 0;
  };
  std::vector<SceneNode> accepted;
  uint64_t acceptedPaintTicketId = 0;
  uint64_t acceptedSceneVersion = 0;
  bool editing = false, editingContextLive = false, editorRetired = false;
  uint64_t editingNodeId = 0;
  int64_t editingContextId = 0, editingResourceId = -1;
  uint32_t editingNodeKind = kKindText;
  uint64_t editingProjectionVersion = 0;
  bool ownedTextSessionEnabled = false;
  uint64_t ownedTextSessionNodeId = 0, ownedTextSessionBindingEpoch = 0;
  int64_t ownedTextSessionResourceId = -1;
  uint32_t ownedTextSessionNodeKind = kKindText;
  OwnedMirrorDeclaration ownedMirrorAccepted;
};
static Session g_theSession;
struct { std::mutex lock; } g_sessions;
static Session *lookupSessionLocked(uint64_t) { return &g_theSession; }

// ASCII 忠实即可（两条路径同用一份换算）。
static std::u16string utf8ToUtf16(const std::string &s) { return std::u16string(s.begin(), s.end()); }
static std::string utf16ToUtf8(const std::u16string &s) { return std::string(s.begin(), s.end()); }
static std::u16string composedBuffer(const Session &) { return u"AB"; }

static std::map<uint64_t, std::shared_ptr<PaintedTextLayout>> publishedPresentationLease;
static bool paintedLayoutUsable = false;
static uint64_t renderEpoch = 7;
static void *boundWindow = reinterpret_cast<void *>(0xABCD);
static uint64_t boundGeneration = 3;
static bool leaseValid(uint64_t g) { return g == boundGeneration; }
static bool geometryMatches(void *w, uint64_t g, int, int, uint64_t rev) {
  return w == boundWindow && g == boundGeneration && rev == 11;
}

// 渲染线程派发记录器：内联 = presentation 租约路径（真跑 runPresentationHitLocked），
// 队列 = 编辑缓冲路径（设备原件里正是它给出 painted_layout_unavailable）。
static int inlineHits = 0, queueHits = 0;
CjguiInternalRendererStatus runPresentationHitLocked(CaretHitTestJob *job);   // 真实抽取，前置声明
struct RenderStub {
  CjguiInternalRendererStatus executePresentationHit(std::shared_ptr<CaretHitTestJob> job) {
    ++inlineHits;
    return runPresentationHitLocked(job.get());
  }
  bool postIfRunning(std::shared_ptr<CaretHitTestJob>) { ++queueHits; return true; }
};
static RenderStub g_render;
'''

MAIN = r'''
static SceneNode makeNode(uint64_t id, uint32_t kind, const char *value, uint64_t epoch) {
  SceneNode n;
  n.pod.nodeId = id; n.pod.nodeKind = kind; n.pod.resourceId = 9801;
  n.pod.projectionVersion = 9; n.pod.acceptedBindingEpoch = epoch;
  n.pod.x = 0; n.pod.y = 0; n.pod.width = 100; n.pod.height = 20;
  n.value = value;
  return n;
}
static void publishLease() {
  auto e = std::make_shared<PaintedTextLayout>();
  e->typography = std::make_shared<OH_Drawing_Typography>();
  e->node = g_theSession.accepted[0].pod;
  e->text = utf8ToUtf16(g_theSession.accepted[0].value);
  e->session = 42; e->renderEpoch = renderEpoch; e->basePresentTicket = 5;
  e->projectionVersion = 9; e->generation = boundGeneration; e->geometryRevision = 11;
  e->window = boundWindow; e->width = 800; e->height = 600; e->serial = 3;
  publishedPresentationLease[e->node.nodeId] = e;
  g_theSession.acceptedPaintTicketId = 5;
  paintedLayoutUsable = true;
}
static CjguiInternalRendererStatus hitWith(uint64_t nodeId, uint64_t expectedScene,
    uint32_t &caret) {
  uint32_t byteOffset = 0, affinity = 0;
  const auto st = cjgui_internal_renderer_hit_test_composable_text(
      42, nodeId, 3.0, 1.0, expectedScene, &byteOffset, &affinity);
  caret = byteOffset;
  return st;
}
int main() {
  uint32_t caret = 0;

  // 公共前提：accepted 里有交互非只读 presentation TEXT，且其排版已入租约表；
  // 当前已接受场景代际为 9（调用方此前冻结的即此值）。
  g_theSession.accepted.push_back(makeNode(190, kKindText, "AB", 7));
  publishLease();
  g_theSession.acceptedSceneVersion = 9;

  // 1 场景一致（冷会话）⇒ OK + 内联，caret 来自已画排版。
  inlineHits = queueHits = 0;
  if (hitWith(190, 9, caret) != CJGUI_INTERNAL_RENDERER_OK) return 10;
  if (inlineHits != 1 || queueHits != 0) return 11;
  if (caret != 2) return 12;

  // 2 一次提交之后（代际 9→10），旧预期 ⇒ SCENE_STALE，零派发。
  g_theSession.acceptedSceneVersion = 10;
  inlineHits = queueHits = 0;
  if (hitWith(190, 9, caret) != CJGUI_INTERNAL_RENDERER_SCENE_STALE) return 20;
  if (inlineHits != 0 || queueHits != 0) return 21;

  // 3 场景不一致且节点亦未知 ⇒ 仍是 SCENE_STALE（先核场景，后解节点）。
  inlineHits = queueHits = 0;
  if (hitWith(777, 9, caret) != CJGUI_INTERNAL_RENDERER_SCENE_STALE) return 30;
  if (inlineHits != 0 || queueHits != 0) return 31;

  // 4 新预期追上当前代际 ⇒ 恢复 OK（调用方重冻重查即通）。
  inlineHits = queueHits = 0;
  if (hitWith(190, 10, caret) != CJGUI_INTERNAL_RENDERER_OK) return 40;
  if (inlineHits != 1 || queueHits != 0) return 41;

  // 5 编辑缓冲路径在场景一致时仍走队列（场景门不改分支路由）。
  g_theSession.accepted.clear();
  g_theSession.accepted.push_back(makeNode(107, kKindMultiline, "AB", 7));
  g_theSession.editing = true; g_theSession.editingContextLive = true;
  g_theSession.editingNodeId = 107; g_theSession.editingResourceId = 9801;
  g_theSession.editingNodeKind = kKindMultiline;
  g_theSession.ownedTextSessionEnabled = true;
  g_theSession.ownedTextSessionNodeId = 107; g_theSession.ownedTextSessionNodeKind = kKindMultiline;
  g_theSession.ownedMirrorAccepted.valid = true;
  g_theSession.ownedMirrorAccepted.declaredBindingEpoch = 7;
  g_theSession.ownedTextSessionBindingEpoch = 7;
  inlineHits = queueHits = 0;
  hitWith(107, 10, caret);
  if (inlineHits != 0 || queueHits != 1) return 50;

  std::cout << "presentation_hit_scene_gate=ok" << std::endl;
  return 0;
}
'''


def cut(text, start_marker, end_marker):
    """按**每条真实闭合形状**抽取整函数：自由函数收尾在第 0 列，类成员收尾在
    第 4 列（runPresentationHitLocked 是后者，用错标记会一路吞到类尾）。"""
    start = text.index(start_marker)
    end = text.index(end_marker, start) + len(end_marker)
    return text[start:end]


def build_source(host_text):
    # 抽取顺序：先真实镜像声明判据，再真实内联命中，最后真实公共入口。
    return (PREFIX + '\n'
            + cut(host_text, MIRROR_START, '\n}\n') + '\n'
            + cut(host_text, HIT_START, '\n    }\n') + '\n'
            + cut(host_text, ENTRY_START, '\n}\n') + MAIN)


def compile_and_run(cxx_text):
    with tempfile.TemporaryDirectory() as tmp:
        src = pathlib.Path(tmp) / "harness.cpp"
        exe = pathlib.Path(tmp) / "harness"
        src.write_text(cxx_text)
        q = subprocess.run(['clang++', '-std=c++17', '-Wall', '-Wextra', '-Werror',
                            '-Wno-unused-parameter', '-Wno-unused-variable',
                            '-Wno-unused-but-set-variable', str(src), '-o', str(exe)],
                           capture_output=True, text=True)
        if q.returncode != 0:
            raise AssertionError("compile failed:\n" + q.stderr)
        return subprocess.run([str(exe)], capture_output=True, text=True)


class PresentationHitSceneTest(unittest.TestCase):
    def test_public_entry_verifies_expected_scene(self):
        cxx = build_source(SOURCE.read_text(encoding="utf-8"))
        self.assertIn(SCENE_GATE, cxx, "公共命中入口必须先核对预期场景代际")
        r = compile_and_run(cxx)
        self.assertEqual(r.returncode, 0,
                         "rc=%d out=%r err=%r" % (r.returncode, r.stdout, r.stderr))
        self.assertIn("presentation_hit_scene_gate=ok", r.stdout)

    def test_mutation_dropping_scene_gate_fails(self):
        cxx = build_source(SOURCE.read_text(encoding="utf-8"))
        cut_start = cxx.index(SCENE_GATE)
        cut_end = cxx.index('}', cxx.index('return CJGUI_INTERNAL_RENDERER_SCENE_STALE;')) + 1
        mutated = cxx[:cut_start] + cxx[cut_end:]
        self.assertNotEqual(mutated, cxx, "变异未生效")
        r = compile_and_run(mutated)
        self.assertNotEqual(r.returncode, 0, "删掉场景门仍通过 ⇒ 判别无证明力")
        self.assertTrue(r.returncode in (20, 21, 30, 31),
                        "预期第 2/3 例失败，实际 rc=%d out=%r" % (r.returncode, r.stdout))


if __name__ == "__main__":
    unittest.main()

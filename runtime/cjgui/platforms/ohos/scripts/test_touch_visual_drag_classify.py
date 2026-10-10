#!/usr/bin/env python3
"""可视编辑包 C 组反例：横向拖选分类的 RED/GREEN（宿主提取真实手势链）。

复用 test_touch_gesture_native 的提取与编译机制（同一真实
synthesizeEventsFromRawTouch），只新增可视拖选判别：

  V1 BEGIN 原点：BEGIN(100,100)→MOVE(125,100)→END(160,100) 的指针流必须以
     原始触点 100 开流（现实现以跨阈值的当前 MOVE 125 开流 ⇒ RED）。
  V2 END-only：BEGIN(100,100)→END(160,100)（零 MOVE）落在交互 presentation
     TEXT 上必须走同一分类入口开指针流，不得整笔判成滚动（现实现 ⇒ RED）。
  V3 控制：纵向拖动仍由视口接管（滚动）。
  V4 控制：选择胜出后转向纵向仍保持指针流（胜出不翻转）。
  V5 控制：流中 CANCEL 恰好一条指针取消、无 END。

exit 0 = 全部判别通过；任何一条失败以非零退出（负控沿用旧实现反演）。
"""
import importlib.util
import pathlib
import subprocess
import tempfile
import unittest

HERE = pathlib.Path(__file__).resolve().parent
SPEC = importlib.util.spec_from_file_location(
    "visual_drag_fx", HERE / "test_touch_gesture_native.py")


def load():
    mod = importlib.util.module_from_spec(SPEC)
    SPEC.loader.exec_module(mod)
    return mod


MAIN = r'''
// --- 可视拖选分类反例 -------------------------------------------------------
static SceneNode makeNode(uint64_t id, uint32_t kind, int64_t x, int64_t y, int64_t w, int64_t h,
                          uint64_t version, int64_t resourceId, bool interactive) {
  SceneNode node;
  node.pod.nodeId = id;
  node.pod.nodeKind = kind;
  node.pod.x = x; node.pod.y = y; node.pod.width = w; node.pod.height = h;
  node.pod.projectionVersion = version;
  node.pod.resourceId = resourceId;
  node.pod.isInteractive = interactive ? 1u : 0u;
  node.pod.isReadOnly = 0;
  node.pod.cornerRadius = 0.0;
  node.pod.clipConstraintCount = 0;
  node.pod.acceptedBindingEpoch = 1;
  return node;
}
// 视口 900 + 交互 presentation TEXT 950（可视片段同型：kind=3、非只读、可交互）
static void addVisualScene(Session &s) {
  s.accepted.push_back(makeNode(900, CJGUI_INTERNAL_RENDERER_COMPOSABLE_SCROLL_AREA, 0, 0, 400, 420, 100, -1, false));
  s.accepted.push_back(makeNode(950, CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT, 20, 100, 360, 60, 100, -1, true));
}
static size_t countKind(const Session &s, uint32_t kind) {
  size_t n = 0;
  for (const QueuedEvent &ev : s.events) if (ev.kind == kind) ++n;
  return n;
}
static const QueuedEvent *firstOf(const Session &s, uint32_t kind) {
  for (const QueuedEvent &ev : s.events) if (ev.kind == kind) return &ev;
  return nullptr;
}
int main() {
  // V1 BEGIN 原点：跨阈值后的指针流必须从原始触点 (100,100) 开流。
  {
    Session s; addVisualScene(s);
    synthesizeEventsFromRawTouch(s, CJGUI_OHOS_TOUCH_BEGIN, 42, 100, 100);
    synthesizeEventsFromRawTouch(s, CJGUI_OHOS_TOUCH_UPDATE, 42, 125, 100);
    synthesizeEventsFromRawTouch(s, CJGUI_OHOS_TOUCH_UPDATE, 42, 145, 100);
    synthesizeEventsFromRawTouch(s, CJGUI_OHOS_TOUCH_END, 42, 160, 100);
    if (countKind(s, kEvPointerBegin) != 1) return 1;
    if (countKind(s, kEvPointerEnd) != 1) return 2;
    const QueuedEvent *begin = firstOf(s, kEvPointerBegin);
    if (begin->pointerX != 100 || begin->pointerY != 100) return 3;  // 原始触点
    if (begin->nodeId != 950) return 4;
    if (s.events.back().kind != kEvPointerEnd || s.events.back().pointerX != 160) return 5;
    for (const QueuedEvent &ev : s.events) if (ev.kind == kEvScroll && ev.text != "takeover:") return 6;
  }
  // V2 END-only：零 MOVE 的快扫落在交互 TEXT 上走同一分类——指针流（BEGIN 原点 +
  // END 当前），不得整笔判成滚动。
  {
    Session s; addVisualScene(s);
    synthesizeEventsFromRawTouch(s, CJGUI_OHOS_TOUCH_BEGIN, 42, 100, 100);
    synthesizeEventsFromRawTouch(s, CJGUI_OHOS_TOUCH_END, 42, 160, 100);
    if (countKind(s, kEvPointerBegin) != 1) return 7;
    if (countKind(s, kEvPointerEnd) != 1) return 8;
    const QueuedEvent *begin = firstOf(s, kEvPointerBegin);
    if (begin->pointerX != 100 || begin->pointerY != 100) return 9;
    if (s.events.back().pointerX != 160) return 10;
    int64_t scrollDeltas = 0;
    for (const QueuedEvent &ev : s.events) if (ev.kind == kEvScroll && ev.text != "takeover:") ++scrollDeltas;
    if (scrollDeltas != 0) return 11;
  }
  // V3 控制：纵向拖动仍由视口接管（滚动），无指针相位。
  {
    Session s; addVisualScene(s);
    synthesizeEventsFromRawTouch(s, CJGUI_OHOS_TOUCH_BEGIN, 42, 100, 100);
    synthesizeEventsFromRawTouch(s, CJGUI_OHOS_TOUCH_UPDATE, 42, 102, 140);
    synthesizeEventsFromRawTouch(s, CJGUI_OHOS_TOUCH_END, 42, 102, 160);
    if (countKind(s, kEvPointerBegin) != 0 || countKind(s, kEvPointerEnd) != 0) return 12;
    int64_t total = 0;
    for (const QueuedEvent &ev : s.events) if (ev.kind == kEvScroll) total += ev.scrollDelta;
    if (total == 0) return 13;
  }
  // V4 控制：选择胜出后转向纵向仍保持指针流（胜出不翻转，无滚动位移）。
  {
    Session s; addVisualScene(s);
    synthesizeEventsFromRawTouch(s, CJGUI_OHOS_TOUCH_BEGIN, 42, 100, 100);
    synthesizeEventsFromRawTouch(s, CJGUI_OHOS_TOUCH_UPDATE, 42, 130, 100);  // 横向过阈值
    synthesizeEventsFromRawTouch(s, CJGUI_OHOS_TOUCH_UPDATE, 42, 132, 150);  // 转纵向
    synthesizeEventsFromRawTouch(s, CJGUI_OHOS_TOUCH_END, 42, 134, 170);
    if (countKind(s, kEvPointerBegin) != 1) return 14;
    if (countKind(s, kEvPointerEnd) != 1) return 15;
    for (const QueuedEvent &ev : s.events) if (ev.kind == kEvScroll && ev.text != "takeover:") return 16;
  }
  // V5 控制：流中 CANCEL 恰好一条指针取消（40），无 END；迟到 END 不补发。
  {
    Session s; addVisualScene(s);
    synthesizeEventsFromRawTouch(s, CJGUI_OHOS_TOUCH_BEGIN, 42, 100, 100);
    synthesizeEventsFromRawTouch(s, CJGUI_OHOS_TOUCH_UPDATE, 42, 130, 100);
    synthesizeEventsFromRawTouch(s, CJGUI_OHOS_TOUCH_CANCEL, 42, 135, 100);
    synthesizeEventsFromRawTouch(s, CJGUI_OHOS_TOUCH_END, 42, 140, 100);
    if (countKind(s, kEvPointerBegin) != 1) return 17;
    if (countKind(s, kEvPointerEnd) != 0) return 18;
    if (countKind(s, CJGUI_OHOS_TOUCH_CANCEL) != 1) return 19;
  }
  return 0;
}
'''


class VisualDragClassifyTest(unittest.TestCase):
    def test_visual_drag_classify_counterexamples(self) -> None:
        mod = load()
        harness = mod.build_harness_text(MAIN)
        self.assertIn("void synthesizeEventsFromRawTouch", harness)
        with tempfile.TemporaryDirectory() as directory:
            path = pathlib.Path(directory) / "visual_drag.cpp"
            binary = pathlib.Path(directory) / "visual_drag"
            path.write_text(harness)
            subprocess.run(["clang++", "-std=c++17", "-Wall", "-Wextra", "-Werror",
                            "-Wno-unused-const-variable", "-Wno-unused-function",
                            "-I", str(mod.SNAPSHOT), "-I", str(mod.INGRESS.parent),
                            str(path), "-o", str(binary)], check=True)
            subprocess.run([str(binary)], check=True)


if __name__ == "__main__":
    unittest.main()

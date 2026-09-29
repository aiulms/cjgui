#!/usr/bin/env python3
"""Compile the renderer's real touch-gesture chain and assert tap/scroll/cancel
arbitration counterexamples.

抽取 ohos_renderer.cpp 的真实手势函数（待定→视口滚动/指针拖动仲裁、有效抬起
点击、取消与旧代、滚动位移合并、绑定冻结、捕获恰好一次终结、聚焦幂等与跨
字段草稿结算），在宿主 clang++ 下用最小 Session 副本断言。
"""
import pathlib
import subprocess
import tempfile
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]
SOURCE = ROOT / "host" / "ohos_renderer.cpp"
INGRESS = ROOT / "host" / "cjgui_ohos_ingress.h"
SNAPSHOT = ROOT / "snapshot"

MAIN_ORIGINAL = r'''
// --- 测试场景脚手架 -------------------------------------------------------
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
static void addScrollScene(Session &s) {
  SceneNode vp = makeNode(900, CJGUI_INTERNAL_RENDERER_COMPOSABLE_SCROLL_AREA, 0, 0, 400, 420, 100, -1, false);
  s.accepted.push_back(vp);
  s.accepted.push_back(makeNode(941, CJGUI_INTERNAL_RENDERER_COMPOSABLE_BUTTON, 20, 100, 180, 64, 100, 9700, true));
  s.accepted.push_back(makeNode(942, CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT_INPUT, 20, 300, 360, 64, 100, 9700, true));
  s.accepted[0].pod.projectionVersion = 100;
}
static size_t countKind(const Session &s, uint32_t kind) {
  size_t n = 0;
  for (const QueuedEvent &ev : s.events) if (ev.kind == kind) ++n;
  return n;
}
static const QueuedEvent *lastEvent(const Session &s) {
  return s.events.empty() ? nullptr : &s.events.back();
}
int main() {
  // 1. 按钮点击：BEGIN 不激活；有效抬起恰好一次 ACTIVATE。
  {
    Session s; addScrollScene(s);
    synthesizeEventsFromRawTouch(s, CJGUI_OHOS_TOUCH_BEGIN, 42, 60, 120);
    if (!s.events.empty()) return 1;
    synthesizeEventsFromRawTouch(s, CJGUI_OHOS_TOUCH_END, 42, 60, 120);
    if (s.events.size() != 1 || s.events.back().kind != kEvActivate ||
        s.events.back().nodeId != 941) return 2;
  }
  // 2. 无视口按钮上滑动：指针相位流，零 ACTIVATE（移出/拖动不误激活）。
  {
    Session s; addScrollScene(s);
    s.accepted.erase(s.accepted.begin());  // 移除视口：只剩按钮/编辑器
    synthesizeEventsFromRawTouch(s, CJGUI_OHOS_TOUCH_BEGIN, 42, 60, 120);
    synthesizeEventsFromRawTouch(s, CJGUI_OHOS_TOUCH_UPDATE, 42, 60, 170);
    synthesizeEventsFromRawTouch(s, CJGUI_OHOS_TOUCH_UPDATE, 42, 60, 185);
    synthesizeEventsFromRawTouch(s, CJGUI_OHOS_TOUCH_END, 42, 60, 190);
    if (countKind(s, kEvActivate) != 0) return 3;
    if (countKind(s, kEvPointerBegin) != 1 || countKind(s, kEvPointerEnd) != 1) return 4;
  }
  // 3. 视口内从按钮起手滑动：视口接管取消点击，纯滚动零 ACTIVATE/FOCUS；
  //    下拖 30px → 单条累计 "by:-30"（向下拖露出上方内容，offset 减小）。
  {
    Session s; addScrollScene(s);
    synthesizeEventsFromRawTouch(s, CJGUI_OHOS_TOUCH_BEGIN, 42, 60, 120);
    synthesizeEventsFromRawTouch(s, CJGUI_OHOS_TOUCH_UPDATE, 42, 60, 136);
    synthesizeEventsFromRawTouch(s, CJGUI_OHOS_TOUCH_UPDATE, 42, 60, 148);
    synthesizeEventsFromRawTouch(s, CJGUI_OHOS_TOUCH_UPDATE, 42, 60, 150);
    synthesizeEventsFromRawTouch(s, CJGUI_OHOS_TOUCH_END, 42, 60, 150);
    if (countKind(s, kEvScroll) != 1) return 5;
    if (countKind(s, kEvActivate) != 0 || countKind(s, kEvFocus) != 0) return 6;
    const QueuedEvent &tail = s.events.back();
    if (tail.nodeId != 900 || tail.text != "by:-30" || tail.scrollDelta != -30) return 7;
    if (tail.projectionVersion != 100) return 8;
  }
  // 4. 有效取消：CANCEL 终结手势，不激活；迟到的 END 不补发。
  {
    Session s; addScrollScene(s);
    synthesizeEventsFromRawTouch(s, CJGUI_OHOS_TOUCH_BEGIN, 42, 60, 120);
    synthesizeEventsFromRawTouch(s, CJGUI_OHOS_TOUCH_CANCEL, 42, 60, 121);
    synthesizeEventsFromRawTouch(s, CJGUI_OHOS_TOUCH_END, 42, 60, 121);
    if (!s.events.empty()) return 9;
  }
  // 5. Surface 换代：旧代手势不得延续（UPDATE 取消，END 不激活）。
  {
    Session s; addScrollScene(s);
    synthesizeEventsFromRawTouch(s, CJGUI_OHOS_TOUCH_BEGIN, 42, 60, 120);
    s.surfaceGeneration += 1;
    synthesizeEventsFromRawTouch(s, CJGUI_OHOS_TOUCH_UPDATE, 42, 60, 180);
    synthesizeEventsFromRawTouch(s, CJGUI_OHOS_TOUCH_END, 42, 60, 180);
    if (!s.events.empty()) return 10;
  }
  // 6. 视口移除：滚动中视口退役即取消，无后续事件。
  {
    Session s; addScrollScene(s);
    synthesizeEventsFromRawTouch(s, CJGUI_OHOS_TOUCH_BEGIN, 42, 60, 120);
    synthesizeEventsFromRawTouch(s, CJGUI_OHOS_TOUCH_UPDATE, 42, 60, 140);
    s.accepted.erase(s.accepted.begin());
    synthesizeEventsFromRawTouch(s, CJGUI_OHOS_TOUCH_UPDATE, 42, 60, 160);
    synthesizeEventsFromRawTouch(s, CJGUI_OHOS_TOUCH_END, 42, 60, 160);
    if (countKind(s, kEvScroll) != 1) return 11;
    if (lastEvent(s)->kind == kEvActivate || lastEvent(s)->kind == kEvFocus) return 12;
  }
  // 7. 新 accepted 场景后同一手势继续：版本变化产生新滚动事件（不并入旧
  //    版本尾巴），身份仍是同一视口。
  {
    Session s; addScrollScene(s);
    synthesizeEventsFromRawTouch(s, CJGUI_OHOS_TOUCH_BEGIN, 42, 60, 120);
    synthesizeEventsFromRawTouch(s, CJGUI_OHOS_TOUCH_UPDATE, 42, 60, 140);  // by:-20 v100
    s.accepted[0].pod.projectionVersion = 101;  // 下一帧 accepted
    s.accepted[1].pod.projectionVersion = 101;
    s.accepted[2].pod.projectionVersion = 101;
    synthesizeEventsFromRawTouch(s, CJGUI_OHOS_TOUCH_UPDATE, 42, 60, 150);  // by:-10 v101
    if (countKind(s, kEvScroll) != 2) return 13;
    if (s.events.back().projectionVersion != 101 || s.events.back().text != "by:-10") return 14;
  }
  // 8. 编辑器点击：有效抬起激活（FOCUS 恰一次 + 编辑上下文 + caret 点击）。
  {
    Session s; addScrollScene(s);
    synthesizeEventsFromRawTouch(s, CJGUI_OHOS_TOUCH_BEGIN, 42, 60, 320);
    if (!s.events.empty() || s.editing) return 15;
    synthesizeEventsFromRawTouch(s, CJGUI_OHOS_TOUCH_END, 42, 60, 320);
    if (countKind(s, kEvFocus) != 1) return 16;
    if (!s.editing || s.editingNodeId != 942 || !s.editingContextLive) return 17;
    if (!s.editingTapPending || !s.focusNotifyPending) return 18;
  }
  // 9. 无视口编辑器上拖动：保持待定（不滚动、不产生指针流），抬起按点击。
  {
    Session s; addScrollScene(s);
    s.accepted.erase(s.accepted.begin());
    synthesizeEventsFromRawTouch(s, CJGUI_OHOS_TOUCH_BEGIN, 42, 60, 320);
    synthesizeEventsFromRawTouch(s, CJGUI_OHOS_TOUCH_UPDATE, 42, 60, 360);
    if (!s.events.empty()) return 19;
    synthesizeEventsFromRawTouch(s, CJGUI_OHOS_TOUCH_END, 42, 60, 320);
    if (countKind(s, kEvFocus) != 1) return 20;
  }
  // 10. 已激活编辑器长按：位移不接管为滚动；≥400ms 抬起全选。
  {
    Session s; addScrollScene(s);
    s.editing = true; s.editingNodeId = 942; s.editingResourceId = 9700;
    s.editingText = utf8ToUtf16("abcdef");
    synthesizeEventsFromRawTouch(s, CJGUI_OHOS_TOUCH_BEGIN, 42, 60, 320);
    synthesizeEventsFromRawTouch(s, CJGUI_OHOS_TOUCH_UPDATE, 42, 60, 380);
    if (!s.events.empty()) return 21;
    struct timespec ts = {0, 450 * 1000 * 1000};
    nanosleep(&ts, nullptr);
    synthesizeEventsFromRawTouch(s, CJGUI_OHOS_TOUCH_END, 42, 60, 380);
    if (s.selStartUtf16 != 0 || s.selEndUtf16 != 6) return 22;
    if (countKind(s, kEvFocus) != 0) return 23;  // 已激活：无重复焦点事件
  }
  // 11. 待定手势移出目标后抬起：不激活（点击容差内的移出）。
  {
    Session s; addScrollScene(s);
    synthesizeEventsFromRawTouch(s, CJGUI_OHOS_TOUCH_BEGIN, 42, 60, 120);
    synthesizeEventsFromRawTouch(s, CJGUI_OHOS_TOUCH_UPDATE, 42, 60, 128);  // < 阈值
    synthesizeEventsFromRawTouch(s, CJGUI_OHOS_TOUCH_END, 42, 200, 380);    // 抬在编辑器上
    if (countKind(s, kEvActivate) != 0) return 24;
    if (countKind(s, kEvFocus) != 0) return 25;  // 命中变成 942：身份不符不激活
  }
  // 12. 只读节点不可激活；但其包含视口滚动照常。
  {
    Session s; addScrollScene(s);
    s.accepted[2].pod.isReadOnly = 1;
    synthesizeEventsFromRawTouch(s, CJGUI_OHOS_TOUCH_BEGIN, 42, 60, 320);
    synthesizeEventsFromRawTouch(s, CJGUI_OHOS_TOUCH_END, 42, 60, 320);
    if (!s.events.empty() || s.editing) return 26;
    Session s2; addScrollScene(s2);
    s2.accepted[2].pod.isReadOnly = 1;
    synthesizeEventsFromRawTouch(s2, CJGUI_OHOS_TOUCH_BEGIN, 60, 320);
    synthesizeEventsFromRawTouch(s2, CJGUI_OHOS_TOUCH_UPDATE, 60, 380);
    if (countKind(s2, kEvScroll) != 1) return 27;
  }
  return 0;
}
'''

MAIN_REVIEW = r'''
// --- 触摸包指导接续 B/C 反例 ----------------------------------------------
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
static void addScrollScene(Session &s) {
  s.accepted.push_back(makeNode(900, CJGUI_INTERNAL_RENDERER_COMPOSABLE_SCROLL_AREA, 0, 0, 400, 420, 100, -1, false));
  s.accepted.push_back(makeNode(941, CJGUI_INTERNAL_RENDERER_COMPOSABLE_BUTTON, 20, 100, 180, 64, 100, 9700, true));
  s.accepted.push_back(makeNode(942, CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT_INPUT, 20, 300, 360, 64, 100, 9700, true));
}
static void addPlainScene(Session &s) {
  s.accepted.push_back(makeNode(41, CJGUI_INTERNAL_RENDERER_COMPOSABLE_BUTTON, 10, 10, 180, 60, 100, 9700, true));
  s.accepted.push_back(makeNode(42, CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT_INPUT, 10, 200, 300, 60, 100, 9700, true));
}
static size_t countKind(const Session &s, uint32_t kind) {
  size_t n = 0;
  for (const QueuedEvent &ev : s.events) if (ev.kind == kind) ++n;
  return n;
}
int main() {
  // R1 快速轻扫：BEGIN 后无任何 UPDATE，END 落点远超阈值——不得当点击激活；
  //    全部位移在 END 结算为一次滚动（尾差消费 + 阈值重判）。
  {
    Session s; addScrollScene(s);
    synthesizeEventsFromRawTouch(s, CJGUI_OHOS_TOUCH_BEGIN, 42, 60, 120);
    synthesizeEventsFromRawTouch(s, CJGUI_OHOS_TOUCH_END, 42, 60, 250);
    if (countKind(s, kEvActivate) != 0) return 100;
    if (countKind(s, kEvScroll) != 1) return 101;
    if (s.events.back().scrollDelta != -130) return 102;
  }
  // R2 小数位移：0.5px 连续样本不得逐样本截断丢失（截断总和为 0），也
  //    不得产生 by:0 事件；交付总数与未压缩参考（13.0px → 13px）一致。
  {
    Session s; addScrollScene(s);
    synthesizeEventsFromRawTouch(s, CJGUI_OHOS_TOUCH_BEGIN, 42, 60, 100);
    for (int i = 1; i <= 26; ++i) {
      synthesizeEventsFromRawTouch(s, CJGUI_OHOS_TOUCH_UPDATE, 42, 60, 100.0f + 0.5f * i);
    }
    synthesizeEventsFromRawTouch(s, CJGUI_OHOS_TOUCH_END, 42, 60, 113.0f);
    for (const QueuedEvent &ev : s.events) {
      if (ev.kind == kEvScroll && ev.scrollDelta == 0) return 103;
    }
    int64_t total = 0;
    for (const QueuedEvent &ev : s.events) if (ev.kind == kEvScroll) total += ev.scrollDelta;
    if (total != -13) return 104;
    if (countKind(s, kEvScroll) != 1) return 119;  // 同身份压缩为单一事件
  }
  // R3（被 N4 取代并修正）：纯版本变化不构成换绑判据——同绑定换帧必须
  //    存活（激活以当前版本 101 发出）；真换绑由 N4 的语义冻结拒绝。
  {
    Session s; addScrollScene(s);
    synthesizeEventsFromRawTouch(s, CJGUI_OHOS_TOUCH_BEGIN, 42, 60, 120);
    s.accepted[1].pod.projectionVersion = 101;  // 同绑定换帧
    synthesizeEventsFromRawTouch(s, CJGUI_OHOS_TOUCH_END, 42, 60, 120);
    if (countKind(s, kEvActivate) != 1) return 105;
    if (s.events.back().projectionVersion != 101) return 120;
  }
  // R4 捕获恰好一次终结：指针相位流（37 已入队）后系统 CANCEL → 恰好一条
  //    指针取消（40）沿旧身份送达，无 39 END，后续迟到 END 不再补发。
  {
    Session s; addPlainScene(s);
    synthesizeEventsFromRawTouch(s, CJGUI_OHOS_TOUCH_BEGIN, 42, 30, 30);
    synthesizeEventsFromRawTouch(s, CJGUI_OHOS_TOUCH_UPDATE, 42, 30, 90);
    if (countKind(s, kEvPointerBegin) != 1) return 106;
    synthesizeEventsFromRawTouch(s, CJGUI_OHOS_TOUCH_CANCEL, 42, 30, 95);
    if (countKind(s, CJGUI_OHOS_TOUCH_CANCEL) != 1) return 107;  // 恰好一条指针取消（40）
    if (countKind(s, kEvPointerEnd) != 0) return 108;
    size_t before = s.events.size();
    synthesizeEventsFromRawTouch(s, CJGUI_OHOS_TOUCH_END, 42, 30, 95);
    if (s.events.size() != before) return 109;
  }
  // R5 重复聚焦幂等：同一已激活节点再次 focus 不得换 contextId（代理仍持
  //    旧编号；换号即 stale 拒绝后续输入）。
  {
    Session s; addScrollScene(s);
    synthesizeEventsFromRawTouch(s, CJGUI_OHOS_TOUCH_BEGIN, 42, 60, 320);
    synthesizeEventsFromRawTouch(s, CJGUI_OHOS_TOUCH_END, 42, 60, 320);
    int64_t ctx = s.editingContextId;
    beginEditingOnNodeLocked(s, s.accepted[2]);
    if (s.editingContextId != ctx) return 110;
  }
  // R6 点击按钮结束编辑：恰好一次激活；失焦结算沿既有 pump 延迟路径
  //    （合成时不产生文本事件）。
  {
    Session s; addScrollScene(s);
    synthesizeEventsFromRawTouch(s, CJGUI_OHOS_TOUCH_BEGIN, 42, 60, 320);
    synthesizeEventsFromRawTouch(s, CJGUI_OHOS_TOUCH_END, 42, 60, 320);  // 激活 942
    s.editingText = utf8ToUtf16("AB");
    s.caretUtf16 = 2; s.selStartUtf16 = 2; s.selEndUtf16 = 2;
    s.previewActive = true; s.previewText = utf8ToUtf16("XY");
    s.previewStart = 2; s.previewEnd = 2;
    synthesizeEventsFromRawTouch(s, CJGUI_OHOS_TOUCH_BEGIN, 42, 60, 120);  // 按下按钮 941
    synthesizeEventsFromRawTouch(s, CJGUI_OHOS_TOUCH_END, 42, 60, 120);
    if (countKind(s, kEvActivate) != 1) return 111;
    if (countKind(s, kEvTextChanged) != 0) return 112;
    if (!s.editorRetired || !s.pendingSettleOnDetach) return 113;
  }
  // N1 二次复核：跨阈值后回到起点不恢复点击资格（阈值闰不可逆）。
  //    BEGIN(60,120)→MOVE(60,150)→MOVE(60,120)→END(60,120)：
  //    未压缩真值 activate=0 且发生过滚动；压缩成最新样本不得变回点击。
  {
    Session s; addScrollScene(s);
    synthesizeEventsFromRawTouch(s, CJGUI_OHOS_TOUCH_BEGIN, 42, 60, 120);
    synthesizeEventsFromRawTouch(s, CJGUI_OHOS_TOUCH_UPDATE, 42, 60, 150);
    synthesizeEventsFromRawTouch(s, CJGUI_OHOS_TOUCH_UPDATE, 42, 60, 120);
    synthesizeEventsFromRawTouch(s, CJGUI_OHOS_TOUCH_END, 42, 60, 120);
    if (countKind(s, kEvActivate) != 0) return 130;
    if (countKind(s, kEvScroll) < 1) return 131;
  }
  // N2 END 尾段：BEGIN y100→MOVE y80→END y50，总滚动意图 50（含 END 尾差）。
  {
    Session s; addScrollScene(s);
    synthesizeEventsFromRawTouch(s, CJGUI_OHOS_TOUCH_BEGIN, 42, 60, 100);
    synthesizeEventsFromRawTouch(s, CJGUI_OHOS_TOUCH_UPDATE, 42, 60, 80);
    synthesizeEventsFromRawTouch(s, CJGUI_OHOS_TOUCH_END, 42, 60, 50);
    int64_t total = 0;
    for (const QueuedEvent &ev : s.events) if (ev.kind == kEvScroll) total += ev.scrollDelta;
    if (total != 50) return 132;
  }
  // N3 反向分段：offset=0 时 -30/+30 不得合并为 0；反号滚动按序交付，
  //    由共享 viewport 逐段夹紧（净效果 30）。
  {
    Session s; addScrollScene(s);
    synthesizeEventsFromRawTouch(s, CJGUI_OHOS_TOUCH_BEGIN, 42, 60, 100);
    synthesizeEventsFromRawTouch(s, CJGUI_OHOS_TOUCH_UPDATE, 42, 60, 70);   // 上滑 30 → +30
    synthesizeEventsFromRawTouch(s, CJGUI_OHOS_TOUCH_UPDATE, 42, 60, 100);  // 下滑 30 → -30
    synthesizeEventsFromRawTouch(s, CJGUI_OHOS_TOUCH_END, 42, 60, 100);
    int64_t total = 0;
    size_t positive = 0, negative = 0;
    for (const QueuedEvent &ev : s.events) if (ev.kind == kEvScroll) {
      total += ev.scrollDelta;
      if (ev.scrollDelta > 0) ++positive;
      if (ev.scrollDelta < 0) ++negative;
    }
    if (positive < 1 || negative < 1) return 133;  // 反号不得并入同段
    if (total != 0) return 134;  // 无夹紧信息时净和为零，夹紧由核心按段执行
  }
  // N4 绑定语义冻结：同槽换 semanticId（真换绑）→ 激活拒绝；同绑定换帧
  //    （semanticId 不变、版本推进）→ 激活以当前版本发出（存活）。
  {
    Session s; addScrollScene(s);
    synthesizeEventsFromRawTouch(s, CJGUI_OHOS_TOUCH_BEGIN, 42, 60, 120);
    s.accepted[1].semanticId = "hand-scroll-swapped";  // 真换绑：核心签发新代
    s.accepted[1].pod.acceptedBindingEpoch = 2;
    synthesizeEventsFromRawTouch(s, CJGUI_OHOS_TOUCH_END, 42, 60, 120);
    if (countKind(s, kEvActivate) != 0) return 135;
    Session s2; addScrollScene(s2);
    synthesizeEventsFromRawTouch(s2, CJGUI_OHOS_TOUCH_BEGIN, 60, 120);
    s2.accepted[1].pod.projectionVersion = 101;  // 同绑定换帧
    synthesizeEventsFromRawTouch(s2, CJGUI_OHOS_TOUCH_END, 60, 120);
    if (countKind(s2, kEvActivate) != 1) return 136;
    if (s2.events.back().projectionVersion != 101) return 137;
  }
  // B: A's queued CANCEL after B BEGIN must carry A and leave B alive. All
  // derived phases must retain the exact per-sample key, including delayed BEGIN.
  {
    Session s; addScrollScene(s); s.accepted.erase(s.accepted.begin());
    touch(s, CJGUI_OHOS_TOUCH_BEGIN, 71, 60, 120);
    touch(s, CJGUI_OHOS_TOUCH_UPDATE, 71, 60, 160);
    touch(s, CJGUI_OHOS_TOUCH_BEGIN, 72, 60, 120);
    touch(s, CJGUI_OHOS_TOUCH_CANCEL, 71, 60, 160);
    if (!s.gesture.active || s.gesture.gestureEpoch != 72) return 138;
    touch(s, CJGUI_OHOS_TOUCH_UPDATE, 72, 60, 165);
    touch(s, CJGUI_OHOS_TOUCH_END, 72, 60, 170);
    int aCancel = 0, bEnd = 0;
    for (const auto &ev : s.events) {
      if (ev.kind == kEvPointerCancel && ev.gestureEpoch == 71) ++aCancel;
      if (ev.kind == kEvPointerEnd && ev.gestureEpoch == 72) ++bEnd;
      if (ev.gestureEpoch != 71 && ev.gestureEpoch != 72) return 139;
      if (ev.appInstance != 1 || ev.componentInstance != 2 ||
          ev.surfaceGeneration != 7 || ev.pointerId != 0) return 140;
    }
    if (aCancel != 1 || bEnd != 1) return 141;
  }
  // Binding A->B->A still invalidates A's pending tap despite equal final text.
  {
    Session s; addScrollScene(s);
    touch(s, CJGUI_OHOS_TOUCH_BEGIN, 73, 60, 120);
    s.accepted[1].pod.acceptedBindingEpoch = 2;
    s.accepted[1].pod.acceptedBindingEpoch = 3;
    touch(s, CJGUI_OHOS_TOUCH_END, 73, 60, 120);
    if (countKind(s, kEvActivate) != 0) return 142;
  }
  // Active cancellation enters the real exported native FFI. A stale key may
  // differ in any dimension; only B's exact key may terminate B once.
  {
    Session s; addScrollScene(s); s.accepted.erase(s.accepted.begin());
    g_testSession = &s;
    touch(s, CJGUI_OHOS_TOUCH_BEGIN, 72, 60, 120);
    touch(s, CJGUI_OHOS_TOUCH_UPDATE, 72, 60, 160);
    if (!s.gesture.active) return 143;
    const uint64_t app = s.gesture.appInstance;
    const uint64_t component = s.gesture.componentInstance;
    const uint64_t generation = s.gesture.surfaceGeneration;
    const int64_t pointer = s.gesture.pointerId;
    const uint64_t epoch = s.gesture.gestureEpoch;
    if (cjgui_internal_renderer_cancel_composable_pointer_capture_gesture_key(
            1, app, component, generation, pointer, 71) != CJGUI_INTERNAL_RENDERER_OK ||
        !s.gesture.active) return 144;
    if (cjgui_internal_renderer_cancel_composable_pointer_capture_gesture_key(
            1, app + 1, component, generation, pointer, epoch) != CJGUI_INTERNAL_RENDERER_OK ||
        !s.gesture.active) return 145;
    if (cjgui_internal_renderer_cancel_composable_pointer_capture_gesture_key(
            1, app, component + 1, generation, pointer, epoch) != CJGUI_INTERNAL_RENDERER_OK ||
        !s.gesture.active) return 146;
    if (cjgui_internal_renderer_cancel_composable_pointer_capture_gesture_key(
            1, app, component, generation + 1, pointer, epoch) != CJGUI_INTERNAL_RENDERER_OK ||
        !s.gesture.active) return 147;
    if (cjgui_internal_renderer_cancel_composable_pointer_capture_gesture_key(
            1, app, component, generation, pointer + 1, epoch) != CJGUI_INTERNAL_RENDERER_OK ||
        !s.gesture.active) return 148;
    if (cjgui_internal_renderer_cancel_composable_pointer_capture_gesture_key(
            1, app, component, generation, pointer, epoch) != CJGUI_INTERNAL_RENDERER_OK ||
        s.gesture.active || countKind(s, kEvPointerCancel) != 1) return 149;
    if (cjgui_internal_renderer_cancel_composable_pointer_capture_gesture_key(
            1, app, component, generation, pointer, epoch) != CJGUI_INTERNAL_RENDERER_OK ||
        countKind(s, kEvPointerCancel) != 1) return 150;
    g_testSession = nullptr;
  }
  // R7 跨字段直接切换：A 活草稿 → 点击另一编辑器 B：A 恰好结算一次，B 以
  //    新上下文和 accepted 值起步，A 的缓冲不带入 B。
  {
    Session s; addScrollScene(s);
    synthesizeEventsFromRawTouch(s, CJGUI_OHOS_TOUCH_BEGIN, 42, 60, 320);
    synthesizeEventsFromRawTouch(s, CJGUI_OHOS_TOUCH_END, 42, 60, 320);
    s.editingText = utf8ToUtf16("AB");
    s.caretUtf16 = 2; s.selStartUtf16 = 2; s.selEndUtf16 = 2;
    s.previewActive = true; s.previewText = utf8ToUtf16("XY");
    s.previewStart = 2; s.previewEnd = 2;
    s.accepted.push_back(makeNode(943, CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT_INPUT, 20, 380, 360, 64, 100, 9700, true));
    synthesizeEventsFromRawTouch(s, CJGUI_OHOS_TOUCH_BEGIN, 42, 60, 400);
    synthesizeEventsFromRawTouch(s, CJGUI_OHOS_TOUCH_END, 42, 60, 400);  // 激活 943
    if (!s.editing || s.editingNodeId != 943) return 115;
    bool aSettledOnce = false;
    size_t aEvents = 0;
    for (const QueuedEvent &ev : s.events) {
      if (ev.kind == kEvTextChanged && ev.nodeId == 942) { ++aEvents; if (ev.text == "ABXY") aSettledOnce = true; }
    }
    if (aEvents != 1 || !aSettledOnce) return 116;
    if (!s.editingText.empty()) return 117;  // B 从 accepted 值（空）起步
  }
  return 0;
}
'''

MAIN_SCROLL_ACCOUNTING = MAIN_ORIGINAL.split("int main() {")[0] + r'''
int main() {
  Session s; addScrollScene(s);
  touch(s, CJGUI_OHOS_TOUCH_BEGIN, 77, 60, 120);
  touch(s, CJGUI_OHOS_TOUCH_UPDATE, 77, 60, 136.25f);
  touch(s, CJGUI_OHOS_TOUCH_UPDATE, 77, 60, 148.75f);
  touch(s, CJGUI_OHOS_TOUCH_END, 77, 60, 151.5f);
  if (g_scrollLog.empty()) return 81;
  if (g_scrollFormat.find("gesture-scroll-terminal") == std::string::npos ||
      g_scrollFormat.find("rawDy=") == std::string::npos ||
      g_scrollFormat.find("remainder=") == std::string::npos) return 82;
  // app/component/surface/pointer/epoch, sample count, raw displacement,
  // integer pixels delivered to the shared viewport and retained remainder.
  if (g_scrollLog.find("1|2|7|0|77|3|31.5|31|0.5|") == std::string::npos) return 83;
  return 0;
}
'''


def extract_method(text: str, signature: str) -> str:
    start = text.index(signature)
    opening = text.index("{", start)
    depth = 0
    for index in range(opening, len(text)):
        depth += (text[index] == "{") - (text[index] == "}")
        if depth == 0:
            return text[start:index + 1]
    raise ValueError("unterminated method")


def extract_constants(text: str) -> str:
    lines = []
    for line in text.splitlines():
        if line.startswith("constexpr uint32_t kKind") or line.startswith("constexpr uint32_t kEv"):
            lines.append(line)
    return "\n".join(lines)


REPLICA = """
struct Session {
__TOUCHGESTURE__
  TouchGesture gesture;
  uint64_t surfaceGeneration = 7;
  std::vector<SceneNode> accepted;
  std::deque<QueuedEvent> events;
  int64_t textPressBeginMs = 0;
  bool editing = false;
  bool editorRetired = false;
  uint64_t editingNodeId = 0;
  int64_t editingResourceId = -1;
  uint32_t editingNodeKind = 0;
  uint64_t editingProjectionVersion = 0;
  int64_t editingContextId = 0;
  std::string editingFieldName;
  uint64_t editingContextGeneration = 0;
  uint64_t editingContextBaseVersion = 0;
  bool editingContextLive = false;
  bool reconcileNotifyPending = false;
  int64_t reconcileOldContextId = 0;
  bool pendingSettleOnDetach = false;
  bool pendingImeDetach = false;
  std::u16string editingText;
  uint32_t caretUtf16 = 0;
  uint32_t selStartUtf16 = 0;
  uint32_t selEndUtf16 = 0;
  bool previewActive = false;
  std::u16string previewText;
  uint32_t previewStart = 0;
  uint32_t previewEnd = 0;
  bool markedActive = false;
  bool focusNotifyPending = false;
  double editingTapX = 0.0;
  bool editingTapPending = false;
  int64_t detachContextId = 0;
  std::string detachFieldName;
  uint64_t touchGestureEpoch = 0;
  bool editingContextRevealRequested = false;
};
static std::u16string composedBuffer(Session &s) { return s.editingText; }
static std::string utf16ToUtf8(const std::u16string &text) {
  std::string out;
  for (char16_t c : text) out.push_back(static_cast<char>(c));
  return out;
}
"""

STUBS = """
#define RLOGI(...) do {} while (0)
#define RLOGW(...) do {} while (0)
struct RedrawJob {};
struct RenderThread {
  template <class T> void post(T) {}
  static bool pointInsideClips(const CjguiInternalRendererComposableNode &n, float x, float y) {
    (void)n; (void)x; (void)y; return true;
  }
};
static RenderThread g_render;
static std::atomic<int64_t> g_nextEditingContextId{1};
static std::u16string utf8ToUtf16(const std::string &text) {
  std::u16string out;
  for (unsigned char c : text) out.push_back(static_cast<char16_t>(c));
  return out;
}
using SceneNodePod = CjguiInternalRendererComposableNode;
struct SceneNode {
  SceneNodePod pod{};
  std::string semanticId;
  std::string label;
  std::string value;
};
"""

# 依赖次序：text_changed/settle 引用 composedBuffer/utf16ToUtf8；
# begin_edit 引用 settle；synthesize 引用其余。
EXTRACT_ORDER = ["hit", "viewport_hit", "identity", "stamp", "cancel", "end_edit",
                 "text_changed", "settle", "begin_edit", "scroll_intent",
                 "consume", "tap", "synth"]


def build_harness_text(main_text: str) -> str:
    source = SOURCE.read_text()
    gesture = extract_method(source, "    struct TouchGesture {") + ";"
    queued = extract_method(source, "struct QueuedEvent {") + ";"
    raw = extract_method(source, "struct RawTouchSample {") + ";"
    constants = extract_constants(source)
    signatures = {
        "hit": "bool hitTestAccepted(Session &s, float x, float y, size_t *outIndex)",
        "viewport_hit": "bool scrollAreaIndexContainingPoint(Session &s, float x, float y, size_t *outIndex)",
        "identity": ("bool sceneIndexByIdentityLocked(Session &s, uint64_t nodeId, int64_t resourceId, uint32_t nodeKind,\n"
                     "                                size_t *outIndex)"),
        "stamp": "void stampTouchEvent(const Session &s, QueuedEvent &ev)",
        "cancel": "void cancelTouchGestureLocked(Session &s)",
        "end_edit": "void enqueueEndEditingForTapLocked(Session &s)",
        "text_changed": "void editorEnqueueTextChanged(Session &s)",
        "settle": "bool settleComposedBufferOnBlurLocked(Session &s)\n{",
        "begin_edit": "void beginEditingOnNodeLocked(Session &s, const SceneNode &node)",
        "scroll_intent": ("void appendScrollIntentLocked(Session &s, uint64_t nodeId, int64_t resourceId, uint64_t version,\n"
                          "                              int64_t delta)\n{"),
        "consume": "int64_t consumeScrollSampleLocked(Session &s, float dySample)",
        "tap": "void executePendingTapLocked(Session &s, float x, float y, int64_t nowMs)",
        "synth": "void synthesizeEventsFromRawTouch(Session &s, const RawTouchSample &sample)",
    }
    body = "\n".join(extract_method(source, signatures[name]) for name in EXTRACT_ORDER)
    harness = '#include "cjgui_internal_renderer.h"\n#include "cjgui_ohos_ingress.h"\n'
    harness += '#include <atomic>\n#include <cmath>\n#include <cstdint>\n#include <deque>\n'
    harness += '#include <memory>\n#include <mutex>\n#include <string>\n#include <vector>\n'
    harness += constants + "\n"
    adapter = '''
static void touch(Session &s, uint32_t action, uint64_t epoch, float x, float y,
                  uint64_t generation = 7) {
  synthesizeEventsFromRawTouch(s, RawTouchSample{action, x, y, 1, 2, generation, 0, epoch});
}
static void touch(Session &s, uint32_t action, float x, float y) {
  touch(s, action, 42, x, y);
}
'''
    sessions = '''
static struct { std::mutex lock; } g_sessions;
static Session *g_testSession = nullptr;
static Session *lookupSessionLocked(uint64_t session) {
  return session == 1 ? g_testSession : nullptr;
}
'''
    exact_cancel = extract_method(source,
        "CjguiInternalRendererStatus cjgui_internal_renderer_cancel_composable_pointer_capture_gesture_key(")
    harness += STUBS + queued + raw + REPLICA.replace("__TOUCHGESTURE__", gesture)
    harness += sessions + body + exact_cancel + adapter
    harness += main_text.replace("synthesizeEventsFromRawTouch(", "touch(")
    return harness


class TouchGestureNativeTest(unittest.TestCase):
    def test_terminal_scroll_accounting_uses_the_real_renderer_chain(self) -> None:
        harness = build_harness_text(MAIN_SCROLL_ACCOUNTING)
        harness = harness.replace("#define RLOGI(...) do {} while (0)", r'''
#include <sstream>
static std::string g_scrollFormat;
static std::string g_scrollLog;
template <class... Args> static void captureLog(const char *format, Args... args) {
  if (std::string(format).find("gesture-scroll-terminal") == std::string::npos) return;
  g_scrollFormat = format;
  std::ostringstream stream;
  ((stream << args << "|"), ...);
  g_scrollLog = stream.str();
}
#define RLOGI(...) captureLog(__VA_ARGS__)
''')
        with tempfile.TemporaryDirectory() as directory:
            path = pathlib.Path(directory) / "scroll_accounting.cpp"
            binary = pathlib.Path(directory) / "scroll_accounting"
            path.write_text(harness)
            subprocess.run(["clang++", "-std=c++17", "-Wall", "-Wextra", "-Werror",
                            "-Wno-unused-const-variable", "-Wno-unused-function",
                            "-I", str(SNAPSHOT), "-I", str(INGRESS.parent),
                            str(path), "-o", str(binary)], check=True)
            subprocess.run([str(binary)], check=True)

    def test_touch_chain_arbitration_counterexamples(self) -> None:
        harness = build_harness_text(MAIN_ORIGINAL)
        self.assertIn("struct TouchGesture", harness)
        self.assertIn("void synthesizeEventsFromRawTouch", harness)
        self.assertIn("scrollDelta", harness)
        with tempfile.TemporaryDirectory() as directory:
            path = pathlib.Path(directory) / "touch_gesture.cpp"
            binary = pathlib.Path(directory) / "touch_gesture"
            path.write_text(harness)
            subprocess.run(["clang++", "-std=c++17", "-Wall", "-Wextra", "-Werror",
                            "-Wno-unused-const-variable",
                            "-I", str(SNAPSHOT), "-I", str(INGRESS.parent),
                            str(path), "-o", str(binary)], check=True)
            subprocess.run([str(binary)], check=True)

    def test_touch_lifecycle_review_counterexamples(self) -> None:
        """触摸包指导接续 B/C 反例：快速轻扫、小数位移、绑定冻结、捕获终结、
        重复聚焦幂等与跨字段草稿结算。"""
        harness = build_harness_text(MAIN_REVIEW)
        self.assertIn("void synthesizeEventsFromRawTouch", harness)
        with tempfile.TemporaryDirectory() as directory:
            path = pathlib.Path(directory) / "touch_review.cpp"
            binary = pathlib.Path(directory) / "touch_review"
            path.write_text(harness)
            subprocess.run(["clang++", "-std=c++17", "-Wall", "-Wextra", "-Werror",
                            "-Wno-unused-const-variable",
                            "-I", str(SNAPSHOT), "-I", str(INGRESS.parent),
                            str(path), "-o", str(binary)], check=True)
            subprocess.run([str(binary)], check=True)


if __name__ == "__main__":
    unittest.main()

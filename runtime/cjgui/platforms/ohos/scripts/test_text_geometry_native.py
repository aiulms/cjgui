#!/usr/bin/env python3
"""H1-3：正文几何的确定性反例（绘制 / 光标 / 选区高亮 / 触摸命中同源）。

真实缺陷（2026-09-30 鸿蒙模拟器上可见）：多行正文节点比正文高时，字形按
`(盒高 - 文本高) / 2` 垂直居中绘制，于是短文档落在画面正中；而选区高亮按
`pod.y` 绘制、命中测试只用 `tapX`（前缀宽度二分，且 `longestLine` 对折行前缀
不是该行宽度）、绘制与命中各用一个硬编码内缩（6.0 / 7.0）。结果是"看到的"
和"点中的"不是同一行同一列。

本 harness 把绘制路径（`drawNodeText`）与命中路径（`executeCaretHitTest`）一起
摘出来，用同一套假排版模型跑，断言：
  1. 多行正文从节点上沿开始排版（不被居中）；单行 label 仍在盒内居中；
  2. 跨行选区高亮是**每行一段**矩形，且各段落在自己那一行的 y 带内；
  3. 光标矩形来自排版给出的那一行（第二行的光标不在第一行）；
  4. 往返一致：点在光标画出的位置上，命中测试返回同一个码元位置；
  5. 命中测试传给排版的坐标是**几何原点相对**坐标（内缩只有一处定义）；
  6. 排版答不出位置时 fail-closed（不把 0 当成命中结果）。

摘掉任一守卫，同一套断言必须失败（见 NEGATIVE_CONTROLS）。
"""
import pathlib
import subprocess
import sys
import tempfile
import unittest
import test_grapheme_service_native as system_grapheme

ROOT = pathlib.Path(__file__).resolve().parents[1]
SOURCE = ROOT / "host" / "ohos_renderer.cpp"
INGRESS = ROOT / "host" / "cjgui_ohos_ingress.h"

STUBS = r'''
#include <algorithm>
#include <array>
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <cstddef>
#include <cstring>
#include <string>
#include <vector>

template <class... Args> static void cjguiLogSinkStub(Args&&...) {}
#define RLOGI(...) cjguiLogSinkStub(__VA_ARGS__)
#define RLOGW(...) cjguiLogSinkStub(__VA_ARGS__)

enum CjguiInternalRendererStatus {
  CJGUI_INTERNAL_RENDERER_OK = 0,
  CJGUI_INTERNAL_RENDERER_VIEW_INVALIDATED = 10,
  CJGUI_INTERNAL_RENDERER_GEOMETRY_EMPTY = 18,
  CJGUI_INTERNAL_RENDERER_PRESENT_PENDING = 20,
  CJGUI_INTERNAL_RENDERER_INVALID_UTF8 = 14,
  CJGUI_INTERNAL_RENDERER_TEXT_RESOURCE_BUDGET_EXCEEDED = 16,
  CJGUI_INTERNAL_RENDERER_GRAPHEME_BOUNDARY_INVALID = 24,
  CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED = 32,
  CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR = 99
};
extern "C" CjguiInternalRendererStatus cjgui_internal_renderer_grapheme_cluster_range(
    const char *, uint64_t, uint64_t, uint64_t *, uint64_t *);
enum { FONT_WEIGHT_400 = 400 };

typedef enum {
  RECT_HEIGHT_STYLE_TIGHT = 0,
  RECT_HEIGHT_STYLE_MAX,
  RECT_HEIGHT_STYLE_INCLUDELINESPACEMIDDLE,
  RECT_HEIGHT_STYLE_INCLUDELINESPACETOP,
  RECT_HEIGHT_STYLE_INCLUDELINESPACEBOTTOM,
  RECT_HEIGHT_STYLE_STRUCT
} OH_Drawing_RectHeightStyle;
typedef enum {
  RECT_WIDTH_STYLE_TIGHT = 0,
  RECT_WIDTH_STYLE_MAX
} OH_Drawing_RectWidthStyle;

// ---------------------------------------------------------------------------
// 假排版模型：每码元推进 = fontSize * 0.6，行高 = fontSize * 1.4，
// 折行按约束宽度，硬换行按 '\n'。它必须忠实实现被测代码依赖的三件事：
// GetRectsForRange 逐行给盒、坐标→位置解析按 (x,y) 定位行、longestLine 是
// 最长行宽（旧命中测试正是败在这里）。
// ---------------------------------------------------------------------------
static double g_advanceFactor = 0.6;
static double g_lineHeightFactor = 1.4;
static bool g_stubPositionUnavailable = false;
static int g_paintCalls = 0;
static uint64_t g_layoutSerial=0,g_lastPaintedSerial=0,g_lastHitSerial=0;
static double g_paintX = 0.0;
static double g_paintY = 0.0;
static std::vector<std::array<double, 4>> g_drawnRects;  // left, top, right, bottom
static bool g_hitCoordRecorded = false;
static double g_hitDx = 0.0;
static double g_hitDy = 0.0;

struct FakeLine {
  size_t start = 0;
  size_t end = 0;
  double top = 0.0;
  double bottom = 0.0;
};
struct OH_Drawing_LineMetrics { double x=0,y=0,height=0,width=0; size_t startIndex=0,endIndex=0; };
struct FakeTypography {
  uint64_t serial=0;
  std::u16string units;
  double fontSize = 14.0;
  double width = 100.0;
  std::vector<FakeLine> lines;
  double height = 0.0;
  double longestLine = 0.0;
  double maxWidth = 0.0;
  double baseline = 0.0;
};
struct FakeTextBox { std::vector<std::array<double, 4>> boxes; };
struct FakePositionAndAffinity { size_t position = 0; };
struct FakeCanvas { int id = 1; };
struct FakeBrush { uint32_t color = 0; };
struct FakeRect { float left = 0, top = 0, right = 0, bottom = 0; };
struct OH_Drawing_Point { float x=0,y=0; };
struct OH_Drawing_Range { size_t start=0,end=0; };
struct FakeTextStyle { double fontSize = 14.0; uint32_t color = 0; };
struct FakeTypographyStyle { int unused = 0; };
struct FakeHandler { std::string text; double fontSize = 14.0; };
struct FakeFontCollection { int unused = 0; };

typedef FakeTypography OH_Drawing_Typography;
typedef FakeTextBox OH_Drawing_TextBox;
typedef FakePositionAndAffinity OH_Drawing_PositionAndAffinity;
typedef FakeCanvas OH_Drawing_Canvas;
typedef FakeBrush OH_Drawing_Brush;
typedef FakeRect OH_Drawing_Rect;
typedef FakeTextStyle OH_Drawing_TextStyle;
typedef FakeTypographyStyle OH_Drawing_TypographyStyle;
typedef FakeHandler OH_Drawing_TypographyCreate;
typedef FakeFontCollection OH_Drawing_FontCollection;

static FakeTextStyle *OH_Drawing_CreateTextStyle() { return new FakeTextStyle(); }
static void OH_Drawing_SetTextStyleFontSize(FakeTextStyle *s, double size) { s->fontSize = size; }
static void OH_Drawing_SetTextStyleFontWeight(FakeTextStyle *s, int weight) { (void)s; (void)weight; }
static void OH_Drawing_SetTextStyleColor(FakeTextStyle *s, uint32_t color) { s->color = color; }
static void OH_Drawing_SetTextStyleFontFamilies(FakeTextStyle *s, uint32_t count, const char **names) {
  (void)s; (void)count; (void)names;
}
static void OH_Drawing_DestroyTextStyle(FakeTextStyle *s) { delete s; }
static FakeTypographyStyle *OH_Drawing_CreateTypographyStyle() { return new FakeTypographyStyle(); }
static void OH_Drawing_DestroyTypographyStyle(FakeTypographyStyle *s) { delete s; }
static FakeFontCollection *OH_Drawing_GetFontCollectionGlobalInstance() {
  static FakeFontCollection collection;
  return &collection;
}
static FakeHandler *OH_Drawing_CreateTypographyHandler(FakeTypographyStyle *style,
                                                      FakeFontCollection *collection) {
  (void)style; (void)collection;
  return new FakeHandler();
}
static void OH_Drawing_TypographyHandlerPushTextStyle(FakeHandler *handler, FakeTextStyle *style) {
  handler->fontSize = style->fontSize;
}
static void OH_Drawing_TypographyHandlerAddText(FakeHandler *handler, const char *text) {
  handler->text = text ? text : "";
}
static void OH_Drawing_TypographyHandlerPopTextStyle(FakeHandler *handler) { (void)handler; }
static void OH_Drawing_DestroyTypographyHandler(FakeHandler *handler) { delete handler; }

static FakeTypography *OH_Drawing_CreateTypography(FakeHandler *handler) {
  FakeTypography *typography = new FakeTypography();
  typography->serial=++g_layoutSerial;
  typography->fontSize = handler->fontSize;
  typography->units = utf8ToUtf16(handler->text);
  return typography;
}
static void OH_Drawing_TypographyLayout(FakeTypography *t, double width) {
  t->width = width > 0.0 ? width : 1.0;
  const double advance = t->fontSize * g_advanceFactor;
  const double lineHeight = t->fontSize * g_lineHeightFactor;
  const size_t perLine = advance > 0.0
      ? std::max<size_t>(1, static_cast<size_t>(t->width / advance)) : 1;
  t->lines.clear();
  size_t cursor = 0;
  for (;;) {
    const size_t lineStart = cursor;
    const size_t limit = std::min(t->units.size(), lineStart + perLine);
    const size_t newline = t->units.find(u'\n', lineStart);
    size_t lineEnd = limit;
    bool consumedNewline = false;
    if (newline != std::u16string::npos && newline < limit) {
      lineEnd = newline;
      consumedNewline = true;
    }
    FakeLine line;
    line.start = lineStart;
    line.end = lineEnd;
    line.top = static_cast<double>(t->lines.size()) * lineHeight;
    line.bottom = line.top + lineHeight;
    t->lines.push_back(line);
    if (!consumedNewline && lineEnd >= t->units.size()) break;
    cursor = consumedNewline ? lineEnd + 1 : lineEnd;
    if (cursor > t->units.size()) break;
  }
  t->height = static_cast<double>(t->lines.size()) * lineHeight;
  double longest = 0.0;
  for (const FakeLine &line : t->lines) {
    longest = std::max(longest, static_cast<double>(line.end - line.start) * advance);
  }
  t->longestLine = longest;
  t->maxWidth = t->width;
  t->baseline = t->fontSize;
}
static double OH_Drawing_TypographyGetHeight(FakeTypography *t) { return t->height; }
static double OH_Drawing_TypographyGetLongestLine(FakeTypography *t) { return t->longestLine; }
static double OH_Drawing_TypographyGetMaxWidth(FakeTypography *t) { return t->maxWidth; }
static size_t OH_Drawing_TypographyGetLineCount(FakeTypography *t) { return t->lines.size(); }
static bool OH_Drawing_TypographyGetLineMetricsAt(FakeTypography *t, int index, OH_Drawing_LineMetrics *out) {
  if (!t || !out || index<0 || static_cast<size_t>(index)>=t->lines.size()) return false;
  const auto &line=t->lines[index];
  out->x=0;out->y=line.top;out->height=line.bottom-line.top;
  out->startIndex=line.start;out->endIndex=line.end;out->width=(line.end-line.start)*t->fontSize*g_advanceFactor;
  return true;
}
static double OH_Drawing_TypographyGetAlphabeticBaseline(FakeTypography *t) { return t->baseline; }
static void OH_Drawing_DestroyTypography(FakeTypography *t) { delete t; }
static void OH_Drawing_TypographyPaint(FakeTypography *t, FakeCanvas *canvas, double x, double y) {
  (void)t; (void)canvas;
  g_paintCalls += 1;
  g_lastPaintedSerial=t->serial;
  g_paintX = x;
  g_paintY = y;
}

// Calibrated by the real API24 HAP: a partial emoji/combining/ZWJ range gives no box.
// The boundary oracle is the production CABI plus real host ICU, not a fake segmenter.
static bool fakeClusterBoundary(const std::u16string &text, size_t offset) {
  if (offset == 0 || offset == text.size()) return true;
  if (offset > text.size()) return false;
  if (text[offset] >= 0xdc00 && text[offset] <= 0xdfff &&
      text[offset - 1] >= 0xd800 && text[offset - 1] <= 0xdbff) return false;
  const std::string encoded = utf16ToUtf8(text);
  const uint64_t byte = utf16ToUtf8(text.substr(0, offset)).size();
  uint64_t lo=0,hi=0;
  return cjgui_internal_renderer_grapheme_cluster_range(encoded.c_str(),encoded.size(),byte,&lo,&hi)==0 && lo==byte;
}

static FakeTextBox *OH_Drawing_TypographyGetRectsForRange(FakeTypography *t, size_t start, size_t end,
    OH_Drawing_RectHeightStyle heightStyle, OH_Drawing_RectWidthStyle widthStyle) {
  (void)heightStyle; (void)widthStyle;
  if (!t || end <= start) return nullptr;
  const double advance = t->fontSize * g_advanceFactor;
  FakeTextBox *box = new FakeTextBox();
  if (!fakeClusterBoundary(t->units,start) || !fakeClusterBoundary(t->units,end)) return box;
  for (const FakeLine &line : t->lines) {
    const size_t a = std::max(start, line.start);
    const size_t b = std::min(end, line.end);
    if (b <= a && !(line.start == line.end && start <= line.start && end > line.start && line.start < t->units.size() && t->units[line.start] == u'\n')) continue;
    std::array<double, 4> rect;
    rect[0] = static_cast<double>(a - line.start) * advance;
    rect[1] = line.top;
    rect[2] = static_cast<double>(b - line.start) * advance;
    rect[3] = line.bottom;
    box->boxes.push_back(rect);
  }
  return box;
}
static size_t OH_Drawing_GetSizeOfTextBox(FakeTextBox *box) { return box ? box->boxes.size() : 0; }
static float OH_Drawing_GetLeftFromTextBox(FakeTextBox *box, int index) {
  return static_cast<float>(box->boxes[static_cast<size_t>(index)][0]);
}
static float OH_Drawing_GetRightFromTextBox(FakeTextBox *box, int index) {
  return static_cast<float>(box->boxes[static_cast<size_t>(index)][2]);
}
static float OH_Drawing_GetTopFromTextBox(FakeTextBox *box, int index) {
  return static_cast<float>(box->boxes[static_cast<size_t>(index)][1]);
}
static float OH_Drawing_GetBottomFromTextBox(FakeTextBox *box, int index) {
  return static_cast<float>(box->boxes[static_cast<size_t>(index)][3]);
}
static int OH_Drawing_GetTextDirectionFromTextBox(FakeTextBox *, int) { return 1; }
static void OH_Drawing_TypographyDestroyTextBox(FakeTextBox *box) { delete box; }

static FakePositionAndAffinity *OH_Drawing_TypographyGetGlyphPositionAtCoordinateWithCluster(
    FakeTypography *t, double dx, double dy) {
  g_hitCoordRecorded = true;
  g_lastHitSerial=t?t->serial:0;
  g_hitDx = dx;
  g_hitDy = dy;
  if (!t || g_stubPositionUnavailable || t->lines.empty()) return nullptr;
  const double advance = t->fontSize * g_advanceFactor;
  const double lineHeight = t->fontSize * g_lineHeightFactor;
  size_t index = 0;
  if (lineHeight > 0.0) {
    long long resolved = static_cast<long long>(std::floor(dy / lineHeight));
    if (resolved < 0) resolved = 0;
    if (resolved >= static_cast<long long>(t->lines.size())) {
      resolved = static_cast<long long>(t->lines.size()) - 1;
    }
    index = static_cast<size_t>(resolved);
  }
  const FakeLine &line = t->lines[index];
  long long local = advance > 0.0 ? static_cast<long long>(std::floor((dx + advance * 0.5) / advance)) : 0;
  if (local < 0) local = 0;
  const long long maxLocal = static_cast<long long>(line.end - line.start);
  if (local > maxLocal) local = maxLocal;
  FakePositionAndAffinity *hit = new FakePositionAndAffinity();
  hit->position = line.start + static_cast<size_t>(local);
  return hit;
}
static size_t OH_Drawing_GetPositionFromPositionAndAffinity(FakePositionAndAffinity *hit) {
  return hit ? hit->position : 0;
}
static int OH_Drawing_GetAffinityFromPositionAndAffinity(FakePositionAndAffinity *) { return 1; }
static void OH_Drawing_DestroyPositionAndAffinity(FakePositionAndAffinity *hit) { delete hit; }

static FakeBrush *OH_Drawing_BrushCreate() { return new FakeBrush(); }
static void OH_Drawing_BrushSetColor(FakeBrush *brush, uint32_t color) { brush->color = color; }
static void OH_Drawing_CanvasAttachBrush(FakeCanvas *canvas, FakeBrush *brush) { (void)canvas; (void)brush; }
static void OH_Drawing_CanvasDetachBrush(FakeCanvas *canvas) { (void)canvas; }
static void OH_Drawing_BrushDestroy(FakeBrush *brush) { delete brush; }
static FakeRect *OH_Drawing_RectCreate(float left, float top, float right, float bottom) {
  FakeRect *rect = new FakeRect();
  rect->left = left; rect->top = top; rect->right = right; rect->bottom = bottom;
  return rect;
}
static void OH_Drawing_RectDestroy(FakeRect *rect) { delete rect; }
static void OH_Drawing_CanvasDrawRect(FakeCanvas *canvas, FakeRect *rect) {
  (void)canvas;
  if (!rect) return;
  std::array<double, 4> recorded;
  recorded[0] = rect->left;
  recorded[1] = rect->top;
  recorded[2] = rect->right;
  recorded[3] = rect->bottom;
  g_drawnRects.push_back(recorded);
}
static void OH_Drawing_BrushSetAntiAlias(FakeBrush *, bool) {}
static OH_Drawing_Point *OH_Drawing_PointCreate(float x,float y) {return new OH_Drawing_Point{x,y};}
static void OH_Drawing_PointDestroy(OH_Drawing_Point *p) {delete p;}
static std::vector<std::array<double,3>> g_drawnCircles;
static void OH_Drawing_CanvasDrawCircle(FakeCanvas *,const OH_Drawing_Point *p,float radius) {
  g_drawnCircles.push_back({p->x,p->y,radius});
}
// Mechanical SDK substitute for tests of the production job's validation.
// Actual UTF16/CJK/ZWJ SDK word ranges are separately captured on the emulator.
static OH_Drawing_Range g_wordRange{0,1};
static bool g_wordUnavailable=false;
static OH_Drawing_Range *OH_Drawing_TypographyGetWordBoundary(FakeTypography *,size_t) {
  return g_wordUnavailable ? nullptr : new OH_Drawing_Range(g_wordRange);
}
static size_t OH_Drawing_GetStartFromRange(OH_Drawing_Range *r){return r->start;}
static size_t OH_Drawing_GetEndFromRange(OH_Drawing_Range *r){return r->end;}
static void OH_Drawing_ReleaseRangeBuffer(OH_Drawing_Range *r){delete r;}
'''

REPLICA = r'''
struct SceneNodePod {
  uint64_t nodeId = 0;
  uint64_t projectionVersion = 0;
  uint64_t acceptedBindingEpoch = 7;
  int64_t resourceId = -1;
  int64_t x = 0;
  int64_t y = 0;
  int64_t width = 0;
  int64_t height = 0;
  uint32_t nodeKind = 0;
  uint32_t isInteractive = 1;
  uint32_t isReadOnly = 0;
  uint32_t preservesActiveLocalText = 0;
  double fontSize = 14.0;
  uint32_t fontWeight = 400;
  double textRed = 0.1;
  double textGreen = 0.1;
  double textBlue = 0.1;
  double textAlpha = 1.0;
};
using CjguiInternalRendererComposableNode=SceneNodePod;
struct OhosImageRef {};
struct SceneNode {
  SceneNodePod pod;
  std::string label;
  std::string value;
  std::string semanticId;
  OhosImageRef image;
};
struct Session {
  bool caretBlinkVisible=true;
  bool caretBlinkResetPending=false;
  bool editingContextLive=true;
  int64_t editingContextId=7;
  uint64_t token=4242;
  uint64_t acceptedPaintTicketId=9;
  uint64_t editingProjectionVersion=0;
  uint32_t editingNodeKind=0;
  int32_t caretAffinity=0;
  std::vector<SceneNode> accepted;
  bool editing = false;
  bool editorRetired = false;
  uint64_t editingNodeId = 0;
  int64_t editingResourceId = -1;
  std::u16string editingText;
  uint32_t caretUtf16 = 0;
  uint32_t selStartUtf16 = 0;
  uint32_t selEndUtf16 = 0;
  std::u16string previewText;
  uint32_t previewStart = 0;
  uint32_t previewEnd = 0;
  bool previewActive = false;
  bool inUse = false;
};
static const size_t kMaxSessions = 4;
struct SessionTable {
  Session sessions[kMaxSessions];
  std::mutex lock;
};
static SessionTable g_sessions;
static Session *lookupSessionLocked(uint64_t token) { for(auto &s:g_sessions.sessions)if(s.inUse&&s.token==token)return &s;return nullptr;}
static int g_foreground=1;
static int foregroundLevel() { return g_foreground; }
static struct { int (*foregroundLevel)(); } g_ingress = {foregroundLevel};

enum class JobKind { Measure, CaretHitTest, Present, Redraw, ImageRealize, Teardown, Shutdown };
struct WaitableJob {
  JobKind kind;
  explicit WaitableJob(JobKind k) : kind(k) {}
  virtual ~WaitableJob() = default;
  CjguiInternalRendererStatus status = CJGUI_INTERNAL_RENDERER_OK;
  void finish(CjguiInternalRendererStatus value) { status = value; }
  CjguiInternalRendererStatus waitFor() { return status; }
};
'''

CLASS_BODY_MARKERS = [
    "struct Measured {",
    "struct TextGeometry {",
    "static int mapWeight(uint32_t weight)",
    "static uint32_t packColor(double r, double g, double b, double a)",
    "static std::string displayTextForNode(const SceneNode &node)",
    "Measured layoutText(const std::string &text, double fontSize, uint32_t fontWeight,",
    "TextGeometry computeTextGeometry(double nodeX, double nodeY, double nodeHeight, uint32_t kind,",
    "bool caretRectFor(OH_Drawing_Typography *typography, uint32_t caret, const std::u16string &text,",
    "void drawSelectionBoxes(OH_Drawing_Canvas *canvas, OH_Drawing_Typography *typography,",
    "void drawNodeText(OH_Drawing_Canvas *canvas, const SceneNode &node, TextPaintFrame &frame)",
    "double prefixWidthUtf16(const std::u16string &text, uint32_t prefixUnits, double fontSize,",
    "void executeCaretHitTest(CaretHitTestJob *job)",
    "void publishPaintedLayout(TextPaintFrame &frame)",
    "void invalidatePaintedLayout(uint64_t session)",
]

SUPPORT = [
    "std::u16string utf8ToUtf16(const std::string &utf8)",
    "std::string utf16ToUtf8(const std::u16string &utf16)",
    "uint32_t clampToCodePointBoundary(const std::u16string &text, uint32_t offset)",
    "bool utf16IsHighSurrogate(uint16_t unit)",
    "bool utf16IsLowSurrogate(uint16_t unit)",
    "std::u16string composedBuffer(const Session &s)",
    "bool cjguiOhosGraphemeRange16(const std::u16string &text, uint32_t offset,",
]

CONSTANT_LINES = [
    "constexpr uint32_t kKindText = 3;",
    "constexpr uint32_t kKindButton = 4;",
    "constexpr uint32_t kKindTextInput = 5;",
    "constexpr uint32_t kKindIntegerInput = 6;",
    "constexpr uint32_t kKindBooleanInput = 7;",
    "constexpr uint32_t kKindMultiline = 10;",
    "constexpr double kTextInsetSingleLine = 2.0;",
    "constexpr double kTextInsetMultiline = 6.0;",
]

MAIN_BODY = r"""
static int g_failures = 0;
#define EXPECT(cond, code) do { if (!(cond)) { fprintf(stderr, "FAIL %d (%s)\n", code, #cond); g_failures += 1; } } while (0)
#define EXPECT_NEAR(a, b, eps, code) do { if (std::fabs((a) - (b)) > (eps)) { \
    fprintf(stderr, "FAIL %d (%s = %.3f, expected %.3f)\n", code, #a, (double)(a), (double)(b)); g_failures += 1; } } while (0)

static void resetRecording() {
  g_paintCalls = 0;
  g_paintX = 0.0;
  g_paintY = 0.0;
  g_drawnRects.clear();
  g_drawnCircles.clear();
  g_hitCoordRecorded = false;
  g_hitDx = 0.0;
  g_hitDy = 0.0;
  g_stubPositionUnavailable = false;
}

static SceneNode bodyNode(int64_t width, int64_t height, const std::string &value) {
  SceneNode node;
  node.pod.nodeId = 107;
  node.pod.resourceId = 1;
  node.pod.nodeKind = kKindMultiline;
  node.pod.x = 0;
  node.pod.y = 0;
  node.pod.width = width;
  node.pod.height = height;
  node.pod.fontSize = 14.0;
  node.pod.fontWeight = 400;
  node.value = value;
  node.semanticId = "pharos-editor-body";
  return node;
}

// 把会话绑到该节点：绘制路径只有绑定会话的节点才画光标与选区。
static Session &bindEditing(const SceneNode &node, const std::string &value, uint32_t caret,
                            uint32_t selStart, uint32_t selEnd) {
  for (Session &slot : g_sessions.sessions) { slot = Session(); }
  Session &s = g_sessions.sessions[0];
  s.inUse = true;
  s.editing = true;
  s.editorRetired = false;
  s.editingNodeId = node.pod.nodeId;
  s.editingResourceId = node.pod.resourceId;
  s.editingNodeKind = node.pod.nodeKind;
  s.accepted = {node};
  s.editingText = utf8ToUtf16(value);
  s.caretUtf16 = caret;
  s.selStartUtf16 = selStart;
  s.selEndUtf16 = selEnd;
  return s;
}

int main() {
  FakeCanvas canvas;
  RenderThreadStub renderer;
  const double advance = 14.0 * g_advanceFactor;      // 8.4
  const double lineHeight = 14.0 * g_lineHeightFactor;  // 19.6

  // 1) 多行正文从节点上沿开始排版，不被盒高居中。
  {
    resetRecording();
    SceneNode node = bodyNode(300, 400, "# Pharos Mark");
    bindEditing(node, "# Pharos Mark", 13, 13, 13);
    renderer.drawForTest(&canvas, node);
    EXPECT(g_paintCalls == 1, 11);
    EXPECT_NEAR(g_paintX, node.pod.x + kTextInsetMultiline, 0.001, 12);
    EXPECT_NEAR(g_paintY, node.pod.y + kTextInsetMultiline, 0.001, 13);
    // 居中版本会落在 (400 - 19.6)/2 + 6 ≈ 196.2。
    EXPECT(g_paintY < 20.0, 14);
  }

  // 2) 单行 label 仍在盒内垂直居中（既有视觉行为不得回归）。
  {
    resetRecording();
    SceneNode node = bodyNode(120, 40, "label");
    node.pod.nodeKind = kKindText;
    node.value = "label";
    bindEditing(node, "", 0, 0, 0);
    g_sessions.sessions[0].inUse = false;   // 非编辑节点：走静态 value
    renderer.drawForTest(&canvas, node);
    EXPECT(g_paintCalls == 1, 21);
    // 既有实现（HEAD 的 drawNodeText）在文本装得下时是 drawY = y + (h - textH)/2，
    // 不加 inset；这里锁死这个旧行为，避免"修正文顶部对齐"顺手挪动 label/button。
    EXPECT_NEAR(g_paintY, (40.0 - lineHeight) / 2.0, 0.001, 22);
    EXPECT_NEAR(g_paintX, node.pod.x + kTextInsetSingleLine, 0.001, 23);
  }

  // 3) 跨行选区高亮：每行一段，且各段落在自己那一行的 y 带内。
  {
    resetRecording();
    // 宽 100 → 每行 11 个码元；文本两行各 10 个字符（硬换行）。
    SceneNode node = bodyNode(100, 300, "0123456789\n0123456789");
    bindEditing(node, "0123456789\n0123456789", 21, 2, 17);
    renderer.drawForTest(&canvas, node);
    // Nonempty range paints two line highlights and two grips, no collapsed caret.
    EXPECT(g_drawnRects.size() == 4, 31); // two highlights plus two handle stems
    EXPECT(g_drawnCircles.size() == 2, 131);
    const auto &handles = g_sessions.sessions[0].selectionHandles;
    EXPECT(handles.valid && handles.start == 2 && handles.end == 17, 132);
    EXPECT(handles.ticket == g_sessions.sessions[0].acceptedPaintTicketId && handles.context == 7, 133);
    EXPECT_NEAR(g_drawnCircles[0][0], handles.startX, 0.001, 134);
    EXPECT_NEAR(g_drawnCircles[1][1], handles.endY, 0.001, 135);
    const std::array<double, 4> &first = g_drawnRects[0];
    const std::array<double, 4> &second = g_drawnRects[1];
    EXPECT_NEAR(first[0], node.pod.x + kTextInsetMultiline + 2 * advance, 0.001, 32);
    EXPECT_NEAR(first[2], node.pod.x + kTextInsetMultiline + 10 * advance, 0.001, 33);
    EXPECT_NEAR(first[1], node.pod.y + kTextInsetMultiline, 0.001, 34);
    EXPECT_NEAR(first[3], node.pod.y + kTextInsetMultiline + lineHeight, 0.001, 35);
    // 第二段在第二行：y 带整体下移一个行高，x 从该行起点算（不是整宽横杠）。
    EXPECT_NEAR(second[1], node.pod.y + kTextInsetMultiline + lineHeight, 0.001, 36);
    EXPECT_NEAR(second[3], node.pod.y + kTextInsetMultiline + 2 * lineHeight, 0.001, 37);
    EXPECT_NEAR(second[0], node.pod.x + kTextInsetMultiline, 0.001, 38);
    EXPECT_NEAR(second[2], node.pod.x + kTextInsetMultiline + 6 * advance, 0.001, 39);
  }

  // 4) 光标在第二行：矩形来自排版给出的那一行，而不是首行 y=0。
  {
    resetRecording();
    SceneNode node = bodyNode(100, 300, "0123456789\n0123456789");
    bindEditing(node, "0123456789\n0123456789", 15, 15, 15);   // 第二行第 4 个字符后
    renderer.drawForTest(&canvas, node);
    EXPECT(g_drawnRects.size() == 1, 41);
    const std::array<double, 4> &caret = g_drawnRects[0];
    EXPECT_NEAR(caret[0], node.pod.x + kTextInsetMultiline + 4 * advance - 1.0, 0.001, 42);
    EXPECT_NEAR(caret[1], node.pod.y + kTextInsetMultiline + lineHeight, 0.001, 43);
    EXPECT_NEAR(caret[3], node.pod.y + kTextInsetMultiline + 2 * lineHeight, 0.001, 44);
  }

  // 5) 往返一致：点在光标画出的位置上，命中测试返回同一个码元位置；
  //    并且传给排版的坐标是几何原点相对坐标（内缩只有一处定义）。
  {
    resetRecording();
    SceneNode node = bodyNode(100, 300, "0123456789\n0123456789");
    bindEditing(node, "0123456789\n0123456789", 15, 15, 15);
    renderer.drawForTest(&canvas, node);
    const std::array<double, 4> caret = g_drawnRects[0];
    CaretHitTestJob job;
    job.text = utf8ToUtf16("0123456789\n0123456789");
    job.fontSize = node.pod.fontSize;
    job.fontWeight = node.pod.fontWeight;
    job.nodeWidth = static_cast<double>(node.pod.width);
    job.nodeHeight = static_cast<double>(node.pod.height);
    job.nodeKind = node.pod.nodeKind;
    job.tapX = caret[0] + 1.0;                                  // 光标右沿（节点内坐标）
    job.tapY = (caret[1] + caret[3]) / 2.0;                      // 第二行行中带
    job.caretUtf16 = 999;
    renderer.hitForTest(&job);
    EXPECT(job.status == CJGUI_INTERNAL_RENDERER_OK, 51);
    EXPECT(job.caretUtf16 == 15, 52);
    EXPECT(g_lastHitSerial == g_lastPaintedSerial, 92);
    EXPECT(g_hitCoordRecorded, 53);
    EXPECT_NEAR(g_hitDx, job.tapX - kTextInsetMultiline, 0.001, 54);
    EXPECT_NEAR(g_hitDy, job.tapY - kTextInsetMultiline, 0.001, 55);
    // 第一行的点必须落在第一行（旧的"只用 tapX"实现会把它算到别处）。
    resetRecording();
    CaretHitTestJob firstLine = job;
    firstLine.tapX = node.pod.x + kTextInsetMultiline + 3 * advance + advance * 0.4;
    firstLine.tapY = node.pod.y + kTextInsetMultiline + lineHeight * 0.5;
    firstLine.caretUtf16 = 999;
    renderer.hitForTest(&firstLine);
    EXPECT(firstLine.status == CJGUI_INTERNAL_RENDERER_OK, 56);
    EXPECT(firstLine.caretUtf16 == 3, 57);
  }

  // 6) 排版答不出位置：fail-closed，不把 0 当命中结果。
  {
    resetRecording();
    g_stubPositionUnavailable = true;
    CaretHitTestJob job;
    job.text = utf8ToUtf16("0123456789\n0123456789");
    job.fontSize = 14.0;
    job.fontWeight = 400;
    job.nodeWidth = 100.0;
    job.nodeHeight = 300.0;
    job.nodeKind = kKindMultiline;
    job.tapX = 20.0;
    job.tapY = 30.0;
    job.caretUtf16 = 999;
    renderer.hitForTest(&job);
    EXPECT(job.status != CJGUI_INTERNAL_RENDERER_OK, 61);
    EXPECT(job.caretUtf16 == 999, 62);
    EXPECT(g_hitCoordRecorded, 105);
  }

  // 7) Actual API24 counterexample: partial clusters have no box. Every caret
  // after emoji/combining/ZWJ/skin/flag must remain on the second line.
  for (const std::string &cluster : {std::string(u8"😀"), std::string(u8"é"),
         std::string(u8"👨‍👩‍👧‍👦"), std::string(u8"👍🏽"), std::string(u8"🇨🇳")}) {
    resetRecording();
    const std::string text = "A\n" + cluster;
    const uint32_t units = static_cast<uint32_t>(utf8ToUtf16(text).size());
    SceneNode node = bodyNode(600,300,text);
    bindEditing(node,text,units,units,units);
    renderer.drawForTest(&canvas,node);
    EXPECT(g_drawnRects.size()==1,70);
    if (g_drawnRects.size()==1) {
      EXPECT_NEAR(g_drawnRects[0][1],node.pod.y+kTextInsetMultiline+lineHeight,0.001,71);
      EXPECT_NEAR(g_drawnRects[0][0],node.pod.x+kTextInsetMultiline+(units-2)*advance-1,0.001,72);
    }
  }

  // A hard newline ends the preceding line's box; the caret belongs to the
  // next blank line, including repeated trailing empty lines.
  for (const std::string &text : {std::string("A\n"),std::string("A\n\n")}) {
    resetRecording();
    const uint32_t units=static_cast<uint32_t>(text.size());
    SceneNode node=bodyNode(600,300,text);bindEditing(node,text,units,units,units);
    renderer.drawForTest(&canvas,node);EXPECT(g_drawnRects.size()==1,73);
    if(g_drawnRects.size()==1){
      EXPECT_NEAR(g_drawnRects[0][0],kTextInsetMultiline-1,0.001,74);
      EXPECT_NEAR(g_drawnRects[0][1],kTextInsetMultiline+(units-1)*lineHeight,0.001,75);
    }
  }
  for (const auto &sample : {std::pair<std::string,uint32_t>{"A\n\nB",2},
           {"\nB",0},{"\n\n",1},{"",0}}) {
    resetRecording();auto node=bodyNode(600,300,sample.first);
    bindEditing(node,sample.first,sample.second,sample.second,sample.second);
    renderer.drawForTest(&canvas,node);EXPECT(g_drawnRects.size()==1,93);
    if(g_drawnRects.size()==1){double line=sample.first.empty()?0:(sample.second==0?0:1);
      EXPECT_NEAR(g_drawnRects[0][1],kTextInsetMultiline+line*lineHeight,0.001,94);}
  }
  // A quiet dark phase must erase the caret without changing the text paint.
  {
    resetRecording();SceneNode node=bodyNode(600,300,"A\nB");
    Session &session=bindEditing(node,"A\nB",3,3,3);session.caretBlinkVisible=false;
    renderer.drawForTest(&canvas,node);EXPECT(g_paintCalls==1,78);EXPECT(g_drawnRects.empty(),79);
  }
  {
    resetRecording();SceneNode node=bodyNode(600,300,u8"😀");bindEditing(node,u8"😀",0,0,0);
    renderer.drawForTest(&canvas,node);EXPECT(g_drawnRects.size()==1,76);
    if(g_drawnRects.size()==1)EXPECT_NEAR(g_drawnRects[0][0],kTextInsetMultiline-1,0.001,77);
  }

  // Pending real input is bright even before the next pump. Matching numbers
  // in another Session or a retired binding cannot supply an editable overlay.
  {
    resetRecording();SceneNode node=bodyNode(600,300,"A\nB");
    auto &s=bindEditing(node,"A\nB",3,3,3);s.caretBlinkVisible=false;s.caretBlinkResetPending=true;
    renderer.drawForTest(&canvas,node);EXPECT(g_drawnRects.size()==1,80);
    resetRecording();s.token=4243;renderer.drawForTest(&canvas,node);
    EXPECT(g_paintCalls==1,81);EXPECT(g_drawnRects.empty(),82);
    resetRecording();s.token=4242;s.accepted[0].pod.acceptedBindingEpoch=8;
    renderer.drawForTest(&canvas,node);EXPECT(g_drawnRects.empty(),83);
  }
  {
    resetRecording();SceneNode node=bodyNode(600,300,"A\nB");
    auto &s=bindEditing(node,"A\nB",3,3,3);s.editorRetired=true;node.pod.preservesActiveLocalText=1;
    renderer.drawForTest(&canvas,node);EXPECT(g_paintCalls==1,84);EXPECT(g_drawnRects.empty(),85);
    s.editorRetired=false;resetRecording();g_foreground=0;
    renderer.drawForTest(&canvas,node);EXPECT(g_paintCalls==1,86);EXPECT(g_drawnRects.empty(),87);g_foreground=1;
  }
  // A soft wrap has two visual positions for one UTF16 boundary. Preserve the
  // native hit affinity; downstream places the caret at the next line's start.
  {
    resetRecording();SceneNode node=bodyNode(100,300,"abcdefghijklmnopqrst");
    auto &s=bindEditing(node,node.value,11,11,11);s.caretAffinity=1;
    renderer.drawForTest(&canvas,node);EXPECT(g_drawnRects.size()==1,88);
    if(g_drawnRects.size()==1){EXPECT_NEAR(g_drawnRects[0][0],kTextInsetMultiline-1,0.001,89);
      EXPECT_NEAR(g_drawnRects[0][1],kTextInsetMultiline+lineHeight,0.001,90);}
  }
  // An interior grapheme boundary is ambiguous; do not silently snap or draw
  // a caret on the first line. Platform insertion remains UTF16 based.
  {
    resetRecording();SceneNode node=bodyNode(600,300,u8"A\né");bindEditing(node,node.value,3,3,3);
    renderer.drawForTest(&canvas,node);EXPECT(g_drawnRects.empty(),91);
  }

  // Cache admission is ticket based, even for two frames with the same
  // projection. Publication is a move of the actual Paint object; querying
  // creates no Typography and blink need not change this accepted ticket.
  {
    resetRecording();auto node=bodyNode(100,300,"0123456789\n0123456789");
    auto &s=bindEditing(node,node.value,15,15,15);renderer.drawForTest(&canvas,node);
    CaretHitTestJob job;job.text=s.editingText;job.nodeWidth=100;job.nodeHeight=300;
    job.nodeKind=kKindMultiline;job.fontSize=14;job.fontWeight=400;job.tapX=39.6;job.tapY=35.4;
    const auto before=g_layoutSerial;renderer.hitForTest(&job);
    EXPECT(job.status==CJGUI_INTERNAL_RENDERER_OK,95);EXPECT(g_layoutSerial==before,96);
    s.acceptedPaintTicketId=10;renderer.hitForTest(&job);EXPECT(job.status==CJGUI_INTERNAL_RENDERER_PRESENT_PENDING,97);
    TextPaintFrame candidate{4242,10,node.pod.projectionVersion,nullptr};renderer.drawNodeText(&canvas,node,candidate);
    renderer.publishPaintedLayout(candidate);s.acceptedPaintTicketId=9;
    renderer.hitForTest(&job);EXPECT(job.status==CJGUI_INTERNAL_RENDERER_PRESENT_PENDING,98);
    s.acceptedPaintTicketId=10;const auto after=g_layoutSerial;renderer.hitForTest(&job);
    EXPECT(job.status==CJGUI_INTERNAL_RENDERER_OK,99);EXPECT(g_layoutSerial==after,100);
    renderer.paintedLayoutUsable=false;renderer.hitForTest(&job);EXPECT(job.status==CJGUI_INTERNAL_RENDERER_GEOMETRY_EMPTY,101);
    renderer.paintedLayoutUsable=true;renderer.permitGeometryRevision++;
    renderer.hitForTest(&job);EXPECT(job.status==CJGUI_INTERNAL_RENDERER_VIEW_INVALIDATED,102);renderer.permitGeometryRevision--;
    TextPaintFrame absent{4242,10,node.pod.projectionVersion,nullptr};renderer.publishPaintedLayout(absent);
    EXPECT(!renderer.lastPaintLayout,103);renderer.hitForTest(&job);EXPECT(job.status==CJGUI_INTERNAL_RENDERER_GEOMETRY_EMPTY,104);
  }

  // A word query uses the retained Paint object; invalid SDK ranges refuse.
  {
    resetRecording();auto node=bodyNode(600,300,u8"A👨‍👩‍👧‍👦B");
    auto &s=bindEditing(node,node.value,1,1,1);renderer.drawForTest(&canvas,node);
    auto make=[&](){CaretHitTestJob j;j.text=s.editingText;j.fontSize=14;j.fontWeight=400;
      j.nodeWidth=600;j.nodeHeight=300;j.nodeKind=kKindMultiline;j.tapX=kTextInsetMultiline+2*advance;
      j.tapY=kTextInsetMultiline+lineHeight/2;j.mode=1;return j;};
    const auto serial=g_layoutSerial;
    g_wordRange={2,4};auto inside=make();renderer.hitForTest(&inside);
    EXPECT(inside.status==CJGUI_INTERNAL_RENDERER_OK&&inside.wordStart==1&&inside.wordEnd==12,136);
    EXPECT(g_layoutSerial==serial&&g_lastHitSerial==g_lastPaintedSerial,137);
    g_wordRange={7,200};auto bad=make();renderer.hitForTest(&bad);EXPECT(bad.status!=CJGUI_INTERNAL_RENDERER_OK,138);
    g_wordUnavailable=true;auto absent=make();renderer.hitForTest(&absent);EXPECT(absent.status!=CJGUI_INTERNAL_RENDERER_OK,139);g_wordUnavailable=false;
    g_wordRange={4,4};auto empty=make();renderer.hitForTest(&empty);EXPECT(empty.status!=CJGUI_INTERNAL_RENDERER_OK,140);
  }
  // Paragraph selection consumes the same Paint hit, across visual wraps.
  {
    resetRecording();auto node=bodyNode(100,600,"alpha beta gamma delta\nnext");
    auto &s=bindEditing(node,node.value,3,3,3);renderer.drawForTest(&canvas,node);
    CaretHitTestJob j;j.text=s.editingText;j.fontSize=14;j.fontWeight=400;
    j.nodeWidth=100;j.nodeHeight=600;j.nodeKind=kKindMultiline;j.mode=3;
    j.tapX=kTextInsetMultiline+advance;j.tapY=kTextInsetMultiline+lineHeight*1.5;
    const auto serial=g_layoutSerial;renderer.hitForTest(&j);
    EXPECT(j.status==CJGUI_INTERNAL_RENDERER_OK&&j.wordStart==0&&j.wordEnd==22,145);
    EXPECT(g_layoutSerial==serial&&g_lastHitSerial==g_lastPaintedSerial,146);
    uint32_t lo=0,hi=0;
    sourceParagraphRange16(u"A\r\nB\n\nC\u2029D",3,lo,hi);EXPECT(lo==3&&hi==4,147);
    sourceParagraphRange16(u"A\r\nB\n\nC\u2029D",5,lo,hi);EXPECT(lo==5&&hi==5,148);
    sourceParagraphRange16(u"A\r\nB\n\nC\u2029D",8,lo,hi);EXPECT(lo==8&&hi==9,149);
    sourceParagraphRange16(u"A\U0001f606B\nC",2,lo,hi);EXPECT(lo==0&&hi==4,150);
  }
  // A successful frame without the editing node revokes both endpoint facts.
  {
    resetRecording();auto node=bodyNode(600,300,"word other");auto &s=bindEditing(node,node.value,4,0,4);
    renderer.drawForTest(&canvas,node);EXPECT(s.selectionHandles.valid,141);
    TextPaintFrame absent{4242,s.acceptedPaintTicketId,0,nullptr};renderer.publishPaintedLayout(absent);
    EXPECT(!s.selectionHandles.valid,142);
    renderer.drawForTest(&canvas,node);EXPECT(s.selectionHandles.valid,143);
    renderer.invalidatePaintedLayout(s.token);EXPECT(!s.selectionHandles.valid&&!renderer.paintedLayoutUsable,144);
  }
  if (g_failures == 0) {
    printf("text geometry harness ok\n");
    return 0;
  }
  fprintf(stderr, "text geometry harness failures=%d\n", g_failures);
  return 1;
}
"""


def extract_decl(text: str, marker: str) -> str:
    # 必须摘到"定义"而不是前置声明：`composedBuffer` 在源码里先有声明后有定义，
    # 若从声明处向后找第一个 `{`，会把无关的 enum 一起吞进来（生成物编译失败）。
    search = 0
    while True:
        start = text.index(marker, search)
        opening = text.index("{", start)
        if ";" in text[start + len(marker):opening]:
            search = start + len(marker)
            continue
        depth = 0
        for index in range(opening, len(text)):
            depth += (text[index] == "{") - (text[index] == "}")
            if depth == 0:
                decl = text[start:index + 1]
                # 结构体定义的尾分号不在花括号内，摘出来要补上。
                if marker.startswith("struct "):
                    decl += ";"
                return decl
        raise ValueError(f"unterminated declaration: {marker}")


def extract_line(text: str, marker: str) -> str:
    start = text.index(marker)
    end = text.index("\n", start)
    return text[start:end]


INCLUDES = """#include <algorithm>
#include <array>
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <cstddef>
#include <cstring>
#include <dlfcn.h>
#include <limits>
#include <memory>
#include <mutex>
#include <string>
#include <vector>
#include <unicode/ubrk.h>
#include <unicode/ustring.h>
#define CJGUI_OHOS_ICU_LIBRARY "/usr/lib/libicucore.dylib"
"""


def build_harness(source_text: str) -> str:
    # 顺序不是随意的：STUBS 的假排版模型会调用真实 utf8ToUtf16，REPLICA 的 Session
    # 又是 composedBuffer 的参数类型，两边互相需要，所以先统一前置声明再定义。
    harness = INCLUDES
    harness += "struct Session;\n"
    # The multiline signature's comma marker is for extraction, not a declaration.
    harness += "\n".join(sig + ";" for sig in SUPPORT if not sig.endswith(",")) + "\n"
    harness += STUBS
    harness += system_grapheme.production_service() + "\n"
    harness += "\n".join(extract_line(source_text, line) for line in CONSTANT_LINES) + "\n"
    import test_touch_gesture_native as touch
    handles, selection_fields = touch.selection_declarations(source_text)
    harness += handles + REPLICA.replace("struct Session {", "struct Session {\n" + selection_fields, 1)
    harness += "\n".join(extract_decl(source_text, sig) for sig in SUPPORT)
    harness += extract_decl(source_text, "struct PaintedTextLayout {")
    harness += extract_decl(source_text, "struct TextPaintFrame {")
    harness += extract_decl(source_text, "void sourceParagraphRange16(const std::u16string &text, uint32_t caret, uint32_t &lo, uint32_t &hi)")
    harness += extract_decl(source_text, "struct CaretHitTestJob : WaitableJob {")
    harness += "\nstruct RenderThreadStub {\n"
    harness += r'''
    std::unique_ptr<PaintedTextLayout> lastPaintLayout;
    bool paintedLayoutUsable=false;uint64_t textLayoutsBuilt=0,textLayoutInputBytes=0,textPaintSerial=0,renderEpoch=1,boundGeneration=7,permitGeometryRevision=1;
    void *boundWindow=reinterpret_cast<void*>(9);int32_t surfaceW=1320,surfaceH=2856;double surfaceDensity=3.5;
    static bool pointInsideClips(const SceneNodePod &,float,float){return true;}
    bool leaseValid(uint64_t generation) { return generation==boundGeneration; }
    bool geometryMatches(void *window,uint64_t generation,int w,int h,uint64_t revision) {
      return window==boundWindow&&generation==boundGeneration&&w==surfaceW&&h==surfaceH&&revision==permitGeometryRevision;
    }
    void drawForTest(FakeCanvas *canvas,const SceneNode &node) {
      TextPaintFrame frame{4242,g_sessions.sessions[0].acceptedPaintTicketId,node.pod.projectionVersion,nullptr};
      drawNodeText(canvas,node,frame);publishPaintedLayout(frame);
    }
    void hitForTest(CaretHitTestJob *job) {
      const auto &s=g_sessions.sessions[0];const auto &node=s.accepted.front().pod;
      job->session=s.token;job->nodeId=node.nodeId;job->resourceId=node.resourceId;
      job->bindingEpoch=node.acceptedBindingEpoch;job->projectionVersion=node.projectionVersion;
      job->contextId=s.editingContextId;job->nodeX=node.x;job->nodeY=node.y;
      executeCaretHitTest(job);
    }
    '''
    harness += "\n".join(extract_decl(source_text, marker) for marker in CLASS_BODY_MARKERS)
    harness += "\n};\n"
    harness += MAIN_BODY
    return harness


def mutate(source: str, marker: str, replacement: str, name: str) -> str:
    if marker not in source:
        raise AssertionError(f"negative control {name} did not match the source")
    return source.replace(marker, replacement, 1)


def drop_multiline_top_align(source: str) -> str:
    # 去掉"正文顶部对齐"规则 → 回到盒内居中（短文档落在画面正中）。
    return mutate(source,
                  "if (kind != kKindMultiline && m.height < nodeHeight) {",
                  "if (false && m.height < nodeHeight) {",
                  "drop_multiline_top_align")


def drop_single_line_centering(source: str) -> str:
    # 反过来：把居中规则扩到所有 kind → 单行 label 视觉回归。
    return mutate(source,
                  "if (kind != kKindMultiline && m.height < nodeHeight) {",
                  "if (m.height < nodeHeight) {",
                  "drop_single_line_centering")


def drop_selection_per_line(source: str) -> str:
    # 只画最后一个盒 → 跨行选区退化成一段。
    return mutate(source,
                  "            for (size_t i = 0; i < count; ++i) {\n                int index = static_cast<int>(i);",
                  "            for (size_t i = count > 0 ? count - 1 : 0; i < count; ++i) {\n                int index = static_cast<int>(i);",
                  "drop_selection_per_line")


def drop_caret_typography_rect(source: str) -> str:
    # 不用排版给的行矩形 → 光标退回首行前缀宽度（y=0）。
    return mutate(source,
                  "                static_cast<float>(geom.originY + caretTop),",
                  "                static_cast<float>(geom.originY + 0.0 * caretTop),",
                  "drop_caret_typography_rect")


def drop_hit_geometry_origin(source: str) -> str:
    # 命中不再按几何原点换算坐标 → 绘制与命中不共原点（旧的 7.0 硬编码同类缺陷）。
    # 保留对 geom 的引用（乘 0），否则 -Werror 会把"编译失败"混进负控结果。
    return mutate(source,
                  "painted->typography.get(), job->tapX - painted->relativeOriginX, job->tapY - painted->relativeOriginY);",
                  "painted->typography.get(), job->tapX + 0.0 * painted->relativeOriginX, job->tapY + 0.0 * painted->relativeOriginY);",
                  "drop_hit_geometry_origin")


def drop_hit_vertical(source: str) -> str:
    # 只用 x 命中 → 点在第二行会把光标落到第一行。
    return mutate(source,
                  "painted->typography.get(), job->tapX - painted->relativeOriginX, job->tapY - painted->relativeOriginY);",
                  "painted->typography.get(), job->tapX - painted->relativeOriginX, 0.0);",
                  "drop_hit_vertical")


def drop_hit_fail_closed(source: str) -> str:
    # 排版答不出时仍报成功 → 把未测出的位置当命中结果。
    return mutate(source,
                  "        if (!hit) {\n            job->finish(CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR);\n            return;\n        }",
                  "        if (!hit && false) {\n            job->finish(CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR);\n            return;\n        }",
                  "drop_hit_fail_closed")


def drop_shared_inset(source: str) -> str:
    # 内缩回到硬编码 7.0（绘制 6.0 / 命中 7.0 的老分裂）。
    return mutate(source,
                  "const double inset = (kind == kKindText) ? kTextInsetSingleLine : kTextInsetMultiline;",
                  "const double inset = (kind == kKindText) ? kTextInsetSingleLine : 7.0;",
                  "drop_shared_inset")


NEGATIVE_CONTROLS = [
    ("drop_multiline_top_align", drop_multiline_top_align),
    ("drop_single_line_centering", drop_single_line_centering),
    ("drop_selection_per_line", drop_selection_per_line),
    ("drop_caret_typography_rect", drop_caret_typography_rect),
    ("drop_hit_geometry_origin", drop_hit_geometry_origin),
    ("drop_hit_vertical", drop_hit_vertical),
    ("drop_hit_fail_closed", drop_hit_fail_closed),
    ("drop_shared_inset", drop_shared_inset),
    ("drop_blink_visibility", lambda source: mutate(source,
        "(sess.caretBlinkResetPending || sess.caretBlinkVisible)", "true", "drop_blink_visibility")),
    ("drop_frame_session", lambda source: mutate(source,
        "sess.inUse && sess.token == frameSession && sess.editing", "sess.inUse && sess.editing", "drop_frame_session")),
    ("drop_paint_acceptance_ticket", lambda source: mutate(source,
        "if (s->acceptedPaintTicketId != painted->basePresentTicket)",
        "if (false && s->acceptedPaintTicketId != painted->basePresentTicket)", "drop_paint_acceptance_ticket")),

]


class TextGeometryNativeTest(unittest.TestCase):
    def _compile_and_run(self, source_text: str, tmp: pathlib.Path) -> int:
        harness = tmp / "text_geometry_harness.cpp"
        harness.write_text(build_harness(source_text))
        binary = tmp / "text_geometry_harness"
        compile_cmd = ["clang++", "-std=c++17", "-Wall", "-Wextra", "-Werror",
                       "-Wno-unused-function", "-Wno-unused-parameter",
                       f"-I{ROOT / 'host'}", f"-I{INGRESS.parent}",
                       "-idirafter", str(system_grapheme.SDK_INCLUDE), str(harness), "-o", str(binary)]
        compiled = subprocess.run(compile_cmd, capture_output=True, text=True)
        if compiled.returncode != 0:
            self.fail(f"harness compile failed:\n{compiled.stderr}")
        run = subprocess.run([str(binary)], capture_output=True, text=True)
        self.last_run = run.stdout + run.stderr
        return run.returncode

    def test_geometry_contract(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            rc = self._compile_and_run(SOURCE.read_text(), pathlib.Path(tmpdir))
            self.assertEqual(rc, 0, f"text geometry harness failed with rc={rc}: {self.last_run}")

    def test_negative_controls(self) -> None:
        source = SOURCE.read_text()
        for name, mutate_source in NEGATIVE_CONTROLS:
            with tempfile.TemporaryDirectory() as tmpdir:
                rc = self._compile_and_run(mutate_source(source), pathlib.Path(tmpdir))
                self.assertNotEqual(rc, 0, f"negative control {name} must fail")


if __name__ == "__main__":
    sys.exit(0 if unittest.main(exit=False).result.wasSuccessful() else 1)

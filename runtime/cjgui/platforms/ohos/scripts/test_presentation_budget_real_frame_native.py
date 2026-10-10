#!/usr/bin/env python3
"""A2 复核（2026-10-06）：预算三界与必需/可选分流必须经**真实 present/redraw 控制
流**验证；抽取模型与字符串存在断言不替代这条运行链（参见
fixla19-review/overflow-gate-coverage-result.json：旧 harness 对「门挪到 Flush 后」
不敏感）。

本 harness 的做法：**逐字抽取**生产源码的运行链切片（不是手写状态机）：

  * redraw 全链：`TextPaintFrame paintFrame{...}` → 绘制循环（真实 drawNodeText
    保留块）→ 几何复核 → 溢出拒候选（Flush 前）→ `OH_Drawing_SurfaceFlush` →
    `publishPaintedLayout`（真实整表替换）；
  * drawNodeText 保留块：三界判据 + 必需/可选分流（layout_not_retained /
    layout_budget_exceeded 具名）；
  * present 拒候选切片：A2 注释 → 溢出门 → `OH_Drawing_ErrorCode flush = ...`
    声明（结构断言：门必须在 Flush 声明之前——生产挪门会让切片失去门文本而翻红）；
  * 命中消费：真实 `runPresentationHitLocked`（旧 accepted 命中保持 / 具名拒绝）；
  * 查询队列界：真实 `post` / `postIfRunning` / `cancelBeforeCommit`。

切片按锚点抽取，锚点间的**生产顺序**被原样编译进 harness：把溢出门挪到 Flush
之后、把计费改成只数新表、删掉必需/可选分流，都会让本文件运行翻红或抽取失败。

计费模型（生产语义）：旧 published 表与新帧表在绘制窗口内同时存活，三界的
「条目数/单节点文本/全表单元」都按两表共同峰值计费；因此用例以「旧表 32 条 +
新帧 ≤32 条」贴近 64 条目界，以「旧表 259,200 单元 + 新帧增量」贴近全表单元界。

运行时反例（全部经上述真实链执行）：
  ① 可选目标超限（第 65 条）→ 具名 layout_not_retained、照常 Flush、发布受限表、
     缺条目查询具名拒绝；必需目标（活动选择/拖动的已知片段）超限 → 零 Flush 拒
     候选、旧 accepted 与命中保持、下一合法帧恢复。
  ② 单节点文本越界（可选 skip / 必需拒候选）；旧表+新表共同计费越界（只数新表
     时该反例不红——旧表计费参与判定）。
  ③ 查询队列界：第 33 个待执行查询具名拒绝（query_queue_over_budget），在途查询
     不受影响。
"""
import pathlib
import re
import subprocess
import tempfile
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]
SOURCE = ROOT / "host" / "ohos_renderer.cpp"

REDRAW_START = ("        TextPaintFrame paintFrame{lastFrameSession, lastFrameTicket, "
                "lastProjectionVersion, nullptr};")
REDRAW_END = "        publishPaintedLayout(paintFrame);"
PRESENT_COMMENT = "        // A2：必需目标超出保留预算 ⇒ 零 Flush 拒候选。drawNodeText 的早返回只销毁"
PRESENT_FLUSH_DECL = "        OH_Drawing_ErrorCode flush = OH_DRAWING_SUCCESS;"
RETENTION_TRIGGER = "if (retainHere) {\n                auto retained"
# A2 准入片段：从"计费资格"第一条语句起，到排版调用为止（不含）。
ADMISSION_TRIGGER = "        const bool leaseEligible = kind == kKindText"


def balanced_block(text, open_index):
    depth = 0
    for i in range(open_index, len(text)):
        c = text[i]
        if c == '{':
            depth += 1
        elif c == '}':
            depth -= 1
            if depth == 0:
                return text[open_index:i + 1]
    raise ValueError('unbalanced block')


def balanced_block_upto(text, start, end_marker):
    """抽取 `[start, end_marker)` —— 用于"准入必须在昂贵准备之前"这一形状断言：
    准入片段本身不得包含排版调用，排版调用是它后面的第一条语句。"""
    end = text.index(end_marker, start)
    return text[start:end]


def extract_function(text, signature_snippet):
    start = text.index(signature_snippet)
    open_brace = text.index('{', start)
    return balanced_block(text, start)


def extract_constants(text):
    out = []
    for name in ("kPresentationLeaseMax", "kPresentationLeaseNodeTextMax",
                 "kPresentationLeaseNodeRunsMax", "kPresentationLeaseTotalUnitsMax",
                 "kPresentationQueryQueueMax", "kMaxSessions"):
        m = re.search(rf"constexpr size_t {name} = (\d+);", text)
        assert m, name
        out.append(f"constexpr size_t {name} = {m.group(1)};")
    return "\n".join(out)


def build_pieces(text=None):
    if text is None:
        text = SOURCE.read_text(encoding="utf-8")

    a = text.index(REDRAW_START)
    b = text.index(REDRAW_END, a) + len(REDRAW_END)
    redraw_region = text[a:b]
    assert redraw_region.index("redraw refused: presentation_lease_overflow") < \
        redraw_region.index("OH_Drawing_SurfaceFlush"), "redraw gate must precede Flush"

    p0 = text.index(PRESENT_COMMENT)
    p1 = text.index(PRESENT_FLUSH_DECL, p0) + len(PRESENT_FLUSH_DECL)
    present_region = text[p0:p1]
    assert "present refused: presentation_lease_overflow" in present_region, \
        "present gate must precede Flush declaration"

    t = text.index(ADMISSION_TRIGGER)
    admission_block = balanced_block_upto(text, t, "const bool reuseEditing =")
    r = text.index(RETENTION_TRIGGER)
    outer = text.rindex("if (!isEditingNode) {", 0, r)
    retention_block = balanced_block(text, outer)

    pieces = {
        "constants": extract_constants(text),
        "enums": (extract_function(text, "enum class JobKind") + ";\n" +
                  extract_function(text, "enum class JobPhase") + ";"),
        "gesture_struct": extract_function(text, "struct TouchGesture {") + ";",
        "layout_struct": extract_function(text, "struct PaintedTextLayout {") + ";",
        "frame_struct": extract_function(text, "struct AcceptedCaretRect {") + ";\n" +
                        extract_function(text, "struct TextPaintFrame {") + ";",
        "utf8_fn": extract_function(text, "std::u16string utf8ToUtf16(const std::string &utf8)"),
        "cancel_fn": extract_function(text, "bool cancelBeforeCommit()"),
        "post_fn": extract_function(text, "void post(const JobRef &job)"),
        "post_if_fn": extract_function(text, "bool postIfRunning(const JobRef &job)"),
        "hit_post_fn": extract_function(text, "bool postCaretHitAfterRedraw("),
        "lease_units_fn": extract_function(text, "static size_t leaseTableUnits("),
        "frozen_owner_fn": extract_function(text, "static int64_t cjguiOhosFrozenPaintOwnerVersion("),
        "drag_target_fn": extract_function(text, "uint64_t activePresentationDragTarget(uint64_t session)"),
        "plan_fn": extract_function(text, "void planPresentationLeaseReservation("),
        "publish_fn": extract_function(text, "void publishPaintedLayout(TextPaintFrame &frame)"),
        "hit_fn": extract_function(text, "CjguiInternalRendererStatus runPresentationHitLocked(CaretHitTestJob *job)"),
        "redraw_region": redraw_region,
        "present_region": present_region,
        "admission_block": admission_block,
        "retention_block": retention_block,
    }
    for key in ("post_fn", "post_if_fn", "hit_post_fn"):
        assert "kPresentationQueryQueueMax" in pieces[key], key
    # 释放线程归属本身不在宿主切片里冒充证明——它由设备原件（teardown 日志行的 TID）
    # 验证（见 D 组）。但那条**设备凭据成立的前提**是形状可断言的：释放量必须在
    # clear 之前取样。旧实现清空后才打印写死的 `retained=0`，既不区分"本来就空"与
    # "释放了 N 项"，也使该判据在设备上永远无法成立（结构性空洞）。
    teardown_fn = extract_function(text, "void teardownSurface(")
    assert "publishedPresentationLease.clear()" in teardown_fn, "teardown clears no lease"
    sample_slots = teardown_fn.find("releasedLeaseSlots = publishedPresentationLease.size()")
    sample_units = teardown_fn.find("releasedLeaseUnits = leaseTableUnits(publishedPresentationLease)")
    clear_at = teardown_fn.find("publishedPresentationLease.clear()")
    assert 0 <= sample_slots < sample_units < clear_at, \
        "lease release amount not sampled before clear (unfalsifiable log)"
    logged = teardown_fn[teardown_fn.find("lease cleared on teardown"):]
    assert "releasedLeaseSlots" in logged and "releasedLeaseUnits" in logged, \
        "teardown log does not report the measured release amount"
    # 三界判据、必需/可选分流与预留限制都在**准入块**里（生产文本已移到排版之前）。
    a = pieces["admission_block"]
    for needle in ("layout_not_retained", "layout_budget_exceeded",
                   "leaseTableUnits(publishedPresentationLease)",
                   "kPresentationLeaseNodeRunsMax", "leaseReservedSlotsLeft",
                   "leaseTransientUnits", "lastPaintLayout"):
        assert needle in a, needle
    # "准入在相关昂贵准备之前"是形状可断言的：准入块里不得出现排版调用，
    # 而排版调用紧随其后。
    assert "layoutTextStyled" not in a
    assert "OH_Drawing_TypographyCreate" not in a
    assert "auto retained = std::make_unique<PaintedTextLayout>()" in pieces["retention_block"]
    return pieces


HARNESS_HEAD = r'''
// 宿主 harness：真实生产切片 + 最小替身环境。OH_Drawing/日志为无行为替身；
// 判定逻辑全部来自抽取的生产文本。
#include <algorithm>
#include <atomic>
#include <condition_variable>
#include <cstdint>
#include <deque>
#include <iostream>
#include <map>
#include <memory>
#include <mutex>
#include <string>
#include <type_traits>
#include <vector>
// 日志替身：格式串 + 任意位置出现的 const char* 实参（具名 reason）拼接，
// 供 countLog 断言（数字实参跳过）。
static void logAppend(std::string &out, const char *s) { out += " "; out += s; }
template <typename T> static void logAppend(std::string &, T &&) {}
template <typename... A>
static std::string logJoin(const char *fmt, A &&...rest) {
  std::string out(fmt);
  (void)std::initializer_list<int>{(logAppend(out, rest), 0)...};
  return out;
}
#define RLOGI(...) do { g_logSink.push_back(logJoin(__VA_ARGS__)); } while(0)
#define RLOGW(...) do { g_logSink.push_back(logJoin(__VA_ARGS__)); } while(0)

enum CjguiInternalRendererStatus {
  CJGUI_INTERNAL_RENDERER_OK = 0,
  CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR = 2,
  CJGUI_INTERNAL_RENDERER_VIEW_INVALIDATED = 5,
  CJGUI_INTERNAL_RENDERER_METAL_DRAWABLE_UNAVAILABLE = 15,
  CJGUI_INTERNAL_RENDERER_GEOMETRY_EMPTY = 7,
  CJGUI_INTERNAL_RENDERER_PRESENT_PENDING = 20,
};
enum CjguiInternalRendererComposableNodeKind { kKindText = 3, kKindButton = 4, kKindTextInput = 5, kKindIntegerInput=6, kKindBooleanInput=7, kKindMultiline=10 };
enum OH_Drawing_ErrorCode { OH_DRAWING_SUCCESS = 0, OH_DRAWING_ERROR = 1 };

static unsigned long g_flushCount = 0;
static std::vector<std::string> g_logSink;
static int countLog(const char *needle) {
  int n = 0;
  for (const auto &l : g_logSink) if (l.find(needle) != std::string::npos) n += 1;
  return n;
}

struct OH_Drawing_Typography { int dummy = 0; };
static OH_Drawing_Typography *OH_Drawing_TypographyCreateStub() {
  static OH_Drawing_Typography t;
  return &t;
}
static void OH_Drawing_DestroyTypography(OH_Drawing_Typography *) {}
struct OH_Drawing_Surface { int dummy = 0; };
static OH_Drawing_ErrorCode OH_Drawing_SurfaceFlush(OH_Drawing_Surface *) {
  g_flushCount += 1;
  return OH_DRAWING_SUCCESS;
}
struct OH_Drawing_Canvas { int dummy = 0; };
static void OH_Drawing_CanvasSave(OH_Drawing_Canvas *) {}
static void OH_Drawing_CanvasRestore(OH_Drawing_Canvas *) {}
static void OH_Drawing_CanvasScale(OH_Drawing_Canvas *, float, float) {}
struct OH_Drawing_PositionAndAffinity { int unused; };
static OH_Drawing_PositionAndAffinity *OH_Drawing_TypographyGetGlyphPositionAtCoordinateWithCluster(
    OH_Drawing_Typography *, float, float) {
  static OH_Drawing_PositionAndAffinity pos;
  return &pos;
}
static size_t OH_Drawing_GetPositionFromPositionAndAffinity(OH_Drawing_PositionAndAffinity *) {
  return 2;
}
static int OH_Drawing_GetAffinityFromPositionAndAffinity(OH_Drawing_PositionAndAffinity *) {
  return 0;
}
static void OH_Drawing_DestroyPositionAndAffinity(OH_Drawing_PositionAndAffinity *) {}
static bool cjguiOhosGraphemeRange16(const std::u16string &, uint32_t pos,
                                     uint32_t &lo, uint32_t &hi) {
  lo = pos; hi = pos + 1; return true;
}
'''

HARNESS_REPLICAS = r'''
// ---- 最小替身值类型（真实抽取结构体在常量之后注入） ----
struct CjguiInternalRendererComposableNode {
  uint64_t nodeId = 0, projectionVersion = 0;
  int64_t resourceId = -1, x = 0, y = 0, width = 0, height = 0;
  uint32_t nodeKind = kKindText;
  uint32_t isInteractive = 1;
  uint32_t isReadOnly = 0;
  double fontSize = 13.0;
  uint32_t fontWeight = 400;
  uint64_t acceptedBindingEpoch = 0;
};
struct SceneNode {
  CjguiInternalRendererComposableNode pod;
  std::string value;
  // 生产准入只读 `.size()`（样式 runs 条数上界）；类型按最小替身提供。
  std::vector<uint32_t> textStyleRuns;
};
struct PaintedSelectionHandles { bool valid = false; uint32_t start = 0, end = 0; };
struct PresentJobStub {
  uint64_t session = 42, ticketId = 5, generation = 3, geometryRevision = 11;
  void *window = reinterpret_cast<void *>(0xABCD);
  int32_t width = 800, height = 600;
  CjguiInternalRendererStatus finishStatus = CJGUI_INTERNAL_RENDERER_OK;
  int finishCalls = 0;
  void finish(CjguiInternalRendererStatus s) { finishStatus = s; finishCalls += 1; }
};
'''


HARNESS_SESSION = r'''
// 会话替身：TouchGesture 为真实抽取结构；publish/hit 的会话分支按字段取值。
struct Session {
  AcceptedCaretRect activeCaret;
  using TouchGesture = ::TouchGesture;   // 生产文本以 Session::TouchGesture 限定
  TouchGesture gesture;
  uint64_t acceptedPaintTicketId = 0;
  PaintedSelectionHandles selectionHandles;
  bool editing = false, editingContextLive = false, editorRetired = false;
  bool previewActive = false;
  bool selectionIntentConfirmed = true;
  struct {bool armed=false,awaitingAck=false,platformInstalled=false;} proxyRestore;
  int64_t editingContextId = 0;
  uint32_t selStartUtf16 = 0, selEndUtf16 = 0;
  // 供生产 `planPresentationLeaseReservation` 的会话扫描使用（必需集合身份）。
  bool inUse = false;
  uint64_t token = 0;
  uint64_t editingNodeId = 0;
  int64_t editingMirrorOwnerVersion = -1;
};
static std::map<uint64_t, Session> g_sessionMap;
struct { std::mutex lock; Session sessions[kMaxSessions]; } g_sessions;
static Session *lookupSessionLocked(uint64_t id) {
  auto it = g_sessionMap.find(id);
  return it == g_sessionMap.end() ? nullptr : &it->second;
}
static std::u16string composedBuffer(const Session &) { return u""; }
static std::string displayTextForNode(const SceneNode &node) { return node.value; }
'''

HARNESS_MAIN_CLASS = r'''
// ---- 命中/队列任务的宿主替身：携带真实 cancelBeforeCommit（下方注入） ----
struct CjguiHitJob {
  std::u16string text;
  double fontSize = 13.0;
  uint32_t fontWeight = 400;
  double nodeWidth = 0, nodeHeight = 0, tapX = 0, tapY = 0;
  uint32_t nodeKind = 0;
  uint32_t caretUtf16 = 0;
  int32_t caretAffinity = 0;
  uint64_t session = 0, nodeId = 0, bindingEpoch = 0, projectionVersion = 0;
  int64_t resourceId = -1, contextId = 0, nodeX = 0, nodeY = 0;
  uint64_t paintSerial = 0, sourcePaintTicket = 0;
  bool presentation = false;
  JobKind kind = JobKind::CaretHitTest;
  std::mutex mutex;
  std::condition_variable cv;
  JobPhase phase = JobPhase::Queued;
  CjguiInternalRendererStatus status = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
%CANCEL_FN%
};
// RedrawJob 替身：队列只需一个 kind=Redraw 的任务对象；判定逻辑不读它的字段。
struct RedrawJob : CjguiHitJob { RedrawJob() { kind = JobKind::Redraw; } };
using CaretHitTestJob = CjguiHitJob;   // 生产文本的类型名
using JobRef = std::shared_ptr<CjguiHitJob>;

// ---- 查询队列界：真实 post / postIfRunning（下方注入） ----
struct QueueHarness {
  std::mutex lock;
  std::condition_variable cv;
  std::deque<JobRef> jobs;
  std::atomic<size_t> queuedCaretQueries{0};
  bool running = true, stopping = false;
  uint64_t renderEpoch = 7;
  void ensureStarted() {}
%POST_FN%
%POST_IF_FN%
%HIT_POST_FN%
};

// Accepted clip IO here supplies visible fixtures; the real clip/text entry is
// separately compiled by test_text_visible_budget_native.py.
static bool cjguiOhosTextIntersectsClip(const CjguiInternalRendererComposableNode &n) { return n.width > 0 && n.height > 0; }
%FROZEN_OWNER_FN%
// ---- 帧运行链：替身成员 + 真实抽取成员（计费/必需目标/发布/命中/保留块） ----
struct FrameHarness {
    OH_Drawing_Surface *surface = reinterpret_cast<OH_Drawing_Surface *>(0x1);
    OH_Drawing_Canvas *canvas = reinterpret_cast<OH_Drawing_Canvas *>(0x2);
    std::vector<SceneNode> lastNodes;
    uint64_t lastFrameSession = 42, lastFrameTicket = 5, lastProjectionVersion = 9;
    bool lastFrameMirrorValid = false; std::u16string lastFrameMirrorText; int64_t lastFrameMirrorOwnerVersion = -1;
    uint64_t lastFrameMirrorBindingEpoch = 0, lastFrameMirrorDeclaredBindingEpoch = 0, lastFrameOwnedNodeId = 0;
    int64_t lastFrameOwnedResourceId = -1, lastFrameSourceContextId = 0;
    uint32_t lastFrameOwnedNodeKind = 0;
    void *boundWindow = reinterpret_cast<void *>(0xABCD);
    uint64_t boundGeneration = 3, permitGeometryRevision = 11;
    uint64_t renderEpoch = 7;
    uint64_t textLayoutsBuilt = 0, textLayoutInputBytes = 0;
    uint64_t textPaintSerial = 0;
    uint64_t redrawFrames = 0;
    int32_t surfaceW = 800, surfaceH = 600;
    double surfaceDensity = 1.0;
    std::unique_ptr<PaintedTextLayout> lastPaintLayout;
    std::map<uint64_t, std::unique_ptr<PaintedTextLayout>> publishedPresentationLease;
    bool paintedLayoutUsable = false;
    int teardownCalls = 0;

    // teardown 的租约表释放由设备原件验证（宿主替身只计调用次数，不充当证据）。
    void teardownSurface(bool) { teardownCalls += 1; }
    bool leaseValid(uint64_t g) { return g == boundGeneration; }
    bool geometryMatches(void *w, uint64_t g, int, int, uint64_t rev) {
        return w == boundWindow && g == boundGeneration && rev == permitGeometryRevision;
    }
    void invalidatePaintedLayout(uint64_t) { paintedLayoutUsable = false; }
    bool applyClipChain(OH_Drawing_Canvas *, const CjguiInternalRendererComposableNode &) { return true; }
    void drawFill(OH_Drawing_Canvas *, const CjguiInternalRendererComposableNode &) {}
    void drawNodeImage(OH_Drawing_Canvas *, const SceneNode &) {}
    void drawBorder(OH_Drawing_Canvas *, const CjguiInternalRendererComposableNode &) {}

%LEASE_UNITS_FN%

%DRAG_TARGET_FN%

%PLAN_FN%

    // 真实生产切片逐字挂在最小替身环境上：**准入块**（三界计费、必需/可选分流、
    // 预留限制）与**登记块**（把本帧实际绘制的排版保留进租约表）都来自生产文本。
    // `isEditingNode` 由 `editingNodeUnderTest` 注入 ⇒ "实际编辑排版是否入账"可测；
    // 排版替身调用位于准入**之后** ⇒ `layoutCalls` 是"准入在昂贵准备之前"的可观测
    // 断言（被拒节点必须零排版调用）。
    uint64_t editingNodeUnderTest = 0;
    size_t layoutCalls = 0;

    void drawNodeText(OH_Drawing_Canvas *, const SceneNode &node, TextPaintFrame &frame)
    {
        uint32_t kind = node.pod.nodeKind;
        if (kind == 1) return;  // production drawNodeText excludes structural groups
        const bool isEditingNode = editingNodeUnderTest != 0 &&
                                   node.pod.nodeId == editingNodeUnderTest;
        std::u16string editComposed;
        if (isEditingNode) {
            for (char c : node.value) editComposed.push_back(static_cast<char16_t>(c));
        }
        std::string text = node.value;
        if (text.empty() && kind == kKindText && node.pod.isInteractive != 0 &&
            node.pod.isReadOnly == 0) text = " ";
        if (text.empty()) return;
        struct Measured { OH_Drawing_Typography *typography = nullptr; } m;
        struct Geom { double originX = 0.0, originY = 0.0; } geom;
%ADMISSION_BLOCK%
        m.typography = OH_Drawing_TypographyCreateStub();
        ++layoutCalls;
%RETENTION_BLOCK%
    }

%PUBLISH_FN%

%HIT_FN%

    void executeRedrawRegion()
    {
%REDRAW_REGION%
    }

    void presentTailRegion(PresentJobStub *job, TextPaintFrame &paintFrame)
    {
        (void)job;
        (void)paintFrame;
%PRESENT_REGION%
    }
};
'''

HARNESS_MAIN = r'''
static FrameHarness g_h;

static SceneNode makeTextNode(uint64_t id, size_t units) {
  SceneNode n;
  n.pod.nodeId = id;
  n.pod.nodeKind = kKindText;
  n.pod.isInteractive = 1;
  n.pod.isReadOnly = 0;
  n.pod.x = 0; n.pod.y = 0; n.pod.width = 100; n.pod.height = 20;
  for (size_t i = 0; i < units; ++i) n.value.push_back('a');
  return n;
}

static std::unique_ptr<CjguiHitJob> makeHitJob(uint64_t nodeId) {
  std::unique_ptr<CjguiHitJob> j(new CjguiHitJob());
  j->nodeId = nodeId;
  j->resourceId = -1;
  j->nodeKind = kKindText;
  j->session = 42;
  j->sourcePaintTicket = 5;
  j->projectionVersion = 0;   // pod 替身的投影版本默认 0，逐字段一致
  j->bindingEpoch = 0;
  j->text = u"a";
  j->nodeWidth = 100;
  j->nodeHeight = 20;
  j->nodeX = 0; j->nodeY = 0;
  j->fontSize = 13.0;
  j->fontWeight = 400;
  return j;
}

static void ensureHitSession() {
  g_sessionMap[42] = Session{};
  g_sessionMap[42].acceptedPaintTicketId = 5;
}

static void armDragTarget(uint64_t nodeId, uint32_t phase) {
  ensureHitSession();
  g_sessionMap[42].gesture.active = true;
  g_sessionMap[42].gesture.phase = phase;
  g_sessionMap[42].gesture.hasTarget = true;
  g_sessionMap[42].gesture.targetEditableText = false;
  g_sessionMap[42].gesture.targetNodeId = nodeId;
}

// 发布一帧 32 节点合法帧（旧表基线：32 条 / 每条 1 单元）。返回发布条目数。
// 从**空租约表**发布一帧：用来构造"旧表已占满额度"的必需集合超限负载。
static size_t publishFromEmpty(size_t count, size_t units) {
  g_sessionMap.clear();
  ensureHitSession();
  g_h.publishedPresentationLease.clear();
  g_h.lastPaintLayout.reset();
  g_h.editingNodeUnderTest = 0;
  g_h.lastNodes.clear();
  for (uint64_t id = 1; id <= count; ++id) g_h.lastNodes.push_back(makeTextNode(id, units));
  g_flushCount = 0;
  g_h.executeRedrawRegion();
  return g_h.publishedPresentationLease.size();
}

// 把会话置为"正在编辑该节点"：生产 plan 函数从 g_sessions 数组读必需身份。
static void armEditingTarget(uint64_t nodeId) {
  ensureHitSession();
  for (size_t i = 0; i < kMaxSessions; ++i) {
    Session &s = g_sessions.sessions[i];
    if (!s.inUse) {
      s.inUse = true;
      s.token = 42;
      s.editing = true;
      s.editorRetired = false;
      s.editingNodeId = nodeId;
      break;
    }
  }
}

static size_t publishBaseline() {
  g_sessionMap.clear();
  ensureHitSession();
  g_h.lastNodes.clear();
  for (uint64_t id = 1; id <= 32; ++id) g_h.lastNodes.push_back(makeTextNode(id, 1));
  g_flushCount = 0;
  g_h.executeRedrawRegion();
  return g_h.publishedPresentationLease.size();
}

int main() {
  unsigned long flushBase = 0;
  // ============ ① 可选第 65 个条目：具名不保留、照常 Flush、命中按名拒绝 ============
  // 计费含"同一 id 的旧条目将被本帧换代"的让位关系 ⇒ 稳定满表可以重绘，
  // 而真正的第 65 个条目（新 id）必须具名不保留。
  if (publishFromEmpty(kPresentationLeaseMax, 1) != kPresentationLeaseMax) return 10;
  flushBase = g_flushCount;
  g_logSink.clear();
  g_h.layoutCalls = 0;
  g_h.lastNodes.clear();
  for (uint64_t id = 1; id <= kPresentationLeaseMax; ++id)
      g_h.lastNodes.push_back(makeTextNode(id, 1));
  g_h.lastNodes.push_back(makeTextNode(900, 1));      // 第 65 个条目（可选）
  g_h.executeRedrawRegion();
  if (g_flushCount != flushBase + 1) return 11;       // 可选超限不拒帧
  if (countLog("layout_not_retained") != 1) return 12;
  if (countLog("entry_count_over_budget") != 1) return 13;
  if (g_h.publishedPresentationLease.size() != kPresentationLeaseMax) return 14;
  if (g_h.publishedPresentationLease.count(900) != 0) return 15;
  {
    auto j = makeHitJob(1);
    if (g_h.runPresentationHitLocked(j.get()) != CJGUI_INTERNAL_RENDERER_OK) return 16;
  }
  {
    auto j = makeHitJob(900);   // 具名不保留的条目：查询拒绝，不现场重排
    if (g_h.runPresentationHitLocked(j.get()) != CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR) return 17;
  }

  // ============ ① 必需集合**自身**无法满足：Flush 前拒候选，旧 accepted 保持 =====
  // 旧表已占满 64 条 ⇒ 必需目标（活动选择拖动）无论可选目标如何让位都放不下。
  // 必需目标排在绘制序列**首位**：被拒时整帧零排版（准入在昂贵准备之前）。
  if (publishFromEmpty(kPresentationLeaseMax, 1) != kPresentationLeaseMax) return 18;
  flushBase = g_flushCount;
  armDragTarget(900, static_cast<uint32_t>(TouchGesture::kGestureSelectionDrag));
  g_logSink.clear();
  g_h.layoutCalls = 0;
  g_h.lastNodes.clear();
  g_h.lastNodes.push_back(makeTextNode(900, 1));      // 必需目标：放不进任何额度
  for (uint64_t id = 1; id <= kPresentationLeaseMax; ++id)
      g_h.lastNodes.push_back(makeTextNode(id, 1));
  g_h.executeRedrawRegion();
  if (g_flushCount != flushBase) return 19;           // 零新 Flush
  if (countLog("layout_budget_exceeded") != 1) return 20;
  if (countLog("required: reject candidate before flush") != 1) return 21;
  if (countLog("redraw refused: presentation_lease_overflow") != 1) return 22;
  if (g_h.publishedPresentationLease.size() != kPresentationLeaseMax) return 23;
  if (g_h.layoutCalls != 0) return 24;                // 被拒节点零排版调用
  {
    auto j = makeHitJob(1);
    if (g_h.runPresentationHitLocked(j.get()) != CJGUI_INTERNAL_RENDERER_OK) return 25;
  }
  // 下一合法帧恢复（拖动结束，负载回到额度内）。
  g_sessionMap.clear();
  ensureHitSession();
  g_h.lastNodes.clear();
  for (uint64_t id = 1; id <= kPresentationLeaseMax; ++id)
      g_h.lastNodes.push_back(makeTextNode(id, 1));
  g_h.executeRedrawRegion();
  if (g_flushCount != flushBase + 1) return 26;
  if (g_h.publishedPresentationLease.size() != kPresentationLeaseMax) return 27;
  {
    auto j = makeHitJob(1);
    if (g_h.runPresentationHitLocked(j.get()) != CJGUI_INTERNAL_RENDERER_OK) return 28;
  }

  // ============ ② 单节点文字量越界（可选 skip / 必需拒候选） ============
  if (publishFromEmpty(32, 1) != 32) return 30;
  flushBase = g_flushCount;
  g_logSink.clear();
  g_h.lastNodes.clear();
  g_h.lastNodes.push_back(makeTextNode(501, kPresentationLeaseNodeTextMax + 1));
  for (uint64_t id = 1; id <= 32; ++id) g_h.lastNodes.push_back(makeTextNode(id, 1));
  g_h.executeRedrawRegion();
  if (countLog("layout_not_retained") != 1) return 31;
  if (countLog("node_text_over_budget") != 1) return 32;
  if (g_flushCount != flushBase + 1) return 33;       // 可选：不拒帧
  armDragTarget(901, static_cast<uint32_t>(TouchGesture::kGestureSelectionDrag));
  g_logSink.clear();
  g_h.lastNodes.clear();
  g_h.lastNodes.push_back(makeTextNode(901, kPresentationLeaseNodeTextMax + 1));
  for (uint64_t id = 1; id <= 32; ++id) g_h.lastNodes.push_back(makeTextNode(id, 1));
  g_h.executeRedrawRegion();
  if (g_flushCount != flushBase + 1) return 34;       // 必需：零新 Flush
  if (countLog("layout_budget_exceeded") != 1) return 35;
  if (countLog("node_text_over_budget") != 1) return 36;
  g_sessionMap.clear();
  ensureHitSession();

  // ============ ② 单节点样式 runs 越界（复用既有 64 条 runs 门） ============
  if (publishFromEmpty(8, 1) != 8) return 37;
  flushBase = g_flushCount;
  g_logSink.clear();
  {
    SceneNode n = makeTextNode(600, 1);
    n.textStyleRuns.resize(kPresentationLeaseNodeRunsMax + 1, 0xFF000000u);
    g_h.lastNodes.clear();
    g_h.lastNodes.push_back(n);
    for (uint64_t id = 1; id <= 8; ++id) g_h.lastNodes.push_back(makeTextNode(id, 1));
    g_h.executeRedrawRegion();
  }
  if (countLog("node_runs_over_budget") != 1) return 38;
  if (countLog("layout_not_retained") != 1) return 39;
  if (g_flushCount != flushBase + 1) return 200;      // 可选 runs 越界不拒帧
  if (g_h.publishedPresentationLease.size() != 8) return 201;

  // ============ ② 旧表 + 新条目共同工作量越界（只数新表时不红） ============
  // 旧表 32 × 8,100 = 259,200 单元；新 id 3,000 单元 ⇒ 262,200 > 262,144。
  if (publishFromEmpty(32, 8100) != 32) return 40;
  if (g_flushCount != 1) return 41;
  flushBase = g_flushCount;
  g_logSink.clear();
  g_h.lastNodes.clear();
  g_h.lastNodes.push_back(makeTextNode(700, 3000));    // 新 id（可选）
  for (uint64_t id = 1; id <= 32; ++id) g_h.lastNodes.push_back(makeTextNode(id, 8100));
  g_h.executeRedrawRegion();
  if (countLog("layout_not_retained") != 1) return 42;
  if (countLog("total_workload_over_budget") != 1) return 43;
  if (g_flushCount != flushBase + 1) return 44;        // 可选：帧照常提交
  if (g_h.publishedPresentationLease.count(700) != 0) return 45;
  flushBase = g_flushCount;
  armDragTarget(902, static_cast<uint32_t>(TouchGesture::kGestureSelectionDrag));
  g_logSink.clear();
  g_h.lastNodes.clear();
  g_h.lastNodes.push_back(makeTextNode(902, 3000));    // 必需：自身就放不下
  for (uint64_t id = 1; id <= 32; ++id) g_h.lastNodes.push_back(makeTextNode(id, 8100));
  g_h.executeRedrawRegion();
  if (g_flushCount != flushBase) return 46;            // 零新 Flush
  if (countLog("layout_budget_exceeded") != 1) return 47;
  if (countLog("total_workload_over_budget") != 1) return 48;
  if (g_h.publishedPresentationLease.size() != 32) return 49;
  g_sessionMap.clear();
  ensureHitSession();

  // ============ 实际编辑排版入账：编辑节点的排版量必须进共同峰值 ============
  // 旧表 15 × 16,384 = 245,760 单元；编辑节点本次 16,000 + 新可选 1,000：
  // 编辑量入账 ⇒ 可选目标越界（必需集合本身放得下，帧仍 Flush）；漏账 ⇒ 结论翻转。
  if (publishFromEmpty(15, kPresentationLeaseNodeTextMax) != 15) return 100;
  flushBase = g_flushCount;
  armEditingTarget(800);
  g_h.editingNodeUnderTest = 800;
  g_h.lastPaintLayout.reset();
  g_logSink.clear();
  g_h.lastNodes.clear();
  g_h.lastNodes.push_back(makeTextNode(800, 16000));
  g_h.lastNodes.push_back(makeTextNode(801, 1000));
  g_h.executeRedrawRegion();
  if (g_flushCount != flushBase + 1) return 101;
  if (countLog("layout_not_retained") != 1) return 102;
  if (countLog("total_workload_over_budget") != 1) return 103;
  if (g_h.publishedPresentationLease.count(801) != 0) return 104;
  if (g_h.publishedPresentationLease.count(800) != 0) return 105;   // 编辑排版不入表
  g_h.editingNodeUnderTest = 0;

  // ============ 上一帧仍存活的实际编辑排版（真实峰值）也必须入账 ============
  // 旧表 32 × 1 单元 + 上一帧编辑排版 262,145 单元 > 总上限 262,144：漏账时本帧
  // 照常 Flush（历史 RED），落实"旧+新+临时"共同计费后必须 Flush 前拒候选。
  if (publishFromEmpty(32, 1) != 32) return 106;
  flushBase = g_flushCount;
  {
    std::unique_ptr<PaintedTextLayout> peak(new PaintedTextLayout());
    peak->text = std::u16string(262145, u'a');
    peak->node.nodeId = 903;
    g_h.lastPaintLayout = std::move(peak);
  }
  armDragTarget(903, static_cast<uint32_t>(TouchGesture::kGestureSelectionDrag));
  g_logSink.clear();
  g_h.lastNodes.clear();
  for (uint64_t id = 1; id <= 32; ++id) g_h.lastNodes.push_back(makeTextNode(id, 1));
  g_h.lastNodes.push_back(makeTextNode(903, 1));
  g_h.executeRedrawRegion();
  if (g_flushCount != flushBase) return 107;           // 零新 Flush
  if (countLog("layout_budget_exceeded") != 1) return 108;
  if (g_h.publishedPresentationLease.size() != 32) return 109;
  g_h.lastPaintLayout.reset();
  g_sessionMap.clear();
  ensureHitSession();

  // ============ 同一负载：必需目标在首位 / 末位，结论必须一致 ============
  // 旧表 63 条 ⇒ 恰好 1 条额度：1 个新可选 + 1 个新必需。无预留时末位必需目标
  // 会被可选目标挤掉（历史 RED：仅换顺序就从"保留成功"变"Flush 前拒帧"）。
  {
    size_t flushTail = 0, retainedTail = 0, skippedTail = 0;
    bool requiredTail = false, refusedTail = false;
    if (publishFromEmpty(63, 1) != 63) return 110;
    flushBase = g_flushCount;
    armDragTarget(900, static_cast<uint32_t>(TouchGesture::kGestureSelectionDrag));
    g_logSink.clear();
    g_h.lastNodes.clear();
    for (uint64_t id = 1; id <= 63; ++id) g_h.lastNodes.push_back(makeTextNode(id, 1));
    g_h.lastNodes.push_back(makeTextNode(700, 1));      // 新可选
    g_h.lastNodes.push_back(makeTextNode(900, 1));      // 新必需：**末位**
    g_h.executeRedrawRegion();
    flushTail = g_flushCount - flushBase;
    retainedTail = g_h.publishedPresentationLease.size();
    requiredTail = g_h.publishedPresentationLease.count(900) == 1;
    skippedTail = (size_t)countLog("layout_not_retained");
    refusedTail = countLog("layout_budget_exceeded") != 0;
    g_sessionMap.clear();
    ensureHitSession();
    if (refusedTail || flushTail != 1) return 111;      // 末位不得拒帧
    if (!requiredTail) return 112;                      // 必需目标必须保留
    if (retainedTail != kPresentationLeaseMax) return 113;
    if (skippedTail != 1) return 114;                   // 恰一个可选让位
    if (g_h.publishedPresentationLease.count(700) != 0) return 115;

    if (publishFromEmpty(63, 1) != 63) return 116;
    flushBase = g_flushCount;
    armDragTarget(900, static_cast<uint32_t>(TouchGesture::kGestureSelectionDrag));
    g_logSink.clear();
    g_h.lastNodes.clear();
    g_h.lastNodes.push_back(makeTextNode(900, 1));      // 同一负载：**首位**
    g_h.lastNodes.push_back(makeTextNode(700, 1));
    for (uint64_t id = 1; id <= 63; ++id) g_h.lastNodes.push_back(makeTextNode(id, 1));
    g_h.executeRedrawRegion();
    if (g_flushCount - flushBase != flushTail) return 117;
    if (g_h.publishedPresentationLease.size() != retainedTail) return 118;
    if (g_h.publishedPresentationLease.count(900) != 1) return 119;
    if (countLog("layout_not_retained") != (int)skippedTail) return 120;
    if (countLog("layout_budget_exceeded") != 0) return 121;
    g_sessionMap.clear();
    ensureHitSession();
  }

  // ============ ③ 排队查询遇新 Flush / resize：具名失败、零新布局 ============
  if (publishFromEmpty(32, 1) != 32) return 122;
  {
    auto j = makeHitJob(1);
    if (g_h.runPresentationHitLocked(j.get()) != CJGUI_INTERNAL_RENDERER_OK) return 123;
  }
  g_h.layoutCalls = 0;
  g_logSink.clear();
  g_sessionMap[42].acceptedPaintTicketId = 6;          // 新 Flush 取代绑定身份
  {
    auto j = makeHitJob(1);
    if (g_h.runPresentationHitLocked(j.get()) !=
        CJGUI_INTERNAL_RENDERER_PRESENT_PENDING) return 124;
  }
  if (countLog("scene_ticket_stale") != 1) return 125;
  g_sessionMap[42].acceptedPaintTicketId = 5;
  g_h.permitGeometryRevision = 12;                     // resize：几何代际变化
  {
    auto j = makeHitJob(1);
    if (g_h.runPresentationHitLocked(j.get()) !=
        CJGUI_INTERNAL_RENDERER_VIEW_INVALIDATED) return 126;
  }
  if (countLog("retained_layout_stale") != 1) return 127;
  if (g_h.layoutCalls != 0) return 128;                // 过期查询零新布局
  g_h.permitGeometryRevision = 11;

  // ============ ③ 投递点界：postCaretHitAfterRedraw 不得绕过队列上界 ============
  {
    QueueHarness q;
    JobRef lead(new CjguiHitJob());
    if (!q.postCaretHitAfterRedraw(lead, q.renderEpoch)) return 129;   // 正控：首笔入队
    if (q.jobs.size() != 2) return 130;
    if (q.queuedCaretQueries.load() != 1) return 131;
    for (size_t i = 0; i < kPresentationQueryQueueMax; ++i) {
      JobRef more(new CjguiHitJob());
      q.post(more);
    }
    g_logSink.clear();
    JobRef over(new CjguiHitJob());
    if (q.postCaretHitAfterRedraw(over, q.renderEpoch)) return 132;    // 满界必须拒
    if (over->phase != JobPhase::Cancelled) return 133;
    if (countLog("query_queue_over_budget") != 1) return 134;
  }

  // ============ ③ 查询队列界：真实 post / postIfRunning ============
  {
    QueueHarness q;
    for (size_t i = 0; i < kPresentationQueryQueueMax; ++i) {
      JobRef job(new CjguiHitJob());
      q.post(job);
      if (job->phase != JobPhase::Queued) return 50;
    }
    g_logSink.clear();
    JobRef over(new CjguiHitJob());
    q.post(over);
    if (over->phase != JobPhase::Cancelled) return 53;   // 第 33 个查询具名拒绝
    if (countLog("query_queue_over_budget") != 1) return 54;
    g_logSink.clear();
    JobRef over2(new CjguiHitJob());
    if (!q.postIfRunning(over2)) return 55;
    if (over2->phase != JobPhase::Cancelled) return 56;
    if (countLog("query_queue_over_budget") != 1) return 57;
  }

  // ============ present 拒候选切片：门在 Flush 声明之前、终态具名 ============
  {
    TextPaintFrame f;
    PresentJobStub job;
    g_h.presentTailRegion(&job, f);
    if (job.finishCalls != 0) return 60;   // 无溢出：不拒（直达 Flush 声明）
    f.presentationLeaseOverflow = true;
    g_h.presentTailRegion(&job, f);
    if (job.finishCalls != 1) return 61;
    if (job.finishStatus != CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR) return 62;
  }

  // A full prior table already contains the required captured target. Chrome
  // before it must not double-reserve that target and reject the whole frame.
  g_sessionMap.clear(); ensureHitSession();
  if (publishFromEmpty(kPresentationLeaseMax, 1) != kPresentationLeaseMax) return 140;
  armDragTarget(1, static_cast<uint32_t>(TouchGesture::kGestureSelectionDrag));
  for(size_t i=0;i<kMaxSessions;++i)g_sessions.sessions[i]=Session{};
  armEditingTarget(190); // structural proxy is never text-painted
  flushBase=g_flushCount;g_logSink.clear();g_h.lastNodes.clear();
  auto chrome=makeTextNode(999,11);chrome.pod.nodeKind=4;
  g_h.lastNodes.push_back(chrome);
  auto carrier=makeTextNode(190,0);carrier.pod.nodeKind=1;g_h.lastNodes.push_back(carrier);
  for(uint64_t id=1;id<=kPresentationLeaseMax;++id)g_h.lastNodes.push_back(makeTextNode(id,1));
  g_h.executeRedrawRegion();
  if(g_flushCount!=flushBase+1 || countLog("transient_peak_over_budget")!=0) return 141;
  if(g_h.publishedPresentationLease.size()>kPresentationLeaseMax) return 142;

  std::cout << "presentation_budget_real_frame=ok" << std::endl;
  return 0;
}
'''


def assemble(text=None):
    p = build_pieces(text)
    src = HARNESS_HEAD + "\n" + p["constants"] + "\n" + p["enums"] + "\n" \
        + HARNESS_REPLICAS + "\n" + p["gesture_struct"] + "\n" \
        + p["layout_struct"] + "\n" + p["frame_struct"] \
        + "\n" + p["utf8_fn"] + "\n" + HARNESS_SESSION + "\n" + HARNESS_MAIN_CLASS
    src = src.replace("%CANCEL_FN%", p["cancel_fn"])
    src = src.replace("%POST_FN%", p["post_fn"])
    src = src.replace("%POST_IF_FN%", p["post_if_fn"])
    src = src.replace("%HIT_POST_FN%", p["hit_post_fn"])
    src = src.replace("%LEASE_UNITS_FN%", p["lease_units_fn"])
    src = src.replace("%FROZEN_OWNER_FN%", p["frozen_owner_fn"])
    src = src.replace("%DRAG_TARGET_FN%", p["drag_target_fn"])
    src = src.replace("%PUBLISH_FN%", p["publish_fn"])
    src = src.replace("%HIT_FN%", p["hit_fn"])
    src = src.replace("%RETENTION_BLOCK%", p["retention_block"])
    src = src.replace("%ADMISSION_BLOCK%", p["admission_block"])
    src = src.replace("%PLAN_FN%", p["plan_fn"])
    src = src.replace("%REDRAW_REGION%", p["redraw_region"])
    src = src.replace("%PRESENT_REGION%", p["present_region"])
    src += HARNESS_MAIN
    return src


def build_and_run(harness):
    with tempfile.TemporaryDirectory() as td:
        cpp = pathlib.Path(td) / "budget_real_frame.cpp"
        cpp.write_text(harness, encoding="utf-8")
        exe = pathlib.Path(td) / "budget_real_frame"
        build = subprocess.run(
            ["clang++", "-std=c++17", "-Wall", "-Wextra",
             "-Wno-unused-parameter", "-Wno-unused-variable",
             "-o", str(exe), str(cpp)],
            capture_output=True, text=True)
        if build.returncode != 0:
            raise AssertionError(f"harness compile failed:\n{build.stderr[-4000:]}")
        return subprocess.run([str(exe)], capture_output=True, text=True,
                              timeout=60)


class PresentationBudgetRealFrameTest(unittest.TestCase):
    def test_real_frame_counterexamples(self):
        run = build_and_run(assemble())
        self.assertEqual(
            run.returncode, 0,
            f"real-frame chain red (exit {run.returncode}):\n"
            f"stdout tail: {run.stdout[-1500:]}\nstderr tail: {run.stderr[-800:]}")
        self.assertIn("presentation_budget_real_frame=ok", run.stdout)

    def test_harness_exit_codes_are_unambiguous(self):
        """退出码按 256 取模：任何 ≥256 的 return 都会伪装成别的结论。"""
        codes = [int(c) for c in re.findall(r"return (\d+);", HARNESS_MAIN)]
        self.assertGreater(len(codes), 40, "no leg codes found")
        self.assertEqual([c for c in codes if not 0 <= c < 256], [],
                         "ambiguous exit code (>=256) in harness main")
        self.assertEqual(len(set(codes)), len(codes), "duplicate leg exit code")

    def test_production_ordering_anchors(self):
        """结构断言：门在 Flush 之前、具名分流与三界常量存在于生产文本。"""
        text = SOURCE.read_text(encoding="utf-8")
        a = text.index(REDRAW_START)
        b = text.index(REDRAW_END, a)
        region = text[a:b]
        self.assertLess(region.index("redraw refused: presentation_lease_overflow"),
                        region.index("OH_Drawing_SurfaceFlush"))
        p0 = text.index(PRESENT_COMMENT)
        p1 = text.index(PRESENT_FLUSH_DECL, p0)
        self.assertIn("present refused: presentation_lease_overflow", text[p0:p1])
        self.assertIn("layout_not_retained", text)
        self.assertIn("layout_budget_exceeded", text)
        for name in ("kPresentationLeaseNodeTextMax", "kPresentationLeaseTotalUnitsMax",
                     "kPresentationQueryQueueMax", "leaseTableUnits(publishedPresentationLease)"):
            self.assertIn(name, text)


class MutationDiscriminationTest(unittest.TestCase):
    """判别力自检：对生产文本做两类历史漏检变异，harness 必须翻红。
    （fixla19-review/overflow-gate-coverage-result.json 证明旧 harness 对这两类
    变异无感；本文件按构造必须敏感。）"""

    def _run_mutated(self, mutate, expect):
        text = SOURCE.read_text(encoding="utf-8")
        mutated = mutate(text)
        self.assertNotEqual(mutated, text, "mutation did not apply")
        self.addCleanup(lambda: None)
        if expect == "extract_fails":
            with self.assertRaises(AssertionError):
                build_pieces(mutated)
            return
        run = build_and_run(assemble(mutated))
        self.assertNotEqual(run.returncode, 0,
                            "mutated production still passed the run chain")

    def test_gate_moved_after_flush_is_detected(self):
        # 把 redraw 溢出门整块搬到 SurfaceFlush 之后：抽取结构断言必须失败。
        def mutate(text):
            anchor = "        if (paintFrame.presentationLeaseOverflow) {"
            i = text.index("redraw refused: presentation_lease_overflow")
            start = text.rindex(anchor, 0, i)
            block = balanced_block(text, start)
            flushed = text.index("OH_Drawing_SurfaceFlush", start + len(block))
            # 搬到 redraw 的 Flush 调用之后
            insert_at = text.index("publishPaintedLayout(paintFrame);", flushed)
            return text[:start] + text[start + len(block):insert_at] + block + \
                text[insert_at:]
        self._run_mutated(mutate, "extract_fails")

    def test_billing_ignoring_published_table_is_detected(self):
        # 计费只数新表＋临时：② 的「旧 published + 新 candidate + 临时峰值」共同
        # 计费反例必须翻红（生产表达式为两行，变异按当前文本锚定）。
        def mutate(text):
            return text.replace(
                "const size_t heldUnits = leaseTableUnits(publishedPresentationLease) -",
                "const size_t heldUnits = std::min(leaseTableUnits(publishedPresentationLease), size_t(0)) -", 1)
        self._run_mutated(mutate, "run_red")

    def test_billing_ignoring_transient_peak_is_detected(self):
        # 「实际编辑排版漏账」原反例的等价变异：临时峰值（上一帧 lastPaintLayout /
        # 本帧待保留文本）不计入总工作量，② 的峰值越界腿必须翻红。
        def mutate(text):
            return text.replace(
                "leaseTableUnits(frame.presentationLease) + frame.leaseTransientUnits;",
                "leaseTableUnits(frame.presentationLease);", 1)
        self._run_mutated(mutate, "run_red")

    def test_admission_after_expensive_layout_is_detected(self):
        # 准入必须在昂贵准备之前：把 layoutTextStyled 提到准入块之前，
        # build_pieces 的结构断言（准入块内不得含排版创建）必须失败。
        def mutate(text):
            i = text.index(ADMISSION_TRIGGER)
            cut = text.index("\n", i) + 1
            return (text[:cut] + "        OH_Drawing_TypographyCreateStub();\n" + text[cut:])
        self._run_mutated(mutate, "extract_fails")

    def test_required_reservation_removed_is_detected(self):
        # 绘制前预留额度消失：可选目标占尽额度、必需目标被拒 → ②顺序无关腿翻红。
        def mutate(text):
            return text.replace(
                "const size_t reserveSlots = requiredHere ? 0 : frame.leaseReservedSlotsLeft;",
                "const size_t reserveSlots = 0;", 1)
        self._run_mutated(mutate, "run_red")

    def test_teardown_unmeasured_release_amount_is_detected(self):
        # 变异：退回旧实现——清空后才打印写死的 retained=0。结构断言必须失败，
        # 否则"资源在渲染线程释放"这条设备判据又变成不可证（无前置非零观测）。
        measured = (
            "        const size_t releasedLeaseSlots = publishedPresentationLease.size();\n"
            "        const size_t releasedLeaseUnits = leaseTableUnits(publishedPresentationLease);\n"
            "        publishedPresentationLease.clear();\n"
            '        RLOGI("presentation lease cleared on teardown released_slots=%{public}zu "\n'
            '              "released_units=%{public}zu remaining=0",\n'
            "              releasedLeaseSlots, releasedLeaseUnits);\n")
        constant = ('        publishedPresentationLease.clear();\n'
                    '        RLOGI("presentation lease cleared on teardown retained=0");\n')

        def mutate(text):
            assert measured in text, "teardown measurement anchor moved"
            return text.replace(measured, constant, 1)
        self._run_mutated(mutate, "extract_fails")


if __name__ == "__main__":
    unittest.main(verbosity=2)

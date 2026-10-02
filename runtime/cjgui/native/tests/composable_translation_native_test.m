// One accepted geometry drives the production hit, AX and FIFO event paths.
#define CJGUI_INTERNAL_TESTING 1
#import "../cjgui_internal_renderer.m"
#import <AppKit/AppKit.h>
#include <math.h>
#include <stdio.h>

static int require(BOOL passed, const char *name) {
    if (passed) return 0;
    fprintf(stderr, "F11_TRANSLATION_RED %s\n", name);
    return 1;
}

static double sampleX = -1.0;
static double sampleY = 1.0;
static uint8_t sampledGreen = 0;

static CjguiInternalRendererStatus submit(uint64_t session, uint64_t version,
    double parentX, double parentY, double childLocalX, double childLocalY,
    BOOL invalidGeometry) {
    CjguiInternalRendererComposableNode root = {0}, child = {0};
    root.nodeId = 100; root.projectionVersion = version; root.resourceId = -1;
    root.nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_VERTICAL;
    root.x = 0; root.y = 0; root.width = 60; root.height = 30;
    root.clipX = 0; root.clipY = 0; root.clipWidth = 120; root.clipHeight = 80;
    root.clipConstraintCount = 1;
    root.clip0X = 0; root.clip0Y = 0; root.clip0Width = 120; root.clip0Height = 80;
    root.effectGroupSubtreeCount = 2;
    child.nodeId = 101; child.projectionVersion = version; child.resourceId = -1;
    child.nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_BUTTON;
    child.isInteractive = 1; child.x = 2; child.y = 0; child.width = 20; child.height = 20;
    child.clipX = 0; child.clipY = 0; child.clipWidth = 60; child.clipHeight = 30;
    child.clipConstraintCount = 2;
    child.clip0X = 0; child.clip0Y = 0; child.clip0Width = 120; child.clip0Height = 80;
    child.clip1X = 0; child.clip1Y = 0; child.clip1Width = 60; child.clip1Height = 30;
    child.effectGroupSubtreeCount = 1;
    child.fillRed = 1.0; child.fillGreen = 0.1; child.fillBlue = 0.1;
    child.fillAlpha = 1.0; child.textAlpha = 1.0;
    CjguiInternalRendererComposableGeometry rootVisual = {0}, childVisual = {0};
    rootVisual.nodeId = root.nodeId; rootVisual.clipCount = 1;
    rootVisual.translateX = parentX; rootVisual.translateY = parentY;
    childVisual.nodeId = child.nodeId; childVisual.clipCount = 2;
    childVisual.translateX = parentX + childLocalX;
    childVisual.translateY = parentY + childLocalY;
    childVisual.clip1X = parentX; childVisual.clip1Y = parentY;
    CjguiInternalRendererStatus status = cjgui_internal_renderer_configure_composable_scene(session, version, 2);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
    status = cjgui_internal_renderer_set_composable_scene_node(session, 0, &root, "", "", "root", "", 0);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
    status = cjgui_internal_renderer_set_composable_scene_node(session, 1, &child, "Go", "", "child", "", 0);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
    status = cjgui_internal_renderer_set_composable_scene_geometry(session, version, 0, &rootVisual);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
    if (invalidGeometry) childVisual.translateX = 5000.0;
    status = cjgui_internal_renderer_set_composable_scene_geometry(session, version, 1, &childVisual);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
    status = cjgui_internal_renderer_stage_window_background(session, version, 0, 1);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
    if (sampleX >= 0.0) {
        status = cjgui_internal_renderer_test_request_composable_drawable_pixel_precise(
            session, sampleX, sampleY);
        if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
    }
    CjguiInternalRendererFrameObservation frame = {0};
    status = cjgui_internal_renderer_present_composable_scene(session, &frame);
    if (status == CJGUI_INTERNAL_RENDERER_OK && sampleX >= 0.0) {
        uint8_t b = 0, g = 0, r = 0, a = 0;
        status = cjgui_internal_renderer_test_composable_drawable_pixel(session, &b, &g, &r, &a);
        if (status == CJGUI_INTERNAL_RENDERER_OK) sampledGreen = g;
    }
    return status;
}

static CjguiInternalRendererStatus submitBackdrop(uint64_t session, uint64_t version,
    double sourceTranslateX, uint8_t outBGRA[4]) {
    CjguiInternalRendererComposableNode nodes[3] = {0};
    CjguiInternalRendererComposableGeometry geometry[3] = {0};
    nodes[0].nodeId = 300; nodes[0].projectionVersion = version; nodes[0].resourceId = -1;
    nodes[0].nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_VERTICAL;
    nodes[0].x = 0; nodes[0].y = 0; nodes[0].width = 60; nodes[0].height = 80;
    nodes[0].fillRed = 1.0; nodes[0].fillAlpha = 1.0;
    nodes[0].effectGroupSubtreeCount = 1;
    nodes[1].nodeId = 301; nodes[1].projectionVersion = version; nodes[1].resourceId = -1;
    nodes[1].nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_VERTICAL;
    nodes[1].x = 45; nodes[1].y = 15; nodes[1].width = 50; nodes[1].height = 50;
    nodes[1].effectGroupPresent = 1; nodes[1].effectGroupSubtreeCount = 2;
    nodes[1].effectGroupOpacity = 1.0; nodes[1].effectBackdropBlurRadiusPoints = 4;
    nodes[2].nodeId = 302; nodes[2].projectionVersion = version; nodes[2].resourceId = -1;
    nodes[2].nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_VERTICAL;
    nodes[2].x = 45; nodes[2].y = 15; nodes[2].width = 50; nodes[2].height = 50;
    nodes[2].effectGroupSubtreeCount = 1;
    for (uint32_t index = 0; index < 3; index++) {
        nodes[index].clipX = 0; nodes[index].clipY = 0;
        nodes[index].clipWidth = 120; nodes[index].clipHeight = 80;
        nodes[index].clipConstraintCount = 1;
        nodes[index].clip0X = 0; nodes[index].clip0Y = 0;
        nodes[index].clip0Width = 120; nodes[index].clip0Height = 80;
        geometry[index].nodeId = nodes[index].nodeId;
        geometry[index].clipCount = 1;
    }
    geometry[0].translateX = sourceTranslateX;
    CjguiInternalRendererStatus status = cjgui_internal_renderer_configure_composable_scene(session, version, 3);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
    for (uint32_t index = 0; index < 3; index++) {
        status = cjgui_internal_renderer_set_composable_scene_node(session, index, &nodes[index],
            "", "", "", "", 0);
        if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
        status = cjgui_internal_renderer_set_composable_scene_geometry(session, version,
            index, &geometry[index]);
        if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
    }
    status = cjgui_internal_renderer_stage_window_background(session, version, 0, 1);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
    status = cjgui_internal_renderer_test_request_composable_drawable_pixel_precise(session, 60.5, 40.0);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
    CjguiInternalRendererFrameObservation frame = {0};
    status = cjgui_internal_renderer_present_composable_scene(session, &frame);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
    return cjgui_internal_renderer_test_composable_drawable_pixel(session,
        &outBGRA[0], &outBGRA[1], &outBGRA[2], &outBGRA[3]);
}

static CjguiInternalRendererStatus submitLongTextWithTransport(uint64_t session, uint64_t version,
    double nodeTranslateY, double clipTranslateY, BOOL preserveActiveLocalText) {
    static NSMutableString *body = nil;
    if (!body) {
        body = [[NSMutableString alloc] init];
        for (NSUInteger row = 0; row < 720; row++)
            [body appendFormat:@"row %04lu 中文🙂\n", (unsigned long)row];
    }
    CjguiInternalRendererComposableNode node = {0};
    node.nodeId = 990; node.projectionVersion = version; node.resourceId = -1;
    node.nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT;
    node.x = 0; node.y = 0; node.width = 1000; node.height = 10000;
    node.clipX = 0; node.clipY = 0; node.clipWidth = 1000; node.clipHeight = 400;
    node.clipConstraintCount = 1;
    node.clip0X = 0; node.clip0Y = 0; node.clip0Width = 1000; node.clip0Height = 400;
    node.effectGroupSubtreeCount = 1;
    node.isInteractive = 1;
    node.preservesActiveLocalText = preserveActiveLocalText ? 1 : 0;
    node.textAlpha = 1.0; node.textRed = 0.0; node.textGreen = 0.0; node.textBlue = 0.0;
    node.fontSize = 14.0;
    CjguiInternalRendererComposableGeometry geometry = {0};
    geometry.nodeId = node.nodeId; geometry.clipCount = 1;
    geometry.translateY = nodeTranslateY; geometry.clip0Y = clipTranslateY;
    CjguiInternalRendererStatus status = cjgui_internal_renderer_configure_composable_scene(session, version, 1);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
    status = cjgui_internal_renderer_set_composable_scene_node(session, 0, &node,
        "", preserveActiveLocalText ? "" : body.UTF8String, "long text", "", 0);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
    status = cjgui_internal_renderer_set_composable_scene_geometry(session, version, 0, &geometry);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
    status = cjgui_internal_renderer_stage_window_background(session, version, 0, 1);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
    CjguiInternalRendererFrameObservation frame = {0};
    return cjgui_internal_renderer_present_composable_scene(session, &frame);
}

static CjguiInternalRendererStatus submitLongText(uint64_t session, uint64_t version,
    double nodeTranslateY, double clipTranslateY) {
    return submitLongTextWithTransport(session, version, nodeTranslateY, clipTranslateY, NO);
}

static CjguiInternalRendererStatus submitClippedSingleLineWithTransport(uint64_t session,
    uint64_t version, double translateX, BOOL preserveActiveLocalText) {
    static NSMutableString *body = nil;
    if (!body) {
        body = [[NSMutableString alloc] init];
        for (NSUInteger index = 0; index < 150; index++) [body appendString:@"中"];
    }
    CjguiInternalRendererComposableNode node = {0};
    node.nodeId = 991; node.projectionVersion = version; node.resourceId = -1;
    node.nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT_INPUT;
    node.x = 0; node.y = 0; node.width = 1000; node.height = 40;
    node.clipX = 0; node.clipY = 0; node.clipWidth = 100; node.clipHeight = 40;
    node.clipConstraintCount = 1;
    node.clip0X = 0; node.clip0Y = 0; node.clip0Width = 100; node.clip0Height = 40;
    node.effectGroupSubtreeCount = 1; node.isInteractive = 1;
    node.preservesActiveLocalText = preserveActiveLocalText ? 1 : 0;
    node.textAlpha = 1.0; node.fontSize = 14.0;
    CjguiInternalRendererComposableGeometry geometry = {0};
    geometry.nodeId = node.nodeId; geometry.clipCount = 1;
    geometry.translateX = translateX;
    CjguiInternalRendererStatus status = cjgui_internal_renderer_configure_composable_scene(session, version, 1);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
    status = cjgui_internal_renderer_set_composable_scene_node(session, 0, &node,
        "", preserveActiveLocalText ? "" : body.UTF8String, "single-line", "", 0);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
    status = cjgui_internal_renderer_set_composable_scene_geometry(session, version, 0, &geometry);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
    status = cjgui_internal_renderer_stage_window_background(session, version, 0, 1);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
    CjguiInternalRendererFrameObservation frame = {0};
    return cjgui_internal_renderer_present_composable_scene(session, &frame);
}

static CjguiInternalRendererStatus submitControl(uint64_t session, uint64_t version,
    uint64_t nodeId, int64_t resourceId, uint32_t kind, double translateX) {
    CjguiInternalRendererComposableNode node = {0};
    node.nodeId = nodeId; node.resourceId = resourceId; node.projectionVersion = version;
    node.nodeKind = kind; node.isInteractive = 1;
    node.width = 20; node.height = 20;
    node.clipWidth = 120; node.clipHeight = 80;
    node.clipConstraintCount = 1;
    node.clip0Width = 120; node.clip0Height = 80;
    node.effectGroupSubtreeCount = 1;
    node.textAlpha = 1.0;
    CjguiInternalRendererComposableGeometry geometry = {0};
    geometry.nodeId = nodeId; geometry.clipCount = 1; geometry.translateX = translateX;
    CjguiInternalRendererStatus status = cjgui_internal_renderer_configure_composable_scene(session, version, 1);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
    status = cjgui_internal_renderer_set_composable_scene_node(session, 0, &node,
        kind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_BUTTON ? "Go" : "", "", "control", "", 0);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
    status = cjgui_internal_renderer_set_composable_scene_geometry(session, version, 0, &geometry);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
    status = cjgui_internal_renderer_stage_window_background(session, version, 0, 1);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
    CjguiInternalRendererFrameObservation frame = {0};
    return cjgui_internal_renderer_present_composable_scene(session, &frame);
}

// M2（视觉导航）对照夹具：bidi 行 + 软折行长行 + CJK/emoji 行；160pt 宽在
// 7pt 内缩后 146pt，长行必然软折行。字体 14pt system、wordWrapping+pushOut、
// padding 0 —— 与 CjguiPrepareTextNodeLayout 的 TEXT 路径完全一致。
static NSString *CjguiVisualNavDocText(void) {
    return @"latin מספר end\n折行两侧这是很长的一行文字需要在窗口内折成至少两行折点前后都有é字素。\nrow 中文🙂\n";
}

static CjguiInternalRendererStatus submitVisualNavDoc(uint64_t session, uint64_t version) {
    CjguiInternalRendererComposableNode node = {0};
    node.nodeId = 992; node.projectionVersion = version; node.resourceId = -1;
    node.nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT;
    node.x = 0; node.y = 0; node.width = 160; node.height = 400;
    node.clipX = 0; node.clipY = 0; node.clipWidth = 160; node.clipHeight = 400;
    node.clipConstraintCount = 1;
    node.clip0X = 0; node.clip0Y = 0; node.clip0Width = 160; node.clip0Height = 400;
    node.effectGroupSubtreeCount = 1; node.isInteractive = 1;
    node.textAlpha = 1.0; node.textRed = 0.0; node.textGreen = 0.0; node.textBlue = 0.0;
    node.fontSize = 14.0;
    CjguiInternalRendererComposableGeometry geometry = {0};
    geometry.nodeId = node.nodeId; geometry.clipCount = 1;
    CjguiInternalRendererStatus status = cjgui_internal_renderer_configure_composable_scene(session, version, 1);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
    status = cjgui_internal_renderer_set_composable_scene_node(session, 0, &node,
        "", CjguiVisualNavDocText().UTF8String, "visual nav", "", 0);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
    status = cjgui_internal_renderer_set_composable_scene_geometry(session, version, 0, &geometry);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
    status = cjgui_internal_renderer_stage_window_background(session, version, 0, 1);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
    CjguiInternalRendererFrameObservation frame = {0};
    return cjgui_internal_renderer_present_composable_scene(session, &frame);
}

static NSString *CjguiAccentFragDocText(void) {
    return @"e\u0301";
}

static CjguiInternalRendererStatus submitAccentFragDoc(uint64_t session, uint64_t version) {
    CjguiInternalRendererComposableNode node = {0};
    node.nodeId = 993; node.projectionVersion = version; node.resourceId = -1;
    node.nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT;
    node.x = 0; node.y = 0; node.width = 160; node.height = 60;
    node.clipX = 0; node.clipY = 0; node.clipWidth = 160; node.clipHeight = 60;
    node.clipConstraintCount = 1;
    node.clip0X = 0; node.clip0Y = 0; node.clip0Width = 160; node.clip0Height = 60;
    node.effectGroupSubtreeCount = 1; node.isInteractive = 1;
    node.textAlpha = 1.0; node.fontSize = 14.0;
    CjguiInternalRendererComposableGeometry geometry = {0};
    geometry.nodeId = node.nodeId; geometry.clipCount = 1;
    CjguiInternalRendererStatus status = cjgui_internal_renderer_configure_composable_scene(session, version, 1);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
    status = cjgui_internal_renderer_set_composable_scene_node(session, 0, &node,
        "", CjguiAccentFragDocText().UTF8String, "accent frag", "", 0);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
    status = cjgui_internal_renderer_set_composable_scene_geometry(session, version, 0, &geometry);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
    status = cjgui_internal_renderer_stage_window_background(session, version, 0, 1);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
    CjguiInternalRendererFrameObservation frame = {0};
    return cjgui_internal_renderer_present_composable_scene(session, &frame);
}

// M1 逐层失效夹具：同 nodeId 改文字（换绑）、同文字改宽（resize）、同文字同宽
// 改 translateY（滚动）——各自 staging 为新场景版本，旧票据被拒、当前票据按新层回答。
static CjguiInternalRendererStatus submitSceneVariant(uint64_t session, uint64_t version,
    uint64_t nodeId, NSString *text, double width, double translateY) {
    CjguiInternalRendererComposableNode node = {0};
    node.nodeId = nodeId; node.projectionVersion = version; node.resourceId = -1;
    node.nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT;
    node.x = 0; node.y = 0; node.width = width; node.height = 400;
    node.clipX = 0; node.clipY = 0; node.clipWidth = width; node.clipHeight = 400;
    node.clipConstraintCount = 1;
    node.clip0X = 0; node.clip0Y = 0; node.clip0Width = width; node.clip0Height = 400;
    node.effectGroupSubtreeCount = 1; node.isInteractive = 1;
    node.textAlpha = 1.0; node.fontSize = 14.0;
    CjguiInternalRendererComposableGeometry geometry = {0};
    geometry.nodeId = node.nodeId; geometry.clipCount = 1;
    geometry.translateY = translateY;
    CjguiInternalRendererStatus status = cjgui_internal_renderer_configure_composable_scene(session, version, 1);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
    status = cjgui_internal_renderer_set_composable_scene_node(session, 0, &node,
        "", text.UTF8String, "variant", "", 0);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
    status = cjgui_internal_renderer_set_composable_scene_geometry(session, version, 0, &geometry);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
    status = cjgui_internal_renderer_stage_window_background(session, version, 0, 1);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
    CjguiInternalRendererFrameObservation frame = {0};
    return cjgui_internal_renderer_present_composable_scene(session, &frame);
}

// R1 夹具：宽 W 短行 + 窄 i 长折行（软折行，非换行结尾）。行 A 字符少、
// 行 B（折出）字符多——行末点击把 charIndex 解析到 A.maxRange == B.location，
// 插入点查询落在**行 B**，而旧实现的缓冲按**行 A** 容量分配（越界写）。
static NSString *CjguiWrapFoldDocText(void) {
    return @"WWWW" @"iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii";
}

// M1 夹具：真空行与末尾换行——"aa\n\nbb"（行0="aa\n"、行1="\n" 空行、
// 行2="bb"）与 "ab\n"（EOF caret 在 extra line fragment）。
// R2 夹具：纯硬换行文档（无软折行）——行首位置的分支必须与软折行区分：
// 硬断行后 byte3（行2首）唯一渲染在行2，Upstream 不得画到行1末；软折行边界
// 才有双侧渲染。
static NSString *CjguiHardBreakDocText(void) { return @"ab\ncd\nef\n"; }

static CjguiInternalRendererStatus submitHardBreakDoc(uint64_t session, uint64_t version) {
    CjguiInternalRendererComposableNode node = {0};
    node.nodeId = 997; node.projectionVersion = version; node.resourceId = -1;
    node.nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT;
    node.x = 0; node.y = 0; node.width = 160; node.height = 200;
    node.clipX = 0; node.clipY = 0; node.clipWidth = 160; node.clipHeight = 200;
    node.clipConstraintCount = 1;
    node.clip0X = 0; node.clip0Y = 0; node.clip0Width = 160; node.clip0Height = 200;
    node.effectGroupSubtreeCount = 1; node.isInteractive = 1;
    node.textAlpha = 1.0; node.fontSize = 14.0;
    CjguiInternalRendererComposableGeometry geometry = {0};
    geometry.nodeId = node.nodeId; geometry.clipCount = 1;
    CjguiInternalRendererStatus status = cjgui_internal_renderer_configure_composable_scene(session, version, 1);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
    status = cjgui_internal_renderer_set_composable_scene_node(session, 0, &node,
        "", CjguiHardBreakDocText().UTF8String, "hard break", "", 0);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
    status = cjgui_internal_renderer_set_composable_scene_geometry(session, version, 0, &geometry);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
    status = cjgui_internal_renderer_stage_window_background(session, version, 0, 1);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
    CjguiInternalRendererFrameObservation frame = {0};
    return cjgui_internal_renderer_present_composable_scene(session, &frame);
}

static NSString *CjguiEmptyLineDocText(void) { return @"aa\n\nbb"; }

static CjguiInternalRendererStatus submitEmptyLineDoc(uint64_t session, uint64_t version) {
    CjguiInternalRendererComposableNode node = {0};
    node.nodeId = 995; node.projectionVersion = version; node.resourceId = -1;
    node.nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT;
    node.x = 0; node.y = 0; node.width = 160; node.height = 120;
    node.clipX = 0; node.clipY = 0; node.clipWidth = 160; node.clipHeight = 120;
    node.clipConstraintCount = 1;
    node.clip0X = 0; node.clip0Y = 0; node.clip0Width = 160; node.clip0Height = 120;
    node.effectGroupSubtreeCount = 1; node.isInteractive = 1;
    node.textAlpha = 1.0; node.fontSize = 14.0;
    CjguiInternalRendererComposableGeometry geometry = {0};
    geometry.nodeId = node.nodeId; geometry.clipCount = 1;
    CjguiInternalRendererStatus status = cjgui_internal_renderer_configure_composable_scene(session, version, 1);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
    status = cjgui_internal_renderer_set_composable_scene_node(session, 0, &node,
        "", CjguiEmptyLineDocText().UTF8String, "empty line", "", 0);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
    status = cjgui_internal_renderer_set_composable_scene_geometry(session, version, 0, &geometry);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
    status = cjgui_internal_renderer_stage_window_background(session, version, 0, 1);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
    CjguiInternalRendererFrameObservation frame = {0};
    return cjgui_internal_renderer_present_composable_scene(session, &frame);
}

static CjguiInternalRendererStatus submitWrapFoldDoc(uint64_t session, uint64_t version) {
    CjguiInternalRendererComposableNode node = {0};
    node.nodeId = 994; node.projectionVersion = version; node.resourceId = -1;
    node.nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT;
    node.x = 0; node.y = 0; node.width = 84; node.height = 400;
    node.clipX = 0; node.clipY = 0; node.clipWidth = 84; node.clipHeight = 400;
    node.clipConstraintCount = 1;
    node.clip0X = 0; node.clip0Y = 0; node.clip0Width = 84; node.clip0Height = 400;
    node.effectGroupSubtreeCount = 1; node.isInteractive = 1;
    node.textAlpha = 1.0; node.fontSize = 14.0;
    CjguiInternalRendererComposableGeometry geometry = {0};
    geometry.nodeId = node.nodeId; geometry.clipCount = 1;
    CjguiInternalRendererStatus status = cjgui_internal_renderer_configure_composable_scene(session, version, 1);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
    status = cjgui_internal_renderer_set_composable_scene_node(session, 0, &node,
        "", CjguiWrapFoldDocText().UTF8String, "wrap fold", "", 0);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
    status = cjgui_internal_renderer_set_composable_scene_geometry(session, version, 0, &geometry);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
    status = cjgui_internal_renderer_stage_window_background(session, version, 0, 1);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
    CjguiInternalRendererFrameObservation frame = {0};
    return cjgui_internal_renderer_present_composable_scene(session, &frame);
}

static NSUInteger CjguiTestUtf16LengthOfUtf8Prefix(NSString *text, NSUInteger byteCount) {
    if (byteCount == 0) return 0;
    NSString *prefix = [[NSString alloc] initWithBytes:text.UTF8String length:byteCount
                                              encoding:NSUTF8StringEncoding];
    return prefix ? prefix.length : NSNotFound;
}

static NSUInteger CjguiTestUtf8LengthOfUtf16Prefix(NSString *text, NSUInteger charCount) {
    if (charCount == 0) return 0;
    NSString *prefix = [text substringToIndex:charCount];
    return [prefix lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
}

int main(void) {
    @autoreleasepool {
        CjguiInternalRendererConfig config = {.windowWidth = 120, .windowHeight = 80,
            .clearColorRed = 0.0, .clearColorGreen = 0.0, .clearColorBlue = 0.0,
            .clearColorAlpha = 1.0};
        CjguiInternalRendererStatus created = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
        uint64_t session = cjgui_internal_renderer_create(&config, &created);
        if (require(created == CJGUI_INTERNAL_RENDERER_OK && session > 0, "create")) return 1;
        if (require(submit(session, 1, 0.25, 0.5, -0.75, 0.25, NO) == CJGUI_INTERNAL_RENDERER_OK,
            "accepted_nested_submit")) return 2;
        CJGuiInternalSession *ctx = CjguiLookupSession(session);
        CJGuiInternalComposableSceneOverlay *overlay = ctx.composableSceneOverlay;
        CJGuiInternalComposableSceneNode *child = ctx.composableNodes[1];
        double caretX = 0, caretY = 0, caretWidth = 0, caretHeight = 0;
        if (require(cjgui_internal_renderer_text_geometry_caret(session, 101, 0, 1.5,
            ctx.composableSceneVersion, 2, &caretX, &caretY, &caretWidth, &caretHeight) == CJGUI_INTERNAL_RENDERER_OK,
            "initial_caret_from_prepared_text")) return 18;
        int32_t rangeCount = cjgui_internal_renderer_text_line_rect_count(session, 101, 0, 2, 4, ctx.composableSceneVersion);
        double rangeX = cjgui_internal_renderer_text_line_rect_value(session, 101, 0, 2, 4, 0, 0, ctx.composableSceneVersion);
        double rangeY = cjgui_internal_renderer_text_line_rect_value(session, 101, 0, 2, 4, 0, 1, ctx.composableSceneVersion);
        if (require(rangeCount > 0, "initial_selection_range_from_prepared_text")) return 21;
        if (require(fabs(NSMinX(CjguiComposableVisualNodeRect(child)) - 1.5) < 0.000001 &&
            fabs(NSMinY(CjguiComposableVisualNodeRect(child)) - 0.75) < 0.000001,
            "nested_exact_rect") ||
            require([overlay nodeAtPoint:NSMakePoint(1.49, 1.0)] == nil &&
                [overlay nodeAtPoint:NSMakePoint(1.5, 1.0)] == child,
                "fractional_hit_boundary") ||
            require(CjguiComposablePointInClipChain(1.5, 1.0, child) &&
                !CjguiComposablePointInClipChain(60.26, 1.0, child),
                "ancestor_clip_owner_offset")) return 3;
        [overlay reconcileAccessibilityActions];
        CJGuiInternalComposableAccessibilityAction *ax = overlay.accessibilityActions.lastObject;
        NSRect axRect = [ax accessibilityFrameInParentSpace];
        if (require(fabs(NSMinX(axRect) - 1.5) < 0.000001 &&
            fabs(NSMinY(axRect) - 0.75) < 0.000001,
            "ax_uses_accepted_visual_rect")) return 4;
        if (require(cjgui_internal_renderer_test_activate_composable_point(session, 1.5f, 1.0f) ==
            CJGUI_INTERNAL_RENDERER_OK, "activate_at_fractional_edge")) return 5;
        BOOL sawPrecise = NO;
        for (int i = 0; i < 8; i++) {
            CjguiInternalRendererEvent event = {0};
            CjguiInternalRendererPointerEventGeometry exact = {0};
            if (cjgui_internal_renderer_pump_event(session, 0, &event) != CJGUI_INTERNAL_RENDERER_OK ||
                cjgui_internal_renderer_pumped_pointer_geometry(session, &exact) != CJGUI_INTERNAL_RENDERER_OK)
                return 6;
            if (event.kind == CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_ACTIVATE) {
                sawPrecise = exact.present == 1 && exact.kind == event.kind && exact.nodeId == 101 &&
                    exact.projectionVersion == 1 && exact.resourceId == -1 &&
                    fabs(exact.x - 1.5) < 0.000001 && fabs(exact.y - 1.0) < 0.000001 &&
                    fabs(exact.translateX + 0.5) < 0.000001 &&
                    fabs(exact.translateY - 0.75) < 0.000001;
                break;
            }
        }
        if (require(sawPrecise, "queued_precise_identity_and_transform")) return 7;
        if (require(submit(session, 2, 0.25, 0.5, 5000.0, 0.25, YES) !=
            CJGUI_INTERNAL_RENDERER_OK, "invalid_native_geometry_rejected") ||
            require(ctx.composableSceneVersion == 1 &&
                [overlay nodeAtPoint:NSMakePoint(1.5, 1.0)] == ctx.composableNodes[1],
                "rejected_candidate_keeps_accepted_hit")) return 8;
        double rejectedCaretX = 0, rejectedCaretY = 0;
        if (require(cjgui_internal_renderer_text_geometry_caret(session, 101, 0, 1.5,
            ctx.composableSceneVersion, 2, &rejectedCaretX, &rejectedCaretY, &caretWidth, &caretHeight) == CJGUI_INTERNAL_RENDERER_OK &&
            fabs(rejectedCaretX - caretX) < 0.000001 && fabs(rejectedCaretY - caretY) < 0.000001,
            "rejected_candidate_keeps_caret")) return 19;
        if (require(cjgui_internal_renderer_test_activate_composable_point(session, 1.5f, 1.0f) ==
            CJGUI_INTERNAL_RENDERER_OK, "queue_button_before_new_acceptance")) return 34;
        if (require(submit(session, 3, 0.25, 0.5, 4.0, 0.25, NO) ==
            CJGUI_INTERNAL_RENDERER_OK, "recovery_submit") ||
            require([overlay nodeAtPoint:NSMakePoint(1.5, 1.0)] == nil &&
                [overlay nodeAtPoint:NSMakePoint(6.25, 1.0)] == ctx.composableNodes[1],
                "old_hit_rejected_new_hit_accepted")) return 9;
        BOOL oldButtonEvent = NO;
        for (int turn = 0; turn < 8; turn++) {
            CjguiInternalRendererEvent event = {0};
            CjguiInternalRendererPointerEventGeometry exact = {0};
            if (cjgui_internal_renderer_pump_event(session, 0, &event) != CJGUI_INTERNAL_RENDERER_OK) break;
            if (event.kind != CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_ACTIVATE) continue;
            if (cjgui_internal_renderer_pumped_pointer_geometry(session, &exact) != CJGUI_INTERNAL_RENDERER_OK) break;
            oldButtonEvent = event.projectionVersion == 1 && exact.projectionVersion == 1 &&
                exact.nodeId == 101 && exact.resourceId == -1 && fabs(exact.x - 1.5) < 0.000001 &&
                ctx.composableSceneVersion == 3;
            break;
        }
        if (require(oldButtonEvent, "queued_old_button_keeps_frozen_version_and_point")) return 35;
        double movedCaretX = 0, movedCaretY = 0;
        if (require(cjgui_internal_renderer_text_geometry_caret(session, 101, 0, 1.5,
            ctx.composableSceneVersion, 2, &movedCaretX, &movedCaretY, &caretWidth, &caretHeight) == CJGUI_INTERNAL_RENDERER_OK &&
            fabs(movedCaretX - caretX - 4.75) < 0.000001 &&
            fabs(movedCaretY - caretY) < 0.000001,
            "geometry_cow_retains_caret_and_moves_it_once")) return 20;
        int32_t movedRangeCount = cjgui_internal_renderer_text_line_rect_count(session, 101, 0, 2, 4, ctx.composableSceneVersion);
        double movedRangeX = cjgui_internal_renderer_text_line_rect_value(session, 101, 0, 2, 4, 0, 0, ctx.composableSceneVersion);
        double movedRangeY = cjgui_internal_renderer_text_line_rect_value(session, 101, 0, 2, 4, 0, 1, ctx.composableSceneVersion);
        if (require(movedRangeCount == rangeCount &&
            fabs(movedRangeX - rangeX - 4.75) < 0.000001 &&
            fabs(movedRangeY - rangeY) < 0.000001,
            "selection_range_moves_with_accepted_visual_geometry")) return 22;
        // M1（2026-09-30）：场景票据判别——场景已从 1 前进到 3，旧票据(1)必须被
        // caret/范围两类查询具名拒绝；当前票据照常成功。
        if (require(cjgui_internal_renderer_text_geometry_caret(session, 101, 0, 1.5, 1, 2,
                &caretX, &caretY, &caretWidth, &caretHeight) == CJGUI_INTERNAL_RENDERER_SCENE_STALE,
            "stale_scene_ticket_rejects_caret_query")) return 45;
        if (require(cjgui_internal_renderer_text_line_rect_count(session, 101, 0, 2, 4, 1) ==
                -CJGUI_INTERNAL_RENDERER_SCENE_STALE,
            "stale_scene_ticket_rejects_range_rect_query")) return 46;
        if (require(cjgui_internal_renderer_text_line_rect_count(session, 101, 0, 2, 4,
                ctx.composableSceneVersion) > 0,
            "current_scene_ticket_still_answered")) return 47;
        // Restore the fractional edge, then sample adjacent 2x drawable
        // texels. Their centres are 1.25 and 1.75 logical points; the body
        // starts at 1.5. The same accepted geometry decides both pixels.
        sampleX = 1.25;
        if (require(submit(session, 4, 0.25, 0.5, -0.75, 0.25, NO) ==
            CJGUI_INTERNAL_RENDERER_OK, "fractional_pixel_outside_submit")) return 10;
        uint8_t outsideGreen = sampledGreen;
        uint64_t textRasterBefore = ctx.view.testComposableTextRasterCount;
        sampleX = 1.75;
        if (require(submit(session, 5, 0.25, 0.5, -0.75, 0.25, NO) ==
            CJGUI_INTERNAL_RENDERER_OK, "fractional_pixel_inside_submit")) return 11;
        uint8_t insideGreen = sampledGreen;
        if (require(outsideGreen > insideGreen + 80,
            "two_x_adjacent_pixels_straddle_fractional_edge")) {
            fprintf(stderr, "F11_PIXEL outside_g=%u inside_g=%u\n", outsideGreen, insideGreen);
            return 12;
        }
        if (require(textRasterBefore > 0 &&
            ctx.view.testComposableTextRasterCount == textRasterBefore,
            "translation_reuses_text_raster")) return 13;
        sampleX = -1.0;
        if (require(submit(session, 6, 0.0, 0.0, 0.0, 0.0, NO) == CJGUI_INTERNAL_RENDERER_OK &&
            ctx.view.testComposableTextRasterCount == textRasterBefore,
            "translated_to_zero_reuses_full_text_coverage")) return 23;
        uint64_t scaleRevision = 0; double oldScale = 0.0, newScale = 0.0;
        uint32_t pixelWidth = 0, pixelHeight = 0;
        if (require(cjgui_internal_renderer_test_toggle_composable_backing_scale(session,
            &scaleRevision, &oldScale, &newScale, &pixelWidth, &pixelHeight) ==
            CJGUI_INTERNAL_RENDERER_OK && oldScale == 2.0 && newScale == 1.0,
            "controlled_scale_two_to_one")) return 14;
        sampleX = 0.25;
        if (require(submit(session, 7, 0.25, 0.5, -0.75, 0.25, NO) ==
            CJGUI_INTERNAL_RENDERER_OK, "one_x_outside_submit")) return 15;
        uint8_t outsideOneXGreen = sampledGreen;
        sampleX = 2.25;
        if (require(submit(session, 8, 0.25, 0.5, -0.75, 0.25, NO) ==
            CJGUI_INTERNAL_RENDERER_OK, "one_x_inside_submit")) return 16;
        uint8_t insideOneXGreen = sampledGreen;
        if (require(outsideOneXGreen > insideOneXGreen + 80,
            "one_x_pixels_straddle_fractional_edge")) return 17;
        // Keep the quantized ROI and every POD byte unchanged. Moving only
        // accepted visual geometry must invalidate both the group's rendered
        // pixels and an earlier painter sampled by an in-app backdrop.
        CJGuiInternalComposableSceneNode *source = ctx.composableNodes[0];
        CjguiInternalRendererComposableNode sourcePOD = source.node;
        sourcePOD.fillAlpha = 1.0;
        source.node = sourcePOD;
        CGSize cacheDrawable = CGSizeMake(240, 160);
        MTLClearColor cacheClear = MTLClearColorMake(0.0, 0.0, 0.0, 1.0);
        NSString *groupBefore = CjguiEffectContentSignature(ctx.composableNodes, 0, 2,
            0, 0, 120, 80, NO, NSMakeSize(120, 80), cacheDrawable);
        NSString *backdropBefore = CjguiBackdropSignature(ctx.view, 1, 0, 0, 20, 20,
            0, 20, 4, 2.0f, 2.0f, 6, 6, cacheDrawable, cacheClear);
        CjguiInternalRendererComposableGeometry sourceGeometry = source.geometry;
        sourceGeometry.translateX += 0.125;
        source.geometry = sourceGeometry;
        NSString *groupAfter = CjguiEffectContentSignature(ctx.composableNodes, 0, 2,
            0, 0, 120, 80, NO, NSMakeSize(120, 80), cacheDrawable);
        NSString *backdropAfter = CjguiBackdropSignature(ctx.view, 1, 0, 0, 20, 20,
            0, 20, 4, 2.0f, 2.0f, 6, 6, cacheDrawable, cacheClear);
        if (require(![backdropBefore isEqualToString:backdropAfter],
            "subpixel_backdrop_cache_dependency") ||
            require(![groupBefore isEqualToString:groupAfter],
            "subpixel_group_cache_dependency")) return 24;
        // Production coverage planner: the same long body must remain bounded
        // when only its accepted visual transform (or its clip owner) changes.
        CJGuiInternalComposableSceneNode *longText = [[CJGuiInternalComposableSceneNode alloc] init];
        CjguiInternalRendererComposableNode longValue = {0};
        longValue.nodeId = 990; longValue.nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT;
        longValue.width = 1000; longValue.height = 10000;
        longValue.clipWidth = 1000; longValue.clipHeight = 400;
        longValue.clipConstraintCount = 1;
        longValue.clip0Width = 1000; longValue.clip0Height = 400;
        longText.node = longValue;
        CjguiInternalRendererComposableGeometry longGeometry = {0};
        longGeometry.nodeId = 990; longGeometry.clipCount = 1;
        longText.geometry = longGeometry;
        NSRect zeroCoverage = CjguiComposableTextTextureRectForNode(longText);
        longGeometry.translateY = 0.25;
        longText.geometry = longGeometry;
        NSRect translatedCoverage = CjguiComposableTextTextureRectForNode(longText);
        uint64_t boundedBytes = 0;
        NSArray<NSValue *> *boundedTiles = CjguiPlanComposableTextTiles(translatedCoverage,
            CjguiComposableTextNodeLayoutRect(longText), 1.0, &boundedBytes);
        if (require(!NSIsEmptyRect(zeroCoverage) && NSHeight(zeroCoverage) < 500.0 &&
            !NSIsEmptyRect(translatedCoverage) && NSHeight(translatedCoverage) < 500.0 &&
            boundedTiles.count > 0 && boundedBytes <= CjguiComposableTextTextureByteCapacity,
            "translated_long_text_uses_bounded_visible_tiles")) {
            fprintf(stderr, "F11_TEXT_COVERAGE zero=%.1f translated=%.1f tiles=%lu bytes=%llu\n",
                NSHeight(zeroCoverage), NSHeight(translatedCoverage), (unsigned long)boundedTiles.count,
                (unsigned long long)boundedBytes);
            return 26;
        }
        CJGuiInternalComposableSceneNode *memoText = [[CJGuiInternalComposableSceneNode alloc] init];
        CjguiInternalRendererComposableNode memoValue = longValue;
        memoValue.nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT;
        memoValue.width = 280; memoValue.height = 1000; memoValue.fontSize = 14;
        memoValue.clipWidth = 280; memoValue.clipHeight = 180;
        memoValue.clip0Width = 280; memoValue.clip0Height = 180;
        memoText.node = memoValue;
        memoText.geometry = longGeometry;
        NSString *memoBody = @"中文🙂 text extent measurement wraps at the accepted width";
        NSRect memoFirst = CjguiComposableTextTextureRectForNodeWithText(memoText, memoBody);
        CjguiInternalRendererComposableGeometry movedMemoGeometry = memoText.geometry;
        movedMemoGeometry.translateY += 0.25;
        memoText.geometry = movedMemoGeometry;
        NSRect memoMoved = CjguiComposableTextTextureRectForNodeWithText(memoText, memoBody);
        if (require(!NSIsEmptyRect(memoFirst) && !NSIsEmptyRect(memoMoved) &&
            memoText.testTextExtentMeasurementCount == 1,
            "text_extent_reused_across_visual_translation")) return 42;
        memoValue.width = 240;
        memoText.node = memoValue;
        (void)CjguiComposableTextTextureRectForNodeWithText(memoText, memoBody);
        if (require(memoText.testTextExtentMeasurementCount == 2,
            "text_extent_invalidates_on_wrap_width")) return 43;
        (void)CjguiComposableTextTextureRectForNodeWithText(memoText, @"中文🙂 changed body");
        if (require(memoText.testTextExtentMeasurementCount == 3,
            "text_extent_invalidates_on_content")) return 44;
        uint8_t oldBackdrop[4] = {0}, movedBackdrop[4] = {0}, stableBackdrop[4] = {0};
        CjguiInternalRendererEffectStats oldStats = {0}, movedStats = {0}, stableStats = {0};
        if (require(submitBackdrop(session, 9, 0.0, oldBackdrop) == CJGUI_INTERNAL_RENDERER_OK,
            "backdrop_baseline_submit") ||
            require(cjgui_internal_renderer_test_composable_effect_stats(session, &oldStats) ==
                CJGUI_INTERNAL_RENDERER_OK, "backdrop_baseline_stats") ||
            require(submitBackdrop(session, 10, 0.75, movedBackdrop) == CJGUI_INTERNAL_RENDERER_OK,
            "backdrop_moved_source_submit") ||
            require(cjgui_internal_renderer_test_composable_effect_stats(session, &movedStats) ==
                CJGUI_INTERNAL_RENDERER_OK, "backdrop_moved_stats") ||
            require(movedStats.backdropPrefixPasses > oldStats.backdropPrefixPasses &&
                abs((int)movedBackdrop[2] - (int)oldBackdrop[2]) >= 3,
                "backdrop_source_move_redraws_pixels") ||
            require(submitBackdrop(session, 11, 0.75, stableBackdrop) == CJGUI_INTERNAL_RENDERER_OK,
                "backdrop_static_source_submit") ||
            require(cjgui_internal_renderer_test_composable_effect_stats(session, &stableStats) ==
                CJGUI_INTERNAL_RENDERER_OK, "backdrop_static_stats") ||
            require(stableStats.backdropPrefixPasses == movedStats.backdropPrefixPasses &&
                stableStats.backdropCacheHits > movedStats.backdropCacheHits &&
            memcmp(movedBackdrop, stableBackdrop, 4) == 0,
            "backdrop_static_cache_reuses_exact_pixels")) return 25;
        if (require(submitLongText(session, 12, 0.0, 0.0) == CJGUI_INTERNAL_RENDERER_OK,
            "long_text_initial_accepted")) return 27;
        // M1（2026-09-30）：范围矩形的字节单位/身份票判别。行 1 =
        // "row 0000 中文🙂\n"（UTF-8 20 B / UTF-16 14 单元；中=6 B、🙂=4 B 代理对）。
        // [0,19) 恰是首行内容：精确换算 ⇒ 1 个行矩形；旧行为把字节当 UTF-16
        // 索引（[0,19) 字符跨过换行）会给出 ≥2 个矩形。
        if (require(cjgui_internal_renderer_text_line_rect_count(session, 990, 0, 19, 8,
                ctx.composableSceneVersion) == 1,
            "cjk_emoji_byte_range_converted_not_char_indexed")) return 41;
        // 劈开标量：byte 10 落在 "中"（bytes 9..14）内部 ⇒ 具名 TEXT_RANGE_INVALID，
        // 不向标量边界回退洗白。
        if (require(cjgui_internal_renderer_text_line_rect_count(session, 990, 0, 10, 8,
                ctx.composableSceneVersion) == -CJGUI_INTERNAL_RENDERER_TEXT_RANGE_INVALID,
            "mid_scalar_range_end_rejected_not_walked_back")) return 42;
        // 越界：EOF 之后仍具名拒绝；半开空范围 [x,x) 合法零矩形。
        if (require(cjgui_internal_renderer_text_line_rect_count(session, 990, 0, 999999, 8,
                ctx.composableSceneVersion) == -CJGUI_INTERNAL_RENDERER_TEXT_RANGE_INVALID,
            "out_of_range_end_rejected_not_clamped")) return 43;
        if (require(cjgui_internal_renderer_text_line_rect_count(session, 990, 20, 20, 8,
                ctx.composableSceneVersion) == 0,
            "empty_half_open_range_is_zero_rects")) return 44;
        // 空行区段：范围 [19,20) 恰覆盖行 1 的换行符——选区矩形必须落在行 1 的
        // 行矩形内（y 与 [0,19) 的首矩形同高），不越到下一行。
        {
            double fullRect[4] = {0}, nlRect[4] = {0};
            int32_t fullCount = cjgui_internal_renderer_text_line_rect_count(session, 990, 0, 19, 4,
                ctx.composableSceneVersion);
            int32_t nlCount = cjgui_internal_renderer_text_line_rect_count(session, 990, 19, 20, 4,
                ctx.composableSceneVersion);
            if (require(fullCount == 1 && nlCount == 1,
                    "newline_range_has_one_rect")) return 63;
            for (int comp = 0; comp < 4; comp++) {
                fullRect[comp] = cjgui_internal_renderer_text_line_rect_value(session, 990, 0, 19, 4, 0,
                    comp, ctx.composableSceneVersion);
                nlRect[comp] = cjgui_internal_renderer_text_line_rect_value(session, 990, 19, 20, 4, 0,
                    comp, ctx.composableSceneVersion);
            }
            if (require(fabs(nlRect[1] - fullRect[1]) < 0.000001 &&
                    fabs(nlRect[3] - fullRect[3]) < 0.000001 && nlRect[2] > 0.0,
                    "newline_range_rect_stays_on_its_line")) return 64;
        }
        uint64_t longRasterInitial = ctx.view.testComposableTextRasterCount;
        uint64_t longBytes = ctx.composableNodes[0].textTextureByteCount;
        if (require(longBytes > 0 && longBytes < CjguiComposableTextTextureByteCapacity &&
            ctx.composableNodes[0].textTileTextures.count == 4,
            "long_text_initial_bounded_tiles")) return 28;
        id<MTLTexture> initialTile = ctx.composableNodes[0].textTileTextures.firstObject;
        id<MTLTexture> retainedNextRow = ctx.composableNodes[0].textTileTextures[1];
        uint64_t initialSubmittedFrame = ctx.view.frameIndex;
        NSArray<id<MTLTexture>> *initialSubmission =
            ctx.submittedTextTextures[@(initialSubmittedFrame)];
        CjguiTextSubmissionCompletion *initialCompletion =
            ctx.submittedTextCompletionFlags[@(initialSubmittedFrame)];
        if (require([initialSubmission containsObject:initialTile],
            "submitted_frame_holds_exact_text_tile_generation")) return 40;
        if (require(submitLongText(session, 13, 0.25, 0.0) == CJGUI_INTERNAL_RENDERER_OK &&
            ctx.view.testComposableTextRasterCount == longRasterInitial &&
            ctx.composableNodes[0].textTileTextures.firstObject == initialTile,
            "quarter_point_reuses_tile_identity")) return 29;
        if (require(submitLongText(session, 14, -258.25, 0.0) == CJGUI_INTERNAL_RENDERER_OK &&
            ctx.view.testComposableTextRasterCount == longRasterInitial + 2 &&
            ctx.composableNodes[0].textTileTextures.firstObject == retainedNextRow &&
            ctx.composableNodes[0].textTextureByteCount <= CjguiComposableTextTextureByteCapacity,
            "crossing_grid_rasterizes_only_new_row")) {
            fprintf(stderr, "F11_TILE_CROSS initial=%llu now=%llu first=%p retained=%p count=%lu bytes=%llu\n",
                (unsigned long long)longRasterInitial,
                (unsigned long long)ctx.view.testComposableTextRasterCount,
                ctx.composableNodes[0].textTileTextures.firstObject, retainedNextRow,
                (unsigned long)ctx.composableNodes[0].textTileTextures.count,
                (unsigned long long)ctx.composableNodes[0].textTextureByteCount);
            return 30;
        }
        uint64_t currentAcceptedBytes = ctx.composableNodes[0].textTextureByteCount;
        // The real submitted frame may already have completed while this
        // synchronous owner turn is still running. Wait for that actual Metal
        // fence, then prove a pending generation is charged and a completed
        // one is pruned without requiring the main dispatch queue to drain.
        for (NSUInteger retry = 0; retry < 1000 && !initialCompletion.resourcesReleased; retry++)
            usleep(1000);
        if (require(initialCompletion.resourcesReleased &&
            [initialSubmission containsObject:initialTile] &&
            ![ctx.composableNodes[0].textTileTextures containsObject:initialTile],
            "retired_text_tile_gpu_completion_observed")) return 41;
        (void)CjguiComposableRetainedTextTextureBytes(ctx);
        NSNumber *heldFrame = @(UINT64_MAX - 1u);
        CjguiTextSubmissionCompletion *heldFence = [[CjguiTextSubmissionCompletion alloc] init];
        ctx.submittedTextTextures[heldFrame] = initialSubmission;
        ctx.submittedTextCompletionFlags[heldFrame] = heldFence;
        uint64_t pendingBytes = CjguiComposableRetainedTextTextureBytes(ctx);
        if (require(pendingBytes > currentAcceptedBytes &&
            pendingBytes <= CjguiComposableTextTextureByteCapacity,
            "retired_inflight_text_tile_stays_in_budget_until_completion")) return 51;
        heldFence.resourcesReleased = YES;
        uint64_t completedBytes = CjguiComposableRetainedTextTextureBytes(ctx);
        if (require(completedBytes < pendingBytes &&
            !ctx.submittedTextTextures[heldFrame] &&
            !ctx.submittedTextCompletionFlags[heldFrame],
            "completed_text_tile_retires_before_next_admission")) return 52;
        uint64_t translatedRaster = ctx.view.testComposableTextRasterCount;
        if (require(submitLongText(session, 15, -258.25, 0.5) == CJGUI_INTERNAL_RENDERER_OK &&
            ctx.view.testComposableTextRasterCount == translatedRaster,
            "clip_owner_subpoint_motion_reuses_tiles")) return 31;
        if (require(cjgui_internal_renderer_focus_composable_node(session, 990) ==
            CJGUI_INTERNAL_RENDERER_OK &&
            ctx.composableSceneOverlay.activeNodeId == 990,
            "focus_long_text_native_owner")) return 32;
        uint64_t acceptedBeforeFocusedMove = ctx.composableSceneVersion;
        id<MTLTexture> acceptedFocusedTile = ctx.composableNodes[0].textTileTextures.firstObject;
        if (require(cjgui_internal_renderer_test_set_composable_text_preparation_failures(session, 1) ==
            CJGUI_INTERNAL_RENDERER_OK, "arm_focused_preparation_failure") ||
            require(submitLongText(session, 16, -514.25, 0.5) != CJGUI_INTERNAL_RENDERER_OK &&
                ctx.composableSceneVersion == acceptedBeforeFocusedMove &&
                ctx.composableNodes[0].textTileTextures.firstObject == acceptedFocusedTile,
                "focused_missing_tile_failure_keeps_accepted_scene") ||
            require(submitLongText(session, 16, -514.25, 0.5) == CJGUI_INTERNAL_RENDERER_OK &&
                ctx.composableSceneVersion == 16 &&
                ctx.composableNodes[0].textTextureByteCount <= CjguiComposableTextTextureByteCapacity,
                "focused_missing_tile_retry_accepts_complete_coverage")) return 33;
        if (require(submitControl(session, 17, 101, -1,
                CJGUI_INTERNAL_RENDERER_COMPOSABLE_BUTTON, 0.0) == CJGUI_INTERNAL_RENDERER_OK,
            "button_rebind_baseline") ||
            require(cjgui_internal_renderer_test_activate_composable_point(session, 1.0f, 1.0f) ==
                CJGUI_INTERNAL_RENDERER_OK, "queue_before_rebind") ||
            require(submitControl(session, 18, 101, 8,
                CJGUI_INTERNAL_RENDERER_COMPOSABLE_BUTTON, 0.0) == CJGUI_INTERNAL_RENDERER_OK,
                "accept_rebound_button")) return 36;
        BOOL oldReboundEvent = NO;
        for (int turn = 0; turn < 8; turn++) {
            CjguiInternalRendererEvent event = {0};
            if (cjgui_internal_renderer_pump_event(session, 0, &event) != CJGUI_INTERNAL_RENDERER_OK) break;
            if (event.kind != CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_ACTIVATE) continue;
            oldReboundEvent = event.projectionVersion == 17 && event.resourceId == -1 &&
                ctx.composableSceneVersion == 18 && ctx.composableNodes[0].node.resourceId == 8;
            break;
        }
        if (require(oldReboundEvent, "rebind_does_not_retarget_queued_button")) return 37;
        if (require(submitControl(session, 19, 202, 3,
                CJGUI_INTERNAL_RENDERER_COMPOSABLE_SPLIT_DIVIDER, 0.0) == CJGUI_INTERNAL_RENDERER_OK,
            "split_capture_baseline") ||
            require(cjgui_internal_renderer_test_send_composable_pointer(session, 1, 2.0f, 2.0f) ==
                CJGUI_INTERNAL_RENDERER_OK, "queue_capture_begin") ||
            require(submitControl(session, 20, 202, 3,
                CJGUI_INTERNAL_RENDERER_COMPOSABLE_SPLIT_DIVIDER, 100.25) == CJGUI_INTERNAL_RENDERER_OK,
                "accept_split_translation_before_pump")) return 38;
        BOOL oldCaptureEvent = NO;
        uint64_t capturedGestureEpoch = 0;
        for (int turn = 0; turn < 8; turn++) {
            CjguiInternalRendererEvent event = {0};
            CjguiInternalRendererPointerEventGeometry exact = {0};
            if (cjgui_internal_renderer_pump_event(session, 0, &event) != CJGUI_INTERNAL_RENDERER_OK) break;
            if (event.kind != CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_POINTER_BEGIN) continue;
            if (cjgui_internal_renderer_pumped_pointer_geometry(session, &exact) != CJGUI_INTERNAL_RENDERER_OK) break;
            oldCaptureEvent = event.projectionVersion == 19 && exact.projectionVersion == 19 &&
                exact.resourceId == 3 && fabs(exact.translateX) < 0.000001 &&
                fabs(exact.x - 2.0) < 0.000001 && ctx.composableSceneVersion == 20;
            capturedGestureEpoch = event.bindingEpoch;
            break;
        }
        if (require(oldCaptureEvent, "queued_capture_begin_stays_old_projection")) return 39;
        if (require(capturedGestureEpoch != 0, "pointer_begin_has_gesture_epoch") ||
            require(cjgui_internal_renderer_test_send_composable_pointer(session, 2, 105.0f, 2.0f) ==
                CJGUI_INTERNAL_RENDERER_OK, "same_gesture_update_after_accept")) return 42;
        BOOL continuedEpoch = NO;
        for (int turn = 0; turn < 8; turn++) {
            CjguiInternalRendererEvent event = {0};
            if (cjgui_internal_renderer_pump_event(session, 0, &event) != CJGUI_INTERNAL_RENDERER_OK) break;
            if (event.kind != CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_POINTER_UPDATE) continue;
            continuedEpoch = event.bindingEpoch == capturedGestureEpoch && event.projectionVersion == 20;
            break;
        }
        if (require(continuedEpoch, "accepted_refresh_keeps_same_pointer_generation") ||
            require(cjgui_internal_renderer_test_send_composable_pointer(session, 3, 105.0f, 2.0f) ==
                CJGUI_INTERNAL_RENDERER_OK, "end_first_generation") ||
            require(cjgui_internal_renderer_test_send_composable_pointer(session, 1, 101.0f, 2.0f) ==
                CJGUI_INTERNAL_RENDERER_OK, "begin_second_generation")) return 43;
        uint64_t secondGestureEpoch = overlay.pointerCaptureGestureEpoch;
        if (require(secondGestureEpoch != 0 && secondGestureEpoch != capturedGestureEpoch,
                "pointer_generation_not_reused") ||
            require(cjgui_internal_renderer_cancel_composable_pointer_capture_epoch(session, capturedGestureEpoch) ==
                CJGUI_INTERNAL_RENDERER_OK && overlay.pointerCaptureActive &&
                overlay.pointerCaptureGestureEpoch == secondGestureEpoch,
                "late_cancel_cannot_clear_new_capture") ||
            require(cjgui_internal_renderer_cancel_composable_pointer_capture_epoch(session, secondGestureEpoch) ==
                CJGUI_INTERNAL_RENDERER_OK && !overlay.pointerCaptureActive,
                "matching_cancel_releases_capture")) return 44;
        // The prior generation's terminal and second BEGIN remain in the FIFO
        // after testing native capture cancellation. Settle them before the
        // separate sparse-scene pointer assertion.
        for (int turn = 0; turn < 16; turn++) {
            CjguiInternalRendererEvent ignored = {0};
            if (cjgui_internal_renderer_pump_event(session, 0, &ignored) != CJGUI_INTERNAL_RENDERER_OK) break;
        }
        // A sparse accepted scene reuses the node POD captured in scene 20.
        // Its node.projectionVersion remains 20, while a fresh pointer must be
        // stamped with the accepted input scene 21 or the core rejects it.
        CjguiInternalRendererComposableGeometry reusedGeometry = ctx.composableNodes[0].geometry;
        if (require(cjgui_internal_renderer_configure_composable_scene(session, 21, 1) ==
                CJGUI_INTERNAL_RENDERER_OK &&
                cjgui_internal_renderer_set_composable_scene_geometry(session, 21, 0, &reusedGeometry) ==
                CJGUI_INTERNAL_RENDERER_OK &&
                cjgui_internal_renderer_stage_window_background(session, 21, 0, 1) ==
                CJGUI_INTERNAL_RENDERER_OK,
                "stage_sparse_same_node_projection")) return 45;
        CjguiInternalRendererFrameObservation reusedFrame = {0};
        if (require(cjgui_internal_renderer_present_composable_scene(session, &reusedFrame) ==
                CJGUI_INTERNAL_RENDERER_OK && ctx.composableSceneVersion == 21 &&
                ctx.composableNodes[0].node.projectionVersion == 20,
                "accept_sparse_scene_preserves_node_pod_generation") ||
            require(cjgui_internal_renderer_test_send_composable_pointer(session, 1, 101.0f, 2.0f) ==
                CJGUI_INTERNAL_RENDERER_OK, "sparse_scene_pointer_begin")) return 46;
        BOOL sparseAcceptedEvent = NO;
        for (int turn = 0; turn < 8; turn++) {
            CjguiInternalRendererEvent event = {0};
            if (cjgui_internal_renderer_pump_event(session, 0, &event) != CJGUI_INTERNAL_RENDERER_OK) break;
            if (event.kind != CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_POINTER_BEGIN) continue;
            sparseAcceptedEvent = event.projectionVersion == 21 && event.bindingEpoch != 0;
            break;
        }
        if (require(sparseAcceptedEvent, "sparse_reuse_pointer_uses_accepted_input_version")) return 47;
        [overlay cancelPointerCapture];
        // The actual Cangjie active-input handoff sends an empty staged value
        // and preservesActiveLocalText=1. A translated clip cannot accept new
        // geometry before its newly visible tile is prepared from the native
        // draft, even though the owner and node identity are unchanged.
        if (require(submitLongText(session, 22, -258.25, 0.5) == CJGUI_INTERNAL_RENDERER_OK,
                "preserve_long_text_baseline") ||
            require(cjgui_internal_renderer_focus_composable_node(session, 990) ==
                CJGUI_INTERNAL_RENDERER_OK, "preserve_long_text_focus")) return 48;
        uint64_t preserveAcceptedVersion = ctx.composableSceneVersion;
        id<MTLTexture> preserveAcceptedTile = ctx.composableNodes[0].textTileTextures.firstObject;
        NSString *preserveDraft = [overlay.inputProxy.string copy];
        NSRange preserveSelection = overlay.inputProxy.selectedRange;
        if (require(preserveDraft.length > 0 && preserveAcceptedTile != nil,
                "preserve_baseline_has_native_draft_and_tile") ||
            require(cjgui_internal_renderer_test_set_composable_text_preparation_failures(session, 1) ==
                CJGUI_INTERNAL_RENDERER_OK, "preserve_arm_tile_failure") ||
            require(submitLongTextWithTransport(session, 23, -514.25, 0.5, YES) !=
                CJGUI_INTERNAL_RENDERER_OK &&
                ctx.composableSceneVersion == preserveAcceptedVersion &&
                ctx.composableNodes[0].textTileTextures.firstObject == preserveAcceptedTile &&
                [overlay.inputProxy.string isEqualToString:preserveDraft] &&
                NSEqualRanges(overlay.inputProxy.selectedRange, preserveSelection),
                "preserve_missing_tile_rejects_before_acceptance") ||
            require(submitLongTextWithTransport(session, 23, -514.25, 0.5, YES) ==
                CJGUI_INTERNAL_RENDERER_OK && ctx.composableSceneVersion == 23 &&
                [overlay.inputProxy.string isEqualToString:preserveDraft],
            "preserve_retry_accepts_from_same_draft")) return 49;
        uint64_t coveredRaster = ctx.view.testComposableTextRasterCount;
        if (require(cjgui_internal_renderer_test_set_composable_text_preparation_failures(session, 1) ==
                CJGUI_INTERNAL_RENDERER_OK, "arm_covered_motion_failure") ||
            require(submitLongTextWithTransport(session, 24, -514.25, 0.5, YES) ==
                CJGUI_INTERNAL_RENDERER_OK && ctx.composableSceneVersion == 24 &&
                ctx.view.testComposableTextRasterCount == coveredRaster &&
                ctx.forcedComposableTextPreparationFailures == 1,
                "covered_motion_reuses_tile_without_consuming_failure") ||
            require(submitLongTextWithTransport(session, 25, -770.25, 0.5, YES) !=
                CJGUI_INTERNAL_RENDERER_OK && ctx.composableSceneVersion == 24,
                "next_uncovered_cell_still_requires_admission") ||
            require(submitLongTextWithTransport(session, 25, -770.25, 0.5, YES) ==
                CJGUI_INTERNAL_RENDERER_OK && ctx.composableSceneVersion == 25,
            "next_uncovered_cell_retries")) return 50;
        // A focused single-line input must obey the same acceptance fence.
        // The initial node-local tile covers 0..512, while the unchanged
        // native draft needs 600..700 after the parent-relative visual move.
        if (require(submitClippedSingleLineWithTransport(session, 26, 0.0, NO) ==
                CJGUI_INTERNAL_RENDERER_OK, "single_line_baseline") ||
            require(cjgui_internal_renderer_focus_composable_node(session, 991) ==
                CJGUI_INTERNAL_RENDERER_OK, "single_line_focus")) return 55;
        uint64_t singleAcceptedVersion = ctx.composableSceneVersion;
        id<MTLTexture> singleAcceptedTexture = ctx.composableNodes[0].textTexture;
        NSRect singleAcceptedRect = ctx.composableNodes[0].textTextureRect;
        NSString *singleDraft = [overlay.inputProxy.string copy];
        overlay.inputProxy.selectedRange = NSMakeRange(4, 2);
        NSRange singleSelection = overlay.inputProxy.selectedRange;
        if (require(singleAcceptedTexture != nil && NSMaxX(singleAcceptedRect) < 600.0 &&
                singleDraft.length >= 100 && singleSelection.length == 2,
                "single_line_local_coverage_baseline") ||
            require(cjgui_internal_renderer_test_set_composable_text_preparation_failures(session, 1) ==
                CJGUI_INTERNAL_RENDERER_OK, "single_line_arm_uncovered_failure") ||
            require(submitClippedSingleLineWithTransport(session, 27, -600.0, YES) !=
                CJGUI_INTERNAL_RENDERER_OK && ctx.composableSceneVersion == singleAcceptedVersion &&
                ctx.composableNodes[0].textTexture == singleAcceptedTexture &&
                [overlay.inputProxy.string isEqualToString:singleDraft] &&
                NSEqualRanges(overlay.inputProxy.selectedRange, singleSelection),
                "single_line_missing_tile_rejects_before_acceptance") ||
            require(submitClippedSingleLineWithTransport(session, 27, -600.0, YES) ==
                CJGUI_INTERNAL_RENDERER_OK && ctx.composableSceneVersion == 27 &&
                NSMinX(ctx.composableNodes[0].textTextureRect) <= 600.0 &&
                NSMaxX(ctx.composableNodes[0].textTextureRect) >= 700.0 &&
                [overlay.inputProxy.string isEqualToString:singleDraft] &&
                NSEqualRanges(overlay.inputProxy.selectedRange, singleSelection),
                "single_line_retry_admits_draft_coverage")) return 56;
        uint64_t singleCoveredRaster = ctx.view.testComposableTextRasterCount;
        if (require(submitClippedSingleLineWithTransport(session, 28, -600.25, YES) ==
                CJGUI_INTERNAL_RENDERER_OK && ctx.view.testComposableTextRasterCount == singleCoveredRaster,
                "single_line_covered_subpoint_reuses_tile")) return 57;
        uint64_t finalFrame = ctx.view.frameIndex;
        NSNumber *finalKey = @(finalFrame);
        CjguiTextSubmissionCompletion *finalFence = ctx.submittedTextCompletionFlags[finalKey];
        for (NSUInteger retry = 0; retry < 1000 && !finalFence.resourcesReleased; retry++)
            usleep(1000);
        if (require(finalFence && finalFence.resourcesReleased &&
            ctx.submittedTextTextures[finalKey] != nil,
            "actual_gpu_completion_precedes_main_queue_text_retirement")) return 53;
        (void)CjguiComposableRetainedTextTextureBytes(ctx);
        if (require(ctx.submittedTextTextures[finalKey] == nil &&
            ctx.submittedTextCompletionFlags[finalKey] == nil,
            "next_owner_admission_prunes_completed_gpu_generation")) return 54;
        // M2（视觉导航）系统对照：同一文字/字体/宽度/段落属性下，CJGUI
        // text_visual_neighbor 与 NSTextView moveLeft:/moveRight: 的落点逐簇
        // 一致（箭头=视觉邻位、簇对齐；覆盖 bidi 行、软折行行界、CJK/emoji、EOF）。
        if (require(submitVisualNavDoc(session, 29) == CJGUI_INTERNAL_RENDERER_OK,
            "visual_nav_doc_accepted")) return 58;
        NSString *navText = CjguiVisualNavDocText();
        NSMutableParagraphStyle *refPara = [[NSMutableParagraphStyle alloc] init];
        refPara.lineBreakMode = NSLineBreakByWordWrapping;
        refPara.lineBreakStrategy = NSLineBreakStrategyPushOut;
        NSTextStorage *refStorage = [[NSTextStorage alloc] initWithString:navText attributes:@{
            NSFontAttributeName: [NSFont systemFontOfSize:14.0],
            NSParagraphStyleAttributeName: refPara }];
        NSLayoutManager *refLM = [NSLayoutManager new];
        [refStorage addLayoutManager:refLM];
        NSTextContainer *refContainer =
            [[NSTextContainer alloc] initWithSize:NSMakeSize(146.0, CGFLOAT_MAX)];
        refContainer.widthTracksTextView = NO;
        refContainer.lineFragmentPadding = 0.0;
        [refLM addTextContainer:refContainer];
        NSTextView *refView = [[NSTextView alloc] initWithFrame:NSMakeRect(0, 0, 146.0, 400.0)
                                                  textContainer:refContainer];
        [refLM ensureLayoutForTextContainer:refContainer];
        {
            CJGuiInternalComposableSceneNode *navNode = nil;
            for (CJGuiInternalComposableSceneNode *candidate in ctx.composableSceneOverlay.nodes) {
                if (candidate.node.nodeId == 992) { navNode = candidate; break; }
            }
            NSLog(@"VISNAV_DOC node=%@ storageLen=%lu valueBytes=%lu prepared=%@",
                navNode ? @"992" : @"MISSING",
                (unsigned long)(navNode.preparedTextLayout ? navNode.preparedTextLayout.storage.length : 0),
                (unsigned long)(navNode ? [navNode.value lengthOfBytesUsingEncoding:NSUTF8StringEncoding] : 0),
                navNode.preparedTextLayout ? @"yes" : @"no");
        }
        NSUInteger navUtf8Length = [navText lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
        NSUInteger navCompared = 0;
        NSUInteger navBoundaryByte = 0;
        BOOL navMismatch = NO;
        NSString *navMismatchDetail = @"";
        while (navBoundaryByte <= navUtf8Length && !navMismatch) {
            NSUInteger caretChar =
                CjguiTestUtf16LengthOfUtf8Prefix(navText, navBoundaryByte);
            if (caretChar == NSNotFound) break;
            for (uint32_t goingLeft = 1; goingLeft >= 0 && goingLeft <= 1; goingLeft--) {
                uint32_t navByte = 0, navAff = 0;
                CjguiInternalRendererStatus navStatus = cjgui_internal_renderer_text_visual_neighbor(
                    session, 992, (int64_t)navBoundaryByte, goingLeft,
                    ctx.composableSceneVersion, 2, &navByte, &navAff);
                if (navStatus != CJGUI_INTERNAL_RENDERER_OK) {
                    navMismatch = YES;
                    navMismatchDetail = [NSString stringWithFormat:@"status=%ld byte=%lu",
                        (long)navStatus, (unsigned long)navBoundaryByte];
                    break;
                }
                refView.selectedRange = NSMakeRange(caretChar, 0);
                if (goingLeft) [refView moveLeft:nil]; else [refView moveRight:nil];
                NSUInteger refChar = refView.selectedRange.location;
                NSUInteger navChar = CjguiTestUtf16LengthOfUtf8Prefix(navText, navByte);
                if (navChar != refChar) {
                    navMismatch = YES;
                    navMismatchDetail = [NSString stringWithFormat:
                        @"dir=%@ caretByte=%lu cjgui=%lu nstextview=%lu",
                        goingLeft ? @"L" : @"R", (unsigned long)navBoundaryByte,
                        (unsigned long)navChar, (unsigned long)refChar];
                    break;
                }
                navCompared += 1;
            }
            if (navMismatch) break;
            // 下一**簇**边界（跳过簇内标量边界）。
            NSUInteger probeChar = caretChar < navText.length ? caretChar : navText.length - 1;
            CFRange cluster = CFStringGetRangeOfComposedCharactersAtIndex((CFStringRef)navText, probeChar);
            NSUInteger nextClusterChar = cluster.location + cluster.length;
            if (caretChar >= navText.length) break;
            NSUInteger nextByte = CjguiTestUtf8LengthOfUtf16Prefix(navText, nextClusterChar);
            if (nextByte == NSNotFound || nextByte <= navBoundaryByte) break;
            navBoundaryByte = nextByte;
        }
        if (navMismatch || navCompared < 20) {
            printf("VISUAL_NAV_MISMATCH compared=%lu detail=%s\n",
                (unsigned long)navCompared, navMismatchDetail.UTF8String);
            (void)require(NO, "visual_neighbor_matches_nstextview_arrows");
            return 59;
        }
        // M2（affinity 显式分支）判别：以参照布局（同文字/字体/宽度）的行几何为
        // 平台事实——
        // ① 软折行边界：行 N 末内侧与行 N+1 首内侧两次命中必须给出**同一 byte、
        //    相异 affinity**（0=Upstream 渲染上一行末 / 1=Downstream 渲染本行首）；
        //    旧 fraction>0.5 在行界点击不具此判别力（next 插入点在另一行）。
        // ② bidi 行：跨 RTL/LTR 交界的命中点在插入点 x 两侧 affinity 翻转。
        // ③ 渲染侧：caret 矩形按 affinity 分行（Upstream y = 上一视觉行）。
        {
            NSUInteger affUtf8Length = [navText lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
            // ① 软折行双侧：找连续两个视觉行，取前行末/次行首的内部采样点。
            __block int wrapCases = 0;
            __block NSUInteger prevLineGlyphEnd = 0;
            [refLM enumerateLineFragmentsForGlyphRange:NSMakeRange(0, refLM.numberOfGlyphs)
                                            usingBlock:^(NSRect rect, NSRect usedRect,
                                                         NSTextContainer *c, NSRange glyphRange, BOOL *stop) {
                if (glyphRange.location > 0 && prevLineGlyphEnd > 0 && wrapCases < 3) {
                    NSRange prevG = NSMakeRange(0, 0), curG = NSMakeRange(0, 0);
                    [refLM lineFragmentRectForGlyphAtIndex:prevLineGlyphEnd - 1 effectiveRange:&prevG];
                    [refLM lineFragmentRectForGlyphAtIndex:glyphRange.location effectiveRange:&curG];
                    NSRange prevC = [refLM characterRangeForGlyphRange:prevG actualGlyphRange:NULL];
                    NSRange curC = [refLM characterRangeForGlyphRange:curG actualGlyphRange:NULL];
                    NSUInteger boundaryChar = NSMaxRange(prevC); // 次行首字符 == 前行 maxRange
                    // 参照容器坐标 → CJGUI 场景坐标：加 textRect 内缩 (7,6)。
                    CGFloat endX = NSMaxX(usedRect) + 7.0 + 0.5; // 行末线外侧：命中解析到边界字符
                    CGFloat endY = NSMidY([refLM lineFragmentRectForGlyphAtIndex:prevLineGlyphEnd - 1
                                                                  effectiveRange:NULL]) + 6.0;
                    CGFloat startX = NSMinX(rect) + 7.0 + 1.0, startCY = NSMidY(rect) + 6.0;
                    uint32_t b1 = 0, a1 = 0, b2 = 0, a2 = 0;
                    CjguiInternalRendererStatus s1 = cjgui_internal_renderer_hit_test_composable_text(
                        session, 992, endX, endY, ctx.composableSceneVersion, &b1, &a1);
                    CjguiInternalRendererStatus s2 = cjgui_internal_renderer_hit_test_composable_text(
                        session, 992, startX, startCY, ctx.composableSceneVersion, &b2, &a2);
                    if (s1 == CJGUI_INTERNAL_RENDERER_OK && s2 == CJGUI_INTERNAL_RENDERER_OK) {
                        NSUInteger c1 = CjguiTestUtf16LengthOfUtf8Prefix(navText, b1);
                        NSUInteger c2 = CjguiTestUtf16LengthOfUtf8Prefix(navText, b2);
                        // 两侧都解析到边界字节（容差：行末采样可能落在次行首字符，
                        // 行首采样也可能因 1pt 内缩落回本行末——只断言能区分侧）。
                        if (c1 == boundaryChar && c2 == boundaryChar) {
                            if (a1 == 0 && a2 == 1) {
                                wrapCases += 1;
                            } else {
                                printf("SOFTWRAP_AFFINITY_MISMATCH boundaryChar=%lu a1=%u a2=%u\n",
                                    (unsigned long)boundaryChar, a1, a2);
                                *stop = YES;
                            }
                        } else if (c1 != boundaryChar || c2 != boundaryChar) {
                            printf("SOFTWRAP_SAMPLE boundaryChar=%lu c1=%lu(a%u) c2=%lu(a%u)\n",
                                (unsigned long)boundaryChar, (unsigned long)c1, a1,
                                (unsigned long)c2, a2);
                        }
                    }
                }
                prevLineGlyphEnd = NSMaxRange(glyphRange);
            }];
            {
                __block int refLinesNow = 0;
                [refLM enumerateLineFragmentsForGlyphRange:NSMakeRange(0, refLM.numberOfGlyphs)
                                                usingBlock:^(NSRect r, NSRect u, NSTextContainer *c,
                                                             NSRange g, BOOL *stop) { refLinesNow += 1; }];
                printf("REF_LINES_AT_AFFINITY count=%d glyphs=%lu containerW=%.1f\n",
                    refLinesNow, (unsigned long)refLM.numberOfGlyphs, refContainer.size.width);
            }
            if (require(wrapCases >= 1, "softwrap_affinity_cases_present")) {
                printf("SOFTWRAP_AFFINITY_NO_CASES\n");
                return 68;
            }
            // ③ 渲染侧：取一个软折行边界字节，Upstream/Downstream caret 矩形分行。
            __block int sideOk = 0;
            [refLM enumerateLineFragmentsForGlyphRange:NSMakeRange(0, refLM.numberOfGlyphs)
                                            usingBlock:^(NSRect rect, NSRect usedRect,
                                                         NSTextContainer *c, NSRange glyphRange, BOOL *stop) {
                if (sideOk || glyphRange.location == 0) return;
                NSRange curC = [refLM characterRangeForGlyphRange:glyphRange actualGlyphRange:NULL];
                // 只取**软折行**行首（前一字符非硬终止符）：双侧渲染只在软折行
                // 存在；硬断行行首两 affinity 同行（R2 新判别）。
                if (curC.location > 0 && CjguiIsHardLineTerminatorBefore(navText, curC.location)) return;
                NSUInteger probeByte = CjguiTestUtf8LengthOfUtf16Prefix(navText, curC.location);
                if (probeByte == NSNotFound || probeByte == 0) return;
                double ux = 0, uy = 0, uw = 0, uh = 0, dx = 0, dy = 0, dw = 0, dh = 0;
                if (cjgui_internal_renderer_text_geometry_caret(session, 992, (int64_t)probeByte, 1.5,
                        ctx.composableSceneVersion, 0, &ux, &uy, &uw, &uh) != CJGUI_INTERNAL_RENDERER_OK) return;
                if (cjgui_internal_renderer_text_geometry_caret(session, 992, (int64_t)probeByte, 1.5,
                        ctx.composableSceneVersion, 1, &dx, &dy, &dw, &dh) != CJGUI_INTERNAL_RENDERER_OK) return;
                if (require(uy < dy - 0.000001, "affinity_upstream_renders_previous_line") == 0) {
                    sideOk = 1;
                } else {
                    printf("AFFINITY_SIDE_MISMATCH byte=%lu upY=%.2f downY=%.2f\n",
                        (unsigned long)probeByte, uy, dy);
                    *stop = YES;
                }
            }];
            if (require(sideOk == 1, "affinity_boundary_side_case_present")) return 67;
        }
        // M1（逐层失效反例，2026-09-30）：resize/滚动/换绑各自 staging 新场景——
        // 旧票据一律 SCENE_STALE；当前票据按**新层**回答（宽度/位移/内容真实生效）。
        {
            double lx = 0, ly = 0, lw = 0, lh = 0;
            // resize（同文字、宽 320）：旧票据拒；同字节区段行数变少（布局层真实重排）。
            int32_t narrowRows = cjgui_internal_renderer_text_line_rect_count(session, 992, 19, 123, 32,
                ctx.composableSceneVersion);
            {
                int32_t allRows = cjgui_internal_renderer_text_line_rect_count(session, 992, 0, 138, 32,
                    ctx.composableSceneVersion);
                printf("CJGUI_LINES all=%d\n", allRows);
                // 参照布局同范围枚举（平台行为对照）。
                NSRange diagChars = NSMakeRange(0, 60);
                NSRange diagGlyphs = [refLM glyphRangeForCharacterRange:diagChars actualCharacterRange:NULL];
                __block int refRects = 0;
                [refLM enumerateEnclosingRectsForGlyphRange:diagGlyphs
                           withinSelectedGlyphRange:diagGlyphs
                                    inTextContainer:refContainer
                                         usingBlock:^(NSRect r, BOOL *stop) { refRects += 1; }];
                printf("REF_LINES rects=%d glyphs=%lu\n", refRects, (unsigned long)refLM.numberOfGlyphs);
                {
                    __block int refLinesLayer = 0;
                    [refLM enumerateLineFragmentsForGlyphRange:NSMakeRange(0, refLM.numberOfGlyphs)
                                                    usingBlock:^(NSRect r, NSRect u, NSTextContainer *c,
                                                                 NSRange g, BOOL *stop) { refLinesLayer += 1; }];
                    printf("REF_LINES_AT_LAYER count=%d containerW=%.1f viewFrame=%.1f\n",
                        refLinesLayer, refContainer.size.width, refView.frame.size.width);
                }
                for (int32_t ri = 0; ri < allRows && ri < 10; ri++) {
                    printf("CJGUI_LINE row=%d y=%.2f x=%.2f w=%.2f\n", ri,
                        cjgui_internal_renderer_text_line_rect_value(session, 992, 0, 138, 32, ri, 1,
                            ctx.composableSceneVersion),
                        cjgui_internal_renderer_text_line_rect_value(session, 992, 0, 138, 32, ri, 0,
                            ctx.composableSceneVersion),
                        cjgui_internal_renderer_text_line_rect_value(session, 992, 0, 138, 32, ri, 2,
                            ctx.composableSceneVersion));
                }
            }
            if (require(narrowRows >= 2, "layer_baseline_wrapped_rows")) {
                for (int32_t ri = 0; ri < (narrowRows > 6 ? 6 : narrowRows); ri++) {
                    printf("NARROW_RECT row=%d y=%.2f w=%.2f\n", ri,
                        cjgui_internal_renderer_text_line_rect_value(session, 992, 19, 123, 32, ri, 1,
                            ctx.composableSceneVersion),
                        cjgui_internal_renderer_text_line_rect_value(session, 992, 19, 123, 32, ri, 2,
                            ctx.composableSceneVersion));
                }
                return 70;
            }
            if (require(submitSceneVariant(session, 30, 992, CjguiVisualNavDocText(), 320, 0) ==
                CJGUI_INTERNAL_RENDERER_OK, "resize_doc_accepted")) return 71;
            if (require(cjgui_internal_renderer_text_line_rect_count(session, 992, 19, 123, 32, 29) ==
                -CJGUI_INTERNAL_RENDERER_SCENE_STALE,
                "resize_rejects_old_ticket")) return 72;
            int32_t wideRows = cjgui_internal_renderer_text_line_rect_count(session, 992, 19, 123, 32,
                ctx.composableSceneVersion);
            CJGuiInternalComposableSceneNode *diagNode = nil;
            for (CJGuiInternalComposableSceneNode *cand in ctx.composableSceneOverlay.nodes) {
                if (cand.node.nodeId == 992) { diagNode = cand; break; }
            }
            printf("LAYER_DIAG narrow=%d wide=%d containerW=%.1f\n", narrowRows, wideRows,
                diagNode.preparedTextLayout ? diagNode.preparedTextLayout.container.size.width : -1.0);
            if (require(wideRows >= 1 && wideRows < narrowRows,
                "resize_relayout_fewer_rows_at_wider_width")) return 73;
            // 滚动（同文字同宽、translateY=-25）：旧票据拒；当前票据 caret 矩形
            // y 精确平移 -25，byte 逻辑锚不变。
            double px = 0, py = 0, pw = 0, ph = 0;
            if (require(cjgui_internal_renderer_text_geometry_caret(session, 992, 0, 1.5,
                    ctx.composableSceneVersion, 2, &px, &py, &pw, &ph) == CJGUI_INTERNAL_RENDERER_OK,
                "scroll_pre_caret")) return 74;
            if (require(submitSceneVariant(session, 31, 992, CjguiVisualNavDocText(), 320, -25) ==
                CJGUI_INTERNAL_RENDERER_OK, "scroll_doc_accepted")) return 75;
            if (require(cjgui_internal_renderer_text_geometry_caret(session, 992, 0, 1.5, 30, 2,
                    &lx, &ly, &lw, &lh) == CJGUI_INTERNAL_RENDERER_SCENE_STALE,
                "scroll_rejects_old_ticket")) return 76;
            double sx = 0, sy = 0, sw = 0, sh = 0;
            if (require(cjgui_internal_renderer_text_geometry_caret(session, 992, 0, 1.5,
                    ctx.composableSceneVersion, 2, &sx, &sy, &sw, &sh) == CJGUI_INTERNAL_RENDERER_OK &&
                fabs(sy - py + 25.0) < 0.000001,
                "scroll_moves_rect_keeps_logical_anchor")) return 77;
            // 换绑（同 nodeId、不同文字）：旧票据拒，新票据按新文字回答。
            if (require(submitSceneVariant(session, 32, 992, @"switched 文档", 320, -25) ==
                CJGUI_INTERNAL_RENDERER_OK, "rebind_doc_accepted")) return 78;
            if (require(cjgui_internal_renderer_text_geometry_caret(session, 992, 0, 1.5, 31, 2,
                    &lx, &ly, &lw, &lh) == CJGUI_INTERNAL_RENDERER_SCENE_STALE,
                "rebind_rejects_old_ticket")) return 79;
            if (require(cjgui_internal_renderer_text_geometry_caret(session, 992, 0, 1.5,
                    ctx.composableSceneVersion, 2, &lx, &ly, &lw, &lh) == CJGUI_INTERNAL_RENDERER_OK,
                "rebind_current_ticket_answered")) return 80;
        }
        // R1（插入点查询所属行与容量，2026-09-30）：宽 W 行 A + 窄 i 折行 B。
        // 点击行 A 末（used 末端外 0.5pt）⇒ charIndex=A.maxRange（行末 snap）；
        // 旧实现缓冲按 A 行容量分配、插入点查询落在 B 行（字符多）⇒ 越界写
        // （ASan/guard 应能区分）。判别：命中返回 byte=A 末边界、affinity=0
        // （Upstream），且重复调用稳定（不破坏堆）。同一节点再验正常行首点击
        // 正控（B 行首 ⇒ Downstream）。
        if (require(submitWrapFoldDoc(session, 33) == CJGUI_INTERNAL_RENDERER_OK,
            "wrapfold_doc_accepted")) return 81;
        {
            CJGuiInternalComposableSceneNode *foldNode = nil;
            for (CJGuiInternalComposableSceneNode *cand in ctx.composableSceneOverlay.nodes) {
                if (cand.node.nodeId == 994) { foldNode = cand; break; }
            }
            NSLayoutManager *foldLM = foldNode.preparedTextLayout.layoutManager;
            NSString *foldText = CjguiWrapFoldDocText();
            // 行 A = 首视觉行（W 行）。定位其矩形与已用末端。
            NSRange lineAGlyph = NSMakeRange(0, 0);
            [foldLM lineFragmentRectForGlyphAtIndex:0 effectiveRange:&lineAGlyph];
            NSRect lineARect = [foldLM lineFragmentRectForGlyphAtIndex:0 effectiveRange:NULL];
            NSRect lineAUsed = [foldLM lineFragmentUsedRectForGlyphAtIndex:0 effectiveRange:NULL];
            NSRange lineAChar = [foldLM characterRangeForGlyphRange:lineAGlyph actualGlyphRange:NULL];
            // 至少两行（W 行 + i 折行）才构成反例形状。
            if (require(NSMaxRange(lineAGlyph) < foldLM.numberOfGlyphs,
                    "wrapfold_doc_has_folded_second_line")) return 82;
            // 点击行 A 末：used 末端外 0.5pt、行 A 中线；场景坐标 = textRect 内缩(7,6)。
            CGFloat clickX = NSMaxX(lineAUsed) + 7.0 + 0.5;
            CGFloat clickY = NSMidY(lineARect) + 6.0;
            uint32_t hitByte = 0, hitAff = 0;
            if (require(cjgui_internal_renderer_hit_test_composable_text(session, 994,
                    clickX, clickY, ctx.composableSceneVersion, &hitByte, &hitAff) ==
                CJGUI_INTERNAL_RENDERER_OK,
                "wrapfold_line_end_click_ok")) return 83;
            NSUInteger expectedChar = NSMaxRange(lineAChar);
            NSString *prefixA = [foldText substringToIndex:expectedChar];
            NSUInteger expectedByte = [prefixA lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
            if (require(hitByte == expectedByte,
                    "wrapfold_line_end_byte_is_boundary")) {
                printf("WRAPFOLD_MISMATCH expectedByte=%lu got=%lu\n",
                    (unsigned long)expectedByte, (unsigned long)hitByte);
                return 84;
            }
            if (require(hitAff == 0u, "wrapfold_line_end_affinity_upstream")) return 85;
            // 正控：精确点击行 B 插入点起始边界 ⇒ Downstream。
            // 字形原点+2pt可能已经越过窄i的半字宽，不能固定期待上一停靠点。
            NSRange lineBGlyph = NSMakeRange(0, 0);
            [foldLM lineFragmentRectForGlyphAtIndex:NSMaxRange(lineAGlyph) effectiveRange:&lineBGlyph];
            NSRange lineBChar = [foldLM characterRangeForGlyphRange:lineBGlyph actualGlyphRange:NULL];
            NSRect lineBRect = [foldLM lineFragmentRectForGlyphAtIndex:NSMaxRange(lineAGlyph) effectiveRange:NULL];
            NSUInteger bFirst = lineBChar.location;
            CGFloat bX = lineBRect.origin.x + 7.0;
            CGFloat bY = NSMidY(lineBRect) + 6.0;
            uint32_t bByte = 0, bAff = 0;
            if (require(cjgui_internal_renderer_hit_test_composable_text(session, 994,
                    bX, bY, ctx.composableSceneVersion, &bByte, &bAff) ==
                CJGUI_INTERNAL_RENDERER_OK,
                "wrapfold_line_b_click_ok")) return 86;
            NSString *prefixB = [foldText substringToIndex:bFirst];
            NSUInteger bExpectedByte = [prefixB lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
            if (require(bByte == bExpectedByte, "wrapfold_line_b_byte")) return 87;
            if (require(bAff == 1u, "wrapfold_line_b_affinity_downstream")) return 88;
        }
        // 组一（Astra 正式裁决）：停靠点解析器判别。
        // ① 反例一（短行A/长行B，AUTO 误析）：994 折行夹具的边界字节 b——
        //    resolve(b, Upstream) 必须解析到**行A**（lineFirst==A.location），
        //    resolve(b, Downstream/AUTO) 解析到行B——曾 AUTO 一律按 B 首并误判。
        {
            CJGuiInternalComposableSceneNode *foldNode3 = nil;
            for (CJGuiInternalComposableSceneNode *cand in ctx.composableSceneOverlay.nodes) {
                if (cand.node.nodeId == 994) { foldNode3 = cand; break; }
            }
            if (!foldNode3 || !foldNode3.preparedTextLayout) {
                if (require(submitWrapFoldDoc(session, 38) == CJGUI_INTERNAL_RENDERER_OK,
                    "wrapfold_for_stopresolver")) return 110;
                for (CJGuiInternalComposableSceneNode *cand in ctx.composableSceneOverlay.nodes) {
                    if (cand.node.nodeId == 994) { foldNode3 = cand; break; }
                }
            }
            NSLayoutManager *fLM3 = foldNode3.preparedTextLayout.layoutManager;
            NSString *fText3 = CjguiWrapFoldDocText();
            NSRange firstLineG3 = NSMakeRange(0, 0);
            [fLM3 lineFragmentRectForGlyphAtIndex:0 effectiveRange:&firstLineG3];
            NSRange firstLineC3 = [fLM3 characterRangeForGlyphRange:firstLineG3 actualGlyphRange:NULL];
            NSUInteger boundaryByte3 =
                CjguiTestUtf8LengthOfUtf16Prefix(fText3, NSMaxRange(firstLineC3));
            uint32_t rb3 = 0, rs3 = 2, rf3 = 0, rl3 = 0; double rx3 = 0;
            if (require(cjgui_internal_renderer_text_stop_resolve(session, 994,
                    (int64_t)boundaryByte3, 0, ctx.composableSceneVersion,
                    &rb3, &rs3, &rf3, &rl3, &rx3) == CJGUI_INTERNAL_RENDERER_OK &&
                    rs3 == 0u && rf3 == (uint32_t)firstLineC3.location,
                "stop_resolve_upstream_belongs_to_lineA")) {
                printf("STOP_RESOLVE_UP got side=%u lineFirst=%u want lineA=%lu\n",
                    rs3, rf3, (unsigned long)firstLineC3.location);
                return 111;
            }
            if (require(cjgui_internal_renderer_text_stop_resolve(session, 994,
                    (int64_t)boundaryByte3, 1, ctx.composableSceneVersion,
                    &rb3, &rs3, &rf3, &rl3, &rx3) == CJGUI_INTERNAL_RENDERER_OK &&
                    rs3 == 1u && rf3 == (uint32_t)NSMaxRange(firstLineC3),
                "stop_resolve_downstream_belongs_to_lineB")) return 112;
            // ② 反例二（携带分支不随点击/失效重解析——会话层窗口已接
            // invalidatePlainPositionBranch；native 侧判据：resolve AUTO 在
            // 边界字节取 B（primary 所在行），使失效后重解析得到确定结果）。
            if (require(cjgui_internal_renderer_text_stop_resolve(session, 994,
                    (int64_t)boundaryByte3, 2, ctx.composableSceneVersion,
                    &rb3, &rs3, &rf3, &rl3, &rx3) == CJGUI_INTERNAL_RENDERER_OK &&
                    rs3 == 1u && rf3 == (uint32_t)NSMaxRange(firstLineC3),
                "stop_resolve_auto_prefers_own_line")) return 113;
            // ③ 水平键盘边跳过折行处同字节别名；双侧停靠点仍供命中、caret和垂直导航。
            // 期望独立取自字符串字素边界，并由上面的 NSTextView 对照覆盖。
            NSUInteger boundaryChar3 = NSMaxRange(firstLineC3);
            CFRange nextCluster3 = CFStringGetRangeOfComposedCharactersAtIndex((CFStringRef)fText3, boundaryChar3);
            CFRange previousCluster3 = CFStringGetRangeOfComposedCharactersAtIndex((CFStringRef)fText3, boundaryChar3 - 1);
            NSUInteger nextByte3 = CjguiTestUtf8LengthOfUtf16Prefix(fText3, (NSUInteger)(nextCluster3.location + nextCluster3.length));
            NSUInteger previousByte3 = CjguiTestUtf8LengthOfUtf16Prefix(fText3, (NSUInteger)previousCluster3.location);
            uint32_t nb3 = 0, ns3 = 2;
            if (require(cjgui_internal_renderer_text_stop_neighbor(session, 994,
                    (int64_t)boundaryByte3, 0, 0, ctx.composableSceneVersion,
                    &nb3, &ns3) == CJGUI_INTERNAL_RENDERER_OK &&
                    nb3 == nextByte3,
                "stop_neighbor_upstream_right_skips_wrap_alias")) return 114;
            if (require(cjgui_internal_renderer_text_stop_neighbor(session, 994,
                    (int64_t)boundaryByte3, 1, 1, ctx.composableSceneVersion,
                    &nb3, &ns3) == CJGUI_INTERNAL_RENDERER_OK && nb3 == previousByte3,
                "stop_neighbor_downstream_left_skips_wrap_alias")) return 115;
            // ④ bidi 行经解析器可解（primary+alternate 合并表覆盖；具体分支
            //    数量由平台决定，此处只证**可解析不具名拒绝**）。
            if (require(submitVisualNavDoc(session, 39) == CJGUI_INTERNAL_RENDERER_OK,
                "navdoc_for_stopresolver")) return 116;
            NSUInteger bidiByte = CjguiTestUtf8LengthOfUtf16Prefix(navText, 8); // מ 段中部
            uint32_t bb3 = 0, bs3 = 2, bf3 = 0, bl3 = 0; double bx3 = 0;
            if (require(cjgui_internal_renderer_text_stop_resolve(session, 992,
                    (int64_t)bidiByte, 2, ctx.composableSceneVersion,
                    &bb3, &bs3, &bf3, &bl3, &bx3) == CJGUI_INTERNAL_RENDERER_OK,
                "stop_resolve_bidi_mid_run_ok")) {
                printf("STOP_RESOLVE_BIDI byte=%lu status?\n", (unsigned long)bidiByte);
                return 117;
            }
        }
        // R2（硬/软换行的插入点分支，2026-09-30 复核反例）：
        // ① 硬断行行首落点（Left 从行2的 c 后到 byte3）affinity 必须 Downstream(1)
        //    ——byte3 唯一渲染在行2；软折行行首才是 Upstream(0)。旧代码对所有左邻
        //    无条件 Upstream。
        // ② 硬断行行首 caret 的 Upstream 渲染不得跳行1末：affinity 0 与 1 的矩形
        //    必须同行（行2）。软折行边界（994 夹具）两 affinity 分行保持。
        // ③ 垂直反例的前半：byte3 若被画到行1，Down 会从行1出发去行2 而不是
        //    行2→行3——由②的同行断言保证正确起点。
        if (require(submitHardBreakDoc(session, 36) == CJGUI_INTERNAL_RENDERER_OK,
            "hardbreak_doc_accepted")) return 96;
        {
            uint32_t nb = 0, na = 0;
            if (require(cjgui_internal_renderer_text_visual_neighbor(session, 997, 4, 1,
                    ctx.composableSceneVersion, 2, &nb, &na) ==
                    CJGUI_INTERNAL_RENDERER_OK && nb == 3 && na == 1u,
                "hardbreak_left_lands_downstream")) {
                printf("HARDBREAK_NEIGHBOR byte=%u aff=%u (want 3,1)\n", nb, na);
                return 97;
            }
            double ux = 0, uy = 0, uw = 0, uh = 0, dx = 0, dy = 0, dw = 0, dh = 0;
            if (require(cjgui_internal_renderer_text_geometry_caret(session, 997, 3, 1.5,
                    ctx.composableSceneVersion, 0, &ux, &uy, &uw, &uh) ==
                CJGUI_INTERNAL_RENDERER_OK, "hardbreak_up_caret")) return 98;
            if (require(cjgui_internal_renderer_text_geometry_caret(session, 997, 3, 1.5,
                    ctx.composableSceneVersion, 1, &dx, &dy, &dw, &dh) ==
                CJGUI_INTERNAL_RENDERER_OK, "hardbreak_down_caret")) return 99;
            if (require(fabs(uy - dy) < 0.000001,
                    "hardbreak_line_start_renders_same_line_both_affinity")) {
                printf("HARDBREAK_CARET upY=%.2f downY=%.2f (must be same line)\n", uy, dy);
                return 100;
            }
        }
        // Accepted position facts keep both wrap-side stops. Horizontal keyboard
        // policy skips their alias edge, whereas hit/caret/vertical keep identity.
        {
            if (require(submitWrapFoldDoc(session, 37) == CJGUI_INTERNAL_RENDERER_OK,
                "wrapfold_for_full_position_identity")) return 101;
            CJGuiInternalComposableSceneNode *foldNode2 = nil;
            for (CJGuiInternalComposableSceneNode *cand in ctx.composableSceneOverlay.nodes)
                if (cand.node.nodeId == 994) { foldNode2 = cand; break; }
            NSLayoutManager *fLM = foldNode2.preparedTextLayout.layoutManager;
            NSString *fText = CjguiWrapFoldDocText();
            NSRange firstLineG = NSMakeRange(0, 0);
            [fLM lineFragmentRectForGlyphAtIndex:0 effectiveRange:&firstLineG];
            NSRange firstLineC = [fLM characterRangeForGlyphRange:firstLineG actualGlyphRange:NULL];
            NSUInteger boundaryChar = NSMaxRange(firstLineC);
            NSUInteger boundaryByte = CjguiTestUtf8LengthOfUtf16Prefix(fText, boundaryChar);
            uint64_t up[8], down[8], hitUp[8], moved[8];
            double upRect[4], downRect[4], hitRect[4], moveRect[4];
            if (require(cjgui_internal_renderer_text_position_v1(session, 994, ctx.composableSceneVersion,
                    0, boundaryByte, 0, 0, 0, 0, 0, 0, up, upRect) == CJGUI_INTERNAL_RENDERER_OK &&
                cjgui_internal_renderer_text_position_v1(session, 994, ctx.composableSceneVersion,
                    0, boundaryByte, 1, 0, 0, 0, 0, 0, down, downRect) == CJGUI_INTERNAL_RENDERER_OK &&
                up[2] == down[2] && up[0] == down[0] && up[1] != down[1] && upRect[1] < downRect[1],
                "same_byte_distinct_accepted_wrap_stops")) return 102;
            if (require(cjgui_internal_renderer_text_position_v1(session, 994, ctx.composableSceneVersion,
                    1, 0, 2, 0, 0, 0, upRect[0] + 100, upRect[1] + upRect[3]/2, hitUp, hitRect)
                    == CJGUI_INTERNAL_RENDERER_OK && hitUp[0] == up[0] && hitUp[1] == up[1],
                "hit_and_caret_share_wrap_stop_identity")) return 103;
            if (require(cjgui_internal_renderer_text_position_v1(session, 994, ctx.composableSceneVersion,
                    3, boundaryByte, 1, down[0], down[1], 0, upRect[0]+100, downRect[1], moved, moveRect)
                    == CJGUI_INTERNAL_RENDERER_OK && moved[1] == up[1] && moved[2] == boundaryByte && !moved[7],
                "vertical_same_byte_is_successful_distinct_stop")) return 104;
            CFRange nextCluster = CFStringGetRangeOfComposedCharactersAtIndex((CFStringRef)fText, boundaryChar);
            NSUInteger expectedNext = CjguiTestUtf8LengthOfUtf16Prefix(fText,
                (NSUInteger)(nextCluster.location + nextCluster.length));
            if (require(cjgui_internal_renderer_text_position_v1(session, 994, ctx.composableSceneVersion,
                    2, boundaryByte, 0, up[0], up[1], 1, 0, 0, moved, moveRect)
                    == CJGUI_INTERNAL_RENDERER_OK && moved[2] == expectedNext && !moved[7],
                "horizontal_keyboard_skips_only_wrap_alias")) return 105;
            if (require(cjgui_internal_renderer_text_position_v1(session, 994, ctx.composableSceneVersion,
                    0, boundaryByte, 0, up[0]+1, up[1], 0, 0, 0, moved, moveRect)
                    == CJGUI_INTERNAL_RENDERER_SCENE_STALE,
                "expired_layout_lease_refuses_old_stop")) return 106;
            uint64_t before[4], after[4];
            cjgui_internal_renderer_text_position_stats_v1(session, before);
            for (NSUInteger i=0;i<100;i++)
                if (require(cjgui_internal_renderer_text_position_v1(session, 994, ctx.composableSceneVersion,
                    0, boundaryByte, 0, up[0], up[1], 0, 0, 0, moved, moveRect)
                    == CJGUI_INTERNAL_RENDERER_OK, "same_lease_repeated_query")) return 107;
            cjgui_internal_renderer_text_position_stats_v1(session, after);
            if (require(after[0] == before[0] && after[2] == before[2] && after[1] == before[1]+100 &&
                    after[3] > before[3], "repeated_queries_reuse_prepared_layout_and_stop_table")) return 108;
        }
        // M1（空行/末尾换行/空范围矩形契约）：文档 "aa\n\nbb"——
        // · 空范围 [x,x) ⇒ 零矩形（折叠选区不产生高亮）；
        // · 真空行的换行符 [3,4) ⇒ 恰一行矩形，其 y 介于行0 与行2 之间；
        // · EOF caret（"ab\n" 的 byte 3）矩形落在 extra line fragment（低于
        //   行末 \n 的 caret 一整行）。
        if (require(submitEmptyLineDoc(session, 34) == CJGUI_INTERNAL_RENDERER_OK,
            "emptyline_doc_accepted")) return 89;
        if (require(cjgui_internal_renderer_text_line_rect_count(session, 995, 3, 3, 4,
                ctx.composableSceneVersion) == 0,
            "empty_range_is_zero_rects_contract")) return 90;
        {
            int32_t nlCount = cjgui_internal_renderer_text_line_rect_count(session, 995, 3, 4, 4,
                ctx.composableSceneVersion);
            double nlY = cjgui_internal_renderer_text_line_rect_value(session, 995, 3, 4, 4, 0, 1,
                ctx.composableSceneVersion);
            double row0Y = cjgui_internal_renderer_text_line_rect_value(session, 995, 0, 3, 4, 0, 1,
                ctx.composableSceneVersion);
            double row2Y = cjgui_internal_renderer_text_line_rect_value(session, 995, 4, 6, 4, 0, 1,
                ctx.composableSceneVersion);
            if (require(nlCount == 1 && nlY > row0Y && nlY < row2Y,
                    "empty_line_newline_rect_between_rows")) {
                printf("EMPTYLINE nl=%d y=%.2f row0=%.2f row2=%.2f\n", nlCount, nlY, row0Y, row2Y);
                return 91;
            }
        }
        // EOF caret 在 extra line fragment：用 R1 文档的变体在 992 上验证
        //（"ab\n" 短文单独提交）。
        if (require(submitSceneVariant(session, 35, 996, @"ab\n", 160, 0) ==
            CJGUI_INTERNAL_RENDERER_OK, "eof_doc_accepted")) return 92;
        {
            double c2y = 0, c2x = 0, c2w = 0, c2h = 0, eofY = 0, eofX = 0, eofW = 0, eofH = 0;
            if (require(cjgui_internal_renderer_text_geometry_caret(session, 996, 2, 1.5,
                    ctx.composableSceneVersion, 2, &c2x, &c2y, &c2w, &c2h) ==
                CJGUI_INTERNAL_RENDERER_OK, "eof_pre_caret")) return 93;
            if (require(cjgui_internal_renderer_text_geometry_caret(session, 996, 3, 1.5,
                    ctx.composableSceneVersion, 2, &eofX, &eofY, &eofW, &eofH) ==
                CJGUI_INTERNAL_RENDERER_OK, "eof_caret")) return 94;
            if (require(eofY > c2y + 5.0,
                    "eof_caret_renders_on_extra_line")) {
                printf("EOF_CARET eolY=%.2f eofY=%.2f\n", c2y, eofY);
                return 95;
            }
        }

        // 回归（cross_fragment 反例）：整片段=单个重音簇 e+U+0301 时，簇起点的
        // Right 落点是行末线（簇末边界 3B），行末的 Left 回簇首——行末插入点曾
        // 被误取末簇起点，导致 Right 误判成行界跳片段。
        if (require(submitAccentFragDoc(session, 30) == CJGUI_INTERNAL_RENDERER_OK,
            "accent_frag_doc_accepted")) return 60;
        uint32_t accentByte = 0, accentAff = 0;
        if (require(cjgui_internal_renderer_text_visual_neighbor(session, 993, 0, 0,
                ctx.composableSceneVersion, 2, &accentByte, &accentAff) ==
                CJGUI_INTERNAL_RENDERER_OK && accentByte == 3,
            "accent_cluster_start_right_lands_after_cluster")) return 61;
        if (require(cjgui_internal_renderer_text_visual_neighbor(session, 993, 3, 1,
                ctx.composableSceneVersion, 2, &accentByte, &accentAff) ==
                CJGUI_INTERNAL_RENDERER_OK && accentByte == 0,
            "accent_line_end_left_lands_cluster_start")) return 62;
        printf("F11_TRANSLATION_NATIVE_PASS rect=1.5,0.75 hit=1.49:no/1.5:101 "
               "clip=60.25 precise_fifo=1.5,1.0@scene1 reject_keeps_scene=1 recovery_scene=3 "
               "scale2_edge_green=%u,%u scale1_edge_green=%u,%u text_rasters=%llu caret_x=%.3f->%.3f "
               "backdrop_red=%u->%u redraw=%llu->%llu hot_hit=%llu\n",
               outsideGreen, insideGreen, outsideOneXGreen, insideOneXGreen,
               (unsigned long long)textRasterBefore, caretX, movedCaretX,
               oldBackdrop[2], movedBackdrop[2],
               (unsigned long long)oldStats.backdropPrefixPasses,
               (unsigned long long)movedStats.backdropPrefixPasses,
               (unsigned long long)stableStats.backdropCacheHits);
        if (require(cjgui_internal_renderer_destroy(session) == CJGUI_INTERNAL_RENDERER_OK,
            "destroy")) return 10;
        return 0;
    }
}

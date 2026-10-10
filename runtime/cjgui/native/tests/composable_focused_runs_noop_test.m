#define CJGUI_INTERNAL_TESTING 1
#import "../cjgui_internal_renderer.m"

#include <stdio.h>

typedef struct {
    BOOL generationStable;
    BOOL rasterStable;
    BOOL keyStable;
} RunNoopObservation;

static CJGuiInternalComposableSceneNode *makeFocusedNode(uint64_t projectionVersion) {
    CJGuiInternalComposableSceneNode *node = [CJGuiInternalComposableSceneNode new];
    CjguiInternalRendererComposableNode raw = {0};
    raw.nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT;
    raw.nodeId = 107;
    raw.resourceId = 1;
    raw.projectionVersion = projectionVersion;
    raw.x = 16; raw.y = 12; raw.width = 280; raw.height = 112;
    raw.clipX = raw.x; raw.clipY = raw.y; raw.clipWidth = raw.width; raw.clipHeight = raw.height;
    raw.fontSize = 18;
    raw.textRed = 0.14; raw.textGreen = 0.18; raw.textBlue = 0.22;
    raw.textAlpha = 1.0;
    raw.isInteractive = 1;
    node.node = raw;
    node.index = 0;
    node.value = @"A focused body whose glyph texture remains stable.\nSecond line for active TextKit.";
    node.styleRunsSignature = @"";
    node.textTextureCacheKey = @"";
    return node;
}

static CJGuiInternalComposableSceneNode *makeProgressNode(NSString *value, uint64_t version) {
    CJGuiInternalComposableSceneNode *node = [CJGuiInternalComposableSceneNode new];
    CjguiInternalRendererComposableNode raw = {0};
    raw.nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT;
    raw.nodeId = 108;
    raw.resourceId = 2;
    raw.projectionVersion = version;
    raw.x = 16; raw.y = 140; raw.width = 280; raw.height = 28;
    raw.clipX = raw.x; raw.clipY = raw.y; raw.clipWidth = raw.width; raw.clipHeight = raw.height;
    raw.fontSize = 14;
    raw.textAlpha = 1.0;
    node.node = raw;
    node.index = 1;
    node.value = value;
    node.styleRunsSignature = @"";
    node.textTextureCacheKey = @"";
    return node;
}

static BOOL publishProgressOnly(CJGuiInternalSession *session, NSString *progress,
                                uint64_t version, NSString *activeRuns) {
    CJGuiInternalComposableSceneOverlay *overlay = session.composableSceneOverlay;
    CJGuiInternalComposableSceneNode *previousActive = overlay.nodes.count > 0 ? overlay.nodes[0] : nil;
    CJGuiInternalComposableSceneNode *active = CjguiCloneComposableSceneNode(session, previousActive, 0, version);
    if (!active) return NO;
    active.styleRunsSignature = activeRuns ?: @"";
    CJGuiInternalComposableSceneNode *status = makeProgressNode(progress, version);
    [overlay setNodesFromProjection:@[active, status]];
    session.composableNodes = [NSMutableArray arrayWithArray:overlay.nodes];
    session.view.composableNodes = [overlay.nodes copy];
    return YES;
}

static RunNoopObservation resendSameRunsAndProgress(CJGuiInternalSession *session, uint64_t token,
                                                     const char *encoded, NSString *activeRuns,
                                                     uint64_t version, const char *label) {
    CJGuiInternalComposableSceneOverlay *overlay = session.composableSceneOverlay;
    RunNoopObservation result = {0};
    uint64_t generationBefore = overlay.activeTextAttributedGeneration;
    uint64_t rasterBefore = session.view.testComposableTextRasterCount;
    NSString *keyBefore = overlay.nodes[0].textTextureCacheKey ?: @"";
    CjguiInternalRendererStatus status = cjgui_internal_renderer_set_composable_text_runs(
        token, 107, encoded);
    BOOL published = publishProgressOnly(session, [NSString stringWithFormat:@"Progress %llu", version],
                                         version, activeRuns);
    uint64_t generationAfter = overlay.activeTextAttributedGeneration;
    uint64_t rasterAfter = session.view.testComposableTextRasterCount;
    NSString *keyAfter = overlay.nodes[0].textTextureCacheKey ?: @"";
    result.generationStable = status == CJGUI_INTERNAL_RENDERER_OK && published &&
        generationAfter == generationBefore;
    result.rasterStable = rasterAfter == rasterBefore;
    result.keyStable = [keyAfter isEqualToString:keyBefore];
    fprintf(stderr, "case=%s status=%d gen=%llu->%llu raster=%llu->%llu key_stable=%d\n",
        label, (int)status, (unsigned long long)generationBefore,
        (unsigned long long)generationAfter, (unsigned long long)rasterBefore,
        (unsigned long long)rasterAfter, result.keyStable);
    return result;
}

static int runDuplicateRunsSetterProbe(void) {
    id<MTLDevice> device = MTLCreateSystemDefaultDevice();
    if (!device) {
        fprintf(stderr, "focused runs no-op: no Metal device available\n");
        return 2;
    }
    CJGuiInternalSession *session = [CJGuiInternalSession new];
    session.view = [[CJGuiInternalMetalView alloc] initWithFrame:NSMakeRect(0, 0, 340, 190)
        device:device commandQueue:[device newCommandQueue]];
    session.composableNodes = [NSMutableArray array];
    session.stagedComposableNodes = [NSMutableArray array];
    session.composableTextStyleRunsRaw = [NSMutableDictionary dictionary];
    CJGuiInternalComposableSceneOverlay *overlay = [[CJGuiInternalComposableSceneOverlay alloc]
        initWithFrame:NSMakeRect(0, 0, 340, 190) session:session];
    session.composableSceneOverlay = overlay;
    CJGuiInternalComposableSceneNode *active = makeFocusedNode(1);
    CJGuiInternalComposableSceneNode *progress = makeProgressNode(@"Progress 0", 1);
    session.composableTextStyleRunsRaw[@(107)] = @"";
    session.composableNodes = [NSMutableArray arrayWithArray:@[active, progress]];
    overlay.nodes = [NSMutableArray arrayWithArray:@[active, progress]];
    overlay.activeNodeId = active.node.nodeId;
    overlay.activeNodeResourceId = active.node.resourceId;
    overlay.activeNodeKind = active.node.nodeKind;
    overlay.activeNodeIndex = active.index;
    overlay.activeProjectionVersion = active.node.projectionVersion;
    overlay.activeTextBodyGeneration = 1;
    overlay.inputProxy.string = active.value;
    uint64_t token = CjguiAllocateSession(session);
    if (token == CJGUI_INTERNAL_RENDERER_INVALID_SESSION_TOKEN) return 3;

    // Establish the accepted glyph storage and one real active texture before
    // measuring no-op publications.
    CjguiInternalRendererStatus initialSet = cjgui_internal_renderer_set_composable_text_runs(token, 107, "");
    [overlay refreshGpuTextForActiveInput];
    if (initialSet != CJGUI_INTERNAL_RENDERER_OK || !active.textTexture && active.textTileTextures.count == 0) {
        fprintf(stderr, "focused runs no-op: failed to establish active texture\n");
        CjguiReleaseSession(token);
        return 4;
    }

    BOOL pass = YES;
    for (uint64_t version = 2; version <= 4; version++) {
        RunNoopObservation empty = resendSameRunsAndProgress(session, token, "", @"",
            version, "repeat-empty-runs-progress-only");
        pass &= empty.generationStable && empty.rasterStable && empty.keyStable;
    }

    // A real run value change must update attributed glyph storage and its
    // active texture. The payload format matches the existing active-run test.
    const char *rich = "0:8:18:700:2:0:0:0:1:1:0.1:0.9:0.2:0.8";
    uint64_t beforeRichGeneration = overlay.activeTextAttributedGeneration;
    uint64_t beforeRichRaster = session.view.testComposableTextRasterCount;
    CjguiInternalRendererStatus richSet = cjgui_internal_renderer_set_composable_text_runs(token, 107, rich);
    BOOL richPublished = publishProgressOnly(session, @"Progress rich", 5, [NSString stringWithUTF8String:rich]);
    BOOL richChanged = richSet == CJGUI_INTERNAL_RENDERER_OK && richPublished &&
        overlay.activeTextAttributedGeneration > beforeRichGeneration &&
        session.view.testComposableTextRasterCount > beforeRichRaster &&
        [overlay.nodes[0].textTextureCacheKey containsString:[NSString stringWithUTF8String:rich]];
    fprintf(stderr, "case=changed-to-nonempty status=%d gen=%llu->%llu raster=%llu->%llu key_has_run=%d\n",
        (int)richSet, (unsigned long long)beforeRichGeneration,
        (unsigned long long)overlay.activeTextAttributedGeneration,
        (unsigned long long)beforeRichRaster,
        (unsigned long long)session.view.testComposableTextRasterCount,
        [overlay.nodes[0].textTextureCacheKey containsString:[NSString stringWithUTF8String:rich]]);
    pass &= richChanged;

    for (uint64_t version = 6; version <= 8; version++) {
        RunNoopObservation repeatRich = resendSameRunsAndProgress(session, token, rich,
            [NSString stringWithUTF8String:rich], version, "repeat-nonempty-runs-progress-only");
        pass &= repeatRich.generationStable && repeatRich.rasterStable && repeatRich.keyStable;
    }

    const char *different = "0:8:18:400:0:0:0:0:1:1:1:0:0:1";
    uint64_t beforeDifferentGeneration = overlay.activeTextAttributedGeneration;
    uint64_t beforeDifferentRaster = session.view.testComposableTextRasterCount;
    CjguiInternalRendererStatus differentSet = cjgui_internal_renderer_set_composable_text_runs(token, 107, different);
    BOOL differentPublished = publishProgressOnly(session, @"Progress different", 9,
        [NSString stringWithUTF8String:different]);
    BOOL differentChanged = differentSet == CJGUI_INTERNAL_RENDERER_OK && differentPublished &&
        overlay.activeTextAttributedGeneration > beforeDifferentGeneration &&
        session.view.testComposableTextRasterCount > beforeDifferentRaster &&
        [overlay.nodes[0].textTextureCacheKey containsString:[NSString stringWithUTF8String:different]];
    fprintf(stderr, "case=changed-nonempty-runs status=%d gen=%llu->%llu raster=%llu->%llu key_has_run=%d\n",
        (int)differentSet, (unsigned long long)beforeDifferentGeneration,
        (unsigned long long)overlay.activeTextAttributedGeneration,
        (unsigned long long)beforeDifferentRaster,
        (unsigned long long)session.view.testComposableTextRasterCount,
        [overlay.nodes[0].textTextureCacheKey containsString:[NSString stringWithUTF8String:different]]);
    pass &= differentChanged;

    CjguiReleaseSession(token);
    fprintf(stderr, "focused_runs_noop_result=%s\n", pass ? "PASS" : "RED");
    return pass ? 0 : 1;
}

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        if (argc == 2 && strcmp(argv[1], "--runs-setter-only") == 0)
            return runDuplicateRunsSetterProbe();
        fprintf(stderr, "usage: composable_focused_runs_noop_test --runs-setter-only\n");
        return 64;
    }
}

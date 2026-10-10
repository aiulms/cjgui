#define CJGUI_INTERNAL_TESTING 1
#import "../cjgui_internal_renderer.m"

#include <stdio.h>

typedef struct {
    BOOL needBefore;
    BOOL prepStatus;
    BOOL keyMatchesAfterPrepare;
    BOOL keyMatchesAfterGlyphSync;
    BOOL keyMatchesAfterRepair;
    BOOL unchangedCandidateSkipped;
    BOOL rasterCountStable;
    uint64_t rasterBefore;
    uint64_t rasterAfterPrepare;
    uint64_t rasterAfterGlyphSync;
    uint64_t rasterAfterRepair;
    uint64_t rasterAfterUnchanged;
    uint64_t attributedBefore;
    uint64_t attributedAfter;
    NSString *storedKey;
    NSString *currentKey;
} AckObservation;

static CJGuiInternalComposableSceneNode *focusedNode(void) {
    CJGuiInternalComposableSceneNode *node = [CJGuiInternalComposableSceneNode new];
    CjguiInternalRendererComposableNode raw = {0};
    raw.nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT;
    raw.nodeId = 81;
    raw.resourceId = 1;
    raw.x = 12; raw.y = 8; raw.width = 240; raw.height = 96;
    raw.clipX = raw.x; raw.clipY = raw.y; raw.clipWidth = raw.width; raw.clipHeight = raw.height;
    raw.fontSize = 18;
    raw.textRed = 0.12; raw.textGreen = 0.18; raw.textBlue = 0.24;
    raw.textAlpha = 1.0;
    node.node = raw;
    node.index = 0;
    node.value = @"focused cache acknowledgement\nsecond line for visible glyphs\nthird line";
    node.styleRunsSignature = @"";
    node.textTextureCacheKey = @"";
    return node;
}

static AckObservation prepareThenRepeat(CJGuiInternalSession *session,
                                       CJGuiInternalComposableSceneNode *node,
                                       const char *label) {
    CJGuiInternalComposableSceneOverlay *overlay = session.composableSceneOverlay;
    AckObservation observation = {0};
    observation.attributedBefore = overlay.activeTextAttributedGeneration;
    observation.rasterBefore = session.view.testComposableTextRasterCount;
    BOOL neededBefore = CjguiStagedFocusedMultilineTilesNeedPreparation(session, node, 1.0);
    observation.needBefore = neededBefore;
    uint64_t freshBytes = 0;
    CjguiInternalRendererStatus status = CjguiPrepareStagedFocusedMultilineTiles(
        session, node, 1.0, 0, 0, &freshBytes);
    observation.prepStatus = status == CJGUI_INTERNAL_RENDERER_OK && node.textTextureByteCount > 0;
    observation.rasterAfterPrepare = session.view.testComposableTextRasterCount;
    observation.attributedAfter = overlay.activeTextAttributedGeneration;
    observation.storedKey = node.textTextureCacheKey ?: @"";
    observation.currentKey = [overlay activeMultilineTileKeyForNode:node scale:1.0] ?: @"";
    observation.keyMatchesAfterPrepare = [observation.storedKey isEqualToString:observation.currentKey];

    // This is the same active TextKit reconciliation used by the normal
    // focused-input refresh. A staged geometry acknowledgement can race ahead
    // of that refresh, so compare the stored tile provenance after glyph
    // storage has reached the candidate's actual font/run/layout state.
    [overlay prepareActiveMultilineFallbackRunsForNode:node];
    observation.attributedAfter = overlay.activeTextAttributedGeneration;
    observation.currentKey = [overlay activeMultilineTileKeyForNode:node scale:1.0] ?: @"";
    observation.keyMatchesAfterGlyphSync = [observation.storedKey isEqualToString:observation.currentKey];
    observation.rasterAfterGlyphSync = session.view.testComposableTextRasterCount;

    BOOL neededAfter = CjguiStagedFocusedMultilineTilesNeedPreparation(session, node, 1.0);
    observation.unchangedCandidateSkipped = NO;
    if (neededAfter) {
        uint64_t ignoredFreshBytes = 0;
        CjguiInternalRendererStatus repeatStatus = CjguiPrepareStagedFocusedMultilineTiles(
            session, node, 1.0, 0, 0, &ignoredFreshBytes);
        (void)repeatStatus;
    } else {
        observation.unchangedCandidateSkipped = YES;
    }
    observation.rasterAfterRepair = session.view.testComposableTextRasterCount;
    observation.currentKey = [overlay activeMultilineTileKeyForNode:node scale:1.0] ?: @"";
    observation.storedKey = node.textTextureCacheKey ?: @"";
    observation.keyMatchesAfterRepair = [observation.storedKey isEqualToString:observation.currentKey];
    BOOL neededAfterRepair = CjguiStagedFocusedMultilineTilesNeedPreparation(session, node, 1.0);
    observation.rasterAfterUnchanged = session.view.testComposableTextRasterCount;
    observation.rasterCountStable = observation.rasterAfterUnchanged == observation.rasterAfterRepair &&
        !neededAfterRepair;

    fprintf(stderr,
        "case=%s need_before=%d prep_ok=%d attr=%llu->%llu raster=%llu->%llu->%llu->%llu->%llu "
        "key_after_stage=%d key_after_glyph_sync=%d need_after_sync=%d key_after_repair=%d "
        "need_after_repair=%d repeat_raster_stable=%d fresh_bytes=%llu\n"
        "  stored_key=%s\n  current_key=%s\n",
        label, neededBefore, observation.prepStatus,
        (unsigned long long)observation.attributedBefore,
        (unsigned long long)observation.attributedAfter,
        (unsigned long long)observation.rasterBefore,
        (unsigned long long)observation.rasterAfterPrepare,
        (unsigned long long)observation.rasterAfterGlyphSync,
        (unsigned long long)observation.rasterAfterRepair,
        (unsigned long long)observation.rasterAfterUnchanged,
        observation.keyMatchesAfterPrepare, observation.keyMatchesAfterGlyphSync, neededAfter,
        observation.keyMatchesAfterRepair, neededAfterRepair, observation.rasterCountStable,
        (unsigned long long)freshBytes,
        observation.storedKey.UTF8String ?: "", observation.currentKey.UTF8String ?: "");
    return observation;
}

static void setFontSize(CJGuiInternalComposableSceneNode *node, int64_t size) {
    CjguiInternalRendererComposableNode value = node.node;
    value.fontSize = size;
    node.node = value;
}

static void setWidth(CJGuiInternalComposableSceneNode *node, int64_t width) {
    CjguiInternalRendererComposableNode value = node.node;
    value.width = width;
    value.clipWidth = width;
    node.node = value;
}

int main(void) {
    @autoreleasepool {
        id<MTLDevice> device = MTLCreateSystemDefaultDevice();
        if (!device) {
            fprintf(stderr, "focused ack cache: no Metal device available\n");
            return 2;
        }
        CJGuiInternalSession *session = [CJGuiInternalSession new];
        session.view = [[CJGuiInternalMetalView alloc] initWithFrame:NSMakeRect(0, 0, 320, 180)
            device:device commandQueue:[device newCommandQueue]];
        session.composableNodes = [NSMutableArray array];
        session.stagedComposableNodes = [NSMutableArray array];
        session.composableTextStyleRunsRaw = [NSMutableDictionary dictionary];
        CJGuiInternalComposableSceneOverlay *overlay = [[CJGuiInternalComposableSceneOverlay alloc]
            initWithFrame:NSMakeRect(0, 0, 320, 180) session:session];
        session.composableSceneOverlay = overlay;

        CJGuiInternalComposableSceneNode *node = focusedNode();
        overlay.activeNodeId = node.node.nodeId;
        overlay.activeNodeResourceId = node.node.resourceId;
        overlay.activeNodeKind = node.node.nodeKind;
        overlay.activeNodeIndex = node.index;
        overlay.activeProjectionVersion = 1;
        overlay.activeTextBodyGeneration = 1;
        overlay.nodes = [NSMutableArray arrayWithObject:node];
        overlay.inputProxy.string = node.value;
        session.composableTextStyleRunsRaw[@(node.node.nodeId)] = @"";
        fprintf(stderr, "setup_before_active_storage_reconcile\n");
        [overlay prepareActiveMultilineFallbackRunsForNode:node];
        fprintf(stderr, "setup_after_active_storage_reconcile attr=%llu\n",
            (unsigned long long)overlay.activeTextAttributedGeneration);

        BOOL pass = YES;
        AckObservation initial = prepareThenRepeat(session, node, "initial");
        pass &= initial.prepStatus && initial.keyMatchesAfterPrepare && initial.keyMatchesAfterGlyphSync &&
            initial.keyMatchesAfterRepair && initial.rasterCountStable;

        CJGuiInternalComposableSceneNode *fontCandidate = CjguiCloneComposableSceneNode(
            session, node, 0, 2);
        setFontSize(fontCandidate, 21);
        overlay.activeProjectionVersion = 2;
        overlay.nodes = [NSMutableArray arrayWithObject:fontCandidate];
        AckObservation font = prepareThenRepeat(session, fontCandidate, "base-font-change");
        pass &= font.prepStatus && font.needBefore && font.keyMatchesAfterGlyphSync && font.keyMatchesAfterRepair &&
            font.rasterCountStable;
        node = fontCandidate;

        CJGuiInternalComposableSceneNode *widthCandidate = CjguiCloneComposableSceneNode(
            session, node, 0, 3);
        setWidth(widthCandidate, 196);
        overlay.activeProjectionVersion = 3;
        overlay.nodes = [NSMutableArray arrayWithObject:widthCandidate];
        AckObservation width = prepareThenRepeat(session, widthCandidate, "width-change");
        pass &= width.prepStatus && width.needBefore && width.keyMatchesAfterGlyphSync && width.keyMatchesAfterRepair &&
            width.rasterCountStable;
        node = widthCandidate;

        session.composableTextStyleRunsRaw[@(node.node.nodeId)] = @"0:8:21:700:2:0:0:0:1:1:0.1:0.9:0.2:0.8";
        CJGuiInternalComposableSceneNode *runsCandidate = CjguiCloneComposableSceneNode(
            session, node, 0, 4);
        runsCandidate.styleRunsSignature = session.composableTextStyleRunsRaw[@(node.node.nodeId)];
        overlay.activeProjectionVersion = 4;
        overlay.nodes = [NSMutableArray arrayWithObject:runsCandidate];
        AckObservation runs = prepareThenRepeat(session, runsCandidate, "style-runs-change");
        pass &= runs.prepStatus && runs.needBefore && runs.keyMatchesAfterGlyphSync && runs.keyMatchesAfterRepair &&
            runs.rasterCountStable;

        fprintf(stderr, "focused_ack_cache_result=%s\n", pass ? "PASS" : "RED");
        return pass ? 0 : 1;
    }
}

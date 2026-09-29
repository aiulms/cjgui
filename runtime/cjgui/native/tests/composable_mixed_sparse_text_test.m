#define CJGUI_INTERNAL_TESTING 1
#import "../cjgui_internal_renderer.m"
#import <AppKit/AppKit.h>

#include <stdio.h>

static CJGuiInternalComposableSceneNode *mixedNode(uint32_t kind, uint64_t id, NSString *value,
                                                   int64_t width, int64_t height) {
    CJGuiInternalComposableSceneNode *node = [CJGuiInternalComposableSceneNode new];
    CjguiInternalRendererComposableNode raw = {0};
    raw.nodeKind = kind; raw.nodeId = id; raw.resourceId = (int64_t)id;
    raw.width = width; raw.height = height;
    raw.clipWidth = width; raw.clipHeight = height;
    raw.fontSize = 14; raw.textAlpha = 1.0;
    raw.fillAlpha = 1.0;
    node.node = raw;
    node.label = @""; node.value = value;
    node.imageTextureCacheKey = @""; node.imageTextureContentKey = @"";
    node.textTextureCacheKey = @"";
    return node;
}

int main(void) {
    @autoreleasepool {
        id<MTLDevice> device = MTLCreateSystemDefaultDevice();
        if (!device) return 2;
        CJGuiInternalSession *session = [CJGuiInternalSession new];
        session.view = [[CJGuiInternalMetalView alloc] initWithFrame:NSMakeRect(0, 0, 320, 200)
            device:device commandQueue:[device newCommandQueue]];
        session.composableSceneOverlay = [[CJGuiInternalComposableSceneOverlay alloc]
            initWithFrame:NSMakeRect(0, 0, 320, 200)];
        session.composableSceneOverlay.session = session;
        CJGuiInternalComposableSceneNode *group = mixedNode(CJGUI_INTERNAL_RENDERER_COMPOSABLE_VERTICAL,
            1, @"", 320, 200);
        CjguiInternalRendererComposableNode groupValue = group.node;
        groupValue.effectGroupPresent = 1; groupValue.effectGroupSubtreeCount = 6;
        groupValue.effectGroupOpacity = 0.8;
        group.node = groupValue;
        CJGuiInternalComposableSceneNode *vector = mixedNode(CJGUI_INTERNAL_RENDERER_COMPOSABLE_VECTOR_GRAPHIC,
            2, @"", 80, 40);
        CJGuiInternalComposableSceneNode *image = mixedNode(CJGUI_INTERNAL_RENDERER_COMPOSABLE_IMAGE,
            3, @"", 80, 40);
        CJGuiInternalComposableSceneNode *text = mixedNode(CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT,
            4, @"混合正文", 160, 32);
        CJGuiInternalComposableSceneNode *emptyInput = mixedNode(
            CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT, 5, @"", 160, 50);
        CJGuiInternalComposableSceneNode *tinyInput = mixedNode(
            CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT_INPUT, 6, @"", 8, 8);
        session.stagedComposableNodes = [NSMutableArray arrayWithArray:@[
            group, vector, image, text, emptyInput, tinyInput]];
        session.composableNodes = [NSMutableArray array];
        session.stagedComposableSceneVersion = 1;
        if (CjguiPrepareComposableTextResources(session) != CJGUI_INTERNAL_RENDERER_OK ||
            !emptyInput.preparedTextLayout || tinyInput.preparedTextLayout ||
            !text.textTexture || text.textTextureByteCount == 0) {
            fprintf(stderr, "mixed sparse baseline text/empty layout was not prepared\n");
            return 3;
        }
        session.composableNodes = [session.stagedComposableNodes mutableCopy];
        uint64_t beforeClones = session.composableSceneCloneCount;
        uint64_t beforeTextPrepares = session.composableTextLayoutPreparationCount;
        for (uint64_t turn = 0; turn < 30; turn++) {
            session.stagedComposableSceneVersion = turn + 2;
            session.stagedComposableNodes = [session.composableNodes mutableCopy];
            CJGuiInternalComposableSceneNode *recolored = CjguiCloneComposableSceneNode(session,
                session.composableNodes[1], 1, session.stagedComposableSceneVersion);
            CjguiInternalRendererComposableNode value = recolored.node;
            value.fillRed = (turn % 2) ? 0.25 : 0.75;
            recolored.node = value;
            session.stagedComposableNodes[1] = recolored;
            if (CjguiPrepareComposableTextResources(session) != CJGUI_INTERNAL_RENDERER_OK ||
                session.stagedComposableNodes[0] != session.composableNodes[0] ||
                session.stagedComposableNodes[2] != session.composableNodes[2] ||
                session.stagedComposableNodes[3] != session.composableNodes[3] ||
                session.stagedComposableNodes[4] != session.composableNodes[4] ||
                session.stagedComposableNodes[5] != session.composableNodes[5]) return 4;
            session.composableNodes = [session.stagedComposableNodes mutableCopy];
        }
        uint64_t sparseClones = session.composableSceneCloneCount - beforeClones;
        uint64_t sparseTextPrepares = session.composableTextLayoutPreparationCount - beforeTextPrepares;
        session.stagedComposableSceneVersion += 1;
        session.stagedComposableNodes = [session.composableNodes mutableCopy];
        if (CjguiPrepareComposableTextResources(session) != CJGUI_INTERNAL_RENDERER_OK ||
            session.composableSceneCloneCount != beforeClones + 30 ||
            session.composableTextLayoutPreparationCount != beforeTextPrepares) return 5;
        CJGuiInternalComposableSceneNode *acceptedText = session.composableNodes[3];
        id<MTLTexture> acceptedTexture = acceptedText.textTexture;
        session.stagedComposableSceneVersion += 1;
        session.stagedComposableNodes = [session.composableNodes mutableCopy];
        CJGuiInternalComposableSceneNode *failedText = CjguiCloneComposableSceneNode(session,
            acceptedText, 3, session.stagedComposableSceneVersion);
        failedText.value = @"rejected different body";
        session.stagedComposableNodes[3] = failedText;
        session.forcedComposableTextPreparationFailures = 1;
        BOOL rejectedKeepsOld = CjguiPrepareComposableTextResources(session) == CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR &&
            session.composableNodes[3] == acceptedText && acceptedText.textTexture == acceptedTexture &&
            [acceptedText.value isEqualToString:@"混合正文"];
        CjguiReleaseFailedCandidateTextResources(session);
        session.stagedComposableSceneVersion += 1;
        session.stagedComposableNodes = [session.composableNodes mutableCopy];
        CJGuiInternalComposableSceneNode *replacement = CjguiCloneComposableSceneNode(session,
            acceptedText, 3, session.stagedComposableSceneVersion);
        CjguiInternalRendererComposableNode replacementValue = replacement.node;
        replacementValue.nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_VECTOR_GRAPHIC;
        replacement.node = replacementValue;
        replacement.value = @"";
        session.stagedComposableNodes[3] = replacement;
        BOOL kindClear = CjguiPrepareComposableTextResources(session) == CJGUI_INTERNAL_RENDERER_OK &&
            !replacement.textTexture && replacement.textTextureByteCount == 0 &&
            !replacement.preparedTextLayout && acceptedText.textTexture == acceptedTexture;
        printf("CJGUI_MIXED_SPARSE clones=%llu/30 text_prepares=%llu/0 empty_layout=%d "
               "tiny_unprepared=%d rejected_keeps_old=%d kind_clear=%d\n",
               (unsigned long long)sparseClones, (unsigned long long)sparseTextPrepares,
               emptyInput.preparedTextLayout != nil, tinyInput.preparedTextLayout == nil,
               rejectedKeepsOld, kindClear);
        return sparseClones == 30 && sparseTextPrepares == 0 && rejectedKeepsOld && kindClear ? 0 : 6;
    }
}

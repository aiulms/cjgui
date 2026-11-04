// This test compiles the production renderer implementation into the test
// translation unit so the focus-skip predicate is exercised exactly as the
// prepare pass calls it, not a copied policy.
//
// Stage "长文本增量更新与完整样式绑定" A1: the skip exists so the focused
// input's visible body comes from the active TextKit refresh instead of a
// duplicated static raster. Only a real text input is continued by that
// refresh. A focused tab title or button has no caret/selection/marked text,
// so its static candidate must still rasterize in the same commit — otherwise
// a label or textColor change keeps rendering the old texture.
#define CJGUI_INTERNAL_TESTING 1
#import "../cjgui_internal_renderer.m"

#include <stdio.h>

static CJGuiInternalComposableSceneNode *makeNode(uint32_t kind, uint64_t nodeId, int64_t resourceId) {
    CJGuiInternalComposableSceneNode *node = [CJGuiInternalComposableSceneNode new];
    CjguiInternalRendererComposableNode nativeNode = {0};
    nativeNode.nodeKind = kind;
    nativeNode.nodeId = nodeId;
    nativeNode.resourceId = resourceId;
    node.node = nativeNode;
    return node;
}

int main(void) {
    @autoreleasepool {
        CJGuiInternalSession *ctx = [CJGuiInternalSession new];
        CJGuiInternalComposableSceneOverlay *overlay =
            [[CJGuiInternalComposableSceneOverlay alloc] initWithFrame:NSZeroRect];
        overlay.activeNodeId = 42;
        overlay.activeNodeResourceId = 7;
        ctx.composableSceneOverlay = overlay;

        // A focused tab title keeps the active identity (B1 keyboard focus),
        // but it is not a text input: no active TextKit refresh continues it.
        overlay.activeNodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_TAB_TITLE;
        if (CjguiStagedNodeIsFocusedInput(ctx, makeNode(CJGUI_INTERNAL_RENDERER_COMPOSABLE_TAB_TITLE, 42, 7))) {
            fprintf(stderr, "focused tab title must not take the active-input skip\n");
            return 1;
        }

        overlay.activeNodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_BUTTON;
        if (CjguiStagedNodeIsFocusedInput(ctx, makeNode(CJGUI_INTERNAL_RENDERER_COMPOSABLE_BUTTON, 42, 7))) {
            fprintf(stderr, "focused button must not take the active-input skip\n");
            return 2;
        }

        // Real text inputs keep the skip: the active TextKit refresh owns the
        // visible body, and retaining the previous resource is what avoids
        // rasterizing the same body twice per commit. This benefit must stay.
        overlay.activeNodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT_INPUT;
        if (!CjguiStagedNodeIsFocusedInput(ctx, makeNode(CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT_INPUT, 42, 7))) {
            fprintf(stderr, "focused text input must keep the active-input skip\n");
            return 3;
        }
        overlay.activeNodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_INTEGER_INPUT;
        if (!CjguiStagedNodeIsFocusedInput(ctx, makeNode(CJGUI_INTERNAL_RENDERER_COMPOSABLE_INTEGER_INPUT, 42, 7))) {
            fprintf(stderr, "focused integer input must keep the active-input skip\n");
            return 4;
        }
        overlay.activeNodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT;
        if (!CjguiStagedNodeIsFocusedInput(ctx, makeNode(CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT, 42, 7))) {
            fprintf(stderr, "focused multiline input must keep the active-input skip\n");
            return 5;
        }

        // Return/newline semantics: a single-line composable input has no line
        // model. Its proxy must consume Return instead of inserting a line
        // break, while multiline keeps NSTextView's own newline insertion.
        overlay.activeProjectionVersion = 1;
        overlay.activeNodeIndex = 0;
        overlay.inputProxy = [[CJGuiInternalComposableInputProxy alloc] initWithFrame:NSMakeRect(0, 0, 1, 1)];
        overlay.inputProxy.string = @"abc";
        overlay.activeNodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT_INPUT;
        CJGuiInternalComposableSceneNode *single =
            makeNode(CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT_INPUT, 42, 7);
        single.index = 0; single.value = @"abc";
        CjguiInternalRendererComposableNode singleValue = single.node;
        singleValue.projectionVersion = 1;
        single.node = singleValue;
        overlay.nodes = @[single];
        BOOL singleHandled = [overlay textView:overlay.inputProxy
                             doCommandBySelector:@selector(insertNewline:)];
        if (!singleHandled || ![overlay.inputProxy.string isEqualToString:@"abc"]) {
            fprintf(stderr, "single-line Return must be consumed without changing the proxy\n");
            return 8;
        }
        overlay.activeNodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_INTEGER_INPUT;
        CJGuiInternalComposableSceneNode *integer =
            makeNode(CJGUI_INTERNAL_RENDERER_COMPOSABLE_INTEGER_INPUT, 42, 7);
        integer.index = 0; integer.value = @"42";
        CjguiInternalRendererComposableNode integerValue = integer.node;
        integerValue.projectionVersion = 1;
        integer.node = integerValue;
        overlay.nodes = @[integer];
        if (![overlay textView:overlay.inputProxy doCommandBySelector:@selector(insertNewline:)]) {
            fprintf(stderr, "integer Return must be consumed without a line break\n");
            return 9;
        }
        overlay.activeNodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT;
        CJGuiInternalComposableSceneNode *multiline =
            makeNode(CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT, 42, 7);
        multiline.index = 0; multiline.value = @"abc";
        CjguiInternalRendererComposableNode multilineValue = multiline.node;
        multilineValue.projectionVersion = 1;
        multiline.node = multilineValue;
        overlay.nodes = @[multiline];
        if ([overlay textView:overlay.inputProxy doCommandBySelector:@selector(insertNewline:)]) {
            fprintf(stderr, "multiline Return must keep NSTextView newline insertion\n");
            return 10;
        }
        // Marked text still belongs to the system composition: Return is the
        // IME confirmation and must not be consumed by the single-line rule.
        overlay.activeNodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT_INPUT;
        overlay.nodes = @[single];
        [overlay.inputProxy setMarkedText:@"n" selectedRange:NSMakeRange(1, 0)
                        replacementRange:NSMakeRange(NSNotFound, 0)];
        if (!overlay.inputProxy.hasMarkedText ||
            [overlay textView:overlay.inputProxy doCommandBySelector:@selector(insertNewline:)]) {
            fprintf(stderr, "marked Return must stay with the system composition\n");
            return 11;
        }
        [overlay.inputProxy unmarkText];

        // Identity still gates the skip: a different text input is not active.
        if (CjguiStagedNodeIsFocusedInput(ctx, makeNode(CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT_INPUT, 43, 7))) {
            fprintf(stderr, "non-active node must not take the skip\n");
            return 6;
        }
        if (CjguiStagedNodeIsFocusedInput(ctx, makeNode(CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT_INPUT, 42, 8))) {
            fprintf(stderr, "stale resource identity must not take the skip\n");
            return 7;
        }
    }
    return 0;
}

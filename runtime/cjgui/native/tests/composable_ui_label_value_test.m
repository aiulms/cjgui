// This test compiles the production renderer implementation into the test
// translation unit so its assertions exercise the real GPU display-text
// helper rather than a copied policy.
#define CJGUI_INTERNAL_TESTING 1
#import "../cjgui_internal_renderer.m"

#include <stdio.h>

static BOOL expectDisplayText(uint32_t kind, NSString *label, NSString *value, NSString *expected) {
    CJGuiInternalComposableSceneNode *node = [CJGuiInternalComposableSceneNode new];
    CjguiInternalRendererComposableNode nativeNode = {0};
    nativeNode.nodeKind = kind;
    node.node = nativeNode;
    node.label = label;
    node.value = value;
    NSString *actual = CjguiComposableGpuTextValue(node);
    if ([actual isEqualToString:expected]) return YES;
    fprintf(stderr, "expected display text '%s', got '%s'\n", expected.UTF8String, actual.UTF8String);
    return NO;
}

int main(void) {
    @autoreleasepool {
        // Normal action declarations intentionally use the same visible label
        // and value. They must paint once, while non-action label/value pairs
        // keep their distinct text semantics.
        if (!expectDisplayText(CJGUI_INTERNAL_RENDERER_COMPOSABLE_BUTTON, @"撤销", @"撤销", @"撤销")) return 1;
        if (!expectDisplayText(CJGUI_INTERNAL_RENDERER_COMPOSABLE_BUTTON, @"选择", @"选择", @"选择")) return 2;
        if (!expectDisplayText(CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT_INPUT, @"名称", @"仓颉", @"名称 仓颉")) return 3;
        if (!expectDisplayText(CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT, @"ignored-label", @"正文", @"正文")) return 4;
    }
    return 0;
}

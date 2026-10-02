// Normal renderer projection: visible checkbox state and accessible label
// retain separate meanings. No internal testing macro or desktop input seam.
#import "../cjgui_internal_renderer.m"
#include <stdio.h>

int main(void) {
    @autoreleasepool {
        CJGuiInternalComposableSceneNode *node = [CJGuiInternalComposableSceneNode new];
        CjguiInternalRendererComposableNode value = {0};
        value.nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_BOOLEAN_INPUT;
        node.node = value;
        node.label = @"";
        node.value = @"false";
        if (![CjguiComposableGpuTextValue(node) isEqualToString:@"☐"]) {
            fprintf(stderr, "RED unchecked paints=%s expected=checkbox\n", CjguiComposableGpuTextValue(node).UTF8String);
            return 1;
        }
        node.value = @"true";
        if (![CjguiComposableGpuTextValue(node) isEqualToString:@"☑"]) return 2;
        node.label = @"选择";
        if (![CjguiComposableGpuTextValue(node) isEqualToString:@"☑ 选择"] ||
            ![node.label isEqualToString:@"选择"] || ![node.value isEqualToString:@"true"]) return 3;
        node.value = @"false";
        if (![CjguiComposableGpuTextValue(node) isEqualToString:@"☐ 选择"]) return 4;
        printf("BOOLEAN_PAINT normal=1 checked_and_unchecked=1 labeled_and_icon=1 label_value_unchanged=1\n");
    }
    return 0;
}

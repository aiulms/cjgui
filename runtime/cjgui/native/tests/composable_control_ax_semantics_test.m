// Exercises the production AX projection with accepted control facts. The
// title's paint kind must not decide its public role, and the accepted tab
// group must remain discoverable when it is not itself pointer interactive.
#define CJGUI_INTERNAL_TESTING 1
#import "../cjgui_internal_renderer.m"
#import <AppKit/AppKit.h>
#include <stdio.h>

static CJGuiInternalComposableSceneNode *control(uint32_t kind, uint64_t nodeId,
                                                  NSString *semanticId, NSString *label,
                                                  uint32_t selected) {
    CJGuiInternalComposableSceneNode *node = [CJGuiInternalComposableSceneNode new];
    CjguiInternalRendererComposableNode value = {0};
    value.nodeKind = kind;
    value.nodeId = nodeId;
    value.projectionVersion = 1;
    value.resourceId = -1;
    value.x = 0; value.y = 0; value.width = 120; value.height = 30;
    value.clipX = 0; value.clipY = 0; value.clipWidth = 120; value.clipHeight = 30;
    value.tabSelected = selected;
    value.effectGroupSubtreeCount = 1;
    value.isInteractive = kind == CJGUI_INTERNAL_RENDERER_COMPOSABLE_TAB_TITLE ? 1 : 0;
    node.node = value;
    node.semanticId = semanticId;
    node.semanticBindingKey = semanticId;
    node.label = label;
    node.value = @"";
    return node;
}

int main(void) {
    @autoreleasepool {
        CJGuiInternalComposableSceneOverlay *overlay =
            [[CJGuiInternalComposableSceneOverlay alloc] initWithFrame:NSMakeRect(0, 0, 120, 60)];
        CJGuiInternalSession *session = [CJGuiInternalSession new];
        overlay.session = session;
        CJGuiInternalComposableSceneNode *tabs = control(16, 1, @"main-tabs", @"Views", 0);
        CJGuiInternalComposableSceneNode *title = control(CJGUI_INTERNAL_RENDERER_COMPOSABLE_TAB_TITLE,
                                                            2, @"main-tabs-tab-a", @"Overview", 1);
        overlay.nodes = @[tabs, title];
        if (!CjguiComposableNodeIsAccessibilityElement(tabs)) {
            fprintf(stderr, "RED tab group absent from accepted AX elements\n");
            return 1;
        }
        CJGuiInternalComposableAccessibilityAction *tabAction =
            [[CJGuiInternalComposableAccessibilityAction alloc] initWithOverlay:overlay node:title];
        if (![[tabAction accessibilityRole] isEqualToString:NSAccessibilityRadioButtonRole]) {
            fprintf(stderr, "RED tab title role=%s expected=radio button\n",
                    [tabAction accessibilityRole].UTF8String);
            return 2;
        }
        if (![tabAction isAccessibilitySelected]) {
            fprintf(stderr, "RED accepted selected tab is not AX selected\n");
            return 3;
        }
        CjguiInternalRendererComposableNode tabsValue = tabs.node;
        tabsValue.effectGroupSubtreeCount = 2;
        tabs.node = tabsValue;
        overlay.nodes = @[tabs, title];
        [overlay reconcileAccessibilityActions];
        if (overlay.accessibilityRoots.count != 1 || overlay.accessibilityRoots.firstObject != overlay.accessibilityActions.firstObject ||
            [overlay.accessibilityRoots.firstObject accessibilityChildren].count != 1) {
            // The parent and child assertions below use object identity; the
            // extra count check first makes a flat list an explicit RED.
            fprintf(stderr, "RED accepted tab hierarchy is flat\n");
            return 4;
        }
        if ([overlay.accessibilityActions.lastObject accessibilityParent] != overlay.accessibilityRoots.firstObject) {
            fprintf(stderr, "RED title parent is not accepted tab group\n");
            return 5;
        }

        CJGuiInternalComposableSceneNode *a = control(CJGUI_INTERNAL_RENDERER_COMPOSABLE_BUTTON, 20, @"a", @"A", 0);
        CJGuiInternalComposableSceneNode *b = control(CJGUI_INTERNAL_RENDERER_COMPOSABLE_BUTTON, 21, @"b", @"B", 0);
        CjguiInternalRendererComposableNode av = a.node; av.isInteractive = 1; a.node = av;
        CjguiInternalRendererComposableNode bv = b.node; bv.isInteractive = 1; b.node = bv;
        overlay.nodes = @[a, b]; [overlay reconcileAccessibilityActions];
        CJGuiInternalComposableAccessibilityAction *oldA = overlay.accessibilityActions.firstObject;
        overlay.nodes = @[b, a]; [overlay reconcileAccessibilityActions];
        if (overlay.accessibilityActions.lastObject != oldA || [oldA currentNode] != a) {
            fprintf(stderr, "RED reorder replaced stable AX identity\n"); return 6;
        }
        CJGuiInternalComposableSceneNode *reboundA = control(CJGUI_INTERNAL_RENDERER_COMPOSABLE_BUTTON, 20, @"a", @"A", 0);
        av = reboundA.node; av.isInteractive = 1; reboundA.node = av;
        reboundA.semanticBindingKey = @"a/new-operation-owner";
        overlay.nodes = @[b, reboundA]; [overlay reconcileAccessibilityActions];
        if ([oldA currentNode] || overlay.accessibilityActions.lastObject == oldA || [oldA accessibilityPerformPress]) {
            fprintf(stderr, "RED retired AX action retargeted rebound owner\n"); return 7;
        }

        CJGuiInternalComposableSceneNode *outline = control(CJGUI_INTERNAL_RENDERER_COMPOSABLE_SCROLL_AREA, 30, @"tree", @"Tree", 0);
        CjguiInternalRendererComposableNode ov = outline.node; ov.semanticRole = 4; ov.effectGroupSubtreeCount = 3; outline.node = ov;
        CJGuiInternalComposableSceneNode *row = control(CJGUI_INTERNAL_RENDERER_COMPOSABLE_BUTTON, 31, @"row-1", @"Parent", 0);
        CjguiInternalRendererComposableNode rv = row.node; rv.semanticRole = 5; rv.semanticState = 2u | 4u; rv.isInteractive = 1; row.node = rv;
        row.semanticRowKey = @"parent";
        CJGuiInternalComposableSceneNode *child = control(CJGUI_INTERNAL_RENDERER_COMPOSABLE_BUTTON, 32, @"row-2", @"Child", 0);
        CjguiInternalRendererComposableNode cv = child.node; cv.semanticRole = 5; cv.semanticState = 1u | 8u; cv.semanticLevel = 1; child.node = cv;
        child.semanticRowKey = @"child"; child.semanticParentRowKey = @"parent";
        overlay.nodes = @[outline, row, child]; [overlay reconcileAccessibilityActions];
        CJGuiInternalComposableAccessibilityAction *outlineAX = overlay.accessibilityRoots.firstObject;
        CJGuiInternalComposableAccessibilityAction *rowAX = overlay.accessibilityActions[1];
        CJGuiInternalComposableAccessibilityAction *childAX = overlay.accessibilityActions[2];
        if (![outlineAX.accessibilityRole isEqualToString:NSAccessibilityOutlineRole] ||
            [rowAX accessibilityParent] != outlineAX || [childAX accessibilityParent] != rowAX ||
            ![rowAX isAccessibilityExpanded] || ![childAX isAccessibilitySelected] ||
            [childAX accessibilityDisclosureLevel] != 1 || [childAX isAccessibilityEnabled]) {
            fprintf(stderr, "RED outline hierarchy/state or disabled row incorrect\n"); return 8;
        }
        uint64_t settledNotifications = session.testComposableAccessibilityNotificationCount;
        [overlay reconcileAccessibilityActions];
        if (session.testComposableAccessibilityNotificationCount != settledNotifications) {
            fprintf(stderr, "RED equal accepted semantics repeated AX notifications before=%llu after=%llu actions=%lu\n",
                    (unsigned long long)settledNotifications,
                    (unsigned long long)session.testComposableAccessibilityNotificationCount,
                    (unsigned long)overlay.accessibilityActions.count); return 9;
        }
        CJGuiInternalComposableSceneNode *movedChild = control(CJGUI_INTERNAL_RENDERER_COMPOSABLE_BUTTON,
                                                                 32, @"row-2", @"Child", 0);
        cv = movedChild.node; cv.semanticRole = 5; cv.semanticState = 1u | 8u;
        cv.semanticLevel = 1; cv.x = 8; movedChild.node = cv;
        movedChild.semanticRowKey = @"child";
        movedChild.semanticParentRowKey = @"parent";
        overlay.nodes = @[outline, row, movedChild];
        [overlay reconcileAccessibilityActions];
        if (session.testComposableAccessibilityNotificationCount != settledNotifications + 1) {
            fprintf(stderr, "RED accepted geometry change did not issue one AX layout notification\n"); return 10;
        }
    }
    return 0;
}

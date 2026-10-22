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

        CJGuiInternalComposableSceneNode *slider = control(CJGUI_INTERNAL_RENDERER_COMPOSABLE_SLIDER,
            50, @"preview-limit", @"Preview limit", 0);
        CjguiInternalRendererComposableNode sv = slider.node;
        sv.isInteractive = 1; slider.node = sv; slider.value = @"160";
        overlay.nodes = @[slider]; [overlay reconcileAccessibilityActions];
        CJGuiInternalComposableAccessibilityAction *sliderAX = overlay.accessibilityActions.firstObject;
        if (![sliderAX.accessibilityRole isEqualToString:NSAccessibilitySliderRole] ||
            ![[sliderAX accessibilityValue] isKindOfClass:NSNumber.class] ||
            [[sliderAX accessibilityValue] longLongValue] != 160) {
            fprintf(stderr, "RED slider must expose AXSlider and an exact numeric accepted value\n"); return 11;
        }
        if (![sliderAX.accessibilityActionNames containsObject:NSAccessibilityIncrementAction] ||
            ![sliderAX.accessibilityActionNames containsObject:NSAccessibilityDecrementAction]) {
            fprintf(stderr, "RED slider increment/decrement actions absent\n"); return 12;
        }
        sv.pointerControlMinimum = 128; sv.pointerControlMaximum = 512; slider.node = sv;
        if ([[sliderAX accessibilityMinValue] longLongValue] != 128 ||
            [[sliderAX accessibilityMaxValue] longLongValue] != 512 ||
            [sliderAX accessibilityNumberOfCharacters] != 0) {
            fprintf(stderr, "RED slider range must read accepted signed facts without text selectors\n"); return 13;
        }
        session.composableNodes = [NSMutableArray arrayWithArray:@[slider]];
        session.composableSceneVersion = 1;
        session.pendingInteractions = [NSMutableArray array];
        if (![sliderAX accessibilityPerformIncrement] ||
            session.pendingInteractions.lastObject.kind != CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_NAVIGATE ||
            ![session.pendingInteractions.lastObject.formText isEqualToString:@"right"] ||
            session.pendingInteractions.lastObject.nodeId != 50 ||
            session.pendingInteractions.lastObject.projectionVersion != 1 ||
            session.pendingInteractions.lastObject.modifierFlags != 0 ||
            ![slider.value isEqualToString:@"160"]) {
            fprintf(stderr, "RED AX increment must queue existing NAVIGATE without mutating value\n"); return 14;
        }
        [sliderAX accessibilityPerformAction:NSAccessibilityDecrementAction];
        if (![session.pendingInteractions.lastObject.formText isEqualToString:@"left"] ||
            ![slider.value isEqualToString:@"160"]) {
            fprintf(stderr, "RED legacy AX decrement must share NAVIGATE and leave owner authoritative\n"); return 15;
        }
        NSUInteger queued = session.pendingInteractions.count;
        sv.isInteractive = 0; slider.node = sv;
        if (!CjguiComposableNodeIsAccessibilityElement(slider) || [sliderAX isAccessibilityEnabled] ||
            sliderAX.accessibilityActionNames.count || [sliderAX accessibilityPerformIncrement] ||
            session.pendingInteractions.count != queued) {
            fprintf(stderr, "RED disabled slider must remain readable and reject actions\n"); return 16;
        }
        sv.isInteractive = 1; sv.isReadOnly = 1; slider.node = sv;
        if ([sliderAX accessibilityPerformDecrement] || session.pendingInteractions.count != queued) {
            fprintf(stderr, "RED read-only slider accepted AX write\n"); return 17;
        }
        sv.isReadOnly = 0; sv.inputScope = 2; slider.node = sv;
        CJGuiInternalComposableSceneNode *modal = control(CJGUI_INTERNAL_RENDERER_COMPOSABLE_BUTTON,
            51, @"modal", @"Modal", 0);
        CjguiInternalRendererComposableNode mv = modal.node; mv.inputScope = 3; mv.isInteractive = 1;
        modal.node = mv; modal.index = 1;
        overlay.nodes = @[slider, modal]; session.composableNodes = [NSMutableArray arrayWithArray:overlay.nodes];
        overlay.activeNodeId = 51; overlay.activeNodeResourceId = -1;
        overlay.activeNodeKind = mv.nodeKind; overlay.activeProjectionVersion = 1; overlay.activeNodeIndex = 1;
        if ([sliderAX accessibilityPerformIncrement] || session.pendingInteractions.count != queued) {
            fprintf(stderr, "RED slider AX action escaped active input scope\n"); return 18;
        }
        CJGuiInternalComposableSceneNode *reboundSlider = control(CJGUI_INTERNAL_RENDERER_COMPOSABLE_SLIDER,
            50, @"preview-limit", @"Preview limit", 0);
        reboundSlider.node = sv; reboundSlider.semanticBindingKey = @"preview-limit/new-owner";
        reboundSlider.value = @"160";
        overlay.nodes = @[reboundSlider]; [overlay reconcileAccessibilityActions];
        if ([sliderAX currentNode] || [sliderAX accessibilityPerformDecrement] ||
            [sliderAX accessibilityValue] || [sliderAX accessibilityMinValue] ||
            session.pendingInteractions.count != queued) {
            fprintf(stderr, "RED retired slider action retargeted a new owner\n"); return 19;
        }
        CJGuiInternalComposableAccessibilityAction *liveSlider = overlay.accessibilityActions.firstObject;
        CJGuiInternalComposableSceneNode *rangedSlider = control(CJGUI_INTERNAL_RENDERER_COMPOSABLE_SLIDER,
            50, @"preview-limit", @"Preview limit", 0);
        rangedSlider.semanticBindingKey = reboundSlider.semanticBindingKey;
        sv.pointerControlMinimum = INT64_MIN; sv.pointerControlMaximum = INT64_MAX;
        rangedSlider.node = sv; rangedSlider.value = @"-9223372036854775808";
        uint64_t notices = session.testComposableAccessibilityNotificationCount;
        overlay.nodes = @[rangedSlider]; [overlay reconcileAccessibilityActions];
        if (overlay.accessibilityActions.firstObject != liveSlider ||
            [[liveSlider accessibilityMinValue] longLongValue] != INT64_MIN ||
            [[liveSlider accessibilityMaxValue] longLongValue] != INT64_MAX ||
            [[liveSlider accessibilityValue] longLongValue] != INT64_MIN ||
            session.testComposableAccessibilityNotificationCount != notices + 1) {
            fprintf(stderr, "RED accepted slider range/value update lost identity, precision or notification\n"); return 20;
        }
        fprintf(stderr, "PASS slider role numeric_range NAVIGATE disabled readonly scope retired_identity range_update\n");
        CJGuiInternalComposableSceneNode *field = control(CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT_INPUT,
            60, @"name", @"Name", 0);
        field.value = @"";
        // The common owner publishes help separately from the editable value.
        // KVC keeps this counterexample compilable before the new fact exists.
        if (![field respondsToSelector:NSSelectorFromString(@"setSemanticHelp:")]) {
            fprintf(stderr, "RED common field help has no native transport\n"); return 21;
        }
        [field setValue:@"Name is required (required)" forKey:@"semanticHelp"];
        overlay.activeNodeId = 0; overlay.nodes = @[field]; [overlay reconcileAccessibilityActions];
        CJGuiInternalComposableAccessibilityAction *fieldAX = overlay.accessibilityActions.firstObject;
        if (![[fieldAX accessibilityHelp] isEqualToString:@"Name is required (required)"] ||
            ![[fieldAX accessibilityValue] isEqualToString:@""]) {
            fprintf(stderr, "RED field help absent or overwrote business value\n"); return 22;
        }
        uint64_t helpNotices = session.testComposableAccessibilityNotificationCount;
        [overlay reconcileAccessibilityActions];
        if (session.testComposableAccessibilityNotificationCount != helpNotices) return 23;
        CJGuiInternalComposableSceneNode *helpOnly = control(CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT_INPUT,
            60, @"name", @"Name", 0);
        [helpOnly setValue:@"Different explanation" forKey:@"semanticHelp"];
        overlay.nodes = @[helpOnly]; [overlay reconcileAccessibilityActions];
        if (session.testComposableAccessibilityNotificationCount != ++helpNotices ||
            ![[fieldAX accessibilityHelp] isEqualToString:@"Different explanation"]) return 26;
        CJGuiInternalComposableSceneNode *repaired = control(CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT_INPUT,
            60, @"name", @"Name", 0);
        repaired.value = @"fixed";
        overlay.nodes = @[repaired]; [overlay reconcileAccessibilityActions];
        if (overlay.accessibilityActions.firstObject != fieldAX || [fieldAX accessibilityHelp].length ||
            ![[fieldAX accessibilityValue] isEqualToString:@"fixed"] ||
            session.testComposableAccessibilityNotificationCount != helpNotices + 1) return 24;
        overlay.nodes = @[]; [overlay reconcileAccessibilityActions];
        if ([fieldAX accessibilityHelp] || [fieldAX accessibilityValue]) return 25;
        session.rendererSessionToken = 1; session.sessionGeneration = 1;
        gCjguiSessions[0] = session; gCjguiSessionOccupied[0] = YES;
        session.composableNodes = [NSMutableArray arrayWithObject:field];
        session.stagedComposableNodes = [NSMutableArray arrayWithObject:field];
        if (cjgui_internal_renderer_set_composable_node_semantic_help(1, 0, 0, "Staged only") != 0 ||
            session.stagedComposableNodes[0] == field ||
            ![field.semanticHelp isEqualToString:@"Name is required (required)"] ||
            ![session.stagedComposableNodes[0].semanticHelp isEqualToString:@"Staged only"]) return 27;
        if (cjgui_internal_renderer_set_composable_node_semantic_metadata(1, 0, "name", "", "", "Name") != 0 ||
            session.stagedComposableNodes[0].semanticHelp.length) return 28;
        CjguiComposablePreparation *preparation = [CjguiComposablePreparation new];
        preparation.preparationId = 2; preparation.projectionVersion = 1;
        preparation.nodes = [NSMutableArray arrayWithObject:field];
        preparation.filled = [NSMutableIndexSet indexSetWithIndex:0];
        session.composablePreparation = preparation;
        if (cjgui_internal_renderer_set_composable_node_semantic_help(1, 2, 0, "Prepared only") != 0 ||
            preparation.nodes[0] == field || ![preparation.nodes[0].semanticHelp isEqualToString:@"Prepared only"] ||
            ![field.semanticHelp isEqualToString:@"Name is required (required)"]) return 29;
        session.composablePreparation = nil;
        if (cjgui_internal_renderer_set_composable_node_semantic_help(1, 2, 0, "retired") == 0) return 30;
        gCjguiSessions[0] = nil; gCjguiSessionOccupied[0] = NO;
        CjguiInternalRendererComposableNode readonly = field.node;
        readonly.isInteractive = 1; readonly.isReadOnly = 1; field.node = readonly;
        overlay.nodes = @[field]; [overlay reconcileAccessibilityActions];
        fieldAX = overlay.accessibilityActions.firstObject;
        if ([fieldAX isAccessibilitySelectorAllowed:@selector(setAccessibilityValue:)] ||
            [fieldAX isAccessibilitySelectorAllowed:@selector(accessibilityPerformIncrement)] ||
            [fieldAX isAccessibilitySelectorAllowed:@selector(accessibilityPerformPress)] ||
            ![fieldAX isAccessibilitySelectorAllowed:@selector(setAccessibilitySelectedTextRange:)]) {
            fprintf(stderr, "RED AppKit selectors advertise readonly writes or foreign actions\n"); return 31;
        }
        readonly.inputScope = 1; field.node = readonly;
        overlay.activeNodeId = field.node.nodeId; overlay.activeNodeResourceId = field.node.resourceId;
        overlay.activeNodeKind = field.node.nodeKind; overlay.activeProjectionVersion = field.node.projectionVersion;
        overlay.activeNodeIndex = field.index;
        readonly.inputScope = 2;
        CJGuiInternalComposableSceneNode *covered = control(CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT_INPUT,
            61, @"covered", @"Covered", 0); covered.node = readonly;
        readonly = covered.node; readonly.nodeId = 61; covered.node = readonly;
        overlay.nodes = @[field, covered]; [overlay reconcileAccessibilityActions];
        CJGuiInternalComposableAccessibilityAction *coveredAX = overlay.accessibilityActions.lastObject;
        if ([coveredAX isAccessibilitySelectorAllowed:@selector(setAccessibilityFocused:)] ||
            [coveredAX isAccessibilitySelectorAllowed:@selector(setAccessibilitySelectedTextRange:)]) return 32;
        fprintf(stderr, "PASS field_help separate_value accepted_clear change_only retired_identity\n");
        fprintf(stderr, "PASS help_transport staged_COW prepared_COW discard_clear obsolete_preparation\n");
        fprintf(stderr, "PASS AppKit_selectors readonly_value role_actions scope_focus_selection\n");
    }
    return 0;
}

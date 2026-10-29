// Windowless production hit/Tab selectors. This is not normal GUI acceptance:
// the eventual Rules run must prove real focus, input and owner state separately.
#define CJGUI_INTERNAL_TESTING 1
#import "../cjgui_internal_renderer.m"
#include <stdio.h>

static int failures;
#define CHECK(value, label) do { \
    BOOL ok = (value); \
    fprintf(stderr, "modal_hit_occlusion case=%s result=%s\n", label, ok ? "PASS" : "FAIL"); \
    if (!ok) failures++; \
} while (0)

static CJGuiInternalComposableSceneNode *Node(uint64_t identity, uint32_t kind,
    uint64_t scope, NSRect bounds, NSUInteger index) {
    CJGuiInternalComposableSceneNode *node = [CJGuiInternalComposableSceneNode new];
    CjguiInternalRendererComposableNode raw = {0};
    raw.nodeId = identity; raw.resourceId = (int64_t)identity;
    raw.nodeKind = kind; raw.inputScope = scope; raw.projectionVersion = 1;
    raw.x = bounds.origin.x; raw.y = bounds.origin.y;
    raw.width = bounds.size.width; raw.height = bounds.size.height;
    raw.clipX = 0; raw.clipY = 0; raw.clipWidth = 300; raw.clipHeight = 200;
    raw.isInteractive = 1;
    node.node = raw; node.index = index; node.value = @"field";
    return node;
}

static void SelectForSelectorOnly(CJGuiInternalComposableSceneOverlay *overlay,
    CJGuiInternalComposableSceneNode *node) {
    overlay.activeNodeIndex = node.index; overlay.activeNodeId = node.node.nodeId;
    overlay.activeNodeResourceId = node.node.resourceId;
    overlay.activeNodeKind = node.node.nodeKind;
    overlay.activeProjectionVersion = node.node.projectionVersion;
}

int main(void) {
    @autoreleasepool {
        // Use only inherited NSView construction. No input proxy, NSWindow,
        // native session, activation or desktop responder is created.
        CJGuiInternalComposableSceneOverlay *overlay =
            [[CJGuiInternalComposableSceneOverlay alloc] initWithFrame:NSMakeRect(0, 0, 300, 200)];
        CHECK(overlay.window == nil, "fixture_has_no_window_or_desktop_focus");
        for (NSUInteger mode = 0; mode < 3; mode++) {
            uint32_t lowerKind = mode == 1 ? CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT_INPUT :
                CJGUI_INTERNAL_RENDERER_COMPOSABLE_BUTTON;
            uint64_t lowerScope = mode == 2 ? 77 : 0;
            CJGuiInternalComposableSceneNode *scroll = Node(100,
                CJGUI_INTERNAL_RENDERER_COMPOSABLE_SCROLL_AREA, 0, NSMakeRect(0, 0, 300, 200), 0);
            CJGuiInternalComposableSceneNode *lower = Node(101, lowerKind, lowerScope,
                NSMakeRect(50, 50, 30, 16), 1);
            CJGuiInternalComposableSceneNode *shield = Node(300,
                CJGUI_INTERNAL_RENDERER_COMPOSABLE_LAYER_BACKDROP, 77, NSMakeRect(0, 0, 300, 200), 2);
            CJGuiInternalComposableSceneNode *field = Node(201,
                CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT_INPUT, 77, NSMakeRect(30, 40, 200, 48), 3);
            CJGuiInternalComposableSceneNode *action = Node(202,
                CJGUI_INTERNAL_RENDERER_COMPOSABLE_BUTTON, 77, NSMakeRect(180, 130, 70, 30), 4);
            overlay.nodes = @[scroll, lower, shield, field, action];
            CJGuiInternalComposableSceneNode *hit = [overlay nodeAtPoint:NSMakePoint(60, 60)];
            CHECK(hit == field, mode == 0 ? "modal_field_shields_contained_lower_button" :
                mode == 1 ? "modal_field_shields_contained_lower_editor" :
                "backdrop_is_barrier_even_with_equal_scope_codes");
            if (mode == 0) {
                SelectForSelectorOnly(overlay, hit);
                CJGuiInternalComposableSceneNode *forward = [overlay nextFocusableNodeBackwards:NO];
                CJGuiInternalComposableSceneNode *backward = [overlay nextFocusableNodeBackwards:YES];
                CHECK(forward == action, "tab_after_actual_hit_stays_in_modal");
                CHECK(backward == action, "shift_tab_after_actual_hit_stays_in_modal");
                SelectForSelectorOnly(overlay, action);
                CHECK([overlay nextFocusableNodeBackwards:NO] == field,
                    "tab_wrap_never_chooses_background");
            }
            CHECK([overlay nodeAtPoint:NSMakePoint(280, 100)] == shield,
                "modal_empty_space_is_shield_not_background");
        }
        // Retain the existing inner-node rule within an ordinary container.
        CJGuiInternalComposableSceneNode *inner = Node(401,
            CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT_INPUT, 0, NSMakeRect(50, 50, 90, 20), 0);
        CJGuiInternalComposableSceneNode *outer = Node(400,
            CJGUI_INTERNAL_RENDERER_COMPOSABLE_SCROLL_AREA, 0, NSMakeRect(0, 0, 300, 200), 1);
        overlay.nodes = @[inner, outer];
        CHECK([overlay nodeAtPoint:NSMakePoint(60, 60)] == inner,
            "same_container_inner_text_preference_preserved");
        CHECK(overlay.window == nil, "selector_checks_never_create_window");
    }
    return failures ? 1 : 0;
}

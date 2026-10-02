// Cross-language ABI sentinel probe shim (host-side harness).
//
// Compiled by scripts/run_node_abi_sentinel_cjpm.py against the REAL H snapshot
// header (snapshot/cjgui_internal_renderer.h) into a small shared library. The
// Cangjie side fills CjguiInternalRendererComposableNode/CjguiInternalRendererEvent
// with distinct sentinel values and reads them back through these functions, so a
// mirror drift anywhere in the probed field groups fails the focused Cangjie test.
//
// This file is a test fixture only: it is never compiled into any HAP.

#include <stddef.h>
#include <stdint.h>

#include "cjgui_internal_renderer.h"

size_t cjgui_node_probe_sizeof(void)
{
    return sizeof(CjguiInternalRendererComposableNode);
}

void cjgui_node_probe_copy(const CjguiInternalRendererComposableNode *in,
                           CjguiInternalRendererComposableNode *out)
{
    *out = *in;
}

uint64_t cjgui_node_probe_u64(const CjguiInternalRendererComposableNode *n, int32_t index)
{
    switch (index) {
        case 0: return n->nodeId;
        case 1: return n->projectionVersion;
        case 2: return (uint64_t)n->resourceId;
        case 3: return (uint64_t)n->x;
        case 4: return (uint64_t)n->y;
        case 5: return (uint64_t)n->width;
        case 6: return (uint64_t)n->height;
        case 7: return (uint64_t)n->nodeKind;
        case 8: return (uint64_t)n->isInteractive;
        case 9: return (uint64_t)n->isReadOnly;
        case 10: return n->inputScope;
        case 11: return n->tabGroupId;
        case 12: return (uint64_t)n->tabSelected;
        case 13: return (uint64_t)n->semanticRole;
        case 14: return (uint64_t)n->semanticState;
        case 15: return (uint64_t)n->semanticLevel;
        case 16: return (uint64_t)n->semanticIncarnation;
        case 17: return (uint64_t)n->shadowPresent;
        case 18: return (uint64_t)n->gradientPresent;
        case 19: return (uint64_t)n->gradientStopCount;
        case 20: return (uint64_t)n->effectGroupPresent;
        case 21: return (uint64_t)n->effectGroupSubtreeCount;
        case 22: return (uint64_t)n->effectGroupBlendMode;
        case 23: return (uint64_t)n->effectMaskPresent;
        case 24: return (uint64_t)n->effectMaskStopCount;
        case 25: return (uint64_t)n->effectBackdropBlurRadiusPoints;
        case 26: return (uint64_t)n->effectBackdropBlurFallback;
        case 27: return (uint64_t)n->wheelScrollable;
        case 28: return n->acceptedBindingEpoch;
        default: return 0xDEADDEADDEADDEADULL;
    }
}

double cjgui_node_probe_f64(const CjguiInternalRendererComposableNode *n, int32_t index)
{
    switch (index) {
        case 0: return n->fontSize;
        case 1: return n->fillAlpha;
        case 2: return n->textAlpha;
        case 3: return n->cornerRadius;
        case 4: return n->clip0CornerRadius;
        case 5: return n->shadowOffsetX;
        case 6: return n->shadowOffsetY;
        case 7: return n->shadowBlurRadius;
        case 8: return n->shadowSpread;
        case 9: return n->shadowAlpha;
        case 10: return n->gradientStartX;
        case 11: return n->gradientEndY;
        case 12: return n->gradientStop3Alpha;
        case 13: return n->effectGroupOpacity;
        case 14: return n->effectMaskStartX;
        case 15: return n->effectMaskEndY;
        case 16: return n->effectMaskStop3Alpha;
        default: return -424242.0;
    }
}

size_t cjgui_event_probe_sizeof(void)
{
    return sizeof(CjguiInternalRendererEvent);
}

uint64_t cjgui_event_probe_u64(const CjguiInternalRendererEvent *e, int32_t index)
{
    switch (index) {
        case 0: return e->kind;
        case 1: return e->recordIndex;
        case 2: return e->nodeId;
        case 3: return e->projectionVersion;
        case 4: return (uint64_t)e->resourceId;
        case 5: return (uint64_t)e->nodeKind;
        case 6: return (uint64_t)e->pointerX;
        case 7: return (uint64_t)e->pointerY;
        case 8: return e->gestureAppInstance;
        case 9: return e->gestureComponentInstance;
        case 10: return e->gestureSurfaceGeneration;
        case 11: return (uint64_t)e->gesturePointerId;
        case 12: return e->gestureEpoch;
        case 13: return e->acceptedBindingEpoch;
        default: return 0xDEADDEADDEADDEADULL;
    }
}

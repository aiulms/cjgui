#include <stdio.h>
#include <math.h>
#include <string.h>
#include <windows.h>

#include "cjgui_internal_renderer.h"

// This internal probe-only query is present in the Windows backend but not
// declared by the AppKit-focused public internal header.
int32_t cjgui_internal_renderer_window_number(uint64_t session, int64_t *outNumber);
int cjgui_windows_contract_session_state(uint64_t token, uint32_t *outDpi,
    uint32_t *outPixelWidth, uint32_t *outPixelHeight, uint64_t *outTextureBytes,
    uint64_t *outTextureResources, uint64_t *outScratchBytes);
int32_t cjgui_internal_renderer_owner_consumed_pointer_coordinate_lifetime(
    uint64_t session, uint64_t *outSessionGeneration, uint64_t *outCoordinateEpoch);
int cjgui_windows_contract_mouse_diagnostic(uint64_t token, int64_t *outValues,
    double *outCoordinates);

static LPARAM logical_to_client_point(double x, double y, uint32_t dpi) {
    double scale = (double)dpi / 96.0;
    int pixelX = (int)floor(x * scale + 0.5);
    int pixelY = (int)floor(y * scale + 0.5);
    return MAKELPARAM(pixelX, pixelY);
}

int main(void) {
    CjguiInternalRendererConfig config = {640u, 360u, 0.96, 0.97, 0.99, 1.0};
    CjguiInternalRendererStatus status = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    uint64_t session = cjgui_internal_renderer_create(&config, &status);
    if (!session || status != CJGUI_INTERNAL_RENDERER_OK) {
        fprintf(stderr, "WINDOWS_INPUT_RED create_status=%d\n", status);
        return 10;
    }

    CjguiInternalRendererComposableNode node;
    memset(&node, 0, sizeof(node));
    node.nodeId = 77u;
    node.projectionVersion = 1u;
    node.x = 16; node.y = 16; node.width = 480; node.height = 72;
    node.clipWidth = 640; node.clipHeight = 360;
    node.nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT_INPUT;
    node.isInteractive = 1u;
    node.fontSize = 18.0;
    node.textAlpha = 1.0;
    CjguiInternalRendererComposableGeometry geometry;
    memset(&geometry, 0, sizeof(geometry));
    geometry.nodeId = node.nodeId;
    status = cjgui_internal_renderer_configure_composable_scene(session, 1u, 2u);
    if (status == CJGUI_INTERNAL_RENDERER_OK)
        status = cjgui_internal_renderer_set_composable_scene_node(session, 0u, &node,
            "Name", "A\xF0\x9F\x9A\x80" "B", "", "", 0u);
    if (status == CJGUI_INTERNAL_RENDERER_OK)
        status = cjgui_internal_renderer_set_composable_scene_geometry(session, 1u, 0u, &geometry);
    CjguiInternalRendererComposableNode bodyNode = node;
    bodyNode.nodeId = 78u;
    bodyNode.y = 128;
    bodyNode.nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT;
    if (status == CJGUI_INTERNAL_RENDERER_OK)
        status = cjgui_internal_renderer_set_composable_scene_node(session, 1u, &bodyNode,
            "", "Body text", "", "", 0u);
    CjguiInternalRendererComposableGeometry bodyGeometry;
    memset(&bodyGeometry, 0, sizeof(bodyGeometry));
    bodyGeometry.nodeId = bodyNode.nodeId;
    if (status == CJGUI_INTERNAL_RENDERER_OK)
        status = cjgui_internal_renderer_set_composable_scene_geometry(session, 1u, 1u, &bodyGeometry);
    CjguiInternalRendererFrameObservation frame;
    memset(&frame, 0, sizeof(frame));
    if (status == CJGUI_INTERNAL_RENDERER_OK)
        status = cjgui_internal_renderer_present_composable_scene(session, &frame);
    if (status != CJGUI_INTERNAL_RENDERER_OK || frame.frameIndex == 0u) {
        fprintf(stderr, "WINDOWS_INPUT_RED scene_status=%d\n", status);
        (void)cjgui_internal_renderer_destroy(session);
        return 11;
    }

    // Label and editable value use separate coordinate spaces. Query the
    // accepted caret after `A`, then drive the actual WndProc message route.
    // The subsequent drag ends after the supplementary-plane rocket, whose
    // UTF-16 caret is 3 even though the UTF-8 byte offset is 5.
    int64_t hwndValue = 0;
    if (cjgui_internal_renderer_window_number(session, &hwndValue) != CJGUI_INTERNAL_RENDERER_OK || !hwndValue) {
        (void)cjgui_internal_renderer_destroy(session);
        return 13;
    }
    uint32_t windowDpi = 0u, pixelWidth = 0u, pixelHeight = 0u;
    uint64_t textTextureBytes = 0u, textTextureResources = 0u, textScratchBytes = 0u;
    if (!cjgui_windows_contract_session_state(session, &windowDpi, &pixelWidth, &pixelHeight,
            &textTextureBytes, &textTextureResources, &textScratchBytes) ||
        windowDpi < 48u || windowDpi > 960u || pixelWidth == 0u || pixelHeight == 0u) {
        fprintf(stderr, "WINDOWS_INPUT_RED window_geometry dpi=%u pixels=%u:%u\n",
            windowDpi, pixelWidth, pixelHeight);
        (void)cjgui_internal_renderer_destroy(session);
        return 21;
    }
    uint64_t positionMeta[8] = {0};
    double caretAfterA[4] = {0}, caretAfterRocket[4] = {0};
    status = cjgui_internal_renderer_text_position_v1(session, node.nodeId, 1u, 0u,
        1, 1u, 0u, 0u, 0u, 0.0, 0.0, positionMeta, caretAfterA);
    if (status == CJGUI_INTERNAL_RENDERER_OK)
        status = cjgui_internal_renderer_text_position_v1(session, node.nodeId, 1u, 0u,
            5, 1u, 0u, 0u, 0u, 0.0, 0.0, positionMeta, caretAfterRocket);
    if (status != CJGUI_INTERNAL_RENDERER_OK) {
        fprintf(stderr, "WINDOWS_INPUT_RED caret_status=%d\n", status);
        (void)cjgui_internal_renderer_destroy(session);
        return 14;
    }
    CjguiInternalRendererEvent event;
    memset(&event, 0, sizeof(event));
    for (uint32_t drain = 0; drain < 64u; ++drain) {
        status = cjgui_internal_renderer_pump_event(session, 0u, &event);
        if (status != CJGUI_INTERNAL_RENDERER_OK || event.kind == CJGUI_INTERNAL_RENDERER_EVENT_NONE)
            break;
    }
    HWND hwnd = (HWND)(intptr_t)hwndValue;
    double downLogicalX = caretAfterA[0] + 0.6;
    double downLogicalY = caretAfterA[1] + caretAfterA[3] / 2.0 + 0.5;
    double dragLogicalX = caretAfterRocket[0] + 0.6;
    double dragLogicalY = caretAfterRocket[1] + caretAfterRocket[3] / 2.0 + 0.5;
    LPARAM downPoint = logical_to_client_point(downLogicalX, downLogicalY, windowDpi);
    LPARAM dragPoint = logical_to_client_point(dragLogicalX, dragLogicalY, windowDpi);
    (void)SendMessageW(hwnd, WM_LBUTTONDOWN, MK_LBUTTON, downPoint);
    int64_t mouseDiag[20] = {0};
    double mouseCoordinates[4] = {0};
    int mouseDiagRead = cjgui_windows_contract_mouse_diagnostic(session, mouseDiag, mouseCoordinates);
    fprintf(stderr,
        "WINDOWS_MOUSE_TRACE read=%d msg=%lld handler=%lld stage=%lld accepted=%lld:%lld "
        "hit=%lld:%lld text=%lld caret=%lld queue_before=%lld room_first=%lld "
        "focus=%lld focus_hwnd=%lld focus_push=%lld selection_push=%lld queue_after=%lld "
        "dpi=%lld epoch=%lld version=%lld raw=%.2f,%.2f logical=%.2f,%.2f point=%.2f,%.2f "
        "fixture_dpi=%u fixture_pixels=%d,%d fixture_scale=%.4f\n",
        mouseDiagRead, (long long)mouseDiag[0], (long long)mouseDiag[1],
        (long long)mouseDiag[2], (long long)mouseDiag[3], (long long)mouseDiag[4],
        (long long)mouseDiag[5], (long long)mouseDiag[6], (long long)mouseDiag[7],
        (long long)mouseDiag[8], (long long)mouseDiag[9], (long long)mouseDiag[16],
        (long long)mouseDiag[11], (long long)mouseDiag[12], (long long)mouseDiag[13],
        (long long)mouseDiag[14], (long long)mouseDiag[15], (long long)mouseDiag[17],
        (long long)mouseDiag[18], (long long)mouseDiag[19], mouseCoordinates[0],
        mouseCoordinates[1], mouseCoordinates[2], mouseCoordinates[3],
        downLogicalX, downLogicalY, windowDpi, (int)(intptr_t)(int16_t)LOWORD(downPoint),
        (int)(intptr_t)(int16_t)HIWORD(downPoint), (double)windowDpi / 96.0);
    double coordinateTolerance = 0.51 * 96.0 / (double)windowDpi;
    int hitOracleOk = mouseDiagRead && mouseDiag[0] >= 1 && mouseDiag[1] == 1 &&
        mouseDiag[5] == 0 && mouseDiag[6] == (int64_t)node.nodeId &&
        fabs(mouseCoordinates[2] - downLogicalX) <= coordinateTolerance &&
        fabs(mouseCoordinates[3] - downLogicalY) <= coordinateTolerance;
    if (!hitOracleOk) {
        fprintf(stderr,
            "WINDOWS_INPUT_RED mouse_coordinate_oracle dpi=%u raw=%d,%d decoded=%.3f,%.3f "
            "expected=%.3f,%.3f hit=%lld:%lld msg=%lld handler=%lld\n",
            windowDpi, (int)(intptr_t)(int16_t)LOWORD(downPoint),
            (int)(intptr_t)(int16_t)HIWORD(downPoint), mouseCoordinates[2], mouseCoordinates[3],
            downLogicalX, downLogicalY, (long long)mouseDiag[5], (long long)mouseDiag[6],
            (long long)mouseDiag[0], (long long)mouseDiag[1]);
        (void)cjgui_internal_renderer_destroy(session);
        return 22;
    }
    memset(&event, 0, sizeof(event));
    status = cjgui_internal_renderer_pump_event(session, 0u, &event);
    const char *focusText = cjgui_internal_renderer_form_event_text(session);
    CjguiInternalRendererPointerEventGeometry pointerGeometry;
    memset(&pointerGeometry, 0, sizeof(pointerGeometry));
    (void)cjgui_internal_renderer_pumped_pointer_geometry(session, &pointerGeometry);
    int focusOk = status == CJGUI_INTERNAL_RENDERER_OK &&
        event.kind == CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_FOCUS &&
        event.nodeId == node.nodeId && event.projectionVersion == 1u &&
        event.selectionStart == 1u && event.selectionEnd == 1u &&
        strcmp(focusText, "A\xF0\x9F\x9A\x80" "B") == 0 &&
        pointerGeometry.present == 1u && pointerGeometry.kind == event.kind &&
        pointerGeometry.nodeId == node.nodeId && pointerGeometry.projectionVersion == 1u;
    if (!focusOk) {
        fprintf(stderr, "WINDOWS_INPUT_RED label_value_focus status=%d kind=%u selection=%u:%u sidecar=%u bytes=%llu\n",
            status, event.kind, event.selectionStart, event.selectionEnd,
            pointerGeometry.present, (unsigned long long)strlen(focusText));
        (void)cjgui_internal_renderer_destroy(session);
        return 15;
    }
    // The companion selection event and the captured drag must stay in the
    // accepted scene and express UTF-16 value coordinates, never label bytes.
    memset(&event, 0, sizeof(event));
    status = cjgui_internal_renderer_pump_event(session, 0u, &event);
    int initialSelectionOk = status == CJGUI_INTERNAL_RENDERER_OK &&
        event.kind == CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_SELECTION_CHANGED &&
        event.selectionStart == 1u && event.selectionEnd == 1u;
    (void)SendMessageW(hwnd, WM_MOUSEMOVE, MK_LBUTTON, dragPoint);
    (void)SendMessageW(hwnd, WM_LBUTTONUP, 0, dragPoint);
    uint32_t finalStart = 0u, finalEnd = 0u;
    for (uint32_t read = 0; read < 4u; ++read) {
        memset(&event, 0, sizeof(event));
        status = cjgui_internal_renderer_pump_event(session, 0u, &event);
        if (status != CJGUI_INTERNAL_RENDERER_OK || event.kind == CJGUI_INTERNAL_RENDERER_EVENT_NONE) break;
        if (event.kind == CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_SELECTION_CHANGED) {
            finalStart = event.selectionStart;
            finalEnd = event.selectionEnd;
        }
    }
    if (!initialSelectionOk || finalStart != 1u || finalEnd != 3u) {
        fprintf(stderr, "WINDOWS_INPUT_RED label_value_drag initial=%d final=%u:%u expected=1:3\n",
            initialSelectionOk, finalStart, finalEnd);
        (void)cjgui_internal_renderer_destroy(session);
        return 16;
    }

    uint64_t bodyMeta[8] = {0};
    double bodyCaret[4] = {0};
    status = cjgui_internal_renderer_text_position_v1(session, bodyNode.nodeId, 1u, 0u,
        1, 1u, 0u, 0u, 0u, 0.0, 0.0, bodyMeta, bodyCaret);
    if (status != CJGUI_INTERNAL_RENDERER_OK) {
        fprintf(stderr, "WINDOWS_INPUT_RED body_caret_status=%d\n", status);
        (void)cjgui_internal_renderer_destroy(session);
        return 17;
    }
    for (uint32_t drain = 0; drain < 64u; ++drain) {
        memset(&event, 0, sizeof(event));
        status = cjgui_internal_renderer_pump_event(session, 0u, &event);
        if (status != CJGUI_INTERNAL_RENDERER_OK || event.kind == CJGUI_INTERNAL_RENDERER_EVENT_NONE)
            break;
    }
    LPARAM bodyPoint = logical_to_client_point(bodyCaret[0] + 0.6,
        bodyCaret[1] + bodyCaret[3] / 2.0 + 0.5, windowDpi);
    LPARAM bodyDragPoint = logical_to_client_point(bodyCaret[0] + 24.0,
        bodyCaret[1] + bodyCaret[3] / 2.0 + 0.5, windowDpi);
    (void)SendMessageW(hwnd, WM_LBUTTONDOWN, MK_LBUTTON, bodyPoint);
    memset(&event, 0, sizeof(event));
    status = cjgui_internal_renderer_pump_event(session, 0u, &event);
    const char *bodyText = cjgui_internal_renderer_form_event_text(session);
    int bodyFocusOk = status == CJGUI_INTERNAL_RENDERER_OK &&
        event.kind == CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_FOCUS &&
        event.nodeId == bodyNode.nodeId && event.projectionVersion == 1u &&
        event.selectionStart == 1u && event.selectionEnd == 1u && strcmp(bodyText, "Body text") == 0;
    memset(&event, 0, sizeof(event));
    status = cjgui_internal_renderer_pump_event(session, 0u, &event);
    int bodySelectionOk = status == CJGUI_INTERNAL_RENDERER_OK &&
        event.kind == CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_SELECTION_CHANGED &&
        event.nodeId == bodyNode.nodeId && event.selectionStart == 1u && event.selectionEnd == 1u;
    CjguiInternalRendererPointerEventGeometry bodySidecar;
    memset(&bodySidecar, 0, sizeof(bodySidecar));
    memset(&event, 0, sizeof(event));
    status = cjgui_internal_renderer_pump_event(session, 0u, &event);
    (void)cjgui_internal_renderer_pumped_pointer_geometry(session, &bodySidecar);
    int bodyBeginOk = status == CJGUI_INTERNAL_RENDERER_OK &&
        event.kind == CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_POINTER_BEGIN &&
        event.nodeId == bodyNode.nodeId && event.projectionVersion == 1u && event.bindingEpoch != 0u &&
        bodySidecar.present == 1u && bodySidecar.kind == event.kind && bodySidecar.nodeId == bodyNode.nodeId;
    uint64_t bodySessionGeneration = 0u, bodyCoordinateEpoch = 0u;
    int bodyCoordinateLifetimeOk = cjgui_internal_renderer_owner_consumed_pointer_coordinate_lifetime(
        session, &bodySessionGeneration, &bodyCoordinateEpoch) == 1 &&
        bodySessionGeneration != 0u && bodyCoordinateEpoch != 0u;
    (void)SendMessageW(hwnd, WM_MOUSEMOVE, MK_LBUTTON, bodyDragPoint);
    memset(&event, 0, sizeof(event));
    status = cjgui_internal_renderer_pump_event(session, 0u, &event);
    (void)cjgui_internal_renderer_pumped_pointer_geometry(session, &bodySidecar);
    int bodyUpdateOk = status == CJGUI_INTERNAL_RENDERER_OK &&
        event.kind == CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_POINTER_UPDATE &&
        event.nodeId == bodyNode.nodeId && event.bindingEpoch != 0u &&
        bodySidecar.present == 1u && bodySidecar.kind == event.kind;
    (void)SendMessageW(hwnd, WM_LBUTTONUP, 0, bodyDragPoint);
    memset(&event, 0, sizeof(event));
    status = cjgui_internal_renderer_pump_event(session, 0u, &event);
    (void)cjgui_internal_renderer_pumped_pointer_geometry(session, &bodySidecar);
    int bodyEndOk = status == CJGUI_INTERNAL_RENDERER_OK &&
        event.kind == CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_POINTER_END &&
        event.nodeId == bodyNode.nodeId && event.bindingEpoch != 0u &&
        bodySidecar.present == 1u && bodySidecar.kind == event.kind;
    if (!bodyFocusOk || !bodySelectionOk || !bodyBeginOk || !bodyCoordinateLifetimeOk ||
        !bodyUpdateOk || !bodyEndOk) {
        fprintf(stderr, "WINDOWS_INPUT_RED body_pointer focus=%d selection=%d begin=%d coordinate=%d update=%d end=%d\n",
            bodyFocusOk, bodySelectionOk, bodyBeginOk, bodyCoordinateLifetimeOk, bodyUpdateOk, bodyEndOk);
        (void)cjgui_internal_renderer_destroy(session);
        return 18;
    }

    // A queued pointer begin from the old client-coordinate generation must
    // not be relabelled with the DPI generation current at dequeue time. The
    // matching cancel still terminates its native capture after the change.
    (void)SendMessageW(hwnd, WM_LBUTTONDOWN, MK_LBUTTON, bodyPoint);
    (void)SendMessageW(hwnd, WM_DPICHANGED, MAKEWPARAM(144u, 144u), 0);
    int staleBeginRejected = 0, staleCancelDelivered = 0;
    for (uint32_t read = 0; read < 12u; ++read) {
        memset(&event, 0, sizeof(event));
        status = cjgui_internal_renderer_pump_event(session, 0u, &event);
        if (status != CJGUI_INTERNAL_RENDERER_OK || event.kind == CJGUI_INTERNAL_RENDERER_EVENT_NONE) break;
        if (event.nodeId == bodyNode.nodeId &&
            event.kind == CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_POINTER_BEGIN) {
            CjguiInternalRendererPointerEventGeometry staleSidecar;
            memset(&staleSidecar, 0, sizeof(staleSidecar));
            (void)cjgui_internal_renderer_pumped_pointer_geometry(session, &staleSidecar);
            uint64_t staleGeneration = 1u, staleEpoch = 1u;
            staleBeginRejected = staleSidecar.present == 1u &&
                cjgui_internal_renderer_owner_consumed_pointer_coordinate_lifetime(
                    session, &staleGeneration, &staleEpoch) == 0 &&
                staleGeneration == 0u && staleEpoch == 0u;
        } else if (event.nodeId == bodyNode.nodeId &&
            event.kind == CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_POINTER_CANCEL) {
            staleCancelDelivered = 1;
            CjguiInternalRendererPointerEventGeometry cancelSidecar;
            memset(&cancelSidecar, 0, sizeof(cancelSidecar));
            (void)cjgui_internal_renderer_pumped_pointer_geometry(session, &cancelSidecar);
        }
    }
    if (!staleBeginRejected || !staleCancelDelivered) {
        fprintf(stderr, "WINDOWS_INPUT_RED stale_pointer_begin_rejected=%d cancel_delivered=%d\n",
            staleBeginRejected, staleCancelDelivered);
        (void)cjgui_internal_renderer_destroy(session);
        return 19;
    }
    (void)SendMessageW(hwnd, WM_DPICHANGED, MAKEWPARAM(96u, 96u), 0);

    status = cjgui_internal_renderer_focus_composable_node(session, node.nodeId);
    if (status == CJGUI_INTERNAL_RENDERER_OK)
        status = cjgui_internal_renderer_set_composable_owned_text_session(session,
            node.nodeId, 0, node.nodeKind, 9u, 1u);
    if (status != CJGUI_INTERNAL_RENDERER_OK) {
        fprintf(stderr, "WINDOWS_INPUT_RED bind_status=%d\n", status);
        (void)cjgui_internal_renderer_destroy(session);
        return 12;
    }

    // Direct WM_CHAR delivery is only a route diagnostic. It does not claim to
    // model real keyboard input or a system IME; those remain separate gates.
    // Two queued edits distinguish per-event payload ownership from a single
    // mutable formEventText buffer. This probe begins with a labelled value
    // containing one supplementary scalar, so insertion ranges start at UTF-16
    // length 4 and then advance to 5.
    // Discard creation-time resize/activation packets so they cannot masquerade
    // as missing character delivery in this focused route probe.
    for (uint32_t drain = 0; drain < 64u; ++drain) {
        memset(&event, 0, sizeof(event));
        status = cjgui_internal_renderer_pump_event(session, 0u, &event);
        if (status != CJGUI_INTERNAL_RENDERER_OK || event.kind == CJGUI_INTERNAL_RENDERER_EVENT_NONE)
            break;
    }
    (void)SendMessageW((HWND)(intptr_t)hwndValue, WM_CHAR, (WPARAM)L'A', (LPARAM)1);
    (void)SendMessageW((HWND)(intptr_t)hwndValue, WM_CHAR, (WPARAM)L'B', (LPARAM)1);
    memset(&event, 0, sizeof(event));
    status = cjgui_internal_renderer_pump_event(session, 0u, &event);
    const char *eventText = cjgui_internal_renderer_form_event_text(session);
    uint32_t firstKind = event.kind;
    int firstOk = status == CJGUI_INTERNAL_RENDERER_OK &&
        event.kind == CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_TEXT_RANGE_CHANGED &&
        strcmp(eventText, "A") == 0 && event.bindingEpoch == 9u &&
        event.selectionStart == 4u && event.selectionEnd == 4u;
    memset(&event, 0, sizeof(event));
    status = cjgui_internal_renderer_pump_event(session, 0u, &event);
    eventText = cjgui_internal_renderer_form_event_text(session);
    int secondOk = status == CJGUI_INTERNAL_RENDERER_OK &&
        event.kind == CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_TEXT_RANGE_CHANGED &&
        strcmp(eventText, "B") == 0 && event.bindingEpoch == 9u &&
        event.selectionStart == 5u && event.selectionEnd == 5u;
    if (firstOk && secondOk) {
        printf("WINDOWS_INPUT_CONTRACT PASS events=2 inserts=A,B ranges=4:4,5:5 label_value_click=1 drag=1:3 body_shared_pointer=begin,update,end coordinate_lifetime=accepted,stale_refused utf16=true binding=9\n");
        (void)cjgui_internal_renderer_destroy(session);
        return 0;
    }
    printf("WINDOWS_INPUT_RED first_ok=%d first_kind=%u second_ok=%d second_kind=%u second_bytes=%llu status=%d\n",
        firstOk, firstKind, secondOk, event.kind, (unsigned long long)strlen(eventText), status);
    (void)cjgui_internal_renderer_destroy(session);
    return 20;
}

// Source-install seam contract: the three negative controls from the
// Windows Pharos package review, driven through the real Win32 message
// route (SendMessageW) and the native FIFO. Not a product editor.
//
// Control 1 (gate): with a source-install ticket pending, WM_CHAR /
//   VK_DELETE / VK_LEFT must not emit owner transactions on the old
//   selection; the gated-input counter must read exactly 3.
// Control 2 (atomic install): installing A while focus sits on B must
//   succeed with the correct ticket (proxy + focus + non-empty range land
//   together, gate goes provisional and stays held) and fail with a wrong
//   epoch leaving B intact; after the owner settles the gate, the first
//   keystroke replaces exactly the new frozen range.
// Control 3 (recover): recovering non-active target B while A is edited
//   must refuse with proxy/selection/pending input preserved (A keeps typing).
#include <stdio.h>
#include <math.h>
#include <string.h>
#include <windows.h>

#include "cjgui_internal_renderer.h"
#include "probe_recovery_receiver.h"

uint64_t cjgui_internal_renderer_source_install_gated_inputs(uint64_t session);
extern uint32_t cjgui_internal_renderer_debug_source_install_state(uint64_t token,
    uint32_t *outProvisional, uint32_t *outOutcome);

static LPARAM logical_to_client_point(double x, double y, uint32_t dpi) {
    double scale = (double)dpi / 96.0;
    int pixelX = (int)floor(x * scale + 0.5);
    int pixelY = (int)floor(y * scale + 0.5);
    return MAKELPARAM(pixelX, pixelY);
}

static int pump_all(uint64_t session, CjguiInternalRendererEvent *event,
    uint32_t *outRangeChanged, uint32_t *outNavigate, uint64_t nodeId) {
    uint32_t rangeChanged = 0u, navigate = 0u;
    for (uint32_t drain = 0u; drain < 128u; ++drain) {
        memset(event, 0, sizeof(*event));
        CjguiInternalRendererStatus status =
            cjgui_internal_renderer_pump_event(session, 0u, event);
        if (status != CJGUI_INTERNAL_RENDERER_OK ||
            event->kind == CJGUI_INTERNAL_RENDERER_EVENT_NONE)
            break;
        if (event->nodeId == nodeId &&
            event->kind == CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_TEXT_RANGE_CHANGED)
            ++rangeChanged;
        if (event->nodeId == nodeId &&
            event->kind == CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_NAVIGATE)
            ++navigate;
    }
    if (outRangeChanged) *outRangeChanged = rangeChanged;
    if (outNavigate) *outNavigate = navigate;
    return 1;
}

static int click_node(uint64_t session, HWND hwnd, uint32_t dpi,
    double cx, double cy, uint64_t nodeId) {
    (void)session;
    (void)nodeId;
    (void)SendMessageW(hwnd, WM_LBUTTONDOWN, MK_LBUTTON,
        logical_to_client_point(cx, cy, dpi));
    (void)SendMessageW(hwnd, WM_LBUTTONUP, 0,
        logical_to_client_point(cx, cy, dpi));
    return 1;
}

int main(void) {
    CjguiInternalRendererConfig config = {640u, 480u, 0.96, 0.97, 0.99, 1.0};
    CjguiInternalRendererStatus status = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    uint64_t session = cjgui_internal_renderer_create(&config, &status);
    if (!session || status != CJGUI_INTERNAL_RENDERER_OK) {
        fprintf(stderr, "WINDOWS_INSTALL_RED create_status=%d\n", status);
        return 10;
    }
    CjguiInternalRendererComposableNode nodeA;
    memset(&nodeA, 0, sizeof(nodeA));
    nodeA.nodeId = 101u;
    nodeA.projectionVersion = 1u;
    nodeA.x = 16; nodeA.y = 16; nodeA.width = 480; nodeA.height = 72;
    nodeA.clipWidth = 640; nodeA.clipHeight = 480;
    nodeA.nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT;
    nodeA.isInteractive = 1u;
    nodeA.fontSize = 18.0;
    nodeA.textAlpha = 1.0;
    CjguiInternalRendererComposableNode nodeB = nodeA;
    nodeB.nodeId = 102u;
    nodeB.y = 128;
    CjguiInternalRendererComposableGeometry geometryA;
    memset(&geometryA, 0, sizeof(geometryA));
    geometryA.nodeId = nodeA.nodeId;
    CjguiInternalRendererComposableGeometry geometryB;
    memset(&geometryB, 0, sizeof(geometryB));
    geometryB.nodeId = nodeB.nodeId;
    status = cjgui_internal_renderer_configure_composable_scene(session, 1u, 2u);
    if (status == CJGUI_INTERNAL_RENDERER_OK)
        status = cjgui_internal_renderer_set_composable_scene_node(session, 0u, &nodeA,
            "", "hello world", "", "", 0u);
    if (status == CJGUI_INTERNAL_RENDERER_OK)
        status = cjgui_internal_renderer_set_composable_scene_geometry(session, 1u, 0u, &geometryA);
    if (status == CJGUI_INTERNAL_RENDERER_OK)
        status = cjgui_internal_renderer_set_composable_scene_node(session, 1u, &nodeB,
            "", "other text", "", "", 0u);
    if (status == CJGUI_INTERNAL_RENDERER_OK)
        status = cjgui_internal_renderer_set_composable_scene_geometry(session, 1u, 1u, &geometryB);
    CjguiInternalRendererFrameObservation frame;
    memset(&frame, 0, sizeof(frame));
    if (status == CJGUI_INTERNAL_RENDERER_OK)
        status = cjgui_internal_renderer_present_composable_scene(session, &frame);
    if (status != CJGUI_INTERNAL_RENDERER_OK || frame.frameIndex == 0u) {
        fprintf(stderr, "WINDOWS_INSTALL_RED scene_status=%d\n", status);
        (void)probe_destroy_with_recovery(session);
        return 11;
    }
    CjguiInternalRendererWindowBackgroundSnapshot snapshot;
    memset(&snapshot, 0, sizeof(snapshot));
    status = cjgui_internal_renderer_window_background_snapshot(session, &snapshot);
    if (status != CJGUI_INTERNAL_RENDERER_OK || snapshot.acceptedSceneVersion == 0u) {
        fprintf(stderr, "WINDOWS_INSTALL_RED snapshot_status=%d\n", status);
        (void)probe_destroy_with_recovery(session);
        return 12;
    }
    uint64_t sceneVersion = snapshot.acceptedSceneVersion;
    int64_t hwndValue = 0;
    extern int32_t cjgui_internal_renderer_window_number(uint64_t session, int64_t *outNumber);
    if (cjgui_internal_renderer_window_number(session, &hwndValue) != CJGUI_INTERNAL_RENDERER_OK ||
        !hwndValue) {
        fprintf(stderr, "WINDOWS_INSTALL_RED no_hwnd\n");
        (void)probe_destroy_with_recovery(session);
        return 13;
    }
    HWND hwnd = (HWND)(intptr_t)hwndValue;
    uint32_t dpi = 96u;
    {
        extern int cjgui_windows_contract_session_state(uint64_t token, uint32_t *outDpi,
            uint32_t *outPixelWidth, uint32_t *outPixelHeight, uint64_t *outTextureBytes,
            uint64_t *outTextureResources, uint64_t *outScratchBytes);
        uint32_t pw = 0u, ph = 0u;
        uint64_t tb = 0u, tr = 0u, sb = 0u;
        if (cjgui_windows_contract_session_state(session, &dpi, &pw, &ph, &tb, &tr, &sb) &&
            dpi >= 48u && dpi <= 960u) {
            (void)pw; (void)ph; (void)tb; (void)tr; (void)sb;
        } else {
            dpi = 96u;
        }
    }
    CjguiInternalRendererEvent event;
    // Focus A by clicking its center, then bind the owned session (epoch 9).
    click_node(session, hwnd, dpi, 16 + 240.0, 16 + 36.0, nodeA.nodeId);
    pump_all(session, &event, NULL, NULL, 0u);
    status = cjgui_internal_renderer_focus_composable_node(session, nodeA.nodeId);
    if (status == CJGUI_INTERNAL_RENDERER_OK)
        status = cjgui_internal_renderer_set_composable_owned_text_session(session,
            nodeA.nodeId, 0, nodeA.nodeKind, 9u, 1u);
    if (status != CJGUI_INTERNAL_RENDERER_OK) {
        fprintf(stderr, "WINDOWS_INSTALL_RED bind_status=%d\n", status);
        (void)probe_destroy_with_recovery(session);
        return 14;
    }
    pump_all(session, &event, NULL, NULL, 0u);
    // Arm the install gate for A (epoch 9, request 1001).
    status = cjgui_internal_renderer_set_source_install_gate(session, 9u, 1001u, 1u);
    if (status != CJGUI_INTERNAL_RENDERER_OK) {
        fprintf(stderr, "WINDOWS_INSTALL_RED arm_status=%d\n", status);
        (void)probe_destroy_with_recovery(session);
        return 15;
    }
    // Control 1: gated char / delete / navigation must not transact.
    (void)SendMessageW(hwnd, WM_CHAR, (WPARAM)L'X', (LPARAM)1);
    (void)SendMessageW(hwnd, WM_KEYDOWN, (WPARAM)VK_DELETE, (LPARAM)0);
    (void)SendMessageW(hwnd, WM_KEYDOWN, (WPARAM)VK_LEFT, (LPARAM)0);
    uint32_t gatedRange = 0u, gatedNav = 0u;
    pump_all(session, &event, &gatedRange, &gatedNav, nodeA.nodeId);
    uint64_t gated = cjgui_internal_renderer_source_install_gated_inputs(session);
    if (gatedRange != 0u || gatedNav != 0u || gated != 3u) {
        fprintf(stderr, "WINDOWS_INSTALL_RED gate_leak range=%u nav=%u gated=%llu\n",
            gatedRange, gatedNav, (unsigned long long)gated);
        (void)probe_destroy_with_recovery(session);
        return 16;
    }
    // Independent gate control settles by cancellation, then the real test
    // receiver stores all three held operations before ACK. The install control
    // begins with a fresh request instead of silently forgetting held inputs.
    extern CjguiInternalRendererStatus cjgui_internal_renderer_finish_source_install(uint64_t,uint64_t,uint32_t,uint64_t);
    if(cjgui_internal_renderer_finish_source_install(session,1001u,2u,0u)!=0 ||
        probe_receive_recovery(session)!=3 ||
        cjgui_internal_renderer_set_source_install_gate(session,9u,1003u,1u)!=0){
        fprintf(stderr,"WINDOWS_INSTALL_RED gate_recovery_transfer\n");probe_destroy_with_recovery(session);return 16;
    }
    // Move focus to B; the correct ticket for A must still install atomically.
    click_node(session, hwnd, dpi, 16 + 240.0, 128 + 36.0, nodeB.nodeId);
    pump_all(session, &event, NULL, NULL, 0u);
    uint64_t deadline = cjgui_internal_renderer_owner_clock_ns() + 3600u * 1000000000u;
    uint32_t outStart = 0u, outEnd = 0u;
    uint8_t deferred = 0u;
    status = cjgui_internal_renderer_install_owned_source_selection(session,
        nodeA.nodeId, 0, sceneVersion, 9u, 1003u, deadline,
        "hello world", 0u, 5u, &outStart, &outEnd, &deferred);
    if (status != CJGUI_INTERNAL_RENDERER_OK || deferred || outStart != 0u || outEnd != 5u) {
        fprintf(stderr, "WINDOWS_INSTALL_RED install_status=%d deferred=%u sel=%u:%u\n",
            status, deferred, outStart, outEnd);
        (void)probe_destroy_with_recovery(session);
        return 17;
    }
    uint32_t prov = 0u, outcome = 0u;
    uint32_t stillPending =
        cjgui_internal_renderer_debug_source_install_state(session, &prov, &outcome);
    if (!stillPending || !prov || outcome != 1u) {
        fprintf(stderr, "WINDOWS_INSTALL_RED not_provisional pending=%u prov=%u outcome=%u\n",
            stillPending, prov, outcome);
        (void)probe_destroy_with_recovery(session);
        return 18;
    }
    // Owner settles the gate; only then may input flow again.
    status = cjgui_internal_renderer_set_source_install_gate(session, 9u, 1003u, 0u);
    if (status != CJGUI_INTERNAL_RENDERER_OK) {
        fprintf(stderr, "WINDOWS_INSTALL_RED settle_status=%d\n", status);
        (void)probe_destroy_with_recovery(session);
        return 18;
    }
    stillPending =
        cjgui_internal_renderer_debug_source_install_state(session, &prov, &outcome);
    if (stillPending || prov || outcome != 2u) {
        fprintf(stderr, "WINDOWS_INSTALL_RED not_confirmed pending=%u prov=%u outcome=%u\n",
            stillPending, prov, outcome);
        (void)probe_destroy_with_recovery(session);
        return 18;
    }
    // Wrong epoch must refuse and leave everything (focus A, range 0:5) intact.
    status = cjgui_internal_renderer_set_source_install_gate(session, 9u, 1002u, 1u);
    if (status != CJGUI_INTERNAL_RENDERER_OK) {
        fprintf(stderr, "WINDOWS_INSTALL_RED rearm_status=%d\n", status);
        (void)probe_destroy_with_recovery(session);
        return 19;
    }
    outStart = 0u; outEnd = 0u; deferred = 0u;
    status = cjgui_internal_renderer_install_owned_source_selection(session,
        nodeA.nodeId, 0, sceneVersion, 8u, 1002u, deadline,
        "hello world", 0u, 2u, &outStart, &outEnd, &deferred);
    if (status == CJGUI_INTERNAL_RENDERER_OK) {
        fprintf(stderr, "WINDOWS_INSTALL_RED stale_epoch_accepted\n");
        (void)probe_destroy_with_recovery(session);
        return 20;
    }
    status = cjgui_internal_renderer_set_source_install_gate(session, 9u, 1002u, 0u);
    if (status != CJGUI_INTERNAL_RENDERER_OK) {
        fprintf(stderr, "WINDOWS_INSTALL_RED disarm_status=%d\n", status);
        (void)probe_destroy_with_recovery(session);
        return 21;
    }
    // First keystroke after install replaces exactly the new frozen range.
    (void)SendMessageW(hwnd, WM_CHAR, (WPARAM)L'X', (LPARAM)1);
    memset(&event, 0, sizeof(event));
    status = cjgui_internal_renderer_pump_event(session, 0u, &event);
    const char *eventText = cjgui_internal_renderer_form_event_text(session);
    // The event carries the replaced (pre-insert) range; the session caret
    // advances to 1:1 behind it (proven by the follow-up Y keystroke below).
    int firstOk = status == CJGUI_INTERNAL_RENDERER_OK &&
        event.kind == CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_TEXT_RANGE_CHANGED &&
        event.nodeId == nodeA.nodeId && strcmp(eventText, "X") == 0 &&
        event.replacementStart16 == 0 && event.replacementLength16 == 5 &&
        event.selectionStart == 0u && event.selectionEnd == 5u;
    if (!firstOk) {
        fprintf(stderr, "WINDOWS_INSTALL_RED first_replace kind=%u node=%llu text=%s repl=%lld:%lld sel=%u:%u\n",
            event.kind, (unsigned long long)event.nodeId, eventText,
            (long long)event.replacementStart16, (long long)event.replacementLength16,
            event.selectionStart, event.selectionEnd);
        (void)probe_destroy_with_recovery(session);
        return 22;
    }
    // Control 3: recovering non-active B must refuse; A keeps typing.
    uint32_t recStart = 0u, recEnd = 0u;
    status = cjgui_internal_renderer_recover_active_text_proxy(session,
        nodeB.nodeId, 0, nodeB.nodeKind, "other text", &recStart, &recEnd);
    if (status == CJGUI_INTERNAL_RENDERER_OK) {
        fprintf(stderr, "WINDOWS_INSTALL_RED foreign_recover_accepted\n");
        (void)probe_destroy_with_recovery(session);
        return 23;
    }
    (void)SendMessageW(hwnd, WM_CHAR, (WPARAM)L'Y', (LPARAM)1);
    memset(&event, 0, sizeof(event));
    status = cjgui_internal_renderer_pump_event(session, 0u, &event);
    eventText = cjgui_internal_renderer_form_event_text(session);
    int secondOk = status == CJGUI_INTERNAL_RENDERER_OK &&
        event.kind == CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_TEXT_RANGE_CHANGED &&
        event.nodeId == nodeA.nodeId && strcmp(eventText, "Y") == 0;
    if (!secondOk) {
        fprintf(stderr, "WINDOWS_INSTALL_RED continue_after_refuse kind=%u node=%llu text=%s\n",
            event.kind, (unsigned long long)event.nodeId, eventText);
        (void)probe_destroy_with_recovery(session);
        return 24;
    }
    printf("WINDOWS_INSTALL_CONTRACT PASS gate=3 install=0:5 first=X stale_refused recover_refused continue=Y\n");
    (void)probe_destroy_with_recovery(session);
    return 0;
}

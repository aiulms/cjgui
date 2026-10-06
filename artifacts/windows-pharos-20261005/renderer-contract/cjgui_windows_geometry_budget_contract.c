#include <math.h>
#include <stdio.h>
#include <string.h>
#include "cjgui_internal_renderer.h"

int cjgui_windows_contract_send_dpi_change(uint64_t, uint32_t);
int cjgui_windows_contract_session_state(uint64_t, uint32_t *, uint32_t *, uint32_t *,
    uint64_t *, uint64_t *, uint64_t *);
int cjgui_windows_contract_node_text_state(uint64_t, uint64_t, uint64_t *, uint64_t *,
    uint32_t *, uint32_t *, uint64_t *);
int cjgui_windows_contract_live_text_texture_usage(uint64_t *, uint32_t *);
int cjgui_windows_contract_set_hold_text_flights(uint64_t, uint32_t);
int cjgui_windows_contract_text_flight_state(uint64_t, uint32_t *, uint32_t *, uint64_t *);
int cjgui_windows_contract_drain_text_flights(uint64_t, uint32_t);
int cjgui_windows_contract_readback_node_text_alpha(uint64_t, uint64_t, uint64_t *);
CjguiInternalRendererStatus cjgui_internal_renderer_text_geometry_caret(uint64_t, int64_t,
    int64_t, double, uint64_t, uint32_t, double *, double *, double *, double *);
int32_t cjgui_internal_renderer_text_line_rect_count(uint64_t, uint64_t, int64_t,
    int64_t, int32_t, uint64_t);
double cjgui_internal_renderer_text_line_rect_value(uint64_t, uint64_t, int64_t,
    int64_t, int32_t, int32_t, int32_t, uint64_t);

static int fail(const char *name, long long actual, long long expected) {
    fprintf(stderr, "CJGUI_WINDOWS_GEOMETRY_BUDGET_CONTRACT FAIL %s actual=%lld expected=%lld\n",
        name, actual, expected);
    return 1;
}

static int accept_bottom_right_text(uint64_t session, uint64_t version, uint32_t expectedDpi,
    uint64_t *outLease, uint32_t *outTextureWidth, uint32_t *outTextureHeight,
    uint64_t *outTextureBytes) {
    CjguiInternalRendererViewport viewport;
    if (cjgui_internal_renderer_composable_viewport(session, &viewport) != CJGUI_INTERNAL_RENDERER_OK)
        return fail("viewport_status", -1, CJGUI_INTERNAL_RENDERER_OK);
    uint32_t dpi = 0, pixelWidth = 0, pixelHeight = 0;
    uint64_t ignoredBytes = 0, ignoredCount = 0, ignoredScratch = 0;
    if (!cjgui_windows_contract_session_state(session, &dpi, &pixelWidth, &pixelHeight,
        &ignoredBytes, &ignoredCount, &ignoredScratch)) return fail("session_state", 0, 1);
    if (dpi != expectedDpi) return fail("effective_dpi", dpi, expectedDpi);
    double scale = (double)dpi / 96.0;
    if ((uint64_t)floor((double)pixelWidth / scale) != viewport.width ||
        (uint64_t)floor((double)pixelHeight / scale) != viewport.height)
        return fail("logical_viewport", viewport.width,
            (long long)floor((double)pixelWidth / scale));

    CjguiInternalRendererStatus status = cjgui_internal_renderer_configure_composable_scene(
        session, version, 1u);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return fail("configure", status, 0);
    CjguiInternalRendererComposableNode node;
    memset(&node, 0, sizeof(node));
    node.nodeId = 77u;
    node.projectionVersion = version;
    node.x = (int64_t)viewport.width - 126;
    node.y = (int64_t)viewport.height - 42;
    node.width = 118;
    node.height = 32;
    node.clipX = 0; node.clipY = 0;
    node.clipWidth = viewport.width; node.clipHeight = viewport.height;
    node.nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT;
    node.fontSize = 16.0; node.fontWeight = 400u;
    node.textRed = 0.06; node.textGreen = 0.08; node.textBlue = 0.12; node.textAlpha = 1.0;
    node.fillRed = 0.86; node.fillGreen = 0.90; node.fillBlue = 0.96; node.fillAlpha = 1.0;
    status = cjgui_internal_renderer_set_composable_scene_node(session, 0u, &node,
        "", "Bottom right", "", "", 0u);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return fail("set_node", status, 0);
    CjguiInternalRendererComposableGeometry geometry;
    memset(&geometry, 0, sizeof(geometry));
    geometry.nodeId = node.nodeId;
    status = cjgui_internal_renderer_set_composable_scene_geometry(session, version, 0u, &geometry);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return fail("set_geometry", status, 0);
    CjguiInternalRendererFrameObservation observation;
    memset(&observation, 0, sizeof(observation));
    status = cjgui_internal_renderer_present_composable_scene(session, &observation);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return fail("present", status, 0);
    CjguiInternalRendererDiagnosticNodeGeometry accepted;
    memset(&accepted, 0, sizeof(accepted));
    status = cjgui_internal_renderer_diagnostic_node_geometry(session, 0u, &accepted);
    if (status != CJGUI_INTERNAL_RENDERER_OK || accepted.sceneVersion != version)
        return fail("accepted_identity", accepted.sceneVersion, version);
    if (accepted.outputX < 0.0 || accepted.outputY < 0.0 ||
        accepted.outputX + accepted.outputWidth > (double)viewport.width ||
        accepted.outputY + accepted.outputHeight > (double)viewport.height)
        return fail("control_inside_logical_client", 0, 1);
    double rightPx = ceil((accepted.outputX + accepted.outputWidth) * scale);
    double bottomPx = ceil((accepted.outputY + accepted.outputHeight) * scale);
    if (rightPx > pixelWidth || bottomPx > pixelHeight)
        return fail("control_inside_drawable", (long long)fmax(rightPx, bottomPx),
            (long long)fmax(pixelWidth, pixelHeight));

    uint64_t textDpi = 0, ink = 0;
    if (!cjgui_windows_contract_node_text_state(session, node.nodeId, outLease, &textDpi,
        outTextureWidth, outTextureHeight, &ink)) return fail("accepted_text_state", 0, 1);
    if (*outLease == 0u || textDpi != dpi || ink == 0u)
        return fail("accepted_layout_raster_identity", (long long)textDpi, dpi);
    if (*outTextureWidth != (uint32_t)ceil(node.width * scale) ||
        *outTextureHeight != (uint32_t)ceil(node.height * scale))
        return fail("rgba_texture_dpi_dimensions", *outTextureWidth,
            (long long)ceil(node.width * scale));
    uint64_t alphaPixels = 0;
    if (!cjgui_windows_contract_readback_node_text_alpha(session, node.nodeId, &alphaPixels) ||
        alphaPixels == 0u) return fail("actual_text_texture_alpha", alphaPixels, 1);

    double caretX = 0.0, caretY = 0.0, caretWidth = 0.0, caretHeight = 0.0;
    status = cjgui_internal_renderer_text_geometry_caret(session, 77, 1, 1.0,
        version, 1u, &caretX, &caretY, &caretWidth, &caretHeight);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return fail("accepted_caret", status, 0);
    uint32_t hitByte = UINT32_MAX, hitAffinity = UINT32_MAX;
    status = cjgui_internal_renderer_hit_test_composable_text(session, 77,
        caretX + 0.1, caretY + caretHeight / 2.0, version,
        &hitByte, &hitAffinity);
    if (status != CJGUI_INTERNAL_RENDERER_OK || hitByte != 1u)
        return fail("hit_roundtrip_to_same_layout", hitByte, 1);
    uint64_t meta[8] = {0}; double rect[4] = {0};
    status = cjgui_internal_renderer_text_position_v1(session, 77, version, 0u, 1,
        1u, 0u, 0u, 0u, 0.0, 0.0, meta, rect);
    if (status != CJGUI_INTERNAL_RENDERER_OK || meta[0] != *outLease || meta[1] == 0u || meta[2] != 1u)
        return fail("position_layout_lease", status, 0);
    if (fabs(rect[0] - caretX) > 0.75 || fabs(rect[1] - caretY) > 0.75)
        return fail("caret_and_position_same_layout", (long long)rect[0],
            (long long)caretX);
    int32_t rects = cjgui_internal_renderer_text_line_rect_count(session, 77, 0, 4, 8, version);
    if (rects <= 0) return fail("selection_rects_from_accepted_layout", rects, 1);
    double rangeX = cjgui_internal_renderer_text_line_rect_value(session, 77, 0, 4, 8, 0, 0, version);
    double rangeY = cjgui_internal_renderer_text_line_rect_value(session, 77, 0, 4, 8, 0, 1, version);
    double rangeWidth = cjgui_internal_renderer_text_line_rect_value(session, 77, 0, 4, 8, 0, 2, version);
    if (!isfinite(rangeX) || !isfinite(rangeY) || !isfinite(rangeWidth) || rangeWidth <= 0.0 ||
        rangeX < node.x || rangeX + rangeWidth > node.x + node.width || rangeY < node.y ||
        rangeY > node.y + node.height)
        return fail("selection_rect_scene_coordinates", rects, 1);
    printf("DPI_ACCEPTED dpi=%u pixels=%ux%u logical=%ux%u node_right_bottom=%.2f,%.2f text_texture=%ux%u lease=%llu alpha=%llu caret=%.2f,%.2f hit=%u selection_rects=%d\n",
        dpi, pixelWidth, pixelHeight, viewport.width, viewport.height,
        accepted.outputX + accepted.outputWidth, accepted.outputY + accepted.outputHeight,
        *outTextureWidth, *outTextureHeight, (unsigned long long)*outLease,
        (unsigned long long)alphaPixels, node.x + caretX, node.y + caretY, hitByte, rects);
    if (!cjgui_windows_contract_session_state(session, &dpi, &pixelWidth, &pixelHeight,
        outTextureBytes, &ignoredCount, &ignoredScratch)) return fail("post_present_resources", 0, 1);
    return 0;
}

int main(void) {
    CjguiInternalRendererConfig config = {640u, 420u, 0.96, 0.97, 0.99, 1.0};
    CjguiInternalRendererStatus status = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    uint64_t session = cjgui_internal_renderer_create(&config, &status);
    if (!session || status != CJGUI_INTERNAL_RENDERER_OK) return fail("create", status, 0);
    if (!cjgui_windows_contract_set_hold_text_flights(session, 1u))
        return fail("hold_gpu_text_flights", 0, 1);
    uint64_t lease96 = 0, bytes96 = 0, lease144 = 0, bytes144 = 0;
    uint32_t width96 = 0, height96 = 0, width144 = 0, height144 = 0;
    if (!cjgui_windows_contract_send_dpi_change(session, 96u)) return fail("set_100_percent", 0, 1);
    if (accept_bottom_right_text(session, 96u, 96u, &lease96, &width96, &height96, &bytes96)) return 1;
    uint32_t pendingFlights = 0u, flightLeaseRefs = 0u;
    uint64_t flightReferencedBytes = 0u;
    if (!cjgui_windows_contract_text_flight_state(session, &pendingFlights,
        &flightLeaseRefs, &flightReferencedBytes) || pendingFlights != 1u ||
        flightLeaseRefs == 0u || flightReferencedBytes == 0u)
        return fail("submitted_text_leases_retained", flightLeaseRefs, 1);
    if (!cjgui_windows_contract_send_dpi_change(session, 144u)) return fail("set_150_percent", 0, 1);
    double staleX = 0.0, staleY = 0.0, staleW = 0.0, staleH = 0.0;
    status = cjgui_internal_renderer_text_geometry_caret(session, 77, 1, 1.0,
        96u, 1u, &staleX, &staleY, &staleW, &staleH);
    if (status != CJGUI_INTERNAL_RENDERER_SCENE_STALE)
        return fail("dpi_invalidates_old_accepted_layout", status, CJGUI_INTERNAL_RENDERER_SCENE_STALE);
    if (accept_bottom_right_text(session, 97u, 144u, &lease144, &width144, &height144, &bytes144)) return 1;
    if (lease96 == lease144 || width144 <= width96 || height144 <= height96)
        return fail("dpi_invalidates_layout_and_texture", width144, width96 + 1u);

    if (!cjgui_windows_contract_send_dpi_change(session, 96u)) return fail("reset_100_percent", 0, 1);
    status = cjgui_internal_renderer_configure_composable_scene(session, 98u, 2u);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return fail("configure_budget_candidate", status, 0);
    uint32_t dpi = 0, pixelWidth = 0, pixelHeight = 0;
    uint64_t baselineBytes = 0, baselineResources = 0, scratchBytes = 0;
    if (!cjgui_windows_contract_session_state(session, &dpi, &pixelWidth, &pixelHeight,
        &baselineBytes, &baselineResources, &scratchBytes)) return fail("budget_baseline", 0, 1);
    if (dpi != 96u) return fail("budget_test_dpi", dpi, 96);
    CjguiInternalRendererComposableNode giant;
    memset(&giant, 0, sizeof(giant));
    giant.nodeId = 801u; giant.projectionVersion = 98u;
    giant.width = 8192; giant.height = 512;
    giant.clipWidth = 640; giant.clipHeight = 420;
    giant.nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT;
    giant.fontSize = 16.0; giant.fontWeight = 400u;
    giant.textRed = 0.1; giant.textGreen = 0.1; giant.textBlue = 0.1; giant.textAlpha = 1.0;
    status = cjgui_internal_renderer_set_composable_scene_node(session, 0u, &giant,
        "", "X", "", "", 0u);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return fail("first_large_candidate", status, 0);
    CjguiInternalRendererComposableGeometry geometry;
    memset(&geometry, 0, sizeof(geometry)); geometry.nodeId = giant.nodeId;
    status = cjgui_internal_renderer_set_composable_scene_geometry(session, 98u, 0u, &geometry);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return fail("first_large_geometry", status, 0);
    uint64_t candidateBytes = 0, candidateResources = 0;
    if (!cjgui_windows_contract_session_state(session, &dpi, &pixelWidth, &pixelHeight,
        &candidateBytes, &candidateResources, &scratchBytes)) return fail("candidate_resources", 0, 1);
    if (candidateBytes <= baselineBytes || candidateResources <= baselineResources)
        return fail("candidate_allocation_charged", candidateBytes, baselineBytes + 1u);
    giant.nodeId = 802u;
    status = cjgui_internal_renderer_set_composable_scene_node(session, 1u, &giant,
        "", "Y", "", "", 0u);
    if (status != CJGUI_INTERNAL_RENDERER_TEXT_RESOURCE_BUDGET_EXCEEDED)
        return fail("multi_node_scene_budget", status,
            CJGUI_INTERNAL_RENDERER_TEXT_RESOURCE_BUDGET_EXCEEDED);
    CjguiInternalRendererDiagnosticNodeGeometry accepted;
    memset(&accepted, 0, sizeof(accepted));
    status = cjgui_internal_renderer_diagnostic_node_geometry(session, 0u, &accepted);
    if (status != CJGUI_INTERNAL_RENDERER_OK || accepted.sceneVersion != 97u)
        return fail("accepted_preserved_after_budget_reject", accepted.sceneVersion, 97);
    status = cjgui_internal_renderer_discard_composable_scene_candidate(session);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return fail("discard_candidate", status, 0);
    uint64_t cancelledBytes = 0, cancelledResources = 0;
    if (!cjgui_windows_contract_session_state(session, &dpi, &pixelWidth, &pixelHeight,
        &cancelledBytes, &cancelledResources, &scratchBytes)) return fail("cancel_resources", 0, 1);
    if (cancelledBytes != baselineBytes || cancelledResources != baselineResources || scratchBytes != 0u)
        return fail("cancel_releases_candidate", cancelledBytes, baselineBytes);
    uint32_t pendingAfterCancel = 0u, referencesAfterCancel = 0u;
    uint64_t bytesAfterCancel = 0u;
    if (!cjgui_windows_contract_text_flight_state(session, &pendingAfterCancel,
        &referencesAfterCancel, &bytesAfterCancel) || pendingAfterCancel < pendingFlights ||
        referencesAfterCancel == 0u || bytesAfterCancel == 0u)
        return fail("cancel_does_not_retire_in_flight_text", referencesAfterCancel, 1);
    uint64_t globalBytes = 0; uint32_t globalResources = 0;
    if (!cjgui_windows_contract_live_text_texture_usage(&globalBytes, &globalResources) ||
        globalBytes != cancelledBytes || globalResources != cancelledResources)
        return fail("live_texture_accounting", globalBytes, cancelledBytes);
    printf("TEXTURE_BUDGET baseline=%llu candidate=%llu candidate_resources=%llu cancelled=%llu cancelled_resources=%llu scratch=%llu\n",
        (unsigned long long)baselineBytes, (unsigned long long)candidateBytes,
        (unsigned long long)candidateResources, (unsigned long long)cancelledBytes,
        (unsigned long long)cancelledResources, (unsigned long long)scratchBytes);
    if (!cjgui_windows_contract_set_hold_text_flights(session, 0u) ||
        !cjgui_windows_contract_drain_text_flights(session, 5000u))
        return fail("complete_submitted_text_reads", pendingAfterCancel, 0);
    uint32_t pendingAfterDrain = UINT32_MAX, referencesAfterDrain = UINT32_MAX;
    uint64_t bytesAfterDrain = UINT64_MAX;
    if (!cjgui_windows_contract_text_flight_state(session, &pendingAfterDrain,
        &referencesAfterDrain, &bytesAfterDrain) || pendingAfterDrain != 0u ||
        referencesAfterDrain != 0u || bytesAfterDrain != 0u)
        return fail("completed_text_flights_release", referencesAfterDrain, 0);
    if (!cjgui_windows_contract_session_state(session, &dpi, &pixelWidth, &pixelHeight,
        &cancelledBytes, &cancelledResources, &scratchBytes) || cancelledBytes == 0u ||
        !cjgui_windows_contract_live_text_texture_usage(&globalBytes, &globalResources) ||
        globalBytes != cancelledBytes || globalResources != cancelledResources)
        return fail("flight_release_preserves_accepted_scene", globalBytes, cancelledBytes);
    status = cjgui_internal_renderer_destroy(session);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return fail("destroy", status, 0);
    if (!cjgui_windows_contract_live_text_texture_usage(&globalBytes, &globalResources) ||
        globalBytes != 0u || globalResources != 0u)
        return fail("close_releases_all_text_textures", globalBytes, 0);
    puts("CJGUI_WINDOWS_GEOMETRY_BUDGET_CONTRACT PASS dpi=96,144 hit,caret,selection=same_accepted_layout multi_node_budget=reject_old_accepted=preserved candidate_cancel=zero_delta gpu_flights=held,reaped window_close=zero_live_textures");
    return 0;
}

/* Actual Windows preparation, staged scene, Present and accepted proxy.
 * No value recovery, selection unclamping or replacement implementation. */
#include "cjgui_windows_renderer.c"
static int failures;
static const char *original = "abcde\nFGHIJ\n";
static void check(const char *name, int pass) {
    printf("DISPLAY_NATIVE_CASE %s pass=%d\n", name, !!pass);
    fflush(stdout);
    if (!pass) ++failures;
}
static CjguiInternalRendererComposableNode declaration(uint64_t scene, int64_t resource,
    uint32_t preserve) {
    CjguiInternalRendererComposableNode n = {0};
    n.nodeId = 4; n.resourceId = resource; n.projectionVersion = scene;
    n.x = 20; n.y = 24; n.width = 420; n.height = 220;
    n.clipWidth = 640; n.clipHeight = 360;
    n.nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT;
    n.isInteractive = 1; n.preservesActiveLocalText = preserve;
    n.fontSize = 20; n.fontWeight = 400;
    n.textRed = n.textGreen = n.textBlue = 0.1; n.textAlpha = 1; n.fillAlpha = 1;
    return n;
}
static int stage(uint64_t token, uint64_t scene, int64_t resource, uint32_t preserve,
    const char *body) {
    CjguiInternalRendererComposableNode n = declaration(scene, resource, preserve);
    CjguiInternalRendererComposableGeometry g = {0}; g.nodeId = 4;
    int ok = configure_composable_scene_impl(token, scene, 1) == 0;
    ok = ok && set_composable_scene_node_impl(token, 0, &n, "Body", body, "", "", 0) == 0;
    ok = ok && set_scene_geometry(find_session(token), scene, 0, &g) == 0;
    return ok;
}
static int present(uint64_t token) {
    CjguiInternalRendererFrameObservation f = {0};
    return present_composable_scene_impl(token, &f);
}
static int accepted(CjguiWindowsRendererSession *s, uint64_t scene, const char *body) {
    CjguiWindowsSceneNode *n = scene_node_by_id(&s->acceptedScene, 4);
    printf("DISPLAY_NATIVE_FACT stage=accepted token=%llu scene=%llu bytes=%llu value=[%s]\n",
        (unsigned long long)s->token, (unsigned long long)s->acceptedScene.version,
        (unsigned long long)(n && n->value ? strlen(n->value) : 0), n && n->value ? n->value : "");
    return n && s->acceptedScene.version == scene && !strcmp(n->value ? n->value : "", body);
}
/* Read the real uploaded text texture. A glyph-only raster cannot satisfy
   this blue-background count, so the capability check also proves drawing. */
static uint64_t selection_pixels(CjguiWindowsRendererSession *s) {
    CjguiWindowsSceneNode *node = scene_node_by_id(&s->acceptedScene, 4);
    if (!node || !node->textTexture) return 0u;
    D3D11_TEXTURE2D_DESC desc = {0};
    ID3D11Texture2D_GetDesc(node->textTexture, &desc);
    desc.Usage = D3D11_USAGE_STAGING; desc.BindFlags = 0u;
    desc.CPUAccessFlags = D3D11_CPU_ACCESS_READ; desc.MiscFlags = 0u;
    ID3D11Texture2D *copy = NULL;
    if (FAILED(ID3D11Device_CreateTexture2D(s->device, &desc, NULL, &copy))) return 0u;
    ID3D11DeviceContext_CopyResource(s->context, (ID3D11Resource *)copy,
        (ID3D11Resource *)node->textTexture);
    D3D11_MAPPED_SUBRESOURCE mapped = {0};
    uint64_t count = 0u;
    if (SUCCEEDED(ID3D11DeviceContext_Map(s->context, (ID3D11Resource *)copy, 0,
        D3D11_MAP_READ, 0u, &mapped))) {
        for (UINT y = 0; y < desc.Height; ++y) for (UINT x = 0; x < desc.Width; ++x) {
            const uint8_t *p = (uint8_t *)mapped.pData + (size_t)y * mapped.RowPitch + x * 4u;
            if (p[2] > p[0] + 50u && p[1] > p[0] + 20u && p[3] > 0u) ++count;
        }
        ID3D11DeviceContext_Unmap(s->context, (ID3D11Resource *)copy, 0);
    }
    ID3D11Texture2D_Release(copy);
    printf("DISPLAY_NATIVE_FACT selection_texture_blue_pixels=%llu\n", (unsigned long long)count);
    return count;
}
static CjguiInternalRendererStatus display_fixture_proc(CjguiWindowsRendererSession *s, void *raw) {
    (void)raw;
    uint64_t token = s->token;
    check("first_real_scene", stage(token, 1, 102, 0, original) && present(token) == 0 && accepted(s, 1, original));
    check("focus_actual_node", focus_composable_node_impl(token, 4) == 0);
    s->ownedTextSessionEnabled = 1; s->ownedTextSessionNodeId = 4;
    s->ownedTextSessionResourceId = 102;
    s->ownedTextSessionNodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT;
    s->ownedTextSessionBindingEpoch = 1;
    s->selectionStart16 = s->selectionEnd16 = 2;

    /* One immutable prepared ticket. Both bytes and selection come from its
       own declaration; a later caller mutation must not change its copy. */
    CjguiInternalRendererComposableNode n = declaration(2, 102, 1);
    CjguiInternalRendererComposableGeometry g = {0}; g.nodeId = 4;
    const char *payload = original;
    char frozen[32]; strcpy(frozen, payload);
    check("prepare_same_ticket", begin_composable_preparation_impl(token, 100, 1, 2, 1) == 0 &&
        prepare_composable_node_impl(token, 100, 0, &n, &g, "Body", frozen,
            "transport-body", "", "", "", "", "") == 0);
    printf("DISPLAY_NATIVE_FACT stage=candidate token=%llu prep=100 scene=2 owner=1 bytes=%llu value=[%s]\n",
        (unsigned long long)token, (unsigned long long)strlen(s->preparationIncoming[0].value),
        s->preparationIncoming[0].value);
    check("prepared_value_is_exact_12", !strcmp(s->preparationIncoming[0].value, original));
    memset(frozen, 'Z', strlen(frozen));
    uint32_t ready = 0;
    uint64_t deadline = cjgui_internal_renderer_owner_clock_ns() + 1000000000ull;
    check("prepare_real_layout", advance_composable_preparation_impl(token, 100, deadline, &ready) == 0 && ready == 1);
    check("prepared_promote_present", configure_composable_scene_impl(token, 2, 1) == 0 &&
        promote_composable_preparation_impl(token, 100) == 0 && present(token) == 0);
    check("accepted_12_not_caller_mutation", accepted(s, 2, original) &&
        !strcmp((const char *)s->proxyValueUtf8, original));
    check("accepted_same_caret_2", s->selectionStart16 == 2 && s->selectionEnd16 == 2);

    const char *replacement = "klmno\nPQRST\n";
    check("same_length_different_body", stage(token, 3, 102, 1, replacement) && present(token) == 0 &&
        accepted(s, 3, replacement) && !strcmp((const char *)s->proxyValueUtf8, replacement));
    check("clear_is_real_empty_with_preserve", stage(token, 4, 102, 1, "") && present(token) == 0 &&
        accepted(s, 4, "") && s->proxyValueUtf8 && !s->proxyValueUtf8[0] &&
        s->selectionStart16 == 0 && s->selectionEnd16 == 0);
    check("binding_change_uses_new_body", stage(token, 5, 103, 0, "new owner") && present(token) == 0 &&
        accepted(s, 5, "new owner") && focus_composable_node_impl(token, 4) == 0 &&
        !strcmp((const char *)s->proxyValueUtf8, "new owner"));

    n = declaration(6, 103, 1);
    check("cancel_original_ticket", begin_composable_preparation_impl(token, 101, 5, 6, 1) == 0 &&
        prepare_composable_node_impl(token, 101, 0, &n, &g, "Body", "cancel body",
            "transport-body", "", "", "", "", "") == 0 &&
        cancel_composable_preparation_impl(token, 101) == 0 && accepted(s, 5, "new owner"));
    uint8_t mayBegin = 0;
    check("cancel_real_reclaim", cjgui_internal_renderer_drain_composable_retirement(token,
        cjgui_internal_renderer_owner_clock_ns() + 1000000000ull, &mayBegin) == 0 && mayBegin == 1);
    check("cancel_late_promote_refused", promote_composable_preparation_impl(token, 101) != 0 &&
        accepted(s, 5, "new owner"));

    check("failed_present_candidate_staged", stage(token, 7, 103, 1, "failed frame"));
    /* The real Present precondition rejects missing geometry. The candidate's
       new bytes have already reached the actual native scene at this point. */
    s->candidateScene.nodes[0].hasGeometry = 0;
    uint64_t acceptedCount = s->presentationAcceptedCount;
    check("failed_present_no_new_accepted", present(token) == CJGUI_INTERNAL_RENDERER_SCENE_STALE &&
        s->presentationAcceptedCount == acceptedCount && accepted(s, 5, "new owner"));
    check("failed_candidate_discard", discard_composable_scene_candidate_impl(token) == 0);
    s->ownedTextSessionEnabled = 0;
    check("ordinary_nonowned_display", stage(token, 8, 103, 1, "ordinary body") && present(token) == 0 &&
        accepted(s, 8, "ordinary body"));
    /* The normal Undo candidate contains additive selection backgrounds on
       its previews. The advertised version must match this real wire/draw
       path, while platform colours and malformed spans stay refused. */
    const char *decoration = "2:9:0:0:0:0:0:0:0:1:0.25:0.5:0.85:0.42:1";
    CjguiWindowsTextStyleRun *runs = NULL;
    uint32_t runCount = 0u;
    check("explicit_selection_capability_only", cjgui_internal_renderer_selection_background_version() == 1u);
    check("selection_wire_exact_span", parse_style_run_list(decoration, original, &runs, &runCount) == 0 &&
        runCount == 1u && runs[0].selectionBackgroundOnly && runs[0].hasBackground &&
        runs[0].start16 == 2u && runs[0].end16 == 9u && runs[0].fontSize == 0.0f);
    free(runs); runs = NULL;
    check("platform_selection_colour_still_refused", parse_style_run_list(
        "2:9:0:0:0:0:0:0:0:1:0:0:0:0:2", original, &runs, &runCount) ==
        CJGUI_INTERNAL_RENDERER_STYLE_RUN_INVALID && !runs);
    check("selection_internal_utf8_boundary_refused", parse_style_run_list(
        "1:2:0:0:0:0:0:0:0:1:0.25:0.5:0.85:0.42:1", "\xc3\xa9Z", &runs, &runCount) ==
        CJGUI_INTERNAL_RENDERER_TEXT_RANGE_INVALID && !runs);
    check("selection_outside_body_refused", parse_style_run_list(
        "2:13:0:0:0:0:0:0:0:1:0.25:0.5:0.85:0.42:1", original, &runs, &runCount) ==
        CJGUI_INTERNAL_RENDERER_TEXT_RANGE_INVALID && !runs);
    check("selection_decoration_real_stage", stage(token, 9, 103, 0, original) &&
        set_composable_text_runs_impl(token, 4, decoration) == 0);
    check("selection_decoration_real_present", present(token) == 0 && accepted(s, 9, original) &&
        scene_node_by_id(&s->acceptedScene, 4)->textMaskNonzeroPixels > 0u);
    check("selection_decoration_uploaded_pixels", selection_pixels(s) > 20u);
    return CJGUI_INTERNAL_RENDERER_OK;
}
int main(void) {
    CjguiInternalRendererConfig config = {640, 360, 0.96, 0.97, 0.99, 1};
    CjguiInternalRendererStatus status = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    uint64_t token = cjgui_internal_renderer_create(&config, &status);
    check("real_window_device_create", token && status == 0);
    if (!token || status) return 1;
    check("actual_ui_dispatch", windows_dispatch_sync(token, "display_fixture",
        CJGUI_WINDOWS_CMD_GENERIC, display_fixture_proc, NULL, NULL, 3000, NULL) == 0);
    check("own_session_destroy", cjgui_internal_renderer_destroy(token) == 0);
    printf("OBSERVATION_UNIT failures=%d\n", failures);
    return failures ? 1 : 0;
}

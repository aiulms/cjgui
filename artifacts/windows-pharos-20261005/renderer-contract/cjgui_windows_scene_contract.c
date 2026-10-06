#include <stdio.h>
#include <string.h>
#include <math.h>
#include <dwrite.h>

#include "cjgui_internal_renderer.h"

int cjgui_windows_scene_contract_readback_counts(uint64_t token,
    uint64_t *outNonClear, uint64_t *outDark, uint64_t *outMaskPixels);
typedef struct CjguiWindowsSceneContractTextDiagnostic {
    uint64_t glyphRunCalls;
    uint32_t glyphCount;
    uint32_t activeTextureType;
    FLOAT fontEmSize;
    int32_t analysisHr;
    int32_t boundsAliasHr;
    int32_t boundsClearTypeHr;
    int32_t alphaTextureHr;
    int32_t drawHr;
    int32_t rendererFailureHr;
    int32_t layoutMetricsHr;
    LONG aliasLeft, aliasTop, aliasRight, aliasBottom;
    LONG clearTypeLeft, clearTypeTop, clearTypeRight, clearTypeBottom;
    FLOAT layoutWidthIncludingTrailingWhitespace;
    FLOAT layoutHeight;
    uint32_t layoutLineCount;
    uint32_t reserved;
    uint64_t alphaTextureNonzero;
    uint64_t compositeWrites;
    uint64_t maskNonzero;
    uint64_t textureNonzero;
} CjguiWindowsSceneContractTextDiagnostic;
int cjgui_windows_scene_contract_text_diagnostic(uint64_t token,
    CjguiWindowsSceneContractTextDiagnostic *outDiagnostic);
int cjgui_windows_scene_contract_readback_text_texture(uint64_t token, uint64_t *outNonzero);
int cjgui_windows_scene_contract_readback_color_counts(uint64_t token,
    uint64_t *outRedPixels, uint64_t *outGreenPixels);
int cjgui_windows_scene_contract_input_layout_widths(uint64_t token, uint64_t nodeId,
    FLOAT *outActualWidth, FLOAT *outValueOnlyWidth);
CjguiInternalRendererStatus cjgui_internal_renderer_grapheme_cluster_range(
    const char *utf8, uint64_t declaredLength, uint64_t offsetByte,
    uint64_t *outStartByte, uint64_t *outEndByte);

static int fail(const char *name, int value) {
    fprintf(stderr, "CJGUI_WINDOWS_SCENE_CONTRACT FAIL %s=%d\n", name, value);
    return 1;
}

static int expect_cluster(const char *name, const char *text, uint64_t offset,
    uint64_t expectedStart, uint64_t expectedEnd) {
    uint64_t start = 0u, end = 0u;
    CjguiInternalRendererStatus status = cjgui_internal_renderer_grapheme_cluster_range(
        text, (uint64_t)strlen(text), offset, &start, &end);
    if (status != CJGUI_INTERNAL_RENDERER_OK || start != expectedStart || end != expectedEnd) {
        fprintf(stderr, "CJGUI_WINDOWS_SCENE_CONTRACT FAIL %s status=%d range=[%llu,%llu)\n",
            name, status, (unsigned long long)start, (unsigned long long)end);
        return 1;
    }
    return 0;
}

int main(void) {
    static const char combining[] = "Ae\xcc\x81" "B";
    static const char family[] =
        "A\xf0\x9f\x91\xa8\xe2\x80\x8d\xf0\x9f\x91\xa9"
        "\xe2\x80\x8d\xf0\x9f\x91\xa7\xe2\x80\x8d\xf0\x9f\x91\xa6" "B";
    static const char crlf[] = "A\r\nB";
    if (expect_cluster("combining_scalar_start", combining, 2u, 1u, 4u) ||
        expect_cluster("combining_scalar_middle", combining, 3u, 1u, 4u) ||
        expect_cluster("zwj_family_member", family, 9u, 1u, 26u) ||
        expect_cluster("crlf_cluster", crlf, 2u, 1u, 3u)) return 1;
    uint64_t prefixBytes = 0u;
    CjguiInternalRendererStatus prefixStatus = cjgui_internal_renderer_composed_prefix_utf8_length(
        combining, (uint64_t)strlen(combining), 2u, 10u, 1u, &prefixBytes);
    if (prefixStatus != CJGUI_INTERNAL_RENDERER_OK || prefixBytes != 1u)
        return fail("prefix_does_not_split_grapheme", prefixStatus);
    prefixBytes = 0u;
    prefixStatus = cjgui_internal_renderer_composed_prefix_utf8_length(
        combining, (uint64_t)strlen(combining), 32u, 10u, 0u, &prefixBytes);
    if (prefixStatus != CJGUI_INTERNAL_RENDERER_OK || prefixBytes != 4u)
        return fail("incomplete_scan_drops_last_grapheme", prefixStatus);
    uint64_t invalidStart = 0u, invalidEnd = 0u;
    CjguiInternalRendererStatus invalidOffset = cjgui_internal_renderer_grapheme_cluster_range(
        combining, (uint64_t)strlen(combining), (uint64_t)strlen(combining),
        &invalidStart, &invalidEnd);
    if (invalidOffset != CJGUI_INTERNAL_RENDERER_GRAPHEME_BOUNDARY_INVALID)
        return fail("cluster_offset_past_end", invalidOffset);
    puts("CJGUI_WINDOWS_GRAPHEME_CONTRACT PASS combining=1:4 family=1:26 crlf=1:3 prefix=1,4 invalid=24");

    CjguiInternalRendererConfig config = {640u, 360u, 0.96, 0.97, 0.99, 1.0};
    CjguiInternalRendererStatus status = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    uint64_t session = cjgui_internal_renderer_create(&config, &status);
    if (!session || status != CJGUI_INTERNAL_RENDERER_OK) return fail("create", status);

    CjguiInternalRendererComposableNode node;
    memset(&node, 0, sizeof(node));
    node.nodeId = 7u;
    node.projectionVersion = 41u;
    node.x = 20; node.y = 24; node.width = 420; node.height = 52;
    node.clipX = 0; node.clipY = 0; node.clipWidth = 640; node.clipHeight = 360;
    node.nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT;
    node.fontSize = 20.0;
    node.fontWeight = 400u;
    node.textRed = 0.08; node.textGreen = 0.10; node.textBlue = 0.14; node.textAlpha = 1.0;
    CjguiInternalRendererComposableGeometry geometry;
    memset(&geometry, 0, sizeof(geometry));
    geometry.nodeId = node.nodeId;

    status = cjgui_internal_renderer_configure_composable_scene(session, 41u, 1u);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return fail("configure_first", status);
    status = cjgui_internal_renderer_set_composable_scene_node(session, 0u, &node,
        "", "Windows accepted-scene contract", "", "", 0u);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return fail("set_first", status);
    status = cjgui_internal_renderer_set_composable_scene_geometry(session, 41u, 0u, &geometry);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return fail("geometry_first", status);

    CjguiInternalRendererFrameObservation observation;
    memset(&observation, 0, sizeof(observation));
    status = cjgui_internal_renderer_present_composable_scene(session, &observation);
    if (status != CJGUI_INTERNAL_RENDERER_OK || observation.frameIndex == 0u)
        return fail("present_first", status);
    CjguiWindowsSceneContractTextDiagnostic textDiagnostic;
    memset(&textDiagnostic, 0, sizeof(textDiagnostic));
    uint64_t textureNonzero = 0u;
    if (!cjgui_windows_scene_contract_text_diagnostic(session, &textDiagnostic) ||
        !cjgui_windows_scene_contract_readback_text_texture(session, &textureNonzero))
        return fail("text_diagnostic_readback", 0);
    textDiagnostic.textureNonzero = textureNonzero;
    printf("DIRECTWRITE glyph_calls=%llu glyphs=%lu em=%.2f metrics_hr=0x%08lx metrics=%.2fx%.2f lines=%lu draw_hr=0x%08lx failure_hr=0x%08lx active_texture=%lu alias_hr=0x%08lx alias_rect=%ld,%ld,%ld,%ld cleartype_hr=0x%08lx cleartype_rect=%ld,%ld,%ld,%ld alpha_hr=0x%08lx alpha_nonzero=%llu composite_writes=%llu mask_nonzero=%llu texture_nonzero=%llu\n",
        (unsigned long long)textDiagnostic.glyphRunCalls, (unsigned long)textDiagnostic.glyphCount,
        textDiagnostic.fontEmSize, (unsigned long)textDiagnostic.layoutMetricsHr,
        textDiagnostic.layoutWidthIncludingTrailingWhitespace, textDiagnostic.layoutHeight,
        (unsigned long)textDiagnostic.layoutLineCount, (unsigned long)textDiagnostic.drawHr,
        (unsigned long)textDiagnostic.rendererFailureHr, (unsigned long)textDiagnostic.activeTextureType,
        (unsigned long)textDiagnostic.boundsAliasHr, (long)textDiagnostic.aliasLeft,
        (long)textDiagnostic.aliasTop, (long)textDiagnostic.aliasRight, (long)textDiagnostic.aliasBottom,
        (unsigned long)textDiagnostic.boundsClearTypeHr, (long)textDiagnostic.clearTypeLeft,
        (long)textDiagnostic.clearTypeTop, (long)textDiagnostic.clearTypeRight,
        (long)textDiagnostic.clearTypeBottom, (unsigned long)textDiagnostic.alphaTextureHr,
        (unsigned long long)textDiagnostic.alphaTextureNonzero,
        (unsigned long long)textDiagnostic.compositeWrites,
        (unsigned long long)textDiagnostic.maskNonzero, (unsigned long long)textDiagnostic.textureNonzero);
    uint64_t nonClearPixels = 0u, darkPixels = 0u, maskPixels = 0u;
    if (!cjgui_windows_scene_contract_readback_counts(session, &nonClearPixels, &darkPixels, &maskPixels) ||
        nonClearPixels < 20u || darkPixels < 20u || maskPixels < 20u) {
        fprintf(stderr, "PIXEL_COUNTS nonclear=%llu dark=%llu mask=%llu texture=%llu\n",
            (unsigned long long)nonClearPixels, (unsigned long long)darkPixels,
            (unsigned long long)maskPixels, (unsigned long long)textureNonzero);
        return fail("readback_text_pixels", (int)darkPixels);
    }
    CjguiInternalRendererDiagnosticNodeGeometry diagnostic;
    memset(&diagnostic, 0, sizeof(diagnostic));
    status = cjgui_internal_renderer_diagnostic_node_geometry(session, 0u, &diagnostic);
    if (status != CJGUI_INTERNAL_RENDERER_OK || diagnostic.sceneVersion != 41u)
        return fail("accepted_first", status);

    int boundaryFailures = 0;
    status = cjgui_internal_renderer_configure_composable_scene(session, 42u, 2u);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return fail("configure_renderer_boundaries", status);
    const char *unknownTag = "0:4:24:700:0:1:0:0:1:0:0:0:0:1:2";
    status = cjgui_internal_renderer_set_composable_text_runs(session, 7u, unknownTag);
    if (status != CJGUI_INTERNAL_RENDERER_STYLE_RUN_INVALID) {
        fprintf(stderr, "STYLE_TAG_RED status=%d expected=%d\n", status,
            CJGUI_INTERNAL_RENDERER_STYLE_RUN_INVALID);
        ++boundaryFailures;
    }
    const char *styledRuns =
        "0:4:24:700:0:1:0:0:1:0:0:0:0:1;"
        "5:9:20:400:1:0:0:1:1:1:0.1:0.8:0.1:1";
    status = cjgui_internal_renderer_set_composable_text_runs(session, 7u, styledRuns);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return fail("install_styled_runs", status);
    node.projectionVersion = 42u;
    node.nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT;
    node.x = 20; node.y = 24; node.width = 420; node.height = 64;
    status = cjgui_internal_renderer_set_composable_scene_node(session, 0u, &node,
        "", "Bold code", "", "", 0u);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return fail("set_styled_node", status);
    geometry.nodeId = node.nodeId;
    status = cjgui_internal_renderer_set_composable_scene_geometry(session, 42u, 0u, &geometry);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return fail("styled_geometry", status);

    CjguiInternalRendererComposableNode inputNode;
    memset(&inputNode, 0, sizeof(inputNode));
    inputNode.nodeId = 8u;
    inputNode.projectionVersion = 42u;
    inputNode.x = 20; inputNode.y = 110; inputNode.width = 420; inputNode.height = 56;
    inputNode.clipX = 0; inputNode.clipY = 0; inputNode.clipWidth = 640; inputNode.clipHeight = 360;
    inputNode.nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT_INPUT;
    inputNode.fontSize = 20.0;
    inputNode.fontWeight = 400u;
    inputNode.textRed = 0.08; inputNode.textGreen = 0.10; inputNode.textBlue = 0.14;
    inputNode.textAlpha = 1.0;
    status = cjgui_internal_renderer_set_composable_scene_node(session, 1u, &inputNode,
        "A deliberately long input label", "X", "", "", 0u);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return fail("set_labeled_input", status);
    memset(&geometry, 0, sizeof(geometry));
    geometry.nodeId = inputNode.nodeId;
    status = cjgui_internal_renderer_set_composable_scene_geometry(session, 42u, 1u, &geometry);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return fail("labeled_input_geometry", status);
    memset(&observation, 0, sizeof(observation));
    status = cjgui_internal_renderer_present_composable_scene(session, &observation);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return fail("present_renderer_boundaries", status);

    uint64_t redPixels = 0u, greenPixels = 0u;
    if (!cjgui_windows_scene_contract_readback_color_counts(session, &redPixels, &greenPixels))
        return fail("styled_color_readback", 0);
    FLOAT inputActualWidth = 0.0f, inputValueOnlyWidth = 0.0f;
    if (!cjgui_windows_scene_contract_input_layout_widths(session, 8u,
        &inputActualWidth, &inputValueOnlyWidth)) return fail("input_layout_widths", 0);
    printf("STYLE_PIXELS red=%llu green=%llu\n",
        (unsigned long long)redPixels, (unsigned long long)greenPixels);
    printf("LABELED_INPUT_LAYOUT actual_width=%.2f value_only_width=%.2f\n",
        inputActualWidth, inputValueOnlyWidth);
    if (redPixels < 10u || greenPixels < 100u) ++boundaryFailures;
    if (fabsf(inputActualWidth - inputValueOnlyWidth) > 0.75f) ++boundaryFailures;
    if (boundaryFailures) {
        fprintf(stderr, "RENDERER_BOUNDARIES_RED failures=%d\n", boundaryFailures);
        return boundaryFailures;
    }

    status = cjgui_internal_renderer_configure_composable_scene(session, 43u, 1u);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return fail("configure_stale_candidate", status);
    node.projectionVersion = 42u; // stale node must not enter the new candidate
    status = cjgui_internal_renderer_set_composable_scene_node(session, 0u, &node,
        "", "stale candidate", "", "", 0u);
    if (status == CJGUI_INTERNAL_RENDERER_OK) return fail("stale_node_accepted", status);
    memset(&observation, 0, sizeof(observation));
    status = cjgui_internal_renderer_present_composable_scene(session, &observation);
    if (status == CJGUI_INTERNAL_RENDERER_OK) return fail("invalid_candidate_presented", status);
    memset(&diagnostic, 0, sizeof(diagnostic));
    status = cjgui_internal_renderer_diagnostic_node_geometry(session, 0u, &diagnostic);
    if (status != CJGUI_INTERNAL_RENDERER_OK || diagnostic.sceneVersion != 42u)
        return fail("old_scene_not_preserved", status);

    status = cjgui_internal_renderer_destroy(session);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return fail("destroy", status);
    printf("CJGUI_WINDOWS_SCENE_CONTRACT PASS accepted=42 stale_candidate_rejected=1 renderer_boundaries=styled_runs,labeled_input old_scene_preserved=1 nonclear_pixels=%llu dark_text_pixels=%llu\n",
        (unsigned long long)nonClearPixels, (unsigned long long)darkPixels);
    return 0;
}

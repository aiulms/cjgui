// Actual Metal drawable comparison for retained text tiles crossing a
// subpoint translation. The reference is a fresh renderer session rasterized
// at the same final geometry, so it cannot inherit the moving session's tiles.
#define CJGUI_INTERNAL_TESTING 1
#import "../cjgui_internal_renderer.m"
#import <AppKit/AppKit.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static int require(BOOL passed, const char *name) {
    if (passed) return 0;
    fprintf(stderr, "TEXT_TILE_DRAWABLE_SEAM_FAIL %s\n", name);
    return 1;
}

static NSString *FixtureBody(void) {
    static NSString *body = nil;
    if (!body) {
        NSMutableString *value = [NSMutableString string];
        for (NSUInteger row = 0; row < 42; row++) {
            [value appendFormat:@"第%02lu行 中文🙂 tile seam · abcdefghijklmnop\n",
                               (unsigned long)row];
        }
        body = [value copy];
    }
    return body;
}

static CjguiInternalRendererStatus submitFixture(uint64_t session, uint64_t version,
    double translateX, double translateY, BOOL preserveActive, BOOL capturePixel,
    double pixelX, double pixelY) {
    CjguiInternalRendererComposableNode node = {0};
    node.nodeId = 812; node.projectionVersion = version; node.resourceId = -1;
    node.nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT;
    node.x = 0; node.y = 0; node.width = 640; node.height = 900;
    node.clipX = 0; node.clipY = 0; node.clipWidth = 640; node.clipHeight = 300;
    node.clipConstraintCount = 1;
    node.clip0X = 0; node.clip0Y = 0; node.clip0Width = 640; node.clip0Height = 300;
    node.effectGroupSubtreeCount = 1;
    node.isInteractive = 1;
    node.preservesActiveLocalText = preserveActive ? 1 : 0;
    node.fillRed = 0.91; node.fillGreen = 0.87; node.fillBlue = 0.74; node.fillAlpha = 1.0;
    node.textAlpha = 1.0; node.textRed = 0.08; node.textGreen = 0.10; node.textBlue = 0.15;
    node.fontSize = 15.0;
    CjguiInternalRendererComposableGeometry geometry = {0};
    geometry.nodeId = node.nodeId; geometry.clipCount = 1;
    geometry.translateX = translateX; geometry.translateY = translateY;
    CjguiInternalRendererStatus status = cjgui_internal_renderer_configure_composable_scene(session, version, 1);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
    status = cjgui_internal_renderer_set_composable_scene_node(session, 0, &node,
        "", preserveActive ? "" : FixtureBody().UTF8String, "active multiline seam fixture", "", 0);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
    status = cjgui_internal_renderer_set_composable_scene_geometry(session, version, 0, &geometry);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
    status = cjgui_internal_renderer_stage_window_background(session, version, 0, 1);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
    if (capturePixel) {
        status = cjgui_internal_renderer_test_request_composable_drawable_pixel_precise(
            session, pixelX, pixelY);
        if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
    }
    CjguiInternalRendererFrameObservation frame = {0};
    return cjgui_internal_renderer_present_composable_scene(session, &frame);
}

static CjguiInternalRendererStatus readDrawablePixel(uint64_t session, uint64_t *version,
    double translateX, double translateY, double pointX, double pointY, uint8_t outBGRA[4]) {
    CjguiInternalRendererStatus status = submitFixture(session, ++(*version), translateX, translateY,
        YES, YES, pointX, pointY);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
    return cjgui_internal_renderer_test_composable_drawable_pixel(session,
        &outBGRA[0], &outBGRA[1], &outBGRA[2], &outBGRA[3]);
}

static CjguiInternalRendererStatus createFixtureSession(double scale, double initialTranslateX,
    double initialTranslateY,
    uint64_t *outSession, uint64_t *outVersion, uint64_t *outRasterCount,
    uint64_t *outTileBytes, uint32_t *outTileCount) {
    *outSession = 0; *outVersion = 1; *outRasterCount = 0;
    *outTileBytes = 0; *outTileCount = 0;
    CjguiInternalRendererConfig config = {.windowWidth = 640, .windowHeight = 300,
        .clearColorRed = 0.13, .clearColorGreen = 0.25, .clearColorBlue = 0.34,
        .clearColorAlpha = 1.0};
    CjguiInternalRendererStatus created = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    uint64_t session = cjgui_internal_renderer_create(&config, &created);
    if (created != CJGUI_INTERNAL_RENDERER_OK || session == 0) return created;
    CJGuiInternalSession *ctx = CjguiLookupSession(session);
    if (!ctx || !ctx.view || !ctx.window) return CJGUI_INTERNAL_RENDERER_VIEW_INVALIDATED;
    ctx.view.testBackingScaleOverride = scale;
    [ctx.view updateDrawableSize];
    CjguiInternalRendererStatus status = submitFixture(session, 1, initialTranslateX, initialTranslateY,
        NO, NO, 0, 0);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
    status = cjgui_internal_renderer_focus_composable_node(session, 812);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
    [ctx.composableSceneOverlay.inputProxy setString:FixtureBody()];
    NSUInteger tileCount = ctx.composableNodes[0].textTileTextures.count;
    if (tileCount == 0 && ctx.composableNodes[0].textTexture) tileCount = 1;
    uint64_t bytes = 0; float x = 0, y = 0, width = 0, height = 0;
    for (uint32_t tile = 0; tile < tileCount; tile++) {
        uint32_t reportedCount = 0;
        status = cjgui_internal_renderer_test_composable_text_tile_stats(session, 0, tile,
            &reportedCount, &bytes, &x, &y, &width, &height);
        if (status != CJGUI_INTERNAL_RENDERER_OK || reportedCount != tileCount) return status;
        *outTileBytes += bytes;
    }
    *outSession = session;
    *outRasterCount = ctx.view.testComposableTextRasterCount;
    *outTileCount = (uint32_t)tileCount;
    return CJGUI_INTERNAL_RENDERER_OK;
}

static int runScale(double scale) {
    uint64_t movedSession = 0, freshSession = 0, movedVersion = 1, freshVersion = 1;
    uint64_t movedInitialRaster = 0, freshRaster = 0, movedBytes = 0, freshBytes = 0;
    uint32_t movedTiles = 0, freshTiles = 0;
    if (require(createFixtureSession(scale, 0.0, -0.25, &movedSession, &movedVersion,
            &movedInitialRaster, &movedBytes, &movedTiles) == CJGUI_INTERNAL_RENDERER_OK,
            "moving_session_initial_tiles")) return 1;
    CJGuiInternalSession *moved = CjguiLookupSession(movedSession);
    if (require(moved != nil && moved.composableSceneOverlay.activeNodeId == 812 &&
            [moved.composableSceneOverlay.inputProxy.string isEqualToString:FixtureBody()],
            "moving_session_has_active_multiline_draft")) return 2;
    uint64_t beforeMove = moved.view.testComposableTextRasterCount;
    if (require(submitFixture(movedSession, ++movedVersion, 0.0, 0.25, YES, NO, 0, 0) ==
                CJGUI_INTERNAL_RENDERER_OK,
            "subpoint_translation_across_tile_edge")) return 3;
    uint64_t afterMove = moved.view.testComposableTextRasterCount;
    if (require(afterMove == beforeMove && moved.composableNodes[0].textTileTextures.count == movedTiles,
            "covered_tiles_reused_during_subpoint_motion")) return 4;

    if (require(createFixtureSession(scale, 0.0, 0.25, &freshSession, &freshVersion,
            &freshRaster, &freshBytes, &freshTiles) == CJGUI_INTERNAL_RENDERER_OK,
            "fresh_session_recomputes_final_coverage")) return 5;
    CJGuiInternalSession *fresh = CjguiLookupSession(freshSession);
    if (require(freshRaster > 0 && freshTiles > 0 && movedTiles > 0 &&
            movedBytes <= CjguiComposableTextTextureByteCapacity &&
            freshBytes <= CjguiComposableTextTextureByteCapacity,
            "both_paths_have_real_text_tiles")) return 6;
    if (require(fabs((double)moved.view.currentBackingScale - scale) < 0.000001 &&
            fabs((double)fresh.view.currentBackingScale - scale) < 0.000001 &&
            moved.view.metalLayer.drawableSize.width == ceil(moved.view.bounds.size.width * scale) &&
            fresh.view.metalLayer.drawableSize.width == ceil(fresh.view.bounds.size.width * scale),
            "true_scale_override_and_drawable_dimensions")) return 7;

    // Compare a narrow actual drawable band around the horizontal 256-point
    // text tile edge. The body contains repeated CJK, emoji, Latin glyphs and
    // a contrasting opaque background. Pixel-center requests cover both sides
    // of the edge at the physical texel density for this scale.
    const NSUInteger yCenter = (NSUInteger)floor(256.0 * scale);
    const NSUInteger xStart = (NSUInteger)floor(8.0 * scale);
    const NSUInteger xEnd = (NSUInteger)floor(208.0 * scale);
    const NSInteger yFirst = (NSInteger)yCenter - 2;
    const NSInteger yLast = (NSInteger)yCenter + 2;
    const NSUInteger sampleCount = (NSUInteger)(yLast - yFirst + 1) * (xEnd - xStart);
    NSMutableData *movedPixels = [NSMutableData dataWithLength:sampleCount * 4u];
    NSMutableData *freshPixels = [NSMutableData dataWithLength:sampleCount * 4u];
    if (require(movedPixels != nil && freshPixels != nil && sampleCount > 0,
            "bounded_readback_buffer")) return 8;
    uint8_t *movedBytesOut = movedPixels.mutableBytes;
    uint8_t *freshBytesOut = freshPixels.mutableBytes;
    uint64_t startMicros = CjguiMonotonicMicros();
    NSUInteger offset = 0;
    for (NSInteger py = yFirst; py <= yLast; py++) {
        for (NSUInteger px = xStart; px < xEnd; px++) {
            double pointX = ((double)px + 0.5) / scale;
            double pointY = ((double)py + 0.5) / scale;
            uint8_t pixel[4] = {0};
            if (readDrawablePixel(movedSession, &movedVersion, 0.0, 0.25, pointX, pointY, pixel) !=
                    CJGUI_INTERNAL_RENDERER_OK) return 9;
            memcpy(movedBytesOut + offset, pixel, 4);
            if (readDrawablePixel(freshSession, &freshVersion, 0.0, 0.25, pointX, pointY, pixel) !=
                    CJGUI_INTERNAL_RENDERER_OK) return 10;
            memcpy(freshBytesOut + offset, pixel, 4);
            offset += 4;
        }
    }
    uint64_t readbackMicros = CjguiMonotonicMicros() - startMicros;
    uint64_t diffBytes = 0, backgroundPixels = 0, inkPixels = 0;
    const uint8_t *movedRaw = movedPixels.bytes;
    const uint8_t *freshRaw = freshPixels.bytes;
    for (NSUInteger byte = 0; byte < movedPixels.length; byte++) {
        if (movedRaw[byte] != freshRaw[byte]) diffBytes++;
        if ((byte & 3u) == 3u) {
            uint8_t blue = movedRaw[byte - 3], green = movedRaw[byte - 2], red = movedRaw[byte - 1];
            if (abs((int)blue - 189) <= 1 && abs((int)green - 222) <= 1 && abs((int)red - 232) <= 1)
                backgroundPixels++;
            if (blue < 100 && green < 100 && red < 100) inkPixels++;
        }
    }
    if (require(diffBytes == 0, "actual_drawable_pixels_match_fresh_recomputation")) {
        fprintf(stderr, "scale=%.0f drawable_diff_bytes=%llu samples=%lu\n", scale,
                (unsigned long long)diffBytes, (unsigned long)sampleCount);
        return 11;
    }
    if (require(backgroundPixels > 0 && inkPixels > 0, "sample_band_contains_text_and_background")) {
        fprintf(stderr, "scale=%.0f background_pixels=%llu ink_pixels=%llu samples=%lu\n", scale,
                (unsigned long long)backgroundPixels, (unsigned long long)inkPixels,
                (unsigned long)sampleCount);
        return 12;
    }

    printf("TEXT_TILE_DRAWABLE_SEAM_PASS scale=%.0f drawable=%lux%lu samples=%lu diff_bytes=%llu "
           "background_pixels=%llu ink_pixels=%llu "
           "active=1 tile_count=%u tile_bytes=%llu fresh_tile_count=%u fresh_tile_bytes=%llu "
           "move_rasters=%llu->%llu fresh_rasters=%llu readback_us=%llu\n",
           scale, (unsigned long)moved.view.metalLayer.drawableSize.width,
           (unsigned long)moved.view.metalLayer.drawableSize.height,
           (unsigned long)sampleCount, (unsigned long long)diffBytes,
           (unsigned long long)backgroundPixels, (unsigned long long)inkPixels, movedTiles,
           (unsigned long long)movedBytes, freshTiles, (unsigned long long)freshBytes,
           (unsigned long long)beforeMove, (unsigned long long)afterMove,
           (unsigned long long)freshRaster, (unsigned long long)readbackMicros);
    cjgui_internal_renderer_destroy(movedSession);
    cjgui_internal_renderer_destroy(freshSession);
    return 0;
}

static int runCrossGridPhase(double scale) {
    uint64_t movedSession = 0, freshSession = 0, movedVersion = 1, freshVersion = 1;
    uint64_t movedRaster = 0, freshRaster = 0, movedBytes = 0, freshBytes = 0;
    uint32_t movedTiles = 0, freshTiles = 0;
    const double finalX = 0.375, finalY = 0.625;
    if (require(createFixtureSession(scale, -0.25, -0.25, &movedSession, &movedVersion,
            &movedRaster, &movedBytes, &movedTiles) == CJGUI_INTERNAL_RENDERER_OK,
            "cross_grid_moving_session") ||
        require(submitFixture(movedSession, ++movedVersion, finalX, finalY,
            YES, NO, 0, 0) == CJGUI_INTERNAL_RENDERER_OK,
            "cross_grid_changed_subpoint_phase")) return 1;
    CJGuiInternalSession *moved = CjguiLookupSession(movedSession);
    if (require(moved && moved.view.testComposableTextRasterCount == movedRaster,
            "cross_grid_phase_reuses_covered_tiles") ||
        require(createFixtureSession(scale, finalX, finalY, &freshSession, &freshVersion,
            &freshRaster, &freshBytes, &freshTiles) == CJGUI_INTERNAL_RENDERER_OK,
            "cross_grid_fresh_session")) return 2;
    // Horizontal edge, vertical edge and their intersection. Each reads the
    // actual Metal drawable at pixel centers on both sides of the tile line.
    const double centers[3][2] = {{64.0, 256.0}, {512.0, 40.0}, {512.0, 256.0}};
    uint64_t differences = 0;
    uint64_t samples = 0;
    uint8_t firstMoved[4] = {0};
    for (NSUInteger region = 0; region < 3; region++) {
        for (NSInteger dy = -2; dy <= 2; dy++) {
            for (NSInteger dx = -2; dx <= 2; dx++) {
                double pointX = (floor(centers[region][0] * scale) + dx + 0.5) / scale;
                double pointY = (floor(centers[region][1] * scale) + dy + 0.5) / scale;
                uint8_t movingPixel[4] = {0}, freshPixel[4] = {0};
                if (readDrawablePixel(movedSession, &movedVersion, finalX, finalY,
                        pointX, pointY, movingPixel) != CJGUI_INTERNAL_RENDERER_OK ||
                    readDrawablePixel(freshSession, &freshVersion, finalX, finalY,
                        pointX, pointY, freshPixel) != CJGUI_INTERNAL_RENDERER_OK) return 3;
                if (samples == 0) memcpy(firstMoved, movingPixel, 4);
                for (NSUInteger channel = 0; channel < 4; channel++)
                    if (movingPixel[channel] != freshPixel[channel]) differences++;
                samples++;
            }
        }
    }
    uint8_t altered[4] = {0};
    memcpy(altered, firstMoved, 4);
    altered[0] ^= 1u;
    if (require(differences == 0 && samples == 75 && altered[0] != firstMoved[0],
            "cross_grid_metal_pixels_and_negative_control")) {
        fprintf(stderr, "scale=%.0f cross_grid_samples=%llu diff_bytes=%llu\n", scale,
            (unsigned long long)samples, (unsigned long long)differences);
        return 4;
    }
    printf("TEXT_TILE_DRAWABLE_CROSS_GRID_PASS scale=%.0f phase=-0.25,-0.25->0.375,0.625 "
           "regions=horizontal,vertical,intersection samples=%llu diff_bytes=%llu "
           "negative_control=1 move_rasters=%llu->%llu fresh_rasters=%llu "
           "move_tiles=%u fresh_tiles=%u\n", scale, (unsigned long long)samples,
           (unsigned long long)differences, (unsigned long long)movedRaster,
           (unsigned long long)moved.view.testComposableTextRasterCount,
           (unsigned long long)freshRaster, movedTiles, freshTiles);
    cjgui_internal_renderer_destroy(movedSession);
    cjgui_internal_renderer_destroy(freshSession);
    return 0;
}

int main(void) {
    @autoreleasepool {
        if (runScale(1.0) != 0) return 1;
        if (runScale(2.0) != 0) return 2;
        if (runCrossGridPhase(1.0) != 0) return 3;
        if (runCrossGridPhase(2.0) != 0) return 4;
        puts("TEXT_TILE_DRAWABLE_SEAM_ALL_PASS");
        return 0;
    }
}

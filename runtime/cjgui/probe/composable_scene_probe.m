#import "../native/cjgui_internal_renderer.h"
#import <AppKit/AppKit.h>

@interface NSObject (CJGuiComposableProbeRoute)
- (void)routeScrollAtPoint:(NSPoint)point deltaY:(CGFloat)deltaY;
- (void)accessibilitySetValue:(id)value;
- (BOOL)accessibilityPerformPress;
- (BOOL)accessibilityFocused;
- (BOOL)accessibilityIsEnabled;
- (BOOL)accessibilityIsAttributeSettable:(NSAccessibilityAttributeName)attribute;
@end

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static int require(int condition, const char *message) {
    if (!condition) { fprintf(stderr, "composable scene probe: failed %s\n", message); }
    return condition;
}

static int require_bgra(uint8_t blue, uint8_t green, uint8_t red, uint8_t alpha,
                        uint8_t expectedBlue, uint8_t expectedGreen, uint8_t expectedRed,
                        uint8_t expectedAlpha, const char *message) {
    const int tolerance = 10;
    int valid = abs((int)blue - (int)expectedBlue) <= tolerance &&
                abs((int)green - (int)expectedGreen) <= tolerance &&
                abs((int)red - (int)expectedRed) <= tolerance &&
                abs((int)alpha - (int)expectedAlpha) <= tolerance;
    if (!valid) {
        fprintf(stderr, "composable scene probe: failed %s actual=%u,%u,%u,%u expected=%u,%u,%u,%u\n",
                message, blue, green, red, alpha, expectedBlue, expectedGreen, expectedRed, expectedAlpha);
    }
    return valid;
}

// The exact-pixel asset deliberately has a non-square 2:1 aspect ratio and
// large interior color blocks.  It includes opaque, transparent and
// half-transparent texels, so FIT/FILL/clip and blend assertions do not
// depend on decorative artwork or an arbitrary "opaque enough" sample.
static int write_pixel_fixture(char *outPath, size_t outPathSize) {
    const NSInteger width = 32, height = 16;
    NSBitmapImageRep *bitmap = [[NSBitmapImageRep alloc]
        initWithBitmapDataPlanes:NULL pixelsWide:width pixelsHigh:height bitsPerSample:8
        samplesPerPixel:4 hasAlpha:YES isPlanar:NO colorSpaceName:NSDeviceRGBColorSpace
        bitmapFormat:NSBitmapFormatAlphaNonpremultiplied bytesPerRow:0 bitsPerPixel:0];
    if (!bitmap || !bitmap.bitmapData) return 0;
    unsigned char *pixels = bitmap.bitmapData;
    const NSInteger stride = bitmap.bytesPerRow;
    for (NSInteger y = 0; y < height; y++) {
        for (NSInteger x = 0; x < width; x++) {
            unsigned char *pixel = pixels + y * stride + x * 4;
            if (x < 8) {
                pixel[0] = 240; pixel[1] = 24; pixel[2] = 32; pixel[3] = 255; // opaque red
            } else if (x < 16) {
                pixel[0] = 16; pixel[1] = 224; pixel[2] = 48; pixel[3] = 255; // opaque green
            } else if (x < 24) {
                pixel[0] = 32; pixel[1] = 96; pixel[2] = 224; pixel[3] = 128; // translucent blue
            } else {
                pixel[0] = 0; pixel[1] = 0; pixel[2] = 0; pixel[3] = 0; // transparent
            }
        }
    }
    NSString *fixturePath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"cjgui-composable-pixel-fixture.png"];
    NSData *png = [bitmap representationUsingType:NSBitmapImageFileTypePNG properties:@{}];
    if (!png || ![png writeToFile:fixturePath atomically:YES]) return 0;
    return snprintf(outPath, outPathSize, "%s", fixturePath.fileSystemRepresentation) > 0;
}

static int capture_composable_pixel(uint64_t session, uint32_t x, uint32_t y,
                                    uint8_t *outBlue, uint8_t *outGreen,
                                    uint8_t *outRed, uint8_t *outAlpha) {
    CjguiInternalRendererClearColor clear = { 0.08, 0.16, 0.20, 1.0 };
    CjguiInternalRendererFrameObservation frame = {0};
    if (cjgui_internal_renderer_test_request_composable_drawable_pixel(session, x, y) != CJGUI_INTERNAL_RENDERER_OK) return 0;
    if (cjgui_internal_renderer_present_clear(session, &clear, &frame) != CJGUI_INTERNAL_RENDERER_OK) return 0;
    return cjgui_internal_renderer_test_composable_drawable_pixel(session, outBlue, outGreen, outRed, outAlpha) == CJGUI_INTERNAL_RENDERER_OK;
}

// A scene accepts an image's declared loading state immediately; the normal
// Cangjie window later observes resourceCompletionVersion and submits the
// same declaration again.  This probe must model that bounded application
// turn instead of sampling the placeholder before the main run loop receives
// the loader completion.
static int wait_for_composable_image_ready(uint64_t session, const char *path,
                                           const char *identifier, uint64_t version) {
    NSDate *deadline = [NSDate dateWithTimeIntervalSinceNow:2.0];
    while ([deadline timeIntervalSinceNow] > 0.0) {
        uint32_t state = 0;
        if (cjgui_internal_renderer_composable_image_resource_state(session, path, identifier, version, &state) != CJGUI_INTERNAL_RENDERER_OK) return 0;
        if (state == 2) return 1; // CjguiComposableImageResourceReady
        if (state == 3) return 0; // CjguiComposableImageResourceFailed
        @autoreleasepool {
            NSDate *slice = [NSDate dateWithTimeIntervalSinceNow:0.01];
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:slice];
        }
    }
    return 0;
}

// The full block glyph makes one interior scene pixel deterministic across
// system fonts.  The first assertion is red until text joins the Metal command
// stream; the second proves that a later opaque shape then covers that same
// text pixel in painter order.
static int verify_cross_type_text_ordering(uint64_t session) {
    CjguiInternalRendererComposableNode root = {
        .nodeId = 840, .projectionVersion = 84,
        .x = 0, .y = 0, .width = 420, .height = 180,
        .clipX = 0, .clipY = 0, .clipWidth = 420, .clipHeight = 180,
        .nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_VERTICAL,
        .fillRed = 0.04, .fillGreen = 0.08, .fillBlue = 0.14, .fillAlpha = 1.0
    };
    CjguiInternalRendererComposableNode text = root;
    text.nodeId = 841; text.x = 40; text.y = 20; text.width = 200; text.height = 140;
    text.clipX = 40; text.clipY = 20; text.clipWidth = 200; text.clipHeight = 140;
    text.nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT;
    text.fillAlpha = 0.0; text.fontSize = 96.0;
    text.textRed = 1.0; text.textGreen = 0.0; text.textBlue = 1.0; text.textAlpha = 1.0;
    CjguiInternalRendererFrameObservation frame = {0};
    if (!require(cjgui_internal_renderer_configure_composable_scene(session, 84, 2) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_set_composable_scene_node(session, 0, &root, "order-root", "", "", "", 0) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_set_composable_scene_node(session, 1, &text, "order-text", "█", "", "", 0) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_present_composable_scene(session, &frame) == CJGUI_INTERNAL_RENDERER_OK,
                 "stage_cross_type_text_before_cover")) return 0;
    uint8_t blue = 0, green = 0, red = 0, alpha = 0;
    const uint32_t textPixelX = 70, textPixelY = 80;
    if (!(capture_composable_pixel(session, textPixelX, textPixelY, &blue, &green, &red, &alpha) &&
          require_bgra(blue, green, red, alpha, 255, 0, 255, 255, "text_glyph_participates_in_ordered_gpu_scene"))) return 0;

    root.projectionVersion = 85; text.projectionVersion = 85;
    CjguiInternalRendererComposableNode cover = root;
    cover.nodeId = 842; cover.nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_VERTICAL;
    cover.fillRed = 0.08; cover.fillGreen = 0.18; cover.fillBlue = 0.82; cover.fillAlpha = 1.0;
    cover.textAlpha = 0.0;
    if (!require(cjgui_internal_renderer_configure_composable_scene(session, 85, 3) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_set_composable_scene_node(session, 0, &root, "order-root", "", "", "", 0) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_set_composable_scene_node(session, 1, &text, "order-text", "█", "", "", 0) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_set_composable_scene_node(session, 2, &cover, "order-cover", "", "", "", 0) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_present_composable_scene(session, &frame) == CJGUI_INTERNAL_RENDERER_OK,
                 "stage_cross_type_opaque_cover")) return 0;
    return capture_composable_pixel(session, textPixelX, textPixelY, &blue, &green, &red, &alpha) &&
           require_bgra(blue, green, red, alpha, 209, 46, 20, 255, "later_shape_covers_earlier_text");
}

// Direction-bearing text must retain the AppKit scene's top-to-bottom
// orientation after bitmap upload and the Metal texture draw. A bold F gives
// us an opaque upper crossbar and a deliberately empty lower-right sample;
// unlike the full-block glyph used by painter-order coverage, it fails if
// either raster or texture coordinates vertically mirror the final pixels.
static int verify_static_text_orientation(uint64_t session) {
    CjguiInternalRendererComposableNode root = {
        .nodeId = 843, .projectionVersion = 843,
        .x = 0, .y = 0, .width = 420, .height = 180,
        .clipX = 0, .clipY = 0, .clipWidth = 420, .clipHeight = 180,
        .nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_VERTICAL,
        .fillRed = 0.04, .fillGreen = 0.08, .fillBlue = 0.14, .fillAlpha = 1.0
    };
    CjguiInternalRendererComposableNode text = root;
    text.nodeId = 844; text.x = 40; text.y = 20; text.width = 200; text.height = 140;
    text.clipX = 40; text.clipY = 20; text.clipWidth = 200; text.clipHeight = 140;
    text.nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT;
    text.fillAlpha = 0.0; text.fontSize = 96.0; text.fontWeight = 1;
    text.textRed = 1.0; text.textGreen = 0.0; text.textBlue = 1.0; text.textAlpha = 1.0;
    CjguiInternalRendererFrameObservation frame = {0};
    if (!require(cjgui_internal_renderer_configure_composable_scene(session, 843, 2) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_set_composable_scene_node(session, 0, &root, "direction-root", "", "", "", 0) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_set_composable_scene_node(session, 1, &text, "direction-text", "F", "", "", 0) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_present_composable_scene(session, &frame) == CJGUI_INTERNAL_RENDERER_OK,
                 "stage_direction_bearing_static_text")) return 0;
    uint8_t upperBlue = 0, upperGreen = 0, upperRed = 0, upperAlpha = 0;
    uint8_t lowerBlue = 0, lowerGreen = 0, lowerRed = 0, lowerAlpha = 0;
    if (!capture_composable_pixel(session, 85, 55, &upperBlue, &upperGreen, &upperRed, &upperAlpha) ||
        !capture_composable_pixel(session, 85, 105, &lowerBlue, &lowerGreen, &lowerRed, &lowerAlpha)) return 0;
    printf("CJGUI_TEXT_DIRECTION upper=%u,%u,%u,%u lower=%u,%u,%u,%u\n",
           upperBlue, upperGreen, upperRed, upperAlpha, lowerBlue, lowerGreen, lowerRed, lowerAlpha);
    return require_bgra(upperBlue, upperGreen, upperRed, upperAlpha, 255, 0, 255, 255,
                        "upright_static_text_upper_crossbar") &&
           require_bgra(lowerBlue, lowerGreen, lowerRed, lowerAlpha, 36, 20, 10, 255,
                        "upright_static_text_lower_right_is_empty");
}

// A texture node is also a strict painter-order boundary.  This uses the
// already-loaded deterministic image fixture so the final pixel proves that
// a later image covers an earlier text glyph through the production resource
// path, not merely through same-pipeline rectangle ordering.
static int verify_later_image_covers_text(uint64_t session, const char *fixturePath) {
    CjguiInternalRendererComposableNode root = {
        .nodeId = 850, .projectionVersion = 85,
        .x = 0, .y = 0, .width = 420, .height = 180,
        .clipX = 0, .clipY = 0, .clipWidth = 420, .clipHeight = 180,
        .nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_VERTICAL,
        .fillRed = 0.04, .fillGreen = 0.08, .fillBlue = 0.14, .fillAlpha = 1.0
    };
    CjguiInternalRendererComposableNode text = root;
    // Preserve the previously verified full-block local pixel at (70, 40)
    // while placing the known opaque-green FIT fixture over that exact point.
    text.nodeId = 851; text.x = 40; text.y = -20; text.width = 200; text.height = 140;
    text.clipX = 40; text.clipY = 0; text.clipWidth = 200; text.clipHeight = 120;
    text.nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT;
    text.fillAlpha = 0.0; text.fontSize = 96.0;
    text.textRed = 1.0; text.textGreen = 0.0; text.textBlue = 1.0; text.textAlpha = 1.0;
    CjguiInternalRendererComposableNode image = root;
    image.nodeId = 852; image.x = 40; image.y = 10; image.width = 80; image.height = 80;
    image.clipX = 40; image.clipY = 10; image.clipWidth = 80; image.clipHeight = 80;
    image.nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_IMAGE; image.imageContentMode = 1;
    image.fillAlpha = 0.0; image.borderWidth = 0;
    CjguiInternalRendererFrameObservation frame = {0};
    if (!require(cjgui_internal_renderer_configure_composable_scene(session, 85, 3) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_set_composable_scene_node(session, 0, &root, "image-order-root", "", "", "", 0) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_set_composable_scene_node(session, 1, &text, "image-order-text", "█", "", "", 0) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_set_composable_scene_node(session, 2, &image, "image-order-cover", "", fixturePath, "fixture-v1", 1) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_present_composable_scene(session, &frame) == CJGUI_INTERNAL_RENDERER_OK,
                 "stage_later_image_covers_text")) return 0;
    uint8_t blue = 0, green = 0, red = 0, alpha = 0;
    return capture_composable_pixel(session, 70, 40, &blue, &green, &red, &alpha) &&
           require_bgra(blue, green, red, alpha, 48, 224, 16, 255, "later_image_covers_earlier_text");
}

// The TextKit proxy owns IME and selection state, but it must never regain a
// second visible surface while a field is active.  This starts with an empty
// projection, types a deterministic glyph through the real first responder,
// then reads the Metal drawable before a Cangjie value refresh arrives.  The
// later cover proves that the live caret/text presentation still participates
// in painter order rather than being painted by the AppKit overlay afterwards.
static int verify_active_input_stays_in_gpu_order(uint64_t session) {
    CjguiInternalRendererComposableNode root = {
        .nodeId = 870, .projectionVersion = 87,
        .x = 0, .y = 0, .width = 420, .height = 180,
        .clipX = 0, .clipY = 0, .clipWidth = 420, .clipHeight = 180,
        .nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_VERTICAL,
        .fillRed = 0.04, .fillGreen = 0.08, .fillBlue = 0.14, .fillAlpha = 1.0
    };
    CjguiInternalRendererComposableNode input = root;
    input.nodeId = 871; input.x = 40; input.y = 20; input.width = 200; input.height = 140;
    input.clipX = 40; input.clipY = 20; input.clipWidth = 200; input.clipHeight = 140;
    input.nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT_INPUT;
    input.isInteractive = 1; input.fillAlpha = 0.0; input.fontSize = 96.0;
    input.textRed = 1.0; input.textGreen = 0.0; input.textBlue = 1.0; input.textAlpha = 1.0;
    CjguiInternalRendererFrameObservation frame = {0};
    if (!require(cjgui_internal_renderer_configure_composable_scene(session, 87, 2) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_set_composable_scene_node(session, 0, &root, "active-order-root", "", "", "", 0) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_set_composable_scene_node(session, 1, &input, "", "", "", "", 0) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_present_composable_scene(session, &frame) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_test_insert_composable_text(session, 1, "█") == CJGUI_INTERNAL_RENDERER_OK,
                 "stage_active_input_live_text")) return 0;
    uint8_t blue = 0, green = 0, red = 0, alpha = 0;
    const uint32_t textPixelX = 70, textPixelY = 80;
    if (!(capture_composable_pixel(session, textPixelX, textPixelY, &blue, &green, &red, &alpha) &&
          require_bgra(blue, green, red, alpha, 255, 0, 255, 255, "active_textkit_input_updates_gpu_texture"))) return 0;

    root.projectionVersion = 88; input.projectionVersion = 88;
    input.preservesActiveLocalText = 1;
    CjguiInternalRendererComposableNode cover = root;
    cover.nodeId = 872; cover.nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_VERTICAL;
    cover.fillRed = 0.08; cover.fillGreen = 0.18; cover.fillBlue = 0.82; cover.fillAlpha = 1.0;
    cover.textAlpha = 0.0;
    if (!require(cjgui_internal_renderer_configure_composable_scene(session, 88, 3) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_set_composable_scene_node(session, 0, &root, "active-order-root", "", "", "", 0) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_set_composable_scene_node(session, 1, &input, "", "", "", "", 0) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_set_composable_scene_node(session, 2, &cover, "active-order-cover", "", "", "", 0) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_present_composable_scene(session, &frame) == CJGUI_INTERNAL_RENDERER_OK,
                 "stage_active_input_later_cover")) return 0;
    return capture_composable_pixel(session, textPixelX, textPixelY, &blue, &green, &red, &alpha) &&
           require_bgra(blue, green, red, alpha, 209, 46, 20, 255, "later_shape_covers_active_textkit_input");
}

// A focused single-line field owns a scene-derived texture just as a focused
// multiline field does.  A transient allocation rejection must retain that
// last texture and settle with the same one-turn bounded retry contract.
static int verify_active_single_text_resource_failure_retries(uint64_t session) {
    CjguiInternalRendererComposableNode root = {
        .nodeId = 873, .projectionVersion = 86,
        .x = 0, .y = 0, .width = 420, .height = 180,
        .clipX = 0, .clipY = 0, .clipWidth = 420, .clipHeight = 180,
        .nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_VERTICAL,
        .fillRed = 0.04, .fillGreen = 0.08, .fillBlue = 0.14, .fillAlpha = 1.0
    };
    CjguiInternalRendererComposableNode input = root;
    input.nodeId = 874; input.x = 40; input.y = 20; input.width = 200; input.height = 140;
    input.clipX = 40; input.clipY = 20; input.clipWidth = 200; input.clipHeight = 140;
    input.nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT_INPUT;
    input.isInteractive = 1; input.fillAlpha = 0.0; input.fontSize = 96.0;
    input.textRed = 1.0; input.textGreen = 0.0; input.textBlue = 1.0; input.textAlpha = 1.0;
    CjguiInternalRendererFrameObservation frame = {0};
    if (!require(cjgui_internal_renderer_configure_composable_scene(session, 86, 2) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_set_composable_scene_node(session, 0, &root, "active-single-resource-root", "", "", "", 0) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_set_composable_scene_node(session, 1, &input, "", "", "", "", 0) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_present_composable_scene(session, &frame) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_test_insert_composable_text(session, 1, "M") == CJGUI_INTERNAL_RENDERER_OK,
                 "stage_active_single_resource_baseline")) return 0;
    uint64_t retainedBytes = 0; float retainedX = 0, retainedY = 0, retainedWidth = 0, retainedHeight = 0;
    if (!require(cjgui_internal_renderer_test_composable_text_resource_stats(session, 1, &retainedBytes, &retainedX, &retainedY, &retainedWidth, &retainedHeight) == CJGUI_INTERNAL_RENDERER_OK &&
                 retainedBytes > 0 &&
                 cjgui_internal_renderer_test_set_composable_selection(session, 1, 0, 1) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_test_set_composable_text_preparation_failures(session, 1) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_test_insert_composable_text(session, 1, "N") == CJGUI_INTERNAL_RENDERER_OK,
                 "stage_active_single_resource_failure")) return 0;
    uint8_t textureFailed = 0; uint32_t retryCount = 0; uint32_t remainingFailures = 1;
    NSDate *retryDeadline = [NSDate dateWithTimeIntervalSinceNow:0.10];
    do {
        NSDate *slice = [NSDate dateWithTimeIntervalSinceNow:0.01];
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:slice];
        if (cjgui_internal_renderer_test_composable_active_text_resource_state(session, &textureFailed, &retryCount) != CJGUI_INTERNAL_RENDERER_OK ||
            cjgui_internal_renderer_test_composable_text_preparation_failures_remaining(session, &remainingFailures) != CJGUI_INTERNAL_RENDERER_OK) return 0;
    } while ((remainingFailures != 0 || textureFailed != 0 || retryCount != 0) && [retryDeadline timeIntervalSinceNow] > 0.0);
    if (!require(remainingFailures == 0 && textureFailed == 0 && retryCount == 0 &&
                 cjgui_internal_renderer_test_composable_text_resource_stats(session, 1, &retainedBytes, &retainedX, &retainedY, &retainedWidth, &retainedHeight) == CJGUI_INTERNAL_RENDERER_OK &&
                 retainedBytes > 0,
                 "active_single_failure_retains_previous_texture_and_consumes_one_retry")) return 0;
    return require(textureFailed == 0 && retryCount == 0 &&
                   cjgui_internal_renderer_test_composable_text_matches(session, "N") == CJGUI_INTERNAL_RENDERER_OK,
                   "active_single_failure_retries_without_new_input");
}

// A selection/caret move is presentation-only state of the one active
// TextKit input graph.  It must update the ordered GPU scene without creating
// a replacement body bitmap or issuing another texture upload.  The sampled
// pixel also keeps this from becoming a counter-only no-op: selecting the
// first visible glyph must change the painted background.
static int verify_active_selection_reuses_content_resource(uint64_t session) {
    CjguiInternalRendererComposableNode root = {
        .nodeId = 875, .projectionVersion = 87,
        .x = 0, .y = 0, .width = 420, .height = 180,
        .clipX = 0, .clipY = 0, .clipWidth = 420, .clipHeight = 180,
        .nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_VERTICAL,
        .fillRed = 0.04, .fillGreen = 0.08, .fillBlue = 0.14, .fillAlpha = 1.0
    };
    CjguiInternalRendererComposableNode input = root;
    input.nodeId = 876; input.x = 40; input.y = 20; input.width = 200; input.height = 140;
    input.clipX = 40; input.clipY = 20; input.clipWidth = 200; input.clipHeight = 140;
    input.nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT;
    input.isInteractive = 1; input.fillAlpha = 0.0; input.fontSize = 96.0;
    input.textRed = 1.0; input.textGreen = 0.0; input.textBlue = 1.0; input.textAlpha = 1.0;
    CjguiInternalRendererFrameObservation frame = {0};
    if (!require(cjgui_internal_renderer_configure_composable_scene(session, 87, 2) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_set_composable_scene_node(session, 0, &root, "selection-reuse-root", "", "", "", 0) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_set_composable_scene_node(session, 1, &input, "", "MMMM\nNN", "", "", 0) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_present_composable_scene(session, &frame) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_test_set_composable_selection(session, 1, 0, 0) == CJGUI_INTERNAL_RENDERER_OK,
                 "stage_active_selection_reuse_baseline")) return 0;
    uint64_t beforeRasterCount = 0, beforeRasterBytes = 0, beforeRasterMicros = 0;
    uint64_t beforeUploadCount = 0, beforeUploadBytes = 0, beforeUploadMicros = 0;
    uint8_t beforeBlue = 0, beforeGreen = 0, beforeRed = 0, beforeAlpha = 0;
    if (!require(cjgui_internal_renderer_test_composable_text_work_stats(session, &beforeRasterCount, &beforeRasterBytes,
                                                                          &beforeRasterMicros, &beforeUploadCount,
                                                                          &beforeUploadBytes, &beforeUploadMicros) == CJGUI_INTERNAL_RENDERER_OK &&
                 capture_composable_pixel(session, 48, 28, &beforeBlue, &beforeGreen, &beforeRed, &beforeAlpha),
                 "capture_active_selection_reuse_before")) return 0;
    if (!require(cjgui_internal_renderer_test_set_composable_selection(session, 1, 0, 1) == CJGUI_INTERNAL_RENDERER_OK,
                 "move_active_multiline_selection_without_body_edit")) return 0;
    uint64_t afterRasterCount = 0, afterRasterBytes = 0, afterRasterMicros = 0;
    uint64_t afterUploadCount = 0, afterUploadBytes = 0, afterUploadMicros = 0;
    uint8_t afterBlue = 0, afterGreen = 0, afterRed = 0, afterAlpha = 0;
    if (!require(cjgui_internal_renderer_test_composable_text_work_stats(session, &afterRasterCount, &afterRasterBytes,
                                                                          &afterRasterMicros, &afterUploadCount,
                                                                          &afterUploadBytes, &afterUploadMicros) == CJGUI_INTERNAL_RENDERER_OK &&
                 capture_composable_pixel(session, 48, 28, &afterBlue, &afterGreen, &afterRed, &afterAlpha) &&
                 afterRasterCount == beforeRasterCount && afterRasterBytes == beforeRasterBytes &&
                 afterRasterMicros == beforeRasterMicros && afterUploadCount == beforeUploadCount &&
                 afterUploadBytes == beforeUploadBytes && afterUploadMicros == beforeUploadMicros &&
                 (afterBlue != beforeBlue || afterGreen != beforeGreen || afterRed != beforeRed || afterAlpha != beforeAlpha),
                 "selection_reuses_body_texture_and_updates_ordered_pixels")) return 0;
    beforeRasterCount = afterRasterCount; beforeRasterBytes = afterRasterBytes; beforeRasterMicros = afterRasterMicros;
    beforeUploadCount = afterUploadCount; beforeUploadBytes = afterUploadBytes; beforeUploadMicros = afterUploadMicros;
    if (!require(cjgui_internal_renderer_test_set_composable_selection(session, 1, 1, 1) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_test_composable_text_work_stats(session, &afterRasterCount, &afterRasterBytes,
                                                                          &afterRasterMicros, &afterUploadCount,
                                                                          &afterUploadBytes, &afterUploadMicros) == CJGUI_INTERNAL_RENDERER_OK &&
                 afterRasterCount == beforeRasterCount && afterRasterBytes == beforeRasterBytes &&
                 afterRasterMicros == beforeRasterMicros && afterUploadCount == beforeUploadCount &&
                 afterUploadBytes == beforeUploadBytes && afterUploadMicros == beforeUploadMicros,
                 "caret_reuses_body_texture_without_upload")) return 0;
    return require(cjgui_internal_renderer_test_composable_text_matches(session, "MMMM\nNN") == CJGUI_INTERNAL_RENDERER_OK,
                   "selection_reuse_keeps_textkit_owner_value");
}

// Sparse Cangjie submission intentionally shares untouched node objects with
// the accepted scene. A failed update to another text node must therefore not
// clear the active input's presentation-only selection before its candidate
// can be admitted. This is the COW boundary for direct decoration geometry.
static int verify_failed_sparse_candidate_keeps_active_text_decorations(uint64_t session) {
    CjguiInternalRendererComposableNode root = {
        .nodeId = 877, .projectionVersion = 88,
        .x = 0, .y = 0, .width = 420, .height = 180,
        .clipX = 0, .clipY = 0, .clipWidth = 420, .clipHeight = 180,
        .nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_VERTICAL,
        .fillRed = 0.04, .fillGreen = 0.08, .fillBlue = 0.14, .fillAlpha = 1.0
    };
    CjguiInternalRendererComposableNode input = root;
    input.nodeId = 878; input.x = 40; input.y = 20; input.width = 200; input.height = 140;
    input.clipX = 40; input.clipY = 20; input.clipWidth = 200; input.clipHeight = 140;
    input.nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT;
    input.isInteractive = 1; input.fillAlpha = 0.0; input.fontSize = 96.0;
    input.textRed = 1.0; input.textGreen = 0.0; input.textBlue = 1.0; input.textAlpha = 1.0;
    CjguiInternalRendererComposableNode staticText = root;
    staticText.nodeId = 879; staticText.x = 260; staticText.y = 20; staticText.width = 120; staticText.height = 48;
    staticText.clipX = 260; staticText.clipY = 20; staticText.clipWidth = 120; staticText.clipHeight = 48;
    staticText.nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT;
    staticText.fillAlpha = 0.0; staticText.fontSize = 18.0;
    staticText.textRed = 0.8; staticText.textGreen = 0.9; staticText.textBlue = 1.0; staticText.textAlpha = 1.0;
    CjguiInternalRendererFrameObservation frame = {0};
    if (!require(cjgui_internal_renderer_configure_composable_scene(session, 88, 3) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_set_composable_scene_node(session, 0, &root, "decoration-cow-root", "", "", "", 0) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_set_composable_scene_node(session, 1, &input, "", "MMMM\nNN", "", "", 0) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_set_composable_scene_node(session, 2, &staticText, "", "stable", "", "", 0) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_present_composable_scene(session, &frame) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_test_set_composable_selection(session, 1, 0, 1) == CJGUI_INTERNAL_RENDERER_OK,
                 "stage_sparse_decoration_cow_baseline")) return 0;
    uint8_t beforeBlue = 0, beforeGreen = 0, beforeRed = 0, beforeAlpha = 0;
    if (!require(capture_composable_pixel(session, 48, 28, &beforeBlue, &beforeGreen, &beforeRed, &beforeAlpha),
                 "capture_sparse_decoration_cow_before")) return 0;
    staticText.projectionVersion = 89;
    uint64_t sceneVersion = 0;
    if (!require(cjgui_internal_renderer_configure_composable_scene(session, 89, 3) == CJGUI_INTERNAL_RENDERER_OK &&
                 // Leave index 1 untouched: it deliberately aliases the
                 // accepted focused input until resource preparation COWs it.
                 cjgui_internal_renderer_set_composable_scene_node(session, 2, &staticText, "", "candidate", "", "", 0) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_test_set_composable_text_preparation_failures(session, 1) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_present_composable_scene(session, &frame) == CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR &&
                 cjgui_internal_renderer_test_composable_scene_version(session, &sceneVersion) == CJGUI_INTERNAL_RENDERER_OK && sceneVersion == 88,
                 "sparse_candidate_text_failure")) return 0;
    uint8_t afterBlue = 0, afterGreen = 0, afterRed = 0, afterAlpha = 0;
    return require(capture_composable_pixel(session, 48, 28, &afterBlue, &afterGreen, &afterRed, &afterAlpha) &&
                   afterBlue == beforeBlue && afterGreen == beforeGreen && afterRed == beforeRed && afterAlpha == beforeAlpha,
                   "failed_sparse_candidate_keeps_accepted_selection_pixels");
}

// Multiline input previously remained an AppKit overlay after every Metal
// node.  Exercise both the admitted text texture and the live TextKit proxy:
// a later opaque shape must cover the same full-block pixel in either case.
static int verify_multiline_text_stays_in_gpu_order(uint64_t session) {
    fprintf(stderr, "[multiline-probe] stage-static\n"); fflush(stderr);
    CjguiInternalRendererComposableNode root = {
        .nodeId = 880, .projectionVersion = 89,
        .x = 0, .y = 0, .width = 420, .height = 180,
        .clipX = 0, .clipY = 0, .clipWidth = 420, .clipHeight = 180,
        .nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_VERTICAL,
        .fillRed = 0.04, .fillGreen = 0.08, .fillBlue = 0.14, .fillAlpha = 1.0
    };
    CjguiInternalRendererComposableNode input = root;
    input.nodeId = 881; input.x = 40; input.y = 20; input.width = 200; input.height = 140;
    input.clipX = 40; input.clipY = 20; input.clipWidth = 200; input.clipHeight = 140;
    input.nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT;
    input.isInteractive = 1; input.fillAlpha = 0.0; input.fontSize = 96.0;
    input.textRed = 1.0; input.textGreen = 0.0; input.textBlue = 1.0; input.textAlpha = 1.0;
    CjguiInternalRendererFrameObservation frame = {0};
    if (!require(cjgui_internal_renderer_configure_composable_scene(session, 89, 2) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_set_composable_scene_node(session, 0, &root, "multiline-root", "", "", "", 0) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_set_composable_scene_node(session, 1, &input, "", "█\nsecond", "", "", 0) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_present_composable_scene(session, &frame) == CJGUI_INTERNAL_RENDERER_OK,
                 "stage_multiline_gpu_text")) return 0;
    uint8_t blue = 0, green = 0, red = 0, alpha = 0;
    // The live M's left stem is fully opaque at this point; the former x=70
    // sample was inside its counter and did not prove a failed raster.
    const uint32_t textPixelX = 57, textPixelY = 80;
    if (!(capture_composable_pixel(session, textPixelX, textPixelY, &blue, &green, &red, &alpha) &&
          require_bgra(blue, green, red, alpha, 255, 0, 255, 255, "multiline_glyph_participates_in_ordered_gpu_scene"))) return 0;
    // Reset to an empty authoritative projection before typing.  The static
    // fixture intentionally wraps several lines; inserting at its end would
    // correctly reveal the caret by scrolling the first glyph out of this
    // sample point, which is a different behavior from live GPU admission.
    root.projectionVersion = 90; input.projectionVersion = 90;
    if (!require(cjgui_internal_renderer_configure_composable_scene(session, 90, 2) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_set_composable_scene_node(session, 0, &root, "multiline-root", "", "", "", 0) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_set_composable_scene_node(session, 1, &input, "", "", "", "", 0) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_present_composable_scene(session, &frame) == CJGUI_INTERNAL_RENDERER_OK,
                 "reset_multiline_active_fixture")) return 0;
    fprintf(stderr, "[multiline-probe] stage-active\n"); fflush(stderr);
    // U+2588 is accepted by NSString fallback drawing but this SDK's active
    // TextKit graph reports it as NSGlyphPropertyNull.  Use a Latin glyph here
    // so this probe exercises an emitted glyph, not the missing-glyph path.
    if (!require(cjgui_internal_renderer_test_insert_composable_text(session, 1, "M") == CJGUI_INTERNAL_RENDERER_OK,
                 "multiline_live_textkit_insert")) return 0;
    if (!(capture_composable_pixel(session, textPixelX, textPixelY, &blue, &green, &red, &alpha) &&
          require_bgra(blue, green, red, alpha, 255, 0, 255, 255, "active_multiline_textkit_updates_gpu_texture"))) return 0;
    // Keep this compact coverage on the one active TextKit graph.  The
    // testing build logs the actual UTF-16/glyph/font state for each case;
    // selection still goes through the production composed-range adapter.
    if (!require(cjgui_internal_renderer_test_set_composable_selection(session, 1, 0, 1) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_test_insert_composable_text(session, 1, "A中🙂B") == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_test_composable_text_matches(session, "A中🙂B") == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_test_set_composable_selection(session, 1, 1, 4) == CJGUI_INTERNAL_RENDERER_OK,
                 "multiline_mixed_script_input_display_selection")) return 0;
    if (!require(cjgui_internal_renderer_test_set_composable_selection(session, 1, 0, 5) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_test_insert_composable_text(session, 1, "中") == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_test_composable_text_matches(session, "中") == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_test_set_composable_selection(session, 1, 0, 1) == CJGUI_INTERNAL_RENDERER_OK,
                 "multiline_cjk_input_display_selection")) return 0;
    if (!require(cjgui_internal_renderer_test_insert_composable_text(session, 1, "🙂") == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_test_composable_text_matches(session, "🙂") == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_test_set_composable_selection(session, 1, 0, 2) == CJGUI_INTERNAL_RENDERER_OK,
                 "multiline_emoji_input_display_selection")) return 0;
    if (!require(cjgui_internal_renderer_test_insert_composable_text(session, 1, "👩‍💻") == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_test_composable_text_matches(session, "👩‍💻") == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_test_set_composable_selection(session, 1, 0, 5) == CJGUI_INTERNAL_RENDERER_OK,
                 "multiline_emoji_zwj_input_display_selection")) return 0;
    // Replace and delete an entire ZWJ cluster through the production adapter.
    // This specifically exercises the zero-length deletion boundary used by
    // deferred fallback preparation, not merely selection normalization.
    if (!require(cjgui_internal_renderer_test_insert_composable_text(session, 1, "A👩‍💻中") == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_test_set_composable_selection(session, 1, 1, 6) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_test_insert_composable_text(session, 1, "") == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_test_composable_text_matches(session, "A中") == CJGUI_INTERNAL_RENDERER_OK,
                 "multiline_zwj_replacement_and_zero_length_delete")) return 0;
    // An active-text allocation failure must retain its old tile, then retry
    // once on the next main-loop turn even when there is no further input.
    if (!require(cjgui_internal_renderer_test_set_composable_selection(session, 1, 0, 2) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_test_set_composable_text_preparation_failures(session, 1) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_test_insert_composable_text(session, 1, "M") == CJGUI_INTERNAL_RENDERER_OK,
                 "stage_active_multiline_text_resource_failure")) return 0;
    uint8_t textureFailed = 0; uint32_t retryCount = 0; uint64_t retainedBytes = 0;
    float retainedX = 0, retainedY = 0, retainedWidth = 0, retainedHeight = 0;
    if (!require(cjgui_internal_renderer_test_composable_active_text_resource_state(session, &textureFailed, &retryCount) == CJGUI_INTERNAL_RENDERER_OK &&
                 textureFailed == 1 && retryCount == 1 &&
                 cjgui_internal_renderer_test_composable_text_resource_stats(session, 1, &retainedBytes, &retainedX, &retainedY, &retainedWidth, &retainedHeight) == CJGUI_INTERNAL_RENDERER_OK &&
                 retainedBytes > 0,
                 "active_multiline_failure_retains_previous_texture")) return 0;
    NSDate *retryDeadline = [NSDate dateWithTimeIntervalSinceNow:0.10];
    // One runMode call may return for an unrelated AppKit source before the
    // queued main-dispatch retry runs.  Poll the bounded observation until
    // that one deferred turn has either settled or the deadline expires.
    do {
        NSDate *slice = [NSDate dateWithTimeIntervalSinceNow:0.01];
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:slice];
        if (cjgui_internal_renderer_test_composable_active_text_resource_state(session, &textureFailed, &retryCount) != CJGUI_INTERNAL_RENDERER_OK) return 0;
    } while ((textureFailed != 0 || retryCount != 0) && [retryDeadline timeIntervalSinceNow] > 0.0);
    if (!require(cjgui_internal_renderer_test_composable_active_text_resource_state(session, &textureFailed, &retryCount) == CJGUI_INTERNAL_RENDERER_OK &&
                 textureFailed == 0 && retryCount == 0 &&
                 cjgui_internal_renderer_test_composable_text_matches(session, "M") == CJGUI_INTERNAL_RENDERER_OK,
                 "active_multiline_failure_retries_without_new_input")) return 0;
    if (!require(cjgui_internal_renderer_test_set_composable_selection(session, 1, 0, 1) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_test_insert_composable_text(session, 1, "█") == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_test_composable_text_matches(session, "█") == CJGUI_INTERNAL_RENDERER_OK,
                 "multiline_block_character_safe_owner_input")) return 0;
    if (!require(cjgui_internal_renderer_test_set_composable_selection(session, 1, 0, 1) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_test_insert_composable_text(session, 1, "M") == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_test_composable_text_matches(session, "M") == CJGUI_INTERNAL_RENDERER_OK,
                 "restore_multiline_painter_order_fixture")) return 0;
    root.projectionVersion = 91; input.projectionVersion = 91; input.preservesActiveLocalText = 1;
    CjguiInternalRendererComposableNode cover = root;
    cover.nodeId = 882; cover.nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_VERTICAL;
    cover.fillRed = 0.08; cover.fillGreen = 0.18; cover.fillBlue = 0.82; cover.fillAlpha = 1.0;
    if (!require(cjgui_internal_renderer_configure_composable_scene(session, 91, 3) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_set_composable_scene_node(session, 0, &root, "multiline-root", "", "", "", 0) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_set_composable_scene_node(session, 1, &input, "", "", "", "", 0) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_set_composable_scene_node(session, 2, &cover, "multiline-cover", "", "", "", 0) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_present_composable_scene(session, &frame) == CJGUI_INTERNAL_RENDERER_OK,
                 "stage_active_multiline_later_cover")) return 0;
    return capture_composable_pixel(session, textPixelX, textPixelY, &blue, &green, &red, &alpha) &&
           require_bgra(blue, green, red, alpha, 209, 46, 20, 255, "later_shape_covers_active_multiline_textkit_input");
}

// Rounded panels and inherited rounded clips must constrain the actual Metal
// pixels. This has a deliberately opaque child: painter order alone cannot
// hide a missing corner mask.
static int verify_rounded_shape_and_clip(uint64_t session) {
    CjguiInternalRendererComposableNode root = {
        .nodeId = 860, .projectionVersion = 86,
        .x = 0, .y = 0, .width = 420, .height = 180,
        .clipX = 0, .clipY = 0, .clipWidth = 420, .clipHeight = 180,
        .nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_VERTICAL,
        .fillRed = 0.10, .fillGreen = 0.20, .fillBlue = 0.30, .fillAlpha = 1.0
    };
    CjguiInternalRendererComposableNode panel = root;
    panel.nodeId = 861; panel.x = 40; panel.y = 24; panel.width = 180; panel.height = 120;
    panel.clipX = 40; panel.clipY = 24; panel.clipWidth = 180; panel.clipHeight = 120;
    panel.cornerRadius = 28.0; panel.clipCornerRadius = 28.0;
    // The same rounded inherited clip must exclude both the child pixels and
    // interaction targets in its transparent corner.
    panel.nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_BUTTON;
    panel.isInteractive = 1;
    panel.fillRed = 0.86; panel.fillGreen = 0.16; panel.fillBlue = 0.24;
    CjguiInternalRendererComposableNode clippedChild = panel;
    clippedChild.nodeId = 862; clippedChild.x = 40; clippedChild.y = 24;
    clippedChild.cornerRadius = 0.0; clippedChild.clipCornerRadius = 28.0;
    clippedChild.fillRed = 0.10; clippedChild.fillGreen = 0.36; clippedChild.fillBlue = 0.92;
    CjguiInternalRendererFrameObservation frame = {0};
    if (!require(cjgui_internal_renderer_configure_composable_scene(session, 86, 3) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_set_composable_scene_node(session, 0, &root, "rounded-root", "", "", "", 0) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_set_composable_scene_node(session, 1, &panel, "rounded-panel", "", "", "", 0) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_set_composable_scene_node(session, 2, &clippedChild, "rounded-child", "", "", "", 0) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_present_composable_scene(session, &frame) == CJGUI_INTERNAL_RENDERER_OK,
                 "stage_rounded_panel_and_clip")) return 0;
    uint8_t blue = 0, green = 0, red = 0, alpha = 0;
    return capture_composable_pixel(session, 42, 26, &blue, &green, &red, &alpha) &&
           require_bgra(blue, green, red, alpha, 77, 51, 26, 255, "rounded_corner_rejects_child_fill") &&
           capture_composable_pixel(session, 120, 84, &blue, &green, &red, &alpha) &&
           require_bgra(blue, green, red, alpha, 235, 92, 26, 255, "rounded_clip_keeps_child_interior") &&
           require(cjgui_internal_renderer_test_click_composable_point(session, 42.0f, 26.0f) ==
                       CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR,
                   "rounded_clip_rejects_transparent_corner_hit") &&
           require(cjgui_internal_renderer_test_click_composable_point(session, 120.0f, 84.0f) ==
                       CJGUI_INTERNAL_RENDERER_OK,
                   "rounded_clip_accepts_interior_hit");
}

// A scalar radius on the final rectangle cannot represent this chain: the
// inner square intersects the outer rounded ancestor, but its upper-left
// point is still outside the ancestor circle.  Rendering and hit routing must
// retain both original constraints.
static int verify_nested_rounded_clip_chain(uint64_t session) {
    CjguiInternalRendererComposableNode root = {
        .nodeId = 890, .projectionVersion = 91,
        .x = 0, .y = 0, .width = 420, .height = 180,
        .clipX = 0, .clipY = 0, .clipWidth = 420, .clipHeight = 180,
        .nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_VERTICAL,
        .fillRed = 0.10, .fillGreen = 0.20, .fillBlue = 0.30, .fillAlpha = 1.0
    };
    CjguiInternalRendererComposableNode child = root;
    child.nodeId = 891; child.x = 40; child.y = 20; child.width = 160; child.height = 120;
    // This is only the rectangular intersection used for culling.  The
    // explicit constraints below are the source of truth.
    child.clipX = 40; child.clipY = 20; child.clipWidth = 160; child.clipHeight = 120;
    child.clipCornerRadius = 0.0; child.clipConstraintCount = 3;
    child.clip0X = 0; child.clip0Y = 0; child.clip0Width = 420; child.clip0Height = 180;
    child.clip1X = 20; child.clip1Y = 20; child.clip1Width = 200; child.clip1Height = 140; child.clip1CornerRadius = 40.0;
    child.clip2X = 40; child.clip2Y = 20; child.clip2Width = 160; child.clip2Height = 120;
    child.nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_BUTTON; child.isInteractive = 1;
    child.fillRed = 0.10; child.fillGreen = 0.36; child.fillBlue = 0.92;
    CjguiInternalRendererFrameObservation frame = {0};
    if (!require(cjgui_internal_renderer_configure_composable_scene(session, 91, 2) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_set_composable_scene_node(session, 0, &root, "chain-root", "", "", "", 0) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_set_composable_scene_node(session, 1, &child, "chain-child", "", "", "", 0) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_present_composable_scene(session, &frame) == CJGUI_INTERNAL_RENDERER_OK,
                 "stage_nested_rounded_clip_chain")) return 0;
    uint8_t blue = 0, green = 0, red = 0, alpha = 0;
    return capture_composable_pixel(session, 42, 23, &blue, &green, &red, &alpha) &&
           require_bgra(blue, green, red, alpha, 77, 51, 26, 255, "ancestor_round_rejects_intersection_corner") &&
           capture_composable_pixel(session, 80, 40, &blue, &green, &red, &alpha) &&
           require_bgra(blue, green, red, alpha, 235, 92, 26, 255, "nested_clip_chain_keeps_interior") &&
           require(cjgui_internal_renderer_test_click_composable_point(session, 42.0f, 23.0f) == CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR,
                   "nested_clip_chain_rejects_corner_hit") &&
           require(cjgui_internal_renderer_test_click_composable_point(session, 80.0f, 40.0f) == CJGUI_INTERNAL_RENDERER_OK,
                   "nested_clip_chain_accepts_interior_hit");
}

// Resource preparation is part of scene admission.  An injected allocation
// failure must leave the accepted input/projection visible, then a normal
// retry must replace it without recreating a second input owner.
static int verify_text_resource_failure_is_atomic_and_retryable(uint64_t session) {
    CjguiInternalRendererComposableNode root = {
        .nodeId = 900, .projectionVersion = 92,
        .x = 0, .y = 0, .width = 420, .height = 180,
        .clipX = 0, .clipY = 0, .clipWidth = 420, .clipHeight = 180,
        .nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_VERTICAL,
        .fillRed = 0.04, .fillGreen = 0.08, .fillBlue = 0.14, .fillAlpha = 1.0
    };
    CjguiInternalRendererComposableNode input = root;
    input.nodeId = 901; input.x = 40; input.y = 20; input.width = 200; input.height = 80;
    input.clipX = 40; input.clipY = 20; input.clipWidth = 200; input.clipHeight = 80;
    input.nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT_INPUT; input.isInteractive = 1;
    input.fillAlpha = 0.0; input.fontSize = 32.0;
    input.textRed = 1.0; input.textGreen = 0.0; input.textBlue = 1.0; input.textAlpha = 1.0;
    CjguiInternalRendererFrameObservation frame = {0};
    if (!require(cjgui_internal_renderer_configure_composable_scene(session, 92, 2) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_set_composable_scene_node(session, 0, &root, "resource-root", "", "", "", 0) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_set_composable_scene_node(session, 1, &input, "", "", "", "", 0) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_present_composable_scene(session, &frame) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_test_insert_composable_text(session, 1, "█") == CJGUI_INTERNAL_RENDERER_OK,
                 "stage_text_resource_atomic_baseline")) return 0;
    uint64_t sceneVersion = 0;
    if (!require(cjgui_internal_renderer_test_composable_text_matches(session, "█") == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_test_composable_scene_version(session, &sceneVersion) == CJGUI_INTERNAL_RENDERER_OK && sceneVersion == 92,
                 "text_resource_baseline_is_live")) return 0;
    root.projectionVersion = 93; input.projectionVersion = 93;
    if (!require(cjgui_internal_renderer_configure_composable_scene(session, 93, 2) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_set_composable_scene_node(session, 0, &root, "resource-root", "", "", "", 0) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_set_composable_scene_node(session, 1, &input, "", "external replacement", "", "", 0) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_test_set_composable_text_preparation_failures(session, 1) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_present_composable_scene(session, &frame) == CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR,
                 "injected_text_preparation_failure")) return 0;
    if (!require(cjgui_internal_renderer_test_composable_text_matches(session, "█") == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_test_composable_scene_version(session, &sceneVersion) == CJGUI_INTERNAL_RENDERER_OK && sceneVersion == 92,
                 "failed_text_resource_keeps_old_input_and_scene")) return 0;
    return require(cjgui_internal_renderer_present_composable_scene(session, &frame) == CJGUI_INTERNAL_RENDERER_OK &&
                   cjgui_internal_renderer_test_composable_text_matches(session, "external replacement") == CJGUI_INTERNAL_RENDERER_OK &&
                   cjgui_internal_renderer_test_composable_scene_version(session, &sceneVersion) == CJGUI_INTERNAL_RENDERER_OK && sceneVersion == 93,
                   "text_resource_retry_recovers_new_projection");
}

// A deliberately oversized logical text node is clipped to a normal viewport.
// The old full-node backing store exceeded the per-texture dimension/budget
// before it could paint; the admitted resource must describe only the visible
// tile and still participate in the real Metal frame.
static int verify_text_texture_uses_visible_tile(uint64_t session) {
    CjguiInternalRendererComposableNode root = {
        .nodeId = 910, .projectionVersion = 94,
        .x = 0, .y = 0, .width = 420, .height = 180,
        .clipX = 0, .clipY = 0, .clipWidth = 420, .clipHeight = 180,
        .nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_VERTICAL,
        .fillRed = 0.04, .fillGreen = 0.08, .fillBlue = 0.14, .fillAlpha = 1.0
    };
    CjguiInternalRendererComposableNode text = root;
    text.nodeId = 911; text.x = 40; text.y = 20; text.width = 3000; text.height = 3000;
    text.clipX = 40; text.clipY = 20; text.clipWidth = 200; text.clipHeight = 140;
    text.nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT;
    text.fillAlpha = 0.0; text.fontSize = 96.0;
    text.textRed = 1.0; text.textGreen = 0.0; text.textBlue = 1.0; text.textAlpha = 1.0;
    CjguiInternalRendererFrameObservation frame = {0};
    if (!require(cjgui_internal_renderer_configure_composable_scene(session, 94, 2) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_set_composable_scene_node(session, 0, &root, "visible-tile-root", "", "", "", 0) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_set_composable_scene_node(session, 1, &text, "visible-tile-text", "█", "", "", 0) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_present_composable_scene(session, &frame) == CJGUI_INTERNAL_RENDERER_OK,
                 "stage_visible_text_tile_without_full_node_oom")) return 0;
    uint64_t bytes = 0; float x = 0, y = 0, width = 0, height = 0;
    if (!require(cjgui_internal_renderer_test_composable_text_resource_stats(session, 1, &bytes, &x, &y, &width, &height) == CJGUI_INTERNAL_RENDERER_OK &&
                 bytes > 0 && bytes <= 1024 * 1024 && x == 40.0f && y == 20.0f && width == 200.0f && height == 140.0f,
                 "visible_text_tile_has_bounded_texture_and_scene_rect")) return 0;
    uint8_t blue = 0, green = 0, red = 0, alpha = 0;
    return capture_composable_pixel(session, 70, 80, &blue, &green, &red, &alpha) &&
           require_bgra(blue, green, red, alpha, 255, 0, 255, 255, "visible_text_tile_preserves_glyph_position");
}

// A 1000x400pt editor is a normal full visible viewport, not an oversized
// logical-document stress case.  At this machine's 2x backing scale it needs
// 6.4 MiB, so the former 4 MiB single-tile admission incorrectly rejected
// the entire scene before a first frame.
static int verify_ordinary_large_visible_text_tile(void) {
    CjguiInternalRendererStatus status = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    CjguiInternalRendererConfig config = { 1100, 500, 0.08, 0.16, 0.20, 1.0 };
    uint64_t session = cjgui_internal_renderer_create(&config, &status);
    if (!require(status == CJGUI_INTERNAL_RENDERER_OK && session != CJGUI_INTERNAL_RENDERER_INVALID_SESSION,
                 "create_ordinary_large_visible_text_window")) return 0;
    CjguiInternalRendererComposableNode root = {
        .nodeId = 914, .projectionVersion = 95,
        .x = 0, .y = 0, .width = 1100, .height = 500,
        .clipX = 0, .clipY = 0, .clipWidth = 1100, .clipHeight = 500,
        .nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_VERTICAL,
        .fillRed = 0.04, .fillGreen = 0.08, .fillBlue = 0.14, .fillAlpha = 1.0
    };
    CjguiInternalRendererComposableNode editor = root;
    editor.nodeId = 915; editor.x = 50; editor.y = 50; editor.width = 1000; editor.height = 400;
    editor.clipX = 50; editor.clipY = 50; editor.clipWidth = 1000; editor.clipHeight = 400;
    editor.nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT;
    editor.fillAlpha = 0.0; editor.fontSize = 24.0;
    editor.textRed = 1.0; editor.textGreen = 0.0; editor.textBlue = 1.0; editor.textAlpha = 1.0;
    CjguiInternalRendererFrameObservation frame = {0};
    if (!require(cjgui_internal_renderer_configure_composable_scene(session, 95, 2) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_set_composable_scene_node(session, 0, &root, "ordinary-large-root", "", "", "", 0) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_set_composable_scene_node(session, 1, &editor, "ordinary-large-editor", "ordinary visible editor", "", "", 0) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_present_composable_scene(session, &frame) == CJGUI_INTERNAL_RENDERER_OK,
                 "ordinary_large_visible_editor_is_admitted")) { (void)cjgui_internal_renderer_destroy(session); return 0; }
    uint64_t bytes = 0; float x = 0, y = 0, width = 0, height = 0;
    int passed = require(cjgui_internal_renderer_test_composable_text_resource_stats(session, 1, &bytes, &x, &y, &width, &height) == CJGUI_INTERNAL_RENDERER_OK &&
                         bytes > 4u * 1024u * 1024u && bytes <= 8u * 1024u * 1024u &&
                         x == 50.0f && y == 50.0f && width == 1000.0f && height == 400.0f,
                         "ordinary_large_visible_editor_keeps_bounded_admitted_tile");
    if (cjgui_internal_renderer_request_close(session) != CJGUI_INTERNAL_RENDERER_OK ||
        cjgui_internal_renderer_destroy(session) != CJGUI_INTERNAL_RENDERER_OK) return 0;
    return passed;
}

// The backing rectangle can remain unchanged while a node moves beneath a
// fixed ancestor clip.  Rasterization translates from the tile into the
// node's local text coordinates, so reusing a cache key made only from the
// absolute tile incorrectly keeps the former pixels.
static int verify_static_text_tile_invalidates_for_relative_node_offset(void) {
    CjguiInternalRendererStatus status = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    CjguiInternalRendererConfig config = { 420, 180, 0.08, 0.16, 0.20, 1.0 };
    uint64_t session = cjgui_internal_renderer_create(&config, &status);
    if (!require(status == CJGUI_INTERNAL_RENDERER_OK && session != CJGUI_INTERNAL_RENDERER_INVALID_SESSION,
                 "create_static_relative_tile_offset_window")) return 0;
    CjguiInternalRendererComposableNode root = {
        .nodeId = 916, .projectionVersion = 96,
        .x = 0, .y = 0, .width = 420, .height = 180,
        .clipX = 0, .clipY = 0, .clipWidth = 420, .clipHeight = 180,
        .nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_VERTICAL,
        .fillRed = 0.04, .fillGreen = 0.08, .fillBlue = 0.14, .fillAlpha = 1.0
    };
    CjguiInternalRendererComposableNode text = root;
    text.nodeId = 917; text.x = 80; text.y = 20; text.width = 260; text.height = 140;
    text.clipX = 100; text.clipY = 20; text.clipWidth = 200; text.clipHeight = 140;
    text.nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT;
    text.fillAlpha = 0.0; text.fontSize = 96.0;
    text.textRed = 1.0; text.textGreen = 0.0; text.textBlue = 1.0; text.textAlpha = 1.0;
    CjguiInternalRendererFrameObservation frame = {0};
    if (!require(cjgui_internal_renderer_configure_composable_scene(session, 96, 2) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_set_composable_scene_node(session, 0, &root, "relative-tile-root", "", "", "", 0) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_set_composable_scene_node(session, 1, &text, "relative-tile-text", "█", "", "", 0) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_present_composable_scene(session, &frame) == CJGUI_INTERNAL_RENDERER_OK,
                 "stage_static_relative_tile_offset_baseline")) { (void)cjgui_internal_renderer_destroy(session); return 0; }
    uint8_t blue = 0, green = 0, red = 0, alpha = 0;
    if (!require(capture_composable_pixel(session, 190, 80, &blue, &green, &red, &alpha) &&
                 !(red > 220 && green < 30 && blue > 220),
                 "relative_tile_offset_baseline_pixel_is_not_yet_glyph")) { (void)cjgui_internal_renderer_destroy(session); return 0; }
    root.projectionVersion = 97; text.projectionVersion = 97; text.x = 100;
    int passed = require(cjgui_internal_renderer_configure_composable_scene(session, 97, 2) == CJGUI_INTERNAL_RENDERER_OK &&
                         cjgui_internal_renderer_set_composable_scene_node(session, 0, &root, "relative-tile-root", "", "", "", 0) == CJGUI_INTERNAL_RENDERER_OK &&
                         cjgui_internal_renderer_set_composable_scene_node(session, 1, &text, "relative-tile-text", "█", "", "", 0) == CJGUI_INTERNAL_RENDERER_OK &&
                         cjgui_internal_renderer_present_composable_scene(session, &frame) == CJGUI_INTERNAL_RENDERER_OK &&
                         capture_composable_pixel(session, 190, 80, &blue, &green, &red, &alpha) &&
                         require_bgra(blue, green, red, alpha, 255, 0, 255, 255,
                                      "relative_node_move_rasterizes_new_static_tile_pixels"),
                         "static_relative_tile_offset_rebuilds_texture");
    if (cjgui_internal_renderer_request_close(session) != CJGUI_INTERNAL_RENDERER_OK ||
        cjgui_internal_renderer_destroy(session) != CJGUI_INTERNAL_RENDERER_OK) return 0;
    return passed;
}

// An accepted active-multiline projection must rebuild correctly when a
// focused node moves beneath an unchanged ancestor clip rectangle.  The
// normal projection replacement/refresh path is the behavior under test;
// it must not leave the former tile visible merely because the absolute tile
// bounds stayed fixed.
static int verify_active_multiline_tile_invalidates_for_relative_node_offset(void) {
    CjguiInternalRendererStatus status = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    CjguiInternalRendererConfig config = { 420, 180, 0.08, 0.16, 0.20, 1.0 };
    uint64_t session = cjgui_internal_renderer_create(&config, &status);
    if (!require(status == CJGUI_INTERNAL_RENDERER_OK && session != CJGUI_INTERNAL_RENDERER_INVALID_SESSION,
                 "create_active_relative_tile_offset_window")) return 0;
    CjguiInternalRendererComposableNode root = {
        .nodeId = 918, .projectionVersion = 98,
        .x = 0, .y = 0, .width = 420, .height = 180,
        .clipX = 0, .clipY = 0, .clipWidth = 420, .clipHeight = 180,
        .nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_VERTICAL,
        .fillRed = 0.04, .fillGreen = 0.08, .fillBlue = 0.14, .fillAlpha = 1.0
    };
    CjguiInternalRendererComposableNode input = root;
    input.nodeId = 919; input.x = 80; input.y = 20; input.width = 260; input.height = 140;
    input.clipX = 100; input.clipY = 20; input.clipWidth = 200; input.clipHeight = 140;
    input.nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT;
    input.isInteractive = 1; input.fillAlpha = 0.0; input.fontSize = 96.0;
    input.textRed = 1.0; input.textGreen = 0.0; input.textBlue = 1.0; input.textAlpha = 1.0;
    CjguiInternalRendererFrameObservation frame = {0};
    if (!require(cjgui_internal_renderer_configure_composable_scene(session, 98, 2) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_set_composable_scene_node(session, 0, &root, "active-relative-tile-root", "", "", "", 0) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_set_composable_scene_node(session, 1, &input, "", "", "", "", 0) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_present_composable_scene(session, &frame) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_test_insert_composable_text(session, 1, "█") == CJGUI_INTERNAL_RENDERER_OK,
                 "stage_active_relative_tile_offset_baseline")) { (void)cjgui_internal_renderer_destroy(session); return 0; }
    uint8_t blue = 0, green = 0, red = 0, alpha = 0;
    if (!require(capture_composable_pixel(session, 190, 80, &blue, &green, &red, &alpha) &&
                 !(red > 220 && green < 30 && blue > 220),
                 "active_relative_tile_offset_baseline_pixel_is_not_yet_glyph")) { (void)cjgui_internal_renderer_destroy(session); return 0; }
    root.projectionVersion = 99; input.projectionVersion = 99; input.x = 100; input.preservesActiveLocalText = 1;
    int passed = require(cjgui_internal_renderer_configure_composable_scene(session, 99, 2) == CJGUI_INTERNAL_RENDERER_OK &&
                         cjgui_internal_renderer_set_composable_scene_node(session, 0, &root, "active-relative-tile-root", "", "", "", 0) == CJGUI_INTERNAL_RENDERER_OK &&
                         cjgui_internal_renderer_set_composable_scene_node(session, 1, &input, "", "", "", "", 0) == CJGUI_INTERNAL_RENDERER_OK &&
                         cjgui_internal_renderer_present_composable_scene(session, &frame) == CJGUI_INTERNAL_RENDERER_OK &&
                         capture_composable_pixel(session, 190, 80, &blue, &green, &red, &alpha) &&
                         require_bgra(blue, green, red, alpha, 255, 0, 255, 255,
                                      "relative_node_move_rasterizes_new_active_tile_pixels"),
                         "active_relative_tile_offset_rebuilds_texture");
    if (cjgui_internal_renderer_request_close(session) != CJGUI_INTERNAL_RENDERER_OK ||
        cjgui_internal_renderer_destroy(session) != CJGUI_INTERNAL_RENDERER_OK) return 0;
    return passed;
}

// The active multiline raster applies the original rounded clip chain, while
// its visible tile remains the chain's same rectangular intersection. Change
// only the radius and prove a corner pixel is admitted by the replacement
// projection. This catches a stale active tile even though x/y/width/height
// and the TextKit value are unchanged.
static int verify_active_multiline_clip_shape_reprojects_same_tile(void) {
    CjguiInternalRendererStatus status = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    CjguiInternalRendererConfig config = { 420, 180, 0.08, 0.16, 0.20, 1.0 };
    uint64_t session = cjgui_internal_renderer_create(&config, &status);
    if (!require(status == CJGUI_INTERNAL_RENDERER_OK && session != CJGUI_INTERNAL_RENDERER_INVALID_SESSION,
                 "create_active_multiline_clip_shape_window")) return 0;
    CjguiInternalRendererComposableNode root = {
        .nodeId = 920, .projectionVersion = 100,
        .x = 0, .y = 0, .width = 420, .height = 180,
        .clipX = 0, .clipY = 0, .clipWidth = 420, .clipHeight = 180,
        .nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_VERTICAL,
        .fillRed = 0.04, .fillGreen = 0.08, .fillBlue = 0.14, .fillAlpha = 1.0
    };
    CjguiInternalRendererComposableNode input = root;
    input.nodeId = 921; input.x = 40; input.y = 20; input.width = 200; input.height = 140;
    input.clipX = 40; input.clipY = 20; input.clipWidth = 200; input.clipHeight = 140;
    input.clipConstraintCount = 1;
    input.clip0X = 40; input.clip0Y = 20; input.clip0Width = 200; input.clip0Height = 140;
    input.clip0CornerRadius = 70.0;
    input.nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT;
    input.isInteractive = 1; input.fillAlpha = 0.0; input.fontSize = 96.0;
    input.textRed = 1.0; input.textGreen = 0.0; input.textBlue = 1.0; input.textAlpha = 1.0;
    CjguiInternalRendererFrameObservation frame = {0};
    if (!require(cjgui_internal_renderer_configure_composable_scene(session, 100, 2) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_set_composable_scene_node(session, 0, &root, "active-clip-shape-root", "", "", "", 0) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_set_composable_scene_node(session, 1, &input, "", "", "", "", 0) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_present_composable_scene(session, &frame) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_test_insert_composable_text(session, 1, "█") == CJGUI_INTERNAL_RENDERER_OK,
                 "stage_active_multiline_rounded_clip_shape")) { (void)cjgui_internal_renderer_destroy(session); return 0; }
    uint8_t blue = 0, green = 0, red = 0, alpha = 0;
    // This is inside the 96pt block glyph but outside the radius-70 corner
    // (nearest rounded-corner centre is {110,90}; distance is > 70).
    const uint32_t cornerGlyphX = 50, cornerGlyphY = 50;
    if (!require(capture_composable_pixel(session, cornerGlyphX, cornerGlyphY, &blue, &green, &red, &alpha) &&
                 !(red > 220 && green < 30 && blue > 220),
                 "rounded_active_clip_excludes_corner_glyph")) { (void)cjgui_internal_renderer_destroy(session); return 0; }
    root.projectionVersion = 101; input.projectionVersion = 101;
    input.clip0CornerRadius = 0.0; input.preservesActiveLocalText = 1;
    int passed = require(cjgui_internal_renderer_configure_composable_scene(session, 101, 2) == CJGUI_INTERNAL_RENDERER_OK &&
                         cjgui_internal_renderer_set_composable_scene_node(session, 0, &root, "active-clip-shape-root", "", "", "", 0) == CJGUI_INTERNAL_RENDERER_OK &&
                         cjgui_internal_renderer_set_composable_scene_node(session, 1, &input, "", "", "", "", 0) == CJGUI_INTERNAL_RENDERER_OK &&
                         cjgui_internal_renderer_present_composable_scene(session, &frame) == CJGUI_INTERNAL_RENDERER_OK &&
                         capture_composable_pixel(session, cornerGlyphX, cornerGlyphY, &blue, &green, &red, &alpha) &&
                         require_bgra(blue, green, red, alpha, 255, 0, 255, 255,
                                      "active_clip_radius_change_reprojects_same_tile"),
                         "active_multiline_clip_shape_rebuilds_texture");
    if (cjgui_internal_renderer_request_close(session) != CJGUI_INTERNAL_RENDERER_OK ||
        cjgui_internal_renderer_destroy(session) != CJGUI_INTERNAL_RENDERER_OK) return 0;
    return passed;
}

// A local-owner acknowledgement may carry a new presentation style while its
// staged text value remains empty. The active TextKit value must survive that
// narrow hand-off, but its derived tile must still take the new text colour.
static int verify_active_multiline_style_reprojects_same_tile(void) {
    CjguiInternalRendererStatus status = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    CjguiInternalRendererConfig config = { 420, 180, 0.08, 0.16, 0.20, 1.0 };
    uint64_t session = cjgui_internal_renderer_create(&config, &status);
    if (!require(status == CJGUI_INTERNAL_RENDERER_OK && session != CJGUI_INTERNAL_RENDERER_INVALID_SESSION,
                 "create_active_multiline_style_window")) return 0;
    CjguiInternalRendererComposableNode root = {
        .nodeId = 922, .projectionVersion = 102,
        .x = 0, .y = 0, .width = 420, .height = 180,
        .clipX = 0, .clipY = 0, .clipWidth = 420, .clipHeight = 180,
        .nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_VERTICAL,
        .fillRed = 0.04, .fillGreen = 0.08, .fillBlue = 0.14, .fillAlpha = 1.0
    };
    CjguiInternalRendererComposableNode input = root;
    input.nodeId = 923; input.x = 40; input.y = 20; input.width = 200; input.height = 140;
    input.clipX = 40; input.clipY = 20; input.clipWidth = 200; input.clipHeight = 140;
    input.nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT;
    input.isInteractive = 1; input.fillAlpha = 0.0; input.fontSize = 96.0;
    input.textRed = 1.0; input.textGreen = 0.0; input.textBlue = 1.0; input.textAlpha = 1.0;
    CjguiInternalRendererFrameObservation frame = {0};
    if (!require(cjgui_internal_renderer_configure_composable_scene(session, 102, 2) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_set_composable_scene_node(session, 0, &root, "active-style-root", "", "", "", 0) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_set_composable_scene_node(session, 1, &input, "", "", "", "", 0) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_present_composable_scene(session, &frame) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_test_insert_composable_text(session, 1, "█") == CJGUI_INTERNAL_RENDERER_OK,
                 "stage_active_multiline_style_baseline")) { (void)cjgui_internal_renderer_destroy(session); return 0; }
    const uint32_t textPixelX = 57, textPixelY = 80;
    uint8_t blue = 0, green = 0, red = 0, alpha = 0;
    if (!(capture_composable_pixel(session, textPixelX, textPixelY, &blue, &green, &red, &alpha) &&
          require_bgra(blue, green, red, alpha, 255, 0, 255, 255, "active_style_baseline_magenta_glyph"))) {
        (void)cjgui_internal_renderer_destroy(session); return 0;
    }
    root.projectionVersion = 103; input.projectionVersion = 103; input.preservesActiveLocalText = 1;
    input.textRed = 0.0; input.textGreen = 1.0; input.textBlue = 0.0;
    int passed = require(cjgui_internal_renderer_configure_composable_scene(session, 103, 2) == CJGUI_INTERNAL_RENDERER_OK &&
                         cjgui_internal_renderer_set_composable_scene_node(session, 0, &root, "active-style-root", "", "", "", 0) == CJGUI_INTERNAL_RENDERER_OK &&
                         cjgui_internal_renderer_set_composable_scene_node(session, 1, &input, "", "", "", "", 0) == CJGUI_INTERNAL_RENDERER_OK &&
                         cjgui_internal_renderer_present_composable_scene(session, &frame) == CJGUI_INTERNAL_RENDERER_OK &&
                         capture_composable_pixel(session, textPixelX, textPixelY, &blue, &green, &red, &alpha) &&
                         require_bgra(blue, green, red, alpha, 0, 255, 0, 255,
                                      "active_style_change_reprojects_local_text_tile"),
                         "active_multiline_style_rebuilds_texture");
    if (cjgui_internal_renderer_request_close(session) != CJGUI_INTERNAL_RENDERER_OK ||
        cjgui_internal_renderer_destroy(session) != CJGUI_INTERNAL_RENDERER_OK) return 0;
    return passed;
}

// The generic first-frame diagnostic may only compare a point whose final
// colour it can derive without guessing at clip, z order, or alpha.  This is
// deliberately a normal AppKit window: it proves the diagnostic selection
// after an actual content resize as well as the individual drawable pixels.
// Before the matching renderer fix, the final clipped node below was chosen
// by its off-clip centre and caused a false scene_color_mismatch.
static int verify_readback_probe_selects_visible_opaque_nodes(void) {
    CjguiInternalRendererStatus status = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    CjguiInternalRendererConfig config = { 420, 180, 0.08, 0.16, 0.20, 1.0 };
    uint64_t session = cjgui_internal_renderer_create(&config, &status);
    if (!require(status == CJGUI_INTERNAL_RENDERER_OK && session != CJGUI_INTERNAL_RENDERER_INVALID_SESSION,
                 "create_readback_selection_window")) return 0;

    CjguiInternalRendererComposableNode root = {
        .nodeId = 910, .projectionVersion = 91,
        .x = 0, .y = 0, .width = 420, .height = 180,
        .clipX = 0, .clipY = 0, .clipWidth = 420, .clipHeight = 180,
        .nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_VERTICAL,
        .fillRed = 0.10, .fillGreen = 0.20, .fillBlue = 0.30, .fillAlpha = 1.0
    };
    // Its centre is covered by the later opaque rectangle. A valid generic
    // choice must therefore be the topmost visible opaque node, not simply
    // the root's centre.
    CjguiInternalRendererComposableNode opaqueOverlap = root;
    opaqueOverlap.nodeId = 911; opaqueOverlap.x = 160; opaqueOverlap.y = 60;
    opaqueOverlap.width = 100; opaqueOverlap.height = 80;
    opaqueOverlap.clipX = 160; opaqueOverlap.clipY = 60;
    opaqueOverlap.clipWidth = 100; opaqueOverlap.clipHeight = 80;
    opaqueOverlap.fillRed = 0.12; opaqueOverlap.fillGreen = 0.70; opaqueOverlap.fillBlue = 0.32;
    // This transparent rectangle is rendered, but it is intentionally not a
    // generic diagnostic source: its raw alpha composition is not a stable
    // proxy for the whole scene. Exact drawable capture below still proves it.
    CjguiInternalRendererComposableNode transparent = root;
    transparent.nodeId = 912; transparent.x = 20; transparent.y = 20;
    transparent.width = 80; transparent.height = 40;
    transparent.clipX = 20; transparent.clipY = 20;
    transparent.clipWidth = 80; transparent.clipHeight = 40;
    transparent.fillRed = 0.80; transparent.fillGreen = 0.10; transparent.fillBlue = 0.20; transparent.fillAlpha = 0.50;
    // This final node has a visible left strip but its own centre lies outside
    // that strip. Choosing it is the resize false-positive we must reject.
    CjguiInternalRendererComposableNode centreClipped = root;
    centreClipped.nodeId = 913; centreClipped.x = 300; centreClipped.y = 20;
    centreClipped.width = 100; centreClipped.height = 80;
    centreClipped.clipX = 300; centreClipped.clipY = 20;
    centreClipped.clipWidth = 20; centreClipped.clipHeight = 80;
    centreClipped.fillRed = 1.0; centreClipped.fillGreen = 0.0; centreClipped.fillBlue = 1.0; centreClipped.fillAlpha = 1.0;

    CjguiInternalRendererFrameObservation frame = {0};
    if (!require(cjgui_internal_renderer_configure_composable_scene(session, 91, 4) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_set_composable_scene_node(session, 0, &root, "readback-root", "", "", "", 0) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_set_composable_scene_node(session, 1, &opaqueOverlap, "readback-overlap", "", "", "", 0) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_set_composable_scene_node(session, 2, &transparent, "readback-transparent", "", "", "", 0) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_set_composable_scene_node(session, 3, &centreClipped, "readback-centre-clipped", "", "", "", 0) == CJGUI_INTERNAL_RENDERER_OK,
                 "stage_readback_selection_scene")) { (void)cjgui_internal_renderer_destroy(session); return 0; }
    if (!require(cjgui_internal_renderer_present_composable_scene(session, &frame) == CJGUI_INTERNAL_RENDERER_OK &&
                 frame.readbackAttempted == 1 && frame.readbackCompleted == 1 && frame.readbackColorMatched == 1,
                 "generic_readback_uses_visible_opaque_node")) { (void)cjgui_internal_renderer_destroy(session); return 0; }

    uint32_t shapeNodes = 0, shapeBatches = 0, textureDraws = 0, vertexStride = 0;
    uint64_t shapeVertexBytes = 0, maxShapeBatchVertexBytes = 0;
    if (!require(cjgui_internal_renderer_test_composable_encoder_stats(session, &shapeNodes, &shapeBatches,
                                                                        &textureDraws, &shapeVertexBytes) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_test_composable_encoder_batch_stats(session, &vertexStride,
                                                                                &maxShapeBatchVertexBytes) == CJGUI_INTERNAL_RENDERER_OK &&
                 shapeNodes == 4 && shapeBatches == 2 && textureDraws == 0 && shapeVertexBytes > 4096 &&
                 vertexStride > 0 && maxShapeBatchVertexBytes > 0 && maxShapeBatchVertexBytes <= 4096,
                 "consecutive_shapes_share_bounded_ordered_encoder_batches")) { (void)cjgui_internal_renderer_destroy(session); return 0; }

    uint8_t blue = 0, green = 0, red = 0, alpha = 0;
    if (!require(capture_composable_pixel(session, 210, 100, &blue, &green, &red, &alpha) &&
                 require_bgra(blue, green, red, alpha, 82, 179, 31, 255, "overlap_draws_top_opaque_node") &&
                 capture_composable_pixel(session, 50, 40, &blue, &green, &red, &alpha) &&
                 // The drawable starts opaque. A 50% red node must blend
                 // over the blue-grey root, rather than replacing it with a
                 // raw half-alpha source colour.
                 require_bgra(blue, green, red, alpha, 64, 38, 115, 255, "transparent_node_blends_over_opaque_root") &&
                 capture_composable_pixel(session, 310, 60, &blue, &green, &red, &alpha) &&
                 require_bgra(blue, green, red, alpha, 255, 0, 255, 255, "clip_visible_strip_draws") &&
                 capture_composable_pixel(session, 350, 60, &blue, &green, &red, &alpha) &&
                 require_bgra(blue, green, red, alpha, 77, 51, 26, 255, "clip_excluded_centre_keeps_root"),
                 "readback_selection_pixels")) {
        (void)cjgui_internal_renderer_destroy(session); return 0;
    }

    uint64_t resizeVersion = 0;
    CjguiInternalRendererViewport viewport = {0};
    if (!require(cjgui_internal_renderer_test_resize_composable_window(session, &resizeVersion) == CJGUI_INTERNAL_RENDERER_OK &&
                 resizeVersion > 0 && cjgui_internal_renderer_composable_viewport(session, &viewport) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_test_request_composable_drawable_pixel(session, 210, 100) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_present_clear(session, &(CjguiInternalRendererClearColor){ 0.08, 0.16, 0.20, 1.0 }, &frame) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_test_composable_drawable_pixel(session, &blue, &green, &red, &alpha) == CJGUI_INTERNAL_RENDERER_OK &&
                 require_bgra(blue, green, red, alpha, 82, 179, 31, 255, "resize_keeps_scaled_opaque_pixel") &&
                 frame.contentsScale > 0.0 &&
                 frame.drawableWidthPixels == (uint32_t)((double)viewport.width * frame.contentsScale) &&
                 frame.drawableHeightPixels == (uint32_t)((double)viewport.height * frame.contentsScale),
                 "resize_drawable_matches_logical_viewport_and_scale")) { (void)cjgui_internal_renderer_destroy(session); return 0; }
    if (!require(cjgui_internal_renderer_request_close(session) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_destroy(session) == CJGUI_INTERNAL_RENDERER_OK,
                 "destroy_readback_selection_window")) return 0;
    return 1;
}

// GPU text is not a second scene owner, but its immutable texture is still a
// real painter-order command.  A generic first-frame colour oracle cannot
// derive the final pixel beneath that texture from the lower opaque fill. The
// full-block glyph makes the affected centre deterministic for the explicit
// drawable-pixel assertion below. Before the conservative coverage fix, the
// first present incorrectly compared the root fill at (70, 80) and failed
// with scene_color_mismatch.
static int verify_readback_probe_rejects_gpu_text_coverage(void) {
    CjguiInternalRendererStatus status = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    CjguiInternalRendererConfig config = { 240, 180, 0.08, 0.16, 0.20, 1.0 };
    uint64_t session = cjgui_internal_renderer_create(&config, &status);
    if (!require(status == CJGUI_INTERNAL_RENDERER_OK && session != CJGUI_INTERNAL_RENDERER_INVALID_SESSION,
                 "create_readback_text_coverage_window")) return 0;

    CjguiInternalRendererComposableNode root = {
        .nodeId = 920, .projectionVersion = 92,
        .x = 0, .y = 0, .width = 140, .height = 160,
        .clipX = 0, .clipY = 0, .clipWidth = 140, .clipHeight = 160,
        .nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_VERTICAL,
        .fillRed = 0.04, .fillGreen = 0.08, .fillBlue = 0.14, .fillAlpha = 1.0
    };
    CjguiInternalRendererComposableNode text = root;
    text.nodeId = 921; text.x = 0; text.y = 0; text.width = 200; text.height = 160;
    text.clipX = 0; text.clipY = 0; text.clipWidth = 200; text.clipHeight = 160;
    text.nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT;
    text.fillAlpha = 0.0; text.fontSize = 96.0;
    text.textRed = 1.0; text.textGreen = 0.0; text.textBlue = 1.0; text.textAlpha = 1.0;

    CjguiInternalRendererFrameObservation frame = {0};
    if (!require(cjgui_internal_renderer_configure_composable_scene(session, 92, 2) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_set_composable_scene_node(session, 0, &root, "readback-text-root", "", "", "", 0) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_set_composable_scene_node(session, 1, &text, "readback-text-cover", "█", "", "", 0) == CJGUI_INTERNAL_RENDERER_OK,
                 "stage_readback_text_coverage_scene")) { (void)cjgui_internal_renderer_destroy(session); return 0; }
    if (!require(cjgui_internal_renderer_present_composable_scene(session, &frame) == CJGUI_INTERNAL_RENDERER_OK &&
                 frame.readbackAttempted == 1 && frame.readbackCompleted == 1 && frame.readbackColorMatched == 0,
                 "generic_readback_skips_gpu_text_covered_opaque_fill")) { (void)cjgui_internal_renderer_destroy(session); return 0; }

    uint8_t blue = 0, green = 0, red = 0, alpha = 0;
    if (!require(capture_composable_pixel(session, 70, 80, &blue, &green, &red, &alpha) &&
                 require_bgra(blue, green, red, alpha, 255, 0, 255, 255,
                              "gpu_text_coverage_is_still_drawn_and_observable"),
                 "readback_text_coverage_pixel")) { (void)cjgui_internal_renderer_destroy(session); return 0; }
    if (!require(cjgui_internal_renderer_request_close(session) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_destroy(session) == CJGUI_INTERNAL_RENDERER_OK,
                 "destroy_readback_text_coverage_window")) return 0;
    return 1;
}

// The same rule applies when the text node itself has an opaque fill. Its
// texture is painted after that fill, so selecting the node as a generic
// colour candidate would be just as wrong as ignoring a later text node.
static int verify_readback_probe_rejects_self_gpu_text_coverage(void) {
    CjguiInternalRendererStatus status = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    CjguiInternalRendererConfig config = { 240, 180, 0.08, 0.16, 0.20, 1.0 };
    uint64_t session = cjgui_internal_renderer_create(&config, &status);
    if (!require(status == CJGUI_INTERNAL_RENDERER_OK && session != CJGUI_INTERNAL_RENDERER_INVALID_SESSION,
                 "create_readback_self_text_coverage_window")) return 0;

    CjguiInternalRendererComposableNode text = {
        .nodeId = 922, .projectionVersion = 93,
        .x = 0, .y = 0, .width = 140, .height = 160,
        .clipX = 0, .clipY = 0, .clipWidth = 140, .clipHeight = 160,
        .nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT,
        .fillRed = 0.04, .fillGreen = 0.08, .fillBlue = 0.14, .fillAlpha = 1.0,
        .fontSize = 96.0,
        .textRed = 1.0, .textGreen = 0.0, .textBlue = 1.0, .textAlpha = 1.0
    };
    CjguiInternalRendererFrameObservation frame = {0};
    if (!require(cjgui_internal_renderer_configure_composable_scene(session, 93, 1) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_set_composable_scene_node(session, 0, &text, "readback-self-text", "█", "", "", 0) == CJGUI_INTERNAL_RENDERER_OK,
                 "stage_readback_self_text_coverage_scene")) { (void)cjgui_internal_renderer_destroy(session); return 0; }
    if (!require(cjgui_internal_renderer_present_composable_scene(session, &frame) == CJGUI_INTERNAL_RENDERER_OK &&
                 frame.readbackAttempted == 1 && frame.readbackCompleted == 1 && frame.readbackColorMatched == 0,
                 "generic_readback_skips_self_gpu_text_covered_opaque_fill")) { (void)cjgui_internal_renderer_destroy(session); return 0; }

    uint8_t blue = 0, green = 0, red = 0, alpha = 0;
    if (!require(capture_composable_pixel(session, 70, 80, &blue, &green, &red, &alpha) &&
                 require_bgra(blue, green, red, alpha, 255, 0, 255, 255,
                              "self_gpu_text_coverage_is_still_drawn_and_observable"),
                 "readback_self_text_coverage_pixel")) { (void)cjgui_internal_renderer_destroy(session); return 0; }
    if (!require(cjgui_internal_renderer_request_close(session) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_destroy(session) == CJGUI_INTERNAL_RENDERER_OK,
                 "destroy_readback_self_text_coverage_window")) return 0;
    return 1;
}

// Metal's setVertexBytes input has a 4 KiB limit.  Text and image nodes
// normally flush the preceding shape batch, so this deliberately contains
// only consecutive shapes.  It captures an actual final-tile pixel as well
// as encoder scalars: a count-only test could otherwise pass after an
// accidental painter-order change.
static int verify_consecutive_shape_batch_respects_vertex_bytes_limit(void) {
    CjguiInternalRendererStatus status = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    CjguiInternalRendererConfig config = { 420, 180, 0.04, 0.08, 0.12, 1.0 };
    uint64_t session = cjgui_internal_renderer_create(&config, &status);
    if (!require(status == CJGUI_INTERNAL_RENDERER_OK && session != CJGUI_INTERNAL_RENDERER_INVALID_SESSION,
                 "create_oversized_consecutive_shape_batch_window")) return 0;

    enum { CjguiOversizedShapeCount = 7 };
    CjguiInternalRendererComposableNode root = {
        .nodeId = 930, .projectionVersion = 93,
        .x = 0, .y = 0, .width = 420, .height = 180,
        .clipX = 0, .clipY = 0, .clipWidth = 420, .clipHeight = 180,
        .nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_VERTICAL,
        .fillRed = 0.04, .fillGreen = 0.08, .fillBlue = 0.12, .fillAlpha = 1.0
    };
    if (!require(cjgui_internal_renderer_configure_composable_scene(session, 93, CjguiOversizedShapeCount) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_set_composable_scene_node(session, 0, &root, "shape-batch-root", "", "", "", 0) == CJGUI_INTERNAL_RENDERER_OK,
                 "stage_oversized_consecutive_shape_batch_root")) { (void)cjgui_internal_renderer_destroy(session); return 0; }
    for (uint32_t index = 1; index < CjguiOversizedShapeCount; index++) {
        CjguiInternalRendererComposableNode tile = root;
        tile.nodeId = 930 + index;
        tile.x = 20.0 + ((double)(index - 1) * 62.0);
        tile.y = 50.0;
        tile.width = 54.0;
        tile.height = 72.0;
        tile.clipX = tile.x;
        tile.clipY = tile.y;
        tile.clipWidth = tile.width;
        tile.clipHeight = tile.height;
        tile.fillRed = index == CjguiOversizedShapeCount - 1 ? 0.92 : 0.18;
        tile.fillGreen = index == CjguiOversizedShapeCount - 1 ? 0.12 : 0.34;
        tile.fillBlue = index == CjguiOversizedShapeCount - 1 ? 0.76 : 0.46;
        if (!require(cjgui_internal_renderer_set_composable_scene_node(session, index, &tile, "shape-batch-tile", "", "", "", 0) == CJGUI_INTERNAL_RENDERER_OK,
                     "stage_oversized_consecutive_shape_batch_tile")) { (void)cjgui_internal_renderer_destroy(session); return 0; }
    }
    CjguiInternalRendererFrameObservation frame = {0};
    if (!require(cjgui_internal_renderer_present_composable_scene(session, &frame) == CJGUI_INTERNAL_RENDERER_OK,
                 "present_oversized_consecutive_shape_batch")) { (void)cjgui_internal_renderer_destroy(session); return 0; }

    uint32_t shapeNodes = 0, shapeBatches = 0, textureDraws = 0, vertexStride = 0;
    uint64_t shapeVertexBytes = 0, maxShapeBatchVertexBytes = 0;
    int bounded = cjgui_internal_renderer_test_composable_encoder_stats(session, &shapeNodes, &shapeBatches,
                                                                           &textureDraws, &shapeVertexBytes) == CJGUI_INTERNAL_RENDERER_OK &&
                  cjgui_internal_renderer_test_composable_encoder_batch_stats(session, &vertexStride,
                                                                                 &maxShapeBatchVertexBytes) == CJGUI_INTERNAL_RENDERER_OK &&
                  shapeNodes == CjguiOversizedShapeCount && textureDraws == 0 &&
                  shapeVertexBytes > 4096 && shapeBatches > 1 && vertexStride > 0 &&
                  maxShapeBatchVertexBytes > 0 && maxShapeBatchVertexBytes <= 4096;
    if (!bounded) {
        fprintf(stderr, "composable scene probe: failed consecutive_shape_batch_is_split_before_setVertexBytes_limit nodes=%u batches=%u texture_draws=%u vertex_stride=%u total_vertex_bytes=%llu max_batch_vertex_bytes=%llu\n",
                shapeNodes, shapeBatches, textureDraws, vertexStride, (unsigned long long)shapeVertexBytes,
                (unsigned long long)maxShapeBatchVertexBytes);
        (void)cjgui_internal_renderer_destroy(session);
        return 0;
    }
    printf("CJGUI_SHAPE_BATCH_BYTES vertex_stride=%u total_vertex_bytes=%llu max_batch_vertex_bytes=%llu set_vertex_bytes_limit=4096\n",
           vertexStride, (unsigned long long)shapeVertexBytes, (unsigned long long)maxShapeBatchVertexBytes);
    uint8_t blue = 0, green = 0, red = 0, alpha = 0;
    if (!require(capture_composable_pixel(session, 365, 86, &blue, &green, &red, &alpha) &&
                 require_bgra(blue, green, red, alpha, 194, 31, 235, 255,
                              "split_shape_batch_keeps_last_shape_painter_order"),
                 "oversized_consecutive_shape_batch_pixels")) { (void)cjgui_internal_renderer_destroy(session); return 0; }
    if (!require(cjgui_internal_renderer_request_close(session) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_destroy(session) == CJGUI_INTERNAL_RENDERER_OK,
                 "destroy_oversized_consecutive_shape_batch_window")) return 0;
    return 1;
}

typedef struct CjguiShapeSubmissionCost {
    uint32_t shapeNodes;
    uint32_t shapeDraws;
    uint64_t vertexBytes;
    uint64_t maxUploadBytes;
    uint64_t encodeMicros;
    uint8_t blue;
    uint8_t green;
    uint8_t red;
    uint8_t alpha;
} CjguiShapeSubmissionCost;

static int run_legal_shape_submission_cost_sample(uint8_t mode, const char *label,
                                                   CjguiShapeSubmissionCost *out) {
    if (!out) return 0;
    memset(out, 0, sizeof(*out));
    CjguiInternalRendererStatus status = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    CjguiInternalRendererConfig config = { 420, 180, 0.04, 0.08, 0.12, 1.0 };
    uint64_t session = cjgui_internal_renderer_create(&config, &status);
    if (!require(status == CJGUI_INTERNAL_RENDERER_OK && session != CJGUI_INTERNAL_RENDERER_INVALID_SESSION,
                 label)) return 0;
    enum { CjguiComparedShapeCount = 7 };
    CjguiInternalRendererComposableNode root = {
        .nodeId = 1930, .projectionVersion = 193,
        .x = 0, .y = 0, .width = 420, .height = 180,
        .clipX = 0, .clipY = 0, .clipWidth = 420, .clipHeight = 180,
        .nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_VERTICAL,
        .fillRed = 0.04, .fillGreen = 0.08, .fillBlue = 0.12, .fillAlpha = 1.0
    };
    if (!require(cjgui_internal_renderer_test_set_composable_shape_submission_mode(session, mode) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_configure_composable_scene(session, 193, CjguiComparedShapeCount) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_set_composable_scene_node(session, 0, &root, "shape-cost-root", "", "", "", 0) == CJGUI_INTERNAL_RENDERER_OK,
                 "stage_legal_shape_submission_cost_root")) { (void)cjgui_internal_renderer_destroy(session); return 0; }
    for (uint32_t index = 1; index < CjguiComparedShapeCount; index++) {
        CjguiInternalRendererComposableNode tile = root;
        tile.nodeId = 1930 + index;
        tile.x = 20.0 + ((double)(index - 1) * 62.0);
        tile.y = 50.0;
        tile.width = 54.0;
        tile.height = 72.0;
        tile.clipX = tile.x;
        tile.clipY = tile.y;
        tile.clipWidth = tile.width;
        tile.clipHeight = tile.height;
        tile.fillRed = index == CjguiComparedShapeCount - 1 ? 0.92 : 0.18;
        tile.fillGreen = index == CjguiComparedShapeCount - 1 ? 0.12 : 0.34;
        tile.fillBlue = index == CjguiComparedShapeCount - 1 ? 0.76 : 0.46;
        if (!require(cjgui_internal_renderer_set_composable_scene_node(session, index, &tile, "shape-cost-tile", "", "", "", 0) == CJGUI_INTERNAL_RENDERER_OK,
                     "stage_legal_shape_submission_cost_tile")) { (void)cjgui_internal_renderer_destroy(session); return 0; }
    }
    CjguiInternalRendererFrameObservation frame = {0};
    if (!require(cjgui_internal_renderer_present_composable_scene(session, &frame) == CJGUI_INTERNAL_RENDERER_OK,
                 "present_legal_shape_submission_cost_scene")) { (void)cjgui_internal_renderer_destroy(session); return 0; }
    uint32_t textureDraws = 0, vertexStride = 0;
    if (!require(cjgui_internal_renderer_test_composable_encoder_stats(session, &out->shapeNodes, &out->shapeDraws,
                                                                        &textureDraws, &out->vertexBytes) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_test_composable_encoder_batch_stats(session, &vertexStride, &out->maxUploadBytes) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_test_composable_encoder_cpu_stats(session, &out->encodeMicros) == CJGUI_INTERNAL_RENDERER_OK &&
                 out->shapeNodes == CjguiComparedShapeCount && textureDraws == 0 && vertexStride > 0 &&
                 out->vertexBytes == (uint64_t)CjguiComparedShapeCount * 6 * vertexStride &&
                 out->maxUploadBytes > 0 && out->maxUploadBytes <= 4096,
                 "read_legal_shape_submission_cost_stats")) { (void)cjgui_internal_renderer_destroy(session); return 0; }
    if (!require(capture_composable_pixel(session, 365, 86, &out->blue, &out->green, &out->red, &out->alpha) &&
                 require_bgra(out->blue, out->green, out->red, out->alpha, 194, 31, 235, 255,
                              "legal_shape_submission_keeps_painter_order"),
                 "read_legal_shape_submission_cost_pixel")) { (void)cjgui_internal_renderer_destroy(session); return 0; }
    if (!require(cjgui_internal_renderer_request_close(session) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_destroy(session) == CJGUI_INTERNAL_RENDERER_OK,
                 "destroy_legal_shape_submission_cost_scene")) return 0;
    return 1;
}

static int verify_legal_shape_submission_cost_comparison(void) {
    CjguiShapeSubmissionCost individual = {0};
    CjguiShapeSubmissionCost capacity = {0};
    if (!run_legal_shape_submission_cost_sample(1, "create_legal_individual_shape_submission_window", &individual)) return 0;
    if (!run_legal_shape_submission_cost_sample(0, "create_legal_capacity_shape_submission_window", &capacity)) return 0;
    printf("CJGUI_SHAPE_SUBMISSION_COST individual_draws=%u capacity_draws=%u individual_uploads=%u capacity_uploads=%u individual_vertex_bytes=%llu capacity_vertex_bytes=%llu individual_cpu_encode_us=%llu capacity_cpu_encode_us=%llu pixels_equal=%s\n",
           individual.shapeDraws, capacity.shapeDraws, individual.shapeDraws, capacity.shapeDraws,
           (unsigned long long)individual.vertexBytes, (unsigned long long)capacity.vertexBytes,
           (unsigned long long)individual.encodeMicros, (unsigned long long)capacity.encodeMicros,
           (individual.blue == capacity.blue && individual.green == capacity.green && individual.red == capacity.red && individual.alpha == capacity.alpha) ? "true" : "false");
    return require(individual.shapeDraws == 7 && capacity.shapeDraws == 3 &&
                   individual.vertexBytes == capacity.vertexBytes &&
                   individual.maxUploadBytes == 1056 && capacity.maxUploadBytes == 3168 &&
                   individual.maxUploadBytes <= 4096 && capacity.maxUploadBytes <= 4096 &&
                   individual.blue == capacity.blue && individual.green == capacity.green &&
                   individual.red == capacity.red && individual.alpha == capacity.alpha,
                   "compare_legal_shape_submission_costs_same_scene");
}

int main(void) {
    CjguiInternalRendererStatus status = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    CjguiInternalRendererConfig config = { 420, 180, 0.08, 0.16, 0.20, 1.0 };
    uint64_t session = cjgui_internal_renderer_create(&config, &status);
    if (!require(status == CJGUI_INTERNAL_RENDERER_OK && session != CJGUI_INTERNAL_RENDERER_INVALID_SESSION, "create")) return 1;

    CjguiInternalRendererComposableNode background = {
        .nodeId = 1, .projectionVersion = 77,
        .x = 0, .y = 0, .width = 420, .height = 180,
        .clipX = 0, .clipY = 0, .clipWidth = 420, .clipHeight = 180,
        .nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_VERTICAL,
        .isInteractive = 0, .borderWidth = 0,
        .fillRed = 0.94, .fillGreen = 0.95, .fillBlue = 0.97, .fillAlpha = 1.0,
        .borderRed = 0.0, .borderGreen = 0.0, .borderBlue = 0.0, .borderAlpha = 0.0
    };
    CjguiInternalRendererComposableNode textInput = {
        .nodeId = 22, .projectionVersion = 77,
        .x = 20, .y = 38, .width = 120, .height = 34,
        .clipX = 20, .clipY = 38, .clipWidth = 120, .clipHeight = 34,
        .nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT_INPUT,
        .isInteractive = 1, .borderWidth = 1,
        .fillRed = 1.0, .fillGreen = 1.0, .fillBlue = 1.0, .fillAlpha = 1.0,
        .borderRed = 0.10, .borderGreen = 0.20, .borderBlue = 0.40, .borderAlpha = 1.0
    };
    textInput.textRed = 0.75;
    textInput.textGreen = 0.12;
    textInput.textBlue = 0.14;
    textInput.textAlpha = 1.0;
    CjguiInternalRendererComposableNode booleanInput = {
        .nodeId = 23, .projectionVersion = 77,
        .x = 20, .y = 82, .width = 120, .height = 34,
        .clipX = 20, .clipY = 82, .clipWidth = 120, .clipHeight = 34,
        .nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_BOOLEAN_INPUT,
        .isInteractive = 1, .borderWidth = 1,
        .fillRed = 1.0, .fillGreen = 1.0, .fillBlue = 1.0, .fillAlpha = 1.0,
        .borderRed = 0.10, .borderGreen = 0.20, .borderBlue = 0.40, .borderAlpha = 1.0
    };
    CjguiInternalRendererComposableNode button = {
        .nodeId = 24, .projectionVersion = 77,
        .x = 20, .y = 126, .width = 120, .height = 34,
        .clipX = 20, .clipY = 126, .clipWidth = 120, .clipHeight = 34,
        .nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_BUTTON,
        .isInteractive = 1, .borderWidth = 1,
        .fillRed = 0.20, .fillGreen = 0.45, .fillBlue = 0.82, .fillAlpha = 1.0,
        .borderRed = 0.10, .borderGreen = 0.20, .borderBlue = 0.40, .borderAlpha = 1.0
    };
    CjguiInternalRendererComposableNode scrollArea = {
        .nodeId = 25, .projectionVersion = 77,
        .x = 200, .y = 38, .width = 180, .height = 110,
        .clipX = 200, .clipY = 38, .clipWidth = 180, .clipHeight = 110,
        .nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_SCROLL_AREA,
        .isInteractive = 1, .borderWidth = 1,
        .fillRed = 0.95, .fillGreen = 0.95, .fillBlue = 0.95, .fillAlpha = 1.0,
        .borderRed = 0.10, .borderGreen = 0.20, .borderBlue = 0.40, .borderAlpha = 1.0
    };
    CjguiInternalRendererComposableNode scrollChild = {
        .nodeId = 26, .projectionVersion = 77,
        .x = 210, .y = 50, .width = 150, .height = 30,
        .clipX = 200, .clipY = 38, .clipWidth = 180, .clipHeight = 110,
        .nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_BUTTON,
        .isInteractive = 1, .borderWidth = 1,
        .fillRed = 0.20, .fillGreen = 0.45, .fillBlue = 0.82, .fillAlpha = 1.0,
        .borderRed = 0.10, .borderGreen = 0.20, .borderBlue = 0.40, .borderAlpha = 1.0
    };
    if (!require(cjgui_internal_renderer_configure_composable_scene(session, 77, 6) == CJGUI_INTERNAL_RENDERER_OK, "configure")) return 1;
    if (!require(cjgui_internal_renderer_set_composable_scene_node(session, 0, &background, "根", "", "", "", 0) == CJGUI_INTERNAL_RENDERER_OK, "background")) return 1;
    if (!require(cjgui_internal_renderer_set_composable_scene_node(session, 1, &textInput, "规则名称", "alpha", "", "", 0) == CJGUI_INTERNAL_RENDERER_OK, "text_input")) return 1;
    if (!require(cjgui_internal_renderer_set_composable_scene_node(session, 2, &booleanInput, "启用规则", "true", "", "", 0) == CJGUI_INTERNAL_RENDERER_OK, "boolean_input")) return 1;
    if (!require(cjgui_internal_renderer_set_composable_scene_node(session, 3, &button, "应用草稿", "APPLY", "", "", 0) == CJGUI_INTERNAL_RENDERER_OK, "button")) return 1;
    if (!require(cjgui_internal_renderer_set_composable_scene_node(session, 4, &scrollArea, "规则列表", "", "", "", 0) == CJGUI_INTERNAL_RENDERER_OK, "scroll_area")) return 1;
    if (!require(cjgui_internal_renderer_set_composable_scene_node(session, 5, &scrollChild, "列表项", "SELECT", "", "", 0) == CJGUI_INTERNAL_RENDERER_OK, "scroll_child")) return 1;

    CjguiInternalRendererFrameObservation frame = {0};
    if (!require(cjgui_internal_renderer_present_composable_scene(session, &frame) == CJGUI_INTERNAL_RENDERER_OK, "present")) return 1;
    if (!require(frame.readbackAttempted == 1 && frame.readbackCompleted == 1 && frame.readbackColorMatched == 1, "metal_scene_readback")) return 1;

    id overlay = nil;
    for (NSView *candidate in NSApp.windows.lastObject.contentView.subviews) {
        if ([[candidate accessibilityChildren] count] == 5) { overlay = candidate; break; }
    }
    if (!require(overlay != nil, "accessibility_overlay")) return 1;
    if (!verify_readback_probe_selects_visible_opaque_nodes()) return 1;
    if (!verify_readback_probe_rejects_gpu_text_coverage()) return 1;
    if (!verify_readback_probe_rejects_self_gpu_text_coverage()) return 1;
    NSArray *actions = [overlay accessibilityChildren];
    id textAction = actions[0]; id booleanAction = actions[1]; id buttonAction = actions[2];
    if (!require([textAction accessibilityFrame].size.width > 0 && [textAction accessibilityFrame].size.height > 0, "text_accessibility_frame")) return 1;
    if (!require([booleanAction accessibilityFrame].size.width > 0 && [booleanAction accessibilityFrame].size.height > 0, "boolean_accessibility_frame")) return 1;
    if (!require([[textAction accessibilityLabel] isEqualToString:@"规则名称"] &&
                 [[[booleanAction accessibilityValue] description] isEqualToString:@"1"], "accessibility_label_value")) return 1;
    if (!require([buttonAction accessibilityPerformPress], "accessibility_button_action")) return 1;
    if (!require([buttonAction accessibilityFocused], "accessibility_button_focus")) return 1;
    CjguiInternalRendererEvent event = {0};
    if (!require(cjgui_internal_renderer_pump_event(session, 0, &event) == CJGUI_INTERNAL_RENDERER_OK, "pump")) return 1;
    // A real button press first publishes local focus, then its semantic
    // activation. This is not an obsolete one-event synthetic route: normal
    // window pump drains the bounded FIFO against one rendered snapshot.
    if (!require(event.kind == CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_FOCUS && event.recordIndex == 3 &&
                 event.nodeId == 24 && event.projectionVersion == 77, "stable_focus_event")) return 1;
    if (!require(cjgui_internal_renderer_pump_event(session, 0, &event) == CJGUI_INTERNAL_RENDERER_OK, "pump_activate")) return 1;
    if (!require(event.kind == CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_ACTIVATE && event.recordIndex == 3 &&
                 event.nodeId == 24 && event.projectionVersion == 77, "stable_event")) return 1;

    // This is an accessibility-edit path rather than a synthetic domain
    // mutation: Unicode text remains associated with the rendered field and
    // is copied out through the same native FIFO consumed by Cangjie.
    [textAction accessibilitySetValue:@"中文é"];
    if (!require(cjgui_internal_renderer_pump_event(session, 0, &event) == CJGUI_INTERNAL_RENDERER_OK, "pump_unicode_text")) return 1;
    if (!require(event.kind == CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_TEXT_CHANGED && event.nodeId == 22 &&
                 event.projectionVersion == 77 && strcmp(cjgui_internal_renderer_form_event_text(session), "中文é") == 0,
                 "unicode_text_keeps_stable_target")) return 1;

    // AppKit uses UTF-16 while public document positions are UTF-8 bytes.
    // The input bridge must never accept a surrogate/ZWJ interior as a
    // separate character boundary. Here 2..7 lands inside 🙂 and 👩‍💻; the
    // actual native selection is normalized to their composed 1..8 range,
    // and Backspace removes exactly those clusters rather than half of either.
    [textAction accessibilitySetValue:@"A🙂👩‍💻é\n中"];
    if (!require(cjgui_internal_renderer_pump_event(session, 0, &event) == CJGUI_INTERNAL_RENDERER_OK &&
                 event.kind == CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_TEXT_CHANGED,
                 "pump_unicode_composed_text")) return 1;
    if (!require(cjgui_internal_renderer_test_set_composable_selection(session, 1, 2, 7) == CJGUI_INTERNAL_RENDERER_OK,
                 "set_unicode_composed_selection")) return 1;
    if (!require(cjgui_internal_renderer_pump_event(session, 0, &event) == CJGUI_INTERNAL_RENDERER_OK &&
                 event.kind == CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_SELECTION_CHANGED &&
                 event.selectionStart == 1 && event.selectionEnd == 8,
                 "unicode_selection_rejects_interior_utf16")) return 1;
    uint64_t unicodeFocusedNode = 0;
    if (!require(cjgui_internal_renderer_test_send_composable_key(session, 51, 0, &unicodeFocusedNode) == CJGUI_INTERNAL_RENDERER_OK &&
                 unicodeFocusedNode == 22, "unicode_backspace_routes_to_textkit")) return 1;
    BOOL unicodeBackspaceApplied = NO;
    for (uint32_t attempt = 0; attempt < 3; attempt++) {
        if (!require(cjgui_internal_renderer_pump_event(session, 0, &event) == CJGUI_INTERNAL_RENDERER_OK,
                     "pump_unicode_backspace")) return 1;
        if (event.kind == CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_TEXT_CHANGED) {
            unicodeBackspaceApplied = strcmp(cjgui_internal_renderer_form_event_text(session), "Aé\n中") == 0;
            break;
        }
        if (event.kind == 0) break;
    }
    if (!require(unicodeBackspaceApplied, "unicode_backspace_preserves_clusters")) return 1;

    [overlay routeScrollAtPoint:NSMakePoint(240.0, 60.0) deltaY:-1.0];
    if (!require(cjgui_internal_renderer_pump_event(session, 0, &event) == CJGUI_INTERNAL_RENDERER_OK, "pump_scroll")) return 1;
    if (!require(event.kind == CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_SCROLL && event.recordIndex == 4 && event.nodeId == 25 &&
                 event.projectionVersion == 77, "scroll_routes_from_child_to_container")) return 1;

    // A saturated FIFO retains its already-accepted intents and reports one
    // explicit retry notice for the refused interaction.  It may not discard
    // or reinterpret the accepted nodes.
    for (uint32_t index = 0; index < 64; index++) {
        if (!require(cjgui_internal_renderer_test_enqueue_composable_event(
                session, 3, CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_ACTIVATE, "") == CJGUI_INTERNAL_RENDERER_OK,
                "enqueue_bounded_interaction")) return 1;
    }
    if (!require(cjgui_internal_renderer_test_enqueue_composable_event(
            session, 3, CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_ACTIVATE, "") == CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR,
            "refuse_interaction_after_capacity")) return 1;
    for (uint32_t index = 0; index < 64; index++) {
        if (!require(cjgui_internal_renderer_pump_event(session, 0, &event) == CJGUI_INTERNAL_RENDERER_OK &&
                     event.kind == CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_ACTIVATE && event.nodeId == 24,
                     "drain_accepted_interaction")) return 1;
    }
    if (!require(cjgui_internal_renderer_pump_event(session, 0, &event) == CJGUI_INTERNAL_RENDERER_OK &&
                 event.kind == CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_INPUT_QUEUE_FULL,
                 "queue_full_is_visible")) return 1;

    // A value/style refresh with the same interactive structure must keep
    // the existing AX elements. Recreating every action for every projection
    // makes a high-cardinality list look like 100 unrelated controls to
    // assistive clients.
    background.projectionVersion = 78; textInput.projectionVersion = 78;
    booleanInput.projectionVersion = 78; button.projectionVersion = 78;
    scrollArea.projectionVersion = 78; scrollChild.projectionVersion = 78;
    if (!require(cjgui_internal_renderer_configure_composable_scene(session, 78, 6) == CJGUI_INTERNAL_RENDERER_OK, "stage_same_structure_refresh")) return 1;
    if (!require(cjgui_internal_renderer_set_composable_scene_node(session, 0, &background, "根", "", "", "", 0) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_set_composable_scene_node(session, 1, &textInput, "规则名称", "中文é", "", "", 0) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_set_composable_scene_node(session, 2, &booleanInput, "启用规则", "true", "", "", 0) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_set_composable_scene_node(session, 3, &button, "应用草稿", "APPLY", "", "", 0) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_set_composable_scene_node(session, 4, &scrollArea, "规则列表", "", "", "", 0) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_set_composable_scene_node(session, 5, &scrollChild, "列表项", "SELECT", "", "", 0) == CJGUI_INTERNAL_RENDERER_OK,
                 "stage_same_structure_nodes")) return 1;
    if (!require(cjgui_internal_renderer_present_composable_scene(session, &frame) == CJGUI_INTERNAL_RENDERER_OK, "present_same_structure_refresh")) return 1;
    NSArray *refreshedActions = [overlay accessibilityChildren];
    if (!require(refreshedActions.count == 5 && refreshedActions[0] == textAction, "accessibility_identity_is_retained")) return 1;

    // Building a replacement scene must not expose an empty/partial AX and
    // hit-test projection before the final present commits it.
    if (!require(cjgui_internal_renderer_configure_composable_scene(session, 79, 1) == CJGUI_INTERNAL_RENDERER_OK, "stage_replacement")) return 1;
    if (!require([[overlay accessibilityChildren] count] == 5, "replacement_is_not_partially_published")) return 1;

    // A committed replacement must expose readable static content, retain a
    // selectable-but-not-editable field, and keep disabled controls visible
    // without making them actionable.  The former editable AX object is no
    // longer a live identity: it must not route a stale action to node index
    // zero of this new scene.
    CjguiInternalRendererComposableNode staticText = background;
    staticText.nodeId = 90; staticText.projectionVersion = 79;
    staticText.nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT;
    staticText.x = 20; staticText.y = 18; staticText.width = 220; staticText.height = 24;
    staticText.clipX = 20; staticText.clipY = 18; staticText.clipWidth = 220; staticText.clipHeight = 24;
    CjguiInternalRendererComposableNode readOnlyInput = textInput;
    readOnlyInput.nodeId = 91; readOnlyInput.projectionVersion = 79;
    readOnlyInput.resourceId = 991; readOnlyInput.isReadOnly = 1; readOnlyInput.isInteractive = 1;
    readOnlyInput.x = 20; readOnlyInput.y = 54; readOnlyInput.width = 220; readOnlyInput.height = 34;
    readOnlyInput.clipX = 20; readOnlyInput.clipY = 54; readOnlyInput.clipWidth = 220; readOnlyInput.clipHeight = 34;
    CjguiInternalRendererComposableNode disabledButton = button;
    disabledButton.nodeId = 92; disabledButton.projectionVersion = 79;
    disabledButton.resourceId = 992; disabledButton.isInteractive = 0;
    disabledButton.x = 20; disabledButton.y = 102; disabledButton.width = 140; disabledButton.height = 34;
    disabledButton.clipX = 20; disabledButton.clipY = 102; disabledButton.clipWidth = 140; disabledButton.clipHeight = 34;
    if (!require(cjgui_internal_renderer_configure_composable_scene(session, 79, 3) == CJGUI_INTERNAL_RENDERER_OK, "stage_accessibility_replacement")) return 1;
    if (!require(cjgui_internal_renderer_set_composable_scene_node(session, 0, &staticText, "", "可读状态", "", "", 0) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_set_composable_scene_node(session, 1, &readOnlyInput, "只读文档", "锁定内容", "", "", 0) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_set_composable_scene_node(session, 2, &disabledButton, "不可用操作", "DISABLED", "", "", 0) == CJGUI_INTERNAL_RENDERER_OK,
                 "stage_accessibility_replacement_nodes")) return 1;
    if (!require(cjgui_internal_renderer_present_composable_scene(session, &frame) == CJGUI_INTERNAL_RENDERER_OK, "present_accessibility_replacement")) return 1;
    NSArray *replacementActions = [overlay accessibilityChildren];
    if (!require(replacementActions.count == 3, "accessibility_replacement_child_count")) return 1;
    id staticAction = replacementActions[0]; id readOnlyAction = replacementActions[1]; id disabledAction = replacementActions[2];
    if (!require([[staticAction accessibilityRole] isEqualToString:NSAccessibilityStaticTextRole] &&
                 [[staticAction accessibilityValue] isEqualToString:@"可读状态"], "static_text_accessibility")) return 1;
    if (!require([[readOnlyAction accessibilityRole] isEqualToString:NSAccessibilityTextFieldRole] &&
                 [[readOnlyAction accessibilityValue] isEqualToString:@"锁定内容"] &&
                 ![readOnlyAction accessibilityIsAttributeSettable:NSAccessibilityValueAttribute] &&
                 [readOnlyAction accessibilityIsEnabled], "read_only_accessibility")) return 1;
    if (!require([[disabledAction accessibilityRole] isEqualToString:NSAccessibilityButtonRole] &&
                 ![disabledAction accessibilityIsEnabled] && ![disabledAction accessibilityPerformPress],
                 "disabled_accessibility_does_not_act")) return 1;
    if (!require(![textAction isAccessibilityElement] && ![textAction accessibilityPerformPress],
                 "stale_accessibility_identity_is_invalid")) return 1;
    if (!require(cjgui_internal_renderer_pump_event(session, 0, &event) == CJGUI_INTERNAL_RENDERER_OK && event.kind == 0,
                 "stale_accessibility_did_not_enqueue")) return 1;

    // Exact image pixels use a deterministic fixture rather than the
    // decorative transparent lighthouse resource.  The fixture is 2:1,
    // letting this one production Metal path prove FIT letterboxing, FILL
    // crop coverage, clip rejection, and alpha composition independently.
    char fixturePath[4096] = {0};
    if (!require(write_pixel_fixture(fixturePath, sizeof(fixturePath)), "write_pixel_fixture")) return 1;
    CjguiInternalRendererComposableNode fixtureRoot = background;
    fixtureRoot.nodeId = 800; fixtureRoot.projectionVersion = 80;
    fixtureRoot.x = 0; fixtureRoot.y = 0; fixtureRoot.width = 420; fixtureRoot.height = 180;
    fixtureRoot.clipX = 0; fixtureRoot.clipY = 0; fixtureRoot.clipWidth = 420; fixtureRoot.clipHeight = 180;
    fixtureRoot.fillRed = 0.10; fixtureRoot.fillGreen = 0.20; fixtureRoot.fillBlue = 0.30; fixtureRoot.fillAlpha = 1.0;
    CjguiInternalRendererComposableNode fixtureImage = fixtureRoot;
    fixtureImage.nodeId = 801; fixtureImage.x = 40; fixtureImage.y = 10; fixtureImage.width = 80; fixtureImage.height = 80;
    fixtureImage.clipX = 40; fixtureImage.clipY = 10; fixtureImage.clipWidth = 80; fixtureImage.clipHeight = 80;
    fixtureImage.nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_IMAGE;
    fixtureImage.imageContentMode = 1; // FIT: source draws 80x40 at y=30.
    fixtureImage.fillRed = 1.0; fixtureImage.fillGreen = 0.0; fixtureImage.fillBlue = 1.0; fixtureImage.fillAlpha = 1.0;
    fixtureImage.borderWidth = 0;
    if (!require(cjgui_internal_renderer_configure_composable_scene(session, 80, 2) == CJGUI_INTERNAL_RENDERER_OK, "stage_fixture_fit")) return 1;
    if (!require(cjgui_internal_renderer_set_composable_scene_node(session, 0, &fixtureRoot, "fixture-root", "", "", "", 0) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_set_composable_scene_node(session, 1, &fixtureImage, "fixture-image", "", fixturePath, "fixture-v1", 1) == CJGUI_INTERNAL_RENDERER_OK,
                 "stage_fixture_fit_nodes")) return 1;
    if (!require(wait_for_composable_image_ready(session, fixturePath, "fixture-v1", 1), "fixture_image_becomes_ready")) return 1;
    if (!require(cjgui_internal_renderer_configure_composable_scene(session, 80, 2) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_set_composable_scene_node(session, 0, &fixtureRoot, "fixture-root", "", "", "", 0) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_set_composable_scene_node(session, 1, &fixtureImage, "fixture-image", "", fixturePath, "fixture-v1", 1) == CJGUI_INTERNAL_RENDERER_OK,
                 "refresh_fixture_fit_after_ready")) return 1;
    uint8_t pixelBlue = 0, pixelGreen = 0, pixelRed = 0, pixelAlpha = 0;
    if (!require(cjgui_internal_renderer_test_request_composable_drawable_pixel(session, 70, 40) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_present_composable_scene(session, &frame) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_test_composable_drawable_pixel(session, &pixelBlue, &pixelGreen, &pixelRed, &pixelAlpha) == CJGUI_INTERNAL_RENDERER_OK,
                 "capture_fixture_fit_opaque")) return 1;
    if (!require_bgra(pixelBlue, pixelGreen, pixelRed, pixelAlpha, 48, 224, 16, 255, "fit_maps_opaque_green_source")) return 1;
    if (!require(capture_composable_pixel(session, 70, 20, &pixelBlue, &pixelGreen, &pixelRed, &pixelAlpha), "capture_fixture_fit_letterbox")) return 1;
    if (!require_bgra(pixelBlue, pixelGreen, pixelRed, pixelAlpha, 255, 0, 255, 255, "fit_letterbox_keeps_node_fill")) return 1;
    if (!require(capture_composable_pixel(session, 115, 40, &pixelBlue, &pixelGreen, &pixelRed, &pixelAlpha), "capture_fixture_transparent")) return 1;
    if (!require_bgra(pixelBlue, pixelGreen, pixelRed, pixelAlpha, 255, 0, 255, 255, "transparent_source_composes_node_fill")) return 1;
    if (!require(capture_composable_pixel(session, 90, 40, &pixelBlue, &pixelGreen, &pixelRed, &pixelAlpha), "capture_fixture_half_alpha")) return 1;
    if (!require_bgra(pixelBlue, pixelGreen, pixelRed, pixelAlpha, 239, 48, 143, 255, "half_alpha_source_composes_over_node_fill")) return 1;

    fixtureRoot.projectionVersion = 81; fixtureImage.projectionVersion = 81;
    fixtureImage.imageContentMode = 2; // FILL: source spans x=0..160 and crops red/transparent sides.
    if (!require(cjgui_internal_renderer_configure_composable_scene(session, 81, 2) == CJGUI_INTERNAL_RENDERER_OK, "stage_fixture_fill")) return 1;
    if (!require(cjgui_internal_renderer_set_composable_scene_node(session, 0, &fixtureRoot, "fixture-root", "", "", "", 0) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_set_composable_scene_node(session, 1, &fixtureImage, "fixture-image", "", fixturePath, "fixture-v1", 1) == CJGUI_INTERNAL_RENDERER_OK,
                 "stage_fixture_fill_nodes")) return 1;
    if (!require(cjgui_internal_renderer_test_request_composable_drawable_pixel(session, 45, 40) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_present_composable_scene(session, &frame) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_test_composable_drawable_pixel(session, &pixelBlue, &pixelGreen, &pixelRed, &pixelAlpha) == CJGUI_INTERNAL_RENDERER_OK,
                 "capture_fixture_fill_crop")) return 1;
    if (!require_bgra(pixelBlue, pixelGreen, pixelRed, pixelAlpha, 48, 224, 16, 255, "fill_crop_maps_visible_green_source")) return 1;

    fixtureRoot.projectionVersion = 82; fixtureImage.projectionVersion = 82;
    fixtureImage.clipX = 45; fixtureImage.clipWidth = 75;
    if (!require(cjgui_internal_renderer_configure_composable_scene(session, 82, 2) == CJGUI_INTERNAL_RENDERER_OK, "stage_fixture_clip")) return 1;
    if (!require(cjgui_internal_renderer_set_composable_scene_node(session, 0, &fixtureRoot, "fixture-root", "", "", "", 0) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_set_composable_scene_node(session, 1, &fixtureImage, "fixture-image", "", fixturePath, "fixture-v1", 1) == CJGUI_INTERNAL_RENDERER_OK,
                 "stage_fixture_clip_nodes")) return 1;
    if (!require(cjgui_internal_renderer_test_request_composable_drawable_pixel(session, 42, 40) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_present_composable_scene(session, &frame) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_test_composable_drawable_pixel(session, &pixelBlue, &pixelGreen, &pixelRed, &pixelAlpha) == CJGUI_INTERNAL_RENDERER_OK,
                 "capture_fixture_clip_outside")) return 1;
    if (!require_bgra(pixelBlue, pixelGreen, pixelRed, pixelAlpha, 77, 51, 26, 255, "clip_outside_keeps_root_background")) return 1;

    // Negative control: keep the same target point but omit the image draw.
    // The fixture's expected opaque-green source must now be absent, proving
    // the pixel assertion detects a skipped/incorrect resource projection.
    fixtureRoot.projectionVersion = 83; fixtureImage.projectionVersion = 83;
    fixtureImage.nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_VERTICAL;
    fixtureImage.clipX = 40; fixtureImage.clipWidth = 80;
    if (!require(cjgui_internal_renderer_configure_composable_scene(session, 83, 2) == CJGUI_INTERNAL_RENDERER_OK, "stage_fixture_image_omitted")) return 1;
    if (!require(cjgui_internal_renderer_set_composable_scene_node(session, 0, &fixtureRoot, "fixture-root", "", "", "", 0) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_set_composable_scene_node(session, 1, &fixtureImage, "fixture-image-omitted", "", "", "", 0) == CJGUI_INTERNAL_RENDERER_OK,
                 "stage_fixture_image_omitted_nodes")) return 1;
    if (!require(cjgui_internal_renderer_test_request_composable_drawable_pixel(session, 70, 40) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_present_composable_scene(session, &frame) == CJGUI_INTERNAL_RENDERER_OK &&
                 cjgui_internal_renderer_test_composable_drawable_pixel(session, &pixelBlue, &pixelGreen, &pixelRed, &pixelAlpha) == CJGUI_INTERNAL_RENDERER_OK,
                 "capture_fixture_image_omitted")) return 1;
    if (!require(!(abs((int)pixelBlue - 48) <= 10 && abs((int)pixelGreen - 224) <= 10 &&
                   abs((int)pixelRed - 16) <= 10 && abs((int)pixelAlpha - 255) <= 10),
                 "omitted_image_is_not_false_positive_green")) return 1;
    if (!verify_later_image_covers_text(session, fixturePath)) return 1;
    (void)remove(fixturePath);

    if (!verify_cross_type_text_ordering(session)) {
        (void)cjgui_internal_renderer_destroy(session);
        return 1;
    }
    if (!verify_static_text_orientation(session)) {
        (void)cjgui_internal_renderer_destroy(session);
        return 1;
    }
    if (!verify_active_input_stays_in_gpu_order(session)) {
        (void)cjgui_internal_renderer_destroy(session);
        return 1;
    }
    if (!verify_active_single_text_resource_failure_retries(session)) {
        (void)cjgui_internal_renderer_destroy(session);
        return 1;
    }
    if (!verify_active_selection_reuses_content_resource(session)) {
        (void)cjgui_internal_renderer_destroy(session);
        return 1;
    }
    if (!verify_failed_sparse_candidate_keeps_active_text_decorations(session)) {
        (void)cjgui_internal_renderer_destroy(session);
        return 1;
    }
    if (!verify_multiline_text_stays_in_gpu_order(session)) {
        (void)cjgui_internal_renderer_destroy(session);
        return 1;
    }
    if (!verify_text_resource_failure_is_atomic_and_retryable(session)) {
        (void)cjgui_internal_renderer_destroy(session);
        return 1;
    }
    if (!verify_text_texture_uses_visible_tile(session)) {
        (void)cjgui_internal_renderer_destroy(session);
        return 1;
    }
    if (!verify_ordinary_large_visible_text_tile()) {
        (void)cjgui_internal_renderer_destroy(session);
        return 1;
    }
    if (!verify_static_text_tile_invalidates_for_relative_node_offset()) {
        (void)cjgui_internal_renderer_destroy(session);
        return 1;
    }
    if (!verify_active_multiline_tile_invalidates_for_relative_node_offset()) {
        (void)cjgui_internal_renderer_destroy(session);
        return 1;
    }
    if (!verify_active_multiline_clip_shape_reprojects_same_tile()) {
        (void)cjgui_internal_renderer_destroy(session);
        return 1;
    }
    if (!verify_active_multiline_style_reprojects_same_tile()) {
        (void)cjgui_internal_renderer_destroy(session);
        return 1;
    }
    if (!verify_rounded_shape_and_clip(session)) {
        (void)cjgui_internal_renderer_destroy(session);
        return 1;
    }
    if (!verify_nested_rounded_clip_chain(session)) {
        (void)cjgui_internal_renderer_destroy(session);
        return 1;
    }
    if (!verify_consecutive_shape_batch_respects_vertex_bytes_limit()) {
        (void)cjgui_internal_renderer_destroy(session);
        return 1;
    }
    if (!verify_legal_shape_submission_cost_comparison()) {
        (void)cjgui_internal_renderer_destroy(session);
        return 1;
    }

    if (!require(cjgui_internal_renderer_request_close(session) == CJGUI_INTERNAL_RENDERER_OK, "close")) return 1;
    if (!require(cjgui_internal_renderer_destroy(session) == CJGUI_INTERNAL_RENDERER_OK, "destroy")) return 1;
    puts("composable scene probe: metal_rectangles=true readback=true image_pixels_fit_fill_clip_alpha=true accessibility_layout=true stable_event=true");
    return 0;
}

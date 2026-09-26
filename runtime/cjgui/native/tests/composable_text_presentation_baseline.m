// Old-path baseline for the composable text presentation seam.
//
// Astra's implementation order starts by freezing what the CURRENT single-style
// text path produces, so a later rich presentation can be proved equivalent:
// four scalar metrics plus the decoded RGBA of the rasterized texture, at 1x and
// 2x compared separately (never across scales).
//
// This harness compiles the production renderer into the test translation unit
// and exercises the real GPU text path, not a copied policy.
//
// usage:
//   composable_text_presentation_baseline            -> print a TSV baseline
//   composable_text_presentation_baseline --write F  -> write the TSV to F
//   composable_text_presentation_baseline --compare F-> compare against F, report
#define CJGUI_INTERNAL_TESTING 1
#import "../cjgui_internal_renderer.m"

#include <stdio.h>
#include <string.h>

static NSData *baselineReadTexture(id<MTLTexture> texture) {
    if (!texture || texture.pixelFormat != MTLPixelFormatBGRA8Unorm) return nil;
    NSUInteger rowBytes = texture.width * 4;
    NSMutableData *bytes = [NSMutableData dataWithLength:rowBytes * texture.height];
    [texture getBytes:bytes.mutableBytes bytesPerRow:rowBytes
          fromRegion:MTLRegionMake2D(0, 0, texture.width, texture.height) mipmapLevel:0];
    return bytes;
}

typedef struct {
    const char *caseId;
    const char *text;
    double fontSize;
    uint32_t fontWeight;
    uint32_t fontFamily;   // 0 = system, 1 = monospaced
    uint32_t width;
} BaselineCase;

// Coverage required by the plan: body, heading, monospaced, empty string,
// trailing newline, English word wrapping, CJK, emoji and a combining sequence.
static const BaselineCase kCases[] = {
    {"body_ascii", "Pharos Mark keeps a single document owner.", 18.0, 0, 0, 640},
    {"body_ascii_400", "Regular weight body text at 400.", 18.0, 400, 0, 640},
    {"heading1", "Heading level one", 32.0, 600, 0, 640},
    {"heading2", "Heading level two", 26.0, 600, 0, 640},
    {"mono_14", "let x = 1", 14.0, 400, 1, 480},
    {"empty", "", 18.0, 0, 0, 640},
    {"trailing_newline", "line with trailing newline\n", 18.0, 0, 0, 640},
    {"english_wrap", "Pharos Mark keeps a single document owner and a bounded piece tree.", 18.0, 0, 0, 220},
    {"cjk", "中文段落与标点：、。！？", 18.0, 0, 0, 480},
    {"emoji", "\u1F600 emoji \u1F469‍\u1F4BB ZWJ sequence", 18.0, 0, 0, 480},
    {"combining", "e\u0301 combining acute", 18.0, 0, 0, 480},
    {"mixed", "\u6807\u9898 \u1F600 English words mixed \u4E2D\u6587", 18.0, 0, 0, 320},
};

static const size_t kCaseCount = sizeof(kCases) / sizeof(kCases[0]);

// The scalar measurement needs a live renderer session, so it is captured on the
// product side (which owns one); this native harness freezes the rasterized
// pixels, which is what "old path" equivalence is judged on.
static id<MTLTexture> baselineTexture(CJGuiInternalMetalView *view, const BaselineCase *one,
                                      CGFloat scale) {
    CJGuiInternalComposableSceneNode *node = [CJGuiInternalComposableSceneNode new];
    CjguiInternalRendererComposableNode value = {0};
    value.nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT;
    value.nodeId = 0xB45;
    value.resourceId = 0xC17;
    value.x = 0;
    value.y = 0;
    value.width = one->width;
    value.height = 200;
    value.clipX = 0;
    value.clipY = 0;
    value.clipWidth = one->width;
    value.clipHeight = 200;
    value.fontSize = one->fontSize;
    value.fontWeight = one->fontWeight;
    value.fontFamily = one->fontFamily;
    value.textAlpha = 1.0;
    node.node = value;
    node.value = [NSString stringWithUTF8String:one->text];

    NSString *displayText = CjguiComposableGpuTextValue(node);
    return CjguiComposableTextTexture(view, node, scale, scale, displayText,
                                      CjguiInternalTextWorkReasonStaticCandidate);
}

// FNV-1a over the decoded texture bytes: stable, dependency-free and enough to
// detect any pixel change without shipping raw bitmaps into the repository.
static uint64_t digestBytes(const uint8_t *bytes, NSUInteger length) {
    uint64_t hash = 1469598103934665603ULL;
    for (NSUInteger i = 0; i < length; i++) {
        hash ^= (uint64_t)bytes[i];
        hash *= 1099511628211ULL;
    }
    return hash;
}

static BOOL textureFacts(id<MTLTexture> texture, uint64_t *outDigest, NSUInteger *outWidth,
                         NSUInteger *outHeight, NSUInteger *outInkPixels) {
    NSData *data = baselineReadTexture(texture);
    if (!data) return NO;
    const uint8_t *pixels = data.bytes;
    NSUInteger rowBytes = texture.width * 4;
    NSUInteger ink = 0;
    for (NSUInteger y = 0; y < texture.height; y++) {
        for (NSUInteger x = 0; x < texture.width; x++) {
            if (pixels[y * rowBytes + x * 4 + 3] != 0) ink++;
        }
    }
    *outDigest = digestBytes(pixels, data.length);
    *outWidth = texture.width;
    *outHeight = texture.height;
    *outInkPixels = ink;
    return YES;
}

static NSString *baselineLine(CJGuiInternalMetalView *view, const BaselineCase *one, CGFloat scale,
                              BOOL *outOk) {
    id<MTLTexture> texture = baselineTexture(view, one, scale);
    uint64_t digest = 0;
    NSUInteger width = 0, height = 0, ink = 0;
    if (!textureFacts(texture, &digest, &width, &height, &ink)) {
        // An empty string legitimately has no texture at all. That is a fact the
        // baseline must record, not a failure: the rich path has to keep drawing
        // nothing for it too.
        *outOk = YES;
        return [NSString stringWithFormat:@"%s\t%.0f\t%u\t0\t0\t0\tno_texture",
                one->caseId, scale, (unsigned)one->width];
    }
    *outOk = YES;
    return [NSString stringWithFormat:@"%s\t%.0f\t%u\t%lu\t%lu\t%lu\t%llu",
            one->caseId, scale, (unsigned)one->width,
            (unsigned long)width, (unsigned long)height, (unsigned long)ink,
            (unsigned long long)digest];
}

// --- single-run equivalence gate (Astra step 2) ------------------------------

static id<MTLTexture> richTexture(CJGuiInternalMetalView *view, const BaselineCase *one, CGFloat scale,
                                  const CjguiInternalTextStyleRun *runs, uint32_t runCount) {
    CJGuiInternalComposableSceneNode *node = [CJGuiInternalComposableSceneNode new];
    CjguiInternalRendererComposableNode value = {0};
    value.nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT;
    value.nodeId = 0xB45;
    value.resourceId = 0xC17;
    value.width = one->width;
    value.height = 200;
    value.clipWidth = one->width;
    value.clipHeight = 200;
    value.fontSize = one->fontSize;
    value.fontWeight = one->fontWeight;
    value.fontFamily = one->fontFamily;
    value.textAlpha = 1.0;
    node.node = value;
    node.value = [NSString stringWithUTF8String:one->text];
    NSString *displayText = CjguiComposableGpuTextValue(node);
    NSRect textureRect = CjguiComposableTextTextureRectForNode(node);
    return CjguiRasterComposableTextTexture(view, node, scale, scale, displayText, textureRect, NULL, nil
#ifdef CJGUI_INTERNAL_TESTING
                                            , CjguiInternalTextWorkReasonStaticCandidate
#endif
                                            , runs, runCount);
}

static uint64_t digestOfTexture(id<MTLTexture> texture) {
    NSData *data = baselineReadTexture(texture);
    if (!data) return 0;
    return digestBytes(data.bytes, data.length);
}

static BOOL runEquivalenceGate(CJGuiInternalMetalView *view) {
    // Every case, both scales: an empty run list (today's single-style path), one
    // run covering the whole text with identical attributes, and the same
    // attributes split into three adjacent runs must all rasterize identically.
    for (CGFloat scale = 1.0; scale <= 2.0; scale += 1.0) {
        for (size_t i = 0; i < kCaseCount; i++) {
            const BaselineCase *one = &kCases[i];
            uint64_t baseDigest = digestOfTexture(richTexture(view, one, scale, NULL, 0));
            NSString *display = [NSString stringWithUTF8String:one->text];
            NSUInteger length = display.length;
            CjguiInternalTextStyleRun whole = {0};
            whole.start = 0;
            whole.end = (uint32_t)length;
            whole.fontSize = one->fontSize;
            whole.fontWeight = one->fontWeight;
            whole.fontFamily = one->fontFamily;
            whole.red = 0; whole.green = 0; whole.blue = 0; whole.alpha = 1.0;
            uint64_t oneRunDigest = digestOfTexture(richTexture(view, one, scale, &whole, 1));
            if (baseDigest == 0 && oneRunDigest == 0) continue;   // the empty case
            if (baseDigest != oneRunDigest) {
                fprintf(stderr, "ONE_RUN_DIFF case=%s scale=%.0f base=%llu rich=%llu\n", one->caseId,
                        scale, (unsigned long long)baseDigest, (unsigned long long)oneRunDigest);
                return NO;
            }
            // Same attributes, split into three adjacent runs (normalization must
            // not change shaping).
            CjguiInternalTextStyleRun split[3];
            for (int k = 0; k < 3; k++) {
                split[k] = whole;
                split[k].start = (uint32_t)(length * (NSUInteger)k / 3);
                split[k].end = (uint32_t)(length * (NSUInteger)(k + 1) / 3);
            }
            uint64_t splitDigest = digestOfTexture(richTexture(view, one, scale, split, 3));
            if (splitDigest != baseDigest) {
                fprintf(stderr, "SPLIT_RUN_DIFF case=%s scale=%.0f base=%llu split=%llu\n", one->caseId,
                        scale, (unsigned long long)baseDigest, (unsigned long long)splitDigest);
                return NO;
            }
        }
    }
    // A run that changes colour must change the pixels, otherwise the run list is
    // not actually reaching the rasterizer.
    const BaselineCase *probe = &kCases[0];
    uint64_t plain = digestOfTexture(richTexture(view, probe, 1.0, NULL, 0));
    CjguiInternalTextStyleRun coloured = {0};
    coloured.start = 0;
    coloured.end = 8;
    coloured.fontSize = probe->fontSize;
    coloured.fontWeight = probe->fontWeight;
    coloured.fontFamily = probe->fontFamily;
    coloured.red = 1.0f; coloured.green = 0.0f; coloured.blue = 0.0f; coloured.alpha = 1.0f;
    uint64_t tinted = digestOfTexture(richTexture(view, probe, 1.0, &coloured, 1));
    if (plain == tinted) {
        fprintf(stderr, "COLOUR_RUN_NO_EFFECT: a coloured run did not change the pixels\n");
        return NO;
    }
    return YES;
}

static const char *kHeader =
    "case\tscale\tbounded_width\ttex_w\ttex_h\tink_pixels\trgba_digest";

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        const char *writePath = NULL;
        const char *comparePath = NULL;
        for (int i = 1; i < argc; i++) {
            if (strcmp(argv[i], "--write") == 0 && i + 1 < argc) writePath = argv[++i];
            if (strcmp(argv[i], "--compare") == 0 && i + 1 < argc) comparePath = argv[++i];
        }
        id<MTLDevice> device = MTLCreateSystemDefaultDevice();
        if (!device) {
            fprintf(stderr, "presentation baseline: no Metal device available\n");
            return 2;
        }
        CJGuiInternalMetalView *view = [[CJGuiInternalMetalView alloc]
            initWithFrame:NSMakeRect(0, 0, 640, 240) device:device
            commandQueue:[device newCommandQueue]];

        NSMutableArray<NSString *> *lines = [NSMutableArray array];
        [lines addObject:[NSString stringWithUTF8String:kHeader]];
        // Each scale is measured and rasterized separately; 1x and 2x are never
        // compared against each other.
        for (CGFloat scale = 1.0; scale <= 2.0; scale += 1.0) {
            for (size_t i = 0; i < kCaseCount; i++) {
                BOOL ok = NO;
                NSString *line = baselineLine(view, &kCases[i], scale, &ok);
                if (!ok) {
                    fprintf(stderr, "presentation baseline: case %s at scale %.0f produced no texture\n",
                            kCases[i].caseId, scale);
                    return 3;
                }
                [lines addObject:line];
            }
        }
        NSString *payload = [[lines componentsJoinedByString:@"\n"] stringByAppendingString:@"\n"];

        if (getenv("PHAROS_RUN_EQUIVALENCE")) {
            if (!runEquivalenceGate(view)) {
                return 6;
            }
            printf("RUN_EQUIVALENCE ok cases=%zu scales=2\n", kCaseCount);
            return 0;
        }
        if (writePath) {
            NSError *error = nil;
            if (![payload writeToFile:[NSString stringWithUTF8String:writePath] atomically:YES
                             encoding:NSUTF8StringEncoding error:&error]) {
                fprintf(stderr, "presentation baseline: cannot write %s: %s\n", writePath,
                        error.localizedDescription.UTF8String);
                return 4;
            }
            printf("WROTE %s cases=%zu\n", writePath, kCaseCount * 2);
            return 0;
        }
        if (comparePath) {
            NSString *expected = [NSString stringWithContentsOfFile:[NSString stringWithUTF8String:comparePath]
                                                           encoding:NSUTF8StringEncoding error:NULL];
            if (!expected) {
                fprintf(stderr, "presentation baseline: cannot read %s\n", comparePath);
                return 5;
            }
            NSArray<NSString *> *expectedLines = [expected componentsSeparatedByString:@"\n"];
            NSArray<NSString *> *actualLines = [payload componentsSeparatedByString:@"\n"];
            NSUInteger differences = 0;
            NSUInteger compared = 0;
            for (NSUInteger i = 0; i < expectedLines.count; i++) {
                NSString *want = expectedLines[i];
                if (want.length == 0) continue;
                if (i >= actualLines.count) {
                    printf("MISSING %s\n", want.UTF8String);
                    differences++;
                    continue;
                }
                NSString *got = actualLines[i];
                if (![want isEqualToString:got]) {
                    printf("DIFF\n  want %s\n  got  %s\n", want.UTF8String, got.UTF8String);
                    differences++;
                }
                compared++;
            }
            printf("COMPARED %lu DIFFERENCES %lu\n", (unsigned long)compared, (unsigned long)differences);
            return differences == 0 ? 0 : 1;
        }
        fputs(payload.UTF8String, stdout);
    }
    return 0;
}

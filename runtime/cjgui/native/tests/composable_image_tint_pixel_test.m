// Offscreen pixel consumer for composable image tint. It runs the production
// Metal image shader with the same vertex layout and tint rules as a window and
// reads back the private render target; no window or drawable is involved.
#define CJGUI_INTERNAL_TESTING 1
#import "../cjgui_internal_renderer.m"
#include <stdio.h>

typedef struct { const char *name; double r, g, b, a; } TintCase;

static id<MTLTexture> loadGlyph(id<MTLDevice> device, const char *path) {
    NSError *error = nil;
    NSDictionary *options = @{ MTKTextureLoaderOptionSRGB: @NO,
                               MTKTextureLoaderOptionGenerateMipmaps: @NO };
    MTKTextureLoader *loader = [[MTKTextureLoader alloc] initWithDevice:device];
    id<MTLTexture> texture = [loader newTextureWithContentsOfURL:
        [NSURL fileURLWithPath:[NSString stringWithUTF8String:path]]
        options:options error:&error];
    return texture;
}

static BOOL renderCase(id<MTLDevice> device, id<MTLTexture> glyph, TintCase c,
                       uint64_t *outCount, uint64_t *outAlpha,
                       uint64_t *outR, uint64_t *outG, uint64_t *outB) {
    const uint32_t width = 96, height = 96;
    CJGuiInternalMetalView *view = [[CJGuiInternalMetalView alloc]
        initWithFrame:NSMakeRect(0, 0, width, height) device:device
        commandQueue:[device newCommandQueue]];
    CjguiInternalRendererComposableNode raw = {0};
    raw.nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_IMAGE;
    raw.nodeId = 701; raw.resourceId = 702; raw.projectionVersion = 1;
    raw.x = 0; raw.y = 0; raw.width = width; raw.height = height;
    raw.clipX = 0; raw.clipY = 0; raw.clipWidth = width; raw.clipHeight = height;
    raw.clipConstraintCount = 1;
    raw.clip0X = 0; raw.clip0Y = 0; raw.clip0Width = width; raw.clip0Height = height;
    raw.imageContentMode = 1;
    raw.iconTintRed = c.r; raw.iconTintGreen = c.g;
    raw.iconTintBlue = c.b; raw.iconTintAlpha = c.a;
    CJGuiInternalComposableSceneNode *node = [CJGuiInternalComposableSceneNode new];
    node.node = raw;
    node.imageTexture = glyph;
    view.composableNodes = [NSMutableArray arrayWithObject:node];
    view.composableUsesMultisampling = NO;

    MTLTextureDescriptor *td = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatBGRA8Unorm
        width:width height:height mipmapped:NO];
    td.storageMode = MTLStorageModeShared; td.usage = MTLTextureUsageRenderTarget;
    id<MTLTexture> target = [device newTextureWithDescriptor:td];
    MTLRenderPassDescriptor *pass = [MTLRenderPassDescriptor renderPassDescriptor];
    pass.colorAttachments[0].texture = target;
    pass.colorAttachments[0].loadAction = MTLLoadActionClear;
    pass.colorAttachments[0].storeAction = MTLStoreActionStore;
    pass.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 0);
    id<MTLCommandBuffer> command = [view.commandQueue commandBuffer];
    id<MTLRenderCommandEncoder> encoder = [command renderCommandEncoderWithDescriptor:pass];
    if (!encoder) return NO;
    BOOL ok = CjguiEncodeComposableNodesRange(view, encoder, CGSizeMake(width, height),
        0, 0, width, height, 0, view.composableNodes.count, NSUIntegerMax);
    [encoder endEncoding];
    if (!ok) return NO;
    [command commit]; [command waitUntilCompleted];
    if (command.status != MTLCommandBufferStatusCompleted) return NO;

    NSMutableData *data = [NSMutableData dataWithLength:width * height * 4];
    [target getBytes:data.mutableBytes bytesPerRow:width * 4
         fromRegion:MTLRegionMake2D(0, 0, width, height) mipmapLevel:0];
    const uint8_t *p = data.bytes;
    uint64_t n = 0, a = 0, r = 0, g = 0, b = 0;
    for (NSUInteger i = 0; i < data.length; i += 4) {
        uint8_t bb = p[i], gg = p[i + 1], rr = p[i + 2], aa = p[i + 3];
        if (aa > 8) { n++; a += aa; r += rr; g += gg; b += bb; }
    }
    *outCount = n; *outAlpha = a; *outR = r; *outG = g; *outB = b;
    return YES;
}

int main(int argc, const char **argv) {
    @autoreleasepool {
        if (argc < 2) { fprintf(stderr, "usage: %s <monochrome.png> [json-out]\n", argv[0]); return 2; }
        id<MTLDevice> device = MTLCreateSystemDefaultDevice();
        if (!device) return 3;
        id<MTLTexture> glyph = loadGlyph(device, argv[1]);
        if (!glyph) { fprintf(stderr, "glyph load failed\n"); return 4; }
        const TintCase cases[] = {
            {"untinted", 0, 0, 0, 0},
            {"tint_absent_alpha_zero", 0.95, 0.35, 0.30, 0},
            {"tint_red", 0.95, 0.35, 0.30, 1},
            {"tint_blue", 0.30, 0.55, 0.98, 1},
            {"tint_red_half_alpha", 0.95, 0.35, 0.30, 0.5},
        };
        const size_t count = sizeof(cases) / sizeof(cases[0]);
        uint64_t m[sizeof(cases) / sizeof(cases[0])][5] = {{0}};
        FILE *out = argc > 2 ? fopen(argv[2], "w") : stdout;
        if (!out) return 5;
        fprintf(out, "{\"source\":\"production_image_shader_offscreen\",\"format\":\"BGRA8Unorm\",\"cases\":[\n");
        for (size_t i = 0; i < count; i++) {
            if (!renderCase(device, glyph, cases[i], &m[i][0], &m[i][1], &m[i][2], &m[i][3], &m[i][4])) return 6;
            fprintf(out, "{\"case\":\"%s\",\"inkPixels\":%llu,\"sumAlpha\":%llu,\"sumR\":%llu,\"sumG\":%llu,\"sumB\":%llu}%s\n",
                cases[i].name, (unsigned long long)m[i][0], (unsigned long long)m[i][1],
                (unsigned long long)m[i][2], (unsigned long long)m[i][3], (unsigned long long)m[i][4],
                i + 1 < count ? "," : "");
            if (argc > 2) printf("%s ink=%llu meanRGB=%.1f,%.1f,%.1f alpha=%.3f\n", cases[i].name,
                (unsigned long long)m[i][0],
                (double)m[i][2] / (double)(m[i][0] ? m[i][0] : 1),
                (double)m[i][3] / (double)(m[i][0] ? m[i][0] : 1),
                (double)m[i][4] / (double)(m[i][0] ? m[i][0] : 1),
                (double)m[i][1] / (255.0 * (double)(m[i][0] ? m[i][0] : 1)));
        }
        fprintf(out, "]}\n");
        if (argc > 2) fclose(out);

        const double eps = 1e-9;
        double unR = (double)m[0][2] / (m[0][0] + eps), unG = (double)m[0][3] / (m[0][0] + eps),
               unB = (double)m[0][4] / (m[0][0] + eps);
        double redR = (double)m[2][2] / (m[2][0] + eps), redG = (double)m[2][3] / (m[2][0] + eps),
               redB = (double)m[2][4] / (m[2][0] + eps);
        double blueR = (double)m[3][2] / (m[3][0] + eps), blueG = (double)m[3][3] / (m[3][0] + eps),
               blueB = (double)m[3][4] / (m[3][0] + eps);
        if (m[0][0] < 400) { fprintf(stderr, "glyph coverage too small\n"); return 7; }
        if (unR < 180 || unG < 180 || unB < 180 ||
            fabs(unR - unG) > 12 || fabs(unG - unB) > 12) {
            fprintf(stderr, "untinted glyph is not white\n"); return 8;
        }
        if (m[1][2] != m[0][2] || m[1][3] != m[0][3] || m[1][4] != m[0][4]) {
            fprintf(stderr, "alpha-zero tint is not the absent sentinel\n"); return 9;
        }
        if (!(redR > 180 && redG < 130 && redB < 120 && redR > redG + 60)) {
            fprintf(stderr, "red tint did not multiply the glyph\n"); return 10;
        }
        if (!(blueB > 180 && blueR < 130 && blueG < 170 && blueB > blueR + 60)) {
            fprintf(stderr, "blue tint did not multiply the glyph\n"); return 11;
        }
        if (!(m[4][1] > 0.40 * m[2][1] && m[4][1] < 0.60 * m[2][1])) {
            fprintf(stderr, "tint alpha was not applied to glyph coverage\n"); return 12;
        }
        printf("PASS untinted=(%.1f,%.1f,%.1f) red=(%.1f,%.1f,%.1f) blue=(%.1f,%.1f,%.1f) "
               "alpha_half=%.3f\n", unR, unG, unB, redR, redG, redB, blueR, blueG, blueB,
               (double)m[4][1] / (double)(m[2][1] ? m[2][1] : 1));
        return 0;
    }
}

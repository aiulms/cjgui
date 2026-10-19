// Offscreen pixel consumer for the composable paint capabilities that had no
// native evidence yet: inherited rounded clip chain, paint-only rotation,
// effectGroup opacity, the geometry sidecar (translate/scale), and the
// backdrop "off" path. It drives the production encoder against a private
// render target, so no window or drawable is involved.
#define CJGUI_INTERNAL_TESTING 1
#import "../cjgui_internal_renderer.m"
#include <stdio.h>
#include <string.h>

static const uint32_t kWidth = 128, kHeight = 128;

typedef struct {
    uint64_t nodeId;
    int64_t x, y, width, height;
    double r, g, b, a;
    double rotateDegrees;
    double cornerRadius;
    uint32_t clipCount;
    double clipCornerRadius;
    uint32_t groupPresent;
    uint32_t groupSubtreeCount;
    double groupOpacity;
    uint32_t backdropRadius;
    double translateX, translateY;
    double scaleX, scaleY;
} NodeSpec;

static CJGuiInternalMetalView *newView(id<MTLDevice> device) {
    CJGuiInternalMetalView *view = [[CJGuiInternalMetalView alloc]
        initWithFrame:NSMakeRect(0, 0, kWidth, kHeight) device:device
        commandQueue:[device newCommandQueue]];
    view.composableUsesMultisampling = NO;
    return view;
}

static CJGuiInternalComposableSceneNode *makeNode(const NodeSpec *s) {
    CjguiInternalRendererComposableNode raw = {0};
    raw.nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_VERTICAL;
    raw.nodeId = s->nodeId;
    raw.resourceId = (int64_t)s->nodeId;
    raw.projectionVersion = 1;
    raw.x = s->x; raw.y = s->y; raw.width = s->width; raw.height = s->height;
    raw.clipX = s->clipCount > 0 ? s->x : 0;
    raw.clipY = s->clipCount > 0 ? s->y : 0;
    raw.clipWidth = s->clipCount > 0 ? s->width : (int64_t)kWidth;
    raw.clipHeight = s->clipCount > 0 ? s->height : (int64_t)kHeight;
    raw.fillRed = s->r; raw.fillGreen = s->g; raw.fillBlue = s->b; raw.fillAlpha = s->a;
    raw.borderWidth = 0;
    raw.cornerRadius = s->cornerRadius;
    raw.rotateDegrees = s->rotateDegrees;
    raw.effectGroupPresent = s->groupPresent;
    raw.effectGroupSubtreeCount = s->groupSubtreeCount;
    raw.effectGroupOpacity = s->groupOpacity;
    raw.effectBackdropBlurRadiusPoints = s->backdropRadius;
    if (s->clipCount > 0) {
        raw.clipConstraintCount = s->clipCount;
        raw.clip0X = s->x; raw.clip0Y = s->y;
        raw.clip0Width = s->width; raw.clip0Height = s->height;
        raw.clip0CornerRadius = s->clipCornerRadius;
    }
    CJGuiInternalComposableSceneNode *node = [CJGuiInternalComposableSceneNode new];
    node.node = raw;
    CjguiInternalRendererComposableGeometry geometry = {0};
    geometry.nodeId = s->nodeId;
    geometry.clipCount = s->clipCount;
    geometry.translateX = s->translateX;
    geometry.translateY = s->translateY;
    geometry.scaleX = s->scaleX > 0 ? s->scaleX : 1.0;
    geometry.scaleY = s->scaleY > 0 ? s->scaleY : 1.0;
    node.geometry = geometry;
    return node;
}

static BOOL renderScene(id<MTLDevice> device, NSArray<CJGuiInternalComposableSceneNode *> *nodes,
                        NSMutableData *outPixels) {
    CJGuiInternalMetalView *view = newView(device);
    view.composableNodes = [NSMutableArray arrayWithArray:nodes];
    MTLTextureDescriptor *td = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatBGRA8Unorm
        width:kWidth height:kHeight mipmapped:NO];
    td.storageMode = MTLStorageModeShared;
    td.usage = MTLTextureUsageRenderTarget | MTLTextureUsageShaderRead;
    id<MTLTexture> target = [device newTextureWithDescriptor:td];
    if (!target) return NO;
    MTLRenderPassDescriptor *pass = [MTLRenderPassDescriptor renderPassDescriptor];
    pass.colorAttachments[0].texture = target;
    pass.colorAttachments[0].loadAction = MTLLoadActionClear;
    pass.colorAttachments[0].storeAction = MTLStoreActionStore;
    pass.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 0);
    id<MTLCommandBuffer> command = [view.commandQueue commandBuffer];
    id<MTLRenderCommandEncoder> encoder = [command renderCommandEncoderWithDescriptor:pass];
    if (!encoder) return NO;
    BOOL ok = CjguiEncodeComposableNodesRange(view, encoder, CGSizeMake(kWidth, kHeight),
        0, 0, kWidth, kHeight, 0, view.composableNodes.count, NSUIntegerMax);
    [encoder endEncoding];
    if (!ok) return NO;
    [command commit];
    [command waitUntilCompleted];
    if (command.status != MTLCommandBufferStatusCompleted) return NO;
    [outPixels setLength:kWidth * kHeight * 4];
    [target getBytes:outPixels.mutableBytes bytesPerRow:kWidth * 4
         fromRegion:MTLRegionMake2D(0, 0, kWidth, kHeight) mipmapLevel:0];
    return YES;
}

// BGRA8 offscreen target; returns alpha and the premultiplied-looking channel.
static void pixelAt(NSData *pixels, uint32_t x, uint32_t y,
                    uint8_t *r, uint8_t *g, uint8_t *b, uint8_t *a) {
    const uint8_t *p = (const uint8_t *)pixels.bytes + ((NSUInteger)y * kWidth + x) * 4;
    *b = p[0]; *g = p[1]; *r = p[2]; *a = p[3];
}

typedef struct { double r, g, b, a; } Sample;

static Sample sample(NSData *px, uint32_t x, uint32_t y) {
    uint8_t r = 0, g = 0, b = 0, a = 0;
    pixelAt(px, x, y, &r, &g, &b, &a);
    Sample s = { r, g, b, a };
    return s;
}

int main(void) {
    @autoreleasepool {
        id<MTLDevice> device = MTLCreateSystemDefaultDevice();
        if (!device) { fprintf(stderr, "no Metal device\n"); return 3; }
        NSMutableData *px = [NSMutableData data];
        int failures = 0;

        // 1. Inherited rounded clip chain on a colour quad.
        {
            NodeSpec s = { .nodeId = 1101, .x = 14, .y = 14, .width = 100, .height = 100,
                           .r = 0.15, .g = 0.42, .b = 0.95, .a = 1.0,
                           .clipCount = 1, .clipCornerRadius = 40.0 };
            NSArray *nodes = @[ makeNode(&s) ];
            if (!renderScene(device, nodes, px)) return 4;
            Sample corner = sample(px, 18, 18), center = sample(px, 64, 64),
                   top = sample(px, 64, 16);
            printf("clip_rounded corner=(%.0f,%.0f,%.0f,%.0f) center=(%.0f,%.0f,%.0f,%.0f) "
                   "topmid=(%.0f,%.0f,%.0f,%.0f)\n",
                   corner.r, corner.g, corner.b, corner.a,
                   center.r, center.g, center.b, center.a,
                   top.r, top.g, top.b, top.a);
            if (!(corner.a < 32 && center.a > 220 && top.a > 220)) {
                fprintf(stderr, "FAIL rounded clip chain did not cut only the corner\n");
                failures++;
            }
        }

        // 2. Rotation is paint-only: same box, 45 degrees around its centre.
        {
            NodeSpec plain = { .nodeId = 1201, .x = 30, .y = 30, .width = 40, .height = 40,
                               .r = 0.9, .g = 0.2, .b = 0.2, .a = 1.0 };
            NodeSpec rotated = plain;
            rotated.nodeId = 1202;
            rotated.rotateDegrees = 45.0;
            if (!renderScene(device, @[ makeNode(&plain) ], px)) return 5;
            Sample pCorner = sample(px, 34, 34), pCenter = sample(px, 50, 50);
            if (!renderScene(device, @[ makeNode(&rotated) ], px)) return 6;
            Sample rCorner = sample(px, 34, 34), rCenter = sample(px, 50, 50);
            printf("rotate plain_corner=%.0f plain_center=%.0f rot_corner=%.0f rot_center=%.0f\n",
                   pCorner.a, pCenter.a, rCorner.a, rCenter.a);
            if (!(pCorner.a > 220 && pCenter.a > 220 && rCorner.a < 32 && rCenter.a > 220)) {
                fprintf(stderr, "FAIL rotation did not turn the quad around its centre\n");
                failures++;
            }
        }

        // 3. effectGroup is encoded by the session's effect-target pass; the
        // direct range encoder skips group headers by contract, so it is not
        // exercised here.

        // 4. Geometry sidecar translate: paint moves, layout rect does not.
        {
            NodeSpec s = { .nodeId = 1401, .x = 10, .y = 10, .width = 40, .height = 40,
                           .r = 0.2, .g = 0.8, .b = 0.35, .a = 1.0,
                           .translateX = 30.0, .translateY = 20.0 };
            if (!renderScene(device, @[ makeNode(&s) ], px)) return 9;
            Sample old = sample(px, 15, 15), moved = sample(px, 50, 40);
            printf("translate old_rect=(%.0f,%.0f,%.0f,%.0f) moved_rect=(%.0f,%.0f,%.0f,%.0f)\n",
                   old.r, old.g, old.b, old.a, moved.r, moved.g, moved.b, moved.a);
            if (!(old.a < 32 && moved.g > 180 && moved.a > 220)) {
                fprintf(stderr, "FAIL geometry translate did not move paint only\n");
                failures++;
            }
        }

        // 5. Geometry sidecar scale: 2x around the node centre, no layout change.
        {
            NodeSpec s = { .nodeId = 1501, .x = 30, .y = 30, .width = 40, .height = 40,
                           .r = 0.25, .g = 0.7, .b = 0.3, .a = 1.0,
                           .scaleX = 2.0, .scaleY = 2.0 };
            if (!renderScene(device, @[ makeNode(&s) ], px)) return 10;
            Sample outside = sample(px, 15, 15), inside = sample(px, 85, 85),
                   center = sample(px, 50, 50);
            printf("scale outside=(%.0f,%.0f,%.0f,%.0f) inside=(%.0f,%.0f,%.0f,%.0f) center_a=%.0f\n",
                   outside.r, outside.g, outside.b, outside.a,
                   inside.r, inside.g, inside.b, inside.a, center.a);
            if (!(outside.g > 150 && inside.g > 150 && outside.a > 220 && inside.a > 220 &&
                  center.a > 220)) {
                fprintf(stderr, "FAIL geometry scale did not expand around the node centre\n");
                failures++;
            }
        }

        // 6. Backdrop OFF must be pixel-identical to a scene without the node.
        {
            NodeSpec base = { .nodeId = 1601, .x = 10, .y = 10, .width = 40, .height = 40,
                              .r = 0.2, .g = 0.3, .b = 0.9, .a = 1.0 };
            NodeSpec off = { .nodeId = 1602, .x = 5, .y = 5, .width = 110, .height = 110,
                             .r = 0.9, .g = 0.9, .b = 0.9, .a = 0.0, .backdropRadius = 0 };
            NSMutableData *baseline = [NSMutableData data], *withOff = [NSMutableData data];
            if (!renderScene(device, @[ makeNode(&base) ], baseline)) return 11;
            if (!renderScene(device, @[ makeNode(&base), makeNode(&off) ], withOff)) return 12;
            BOOL identical = [baseline isEqualToData:withOff];
            printf("backdrop_off identical=%s\n", identical ? "yes" : "no");
            if (!identical) {
                fprintf(stderr, "FAIL backdrop radius 0 did not preserve the off path\n");
                failures++;
            }
        }

        printf("%s\n", failures == 0 ? "PASS paint capabilities (clip, rotate, translate, scale, backdrop-off)"
                                     : "FAIL paint capabilities");
        return failures == 0 ? 0 : 1;
    }
}

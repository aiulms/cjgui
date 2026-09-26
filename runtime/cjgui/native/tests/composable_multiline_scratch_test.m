// This test compiles the production renderer implementation into the test
// translation unit so the multiline raster's CPU-scratch accounting is
// exercised on the exact production path (`rasterizeMultilineNode`), which
// previously allocated its BGRA bitmap without touching the shared counters.
//
// Stage "长文本增量更新与完整样式绑定" A2: the shared scratch counters must
// cover the active/multiline raster as well as the static raster, on success
// and on preparation failure, and current must honestly return to its prior
// value while peak records the transient high-water mark.
#define CJGUI_INTERNAL_TESTING 1
#import "../cjgui_internal_renderer.m"

#include <stdio.h>

static CJGuiInternalComposableSceneNode *multilineNode(void) {
    CJGuiInternalComposableSceneNode *node = [CJGuiInternalComposableSceneNode new];
    CjguiInternalRendererComposableNode n = {0};
    n.nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT;
    n.nodeId = 9;
    n.resourceId = 1;
    n.x = 0; n.y = 0; n.width = 300; n.height = 100;
    n.clipX = 0; n.clipY = 0; n.clipWidth = 300; n.clipHeight = 100;
    n.fontSize = 14;
    n.textAlpha = 1.0;
    node.node = n;
    node.value = @"第一行中文\n第二行 emoji 🙂\nthird line";
    return node;
}

int main(void) {
    @autoreleasepool {
        id<MTLDevice> device = MTLCreateSystemDefaultDevice();
        if (!device) {
            fprintf(stderr, "multiline scratch test: no Metal device available\n");
            return 2;
        }
        CJGuiInternalMetalView *view = [[CJGuiInternalMetalView alloc]
            initWithFrame:NSMakeRect(0, 0, 320, 140) device:device
            commandQueue:[device newCommandQueue]];
        CJGuiInternalSession *session = [CJGuiInternalSession new];
        session.view = view;
        CJGuiInternalComposableSceneOverlay *overlay =
            [[CJGuiInternalComposableSceneOverlay alloc] initWithFrame:NSZeroRect];
        overlay.session = session;

        uint64_t baseline = view.testComposableTextCpuScratchCurrentBytes;

        // 1. Success: allocation is counted, peak records it, and current
        //    honestly returns to the baseline after the raster.
        uint64_t outBytes = 0;
        id<MTLTexture> texture = [overlay rasterizeMultilineNode:multilineNode()
                                                          active:NO
                                                           scale:2.0
                                                        tileRect:NSMakeRect(0, 0, 300, 100)
                                                    outByteCount:&outBytes
                                                  outTextureRect:NULL
                                                          reason:CjguiInternalTextWorkReasonUnknown];
        if (!texture || outBytes == 0) {
            fprintf(stderr, "multiline raster should succeed with a real device\n");
            return 1;
        }
        if (view.testComposableTextCpuScratchCurrentBytes != baseline) {
            fprintf(stderr, "current scratch must return to baseline after success\n");
            return 3;
        }
        if (view.testComposableTextCpuScratchPeakBytes < outBytes) {
            fprintf(stderr, "peak scratch must cover the multiline raster allocation\n");
            return 4;
        }

        // 2. Preparation failure after allocation (device gone so the texture
        //    cannot be created): the drop must still run — current stays at the
        //    baseline while peak proves the transient allocation was counted.
        view.device = nil;
        view.testComposableTextCpuScratchPeakBytes = 0;
        uint64_t failedOut = 12345;
        id<MTLTexture> failed = [overlay rasterizeMultilineNode:multilineNode()
                                                          active:NO
                                                           scale:2.0
                                                        tileRect:NSMakeRect(0, 0, 300, 100)
                                                    outByteCount:&failedOut
                                                  outTextureRect:NULL
                                                          reason:CjguiInternalTextWorkReasonUnknown];
        if (failed != nil || failedOut != 0) {
            fprintf(stderr, "raster without a device must fail cleanly\n");
            return 5;
        }
        if (view.testComposableTextCpuScratchCurrentBytes != baseline) {
            fprintf(stderr, "current scratch must return to baseline after raster failure\n");
            return 6;
        }
        if (view.testComposableTextCpuScratchPeakBytes == 0) {
            fprintf(stderr, "failed raster must still have counted its transient allocation\n");
            return 7;
        }

        // 3. Never-allocated path (tile rect rejected before allocation): the
        //    counters must not move at all.
        view.testComposableTextCpuScratchPeakBytes = 0;
        id<MTLTexture> rejected = [overlay rasterizeMultilineNode:multilineNode()
                                                            active:NO
                                                             scale:2.0
                                                          tileRect:NSMakeRect(0, 0, 200000, 200000)
                                                      outByteCount:NULL
                                                    outTextureRect:NULL
                                                            reason:CjguiInternalTextWorkReasonUnknown];
        if (rejected != nil) {
            fprintf(stderr, "oversized tile rect must be rejected\n");
            return 8;
        }
        if (view.testComposableTextCpuScratchPeakBytes != 0 ||
            view.testComposableTextCpuScratchCurrentBytes != baseline) {
            fprintf(stderr, "rejected-before-allocation raster must not touch scratch counters\n");
            return 9;
        }
    }
    return 0;
}

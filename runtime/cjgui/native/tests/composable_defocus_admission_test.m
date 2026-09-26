// This test compiles the production renderer implementation into the test
// translation unit so the defocus re-admission (the text resource prepare
// pass) is exercised on the exact production rejection judgments.
//
// Stage "长文本增量更新与完整样式绑定" A3 (controlled evidence): the two
// distinguishable rejections — scene aggregate budget rejection and tile-plan
// failure — must both leave the rejected node's retained text resources
// (byte count, cache key, texture rect) untouched, and a subsequent healthy
// prepare must recover with fresh resources. The aggregate rejection is hit
// by staging a retained sibling whose fabricated byte count fills the 24MB
// production capacity (the production `FitsSceneBudget`-equivalent judgment
// inside the prepare pass); no capacity override is used.
#define CJGUI_INTERNAL_TESTING 1
#import "../cjgui_internal_renderer.m"
#import <AppKit/AppKit.h>

#include <stdio.h>

static CJGuiInternalComposableSceneNode *multilineNode(uint64_t nodeId, NSString *value) {
    CJGuiInternalComposableSceneNode *node = [CJGuiInternalComposableSceneNode new];
    CjguiInternalRendererComposableNode n = {0};
    n.nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT;
    n.nodeId = nodeId;
    n.resourceId = 1;
    n.x = 0; n.y = 0; n.width = 300; n.height = 100;
    n.clipX = 0; n.clipY = 0; n.clipWidth = 300; n.clipHeight = 100;
    n.fontSize = 14;
    n.textAlpha = 1.0;
    node.node = n;
    node.value = value;
    return node;
}

static void enlargeGeometry(CJGuiInternalComposableSceneNode *node, CGFloat width, CGFloat height) {
    CjguiInternalRendererComposableNode v = node.node;
    v.width = width; v.height = height;
    v.clipWidth = width; v.clipHeight = height;
    node.node = v;
}

static void markRetained(CJGuiInternalComposableSceneNode *node, uint64_t bytes) {
    node.textTextureByteCount = bytes;
    node.textTextureCacheKey = @"old-accepted-key";
    node.textTextureRect = NSMakeRect(0, 0, 300, 100);
}

int main(void) {
    @autoreleasepool {
        id<MTLDevice> device = MTLCreateSystemDefaultDevice();
        if (!device) {
            fprintf(stderr, "defocus admission test: no Metal device available\n");
            return 2;
        }
        CJGuiInternalMetalView *view = [[CJGuiInternalMetalView alloc]
            initWithFrame:NSMakeRect(0, 0, 320, 140) device:device
            commandQueue:[device newCommandQueue]];
        CJGuiInternalSession *ctx = [CJGuiInternalSession new];
        ctx.view = view;
        ctx.composableSceneOverlay =
            [[CJGuiInternalComposableSceneOverlay alloc] initWithFrame:NSZeroRect];
        ctx.composableSceneOverlay.session = ctx;
        CGFloat scale = MAX(1.0, [view currentBackingScale]);

        // --- Case 1: scene aggregate budget rejection. Index 0 is a retained
        // sibling whose byte count fills the whole production capacity (its
        // cache key matches its own geometry so the prepare pass treats it as
        // needsPreparation=false and charges the fabricated bytes). Index 1 is
        // the previously focused input being re-admitted after defocus; its
        // aggregate check must reject while every retained field survives.
        {
            CJGuiInternalComposableSceneNode *sibling = multilineNode(10, @"占位 sibling");
            NSString *sibText = CjguiComposableGpuTextValue(sibling);
            NSRect sibRect = CjguiComposableTextTextureRectForNode(sibling);
            sibling.textTexture = [view.device newTextureWithDescriptor:({
                MTLTextureDescriptor *d = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatBGRA8Unorm width:4 height:4 mipmapped:NO];
                d.usage = MTLTextureUsageShaderRead; d.storageMode = MTLStorageModeShared; d; })];
            sibling.textTextureCacheKey = CjguiComposableTextTextureKey(sibling, scale, scale, sibText, sibRect);
            sibling.textTextureByteCount = 24u * 1024u * 1024u;  // fills the whole capacity
            sibling.textTextureRect = sibRect;

            CJGuiInternalComposableSceneNode *defocused = multilineNode(9, @"旧内容 old body");
            markRetained(defocused, 555555);
            ctx.stagedComposableNodes = [NSMutableArray arrayWithArray:@[sibling, defocused]];
            ctx.composableNodes = [NSMutableArray arrayWithArray:@[sibling, defocused]];
            CjguiInternalRendererStatus status = CjguiPrepareComposableTextResources(ctx);
            if (status != CJGUI_INTERNAL_RENDERER_TEXT_RESOURCE_BUDGET_EXCEEDED) {
                fprintf(stderr, "aggregate rejection expected, got status=%d\n", (int)status);
                return 1;
            }
            if (defocused.textTextureByteCount != 555555) {
                fprintf(stderr, "rejected re-admission must keep old byte count\n");
                return 3;
            }
            if (![defocused.textTextureCacheKey isEqualToString:@"old-accepted-key"]) {
                fprintf(stderr, "rejected re-admission must keep old cache key\n");
                return 4;
            }
            if (defocused.textTextureRect.origin.x != 0 || defocused.textTextureRect.origin.y != 0 ||
                defocused.textTextureRect.size.width != 300 || defocused.textTextureRect.size.height != 100) {
                fprintf(stderr, "rejected re-admission must keep old texture rect\n");
                return 5;
            }
        }

        // --- Case 2: tile-plan failure on the re-admitted node itself (a
        // geometry whose tiles cannot fit the capacity). Same retention
        // contract on the other rejection judgment.
        {
            CJGuiInternalComposableSceneNode *defocused = multilineNode(11, @"恢复前 body");
            markRetained(defocused, 96000);
            enlargeGeometry(defocused, 200000, 200000);
            
            ctx.stagedComposableNodes = [NSMutableArray arrayWithArray:@[defocused]];
            ctx.composableNodes = [NSMutableArray arrayWithArray:@[defocused]];
            CjguiInternalRendererStatus status = CjguiPrepareComposableTextResources(ctx);
            if (status != CJGUI_INTERNAL_RENDERER_TEXT_RESOURCE_BUDGET_EXCEEDED) {
                fprintf(stderr, "plan-failure rejection expected, got status=%d\n", (int)status);
                return 6;
            }
            if (defocused.textTextureByteCount != 96000) {
                fprintf(stderr, "plan failure must keep old byte count\n");
                return 7;
            }
            if (![defocused.textTextureCacheKey isEqualToString:@"old-accepted-key"]) {
                fprintf(stderr, "plan failure must keep old cache key\n");
                return 8;
            }
        }

        // --- Case 3: recovery. With the pressure removed the same node
        //     re-admits and carries a fresh key, fresh bytes and a texture.
        {
            CJGuiInternalComposableSceneNode *defocused =
                multilineNode(12, @"恢复后 body after recovery");
            markRetained(defocused, 555555);
            ctx.stagedComposableNodes = [NSMutableArray arrayWithArray:@[defocused]];
            ctx.composableNodes = [NSMutableArray arrayWithArray:@[defocused]];
            CjguiInternalRendererStatus status = CjguiPrepareComposableTextResources(ctx);
            if (status != CJGUI_INTERNAL_RENDERER_OK) {
                fprintf(stderr, "healthy prepare expected, got status=%d\n", (int)status);
                return 9;
            }
            // The prepare pass clones the node when staged == live; the fresh
            // resource fields land on the staged copy.
            CJGuiInternalComposableSceneNode *staged = ctx.stagedComposableNodes.firstObject;
            if ([staged.textTextureCacheKey isEqualToString:@"old-accepted-key"]) {
                fprintf(stderr, "recovered node must carry a fresh cache key\n");
                return 10;
            }
            if (staged.textTexture == nil && staged.textTileTextures.count == 0) {
                fprintf(stderr, "recovered node must carry a fresh texture\n");
                return 11;
            }
            if (staged.textTextureByteCount == 555555 || staged.textTextureByteCount == 0) {
                fprintf(stderr, "recovered node must report fresh byte count\n");
                return 12;
            }
        }
    }
    return 0;
}

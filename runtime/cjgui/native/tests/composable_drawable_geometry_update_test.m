// A stable owner retry must not mutate CAMetalLayer geometry while its
// acquisition worker can be in nextDrawable. Actual resize/scale/layer changes
// must still reach the layer. This exercises the real view update method.
#define main CjguiDrawableGeometryPriorMain
#import "composable_preparation_batch_test.m"
#undef main

@interface GeometryCountingLayer : CAMetalLayer
@property(nonatomic) NSUInteger frameWrites;
@property(nonatomic) NSUInteger scaleWrites;
@property(nonatomic) NSUInteger sizeWrites;
@end
@implementation GeometryCountingLayer
- (void)setFrame:(CGRect)value { self.frameWrites++; [super setFrame:value]; }
- (void)setContentsScale:(CGFloat)value { self.scaleWrites++; [super setContentsScale:value]; }
- (void)setDrawableSize:(CGSize)value { self.sizeWrites++; [super setDrawableSize:value]; }
@end

int main(void) {
    @autoreleasepool {
        [NSApplication sharedApplication];
        id<MTLDevice> device=MTLCreateSystemDefaultDevice();
        CHECK(device!=nil,"device_available");
        if (!device) return 1;
        CJGuiInternalMetalView *view=[[CJGuiInternalMetalView alloc]
            initWithFrame:NSMakeRect(0,0,480,320) device:device commandQueue:[device newCommandQueue]];
        GeometryCountingLayer *layer=[GeometryCountingLayer layer];
        view.metalLayer=layer;view.testBackingScaleOverride=2;
        [view updateDrawableSize];
        NSUInteger frame=layer.frameWrites,scale=layer.scaleWrites,size=layer.sizeWrites;
        CHECK(CGSizeEqualToSize(layer.drawableSize,CGSizeMake(960,640)),"first_update_sets_real_texels");
        for (NSUInteger n=0;n<62;n++) [view updateDrawableSize];
        CHECK(layer.frameWrites==frame && layer.scaleWrites==scale && layer.sizeWrites==size,
            "stable_candidate_retries_do_not_write_metal_layer_geometry");
        [view setFrameSize:NSMakeSize(481,321)];[view updateDrawableSize];
        CHECK(CGSizeEqualToSize(layer.drawableSize,CGSizeMake(962,642)) && layer.sizeWrites==size+1,
            "actual_resize_updates_integral_texels_once");
        view.testBackingScaleOverride=1.5;[view viewDidChangeBackingProperties];
        CHECK(CGSizeEqualToSize(layer.drawableSize,CGSizeMake(722,482)) && layer.contentsScale==1.5,
            "backing_notification_updates_ceil_and_scale");
        GeometryCountingLayer *replacement=[GeometryCountingLayer layer];
        view.metalLayer=replacement;[view updateDrawableSize];
        CHECK(replacement.sizeWrites==1 && CGSizeEqualToSize(replacement.drawableSize,layer.drawableSize),
            "replacement_layer_receives_geometry_even_with_same_view_bounds");
        [view invalidateBridgeResources];
        NSUInteger retired=replacement.sizeWrites;[view updateDrawableSize];
        CHECK(replacement.sizeWrites==retired,"retired_view_does_not_touch_layer");
        fprintf(stderr,"drawable_geometry failures=%d\n",failures);
        return failures?1:0;
    }
}

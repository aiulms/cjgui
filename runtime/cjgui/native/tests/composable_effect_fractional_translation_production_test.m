// Same production GPU path and real completion as the original Home fixture.
// A fractional placement-only move must reuse the completed local content.
#define main localTranslationOriginalFixtureMain
#import "composable_effect_local_translation_production_test.m"
#undef main

static NSPoint fractionalLastSubmittedCompositePoint;
static NSUInteger fractionalSubmittedCompositeCount;
@interface FractionalCaptureEncoder : NSObject
@property(nonatomic,strong) id<MTLRenderCommandEncoder> real;
@end
@implementation FractionalCaptureEncoder
- (id)forwardingTargetForSelector:(SEL)selector { return self.real; }
- (void)setVertexBytes:(const void *)bytes length:(NSUInteger)length atIndex:(NSUInteger)index {
    if (index==0 && length==6*sizeof(CjguiEffectCompositeVertex)) {
        const float *values=bytes;
        fractionalLastSubmittedCompositePoint=NSMakePoint(values[2],values[3]);
        fractionalSubmittedCompositeCount++;
    }
    [self.real setVertexBytes:bytes length:length atIndex:index];
}
@end
@interface FractionalCaptureBuffer : NSObject
@property(nonatomic,strong) id<MTLCommandBuffer> real;
@end
@implementation FractionalCaptureBuffer
- (id)forwardingTargetForSelector:(SEL)selector { return self.real; }
- (id<MTLRenderCommandEncoder>)renderCommandEncoderWithDescriptor:(MTLRenderPassDescriptor *)descriptor {
    FractionalCaptureEncoder *wrapper=[FractionalCaptureEncoder new];
    wrapper.real=[self.real renderCommandEncoderWithDescriptor:descriptor];
    return (id<MTLRenderCommandEncoder>)wrapper;
}
@end
@interface FractionalCaptureQueue : NSObject
@property(nonatomic,strong) id<MTLCommandQueue> real;
@end
@implementation FractionalCaptureQueue
- (id)forwardingTargetForSelector:(SEL)selector { return self.real; }
- (id<MTLCommandBuffer>)commandBuffer {
    FractionalCaptureBuffer *wrapper=[FractionalCaptureBuffer new];wrapper.real=[self.real commandBuffer];
    return (id<MTLCommandBuffer>)wrapper;
}
@end

int main(void) {
    @autoreleasepool {
        CjguiInternalRendererConfig config = {.windowWidth=420,.windowHeight=320,.clearColorAlpha=1};
        CjguiInternalRendererStatus status = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
        uint64_t session=cjgui_internal_renderer_create(&config,&status);
        if(status!=CJGUI_INTERNAL_RENDERER_OK || !session) return 2;
        CJGuiInternalSession *ctx=CjguiLookupSession(session);
        id<MTLCommandQueue> originalQueue=ctx.view.commandQueue;
        FractionalCaptureQueue *captureQueue=[FractionalCaptureQueue new];captureQueue.real=originalQueue;
        ctx.view.commandQueue=(id<MTLCommandQueue>)captureQueue;
        localTranslationProbeLayer=ctx.view.metalLayer;
        Method method=class_getInstanceMethod(CAMetalLayer.class,@selector(nextDrawable));
        localTranslationOriginalNextDrawable=method_setImplementation(method,(IMP)localTranslationCaptureNextDrawable);
        BOOL failed=NO;
        const int64_t resources=980000;
        CjguiInternalRendererEffectStats first={0},moved={0};
        LocalTranslationReadback firstImage={0},movedImage={0},freshImage={0};
        failed |= !localTranslationRequire(localHomeSubmit(session,1,0,.125,
            "Daily notes", "10:42", "Review the latest project changes",resources,1.0f,.55f,NO,-1,YES),
            "fractional_first_real_scene");
        failed |= !localTranslationRequire(localHomeWaitCurrentTarget(ctx),"fractional_first_actual_gpu_completion");
        failed |= !localTranslationReadbackNow(session,&firstImage);
        CJGuiInternalComposableEffectTarget *original=ctx.view.composableNodes.firstObject.effectTarget;
        failed |= !localTranslationStats(session,&first);
        failed |= !localTranslationRequire(localHomeSubmit(session,2,0,.375,
            "Daily notes", "10:42", "Review the latest project changes",resources,1.0f,.55f,NO,-1,YES),
            "fractional_original_move_once");
        failed |= !localTranslationReadbackNow(session,&movedImage);
        failed |= !localTranslationRequire(fractionalSubmittedCompositeCount>=2 &&
            fabs(fractionalLastSubmittedCompositePoint.x-52.0)<0.00001 &&
            fabs(fractionalLastSubmittedCompositePoint.y-82.375)<0.00001,
            "fractional_actual_submitted_quad_retains_exact_current_point");
        failed |= !localTranslationRequire(!localHomeSameImage(&firstImage,&movedImage),
            "fractional_placement_changes_real_drawable_before_next_event");
        failed |= !localTranslationStats(session,&moved);
        failed |= !localHomeCheckDelta("fractional_placement_only_reuses_completed_content",first,moved,0,0,1);
        failed |= !localTranslationRequire(ctx.view.composableNodes.firstObject.effectTarget==original,
            "fractional_same_completed_target_retained");
        // General spring positions, including negative translations, must not
        // turn subtraction noise into a new content identity.
        const double positions[] = {.153753426135, .233842159313, -.287421352137, .499999999999};
        uint64_t version=3;
        for (NSUInteger i=0;i<sizeof(positions)/sizeof(positions[0]);i++) {
            CjguiInternalRendererEffectStats before={0},after={0};
            failed |= !localTranslationStats(session,&before);
            failed |= !localTranslationRequire(localHomeSubmit(session,version++,0,positions[i],
                "Daily notes", "10:42", "Review the latest project changes",resources,1.0f,.55f,NO,-1,YES),
                "fractional_spring_original_position");
            failed |= !localTranslationStats(session,&after);
            failed |= !localHomeCheckDelta("fractional_spring_reuses_original_content",before,after,0,0,1);
        }
        failed |= !localTranslationRequire(localHomeSubmit(session,version++,0,.375,
            "Daily notes", "10:42", "Review the latest project changes",resources,1.0f,.55f,NO,-1,YES),
            "fractional_return_same_original_point");
        localHomeReleaseImage(&movedImage);
        failed |= !localTranslationReadbackNow(session,&movedImage);
        // New resource identity forces a fresh render at the SAME final point.
        // Its complete drawable bytes remain the independent visual control.
        failed |= !localTranslationRequire(localHomeSubmit(session,version++,0,.375,
            "Daily notes", "10:42", "Review the latest project changes",resources+100,1.0f,.55f,NO,-1,YES),
            "fractional_fresh_resources_visual_reference");
        failed |= !localTranslationReadbackNow(session,&freshImage);
        failed |= !localTranslationRequire(localHomeSameImage(&movedImage,&freshImage),
            "fractional_reused_drawable_matches_fresh_drawable_all_bytes");
        fprintf(stderr,"HOME_FRACTIONAL_RESULT failures=%d allocations_delta=%llu redraws_delta=%llu reuse_delta=%llu\n",
            failed,(unsigned long long)(moved.targetAllocations-first.targetAllocations),
            (unsigned long long)(moved.contentRedraws-first.contentRedraws),
            (unsigned long long)(moved.targetReuses-first.targetReuses));
        localHomeReleaseImage(&firstImage);localHomeReleaseImage(&movedImage);localHomeReleaseImage(&freshImage);
        method_setImplementation(method,localTranslationOriginalNextDrawable);
        localTranslationCapturedDrawable=nil;localTranslationProbeLayer=nil;
        ctx.view.commandQueue=originalQueue;
        cjgui_internal_renderer_destroy(session);
        return failed ? 1 : 0;
    }
}

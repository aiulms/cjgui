// Count real private paint-node construction on the existing production path.
#define main previousFractionalFixtureMain
#import "composable_effect_local_translation_production_test.m"
#undef main
#include <stdatomic.h>
static _Atomic(uint64_t) prepareNodeAllocations;
static IMP prepareOriginalAlloc;
typedef id (*PrepareAllocFunction)(id,SEL,NSZone *) __attribute__((ns_returns_retained));
static id prepareCountAlloc(id cls,SEL sel,NSZone *zone) __attribute__((ns_returns_retained));
static id prepareCountAlloc(id cls,SEL sel,NSZone *zone) {
    if (cls==CJGuiInternalComposableSceneNode.class) atomic_fetch_add(&prepareNodeAllocations,1);
    return ((PrepareAllocFunction)prepareOriginalAlloc)(cls,sel,zone);
}
int main(void) {
 @autoreleasepool {
    CjguiInternalRendererConfig config={.windowWidth=420,.windowHeight=320,.clearColorAlpha=1};
    CjguiInternalRendererStatus status=CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    uint64_t session=cjgui_internal_renderer_create(&config,&status);
    if(status!=CJGUI_INTERNAL_RENDERER_OK||!session)return 2;
    CJGuiInternalSession *ctx=CjguiLookupSession(session);
    localTranslationProbeLayer=ctx.view.metalLayer;
    Method drawable=class_getInstanceMethod(CAMetalLayer.class,@selector(nextDrawable));
    localTranslationOriginalNextDrawable=method_setImplementation(drawable,(IMP)localTranslationCaptureNextDrawable);
    BOOL failed=!localHomeSubmit(session,1,0,.125,"Daily notes","10:42","Review the latest project changes",980000,1,.55,NO,-1,YES);
    failed |= !localHomeWaitCurrentTarget(ctx);
    Class meta=object_getClass(CJGuiInternalComposableSceneNode.class);
    Method alloc=class_getClassMethod(CJGuiInternalComposableSceneNode.class,@selector(allocWithZone:));
    prepareOriginalAlloc=method_getImplementation(alloc);
    class_addMethod(meta,@selector(allocWithZone:),(IMP)prepareCountAlloc,method_getTypeEncoding(alloc));
    atomic_store(&prepareNodeAllocations,0);
    uint64_t start=CjguiDiagnosticMonotonicNanoseconds();
    for(int i=0;i<50;i++) {
        failed |= CjguiPrepareEffectTargets(ctx.view,ctx.view.metalLayer.drawableSize)!=CJGUI_INTERNAL_RENDERER_OK;
    }
    uint64_t end=CjguiDiagnosticMonotonicNanoseconds(),allocations=atomic_load(&prepareNodeAllocations);
    class_replaceMethod(meta,@selector(allocWithZone:),prepareOriginalAlloc,method_getTypeEncoding(alloc));
    fprintf(stderr,"PREPARE_INPUT_REUSE original_unchanged_GPU_ready_hits=50 private_paint_nodes_created=%llu wall_ns=%llu\n",(unsigned long long)allocations,(unsigned long long)(end-start));
    failed |= !localTranslationRequire(allocations==0,"unchanged_completed_content_hit_does_not_reconstruct_private_paint_nodes");
    method_setImplementation(drawable,localTranslationOriginalNextDrawable);
    localTranslationCapturedDrawable=nil;localTranslationProbeLayer=nil;
    cjgui_internal_renderer_destroy(session);
    return failed?1:0;
 }
}

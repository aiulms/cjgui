#define CJGUI_INTERNAL_TESTING 1
#import "../cjgui_internal_renderer.m"
#import "../cjgui_async_multiline_measure.h"
#include <stdio.h>
#include <time.h>
#pragma clang diagnostic error "-Wincompatible-pointer-types"

// The pre-implementation RED records missing bridge symbols at link time.
// It proves an absent capability; it is not an existing runtime regression.
extern int32_t cjgui_internal_renderer_font_resource_register(uint32_t,const char *,uint32_t,uint32_t *) __attribute__((weak_import));
extern int32_t cjgui_internal_renderer_font_resource_release(uint32_t) __attribute__((weak_import));
extern int32_t cjgui_internal_renderer_font_resource_stats(uint64_t *) __attribute__((weak_import));
extern int32_t cjgui_async_composable_multiline_typography_begin(const char *,uint64_t,double,
    uint32_t,uint32_t,uint32_t,double,double,uint64_t *);
static uint64_t monotonicNs(void){struct timespec t;clock_gettime(CLOCK_MONOTONIC,&t);return (uint64_t)t.tv_sec*1000000000ull+t.tv_nsec;}
static void *foreignThread(void *source) {
    // Deliberately no caller autorelease pool, like an ordinary foreign thread.
    for(int i=0;i<100;i++){
        uint32_t code=0;
        if(cjgui_internal_renderer_font_resource_register(2,source,0,&code)!=0 ||
           cjgui_internal_renderer_font_resource_release(code)!=0)return (void *)1;
    }
    return NULL;
}
static int failures;
#define CHECK(c,n) do { BOOL ok=(c);fprintf(stderr,"font_resource case=%s result=%s\n",n,ok?"PASS":"FAIL");if(!ok)failures++; }while(0)
static BOOL fontReadChanged;
static void GrowFontAfterStat(const char *path) {
    int descriptor=open(path,O_WRONLY|O_CLOEXEC);
    fontReadChanged=descriptor>=0 && ftruncate(descriptor,17*1024*1024)==0;
    if(descriptor>=0)close(descriptor);
}
static void CheckChangingFontFile(const char *fixture) {
    NSString *directory=[NSTemporaryDirectory() stringByAppendingPathComponent:NSUUID.UUID.UUIDString];
    NSString *path=[directory stringByAppendingPathComponent:@"changing-font.ttf"];
    [[NSFileManager defaultManager] createDirectoryAtPath:directory withIntermediateDirectories:NO attributes:nil error:NULL];
    @try {
        CHECK([[NSFileManager defaultManager] copyItemAtPath:[NSString stringWithUTF8String:fixture] toPath:path error:NULL],"changing_font_original_copied");
        uint64_t before[5]={0},after[5]={0};uint32_t code=0;
        cjgui_internal_renderer_font_resource_stats(before);
        gCjguiFontTestReadAfterStat=GrowFontAfterStat;
        int status=cjgui_internal_renderer_font_resource_register(2,path.fileSystemRepresentation,0,&code);
        gCjguiFontTestReadAfterStat=NULL;
        cjgui_internal_renderer_font_resource_stats(after);
        CHECK(fontReadChanged,"actual_open_file_grew_after_initial_stat");
        CHECK(status==3 && code>=4,"changed_font_is_explicit_invalid_fallback");
        CHECK(after[2]==before[2],"changed_font_never_retains_over_limit_data");
        if(code)cjgui_internal_renderer_font_resource_release(code);
    } @finally {
        gCjguiFontTestReadAfterStat=NULL;
        [[NSFileManager defaultManager] removeItemAtPath:directory error:NULL];
    }
}
static void CheckLabelledInputPositions(uint32_t font) {
    CJGuiInternalSession *ctx=[CJGuiInternalSession new];
    id<MTLDevice> device=MTLCreateSystemDefaultDevice();
    ctx.view=[[CJGuiInternalMetalView alloc] initWithFrame:NSMakeRect(0,0,600,80)
        device:device commandQueue:[device newCommandQueue]];
    ctx.composableSceneVersion=1;
    ctx.composableSceneOverlay=[[CJGuiInternalComposableSceneOverlay alloc]
        initWithFrame:NSMakeRect(0,0,600,80) session:ctx];
    uint64_t token=CjguiAllocateSession(ctx);
    for(NSString *body in @[@"BCxa",@"中👩🏽‍💻é"]){
        CJGuiInternalComposableSceneNode *node=[CJGuiInternalComposableSceneNode new];
        node.node=(CjguiInternalRendererComposableNode){.nodeId=101,.resourceId=6201,
            .nodeKind=CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT_INPUT,.projectionVersion=1,
            .width=600,.height=40,.fontSize=17,.fontFamily=font,.textAlpha=1};
        node.label=@"打印任务";node.value=body;
        ctx.composableSceneOverlay.nodes=@[node];
        NSMutableArray<NSNumber *> *bytes=[NSMutableArray arrayWithObject:@0];
        [body enumerateSubstringsInRange:NSMakeRange(0,body.length)
            options:NSStringEnumerationByComposedCharacterSequences
            usingBlock:^(NSString *part,NSRange range,NSRange enclosing,BOOL *stop){
                [bytes addObject:@([[body substringToIndex:NSMaxRange(range)] lengthOfBytesUsingEncoding:NSUTF8StringEncoding])];
            }];
        BOOL right=YES,left=YES,hit=YES;
        for(NSUInteger i=0;i<bytes.count;i++){
            uint64_t m[8]={0};double r[4]={0};
            int status=cjgui_internal_renderer_text_position_v1(token,101,1,0,bytes[i].longLongValue,2,0,0,0,0,0,m,r);
            double caretX=r[0],caretY=r[1]+r[3]/2;
            hit &= status==0 && cjgui_internal_renderer_text_position_v1(token,101,1,1,0,2,0,0,0,caretX,caretY,m,r)==0 && m[2]==bytes[i].unsignedLongLongValue;
            if(i+1<bytes.count)right &= cjgui_internal_renderer_text_position_v1(token,101,1,2,bytes[i].longLongValue,2,0,0,1,0,0,m,r)==0 && m[2]==bytes[i+1].unsignedLongLongValue;
            if(i>0)left &= cjgui_internal_renderer_text_position_v1(token,101,1,2,bytes[i].longLongValue,2,0,0,0,0,0,m,r)==0 && m[2]==bytes[i-1].unsignedLongLongValue;
        }
        CHECK(right,"labelled_input_right_moves_only_value_clusters");
        CHECK(left,"labelled_input_left_moves_only_value_clusters");
        CHECK(hit,"labelled_input_caret_hit_roundtrip_uses_value_bytes");
        uint64_t m[8]={0};double r[4]={0};
        CHECK(cjgui_internal_renderer_text_position_v1(token,101,1,2,0,2,0,0,0,0,0,m,r)==0 && m[2]==0 && m[7],
            "labelled_input_start_cannot_enter_label");
    }
    CjguiReleaseSession(token);
}
static __weak id gRetiredFontAcquire;
__attribute__((noinline)) static void BorrowRetainedFont(uint32_t code){
    id lease=CjguiFontResourceLease(code);gRetiredFontAcquire=lease;
    CHECK(lease!=nil,"internal_retained_font_acquire_is_live_during_use");
}
static void CheckFontAcquireBoundary(void){
    uint32_t code=0;
    CHECK(cjgui_internal_renderer_font_resource_register(1,"Georgia",0,&code)==0,"acquire_boundary_registers_font");
    BorrowRetainedFont(code);
    CHECK(cjgui_internal_renderer_font_resource_release(code)==0,"acquire_boundary_retires_registry_owner");
    // The caller's surrounding autorelease pool is deliberately still open.
    CHECK(gRetiredFontAcquire==nil,"font_acquire_retires_without_caller_pool_drain");
}
int main(int argc,const char **argv) { @autoreleasepool {
    [NSApplication sharedApplication];
    CheckFontAcquireBoundary();
    CHECK(cjgui_internal_renderer_font_resource_register!=NULL,"public_font_resource_registration_available");
    if(!cjgui_internal_renderer_font_resource_register)return 1;
    if(argc==2)CheckChangingFontFile(argv[1]);
    uint32_t serif=0, fixture=0, missing=0;
    double wa=0,wb=0;uint64_t cold[5]={0},hot[5]={0};
    @autoreleasepool {
    CHECK(cjgui_internal_renderer_font_resource_register(1,"Georgia",0,&serif)==0 && serif>=4,"system_family_resolves_once");
    CHECK(argc==2 && cjgui_internal_renderer_font_resource_register(2,argv[1],0,&fixture)==0 && fixture>serif,"bundle_font_resolves_new_generation");
    NSFont *a=CjguiComposableFontSnapshotForStyle(18,0,serif);
    NSFont *b=CjguiComposableFontSnapshotForStyle(18,0,fixture);
    CHECK([a.familyName isEqualToString:@"Georgia"] && [b.familyName containsString:@"Lilex"],"actual_font_families_are_selected");
    CheckLabelledInputPositions(serif);
    CheckLabelledInputPositions(fixture);
    CheckLabelledInputPositions(0);
    wa=[@"iiiiWWWW" sizeWithAttributes:@{NSFontAttributeName:a}].width;
    wb=[@"iiiiWWWW" sizeWithAttributes:@{NSFontAttributeName:b}].width;
    CHECK(fabs(wa-wb)>2,"same_text_different_font_changes_geometry");
    cjgui_internal_renderer_font_resource_stats(cold);
    BOOL reused=YES;for(int i=0;i<100;i++)reused &= CjguiComposableFontSnapshotForStyle(18,0,fixture)==b;
    CHECK(reused,"hot_immutable_snapshot_reused");
    cjgui_internal_renderer_font_resource_stats(hot);
    CHECK(cold[3]==hot[3],"hot_font_selection_does_not_resolve_again");
    CHECK(cjgui_internal_renderer_font_resource_register(2,"/no-such-cjgui-font.ttf",0,&missing)==2 && missing>fixture,"missing_resource_reports_explicit_fallback");
    NSFont *fallback=CjguiComposableFontSnapshotForStyle(18,0,missing);
    NSFont *system=CjguiComposableFontSnapshotForStyle(18,0,0);
    CHECK([fallback.fontName isEqualToString:system.fontName] &&
        [@"中文 é 👩🏽‍💻" sizeWithAttributes:@{NSFontAttributeName:fallback}].width==
        [@"中文 é 👩🏽‍💻" sizeWithAttributes:@{NSFontAttributeName:system}].width,"fallback_measurement_and_paint_share_actual_font");
    NSMutableDictionary *attributes=[@{NSFontAttributeName:b} mutableCopy];
    CjguiApplyComposableTypography(attributes,0.25,24);
    NSString *body=@"iiiiWWWW 中文 é 👩🏽‍💻\nsecond";
    uint64_t started=monotonicNs();
    CjguiComposableTextMetrics coldMeasure=CjguiMeasureComposableTypography(body,attributes,b,160,24);
    uint64_t coldNs=monotonicNs()-started;
    BOOL metricsStable=YES;started=monotonicNs();
    for(int i=0;i<200;i++){@autoreleasepool{
        NSFont *same=CjguiComposableFontSnapshotForStyle(18,0,fixture);
        CjguiComposableTextMetrics measured=CjguiMeasureComposableTypography(body,attributes,same,160,24);
        metricsStable &= measured.width==coldMeasure.width && measured.height==coldMeasure.height;
    }}
    fprintf(stderr,"font_workload bytes=%lu width=160 points=18 queries=200 cold_measure_ns=%llu hot_total_ns=%llu\n",
        (unsigned long)[body lengthOfBytesUsingEncoding:NSUTF8StringEncoding],(unsigned long long)coldNs,(unsigned long long)(monotonicNs()-started));
    CHECK(metricsStable,"fixed_hot_measurements_keep_font_geometry");
    for(NSNumber *kind in @[@(CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT),@(CJGUI_INTERNAL_RENDERER_COMPOSABLE_BUTTON),
        @(CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT_INPUT),@(CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT)]){
        CJGuiInternalComposableSceneNode *surface=[CJGuiInternalComposableSceneNode new];
        surface.node=(CjguiInternalRendererComposableNode){.nodeKind=kind.unsignedIntValue,.width=200,.height=80,
            .fontSize=18,.fontFamily=fixture,.textAlpha=1};
        CjguiPreparedTextNodeLayout *prepared=CjguiPrepareTextNodeLayout(surface,@"iiiiWWWW",1,nil,nil);
        NSFont *actual=[prepared.storage attribute:NSFontAttributeName atIndex:0 effectiveRange:NULL];
        CHECK(prepared && [actual.familyName containsString:@"Lilex"],"label_button_single_multiline_share_resolved_font");
        if(kind.unsignedIntValue==CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT){
            [prepared.layoutManager ensureLayoutForTextContainer:prepared.container];
            CGFloat fraction=0;
            NSUInteger glyph=[prepared.layoutManager glyphIndexForPoint:NSMakePoint(wb/8*3.25,5)
                inTextContainer:prepared.container fractionOfDistanceThroughGlyph:&fraction];
            CHECK([prepared.layoutManager characterIndexForGlyphAtIndex:glyph]==3,"textkit_hit_uses_registered_font_advance");
        }
    }
    @autoreleasepool {
        CJGuiInternalComposableSceneNode *node=[CJGuiInternalComposableSceneNode new];
        node.node=(CjguiInternalRendererComposableNode){.nodeKind=CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT,
            .width=160,.height=180,.fontSize=18,.fontFamily=fixture,.textAlpha=1,.textMaxLines=2,.textOverflow=1};
        node.styleRunsSignature=[NSString stringWithFormat:@"0:4:18:0:%u:0:0:0:1:0:0:0:0:0",serif];
        CHECK(cjgui_internal_renderer_font_resource_release(fixture)==0 && cjgui_internal_renderer_font_resource_release(serif)==0,"registry_withdraws_both_generations");
        CjguiInternalTextStyleRun run={.start=0,.end=4,.fontSize=18,.fontFamily=serif,.alpha=1};
        CjguiPreparedTextNodeLayout *p=CjguiPrepareTextNodeLayout(node,@"iiiiWWWW 中文 é 👩🏽‍💻\nnext",1,
            [NSData dataWithBytes:&run length:sizeof(run)],nil);
        NSFont *runFont=[p.storage attribute:NSFontAttributeName atIndex:0 effectiveRange:NULL];
        CHECK([runFont.familyName isEqualToString:@"Georgia"],"style_run_draws_its_registered_font");
        CHECK(p && [CjguiComposableFont(node).familyName containsString:@"Lilex"],"accepted_node_keeps_withdrawn_font_generation");
        CHECK(CjguiComposableFontSnapshotForStyle(18,0,serif)!=nil,"style_run_keeps_its_own_old_generation");
        CHECK([p.storage.string isEqualToString:@"iiiiWWWW 中文 é 👩🏽‍💻\nnext"],"font_selection_keeps_full_source");
    }
    CHECK(cjgui_internal_renderer_font_resource_release(missing)==0,"fallback_resource_released");
    } // Drain the actual owner-turn autorelease pool before testing retirement.
    CHECK(CjguiComposableFontSnapshotForStyle(18,0,fixture)==nil && CjguiComposableFontSnapshotForStyle(18,0,serif)==nil,
        "unleased_retired_generation_is_not_silently_rebound");
    uint64_t job=0;uint32_t preparing=0;
    CjguiAsyncMultilineMeasureTestCloseWorkerGate();
    @autoreleasepool {
        CHECK(cjgui_internal_renderer_font_resource_register(2,argv[1],0,&preparing)==0,"preparing_generation_registered");
        const char *body="iiiiWWWW\n中文 é 👩🏽‍💻";
        CHECK(cjgui_async_composable_multiline_typography_begin(body,strlen(body),18,0,preparing,160,0.25,24,&job)==CJGUI_ASYNC_MEASURE_STARTED,
            "real_async_bridge_accepts_registered_font");
        CHECK(CjguiAsyncMultilineMeasureTestWaitForWorkerGate(1000),"original_worker_paused_in_preparation");
        CHECK(cjgui_internal_renderer_font_resource_release(preparing)==0,"withdraw_while_worker_is_in_flight");
    }
    @autoreleasepool { CHECK(CjguiFontResourceLease(preparing)!=nil,"worker_retains_original_generation_after_owner_retires"); }
    CjguiAsyncMultilineMeasureTestOpenWorkerGate();
    uint32_t measuredHeight=0;CjguiAsyncMultilineMeasureFailure failure=0;
    CjguiAsyncMultilineMeasureStatus state=CJGUI_ASYNC_MEASURE_NOT_READY;
    @autoreleasepool {
        for(int i=0;i<2000;i++){
            state=CjguiAsyncMultilineMeasurePoll(job,&measuredHeight,&failure);
            if(state==CJGUI_ASYNC_MEASURE_READY || state==CJGUI_ASYNC_MEASURE_FAILED)break;
            usleep(1000);
        }
        CHECK(state==CJGUI_ASYNC_MEASURE_READY && failure==0 && measuredHeight>=48,"old_generation_finishes_with_original_metrics");
        CHECK(CjguiAsyncMultilineMeasureRelease(job,CJGUI_ASYNC_MEASURE_RELEASE_CONSUMED)==CJGUI_ASYNC_MEASURE_READY,
            "original_completion_releases_resource_lease");
        CHECK(CjguiFontResourceLease(preparing)==nil,"consumed_original_font_job_retires_before_caller_pool_drain");
    }
    pthread_t foreign;void *foreignResult=NULL;
    int threadStatus=pthread_create(&foreign,NULL,foreignThread,(void *)argv[1]);
    CHECK(threadStatus==0,"plain_foreign_thread_started");
    if(threadStatus==0)pthread_join(foreign,&foreignResult);else foreignResult=(void *)1;
    CHECK(foreignResult==NULL,"plain_foreign_thread_registration_and_retirement_complete");
    uint64_t end[5]={0};cjgui_internal_renderer_font_resource_stats(end);
    CHECK(end[0]==0 && end[1]==0 && end[2]==0,"resource_registry_converges");
    fprintf(stderr,"font_resource widths=%.3f,%.3f cold_builds=%llu hot_builds=%llu failures=%d\n",wa,wb,cold[3],hot[3],failures);
    return failures?1:0;
} }

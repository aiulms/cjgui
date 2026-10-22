// Reuse real sparse-run/COW setup, without rerunning the imported suites.
#define CJGUI_SPARSE_RUNS_NO_MAIN 1
#import "composable_sparse_text_runs_test.m"

static _Atomic(bool) runsDone;
static uint64_t runsSession, runsVersion;
static uint32_t runsCount;
static uint64_t runsIds[256];
static const char *runsValues[256];
static BOOL runsScalar;
static CjguiInternalRendererStatus runsStatus;

static void *runsWrite(void *unused) {
    (void)unused;
    @autoreleasepool {
        if (runsScalar) {
            runsStatus=cjgui_internal_renderer_set_composable_text_runs(runsSession,runsIds[0],runsValues[0]);
        }
#ifdef CJGUI_INTERNAL_TEXT_RUN_BATCH_TESTING
        else runsStatus=cjgui_internal_renderer_set_composable_text_runs_batch(runsSession,runsVersion,
            runsCount,runsIds,runsValues);
#endif
        atomic_store(&runsDone, true);
    }
    return NULL;
}

static BOOL runsWorker(void) {
    atomic_store(&runsDone, false);
    pthread_t thread;
    if (pthread_create(&thread, NULL, runsWrite, NULL)) return NO;
    uint64_t end = CjguiOwnerTraceNanoseconds() + UINT64_C(2000000000);
    while (!atomic_load(&runsDone) && CjguiOwnerTraceNanoseconds() < end)
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:.001]];
    if (!atomic_load(&runsDone)) return NO;
    pthread_join(thread, NULL);
    return YES;
}

int main(void) { @autoreleasepool {
    setenv("CJGUI_OWNER_PHASE_TRACE", "1", 1);
    setenv("CJGUI_OWNER_TRACE_LIGHT", "1", 1);
    [NSApplication sharedApplication];
    [NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];
    CJGuiInternalSession *ctx=nil,*peer=nil;uint64_t token=0,other=0;
    CHECK(makeSession(&ctx,&token) && sparseInitial(ctx,token) && makeSession(&peer,&other), "runs_batch_real_sessions");
    if (!ctx || !peer) return 2;
    NSArray<CJGuiInternalComposableSceneNode *> *accepted=[ctx.composableNodes copy];
    CHECK(CjguiConfigureComposableSceneOnMain(token,3,3)==0,"runs_batch_configure");
    runsSession=token;runsVersion=3;runsCount=1;runsIds[0]=100;runsValues[0]="";runsScalar=YES;
    gCjguiMainThreadDispatchEnabled=NO;
    CHECK(runsWorker() && runsStatus==CJGUI_INTERNAL_RENDERER_NOT_MAIN_THREAD,
          "runs_scalar_dispatch_disabled_refuses");
    gCjguiMainThreadDispatchEnabled=YES;
    uint64_t dispatchBefore=atomic_load(&gCjguiOwnerTraceDispatchSequence);
    CHECK(runsWorker() && runsStatus==0,"runs_scalar_owner_call");
    uint64_t scalarDispatches=atomic_load(&gCjguiOwnerTraceDispatchSequence)-dispatchBefore;
    CHECK(scalarDispatches==1,"runs_scalar_enters_main_instead_of_mutating_from_owner");
#ifndef CJGUI_INTERNAL_TEXT_RUN_BATCH_TESTING
    {
        CHECK(NO,"runs_batch_transport_available");
        fprintf(stdout,"runs_batch_red scalar_dispatches=%llu failures=%d\n",(unsigned long long)scalarDispatches,failures);
        CjguiReleaseSession(token);CjguiReleaseSession(other);return 1;
    }
#else
    runsScalar=NO;runsCount=3;
    for(uint32_t i=0;i<3;i++){runsIds[i]=100+i*100;runsValues[i]="";}
    runsValues[0]=sparseRuns;runsValues[2]="\xff";
    CHECK(cjgui_internal_renderer_set_composable_text_runs_batch(token,3,3,runsIds,runsValues)==CJGUI_INTERNAL_RENDERER_INVALID_UTF8 &&
          [ctx.composableTextStyleRunsRaw[@100] length]==0 && ctx.stagedComposableNodes[0]==accepted[0],
          "runs_batch_bad_tail_does_not_mutate_prefix");
    runsValues[0]="";runsValues[1]=sparseRuns;runsValues[2]="";
    uint64_t clones=ctx.composableSceneCloneCount;
    dispatchBefore=atomic_load(&gCjguiOwnerTraceDispatchSequence);
    CHECK(runsWorker() && runsStatus==0 && atomic_load(&gCjguiOwnerTraceDispatchSequence)-dispatchBefore==1,
          "runs_batch_owner_one_main_hop");
    CHECK(ctx.composableSceneCloneCount==clones+1 && ctx.stagedComposableNodes[0]==accepted[0] &&
          ctx.stagedComposableNodes[2]==accepted[2] && ctx.stagedComposableNodes[1]!=accepted[1] &&
          [accepted[1] styleRunsSignature].length==0 && peer.composableSceneVersion==1,
          "runs_batch_reuses_cow_and_keeps_accepted_peer");
    CHECK(cjgui_internal_renderer_discard_composable_scene_candidate(token)==0 && ctx.composableNodes[1]==accepted[1],
          "runs_batch_discard_keeps_accepted");
    CHECK(CjguiConfigureComposableSceneOnMain(token,3,256)==0,"runs_batch_large_configure");
    for(uint32_t i=0;i<256;i++){
        CjguiInternalRendererComposableNode raw=[accepted[0] node];raw.nodeId=1000+i;raw.resourceId=1000+i;raw.projectionVersion=3;
        CHECK(CjguiSetComposableSceneNodeOnMain(token,i,&raw,"","",NULL,NULL,0,nil)==0,"runs_batch_large_nodes");
        runsIds[i]=1000+i;runsValues[i]=NULL;
    }
    runsCount=256;
    gCjguiMainThreadDispatchEnabled=NO;
    CHECK(runsWorker() && runsStatus==CJGUI_INTERNAL_RENDERER_NOT_MAIN_THREAD,"runs_batch_dispatch_disabled_refuses");
    gCjguiMainThreadDispatchEnabled=YES;
    dispatchBefore=atomic_load(&gCjguiOwnerTraceDispatchSequence);
    CHECK(runsWorker() && runsStatus==0 && atomic_load(&gCjguiOwnerTraceDispatchSequence)-dispatchBefore==1,
          "runs_batch_256_one_main_hop");
#ifdef CJGUI_INTERNAL_TEXT_RUN_BATCH_TESTING
    CHECK(gCjguiTextRunBatchNodeVisits==512,"runs_batch_linear_scan_and_matching_slots");
#endif
    CHECK(cjgui_internal_renderer_set_composable_text_runs_batch(token,4,256,runsIds,runsValues)==CJGUI_INTERNAL_RENDERER_SCENE_STALE,
          "runs_batch_scene_version_qualified");
    CHECK(cjgui_internal_renderer_set_composable_text_runs_batch(token,3,0,runsIds,runsValues)!=0 &&
          cjgui_internal_renderer_set_composable_text_runs_batch(token,3,1025,runsIds,runsValues)!=0,
          "runs_batch_shape_bounded");
    CjguiReleaseSession(token);CjguiReleaseSession(other);
    CHECK(cjgui_internal_renderer_set_composable_text_runs_batch(token,3,256,runsIds,runsValues)==CJGUI_INTERNAL_RENDERER_INVALID_SESSION,
          "runs_batch_closed_identity_refused");
    fprintf(stdout,"runs_batch nodes=256 scalar_dispatches=%llu failures=%d\n",(unsigned long long)scalarDispatches,failures);
    return failures?1:0;
#endif
} }

#define CJGUI_INTERNAL_TESTING 1
#import "../cjgui_internal_renderer.m"

#include <stdio.h>

static int failures;
static uint64_t nextRequest=77;
#define CHECK(condition,label) do { \
    BOOL passed=(condition); \
    fprintf(stderr,"source_proxy_worker case=%s result=%s\n",label,passed?"PASS":"FAIL"); \
    if(!passed) failures++; \
} while(0)

static CjguiSourceProxyPreparation *makePreparation(CJGuiInternalSession *ctx, NSString *body) {
    CjguiSourceProxyPreparation *p=[CjguiSourceProxyPreparation new];
    CJGuiInternalComposableSceneNode *node=[CJGuiInternalComposableSceneNode new];
    CjguiInternalRendererComposableNode raw={0};
    raw.nodeId=701;raw.resourceId=3;raw.projectionVersion=9;
    raw.nodeKind=CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT;
    raw.isInteractive=1;raw.width=680;raw.height=915;raw.clipWidth=680;raw.clipHeight=689;
    raw.fontSize=18;raw.fontWeight=400;raw.textAlpha=1;
    CjguiInternalRendererComposableGeometry geometry={0};geometry.nodeId=701;
    node.node=raw;node.geometry=geometry;node.value=body;
    p.target=node;p.runs=@"";p.scale=1;p.wanted=NSMakeRange(17,0);
    p.sessionGeneration=ctx.sessionGeneration;p.bindingEpoch=4;p.requestId=nextRequest++;p.sceneVersion=2;
    p.workerAdmission=[CjguiComposablePreparation new];
    p.workerAdmission.sessionToken=ctx.rendererSessionToken;
    p.workerAdmission.sessionGeneration=ctx.sessionGeneration;
    p.workerAdmission.preparationId=p.requestId;
    p.workerAdmission.baseSceneVersion=p.sceneVersion;
    p.workerAdmission.bindingEpoch=p.bindingEpoch;
    p.workerAdmission.scale=p.scale;
    (void)ctx;return p;
}

static BOOL prepareThroughPhase4(CJGuiInternalSession *ctx,CjguiSourceProxyPreparation *p) {
    while(p.phase<4) {
        CjguiInternalRendererStatus status=CjguiAdvanceSourceProxyPreparationUnit(ctx,p);
        if(status!=CJGUI_INTERNAL_RENDERER_OK)return NO;
    }
    return YES;
}

static BOOL sourceWorkerReady(CJGuiInternalSession *ctx,CjguiSourceProxyPreparation *p) {
    for(NSUInteger attempt=0;attempt<500 && p.phase==4;attempt++) {
        usleep(1000);
        if(CjguiAdvanceSourceProxyPreparationUnit(ctx,p)!=CJGUI_INTERNAL_RENDERER_OK)return NO;
    }
    return p.phase==5;
}

static BOOL makeSession(CJGuiInternalSession **out) {
    id<MTLDevice> device=MTLCreateSystemDefaultDevice();if(!device)return NO;
    CJGuiInternalSession *ctx=[CJGuiInternalSession new];if(!ctx)return NO;
    ctx.view=[[CJGuiInternalMetalView alloc] initWithFrame:NSMakeRect(0,0,680,689)
        device:device commandQueue:[device newCommandQueue]];
    ctx.composableNodes=[NSMutableArray array];
    ctx.composableTextStyleRunsRaw=[NSMutableDictionary dictionary];
    ctx.composableSceneOverlay=[[CJGuiInternalComposableSceneOverlay alloc]
        initWithFrame:ctx.view.bounds session:ctx];
    ctx.composableSceneOverlay.session=ctx;
    ctx.view.sessionToken=CjguiAllocateSession(ctx);
    if(!ctx.view.sessionToken)return NO;
    *out=ctx;return YES;
}

int main(void) {@autoreleasepool {
    [NSApplication sharedApplication];
    [NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];
    CJGuiInternalSession *ctx=nil;if(!makeSession(&ctx))return 2;
    NSMutableString *body=[NSMutableString stringWithCapacity:16384];
    for(NSUInteger i=0;i<16384;i++)[body appendString:@"a"];
    CjguiSourceProxyPreparation *p=makePreparation(ctx,body);
    if(!prepareThroughPhase4(ctx,p))return 3;
    [p.overlay.inputProxy.textStorage addAttribute:NSFontAttributeName
        value:[NSFont boldSystemFontOfSize:18.0] range:NSMakeRange(320,5)];
    [p.overlay.inputProxy.textStorage addAttribute:NSForegroundColorAttributeName
        value:NSColor.systemRedColor range:NSMakeRange(320,5)];
    NSDictionary *fallback=@{NSUnderlineStyleAttributeName:@(NSUnderlineStyleSingle)};
    [p.overlay.inputProxy.layoutManager addTemporaryAttributes:fallback
        forCharacterRange:NSMakeRange(40,1)];
    NSUInteger before=p.overlay.inputProxy.layoutManager.firstUnlaidCharacterIndex;
    uint64_t started=CjguiMonotonicMicros();
    CjguiInternalRendererStatus status=CjguiAdvanceSourceProxyPreparationUnit(ctx,p);
    uint64_t elapsed=CjguiMonotonicMicros()-started;
    NSUInteger after=p.overlay.inputProxy.layoutManager.firstUnlaidCharacterIndex;
    CjguiTextPreparationWorkerJob *firstJob=p.workerAdmission.textLayoutJob;
    fprintf(stderr,"SOURCE_PROXY_PHASE4_GREEN main_thread=%d status=%d request_chars=1024 before=%lu after=%lu body=%lu elapsed_us=%llu\n",
        pthread_main_np()!=0,status,(unsigned long)before,(unsigned long)after,(unsigned long)body.length,
        (unsigned long long)elapsed);
    // The preserved RED log records that the old first 1024-range request
    // synchronously completed this exact paragraph on the owner.
    BOOL ownerTurnBounded=status==CJGUI_INTERNAL_RENDERER_OK && pthread_main_np()!=0 && after<body.length &&
        p.workerAdmission.textLayoutJob!=nil;
    CHECK(ownerTurnBounded,"phase4_admits_worker_without_owner_full_layout");
    (void)sourceWorkerReady(ctx,p);
    if(firstJob) fprintf(stderr,"SOURCE_PROXY_WORKER_TIMING body=%lu worker_us=%llu full_source=%lu full_painter=%lu\n",
        (unsigned long)body.length,
        (unsigned long long)(firstJob.workerCompletedMicros-firstJob.workerStartedMicros),
        (unsigned long)(p.sourceLayout.layoutManager.firstUnlaidCharacterIndex),
        (unsigned long)(p.painter.layoutManager.firstUnlaidCharacterIndex));
    BOOL handedOff=p.phase==5 && p.sourceLayout && p.painter &&
        p.overlay.inputProxy.textStorage==p.sourceLayout.storage &&
        p.overlay.inputProxy.layoutManager==p.sourceLayout.layoutManager &&
        p.overlay.inputProxy.textContainer==p.sourceLayout.container &&
        p.sourceLayout.storage!=p.painter.storage &&
        p.sourceLayout.layoutManager!=p.painter.layoutManager &&
        p.sourceLayout.container!=p.painter.container &&
        p.sourceLayout.layoutManager.firstUnlaidCharacterIndex>=body.length &&
        p.painter.layoutManager.firstUnlaidCharacterIndex>=body.length &&
        p.sourceLayout.layoutManager.numberOfGlyphs==p.painter.layoutManager.numberOfGlyphs &&
        fabs(NSHeight([p.sourceLayout.layoutManager usedRectForTextContainer:p.sourceLayout.container])-
             NSHeight([p.painter.layoutManager usedRectForTextContainer:p.painter.container]))<0.5 &&
        [p.sourceLayout.layoutManager temporaryAttributesAtCharacterIndex:40 effectiveRange:NULL][NSUnderlineStyleAttributeName] != nil &&
        [p.painter.layoutManager temporaryAttributesAtCharacterIndex:40 effectiveRange:NULL][NSUnderlineStyleAttributeName] != nil;
    CHECK(handedOff,"worker_source_graph_handoff_keeps_full_layout_geometry_fallbacks_and_separate_painter");
    // A long multi-paragraph body must reach the same complete source/painter
    // geometry without making the owner perform its layout.
    NSMutableString *multiline=[NSMutableString stringWithCapacity:16384];
    for(NSUInteger i=0;i<2048;i++)[multiline appendFormat:@"行🧪%04lu\n",(unsigned long)i];
    CjguiSourceProxyPreparation *m=makePreparation(ctx,multiline);
    BOOL multiPrepared=prepareThroughPhase4(ctx,m);
    NSAttributedString *multiFrozen=nil;
    NSArray *multiRuns=CjguiFreezeRasterAttributeRuns(m.overlay.inputProxy.textStorage,&multiFrozen);
    NSArray *multiTemporary=CjguiFreezeTemporaryAttributeRuns(m.overlay.inputProxy.layoutManager,m.overlay.inputProxy.textStorage.length);
    NSError *archiveError=nil;
    NSData *frozenArchive=[NSKeyedArchiver archivedDataWithRootObject:@{ @"body":m.target.value,
        @"attributed":multiFrozen ?: (id)NSNull.null, @"attributes":multiRuns ?: @[],
        @"temporary":multiTemporary ?: @[] }
        requiringSecureCoding:NO error:&archiveError];
    uint64_t debugAttrBytes=0,debugTempBytes=0,debugExtentBytes=0;
    uint64_t debugAttrContainers=0,debugTempContainers=0,debugExtentContainers=0;
    NSHashTable *debugSharedValues=[NSHashTable hashTableWithOptions:
        NSPointerFunctionsObjectPointerPersonality | NSPointerFunctionsStrongMemory];
    CjguiFrozenRasterValueBytes(multiRuns,0,debugSharedValues,&debugAttrBytes,&debugAttrContainers);
    CjguiFrozenRasterValueBytes(multiTemporary,0,debugSharedValues,&debugTempBytes,&debugTempContainers);
    CjguiFrozenRasterValueBytes([multiFrozen attributesAtIndex:0 effectiveRange:NULL],0,debugSharedValues,&debugExtentBytes,&debugExtentContainers);
    uint64_t multiStart=CjguiMonotonicMicros();
    CjguiInternalRendererStatus multiAdmission=multiPrepared
        ? CjguiAdvanceSourceProxyPreparationUnit(ctx,m):CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    uint64_t multiAdmissionMicros=CjguiMonotonicMicros()-multiStart;
    uint64_t multiCharge=m.workerAdmission.textLayoutJob.reservedBytes;
    BOOL multiReady=multiPrepared && multiAdmission==CJGUI_INTERNAL_RENDERER_OK && sourceWorkerReady(ctx,m);
    NSRect sourceUsed=multiReady?[m.sourceLayout.layoutManager usedRectForTextContainer:m.sourceLayout.container]:NSZeroRect;
    NSRect painterUsed=multiReady?[m.painter.layoutManager usedRectForTextContainer:m.painter.container]:NSZeroRect;
    fprintf(stderr,"SOURCE_PROXY_MULTILINE body=%lu ready=%d source_len=%lu painter_len=%lu source_unlaid=%lu painter_unlaid=%lu source_glyphs=%lu painter_glyphs=%lu source_rect=(%.2f,%.2f) painter_rect=(%.2f,%.2f) phase=%lu\n",
        (unsigned long)multiline.length,multiReady,(unsigned long)m.sourceLayout.storage.length,
        (unsigned long)m.painter.storage.length,(unsigned long)m.sourceLayout.layoutManager.firstUnlaidCharacterIndex,
        (unsigned long)m.painter.layoutManager.firstUnlaidCharacterIndex,(unsigned long)m.sourceLayout.layoutManager.numberOfGlyphs,
        (unsigned long)m.painter.layoutManager.numberOfGlyphs,NSWidth(sourceUsed),NSHeight(sourceUsed),
        NSWidth(painterUsed),NSHeight(painterUsed),(unsigned long)m.phase);
    fprintf(stderr,"SOURCE_PROXY_MULTILINE_ADMISSION prepared=%d status=%d chars=%lu utf8=%lu container=(%.1f,%.1f) textview=%lu\n",
        multiPrepared,multiAdmission,(unsigned long)m.overlay.inputProxy.textStorage.length,
        (unsigned long)strlen(m.target.value.UTF8String),m.overlay.inputProxy.textContainer.containerSize.width,
        m.overlay.inputProxy.textContainer.containerSize.height,(unsigned long)m.overlay.inputProxy.string.length);
    fprintf(stderr,"SOURCE_PROXY_MULTILINE_RUNS attrs=%lu temporary=%lu frozen=%d archive=%lu logical_attr=%llu/%llu logical_temp=%llu/%llu logical_extent=%llu/%llu charged=%llu admission_us=%llu archive_error=%s\n",
        (unsigned long)multiRuns.count,(unsigned long)multiTemporary.count,multiFrozen!=nil,
        (unsigned long)frozenArchive.length,(unsigned long long)debugAttrBytes,(unsigned long long)debugAttrContainers,
        (unsigned long long)debugTempBytes,(unsigned long long)debugTempContainers,
        (unsigned long long)debugExtentBytes,(unsigned long long)debugExtentContainers,(unsigned long long)multiCharge,
        (unsigned long long)multiAdmissionMicros,archiveError.localizedDescription.UTF8String ?: "none");
    BOOL sameGeometry=multiReady && m.sourceLayout.storage.length==multiline.length &&
        m.sourceLayout.layoutManager.firstUnlaidCharacterIndex>=multiline.length &&
        m.painter.layoutManager.firstUnlaidCharacterIndex>=multiline.length &&
        m.sourceLayout.layoutManager.numberOfGlyphs==m.painter.layoutManager.numberOfGlyphs &&
        fabs(NSWidth(sourceUsed)-NSWidth(painterUsed))<0.5 &&
        fabs(NSHeight(sourceUsed)-NSHeight(painterUsed))<0.5;
    CHECK(sameGeometry && multiCharge>frozenArchive.length &&
        multiCharge<=CjguiTextPreparationWorkerMaxBytesPerJob && multiAdmissionMicros<16000,
        "multiline_frozen_snapshot_and_two_graph_charge_within_job_cap_and_owner_turn");

    // Block both pool slots, fill the four FIFO waiters, then prove a fifth
    // request is refused and cancellation returns its byte reservation.
    CjguiTextPreparationTestCloseWorkerGate();
    NSMutableString *shortBody=[NSMutableString stringWithCapacity:1024];
    for(NSUInteger i=0;i<1024;i++)[shortBody appendString:@"b"];
    CjguiSourceProxyPreparation *slots[2];
    for(NSUInteger i=0;i<2;i++) {
        slots[i]=makePreparation(ctx,shortBody);
        if(!prepareThroughPhase4(ctx,slots[i]) ||
            CjguiAdvanceSourceProxyPreparationUnit(ctx,slots[i])!=CJGUI_INTERNAL_RENDERER_OK)return 4;
    }
    BOOL workersAtGate=CjguiTextPreparationTestWaitForWorkerGate(2000);
    usleep(20000);
    CjguiSourceProxyPreparation *waiters[5];
    for(NSUInteger i=0;i<5;i++) {
        waiters[i]=makePreparation(ctx,shortBody);
        if(!prepareThroughPhase4(ctx,waiters[i]))return 5;
    }
    for(NSUInteger i=0;i<4;i++)
        if(CjguiAdvanceSourceProxyPreparationUnit(ctx,waiters[i])!=CJGUI_INTERNAL_RENDERER_OK)return 6;
    uint64_t reservedWithFour=gCjguiTextPreparationReservedBytes;
    NSUInteger waiterCountWithFour=gCjguiTextPreparationWaiterCount;
    CjguiInternalRendererStatus fifth=CjguiAdvanceSourceProxyPreparationUnit(ctx,waiters[4]);
    CHECK(workersAtGate && waiterCountWithFour==4 &&
        fifth==CJGUI_INTERNAL_RENDERER_TEXT_RESOURCE_BUDGET_EXCEEDED &&
        gCjguiTextPreparationWaiterCount==4,"pool_slots_and_four_waiter_limit_are_explicit");
    for(NSUInteger i=0;i<4;i++)CjguiCancelTextPreparationWorker(waiters[i].workerAdmission);
    CHECK(gCjguiTextPreparationWaiterCount==0 &&
        gCjguiTextPreparationReservedBytes<reservedWithFour,"cancelled_waiters_release_reserved_capacity");
    uint64_t withWorkers=gCjguiTextPreparationReservedBytes;
    for(NSUInteger i=0;i<2;i++)CjguiCancelTextPreparationWorker(slots[i].workerAdmission);
    CHECK(gCjguiTextPreparationReservedBytes==withWorkers,"running_cancel_keeps_slot_charge_until_worker_exit");
    CjguiTextPreparationTestOpenWorkerGate();
    CHECK(CjguiTextPreparationTestWaitForFinished(3000) &&
        gCjguiTextPreparationReservedBytes==0,"cancelled_worker_exit_releases_slots_and_pool_bytes");

    // Individual 16 KiB CJK/emoji jobs fit below 16 MiB, but the same third
    // reservation must fail when two workers already charge more than 32 MiB.
    CjguiTextPreparationTestCloseWorkerGate();
    CjguiSourceProxyPreparation *heavySlots[2];
    for(NSUInteger i=0;i<2;i++) {
        heavySlots[i]=makePreparation(ctx,multiline);
        if(!prepareThroughPhase4(ctx,heavySlots[i]) ||
            CjguiAdvanceSourceProxyPreparationUnit(ctx,heavySlots[i])!=CJGUI_INTERNAL_RENDERER_OK)return 9;
    }
    BOOL heavyWorkersWaiting=CjguiTextPreparationTestWaitForWorkerGate(3000);
    usleep(20000);
    uint64_t heavyEach=heavySlots[0].workerAdmission.textLayoutJob.reservedBytes;
    uint64_t heavyReserved=gCjguiTextPreparationReservedBytes;
    CjguiSourceProxyPreparation *overPool=makePreparation(ctx,multiline);
    BOOL overPrepared=prepareThroughPhase4(ctx,overPool);
    CjguiInternalRendererStatus overStatus=overPrepared
        ? CjguiAdvanceSourceProxyPreparationUnit(ctx,overPool):CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    CHECK(heavyWorkersWaiting && heavyEach<=CjguiTextPreparationWorkerMaxBytesPerJob &&
        heavyReserved==heavyEach*2 && heavyReserved+heavyEach>CjguiTextPreparationWorkerMaxReservedBytes &&
        overStatus==CJGUI_INTERNAL_RENDERER_TEXT_RESOURCE_BUDGET_EXCEEDED &&
        gCjguiTextPreparationWaiterCount==0 && gCjguiTextPreparationReservedBytes==heavyReserved,
        "third_multiline_job_rejected_by_32mib_pool_not_per_job_cap");
    for(NSUInteger i=0;i<2;i++)CjguiCancelTextPreparationWorker(heavySlots[i].workerAdmission);
    CjguiTextPreparationTestOpenWorkerGate();
    CHECK(CjguiTextPreparationTestWaitForFinished(3000) &&
        gCjguiTextPreparationReservedBytes==0,"over_pool_negative_control_releases_all_slots");

    // A fully constructed but not yet published worker result is still
    // private: cancellation at the publication fence cannot attach its graph.
    CjguiSourceProxyPreparation *late=makePreparation(ctx,shortBody);
    if(!prepareThroughPhase4(ctx,late))return 7;
    CjguiTextPreparationTestClosePublicationGate();
    if(CjguiAdvanceSourceProxyPreparationUnit(ctx,late)!=CJGUI_INTERNAL_RENDERER_OK ||
        !CjguiTextPreparationTestWaitForPublicationGate(3000))return 8;
    uint64_t chargedAtPublication=gCjguiTextPreparationReservedBytes;
    CjguiCancelTextPreparationWorker(late.workerAdmission);
    BOOL publicationStillCharged=gCjguiTextPreparationReservedBytes==chargedAtPublication;
    CjguiTextPreparationTestOpenPublicationGate();
    BOOL workerExited=CjguiTextPreparationTestWaitForFinished(3000);
    CjguiInternalRendererStatus lateAdoption=CjguiAdvanceSourceProxyPreparationUnit(ctx,late);
    CHECK(publicationStillCharged && workerExited &&
        lateAdoption==CJGUI_INTERNAL_RENDERER_SCENE_STALE && late.phase==4 &&
        late.sourceLayout==nil && late.painter==nil &&
        gCjguiTextPreparationTestDiscardedGraphsReleased &&
        gCjguiTextPreparationReservedBytes==0,
        "cancelled_ready_graph_is_discarded_without_late_proxy_publication");
    return failures?1:0;
}}

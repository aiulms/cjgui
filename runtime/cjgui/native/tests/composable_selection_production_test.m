// No CJGUI_INTERNAL_TESTING: exercise the same selection ABI as the shipped app.
#import "../cjgui_internal_renderer.m"
#import <objc/runtime.h>

static int failures;
static NSString *gSelectionProductionTargetBody;
static uint32_t gSelectionProductionTargetKind=CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT;
static CGFloat gSelectionProductionTargetHeight=120.0;
static CGFloat gSelectionProductionTargetClipHeight=500.0;
static CGFloat gSelectionProductionTargetY=130.0;
static IMP gOriginalEnsureLayoutForContainer;
static pthread_mutex_t gSelectionLayoutCounterLock=PTHREAD_MUTEX_INITIALIZER;
static uint64_t gSelectionLongMainEnsureCount;
static uint64_t gSelectionLongWorkerEnsureCount;
static void SelectionCountedEnsureLayoutForContainer(id self, SEL selector, NSTextContainer *container) {
    NSLayoutManager *layout=(id)self;
    if (layout.textStorage.length>=1024) {
        pthread_mutex_lock(&gSelectionLayoutCounterLock);
        if ([NSThread isMainThread]) gSelectionLongMainEnsureCount++;
        else gSelectionLongWorkerEnsureCount++;
        pthread_mutex_unlock(&gSelectionLayoutCounterLock);
    }
    ((void(*)(id,SEL,NSTextContainer *))gOriginalEnsureLayoutForContainer)(self,selector,container);
}
static void InstallSelectionLayoutCounter(void) {
    Method method=class_getInstanceMethod(NSLayoutManager.class,@selector(ensureLayoutForTextContainer:));
    gOriginalEnsureLayoutForContainer=method_getImplementation(method);
    method_setImplementation(method,(IMP)SelectionCountedEnsureLayoutForContainer);
}
#define CHECK(c, label) do { BOOL ok=(c); fprintf(stderr,"selection_production %s %s\n",label,ok?"PASS":"FAIL"); if(!ok)failures++; } while(0)

@interface SelectionProductionWindow : NSWindow
@property BOOL refuseInputHost;
@end
@implementation SelectionProductionWindow
- (BOOL)makeFirstResponder:(NSResponder *)responder {
    if (self.refuseInputHost && [responder isKindOfClass:[CJGuiInternalComposableInputHost class]]) return NO;
    return [super makeFirstResponder:responder];
}
@end
@interface SelectionProductionOverlay : CJGuiInternalComposableSceneOverlay
@property BOOL inputDuringAttachment;
@property BOOL cancelDuringPublication;
@end
@implementation SelectionProductionOverlay
- (void)swapPrivateInputGraphWith:(CJGuiInternalComposableSceneOverlay *)other {
    [super swapPrivateInputGraphWith:other];
    if (self.cancelDuringPublication) {
        self.cancelDuringPublication=NO;
        cjgui_internal_renderer_selection_transfer_request_cancel(self.session.rendererSessionToken,self.session.selectionTransferId);
    }
}
- (void)addSubview:(NSView *)view {
    [super addSubview:view];
    if (self.inputDuringAttachment && [view isKindOfClass:[NSScrollView class]]) {
        self.inputDuringAttachment=NO;
        [(id<NSTextInputClient>)self.window.firstResponder insertText:@"X" replacementRange:NSMakeRange(NSNotFound,0)];
    }
}
@end

static CJGuiInternalSession *Fixture(id<MTLDevice> device, BOOL initiallyFocused) {
    CJGuiInternalSession *ctx=[CJGuiInternalSession new];
    ctx.app=[NSApplication sharedApplication];
    ctx.view=[[CJGuiInternalMetalView alloc] initWithFrame:NSMakeRect(0,0,680,500)
        device:device commandQueue:[device newCommandQueue]];
    ctx.window=[[SelectionProductionWindow alloc] initWithContentRect:NSMakeRect(0,0,680,500)
        styleMask:NSWindowStyleMaskBorderless backing:NSBackingStoreBuffered defer:YES];
    ctx.window.releasedWhenClosed=NO;
    ctx.composableNodes=[NSMutableArray array]; ctx.stagedComposableNodes=[NSMutableArray array];
    ctx.composableTextStyleRunsRaw=[NSMutableDictionary dictionary];
    CJGuiInternalComposableSceneOverlay *o=[[SelectionProductionOverlay alloc]
        initWithFrame:NSMakeRect(0,0,680,500) session:ctx];
    ctx.composableSceneOverlay=o; ctx.window.contentView=o;
    for (NSUInteger i=0;i<2;i++) {
        CJGuiInternalComposableSceneNode *n=[CJGuiInternalComposableSceneNode new];
        CjguiInternalRendererComposableNode raw={0};
        raw.nodeId=401+i; raw.resourceId=1; raw.projectionVersion=1;
        raw.nodeKind=i?gSelectionProductionTargetKind:CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT;
        raw.x=0;raw.y=i?gSelectionProductionTargetY:(gSelectionProductionTargetY==0.0?130.0:0.0);
        raw.width=680;raw.height=i?gSelectionProductionTargetHeight:120.0;
        raw.clipWidth=680;raw.clipHeight=i?gSelectionProductionTargetClipHeight:500.0;raw.fontSize=13;raw.textAlpha=1;raw.isInteractive=1;
        n.node=raw;n.index=i;n.value=i?(gSelectionProductionTargetBody ?: @"FGHIJ"): @"abcde";
        n.styleRunsSignature=@"";n.textTextureCacheKey=@"";
        [ctx.stagedComposableNodes addObject:n];
    }
    ctx.stagedComposableSceneVersion=1;ctx.stagedComposableDataTransferItems=[NSMutableArray array];
    ctx.stagedComposableDataTransferVersion=1;
    uint64_t token=CjguiAllocateSession(ctx);
    CHECK(CjguiCommitComposableSceneOnMain(token)==0,"accepted_two_plain_text_nodes");
    [o setNodesFromProjection:ctx.view.composableNodes];
    ctx.ownedTextSessionEnabled=YES;ctx.ownedTextSessionNodeId=401;
    ctx.ownedTextSessionResourceId=1;ctx.ownedTextSessionNodeKind=CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT;
    ctx.ownedTextSessionBindingEpoch=81;ctx.rangeTextEditDeltaDeliveryEnabled=YES;
    if(initiallyFocused) [o focusCommittedNodeId:401];
    else [ctx.window makeFirstResponder:o];
    [ctx.pendingInteractions removeAllObjects];
    return ctx;
}

static uint64_t Prepare(CJGuiInternalSession *ctx, uint32_t anchor, uint32_t focus) {
    uint64_t id=0,token=ctx.rendererSessionToken;
    CjguiInternalRendererStatus status=cjgui_internal_renderer_selection_transfer_create(token,&id);
    CHECK(status==0 && id!=0,"normal_build_admits_valid_selection");
    if(status || !id)return 0;
    NSString *targetBody=ctx.composableSceneOverlay.nodes[1].value;
    NSData *b=[targetBody dataUsingEncoding:NSUTF8StringEncoding];
    CjguiInternalSelectionTransferCandidate c={0};
    c.transferId=id;c.sourceWindowInstanceToken=9101;c.sourceOwnerVersion=10;
    c.sourceContextEpoch=4;c.sourceMirrorRevision=2;
    CJGuiInternalComposableSceneNode *target=ctx.composableSceneOverlay.nodes[1];
    c.targetNodeId=target.node.nodeId;c.targetProjectionVersion=target.node.projectionVersion;
    c.targetResourceId=target.node.resourceId;
    c.targetNodeKind=gSelectionProductionTargetKind;c.targetSceneVersion=ctx.composableSceneVersion;
    c.targetAnchor16=anchor;c.targetFocus16=focus;c.targetBodyUtf8=b.bytes;c.targetBodyUtf8Length=(uint32_t)b.length;
    uint8_t actual[65536]={0};
    CHECK(cjgui_internal_renderer_selection_transfer_capture_current(token,&c,actual,sizeof(actual))==0,
        "capture_actual_A_without_changing_it");
    CHECK(cjgui_internal_renderer_selection_transfer_publish_pending(token,id)==0,"publish_pending");
    return id;
}
static void Retire(CJGuiInternalSession *ctx,uint64_t transfer,BOOL committed);

// Recommit the same logical document at a new scene/projection version. A
// variant of zero changes only the target's coordinates; variants 1/2/3 alter
// body/font/width respectively for spare-invalidation negative controls.
static BOOL CommitSelectionTestSceneVariant(CJGuiInternalSession *ctx, uint64_t version, uint32_t variant) {
    NSMutableArray<CJGuiInternalComposableSceneNode *> *nodes=[NSMutableArray array];
    for (NSUInteger i=0;i<ctx.composableNodes.count;i++) {
        CJGuiInternalComposableSceneNode *copy=CjguiCloneComposableSceneNode(ctx,ctx.composableNodes[i],
            (uint32_t)i,version);
        if (!copy) return NO;
        if (i==1) {
            CjguiInternalRendererComposableNode raw=copy.node;
            if (variant==0) raw.x+=8.0;
            else if (variant==1) copy.value=[copy.value stringByAppendingString:@"z"];
            else if (variant==2) raw.fontSize+=1.0;
            else if (variant==3) raw.width+=20.0;
            else return NO;
            copy.node=raw;
        }
        [nodes addObject:copy];
    }
    ctx.stagedComposableNodes=nodes;
    ctx.stagedComposableSceneVersion=version;
    ctx.stagedComposableDataTransferItems=[NSMutableArray array];
    ctx.stagedComposableDataTransferVersion=version;
    CjguiInternalRendererStatus status=CjguiCommitComposableSceneOnMain(ctx.rendererSessionToken);
    if (status!=CJGUI_INTERNAL_RENDERER_OK) return NO;
    [ctx.composableSceneOverlay setNodesFromProjection:ctx.view.composableNodes];
    return YES;
}

static void PreserveActiveLocalTextRefreshKeepsSelectionGeometry(id<MTLDevice> device,
    uint32_t anchor, uint32_t focus, BOOL expectCaret, const char *label) {
    gSelectionProductionTargetKind=CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT;
    gSelectionProductionTargetBody=@"alpha\nbeta\ngamma";
    gSelectionProductionTargetHeight=240.0;
    gSelectionProductionTargetClipHeight=240.0;
    gSelectionProductionTargetY=0.0;
    CJGuiInternalSession *ctx=Fixture(device,YES);
    uint64_t token=ctx.rendererSessionToken;
    SelectionProductionOverlay *o=(id)ctx.composableSceneOverlay;
    uint64_t transfer=Prepare(ctx,anchor,focus);
    CjguiInternalSelectionTransferReceipt receipt={0};
    BOOL installed=transfer && cjgui_internal_renderer_selection_transfer_install_b(token,transfer,&receipt)==
        CJGUI_INTERNAL_RENDERER_OK;
    CHECK(installed,label);
    if (!installed) {
        if (transfer) Retire(ctx,transfer,NO);
        cjgui_internal_renderer_destroy(token);
        gSelectionProductionTargetBody=nil;
        gSelectionProductionTargetKind=CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT;
        gSelectionProductionTargetHeight=120.0;
        gSelectionProductionTargetClipHeight=500.0;
        gSelectionProductionTargetY=130.0;
        return;
    }
    Retire(ctx,transfer,YES);
    CjguiInstalledRangeState *basis=ctx.installedRangeBasis;
    NSString *source=[[NSString alloc] initWithData:basis.sourceUtf8 encoding:NSUTF8StringEncoding];
    NSRange selected=o.inputProxy.selectedRange;
    BOOL preRefreshReadback=basis && basis.active && basis.hasReceipt && source &&
        [o.inputProxy.string isEqualToString:source] && NSEqualRanges(selected,
            NSMakeRange(basis.actualSelectionStart16,basis.actualSelectionEnd16-basis.actualSelectionStart16)) &&
        CjguiInstalledRangeBasisMatchesActual(ctx,o);
    CHECK(preRefreshReadback,"preserve_refresh_proxy_body_selection_and_ack_are_current");

    uint64_t nextVersion=ctx.composableSceneVersion+1;
    NSMutableArray<CJGuiInternalComposableSceneNode *> *next=[NSMutableArray array];
    for (NSUInteger i=0;i<ctx.composableNodes.count;i++) {
        CJGuiInternalComposableSceneNode *copy=CjguiCloneComposableSceneNode(ctx,ctx.composableNodes[i],
            (uint32_t)i,nextVersion);
        if (!copy) { [next removeAllObjects]; break; }
        if (i==1) {
            CjguiInternalRendererComposableNode raw=copy.node;
            raw.preservesActiveLocalText=1;
            copy.node=raw;
            copy.value=@"";
        }
        [next addObject:copy];
    }
    ctx.stagedComposableNodes=next;
    ctx.stagedComposableSceneVersion=nextVersion;
    ctx.stagedComposableDataTransferItems=[NSMutableArray array];
    ctx.stagedComposableDataTransferVersion=nextVersion;
    CjguiInternalRendererStatus committed=next.count==ctx.composableNodes.count
        ? CjguiCommitComposableSceneOnMain(token) : CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    CHECK(committed==CJGUI_INTERNAL_RENDERER_OK,"preserve_empty_value_scene_commits");
    if (committed==CJGUI_INTERNAL_RENDERER_OK) {
        CJGuiInternalComposableSceneNode *before=ctx.view.composableNodes[1];
        fprintf(stderr,"selection_production PRESERVE_REFRESH_BEFORE case=%s scene=%llu basis_scene=%llu "
            "node=%llu body_bytes=%lu preserve=%u transfer_tag=%llu caret=%.3f,%.3f,%.3f,%.3f selection_rects=%lu\n",
            label,(unsigned long long)ctx.composableSceneVersion,
            (unsigned long long)basis.candidate.installedSceneVersion,
            (unsigned long long)before.node.nodeId,
            (unsigned long)[before.value lengthOfBytesUsingEncoding:NSUTF8StringEncoding],
            (unsigned)before.node.preservesActiveLocalText,(unsigned long long)before.textSelectionTransferId,
            NSMinX(before.textCaretRect),NSMinY(before.textCaretRect),NSWidth(before.textCaretRect),
            NSHeight(before.textCaretRect),(unsigned long)before.textSelectionRects.count);
        CHECK(before.node.preservesActiveLocalText && before.value.length==0 &&
            before.textSelectionTransferId==basis.selectionTransferId,
            "preserve_refresh_candidate_is_empty_hint_with_old_transfer_tag");
        [o setNodesFromProjection:ctx.view.composableNodes];
    }
    CHECK(committed==CJGUI_INTERNAL_RENDERER_OK,"preserve_empty_scene_commit_remains_accepted");
    if (committed==CJGUI_INTERNAL_RENDERER_OK) {
        CJGuiInternalComposableSceneNode *after=ctx.view.composableNodes[1];
        NSRect effectiveCaret=CjguiEffectiveTransferTextCaretRect(ctx,after);
        NSArray<NSValue *> *effectiveRects=CjguiEffectiveTransferTextSelectionRects(ctx,after);
        BOOL bodyRestored=[after.value isEqualToString:source];
        BOOL proxyStillMatches=[o.inputProxy.string isEqualToString:source] &&
            NSEqualRanges(o.inputProxy.selectedRange,selected) && CjguiInstalledRangeBasisMatchesActual(ctx,o);
        BOOL geometryReady=expectCaret ? !NSIsEmptyRect(after.textCaretRect) && !NSIsEmptyRect(effectiveCaret) :
            after.textSelectionRects.count>0 && effectiveRects.count>0;
        fprintf(stderr,"selection_production PRESERVE_REFRESH_AFTER case=%s body_bytes=%lu proxy_bytes=%lu "
            "selection=%lu:%lu transfer_tag=%llu caret=%.3f,%.3f,%.3f,%.3f effective_caret=%.3f,%.3f,%.3f,%.3f "
            "rects=%lu effective_rects=%lu readback=%d\n",label,
            (unsigned long)[after.value lengthOfBytesUsingEncoding:NSUTF8StringEncoding],
            (unsigned long)[o.inputProxy.string lengthOfBytesUsingEncoding:NSUTF8StringEncoding],
            (unsigned long)o.inputProxy.selectedRange.location,(unsigned long)o.inputProxy.selectedRange.length,
            (unsigned long long)after.textSelectionTransferId,NSMinX(after.textCaretRect),NSMinY(after.textCaretRect),
            NSWidth(after.textCaretRect),NSHeight(after.textCaretRect),NSMinX(effectiveCaret),NSMinY(effectiveCaret),
            NSWidth(effectiveCaret),NSHeight(effectiveCaret),(unsigned long)after.textSelectionRects.count,
            (unsigned long)effectiveRects.count,(int)proxyStillMatches);
        CHECK(bodyRestored && proxyStillMatches,"preserve_refresh_keeps_exact_active_text_receipt");
        CHECK(after.textSelectionTransferId==0,"old_transfer_geometry_tag_is_retired");
        CHECK(geometryReady,expectCaret ? "preserve_refresh_retains_collapsed_caret" :
            "preserve_refresh_retains_noncollapsed_selection_geometry");
    }
    cjgui_internal_renderer_destroy(token);
    gSelectionProductionTargetBody=nil;
    gSelectionProductionTargetKind=CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT;
    gSelectionProductionTargetHeight=120.0;
    gSelectionProductionTargetClipHeight=500.0;
    gSelectionProductionTargetY=130.0;
}

static void SelectionBSpareChangedIdentityColdPrepares(CJGuiInternalSession *ctx,
    uint64_t version, uint32_t variant, const char *label) {
    uint64_t token=ctx.rendererSessionToken;
    BOOL staged=CommitSelectionTestSceneVariant(ctx,version,variant);
    uint64_t transfer=staged ? Prepare(ctx,3,6) : 0; uint8_t ready=0;
    CjguiInternalRendererStatus status=transfer
        ? cjgui_internal_renderer_selection_transfer_prepare_b(token,transfer,
            cjgui_internal_renderer_owner_clock_ns()+UINT64_C(16000000),&ready)
        : CJGUI_INTERNAL_RENDERER_SCENE_STALE;
    NSUInteger pumps=0;
    while (status==CJGUI_INTERNAL_RENDERER_OK && !ready && pumps++<10000) {
        usleep(1000);
        status=cjgui_internal_renderer_selection_transfer_prepare_b(token,transfer,
            cjgui_internal_renderer_owner_clock_ns()+UINT64_C(16000000),&ready);
    }
    CjguiSelectionTransferBPreparation *b=ctx.selectionTransferCapsule.bPreparation;
    CjguiTextPreparationWorkerJob *job=b.admission.textLayoutJob;
    BOOL cold=staged && status==CJGUI_INTERNAL_RENDERER_OK && ready && !b.reusedSpare && job &&
        !ctx.selectionBSpare && !job.workerLive && job.workerCompletedMicros>0;
    fprintf(stderr,"selection_production B_SPARE_NEGATIVE name=%s staged=%u status=%u ready=%u reused=%u job=%u spare=%u worker_completed=%llu result=%s\n",
        label,(unsigned)staged,(unsigned)status,(unsigned)ready,b.reusedSpare!=nil,job!=nil,
        ctx.selectionBSpare!=nil,(unsigned long long)(job?job.workerCompletedMicros:0),cold?"cold_worker":"mismatch");
    CHECK(cold,label);
    CjguiInternalSelectionTransferReceipt receipt={0};
    BOOL committed=cold && cjgui_internal_renderer_selection_transfer_install_b(token,transfer,&receipt)==
        CJGUI_INTERNAL_RENDERER_OK;
    CHECK(committed,"changed_identity_cold_worker_result_commits");
    if (transfer) Retire(ctx,transfer,committed);
    CHECK(committed && ctx.selectionBSpare && ctx.selectionBSpare.chargedBytes>0,
        "changed_identity_replenishes_bounded_spare_from_private_painter");
}

static void ChooseAndType(id<MTLDevice> device, BOOL initiallyFocused) {
    CJGuiInternalSession *ctx=Fixture(device,initiallyFocused);
    CJGuiInternalComposableSceneOverlay *o=ctx.composableSceneOverlay;
    uint64_t token=ctx.rendererSessionToken,transfer=Prepare(ctx,1,4);
    if(!transfer){cjgui_internal_renderer_destroy(token);return;}
    CjguiInternalSelectionTransferReceipt r={0};
    CHECK(cjgui_internal_renderer_selection_transfer_install_b(token,transfer,&r)==0,
        initiallyFocused?"choose_from_existing_caret":"first_click_from_non_text_responder");
    uint32_t state=0,refs=0;uint8_t cancel=0;
    cjgui_internal_renderer_selection_transfer_state(token,transfer,&state,&cancel,&refs);
    CHECK(state==CJGUI_SELECTION_TRANSFER_COMMITTED && r.proxyGeneration && r.firstResponder &&
        r.nodeId==402 && r.selectionStart16==1 && r.selectionEnd16==4,"actual_B_route_and_selection");
    CHECK(cjgui_internal_renderer_selection_transfer_request_cancel(token,transfer)!=0,"late_cancel_cannot_undo_choice");
    CHECK(cjgui_internal_renderer_selection_transfer_discard_capsule(token,transfer)==0,"native_retirement");
    CHECK(cjgui_internal_renderer_selection_transfer_release(token,transfer)==0,"owner_retirement");
    id<NSTextInputClient> responder=(id<NSTextInputClient>)ctx.window.firstResponder;
    CHECK([(NSObject *)responder respondsToSelector:@selector(insertText:replacementRange:)],"actual_responder_is_text_input_client");
    if([(NSObject *)responder respondsToSelector:@selector(insertText:replacementRange:)])
        [responder insertText:@"Z" replacementRange:NSMakeRange(NSNotFound,0)];
    CHECK([o.inputProxy.string isEqualToString:@"FZJ"],"actual_responder_inserts_exactly_once");
    CjguiInternalRendererEvent e={0};
    CHECK(cjgui_internal_renderer_pump_event(token,0,&e)==0 && e.kind==51,"normal_owner_fifo_receives_edit");
    CjguiInternalInstalledRangeIntent input={0};
    CHECK(cjgui_internal_renderer_claim_last_pumped_range(token,402,1,r.bindingEpoch,1,&input)==0 &&
        input.flags==2 && input.nonce==transfer && input.rangeStart16==1 && input.rangeLength16==3,
        "edit_carries_proven_local_range_and_global_choice_identity");
    cjgui_internal_renderer_destroy(token);
}

static void Retire(CJGuiInternalSession *ctx,uint64_t transfer,BOOL committed) {
    uint64_t token=ctx.rendererSessionToken;
    CHECK((committed?cjgui_internal_renderer_selection_transfer_discard_capsule(token,transfer):
        cjgui_internal_renderer_selection_transfer_replay_input(token,transfer))==0,"terminal_native_retirement");
    CHECK(cjgui_internal_renderer_selection_transfer_release(token,transfer)==0,"terminal_owner_retirement");
}

static BOOL SelectionPositionStopsMatch(CjguiPositionLine *a, CjguiPositionLine *b) {
    if (!a || !b) return NO;
    const NSData *groupsA[2]={a.primary,a.alternate};
    const NSData *groupsB[2]={b.primary,b.alternate};
    for (NSUInteger branch=0;branch<2;branch++) {
        if (groupsA[branch].length!=groupsB[branch].length) return NO;
        NSUInteger count=groupsA[branch].length/sizeof(CjguiPositionStop);
        const CjguiPositionStop *left=groupsA[branch].bytes,*right=groupsB[branch].bytes;
        for (NSUInteger i=0;i<count;i++)
            if (left[i].character!=right[i].character || left[i].branch!=right[i].branch ||
                left[i].platformOrdinal!=right[i].platformOrdinal || fabs(left[i].x-right[i].x)>1e-6) return NO;
    }
    return YES;
}

static BOOL SelectionPositionGeometryMatches(CjguiPreparedTextNodeLayout *worker,
                                              CjguiPreparedTextNodeLayout *oracle,
                                              NSUInteger character) {
    if (!worker || !oracle || character>=worker.storage.length || character>=oracle.storage.length) return NO;
    NSUInteger workerGlyph=[worker.layoutManager glyphIndexForCharacterAtIndex:character];
    NSUInteger oracleGlyph=[oracle.layoutManager glyphIndexForCharacterAtIndex:character];
    CjguiPositionLine *workerLine=nil,*oracleLine=nil; NSUInteger workerOrdinal=0,oracleOrdinal=0;
    CjguiInternalRendererStatus workerLineStatus=CjguiPositionLineForGlyph(worker,workerGlyph,NO,&workerLine);
    CjguiInternalRendererStatus oracleLineStatus=CjguiPositionLineForGlyph(oracle,oracleGlyph,NO,&oracleLine);
    CjguiInternalRendererStatus workerResolveStatus=CjguiPositionResolve(worker,character,2,0,0,&workerLine,&workerOrdinal);
    CjguiInternalRendererStatus oracleResolveStatus=CjguiPositionResolve(oracle,character,2,0,0,&oracleLine,&oracleOrdinal);
    if (workerLineStatus!=CJGUI_INTERNAL_RENDERER_OK || oracleLineStatus!=CJGUI_INTERNAL_RENDERER_OK ||
        workerResolveStatus!=CJGUI_INTERNAL_RENDERER_OK || oracleResolveStatus!=CJGUI_INTERNAL_RENDERER_OK) {
        fprintf(stderr,"selection_production B_GEOMETRY_RESOLVE character=%lu status=%u,%u,%u,%u glyph=%lu,%lu\n",
            (unsigned long)character,(unsigned)workerLineStatus,(unsigned)oracleLineStatus,
            (unsigned)workerResolveStatus,(unsigned)oracleResolveStatus,
            (unsigned long)workerGlyph,(unsigned long)oracleGlyph);
        return NO;
    }
    const CjguiPositionStop *workerStops=workerLine.stops.bytes,*oracleStops=oracleLine.stops.bytes;
    if (workerOrdinal>=workerLine.stops.length/sizeof(CjguiPositionStop) ||
        oracleOrdinal>=oracleLine.stops.length/sizeof(CjguiPositionStop)) {
        fprintf(stderr,"selection_production B_GEOMETRY_MISMATCH character=%lu reason=ordinal worker=%lu/%lu oracle=%lu/%lu\n",
            (unsigned long)character,(unsigned long)workerOrdinal,
            (unsigned long)(workerLine.stops.length/sizeof(CjguiPositionStop)),
            (unsigned long)oracleOrdinal,(unsigned long)(oracleLine.stops.length/sizeof(CjguiPositionStop)));
        return NO;
    }
    BOOL mismatch = workerLine.glyphs.location!=oracleLine.glyphs.location || workerLine.glyphs.length!=oracleLine.glyphs.length ||
        workerLine.characters.location!=oracleLine.characters.location || workerLine.characters.length!=oracleLine.characters.length ||
        fabs(NSMinX(workerLine.rect)-NSMinX(oracleLine.rect))>1e-6 ||
        fabs(NSMinY(workerLine.rect)-NSMinY(oracleLine.rect))>1e-6 ||
        fabs(NSWidth(workerLine.rect)-NSWidth(oracleLine.rect))>1e-6 ||
        fabs(NSHeight(workerLine.rect)-NSHeight(oracleLine.rect))>1e-6 ||
        workerStops[workerOrdinal].character!=oracleStops[oracleOrdinal].character ||
        workerStops[workerOrdinal].branch!=oracleStops[oracleOrdinal].branch ||
        fabs(workerStops[workerOrdinal].x-oracleStops[oracleOrdinal].x)>1e-6 ||
        !SelectionPositionStopsMatch(workerLine,oracleLine);
    if (mismatch) fprintf(stderr,"selection_production B_GEOMETRY_MISMATCH character=%lu worker_glyph=%lu:%lu oracle_glyph=%lu:%lu worker_chars=%lu:%lu oracle_chars=%lu:%lu worker_rect=%.3f,%.3f,%.3f,%.3f oracle_rect=%.3f,%.3f,%.3f,%.3f worker_stop=%lu/%lu/%.3f oracle_stop=%lu/%lu/%.3f worker_primary=%lu oracle_primary=%lu\n",
        (unsigned long)character,(unsigned long)workerLine.glyphs.location,(unsigned long)workerLine.glyphs.length,
        (unsigned long)oracleLine.glyphs.location,(unsigned long)oracleLine.glyphs.length,
        (unsigned long)workerLine.characters.location,(unsigned long)workerLine.characters.length,
        (unsigned long)oracleLine.characters.location,(unsigned long)oracleLine.characters.length,
        NSMinX(workerLine.rect),NSMinY(workerLine.rect),NSWidth(workerLine.rect),NSHeight(workerLine.rect),
        NSMinX(oracleLine.rect),NSMinY(oracleLine.rect),NSWidth(oracleLine.rect),NSHeight(oracleLine.rect),
        (unsigned long)workerStops[workerOrdinal].character,(unsigned long)workerStops[workerOrdinal].branch,
        workerStops[workerOrdinal].x,(unsigned long)oracleStops[oracleOrdinal].character,
        (unsigned long)oracleStops[oracleOrdinal].branch,oracleStops[oracleOrdinal].x,
        (unsigned long)workerLine.stops.length,(unsigned long)oracleLine.stops.length);
    return !mismatch;
    return YES;
}

static BOOL SelectionGeometryOracleMatches(CjguiPreparedTextNodeLayout *worker,
                                            CjguiPreparedTextNodeLayout *oracle) {
    NSUInteger length=worker.storage.length;
    if (length<2 || oracle.storage.length!=length) return NO;
    NSUInteger samples[4]={0,length/2,length-1,NSNotFound};
    CjguiPositionLine *first=nil;
    NSUInteger firstGlyph=[oracle.layoutManager glyphIndexForCharacterAtIndex:0];
    if (CjguiPositionLineForGlyph(oracle,firstGlyph,NO,&first)==CJGUI_INTERNAL_RENDERER_OK) {
        NSUInteger boundary=NSMaxRange(first.characters);
        if (boundary>0 && boundary<length &&
            [oracle.storage.string characterAtIndex:boundary-1]!='\n' &&
            [oracle.storage.string characterAtIndex:boundary-1]!='\r') samples[3]=boundary;
    }
    for (NSUInteger i=0;i<4;i++) {
        if (samples[i]==NSNotFound) continue;
        if (!SelectionPositionGeometryMatches(worker,oracle,samples[i])) return NO;
    }
    return YES;
}

static BOOL SelectionFiniteHeightControlMatches(CjguiPreparedTextNodeLayout *worker,
                                                 CjguiPreparedTextNodeLayout *oracle) {
    if (!worker || !oracle || worker.storage.length!=oracle.storage.length) return NO;
    NSUInteger firstGlyph=[oracle.layoutManager glyphIndexForCharacterAtIndex:0];
    CjguiPositionLine *first=nil;
    if (CjguiPositionLineForGlyph(oracle,firstGlyph,NO,&first)!=CJGUI_INTERNAL_RENDERER_OK ||
        !first || NSIsEmptyRect(first.rect)) return NO;
    NSUInteger softBoundary=NSMaxRange(first.characters);
    NSUInteger visibleSamples[3]={0,MIN((NSUInteger)500,worker.storage.length-1),NSNotFound};
    if (softBoundary>0 && softBoundary<worker.storage.length) visibleSamples[2]=softBoundary;
    for (NSUInteger i=0;i<3;i++) if (visibleSamples[i]!=NSNotFound &&
        !SelectionPositionGeometryMatches(worker,oracle,visibleSamples[i])) return NO;
    NSUInteger offscreen[2]={worker.storage.length/2,worker.storage.length-1};
    for (NSUInteger i=0;i<2;i++) {
        CjguiPositionLine *workerLine=nil,*oracleLine=nil; NSUInteger workerOrdinal=0,oracleOrdinal=0;
        CjguiInternalRendererStatus a=CjguiPositionResolve(worker,offscreen[i],2,0,0,&workerLine,&workerOrdinal);
        CjguiInternalRendererStatus b=CjguiPositionResolve(oracle,offscreen[i],2,0,0,&oracleLine,&oracleOrdinal);
        if (a!=CJGUI_INTERNAL_RENDERER_VISUAL_NAV_UNSUPPORTED ||
            b!=CJGUI_INTERNAL_RENDERER_VISUAL_NAV_UNSUPPORTED) return NO;
    }
    return YES;
}

static void SelectionLogLongLineInsertionGeometry(const char *name, CjguiPreparedTextNodeLayout *layout) {
    NSUInteger chars[3]={0,8192,layout.storage.length ? layout.storage.length-1 : 0};
    NSRect used=[layout.layoutManager usedRectForTextContainer:layout.container];
    fprintf(stderr,"selection_production B_LONG_LINE layout=%s length=%lu container=%.3f,%.3f used=%.3f,%.3f,%.3f,%.3f glyphs=%lu\n",
        name,(unsigned long)layout.storage.length,layout.container.containerSize.width,
        layout.container.containerSize.height,NSMinX(used),NSMinY(used),NSWidth(used),NSHeight(used),
        (unsigned long)layout.layoutManager.numberOfGlyphs);
    for (NSUInteger sample=0;sample<3;sample++) {
        NSUInteger character=chars[sample];
        NSUInteger glyph=[layout.layoutManager glyphIndexForCharacterAtIndex:character];
        NSRange glyphRange=NSMakeRange(NSNotFound,0);
        NSRect fragment=[layout.layoutManager lineFragmentRectForGlyphAtIndex:glyph effectiveRange:&glyphRange];
        NSRange characterRange=[layout.layoutManager characterRangeForGlyphRange:glyphRange actualGlyphRange:NULL];
        fprintf(stderr,"selection_production B_LONG_LINE_SAMPLE layout=%s char=%lu glyph=%lu line_glyph=%lu:%lu line_char=%lu:%lu rect=%.3f,%.3f,%.3f,%.3f",
            name,(unsigned long)character,(unsigned long)glyph,(unsigned long)glyphRange.location,
            (unsigned long)glyphRange.length,(unsigned long)characterRange.location,
            (unsigned long)characterRange.length,NSMinX(fragment),NSMinY(fragment),NSWidth(fragment),NSHeight(fragment));
        for (NSUInteger branch=0;branch<2;branch++) {
            BOOL alternate=branch!=0;
            NSUInteger count=[layout.layoutManager getLineFragmentInsertionPointsForCharacterAtIndex:character
                alternatePositions:alternate inDisplayOrder:YES positions:NULL characterIndexes:NULL];
            NSUInteger *indexes=count && count<=32769 ? calloc(count,sizeof(NSUInteger)) : NULL;
            CGFloat *positions=count && count<=32769 ? calloc(count,sizeof(CGFloat)) : NULL;
            NSUInteger filled=0;
            if (positions && indexes) filled=[layout.layoutManager getLineFragmentInsertionPointsForCharacterAtIndex:character
                alternatePositions:alternate inDisplayOrder:YES positions:positions characterIndexes:indexes];
            fprintf(stderr," %s_count=%lu_filled=%lu_first=%lu:%.3f_last=%lu:%.3f",
                alternate?"alternate":"primary",(unsigned long)count,(unsigned long)filled,
                filled?(unsigned long)indexes[0]:(unsigned long)NSNotFound,filled?positions[0]:0.0,
                filled?(unsigned long)indexes[filled-1]:(unsigned long)NSNotFound,filled?positions[filled-1]:0.0);
            free(indexes); free(positions);
        }
        fputc('\n',stderr);
    }
}

static void RefusedFocusPreservesA(id<MTLDevice> device) {
    CJGuiInternalSession *ctx=Fixture(device,NO); uint64_t token=ctx.rendererSessionToken;
    NSTextView *a=ctx.composableSceneOverlay.inputProxy; NSString *before=[a.string copy];
    ((SelectionProductionWindow *)ctx.window).refuseInputHost=YES;
    uint64_t transfer=Prepare(ctx,1,4); CjguiInternalSelectionTransferReceipt receipt={0};
    CHECK(cjgui_internal_renderer_selection_transfer_install_b(token,transfer,&receipt)!=0,
        "fallible_responder_attachment_refuses_before_decision");
    CHECK(ctx.composableSceneOverlay.inputProxy==a && [a.string isEqualToString:before] && !receipt.proxyGeneration,
        "attachment_failure_never_changes_A_graph_or_body");
    CHECK(cjgui_internal_renderer_selection_transfer_finish_abort(token,transfer)==0,"unmodified_A_aborts_without_recovery");
    Retire(ctx,transfer,NO);cjgui_internal_renderer_destroy(token);
}
static void SameChoiceReentryAndMarkedInput(id<MTLDevice> device) {
    CJGuiInternalSession *ctx=Fixture(device,YES); uint64_t token=ctx.rendererSessionToken;
    SelectionProductionOverlay *o=(id)ctx.composableSceneOverlay;
    CjguiInternalSelectionTransferReceipt first={0},second={0};
    uint64_t one=Prepare(ctx,1,4);
    CHECK(cjgui_internal_renderer_selection_transfer_install_b(token,one,&first)==0,"first_choice_installed");
    Retire(ctx,one,YES);
    NSResponder *host=ctx.window.firstResponder;
    uint64_t two=Prepare(ctx,4,1);
    CHECK(cjgui_internal_renderer_selection_transfer_install_b(token,two,&second)==0 && two!=one &&
        second.selectionRevision>first.selectionRevision && second.proxyGeneration>first.proxyGeneration &&
        ctx.window.firstResponder==host,"same_local_range_is_new_choice_with_stable_actual_responder");
    Retire(ctx,two,YES);
    uint64_t three=Prepare(ctx,0,2); o.inputDuringAttachment=YES;
    CjguiInternalSelectionTransferReceipt rejected={0};
    CHECK(cjgui_internal_renderer_selection_transfer_install_b(token,three,&rejected)!=0 &&
        [o.inputProxy.string isEqualToString:@"FXJ"] && !rejected.proxyGeneration,
        "reentrant_AppKit_input_defeats_pending_candidate_and_edits_A_once");
    uint32_t state=0,refs=0;uint8_t cancel=0;
    cjgui_internal_renderer_selection_transfer_state(token,three,&state,&cancel,&refs);
    CHECK(state==CJGUI_SELECTION_TRANSFER_ABORTED && ctx.selectionTransferCapsule.retainedInputs.count==0,
        "reentry_completes_in_A_FIFO_without_finalizing_retention");
    Retire(ctx,three,NO);
    CHECK([o.inputProxy.string isEqualToString:@"FXJ"],"retiring_aborted_choice_cannot_replay_text");
    cjgui_internal_renderer_destroy(token);

    ctx=Fixture(device,YES);token=ctx.rendererSessionToken;o=(id)ctx.composableSceneOverlay;
    one=Prepare(ctx,1,4);cjgui_internal_renderer_selection_transfer_install_b(token,one,&first);Retire(ctx,one,YES);
    host=ctx.window.firstResponder;
    CHECK(o.inputProxy.inputContext==[(NSView *)host inputContext] && [(NSView *)host inputContext].client==host,
        "IME_context_client_is_actual_stable_responder");
    [(id<NSTextInputClient>)host setMarkedText:@"ni" selectedRange:NSMakeRange(2,0) replacementRange:NSMakeRange(NSNotFound,0)];
    CHECK(o.inputProxy.hasMarkedText && [(id<NSTextInputClient>)host hasMarkedText],"host_preserves_system_marked_state");
    [(CJGuiInternalComposableInputProxy *)o.inputProxy cancelMarkedText];
    CHECK(!o.inputProxy.hasMarkedText && [o.inputProxy.string isEqualToString:@"FGHIJ"],
        "composition_cancel_restores_body_through_stable_context");
    cjgui_internal_renderer_destroy(token);
}

static void FinalizingCancelAndRealKey(id<MTLDevice> device) {
    CJGuiInternalSession *ctx=Fixture(device,YES);uint64_t token=ctx.rendererSessionToken;
    SelectionProductionOverlay *o=(id)ctx.composableSceneOverlay;
    NSTextView *old=o.inputProxy;NSResponder *host=ctx.window.firstResponder;
    uint64_t transfer=Prepare(ctx,1,4);o.cancelDuringPublication=YES;
    CjguiInternalSelectionTransferReceipt receipt={0};
    CHECK(cjgui_internal_renderer_selection_transfer_install_b(token,transfer,&receipt)!=0 &&
        o.inputProxy==old && [o.inputProxy.string isEqualToString:@"abcde"] && ctx.window.firstResponder==host &&
        !receipt.proxyGeneration,"cancel_at_publication_restores_exact_A_without_AppKit_rollback");
    uint32_t state=0,refs=0;uint8_t cancel=0;
    cjgui_internal_renderer_selection_transfer_state(token,transfer,&state,&cancel,&refs);
    CHECK(state==CJGUI_SELECTION_TRANSFER_ABORTED,"publication_cancel_is_terminal_before_returning_to_event_loop");
    Retire(ctx,transfer,NO);
    transfer=Prepare(ctx,1,4);
    CHECK(cjgui_internal_renderer_selection_transfer_install_b(token,transfer,&receipt)==0,"post_cancel_new_choice_succeeds");
    Retire(ctx,transfer,YES);
    NSEvent *key=[NSEvent keyEventWithType:NSEventTypeKeyDown location:NSZeroPoint modifierFlags:0 timestamp:0
        windowNumber:ctx.window.windowNumber context:nil characters:@"Z" charactersIgnoringModifiers:@"Z" isARepeat:NO keyCode:6];
    [ctx.window sendEvent:key];
    CHECK([o.inputProxy.string isEqualToString:@"FZJ"],"NSWindow_key_event_reaches_actual_host_and_TextKit");
    cjgui_internal_renderer_destroy(token);
}

static void WholeSelectionIncludesClippedText(id<MTLDevice> device) {
    CJGuiInternalSession *ctx=Fixture(device,NO); uint64_t token=ctx.rendererSessionToken;
    NSString *body=@"E-large-document: line=000000000000; unicode=仓颉🙂; payload=abcdefghijklmnopqrstuvwxyz";
    NSUInteger byteLength=[body lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
    cjgui_internal_renderer_configure_composable_scene(token,2,40);
    NSMutableArray<CJGuiInternalComposableSceneNode *> *nodes=[NSMutableArray array];
    for (NSUInteger i=0;i<40;i++) {
        CJGuiInternalComposableSceneNode *n=[CJGuiInternalComposableSceneNode new];
        CjguiInternalRendererComposableNode r={0};r.nodeId=1000+i;r.resourceId=-1;r.projectionVersion=2;
        r.nodeKind=CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT;r.isInteractive=1;r.x=20;r.y=i*158;
        r.width=640;r.height=158;r.clipWidth=680;r.clipHeight=500;r.fontSize=32;r.fontWeight=600;r.textAlpha=1;
        n.node=r;n.value=body;n.index=i;[nodes addObject:n];
    }
    ctx.stagedComposableNodes=nodes;ctx.stagedComposableDataTransferItems=[NSMutableArray array];
    ctx.stagedComposableDataTransferVersion=2;
    CHECK(CjguiCommitComposableSceneOnMain(token)==0,"large_surface_accepts_visible_and_clipped_text");
    NSString *runs=[NSString stringWithFormat:@"0:%lu:0:0:0:0:0:0:0:1:0.804:0.867:0.949:0.55:1",byteLength];
    cjgui_internal_renderer_configure_composable_scene(token,3,40);
    ctx.stagedComposableDataTransferVersion=3;
    for (NSUInteger i=0;i<40;i++) cjgui_internal_renderer_set_composable_text_runs(token,1000+i,runs.UTF8String);
    CHECK(CjguiCommitComposableSceneOnMain(token)==0,
        "whole_selection_publishes_with_unlaid_offscreen_fragments");
    NSUInteger visible=0,clipped=0;
    for (CJGuiInternalComposableSceneNode *n in ctx.composableNodes) {
        if (NSIsEmptyRect(NSIntersectionRect(CjguiComposableVisualNodeRect(n),CjguiComposableVisualClipBounds(n)))) {
            clipped++; CHECK(n.textDeclaredSelectionDecorations.count==0,"clipped_fragment_paints_no_old_selection");
        } else { visible+=n.textDeclaredSelectionDecorations.count>0; }
    }
    CHECK(visible>0 && clipped>0,"visible_selection_geometry_and_clipped_absence_are_both_proven");
    CJGuiInternalComposableSceneNode *bad=[CJGuiInternalComposableSceneNode new];bad.node=nodes[0].node;bad.value=body;
    CHECK(CjguiComposableDeclaredSelectionDecorations(bad,CjguiComposableDecodeStyleRuns(runs))==nil,
        "visible_missing_layout_still_refuses_selection");
    cjgui_internal_renderer_destroy(token);
}

// Exercise the shipped Edit-menu route for an interactive presentation TEXT
// whose center is inside a scroll region's frame but outside its clip. The
// overlay must fall back to the exact focused TEXT node, and the ordinary
// bounded interaction queue must accept kind-35 NAVIGATE for that identity.
static void PresentationTextSelectAllFallsBackToActiveNode(id<MTLDevice> device) {
    gSelectionProductionTargetKind=CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT;
    gSelectionProductionTargetBody=@"single paragraph";
    gSelectionProductionTargetHeight=120.0;
    gSelectionProductionTargetClipHeight=500.0;
    gSelectionProductionTargetY=130.0;
    CJGuiInternalSession *ctx=Fixture(device,NO);
    uint64_t token=ctx.rendererSessionToken;
    SelectionProductionOverlay *o=(id)ctx.composableSceneOverlay;

    NSMutableArray<CJGuiInternalComposableSceneNode *> *nodes=[NSMutableArray array];
    for (NSUInteger i=0;i<ctx.composableNodes.count;i++) {
        CJGuiInternalComposableSceneNode *copy=CjguiCloneComposableSceneNode(ctx,ctx.composableNodes[i],
            (uint32_t)i,2);
        if (copy) [nodes addObject:copy];
    }
    CJGuiInternalComposableSceneNode *scroll=[CJGuiInternalComposableSceneNode new];
    CjguiInternalRendererComposableNode raw={0};
    raw.nodeId=403;raw.resourceId=1;raw.projectionVersion=2;
    raw.nodeKind=CJGUI_INTERNAL_RENDERER_COMPOSABLE_SCROLL_AREA;
    raw.x=0;raw.y=130;raw.width=680;raw.height=240;
    raw.clipX=0;raw.clipY=130;raw.clipWidth=680;raw.clipHeight=20;
    raw.clipConstraintCount=1;raw.clip0X=0;raw.clip0Y=130;raw.clip0Width=680;raw.clip0Height=20;
    scroll.node=raw;scroll.index=(uint32_t)nodes.count;scroll.value=@"";
    [nodes addObject:scroll];
    ctx.stagedComposableNodes=nodes;ctx.stagedComposableSceneVersion=2;
    ctx.stagedComposableDataTransferItems=[NSMutableArray array];ctx.stagedComposableDataTransferVersion=2;
    CHECK(CjguiCommitComposableSceneOnMain(token)==CJGUI_INTERNAL_RENDERER_OK,
        "select_all_fixture_accepts_clipped_scroll_scope");
    [o setNodesFromProjection:ctx.view.composableNodes];
    [o focusCommittedNodeId:402];
    [ctx.pendingInteractions removeAllObjects];

    CJGuiInternalComposableSceneNode *active=[o activeFocusableNode];
    NSRect activeRect=active ? CjguiComposableRect(active,o) : NSZeroRect;
    NSPoint center=NSMakePoint(NSMidX(activeRect),NSMidY(activeRect));
    BOOL scopeMiss=active && active.node.nodeKind==CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT &&
        [o scrollNodeContainingPoint:center]==nil;
    CHECK(scopeMiss,"presentation_TEXT_center_outside_scroll_clip_uses_fallback_case");

    [o.inputHost selectAll:nil];
    CJGuiInternalQueuedInteraction *queued=ctx.pendingInteractions.lastObject;
    BOOL routed=ctx.pendingInteractions.count==1 && queued &&
        queued.kind==CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_NAVIGATE &&
        queued.formText.length && [queued.formText isEqualToString:@"select_all"] &&
        queued.recordIndex==active.index && queued.nodeId==active.node.nodeId &&
        queued.nodeKind==CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT;
    CHECK(routed,"menu_select_all_enqueues_kind35_for_active_TEXT_fallback_identity");
    fprintf(stderr,"selection_production SELECT_ALL_ROUTE active_kind=%u active_index=%u active_id=%llu "
        "center=%.1f,%.1f scope_miss=%d queued=%d queue_count=%lu\n",
        active ? active.node.nodeKind : 0,active ? active.index : UINT32_MAX,
        (unsigned long long)(active ? active.node.nodeId : 0),center.x,center.y,(int)scopeMiss,
        (int)routed,(unsigned long)ctx.pendingInteractions.count);

    // Widen only the scroll clip. The same production selector must now
    // choose the containing scroll node rather than the active TEXT fallback.
    NSMutableArray<CJGuiInternalComposableSceneNode *> *wideNodes=[NSMutableArray array];
    for (NSUInteger i=0;i<ctx.composableNodes.count;i++) {
        CJGuiInternalComposableSceneNode *copy=CjguiCloneComposableSceneNode(ctx,ctx.composableNodes[i],
            (uint32_t)i,3);
        if (copy && copy.node.nodeId==403) {
            CjguiInternalRendererComposableNode wider=copy.node;
            wider.clipHeight=240;wider.clip0Height=240;copy.node=wider;
        }
        if (copy) [wideNodes addObject:copy];
    }
    ctx.stagedComposableNodes=wideNodes;ctx.stagedComposableSceneVersion=3;
    ctx.stagedComposableDataTransferItems=[NSMutableArray array];ctx.stagedComposableDataTransferVersion=3;
    BOOL wideAccepted=CjguiCommitComposableSceneOnMain(token)==CJGUI_INTERNAL_RENDERER_OK;
    CHECK(wideAccepted,"select_all_fixture_accepts_visible_scroll_clip");
    if (wideAccepted) {
        [o setNodesFromProjection:ctx.view.composableNodes];
        [o focusCommittedNodeId:402];
        [ctx.pendingInteractions removeAllObjects];
        active=[o activeFocusableNode];
        activeRect=active ? CjguiComposableRect(active,o) : NSZeroRect;
        center=NSMakePoint(NSMidX(activeRect),NSMidY(activeRect));
        CJGuiInternalComposableSceneNode *scope=[o scrollNodeContainingPoint:center];
        [o.inputHost selectAll:nil];
        queued=ctx.pendingInteractions.lastObject;
        BOOL scoped=scope && scope.node.nodeId==403 && ctx.pendingInteractions.count==1 && queued &&
            queued.kind==CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_NAVIGATE &&
            [queued.formText isEqualToString:@"select_all"] && queued.recordIndex==scope.index &&
            queued.nodeId==scope.node.nodeId && queued.nodeKind==CJGUI_INTERNAL_RENDERER_COMPOSABLE_SCROLL_AREA;
        CHECK(scoped,"menu_select_all_inside_clip_enqueues_containing_scroll_scope");
    }

    // The production enqueue guard is the bounded FIFO capacity. A full queue
    // must reject this same real selector call and expose its named notice.
    [ctx.pendingInteractions removeAllObjects];
    for (NSUInteger i=0;i<kCjguiPendingInteractionCapacity;i++)
        (void)CjguiEnqueueComposableInteraction(ctx,
            CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_NAVIGATE,1,@"sentinel",NSMakeRange(0,0));
    ctx.pendingInputQueueFullNotice=NO;
    NSUInteger fullBefore=ctx.pendingInteractions.count;
    [o.inputHost selectAll:nil];
    CHECK(fullBefore==kCjguiPendingInteractionCapacity &&
        ctx.pendingInteractions.count==fullBefore && ctx.pendingInputQueueFullNotice,
        "menu_select_all_full_queue_refuses_without_overflow_and_sets_notice");

    cjgui_internal_renderer_destroy(token);
    gSelectionProductionTargetBody=nil;
    gSelectionProductionTargetHeight=120.0;
    gSelectionProductionTargetClipHeight=500.0;
    gSelectionProductionTargetY=130.0;
    gSelectionProductionTargetKind=CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT;
}

static void LongBUsesPrivateWorkerGraph(id<MTLDevice> device, NSString *body, const char *label,
                                       CGFloat targetHeight, BOOL finiteHeightControl) {
    gSelectionProductionTargetBody=body;
    gSelectionProductionTargetHeight=targetHeight;
    gSelectionProductionTargetClipHeight=targetHeight>120.0 ? 120.0 : 500.0;
    gSelectionProductionTargetY=targetHeight>120.0 ? 0.0 : 130.0;
    CJGuiInternalSession *ctx=Fixture(device,YES);
    uint64_t token=ctx.rendererSessionToken,transfer=Prepare(ctx,1,4);
    if (!transfer) { cjgui_internal_renderer_destroy(token); gSelectionProductionTargetBody=nil; return; }
    CJGuiInternalComposableSceneNode *target=ctx.composableSceneOverlay.nodes[1];
    CjguiPreparedTextNodeLayout *oldLayout=target.preparedTextLayout;
    NSData *oracleRuns=CjguiComposableDecodeStyleRuns(ctx.composableTextStyleRunsRaw[@(target.node.nodeId)] ?: @"");
    CjguiPreparedTextNodeLayout *syncOracle=CjguiPrepareTextNodeLayout(target,target.value,1.0,oracleRuns,ctx);
    BOOL oracleComplete=CjguiTextPreparationForceCompleteLayout(syncOracle);
    pthread_mutex_lock(&gSelectionLayoutCounterLock);
    uint64_t mainEnsureBefore=gSelectionLongMainEnsureCount,workerEnsureBefore=gSelectionLongWorkerEnsureCount;
    pthread_mutex_unlock(&gSelectionLayoutCounterLock);
    CjguiTextPreparationWorkerJob *job=nil;
    uint8_t ready=0;
    CjguiInternalRendererStatus status=CJGUI_INTERNAL_RENDERER_OK;
    uint64_t preparationStart=cjgui_internal_renderer_owner_clock_ns();
    uint64_t deadline=cjgui_internal_renderer_owner_clock_ns()+UINT64_C(16000000);
    status=cjgui_internal_renderer_selection_transfer_prepare_b(token,transfer,deadline,&ready);
    NSUInteger pumps=0;
    while (status==CJGUI_INTERNAL_RENDERER_OK && !ready && pumps++<10000) {
        usleep(1000);
        deadline=cjgui_internal_renderer_owner_clock_ns()+UINT64_C(16000000);
        status=cjgui_internal_renderer_selection_transfer_prepare_b(token,transfer,deadline,&ready);
    }
    CjguiSelectionTransferBPreparation *b=ctx.selectionTransferCapsule.bPreparation;
    if (!b || !b.admission.textLayoutJob) {
        CHECK(NO,label);
        uint32_t transferState=0; uint8_t transferCancelled=0; uint32_t refs=0;
        cjgui_internal_renderer_selection_transfer_state(token,transfer,&transferState,&transferCancelled,&refs);
        if (transferState==CJGUI_SELECTION_TRANSFER_PENDING)
            cjgui_internal_renderer_selection_transfer_finish_abort(token,transfer);
        Retire(ctx,transfer,NO);
        cjgui_internal_renderer_destroy(token);
        gSelectionProductionTargetBody=nil;
        return;
    }
    job=b.admission.textLayoutJob;
    if (strstr(label,"16KiB_ASCII")!=NULL) {
        SelectionLogLongLineInsertionGeometry("worker",b.sourceLayout);
        SelectionLogLongLineInsertionGeometry("sync_oracle",syncOracle);
    }
    fprintf(stderr,"selection_production B_LAYOUT_CONFIG case=%s input=%u,%0.3f,%u,%lu,%u,%u,%u layout=%0.3fx%0.3f,%0.3f,%u,%lu,%u,%u,%u\n",
        label,(unsigned)b.workerInput.sourceGraphConfigurationPresent,b.workerInput.containerPadding,
        (unsigned)b.workerInput.containerLineBreakMode,(unsigned long)b.workerInput.containerMaximumNumberOfLines,
        (unsigned)b.workerInput.containerHeightTracksTextView,(unsigned)b.workerInput.layoutAllowsNonContiguous,
        (unsigned)b.workerInput.layoutUsesFontLeading,b.painter.container.containerSize.width,
        b.painter.container.containerSize.height,b.painter.container.lineFragmentPadding,
        (unsigned)b.painter.container.lineBreakMode,(unsigned long)b.painter.container.maximumNumberOfLines,
        (unsigned)b.painter.container.heightTracksTextView,(unsigned)b.painter.layoutManager.allowsNonContiguousLayout,
        (unsigned)b.painter.layoutManager.usesFontLeading);
    uint64_t preparationReady=cjgui_internal_renderer_owner_clock_ns();
    fprintf(stderr,"selection_production B_PREP_DIAG case=%s status=%u ready=%u b=%d job=%d state=%u live=%d cancel=%d failure=%s reserved=%llu input=%p source=%p painter=%p\n",
        label,(unsigned)status,ready,b!=nil,job!=nil,(unsigned)job.state,(int)job.workerLive,(int)job.cancelled,
        job.failure.UTF8String ?: "none",(unsigned long long)job.reservedBytes,job.input,job.sourceLayout,job.painter);
    BOOL readyChargeHeld=NO;
    pthread_mutex_lock(&gCjguiTextPreparationWorkerLock);
    readyChargeHeld=job.reservedBytes>0 && job.slotIndex<CjguiTextPreparationWorkerSlotCount &&
        gCjguiTextPreparationWorkerSlots[job.slotIndex]==job;
    pthread_mutex_unlock(&gCjguiTextPreparationWorkerLock);
    CHECK(status==CJGUI_INTERNAL_RENDERER_OK && ready && b.ready && !job.workerLive &&
        readyChargeHeld && b.sourceLayout.layoutManager.firstUnlaidCharacterIndex>=b.sourceLayout.storage.length,
        label);
    NSTextView *preparedProxy=b.preparedOverlay.inputProxy;
    CHECK(!preparedProxy.richText && !preparedProxy.usesRuler && !preparedProxy.allowsUndo &&
        !preparedProxy.continuousSpellCheckingEnabled && !preparedProxy.grammarCheckingEnabled &&
        !preparedProxy.automaticSpellingCorrectionEnabled && !preparedProxy.automaticTextReplacementEnabled &&
        !preparedProxy.automaticQuoteSubstitutionEnabled && !preparedProxy.automaticDashSubstitutionEnabled,
        "worker_B_inherits_plain_input_policy_before_selection");
    CHECK(target.preparedTextLayout==oldLayout,"B_candidate_does_not_mutate_accepted_layout_before_commit");
    CjguiPreparedTextNodeLayout *layout=b.sourceLayout;
    if (finiteHeightControl) {
        CHECK(oracleComplete && SelectionFiniteHeightControlMatches(layout,syncOracle),
            "finite_height_worker_matches_visible_rows_and_both_name_offscreen_unsupported");
    } else {
        BOOL fullParagraphMaterialized=oracleComplete &&
            layout.layoutManager.firstUnlaidCharacterIndex>=layout.storage.length &&
            syncOracle.layoutManager.firstUnlaidCharacterIndex>=syncOracle.storage.length &&
            NSHeight([layout.layoutManager usedRectForTextContainer:layout.container]) < layout.container.containerSize.height &&
            NSHeight([syncOracle.layoutManager usedRectForTextContainer:syncOracle.container]) < syncOracle.container.containerSize.height;
        CHECK(fullParagraphMaterialized && SelectionGeometryOracleMatches(layout,syncOracle),
            "full_paragraph_worker_matches_first_middle_tail_softwrap_and_caret_oracle");
    }
    uint64_t workerStartMono=b.workerStartedMonoNs,workerCompleteMono=b.workerCompletedMonoNs;
    uint64_t mainService=b.mainServiceNs;
    NSUInteger sourceFirstUnlaid=layout.layoutManager.firstUnlaidCharacterIndex;
    NSUInteger before=layout.layoutManager.firstUnlaidCharacterIndex;
    CjguiInternalSelectionTransferReceipt receipt={0};
    CHECK(cjgui_internal_renderer_selection_transfer_install_b(token,transfer,&receipt)==CJGUI_INTERNAL_RENDERER_OK,
        "prepared_B_install_succeeds");
    BOOL sameStorage=ctx.composableSceneOverlay.inputProxy.textStorage==layout.storage;
    BOOL sameManager=ctx.composableSceneOverlay.inputProxy.layoutManager==layout.layoutManager;
    BOOL sameContainer=ctx.composableSceneOverlay.inputProxy.textContainer==layout.container;
    BOOL sameUnlaid=layout.layoutManager.firstUnlaidCharacterIndex==before;
    BOOL sameNodeLayout=target.preparedTextLayout==layout;
    BOOL sameSelection=NSEqualRanges(ctx.composableSceneOverlay.inputProxy.selectedRange,NSMakeRange(1,3));
    fprintf(stderr,"selection_production B_ADOPT case=%s storage=%d manager=%d container=%d unlaid=%d node_layout=%d selection=%d actual_selection=%lu:%lu first_unlaid=%lu before=%lu\n",
        label,sameStorage,sameManager,sameContainer,sameUnlaid,sameNodeLayout,sameSelection,
        (unsigned long)ctx.composableSceneOverlay.inputProxy.selectedRange.location,
        (unsigned long)NSMaxRange(ctx.composableSceneOverlay.inputProxy.selectedRange),
        (unsigned long)layout.layoutManager.firstUnlaidCharacterIndex,(unsigned long)before);
    CHECK(sameStorage && sameManager && sameContainer && sameUnlaid && sameNodeLayout && sameSelection,
        "install_adopts_same_complete_worker_graph_and_selection");
    uint64_t caretSamples[3]={0,finiteHeightControl ? (uint64_t)MIN((NSUInteger)500,layout.storage.length-1)
        : layout.storage.length/2,layout.storage.length-1};
    BOOL hitQueriesComplete=YES;
    for (NSUInteger i=0;i<3;i++) {
        CjguiPositionLine *line=nil; NSUInteger ordinal=0;
        CjguiInternalRendererStatus hitStatus=CjguiPositionResolve(layout,caretSamples[i],2,0,0,&line,&ordinal);
        if (finiteHeightControl && i==2) {
            CjguiPositionLine *oracleLine=nil; NSUInteger oracleOrdinal=0;
            CjguiInternalRendererStatus oracleStatus=CjguiPositionResolve(syncOracle,caretSamples[i],2,0,0,
                &oracleLine,&oracleOrdinal);
            BOOL clippedBoth=hitStatus==CJGUI_INTERNAL_RENDERER_VISUAL_NAV_UNSUPPORTED &&
                oracleStatus==CJGUI_INTERNAL_RENDERER_VISUAL_NAV_UNSUPPORTED;
            fprintf(stderr,"selection_production B_FINITE_OFFSCREEN char=%llu worker_status=%u oracle_status=%u result=%s\n",
                (unsigned long long)caretSamples[i],(unsigned)hitStatus,(unsigned)oracleStatus,
                clippedBoth?"both_named_unsupported":"mismatch");
            hitQueriesComplete &= clippedBoth;
            continue;
        }
        BOOL sampleOK=hitStatus==CJGUI_INTERNAL_RENDERER_OK &&
            line && ordinal<line.stops.length/sizeof(CjguiPositionStop) &&
            ((const CjguiPositionStop *)line.stops.bytes)[ordinal].character==caretSamples[i];
        if (!sampleOK) fprintf(stderr,"selection_production B_HIT_SAMPLE character=%llu status=%u line=%d ordinal=%lu stop_count=%lu actual=%lu\n",
            (unsigned long long)caretSamples[i],(unsigned)hitStatus,line!=nil,(unsigned long)ordinal,
            (unsigned long)(line.stops.length/sizeof(CjguiPositionStop)),
            line && ordinal<line.stops.length/sizeof(CjguiPositionStop)
                ? (unsigned long)((const CjguiPositionStop *)line.stops.bytes)[ordinal].character : (unsigned long)NSNotFound);
        hitQueriesComplete &= sampleOK;
    }
    id<MTLTexture> firstDraw=CjguiComposableTextTexture(ctx.view,target,1.0,1.0,target.value
#ifdef CJGUI_INTERNAL_TESTING
        ,CjguiInternalTextWorkReasonActiveContent
#endif
    );
    pthread_mutex_lock(&gSelectionLayoutCounterLock);
    BOOL drawHitNoMainWholeLayout=gSelectionLongMainEnsureCount==mainEnsureBefore;
    pthread_mutex_unlock(&gSelectionLayoutCounterLock);
    CHECK(hitQueriesComplete && firstDraw && layout.layoutManager.firstUnlaidCharacterIndex==layout.storage.length &&
        drawHitNoMainWholeLayout,"first_draw_and_edge_hit_queries_keep_complete_worker_layout_without_main_relayout");
    pthread_mutex_lock(&gSelectionLayoutCounterLock);
    BOOL layoutStayedOffMain=gSelectionLongMainEnsureCount==mainEnsureBefore &&
        gSelectionLongWorkerEnsureCount>workerEnsureBefore;
    pthread_mutex_unlock(&gSelectionLayoutCounterLock);
    fprintf(stderr,"selection_production B_PREP_TIMING case=%s total_to_ready_ns=%llu worker_start_mono_ns=%llu "
        "worker_complete_mono_ns=%llu worker_total_ns=%llu main_service_ns=%llu main_thread=%d source_first_unlaid=%lu\n",
        label,(unsigned long long)(preparationReady-preparationStart),
        (unsigned long long)workerStartMono,(unsigned long long)workerCompleteMono,
        (unsigned long long)(workerCompleteMono-workerStartMono),(unsigned long long)mainService,
        (int)[NSThread isMainThread],(unsigned long)sourceFirstUnlaid);
    CHECK(layoutStayedOffMain,"whole_TextKit_ensure_occurs_on_worker_not_selection_main_path");
    BOOL released=YES;
    pthread_mutex_lock(&gCjguiTextPreparationWorkerLock);
    for (NSUInteger i=0;i<CjguiTextPreparationWorkerSlotCount;i++) released &= gCjguiTextPreparationWorkerSlots[i]!=job;
    pthread_mutex_unlock(&gCjguiTextPreparationWorkerLock);
    CHECK(released && !job.reservedBytes,"worker_capacity_released_after_graph_adoption");
    fprintf(stderr,"selection_production B_SPARE case=%s present=%d charge=%llu private_painter=%d identity=%d\n",
        label,ctx.selectionBSpare!=nil,(unsigned long long)ctx.selectionBSpare.chargedBytes,
        ctx.selectionBSpare.painter!=layout,
        CjguiSelectionBSpareLayoutMatches(ctx.selectionBSpare.painter,ctx.selectionBSpare.identity));
    uint32_t transferState=0; uint8_t transferCancelled=0; uint32_t refs=0;
    cjgui_internal_renderer_selection_transfer_state(token,transfer,&transferState,&transferCancelled,&refs);
    if (transferState==CJGUI_SELECTION_TRANSFER_COMMITTED) Retire(ctx,transfer,YES);
    else { cjgui_internal_renderer_selection_transfer_finish_abort(token,transfer); Retire(ctx,transfer,NO); }
    if (ctx.selectionBSpare && strcmp(label,"16KiB_ASCII_full_paragraph_geometry")==0) {
        pthread_mutex_lock(&gSelectionLayoutCounterLock);
        uint64_t repeatedMainBefore=gSelectionLongMainEnsureCount, repeatedWorkerBefore=gSelectionLongWorkerEnsureCount;
        pthread_mutex_unlock(&gSelectionLayoutCounterLock);
        uint64_t repeated=Prepare(ctx,2,5); uint8_t repeatedReady=0;
        CjguiInternalRendererStatus repeatedStatus=cjgui_internal_renderer_selection_transfer_prepare_b(
            token,repeated,cjgui_internal_renderer_owner_clock_ns()+UINT64_C(16000000),&repeatedReady);
        CjguiSelectionTransferBPreparation *repeatedB=ctx.selectionTransferCapsule.bPreparation;
        CHECK(repeatedStatus==CJGUI_INTERNAL_RENDERER_OK && repeatedReady && repeatedB.reusedSpare==ctx.selectionBSpare &&
            !repeatedB.admission.textLayoutJob,"same_node_same_body_selection_reuses_detached_spare_without_worker");
        CjguiInternalSelectionTransferReceipt repeatedReceipt={0};
        CHECK(cjgui_internal_renderer_selection_transfer_install_b(token,repeated,&repeatedReceipt)==CJGUI_INTERNAL_RENDERER_OK,
            "same_node_spare_selection_commits");
        pthread_mutex_lock(&gSelectionLayoutCounterLock);
        BOOL repeatedNoWholeLayout=gSelectionLongMainEnsureCount==repeatedMainBefore &&
            gSelectionLongWorkerEnsureCount==repeatedWorkerBefore;
        pthread_mutex_unlock(&gSelectionLayoutCounterLock);
        CHECK(repeatedNoWholeLayout,"same_node_hot_selection_adds_no_whole_layout");
        Retire(ctx,repeated,YES);
        if (strcmp(label,"16KiB_ASCII_full_paragraph_geometry")==0) {
            pthread_mutex_lock(&gSelectionLayoutCounterLock);
            uint64_t sceneMainBefore=gSelectionLongMainEnsureCount,sceneWorkerBefore=gSelectionLongWorkerEnsureCount;
            pthread_mutex_unlock(&gSelectionLayoutCounterLock);
            BOOL changedScene=CommitSelectionTestSceneVariant(ctx,2,0);
            uint64_t nextTransfer=changedScene ? Prepare(ctx,3,6) : 0; uint8_t nextReady=0;
            CjguiInternalRendererStatus nextStatus=nextTransfer
                ? cjgui_internal_renderer_selection_transfer_prepare_b(token,nextTransfer,
                    cjgui_internal_renderer_owner_clock_ns()+UINT64_C(16000000),&nextReady)
                : CJGUI_INTERNAL_RENDERER_SCENE_STALE;
            CjguiSelectionTransferBPreparation *nextB=ctx.selectionTransferCapsule.bPreparation;
            BOOL crossSceneReuse=changedScene && nextStatus==CJGUI_INTERNAL_RENDERER_OK && nextReady &&
                nextB.reusedSpare==ctx.selectionBSpare && !nextB.admission.textLayoutJob;
            CHECK(crossSceneReuse,"new_scene_coordinate_and_selection_change_reuses_layout_spare");
            CjguiInternalSelectionTransferReceipt nextReceipt={0};
            BOOL crossSceneCommit=nextTransfer && cjgui_internal_renderer_selection_transfer_install_b(
                token,nextTransfer,&nextReceipt)==CJGUI_INTERNAL_RENDERER_OK;
            CHECK(crossSceneCommit,"new_scene_cached_selection_commits");
            pthread_mutex_lock(&gSelectionLayoutCounterLock);
            BOOL crossSceneNoWholeLayout=gSelectionLongMainEnsureCount==sceneMainBefore &&
                gSelectionLongWorkerEnsureCount==sceneWorkerBefore;
            pthread_mutex_unlock(&gSelectionLayoutCounterLock);
            CHECK(crossSceneCommit && crossSceneNoWholeLayout,
                "new_scene_coordinate_and_selection_change_adds_no_whole_layout");
            if (nextTransfer) Retire(ctx,nextTransfer,crossSceneCommit);
            if (crossSceneCommit) {
                SelectionBSpareChangedIdentityColdPrepares(ctx,3,1,"body_change_requires_cold_worker");
                SelectionBSpareChangedIdentityColdPrepares(ctx,4,2,"font_change_requires_cold_worker");
                SelectionBSpareChangedIdentityColdPrepares(ctx,5,3,"width_change_requires_cold_worker");
            }
        }
    }
    cjgui_internal_renderer_destroy(token);
    gSelectionProductionTargetBody=nil;
    gSelectionProductionTargetHeight=120.0;
    gSelectionProductionTargetClipHeight=500.0;
    gSelectionProductionTargetY=130.0;
    gSelectionProductionTargetKind=CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT;
}

#ifdef CJGUI_INTERNAL_TESTING
static void CancelledBWorkerKeepsChargeUntilExit(id<MTLDevice> device) {
    CjguiTextPreparationTestCloseWorkerGate();
    gSelectionProductionTargetBody=[@"" stringByPaddingToLength:4096 withString:@"c" startingAtIndex:0];
    CJGuiInternalSession *ctx=Fixture(device,YES);
    uint64_t token=ctx.rendererSessionToken,transfer=Prepare(ctx,1,4);
    uint8_t ready=0;
    CjguiInternalRendererStatus started=cjgui_internal_renderer_selection_transfer_prepare_b(
        token,transfer,cjgui_internal_renderer_owner_clock_ns()+UINT64_C(16000000),&ready);
    CjguiSelectionTransferBPreparation *b=ctx.selectionTransferCapsule.bPreparation;
    CjguiTextPreparationWorkerJob *job=b.admission.textLayoutJob;
    BOOL atGate=CjguiTextPreparationTestWaitForWorkerGate(3000);
    uint64_t chargedBefore=job.reservedBytes;
    id<NSTextInputClient> responder=(id<NSTextInputClient>)ctx.window.firstResponder;
    if ([(NSObject *)responder respondsToSelector:@selector(insertText:replacementRange:)])
        [responder insertText:@"X" replacementRange:NSMakeRange(NSNotFound,0)];
    CjguiInternalRendererStatus stale=cjgui_internal_renderer_selection_transfer_prepare_b(
        token,transfer,cjgui_internal_renderer_owner_clock_ns()+UINT64_C(16000000),&ready);
    uint32_t state=CJGUI_SELECTION_TRANSFER_EMPTY,refs=0;uint8_t cancelled=0;
    cjgui_internal_renderer_selection_transfer_state(token,transfer,&state,&cancelled,&refs);
    BOOL held=NO;
    pthread_mutex_lock(&gCjguiTextPreparationWorkerLock);
    held=job.workerLive && job.cancelled && !job.consumerLive && job.reservedBytes==chargedBefore &&
        job.slotIndex<CjguiTextPreparationWorkerSlotCount && gCjguiTextPreparationWorkerSlots[job.slotIndex]==job;
    pthread_mutex_unlock(&gCjguiTextPreparationWorkerLock);
    CHECK(started==CJGUI_INTERNAL_RENDERER_OK && !ready && atGate && chargedBefore>0,
        "B_worker_started_and_blocked_with_capacity_charge");
    CHECK(state==CJGUI_SELECTION_TRANSFER_ABORTED && stale==CJGUI_INTERNAL_RENDERER_SCENE_STALE &&
        ctx.selectionTransferCapsule.bPreparation==nil &&
        [ctx.composableSceneOverlay.inputProxy.string isEqualToString:@"abcdeX"],
        "real_A_input_aborts_pending_edits_A_once_and_B_cannot_be_resurrected");
    CHECK(held,"cancelled_B_keeps_slot_and_charge_while_worker_is_live");
    CjguiTextPreparationTestOpenWorkerGate();
    BOOL exited=CjguiTextPreparationTestWaitForFinished(5000);
    BOOL released=NO;
    pthread_mutex_lock(&gCjguiTextPreparationWorkerLock);
    released=!job.workerLive && !job.reservedBytes &&
        gCjguiTextPreparationWorkerSlots[job.slotIndex]!=job;
    pthread_mutex_unlock(&gCjguiTextPreparationWorkerLock);
    CHECK(exited && released,"cancelled_B_releases_capacity_only_after_worker_exit");
    Retire(ctx,transfer,NO);
    cjgui_internal_renderer_destroy(token);
    gSelectionProductionTargetBody=nil;
}
#endif

// A hot graph must retain its extent before a later scrolled selection scene.
static void WarmSelectionPreservesScrolledGeometry(id<MTLDevice> device) {
    gSelectionProductionTargetBody=[@"" stringByPaddingToLength:16384 withString:@"a" startingAtIndex:0];
    gSelectionProductionTargetHeight=5000; gSelectionProductionTargetY=0;
    gSelectionProductionTargetClipHeight=120;
    CJGuiInternalSession *ctx=Fixture(device,YES); uint64_t token=ctx.rendererSessionToken;
    NSSize coldExtent=NSZeroSize;
    for(NSUInteger i=0;i<2;i++) {
        uint64_t transfer=Prepare(ctx,(uint32_t)(i+1),(uint32_t)(i+4)); uint8_t ready=0;
        CjguiInternalRendererStatus status=0;
        for(NSUInteger pump=0;!ready && !status && pump<10000;pump++) {
            status=cjgui_internal_renderer_selection_transfer_prepare_b(token,transfer,
                cjgui_internal_renderer_owner_clock_ns()+UINT64_C(16000000),&ready);
            if(!ready)usleep(1000);
        }
        CjguiSelectionTransferBPreparation *b=ctx.selectionTransferCapsule.bPreparation;
        if(i==0)coldExtent=b.measuredExtent;
        fprintf(stderr,"WARM_EXTENT pass=%lu ready=%u reused=%u job=%u extent=%.3f:%.3f cold=%.3f:%.3f\n",
            (unsigned long)i,ready,b.reusedSpare!=nil,b.admission.textLayoutJob!=nil,
            b.measuredExtent.width,b.measuredExtent.height,coldExtent.width,coldExtent.height);
        CHECK(status==0 && ready,"prepare_ready");
        CHECK(coldExtent.width>0 && coldExtent.height>1000 && NSEqualSizes(coldExtent,b.measuredExtent),
            "warm_selection_preserves_complete_extent");
        CjguiInternalSelectionTransferReceipt receipt={0};
        CHECK(cjgui_internal_renderer_selection_transfer_install_b(token,transfer,&receipt)==0,"install_ready_graph");
        Retire(ctx,transfer,YES);
    }
    NSMutableArray *next=[NSMutableArray array];
    for(NSUInteger i=0;i<ctx.composableNodes.count;i++) {
        CJGuiInternalComposableSceneNode *node=CjguiCloneComposableSceneNode(ctx,ctx.composableNodes[i],(uint32_t)i,2);
        if(i==1) { CjguiInternalRendererComposableNode raw=node.node; raw.y=-1000; node.node=raw; }
        [next addObject:node];
    }
    ctx.composableTextStyleRunsRaw[@402]=@"0:16384:0:0:0:0:0:0:0:1:0.804:0.867:0.949:0.55:1";
    ctx.stagedComposableNodes=next;ctx.stagedComposableSceneVersion=2;
    ctx.stagedComposableDataTransferItems=[NSMutableArray array];ctx.stagedComposableDataTransferVersion=2;
    CjguiInternalRendererStatus commit=CjguiCommitComposableSceneOnMain(token);
    CJGuiInternalComposableSceneNode *candidate=next[1];
    fprintf(stderr,"WARM_SCROLLED_ALL status=%u extent=%.3f:%.3f storage=%lu body=%lu declared=%lu coverage=%s\n",
        commit,candidate.textMeasuredExtent.width,candidate.textMeasuredExtent.height,
        (unsigned long)candidate.preparedTextLayout.storage.length,(unsigned long)candidate.value.length,
        (unsigned long)candidate.textDeclaredSelectionDecorations.count,
        NSStringFromRect(CjguiComposableTextTextureRectForNode(candidate)).UTF8String);
    CHECK(commit==0 && candidate.preparedTextLayout.storage.length==16384 &&
        candidate.textDeclaredSelectionDecorations.count>0,"warm_scrolled_select_all_has_matching_visible_geometry");
    cjgui_internal_renderer_destroy(token);
    gSelectionProductionTargetBody=nil; gSelectionProductionTargetHeight=120.0;
    gSelectionProductionTargetY=130.0; gSelectionProductionTargetClipHeight=500.0;
}

int main(void) { @autoreleasepool {
    InstallSelectionLayoutCounter();
    id<MTLDevice> device=MTLCreateSystemDefaultDevice();if(!device)return 2;
    WarmSelectionPreservesScrolledGeometry(device);
    WholeSelectionIncludesClippedText(device);ChooseAndType(device,YES);ChooseAndType(device,NO);
    PresentationTextSelectAllFallsBackToActiveNode(device);
    RefusedFocusPreservesA(device);SameChoiceReentryAndMarkedInput(device);FinalizingCancelAndRealKey(device);
    NSString *longASCII=[[@"" stringByPaddingToLength:16384 withString:@"x" startingAtIndex:0] copy];
    LongBUsesPrivateWorkerGraph(device,longASCII,"16KiB_ASCII_finite_height_clipping_control",120.0,YES);
    LongBUsesPrivateWorkerGraph(device,longASCII,"16KiB_ASCII_full_paragraph_geometry",5000.0,NO);
    gSelectionProductionTargetKind=CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT;
    NSMutableString *multiline=[NSMutableString string];
    for (NSUInteger i=0;i<2048;i++) [multiline appendString:@"line\n"];
    LongBUsesPrivateWorkerGraph(device,multiline,"multiline_control_prepared_on_worker_before_install",120.0,NO);
    PreserveActiveLocalTextRefreshKeepsSelectionGeometry(device,10,10,YES,
        "preserve_empty_multiline_collapsed_selection_installs");
    PreserveActiveLocalTextRefreshKeepsSelectionGeometry(device,2,10,NO,
        "preserve_empty_multiline_noncollapsed_selection_installs");
#ifdef CJGUI_INTERNAL_TESTING
    CancelledBWorkerKeepsChargeUntilExit(device);
#endif
    fprintf(stderr,"selection_production failures=%d\n",failures);
    return failures?1:0;
} }

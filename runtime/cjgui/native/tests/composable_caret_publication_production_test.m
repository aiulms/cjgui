#define main existingSelectionPaintProductionMain
#import "composable_selection_transfer_paint_production_test.m"
#undef main

// Missing publication uses the previous production maintenance query, so the
// original RED measures real repeated TextKit calls, not an invented receipt.
#include <dlfcn.h>
typedef CjguiInternalRendererStatus (*CaretValueGetter)(uint64_t,uint64_t,uint64_t,int64_t,int64_t,uint32_t,const uint64_t *,uint64_t *,double *);

typedef struct { CaretValueGetter getter; uint64_t session,generation; int status; BOOL done; } CaretWorker;
static void *CaretReadWhileMainHeld(void *opaque) { @autoreleasepool {
    CaretWorker *w=opaque; uint64_t m[16]={0}; double r[8]={0};
    w->status=w->getter(w->session,w->generation,2,401,2,2,NULL,m,r);
    w->done=w->status==CJGUI_INTERNAL_RENDERER_OK && r[3]>0;
    return NULL;
} }

static void ActualReceiptIdentity(CJGuiInternalSession *ctx, uint64_t key[12], int64_t origin[16]) {
    CjguiInstalledRangeState *b=ctx.installedRangeBasis;
    key[0]=b.candidate.windowInstanceToken;key[1]=b.candidate.bindingEpoch;
    key[2]=b.candidate.contextEpoch;key[3]=b.candidate.mirrorRevision;
    key[4]=b.candidate.ownerVersion;key[5]=key[4];key[6]=ctx.selectionReceiptOwnerRevision;
    key[7]=1;key[8]=key[4];key[9]=key[6];
    key[10]=b.actualSelectionStart16;key[11]=b.actualSelectionEnd16;
    int64_t actual[16]={(int64_t)b.selectionTransferId,(int64_t)ctx.sessionGeneration,
        (int64_t)b.candidate.windowInstanceToken,(int64_t)b.candidate.bindingEpoch,
        (int64_t)b.candidate.installedSceneVersion,(int64_t)b.installedProjectionVersion,
        (int64_t)b.candidate.nodeId,b.candidate.resourceId,b.proxyNodeKind,
        (int64_t)b.proxyGeneration,(int64_t)b.selectionRevision,b.candidate.ownerVersion,
        ctx.selectionReceiptOwnerRevision,(int64_t)b.actualSelectionStart16,
        (int64_t)b.actualSelectionEnd16,1};
    memcpy(origin,actual,sizeof(actual));
}
static BOOL AdoptActualReceipt(CJGuiInternalSession *ctx) {
    CjguiInstalledRangeState *b=ctx.installedRangeBasis;uint8_t needs=0;
    return cjgui_internal_renderer_finish_selection_paint_publication(ctx.rendererSessionToken,
        b.selectionTransferId,ctx.sessionGeneration,b.candidate.bindingEpoch,b.proxyGeneration,
        b.selectionRevision,b.candidate.ownerVersion,38,1,&needs)==0;
}
static void ConfigureActualBackground(CJGuiInternalSession *ctx,uint64_t scene) {
    ctx.windowContentHost=ctx.window.contentView;
    ctx.windowOpaqueFallbackView=[[NSView alloc] initWithFrame:ctx.windowContentHost.bounds];
    ctx.windowOpaqueFallbackView.wantsLayer=YES;
    [ctx.windowContentHost addSubview:ctx.windowOpaqueFallbackView positioned:NSWindowBelow relativeTo:nil];
    CHECK(cjgui_internal_renderer_configure_composable_scene(ctx.rendererSessionToken,scene,3)==0 &&
        cjgui_internal_renderer_stage_window_background(ctx.rendererSessionToken,scene,0,1)==0,
        "origin_real_candidate_and_background");
}
static void TestActualInstalledOrigin(id<MTLDevice> device) {
    CJGuiInternalSession *ctx=ProductionFixture(device);
    CHECK(ctx && InstallSelectionOnSameAcceptedScene(ctx,2,2) && AdoptActualReceipt(ctx),
        "origin_ordinary_pointer_installation_and_owner_adoption_are_real");
    if(!ctx) return;
    uint64_t session=ctx.rendererSessionToken,key[12]={0};int64_t origin[16]={0};
    ActualReceiptIdentity(ctx,key,origin);ConfigureActualBackground(ctx,2);
    CHECK(cjgui_internal_renderer_stage_candidate_caret_identity(session,0,2,1,402,2,2,key,origin)==0,
        "origin_new_scene_freezes_actual_ordinary_completion");
    CHECK(ctx.stagedCaretProjection.originSnapshot!=nil,"origin_actual_receipt_attached_before_ordinary_scene_submit");
    // Exercise the same public staging entry with narrowly corrupted claims.
    const NSUInteger wrongKey[]={1,4,6};
    for(NSUInteger i=0;i<3;i++) {
        uint64_t bad[12];memcpy(bad,key,sizeof(bad));bad[wrongKey[i]]++;
        CHECK(cjgui_internal_renderer_stage_candidate_caret_identity(session,0,2,1,402,2,2,bad,origin)==0 &&
            !ctx.stagedCaretProjection.originSnapshot,"origin_wrong_binding_owner_or_revision_refused");
    }
    int64_t badOrigin[16];memcpy(badOrigin,origin,sizeof(badOrigin));badOrigin[14]++;
    CHECK(cjgui_internal_renderer_stage_candidate_caret_identity(session,0,2,1,402,2,2,key,badOrigin)==0 &&
        !ctx.stagedCaretProjection.originSnapshot,"origin_wrong_native_selection_span_refused");
    CHECK(cjgui_internal_renderer_stage_candidate_caret_identity(session,0,2,1,402,2,2,key,origin)==0 &&
        ctx.stagedCaretProjection.originSnapshot,"origin_valid_claim_restored_after_negative_controls");
    CjguiInternalRendererFrameObservation observation={0};
    CjguiInternalRendererStatus status=cjgui_internal_renderer_present_composable_scene(session,&observation);
    uint64_t meta[16]={0};double rect[8]={0};
    CHECK((status==0 || status==CJGUI_INTERNAL_RENDERER_READBACK_FAILED) &&
        cjgui_internal_renderer_accepted_caret_value(session,ctx.sessionGeneration,2,402,2,2,key,meta,rect)==0 &&
        meta[12]==(uint64_t)origin[0] && meta[13]==(uint64_t)origin[11] && meta[14]==(uint64_t)origin[10],
        "origin_ordinary_completion_links_current_accepted_layout");
    ctx.composableSceneOverlay.inputProxy.string=@"same-length-wrong-body";
    CHECK(cjgui_internal_renderer_stage_candidate_caret_identity(session,0,2,1,402,2,2,key,origin)==0 &&
        !ctx.stagedCaretProjection.originSnapshot,"origin_actual_proxy_body_mismatch_refused");
    CjguiReleaseSession(session);
}
static void TestActualInflightOrigin(id<MTLDevice> device) {
    CJGuiInternalSession *ctx=ProductionFixture(device);
    CHECK(ctx && InstallSelectionOnSameAcceptedScene(ctx,2,2) && AdoptActualReceipt(ctx),
        "origin_inflight_starts_with_actual_installation");
    if(!ctx)return;
    uint64_t key[12]={0};int64_t origin[16]={0};ActualReceiptIdentity(ctx,key,origin);
    ConfigureActualBackground(ctx,2);
    CHECK(cjgui_internal_renderer_stage_candidate_caret_identity(ctx.rendererSessionToken,0,2,1,402,2,2,key,origin)==0 &&
        ctx.stagedCaretProjection.originSnapshot,"origin_inflight_control_starts_valid");
    [ctx.composableSceneOverlay.inputProxy insertText:@"q" replacementRange:NSMakeRange(NSNotFound,0)];
    CHECK(cjgui_internal_renderer_stage_candidate_caret_identity(ctx.rendererSessionToken,0,2,1,402,2,2,key,origin)==0 &&
        !ctx.stagedCaretProjection.originSnapshot,"origin_real_inflight_input_cannot_borrow_old_receipt");
    CjguiReleaseSession(ctx.rendererSessionToken);
}
static void TestActualNewBOrigin(id<MTLDevice> device, BOOL reverse) {
    CJGuiInternalSession *ctx=ProductionFixture(device);
    CHECK(ctx && InstallSelectionOnSameAcceptedScene(ctx,2,2) && AdoptActualReceipt(ctx),
        "origin_newB_source_is_actual_A");
    if(!ctx) return;
    uint64_t session=ctx.rendererSessionToken,key[12]={0};int64_t oldOrigin[16]={0};
    ActualReceiptIdentity(ctx,key,oldOrigin);ConfigureActualBackground(ctx,2);
    CjguiInstalledRangeState *a=ctx.installedRangeBasis;
    CjguiInternalSelectionTransferReceipt source={0};
    source.transferId=a.selectionTransferId;source.sceneVersion=a.candidate.installedSceneVersion;
    source.bindingEpoch=a.candidate.bindingEpoch;source.nodeId=a.candidate.nodeId;
    source.projectionVersion=a.installedProjectionVersion;source.resourceId=a.candidate.resourceId;
    source.nodeKind=a.proxyNodeKind;source.selectionStart16=a.actualSelectionStart16;
    source.selectionEnd16=a.actualSelectionEnd16;source.proxyGeneration=a.proxyGeneration;
    source.selectionRevision=a.selectionRevision;source.firstResponder=1;
    CJGuiInternalComposableSceneNode *node=CjguiCloneComposableSceneNode(ctx,ctx.stagedComposableNodes[2],2,2);
    CjguiInternalRendererComposableNode raw=node.node;raw.nodeId=1013;raw.projectionVersion=2;node.node=raw;
    node.value=@"klmnop";ctx.stagedComposableNodes[2]=node;
    CHECK(CjguiPrepareComposableTextResources(ctx)==0,"origin_newB_actual_layout_prepared");
    uint64_t transfer=0;CHECK(cjgui_internal_renderer_selection_transfer_create(session,&transfer)==0,"origin_newB_transfer");
    NSData *body=[node.value dataUsingEncoding:NSUTF8StringEncoding];
    CjguiInternalSelectionTransferCandidate candidate={0};candidate.transferId=transfer;
    candidate.sourceWindowInstanceToken=a.candidate.windowInstanceToken;
    candidate.sourceOwnerVersion=a.candidate.ownerVersion;candidate.sourceAcceptedVersion=a.candidate.ownerVersion;
    candidate.targetNodeId=1013;candidate.targetResourceId=1;candidate.targetNodeKind=CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT;
    candidate.targetSceneVersion=2;candidate.targetAnchor16=reverse ? 4 : 2;candidate.targetFocus16=reverse ? 2 : 4;
    candidate.targetBodyUtf8=body.bytes;candidate.targetBodyUtf8Length=(uint32_t)body.length;
    uint8_t bytes[65536]={0},ready=0;
    CHECK(cjgui_internal_renderer_capture_candidate_selection(session,&candidate,&source,bytes,sizeof(bytes),4,2,38,0)==0 &&
        cjgui_internal_renderer_selection_transfer_publish_pending(session,transfer)==0 &&
        cjgui_internal_renderer_prepare_candidate_selection(session,transfer,0,&ready)==0 && ready,
        "origin_newB_prepares_without_installing");
    CjguiInstalledRangeState *future=ctx.selectionTransferCapsule.bInputBasis;
    key[1]=future.candidate.bindingEpoch;key[10]=candidate.targetAnchor16;key[11]=candidate.targetFocus16;
    int64_t focusByte=candidate.targetFocus16;
    CHECK(cjgui_internal_renderer_stage_candidate_caret_identity(session,0,2,1,1013,focusByte,2,key,NULL)==0,
        "origin_newB_only_frozen_semantic_before_actual_commit");
    uint64_t meta[16]={0};double rect[8]={0};
    CHECK(cjgui_internal_renderer_accepted_caret_value(session,ctx.sessionGeneration,2,1013,focusByte,2,key,meta,rect)!=0,
        "origin_newB_cannot_publish_during_preparation");
    CjguiInternalRendererFrameObservation observation={0};
    int status=cjgui_internal_renderer_present_composable_scene(session,&observation);
    int value=cjgui_internal_renderer_accepted_caret_value(session,ctx.sessionGeneration,2,1013,focusByte,2,key,meta,rect);
    fprintf(stderr,"ORIGIN_B_FACT status=%d value=%d actual_transfer=%llu observed_transfer=%llu owner=%llu native_revision=%llu\n",
        status,value,(unsigned long long)ctx.installedRangeBasis.selectionTransferId,(unsigned long long)meta[12],
        (unsigned long long)meta[13],(unsigned long long)meta[14]);
    CHECK((status==0 || status==CJGUI_INTERNAL_RENDERER_READBACK_FAILED) && value==0 &&
        meta[12]==transfer && meta[13]==(uint64_t)ctx.installedRangeBasis.candidate.ownerVersion &&
        meta[14]==ctx.installedRangeBasis.selectionRevision,
        "origin_newB_real_commit_publishes_actual_B_not_A");
    const int64_t *attached=ctx.acceptedCaretProjection.originReceipt.bytes;
    CHECK(attached && attached[13]==candidate.targetAnchor16 && attached[14]==candidate.targetFocus16,
        reverse ? "origin_newB_reverse_direction_preserved" : "origin_newB_forward_direction_preserved");
    CjguiReleaseSession(session);
}

typedef CjguiInternalRendererStatus (*AcceptedSelectionPainter)(uint64_t,uint64_t,uint64_t,uint64_t,
    int64_t,int64_t,int64_t,uint64_t,double,double,double,double,const char *,const uint64_t *);
static void TestActualAcceptedSelectionPaint(id<MTLDevice> device) {
    AcceptedSelectionPainter paint=(AcceptedSelectionPainter)dlsym(RTLD_DEFAULT,
        "cjgui_internal_renderer_stage_accepted_selection_decoration");
    CHECK(paint!=NULL,"accepted_selection_direct_paint_production_entry_exists");if(!paint)return;
    CJGuiInternalSession *ctx=ProductionFixture(device);
    CHECK(ctx && InstallSelectionOnSameAcceptedScene(ctx,2,2) && AdoptActualReceipt(ctx),
        "accepted_selection_starts_from_real_ordinary_receipt");if(!ctx)return;
    uint64_t key[12]={0};int64_t origin[16]={0};ActualReceiptIdentity(ctx,key,origin);
    uint64_t scene=ctx.composableSceneVersion,transfer=ctx.installedRangeBasis.selectionTransferId;
    uint64_t layouts=ctx.composableTextLayoutPreparationCount;
    CHECK(paint(ctx.rendererSessionToken,transfer,ctx.sessionGeneration,key[1],key[4],key[9],1,scene,
        .4,.6,.9,.5,"401:0:0;402:2:2",key)==0,"accepted_selection_uses_exact_current_layout_without_new_scene");
    uint64_t meta[16]={0};double rect[8]={0};
    CHECK(ctx.composableSceneVersion==scene && ctx.installedRangeBasis.selectionTransferId==transfer &&
        ctx.composableTextLayoutPreparationCount==layouts &&
        cjgui_internal_renderer_accepted_caret_value(ctx.rendererSessionToken,ctx.sessionGeneration,
        scene,402,2,2,key,meta,rect)==0 && meta[12]==transfer,
        "accepted_selection_publishes_current_caret_without_layout_or_installation");
    CHECK(paint(ctx.rendererSessionToken,transfer,ctx.sessionGeneration,key[1]+1,key[4],key[9],1,scene,
        .4,.6,.9,.5,"401:0:0;402:2:2",key)!=0,
        "accepted_selection_wrong_binding_refused");
    CHECK(paint(ctx.rendererSessionToken,transfer,ctx.sessionGeneration,key[1],key[4],key[9]+1,1,scene,
        .4,.6,.9,.5,"401:0:0;402:2:2",key)!=0,
        "accepted_selection_wrong_owner_revision_refused");
    CHECK(paint(ctx.rendererSessionToken,transfer,ctx.sessionGeneration,key[1],key[4],key[9],1,scene+1,
        .4,.6,.9,.5,"401:0:0;402:2:2",key)!=0,
        "accepted_selection_future_layout_refused");
    CHECK(paint(ctx.rendererSessionToken,transfer,ctx.sessionGeneration,key[1],key[4],key[9],1,scene,
        .4,.6,.9,.5,"9999:0:1;402:2:2",key)!=0 &&
        cjgui_internal_renderer_accepted_caret_value(ctx.rendererSessionToken,ctx.sessionGeneration,
        scene,402,2,2,key,meta,rect)==0,
        "accepted_selection_failed_batch_preserves_previous_paint");
    [ctx.composableSceneOverlay.inputProxy insertText:@"q" replacementRange:NSMakeRange(NSNotFound,0)];
    CHECK(paint(ctx.rendererSessionToken,transfer,ctx.sessionGeneration,key[1],key[4],key[9],1,scene,
        .4,.6,.9,.5,"401:0:0;402:2:2",key)!=0,
        "accepted_selection_inflight_input_cannot_borrow_old_source");
    CjguiReleaseSession(ctx.rendererSessionToken);
}

#ifndef CJGUI_CARET_PUBLICATION_FIXTURE_ONLY
int main(void) { @autoreleasepool {
    [NSApplication sharedApplication];
    id<MTLDevice> device=MTLCreateSystemDefaultDevice();
    TestActualAcceptedSelectionPaint(device);
    TestActualInstalledOrigin(device);
    TestActualInflightOrigin(device);
    TestActualNewBOrigin(device,NO);
    TestActualNewBOrigin(device,YES);
    CJGuiInternalSession *ctx=ProductionFixture(device);
    CHECK(ctx!=nil,"caret_publication_real_metal_fixture");
    if (!ctx) return 1;
    uint64_t session=ctx.rendererSessionToken;
    CHECK(cjgui_internal_renderer_configure_composable_scene(session,2,3)==CJGUI_INTERNAL_RENDERER_OK,
        "caret_publication_candidate_configured");
    ctx.windowContentHost=ctx.window.contentView;
    ctx.windowOpaqueFallbackView=[[NSView alloc] initWithFrame:ctx.windowContentHost.bounds];
    ctx.windowOpaqueFallbackView.wantsLayer=YES;
    [ctx.windowContentHost addSubview:ctx.windowOpaqueFallbackView positioned:NSWindowBelow relativeTo:nil];
    CHECK(cjgui_internal_renderer_stage_window_background(session,2,0,1)==CJGUI_INTERNAL_RENDERER_OK,
        "caret_publication_real_background_staged");
    CjguiInternalRendererFrameObservation observation={0};
    CHECK(cjgui_internal_renderer_stage_candidate_caret(session,0,2,1,401,2,2)==CJGUI_INTERNAL_RENDERER_OK,
        "caret_publication_real_candidate_staged");
    CjguiInternalRendererStatus presented=cjgui_internal_renderer_present_composable_scene(session,&observation);
    CHECK((presented==CJGUI_INTERNAL_RENDERER_OK || presented==CJGUI_INTERNAL_RENDERER_READBACK_FAILED) &&
        observation.frameIndex>0 && ctx.composableSceneVersion==2,
        "caret_publication_real_candidate_submitted_not_pixel_acceptance");
    fprintf(stderr,"CARET_FACT scene=%llu accepted=%p present=%d semantic=%d slot=%d node=%llu layout=%p frame=%llu\n",
        (unsigned long long)ctx.composableSceneVersion,ctx.acceptedCaretProjection,
        ctx.acceptedCaretProjection.present,ctx.acceptedCaretProjection.usesByteOffset,
        gCjguiAcceptedCaretValues[session-1].valid,(unsigned long long)gCjguiAcceptedCaretValues[session-1].node,
        ctx.view.composableNodes[0].preparedTextLayout,(unsigned long long)ctx.view.frameIndex);
    ctx.diagnosticTimingEnabled=YES;
    uint64_t count=ctx.positionQueryCount;
    CaretValueGetter getter=(CaretValueGetter)dlsym(RTLD_DEFAULT,"cjgui_internal_renderer_accepted_caret_value");
    if (getenv("CJGUI_CARET_WITHDRAW_VALUE")) getter=NULL;
    uint64_t meta[16]={0}; double rect[8]={0};
    for (NSUInteger i=0;i<32;i++) {
        CjguiInternalRendererStatus status;
        if (getter) {
            status=getter(session,ctx.sessionGeneration,2,401,2,2,NULL,meta,rect);
        } else {
            status=cjgui_internal_renderer_text_position_v1(session,401,2,0,2,2,0,0,0,0,0,meta,rect);
        }
        CHECK(status==CJGUI_INTERNAL_RENDERER_OK && rect[3]>0,"caret_publication_stable_geometry_real");
    }
    CHECK(ctx.positionQueryCount==count,"caret_maintenance_does_not_repeat_sync_position_query");
    if (getter) {
        CaretWorker work={getter,session,ctx.sessionGeneration,-1,NO}; pthread_t worker;
        CHECK(pthread_create(&worker,NULL,CaretReadWhileMainHeld,&work)==0,"caret_read_worker_created");
        pthread_join(worker,NULL); // main deliberately services no dispatch block
        CHECK(work.done,"caret_observation_completes_while_main_is_held");
        uint64_t key[12]={0};
        key[0]=9101;key[1]=ctx.ownedTextSessionBindingEpoch;
        key[4]=10;key[8]=10;key[9]=1;key[10]=2;key[11]=2;
        CHECK(cjgui_internal_renderer_configure_composable_scene(session,3,3)==0 &&
            cjgui_internal_renderer_stage_window_background(session,3,0,1)==0 &&
            cjgui_internal_renderer_stage_candidate_caret_identity(session,0,3,1,401,2,2,key,NULL)==0,
            "caret_new_identity_is_only_staged");
        CHECK(getter(session,ctx.sessionGeneration,3,401,2,2,key,meta,rect)==CJGUI_INTERNAL_RENDERER_SCENE_STALE,
            "caret_staged_identity_never_ready_before_submission");
        presented=cjgui_internal_renderer_present_composable_scene(session,&observation);
        CHECK((presented==0 || presented==CJGUI_INTERNAL_RENDERER_READBACK_FAILED) &&
            getter(session,ctx.sessionGeneration,3,401,2,2,key,meta,rect)==0,
            "caret_identity_published_by_actual_acceptance");
        for (NSUInteger i=0;i<12;i++) {
            uint64_t wrong[12];memcpy(wrong,key,sizeof(wrong));wrong[i]++;
            CHECK(getter(session,ctx.sessionGeneration,3,401,2,2,wrong,meta,rect)==CJGUI_INTERNAL_RENDERER_SCENE_STALE,
                "caret_old_owner_selection_binding_and_source_identity_refused");
        }
        CHECK(getter(session,ctx.sessionGeneration,3,401,2,0,key,meta,rect)==CJGUI_INTERNAL_RENDERER_SCENE_STALE,
            "caret_same_byte_different_affinity_not_aliased");
        CHECK(cjgui_internal_renderer_configure_composable_scene(session,4,3)==0 &&
            cjgui_internal_renderer_stage_window_background(session,4,0,1)==0 &&
            cjgui_internal_renderer_stage_candidate_caret_identity(session,0,4,1,401,999,2,key,NULL)==0,
            "caret_invalid_candidate_staged");
        CHECK(cjgui_internal_renderer_present_composable_scene(session,&observation)!=0 &&
            getter(session,ctx.sessionGeneration,3,401,2,2,key,meta,rect)==0 &&
            getter(session,ctx.sessionGeneration,4,401,999,2,key,meta,rect)!=0,
            "caret_rejected_candidate_keeps_only_original_fact");
        CHECK(cjgui_internal_renderer_configure_composable_scene(session,5,3)==0 &&
            cjgui_internal_renderer_stage_window_background(session,5,0,1)==0,
            "caret_wrapped_candidate_configured");
        CJGuiInternalComposableSceneNode *wrapped=CjguiCloneComposableSceneNode(ctx,ctx.stagedComposableNodes[0],0,5);
        CjguiInternalRendererComposableNode raw=wrapped.node;raw.width=60;wrapped.node=raw;
        wrapped.value=@"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMN";
        wrapped.preparedTextLayout=CjguiPrepareTextNodeLayout(wrapped,wrapped.value,1,nil,ctx);
        ctx.stagedComposableNodes[0]=wrapped;
        NSRange glyphs=[wrapped.preparedTextLayout.layoutManager lineFragmentUsedRectForGlyphAtIndex:0 effectiveRange:NULL].size.width>0
            ? NSMakeRange(0,1):NSMakeRange(0,0);
        [wrapped.preparedTextLayout.layoutManager lineFragmentRectForGlyphAtIndex:0 effectiveRange:&glyphs];
        NSRange characters=[wrapped.preparedTextLayout.layoutManager characterRangeForGlyphRange:glyphs actualGlyphRange:NULL];
        int64_t boundary=NSMaxRange(characters);key[10]=boundary;key[11]=boundary;
        CHECK(boundary>0 && boundary<(int64_t)wrapped.value.length &&
            cjgui_internal_renderer_stage_candidate_caret_identity(session,0,5,1,401,boundary,0,key,NULL)==0,
            "caret_real_soft_wrap_upstream_staged");
        presented=cjgui_internal_renderer_present_composable_scene(session,&observation);
        CHECK((presented==0 || presented==CJGUI_INTERNAL_RENDERER_READBACK_FAILED) &&
            getter(session,ctx.sessionGeneration,5,401,boundary,0,key,meta,rect)==0,
            "caret_real_soft_wrap_upstream_accepted");
        double upperY=rect[1];uint64_t upperStop=meta[6];
        CHECK(cjgui_internal_renderer_configure_composable_scene(session,6,3)==0 &&
            cjgui_internal_renderer_stage_window_background(session,6,0,1)==0 &&
            cjgui_internal_renderer_stage_candidate_caret_identity(session,0,6,1,401,boundary,1,key,NULL)==0,
            "caret_real_soft_wrap_downstream_staged");
        presented=cjgui_internal_renderer_present_composable_scene(session,&observation);
        CHECK((presented==0 || presented==CJGUI_INTERNAL_RENDERER_READBACK_FAILED) &&
            getter(session,ctx.sessionGeneration,6,401,boundary,1,key,meta,rect)==0 &&
            rect[1]>upperY && meta[6]!=upperStop &&
            getter(session,ctx.sessionGeneration,6,401,boundary,0,key,meta,rect)!=0,
            "caret_same_byte_two_real_wrap_positions_remain_distinct");
        ctx.view.frame=NSMakeRect(0,0,640,490);[ctx windowGeometryDidChange];
        CHECK(getter(session,ctx.sessionGeneration,6,401,boundary,1,key,meta,rect)!=0,
            "caret_real_resize_invalidates_previous_geometry_until_acceptance");
        CjguiInternalRendererEvent resizeEvent={0};
        CHECK(cjgui_internal_renderer_pump_event(session,0,&resizeEvent)==CJGUI_INTERNAL_RENDERER_OK &&
            resizeEvent.kind==CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_RESIZED,
            "caret_actual_resize_event_consumed_before_successor_submit");
        CHECK(cjgui_internal_renderer_configure_composable_scene(session,7,3)==0 &&
            cjgui_internal_renderer_stage_window_background(session,7,0,1)==0,
            "caret_transform_successor_configured");
        wrapped=CjguiCloneComposableSceneNode(ctx,ctx.stagedComposableNodes[0],0,7);
        raw=wrapped.node;raw.y+=30;wrapped.node=raw;ctx.stagedComposableNodes[0]=wrapped;
        CHECK(cjgui_internal_renderer_stage_candidate_caret_identity(session,0,7,1,401,boundary,1,key,NULL)==0,
            "caret_same_source_new_transform_staged");
        presented=cjgui_internal_renderer_present_composable_scene(session,&observation);
        int transformStatus=getter(session,ctx.sessionGeneration,7,401,boundary,1,key,meta,rect);
        CjguiAcceptedCaretValue transformed=gCjguiAcceptedCaretValues[session-1];
        fprintf(stderr,"CARET_TRANSFORM status=%d presented=%d y=%g upper=%g resize=%llu observed=%llu "
            "valid=%d fact_scene=%llu fact_node=%llu fact_byte=%llu expected_byte=%lld fact_affinity=%llu fact_resize=%llu current_scene=%llu\n",
            transformStatus,presented,rect[1],upperY,(unsigned long long)meta[8],(unsigned long long)ctx.resizeVersion,
            transformed.valid,(unsigned long long)transformed.scene,(unsigned long long)transformed.node,
            (unsigned long long)transformed.byte,(long long)boundary,(unsigned long long)transformed.affinity,
            (unsigned long long)transformed.resize,(unsigned long long)ctx.composableSceneVersion);
        CHECK((presented==0 || presented==CJGUI_INTERNAL_RENDERER_READBACK_FAILED) &&
            transformStatus==0 && rect[1]>upperY+30,
            "caret_new_transform_uses_actual_successor_geometry");
        [ctx windowDidResignKey:nil];
        CHECK(getter(session,ctx.sessionGeneration,7,401,boundary,1,key,meta,rect)!=0,
            "caret_real_focus_loss_invalidates_observation");
        uint64_t generation=ctx.sessionGeneration;
        CjguiReleaseSession(session);
        CHECK(getter(session,generation,7,401,boundary,1,key,meta,rect)!=0,
            "caret_late_read_after_close_cannot_borrow_slot");
    } else { CjguiReleaseSession(session); }
    return failures?1:0;
} }
#endif

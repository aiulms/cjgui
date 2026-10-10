// Reuse the real Metal/AppKit production fixture. This test deliberately has
// no CJGUI_INTERNAL_TESTING renderer and no synthetic installed receipt.
#define main existingSelectionPaintProductionMain
#import "composable_selection_transfer_paint_production_test.m"
#undef main

// A real insertText re-enters while the renderer is preparing a command
// buffer, before GPU commit. No fabricated input payload or test renderer.
@interface CandidateReentrantQueue : NSObject
@property(nonatomic,strong) id<MTLCommandQueue> queue;
@property(nonatomic,strong) CJGuiInternalSession *ctx;
@property(nonatomic,assign) BOOL fired;
@end
@implementation CandidateReentrantQueue
- (id<MTLCommandBuffer>)commandBuffer {
    if (!self.fired) {
        self.fired=YES;
        [self.ctx.composableSceneOverlay.inputProxy insertText:@"Z" replacementRange:NSMakeRange(NSNotFound,0)];
    }
    return [self.queue commandBuffer];
}
@end

#ifdef CJGUI_INTERNAL_TESTING
typedef struct {
    uint64_t session, scene, transfer, ticket;
    CjguiInternalRendererStatus receiptStatus, ackStatus;
    CjguiInternalSelectionTransferReceipt receipt;
} CandidateReceiptAckWorker;
static void *CandidateReadReceiptAndAck(void *opaque) {
    @autoreleasepool {
        CandidateReceiptAckWorker *work=opaque;
        work->receiptStatus=cjgui_internal_renderer_candidate_selection_receipt(
            work->session,work->scene,work->transfer,&work->receipt);
        work->ackStatus=cjgui_internal_renderer_acknowledge_present(work->session,work->ticket);
    }
    return NULL;
}
#endif

static void TestCandidateCaretKeepsLayoutOutsideClip(id<MTLDevice> device) {
    CJGuiInternalSession *ctx=ProductionFixture(device);
    CHECK(ctx!=nil,"candidate_clipped_caret_fixture_has_owned_session");
    if (!ctx) return;
    uint64_t token=ctx.rendererSessionToken;
    CHECK(cjgui_internal_renderer_configure_composable_scene(token,2,3)==CJGUI_INTERNAL_RENDERER_OK,
        "candidate_clipped_caret_scene_configured");
    CJGuiInternalComposableSceneNode *target=CjguiCloneComposableSceneNode(ctx,ctx.stagedComposableNodes[2],2,2);
    CjguiInternalRendererComposableNode raw=target.node; raw.width=80; raw.clipHeight=280;
    target.node=raw; target.value=@"abcdefghijklmnopqrstuvwxABCDEFGHIJKL";
    ctx.stagedComposableNodes[2]=target;
    int64_t byte=[target.value lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
    CHECK(cjgui_internal_renderer_stage_candidate_caret(token,0,2,1,403,byte,2)==CJGUI_INTERNAL_RENDERER_OK &&
        CjguiCommitComposableSceneOnMain(token)==CJGUI_INTERNAL_RENDERER_OK,
        "candidate_clipped_caret_uses_own_prepared_layout");
    target=ctx.view.composableNodes[2]; NSRect local=NSZeroRect;
    CHECK(CjguiCandidateCaretRect(target,byte,2,&local)==CJGUI_INTERNAL_RENDERER_OK && !NSIsEmptyRect(local),
        "candidate_clipped_caret_has_real_local_layout_geometry");
    NSRect origin=CjguiComposableVisualNodeRect(target);
    NSRect expected=NSOffsetRect(local,origin.origin.x,origin.origin.y);
    CHECK(target.textCaretIsDeclared && NSEqualRects(target.textCaretRect,expected) &&
        NSIsEmptyRect(NSIntersectionRect(expected,CjguiComposableVisualClipBounds(target))),
        "candidate_raw_caret_keeps_layout_geometry_while_paint_is_clipped");
    CjguiReleaseSession(token);
}

static void TestPrivateCandidateTarget(id<MTLDevice> device, NSInteger mode) {
    CJGuiInternalSession *ctx=ProductionFixture(device);
    CHECK(ctx && InstallSelectionOnSameAcceptedScene(ctx,1,4),"candidate_source_is_real_installed_B");
    if (!ctx || !ctx.installedRangeBasis.hasReceipt) return;
    ctx.windowContentHost=ctx.window.contentView;
    ctx.windowOpaqueFallbackView=[[NSView alloc] initWithFrame:ctx.windowContentHost.bounds];
    ctx.windowOpaqueFallbackView.wantsLayer=YES;
    [ctx.windowContentHost addSubview:ctx.windowOpaqueFallbackView positioned:NSWindowBelow relativeTo:nil];
    uint64_t token=ctx.rendererSessionToken;
    CjguiInstalledRangeState *basis=ctx.installedRangeBasis;
    CjguiInternalSelectionTransferReceipt source={0};
    source.transferId=basis.selectionTransferId; source.sceneVersion=basis.candidate.installedSceneVersion;
    source.bindingEpoch=basis.candidate.bindingEpoch; source.nodeId=basis.candidate.nodeId;
    source.projectionVersion=ctx.composableSceneOverlay.activeProjectionVersion;
    source.resourceId=basis.candidate.resourceId; source.nodeKind=basis.proxyNodeKind;
    source.selectionStart16=basis.actualSelectionStart16; source.selectionEnd16=basis.actualSelectionEnd16;
    source.proxyGeneration=basis.proxyGeneration; source.selectionRevision=basis.selectionRevision; source.firstResponder=1;
    uint8_t needs=0;
    CHECK(cjgui_internal_renderer_finish_selection_paint_publication(token,source.transferId,
        ctx.sessionGeneration,source.bindingEpoch,source.proxyGeneration,source.selectionRevision,
        basis.candidate.ownerVersion,38,1,&needs)==CJGUI_INTERNAL_RENDERER_OK,"candidate_owner_adopts_actual_source_receipt");
    NSTextView *oldProxy=ctx.composableSceneOverlay.inputProxy;
    NSString *oldBody=[oldProxy.string copy]; NSRange oldRange=oldProxy.selectedRange;
    CHECK(cjgui_internal_renderer_configure_composable_scene(token,2,3)==CJGUI_INTERNAL_RENDERER_OK,
        "candidate_future_scene_configured");
    ctx.stagedComposableDataTransferVersion=2;
    CHECK(cjgui_internal_renderer_stage_window_background(token,2,0,1)==CJGUI_INTERNAL_RENDERER_OK,
        "candidate_real_background_staged");
    CJGuiInternalComposableSceneNode *node=CjguiCloneComposableSceneNode(ctx,ctx.stagedComposableNodes[2],2,2);
    CjguiInternalRendererComposableNode raw=node.node; raw.nodeId=1013; raw.projectionVersion=2;
    node.node=raw; node.value=@"中文😀new"; ctx.stagedComposableNodes[2]=node;
    CHECK(CjguiPrepareComposableTextResources(ctx)==CJGUI_INTERNAL_RENDERER_OK,
        "candidate_new_target_owns_prepared_layout");
    uint64_t transfer=0;
    CHECK(cjgui_internal_renderer_selection_transfer_create(token,&transfer)==CJGUI_INTERNAL_RENDERER_OK,
        "candidate_transfer_created");
    CjguiInternalSelectionTransferCandidate candidate={0};
    candidate.transferId=transfer; candidate.sourceWindowInstanceToken=basis.candidate.windowInstanceToken;
    candidate.sourceOwnerVersion=basis.candidate.ownerVersion; candidate.sourceAcceptedVersion=basis.candidate.ownerVersion;
    candidate.targetNodeId=1013; candidate.targetResourceId=1; candidate.targetNodeKind=raw.nodeKind;
    candidate.targetSceneVersion=2; candidate.targetAnchor16=2; candidate.targetFocus16=4;
    NSData *body=[node.value dataUsingEncoding:NSUTF8StringEncoding];
    candidate.targetBodyUtf8=body.bytes; candidate.targetBodyUtf8Length=(uint32_t)body.length;
    uint8_t actual[65536]={0};
    CjguiInternalSelectionTransferReceipt wrong=source; wrong.transferId++;
    CHECK(cjgui_internal_renderer_capture_candidate_selection(token,&candidate,&wrong,actual,sizeof(actual),5,7,38,0)
        ==CJGUI_INTERNAL_RENDERER_SCENE_STALE,"candidate_rejects_wrong_source_receipt");
    CHECK(cjgui_internal_renderer_capture_candidate_selection(token,&candidate,&source,actual,sizeof(actual),5,7,38,0)
        ==CJGUI_INTERNAL_RENDERER_OK,"candidate_captures_actual_A_for_different_future_target");
    CHECK(candidate.sourceNodeId==402 && candidate.targetNodeId==1013 && candidate.sourceSceneVersion==1 &&
        candidate.targetSceneVersion==2,"candidate_source_and_target_identities_stay_separate");
    CHECK(cjgui_internal_renderer_selection_transfer_publish_pending(token,transfer)==CJGUI_INTERNAL_RENDERER_OK,
        "candidate_private_transfer_pending");
    uint8_t ready=0;
    CHECK(cjgui_internal_renderer_prepare_candidate_selection(token,transfer,0,&ready)==CJGUI_INTERNAL_RENDERER_OK && ready,
        "candidate_real_private_B_setter_readback_and_geometry_ready");
    CHECK(ctx.composableSceneOverlay.inputProxy==oldProxy && ctx.installedRangeBasis==basis &&
        [oldProxy.string isEqualToString:oldBody] && NSEqualRanges(oldProxy.selectedRange,oldRange) &&
        ctx.composableSceneOverlay.activeNodeId==402 && ctx.composableSceneVersion==1,
        "candidate_private_preparation_leaves_entire_A_live");
    CjguiInternalSelectionTransferReceipt absent={0};
    CHECK(cjgui_internal_renderer_candidate_selection_receipt(token,2,transfer,&absent)==CJGUI_INTERNAL_RENDERER_SCENE_STALE &&
        !absent.transferId,"candidate_preparation_cannot_export_installed_receipt");
    CjguiInternalRendererFrameObservation observation={0};
#ifdef CJGUI_INTERNAL_TESTING
    if (mode==3 || mode==4) {
        CHECK(cjgui_internal_renderer_test_hold_next_composable_present(token)==CJGUI_INTERNAL_RENDERER_OK &&
            CjguiPresentComposableSceneOnMain(token,&observation)==CJGUI_INTERNAL_RENDERER_PRESENT_PENDING &&
            observation.ticketId && ctx.composableSceneVersion==1 &&
            ctx.composableSceneOverlay.inputProxy==oldProxy,
            "candidate_PENDING_keeps_original_A_and_original_present_ticket");
        uint64_t ticket=observation.ticketId;
        CjguiInternalRendererPresentReceipt terminal={0};
        CHECK(cjgui_internal_renderer_query_present(token,ticket,&terminal)==CJGUI_INTERNAL_RENDERER_OK &&
            terminal.ticketId==ticket && !terminal.settled &&
            cjgui_internal_renderer_candidate_selection_receipt(token,2,transfer,&absent)==CJGUI_INTERNAL_RENDERER_SCENE_STALE,
            "candidate_PENDING_query_cannot_publish_installation");
        if (mode==3) {
            CHECK(cjgui_internal_renderer_selection_transfer_request_cancel(token,transfer)==CJGUI_INTERNAL_RENDERER_OK &&
                cjgui_internal_renderer_test_resolve_pending_composable_present(token)==CJGUI_INTERNAL_RENDERER_SCENE_STALE &&
                cjgui_internal_renderer_query_present(token,ticket,&terminal)==CJGUI_INTERNAL_RENDERER_OK &&
                terminal.settled && terminal.decision==CJGUI_INTERNAL_RENDERER_PRESENT_DECISION_REJECTED &&
                terminal.ticketId==ticket && ctx.composableSceneVersion==1 &&
                ctx.composableSceneOverlay.inputProxy==oldProxy && [oldProxy.string isEqualToString:oldBody] &&
                cjgui_internal_renderer_candidate_selection_receipt(token,2,transfer,&absent)==CJGUI_INTERNAL_RENDERER_SCENE_STALE,
                "candidate_PENDING_cancel_rejects_original_ticket_and_preserves_A");
            CHECK(cjgui_internal_renderer_acknowledge_present(token,ticket)==CJGUI_INTERNAL_RENDERER_OK &&
                ctx.testComposableTicketAckCount==1,"candidate_PENDING_rejection_ACK_only_once");
        } else {
            CjguiInternalRendererStatus settled=cjgui_internal_renderer_test_resolve_pending_composable_present(token);
            CHECK((settled==CJGUI_INTERNAL_RENDERER_OK || settled==CJGUI_INTERNAL_RENDERER_READBACK_FAILED) &&
                cjgui_internal_renderer_query_present(token,ticket,&terminal)==CJGUI_INTERNAL_RENDERER_OK &&
                terminal.settled && terminal.decision==CJGUI_INTERNAL_RENDERER_PRESENT_DECISION_ACCEPTED &&
                terminal.ticketId==ticket && ctx.composableSceneVersion==2 &&
                ctx.composableSceneOverlay.activeNodeId==1013,
                "candidate_PENDING_accepts_same_prepared_target_on_original_ticket");
            uint64_t frame=ctx.view.frameIndex;
            CandidateReceiptAckWorker work={.session=token,.scene=2,.transfer=transfer,.ticket=ticket};
            BOOL dispatchWasEnabled=gCjguiMainThreadDispatchEnabled;
            gCjguiMainThreadDispatchEnabled=NO;
            pthread_t worker; int created=pthread_create(&worker,NULL,CandidateReadReceiptAndAck,&work);
            CHECK(created==0,"candidate_ACK_transport_failure_worker_created");
            if (!created) pthread_join(worker,NULL);
            gCjguiMainThreadDispatchEnabled=dispatchWasEnabled;
            CHECK(!created && work.receiptStatus==CJGUI_INTERNAL_RENDERER_OK &&
                work.receipt.transferId==transfer && work.receipt.nodeId==1013 &&
                work.ackStatus==CJGUI_INTERNAL_RENDERER_NOT_MAIN_THREAD &&
                ctx.testPendingComposableTicket==ticket && ctx.testComposableTicketAckCount==0 &&
                ctx.view.frameIndex==frame && [ctx.composableSceneOverlay.inputProxy.string isEqualToString:node.value],
                "candidate_real_terminal_receipt_survives_failed_original_ACK_transport");
            CHECK(cjgui_internal_renderer_acknowledge_present(token,ticket)==CJGUI_INTERNAL_RENDERER_OK &&
                ctx.testComposableTicketAckCount==1 && ctx.testPendingComposableTicket==0 &&
                ctx.view.frameIndex==frame &&
                cjgui_internal_renderer_candidate_selection_receipt(token,2,transfer,&absent)==CJGUI_INTERNAL_RENDERER_OK &&
                absent.proxyGeneration==work.receipt.proxyGeneration,
                "candidate_ACK_retry_confirms_only_without_present_or_input_replay");
        }
    } else
#endif
    if (mode==1) {
        CHECK(cjgui_internal_renderer_selection_transfer_request_cancel(token,transfer)==CJGUI_INTERNAL_RENDERER_OK,
            "candidate_can_cancel_before_present");
        CHECK(CjguiPresentComposableSceneOnMain(token,&observation)==CJGUI_INTERNAL_RENDERER_SCENE_STALE &&
            ctx.composableSceneOverlay.inputProxy==oldProxy && ctx.installedRangeBasis==basis &&
            ctx.composableSceneVersion==1 && [oldProxy.string isEqualToString:oldBody] &&
            cjgui_internal_renderer_candidate_selection_receipt(token,2,transfer,&absent)==CJGUI_INTERNAL_RENDERER_SCENE_STALE,
            "candidate_cancel_source_gate_preserves_A_and_exports_no_new_receipt");
    } else if (mode==2) {
        CandidateReentrantQueue *queue=[CandidateReentrantQueue new];
        queue.queue=ctx.view.commandQueue; queue.ctx=ctx;
        ctx.view.commandQueue=(id<MTLCommandQueue>)queue;
        uint64_t oldFrame=ctx.view.frameIndex;
        CjguiInternalRendererStatus presented=CjguiPresentComposableSceneOnMain(token,&observation);
        CHECK(queue.fired && presented==CJGUI_INTERNAL_RENDERER_SCENE_STALE && ctx.view.frameIndex==oldFrame &&
            ctx.composableSceneVersion==1 && ctx.composableSceneOverlay.inputProxy==oldProxy &&
            [oldProxy.string isEqualToString:oldBody] && ctx.selectionTransferCapsule.retainedInputs.count==1,
            "candidate_reentrant_original_input_aborts_before_GPU_commit_and_keeps_A");
        CHECK(cjgui_internal_renderer_selection_transfer_replay_input(token,transfer)==CJGUI_INTERNAL_RENDERER_OK &&
            ctx.composableSceneOverlay.inputProxy==oldProxy && [oldProxy.string isEqualToString:@"FZJ"] &&
            !ctx.selectionTransferCapsule &&
            cjgui_internal_renderer_candidate_selection_receipt(token,2,transfer,&absent)==CJGUI_INTERNAL_RENDERER_SCENE_STALE,
            "candidate_abort_consumes_original_A_input_once_without_new_coordinates");
        ctx.view.commandQueue=queue.queue;
    } else {
        CjguiInternalRendererStatus presented=CjguiPresentComposableSceneOnMain(token,&observation);
        fprintf(stderr,"candidate actual present status=%u scene=%llu target=%llu frame=%llu\n",presented,
            ctx.composableSceneVersion,ctx.composableSceneOverlay.activeNodeId,ctx.view.frameIndex);
        CHECK((presented==CJGUI_INTERNAL_RENDERER_OK || presented==CJGUI_INTERNAL_RENDERER_READBACK_FAILED) &&
            ctx.composableSceneVersion==2 && ctx.composableSceneOverlay.activeNodeId==1013 &&
            ctx.composableSceneOverlay.inputProxy!=oldProxy &&
            [ctx.composableSceneOverlay.inputProxy.string isEqualToString:node.value] &&
            NSEqualRanges(ctx.composableSceneOverlay.inputProxy.selectedRange,NSMakeRange(2,2)),
            "candidate_actual_present_moves_prepared_B_and_keeps_exact_range");
        CHECK(cjgui_internal_renderer_candidate_selection_receipt(token,2,transfer,&absent)==CJGUI_INTERNAL_RENDERER_OK &&
            absent.transferId==transfer && absent.nodeId==1013 && absent.sceneVersion==2 &&
            absent.proxyGeneration!=source.proxyGeneration && absent.firstResponder==1 &&
            source.nodeId==402 && source.sceneVersion==1,
            "candidate_success_exports_real_successor_without_resigning_old_receipt");
        CHECK(cjgui_internal_renderer_selection_transfer_discard_capsule(token,transfer)==CJGUI_INTERNAL_RENDERER_OK,
            "candidate_success_retires_private_capsule");
    }
    CjguiReleaseSession(token);
}

#ifndef CJGUI_CANDIDATE_NO_MAIN
int main(void) {
    @autoreleasepool {
        id<MTLDevice> device = MTLCreateSystemDefaultDevice();
        if (!device) return 77;
        CJGuiInternalSession *ctx = ProductionFixture(device);
        if (!ctx) return 1;
        uint64_t token = ctx.rendererSessionToken;
        CJGuiInternalComposableSceneOverlay *overlay = ctx.composableSceneOverlay;
        overlay.hasDeclaredInputCaret = YES;
        overlay.declaredInputCaretNodeId = 403;
        overlay.declaredInputCaretRect = NSMakeRect(34, 4, 1.5, 18);
        CHECK(cjgui_internal_renderer_configure_composable_scene(token, 2, 3) ==
            CJGUI_INTERNAL_RENDERER_OK, "candidate_freezes_old_accepted_caret");
        // The still accepted frame may redraw/withdraw its own caret while B
        // is being prepared. That live change must not alter B's frozen input.
        overlay.hasDeclaredInputCaret = NO;
        CHECK(CjguiCommitComposableSceneOnMain(token) == CJGUI_INTERNAL_RENDERER_OK,
            "candidate_prepares_after_accepted_redraw");
        CJGuiInternalComposableSceneNode *candidate = ctx.view.composableNodes[2];
        CHECK(candidate.textCaretIsDeclared && !NSIsEmptyRect(candidate.textCaretRect),
            "candidate_caret_survives_live_withdrawal");
        CjguiReleaseSession(token);
        TestPrivateCandidateTarget(device,1);
        TestPrivateCandidateTarget(device,0);
        TestPrivateCandidateTarget(device,2);
        TestCandidateCaretKeepsLayoutOutsideClip(device);
        fprintf(stderr, "candidate projection failures=%d\n", failures);
        return failures ? 1 : 0;
    }
}
#endif

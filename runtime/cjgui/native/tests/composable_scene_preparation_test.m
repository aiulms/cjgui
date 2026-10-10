#define CJGUI_INTERNAL_TESTING 1
#import "../cjgui_internal_renderer.m"

// This window is never ordered onto the desktop. All resources and source
// proofs are the actual production TextKit/Metal objects, not fake rasters.
@interface PrepWindow : NSWindow
@property(nonatomic, strong) NSResponder *recordedResponder;
@end
@implementation PrepWindow
- (NSResponder *)firstResponder { return self.recordedResponder; }
- (BOOL)makeFirstResponder:(NSResponder *)r { self.recordedResponder=r; return YES; }
- (BOOL)isKeyWindow { return NO; }
- (BOOL)isVisible { return NO; }
- (CGFloat)backingScaleFactor { return 2; }
@end
@interface PrepOverlay : CJGuiInternalComposableSceneOverlay
@property(nonatomic, strong) PrepWindow *recordedWindow;
@end
@implementation PrepOverlay
- (NSWindow *)window { return self.recordedWindow; }
@end
static int failures;
#define CHECK(c,label) do { BOOL ok=(c); fprintf(stderr,"scene_preparation case=%s result=%s\n",label,ok?"PASS":"FAIL"); if(!ok) failures++; } while(0)
static CjguiInternalRendererStatus Fill(uint64_t token,uint64_t id,uint64_t version,NSString *body) {
    CjguiInternalRendererComposableNode n={0};
    n.nodeId=501; n.resourceId=1; n.projectionVersion=version;
    n.nodeKind=CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT;
    n.isInteractive=1; n.width=680; n.height=915; n.clipWidth=680; n.clipHeight=689;
    n.fontSize=18; n.fontWeight=400; n.textAlpha=1;
    CjguiInternalRendererComposableGeometry g={0}; g.nodeId=501;
    return cjgui_internal_renderer_prepare_composable_node(token,id,0,&n,&g,"",body.UTF8String,
        "ordinary-input","binding-501","","","ordinary input","");
}
static CjguiInternalRendererStatus FillStatic(uint64_t token,uint64_t id,uint64_t version) {
    CjguiInternalRendererComposableNode n={0};
    n.nodeId=777; n.resourceId=7; n.projectionVersion=version;
    n.nodeKind=CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT;
    n.width=300; n.height=45; n.clipWidth=300; n.clipHeight=45;
    n.fontSize=18; n.fontWeight=400; n.textAlpha=1;
    CjguiInternalRendererComposableGeometry g={0}; g.nodeId=777;
    return cjgui_internal_renderer_prepare_composable_node(token,id,0,&n,&g,"","new static text",
        "static-selection","binding-777","","","static selection","");
}
static CjguiInternalRendererStatus Finish(uint64_t token,uint64_t id) {
    uint32_t ready=0; CjguiInternalRendererStatus st=0;
    for(NSUInteger i=0;i<80&&!ready;i++) {
        st=cjgui_internal_renderer_advance_composable_preparation(token,id,0,&ready);
        if(st) return st;
    }
    return ready?st:CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
}
static int RunSelectionClipRegression(CJGuiInternalSession *ctx) {
    CJGuiInternalComposableSceneNode *candidate=[CJGuiInternalComposableSceneNode new];
    CjguiInternalRendererComposableNode raw={0};
    raw.nodeId=902; raw.resourceId=9; raw.projectionVersion=2;
    raw.nodeKind=CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT;
    raw.x=0; raw.y=-40; raw.width=300; raw.height=45;
    raw.clipX=0; raw.clipY=0; raw.clipWidth=300; raw.clipHeight=45;
    raw.fontSize=18; raw.fontWeight=400; raw.textAlpha=1;
    CjguiInternalRendererComposableGeometry geometry={0}; geometry.nodeId=902;
    candidate.node=raw; candidate.geometry=geometry; candidate.value=@"short text";
    candidate.semanticId=@"clipped-selection";
    NSString *wire=@"0:10:18:400:0:0:0:0:1:1:0.2:0.4:0.8:0.45:1";
    NSArray *accepted=ctx.composableNodes;
    NSArray *previousStaged=ctx.stagedComposableNodes;
    uint64_t previousStagedVersion=ctx.stagedComposableSceneVersion;
    NSMutableDictionary *previousRuns=ctx.composableTextStyleRunsRaw;
    ctx.stagedComposableNodes=[NSMutableArray arrayWithObject:candidate];
    ctx.stagedComposableSceneVersion=2;
    ctx.composableTextStyleRunsRaw=[@{@(raw.nodeId):wire} mutableCopy];
    NSRect borderIntersection=NSIntersectionRect(CjguiComposableVisualNodeRect(candidate),
        CjguiComposableVisualClipBounds(candidate));
    NSRect glyphCoverage=CjguiComposableTextTextureRectForNodeWithText(candidate,candidate.value);
    CjguiInternalRendererStatus status=CjguiPrepareComposableTextResources(ctx);
    NSString *preparedBody=candidate.preparedTextLayout.storage.string ?: @"<nil>";
    fprintf(stderr,"selection_clip_RED node=%llu status=%d node_y=%lld node_h=%lld clip_y=%lld clip_h=%lld "
        "border=%0.2fx%0.2f glyph_coverage=%0.2fx%0.2f prepared_body=%s expected_status=0\n",
        (unsigned long long)raw.nodeId,status,(long long)raw.y,(long long)raw.height,
        (long long)raw.clipY,(long long)raw.clipHeight,(double)NSWidth(borderIntersection),
        (double)NSHeight(borderIntersection),(double)NSWidth(glyphCoverage),(double)NSHeight(glyphCoverage),
        preparedBody.UTF8String ?: "<utf8-nil>");
    CHECK(!NSIsEmptyRect(borderIntersection) && NSIsEmptyRect(glyphCoverage),
        "clip_regression_border_visible_glyph_coverage_empty");
    CHECK(status==CJGUI_INTERNAL_RENDERER_OK,
        "clip_regression_must_not_reject_unpaintable_selection_geometry");
    CHECK(candidate.preparedTextLayout && candidate.preparedTextLayout.storage.length==0,
        "clip_regression_records_actual_empty_prepared_body");
    CHECK(ctx.composableNodes==accepted,"clip_regression_candidate_does_not_mutate_accepted_scene");

    uint64_t visibilityExtentCount=candidate.testTextExtentMeasurementCount;
    CjguiAcceptedTextVisibility clippedVisibility=CjguiAcceptedTextVisibilityForNode(candidate,
        NSMakeRect(0,0,680,689));
    NSRect candidateVisualRect=CjguiComposableVisualNodeRect(candidate);
    NSRect expectedUnclippedTextRect=NSOffsetRect(candidate.preparedTextLayout.textRect,
        NSMinX(candidateVisualRect),NSMinY(candidateVisualRect));
    NSRect existingCoverage=CjguiComposableTextTextureRectForNodeWithText(candidate,candidate.value);
    fprintf(stderr,"selection_clip_visibility_RED available=%d empty=%d reason=%s text_rect="
        "%0.2f,%0.2f,%0.2f,%0.2f expected_layout_rect=%0.2f,%0.2f,%0.2f,%0.2f "
        "extent_count=%llu->%llu memo_valid=%d memo_body=%d coverage=%0.2fx%0.2f textures=%lu bytes=%llu\n",
        (int)clippedVisibility.available,(int)clippedVisibility.empty,clippedVisibility.reason,
        NSMinX(clippedVisibility.textRect),NSMinY(clippedVisibility.textRect),
        NSWidth(clippedVisibility.textRect),NSHeight(clippedVisibility.textRect),
        NSMinX(expectedUnclippedTextRect),NSMinY(expectedUnclippedTextRect),
        NSWidth(expectedUnclippedTextRect),NSHeight(expectedUnclippedTextRect),
        (unsigned long long)visibilityExtentCount,
        (unsigned long long)candidate.testTextExtentMeasurementCount,(int)candidate.textMeasureValid,
        (int)[candidate.textMeasuredSource isEqualToString:candidate.value],
        (double)NSWidth(existingCoverage),(double)NSHeight(existingCoverage),
        (unsigned long)candidate.textTileTextures.count,(unsigned long long)candidate.textTextureByteCount);
    CHECK(NSIsEmptyRect(existingCoverage) && clippedVisibility.available && clippedVisibility.empty &&
        strcmp(clippedVisibility.reason,"empty_gpu_coverage")==0,
        "clip_regression_empty_gpu_coverage_is_available_empty_visibility");
    CHECK(candidate.testTextExtentMeasurementCount==visibilityExtentCount,
        "clip_regression_visibility_query_does_not_measure_extent");
    CHECK(NSEqualRects(clippedVisibility.textRect,expectedUnclippedTextRect),
        "clip_regression_empty_visibility_keeps_unclipped_native_layout_rect");

    CJGuiInternalComposableSceneNode *visibleWithoutLayout=[CJGuiInternalComposableSceneNode new];
    raw.y=0; visibleWithoutLayout.node=raw; visibleWithoutLayout.geometry=geometry;
    visibleWithoutLayout.value=@"short text";
    NSData *decoded=CjguiComposableDecodeStyleRuns(wire);
    NSRect visibleCoverage=CjguiComposableTextTextureRectForNodeWithText(visibleWithoutLayout,
        visibleWithoutLayout.value);
    CHECK(!NSIsEmptyRect(visibleCoverage) &&
        CjguiComposableDeclaredSelectionDecorations(visibleWithoutLayout,decoded)==nil,
        "visible_selection_without_matching_layout_still_refuses");

    CJGuiInternalComposableSceneNode *visibleBodyMismatch=[CJGuiInternalComposableSceneNode new];
    visibleBodyMismatch.node=raw; visibleBodyMismatch.geometry=geometry;
    visibleBodyMismatch.value=candidate.value;
    visibleBodyMismatch.preparedTextLayout=candidate.preparedTextLayout;
    visibleBodyMismatch.textMeasuredSource=candidate.textMeasuredSource;
    visibleBodyMismatch.textMeasuredWidth=candidate.textMeasuredWidth;
    visibleBodyMismatch.textMeasuredFontSize=candidate.textMeasuredFontSize;
    visibleBodyMismatch.textMeasuredFontWeight=candidate.textMeasuredFontWeight;
    visibleBodyMismatch.textMeasuredFontFamily=candidate.textMeasuredFontFamily;
    visibleBodyMismatch.textMeasuredNodeKind=candidate.textMeasuredNodeKind;
    visibleBodyMismatch.textMeasuredExtent=candidate.textMeasuredExtent;
    visibleBodyMismatch.textMeasureValid=candidate.textMeasureValid;
    CjguiAcceptedTextVisibility visibleMismatchVisibility=CjguiAcceptedTextVisibilityForNode(
        visibleBodyMismatch,NSMakeRect(0,0,680,689));
    CHECK(!NSIsEmptyRect(CjguiComposableTextTextureRectForNodeWithText(visibleBodyMismatch,
            visibleBodyMismatch.value)) && !visibleMismatchVisibility.available &&
        strcmp(visibleMismatchVisibility.reason,"prepared_body_mismatch")==0,
        "visible_body_graph_mismatch_remains_unavailable");

    CJGuiInternalComposableSceneNode *visible=[CJGuiInternalComposableSceneNode new];
    visible.node=raw; visible.geometry=geometry; visible.value=@"short text";
    ctx.stagedComposableNodes=[NSMutableArray arrayWithObject:visible];
    ctx.composableTextStyleRunsRaw=[@{@(raw.nodeId):wire} mutableCopy];
    CjguiInternalRendererStatus visibleStatus=CjguiPrepareComposableTextResources(ctx);
    fprintf(stderr,"selection_clip_VISIBLE status=%d coverage=%0.2fx%0.2f body=%lu decorations=%lu texture=%d\n",
        visibleStatus,(double)NSWidth(CjguiComposableTextTextureRectForNodeWithText(visible,visible.value)),
        (double)NSHeight(CjguiComposableTextTextureRectForNodeWithText(visible,visible.value)),
        (unsigned long)visible.preparedTextLayout.storage.string.length,
        (unsigned long)visible.textDeclaredSelectionDecorations.count,visible.textTexture!=nil);
    CHECK(visibleStatus==CJGUI_INTERNAL_RENDERER_OK &&
        [visible.preparedTextLayout.storage.string isEqualToString:visible.value] &&
        visible.textDeclaredSelectionDecorations.count>0,
        "visible_selection_with_matching_layout_is_painted");

    NSString *invalidWire=@"0:11:18:400:0:0:0:0:1:1:0.2:0.4:0.8:0.45:1";
    ctx.stagedComposableNodes=[NSMutableArray arrayWithObject:visible];
    ctx.composableTextStyleRunsRaw=[@{@(raw.nodeId):invalidWire} mutableCopy];
    CjguiInternalRendererStatus invalidStatus=CjguiPrepareComposableTextResources(ctx);
    CHECK(invalidStatus==CJGUI_INTERNAL_RENDERER_TEXT_RANGE_INVALID &&
        ctx.composableNodes==accepted && ctx.composableSceneVersion==1 &&
        [((CJGuiInternalComposableSceneNode *)accepted.firstObject).value isEqualToString:@"old accepted text 🙂"],
        "failed_candidate_does_not_mutate_accepted_scene");
    ctx.stagedComposableNodes=[previousStaged mutableCopy];
    ctx.stagedComposableSceneVersion=previousStagedVersion;
    ctx.composableTextStyleRunsRaw=previousRuns;
    return failures?1:0;
}
int main(void) { @autoreleasepool {
    [NSApplication sharedApplication]; [NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];
    CJGuiInternalSession *ctx=[CJGuiInternalSession new]; id<MTLDevice> device=MTLCreateSystemDefaultDevice();
    ctx.view=[[CJGuiInternalMetalView alloc] initWithFrame:NSMakeRect(0,0,680,689) device:device commandQueue:[device newCommandQueue]];
    PrepOverlay *overlay=[[PrepOverlay alloc] initWithFrame:ctx.view.bounds session:ctx];
    overlay.recordedWindow=[[PrepWindow alloc] initWithContentRect:ctx.view.bounds
        styleMask:NSWindowStyleMaskBorderless backing:NSBackingStoreBuffered defer:YES];
    overlay.recordedWindow.releasedWhenClosed=NO; overlay.recordedWindow.contentView=overlay;
    ctx.window=overlay.recordedWindow; ctx.composableSceneOverlay=overlay;
    ctx.composableNodes=[NSMutableArray array]; ctx.composableTextStyleRunsRaw=[NSMutableDictionary dictionary];
    CJGuiInternalComposableSceneNode *old=[CJGuiInternalComposableSceneNode new];
    CjguiInternalRendererComposableNode oldRaw={0}; oldRaw.nodeId=501; oldRaw.resourceId=1; oldRaw.projectionVersion=1;
    oldRaw.nodeKind=CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT; oldRaw.isInteractive=1;
    oldRaw.width=680; oldRaw.height=915; oldRaw.clipWidth=680; oldRaw.clipHeight=689;
    oldRaw.fontSize=18; oldRaw.fontWeight=400; oldRaw.textAlpha=1;
    old.node=oldRaw; old.value=@"old accepted text 🙂"; old.semanticId=@"ordinary-input"; old.textTextureCacheKey=@"";
    ctx.stagedComposableNodes=[NSMutableArray arrayWithObject:old]; ctx.stagedComposableSceneVersion=1;
    ctx.stagedComposableDataTransferItems=[NSMutableArray array]; ctx.stagedComposableDataTransferVersion=1;
    uint64_t token=CjguiAllocateSession(ctx); ctx.view.sessionToken=token;
    CHECK(CjguiCommitComposableSceneOnMain(token)==0,"real_old_scene_setup");
    [overlay setNodesFromProjection:ctx.view.composableNodes];
    if(getenv("CJGUI_SELECTION_CLIP_REGRESSION")) return RunSelectionClipRegression(ctx);
    NSString *path=@"/Users/jiangxuanyang/Desktop/cangjie/artifacts/e-macos-large-visual-20261002/normal-consumption/source-install-attribution/source-body-2048.utf8";
    NSString *body=[NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:NULL];
    if(!body.length) return 2;
    NSArray *accepted=ctx.composableNodes; NSArray *staged=ctx.stagedComposableNodes;
    NSString *oldValue=[old.value copy]; NSString *proxyValue=[overlay.inputProxy.string copy];
    uint64_t acceptedVersion=ctx.composableSceneVersion, stagedVersion=ctx.stagedComposableSceneVersion;
    CHECK(cjgui_internal_renderer_begin_composable_preparation(token,41,1,2,1)==0 && Fill(token,41,2,body)==0,
        "owned_packet_before_any_staging");
    CHECK(cjgui_internal_renderer_promote_composable_preparation(token,41)==99,"incomplete_cannot_promote");
    uint64_t rasters=ctx.view.textRasterCount; uint32_t ready=0;
    for(NSUInteger i=0;i<3;i++) CHECK(cjgui_internal_renderer_advance_composable_preparation(token,41,0,&ready)==0,
        "one_resource_unit");
    CHECK(!ready && ctx.composablePreparation.tileCursor==1 && ctx.view.textRasterCount==rasters+1,
        "park_after_one_real_tile");
    CHECK(ctx.composableNodes==accepted && ctx.stagedComposableNodes==staged &&
        ctx.composableSceneVersion==acceptedVersion && ctx.stagedComposableSceneVersion==stagedVersion &&
        [old.value isEqualToString:oldValue] && [overlay.inputProxy.string isEqualToString:proxyValue] &&
        ctx.composableTextStyleRunsRaw.count==0,"preparation_leaves_live_staged_runs_proxy_unchanged");
    CHECK(cjgui_internal_renderer_cancel_composable_preparation(token,41)==0 && !ctx.composablePreparation &&
        ctx.retiringComposablePreparations.count==1,"cancel_has_explicit_retiring_ownership");
    while(ctx.retiringComposablePreparations.count) CjguiRetireComposablePreparationUnit(ctx);
    CHECK(ctx.composableNodes==accepted && [old.value isEqualToString:oldValue],"retirement_preserves_accepted_resources");
    CHECK(cjgui_internal_renderer_begin_composable_preparation(token,42,1,2,1)==0 && Fill(token,42,2,body)==0 &&
        Finish(token,42)==0,"complete_private_resource_graph");
    CjguiComposablePreparation *p=ctx.composablePreparation;
    CJGuiInternalComposableSceneNode *prepared=p.nodes.firstObject;
    CHECK(prepared.textTextureSourceCredential && prepared.textTileTextures.count==6,
        "full_source_credential_and_six_tiles");
    uint64_t rasterBefore=ctx.view.textRasterCount,uploadBefore=ctx.view.textUploadCount;
    CjguiPreparedTextNodeLayout *sameLayout=prepared.preparedTextLayout;
    CHECK(cjgui_internal_renderer_configure_composable_scene(token,2,1)==0 &&
        cjgui_internal_renderer_set_composable_text_runs(token,501,"")==0 &&
        cjgui_internal_renderer_promote_composable_preparation(token,42)==0,
        "original_configure_runs_then_exact_transfer");
    CHECK(ctx.stagedComposableNodes.firstObject==prepared && prepared.preparedTextLayout==sameLayout &&
        !ctx.composablePreparation,"promote_transfers_same_objects");
    CHECK(CjguiPrepareComposableTextResources(ctx)==0 && ctx.view.textRasterCount==rasterBefore &&
        ctx.view.textUploadCount==uploadBefore,"final_admission_has_zero_repeat_raster_upload");
    CHECK(CjguiCommitComposableSceneOnMain(token)==0 && ctx.composableNodes.firstObject==prepared,
        "original_commit_accepts_prepared_objects_once");
    // Full actual-source pointer identity remains part of the proof. Another
    // equal-looking TextKit graph cannot donate its textures to this graph.
    CjguiPreparedTextNodeLayout *other=CjguiPrepareTextNodeLayout(prepared,body,2,nil,ctx);
    CjguiTextRasterSourceCredential *preparedSource=prepared.textTextureSourceCredential;
    CjguiTextRasterSourceCredential *otherSource=CjguiCreateTextRasterSourceCredential(prepared,
        other.storage,other.layoutManager,other.container,nil,body,2,
        preparedSource.coverage,preparedSource.tiles,
        preparedSource.origin,0,0,0);
    CHECK(!CjguiTextRasterSourceCredentialsEqual(prepared.textTextureSourceCredential,otherSource),
        "different_actual_TextKit_graph_cannot_reuse_texture");
    [overlay setNodesFromProjection:ctx.view.composableNodes];
    CHECK(cjgui_internal_renderer_begin_composable_preparation(token,44,2,3,1)==0 && Fill(token,44,3,body)==0,
        "next_private_candidate_has_distinct_handle");
    uint64_t nativeNow=cjgui_internal_renderer_owner_clock_ns();
    CHECK(cjgui_internal_renderer_advance_composable_preparation(token,44,nativeNow,&ready)==0 &&
        ctx.composablePreparation.nodeCursor==0 && !ready,"expired_owner_deadline_does_no_unit");
    uint64_t beforeRaster=ctx.view.textRasterCount;
    uint64_t narrowDeadline=cjgui_internal_renderer_owner_clock_ns()+9000000;
    CHECK(cjgui_internal_renderer_advance_composable_preparation(token,44,narrowDeadline,&ready)==0 &&
        !ready && ctx.composablePreparation.nodeCursor==0 && ctx.composablePreparation.phase==0 &&
        !ctx.composablePreparation.sourceLayout && ctx.view.textRasterCount==beforeRaster,
        "remaining_allowance_must_admit_indivisible_unit_and_owner_tail");
    CHECK(cjgui_internal_renderer_begin_composable_preparation(token,45,2,3,1)==99 &&
        ctx.composablePreparation.preparationId==44,"second_handle_cannot_steal_inflight_preparation");
    [overlay reconcileAccessibilityActions];
    CJGuiInternalComposableAccessibilityAction *action=overlay.accessibilityActions.firstObject;
    NSUInteger beforeEvents=ctx.pendingInteractions.count;
    NSString *human=[body stringByAppendingString:@"H"];
    ctx.rangeTextEditDeltaDeliveryEnabled=YES;
    [(id<NSAccessibility>)action setAccessibilityValue:human];
    CHECK([overlay.inputProxy.string isEqualToString:human] && ctx.pendingInteractions.count>beforeEvents,
        "real_accepted_AX_input_while_private_candidate_waits");
    CHECK(cjgui_internal_renderer_advance_composable_preparation(token,44,0,&ready)==
        CJGUI_INTERNAL_RENDERER_SCENE_STALE && !ready && ctx.composableSceneVersion==2,
        "live_native_input_names_superseded_preparation_before_publication");
    CHECK(cjgui_internal_renderer_cancel_composable_preparation(token,44)==0 &&
        [overlay.inputProxy.string isEqualToString:human] && ctx.pendingInteractions.count>beforeEvents,
        "cancelling_old_candidate_preserves_new_input_and_FIFO");
    // A new request cannot steal another handle or change live accepted facts.
    CHECK(cjgui_internal_renderer_begin_composable_preparation(token,43,1,3,1)==99,
        "stale_base_scene_rejected");
    CHECK(cjgui_internal_renderer_advance_composable_preparation(token,41,0,&ready)==99,
        "retired_handle_cannot_advance_or_publish");
    // Start another independent fixture after the consumer has judged the AX
    // intent above. A changed owned source must prepare its own static graph;
    // admitting it cannot rewrite the still-live adapter synchronously.
    [ctx.pendingInteractions removeAllObjects];
    overlay.activeLocalEditAwaitingOwner=NO;
    overlay.activeTextRangeEditPending=NO;
    for (NSUInteger i=0;i<100 && overlay.activeTextResourcePreparationScheduled;++i)
        [[NSRunLoop mainRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.001]];
    CHECK(!overlay.activeTextResourcePreparationScheduled,
        "prior_AX_resource_callback_settled_before_selection_fixture");
    NSRange choiceBefore=overlay.inputProxy.selectedRange;
    CHECK(cjgui_internal_renderer_begin_composable_preparation(token,47,2,3,1)==0 &&
        FillStatic(token,47,3)==0 && Finish(token,47)==0,
        "selection_only_candidate_prepares_from_actual_source");
    CHECK(cjgui_internal_renderer_configure_composable_scene(token,3,1)==0 &&
        cjgui_internal_renderer_set_composable_text_runs(token,777,"")==0,
        "selection_only_ready_candidate_stages_before_source_recheck");
    NSRange newChoice=NSMakeRange(choiceBefore.location>0?choiceBefore.location-1:1,0);
    [overlay.inputProxy setSelectedRange:newChoice];
    CjguiInternalRendererStatus selectionStale=cjgui_internal_renderer_advance_composable_preparation(token,47,0,&ready);
    fprintf(stderr,"selection_only_diagnostic before=%lu:%lu after=%lu:%lu wanted=%lu:%lu status=%d ready=%u queued=%lu\n",
        (unsigned long)choiceBefore.location,(unsigned long)choiceBefore.length,
        (unsigned long)overlay.inputProxy.selectedRange.location,(unsigned long)overlay.inputProxy.selectedRange.length,
        (unsigned long)newChoice.location,(unsigned long)newChoice.length,selectionStale,ready,
        (unsigned long)ctx.pendingInteractions.count);
    CHECK(NSEqualRanges(overlay.inputProxy.selectedRange,newChoice) &&
        selectionStale==CJGUI_INTERNAL_RENDERER_SCENE_STALE && !ready &&
        ctx.composableSceneVersion==2 && ctx.composablePreparation.preparationId==47,
        "selection_only_input_supersedes_private_candidate_without_new_scene");
    CHECK(cjgui_internal_renderer_promote_composable_preparation(token,47)==
        CJGUI_INTERNAL_RENDERER_SCENE_STALE && ctx.composableSceneVersion==2 &&
        ctx.composablePreparation.preparationId==47,
        "selection_only_input_supersedes_ready_candidate_at_promotion");
    CHECK(cjgui_internal_renderer_cancel_composable_preparation(token,47)==0 &&
        cjgui_internal_renderer_discard_composable_scene_candidate(token)==0 &&
        NSEqualRanges(overlay.inputProxy.selectedRange,newChoice) && ctx.composableSceneVersion==2,
        "superseded_candidate_cancel_preserves_new_selection");
    [ctx.pendingInteractions removeAllObjects];
    prepared.value=human;
    ctx.ownedTextSessionEnabled=YES; ctx.ownedTextSessionNodeId=501;
    ctx.ownedTextSessionResourceId=1; ctx.ownedTextSessionNodeKind=oldRaw.nodeKind;
    ctx.ownedTextSessionBindingEpoch=83;
    NSTextView *priorProxy=overlay.inputProxy;
    NSAttributedString *priorStorage=[priorProxy.textStorage copy];
    NSRange priorSelection=priorProxy.selectedRange;
    NSResponder *priorResponder=ctx.window.firstResponder;
    uint64_t priorActiveProjection=overlay.activeProjectionVersion;
    NSString *nextBody=[body stringByAppendingString:@" accepted source B"];
    cjgui_internal_renderer_set_source_install_gate(token,83,601,1);
    CHECK(cjgui_internal_renderer_begin_composable_preparation(token,46,2,3,1)==0 &&
        Fill(token,46,3,nextBody)==0 && Finish(token,46)==0,
        "owned_changed_source_prepares_static_resources_before_admission");
    CJGuiInternalComposableSceneNode *next=ctx.composablePreparation.nodes.firstObject;
    CHECK(next.textTextureSourceCredential && next.preparedTextLayout &&
        [((CjguiTextRasterSourceCredential *)next.textTextureSourceCredential).body isEqualToString:nextBody],
        "owned_candidate_resources_use_new_actual_source");
    CHECK(cjgui_internal_renderer_configure_composable_scene(token,3,1)==0 &&
        cjgui_internal_renderer_set_composable_text_runs(token,501,"")==0 &&
        cjgui_internal_renderer_promote_composable_preparation(token,46)==0 &&
        CjguiPrepareComposableTextResources(ctx)==0 && CjguiCommitComposableSceneOnMain(token)==0,
        "owned_static_candidate_admitted_under_original_restore_gate");
    [overlay setNodesFromProjection:ctx.view.composableNodes];
    CHECK(overlay.sourceInputParked && overlay.inputProxy==priorProxy &&
        [priorProxy.textStorage isEqualToAttributedString:priorStorage] &&
        NSEqualRanges(priorProxy.selectedRange,priorSelection) &&
        ctx.window.firstResponder==priorResponder && overlay.activeProjectionVersion==priorActiveProjection,
        "owned_admission_keeps_old_proxy_body_selection_and_identity");
    id nextCredential=next.textTextureSourceCredential;
    id nextTextures=next.textTileTextures;
    [overlay positionInputProxyForNode:next]; [overlay refreshGpuTextForActiveInput];
    CHECK(overlay.inputProxy==priorProxy && [priorProxy.textStorage isEqualToAttributedString:priorStorage] &&
        next.textTextureSourceCredential==nextCredential && next.textTileTextures==nextTextures &&
        [next.value isEqualToString:nextBody] && ctx.pendingInteractions.count==0,
        "parked_old_adapter_cannot_relabel_or_paint_new_accepted_source");
    uint32_t selectionStart=0,selectionEnd=0; uint8_t installDeferred=0;
    CjguiInternalRendererStatus installStatus=CJGUI_INTERNAL_RENDERER_SCENE_STALE;
    for (NSUInteger i=0;i<256 && installStatus==CJGUI_INTERNAL_RENDERER_SCENE_STALE;++i)
        installStatus=cjgui_internal_renderer_install_owned_source_selection(token,501,1,3,83,601,
            cjgui_internal_renderer_owner_clock_ns()+10000000000ull,nextBody.UTF8String,7,7,
            &selectionStart,&selectionEnd,&installDeferred);
    fprintf(stderr,"owned_install_diagnostic status=%d deferred=%u gate=%u scene=%llu binding=%llu request=%llu "
        "marked=%u terminal=%u local=%u range=%u fallback_edit=%u scheduled=%u queued=%lu phase=%lu\n",
        installStatus,installDeferred,CjguiSourceInstallPending(ctx),(unsigned long long)ctx.composableSceneVersion,
        (unsigned long long)ctx.ownedTextSessionBindingEpoch,
        (unsigned long long)atomic_load(&gCjguiSourceInstallRequest[token-1]),priorProxy.hasMarkedText,
        overlay.compositionTerminalInFlight,overlay.activeLocalEditAwaitingOwner,overlay.activeTextRangeEditPending,
        overlay.activeTextFallbackHasPendingEdit,overlay.activeTextResourcePreparationScheduled,
        (unsigned long)ctx.pendingInteractions.count,(unsigned long)ctx.sourceProxyPreparation.phase);
    fprintf(stderr,"owned_install_conditions status=%u deferred=%u start=%u end=%u parked=%u proxy_replaced=%u body_equal=%u projection=%llu first_is_proxy=%u first_is_host=%u actual_host_focus=%u queued=%lu\n",
        installStatus,installDeferred,selectionStart,selectionEnd,overlay.sourceInputParked,
        overlay.inputProxy!=priorProxy,[overlay.inputProxy.string isEqualToString:nextBody],
        (unsigned long long)overlay.activeProjectionVersion,ctx.window.firstResponder==overlay.inputProxy,
        ctx.window.firstResponder==overlay.inputHost,CjguiInputProxyIsFirstResponder(overlay),
        (unsigned long)ctx.pendingInteractions.count);
    CHECK(installStatus==CJGUI_INTERNAL_RENDERER_OK && !installDeferred && selectionStart==7 && selectionEnd==7 &&
        !overlay.sourceInputParked && overlay.inputProxy!=priorProxy &&
        [overlay.inputProxy.string isEqualToString:nextBody] && overlay.activeProjectionVersion==3 &&
        ctx.window.firstResponder==overlay.inputHost && CjguiInputProxyIsFirstResponder(overlay) &&
        ctx.pendingInteractions.count==0,
        "owned_static_source_finishes_with_same_ticket_actual_adapter_adoption");
    cjgui_internal_renderer_set_source_install_gate(token,83,601,0);
    // Two cancelled unpublished 117-node graphs must make bounded retirement
    // progress. Their quota stays two; accepted objects remain independently held.
    ctx.retiringComposablePreparations = [NSMutableArray array];
    for (NSUInteger graph = 0; graph < 2; ++graph) {
        CjguiComposablePreparation *retired = [CjguiComposablePreparation new];
        retired.retiring = YES; retired.nodes = [NSMutableArray array];
        for (NSUInteger i = 0; i < 117; ++i)
            [retired.nodes addObject:[CJGuiInternalComposableSceneNode new]];
        [ctx.retiringComposablePreparations addObject:retired];
    }
    NSArray *preservedAccepted = ctx.composableNodes;
    CHECK(cjgui_internal_renderer_begin_composable_preparation(token,91,3,4,1) == 0,
        "two_retired_graphs_progress_before_next_candidate_admission");
    CHECK(ctx.composableNodes == preservedAccepted && ctx.retiringComposablePreparations.count < 2,
        "retirement_keeps_accepted_graph_and_two_slot_quota");
    if (ctx.composablePreparation)
        cjgui_internal_renderer_cancel_composable_preparation(token,91);
    [overlay.recordedWindow close]; CjguiReleaseSession(token);
    return failures?1:0;
} }

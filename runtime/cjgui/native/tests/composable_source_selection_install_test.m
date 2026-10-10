#define CJGUI_INTERNAL_TESTING 1
#import "../cjgui_internal_renderer.m"

// A never-shown window with a controlled responder. No foreground event or
// frame submission occurs. The real proxy/TextKit/Metal/bridge paths run below.
@interface SourceInstallProxy : CJGuiInternalComposableInputProxy
@property(nonatomic, assign) NSUInteger readbackCountdown;
@property(nonatomic, assign) BOOL failAfterNextSelectionSet;
@end
@implementation SourceInstallProxy
- (void)setSelectedRange:(NSRange)range {
    [super setSelectedRange:range];
    if (self.failAfterNextSelectionSet) {
        self.failAfterNextSelectionSet = NO;
        self.readbackCountdown = 1;
    }
}
- (NSRange)selectedRange {
    NSRange range = [super selectedRange];
    if (self.readbackCountdown > 0 && --self.readbackCountdown == 0) range.location += 1;
    return range;
}
@end
@interface SourceInstallWindow : NSWindow
@property(nonatomic, strong) NSResponder *testResponder;
@property(nonatomic, assign) BOOL failNextResponder;
@property(nonatomic, assign) BOOL failNextSelectionReadback;
@property(nonatomic, assign) NSUInteger responderCalls;
@end
@implementation SourceInstallWindow
- (instancetype)initWithContentRect:(NSRect)rect styleMask:(NSWindowStyleMask)style
    backing:(NSBackingStoreType)backing defer:(BOOL)defer {
    self = [super initWithContentRect:rect styleMask:style backing:backing defer:defer];
    // The fixture, like the production session, owns its NSWindow strongly.
    // Closing an unseen fixture must not also release that ARC-owned object.
    if (self) self.releasedWhenClosed = NO;
    return self;
}
- (NSResponder *)firstResponder { return self.testResponder; }
- (BOOL)makeFirstResponder:(NSResponder *)responder {
    self.responderCalls += 1;
    if (self.failNextResponder) { self.failNextResponder = NO; return NO; }
    self.testResponder = responder;
    NSTextView *target = [responder isKindOfClass:[CJGuiInternalComposableInputHost class]]
        ? ((CJGuiInternalComposableInputHost *)responder).composableOverlay.inputProxy
        : ([responder isKindOfClass:[NSTextView class]] ? (NSTextView *)responder : nil);
    if (self.failNextSelectionReadback && [target isKindOfClass:[SourceInstallProxy class]]) {
        self.failNextSelectionReadback = NO;
        ((SourceInstallProxy *)target).failAfterNextSelectionSet = YES;
    }
    return YES;
}
- (BOOL)isKeyWindow { return NO; }
- (BOOL)isVisible { return NO; }
- (BOOL)isMiniaturized { return NO; }
- (NSInteger)windowNumber { return 0; }
- (NSScreen *)screen { return nil; }
- (CGFloat)backingScaleFactor { return 2; }
@end
@interface SourceInstallOverlay : CJGuiInternalComposableSceneOverlay
@property(nonatomic, strong) SourceInstallWindow *testWindow;
@end
@implementation SourceInstallOverlay
- (NSWindow *)window { return (NSWindow *)self.testWindow; }
@end
static int failures = 0;
#define CHECK(c, label) do { BOOL ok = (c); fprintf(stderr, "source_install case=%s result=%s\n", label, ok ? "PASS" : "FAIL"); if (!ok) ++failures; } while (0)

static CjguiInternalRendererStatus SourceInstall(uint64_t token, uint64_t request, uint64_t scene,
    uint64_t binding, NSString *value, uint32_t start, uint32_t end, uint64_t deadline,
    uint32_t *outStart, uint32_t *outEnd, uint8_t *outDeferred) {
    return cjgui_internal_renderer_install_owned_source_selection(token,401,1,scene,binding,request,deadline,
        value.UTF8String,start,end,outStart,outEnd,outDeferred);
}

static BOOL SourceInstallPrepareToReady(CJGuiInternalSession *ctx, uint64_t token, uint64_t request,
    uint64_t scene, uint64_t binding, NSString *value, uint32_t start, uint32_t end,
    uint32_t *outStart, uint32_t *outEnd) {
    uint64_t deadline=cjgui_internal_renderer_owner_clock_ns()+10000000000ull;
    for (NSUInteger i=0;i<256;++i) {
        uint8_t deferred=0;
        CjguiInternalRendererStatus status=SourceInstall(token,request,scene,binding,value,start,end,deadline,
            outStart,outEnd,&deferred);
        if (status!=CJGUI_INTERNAL_RENDERER_SCENE_STALE && status!=CJGUI_INTERNAL_RENDERER_OK) return NO;
        if (ctx.sourceProxyPreparation.ready) return deferred==1;
    }
    return NO;
}

static SourceInstallProxy *SourceInstallReplacePreparedProxy(CjguiSourceProxyPreparation *p) {
    NSTextView *prior=p.overlay.inputProxy;
    prior.delegate=nil;
    SourceInstallProxy *proxy=[[SourceInstallProxy alloc] initWithFrame:prior.frame];
    proxy.composableOverlay=p.overlay; proxy.delegate=p.overlay;
    proxy.layoutManager.allowsNonContiguousLayout=YES;
    proxy.layoutManager.backgroundLayoutEnabled=NO;
    p.overlay.inputProxy=proxy;
    p.overlay.inputScrollProxy.documentView=proxy;
    return proxy;
}

static id SourceInstallCapturedValue(NSDictionary *values, NSString *key) {
    id value=values[key];
    return value==[NSNull null]?nil:value;
}

static BOOL SourceInstallConsumeJudgedInteraction(CJGuiInternalSession *ctx, uint32_t kind, uint64_t nodeId) {
    if (ctx.pendingInteractions.count!=1) return NO;
    CJGuiInternalQueuedInteraction *interaction=ctx.pendingInteractions.firstObject;
    if (interaction.kind!=kind || interaction.nodeId!=nodeId) return NO;
    // This isolated test fixture models its owner receiving and judging this
    // one event. Preserve any unexpected FIFO entries for the assertion.
    [ctx.pendingInteractions removeObjectAtIndex:0];
    return YES;
}

static BOOL SourceInstallSetActualMarkedText(NSTextView *proxy, NSString *marked) {
    SEL selector=@selector(setMarkedText:selectedRange:replacementRange:);
    Method method=class_getInstanceMethod([NSTextView class],selector);
    if (!method) return NO;
    IMP implementation=method_getImplementation(method);
    ((void (*)(id,SEL,id,NSRange,NSRange))implementation)(proxy,selector,marked,
        NSMakeRange(0,marked.length),NSMakeRange(7,0));
    return proxy.hasMarkedText;
}

// This fixture consumes native input only after checking the complete FIFO
// contents, then publishes the accepted body through the normal scene
// configure/set/commit path. It is a native boundary simulation, not evidence
// that the production Cangjie owner consumed or accepted the interaction.
static BOOL SourceInstallConsumeFixtureEditFIFO(CJGuiInternalSession *ctx, NSString *body,
                                                NSString *replacement, NSRange editRange) {
    if (ctx.pendingInteractions.count!=3) return NO;
    CJGuiInternalQueuedInteraction *selection=ctx.pendingInteractions[0];
    CJGuiInternalQueuedInteraction *text=ctx.pendingInteractions[1];
    CJGuiInternalQueuedInteraction *range=ctx.pendingInteractions[2];
    for (CJGuiInternalQueuedInteraction *item in ctx.pendingInteractions)
        if (item.nodeId!=401 || item.resourceId!=1 ||
            item.nodeKind!=CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT ||
            item.projectionVersion!=ctx.composableSceneVersion) return NO;
    if (selection.kind!=CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_SELECTION_CHANGED ||
        text.kind!=CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_TEXT_CHANGED ||
        ![text.formText isEqualToString:body] ||
        range.kind!=CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_TEXT_RANGE_CHANGED ||
        ![range.formText isEqualToString:replacement] ||
        range.selectionStart!=editRange.location || range.selectionEnd!=NSMaxRange(editRange)) return NO;
    [ctx.pendingInteractions removeAllObjects]; // Simulated owner judged every checked item.
    return YES;
}

static BOOL SourceInstallPublishFixtureAcceptedBody(CJGuiInternalSession *ctx, uint64_t token,
                                                     uint64_t scene, NSString *body,
                                                     BOOL preserveActiveLocalText) {
    if (cjgui_internal_renderer_configure_composable_scene(token,scene,1)!=CJGUI_INTERNAL_RENDERER_OK)
        return NO;
    CjguiInternalRendererComposableNode accepted=ctx.composableNodes.firstObject.node;
    accepted.projectionVersion=scene;
    accepted.preservesActiveLocalText=preserveActiveLocalText ? 1 : 0;
    CJGuiInternalComposableSceneNode *prior=ctx.composableNodes.firstObject;
    NSString *transportValue=preserveActiveLocalText ? @"" : body;
    if (cjgui_internal_renderer_set_composable_scene_node(token,0,&accepted,
            prior.label.UTF8String ?: "",transportValue.UTF8String ?: "",
            prior.imageResourcePath.UTF8String ?: "",prior.imageResourceId.UTF8String ?: "",
            prior.imageResourceVersion)!=CJGUI_INTERNAL_RENDERER_OK) return NO;
    // The accepted node is shared by the scene/overlay. Resolving the
    // one-shot omission legitimately fills that same object; freeze the
    // actual staged transport before the accepted path resolves it.
    BOOL exactTransport=[ctx.stagedComposableNodes.firstObject.value isEqualToString:transportValue];
    if (CjguiCommitComposableSceneOnMain(token)!=CJGUI_INTERNAL_RENDERER_OK) return NO;
    [ctx.composableSceneOverlay setNodesFromProjection:ctx.view.composableNodes];
    CJGuiInternalComposableSceneNode *published=ctx.composableNodes.firstObject;
    CJGuiInternalComposableSceneNode *projected=ctx.composableSceneOverlay.nodes.firstObject;
    return ctx.composableSceneVersion==scene && ctx.ownedTextSessionBindingEpoch==71 &&
        published.node.nodeId==401 && published.node.resourceId==1 &&
        published.node.projectionVersion==scene && exactTransport && [published.value isEqualToString:body] &&
        [projected.value isEqualToString:body] &&
        ctx.composableSceneOverlay.activeProjectionVersion==scene &&
        [ctx.composableSceneOverlay.inputProxy.string isEqualToString:body];
}

static BOOL SourceInstallPumpActiveResourcePreparation(CJGuiInternalComposableSceneOverlay *overlay) {
    for (NSUInteger turn=0;turn<100 && overlay.activeTextResourcePreparationScheduled;++turn)
        (void)CFRunLoopRunInMode(kCFRunLoopDefaultMode,0.01,true);
    return !overlay.activeTextResourcePreparationScheduled;
}

static BOOL SourceInstallPerformNativeAppend(CJGuiInternalComposableSceneOverlay *overlay,
                                              NSString *replacement, NSString **outBefore,
                                              NSString **outAfter, NSRange *outEdit) {
    NSString *before=[overlay.inputProxy.string copy];
    NSRange edit=NSMakeRange(before.length,0);
    overlay.applyingProjection=YES; overlay.inputProxy.selectedRange=edit;
    overlay.applyingProjection=NO;
    BOOL allowed=[overlay textView:overlay.inputProxy shouldChangeTextInRange:edit
        replacementString:replacement];
    if (!allowed) return NO;
    [overlay.inputProxy.textStorage replaceCharactersInRange:edit withString:replacement];
    overlay.applyingProjection=YES;
    overlay.inputProxy.selectedRange=NSMakeRange(edit.location+replacement.length,0);
    overlay.applyingProjection=NO;
    [overlay.inputProxy didChangeText];
    NSString *after=[overlay.inputProxy.string copy];
    if (outBefore) *outBefore=before;
    if (outAfter) *outAfter=after;
    if (outEdit) *outEdit=edit;
    return [after isEqualToString:[before stringByAppendingString:replacement]];
}

static void SourceInstallRunSettledLocalEditFixture(id<MTLDevice> device) {
    CJGuiInternalSession *ctx=[CJGuiInternalSession new];
    ctx.view=[[CJGuiInternalMetalView alloc] initWithFrame:NSMakeRect(0,0,680,500)
        device:device commandQueue:[device newCommandQueue]];
    ctx.composableNodes=[NSMutableArray array];
    ctx.stagedComposableNodes=[NSMutableArray array];
    ctx.composableTextStyleRunsRaw=[NSMutableDictionary dictionary];
    SourceInstallOverlay *overlay=[[SourceInstallOverlay alloc]
        initWithFrame:NSMakeRect(0,0,680,500) session:ctx];
    overlay.testWindow=[[SourceInstallWindow alloc] initWithContentRect:NSMakeRect(0,0,680,500)
        styleMask:NSWindowStyleMaskBorderless backing:NSBackingStoreBuffered defer:YES];
    ctx.window=(NSWindow *)overlay.testWindow; ctx.composableSceneOverlay=overlay;
    overlay.testWindow.contentView=overlay;
    overlay.inputProxy.delegate=nil;
    SourceInstallProxy *proxy=[[SourceInstallProxy alloc] initWithFrame:overlay.inputProxy.frame];
    proxy.composableOverlay=overlay; proxy.delegate=overlay;
    proxy.layoutManager.allowsNonContiguousLayout=YES;
    proxy.layoutManager.backgroundLayoutEnabled=NO;
    overlay.inputProxy=proxy; overlay.inputScrollProxy.documentView=proxy;

    CJGuiInternalComposableSceneNode *node=[CJGuiInternalComposableSceneNode new];
    CjguiInternalRendererComposableNode raw={0};
    raw.nodeId=401; raw.resourceId=1; raw.projectionVersion=1;
    raw.nodeKind=CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT;
    raw.width=680; raw.height=1200; raw.clipWidth=680; raw.clipHeight=500;
    raw.fontSize=13; raw.textAlpha=1; raw.isInteractive=1;
    node.node=raw; node.index=0; node.value=@"Owner-accepted fixture body\nwith a second row\n";
    node.styleRunsSignature=@""; node.textTextureCacheKey=@"";
    ctx.stagedComposableNodes=[NSMutableArray arrayWithObject:node];
    ctx.stagedComposableSceneVersion=1;
    ctx.stagedComposableDataTransferItems=[NSMutableArray array];
    ctx.stagedComposableDataTransferVersion=1;
    uint64_t token=CjguiAllocateSession(ctx);
    CHECK(CjguiCommitComposableSceneOnMain(token)==CJGUI_INTERNAL_RENDERER_OK,
        "settled_edit_fixture_scene_one_accepted");
    [overlay setNodesFromProjection:ctx.view.composableNodes];
    ctx.ownedTextSessionEnabled=YES; ctx.ownedTextSessionNodeId=401;
    ctx.ownedTextSessionResourceId=1; ctx.ownedTextSessionNodeKind=raw.nodeKind;
    ctx.ownedTextSessionBindingEpoch=71; ctx.rangeTextEditDeltaDeliveryEnabled=YES;
    CHECK([overlay focusCommittedNodeId:401],"settled_edit_fixture_active_proxy_matches_scene_one");
    overlay.testWindow.testResponder=overlay.inputHost;
    CHECK(ctx.pendingInteractions.count==0,"native_fixture_fifo_empty_before_local_text_edit");

    NSString *before=[overlay.inputProxy.string copy];
    NSString *replacement=@"!";
    NSRange edit=NSMakeRange(before.length,0);
    overlay.applyingProjection=YES; overlay.inputProxy.selectedRange=edit;
    overlay.applyingProjection=NO;
    BOOL accepted=[overlay textView:overlay.inputProxy shouldChangeTextInRange:edit replacementString:replacement];
    if (accepted) {
        [overlay.inputProxy.textStorage replaceCharactersInRange:edit withString:replacement];
        overlay.applyingProjection=YES;
        overlay.inputProxy.selectedRange=NSMakeRange(edit.location+replacement.length,0);
        overlay.applyingProjection=NO;
        [overlay.inputProxy didChangeText];
    }
    NSString *editedBody=[overlay.inputProxy.string copy];
    BOOL bodyIsExactAppend=[editedBody isEqualToString:[before stringByAppendingString:replacement]];
    BOOL actualCallback=accepted && overlay.activeLocalEditAwaitingOwner &&
        overlay.activeLocalEditProjectionVersion==1 && bodyIsExactAppend &&
        ctx.pendingInteractions.count==3 && overlay.activeLocalEditGeneration!=0 &&
        overlay.activeLocalEditSettledGeneration!=overlay.activeLocalEditGeneration &&
        overlay.activeLocalEditProxy==overlay.inputProxy && overlay.activeLocalEditBindingEpoch==71;
    fprintf(stderr,"settled_edit_callback accepted=%d flag=%d captured=%llu projection=%llu body_match=%d body_len=%lu before_len=%lu fifo=%lu callback_count=%lu\n",
        accepted,(int)overlay.activeLocalEditAwaitingOwner,(unsigned long long)overlay.activeLocalEditProjectionVersion,
        (unsigned long long)overlay.activeProjectionVersion,(int)bodyIsExactAppend,(unsigned long)editedBody.length,
        (unsigned long)before.length,(unsigned long)ctx.pendingInteractions.count,
        (unsigned long)overlay.testInputCallbackTrace.textCallbackCount);
    for (CJGuiInternalQueuedInteraction *item in ctx.pendingInteractions)
        fprintf(stderr,"settled_edit_item kind=%u scene=%llu range=%u-%u text=%s\n",item.kind,
            (unsigned long long)item.projectionVersion,item.selectionStart,item.selectionEnd,item.formText.UTF8String);
    CHECK(actualCallback,"real_textkit_edit_callback_sets_unsettled_generation_and_native_fifo");

    uint32_t selectionStart=(uint32_t)editedBody.length, selectionEnd=(uint32_t)editedBody.length;
    uint32_t outStart=0,outEnd=0; uint8_t deferred=0;
    cjgui_internal_renderer_set_source_install_gate(token,71,700,1);
    NSTextView *oldProxy=overlay.inputProxy; NSScrollView *oldScroll=overlay.inputScrollProxy;
    NSUInteger unconsumedCount=ctx.pendingInteractions.count;
    CjguiInternalRendererStatus status=cjgui_internal_renderer_install_owned_source_selection(token,401,1,1,71,700,
        cjgui_internal_renderer_owner_clock_ns()+10000000000ull,editedBody.UTF8String,
        selectionStart,selectionEnd,&outStart,&outEnd,&deferred);
    CHECK(status!=CJGUI_INTERNAL_RENDERER_OK && overlay.inputProxy==oldProxy &&
        overlay.inputScrollProxy==oldScroll && ctx.pendingInteractions.count==unconsumedCount,
        "unconsumed_same_projection_edit_fifo_blocks_selection_install_without_mutation");

    BOOL consumed=SourceInstallConsumeFixtureEditFIFO(ctx,editedBody,replacement,edit);
    CHECK(consumed,"native_fixture_owner_judged_real_text_changed_then_range_changed_fifo");
    BOOL published=consumed && SourceInstallPublishFixtureAcceptedBody(ctx,token,2,editedBody,NO);
    CHECK(published,"native_fixture_published_same_body_same_binding_at_higher_scene");
    CHECK(published && overlay.activeLocalEditSettledGeneration==overlay.activeLocalEditGeneration &&
        overlay.activeLocalEditProxy==overlay.inputProxy && overlay.activeLocalEditBindingEpoch==71,
        "accepted_same_body_projection_settles_captured_proxy_binding_generation");
    BOOL resourcesPrepared=published && SourceInstallPumpActiveResourcePreparation(overlay);
    CHECK(resourcesPrepared,"accepted_scene_main_queue_resource_preparation_callback_completed");
    oldProxy=overlay.inputProxy; oldScroll=overlay.inputScrollProxy;
    uint64_t deadline=cjgui_internal_renderer_owner_clock_ns()+10000000000ull;
    status=SourceInstall(token,700,2,71,editedBody,selectionStart,selectionEnd,deadline,
        &outStart,&outEnd,&deferred);
    BOOL ready=deferred==1 && ctx.sourceProxyPreparation &&
        SourceInstallPrepareToReady(ctx,token,700,2,71,editedBody,selectionStart,selectionEnd,&outStart,&outEnd);
    fprintf(stderr,"settled_edit_install status=%d deferred=%u prep=%d ready=%d scene=%llu body_match=%d proxy_same=%d\n",
        status,(unsigned)deferred,ctx.sourceProxyPreparation!=nil,ready,
        (unsigned long long)ctx.composableSceneVersion,
        (int)[ctx.composableNodes.firstObject.value isEqualToString:overlay.inputProxy.string],
        (int)(overlay.inputProxy==oldProxy));
    if (ready) status=SourceInstall(token,700,2,71,editedBody,selectionStart,selectionEnd,
        cjgui_internal_renderer_owner_clock_ns()+10000000000ull,&outStart,&outEnd,&deferred);
    CHECK(published && ready && status==CJGUI_INTERNAL_RENDERER_OK && deferred==0 &&
        overlay.inputProxy!=oldProxy && overlay.inputProxy.string &&
        [overlay.inputProxy.string isEqualToString:editedBody] && overlay.activeProjectionVersion==2,
        "real_edit_ack_same_body_new_scene_installs_original_selection_request");
    while (ctx.retiringSourceProxyPreparations.count) CjguiRetireSourceProxyPreparationUnit(ctx);
    cjgui_internal_renderer_set_source_install_gate(token,71,700,0);

    // Exercise the real preserve transport: Cangjie sends an empty value with
    // preservesActiveLocalText, and the native same-active owner proof resolves
    // that omission to the exact current body before settling the generation.
    NSString *preserveBefore=nil, *preservedBody=nil; NSRange preserveEdit=NSMakeRange(0,0);
    BOOL preserveCallback=SourceInstallPerformNativeAppend(overlay,@"?",&preserveBefore,
        &preservedBody,&preserveEdit);
    uint64_t preserveGeneration=overlay.activeLocalEditGeneration;
    BOOL preserveFifo=preserveCallback && ctx.pendingInteractions.count==3 &&
        SourceInstallConsumeFixtureEditFIFO(ctx,preservedBody,@"?",preserveEdit);
    CHECK(preserveCallback && preserveFifo && preserveGeneration!=overlay.activeLocalEditSettledGeneration,
        "preserve_transport_fixture_consumed_real_textkit_fifo_for_new_generation");
    cjgui_internal_renderer_set_source_install_gate(token,71,701,1);
    BOOL preservePublished=preserveFifo &&
        SourceInstallPublishFixtureAcceptedBody(ctx,token,3,preservedBody,YES);
    if (!preservePublished || overlay.activeLocalEditSettledGeneration!=preserveGeneration ||
        ![ctx.composableNodes.firstObject.value isEqualToString:preservedBody] ||
        ![overlay.nodes.firstObject.value isEqualToString:preservedBody] ||
        ![overlay.inputProxy.string isEqualToString:preservedBody]) {
        fprintf(stderr,"preserve_transport_diag published=%d flag=%d captured=%llu generation=%llu settled=%llu active_scene=%llu proxy_match=%d binding=%llu parked=%d resource_scheduled=%d body=%s projected=%s transport=%s fifo=%lu\n",
            (int)preservePublished,(int)overlay.activeLocalEditAwaitingOwner,
            (unsigned long long)overlay.activeLocalEditProjectionVersion,
            (unsigned long long)overlay.activeLocalEditGeneration,
            (unsigned long long)overlay.activeLocalEditSettledGeneration,
            (unsigned long long)overlay.activeProjectionVersion,
            (int)(overlay.activeLocalEditProxy==overlay.inputProxy),
            (unsigned long long)overlay.activeLocalEditBindingEpoch,(int)overlay.sourceInputParked,
            (int)overlay.activeTextResourcePreparationScheduled,overlay.inputProxy.string.UTF8String ?: "",
            overlay.nodes.firstObject.value.UTF8String ?: "",
            ctx.composableNodes.firstObject.value.UTF8String ?: "",(unsigned long)ctx.pendingInteractions.count);
        for (CJGuiInternalQueuedInteraction *item in ctx.pendingInteractions)
            fprintf(stderr,"preserve_transport_fifo kind=%u scene=%llu node=%llu resource=%llu range=%u-%u text=%s\n",
                item.kind,(unsigned long long)item.projectionVersion,(unsigned long long)item.nodeId,
                (unsigned long long)item.resourceId,item.selectionStart,item.selectionEnd,item.formText.UTF8String ?: "");
    }
    CHECK(preservePublished && preserveGeneration==overlay.activeLocalEditSettledGeneration &&
        overlay.activeLocalEditProxy==overlay.inputProxy && overlay.activeLocalEditBindingEpoch==71 &&
        [ctx.composableNodes.firstObject.value isEqualToString:preservedBody] &&
        [overlay.nodes.firstObject.value isEqualToString:preservedBody] &&
        [overlay.inputProxy.string isEqualToString:preservedBody],
        "empty_preserve_transport_resolves_exact_body_and_settles_generation");
    BOOL preserveResourcesPrepared=preservePublished && SourceInstallPumpActiveResourcePreparation(overlay);
    CHECK(preserveResourcesPrepared,"preserve_transport_main_queue_resource_preparation_completed");
    uint32_t preserveSelection=(uint32_t)preservedBody.length;
    status=SourceInstall(token,701,3,71,preservedBody,preserveSelection,preserveSelection,
        cjgui_internal_renderer_owner_clock_ns()+10000000000ull,&outStart,&outEnd,&deferred);
    BOOL preserveReady=deferred==1 && ctx.sourceProxyPreparation &&
        SourceInstallPrepareToReady(ctx,token,701,3,71,preservedBody,preserveSelection,preserveSelection,
            &outStart,&outEnd);
    if (preserveReady) status=SourceInstall(token,701,3,71,preservedBody,preserveSelection,preserveSelection,
        cjgui_internal_renderer_owner_clock_ns()+10000000000ull,&outStart,&outEnd,&deferred);
    CHECK(preservePublished && preserveResourcesPrepared && preserveReady &&
        status==CJGUI_INTERNAL_RENDERER_OK && deferred==0 && overlay.activeProjectionVersion==3 &&
        [overlay.inputProxy.string isEqualToString:preservedBody],
        "empty_preserve_transport_installs_original_source_selection_request");
    while (ctx.retiringSourceProxyPreparations.count) CjguiRetireSourceProxyPreparationUnit(ctx);
    cjgui_internal_renderer_set_source_install_gate(token,71,701,0);

    // A newer native edit plus a different accepted owner body must not inherit
    // the previous generation's settlement.
    NSString *mismatchBefore=nil, *mismatchEditedBody=nil; NSRange mismatchEdit=NSMakeRange(0,0);
    BOOL mismatchCallback=SourceInstallPerformNativeAppend(overlay,@"!",&mismatchBefore,
        &mismatchEditedBody,&mismatchEdit);
    uint64_t mismatchGeneration=overlay.activeLocalEditGeneration;
    uint64_t priorSettledGeneration=overlay.activeLocalEditSettledGeneration;
    BOOL mismatchFifo=mismatchCallback && ctx.pendingInteractions.count==3 &&
        SourceInstallConsumeFixtureEditFIFO(ctx,mismatchEditedBody,@"!",mismatchEdit);
    CHECK(mismatchCallback && mismatchFifo && mismatchGeneration!=priorSettledGeneration,
        "mismatch_fixture_created_and_consumed_new_native_generation");
    NSString *relocatedBody=@"Owner accepted relocated body";
    BOOL relocatedPublished=mismatchFifo &&
        SourceInstallPublishFixtureAcceptedBody(ctx,token,4,relocatedBody,NO);
    BOOL relocatedResourcesPrepared=relocatedPublished && SourceInstallPumpActiveResourcePreparation(overlay);
    CHECK(relocatedResourcesPrepared,"relocated_scene_main_queue_resource_preparation_completed");
    CJGuiInternalQueuedInteraction *reposition=ctx.pendingInteractions.firstObject;
    BOOL exactReposition=ctx.pendingInteractions.count==1 &&
        reposition.kind==CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_SELECTION_CHANGED &&
        reposition.nodeId==401 && reposition.resourceId==1 && reposition.projectionVersion==4 &&
        reposition.selectionStart==relocatedBody.length && reposition.selectionEnd==relocatedBody.length &&
        SourceInstallConsumeJudgedInteraction(ctx,CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_SELECTION_CHANGED,401);
    CHECK(exactReposition,"relocated_mirror_owner_judged_exact_native_caret_reposition_fifo");
    BOOL remainsUnsettled=relocatedPublished && mismatchGeneration!=priorSettledGeneration &&
        overlay.activeLocalEditGeneration==mismatchGeneration &&
        overlay.activeLocalEditSettledGeneration==priorSettledGeneration &&
        [overlay.inputProxy.string isEqualToString:relocatedBody] && ctx.pendingInteractions.count==0;
    CHECK(remainsUnsettled,"different_accepted_body_does_not_settle_new_local_edit_generation");
    NSTextView *mismatchProxy=overlay.inputProxy; NSScrollView *mismatchScroll=overlay.inputScrollProxy;
    NSString *liveRelocatedBody=[overlay.inputProxy.string copy];
    NSUInteger mismatchPending=ctx.pendingInteractions.count;
    cjgui_internal_renderer_set_source_install_gate(token,71,702,1);
    status=SourceInstall(token,702,4,71,relocatedBody,(uint32_t)relocatedBody.length,
        (uint32_t)relocatedBody.length,cjgui_internal_renderer_owner_clock_ns()+10000000000ull,
        &outStart,&outEnd,&deferred);
    fprintf(stderr,"unsettled_mismatch_install status=%d deferred=%u prep=%d generation=%llu settled=%llu scene=%llu proxy_same=%d body_same=%d fifo=%lu\n",
        status,(unsigned)deferred,ctx.sourceProxyPreparation!=nil,
        (unsigned long long)overlay.activeLocalEditGeneration,
        (unsigned long long)overlay.activeLocalEditSettledGeneration,
        (unsigned long long)overlay.activeProjectionVersion,(int)(overlay.inputProxy==mismatchProxy),
        (int)[overlay.inputProxy.string isEqualToString:liveRelocatedBody],(unsigned long)ctx.pendingInteractions.count);
    CHECK(relocatedPublished && remainsUnsettled && relocatedResourcesPrepared &&
        status==CJGUI_INTERNAL_RENDERER_SCENE_STALE && deferred==0 && !ctx.sourceProxyPreparation &&
        overlay.inputProxy==mismatchProxy && overlay.inputScrollProxy==mismatchScroll &&
        [overlay.inputProxy.string isEqualToString:liveRelocatedBody] &&
        ctx.pendingInteractions.count==mismatchPending,
        "unsettled_new_generation_refuses_different_accepted_body_without_mutation");
    CjguiCancelSourceProxyPreparation(ctx);
    cjgui_internal_renderer_set_source_install_gate(token,71,702,0);
    CjguiRetireSourceProxyPreparationUnit(ctx);
    (void)cjgui_internal_renderer_destroy(token);
}

static BOOL SourceInstallRollbackIsExact(CJGuiInternalSession *ctx, CJGuiInternalComposableSceneOverlay *overlay,
    CJGuiInternalComposableSceneNode *node, NSTextView *proxy, NSScrollView *scroll,
    NSResponder *responder, NSTextStorage *storageObject, NSAttributedString *storage, NSRange selection,
    NSDictionary *overlayFields, NSDictionary *resources, NSMutableDictionary *offsets,
    NSMutableDictionary *cache, NSMutableArray *cacheOrder) {
    BOOL graph=overlay.inputProxy==proxy && overlay.inputScrollProxy==scroll && scroll.superview==overlay &&
        scroll.documentView==proxy && proxy.delegate==overlay &&
        ((CJGuiInternalComposableInputProxy *)proxy).composableOverlay==overlay;
    BOOL body=proxy.textStorage==storageObject && [proxy.textStorage isEqualToAttributedString:storage];
    BOOL selectionMatches=NSEqualRanges(proxy.selectedRange,selection);
    BOOL responderMatches=ctx.window.firstResponder==responder;
    BOOL overlayMatches=[CjguiCapturePrivateFields(overlay,CjguiSourceProxyOverlayKeys())
        isEqualToDictionary:overlayFields];
    BOOL resourcesMatch=[CjguiCapturePrivateFields(node,CjguiSourceProxyResourceKeys())
        isEqualToDictionary:resources] &&
        node.textTexture==SourceInstallCapturedValue(resources,@"textTexture") &&
        node.textTileTextures==SourceInstallCapturedValue(resources,@"textTileTextures") &&
        node.textTextureSourceCredential==SourceInstallCapturedValue(resources,@"textTextureSourceCredential") &&
        node.textTileRects==SourceInstallCapturedValue(resources,@"textTileRects");
    BOOL cachesMatch=overlay.multilineScrollOffsets==offsets && overlay.multilineLayoutCache==cache &&
        overlay.multilineLayoutCacheOrder==cacheOrder;
    fprintf(stderr,"source_install rollback_parts graph=%d body=%d selection=%d responder=%d overlay=%d resources=%d caches=%d\n",
        graph,body,selectionMatches,responderMatches,overlayMatches,resourcesMatch,cachesMatch);
    return graph && body && selectionMatches && responderMatches && overlayMatches && resourcesMatch && cachesMatch;
}

int main(void) { @autoreleasepool {
    [NSApplication sharedApplication];
    [NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];
    id<MTLDevice> device = MTLCreateSystemDefaultDevice();
    if (!device) return 2;
    CJGuiInternalSession *ctx = [CJGuiInternalSession new];
    ctx.view = [[CJGuiInternalMetalView alloc] initWithFrame:NSMakeRect(0,0,680,500)
        device:device commandQueue:[device newCommandQueue]];
    ctx.composableNodes = [NSMutableArray array];
    ctx.stagedComposableNodes = [NSMutableArray array];
    ctx.composableTextStyleRunsRaw = [NSMutableDictionary dictionary];
    SourceInstallOverlay *overlay = [[SourceInstallOverlay alloc]
        initWithFrame:NSMakeRect(0,0,680,500) session:ctx];
    overlay.testWindow = [[SourceInstallWindow alloc] initWithContentRect:NSMakeRect(0,0,680,500)
        styleMask:NSWindowStyleMaskBorderless backing:NSBackingStoreBuffered defer:YES];
    ctx.window = (NSWindow *)overlay.testWindow;
    ctx.composableSceneOverlay = overlay;
    overlay.inputProxy.delegate = nil;
    SourceInstallProxy *controlledProxy = [[SourceInstallProxy alloc] initWithFrame:overlay.inputProxy.frame];
    controlledProxy.composableOverlay = overlay;
    controlledProxy.delegate = overlay;
    controlledProxy.layoutManager.allowsNonContiguousLayout = YES;
    controlledProxy.layoutManager.backgroundLayoutEnabled = NO;
    overlay.inputProxy = controlledProxy;
    overlay.inputScrollProxy.documentView = controlledProxy;
    overlay.testWindow.contentView = overlay;
    CJGuiInternalComposableSceneNode *node = [CJGuiInternalComposableSceneNode new];
    CjguiInternalRendererComposableNode raw = {0};
    raw.nodeId=401; raw.resourceId=1; raw.projectionVersion=1;
    raw.nodeKind=CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT;
    raw.width=680; raw.height=1200; raw.clipWidth=680; raw.clipHeight=500;
    raw.fontSize=13; raw.textAlpha=1; raw.isInteractive=1;
    node.node=raw; node.index=0;
    node.value=@"A🙂e\u0301\r\nfirst source row\nsecond source row\n";
    node.styleRunsSignature=@""; node.textTextureCacheKey=@"";
    ctx.stagedComposableNodes=[NSMutableArray arrayWithObject:node];
    ctx.stagedComposableSceneVersion=1;
    ctx.stagedComposableDataTransferItems=[NSMutableArray array];
    ctx.stagedComposableDataTransferVersion=1;
    uint64_t token=CjguiAllocateSession(ctx);
    CHECK(CjguiCommitComposableSceneOnMain(token)==CJGUI_INTERNAL_RENDERER_OK,"accepted_static_setup");
    [overlay setNodesFromProjection:ctx.view.composableNodes];
    CHECK([overlay.nodes containsObject:node],"accepted_overlay_same_node");
    ctx.ownedTextSessionEnabled=YES; ctx.ownedTextSessionNodeId=401;
    ctx.ownedTextSessionResourceId=1; ctx.ownedTextSessionNodeKind=raw.nodeKind;
    ctx.ownedTextSessionBindingEpoch=71;
    overlay.applyingProjection=YES;
    overlay.inputProxy.string=@"Retained prior proxy";
    overlay.inputProxy.selectedRange=NSMakeRange(3,4);
    [overlay.inputProxy.textStorage addAttribute:@"source-install-sentinel" value:@"kept"
        range:NSMakeRange(0,overlay.inputProxy.string.length)];
    overlay.applyingProjection=NO;
    overlay.testWindow.testResponder=overlay;
    NSAttributedString *prior=[overlay.inputProxy.textStorage copy];
    NSRange priorSelection=overlay.inputProxy.selectedRange;
    uint32_t a=0,b=0; uint8_t deferred=0;
    CjguiInternalRendererStatus status=cjgui_internal_renderer_restore_composable_selection(token,401,1,
        raw.nodeKind,1,node.value.UTF8String,7,7,&a,&b);
    CHECK(status!=CJGUI_INTERNAL_RENDERER_OK && [overlay.inputProxy.textStorage isEqualToAttributedString:prior],
        "RED_legacy_restore_cannot_install_unfocused_source");
    cjgui_internal_renderer_set_source_install_gate(token,71,1,1);
#define INSTALL(req,scene,epoch,value,lo,hi,deadline) cjgui_internal_renderer_install_owned_source_selection( \
    token,401,1,scene,epoch,req,deadline,value,lo,hi,&a,&b,&deferred)
#define PRESERVED() ([overlay.inputProxy.textStorage isEqualToAttributedString:prior] && \
    NSEqualRanges(overlay.inputProxy.selectedRange,priorSelection) && overlay.testWindow.firstResponder==overlay)
    status=INSTALL(2,1,71,node.value.UTF8String,7,7,0);
    CHECK(status!=0 && PRESERVED(),"wrong_request_preserves_proxy");
    status=INSTALL(1,2,71,node.value.UTF8String,7,7,0);
    CHECK(status!=0 && PRESERVED(),"wrong_scene_preserves_proxy");
    status=INSTALL(1,1,72,node.value.UTF8String,7,7,0);
    CHECK(status!=0 && PRESERVED(),"old_binding_preserves_proxy");
    status=INSTALL(1,1,71,"unrelated source",7,7,0);
    CHECK(status!=0 && PRESERVED(),"wrong_value_preserves_proxy");
    NSUInteger calls=overlay.testWindow.responderCalls;
    status=INSTALL(1,1,71,node.value.UTF8String,7,7,1);
    CHECK(status!=0 && deferred==1 && calls==overlay.testWindow.responderCalls && PRESERVED(),
        "expired_deadline_no_install_attempt");
    for (uint32_t internal=2;internal<=6;internal+=2) {
        status=INSTALL(1,1,71,node.value.UTF8String,internal,internal,0);
        CHECK(status==CJGUI_INTERNAL_RENDERER_TEXT_RANGE_INVALID && PRESERVED(),"grapheme_crlf_internal_refused");
    }
    CjguiEnqueueComposableInteraction(ctx,CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_SELECTION_CHANGED,0,@"",NSMakeRange(1,0));
    status=INSTALL(1,1,71,node.value.UTF8String,7,7,0);
    CHECK(status!=0 && ctx.pendingInteractions.count==1 && PRESERVED(),"unjudged_selection_retained");
    [ctx.pendingInteractions removeAllObjects]; // Test consumer judges this deliberate input before retry.
    overlay.testWindow.failNextResponder=YES;
    id<MTLTexture> oldTexture=node.textTexture;
    NSArray *oldTiles=node.textTileTextures;
    NSString *oldKey=node.textTextureCacheKey;
    status=INSTALL(1,1,71,node.value.UTF8String,7,7,0);
    CHECK(status!=0 && PRESERVED() && node.textTexture==oldTexture && node.textTileTextures==oldTiles &&
        [node.textTextureCacheKey isEqualToString:oldKey],"responder_failure_exact_rollback");
    overlay.testWindow.failNextSelectionReadback=YES;
    status=INSTALL(1,1,71,node.value.UTF8String,7,7,0);
    fprintf(stderr,"readback_failure status=%d preserved=%d resource_same=%d\n",status,PRESERVED(),
        node.textTexture==oldTexture && node.textTileTextures==oldTiles);
    CHECK(status==CJGUI_INTERNAL_RENDERER_TEXT_RANGE_INVALID && PRESERVED() &&
        node.textTexture==oldTexture && node.textTileTextures==oldTiles &&
        [node.textTextureCacheKey isEqualToString:oldKey],"selection_readback_failure_exact_rollback");
    cjgui_internal_renderer_set_source_install_gate(token,71,2,1);
    cjgui_internal_renderer_set_source_install_gate(token,71,1,0);
    CHECK(CjguiSourceInstallPending(ctx) && atomic_load(&gCjguiSourceInstallRequest[token-1])==2,
        "old_clear_cannot_retire_new_request");
    calls=overlay.testWindow.responderCalls;
    uint64_t started=CjguiDiagnosticMonotonicNanoseconds();
    status=INSTALL(2,1,71,node.value.UTF8String,7,7,0);
    uint64_t elapsed=CjguiDiagnosticMonotonicNanoseconds()-started;
    CHECK(status==0 && a==7 && b==7 && CjguiInputProxyIsFirstResponder(overlay) &&
        [overlay.inputProxy.string isEqualToString:node.value] &&
        NSEqualRanges(overlay.inputProxy.selectedRange,NSMakeRange(7,0)) &&
        overlay.testWindow.responderCalls==calls+1,"single_final_selection_install");
    fprintf(stderr,"source_install elapsed_ns=%llu body_raster=%llu upload=%llu bytes=%llu\n",
        (unsigned long long)elapsed,(unsigned long long)ctx.view.testComposableTextRasterCount,
        (unsigned long long)ctx.view.testComposableTextUploadCount,(unsigned long long)node.textTextureByteCount);
    NSString *acceptedProxy=[overlay.inputProxy.string copy];
    uint64_t generation=overlay.activeTextBodyGeneration;
    BOOL allowed=[overlay textView:overlay.inputProxy shouldChangeTextInRange:NSMakeRange(7,0)
        replacementString:@"WRONG"];
    CHECK(!allowed && [overlay.inputProxy.string isEqualToString:acceptedProxy] &&
        overlay.activeTextBodyGeneration==generation &&
        [ctx.pendingInteractions.lastObject.formText hasPrefix:@"selection_install_pending:"],
        "pending_install_refuses_input_before_proxy_mutation");
    [ctx.pendingInteractions removeAllObjects];
    cjgui_internal_renderer_set_source_install_gate(token,71,2,0);
    CHECK(!CjguiSourceInstallPending(ctx),"matching_completion_opens_input");
    [ctx.pendingInteractions removeAllObjects];
    [overlay beginTextSelectionForNode:node atPoint:NSMakePoint(45,14)];
    CJGuiInternalQueuedInteraction *pointerSelection=ctx.pendingInteractions.lastObject;
    CHECK(pointerSelection.kind==CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_SELECTION_CHANGED &&
        pointerSelection.hasPrecisePointer && pointerSelection.nodeId==401 &&
        pointerSelection.projectionVersion==1,"fresh_pointer_selection_has_provenance");
    // A later non-pointer notification must not inherit the pointer's origin
    // when the ordinary consecutive-selection coalescing path replaces it.
    CjguiStampPointerPositionOnQueuedInteraction(ctx,
        CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_SELECTION_CHANGED,0,NSMakePoint(45,14));
    CjguiEnqueueComposableInteraction(ctx,CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_SELECTION_CHANGED,
        0,@"",overlay.inputProxy.selectedRange);
    CHECK(!ctx.pendingInteractions.lastObject.hasPrecisePointer,"nonpointer_coalesce_clears_pointer_provenance");
    [ctx.pendingInteractions removeAllObjects];
    // A same-body selection-only recovery must keep ordinary owned arrows
    // in FIFO order while edits stay gated. Exercise keyDown before the
    // selector interception, not only the selector test seam.
    cjgui_internal_renderer_set_source_install_gate(token,71,3,1);
    for (NSUInteger i=0;i<40;++i) {
        NSString *arrow = [NSString stringWithFormat:@"%C", i%2==0 ? NSLeftArrowFunctionKey : NSRightArrowFunctionKey];
        NSEvent *key = [NSEvent keyEventWithType:NSEventTypeKeyDown location:NSZeroPoint
            modifierFlags:0 timestamp:(NSTimeInterval)i/1000 windowNumber:0 context:nil
            characters:arrow charactersIgnoringModifiers:arrow isARepeat:i>0 keyCode:i%2==0 ? 123 : 124];
        [overlay.inputProxy keyDown:key];
    }
    BOOL ordered=ctx.pendingInteractions.count==40;
    for (NSUInteger i=0;i<ctx.pendingInteractions.count;++i)
        ordered=ordered && ctx.pendingInteractions[i].kind==CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_NAVIGATE &&
            [ctx.pendingInteractions[i].formText isEqualToString:i%2==0 ? @"left" : @"right"];
    fprintf(stderr,"rapid_navigation count=%lu active=%llu:%lld:%u projection=%llu own=%d\n",
        (unsigned long)ctx.pendingInteractions.count,(unsigned long long)overlay.activeNodeId,
        (long long)overlay.activeNodeResourceId,overlay.activeNodeKind,
        (unsigned long long)overlay.activeProjectionVersion,[overlay activeNodeOwnsCompositionSession]);
    for (NSUInteger i=0;i<MIN(4,ctx.pendingInteractions.count);++i)
        fprintf(stderr,"rapid_item index=%lu kind=%u text=%s\n",(unsigned long)i,
            ctx.pendingInteractions[i].kind,ctx.pendingInteractions[i].formText.UTF8String);
    CHECK(ordered,"rapid_navigation_fifo_no_coalescing");
    [ctx.pendingInteractions removeAllObjects];
    NSEvent *leftKey = [NSEvent keyEventWithType:NSEventTypeKeyDown location:NSZeroPoint
        modifierFlags:0 timestamp:1 windowNumber:0 context:nil
        characters:[NSString stringWithFormat:@"%C", NSLeftArrowFunctionKey]
        charactersIgnoringModifiers:[NSString stringWithFormat:@"%C", NSLeftArrowFunctionKey]
        isARepeat:NO keyCode:123];
    NSString *currentValue = node.value;
    node.value = [currentValue stringByAppendingString:@"new body"];
    [overlay.inputProxy keyDown:leftKey];
    CHECK(ctx.pendingInteractions.count == 1 &&
        [ctx.pendingInteractions.lastObject.formText hasPrefix:@"selection_install_pending:"],
        "pending_arrow_new_body_refused");
    node.value = currentValue;
    [ctx.pendingInteractions removeAllObjects];
    overlay.activeNodeResourceId += 1;
    [overlay.inputProxy keyDown:leftKey];
    CHECK(ctx.pendingInteractions.count == 1 &&
        [ctx.pendingInteractions.lastObject.formText hasPrefix:@"selection_install_pending:"],
        "pending_arrow_other_binding_refused");
    overlay.activeNodeResourceId -= 1;
    [ctx.pendingInteractions removeAllObjects];
    overlay.activeLocalEditAwaitingOwner = YES;
    [overlay.inputProxy keyDown:leftKey];
    CHECK(ctx.pendingInteractions.count == 1 &&
        [ctx.pendingInteractions.lastObject.formText hasPrefix:@"selection_install_pending:"],
        "pending_arrow_unacknowledged_edit_refused");
    overlay.activeLocalEditAwaitingOwner = NO;
    [ctx.pendingInteractions removeAllObjects];
    overlay.activeProjectionVersion = 0;
    [overlay.inputProxy keyDown:leftKey];
    CHECK(ctx.pendingInteractions.count == 1 &&
        [ctx.pendingInteractions.lastObject.formText hasPrefix:@"selection_install_pending:"],
        "pending_arrow_stale_projection_refused");
    overlay.activeProjectionVersion = 1;
    [ctx.pendingInteractions removeAllObjects];
    cjgui_internal_renderer_set_source_install_gate(token,71,3,0);
    // A budgeted call creates a private graph but must not mutate the live
    // adapter, accepted resources, interaction FIFO, or present counters.
    overlay.applyingProjection=YES;
    overlay.inputProxy.string=@"Retained during independent preparation";
    overlay.inputProxy.selectedRange=NSMakeRange(3,4);
    overlay.applyingProjection=NO;
    overlay.testWindow.testResponder=overlay;
    NSTextView *parkedPriorProxy=overlay.inputProxy;
    NSAttributedString *parkedPriorStorage=[overlay.inputProxy.textStorage copy];
    oldTexture=node.textTexture;
    oldTiles=node.textTileTextures;
    oldKey=node.textTextureCacheKey;
    NSUInteger queuedBefore=ctx.pendingInteractions.count;
    uint64_t rasterBefore=ctx.view.testComposableTextRasterCount;
    uint64_t uploadBefore=ctx.view.testComposableTextUploadCount;
    uint32_t drawBefore=ctx.view.testComposableTextureDrawCount;
    NSDictionary *liveFieldsBefore=CjguiCapturePrivateFields(overlay,CjguiSourceProxyOverlayKeys());
    NSDictionary *resourceFieldsBefore=CjguiCapturePrivateFields(node,CjguiSourceProxyResourceKeys());
    cjgui_internal_renderer_set_source_install_gate(token,71,500,1);
    uint64_t preparationDeadline=cjgui_internal_renderer_owner_clock_ns()+4000000;
    status=INSTALL(500,1,71,node.value.UTF8String,7,7,preparationDeadline);
    CHECK(status==CJGUI_INTERNAL_RENDERER_SCENE_STALE && deferred==1 && ctx.sourceProxyPreparation &&
        ctx.sourceProxyPreparation.phase==0 && ctx.sourceProxyPreparation.overlay==nil &&
        overlay.inputProxy==parkedPriorProxy &&
        [overlay.inputProxy.textStorage isEqualToAttributedString:parkedPriorStorage] &&
        NSEqualRanges(overlay.inputProxy.selectedRange,NSMakeRange(3,4)) &&
        overlay.testWindow.firstResponder==overlay && node.textTexture==oldTexture &&
        node.textTileTextures==oldTiles && [node.textTextureCacheKey isEqualToString:oldKey] &&
        ctx.pendingInteractions.count==queuedBefore && ctx.view.testComposableTextRasterCount==rasterBefore &&
        ctx.view.testComposableTextUploadCount==uploadBefore && ctx.view.testComposableTextureDrawCount==drawBefore &&
        [CjguiCapturePrivateFields(overlay,CjguiSourceProxyOverlayKeys()) isEqualToDictionary:liveFieldsBefore] &&
        [CjguiCapturePrivateFields(node,CjguiSourceProxyResourceKeys()) isEqualToDictionary:resourceFieldsBefore],
        "prep_first_unit_private_only_no_fifo_present_or_live_resource_side_effects");

    CHECK(SourceInstallPrepareToReady(ctx,token,500,1,71,node.value,7,7,&a,&b),
        "prep_pipeline_reaches_ready_in_bounded_units");
    CjguiSourceProxyPreparation *ready=ctx.sourceProxyPreparation;
    NSTextView *preparedProxy=ready.overlay.inputProxy;
    NSScrollView *preparedScroll=ready.overlay.inputScrollProxy;
    NSTextStorage *preparedStorage=preparedProxy.textStorage;
    NSLayoutManager *preparedLayoutManager=preparedProxy.layoutManager;
    NSTextContainer *preparedContainer=preparedProxy.textContainer;
    NSMutableDictionary *preparedOffsets=ready.overlay.multilineScrollOffsets;
    NSMutableDictionary *preparedCache=ready.overlay.multilineLayoutCache;
    NSMutableArray *preparedCacheOrder=ready.overlay.multilineLayoutCacheOrder;
    CjguiPreparedTextNodeLayout *preparedPainter=ready.painter;
    id<MTLTexture> preparedTexture=ready.target.textTexture;
    NSArray *preparedTiles=ready.target.textTileTextures;
    NSString *preparedKey=ready.target.textTextureCacheKey;
    id preparedCredential=ready.target.textTextureSourceCredential;
    uint64_t rasterAtReady=ctx.view.testComposableTextRasterCount;
    uint64_t uploadAtReady=ctx.view.testComposableTextUploadCount;
    uint64_t sealedAtReady=CjguiTestSealedRasterLayoutCreateCount;
    NSTextView *oldProxyForAdoption=overlay.inputProxy;
    NSScrollView *oldScrollForAdoption=overlay.inputScrollProxy;
    NSAttributedString *oldBodyForAdoption=[oldProxyForAdoption.textStorage copy];
    NSRange oldSelectionForAdoption=oldProxyForAdoption.selectedRange;
    status=INSTALL(500,1,71,node.value.UTF8String,7,7,cjgui_internal_renderer_owner_clock_ns()+10000000000ull);
    BOOL liveAdopted=status==CJGUI_INTERNAL_RENDERER_OK && deferred==0 && overlay.inputProxy==preparedProxy &&
        overlay.inputScrollProxy==preparedScroll && preparedScroll.documentView==preparedProxy &&
        preparedScroll.superview==overlay && preparedProxy.delegate==overlay &&
        ((CJGuiInternalComposableInputProxy *)preparedProxy).composableOverlay==overlay &&
        preparedProxy.textStorage==preparedStorage &&
        preparedProxy.layoutManager==preparedLayoutManager && preparedProxy.textContainer==preparedContainer &&
        overlay.multilineScrollOffsets==preparedOffsets && overlay.multilineLayoutCache==preparedCache &&
        overlay.multilineLayoutCacheOrder==preparedCacheOrder && node.textTexture==preparedTexture &&
        node.textTileTextures==preparedTiles && node.textTextureSourceCredential==preparedCredential &&
        [node.textTextureCacheKey isEqualToString:preparedKey] && ready.painter==preparedPainter &&
        ctx.view.testComposableTextRasterCount==rasterAtReady && ctx.view.testComposableTextUploadCount==uploadAtReady &&
        CjguiTestSealedRasterLayoutCreateCount==sealedAtReady;
    BOOL oldGraphRetired=[ctx.retiringSourceProxyPreparations containsObject:ready] &&
        ready.overlay.inputProxy==oldProxyForAdoption && ready.overlay.inputScrollProxy==oldScrollForAdoption &&
        oldScrollForAdoption.superview==ready.overlay && oldProxyForAdoption.enclosingScrollView==oldScrollForAdoption &&
        ![overlay.subviews containsObject:oldScrollForAdoption] &&
        [oldProxyForAdoption.textStorage isEqualToAttributedString:oldBodyForAdoption] &&
        NSEqualRanges(oldProxyForAdoption.selectedRange,oldSelectionForAdoption) &&
        oldProxyForAdoption.delegate==nil && ((CJGuiInternalComposableInputProxy *)oldProxyForAdoption).composableOverlay==nil;
    fprintf(stderr,"source_install adoption_parts live_prepared_graph=%d retired_old_graph=%d\n",
        liveAdopted,oldGraphRetired);
    CHECK(liveAdopted && oldGraphRetired,
        "prep_adopts_same_proxy_scroll_storage_layout_resources_without_final_work_or_old_body_write");
    cjgui_internal_renderer_set_source_install_gate(token,71,500,0);

    // A same-value newer ticket has distinct identity; the old preparation
    // cannot be adopted and an older clear cannot remove the new ticket.
    cjgui_internal_renderer_set_source_install_gate(token,71,510,1);
    status=INSTALL(510,1,71,node.value.UTF8String,7,7,cjgui_internal_renderer_owner_clock_ns()+10000000000ull);
    cjgui_internal_renderer_set_source_install_gate(token,71,511,1);
    status=INSTALL(510,1,71,node.value.UTF8String,7,7,cjgui_internal_renderer_owner_clock_ns()+10000000000ull);
    CHECK(status!=CJGUI_INTERNAL_RENDERER_OK && deferred==0 && ctx.sourceProxyPreparation==nil,
        "same_value_new_request_cannot_adopt_old_preparation");
    cjgui_internal_renderer_set_source_install_gate(token,71,510,0);
    CHECK(CjguiSourceInstallPending(ctx) && atomic_load(&gCjguiSourceInstallRequest[token-1])==511,
        "old_clear_cannot_clear_new_same_value_request");
    cjgui_internal_renderer_set_source_install_gate(token,71,511,0);
    while (ctx.retiringSourceProxyPreparations.count) CjguiRetireSourceProxyPreparationUnit(ctx);

#define BEGIN_PREP(req) do { \
    cjgui_internal_renderer_set_source_install_gate(token,71,req,1); \
    status=SourceInstall(token,req,1,71,node.value,7,7,cjgui_internal_renderer_owner_clock_ns()+10000000000ull, \
        &a,&b,&deferred); \
    CHECK(status==CJGUI_INTERNAL_RENDERER_SCENE_STALE && deferred==1 && ctx.sourceProxyPreparation, \
        "prep_invalidation_candidate_created"); \
    SourceInstall(token,req,1,71,node.value,7,7,cjgui_internal_renderer_owner_clock_ns()+10000000000ull, \
        &a,&b,&deferred); \
} while (0)
#define INVALIDATE_AND_CHECK(req,condition,label) do { \
    status=SourceInstall(token,req,1,71,node.value,7,7,cjgui_internal_renderer_owner_clock_ns()+10000000000ull, \
        &a,&b,&deferred); \
    CHECK(status!=CJGUI_INTERNAL_RENDERER_OK && ctx.sourceProxyPreparation==nil && (condition),label); \
    cjgui_internal_renderer_set_source_install_gate(token,71,req,0); \
    while (ctx.retiringSourceProxyPreparations.count) CjguiRetireSourceProxyPreparationUnit(ctx); \
} while (0)

    BEGIN_PREP(520);
    NSRange selectionBeforeMutation=overlay.inputProxy.selectedRange;
    NSUInteger fifoBeforeSelection=ctx.pendingInteractions.count;
    overlay.inputProxy.selectedRange=NSMakeRange(8,0);
    INVALIDATE_AND_CHECK(520,NSEqualRanges(overlay.inputProxy.selectedRange,NSMakeRange(8,0)) &&
        !NSEqualRanges(selectionBeforeMutation,overlay.inputProxy.selectedRange) &&
        ctx.pendingInteractions.count==fifoBeforeSelection+1 &&
        ctx.pendingInteractions.lastObject.kind==CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_SELECTION_CHANGED &&
        ctx.pendingInteractions.lastObject.nodeId==401,
        "prep_selection_change_invalidates_and_keeps_live_selection");
    // At this isolated consumer boundary the owner receives and judges that
    // exact selection event. Consume one item only; preserve unexpected FIFO.
    CHECK(SourceInstallConsumeJudgedInteraction(ctx,
        CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_SELECTION_CHANGED,401),
        "prep_selection_fifo_observed_then_owner_judged_one_event");

    BEGIN_PREP(521);
    [overlay.inputProxy.layoutManager addTemporaryAttribute:NSForegroundColorAttributeName value:NSColor.redColor
        forCharacterRange:NSMakeRange(0,1)];
    NSArray *temporaryAfter=[CjguiFreezeTemporaryAttributeRuns(overlay.inputProxy.layoutManager,
        overlay.inputProxy.textStorage.length) copy];
    INVALIDATE_AND_CHECK(521,[CjguiFreezeTemporaryAttributeRuns(overlay.inputProxy.layoutManager,
        overlay.inputProxy.textStorage.length) isEqualToArray:temporaryAfter],
        "prep_temporary_attributes_invalidate_and_remain");

    BEGIN_PREP(522);
    ctx.composableTextStyleRunsRaw[@401]=@"{\"bold\":true}";
    INVALIDATE_AND_CHECK(522,[ctx.composableTextStyleRunsRaw[@401] isEqualToString:@"{\"bold\":true}"],
        "prep_style_runs_change_invalidates_and_remains");
    ctx.composableTextStyleRunsRaw[@401]=@"";

    // The old live body differs from the accepted source. The current owner
    // credential does not authorize applying that input under either source.
    overlay.applyingProjection=YES;
    overlay.inputProxy.string=@"Old source changed without owner credential";
    overlay.inputProxy.selectedRange=NSMakeRange(4,0);
    overlay.applyingProjection=NO;
    BEGIN_PREP(523);
    NSString *changedSource=overlay.inputProxy.string;
    NSUInteger fifoBeforeInput=ctx.pendingInteractions.count;
    BOOL acceptedOldInput=[overlay textView:overlay.inputProxy shouldChangeTextInRange:NSMakeRange(0,0)
        replacementString:@"x"];
    CHECK(!acceptedOldInput && [overlay.inputProxy.string isEqualToString:changedSource] &&
        ctx.pendingInteractions.count==fifoBeforeInput+1 &&
        ctx.pendingInteractions.lastObject.kind==CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_NAVIGATE &&
        ctx.pendingInteractions.lastObject.nodeId==401 &&
        [ctx.pendingInteractions.lastObject.formText hasPrefix:@"selection_install_pending:"],
        "prep_changed_source_text_named_refused_owner_credential_unresolved");
    status=SourceInstall(token,523,1,71,node.value,7,7,cjgui_internal_renderer_owner_clock_ns()+10000000000ull,
        &a,&b,&deferred);
    CHECK(status!=CJGUI_INTERNAL_RENDERER_OK && ctx.sourceProxyPreparation==nil &&
        [overlay.inputProxy.string isEqualToString:changedSource] &&
        ctx.pendingInteractions.count==fifoBeforeInput+1,
        "prep_changed_source_input_invalidates_candidate_and_retains_live_body");
    CHECK(SourceInstallConsumeJudgedInteraction(ctx,
        CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_NAVIGATE,401),
        "prep_input_refusal_fifo_observed_then_owner_judged_one_event");
    while (ctx.retiringSourceProxyPreparations.count) CjguiRetireSourceProxyPreparationUnit(ctx);

    BEGIN_PREP(526);
    NSUInteger retirementsBeforeCancel=ctx.retiringSourceProxyPreparations.count;
    CjguiCancelSourceProxyPreparation(ctx); CjguiCancelSourceProxyPreparation(ctx);
    CHECK(ctx.sourceProxyPreparation==nil &&
        ctx.retiringSourceProxyPreparations.count==retirementsBeforeCancel+1,
        "prep_cancel_idempotent_single_retirement");
    NSUInteger retireBound=ctx.retiringSourceProxyPreparations.firstObject.textures.count+4;
    NSUInteger retiredUnits=0;
    while (ctx.retiringSourceProxyPreparations.count && retiredUnits<retireBound) {
        CjguiRetireSourceProxyPreparationUnit(ctx); retiredUnits++;
    }
    CHECK(ctx.retiringSourceProxyPreparations.count==0 && retiredUnits<=retireBound,
        "prep_cancel_retirement_bounded_by_resources_and_graph");
    overlay.applyingProjection=YES;
    overlay.inputProxy.string=node.value;
    overlay.inputProxy.selectedRange=NSMakeRange(7,0);
    overlay.applyingProjection=NO;
    cjgui_internal_renderer_set_source_install_gate(token,71,523,0);
    cjgui_internal_renderer_set_source_install_gate(token,71,526,0);

    BEGIN_PREP(524);
    ctx.composableSceneVersion=2;
    status=SourceInstall(token,524,2,71,node.value,7,7,cjgui_internal_renderer_owner_clock_ns()+10000000000ull,
        &a,&b,&deferred);
    CHECK(status!=CJGUI_INTERNAL_RENDERER_OK && ctx.sourceProxyPreparation==nil &&
        overlay.inputProxy==preparedProxy && node.textTexture==preparedTexture,
        "prep_scene_agent_version_change_rejects_candidate");
    ctx.composableSceneVersion=1; cjgui_internal_renderer_set_source_install_gate(token,71,524,0);
    while (ctx.retiringSourceProxyPreparations.count) CjguiRetireSourceProxyPreparationUnit(ctx);

    BEGIN_PREP(525);
    ctx.ownedTextSessionBindingEpoch=72;
    status=SourceInstall(token,525,1,72,node.value,7,7,cjgui_internal_renderer_owner_clock_ns()+10000000000ull,
        &a,&b,&deferred);
    CHECK(status!=CJGUI_INTERNAL_RENDERER_OK && ctx.sourceProxyPreparation==nil &&
        overlay.inputProxy==preparedProxy && node.textTexture==preparedTexture,
        "prep_binding_change_rejects_candidate");
    ctx.ownedTextSessionBindingEpoch=71; cjgui_internal_renderer_set_source_install_gate(token,71,525,0);
    while (ctx.retiringSourceProxyPreparations.count) CjguiRetireSourceProxyPreparationUnit(ctx);

#define PREPARE_INJECTED_FAILURE(req) do { \
    cjgui_internal_renderer_set_source_install_gate(token,71,req,1); \
    SourceInstall(token,req,1,71,node.value,7,7,cjgui_internal_renderer_owner_clock_ns()+10000000000ull, \
        &a,&b,&deferred); \
    SourceInstall(token,req,1,71,node.value,7,7,cjgui_internal_renderer_owner_clock_ns()+10000000000ull, \
        &a,&b,&deferred); \
    SourceInstallReplacePreparedProxy(ctx.sourceProxyPreparation); \
    CHECK(SourceInstallPrepareToReady(ctx,token,req,1,71,node.value,7,7,&a,&b), \
        "injected_preparation_reaches_ready"); \
} while (0)
#define CHECK_ADOPTION_ROLLBACK(req,inject,label) do { \
    NSTextView *savedProxy=overlay.inputProxy; NSScrollView *savedScroll=overlay.inputScrollProxy; \
    NSResponder *savedResponder=overlay.testWindow.firstResponder; \
    NSTextStorage *savedStorageObject=savedProxy.textStorage; \
    NSAttributedString *savedStorage=[savedProxy.textStorage copy]; NSRange savedSelection=savedProxy.selectedRange; \
    NSDictionary *savedOverlay=CjguiCapturePrivateFields(overlay,CjguiSourceProxyOverlayKeys()); \
    NSDictionary *savedResources=CjguiCapturePrivateFields(node,CjguiSourceProxyResourceKeys()); \
    NSMutableDictionary *savedOffsets=overlay.multilineScrollOffsets,*savedCache=overlay.multilineLayoutCache; \
    NSMutableArray *savedOrder=overlay.multilineLayoutCacheOrder; \
    inject; \
    status=SourceInstall(token,req,1,71,node.value,7,7,cjgui_internal_renderer_owner_clock_ns()+10000000000ull, \
        &a,&b,&deferred); \
    CHECK(status!=CJGUI_INTERNAL_RENDERER_OK && \
        SourceInstallRollbackIsExact(ctx,overlay,node,savedProxy,savedScroll,savedResponder,savedStorageObject,savedStorage, \
            savedSelection,savedOverlay,savedResources,savedOffsets,savedCache,savedOrder),label); \
    CjguiCancelSourceProxyPreparation(ctx); \
    cjgui_internal_renderer_set_source_install_gate(token,71,req,0); \
    while (ctx.retiringSourceProxyPreparations.count) CjguiRetireSourceProxyPreparationUnit(ctx); \
} while (0)

    // A stable input host deliberately avoids a no-op responder transition.
    // Inject failure on a real focus acquisition from the non-text overlay.
    overlay.testWindow.testResponder=overlay;
    PREPARE_INJECTED_FAILURE(530);
    CHECK_ADOPTION_ROLLBACK(530,overlay.testWindow.failNextResponder=YES,
        "budgeted_responder_failure_exact_live_rollback");
    PREPARE_INJECTED_FAILURE(531);
    CHECK_ADOPTION_ROLLBACK(531,overlay.testWindow.failNextSelectionReadback=YES,
        "budgeted_selection_readback_failure_exact_live_rollback");

    PREPARE_INJECTED_FAILURE(532);
    NSTextView *markedPrior=overlay.inputProxy; NSScrollView *markedScroll=overlay.inputScrollProxy;
    NSResponder *markedResponder=overlay.testWindow.firstResponder;
    NSTextStorage *markedStorageObject=markedPrior.textStorage;
    NSAttributedString *markedStorage=[markedPrior.textStorage copy]; NSRange markedSelection=markedPrior.selectedRange;
    NSDictionary *markedOverlay=CjguiCapturePrivateFields(overlay,CjguiSourceProxyOverlayKeys());
    NSDictionary *markedResources=CjguiCapturePrivateFields(node,CjguiSourceProxyResourceKeys());
    NSMutableDictionary *markedOffsets=overlay.multilineScrollOffsets,*markedCache=overlay.multilineLayoutCache;
    NSMutableArray *markedOrder=overlay.multilineLayoutCacheOrder;
    NSUInteger fifoBeforeMarked=ctx.pendingInteractions.count;
    BOOL actualMarked=SourceInstallSetActualMarkedText(ctx.sourceProxyPreparation.overlay.inputProxy,@"compose");
    CHECK(actualMarked && ctx.sourceProxyPreparation.overlay.inputProxy.hasMarkedText &&
        ctx.pendingInteractions.count==fifoBeforeMarked,
        "marked_private_textkit_state_injected_without_live_fifo_notice");
    status=SourceInstall(token,532,1,71,node.value,7,7,cjgui_internal_renderer_owner_clock_ns()+10000000000ull,
        &a,&b,&deferred);
    CHECK(status!=CJGUI_INTERNAL_RENDERER_OK && ctx.sourceProxyPreparation==nil &&
        SourceInstallRollbackIsExact(ctx,overlay,node,markedPrior,markedScroll,markedResponder,markedStorageObject,markedStorage,
            markedSelection,markedOverlay,markedResources,markedOffsets,markedCache,markedOrder) &&
        ctx.retiringSourceProxyPreparations.count>0,
        "marked_text_blocks_budgeted_adoption_with_exact_live_rollback");
    cjgui_internal_renderer_set_source_install_gate(token,71,532,0);
    while (ctx.retiringSourceProxyPreparations.count) CjguiRetireSourceProxyPreparationUnit(ctx);

    cjgui_internal_renderer_set_source_install_gate(token,71,540,1);
    SourceInstall(token,540,1,71,node.value,7,7,cjgui_internal_renderer_owner_clock_ns()+10000000000ull,
        &a,&b,&deferred);
    CHECK(ctx.sourceProxyPreparation!=nil,"close_cleanup_has_live_preparation");
    CHECK(cjgui_internal_renderer_destroy(token)==CJGUI_INTERNAL_RENDERER_OK &&
        ctx.sourceProxyPreparation==nil && ctx.retiringSourceProxyPreparations.count==0 &&
        CjguiLookupSession(token)==nil,"close_retires_preparation_bundle_and_session");
    SourceInstallRunSettledLocalEditFixture(device);
#undef CHECK_ADOPTION_ROLLBACK
#undef PREPARE_INJECTED_FAILURE
#undef INVALIDATE_AND_CHECK
#undef BEGIN_PREP
#undef INSTALL
#undef PRESERVED
    return failures ? 1 : 0;
} }

// Ordinary images share the real private scene preparation and resource domain.
#define CJGUI_PREPARATION_OWNER_QUEUE_HELPERS_ONLY
#import "composable_preparation_owner_queue_test.m"

int main(void) { @autoreleasepool {
    [NSApplication sharedApplication];
    [NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];
    CJGuiInternalSession *ctx = nil; uint64_t token = 0;
    if (!makeSession(&ctx, &token)) return 2;
    // The shared text fixture deliberately omits the normal image domain.
    // Install the same real device/domain association as renderer create.
    ctx.device=ctx.view.device;
    ctx.composableImageDomain=[[CJGuiInternalComposableImageResourceDomain alloc] initWithDevice:ctx.device];
    NSArray *accepted = ctx.composableNodes;
    CHECK(cjgui_internal_renderer_begin_composable_preparation(token, 40, 1, 2, 1) == 0,
        "ordinary_image_uses_existing_private_candidate");
    CjguiInternalRendererComposableNode node = {0};
    node.nodeId = 201; node.resourceId = 9; node.projectionVersion = 2;
    node.nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_IMAGE;
    node.width = node.height = node.clipWidth = node.clipHeight = 32;
    CjguiInternalRendererComposableGeometry geometry = {0};
    geometry.nodeId = node.nodeId; geometry.scaleX = geometry.scaleY = 1;
    CjguiInternalRendererStatus status = cjgui_internal_renderer_prepare_composable_node(
        token, 40, 0, &node, &geometry, "ordinary image", "", "image", "image", "", "", "image", "");
    CHECK(status == CJGUI_INTERNAL_RENDERER_OK,
        "ordinary_image_declaration_admitted_without_synchronous_scene_fallback");
    CHECK(ctx.composableNodes == accepted && ctx.composableSceneVersion == 1,
        "image_preparation_does_not_publish_partial_scene");
    if (status == CJGUI_INTERNAL_RENDERER_OK) {
        NSString *source=[@(__FILE__) stringByDeletingLastPathComponent];
        source=[source stringByAppendingPathComponent:@"../../examples/rule_set_window_app/composable-beacon.png"].stringByStandardizingPath;
        CHECK([NSFileManager.defaultManager fileExistsAtPath:source], "real_normal_consumer_image_exists");
        ctx.testComposableImageLaunchGateHeld=YES;
        CHECK(cjgui_internal_renderer_prepare_composable_image_node_resource(token,40,0,source.UTF8String,"ordinary",1)==0,
            "immutable_image_identity_version_uses_existing_domain");
        CjguiComposablePreparation *original=ctx.composablePreparation;
        CJGuiInternalComposableSceneNode *pending=original.nodes[0];
        NSString *key=pending.imageTextureCacheKey;
        CJGuiInternalComposableImageResourceDomain *domain=CjguiComposableImageDomainForSession(ctx);
        CHECK(key.length>0 && !pending.imageTexture && domain.pendingKeys.count==1,
            "pending_resource_keeps_original_candidate_without_partial_publication");
        gCjguiMainThreadDispatchEnabled=YES;
        CjguiInternalRendererStatus advanceStatus=-1;uint32_t ready=UINT32_MAX;
        CHECK(ownerAdvance(token,40,nowNs()+1000000000,&advanceStatus,&ready) && advanceStatus==0 && !ready,
            "pending_image_owner_advance_nonblocking");
        CHECK(drainQueueService(token) && queueTicket(token,NULL).state==1 && original.nodeCursor==0,
            "pending_image_is_not_fake_completion_or_empty_wake");
        uint64_t before=cjgui_internal_renderer_owner_work_revision();
        ctx.testComposableImageLaunchGateHeld=NO;CjguiStartNextComposableImageLoads(domain);
        uint64_t limit=nowNs()+5000000000ull;
        while (!original.ready && nowNs()<limit) {
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:.001]];
            (void)ownerAdvance(token,40,nowNs()+200000000,&advanceStatus,&ready);
        }
        CHECK(original.ready && advanceStatus==0 && pending.imageTexture &&
            [pending.imageTextureContentKey isEqualToString:key], "real_completion_resumes_original_private_image_graph");
        CHECK(cjgui_internal_renderer_owner_work_revision()>before && ctx.composableNodes==accepted &&
            ctx.composableSceneVersion==1, "private_completion_wakes_without_publishing_stale_scene");
        id<MTLTexture> retained=pending.imageTexture;
        uint64_t decodes=domain.imageDecodeStartCount;
        [domain.textureCache removeAllObjects];domain.resources[key].texture=nil;
        NSString *againKey=nil;uint32_t state=0;
        CHECK(retained && CjguiComposableImageTexture(ctx,token,source,@"ordinary",1,nil,&againKey,&state)==retained &&
            domain.imageDecodeStartCount==decodes, "cache_eviction_preserves_exact_preparation_texture_without_decode");
        CHECK(cjgui_internal_renderer_prepare_composable_image_node_resource(token,40,0,source.UTF8String,"ordinary",2)!=0 &&
            pending.imageResourceVersion==1, "duplicate_or_mutated_declaration_rejected");
        (void)cjgui_internal_renderer_cancel_composable_preparation(token,40);
        CHECK(!ctx.composablePreparation && !domain.resources[key].requesters.count &&
            !domain.resources[key].subscribers.count, "cancel_restores_only_accepted_image_demand");
        CHECK(cjgui_internal_renderer_begin_composable_preparation(token,41,1,3,1)==0,
            "new_image_generation_uses_new_preparation");
        node.projectionVersion=3;
        CHECK(cjgui_internal_renderer_prepare_composable_node(token,41,0,&node,&geometry,"image","","image","image","","","image","")==0,
            "new_image_pod_is_private");
        ctx.testComposableImageLaunchGateHeld=YES;
        CHECK(cjgui_internal_renderer_prepare_composable_image_node_resource(token,41,0,source.UTF8String,"ordinary",2)==0,
            "replacement_image_keeps_version_two_identity");
        CJGuiInternalComposableSceneNode *replacement=ctx.composablePreparation.nodes[0];
        CHECK(![replacement.imageTextureCacheKey isEqualToString:key], "replacement_never_relabels_old_texture_as_new_generation");
        (void)cjgui_internal_renderer_cancel_composable_preparation(token,41);
        ctx.testComposableImageLaunchGateHeld=NO;CjguiStartNextComposableImageLoads(domain);
        CHECK(!ctx.composablePreparation && ctx.composableNodes==accepted && ctx.composableSceneVersion==1,
            "cancelled_replacement_never_publishes");
        CHECK(cjgui_internal_renderer_begin_composable_preparation(token,42,1,4,1)==0,
            "missing_asset_uses_same_preparation_protocol");
        node.projectionVersion=4;
        CHECK(cjgui_internal_renderer_prepare_composable_node(token,42,0,&node,&geometry,"image","","image","image","","","image","")==0,
            "missing_asset_pod_is_private");
        CHECK(cjgui_internal_renderer_prepare_composable_image_node_resource(token,42,0,"cjgui-transfer:unadmitted","transfer",0)==
            CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED,
            "transfer_does_not_bypass_original_payload_admission");
        NSString *missing=[source stringByAppendingString:@".missing"];
        CHECK(cjgui_internal_renderer_prepare_composable_image_node_resource(token,42,0,missing.UTF8String,"missing",1)==0,
            "missing_asset_has_explicit_resource_identity");
        CjguiComposablePreparation *failedAsset=ctx.composablePreparation;
        limit=nowNs()+5000000000ull;
        while (!failedAsset.ready && nowNs()<limit) {
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:.001]];
            (void)ownerAdvance(token,42,nowNs()+200000000,&advanceStatus,&ready);
        }
        CHECK(failedAsset.ready && advanceStatus==0 && !failedAsset.nodes[0].imageTexture &&
            ctx.composableNodes==accepted, "failed_image_keeps_placeholder_contract_and_terminates_pending");
        (void)cjgui_internal_renderer_cancel_composable_preparation(token,42);
    }
    (void)cjgui_internal_renderer_cancel_composable_preparation(token, 40);
    (void)cjgui_internal_renderer_destroy(token);
    return failures ? 1 : 0;
}}

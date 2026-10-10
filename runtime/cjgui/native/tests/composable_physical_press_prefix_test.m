// Controlled producer seal counterexamples; the window fixture covers the real
// mouse entry, ticket handoff, lease and action. No foreground input here.
#define CJGUI_INTERNAL_TESTING 1
#import "../cjgui_internal_renderer.m"

static int failures=0, checks=0;
#define CHECK(x,name) do { checks++; if (!(x)) { failures++; fprintf(stderr,"FAIL %s\n",name); } } while(0)

static CJGuiInternalSession *fixture(NSUInteger count) {
    CJGuiInternalSession *ctx=[CJGuiInternalSession new];
    ctx.sessionGeneration=7; ctx.composableSceneVersion=3;
    ctx.ownedTextSessionBindingEpoch=9; ctx.inputDequeueSerial=4;
    ctx.physicalProducerDepth=1; ctx.physicalProducerNonce=12;
    ctx.pendingInteractions=[NSMutableArray array];
    ctx.composableNodes=[NSMutableArray array];
    for (uint32_t i=0;i<2;i++) {
        CJGuiInternalComposableSceneNode *node=[CJGuiInternalComposableSceneNode new];
        CjguiInternalRendererComposableNode raw={0};
        raw.nodeId=100+i; raw.resourceId=-1; raw.nodeKind=CJGUI_INTERNAL_RENDERER_COMPOSABLE_BUTTON;
        node.node=raw; node.index=i; [ctx.composableNodes addObject:node];
    }
    for (NSUInteger i=0;i<count;i++) {
        uint32_t kind=i+1==count ? 45 : (i==0 ? 44 : 43);
        uint32_t index=i==0 ? 0 : 1;
        CHECK(CjguiEnqueueComposableInteraction(ctx,kind,index,@"",NSMakeRange(0,0)),"real_enqueue");
    }
    ctx.physicalProducerTerminal=ctx.pendingInteractions.lastObject;
    return ctx;
}
static void seal(CJGuiInternalSession *ctx) { CjguiSealPhysicalPressPrefix(ctx,0,12,7,3,9,4); }
static BOOL noStamp(CJGuiInternalSession *ctx) {
    for (CJGuiInternalQueuedInteraction *event in ctx.pendingInteractions) if(event.activationPrefix.nonce) return NO;
    return YES;
}
int main(void) { @autoreleasepool {
    for (NSUInteger count=1;count<=64;count+=63) {
        CJGuiInternalSession *ctx=fixture(count); seal(ctx);
        NSUInteger ordinal=1;
        for(CJGuiInternalQueuedInteraction *event in ctx.pendingInteractions) {
            CjguiInternalActivationPrefix p=event.activationPrefix;
            CHECK(p.nonce==12 && p.ordinal==ordinal && p.memberCount==count && p.memberKind==event.kind &&
                p.nodeId==event.nodeId && p.resourceId==event.resourceId && p.nodeKind==event.nodeKind &&
                p.sceneVersion==event.projectionVersion && p.bindingEpoch==9 && p.secondKind==45,
                "each_actual_member_owns_exact_identity"); ordinal++;
        }
    }
    for(NSUInteger reason=0;reason<11;reason++) {
        CJGuiInternalSession *ctx=fixture(3);
        switch(reason) {
            case 0: ctx.physicalProducerTerminal=nil; break;
            case 1: ctx.physicalProducerTerminal=ctx.pendingInteractions.firstObject; break;
            case 2: ctx.pendingInteractions[1].physicalProducerNonce=99; break;
            case 3: ctx.inputDequeueSerial++; break;
            case 4: ctx.physicalProducerContaminated=YES; break;
            case 5: ctx.sessionGeneration++; break;
            case 6: ctx.composableSceneVersion++; break;
            case 7: ctx.ownedTextSessionBindingEpoch++; break;
            case 8: ctx.pendingInteractions[1].kind=27; break;
            case 9: ctx.pendingInteractions[1].projectionVersion++; break;
            case 10: ctx.pendingInteractions[1].kind=47; ctx.pendingInteractions[1].bindingEpoch=0; break;
        }
        seal(ctx); CHECK(noStamp(ctx),"failed_preflight_leaves_no_partial_prefix");
    }
    CJGuiInternalSession *retained=fixture(3);
    retained.pendingInteractions[1].kind=47; retained.pendingInteractions[1].bindingEpoch=71;
    retained.pendingInteractions[1].nodeId=999; seal(retained);
    CHECK(retained.pendingInteractions[1].activationPrefix.nodeId==999 &&
        retained.pendingInteractions[1].activationPrefix.memberKind==47,"retired_node_cancel_retains_own_identity");
    CJGuiInternalSession *full=fixture(64);
    full.physicalProducerTerminal=nil;
    CHECK(!CjguiEnqueueComposableInteraction(full,45,1,@"",NSMakeRange(0,0)),"terminal_queue_full_is_actual_failure");
    seal(full); CHECK(noStamp(full),"queue_full_no_actual_terminal_cannot_seal");
    CJGuiInternalSession *plain=fixture(1);
    plain.pendingInteractions[0].kind=43; seal(plain);
    CHECK(noStamp(plain),"plain_hover_is_not_a_press_prefix");
    printf("PHYSICAL_PREFIX_SEAL checks=%d failures=%d physical_input=false\n",checks,failures);
    return failures ? 1 : 0;
} }

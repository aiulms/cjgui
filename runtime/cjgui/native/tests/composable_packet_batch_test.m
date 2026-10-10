// Real private packet upload with an AppKit main loop. No desktop window is
// ordered, no owner is simulated, and no input or accepted scene is changed.
#import "../cjgui_internal_renderer.m"
#include <stdio.h>

static uint64_t token;
static int failures;
#define CHECK(c,label) do { BOOL ok=(c); fprintf(stderr,"packet_batch case=%s result=%s\n",label,ok?"PASS":"FAIL"); if(!ok) failures++; } while(0)

// The pre-fix production path is retained only to make the dispatch-count RED
// reproducible. Both paths use the actual existing per-node validation.
static CjguiInternalRendererStatus upload(uint64_t id, uint32_t first, uint32_t count,
    const CjguiInternalRendererComposableNode *nodes, const CjguiInternalRendererComposableGeometry *geometry,
    const char *const *strings, uint64_t deadline, uint32_t *copied) {
#ifdef CJGUI_PRIVATE_PREPARATION_BATCH_CAPACITY
    return cjgui_internal_renderer_prepare_composable_node_batch(token,id,first,count,nodes,geometry,strings,deadline,copied);
#else
    *copied=0;
    for(uint32_t i=0;i<count;i++) {
        CjguiInternalRendererStatus st=cjgui_internal_renderer_prepare_composable_node(token,id,first+i,
            nodes+i,geometry+i,strings[i*8],strings[i*8+1],strings[i*8+2],strings[i*8+3],
            strings[i*8+4],strings[i*8+5],strings[i*8+6],strings[i*8+7]);
        if(st) return st;
        (*copied)++;
    }
    return 0;
#endif
}
static void *worker(void *unused) { @autoreleasepool {
    cjgui_internal_renderer_owner_trace_set_turn(7101);
    CjguiInternalRendererComposableNode nodes[9]={0};
    CjguiInternalRendererComposableGeometry geometry[9]={0};
    const char *strings[72]; char body[]="bounded🙂";
    for(uint32_t i=0;i<9;i++) {
        nodes[i].nodeId=900+i; nodes[i].projectionVersion=1; nodes[i].nodeKind=CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT;
        nodes[i].width=30; nodes[i].height=20; nodes[i].clipWidth=30; nodes[i].clipHeight=20; nodes[i].fontSize=13;
        geometry[i].nodeId=nodes[i].nodeId;
        for(uint32_t j=0;j<8;j++) strings[i*8+j]=j==1?body:"";
    }
    uint32_t copied=99;
    CHECK(cjgui_internal_renderer_begin_composable_preparation(token,1,0,1,8)==0,"begin_private_eight");
    uint64_t before=atomic_load(&gCjguiOwnerTraceNextSequence);
    CHECK(upload(1,0,8,nodes,geometry,strings,0,&copied)==0 && copied==8,"eight_exact_copies");
    uint64_t after=atomic_load(&gCjguiOwnerTraceNextSequence), submits=0;
    for(uint64_t s=before+1;s<=after;s++) {
        CjguiOwnerTraceRecord *r=&gCjguiOwnerTraceRecords[(s-1)%CJGUI_OWNER_TRACE_CAPACITY];
        if(r->kind==CJGUI_OWNER_TRACE_DISPATCH_SUBMIT && r->phase==CJGUI_OWNER_PHASE_NATIVE_PREPARATION_NODE) submits++;
    }
    fprintf(stderr,"packet_batch actual_main_dispatches=%llu nodes=8\n",(unsigned long long)submits);
    CHECK(submits==1,"one_main_hop_for_eight_nodes");
    body[0]='X';
    dispatch_sync(dispatch_get_main_queue(), ^{
        CJGuiInternalSession *ctx=CjguiLookupSession(token);
        CHECK([ctx.composablePreparation.nodes[0].value isEqualToString:@"bounded🙂"],"borrowed_strings_copied_before_return");
        CHECK(ctx.composableSceneVersion==0 && ctx.composableNodes.count==0,"live_scene_unmodified");
    });
    CHECK(upload(1,0,1,nodes,geometry,strings,0,&copied)!=0 && copied==0,"duplicate_index_rejected");
    CHECK(cjgui_internal_renderer_cancel_composable_preparation(token,1)==0,"cancel_private_packet");
    CHECK(cjgui_internal_renderer_begin_composable_preparation(token,2,0,1,8)==0,"new_packet_after_cancel");
    CHECK(upload(2,0,8,nodes,geometry,strings,1,&copied)==0 && copied==0,"closed_deadline_has_no_copy");
    CHECK(upload(2,0,9,nodes,geometry,strings,0,&copied)!=0 && copied==0,"over_capacity_rejected_before_copy");
    CHECK(upload(999,0,1,nodes,geometry,strings,0,&copied)!=0 && copied==0,"wrong_ticket_rejected");
    nodes[1].projectionVersion=2;
    CHECK(upload(2,0,8,nodes,geometry,strings,0,&copied)!=0 && copied==1,"error_preserves_exact_successful_prefix");
    CHECK(cjgui_internal_renderer_cancel_composable_preparation(token,2)==0,"failed_prefix_cancelled");
    dispatch_async(dispatch_get_main_queue(), ^{
        [NSApp stop:nil]; [NSApp postEvent:[NSEvent otherEventWithType:NSEventTypeApplicationDefined
            location:NSZeroPoint modifierFlags:0 timestamp:0 windowNumber:0 context:nil subtype:0 data1:0 data2:0] atStart:YES];
    });
    return NULL;
} }
int main(void) { @autoreleasepool {
    setenv("CJGUI_OWNER_PHASE_TRACE","1",1); setenv("CJGUI_OWNER_THREAD_SAMPLES","0",1);
    [NSApplication sharedApplication]; [NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];
    CJGuiInternalSession *ctx=[CJGuiInternalSession new]; id<MTLDevice> device=MTLCreateSystemDefaultDevice();
    ctx.view=[[CJGuiInternalMetalView alloc] initWithFrame:NSMakeRect(0,0,300,200) device:device commandQueue:[device newCommandQueue]];
    ctx.composableNodes=[NSMutableArray array]; ctx.composableTextStyleRunsRaw=[NSMutableDictionary dictionary];
    token=CjguiAllocateSession(ctx); ctx.view.sessionToken=token;
    cjgui_internal_renderer_enable_main_thread_dispatch(); CjguiOwnerTraceRememberMainThread();
    pthread_t thread; if(pthread_create(&thread,NULL,worker,NULL)) return 2;
    [NSApp run]; pthread_join(thread,NULL);
    return failures?1:0;
} }

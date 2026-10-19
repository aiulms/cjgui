#define CJGUI_DRAG_EDGE_COMPLETION_SCHEDULE_FIXTURE 1
#import "composable_drag_edge_scroll_residence_test.m"

// The request is created by the real pointer path, then consumes the same
// owner/viewport ACK protocol as the existing native residence contract test.
// No candidate geometry or selection receipt is invented to complete phase 3.
static void BusyResidenceKeepsOpportunity(id<MTLDevice> device, uint32_t phase) {
    SourceInstallOverlay *o=DragEdgeScrollFixture(device);
    CHECK(o!=nil,"completion_schedule_fixture");
    if(!o) return;
    CJGuiInternalSession *ctx=o.session;
    CJGuiInternalComposableSceneNode *text=DragEdgeScrollFindNode(o,401);
    o.testDragEdgeScrollClockActive=YES;
    [ctx.pendingInteractions removeAllObjects];
    CHECK([o beginPointerCaptureForNode:text atPoint:NSMakePoint(300,200)],
        "completion_schedule_original_capture");
    NSPoint outside=NSMakePoint(300,520);
    (void)[o updatePointerCaptureAtPoint:outside];
    uint64_t gesture=o.pointerCaptureGestureEpoch,scene=ctx.composableSceneVersion;
    if(phase>=2) CHECK(cjgui_internal_renderer_ack_drag_edge_viewport(ctx.rendererSessionToken,
        gesture,900,2,71,19,21,120,100,scene,1)==CJGUI_INTERNAL_RENDERER_OK,
        "completion_schedule_owner_ack");
    if(phase>=3) CHECK(cjgui_internal_renderer_ack_drag_edge_viewport(ctx.rendererSessionToken,
        gesture,900,2,71,19,21,120,120,scene,2)==CJGUI_INTERNAL_RENDERER_OK,
        "completion_schedule_real_viewport_ack");
    CHECK(o.dragEdgeScrollPhase==phase,"completion_schedule_requested_phase");
    const uint64_t due=1000000;
    o.dragEdgeScrollDeadlineMicros=due;
    NSUInteger wheels=DragEdgeScrollCount(ctx),updates=DragEdgePointerUpdateCount(ctx);
    [o advanceDragEdgeScrollAtMicros:due];
    CHECK(o.dragEdgeScrollDeadlineMicros==due,
        "busy_residence_keeps_original_due_instead_of_postponing_50ms");
    CHECK(o.dragEdgeScrollPhase==phase && DragEdgeScrollCount(ctx)==wheels &&
        DragEdgePointerUpdateCount(ctx)==updates,
        "busy_residence_neither_duplicates_request_nor_pointer_input");
    if(phase==1) {
        CHECK(cjgui_internal_renderer_ack_drag_edge_viewport(ctx.rendererSessionToken,
            gesture,900,2,71,19,21,100,100,scene,4)==CJGUI_INTERNAL_RENDERER_OK,
            "completion_schedule_fraction_proves_completion");
        [o advanceDragEdgeScrollAtMicros:due+1];
        CHECK(o.dragEdgeScrollPhase==1 && DragEdgeScrollCount(ctx)==wheels+1,
            "completed_due_request_advances_without_new_move_or_another_period");
        CHECK(o.dragEdgeScrollDeadlineMicros==due+1+CjguiDragEdgeScrollPeriodMicros(),
            "only_executable_residence_advances_next_period");
    }
    [o endPointerCaptureAtPoint:outside cancelled:NO];
    [ctx.pendingInteractions removeAllObjects];
    [o advanceDragEdgeScrollAtMicros:due+100000];
    CHECK(!o.dragEdgeScrollActive && !o.dragEdgeScrollDeadlineMicros &&
        DragEdgeScrollCount(ctx)==0,"completion_after_release_cannot_revive_residence");
    cjgui_internal_renderer_destroy(ctx.rendererSessionToken);
}

static void FractionCompletionSchedulesOneAsyncWake(id<MTLDevice> device) {
    SourceInstallOverlay *o=DragEdgeScrollFixture(device);
    CHECK(o!=nil,"completion_wake_fixture");if(!o)return;
    CJGuiInternalSession *ctx=o.session;
    o.testDragEdgeScrollClockActive=YES;
    CJGuiInternalComposableSceneNode *text=DragEdgeScrollFindNode(o,401);
    [ctx.pendingInteractions removeAllObjects];
    CHECK([o beginPointerCaptureForNode:text atPoint:NSMakePoint(300,200)],
        "completion_wake_original_capture");
    NSPoint outside=NSMakePoint(300,520);
    (void)[o updatePointerCaptureAtPoint:outside];
    const uint64_t due=CjguiCaretBlinkClockMicros()-1;
    o.dragEdgeScrollDeadlineMicros=due;
    o.testDragEdgeScrollClockActive=NO;
    NSUInteger wheels=DragEdgeScrollCount(ctx);
    CHECK(cjgui_internal_renderer_ack_drag_edge_viewport(ctx.rendererSessionToken,
        o.pointerCaptureGestureEpoch,900,2,71,19,21,0,0,ctx.composableSceneVersion,4)==0,
        "completion_wake_real_fraction_ack");
    CHECK(o.dragEdgeScrollScheduled && o.dragEdgeScrollDeadlineMicros==due &&
        o.dragEdgeScrollPhase==0 && DragEdgeScrollCount(ctx)==wheels,
        "completion_schedules_expired_due_once_without_synchronous_reentry");
    [o endPointerCaptureAtPoint:outside cancelled:NO];
    [ctx.pendingInteractions removeAllObjects];
    NSDate *end=[NSDate dateWithTimeIntervalSinceNow:.02];
    while(end.timeIntervalSinceNow>0)
        [NSRunLoop.mainRunLoop runMode:NSDefaultRunLoopMode beforeDate:end];
    CHECK(!o.dragEdgeScrollScheduled && !o.dragEdgeScrollActive &&
        DragEdgeScrollCount(ctx)==0,"cancel_invalidates_queued_completion_wake");
    cjgui_internal_renderer_destroy(ctx.rendererSessionToken);
}

int main(void) { @autoreleasepool {
    [NSApplication sharedApplication];
    id<MTLDevice> device=MTLCreateSystemDefaultDevice();
    for(uint32_t phase=1;phase<=3;phase++) BusyResidenceKeepsOpportunity(device,phase);
    FractionCompletionSchedulesOneAsyncWake(device);
    return failures ? 1 : 0;
} }

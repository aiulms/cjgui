#define CJGUI_INTERNAL_TESTING 1
#import "../cjgui_internal_renderer.m"
#include <stdio.h>

int main(void) { @autoreleasepool {
    setenv("CJGUI_OWNER_PHASE_TRACE","1",1);
    uint64_t turn=501;
    uint64_t first=CjguiOwnerTraceAppend(CJGUI_OWNER_TRACE_BOUNDARY,0,turn,0,0,
        UINT64_MAX,CJGUI_OWNER_PHASE_OWNER_OUTER_BEGIN,0);
    // A controlled fixture gate passes a known absolute observation threshold.
    // This is retention correctness, not a consumer performance measurement.
    dispatch_semaphore_t gate=dispatch_semaphore_create(0);
    (void)dispatch_semaphore_wait(gate,dispatch_time(DISPATCH_TIME_NOW,20000000));
    uint64_t last=CjguiOwnerTraceAppend(CJGUI_OWNER_TRACE_BOUNDARY,0,turn,0,0,
        UINT64_MAX,CJGUI_OWNER_PHASE_OWNER_OUTER_END,0);
    BOOL kept=atomic_load(&gCjguiOwnerTraceSlowTurn)==turn &&
        atomic_load(&gCjguiOwnerTraceSlowFirstSequence)<=first &&
        atomic_load(&gCjguiOwnerTraceSlowLastSequence)>=last;
    fprintf(stderr,"shared_owner_slow case=complete_common_owner_is_retained result=%s first=%llu last=%llu\n",
        kept?"PASS":"FAIL",(unsigned long long)first,(unsigned long long)last);
    return kept?0:1;
}}

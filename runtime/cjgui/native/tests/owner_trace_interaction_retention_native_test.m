// Controlled original-production retention sequence, not a performance result.
#define CJGUI_INTERNAL_TESTING 1
#import "../cjgui_internal_renderer.m"
#include <unistd.h>
#include <assert.h>

int main(int argc,const char **argv) {
    setenv("CJGUI_OWNER_PHASE_TRACE", "1", 1);
    setenv("CJGUI_OWNER_THREAD_SAMPLES", "0", 1);
    atomic_store(&gCjguiCoordinateSessionGeneration[0], 19);
    atomic_store(&gCjguiCoordinateEpoch[0], 1);
    cjgui_internal_renderer_owner_trace_boundary(1,1,CJGUI_OWNER_PHASE_OWNER_OUTER_BEGIN,0,0,0,UINT64_MAX);
    // Ordinary initial scene/input-proxy publication must not mark interaction.
    cjgui_internal_renderer_owner_trace_record(CJGUI_OWNER_TRACE_PHASE_BEGIN,1,1,0,0,19,CJGUI_OWNER_PHASE_NATIVE_INPUT_PUBLICATION,0);
    usleep(200000);
    cjgui_internal_renderer_owner_trace_boundary(1,1,CJGUI_OWNER_PHASE_OWNER_OUTER_END,0,0,0,UINT64_MAX);
    for(uint64_t i=0;i<5000;i++)
        cjgui_internal_renderer_owner_trace_record(CJGUI_OWNER_TRACE_OBSERVATION_SCALAR,1,91,0,0,19,CJGUI_OWNER_PHASE_UNKNOWN,i);
    uint64_t first=atomic_load(&gCjguiOwnerTraceNextSequence)+1;
    cjgui_internal_renderer_owner_trace_boundary(1,2,CJGUI_OWNER_PHASE_OWNER_OUTER_BEGIN,0,0,0,UINT64_MAX);
    uint64_t marker=cjgui_internal_renderer_owner_trace_record(CJGUI_OWNER_TRACE_OBSERVATION_SCALAR,1,2,2,501,19,CJGUI_OWNER_PHASE_PROJECTION_INPUT_ADMISSION,CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_POINTER_UPDATE);
    CjguiOwnerTraceRecord original=gCjguiOwnerTraceRecords[(marker-1)%CJGUI_OWNER_TRACE_CAPACITY];
    usleep(20000);
    cjgui_internal_renderer_owner_trace_record(CJGUI_OWNER_TRACE_OBSERVATION_SCALAR,1,2,0,0,19,CJGUI_OWNER_PHASE_UNKNOWN,marker);
    cjgui_internal_renderer_owner_trace_boundary(1,2,CJGUI_OWNER_PHASE_OWNER_OUTER_END,0,0,0,UINT64_MAX);
    fprintf(stderr,"INTERACTION_ORIGINAL marker=%llu begin=%llu session=%llu turn=%llu tid=%llu mono_ns=%llu phase=%u startup_work_ns=%llu\n",
        (unsigned long long)marker,(unsigned long long)first,(unsigned long long)original.session,
        (unsigned long long)original.turn,(unsigned long long)original.threadId,(unsigned long long)original.monoNs,
        original.phase,(unsigned long long)atomic_load(&gCjguiOwnerTraceSlowWorkNs));
    // Evict ordinary activity/critical/source rings without another slow input.
    for(uint64_t turn=3;turn<7000;turn++) {
        cjgui_internal_renderer_owner_trace_boundary(1,turn,CJGUI_OWNER_PHASE_OWNER_OUTER_BEGIN,0,0,0,UINT64_MAX);
        cjgui_internal_renderer_owner_trace_record(CJGUI_OWNER_TRACE_OBSERVATION_SCALAR,1,turn,0,0,19,CJGUI_OWNER_PHASE_SELECTION_INSTALLED,0);
        cjgui_internal_renderer_owner_trace_boundary(1,turn,CJGUI_OWNER_PHASE_OWNER_OUTER_END,0,0,0,UINT64_MAX);
    }
    for(uint64_t i=0;i<CJGUI_OWNER_TRACE_CAPACITY+1;i++)
        cjgui_internal_renderer_owner_trace_record(CJGUI_OWNER_TRACE_OBSERVATION_SCALAR,1,9999,0,0,19,CJGUI_OWNER_PHASE_UNKNOWN,i);
    if(argc>1 && strcmp(argv[1],"capacity")==0) {
        cjgui_internal_renderer_owner_trace_boundary(1,10000,CJGUI_OWNER_PHASE_OWNER_OUTER_BEGIN,0,0,0,UINT64_MAX);
        cjgui_internal_renderer_owner_trace_record(CJGUI_OWNER_TRACE_OBSERVATION_SCALAR,1,10000,3,501,19,CJGUI_OWNER_PHASE_PROJECTION_INPUT_ADMISSION,CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_POINTER_UPDATE);
        for(uint64_t i=0;i<40000;i++)
            cjgui_internal_renderer_owner_trace_record(CJGUI_OWNER_TRACE_OBSERVATION_SCALAR,1,10000,0,0,19,CJGUI_OWNER_PHASE_UNKNOWN,i);
        usleep(40000);
        cjgui_internal_renderer_owner_trace_boundary(1,10000,CJGUI_OWNER_PHASE_OWNER_OUTER_END,0,0,0,UINT64_MAX);
        uint64_t count=MIN(atomic_load(&gCjguiOwnerTraceInteractionNext),(uint64_t)CJGUI_OWNER_TRACE_INTERACTION_CAPACITY);
        assert(count==CJGUI_OWNER_TRACE_INTERACTION_CAPACITY);
        assert(atomic_load(&gCjguiOwnerTraceInteractionDropped)>0 && atomic_load(&gCjguiOwnerTraceInteractionSourceMissing)>0);
        for(uint64_t i=0;i<count;i++) assert(gCjguiOwnerTraceInteractionRecords[i].turn==10000);
        fprintf(stderr,"INTERACTION_CAPACITY records=%llu dropped=%llu source_missing=%llu previous_turn_not_borrowed=1\n",
            (unsigned long long)count,(unsigned long long)atomic_load(&gCjguiOwnerTraceInteractionDropped),
            (unsigned long long)atomic_load(&gCjguiOwnerTraceInteractionSourceMissing));
    }
    int status=cjgui_internal_renderer_finalize_owner_trace();
    fprintf(stderr,"INTERACTION_TERMINAL finalize=%d controlled=1\n",status);
    return status==2?0:1;
}

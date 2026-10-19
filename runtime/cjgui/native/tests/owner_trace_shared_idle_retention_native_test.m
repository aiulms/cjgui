// Shared allowance idle must not mask a later actual-work interaction.
#define CJGUI_INTERNAL_TESTING 1
#import "../cjgui_internal_renderer.m"
#include <assert.h>
static void begin(uint64_t turn) {
 cjgui_internal_renderer_owner_trace_boundary(1,turn,CJGUI_OWNER_PHASE_OWNER_OUTER_BEGIN,0,0,0,UINT64_MAX);
}
static void input(uint64_t turn) {
 cjgui_internal_renderer_owner_trace_record(CJGUI_OWNER_TRACE_OBSERVATION_SCALAR,1,turn,turn,501,19,
  CJGUI_OWNER_PHASE_PROJECTION_INPUT_ADMISSION,CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_POINTER_UPDATE);
}
static void credit(uint64_t turn,uint64_t idle) {
 cjgui_internal_renderer_owner_trace_boundary(0,turn,CJGUI_OWNER_TURN_COST_CREDIT_PHASE,0,0,idle,UINT64_MAX);
}
static void end(uint64_t turn) {
 cjgui_internal_renderer_owner_trace_boundary(1,turn,CJGUI_OWNER_PHASE_OWNER_OUTER_END,0,0,0,UINT64_MAX);
}
static void *foreignCredit(void *unused) { credit(4,0);return NULL; }
int main(int argc,const char **argv) { @autoreleasepool {
 setenv("CJGUI_OWNER_PHASE_TRACE","1",1);setenv("CJGUI_OWNER_TURN_COST","1",1);
 setenv("CJGUI_OWNER_THREAD_SAMPLES","0",1);
 atomic_store(&gCjguiCoordinateSessionGeneration[0],19);atomic_store(&gCjguiCoordinateEpoch[0],1);
 begin(1);usleep(200000);credit(1,0);end(1);
 begin(2);input(2);uint64_t start=CjguiOwnerTraceNanoseconds();usleep(50000);
 uint64_t idle=CjguiOwnerTraceNanoseconds()-start;credit(2,idle);end(2);
 begin(3);input(3);usleep(20000);credit(3,0);end(3);
 fprintf(stderr,"SHARED_IDLE_CONTROL retained_turn=%llu work_ns=%llu credited_idle_ns=%llu cost_rows=%llu\n",
 (unsigned long long)atomic_load(&gCjguiOwnerTraceInteractionTurn),
 (unsigned long long)atomic_load(&gCjguiOwnerTraceInteractionWorkNs),
 (unsigned long long)idle,(unsigned long long)gCjguiOwnerTurnCostRows);
 if(atomic_load(&gCjguiOwnerTraceInteractionTurn)!=3)return 1;
 assert(atomic_load(&gCjguiOwnerTraceInteractionWorkNs)>=16000000);
 assert(gCjguiOwnerTurnCostRows==3 && gCjguiOwnerTurnCostOver16==2);
 CjguiOwnerTurnCostRow row=gCjguiOwnerTurnCosts[1];
 assert(row.idleKnown && row.idleNs==idle && row.endNs-row.beginNs-row.idleNs<16000000);
 fprintf(stderr,"SHARED_IDLE_CONTROL real_later_work_retained=1 original_cost_not_relaxed=1\n");
 if(argc>1) {
  begin(4);input(4);uint64_t started=CjguiOwnerTraceNanoseconds();usleep(30000);
  if(strcmp(argv[1],"duplicate")==0) {
   uint64_t measured=CjguiOwnerTraceNanoseconds()-started;credit(4,measured);credit(4,measured);
  } else if(strcmp(argv[1],"conflict")==0) { credit(4,20000000);credit(4,0); }
  else if(strcmp(argv[1],"foreign-session")==0) {
   cjgui_internal_renderer_owner_trace_boundary(2,4,CJGUI_OWNER_TURN_COST_CREDIT_PHASE,0,0,0,UINT64_MAX);
  } else if(strcmp(argv[1],"foreign-thread")==0) {
   pthread_t worker;assert(!pthread_create(&worker,NULL,foreignCredit,NULL));pthread_join(worker,NULL);
  } else return 2;
  end(4);assert(atomic_load(&gCjguiOwnerTraceInteractionTurn)==3);
  fprintf(stderr,"SHARED_IDLE_NEGATIVE mode=%s previous_genuine_work_preserved=1 no_new_gate_claim=1\n",argv[1]);
 }

 return 0;
}}

// Exact raw block-tail observation through the production synchronous bridge.
#define CJGUI_INTERNAL_TESTING 1
#import "../cjgui_internal_renderer.m"
#include <assert.h>
int main(void) { @autoreleasepool {
 setenv("CJGUI_OWNER_PHASE_TRACE","1",1);setenv("CJGUI_OWNER_THREAD_SAMPLES","0",1);
 [NSApplication sharedApplication];
 atomic_store(&gCjguiCoordinateSessionGeneration[0],19);atomic_store(&gCjguiCoordinateEpoch[0],1);
 cjgui_internal_renderer_owner_trace_set_turn(7);
 __block _Atomic(bool) done=false;
 dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT,0),^{
  CjguiOwnerTraceDispatchSync(1,91,CJGUI_OWNER_PHASE_INSTALLED_RANGE_MAIN,^{usleep(2000);});
  atomic_store(&done,true);
 });
 NSDate *limit=[NSDate dateWithTimeIntervalSinceNow:3];
 while(!atomic_load(&done) && limit.timeIntervalSinceNow>0)
  [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:.001]];
 assert(atomic_load(&done));
 CjguiOwnerTraceRecord *exitRecord=NULL,*tail=NULL,*returned=NULL;
 uint64_t count=MIN(atomic_load(&gCjguiOwnerTraceNextSequence),(uint64_t)CJGUI_OWNER_TRACE_CAPACITY);
 for(uint64_t i=0;i<count;i++) {
  CjguiOwnerTraceRecord *r=&gCjguiOwnerTraceRecords[i];
  if(r->request!=91)continue;
  if(r->kind==CJGUI_OWNER_TRACE_MAIN_EXIT)exitRecord=r;
  if(r->kind==CJGUI_OWNER_TRACE_BOUNDARY && r->phase==359)tail=r;
  if(r->kind==CJGUI_OWNER_TRACE_DISPATCH_SYNC_RETURN)returned=r;
 }
 fprintf(stderr,"BLOCK_TAIL_CONTROL exit=%d tail=%d returned=%d\n",exitRecord!=NULL,tail!=NULL,returned!=NULL);
 if(!exitRecord||!tail||!returned)return 1;
 assert(exitRecord->monoNs<=tail->monoNs && tail->monoNs<=returned->monoNs);
 assert(tail->threadId==exitRecord->threadId && tail->threadId!=returned->threadId);
 assert(tail->session==exitRecord->session && tail->generation==19 && tail->dispatch==returned->dispatch && tail->turn==7);
 assert(!tail->cpuValid); // Captured main clock; no owner CPU mislabeled as main.
 fprintf(stderr,"BLOCK_TAIL_CONTROL observer_tail_ns=%llu handback_ns=%llu identity_exact=1 CPU_unknown=1\n",
 (unsigned long long)(tail->monoNs-exitRecord->monoNs),(unsigned long long)(returned->monoNs-tail->monoNs));
 return 0;
}}

/* Test-only scheduling and release observations around the real dispatcher.
 * No command terminal/status/ownership field is fabricated by this fixture. */
#ifndef CJGUI_DISPATCH_FIXTURE_CASES
#define _WIN32_WINNT 0x0A00
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <stdlib.h>
#include <stdint.h>
static volatile LONG observe_on, observe_alloc_n, observe_event_n, observe_bad;
static struct { void *p; volatile LONG frees; } observe_allocs[64];
static struct { HANDLE h; volatile LONG closes; } observe_events[32];
static HANDLE observe_wait_returned, observe_allow_wait, observe_claimed, observe_allow_execute;
static _Thread_local int observe_wait_mode, observe_pause_ui;
static void *observe_calloc(size_t n, size_t size) {
    void *p = calloc(n, size);
    if (observe_on && p) { LONG i=InterlockedIncrement(&observe_alloc_n)-1;
        if(i<64){observe_allocs[i].p=p;observe_allocs[i].frees=0;}else InterlockedIncrement(&observe_bad); }
    return p;
}
static void observe_free(void *p) {
    if(observe_on && p) for(LONG i=0;i<observe_alloc_n && i<64;++i) if(observe_allocs[i].p==p){
        if(InterlockedIncrement(&observe_allocs[i].frees)!=1){InterlockedIncrement(&observe_bad);return;}break;
    }
    free(p);
}
static HANDLE observe_create_event(LPSECURITY_ATTRIBUTES a,BOOL manual,BOOL initial,LPCWSTR name){
    HANDLE h=CreateEventW(a,manual,initial,name);
    if(observe_on && h){LONG i=InterlockedIncrement(&observe_event_n)-1;
        if(i<32){observe_events[i].h=h;observe_events[i].closes=0;}else InterlockedIncrement(&observe_bad);}
    return h;
}
static BOOL observe_close_handle(HANDLE h){
    if(observe_on && h) for(LONG i=0;i<observe_event_n && i<32;++i)if(observe_events[i].h==h){
        if(InterlockedIncrement(&observe_events[i].closes)!=1){InterlockedIncrement(&observe_bad);return FALSE;}break;
    }
    return CloseHandle(h);
}
/* The wait is real. Barriers only pause its caller before the production
 * cmdLock/terminal claim; no fabricated WAIT result or terminal flag. */
static DWORD observe_wait(HANDLE h,DWORD ms){
    int mode=observe_wait_mode;
    if(mode==3){if(WaitForSingleObject(observe_claimed,5000)!=WAIT_OBJECT_0)InterlockedIncrement(&observe_bad);}
    DWORD result=WaitForSingleObject(h, mode==2?5000:(mode?1:ms));
    if(mode==1 || mode==2){
        if((mode==1 && result!=WAIT_TIMEOUT) || (mode==2 && result!=WAIT_OBJECT_0))InterlockedIncrement(&observe_bad);
        SetEvent(observe_wait_returned);
        if(WaitForSingleObject(observe_allow_wait,5000)!=WAIT_OBJECT_0)InterlockedIncrement(&observe_bad);
    }
    return result;
}
static DWORD observe_thread_id(void){
    DWORD id=GetCurrentThreadId();
    if(observe_pause_ui){observe_pause_ui=0;SetEvent(observe_claimed);
        if(WaitForSingleObject(observe_allow_execute,5000)!=WAIT_OBJECT_0)InterlockedIncrement(&observe_bad);}
    return id;
}
#define calloc observe_calloc
#define free observe_free
#define CreateEventW observe_create_event
#define CloseHandle observe_close_handle
#define WaitForSingleObject observe_wait
#define GetCurrentThreadId observe_thread_id
#else
#undef calloc
#undef free
#undef CreateEventW
#undef CloseHandle
#undef WaitForSingleObject
#undef GetCurrentThreadId

typedef struct DispatchFixture {
    CjguiWindowsRendererSession *s;
    HANDLE ui,ready,work,drained,stop;
    volatile LONG operation,pause,proc_calls;
    CjguiInternalRendererStatus proc_status;
    int inline_status;uint64_t inline_old,inline_completed;CjguiInternalRendererFrameObservation inline_obs;
} DispatchFixture;
typedef struct DispatchProbe {
    DispatchFixture *f;
    int legacy,mode,kind,status;
    uint64_t old_id,completed,facts[10];
    CjguiInternalRendererFrameObservation observation;
    void *ctx;
    HANDLE thread;
} DispatchProbe;
static CjguiInternalRendererStatus dispatch_fixture_proc(CjguiWindowsRendererSession *s,void *raw){
    (void)s;DispatchFixture *f=*(DispatchFixture **)raw;
    InterlockedIncrement(&f->proc_calls);return f->proc_status;
}
static void dispatch_fixture_ctx_free(void *raw){observe_free(raw);}
static DWORD WINAPI dispatch_fixture_ui(void *raw){
    DispatchFixture *f=raw;f->s->pumpThreadId=GetCurrentThreadId();SetEvent(f->ready);
    for(;;){if(WaitForSingleObject(f->work,10000)!=WAIT_OBJECT_0){InterlockedIncrement(&observe_bad);break;}
        if(WaitForSingleObject(f->stop,0)==WAIT_OBJECT_0)break;
        observe_pause_ui=(int)f->pause;f->pause=0;
        if(f->operation==1)cjgui_windows_fail_queued(f->s);
        else if(f->operation==2 || f->operation==3){DispatchFixture *value=f;f->inline_old=f->inline_completed=99;
            if(f->operation==2)f->inline_status=windows_dispatch_sync_with_completed(f->s->token,"inline_fixture",CJGUI_WINDOWS_CMD_GENERIC,
                dispatch_fixture_proc,&value,NULL,5000,&f->inline_old,&f->inline_completed);
            else f->inline_status=windows_dispatch_sync(f->s->token,"legacy_inline",CJGUI_WINDOWS_CMD_GENERIC,
                dispatch_fixture_proc,&value,NULL,5000,&f->inline_old);
        }else if(f->operation==4)f->inline_status=cjgui_internal_renderer_present_composable_scene(f->s->token,&f->inline_obs);
        else drain_dispatcher_commands(f->s,0);
        SetEvent(f->drained);
    }return 0;
}
static DWORD WINAPI dispatch_fixture_owner(void *raw){
    DispatchProbe *p=raw;observe_wait_mode=p->mode;
    if(p->kind==1)p->status=cjgui_internal_renderer_present_composable_scene(p->f->s->token,&p->observation);
    else if(p->kind==2)p->status=cjgui_internal_renderer_restore_composable_selection_paint_result(
        p->f->s->token,1001,-1,CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT,7,"abc",0,1,4,17,p->facts);
    else if(p->legacy)p->status=windows_dispatch_sync(p->f->s->token,"legacy_fixture",CJGUI_WINDOWS_CMD_GENERIC,
        dispatch_fixture_proc,p->ctx,dispatch_fixture_ctx_free,5000,&p->old_id);
    else p->status=windows_dispatch_sync_with_completed(p->f->s->token,"completed_fixture",CJGUI_WINDOWS_CMD_GENERIC,
        dispatch_fixture_proc,p->ctx,dispatch_fixture_ctx_free,5000,&p->old_id,&p->completed);
    observe_wait_mode=0;
    if(!p->kind && p->status!=CJGUI_INTERNAL_RENDERER_COMMAND_IN_FLIGHT &&
       p->status!=CJGUI_INTERNAL_RENDERER_COMMAND_TIMEOUT)observe_free(p->ctx);
    return 0;
}
static void dispatch_fixture_begin(DispatchFixture *f){
    memset(f,0,sizeof(*f));f->s=&g_sessions[1];memset(f->s,0,sizeof(*f->s));
    f->s->occupied=1;f->s->token=998877;f->s->sessionGeneration=991;f->s->cmdNextId=300;
    InitializeCriticalSection(&f->s->cmdLock);InitializeCriticalSection(&f->s->rawLock);
    f->s->cmdWakeEvent=CreateEventW(NULL,FALSE,FALSE,NULL);f->s->pumpThreadRunning=1;
    f->ready=CreateEventW(NULL,FALSE,FALSE,NULL);f->work=CreateEventW(NULL,FALSE,FALSE,NULL);
    f->drained=CreateEventW(NULL,FALSE,FALSE,NULL);f->stop=CreateEventW(NULL,TRUE,FALSE,NULL);
    observe_wait_returned=CreateEventW(NULL,FALSE,FALSE,NULL);observe_allow_wait=CreateEventW(NULL,FALSE,FALSE,NULL);
    observe_claimed=CreateEventW(NULL,TRUE,FALSE,NULL);observe_allow_execute=CreateEventW(NULL,FALSE,FALSE,NULL);
    observe_alloc_n=observe_event_n=observe_bad=0;memset(observe_allocs,0,sizeof(observe_allocs));memset(observe_events,0,sizeof(observe_events));
    observe_on=1;f->ui=CreateThread(NULL,0,dispatch_fixture_ui,f,0,NULL);
    check("fixture_real_ui_ready",f->ui && WaitForSingleObject(f->ready,5000)==WAIT_OBJECT_0);
}
static uint64_t dispatch_probe_start(DispatchFixture *f,DispatchProbe *p,int legacy,int mode,int kind){
    memset(p,0,sizeof(*p));p->f=f;p->legacy=legacy;p->mode=mode;p->kind=kind;
    if(!kind){p->ctx=observe_calloc(1,sizeof(DispatchFixture *));*(DispatchFixture **)p->ctx=f;}
    p->thread=CreateThread(NULL,0,dispatch_fixture_owner,p,0,NULL);
    check("fixture_actual_enqueued",p->thread && WaitForSingleObject(f->s->cmdWakeEvent,5000)==WAIT_OBJECT_0);
    EnterCriticalSection(&f->s->cmdLock);
    CjguiWindowsCommand2 *cmd=f->s->cmdRing[f->s->cmdTail % CJGUI_WINDOWS_CMD_RING_CAPACITY];
    uint64_t id=cmd?cmd->commandId:0;
    LeaveCriticalSection(&f->s->cmdLock);
    check("fixture_frozen_envelope_id",id!=0);return id;
}
static void dispatch_probe_join(DispatchProbe *p){check("fixture_owner_join",WaitForSingleObject(p->thread,5000)==WAIT_OBJECT_0);CloseHandle(p->thread);}
static void dispatch_fixture_run_ui(DispatchFixture *f){SetEvent(f->work);check("fixture_ui_drained",WaitForSingleObject(f->drained,5000)==WAIT_OBJECT_0);}
static void dispatch_fixture_end(DispatchFixture *f,const char *release_case){
    SetEvent(f->stop);SetEvent(f->work);check("fixture_ui_join",WaitForSingleObject(f->ui,5000)==WAIT_OBJECT_0);CloseHandle(f->ui);
    if(f->s->occupied){f->s->pumpThreadRunning=0;destroy_caller_phase_b(f->s);}
    int released=!observe_bad;
    for(LONG i=0;i<observe_alloc_n && i<64;++i)released= released && observe_allocs[i].frees==1;
    for(LONG i=0;i<observe_event_n && i<32;++i)released= released && observe_events[i].closes==1;
    printf("DISPATCH_RELEASE case=%s allocations=%ld events=%ld bad=%ld\n",release_case,observe_alloc_n,observe_event_n,observe_bad);
    check(release_case,released);observe_on=0;
    CloseHandle(f->ready);CloseHandle(f->work);CloseHandle(f->drained);CloseHandle(f->stop);
    CloseHandle(observe_wait_returned);CloseHandle(observe_allow_wait);CloseHandle(observe_claimed);CloseHandle(observe_allow_execute);
}
static void run_dispatcher_completion_cases(void){
    DispatchFixture f;DispatchProbe a,b;
    for(int legacy=0;legacy<2;++legacy){
        dispatch_fixture_begin(&f);f.operation=legacy?3:2;dispatch_fixture_run_ui(&f);
        check(legacy?"legacy_inline_id_zero":"new_inline_completed_zero",f.inline_status==0 && f.inline_old==0 && (legacy || f.inline_completed==0) && f.proc_calls==1);
        dispatch_fixture_end(&f,"inline_release_once");
    }
    dispatch_fixture_begin(&f);f.operation=4;dispatch_fixture_run_ui(&f);
    check("actual_present_inline_rejection",f.inline_status!=0 && f.inline_status!=CJGUI_INTERNAL_RENDERER_PRESENT_PENDING && f.s->presentReceipt.ticketId==0);
    dispatch_fixture_end(&f,"actual_present_inline_ctx_free_once");
    /* Both the new observer and the old wrapper run the identical real queue. */
    for(int legacy=0;legacy<2;++legacy){
        dispatch_fixture_begin(&f);uint64_t id=dispatch_probe_start(&f,&a,legacy,0,0);
        dispatch_fixture_run_ui(&f);dispatch_probe_join(&a);
        check(legacy?"legacy_queued_success_old_id_zero":"completed_queued_success",a.status==0 && a.old_id==0 && (legacy || a.completed==id) && f.proc_calls==1);
        dispatch_fixture_end(&f,"queued_release_once");
        dispatch_fixture_begin(&f);id=dispatch_probe_start(&f,&a,legacy,1,0);
        check("actual_wait_timed_out_before_claim",WaitForSingleObject(observe_wait_returned,5000)==WAIT_OBJECT_0);
        dispatch_fixture_run_ui(&f);SetEvent(observe_allow_wait);dispatch_probe_join(&a);
        check(legacy?"legacy_done_at_timeout_old_id_zero":"completed_done_at_timeout",a.status==0 && a.old_id==0 && (legacy || a.completed==id) && f.proc_calls==1);
        dispatch_fixture_end(&f,"timeout_race_release_once");
    }
    /* A's completion is held before its lock claim; B really executes first. */
    dispatch_fixture_begin(&f);uint64_t aid=dispatch_probe_start(&f,&a,0,2,0);
    dispatch_fixture_run_ui(&f);check("A_not_yet_claimed",WaitForSingleObject(observe_wait_returned,5000)==WAIT_OBJECT_0);
    uint64_t bid=dispatch_probe_start(&f,&b,0,0,0);dispatch_fixture_run_ui(&f);dispatch_probe_join(&b);
    check("B_counter_advanced",bid!=aid && b.completed==bid && f.s->cmdNextId==bid);
    SetEvent(observe_allow_wait);dispatch_probe_join(&a);
    check("A_returns_own_envelope_not_latest_counter",a.status==0 && a.completed==aid && a.completed!=bid && f.proc_calls==2);
    dispatch_fixture_end(&f,"two_command_release_once");
    dispatch_fixture_begin(&f);dispatch_probe_start(&f,&a,0,1,0);
    check("unstarted_real_wait_elapsed",WaitForSingleObject(observe_wait_returned,5000)==WAIT_OBJECT_0);SetEvent(observe_allow_wait);dispatch_probe_join(&a);
    check("not_started_timeout_no_completed",a.status==CJGUI_INTERNAL_RENDERER_COMMAND_TIMEOUT && a.old_id==0 && a.completed==0 && f.proc_calls==0 && f.s->cmdHead==f.s->cmdTail);
    dispatch_fixture_end(&f,"not_started_release_once");
    for(int legacy=0;legacy<2;++legacy){
        dispatch_fixture_begin(&f);aid=dispatch_probe_start(&f,&a,legacy,3,0);f.pause=1;SetEvent(f.work);
        check("actually_claimed_before_timeout",WaitForSingleObject(observe_claimed,5000)==WAIT_OBJECT_0);dispatch_probe_join(&a);
        check("inflight_only_legacy_id",a.status==CJGUI_INTERNAL_RENDERER_COMMAND_IN_FLIGHT && a.old_id==aid && a.completed==0 && f.proc_calls==0);
        SetEvent(observe_allow_execute);check("inflight_ui_finishes_after_return",WaitForSingleObject(f.drained,5000)==WAIT_OBJECT_0);
        uint64_t reaped=0;CjguiInternalRendererStatus status=99;cjgui_internal_renderer_reap_orphaned_command(f.s->token,&reaped,&status);
        check("real_hold_reap_once_no_late_output",reaped==aid && status==0 && a.completed==0 && a.old_id==aid && f.proc_calls==1 && f.s->cmdHoldCount==0);
        uint64_t again=99;cjgui_internal_renderer_reap_orphaned_command(f.s->token,&again,&status);check("second_reap_empty",again==0);
        dispatch_fixture_end(&f,"inflight_release_once");
    }
    dispatch_fixture_begin(&f);f.proc_status=CJGUI_INTERNAL_RENDERER_SCENE_STALE;aid=dispatch_probe_start(&f,&a,0,0,0);
    dispatch_fixture_run_ui(&f);dispatch_probe_join(&a);
    check("completed_id_is_not_operation_success",a.status==CJGUI_INTERNAL_RENDERER_SCENE_STALE && a.completed==aid && a.old_id==0 && f.proc_calls==1);
    dispatch_fixture_end(&f,"failed_operation_release_once");
    dispatch_fixture_begin(&f);dispatch_probe_start(&f,&a,0,0,2);dispatch_fixture_run_ui(&f);dispatch_probe_join(&a);
    int nofacts=1;for(int i=0;i<10;++i)nofacts=nofacts && a.facts[i]==0;
    check("failed_real_restore_exports_no_paint_facts",a.status!=0 && nofacts);
    dispatch_fixture_end(&f,"failed_restore_release_once");
    dispatch_fixture_begin(&f);aid=dispatch_probe_start(&f,&a,0,0,0);f.operation=1;dispatch_fixture_run_ui(&f);dispatch_probe_join(&a);
    check("actual_close_cancellation_not_paint_success",a.status==CJGUI_INTERNAL_RENDERER_INVALID_SESSION && a.completed==aid && a.old_id==0 && f.proc_calls==0);
    dispatch_fixture_end(&f,"close_cancel_release_once");
    dispatch_fixture_begin(&f);aid=dispatch_probe_start(&f,&a,0,1,0);
    check("phase_b_wait_barrier",WaitForSingleObject(observe_wait_returned,5000)==WAIT_OBJECT_0);dispatch_fixture_run_ui(&f);
    destroy_caller_phase_b(f.s);check("real_phase_b_deferred",f.s->callerCleanupDeferred==1 && f.s->cmdWaiters==1);
    SetEvent(observe_allow_wait);dispatch_probe_join(&a);
    check("last_waiter_returns_frozen_terminal_after_phase_b",a.status==0 && a.completed==aid && a.old_id==0 && !f.s->occupied && f.s->token==0);
    dispatch_fixture_end(&f,"deferred_phase_b_release_once");
    /* Execute the actual Present wrapper with empty graphics fixtures. It must
     * preserve rejection/receipt/reference ownership, not claim pixels. */
    for(int inflight=0;inflight<2;++inflight){
        dispatch_fixture_begin(&f);aid=dispatch_probe_start(&f,&a,0,inflight?3:0,1);
        if(inflight){f.pause=1;SetEvent(f.work);check("present_really_claimed",WaitForSingleObject(observe_claimed,5000)==WAIT_OBJECT_0);dispatch_probe_join(&a);
            check("actual_present_pending_receipt",a.status==CJGUI_INTERNAL_RENDERER_PRESENT_PENDING && a.observation.ticketId!=0);
            SetEvent(observe_allow_execute);check("present_finishes_after_handoff",WaitForSingleObject(f.drained,5000)==WAIT_OBJECT_0);
            uint64_t reaped=0;CjguiInternalRendererStatus status=0;cjgui_internal_renderer_reap_orphaned_command(f.s->token,&reaped,&status);
            check("actual_present_reap_releases_dispatch_ref",reaped==aid && status!=0 && f.s->presentReceipt.settled && f.s->presentReceipt.decision==CJGUI_INTERNAL_RENDERER_PRESENT_DECISION_REJECTED);
        }else{dispatch_fixture_run_ui(&f);dispatch_probe_join(&a);check("actual_present_queued_rejection_no_receipt_leak",a.status!=0 && a.status!=CJGUI_INTERNAL_RENDERER_PRESENT_PENDING && f.s->presentReceipt.ticketId==0);}
        dispatch_fixture_end(&f,"actual_present_ctx_and_envelope_free_once");
    }
}
#endif

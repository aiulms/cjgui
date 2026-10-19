/* Real renderer lifetime: count actual producer events, never synthesize a reclaim. */
#include <stdio.h>
#include <stdarg.h>
#include <string.h>
#include <stdlib.h>
static char observed[64][4096];
static unsigned observedCount;
static int observe_fprintf(FILE *stream, const char *format, ...) {
    char line[4096]; va_list args; va_start(args,format);
    int result=vsnprintf(line,sizeof(line),format,args); va_end(args);
    if(stream==stderr && strstr(line,"CJGUI_WINDOWS_PREP event=") && observedCount<64)
        strcpy(observed[observedCount++],line);
    fputs(line,stream); return result;
}
#define fprintf observe_fprintf
#include "../../platforms/windows/native/cjgui_windows_renderer.c"
#undef fprintf
static int failures;
static void check(const char *name,int pass){printf("CLOSE_NATIVE_CASE %s pass=%d\n",name,!!pass);fflush(stdout);if(!pass)++failures;}
static uint64_t field(const char *line,const char *key){char pattern[64];snprintf(pattern,sizeof(pattern)," %s=",key);const char *at=strstr(line,pattern);return at?strtoull(at+strlen(pattern),NULL,10):UINT64_MAX;}
static uint64_t wantedNodes,wantedBytes,wantedTicket;
static CjguiInternalRendererStatus prepare_close_fixture(CjguiWindowsRendererSession *s,void *raw){
    int partial=*(int*)raw; uint64_t token=s->token; wantedTicket=partial?703:701;
    check("real_begin",begin_composable_preparation_impl(token,wantedTicket,0,1,41)==0);
    for(uint32_t i=0;i<3;++i){
        CjguiInternalRendererComposableNode n={0};n.nodeId=i+1;n.projectionVersion=1;n.resourceId=i+10;n.nodeKind=CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT;n.x=20;n.y=24+i*54;n.width=420;n.height=52;n.clipWidth=640;n.clipHeight=360;n.fontSize=20;n.fontWeight=400;n.textAlpha=1;n.fillAlpha=1;
        CjguiInternalRendererComposableGeometry geom={0};geom.nodeId=n.nodeId;
        check("real_stage",prepare_composable_node_impl(token,wantedTicket,i,&n,&geom,"label","中😀value","semantic","binding","row","parent","accessible","")==0);
    }
    wantedNodes=s->preparationNodeCount; wantedBytes=s->preparationOwnedBytes;
    check("actual_graph_nonempty",s->preparationActive&&wantedNodes==41&&wantedBytes>0);
    if(partial){
        check("actual_cancel",cancel_composable_preparation_impl(token,wantedTicket)==0);
        check("actual_partial_retirement",windows_prep_retire_unit(s)==1&&s->preparationRetiringCount==1&&s->preparationRetiring[0].releaseCursor==40&&s->preparationRetiring[0].releasedNodes==1);
    }
    return CJGUI_INTERNAL_RENDERER_OK;
}
static void run_case(int partial){
    observedCount=0;memset(observed,0,sizeof(observed));
    CjguiInternalRendererConfig config={640,360,0.96,0.97,0.99,1};CjguiInternalRendererStatus status=-1;
    uint64_t token=cjgui_internal_renderer_create(&config,&status);check("real_window_device",token&&status==0);if(!token||status)return;
    check("actual_ui_prepare",windows_dispatch_sync(token,"close_fixture",CJGUI_WINDOWS_CMD_GENERIC,prepare_close_fixture,&partial,NULL,3000,NULL)==0);
    check("actual_normal_destroy",cjgui_internal_renderer_destroy(token)==0);
    const char *cancel=NULL,*reclaim=NULL;unsigned cancels=0,reclaims=0;
    for(unsigned i=0;i<observedCount;++i){
        const char *line=observed[i];if(field(line,"ticket")!=wantedTicket)continue;
        if(strstr(line,"event=cancel ")){cancel=line;++cancels;}
        if(strstr(line,"event=reclaim_complete ")){reclaim=line;++reclaims;}
    }
    check(partial?"partial_same_ticket_cancel":"active_close_same_ticket_cancel",cancel&&cancels==1&&field(cancel,"cancel_ns")>0);
    check(partial?"partial_same_ticket_reclaim":"active_close_same_ticket_reclaim",reclaim&&reclaims==1);
    check("same_cancel_identity",cancel&&reclaim&&field(cancel,"cancel_ns")==field(reclaim,"cancel_ns"));
    check("full_node_byte_release",reclaim&&field(reclaim,"graph_nodes")==wantedNodes&&field(reclaim,"released_nodes")==wantedNodes&&field(reclaim,"graph_bytes")==wantedBytes&&field(reclaim,"released_bytes")==wantedBytes&&field(reclaim,"accounting_errors")==0);
    check("final_responsibility_zero",reclaim&&field(reclaim,"active")==0&&field(reclaim,"ready")==0&&field(reclaim,"nodes")==0&&field(reclaim,"live")==0&&field(reclaim,"retiring")==0);
    check("session_retired",find_session(token)==NULL);
}
int main(void){_putenv("PHAROS_WINDOWS_TEST_PROBE_FILE=fixture-observe-only");run_case(0);run_case(1);printf("OBSERVATION_UNIT failures=%d\n",failures);return failures?1:0;}

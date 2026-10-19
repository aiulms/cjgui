/* Real UI dispatcher calls and actual bounded timer rows. */
#include "../../platforms/windows/native/cjgui_windows_renderer.c"
static int failures;
static uint64_t inspectedCount;
static DWORD inspectedUiThread;
static void check(const char *name,int ok){printf("UI_NATIVE_CASE %s pass=%d\n",name,!!ok);fflush(stdout);if(!ok)++failures;}
static CjguiInternalRendererStatus inspect(CjguiWindowsRendererSession *s,void *raw){
 (void)raw;const char *wanted[]={"dispatch_prep_begin","dispatch_prep_prepare","dispatch_prep_advance","dispatch_prep_promote","dispatch_prep_cancel","dispatch_prep_drain","prep_cancel","prep_drain","prep_work","dispatch_pump","pump_work","pump_wait","pump_probe","ui_message","ui_create"};
 DWORD hwndTid=GetWindowThreadProcessId(s->hwnd,NULL);
 inspectedCount=s->traceCount;inspectedUiThread=hwndTid;
 for(unsigned k=0;k<sizeof(wanted)/sizeof(wanted[0]);++k){unsigned count=0;int identities=1;
  for(uint64_t i=0;i<s->traceCount&&i<CJGUI_WINDOWS_TRACE_CAPACITY;++i){CjguiWindowsTraceRow *r=&s->traceRows[i];if(strcmp(r->stage,wanted[k]))continue;
   ++count;if(r->d!=0||r->c==0||r->f!=hwndTid||r->f!=GetCurrentThreadId())identities=0;
  }
  char name[96];snprintf(name,sizeof(name),"%s_real_duration",wanted[k]);check(name,count>0&&identities);
 }
 windows_trace_dump(s,stdout);return CJGUI_INTERNAL_RENDERER_OK;
}
static void prepare(uint64_t token,uint64_t prep,uint64_t base,uint64_t scene){
 CjguiInternalRendererComposableNode n={0};n.nodeId=1;n.resourceId=10;n.projectionVersion=scene;n.nodeKind=CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT;n.x=20;n.y=24;n.width=420;n.height=52;n.clipWidth=640;n.clipHeight=360;n.fontSize=20;n.fontWeight=400;n.textAlpha=1;n.fillAlpha=1;
 CjguiInternalRendererComposableGeometry geom={0};geom.nodeId=n.nodeId;
 check("actual_public_begin",cjgui_internal_renderer_begin_composable_preparation(token,prep,base,scene,1)==0);
 check("actual_public_prepare",cjgui_internal_renderer_prepare_composable_node(token,prep,0,&n,&geom,"label","中😀value","semantic","binding","row","parent","accessible","")==0);
}
int main(void){
 _putenv("CJGUI_WINDOWS_TRACE_TIMING=1");_putenv("PHAROS_WINDOWS_TEST_PROBE_FILE=fixture-observe-only");
 CjguiInternalRendererConfig config={640,360,0.96,0.97,0.99,1};CjguiInternalRendererStatus status=-1;uint64_t token=cjgui_internal_renderer_create(&config,&status);
 check("real_window_device",token&&status==0);if(!token||status)return 1;
 prepare(token,201,0,1);uint32_t ready=0;
 check("actual_public_advance",cjgui_internal_renderer_advance_composable_preparation(token,201,cjgui_internal_renderer_owner_clock_ns()+1000000000ull,&ready)==0&&ready==1);
 check("actual_public_configure",cjgui_internal_renderer_configure_composable_scene(token,1,1)==0);
 check("actual_public_promote",cjgui_internal_renderer_promote_composable_preparation(token,201)==0);
 CjguiInternalRendererFrameObservation frame={0};check("actual_public_present",cjgui_internal_renderer_present_composable_scene(token,&frame)==0);
 prepare(token,202,1,2);check("actual_public_cancel",cjgui_internal_renderer_cancel_composable_preparation(token,202)==0);
 uint8_t mayBegin=0;check("actual_public_drain",cjgui_internal_renderer_drain_composable_retirement(token,cjgui_internal_renderer_owner_clock_ns()+1000000000ull,&mayBegin)==0&&mayBegin==1);
 CjguiWindowsRendererSession *live=find_session(token);check("normal_window_message_post",PostMessageW(live->hwnd,WM_NULL,0,0)!=0);
 CjguiInternalRendererEvent ev={0};uint64_t idle=0;int pumped=0;
 for(int i=0;i<20&&!idle;i++)if(cjgui_internal_renderer_pump_event_measured(token,16,&ev,&idle)==0)++pumped;
 check("actual_public_idle_pump",pumped>0&&idle>0);
 check("actual_ui_inspection",windows_dispatch_sync(token,"inspect_ui_timing",CJGUI_WINDOWS_CMD_GENERIC,inspect,NULL,NULL,3000,NULL)==0);
 FILE *tailOut=freopen("ui-final-trace.txt","wb",stderr);check("close_trace_output_open",tailOut!=NULL);
 check("actual_normal_destroy",cjgui_internal_renderer_destroy(token)==0);
 fflush(stderr);FILE *tail=fopen("ui-final-trace.txt","rb");char line[1024];int finalMarker=0,traceHeader=0;unsigned long long finalCount=0,ui=0;
 if(tail){while(fgets(line,sizeof(line),tail)){fputs(line,stdout);
  if(sscanf(line,"CJGUI_WINDOWS_TRACE_FINAL ui_thread=%llu total=%llu",&ui,&finalCount)==2)finalMarker=1;
  if(!strncmp(line,"TRACE enabled=1 total=",22))traceHeader=1;
 }fclose(tail);}
 check("destroy_final_trace_includes_last_ui_command",finalMarker&&traceHeader&&ui==inspectedUiThread&&finalCount>inspectedCount);

 printf("OBSERVATION_UNIT failures=%d\n",failures);return failures?1:0;
}

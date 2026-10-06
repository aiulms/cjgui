#!/usr/bin/env python3
"""Read-only host probe: exact production C branches, mocked Win32 dependencies.
Not a Windows/VM/render/full owner-chain test. Does not modify production source.
"""
from pathlib import Path
import hashlib, json, subprocess, tempfile
ROOT=Path(__file__).resolve().parents[3]
SRC=ROOT/'runtime/cjgui/platforms/windows/native/cjgui_windows_renderer.c'
src=SRC.read_text()
def extract(marker):
    start=src.index(marker); brace=src.index('{',start); level=1; i=brace+1
    while level:
        if src[i]=='{': level+=1
        elif src[i]=='}': level-=1
        i+=1
    return src[start:i]
gate=extract('static int source_install_gate_holds_input(CjguiWindowsRendererSession *s) {')
begin=extract('static int begin_windows_composition(CjguiWindowsRendererSession *s) {')
ime=extract('static int handle_windows_ime_composition(CjguiWindowsRendererSession *s, LPARAM flags) {')
clear=extract('static void clear_pending_owned_input(CjguiWindowsRendererSession *s) {')
restamp=extract('for (uint32_t restampIndex = 0u; restampIndex < s->eventCount; ++restampIndex) {')
prefix=r'''
#include <stdint.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <assert.h>
typedef intptr_t LPARAM;
typedef void *HIMC;
typedef long LONG;
#define WINDOWS_COMPOSITION_IDLE 0
#define WINDOWS_COMPOSITION_MARKED 1
#define WINDOWS_COMPOSITION_TERMINAL_QUEUED 2
#define WINDOWS_COMPOSITION_GATE_OPEN 0
#define WINDOWS_COMPOSITION_GATE_RECOVERING 1
#define CJGUI_INTERNAL_RENDERER_OK 0
#define CJGUI_INTERNAL_RENDERER_TEXT_COMPOSITION_COMMIT 2
#define CJGUI_WINDOWS_EVENT_CAPACITY 16
#define CJGUI_WINDOWS_EVENT_TEXT_BUDGET 65536
#define CJGUI_WINDOWS_ONE_STRING_BYTE_CAPACITY 1024
#define CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_TEXT_CHANGED 28
#define CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_TEXT_RANGE_CHANGED 51
#define CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_TEXT_COMPOSITION 52
#define CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_COMPOSABLE_SELECTION_CHANGED 33
#define GCS_RESULTSTR 1
#define GCS_COMPSTR 2
#define GCS_CURSORPOS 3
struct Node { uint64_t nodeId; int64_t resourceId; uint32_t nodeKind; };
typedef struct { struct Node node; const char *value; } CjguiWindowsSceneNode;
typedef struct { uint32_t kind; uint64_t projectionVersion, bindingEpoch; uint32_t selectionStart,selectionEnd; } Event;
typedef struct {
  int ownedTextSessionEnabled,sourceInstallPending,compositionState,compositionGate,eventQueueFull;
  uint64_t sourceInstallBindingEpoch,ownedTextSessionBindingEpoch,sourceInstallGatedInputs;
  uint32_t eventCount,eventHead; uint64_t eventTextBytes,sceneVersion;
  Event events[CJGUI_WINDOWS_EVENT_CAPACITY],pointerGeometries[CJGUI_WINDOWS_EVENT_CAPACITY];
  void *hwnd; int acceptedScene;
  uint64_t ownedTextSessionNodeId; int64_t ownedTextSessionResourceId; uint32_t ownedTextSessionNodeKind;
  uint32_t selectionStart16,selectionEnd16;
  char *compositionBaseUtf8,*compositionExpectedOwnerUtf8;
  uint64_t activeCompositionId,compositionBindingEpoch,compositionSceneVersion,compositionNodeId;
  int64_t compositionResourceId; uint32_t compositionNodeKind,compositionReplacementStart16,compositionReplacementLength16;
  uint32_t compositionTerminalReserved,compositionTerminalPhase,compositionActive,pendingHighSurrogate;
  uint64_t pendingHighSurrogateBindingEpoch;
  char *pendingOwnedInputBase,*pendingOwnedInputValue;
  uint64_t pendingOwnedInputSceneVersion,pendingOwnedInputBindingEpoch,pendingOwnedInputNodeId;
  int64_t pendingOwnedInputResourceId; uint32_t pendingOwnedInputNodeKind,pendingOwnedInputEventCount;
} CjguiWindowsRendererSession;
static CjguiWindowsSceneNode node={{7,9,23},"base"};
static uint64_t g_nextCompositionId;
static int updates,terminals,successors,resultFreed;
static void *resultAllocation;
static void tracked_free(void *p) { if (p && p==resultAllocation) { resultFreed++; resultAllocation=NULL; } free(p); }
#define free tracked_free
static CjguiWindowsSceneNode *scene_node_by_id(void *scene,uint64_t id) { (void)scene; (void)id; return &node; }
static int windows_validate_active_text(CjguiWindowsRendererSession *s,uint64_t id,int64_t resource,uint32_t kind,uint64_t scene,const char *value,void *out) { return 0; }
static char *duplicate_utf8_bytes(const char *v,size_t n) { char *p=malloc(n+1); memcpy(p,v,n);p[n]=0;return p; }
static uint64_t next_positive_counter(uint64_t *v) { return ++*v; }
static HIMC ImmGetContext(void *window) { return (void *)1; }
static int read_imm_utf8(HIMC context,int kind,char **text,uint32_t *bytes,uint32_t *units) { *text=strdup("X"); resultAllocation=*text; *bytes=*units=1; return 1; }
static LONG ImmGetCompositionStringW(HIMC c,int kind,void *p,uint32_t n) { return 0; }
static void ImmReleaseContext(void *w,HIMC c) {}
static int queue_windows_composition_update(CjguiWindowsRendererSession *s,const char *v,uint32_t n,uint32_t units) { updates++; return 1; }
static int queue_windows_composition_terminal(CjguiWindowsRendererSession *s,int phase,const char *v,uint32_t n) { terminals++;s->compositionState=WINDOWS_COMPOSITION_TERMINAL_QUEUED;return 1; }
static void remember_ime_successor(CjguiWindowsRendererSession *s,const char *v,uint32_t n,uint32_t units) { successors++; }
'''
main=r'''
static void restamp_exact_loop(CjguiWindowsRendererSession *s) { RESTAMP }
int main(void) {
  for (int gated=0;gated<2;gated++) {
    CjguiWindowsRendererSession s={0};s.ownedTextSessionEnabled=1;s.ownedTextSessionBindingEpoch=5;
    s.sourceInstallPending=gated;s.sourceInstallBindingEpoch=5;s.ownedTextSessionResourceId=9;s.ownedTextSessionNodeKind=23;
    updates=terminals=successors=resultFreed=0;
    int handled=handle_windows_ime_composition(&s,GCS_RESULTSTR);
    printf("{\"case\":\"ime_result_%s\",\"handled\":%d,\"result_freed\":%d,\"updates\":%d,\"terminals\":%d,\"successors\":%d,\"gate_count\":%llu,\"event_count\":%u,\"queue_full\":%d}\n",
      gated?"gate_pending":"baseline",handled,resultFreed,updates,terminals,successors,(unsigned long long)s.sourceInstallGatedInputs,s.eventCount,s.eventQueueFull);
    assert(handled==1 && resultFreed==1);
    if (gated) assert(updates==0 && terminals==0 && successors==0 && s.sourceInstallGatedInputs==1 && s.eventCount==0 && !s.eventQueueFull);
    else assert(updates==1 && terminals==1);
    free(s.compositionBaseUtf8);
  }
  CjguiWindowsRendererSession s={0};s.sceneVersion=42;s.eventCount=5;s.eventHead=14;
  uint32_t kinds[]={28,51,52,33,35};
  for (int i=0;i<5;i++) { unsigned slot=(14+i)%CJGUI_WINDOWS_EVENT_CAPACITY;
    s.events[slot]=(Event){kinds[i],41,5,2,2};s.pointerGeometries[slot]=s.events[slot]; }
  s.pendingOwnedInputBase=strdup("ab");s.pendingOwnedInputValue=strdup("abXY");s.pendingOwnedInputEventCount=2;
  restamp_exact_loop(&s);
  clear_pending_owned_input(&s);
  for (int i=0;i<5;i++) { unsigned slot=(14+i)%CJGUI_WINDOWS_EVENT_CAPACITY;
    printf("{\"case\":\"restamp_and_clear_pending\",\"kind\":%u,\"source_scene\":41,\"event_scene\":%llu,\"geometry_scene\":%llu,\"binding_epoch\":%llu,\"range_start\":%u,\"queue_remaining\":%u,\"pending_count\":%u}\n",
      kinds[i],(unsigned long long)s.events[slot].projectionVersion,(unsigned long long)s.pointerGeometries[slot].projectionVersion,(unsigned long long)s.events[slot].bindingEpoch,s.events[slot].selectionStart,s.eventCount,s.pendingOwnedInputEventCount);
    assert(s.events[slot].projectionVersion==(i<4?42:41));assert(s.events[slot].bindingEpoch==5); }
  assert(s.eventCount==5 && s.pendingOwnedInputEventCount==0);
  return 0;
}
'''.replace('RESTAMP',restamp)
with tempfile.TemporaryDirectory(prefix='windows-input-review-') as d:
    c=Path(d)/'probe.c';binary=Path(d)/'probe'
    c.write_text(prefix+'\n'+gate+'\n'+begin+'\n'+ime+'\n'+clear+'\n'+main)
    compiled=subprocess.run(['clang','-std=c11','-D_DARWIN_C_SOURCE','-Wno-unused-parameter',str(c),'-o',str(binary)],capture_output=True,text=True)
    if compiled.returncode: raise RuntimeError(compiled.stderr)
    run=subprocess.run([str(binary)],capture_output=True,text=True)
    if run.returncode: raise RuntimeError(run.stdout+run.stderr)
    result={'scope':'host-only exact extracted C branches with stub Win32 dependencies; not a Windows or full owner E2E test',
            'source':str(SRC),'source_sha256':hashlib.sha256(src.encode()).hexdigest(),
            'extracted_sha256':{name:hashlib.sha256(value.encode()).hexdigest() for name,value in [('gate',gate),('begin',begin),('ime',ime),('clear',clear),('restamp_loop',restamp)]},
            'observations':[json.loads(line) for line in run.stdout.splitlines()],
            'exit_code':run.returncode}
    output=Path(__file__).with_name('replay_native_input_seams_result.json');output.write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n')
    print(json.dumps(result,ensure_ascii=False,indent=2))

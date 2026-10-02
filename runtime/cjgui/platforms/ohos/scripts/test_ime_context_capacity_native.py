"""Production context serialization + actual host NAPI callback capacity seam."""
from pathlib import Path
import json,subprocess,tempfile,unittest
ROOT=Path(__file__).resolve().parents[1]

def extract(source,marker):
    start=source.index(marker);opening=source.index('{',start);depth=0
    for i in range(opening,len(source)):
        depth+=(source[i]=='{')-(source[i]=='}')
        if depth==0:return source[start:i+1]
    raise AssertionError(marker)

PREFIX=r'''
#include <algorithm>
#include <cstdint>
#include <cstdio>
#include <cstring>
#include <mutex>
#include <string>
#include <vector>
#include <iostream>
#define RLOGW(...) ((void)0)
#define HLOGI(...) ((void)0)
#define HLOGW(...) ((void)0)
using napi_env=void*;using napi_callback_info=void*;using napi_value=void*;
constexpr size_t NAPI_AUTO_LENGTH=static_cast<size_t>(-1);
static std::string g_result;
static int napi_create_string_utf8(napi_env,const char *p,size_t n,napi_value *out){g_result.assign(p,n==NAPI_AUTO_LENGTH?strlen(p):n);*out=nullptr;return 0;}
static void resolveImeEntryPoints(){}
struct NodePod {
 uint64_t nodeId=107; int64_t resourceId=1;uint32_t nodeKind=10,isReadOnly=0,isInteractive=1;
 int64_t x=28,y=64,width=333,height=108015;double fontSize=18;
};
struct SceneNode {NodePod pod;std::string semanticId="pharos-editor-body";};
struct Session {
 uint32_t textMenuIntent=0;
 uint64_t acceptedPaintTicketId=1,surfaceGeneration=9,surfaceGeometryRevision=1,editingProjectionVersion=27;
 struct {bool armed=false,awaitingAck=false,platformInstalled=false;} proxyRestore;
 struct {bool active=false,terminal=false;} selectionDrag;
 struct {bool valid=false,startVisible=false;uint64_t ticket=0,generation=0,geometryRevision=0,projection=0;
 int64_t context=0;uint32_t start=0,end=0;std::u16string text;double startX=0,endX=0,startLineY=0,endLineY=0;} selectionHandles;
 bool inUse=true,editing=true,editorRetired=false,editingContextLive=true;
 int64_t editingContextId=51;uint64_t editingNodeId=107;int64_t editingResourceId=1;
 uint32_t editingNodeKind=10,selStartUtf16=5,selEndUtf16=10;
 std::string editingFieldName="pharos-editor-body";
 uint64_t editingContextGeneration=9,editingContextBaseVersion=27,token=1;
 double surfaceDensity=3.5;
 bool markedCallbackObserved=false,previewActive=false,markedActive=false;
 uint32_t previewStart=5,previewEnd=10,markedStart=5,markedEnd=10;
 std::u16string editingText=u"alpha Z",previewText;
 std::vector<SceneNode> accepted{SceneNode{}};
};
constexpr size_t kMaxSessions=1;
struct SessionTable{std::mutex lock;Session sessions[1];};static SessionTable g_sessions;
'''
MAIN=r'''
int main(int argc,char **argv){
 if(argc!=2)return 2;std::string name=argv[1];Session &s=g_sessions.sessions[0];
 if(name=="body")s.editingText=std::u16string(262144,u'x');
 if(name=="escaped_preview"){s.editingText=std::u16string(262144,1);s.previewActive=true;s.previewText=std::u16string(262144,2);s.markedActive=true;}
 if(name=="over_bound")s.editingText=std::u16string(1048576,1);
 if(name=="retired")s.editorRetired=true;
 if(name=="not_live")s.editingContextLive=false;
 if(name=="idle_caret"||name=="explicit_caret"||name=="ghost_after_navigation"||name=="selected_menu"){
  s.selStartUtf16=s.selEndUtf16=5;
  if(name=="explicit_caret")s.textMenuIntent=2;
  if(name=="ghost_after_navigation")s.textMenuIntent=1;
  if(name=="selected_menu"){s.selEndUtf16=6;s.textMenuIntent=1;}
  auto &m=s.selectionHandles;m.valid=m.startVisible=true;m.ticket=s.acceptedPaintTicketId;
  m.context=s.editingContextId;m.text=s.editingText;m.start=5;m.end=s.selEndUtf16;
  m.generation=s.surfaceGeneration;m.geometryRevision=s.surfaceGeometryRevision;m.projection=s.editingProjectionVersion;
 }
 if(name=="small_guard"){
  char guarded[34];memset(guarded,'Z',sizeof(guarded));int rc=ohos_renderer_ime_context_json(guarded+1,32);
  if(rc!=0||guarded[0]!='Z'||guarded[33]!='Z')return 9;
  for(int i=1;i<33;i++)if(guarded[i]!='Z')return 10;
  std::cout<<"guarded";return 0;
 }
 ImeEditingContext(nullptr,nullptr);std::cout<<g_result;
}
'''

def harness():
    renderer=(ROOT/'host/ohos_renderer.cpp').read_text();bridge=(ROOT/'host/cjgui_host_bridge.cpp').read_text()
    native='\n'.join(extract(renderer,m) for m in (
      'std::string utf16ToUtf8(const std::u16string &utf16)',
      'Session *findEditingSessionLocked()',
      'static void appendJsonEscaped(std::string &out, const std::string &value)\n{',
      'extern "C" int32_t ohos_renderer_ime_context_json(char *out, int32_t capacity)'))
    host=extract(bridge,'static napi_value ImeEditingContext(napi_env env, napi_callback_info info)')
    return PREFIX+native+'\nstatic auto imeContextQueryFn=&ohos_renderer_ime_context_json;\n'+host+MAIN

class ImeContextCapacityNativeTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.tmp=tempfile.TemporaryDirectory(prefix='cjgui-ime-context-capacity-');p=Path(cls.tmp.name)
        (p/'probe.cpp').write_text(harness());cls.exe=p/'probe'
        r=subprocess.run(['clang++','-std=c++17','-Wall','-Wextra','-Werror',str(p/'probe.cpp'),'-o',str(cls.exe)],capture_output=True,text=True)
        if r.returncode:raise RuntimeError(r.stderr)
    @classmethod
    def tearDownClass(cls):cls.tmp.cleanup()
    def run_case(self,name):return subprocess.check_output([str(self.exe),name],text=True)
    def test_small_context_remains_exact(self):
        d=json.loads(self.run_case('small'));self.assertEqual(d['text'],'alpha Z');self.assertEqual([d['context'],d['selStart'],d['selEnd']],[51,5,10])
    def test_idle_caret_geometry_does_not_request_a_toolbar(self):
        d=json.loads(self.run_case('idle_caret'));self.assertFalse(d['menuAvailable'])
    def test_explicit_caret_or_selected_menu_has_current_paint_coordinates(self):
        for name in ['explicit_caret','selected_menu']:
            d=json.loads(self.run_case(name));self.assertTrue(d['menuAvailable']);self.assertIn('menuX',d)
        self.assertFalse(json.loads(self.run_case('ghost_after_navigation'))['menuAvailable'])
    def test_full_256k_body_is_installed_without_truncation(self):
        d=json.loads(self.run_case('body'));self.assertEqual(d['text'],'x'*262144);self.assertEqual(d['baseVersion'],27)
    def test_worst_escaped_body_and_preview_both_remain_complete(self):
        d=json.loads(self.run_case('escaped_preview'));self.assertEqual(d['text'],'\x01'*262144);self.assertEqual(d['previewText'],'\x02'*262144);self.assertEqual([d['markedStart'],d['markedEnd']],[5,10])
    def test_retired_and_not_live_contexts_never_become_snapshots(self):
        self.assertEqual(self.run_case('retired'),'');self.assertEqual(self.run_case('not_live'),'')
    def test_excessive_context_fails_closed_without_partial_string(self):self.assertEqual(self.run_case('over_bound'),'')
    def test_insufficient_output_buffer_writes_no_prefix_or_canary(self):self.assertEqual(self.run_case('small_guard'),'guarded')

if __name__=='__main__':unittest.main()

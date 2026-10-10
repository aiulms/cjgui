#!/usr/bin/env python3
"""Execute the production caret query with same-scene and stale identity cases."""
from pathlib import Path
import subprocess
import tempfile
import sys
SOURCE = Path(__file__).resolve().parents[1]/'host/ohos_renderer.cpp'
def block(text, marker):
    start=text.index(marker); opening=text.index('{',start); depth=0
    for i in range(opening,len(text)):
        depth+=(text[i]=='{')-(text[i]=='}')
        if depth==0:return text[start:i+1]
    raise ValueError(marker)
def run():
    source=SOURCE.read_text()
    new='ohos_renderer_accepted_active_caret_rect' in source
    fact=block(source,'struct AcceptedCaretRect {')+';' if new else ''
    query=block(source,'extern "C" int32_t ohos_renderer_accepted_active_caret_rect(' if new else
        'extern "C" int32_t ohos_renderer_editing_caret_range(')
    setup='''
  s.activeCaret.valid=true; s.activeCaret.nodeId=7; s.activeCaret.resourceId=9;
  s.activeCaret.kind=3; s.activeCaret.binding=11; s.activeCaret.projection=10;
  s.activeCaret.ticket=4; s.activeCaret.context=2; s.activeCaret.generation=5;
  s.activeCaret.geometry=2; s.activeCaret.caret=6;
  s.activeCaret.left=20; s.activeCaret.top=20; s.activeCaret.right=22; s.activeCaret.bottom=40;
  s.activeCaret.text=u"note";
''' if new else '''s.editingCaretRectValid=true;s.editingCaretNodeId=7;s.editingCaretTopVp=20;s.editingCaretBottomVp=40;'''
    call='ohos_renderer_accepted_active_caret_rect(1,7,&node,&binding,&left,&top,&right,&bottom)' if new else 'ohos_renderer_editing_caret_range(1,&node,&top,&bottom)'
    code='''
#include <cstdint>
#include <mutex>
#include <vector>
#include <cstdio>
#include <string>
FACT
struct Pod { uint64_t nodeId=7, acceptedBindingEpoch=11; int64_t resourceId=9; uint32_t nodeKind=3; };
struct Node { Pod pod; };
using SceneNode = Node;
struct Session {
  bool editing=true,editorRetired=false,editingContextLive=true;
  int64_t editingContextId=2;
  uint64_t acceptedSceneVersion=7,acceptedProjectionVersion=10,acceptedPaintTicketId=4;
  uint64_t surfaceGeneration=5,surfaceGeometryRevision=2;
  uint32_t caretUtf16=6;
  std::u16string text=u"note";
  std::vector<Node> accepted={Node{}};
  bool editingCaretRectValid=false; uint64_t editingCaretNodeId=0;
  double editingCaretTopVp=0,editingCaretBottomVp=0;
  NEWFIELD
} s;
struct { std::mutex lock; } g_sessions;
Session *lookupSessionLocked(uint64_t token) { return token==1?&s:nullptr; }
const std::u16string &composedBuffer(const Session &session) { return session.text; }
QUERY
int main() {
  SETUP
  uint64_t node=0,binding=0; double left=0,top=0,right=0,bottom=0;
  int failures=0;
  auto query=[&]{return CALL;};
  auto check=[&](bool good,const char *name){std::printf("%s %s\\n",good?"PASS":"FAIL",name);if(!good)++failures;};
  check(query()==1,"accepted source/presentation caret available");
  ++s.acceptedSceneVersion;check(query()!=1,"old scene refused");--s.acceptedSceneVersion;
  ++s.surfaceGeometryRevision;check(query()!=1,"old surface geometry refused");--s.surfaceGeometryRevision;
  ++s.accepted[0].pod.acceptedBindingEpoch;check(query()!=1,"old binding refused");--s.accepted[0].pod.acceptedBindingEpoch;
  ++s.caretUtf16;check(query()!=1,"old active endpoint refused");
  return failures;
}
'''.replace('FACT',fact).replace('NEWFIELD','AcceptedCaretRect activeCaret;' if new else '')
    code=code.replace('QUERY',query).replace('SETUP',setup).replace('CALL',call)
    with tempfile.TemporaryDirectory(prefix='cjgui-active-caret-') as temp:
        root=Path(temp);(root/'main.cpp').write_text(code)
        subprocess.run(['clang++','-std=c++17',str(root/'main.cpp'),'-o',str(root/'test')],check=True)
        return subprocess.run([str(root/'test')]).returncode
if __name__=='__main__':sys.exit(run())

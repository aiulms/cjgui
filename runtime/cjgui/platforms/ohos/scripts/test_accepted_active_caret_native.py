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
#include "cjgui_ohos_text_coverage.h"
#define RLOGI(...) ((void)0)
FACT
struct Pod { uint64_t nodeId=7, acceptedBindingEpoch=11; int64_t resourceId=9; uint32_t nodeKind=3; };
struct Node { Pod pod; };
using SceneNode = Node;
struct Session {
  bool editing=true,editorRetired=false,editingContextLive=true;
  int64_t editingContextId=2;
  uint64_t acceptedSceneVersion=7,acceptedProjectionVersion=10,acceptedPaintTicketId=4;
  uint64_t surfaceGeneration=5,surfaceGeometryRevision=2;
  uint64_t caretPaintProgress=1;
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
// Controlled callees; this query test is explicitly unowned. Covered-body
// authority is not replaced by a guessed success in this fixture.
static bool cjguiOhosActiveEndCurrent(const Session &s,const AcceptedCaretRect&r){if(r.coverage)std::abort();return r.caret==s.caretUtf16;}
static bool cjguiOhosCoverageCurrent(const Session&,const CjguiOhosCoverage&){std::abort();}
REFUSAL
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
    refusal=block(source,'static const char *cjguiOhosAcceptedCaretRefusal(') if 'static const char *cjguiOhosAcceptedCaretRefusal(' in source else ''
    code=code.replace('REFUSAL',refusal).replace('QUERY',query).replace('SETUP',setup).replace('CALL',call)
    with tempfile.TemporaryDirectory(prefix='cjgui-active-caret-') as temp:
        root=Path(temp);(root/'main.cpp').write_text(code)
        subprocess.run(['clang++','-std=c++17','-I'+str(SOURCE.parents[1]/'host'),str(root/'main.cpp'),'-o',str(root/'test')],check=True)
        return subprocess.run([str(root/'test')]).returncode

def text_lines():
    """Actual value producer + query; SDK metrics and current-caret verdict controlled.
    Does not claim full frame publication or normal application acceptance.
    """
    source=SOURCE.read_text()
    entries=['struct AcceptedTextLineBands {','static AcceptedTextLineBands cjguiOhosPaintedTextLineBands(',
             'extern "C" int32_t ohos_renderer_accepted_text_line_bands(']
    if any(e not in source for e in entries):
        print('FAIL current native has no published text-line geometry route',flush=True);return 31
    fact=block(source,entries[0])+';'
    producer=block(source,entries[1]);query=block(source,entries[2])
    code=r'''
#include "cjgui_internal_renderer.h"
#include "cjgui_ohos_text_coverage.h"
#include <cmath>
#include <mutex>
#include <vector>
#include <cstdio>
#include <cassert>
struct OH_Drawing_LineMetrics {double y=0,height=0;};
struct OH_Drawing_Typography {std::vector<OH_Drawing_LineMetrics> lines;};
int metricReads=0;
size_t OH_Drawing_TypographyGetLineCount(OH_Drawing_Typography*p){return p->lines.size();}
bool OH_Drawing_TypographyGetLineMetricsAt(OH_Drawing_Typography*p,int i,OH_Drawing_LineMetrics*out){
 ++metricReads;if(i<0 || size_t(i)>=p->lines.size())return false;*out=p->lines[i];return true;
}
FACT
struct SceneNode {CjguiInternalRendererComposableNode pod{};};
struct Session {
 uint64_t acceptedSceneVersion=7,acceptedProjectionVersion=10,acceptedPaintTicketId=4;
 uint64_t surfaceGeneration=5,surfaceGeometryRevision=2;
 std::vector<SceneNode>accepted;std::vector<AcceptedTextLineBands>textLineBands;
 struct OwnedMirrorDeclaration {CjguiOhosCoverage coverage;std::u16string text;std::string sourceBasis;} mirror;
 bool caretCurrent=true;
 struct {uint64_t nodeId=7,binding=11;}activeCaret;
} s,other;
struct {std::mutex lock;}g_sessions;
static Session*lookupSessionLocked(uint64_t token){return token==1?&s:token==2?&other:nullptr;}
static const char*cjguiOhosAcceptedCaretRefusal(const Session&v,uint64_t){return v.caretCurrent?nullptr:"active_end_stale";}
static const Session::OwnedMirrorDeclaration*ownedMirrorDeclarationLocked(const Session&v,uint64_t,int64_t,uint32_t){return &v.mirror;}
PRODUCER
QUERY
int main(){
 CjguiInternalRendererComposableNode n{};n.nodeId=7;n.resourceId=9;n.nodeKind=3;n.acceptedBindingEpoch=11;
 n.x=36;n.y=-623;n.width=305;n.height=934;s.accepted.push_back({n});
 OH_Drawing_Typography t{{{4,20},{24,20},{44,37}}};
 auto b=cjguiOhosPaintedTextLineBands(n,&t,100,4,10,5,2);
 assert(b.valid && b.firstTop==104 && b.firstBottom==124 && b.lastTop==144 && b.lastBottom==181);
 s.textLineBands={b};double a=0,z=0,c=0,d=0;const int reads=metricReads;
 auto q=[&]{return ohos_renderer_accepted_text_line_bands(1,7,7,11,&a,&z,&c,&d);};
 assert(q()==1 && a==104 && z==124 && c==144 && d==181 && metricReads==reads);
 other.accepted={{n}};auto second=b;second.nodeY+=200;other.accepted[0].pod.y+=200;
 second.firstTop+=200;second.firstBottom+=200;second.lastTop+=200;second.lastBottom+=200;other.textLineBands={second};
 assert(ohos_renderer_accepted_text_line_bands(2,7,7,11,&a,&z,&c,&d)==1 && a==304);
 assert(q()==1 && a==104);
 ++s.acceptedSceneVersion;assert(q()==0);--s.acceptedSceneVersion;
 ++s.surfaceGeometryRevision;assert(q()==0);--s.surfaceGeometryRevision;
 ++s.surfaceGeneration;assert(q()==0);--s.surfaceGeneration;
 ++s.acceptedPaintTicketId;assert(q()==0);--s.acceptedPaintTicketId;
 ++s.acceptedProjectionVersion;assert(q()==0);--s.acceptedProjectionVersion;
 ++s.accepted[0].pod.acceptedBindingEpoch;assert(q()==0);--s.accepted[0].pod.acceptedBindingEpoch;
 ++s.accepted[0].pod.y;assert(q()==0);--s.accepted[0].pod.y;
 s.textLineBands[0].dynamicText=true;s.caretCurrent=false;assert(q()==0);s.caretCurrent=true;assert(q()==1);
 s.textLineBands[0].dynamicText=false;
 CjguiOhosTextCoverage body;body.ownerVersion=1;body.layoutOrigin=body.platformOrigin=0;
 body.layout=body.platform=std::make_shared<const std::u16string>(u"note");body.bodyBasis="frozen body";
 const auto owned=CjguiOhosTextCoverage::prove(body);assert(owned);
 auto&band=s.textLineBands[0];band.coverage=owned;band.activeValid=true;band.activeTop=144;band.activeBottom=181;
 s.mirror={owned,u"note","frozen body"};assert(q()==1);
 s.mirror.sourceBasis="new owner selection";assert(q()==0);s.mirror.sourceBasis="frozen body";
 s.mirror.text=u"new body";assert(q()==0);s.mirror.text=u"note";
 s.mirror.coverage=CjguiOhosTextCoverage::prove(body);assert(q()==0);s.mirror.coverage=owned;
 band.activeValid=false;assert(q()==0);band.activeValid=true;assert(q()==1);
 OH_Drawing_Typography empty{{{0,24}}};auto e=cjguiOhosPaintedTextLineBands(n,&empty,100,4,10,5,2);
 assert(e.valid && e.firstBottom-e.firstTop==24 && e.lastBottom-e.lastTop==24);
 OH_Drawing_Typography tall{{{0,200}}};auto h=cjguiOhosPaintedTextLineBands(n,&tall,100,4,10,5,2);
 assert(h.valid && h.lastBottom-h.lastTop==200);
 OH_Drawing_Typography unknown{};assert(!cjguiOhosPaintedTextLineBands(n,&unknown,100,4,10,5,2).valid);
 tall.lines[0].height=std::nan("");assert(!cjguiOhosPaintedTextLineBands(n,&tall,100,4,10,5,2).valid);
 assert(ohos_renderer_accepted_text_line_bands(3,7,7,11,&a,&z,&c,&d)==-1);
 assert(metricReads==reads+3);
 puts("PASS actual line-band producer/query: real metric values, bounded reads, stale identities, active endpoint gate, no layout/SDK on query");
}
'''.replace('FACT',fact).replace('PRODUCER',producer).replace('QUERY',query)
    platform=SOURCE.parents[1]
    with tempfile.TemporaryDirectory(prefix='cjgui-text-lines-') as temp:
        root=Path(temp);(root/'main.cpp').write_text(code)
        subprocess.run(['clang++','-std=c++17','-I'+str(platform/'snapshot'),'-I'+str(platform/'host'),str(root/'main.cpp'),'-o',str(root/'test')],check=True)
        return subprocess.run([str(root/'test')]).returncode

if __name__=='__main__':sys.exit(text_lines() if '--text-lines' in sys.argv else run())

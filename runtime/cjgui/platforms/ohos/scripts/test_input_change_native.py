"""Actual native Will/Change, immutable pool and kind-51 producer; no service/GPU claim."""
from pathlib import Path
import subprocess,tempfile
import test_ime_range_delta_native as old
p=Path(__file__).resolve().parents[1];s=(p/'host/ohos_renderer.cpp').read_text()
pieces='\n'.join(old.extract_method(s,k) for k in old.SIGNATURES)
replica=old.REPLICA.replace('struct Session {','''struct Session {
  struct OwnedMirrorDeclaration { std::u16string text; int64_t ownerContentVersion=1; std::string sourceBasis; } ownedMirrorAccepted;
  CjguiOhosFocusAuthority focusAuthority; CjguiOhosEditTickets inputTickets;
  CjguiOhosEditTickets::Ticket lastCompletedInputTicket, lastEventInputTicket;
  std::string editingInputSourceBasis,editingFieldName="body";
  bool editingContextLive=true,editorRetired=false,markedActive=false,previewActive=false;
  uint64_t editingAcceptedBindingEpoch=8;std::u16string previewText;
''',1)
stub='''#include "cjgui_ohos_ingress.h"
#include "cjgui_ohos_edit_ticket.h"
#include <mutex>
#include <cstdio>
'''+old.STUBS+replica+pieces+'''
static Session *current;
static struct {std::mutex lock;} g_sessions;
static Session *lookupSessionLocked(uint64_t session){return session==1?current:nullptr;}
static const Session::OwnedMirrorDeclaration *ownedMirrorDeclarationLocked(Session &s,uint64_t,int64_t,uint32_t){return &s.ownedMirrorAccepted;}
struct RedrawJob{};struct {void post(std::shared_ptr<RedrawJob>) {}} g_render;
'''
entries='\n'.join(old.extract_method(s,k) for k in ['extern "C" int64_t ohos_renderer_input_will(', 'extern "C" int32_t ohos_renderer_input_change('])
main=r'''
void setup(Session &s){current=&s;s.ownedTextSessionEnabled=true;s.rangeEditDeltaRequested=true;
s.editingNodeId=s.ownedTextSessionNodeId=107;s.editingResourceId=s.ownedTextSessionResourceId=1;
s.editingNodeKind=s.ownedTextSessionNodeKind=10;s.ownedTextSessionBindingEpoch=9;s.editingProjectionVersion=3;
s.editingContextId=10;s.editingContextGeneration=3;s.editingMirrorOwnerVersion=1;
s.editingText=u"ABABAB";s.ownedMirrorAccepted.text=s.editingText;
s.ownedMirrorAccepted.sourceBasis="1,1,1,1,0,12291,1,7,0,12291,0,6,0";
s.focusAuthority.issue(107,1,10,8,"body");s.focusAuthority.bind({7,1,3,1,10});}
int64_t will(const char *before,const char *after,uint32_t start,uint32_t end,uint32_t ae,uint64_t mount=1){
return ohos_renderer_input_will(before,std::strlen(before),after,std::strlen(after),"body",start,end,start,ae,7,1,10,3,mount,1);}
int change(const char *after,int64_t id,uint64_t mount=1){return ohos_renderer_input_change(after,std::strlen(after),id,7,1,10,3,mount,1);}
int main(){
 {Session s;setup(s);auto id=will("ABABAB","ABABABAB",0,6,8);if(id<=0)return 1;
 s.ownedMirrorAccepted.sourceBasis="new owner revision"; // Will origin must stay frozen.
 if(change("ABABABAB",id)!=0 || s.events.size()!=1)return 2;
 auto &e=s.events.front();if(e.selectionStart!=0 || e.selectionEnd!=6 || e.text!="ABABABAB")return 3;
 if(!e.inputTicket || e.inputTicket->sourceBasis!="1,1,1,1,0,12291,1,7,0,12291,0,6,0" || e.editingContextId!=10 || e.editingContextGeneration!=3)return 4;
 if(change("ABABABAB",id)==0 || s.events.size()!=1)return 5;
 auto next=will("ABABABAB","ABABABABX",8,8,9);if(next<=id)return 6;
 if(change("ABABABABX",next)!=0 || s.events.back().inputTicket->predecessor!=static_cast<uint64_t>(id))return 7;
 }
 {Session s;setup(s);auto id=will("ABABAB","ABABABAB",0,6,8);if(id<=0)return 8;
 if(change("ABABABAX",id)==0 || !s.events.empty() || s.editingText!=u"ABABAB")return 9;}
 {Session s;setup(s);auto id=will("ABABAB","ABABABAB",0,6,8);s.focusAuthority.setForeground(false);
 if(change("ABABABAB",id)==0 || !s.events.empty())return 10;}
 {Session s;setup(s);if(will("ABABAB","ABABABAB",0,6,8,2)>0 || change("ABABABAB",1,2)==0 || !s.events.empty())return 11;}
 {Session s;setup(s);if(will("ABABAB","ABABAB",0,6,6)>0)return 12;}
 {CjguiOhosEditTickets pool;std::vector<CjguiOhosEditTickets::Ticket> pinned;
 for(size_t i=0;i<32;++i){CjguiOhosEditTicket t;t.key={7,1,3,1,10};t.before=u"a";t.after=u"b";pinned.push_back(pool.admit(t));if(!pinned.back())return 13;}
 CjguiOhosEditTicket extra;if(pool.admit(extra))return 14;pool.clear();pinned.clear();if(pool.liveCount()!=0)return 15;}
 puts("PASS actual Will frozen source/range, paired Change, predecessor, duplicate, old mount, Home and bounded lifecycle");return 0;}
'''
with tempfile.TemporaryDirectory() as tmp:
    d=Path(tmp)
    for withdraw in [False,True]:
        body=entries
        if withdraw:body=body.replace('editorEnqueueTextCommit(*s,before,after,origin)','editorEnqueueTextCommit(*s,before,after)')
        cpp=d/('withdraw.cpp' if withdraw else 'actual.cpp');cpp.write_text(stub+'#include <cstring>\n'+body+main)
        binary=cpp.with_suffix('')
        subprocess.run(['clang++','-std=c++17','-I'+str(p/'host'),str(cpp),'-o',str(binary)],check=True)
        r=subprocess.run([str(binary)])
        if withdraw:
            assert r.returncode==3,r.returncode;print('isolated actual-range withdrawal RED: 3')
        else:assert r.returncode==0,r.returncode

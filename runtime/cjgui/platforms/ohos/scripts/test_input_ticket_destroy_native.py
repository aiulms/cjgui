#!/usr/bin/env python3
"""Actual native destroy must release newly owned input/choice receipts.

The Session registry, image/fact notifications and GPU are controlled shims.
The destroy body, input/choice storage classes and renderer status ABI are
production source. Weak handles observe actual payload ownership while the
retired fixed Session slot remains alive. This is not device RSS evidence.
"""
from pathlib import Path
import re
import subprocess
import sys
import tempfile

PLATFORM = Path(__file__).resolve().parents[1]
SOURCE = PLATFORM / "host/ohos_renderer.cpp"


def function(source, signature):
    assert source.count(signature) == 1, signature
    start = source.index(signature)
    opening = source.index("{", start)
    tokens = re.compile(r'//[^\n]*|/\*[\s\S]*?\*/|"(?:\\.|[^"\\])*"|\'(?:\\.|[^\'\\])*\'|[{}]')
    depth = 0
    for match in tokens.finditer(source, opening):
        if match.group() == "{":
            depth += 1
        elif match.group() == "}":
            depth -= 1
            if depth == 0:
                return source[start:match.end()]
    raise ValueError(signature)


PREFIX = r'''
#include "cjgui_internal_renderer.h"
#include "cjgui_ohos_edit_ticket.h"
#include "cjgui_ohos_original_insert.h"
#include <deque>
#include <map>
#include <mutex>
#include <cstdio>
#define RLOGI(...) do{}while(0)
#define RLOGW(...) do{}while(0)
// @LINEFACT
struct SceneNode {};
struct QueuedEvent {
    CjguiOhosEditTickets::Ticket inputTicket;
    CjguiOhosChoiceSources::Receipt choiceObservation;
    uint32_t kind=51;
    uint32_t recordIndex=0;
};
struct Session {
    bool inUse = false, editing = false;
    bool editingContextLive=true,editorRetired=false;
    int64_t editingContextId=10;uint64_t editingContextGeneration=3;
    uint64_t token = 0, acceptedProjectionVersion = 0;
    int64_t ticketDestroyRefusedCount = 0;
    std::vector<SceneNode> accepted, candidate;
    std::map<uint64_t, int> acceptedRunTable, buildingRunTable, imageObservedSerial;
    std::deque<QueuedEvent> events;
    struct TouchGesture {} gesture;
    std::u16string editingText, previewText;
    CjguiOhosFocusAuthority focusAuthority;
    struct OwnedMirrorDeclaration {CjguiOhosEditTickets::OwnerReceipt ownerAcceptance;CjguiOhosCoverage coverage;} ownedMirrorStaged,ownedMirrorAccepted;
    struct ProxyRestoreRequest {} proxyRestore;
    CjguiOhosOriginalInserts::OwnerResult pendingOriginalResult,consumedOriginalResult;
    CjguiOhosOriginalInserts originalInserts;
    CjguiOhosOriginalInserts::Command lastEventOriginalInsert;
    CjguiOhosAcceptedSelection acceptedSelection;
    CjguiOhosSelectionCapture selectionCapture;
    CjguiOhosSelectionCommandState selectionCommandState;
    struct {CjguiOhosCoverage coverage;}activeCaret,humanAnchor;
    std::vector<AcceptedTextLineBands>textLineBands;
    CjguiOhosEditTickets::Ticket dirtyInputTicket;
    CjguiOhosChoiceSources::Receipt consumedRestoreChoice;
    CjguiOhosEditTickets inputTickets;
    CjguiOhosChoiceSources choiceSources;
    CjguiOhosChoiceSources::Receipt lastEventChoice;
    CjguiOhosEditTickets::Ticket lastCompletedInputTicket, lastEventInputTicket;
    uint64_t inputOwnerCompleted = 0;
    bool inputOwnerFailed = false;
};
struct { std::mutex lock; Session sessions[2]; int occupied = 0; } g_sessions;
struct Pending { bool valid = false; void *job = nullptr; std::vector<int> nodes; } g_pending[2];
struct OhosAcceptedFact {};
struct { uint64_t token = 0, epoch = 0; OhosAcceptedFact fact; } g_acceptedFact[2];
std::mutex g_acceptedFactLock;
static int sessionSlotLocked(uint64_t token) {
    for (int i = 0; i < 2; ++i)
        if (g_sessions.sessions[i].inUse && g_sessions.sessions[i].token == token) return i;
    return -1;
}
static Session *lookupSessionLocked(uint64_t token) {
    const int slot = sessionSlotLocked(token);
    return slot < 0 ? nullptr : &g_sessions.sessions[slot];
}
static void cjguiOhosLogAcceptedImageSwap(const Session &, const std::vector<SceneNode> &,
                                         uint64_t, uint64_t, const char *) {}
static void cjguiOhosPruneReleasedImages() {}
'''

MAIN = r'''
struct Observers {
    std::weak_ptr<const CjguiOhosEditTicket> ticket;
    std::weak_ptr<CjguiOhosChoiceReceipt> choice;
    std::weak_ptr<const CjguiOhosTextCoverage> coverage;
};
static Observers arm(int slot, uint64_t token) {
    Session &s = g_sessions.sessions[slot];
    s.inUse = true; s.token = token; ++g_sessions.occupied;
    CjguiOhosChoiceOrigin origin;
    origin.key = {7, token, 3, 1, 10}; origin.text = u"xyz";
    origin.bodyBasis = "1,1,1,1,0,3,1,2,0,0,0,0";
    CjguiOhosTextCoverage c;c.ownerVersion=1;c.layoutOrigin=c.platformOrigin=0;
    c.layout=c.platform=std::make_shared<const std::u16string>(u"xyz");
    origin.coverage=CjguiOhosTextCoverage::prove(c);
    auto choice = s.choiceSources.observe(std::move(origin));
    if (!choice || !s.choiceSources.settle(choice, true,
        "1,1,1,1,0,3,1,2,0,0,0,0")) std::abort();
    CjguiOhosEditTicket input;
    input.key = choice->origin->key; input.choice = choice;input.ownerBinding=9;
    input.before = u"xyz"; input.after = u"xyAz"; input.inserted = u"A";
    auto ticket = s.inputTickets.admit(std::move(input));
    if (!ticket) std::abort();
    s.inputTickets.consume(ticket->id,ticket->key,ticket->before,ticket->after);
    s.inputTickets.complete(ticket->id,true,2,0,"1,1,2,2,0,4,2,2,0,0,0,0");
    const auto owner=s.inputTickets.acceptedForBody(9,2,"1,1,2,2,0,4,2,2,0,0,0,0");
    s.ownedMirrorStaged.ownerAcceptance=s.ownedMirrorAccepted.ownerAcceptance=owner;
    s.ownedMirrorStaged.coverage=s.ownedMirrorAccepted.coverage=choice->origin->coverage;
    s.activeCaret.coverage=s.humanAnchor.coverage=choice->origin->coverage;
    AcceptedTextLineBands bands;bands.coverage=choice->origin->coverage;s.textLineBands.push_back(std::move(bands));
    s.focusAuthority.transfer.inputOwner=owner;
    s.dirtyInputTicket=ticket;s.consumedRestoreChoice=choice;
    s.lastCompletedInputTicket = s.lastEventInputTicket = ticket;
    s.lastEventChoice = choice;
    s.events.push_back({ticket, choice});
    s.inputOwnerCompleted = ticket->id; s.inputOwnerFailed = true;
    g_acceptedFact[slot].token = token;
    return {ticket, choice,choice->origin->coverage};
}
int main() {
    auto first = arm(0, 91); auto other = arm(1, 92);
    // Preserve original unacknowledged-present guard and all payload ownership.
    g_pending[0].valid = true;
    if (cjgui_internal_renderer_destroy(91) != CJGUI_INTERNAL_RENDERER_PENDING_SETTLEMENT_UNRESOLVED)
        return 10;
    if (first.ticket.expired() || first.choice.expired() || g_sessions.occupied != 2) return 11;
    // The original presentation has now reached its acknowledged terminal.
    g_pending[0].valid = false;
    if (cjgui_internal_renderer_destroy(91) != CJGUI_INTERNAL_RENDERER_OK) return 12;
    Session &retired = g_sessions.sessions[0];
    std::printf("successful_destroy inputExpired=%d choiceExpired=%d pending=%zu liveInput=%zu liveChoice=%zu\n",
        first.ticket.expired(), first.choice.expired(), retired.inputTickets.pendingCount(),
        retired.inputTickets.liveCount(), retired.choiceSources.liveCount());
    if (!first.coverage.expired() || !first.ticket.expired() || !first.choice.expired() ||
        retired.inputTickets.pendingCount() || retired.inputTickets.liveCount() ||
        retired.choiceSources.liveCount()) return 21;
    if (retired.lastEventInputTicket || retired.lastCompletedInputTicket || retired.lastEventChoice ||
        retired.inputOwnerCompleted || retired.inputOwnerFailed || retired.token || retired.inUse) return 22;
    // Destroy is scoped to the exact original token and leaves another window live.
    if (other.ticket.expired() || other.choice.expired() || g_sessions.occupied != 1 ||
        g_acceptedFact[1].token != 92) return 23;
    if (cjgui_internal_renderer_destroy(91) != CJGUI_INTERNAL_RENDERER_INVALID_SESSION) return 24;
    if (cjgui_internal_renderer_destroy(92) != CJGUI_INTERNAL_RENDERER_OK) return 25;
    if (!other.coverage.expired() || !other.ticket.expired() || !other.choice.expired() || g_sessions.occupied) return 26;
    std::puts("PASS actual destroy releases input/choice queue + stream + dequeued receipt; original pending guard and other token preserved");
    return 0;
}
'''


CHAIN_MAIN = r'''
static int inputChain() {
    {
        Session s;CjguiOhosChoiceOrigin origin;origin.key={7,1,3,1,10};origin.text=u"x";origin.prefix={999};
        const auto q=s.choiceSources.observe(std::move(origin));if(!q)return 48;
        CjguiOhosEditTicket t;t.key=q->origin->key;t.before=u"x";t.after=u"x1";t.choice=q;
        const auto refused=s.inputTickets.admit(std::move(t));if(!refused || !s.inputTickets.complete(refused->id,false))return 49;
        s.events.push_back({refused,{}});uint64_t picked=0;
        if(testPick(&s,picked)!=1 || picked!=refused->id)return 50;
        if(!testStale(&s,s.events.front()))return 51;
    }
    CjguiOhosEditTickets pool;const CjguiOhosProxyKey key{7,1,3,1,10};
    auto make=[&](std::u16string before,std::u16string after,uint64_t predecessor=0){
        CjguiOhosEditTicket t;t.key=key;t.focusGeneration=2;t.before=before;t.after=after;t.predecessor=predecessor;
        return pool.admit(std::move(t));
    };
    auto a=make(u"x1",u"x12"),b=make(u"x12",u"x123",a->id),c=make(u"x123",u"x1234",b->id);
    if(!a || !b || !c || pool.pendingPredecessor(a->id) || pool.pendingPredecessor(c->id)!=c)return 31;
    auto wrong=key;++wrong.mount;
    if(pool.platformChanged(c->id,wrong,c->after) || pool.platformChanged(c->id,key,u"wrong"))return 32;
    if(!pool.platformChanged(c->id,key,c->after) || pool.takeReady() ||
       pool.platformChanged(c->id,key,c->after) || pool.hasPairedChange(c->id))return 33;
    if(!pool.platformChanged(b->id,key,b->after) || pool.takeReady())return 34;
    if(!pool.platformChanged(a->id,key,a->after) || pool.takeReady()!=a || pool.takeReady()!=b ||
       pool.takeReady()!=c || pool.takeReady() || !pool.hasPairedChange(c->id))return 35;
    if(!pool.complete(a->id,false) || pool.terminalResult(b->id)!=-1 || pool.terminalResult(c->id)!=-1 ||
       pool.complete(c->id,true,7,0,"new fact"))return 36;
    pool.clear(true);a.reset();b.reset();c.reset();
    if(pool.liveCount()!=0)return 37;
    a=make(u"x",u"x1");b=make(u"x1",u"x12",a->id);c=make(u"x12",u"x123",b->id);
    if(!pool.platformChanged(c->id,key,c->after) || !pool.complete(b->id,false) ||
       pool.pendingCount()!=1 || pool.terminalResult(c->id)!=-1 || pool.pendingPredecessor(c->id))return 38;
    if(!pool.platformChanged(a->id,key,a->after) || pool.takeReady()!=a || pool.takeReady())return 39;
    if(!pool.complete(a->id,true,2,0,"accepted") || pool.complete(a->id,false) || pool.terminalResult(a->id)!=1)return 40;
    pool.clear(true);a.reset();b.reset();c.reset();
    std::vector<CjguiOhosEditTickets::Ticket> held;
    for(size_t i=0;i<32;++i){auto t=make(u"a",u"b");if(!t)return 41;held.push_back(t);}
    if(make(u"a",u"b"))return 42;
    pool.clear(true);if(pool.liveCount()!=32 || make(u"a",u"b"))return 43;
    held.clear();if(pool.liveCount()!=0)return 44;
    a=make(std::u16string(524288,u'a'),std::u16string(524288,u'b'));
    if(!a || make(u"a",u"b"))return 45;
    pool.clear(true);a.reset();if(pool.liveCount()!=0)return 46;
    if(make(std::u16string(524289,u'a'),std::u16string(524288,u'b')))return 47;
    std::puts("PASS original ready/FIFO, exact tail, duplicate/key/body rejection, dependent refusal/cancel, immutable acceptance, 32 tickets and 1Mi UTF16");
    return 0;
}
int main(){return inputChain();}
'''



PREFIX_MAIN = r"""
#include "cjgui_ohos_edit_ticket.h"
#include <cstdio>
#include <cstdlib>
using Pool=CjguiOhosEditTickets;using Ticket=Pool::Ticket;
static void check(bool ok,int code){if(!ok){std::fprintf(stderr,"prefix assertion %d\\n",code);std::exit(code);}}
static const CjguiOhosProxyKey key{7,1,3,2,10};
static CjguiOhosEditTicket origin(std::u16string before,std::u16string after,uint64_t pred=0){
 CjguiOhosEditTicket t;t.key=key;t.focusGeneration=2;t.node=107;t.resource=77;t.kind=10;t.field="body";
 t.acceptedBinding=3;t.ownerBinding=11;t.sourceBasis="frozen original source";t.predecessor=pred;
 t.before=before;t.after=after;t.start=t.end=before.size();t.afterStart=t.start;t.afterEnd=after.size();
 t.inserted=after.substr(std::min<size_t>(t.afterStart,after.size()));return t;
}
static CjguiOhosPlatformChangeEvidence evidence(Ticket t){
 CjguiOhosPlatformChangeEvidence e;e.key=t->key;e.focus=t->focusGeneration;e.anchor=t->id;e.observation=27;
 e.before=t->before;e.after=t->after;e.start=t->start;e.end=t->end;e.afterStart=t->afterStart;e.afterEnd=t->afterEnd;
 e.previewOffset=e.oldPreviewOffset=-1;return e;
}
int main(){
 auto allow=[](const Ticket&){return true;};
 {
  Pool p;auto a=p.admit(origin(u"x1",u"x12"));auto b=p.admit(origin(u"x12",u"x123",a->id));
  auto tail=p.admit(origin(u"x123",u"x1234",b->id));const auto e=evidence(b);
  check(!p.takeReady(),60);auto r=p.platformChangedPrefix(e,allow);
  check(r.boundary==b->id && r.covered==2 && r.newlyReady==2,61);
  uint64_t anchor=0,obs=0;check(p.platformPrefixProof(a->id,anchor,obs)&&anchor==b->id&&obs==27,62);
  check(p.takeReady()==a&&p.takeReady()==b&&!p.takeReady()&&p.pendingPredecessor(tail->id)==tail,63);
  check(!p.platformChangedPrefix(e,allow).boundary&&!p.takeReady(),64);
  check(p.complete(a->id,true,8,0,"owner8")&&p.complete(b->id,true,9,0,"owner9"),65);
  check(!p.complete(a->id,false)&&p.terminalResult(a->id)==1,66);
  p.clear(true);check(!p.platformPrefixProof(a->id,anchor,obs),67);
  a.reset();b.reset();tail.reset();check(p.liveCount()==0,68);
 }
 for(int mode=0;mode<23;++mode){
  Pool p;auto at=origin(u"x1",u"x12");
  if(mode==12)at.start=1; // Original splice is not the admitted postimage.
  if(mode==20){at.before={0xd800};at.after={0xd800,u'2'};at.start=at.end=at.afterStart=1;at.afterEnd=2;at.inserted=u"2";}
  auto a=p.admit(std::move(at));auto bt=origin(a->after,a->after+u"3",a->id);
  if(mode==9)bt.predecessor=0;
  if(mode==10)bt.predecessor=999;
  if(mode==11)bt.before=u"different";
  if(mode==13)++bt.node;
  if(mode==14)++bt.resource;
  if(mode==15)++bt.kind;
  if(mode==16)++bt.acceptedBinding;
  if(mode==17)++bt.ownerBinding;
  if(mode==18)bt.field="different-field";
  if(mode==19)bt.sourceBasis="different-selection-source";
  if(mode==21)bt.sourceLeaf=std::make_shared<const CjguiOhosInputSourceLeaf>();
  auto b=p.admit(std::move(bt));auto e=evidence(b);
  if(mode==0)++e.key.mount;
  if(mode==1)++e.focus;
  if(mode==2)e.before=u"wrong";
  if(mode==3)e.after=u"wrong";
  if(mode==4)++e.start;
  if(mode==5)++e.afterEnd;
  if(mode==6)e.oldPreview=u"composing";
  if(mode==7)e.previewOffset=-2;
  if(mode==8)e.observation=0;
  unsigned checked=0;
  auto permission=[&](const Ticket&t){++checked;return mode!=22 || t->id!=a->id;};
  check(!p.platformChangedPrefix(e,permission).boundary,70+mode);
  check(!p.takeReady(),100+mode);uint64_t anchor=0,obs=0;check(!p.platformPrefixProof(a->id,anchor,obs),130+mode);
 }
 {
  Pool p;auto a=p.admit(origin(u"x",u"x1"));auto b=p.admit(origin(u"x1",u"x12",a->id));auto c=p.admit(origin(u"x12",u"x123",b->id));
  check(p.platformChanged(a->id,key,a->after)&&p.takeReady()==a&&p.complete(a->id,true,7,0,"accepted"),160);
  check(p.platformChangedPrefix(evidence(c),allow).boundary==c->id&&p.takeReady()==b&&p.takeReady()==c,161);
 }
 {
  Pool p;auto a=p.admit(origin(u"x1",u"x12"));auto bt=origin(u"x12",u"x1",a->id);bt.start=bt.afterStart=2;bt.end=3;bt.afterEnd=2;bt.inserted=u"";
  auto b=p.admit(std::move(bt));auto c=p.admit(origin(u"x1",u"x12",b->id));
  check(!p.platformChangedPrefix(evidence(c),allow).boundary&&!p.takeReady(),162);
  check(p.complete(a->id,false)&&p.terminalResult(c->id)==-1&&!p.platformChangedPrefix(evidence(c),allow).boundary,163);
 }
 {
  Pool p;auto a=p.admit(origin(u"x1",u"x12"));auto b=p.admit(origin(u"x12",u"x123",a->id));auto c=p.admit(origin(u"x123",u"x1234",b->id));
  check(p.platformChangedPrefix(evidence(c),allow).covered==3&&p.takeReady()==a,164);
  check(p.complete(a->id,true,8,0,"owner8")&&p.takeReady()==b&&p.complete(b->id,false),165);
  check(p.terminalResult(a->id)==1&&!p.complete(a->id,false)&&p.terminalResult(c->id)==-1&&!p.takeReady(),166);
 }
 {
  Pool p;auto a=p.admit(origin(u"x1",u"x12"));auto semantic=p.admit(origin(u"x12",u"x12",a->id));auto c=p.admit(origin(u"x12",u"x123",semantic->id));
  check(p.platformChanged(semantic->id,key,semantic->after),167);
  const auto r=p.platformChangedPrefix(evidence(c),allow);
  check(r.covered==3&&r.newlyReady==2&&p.takeReady()==a&&p.takeReady()==semantic&&p.takeReady()==c,168);
 }
 {
  Pool p;auto a=p.admit(origin(u"x1",u"x12"));auto b=p.admit(origin(u"x12",u"x123",a->id));
  CjguiOhosFocusAuthority authority;
  check(authority.issue(107,77,10,3,"body")==1&&authority.issue(107,77,10,3,"body")==2&&authority.bind(key),169);
  check(authority.issue(107,77,10,3,"body")==3&&authority.retainAdmittedInput(key,2,{a->id,b->id},11,500),170);
  check(!authority.permits(key,2),171);
  auto permitted=[&](const Ticket&t){return authority.permitsTransferredInput(t->key,t->focusGeneration,t->id,t->ownerBinding,499);};
  check(p.platformChangedPrefix(evidence(b),permitted).boundary==b->id&&p.takeReady()==a&&p.takeReady()==b,172);
  check(a->focusGeneration==2&&b->focusGeneration==2&&authority.generation==3,173);
 }
 std::puts("PASS actual prefix: exact anchor, original FIFO spans, unseen tail, per-ticket permission, scalar/source/ABA guards, semantic position, partial owner refusal, real transferred authority and bounded retirement");
}
"""

def platform_prefix(variant="actual"):
    header=(PLATFORM/'host/cjgui_ohos_edit_ticket.h').read_text()
    if variant=="proof":
        needle='PlatformPrefix platformChangedPrefix(const CjguiOhosPlatformChangeEvidence &e, Permit permit) {'
        assert needle in header;header=header.replace(needle,needle+' return {};',1)
    if variant=="source":
        needle='return a.key==b.key && a.focusGeneration==b.focusGeneration'
        assert needle in header;header=header.replace(needle,'return true || a.key==b.key && a.focusGeneration==b.focusGeneration',1)
    if variant=="chain":
        needle='t->predecessor!=previous->id';assert needle in header;header=header.replace(needle,'false',1)
    with tempfile.TemporaryDirectory(prefix='cjgui-platform-prefix-') as tmp:
        root=Path(tmp);(root/'cjgui_ohos_edit_ticket.h').write_text(header)
        (root/'actual.cpp').write_text(PREFIX_MAIN)
        subprocess.run(['clang++','-std=c++17','-I'+str(root),'-I'+str(PLATFORM/'host'),str(root/'actual.cpp'),'-o',str(root/'actual')],check=True)
        result=subprocess.run([str(root/'actual')]);print('platform-prefix',variant,'exit',result.returncode,flush=True)
        return result.returncode


def prefix_bridge():
    header=next((p for p in [Path('/opt/homebrew/include/node'),Path('/usr/local/include/node')] if (p/'node_api.h').is_file()),None)
    assert header is not None, 'Node NAPI headers unavailable; bridge execution not verified'
    source=(PLATFORM/'host/cjgui_host_bridge.cpp').read_text()
    alias=re.search(r'using InputChangePrefixFn =[\s\S]*?;',source).group()
    declaration=SOURCE.read_text();start=declaration.index('extern "C" int64_t ohos_renderer_input_change_prefix(')
    declaration=declaration[start:declaration.index('{',start)].strip()
    witness=declaration.replace('extern "C" int64_t ohos_renderer_input_change_prefix','static int64_t witness')
    witness+='''{++calls;facts=std::string(before,beforeBytes)+"|"+std::string(after,afterBytes)+"|"+std::to_string(anchor)+","+std::to_string(app)+","+std::to_string(session)+","+std::to_string(context)+","+std::to_string(edit)+","+std::to_string(mount)+","+std::to_string(focus)+","+std::to_string(observation)+","+std::to_string(start)+","+std::to_string(end)+","+std::to_string(afterStart)+","+std::to_string(afterEnd)+","+std::to_string(previewOffset)+","+std::to_string(oldPreviewOffset)+"|"+std::string(preview,previewBytes)+"|"+std::string(oldPreview,oldPreviewBytes);return anchor;}'''
    cpp='''#include <node_api.h>
#include <cmath>
#include <cstdint>
#include <string>
#include <vector>
#include <type_traits>
static unsigned calls=0;static std::string facts;
'''+declaration+';\n'+alias+'\nstatic_assert(std::is_same_v<InputChangePrefixFn,decltype(&ohos_renderer_input_change_prefix)>);\n'+witness+'''
static InputChangePrefixFn inputChangePrefixFn=witness;
static void resolveImeEntryPoints(){}
'''+function(source,'static bool readPlatformEvidenceText(')+'\n'+function(source,'static napi_value ImeInputChangePrefix(')+'''
static napi_value Calls(napi_env env,napi_callback_info){napi_value v;napi_create_uint32(env,calls,&v);return v;}
static napi_value Facts(napi_env env,napi_callback_info){napi_value v;napi_create_string_utf8(env,facts.data(),facts.size(),&v);return v;}
static napi_value Init(napi_env env,napi_value exports){
 napi_property_descriptor properties[]={
 {"prefix",nullptr,ImeInputChangePrefix,nullptr,nullptr,nullptr,napi_default,nullptr},
 {"calls",nullptr,Calls,nullptr,nullptr,nullptr,napi_default,nullptr},
 {"facts",nullptr,Facts,nullptr,nullptr,nullptr,napi_default,nullptr}};
 napi_define_properties(env,exports,3,properties);return exports;
}
NAPI_MODULE(h_prefix_test,Init)
'''
    js=r'''
const assert=require('node:assert/strict'),x=require(process.argv[1]);
const original=['x12','x123',8,7,1,10,3,2,2,27,3,3,3,4,-1,'',-1,''];
assert.equal(x.prefix(...original),'8');assert.equal(x.calls(),1);
assert.equal(x.facts(),'x12|x123|8,7,1,10,3,2,2,27,3,3,3,4,-1,-1||');
let cases=0;
for(const [i,value]of [[2,0],[2,NaN],[2,Infinity],[2,1.5],[3,true],[4,9007199254740992],[5,-1],[7,null],[10,-1],[11,3.5],[12,4294967296],[14,undefined],[16,0],[0,'\ud800'],[1,'\udfff'],[0,'中'.repeat(100000)],[15,{}],[17,null]]){
 const a=original.slice();a[i]=value;assert.equal(x.prefix(...a),'0',String(i));assert.equal(x.calls(),1);++cases;
}
assert.equal(x.prefix(...original.slice(0,17)),'0');assert.equal(x.prefix(...original,'extra'),'0');assert.equal(x.calls(),1);
const composition=original.slice();composition[15]='marked';assert.equal(x.prefix(...composition),'8');
assert(x.facts().endsWith('|marked|'),'transport real preview unchanged; actual native prefix checker rejects it');
console.log(JSON.stringify({passed:true,strictNegativeCases:cases+2,actualNapiExecuted:true,privateAbiSignatureEqual:true,previewTransportedUnchanged:true,SDKRuntimeClaimed:false}));
'''
    with tempfile.TemporaryDirectory(prefix='cjgui-prefix-napi-') as tmp:
        root=Path(tmp);(root/'actual.cpp').write_text(cpp)
        subprocess.run(['clang++','-std=c++17','-bundle','-undefined','dynamic_lookup','-I'+str(header),str(root/'actual.cpp'),'-o',str(root/'actual.node')],check=True)
        subprocess.run(['node','-e',js,str(root/'actual.node')],check=True)
    return 0


def run(withdraw=False, chain=False):
    production = function(SOURCE.read_text(), "CjguiInternalRendererStatus cjgui_internal_renderer_destroy(uint64_t session)")
    if withdraw:
        begin = "    // Input origins and choice receipts also belong to the retired fixed slot."
        end = "    s->gesture = Session::TouchGesture{};"
        assert production.count(begin) == production.count(end) == 1
        a = production.index(begin)
        b = production.index(end, a)
        production = production[:a] + production[b:]
    with tempfile.TemporaryDirectory(prefix="cjgui-input-destroy-") as tmp:
        cpp = Path(tmp) / "actual.cpp"
        binary = Path(tmp) / "actual"
        if chain and withdraw:
            header=(PLATFORM/'host/cjgui_ohos_edit_ticket.h').read_text()
            begin=header.index('        if(!accepted) {')
            end=header.index('        // Compact terminals',begin)
            (Path(tmp)/'cjgui_ohos_edit_ticket.h').write_text(header[:begin]+header[end:])
        clear=function(SOURCE.read_text(),"static void cjguiOhosClearSelectionCaptureLocked(Session &s)")
        pick=''
        if chain:
            source=SOURCE.read_text()
            begin=source.index('    // Owner execution and actual command installation are independent facts.')
            end=source.index('    QueuedEvent ev = *selected;',begin)
            stale_begin=source.index('        if (ev.inputTicket && (s->inputTickets.terminalResult(')
            stale_end=source.index(' ev.recordIndex = 1u;',stale_begin)+len(' ev.recordIndex = 1u;')
            # Actual production waiting/selection seam. Only the SDK/source
            # readiness is controlled; the test never substitutes its decision.
            pick='''
static constexpr uint32_t kEvSelectionChanged=33;
static bool cjguiOhosCompletedCommandInputSourceLocked(const Session&,const CjguiOhosEditTickets::Ticket&){return false;}
static int cjguiOhosChoiceReadyLocked(const Session&,const CjguiOhosChoiceSources::Receipt&){return 0;}
static int testPick(Session*s,uint64_t&picked){
 struct {uint32_t kind=0;} result;auto*outEvent=&result;
'''+source[begin:end]+'''picked=selected->inputTicket?selected->inputTicket->id:0;return 1;}
static int64_t proxyRestoreNowMs(){return 0;}
static bool testStale(Session*s,QueuedEvent&ev){
'''+source[stale_begin:stale_end]+'''return ev.recordIndex==1;}
'''
        prefix=PREFIX.replace('// @LINEFACT',function(SOURCE.read_text(),'struct AcceptedTextLineBands {')+';')
        cpp.write_text(prefix + (pick+CHAIN_MAIN if chain else clear + production + MAIN))
        subprocess.run(["clang++", "-std=c++17", "-I" + str(PLATFORM / "snapshot"),
                        "-I" + str(PLATFORM / "host"), str(cpp), "-o", str(binary)], check=True)
        result = subprocess.run([str(binary)])
        print("withdrawal" if withdraw else "actual", "exit", result.returncode, flush=True)
        return result.returncode


if __name__ == "__main__":
    if "--prefix-bridge" in sys.argv:
        sys.exit(prefix_bridge())
    if "--platform-prefix" in sys.argv:
        variant=next((x.split("=",1)[1]for x in sys.argv if x.startswith("--withdraw-prefix=")),"actual")
        sys.exit(platform_prefix(variant))
    chain="--input-chain" in sys.argv
    result = run(chain=chain)
    if result:
        sys.exit(result)
    if "--selftest" in sys.argv:
        negative = run(withdraw=True,chain=chain)
        if negative != (36 if chain else 21):
            raise SystemExit("withdrawal failed to discriminate retained receipts")

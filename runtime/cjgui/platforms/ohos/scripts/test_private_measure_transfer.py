#!/usr/bin/env python3
"""Actual measure/acquisition/admission/publication seams with counted SDK objects.

The cache, key and peak policies come verbatim from production. Drawing and the
unused selection/caret boundary are controlled substitutes, not device evidence.
"""
from pathlib import Path
import hashlib
import json
import os
import subprocess
import sys
import tempfile
from test_presentation_typography_reuse import block

SOURCE = Path(__file__).resolve().parents[1] / 'host/ohos_renderer.cpp'


def run(mutation=None, code_transform=None):
    source = SOURCE.read_text()
    draw = block(source, '    void drawNodeText(')
    admission = draw[draw.index('        const bool leaseEligible'):draw.index('        const PaintedTextLayout *reusedLayout')]
    acquire = draw[draw.index('        const PaintedTextLayout *reusedLayout'):draw.index('        if (!m.typography)')]
    publish = block(source, '    void publishPaintedLayout(TextPaintFrame &frame)')
    publish = publish[publish.index('{') + 1:publish.index('        paintedLayoutUsable = true;')]
    editing = draw[draw.index('        if (isEditingNode) {\n            auto painted'):draw.index('            {\n                double sx =')]
    editing += '            frame.candidate = std::move(painted);\n        }\n'
    retention = block(draw, '        if (!isEditingNode) {\n            // A2：pointerInteractive')
    methods = []
    for marker in ('    bool canKeepPreparedMeasurement(', '    bool preparedMeasurementMatches(',
                   '    void retireInvalidPreparedMeasurement(', '    void stagePreparedMeasurement(',
                   '    Measured takePreparedMeasurement('):
        if marker in source:
            methods.append(block(source, marker))
    prepared = (block(source, 'struct PreparedTextMeasurement {') + ';'
                if 'struct PreparedTextMeasurement {' in source else 'struct PreparedTextMeasurement {};')
    finish = block(source, '    void executeMeasure(MeasureJob *job)')
    teardown = block(source, '    void teardownSurface(')
    teardown = teardown[teardown.index('        invalidatePaintedLayout'):teardown.index('        RLOGI("font generations teardown')]
    dispatch = block(source, '    void execute(WaitableJob *job)')
    snippets = {'ADMISSION': admission, 'ACQUIRE': acquire, 'PUBLISH': publish,
                'EDITING': editing, 'RETENTION': retention, 'METHODS': '\n'.join(methods),
                'MEASURE': finish, 'TEARDOWN': teardown, 'DISPATCH': dispatch}
    mutations = {
        'disable-transfer': ('ACQUIRE', 'else if (usePreparedMeasurement)', 'else if (false)'),
        'omit-private-peak': ('ADMISSION', 'frame.leaseTransientUnits + frame.preparedMeasureUnits;', 'frame.leaseTransientUnits;'),
        'omit-full-text': ('METHODS', 'p.text == text &&', 'true &&'),
        'keep-cancelled': ('MEASURE', 'if (keepPrivate && job->phaseSnapshot() != JobPhase::Done && preparedMeasurement &&\n            preparedMeasurement->measureJobId == job->observationId) preparedMeasurement.reset();', ''),
        'retire-on-unrelated': ('MEASURE', 'if (canKeepPreparedMeasurement(job, measuredUnits)) preparedMeasurement.reset();', 'preparedMeasurement.reset();'),
        'omit-unrelated-peak': ('MEASURE', 'if (preparedMeasurement) {', 'if (false && preparedMeasurement) {'),
        'omit-teardown': ('TEARDOWN', 'preparedMeasurement.reset();', ''),
        'omit-font-clear': ('TEARDOWN', 'fontPool.clear();', ''),
        'destroy-transferred': ('METHODS', 'p.typography.release()', 'p.typography.get()'),
    }
    if mutation:
        key, old, new = mutations[mutation]
        assert old in snippets[key], mutation
        snippets[key] = snippets[key].replace(old, new, 1)
    declarations = '\n'.join(block(source, marker) + ';' for marker in (
        'enum class JobKind', 'enum class JobPhase', 'struct WaitableJob {',
        'struct MeasureJob : WaitableJob {'))
    helper = block(source, 'static bool cjguiOhosCanReuseEditingTypography(')
    width = block(source, 'static double cjguiOhosTextLayoutWidth(')
    utf16 = block(source, 'std::u16string utf8ToUtf16(const std::string &utf8)')
    measured = block(source, '    struct Measured {') + ';'
    lease_units = '\n'.join(block(source, marker) for marker in (
        '    static size_t leaseTableUnits(', '    static size_t ownedLeaseTableUnits(',
        '    static size_t ownedLeaseTableSlots(', '    void pruneRenderOnlyLayouts('))
    entry = block(source, 'CjguiInternalRendererStatus cjgui_internal_renderer_measure_composable_multiline_natural_height(')
    constants = '\n'.join(line for line in source.splitlines() if line.startswith('constexpr size_t kPresentationLease'))
    wire = '''j.keepPrivateLayout=true; j.preparedNode=107; j.preparedResource=77;
              j.preparedKind=10; j.preparedBinding=1;''' if 'bool keepPrivateLayout' in source else ''
    fallback = '' if methods else '''
    bool canKeepPreparedMeasurement(MeasureJob*,size_t){return false;}
    void stagePreparedMeasurement(const std::vector<Node>&,TextPaintFrame&){}
    '''
    pre_admission = '' if 'const bool usePreparedMeasurement' in admission else 'const bool usePreparedMeasurement=false;'
    code = r'''
#include "cjgui_ohos_font_lease.h"
#include "cjgui_ohos_text_work_trace.h"
#include <algorithm>
#include <atomic>
#include <chrono>
#include <cassert>
#include <condition_variable>
#include <cstdio>
#include <cstdlib>
#include <functional>
#include <map>
#include <mutex>
#include <set>
#include <string>
#include <vector>
#define RLOGI(...) ((void)0)
#define RLOGW(...) ((void)0)
#define RLOGD(...) ((void)0)
template<class...A>void cjguiOhosObserveTextWork(A&&...){}
#define CHECK(x,why) do{if(!(x)){puts("FAIL " why);std::exit(1);}}while(0)
enum CjguiInternalRendererStatus { CJGUI_INTERNAL_RENDERER_OK=0,
 CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR=2,CJGUI_INTERNAL_RENDERER_INVALID_SESSION=11,CJGUI_INTERNAL_RENDERER_METAL_DRAWABLE_UNAVAILABLE=15,
 CJGUI_INTERNAL_RENDERER_PENDING=20 };
constexpr auto kRenderWaitTimeout=std::chrono::milliseconds(200);
constexpr uint32_t kKindText=3,kKindButton=4,kKindMultiline=10;
@@CONSTANTS@@
static std::atomic<uint64_t> g_observedRenderJobSequence{0};
@@DECLARATIONS@@
using JobRef=std::shared_ptr<WaitableJob>;
struct Session {
 int64_t editingContextId=7,editingContextBaseVersion=1,editingResourceId=77;
 uint64_t editingProjectionVersion=1,editingNodeId=107,editingAcceptedBindingEpoch=1;
 uint32_t editingNodeKind=10;bool editingContextLive=true,editorRetired=false;
 CjguiOhosTextWorkTraceRef textWorkTrace;
};
struct { std::mutex lock;Session session; } g_sessions;
Session*lookupSessionLocked(uint64_t id){return id==42?&g_sessions.session:nullptr;}
struct OH_Drawing_Typography { int id; double width; uint32_t color; };
int layouts=0,destroyed=0,colorUpdates=0;bool failLayout=false;OH_Drawing_Typography *lastCreated=nullptr;
std::set<void*> dead; std::function<void()> duringLayout;
void cjguiOhosDestroyObservedTypography(OH_Drawing_Typography *p) {
 if(p){CHECK(!dead.count(p),"double Typography destruction");dead.insert(p);++destroyed;delete p;}
}
void OH_Drawing_TypographyUpdateFontColor(OH_Drawing_Typography *p,uint32_t c){
 CHECK(!dead.count(p),"color update on retired private object");p->color=c;++colorUpdates;
}
double OH_Drawing_TypographyGetHeight(OH_Drawing_Typography*){return 20;}
double OH_Drawing_TypographyGetLongestLine(OH_Drawing_Typography*){return 10;}
double OH_Drawing_TypographyGetMaxWidth(OH_Drawing_Typography*p){return p->width;}
size_t OH_Drawing_TypographyGetLineCount(OH_Drawing_Typography*){return 1;}
double OH_Drawing_TypographyGetAlphabeticBaseline(OH_Drawing_Typography*){return 16;}
struct FontCollection{};using OhosFontPool=CjguiOhosFontPool<FontCollection>;
struct Pod{uint64_t nodeId=107,acceptedBindingEpoch=1,projectionVersion=1;int64_t resourceId=77;
 uint32_t nodeKind=10,fontWeight=0;double fontSize=16,textRed=0,textGreen=0,textBlue=0,textAlpha=1;
 int64_t x=0,y=0,width=333,height=200;int isInteractive=1,isReadOnly=0;};
using CjguiInternalRendererComposableNode=Pod;
struct OhosTextStyleRun{bool selectionBackgroundOnly=false;};
struct Node{Pod pod;std::string value="ABC";std::vector<OhosTextStyleRun> textStyleRuns;};
using SceneNode=Node;
struct PaintedTextLayout{
 OhosFontPool::Lease fontLease;
 std::unique_ptr<OH_Drawing_Typography,decltype(&cjguiOhosDestroyObservedTypography)> typography{nullptr,&cjguiOhosDestroyObservedTypography};
 Pod node;std::u16string text;CjguiOhosCoverage coverage;
 uint64_t session=0,renderEpoch=0,basePresentTicket=0,projectionVersion=0,serial=0,generation=0,geometryRevision=0;
 int64_t paintContext=0,layoutSourceContext=0;uint64_t layoutOwnedBinding=0,layoutOwnedDeclaredBinding=0;
 void*window=nullptr;int32_t width=0,height=0;double density=1,relativeOriginX=0,relativeOriginY=0;
 bool plainTextLayout=false,borrowsEditingTypography=false,borrowsPresentationTypography=false;
 std::string renderTextBytes;bool borrowsRenderOnlyTypography=false;
};
@@PREPARED@@
struct TextPaintFrame{
 uint64_t session=42,ticket=1,projectionVersion=1,ownedMirrorBindingEpoch=1,ownedMirrorDeclaredBindingEpoch=1;
 uint64_t leaseRequiredNodeId=107,leaseEditingNodeId=107,ownedNodeId=107;
 int64_t ownedMirrorOwnerVersion=1;CjguiOhosCoverage ownedCoverage;CjguiOhosTextWorkTraceRef textWorkTrace;
 std::unique_ptr<PaintedTextLayout>candidate;std::map<uint64_t,std::unique_ptr<PaintedTextLayout>> presentationLease;
 std::map<uint64_t,std::unique_ptr<PaintedTextLayout>>renderOnlyLease;
 size_t renderOnlyHits=0,renderOnlyMisses=0,renderOnlyEvicted=0;
 bool leasePeakCharged=false,presentationLeaseOverflow=false;
 size_t leaseTransientUnits=0,leaseReplacedSlots=0,leaseReplacedUnits=0,leaseReservedSlotsLeft=0,leaseReservedUnitsLeft=0;
 size_t preparedMeasureUnits=0;std::vector<uint64_t>leaseSkippedNodeIds;
 std::map<uint64_t,std::pair<size_t,size_t>>leaseReservations;
};
@@UTF16@@
std::string displayTextForNode(const Node&n){return n.value;}
@@HELPER@@
@@WIDTH@@
struct CaretHitTestJob:WaitableJob{CaretHitTestJob():WaitableJob(JobKind::CaretHitTest){}};
struct PresentJob:WaitableJob{PresentJob():WaitableJob(JobKind::Present){}};
struct RedrawJob:WaitableJob{RedrawJob():WaitableJob(JobKind::Redraw){}};
struct ImageRealizeJob:WaitableJob{ImageRealizeJob():WaitableJob(JobKind::ImageRealize){}};
struct TeardownJob:WaitableJob{TeardownJob():WaitableJob(JobKind::Teardown){}};
struct Renderer{
 OhosFontPool fontPool{[]{return new FontCollection;},[](FontCollection*p){delete p;}};
 uint64_t fontConfigurationGeneration=1,renderEpoch=1,boundGeneration=1,permitGeometryRevision=1,textPaintSerial=0;
 uint64_t lastFrameSession=42;void*boundWindow=(void*)1;int surfaceW=377,surfaceH=800;double surfaceDensity=3.5;
 bool paintedLayoutUsable=false;std::unique_ptr<PaintedTextLayout>lastPaintLayout;
 std::map<uint64_t,std::unique_ptr<PaintedTextLayout>>publishedPresentationLease;
 std::map<uint64_t,std::unique_ptr<PaintedTextLayout>>publishedRenderOnlyLease;
 std::unique_ptr<PreparedTextMeasurement>preparedMeasurement;
 @@MEASURED@@
 @@LEASE_UNITS@@
 template<class...A>void observeResources(A&&...){}
 uint64_t textWorkFingerprint(const std::string&){return 1;}
 static uint64_t observedCoverageInput(const CjguiOhosCoverage&){return 0;}
 bool leaseValid(uint64_t g){return g==boundGeneration;}
 bool geometryMatches(void*w,uint64_t g,int a,int b,uint64_t rev){return w==boundWindow&&g==boundGeneration&&a==surfaceW&&b==surfaceH&&rev==permitGeometryRevision;}
 void invalidatePaintedLayout(uint64_t){paintedLayoutUsable=false;}
 Measured layoutText(const std::string&t,double,uint32_t,double width,bool,uint32_t color){
  ++layouts;if(failLayout)return {};auto*p=new OH_Drawing_Typography{layouts,width,color};dead.erase(p);lastCreated=p;
  Measured m; m.fontLease=fontPool.acquire(utf8ToUtf16(t).size(),fontConfigurationGeneration);
  m.typography=p;m.height=20;m.longestLine=10;m.maxWidth=width;m.lineCount=1;m.alphabeticBaseline=16;
  if(duringLayout){auto hook=std::move(duringLayout);duringLayout={};hook();}return m;
 }
 Measured layoutTextStyled(const std::string&t,double size,uint32_t weight,double w,bool u,uint32_t c,const OhosTextStyleRun*,size_t,uint64_t,TextPaintFrame*){return layoutText(t,size,weight,w,u,c);}
 @@FALLBACK@@
 @@METHODS@@
 @@MEASURE@@
 void post(const JobRef&j){executeMeasure(static_cast<MeasureJob*>(j.get()));}
 void publish(TextPaintFrame&frame){@@PUBLISH@@}
 void teardown(){@@TEARDOWN@@}
 void executeCaretHitTest(CaretHitTestJob*){}
 void executePresent(PresentJob*){}
 void executeRedraw(RedrawJob*){}
 void executeImageRealize(ImageRealizeJob*){}
 void executeTeardown(TeardownJob*){teardown();}
 @@DISPATCH@@
 void paint(TextPaintFrame&frame,Node node,std::string text="ABC",bool editing=true,int64_t context=7){
  const bool isEditingNode=editing,presentFeedback=false;uint32_t kind=node.pod.nodeKind;
  int64_t layoutSourceContext=context,caretContext=context;uint32_t textColor=0xff262626;
  auto editComposed=utf8ToUtf16(text);node.value=text;
  @@PRE_ADMISSION@@
  @@ADMISSION@@
  @@ACQUIRE@@
  if(!m.typography)return;
  struct{double originX=6,originY=6;}geom;
  @@EDITING@@
  @@RETENTION@@
 }
};
static Renderer g_render;
@@PUBLIC_ENTRY@@
void configure(MeasureJob&j,const std::string&t="ABC"){
 j.text=t;j.fontSize=16;j.fontWeight=0;j.constraintWidth=319;j.unlimitedWidth=false;
 j.traceSession=42;j.traceContext=7;@@WIRE@@
}
int main(){
 {uint32_t height=0;int c=layouts;
  auto status=cjgui_internal_renderer_measure_composable_multiline_natural_height(42,"ABC",16,0,0,319,&height);
  CHECK(status==CJGUI_INTERNAL_RENDERER_OK&&height==20&&layouts==c+1&&g_render.preparedMeasurement,
        "public measurer did not wire the private identity");
  g_render.teardown();}
 Renderer r;Node n;
 {TextPaintFrame old;r.paint(old,n,"OLD");r.publish(old);}
 auto*old=r.lastPaintLayout->typography.get();int start=layouts;
 MeasureJob j;configure(j);r.executeMeasure(&j);auto*measured=lastCreated;
 CHECK(j.phaseSnapshot()==JobPhase::Done,"measure completion");
 CHECK(r.preparedMeasurement&&!dead.count(measured),"measurement was retired before its normal consumer");
 CHECK(layouts==start+1,"measure did not prepare exactly once");
 {MeasureJob footer;configure(footer);footer.keepPrivateLayout=false;
  footer.cancelBeforeCommit();int c=layouts;r.execute(&footer);
  CHECK(layouts==c&&r.preparedMeasurement&&r.preparedMeasurement->typography.get()==measured,
        "unrelated queued cancellation retired the pending body layout");}
 {MeasureJob footer;configure(footer,"cancelled footer");footer.keepPrivateLayout=false;
  duringLayout=[&]{footer.cancelBeforeCommit();};r.execute(&footer);
  CHECK(footer.phaseSnapshot()==JobPhase::Cancelled&&r.preparedMeasurement&&
        r.preparedMeasurement->typography.get()==measured,
        "unrelated running cancellation retired the pending body layout");}
 {MeasureJob footer;configure(footer);footer.keepPrivateLayout=false;
  failLayout=true;r.execute(&footer);failLayout=false;
  CHECK(footer.statusSnapshot()==CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR&&r.preparedMeasurement&&
        r.preparedMeasurement->typography.get()==measured,
        "unrelated failed measurement retired the pending body layout");}
 // Normal Pharos measures its unrelated status text after the body and before
 // Present. Exercise the real dispatcher, not just adjacent body->paint calls.
 {MeasureJob footer;configure(footer,"status footer");footer.keepPrivateLayout=false;
  footer.unlimitedWidth=true;footer.constraintWidth=0;
  int c=layouts;r.execute(&footer);
  CHECK(layouts==c+1&&r.preparedMeasurement&&
        r.preparedMeasurement->typography.get()==measured&&!dead.count(measured),
        "unrelated normal measurement retired the pending body layout");}
 TextPaintFrame frame;frame.ticket=2;r.stagePreparedMeasurement({n},frame);
 Node header;header.pod.nodeId=500;header.pod.nodeKind=3;
 r.paint(frame,header,"H",false);
 CHECK(frame.leaseTransientUnits==3 && frame.preparedMeasureUnits==3,"private plus old editing peak omitted before body");
 int before=layouts;r.paint(frame,n);
 CHECK(layouts==before&&!r.preparedMeasurement,"body was prepared twice");
 CHECK(frame.leaseTransientUnits==6,"private handoff charged two names for same object");
 CHECK(frame.candidate->typography.get()==measured&&!dead.count(measured),"private unique object lost");
 CHECK(measured->width==319&&measured->color==0xff262626&&colorUpdates==1,"private color/width transport");
 CHECK(r.lastPaintLayout->typography.get()==old&&!dead.count(old),"accepted object changed before Flush");
 r.publish(frame);CHECK(r.lastPaintLayout->typography.get()==measured&&dead.count(old),"success transfer");
 {MeasureJob failed;configure(failed,"NEW");r.executeMeasure(&failed);TextPaintFrame f;r.stagePreparedMeasurement({n},f);r.paint(f,n,"NEW");}
 CHECK(r.lastPaintLayout->typography.get()==measured&&!dead.count(measured),"failed frame stole old query resource");
 {MeasureJob cancelled;configure(cancelled);duringLayout=[&]{cancelled.cancelBeforeCommit();};r.executeMeasure(&cancelled);
  CHECK(cancelled.phaseSnapshot()==JobPhase::Cancelled&&!r.preparedMeasurement,"cancelled measurement retained");}
 {MeasureJob pre;configure(pre);pre.cancelBeforeCommit();int c=layouts;r.executeMeasure(&pre);CHECK(layouts==c&&!r.preparedMeasurement,"cancelled queued measure did work");}
 {MeasureJob failed;configure(failed);failLayout=true;r.executeMeasure(&failed);failLayout=false;
  CHECK(failed.statusSnapshot()==CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR&&!r.preparedMeasurement&&
        r.lastPaintLayout->typography.get()==measured&&!dead.count(measured),"SDK failure altered accepted resource");}
 {MeasureJob a,b;configure(a);configure(b,"ABD");r.executeMeasure(&a);int d=destroyed;r.executeMeasure(&b);CHECK(destroyed==d+1,"superseded measure retained");}
 {MeasureJob footer;configure(footer,std::string(kPresentationLeaseTotalUnitsMax-3,'x'));
  footer.keepPrivateLayout=false;footer.unlimitedWidth=true;footer.constraintWidth=0;
  duringLayout=[&]{CHECK(!r.preparedMeasurement,
      "old/private/unrelated measurement peak exceeded the unchanged total");};
  r.execute(&footer);CHECK(!r.preparedMeasurement,"unrelated over-budget work retained optional cache");}
 {MeasureJob fresh;configure(fresh);r.executeMeasure(&fresh);
  CHECK(r.preparedMeasurement,"early Present retirement fixture missing private object");
  PresentJob rejected;r.execute(&rejected);CHECK(r.preparedMeasurement,"unrelated early Present exit retired private object");}
 for(int which=0;which<17;++which){
  MeasureJob m;configure(m);r.executeMeasure(&m);TextPaintFrame f;Node changed=n;std::string text="ABC";
  auto oldEpoch=r.renderEpoch;auto oldGen=r.boundGeneration;auto oldGeom=r.permitGeometryRevision;auto oldDensity=r.surfaceDensity;auto oldWindow=r.boundWindow;
  if(which==0)text="ABD";if(which==1)changed.pod.width++;if(which==2)changed.pod.fontSize++;
  if(which==3)changed.pod.fontWeight++;if(which==4)changed.pod.nodeId++;if(which==5)changed.pod.resourceId++;
  if(which==6)changed.pod.acceptedBindingEpoch++;if(which==7)f.session++;if(which==8)r.renderEpoch++;
  if(which==9)r.boundGeneration++;if(which==10)r.permitGeometryRevision++;if(which==11)r.surfaceDensity=2;
  if(which==12)r.boundWindow=(void*)2;if(which==13)changed.textStyleRuns.push_back({false});
  if(which==14)r.fontConfigurationGeneration++;if(which==15)changed.pod.nodeKind=3;
  r.stagePreparedMeasurement({changed},f);int c=layouts;r.paint(f,changed,text,true,which==16?8:7);
  CHECK(layouts==c+1,"incomplete key consumed wrong private layout");
  r.renderEpoch=oldEpoch;r.boundGeneration=oldGen;r.permitGeometryRevision=oldGeom;r.surfaceDensity=oldDensity;r.boundWindow=oldWindow;r.fontConfigurationGeneration=1;
 }
 {MeasureJob m;configure(m);r.executeMeasure(&m);TextPaintFrame f;std::vector<Node>large(17,n);
  for(size_t i=0;i<large.size();++i){large[i].pod.nodeId=100+i;large[i].value=std::string(kPresentationLeaseNodeTextMax,'x');}
  r.stagePreparedMeasurement(large,f);
  CHECK(r.preparedMeasurement&&f.preparedMeasureUnits==3,"staging guessed pressure instead of charging real private");
  for(const auto&node:large)r.paint(f,node,node.value,false);
  CHECK(!r.preparedMeasurement&&f.preparedMeasureUnits==0,"real full-frame peak retained optional private");}
 {MeasureJob large;configure(large,std::string(kPresentationLeaseNodeTextMax+1,'x'));r.executeMeasure(&large);
  CHECK(!r.preparedMeasurement,"oversized private retention bypassed node bound");}
 {Renderer b;TextPaintFrame full;std::string payload(kPresentationLeaseNodeTextMax-4,'x');
  for(uint64_t i=0;i<16;++i){Node c;c.pod.nodeId=1000+i;c.pod.nodeKind=3;b.paint(full,c,payload,false);}
  b.publish(full);CHECK(b.publishedPresentationLease.size()==16,"full old-table setup");
  MeasureJob m;configure(m,std::string(80,'a'));b.executeMeasure(&m);
  CHECK(!b.preparedMeasurement,"private retention ignored real old table units");b.teardown();}
 {MeasureJob m;configure(m,"A中");r.executeMeasure(&m);TextPaintFrame f;r.stagePreparedMeasurement({n},f);
  int c=layouts;r.paint(f,n,"A中");CHECK(layouts==c,"UTF8 body/UTF16 units failed private transfer");}
 {MeasureJob m;configure(m);r.executeMeasure(&m);r.teardown();CHECK(!r.preparedMeasurement&&r.fontPool.liveGenerations()==0,"teardown retained native/font owner");}
 CHECK(r.publishedPresentationLease.empty()&&!r.lastPaintLayout,"teardown kept accepted resources");
 {Renderer b;TextPaintFrame full;std::string payload(kPresentationLeaseNodeTextMax,'x');
  for(uint64_t i=0;i<16;++i){Node c;c.pod.nodeId=1000+i;c.pod.nodeKind=3;c.pod.isInteractive=0;b.paint(full,c,payload,false);}
  b.publish(full);CHECK(b.leaseTableUnits(b.publishedRenderOnlyLease)==kPresentationLeaseTotalUnitsMax,
     "render-only/private peak fixture not full");
  MeasureJob m;configure(m);b.executeMeasure(&m);
  CHECK(b.publishedRenderOnlyLease.empty()&&b.preparedMeasurement,
     "optional static holding displaced required private body or hid peak");
  TextPaintFrame f;b.stagePreparedMeasurement({n},f);int before=layouts;b.paint(f,n);
  CHECK(layouts==before&&f.candidate&&f.candidate->typography,
     "body did not transfer after optional static retirement");b.publish(f);b.teardown();
  CHECK(!b.preparedMeasurement&&b.publishedRenderOnlyLease.empty()&&b.fontPool.liveGenerations()==0,
     "render-only/private teardown leaked");}
 {Renderer b;Node c;c.pod.nodeId=1000;c.pod.nodeKind=3;c.pod.isInteractive=0;
  {TextPaintFrame f;b.paint(f,c,std::string(kPresentationLeaseNodeTextMax,'x'),false);b.publish(f);}
  MeasureJob m;configure(m);b.executeMeasure(&m);CHECK(b.preparedMeasurement,"overflow-bound private fixture absent");
  std::vector<Node>large(17,n);for(size_t i=0;i<large.size();++i){large[i].pod.nodeId=100+i;large[i].value=std::string(kPresentationLeaseNodeTextMax,'x');}
  TextPaintFrame f;b.stagePreparedMeasurement(large,f);
  for(const auto&node:large)b.paint(f,node,node.value,false);
  CHECK(!b.preparedMeasurement&&f.preparedMeasureUnits==0&&f.presentationLeaseOverflow,
      "real old/private/new peak hid the remaining oversized scene");b.teardown();}
 {Renderer b;TextPaintFrame accepted;
  for(uint64_t i=0;i<15;++i){Node c;c.pod.nodeId=1000+i;c.pod.nodeKind=3;b.paint(accepted,c,std::string(16300,'l'),false);}
  b.paint(accepted,n,std::string(3000,'A'));b.publish(accepted);
  MeasureJob m;configure(m,std::string(3000,'B'));b.execute(&m);
  CHECK(b.preparedMeasurement,"exact simultaneous private peak fixture missing");
  TextPaintFrame f;Node c;c.pod.nodeId=666;c.pod.nodeKind=3;f.leaseRequiredNodeId=666;
  b.stagePreparedMeasurement({c},f);
  duringLayout=[&]{CHECK(!b.preparedMeasurement,"private object omitted from real required peak");};
  b.paint(f,c,std::string(14600,'R'),false);
  CHECK(!f.presentationLeaseOverflow&&f.presentationLease.count(666),"optional private displaced required work");b.teardown();}
 puts("PASS actual measure-to-paint unique transfer; complete key; A2 old/private/new peak; cancellation/failure/retirement");
}
'''
    measurement_pod = 'struct CjguiInternalRendererTextMeasurement { uint32_t width=0,height=0,lineHeight=0,baseline=0; };\n'
    code = code.replace('@@DECLARATIONS@@', measurement_pod + declarations)
    replacements = {'CONSTANTS': constants, 'PREPARED': prepared, 'UTF16': utf16,
                    'HELPER': helper, 'WIDTH': width, 'MEASURED': measured,
                    'LEASE_UNITS': lease_units, 'FALLBACK': fallback, 'WIRE': wire,
                    'PRE_ADMISSION': pre_admission, 'PUBLIC_ENTRY': entry, **snippets}
    # Delimited whole-line tokens avoid one marker replacing another's suffix.
    for token, value in sorted(replacements.items(), key=lambda item: -len(item[0])):
        code = code.replace('@@'+token+'@@', value)
    if code_transform:
        code = code_transform(source, code)
    name = mutation or 'baseline'
    with tempfile.TemporaryDirectory(prefix='cjgui-private-measure-') as directory:
        tmp = Path(directory);cpp=tmp/'test.cpp';exe=tmp/'test';cpp.write_text(code)
        command=['clang++','-std=c++17','-I'+str(SOURCE.parent),str(cpp),'-o',str(exe)]
        built=subprocess.run(command,capture_output=True,text=True)
        result=subprocess.run([str(exe)],capture_output=True,text=True) if not built.returncode else built
        print(name+': '+result.stdout+result.stderr,end='')
        if os.environ.get('CJGUI_H_NATIVE_TEST_ARTIFACTS'):
            out=Path(os.environ['CJGUI_H_NATIVE_TEST_ARTIFACTS']);out.mkdir(parents=True,exist_ok=True)
            (out/(name+'.cpp')).write_text(code)
            (out/(name+'.json')).write_text(json.dumps({'source_SHA256':hashlib.sha256(source.encode()).hexdigest(),
                'compile_exit':built.returncode,'run_exit':None if built.returncode else result.returncode,
                'mutation':mutation,'stdout':result.stdout,'stderr':result.stderr},indent=2)+'\n')
        if built.returncode:raise RuntimeError('compilation failure is not a behavioral RED')
        return result.returncode


if __name__=='__main__':
    if run():sys.exit(1)
    if '--selftest' in sys.argv:
        for mutation in ('disable-transfer','omit-private-peak','omit-full-text','keep-cancelled',
                         'omit-teardown','destroy-transferred',
                         'retire-on-unrelated','omit-unrelated-peak','omit-font-clear'):
            if run(mutation)==0:raise AssertionError('mutation passed: '+mutation)

#!/usr/bin/env python3
"""Run production acquisition, retention and Flush-publication ownership slices.

The Drawing SDK is a counted substitute, the font pool is real.  No duplicate
reuse predicate or hand-filled accepted Typography is used.  A cancelled/failed
frame simply dies without calling the actual success-publication slice.
"""
from pathlib import Path
import hashlib
import json
import os
import re
import subprocess
import sys
import tempfile

SOURCE = Path(__file__).resolve().parents[1] / 'host/ohos_renderer.cpp'


def block(text, marker):
    start = text.index(marker)
    opening = text.index('{', start)
    depth = 0
    for i in range(opening, len(text)):
        depth += (text[i] == '{') - (text[i] == '}')
        if not depth:
            return text[start:i + 1]
    raise ValueError(marker)


def run(mutation=None, content_box=False, render_only=False):
    source = SOURCE.read_text()
    draw = block(source, '    void drawNodeText(')
    acquire = draw[draw.index('        const PaintedTextLayout *reusedLayout'):draw.index('        if (!m.typography)')]
    admission = draw[draw.index('        const bool leaseEligible'):draw.index('        const PaintedTextLayout *reusedLayout')]
    constants = '\n'.join(re.search(r'constexpr size_t '+name+r' = \d+;', source)[0]
        for name in ('kPresentationLeaseMax', 'kPresentationLeaseNodeTextMax',
                     'kPresentationLeaseNodeRunsMax', 'kPresentationLeaseTotalUnitsMax'))
    lease_units = '\n'.join(block(source, marker) for marker in (
        '    static size_t leaseTableUnits(', '    static size_t ownedLeaseTableUnits(',
        '    static size_t ownedLeaseTableSlots(', '    void pruneRenderOnlyLayouts('))
    retention = block(draw, '        if (!isEditingNode) {\n            // A2：pointerInteractive')
    caret_failure = block(draw, '            if (!caretRectFor(m.typography, caret, caretText, caretAffinity,')
    publish = block(source, '    void publishPaintedLayout(TextPaintFrame &frame)')
    publish = publish[publish.index('{') + 1:publish.index('        paintedLayoutUsable = true;')]
    helper = block(source, 'static bool cjguiOhosCanReuseEditingTypography(')
    width_helper = (block(source, 'static double cjguiOhosTextLayoutWidth(')
                    if 'static double cjguiOhosTextLayoutWidth(' in source else '')
    prepared_type = (block(source, 'struct PreparedTextMeasurement {') + ';'
                     if 'struct PreparedTextMeasurement {' in source else 'struct PreparedTextMeasurement {};')
    display = block(source, '    static std::string displayTextForNode(')
    conversions = '\n'.join(block(source, marker) for marker in (
        'std::u16string utf8ToUtf16(', 'std::string utf16ToUtf8('))
    teardown = block(source, '    void teardownSurface(')
    teardown = teardown[teardown.index('        preparedMeasurement.reset();'):
                        teardown.index('        const uint64_t tornGeneration')]
    reservation = block(source, '    void planPresentationLeaseReservation(')
    pressure_start = source.index('        // Measure/query jobs have no in-flight paint candidate;')
    font_pressure = source[pressure_start:source.index('        result.fontLease = fontPool.acquire(', pressure_start)]
    if mutation == 'outer-layout-width':
        needle = 'const double layoutWidth = cjguiOhosTextLayoutWidth(static_cast<double>(node.pod.width), kind);'
        assert acquire.count(needle) == 1, 'actual fresh draw width call moved'
        acquire = acquire.replace(needle, 'const double layoutWidth = static_cast<double>(node.pod.width);', 1)
    if mutation == 'disable-reuse':
        assert 'const bool reusePresentation = retainHere &&' in admission
        admission = admission.replace('const bool reusePresentation = retainHere &&',
                                  'const bool reusePresentation = false &&')
    if mutation == 'omit-transfer':
        start = publish.index('        for (auto &entry : frame.presentationLease)')
        loop = block(publish[start:], '        for (auto &entry : frame.presentationLease)')
        publish = publish[:start] + publish[start:].replace(loop, '', 1)
    if mutation == 'destroy-borrowed-on-caret-failure':
        assert '!isEditingNode && !reusePresentation' in caret_failure
        caret_failure = caret_failure.replace('!isEditingNode && !reusePresentation', '!isEditingNode')
    if mutation == 'disable-render-reuse':
        needle = 'if (!renderOnlyEligible) return nullptr;'
        assert admission.count(needle) == 1
        admission = admission.replace(needle, 'if (true) return nullptr;', 1)
    if mutation == 'omit-render-full-bytes':
        needle = 'layout.renderTextBytes == text &&'
        assert admission.count(needle) == 1
        admission = admission.replace(needle, 'true &&', 1)
    if mutation == 'omit-render-color':
        needle = 'last.node.textRed == node.textRed &&'
        assert helper.count(needle) == 1
        helper = helper.replace(needle, 'true &&', 1)
    if mutation == 'omit-render-old-peak':
        needle = 'leaseTableUnits(publishedRenderOnlyLease)'
        assert admission.count(needle) == 1
        admission = admission.replace(needle, 'size_t(0)', 1)
    if mutation == 'omit-render-pressure-retire':
        needle = 'pruneRenderOnlyLayouts(frame, true);'
        assert font_pressure.count(needle) == 1
        font_pressure = font_pressure.replace(needle, '(void)frame;', 1)
    if mutation == 'drop-borrowed-render-only':
        needle = 'if (borrowed || (sealedOnly'
        assert lease_units.count(needle) == 1
        lease_units = lease_units.replace(needle, 'if (false || (sealedOnly', 1)
    code = r'''
#include "cjgui_ohos_font_lease.h"
#include <algorithm>
#include <chrono>
#include <cassert>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <map>
#include <memory>
#include <mutex>
#include <set>
#include <string>
#include <vector>
#define RLOGI(...) ((void)0)
#define RLOGW(...) ((void)0)
#define RLOGD(...) ((void)0)
#define CHECK(value, why) do { if (!(value)) { puts("FAIL " why); std::exit(1); } } while (0)
CONSTANTS
constexpr uint32_t kKindText=3;
constexpr uint32_t kKindButton=4;
constexpr uint32_t kKindTextInput=5,kKindIntegerInput=6,kKindBooleanInput=7;
constexpr uint32_t kKindMultiline=10;
constexpr size_t kMaxSessions=4;
int builds=0, destroyed=0;
double lastConstraintWidth=-1;
std::set<void*> dead;
struct OH_Drawing_Typography { int id=0; };
struct FontCollection {};
using OhosFontPool=CjguiOhosFontPool<FontCollection>;
void cjguiOhosDestroyObservedTypography(OH_Drawing_Typography *p) {
    if (p) { CHECK(!dead.count(p), "double destroy"); dead.insert(p); ++destroyed; delete p; }
}
struct Pod {
    uint64_t nodeId=107, acceptedBindingEpoch=1, projectionVersion=1;
    int resourceId=77, width=377, height=80, x=10, y=20;
    int isInteractive=1, isReadOnly=0;
    uint32_t nodeKind=3, fontWeight=0;
    double fontSize=16, textRed=1, textGreen=1, textBlue=1, textAlpha=1;
};
using CjguiInternalRendererComposableNode=Pod;
struct OhosTextStyleRun { bool selectionBackgroundOnly=false; };
struct Node { Pod pod; std::string value, label; std::vector<OhosTextStyleRun> textStyleRuns; };
using SceneNode=Node;
struct Session {
    bool inUse=false, editing=false, editorRetired=false;
    uint64_t token=0, editingNodeId=0;
    int64_t editingContextId=0;
    std::u16string editingText;
};
struct {std::mutex lock; Session sessions[kMaxSessions];} g_sessions;
std::u16string composedBuffer(const Session &s){return s.editingText;}
bool cjguiOhosTextIntersectsClip(const Pod&){return true;} // fixed entirely visible scene
CONVERSIONS
struct PaintedTextLayout {
    OhosFontPool::Lease fontLease;
    std::unique_ptr<OH_Drawing_Typography,decltype(&cjguiOhosDestroyObservedTypography)> typography
        {nullptr, &cjguiOhosDestroyObservedTypography};
    Pod node;
    std::u16string text;
    uint64_t session=0, renderEpoch=0, basePresentTicket=0, projectionVersion=0, serial=0;
    uint64_t generation=0, geometryRevision=0;
    int64_t paintContext=0, layoutSourceContext=0;
    uint64_t layoutOwnedBinding=0, layoutOwnedDeclaredBinding=0;
    void *window=nullptr;
    int width=0, height=0;
    double density=1, relativeOriginX=0, relativeOriginY=0;
    bool plainTextLayout=false, borrowsEditingTypography=false, borrowsPresentationTypography=false;
    std::string renderTextBytes;
    bool borrowsRenderOnlyTypography=false;
};
struct TextPaintFrame {
    uint64_t session=1, ticket=1, projectionVersion=1;
    uint64_t ownedMirrorBindingEpoch=0, ownedMirrorDeclaredBindingEpoch=0;
    int64_t ownedMirrorOwnerVersion=-1;
    int ownedCoverage=0, textWorkTrace=0;
    uint64_t ownedNodeId=0;
    bool ownedMirrorValid=false;
    std::u16string ownedMirrorText;
    int64_t sourceContextId=0;
    std::unique_ptr<PaintedTextLayout> candidate;
    std::map<uint64_t,std::unique_ptr<PaintedTextLayout>> presentationLease;
    std::map<uint64_t,std::unique_ptr<PaintedTextLayout>> renderOnlyLease;
    size_t renderOnlyHits=0, renderOnlyMisses=0, renderOnlyEvicted=0;
    uint64_t leaseRequiredNodeId=0;
    uint64_t leaseEditingNodeId=0;
    bool leasePeakCharged=false, presentationLeaseOverflow=false;
    const char *textFailureReason=nullptr;
    size_t leaseTransientUnits=0, leaseReplacedSlots=0, leaseReplacedUnits=0;
    size_t preparedMeasureUnits=0;
    size_t leaseReservedSlotsLeft=0, leaseReservedUnitsLeft=0;
    std::map<uint64_t,std::pair<size_t,size_t>> leaseReservations;
    std::vector<uint64_t> leaseSkippedNodeIds;
};
struct Measured {
    OhosFontPool::Lease fontLease;
    OH_Drawing_Typography *typography=nullptr;
    double height=10, longestLine=1, maxWidth=377;
    size_t lineCount=1;
    double alphabeticBaseline=8;
};
double OH_Drawing_TypographyGetHeight(OH_Drawing_Typography*) { return 10; }
double OH_Drawing_TypographyGetLongestLine(OH_Drawing_Typography*) { return 1; }
double OH_Drawing_TypographyGetMaxWidth(OH_Drawing_Typography*) { return 377; }
size_t OH_Drawing_TypographyGetLineCount(OH_Drawing_Typography*) { return 1; }
double OH_Drawing_TypographyGetAlphabeticBaseline(OH_Drawing_Typography*) { return 8; }
uint64_t observedCoverageInput(int) { return 0; }
template<class... Args> void cjguiOhosObserveTextWork(Args&&...) {}
HELPER
CONTENT_WIDTH_FUNCTION
PREPARED_TYPE
struct Renderer {
    int fontAlive=0, fontPeak=0;
    OhosFontPool fontPool{[this]{fontPeak=std::max(fontPeak,++fontAlive);return new FontCollection;},
                         [this](FontCollection *p){--fontAlive;delete p;}};
    uint64_t fontConfigurationGeneration=1, renderEpoch=1, boundGeneration=1;
    uint64_t permitGeometryRevision=1, textPaintSerial=0;
    void *boundWindow=(void*)1;
    int surfaceW=1320, surfaceH=2622;
    double surfaceDensity=3.5;
    std::unique_ptr<PaintedTextLayout> lastPaintLayout;
    std::map<uint64_t,std::unique_ptr<PaintedTextLayout>> publishedPresentationLease;
    std::map<uint64_t,std::unique_ptr<PaintedTextLayout>> publishedRenderOnlyLease;
    std::unique_ptr<PreparedTextMeasurement> preparedMeasurement;
    bool preparedMeasurementMatches(const TextPaintFrame&,const Node&,const std::string&,int64_t) {
        CHECK(!preparedMeasurement,"private transfer outside accepted-reuse fixture");return false;
    }
    Measured takePreparedMeasurement(uint32_t) { CHECK(false,"unexpected private transfer");return {}; }
LEASE_UNITS
DISPLAY
RESERVATION
    template<class... Args> void observeResources(Args&&...) {}
    uint64_t textWorkFingerprint(const std::string&) { return 1; } // forced collision, not a reuse answer
    Measured layoutTextStyled(const std::string &text,double,uint32_t,double width,bool,uint32_t,
                              const OhosTextStyleRun*,size_t,uint64_t,TextPaintFrame *frame=nullptr) {
FONT_PRESSURE
        lastConstraintWidth=width;
        auto lease=fontPool.acquire(utf8ToUtf16(text).size(),fontConfigurationGeneration);
        if(!lease)return {};
        ++builds; auto *p=new OH_Drawing_Typography{builds}; dead.erase(p);
        return {lease,p};
    }
    bool failCaret=false;
    bool caretRectFor(OH_Drawing_Typography*,uint32_t,const std::u16string&,int,double&,double&,double&) {
        return !failCaret;
    }
    void paint(TextPaintFrame &frame, Node node, std::u16string body=u"ABC",const std::string *raw=nullptr) {
        const bool isEditingNode=false, presentFeedback=false;
        const uint32_t kind=node.pod.nodeKind;
        int64_t layoutSourceContext=0, caretContext=0;
        std::u16string editComposed;
        std::string text=raw?*raw:utf16ToUtf8(body); node.value=text;
        text=displayTextForNode(node); uint32_t textColor=0;
ADMISSION
ACQUIRE
        if(!m.typography){frame.textFailureReason="render_only_text_layout_failed";return;}
        uint32_t caret=0; const auto &caretText=chargeText; int caretAffinity=0;
        double caretX=0, caretTop=0, caretBottom=10;
CARET_FAILURE
        struct { double originX=0, originY=0; } geom;
        geom.originX=node.pod.x+2; geom.originY=node.pod.y+2;
RETENTION
    }
    void publish(TextPaintFrame &frame) { PUBLISH }
    void close() { TEARDOWN }
};
int main() {
    Renderer r; Node n;
    { TextPaintFrame initial; r.paint(initial,n); r.publish(initial); }
    CHECK(builds==1 && r.publishedPresentationLease.size()==1,"initial real publication");
    auto *original=r.publishedPresentationLease.at(n.pod.nodeId)->typography.get();
    CHECK(original,"initial native layout");
    for (unsigned i=0;i<12;++i) {
        TextPaintFrame repeat; repeat.ticket=i+2;
        r.paint(repeat,n); r.publish(repeat);
        CHECK(builds==1 && destroyed==0 && r.publishedPresentationLease.size()==1,
              "repeated same-value resource population did not converge");
    }
    { TextPaintFrame failed; r.paint(failed,n);
      CHECK(builds==1,"same presentation laid out twice");
      CHECK(r.publishedPresentationLease.at(n.pod.nodeId)->typography.get()==original,"early ownership move"); }
    CHECK(destroyed==0,"failed frame destroyed accepted layout");
    { TextPaintFrame success; success.ticket=9; success.projectionVersion=8;
      n.pod.x=33; n.pod.y=44; n.pod.projectionVersion=8;
      r.paint(success,n); r.publish(success); }
    auto &accepted=r.publishedPresentationLease.at(n.pod.nodeId);
    CHECK(accepted->typography.get()==original && builds==1,"successful Flush did not transfer actual object");
    CHECK(accepted->basePresentTicket==9 && accepted->projectionVersion==8 &&
          accepted->relativeOriginX==2 && accepted->node.x==33 && accepted->node.y==44,
          "old per-frame source or geometry wrapper reused");
    { auto next=r.fontPool.acquire(OhosFontPool::kWorkUnitsPerGeneration,1);
      CHECK(next && next->id!=accepted->fontLease->id,"no real font work rollover");
      TextPaintFrame rolled; r.paint(rolled,n); r.publish(rolled);
      CHECK(builds==1 && r.publishedPresentationLease.at(n.pod.nodeId)->fontLease->id!=next->id,
            "valid old font lease relabelled or rebuilt"); }
    { TextPaintFrame failedCaret; r.failCaret=true; r.paint(failedCaret,n); r.failCaret=false; }
    CHECK(destroyed==0 && !dead.count(original),"caret failure destroyed borrowed accepted object");
    // A hash collision cannot make different full text reusable.
    { TextPaintFrame changed; r.paint(changed,n,u"ABD"); CHECK(builds==2,"full text equality missing"); }
    { TextPaintFrame changed; auto c=n; c.pod.width--; r.paint(changed,c); CHECK(builds==3,"width guard"); }
    { TextPaintFrame changed; auto c=n; c.pod.textRed=0.5; r.paint(changed,c); CHECK(builds==4,"baked color guard"); }
    { TextPaintFrame changed; auto c=n; c.pod.fontSize++; r.paint(changed,c); CHECK(builds==5,"font size guard"); }
    { TextPaintFrame changed; auto c=n; c.pod.fontWeight++; r.paint(changed,c); CHECK(builds==6,"font weight guard"); }
    { TextPaintFrame changed; auto c=n; c.pod.acceptedBindingEpoch++; r.paint(changed,c); CHECK(builds==7,"binding guard"); }
    { TextPaintFrame changed; auto c=n; c.pod.resourceId++; r.paint(changed,c); CHECK(builds==8,"resource guard"); }
    { TextPaintFrame changed; r.fontConfigurationGeneration=2; r.paint(changed,n); CHECK(builds==9,"font configuration guard"); }
    r.fontConfigurationGeneration=1;
    { TextPaintFrame changed; r.surfaceDensity=2; r.paint(changed,n); CHECK(builds==10,"density guard"); }
    r.surfaceDensity=3.5;
    { TextPaintFrame changed; r.permitGeometryRevision++; r.paint(changed,n); CHECK(builds==11,"geometry guard"); }
    r.permitGeometryRevision--;
    { TextPaintFrame changed; changed.session=2; r.paint(changed,n); CHECK(builds==12,"session guard"); }
    { TextPaintFrame changed; auto c=n; c.textStyleRuns.push_back({false}); r.paint(changed,c); CHECK(builds==13,"baked style/background guard"); }
    { TextPaintFrame selection; auto c=n; c.textStyleRuns.push_back({true}); r.paint(selection,c);
      CHECK(builds==13,"independently painted selection forced reshaping"); }
    // The old object is still queryable until a changed frame actually succeeds.
    CHECK(r.publishedPresentationLease.at(n.pod.nodeId)->typography.get()==original && !dead.count(original),
          "rejected candidates stole old hit-test object");
    { TextPaintFrame changed; r.paint(changed,n,u"ABCDE"); r.publish(changed); }
    CHECK(builds==14 && destroyed==13,"successful text change did not retire old actual object");
    { TextPaintFrame retired; r.publish(retired); }
    CHECK(r.publishedPresentationLease.empty() && destroyed==builds,"retirement leaks actual object");
    CHECK(r.fontPool.liveGenerations()<=OhosFontPool::kMaxGenerations,"font generation bound");
    // All tests below execute the real admission block before expensive work.
    const int beforeBudget=builds;
    { TextPaintFrame optional; r.paint(optional,n,std::u16string(kPresentationLeaseNodeTextMax+1,u'a'));
      CHECK(builds==beforeBudget && optional.leaseSkippedNodeIds.size()==1 &&
            !optional.presentationLeaseOverflow,"optional oversized node prepared or whole frame refused"); }
    { TextPaintFrame required; required.leaseRequiredNodeId=n.pod.nodeId;
      r.paint(required,n,std::u16string(kPresentationLeaseNodeTextMax+1,u'a'));
      CHECK(builds==beforeBudget && required.presentationLeaseOverflow,"required oversize not rejected before prepare"); }
    { TextPaintFrame runs; auto c=n; c.textStyleRuns.resize(kPresentationLeaseNodeRunsMax+1);
      r.paint(runs,c); CHECK(builds==beforeBudget && runs.leaseSkippedNodeIds.size()==1,"run budget bypass"); }
    // Fill the accepted table only via actual draws and actual publication.
    { TextPaintFrame full;
      for (uint64_t i=1;i<=kPresentationLeaseMax;++i) { auto c=n; c.pod.nodeId=i; r.paint(full,c); }
      r.publish(full); }
    CHECK(r.publishedPresentationLease.size()==kPresentationLeaseMax,"entry budget baseline");
    const int fullBuilds=builds;
    { TextPaintFrame replacement; auto c=n; c.pod.nodeId=1; r.paint(replacement,c);
      CHECK(builds==fullBuilds && replacement.presentationLease.size()==1,"same-node replacement charged as new slot"); }
    { TextPaintFrame newNode; auto c=n; c.pod.nodeId=kPresentationLeaseMax+1; r.paint(newNode,c);
      CHECK(builds==fullBuilds && newNode.leaseSkippedNodeIds.size()==1,"old+new entry peak not bounded"); }
    { TextPaintFrame peak; peak.leaseTransientUnits=kPresentationLeaseTotalUnitsMax;
      auto c=n; c.pod.nodeId=1; r.paint(peak,c);
      CHECK(builds==fullBuilds && peak.leaseSkippedNodeIds.size()==1,"temporary peak omitted"); }
    { TextPaintFrame retired; r.publish(retired); }
    CHECK(destroyed==builds,"budget fixtures leaked native objects");
    puts("PASS presentation full-key reuse; fresh wrapper; real font rollover; failed/caret/changed/retired ownership");
    return 0;
}
'''
    if render_only:
        # Exercise the real Paint statement as well as the existing acquisition,
        # retention and success-publication slices. No input eligibility changes.
        paint = next(line.strip() for line in draw.splitlines()
                     if line.strip().startswith('OH_Drawing_TypographyPaint(m.typography,'))
        code = code.replace('int builds=0, destroyed=0;', 'int builds=0, destroyed=0, paints=0;')
        code = code.replace('HELPER\n', '''
void OH_Drawing_TypographyPaint(OH_Drawing_Typography *p, void *, double, double) {
    CHECK(p && !dead.count(p), "paint uses missing/retired Typography"); ++paints;
}
HELPER
''', 1)
        code = code.replace('RETENTION\n', 'void *canvas=nullptr;\n        '+paint+'\nRETENTION\n', 1)
    for marker, value in [('CONSTANTS', constants), ('LEASE_UNITS', lease_units), ('ADMISSION', admission),
                          ('HELPER', helper), ('CONTENT_WIDTH_FUNCTION', width_helper),
                          ('CONVERSIONS', conversions), ('DISPLAY', display), ('TEARDOWN', teardown),
                          ('RESERVATION', reservation),
                          ('FONT_PRESSURE', font_pressure),
                          ('PREPARED_TYPE', prepared_type),
                          ('ACQUIRE', acquire), ('RETENTION', retention),
                          ('CARET_FAILURE', caret_failure), ('PUBLISH', publish)]:
        code = code.replace(marker, value)
    if content_box:
        common = SOURCE.parent.parent / 'snapshot/src/composable_ui.cj'
        inset = int(re.search(r'CJGUI_COMPOSABLE_UI_TEXT_HORIZONTAL_INSET: Int64 = (\d+)',
                              common.read_text())[1])
        main = r'''
int main() {
    for (uint32_t kind : {uint32_t(3),uint32_t(10)}) {
        for (int outer : {333,14,15,1,0}) {
            Renderer r; Node n; n.pod.nodeKind=kind; n.pod.width=outer;
            TextPaintFrame candidate; r.paint(candidate,n);
            const double expected=std::max(1,outer-COMMON_INSET*2);
            CHECK(lastConstraintWidth==expected,"draw did not consume common measured content width");
        }
    }
    // Other kinds do not use this shared natural-height content-width path.
    { Renderer r; Node n; n.pod.nodeKind=4; n.pod.width=333;
      TextPaintFrame candidate; r.paint(candidate,n);
      CHECK(lastConstraintWidth==333,"unrelated button layout changed"); }
    puts("PASS actual draw preparation matches common content width; narrow other-kind boundary");
}
'''.replace('COMMON_INSET', str(inset))
        code = code[:code.index('int main() {')] + main
    if render_only:
        main = r'''
int main() {
    Renderer r; Node n; n.pod.isInteractive=0;
    for (unsigned i=0; i<13; ++i) {
        TextPaintFrame frame; frame.ticket=i+1; frame.projectionVersion=i+1;
        r.paint(frame,n); r.publish(frame);
        CHECK(r.publishedPresentationLease.empty(),"ordinary label acquired input/presentation eligibility");
    }
    printf("actual_paints=%d actual_Layouts=%d destroyed=%d\n",paints,builds,destroyed);
    CHECK(paints==13,"controlled workload changed actual Paint count");
    CHECK(builds==1,"unchanged render-only declaration repeated SDK Layout");
    CHECK(r.publishedRenderOnlyLease.size()==1,"no render-only resource retained");
    auto *original=r.publishedRenderOnlyLease.at(n.pod.nodeId)->typography.get();
    {TextPaintFrame failed; r.paint(failed,n);
     CHECK(failed.renderOnlyLease.at(n.pod.nodeId)->borrowsRenderOnlyTypography &&
           !failed.renderOnlyLease.at(n.pod.nodeId)->typography &&
           r.publishedRenderOnlyLease.at(n.pod.nodeId)->typography.get()==original,
           "failed Flush stole accepted ownership");}
    CHECK(destroyed==0 && !dead.count(original),"failed borrow destroyed accepted native object");
    {TextPaintFrame moved; auto c=n; c.pod.x=33; c.pod.y=44;
     r.paint(moved,c); r.publish(moved);
     const auto &a=*r.publishedRenderOnlyLease.at(n.pod.nodeId);
     CHECK(builds==1 && a.typography.get()==original && a.node.x==33 && a.node.y==44 &&
           a.relativeOriginX==2 && a.relativeOriginY==2,"position-only change reshaped or reused old wrapper");}
    int expected=builds;
    const auto checkMiss=[&](Node c,const std::u16string &text=u"ABC",const std::string *raw=nullptr){
        TextPaintFrame failed; r.paint(failed,c,text,raw);
        CHECK(builds==++expected,"effective full-key change reused accepted Typography");
        if(!r.publishedRenderOnlyLease.count(n.pod.nodeId))
            fprintf(stderr,"keycase=%d font_live=%zu font_created=%llu optional_cache=%zu\n",expected,
                r.fontPool.liveGenerations(),(unsigned long long)r.fontPool.stats().created,
                r.publishedRenderOnlyLease.size());
        CHECK(r.publishedRenderOnlyLease.count(n.pod.nodeId)==1,"key-only case reached optional font-pressure retirement");
        CHECK(r.publishedRenderOnlyLease.at(n.pod.nodeId)->typography.get()==original,
              "failed changed candidate replaced accepted resource");
    };
    checkMiss(n,u"A中👩‍💻");
    // Same UTF-16 after the real decoder, but different full SDK input bytes.
    const std::string byteDifferent=std::string("ABC")+char(0xff);checkMiss(n,u"ABC",&byteDifferent);
    {auto c=n;c.pod.width--;checkMiss(c);}
    {auto c=n;c.pod.fontSize++;checkMiss(c);}
    {auto c=n;c.pod.fontWeight++;checkMiss(c);}
    {auto c=n;c.pod.textRed=0.5;checkMiss(c);}
    {auto c=n;c.pod.textAlpha=0.5;checkMiss(c);}
    {auto c=n;c.pod.resourceId++;checkMiss(c);}
    {auto c=n;c.pod.acceptedBindingEpoch++;checkMiss(c);}
    {auto c=n;c.pod.nodeKind=kKindButton;checkMiss(c);}
    {r.surfaceDensity=2;checkMiss(n);r.surfaceDensity=3.5;}
    {r.renderEpoch++;checkMiss(n);r.renderEpoch--;}
    {r.boundWindow=(void*)2;checkMiss(n);r.boundWindow=(void*)1;}
    {r.boundGeneration++;checkMiss(n);r.boundGeneration--;}
    {r.permitGeometryRevision++;checkMiss(n);r.permitGeometryRevision--;}
    {r.surfaceW++;checkMiss(n);r.surfaceW--;}
    {r.surfaceH++;checkMiss(n);r.surfaceH--;}
    {TextPaintFrame other;other.session=2;r.paint(other,n);
     CHECK(builds==++expected,"render session guard missing");}
    for(bool background:{false,true}){
        TextPaintFrame styled;auto c=n;c.textStyleRuns.push_back({background});r.paint(styled,c);
        CHECK(builds==++expected && styled.renderOnlyLease.empty(),"styled/selection runs entered plain cache");
    }
    // Isolate key invalidation from the separately tested legitimate optional
    // retirement at three generations; do not require cache to remain pinned.
    {r.fontConfigurationGeneration++;checkMiss(n);r.fontConfigurationGeneration--;}
    r.close();CHECK(r.fontAlive==0 && destroyed==builds,"real teardown leaked cached Typography/font");
    {
        Renderer buttons;Node b;b.pod.nodeKind=kKindButton;b.label="Save";
        const int before=builds;
        {TextPaintFrame f;buttons.paint(f,b,u"Draft");buttons.publish(f);}
        CHECK(buttons.publishedRenderOnlyLease.at(b.pod.nodeId)->renderTextBytes=="Save Draft",
              "button effective display bytes not retained");
        {TextPaintFrame f;buttons.paint(f,b,u"Draft");buttons.publish(f);}
        CHECK(builds==before+1,"unchanged effective button label reshaped");
        b.label="Keep";{TextPaintFrame f;buttons.paint(f,b,u"Draft");}
        CHECK(builds==before+2,"changed label with unchanged value reused old text");
        buttons.close();CHECK(buttons.fontAlive==0,"button close font leak");
    }
    const auto body=std::u16string(kPresentationLeaseNodeTextMax,u'a');
    {
        Renderer pressure;Node c;c.pod.isInteractive=0;
        {TextPaintFrame f;for(uint64_t i=1;i<=16;++i){c.pod.nodeId=i;pressure.paint(f,c,body);}pressure.publish(f);}
        CHECK(pressure.leaseTableUnits(pressure.publishedRenderOnlyLease)==kPresentationLeaseTotalUnitsMax,
              "optional workload did not fill actual retained budget");
        Node required;required.pod.nodeId=999;
        TextPaintFrame next;next.leaseRequiredNodeId=999;
        required.value="Z";pressure.planPresentationLeaseReservation({required},next);
        CHECK(next.leaseReservedUnitsLeft==1,"actual required reservation absent");
        pressure.paint(next,required,u"Z");
        CHECK(!next.presentationLeaseOverflow && next.presentationLease.size()==1 &&
              pressure.publishedRenderOnlyLease.empty(),"optional old cache hid peak or displaced required target");
        pressure.publish(next);pressure.close();CHECK(pressure.fontAlive==0,"pressure close leak");
    }
    {
        Renderer ordered;Node old;old.pod.isInteractive=0;old.pod.nodeId=500;
        {TextPaintFrame f;ordered.paint(f,old,body);ordered.publish(f);}
        std::vector<Node> nodes;
        for(uint64_t i=1;i<=15;++i){Node c;c.pod.nodeId=i;c.pod.isInteractive=0;c.value=std::string(body.size(),'a');nodes.push_back(c);}
        Node required;required.pod.nodeId=999;required.value=std::string(body.size(),'a');nodes.push_back(required);
        TextPaintFrame f;f.leaseRequiredNodeId=999;ordered.planPresentationLeaseReservation(nodes,f);
        for(const auto &node:nodes)ordered.paint(f,node,body);
        CHECK(!f.presentationLeaseOverflow && f.presentationLease.count(999)==1 &&
              ordered.publishedRenderOnlyLease.empty(),"required target at end displaced by optional retention");
        ordered.publish(f);ordered.close();CHECK(ordered.fontAlive==0,"ordered close leak");
    }
    {
        Renderer full;Node p;
        {TextPaintFrame f;for(uint64_t i=1;i<=kPresentationLeaseMax;++i){p.pod.nodeId=i;full.paint(f,p);}full.publish(f);}
        CHECK(full.publishedPresentationLease.size()==kPresentationLeaseMax,"full required-table setup");
        Node ordinary;ordinary.pod.nodeId=1000;ordinary.pod.isInteractive=0;
        const int before=builds, beforePaint=paints;
        {TextPaintFrame f;full.paint(f,ordinary);
         CHECK(!f.presentationLeaseOverflow && f.renderOnlyLease.empty(),"no optional slot omitted normal drawing");}
        CHECK(builds==before+1 && paints==beforePaint+1,"optional cache overflow was not one normal Paint");
        full.close();CHECK(full.fontAlive==0,"full table close leak");
    }
    {
        Renderer full;Node p;
        {TextPaintFrame f;for(uint64_t i=1;i<=16;++i){p.pod.nodeId=i;full.paint(f,p,body);}full.publish(f);}
        p.pod.nodeId=1;const int before=builds;
        {TextPaintFrame same;full.paint(same,p,body);CHECK(!same.presentationLeaseOverflow && builds==before,
             "same SDK object charged twice at full bound");}
        {TextPaintFrame changed;changed.leaseRequiredNodeId=1;p.pod.textRed=0.5;full.paint(changed,p,body);
         CHECK(changed.presentationLeaseOverflow && builds==before,
               "new object discounted because future Flush would replace same id");}
        CHECK(full.publishedPresentationLease.size()==16,"failed candidate changed accepted query table");
        full.close();CHECK(full.fontAlive==0,"changed peak close leak");
    }

    {
        // Controlled render-thread draw/failed-Flush pressure, not a new human
        // latency sample. Every work unit below comes from actual fresh Layout.
        Renderer generations;Node cached;cached.pod.nodeId=1;cached.pod.isInteractive=0;
        Node mandatory2;mandatory2.pod.nodeId=2;
        Node mandatory3;mandatory3.pod.nodeId=3;
        Node fresh;fresh.pod.nodeId=4;fresh.pod.isInteractive=0;
        {TextPaintFrame f;generations.paint(f,cached,body);generations.publish(f);}
        for(int i=0;i<15;++i){TextPaintFrame failed;generations.paint(failed,fresh,body);}
        {TextPaintFrame f;generations.paint(f,cached,body);generations.paint(f,mandatory2,body);generations.publish(f);}
        CHECK(generations.fontPool.liveGenerations()==2,"second real generation missing");
        for(int i=0;i<15;++i){TextPaintFrame failed;generations.paint(failed,cached,body);generations.paint(failed,fresh,body);}
        {TextPaintFrame f;generations.paint(f,cached,body);generations.paint(f,mandatory2,body);
         generations.paint(f,mandatory3,body);generations.publish(f);}
        CHECK(generations.fontPool.liveGenerations()==3 && generations.publishedPresentationLease.size()==2,
              "third generation did not have real mandatory owners");
        for(int i=0;i<15;++i){TextPaintFrame failed;generations.paint(failed,cached,body);generations.paint(failed,fresh,body);
            CHECK(generations.publishedRenderOnlyLease.count(1)==1,"borrowed optional retired during real candidate");}
        const int before=builds;
        {TextPaintFrame blocked;generations.paint(blocked,cached,body);generations.paint(blocked,fresh,body);
         CHECK(blocked.textFailureReason && builds==before && generations.publishedRenderOnlyLease.count(1)==1,
               "three held generations neither refused nor preserved actual candidate");}
        CHECK(generations.fontAlive==3 && generations.fontPeak==3,"font slots exceeded three");
        {TextPaintFrame released;generations.paint(released,fresh,body);
         CHECK(!released.textFailureReason && builds==before+1 && generations.publishedRenderOnlyLease.empty() &&
               generations.publishedPresentationLease.size()==2,"unborrowed optional did not yield font slot to actual new Layout");}
        CHECK(generations.fontPeak==3,"retirement created a fourth simultaneously live generation");
        generations.close();CHECK(generations.fontAlive==0,"generation pressure close leaked");
    }
    CHECK(destroyed==builds,"font/Typos not zero after all real close paths");
    puts("PASS render-only full bytes/effective inputs, actual Paint count, failed Flush, current origin, required budget and close");
}
'''
        code = code[:code.index('int main() {')] + main
    suffix = mutation or ('render-only' if render_only else 'content-box' if content_box else 'baseline')
    with tempfile.TemporaryDirectory(prefix='cjgui-presentation-reuse-') as tmp:
        root = Path(tmp)
        (root / 'test.cpp').write_text(code)
        command = ['clang++', '-std=c++17', '-I' + str(SOURCE.parent), str(root/'test.cpp'), '-o', str(root/'test')]
        compiled = subprocess.run(command, capture_output=True, text=True)
        result = subprocess.run([str(root/'test')], capture_output=True, text=True) if not compiled.returncode else compiled
        print(suffix + ': ' + result.stdout + result.stderr, end='')
        if os.environ.get('CJGUI_H_NATIVE_TEST_ARTIFACTS'):
            out = Path(os.environ['CJGUI_H_NATIVE_TEST_ARTIFACTS'])
            out.mkdir(parents=True, exist_ok=True)
            (out / (suffix+'.cpp')).write_text(code)
            (out / (suffix+'.json')).write_text(json.dumps(dict(
                source=str(SOURCE), source_sha256=hashlib.sha256(source.encode()).hexdigest(),
                mutation=mutation, compile_command=command, compile_exit=compiled.returncode,
                run_exit=result.returncode if not compiled.returncode else None,
                stdout=result.stdout, stderr=result.stderr), indent=2)+'\n')
        if compiled.returncode:
            raise RuntimeError('fixture compilation failed, not a valid behavioral RED')
        return result.returncode


if __name__ == '__main__':
    content_box = '--content-box-contract' in sys.argv
    render_only = '--render-only-contract' in sys.argv
    if run(content_box=content_box, render_only=render_only):
        sys.exit(1)
    if '--selftest' in sys.argv:
        mutations = (('disable-render-reuse', 'omit-render-full-bytes', 'omit-render-color', 'omit-render-old-peak',
                      'omit-render-pressure-retire', 'drop-borrowed-render-only')
                     if render_only else ('outer-layout-width',) if content_box else
                     ('disable-reuse', 'omit-transfer', 'destroy-borrowed-on-caret-failure'))
        for mutation in mutations:
            if run(mutation, content_box=content_box, render_only=render_only) == 0:
                raise AssertionError('withdrawal did not fail: '+mutation)

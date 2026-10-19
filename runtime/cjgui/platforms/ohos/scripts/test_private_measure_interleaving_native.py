#!/usr/bin/env python3
"""Real execute/Measure/Redraw/Present with counted, synchronous Drawing SDK.

Reuse the existing production admission/acquisition/publication harness. Only
the OS surface, SDK, frozen text-source boundary and irrelevant image/geometry
diagnostics are substitutes. No shadow dispatch or private lifetime policy.
"""
import os
import sys
from pathlib import Path
from test_private_measure_transfer import run
from test_presentation_typography_reuse import block


def integrate(source, code, mutation=None):
    code = code.replace('struct PresentJob:WaitableJob{PresentJob():WaitableJob(JobKind::Present){}};', r'''
struct PresentJob:WaitableJob{PresentJob():WaitableJob(JobKind::Present){}
 uint64_t session=42,ticketId=1,projectionVersion=1,generation=1,geometryRevision=1;
 std::vector<Node>nodes;void*window=(void*)1;int width=377,height=800;
 bool ownedMirrorValid=true;std::u16string ownedMirrorText;
 int64_t sourceContextId=7,ownedMirrorOwnerVersion=1,ownedResourceId=77;
 uint64_t ownedMirrorBindingEpoch=1,ownedMirrorDeclaredBindingEpoch=1,ownedNodeId=107;
 uint32_t ownedNodeKind=10;CjguiOhosCoverage ownedCoverage;
 double clearR=0,clearG=0,clearB=0,clearA=1;
};''')
    code = code.replace('struct RedrawJob:WaitableJob{RedrawJob():WaitableJob(JobKind::Redraw){}};', r'''
struct RedrawJob:WaitableJob{RedrawJob():WaitableJob(JobKind::Redraw){}
 CjguiOhosCoverage installedCoverage;uint64_t installedSession=0,installedTicket=0;
};''')
    code = code.replace('struct TextPaintFrame{', r'''
struct TextPaintFrame{
 TextPaintFrame()=default;
 TextPaintFrame(uint64_t s,uint64_t t,uint64_t p,std::nullptr_t):session(s),ticket(t),projectionVersion(p){}
 bool ownedMirrorValid=true;std::u16string ownedMirrorText;int64_t sourceContextId=7,ownedResourceId=77;
 uint32_t ownedNodeKind=10;const char*textFailureReason=nullptr;
''')
    code = code.replace('CjguiOhosTextWorkTraceRef textWorkTrace;\n};\nstruct {',
        'CjguiOhosTextWorkTraceRef textWorkTrace;\n struct{CjguiOhosCoverage coverage;}ownedMirrorAccepted;uint64_t acceptedPaintTicketId=1;\n};\nstruct {', 1)
    code = code.replace('struct Session {', 'struct Session { bool inUse=true,editing=true;uint64_t token=42;std::u16string editingText=u"ABC";')
    code = code.replace('std::mutex lock;Session session;', 'std::mutex lock;Session sessions[1];Session&session=sessions[0];')
    sdk = r'''
using OH_Drawing_ErrorCode=int;constexpr int OH_DRAWING_SUCCESS=0;
struct OH_Drawing_Canvas{};struct OH_Drawing_Brush{};
bool failFlush=false;int flushes=0;std::function<void()>beforeFlush;
std::vector<std::string>drawn;std::vector<int>drawnIds;
OH_Drawing_Canvas*OH_Drawing_SurfaceGetCanvas(void*){static OH_Drawing_Canvas c;return &c;}
OH_Drawing_Brush*OH_Drawing_BrushCreate(){return new OH_Drawing_Brush;}
void OH_Drawing_BrushDestroy(OH_Drawing_Brush*b){delete b;}
template<class...A>void OH_Drawing_BrushSetAntiAlias(A...){}
template<class...A>void OH_Drawing_BrushSetColor(A...){}
template<class...A>void OH_Drawing_CanvasDrawBackground(A...){}
template<class...A>void OH_Drawing_CanvasSave(A...){}
template<class...A>void OH_Drawing_CanvasRestore(A...){}
template<class...A>void OH_Drawing_CanvasScale(A...){}
int OH_Drawing_SurfaceFlush(void*){++flushes;if(beforeFlush){auto h=std::move(beforeFlush);beforeFlush={};h();}return failFlush?1:0;}
template<class...A>uint32_t packColor(A...){return 0;}
struct{std::atomic<int>postBoundaryAttempts{0},drawEnter{0},drawExit{0},flushEnter{0},flushExit{0};}g_pcCalls;
struct{int(*surfaceActive)(void**,uint64_t*,int32_t*,int32_t*,double*,uint64_t*)=nullptr;}g_ingress;
enum class SurfaceBackend{None,Stub,Real};
constexpr size_t kMaxSessions=1;
constexpr uint32_t kKindTextInput=5,kKindIntegerInput=6,kKindBooleanInput=7;
std::u16string composedBuffer(const Session&s){return s.editingText;}
bool cjguiOhosTextIntersectsClip(const Pod&){return true;}
'''
    sdk += block(source, 'std::string utf16ToUtf8(const std::u16string &utf16)')
    code = code.replace('struct Renderer{', sdk + r'''
struct Renderer{
 SurfaceBackend surfaceBackend=SurfaceBackend::Real;void*surface=(void*)1;
 uint64_t lastFrameTicket=0,lastProjectionVersion=0,lastFrameGeneration=1;
 uint64_t lastFrameMirrorBindingEpoch=1,lastFrameMirrorDeclaredBindingEpoch=1,lastFrameOwnedNodeId=107;
 int64_t lastFrameMirrorOwnerVersion=1,lastFrameOwnedResourceId=77,lastFrameSourceContextId=7;
 uint32_t lastFrameOwnedNodeKind=10;bool lastFrameMirrorValid=true,hasLastFrame=false;
 std::u16string lastFrameMirrorText;std::vector<Node>lastNodes;
 CjguiOhosCoverage lastFrameCoverage;CjguiOhosTextWorkTraceRef lastFrameTextWorkTrace;
 void*lastFrameWindow=(void*)1;double lastClearR=0,lastClearG=0,lastClearB=0,lastClearA=1;
 uint64_t redrawFrames=0,submittedFrames=0,rejectedFlushes=0;
 std::atomic<uint64_t>busyGeneration{0};std::function<void()>afterDraw;
 bool cachedFrameMatchesSurface(){return hasLastFrame;}
 bool ownedPlainPostImageAwaitingAcceptedFrame(){return false;}
 void pruneImageBitmaps(){}
 bool ensureSurface(void*,uint64_t,int,int,uint64_t){return true;}
 bool applyClipChain(OH_Drawing_Canvas*,const Pod&){return true;}
 template<class...A>void drawFill(A...){}
 template<class...A>void drawNodeImage(A...){}
 template<class...A>void drawBorder(A...){}
 uint64_t activePresentationDragTarget(uint64_t){return 0;}
 void planPresentationLeaseReservation(const std::vector<Node>&,TextPaintFrame&f){f.leaseEditingNodeId=107;}
 void teardownSurface(bool=true){teardown();}
 void publishPaintedLayout(TextPaintFrame&f){publish(f);paintedLayoutUsable=true;}
 void drawNodeText(OH_Drawing_Canvas*,const Node&n,TextPaintFrame&f){
  paint(f,n,n.value,n.pod.nodeId==107,f.sourceContextId);
  if(f.candidate){drawn.push_back(n.value);drawnIds.push_back(f.candidate->typography ? f.candidate->typography->id : lastPaintLayout->typography->id);}
  if(afterDraw){auto h=std::move(afterDraw);afterDraw={};h();}
 }
''', 1)
    code = code.replace('void executePresent(PresentJob*){}', block(source, '    void executePresent(PresentJob *job)'))
    code = code.replace('void executeRedraw(RedrawJob*){}', block(source, '    void executeRedraw(const RedrawJob *wake=nullptr)'))
    code = code.replace('void planPresentationLeaseReservation(const std::vector<Node>&,TextPaintFrame&f){f.leaseEditingNodeId=107;}',
                        block(source, '    void planPresentationLeaseReservation('))
    if mutation == 'restore-tail-reset':
        marker = '        } else if (job->kind == JobKind::Teardown) {'
        start = code.index('    void execute(WaitableJob *job)')
        dispatch = block(code[start:], '    void execute(WaitableJob *job)')
        code = code.replace(dispatch, dispatch[:-1] + '\nif(job->kind!=JobKind::Measure)preparedMeasurement.reset();\n}')
    elif mutation == 'omit-private-peak':
        old = 'frame.leaseTransientUnits + frame.preparedMeasureUnits;'
        assert old in code
        code = code.replace(old, 'frame.leaseTransientUnits;', 1)
    elif mutation == 'restore-draw-mismatch-reset':
        old = '        const auto superseded = publishedPresentationLease.find(node.pod.nodeId);'
        assert old in code
        code = code.replace(old, 'if(isEditingNode && preparedMeasurement && !usePreparedMeasurement)preparedMeasurement.reset();\n'+old, 1)
    start = code.index('int main(){')
    code = code[:start] + r'''
void present(Renderer&r,const std::string&t,uint64_t ticket=1){
 PresentJob p;Node n;n.value=t;p.nodes={n};p.ticketId=ticket;p.projectionVersion=ticket;
 p.ownedMirrorText=utf8ToUtf16(t);r.execute(&p);
 CHECK(p.phaseSnapshot()==JobPhase::Done,"actual Present did not settle");
}
int main(){
 Renderer r;present(r,"OLD");int start=layouts;
 MeasureJob b;configure(b,"FUTURE");r.execute(&b);
 int id=r.preparedMeasurement->typography->id;auto*identity=r.preparedMeasurement->typography.get();
 {RedrawJob old;r.execute(&old);}
 CHECK(r.preparedMeasurement && r.preparedMeasurement->typography.get()==identity,
       "real execute old Redraw retired future private object (315/316/318)");
 CHECK(r.lastPaintLayout->text==u"OLD" && drawn.back()=="OLD" && drawnIds.back()!=id,
       "old Redraw displayed future body or borrowed its unpublished object");
 {CaretHitTestJob q;r.execute(&q);ImageRealizeJob image;r.execute(&image);
  CHECK(r.preparedMeasurement && r.preparedMeasurement->typography.get()==identity,
        "unrelated read/image execute retired future private object");}
 failFlush=true;{RedrawJob old;r.execute(&old);}failFlush=false;
 CHECK(!r.paintedLayoutUsable && r.preparedMeasurement && r.preparedMeasurement->typography.get()==identity,
       "old frame Flush failure retired untaken private or granted input");
 present(r,"FUTURE",2);
 CHECK(layouts==start+1 && !r.preparedMeasurement && r.lastPaintLayout->typography.get()==identity,
       "target did not transfer the exact once-laid-out private object");
 CHECK(r.lastPaintLayout->text==u"FUTURE" && identity->color==0xff262626 && colorUpdates==1,
       "unique target color/final text incorrect");
 CHECK(drawnIds.back()==id && drawn.back()=="FUTURE","target paint identity incorrect");
 {MeasureJob n;configure(n,"NEXT");r.execute(&n);int d=destroyed;
  failFlush=true;present(r,"NEXT",3);failFlush=false;
  CHECK(!r.preparedMeasurement && r.lastPaintLayout->text==u"FUTURE" && destroyed==d+1,
       "failed target resurrected taken private or destroyed accepted object");}
 {MeasureJob n;configure(n,"CANCELLED");r.execute(&n);int d=destroyed;
  PresentJob p;Node node;node.value="CANCELLED";p.nodes={node};p.ownedMirrorText=u"CANCELLED";
  r.afterDraw=[&]{p.cancelBeforeCommit();};int f=flushes;r.execute(&p);
  CHECK(p.phaseSnapshot()==JobPhase::Cancelled && !r.preparedMeasurement && flushes==f && destroyed==d+1,
       "cancel after take did not release once before Flush");}
 {MeasureJob a,b;configure(a,"KEEP");r.execute(&a);auto*kept=r.preparedMeasurement->typography.get();
  configure(b,"QUEUED CANCEL");b.cancelBeforeCommit();r.execute(&b);
  CHECK(r.preparedMeasurement && r.preparedMeasurement->typography.get()==kept,
       "queued cancelled request retired someone else's completed private object");
  MeasureJob fresh;configure(fresh,"NEW");int d=destroyed;r.execute(&fresh);
  CHECK(destroyed==d+1 && r.preparedMeasurement->text=="NEW","new eligible Measure failed to replace single slot");}
 {MeasureJob m;configure(m,"ABC");r.execute(&m);auto*kept=r.preparedMeasurement->typography.get();
  Node changed;changed.value="ABC";changed.pod.acceptedBindingEpoch=2;
  PresentJob p;p.nodes={changed};p.ownedMirrorText=u"ABC";r.execute(&p);
  CHECK(r.preparedMeasurement && r.preparedMeasurement->typography.get()==kept &&
        r.lastPaintLayout->typography.get()!=kept,"same text different frame binding consumed/retired private");
  g_sessions.session.editingAcceptedBindingEpoch=2;CaretHitTestJob q;r.execute(&q);
  CHECK(!r.preparedMeasurement,"actual binding retirement kept stale private object");
  g_sessions.session.editingAcceptedBindingEpoch=1;}
 {MeasureJob m;configure(m,"GEOMETRY");r.execute(&m);++r.permitGeometryRevision;CaretHitTestJob q;r.execute(&q);
  CHECK(!r.preparedMeasurement,"real environment retirement kept private object");--r.permitGeometryRevision;}
 r.teardown();CHECK(r.fontPool.liveGenerations()==0,"first renderer close retained native/font objects");
 {Renderer p;std::string label(16300,'l');TextPaintFrame frame;
  for(uint64_t i=0;i<15;++i){Node n;n.pod.nodeId=1000+i;n.pod.nodeKind=3;p.paint(frame,n,label,false);}
  p.publish(frame);present(p,std::string(3000,'A'));
  // Reinstall the real accepted table alongside the editor (the scene for this
  // fixture includes both); do not fabricate units or private pointers.
  TextPaintFrame accepted;
  for(uint64_t i=0;i<15;++i){Node n;n.pod.nodeId=1000+i;n.pod.nodeKind=3;p.paint(accepted,n,label,false);}
  Node editor;p.paint(accepted,editor,std::string(3000,'A'));p.publish(accepted);
  MeasureJob future;configure(future,std::string(3000,'B'));p.execute(&future);
  CHECK(p.preparedMeasurement,"pressure private fixture missing");
  const int before=layouts;TextPaintFrame required;Node n;n.pod.nodeId=666;n.pod.nodeKind=3;
  required.leaseRequiredNodeId=666;p.stagePreparedMeasurement({n},required);
  duringLayout=[&]{CHECK(!p.preparedMeasurement,"private not retired before required SDK work exceeded actual peak");};
  p.paint(required,n,std::string(14600,'R'),false);
  CHECK(!p.preparedMeasurement && !required.presentationLeaseOverflow && layouts==before+1 &&
        required.presentationLease.count(666),"optional private displaced legitimate required drawing");
  p.teardown();}
 CHECK(layouts==destroyed,"Typography objects not fully released exactly once");
 puts("PASS actual execute Measure -> old Redraw -> target Present; one layout identity; exact peak/lifetime; Flush/cancel/binding/close");
}
'''
    return code


if __name__ == '__main__':
    mutation = sys.argv[2] if len(sys.argv) == 3 and sys.argv[1] == '--mutation' else None
    sys.exit(run(code_transform=lambda source, code: integrate(source, code, mutation)))

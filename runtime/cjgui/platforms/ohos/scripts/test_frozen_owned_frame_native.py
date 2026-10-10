#!/usr/bin/env python3
"""Actual draw -> pre-Flush gate -> publish -> restore -> redraw, with drawing API doubles.

Only platform glyph/geometry functions are doubles. Source decisions, budget admission,
layout acquisition, ownership publication and redraw ordering are extracted verbatim.
"""
from pathlib import Path
import argparse, subprocess, tempfile
import test_presentation_budget_real_frame_native as a2

def build(source):
    s = source.read_text()
    fn = lambda key: a2.extract_function(s, key)
    layout = fn('struct PaintedTextLayout {') + ';'
    if 'layoutSourceContext' not in layout:
        layout = layout.replace('int64_t paintContext = 0;', 'int64_t paintContext = 0; int64_t layoutSourceContext = 0;')
    frame = fn('struct TextPaintFrame {') + ';'
    # In the baseline these fixture fields are unused by the actual production body.
    if 'sourceContextId' not in frame:
        frame = frame.replace('AcceptedCaretRect activeCaret;', '''
        uint64_t ownedMirrorBindingEpoch=0, ownedMirrorDeclaredBindingEpoch=0, ownedNodeId=0;
        int64_t ownedResourceId=-1, sourceContextId=0; uint32_t ownedNodeKind=0;
        const char *textFailureReason=nullptr; AcceptedCaretRect activeCaret;''')
    helpers = fn('static bool cjguiOhosCanReuseEditingTypography(')
    if 'enum class OwnedFrameTextSource' in s:
        helpers += '\n' + fn('enum class OwnedFrameTextSource') + ';\n'
        helpers += fn('static OwnedFrameTextSource cjguiOhosOwnedFrameTextSource(')
    helpers += fn('static int64_t cjguiOhosFrozenPaintOwnerVersion(')
    redraw = s[s.index(a2.REDRAW_START):]
    redraw = redraw[:redraw.index(a2.REDRAW_END) + len(a2.REDRAW_END)]
    publish = fn('void publishPaintedLayout(TextPaintFrame &frame)')
    code = r'''
#include <algorithm>
#include <atomic>
#include <cassert>
#include <chrono>
#include <cstdint>
#include <cstdio>
#include <deque>
#include <map>
#include <memory>
#include <mutex>
#include <string>
#include <vector>
#define RLOGI(...) ((void)0)
#define RLOGW(...) ((void)0)
constexpr size_t kMaxSessions=1,kPresentationLeaseMax=64,kPresentationLeaseNodeTextMax=16384,kPresentationLeaseNodeRunsMax=1024,kPresentationLeaseTotalUnitsMax=262144;
enum { kKindText=3,kKindButton=4,kKindTextInput=5,kKindIntegerInput=6,kKindBooleanInput=7,kKindMultiline=10 };
enum CjguiInternalRendererStatus { CJGUI_INTERNAL_RENDERER_OK=0,CJGUI_INTERNAL_RENDERER_INVALID_SESSION=1,CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR=2 };
constexpr int CJGUI_INTERNAL_RENDERER_PROXY_RESTORE_ADOPTED=1;
enum OH_Drawing_ErrorCode { OH_DRAWING_SUCCESS, OH_DRAWING_ERROR };
struct OH_Drawing_Typography { std::string text; };
int builds=0,destroys=0,flushes=0,carets=0,selectionPaints=0; bool failLayout=false;
std::string visible,drawn;
void OH_Drawing_DestroyTypography(OH_Drawing_Typography*p){if(p){++destroys;delete p;}}
struct OH_Drawing_Canvas{}; struct OH_Drawing_Surface{}; struct OH_Drawing_Brush{};struct OH_Drawing_Rect{};struct OH_Drawing_Point{};
void OH_Drawing_CanvasSave(OH_Drawing_Canvas*){} void OH_Drawing_CanvasRestore(OH_Drawing_Canvas*){}
OH_Drawing_ErrorCode OH_Drawing_SurfaceFlush(OH_Drawing_Surface*){++flushes;visible=drawn;return OH_DRAWING_SUCCESS;}
void OH_Drawing_TypographyPaint(OH_Drawing_Typography*t,OH_Drawing_Canvas*,double,double){drawn=t->text;}
double OH_Drawing_TypographyGetHeight(OH_Drawing_Typography*){return 10;}
double OH_Drawing_TypographyGetLongestLine(OH_Drawing_Typography*){return 10;}
double OH_Drawing_TypographyGetMaxWidth(OH_Drawing_Typography*){return 377;}
size_t OH_Drawing_TypographyGetLineCount(OH_Drawing_Typography*){return 1;}
double OH_Drawing_TypographyGetAlphabeticBaseline(OH_Drawing_Typography*){return 8;}
OH_Drawing_Brush*OH_Drawing_BrushCreate(){return new OH_Drawing_Brush;}
void OH_Drawing_BrushSetAntiAlias(OH_Drawing_Brush*,bool){}void OH_Drawing_BrushSetColor(OH_Drawing_Brush*,uint32_t){}
void OH_Drawing_CanvasAttachBrush(OH_Drawing_Canvas*,OH_Drawing_Brush*){}void OH_Drawing_CanvasDetachBrush(OH_Drawing_Canvas*){}
void OH_Drawing_BrushDestroy(OH_Drawing_Brush*p){delete p;}
OH_Drawing_Rect*OH_Drawing_RectCreate(double,double,double,double){return new OH_Drawing_Rect;}
void OH_Drawing_CanvasDrawRect(OH_Drawing_Canvas*,OH_Drawing_Rect*){++carets;}void OH_Drawing_RectDestroy(OH_Drawing_Rect*p){delete p;}
OH_Drawing_Point*OH_Drawing_PointCreate(double,double){return new OH_Drawing_Point;}
void OH_Drawing_PointDestroy(OH_Drawing_Point*p){delete p;}void OH_Drawing_CanvasDrawCircle(OH_Drawing_Canvas*,OH_Drawing_Point*,double){}
struct CjguiInternalRendererComposableNode {
 uint64_t nodeId=107,projectionVersion=9,acceptedBindingEpoch=5; int64_t resourceId=1,x=0,y=0,width=377,height=400;
 uint32_t nodeKind=kKindMultiline,isInteractive=1,isReadOnly=0,preservesActiveLocalText=0,fontWeight=400;
 double fontSize=16,textRed=1,textGreen=1,textBlue=1,textAlpha=1;
};
struct OhosTextStyleRun{bool selectionBackgroundOnly=false;uint32_t start=0,end=0;double bgRed=0,bgGreen=0,bgBlue=0,bgAlpha=0;};
struct SceneNode{CjguiInternalRendererComposableNode pod;std::string value="OLD";std::vector<OhosTextStyleRun>textStyleRuns;};
struct PaintedSelectionHandles{
 bool valid=false,startVisible=false,endVisible=false;uint64_t session=0,nodeId=0,binding=0,ticket=0,projection=0,generation=0,geometryRevision=0;
 int64_t resource=-1,context=0;uint32_t kind=0,start=0,end=0;std::u16string text;
 double startX=0,startY=0,endX=0,endY=0,startLineY=0,endLineY=0;
};
%CARET%
%LAYOUT%
%FRAME%
struct Session{
 bool inUse=true,editing=true,editingContextLive=true,editorRetired=false,previewActive=false,markedActive=false,rangeEditDeltaRequested=true;
 bool ownedTextSessionEnabled=true,caretBlinkResetPending=true,caretBlinkVisible=true;
 bool selectionIntentConfirmed=true;
 struct ProxyRestoreRequest {bool armed=false,awaitingAck=false,platformInstalled=false;uint64_t requestId=0;uint32_t observedStart=0,observedEnd=0;}proxyRestore;
 struct ProxyRestoreTerminal {uint64_t requestId=0;int code=0;std::string reason;bool platformInstalled=false;uint32_t observedStart=0,observedEnd=0;};
 std::deque<ProxyRestoreTerminal>proxyRestoreTerminals;
 uint64_t token=1,editingNodeId=107,ownedTextSessionNodeId=107,ownedTextSessionBindingEpoch=5,acceptedPaintTicketId=10,acceptedProjectionVersion=9;
 int64_t editingResourceId=1,ownedTextSessionResourceId=1,editingContextId=16,editingMirrorOwnerVersion=1;
 uint32_t editingNodeKind=kKindMultiline,ownedTextSessionNodeKind=kKindMultiline,selStartUtf16=0,selEndUtf16=0,caretUtf16=0;
 int32_t caretAffinity=0;std::u16string editingText=u"NATIVE POSTIMAGE";std::vector<SceneNode>accepted{SceneNode{}};
 struct OwnedMirrorDeclaration{bool valid=true;std::u16string text=u"OLD";int64_t ownerContentVersion=1;uint64_t bindingEpoch=5,declaredBindingEpoch=5;}ownedMirrorAccepted;
 AcceptedCaretRect activeCaret;PaintedSelectionHandles selectionHandles;
};
struct {std::mutex lock;Session sessions[kMaxSessions];} g_sessions;
Session*lookupSessionLocked(uint64_t t){return t==1?&g_sessions.sessions[0]:nullptr;}
std::u16string composedBuffer(const Session&s){return s.previewActive||s.markedActive?u"COMPOSITION":s.editingText;}
std::u16string utf8ToUtf16(const std::string&s){return std::u16string(s.begin(),s.end());}
std::string utf16ToUtf8(const std::u16string&s){return std::string(s.begin(),s.end());}
std::string displayTextForNode(const SceneNode&n){return n.value;}
bool isEditableTextKind(uint32_t k){return k==kKindMultiline||k==kKindTextInput;}
bool cjguiOhosTextIntersectsClip(const CjguiInternalRendererComposableNode&){return true;}
bool pointInsideClips(const CjguiInternalRendererComposableNode&,double,double){return true;}
uint32_t packColor(double,double,double,double){return 0;}
uint64_t textWorkFingerprint(const std::string&){return 0;}
struct{int(*foregroundLevel)()=nullptr;}g_ingress;
struct RedrawJob {};int queuedRedraws=0;
struct{bool postIfRunning(std::shared_ptr<RedrawJob>){++queuedRedraws;return true;}}g_render;
%DECL%
%HELPERS%
%FEEDBACK_WAKE%
%CONSUME%
struct Renderer{
 struct Measured {OH_Drawing_Typography*typography=nullptr;double height=10,longestLine=0,maxWidth=377;size_t lineCount=1;double alphabeticBaseline=8;};
 struct TextGeometry{double originX=0,originY=0,lineHeight=10;};
 TextGeometry computeTextGeometry(double,double,double,uint32_t,const Measured&,double){return {};}
 bool caretRectFor(OH_Drawing_Typography*,uint32_t,const std::u16string&,int32_t,double&x,double&t,double&b){x=1;t=0;b=10;return true;}
 void drawSelectionBoxes(OH_Drawing_Canvas*,OH_Drawing_Typography*,uint32_t,uint32_t,const TextGeometry&,uint32_t=0){++selectionPaints;}
 Measured layoutTextStyled(const std::string&text,double,uint32_t,double,bool,uint32_t,const OhosTextStyleRun*,size_t){++builds;return {failLayout?nullptr:new OH_Drawing_Typography{text}};}
 std::unique_ptr<PaintedTextLayout>lastPaintLayout;std::map<uint64_t,std::unique_ptr<PaintedTextLayout>>publishedPresentationLease;
 uint64_t renderEpoch=1,boundGeneration=1,permitGeometryRevision=1,textPaintSerial=0,textLayoutsBuilt=0,textLayoutInputBytes=0,redrawFrames=0;
 void*boundWindow=(void*)1;int surfaceW=1320,surfaceH=2622;double surfaceDensity=3.5;bool paintedLayoutUsable=false;
 OH_Drawing_Surface *surface=nullptr;OH_Drawing_Canvas *canvas=nullptr;
 uint64_t lastFrameSession=1,lastFrameTicket=10,lastProjectionVersion=9,lastFrameMirrorBindingEpoch=5,lastFrameMirrorDeclaredBindingEpoch=5,lastFrameOwnedNodeId=107;
 int64_t lastFrameMirrorOwnerVersion=1,lastFrameOwnedResourceId=1,lastFrameSourceContextId=16;uint32_t lastFrameOwnedNodeKind=kKindMultiline;
 bool lastFrameMirrorValid=true;std::u16string lastFrameMirrorText=u"OLD";std::vector<SceneNode>lastNodes{SceneNode{}};
 bool leaseValid(uint64_t){return true;}bool geometryMatches(void*,uint64_t,int,int,uint64_t){return true;}void teardownSurface(bool){}void invalidatePaintedLayout(uint64_t){}
 bool applyClipChain(OH_Drawing_Canvas*,const CjguiInternalRendererComposableNode&){return true;}
 void drawFill(OH_Drawing_Canvas*,const CjguiInternalRendererComposableNode&){}void drawNodeImage(OH_Drawing_Canvas*,const SceneNode&){}void drawBorder(OH_Drawing_Canvas*,const CjguiInternalRendererComposableNode&){}
 uint64_t activePresentationDragTarget(uint64_t){return 0;}void planPresentationLeaseReservation(const std::vector<SceneNode>&,TextPaintFrame&){}
 %LEASEUNITS%
 %DRAW%
 %PUBLISH%
 struct PresentStub {int status=0; void finish(int rc){status=rc;}};
 void presentTail(PresentStub *job,TextPaintFrame &paintFrame){%PRESENTTAIL%
   OH_Drawing_SurfaceFlush(surface);publishPaintedLayout(paintFrame);
 }
 void redraw(){%REDRAW%}
};
int main(){
 auto &s=g_sessions.sessions[0];Renderer r;
 r.redraw();assert(visible=="OLD"&&"Present must paint its frozen source, never a later native postimage");
 assert(builds==1&&!s.activeCaret.valid&&selectionPaints==0);
 auto*old=r.lastPaintLayout->typography.get();int before=flushes;
 s.ownedTextSessionBindingEpoch=6;s.editingText=u"WRONG";r.redraw();
 assert(flushes==before&&r.lastPaintLayout->typography.get()==old&&visible=="OLD");
 s.ownedTextSessionBindingEpoch=5;s.acceptedPaintTicketId=11;r.redraw();assert(flushes==before);
 s.acceptedPaintTicketId=10;
 s.ownedTextSessionBindingEpoch=5;s.editingText=u"OLD";s.editingMirrorOwnerVersion=2;r.redraw();
 assert(!s.activeCaret.valid&&builds==1&&"same bytes of another owner cannot publish stale interaction");
 s.editingMirrorOwnerVersion=1;s.editingContextId=17;s.selStartUtf16=0;s.selEndUtf16=2;s.caretUtf16=2;
 queueOwnedInteractionFeedbackIfCurrentLocked(&s);assert(queuedRedraws==1&&"accepted same-context synchronization must wake feedback before the next blink");r.redraw();
 assert(builds==1&&s.activeCaret.valid&&s.selectionHandles.valid&&selectionPaints==1);
 assert(r.lastPaintLayout->typography.get()==old&&"restore -> redraw reuses the exact text layout");
 s.proxyRestore={false,true,true,42,0,2};int consumed=0;
 cjgui_internal_renderer_consume_proxy_restore_ticket(1,41,0,2,&consumed);assert(consumed==0&&queuedRedraws==1);
 cjgui_internal_renderer_consume_proxy_restore_ticket(1,42,0,2,&consumed);assert(consumed==1&&queuedRedraws==2);r.redraw();assert(builds==1&&s.activeCaret.valid);
 s.markedActive=true;r.redraw();assert(visible=="COMPOSITION"&&builds==2);s.markedActive=false;
 // Changed inputs require new layout, not an invalid cache hit.
 s.editingText=u"OLD";r.redraw();int base=builds;
 auto changed=[&]{r.redraw();assert(builds==++base);};
 r.lastNodes[0].pod.fontSize=18;changed();r.lastNodes[0].pod.fontWeight=500;changed();
 r.lastNodes[0].pod.textRed=.5;changed();r.lastNodes[0].pod.width=376;changed();
 r.surfaceDensity=2;changed();r.permitGeometryRevision=2;changed();r.boundGeneration=2;changed();
 r.lastNodes[0].textStyleRuns.push_back({});changed();
 // Mandatory layout failure is a frame failure, with old resources still usable.
 old=r.lastPaintLayout->typography.get();before=flushes;failLayout=true;r.redraw();
 assert(flushes==before&&r.lastPaintLayout->typography.get()==old&&s.activeCaret.valid);
 failLayout=false;r.redraw();assert(flushes==before+1);
 Renderer::PresentStub job;TextPaintFrame rejected;rejected.textFailureReason="required_text_layout_failed";
 before=flushes;old=r.lastPaintLayout->typography.get();r.presentTail(&job,rejected);
 assert(job.status==2&&flushes==before&&r.lastPaintLayout->typography.get()==old);
 r.lastNodes[0].textStyleRuns.clear();r.redraw();base=builds;
 r.lastFrameSourceContextId=18;changed();
 s.ownedTextSessionBindingEpoch=6;r.lastFrameMirrorBindingEpoch=6;r.lastFrameMirrorDeclaredBindingEpoch=6;changed();
 s.ownedTextSessionEnabled=false;r.lastFrameOwnedNodeId=0;r.lastFrameMirrorValid=false;s.editingText=u"NONOWNED";
 r.redraw();assert(visible=="NONOWNED"&&s.activeCaret.valid);
 puts("PASS actual draw/Flush/publish/restore/redraw: frozen owned text, mismatch refusal, composition, complete keys, failure preserves old, restored interaction + reuse");
}
'''
    present=s[s.index(a2.PRESENT_COMMENT):]
    present=present[:present.index(a2.PRESENT_FLUSH_DECL)]
    pieces={'CARET':fn('struct AcceptedCaretRect {')+';','LAYOUT':layout,'FRAME':frame,
            'DECL':fn('static const Session::OwnedMirrorDeclaration *ownedMirrorDeclarationLocked('),
            'HELPERS':helpers,'LEASEUNITS':fn('static size_t leaseTableUnits('),
            'DRAW':fn('void drawNodeText('),'PUBLISH':publish,'REDRAW':redraw,'PRESENTTAIL':present}
    pieces['FEEDBACK_WAKE']=fn('static void queueOwnedInteractionFeedbackIfCurrentLocked(') if 'static void queueOwnedInteractionFeedbackIfCurrentLocked(' in s else 'void queueOwnedInteractionFeedbackIfCurrentLocked(Session*){}'
    pieces['CONSUME']=fn('CjguiInternalRendererStatus cjgui_internal_renderer_consume_proxy_restore_ticket(')
    for k,v in pieces.items():code=code.replace('%'+k+'%',v)
    return code

if __name__=='__main__':
    ap=argparse.ArgumentParser();ap.add_argument('--source',type=Path,default=a2.SOURCE);args=ap.parse_args()
    with tempfile.TemporaryDirectory(prefix='h-frozen-frame-') as tmp:
        p=Path(tmp);(p/'main.cpp').write_text(build(args.source))
        subprocess.run(['clang++','-std=c++17',str(p/'main.cpp'),'-o',str(p/'main')],check=True)
        raise SystemExit(subprocess.run([str(p/'main')]).returncode)

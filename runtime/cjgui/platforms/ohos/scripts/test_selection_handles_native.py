#!/usr/bin/env python3
"""Compile the production gesture/range chain; SDK Paint geometry is tested separately."""
import subprocess
import tempfile
import unittest
from pathlib import Path
import test_touch_gesture_native as touch

PRELUDE = touch.MAIN_ORIGINAL.split('int main() {')[0]
MAIN = PRELUDE + r'''
#define CHECK(c,n) do { if(!(c)){fprintf(stderr,"FAIL %d: %s\n",n,#c);return n;} }while(0)
static void setup(Session &s,bool focused=true){
  addScrollScene(s);s.accepted[2].pod.nodeKind=kKindMultiline;s.accepted[2].pod.height=100;
  s.accepted[2].value="first\nsecond\nthird";
  if(focused){beginEditingOnNodeLocked(s,s.accepted[2]);s.caretUtf16=s.selStartUtf16=s.selEndUtf16=6;}
}
static void overdue(Session &s){
  s.gesture.pressBeginMs=std::chrono::duration_cast<std::chrono::milliseconds>(
    std::chrono::steady_clock::now().time_since_epoch()).count()-500;
  s.textPressBeginMs=s.gesture.pressBeginMs;
}
static void facts(Session &s){
  s.selStartUtf16=6;s.selEndUtf16=s.caretUtf16=12;recordHumanSelectionAnchorLocked(s,"fixture_word");
  auto &h=s.selectionHandles;h.valid=h.startVisible=h.endVisible=true;
  h.session=s.token;h.ticket=s.acceptedPaintTicketId;h.nodeId=s.editingNodeId;h.resource=s.editingResourceId;
  h.kind=s.editingNodeKind;h.context=s.editingContextId;h.projection=s.editingProjectionVersion;
  h.generation=s.surfaceGeneration;h.geometryRevision=s.surfaceGeometryRevision;
  h.binding=s.accepted[2].pod.acceptedBindingEpoch;h.text=s.editingText;h.start=6;h.end=12;
  h.startX=60;h.startY=310;h.startLineY=320;h.endX=200;h.endY=370;h.endLineY=360;
}
static bool apply(Session &s,uint32_t mode,uint32_t caret,uint32_t lo=0,uint32_t hi=0){
  s.editingTapPending=false;
  return applySelectionHitLocked(s,s.selectionOperationGeneration,mode,caret,1,lo,hi);
}
int main(int argc,char **argv){
  if(argc!=2)return 2;std::string test=argv[1];Session s;
  if(test=="long"||test=="first_long"||test=="hold"||test=="pending_move"){
    setup(s,test!="first_long");touch(s,CJGUI_OHOS_TOUCH_BEGIN,42,90,320);overdue(s);
    if(test=="hold"||test=="pending_move"){
      auto now=std::chrono::duration_cast<std::chrono::milliseconds>(std::chrono::steady_clock::now().time_since_epoch()).count();
      CHECK(requestLongPressWordLocked(s,now),180);
      if(test=="pending_move"){
        touch(s,CJGUI_OHOS_TOUCH_UPDATE,42,140,350);touch(s,CJGUI_OHOS_TOUCH_END,42,155,355);
        CHECK(s.selectionDrag.moved&&s.selectionDrag.terminal&&s.selectionDrag.lastY==355,179);
      }
    }else touch(s,CJGUI_OHOS_TOUCH_END,42,90,320);
    CHECK(!(s.selStartUtf16==0&&s.selEndUtf16==s.editingText.size()),181);
    CHECK(s.editingTapPending&&s.editingHitMode==1&&s.selectionDrag.active,182);
    CHECK(apply(s,1,9,6,12),183);
    CHECK(s.selStartUtf16==6&&s.selEndUtf16==12&&s.editingText==u"first\nsecond\nthird",184);
    CHECK(s.humanAnchor.start16==6&&s.humanAnchor.end16==12,185);
    if(test=="hold"){
      CHECK(s.gesture.phase==Session::TouchGesture::kGestureSelectionDrag,186);
      touch(s,CJGUI_OHOS_TOUCH_END,42,90,320);
      CHECK(!s.selectionDrag.active&&!s.editingTapPending&&s.selStartUtf16==6&&s.selEndUtf16==12,187);
    }else if(test=="pending_move"){
      CHECK(s.editingTapPending&&s.editingHitMode==2&&s.selectionDrag.terminal,188);
      CHECK(apply(s,2,15),189);CHECK(s.selStartUtf16==6&&s.selEndUtf16==15&&!s.selectionDrag.active,190);
    }else CHECK(!s.selectionDrag.active&&!s.gesture.active,191);
    if(test=="first_long")CHECK(countKind(s,kEvFocus)==1,192);
  }else if(test=="start_drag"||test=="end_reverse"||test=="cancel"||test=="new_begin"){
    setup(s);facts(s);const bool start=test!="end_reverse";
    touch(s,CJGUI_OHOS_TOUCH_BEGIN,43,start?60:200,start?310:370);
    CHECK(s.gesture.phase==Session::TouchGesture::kGestureSelectionDrag&&s.selectionDrag.anchorReady,193);
    CHECK(s.selectionDrag.anchor==(start?12:6),194);
    auto op=s.selectionOperationGeneration;auto seq=s.humanAnchorSeq;
    touch(s,CJGUI_OHOS_TOUCH_UPDATE,43,75,335);
    CHECK(s.editingTapPending&&s.editingHitMode==2&&!s.selectionDrag.terminal,195);
    CHECK(s.editingTapY==(start?45:25),196); // grip offset maps to glyph line centre
    CHECK(apply(s,2,start?8:2),197);
    CHECK(s.humanAnchorSeq==seq,198); // MOVE does not install hundreds of anchors
    CHECK(s.selStartUtf16==(start?8:2)&&s.selEndUtf16==(start?12:6),199);
    if(test=="cancel"){
      touch(s,CJGUI_OHOS_TOUCH_UPDATE,43,110,350); // unresolved last MOVE must not be invented at CANCEL
      touch(s,CJGUI_OHOS_TOUCH_CANCEL,43,120,360);
      CHECK(!s.selectionDrag.active&&!s.editingTapPending&&!s.gesture.active,200);
      CHECK(s.selStartUtf16==8&&s.selEndUtf16==12&&s.humanAnchorSeq==seq+1,201);
      touch(s,CJGUI_OHOS_TOUCH_END,43,160,390);CHECK(s.selStartUtf16==8&&s.selEndUtf16==12,202);
    }else{
      touch(s,CJGUI_OHOS_TOUCH_END,43,160,390);
      CHECK(s.selectionDrag.terminal&&s.editingTapPending&&!s.gesture.active,203);
      CHECK(s.editingTapY==(start?100:80),204); // final END coordinate replaces MOVE
      if(test=="new_begin"){
        touch(s,CJGUI_OHOS_TOUCH_BEGIN,44,300,320);
        CHECK(!applySelectionHitLocked(s,op,2,3,1,0,0),205);
        CHECK(!applySelectionHitLocked(s,op,0,3,1,0,0),206);
        CHECK(s.selStartUtf16==8&&s.selEndUtf16==12,207);
      }else{
        CHECK(apply(s,2,start?3:2),208);
        CHECK(s.selStartUtf16==(start?3:2)&&s.selEndUtf16==(start?12:6),209);
        CHECK(!s.selectionDrag.active&&s.humanAnchorSeq==seq+1,210);
      }
    }
    CHECK(s.editingText==u"first\nsecond\nthird",211);
  }else if(test.rfind("stale_",0)==0){
    setup(s);facts(s);
    if(test=="stale_ticket")s.selectionHandles.ticket+=1;
    if(test=="stale_context")s.selectionHandles.context+=1;
    if(test=="stale_binding")s.selectionHandles.binding+=1;
    if(test=="stale_projection")s.selectionHandles.projection+=1;
    if(test=="stale_geometry")s.selectionHandles.geometryRevision+=1;
    if(test=="stale_surface")s.selectionHandles.generation+=1;
    if(test=="stale_text")s.selectionHandles.text=u"other";
    if(test=="stale_range")s.selectionHandles.end=13;
    if(test=="stale_preview")s.previewActive=true;
    if(test=="stale_retired")s.editorRetired=true;
    if(test=="stale_hidden")s.selectionHandles.startVisible=false;
    touch(s,CJGUI_OHOS_TOUCH_BEGIN,43,60,310);
    CHECK(s.gesture.phase!=Session::TouchGesture::kGestureSelectionDrag&&!s.selectionDrag.active,212);
  }else if(test.rfind("job_",0)==0){
    setup(s);facts(s);touch(s,CJGUI_OHOS_TOUCH_BEGIN,43,60,310);auto op=s.selectionOperationGeneration;
    if(test=="job_context")s.editingContextId+=1;
    if(test=="job_binding")s.accepted[2].pod.acceptedBindingEpoch+=1;
    if(test=="job_projection")s.editingProjectionVersion+=1;
    if(test=="job_geometry")s.surfaceGeometryRevision+=1;
    if(test=="job_surface")s.surfaceGeneration+=1;
    if(test=="job_text")s.editingText+=u"changed";
    if(test=="job_preview")s.previewActive=true;
    if(test=="job_retired")s.editorRetired=true;
    CHECK(!applySelectionHitLocked(s,op,2,3,1,0,0),213);
    CHECK(s.selStartUtf16==6&&s.selEndUtf16==12,214);
    s.selectionDrag.terminal=false;cancelTouchGestureLocked(s);CHECK(!s.selectionDrag.active,215);
  }else if(test=="short"){
    setup(s);touch(s,CJGUI_OHOS_TOUCH_BEGIN,42,90,320);touch(s,CJGUI_OHOS_TOUCH_END,42,90,320);
    CHECK(s.editingHitMode==0&&s.editingTapPending&&!s.selectionDrag.active,216);
  }else if(test=="scroll"){
    setup(s);touch(s,CJGUI_OHOS_TOUCH_BEGIN,42,90,320);touch(s,CJGUI_OHOS_TOUCH_UPDATE,42,90,260);
    touch(s,CJGUI_OHOS_TOUCH_END,42,90,250);
    int64_t whole=0;for(auto &e:s.events)if(e.kind==kEvScroll)whole+=e.scrollDelta;
    CHECK(whole==70&&countTakeover(s)==1&&countScrollDelta(s)==1&&!s.editingTapPending,217);
    CHECK(s.editingText==u"first\nsecond\nthird"&&countKind(s,kEvFocus)==0,218);
  }else return 3;
  return 0;
}
'''
CASES = ['long','first_long','hold','pending_move','start_drag','end_reverse','cancel','new_begin','short','scroll']
CASES += ['stale_'+n for n in ['ticket','context','binding','projection','geometry','surface','text','range','preview','retired','hidden']]
CASES += ['job_'+n for n in ['context','binding','projection','geometry','surface','text','preview','retired']]

class SelectionHandlesNativeTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.tmp=tempfile.TemporaryDirectory(prefix='ohos-selection-handles-');cls.root=Path(cls.tmp.name)
        cls.source=touch.SOURCE.read_text();cls.binary=cls.compile(cls.source,'production')
    @classmethod
    def tearDownClass(cls):cls.tmp.cleanup()
    @classmethod
    def compile(cls,source,name):
        p=cls.root/(name+'.cpp');p.write_text(touch.build_harness_text(MAIN,source));binary=cls.root/name
        result=subprocess.run(['clang++','-std=c++17','-I',str(touch.SNAPSHOT),'-I',str(touch.SOURCE.parent),str(p),'-o',str(binary)],capture_output=True,text=True)
        if result.returncode:raise AssertionError(result.stderr)
        return binary
    def test_production_word_handles_terminal_and_identity(self):
        for case in CASES:
            with self.subTest(case=case):
                p=subprocess.run([str(self.binary),case],capture_output=True,text=True)
                self.assertEqual(p.returncode,0,p.stderr)
    def test_negative_controls_discriminate(self):
        mutations=[
          ('all','long','s.editingHitMode = 1; s.editingTapPending = true; // replaces BEGIN\'s caret job','s.selStartUtf16=0;s.selEndUtf16=s.editingText.size();s.editingHitMode = 1; s.editingTapPending = true;'),
          ('anchor','start_drag','d.anchorReady = true; d.anchor = start ? h.end : h.start;','d.anchorReady = true; d.anchor = start ? h.start : h.end;'),
          ('operation','new_begin','if (operation != s.selectionOperationGeneration) return false;','if (false) return false;'),
          ('binding','job_binding','drag.binding != 0 && s.accepted[index].pod.acceptedBindingEpoch == drag.binding;','true;'),
        ]
        for name,case,old,new in mutations:
            with self.subTest(name=name):
                self.assertIn(old,self.source);binary=self.compile(self.source.replace(old,new,1),name)
                result=subprocess.run([str(binary),case],capture_output=True,text=True)
                self.assertNotEqual(result.returncode,0,'negative control escaped '+name)

if __name__=='__main__':unittest.main(verbosity=2)

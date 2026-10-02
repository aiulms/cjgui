"""Actual native touch sequence, before any SDK typography result is supplied."""
from pathlib import Path
import subprocess
import tempfile
import unittest
import test_touch_gesture_native as touch

MAIN = touch.MAIN_ORIGINAL.split('int main() {')[0] + r'''
int main(int argc,char **argv){
 if(argc!=2)return 2;Session s;addScrollScene(s);s.accepted[2].pod.nodeKind=kKindMultiline;
 s.accepted[2].pod.height=100;s.accepted[2].value="first\nsecond words\nthird";
 beginEditingOnNodeLocked(s,s.accepted[2]);
 const std::string name=argv[1];const int count=name=="triple"?3:2;
 for(int i=0;i<count;i++){
  const int64_t step=name=="expired"?450000000LL:150000000LL;
  if(i==1&&name=="context")s.editingContextId+=1;
  if(i==1&&name=="binding")s.accepted[2].pod.acceptedBindingEpoch+=1;
  if(i==1&&name=="text")s.editingText+=u"changed";
  if(i==1&&name=="geometry")s.surfaceGeometryRevision+=1;
  if(i==1&&name=="clock"){
   auto nativeTouch=&synthesizeEventsFromRawTouch;
   nativeTouch(s,RawTouchSample{CJGUI_OHOS_TOUCH_BEGIN,90,320,1,2,7,0,43,1150000000LL,1});
   nativeTouch(s,RawTouchSample{CJGUI_OHOS_TOUCH_END,90,320,1,2,7,0,43,1200000000LL,1});
  }else{
   const float x=i==1&&name=="distant"?170:90;
   touchAt(s,CJGUI_OHOS_TOUCH_BEGIN,42+i,x,320,1000000000LL+i*step);
   touchAt(s,CJGUI_OHOS_TOUCH_END,42+i,x,320,1050000000LL+i*step);
  }
 }
 const uint32_t expected=name=="double"?1U:name=="triple"?3U:0U;
 if(!s.editingTapPending||s.editingHitMode!=expected){
  fprintf(stderr,"tap count=%d mode=%u pending=%d\n",count,s.editingHitMode,s.editingTapPending);return 4;
 }
 return 0;
}
'''

class TextMultitapNativeTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.tmp=tempfile.TemporaryDirectory(prefix='ohos-text-multitap-');p=Path(cls.tmp.name)
        (p/'probe.cpp').write_text(touch.build_harness_text(MAIN));cls.binary=p/'probe'
        r=subprocess.run(['clang++','-std=c++17','-I',str(touch.SNAPSHOT),'-I',str(touch.SOURCE.parent),str(p/'probe.cpp'),'-o',str(cls.binary)],capture_output=True,text=True)
        if r.returncode:raise AssertionError(r.stderr)
    @classmethod
    def tearDownClass(cls):cls.tmp.cleanup()
    def test_double_tap_uses_painted_word_hit(self):
        r=subprocess.run([str(self.binary),'double'],capture_output=True,text=True);self.assertEqual(r.returncode,0,r.stderr)
    def test_triple_tap_uses_painted_paragraph_hit(self):
        r=subprocess.run([str(self.binary),'triple'],capture_output=True,text=True);self.assertEqual(r.returncode,0,r.stderr)
    def test_sequence_resets_for_time_distance_clock_or_identity(self):
        for name in ['expired','distant','clock','context','binding','text','geometry']:
            with self.subTest(name=name):
                r=subprocess.run([str(self.binary),name],capture_output=True,text=True);self.assertEqual(r.returncode,0,r.stderr)

if __name__=='__main__':unittest.main(verbosity=2)

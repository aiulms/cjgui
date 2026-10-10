#!/usr/bin/env python3
"""Run the actual reveal entry before native geometry: live gesture owns scroll."""
from pathlib import Path
import subprocess,tempfile,sys
SOURCE=Path(__file__).resolve().parents[1]/'snapshot/src/composable_ui_window.cj'
def run(withdraw=False):
 s=SOURCE.read_text();a=s.index('private func revealEditingCaretIfNeeded(): Unit {');b=s.index('        let caret = internalRendererAcceptedActiveCaretRect',a)
 entry=s[a:b]
 if withdraw:entry=entry.replace('if (pointerCaptureActive) {','if (false) {',1)
 code='''package test
var sceneReads=0
func internalRendererWindowLog(text:String):Unit {}
class Window {
 var pointerCaptureActive=false
 func frozenSceneGeneration():?UInt64 {sceneReads+=1;return None}
 ENTRY
 }
 func call(active:Bool):Unit {pointerCaptureActive=active;revealEditingCaretIfNeeded()}
}
main():Int64 {let w=Window();w.call(true);if(sceneReads!=0){println("FAIL accepted reveal stole active gesture");return 1};w.call(false);if(sceneReads!=1){return 2};println("PASS live capture defers reveal, UP permits shared reveal");return 0}
'''.replace('ENTRY',entry)
 with tempfile.TemporaryDirectory() as t:
  p=Path(t);(p/'a.cj').write_text(code);subprocess.run(['cjc',str(p/'a.cj'),'-Woff','unused','-o',str(p/'a')],check=True);return subprocess.run([str(p/'a')]).returncode
if __name__=='__main__':
 code=run()
 if code:sys.exit(code)
 if '--selftest'in sys.argv:
  red=run(True);print('isolated withdrawal RED:',red);sys.exit(99 if not red else 0)

#!/usr/bin/env python3
from pathlib import Path
import subprocess,tempfile,sys
S=Path(__file__).resolve().parents[1]/'snapshot/src/composable_ui_window.cj'
def run(withdraw=False):
 s=S.read_text();a=s.index('private func restoreFocusAfterProjectionChange(previousScene: CjguiComposableUiScene): Unit {');b=s.index('        if (focusedNodeId < 0)',a);entry=s[a:b]
 if withdraw:entry=entry.replace('if (pointerCaptureActive) {','if (false) {',1)
 code='''package test
var focusCalls=0
class Node {let nodeId=190;let resourceId = -1;let nodeKind=1}
class CjguiComposableUiScene {func nodeForId(id:Int64):Node{return Node()}}
class Window {
 var pointerCaptureActive=false;var currentBinding=true
 let ownedTextSessionNodeId=190;let focusedNodeId=190;let focusedResourceId = -1;let focusedNodeKind=1
 let nativeInputScene=CjguiComposableUiScene()
 func syncOwnedSessionMirrorDeclaration():Unit{}
 func reconcilePointerCaptureAfterProjection():Unit {if(!currentBinding){pointerCaptureActive=false}}
 func ownedAnchorFocusable(n:Node):Bool{return true}
 ENTRY focusCalls+=1
 }
 func call(active:Bool,binding:Bool):Unit {pointerCaptureActive=active;currentBinding=binding;restoreFocusAfterProjectionChange(nativeInputScene)}
}
main():Int64{let w=Window();for(_ in 0..100){w.call(true,true)};if(focusCalls!=0){println("FAIL accepted scrolling reasserted current proxy focus on every frame");return 1};w.call(false,true);w.call(true,false);if(focusCalls!=2){return 2};println("PASS live accepted capture defers projection focus; UP or binding retirement resumes normal path");return 0}
'''.replace('ENTRY',entry)
 with tempfile.TemporaryDirectory()as t:
  p=Path(t);(p/'x.cj').write_text(code);subprocess.run(['cjc',str(p/'x.cj'),'-Woff','unused','-o',str(p/'x')],check=True);return subprocess.run([str(p/'x')]).returncode
if __name__=='__main__':
 c=run()
 if c:sys.exit(c)
 if '--selftest'in sys.argv:
  r=run(True);print('isolated withdrawal RED:',r);sys.exit(99 if not r else 0)

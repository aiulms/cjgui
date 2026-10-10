#!/usr/bin/env python3
"""Run the real synthetic UPDATE dispatch; accepted self progress must retain capture."""
from pathlib import Path
import subprocess
import tempfile
import sys
SOURCE=Path(__file__).resolve().parents[1]/'snapshot/src/composable_ui_window.cj'
def method():
    text=SOURCE.read_text();start=text.index('    private func dispatchEdgeDwellPointerUpdate(')
    end=text.index('    private func pointerEventBindingMatches(',start)
    return text[start:end].replace('private func','public func',1)
def run():
    with tempfile.TemporaryDirectory(prefix='cjgui-dwell-capture-') as temp:
        root=Path(temp)
        code='''package dwell
let CJGUI_COMPOSABLE_UI_EVENT_POINTER_UPDATE: Int64 = 21
func internalRendererWindowLog(text: String): Unit {}
class CjguiComposableUiLayoutNode { let binding = 11u64 }
class CjguiComposableUiEvent {
 let x:Int64
 let y:Int64
 init(n:CjguiComposableUiLayoutNode,k:Int64,s:String,a:Int64,b:Int64,v:Int64,
      pointerX!:Int64=0,pointerY!:Int64=0) {x=pointerX;y=pointerY}
}
class Dispatch { let didApply = true }
class Controller {
 var lastX: Int64 = 0
 var lastY: Int64 = 0
 var revision: Int64 = 3
 var calls: Int64 = 0
 func applyUiEvent(e:CjguiComposableUiEvent): Dispatch { revision += 1;calls += 1;lastX=e.x;lastY=e.y;return Dispatch() }
}
class Scene { let version: Int64 = 7 }
class Window {
 var pointerCaptureActive = true
 var pointerCaptureGestureEpoch = 5u64
 var edgeDwellGestureEpoch = 5u64
 var edgeDwellBindingEpoch = 11u64
 var edgeDwellAwaitingOffset: Int64 = 1
 var edgeDwellAwaitingSolve: Int64 = 3
 var edgeDwellPointerX: Int64 = 358
 var edgeDwellPointerY: Int64 = 457
 var pointerCaptureOwnerVersion: Int64 = 3
 let nativeInputScene = Scene()
 let controller = Controller()
 func currentAcceptedBindingEpoch(n:CjguiComposableUiLayoutNode): UInt64 { return n.binding }
 func acceptedSelectionPointerPoint(n:CjguiComposableUiLayoutNode,x:Int64,y:Int64):(Int64,Int64) {
   return cjguiAcceptedTextDragPoint(x,y,[CjguiComposableUiRect(24,409,331,37),CjguiComposableUiRect(24,458,331,67)])
 }
 func stopEdgeDwell(reason:String): Unit {}
 func pointerCaptureVersionFor(n:CjguiComposableUiLayoutNode): Int64 { return controller.revision }
 func rememberInteraction(n:CjguiComposableUiLayoutNode,k:Int64,a:Int64,b:Int64): Unit {}
METHOD
}
main(): Int64 {
 let w=Window();let n=CjguiComposableUiLayoutNode()
 var failures=0
 let delivered=w.dispatchEdgeDwellPointerUpdate(n)
 if(w.controller.lastX!=354 || w.controller.lastY!=458) {
   println("FAIL static edge resolves gap to retired start fragment");failures+=1
 } else {println("PASS static edge resolves current accepted paragraph gap") }
 if (!delivered || w.pointerCaptureOwnerVersion != w.controller.revision) {
   println("FAIL accepted edge UPDATE leaves old capture revision");failures += 1
 } else { println("PASS accepted edge UPDATE records its own capture progress") }
 w.pointerCaptureActive=false
 let oldCalls=w.controller.calls
 if(w.dispatchEdgeDwellPointerUpdate(n) || w.controller.calls != oldCalls) {
   println("FAIL retired tick reaches new selection");failures += 1
 } else { println("PASS retired gesture refuses old tick") }
 return failures
}
'''.replace('METHOD',method())
        geometry=(SOURCE.parent/'composable_ui_visible_geometry.cj').read_text()
        rect='class CjguiComposableUiRect {let x:Int64;let y:Int64;let width:Int64;let height:Int64;init(x:Int64,y:Int64,w:Int64,h:Int64){this.x=x;this.y=y;width=w;height=h}}'
        code=code.replace('package dwell',geometry.replace('package cjgui','package dwell')+rect)
        (root/'main.cj').write_text(code)
        subprocess.run(['cjc',str(root/'main.cj'),'-Woff','unused','-o',str(root/'test')],check=True)
        return subprocess.run([str(root/'test')]).returncode
if __name__=='__main__':sys.exit(run())

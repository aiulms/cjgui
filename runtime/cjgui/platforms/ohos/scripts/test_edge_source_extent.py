#!/usr/bin/env python3
from pathlib import Path
import tempfile,subprocess,sys
ROOT=Path(__file__).resolve().parents[1]
def block(text,key):
 a=text.index(key);b=text.index('{',a);d=0
 for i in range(b,len(text)):
  d+=(text[i]=='{')-(text[i]=='}')
  if not d:return text[a:i+1]
def run(withdraw=False, lines=False, window=False):
 source=(ROOT/'snapshot/src/composable_ui_visible_geometry.cj').read_text()
 if withdraw:
  if lines or window:
   source=source.replace('min(firstLine.height, viewport.height)','1').replace('min(lastLine.height, viewport.height)','1')
  else:source=source.replace('return min(requested, max(room, 0))','return requested')
 rect=block((ROOT/'snapshot/src/composable_ui.cj').read_text(),'public class CjguiComposableUiRect {')
 if window:
  host=(ROOT/'snapshot/src/composable_ui_window.cj').read_text()
  method=block(host,'    private func acceptedTextEdgeScrollDistance(')
  helper=block(host,'    private func acceptedTextEdgeHasContinuation(') if '    private func acceptedTextEdgeHasContinuation(' in host else ''
  waiting=block(host,'        if (boundedWhole < 0)') if '        if (boundedWhole < 0)' in host else ''
  wait_method='''
 var edgeDwellGeometryDeadline:?MonoTime=None
 var stopped:Int64=0
 func stopEdgeDwell(reason:String):Unit{stopped+=1}
 func waitForGeometry(now:MonoTime):CjguiComposableUiActivityStep{
   let boundedWhole:Int64 = -1
   let target=CjguiComposableUiLayoutNode()
   WAITING
   return CjguiComposableUiActivityStep(true,false)
 }
'''.replace('WAITING',waiting)
  activity=block((ROOT/'snapshot/src/composable_ui.cj').read_text(),'public struct CjguiComposableUiActivityStep {')
  code=source.replace('import std.math.*','import std.math.*\nimport std.collection.*\nimport std.time.*')+rect+'\n'+activity+r'''
let CJGUI_COMPOSABLE_UI_TEXT:Int64=3
var lineStatus:Int32=1
func internalRendererWindowLog(message:String):Unit{}
func internalRendererAcceptedTextLineBands(session:UInt64,scene:UInt64,node:UInt64,binding:UInt64):(Int32,Float64,Float64,Float64,Float64){return (lineStatus,400.0,420.0,440.0,460.0)}
func cjguiFocusVisibleIntersection(b:CjguiComposableUiRect,c:Array<CjguiComposableUiRect>):CjguiComposableUiRect{return b}
class Style {let pointerInteractive=true}
class CjguiComposableUiLayoutNode {
 let nodeId:Int64=25;let nodeKind:Int64=3;let resourceId:Int64=1;let style=Style()
 let bounds=CjguiComposableUiRect(36,100,305,934)
 func clipConstraints():Array<CjguiComposableUiRect>{return []}
}
class FakeSource {func itemCount():Int64{return 10}}
class FakeState {
 var end:Int64=10
 func materializedStart():Int64{return 0}
 func materializedEnd():Int64{return end}
 func retainedVariableCaptureIndex(source:FakeSource):Int64{return 0}
}
class CjguiComposableUiNode {
 let nodeId:Int64=99;let state=FakeState();var virtual:Bool=false
 func children():Array<CjguiComposableUiNode>{return []}
 func variableHeightListSource():?FakeSource{return if(virtual){Some(FakeSource())}else{None}}
 func virtualListState():?FakeState{return if(virtual){Some(state)}else{None}}
}
class CjguiEdgeDwellContainer {
 let nodeId:Int64=99;let visible=CjguiComposableUiRect(12,310,353,153)
}
class FakeScene {func nodes():Array<CjguiComposableUiLayoutNode>{return [CjguiComposableUiLayoutNode()]}}
class Host {
 let nativeInputScene=FakeScene();let renderedRoot=CjguiComposableUiNode();let sessionToken:UInt64=1
 func frozenSceneGeneration():?UInt64{return Some(7u64)}
 func currentAcceptedBindingEpoch(n:CjguiComposableUiLayoutNode):UInt64{return 11u64}
 func edgeDwellViewportContainer(n:CjguiComposableUiLayoutNode):?CjguiEdgeDwellContainer{return Some(CjguiEdgeDwellContainer())}
 METHOD
 HELPER
 WAITER
 func distance(d:Int64,n:Int64):Int64{return acceptedTextEdgeScrollDistance(CjguiComposableUiLayoutNode(),CjguiEdgeDwellContainer(),d,n)}
}
main():Int64 {
 let h=Host()
 if(h.distance(-1,80)!=43 || h.distance(1,200)!=130){println("FAIL actual window still uses 934vp node box instead of actual 20vp text bands");return 21}
 lineStatus=0
 if(h.distance(1,80)!=(-1)){println("FAIL unavailable current geometry must prepare/wait, not use node box");return 22}
 lineStatus=1;h.renderedRoot.virtual=true;h.renderedRoot.state.end=2
 if(h.distance(1,200)!=200){println("FAIL materialized window is not global EOF");return 23}
 h.renderedRoot.state.end=10
 if(h.distance(1,200)!=130){println("FAIL actual last logical row must retain its last text line");return 24}
 let now=MonoTime.now()
 let waiting=h.waitForGeometry(now)
 let waitingAgain=h.waitForGeometry(now+Duration.millisecond*2499)
 let terminal=h.waitForGeometry(now+Duration.millisecond*2501)
 if(waiting.changed || !waiting.active || waitingAgain.changed || !waitingAgain.active || terminal.changed || terminal.active || h.stopped!=1){
   println("FAIL existing activity must keep valid picture, preserve one deadline, and stop boundedly");return 25
 }
 println("PASS actual window entry consumes published line bands; unavailable geometry waits and virtual continuation stays open");return 0
}
'''.replace('METHOD',method).replace('HELPER',helper).replace('WAITER',wait_method)
 elif lines:
  # The old production rule is still callable for the RED; proposed geometry
  # must not turn an absent new API into a mere compile error.
  actual='cjguiAcceptedTextLineEdgeScrollDistance' in source
  call='cjguiAcceptedTextLineEdgeScrollDistance(d,n,v,a,b)' if actual else 'cjguiAcceptedTextEdgeScrollDistance(d,n,v,[a,b])'
  code=source+rect+'''
func distance(d:Int64,n:Int64,v:CjguiComposableUiRect,a:CjguiComposableUiRect,b:CjguiComposableUiRect):Int64 { return CALL }
main():Int64 {
 let v=CjguiComposableUiRect(12,310,353,153)
 let first=CjguiComposableUiRect(36,400,305,20)
 let last=CjguiComposableUiRect(36,440,305,20)
 if(distance(-1,80,v,first,last)!=43){println("FAIL actual 20vp first line must remain fully visible at upper source boundary");return 11}
 if(distance(1,200,v,first,last)!=130){println("FAIL actual 20vp last line must remain fully visible at lower source boundary");return 12}
 let tall=CjguiComposableUiRect(36,300,305,200)
 if(distance(-1,100,v,tall,tall)!=10 || distance(1,100,v,tall,tall)!=37){println("FAIL tall line keeps maximum attainable band, not fixed font or 1vp");return 13}
 let largeFont=CjguiComposableUiRect(36,420,305,37)
 if(distance(-1,80,v,largeFont,largeFont)!=6){return 14}
 let emptyLine=CjguiComposableUiRect(36,400,1,24)
 if(distance(-1,80,v,emptyLine,emptyLine)!=39){return 15}
 let unknown=CjguiComposableUiRect(0,0,0,0)
 if(distance(1,80,v,unknown,unknown)!=0){return 16}
 if(distance(-1,0,v,first,last)!=0){return 17}
 println("PASS actual line heights, both directions, keyboard band, tall/empty/unknown text");return 0
}
'''.replace('CALL',call)
  if withdraw:code=code.replace('min(firstLine.height, viewport.height)','1').replace('min(lastLine.height, viewport.height)','1')
 else:code=source+rect+'''\nmain():Int64 {
 let clip=CjguiComposableUiRect(12,310,353,153)
 let edge=[CjguiComposableUiRect(36,460,305,934)]
 if(cjguiAcceptedTextEdgeScrollDistance(-1,8,clip,edge)!=2){println("FAIL UP layout scrolled outside accepted band");return 1}
 if(cjguiAcceptedTextEdgeScrollDistance(-1,8,clip,[CjguiComposableUiRect(36,462,305,934)])!=0){return 2}
 if(cjguiAcceptedTextEdgeScrollDistance(1,8,clip,[CjguiComposableUiRect(36,-621,305,934)])!=2){return 3}
 if(cjguiAcceptedTextEdgeScrollDistance(-1,8,clip,[CjguiComposableUiRect(36,-621,305,934),CjguiComposableUiRect(36,400,305,60)])!=8){return 4}
 println("PASS common accepted source extent keeps last layout available for real UP");return 0
}\n'''
 with tempfile.TemporaryDirectory() as t:
  p=Path(t);(p/'a.cj').write_text(code);subprocess.run(['cjc',str(p/'a.cj'),'-Woff','unused','-o',str(p/'a')],check=True);return subprocess.run([str(p/'a')]).returncode
if __name__=='__main__':
 lines='--text-lines' in sys.argv;window='--window' in sys.argv
 c=run(lines=lines,window=window)
 if c:sys.exit(c)
 if '--selftest'in sys.argv:
  r=run(True,lines=lines,window=window);print('isolated withdrawal RED:',r);sys.exit(99 if not r else 0)

#!/usr/bin/env python3
"""Production captured-source continuation: geometry advance allowed, owner/binding/UP refused."""
from pathlib import Path
import subprocess,tempfile,sys
P=Path(__file__).resolve().parents[1]/'snapshot/src/composable_ui_window.cj';s=P.read_text()
def block(marker):
 a=s.index(marker);b=s.index('{',a);d=0
 for i in range(b,len(s)):
  d+=(s[i]=='{')-(s[i]=='}')
  if not d:return s[a:i+1]
method=block('    public func extendCapturedPresentationSelection(')
code='''package captured
import std.math.*
class Mirror {var text="abcd";var contentVersion:Int64=3}
class Session {let mirror=Mirror();var writes:Int64=0;var start:Int64 = -1;var end:Int64 = -1;func mirrorSnapshot():Mirror{return mirror};func setSelection16(a:Int64,b:Int64):Unit{writes+=1;start=a;end=b};func markNativeSelectionRestoreRequired():Unit{}}
class Node {let nodeId:Int64=25;let resourceId:Int64=9801;let nodeKind:Int64=3;let value="abcd"}
class Scene {func nodeForId(n:Int64):Node{return Node()}}
class Window {
var pointerCapturePresentationAnchor:?CjguiPresentationHitTicket=None
var pointerCaptureActive=true
let pointerCaptureNode=Node()
let nativeInputScene=Scene()
let session=Session()
var ownedTextSession:?Session=None
let ownedTextSessionNodeId:Int64=25
var textSessionBindingEpoch=7u64
func frozenSceneGeneration():?UInt64{return Some(11u64)}
METHOD
}
TICKET
VERIFY
func hit(pos:Int64,scene:Int64):CjguiPresentationHitTicket{return CjguiPresentationHitTicket(25,pos,"abcd",scene,9801,3,7u64,"abcd",3)}
main():Int64{
var failures=0;let w=Window();w.ownedTextSession=Some(w.session);let a=hit(1,10);let f=hit(3,11);w.pointerCapturePresentationAnchor=Some(a)
if(w.extendCapturedPresentationSelection(25,a,f)[0]!=0 || w.session.start!=1 || w.session.end!=3){println("FAIL geometry-only accepted scroll loses source anchor");failures+=1}else{println("PASS geometry-only scroll keeps fixed source anchor")}
let writes=w.session.writes
w.session.mirror.contentVersion=4
if(w.extendCapturedPresentationSelection(25,a,f)[0]==0 || w.session.writes!=writes){println("FAIL changed owner accepted");failures+=1}else{println("PASS owner progress refuses old source")}
w.session.mirror.contentVersion=3;w.textSessionBindingEpoch=8u64
if(w.extendCapturedPresentationSelection(25,a,f)[0]==0){println("FAIL changed binding accepted");failures+=1}else{println("PASS binding replacement refuses old source")}
w.textSessionBindingEpoch=7u64;w.pointerCaptureActive=false
if(w.extendCapturedPresentationSelection(25,a,f)[0]==0){println("FAIL UP accepts old tick");failures+=1}else{println("PASS UP rejects late tick")}
w.pointerCaptureActive=true
if(w.extendCapturedPresentationSelection(25,hit(2,10),f)[0]==0){println("FAIL different anchor accepted");failures+=1}else{println("PASS captured anchor cannot be substituted")}
if(w.extendCapturedPresentationSelection(25,a,hit(3,10))[0]==0){println("FAIL stale active-end accepted");failures+=1}else{println("PASS active-end requires current accepted layout")}
return failures
}
'''.replace('METHOD',method).replace('TICKET',block('public class CjguiPresentationHitTicket {')).replace('VERIFY',block('public func verifyPresentationHitTicket('))
with tempfile.TemporaryDirectory(prefix='cjgui-captured-selection-') as t:
 p=Path(t);p.joinpath('main.cj').write_text(code);subprocess.run(['cjc',str(p/'main.cj'),'-Woff','unused','-o',str(p/'test')],check=True);sys.exit(subprocess.run([str(p/'test')]).returncode)

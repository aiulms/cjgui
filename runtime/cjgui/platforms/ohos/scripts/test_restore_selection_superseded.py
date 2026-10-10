#!/usr/bin/env python3
"""Production receipt decision: a late installed range cannot replace a newer selection.
The real pending ticket and real window receipt handler are compiled; platform IO
and the owner are minimal stubs. Canonical platform normalization stays allowed.
"""
from pathlib import Path
import subprocess,tempfile,sys
s=(Path(__file__).resolve().parents[1]/'snapshot/src/composable_ui_window.cj').read_text()
def block(marker):
 a=s.index(marker);b=s.index('{',a);d=0
 for i in range(b,len(s)):
  d+=(s[i]=='{')-(s[i]=='}')
  if not d:return s[a:i+1]
pending=block('private class CjguiPendingPlatformRestore {').replace('private class','class',1)
handler=block('    private func onPlatformProxyRestoreReceipt(').replace('private func','func',1)
if '--withdraw-guard' in sys.argv:
 old='if (!pending.refusalRecovery &&';assert handler.count(old)==1
 handler=handler.replace(old,'if (false && !pending.refusalRecovery &&',1)
code='''package receipt
var consumed:Int64=0
let CJGUI_INTERNAL_RENDERER_OK:Int32=0
func internalRendererConsumeProxyRestoreTicket(t:UInt64,r:UInt64,a:Int64,b:Int64):Bool{consumed+=1;return true}
class InternalRendererPumpResult{
 let nodeId=25u64;let resourceId:Int64=9801;let nodeKind=3u32;let recordIndex=0u32
 let projectionVersion=6u64;let acceptedBindingEpoch=7u64;let bindingEpoch=9u64
 let selectionStart=4u32;var selectionEnd=9u32
}
class InternalRendererProxyRestoreTicket{
 let requestId=9u64;let contextId:Int64=2;let contextGeneration=1u64
 let acceptedBindingEpoch=7u64;let acceptedProjectionVersion=6u64
 let canonicalStart:Int64=4;var canonicalEnd:Int64=9
}
class CjguiTextSession{
 var start:Int64=4;var end:Int64=9;var version:Int64=1;var need=true
 func selection16():(Int64,Int64){return(start,end)}
 func canAdoptNativeRestore(e:Int64,m:Int64,v:Int64,a:Int64,b:Int64,r:Bool):Bool{return v==version}
 func confirmProxyRestored(e:Int64,m:Int64,selectionStart16!:Int64,selectionEnd16!:Int64):Bool{return true}
 func adoptNativeSelectionRestored(v:Int64,a:Int64,b:Int64):Bool{start=a;end=b;need=false;return true}
}
class Scene{func nodeForId(n:Int64):Int64{return n}}
PENDING
class Window{
 var pendingPlatformRestore:?CjguiPendingPlatformRestore=None
 var textSessionRestoreFailures:Int64=0;var textSessionRestores:Int64=0
 var refusedRangeTextPending=false;var refusedRangeTextRecoveries:Int64=0
 var ownedRestoreNamedTerminal=false;var lastNativeFailure="";var refreshes:Int64=0
 let sessionToken=1u64;let focusedNodeId:Int64=25;let focusedResourceId:Int64=9801;let focusedNodeKind:Int64=3
 var focusedSelectionStart:Int64=4;var focusedSelectionEnd:Int64=9;var interactionVersion:Int64=0
 var lastAdoptedRestore:(Int64,Int64,Int64,Int64,Int64,Int64,Int64)=(0,0,0,0,0,0,0)
 let nativeInputScene=Scene()
 func requestRefresh():Unit{refreshes+=1}
 func noteOwnedTextSessionRestoreFailure():Unit{textSessionRestoreFailures+=1}
 func refreshPageFocusBookmark(n:Int64):Unit{}
 HANDLER
}
func arm(s:CjguiTextSession,canonicalEnd:Int64):Window{
 let w=Window();let ticket=InternalRendererProxyRestoreTicket();ticket.canonicalEnd=canonicalEnd
 w.pendingPlatformRestore=Some(CjguiPendingPlatformRestore(25,9801,3,6,4,9,1,1,false,1,Some(s),ticket));return w
}
main():Int64{
 var failures=0;consumed=0
 let s=CjguiTextSession();s.end=20;let w=arm(s,9);w.onPlatformProxyRestoreReceipt(InternalRendererPumpResult())
 if(s.end!=20 || w.textSessionRestores!=0 || consumed!=0 || !s.need || w.pendingPlatformRestore.isSome()){
  println("FAIL late receipt overwrites newer selection");failures+=1
 }else{println("PASS newer selection survives old installed receipt")}
 consumed=0;let s2=CjguiTextSession();let w2=arm(s2,8);let e=InternalRendererPumpResult();e.selectionEnd=8u32;w2.onPlatformProxyRestoreReceipt(e)
 if(s2.end!=8 || w2.textSessionRestores!=1 || consumed!=1){println("FAIL canonical normalization rejected");failures+=1}else{println("PASS current requested selection accepts canonical normalization")}
 consumed=0;let s3=CjguiTextSession();s3.version=2;let w3=arm(s3,9);w3.onPlatformProxyRestoreReceipt(InternalRendererPumpResult())
 if(w3.textSessionRestores!=0 || consumed!=0 || !s3.need){println("FAIL old owner receipt adopted");failures+=1}else{println("PASS owner version gate retained")}
 return failures
}
'''.replace('PENDING',pending).replace('HANDLER',handler)
with tempfile.TemporaryDirectory(prefix='cjgui-late-selection-') as temp:
 p=Path(temp);p.joinpath('main.cj').write_text(code)
 subprocess.run(['cjc',str(p/'main.cj'),'-Woff','unused','-o',str(p/'test')],check=True)
 sys.exit(subprocess.run([str(p/'test')]).returncode)

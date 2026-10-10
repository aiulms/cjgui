#!/usr/bin/env python3
"""Real owned selection admission: proxy echoes cannot replace a pending source range."""
from pathlib import Path
import subprocess,tempfile,sys
s=(Path(__file__).resolve().parents[1]/'snapshot/src/composable_ui_window.cj').read_text()
a=s.index('    private func adoptOwnedTextSelection(');b=s.index('{',a);depth=0
for i in range(b,len(s)):
 depth+=(s[i]=='{')-(s[i]=='}')
 if not depth:method=s[a:i+1].replace('private func','func',1);break
if '--withdraw-guard' in sys.argv:
 old='if (current[1] > current[0] &&';assert method.count(old)==1
 method=method.replace(old,'if (false && current[1] > current[0] &&',1)
code='''package echo
let CJGUI_OWNED_SELECTION_NOT_OWNED:Int64=0
let CJGUI_OWNED_SELECTION_ADOPTED:Int64=1
let CJGUI_OWNED_SELECTION_NAMED_STALE:Int64=2
var human=false
func internalRendererTakeHumanSelectionAnchor(t:UInt64,n:Int64,r:Int64,k:Int64,p:Int64,b:Int64,s:Int64,e:Int64):(Int64,Int64){return(if(human){1}else{0},1)}
class CjguiComposableUiLayoutNode{let nodeId:Int64=25;let resourceId:Int64=9801;let nodeKind:Int64=3}
class Mirror{let sourceVersion:Int64=1}
class Session{
 var start:Int64=4;var end:Int64=20;var fresh=true;var need=true
 func contentVersion():Int64{return if(fresh){1}else{2}}
 func mirrorSnapshot():Mirror{return Mirror()}
 func selection16():(Int64,Int64){return(start,end)}
 func needsNativeSelectionRestore():Bool{return need}
 func setSelection16(s:Int64,e:Int64):Unit{start=s;end=e}
 func canAnchorHumanSelection16(s:Int64,e:Int64):Bool{return human}
 func anchorHumanSelection16(q:Int64,s:Int64,e:Int64):Bool{setSelection16(s,e);need=false;return true}
}
class Window{
 let sessionToken=1u64;let ownedTextSessionNodeId:Int64=25;let ownedTextSessionResourceId:Int64=9801
 var ownedTextSession:?Session=None;var refusedRangeTextPending=false
 let refusedRangeTextNodeId:Int64=25;let refusedRangeTextResourceId:Int64=9801;let refusedRangeTextNodeKind:Int64=3
 var staleOwnedSelectionEvents:Int64=0;var humanSelectionAnchorsAdopted:Int64=0
 METHOD
}
main():Int64{
 let s=Session();let w=Window();w.ownedTextSession=Some(s);let n=CjguiComposableUiLayoutNode();var bad=0
 let old=w.adoptOwnedTextSelection(n,4,9,6,7)
 if(s.end!=20 || !s.need || old!=2){println("FAIL stale nonempty proxy echo replaces pending source");bad+=1}else{println("PASS pending nonempty source survives old echo")}
 let same=w.adoptOwnedTextSelection(n,4,20,6,7)
 if(s.end!=20 || !s.need || same!=1){println("FAIL current observation lost");bad+=1}else{println("PASS matching echo remains an observation and holds lock")}
 s.end=4;let initial=w.adoptOwnedTextSelection(n,4,9,6,7)
 if(s.end!=9 || !s.need || initial!=1){println("FAIL initial nonempty observation lost");bad+=1}else{println("PASS initial platform nonempty selection retained")}
 human=true;let nav=w.adoptOwnedTextSelection(n,8,12,6,7)
 if(s.start!=8 || s.end!=12 || s.need || nav!=1){println("FAIL authenticated human navigation refused");bad+=1}else{println("PASS genuine human anchor replaces pending selection")}
 human=false;s.fresh=false;s.need=true;let stale=w.adoptOwnedTextSelection(n,4,9,6,7)
 if(s.start!=8 || s.end!=12 || stale!=2){println("FAIL stale owner observation adopted");bad+=1}else{println("PASS stale owner observation refused")}
 return bad
}
'''.replace('METHOD',method)
with tempfile.TemporaryDirectory(prefix='cjgui-selection-echo-') as tmp:
 p=Path(tmp);p.joinpath('main.cj').write_text(code)
 subprocess.run(['cjc',str(p/'main.cj'),'-Woff','unused','-o',str(p/'test')],check=True)
 sys.exit(subprocess.run([str(p/'test')]).returncode)

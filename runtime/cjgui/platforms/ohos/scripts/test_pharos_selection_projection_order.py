#!/usr/bin/env python3
"""Real preview build branch must select and draw from the same SourceMap candidate.
The surface and owner are small recording stubs; the production branch is verbatim.
"""
from pathlib import Path
import subprocess,tempfile,sys
s=Path('/Users/jiangxuanyang/Desktop/Pharos Mark/apps/pharos_mark_ohos/application/src/pharos_ohos_controller.cj').read_text();a=s.index('        if (this.previewMode) {',s.index('    public func buildUi('));b=s.index('{',a);d=0
for i in range(b,len(s)):
 d+=(s[i]=='{')-(s[i]=='}')
 if not d:branch=s[a:i+1];break
code='''package projection
class Root{let selectionStart:Int64;let selectionEnd:Int64;init(a:Int64,b:Int64){selectionStart=a;selectionEnd=b}}
class Metrics{let minimumWindowWidth:Int64=500}
class Scene{func build(a:String,b:String,c:String,d:String,e:String,f:Bool,availableWidth!:Int64,visual!:Array<Int64>,caretNodeId!:Int64,caretDisplayOffset!:Int64,selectionStart!:Int64,selectionEnd!:Int64,scrollable!:Bool,viewport!:?Int64,note!:String,noteVisible!:Bool):Root{return Root(selectionStart,selectionEnd)}}
class Summary{let undoDepth:Int64=0;let redoDepth:Int64=0}
class Controller{
 let previewMode=true;let viewportWidth:Int64=377;let metrics=Metrics();let scene=Scene();let sourceViewport:Int64=0
 var candidateReady=false;var builds:Int64=0;var drawnFromCandidate=false
 func ensureVisualCandidate():Array<Int64>{candidateReady=true;builds+=1;return [1]}
 func visualDrawStateFromSession():(Int64,Int64,Int64,Int64,Bool){drawnFromCandidate=candidateReady;return (1001,3,1,3,candidateReady)}
 func noteProjection():String{return ""}
 func attachToolbar(r:Root,a:Int64,b:Int64):Unit{}
 func build():Root{
  let narrow=true;let stateLine="";let counts="";let summary=Summary()
 BRANCH
 return Root(-1,-1)
 }
}
main():Int64{let c=Controller();let root=c.build();if(!c.drawnFromCandidate || root.selectionStart!=1 || root.selectionEnd!=3 || c.builds!=1){println("FAIL selection is drawn before its SourceMap candidate is available");return 1};println("PASS selection and fragments consume one SourceMap candidate");return 0}
'''.replace('BRANCH',branch)
with tempfile.TemporaryDirectory(prefix='h-selection-map-order-')as t:
 p=Path(t);p.joinpath('main.cj').write_text(code);subprocess.run(['cjc',str(p/'main.cj'),'-Woff','unused','-o',str(p/'test')],check=True);sys.exit(subprocess.run([str(p/'test')]).returncode)

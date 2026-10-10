#!/usr/bin/env python3
"""Shared background-only declaration and real display-byte admission in OHOS."""
from pathlib import Path
import subprocess,tempfile,sys,re
s=(Path(__file__).resolve().parents[1]/'snapshot/src/composable_ui.cj').read_text()
def block(marker):
 a=s.index(marker);b=s.index('{',a);d=0
 for i in range(b,len(s)):
  d+=(s[i]=='{')-(s[i]=='}')
  if not d:return s[a:i+1]
code='''package decoration
public class CjguiComposableUiColor{let red:Float64;let green:Float64;let blue:Float64;let alpha:Float64;init(r:Float64,g:Float64,b:Float64,a:Float64){red=r;green=g;blue=b;alpha=a}}
%CLASS%
%VALIDATE%
main():Int64{
 var failures=0;let color=CjguiComposableUiColor(0.3,0.5,0.8,0.55)
 let ordinary=CjguiComposableUiTextStyleRun(0,6,26.0,700,"system",0.1,0.1,0.1,1.0)
 let background=CjguiComposableUiTextStyleRun.selectionBackground(0,6,color)
 if(!background.encoded().endsWith(":1") || cjguiSelectionBackgroundRunsRejection("中文",[ordinary,background]).isSome()){println("FAIL tagged overlapping declaration refused");failures+=1}else{println("PASS tagged background and ordinary font keep separate attributes")}
 if(cjguiSelectionBackgroundRunsRejection("中文",[CjguiComposableUiTextStyleRun.selectionBackground(1,6,color)]).isNone()){println("FAIL split scalar accepted");failures+=1}else{println("PASS actual UTF-8 scalar boundary enforced")}
 if(cjguiSelectionBackgroundRunsRejection("中文",[CjguiComposableUiTextStyleRun.selectionBackground(0,7,color)]).isNone()){println("FAIL old display range accepted");failures+=1}else{println("PASS current display bounds enforced")}
 if(cjguiSelectionBackgroundRunsRejection("中文",[CjguiComposableUiTextStyleRun.selectionBackground(0,6,CjguiComposableUiColor(2.0,0.0,0.0,1.0))]).isNone()){println("FAIL invalid color accepted");failures+=1}else{println("PASS invalid decoration color refused")}
 return failures
}
'''
parts={'CLASS':block('public class CjguiComposableUiTextStyleRun {'),'VALIDATE':block('func cjguiSelectionBackgroundRunsRejection(')};code=re.sub(r'%(CLASS|VALIDATE)%',lambda m:parts[m[1]],code)
with tempfile.TemporaryDirectory(prefix='h-bg-contract-')as t:
 p=Path(t);p.joinpath('main.cj').write_text(code);subprocess.run(['cjc',str(p/'main.cj'),'-Woff','unused','-o',str(p/'test')],check=True);sys.exit(subprocess.run([str(p/'test')]).returncode)

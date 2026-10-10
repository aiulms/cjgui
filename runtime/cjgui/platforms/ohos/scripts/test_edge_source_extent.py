#!/usr/bin/env python3
from pathlib import Path
import tempfile,subprocess,sys
ROOT=Path(__file__).resolve().parents[1]
def block(text,key):
 a=text.index(key);b=text.index('{',a);d=0
 for i in range(b,len(text)):
  d+=(text[i]=='{')-(text[i]=='}')
  if not d:return text[a:i+1]
def run(withdraw=False):
 source=(ROOT/'snapshot/src/composable_ui_visible_geometry.cj').read_text()
 if withdraw:source=source.replace('return min(requested, max(room, 0))','return requested')
 rect=block((ROOT/'snapshot/src/composable_ui.cj').read_text(),'public class CjguiComposableUiRect {')
 code=source+rect+'''\nmain():Int64 {
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
 c=run()
 if c:sys.exit(c)
 if '--selftest'in sys.argv:
  r=run(True);print('isolated withdrawal RED:',r);sys.exit(99 if not r else 0)

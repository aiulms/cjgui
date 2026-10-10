#!/usr/bin/env python3
"""Run production band/rounding code, then withdraw fixes in isolated copies."""
from pathlib import Path
import subprocess
import tempfile
import sys
ROOT=Path(__file__).resolve().parents[1]
def block(text,marker):
    start=text.index(marker);opening=text.index('{',start);depth=0
    for i in range(opening,len(text)):
        depth+=(text[i]=='{')-(text[i]=='}')
        if depth==0:return text[start:i+1]
    raise ValueError(marker)
def native(withdraw=False):
    function=block((ROOT/'host/ohos_renderer.cpp').read_text(),'static void effectiveVisibleBand(')
    if withdraw:
        function=function.replace('if (overlay >= 0) height = std::min(height, std::floor(static_cast<double>(overlay) / density));','')
    code='''#include <atomic>
#include <algorithm>
#include <cmath>
#include <cstdio>
struct Session { double surfaceDensity=3.5;int surfaceWidth=1320,surfaceHeight=2622; };
std::atomic<int> g_keyboardOverlayTopPx{1760};
FUNCTION
int main(){Session s;double w=0,h=0;int fail=0;
effectiveVisibleBand(s,w,h);if(w!=377 || h!=502){++fail;puts("FAIL fractional keyboard band");}else puts("PASS fractional keyboard band");
s.surfaceHeight=1400;effectiveVisibleBand(s,w,h);if(h!=400){++fail;puts("FAIL resized surface double subtraction");}else puts("PASS resized surface intersected once");
g_keyboardOverlayTopPx=-1;s.surfaceHeight=2622;effectiveVisibleBand(s,w,h);if(h!=749){++fail;puts("FAIL keyboard dismissal");}else puts("PASS keyboard dismissal restores surface band");return fail;}
'''.replace('FUNCTION',function)
    with tempfile.TemporaryDirectory(prefix='cjgui-keyboard-band-') as tmp:
        root=Path(tmp);(root/'main.cpp').write_text(code)
        subprocess.run(['clang++','-std=c++17',str(root/'main.cpp'),'-o',str(root/'test')],check=True)
        return subprocess.run([str(root/'test')]).returncode
def cangjie(withdraw=False):
    source=(ROOT/'snapshot/src/composable_ui_visible_geometry.cj').read_text()
    if withdraw:source=source.replace('ceil(bottom)','floor(bottom)')
    rect=block((ROOT/'snapshot/src/composable_ui.cj').read_text(),'public class CjguiComposableUiRect {')
    # Rect methods include a contains helper but have no platform dependencies.
    code=source+rect+'''
main():Int64 {
 let clip=cjguiAcceptedVisibleIntersection(CjguiComposableUiRect(0,0,377,502),CjguiComposableUiRect(10,20,400,700))
 let end=cjguiAcceptedActiveEndRect(10.2,501.2,12.2,502.01)
 var failed=0
 if(clip.x!=10 || clip.y!=20 || clip.width!=367 || clip.y+clip.height!=502){println("FAIL accepted clip intersection");failed+=1}else{println("PASS accepted clip intersection")}
 if(end.y+end.height!=503 || end.y+end.height<=clip.y+clip.height){println("FAIL fractional active bottom is hidden");failed+=1}else{println("PASS fractional active bottom triggers reveal")}
 return failed
}
'''
    with tempfile.TemporaryDirectory(prefix='cjgui-keyboard-round-') as tmp:
        root=Path(tmp);(root/'main.cj').write_text(code)
        subprocess.run(['cjc',str(root/'main.cj'),'-Woff','unused','-o',str(root/'test')],check=True)
        return subprocess.run([str(root/'test')]).returncode
if __name__=='__main__':
    clean=native()+cangjie()
    if clean:sys.exit(clean)
    if '--selftest' in sys.argv:
        n=native(True);c=cangjie(True)
        print(f'isolated withdrawal native={n} caret-rounding={c}')
        if n==0 or c==0:sys.exit(99)

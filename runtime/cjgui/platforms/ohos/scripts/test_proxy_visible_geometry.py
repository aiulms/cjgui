"""Actual native visible-box and common ArkTS geometry; isolated floor withdrawal."""
from pathlib import Path
import json,subprocess,tempfile,sys
from test_ime_range_delta_native import extract_method
p=Path(__file__).resolve().parents[1];s=(p/'host/ohos_renderer.cpp').read_text()
keys=['static void cjguiOhosClipConstraintAt(', 'static bool cjguiOhosAggregateClipRect(',
      'static void effectiveVisibleBand(', 'static bool cjguiOhosProxyVisibleBox(']
pieces='\n'.join(extract_method(s,k) for k in keys)
stub='''#include "cjgui_internal_renderer.h"
#include <atomic>
#include <algorithm>
#include <cmath>
#include <iostream>
struct Session { int32_t surfaceWidth=1320,surfaceHeight=2856;double surfaceDensity=3.5; };
static std::atomic<int32_t> g_keyboardOverlayTopPx{-1};
'''
main='''
int main(){Session s;CjguiInternalRendererComposableNode n{};n.x=11;n.y=67;n.width=333;n.height=7332;
n.clipX=20;n.clipY=70;n.clipWidth=300;n.clipHeight=7300;
double x,y,w,h;for(double d:{1.0,2.0,3.5}){s.surfaceDensity=d;s.surfaceWidth=static_cast<int32_t>(377*d);s.surfaceHeight=static_cast<int32_t>(749*d);
g_keyboardOverlayTopPx=static_cast<int32_t>(424.75*d);
if(!cjguiOhosProxyVisibleBox(s,n,x,y,w,h))return 1;
double bottom=std::floor(static_cast<double>(g_keyboardOverlayTopPx.load())/d);
if(y+h!=bottom || x!=20 || w!=300 || y!=70 || h>=7332)return 2;
std::cout<<"{\\\"density\\\":"<<d<<",\\\"fullWidth\\\":"<<n.width<<",\\\"x\\\":"<<x<<",\\\"y\\\":"<<y<<",\\\"width\\\":"<<w<<",\\\"height\\\":"<<h<<"}\\n";
}g_keyboardOverlayTopPx=60;if(cjguiOhosProxyVisibleBox(s,n,x,y,w,h))return 3;return 0;}
'''
with tempfile.TemporaryDirectory() as t:
    root=Path(t)
    for withdrawn in [False,True]:
        code=pieces
        if withdrawn:code=code.replace('std::floor(static_cast<double>(overlay) / density)','static_cast<double>(overlay) / density')
        cpp=root/('withdraw.cpp' if withdrawn else 'actual.cpp');cpp.write_text(stub+code+main);exe=cpp.with_suffix('')
        subprocess.run(['clang++','-std=c++17','-I'+str(p.parents[1]/'native'),str(cpp),'-o',str(exe)],check=True)
        r=subprocess.run([str(exe)],capture_output=True,text=True)
        if withdrawn:
            assert r.returncode==2,(r.returncode,r.stdout)
            print('isolated fractional bottom withdrawal RED: 2')
        else:
            assert r.returncode==0,(r.returncode,r.stderr)
            facts=[json.loads(line) for line in r.stdout.splitlines()]
    js=root/'geometry.cjs'
    js.write_text('''const fs=require('node:fs');const assert=require('node:assert/strict');const {stripTypeScriptTypes}=require('node:module');
global.FrameCallback=class{};
const source=fs.readFileSync(process.argv[2],'utf8').replace(/^import .*;\\s*$/gm,'');
(async()=>{const {CjguiProxyGeometry}=await import('data:text/javascript,'+encodeURIComponent(stripTypeScriptTypes(source,{mode:'transform'})));
for(const f of JSON.parse(process.argv[3])){const g=new CjguiProxyGeometry(11,f.x,f.y,f.fullWidth,f.width,f.height);
assert(g.valid());assert.equal(g.width,333);assert.equal(g.clipWidth,300);assert.equal(g.x,11);assert.equal(g.y,70);assert.equal(g.height,f.height);}
assert(!new CjguiProxyGeometry(0,0,0,333,300,0).valid());console.log('PASS actual visible band/clip, fractional keyboard floor and vp/layout separation');})();''')
    subprocess.run(['node','--disable-warning=ExperimentalWarning',str(js),str(p/'arkts/cjgui-text-proxy.ets'),json.dumps(facts)],check=True)

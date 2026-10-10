#!/usr/bin/env python3
"""Compile the real text draw entry: fully clipped text must not spend layout slots."""
from pathlib import Path
import ast,re,subprocess,tempfile,sys
root=Path(__file__).resolve().parents[1];s=(root/'host/ohos_renderer.cpp').read_text()
def block(mark):
 a=s.index(mark);b=s.index('{',a);d=0
 for i in range(b,len(s)):
  d+=(s[i]=='{')-(s[i]=='}')
  if not d:return s[a:i+1]
source=(Path(__file__).parent/'test_readback_publish_consistency.py').read_text()
for n in ast.parse(source).body:
 if isinstance(n,ast.Assign) and any(isinstance(t,ast.Name) and t.id=='PROLOGUE' for t in n.targets):prologue=ast.literal_eval(n.value)
helpers=block('static void cjguiOhosClipConstraintAt(')+'\n'+block('static bool cjguiOhosAggregateClipRect(')
if 'static bool cjguiOhosTextIntersectsClip(' in s:helpers+='\n'+block('static bool cjguiOhosTextIntersectsClip(')
a=s.index('    void drawNodeText(');b=s.index('        uint32_t textColor =',a);entry=s[a:b]
if '--withdraw-guard' in sys.argv:
 old='        if (!cjguiOhosTextIntersectsClip(node.pod)) return;\n';assert entry.count(old)==1;entry=entry.replace(old,'')
constants='\n'.join(re.findall(r'^constexpr uint32_t kKind\w+ = \d+;',s,re.M))
code=prologue+helpers+constants+'''\nstruct TextPaintFrame{uint64_t session=1;};using OH_Drawing_Canvas=void;
int layouts=0,visible=0;
'''+entry+'''        if(layouts<64){++layouts;if(node.pod.nodeId==100)++visible;}
}
int main(){
 SceneNode n{};n.pod.nodeKind=kKindText;n.pod.width=100;n.pod.height=30;n.pod.clipWidth=400;n.pod.clipHeight=400;
 TextPaintFrame f;
 for(int i=0;i<100;++i){n.pod.nodeId=i;n.pod.y=-4000+i*30;drawNodeText(nullptr,n,f);}
 n.pod.nodeId=100;n.pod.y=100;drawNodeText(nullptr,n,f);
 if(layouts!=1||visible!=1){std::printf("FAIL invisible text spends finite layout budget layouts=%d visible=%d\\n",layouts,visible);return 1;}
 n.pod.y=400;drawNodeText(nullptr,n,f);
 if(layouts!=1){std::puts("FAIL touching bottom boundary treated visible");return 2;}
 n.pod.y=399;drawNodeText(nullptr,n,f);
 if(layouts!=2){std::puts("FAIL partial intersection discarded");return 3;}
 n.pod.clipConstraintCount=2;n.pod.clip0Width=400;n.pod.clip0Height=400;n.pod.clip1Y=410;n.pod.clip1Width=400;n.pod.clip1Height=20;
 drawNodeText(nullptr,n,f);if(layouts!=2){std::puts("FAIL disjoint accepted clips spend budget");return 4;}
 std::puts("PASS offscreen/edge/partial/disjoint text admission");return 0;
}
'''
with tempfile.TemporaryDirectory(prefix='cjgui-visible-text-') as tmp:
 p=Path(tmp);p.joinpath('test.cpp').write_text(code);subprocess.run(['c++','-std=c++17',str(p/'test.cpp'),'-o',str(p/'test')],check=True);sys.exit(subprocess.run([str(p/'test')]).returncode)

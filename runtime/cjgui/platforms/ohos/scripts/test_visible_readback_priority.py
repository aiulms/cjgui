#!/usr/bin/env python3
"""Real accepted publisher: a bounded geometry report retains currently visible targets."""
from pathlib import Path
import importlib.util,sys
p=Path(__file__).parent/'test_readback_publish_consistency.py';spec=importlib.util.spec_from_file_location('publisher',p);m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
case=r'''
    std::vector<SceneNode> many;
    for(uint64_t i=0;i<100;++i)many.push_back(mkNode(700+i,"offscreen",0,-4000+i*20,100,10,kOhosFaceTextKind));
    auto visible=mkNode(900,"current-visible",0,100,100,30,kOhosFaceTextKind);
    visible.pod.projectionVersion=32;visible.pod.acceptedBindingEpoch=77;many.push_back(visible);
    PendingSettlement vp=p;vp.projectionVersion=32;vp.ticketId=32;vp.frameIndex=32;
    publishSuccess(s2.token,vp,many,32,32);show("VISIBLE",s2.token);
'''
old='    return 0;\n}\n';assert m.MAIN.count(old)==1;m.MAIN=m.MAIN.replace(old,case+old)
s=m.HOST.read_text()
if '--withdraw-guard' in sys.argv:
 old='            if (!g.fullyInvisible) {';assert s.count(old)==1;s=s.replace(old,'            if (false && !g.fullyInvisible) {')
out=m.run_probe(s);row=out['VISIBLE']
if 'truncated=1' not in row or 'G900:current-visible,b=77,p=32' not in row:
 print('FAIL visible accepted target lost behind offscreen truncated prefix');sys.exit(1)
print('PASS visible target keeps exact accepted binding/projection under finite cap')

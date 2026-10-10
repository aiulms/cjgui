#!/usr/bin/env python3
"""One physical drag with a static edge hold, accepted extension, UP stop, exact replacement.
The caller provides a normally focused preview. Each intent is delivered once.
"""
import argparse,importlib.util,json,re,threading,time,sys
from pathlib import Path
HERE=Path(__file__).resolve().parent
spec=importlib.util.spec_from_file_location('h',HERE/'h_source_preview_consumption.py');m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
sys.path.insert(0,str(HERE));import strict_utf16

def dev_ms(row):
 t=re.match(r'\d\d-\d\d (\d\d):(\d\d):(\d\d)\.(\d\d\d)',row)
 return sum(int(x)*w for x,w in zip(t.groups(),(3600000,60000,1000,1))) if t else None

def main():
 p=argparse.ArgumentParser();p.add_argument('--target',required=True);p.add_argument('--port',type=int,default=28991);p.add_argument('--out',required=True);p.add_argument('--observe-only',action='store_true');a=p.parse_args();m.TARGET=a.target
 out=Path(a.out);out.mkdir(parents=True,exist_ok=False);res={'intent_count':1,'pid':m.hdc('shell','pidof',m.BUNDLE).stdout.strip()}
 def rows():return [r for r in m.hilog_rows() if f" {res['pid']} "in r]
 ready_deadline=time.monotonic()+8
 while True:
  state=m.public_owner_state(a.port)
  if 'MODE=preview'in state and re.search(r'edit=live ctx=\d+ gen=\d+ node=190 ',state):break
  if time.monotonic()>=ready_deadline:raise RuntimeError('normal preview and live presentation identity not accepted')
  time.sleep(.08)
 initial=rows();fence=initial[-1] if initial else '';version,h=m.read_all(a.port);body=bytes.fromhex(h)
 geo=m.parse_geo_section(state);origin=m.surface_origin_px();density=geo['density']
 overlays=[int(re.search(r'top_px=(-?\d+)',r).group(1)) for r in initial if 'keyboard overlay top_px='in r]
 band=min(geo['viewport'][1]/density,overlays[-1]/density) if overlays and overlays[-1]>=0 else geo['viewport'][1]/density
 clips=[r for r in geo['records'] if r['semantic']=='pharos-editor-scroll'];clip=clips[0]['visible'];bottom=min(clip[1]+clip[3],int(band));left=clip[0];right=left+clip[2]
 blocks=[r for r in geo['records'] if r['semantic']=='pharos-editor-block' and not r['invisible'] and r['visible'][3]>=24]
 starts=[r for r in blocks if r['visible'][1]+8<bottom-90]
 if not starts:raise RuntimeError('accepted start rectangle unavailable')
 start=max(starts,key=lambda r:r['visible'][1]);rect=start['visible']
 sx=rect[0]+3;sy=min(rect[1]+rect[3]-10,bottom-100);ex=min(right-32,rect[0]+rect[2]-24);ey=bottom-14
 if ex-sx<=abs(ey-sy):raise RuntimeError('one selection gesture cannot dominate horizontal motion within current visible band')
 pt=lambda x,y:[int(origin[0]+x*density),int(origin[1]+y*density)]
 begin=pt(sx,sy);end=pt(ex,ey);res.update(begin=begin,end=end,visible_band_bottom=bottom)
 out.joinpath('before.ctx').write_text(m.ctx(a.port));samples=[];start_time=time.monotonic();tool={}
 def inject():
  r=m.hdc('shell','uinput','-T','-m',*map(str,begin+end),'-k','2500','900',timeout=15);tool.update(rc=r.returncode,stdout=r.stdout,stderr=r.stderr)
 thread=threading.Thread(target=inject);thread.start()
 while thread.is_alive() and time.monotonic()-start_time<10:
  i=len(samples);samples.append({'s':time.monotonic()-start_time,'ctx':m.ctx(a.port)})
  device=f'/data/local/tmp/hdwell{i:02d}.jpeg';m.hdc('shell','snapshot_display','-f',device);m.hdc('file','recv',device,str(out/f'frame{i:02d}.jpeg'));time.sleep(.12)
 thread.join(timeout=1)
 # Tool completion means UP was sent. Observe application consumption before
 # checking that no later tick can mutate the selection.
 terminal_deadline=time.monotonic()+8
 while True:
  after=rows();idx=after.index(fence)+1 if fence in after else len(after);raw=after[idx:]
  if any('EDGE_DWELL stage=stop reason=phase_terminal'in r for r in raw) or time.monotonic()>=terminal_deadline:break
  time.sleep(.08)
 out.joinpath('raw-hilog.txt').write_text('\n'.join(raw));out.joinpath('samples.json').write_text(json.dumps(samples,indent=2));res['tool']=tool
 recomputed=[r for r in raw if 'EDGE_DWELL stage=recomputed'in r];stops=[r for r in raw if 'EDGE_DWELL stage=stop'in r];evals=[r for r in raw if 'EDGE_DWELL stage=eval'in r]
 first=dev_ms(evals[0]) if evals else None
 static=[r for r in recomputed if first is not None and dev_ms(r)>=first+1100]
 identities={tuple(re.search(r'gesture=(\d+) binding=(\d+)',r).groups()) for r in recomputed}
 offsets=[int(re.search(r'acceptedOffset=(\d+)',r).group(1)) for r in static]
 selections=[r for r in raw if 'OWNED_SELECTION_ADOPTED2 node=190'in r]
 static_sel=[]
 for sample in samples:
  if sample['s']<1.1:continue
  context=sample['ctx'];mo=re.search(r'OWNER_STATE_UTF8_HEX \d+ ([0-9A-Fa-f]+)',context)
  state=bytes.fromhex(mo.group(1)).decode() if mo else ''
  selection=re.search(r'SOURCE_SELECTION ownerVersion=(\d+) mirrorVersion=(\d+) sourceContext=(\d+) sessionEpoch=(\d+) range=(\d+):(\d+)',state)
  if selection and int(selection[1])==int(selection[2])==version:
   static_sel.append((int(selection[5]),int(selection[6])))
 stop_fence=after[-1] if after else '';time.sleep(.8);settled=rows();si=settled.index(stop_fence)+1 if stop_fence in settled else len(settled);late=[r for r in settled[si:] if 'EDGE_DWELL stage=recomputed'in r or 'EDGE_DWELL stage=step'in r]
 res.update(static_offsets=offsets,static_selection=static_sel,gesture_identities=list(identities),stops=stops,late_tick_rows=late)
 res['dwell_ok']=len(set(offsets))>=3 and len(identities)==1 and len(set(static_sel))>=3 and len({x[0] for x in static_sel})==1 and not late and any('reason=phase_terminal'in r for r in stops)
 if not a.observe_only and res['dwell_ok']:
  final_source=[r for r in raw if 'PHAROS_VISUAL_SELECTION caret_node='in r and 'committed=true'in r and 'SOURCE_SELECTION'in r]
  if not final_source:raise RuntimeError('UP source selection identity unavailable')
  up_frozen=re.search(r'SOURCE_SELECTION ownerVersion=(\d+) mirrorVersion=(\d+) sourceContext=(\d+) sessionEpoch=(\d+) range=(\d+):(\d+)',final_source[-1])
  current=m.public_owner_state(a.port)
  frozen=re.search(r'SOURCE_SELECTION ownerVersion=(\d+) mirrorVersion=(\d+) sourceContext=(\d+) sessionEpoch=(\d+) range=(\d+):(\d+)',current)
  if not frozen or not (int(frozen[1])==int(frozen[2])==version):raise RuntimeError('current source selection basis unavailable')
  if not up_frozen or frozen.groups()!=up_frozen.groups():raise RuntimeError('settlement replaced the source selection frozen at UP')
  sel=sorted((int(frozen[5]),int(frozen[6])))
  live=re.search(r'edit=live ctx=(\d+) gen=(\d+) node=190 res=(-?\d+) kind=(\d+) b=(\d+)',current)
  if not live:raise RuntimeError('current native presentation identity unavailable')
  res['frozen_source_basis']=frozen.group(0);res['frozen_native_basis']=live.group(0)
  adoption_deadline=time.monotonic()+8;adopted=False
  while time.monotonic()<adoption_deadline:
   current=m.public_owner_state(a.port)
   exact=re.search(r'SOURCE_SELECTION ownerVersion=(\d+) mirrorVersion=(\d+) sourceContext=(\d+) sessionEpoch=(\d+) range=(\d+):(\d+)',current)
   if not exact or exact.groups()!=up_frozen.groups():raise RuntimeError('restore settlement changed the UP source selection')
   installed=re.search(r'needsRestore=(true|false) restorePending=(true|false) restoreCount=(\d+) restoreFailures=(\d+) restoreRequest=(\d+) restoreContext=(\d+) restoreNode=(\d+) restoredRange=(\d+):(\d+) restoreOwner=(\d+) restoreProjection=(\d+)',current)
   if installed and installed[1]=='false' and installed[2]=='false' and int(installed[5])>0 and installed[6]==live[1] and installed[7]=='190' and [int(installed[8]),int(installed[9])]==sel and int(installed[10])==version:
    adopted=True;res['final_window_adoption']=installed.group(0);break
   time.sleep(.08)
  if not adopted:
   res['ok']=False;res['failure']='final_selection_not_adopted';out.joinpath('dwell.json').write_text(json.dumps(res,indent=2));out.joinpath('settlement-hilog.txt').write_text('\n'.join(rows()));return 2
  expected=strict_utf16.expected_replacement(body,*sel,'X');m.uitest('text','X');deadline=time.monotonic()+8;actual=b''
  while time.monotonic()<deadline:
   v,h=m.read_all(a.port);actual=bytes.fromhex(h)
   if actual==expected:break
   time.sleep(.08)
  res.update(selection=sel,replacement_exact=actual==expected,version=[version,v]);out.joinpath('expected.md').write_bytes(expected);out.joinpath('actual.md').write_bytes(actual)
 res['ok']=res['dwell_ok'] and (a.observe_only or res.get('replacement_exact',False));out.joinpath('dwell.json').write_text(json.dumps(res,ensure_ascii=False,indent=2));print(json.dumps({'ok':res['ok'],'static_scrolls':len(set(offsets)),'static_selections':len(set(static_sel))}));return 0 if res['ok'] else 2
if __name__=='__main__':sys.exit(main())

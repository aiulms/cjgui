#!/usr/bin/env python3
"""Normal thermo: first focus, shared reveal, one physical static hold/UP, exact note replacement."""
import argparse,json,re,sys,threading,time
from pathlib import Path
HERE=Path(__file__).resolve().parent;sys.path.insert(0,str(HERE))
import h_source_preview_consumption as m
import verify_thermo_continuity as tc
import strict_utf16

def dev_ms(row):
 t=re.match(r'\d\d-\d\d (\d\d):(\d\d):(\d\d)\.(\d\d\d)',row)
 return sum(int(x)*w for x,w in zip(t.groups(),(3600000,60000,1000,1))) if t else None

def main():
 ap=argparse.ArgumentParser();ap.add_argument('--target',required=True);ap.add_argument('--out',required=True);a=ap.parse_args()
 m.TARGET=a.target;tc._m.TARGET=a.target;out=Path(a.out);out.mkdir(parents=True,exist_ok=False)
 tc.EXCHANGE=tc.BoundedExchange('127.0.0.1',17857,str(out/'raw-protocol.json'))
 res={'ok':False,'gesture_intents':1,'pid':m.hdc('shell','pidof',tc.BUNDLE).stdout.strip()};samples=[]
 def rows():return [r for r in m.hilog_rows() if f" {res['pid']} "in r]
 def state():return tc.readback_owner_state()
 def wait(check,label,seconds=8):
  deadline=time.monotonic()+seconds
  while time.monotonic()<deadline:
   s=state()
   if s and check(s):return s
   time.sleep(.08)
  raise RuntimeError(label)
 try:
  v0,baseline=tc.read_state();res['baseline']={'version':v0,'fields':baseline}
  fixture='\n'.join(chr(65+i%26) for i in range(31));res['fixture']=fixture
  if baseline.get('note')==fixture:
   v,fields=v0,baseline;res['fixture_setup']='existing owned diagnostic fixture'
  else:
   inv=tc.invoke('SET_NOTE',v0,[('text','STRING',fixture)]);res['fixture_response']=inv
   v,fields=tc.read_state();assert inv['applied'] and v==v0+1 and fields['note']==fixture
  untouched={k:x for k,x in baseline.items() if k!='note'}
  if {k:x for k,x in fields.items() if k!='note'}!=untouched:raise RuntimeError('fixture polluted another field')
  s=wait(lambda s: bool(m.find_geo_record(m.parse_geo_section(s),'thermo-note-presentation')[0]),'note not published')
  # Each navigation page uses a fresh accepted geometry and one real swipe.
  # A page that does not settle fails immediately; no focus/Back preparation.
  res['navigation_pages']=[]
  for page in range(6):
   geo=m.parse_geo_section(s);note,why=m.find_geo_record(geo,'thermo-note-presentation');assert note,why
   if not note['invisible'] and note['visible'][3]>=40:break
   scroll,why=m.find_geo_record(geo,'thermo-card-scroll');assert scroll and not scroll['invisible'],why
   x,y,w,h=scroll['visible'];origin=m.surface_origin_px();density=geo['density']
   coords=[int(origin[0]+(x+w/2)*density),int(origin[1]+(y+h-10)*density),int(origin[0]+(x+w/2)*density),int(origin[1]+(y+10)*density)]
   oldY=note['bounds'][1]
   r=m.hdc('shell','uinput','-T','-m',*map(str,coords),'2200',timeout=12)
   # Tool completion is real UP, not inertia completion. Observe stable accepted
   # geometry before another physical intent so page motion cannot accumulate.
   deadline=time.monotonic()+8;lastY=None;stableSince=None
   while time.monotonic()<deadline:
    s=state();n,_=m.find_geo_record(m.parse_geo_section(s),'thermo-note-presentation')
    yNow=n['bounds'][1] if n else None
    if yNow!=lastY:lastY=yNow;stableSince=time.monotonic()
    elif yNow is not None and yNow<oldY and time.monotonic()-stableSince>=.4:break
    time.sleep(.1)
   else:raise RuntimeError('one navigation page did not settle')
   fresh,_=m.find_geo_record(m.parse_geo_section(s),'thermo-note-presentation')
   res['navigation_pages'].append({'before_note_y':oldY,'after_note_y':fresh['bounds'][1],'coords':coords,'rc':r.returncode})
  else:raise RuntimeError('bounded navigation did not expose the note')
  point=tc.readback_semantic_point('thermo-note-presentation');assert point,'normal note is not visible'
  initial=rows();fence=initial[-1] if initial else ''
  res['first_focus']=m.uitest('click',*map(lambda x:str(int(x)),point)).stdout
  s=wait(lambda s:re.search(r'edit=live ctx=\d+ gen=\d+ node=25 ',s) and 'needsRestore=false restorePending=false'in s,'first normal focus not settled')
  out.joinpath('focused-state.txt').write_text(s)
  geo=m.parse_geo_section(s);note,why=m.find_geo_record(geo,'thermo-note-presentation');assert note,why
  scroller,_=m.find_geo_record(geo,'thermo-card-scroll');assert scroller,'card scroll identity absent'
  deadline=time.monotonic()+8
  while time.monotonic()<deadline:
   overlays=[int(re.search(r'top_px=(-?\d+)',r)[1]) for r in rows() if 'keyboard overlay top_px='in r]
   if overlays and overlays[-1]>=0:break
   time.sleep(.08)
  else:raise RuntimeError('first focus did not expand keyboard within bound')
  # Use the geometry adopted after the keyboard report, rather than the earlier
  # focus response. In a continued diagnostic this can be an existing keyboard.
  s=state();geo=m.parse_geo_section(s);note,why=m.find_geo_record(geo,'thermo-note-presentation');assert note,why
  scroller,_=m.find_geo_record(geo,'thermo-card-scroll');assert scroller,'card scroll identity absent'
  density=geo['density'];band=min(int(geo['viewport'][1]/density),int(overlays[-1]/density))
  rect=note['visible'];clip=scroller['visible'];bottom=min(clip[1]+clip[3],band)
  if note['bounds'][1]<clip[1]:
   # At the end of a long note there is room above, so hold the upper edge.
   # This is a single reverse physical gesture, not accumulated presses.
   sx=rect[0]+rect[2]-8;sy=min(bottom-24,rect[1]+rect[3]-12);ex=rect[0]+18;ey=clip[1]+12
  else:
   sx=rect[0]+8;sy=rect[1]+8;ex=rect[0]+rect[2]-18;ey=bottom-12
  if not(rect[1]<=sy<bottom and abs(ex-sx)>abs(ey-sy)):raise RuntimeError('accepted visible band cannot start one selection gesture')
  origin=m.surface_origin_px();pt=lambda x,y:[int(origin[0]+x*density),int(origin[1]+y*density)]
  begin,end=pt(sx,sy),pt(ex,ey);res.update(begin=begin,end=end,band_bottom=bottom)
  before=rows();fence=before[-1] if before else '';tool={};t0=time.monotonic()
  def inject():
   r=m.hdc('shell','uinput','-T','-m',*map(str,begin+end),'-k','2500','900',timeout=15);tool.update(rc=r.returncode,stdout=r.stdout,stderr=r.stderr)
  thread=threading.Thread(target=inject);thread.start()
  while thread.is_alive() and time.monotonic()-t0<10:
   i=len(samples);samples.append({'s':time.monotonic()-t0,'state':state()})
   device=f'/data/local/tmp/thermo-common-{i:02d}.jpeg';m.hdc('shell','snapshot_display','-f',device);m.hdc('file','recv',device,str(out/f'frame-{i:02d}.jpeg'));time.sleep(.12)
  thread.join(timeout=1);res['tool']=tool
  deadline=time.monotonic()+8
  while time.monotonic()<deadline:
   rr=rows();idx=rr.index(fence)+1 if fence in rr else len(rr);raw=rr[idx:]
   if any('EDGE_DWELL stage=stop reason=phase_terminal'in r for r in raw):break
   time.sleep(.08)
  out.joinpath('dwell-hilog.txt').write_text('\n'.join(raw))
  evals=[r for r in raw if 'EDGE_DWELL stage=eval'in r];first=dev_ms(evals[0]) if evals else None
  accepted=[r for r in raw if 'EDGE_DWELL stage=recomputed'in r and first is not None and dev_ms(r)>=first+1100]
  offsets={int(re.search(r'acceptedOffset=(\d+)',r)[1]) for r in accepted}
  identities={re.search(r'gesture=(\d+) binding=(\d+)',r).groups() for r in accepted}
  ranges=[]
  for sample in samples:
   sel=re.search(r'NOTE_SELECTION ownerVersion=(\d+) mirrorVersion=(\d+) sourceContext=(\d+) range=(\d+):(\d+)',sample['state'] or '')
   if sample['s']>=1.1 and sel and int(sel[1])==int(sel[2])==v:ranges.append((int(sel[4]),int(sel[5])))
  stopFence=rr[-1] if rr else '';time.sleep(.8);after=rows();idx=after.index(stopFence)+1 if stopFence in after else len(after)
  late=[r for r in after[idx:] if 'EDGE_DWELL stage=recomputed'in r or 'EDGE_DWELL stage=step'in r]
  res.update(static_offsets=sorted(offsets),gesture_identities=list(identities),static_ranges=ranges,late_ticks=late)
  if len(offsets)<3 or len(identities)!=1 or len(set(ranges))<3 or not(len({r[0] for r in ranges})==1 or len({r[1] for r in ranges})==1) or late:raise RuntimeError('one static gesture did not extend accepted selection')
  if not any('EDGE_DWELL stage=stop reason=phase_terminal'in r for r in raw):raise RuntimeError('real UP not consumed')
  s=state();endFact=re.search(r'NOTE_END ownerVersion=(\d+) range=(\d+):(\d+) scene=(\d+)',s or '')
  if not endFact or int(endFact[1])!=v:raise RuntimeError('UP frozen note range absent')
  sel=sorted(map(int,(endFact[2],endFact[3])));res['up_basis']=endFact.group(0);live=re.search(r'edit=live ctx=(\d+) gen=(\d+) node=25 res=(\d+) kind=(\d+) b=(\d+)',s);assert live,'current presentation input identity absent'
  def installed(s):
   fact=re.search(r'NOTE_SELECTION ownerVersion=(\d+) mirrorVersion=(\d+) sourceContext=(\d+) range=(\d+):(\d+) needsRestore=(true|false) restorePending=(true|false) restoreRequest=(\d+) restoreContext=(\d+) restoreNode=(\d+) restoredRange=(\d+):(\d+) restoreOwner=(\d+) restoreProjection=(\d+)',s)
   return fact and int(fact[1])==int(fact[2])==v and list(map(int,(fact[4],fact[5])))==sel and fact[6]==fact[7]=='false' and int(fact[8])>0 and fact[9]==live[1] and fact[10]=='25' and list(map(int,(fact[11],fact[12])))==sel and int(fact[13])==v
  adopted=wait(installed,'UP note range did not reach window adoption');res['window_adoption']=adopted
  expected=strict_utf16.expected_replacement(fixture.encode(),*sel,'X').decode();m.uitest('text','X');deadline=time.monotonic()+8
  while time.monotonic()<deadline:
   v2,fields2=tc.read_state()
   if v2==v+1 and fields2.get('note')==expected:break
   time.sleep(.08)
  res['after']={'version':v2,'fields':fields2};res['expected_note']=expected
  if v2!=v+1 or fields2.get('note')!=expected or {k:x for k,x in fields2.items() if k!='note'}!=untouched:raise RuntimeError('single X replacement was not exact or another field changed')
  evidence=rows();res['common_reveal']=[r for r in evidence if 'CJGUI_CARET_REVEAL'in r and 'node=25'in r]
  if not res['common_reveal']:raise RuntimeError('same common reveal was not consumed')
  res['ok']=m.hdc('shell','pidof',tc.BUNDLE).stdout.strip()==res['pid']
 except Exception as e:res['failure']=str(e)
 finally:
  out.joinpath('samples.json').write_text(json.dumps(samples,ensure_ascii=False,indent=2));out.joinpath('final-hilog.txt').write_text('\n'.join(rows()));out.joinpath('final-state.txt').write_text(state() or '');out.joinpath('result.json').write_text(json.dumps(res,ensure_ascii=False,indent=2));print(json.dumps({k:res.get(k) for k in ('ok','pid','failure')},ensure_ascii=False))
 return 0 if res['ok'] else 2
if __name__=='__main__':sys.exit(main())

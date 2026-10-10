#!/usr/bin/env python3
"""Twenty single input intents, correlated to producer identity, owner and painted feedback.
Tool duration and observed owner/visible upper bounds use the host monotonic clock.
Device dequeue-to-paint uses only this input's producer/dequeue/owner/accepted pair.
"""
import argparse
import importlib.util
import json
import re
import subprocess
import sys
import time
from pathlib import Path

HERE = Path(__file__).resolve().parent
_spec = importlib.util.spec_from_file_location(
    'pharos_driver', HERE / 'h_source_preview_consumption.py')
m = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(m)
sys.path.insert(0,str(HERE));import strict_utf16

PORT = 0
HDC = '/Applications/DevEco-Studio.app/Contents/sdk/default/openharmony/toolchains/hdc'
DEV = re.compile(r'^(\d\d-\d\d) (\d\d:\d\d:\d\d\.\d\d\d)\s+\d+\s+\d+')


def dev_ms(row: str):
    mo = DEV.match(row)
    if not mo:
        return None
    h, mi, s = mo.group(2).split(':')
    return ((int(h) * 60 + int(mi)) * 60 + float(s)) * 1000.0


def pid():
    r = m.hdc('shell', 'pidof', 'com.pharos.mark')
    out = (r.stdout or '').strip().split()
    return out[0] if out else None


def vm_hwm_kb(p: str):
    r = m.hdc('shell', 'cat', f'/proc/{p}/status')
    mo = re.search(r'VmHWM:\s+(\d+)', r.stdout or '')
    return int(mo.group(1)) if mo else None


def memory_kb(p):
    text=m.hdc('shell','cat',f'/proc/{p}/status').stdout
    return {k:int(v) for k,v in re.findall(r'(VmRSS|VmHWM):\s+(\d+) kB',text)}


def read_version():
    try:
        v, hx = m.read_all(PORT)
        return v, hx
    except Exception:
        return None, None


def app_rows():
    return [r for r in m.hilog_rows() if 'Cjgui' in r]



def capture(out: Path, tag: str):
    dst = out / f'{tag}.jpeg'
    m.hdc('shell', 'snapshot_display', '-f', f'/data/local/tmp/{tag}.jpeg')
    m.hdc('file', 'recv', f'/data/local/tmp/{tag}.jpeg', str(dst))
    return dst.name


def main():
    global args, PORT
    ap = argparse.ArgumentParser()
    ap.add_argument('--target', required=True)
    ap.add_argument('--port', type=int, default=28991)
    ap.add_argument('--out', required=True)
    ap.add_argument('--rounds', type=int, default=20)
    args = ap.parse_args()
    PORT = args.port
    m.TARGET = args.target
    out = Path(args.out)
    out.mkdir(parents=True, exist_ok=False)
    res = {'rounds': []}

    p = pid()
    res['pid'] = p
    res['rss_hwm_kb_start'] = vm_hwm_kb(p) if p else None

    # Caller supplies the current, normally focused source editor. No restart,
    # focus/Back preparation, or replay is part of the measurement.
    for i in range(args.rounds):
        if pid()!=p: raise RuntimeError('PID changed during 20-input sample')
        before=app_rows();marker=before[-1] if before else ''
        v0,h0=read_version();body=bytes.fromhex(h0)
        source=m.public_owner_state(PORT)
        selection=re.search(r'SOURCE_SELECTION ownerVersion=(\d+) mirrorVersion=(\d+) sourceContext=(\d+) sessionEpoch=(\d+) range=(\d+):(\d+).*?mirrorStart=(\d+)',source)
        if not selection or int(selection[1])!=v0 or int(selection[2])!=v0:raise RuntimeError('input source basis unavailable')
        lo,hi=map(int,(selection[5],selection[6]));startByte=int(selection[7])
        expected=body[:startByte]+strict_utf16.expected_replacement(body[startByte:],lo,hi,'x')
        t0=time.monotonic()
        tool=m.uitest('text','x')
        tool_ms=(time.monotonic()-t0)*1000
        observed=None;v1=None;h1=None
        deadline=time.monotonic()+4
        while time.monotonic()<deadline:
            v1,h1=read_version()
            if v1==v0+1:
                observed=(time.monotonic()-t0)*1000;break
            time.sleep(.03)
        decision=None;producer=None;delta=None;feedback=None;commit=None;raw=[]
        deadline=time.monotonic()+3
        while time.monotonic()<deadline:
            rr=app_rows();idx=rr.index(marker)+1 if marker in rr else len(rr)
            raw=[r for r in rr[idx:] if f' {p} 'in r]
            decisions=[r for r in raw if 'PHAROS_OHOS_EDIT 'in r and f'owner_version={v1} 'in r and 'applied=true' in r]
            producers=[r for r in raw if 'ime range delta node='in r and f'ownerBase={v0}'in r]
            deltas=[r for r in raw if 'ime range delta dequeue 'in r]
            feedbacks=[r for r in raw if 'text feedback 'in r and f'owner={v1} 'in r and 'node=107 'in r]
            if len(decisions)==1 and len(producers)==1 and len(deltas)==1 and feedbacks:
                candidate=feedbacks[0]
                ticket=re.search(r'ticket=(\d+)',candidate)[1];projection=re.search(r'projection=(\d+)',candidate)[1]
                commits=[r for r in raw if 'accepted commit 'in r and f'v={projection} 'in r and f'ticket={ticket} 'in r]
                if len(commits)==1:
                    decision=decisions[0];producer=producers[0];delta=deltas[0];feedback=candidate;commit=commits[0];break
            time.sleep(.04)
        visible_ms=(time.monotonic()-t0)*1000 if feedback else None
        def fields(row):
            return dict(re.findall(r'(\w+)=(-?\d+)',row or ''))
        d=fields(decision);issued=fields(producer);native=fields(delta);paint=fields(feedback);accepted=fields(commit)
        issuedRange=re.search(r'range=(\d+):(\d+)',producer or '')
        dequeuedRange=re.search(r'range=(\d+):(\d+)',delta or '')
        correlated=bool(d and issued and native and paint and accepted and accepted.get('v')==paint.get('projection') and accepted.get('ticket')==paint.get('ticket') and issuedRange and dequeuedRange and
            issuedRange.groups()==dequeuedRange.groups() and issued.get('bytes')==native.get('bytes')=='1' and
            issued.get('projection')==native.get('projection') and issued.get('ownedBinding')==native.get('binding') and
            issued.get('node')==native.get('node')==paint.get('node') and
            issued.get('acceptedBinding')==paint.get('binding') and issued.get('context')==paint.get('context') and
            int(issued['ownerBase'])==v0 and int(d['owner_version'])==int(paint['owner'])==v0+1 and
            int(d.get('ticket','0'))>0 and int(d.get('seq','0'))>0 and bytes.fromhex(h1)==expected)
        (out/f'input-{i:02d}-hilog.txt').write_text('\n'.join(raw))
        res['rounds'].append({'i':i,'pid':p,'input':'x','tool_ms':round(tool_ms,1),
            'owner_observed_ms':round(observed,1) if observed is not None else None,
            'visible_observed_ms':round(visible_ms,1) if visible_ms is not None else None,
            'delta_to_visible_device_ms':round(dev_ms(feedback)-dev_ms(delta),1) if correlated else None,
            'producer_to_visible_device_ms':round(dev_ms(feedback)-dev_ms(producer),1) if correlated else None,
            'version':[v0,v1],'source_basis':selection.group(0),'decision':d,'producer':issued,'native_input':native,'accepted_paint':paint,'accepted_commit':accepted,
            'correlated':correlated,'exact_owner':bytes.fromhex(h1)==expected,'tool_rc':tool.returncode,'rss':memory_kb(p)})
        if not correlated or v1!=v0+1:
            res['failure']='one_input_not_correlated';break
        time.sleep(.1)

    def pct(vals, q):
        vals = sorted(v for v in vals if v is not None)
        if not vals:
            return None
        k = max(0, min(len(vals) - 1, int(round(q * (len(vals) - 1)))))
        return vals[k]

    for key in ('tool_ms','owner_observed_ms','visible_observed_ms','delta_to_visible_device_ms','producer_to_visible_device_ms'):
        values=[r[key] for r in res['rounds']]
        res[key+'_p50']=pct(values,.5);res[key+'_p95']=pct(values,.95);res[key+'_max']=pct(values,1)
    res['rss_end']=memory_kb(p)
    # Same PID, unchanged owner and accepted paint identity during a bounded idle.
    idle=[];idle_start=time.monotonic();idle_version,idle_body=read_version()
    for step in range(4):
        rr=[r for r in app_rows() if f' {p} 'in r and 'text feedback 'in r and 'node=107 'in r]
        idle.append({'elapsed_ms':round((time.monotonic()-idle_start)*1000,1),'pid':pid(),'owner':read_version()[0],'rss':memory_kb(p),'last_paint':fields(rr[-1]) if rr else {},'raw':rr[-1] if rr else ''})
        if step<3:time.sleep(1)
    res['idle_same_instance']=idle
    res['idle_owner_unchanged']=read_version()==(idle_version,idle_body)
    if idle[0]['last_paint'] and idle[-1]['last_paint']:
        res['idle_layout_work']={k:int(idle[-1]['last_paint'][k])-int(idle[0]['last_paint'][k]) for k in ('layouts','layoutBytes')}
        res['idle_live_resource_bounds']={k:[int(x['last_paint'][k]) for x in idle if k in x['last_paint']] for k in ('liveSlots','liveUnits')}

    res['layouts_interpretation']='layouts/layoutBytes are cumulative work; accepted_paint identifies ticket/projection and current liveSlots/liveUnits'
    res['ok']=len(res['rounds'])==args.rounds and all(r['correlated'] for r in res['rounds']) and pid()==p
    (out / 'input_cost.json').write_text(json.dumps(res, ensure_ascii=False, indent=2))
    print(json.dumps({'ok':res['ok'],'pid':p,'rounds':len(res['rounds']),
        'tool_p95':res['tool_ms_p95'],'visible_upper_bound_p95':res['visible_observed_ms_p95']},ensure_ascii=False))
    return 0 if res['ok'] else 2


if __name__ == '__main__':
    sys.exit(main())

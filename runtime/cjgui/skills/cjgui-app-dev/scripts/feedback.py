#!/usr/bin/env python3
"""Append-only, local CJGUI observations. Never executes input content."""
import argparse
import datetime
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import sys
import uuid

ID = re.compile(r'^[0-9a-f]{32}$')
MAX_FILE = 64 * 1024 * 1024
MAX_EVENT = 512 * 1024 * 1024
FIELDS = {'goal':'', 'expected':'', 'actual':'', 'identity':{}, 'platform':'unknown', 'reproduction':[], 'attempts':[], 'classification':'unclassified', 'hypotheses':[], 'usability':[], 'workaround':{}, 'evidence':[], 'links':[], 'source_fix':'unknown', 'sdk_inclusion':'unknown', 'consumer_verification':'unknown', 'supersedes':None}
TRIAGE = {'decision':'pending', 'reason':''}
DECISIONS = {'pending', 'needs_evidence', 'framework_fix', 'usability_improvement', 'no_framework_action'}
FIELDS['triage'] = TRIAGE


def canonical(v): return json.dumps(v,ensure_ascii=False,sort_keys=True,separators=(',',':')).encode()
def digest(b): return hashlib.sha256(b).hexdigest()
def file_digest(p):
    h=hashlib.sha256()
    with p.open('rb') as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b''): h.update(chunk)
    return h.hexdigest()

def load(p):
    try:
        with p.open(encoding='utf-8') as f: return json.load(f)
    except json.JSONDecodeError as error:
        raise ValueError(f'{p}: {error}') from error
def valid_id(s):
    if not ID.fullmatch(s): raise ValueError('invalid issue or event ID')
    return s

def input_data(p):
    d=load(p)
    if not isinstance(d,dict): raise ValueError('input must be an object')
    if set(d)-set(FIELDS): raise ValueError('unknown fields: ' + ', '.join(sorted(set(d)-set(FIELDS))))
    for k in ('goal','expected','actual'):
        if not isinstance(d.get(k),str) or not d[k].strip(): raise ValueError(f'{k} must be a nonempty string')
    for k in ('evidence','reproduction','attempts','hypotheses','usability','links'):
        if k in d and not isinstance(d[k],list): raise ValueError(f'{k} must be a list')
    for k in ('identity','workaround'):
        if k in d and not isinstance(d[k],dict): raise ValueError(f'{k} must be an object')
    for k in ('platform','classification','source_fix','sdk_inclusion','consumer_verification'):
        if k in d and not isinstance(d[k],str): raise ValueError(f'{k} must be a string')
    if any(not isinstance(x,str) or not x for x in d.get('evidence',[])): raise ValueError('evidence must be file paths')
    if d.get('supersedes') is not None: valid_id(d['supersedes'])
    triage = d.get('triage', TRIAGE)
    if not isinstance(triage,dict) or set(triage)-set(TRIAGE): raise ValueError('triage requires decision and reason')
    if not isinstance(triage.get('decision'),str) or triage['decision'] not in DECISIONS: raise ValueError('invalid triage decision')
    if not isinstance(triage.get('reason'),str): raise ValueError('triage reason must be a string')
    if triage['decision'] != 'pending' and not triage['reason'].strip(): raise ValueError('triage decisions require a reason; use pending until reviewed')
    return {**FIELDS,**d}


def issue_dir(root, issue):
    valid_id(issue); p=root/'issues'/issue
    if p.is_symlink() or not p.is_dir() or not p.resolve().is_relative_to(root): raise ValueError('issue does not exist or is unsafe')
    for sub in ('events','evidence'):
        q=p/sub
        if q.is_symlink() or not q.is_dir(): raise ValueError('unsafe issue directory')
    return p


def verify(p):
    events=[]
    for file in sorted((p/'events').glob('*.json')):
        if file.is_symlink(): raise ValueError('symlink event')
        event=load(file)
        if not isinstance(event,dict): raise ValueError('invalid event')
        checksum=event.get('record_sha256'); body={k:v for k,v in event.items() if k!='record_sha256'}
        if file.stem != event.get('id') or not ID.fullmatch(file.stem) or checksum != digest(canonical(body)): raise ValueError('event integrity check failed')
        for item in event['data']['evidence']:
            name=item['file']; ep=p/'evidence'/name
            if Path(name).name != name or ep.is_symlink() or not ep.is_file() or file_digest(ep) != item['sha256']: raise ValueError('evidence integrity check failed')
        events.append(event)
    return sorted(events, key=lambda e: (e['timestamp'], e['id']))


def write_event(p, data):
    previous=verify(p)
    if data.get('supersedes') and not any(e['id']==data['supersedes'] for e in previous): raise ValueError('supersedes event not found')
    files=[]; created=[]; published=False; tmp=None; total=0
    try:
        for value in data['evidence']:
            src=Path(value).expanduser()
            if not src.is_file(): raise ValueError(f'evidence file unavailable: {src}')
            if src.stat().st_size > MAX_FILE: raise ValueError('evidence exceeds 64 MiB per file; link existing evidence instead')
            name=uuid.uuid4().hex + '.bin'; dst=p/'evidence'/name
            h=hashlib.sha256(); size=0
            with src.open('rb') as inp, dst.open('xb') as out:
                created.append(dst)
                while True:
                    chunk=inp.read(1024*1024)
                    if not chunk: break
                    size+=len(chunk); total+=len(chunk)
                    if size>MAX_FILE or total>MAX_EVENT: raise ValueError('evidence exceeds 64 MiB per file or 512 MiB per event; link existing evidence instead')
                    h.update(chunk); out.write(chunk)
                out.flush(); os.fsync(out.fileno())
            files.append({'file':name,'original_name':src.name,'sha256':h.hexdigest(),'size':size})
        data={**data,'evidence':files}; eid=uuid.uuid4().hex
        event={'id':eid,'timestamp':datetime.datetime.now(datetime.timezone.utc).isoformat(),'data':data}
        event['record_sha256']=digest(canonical(event))
        tmp=p/'events'/('.'+eid+'.tmp'); final=p/'events'/(eid+'.json')
        with tmp.open('xb') as f: f.write(json.dumps(event,ensure_ascii=False,indent=2).encode()+b'\n'); f.flush(); os.fsync(f.fileno())
        os.link(tmp,final); published=True
        return eid
    finally:
        if tmp is not None: tmp.unlink(missing_ok=True)
        if not published:
            for dst in created: dst.unlink(missing_ok=True)


def main():
    parser=argparse.ArgumentParser(); sub=parser.add_subparsers(dest='action',required=True)
    sub.add_parser('template')
    c=sub.add_parser('create'); c.add_argument('--app',required=True,type=Path); c.add_argument('--input',required=True,type=Path); c.add_argument('--root',type=Path)
    a=sub.add_parser('append'); a.add_argument('--root',required=True,type=Path); a.add_argument('--issue',required=True); a.add_argument('--input',required=True,type=Path)
    s=sub.add_parser('show'); s.add_argument('--root',required=True,type=Path); s.add_argument('--issue',required=True)
    l=sub.add_parser('list'); l.add_argument('--root',required=True,type=Path)
    x=parser.parse_args()
    if x.action=='template': print(json.dumps(FIELDS,ensure_ascii=False,indent=2)); return
    if x.action=='create':
        data=input_data(x.input)
        if not x.app.is_dir(): raise ValueError('app must be an existing directory')
        if x.root:
            if not x.root.is_dir(): raise ValueError('provided feedback root must exist')
            root=x.root.resolve()
        else:
            app=x.app.resolve(); local=app/'.cjgui'; candidate=local/'feedback'
            if local.is_symlink() or candidate.is_symlink(): raise ValueError('default feedback path cannot use symlinks')
            root=candidate.resolve()
            if not root.is_relative_to(app): raise ValueError('default feedback path escapes app')
            root.mkdir(parents=True,exist_ok=True)
        issues=root/'issues'
        if issues.is_symlink(): raise ValueError('unsafe issues directory')
        issues.mkdir(exist_ok=True)
        issue=uuid.uuid4().hex; p=issues/issue; p.mkdir(); (p/'events').mkdir(); (p/'evidence').mkdir()
        try:
            eid=write_event(p,data)
        except Exception:
            shutil.rmtree(p)  # newly-created, unpublished issue only
            raise
        out={'root':str(root),'issue':issue,'event':eid}
    else:
        if not x.root.is_dir(): raise ValueError('feedback root does not exist')
        root=x.root.resolve()
        if (root/'issues').is_symlink(): raise ValueError('unsafe issues directory')
        if x.action=='list':
            issues=root/'issues'; out={'schema_version':2,'root':str(root),'status':'complete','issues':[],'errors':[]}
            if issues.is_dir():
                for p in sorted(issues.iterdir()):
                    if ID.fullmatch(p.name):
                        try:
                            events=verify(issue_dir(root,p.name))
                        except (OSError,ValueError,TypeError,KeyError) as error:
                            out['errors'].append({'issue':p.name,'error':str(error)}); out['status']='partial'; continue
                        last=events[-1]['data'] if events else {}
                        superseded={e['data'].get('supersedes') for e in events}
                        observations=[{'event':e['id'],'identity':e['data'].get('identity',{}),
                                       'classification':e['data'].get('classification'),
                                       'usability':e['data'].get('usability',[]),
                                       'triage':e['data'].get('triage',TRIAGE)}
                                      for e in events if e['id'] not in superseded]
                        out['issues'].append({'issue':p.name,'events':len(events),'goal':last.get('goal'),
                                              'latest_classification':last.get('classification'),
                                              'summary_scope':'latest_observation_only','observations':observations})
        else:
            p=issue_dir(root,x.issue)
            if x.action=='append': out={'root':str(root),'issue':x.issue,'event':write_event(p,input_data(x.input))}
            else: out={'root':str(root),'issue':x.issue,'events':verify(p)}
    print(json.dumps(out,ensure_ascii=False,indent=2))

if __name__=='__main__':
    try: main()
    except (OSError, ValueError, TypeError, KeyError, json.JSONDecodeError) as e:
        print(f'feedback: {e}',file=sys.stderr); sys.exit(2)

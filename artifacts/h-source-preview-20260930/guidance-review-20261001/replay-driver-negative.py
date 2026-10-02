#!/usr/bin/env python3
"""Run the current driver's real main against no-op device/input and a fixed owner.
No hdc, socket, device, clipboard or production mutation is used.
Expected after repair: nonzero/rejected. Before repair: rc=0/status=OK.
"""
from pathlib import Path
import importlib.util,sys,json,tempfile,hashlib
root=Path(__file__).resolve().parents[3]
path=root/'runtime/cjgui/platforms/ohos/scripts/h_source_preview_consumption.py'
spec=importlib.util.spec_from_file_location('review_driver',path)
m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
body='固定原文 预览前人写 Agent 续写完成'; hx=body.encode().hex()
class Reply:
    stdout='OK\n';stderr='';returncode=0
def fake_hdc(*args,**kwargs):
    r=Reply();r.stdout='99999' if len(args)>1 and 'pidof' in args[1] else 'OK\n';return r
m.ensure_foreground=lambda:True;m.hdc=fake_hdc;m.uitest=lambda *a,**kw:Reply()
m.accepted_editor_point=lambda:(10,10);m.tap_semantic=lambda x:True
m.read_all=lambda port:(1,hx)
m.agent_replace=lambda *a,**kw:'KIND RESULT\nAPPLIED false\nREASON version_conflict\nEND'
m.time.sleep=lambda *a:None
m.save_evidence=lambda out,label,port,extra=None:{'label':label,'version':1,'owner_bytes':len(body.encode()),'owner_hex':hx,'screenshot':'not_run'}
with tempfile.TemporaryDirectory(prefix='h-preview-driver-review-') as out:
    sys.argv=['h_source_preview_consumption.py','--out',out]
    try:
        rc=m.main();result=json.loads((Path(out)/'result.json').read_text())
        false_green=rc==0 and result.get('status')=='OK'
        print(json.dumps({'driver_sha':hashlib.sha256(path.read_bytes()).hexdigest(),'main_exit':rc,'reported_status':result.get('status'),'agent_applied_response':result.get('agent_applied_response'),'false_green':false_green},ensure_ascii=False))
    except Exception as error:
        print(json.dumps({'status':'replay_error','error':str(error)}));raise
raise SystemExit(1 if false_green else 0)

import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest

SCRIPTS = Path(__file__).resolve().parents[2] / 'skills/cjgui-app-dev/scripts'

def run(script, *args, ok=True):
    p = subprocess.run([sys.executable, str(SCRIPTS / script), *map(str, args)], text=True, capture_output=True)
    if ok and p.returncode:
        raise AssertionError(p.stderr)
    return json.loads(p.stdout) if p.returncode == 0 else p

class Helpers(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(); self.root = Path(self.tmp.name)
    def tearDown(self): self.tmp.cleanup()
    def package(self, path, name, deps=''):
        path.mkdir(parents=True, exist_ok=True)
        (path/'cjpm.toml').write_text(f'[package]\nname="{name}"\n[dependencies]\n{deps}\n')
    def test_identify_layers_and_indirect_sdk(self):
        app=self.root/'app'; lib=self.root/'lib'; sdk=self.root/'sdk'; fw=sdk/'framework'
        self.package(app,'app','lib = { path = "../lib" }'); self.package(lib,'lib','cjgui = { path = "../sdk/framework" }'); self.package(fw,'cjgui')
        (sdk/'source-manifest.json').write_text(json.dumps({'format':2,'files':[{'path':'framework/cjpm.toml','sha256':'0'*64}]}))
        build=self.root/'build.json'; build.write_text(json.dumps({'framework_source':'/old/framework/src','native_libraries':{'/other/native/lib.a':'abc'},'verified':True,'executable_sha256':'x'}))
        result=run('identify.py','--app',app,'--build-provenance',build,'--verify-files')
        self.assertEqual(result['references'][0]['kind'],'export_sdk')
        self.assertEqual(result['references'][0]['file_verification']['status'],'mismatch')
        self.assertEqual(result['runtime']['status'],'unknown')
        self.assertEqual(result['build']['framework_source'],'/old/framework/src')
        self.assertTrue(result['warnings'])
    def test_missing_and_runtime(self):
        app=self.root/'app'; fw=self.root/'captured'; self.package(app,'app','cjgui = { path="../captured" }'); self.package(fw,'cjgui')
        runtime=self.root/'runtime.json'; runtime.write_text(json.dumps({'executable':'/tmp/app','executable_sha256':'abc','descriptor':'SECRET'}))
        result=run('identify.py','--app',app,'--runtime-evidence',runtime)
        self.assertEqual(result['references'][0]['kind'],'captured_or_unknown')
        self.assertEqual(result['runtime']['status'],'reported')
        self.assertNotIn('SECRET',json.dumps(result))
    def test_feedback_history_parallel_and_tamper(self):
        app=self.root/'app'; app.mkdir(); evidence=self.root/'error.log'; evidence.write_text('failure original')
        payload={'goal':'layout','expected':'footer visible','actual':'footer hidden','classification':'framework','usability':['stretch unclear'],'evidence':[str(evidence)]}
        f=self.root/'input.json'; f.write_text(json.dumps(payload))
        created=run('feedback.py','create','--app',app,'--input',f); root=Path(created['root']); issue=created['issue']; first=created['event']
        update={'goal':'layout','expected':'footer visible','actual':'misuse','classification':'application','supersedes':first,'evidence':[str(evidence)],'sdk_inclusion':'unknown','consumer_verification':'unknown'}
        f.write_text(json.dumps(update))
        procs=[subprocess.Popen([sys.executable,str(SCRIPTS/'feedback.py'),'append','--root',str(root),'--issue',issue,'--input',str(f)],stdout=subprocess.PIPE,stderr=subprocess.PIPE,text=True) for _ in range(4)]
        for p in procs:
            out,err=p.communicate(); self.assertEqual(p.returncode,0,err)
        shown=run('feedback.py','show','--root',root,'--issue',issue)
        self.assertEqual(len(shown['events']),5); self.assertIn('stretch unclear',json.dumps(shown)); self.assertIn('failure original', next((root/'issues'/issue/'evidence').iterdir()).read_text())
        event=next((root/'issues'/issue/'events').glob('*.json')); event.write_text('{}')
        self.assertNotEqual(run('feedback.py','show','--root',root,'--issue',issue,ok=False).returncode,0)
        self.assertNotEqual(run('feedback.py','show','--root',root,'--issue','../bad',ok=False).returncode,0)
    def test_lock_and_new_version_are_explicit(self):
        import hashlib
        app=self.root/'app'; sdk=self.root/'sdk'; fw=sdk/'framework'
        self.package(app,'app','cjgui = { path="../sdk/framework" }'); self.package(fw,'cjgui')
        content=(fw/'cjpm.toml').read_bytes()
        (sdk/'source-manifest.json').write_text(json.dumps({'format':2,'profile':'macos-dev','files':[{'path':'framework/cjpm.toml','sha256':hashlib.sha256(content).hexdigest()}]}))
        (sdk/'source-lock.json').write_text(json.dumps({'format':2,'profile':'macos-dev','inputs':{'src/a.cj':'a'*64}}))
        result=run('identify.py','--app',app,'--verify-files')
        self.assertEqual(result['references'][0]['file_verification']['status'],'matched')
        self.assertEqual(result['references'][0]['source_lock']['input_count'],1)
        payload={'goal':'x','expected':'y','actual':'z','identity':{'sdk':'old'},'usability':['unclear'],'source_fix':'unknown'}
        f=self.root/'f.json'; f.write_text(json.dumps(payload))
        created=run('feedback.py','create','--app',app,'--input',f)
        payload.update(identity={'sdk':'new'},source_fix='reported in source',sdk_inclusion='unknown',consumer_verification='unknown')
        f.write_text(json.dumps(payload)); run('feedback.py','append','--root',created['root'],'--issue',created['issue'],'--input',f)
        events=run('feedback.py','show','--root',created['root'],'--issue',created['issue'])['events']
        self.assertEqual({e['data']['identity']['sdk'] for e in events},{'old','new'})
        self.assertTrue(all(e['data']['consumer_verification']=='unknown' for e in events))
    def test_manifest_path_traversal_rejected(self):
        app=self.root/'app'; sdk=self.root/'sdk'; fw=sdk/'framework'
        self.package(app,'app','cjgui = { path="../sdk/framework" }'); self.package(fw,'cjgui')
        (sdk/'source-manifest.json').write_text(json.dumps({'files':[{'path':'../secret','sha256':'x'}]}))
        self.assertNotEqual(run('identify.py','--app',app,'--verify-files',ok=False).returncode,0)
    def test_failed_append_cleans_unpublished_evidence_and_list_summary(self):
        app=self.root/'app'; app.mkdir(); good=self.root/'good'; good.write_text('evidence')
        f=self.root/'input.json'; data={'goal':'resize footer','expected':'visible','actual':'hidden','classification':'unclassified'}; f.write_text(json.dumps(data))
        created=run('feedback.py','create','--app',app,'--input',f); root=Path(created['root']); issue=created['issue']
        data['evidence']=[str(good),str(self.root/'missing')]; f.write_text(json.dumps(data))
        self.assertNotEqual(run('feedback.py','append','--root',root,'--issue',issue,'--input',f,ok=False).returncode,0)
        self.assertEqual(list((root/'issues'/issue/'evidence').iterdir()),[])
        listing=run('feedback.py','list','--root',root)['issues'][0]
        self.assertEqual(listing['goal'],'resize footer'); self.assertEqual(listing['latest_classification'],'unclassified')
    def test_default_feedback_root_symlink_and_evidence_limit(self):
        app=self.root/'app'; app.mkdir(); (app/'.cjgui').mkdir(); outside=self.root/'outside'; outside.mkdir()
        (app/'.cjgui'/'feedback').symlink_to(outside, target_is_directory=True)
        f=self.root/'input.json'; f.write_text(json.dumps({'goal':'a','expected':'b','actual':'c'}))
        self.assertNotEqual(run('feedback.py','create','--app',app,'--input',f,ok=False).returncode,0)
        root=self.root/'explicit'; root.mkdir(); big=self.root/'big'
        with big.open('wb') as out: out.truncate(64*1024*1024+1)
        f.write_text(json.dumps({'goal':'a','expected':'b','actual':'c','evidence':[str(big)]}))
        self.assertNotEqual(run('feedback.py','create','--app',app,'--root',root,'--input',f,ok=False).returncode,0)
        self.assertEqual(list((root/'issues').iterdir()),[])
    def test_event_total_limit_cleans_partial_copies(self):
        import importlib.util
        spec=importlib.util.spec_from_file_location('feedback_under_test', SCRIPTS/'feedback.py')
        mod=importlib.util.module_from_spec(spec); spec.loader.exec_module(mod)
        mod.MAX_FILE=10; mod.MAX_EVENT=15
        issue=self.root/'issue'; (issue/'events').mkdir(parents=True); (issue/'evidence').mkdir()
        one=self.root/'one'; two=self.root/'two'; one.write_bytes(b'x'*8); two.write_bytes(b'y'*8)
        with self.assertRaises(ValueError): mod.write_event(issue,{'evidence':[str(one),str(two)],'supersedes':None})
        self.assertEqual(list((issue/'evidence').iterdir()),[]); self.assertEqual(list((issue/'events').iterdir()),[])
    def test_build_provenance_is_report_not_current_verification(self):
        app=self.root/'app'; self.package(app,'app'); build=self.root/'build.json'
        build.write_text(json.dumps({'verified':True,'executable':'/missing','executable_sha256':'0'*64}))
        result=run('identify.py','--app',app,'--build-provenance',build)
        self.assertEqual(result['build']['status'],'metadata_report')
        self.assertEqual(result['build']['current_verification'],'not_performed')
        self.assertTrue(result['build']['recorded_verified'])
    def test_actual_export_layout_and_default_build(self):
        app=self.root/'app'; sdk=self.root/'sdk'; fw=sdk/'framework'/'cjgui'
        self.package(app,'app','cjgui = { path="../sdk/framework/cjgui" }'); self.package(fw,'cjgui')
        (sdk/'source-manifest.json').write_text(json.dumps({'format':2,'files':[]}))
        cache=app/'.cjgui'/'macos-build'; cache.mkdir(parents=True)
        (cache/'build-provenance.json').write_text(json.dumps({'verified':True,'source_files':{'/src/a':'abc'},'prepared_sources':{'/cache/a':'def'}}))
        result=run('identify.py','--app',app)
        self.assertEqual(result['references'][0]['kind'],'export_sdk')
        self.assertEqual(result['build']['status'],'metadata_report')
        self.assertEqual(result['build']['source_files']['count'],1)
        self.assertEqual(len(result['build']['prepared_sources']['index_sha256']),64)
        override=self.root/'override.json'; override.write_text(json.dumps({'build_key':'override'}))
        self.assertEqual(run('identify.py','--app',app,'--build-provenance',override)['build']['build_key'],'override')
    def test_lock_only_legacy_and_captured_not_checkout(self):
        app=self.root/'app'; sdk=self.root/'sdk'; fw=sdk/'framework'/'cjgui'
        self.package(app,'app','cjgui = { path="../sdk/framework/cjgui" }'); self.package(fw,'cjgui')
        (sdk/'source-lock.json').write_text(json.dumps({'src/a.cj':'abc'}))
        result=run('identify.py','--app',app)
        self.assertEqual(result['references'][0]['source_lock']['format'],'legacy')
        self.assertEqual(result['references'][0]['manifest_status'],'unknown')
        (sdk/'source-lock.json').write_text(json.dumps({'format':2,'inputs':{'src/a.cj':'abc'},'categories':{'src/a.cj':'source'}}))
        self.assertEqual(run('identify.py','--app',app)['references'][0]['source_lock']['input_count'],1)
        captured=app/'.cjgui'/'macos-build'/'framework'; self.package(captured,'cjgui')
        (captured/'ACTIVE_DIRECTION.md').write_text('old'); (captured/'native').mkdir()
        self.package(app,'app','cjgui = { path=".cjgui/macos-build/framework" }')
        self.assertEqual(run('identify.py','--app',app)['references'][0]['kind'],'captured_or_unknown')
    def test_mixed_shared_core_sources_are_visible(self):
        app=self.root/'app'; sdk_a=self.root/'a'/'framework'/'cjgui'; sdk_b=self.root/'b'/'framework'/'cjgui'
        self.package(sdk_a,'cjgui','cjgui_shared_operation_core = { path="shared_operation_core" }')
        self.package(sdk_a/'shared_operation_core','cjgui_shared_operation_core')
        self.package(sdk_b/'shared_operation_core','cjgui_shared_operation_core')
        self.package(app,'app',f'cjgui = {{ path="{sdk_a}" }}\ncjgui_shared_operation_core = {{ path="{sdk_b}/shared_operation_core" }}')
        result=run('identify.py','--app',app)
        self.assertEqual({x['path'] for x in result['supporting_dependencies']},{str((sdk_a/'shared_operation_core').resolve()),str((sdk_b/'shared_operation_core').resolve())})
        self.assertTrue(all(len(x['manifest_sha256'])==64 for x in result['supporting_dependencies']))
        self.assertTrue(any('mixed' in w and 'cjgui_shared_operation_core' in w for w in result['warnings']))
    def test_copy_outside_package(self):
        dst=self.root/'scripts'; shutil.copytree(SCRIPTS,dst)
        p=subprocess.run([sys.executable,str(dst/'feedback.py'),'template'],text=True,capture_output=True)
        self.assertEqual(p.returncode,0,p.stderr); self.assertIn('goal',json.loads(p.stdout))

if __name__=='__main__': unittest.main()

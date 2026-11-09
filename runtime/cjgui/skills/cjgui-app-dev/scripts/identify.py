#!/usr/bin/env python3
"""Report observed CJGUI references, build provenance and runtime evidence separately."""
import argparse
import hashlib
import json
from pathlib import Path
import sys
try:
    import tomllib
except ImportError:
    print('cjgui-app-dev requires Python 3.11+ for dependency lookup; '
          f'current interpreter: {sys.executable} ({sys.version.split()[0]}). '
          'Use an available Python 3.11+ interpreter (for example python3.11).', file=sys.stderr)
    sys.exit(2)


def read_json(path):
    try:
        with path.open(encoding='utf-8') as f:
            value = json.load(f)
    except json.JSONDecodeError as error:
        raise ValueError(f'{path}: {error}') from error
    if not isinstance(value, dict):
        raise ValueError(f'expected JSON object: {path}')
    return value


def sha(path):
    h = hashlib.sha256()
    with path.open('rb') as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b''):
            h.update(chunk)
    return h.hexdigest()


def safe_child(root, name):
    p = (root / name).resolve()
    if not p.is_relative_to(root.resolve()) or Path(name).is_absolute():
        raise ValueError('manifest path escapes SDK')
    return p


def app_path(value):
    if not str(value).strip():
        raise argparse.ArgumentTypeError('app path must not be empty')
    path = Path(value).expanduser()
    return path.parent if path.name == 'cjpm.toml' else path


def identify(app, verify):
    manifest = app / 'cjpm.toml'
    if not app.is_dir() or not manifest.is_file():
        raise ValueError(f'app requires an existing cjpm.toml: {manifest}; '
                         'for a new application, create it from the selected SDK first')
    try:
        with manifest.open('rb') as f:
            tomllib.load(f)
    except tomllib.TOMLDecodeError as error:
        raise ValueError(f'{manifest}: {error}') from error
    todo = [app.resolve()]; seen = set(); refs = []; supporting = []; warnings = []
    while todo and len(seen) < 256:
        root = todo.pop()
        if root in seen: continue
        seen.add(root)
        try:
            with (root / 'cjpm.toml').open('rb') as f: data = tomllib.load(f)
        except (OSError, tomllib.TOMLDecodeError) as e:
            warnings.append(f'cannot read dependency manifest {root}: {e}'); continue
        package = data.get('package', {})
        if package.get('name') == 'cjgui_shared_operation_core':
            supporting.append({'name':'cjgui_shared_operation_core','path':str(root),'manifest':str(root / 'cjpm.toml'),'manifest_sha256':sha(root / 'cjpm.toml')})
        if package.get('name') == 'cjgui':
            roots = (root, root.parent, root.parent.parent)
            sdk = next((p for p in roots if (p / 'source-manifest.json').is_file()), None)
            lock_root = next((p for p in roots if (p / 'source-lock.json').is_file()), None)
            repo = root.parent.parent
            checkout = (root.name == 'cjgui' and root.parent.name == 'runtime' and (repo / '.git').exists() and '.cjgui' not in root.parts)
            kind = 'export_sdk' if sdk else ('checkout' if checkout else 'captured_or_unknown')
            ref = {'path': str(root), 'kind': kind, 'identity_status': 'unknown', 'manifest_status':'unknown', 'docs': []}
            for rel in ('README.md', 'LAYOUT_PRIMITIVES.md', 'STYLE_ROLES.md', 'preview/MACOS_DEVELOPER_QUICKSTART.md'):
                p = root / rel
                if p.is_file(): ref['docs'].append(str(p))
            if lock_root:
                lock=lock_root/'source-lock.json'; info=read_json(lock)
                if info.get('format') == 2 and isinstance(info.get('inputs'),dict):
                    lock_format='format2'; inputs=info['inputs']; coverage='reported_delivery_closure'
                elif info and all(isinstance(k,str) and isinstance(v,str) for k,v in info.items()):
                    lock_format='legacy'; inputs=info; coverage='reported_cj_sources_only'
                else:
                    lock_format='unknown'; inputs={}; coverage='unknown'
                ref['source_lock']={'path':str(lock),'format':lock_format,'profile':info.get('profile'),'sha256':sha(lock),'input_count':len(inputs) if lock_format != 'unknown' else None,'coverage':coverage,'verification':'not_performed'}
            if sdk:
                if (sdk / 'README.md').is_file(): ref['docs'].append(str(sdk / 'README.md'))
                manifest = read_json(sdk / 'source-manifest.json')
                ref.update(manifest_path=str(sdk / 'source-manifest.json'), manifest_status='reported', manifest_format=manifest.get('format'), profile=manifest.get('profile'), exported_content_sha256=manifest.get('exported_content_sha256'), source_content_sha256=manifest.get('source_content_sha256'), identity_status='reported')
                if lock_root and lock_root != sdk: warnings.append('manifest and source lock found in different directories; association unknown')
                if verify:
                    files = manifest.get('files'); mismatches=[]; checked=0
                    if not isinstance(files, list): raise ValueError('manifest files must be a list')
                    for item in files:
                        if not isinstance(item, dict) or not isinstance(item.get('path'), str) or not isinstance(item.get('sha256'), str): raise ValueError('invalid manifest file entry')
                        p = safe_child(sdk, item['path']); checked += 1
                        if not p.is_file() or sha(p) != item['sha256']: mismatches.append(item['path'])
                    ref['file_verification'] = {'status':'mismatch' if mismatches else ('matched' if checked else 'unknown'), 'checked':checked, 'mismatches':mismatches}
            elif verify:
                ref['file_verification']={'status':'unknown','reason':'source manifest unavailable'}
            refs.append(ref)
        workspace = data.get('workspace')
        if isinstance(workspace, dict):
            members = workspace.get('members', [])
            warnings.append(f'workspace {root}: scanning declared members for references; '
                            'this is not build selection or member runtime evidence; '
                            'use --app MEMBER for its build provenance')
            if not isinstance(members, list):
                warnings.append(f'workspace members must be a list in {root}; member sources unknown')
            else:
                for member in members:
                    if not isinstance(member, str) or not member.strip():
                        warnings.append(f'invalid workspace member in {root}; member source unknown')
                    elif any(c in member for c in '*?['):
                        warnings.append(f'workspace member pattern is not resolved: {root / member}; inspect an explicit member')
                    else:
                        todo.append((root / member).resolve())
        deps = data.get('dependencies', {})
        if isinstance(deps, dict):
            for dep in deps.values():
                if isinstance(dep, dict) and isinstance(dep.get('path'), str): todo.append((root / dep['path']).resolve())
                else: warnings.append(f'non-path dependency in {root}; its source is unknown')
    if todo: warnings.append('dependency traversal limit reached (256 packages)')
    if not refs: warnings.append('no CJGUI source found in traversed local manifests; inspect the member/dependency warnings and selected app path')
    if len(refs)>1: warnings.append('multiple CJGUI references; actual build selection requires provenance')
    expected = {(Path(ref['path']) / 'shared_operation_core').resolve() for ref in refs}
    observed = {Path(item['path']).resolve() for item in supporting}
    if expected and observed - expected:
        warnings.append('mixed cjgui_shared_operation_core source paths: ' + ', '.join(sorted(str(p) for p in observed - expected)) + '; actual build selection unknown')
    if refs and not observed:
        warnings.append('cjgui_shared_operation_core source is unknown; dependency may be non-path or unavailable')
    return refs, supporting, warnings


def main():
    p=argparse.ArgumentParser(description=__doc__); p.add_argument('--app',required=True,type=app_path,help='existing application directory or cjpm.toml; create new apps first'); p.add_argument('--build-provenance',type=Path); p.add_argument('--runtime-evidence',type=Path); p.add_argument('--verify-files',action='store_true'); a=p.parse_args()
    app = a.app
    refs,supporting,warnings=identify(app,a.verify_files)
    build={'status':'unknown'}; runtime={'status':'unknown'}
    provenance = a.build_provenance or (app / '.cjgui' / 'macos-build' / 'build-provenance.json')
    if a.build_provenance or provenance.is_file():
        d=read_json(provenance)
        keys=('format','framework_source','application_source','source_application','native_libraries','renderer_archive','renderer_sha256','build_key','executable','executable_sha256','actual_native_members')
        build={'status':'metadata_report','current_verification':'not_performed','recorded_verified':d.get('verified'), 'provenance':str(provenance.resolve()),**{k:d[k] for k in keys if k in d}}
        for name in ('source_files','prepared_sources'):
            index=d.get(name)
            if isinstance(index,dict):
                encoded=json.dumps(index,sort_keys=True,ensure_ascii=False,separators=(',',':')).encode()
                build[name]={'count':len(index),'index_sha256':hashlib.sha256(encoded).hexdigest(),'verification':'not_performed'}
            else: build[name]={'status':'unknown'}
        if refs and d.get('framework_source'):
            src=Path(d['framework_source']).resolve(); ref=Path(refs[0]['path']).resolve()
            if not src.is_relative_to(ref): warnings.append('build framework source differs from reference; prepared copies may explain this, inspect provenance')
        if d.get('native_libraries') and refs:
            warnings.append('native archives are separate build inputs; inspect provenance and link evidence for mixed sources')
    if a.runtime_evidence:
        d=read_json(a.runtime_evidence)
        keys=('executable','executable_sha256','pid','bundle_id','platform','observed_at')
        runtime={'status':'reported','evidence':str(a.runtime_evidence.resolve()),**{k:d[k] for k in keys if k in d}}
        if not any(k in d for k in ('executable','executable_sha256','pid','bundle_id')): runtime['status']='unknown'
    print(json.dumps({'app':str(app.resolve()),'references':refs,'supporting_dependencies':supporting,'build':build,'runtime':runtime,'warnings':warnings},ensure_ascii=False,indent=2))

if __name__=='__main__':
    try: main()
    except (OSError, ValueError, TypeError, json.JSONDecodeError) as e:
        print(f'identify: {e}',file=sys.stderr); sys.exit(2)

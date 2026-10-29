#!/usr/bin/env zsh
set -euo pipefail

usage() {
  print -u2 'usage: export_framework_preview.sh DESTINATION [--profile full|macos-dev] [--source-lock JSON] [--write-source-lock JSON]'
  exit 2
}
(( $# >= 1 )) || usage
DESTINATION="$1"
shift
PROFILE=full
SOURCE_LOCK=''
WRITE_SOURCE_LOCK=''
while (( $# > 0 )); do
  (( $# >= 2 )) || usage
  case "$1" in
    --profile) PROFILE="$2" ;;
    --source-lock) SOURCE_LOCK="$2" ;;
    --write-source-lock) WRITE_SOURCE_LOCK="$2" ;;
    *) usage ;;
  esac
  shift 2
done
[[ "$PROFILE" == full || "$PROFILE" == macos-dev ]] || usage
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUNTIME_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REPOSITORY_ROOT="$(cd "$RUNTIME_DIR/../.." && pwd)"
source "$RUNTIME_DIR/native/scripts/lib_cjgui_source_set.sh"
if [[ -e "$DESTINATION" || -L "$DESTINATION" ]]; then
  print -u2 -- "cjgui preview: destination already exists: $DESTINATION"
  exit 2
fi
mkdir -p "$(dirname "$DESTINATION")"
DESTINATION_PARENT="$(cd "$(dirname "$DESTINATION")" && pwd)"
DESTINATION="$DESTINATION_PARENT/$(basename "$DESTINATION")"
STAGING_DIR="$(mktemp -d "$DESTINATION_PARENT/.$(basename "$DESTINATION").cjgui-preview.XXXXXX")"
cleanup() { rm -rf "$STAGING_DIR"; }
trap cleanup EXIT
trap 'exit 130' HUP INT TERM

typeset -a PACKAGE_INPUTS
PACKAGE_INPUTS=(
  "${(@f)$(cjgui_package_source_paths "$RUNTIME_DIR")}"
  "${(@f)$(cjgui_package_source_paths "$RUNTIME_DIR/shared_operation_core")}"
  "${(@f)$(cjgui_macos_native_source_paths "$RUNTIME_DIR/native")}"
)
python3 - "$RUNTIME_DIR" "$REPOSITORY_ROOT" "$STAGING_DIR" "$PROFILE" "$SOURCE_LOCK" "$WRITE_SOURCE_LOCK" "${PACKAGE_INPUTS[@]}" <<'PY'
from pathlib import Path
import hashlib
import json
import os
import re
import shutil
import sys

runtime, repository, stage = map(Path, sys.argv[1:4])
profile = sys.argv[4]
source_lock = Path(sys.argv[5]).resolve() if sys.argv[5] else None
write_source_lock = Path(sys.argv[6]).resolve() if sys.argv[6] else None
locked = json.loads(source_lock.read_text()) if source_lock else None
# Two lock formats share this one exit:
#   * closure (format 2): the lock names EVERY delivered input (source, native,
#     build script, scripts, config, templates, assets) with its raw SHA-256, so a
#     native/script change cannot pass while only .cj files are pinned. The set
#     must match the delivery closure exactly: an added or dropped input is a
#     refusal, not a silent omission.
#   * flat legacy map (path -> .cj SHA-256): the older release lock. Kept
#     byte-compatible because older release procedures still produce it.
lock_mode = 'none'
locked_inputs = None
if locked is not None:
    if isinstance(locked, dict) and locked.get('format') == 2:
        lock_mode = 'closure'
        locked_inputs = locked['inputs']
    else:
        lock_mode = 'legacy'
package_inputs = {Path(value) for value in sys.argv[7:]}
if lock_mode == 'legacy':
    package_inputs = {p for p in package_inputs if p.suffix != '.cj' or p.relative_to(runtime).as_posix() in locked}
framework = Path('framework/cjgui')
ignored = {'target', '.cjgui', 'artifacts', '__pycache__', '.DS_Store', '.git', 'build-script-cache'}
plan = {}


def source_category(source):
    """The delivery role of one shipped input, used for drift diagnostics and
    for the closure summary. It is derived from the path, never hand-listed."""
    relative = source.relative_to(runtime).as_posix() if source.is_relative_to(runtime) else 'repository/' + source.name
    if relative.startswith('repository/'):
        return 'license'
    if relative == 'src/macos_owner_fixture_test.cj':
        return 'test-fixture'
    if relative == 'build.cj':
        return 'build'
    if relative.startswith('native/'):
        if relative.endswith(('.m', '.h')):
            return 'native'
        return 'script'
    if relative.startswith('templates/'):
        return 'template'
    if relative.startswith('resources/'):
        return 'asset'
    if relative.endswith('.cj'):
        return 'source'
    if relative.endswith('.toml'):
        return 'config'
    if relative.endswith(('.sh', '.py')):
        return 'script'
    if relative.endswith('.md'):
        return 'doc'
    return 'asset'


def lock_key(source):
    if source.is_relative_to(runtime):
        return source.relative_to(runtime).as_posix()
    return 'repository/' + source.name


def add(source, relative, replacement=None):
    source, relative = Path(source), Path(relative).as_posix()
    if source.is_symlink() or not source.is_file():
        raise ValueError(f'required regular source is missing: {source}')
    if source.suffix == '.cj' and source != runtime / 'build.cj' and lock_mode == 'legacy':
        key = source.relative_to(runtime).as_posix()
        if key not in locked:
            return  # Concurrent, unaccepted leaf modules are outside this release.
        if hashlib.sha256(source.read_bytes()).hexdigest() != locked[key]:
            raise ValueError(f'source lock changed: {key}')
    if relative in plan:
        raise ValueError(f'duplicate export destination: {relative}')
    plan[relative] = (source, replacement)


def source_files(source):
    for directory, subdirectories, filenames in os.walk(source, followlinks=False):
        subdirectories[:] = sorted(name for name in subdirectories if name not in ignored)
        for name in subdirectories + sorted(filenames):
            path = Path(directory) / name
            if path.is_symlink():
                raise ValueError(f'export does not follow source symlinks: {path}')
        for name in sorted(filenames):
            if name not in ignored and not name.endswith(('.cj.orig', '.cj.rej')):
                yield Path(directory) / name


def tree(source, relative, require_application_sources=False):
    for path in source_files(source):
        target = Path(relative) / path.relative_to(source)
        add(path, target)
        if (require_application_sources and path.suffix == '.cj' and not path.name.endswith('_test.cj')
                and target.as_posix() not in plan):
            raise ValueError(f'source lock omitted required template/application source: {path.relative_to(runtime)}')


def rewrite_dependencies(text, replacements):
    for name, value in replacements.items():
        text = re.sub(rf'(?m)^(\s*{re.escape(name)}\s*=\s*\{{\s*path\s*=\s*)"[^"]+"',
                      lambda match: match[1] + json.dumps(value), text)
    return text


for source in sorted(package_inputs):
    add(source, framework / source.relative_to(runtime))
if source_lock:
    add(source_lock, 'source-lock.json')
for package in [Path('.'), Path('shared_operation_core')]:
    add(runtime / package / 'cjpm.toml', framework / package / 'cjpm.toml')
add(runtime / 'build.cj', framework / 'build.cj')
add(runtime / 'native/scripts/build_cjgui_internal_renderer_sidecar.sh',
    framework / 'native/scripts/build_cjgui_internal_renderer_sidecar.sh')
for name in ['LICENSE', 'NOTICE']:
    for relative in [Path(name), framework / name, framework / 'shared_operation_core' / name]:
        add(repository / name, relative)
for source in sorted((runtime / 'shared_operation_core').glob('*.py')):
    if not source.name.startswith('test_') and not source.name.endswith('_test.py'):
        add(source, framework / 'shared_operation_core' / source.name)
# The editing guide is part of the public client contract, not incidental
# documentation: ship it beside the API it documents.
add(runtime / 'shared_operation_core/GENERATED_EDITING.md',
    framework / 'shared_operation_core/GENERATED_EDITING.md')
tree(runtime / 'resources', framework / 'resources')
tree(runtime / 'templates/macos_application', framework / 'templates/macos_application', require_application_sources=True)
# Mixed template tests call this framework-owned AppKit fixture. Ship a
# package-renamed copy beside the tests so an extracted SDK is test-closed.
owner_fixture = runtime / 'src/macos_owner_fixture_test.cj'
if owner_fixture.is_file():
    if lock_mode == 'legacy' and owner_fixture.relative_to(runtime).as_posix() not in locked:
        raise ValueError('source lock omitted required mixed template test dependency: src/macos_owner_fixture_test.cj')
    mixed = runtime / 'templates/macos_application/mixed_form'
    manifest = (mixed / 'cjpm.toml').read_text()
    package_match = re.search(r'(?m)^\s*name\s*=\s*"([^"]+)"', manifest)
    if not package_match:
        raise ValueError('mixed_form package name is required for owner fixture test closure')
    fixture_text = owner_fixture.read_text()
    if fixture_text.count('package cjgui') != 1:
        raise ValueError('owner fixture must declare the cjgui framework package exactly once')
    fixture_text = re.sub(r'(?m)^package cjgui$', 'package ' + package_match[1], fixture_text, count=1)
    add(owner_fixture, Path('framework/cjgui/templates/macos_application/mixed_form/src/cjgui_macos_owner_fixture_test.cj'),
        fixture_text)
else:
    raise ValueError('required mixed template test dependency is missing: src/macos_owner_fixture_test.cj')
for name in ['run_macos_application.sh', 'create_macos_application.sh', 'macos_build_config.py']:
    add(runtime / 'scripts' / name, framework / 'scripts' / name)
add(runtime / 'native/scripts/lib_cjgui_source_set.sh', framework / 'native/scripts/lib_cjgui_source_set.sh')
add(runtime / 'native/scripts/verify_cjpm_mac_testing_link.py',
    framework / 'native/scripts/verify_cjpm_mac_testing_link.py')
add(runtime / 'MACOS_APPLICATION_HOST.md', framework / 'MACOS_APPLICATION_HOST.md')
for name in ['LAYOUT_PRIMITIVES.md', 'FIELD_CONTROLS.md', 'CARD_GRID.md', 'ACCESSIBILITY.md', 'FONT_RESOURCES.md', 'STYLED_TEXT.md']:
    add(runtime / name, framework / name)
add(runtime / 'preview/MACOS_CANDIDATE.md', 'MACOS-CANDIDATE.md',
    (runtime / 'preview/MACOS_CANDIDATE.md').read_text())
add(runtime / 'preview/FRAMEWORK_PREVIEW_MANIFEST.md', 'preview-manifest.md',
    (runtime / 'preview/FRAMEWORK_PREVIEW_MANIFEST.md').read_text())
add(runtime / 'preview/MACOS_DEVELOPER_QUICKSTART.md', 'README.md',
    (runtime / 'preview/MACOS_DEVELOPER_QUICKSTART.md').read_text())
add(runtime / 'preview/MACOS_DEVELOPER_QUICKSTART.md',
    framework / 'preview/MACOS_DEVELOPER_QUICKSTART.md',
    '# macOS开发预览\n\n[从包根快速开始](../../../README.md)。\n')
if profile == 'macos-dev':
    add(runtime / 'README.md', framework / 'README.md',
        '# CJGUI macOS framework source\n\n[快速开始](../../README.md) · '
        '[应用宿主](MACOS_APPLICATION_HOST.md) · '
        '[混合表单接入](templates/macos_application/mixed_form/README.md) · '
        '[生成界面编辑](shared_operation_core/GENERATED_EDITING.md)\n\n'
        'Experimental，macOS Apple Silicon / Cangjie 1.1.3。原生缓存由正常 runner 从本包源码生成。\n')
else:
    add(runtime / 'README.md', framework / 'README.md')
client_readme = runtime / 'shared_operation_core/README.md'
add(client_readme if client_readme.exists() else runtime / 'README.md',
    framework / 'shared_operation_core/README.md',
    '# Shared operation clients\n\n[本包快速开始](../../../README.md)。'
    '`client.py` 是通用 descriptor 客户端；`cjgui_generated_client.py` 是同一协议的 typed generated-UI 层。'
    '生成界面的保存计划、跨进程应用与拒绝/恢复见 [GENERATED_EDITING.md](GENERATED_EDITING.md)。'
    '运行应用显式启用连接后才有 descriptor；动作、参数与授权从实际应用发现。'
    '不包含模型服务，不保有第二份业务状态。\n')

if profile in ['full', 'macos-dev']:
    application = runtime / 'examples/rule_set_application'
    if not application.exists():
        raise ValueError('required collection dependency is missing: rule_set_application')
    if application.exists():
        for path in source_files(application):
            relative = path.relative_to(application)
            if any(part in ignored for part in relative.parts) or not path.is_file():
                continue
            value = None
            if relative.as_posix() == 'cjpm.toml':
                value = rewrite_dependencies(path.read_text(),
                    {'cjgui': '../cjgui', 'cjgui_shared_operation_core': '../cjgui/shared_operation_core'})
            add(path, Path('framework/rule_set_application') / relative, value)
    consumers = ['generated_collection', 'rule_set_window_app']
    if profile == 'full':
        consumers += ['tree_outline_consumer', 'generated_panel_consumer', 'adaptive_layout_public_consumer']
    for name in consumers:
        source = runtime / 'examples' / name
        if not source.exists():
            if name in ['generated_collection', 'rule_set_window_app']:
                raise ValueError(f'required consumer is missing: {name}')
            continue  # Preserve full profile's older optional consumers.
        target = Path('consumers') / name
        tree(source / 'src', target / 'src')
        for filename in ['cjpm.toml', 'run.sh', 'cjgui_macos_app.sh', 'cjgui_macos_unified.sh', 'README.md', 'client.py',
                         'COLLECTION_SELECTION.md', 'COLLECTION_VIEWS.md', 'TABLE_COMPONENT.md']:
            path = source / filename
            if not path.is_file():
                continue
            value = None
            if filename == 'cjpm.toml':
                value = rewrite_dependencies(path.read_text(),
                    {'cjgui': '../../framework/cjgui',
                     'cjgui_shared_operation_core': '../../framework/cjgui/shared_operation_core',
                     'cjgui_rule_set_application': '../../framework/rule_set_application'})
            elif filename == 'run.sh':
                value = path.read_text().replace('$CJGUI_ROOT/scripts/run_macos_application.sh',
                    '$CJGUI_ROOT/framework/cjgui/scripts/run_macos_application.sh').replace(
                    '$APP_DIR/../../scripts/run_macos_application.sh',
                    '$APP_DIR/../../framework/cjgui/scripts/run_macos_application.sh')
            elif filename == 'client.py':
                value = path.read_text().replace('parents[2] / "shared_operation_core"',
                    'parents[2] / "framework/cjgui/shared_operation_core"')
            add(path, target / filename, value)
        if name == 'generated_panel_consumer':
            for path in sorted(source.glob('verify_*.py')):
                add(path, target / path.name)

# Source documentation moves with its code. Relocate links to shipped files;
# unshipped historical evidence remains labelled text, not a broken dependency
# on the author's checkout. Authored package-root guides already use package
# paths and are supplied as explicit replacements above.
destinations = {source.resolve(): relative for relative, (source, _) in plan.items()}
def relocate_document(source, relative):
    def link(match):
        label, target = match[1], match[2].strip('<>')
        if target.startswith(('https:', 'http:', 'mailto:', '#')):
            return match[0]
        target_path, separator, anchor = target.partition('#')
        target_path = re.sub(r':\d+$', '', target_path)
        resolved = (source.parent / target_path).resolve()
        chosen = destinations.get(resolved)
        if chosen is None and resolved.is_dir():
            children = [p for original, p in destinations.items() if original.parent == resolved]
            if children:
                chosen = str(Path(children[0]).parent)
        if chosen is None:
            return label + '（仓库参考，未随包）'
        relocated = os.path.relpath(chosen, Path(relative).parent)
        if separator: relocated += '#' + anchor
        return '[' + label + '](<' + relocated + '>)'
    return re.sub(r'\[([^\]]+)\]\((<[^>]+>|[^)]+)\)', link, source.read_text())
for relative, (source, replacement) in list(plan.items()):
    if source.suffix == '.md' and replacement is None:
        plan[relative] = (source, relocate_document(source, relative))

original = {source: hashlib.sha256(source.read_bytes()).hexdigest() for source, _ in plan.values()}

# The DELIVERY CLOSURE: every shipped input that carries behaviour or identity
# (source, native/ABI, build.cj, scripts, config, templates, assets, license),
# keyed by its raw source path and SHA-256. Documentation is deliberately out of
# the closure: it is relocated/rewritten on export and is not an input contract.
# The generated-UI editing guide is the one exception: it is the usage contract
# for the public client, so consumer code and its usage text are pinned together.
essential_closure_docs = {runtime / 'shared_operation_core/GENERATED_EDITING.md'}
closure = {}
closure_categories = {}
# A source is one input even when the package ships it at several destinations
# (LICENSE/NOTICE, shared helpers), so the closure is keyed by SOURCE identity.
excluded_closure_sources = {p for p in (source_lock, write_source_lock) if p is not None}
for source in sorted(set(source for source, _ in plan.values())):
    if source in excluded_closure_sources:
        continue  # The lock file ships as data; it cannot contain its own digest.
    category = source_category(source)
    if category == 'doc' and source not in essential_closure_docs:
        continue
    key = lock_key(source)
    closure[key] = original[source]
    closure_categories[key] = category
if lock_mode == 'closure':
    # Refuse BEFORE writing anything. The three failure texts name the input and
    # its role, so a native/script drift is distinguishable from a source drift.
    for key, expected in sorted(locked_inputs.items()):
        category = locked.get('categories', {}).get(key, source_category(runtime / key)
                                                    if (runtime / key).is_file() else 'unknown')
        if key not in closure:
            raise ValueError(f'source lock names an input this export does not deliver: {key} ({category})')
        if closure[key] != expected:
            raise ValueError(f'source lock changed: {key} ({category}) '
                             f'expected={expected} actual={closure[key]}')
    for key, digest in sorted(closure.items()):
        if key not in locked_inputs:
            raise ValueError(f'source lock omitted a delivered input: {key} ({closure_categories[key]})')

files = []
for relative, (source, replacement) in sorted(plan.items()):
    destination = stage / relative
    destination.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(source, destination)
    if replacement is not None:
        destination.write_text(replacement)
    if replacement is None and hashlib.sha256(destination.read_bytes()).hexdigest() != original[source]:
        raise RuntimeError(f'source changed while copying: {source}')
    source_relative = (source.relative_to(runtime).as_posix() if source.is_relative_to(runtime)
                       else 'repository/' + source.name)
    files.append({'path': relative, 'source': source_relative,
                  'source_sha256': original[source],
                  'sha256': hashlib.sha256(destination.read_bytes()).hexdigest(),
                  'size': destination.stat().st_size,
                  'origin': 'rewritten' if replacement is not None else 'identical'})
changed = [str(source) for source, digest in original.items()
           if hashlib.sha256(source.read_bytes()).hexdigest() != digest]
current_inputs = {p for package in [runtime, runtime / 'shared_operation_core']
                  for p in (package / 'src').glob('*.cj') if not p.name.endswith('_test.cj')}
current_inputs.update(p for p in (runtime / 'native').iterdir() if p.suffix in ['.m', '.h'])
if lock_mode == 'legacy':
    current_inputs = {p for p in current_inputs if p.suffix != '.cj' or p.relative_to(runtime).as_posix() in locked}
if changed or (lock_mode == 'legacy' and current_inputs != package_inputs):
    raise RuntimeError(f'export source changed during capture; retry after source settles: {changed}')
closure_categories_counted = {}
for category in closure_categories.values():
    closure_categories_counted[category] = closure_categories_counted.get(category, 0) + 1
lock_payload = {'format': 2, 'profile': profile,
                'source_origin': 'runtime/cjgui delivery closure (source, native/ABI, build, scripts, config, templates, assets)',
                'inputs': dict(sorted(closure.items())),
                'categories': dict(sorted(closure_categories.items()))}
lock_bytes = (json.dumps(lock_payload, ensure_ascii=False, indent=2, sort_keys=True) + '\n').encode()
manifest = {'format': 2, 'profile': profile,
            'source_origin': 'runtime/cjgui and repository LICENSE/NOTICE',
            'production_package_sources': sum(p.suffix == '.cj' for p in package_inputs),
            'source_content_sha256': hashlib.sha256(json.dumps(
                [(f['path'], f['source_sha256']) for f in files], separators=(',', ':')).encode()).hexdigest(),
            'exported_content_sha256': hashlib.sha256(json.dumps(
                [(f['path'], f['sha256']) for f in files], separators=(',', ':')).encode()).hexdigest(),
            'delivery_closure': {'inputs': len(closure), 'categories': dict(sorted(closure_categories_counted.items())),
                                 'closure_sha256': hashlib.sha256(json.dumps(
                                     sorted(closure.items()), separators=(',', ':')).encode()).hexdigest()},
            'source_lock': {'mode': lock_mode,
                            'sha256': hashlib.sha256(lock_bytes).hexdigest() if lock_mode == 'closure' else '',
                            'inputs': len(locked_inputs) if locked_inputs is not None else 0},
            'source_drift': [], 'files': files}
(stage / 'source-manifest.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + '\n')
if write_source_lock is not None:
    if write_source_lock.is_relative_to(Path(stage)):
        raise ValueError(f'source lock must be written outside the exported tree: {write_source_lock}')
    pending = write_source_lock.with_name(write_source_lock.name + '.pending')
    pending.write_bytes(lock_bytes)
    os.replace(pending, write_source_lock)
print(f'cjgui preview: profile={profile} files={len(files)} content_sha256={manifest["exported_content_sha256"]} '
      f'closure={len(closure)} lock={lock_mode}')
PY
mv "$STAGING_DIR" "$DESTINATION"
trap - EXIT HUP INT TERM
print -r -- "cjgui preview: exported=$DESTINATION"

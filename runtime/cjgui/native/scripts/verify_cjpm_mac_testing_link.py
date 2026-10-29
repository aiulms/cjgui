#!/usr/bin/env python3
"""Selected package tests linked to a separate testing archive, never native/lib.

Reuses the ordinary source/config helpers and shared four-member native builder.
One owned graph per --output is retired in finally unless --keep-build is set.
Consumer tests use the standard Cangjie runner and the same four renderer
members; the application-only interposed runtime launcher is never linked.
"""
from __future__ import annotations
import argparse
import fcntl
import importlib.util
import json
import os
from pathlib import Path
import re
import shutil
import signal
import subprocess
import tarfile
import time


OWNER_FIXTURE = 'cjgui_macos_owner_fixture_test.cj'
OWNER_FIXTURE_CALL = re.compile(r'\bcjguiMacosOwnerTest\s*\(')


def ensure_consumer_owner_fixture(consumer_source: Path, runtime: Path, package: Path,
                                  sources: dict[str, str], package_name: str,
                                  digest) -> None:
    """Supply the SDK-owned AppKit test helper only to consumers that use it.

    An existing consumer copy is source input and is never overwritten. Exported
    SDKs keep the framework-owned original under mixed_form; generic consumers
    such as the Rules app can reuse that source with their own package name.
    """
    destination = package / 'src' / OWNER_FIXTURE
    if destination.is_file():
        return
    source_files = [p for p in consumer_source.rglob('*.cj') if p.is_file() and not p.is_symlink()]
    source_texts = [p.read_text(errors='replace') for p in source_files]
    if not any(OWNER_FIXTURE_CALL.search(text) for text in source_texts):
        return
    if any(re.search(r'(?m)^\s*func\s+cjguiMacosOwnerTest\s*\(', text) for text in source_texts):
        return

    candidates = [runtime / 'src/macos_owner_fixture_test.cj',
                  runtime / 'templates/macos_application/mixed_form/src' / OWNER_FIXTURE]
    fixture = next((candidate for candidate in candidates if candidate.is_file()), None)
    if fixture is None:
        raise ValueError('consumer tests use cjguiMacosOwnerTest but the SDK has no owner fixture source')
    text = fixture.read_text()
    declaration = re.findall(r'(?m)^package\s+([A-Za-z_][A-Za-z0-9_.]*)\s*$', text)
    if declaration not in (['cjgui'], ['cjgui_mixed_form_starter']):
        raise ValueError('owner fixture source has an unsupported package declaration')
    text = re.sub(r'(?m)^package[ \t]+[A-Za-z_][A-Za-z0-9_.]*[ \t]*$',
                  'package ' + package_name, text, count=1)
    destination.parent.mkdir(parents=True, exist_ok=True)
    with destination.open('x', encoding='utf-8') as output:
        output.write(text)
    sources[str(fixture)] = digest(fixture)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path)
    parser.add_argument('--runtime', type=Path, help='Test an exact exported runtime source/ABI pair')
    parser.add_argument('--consumer', type=Path, help='Test a normal application package with an isolated target and standard unittest entry')
    parser.add_argument('--filter', action='append', help='Execute only this selection; repeatable')
    parser.add_argument('--source-lock', type=Path, help='Accepted runtime-relative .cj paths and SHA256 values')
    parser.add_argument('--keep-build', action='store_true', help='Keep the one owned build graph for diagnosis')
    args = parser.parse_args()
    runtime = (args.runtime or Path(__file__).resolve().parents[2]).resolve()
    output = (args.output or runtime / '.cjgui/macos-tests').resolve()
    output.mkdir(parents=True, exist_ok=True)
    consumer = args.consumer.resolve() if args.consumer else None
    if consumer and args.source_lock:
        parser.error('--source-lock selects framework tests only')
    package = output / ('application' if consumer else 'package')
    owner = output / 'owner.json'
    identity = {'runtime': str(runtime)}
    if consumer: identity['consumer'] = str(consumer)
    if owner.exists() and json.loads(owner.read_text()) != identity:
        parser.error('output belongs to another runtime')
    if package.exists() and not owner.exists():
        parser.error('output contains an unowned package')
    owner.write_text(json.dumps(identity) + '\n')
    lock = (output / 'build.lock').open('a')
    fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
    sdk = os.environ.get('CJ_GUI_SDKROOT') or subprocess.check_output(
        ['xcrun', '--sdk', 'macosx', '--show-sdk-path'], text=True).strip()
    cangjie = os.environ.get('CANGJIE_HOME')
    if not cangjie:
        parser.error('CANGJIE_HOME must identify the installed Cangjie toolchain')
    spec = importlib.util.spec_from_file_location('cjgui_build_inputs', runtime / 'scripts/macos_build_config.py')
    build = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(build)
    normal = runtime / 'native/lib/libcjgui_internal_renderer.a'
    before = build.digest(normal) if normal.exists() else None
    env = dict(os.environ, CJ_GUI_SDKROOT=sdk)
    env.pop('CJGUI_NATIVE_CLANG_FLAGS_APPEND', None)
    env['DYLD_LIBRARY_PATH'] = str(Path(cangjie) / 'runtime/lib/darwin_aarch64_cjnative')
    steps, sources = [], {}
    rc = 1
    result = {'runtime': str(runtime), 'package': str(package), 'native_mode': 'testing'}

    def cancelled(signum, frame):
        raise KeyboardInterrupt()
    signal.signal(signal.SIGTERM, cancelled)

    def run(label, command, cwd=runtime):
        began = time.monotonic_ns()
        with (output / (label + '.log')).open('wb') as log:
            child = subprocess.Popen(command, cwd=cwd, env=env, stdout=log,
                                     stderr=subprocess.STDOUT, start_new_session=True)
            try:
                status = child.wait(timeout=600)
            finally:
                if child.poll() is None:
                    os.killpg(child.pid, signal.SIGTERM)
                    try:
                        child.wait(timeout=5)
                    except subprocess.TimeoutExpired:
                        os.killpg(child.pid, signal.SIGKILL)
                        child.wait()
        step = {'label': label, 'command': command, 'exit_code': status,
                'elapsed_ms': (time.monotonic_ns() - began) / 1e6}
        steps.append(step)
        print(json.dumps(step), flush=True)
        return status

    try:
        sources = build.source_snapshot(consumer or runtime)
        locked = json.loads(args.source_lock.read_text()) if args.source_lock else None
        if locked is not None:
            sources = {p: value for p, value in sources.items()
                       if not p.endswith('.cj') or Path(p).relative_to(runtime).as_posix() in locked}
            for p, value in sources.items():
                if p.endswith('.cj') and value != locked[Path(p).relative_to(runtime).as_posix()]:
                    raise ValueError(f'source lock changed: {p}')
        rc = run('native-testing', ['zsh', str(runtime / 'native/scripts/build_cjgui_internal_renderer_sidecar.sh'), '--testing'])
        if rc:
            return rc
        native = runtime / 'native/testing/lib'
        archives = [native / 'libcjgui_internal_renderer.a']
        if consumer:
            injected = package / 'src/cjgui_macos_owner_fixture_test.cj'
            fixture = runtime / 'src/macos_owner_fixture_test.cj'
            if injected.exists() and fixture.is_file():
                expected = re.sub(r'^package cjgui$', 'package ' + build.read_manifest(consumer)['package']['name'],
                                  fixture.read_text(), count=1, flags=re.M)
                previous = json.loads((output / 'prepared.json').read_text())
                if previous.get('source_application') != str(consumer) or injected.read_text() != expected:
                    raise ValueError('unowned or changed injected owner fixture on test graph reuse')
                injected.unlink()
            prepared = build.prepare(consumer, runtime, native, output, testing=True)
            if prepared != package:
                raise ValueError('consumer test output mismatch')
            consumer_manifest = build.read_manifest(consumer)
            consumer_source = build.resolve(consumer, consumer_manifest['package'].get('src-dir', 'src'))
            ensure_consumer_owner_fixture(consumer_source, runtime, package, sources,
                                          build.read_manifest(consumer)['package']['name'], build.digest)
            result['consumer'] = str(consumer)
            result['entry'] = 'standard_cangjie_unittest_no_application_launcher'
        else:
            manifest = build.relocate(build.read_manifest(runtime), runtime)
            build.snapshot_sources(runtime / 'src', package / 'src', include_tests=True,
                source_names=None if locked is None else {p[4:] for p in locked if p.startswith('src/')})
            core = runtime / 'shared_operation_core'
            build.snapshot_sources(core / 'src', package / 'shared_operation_core/src',
                source_names=None if locked is None else {p[len('shared_operation_core/src/'):] for p in locked
                                                         if p.startswith('shared_operation_core/src/')})
            core_manifest = build.relocate(build.read_manifest(core), core)
            core_manifest['package']['src-dir'] = 'src'
            build.write_manifest(package / 'shared_operation_core/cjpm.toml', core_manifest)
            manifest['dependencies']['cjgui_shared_operation_core']['path'] = str(package / 'shared_operation_core')
            manifest['package']['src-dir'] = 'src'
            manifest['package']['target-dir'] = 'target'
            manifest['package']['link-option'] += ' -t -map cjgui-test-link.map'
            manifest['ffi']['c']['cjgui_internal_renderer']['path'] = str(native)
            build.write_manifest(package / 'cjpm.toml', manifest)
        sources.update({str(p): build.digest(p) for p in (runtime / 'native').iterdir() if p.suffix in ('.m', '.h')})
        (output / 'source-inputs.json').write_text(json.dumps(sources, indent=2) + '\n')
        with tarfile.open(output / 'source-inputs.tar.xz', 'w:xz') as source_archive:
            for name in sorted(sources):
                source_archive.add(name, arcname=('inputs/' + str(Path(name)).lstrip('/')) if consumer else str(Path(name).relative_to(runtime)))
        result['native_libraries'] = {str(p): build.digest(p) for p in archives}
        command = ['cjpm', 'test', '--skip-script', '-i', '-V', '--no-color', '--no-progress']
        rc = run('cjpm-link', command + ['--no-run'], package)
        if rc:
            return rc
        trace = (output / 'cjpm-link.log').read_text(errors='replace')
        selected = set(re.findall(r'^(.+libcjgui_(?:internal_renderer|macos_application_launcher)\.a)\([^)]+\)\s*$', trace, re.M))
        expected = {str(p) for p in archives}
        if selected != expected:
            raise ValueError(f'testing link archive mismatch: expected {expected}, got {selected}')
        result['actual_linked_archives'] = sorted(selected)
        for index, selection in enumerate(args.filter or []):
            rc = run(f'cjpm-test-{index}', command + ['--skip-build', '--filter', selection,
                     '--show-all-output', '--no-capture-output'], package)
            if rc:
                return rc
        rc = 0
        return rc
    finally:
        after = build.digest(normal) if normal.exists() else None
        changed = [p for p, value in sources.items() if not Path(p).exists() or build.digest(Path(p)) != value]
        result.update(exit_code=rc, steps=steps, source_changes_during_test=changed,
                      normal_archive_before=before, normal_archive_after=after,
                      normal_archive_unchanged=before == after, production_consumption_proven=False)
        if not args.keep_build:
            for owned in ((package, output / 'framework', output / 'native') if consumer else (package, output / 'native')):
                if owned.exists():
                    shutil.rmtree(owned)
        result['build_retired'] = not package.exists()
        (output / 'result.json').write_text(json.dumps(result, indent=2) + '\n')
        if changed or before != after:
            raise RuntimeError('source or production archive changed during isolated testing')


if __name__ == '__main__':
    raise SystemExit(main())

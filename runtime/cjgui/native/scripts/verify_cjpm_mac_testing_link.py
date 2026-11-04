#!/usr/bin/env python3
"""Selected package tests linked to a separate testing archive, never native/lib.

Reuses the ordinary source/config helpers and shared four-member native builder.
--output owns the reusable package/application graph; --evidence-output owns
the unique logs, input snapshots, and result (default: <output>/evidence).
Evidence is never overwritten. One owned graph is retired in finally unless --keep-build is set.
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
import stat
import subprocess
import tarfile
import time


OWNER_FIXTURE = 'cjgui_macos_owner_fixture_test.cj'
OWNER_FIXTURE_CALL = re.compile(r'\bcjguiMacosOwnerTest\s*\(')
EVIDENCE_FILES = {
    'run-context.json', 'source-inputs.json', 'source-inputs.tar.xz',
    'native-testing.log', 'cjpm-link.log', 'result.json',
}
EVIDENCE_TEST_LOG = re.compile(r'^cjpm-test-[0-9]+\.log$')


def evidence_collisions(directory: Path) -> list[str]:
    if not directory.exists():
        return []
    if directory.is_symlink() or not directory.is_dir():
        return [str(directory)]
    collisions = [str(directory / name) for name in sorted(EVIDENCE_FILES)
                  if (directory / name).exists()]
    collisions.extend(str(path) for path in sorted(directory.iterdir())
                      if EVIDENCE_TEST_LOG.fullmatch(path.name))
    retained = directory / 'retained-test-binary'
    if retained.exists():
        collisions.append(str(retained))
    return collisions


def output_preflight(output: Path, evidence: Path, package: Path, *, explicit_evidence: bool) -> list[str]:
    problems = []
    for reserved in (package, output / 'framework', output / 'native'):
        if evidence == reserved or evidence.is_relative_to(reserved):
            problems.append(f'evidence output overlaps build graph: {evidence}')
            break
    if evidence == output or output.is_relative_to(evidence):
        problems.append(f'evidence output must be separate from --output workspace: {evidence}')
    if not explicit_evidence:
        legacy = evidence_collisions(output)
        if legacy:
            problems.append('legacy evidence exists under --output: ' + ', '.join(legacy))
    conflicts = evidence_collisions(evidence)
    if conflicts:
        problems.append('evidence output already contains CJGUI evidence: ' + ', '.join(conflicts))
    return problems


def claim_evidence_directory(evidence: Path, context: dict) -> Path:
    evidence.mkdir(parents=True, exist_ok=True)
    marker = evidence / 'run-context.json'
    with marker.open('x', encoding='utf-8') as destination:
        destination.write(json.dumps(context, indent=2) + '\n')
    return marker


def run_logged_process(evidence: Path, label: str, command: list[str], env: dict,
                       cwd: Path, timeout: int = 600) -> dict:
    if not re.fullmatch(r'[a-z0-9-]+', label):
        raise ValueError(f'invalid evidence log label: {label}')
    log_path = evidence / (label + '.log')
    began = time.monotonic_ns()
    with log_path.open('xb') as log:
        child = subprocess.Popen(command, cwd=cwd, env=env, stdout=log,
                                 stderr=subprocess.STDOUT, start_new_session=True)
        try:
            status = child.wait(timeout=timeout)
        finally:
            if child.poll() is None:
                os.killpg(child.pid, signal.SIGTERM)
                try:
                    child.wait(timeout=5)
                except subprocess.TimeoutExpired:
                    os.killpg(child.pid, signal.SIGKILL)
                    child.wait()
    return {'label': label, 'command': command, 'exit_code': status,
            'elapsed_ms': (time.monotonic_ns() - began) / 1e6,
            'log': str(log_path)}


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
    parser.add_argument('--target-dir', type=Path,
                        help='Reuse this coordinated cjpm target; it is never retired by this runner')
    parser.add_argument('--evidence-output', type=Path,
                        help='Fresh evidence directory for source inputs, logs, and result; defaults to <output>/evidence')
    parser.add_argument('--runtime', type=Path, help='Test an exact exported runtime source/ABI pair')
    parser.add_argument('--consumer', type=Path, help='Test a normal application package with an isolated target and standard unittest entry')
    parser.add_argument('--filter', action='append', help='Execute only this selection; repeatable')
    parser.add_argument('--source-lock', type=Path, help='Accepted runtime-relative .cj paths and SHA256 values')
    parser.add_argument('--test-resource', type=Path, action='append', default=[],
                        help='Copy this exact resource beside the owned standard test executable; repeatable')
    parser.add_argument('--keep-build', action='store_true', help='Keep the one owned build graph for diagnosis')
    parser.add_argument('--collect-failures', action='store_true',
                        help='Run every selected filter in a separate runner and fail if any fails')
    parser.add_argument('--retain-test-binary-on-failure', action='store_true',
                        help='Retain the exact failed package test executable before retiring its build graph')
    args = parser.parse_args()
    runtime = (args.runtime or Path(__file__).resolve().parents[2]).resolve()
    output = (args.output or runtime / '.cjgui/macos-tests').resolve()
    consumer = args.consumer.resolve() if args.consumer else None
    if consumer and args.source_lock:
        parser.error('--source-lock selects framework tests only')
    package = output / ('application' if consumer else 'package')
    target = args.target_dir.resolve() if args.target_dir else package / 'target'
    owner = output / 'owner.json'
    raw_evidence = args.evidence_output or output / 'evidence'
    if raw_evidence.is_symlink():
        parser.error('--evidence-output must not be a symlink')
    evidence = raw_evidence.resolve()
    problems = output_preflight(output, evidence, package,
                                explicit_evidence=args.evidence_output is not None)
    if problems:
        detail = '; '.join(problems)
        parser.error(detail + '; preserve the --output workspace and choose a fresh --evidence-output')
    identity = {'runtime': str(runtime)}
    if consumer: identity['consumer'] = str(consumer)
    if args.target_dir: identity['target_dir'] = str(target)
    if owner.exists() and json.loads(owner.read_text()) != identity:
        parser.error('output belongs to another runtime')
    if package.exists() and not owner.exists():
        parser.error('output contains an unowned package')
    output.mkdir(parents=True, exist_ok=True)
    lock = (output / 'build.lock').open('a')
    fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
    evidence.mkdir(parents=True, exist_ok=True)
    evidence_context = {'runtime': str(runtime), 'workspace': str(output),
                        'evidence_output': str(evidence), 'package': str(package),
                        'consumer': str(consumer) if consumer else None,
                        'filters': args.filter or [], 'created_at_ns': time.time_ns()}
    claim_evidence_directory(evidence, evidence_context)
    if not owner.exists():
        with owner.open('x', encoding='utf-8') as owner_file:
            owner_file.write(json.dumps(identity) + '\n')
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
    steps, sources, failed_filters = [], {}, []
    rc = 1
    result = {'runtime': str(runtime), 'package': str(package), 'evidence_output': str(evidence),
              'target_dir': str(target), 'external_target_retirement_owner': 'caller' if args.target_dir else None,
              'native_mode': 'testing'}

    def cancelled(signum, frame):
        raise KeyboardInterrupt()
    signal.signal(signal.SIGTERM, cancelled)

    def run(label, command, cwd=runtime):
        step = run_logged_process(evidence, label, command, env, cwd)
        steps.append(step)
        print(json.dumps(step), flush=True)
        return step['exit_code']

    try:
        if evidence == target or evidence.is_relative_to(target) or target.is_relative_to(evidence):
            raise ValueError('evidence output overlaps the cjpm target')
        sources = build.source_snapshot(consumer or runtime)
        sources[str(Path(__file__).resolve())] = build.digest(Path(__file__).resolve())
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
        resources = {}
        for supplied in args.test_resource:
            if supplied.is_symlink() or not supplied.is_file():
                raise ValueError(f'test resource must be a regular file: {supplied}')
            source = supplied.resolve()
            if source.name in resources and resources[source.name] != source:
                raise ValueError(f'test resource basename collision: {source.name}')
            resources[source.name] = source
            sources[str(source)] = build.digest(source)
        with (evidence / 'source-inputs.json').open('x', encoding='utf-8') as source_manifest:
            source_manifest.write(json.dumps(sources, indent=2) + '\n')
        with tarfile.open(evidence / 'source-inputs.tar.xz', 'x:xz') as source_archive:
            for name in sorted(sources):
                source_archive.add(name, arcname=('inputs/' + str(Path(name)).lstrip('/'))
                                   if consumer or not Path(name).is_relative_to(runtime)
                                   else str(Path(name).relative_to(runtime)))
        result['native_libraries'] = {str(p): build.digest(p) for p in archives}
        command = ['cjpm', 'test', '--skip-script', '-i', '-V', '--no-color', '--no-progress']
        if args.target_dir: command += ['--target-dir', str(target)]
        rc = run('cjpm-link', command + ['--no-run'], package)
        if rc:
            return rc
        trace = (evidence / 'cjpm-link.log').read_text(errors='replace')
        selected = set(re.findall(r'^(.+libcjgui_(?:internal_renderer|macos_application_launcher)\.a)\([^)]+\)\s*$', trace, re.M))
        expected = {str(p) for p in archives}
        if selected != expected:
            raise ValueError(f'testing link archive mismatch: expected {expected}, got {selected}')
        result['actual_linked_archives'] = sorted(selected)
        result['test_resources'] = []
        for name, source in resources.items():
            destination = target / 'release/unittest_bin' / name
            expected_digest = sources[str(source)]
            if destination.exists():
                if destination.is_symlink() or not destination.is_file() or build.digest(destination) != expected_digest:
                    raise ValueError(f'test resource would overwrite another test artifact: {destination}')
            else:
                shutil.copyfile(source, destination)
            result['test_resources'].append({'source': str(source), 'destination': str(destination),
                                             'sha256': expected_digest})
        for index, selection in enumerate(args.filter or []):
            rc = run(f'cjpm-test-{index}', command + ['--skip-build', '--filter', selection,
                     '--show-all-output', '--no-capture-output'], package)
            if rc:
                failed_filters.append({'filter': selection, 'exit_code': rc})
                if not args.collect_failures:
                    return rc
        rc = 1 if failed_filters else 0
        return rc
    except BaseException as error:
        rc = 1
        result['failure'] = type(error).__name__ + ': ' + str(error)
        raise
    finally:
        after = build.digest(normal) if normal.exists() else None
        changed = [p for p, value in sources.items() if not Path(p).exists() or build.digest(Path(p)) != value]
        result.update(exit_code=rc, steps=steps, failed_filters=failed_filters,
                      source_changes_during_test=changed,
                      normal_archive_before=before, normal_archive_after=after,
                      normal_archive_unchanged=before == after, production_consumption_proven=False)
        preserve_failed_original = False
        if args.retain_test_binary_on_failure and failed_filters:
            try:
                name = build.read_manifest(package)['package']['name']
                executable = target / 'release/unittest_bin' / name
                if executable.is_symlink() or not executable.is_file():
                    raise ValueError(f'failed test executable missing: {executable}')
                retained = evidence / 'retained-test-binary' / name
                retained.parent.mkdir(exist_ok=True)
                if retained.exists():
                    raise ValueError(f'failed test original already exists: {retained}')
                with executable.open('rb') as source, retained.open('xb') as destination:
                    shutil.copyfileobj(source, destination)
                retained.chmod(stat.S_IMODE(executable.stat().st_mode))
                if build.digest(retained) != build.digest(executable):
                    raise ValueError('failed test executable copy changed bytes')
                result['retained_test_executable'] = {
                    'path': str(retained), 'sha256': build.digest(retained),
                    'mode': stat.S_IMODE(retained.stat().st_mode), 'bytes': retained.stat().st_size}
            except Exception as error:
                # Keep the only failed executable if archival cannot be proved.
                preserve_failed_original = True
                result['retention_failure'] = type(error).__name__ + ': ' + str(error)
        result['retired_allocated_bytes'] = 0
        if not args.keep_build and not preserve_failed_original:
            owned_graphs = (package, output / 'framework') if consumer else (package,)
            for owned in owned_graphs:
                if owned.exists():
                    seen = set()
                    for path in [owned, *owned.rglob('*')]:
                        info = path.lstat()
                        identity = (info.st_dev, info.st_ino)
                        if identity not in seen:
                            result['retired_allocated_bytes'] += info.st_blocks * 512
                            seen.add(identity)
                    shutil.rmtree(owned)
        result['build_retired'] = not package.exists()
        with (evidence / 'result.json').open('x', encoding='utf-8') as result_file:
            result_file.write(json.dumps(result, indent=2) + '\n')
        if changed or before != after:
            raise RuntimeError('source or production archive changed during isolated testing')


if __name__ == '__main__':
    raise SystemExit(main())

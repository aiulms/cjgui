from __future__ import annotations

import importlib.util
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

DRIVER_PATH = Path(__file__).resolve().parents[1] / 'verify_cjpm_mac_testing_link.py'
RUNTIME = DRIVER_PATH.parents[2]
SPEC = importlib.util.spec_from_file_location('verify_cjpm_mac_testing_link', DRIVER_PATH)
DRIVER = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(DRIVER)


class EvidenceSeparationTests(unittest.TestCase):
    def executable_marker_tools(self, root: Path) -> Path:
        tools = root / 'bin'
        tools.mkdir()
        for name in ('xcrun', 'cjpm'):
            marker = tools / f'{name}-started'
            script = tools / name
            script.write_text(f'#!/bin/sh\nprintf started > "{marker}"\nexit 97\n')
            script.chmod(0o755)
        return tools

    def run_driver(self, *args: str, path: Path) -> subprocess.CompletedProcess[str]:
        env = dict(os.environ)
        env['PATH'] = str(path) + os.pathsep + env.get('PATH', '')
        env.pop('CANGJIE_HOME', None)
        return subprocess.run([sys.executable, str(DRIVER_PATH), *args],
                              capture_output=True, text=True, env=env, timeout=15)

    def test_legacy_output_collision_refuses_before_writes_or_tool_process(self):
        with tempfile.TemporaryDirectory(prefix='cjgui-link-evidence-legacy-') as temporary:
            root = Path(temporary)
            workspace = root / 'workspace'
            package = workspace / 'package'
            package.mkdir(parents=True)
            identity = {'runtime': str(RUNTIME.resolve())}
            (workspace / 'owner.json').write_text(json.dumps(identity) + '\n')
            (package / 'owned-build-sentinel').write_bytes(b'keep-build')
            result = workspace / 'result.json'
            high_log = workspace / 'cjpm-test-8.log'
            result.write_bytes(b'old-result')
            high_log.write_bytes(b'old-high-number-log')
            tools = self.executable_marker_tools(root)

            completed = self.run_driver('--output', str(workspace), '--runtime', str(RUNTIME),
                                        '--filter', '*unused*', path=tools)

            self.assertEqual(completed.returncode, 2, completed.stderr)
            self.assertIn('legacy evidence exists under --output', completed.stderr)
            self.assertIn('fresh --evidence-output', completed.stderr)
            self.assertEqual(result.read_bytes(), b'old-result')
            self.assertEqual(high_log.read_bytes(), b'old-high-number-log')
            self.assertEqual((package / 'owned-build-sentinel').read_bytes(), b'keep-build')
            self.assertFalse((workspace / 'build.lock').exists())
            self.assertFalse((workspace / 'evidence').exists())
            self.assertFalse((tools / 'xcrun-started').exists())
            self.assertFalse((tools / 'cjpm-started').exists())

    def test_explicit_evidence_collision_refuses_without_clearing_foreign_files(self):
        with tempfile.TemporaryDirectory(prefix='cjgui-link-evidence-explicit-') as temporary:
            root = Path(temporary)
            workspace = root / 'workspace'
            workspace.mkdir()
            evidence = root / 'evidence'
            evidence.mkdir()
            marker = evidence / 'operator-note.txt'
            marker.write_bytes(b'preserve')
            result = evidence / 'result.json'
            result.write_bytes(b'prior-result')
            tools = self.executable_marker_tools(root)

            completed = self.run_driver('--output', str(workspace), '--evidence-output', str(evidence),
                                        '--runtime', str(RUNTIME), '--filter', '*unused*', path=tools)

            self.assertEqual(completed.returncode, 2, completed.stderr)
            self.assertIn('evidence output already contains CJGUI evidence', completed.stderr)
            self.assertEqual(marker.read_bytes(), b'preserve')
            self.assertEqual(result.read_bytes(), b'prior-result')
            self.assertFalse((workspace / 'build.lock').exists())
            self.assertFalse((workspace / 'owner.json').exists())
            self.assertFalse((tools / 'xcrun-started').exists())
            self.assertFalse((tools / 'cjpm-started').exists())

    def test_same_workspace_accepts_two_fresh_evidence_dirs_without_mixing_logs(self):
        with tempfile.TemporaryDirectory(prefix='cjgui-link-evidence-paired-') as temporary:
            root = Path(temporary)
            workspace = root / 'workspace'
            package = workspace / 'package'
            package.mkdir(parents=True)
            package_marker = package / 'reused-package-source'
            package_marker.write_bytes(b'one-workspace')
            owner = workspace / 'owner.json'
            owner.write_text(json.dumps({'runtime': str(RUNTIME.resolve())}) + '\n')
            external_note = root / 'evidence-a' / 'operator-note.txt'
            external_note.parent.mkdir()
            external_note.write_bytes(b'keep-non-evidence-file')
            first = external_note.parent
            second = root / 'evidence-b'

            problems = DRIVER.output_preflight(workspace, first, package, explicit_evidence=True)
            self.assertEqual(problems, [])
            DRIVER.claim_evidence_directory(first, {
                'workspace': str(workspace), 'evidence_output': str(first), 'test_only': True})
            env = dict(os.environ)
            first_step = DRIVER.run_logged_process(
                first, 'cjpm-test-8',
                [sys.executable, '-c', "print('old high-index evidence')"], env, root)
            self.assertEqual(first_step['exit_code'], 0)
            self.assertEqual((first / 'cjpm-test-8.log').read_text().strip(), 'old high-index evidence')
            self.assertIn(str(first / 'cjpm-test-8.log'), DRIVER.evidence_collisions(first))
            self.assertEqual(DRIVER.output_preflight(workspace, second, package,
                                                     explicit_evidence=True), [])
            DRIVER.claim_evidence_directory(second, {
                'workspace': str(workspace), 'evidence_output': str(second), 'test_only': True})
            second_step = DRIVER.run_logged_process(
                second, 'cjpm-test-0',
                [sys.executable, '-c', "print('new case only')"], env, root)
            self.assertEqual(second_step['exit_code'], 0)

            self.assertEqual((first / 'cjpm-test-8.log').read_text().strip(), 'old high-index evidence')
            self.assertFalse((second / 'cjpm-test-8.log').exists())
            self.assertEqual((second / 'cjpm-test-0.log').read_text().strip(), 'new case only')
            self.assertEqual(first_step['log'], str(first / 'cjpm-test-8.log'))
            self.assertEqual(second_step['log'], str(second / 'cjpm-test-0.log'))
            self.assertEqual(external_note.read_bytes(), b'keep-non-evidence-file')
            self.assertEqual(package_marker.read_bytes(), b'one-workspace')
            self.assertEqual(json.loads((first / 'run-context.json').read_text())['test_only'], True)
            self.assertEqual(json.loads((second / 'run-context.json').read_text())['test_only'], True)


if __name__ == '__main__':
    unittest.main()

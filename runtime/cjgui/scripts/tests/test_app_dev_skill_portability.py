"""Portable discovery, dependency-scoped lookup and evidence-based triage."""
from pathlib import Path
import hashlib
import json
import shutil
import subprocess
import sys
import tempfile
import unittest

SKILL = Path(__file__).resolve().parents[2] / 'skills/cjgui-app-dev'


class Portability(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='cjgui portable ')
        self.root = Path(self.temp.name)

    def tearDown(self):
        self.temp.cleanup()

    def call(self, script, *args, skill=SKILL, python=sys.executable):
        return subprocess.run([str(python), '-B', str(skill / 'scripts' / script),
                               *map(str, args)], text=True, capture_output=True)

    def data(self, result):
        self.assertEqual(result.returncode, 0, result.stderr)
        return json.loads(result.stdout)

    def package(self, path, name, deps=''):
        path.mkdir(parents=True, exist_ok=True)
        (path / 'cjpm.toml').write_text(f'[package]\nname="{name}"\n[dependencies]\n{deps}\n')
        return path

    def application(self):
        fw = self.package(self.root / 'sdk/framework/cjgui', 'cjgui')
        app = self.package(self.root / 'app', 'app', 'cjgui={path="../sdk/framework/cjgui"}')
        (fw / 'src').mkdir()
        (fw / 'src/widgets.cj').write_text('package cjgui\npublic func preciseWidget(width: Int64): Int64 { width }\n')
        (fw / 'LAYOUT_PRIMITIVES.md').write_text('# 布局\n让 growY 分配剩余高度。\n')
        return app, fw

    def test_invalid_app_is_not_an_unknown_dependency(self):
        empty = self.root / 'empty'; empty.mkdir()
        file = self.root / 'not-an-app'; file.write_text('x')
        bad = self.root / 'bad'; bad.mkdir(); (bad / 'cjpm.toml').write_text('[package')
        for path in [self.root / 'missing', empty, file, bad, '']:
            with self.subTest(path=path):
                result = self.call('identify.py', '--app', path)
                self.assertEqual(result.returncode, 2, result.stdout + result.stderr)
                self.assertNotIn('Traceback', result.stderr)
        app = self.package(self.root / 'plain', 'plain')
        self.assertEqual(self.data(self.call('identify.py', '--app', app))['references'], [])

    def test_old_python_reports_required_runtime(self):
        old = Path('/usr/bin/python3')
        if not old.exists(): self.skipTest('system Python unavailable')
        version = subprocess.check_output([str(old), '-c', 'import sys; print(sys.version_info.minor)'], text=True)
        if int(version) >= 11: self.skipTest('system Python already supports tomllib')
        result = self.call('identify.py', '--app', self.root, python=old)
        self.assertEqual(result.returncode, 2)
        self.assertIn('3.11', result.stderr)
        self.assertNotIn('Traceback', result.stderr)

    def test_json_errors_name_the_input(self):
        app = self.package(self.root / 'app', 'app')
        broken = self.root / 'broken-report.json'; broken.write_text('{')
        for script, args in [('identify.py', ['--app', app, '--build-provenance', broken]),
                             ('feedback.py', ['create', '--app', app, '--input', broken])]:
            result = self.call(script, *args)
            self.assertEqual(result.returncode, 2)
            self.assertIn(str(broken), result.stderr)

    def test_host_profiles_are_explicit_and_preview_does_not_install(self):
        for host, directory in [('dsh', '.dsh'), ('agents', '.agents')]:
            data = self.data(self.call('install.py', '--host', host, '--dry-run'))
            self.assertEqual(Path(data['destination']), Path.home() / directory / 'skills/cjgui-app-dev')
            self.assertEqual(data['status'], 'planned')
            self.assertEqual(data['discovery'], 'not_checked')
        target = self.root / 'custom skills'
        self.data(self.call('install.py', '--skills-dir', target, '--dry-run'))
        self.assertFalse(target.exists())
        self.assertEqual(self.call('install.py', '--host', 'dsh', '--skills-dir', target).returncode, 2)

    def test_lookup_uses_the_app_dependency_and_current_source(self):
        app, fw = self.application()
        other = self.package(self.root / 'latest', 'cjgui')
        (other / 'src').mkdir(); (other / 'src/new.cj').write_text('public func newerOnly(): Int64 { 1 }\n')
        result = self.data(self.call('lookup.py', '--app', app, '--query', 'preciseWidget', '--query', 'newerOnly'))
        self.assertEqual(Path(result['framework']['path']), fw.resolve())
        hit = result['queries'][0]['matches'][0]
        self.assertEqual(hit['line'], 2)
        self.assertIn('preciseWidget(width: Int64)', hit['snippet'])
        self.assertEqual(hit['file_sha256'], hashlib.sha256((fw / 'src/widgets.cj').read_bytes()).hexdigest())
        self.assertEqual(result['queries'][1]['status'], 'no_match')
        (fw / 'src/widgets.cj').write_text('public func replacement(): Int64 { 2 }\n')
        refreshed = self.data(self.call('lookup.py', '--app', app, '--query', 'preciseWidget'))
        self.assertEqual(refreshed['queries'][0]['status'], 'no_match')

    def test_copy_install_lookup_works_without_its_original_skill(self):
        app, fw = self.application()
        source = self.root / 'skill source'; shutil.copytree(SKILL, source, ignore=shutil.ignore_patterns('__pycache__'))
        installed = self.root / 'tool discovery/cjgui-app-dev'
        self.data(self.call('install.py', '--skills-dir', installed.parent, '--mode', 'copy', skill=source))
        shutil.rmtree(source)
        result = self.data(self.call('lookup.py', '--framework', fw, '--query', '布局', skill=installed))
        self.assertTrue(result['queries'][0]['matches'])
        self.assertEqual(Path(result['queries'][0]['matches'][0]['path']), (fw / 'LAYOUT_PRIMITIVES.md').resolve())

    def test_lookup_prefers_definition_over_adjacent_lines_and_references(self):
        app, fw = self.application()
        (fw / 'src/widgets.cj').write_text(
            'public let EVENT_ACTIVATE: Int64 = 27\n'
            'public let EVENT_TEXT_CHANGED: Int64 = 28\n'
            'public func consume(controller: SampleController): Unit {}\n'
            'public interface SampleController {\n}\n')
        result = self.data(self.call('lookup.py', '--app', app, '--query', 'EVENT_TEXT_CHANGED',
                                     '--query', 'SampleController', '--max-results', '1'))
        self.assertEqual(result['queries'][0]['matches'][0]['line'], 2)
        self.assertEqual(result['queries'][1]['matches'][0]['line'], 4)

    def test_ambiguous_dependencies_are_not_silently_selected(self):
        app, fw = self.application()
        self.package(self.root / 'second', 'cjgui')
        self.package(app, 'app', 'one={path="../sdk/framework/cjgui"}\ntwo={path="../second"}')
        result = self.call('lookup.py', '--app', app, '--query', 'preciseWidget')
        self.assertEqual(result.returncode, 2)
        self.assertIn('multiple', result.stderr)

    def test_triage_can_dismiss_misuse_without_erasing_usability(self):
        app = self.package(self.root / 'app', 'app')
        f = self.root / 'input.json'
        data = {'goal':'fill sidebar', 'expected':'fills height', 'actual':'gap',
                'usability':['stretch was difficult to find']}
        f.write_text(json.dumps(data)); created = self.data(self.call('feedback.py', 'create', '--app', app, '--input', f))
        root = created['root']; issue = created['issue']
        data.update(actual='fixed by documented stretch', classification='application_integration',
                    supersedes=created['event'], triage={'decision':'no_framework_action','reason':'same-version recipe was explicit; one missed step'})
        f.write_text(json.dumps(data))
        self.data(self.call('feedback.py', 'append', '--root', root, '--issue', issue, '--input', f))
        shown = self.data(self.call('feedback.py', 'show', '--root', root, '--issue', issue))
        self.assertEqual(len(shown['events']), 2)
        self.assertEqual(shown['events'][0]['data']['actual'], 'gap')
        self.assertIn('stretch was difficult to find', json.dumps(shown))
        listing = self.data(self.call('feedback.py', 'list', '--root', root))['issues'][0]
        self.assertEqual(listing['observations'][0]['triage']['decision'], 'no_framework_action')
        data['triage']['reason'] = ''; f.write_text(json.dumps(data))
        self.assertEqual(self.call('feedback.py', 'append', '--root', root, '--issue', issue, '--input', f).returncode, 2)

    def test_one_corrupt_issue_does_not_hide_other_feedback(self):
        app = self.package(self.root / 'app', 'app'); f = self.root / 'in.json'
        f.write_text(json.dumps({'goal':'a','expected':'b','actual':'c'}))
        one = self.data(self.call('feedback.py', 'create', '--app', app, '--input', f))
        two = self.data(self.call('feedback.py', 'create', '--app', app, '--input', f))
        file = Path(one['root']) / 'issues' / one['issue'] / 'events' / (one['event'] + '.json')
        file.write_text('{')
        listing = self.data(self.call('feedback.py', 'list', '--root', one['root']))
        self.assertEqual(listing['status'], 'partial')
        self.assertEqual([i['issue'] for i in listing['issues']], [two['issue']])
        self.assertIn(str(file), listing['errors'][0]['error'])


if __name__ == '__main__':
    unittest.main()

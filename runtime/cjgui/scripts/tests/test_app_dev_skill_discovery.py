"""Regression cases from normal workspace and captured-SDK consumption."""
from pathlib import Path
import json
import subprocess
import sys
import tempfile
import unittest

SCRIPTS = Path(__file__).resolve().parents[2] / 'skills/cjgui-app-dev/scripts'


class Discovery(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='cjgui discovery ')
        self.root = Path(self.temp.name).resolve()
        self.fw = self.root / 'framework'; self.fw.mkdir()
        (self.fw / 'cjpm.toml').write_text('[package]\nname="cjgui"\n')
        (self.fw / 'src').mkdir()

    def tearDown(self): self.temp.cleanup()

    def call(self, script, *args):
        return subprocess.run([sys.executable, '-B', str(SCRIPTS / script), *map(str,args)], text=True, capture_output=True)

    def data(self, result):
        self.assertEqual(result.returncode, 0, result.stderr)
        return json.loads(result.stdout)

    def query(self, query, count=3):
        return self.data(self.call('lookup.py', '--framework', self.fw, '--query', query, '--max-results', count))

    def test_workspace_members_are_discovered_without_claiming_build_selection(self):
        (self.root / 'cjpm.toml').write_text('[workspace]\nmembers=["desktop", "missing", "."]\nbuild-members=[]\n')
        app = self.root / 'desktop'; app.mkdir()
        (app / 'cjpm.toml').write_text('[package]\nname="app"\n[dependencies]\ncjgui={path="../framework"}\n')
        report = self.data(self.call('identify.py', '--app', self.root))
        self.assertEqual([r['path'] for r in report['references']], [str(self.fw)])
        self.assertEqual(report['build']['status'], 'unknown')
        self.assertTrue(any('workspace' in w and 'build' in w for w in report['warnings']))
        self.assertTrue(any('missing' in w for w in report['warnings']))

    def test_workspace_with_multiple_frameworks_remains_ambiguous(self):
        (self.root / 'cjpm.toml').write_text('[workspace]\nmembers=["framework", "other"]\n')
        other=self.root/'other'; other.mkdir(); (other/'cjpm.toml').write_text('[package]\nname="cjgui"\n')
        report=self.data(self.call('identify.py','--app',self.root))
        self.assertEqual(len(report['references']),2)
        self.assertEqual(self.call('lookup.py','--app',self.root,'--query','字段').returncode,2)

    def test_absence_does_not_invent_a_remote_dependency(self):
        app=self.root/'plain'; app.mkdir(); (app/'cjpm.toml').write_text('[package]\nname="plain"\n')
        report=self.data(self.call('identify.py','--app',app))
        self.assertFalse(any('remote or missing' in w for w in report['warnings']))

    def test_captured_source_reports_missing_guides(self):
        (self.fw/'src/events.cj').write_text('public let EVENT_TEXT_CHANGED: Int64 = 28\n')
        report=self.query('文本输入的事件')
        self.assertIn('coverage',report)
        self.assertEqual(report['coverage']['documentation_files'],0)
        self.assertIn('FIELD_CONTROLS.md',report['queries'][0]['routes_not_present'])
        self.assertTrue(any('no public documentation' in w for w in report['warnings']))
        exact=self.query('EVENT_TEXT_CHANGED')
        self.assertTrue(exact['queries'][0]['matches'])

    def test_specific_layout_recipe_beats_the_routed_title(self):
        (self.fw/'LAYOUT_PRIMITIVES.md').write_text(
            '# 公共布局原语\n\n概述。\n\n## 剩余空间与交叉轴\n\n'
            'grow 分配主轴剩余空间；交叉轴必须使用 stretch。\n\n## 其他\n\n其他内容。\n')
        report=self.query('grow 交叉轴 stretch',1)
        hit=report['queries'][0]['matches'][0]
        self.assertGreater(hit['line'],1)
        self.assertIn('交叉轴必须使用 stretch',hit['snippet'])

    def test_unrelated_docs_do_not_hide_missing_requested_guides(self):
        shared=self.fw/'shared_operation_core'; shared.mkdir()
        (shared/'README.md').write_text('# Protocol\n\nTransport contract.\n')
        report=self.query('文本输入的事件')
        self.assertEqual(report['coverage']['documentation_files'],1)
        self.assertTrue(any('FIELD_CONTROLS.md' in w for w in report['warnings']))

    def test_package_gaps_are_reported_without_a_topic_route(self):
        shared=self.fw/'shared_operation_core'; shared.mkdir()
        (shared/'DOCUMENT_CLIENT.md').write_text(
            '# Document lifecycle\n\nOne live document owns one `CjguiTextDocumentFileBinding`.\n')
        report=self.query('CjguiTextDocumentFileBinding')
        self.assertEqual(report['coverage']['root_documentation_files'],0)
        self.assertFalse(report['coverage']['templates_present'])
        self.assertEqual(report['queries'][0]['status'],'found')
        self.assertEqual(report['queries'][0]['routes_not_present'],[])
        self.assertTrue(any('root-level public guides' in w for w in report['warnings']))
        self.assertTrue(any('templates directory' in w for w in report['warnings']))
        self.assertEqual(report['evidence_kind'],'source_lookup_only')

    def test_overlapping_chinese_matches_do_not_hide_event_declarations(self):
        (self.fw/'MACOS_APPLICATION_HOST.md').write_text(
            '# 最小应用\n\n'+ '\n\n'.join(
                f'模板{i}包含本地 controller；文本输入直接走领域动作，拒绝旧事件。'
                for i in range(4))+'\n')
        (self.fw/'FIELD_CONTROLS.md').write_text('# 公共字段控件\n\n数值步进。\n')
        (self.fw/'src/events.cj').write_text(
            'public let CJGUI_COMPOSABLE_UI_EVENT_TEXT_CHANGED: Int64 = 28\n'
            'public interface CjguiComposableUiController {\n}\n')
        for query in ('文本输入事件','文本输入的事件'):
            with self.subTest(query=query):
                matches=self.query(query)['queries'][0]['matches']
                self.assertTrue(any('EVENT_TEXT_CHANGED' in m['snippet'] for m in matches),matches)
                self.assertTrue(any('interface CjguiComposableUiController' in m['snippet'] for m in matches),matches)
                self.assertNotEqual(matches[0]['kind'],'documentation')

    def test_exact_symbol_declaration_keeps_priority_over_documentation(self):
        (self.fw/'README.md').write_text(
            '# Events\n\nTEXT_CHANGED TEXT_CHANGED controller CjguiComposableUiController.\n')
        (self.fw/'src/events.cj').write_text('public let TEXT_CHANGED: Int64 = 28\n')
        hit=self.query('TEXT_CHANGED',1)['queries'][0]['matches'][0]
        self.assertEqual(hit['kind'],'declaration_text')
        self.assertEqual(hit['snippet'],'public let TEXT_CHANGED: Int64 = 28')

    def test_chinese_phrase_recall_does_not_require_the_whole_query(self):
        (self.fw/'FIELD_CONTROLS.md').write_text(
            '# 字段控件\n\n总览。\n\n## 编辑回调\n\n文本输入事件包含字段的新值。\n')
        report=self.query('文本输入的事件',1)
        hit=report['queries'][0]['matches'][0]
        self.assertGreater(hit['line'],1)
        self.assertIn('文本输入事件',hit['snippet'])

    def test_distinct_relevant_blocks_in_one_document_can_both_be_returned(self):
        (self.fw/'FIELD_CONTROLS.md').write_text(
            '# 控件\n\n## 文本\n\n输入事件更新文本。\n\n## 数字\n\n输入事件更新数字。\n')
        matches=self.query('输入事件',3)['queries'][0]['matches']
        self.assertGreaterEqual(len(matches),2)
        self.assertTrue(any('更新文本' in m['snippet'] for m in matches))
        self.assertTrue(any('更新数字' in m['snippet'] for m in matches))

    def test_complete_short_declaration_is_not_marked_truncated_by_later_code(self):
        (self.fw/'src/events.cj').write_text('public let EXACT_EVENT: Int64 = 28\n'+'// later unrelated line\n'*30)
        hit=self.query('EXACT_EVENT',1)['queries'][0]['matches'][0]
        self.assertFalse(hit['snippet_truncated'])
        self.assertTrue(hit['has_more_context_after'])

    def test_long_signature_reports_actual_excerpt_limit(self):
        (self.fw/'src/widgets.cj').write_text('public func longSignature(\n'+''.join(f'  field{i}: Int64,\n' for i in range(20))+'  last: Int64): Unit {}\n')
        hit=self.query('longSignature',1)['queries'][0]['matches'][0]
        self.assertTrue(hit['snippet_truncated'])
        self.assertEqual(hit.get('snippet_scope'),'declaration_header')

    def test_feedback_summary_names_the_latest_observation_explicitly(self):
        f=self.root/'input.json'; f.write_text(json.dumps({'goal':'x','expected':'y','actual':'z','classification':'unclassified'}))
        created=self.data(self.call('feedback.py','create','--app',self.root,'--input',f))
        report=self.data(self.call('feedback.py','list','--root',created['root']))
        self.assertEqual(report.get('schema_version'),2)
        self.assertNotIn('classification',report['issues'][0])
        self.assertEqual(report['issues'][0]['latest_classification'],'unclassified')


if __name__=='__main__': unittest.main()

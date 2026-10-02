#!/usr/bin/env python3
"""R4 负控回归（h-source-preview-followup 2026-10-02）。

执行**未改动**的 verify_pharos_dual_owner.main（AST 提取，替换设备/传输层），
用受控 owner 回包与受控日志行驱动总门。指导复核的假绿负控在此必须变红：

  wrong-note-range      应替换冻结选区 [1,3)（bc→N），实际替换了 de → 总门失败；
  destructive-A-resume  A 续写必须落冻结 caret（removed=0），实际误删 b → 失败；
  zero-input / duplicate-write / missing-install-confirm / stale-log /
  note-cleared         同样必须失败。

设备/传输全部替换；不连接设备。断言的是**实际总程序**的退出码与 status，
不是重写后的布尔表达式。
"""
import argparse
import ast
import importlib.util
import json
import re
import sys
import unittest
from pathlib import Path
from types import SimpleNamespace

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent
SOURCE = ROOT / 'scripts' / 'verify_pharos_dual_owner.py'
DRIVER_HELPER = HERE / 'h_source_preview_consumption.py'


def _load_strict_utf16():
    spec = importlib.util.spec_from_file_location('strict_utf16_local', HERE / 'strict_utf16.py')
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


EXTRACT = ['hexs', 'confirmed_selection', 'wait_confirmed_selection',
           'expected_after_replacement', '_finish', 'main']
# read_public / find_note_resource / reach_mode / current_mode 保持受控 stub：
# 提取它们会覆盖受控回包，m.request 也会被牵连（指导 harness 同一纪律）。

_tree = ast.parse(SOURCE.read_text())
_nodes = [n for n in _tree.body if isinstance(n, ast.FunctionDef) and n.name in EXTRACT]
assert {n.name for n in _nodes} == set(EXTRACT), "extraction mismatch"
_MAIN_CODE = compile(ast.Module(body=_nodes, type_ignores=[]), str(SOURCE), 'exec')


class StatefulRows:
    """设备语义：日志只增不减。

    前两次调用只见 prefix（上一轮/历史行，必须被 cursor 围栏排除）；随调用
    推进，本轮 scripted 行逐步可见——安装确认行在拖选之后才出现。"""

    def __init__(self, prefix, scripted):
        self.prefix = list(prefix)
        self.scripted = list(scripted)
        self.calls = 0

    def __call__(self):
        self.calls += 1
        visible = min(len(self.scripted), max(0, self.calls - 2))
        return self.prefix + self.scripted[:visible]


def note_rows(sel=(1, 3), confirmed=True):
    rows = ['10-01 08:00:00.000 proxy mounted key=app0/s1/c22/e3/m2 field=pharos-document-note']
    if confirmed:
        rows.append('10-02 09:00:00.000 ime selection confirmed [%d,%d) rc=0 (shared lifecycle)'
                    % sel)
        rows.append('10-02 09:00:00.032 ime proxy selection terminal=INSTALLED '
                    'reason=attach_confirmed target=[%d,%d) mount=app0/s1/c22/e3/m2' % sel)
    return rows


def body_rows(sel=(1, 1), confirmed=True):
    rows = ['10-01 08:00:00.000 proxy mounted key=app0/s1/c9/e1/m1 field=pharos-editor-body']
    if confirmed:
        rows.append('10-02 09:00:01.000 ime selection confirmed [%d,%d) rc=0 (shared lifecycle)'
                    % sel)
        rows.append('10-02 09:00:01.032 ime proxy selection terminal=INSTALLED '
                    'reason=attach_confirmed target=[%d,%d) mount=app0/s1/c9/e1/m1' % sel)
    return rows


def run_case(name, *,
             actual_a='a回bc', actual_b='aNdef',
             note_versions=None,
             scripted=None, prefix=None):
    """跑一次真实 main；返回 (exit_code, status, results)。"""
    a = 'abc'.encode().hex()
    b = b'abcdef'.hex()
    if note_versions is None:
        note_versions = [(1, b), (2, b), (2, b), (3, actual_b.encode().hex()),
                         (3, actual_b.encode().hex()), (3, actual_b.encode().hex())]
    main_replies = iter([(1, a), (1, a), (1, a), (2, actual_a.encode().hex())])
    note_replies = iter(note_versions)
    if scripted is None:
        scripted = note_rows() + body_rows()
    if prefix is None:
        # 历史行：上一轮的旧确认（含旧挂载），不得被本轮围栏误采。
        prefix = ['10-01 07:59:00.000 proxy mounted key=app0/s0/c18/e2/m1 field=pharos-document-note',
                  '10-01 07:59:00.000 ime selection confirmed [5,7) rc=0 (shared lifecycle)',
                  '10-01 07:59:00.032 ime proxy selection terminal=INSTALLED '
                  'reason=attach_confirmed target=[5,7) mount=app0/s0/c18/e2/m1']
    h = {}
    spec = importlib.util.spec_from_file_location('helper_diff', DRIVER_HELPER)
    helper = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(helper)
    h['diff_span'] = helper.diff_span
    rows = StatefulRows(prefix, scripted)
    m = SimpleNamespace(
        instance_identity=lambda: {'pid': 11, 'bundle': 'controlled'},
        hilog_rows=rows, hdc=lambda *a: SimpleNamespace(stdout='OK'),
        reset_fixture=lambda port: (True, {}), read_all=lambda port: next(main_replies),
        accepted_semantic_point=lambda *a, **k: (100, 100),
        accepted_semantic_rect=lambda *a: (0, 0, 200, 100), uitest=lambda *a: None,
        last_note_caret=lambda port: 1, note_rendered_units=lambda node: 6,
        note_projected_text=lambda port: 'abcdef')
    env = dict(argparse=argparse, Path=Path, json=json, re=re, m=m, OUT=None,
               time=SimpleNamespace(sleep=lambda seconds: None),
               strict_utf16=_load_strict_utf16(),
               NOTE_FIELD='pharos-document-note', BODY_FIELD='pharos-editor-body',
               find_note_resource=lambda port: 1001,
               read_public=lambda port, rid: next(note_replies),
               reach_mode=lambda *a, **k: (True, {'mode': a[1]}))
    exec(_MAIN_CODE, env)
    out = HERE / 'negative-controls-artifacts' / name
    out.mkdir(parents=True, exist_ok=True)
    old_argv = sys.argv
    try:
        sys.argv = [str(SOURCE), '--out', str(out)]
        rc = env['main']()
    finally:
        sys.argv = old_argv
    results = json.loads((out / 'dual-owner.json').read_text())
    return rc, results.get('status'), results


class DualOwnerNegativeControlsTest(unittest.TestCase):
    def assert_red(self, rc, status, name):
        self.assertNotEqual(rc, 0, f'{name} must fail the overall gate (rc={rc})')
        self.assertNotEqual(status, 'OK', f'{name} must not report OK')

    def test_positive_control_passes(self):
        rc, status, _ = run_case('positive-control')
        self.assertEqual(rc, 0)
        self.assertEqual(status, 'OK')

    def test_wrong_note_range_fails(self):
        # 冻结选区 [1,3)=bc；实际把 de 换成了 N（abcNf）。
        rc, status, r = run_case('wrong-note-range', actual_b='abcNf')
        self.assert_red(rc, status, 'wrong-note-range')
        self.assertFalse(r['required_values']['b_replace_exact_owner'])

    def test_destructive_a_resume_fails(self):
        # A 冻结 caret [1,1)；期望 a+回+bc，实际误删 b 得 a回c。
        rc, status, r = run_case('destructive-A-resume', actual_a='a回c')
        self.assert_red(rc, status, 'destructive-A-resume')
        self.assertFalse(r['required_values']['a_resume_exact_owner'])

    def test_zero_input_fails(self):
        # 输入未生效：版本不变、字节不变。
        b = b'abcdef'.hex()
        rc, status, _ = run_case('zero-input',
                                 note_versions=[(1, b), (2, b), (2, b), (2, b), (2, b), (2, b)])
        self.assert_red(rc, status, 'zero-input')

    def test_duplicate_write_fails(self):
        # 版本 +2：重复写。
        b2 = (b'aNNdef').hex()
        rc, status, _ = run_case('duplicate-write',
                                 note_versions=[(1, b'abcdef'.hex()), (2, b'abcdef'.hex()),
                                                (2, b'abcdef'.hex()), (4, b2), (4, b2), (4, b2)])
        self.assert_red(rc, status, 'duplicate-write')

    def test_missing_install_confirmation_fails(self):
        # 本轮日志没有任何备注安装确认行。
        rc, status, r = run_case('missing-install-confirm', scripted=body_rows())
        self.assert_red(rc, status, 'missing-install-confirm')
        self.assertEqual(r.get('status'), 'b_install_unconfirmed')

    def test_stale_log_confirmation_not_accepted(self):
        # 确认行只存在于 cursor0 之前（旧轮日志）；本轮无新确认。
        rc, status, r = run_case(
            'stale-log-confirmation',
            scripted=body_rows(),
            prefix=note_rows(sel=(5, 7)))
        self.assert_red(rc, status, 'stale-log-confirmation')
        self.assertEqual(r.get('status'), 'b_install_unconfirmed')

    def test_note_cleared_fails(self):
        # 替换后备注被清空。
        rc, status, _ = run_case('note-cleared',
                                 note_versions=[(1, b'abcdef'.hex()), (2, b'abcdef'.hex()),
                                                (2, b'abcdef'.hex()), (3, ''), (3, ''), (3, '')])
        self.assert_red(rc, status, 'note-cleared')


if __name__ == '__main__':
    unittest.main()

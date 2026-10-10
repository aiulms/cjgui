#!/usr/bin/env python3
"""R4补轮负控回归（2026-10-02 指导复核，第二版）。

硬约束（指导复核 A）：
  * 输出隔离：本模块**只**用调用方给出的临时目录；任何一次 main() 都必须
    传入临时 output_dir。模块级断言历史证据 thermo-shared.json 的哈希在整个
    运行前后不变（旧版会把真实证据覆盖成替身结果）。
  * 正控：actual main（不是插入腿局部控制）必须走到 exit0/status==OK。
  * 负控必须**到达对应判据后被拒**（具名状态/判据），不能因无关早期失败蒙混：
      1 错字段        2 同坐标跨 mount 拼接   3 旧确认复活
      4 错 PID        5 零输入               6 重复写
      7 未知端点（转发创建失败不得继续写应用、不得删他方映射）
  * 确认链绑定 target/mount/context/request：confirmed_selection 必须接收
    期望 field，并按挂载 key 身份配对，不再只凭坐标相等。

设备/传输全部替换；不连接设备，不写历史设备目录。
"""
import ast
import hashlib
import json
import os
import re
import sys
import tempfile
import types
import unittest
from pathlib import Path

HERE = Path(__file__).resolve().parent
SCRIPT = HERE / 'verify_thermo_shared_lifecycle.py'
sys.path.insert(0, str(HERE))
import strict_utf16 as _real_utf16  # noqa: E402
REAL_OUT = Path('/Users/jiangxuanyang/Desktop/cangjie'
                '/artifacts/h-r-final-20261002/thermo-shared')
REAL_EVIDENCE = REAL_OUT / 'thermo-shared.json'


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest() if path.exists() else None


def load_driver(ns_overrides):
    tree = ast.parse(SCRIPT.read_text())
    funcs = ast.Module(body=[n for n in tree.body
                             if isinstance(n, (ast.FunctionDef, ast.AsyncFunctionDef,
                                               ast.Assign, ast.ClassDef))],
                       type_ignores=[])
    ns = {'re': re, 'json': json, 'sys': sys, 'os': os,
          'time': types.SimpleNamespace(sleep=lambda _: None),
          'Path': Path, 'strict_utf16': types.SimpleNamespace(
              expected_replacement=lambda data, s, e, t: data)}
    ns['tc'] = types.SimpleNamespace(_m=types.SimpleNamespace(hilog_rows=lambda: []),
                                     BUNDLE_THERMO='test.bundle', HDC='hdc-stub')
    ns.update(ns_overrides)
    exec(compile(funcs, str(SCRIPT), 'exec'), ns)
    return ns


PREFIX_TMPL = '10-02 12:00:00.000  1234  1234 I A00000/X: '


def row(msg, pid='1234', sec=0):
    mm, ss = divmod(sec, 60)
    return (f'10-02 12:{mm:02d}:{ss:02d}.000  {pid}  {pid} I A00000/X: ') + msg


import importlib.util as _iu  # noqa: E402
_REAL_SPEC = _iu.spec_from_file_location('r13_real_device',
                                         HERE / 'h_source_preview_consumption.py')
REAL_DEVICE = _iu.module_from_spec(_REAL_SPEC)
_REAL_SPEC.loader.exec_module(REAL_DEVICE)


class _Device:
    """受控替身：真实 owner 字节/版本 + 真实共享生命周期日志行。

    与设备一致的粒度：uitest 文本注入按 ASCII 码元逐笔（version += len(t)）。
    mode 用于从正控派生负控：'ok' 正常、'zero' 零输入、'duplicate' 重复写。
    """

    def __init__(self, mode='ok'):
        self.note = ''
        self.version = 0
        self.rows = []
        self.calls = []
        self.last_selection = (0, 0)
        self.mount_gen = 0
        self.mode = mode
        self.sec = 0
        self.gen_semantic = 'gen-note-r3'
        # 与设备一致：IME field 由宿主编排为 node.semanticId，生成节点是自动
        # 编号（gen_semantic），不是候选声明的 field 属性。挂载后 field 作为
        # 当前挂载身份沿用，直到下一次 mount。
        self.current_field = 'hand-scroll-note'
        # round13-R3：当前挂载的完整身份元组（读回 edit= 段、观测与采纳共用）。
        self.last_mount_node = 942
        self.last_mount_resource = 9801
        self.last_mount_kind = 5
        self.last_mount_binding = 1
        self.last_mount_v = 4

    def _append(self, msg):
        self.sec += 1
        self.rows.append(row(msg, sec=self.sec))

    def mount(self, field):
        self.mount_gen += 1
        self.current_field = field
        # round14-A：挂载键按 CjguiProxyKey.describe() 真实形状——contextId 固定
        # c1、editGeneration e1（读回 gen=1），每次真实挂载只递增 mountGeneration。
        key = f'app1/s1/c1/e1/m{self.mount_gen}'
        self._append(f'proxy mounted key={key} field={field}')
        return key

    def wire_state(self):
        """与设备一致的 OWNER_STATE wire（读回 edit= 段随当前挂载取字段）。"""
        return ('ACCEPTED token=9 epoch=1 proj=1 nodes=1 semantic=1 frame=1 last=1 '
                'unacked=0 tickets=1 faces=1 edit=live ctx=1 gen=1 '
                f"node={self.last_mount_node} res={self.last_mount_resource} "
                f"kind={self.last_mount_kind} b={self.last_mount_binding} "
                f"v={self.last_mount_v} field={self.current_field}")

    def confirm(self, key, field, a, b):
        self._append(f'ime selection confirmed [{a},{b}) rc=0 (shared lifecycle) '
                     f'mount={key} field={field}')
        self._append(f'ime proxy selection terminal=INSTALLED reason=caret_confirmed '
                     f'target=[{a},{b}) mount={key} field={field}')
        # round13-R3：统一最终守卫的窗口事实与观测原语（与真实产物同形）。
        self._append(f'ime select [{a},{b}) rc=0 mount={key}')
        self._append(f'ime selection observation forwarded ctx=1 sel={a}:{b} '
                     f'node={self.last_mount_node} resource={self.last_mount_resource} '
                     f'kind={self.last_mount_kind} binding={self.last_mount_binding} '
                     f'v={self.last_mount_v} native_changed=0')
        # round14-A：ADOPTED2 owner_version = 当时 owner 状态版本（选择安装
        # 不产生 owner 事务，等于最近一次内容事务后的版本）。
        self._append(f'window-diag: CJGUI_OWNED_SELECTION_ADOPTED2 '
                     f'node={self.last_mount_node} resource={self.last_mount_resource} '
                     f'kind={self.last_mount_kind} sel={a}:{b} '
                     f'projection={self.last_mount_v} binding={self.last_mount_binding} '
                     f'owner_version={self.version} source_ctx=1 source_gen=1')

    # ---- tc._m doubles ----
    def hilog_rows(self):
        return list(self.rows)

    def parse_edit_section(self, state):
        return REAL_DEVICE.parse_edit_section(state)

    def uitest(self, action, *args):
        args = [str(a) for a in args]
        self.calls.append(('uitest', action, *args))
        if action == 'click':
            y = int(args[1])
            field = 'hand-scroll-note' if y < 150 else self.gen_semantic
            key = self.mount(field)
            self.confirm(key, field, 0, 0)
            self.last_selection = (0, 0)
        elif action == 'drag':
            # 拖选：当前挂载上的非空选区 [0,4)
            key = f'app1/s1/c1/e1/m{self.mount_gen}'
            self.confirm(key, self.current_field, 0, 4)
            self.last_selection = (0, 4)
        elif action == 'text':
            self._type(args[0])
        return None

    def _type(self, text):
        from strict_utf16 import expected_replacement
        if self.mode == 'zero':
            return  # 零输入：不改 owner，不增版本
        self.note = expected_replacement(
            self.note.encode('utf-8'), self.last_selection[0], self.last_selection[1],
            text).decode('utf-8')
        self.version += len(text)
        if self.mode == 'duplicate':
            self.version += 1  # 单笔受控意图被写两次
        key = f'app1/s1/c1/e1/m{self.mount_gen}'
        self.confirm(key, self.current_field, 0, 0)

    # ---- tc doubles ----
    def read_state(self):
        self.calls.append(('read_state',))
        return self.version, {'note': self.note}

    def invoke(self, action, expected, args=None):
        self.calls.append(('invoke', action))
        if action == 'SET_NOTE' and args:
            self.note = args[0][2]
            self.version += 1
            key = self.mount('hand-scroll-note')
            self.confirm(key, 'hand-scroll-note', 0, 0)
            self.last_selection = (0, 0)
            return {'applied': True}
        return {'applied': False}

    def business(self, lines):
        self.calls.append(('business', lines[0]))
        cmd = lines[0].split()[0]
        if cmd == 'GET_CONTEXT':
            # round14-B：_readback_full 消费同一响应里的 VERSION 与
            # OWNER_STATE_UTF8_HEX（判定身份/版本/字节同源）。
            state = self.wire_state()
            enc = state.encode('utf-8')
            resp = f'VERSION {self.version}\nOWNER_STATE_UTF8_HEX {len(enc)} {enc.hex().upper()}\n'
            return '', resp
        if cmd == 'GET_GENERATED_UI_CANDIDATE':
            return '', 'CANDIDATE_VERSION 7\n'
        if cmd == 'SUBMIT_GENERATED_UI':
            self._append(f'accepted node=7 semantic={self.gen_semantic} '
                         f'label=thermo-generated-note-r3')
            return '', 'APPLIED true\nCANDIDATE_ACCEPTED true\n'
        return '', ''

    def fields_of(self, text):
        mo = re.search(r'^VERSION (\d+)$', text, re.M)
        return (int(mo.group(1)) if mo else None), {'note': self.note}

    def tap_semantic(self, semantic, fallback_xy=None):
        self.calls.append(('tap_semantic', semantic))
        key = self.mount('hand-scroll-note')
        self.confirm(key, 'hand-scroll-note', 0, 0)
        self.last_selection = (0, 0)
        return (100, 100)

    def thermo_semantic_point(self, semantic):
        self.calls.append(('point', semantic))
        return (200, 200) if semantic == self.gen_semantic else (100, 100)


def _driver_namespace(device, fwd_ok=True, tmp=None):
    """把替身接进驱动命名空间；fwd_ok=False 时转发创建失败。"""

    def fake_run(argv, **kw):
        argv = list(argv)
        device.calls.append(('run', argv[1:3]))
        if argv[1:3] == ['fport', 'tcp:17857']:
            if fwd_ok:
                return types.SimpleNamespace(returncode=0, stdout='Forwardport result:OK', stderr='')
            return types.SimpleNamespace(returncode=32, stdout='[Fail] mapping already exists', stderr='')
        if argv[1:3] == ['fport', 'ls']:
            listing = ('hdc tcp:17857 tcp:7857 [Forward]\n' if fwd_ok else 'hdc tcp:9999 tcp:1 [Forward]\n')
            return types.SimpleNamespace(returncode=0, stdout=listing, stderr='')
        if argv[1:3] == ['fport', 'rm']:
            return types.SimpleNamespace(returncode=0, stdout='Remove success', stderr='')
        return types.SimpleNamespace(returncode=0, stdout='1234\n', stderr='')

    ns = load_driver({
        'subprocess': types.SimpleNamespace(run=fake_run),
        'HDC': 'hdc-stub',
        'strict_utf16': _real_utf16,
    })
    ns['thermo_pid'] = lambda: '1234'
    ns['tc'] = types.SimpleNamespace(
        _m=types.SimpleNamespace(hilog_rows=device.hilog_rows, uitest=device.uitest,
                                 parse_edit_section=REAL_DEVICE.parse_edit_section),
        BUNDLE_THERMO='test.bundle', HDC='hdc-stub',
        tap_semantic=device.tap_semantic, thermo_semantic_point=device.thermo_semantic_point,
        read_state=device.read_state, invoke=device.invoke, business=device.business,
        fields_of=device.fields_of,
        # round13-R1/R3：读回按真实 wire 形状给出**当前挂载**的 live 身份
        # （统一最终守卫必须消费权威当前身份；随 mount/confirm 动态取字段）。
        readback_owner_state=lambda: (
            'ACCEPTED token=9 epoch=1 proj=1 nodes=1 semantic=1 frame=1 last=1 '
            'unacked=0 tickets=1 faces=1 edit=live ctx=1 gen=1 '
            f"node={device.last_mount_node} res={device.last_mount_resource} "
            f"kind={device.last_mount_kind} b={device.last_mount_binding} "
            f"v={device.last_mount_v} field={device.current_field}"),
        parse_edit_section=REAL_DEVICE.parse_edit_section,
        inject_tap=lambda x, y: '0',
        # round12-R2：定位走读回几何；桩映射到带**安装确认副作用**的 tap_semantic
        # （focus-nav 腿的确认对由它发出），纯点查询映射 thermo_semantic_point。
        readback_semantic_point=(
            lambda semantic: device.tap_semantic(semantic)
            if semantic == 'thermo-focus-note-nav'
            else device.thermo_semantic_point(semantic)))
    return ns


class ThermoSharedDriverNegativesTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.real_before = sha(REAL_EVIDENCE)

    @classmethod
    def tearDownClass(cls):
        after = sha(REAL_EVIDENCE)
        assert after == cls.real_before, (
            '历史设备证据被测试覆写: %s -> %s' % (cls.real_before, after))

    # ---------- 正控：actual main 走到 exit0 / OK ----------
    def test_actual_main_positive_control_reaches_ok(self):
        device = _Device('ok')
        ns = _driver_namespace(device)
        with tempfile.TemporaryDirectory(prefix='cjgui-h-pos-') as tmp:
            exit_code = ns['main'](tmp)
            results = json.loads((Path(tmp) / 'thermo-shared.json').read_text())
        self.assertEqual(exit_code, 0, results.get('status'))
        self.assertEqual(results['status'], 'OK')
        leg_names = {leg['leg'] for leg in results['legs']}
        self.assertTrue({'input-insert', 'exact-replace', 'external-set',
                         'continue-input', 'generated-input', 'hand-revisit-input',
                         'generated-revisit-input'} <= leg_names, leg_names)
        # 单笔意图严格恰好一笔；多字符 ASCII 注入按声明粒度。
        for leg in results['legs']:
            if 'exactly_once' in leg:
                self.assertTrue(leg['exactly_once'], leg)

    # ---------- 负控 5/6：零输入、重复写必须具名拒绝 ----------
    def test_zero_input_is_rejected(self):
        device = _Device('zero')
        ns = _driver_namespace(device)
        with tempfile.TemporaryDirectory(prefix='cjgui-h-zero-') as tmp:
            exit_code = ns['main'](tmp)
            results = json.loads((Path(tmp) / 'thermo-shared.json').read_text())
        self.assertNotEqual(exit_code, 0)
        self.assertEqual(results['status'], 'owner_never_matched')

    def test_duplicate_write_is_rejected(self):
        device = _Device('duplicate')
        ns = _driver_namespace(device)
        with tempfile.TemporaryDirectory(prefix='cjgui-h-dup-') as tmp:
            exit_code = ns['main'](tmp)
            results = json.loads((Path(tmp) / 'thermo-shared.json').read_text())
        self.assertNotEqual(exit_code, 0)
        self.assertEqual(results['status'], 'version_delta_mismatch')

    # ---------- 负控 7：未知端点（转发创建失败） ----------
    def test_forward_creation_failure_blocks_and_never_removes(self):
        device = _Device('ok')
        ns = _driver_namespace(device, fwd_ok=False)
        with tempfile.TemporaryDirectory(prefix='cjgui-h-fwd-') as tmp:
            exit_code = ns['main'](tmp)
            results = json.loads((Path(tmp) / 'thermo-shared.json').read_text())
        self.assertEqual(exit_code, 3)
        self.assertEqual(results['status'], 'forward_unavailable')
        self.assertFalse(results['forward_created'])
        # 未借未知固定端点继续写应用；未对他方映射发 rm。
        app_calls = [c for c in device.calls if c[0] in ('uitest', 'business', 'invoke', 'tap_semantic')]
        self.assertEqual(app_calls, [], app_calls)
        self.assertEqual([c for c in device.calls if c[:2] == ('run', ['fport', 'rm'])], [])

    # ---------- 负控 4：错 PID ----------
    def test_wrong_pid_rows_are_never_used(self):
        rows = [row('D 9999 unrelated terminal=INSTALLED', pid='9999'),
                row('ime select [1,1) rc=0', pid='1234')]
        ns = load_driver({})
        ns['tc'] = types.SimpleNamespace(_m=types.SimpleNamespace(hilog_rows=lambda: rows))
        used = ns['rows_for']('1234')
        self.assertTrue(used and all(' 9999 ' not in r.split(' I ')[0] for r in used), used)
        self.assertEqual(ns['rows_for'](''), [])
        self.assertEqual(ns['rows_for']('8888'), [])

    # ---------- 负控 1：错字段 ----------
    def test_wrong_field_does_not_pair(self):
        ns = load_driver({})
        rows = [row('proxy mounted key=app1/s1/c7/e1/m1 field=other-field'),
                row('ime select [0,4) rc=0 mount=app1/s1/c7/e1/m1'),
                row('ime selection observation forwarded ctx=7 sel=0:4 node=942 '
                    'resource=9801 kind=5 binding=1 v=4 native_changed=0'),
                row('window-diag: CJGUI_OWNED_SELECTION_ADOPTED2 node=942 resource=9801 '
                    'kind=5 sel=0:4 projection=4 binding=1 owner_version=1 '
                    'source_ctx=7 source_gen=1'),
                row('ime selection confirmed [0,4) rc=0 (shared lifecycle) mount=app1/s1/c7/e1/m1 field=other-field'),
                row('ime proxy selection terminal=INSTALLED reason=caret_confirmed '
                    'target=[0,4) mount=app1/s1/c7/e1/m1 field=other-field')]
        ident = {'live': True, 'ctx': 7, 'gen': 1, 'node': 942, 'resource': 9801,
                 'kind': 5, 'binding': 1, 'v': 4, 'field': 'other-field',
                 'source': 'readback_edit_identity'}
        # round14-A：统一门要求冻结 owner 基线（行内 ADOPTED2 owner_version=1）。
        self.assertIsNone(ns['confirmed_selection'](rows, 0, {'field': 'hand-scroll-note',
                                                              'readback_identity': ident,
                                                              'owner_version': 1}))
        # 期望 field 自身存在时才配对。
        self.assertEqual(
            ns['confirmed_selection'](rows, 0, {'field': 'other-field',
                                                'readback_identity': ident,
                                                'owner_version': 1}), (0, 4))

    # ---------- 负控 2：同坐标跨 mount 拼接 ----------
    def test_same_coord_cross_mount_does_not_pair(self):
        ns = load_driver({})
        rows = [row('proxy mounted key=app1/s1/c1/e1/m1 field=hand-scroll-note'),
                row('ime selection confirmed [0,4) rc=0 (shared lifecycle) '
                    'mount=app1/s1/c1/e1/m1 field=hand-scroll-note'),
                row('proxy mounted key=app1/s1/c1/e1/m2 field=hand-scroll-note'),
                row('ime proxy selection terminal=INSTALLED reason=caret_confirmed '
                    'target=[0,4) mount=app1/s1/c1/e1/m2 field=hand-scroll-note')]
        self.assertIsNone(ns['confirmed_selection'](rows, 1, {'field': 'hand-scroll-note'}))

    # ---------- 负控 3：旧确认复活 ----------
    def test_old_confirmation_not_revived_by_unrelated_terminal(self):
        ns = load_driver({})
        old = [row('proxy mounted key=app1/s1/c7/e1/m3 field=hand-scroll-note'),
               row('ime selection confirmed [0,4) rc=0 (shared lifecycle) mount=app1/s1/c7/e1/m3 field=hand-scroll-note'),
               row('ime proxy selection terminal=INSTALLED reason=caret_confirmed '
                   'target=[0,4) mount=app1/s1/c7/e1/m3 field=hand-scroll-note')]
        unrelated = [row('ime proxy selection terminal=INSTALLED reason=caret_confirmed '
                         'target=[8,8) mount=app1/s1/c7/e1/m9 field=hand-scroll-note')]
        self.assertIsNone(ns['confirmed_selection'](old + unrelated, len(old),
                                                    {'field': 'hand-scroll-note'}))
        own = [row('ime select [2,5) rc=0 mount=app1/s1/c7/e1/m3'),
               row('ime selection observation forwarded ctx=7 sel=2:5 node=942 '
                   'resource=9801 kind=5 binding=1 v=6 native_changed=0'),
               row('window-diag: CJGUI_OWNED_SELECTION_ADOPTED2 node=942 resource=9801 '
                   'kind=5 sel=2:5 projection=6 binding=1 owner_version=1 '
                   'source_ctx=7 source_gen=1'),
               row('ime selection confirmed [2,5) rc=0 (shared lifecycle) mount=app1/s1/c7/e1/m3 field=hand-scroll-note'),
               row('ime proxy selection terminal=INSTALLED reason=caret_confirmed '
                   'target=[2,5) mount=app1/s1/c7/e1/m3 field=hand-scroll-note')]
        ident = {'live': True, 'ctx': 7, 'gen': 1, 'node': 942, 'resource': 9801,
                 'kind': 5, 'binding': 1, 'v': 6, 'field': 'hand-scroll-note',
                 'source': 'readback_edit_identity'}
        self.assertEqual(
            ns['confirmed_selection'](old + unrelated + own, len(old + unrelated),
                                      {'field': 'hand-scroll-note',
                                       'readback_identity': ident,
                                       'owner_version': 1}), (2, 5))

    # ---------- 缺身份即具名拒绝 ----------
    def test_missing_expect_identity_is_refused(self):
        ns = load_driver({})
        with self.assertRaises(ValueError):
            ns['confirmed_selection']([row('proxy mounted key=K field=f')], 0)


if __name__ == '__main__':
    unittest.main()

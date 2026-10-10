#!/usr/bin/env python3
"""round6-A 回归：恢复证据必须核对**当前有效绑定**。

round6-review 两条新格式反例（已用当前生产函数复现）：
  * coherent_but_retired_context：ctx99 的 ACK 与新格式 ADOPTED 彼此完全一致
    （同 request/落点/版本），但当前 focus 是 ctx7 —— 必须拒绝。
  * 挂载路径：focus/forwarded/BIND_OWNER 组合不构成采纳；必须有同挂载的
    窗口采纳事实（CJGUI_OWNED_SELECTION_ADOPTED2）且落点与观测一致。
正控：当前上下文的显式票、带采纳事实的挂载快照各一条。

round11 复跑更新（夹具对齐当前生产契约，业务判据一条未变）：
  * round9 起 `body_restore_evidence` 依赖 `_mount_lifecycle`，抽取清单补上；
  * focus/观测行带完整身份元组（resource/kind/binding/v）；
  * ADOPTED2 带 owner_version（round8 起必填）与冻结来源 source_ctx/source_gen
    （round9-A 起必填）；`adoption_count_basis` 更名为当前生产值
    `frozen-source+window-adoption-fact+identity-tuple`。
"""
import ast
import re
import unittest
from pathlib import Path

HERE = Path(__file__).resolve().parent
SOURCE = HERE / 'verify_pharos_dual_owner.py'

NAMES = ('_mount_lifecycle', '_identity_mismatch', '_version_behind',
         'body_restore_evidence')
_tree = ast.parse(SOURCE.read_text())
_nodes = [n for n in _tree.body if isinstance(n, ast.FunctionDef) and n.name in NAMES]
assert {n.name for n in _nodes} == set(NAMES), sorted(n.name for n in _nodes)
_ns = {'re': re, 'BODY_FIELD': 'pharos-editor-body'}
exec(compile(ast.Module(body=_nodes, type_ignores=[]), str(SOURCE), 'exec'), _ns)
fn = _ns['body_restore_evidence']

FOCUS7 = ('platform focus node=107 ctx=7 field=pharos-editor-body '
          'resource=54 kind=10 binding=6 v=36')
# round13-R1：最终门消费权威当前身份——各用例按真实读回 wire 形状给 live hint。
HINT7 = {'ctx': 7, 'node': 107, 'field': 'pharos-editor-body', 'resource': 54,
         'kind': 10, 'binding': 6, 'v': 36, 'gen': 1, 'live': True}
OBS7 = ('ime selection observation forwarded ctx=7 sel=3:3 node=107 '
        'resource=54 kind=10 binding=6 v=36 native_changed=0')
ADOPT2_7 = ('window-diag: CJGUI_OWNED_SELECTION_ADOPTED2 node=107 resource=54 '
            'kind=10 sel=3:3 projection=36 binding=6 owner_version=2 '
            'source_ctx=7 source_gen=3')
BOUND = 'PHAROS_OHOS_BIND_OWNER owner=main mirror_version=2 mirror_bytes=137 owner_version=2'


class Round6RestorePairingTest(unittest.TestCase):
    def test_current_context_new_format_positive(self):
        rows = [FOCUS7,
                'proxy restore ack accepted request=4 ctx=7 node=107 installed=3:3 v=36',
                'PHAROS_OHOS_RESTORE_ADOPTED count=2 request=4 ctx=7 node=107 '
                'adopted=3:3 owner_version=2 v=36']
        got = fn(rows, 0, 107, 1, 'main', owner_version=2, identity_hint=HINT7)
        self.assertEqual(got.get('source'), 'restore_ack', got)

    def test_coherent_but_retired_context_rejected(self):
        # round6 反例：记录彼此一致但 ctx99 不是当前上下文。
        rows = [FOCUS7,
                'proxy restore ack accepted request=4 ctx=99 node=107 installed=3:3 v=36',
                'PHAROS_OHOS_RESTORE_ADOPTED count=2 request=4 ctx=99 node=107 '
                'adopted=3:3 owner_version=2 v=36']
        got = fn(rows, 0, 107, 1, 'main', owner_version=2, identity_hint=HINT7)
        # round9 起具名更精确：身份元组不匹配（mismatch='ctx'）而非笼统 stale。
        self.assertEqual(got.get('source'), 'restore_ack_identity_not_current', got)
        self.assertEqual(got.get('current_identity', {}).get('ctx'), 7, got)

    def test_mount_path_requires_window_adoption_fact(self):
        base = [FOCUS7, OBS7, BOUND]
        got = fn(base, 0, 107, 1, 'main', owner_version=2, identity_hint=HINT7)
        # focus/观测/BIND_OWNER 组合不得推断采纳：无窗口采纳事实时是**等待态**
        # （None，主循环继续轮询），绝不推断成立。
        self.assertIsNone(got, 'focus/forwarded/BIND_OWNER 组合不得推断采纳')

    def test_mount_path_with_adoption_fact_accepted(self):
        rows = [FOCUS7, OBS7, ADOPT2_7, BOUND]
        got = fn(rows, 0, 107, 1, 'main', owner_version=2, identity_hint=HINT7)
        self.assertEqual(got.get('source'), 'mount_snapshot', got)
        self.assertEqual(got.get('adoption_count_basis'),
                         'frozen-source+window-adoption-fact+identity-tuple', got)

    def test_mount_adoption_fact_wrong_selection_rejected(self):
        rows = [FOCUS7, OBS7, ADOPT2_7.replace('sel=3:3', 'sel=9:9'), BOUND]
        got = fn(rows, 0, 107, 1, 'main', owner_version=2, identity_hint=HINT7)
        # round9 起拒绝是**具名字典**（不成立 ≠ 静默 None）：落点不一致具名。
        self.assertEqual(got.get('source'), 'mount_snapshot_selection_mismatch', got)

    def test_focus_switch_retires_old_context_candidates(self):
        # 换 focus（ctx7→ctx8）后，ctx7 时期的采纳事实不得拼到新挂载。
        rows = [FOCUS7, OBS7, ADOPT2_7,
                'platform focus node=107 ctx=8 field=pharos-editor-body '
                'resource=54 kind=10 binding=6 v=36',
                BOUND]
        got = fn(rows, 0, 107, 1, 'main', owner_version=2, identity_hint=HINT7)
        self.assertIsNone(got, '旧上下文的采纳候选必须随 focus 切换退役')


if __name__ == '__main__':
    unittest.main()

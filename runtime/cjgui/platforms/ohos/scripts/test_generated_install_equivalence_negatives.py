#!/usr/bin/env python3
"""round14-A：thermo 两种安装来源**归一后**的最终守卫反例（离线，无设备）。

round14 指导复核（guidance-review/round14-review.md）证明 round13 的双分支
判据强弱不一：标准分支漏验观测选区、source_gen 值、观测→采纳顺序，且允许
native 人锚替代窗口采纳；等价分支漏比 source_gen 和 owner 基线。九类错误
输入曾被接受（冻结 RED：guidance-review/round14-review.json）。

修复：`_standard_terminal_gate`/`_install_adoption_identity_gate` 撤销，标准
terminal 配对与等价链 `ime select rc=0` 只作为**两种安装凭据**进入唯一的
`_final_adoption_identity_gate`（安装→观测→窗口采纳→当前身份单出口）；
`human anchor recorded` 不再是采纳证据（设备原件第 19601 行人锚之后第
20073 行才是真正 ADOPTED2）。

本套件 AST 抽取**生产**判定函数逐字执行；正控含当前投影版本推进与
thermo-final 原件真实行（按行号取自归档并校验整体 sha256，防转录漂移）；
负控为 round14 冻结九类反例（两种安装来源各覆盖其适用分支）与既有逐字段
变异。RED 原件不覆盖，本套件即常驻回归。
"""
import ast
import hashlib
import re
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
SOURCE = HERE / 'verify_thermo_shared_lifecycle.py'
ROOT = HERE.parents[4]
LEGACY = ROOT / 'artifacts/h-r-final-20261002/round13-fix/thermo-final/hilog_cjgui_rows.txt'
LEGACY_SHA256 = 'e9c3f749952d4279aa04347b77489d1ca35f789e43375619b0d619bde306e0b9'  # round14-review.json 记录

failures = []


def check(name, got, want):
    ok = got == want
    print(f"  {'OK  ' if ok else 'FAIL'} {name}: {got!r}" + ('' if ok else f' (want {want!r})'))
    if not ok:
        failures.append(name)


src = SOURCE.read_text()
tree = ast.parse(src)
NAMES = ('_final_adoption_identity_gate', 'confirmed_selection',
         '_resolve_fence', '_row_ts')
nodes = [n for n in tree.body if isinstance(n, ast.FunctionDef) and n.name in NAMES]
assert {n.name for n in nodes} == set(NAMES), sorted(n.name for n in nodes)
CONSTS = ('_PROXY_KEY_RE', '_OBS_RE', '_ADOPTED_RE', '_ROW_TS')
const_nodes = []
for n in tree.body:
    if isinstance(n, ast.Assign) and any(
            isinstance(t, ast.Name) and t.id in CONSTS for t in n.targets):
        const_nodes.append(n)
assert len(const_nodes) == len(CONSTS), '判定用的编译正则必须齐全'
assert not re.search(r'^def _standard_terminal_gate', src, re.M), 'human-anchor/旧双分支必须已移除'
assert 'origin=selection_drag_end' not in src.split('def _final_adoption_identity_gate')[1].split('def confirmed_selection')[0], \
    '统一门内不得存在人锚匹配分支（文档性提及除外）'
ns = {'re': re}
exec(compile(ast.Module(body=const_nodes + nodes, type_ignores=[]), str(SOURCE),
             'exec'), ns)
confirmed_selection = ns['confirmed_selection']

MOUNT = 'app1/s1/c3/e1/m3'
FIELD = 'component-2-1'
NODE = 802001
CTX = 3
SEL = (1, 1)


def rows(install=True, obs_ctx=CTX, adopted=True, terminal=False, sel=SEL,
         adopted_over=None):
    out = [f'10-03 21:35:54.259 32064 32064 I A00000/CjguiApp: '
           f'ime proxy mounted ctx={CTX} field={FIELD} node={NODE} gen=1 base=35',
           f'10-03 21:35:54.259 32064 32064 I A00000/CjguiApp: '
           f'proxy mounted key={MOUNT} field={FIELD}']
    if install:
        out.append(f'10-03 21:35:54.371 32064 32064 I A00000/CjguiApp: '
                   f'ime select [{sel[0]},{sel[1]}) rc=0 mount={MOUNT}')
    out.append(f'10-03 21:35:54.378 32064 32064 I A00000/CjguiRenderer: '
               f'ime selection observation forwarded ctx={obs_ctx} sel={sel[0]}:{sel[1]} '
               f'node={NODE} resource=9801 kind=5 binding=35 v=35 native_changed=0')
    if adopted:
        over = adopted_over or {}
        resource = over.get('resource', 9801)
        kind_v = over.get('kind', 5)
        projection = over.get('projection', 35)
        binding_v = over.get('binding', 35)
        owner_version = over.get('owner_version', 29)
        source_gen = over.get('source_gen', 1)
        seg = (f'10-03 21:35:54.393 32064 13003 I A00000/CjguiRenderer: window-diag: '
               f'CJGUI_OWNED_SELECTION_ADOPTED2 node={NODE} resource={resource} '
               f'kind={kind_v} sel={sel[0]}:{sel[1]} projection={projection} '
               f'binding={binding_v}')
        if owner_version is not None:
            seg += f' owner_version={owner_version}'
        if source_gen is not None:
            seg += f' source_ctx={obs_ctx} source_gen={source_gen}'
        out.append(seg)
    if terminal:
        out.append(f'10-03 21:35:54.400 32064 32064 I A00000/CjguiApp: '
                   f'ime selection confirmed [{sel[0]},{sel[1]}) rc=0 (shared lifecycle) '
                   f'mount={MOUNT} field={FIELD}')
        out.append(f'10-03 21:35:54.410 32064 32064 I A00000/CjguiApp: '
                   f'ime proxy selection terminal=INSTALLED reason=attach_confirmed '
                   f'target=[{sel[0]},{sel[1]}) mount={MOUNT} field={FIELD}')
    return out


# ---- thermo-final 原件真实行（按行号取，防漂移三重校验：文件存在、整体
# sha256 与 round14-review.json 记录一致、逐行含期望标记）----
_LEGACY_LINES = {
    4105: 'proxy mounted key=app1/s1/c1/e1/m1 field=hand-scroll-note',
    4191: 'ime selection observation forwarded ctx=1 sel=0:0',
    4192: 'ime select [0,0) rc=0 mount=app1/s1/c1/e1/m1',
    4201: 'CJGUI_OWNED_SELECTION_ADOPTED2 node=942 resource=9801 kind=5 sel=0:0 '
          'projection=4 binding=1 owner_version=0 source_ctx=1 source_gen=1',
    19601: 'human anchor recorded origin=selection_drag_end seq=5 node=942 sel=13:17',
    19820: 'ime selection observation forwarded ctx=1 sel=13:17 node=942 resource=9801 '
           'kind=5 binding=1 v=31',
    19821: 'ime select [13,17) rc=0 mount=app1/s1/c1/e1/m1',
    20073: 'CJGUI_OWNED_SELECTION_ADOPTED2 node=942 resource=9801 kind=5 sel=13:17 '
           'projection=31 binding=1 owner_version=26 source_ctx=1 source_gen=1',
    20097: 'ime selection confirmed [13,17) rc=0 (shared lifecycle) '
           'mount=app1/s1/c1/e1/m1 field=hand-scroll-note',
    20099: 'ime proxy selection terminal=INSTALLED reason=caret_confirmed '
           'target=[13,17) mount=app1/s1/c1/e1/m1 field=hand-scroll-note',
    22047: 'proxy mounted key=app1/s1/c2/e1/m2 field=hand-scroll-note',
    22249: 'ime selection observation forwarded ctx=2 sel=15:15 node=942 resource=9801 '
           'kind=5 binding=1 v=33',
    22250: 'ime select [15,15) rc=0 mount=app1/s1/c2/e1/m2',
    22299: 'CJGUI_OWNED_SELECTION_ADOPTED2 node=942 resource=9801 kind=5 sel=15:15 '
           'projection=33 binding=1 owner_version=28 source_ctx=2 source_gen=1',
    26033: 'ime proxy mounted ctx=3 field=component-2-1 node=802001 gen=1 base=35',
    26034: 'proxy mounted key=app1/s1/c3/e1/m3 field=component-2-1',
    26140: 'ime selection observation forwarded ctx=3 sel=16:16 node=802001 '
           'resource=9801 kind=5 binding=35 v=35',
    26141: 'ime select [16,16) rc=0 mount=app1/s1/c3/e1/m3',
    26175: 'CJGUI_OWNED_SELECTION_ADOPTED2 node=802001 resource=9801 kind=5 sel=16:16 '
           'projection=35 binding=35 owner_version=29 source_ctx=3 source_gen=1',
    28972: 'proxy mounted key=app1/s1/c4/e1/m4 field=hand-scroll-note',
    29030: 'ime selection observation forwarded ctx=4 sel=18:18 node=942 resource=9801 '
           'kind=5 binding=1 v=37',
    29031: 'ime select [18,18) rc=0 mount=app1/s1/c4/e1/m4',
    29069: 'CJGUI_OWNED_SELECTION_ADOPTED2 node=942 resource=9801 kind=5 sel=18:18 '
           'projection=37 binding=1 owner_version=31 source_ctx=4 source_gen=1',
    29215: 'ime selection confirmed [18,18) rc=0 (shared lifecycle) '
           'mount=app1/s1/c4/e1/m4 field=hand-scroll-note',
    29217: 'ime proxy selection terminal=INSTALLED reason=attach_confirmed '
           'target=[18,18) mount=app1/s1/c4/e1/m4 field=hand-scroll-note',
    31836: 'proxy mounted key=app1/s1/c5/e1/m5 field=component-2-1',
    32083: 'ime selection observation forwarded ctx=5 sel=16:16 node=802001 '
           'resource=9801 kind=5 binding=35 v=38',
    32084: 'ime select [16,16) rc=0 mount=app1/s1/c5/e1/m5',
    32095: 'CJGUI_OWNED_SELECTION_ADOPTED2 node=802001 resource=9801 kind=5 sel=16:16 '
           'projection=38 binding=35 owner_version=32 source_ctx=5 source_gen=1',
    32218: 'ime selection confirmed [16,16) rc=0 (shared lifecycle) '
           'mount=app1/s1/c5/e1/m5 field=component-2-1',
    32220: 'ime proxy selection terminal=INSTALLED reason=attach_confirmed '
           'target=[16,16) mount=app1/s1/c5/e1/m5 field=component-2-1',
}


def legacy_lines():
    """取真实原件行；文件缺失或 sha256/标记不符即失败（防转录与归档漂移）。"""
    if not LEGACY.exists():
        raise SystemExit(f'legacy archive missing: {LEGACY}')
    sha = hashlib.sha256(LEGACY.read_bytes()).hexdigest()
    if sha != LEGACY_SHA256:
        raise SystemExit(f'legacy archive sha256 drift: {sha}')
    all_rows = LEGACY.read_text().splitlines()
    out = {}
    for num, marker in _LEGACY_LINES.items():
        line = all_rows[num - 1]
        assert marker in line, f'line {num} marker drift: {marker!r} not in {line!r}'
        out[num] = line
    return out


def ident(ctx, gen, node, binding, v, field):
    return {'live': True, 'ctx': ctx, 'gen': gen, 'node': node,
            'resource': 9801, 'kind': 5, 'binding': binding, 'v': v,
            'field': field, 'source': 'readback_edit_identity'}


def main():
    print('== round14 thermo 归一最终守卫（两种安装凭据一个出口） ==')
    IDENT9 = ident(CTX, 1, NODE, 35, 35, FIELD)
    expect = {'field': FIELD, 'readback_identity': IDENT9, 'owner_version': 29}
    # ---- 正控 ----
    check('positive-equivalent-chain', confirmed_selection(rows(), 0, expect), SEL)
    check('positive-current-projection-advanced',
          confirmed_selection(rows(), 0,
                              dict(expect, readback_identity=dict(IDENT9, v=36))),
          SEL)
    check('standard-terminal-with-adoption-passes',
          confirmed_selection(rows(terminal=True), 0, expect), SEL)
    # ---- 既有逐字段负控（等价链）----
    check('negative-missing-platform-install',
          confirmed_selection(rows(install=False), 0, expect), None)
    check('negative-stale-ctx-observation',
          confirmed_selection(rows(obs_ctx=CTX + 5), 0, expect), None)
    check('negative-missing-window-adoption',
          confirmed_selection(rows(adopted=False), 0, expect), None)
    check('negative-no-readback-identity',
          confirmed_selection(rows(), 0, {'field': FIELD, 'owner_version': 29}), None)
    check('negative-readback-none',
          confirmed_selection(rows(), 0, {'field': FIELD, 'owner_version': 29,
                                          'readback_identity': {'live': False}}), None)
    check('fence-excludes-stale-chain', confirmed_selection(rows(), 6, expect), None)
    check('negative-adopted-resource-conflict',
          confirmed_selection(rows(adopted_over={'resource': 9999}), 0, expect), None)
    check('negative-adopted-kind-conflict',
          confirmed_selection(rows(adopted_over={'kind': 10}), 0, expect), None)
    check('negative-adopted-binding-conflict',
          confirmed_selection(rows(adopted_over={'binding': 999}), 0, expect), None)
    check('negative-adopted-projection-conflict',
          confirmed_selection(rows(adopted_over={'projection': 99}), 0, expect), None)
    check('negative-adopted-owner-version-missing',
          confirmed_selection(rows(adopted_over={'owner_version': None}), 0, expect),
          None)
    check('negative-adopted-source-gen-missing',
          confirmed_selection(rows(adopted_over={'source_gen': None}), 0, expect), None)
    check('negative-adopted-source-gen-unverified',
          confirmed_selection(rows(adopted_over={'source_gen': 'unverified'}), 0,
                              expect), None)
    check('negative-adopted-source-gen-value-conflict',
          confirmed_selection(rows(adopted_over={'source_gen': 999}), 0, expect), None)
    check('negative-readback-ctx-mismatch',
          confirmed_selection(rows(), 0,
                              dict(expect, readback_identity=dict(IDENT9, ctx=99))),
          None)
    check('negative-readback-binding-mismatch',
          confirmed_selection(rows(), 0,
                              dict(expect, readback_identity=dict(IDENT9, binding=99))),
          None)
    check('negative-readback-field-mismatch',
          confirmed_selection(rows(), 0,
                              dict(expect, readback_identity=dict(IDENT9, field='other'))),
          None)
    # 事件顺序：窗口采纳先于它所采的观测 → 不成立。
    r_all = rows()
    obs_row = next(r for r in r_all if 'observation forwarded' in r)
    adopt_row = next(r for r in r_all if 'ADOPTED2' in r)
    rest = [r for r in r_all if r not in (obs_row, adopt_row)]
    reordered = rest[:2] + [adopt_row, obs_row] + rest[2:]
    check('negative-adoption-before-observation',
          confirmed_selection(reordered, 0, expect), None)
    # ---- round14 冻结 RED：等价分支 ----
    check('red-equivalent-wrong-source-gen-999',
          confirmed_selection(rows(adopted_over={'source_gen': 999}), 0, expect), None)
    check('red-equivalent-unknown-owner-version-minus1',
          confirmed_selection(rows(adopted_over={'owner_version': -1}), 0, expect), None)
    check('red-equivalent-wrong-owner-version-999',
          confirmed_selection(rows(adopted_over={'owner_version': 999}), 0, expect), None)
    mismatch_key = 'app1/s1/c99/e9/m99'
    check('red-equivalent-mount-context-mismatch',
          confirmed_selection([r.replace(MOUNT, mismatch_key) for r in rows()], 0,
                              expect), None)
    # ---- round14 冻结 RED：标准分支 ----
    check('red-standard-unverified-source-gen',
          confirmed_selection(rows(terminal=True, adopted_over={'source_gen': 'unverified'}),
                              0, expect), None)
    check('red-standard-wrong-source-gen-999',
          confirmed_selection(rows(terminal=True, adopted_over={'source_gen': 999}),
                              0, expect), None)
    r_obs_other = rows(terminal=True)
    r_obs_other = [x.replace('sel=1:1', 'sel=9:9')
                   if 'observation forwarded' in x else x for x in r_obs_other]
    check('red-standard-observation-is-other-selection',
          confirmed_selection(r_obs_other, 0, expect), None)
    r_order = rows(terminal=True)
    i_adopt = next(i for i, x in enumerate(r_order) if 'ADOPTED2' in x)
    ar = r_order.pop(i_adopt)
    oi = next(i for i, x in enumerate(r_order) if 'observation forwarded' in x)
    r_order.insert(oi, ar)
    check('red-standard-adoption-before-observation',
          confirmed_selection(r_order, 0, expect), None)
    check('red-standard-native-anchor-only-no-window-adoption',
          confirmed_selection(
              rows(terminal=True, adopted=False) + [
                  '10-03 21:35:54.670 32064 12447 I A00000/CjguiRenderer: '
                  'human anchor recorded origin=selection_drag_end seq=5 '
                  f'node={NODE} sel={SEL[0]}:{SEL[1]}'], 0, expect), None)
    check('red-standard-terminal-without-window-fact-rejected',
          confirmed_selection(rows(terminal=True, adopted=False), 0, expect), None)
    check('negative-missing-owner-baseline-rejected',
          confirmed_selection(rows(), 0,
                              {'field': FIELD, 'readback_identity': IDENT9}), None)
    check('negative-owner-baseline-not-int-rejected',
          confirmed_selection(rows(), 0,
                              dict(expect, owner_version='29')), None)
    check('standard-terminal-stale-ctx-rejected',
          confirmed_selection(rows(terminal=True, obs_ctx=CTX + 5), 0, expect), None)
    # ---- B 判定点归档契约：facts 回填判定真正使用的事实与行号 ----
    facts = {}
    got = confirmed_selection(rows(terminal=True), 0, expect, facts=facts)
    check('facts-verdict', got, SEL)
    check('facts-mount-key', facts.get('mount_key'), MOUNT)
    check('facts-install-kind', (facts.get('install') or {}).get('kind'), 'terminal')
    check('facts-obs-row', (facts.get('observation') or {}).get('sel'), SEL)
    check('facts-adopted-owner-version',
          (facts.get('adopted') or {}).get('owner_version'), 29)
    check('facts-row-indices-ordered',
          facts.get('obs_row_idx', 1 << 30) <= facts.get('adopted_row_idx', -1), True)

    # ---- thermo-final 原件真实行回放（round14-B：离线重判同一判据）----
    L = legacy_lines()
    print('  -- legacy thermo-final real-row replay --')
    # 腿1 安装（等价链，attach [0,0)）：owner 基线 0。
    leg1_rows = [L[4105], L[4191], L[4192], L[4201]]
    leg1_ident = ident(1, 1, 942, 1, 4, 'hand-scroll-note')
    check('legacy-1-install-attach-equivalence',
          confirmed_selection(leg1_rows, 0,
                              {'field': 'hand-scroll-note',
                               'readback_identity': leg1_ident,
                               'owner_version': 0}), (0, 0))
    # 腿3 拖选（标准 terminal + 真实 ADOPTED2；人锚行在真实流里被忽略）：
    # owner 基线 26（26 字符插入后的公开版本）。
    leg3_rows = [L[4105], L[19601], L[19820], L[19821], L[20073], L[20097], L[20099]]
    leg3_ident = ident(1, 1, 942, 1, 31, 'hand-scroll-note')
    check('legacy-3-drag-standard-real-adopted2',
          confirmed_selection(leg3_rows, 0,
                              {'field': 'hand-scroll-note',
                               'readback_identity': leg3_ident,
                               'owner_version': 26}), (13, 17))
    # 同一真实流的变异：改一个来源字段必拒（B：缺/改一个来源字段必拒）。
    check('legacy-3-drag-mutation-owner-version-999',
          confirmed_selection([r.replace('owner_version=26', 'owner_version=999')
                               if 'ADOPTED2' in r else r for r in leg3_rows], 0,
                              {'field': 'hand-scroll-note',
                               'readback_identity': leg3_ident,
                               'owner_version': 26}), None)
    check('legacy-3-drag-mutation-source-gen-999',
          confirmed_selection([r.replace('source_gen=1', 'source_gen=999')
                               if 'ADOPTED2' in r else r for r in leg3_rows], 0,
                              {'field': 'hand-scroll-note',
                               'readback_identity': leg3_ident,
                               'owner_version': 26}), None)
    check('legacy-3-drag-mutation-drop-adopted2',
          confirmed_selection([r for r in leg3_rows if 'ADOPTED2' not in r], 0,
                              {'field': 'hand-scroll-note',
                               'readback_identity': leg3_ident,
                               'owner_version': 26}), None)
    check('legacy-3-drag-mutation-drop-observation',
          confirmed_selection([r for r in leg3_rows if 'observation forwarded' not in r],
                              0, {'field': 'hand-scroll-note',
                                  'readback_identity': leg3_ident,
                                  'owner_version': 26}), None)
    # 腿6 外部改版重挂载（等价链 c2）：基线 28。
    check('legacy-6-post-external-equivalence',
          confirmed_selection([L[22047], L[22249], L[22250], L[22299]], 0,
                              {'field': 'hand-scroll-note',
                               'readback_identity': ident(2, 1, 942, 1, 33,
                                                          'hand-scroll-note'),
                               'owner_version': 28}), (15, 15))
    # 腿7b 生成安装 G1（等价链 c3，echo-held）：基线 29。
    check('legacy-7b-generated-equivalence',
          confirmed_selection([L[26033], L[26034], L[26140], L[26141], L[26175]], 0,
                              {'field': 'component-2-1',
                               'readback_identity': ident(3, 1, 802001, 35, 35,
                                                          'component-2-1'),
                               'owner_version': 29}), (16, 16))
    # 腿8 手写回访（标准 attach_confirmed c4）：基线 31。
    check('legacy-8-hand-revisit-standard',
          confirmed_selection([L[28972], L[29030], L[29031], L[29069], L[29215],
                               L[29217]], 0,
                              {'field': 'hand-scroll-note',
                               'readback_identity': ident(4, 1, 942, 1, 37,
                                                          'hand-scroll-note'),
                               'owner_version': 31}), (18, 18))
    # 腿9 生成回访 G2（标准 attach_confirmed c5）：基线 32。
    check('legacy-9-generated-revisit-standard',
          confirmed_selection([L[31836], L[32083], L[32084], L[32095], L[32218],
                               L[32220]], 0,
                              {'field': 'component-2-1',
                               'readback_identity': ident(5, 1, 802001, 35, 38,
                                                          'component-2-1'),
                               'owner_version': 32}), (16, 16))
    # 读回身份 gen 与挂载键 e 段不符 → 拒（归一门①）。
    check('legacy-mount-key-gen-mismatch',
          confirmed_selection([L[26033], L[26034], L[26140], L[26141], L[26175]], 0,
                              {'field': 'component-2-1',
                               'readback_identity': ident(3, 2, 802001, 35, 35,
                                                          'component-2-1'),
                               'owner_version': 29}), None)
    # 挂载键不符合 ProxyKey 形状 → 拒。
    check('legacy-mount-key-shape-mismatch',
          confirmed_selection([L[4105].replace('app1/s1/c1/e1/m1', 'opaque-key'),
                               L[4191], L[4192], L[4201]], 0,
                              {'field': 'hand-scroll-note',
                               'readback_identity': leg1_ident,
                               'owner_version': 0}), None)

    # ---- 采纳补位（round14 复跑 leg6 实测形态；Pi 咨询裁决加固版乙）----
    # 形态 b：挂载 → ADOPTED2（窗口采纳挂载回声）→ attach_confirmed 终态对，
    # 观测行被 hilog 流控丢弃（整个 span 零观测行）。全字段身份/基线/顺序
    # 相符 → 接受，observation_source='attach_confirmed'。
    def rows_fallback(adopted_over=None, reason='attach_confirmed',
                      insert_obs=None, adopt_after_confirmed=False,
                      mount=MOUNT):
        out = [f'10-03 21:35:54.259 32064 32064 I A00000/CjguiApp: '
               f'ime proxy mounted ctx={CTX} field={FIELD} node={NODE} gen=1 base=35',
               f'10-03 21:35:54.259 32064 32064 I A00000/CjguiApp: '
               f'proxy mounted key={mount} field={FIELD}']
        over = adopted_over or {}
        seg = (f'10-03 21:35:54.393 32064 13003 I A00000/CjguiRenderer: window-diag: '
               f'CJGUI_OWNED_SELECTION_ADOPTED2 node={over.get("node", NODE)} '
               f'resource={over.get("resource", 9801)} kind={over.get("kind", 5)} '
               f'sel={over.get("sel", f"{SEL[0]}:{SEL[1]}")} '
               f'projection={over.get("projection", 35)} '
               f'binding={over.get("binding", 35)} '
               f'owner_version={over.get("owner_version", 29)} '
               f'source_ctx={over.get("source_ctx", CTX)} '
               f'source_gen={over.get("source_gen", 1)}')
        if not adopt_after_confirmed:
            out.append(seg)
        confirmed_row = (f'10-03 21:35:54.400 32064 32064 I A00000/CjguiApp: '
                         f'ime selection confirmed [{SEL[0]},{SEL[1]}) rc=0 '
                         f'(shared lifecycle) mount={mount} field={FIELD}')
        terminal_row = (f'10-03 21:35:54.410 32064 32064 I A00000/CjguiApp: '
                        f'ime proxy selection terminal=INSTALLED reason={reason} '
                        f'target=[{SEL[0]},{SEL[1]}) mount={mount} field={FIELD}')
        if adopt_after_confirmed:
            out += [confirmed_row, terminal_row, seg]
        else:
            out += [confirmed_row, terminal_row]
        if insert_obs is not None:
            out.append(insert_obs)
        return out

    OBS_OTHER = (f'10-03 21:35:54.378 32064 32064 I A00000/CjguiRenderer: '
                 f'ime selection observation forwarded ctx={CTX} sel=9:9 '
                 f'node={NODE} resource=9801 kind=5 binding=35 v=35 native_changed=0')
    fb = rows_fallback()
    fb_facts = {}
    got = confirmed_selection(fb, 0, expect, facts=fb_facts)
    check('fallback-positive-attach-confirmed', got, SEL)
    check('fallback-facts-source',
          fb_facts.get('observation_source'), 'attach_confirmed')
    check('fallback-facts-obs-count', fb_facts.get('obs_rows_in_span'), 0)
    check('fallback-positive-with-select-row-also-present',
          confirmed_selection(fb + [
              f'10-03 21:35:54.371 32064 32064 I A00000/CjguiApp: '
              f'ime select [{SEL[0]},{SEL[1]}) rc=0 mount={MOUNT}'], 0, expect), SEL)
    check('fallback-negative-obs-present-other-sel-blocks',
          confirmed_selection(rows_fallback(insert_obs=OBS_OTHER), 0, expect), None)
    obs_after = (f'10-03 21:35:54.420 32064 32064 I A00000/CjguiRenderer: '
                 f'ime selection observation forwarded ctx={CTX} sel={SEL[0]}:{SEL[1]} '
                 f'node={NODE} resource=9801 kind=5 binding=35 v=35 native_changed=0')
    check('fallback-negative-obs-present-after-adopted-blocks',
          confirmed_selection(rows_fallback(insert_obs=obs_after), 0, expect), None)
    check('fallback-negative-source-gen-999',
          confirmed_selection(rows_fallback(adopted_over={'source_gen': 999}), 0,
                              expect), None)
    check('fallback-negative-source-gen-unverified',
          confirmed_selection(rows_fallback(adopted_over={'source_gen': 'unverified'}),
                              0, expect), None)
    check('fallback-negative-owner-version-999',
          confirmed_selection(rows_fallback(adopted_over={'owner_version': 999}), 0,
                              expect), None)
    check('fallback-negative-owner-version-minus1',
          confirmed_selection(rows_fallback(adopted_over={'owner_version': -1}), 0,
                              expect), None)
    check('fallback-negative-source-ctx-mismatch',
          confirmed_selection(rows_fallback(adopted_over={'source_ctx': 1}), 0,
                              expect), None)
    check('fallback-negative-adopted-sel-mismatch',
          confirmed_selection(rows_fallback(adopted_over={'sel': '1:2'}), 0,
                              expect), None)
    check('fallback-negative-adopted-node-mismatch',
          confirmed_selection(rows_fallback(adopted_over={'node': 9999}), 0,
                              expect), None)
    check('fallback-negative-reason-caret-confirmed-blocks',
          confirmed_selection(rows_fallback(reason='caret_confirmed'), 0, expect),
          None)
    check('fallback-negative-adopted-after-confirmed-rejected',
          confirmed_selection(rows_fallback(adopt_after_confirmed=True), 0, expect),
          None)
    check('fallback-negative-mount-ctx-mismatch',
          confirmed_selection(
              [r.replace(MOUNT, 'app1/s1/c99/e9/m99') for r in rows_fallback()],
              0, expect), None)
    # 等价凭据（无 terminal 对）零观测行：补位不启用（只限 attach_confirmed）。
    check('fallback-negative-equivalence-credential-not-eligible',
          confirmed_selection(rows(), 0, expect) if False else
          confirmed_selection(
              [r for r in rows() if 'observation forwarded' not in r], 0, expect),
          None)

    # ---- 运行 B（round14 设备复跑）leg6 真实行回放：补位正控 P2 ----
    RUN_B = ROOT / 'artifacts/h-r-final-20261002/round14-fix/thermo-rerun/6-post-external-select-judgment-rows.txt'
    RUN_B_SHA256 = '58e2487211e842807cc54be84e3dbe970252e9fc39fe30276501e5bb3d220bab'
    if not RUN_B.exists():
        raise SystemExit(f'run-B archive missing: {RUN_B}')
    sha_b = hashlib.sha256(RUN_B.read_bytes()).hexdigest()
    if sha_b != RUN_B_SHA256:
        raise SystemExit(f'run-B archive sha256 drift: {sha_b}')
    rb_all = RUN_B.read_text().splitlines()
    assert not any('observation forwarded ctx=2' in r for r in rb_all), \
        'run-B 前提（零 ctx=2 观测行）失效'
    _RB = {20181: 'proxy mounted key=app1/s1/c2/e1/m2 field=hand-scroll-note',
           20239: 'CJGUI_OWNED_SELECTION_ADOPTED2 node=942 resource=9801 kind=5 '
                  'sel=15:15 projection=33 binding=1 owner_version=28 '
                  'source_ctx=2 source_gen=1',
           20362: 'ime selection confirmed [15,15) rc=0 (shared lifecycle) '
                  'mount=app1/s1/c2/e1/m2 field=hand-scroll-note',
           20364: 'ime proxy selection terminal=INSTALLED reason=attach_confirmed '
                  'target=[15,15) mount=app1/s1/c2/e1/m2 field=hand-scroll-note'}
    rb = []
    for num, marker in _RB.items():
        line = rb_all[num - 1]
        assert marker in line, f'run-B line {num} marker drift: {marker!r}'
        rb.append(line)
    rb_facts = {}
    got = confirmed_selection(rb, 0,
                              {'field': 'hand-scroll-note',
                               'readback_identity': ident(2, 1, 942, 1, 33,
                                                          'hand-scroll-note'),
                               'owner_version': 28},
                              facts=rb_facts)
    check('runB-leg6-fallback-real-rows', got, (15, 15))
    check('runB-leg6-fallback-source',
          rb_facts.get('observation_source'), 'attach_confirmed')
    check('runB-leg6-fallback-obs-count', rb_facts.get('obs_rows_in_span'), 0)
    check('runB-leg6-fallback-baseline',
          (rb_facts.get('adopted') or {}).get('owner_version'), 28)

    # ---- 运行 B 复跑 leg3（round14 设备复跑 2）：陈旧 word_select terminal
    # 配对不得挡住证据齐全的更新 select 凭据。拖选终点 [13,17) 的 app 侧
    # confirmed/terminal 行被 hilog 流控丢弃，但 select 行+观测行+ADOPTED2
    # 全在；过站 [13,14) 配对（caret_confirmed，无观测行）必须被门拒绝。----
    RUN_B2 = ROOT / ('artifacts/h-r-final-20261002/round14-fix/thermo-rerun2/'
                     '3-nonempty-select-judgment-rows.txt')
    RUN_B2_SHA256 = ('80ffa84f0524677f9e4962d7aade418d683b08cba88e35f9477a'
                     '808f826cacca')
    if not RUN_B2.exists():
        raise SystemExit(f'run-B2 archive missing: {RUN_B2}')
    sha_b2 = hashlib.sha256(RUN_B2.read_bytes()).hexdigest()
    if sha_b2 != RUN_B2_SHA256:
        raise SystemExit(f'run-B2 archive sha256 drift: {sha_b2}')
    rb2_all = RUN_B2.read_text().splitlines()
    _RB2 = {4364: 'proxy mounted key=app1/s1/c1/e1/m1 field=hand-scroll-note',
            16791: 'CJGUI_OWNED_SELECTION_ADOPTED2 node=942 resource=9801 kind=5 '
                   'sel=13:14 projection=31 binding=1 owner_version=26 '
                   'source_ctx=1 source_gen=1',
            16837: 'ime selection confirmed [13,14) rc=0 (shared lifecycle) '
                   'mount=app1/s1/c1/e1/m1 field=hand-scroll-note',
            16839: 'ime proxy selection terminal=INSTALLED reason=caret_confirmed '
                   'target=[13,14) mount=app1/s1/c1/e1/m1 field=hand-scroll-note',
            18518: 'ime selection observation forwarded ctx=1 sel=13:17 node=942 '
                   'resource=9801 kind=5 binding=1 v=31',
            18519: 'ime select [13,17) rc=0 mount=app1/s1/c1/e1/m1',
            18547: 'CJGUI_OWNED_SELECTION_ADOPTED2 node=942 resource=9801 kind=5 '
                   'sel=13:17 projection=31 binding=1 owner_version=26 '
                   'source_ctx=1 source_gen=1'}
    rb2 = []
    for num, marker in _RB2.items():
        line = rb2_all[num - 1]
        assert marker in line, f'run-B2 line {num} marker drift: {marker!r}'
        rb2.append(line)
    rb2.sort(key=lambda r: rb2_all.index(r))   # 恢复真实行序
    rb2_facts = {}
    got = confirmed_selection(rb2, 0,
                              {'field': 'hand-scroll-note',
                               'readback_identity': ident(1, 1, 942, 1, 31,
                                                          'hand-scroll-note'),
                               'owner_version': 26},
                              facts=rb2_facts)
    check('runB2-leg3-stale-terminal-does-not-block-select-credential',
          got, (13, 17))
    check('runB2-leg3-winning-credential',
          (rb2_facts.get('install') or {}).get('kind'), 'select')
    check('runB2-leg3-obs-source', rb2_facts.get('observation_source'), 'obs_row')

    print()
    if failures:
        print(f'FAILURES: {len(failures)} -> {failures}')
        sys.exit(1)
    print('round14 thermo 归一最终守卫: OK（单一出口，round14 九类 RED 全反转，'
          'thermo-final 六腿真实行可重判且变异必拒）')


if __name__ == '__main__':
    main()

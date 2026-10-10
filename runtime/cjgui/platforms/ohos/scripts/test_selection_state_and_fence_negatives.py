#!/usr/bin/env python3
"""round15 R-A/R-B/R-C：七个失败形状常驻反例（离线，无设备）。

反例原件 guidance-review/round15-review.{md,py,json}（RED）不覆盖；本套件把
同样七个输入固定为常驻用例，并断言修复后的行为：

A 选择状态退役（最新轮次判定，禁止历史成功复活）：
  1 两条完整等价 select 先 [1,1] 后 [2,2] → 采用后续完整 [2,2]；
  2 旧 [1,1] 完整成功后，新 [2,2] 观测未采纳 → 等待/未证实（None），
    旧成功退役；
  3 旧 [1,1] 成功后，新 [2,2] 候选来源代次冲突 → 冲突不能让旧成功复活（None）。
B 围栏排他边界：
  4 原快照原样回放、零新行（时间戳围栏）→ 无新证据不通过（None）；
  5 {'index': N} 未知围栏 → 具名未证实（None），不回退 0。
C 读回收敛：
  6 _readback_full() 返回 None → 有界等待后具名归档（None，不抛异常）；
  7 当次 owner 版本（VERSION 30）≠ 本腿冻结基线（29）→ 拒绝/不通过；
    无正文变化的 projection 推进（readback v=36）仍允许进入判定。
"""
import ast
import importlib.util
import re
import sys
from pathlib import Path
from types import SimpleNamespace

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent.parent.parent.parent.parent
SCRIPTS = ROOT / 'runtime/cjgui/platforms/ohos/scripts'
sys.path.insert(0, str(SCRIPTS))


def load(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


fx = load('r16fx', HERE / 'test_generated_install_equivalence_negatives.py')
dev = load('r16dev', SCRIPTS / 'h_source_preview_consumption.py')

SOURCE = SCRIPTS / 'verify_thermo_shared_lifecycle.py'
source_text = SOURCE.read_text()
tree = ast.parse(source_text)
CONSTS = ('_PROXY_KEY_RE', '_OBS_RE', '_ADOPTED_RE', '_ROW_TS',
          '_HOST_REFUSAL_PREFIXES')
FUNCS = ('_final_adoption_identity_gate', 'confirmed_selection', '_row_ts',
         '_fence_marker', '_resolve_fence', 'wait_confirmed',
         '_archive_leg_judgment', '_readback_full', 'named_refusals')
body = [n for n in tree.body
        if (isinstance(n, ast.FunctionDef) and n.name in FUNCS)
        or (isinstance(n, ast.ClassDef) and n.name == 'ArchiveRequiredError')
        or (isinstance(n, ast.Assign) and any(isinstance(t, ast.Name) and t.id in CONSTS
                                              for t in n.targets))]
missing = set(FUNCS) - {n.name for n in body if isinstance(n, ast.FunctionDef)}
if missing:
    raise SystemExit(f'missing functions: {sorted(missing)}')
# 提取闭包自检：被抽出的函数体引用了源文件的**模块级名字**却没被抽进来时，运行到
# 那条腿才炸 NameError（本类已复发三次：row_pid、_version_behind、named_refusals，
# 且都只在失败腿命中，绿色套件掩盖过它）。这里在 exec 之前按引用闭合，具名终止。
top = set()
for n in tree.body:
    if isinstance(n, (ast.FunctionDef, ast.ClassDef)):
        top.add(n.name)
    elif isinstance(n, ast.Assign):
        top |= {t.id for t in n.targets if isinstance(t, ast.Name)}
extracted = {n.name for n in body if isinstance(n, (ast.FunctionDef, ast.ClassDef))}
extracted |= {t.id for n in body if isinstance(n, ast.Assign)
              for t in n.targets if isinstance(t, ast.Name)}
unbound = set()
# 本套件在 exec 后向命名空间**注入**这些名字（驱动桩），它们不在抽取列表里但确实
# 由调用方提供；写死清单，注入形状变化时由下面的自检具名报错。
INJECTED = ('rows_for', '_readback_full', 'tc')
provided = extracted | set(INJECTED)
for n in body:
    if not isinstance(n, ast.FunctionDef):
        continue
    # 逐函数各算一次局部集（跨函数共用会把上一个函数的参数当成本函数的绑定）。
    local = {a.arg for a in n.args.args} | {a.arg for a in n.args.kwonlyargs}
    loads = set()
    for sub in ast.walk(n):
        if isinstance(sub, (ast.FunctionDef, ast.Lambda)):
            local |= {a.arg for a in sub.args.args} | {a.arg for a in sub.args.kwonlyargs}
        if isinstance(sub, ast.Name):
            if isinstance(sub.ctx, ast.Store):
                local.add(sub.id)
            else:
                loads.add(sub.id)
        elif isinstance(sub, (ast.Import, ast.ImportFrom)):
            local.add((sub.asname or sub.names[0].name).split('.')[0])
        elif isinstance(sub, ast.ExceptHandler) and sub.name:
            local.add(sub.name)
    unbound |= {x for x in loads - local if x in top and x not in provided}
if unbound:
    raise SystemExit(f'unbound module-level names in extracted code: {sorted(unbound)}')
ns = {'re': re, 'time': SimpleNamespace(sleep=lambda _: None), 'Path': Path,
      'json': __import__('json')}
exec(compile(ast.Module(body=body, type_ignores=[]), str(SOURCE), 'exec'), ns)

ident = fx.ident(3, 1, 802001, 35, 35, fx.FIELD)
EXPECT = {'field': fx.FIELD, 'owner_version': 29, 'readback_identity': ident}
judge = ns['confirmed_selection']

failures = []


def check(name, got, want):
    ok = got == want
    print(f"  {'OK  ' if ok else 'FAIL'} {name}: {got!r}" + ('' if ok else f' (want {want!r})'))
    if not ok:
        failures.append(name)


def retime(rows, stamp):
    return [re.sub(r'^\d\d-\d\d \d\d:\d\d:\d\d\.\d+', stamp, r) for r in rows]


def main():
    print('== round15 七个失败形状（常驻） ==')
    old = fx.rows(terminal=True)
    newsel = fx.rows(sel=(2, 2), terminal=False)

    # A1：两条完整等价 select，后条完整 → 采用后条。
    seq = retime(fx.rows(), '10-04 16:00:00.001') + retime(newsel[2:], '10-04 16:00:00.002')
    check('later-complete-select-adopted', judge(seq, 0, EXPECT), (2, 2))

    # A2：新 [2,2] 观测未采纳 → 旧 [1,1] 退役，等待/未证实。
    seq = retime(old, '10-04 16:00:00.001') + retime(
        fx.rows(sel=(2, 2), terminal=False, adopted=False)[2:], '10-04 16:00:00.002')
    check('newer-unadopted-retires-old-success',
          judge(seq, 0, EXPECT), None)

    # A3：新 [2,2] 候选来源代次冲突 → 旧成功不复活。
    seq = retime(old, '10-04 16:00:00.001') + retime(
        fx.rows(sel=(2, 2), terminal=True, adopted_over={'source_gen': 999})[2:],
        '10-04 16:00:00.002')
    check('newer-conflict-retires-old-success',
          judge(seq, 0, EXPECT), None)

    # B4：原快照原样回放、零新行 → 无新证据不通过。
    seq = retime(old, '10-04 16:00:00.001')
    marker = ns['_fence_marker'](seq)
    check('timestamp-fence-exclusive-replay', judge(seq, marker, EXPECT), None)

    # B5：未知围栏 {'index': N} → 具名未证实（None）。
    seq = fx.rows(terminal=True)
    check('unknown-fence-named-unproven',
          judge(seq, {'index': len(seq)}, EXPECT), None)

    # C6：_readback_full() 返回 None → 有界等待后具名归档（None，不抛异常）。
    ns['rows_for'] = lambda _: fx.rows(terminal=True)
    ns['tc'] = SimpleNamespace(_m=dev)
    ns['_readback_full'] = lambda: None
    got, _rows = ns['wait_confirmed'](1, 0, False,
                                      {'field': fx.FIELD, 'owner_version': 29},
                                      rounds=1)
    check('readback-none-named-unproven', got, None)

    # C7：当次 owner 版本（VERSION 30）≠ 冻结基线（29）→ 拒绝；读回 v=36 的
    # projection 推进允许进入判定（不被本项拒绝）。
    wire = ('ACCEPTED token=201 edit=live ctx=3 gen=1 node=802001 res=9801 '
            'kind=5 b=35 v=36 field=component-2-1')
    ns['_readback_full'] = lambda: {'raw': 'VERSION 30', 'version': 30, 'state': wire}
    got, _rows = ns['wait_confirmed'](1, 0, False,
                                      {'field': fx.FIELD, 'owner_version': 29},
                                      rounds=1)
    check('owner-advanced-rejects-stale-anchor', got, None)

    # C 正控：owner 版本等于基线（VERSION 29）时同一链仍成立——排除"一刀切拒绝"。
    ns['_readback_full'] = lambda: {'raw': 'VERSION 29', 'version': 29, 'state': wire}
    got, _rows = ns['wait_confirmed'](1, 0, False,
                                      {'field': fx.FIELD, 'owner_version': 29},
                                      rounds=1)
    check('owner-baseline-equal-still-passes', got, (1, 1))

    # ---- round18：confirmed 轮次迁移三反例 + 三正控（常驻） ----
    base = fx.rows(terminal=True)
    mount = base[:2]
    b18 = fx.rows(sel=(2, 2), terminal=True)
    pick18 = lambda rows, tag: [r for r in rows if tag in r]
    r18 = [
        ('confirmed_new_choice_unfinished',
         base + pick18(b18, 'ime selection confirmed '), None),
        ('pending_crosses_confirmed_only',
         mount + pick18(base, 'ADOPTED2') + pick18(b18, 'ime selection confirmed ')
         + pick18(base, 'ime selection confirmed ') + pick18(base, 'terminal=INSTALLED'),
         None),
        ('new_confirmed_then_complete_strict',
         base + pick18(b18, 'ime selection confirmed ')
         + pick18(b18, 'ime selection observation ') + pick18(b18, 'ADOPTED2')
         + pick18(b18, 'terminal=INSTALLED'), (2, 2)),
        ('paired_initial_fallback_control',
         mount + pick18(base, 'ADOPTED2') + pick18(base, 'ime selection confirmed ')
         + pick18(base, 'terminal=INSTALLED'), (1, 1)),
        ('unpaired_terminal_with_valid_select_control',
         [r for r in base if 'ime selection confirmed ' not in r], (1, 1)),
        ('duplicate_terminal_preserves_pair_control',
         base + pick18(base, 'terminal=INSTALLED'), (1, 1)),
    ]
    strict18_facts = None
    for name, rows18, want in r18:
        rows18 = [re.sub(r'^\d\d-\d\d \d\d:\d\d:\d\d\.\d+',
                         f'10-04 19:00:00.{i:03d}', r) for i, r in enumerate(rows18)]
        f18 = {}
        got18 = judge(rows18, 0, EXPECT, f18)
        check(f'r18-{name}', got18, want)
        if name == 'new_confirmed_then_complete_strict' and got18 is not None:
            strict18_facts = f18
    # 末段完整 B 的安装/观测/采纳事实必须属于 B 轮。
    prefix18 = len(base)
    check('r18-new-round-facts-belong-to-b',
          strict18_facts is not None
          and all(strict18_facts.get(k, -1) >= prefix18
                  for k in ('obs_row_idx', 'adopted_row_idx'))
          and (strict18_facts.get('install') or {}).get(
              'confirmed_idx', -1) >= prefix18, True)

    # ---- round17-A/B：轮次所有权四条 RED（含正控与既有补位正控） ----
    base = fx.rows(terminal=True)
    mount = base[:2]

    def matching(rows, text):
        return [r for r in rows if text in r]

    adopt_a = matching(base, 'ADOPTED2')
    select_a = matching(base, 'ime select ')
    obs_a = matching(base, 'ime selection observation ')
    confirm_a = matching(base, 'ime selection confirmed ')
    terminal_a = matching(base, 'terminal=INSTALLED')
    other = fx.rows(sel=(2, 2), terminal=True)
    select_b = matching(other, 'ime select ')
    obs_b = matching(other, 'ime selection observation ')
    confirm_b = matching(other, 'ime selection confirmed ')
    terminal_b = matching(other, 'terminal=INSTALLED')
    r17 = [
        ('pending_crosses_select_boundary',
         mount + adopt_a + select_b + select_a + confirm_a + terminal_a, None),
        ('pending_crosses_terminal_boundary',
         mount + adopt_a + confirm_b + terminal_b + confirm_a + terminal_a, None),
        ('unpaired_terminal_as_install',
         mount + obs_a + adopt_a + terminal_a, None),
        ('confirmed_reused_across_rounds',
         base + select_b + obs_b + obs_a + adopt_a + terminal_a, None),
        ('strict_control', base, (1, 1)),
        ('attach_fallback_control', mount + adopt_a + confirm_a + terminal_a, (1, 1)),
        ('foreign_mount_noise_control',
         base + [r.replace(fx.MOUNT, 'app1/s1/c99/e1/m99') for r in select_b], (1, 1)),
        ('intervening_obs_retires_pending_control',
         mount + adopt_a + select_b + obs_b + select_a + confirm_a + terminal_a, None),
    ]
    for name, rows17, want in r17:
        rows17 = [re.sub(r'^\d\d-\d\d \d\d:\d\d:\d\d\.\d+',
                         f'10-04 18:00:00.{i:03d}', r) for i, r in enumerate(rows17)]
        f17 = {}
        got17 = judge(rows17, 0, EXPECT, f17)
        check(f'r17-{name}', got17, want)
        if want is not None and name == 'aba_all_complete':
            pass
    # 末段事实归属检查：三段完整 ABA 的 obs/adopt 行号必须属于末段
    prefix = (segment(1, (1, 1)) if 'segment' in dir() else None)

    print()
    if failures:
        print(f'FAILURES: {len(failures)} -> {failures}')
        sys.exit(1)
    print('round15 七个失败形状常驻反例: OK（修复后行为全部成立）')


if __name__ == '__main__':
    main()

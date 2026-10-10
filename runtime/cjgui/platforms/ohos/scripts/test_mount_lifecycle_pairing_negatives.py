#!/usr/bin/env python3
"""round8-A 回归：`body_restore_evidence` 的**挂载生命周期配对**（离线，无设备）。

核心反例（指导 round8）：旧实现先扫全历史取「最后一条 focus」当前身份，再从**整个
历史**捞同值观测/采纳事实，于是旧挂载的采纳被拼到新挂载上。现在 `_mount_lifecycle`
单遍顺序扫描维护当前有效代，任何换焦 / release / restore terminated / 同值重挂都
立即关闭当前代；所有事实带记录时所属的**代号**，只有同代者可用。

覆盖：
  * 生产**真实格式** `count=N failed=N pending=bool request=R …` 的显式采纳 ACK 路径
    （旧正则要求 `count=` 后紧跟 `request=` 再行尾，真实行永远不匹配 ⇒ 路径被漏读）。
  * owner_version **缺失必须拒绝**（旧实现把该字段当可选，缺失时整段比较被跳过）。
  * 旧采纳 + 新挂载同值 ⇒ 拒；退役后旧回包 ⇒ 拒；换焦后旧采纳 ⇒ 拒。
  * 两条合法路径正控，以及「新挂载后同代重新成立」的正控。

round7 的 `test_current_identity_tuple_negatives.py` 已**并入本文件**：它的 16 例是本
文件生命周期版的子集（业务判据一条未放松），字段级负控（resource/kind/binding/
projection/sel/观测不完整/owner 版本不符）已搬到这里并加了具名 source 断言。保留
两套重叠套件只会让「哪套是当前判据」变模糊。
"""
import ast
import re  # noqa: E402
from pathlib import Path

HERE = Path(__file__).resolve().parent
SCRIPT = HERE / 'verify_pharos_dual_owner.py'
NAMES = ('_mount_lifecycle', 'body_restore_evidence', '_identity_mismatch',
         '_version_behind')

_tree = ast.parse(SCRIPT.read_text())
_nodes = [n for n in _tree.body if isinstance(n, ast.FunctionDef) and n.name in NAMES]
assert {n.name for n in _nodes} == set(NAMES), sorted(n.name for n in _nodes)
ns = {'re': re, 'BODY_FIELD': 'pharos-editor-body'}
exec(compile(ast.Module(body=_nodes, type_ignores=[]), str(SCRIPT), 'exec'), ns)
restore = ns['body_restore_evidence']

BODY, OWNER, FROZEN = 107, 'main', 2
FAILURES = []


def focus(ctx, node=BODY, field='pharos-editor-body', res=54, kind=10, binding=6, v=36):
    return (f"platform focus node={node} ctx={ctx} field={field} "
            f"resource={res} kind={kind} binding={binding} v={v}")


def obs(ctx, start=3, end=3, res=54, kind=10, binding=6, v=36):
    return (f"ime selection observation forwarded ctx={ctx} sel={start}:{end} "
            f"node={BODY} resource={res} kind={kind} binding={binding} v={v} native_changed=0")


def adopt2(start=3, end=3, res=54, kind=10, binding=6, proj=36, owner_version=2,
           source_ctx=7, source_gen=3):
    """round9-A 起生产 ADOPTED2 必带冻结来源（source_ctx/source_gen）。

    round11 复跑发现本夹具停留在 round8 形状（无来源字段），10 例全部塌缩成
    adopted2_missing_frozen_source——那是夹具过时，不是生产放松。默认 source_ctx=7
    与 focus(7) 同挂载；跨代用例按各自挂载传 ctx。来源缺失/unverified 的采纳
    另有专属负控（adopted2-missing-frozen-source / adopted2-source-unverified）。
    """
    owner_tail = '' if owner_version is None else f" owner_version={owner_version}"
    if source_ctx is None:
        source_tail = ''
    else:
        gen = 'unverified' if source_gen == 'unverified' else str(source_gen)
        source_tail = f" source_ctx={source_ctx} source_gen={gen}"
    return (f"CJGUI_OWNED_SELECTION_ADOPTED2 node={BODY} resource={res} kind={kind} "
            f"sel={start}:{end} projection={proj} binding={binding}{owner_tail}{source_tail}")


BOUND = f"PHAROS_OHOS_BIND_OWNER owner={OWNER} mirror_version=2 mirror_bytes=137 owner_version=2"
ACK = f"proxy restore ack accepted request=4 ctx=7 node={BODY} installed=3:3 v=36"
# 生产真实格式（产品 ohos_app.cj 的格式串）：failed=/pending= 夹在 count 与 request 之间。
REAL_ADOPTED = ("PHAROS_OHOS_RESTORE_ADOPTED count=2 failed=2 pending=false request=4 ctx=7 "
                f"node={BODY} adopted=3:3 owner_version=2 v=36")
PLAIN_ADOPTED = (f"PHAROS_OHOS_RESTORE_ADOPTED count=2 request=4 ctx=7 node={BODY} "
                 "adopted=3:3 owner_version=2 v=36")


_DEFAULT_HINT = {'ctx': 7, 'node': BODY, 'field': 'pharos-editor-body',
                 'resource': 54, 'kind': 10, 'binding': 6, 'v': 36,
                 'gen': 1, 'live': True}


def run(rows, identity_hint=None, hint_absent=False):
    # round13-R1：最终门消费权威当前身份。未提供 hint 的用例按真实读回 wire
    # 形状给 live ctx7 默认（与正控夹具一致）；hint_absent=True 模拟读回缺失
    # （hint=None，必须具名拒绝，不借日志）。
    if hint_absent:
        identity_hint = None
    elif identity_hint is None:
        identity_hint = _DEFAULT_HINT
    return restore(rows, 0, BODY, 1, OWNER, owner_version=FROZEN,
                   identity_hint=identity_hint)


def accepted(result):
    return result is not None and result.get('source') in ('restore_ack', 'mount_snapshot')


def expect(name, rows, want, want_source=None, identity_hint=None,
           hint_absent=False):
    result = run(rows, identity_hint=identity_hint, hint_absent=hint_absent)
    got = accepted(result)
    ok = got == want and (want_source is None or (result or {}).get('source') == want_source)
    print(f"   {'OK  ' if ok else 'FAIL'} {name} -> {(result or {}).get('source')!r} "
          f"(accepted={got}, want={want})")
    if not ok:
        FAILURES.append((name, result))


# ---- 正控：两条合法路径 + 生产真实格式 ----
expect('mount-positive', [focus(7), obs(7), adopt2(), BOUND], True, 'mount_snapshot')
expect('ack-positive-plain', [focus(7), ACK, PLAIN_ADOPTED], True, 'restore_ack')
expect('ack-positive-real-producer-format', [focus(7), ACK, REAL_ADOPTED], True, 'restore_ack')

# ---- owner_version 缺失必须拒绝（不再当作可选字段跳过比较） ----
expect('adopted2-missing-owner-version',
       [focus(7), obs(7), adopt2(owner_version=None), BOUND], False)

# ---- 生命周期：旧挂载的采纳不得拼到新挂载 ----
expect('old-adoption-then-new-mount-same-values',
       [focus(7), obs(7), adopt2(), BOUND, focus(8), obs(8)], False)
expect('late-old-adoption-after-new-mount',
       [focus(7), obs(7), focus(8), adopt2(), BOUND], False)
expect('retired-mount-without-new-focus',
       [focus(7), obs(7), adopt2(), BOUND, "proxy released by framework ctx=7"], False)
expect('focus-other-field-then-old-adoption',
       [focus(7), focus(313, field='pharos-document-note', res=1, binding=5, v=9),
        adopt2(), BOUND], False)
expect('restore-terminated-keeps-mount-adoption',
       [focus(7), obs(7), adopt2(), BOUND,
        "proxy restore terminated reason=external_version request=4 ctx=7 code=1"], True,
       'mount_snapshot')
# 同值重开 focus：round9-A 起生产 beginEditingOnNodeLocked 对同身份幂等直接 return
# （不换 ctx），因此同值再 focus 是同一挂载的幂等重复，已成立的采纳**不**被作废。
# 「新挂载不吃旧采纳」的判据由 focus(8)（真换焦）两条负控承担，此处不重复。
expect('idempotent-refocus-keeps-adoption',
       [focus(7), obs(7), adopt2(), BOUND, focus(7), obs(7)], True, 'mount_snapshot')

# ---- 正控：新挂载后同代重新成立（旧代被拒不影响新一代） ----
expect('new-mount-fresh-adoption-accepted',
       [focus(7), obs(7), adopt2(), BOUND,
        focus(8), obs(8), adopt2(source_ctx=8), BOUND], True, 'mount_snapshot',
       identity_hint={'ctx': 8, 'node': BODY, 'field': 'pharos-editor-body',
                      'resource': 54, 'kind': 10, 'binding': 6, 'v': 36,
                      'gen': 1, 'live': True})

# ---- 冻结来源（round9-A）：缺失 / unverified / 异挂载 一律不作证据 ----
expect('adopted2-missing-frozen-source',
       [focus(7), obs(7), adopt2(source_ctx=None), BOUND], False,
       'adopted2_missing_frozen_source')
expect('adopted2-source-unverified',
       [focus(7), obs(7), adopt2(source_gen='unverified'), BOUND], False,
       'adopted2_source_not_numeric')
expect('adopted2-source-not-current-mount',
       [focus(7), obs(7), adopt2(source_ctx=8), BOUND], False,
       'adopted2_source_not_current_mount')

# ---- 显式路径同样受生命周期约束 ----
expect('old-ack-after-new-mount',
       [focus(7), ACK, REAL_ADOPTED, focus(8)], False)
expect('new-mount-fresh-ack-accepted',
       [focus(7), ACK, REAL_ADOPTED, focus(8),
        f"proxy restore ack accepted request=5 ctx=8 node={BODY} installed=3:3 v=36",
        REAL_ADOPTED.replace('count=2', 'count=3').replace('request=4', 'request=5')
        .replace('ctx=7', 'ctx=8')], True, 'restore_ack',
       identity_hint={'ctx': 8, 'node': BODY, 'field': 'pharos-editor-body',
                      'resource': 54, 'kind': 10, 'binding': 6, 'v': 36,
                      'gen': 1, 'live': True})

# ---- 字段级负控（从 round7 套件并入；那一套已并入本文件，见文件头） ----
for _name, _field, _value in [
        ('adopted2-resource', 'resource', 999),
        ('adopted2-kind', 'kind', 99),
        ('adopted2-binding', 'binding', 999),
        ('adopted2-projection', 'projection', 1)]:
    import re as _re
    _broken = _re.sub(rf"{_field}=(-?\d+)", f"{_field}={_value}", adopt2(), count=1)
    _label = 'v' if _field == 'projection' else _field
    expect(_name, [focus(7), obs(7), _broken, BOUND], False, f'mount_snapshot_{_label}_mismatch')
expect('adopted2-selection', [focus(7), obs(7), adopt2(4, 4), BOUND], False,
       'mount_snapshot_selection_mismatch')
expect('observation-identity-incomplete',
       [focus(7), "ime selection observation forwarded ctx=7 sel=3:3 native_changed=0",
        adopt2(), BOUND], False, 'mount_snapshot_observation_identity_incomplete')
expect('adopted2-owner-version-differs',
       [focus(7), obs(7), adopt2(owner_version=1), BOUND], False,
       'mount_snapshot_owner_version_mismatch')
expect('bind-owner-version-differs',
       [focus(7), obs(7), adopt2(),
        f"PHAROS_OHOS_BIND_OWNER owner={OWNER} mirror_version=1 mirror_bytes=137 owner_version=1"],
       False, 'mount_snapshot_owner_version_not_bound')

# ---- 缺当前身份 ----
expect('no-current-identity', [ACK, REAL_ADOPTED], False, hint_absent=True)
expect('focus-identity-incomplete',
       [f"platform focus node={BODY} ctx=7 field=pharos-editor-body", ACK, REAL_ADOPTED],
       False, hint_absent=True)


# ---- round11-D4/round12-R1：读回身份是**权威当前快照** ----
HINT7 = {'ctx': 7, 'node': BODY, 'field': 'pharos-editor-body', 'resource': 54,
         'kind': 10, 'binding': 6, 'v': 36, 'gen': 1, 'live': True}
# 无 focus 行 + 匹配种子 → 采纳成立（设备真实形状：恢复成功、身份行被淘汰）
expect('readback-seed-pairs-adoption',
       [obs(7), adopt2(source_ctx=7), BOUND], True, 'mount_snapshot',
       identity_hint=HINT7)
# 种子 ctx 与采纳冻结来源不符 → 拒（种子不能让别人的采纳冒充本挂载）
expect('readback-seed-ctx-mismatch-rejected',
       [obs(7), adopt2(source_ctx=7), BOUND], False,
       'adopted2_source_not_current_mount',
       identity_hint=dict(HINT7, ctx=9))
# 行内焦点行 + 记录时配对：focus(8) 后到达的 source_ctx=7 采纳属于旧挂载 → 拒
expect('late-old-source-adoption-rejected',
       [focus(8), obs(8), adopt2(source_ctx=7), BOUND], False,
       'adopted2_source_not_current_mount', identity_hint=HINT7)
# 种子不完整（缺字段）→ 权威身份不可用，不能救绿（None=未证实，绝不拼成成立）。
expect('readback-seed-incomplete-rejected',
       [obs(7), adopt2(source_ctx=7), BOUND], False, None,
       identity_hint={'ctx': 7, 'live': True})

# ---- round12-R1 真负控：完整旧 focus 行**不得**覆盖权威当前快照 ----
# 当前 ctx9（读回）+ 完整旧 ctx7 行（focus/ACK/采纳彼此一致）→ 必须拒绝
OLD7_ACK = f"proxy restore ack accepted request=4 ctx=7 node={BODY} installed=3:3 v=36"
OLD7_ADOPT = (f"PHAROS_OHOS_RESTORE_ADOPTED count=2 failed=0 pending=false request=4 "
              f"ctx=7 node={BODY} adopted=3:3 owner_version=2 v=36")
expect('current-ctx9-old-ctx7-logs-rejected',
       [focus(7), OLD7_ACK, OLD7_ADOPT], False,
       'restore_ack_identity_not_current', identity_hint=dict(HINT7, ctx=9))
# 当前 live=False（显式结束编辑）+ 同样完整旧日志 → 必须拒绝
expect('current-none-old-ctx7-logs-rejected',
       [focus(7), OLD7_ACK, OLD7_ADOPT], False,
       'restore_ack_no_current_identity', identity_hint=dict(HINT7, live=False))
# 权威快照与证据同 ctx → 旧 focus 行在场也成立（同身份缺/多行不影响判定）
expect('authoritative-same-ctx-passes-despite-rows',
       [focus(7), OLD7_ACK, OLD7_ADOPT], True, 'restore_ack',
       identity_hint=HINT7)
# 挂载路径同样受权威门：当前 ctx9 + 完整 ctx7 挂载证据 → 拒
expect('mount-path-authoritative-ctx9-rejected',
       [focus(7), obs(7), adopt2(source_ctx=7), BOUND], False,
       'mount_snapshot_not_current_identity', identity_hint=dict(HINT7, ctx=9))

print(f"== 结果 failures={len(FAILURES)}")
raise SystemExit(1 if FAILURES else 0)

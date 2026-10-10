#!/usr/bin/env python3
"""round9-A 恢复证据来源反例（直接抽取当前 `_mount_lifecycle` /
`_identity_mismatch` / `body_restore_evidence`，不启动设备、不读归档）。

复核依据：`artifacts/h-r-final-20261002/guidance-review/round9-review.json`
的 8 例（2 正控 + 6 反例）。本文件把那 6 条**逐条**固化成可重跑的反例，并按
round9 的生产修复补上「迟到旧采纳」真正缺的那一块：生产现在给采纳事实带**本事件
自己的冻结来源**（`source_ctx` / `source_gen`），因此不可区分性有了可判定的形状。

round14-A 的必要修正（本轮真实缺陷，不是判据松紧）：round12-R1/round13-R1 之后
`body_restore_evidence` 把**读回编辑身份**（`identity_hint`）当作查询时刻的权威
当前快照——未提供即 `readback_edit_absent`，提供任何一类不可用读回都会在配对**之前**
短路成具名拒绝。本文件此前一律不传 hint，于是 19 条腿全部命中同一短路：
正控红、反例的具名理由也没被真正执行（`mount_snapshot_owner_version_mismatch` 等
一条都没到达）。判据「reachable」必须自己成立，所以这里改为：

* 每条腿显式给出**该场景结束时设备读回真实会报的内容**（退役/换焦类就报 not-live，
  换代类就报新身份），配对腿照常走完整配对路径；
* 退役语义另用 `_mount_lifecycle` 直接断言（身份=None + 具名 reason），避免权威
  补位把「已退役」这件事本身遮掉；
* 每条负控**必须**给出预期具名来源，不允许再用「不是通过就行」的空断言——否则
  下一次契约变更还会退化成整片同因短路；
* 新增读回四类（live / not-live / malformed / absent）各自的具名拒绝腿，把 round13
  的闸门本身也钉住。

判据不放松：合法路径两条正控必须仍通过；缺来源、来源不属当前挂载、缺当前挂载的
owner 绑定一律具名未证实/拒绝。没有一条反例是靠改预期、关掉合法路径或从历史捞
同值记录求绿的。
"""
import ast
import re
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
SOURCE = HERE / 'verify_pharos_dual_owner.py'
CONSUMPTION = HERE / 'h_source_preview_consumption.py'

NAMES = ('_mount_lifecycle', '_identity_mismatch', '_version_behind',
         'body_restore_evidence',
         # 实例边界用的行首 PID 解析：`_mount_lifecycle` 直接调它，不抽出来就只能在
         # 真实模块里跑到（本轮新加的 instance_pid 腿第一次把这条路径带到离线门上）。
         'row_pid')

BODY_NODE = 107
OWNER = 'main'
FROZEN_OWNER_VERSION = 2
BODY_FIELD = 'pharos-editor-body'

failures = []


def _extract(path, names, extra=()):
    tree = ast.parse(path.read_text(encoding='utf-8'))
    nodes = [n for n in tree.body
             if (isinstance(n, ast.FunctionDef) and n.name in names)
             or (isinstance(n, ast.Assign) and getattr(n.targets[0], 'id', '') in names)]
    missing = set(names) - ({getattr(n, 'name', None) or n.targets[0].id for n in nodes})
    if missing:
        raise SystemExit(f'missing symbols in {path.name}: {sorted(missing)}')
    ns = dict(extra)
    exec(compile(ast.Module(body=nodes, type_ignores=[]), str(path), 'exec'), ns)
    return ns


NS = _extract(SOURCE, NAMES, {'re': re, 'BODY_FIELD': BODY_FIELD})
body_restore_evidence = NS['body_restore_evidence']
_mount_lifecycle = NS['_mount_lifecycle']

# 读回身份必须**由生产解析器**从生产 wire 形状得到，而不是手抄一个 dict：
# 本轮 19 条同因短路的根因就是「夹具与生产契约各写各的」。走解析器之后，字段名/
# 顺序/取值形状一漂移，parse 直接给 None 或 malformed，本文件立刻红在装载期。
_CNS = _extract(CONSUMPTION, ('EDIT_LIVE_RE', 'parse_edit_section'),
                {'re': re})
parse_edit_section = _CNS['parse_edit_section']


def edit_wire(ctx=7, gen=3, node=BODY_NODE, resource=54, kind=10, binding=6,
              v=36, field=BODY_FIELD):
    return (' edit=live ctx=%d gen=%d node=%d res=%d kind=%d b=%d v=%d field=%s'
            % (ctx, gen, node, resource, kind, binding, v, field))


def hint(ctx=7, gen=3, node=BODY_NODE, resource=54, kind=10, binding=6,
         v=36, field=BODY_FIELD):
    """读回编辑身份（live 类）= 生产 ` edit=live …` 段的解析结果。"""
    parsed = parse_edit_section('OWNER_STATE' + edit_wire(ctx, gen, node, resource,
                                                          kind, binding, v, field))
    if parsed is None or parsed.get('live') is not True:
        raise SystemExit(f'readback wire not parsed as live: {parsed!r}')
    return parsed


def hint_not_live():
    return parse_edit_section(' edit=none')


def hint_malformed():
    return parse_edit_section(' edit=live ctx=7 gen=3 node=107')


def hint_partial(ctx=7, gen=3, node=BODY_NODE, resource=54, kind=10, binding=None,
                 v=36, field=BODY_FIELD):
    """live=True 但身份分量缺失：生产把这类读回视同不可用，这里手工构造同形。"""
    return {'live': True, 'ctx': ctx, 'gen': gen, 'node': node, 'field': field,
            'resource': resource, 'kind': kind, 'binding': binding, 'v': v}


def restore(rows, readback=None, tag_prefix='PHAROS', main_owner=OWNER,
            instance_pid=None, owner_version=FROZEN_OWNER_VERSION):
    return body_restore_evidence(rows, 0, BODY_NODE, 1, main_owner,
                                 owner_version=owner_version,
                                 identity_hint=readback, tag_prefix=tag_prefix,
                                 instance_pid=instance_pid)


def lifecycle(rows, readback=None):
    return _mount_lifecycle(rows, 0, BODY_NODE, 1, OWNER, identity_hint=readback)


def accepted(result):
    """两条合法路径的**成功**形状。"""
    return result is not None and result.get('source') in ('restore_ack', 'mount_snapshot')


def expect_reject(name, rows, expect_source, readback=None, **guard_kw):
    """负控：必须命中**指定**的具名来源。

    `expect_source` 现在是必填参数（round14）：允许省略就等于允许一条腿在配对之前
    短路也算「符合预期」，本文件 19 条同因红正是这么漏掉的。
    """
    result = restore(rows, readback, **guard_kw)
    if accepted(result):
        failures.append((name, 'accepted', expect_source))
        print(f'  FAIL {name}: 期望拒绝，实际通过（{result.get("source")}）')
        return result
    if result is None:
        failures.append((name, None, expect_source))
        print(f'  FAIL {name}: 得到未观测到(None)，期望具名 {expect_source}')
        return result
    if _short_circuited(name, result):
        return result
    if result.get('source') != expect_source:
        failures.append((name, result.get('source'), expect_source))
        print(f'  FAIL {name}: 具名={result.get("source")} 期望={expect_source}')
        return result
    print(f'  ok   {name}: 具名 {result.get("source")}')
    return result


def _short_circuited(name, result):
    """装载期契约漂移探测器：非「读回缺失」腿却命中 absent 闸门 = 生产又加了一道
    前置短路，本文件的所有具名理由将再次变成不可达。必须显式记账，不能让它静默
    把整套退化成同一条短路。"""
    if result.get('reason') == 'readback_edit_absent' and 'readback_absent' not in name:
        failures.append((name, 'readback_edit_absent', 'pairing-path-reached'))
        print(f'  FAIL {name}: 命中意外的读回短路（readback_edit_absent），'
              f'具名判据不可达')
        return True
    return False


def expect_accept(name, rows, readback=None, **guard_kw):
    result = restore(rows, readback, **guard_kw)
    if result is not None and _short_circuited(name, result):
        return result
    if not accepted(result):
        failures.append((name, result.get('source') if result else None, 'accept'))
        print(f'  FAIL {name}: 期望通过，实际 {result.get("source") if result else "None"}'
              f'（{result.get("reason") if result else ""}）')
        return result
    print(f'  ok   {name}: 通过（{result.get("source")}）')
    return result


def expect_unobserved(name, rows, readback=None, **guard_kw):
    """「未观测到」(None)：候选已被生命周期本身清空，没有东西可配对。

    这**不是**通过，但也**不是**具名拒绝——退役类场景日志里已无候选，硬要它给出具名
    理由就是把工具的形状编出来。配对层面的「不再通过」在此断言，退役**这件事**由
    `expect_lifecycle` 断言；两条合起来才完整。
    """
    result = restore(rows, readback, **guard_kw)
    if result is not None:
        failures.append((name, result.get('source'), None))
        print(f'  FAIL {name}: 期望未观测到(None)，实际 {result.get("source")}')
        return result
    print(f'  ok   {name}: 未观测到(None)，未通过')
    return result


def expect_lifecycle(name, rows, reason, readback=None):
    """退役语义按**扫描状态**断言：当前身份为 None 且具名 reason 命中。"""
    st = lifecycle(rows, readback)
    if st['identity'] is not None:
        failures.append((name, 'identity_alive', reason))
        print(f'  FAIL {name}: 期望身份退役，实际 {st["identity"]}')
        return st
    if st['reason'] != reason:
        failures.append((name, st['reason'], reason))
        print(f'  FAIL {name}: 生命周期具名={st["reason"]} 期望={reason}')
        return st
    print(f'  ok   {name}: 身份退役（{st["reason"]}）')
    return st


def expect_rebound(name, rows, readback=None, **new_identity):
    """换绑类退役断言的是**候选作废**：身份已换成新元组，旧挂载的 adopted2/
    observation/BIND_OWNER 一项都不剩（留着任何一项都能被拿来补齐新挂载）。"""
    st = lifecycle(rows, readback)
    identity = st['identity']
    if identity is None:
        failures.append((name, 'identity_none', 'identity_replaced'))
        print(f'  FAIL {name}: 期望身份换成新元组，实际已退役(None)')
        return st
    for key, value in new_identity.items():
        if identity.get(key) != value:
            failures.append((name, f'{key}={identity.get(key)}', f'{key}={value}'))
            print(f'  FAIL {name}: 新身份 {key}={identity.get(key)} 期望 {value}')
            return st
    if st['adopted2'] is not None or st['bind_versions']:
        failures.append((name, 'old_candidates_survive', 'cleared'))
        print(f'  FAIL {name}: 旧挂载候选未作废（adopted2={st["adopted2"]} '
              f'bind={st["bind_versions"]}）')
        return st
    print(f'  ok   {name}: 换绑后旧候选全部作废（新身份 {identity}）')
    return st


# ---------------------------------------------------------------------------
# 生产行构造。ADOPTED2 带 round9 新增的 `source_ctx` / `source_gen`（生产在事件
# 入队时冻结的来源身份），以及必填的 `owner_version`。
# ---------------------------------------------------------------------------

def focus(ctx=7, node=BODY_NODE, field=BODY_FIELD, resource=54, kind=10, binding=6, v=36):
    return (f'platform focus node={node} ctx={ctx} field={field} '
            f'resource={resource} kind={kind} binding={binding} v={v}')


def obs(ctx=7, sel=(3, 3), node=BODY_NODE, resource=54, kind=10, binding=6, v=36):
    return (f'ime selection observation forwarded ctx={ctx} sel={sel[0]}:{sel[1]} '
            f'node={node} resource={resource} kind={kind} binding={binding} v={v} '
            f'native_changed=0')


def adopt2(sel=(3, 3), node=BODY_NODE, resource=54, kind=10, projection=36, binding=6,
           owner_version=FROZEN_OWNER_VERSION, source_ctx=7, source_gen=3):
    src = f'source_ctx={source_ctx} source_gen={source_gen}' \
        if source_ctx is not None else 'source_ctx=none source_gen=none'
    return (f'CJGUI_OWNED_SELECTION_ADOPTED2 node={node} resource={resource} '
            f'kind={kind} sel={sel[0]}:{sel[1]} projection={projection} '
            f'binding={binding} owner_version={owner_version} {src}')


def bound(owner=OWNER, owner_version=FROZEN_OWNER_VERSION):
    return (f'PHAROS_OHOS_BIND_OWNER owner={owner} mirror_version=2 mirror_bytes=137 '
            f'owner_version={owner_version}')


def ack(request=4, ctx=7, node=BODY_NODE, installed=(3, 3), v=36):
    return (f'proxy restore ack accepted request={request} ctx={ctx} node={node} '
            f'installed={installed[0]}:{installed[1]} v={v}')


def restore_adopted(count=2, request=4, ctx=7, node=BODY_NODE, adopted=(3, 3),
                    owner_version=FROZEN_OWNER_VERSION, v=36, failed=2, pending='false'):
    """生产真实格式：failed/pending 夹在 count 与 request 之间（round8 的解析修复
    保留，本文件继续按真实形状构造，不退回旧格式）。"""
    return (f'PHAROS_OHOS_RESTORE_ADOPTED count={count} failed={failed} '
            f'pending={pending} request={request} ctx={ctx} node={node} '
            f'adopted={adopted[0]}:{adopted[1]} owner_version={owner_version} v={v}')


RELEASE = 'proxy released by framework ctx=7'
TERMINATED = 'proxy restore terminated reason=human_anchor_supersedes request=4 ctx=7 code=1'
MOUNT_SNAPSHOT_ROWS = [focus(), obs(), adopt2(), bound()]
ACK_ROWS = [focus(), ack(), restore_adopted()]

print('== round9-A 恢复证据来源反例 ==')

# ---- 合法正控（复核件第 1、2 例；必须仍然通过） ----
expect_accept('mount_positive', MOUNT_SNAPSHOT_ROWS, hint())
expect_accept('explicit_real_format_positive', ACK_ROWS, hint())

# ---- 反例 1：同一 live binding 再次 focus（幂等聚焦） ----
# 生产：beginEditingOnNodeLocked 对 wasEditing && sameBindingAsBefore &&
# editingContextLive 直接 return，不换上下文编号；外层仍打印 focus 行。
# round8 把这条当成重挂 → 清空了已完整成立的证据。
expect_accept('idempotent_focus_preserves_current_evidence',
              MOUNT_SNAPSHOT_ROWS + [focus()], hint())

# ---- 反例 2：新 ctx8 已成立后，旧 ctx7 的迟到 release ----
# 生产：proxy released by framework ctx=7 是 ArkTS 侧销毁通知，与 native 聚焦不在
# 同一执行阶段；它只能终结它所指的身份。读回此时报 ctx8（换代后的现值）。
expect_accept('old_context_release_does_not_retire_new_context',
              [focus(), focus(ctx=8), obs(ctx=8), adopt2(source_ctx=8), bound(),
               RELEASE],
              hint(ctx=8, gen=4))

# ---- 反例 3：恢复请求终结（请求生命周期 ≠ 挂载生命周期） ----
# 生产：recordHumanSelectionAnchorLocked 只终结一笔恢复请求，输入上下文仍有效。
expect_accept('request_termination_does_not_retire_editing_context',
              [focus(), TERMINATED, obs(), adopt2(), bound()], hint())

# ---- 反例 4：缺 BIND_OWNER 不是完整挂载证明 ----
# 函数契约要求当前绑定与冻结 owner；round8 的 `if bind_versions` 在空列表时整段
# 跳过检查。
expect_reject('missing_owner_binding_is_not_complete_mount_proof',
              [focus(), obs(), adopt2()],
              'mount_snapshot_no_current_owner_binding', hint())

# ---- 反例 5：只有旧 ctx 的 BIND_OWNER，不能补齐新挂载 ----
expect_reject('old_owner_binding_is_not_current_mount_binding',
              [focus(), obs(), adopt2(), bound(),
               focus(ctx=8), obs(ctx=8), adopt2(source_ctx=8)],
              'mount_snapshot_no_current_owner_binding',
              hint(ctx=8, gen=4))

# ---- 反例 6：迟到旧 ADOPTED2（新挂载已成立，来源仍指向旧 ctx） ----
# round8 无来源字段，只能按到达时代号盖章 → 给旧事实盖新代号并通过。round9 生产
# 带冻结来源后，这条按来源判定：来源不属当前挂载即拒。
expect_reject('late_old_adoption_with_new_same_value_observation',
              [focus(), obs(), focus(ctx=8), obs(ctx=8),
               adopt2(source_ctx=7), bound()],
              'adopted2_source_not_current_mount',
              hint(ctx=8, gen=4))

# ---- 缺冻结来源一律不作成证据（不可区分性不得靠猜） ----
# 生产在拿不到来源时写 `source_ctx=none source_gen=none`（不是省略字段），
# 因此这一形状命中「来源不是有效身份」这条判据。
expect_reject('adopted2_without_frozen_source_is_not_evidence',
              [focus(), obs(), adopt2(source_ctx=None), bound()],
              'adopted2_source_not_numeric', hint())
# 旧版本产物根本没有 source_* 字段：同样不作证据，但具名不同（缺来源字段）。
expect_reject('adopted2_source_field_absent_is_not_evidence',
              [focus(), obs(),
               adopt2().replace(' source_ctx=7 source_gen=3', ''), bound()],
              'adopted2_missing_frozen_source', hint())

# ---- 当前挂载真的被框架释放 → 退役 ----
# 两层都要断言（round14）：扫描层面身份确实退役且候选清空；配对层面在「读回也报无
# 当前编辑」时不再通过。释放把候选一并清空，所以这里的答案是「未观测到」而不是
# 具名拒绝——具名拒绝腿另有（读回四类），两者不能互相顶替。
expect_lifecycle('current_mount_released_retires_identity',
                 MOUNT_SNAPSHOT_ROWS + [RELEASE], 'mount_released_ctx_7', hint())
expect_unobserved('released_mount_pairing_stops_passing',
                  MOUNT_SNAPSHOT_ROWS + [RELEASE], hint_not_live())

# ---- 读回缺失/不可用：不得把「无当前身份」借历史日志拼回绿 ----
expect_reject('readback_absent_is_named_reject', MOUNT_SNAPSHOT_ROWS,
              'mount_snapshot_no_current_identity')
expect_reject('readback_absent_blocks_ack_path', ACK_ROWS,
              'restore_ack_no_current_identity')
expect_reject('readback_not_live_is_named_reject', MOUNT_SNAPSHOT_ROWS,
              'mount_snapshot_no_current_identity', hint_not_live())
expect_reject('readback_malformed_is_named_reject', MOUNT_SNAPSHOT_ROWS,
              'mount_snapshot_no_current_identity', hint_malformed())
# live=True 但字段不完整（缺 binding）：同属畸形，不作权威。
expect_reject('readback_live_but_partial_is_named_reject', MOUNT_SNAPSHOT_ROWS,
              'mount_snapshot_no_current_identity', hint_partial(binding=None))
# 读回与日志候选冲突（读回换到了 ctx8，日志只有 ctx7 的采纳）：按权威拒绝。
expect_reject('readback_authority_conflicts_with_old_mount_evidence',
              MOUNT_SNAPSHOT_ROWS, 'mount_snapshot_not_current_identity',
              hint(ctx=8, gen=4))

# 兜底形状：什么候选都没有就是「未观测到」（None），不具名拒绝。
_unobserved = restore([focus()], hint())
print(f'  ok   no_candidates_is_unobserved: '
      f'{None if _unobserved is None else _unobserved}')
if _unobserved is not None:
    failures.append(('no_candidates_is_unobserved', _unobserved.get('source'), None))

# ---- 换焦到别的节点 / 别的字段族 → 退役 ----
OTHER_NODE = ['platform focus node=313 ctx=8 field=pharos-document-note '
              'resource=1 kind=10 binding=5 v=9']
expect_lifecycle('focus_other_node_retires', MOUNT_SNAPSHOT_ROWS + OTHER_NODE,
                 'focus_moved_to_node_313_pharos-document-note', hint())
expect_unobserved('focus_other_node_retires_pairing', MOUNT_SNAPSHOT_ROWS + OTHER_NODE,
                  hint_not_live())
expect_lifecycle('focus_other_field_retires',
                 MOUNT_SNAPSHOT_ROWS +
                 ['platform focus node=107 ctx=8 field=pharos-note resource=54 '
                  'kind=10 binding=6 v=36'],
                 'focus_field_pharos-note', hint())

# ---- 换绑（身份分量变化）→ 新挂载，旧候选作废 ----
# 断言的是**候选作废**：新身份成立后，旧挂载的 adopted2/BIND_OWNER 一项都不剩，
# 因此旧 owner 绑定补不了新挂载；此时还没有新采纳，答案是「未观测到」而非通过。
expect_rebound('rebind_with_new_epoch_retires_old_adoption',
               [focus(), obs(), adopt2(), bound(),
                focus(binding=99, v=40), obs(ctx=7, binding=99, v=40)],
               hint(), binding=99, v=40)
expect_unobserved('rebind_without_new_adoption_is_unobserved',
                  [focus(), obs(), adopt2(), bound(),
                   focus(binding=99, v=40), obs(ctx=7, binding=99, v=40)],
                  hint())

# ---- 身份分量缺失不得成为身份锚点 ----
INCOMPLETE_FOCUS = ['platform focus node=107 ctx=7 field=pharos-editor-body kind=10']
expect_lifecycle('focus_identity_incomplete_is_not_anchor',
                 INCOMPLETE_FOCUS + [obs(), adopt2(), bound()],
                 'focus_identity_incomplete', hint_not_live())
expect_unobserved('focus_identity_incomplete_pairing',
                  INCOMPLETE_FOCUS + [obs(), adopt2(), bound()], hint())

# ---- 字段级负控（round7 判据全部保留） ----
for _name, _field, _value in [('adopted2-resource', 'resource', 999),
                              ('adopted2-kind', 'kind', 99),
                              ('adopted2-binding', 'binding', 999),
                              ('adopted2-projection', 'projection', 1)]:
    broken = re.sub(rf'{_field}=(-?\d+)', f'{_field}={_value}', adopt2(), count=1)
    label = 'v' if _field == 'projection' else _field
    expect_reject(_name, [focus(), obs(), broken, bound()],
                  f'mount_snapshot_{label}_mismatch', hint())

expect_reject('adopted2-selection', [focus(), obs(), adopt2(sel=(4, 4)), bound()],
              'mount_snapshot_selection_mismatch', hint())
expect_reject('observation_identity_incomplete',
              [focus(), 'ime selection observation forwarded ctx=7 sel=3:3 native_changed=0',
               adopt2(), bound()],
              'mount_snapshot_observation_identity_incomplete', hint())
expect_reject('adopted2_owner_version_differs',
              [focus(), obs(), adopt2(owner_version=1), bound()],
              'mount_snapshot_owner_version_mismatch', hint())
expect_reject('bind_owner_version_differs',
              [focus(), obs(), adopt2(), bound(owner_version=1)],
              'mount_snapshot_owner_version_not_bound', hint())
expect_reject('adopted2_missing_owner_version',
              [focus(), obs(),
               adopt2().replace(f' owner_version={FROZEN_OWNER_VERSION}', ''), bound()],
              'adopted2_missing_owner_version', hint())

# 观测落在别的 ctx（静默换上下文通道）：不得与当前身份配对。
expect_reject('observation_on_other_ctx_not_paired',
              [focus(), obs(ctx=9), adopt2(), bound()],
              'mount_snapshot_no_platform_observation', hint())

# ---- 第二独立消费者（thermo）：同一守卫、具名 tag 前缀 ----
# thermo 产品侧 `controller.takeRestoreAdoptionFact()` 经宿主 hilog 发出
# `THERMO_OHOS_RESTORE_ADOPTED …`；安装腿复用**同一个** body_restore_evidence，
# 只按 tag 前缀归属。两个方向都必须判得开：借来的、错名的一律不通过。
def thermo_adopted(count=2, request=4, ctx=7, node=BODY_NODE, adopted=(3, 3),
                   owner_version=FROZEN_OWNER_VERSION, v=36):
    return (f'THERMO_OHOS_RESTORE_ADOPTED count={count} failed=0 pending=false '
            f'request={request} ctx={ctx} node={node} '
            f'adopted={adopted[0]}:{adopted[1]} owner_version={owner_version} v={v}')


SECOND_CONSUMER_ROWS = [focus(), ack(), thermo_adopted()]
expect_accept('second_consumer_thermo_tag_positive', SECOND_CONSUMER_ROWS, hint(),
              tag_prefix='THERMO', main_owner=None)
# 反方向：同一批日志用 PHAROS 名字查——采纳事实不属该消费者，只能到"票已 ACK 未采纳"。
expect_reject('second_consumer_pharos_tag_cannot_borrow_thermo_adoption',
              SECOND_CONSUMER_ROWS, 'restore_ack_unadopted', hint())
# 只有平台 ACK、产品从未认领：安装不成立。
expect_reject('second_consumer_without_product_adoption_not_installed',
              [focus(), ack()], 'restore_ack_unadopted', hint(),
              tag_prefix='THERMO', main_owner=None)
# 计数未相对基线前进（adopted_before 冻结为 1，行里 count=1）：本轮没有新的采纳，
# 旧挂载的采纳行不能冒充这一笔。
expect_reject('second_consumer_stale_count_not_adopted',
              [focus(), ack(), thermo_adopted(count=1)], 'restore_ack_unadopted', hint(),
              tag_prefix='THERMO', main_owner=None)

# ---- 实例边界：PID 的 int 与 str 两种写法必须等价 ----
# hilog 行解析出的 PID 是 int，而设备脚本（thermo 的 `thermo_pid()`）拿到的是 str。
# 直接 `row_pid(row) != instance_pid` 会把**所有**行滤掉：守卫于是永远"未观测到"，
# 看起来像设备上没装成功，实际是类型不匹配（本轮实测的静默失败形状）。
def hrow(row, pid=20575, tid=20575):
    return f'10-06 11:46:32.366 {pid} {tid} I A00000/CjguiRenderer: {row}'


PID_SCOPED_ROWS = [hrow(r) for r in ACK_ROWS]
expect_accept('instance_pid_int_form_pairs', PID_SCOPED_ROWS, hint(),
              instance_pid=20575)
expect_accept('instance_pid_str_form_pairs_same_as_int', PID_SCOPED_ROWS, hint(),
              instance_pid='20575')
# 别的实例的行一律不配对：同号旧票不能解锁新会话。
expect_unobserved('other_instance_rows_never_paired', PID_SCOPED_ROWS, hint(),
                  instance_pid=20999)

# ---------------------------------------------------------------------------
# round15-B 投影版本**同刻**反例（独立只读咨询裁定 + 设备原件逐字段回放）
# ---------------------------------------------------------------------------
# 读回 `v` 是查询时刻的 Session 现值（host `cjguiOhosEditingIdentityOf` 取
# `s.editingProjectionVersion`，注释明写「只在查询时从现值读取」）；armed/ack/adopted
# 的 `v` 是同一签发时刻冻结的 `acceptedProjectionVersion`。生产在**采纳成功**这一步
# 自己就 `interactionVersion += 1` 调度下一次发布，keep-ctx 发布（local-continuation
# / pure-geometry / local-accept）也在不换 ctx 的前提下推进 v。所以跨时刻的 v **等式
# 结构性不可满足**：设备两轮原件是 159↔161、164↔167（差值不恒定，不是竞态没赢）。
# 改后的判据：票内等式保留（同刻同域），跨时刻只核单调；换挂载仍由 ctx 判别。
#
# 上面 `explicit_real_format_positive` 的 v=36↔36 是**同刻**特例（等式满足 ≥），
# 它不能证明本轮修的是设备形状——下面的原件回放才是。

DEV_CTX, DEV_RES, DEV_KIND, DEV_BINDING = 1, 9801, 3, 1


def dev_rows(installed_v):
    """设备原件形状：**没有** `platform focus` 行（环形缓冲里已淘汰，安装链发生在
    应用启动序列），当前身份只能由读回种子提供；同实例、同请求号的 ack 与产品采纳
    带签发冻结 v，读回必然落在更晚代际。"""
    return [hrow(ack(ctx=DEV_CTX, installed=(0, 0), v=installed_v), pid=27348),
            hrow(thermo_adopted(ctx=DEV_CTX, adopted=(0, 0), v=installed_v), pid=27348)]


def dev_hint(current_v):
    return hint(ctx=DEV_CTX, gen=1, resource=DEV_RES, kind=DEV_KIND,
                binding=DEV_BINDING, v=current_v)


expect_accept('device_replay_v159_readback_v161_pairs', dev_rows(159), dev_hint(161),
              tag_prefix='THERMO', main_owner=None, instance_pid='27348')
expect_accept('device_replay_v164_readback_v167_pairs', dev_rows(164), dev_hint(167),
              tag_prefix='THERMO', main_owner=None, instance_pid='27348')

# ---- 扫描侧同一错误的另一半：同 ctx、v 前进的 focus 行不是换绑 ----
# 生产 `platform focus` 行打印**现值**；keep-ctx 发布之后经 focus API 再聚焦同锚，
# 会得到同 ctx、v 更大的行。旧实现把 v 当身份分量，于是这条合法行清空了
# ADOPTED2／观测／BIND_OWNER 候选（咨询实验 E5 的形状）。
expect_accept('idempotent_refocus_advanced_v_keeps_candidates',
              MOUNT_SNAPSHOT_ROWS + [focus(v=40)], hint(v=40))

# ---- 判据改动**不得**削弱的串票腿 ----
# 原意核心：旧挂载（ctx7）的完整 ACK+采纳，不能补齐新挂载（ctx8）。换挂载判别力
# 现在**只**落在 ctx 上，这条必须仍然红、且具名 mismatch=ctx。
expect_reject('old_mount_adoption_cannot_complete_new_mount',
              [focus(), ack(), restore_adopted(), focus(ctx=8)],
              'restore_ack_identity_not_current', hint(ctx=8, gen=4))
# 票内等式仍是硬门：同一请求号的 ack 与采纳把签发冻结值打成两个 v 即真异常
# （也是「产品按当前代际重认领」这类改法的证伪器——那样改此腿永久红）。
expect_reject('ticket_internal_v_disagreement_named',
              [focus(), ack(v=36), restore_adopted(v=37)],
              'restore_ack_ticket_fields_mismatch', hint())
# 单调不等式保留的残留判别力：同 pid 内窗口重建会重置场景版本计数（ctx 计数是
# 进程级原子、不重置），读回现值**低于**该票签发值即旧窗口采纳串进新窗口。
expect_reject('readback_v_behind_ack_version',
              [focus(), ack(), restore_adopted()],
              'restore_ack_version_behind_current', hint(v=30))

# ---- round15-B 贯穿链（目标点名的那条）----
# 首绑（带完整身份）→ 声明晋升与重新聚焦（同 ctx、v 前进的合法 focus 行）→
# 同 owner 几何提交（accepted 行，守卫不消费但原件在流里）→ 安装与窗口采纳
# （新一次请求的 ack + 产品采纳，票内同刻等值）→ 一次输入后的读回现值。
# 这条腿把上面各条**串成一个时序**：任何一环被误判成换挂载，链就断在中间。
expect_accept('cross_cutting_lifecycle_chain',
              [focus(v=36),
               'accepted node=107 semantic=pharos-editor body commit v=37',
               focus(v=38),
               ack(request=6, v=38), restore_adopted(request=6, count=3, v=38),
               focus(v=40)],
              hint(v=40))

# ---- 外部 owner 推进的退役方向（测量后定的形状）----
# 语义核对：每腿的判据是「本轮**冻结基线**上是否真发生过安装＋采纳」。
# 外部推进（BIND_OWNER 带新版本）之后：
#  * 冻结在旧基线的那一腿仍然是事实（它评的是已经发生的会话）；
#  * 冻结在**新基线**的下一腿不得借旧基线的采纳成证——这才是"退役旧身份"的落点。
EXTERNAL_ADVANCE_ROWS = [focus(), obs(), adopt2(), bound(), bound(owner_version=9)]
expect_accept('old_frozen_baseline_still_pairs_after_external_bind',
              EXTERNAL_ADVANCE_ROWS, hint())
expect_reject('new_frozen_baseline_cannot_borrow_old_owner_adoption',
              EXTERNAL_ADVANCE_ROWS, 'mount_snapshot_owner_version_mismatch',
              hint(), owner_version=9)

# ---- 旧失败 ACK 与新 ctx 交错不串票 ----
# 生产：请求终结只结那一张票；新 ctx 重新签。旧票的 ack/adopted 若留在缓冲里，
# 新会话不得借它成证。
expect_reject('old_terminated_ack_does_not_complete_new_ctx',
              [focus(), ack(), TERMINATED, restore_adopted(), focus(ctx=8)],
              'restore_ack_identity_not_current', hint(ctx=8, gen=4))

print()
if failures:
    print(f'FAILURES: {len(failures)}')
    for item in failures:
        print('  ', item)
    sys.exit(1)
print('round9-A 恢复证据来源反例: OK（全部符合预期）')

#!/usr/bin/env python3
"""round10/11 D3：单份快照判据反例——**执行真实 reach_mode**（不是测试自写 judge）。

round11 复核批评本套件旧版：自写 judge 复刻判定链、且把「会话重建（token 变化）
必须放行」固化成正控——那条前提已被撤回（token 6→8→10 实为格式串错位，不是
产品重建会话）。本版直接 AST 抽取生产 `reach_mode`（含其内嵌 judge/settled/
settledTwice）及其依赖，用受控 OWNER_STATE 线驱动，逐字执行：

  * 六份互不一致的响应轮换 → 恒不通过，且全部具名；
  * 一致快照正控（单次切换）→ 通过，恰好一次动作；
  * 合法无动作正控 → already_at_target，零动作；
  * 异 token（round11 反例 999）：即使 epoch/frame/ticket 更大也拒绝（负控，
    取代被撤回的 session-rebuild 正控）；
  * MODE 声明已到目标而 accepted 还是旧面 → 具名失败且**零额外动作**
    （不得反向 toggle）；
  * ticket_verdict 直测：reason(x) 映射、x 缺失未证实、同 token epoch 倒退。
"""
import ast
import importlib.util
import re
import sys
from pathlib import Path
from types import SimpleNamespace

HERE = Path(__file__).resolve().parent
SOURCE = HERE / 'verify_pharos_dual_owner.py'

# 抽取的生产函数。reach_mode 的内嵌判定（judge/settled/settledTwice）随函数体
# 一起执行；日志侧辅助（mode_trace/_fence_start）与设备出口（m/request）用替身。
NAMES = ('public_state', 'public_snapshot', 'action_baseline', 'ticket_verdict',
         'driver_face_from_snapshot', '_classify_face', 'reach_mode')

failures = []


def check(name, got, want):
    ok = got == want
    print(f"  {'OK  ' if ok else 'FAIL'} {name}: {got!r}" + ('' if ok else f' (want {want!r})'))
    if not ok:
        failures.append(name)


_dev_spec = importlib.util.spec_from_file_location(
    'r13_ss_device', HERE / 'h_source_preview_consumption.py')
_dev = importlib.util.module_from_spec(_dev_spec)
_dev_spec.loader.exec_module(_dev)


def load(src=None):
    src = SOURCE.read_text(encoding='utf-8') if src is None else src
    tree = ast.parse(src)
    nodes = [n for n in tree.body if isinstance(n, ast.FunctionDef) and n.name in NAMES]
    missing = {n for n in NAMES if n not in {x.name for x in nodes}}
    if missing:
        raise SystemExit(f'missing functions: {sorted(missing)}')
    ns = {'re': re, 'm': _dev, '_SNAP_READ_SEQ': {'n': 0},
          'request': lambda *_: 'OWNER_STATE_UTF8_HEX 0 \n'}
    exec(compile(ast.Module(body=nodes, type_ignores=[]), str(SOURCE), 'exec'), ns)
    for const in ('REASON_PROTOCOL', 'REASON_PRESENT_FAILED', 'REASON_CANCELLED',
                  'PRESENT_DECISION'):
        line = next((l for l in src.splitlines() if l.startswith(const + ' = ')), None)
        if line is None:
            raise SystemExit(f'constant not found: {const}')
        rhs = line.split('=', 1)[1].split('#', 1)[0].strip()
        ns[const] = eval(rhs, {'__builtins__': {}}, ns)
    for kind in ('BODY', 'PREVIEW'):
        name = f'_{kind}_PREFIXES'
        start = src.index(f'{name} = (')
        depth, k = 0, src.index('(', start)
        while True:
            if src[k] == '(':
                depth += 1
            elif src[k] == ')':
                depth -= 1
                if depth == 0:
                    break
            k += 1
        ns[name] = tuple(re.findall(r"'([^']+)'", src[start:k]))
    return ns


NS = load()


def state_line(mode, face, token=201, epoch=9, proj=6, frame=6, last=3, unacked=0,
               tickets=1, faces=1, ticket_tail=None, extra_faces=None):
    """构造一条生产形状的 OWNER_STATE 行（字段序与 ohos_renderer_accepted_state 一致）。"""
    semantic = 'pharos-document-note' if face == 'preview' else 'pharos-editor-body'
    row = (f'MODE={mode} ACCEPTED token={token} epoch={epoch} proj={proj} nodes=16 '
           f'semantic=12345 frame={frame} last={last} unacked={unacked} '
           f'unackedDecision=0 unackedStatus=0 unackedCtx=0 unackedNodes=0 '
           f'tickets={tickets} faces={faces}')
    row += f' F107:{semantic}'
    for extra in extra_faces or []:
        row += f' F313:{extra}'
    if ticket_tail:
        row += ticket_tail
    return row


def ticket_tail(tid, decision=2, status=0, ver=6, ctx=9, nodes=16, reason=0):
    tail = '' if reason is None else f'/x{reason}'
    return f' T{tid}/{decision}/s{status}/v{ver}/c{ctx}/n{nodes}{tail}'


def run_reach(sequence, target='preview', rounds=1, ns=None):
    """驱动**真实** reach_mode：request 按序吐行（末行重复），记录动作次数。"""
    ns = NS if ns is None else ns
    if '_SNAP_READ_SEQ' not in ns:
        ns['_SNAP_READ_SEQ'] = {'n': 0}
    for name in ('request', 'm', 'mode_trace', '_fence_start', 'time',
                 'PRESENT_DECISION', 'REASON_PROTOCOL', 'REASON_PRESENT_FAILED',
                 'REASON_CANCELLED', '_BODY_PREFIXES', '_PREVIEW_PREFIXES'):
        if name not in ns and name in NS:
            ns[name] = NS[name]
    if 'request' not in ns:
        # snapshot_of 路径：默认受控 wire（由各用例覆盖）。
        ns['request'] = lambda *_: 'OWNER_STATE_UTF8_HEX 0 \n'
    reads = []
    clicks = []

    def req(_lines, _port):
        row = sequence[min(len(reads), len(sequence) - 1)]
        reads.append(row)
        return f'OWNER_STATE_UTF8_HEX {len(row.encode())} {row.encode().hex()}\n'

    ns['request'] = req
    ns['m'] = SimpleNamespace(
        readback_target_point=lambda *_a, **_k: ((10, 10), None),
        accepted_semantic_point=lambda *_: (10, 10),
        parse_edit_section=_dev.parse_edit_section,
        hilog_rows=lambda: ['D 1234 filler'],
        uitest=lambda *a: clicks.append(a))
    ns['mode_trace'] = lambda *a, **k: {'stub': 'no-log-fallback'}
    ns['_fence_start'] = lambda rows, text: 0
    ns['time'] = SimpleNamespace(sleep=lambda *_: None)
    result = {}
    ok, reason = ns['reach_mode'](0, target, result, 'case', rounds=rounds)
    return {'passed': ok, 'reason': reason, 'reads': len(reads),
            'clicks': len(clicks), 'details': result}


def snapshot_of(state_line):
    NS['request'] = lambda *_: (
        f'OWNER_STATE_UTF8_HEX {len(state_line.encode())} {state_line.encode().hex()}\n')
    return NS['public_snapshot'](28997)


# round13-R1：public_snapshot 引用模块级 m.parse_edit_section——加载真实共享
# 解析规范（与生产同一实现，不允许桩自带解析）。
NS['m'] = _dev
NS['_SNAP_READ_SEQ'] = {'n': 0}


def main():
    print('== round10/11 D3 单份快照判据（真实 reach_mode） ==')

    base_src = state_line('source', 'source', token=201, epoch=3, last=3)
    at_preview_ok = state_line('preview', 'preview', token=201, epoch=10, last=3)
    switched_ok = state_line('preview', 'preview', token=201, epoch=10, last=4,
                             ticket_tail=ticket_tail(4, ver=7))

    # ---- 1. round10 假绿处刑：6 份互不一致的响应轮换 ----
    # 每份都不满足「MODE=preview 且 accepted 为 preview」；首份 MODE=preview ⇒
    # 声明已在目标 ⇒ 全程零动作。
    inconsistent = [
        state_line('preview', 'source', epoch=1, last=3, ticket_tail=ticket_tail(3)),
        state_line('preview', 'source', epoch=2, last=3, ticket_tail=ticket_tail(3)),
        state_line('source', 'preview', epoch=3, last=3, ticket_tail=ticket_tail(3)),
    ] * 2
    r = run_reach(inconsistent, target='preview', rounds=5)
    check('mixed-snapshots-never-pass', r['passed'], False)
    check('mixed-snapshots-zero-extra-actions', r['clicks'], 0)
    check('mixed-snapshots-named-failure',
          r['reason'] in ('accepted_face_not_target', 'mode_not_at_target',
                          'stale_token', 'stale_epoch'), True)

    # ---- 2. 一致快照正控：单次切换恰好一次动作 ----
    # 读序：初始基线→初始判定→动作前基线（仍是 source）→点击后的两次判定。
    r = run_reach([base_src, base_src, base_src, switched_ok, switched_ok],
                  target='preview')
    check('consistent-switch-passes', r['passed'], True)
    check('consistent-switch-single-action', r['clicks'], 1)
    check('consistent-switch-reason', r['reason'], 'submitted_target')

    # ---- 3. 合法无动作正控：已在目标且面一致 ----
    r = run_reach([at_preview_ok], target='preview')
    check('legitimate-no-action-passes', r['passed'], True)
    check('legitimate-no-action-zero-clicks', r['clicks'], 0)
    check('legitimate-no-action-reason', r['reason'], 'already_at_target')

    # ---- 4. 异 token 负控（round11 反例：999 冒充 201）----
    # 取代旧「session-rebuild-is-allowed」正控——该前提已撤回：token 6→8→10 是
    # 格式串错位，不是产品重建会话。异 token 即使 epoch/frame/ticket 更大也拒绝。
    unrelated = state_line('preview', 'preview', token=999, epoch=20, proj=20,
                           frame=20, last=99, ticket_tail=ticket_tail(99, ver=20))
    r = run_reach([base_src, base_src, base_src, unrelated, unrelated],
                  target='preview')
    check('unrelated-token-rejected', r['passed'], False)
    check('unrelated-token-named', r['reason'], 'stale_token')
    check('unrelated-token-single-action', r['clicks'], 1)

    # ---- 5. MODE 声明已到目标而 accepted 还是旧面（round11 反例）----
    declared_wrong_face = state_line('preview', 'source', token=201, epoch=10,
                                     last=3, ticket_tail=ticket_tail(3))
    r = run_reach([declared_wrong_face], target='preview', rounds=2)
    check('declared-target-but-old-face-fails', r['passed'], False)
    check('declared-target-but-old-face-named', r['reason'],
          'accepted_face_not_target')
    check('declared-target-but-old-face-zero-extra-actions', r['clicks'], 0)

    # ---- 6. ticket_verdict 直测（生产函数）----
    base6 = {'token': 201, 'epoch': 9, 'last': 3, 'max_ticket': 3, 'readable': True}
    snap = snapshot_of(switched_ok)
    verdict, _ = NS['ticket_verdict'](snap['tickets'][0], 'preview', base6, snap)
    check('accepted-target-face-verdict', verdict, 'this_action_submitted')
    # reason(x) 映射：x=0 rollback / x=1 present 失败 / x=2 取消 / 缺失未证实
    for reason_val, want in ((0, 'rollback_rejected'), (1, 'present_failed'),
                             (2, 'cancelled'), (None, 'reason_unknown')):
        line = state_line('preview', 'preview', last=4,
                          ticket_tail=ticket_tail(4, decision=3, reason=reason_val))
        s = snapshot_of(line)
        v, _ = NS['ticket_verdict'](s['tickets'][0], 'preview', base6, s)
        check(f'reason-{reason_val}-maps-{want}', v, want)
    # 同 token epoch 倒退 ⇒ 独立具名（不再吞进 stale_token）
    rewound = state_line('preview', 'preview', token=201, epoch=2, last=1,
                         ticket_tail=ticket_tail(1))
    s = snapshot_of(rewound)
    v, _ = NS['ticket_verdict'](s['tickets'][0], 'preview',
                                {'token': 201, 'epoch': 5, 'last': 3,
                                 'max_ticket': 3, 'readable': True}, s)
    check('same-token-epoch-rewind-named', v, 'stale_epoch')
    # 历史 ACCEPTED 冒充本次（票号 ≤ 基线）
    stale = state_line('preview', 'preview', last=3, ticket_tail=ticket_tail(3))
    s = snapshot_of(stale)
    v, _ = NS['ticket_verdict'](s['tickets'][0], 'preview',
                                {'token': 201, 'epoch': 9, 'last': 4,
                                 'max_ticket': 4, 'readable': True}, s)
    check('history-ticket-cannot-impersonate', v, 'not_after_baseline')

    # ---- 7. 多面前缀并存 ⇒ 具名歧义，不取第一个 ----
    multi = state_line('preview', 'preview', last=4, faces=2,
                       extra_faces=['pharos-editor-body'],
                       ticket_tail=ticket_tail(4))
    r = run_reach([base_src, base_src, base_src, multi, multi], target='preview')
    check('multi-face-ambiguous', r['passed'], False)
    check('multi-face-named', r['reason'] in ('driver_face_ambiguous',
                                              'other_face_submitted'), True)

    # ---- 8. 读回全缺 ⇒ 具名，不回落历史 ----
    absent = 'MODE=preview'
    r = run_reach([absent, absent, absent], target='preview')
    check('readback-absent-fails', r['passed'], False)
    check('readback-absent-named',
          r['reason'] in ('readback_unavailable', 'no_ticket_after_baseline',
                          'driver_face_unobserved'), True)
    check('readback-absent-zero-extra-actions', r['clicks'], 0)

    # ---- 9. 变异负控：撤掉任一守卫，对应反例必须翻绿（证明判别力） ----
    src = SOURCE.read_text(encoding='utf-8')
    # 9a. 同时撤掉 judge 与 ticket_verdict 的 token 相等守卫（round10 旧状：判据
    #     里根本不看 token）→ 异 token 冒充得逞。（只撤 judge 一层时 ticket_verdict
    #     仍独立拦截——生产因此是双层守卫。）
    guard = ("        if (baseline.get('token') is not None and snap.get('token') is not None\n"
             "                and snap['token'] != baseline['token']):\n"
             "            return False, 'stale_token', facts, snap")
    assert guard in src
    verdict_guard = ("    if (baseline.get('token') is not None and snap.get('token') is not None\n"
                     "            and snap['token'] != baseline['token']):\n"
                     "        return 'stale_token', facts")
    assert verdict_guard in src
    ns_a = load(src.replace(guard, '', 1).replace(verdict_guard, '', 1))
    r = run_reach([base_src, base_src, base_src, unrelated, unrelated],
                  target='preview', ns=ns_a)
    check('mutant-no-token-guard-passes-unrelated', r['passed'], True)
    # 9b. 撤掉 already_at_target 的目标面核对 → 旧面冒充无动作确认。
    face_guard = ("            if baseline.get('mode') == target and baseline.get('readable'):\n"
                  "                if face != target:\n"
                  "                    return False, 'accepted_face_not_target', facts, snap\n"
                  "                return True, 'already_at_target', facts, snap")
    assert face_guard in src
    ns_b = load(src.replace(
        face_guard,
        "            if baseline.get('mode') == target and baseline.get('readable'):\n"
        "                return True, 'already_at_target', facts, snap", 1))
    r = run_reach([declared_wrong_face], target='preview', rounds=2, ns=ns_b)
    check('mutant-no-face-guard-passes-old-face', r['passed'], True)
    # 9c. 撤掉「模式已到目标不反向切换」 → 旧面场景出现一次动作。
    toggle_guard = ("    if baseline.get('mode') != target:\n"
                    "        # round11-D4：按钮定位走**读回几何**")
    assert toggle_guard in src
    ns_c = load(src.replace(
        toggle_guard,
        "    if True:\n        # round11-D4：按钮定位走**读回几何**", 1))
    r = run_reach([declared_wrong_face], target='preview', rounds=1, ns=ns_c)
    check('mutant-reverse-toggle-clicks', r['clicks'], 1)

    print()
    if failures:
        print(f'FAILURES: {len(failures)} -> {failures}')
        sys.exit(1)
    print('round10/11 D3 单份快照判据: OK（真实 reach_mode，全部符合预期）')


if __name__ == '__main__':
    main()

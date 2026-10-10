#!/usr/bin/env python3
"""round7-B 回归：`decide_t2_ordering` 的**真实阶段边界**判据（离线，无设备）。

判据唯一：`enter(T1) < enqueue(T2) < exit(T1) <= claim(T2)`，四个序号取自同一个
进程内单调原子计数器（`cjgui_ohos_observation_seq`）。hilog 行序与毫秒时间戳都
**不**参与判定：跨线程（owner 的 waitFor 与连接 worker 的入队之间无共享锁）行序
是 hilogd 的接收序，可以与真实先后相反。

round6 的两个推断分支已删除，本文件不再有「首条 terminal 即 T1」这类反例，
取而代之的是四个真实边界的方向反例：

  * T2 在 T1 进入等待**之前**入队；
  * T2 在 T1 等待**返回之后**入队；
  * T2 在 T1 返回**之前**就完成认领分发；
  * 缺 enter / 缺 exit / 缺 enqueue / 缺 claim 任一真实边界行；
  * enqueue 或 claim 的 op 不是写操作（读请求冒充）。

业务终态判据全部保留（唯一 APPLIED true 回包且逐字相等、VERSION_BEFORE 等于
入队前 owner 版本、读回版本一致、版本恰 +1、完整 `58 + before` 字节）。

正控：四个边界齐备且方向正确 + 唯一回包 → pass=True。
"""
import ast
import re  # noqa: E402
import types
from pathlib import Path

HERE = Path(__file__).resolve().parent
SCRIPT = HERE / 'verify_r1_pre_permission_replay.py'

NAMES = ('wait_enter_seq', 'wait_exit_seq', 'enqueue_seq', 'claim_seq',
         'open_wait_tickets', 'decide_t2_ordering')
_tree = ast.parse(SCRIPT.read_text())
_nodes = [n for n in _tree.body if isinstance(n, ast.FunctionDef) and n.name in NAMES]
assert {n.name for n in _nodes} == set(NAMES), sorted(n.name for n in _nodes)
ns = {'re': re}
exec(compile(ast.Module(body=_nodes, type_ignores=[]), str(SCRIPT), 'exec'), ns)
decide = ns['decide_t2_ordering']
open_wait = ns['open_wait_tickets']

# 真实形状的边界行。序号：enter(T1)=100，enqueue(T2)=150，exit(T1)=200，claim(T2)=210。
ROWS = [
    "hilog x: present wait enter session=1 ticket=40 seq=100",
    "hilog x: transport-cost stage=enqueue instance=i requestId=41 op=REPLACE_RANGE seq=150 bytes=120",
    "hilog x: present wait exit session=1 ticket=40 status=7 seq=200",
    "hilog x: transport-cost stage=owner-claim instance=i requestId=41 op=REPLACE_RANGE queueUs=10 seq=210",
    "hilog x: present terminal session=1 ticket=40 status=7 phase=4",
]
RESP = ("PROTOCOL CJGUI_SHARED_OPERATION/2\nKIND RESULT\nAPPLIED true\nCONFLICT false\n"
        "VERSION_BEFORE 11\nVERSION_AFTER 12\nREASON applied\nEND")


def archive(entries):
    return [types.SimpleNamespace(**e) if isinstance(e, dict) else e for e in entries]


def run(rows=ROWS, t1=40, archive_tail=None, resp=RESP,
        owner_before=(11, '61' * 11), owner_after=(12, '58' + '61' * 11)):
    tail = archive([{"t": 1.0, "dir": "request", "raw": "INVOKE 11 REPLACE_RANGE 1 4"},
                    {"t": 2.0, "dir": "response", "raw": RESP}]) if archive_tail is None else archive_tail
    return decide(t1, 41, rows, tail, resp, owner_before, owner_after)


def expect_fail(name, result, want_prefix):
    ok, reason, facts = result
    assert not ok and reason.startswith(want_prefix), (name, reason, facts)
    return facts


# ---- 正控：四个真实边界齐备且方向正确。 ----
ok, reason, facts = run()
assert ok, ('positive control', reason, facts)
assert (facts['t1_enter_seq'], facts['t2_enqueue_seq'], facts['t1_exit_seq'],
        facts['t2_claim_seq']) == (100, 150, 200, 210), facts

# ---- T1 配对：入队那一刻仍在等待的票。 ----
assert open_wait(ROWS, 150) == {40}, open_wait(ROWS, 150)
# 入队发生在 T1 进入等待之前 ⇒ 那张票此刻还没开窗，配对集合为空。
assert open_wait(ROWS, 50) == set(), open_wait(ROWS, 50)
# 入队发生在 T1 已返回之后 ⇒ 同样为空。
assert open_wait(ROWS, 250) == set(), open_wait(ROWS, 250)
# 两张票同时在等 ⇒ 歧义，集合有两个元素（调用方必须拒绝而不是挑一个）。
AMBIGUOUS = ROWS + [
    "hilog x: present wait enter session=1 ticket=41 seq=120",
    "hilog x: present wait exit session=1 ticket=41 status=7 seq=190",
]
assert open_wait(AMBIGUOUS, 150) == {40, 41}, open_wait(AMBIGUOUS, 150)


# ---- 方向反例：入队在 T1 进入等待之前。 ----
BEFORE_ENTER = [
    "hilog x: transport-cost stage=enqueue instance=i requestId=41 op=REPLACE_RANGE seq=90 bytes=120",
    "hilog x: present wait enter session=1 ticket=40 seq=100",
    "hilog x: present wait exit session=1 ticket=40 status=7 seq=200",
    "hilog x: transport-cost stage=owner-claim instance=i requestId=41 op=REPLACE_RANGE queueUs=10 seq=210",
]
expect_fail('enqueue-before-enter', run(BEFORE_ENTER), 't2_not_enqueued_inside_t1_wait_window')

# ---- 方向反例：入队在 T1 等待返回之后。 ----
AFTER_EXIT = [
    "hilog x: present wait enter session=1 ticket=40 seq=100",
    "hilog x: present wait exit session=1 ticket=40 status=7 seq=120",
    "hilog x: transport-cost stage=enqueue instance=i requestId=41 op=REPLACE_RANGE seq=150 bytes=120",
    "hilog x: transport-cost stage=owner-claim instance=i requestId=41 op=REPLACE_RANGE queueUs=10 seq=210",
]
expect_fail('enqueue-after-exit', run(AFTER_EXIT), 't2_enqueued_after_t1_wait_return')

# ---- 方向反例：T2 在 T1 返回之前就完成认领分发。 ----
CLAIM_FIRST = [
    "hilog x: present wait enter session=1 ticket=40 seq=100",
    "hilog x: transport-cost stage=enqueue instance=i requestId=41 op=REPLACE_RANGE seq=110 bytes=120",
    "hilog x: transport-cost stage=owner-claim instance=i requestId=41 op=REPLACE_RANGE queueUs=10 seq=120",
    "hilog x: present wait exit session=1 ticket=40 status=7 seq=200",
]
expect_fail('claim-before-exit', run(CLAIM_FIRST), 't2_dispatched_before_t1_wait_return')

# ---- 缺真实边界：任一行不在流里都必须具名未验，不得退回推断。 ----
for name, rows, prefix in [
    ('no-enter', [r for r in ROWS if 'wait enter' not in r], 't1_wait_enter_boundary_row_missing'),
    ('no-exit', [r for r in ROWS if 'wait exit' not in r], 't1_wait_exit_boundary_row_missing'),
    ('no-enqueue', [r for r in ROWS if 'stage=enqueue' not in r], 't2_enqueue_boundary_row_missing'),
    ('no-claim', [r for r in ROWS if 'stage=owner-claim' not in r], 't2_dispatch_claim_row_missing'),
]:
    expect_fail(name, run(rows), prefix)

# 只有 terminal 行、连 enqueue 都没有 ⇒ 第一个缺失的真实边界就具名（不再是
# 「首条 terminal 即 T1」那种推断通过）。
TERMINAL_ONLY = [
    "hilog x: present terminal session=1 ticket=40 status=7 phase=4",
    "hilog x: transport-cost stage=owner-claim instance=i requestId=41 op=REPLACE_RANGE queueUs=10 seq=210",
]
expect_fail('terminal-only', run(TERMINAL_ONLY), 't2_enqueue_boundary_row_missing')

# ---- 读请求冒充写：enqueue 与 claim 两侧都要核 op。 ----
READ_ENQUEUE = [r.replace("op=REPLACE_RANGE", "op=GET_CONTEXT_0") if "stage=enqueue" in r else r
                for r in ROWS]
expect_fail('read-enqueue', run(READ_ENQUEUE), 't2_enqueue_not_write_operation')
READ_CLAIM = [r.replace("op=REPLACE_RANGE", "op=OTHER") if "stage=owner-claim" in r else r
              for r in ROWS]
expect_fail('read-claim', run(READ_CLAIM), 't2_claim_not_write_operation')

# ---- 业务终态判据全部保留。 ----
expect_fail('zero-applied', run(archive_tail=archive([
    {"t": 1.0, "dir": "response", "raw": "CjguiApp: PHAROS_OHOS_EDIT count=9 applied=true v=12"},
])), 't2_business_terminal_not_unique:0')

expect_fail('two-applied', run(archive_tail=archive([
    {"t": 1.0, "dir": "response", "raw": RESP},
    {"t": 1.5, "dir": "response", "raw": RESP.replace('VERSION_AFTER 12', 'VERSION_AFTER 13')},
])), 't2_business_terminal_not_unique:2')

expect_fail('foreign-response', run(archive_tail=archive([
    {"t": 1.0, "dir": "response", "raw": RESP.replace('REASON applied', 'REASON other')},
])), 't2_business_terminal_response_mismatch')

expect_fail('baseline-mismatch', run(owner_before=(10, '61' * 10)),
            't2_business_terminal_baseline_mismatch')
expect_fail('owner-version', run(owner_after=(13, '58' + '61' * 11)),
            't2_business_terminal_owner_version_mismatch')
expect_fail('bytes-wrong', run(owner_after=(12, '61' * 11 + '5858')),
            't2_full_owner_bytes_mismatch')
# 版本不恰 +1：VERSION_AFTER=12 而读回 14（读回与响应不符先命中，符合判据次序）。
expect_fail('version-mismatch', run(owner_after=(14, '58' + '61' * 11 + '58')),
            't2_business_terminal_owner_version_mismatch')

print('t2 phase-boundary offline negatives: OK (18 cases)')

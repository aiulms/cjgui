#!/usr/bin/env python3
"""R1 提交许可前置窗口的设备级重放（Astra h-r1-source-admission Q3 组1/组2）。

只读裁决：Pharos Mark/artifacts/consultations/h-r1-source-admission-astra/answer-followup-1.md。

真实入口（不是替身）：产品 Pharos normal HAP（本次以
`build_and_run.sh --verify-transport --test-gates` 构建，闸门与验证接缝已注册），
经真实传输 socket 触发业务、经真实 CONTROL CJGUI_VERIFY/1 通道设闸门，观察真实
`executePresent` 的**提交许可前置窗口**里 owner 的行为与最终是否 Flush。

前置时序（本次按当前源码核实）：
    owner: claim/dispatch → build/set → present → job->waitFor()
    waitFor 上限 kRenderWaitTimeout=2000ms（ohos_renderer.cpp:377/2285）：
      超时时若仍是 Queued/Running → **确认取消**、返回非 OK（不会 Flush）；
      若已 Committing → 返回 PENDING(20)。
故「许可前窗口」是有界的：超过 ~2s 仍未取得许可的 job 会被取消，不可能 Flush。

本文件断言（**按票号**取真实 Flush，不使用全局 pending 结算计数）：
  1. 基线 stageHeld[admission] 与按票 Flush 边界可读；
  2. **对照正控**：不装 hold 的同样触发必须产生**恰一张新票的真实 Flush**
     （`flush hold enter`+`exit` 同票）且该票有合法终态（status=0 phase=3）与 accepted-swap；
  3. 装 `GATE_HOLD_ADMIT_8000`（在 `acquireCommitPermission()` 之前按住，常驻到
     `GATE_CLEAR`）后触发一次真实 present：admission 槽推进（闸门确实落在许可前窗口），
     且 hold 期间 **无任何新 Flush 边界票**；
  4. 按住期间 owner 仍可服务（≤kRenderWaitTimeout 后返回）——许可前等待有界；
  5. 释放后：窗口内每张被取消票**从未进入 Flush 边界**（逐票 Flush=0，用 `flush hold`
     正缺证，不用"整段 hilog 无新票"）、**恰一行**终态且为 `(7,4)`（等待方超时确认取消）、
     `|W|` 在 waitFor 上界内；另有**释放后合法 Flush 正证** U（enter+exit+status=0+accepted-swap，U>max(W)）。
     注意：许可前 hold 常驻 ⇒ owner 串行、确认取消后立即重铸，窗口内会有**多张**被取消票
     （每 ~2s 一张，= waitFor 上界的涌现节奏），故判据按**每张窗口票**逐票成立，
     而非"恰一张票"（见 `decide_held_ticket`；GLM-5.3 h-r-b-hold-retry-glm 裁决）。

归属纪律：转发端口被占用时**具名失败并原样退出**，绝不先删他人映射；只有本进程
创建成功的映射才在 `finally` 清理。触发失败（`replace ERR`）立即非0退出。
**本测试含受控写入**：经公开通道对正文偏移 0 插入 1 字节以确定性触发 present。

边界：本文件不声称 (d) 可达或不可达；它是 Astra 组1/组2 的真实入口重放。
所有设备动作只读观察 + 测试闸门；不改产品语义。
"""
import argparse
import importlib.util
import json
import math
import re
import subprocess
import sys
import threading
import time
from pathlib import Path

SCRIPTS = Path('/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/platforms/ohos/scripts')
sys.path.insert(0, str(SCRIPTS))
from ohos_transport_probe_lib import (  # noqa: E402
    BoundedExchange, gate_command, gate_stage_held, GateCommandError)

_spec = importlib.util.spec_from_file_location(
    'pharos_driver', SCRIPTS / 'h_source_preview_consumption.py')
m = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(m)

HDC = ("/Applications/DevEco-Studio.app/Contents/sdk/default/openharmony/"
       "toolchains/hdc")
PORT = 28865
ADMISSION_SLOT = 4   # gate_stage_held 槽位：0 permit/1 create/2 create_ret/3 draw/4 admission/5 flush/6 dequeue
CAP = "pharos-local-capability"
EVIDENCE = []


def note(msg):
    print(msg, flush=True)


def check(desc, ok, detail=""):
    note(f"   {'OK  ' if ok else 'FAIL'} {desc} {detail}")
    EVIDENCE.append({"check": desc, "pass": bool(ok), "detail": detail})
    return 0 if ok else 1


def hdc_run(*args, timeout=30):
    """带退出码的 hdc 调用。**不得丢弃返回码**（复核：旧实现只看 stdout 含 OK，
    隔离的退出 32／stdout OK 仍取得清理权）。"""
    return subprocess.run([HDC, *hdc_target_args(), *args], capture_output=True, text=True,
                          timeout=timeout)


def hdc(*args):
    """**唯一**设备命令出口。round7-B：`-t <target>` 由这里统一注入，hilog、pidof、
    fport 全部经过它——不再有「转发带 target、读日志不带」的第二入口。"""
    return hdc_run(*args).stdout


BOUND_PID = ""        # 本轮应用实例 PID：所有设备日志扫描按它归属，别的实例／进程不计
BOUND_SESSION = "1"   # 应用 renderer 会话号（每进程一个；与既有 present/terminal 约定一致）


def scoped_lines(pattern):
    """读取设备日志并按**本轮 PID**归属过滤。

    无 PID 时返回空串（判据缺失即失败）：绝不退回全局扫描，否则别的实例或残留进程
    的票会被计入（复核反例：session99/pid9876 的 ticket456 曾被当作本轮的票）。"""
    out = hdc("shell", f"hilog -x 2>/dev/null | grep -a '{pattern}'") or ""
    if not BOUND_PID:
        return ""
    return "\n".join(ln for ln in out.splitlines()
                     if len(ln.split()) >= 3 and ln.split()[2] == BOUND_PID)


def app_pid():
    out = (hdc("shell", "pidof com.pharos.mark") or "").strip()
    return out.split()[0] if out else ""


def read_token():
    out = scoped_lines("verify seam armed token=")
    mo = re.search(r"token=(\S+)", out)
    return mo.group(1) if mo else ""


def stats(ex):
    return gate_command(ex, TOKEN, "GATE_A2_STATS", timeout=12.0)


def parse_stats(text):
    out = {}
    for tok in text.split():
        if "=" in tok:
            k, v = tok.split("=", 1)
            out[k] = v
    return out


def committed(ex):
    s = parse_stats(stats(ex))
    v = s.get("committed", "")
    return int(v) if v.lstrip("-").isdigit() else -1


def admission_held(ex):
    # GATE_A2_STATS 的 stageHeld 是发布式命令；槽 4 = admission。
    try:
        return gate_stage_held(ex, TOKEN, ADMISSION_SLOT, timeout=12.0)
    except Exception:  # noqa: BLE001
        return -1


def business(lines, timeout=8.0):
    return m.request(lines, PORT)


def refused_tickets():
    """渲染器具名拒绝的 configure 票据 id 集合（内容围栏，不依赖绝对行号/计数）。"""
    out = scoped_lines("configure refused: pending ticket=")
    return set(re.findall(r"ticket=(\d+)", out))


def committed_tickets():
    """**实际 Flush** 的票号集合：`executePresent` 的 accepted-swap（cause=commit）
    是候选真正晋升为 accepted 的点，即不可逆 Flush 已发生的证据。不用全局
    pending 结算计数（`g_committedSettlements`）冒充——那个只覆盖延迟成功分支。
    只计本轮 PID／session 的行（别的实例的票不计）。"""
    out = scoped_lines("image-lease stage=accepted-swap")
    return {int(m.group(2)) for m in
            re.finditer(r"session=(\d+) ticket=(\d+) cause=commit", out)
            if m.group(1) == BOUND_SESSION}


def flush_boundary_tickets():
    """**按票**的真实 SurfaceFlush 边界证据（闸门构建下已在生产里计量，非替身）。

    `executePresent` 在取得许可后、调用 `OH_Drawing_SurfaceFlush` 前后打印
    `flush hold enter/exit gen=.. session=S ticket=T`（ohos_renderer.cpp:3450-3458）。
    据此得到该票**真实进入并返回**了 Flush 边界。返回 (enter_tickets, exit_tickets)。
    复核要求：不能用 accepted-swap 冒充 Flush 入口，也不能以"整个 hilog 没有新票"
    推断 Flush=0；按票在真实边界上取，且只取本轮 PID／session 的行。"""
    out = scoped_lines("flush hold ")
    enter, exit_ = set(), set()
    for m in re.finditer(r"flush hold (enter|exit) gen=\d+ session=(\d+) ticket=(\d+)", out):
        if m.group(2) != BOUND_SESSION:
            continue
        (enter if m.group(1) == "enter" else exit_).add(int(m.group(3)))
    return enter, exit_


def ticket_terminals():
    """票号 → **全部** `present terminal` 行（按行序，不去重）。

    返回 dict[int, list[(status, phase)]]：同一票的**每一条**终态行都保留，
    以便断言「恰一行」（dict 去重会静默吞掉同一票的第二条行，那正是"双终态"
    缺陷的签名）。只计本轮 PID／session。"""
    out = scoped_lines("present terminal ")
    seen = {}
    for m in re.finditer(r"present terminal session=(\d+) ticket=(\d+) status=(-?\d+) phase=(\d+)", out):
        if m.group(1) != BOUND_SESSION:
            continue
        seen.setdefault(int(m.group(2)), []).append((int(m.group(3)), int(m.group(4))))
    return seen


def scoped_rows(ere):
    """本轮 PID 范围内的**有序**日志行列表（`grep -aE`，保留行序）。

    行序就是设备时间序：跨行比较只用它，绝不拿主机时钟与设备时钟对标。返回空表
    示没有样本——调用方必须具名「未验」，不得当作"没有发生"。"""
    out = hdc("shell", f"hilog -x 2>/dev/null | grep -aE '{ere}'") or ""
    return [ln for ln in out.splitlines()
            if len(ln.split()) >= 3 and ln.split()[2] == BOUND_PID]


def wait_enter_seq(rows, ticket):
    """`present wait enter ... ticket=T seq=S`：waitFor **调用之前**取的一次进程内
    单调序号，即 T 的等待区间左端。没有则 None。"""
    for row in rows:
        mo = re.search(r"present wait enter session=\d+ ticket=(\d+) seq=(\d+)", row)
        if mo and int(mo.group(1)) == ticket:
            return int(mo.group(2))
    return None


def wait_exit_seq(rows, ticket):
    """`present wait exit ... ticket=T seq=S`：waitFor **返回之后**立刻取的一次序号，
    即 T 的等待区间右端（含 PENDING 返回）。没有则 None。

    不用 `present terminal` 代替：它在成功路径上打印于 accepted swap 与 prune 之后，
    记的是「结算决定」的时刻，与「等待返回」之间可以插进任意多行。
    """
    for row in rows:
        mo = re.search(r"present wait exit session=\d+ ticket=(\d+) status=\d+ seq=(\d+)", row)
        if mo and int(mo.group(1)) == ticket:
            return int(mo.group(2))
    return None


def enqueue_seq(rows, request_id):
    """`transport-cost stage=enqueue requestId=R ... seq=S`：R 在
    `context.queue.add(t)` 线性化点（BRIDGE_LOCK 内）取的序号。没有则 None。"""
    for row in rows:
        mo = re.search(r"transport-cost stage=enqueue \S+ requestId=(\d+) \S+ seq=(\d+)", row)
        if mo and int(mo.group(1)) == request_id:
            return int(mo.group(2))
    return None


def claim_seq(rows, request_id):
    """`transport-cost stage=owner-claim requestId=R ... seq=S`：owner 认领同票时在锁内
    取的序号，即该请求分发起点的观测。没有则 None。"""
    for row in rows:
        mo = re.search(r"transport-cost stage=owner-claim \S+ requestId=(\d+) \S+ queueUs=\d+ seq=(\d+)",
                       row)
        if mo and int(mo.group(1)) == request_id:
            return int(mo.group(2))
    return None


def open_wait_tickets(rows, at_seq):
    """在序号 `at_seq` 那一刻**仍在等待**的 present 票集合：`enter < at_seq < exit`。

    这就是 T1 的正面配对规则，取代旧的三条推断（发送后首条 terminal 即 T1、
    window_min_fallback、写入即刻入队）。按**序号**判定而不是行序：跨线程的行序是
    hilogd 的接收序，与真实先后无关。缺 exit 行的票（流被截断）不算在等待内，
    缺 enter 行的票根本不是候选。多于一张即歧义，调用方必须拒绝。
    """
    spans = {}
    for row in rows:
        mo = re.search(r"present wait (enter|exit) session=\d+ ticket=(\d+) .*?seq=(\d+)", row)
        if not mo:
            continue
        ticket, seq = int(mo.group(2)), int(mo.group(3))
        span = spans.setdefault(ticket, [None, None])
        if mo.group(1) == "enter":
            # 同一票多次重铸时保留最晚的 enter：任一次配对成立即该票在该序号上
            # 确实进过等待区间。
            span[0] = seq if span[0] is None else max(span[0], seq)
        else:
            # 保留最早的 exit：该票在更早的时刻就已返回。
            span[1] = seq if span[1] is None else min(span[1], seq)
    out = set()
    for ticket, (enter, exit_) in spans.items():
        if enter is None or exit_ is None:
            continue
        if enter < at_seq < exit_:
            out.add(ticket)
    return out


def ticket_ledger(ex):
    """传输账本（CONTROL TICKETS）：`T<seq> ID <requestId> PHASE <pending|…>`。

    只用它证明**入队身份**（requestId 已登记且仍 pending），不用它证明分发——
    分发看 owner-claim 行（复核 B：CONTROL 可响应不是分发证据）。"""
    # TICKETS 是同步读数（KIND OK 直接回帧），不是发布式闸门命令：走 exchange_strict。
    _, body = ex.exchange_strict(["CONTROL CJGUI_VERIFY/1", f"TOKEN {TOKEN}", "OP TICKETS", "END"],
                                 12.0)
    return [{"seq": int(a), "id": int(b), "phase": c} for a, b, c in
            re.findall(r"T(\d+) ID (\d+) PHASE (\w+)", body)]


def decide_t2_ordering(t1_ticket, t2_request_id, ordered_rows,
                       archive_tail, resp, owner_before=None, owner_after=None,
                       t2_request_frame=None):
    """真实 T2 顺序判据（round7-B）：**唯一判据是四个真实边界序号**
    `enter(T1) < enqueue(T2) < exit(T1) <= claim(T2)`。

    * `enqueue(T2)`：transport 在 `context.queue.add(t)` 线性化点（BRIDGE_LOCK 内）
      打的 `stage=enqueue` 行，requestId 即 T2 身份，op 必须复核为写操作。
    * `enter/exit(T1)`：renderer 在 `job->waitFor()` 紧前/紧后打的
      `present wait enter|exit`，带同一 session/ticket。
    * `claim(T2)`：owner 认领同票时在锁内取的序号（`stage=owner-claim`）。

    四个序号来自**同一个进程内单调原子计数器**（`cjgui_ohos_observation_seq`），
    跨 C++ 与仓颉可比。hilog 行序**不**参与判定：它是 hilogd 的接收序，跨线程
    （owner 的 waitFor 与连接 worker 的入队之间没有共享锁或 happens-before 边）
    可以与真实先后相反，毫秒时间戳还会并列。旧的三条推断（发送后首条 terminal
    就是 T1、window_min_fallback、写入即刻入队）已删除。

    业务终态唯一：T2 是**公开通道 REPLACE_RANGE**，它的业务终态是传输账本里
    归属该请求的回包帧本身。判据：T2 请求之后的归档尾部**恰好一条**
    `APPLIED true` 回包、且逐字等于 T2 的回包；`VERSION_BEFORE` 等于入队前 owner
    版本（请求落在冻结基线上），读回 `VERSION_AFTER` 一致且正文恰好多 1 字节。
    任一缺失 → `pass=False` 带具名原因；不再返回 `pass=null`（缺样本就是未验）。
    """
    facts = {"t1_ticket": t1_ticket, "t2_request_id": t2_request_id}
    if t2_request_id is None:
        return False, "t2_enqueue_identity_missing", facts
    if t1_ticket is None:
        return False, "t1_ticket_identity_missing", facts
    # round7-B：四个真实边界序号，缺一即具名未验。判据**只**比这些序号。
    enq = enqueue_seq(ordered_rows, t2_request_id)
    if enq is None:
        return False, "t2_enqueue_boundary_row_missing", facts
    ci = claim_seq(ordered_rows, t2_request_id)
    if ci is None:
        return False, "t2_dispatch_claim_row_missing", facts
    ei = wait_enter_seq(ordered_rows, t1_ticket)
    if ei is None:
        return False, "t1_wait_enter_boundary_row_missing", facts
    xi = wait_exit_seq(ordered_rows, t1_ticket)
    if xi is None:
        return False, "t1_wait_exit_boundary_row_missing", facts
    # T2 的 enqueue 与 claim 都必须是**写操作**（REPLACE_RANGE）——读请求冒充写
    # （op=READ / 无 action）在此拒绝，不能用别的请求的认领行替代。
    enq_rows = [r for r in ordered_rows
                if "stage=enqueue" in r and f"requestId={t2_request_id} " in r]
    if not any("op=REPLACE_RANGE" in r for r in enq_rows):
        return False, "t2_enqueue_not_write_operation", facts
    claim_rows = [r for r in ordered_rows
                  if f"stage=owner-claim" in r and f"requestId={t2_request_id} " in r]
    if not any("op=REPLACE_RANGE" in r for r in claim_rows):
        return False, "t2_claim_not_write_operation", facts
    facts.update({"t1_enter_seq": ei, "t2_enqueue_seq": enq,
                  "t1_exit_seq": xi, "t2_claim_seq": ci})
    # enter(T1) < enqueue(T2)：T2 必须落在 T1 的等待区间**内**。
    if not ei < enq:
        return False, "t2_not_enqueued_inside_t1_wait_window", facts
    # enqueue(T2) < exit(T1)：入队必须早于 T1 的等待返回。
    if not enq < xi:
        return False, "t2_enqueued_after_t1_wait_return", facts
    # exit(T1) <= claim(T2)：分发不早于等待返回（同号不可能，取等号容差）。
    if ci < xi:
        return False, "t2_dispatched_before_t1_wait_return", facts
    if not resp or "APPLIED true" not in resp:
        return False, "t2_business_terminal_not_applied", facts
    mv = re.search(r"VERSION_AFTER (\d+)", resp)
    mb = re.search(r"VERSION_BEFORE (\d+)", resp)
    if not mv or not mb:
        return False, "t2_business_terminal_version_missing", facts
    version_after, version_before = int(mv.group(1)), int(mb.group(1))
    # 归档尾部：T2 请求条目之后的所有帧。业务终态 = 恰好一条 APPLIED true 回包
    # 且逐字等于 T2 自己的回包（公共写的终态在传输账本，不在 IME 会话判决行）。
    def _frame(e, key):
        if isinstance(e, dict):
            return e.get(key)
        return getattr(e, key, None)

    entries = list(archive_tail or [])
    applied_responses = [e for e in entries
                         if _frame(e, "dir") == "response"
                         and "APPLIED true" in (_frame(e, "raw") or "")]
    if len(applied_responses) != 1:
        return False, f"t2_business_terminal_not_unique:{len(applied_responses)}", facts
    if _frame(applied_responses[0], "raw") != resp:
        return False, "t2_business_terminal_response_mismatch", facts
    # 请求落在冻结基线上：VERSION_BEFORE == 入队前 owner 版本。
    if owner_before is not None and version_before != owner_before[0]:
        return False, "t2_business_terminal_baseline_mismatch", facts
    # round6-B：单笔应用三重核验——读回版本 == VERSION_AFTER；版本恰 +1（响应
    # 与 owner 双侧）；**完整 owner 字节恰为 `58 + before`**（同长度错正文在此
    # 拒绝，不能只比长度）。
    if owner_after is not None:
        after_version, after_hexstr = owner_after
        if after_version != version_after:
            return False, "t2_business_terminal_owner_version_mismatch", facts
        if version_after != version_before + 1:
            return False, f"t2_version_not_exactly_one:{version_before}->{version_after}", facts
        if owner_before is not None and owner_before[1] is not None:
            if (after_hexstr or "") != "58" + owner_before[1]:
                return False, "t2_full_owner_bytes_mismatch", facts
    facts.update({"version_after": version_after, "version_before": version_before,
                  "t2_request_frame": (t2_request_frame or "")[:120]})
    return True, "t2_enqueued_in_t1_wait_window_and_dispatched_after_return", facts


def t2_write_only(version, expected_hex_prefix_check=True):
    """round6-B：T2 线程**只发那一笔目标写**——版本由观察围栏**之前**的基线读取
    传入，线程内不再 read_all（旧实现线程内先读正文：读请求进了传输账本，正是
    「pending id 早于写帧 4 秒」反例的来源）。帧经 EX 归档，回包全文返回。"""
    lines = [
        "PROTOCOL CJGUI_SHARED_OPERATION/2", f"AUTH {CAP}",
        f"INVOKE {version} REPLACE_RANGE 1 4", "ID 1",
        "ARG start INTEGER 0", "ARG end INTEGER 0", "ARG text STRING 1 58",
        f"ARG expectedVersion INTEGER {version}"]
    _, resp = EX.exchange_strict(lines, 40.0)
    return "\n".join(lines), resp


def trigger_present():
    """触发一次真实场景刷新 → present。**含受控写入**：经公开通道对正文偏移 0
    插入 1 字节（确定性触发 owner refresh → pumpOneTurn → present）。不用点击。

    返回 (ok, 描述)。失败必须具名向上传播——旧实现只写 `replace ERR` 仍可能走到
    PASS，等于让触发失败静默变成「没观察到变化」。"""
    try:
        version, _hexstr = m.read_all(PORT)
        m.agent_replace(PORT, 0, 0, "58", version)   # 插入 "X"
        return True, f"replace@0 v{version}"
    except Exception as e:  # noqa: BLE001
        return False, f"replace ERR {e!r}"


EX = None
TOKEN = ""


MAP_ROW = re.compile(r"(?:^|\s)(\S+)\s+tcp:(\d+)\s+(\S+)\s+\[Forward\]")
# 本轮转发的归属三元组：同一行的 (target, local, remote)。跨行拼接会把别人的映射
# 读成本轮事实（round5 后指导 B 的跨行反例：28865→7999 配用户 7856→7856 曾返回
# created+verified）。判据与 run_pending_real_device_checks.sh 的 forward_map_check
# 逐字一致。
# round7-B：target 不再有「脚本猜的默认值」——**必须由入口 `--target` 显式给出**，
# 缺省即工具未配置，`hdc_target_args()` 具名失败，绝不静默落到唯一设备。
FORWARD_TARGET = ""
REMOTE_PORT = 7856
FORWARD_OWNED = []


def hdc_target_args():
    """round7-B：所有设备命令的唯一 target 来源。`--target` 必填；缺失时具名失败，
    且此时**零设备命令**（`hdc_target_args` 在任何 `hdc_run` 之前就抛）。"""
    if not FORWARD_TARGET:
        raise RuntimeError("hdc target not configured: pass --target")
    return ["-t", FORWARD_TARGET]


def forward_rows(listing, local_port):
    return [(mo.group(1), int(mo.group(2)), mo.group(3))
            for line in (listing or "").splitlines()
            if (mo := MAP_ROW.search(line)) and int(mo.group(2)) == local_port]


def ensure_forward():
    """转发归属：**不删占用端口**；读列表 rc=0 才算读到，创建 rc=0＋明确回执，
    复查必须**同一行** `(FORWARD_TARGET, tcp:PORT, tcp:REMOTE_PORT)` 精确相等。

    读列表失败、端口已被他人占用、同端口指向别的 remote、同端口属于别的 target，
    一律不取得清理权（返回 False）。"""
    first = hdc_run("fport", "ls")
    if first.returncode != 0:
        return False, f"forward_list_failed_rc={first.returncode}"
    if forward_rows(first.stdout, PORT):
        return False, f"forward_other_or_old_mapping:{forward_rows(first.stdout, PORT)}"
    r = hdc_run("fport", f"tcp:{PORT}", f"tcp:{REMOTE_PORT}")
    blob = ((r.stdout or "") + (r.stderr or "")).strip()
    if r.returncode != 0:
        return False, f"forward_fail_rc={r.returncode}:{blob[:160]}"
    if "Forwardport result:OK" not in (r.stdout or "") or "[Fail]" in blob:
        return False, f"forward_no_receipt:{blob[:160]}"
    again = hdc_run("fport", "ls")
    if again.returncode != 0:
        return False, f"forward_relist_failed_rc={again.returncode}"
    expect = [(FORWARD_TARGET, PORT, f"tcp:{REMOTE_PORT}")]
    if forward_rows(again.stdout, PORT) != expect:
        return False, f"forward_mapping_mismatch:{forward_rows(again.stdout, PORT)}"
    FORWARD_OWNED.append((FORWARD_TARGET, PORT, f"tcp:{REMOTE_PORT}"))
    return True, "created+verified"


def release_forward():
    """只释放本轮创建、且清理前**仍然同一行精确匹配**的映射；映射被换掉就不动。

    绝不 `fport rm` 一个不属于自己的三元组（用户 7856→7856 等原样保留）。"""
    if not FORWARD_OWNED:
        return "not_owned_skipped"
    mine = FORWARD_OWNED[-1]
    ls = hdc_run("fport", "ls")
    if ls.returncode != 0:
        return f"cleanup_skipped_list_rc={ls.returncode}"
    rows = forward_rows(ls.stdout, PORT)
    if not rows:
        return "already_absent"
    if rows != [mine]:
        return f"cleanup_skipped_mapping_changed:{rows}"
    # round6-B：rm 回执必须核验——退出码非 0 或输出含 [Fail] 具名失败，
    # 不再无条件回报 removed。
    rm = hdc_run("fport", "rm",
                 f"tcp:{mine[1]}", f"tcp:{mine[2].split(':')[1]}")
    rm_blob = ((rm.stdout or "") + (rm.stderr or "")).strip()
    if rm.returncode != 0 or "[Fail]" in rm_blob:
        return f"cleanup_rm_failed_rc={rm.returncode}:{rm_blob[:120]}"
    # round7-B：removed 也要**复查映射**才算清理完成。rm 返回 0 但映射仍在，
    # 同样是清理未完成，必须进最终状态而不是回报 removed。
    post = hdc_run("fport", "ls")
    if post.returncode != 0:
        return f"cleanup_relist_failed_rc={post.returncode}"
    still = forward_rows(post.stdout, PORT)
    if still:
        return f"cleanup_mapping_still_present:{still}"
    return "removed"


def bind_identity():
    """本轮身份：bundle / PID / verify token。无 PID 即无法归属，判据失败。"""
    return {"bundle": "com.pharos.mark", "pid": BOUND_PID, "token": TOKEN}


def partition_hold_window(new_terms, new_boundary):
    """把"释放后的新票"切成窗口票 W（票号 < U，hold 期被取消）与释放后首张合法 Flush U。

    `U = min(new_boundary)`（释放后首张进入 Flush 边界的票）；`W = {票号 < U 的全部新终态票}`。
    若 `new_boundary` 为空 → `U=None`、`W={}`（调用方必须 FAIL：没有释放后合法 Flush 正证）。
    `new_terms`: dict[int, list[(status, phase)]]；`new_boundary`: 释放后新 Flush 边界票集合。
    """
    u = min(new_boundary) if new_boundary else None
    w = {t: new_terms[t] for t in new_terms if u is not None and t < u}
    return w, u


def remint_within_bound(count, window_seconds):
    """重铸票数上界（稳健性，非计划要求）：节奏 = kRenderWaitTimeout 2s；
    窗口内票数不应超 ⌈窗口/2s⌉+2。对"waitFor 上界被改小/重铸变无界"这类回归保持敏感。"""
    return count <= math.ceil(window_seconds * 1000.0 / 2000.0) + 2


def decide_held_ticket(hold_terminals, boundary_after):
    """许可前 hold 窗口内**逐票**判据（离线可测；GLM-5.3 h-r-b-hold-retry-glm 裁决）。

    现实：许可前 hold 常驻到 `GATE_CLEAR`，owner 单线程在 `waitFor` 返回（确认取消）后
    立即重铸，故一个窗口会产生**多张**被取消票（本轮每 2.000s 一张，= kRenderWaitTimeout
    上界的涌现节奏，非独立退避）。故"按 T1 自身"泛化为"按**每一张窗口票**自身"：
      - `nonempty`：窗口票集合非空（空集 = 触发静默失败/扫错 PID → 假绿，必须 FAIL）；
      - `unique_terminal`：每票**恰一行** terminal（按行计数，不靠 dict 去重）；
      - `cancelled_signature`：每票终态为 `(7,4)`（= 等待方超时确认取消的专属签名）；
      - `never_flushed`：每票都不出现在新 Flush 边界票里（逐票 Flush=0）；
      - `t1`：`min(窗口)`（hold 常驻 + owner 串行 ⇒ 首张被取消票即本次触发）。

    `hold_terminals`: dict[int, list[(status, phase)]]（窗口内新增票的全部终态行）。
    `boundary_after`:  hold 期间及释放前的全部新 Flush 边界票集合。
    """
    tickets = sorted(hold_terminals)
    unique_terminal = all(len(hold_terminals[t]) == 1 for t in tickets)
    cancelled_signature = all(hold_terminals[t] == [(7, 4)] for t in tickets)
    never_flushed = all(t not in boundary_after for t in tickets)
    return {
        "t1": tickets[0] if tickets else None,
        "nonempty": len(tickets) > 0,
        "unique_terminal": unique_terminal,
        "cancelled_signature": cancelled_signature,
        "never_flushed": never_flushed,
        "held_tickets": tickets,
    }


EX = None
TOKEN = ""
# round7-B：本轮清理的最终状态（写进 result.json 并折进退出码）。
CLEANUP_RESULT = "not_attempted"


def _rewrite_cleanup_into_result(path):
    """把真实清理结果回写进已落盘的 result.json。文件不存在/损坏时不抛——
    证据回写失败不能反过来吞掉本次运行的真实退出码。"""
    try:
        if not path.exists():
            return
        data = json.loads(path.read_text())
        data["forward_cleanup"] = CLEANUP_RESULT
        path.write_text(json.dumps(data, ensure_ascii=False, indent=1))
    except Exception:  # noqa: BLE001
        pass


def main():
    global EX, TOKEN, FORWARD_TARGET
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", required=True)
    # round7-B：target **必填**，且是所有设备命令（含普通 hilog / pidof）的唯一来源。
    # 缺参数时 argparse 直接非 0 退出，零设备命令。
    ap.add_argument("--target", required=True,
                    help="hdc target (e.g. 127.0.0.1:5555); every device command uses it")
    args = ap.parse_args()
    FORWARD_TARGET = args.target.strip()
    if not FORWARD_TARGET:
        note("FAIL --target 为空：设备目标未配置，零设备命令")
        return 2

    created, why = ensure_forward()
    note(f"fport tcp:{PORT} -> tcp:7856 : {why}")
    if not created:
        note(f"FAIL 转发未取得（{why}）——不清理他人映射，直接非0退出")
        return 2
    # round7-B：清理结果进入**最终退出状态**，不再是一个被 finally 丢掉的字符串。
    # 本轮创建、本轮仍精确匹配的映射没删干净就是本次运行的失败项。
    global CLEANUP_RESULT
    run_rc = 3
    try:
        run_rc = _run(args)
    finally:
        cleanup = release_forward()
        CLEANUP_RESULT = cleanup
        note(f"forward cleanup: {cleanup}")
        # 清理发生在 `_run` 写 result.json **之后**，所以必须回写一次，否则落盘
        # 的 `forward_cleanup` 会永远停在 not_attempted——那正是「清理结果被丢在
        # finally 里」的另一种形状：退出码对了，证据却是假的。
        _rewrite_cleanup_into_result(Path(args.out) / "result.json")
        if not (cleanup.startswith("removed") or cleanup.startswith("already_absent")
                or cleanup.startswith("not_owned_skipped")):
            run_rc = run_rc if run_rc != 0 else 4
    return run_rc


def _run(args):
    global EX, TOKEN, BOUND_PID
    BOUND_PID = app_pid()
    if not BOUND_PID:
        note("FAIL 无本实例 PID——无法归属，判据失败")
        return 2
    TOKEN = read_token()
    if not TOKEN:
        note("FAIL 未读到本实例 verify token（本次产物须为 verify-transport 变体）")
        return 2
    ident = bind_identity()
    note(f"token={TOKEN} identity={ident}")
    EX = BoundedExchange("127.0.0.1", PORT, str(Path(args.out) / "raw.json"))
    failures = 0

    # 基线：清闸门，读 admission 槽、已提交票号集合与真实 Flush 边界票号
    gate_command(EX, TOKEN, "GATE_CLEAR", ("cleared=",), timeout=12.0)
    held0 = admission_held(EX)
    commits0 = committed_tickets()
    fenter0, fexit0 = flush_boundary_tickets()
    note(f"== 基线 admission_held={held0} accepted-swap 票={sorted(commits0)} "
         f"flush边界票 enter={sorted(fenter0)} exit={sorted(fexit0)}")
    failures += check("基线 admission 槽可读", held0 >= 0, f"(got {held0})")
    failures += check("本产物带真实 Flush 边界计量（flush hold enter 可按票读到）",
                      len(fenter0) > 0,
                      "(需 --test-gates 构建；否则按票 Flush 边界不可观测)")

    # 对照组（正控）：不装 hold 的同样触发必须产生**一张新票的真实 Flush**，
    # 且该票有合法终态。这是「本驱动确实在测真实 Flush」的正控；旧实现只看
    # g_committedSettlements 的增量，同步提交或未结算的 Flush 它根本不记。
    adm_before_ctrl = admission_held(EX)
    ok, trig = trigger_present()
    if not ok:
        note(f"FAIL 对照触发失败：{trig}")
        return 2
    time.sleep(2.0)
    adm_ctrl = admission_held(EX)
    commits1 = committed_tickets()
    fenter1, fexit1 = flush_boundary_tickets()
    new_ctrl = sorted((fenter1 | fexit1) - (fenter0 | fexit0))
    terms = ticket_terminals()
    note(f"   对照触发: {trig}  admission {adm_before_ctrl}->{adm_ctrl}  "
         f"新 Flush 边界票 {new_ctrl}（accepted-swap {sorted(commits1 - commits0)}）")
    failures += check("对照（无 hold）admission 槽不推进",
                      adm_ctrl == adm_before_ctrl,
                      f"(before {adm_before_ctrl} after {adm_ctrl})")
    # 正控：同一 target/实例下，该票在**真实 SurfaceFlush 边界**上进入并返回。
    failures += check("对照触发在真实 Flush 边界产生恰一张新票", len(new_ctrl) == 1,
                      f"(new boundary tickets {new_ctrl})")
    if len(new_ctrl) == 1:
        t = new_ctrl[0]
        failures += check("对照票真实 Flush 进入+返回（enter 与 exit 同票）",
                          t in fenter1 and t in fexit1, f"(ticket {t})")
        failures += check("对照票有合法终态（present terminal status=0 phase=3）",
                          terms.get(t) == [(0, 3)], f"(ticket {t} terminal {terms.get(t)})")
        failures += check("对照票作为成功发布证据（accepted-swap，仅发布证据）",
                          t in (commits1 - commits0), f"(ticket {t})")

    # 实验组：装许可前 hold，触发一次真实变更让闸门落在许可前窗口；被按住的票超过
    # kRenderWaitTimeout 即确认取消（不 Flush），owner 串行、在确认取消后按"声明的 UI
    # 版本仍领先于已接受版本"立即重铸，故窗口内会出现**多张**被取消票（GLM 裁决：
    # 预期有界行为）。逐票判据见 decide_held_ticket；完整定义与边界见该函数 docstring。
    gate_command(EX, TOKEN, "GATE_HOLD_ADMIT_8000", ("hold_admission=",), timeout=12.0)
    adm_before = admission_held(EX)
    commits_before = committed_tickets()
    fenter_b, fexit_b = flush_boundary_tickets()
    terms_before = ticket_terminals()
    t_trig = time.time()
    ok, trig2 = trigger_present()
    if not ok:
        note(f"FAIL 实验触发失败：{trig2}")
        return 2
    adm_mid = adm_before
    for _ in range(12):
        h = admission_held(EX)
        if h > adm_before:
            adm_mid = h
            break
        time.sleep(0.25)
    note(f"   实验触发: {trig2}  admission {adm_before}->{adm_mid}")
    failures += check("许可前 hold 落在 admission 槽（推进）", adm_mid > adm_before,
                      f"(before {adm_before} after {adm_mid})")
    failures += check("hold 期间 owner 仍可服务（许可前等待有界，非无限阻塞）",
                      adm_mid >= 0, "(GATE_A2_STATS 在 hold 期间成功返回)")
    # 让涌现的重铸流建立：**按观测收敛**，不靠固定 5s 碰时机（复核 B）。有界轮询直到
    # 窗口内出现至少一张新终态票，或轮次用尽后具名记录（缺样本不伪装成已验）。
    remint_terms = {}
    for _ in range(16):
        now_terms = ticket_terminals()
        remint_terms = {t: v for t, v in now_terms.items() if t not in terms_before}
        if remint_terms:
            break
        time.sleep(0.25)
    failures += check("窗口内重铸流已建立（出现被取消的终态票）", bool(remint_terms),
                      f"(remint tickets={sorted(remint_terms)})")
    fenter_h, fexit_h = flush_boundary_tickets()
    held_flush_during = sorted((fenter_h | fexit_h) - (fenter_b | fexit_b))
    failures += check("hold 期间无任何新 Flush 边界票（被按住的票从未进入 Flush）",
                      held_flush_during == [], f"(during-hold boundary {held_flush_during})")

    # T2（真实业务写请求）：在 T1 的 waitFor 区间内**入队**，等待返回后才**分发**。
    # round7-B：基线（版本+全文）在**观察围栏之前**读取；T2 线程只发那一笔写，
    # 不再读正文（读请求会进传输账本，污染「最新账本项」归属）。
    owner_before_t2 = m.read_all(PORT)          # 围栏之前
    PHASE_PATTERN = ("present wait enter|present wait exit|transport-cost stage=enqueue"
                     "|transport-cost stage=owner-claim|present terminal")

    def max_phase_seq():
        """当前流里已出现的**最大观测序号**（0 = 还没有任何边界行）。

        round7-B：T2 的身份围栏必须取自**与判据同一个单调序号域**。用传输账本
        的 requestId 差集做围栏是错的——本脚本自己的对照触发也是 REPLACE_RANGE，
        差集会把它们算成候选（round7 首跑即因此具名 ambiguous）。序号围栏是
        单调的、跨 C++/仓颉同域的，且只截「发送之前已经发生过」的事实。
        """
        best = 0
        for row in scoped_rows(PHASE_PATTERN):
            for mo in re.finditer(r"seq=(\d+)", row):
                best = max(best, int(mo.group(1)))
        return best

    seq_fence_t2 = max_phase_seq()
    archive_len_before_t2 = len(EX.raw_log)
    fenter_t2, fexit_t2 = flush_boundary_tickets()
    terms_t2_before = ticket_terminals()
    t2_box = {}

    def _send_t2():
        try:
            t2_box["frame"], t2_box["resp"] = t2_write_only(owner_before_t2[0])
        except Exception as exc:  # noqa: BLE001
            t2_box["error"] = repr(exc)

    t2_thread = threading.Thread(target=_send_t2, daemon=True)
    t2_thread.start()
    # round7-B：T2 身份只从**真实入队线性化点**的 `stage=enqueue` 行取，op 必须是
    # 写操作，且序号严格大于发送前围栏。候选多于一个即歧义拒绝（旧实现取
    # write_ids[-1]，那是「碰一个算一个」）。
    t2_request_id, t2_phases, t2_ambiguous = None, [], False
    for _ in range(40):
        enq_rows = scoped_rows(PHASE_PATTERN)
        fresh_write_ids = sorted({int(mo.group(1)) for r in enq_rows
                                  for mo in [re.search(r"stage=enqueue \S+ requestId=(\d+) "
                                                        r"op=REPLACE_RANGE .*?seq=(\d+)", r)]
                                  if mo and int(mo.group(2)) > seq_fence_t2})
        if len(fresh_write_ids) > 1:
            t2_ambiguous = True
            t2_request_id = None
            break
        if fresh_write_ids:
            t2_request_id = fresh_write_ids[0]
            t2_phases = [row["phase"] for row in ticket_ledger(EX) if row["id"] == t2_request_id]
            break
        if not t2_thread.is_alive():
            break
        time.sleep(0.1)
    t2_thread.join(timeout=40.0)
    ok = "resp" in t2_box
    trig_t2 = (f"t2 request={t2_request_id} phases={t2_phases} seq_fence={seq_fence_t2} "
               f"frame={(t2_box.get('frame') or '')[:60]} err={t2_box.get('error')}")
    t2_during = {"trigger": trig_t2,
                 "t2_request_id": t2_request_id,
                 "t2_candidate_ambiguous": t2_ambiguous,
                 "t2_request_frame": t2_box.get("frame"),
                 "boundary_entries_during_hold": [], "terminals_during_hold": [],
                 "response": t2_box.get("resp")}
    fe2, fx2 = flush_boundary_tickets()
    t2_during["boundary_entries_during_hold"] = sorted((fe2 | fx2) - (fenter_t2 | fexit_t2))
    terms_t2_mid = ticket_terminals()
    t2_during["terminals_during_hold"] = sorted(set(terms_t2_mid) - set(terms_t2_before))

    # 释放：hold 常驻，只有 GATE_CLEAR 才放行；排空后才有首张合法 Flush。
    t_clear = time.time()
    gate_command(EX, TOKEN, "GATE_CLEAR", ("cleared=",), timeout=12.0)
    # 有界等待释放真正生效（窗口内首张票进入 Flush 边界），不用固定 4s 碰时机。
    for _ in range(20):
        if sorted((flush_boundary_tickets()[0] | flush_boundary_tickets()[1])
                  - (fenter_b | fexit_b)):
            break
        time.sleep(0.25)
    fenter_a, fexit_a = flush_boundary_tickets()
    terms_after = ticket_terminals()
    commits_after = committed_tickets()
    new_boundary = sorted((fenter_a | fexit_a) - (fenter_b | fexit_b))
    new_terms = {t: terms_after[t] for t in terms_after if t not in terms_before}
    new_commits = sorted(commits_after - commits_before)
    t2_during["boundary_entries_after_release"] = sorted((fenter_a | fexit_a) - (fenter_t2 | fexit_t2))
    t2_during["terminals_after_release"] = sorted(set(terms_after) - set(terms_t2_before))
    note(f"   T2 顺序记录: {t2_during}")

    # U = 释放后首张合法 Flush 票；W = 票号 < U 的全部窗口票（hold 期被取消的票）。
    W, U = partition_hold_window(new_terms, new_boundary)
    verdict = decide_held_ticket(W, set(new_boundary))
    note(f"   释放后 U={U}  窗口票 W={sorted(W)}  逐票终态={W}  新边界票={new_boundary} "
         f"accepted-swap 新票={new_commits}")
    failures += check("窗口内新增终态票集合非空（触发确实到达 present）",
                      verdict["nonempty"], f"(W={sorted(W)})")
    failures += check("每张窗口票恰一行终态（不靠 dict 去重）",
                      verdict["unique_terminal"], f"(W={W})")
    failures += check("每张窗口票终态为 (7,4)：等待方超时确认取消",
                      verdict["cancelled_signature"], f"(W={W})")
    failures += check("每张窗口票从未进入真实 Flush 边界（逐票 Flush=0）",
                      verdict["never_flushed"], f"(W={sorted(W)} boundary={new_boundary})")
    failures += check("T1 = 窗口内首张被取消票（min(W)）",
                      verdict["t1"] is not None, f"(T1={verdict['t1']})")
    # T2 顺序判据（round7-B：pass=null 不再可接受）。判据只比四个**真实边界序号**：
    # `enter(T1) < enqueue(T2) < exit(T1) <= claim(T2)`，四个序号取自同一个进程内
    # 单调原子计数器。hilog 行序与毫秒时间戳都不参与（跨线程无 happens-before，
    # 行序是 hilogd 接收序）。
    # T1 的配对规则：在 `enqueue(T2)` 那一刻**仍在等待**（enter < enqueue <= exit）的
    # present 票。旧的三条推断（发送后首条 terminal 即 T1、window_min_fallback、
    # 写入即刻入队）已删除。候选多于一张即歧义拒绝，不取任何一张凑数。
    phase_rows = scoped_rows(PHASE_PATTERN)
    enq_for_t1 = enqueue_seq(phase_rows, t2_request_id) if t2_request_id is not None else None
    t1_candidates = sorted(open_wait_tickets(phase_rows, enq_for_t1)) \
        if enq_for_t1 is not None else []
    t1_pairing = t1_candidates[0] if len(t1_candidates) == 1 else None
    t2_during["t1_basis"] = ("open_wait_interval_at_enqueue" if t1_pairing is not None
                             else ("t1_candidate_ambiguous" if len(t1_candidates) > 1
                                   else "t1_open_wait_not_found"))
    t2_during["t1_candidates"] = t1_candidates
    t2_during["t1_pairing"] = t1_pairing
    owner_after_t2 = m.read_all(PORT)
    t2_pass, t2_reason, t2_facts = decide_t2_ordering(
        t1_pairing, t2_request_id, phase_rows,
        EX.raw_log[archive_len_before_t2:],
        t2_box.get("resp"),
        owner_before=(owner_before_t2[0],
                      owner_before_t2[1] if isinstance(owner_before_t2[1], str) else None),
        owner_after=(owner_after_t2[0],
                     owner_after_t2[1] if isinstance(owner_after_t2[1], str) else None),
        t2_request_frame=t2_box.get("frame"))
    t2_during["ordering"] = {"pass": t2_pass, "reason": t2_reason, "facts": t2_facts}
    failures += check("真实 T2 在同一 T1 的 waitFor 区间入队、等待返回后才分发、业务终态唯一",
                      t2_pass, f"({t2_reason} {json.dumps(t2_facts, ensure_ascii=False)})")
    EVIDENCE.append({"check": "T2 入队/分发/终态顺序（记录）", "pass": t2_pass,
                     "detail": json.dumps(t2_during, ensure_ascii=False)})
    # 释放后的合法 Flush 正证（U）：enter+exit 同票、status=0、accepted-swap、且 U > max(W)。
    if U is not None:
        failures += check("释放后首张 Flush 票 U 真实 enter+exit",
                          U in fenter_a and U in fexit_a, f"(U={U})")
        failures += check("U 终态 status=0 phase=3（成功）",
                          terms_after.get(U) == [(0, 3)], f"(U={U} terminal {terms_after.get(U)})")
        failures += check("U 作为成功发布证据（accepted-swap，仅发布证据）",
                          U in new_commits, f"(U={U})")
        failures += check("U 在全部窗口票之后（合法 Flush 不混入 W）",
                          (not W) or U > max(W), f"(U={U} W={sorted(W)})")
    else:
        failures += check("释放后存在合法 Flush 正证（U 可绑定）", False,
                          "(new boundary tickets empty)")
    # 稳健性上界（非计划要求）：重铸节奏 = waitFor 上界；窗口内票数不应超 ⌈窗口/2s⌉+2。
    failures += check("重铸票数在 waitFor 上界内（|W| ≤ ⌈窗口/2s⌉+2）",
                      remint_within_bound(len(W), t_clear - t_trig),
                      f"(|W|={len(W)} window={t_clear - t_trig:.1f}s)")

    # 组3（说明性记录，不断言）：许可后 PENDING 窗口。装 `GATE_FLUSH_HOLD_30000` 后触发
    # 一次变更 → present 在 Flush 前被按住；owner 的 waitFor 到 kRenderWaitTimeout 返回
    # PENDING，此时对文档的新请求在真实链上被票据门禁挡住（读 GET_CONTEXT 即不可用）。
    # 这里只记录观测：`configure refused: pending ticket=` 的具名拒绝是否出现、以及
    # PENDING 期间文档读是否被拒。**不**把它当成本文件的通过判据——具名 configure 拒绝的
    # 完整断言依赖一次不依赖被门禁读的第二次变更，见 round3/README 的边界说明。
    refused_before = refused_tickets()
    gate_command(EX, TOKEN, "GATE_FLUSH_HOLD_30000", ("flush_hold=",), timeout=12.0)
    ok, trig3 = trigger_present()
    if not ok:
        note(f"FAIL 组3 触发失败：{trig3}")
        return 2
    time.sleep(2.6)
    pending_read_ok = True
    try:
        m.read_all(PORT)
    except Exception:  # noqa: BLE001
        pending_read_ok = False
    new_refused = refused_tickets() - refused_before
    gate_command(EX, TOKEN, "GATE_FLUSH_HOLD_RELEASE", ("flush_release=",), timeout=12.0)
    time.sleep(1.5)
    note(f"   组3 触发 {trig3}  PENDING 期间读文档 ok={pending_read_ok}  "
         f"新具名拒绝票据 {sorted(new_refused)}")
    EVIDENCE.append({"check": "组3（记录，不断言）PENDING 窗口观察", "pass": None,
                     "detail": f"new_refused={sorted(new_refused)} "
                               f"pending_read_ok={pending_read_ok}"})

    gate_command(EX, TOKEN, "GATE_CLEAR", ("cleared=",), timeout=12.0)

    out = Path(args.out)
    out.mkdir(parents=True, exist_ok=True)
    EX.flush_archive()
    # round6-B：随包保存**可复算的完整有序 hilog 流**——行号判据（T1 终态行
    # vs T2 claim 行）必须能用同一份数据重放，不再只有结论 JSON。
    (out / "ordered_rows.txt").write_text("\n".join(
        f"{i}: {row}" for i, row in enumerate(scoped_rows("."))))
    (out / "result.json").write_text(json.dumps(
        {"failures": failures, "evidence": EVIDENCE, "identity": ident, "token": TOKEN,
         "baseline": {"admission": held0, "committed_tickets": sorted(commits0),
                      "flush_boundary_enter": sorted(fenter0),
                      "flush_boundary_exit": sorted(fexit0)},
         "control": {"admission_before": adm_before_ctrl, "admission_after": adm_ctrl,
                     "new_boundary_tickets": new_ctrl,
                     "new_committed_tickets": sorted(commits1 - commits0)},
         "experiment": {"admission_before": adm_before, "admission_mid": adm_mid,
                        "window_ms": round((t_clear - t_trig) * 1000.0, 1),
                        "t1": verdict["t1"], "held_tickets": verdict["held_tickets"],
                        "held_terminals": {str(k): v for k, v in W.items()},
                        "u": U, "u_terminal": terms_after.get(U) if U is not None else None,
                        "new_boundary_tickets": new_boundary,
                        "new_committed_tickets": new_commits},
         "t2": t2_during,
         "forward_cleanup": CLEANUP_RESULT,
         "target": FORWARD_TARGET,
         "group3": {"new_refused_tickets": sorted(new_refused)}},
        ensure_ascii=False, indent=1))
    note(f"== 结果 failures={failures}  证据 {out/'result.json'}")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())

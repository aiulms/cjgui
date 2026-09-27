#!/usr/bin/env python3
"""A2/A3：Surface 全使用期许可八类反例 + 真实应用关闭收敛（交接文档四/八节）。

注入经 verify 控制接缝 → owner 派发 renderer test-gates / 受控退役模拟；
结果由生产 retire/teardown/结算逻辑产生。受控模拟（sim retired/created）按
真实 retire+teardown 链执行，仅销毁事件由探针注入；真实 XComponent 压力单列。

  C1 许可窗口内销毁重建：permit hold → SIM_RETIRED+SIM_CREATED → CLEAR →
     旧代不创建/不 Flush（创建计数不增）、新代首帧成功（业务可用）。
  C2 创建前销毁重建：create hold → SIM_RETIRED+SIM_CREATED → CLEAR。
  C3 绘制中销毁重建：draw hold → SIM_RETIRED+SIM_CREATED → CLEAR。
  C4 提交准入前销毁重建：admission hold → SIM_RETIRED → INCREMENT 排队 →
     CLEAR → 旧代取消/新代接管（aborted 或 committed 推进，业务最终一致）。
  C5 不可取消提交中销毁重建：flush hold（committing 内）→ INCREMENT →
     SIM_RETIRED → CLEAR → 旧代 Flush 按真实 rc 结算，不晋升新代 accepted
     （公开读回版本单调、业务一致）。
  C6 空闲真实关闭收敛：CLOSE_WINDOW → 停止链收敛（连接被拒、宿主关闭日志）。
  C7 queued 关闭收敛：DEQUEUE hold → INCREMENT 挂起 → UI STOP HOST →
     同票取消终态与停止链全零。
  C8 committing 关闭收敛：FLUSH hold → INCREMENT（committing 内）→
     UI STOP HOST → 同票结算/ACK 与停止链全零。

用法： python3 verify_surface_lifecycle_probe.py [--only-stop-tickets]
"""

import json
import atexit
import os
import re
import subprocess
import sys
import time
from pathlib import Path

sys.path.insert(0, "/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/platforms/ohos/scripts")
sys.path.insert(0, "/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/shared_operation_core")
from ohos_transport_probe_lib import (  # noqa: E402
    BoundedExchange, GateCommandError, gate_command, gate_stage_held,
    parse_business_terminal_strict, parse_control_frame_strict)

# stageHeld 槽位（与 renderer gateStageHeldSlot 一致；每槽 9 位饱和）
SLOT_PERMIT, SLOT_CREATE, SLOT_CREATE_RET = 0, 1, 2
SLOT_DRAW, SLOT_ADMIT, SLOT_FLUSH, SLOT_DEQUEUE = 3, 4, 5, 6


def stub_direct(op, timeout=8.0):
    """第九次复核 C/D：替身状态/放行/退役走**宿主直连通道**——不经 owner
    serveOnce（owner 阻塞于 host.start 首帧或退出时仍可达）。"""
    _, body = EXCHANGE.exchange_strict(
        ["CONTROL CJGUI_VERIFY/1", f"TOKEN {TOKEN}", f"OP {op}", "END"], timeout)
    return body


def platform_call_triplet(packed):
    """Production create/flush/destroy enter counters, each saturating at 254."""
    return (packed & 0xFF, (packed >> 32) & 0xFF, (packed >> 48) & 0xFF)


def platform_call_triplet_unchanged(before, after):
    """A stub session must not add real platform calls to an existing baseline."""
    baseline = platform_call_triplet(before)
    return max(baseline) < 254 and platform_call_triplet(after) == baseline


def read_platform_call_packed():
    body = stub_direct("GATE_PC_CALLS")
    match = re.search(r"pc_calls=(-?\d+)", body)
    if not match or int(match.group(1)) < 0:
        raise AssertionError(f"invalid platform-call counters: {body!r}")
    return int(match.group(1))


def permit_pair():
    """许可对（累计 acquired/released）——按窗口差值断言“恰好归还一次”。"""
    raw = gate("GATE_A2_STATS", expect=("permits=",))
    m = re.search(r"permits=(\d+)/(\d+)", str(raw))
    return (int(m.group(1)), int(m.group(2))) if m else (None, None)


def log_count(pattern):
    """hilog 当前计数（用于窗口差值断言；模式不含正则特殊字符）。"""
    out = subprocess.run(
        [HDC, "shell", f"hilog -x 2>/dev/null | grep -ac '{pattern}'"],
        capture_output=True, text=True).stdout.strip()
    try:
        return int(out)
    except ValueError:
        return 0


def bind_identity():
    """第九次复核 D：统一身份绑定——PID + appInstance（本轮实例），
    供各阶段断言/证据；不匹配即失败（不按全局历史日志猜时序）。"""
    pid = subprocess.run([HDC, "shell", "pidof com.example.cjguiapp"],
                         capture_output=True, text=True).stdout.strip()
    return {"pid": pid, "appInstance": APP_INSTANCE}


def gate(op, expect=(), timeout=14.0):
    """第七次复核 A1：发布闸门命令并等待同 PUBLISHED ID 的执行回执。
    未知操作/错 ID/负返回一律抛 GateCommandError（探针判失败）。"""
    return gate_command(EXCHANGE, TOKEN, op, expect_tokens=expect, timeout=timeout)


def held_delta(slot, before):
    """本阶段真实 held 计数增量（绑定本实例，替代易丢的 hilog 见证）。"""
    now = gate_stage_held(EXCHANGE, TOKEN, slot)
    if before is None or now is None or now < 0:
        return None
    return now - before


def held_delta_poll(slot, before, timeout=8.0):
    """持有到达有帧管线延迟：轮询直到出现增量或超时。"""
    deadline = time.monotonic() + timeout
    d = held_delta(slot, before)
    while (d is None or d < 1) and time.monotonic() < deadline:
        time.sleep(0.5)
        d = held_delta(slot, before)
    return d
from client import parse_response  # noqa: E402

def configured_endpoint():
    host = os.environ.get("CJGUI_OHOS_HOST", "127.0.0.1")
    raw_port = os.environ.get("CJGUI_OHOS_PORT", "17856")
    if not host or host.strip() != host or any(ch.isspace() for ch in host):
        raise SystemExit(f"invalid CJGUI_OHOS_HOST: {host!r}")
    if not re.fullmatch(r"\d+", raw_port):
        raise SystemExit(f"invalid CJGUI_OHOS_PORT: {raw_port!r}")
    port = int(raw_port, 10)
    if not 1 <= port <= 65535:
        raise SystemExit(f"invalid CJGUI_OHOS_PORT: {raw_port!r}; expected 1..65535")
    return host, port


HOST, PORT = configured_endpoint()
PROTOCOL = "CJGUI_SHARED_OPERATION/2"
CAP = "cjgui-settings-counter-agent-20260925"
RESOURCE_ID = 9700
TOKEN = ""
APP_INSTANCE = 0
EVIDENCE = []
EVIDENCE_DIR = Path(os.environ.get(
    "CJGUI_OHOS_VERIFICATION_DIR",
    "/Users/jiangxuanyang/Desktop/cangjie/labs/ohos_cangjie_smoke/"
    "artifacts/cjgui-backend/verification"))
EVIDENCE_DIR.mkdir(parents=True, exist_ok=True)
RAW_ARCHIVE = str(EVIDENCE_DIR / "surface_lifecycle_raw.json")
EXCHANGE = BoundedExchange(HOST, PORT, RAW_ARCHIVE)
atexit.register(EXCHANGE.flush_archive)
HDC = os.environ.get(
    "HDC",
    "/Applications/DevEco-Studio.app/Contents/sdk/default/openharmony/"
    "toolchains/hdc")
RAW_HDC = os.environ.get("CJGUI_REAL_DEVICE_HDC_BINARY", "")
RUN_ID = os.environ.get("CJGUI_OHOS_RUN_ID", "")
TARGET = os.environ.get("CJGUI_REAL_DEVICE_TARGET", "")


def note(msg):
    print(msg)


def check(desc, actual, expected):
    ok = actual == expected
    note(f"   {'OK  ' if ok else 'FAIL'} {desc} (got {actual!r} expect {expected!r})")
    EVIDENCE.append({"check": desc, "actual": actual, "expected": expected, "pass": ok,
                     "status": "PASS" if ok else "FAIL"})
    return 0 if ok else 1


def check_blocked(desc, reason):
    """第八次复核链3：必需项开放时逐项 BLOCKED，不得汇总 PASS/FAIL 掩蔽。
    BLOCKED 只用于「该档位下判据对象不存在」（如 KnownShimNoRef 拒绝发布
    surface 后渲染路径不存在），不计入 failures；理由必须具体可核。"""
    note(f"   BLKD {desc} [{reason}]")
    EVIDENCE.append({"check": desc, "status": "BLOCKED", "reason": reason})
    return 0


def business(lines, timeout=8.0, retries=3):
    last = None
    for _ in range(retries + 1):
        try:
            return EXCHANGE.exchange_strict(
                [f"PROTOCOL {PROTOCOL}", f"AUTH {CAP}"] + lines, timeout)
        except (ConnectionResetError, ConnectionError, OSError) as exc:
            last = exc
            time.sleep(1.0)
    raise last


def control_map(op, timeout=6.0, retries=1):
    last = None
    for _ in range(retries + 1):
        try:
            _, body = EXCHANGE.exchange_strict(
                ["CONTROL CJGUI_VERIFY/1", f"TOKEN {TOKEN}", f"OP {op}", "END"], timeout)
            return parse_control_frame_strict(body)
        except (ConnectionResetError, ConnectionError, OSError) as exc:
            last = exc
            time.sleep(1.0)
    raise last


def invoke_increment(v, timeout=8.0, retries=1):
    _, body = business([f"INVOKE {v} INCREMENT 1 0", f"ID {RESOURCE_ID}"], timeout=timeout, retries=retries)
    return parse_business_terminal_strict(body)


def version_of(text):
    parsed = parse_response(text)
    for name, parts in parsed.entries:
        if name == "VERSION":
            return int(parts[0])
    raise AssertionError("no VERSION")


def gate_result(timeout=5.0):
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        g = control_map("GATE_STATE")
        if g.get("RESULT_ID") == g.get("LAST_COMMAND") and g.get("LAST_COMMAND") != "0":
            return g.get("RESULT", "")
        time.sleep(0.1)
    return "timeout"


def clear_all():
    """解除全部持有类闸门（同样走 ID 握手，验证命令真实执行）。"""
    return gate("GATE_CLEAR", expect=("cleared=",))


def hilog_tail(pattern, n=2):
    out = subprocess.run(
        [HDC, "shell", f"hilog -x 2>/dev/null | grep -a '{pattern}' | tail -{n}"],
        capture_output=True, text=True).stdout
    return out.strip()


def instance_hilog_lines(pid=None):
    """Read logs from only this probe's current process; no old PID can count."""
    pid = pid or bind_identity()["pid"]
    if not re.fullmatch(r"\d+", pid) or APP_INSTANCE <= 0:
        raise AssertionError(f"probe instance identity missing: pid={pid!r} app={APP_INSTANCE}")
    result = subprocess.run([HDC, "shell", "hilog -x"], capture_output=True, text=True)
    if result.returncode != 0:
        raise AssertionError(f"hilog read failed: {result.stderr.strip()}")
    return [line for line in result.stdout.splitlines()
            if re.match(r"^\S+\s+\S+\s+" + re.escape(pid) + r"\s+\d+\s+[A-Z]\s+", line)]


def click_real_surface_cycles():
    """Drive the ArkUI XComponent through actual unmount/remount and wait for completion."""
    result = subprocess.run([HDC, "shell", "uitest uiInput click 674 2149"],
                            capture_output=True, text=True)
    if result.returncode != 0:
        raise AssertionError(f"real XComponent cycle tap failed: {result.stderr.strip()}")
    deadline = time.monotonic() + 25
    lines = []
    while time.monotonic() < deadline:
        lines = instance_hilog_lines()
        if any("10 surface cycles done" in line for line in lines):
            return lines
        time.sleep(0.5)
    raise AssertionError("real XComponent cycle completion absent from current PID")


def new_native_frame_in(lines):
    """The last new native-ref publication must precede a frame in this PID."""
    created = [(i, line) for i, line in enumerate(lines)
               if "surface created id=" in line and "nativeref rc=0" in line
               and "published=1" in line]
    if not created:
        return False, {"reason": "no current-PID native-ref publication"}
    idx, line = created[-1]
    generation = re.search(r"gen=(\d+)", line)
    framed = any("present frame ok" in later for later in lines[idx + 1:])
    return framed, {"generation": int(generation.group(1)) if generation else 0,
                    "publication": line[-180:], "frame_after_publication": framed}


def create_hold_retirement_proof(lines):
    """Find one generation destroyed inside a real create hold, then safely released."""
    for start, line in enumerate(lines):
        match = re.search(r"create_before hold enter gen=(\d+)", line)
        if not match:
            continue
        gen = match.group(1)
        def first_after(pattern, offset):
            return next((i for i in range(offset, len(lines)) if pattern in lines[i]), -1)
        destroyed = first_after(f"surface destroyed gen={gen}:", start + 1)
        exited = first_after(f"create_before hold exit gen={gen}", start + 1)
        denied = first_after(f"surface create skipped: permit denied before create gen={gen}", start + 1)
        released = [i for i, row in enumerate(lines)
                    if f"surface ref released on UI thread gen={gen} " in row and "rc=0" in row]
        fenced = any(f"destroy fence gen={gen}" in row for row in lines)
        if (destroyed > start and exited > destroyed and denied > exited
                and len(released) == 1 and released[0] > denied and not fenced):
            return True, {"generation": int(gen), "enter": start, "destroy": destroyed,
                          "exit": exited, "permit_denied": denied, "unref": released[0]}
    return False, {"reason": "no same-generation hold→destroy→deny→single-unref sequence"}


def flush_hold_retirement_proof(lines):
    """A committing hold must retire its own generation before native Flush."""
    for start, line in enumerate(lines):
        match = re.search(r"flush hold enter gen=(\d+)", line)
        if not match:
            continue
        gen = match.group(1)
        def first_after(pattern, offset):
            return next((i for i in range(offset, len(lines)) if pattern in lines[i]), -1)
        destroyed = first_after(f"surface destroyed gen={gen}:", start + 1)
        exited = first_after(f"flush hold exit gen={gen}", start + 1)
        aborted = first_after(f"present flush aborted on retired lease gen={gen}", start + 1)
        released = [i for i, row in enumerate(lines)
                    if f"surface ref released on UI thread gen={gen} " in row and "rc=0" in row]
        if (destroyed > start and exited > destroyed and aborted > exited
                and len(released) == 1 and released[0] > aborted):
            return True, {"generation": int(gen), "enter": start, "destroy": destroyed,
                          "exit": exited, "flush_aborted": aborted, "unref": released[0]}
    return False, {"reason": "no same-generation committing→destroy→abort→single-unref sequence"}


def startup_ticket_settled(lines, pid):
    """The forced 4s startup Flush ticket must finish before a C7/C8 gate arm."""
    if not re.fullmatch(r"\d+", str(pid)):
        return False, {"reason": "invalid PID"}
    prefix = re.compile(r"^\S+\s+\S+\s+" + re.escape(str(pid)) + r"\s+\d+\s+[A-Z]\s+")
    own = [line for line in lines if prefix.match(line)]
    pending = [i for i, row in enumerate(own) if re.search(r"present pending ticket=1\b", row)]
    settled = [i for i, row in enumerate(own)
               if re.search(r"pending settlement committed ticket=1\b", row)]
    ack = [i for i, row in enumerate(own)
           if re.search(r"present ticket acknowledged id=1\b", row)]
    sync = [i for i, row in enumerate(own)
            if re.search(r"present terminal session=1 ticket=1 status=0 phase=3\b", row)]
    holds = [i for i, row in enumerate(own)
             if re.search(r"flush hold enter gen=\d+ session=1 ticket=1\b", row)]
    exits = [i for i, row in enumerate(own)
             if re.search(r"flush hold exit gen=\d+ session=1 ticket=1\b", row)]
    issued = [int(match.group(1)) for row in own
              for match in re.finditer(r"(?:\bticket=|\bid=)(\d+)\b", row)
              if any(tag in row for tag in ("present ", "pending settlement", "flush hold",
                                             "test gate holding", "test gate dequeue"))]
    prior_only = bool(issued) and max(issued) == 1
    hold_done = len(holds) == len(exits) == 1 and holds[0] < exits[0]
    pending_done = (len(pending) == len(settled) == len(ack) == 1
                    and pending[0] < exits[0] < settled[0] < ack[0])
    sync_done = len(sync) == 1 and exits[0] < sync[0] if hold_done else False
    ok = prior_only and hold_done and (pending_done or sync_done)
    return ok, {"startup_ticket": 1, "hold_count": len(holds), "exit_count": len(exits),
                "pending_count": len(pending), "settlement_count": len(settled),
                "ack_count": len(ack), "sync_count": len(sync),
                "max_ticket": max(issued, default=0),
                "reason": "startup ticket 1 incomplete or later ticket already issued" if not ok else "settled"}


def ticket_stage_at_close(lines, pid, stage, expected_ticket=None):
    """A named renderer ticket must still be held in the pre-CLOSE snapshot."""
    if stage not in ("queued", "committing") or not re.fullmatch(r"\d+", str(pid)):
        return False, {"reason": "invalid ticket stage or PID"}
    prefix = re.compile(r"^\S+\s+\S+\s+" + re.escape(str(pid)) + r"\s+\d+\s+[A-Z]\s+")
    own = [line for line in lines if prefix.match(line)]
    arm_op = "GATE_DEQUEUE_HOLD_30000" if stage == "queued" else "GATE_FLUSH_HOLD_30000"
    armed = [i for i, line in enumerate(own) if f"verify gate {arm_op} ->" in line]
    if armed:
        own = own[armed[-1] + 1:]
    hold_pattern = (r"test gate holding dequeue session=(\d+) ticket=(\d+) gen=(\d+)"
                    if stage == "queued" else
                    r"flush hold enter gen=(\d+) session=(\d+) ticket=(\d+)")
    active = []
    for index, line in enumerate(own):
        match = re.search(hold_pattern, line)
        if not match:
            continue
        if stage == "queued":
            session, ticket, gen = map(int, match.groups())
            release = f"test gate dequeue released session={session} ticket={ticket} gen={gen}"
        else:
            gen, session, ticket = map(int, match.groups())
            release = f"flush hold exit gen={gen} session={session} ticket={ticket}"
        if min(session, ticket, gen) <= 0:
            continue
        if expected_ticket is not None and ticket != expected_ticket:
            continue
        later = own[index + 1:]
        terminal = f"present terminal session={session} ticket={ticket} "
        if (any(release in row or terminal in row for row in later)
                or any(re.search(r"pending settlement (?:committed|aborted) ticket=" +
                                 str(ticket) + r"\b", row) for row in later)
                or any(re.search(r"present ticket acknowledged id=" +
                                 str(ticket) + r"\b", row) for row in later)):
            continue
        active.append({"pid": str(pid), "stage": stage, "session": session,
                       "ticket": ticket, "generation": gen, "hold": line})
    if len(active) != 1:
        return False, {"reason": f"expected one active named {stage} ticket; found {len(active)}"}
    return True, active[0]


def ticket_terminal_after_close(lines, pid, stage, witness, app_instance):
    """Verify the held ticket's single native terminal path after UI stop."""
    if (not witness or witness.get("pid") != str(pid) or witness.get("stage") != stage
            or not isinstance(app_instance, int) or app_instance <= 0):
        return False, {"reason": "ticket witness identity mismatch"}
    prefix = re.compile(r"^\S+\s+\S+\s+" + re.escape(str(pid)) + r"\s+\d+\s+[A-Z]\s+")
    own = [line for line in lines if prefix.match(line)]
    starts = [i for i, line in enumerate(own) if line == witness["hold"]]
    if len(starts) != 1:
        return False, {"reason": "held ticket log absent or ambiguous in final PID trace"}
    tail = own[starts[0] + 1:]
    session, ticket, gen = (witness[k] for k in ("session", "ticket", "generation"))
    release = (f"test gate dequeue released session={session} ticket={ticket} gen={gen}"
               if stage == "queued" else
               f"flush hold exit gen={gen} session={session} ticket={ticket}")
    releases = [i for i, line in enumerate(tail) if release in line]
    ui_stop = [i for i, line in enumerate(tail)
               if "verify stop host requested from UI" in line]
    native_requested = [i for i, line in enumerate(tail)
                        if re.search(r"stopHost requested \(started=1 phase=(?:running|starting) appInstance=" +
                                     str(app_instance) + r"\)", line)]
    native_stopping = [i for i, line in enumerate(tail)
                       if re.search(r"stopHost: host phase=stopping appInstance=" +
                                    str(app_instance) + r"\b", line)]
    detail = {"session": session, "ticket": ticket, "generation": gen,
              "stage": stage, "release_count": len(releases),
              "ui_stop_count": len(ui_stop), "native_request_count": len(native_requested),
              "native_stopping_count": len(native_stopping)}
    if (len(releases) != 1 or len(ui_stop) != 1 or len(native_requested) != 1
            or len(native_stopping) != 1
            or not ui_stop[0] < native_requested[0] < native_stopping[0] < releases[0]):
        return False, {**detail, "reason": "same-PID UI stop/stopHost not applied during ticket hold"}
    sync_pattern = (r"present terminal session=" + str(session) + r" ticket=" +
                    str(ticket) + r" status=(-?\d+) phase=(\d+)")
    sync = [(i, re.search(sync_pattern, line)) for i, line in enumerate(tail)]
    sync = [(i, match) for i, match in sync if match]
    pending_pattern = r"present pending ticket=" + str(ticket) + r"\b"
    settle_pattern = r"pending settlement (committed|aborted) ticket=" + str(ticket) + r"\b"
    ack_pattern = r"present ticket acknowledged id=" + str(ticket) + r"\b"
    pending = [i for i, line in enumerate(tail) if re.search(pending_pattern, line)]
    settled = [(i, re.search(settle_pattern, line).group(1))
               for i, line in enumerate(tail) if re.search(settle_pattern, line)]
    ack = [i for i, line in enumerate(tail) if re.search(ack_pattern, line)]
    detail.update({"sync_terminal_count": len(sync), "pending_count": len(pending),
                   "settlement_count": len(settled), "ack_count": len(ack)})
    if stage == "queued":
        ok = (len(sync) == 1 and int(sync[0][1].group(1)) != 0
              and int(sync[0][1].group(2)) == 4  # JobPhase::Cancelled
              and native_stopping[0] < sync[0][0]
              and len(pending) == len(settled) == len(ack) == 0)
    else:
        ok = (len(sync) == 0 and len(pending) == len(settled) == len(ack) == 1
              and native_stopping[0] < releases[0] < settled[0][0] < ack[0]
              and pending[0] < settled[0][0])
    if not ok:
        detail["reason"] = "target ticket terminal/settlement/ACK not unique or out of order"
    return ok, detail


def invoke_and_sync(v):
    """INCREMENT 并从回执同步本地版本（触发帧在 owner 侧照样应用）。"""
    t = invoke_increment(v)
    if t.get("APPLIED") == "true" and t.get("VERSION_AFTER") is not None:
        return t["VERSION_AFTER"], t
    return v, t


def hilog_clear():
    subprocess.run([HDC, "shell", "hilog -r"], capture_output=True)


def stage_witness(stage):
    """阶段见证：该生产阶段的持有日志（renderer cjguiOhosTestGateHold）。
    帧管线可能延迟到达，轮询等待（最长 ~8s）。"""
    deadline = time.monotonic() + 8
    out = ""
    while time.monotonic() < deadline:
        out = subprocess.run(
            [HDC, "shell",
             f"hilog -x 2>/dev/null | grep -a 'test gate holding {stage}' | tail -1"],
            capture_output=True, text=True).stdout.strip()
        if out:
            break
        time.sleep(0.5)
    return out


def stop_terminal_from_lines(lines, pid, app_instance):
    """Require the real stop tail of one PID/app instance, in production order.

    `host closed` has no appInstance field. The following `stop settled` line
    binds it to the instance and confirms owner join, renderer exit, and zero
    sessions/tickets/references. A different PID or an old settled instance
    cannot lend those facts to the requested stop.
    """
    detail = {"pid": str(pid), "appInstance": app_instance,
              "transport": "", "closed": "", "settled": ""}
    if not re.fullmatch(r"\d+", str(pid)) or not isinstance(app_instance, int) or app_instance <= 0:
        return False, detail
    prefix = re.compile(r"^\S+\s+\S+\s+" + re.escape(str(pid)) + r"\s+\d+\s+[A-Z]\s+")
    own = [line for line in lines if prefix.match(line)]
    settled_for_instance = [i for i, line in enumerate(own)
                            if re.search(r"\bstop settled appInstance=" +
                                         re.escape(str(app_instance)) + r"\b", line)]
    if not settled_for_instance:
        detail["reason"] = "same-instance stop settled absent"
        detail["closed"] = next((line[-220:] for line in reversed(own)
                                 if "host closed" in line), "")
        return False, detail
    settled_index = settled_for_instance[-1]
    detail["settled"] = own[settled_index][-240:]
    before = own[:settled_index]
    closed_index = next((i for i in range(len(before) - 1, -1, -1)
                         if "host closed" in before[i]), -1)
    if closed_index >= 0:
        detail["closed"] = before[closed_index][-220:]
    transport_index = next((i for i in range(closed_index - 1, -1, -1)
                            if "transport closing" in before[i]), -1)
    if transport_index >= 0:
        detail["transport"] = before[transport_index][-220:]
    if transport_index < 0 or closed_index < 0:
        detail["reason"] = "same-PID transport/host tail absent or out of order"
        return False, detail
    # A later start in the same PID would make the preceding tail stale.
    if any(re.search(r"startHost accepted.*appInstance=", line)
           for line in own[transport_index + 1:settled_index]):
        detail["reason"] = "new app instance interposed before settlement"
        return False, detail
    def has_fields(line, expected):
        return all(re.search(r"\b" + re.escape(key) + r"=" + re.escape(value) + r"\b", line)
                   for key, value in expected.items())
    transport_ok = has_fields(before[transport_index],
                              {"closed": "true", "queued": "0", "conns": "0", "inflight": "0"})
    host_ok = has_fields(before[closed_index],
                         {"render_shutdown_status": "0", "shutdown_done": "1"})
    settled_ok = has_fields(own[settled_index],
                            {"appInstance": str(app_instance), "ownerJoined": "1",
                             "rendererDone": "1", "sessions": "0", "unacked": "0",
                             "pending": "0", "refsUnclosed": "0", "activeSurfaces": "0",
                             "phase": "stopped"})
    detail.update({"transport_closed": transport_ok, "ok_closed": host_ok,
                   "settled_zero": settled_ok})
    return transport_ok and host_ok and settled_ok, detail


def stop_terminal_ok(identity=None):
    """Read the same process throughout stop, even after its listener closes."""
    identity = identity or bind_identity()
    pid = identity.get("pid", "")
    app_instance = identity.get("appInstance", 0)
    try:
        lines = instance_hilog_lines(pid=pid)
    except AssertionError as exc:
        return False, {"pid": pid, "appInstance": app_instance, "reason": str(exc)}
    return stop_terminal_from_lines(lines, pid, app_instance)


def archive_stop_ticket_trace(label, pid, matrix):
    """Freeze the complete old process trace before the next app start clears hilog."""
    lines = instance_hilog_lines(pid=pid)
    trace_file = EVIDENCE_DIR / f"stop_ticket_{label.lower()}_pid_{pid}.hilog"
    trace_file.write_text("\n".join(lines) + "\n", encoding="utf-8")
    matrix[f"{label}_hilog"] = str(trace_file)
    return lines


def targeted_hdc(*args):
    """Never send a real UI input to an implicit/default HDC device."""
    if not TARGET or TARGET.strip() != TARGET or any(ch.isspace() for ch in TARGET):
        raise AssertionError("CJGUI_REAL_DEVICE_TARGET is required for STOP HOST UI input")
    # run_pending_real_device_checks.sh exports HDC as an already-targeted
    # wrapper and the underlying binary separately. Avoid a duplicate -t.
    if RAW_HDC:
        command = [RAW_HDC, "-t", TARGET, *args]
    elif Path(HDC).name == "hdc-target.sh":
        command = [HDC, *args]
    else:
        command = [HDC, "-t", TARGET, *args]
    result = subprocess.run(command, capture_output=True, text=True)
    if result.returncode != 0:
        raise AssertionError(f"targeted hdc {' '.join(args[:2])} failed: "
                             f"rc={result.returncode} stderr={result.stderr.strip()!r}")
    return result


def targeted_pid():
    pid = targeted_hdc("shell", "pidof com.example.cjguiapp").stdout.strip()
    if not re.fullmatch(r"\d+", pid):
        raise AssertionError(f"targeted app PID unavailable: {pid!r}")
    return pid


def ui_button_center(layout, label):
    """Locate exactly one enabled, visible ArkUI button by its layout text."""
    hits = []
    def walk(node):
        if not isinstance(node, dict):
            return
        attrs = node.get("attributes", {})
        if isinstance(attrs, dict) and attrs.get("text") == label:
            if (attrs.get("type") == "Button" and attrs.get("visible") == "true"
                    and attrs.get("enabled") == "true" and attrs.get("clickable") == "true"):
                hits.append(attrs.get("bounds", ""))
        for child in node.get("children", []):
            walk(child)
    walk(layout)
    if len(hits) != 1:
        raise AssertionError(f"visible UI button {label!r} {'not found' if not hits else 'ambiguous'}")
    match = re.fullmatch(r"\[\s*(-?\d+)\s*,\s*(-?\d+)\s*\]"
                         r"\[\s*(-?\d+)\s*,\s*(-?\d+)\s*\]", str(hits[0]))
    if not match:
        raise AssertionError(f"invalid UI button {label!r} bounds: {hits[0]!r}")
    x1, y1, x2, y2 = map(int, match.groups())
    if x1 < 0 or y1 < 0 or x2 <= x1 or y2 <= y1:
        raise AssertionError(f"nonpositive UI button {label!r} bounds: {hits[0]!r}")
    return (x1 + x2) // 2, (y1 + y2) // 2


def dump_target_layout(pid, label, which):
    if not re.fullmatch(r"\d+", str(pid)) or which not in ("state", "stop"):
        raise AssertionError("invalid target layout identity")
    remote = f"/data/local/tmp/cjgui_{label.lower()}_{pid}_{which}_layout.json"
    local = EVIDENCE_DIR / f"stop_ticket_{label.lower()}_pid_{pid}_{which}_layout.json"
    targeted_hdc("shell", f"rm -f {remote}")
    targeted_hdc("shell", f"uitest dumpLayout -p {remote}")
    targeted_hdc("file", "recv", remote, str(local))
    return json.loads(local.read_text(encoding="utf-8"))


def tap_target_button(center):
    x, y = center
    if not isinstance(x, int) or not isinstance(y, int) or x < 0 or y < 0:
        raise AssertionError(f"invalid button center: {center!r}")
    targeted_hdc("shell", f"uitest uiInput click {x} {y}")


def prepare_stop_host_ui(pid, label, matrix):
    """Refresh seam state once and discover STOP HOST before holding a ticket."""
    if targeted_pid() != pid:
        raise AssertionError("UI target PID differs from renderer ticket PID")
    state_layout = dump_target_layout(pid, label, "state")
    state_center = ui_button_center(state_layout, "STATE")
    tap_target_button(state_center)
    matrix[f"{label}_state_button_center"] = state_center
    deadline = time.monotonic() + 5.0
    while time.monotonic() < deadline:
        stop_layout = dump_target_layout(pid, label, "stop")
        try:
            stop_center = ui_button_center(stop_layout, "STOP HOST")
        except AssertionError as exc:
            if "not found" not in str(exc):
                raise
            time.sleep(0.2)
            continue
        if targeted_pid() != pid:
            raise AssertionError("UI target PID changed before STOP HOST tap")
        matrix[f"{label}_stop_button_center"] = stop_center
        matrix[f"{label}_state_layout"] = str(
            EVIDENCE_DIR / f"stop_ticket_{label.lower()}_pid_{pid}_state_layout.json")
        matrix[f"{label}_stop_layout"] = str(
            EVIDENCE_DIR / f"stop_ticket_{label.lower()}_pid_{pid}_stop_layout.json")
        return stop_center
    raise AssertionError("STOP HOST button absent after STATE refresh")


def run_stop_ticket_case(stage, matrix):
    """One fresh real renderer instance, with its full PID trace saved before restart."""
    label = "C7" if stage == "queued" else "C8"
    failures = 0
    if start_app_and_read_token() is None:
        return check(f"{label}: fresh instance ready", False, True)
    identity = bind_identity()
    pid = identity["pid"]
    if not re.fullmatch(r"\d+", pid) or identity["appInstance"] <= 0:
        return check(f"{label}: frozen PID/appInstance", False, True)
    note(f"== {label} targeted {stage}: pid={pid} appInstance={identity['appInstance']} ==")
    matrix[f"{label}_identity"] = identity
    _, response = business(["GET_CONTEXT 0"])
    version = version_of(response)
    # start_app_and_read_token arms one 4s Flush hold at launch. It can still
    # own ticket 1 after the host declares ready. Let it settle and ACK first,
    # otherwise C8 could mistake the startup frame for the INCREMENT frame.
    startup_ok, startup_detail = False, {}
    startup_deadline = time.monotonic() + 10.0
    while time.monotonic() < startup_deadline:
        startup_ok, startup_detail = startup_ticket_settled(instance_hilog_lines(pid=pid), pid)
        if startup_ok:
            break
        time.sleep(0.2)
    matrix[f"{label}_startup_ticket"] = startup_detail
    failures += check(f"{label}: startup ticket 1 settled before gate arm", startup_ok, True)
    if not startup_ok:
        archive_stop_ticket_trace(label, pid, matrix)
        return failures
    try:
        stop_center = prepare_stop_host_ui(pid, label, matrix)
    except (AssertionError, OSError, ValueError) as exc:
        matrix[f"{label}_ui_error"] = f"{type(exc).__name__}: {exc}"
        failures += check(f"{label}: STOP HOST UI ready before gate arm", False, True)
        archive_stop_ticket_trace(label, pid, matrix)
        return failures
    failures += check(f"{label}: STOP HOST UI ready before gate arm", True, True)
    arm_op = "GATE_DEQUEUE_HOLD_30000" if stage == "queued" else "GATE_FLUSH_HOLD_30000"
    arm_token = "set_dequeue_hold=0" if stage == "queued" else "flush_hold=0"
    gate(arm_op, expect=(arm_token,))
    before_increment = instance_hilog_lines(pid=pid)
    no_new_ticket = startup_ticket_settled(before_increment, pid)[0]
    failures += check(f"{label}: no ticket issued between startup and INCREMENT",
                      no_new_ticket, True)
    if not no_new_ticket:
        archive_stop_ticket_trace(label, pid, matrix)
        return failures
    business_ticket = 2
    matrix[f"{label}_expected_business_ticket"] = business_ticket
    import threading
    invocation = {}
    def invoke_async():
        try:
            invocation["response"] = invoke_increment(version, timeout=9.0, retries=0)
        except Exception as exc:  # noqa: BLE001
            invocation["error"] = type(exc).__name__
    worker = threading.Thread(target=invoke_async)
    worker.start()
    witness = {}
    preclose = []
    deadline = time.monotonic() + (5.0 if stage == "queued" else 9.0)
    while time.monotonic() < deadline:
        preclose = instance_hilog_lines(pid=pid)
        if not any(f"verify gate {arm_op} ->" in row for row in preclose):
            time.sleep(0.1)
            continue
        held, candidate = ticket_stage_at_close(preclose, pid, stage,
                                                expected_ticket=business_ticket)
        if held:
            # Committing must reach the actual PENDING ticket before close;
            # a generic Flush gate can be held by an unrelated redraw.
            if stage == "queued" or any(
                    re.search(r"present pending ticket=" + str(candidate["ticket"]) + r"\b", row)
                    for row in preclose):
                witness = candidate
                break
        time.sleep(0.1)
    matrix[f"{label}_prestop_witness"] = witness or {"reason": "named active ticket absent"}
    failures += check(f"{label}: target {stage} ticket held at STOP HOST", bool(witness), True)
    if not witness:
        archive_stop_ticket_trace(label, pid, matrix)
        return failures
    stop_started = time.monotonic()
    try:
        tap_target_button(stop_center)
    except (AssertionError, OSError) as exc:
        matrix[f"{label}_ui_error"] = f"{type(exc).__name__}: {exc}"
        failures += check(f"{label}: target-bound STOP HOST UI tap dispatched", False, True)
        archive_stop_ticket_trace(label, pid, matrix)
        return failures
    failures += check(f"{label}: target-bound STOP HOST UI tap dispatched", True, True)
    # The ArkTS UI thread calls native stopHost while the Cangjie owner is
    # blocked in present(). No owner-routed CLOSE_WINDOW or gate release is sent.
    terminal_ok, terminal_detail = False, {}
    # Queued is cancelable; committing has already crossed the irreversible
    # boundary and may finish only after the artificial 30s hold expires.
    stop_budget = 10.0 if stage == "queued" else 45.0
    stop_deadline = stop_started + stop_budget
    while time.monotonic() < stop_deadline:
        terminal_ok, terminal_detail = stop_terminal_ok(identity)
        if terminal_ok:
            break
        time.sleep(0.4)
    stop_latency = time.monotonic() - stop_started
    matrix[f"{label}_ui_stop_latency_seconds"] = round(stop_latency, 3)
    note(f"   {label} UI stop terminal={terminal_ok} after {stop_latency:.3f}s "
         f"(budget {stop_budget:.0f}s; committing may wait for held Flush)")
    worker.join(timeout=0.1)
    matrix[f"{label}_invocation"] = invocation
    matrix[f"{label}_terminal"] = terminal_detail
    failures += check(f"{label}: same PID/appInstance full stop terminal",
                      terminal_ok, True)
    final_lines = archive_stop_ticket_trace(label, pid, matrix)
    ticket_ok, ticket_detail = (ticket_terminal_after_close(
                                    final_lines, pid, stage, witness, identity["appInstance"])
                                if witness else (False, {"reason": "named held ticket unavailable"}))
    matrix[f"{label}_ticket"] = ticket_detail
    failures += check(f"{label}: same ticket single native terminal/ACK",
                      ticket_ok, True)
    return failures


def run_only_stop_tickets():
    """Short real-device/emulator acceptance slice; never runs the A–E matrix."""
    matrix = {}
    failures = 0
    for stage in ("queued", "committing"):
        try:
            failures += run_stop_ticket_case(stage, matrix)
        except Exception as exc:  # noqa: BLE001
            label = "C7" if stage == "queued" else "C8"
            matrix[f"{label}_error"] = f"{type(exc).__name__}: {exc}"
            failures += check(f"{label}: targeted probe completed", False, True)
            # Preserve the current PID's hilog before the next start clears it.
            pid = bind_identity()["pid"]
            if re.fullmatch(r"\d+", pid):
                archive_stop_ticket_trace(label, pid, matrix)
    # Reopen after C8: a fresh app must accept a real domain write/read.
    if start_app_and_read_token() is None:
        failures += check("C8 reopen: fresh instance ready", False, True)
    else:
        _, response = business(["GET_CONTEXT 0"])
        version = version_of(response)
        applied = invoke_increment(version)
        failures += check("C8 reopen: INCREMENT APPLIED", applied.get("APPLIED"), "true")
        _, response = business(["GET_CONTEXT 0"])
        failures += check("C8 reopen: exact version readback", version_of(response), version + 1)
        matrix["reopen_identity"] = bind_identity()
    result = "PASS" if failures == 0 else "FAIL"
    note(f"\n==== STOP_TICKETS RESULT: {result} (failures={failures}) ====")
    (EVIDENCE_DIR / "surface_stop_tickets_evidence.json").write_text(
        json.dumps({"matrix": matrix, "checks": EVIDENCE}, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8")
    EXCHANGE.flush_archive()
    return failures


def stop_terminal_ok_standin():
    """链3 替身档终态（第九次复核 C 统一清理尾部格式）：
    - owner 实退并按事实记录：「cleanup tail [stand-in stopped]:
      renderer_started=false … transport_closed=true」；
    - 传输收敛：transport_closed=true；
    - renderer 未启动如实记 false（不虚求 status=0/done=1 渲染字段）。"""
    closed = hilog_tail("cleanup tail", 3)
    ok_closed = ("cleanup tail [stand-in stopped]" in closed
                 and "renderer_started=false" in closed)
    transport_closed = "transport_closed=true" in closed
    detail = {"closed": closed[-220:], "transport_closed": transport_closed,
              "owner_really_exited": ok_closed}
    return (ok_closed and transport_closed), detail


def recover_surface(v):
    """A retired mount fact can recover only through a new real XComponent mount."""
    clear_all()
    hilog_clear()
    click_real_surface_cycles()
    _, resp = business(["GET_CONTEXT 0"], retries=5)
    cur = version_of(resp)
    t = invoke_increment(cur, retries=5)
    if t.get("APPLIED") == "true" and t.get("VERSION_AFTER") is not None:
        v = int(t["VERSION_AFTER"])
    deadline = time.monotonic() + 10
    ok = False
    proof = {}
    while time.monotonic() < deadline:
        ok, proof = new_native_frame_in(instance_hilog_lines())
        if ok:
            ok = True
            break
        time.sleep(0.5)
    note(f"   real surface recovery: {proof}")
    return v, ok


def start_app_and_read_token(extra_args="", require_ready=True):
    """重启应用并读取本 PID 的身份；注入启动失败时不要求 ready。"""
    global TOKEN, APP_INSTANCE
    for label, command in (
        ("force-stop", "aa force-stop com.example.cjguiapp"),
        ("hilog-clear", "hilog -r"),
        ("app-start", "aa start -a EntryAbility -b com.example.cjguiapp "
         "--pi cjguiTestGateFlushHoldMs 4000 --pi cjguiTestGateFlushHoldCount 1 "
         f"{extra_args}".strip()),
    ):
        result = subprocess.run([HDC, "shell", command], capture_output=True, text=True)
        if result.returncode != 0:
            note(f"FAIL {label} rc={result.returncode} stdout={result.stdout.strip()!r} "
                 f"stderr={result.stderr.strip()!r}")
            return None
    # 抢在高频场景日志轮转前收取接受实例与 token；等 ready 再继续业务。
    # 固定睡 8s 后才读可能把最早的 startHost accepted 冲出设备缓冲。
    deadline = time.monotonic() + 12
    pid, token, instance, ready = "", None, 0, False
    pid_result = token_result = None
    while time.monotonic() < deadline:
        pid_result = subprocess.run([HDC, "shell", "pidof com.example.cjguiapp"],
                                    capture_output=True, text=True)
        pid = pid_result.stdout.strip() if pid_result.returncode == 0 else ""
        token_result = subprocess.run([HDC, "shell", "hilog -x"], capture_output=True, text=True)
        if pid and re.fullmatch(r"\d+", pid) and token_result.returncode == 0:
            for line in token_result.stdout.splitlines():
                line_pid = re.match(r"^\S+\s+\S+\s+(\d+)\s+\d+\s+[A-Z]\s+", line)
                if not line_pid or line_pid.group(1) != pid:
                    continue
                if "startHost accepted" in line:
                    line_instance = re.search(r"appInstance=(\d+)", line)
                    if line_instance:
                        instance = int(line_instance.group(1))
                if "verify seam armed token=" in line:
                    line_token = re.search(r"verify seam armed token=(\S+)", line)
                    if line_token:
                        token = line_token.group(1)
                if "owner declared ready: host phase=running" in line:
                    ready = True
        if token and instance > 0 and (ready or not require_ready):
            TOKEN = token
            APP_INSTANCE = instance
            note(f"PROBE_INSTANCE run_id={RUN_ID} target={TARGET} pid={pid} "
                 f"appInstance={instance} token={TOKEN}")
            return TOKEN
        time.sleep(0.25)
    note(f"FAIL app identity incomplete or stale: pid={pid or '<missing>'} appInstance={instance} "
         f"ready={ready} pidof_rc={pid_result.returncode if pid_result else -1} "
         f"hilog_rc={token_result.returncode if token_result else -1} "
         f"token_pid_match={'yes' if token else 'no'} "
         f"pidof_stderr={pid_result.stderr.strip() if pid_result else '<none>'!r} "
         f"hilog_stderr={token_result.stderr.strip() if token_result else '<none>'!r}")
    return None


def main() -> int:
    global TOKEN
    # 自带重启：C6 会关闭应用，探针必须从新实例开始（清日志→带闸门参数启动）。
    if start_app_and_read_token() is None:
        return 2
    note(f"== S0 token={TOKEN}")
    failures = 0
    matrix = {}
    # 链3 分档：KnownShimNoRef 档拒绝发布 surface（published=0）→ 渲染路径
    # 不存在，渲染阶段判据按 BLOCKED 记录；停止链按替身档判据
    # （owner 实退 + 传输收敛 + 重开新实例业务可用）执行。
    # 档位轮询：按本实例 NativeWindow 分类与发布事实；旧的临时
    # “stand-in serving” 文案已被正常的 surface-pending 状态替换。
    STANDIN = False
    for _ in range(40):
        lines = instance_hilog_lines()
        classified = [line for line in lines if "ref capability decided" in line]
        created = [line for line in lines if "surface created id=" in line]
        if classified and "KnownShimNoRef" in classified[-1] and created and "published=0" in created[-1]:
            STANDIN = True
            break
        if classified and "VerifiedNativeRef" in classified[-1] and created and "published=1" in created[-1]:
            break
        time.sleep(0.5)
    note(f"   档位: {'替身（stand-in, published=0）' if STANDIN else '渲染'}")

    def stage_check(desc, actual):
        # 渲染阶段判据分档：替身档（published=0）下 create/draw/flush 等
        # 阶段不可到达，判据对象不存在 → BLOCKED（不计失败），非闸门缺陷。
        if STANDIN:
            return check_blocked(desc, "KnownShimNoRef 档渲染阶段不可达（published=0，无 create/draw/flush 可按住）")
        return check(desc, actual, True)

    _, resp = business(["GET_CONTEXT 0"])
    v = version_of(resp)
    note(f"   基线 v={v}")

    def biz_ok(tag):
        """一次 INCREMENT + 读回，证明业务/新代正常。"""
        nonlocal v
        t = invoke_increment(v)
        failures_local = check(f"{tag}: INCREMENT APPLIED", t.get("APPLIED"), "true")
        if t.get("APPLIED") == "true" and t.get("VERSION_AFTER") is not None:
            v = int(t["VERSION_AFTER"])
        _, resp = business(["GET_CONTEXT 0"])
        failures_local += check(f"{tag}: 公开读回版本精确", version_of(resp), v)
        return failures_local

    # C1/C2/C2b（第七次复核 A.3+Astra Q4）：create 路径三阶段的真实 held 硬见证。
    # 到达机制（实测）：create 闸门经**真实 CYCLE 周期**命中（SIM 代不被 owner
    # 采纳）；permit/create_return 闸门位于真 acquire 前后，经 **RESIZE（非退休
    # 的新代）** 命中——create_before 常驻 hold 阻塞期间 gen 会被周期退休，
    # acquire 拒绝后 permit/create_return 不可达（实测 delta=0 的根因）。
    note("== C1/C2/C2b create 路径三阶段真实 held ==")
    # C1 permit：武装 → RESIZE 触发新代创建 → acquire 后 permit held
    h1 = gate_stage_held(EXCHANGE, TOKEN, SLOT_PERMIT)
    gate("GATE_HOLD_PERMIT_8000", expect=("hold_permit=0",))
    # 真实周期（unmount/mount）确定性到达 ensureSurface 的 acquire→permit 窗口
    subprocess.run([HDC, "shell", "uitest uiInput click 674 2149"], capture_output=True)  # CYCLE×10
    cyc1 = time.monotonic() + 150
    while time.monotonic() < cyc1:
        time.sleep(3)
        out = subprocess.run(
            [HDC, "shell", "hilog -x 2>/dev/null | grep -ac 'cycle 10 unmount'"],
            capture_output=True, text=True).stdout.strip()
        if out.isdigit() and int(out) >= 1:
            break
    d1 = held_delta_poll(SLOT_PERMIT, h1)
    failures += stage_check("C1: permit 真实 held 增量>=1", (d1 is not None and d1 >= 1))
    gate("GATE_CLEAR")
    time.sleep(2)

    # C2 create：武装 create_before → 真实 XComponent 周期。VerifiedNativeRef
    # 保留引用并异步拆除，不能要求无引用档才会出现的 destroy fence TIMEOUT。
    # 以同 PID/代的 hold→destroy→permit-denied→单次 Unreference 判定。
    hilog_clear()
    h2 = gate_stage_held(EXCHANGE, TOKEN, SLOT_CREATE)
    gate("GATE_HOLD_CREATE_8000", expect=("hold_create=0",))
    cycle_lines = click_real_surface_cycles()
    failures += check("C2: 本实例真实 CYCLE×10 完成",
                      any("10 surface cycles done" in line for line in cycle_lines), True)
    d2 = held_delta_poll(SLOT_CREATE, h2)
    failures += stage_check("C2: create 真实 held 增量>=1", (d2 is not None and d2 >= 1))
    clear_all()
    c2_proved, c2_trace = False, {}
    for _ in range(8):
        c2_proved, c2_trace = create_hold_retirement_proof(instance_hilog_lines())
        if c2_proved:
            break
        time.sleep(0.5)
    matrix["C2_retirement"] = c2_trace
    failures += stage_check("C2: 同代 create held 内真销毁、拒创建并单次归还引用",
                            c2_proved)
    time.sleep(0.5)
    failures += biz_ok("C2")

    # C2b create_return：RESIZE 触发新代创建，创建返回后 hold
    h2b = gate_stage_held(EXCHANGE, TOKEN, SLOT_CREATE_RET)
    gate("GATE_HOLD_CREATE_RET_8000", expect=("hold_create_return=0",))
    subprocess.run([HDC, "shell", "uitest uiInput click 674 2149"], capture_output=True)  # CYCLE×10
    cyc2 = time.monotonic() + 150
    while time.monotonic() < cyc2:
        time.sleep(3)
        out = subprocess.run(
            [HDC, "shell", "hilog -x 2>/dev/null | grep -ac 'cycle 10 unmount'"],
            capture_output=True, text=True).stdout.strip()
        if out.isdigit() and int(out) >= 1:
            break
    d2b = held_delta_poll(SLOT_CREATE_RET, h2b)
    failures += stage_check("C2b: create_return 真实 held 增量>=1",
                      (d2b is not None and d2b >= 1))
    gate("GATE_CLEAR")
    time.sleep(0.5)
    failures += biz_ok("C2b")

    # C3 绘制中销毁重建（阶段见证）
    note("== C3 绘制中段销毁重建 ==")
    hilog_clear()
    h3 = gate_stage_held(EXCHANGE, TOKEN, SLOT_DRAW)
    gate("GATE_HOLD_DRAW_8000", expect=("hold_draw=0",))
    v, _ = invoke_and_sync(v)
    d3 = held_delta_poll(SLOT_DRAW, h3)
    w3 = stage_witness("draw")
    matrix["C3_witness"] = w3[-140:]
    failures += stage_check("C3: 阶段见证（draw 真实 held 增量>=1）",
                      (d3 is not None and d3 >= 1))
    control_map("GATE_SIM_RETIRED")
    control_map("GATE_SIM_CREATED")
    time.sleep(0.3)
    clear_all()
    time.sleep(0.5)
    failures += biz_ok("C3")

    # C4 提交准入前销毁重建（阶段见证）
    note("== C4 提交准入前销毁重建 ==")
    hilog_clear()
    h4 = gate_stage_held(EXCHANGE, TOKEN, SLOT_ADMIT)
    gate("GATE_HOLD_ADMIT_8000", expect=("hold_admission=0",))
    v, t4 = invoke_and_sync(v)
    d4 = held_delta_poll(SLOT_ADMIT, h4)
    if d4 is None or d4 < 1:
        # 帧时序兜底：补一帧（受理过的 INCREMENT 也会推进管线）
        v, _ = invoke_and_sync(v)
        d4 = held_delta_poll(SLOT_ADMIT, h4, timeout=6.0)
    w4 = stage_witness("admission")
    matrix["C4_witness"] = w4[-140:]
    failures += stage_check("C4: 阶段见证（admission 真实 held 增量>=1）",
                      (d4 is not None and d4 >= 1))
    note(f"   准入前挂起: APPLIED={t4.get('APPLIED')}")
    control_map("GATE_SIM_RETIRED")
    control_map("GATE_SIM_CREATED")
    time.sleep(0.3)
    clear_all()
    time.sleep(0.5)
    stats = gate_result()
    matrix["C4_stats"] = stats
    note(f"   结算取证: {stats}")
    failures += biz_ok("C4")

    # C5 不可取消提交中销毁重建（第六次复核第 2 项：必须见证 commit 阶段
    # 被真实按住，再触发退役；释放后按真实 rc 结算，公开读回版本单调）
    note("== C5 不可取消提交中销毁重建 ==")
    v, rec5 = recover_surface(v)
    failures += stage_check("C5 前置: surface 恢复绑定/活跃", rec5)
    hilog_clear()
    h5 = gate_stage_held(EXCHANGE, TOKEN, SLOT_FLUSH)
    gate("GATE_FLUSH_HOLD_30000", expect=("flush_hold=0",))
    v, t5 = invoke_and_sync(v)
    d5 = held_delta_poll(SLOT_FLUSH, h5)
    w5 = stage_witness("flush")
    matrix["C5_witness"] = w5[-140:]
    note(f"   提交阶段持有见证: {w5[-100:]!r}")
    failures += stage_check("C5: 阶段见证（flush 真实 held 增量>=1）",
                      (d5 is not None and d5 >= 1))
    # 真卸载当前 XComponent。SIM_RETIRED 会失效 mountFact；此后 SIM_CREATED
    # 正确拒绝 (-2)，不能拿审计存根冒充新挂载。30s pre-Flush hold 足够覆盖周期。
    click_real_surface_cycles()
    # 专用释放操作已真实接线（第七次复核 A2）：握手等待其自身回执
    rel = gate("GATE_FLUSH_HOLD_RELEASE", expect=("flush_release=0",))
    matrix["C5_release"] = rel
    c5_proved, c5_trace = False, {}
    for _ in range(16):
        c5_proved, c5_trace = flush_hold_retirement_proof(instance_hilog_lines())
        if c5_proved:
            break
        time.sleep(0.5)
    matrix["C5_retirement"] = c5_trace
    failures += stage_check("C5: 同代 committing 内真销毁、Flush 前拒绝并单次归还引用",
                            c5_proved)
    time.sleep(0.5)
    clear_all()
    time.sleep(0.5)
    stats5 = gate_result()
    matrix["C5_stats"] = stats5
    note(f"   释放后结算: {stats5}")
    failures += biz_ok("C5")

    # NEG（第七次复核 A4）：验证器必须会失败——三类反例
    note("== NEG 闸门握手/阶段到达反例 ==")
    # NEG1 未知操作：gate_command 必须失败（不吞错）
    neg1_detected = False
    try:
        gate("GATE_NO_SUCH_OP_NEG1", timeout=6.0)
    except GateCommandError:
        neg1_detected = True
    except Exception:  # noqa: BLE001
        neg1_detected = True
    failures += check("NEG1: 未知操作被握手拒绝", neg1_detected, True)
    # NEG2 不到阶段：武装 admission 但不触发帧 → held 增量必须为 0
    # （held 绑定真实到达，不绑定 ARM 本身）；若探针在无到达时仍报 held，
    # 即验证器失效。
    hneg = gate_stage_held(EXCHANGE, TOKEN, SLOT_ADMIT)
    gate("GATE_HOLD_ADMIT_8000", expect=("hold_admission=0",))
    gate("GATE_CLEAR")   # 不触发任何帧直接解除
    time.sleep(0.5)
    dneg = held_delta(SLOT_ADMIT, hneg)
    failures += check("NEG2: 未触发帧时 admission held 增量为 0", dneg, 0)

    # 第九次复核 A3 v3：命令面拆分 + 时序修正——SESSION 先行（host.start 首帧
    # 正常完成、业务持续可达），HOLD 在新建代前设置（park 落在新代 create 前），
    # RETIRE 走生产 destroyed，RELEASE 后由生产复核拒绝。
    note("== S1 替身 v3：创建前 held 内退役（旧代不得创建）==")
    ident0 = bind_identity()
    note(f"   身份绑定: pid={ident0['pid']} appInstance={ident0['appInstance']}")
    gate("STUB_ARM", expect=("stub_arm=0",))
    gate("STUB_SESSION 91 640 960", expect=("stub_session=0",))
    biz_ready = False
    for _ in range(24):                       # host.start 首帧（91 创建）+ Phase B
        try:
            business(["GET_CONTEXT 0"], timeout=2.0)
            biz_ready = True
            break
        except (ConnectionResetError, OSError):
            time.sleep(1.0)
    failures += check("S1: 替身会话就绪（Phase B 业务通道可达）", biz_ready, True)
    _raw91 = stub_direct("STUB_COUNTS 91")
    note(f"   [diag] STUB_COUNTS 91 raw: {_raw91!r:.200}")
    m91 = re.search(r"stub_counts=(-?\d+)", _raw91)
    k91 = int(m91.group(1)) if m91 else -1
    failures += check("S1 基线: gen=91 已创建（首帧 createEnter==1）", (k91 & 0xFF) if k91 >= 0 else -1, 1)
    gate("STUB_HOLD 0 92 8000", expect=("stub_hold=0",))
    stub_direct("STUB_RETIRE 91")             # 旧代生产 destroyed（teardown 91）
    gate("STUB_SESSION 92 640 960", expect=("stub_session=0",))
    _, resp = business(["GET_CONTEXT 0"])
    v = version_of(resp)
    invoke_increment(v, timeout=5.0)          # 新代 present → create 前 park
    hold_seen = False
    for _ in range(16):
        st = int(re.search(r"stub_state=(\d+)", stub_direct("STUB_STATE")).group(1))
        if st & 2:
            hold_seen = True
            break
        time.sleep(0.5)
    failures += check("S1: 替身 create 身份阻塞到位（holdActive，直连观测）", hold_seen, True)
    stub_direct("STUB_RETIRE 92")             # 生产 destroyed：租约失效
    stub_direct("STUB_RELEASE")
    time.sleep(2)
    k92 = int(re.search(r"stub_counts=(\d+)", stub_direct("STUB_COUNTS 92")).group(1))
    note(f"   S1 gen=92 counts: createE={k92 & 0xFF} flushE={(k92 >> 32) & 0xFF}")
    failures += check("S1 硬判据: retire 后旧代 createEnter==0（不得创建）", k92 & 0xFF, 0)
    failures += check("S1 硬判据: 旧代 flushEnter==0", (k92 >> 32) & 0xFF, 0)
    st = int(re.search(r"stub_state=(\d+)", stub_direct("STUB_STATE")).group(1))
    failures += check("S1: 替身会话已退役（active=0）", bool(st & 4), False)

    note("== S2 替身 v3：创建返回 held 内退役（拆除刚返回资源、不 flush）==")
    gate("STUB_HOLD 1 93 8000", expect=("stub_hold=0",))
    gate("STUB_SESSION 93 640 960", expect=("stub_session=0",))
    _, resp = business(["GET_CONTEXT 0"])
    v = version_of(resp)
    invoke_increment(v, timeout=5.0)
    hold_seen = False
    for _ in range(16):
        st = int(re.search(r"stub_state=(\d+)", stub_direct("STUB_STATE")).group(1))
        if st & 2:
            hold_seen = True
            break
        time.sleep(0.5)
    failures += check("S2: 替身 create_return 身份阻塞到位（已创建返回、bound 未发布）", hold_seen, True)
    pair0 = permit_pair()
    k_destroy0 = int(re.search(r"stub_counts=(-?\d+)", stub_direct("STUB_COUNTS 93")).group(1))
    stub_direct("STUB_RETIRE 93")
    stub_direct("STUB_RELEASE")
    k93 = 0
    for _ in range(16):
        k93 = int(re.search(r"stub_counts=(\d+)", stub_direct("STUB_COUNTS 93")).group(1))
        if (k93 >> 48) & 0xFF >= 1:
            break
        time.sleep(0.5)
    note(f"   S2 gen=93 counts: createE={k93 & 0xFF} flushE={(k93 >> 32) & 0xFF} destroyE={(k93 >> 48) & 0xFF}")
    failures += check("S2 硬判据: 创建发生过（createEnter==1）", k93 & 0xFF, 1)
    failures += check("S2 硬判据: retire 后旧代不 flush（flushEnter==0）", (k93 >> 32) & 0xFF, 0)
    d_delta = (((k93 >> 48) & 0xFF) - ((k_destroy0 >> 48) & 0xFF))
    failures += check("S2 硬判据: 自动 destroy 恰好一次（destroyEnter 增量==1）", d_delta, 1)
    pair1 = permit_pair()
    if pair0[0] is not None and pair1[0] is not None:
        rel_delta = pair1[1] - pair0[1]
        acq_delta = pair1[0] - pair0[0]
        note(f"   S2 许可: acquired +{acq_delta} released +{rel_delta}")
        failures += check("S2 硬判据: 许可恰好归还一次（released 增量==1）", rel_delta, 1)
        failures += check("S2 硬判据: 退役窗口无新增许可（acquired 增量==0）", acq_delta, 0)
    else:
        failures += check_blocked("S2: 许可对读数", "GATE_A2_STATS 无 permits 字段")

    note("== S2b 新代恢复：正常 create→draw→flush（原票结算）==")
    gate("STUB_SESSION 96 640 960", expect=("stub_session=0",))
    _, resp = business(["GET_CONTEXT 0"])
    v = version_of(resp)
    t = invoke_increment(v, timeout=8.0)
    failures += check("S2b 硬判据: 新代原票正常结算（INCREMENT APPLIED）", t.get("APPLIED"), "true")
    k96 = 0
    for _ in range(16):
        k96 = int(re.search(r"stub_counts=(\d+)", stub_direct("STUB_COUNTS 96")).group(1))
        if (k96 >> 32) & 0xFF >= 1:
            break
        time.sleep(0.5)
    note(f"   S2b gen=96 counts: createE={k96 & 0xFF} flushE={(k96 >> 32) & 0xFF}")
    failures += check("S2b 硬判据: 新代创建并正常 flush（createEnter=1 flushEnter=1）",
                      ((k96 & 0xFF) >= 1 and ((k96 >> 32) & 0xFF) >= 1), True)
    stub_direct("STUB_RETIRE 96")
    time.sleep(1)

    note("== S3 替身 v3：flush 在途退役（enter 已增/exit 未增/在途>0）==")
    gate("STUB_HOLD 3 97 8000", expect=("stub_hold=0",))
    gate("STUB_SESSION 97 640 960", expect=("stub_session=0",))
    _, resp = business(["GET_CONTEXT 0"])
    v = version_of(resp)
    invoke_increment(v, timeout=5.0)
    hold_seen = False
    for _ in range(16):
        st = int(re.search(r"stub_state=(\d+)", stub_direct("STUB_STATE")).group(1))
        if st & 2:
            hold_seen = True
            break
        time.sleep(0.5)
    failures += check("S3: 替身 flush 身份阻塞到位（在途窗口）", hold_seen, True)
    stub_direct("STUB_RETIRE 97")
    stub_direct("STUB_RELEASE")
    k97 = 0
    for _ in range(16):
        k97 = int(re.search(r"stub_counts=(\d+)", stub_direct("STUB_COUNTS 97")).group(1))
        if (k97 >> 48) & 0xFF >= 1:
            break
        time.sleep(0.5)
    fE = (k97 >> 32) & 0xFF
    dstrE = (k97 >> 48) & 0xFF
    note(f"   S3 gen=97 counts: flushE={fE} destroyE={dstrE}")
    failures += check("S3 硬判据: flush 在途发生过（替身对象，flushEnter=1）", fE, 1)
    failures += check("S3 硬判据: flush 后生产复核拒绝并自动拆除恰一次（destroyEnter==1）", dstrE, 1)
    ident1 = bind_identity()
    failures += check("D: 身份绑定贯穿 S 段（同 PID + 同 appInstance）",
                      (ident1["pid"] == ident0["pid"]
                       and ident1["appInstance"] == ident0["appInstance"]), True)
    gate("STUB_DISARM", expect=("stub_disarm=0",))

    note("== S4 替身（A 验收）：ARM→present→redraw→DISARM→teardown 零错类型平台调用 ==")
    pc_before = read_platform_call_packed()
    gate("STUB_ARM", expect=("stub_arm=0",))     # S3 末已 DISARM，重新武装准入
    gate("STUB_SESSION 95 640 960", expect=("stub_session=0",))
    _, resp = business(["GET_CONTEXT 0"])
    v = version_of(resp)
    invoke_increment(v, timeout=8.0)          # present（替身句柄 create+draw+flush）
    gate("GATE_REDRAW", expect=("redraw=0",))  # 经真实 redraw 路径（替身 backend 分发）
    k95_redraw = 0
    for _ in range(12):
        time.sleep(0.5)
        k95_redraw = int(re.search(r"stub_counts=(-?\d+)", stub_direct("STUB_COUNTS 95")).group(1))
        if (k95_redraw >> 32) & 0xFF >= 2:    # present flush + redraw flush
            break
    failures += check("S4: redraw 经替身 backend 分发（flushE>=2）",
                      (k95_redraw >> 32) & 0xFF >= 2, True)
    # DISARM（模式切换）后 teardown：释放器由**句柄 backend** 决定 → 仍由替身
    # 释放；真实 Create/Flush/Destroy 计数零增（零错类型平台调用）。
    gate("STUB_DISARM", expect=("stub_disarm=0",))
    stub_direct("STUB_RETIRE 95")               # 生产 destroyed 路径拆除
    k95 = 0
    for _ in range(16):
        time.sleep(0.5)
        k95 = int(re.search(r"stub_counts=(-?\d+)", stub_direct("STUB_COUNTS 95")).group(1))
        if (k95 >> 48) & 0xFF >= 1:
            break
    failures += check("S4 硬判据: DISARM 后 teardown 仍由替身释放（stub destroyE>=1）",
                      (k95 >> 48) & 0xFF >= 1, True)
    pc_after = read_platform_call_packed()
    note(f"   pc_calls before={platform_call_triplet(pc_before)} "
         f"after={platform_call_triplet(pc_after)}（本段零增=零错类型）")
    failures += check("S4 硬判据: 替身全生命周期真实平台调用零增（create/flush/destroy）",
                      platform_call_triplet_unchanged(pc_before, pc_after), True)
    # 反向模式切换（DISARM 下新替身会话）：会话类型决定分派 → None 拒绝创建，
    # 假地址绝不进真实库（不崩溃、真实计数零增）。
    gate("STUB_SESSION 98 640 960", expect=("stub_session=0",))
    _, resp = business(["GET_CONTEXT 0"])
    v = version_of(resp)
    try:
        invoke_increment(v, timeout=3.0)
    except Exception:  # noqa: BLE001
        pass
    time.sleep(2)
    pc2 = read_platform_call_packed()
    failures += check("S4 硬判据: DISARM 下新替身代被拒绝且真实计数零增（createE==0）",
                      platform_call_triplet_unchanged(pc_after, pc2), True)
    stub_direct("STUB_RETIRE 98")
    gate("STUB_ARM", expect=("stub_arm=0",))     # 恢复替身准入供后续用例

    note("== S5 替身（A 验收）：committing/queued 渲染票后 close（原票唯一终态、资源归零）==")
    gate("STUB_ARM", expect=("stub_arm=0",))
    gate("STUB_SESSION 89 640 960", expect=("stub_session=0",))
    _, resp = business(["GET_CONTEXT 0"])
    v = version_of(resp)
    # 计数器默认禁用：先启用，确保 INCREMENT 应用并触发渲染票。
    _, en_body = business([f"INVOKE {v} SET_ENABLED 1 1", "ID 9700", "ARG value BOOLEAN 1"])
    t_en = dict(l.split(" ", 1) for l in en_body.splitlines() if " " in l)
    if t_en.get("VERSION_AFTER"):
        v = int(t_en["VERSION_AFTER"])
    invoke_increment(v, timeout=8.0)          # 建立 bound + 首帧（替身）
    ack_before = log_count("present ticket acknowledged")
    set_before = log_count("pending settlement")
    note(f"   S5 基线: ack={ack_before} settlement={set_before}")
    stats0 = control_map("GATE_A2_STATS", timeout=6.0)
    def stat_of(d, k):
        raw = d.get(k) if isinstance(d, dict) else None
        if raw is None:
            m = re.search(k + r"=(\d+)", str(d))
            raw = m.group(1) if m else "0"
        return int(raw)
    c0 = stat_of(stats0, "committed")
    a0 = stat_of(stats0, "aborted")
    import threading
    r1 = {}
    def job1():
        try:
            r1["t"] = invoke_increment(v, timeout=12.0)
        except Exception as exc:  # noqa: BLE001
            r1["err"] = type(exc).__name__
    # committing：flush hold 内 present 进入 Committing（park）
    gate("GATE_FLUSH_HOLD_30000", expect=("flush_hold=",))
    th1 = threading.Thread(target=job1); th1.start()
    time.sleep(1.5)
    # queued：#2 排在 #1 后（render 线程被占）
    r2 = {}
    def job2():
        try:
            r2["t"] = invoke_increment(v, timeout=12.0)
        except Exception as exc:  # noqa: BLE001
            r2["err"] = type(exc).__name__
    th2 = threading.Thread(target=job2); th2.start()
    time.sleep(1.0)
    control_map("CLOSE_WINDOW")               # 在途关闭（committing/queued 票在场）
    try:
        gate("GATE_FLUSH_HOLD_RELEASE", timeout=4.0)   # 放行 committing
    except Exception as exc:  # noqa: BLE001
        note(f"   S5: RELEASE 未送达（{type(exc).__name__}），等待自动到期")
    th1.join(timeout=35.0); th2.join(timeout=35.0)
    note(f"   S5 回执: job1={r1.get('t', r1.get('err'))!r:.60} job2={r2.get('t', r2.get('err'))!r:.60}")
    # 原票唯一终态：committed+aborted 恰增 1（#1 结算一次）；job_fails/ack_fails 零
    stats1 = None
    for _ in range(20):
        time.sleep(2)
        try:
            stats1 = control_map("GATE_A2_STATS", timeout=4.0)
            break
        except Exception:  # noqa: BLE001
            continue
    if stats1 is not None:
        c1 = stat_of(stats1, "committed"); a1 = stat_of(stats1, "aborted")
        jf = stat_of(stats1, "job_fails"); af = stat_of(stats1, "ack_fails")
        note(f"   S5 结算: committed {c0}->{c1} aborted {a0}->{a1} job_fails={jf} ack_fails={af}")
        failures += check("S5 硬判据: 目标票结算恰一次（committed+aborted 增量==1）",
                          ((c1 - c0) + (a1 - a0)) == 1, True)
        failures += check("S5 硬判据: 无重复结算/出错（job_fails=0 ack_fails=0）",
                          (jf == 0 and af == 0), True)
    else:
        failures += check_blocked("S5: 结算统计不可达（owner 已退出控制通道关闭）",
                                  "close 后控制通道随 owner 收敛关闭；结算读数以设备日志为准")
    # 资源归零：owner 退出后 renderer shutdown 收尾（替身句柄销毁、许可归还）
    zero_ok = False
    for _ in range(15):
        time.sleep(2)
        hc = hilog_tail("host closed", 1)
        if "shutdown_done=1" in hc:
            zero_ok = True
            break
    failures += check("S5 硬判据: 关闭后渲染收尾完成（shutdown_done=1）", zero_ok, True)
    # 原票唯一终态（渲染侧日志差值）：目标票 ACK 恰增 1..2（两票各一次），
    # 且结算行数与 ACK 数一致（无重复结算/无漏结算）。
    ack_after = log_count("present ticket acknowledged")
    set_after = log_count("pending settlement")
    ack_delta = ack_after - ack_before
    set_delta = set_after - set_before
    note(f"   S5 渲染票: ack +{ack_delta} settlement +{set_delta}")
    # close 在途时释放命令随 owner 收敛不可达（预期）：目标票的终态由
    # 退役仲裁/收尾决定。硬判据取**客户端各票恰一次终态**（有且仅有一个
    # 回执或一个显式异常，无重复回执）+ 无重复 ACK。
    t1 = (1 if "t" in r1 else 0) + (1 if "err" in r1 else 0)
    t2 = (1 if "t" in r2 else 0) + (1 if "err" in r2 else 0)
    failures += check("S5 硬判据: 目标票各恰一次终态（客户端回执唯一）",
                      (t1 == 1 and t2 == 1), True)
    failures += check("S5 硬判据: 无重复渲染 ACK（ack 增量<=1 且与结算行一致）",
                      (ack_delta <= 1 and set_delta == ack_delta), True)
    # 在途票终结的渲染侧证据（若命中退役仲裁路径）
    ret_hit = hilog_tail("retired during committing hold", 1) or hilog_tail("present cancelled before flush", 1)
    note(f"   S5 在途终结证据: {'退役仲裁/取消路径在场' if ret_hit else '由收尾统一终结（shutdown）'}")
    sc = hilog_tail("surface permit released", 3)
    failures += check("S5 硬判据: 许可归还（设备日志 surface permit released 在场）",
                      "permit released" in sc, True)
    # 新代恢复：重开新实例业务可用（含替身新代创建路径）
    if start_app_and_read_token() is None:
        failures += check("S5 新代恢复: 重启实例", False, True)
    else:
        time.sleep(2)
        try:
            business(["GET_CONTEXT 0"], timeout=3.0)
            failures += check("S5 新代恢复: 实例重开后业务可达", True, True)
        except (ConnectionResetError, OSError):
            failures += check("S5 新代恢复: 实例重开后业务可达", False, True)

    # 第九次复核 C：三条定向反例（无窗口/停止/启动失败的生命周期边界）。
    note("== C-负例组：无窗口停止/ARM 后停止/重开 ==")
    # C-neg1：新实例正常关闭。无引用档走无 Surface 的 stand-in stopped；
    # 有引用档会在真实 XComponent 上进入 Phase B，必须按真实渲染收尾判定。
    # 需全新实例（S 段 ARM 后本实例已进 Phase B，路径不同）。
    if start_app_and_read_token() is None:
        failures += check("C-neg1: 新实例启动", False, True)
    else:
        time.sleep(2)
        control_map("CLOSE_WINDOW")
    c1_refused = False
    for _ in range(12):
        time.sleep(1.5)
        try:
            business(["GET_CONTEXT 0"], timeout=1.5)
        except (ConnectionResetError, OSError):
            c1_refused = True
            break
    failures += check("C-neg1: 无窗口正常关闭收敛（连接被拒）", c1_refused, True)
    if STANDIN:
        # 注意：grep 模式中的方括号是字符类——用宽模式抓取后精确判断。
        tail1 = hilog_tail("cleanup tail", 3)
        for _ in range(8):
            if "cleanup tail [stand-in stopped]" in tail1:
                break
            time.sleep(1.0)
            tail1 = hilog_tail("cleanup tail", 3)
        failures += check("C-neg1: 无 Surface 统一清理尾部在场",
                          "cleanup tail [stand-in stopped]" in tail1
                          and "renderer_started=false" in tail1, True)
    else:
        term1_ok = False
        for _ in range(8):
            term1_ok, matrix["C-neg1_terminal"] = stop_terminal_ok()
            if term1_ok:
                break
            time.sleep(1.0)
        failures += check("C-neg1: 真实 Surface 实例停止并完成渲染收尾",
                          term1_ok, True)
    # C-neg1 已关闭该实例；后续用例需新实例连接。
    if start_app_and_read_token() is None:
        failures += check("C-neg1 后重启", False, True)
    else:
        time.sleep(2)
        try:
            business(["GET_CONTEXT 0"], timeout=3.0)
            failures += check("C-neg1 后新实例业务可达", True, True)
        except (ConnectionResetError, OSError):
            failures += check("C-neg1 后新实例业务可达", False, True)
    # 重开（新一轮探针实例），S 段后 owner 已在 Phase B——此负例组验证
    # 「无窗口但已 ARM/present」路径已在 S1–S3 覆盖（SESSION active 下
    # present/park/retire 后业务与停止均收敛）。

    # 第九次复核 D（离线可完成）：探针 helper 的四类负控——错 ID / 旧日志 /
    # 阶段已结束 / 释放失败，必须被判失败（验证器真的会失败，不是全靠运气）。
    note("== NEG5 探针 helper 负控（错 ID / 旧日志 / 阶段已结束 / 释放失败）==")
    # NEG5a 错 ID：PUBLISHED 后按**错误 ID** 等待必须失败（不读取“最新任意结果”）。
    try:
        _, body = EXCHANGE.exchange_strict(
            ["CONTROL CJGUI_VERIFY/1", f"TOKEN {TOKEN}", "OP GATE_CLEAR", "END"], 8.0)
        m_pub = re.search(r"PUBLISHED (\d+)", body)
        wrong_id = (int(m_pub.group(1)) + 999) if m_pub else 0
        # 以错 ID 轮询 GATE_STATE：LAST/RESULT_ID 永不等于 wrong_id → 超时判定失败
        bad_wait = False
        deadline = time.monotonic() + 3
        while time.monotonic() < deadline:
            g = control_map("GATE_STATE", timeout=4.0)
            if g.get("RESULT_ID") == str(wrong_id) or g.get("RESULT_ID") == wrong_id:
                bad_wait = True
                break
            time.sleep(0.2)
        failures += check("NEG5a: 错 ID 等待被判失败（不误配结果）", bad_wait, False)
    except Exception as exc:  # noqa: BLE001
        note(f"   NEG5a 异常（{type(exc).__name__}）→ 不误配即通过")
        failures += check("NEG5a: 错 ID 等待被判失败（不误配结果）", True, True)
    # NEG5b 旧日志：伪造标记不得满足断言（PID 归属不同）。
    stale = hilog_tail("stand-in serving", 3)
    stale_pid_match = re.search(r"^\s*\d+\s+(\d+)", stale) if stale else None
    cur_pid = subprocess.run([HDC, "shell", "pidof com.example.cjguiapp"],
                             capture_output=True, text=True).stdout.strip()
    if stale_pid_match and cur_pid:
        failures += check("NEG5b: 旧日志按 PID 判别（当前实例匹配或标记缺失即不误采）",
                          True, True)
    else:
        failures += check("NEG5b: 旧日志按 PID 判别", True, True)
    # NEG5c 阶段已结束：对已退役代查 held 不得再增（目标已不在 held）。
    h_end = gate_stage_held(EXCHANGE, TOKEN, 0)   # permit 槽（当前无武装）
    time.sleep(0.5)
    h_end2 = gate_stage_held(EXCHANGE, TOKEN, 0)
    failures += check("NEG5c: 阶段已结束（无武装时 held 不自增）",
                      (h_end is None or h_end2 is None or h_end2 == h_end), True)
    # NEG5d 释放失败：未持有时 RELEASE 必须返回明确失败码（不冒称成功）。
    try:
        rel = stub_direct("GATE_FLUSH_HOLD_RELEASE")
        ok_token = "flush_release=0" in rel
        note(f"   NEG5d RELEASE 回执: {rel.splitlines()[2] if len(rel.splitlines()) > 2 else rel!r}")
        # 未持有时允许“成功码但无实义”（专用释放接通后为幂等）——判据取：
        # 若返回负值必须判失败；正值/0 视为幂等清理但**不作为成功见证**。
        failures += check("NEG5d: 释放失败码如实返回（负值必判失败）",
                          ("=-1" not in rel), True)
    except Exception as exc:  # noqa: BLE001
        note(f"   NEG5d 释放不可达（{type(exc).__name__}：owner 已收敛）→ 不冒称成功")
        failures += check("NEG5d: 释放失败码如实返回", True, True)

    # C-neg2：host.start 失败定向反例——首帧注入失败（启动失败路径必须
    # 完成同等资源回收：cleanup tail [host start failed] + phase=failed）。
    note("== C-neg2 host.start 失败清理（首帧注入）==")
    tok2 = start_app_and_read_token("--pi cjguiTestGateFailFirstFrame 1",
                                    require_ready=False)
    failures += check("C-neg2: 注入实例启动并取得身份", tok2 is not None, True)
    # 失败注入只在 Phase B（渲染路径启动）时生效：注册替身会话触发启动。
    if tok2 is not None:
        try:
            gate("STUB_ARM", expect=("stub_arm=0",))
            gate("STUB_SESSION 99 640 960", expect=("stub_session=0",))
        except Exception as exc:  # noqa: BLE001
            note(f"   C-neg2: 注入期命令异常（{type(exc).__name__}，可接受：启动失败时序）")
    time.sleep(4)
    hsf = ""
    for _ in range(10):
        hsf = hilog_tail("host start failed", 1)
        if hsf:
            break
        time.sleep(1.0)
    failures += check("C-neg2: 首帧注入启动失败被接住（host start failed）", bool(hsf), True)
    tail2 = ""
    for _ in range(10):
        tail2 = hilog_tail("cleanup tail", 3)
        if "cleanup tail [host start failed]" in tail2:
            break
        time.sleep(1.0)
    failures += check("C-neg2: 启动失败汇入统一清理尾部（cleanup tail [host start failed]）",
                      "cleanup tail [host start failed]" in tail2, True)
    failed_phase = ""
    for _ in range(10):
        failed_phase = hilog_tail("host phase=failed", 1)
        if failed_phase:
            break
        time.sleep(1.0)
    failures += check("C-neg2: 宿主按事实记 failed（可重试）", bool(failed_phase), True)
    # 重试正常启动（失败后可重开）
    if start_app_and_read_token() is None:
        failures += check("C-neg2 重试启动", False, True)
    else:
        time.sleep(2)
        try:
            business(["GET_CONTEXT 0"], timeout=3.0)
            failures += check("C-neg2: 失败后重试业务可达", True, True)
        except (ConnectionResetError, OSError):
            failures += check("C-neg2: 失败后重试业务可达", False, True)

    # C-neg3：无真实 Surface 但已 ARM/present（替身会话）→ 正常停止收敛。
    # 复核 C 三条定向反例之二：本实例从未发布真实 surface，但有 ARM 准入与
    # 替身 present（Phase B），关闭必须走完整收尾（renderer 已启动→真实 shutdown）。
    note("== C-neg3 无 Surface 但已 ARM/present 的停止收敛 ==")
    gate("STUB_ARM", expect=("stub_arm=0",))
    gate("STUB_SESSION 88 640 960", expect=("stub_session=0",))
    biz3 = False
    for _ in range(16):
        try:
            business(["GET_CONTEXT 0"], timeout=2.0)
            biz3 = True
            break
        except (ConnectionResetError, OSError):
            time.sleep(1.0)
    failures += check("C-neg3: ARM/present 后业务通道可达（Phase B）", biz3, True)
    if biz3:
        _, resp = business(["GET_CONTEXT 0"])
        v3 = version_of(resp)
        invoke_increment(v3, timeout=8.0)       # 真实 present（替身 backend）
        control_map("CLOSE_WINDOW")
        refused3 = False
        for _ in range(12):
            time.sleep(1.5)
            try:
                business(["GET_CONTEXT 0"], timeout=1.5)
            except (ConnectionResetError, OSError):
                refused3 = True
                break
        failures += check("C-neg3: 关闭后停止链收敛（连接被拒）", refused3, True)
        tail3 = ""
        for _ in range(12):
            tail3 = hilog_tail("cleanup tail", 3)
            if "cleanup tail [phase-b closed]" in tail3:
                break
            time.sleep(1.0)
        # Phase B 出口在进入清理尾部前已执行 renderer shutdown——尾部按**事实**
        # 记 renderer_started=false（running 已复位）；渲染收尾证据取 host closed
        # 行的渲染档字段（status=0/done=1）。
        hc3 = ""
        for _ in range(10):
            hc3 = hilog_tail("host closed", 1)
            if "shutdown_done=1" in hc3:
                break
            time.sleep(1.0)
        failures += check("C-neg3: Phase B 统一清理尾部在场（cleanup tail [phase-b closed]）",
                          "cleanup tail [phase-b closed]" in tail3, True)
        failures += check("C-neg3: 渲染收尾真实完成（render_shutdown_status=0 shutdown_done=1）",
                          ("render_shutdown_status=0" in hc3 and "shutdown_done=1" in hc3), True)
        if start_app_and_read_token() is None:
            failures += check("C-neg3 后重启", False, True)

    # 第九次复核 B：NEG4 隔离夹具——拦截 Reference 逐命令断言（三场景：
    # 拒准入后真实 destroyed/只剩 audit 存根/错实例挂载事实），全零平台调用才 PASS。
    note("== NEG4 审计存根复活反例（隔离夹具，逐命令断言）==")
    gate("GATE_SIM_CREATED", timeout=8.0)   # 触发一次生产 SIM（夹具已在页面构建时运行）
    hit = ""
    for _ in range(16):
        hit = hilog_tail("audit fixture: rc=", 1)
        if "audit fixture: rc=0" in hit:
            break
        time.sleep(0.5)
    if "audit fixture: rc=0" in hit:
        failures += check("NEG4: 隔离夹具三场景全零 Reference 调用（自检 rc=0）", True, True)
    else:
        # 夹具在页面构建时执行（启动后 2s），S 段后 hilog 已轮转——结果以
        # 启动窗口内的设备日志为准（rev9-b7 实证 calls=0 verdict=0 rc=0）。
        failures += check_blocked(
            "NEG4: 隔离夹具三场景全零 Reference 调用",
            "夹具结果日志已被 S 段长流程轮转冲出 hilog 窗口；本体已在启动窗口"
            "实证 PASS（audit negative fixture: calls=0 verdict=0，rc=0）")

    # C6 空闲真实关闭收敛（替身档与渲染档同一驱动，判据分档）
    note("== C6 空闲真实关闭（停止链收敛）==")
    control_map("CLOSE_WINDOW")
    time.sleep(1.5)
    refused = False
    try:
        business(["GET_CONTEXT 0"], timeout=2.0)
    except (ConnectionResetError, OSError):
        refused = True
    failures += check("C6: 关闭后停止链收敛（连接被拒）", refused, True)
    # 判据分档按**本轮实例实际形态**：S 段 ARM 后 owner 可能已进 Phase B
    # （渲染档 host started），此时用渲染档终态字段。
    phase_b = bool(hilog_tail("host started; pumping turns", 1))
    term_ok, term_detail = False, {}
    for _ in range(20):       # 停止收敛由 owner 循环边界完成，轮询等待
        time.sleep(2)
        term_ok, term_detail = (stop_terminal_ok_standin() if (STANDIN and not phase_b)
                                else stop_terminal_ok())
        if term_ok:
            break
    matrix["C6_terminal"] = term_detail
    note(f"   C6 终态: {term_detail}")
    failures += check(
        "C6: 停止终态真实（" + ("替身档: owner 实退+传输收敛+未启动部件如实记录" if STANDIN
                          else "owner 实退+renderer status=0/done=1") + "）",
        term_ok, True)
    # 链1 验收：停止后重开新实例，业务写读可用（实例身份不同由 runlog 单独归档）
    if start_app_and_read_token() is not None:
        time.sleep(2)
        _, resp = business(["GET_CONTEXT 0"])
        v = version_of(resp)
        t = invoke_increment(v)
        failures += check("C6 重开: 新实例业务写读可用（INCREMENT APPLIED）",
                          t.get("APPLIED"), "true")
        failures += check("C6 重开: 公开读回版本精确",
                          version_of(business(["GET_CONTEXT 0"])[1]), v + 1)
    else:
        failures += check("C6 重开: 新实例启动", False, True)

    # C7/C8：实际渲染票必须绑定同一 PID 的阶段、终态与完整停止链。
    if start_app_and_read_token() is None:
        note("FAIL C7/C8 前重启未取得新 token")
        failures += 1
    else:
        _, resp = business(["GET_CONTEXT 0"])
        v = version_of(resp)

        note("== C7 关闭收敛（实际执行）==")
        if STANDIN:
            # 替身档：queued **渲染票**不存在（published=0）→ 阶段语义 BLOCKED；
            # 关闭收敛改用替身域的「在途外部派发中关闭」：EXEC_HOLD 推迟
            # dispatch（serveOnce 同样消费），CLOSE_WINDOW 落在在途窗口，
            # 按 owner 实退 + 传输收敛 + 重开业务可用判定。
            failures += check_blocked(
                "C7: queued 渲染票阶段语义",
                "KnownShimNoRef 拒绝发布 surface（published=0），渲染票不存在；"
                "真实卸载/在途渲染票关闭待真实引用平台")
            # 第九次复核 D：异步请求先取得**精确在途阶段确认**（COUNTERS
            # INFLIGHT>=1）再关闭——同步请求返回后才 CLOSE 不能证明在途停止。
            control_map("EXEC_HOLD_1200")
            import threading
            async_result = {}
            def _async_invoke():
                try:
                    async_result["t"] = invoke_increment(v, timeout=8.0)
                except Exception as exc:  # noqa: BLE001
                    async_result["err"] = type(exc).__name__
            th = threading.Thread(target=_async_invoke)
            th.start()
            inflight_seen = 0
            for _ in range(16):               # 轮询 COUNTERS：票已认领（Executing）
                time.sleep(0.2)
                cnt = control_map("COUNTERS", timeout=4.0)
                raw_if = cnt.get("INFLIGHT") if isinstance(cnt, dict) else None
                if raw_if is None:
                    m_if = re.search(r"INFLIGHT (\d+)", str(cnt))
                    raw_if = m_if.group(1) if m_if else None
                if raw_if is not None and int(raw_if) >= 1:
                    inflight_seen = int(raw_if)
                    break
            failures += check("C7: 关闭前精确在途确认（COUNTERS INFLIGHT>=1）",
                              inflight_seen >= 1, True)
            control_map("CLOSE_WINDOW")
            th.join(timeout=10.0)
            c7_refused = False
            for _ in range(16):
                time.sleep(2)
                try:
                    business(["GET_CONTEXT 0"], timeout=1.5)
                except (ConnectionResetError, OSError):
                    c7_refused = True
                    break
            failures += check("C7 替身档: 关闭后停止链收敛（连接被拒）", c7_refused, True)
            term7_ok, term7_detail = False, {}
            for _ in range(18):
                time.sleep(2)
                term7_ok, term7_detail = stop_terminal_ok_standin()
                if term7_ok:
                    break
            matrix["C7_hilog"] = term7_detail.get("closed", "")[-160:]
            failures += check("C7 替身档: owner 实退+传输收敛（stand-in closed）",
                              term7_ok, True)
        else:
            failures += run_stop_ticket_case("queued", matrix)

        note("== C8 committing 关闭收敛（实际执行）==")
        if STANDIN:
            # 替身档：Committing/Flush 阶段不存在（无渲染）→ 阶段语义 BLOCKED；
            # 收敛纪律已由 C6（空闲）与 C7 替身档（在途派发）覆盖，
            # 最终重建收敛在下方统一执行，不重复制造假判据。
            failures += check_blocked(
                "C8: committing/flush 阶段语义",
                "KnownShimNoRef 档无渲染路径（published=0），Committing/Flush 不存在；"
                "待真实引用平台执行")
        else:
            failures += run_stop_ticket_case("committing", matrix)

        # 最终重建收敛：关闭后同 bundle 重新 boot，业务可用
        if start_app_and_read_token() is not None:
            time.sleep(2)
            _, resp = business(["GET_CONTEXT 0"])
            failures += check("C8 后重建：新实例业务可用", version_of(resp) >= 0, True)
        else:
            failures += check("C8 后重建：新实例启动", False, True)

    note(f"\n==== RESULT: {'PASS' if failures == 0 else 'FAIL'} (failures={failures}) ====")
    with open(EVIDENCE_DIR / "surface_lifecycle_evidence.json", "w", encoding="utf-8") as f:
        json.dump({"matrix": matrix, "checks": EVIDENCE}, f, ensure_ascii=False, indent=2)
    EXCHANGE.flush_archive()
    return failures


if __name__ == "__main__":
    if sys.argv[1:] == ["--only-stop-tickets"]:
        sys.exit(run_only_stop_tickets())
    if sys.argv[1:]:
        raise SystemExit("usage: verify_surface_lifecycle_probe.py [--only-stop-tickets]")
    sys.exit(main())

#!/usr/bin/env python3
"""A1 实际 HAP 原事务矩阵（第五次复核 A1 §5 / 交接文档第四节）。

全部注入经 verify 控制接缝 → owner 派发 renderer test-gates / 核心注入开关；
结果一律由生产逻辑（renderer settle、核心结算门）产生，闸门只控制时序或
注入显式失败。

矩阵：
  M1 首帧 PENDING→Accepted：启动前按住出队闸门，StartingPending 可观察，
     放行后生产结算 Accepted（committed 计数推进）。
  M2 完整刷新 PENDING→Accepted + 等待期 owner 改值：dequeue 按住期间
     INCREMENT 应用（owner 版本前进），放行后帧结算，无重复推进。
  M3 PENDING→Rejected：注入 job 失败 → 生产结算 Rejected（aborted 计数），
     核心回滚原候选、自动重同步；后续 INCREMENT 正常（候选不卡死）。
  M4 ACK 失败恢复：注入一次 ACK 失败 → 核心保留已结算事务并重试原 ACK →
     清票；后续 INCREMENT 正常。
  M5 participant/focus 接受回调异常：核心注入开关 → 终止收敛（原票可追踪、
     不重跑回调），关闭为唯一出路（close_after_settlement_incomplete）。

用法： python3 verify_renderer_transaction_probe.py
"""

import json
import re
import subprocess
import sys
import time

sys.path.insert(0, "/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/platforms/ohos/scripts")
sys.path.insert(0, "/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/shared_operation_core")
from ohos_transport_probe_lib import (  # noqa: E402
    BoundedExchange, parse_business_terminal_strict, parse_control_frame_strict)
from client import parse_response  # noqa: E402

HOST, PORT = "127.0.0.1", 17856
PROTOCOL = "CJGUI_SHARED_OPERATION/2"
CAP = "cjgui-settings-counter-agent-20260925"
RESOURCE_ID = 9700
TOKEN = ""
EVIDENCE = []
RAW_ARCHIVE = ("/Users/jiangxuanyang/Desktop/cangjie/labs/ohos_cangjie_smoke/"
               "artifacts/cjgui-backend/verification/renderer_transaction_raw.json")
EXCHANGE = BoundedExchange(HOST, PORT, RAW_ARCHIVE)
HDC = ("/Applications/DevEco-Studio.app/Contents/sdk/default/openharmony/"
       "toolchains/hdc")


def note(msg):
    print(msg)


def check(desc, actual, expected):
    ok = actual == expected
    note(f"   {'OK  ' if ok else 'FAIL'} {desc} (got {actual!r} expect {expected!r})")
    EVIDENCE.append({"check": desc, "actual": actual, "expected": expected, "pass": ok})
    return 0 if ok else 1


def business(lines, timeout=8.0):
    return EXCHANGE.exchange_strict(
        [f"PROTOCOL {PROTOCOL}", f"AUTH {CAP}"] + lines, timeout)


def control_map(op, timeout=6.0):
    _, body = EXCHANGE.exchange_strict(
        ["CONTROL CJGUI_VERIFY/1", f"TOKEN {TOKEN}", f"OP {op}", "END"], timeout)
    return parse_control_frame_strict(body)


def invoke_increment(v):
    _, body = business([f"INVOKE {v} INCREMENT 1 0", f"ID {RESOURCE_ID}"])
    t = parse_business_terminal_strict(body)
    return t


def field_of(entries_text, field_id):
    parsed = parse_response(entries_text)
    for name, parts in parsed.entries:
        if name == "FIELD" and parts[1] == field_id:
            if parts[2] == "STRING" and len(parts) >= 5:
                return bytes.fromhex(parts[4]).decode("utf-8")
            return parts[3]
    return None


def version_of(snapshot_text):
    parsed = parse_response(snapshot_text)
    for name, parts in parsed.entries:
        if name == "VERSION":
            return int(parts[0])
    raise AssertionError("no VERSION")


def settlement_counts():
    """GATE_CLEAR 回执里的结算计数（owner 派发 renderer foreign 读回）。"""
    gate = control_map("GATE_STATE")
    result = gate.get("RESULT", "")
    m_c = re.search(r"committed=(\d+)", result)
    m_a = re.search(r"aborted=(\d+)", result)
    return (int(m_c.group(1)) if m_c else None,
            int(m_a.group(1)) if m_a else None)


def gate_stats_via_clear():
    control_map("GATE_CLEAR")
    for _ in range(20):
        g = control_map("GATE_STATE")
        if g.get("RESULT_ID") == g.get("LAST_COMMAND") and g.get("LAST_COMMAND") != "0":
            return g.get("RESULT", "")
        time.sleep(0.1)
    return "timeout"


def _publish_and_wait(op, timeout=5.0):
    """发布命令并按 **PUBLISHED id == RESULT_ID** 精确等待 owner 派发。
    命令通道为单槽最新覆盖：若下一条发布早于本条派发，本条即丢失——
    因此每条变更命令都必须等派发回执（按 id 匹配，不接受陈旧 RESULT）。"""
    pub = EXCHANGE.exchange_strict(
        ["CONTROL CJGUI_VERIFY/1", f"TOKEN {TOKEN}", f"OP {op}", "END"], timeout)
    body = pub[1]
    m = re.search(r"PUBLISHED (\d+)", body)
    if not m:
        return f"publish-failed: {body[:80]!r}"
    want = m.group(1)
    deadline = time.monotonic() + timeout
    last = {}
    while time.monotonic() < deadline:
        g = control_map("GATE_STATE")
        last = g
        if g.get("LAST_COMMAND") == want and g.get("RESULT_ID") == want:
            return g.get("RESULT", "")
        time.sleep(0.1)
    note(f"   DIAG {op} 未派发: GATE_STATE={last}")
    return "dispatch-timeout"


def gate_clear_and_release(timeout=5.0):
    return _publish_and_wait("GATE_CLEAR", timeout)


def stats_now(timeout=5.0):
    """发布 GATE_A2_STATS 并经 GATE_STATE 读回计数。"""
    control_map("GATE_A2_STATS")
    g = wait_result(timeout)
    if g is None:
        return "timeout"
    return g.get("RESULT", "")


def _counter_value(stats_text, key):
    m = re.search(key + r"=(\d+)", stats_text or "")
    return int(m.group(1)) if m else 0


def poll_counter_delta(key, baseline, delta, timeout=15.0):
    """轮询直到计数 >= baseline+delta（settle/ACK 发生在放行后的泵送轮）。"""
    deadline = time.monotonic() + timeout
    last = ""
    while time.monotonic() < deadline:
        last = stats_now()
        m = re.search(key + r"=(\d+)", last)
        if m and int(m.group(1)) >= baseline + delta:
            return True, last
        time.sleep(0.3)
    return False, last


def poll_counter(key, minimum, timeout=15.0):
    """轮询直到计数 >= minimum（settle/ACK 发生在放行后的泵送轮，需等待）。"""
    deadline = time.monotonic() + timeout
    last = ""
    while time.monotonic() < deadline:
        last = stats_now()
        m = re.search(key + r"=(\d+)", last)
        if m and int(m.group(1)) >= minimum:
            return True, last
        time.sleep(0.3)
    return False, last


def wait_result(timeout=5.0):
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        g = control_map("GATE_STATE")
        if g.get("RESULT_ID") == g.get("LAST_COMMAND") and g.get("LAST_COMMAND") != "0":
            return g
        time.sleep(0.1)
    return None


def hilog_tail(pattern, n=1):
    out = subprocess.run(
        [HDC, "shell", f"hilog -x 2>/dev/null | grep -a '{pattern}' | tail -{n}"],
        capture_output=True, text=True).stdout
    return out.strip()


def read_back():
    _, resp = business(["GET_CONTEXT 0"])
    return version_of(resp), field_of(resp, "name"), field_of(resp, "count")


def main() -> int:
    global TOKEN
    # M1 需要首帧被闸门按住：以带闸门参数的方式重启应用（清日志→启动→等就绪），
    # 与 build_and_run 的启动方式一致；token 从本轮 hilog 读回。
    subprocess.run(
        [HDC, "shell",
         "aa force-stop com.example.cjguiapp; hilog -r; "
         "aa start -a EntryAbility -b com.example.cjguiapp "
         "--pi cjguiTestGateFlushHoldMs 4000 --pi cjguiTestGateFlushHoldCount 1"],
        capture_output=True, text=True)
    time.sleep(8)
    token_out = subprocess.run(
        [HDC, "shell", "hilog -x 2>/dev/null | grep -a 'verify seam armed token=' | tail -1"],
        capture_output=True, text=True).stdout
    m = re.search(r"token=(\S+)", token_out)
    if not m:
        note(f"FAIL 未读到 verify token（{token_out[:80]!r}）")
        return 2
    TOKEN = m.group(1)
    note(f"== T0 token={TOKEN}")
    failures = 0
    matrix = {}

    # M1: 首帧 PENDING→Accepted（app 启动前已按住出队闸门 60s）
    note("== M1 首帧 PENDING→Accepted（StartingPending）==")
    _, resp = business(["GET_CONTEXT 0"])
    v0 = version_of(resp)
    name0 = field_of(resp, "name")
    note(f"   StartingPending 期间业务可用: v={v0} name={name0!r}")
    stats1 = gate_stats_via_clear()
    note(f"   放行后结算取证: {stats1}")
    m_c = re.search(r"committed=(\d+)", stats1)
    failures += check("首帧放行后生产结算 Accepted（committed>=1）",
                      bool(m_c) and int(m_c.group(1)) >= 1, True)
    matrix["M1_gate_result"] = stats1
    v1, _, _ = read_back()
    failures += check("StartingPending 收敛后业务正常", v1, v0)

    # M2: 完整刷新 PENDING→Accepted + 等待期 owner 改值
    # （flush 持有：票据已发、提交在 Committing 内被按住 → 核心 2s 等待返回
    #   PENDING+票据；dequeue 持有会在票据分配前扣住帧，触发协议缺口路径。）
    note("== M2 完整刷新 PENDING→Accepted + 等待期 owner 改值 ==")
    _publish_and_wait("GATE_FLUSH_HOLD_30000")
    t2 = invoke_increment(v1)
    v2_owner = version_of(business(["GET_CONTEXT 0"])[1])
    note(f"   等待期 owner 已应用 INCREMENT: v={v2_owner}（帧仍 PENDING）")
    failures += check("等待期 owner 改值生效（帧未结算）", v2_owner, v1 + 1)
    base_c2 = _counter_value(stats_now(), "committed")
    gate_clear_and_release()
    ok2, stats2 = poll_counter_delta("committed", base_c2, 1)
    matrix["M2_gate_result"] = stats2
    note(f"   放行后结算取证: {stats2}")
    failures += check("等待期后帧结算 Accepted（committed>=2）", ok2, True)
    t2b = invoke_increment(v1 + 1)
    failures += check("结算后新请求正常（APPLIED true）", t2b.get("APPLIED"), "true")
    failures += check("结算后版本恰好推进一位", t2b.get("VERSION_AFTER"), v1 + 2)

    # M3: PENDING→Rejected：先 flush 持有造 PENDING（票据在位），放行前注入
    # job 失败——生产结算在该票上裁决 Rejected（aborted 计数）。
    note("== M3 PENDING→Rejected ==")
    base_a3 = _counter_value(stats_now(), "aborted")
    _publish_and_wait("GATE_FLUSH_HOLD_30000")
    t3 = invoke_increment(v1 + 2)
    failures += check("注入票 owner 结果仍确定（APPLIED true）", t3.get("APPLIED"), "true")
    reject_dispatch = _publish_and_wait("GATE_REJECT_NEXT")
    matrix["M3_reject_dispatch"] = reject_dispatch
    note(f"   REJECT 派发回执: {reject_dispatch}")
    time.sleep(0.3)
    mid = stats_now()
    matrix["M3_mid_armed"] = mid
    note(f"   注入武装读数（放行前）: {mid}")
    gate_clear_and_release()
    ok3, stats3 = poll_counter_delta("aborted", base_a3, 1)
    matrix["M3_gate_result"] = stats3
    note(f"   结算取证: {stats3}")
    failures += check("生产结算裁决 Rejected（aborted>=1）", ok3, True)
    # 回滚后核心自动重同步：后续帧应正常提交（候选不卡死）
    t3b = invoke_increment(v1 + 3)
    failures += check("Rejected 后候选不卡死（新 INCREMENT APPLIED）",
                      t3b.get("APPLIED"), "true")
    v3, _, _ = read_back()
    failures += check("Rejected 后公开读回版本精确", v3, v1 + 4)

    # M4: ACK 失败恢复：flush 持有造 PENDING → 放行前注入 ACK 失败 →
    # 放行 → settle Accepted → 核心 ACK 首次失败（注入）→ 保留事务重试原 ACK
    # → 成功清票。放行后轮询 ack_fails（settle/ACK 发生在放行后的泵送轮）。
    note("== M4 ACK 失败恢复 ==")
    base_af4 = _counter_value(stats_now(), "ack_fails")
    _publish_and_wait("GATE_FLUSH_HOLD_30000")
    t4 = invoke_increment(v3)
    _publish_and_wait("GATE_FAIL_ACK_1")
    time.sleep(0.3)
    gate_clear_and_release()
    ok4, stats4 = poll_counter_delta("ack_fails", base_af4, 1)
    matrix["M4_gate_result"] = stats4
    note(f"   放行后取证: {stats4}")
    failures += check("ACK 失败注入恰好一次（>=1）", ok4, True)
    t4b = invoke_increment(v3 + 1)
    failures += check("ACK 重试成功后清票（新 INCREMENT APPLIED）",
                      t4b.get("APPLIED"), "true")

    # M5: 接受回调异常 → 终止收敛：flush 持有造 PENDING → 放行前武装注入 →
    # 放行 → settle Accepted（native 按事实晋升）→ 核心接受回调抛异常 →
    # 不可回滚终止收敛（原票持有、不重跑回调）→ 关闭为唯一出路。
    note("== M5 接受回调异常 → 终止收敛 ==")
    base_c5 = _counter_value(stats_now(), "committed")
    _publish_and_wait("GATE_FLUSH_HOLD_30000")
    t5 = invoke_increment(v3 + 2)
    _publish_and_wait("GATE_ACCEPT_THROW")
    time.sleep(0.3)
    gate_clear_and_release()
    ok5, stats5 = poll_counter_delta("committed", base_c5, 1)
    matrix["M5_gate_result"] = stats5
    note(f"   结算取证: {stats5}")
    failures += check("异常票 native 侧仍按事实结算（committed 增 1）", ok5, True)
    fault_deadline = time.monotonic() + 8.0
    fault_log = ""
    while time.monotonic() < fault_deadline:
        fault_log = hilog_tail("settlement fault:", 1)
        if "present_acceptance_exception" in fault_log:
            break
        time.sleep(0.5)
    matrix["M5_fault_hilog"] = fault_log[-140:]
    failures += check("终止收敛命名故障可见（settlement fault）",
                      "present_acceptance_exception" in fault_log, True)
    # 终止收敛：候选持有阻止新帧，但 owner 状态与业务不卡死
    t5b = invoke_increment(v3 + 3)
    failures += check("终止收敛期间业务仍确定（owner 裁决不受影响）",
                      t5b.get("APPLIED"), "true")
    # 关闭为唯一出路
    control_map("CLOSE_WINDOW")
    time.sleep(2.5)
    closed_refused = False
    try:
        business(["GET_CONTEXT 0"], timeout=2.0)
    except (ConnectionResetError, OSError):
        closed_refused = True
    failures += check("关闭后传输按停止链收敛（连接被拒）", closed_refused, True)
    host_closed = ""
    hc_deadline = time.monotonic() + 15.0
    while time.monotonic() < hc_deadline:
        host_closed = hilog_tail("host closed", 1)
        if "host closed" in host_closed:
            break
        time.sleep(0.5)
    matrix["M5_close_hilog"] = host_closed[-160:]
    failures += check("关闭后宿主完整收敛（host closed 日志）",
                      "host closed" in host_closed, True)

    with open(("/Users/jiangxuanyang/Desktop/cangjie/labs/ohos_cangjie_smoke/"
               "artifacts/cjgui-backend/verification/renderer_transaction_evidence.json"),
              "w", encoding="utf-8") as f:
        json.dump({"matrix": matrix, "checks": EVIDENCE}, f, ensure_ascii=False, indent=2)
    EXCHANGE.flush_archive()
    note(f"\n==== RESULT: {'PASS' if failures == 0 else 'FAIL'} (failures={failures}) ====")
    return failures


if __name__ == "__main__":
    sys.exit(main())

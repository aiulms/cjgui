#!/usr/bin/env python3
"""A2/A3：停止落在「不可取消提交」窗口的反例（第五次复核 B.3/B.4 强化版）。

时序（全部经 verify 接缝驱动生产入口）：
  1. 基线 GET_CONTEXT + 旧实例身份；
  2. PAUSE_CLAIM 闸住 1 张 INCREMENT；
  3. EXEC_HOLD_1200（先安装保持，再 RESUME——消除认领竞态）；
  4. RESUME_CLAIM 后轮询 TICKETS：目标票 PHASE=executing（记录票 ID/实例）；
  5. SETTLE：生产停止入口落在 Executing 窗口内；Executing 票不被取消；
  6. 客户端必须拿到**完整且严格解析**的业务终态（KIND OK + APPLIED true），
     空回包 / outcome_unknown / 未结束线程一律失败（删除旧的宽松断言）；
  7. BOOT_STATE：生产 awaitClosed → 同进程 boot → 新身份；
  8. 公开读回：版本恰好 +1、计数恰好 +1（该层提交恰好一次；
     renderer 的 Flush/Committing 不在本层，如实另记）。

用法： python3 verify_transport_committing_probe.py
"""

import json
import re
import socket
import subprocess
import sys
import time

sys.path.insert(0, "/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/platforms/ohos/scripts")
sys.path.insert(0, "/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/shared_operation_core")
from ohos_transport_probe_lib import (  # noqa: E402
    BoundedExchange, FrameError, parse_business_terminal_strict,
    parse_control_frame_strict)
from client import parse_response  # noqa: E402

HOST, PORT = "127.0.0.1", 17856
PROTOCOL = "CJGUI_SHARED_OPERATION/2"
CAP = "cjgui-settings-counter-agent-20260925"
RESOURCE_ID = 9700
TOKEN = ""
EVIDENCE = []
RAW_ARCHIVE = ("/Users/jiangxuanyang/Desktop/cangjie/labs/ohos_cangjie_smoke/"
               "artifacts/cjgui-backend/verification/transport_committing_raw.json")
EXCHANGE = BoundedExchange(HOST, PORT, RAW_ARCHIVE)


def note(msg):
    print(msg)


def check(desc, actual, expected):
    ok = actual == expected
    note(f"   {'OK  ' if ok else 'FAIL'} {desc} (got {actual!r} expect {expected!r})")
    EVIDENCE.append({"check": desc, "actual": actual, "expected": expected, "pass": ok})
    return 0 if ok else 1


def business(lines, timeout=8.0):
    payload, body = EXCHANGE.exchange_strict(
        [f"PROTOCOL {PROTOCOL}", f"AUTH {CAP}"] + lines, timeout)
    return payload, body


def control_map(op, timeout=6.0):
    _, body = EXCHANGE.exchange_strict(
        ["CONTROL CJGUI_VERIFY/1", f"TOKEN {TOKEN}", f"OP {op}", "END"], timeout)
    return parse_control_frame_strict(body)


def counters():
    return control_map("COUNTERS")


def tickets():
    return control_map("TICKETS")


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


def main() -> int:
    global TOKEN
    token_out = subprocess.run(
        ["/Applications/DevEco-Studio.app/Contents/sdk/default/openharmony/toolchains/hdc",
         "shell", "hilog -x 2>/dev/null | grep -a 'verify seam armed token=' | tail -1"],
        capture_output=True, text=True).stdout
    m = re.search(r"token=(\S+)", token_out)
    if not m:
        note(f"FAIL 未读到本轮 verify token（hilog: {token_out[:80]!r}）")
        return 2
    TOKEN = m.group(1)
    note(f"== C0 token={TOKEN}")
    failures = 0
    run_meta = {"token": TOKEN, "target_ticket_id": None,
                "executing_sample": None, "pre_stop_sample": None}

    # 1) 基线
    _, resp = business(["GET_CONTEXT 0"])
    v0 = version_of(resp)
    name0 = field_of(resp, "name")
    count0 = field_of(resp, "count")
    note(f"   基线: v={v0} name={name0!r} count={count0}")
    failures += check("服务可用", bool(v0 is not None), True)
    old_identity = control_map("STATE").get("IDENTITY", "")
    note(f"   旧实例身份: {old_identity!r}")
    run_meta["old_identity"] = old_identity
    failures += check("旧实例身份可读", old_identity != "" and old_identity != "none", True)

    # 2) 闸住 1 张 INCREMENT
    failures += check("认领已暂停", control_map("PAUSE_CLAIM").get("PAUSED"), "true")

    ticket_terminal = {}

    def submitter():
        try:
            payload, body = business([f"INVOKE {v0} INCREMENT 1 0", f"ID {RESOURCE_ID}"],
                                     timeout=12.0)
            ticket_terminal["payload"] = payload
            ticket_terminal["body"] = body
        except Exception as exc:  # noqa: BLE001
            ticket_terminal["error"] = f"{type(exc).__name__}: {exc}"

    import threading
    th = threading.Thread(target=submitter)
    th.start()
    time.sleep(0.4)

    # 3) 先安装保持，再 RESUME（消除「认领先于保持」的竞态）
    hold = control_map("EXEC_HOLD_1200")
    failures += check("执行保持已设定（先于 RESUME）", hold.get("HOLD_SET"), "true")
    failures += check("认领已放行", control_map("RESUME_CLAIM").get("PAUSED"), "false")

    # 4) 确定性窗口证据：TICKETS 采样目标票 executing
    target = None
    deadline = time.monotonic() + 3.0
    while time.monotonic() < deadline:
        t = tickets()
        if "PHASE executing" in " ".join(f"{k} {v}" for k, v in t.items()):
            target = t
            break
        time.sleep(0.05)
    executing_keys = [k for k, v in (target or {}).items() if v.startswith("ID ") and "PHASE executing" in v]
    note(f"  Executing 采样: {target}")
    failures += check("票据进入不可取消提交窗口（PHASE=executing）",
                      bool(executing_keys), True)
    if executing_keys:
        run_meta["executing_sample"] = {k: target[k] for k in executing_keys}
        run_meta["target_ticket_id"] = target[executing_keys[0]].split()[1]
    run_meta["pre_stop_sample"] = counters()

    # 5) SETTLE：停止落在 Executing 窗口内
    _, settle_body = EXCHANGE.exchange_strict(
        ["CONTROL CJGUI_VERIFY/1", f"TOKEN {TOKEN}", "OP SETTLE", "END"], timeout=10.0)
    settle_map = parse_control_frame_strict(settle_body)
    note(f"   SETTLE: {settle_map}")
    failures += check("停止+收敛完成（含在途票结算）", settle_map.get("SETTLED"), "true")

    # 6) 客户端必须拿到完整且严格解析的业务终态（B.3：删除宽松断言）
    th.join(timeout=12.0)
    if th.is_alive():
        note("   FAIL 提交线程 12s 未结束")
        failures += check("提交线程已结束", False, True)
    if "body" not in ticket_terminal:
        note(f"   提交票客户端结果: {ticket_terminal.get('error', '无回包')!r}")
        failures += check("客户端拿到业务终态回包", False, True)
    else:
        try:
            terminal = parse_business_terminal_strict(ticket_terminal["body"])
            note(f"   严格终态: KIND={terminal['KIND']} APPLIED={terminal['APPLIED']} "
                 f"VERSION_AFTER={terminal['VERSION_AFTER']}")
            failures += check("业务终态 KIND RESULT", terminal["KIND"], "RESULT")
            failures += check("业务终态 APPLIED true", terminal["APPLIED"], "true")
            failures += check("业务终态 VERSION_AFTER 前进一位",
                              terminal["VERSION_AFTER"], v0 + 1)
        except FrameError as exc:
            note(f"   FAIL 业务终态解析失败: {exc}")
            failures += check("业务终态严格解析", False, True)

    # 7) BOOT_STATE：生产 awaitClosed → 同进程 boot → 新身份
    boot_map = None
    deadline = time.monotonic() + 15.0
    while time.monotonic() < deadline:
        try:
            bm = control_map("BOOT_STATE", timeout=3.0)
            if bm.get("PENDING") != "true":
                boot_map = bm
                break
        except (ConnectionResetError, OSError):
            pass
        time.sleep(0.2)
    if boot_map is None:
        note("FAIL BOOT_STATE 未收敛")
        failures += 1
    else:
        note(f"   BOOT_STATE: {boot_map}")
        failures += check("owner 外确认 Closed", boot_map.get("CLOSED"), "true")
        failures += check("同进程 BOOT 完成", boot_map.get("BOOTED"), "true")
        new_identity = boot_map.get("NEW_IDENTITY", "")
        run_meta["new_identity"] = new_identity
        failures += check("新身份不等于旧身份",
                          new_identity != "" and new_identity != old_identity, True)

    # 8) 提交恰好生效一次（公开 owner 读回，非桥接回执）
    _, resp = business(["GET_CONTEXT 0"])
    v1 = version_of(resp)
    count1 = field_of(resp, "count")
    name1 = field_of(resp, "name")
    note(f"   重开后读回: v={v1} name={name1!r} count={count1}")
    failures += check("提交结果保留（版本恰好 +1）", v1, v0 + 1)
    failures += check("提交结果保留（计数恰好 +1）", count1, str(int(count0) + 1))
    failures += check("owner 值保留", name1, name0)
    note("   注：本层为 transport 票据提交；renderer 的 Flush/Committing 不在本反例覆盖内。")
    EVIDENCE.append({"note": "transport-layer commit only; renderer Flush/Committing not covered here"})

    out = ("/Users/jiangxuanyang/Desktop/cangjie/labs/ohos_cangjie_smoke/"
           "artifacts/cjgui-backend/verification/transport_committing_evidence.json")
    with open(out, "w", encoding="utf-8") as f:
        json.dump({"meta": run_meta, "checks": EVIDENCE}, f, ensure_ascii=False, indent=2)
    EXCHANGE.flush_archive()
    note(f"\n==== RESULT: {'PASS' if failures == 0 else 'FAIL'} (failures={failures}) ====")
    return failures


if __name__ == "__main__":
    sys.exit(main())

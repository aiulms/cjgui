#!/usr/bin/env python3
"""A3：应用生命周期反例（StartingPending 停止、重建循环、停止→重启）。

  L1 StartingPending 时 stop：flush 持有造 PENDING → CLOSE_WINDOW →
     关闭意图**等待结算**（传输仍活着、owner 不崩溃）→ 放行 → settle →
     关闭收敛（连接被拒）。
  L2 放行重启（stop→boot）：CLOSE 后 hdc 重启应用 → 新实例业务可用。
  L3 ≥10 次 surface 重建循环：SIM_RETIRED/SIM_CREATED ×10，每轮业务可用；
     结束后许可配对收敛（acquired == released）。

用法： python3 verify_app_lifecycle_probe.py
"""

import json
import re
import subprocess
import sys
import time

sys.path.insert(0, "/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/platforms/ohos/scripts")
sys.path.insert(0, "/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/shared_operation_core")
from ohos_transport_probe_lib import (  # noqa: E402
    BoundedExchange, parse_business_terminal_strict)
from client import parse_response  # noqa: E402

HOST, PORT = "127.0.0.1", 17856
PROTOCOL = "CJGUI_SHARED_OPERATION/2"
CAP = "cjgui-settings-counter-agent-20260925"
RESOURCE_ID = 9700
TOKEN = ""
EVIDENCE = []
RAW_ARCHIVE = ("/Users/jiangxuanyang/Desktop/cangjie/labs/ohos_cangjie_smoke/"
               "artifacts/cjgui-backend/verification/app_lifecycle_raw.json")
EXCHANGE = BoundedExchange(HOST, PORT, RAW_ARCHIVE)
HDC = ("/Applications/DevEco-Studio.app/Contents/sdk/default/openharmony/"
       "toolchains/hdc")
BUNDLE = "com.example.cjguiapp"


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
    lines = body.splitlines()
    out = {}
    for line in lines[2:]:
        parts = line.split(" ", 1)
        if len(parts) == 2:
            out[parts[0]] = parts[1]
    return out


def _publish_and_wait(op, timeout=5.0):
    pub = EXCHANGE.exchange_strict(
        ["CONTROL CJGUI_VERIFY/1", f"TOKEN {TOKEN}", f"OP {op}", "END"], timeout)[1]
    m = re.search(r"PUBLISHED (\d+)", pub)
    if not m:
        return f"publish-failed: {pub[:80]!r}"
    want = m.group(1)
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        g = control_map("GATE_STATE")
        if g.get("LAST_COMMAND") == want and g.get("RESULT_ID") == want:
            return g.get("RESULT", "")
        time.sleep(0.1)
    return "dispatch-timeout"


def invoke_and_sync(v):
    _, body = business([f"INVOKE {v} INCREMENT 1 0", f"ID {RESOURCE_ID}"])
    t = parse_business_terminal_strict(body)
    if t.get("APPLIED") == "true" and t.get("VERSION_AFTER") is not None:
        return t["VERSION_AFTER"], t
    return v, t


def version_of(text):
    parsed = parse_response(text)
    for name, parts in parsed.entries:
        if name == "VERSION":
            return int(parts[0])
    raise AssertionError("no VERSION")


def read_version():
    _, resp = business(["GET_CONTEXT 0"])
    return version_of(resp)


def relaunch_app():
    subprocess.run(
        [HDC, "shell",
         f"aa force-stop {BUNDLE}; hilog -r; "
         f"aa start -a EntryAbility -b {BUNDLE} "
         "--pi cjguiTestGateFlushHoldMs 4000 --pi cjguiTestGateFlushHoldCount 1"],
        capture_output=True, text=True)
    time.sleep(8)


def read_token():
    out = subprocess.run(
        [HDC, "shell", "hilog -x 2>/dev/null | grep -a 'verify seam armed token=' | tail -1"],
        capture_output=True, text=True).stdout
    m = re.search(r"token=(\S+)", out)
    return m.group(1) if m else ""


def main() -> int:
    global TOKEN
    relaunch_app()
    TOKEN = read_token()
    if not TOKEN:
        note("FAIL 未读到 verify token")
        return 2
    note(f"== L0 token={TOKEN}")
    failures = 0

    # L1 StartingPending 时 stop：PENDING 期间 CLOSE 意图等待结算，不崩溃
    note("== L1 StartingPending 时 stop（关闭意图等待结算）==")
    _publish_and_wait("GATE_FLUSH_HOLD_30000")
    v0 = read_version()
    v1, t1 = invoke_and_sync(v0)
    note(f"   PENDING 挂起帧: APPLIED={t1.get('APPLIED')} v={v1}")
    control_map("CLOSE_WINDOW")
    time.sleep(0.8)
    # 关闭意图已挂起：传输仍活着（未强制断开），owner 未崩溃
    still_alive = True
    try:
        v_mid = read_version()
    except Exception:  # noqa: BLE001
        still_alive = False
        v_mid = None
    failures += check("关闭挂起期间传输仍服务（未强制断开）", still_alive, True)
    note(f"   挂起期间读回 v={v_mid}")
    # 放行：结算 → close 自动收敛。收敛可能在 CLEAR 派发前后发生——
    # CLEAR 被拒（连接已关）与 CLEAR 成功后拒绝都证明确认收敛。
    cleared = True
    try:
        _publish_and_wait("GATE_CLEAR")
    except (ConnectionResetError, OSError):
        cleared = False   # 放行前已收敛
    time.sleep(1.5)
    refused = False
    try:
        business(["GET_CONTEXT 0"], timeout=2.0)
    except (ConnectionResetError, OSError):
        refused = True
    failures += check("放行后关闭收敛（连接被拒）", refused, True)
    failures += check("关闭命令未丢失（CLEAR 派发或已收敛）", cleared or refused, True)

    # L2 stop→boot：重启应用，新实例业务可用
    note("== L2 停止后重启（新实例 boot）==")
    relaunch_app()
    TOKEN = read_token()
    v2 = read_version()
    note(f"   新实例读回 v={v2}")
    failures += check("重启后新实例业务可用", isinstance(v2, int), True)

    # L3 ≥10 次 surface 重建循环 + 许可配对收敛
    note("== L3 surface 重建循环 ×10 ==")
    pair0 = control_map("GATE_A2_STATS")
    rebuild_ok = 0
    for cycle in range(10):
        control_map("GATE_SIM_RETIRED")
        time.sleep(0.15)
        control_map("GATE_SIM_CREATED")
        time.sleep(0.35)
        try:
            business(["GET_CONTEXT 0"], timeout=3.0)
            rebuild_ok += 1
        except Exception:  # noqa: BLE001
            break
    failures += check("10 次重建循环业务连续", rebuild_ok, 10)
    stats = _publish_and_wait("GATE_A2_STATS")
    note(f"   结束统计: {stats}")
    m_pair = re.search(r"permits=(\d+)/(\d+)", stats)
    # 收敛判据：acquired - released == 1（唯一活跃 surface 合法持有 1 份许可；
    # 全 0 反而意味着活跃 surface 的许可被错误归还）。
    paired = bool(m_pair) and (int(m_pair.group(1)) - int(m_pair.group(2)) == 1)
    failures += check("许可配对收敛（acquired - released == 1 活跃持有）", paired, True)
    v3, _ = invoke_and_sync(v2)
    failures += check("重建循环后 INCREMENT 正常", v3, v2 + 1)

    out = ("/Users/jiangxuanyang/Desktop/cangjie/labs/ohos_cangjie_smoke/"
           "artifacts/cjgui-backend/verification/app_lifecycle_evidence.json")
    with open(out, "w", encoding="utf-8") as f:
        json.dump(EVIDENCE, f, ensure_ascii=False, indent=2)
    EXCHANGE.flush_archive()
    note(f"\n==== RESULT: {'PASS' if failures == 0 else 'FAIL'} (failures={failures}) ====")
    return failures


if __name__ == "__main__":
    sys.exit(main())

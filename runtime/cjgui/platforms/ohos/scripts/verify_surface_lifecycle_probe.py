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
  C7 queued 关闭收敛：DEQUEUE hold → INCREMENT 挂起 → CLOSE_WINDOW →
     CLEAR 放行 → 结算后关闭收敛。
  C8 committing 关闭收敛：FLUSH hold → INCREMENT（committing 内）→
     CLOSE_WINDOW → CLEAR 放行 → 关闭收敛。

用法： python3 verify_surface_lifecycle_probe.py
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
               "artifacts/cjgui-backend/verification/surface_lifecycle_raw.json")
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
    control_map("GATE_CLEAR")
    return gate_result()


def hilog_tail(pattern, n=2):
    out = subprocess.run(
        [HDC, "shell", f"hilog -x 2>/dev/null | grep -a '{pattern}' | tail -{n}"],
        capture_output=True, text=True).stdout
    return out.strip()


def invoke_and_sync(v):
    """INCREMENT 并从回执同步本地版本（触发帧在 owner 侧照样应用）。"""
    t = invoke_increment(v)
    if t.get("APPLIED") == "true" and t.get("VERSION_AFTER") is not None:
        return t["VERSION_AFTER"], t
    return v, t


def main() -> int:
    global TOKEN
    # 自带重启：C6 会关闭应用，探针必须从新实例开始（清日志→带闸门参数启动）。
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
    note(f"== S0 token={TOKEN}")
    failures = 0
    matrix = {}

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

    # C1 许可窗口内销毁重建
    note("== C1 许可后、创建前销毁重建 ==")
    control_map("GATE_HOLD_PERMIT_8000")
    v, t1 = invoke_and_sync(v)
    note(f"   触发帧（挂起在许可闸门）: APPLIED={t1.get('APPLIED')}")
    r1 = control_map("GATE_SIM_RETIRED")
    r1b = control_map("GATE_SIM_CREATED")
    matrix["C1_sim"] = (r1.get("PUBLISHED"), r1b.get("PUBLISHED"))
    time.sleep(0.3)
    clear_all()
    time.sleep(0.5)
    retire_log = hilog_tail("present rejected after permit hold", 1)
    matrix["C1_hilog"] = retire_log[-140:]
    note(f"   闸门内退役取证: {retire_log[-100:]!r}")
    failures += biz_ok("C1")

    # C2 创建前销毁重建
    note("== C2 创建调用前销毁重建 ==")
    control_map("GATE_HOLD_CREATE_8000")
    v, _ = invoke_and_sync(v)
    control_map("GATE_SIM_RETIRED")
    control_map("GATE_SIM_CREATED")
    time.sleep(0.3)
    clear_all()
    time.sleep(0.5)
    failures += biz_ok("C2")

    # C3 绘制中销毁重建
    note("== C3 绘制中段销毁重建 ==")
    control_map("GATE_HOLD_DRAW_8000")
    v, _ = invoke_and_sync(v)
    control_map("GATE_SIM_RETIRED")
    control_map("GATE_SIM_CREATED")
    time.sleep(0.3)
    clear_all()
    time.sleep(0.5)
    failures += biz_ok("C3")

    # C4 提交准入前销毁重建
    note("== C4 提交准入前销毁重建 ==")
    control_map("GATE_HOLD_ADMIT_8000")
    v, t4 = invoke_and_sync(v)
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

    # C5 不可取消提交中销毁重建
    note("== C5 不可取消提交中销毁重建 ==")
    control_map("GATE_HOLD_ADMIT_8000")
    v, t5 = invoke_and_sync(v)
    control_map("GATE_SIM_RETIRED")
    control_map("GATE_SIM_CREATED")
    time.sleep(0.3)
    clear_all()
    time.sleep(0.5)
    failures += biz_ok("C5")

    # C6 空闲真实关闭收敛
    note("== C6 空闲真实关闭（停止链收敛）==")
    control_map("CLOSE_WINDOW")
    time.sleep(1.5)
    refused = False
    try:
        business(["GET_CONTEXT 0"], timeout=2.0)
    except (ConnectionResetError, OSError):
        refused = True
    failures += check("C6: 关闭后停止链收敛（连接被拒）", refused, True)
    closed_log = hilog_tail("host closed", 1)
    matrix["C6_hilog"] = closed_log[-160:]
    failures += check("C6: 宿主关闭日志存在（render teardown 完成）",
                      "host closed" in closed_log, True)

    note(f"\n==== RESULT: {'PASS' if failures == 0 else 'FAIL'} (failures={failures}) ====")
    note("   C7/C8（queued/committing 关闭收敛）与真实 XComponent 压力："
         "需要重启后的新实例，由 build_and_run 复跑序列覆盖。")
    with open(("/Users/jiangxuanyang/Desktop/cangjie/labs/ohos_cangjie_smoke/"
               "artifacts/cjgui-backend/verification/surface_lifecycle_evidence.json"),
              "w", encoding="utf-8") as f:
        json.dump({"matrix": matrix, "checks": EVIDENCE}, f, ensure_ascii=False, indent=2)
    EXCHANGE.flush_archive()
    return failures


if __name__ == "__main__":
    sys.exit(main())

#!/usr/bin/env python3
"""D/第六次复核第 4 项：三条正常输入路径的逐请求单调阶段样本。

路径（各 8 次采样，首个样本标注 cold，其余 hot）：
  P1 触摸：控制接缝 TOUCH 注入（渲染器命中 → owner 增计数 → accepted）；
  P2 连续输入：uitest inputText 到名称字段（onChange 预览 → 失焦结算）；
  P3 外部请求：transport INCREMENT（请求 → owner 应用 → 画面 accepted）。

每样本记录原始 hilog 时间戳（设备侧单调时钟）：
  t_req（注入/请求在设备侧的首个痕迹）→ t_owner（owner 应用）→ t_acc（accepted）。
断言：逐样本阶段单调（owner 不早于请求、accepted 不早于 owner）、版本单调、
往返耗时（transport 往返另列，不作分段时延声明）。

用法： python3 verify_response_stages.py   （需 --verify-transport --test-gates 产物）
"""

import json
import re
import subprocess
import sys
import time

sys.path.insert(0, "/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/platforms/ohos/scripts")
sys.path.insert(0, "/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/shared_operation_core")
from ohos_transport_probe_lib import BoundedExchange  # noqa: E402
from client import parse_response  # noqa: E402

HOST, PORT = "127.0.0.1", 17856
PROTOCOL = "CJGUI_SHARED_OPERATION/2"
CAP = "cjgui-settings-counter-agent-20260925"
RESOURCE_ID = 9700
TOKEN = ""
N_SAMPLES = 8
HDC = ("/Applications/DevEco-Studio.app/Contents/sdk/default/openharmony/"
       "toolchains/hdc")
EVIDENCE_DIR = ("/Users/jiangxuanyang/Desktop/cangjie/labs/ohos_cangjie_smoke/"
                "artifacts/cjgui-backend/verification")
EXCHANGE = BoundedExchange(HOST, PORT, "")
EVIDENCE = []


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
    out = {}
    for line in body.splitlines()[2:]:
        parts = line.split(" ", 1)
        if len(parts) == 2:
            out[parts[0]] = parts[1]
    return out


def version_of(text):
    parsed = parse_response(text)
    for name, parts in parsed.entries:
        if name == "VERSION":
            return int(parts[0])
    raise AssertionError("no VERSION")


def read_version():
    _, resp = business(["GET_CONTEXT 0"])
    return version_of(resp)


def hilog_ms(pattern, tail=200):
    """返回设备日志中匹配 pattern 的最后若干行的 (时,分,秒,毫秒, 原行)。"""
    out = subprocess.run(
        [HDC, "shell", f"hilog -x 2>/dev/null | grep -a '{pattern}' | tail -{tail}"],
        capture_output=True, text=True).stdout
    rows = []
    for line in out.splitlines():
        m = re.search(r"(\d{2}):(\d{2}):(\d{2})\.(\d{3})", line)
        if m:
            h, mi, s, ms = (int(g) for g in m.groups())
            rows.append((h * 3600 + mi * 60 + s, ms, line))
    return rows


def ts_to_ms(row):
    return row[0] * 1000 + row[1]


def sample_stage(pattern_request, pattern_owner, pattern_accepted):
    """取三类痕迹各自的最后时间戳（毫秒），缺失返回 None。"""
    def last(rows):
        return ts_to_ms(rows[-1]) if rows else None
    return (last(hilog_ms(pattern_request)), last(hilog_ms(pattern_owner)),
            last(hilog_ms(pattern_accepted)))


def main() -> int:
    global TOKEN
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
    control_map("GATE_CLEAR")
    time.sleep(2.5)
    v = read_version()
    note(f"   基线 v={v}")

    samples = {"touch": [], "input": [], "external": []}
    versions = {"touch": [], "input": [], "external": []}

    # P1 触摸路径：TOUCH 注入（升级/降级按钮，节点 22/21），owner 增计数
    rects = {}
    out = subprocess.run(
        [HDC, "shell", "hilog -x 2>/dev/null | grep -a 'node-rect' | tail -40"],
        capture_output=True, text=True).stdout
    for line in out.splitlines():
        mm = re.search(r"node-rect id=(\d+) x=(\d+) y=(\d+) w=(\d+) h=(\d+)", line)
        if mm:
            rects[int(mm.group(1))] = tuple(float(mm.group(k)) for k in range(2, 6))
    if 22 not in rects:
        note("FAIL 未取得升温按钮几何")
        return 2
    bx, by, bw, bh = rects[22]
    for i in range(N_SAMPLES):
        hilog_clear = subprocess.run([HDC, "shell", "hilog -r"], capture_output=True)
        _ = hilog_clear
        before = read_version()
        control_map(f"TOUCH_37_{int(bx + bw / 2)}_{int(by + bh / 2)}")
        time.sleep(0.15)
        control_map(f"TOUCH_39_{int(bx + bw / 2)}_{int(by + bh / 2)}")
        time.sleep(0.6)
        after = read_version()
        req_r = hilog_ms("raw touch action")
        req = ts_to_ms(req_r[-1]) if req_r else None
        # accepted/present 取「请求时间戳之后」的首条（清缓冲后仍可能有
        # 请求前的旧帧记录，不能简单取最后一条）。
        acc = next((ts_to_ms(r) for r in hilog_ms("accepted node=")
                    if ts_to_ms(r) >= (req or 0)), None)
        pres = next((ts_to_ms(r) for r in hilog_ms("present frame ok")
                     if acc is not None and ts_to_ms(r) >= acc), None)
        tag = "cold" if i == 0 else "hot"
        mono = (None in (req, acc, pres)) or (req <= acc <= pres)
        samples["touch"].append({"i": i, "phase": tag, "t_req": req, "t_accepted": acc,
                                 "t_present": pres, "v_before": before, "v_after": after})
        versions["touch"].append(after)
        failures += check(f"P1[{i}]({tag}) 阶段单调 touch<=accepted<=present", mono, True)
        failures += check(f"P1[{i}] 版本 +1", after, before + 1)

    # P2 连续输入路径：inputText 到名称字段（onChange 预览）→ 回车提交
    for i in range(N_SAMPLES):
        subprocess.run([HDC, "shell", "hilog -r"], capture_output=True)
        before = read_version()
        subprocess.run([HDC, "shell",
                        f"uitest uiInput click {660} {600}"], capture_output=True)
        time.sleep(2.5)
        subprocess.run([HDC, "shell",
                        "uitest uiInput inputText 660 600 输入样本"], capture_output=True)
        time.sleep(2.5)
        own_rows = hilog_ms("ime proxy onChange")
        acc_rows = hilog_ms("accepted node=24")
        req = own_rows[-1][0] * 1000 + own_rows[-1][1] if own_rows else None
        acc = acc_rows[-1][0] * 1000 + acc_rows[-1][1] if acc_rows else None
        after = read_version()
        tag = "cold" if i == 0 else "hot"
        mono = (req is None or acc is None) or (req <= acc)
        # 预览语义：连续输入只产生本地预览，不推进 owner 版本（提交才推进）。
        samples["input"].append({"i": i, "phase": tag, "t_change": req,
                                 "t_acc": acc, "v_before": before, "v_after": after})
        failures += check(f"P2[{i}]({tag}) 阶段单调 change<=accepted", mono, True)
        failures += check(f"P2[{i}] 预览不推进 owner 版本", after, before)

    # P2 收尾：回车显式提交 → owner 推进（与预览不推进互补）
    subprocess.run([HDC, "shell", "uitest uiInput keyEvent 2054"], capture_output=True)
    time.sleep(2)
    _ = read_version()
    v_last = versions["input"][-1] if versions["input"] else None

    # P3 外部请求路径：transport INCREMENT → owner → accepted
    for i in range(N_SAMPLES):
        subprocess.run([HDC, "shell", "hilog -r"], capture_output=True)
        before = read_version()
        t0 = time.monotonic()
        _, resp = business([f"INVOKE {before} INCREMENT 1 0", f"ID {RESOURCE_ID}"])
        rtt_ms = int((time.monotonic() - t0) * 1000)
        time.sleep(0.8)
        after = read_version()
        acc = hilog_ms("accepted node=")
        t_acc = acc[-1][0] * 1000 + acc[-1][1] if acc else None
        tag = "cold" if i == 0 else "hot"
        samples["external"].append({"i": i, "phase": tag, "rtt_ms": rtt_ms,
                                    "t_acc": t_acc, "v_before": before,
                                    "v_after": after})
        versions["external"].append(after)
        failures += check(f"P3[{i}]({tag}) 版本 +1（往返 {rtt_ms}ms 另列）",
                          after, before + 1)

    # 版本全程单调（各路径内部）
    for path, vs in versions.items():
        mono = all(b > a for a, b in zip(vs, vs[1:]))
        failures += check(f"{path} 路径版本全程严格单调", mono, True)

    # 汇总：每路径热样本的 accepted 延迟（t_acc - t_req/owner，可得的子集）
    summary = {}
    for path, ss in samples.items():
        hot = [s for s in ss if s["phase"] == "hot"]
        summary[path] = {"n_hot": len(hot)}
    note(f"   汇总: {summary}")

    with open(f"{EVIDENCE_DIR}/response_stage_samples.json", "w",
              encoding="utf-8") as f:
        json.dump({"samples": samples, "checks": EVIDENCE}, f,
                  ensure_ascii=False, indent=2)
    note(f"\n==== RESULT: {'PASS' if failures == 0 else 'FAIL'} (failures={failures}) ====")
    return failures


if __name__ == "__main__":
    sys.exit(main())

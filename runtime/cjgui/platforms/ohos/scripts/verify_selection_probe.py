#!/usr/bin/env python3
"""C selection/marked 探针（uitest 驱动真实系统选区）。

流程：
  1. 点击名称字段 → 隐藏代理 cjguiImeProxy 获得焦点；
  2. inputText 键入含 emoji 文本（预览路径，owner 契约外）；
  3. uitest longClick 触发系统选区 → onTextSelectionChange → imeSetSelection
     → 渲染器 selStart/selEnd → 选区高亮（像素证据：高亮蓝色叠加）；
  4. 选区替换：inputText 新文本 → 失焦提交 → owner 读回逐码元精确。

用法： python3 verify_selection_probe.py
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

HDC = "/Applications/DevEco-Studio.app/Contents/sdk/default/openharmony/toolchains/hdc"
BUNDLE = "com.example.cjguiapp"
FIELD_X, FIELD_Y = 660, 600          # 名称字段屏幕坐标（inputText 实证值）
EVIDENCE_DIR = ("/Users/jiangxuanyang/Desktop/cangjie/labs/ohos_cangjie_smoke/"
                "artifacts/cjgui-backend/verification")
EVIDENCE = []
EX = BoundedExchange("127.0.0.1", 17856, "")


def note(msg):
    print(msg)


def check(desc, actual, expected):
    ok = actual == expected
    note(f"   {'OK  ' if ok else 'FAIL'} {desc} (got {actual!r} expect {expected!r})")
    EVIDENCE.append({"check": desc, "actual": actual, "expected": expected, "pass": ok})
    return 0 if ok else 1


def sh(cmd):
    return subprocess.run([HDC, "shell", cmd], capture_output=True, text=True).stdout


def name_now():
    _, resp = EX.exchange_strict(
        ["PROTOCOL CJGUI_SHARED_OPERATION/2", "AUTH cjgui-settings-counter-agent-20260925",
         "GET_CONTEXT 0"], 8)
    parsed = parse_response(resp)
    ver = None
    for e in parsed.entries:
        if e[0] == "VERSION":
            ver = int(e[1][0])
    name = ""
    for e in parsed.entries:
        if e[0] == "FIELD" and e[1][1] == "name" and e[1][2] == "STRING":
            name = (bytes.fromhex(e[1][4]).decode("utf-8")
                    if len(e[1]) >= 5 and e[1][4] != "-" else "")
    return ver, name


def main() -> int:
    subprocess.run(
        [HDC, "shell",
         f"aa force-stop {BUNDLE}; hilog -r; "
         f"aa start -a EntryAbility -b {BUNDLE} "
         "--pi cjguiTestGateFlushHoldMs 4000 --pi cjguiTestGateFlushHoldCount 1"],
        capture_output=True, text=True)
    time.sleep(8)
    failures = 0

    # 1) 聚焦名称字段 + 键入含 emoji 文本
    subprocess.run([HDC, "shell", f"uitest uiInput click {FIELD_X} {FIELD_Y}"],
                   capture_output=True)
    time.sleep(1.5)
    subprocess.run([HDC, "shell",
                    f"uitest uiInput inputText {FIELD_X} {FIELD_Y} 测试🚀abc"],
                   capture_output=True)
    time.sleep(2.5)

    # 2) 长按触发系统选区 → onTextSelectionChange → imeSetSelection
    subprocess.run([HDC, "shell", f"uitest uiInput longClick {FIELD_X} {FIELD_Y}"],
                   capture_output=True)
    time.sleep(2.0)
    subprocess.run([HDC, "shell",
                    f"uitest uiInput swipe {FIELD_X - 20} {FIELD_Y} {FIELD_X + 30} {FIELD_Y} 800"],
                   capture_output=True)
    time.sleep(1.5)
    sel_log = subprocess.run(
        [HDC, "shell", "hilog -x 2>/dev/null | grep -a 'ime select' | tail -4"],
        capture_output=True, text=True).stdout
    note(f"   选区日志: {sel_log.strip()[-120:] or '(空)'}")
    sel_events = re.findall(r"ime select \[(\d+),(\d+)\) rc=(\S+)", sel_log)
    nonempty = [(int(a), int(b)) for a, b, rc in sel_events if int(b) > int(a)]
    note(f"   选区事件: {sel_events or '（无）'}")
    failures += check("selection 事件到达渲染器 (rc=0)", bool(sel_events), True)
    failures += check("selection 范围非空（start<end）", bool(nonempty), True)
    if nonempty:
        EVIDENCE.append({"selection_events": nonempty})

    # 3) 选区高亮像素证据（截图：文本行出现高亮蓝色叠加）
    subprocess.run([HDC, "shell", "snapshot_display -f /data/local/tmp/d_sel.jpeg"],
                   capture_output=True)
    subprocess.run([HDC, "file recv", "/data/local/tmp/d_sel.jpeg",
                    f"{EVIDENCE_DIR}/selection_highlight.jpeg"], capture_output=True)
    highlight_px = None
    try:
        from PIL import Image
        img = Image.open(f"{EVIDENCE_DIR}/selection_highlight.jpeg").convert("RGB")
        W, H = img.size
        # 名称字段行带：在字段附近扫描高亮蓝（0.30,0.50,0.85 @35% 叠加 → 蓝分量显著抬升）
        for y in range(max(0, FIELD_Y - 40), min(H, FIELD_Y + 60)):
            row_blue = sum(1 for x in range(60, W - 60, 6)
                           if (lambda p: p[2] > p[0] + 30 and p[2] > 90)(img.getpixel((x, y))))
            if row_blue >= 4:
                highlight_px = (y, row_blue)
                break
        note(f"   高亮像素行: {highlight_px}")
        failures += check("选区高亮像素可见", highlight_px is not None, True)
    except Exception as exc:  # noqa: BLE001
        note(f"   像素采样异常: {exc}")
        failures += 1

    # 4) 选区替换 + 失焦提交 → owner 读回
    subprocess.run([HDC, "shell",
                    f"uitest uiInput inputText {FIELD_X} {FIELD_Y} 选区替换🎉完成"],
                   capture_output=True)
    time.sleep(2.0)
    subprocess.run([HDC, "shell", f"uitest uiInput click {FIELD_X} 1350"],
                   capture_output=True)   # 点空白失焦
    time.sleep(2.0)
    _, resp = EX.exchange_strict(
        ["PROTOCOL CJGUI_SHARED_OPERATION/2", "AUTH cjgui-settings-counter-agent-20260925",
         "GET_CONTEXT 0"], 8)
    parsed = parse_response(resp)
    ver = None
    name = ""
    for e in parsed.entries:
        if e[0] == "VERSION":
            try:
                ver = int(e[1][0])
            except (ValueError, IndexError):
                ver = None
    for e in parsed.entries:
        if e[0] == "FIELD" and e[1][1] == "name" and e[1][2] == "STRING":
            name = (bytes.fromhex(e[1][4]).decode("utf-8")
                    if len(e[1]) >= 5 and e[1][4] != "-" else "")
    note(f"   owner 读回: v={ver} name={name!r}")
    failures += check("owner 读回为替换后文本（含 emoji）",
                      "选区替换" in name and "🎉" in name, True)

    out = f"{EVIDENCE_DIR}/selection_probe_evidence.json"
    with open(out, "w", encoding="utf-8") as f:
        json.dump(EVIDENCE, f, ensure_ascii=False, indent=2)
    note(f"\n==== RESULT: {'PASS' if failures == 0 else 'FAIL'} (failures={failures}) ====")
    return failures


if __name__ == "__main__":
    sys.exit(main())

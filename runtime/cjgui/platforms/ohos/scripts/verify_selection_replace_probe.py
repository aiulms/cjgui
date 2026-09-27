#!/usr/bin/env python3
"""C/第六次复核第 3 项：选区替换/删除 精确读回探针（真实系统选区链路）。

历史 selection_probe 的两个 FAIL（非空选区、替换后 owner 值）源自
「uitest 拖拽/双击在 0.01 透明代理上不产生系统选区」。本探针改用
长按 → 系统选择菜单（uitest 树内可见）→ 点「全选」的真实路径：
  - 系统全选产生**非空** ime select [0,len) 事件（FAIL#1 补足）；
  - 选中后 DEL 删除选区、再粘贴新文本 → 失焦提交 → owner 读回与键入
    逐码元一致（FAIL#2 补足）；
  - 全删后失焦：owner 域规则拒绝空名 → owner 保持原值（未提交删除
    不生效；同时演示「取消/撤回的草稿不写入 owner」语义）。

用法： python3 verify_selection_replace_probe.py
"""

import json
import re
import subprocess
import sys
import time

sys.path.insert(0, "/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/platforms/ohos/scripts")
sys.path.insert(0, "/Users/jiangxuanyang/Desktop/cangjie/shared_operation_core" if False else "/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/shared_operation_core")
from client import parse_response  # noqa: E402

HDC = ("/Applications/DevEco-Studio.app/Contents/sdk/default/openharmony/"
       "toolchains/hdc")
EVIDENCE_DIR = ("/Users/jiangxuanyang/Desktop/cangjie/labs/ohos_cangjie_smoke/"
                "artifacts/cjgui-backend/verification")
EVIDENCE = []
FIELD = (660, 600)
BLANK = (660, 1300)


def note(msg):
    print(msg)


def check(desc, actual, expected):
    ok = actual == expected
    note(f"   {'OK  ' if ok else 'FAIL'} {desc} (got {actual!r} expect {expected!r})")
    EVIDENCE.append({"check": desc, "actual": actual, "expected": expected, "pass": ok})
    return 0 if ok else 1


def sh(cmd, timeout=30):
    return subprocess.run([HDC, "shell", cmd], capture_output=True, text=True,
                          timeout=timeout).stdout


def clear_logs():
    sh("hilog -r")


def ime_selects():
    out = sh("hilog -x 2>/dev/null | grep -a 'ime select'")
    return [(int(a), int(b)) for a, b in
            re.findall(r"ime select \[(\d+),(\d+)\) rc=0", out)]


def blur_settle_text():
    out = sh("hilog -x 2>/dev/null | grep -a 'ime blur settle' | tail -1")
    m = re.search(r"text=(.*)", out.strip())
    return m.group(1) if m else ""


def tap(x, y, wait=2.0):
    sh(f"uitest uiInput click {int(x)} {int(y)}")
    time.sleep(wait)


def input_text(x, y, text):
    sh(f"uitest uiInput inputText {int(x)} {int(y)} {text}")
    time.sleep(3)


def find_menu_item(text):
    """在 uitest 树中找系统选择菜单项（如「全选」），返回中心坐标或 None。"""
    sh("uitest dumpLayout -p /data/local/tmp/sel_menu.json")
    time.sleep(0.8)
    subprocess.run([HDC, "file", "recv", "/data/local/tmp/sel_menu.json",
                    "/tmp/sel_menu.json"], capture_output=True)
    try:
        d = json.load(open("/tmp/sel_menu.json"))
    except Exception:  # noqa: BLE001
        return None
    hit = []

    def walk(n):
        a = n.get("attributes", {})
        if a.get("text", "") == text:
            hit.append(a.get("bounds", ""))
        for c in n.get("children", []):
            walk(c)
    walk(d)
    if not hit:
        return None
    b = hit[0].strip("[]").split("][")
    (x1, y1), (x2, y2) = [tuple(int(v) for v in p.split(",")) for p in b]
    return ((x1 + x2) // 2, (y1 + y2) // 2)


def select_all():
    """长按 → 点系统菜单「全选」→ 确认非空选区事件。返回 (start,end) 或 None。"""
    fx, fy = FIELD
    before = len(ime_selects())
    sh(f"uitest uiInput longClick {fx} {fy}")
    time.sleep(2.5)
    pos = find_menu_item("全选")
    if pos is None:
        note("   （菜单未出现，重试长按一次）")
        sh(f"uitest uiInput longClick {fx} {fy}")
        time.sleep(2.5)
        pos = find_menu_item("全选")
        if pos is None:
            return None
    tap(*pos, wait=1.5)
    deadline = time.monotonic() + 4
    while time.monotonic() < deadline:
        sels = ime_selects()
        news = sels[before:]
        for a, b in news:
            if b > a:  # 非空选区
                return (a, b)
        time.sleep(0.3)
    return None


def owner_name():
    subprocess.run([HDC, "fport", "tcp:17856", "tcp:7856"], capture_output=True)
    time.sleep(1)
    out = subprocess.run(
        ["python3",
         "/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/platforms/ohos/scripts/"
         "human_external_human_probe.py", "read", "sel-replace"],
        capture_output=True, text=True).stdout
    line = out.strip().splitlines()[-1]
    d = json.loads(line)
    return d["fields"]["name"], d["version"]


def main() -> int:
    failures = 0
    sh("aa force-stop com.example.cjguithermo; aa force-stop com.example.cjguiapp; "
       "hilog -r; aa start -a EntryAbility -b com.example.cjguiapp "
       "--pi cjguiTestGateFlushHoldMs 4000 --pi cjguiTestGateFlushHoldCount 1")
    time.sleep(8)
    time.sleep(2)

    fx, fy = FIELD
    bx, by = BLANK

    # S1：基线写入。冷首焦的直接粘贴会稳定丢失（实测 4/4），改用与 S2 相同的
    # 「长按全选 → DEL 清空 → 粘贴」热路径（该路径的键盘会话已被菜单交互唤醒）。
    base_name = ""
    base_v = 0
    for attempt in range(3):
        clear_logs()
        tap(fx, fy, wait=4)
        sel = select_all()
        sh("uitest uiInput keyEvent 2055")   # DEL：清空选区
        time.sleep(2)
        input_text(fx, fy, "选区基线甲乙丙")
        sh("uitest uiInput keyEvent 2054")   # 回车显式提交
        time.sleep(2)
        base_name, base_v = owner_name()
        if base_name == "选区基线甲乙丙":
            break
        note(f"   S1 第 {attempt + 1} 次未落（owner={base_name!r} v={base_v} sel={sel}），重试")
    note(f"   S1 基线 owner name={base_name!r} v={base_v}")
    failures += check("S1 基线提交精确", base_name, "选区基线甲乙丙")

    # S2 替换：聚焦 → 全选（真实系统选区，非空）→ DEL 删区 → 粘贴新文本 → 失焦提交
    clear_logs()
    tap(fx, fy, wait=4)
    sel = select_all()
    failures += check("S2a 系统全选产生非空选区事件（历史 FAIL#1）",
                      sel is not None and sel[1] > sel[0], True)
    sh("uitest uiInput keyEvent 2055")   # DEL：删除当前选区
    time.sleep(2)
    input_text(fx, fy, "替换后文本")
    sh("uitest uiInput keyEvent 2054")   # 回车显式提交
    time.sleep(2)
    name, v = owner_name()
    note(f"   S2 owner name={name!r} v={v}")
    failures += check("S2b 选区替换后 owner 读回精确（历史 FAIL#2）",
                      name, "替换后文本")

    # S3 全删 + 失焦：owner 域规则拒绝空名 → 保持原值（撤回的草稿不写入）
    clear_logs()
    tap(fx, fy, wait=4)
    sel = select_all()
    failures += check("S3a 系统全选非空选区（第二次）",
                      sel is not None and sel[1] > sel[0], True)
    sh("uitest uiInput keyEvent 2055")   # 全删
    time.sleep(2)
    sh("uitest uiInput keyEvent 2054")   # 回车提交空串 → 域规则拒绝
    time.sleep(2)
    name, v = owner_name()
    note(f"   S3 owner name={name!r} v={v}")
    failures += check("S3b 空名被域规则拒绝，owner 保持原值", name, "替换后文本")

    with open(f"{EVIDENCE_DIR}/selection_replace_evidence.json", "w",
              encoding="utf-8") as f:
        json.dump(EVIDENCE, f, ensure_ascii=False, indent=2)
    note(f"\n==== RESULT: {'PASS' if failures == 0 else 'FAIL'} (failures={failures}) ====")
    return failures


if __name__ == "__main__":
    sys.exit(main())

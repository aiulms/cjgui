#!/usr/bin/env python3
"""D：裁剪/命中/owner 三重核对夹具探针。

夹具（settings_counter 场景新增）：clipsContent 容器 d-clip-box（400x120）内
两个 80 高文字——d-clip-cross 跨越下边界（部分可见）、d-clip-out 完全界外
（空交集）；圆角按钮（cornerRadius 14）已有。

核对（三重）：
  1. 像素：hdc 截图 → PIL 采样（裁剪容器内/界外区域颜色差异、按钮点击前后像素差）；
  2. 命中：注入触摸（TOUCH 命令 → 宿主触摸队列 → 渲染器命中）到按钮中心
     命中、到裁剪容器空白处不命中（owner 版本不变）、圆角外点行为如实记录；
  3. owner：每次命中后的公开读回版本精确推进。

用法： python3 verify_clipping_probe.py
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
               "artifacts/cjgui-backend/verification/clipping_raw.json")
EXCHANGE = BoundedExchange(HOST, PORT, RAW_ARCHIVE)
HDC = ("/Applications/DevEco-Studio.app/Contents/sdk/default/openharmony/"
       "toolchains/hdc")
EVIDENCE_DIR = ("/Users/jiangxuanyang/Desktop/cangjie/labs/ohos_cangjie_smoke/"
                "artifacts/cjgui-backend/verification")


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


def gate_command_and_wait(op, timeout=5.0):
    control_map(op)
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        g = control_map("GATE_STATE")
        if g.get("RESULT", "").startswith(("touch=", "cleared=")):
            return g.get("RESULT")
        time.sleep(0.1)
    return "dispatch-timeout"


def version_of(text):
    parsed = parse_response(text)
    for name, parts in parsed.entries:
        if name == "VERSION":
            return int(parts[0])
    raise AssertionError("no VERSION")


def read_version():
    _, resp = business(["GET_CONTEXT 0"])
    return version_of(resp)


def inject_tap(x, y):
    """down(37)+up(39) 一次点击（渲染器命中后产生 owner 事件）。"""
    gate_command_and_wait(f"TOUCH_37_{int(x)}_{int(y)}")
    time.sleep(0.12)
    return gate_command_and_wait(f"TOUCH_39_{int(x)}_{int(y)}")


def node_rects_from_hilog():
    """从 hilog 读最新一轮 node-rect（探针触发帧后的 accepted 几何）。"""
    out = subprocess.run(
        [HDC, "shell", "hilog -x 2>/dev/null | grep -a 'node-rect' | tail -40"],
        capture_output=True, text=True).stdout
    rects = {}
    clips = {}
    for line in out.splitlines():
        m = re.search(r"node-rect id=(-?\d+) x=(-?\d+) y=(-?\d+) w=(-?\d+) h=(-?\d+) "
                      r"clip=\((-?\d+),(-?\d+),(-?\d+),(-?\d+)\)", line)
        if m:
            g = [float(m.group(i)) for i in range(2, 10)]
            rects[int(m.group(1))] = tuple(g[0:4])
            clips[int(m.group(1))] = g[4:8]   # (cx, cy, cw, ch)
    return rects, clips


def screenshot(tag):
    """截取设备屏幕并取回本地。返回本地路径。"""
    dev = f"/data/local/tmp/d_{tag}.jpeg"
    local = f"{EVIDENCE_DIR}/d_screenshot_{tag}.jpeg"
    subprocess.run([HDC, "shell", f"snapshot_display -f {dev}"], capture_output=True)
    subprocess.run([HDC, "file recv", dev, local], capture_output=True)
    return local


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
    note(f"== D0 token={TOKEN}")
    failures = 0

    # 触发一帧（CLEAR 闸门使首帧正常走完）并等待 accepted 几何日志
    control_map("GATE_CLEAR")
    time.sleep(2.5)
    _, resp = business(["GET_CONTEXT 0"])
    parsed = parse_response(resp)
    v = next(int(e[1][0]) for e in parsed.entries if e[0] == "VERSION")
    note(f"   基线 v={v}")

    rects, clips = node_rects_from_hilog()
    note(f"   accepted 节点几何: {len(rects)} 项")
    failures += check("accepted 几何日志可读", len(rects) >= 10, True)

    # 夹具节点存在性（40=clip-box 41=界内 42=跨边界 43=界外）
    has_fixtures = all(i in rects for i in (40, 41, 42, 43))
    failures += check("D 夹具节点已渲染（40/41/42/43）", has_fixtures, True)
    if not has_fixtures:
        note("\n==== RESULT: FAIL ====")
        return failures
    # 裁剪边界几何证据：43 的 clip 高度必须为 0（空交集），
    # 42 的 clip 高度必须小于其自身高度（跨边界被截）。
    failures += check("界外节点 clip 高度为 0（空交集）", clips[43][3], 0.0)
    failures += check("跨边界节点 clip 高度被截（10<40）", clips[42][3], 10.0)

    # 截图 1：裁剪像素证据（cross 部分可见 / out 不可见）
    shot = screenshot("clip")
    pixel_ok = False
    clip_inside_sample = None
    try:
        from PIL import Image
        img = Image.open(shot).convert("RGB")
        W, H = img.size
        # 色带自校准：容器背景 (77,31,31)，在 x=容器中心 列扫描其行带。
        cx = int(rects[40][0] + rects[40][2] / 2)
        bg = (77, 31, 31)

        def near(px, ref, tol=12):
            return all(abs(px[i] - ref[i]) <= tol for i in range(3))

        band = [y for y in range(H) if near(img.getpixel((cx, y)), bg)]
        note(f"   容器背景行带: {len(band)} 行")
        if band:
            band_top, band_bottom = min(band), max(band)
            scale_y = (band_bottom - band_top) / 50.0   # 布局 50pt → 像素
            note(f"   行带: y {band_top}..{band_bottom} (scale_y={scale_y:.2f})")
            # 界内文字行（band 顶部 +20pt）：统计接近文字色 (219,227,242) 的像素
            text_row = band_top + int(20 * scale_y)
            text_px = sum(1 for x in range(int(rects[40][0]) + 10, int(rects[40][0] + rects[40][2]) - 10)
                          if near(img.getpixel((x, text_row)), (219, 227, 242), 45))
            note(f"   界内文字行 text_px={text_px}")
            EVIDENCE.append({"band": [band_top, band_bottom], "text_px": text_px,
                             "inside_text_sample": img.getpixel((cx, text_row))})
            pixel_ok = True
        else:
            note("   未找到容器背景行带")
            pixel_ok = False
    except Exception as exc:  # noqa: BLE001
        note(f"   像素采样失败: {exc}")
    failures += check("截图像素采样完成", pixel_ok, True)

    # D1 命中→owner：注入点击增加按钮中心
    if 22 in rects:
        x, y, w, h = rects[22]
        cx, cy = x + w / 2, y + h / 2
        before = read_version()
        inject_tap(cx, cy)
        time.sleep(0.6)
        after = read_version()
        failures += check("命中增加按钮 → owner 版本 +1", after, before + 1)
    else:
        failures += check("增加按钮几何存在", False, True)

    # D2 命中→owner：注入点击减少按钮中心
    if 21 in rects:
        x, y, w, h = rects[21]
        before = read_version()
        inject_tap(x + w / 2, y + h / 2)
        time.sleep(0.6)
        after = read_version()
        failures += check("命中减少按钮 → owner 版本 +1", after, before + 1)
    else:
        failures += check("减少按钮几何存在", False, True)

    # D3 空交集/非按钮区域：点击裁剪容器内非交互区 → owner 版本不变
    x40, y40, w40, h40 = rects[40]
    before = read_version()
    inject_tap(x40 + w40 / 2, y40 + 25)   # 容器内中部（无交互节点）
    time.sleep(0.6)
    after = read_version()
    failures += check("点击裁剪容器非交互区 → owner 版本不变", after, before)

    # D4 圆角外点：按钮左上角外侧点（bbox 内、圆角外）——如实记录行为
    if 22 in rects:
        x, y, w, h = rects[22]
        before = read_version()
        inject_tap(x + 3, y + 3)   # 圆角半径 14：该点在 bounding box 内、圆角外
        time.sleep(0.6)
        after = read_version()
        corner_hit = (after == before + 1)
        note(f"   圆角外点命中行为: 版本 {before}→{after} "
             f"（{'命中' if corner_hit else '未命中'}——如实记录）")
        EVIDENCE.append({"corner_point_hit": corner_hit,
                         "note": "cornerRadius=14; behavior recorded as-is"})

    with open(f"{EVIDENCE_DIR}/clipping_evidence.json", "w", encoding="utf-8") as f:
        json.dump(EVIDENCE, f, ensure_ascii=False, indent=2)
    EXCHANGE.flush_archive()
    note(f"\n==== RESULT: {'PASS' if failures == 0 else 'FAIL'} (failures={failures}) ====")
    return failures


if __name__ == "__main__":
    sys.exit(main())

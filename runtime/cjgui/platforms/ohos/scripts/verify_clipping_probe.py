#!/usr/bin/env python3
"""D：裁剪/命中/owner 三重核对夹具探针。

夹具（settings_counter 正常应用场景）：clipsContent 容器 d-clip-box（400x50）内
三个 40 高文字节点——d-clip-cross 跨越下边界（部分可见）、d-clip-out
有正尺寸布局但完全界外（空交集）；另有跨界按钮与不裁剪孪生按钮。

核对（三重）：
  1. 像素：hdc 全屏截图 → 场景坐标校准 → PIL 采样专属色；
  2. 命中：注入触摸（TOUCH 命令 → 宿主触摸队列 → 渲染器命中）到按钮中心
     命中、到裁剪容器空白处不命中、圆角外点不命中；
  3. owner：每次命中后的公开读回版本与 count 精确推进。

用法： python3 verify_clipping_probe.py
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
    BoundedExchange, GateCommandError, gate_command)
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
EVIDENCE = []
EVIDENCE_DIR = Path(os.environ.get(
    "CJGUI_OHOS_VERIFICATION_DIR",
    "/Users/jiangxuanyang/Desktop/cangjie/labs/ohos_cangjie_smoke/"
    "artifacts/cjgui-backend/verification"))
EVIDENCE_DIR.mkdir(parents=True, exist_ok=True)
RAW_ARCHIVE = str(EVIDENCE_DIR / "clipping_raw.json")
EXCHANGE = BoundedExchange(HOST, PORT, RAW_ARCHIVE)
atexit.register(EXCHANGE.flush_archive)
HDC = os.environ.get(
    "HDC",
    "/Applications/DevEco-Studio.app/Contents/sdk/default/openharmony/"
    "toolchains/hdc")
RUN_ID = os.environ.get("CJGUI_OHOS_RUN_ID", "")
TARGET = os.environ.get("CJGUI_REAL_DEVICE_TARGET", "")


def note(msg):
    print(msg)


def check(desc, actual, expected, details=None):
    ok = actual == expected
    note(f"   {'OK  ' if ok else 'FAIL'} {desc} (got {actual!r} expect {expected!r})")
    entry = {"check": desc, "actual": actual, "expected": expected, "pass": ok}
    if details is not None:
        entry["details"] = details
    EVIDENCE.append(entry)
    return 0 if ok else 1


def business(lines, timeout=8.0):
    return EXCHANGE.exchange_strict(
        [f"PROTOCOL {PROTOCOL}", f"AUTH {CAP}"] + lines, timeout)


def gate_command_and_wait(op, timeout=8.0):
    """Wait for this command's own PUBLISHED/RESULT_ID pair, then check its rc."""
    result = gate_command(EXCHANGE, TOKEN, op, timeout=timeout)
    if op.startswith("TOUCH_") and result != "touch=0":
        raise GateCommandError(f"{op}: native touch did not succeed ({result!r})")
    if op == "GATE_CLEAR" and not result.startswith("cleared="):
        raise GateCommandError(f"{op}: clear result missing ({result!r})")
    return result


def owner_state_of(text):
    parsed = parse_response(text)
    if parsed.kind != "SNAPSHOT":
        raise AssertionError(f"GET_CONTEXT returned {parsed.kind!r}")
    version = None
    count = None
    projection = None
    for name, parts in parsed.entries:
        if name == "VERSION":
            version = int(parts[0])
        elif name == "FIELD" and len(parts) == 4 and parts[:3] == (
                str(RESOURCE_ID), "count", "INTEGER"):
            count = int(parts[3])
        elif name == "WINDOW_PROJECTION":
            projection = parts[0]
    if version is None or count is None:
        raise AssertionError("GET_CONTEXT lacks owner version or count field")
    return {"version": version, "count": count, "window_projection": projection}


def read_owner():
    _, resp = business(["GET_CONTEXT 0"])
    return owner_state_of(resp)


def inject_tap(x, y):
    """down(37)+up(39) 一次点击（渲染器命中后产生 owner 事件）。"""
    gate_command_and_wait(f"TOUCH_37_{int(x)}_{int(y)}")
    time.sleep(0.12)
    return gate_command_and_wait(f"TOUCH_39_{int(x)}_{int(y)}")


def tap_points(rects, clips):
    """Derive points from accepted bounds; reject a vacuous hit negative control."""
    x45, y45, w45, h45 = rects[45]
    cx45, cy45, cw45, ch45 = clips[45]
    x47, y47, w47, h47 = rects[47]
    cx47, cy47, cw47, ch47 = clips[47]
    if (min(w45, h45, cw45, ch45, w47, h47) <= 0
            or not (y45 <= cy45 < cy45 + ch45 < y45 + h45)
            or not (x45 <= cx45 < cx45 + cw45 <= x45 + w45)
            or (cx47, cy47, cw47, ch47) != (x47, y47, w47, h47)):
        raise ValueError("clipped/noclip hit fixtures lack expected accepted geometry")
    mid_x = x45 + w45 / 2
    visible_y = cy45 + ch45 / 2
    hidden_y = (cy45 + ch45 + y45 + h45) / 2
    if not (cx45 <= mid_x < cx45 + cw45 and y45 <= hidden_y < y45 + h45):
        raise ValueError("hit points lie outside fixture bounds")
    for node_id in (46, 47):
        x, y, w, h = rects[node_id]
        if x <= mid_x < x + w and y <= hidden_y < y + h:
            raise ValueError(f"clipped hidden point overlaps later node {node_id}")
    return {
        "clip_visible": (mid_x, visible_y),
        "clip_hidden": (mid_x, hidden_y),
        "noclip_visible": (x47 + w47 / 2, y47 + h47 * 0.25),
        "noclip_outside_parent": (x47 + w47 / 2, y47 + h47 * 0.75),
    }


def node_rects_from_hilog(pid):
    """Read one complete accepted geometry batch from the current process."""
    result = subprocess.run([HDC, "shell", "hilog -x"], capture_output=True, text=True)
    if result.returncode != 0:
        raise RuntimeError(f"hilog failed: {result.stderr.strip()}")
    batches = []
    rects, clips = {}, {}
    for line in result.stdout.splitlines():
        prefix = re.match(r"^\S+\s+\S+\s+(\d+)\s+\d+\s+[A-Z]\s+", line)
        if not prefix or prefix.group(1) != pid:
            continue
        m = re.search(r"node-rect id=(-?\d+) x=(-?\d+) y=(-?\d+) w=(-?\d+) h=(-?\d+) "
                      r"clip=\((-?\d+),(-?\d+),(-?\d+),(-?\d+)\)", line)
        if not m:
            continue
        node_id = int(m.group(1))
        if node_id == 1 and rects:
            batches.append((rects, clips))
            rects, clips = {}, {}
        if node_id in rects:
            raise ValueError(f"duplicate node {node_id} in accepted geometry batch")
        g = tuple(float(m.group(i)) for i in range(2, 10))
        rects[node_id] = g[:4]
        clips[node_id] = g[4:]
    if rects:
        batches.append((rects, clips))
    if not batches:
        raise ValueError(f"no accepted node geometry for pid {pid}")
    return batches[-1]


def pixel_regions(rects, clips, image_size, offset=(0, 0)):
    """Require a drawable negative-control node and unobscured visible/hidden ROIs."""
    x40, y40, w40, h40 = rects[40]
    x42, y42, w42, h42 = rects[42]
    cx42, cy42, cw42, ch42 = clips[42]
    x43, y43, w43, h43 = rects[43]
    if min(w40, h40, w42, h42, w43, h43) <= 0:
        raise ValueError("clip fixture has an empty layout rect")
    if not (x42 <= cx42 < cx42 + cw42 <= x42 + w42
            and y42 <= cy42 < cy42 + ch42 < y42 + h42):
        raise ValueError("cross node lacks a partial visible and hidden region")
    if clips[43][3] != 0 or y43 < y40 + h40:
        raise ValueError("outside node is not wholly beyond the clip box")
    regions = {
        "cross_visible": (cx42, cy42, cx42 + cw42, cy42 + ch42),
        "cross_hidden": (x42, cy42 + ch42, x42 + w42, y42 + h42),
        "fully_out": (x43, y43, x43 + w43, y43 + h43),
    }
    for label in ("cross_hidden", "fully_out"):
        ax0, ay0, ax1, ay1 = regions[label]
        for node_id in (44, 45, 46, 47):
            bx, by, bw, bh = rects[node_id]
            if max(ax0, bx) < min(ax1, bx + bw) and max(ay0, by) < min(ay1, by + bh):
                raise ValueError(f"{label} is occluded by later node {node_id}")
    dx, dy = offset
    width, height = image_size
    shifted = {}
    for label, (x0, y0, x1, y1) in regions.items():
        region = (int(x0 + dx), int(y0 + dy), int(x1 + dx), int(y1 + dy))
        if not (0 <= region[0] < region[2] <= width
                and 0 <= region[1] < region[3] <= height):
            raise ValueError(f"{label} is empty or outside screenshot: {region}")
        shifted[label] = region
    return shifted


def register_scene_to_screenshot(img, anchor_rect, anchor_rgb, tol=12):
    """Locate the unique clip-box background in full-screen screenshot pixels."""
    width, height = img.size
    min_x, min_y, max_x, max_y = width, height, -1, -1
    matches = 0
    pixels = (img.get_flattened_data() if hasattr(img, "get_flattened_data")
              else img.getdata())
    for i, pixel in enumerate(pixels):
        if all(abs(pixel[c] - anchor_rgb[c]) <= tol for c in range(3)):
            x, y = i % width, i // width
            min_x, min_y = min(min_x, x), min(min_y, y)
            max_x, max_y = max(max_x, x), max(max_y, y)
            matches += 1
    ax, ay, aw, ah = anchor_rect
    bbox_width = max_x - min_x + 1
    bbox_height = max_y - min_y + 1
    if (matches < aw * ah // 4 or bbox_width < aw * 0.8
            or bbox_width > aw + 4 or bbox_height < ah * 0.5
            or bbox_height > ah + 4):
        raise ValueError(f"clip-box screenshot anchor absent or ambiguous: "
                         f"pixels={matches} bbox={(min_x, min_y, max_x, max_y)}")
    return int(min_x - ax), int(min_y - ay)


def current_pid():
    result = subprocess.run([HDC, "shell", "pidof com.example.cjguiapp"],
                            capture_output=True, text=True)
    pid = result.stdout.strip() if result.returncode == 0 else ""
    if not re.fullmatch(r"[1-9]\d*", pid):
        raise RuntimeError(f"current app PID unavailable: {pid!r}")
    return pid


def screenshot(tag, pid):
    """截取设备屏幕并取回本地。返回本地路径。"""
    if current_pid() != pid:
        raise RuntimeError("app PID changed before screenshot")
    name = f"d_screenshot_{tag}_{RUN_ID or 'direct'}_{time.time_ns()}.jpeg"
    dev = f"/data/local/tmp/{name}"
    local = EVIDENCE_DIR / name
    captured = subprocess.run([HDC, "shell", f"snapshot_display -f {dev}"],
                              capture_output=True, text=True)
    if captured.returncode != 0 or "fail" in (captured.stdout + captured.stderr).lower():
        raise RuntimeError(f"snapshot_display failed: rc={captured.returncode} "
                           f"{captured.stderr.strip()!r}")
    received = subprocess.run([HDC, "file recv", dev, str(local)],
                              capture_output=True, text=True)
    if (received.returncode != 0 or not local.is_file() or local.stat().st_size == 0
            or current_pid() != pid):
        raise RuntimeError(f"screenshot recv/identity failed: rc={received.returncode} "
                           f"{received.stderr.strip()!r}")
    return str(local)


def main() -> int:
    global TOKEN
    for label, command in (
        ("force-stop", "aa force-stop com.example.cjguiapp"),
        ("hilog-clear", "hilog -r"),
        ("app-start", "aa start -a EntryAbility -b com.example.cjguiapp "
         "--pi cjguiTestGateFlushHoldMs 4000 --pi cjguiTestGateFlushHoldCount 1"),
    ):
        result = subprocess.run([HDC, "shell", command], capture_output=True, text=True)
        if result.returncode != 0:
            note(f"FAIL {label} rc={result.returncode} stdout={result.stdout.strip()!r} "
                 f"stderr={result.stderr.strip()!r}")
            return 2
    time.sleep(8)
    pid_result = subprocess.run([HDC, "shell", "pidof com.example.cjguiapp"],
                                capture_output=True, text=True)
    pid = pid_result.stdout.strip() if pid_result.returncode == 0 else ""
    token_out = subprocess.run([HDC, "shell", "hilog -x"], capture_output=True, text=True)
    token = None
    if pid and re.fullmatch(r"\d+", pid) and token_out.returncode == 0:
        for line in reversed(token_out.stdout.splitlines()):
            if "verify seam armed token=" not in line:
                continue
            line_pid = re.match(r"^\S+\s+\S+\s+(\d+)\s+\d+\s+[A-Z]\s+", line)
            line_token = re.search(r"verify seam armed token=(\S+)", line)
            if line_pid and line_token and line_pid.group(1) == pid:
                token = line_token.group(1)
                break
    if not token:
        note(f"FAIL app identity incomplete or stale: pid={pid or '<missing>'} "
             f"pidof_rc={pid_result.returncode} hilog_rc={token_out.returncode} "
             f"token_pid_match=no pidof_stderr={pid_result.stderr.strip()!r} "
             f"hilog_stderr={token_out.stderr.strip()!r}")
        return 2
    TOKEN = token
    note(f"PROBE_INSTANCE run_id={RUN_ID} target={TARGET} pid={pid} token={TOKEN}")
    note(f"== D0 token={TOKEN}")
    failures = 0

    # 触发一帧（CLEAR 闸门使首帧正常走完）并等待 accepted 几何日志
    gate_command_and_wait("GATE_CLEAR")
    time.sleep(2.5)
    baseline = read_owner()
    note(f"   基线 owner={baseline}")

    rects, clips = node_rects_from_hilog(pid)
    note(f"   accepted 节点几何: {len(rects)} 项")
    failures += check("accepted 几何日志可读", len(rects) >= 10, True)

    # 夹具节点存在性（40=clip-box 41=界内 42=跨边界 43=界外
    #                  44=clip-btn-box 45=裁剪按钮 46=noclip-btn-box 47=不裁按钮）
    has_fixtures = all(i in rects for i in (40, 41, 42, 43, 44, 45, 46, 47))
    failures += check("D 夹具节点已渲染（40/41/42/43/44/45/46/47）", has_fixtures, True)
    if not has_fixtures:
        note("\n==== RESULT: FAIL ====")
        return failures
    # 裁剪边界几何证据：43 必须有正尺寸布局、却有空裁剪；
    # 42 的 clip 高度必须小于其自身高度（跨边界被截）。
    failures += check("界外节点布局高度为正（负控非空）", rects[43][3] > 0, True)
    failures += check("界外节点 clip 高度为 0（空交集）", clips[43][3], 0.0)
    failures += check("跨边界节点 clip 高度被截（10<40）", clips[42][3], 10.0)

    def pixel_target_count(img, x0, y0, x1, y1, ref, tol=45, step=2):
        """目标色像素计数（step 采样）。"""
        return sum(1 for y in range(y0, y1, step) for x in range(x0, x1, step)
                   if all(abs(img.getpixel((x, y))[i] - ref[i]) <= tol for i in range(3)))

    # 截图 1：裁剪像素证据——可见区必须出现目标文字像素、被裁/界外区必须没有。
    # 这是「可见区有目标像素 + 被裁部分无目标像素」的硬断言（修复背景色带假绿）。
    pixel_ok = False
    try:
        from PIL import Image
        shot = screenshot("clip", pid)
        img = Image.open(shot).convert("RGB")
        # snapshot_display 截全屏；accepted 节点坐标以 XComponent 为原点。
        # 先用唯一红色 clip-box 背景求平移，再严格检查所有 ROI 在屏内且未遮挡。
        offset = register_scene_to_screenshot(img, rects[40], (77, 31, 31))
        regions = pixel_regions(rects, clips, img.size, offset)
        cross_color = (10, 209, 191)
        out_color = (242, 115, 26)
        visible_px = pixel_target_count(img, *regions["cross_visible"], cross_color, tol=35)
        hidden_px = pixel_target_count(img, *regions["cross_hidden"], cross_color, tol=35)
        out_px = pixel_target_count(img, *regions["fully_out"], out_color, tol=35)
        counts = {"cross_visible_px": visible_px, "cross_hidden_px": hidden_px,
                  "out_rect_px": out_px, "surface_offset_px": offset,
                  "regions": regions, "screenshot": shot}
        note(f"   全屏校准 offset={offset} 跨界可见={visible_px} 被裁={hidden_px} "
             f"界外={out_px}")
        failures += check("跨边界可见区出现专属像素（>=50）", visible_px >= 50,
                          True, details=counts)
        failures += check("跨边界被裁区无专属像素", hidden_px, 0)
        failures += check("正尺寸界外节点无专属像素", out_px, 0)
        pixel_ok = True
    except Exception as exc:  # noqa: BLE001
        note(f"   像素采样失败: {exc}")
    failures += check("截图像素采样完成", pixel_ok, True)

    def verify_tap(desc, x, y, version_delta, count_delta):
        nonlocal failures
        before = read_owner()
        inject_tap(x, y)
        time.sleep(0.6)
        after = read_owner()
        failures += check(f"{desc}: owner 版本精确变化", after["version"],
                          before["version"] + version_delta,
                          details={"before": before, "after": after, "point": (x, y)})
        failures += check(f"{desc}: count 精确变化", after["count"],
                          before["count"] + count_delta)

    # D1 命中→owner：注入点击增加按钮中心
    if 22 in rects:
        x, y, w, h = rects[22]
        cx, cy = x + w / 2, y + h / 2
        verify_tap("命中增加按钮", cx, cy, 1, 1)
    else:
        failures += check("增加按钮几何存在", False, True)

    # D2 命中→owner：注入点击减少按钮中心
    if 21 in rects:
        x, y, w, h = rects[21]
        verify_tap("命中减少按钮", x + w / 2, y + h / 2, 1, -1)
    else:
        failures += check("减少按钮几何存在", False, True)

    # D3 空交集/非按钮区域：点击裁剪容器内非交互区 → owner 版本不变
    x40, y40, w40, h40 = rects[40]
    verify_tap("点击裁剪容器非交互区", x40 + w40 / 2, y40 + 25, 0, 0)

    # D4 圆角外点：按钮左上角外侧点（bbox 内、圆角外）。已声明契约（并已
    # 实现）：cornerRadius=14 的按钮，命中几何与绘制几何一致，四分圆外的点
    # 不得命中 → owner 不得推进（硬断言，不再仅记录观察）。
    if 22 in rects:
        x, y, w, h = rects[22]
        verify_tap("D4 圆角外点不命中", x + 3, y + 3, 0, 0)

    # D5–D7（第六次复核第 4 项）：裁剪边界**命中**真负控。
    # 45=裁剪按钮（容器 50 高、按钮 80 高：可见 0..50、被裁 50..80）；
    # 47=noclip 孪生（clipsContent:false，同几何同动作）。判据：
    #   可见区命中 → owner +1；被裁区点击 → owner 不变（D5/D6）；
    #   noclip 按钮同几何两点都命中（D7 负控：证明 D6 未命中确由裁剪所致）。
    points = tap_points(rects, clips)
    failures += check("D5–D7 命中坐标与真实 clip 一致", True, True, details=points)
    verify_tap("D5 裁剪按钮可见区命中", *points["clip_visible"], 1, 1)
    verify_tap("D6 裁剪按钮被裁区不命中", *points["clip_hidden"], 0, 0)
    verify_tap("D7 noclip 负控可见区命中", *points["noclip_visible"], 1, 1)
    verify_tap("D7 noclip 负控界外位命中", *points["noclip_outside_parent"], 1, 1)

    with open(EVIDENCE_DIR / "clipping_evidence.json", "w", encoding="utf-8") as f:
        json.dump(EVIDENCE, f, ensure_ascii=False, indent=2)
    EXCHANGE.flush_archive()
    note(f"\n==== RESULT: {'PASS' if failures == 0 else 'FAIL'} (failures={failures}) ====")
    return failures


if __name__ == "__main__":
    sys.exit(main())

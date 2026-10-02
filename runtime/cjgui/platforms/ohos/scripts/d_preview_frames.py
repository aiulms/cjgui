#!/usr/bin/env python3
"""D（h-source-preview-next）补充取证：预览画面像素 + 中段选区切换。

前置：Pharos OHOS normal 产物已安装并运行（新渲染器）。本脚本：
  1. 经公开 agent 通道（REPLACE_RANGE）把正文整体换成 Markdown 夹具
     （标题/加粗/斜体/行内代码/列表）；
  2. 源码模式截图；
  3. 切预览 → 截图（标题/强调/代码底色必须在真实画面上可辨）；
  4. 切回源码 → longClick 选中一个词（非空选区）→ 截图 + hilog 选区行；
  5. 带选区切预览 → 切回源码 → 截图对比：选区应恢复（同一词高亮）。
正文判定走 owner 读回；所有截图与判定写入输出目录。
"""

import json
import os
import re
import socket
import subprocess
import sys
import time

HDC = "/Applications/DevEco-Studio.app/Contents/sdk/default/openharmony/toolchains/hdc"
TARGET = "127.0.0.1:5555"
BUNDLE = "com.pharos.mark"
CAP = "pharos-local-capability"
OUT = ("/Users/jiangxuanyang/Desktop/cangjie/artifacts/h-source-preview-20260930/"
       "d-preview/frames-selection")

FIXTURE = "# 预览取证标题\n\n正文含 **加粗强调** 与 *斜体强调* 以及 `行内代码` 三种样式。\n\n- 列表项一\n- 列表项二\n"
SELECT_WORD = "加粗强调"   # longClick 落点：加粗段中点


def hdc(*args, timeout=30):
    return subprocess.run([HDC, "-t", TARGET] + list(args), capture_output=True,
                          text=True, errors="replace", timeout=timeout)


def uitest(*args, timeout=30):
    return hdc("shell", "uitest", "uiInput", *args, timeout=timeout)


def hilog_rows():
    r = hdc("shell", "hilog -x", timeout=20)
    return (r.stdout or "").splitlines()


def device_pid():
    out = hdc("shell", f"pidof {BUNDLE}").stdout.strip()
    return out.split()[0] if out else ""


def ensure_foreground():
    if not device_pid():
        hdc("shell", f"aa start -a EntryAbility -b {BUNDLE}")
        time.sleep(4)
    hdc("shell", "uitest", "dumpLayout", "-p", "/data/local/tmp/fg.json")
    raw = hdc("shell", "cat", "/data/local/tmp/fg.json").stdout
    m = re.search(r'"bundleName":"([^"]+)"', raw)
    return (m.group(1) if m else "") == BUNDLE


# ---- 公开操作通道（与 h_source_preview_consumption.py 同协议） ----

def frame_of(payload):
    encoded = payload.encode("utf-8")
    return str(len(encoded)).encode("ascii") + b"\n" + encoded


def request(payload_lines, port, timeout=8):
    payload = "\n".join(["PROTOCOL CJGUI_SHARED_OPERATION/2", f"AUTH {CAP}"] + payload_lines)
    with socket.create_connection(("127.0.0.1", port), timeout=timeout) as sock:
        sock.settimeout(timeout)
        sock.sendall(frame_of(payload))
        received = bytearray()
        while b"\nEND" not in received:
            chunk = sock.recv(65536)
            if not chunk:
                break
            received.extend(chunk)
        return received.decode("utf-8", errors="replace")


def context_facts(port):
    resp = request(["GET_CONTEXT 0"], port)
    mv = re.search(r"VERSION (\d+)", resp)
    ml = re.search(r"byteLength INTEGER (\d+)", resp)
    if not mv or not ml:
        raise RuntimeError(f"GET_CONTEXT failed: {resp[:200]}")
    return int(mv.group(1)), int(ml.group(1))


def read_all(port):
    """全文读回。GET_CONTEXT 的 byteLength 是文档真实字节长度（文档末尾必为
    标量边界）；分窗读取时中间窗尾可能落在多字节字符内部（invalid_text_boundary
    非单调：77 拒 82 收），对窗尾做 ≤4 字节回退，不做二分——二分会把
    非边界误当越界收敛到假长度，令后续整段替换留下旧尾巴。"""
    version, total = context_facts(port)
    hexstr = ""
    off = 0
    while off < total:
        want = min(off + 65536, total)
        resp = None
        back = 0
        while want - back > off and back <= 4:
            resp = request(["READ_RANGE 1 %d %d %d" % (off, want - back, version)], port)
            if "CONTENT_UTF8_HEX" in resp:
                break
            back += 1
        m = re.search(r"CONTENT_UTF8_HEX (\d+) ([0-9a-fA-F]*)", resp or "")
        if not m:
            raise RuntimeError(f"READ_RANGE failed at {off}: {(resp or '')[:160]}")
        hexstr += m.group(2)
        got = int(m.group(1))
        off += got
        if got == 0:
            raise RuntimeError("READ_RANGE zero-length chunk")
    return version, hexstr


def agent_replace_all(port, hex_text):
    version, total = context_facts(port)
    n = len(hex_text) // 2
    return request([
        f"INVOKE {version} REPLACE_RANGE 1 4", "ID 1",
        f"ARG start INTEGER 0",
        f"ARG end INTEGER {total}",
        f"ARG text STRING {n} {hex_text}",
        f"ARG expectedVersion INTEGER {version}"], port)


# ---- 画面/几何（与 C 驱动同链） ----

RECT_PAT = re.compile(r"node-rect id=(-?\d+) x=(-?\d+) y=(-?\d+) w=(\d+) h=(\d+) "
                      r"clip=\((-?\d+),(-?\d+),(-?\d+),(-?\d+)\)")


def pid_rows(pid):
    rows = hilog_rows()
    return [r for r in rows if f" {pid} " in r] or rows


def node_geometry(rows, semantic):
    nid = None
    for row in rows:
        if "accepted node=" in row and f"semantic={semantic} " in row:
            m = re.search(r"accepted node=(-?\d+)", row)
            if m:
                nid = m.group(1)
    if nid is None:
        return None
    last = None
    for row in rows:
        m = RECT_PAT.search(row)
        if m and m.group(1) == nid:
            x, y, w, h = (int(m.group(2)), int(m.group(3)), int(m.group(4)), int(m.group(5)))
            cx, cy, cw, ch = (int(m.group(6)), int(m.group(7)), int(m.group(8)), int(m.group(9)))
            left, top = max(x, cx), max(y, cy)
            right, bottom = min(x + w, cx + cw), min(y + h, cy + ch)
            if right > left and bottom > top:
                last = (left, top, right, bottom)
    if last is None:
        return None
    hdc("shell", "uitest", "dumpLayout", "-p", "/data/local/tmp/lp.json")
    raw = hdc("shell", "cat", "/data/local/tmp/lp.json").stdout
    mo = re.search(r'"type":"XComponent"[^}]*?"bounds":"\[([\d.]+),([\d.]+)\]\[([\d.]+),([\d.]+)\]"', raw)
    if not mo:
        mo = re.search(r'"bounds":"\[([\d.]+),([\d.]+)\]\[([\d.]+),([\d.]+)\]"[^}]*?"type":"XComponent"', raw)
    if not mo:
        return None
    ox, oy = float(mo.group(1)), float(mo.group(2))
    root_vp = 0.0
    for row in rows:
        mr = re.search(r"node-rect id=(-?\d+) x=(-?\d+) y=(-?\d+) w=(\d+) h=(\d+)", row)
        if mr and int(mr.group(2)) == 0 and int(mr.group(3)) == 0 and int(mr.group(4)) > 100:
            root_vp = float(mr.group(4))
            break
    xc_w_px = float(mo.group(3)) - ox
    density = (xc_w_px / root_vp) if root_vp > 0 and xc_w_px > 0 else 2.0
    return last, (ox, oy, density)


def shot(label):
    remote = f"/data/local/tmp/d-frame-{label}.jpeg"
    hdc("shell", f"snapshot_display -f {remote}", timeout=45)
    time.sleep(0.4)
    local = os.path.join(OUT, f"{label}.jpeg")
    hdc("file", "recv", remote, local, timeout=45)
    hdc("shell", f"rm -f {remote}")
    if not os.path.isfile(local):
        raise RuntimeError(f"missing screenshot {local}")
    return local


def crop_diff_ratio(path_a, path_b, box):
    from PIL import Image
    a = Image.open(path_a).convert("RGB").crop(box)
    b = Image.open(path_b).convert("RGB").crop(box)
    if a.size != b.size:
        return 1.0
    pa, pb = a.load(), b.load()
    w, h = a.size
    diff = sum(1 for y in range(h) for x in range(w) if pa[x, y] != pb[x, y])
    return diff / float(w * h)


def selection_lines(rows):
    return [r for r in rows if "selection applied" in r or "ime select" in r]


def main():
    os.makedirs(OUT, exist_ok=True)
    report = {}
    if not ensure_foreground():
        print(json.dumps({"fatal": "not foreground"}))
        return 2
    pid = device_pid()
    report["pid"] = pid
    port = 28866
    r = hdc("fport", "rm", f"tcp:{port}", "tcp:7856")
    r = hdc("fport", f"tcp:{port}", "tcp:7856")
    if "OK" not in r.stdout:
        print(json.dumps({"fatal": "forward_fail", "stdout": r.stdout.strip()}))
        return 2
    try:
        # 1. Markdown 夹具整体替换
        resp = agent_replace_all(port, FIXTURE.encode().hex())
        report["fixture_applied"] = "APPLIED true" in resp
        time.sleep(1.0)
        version, hexstr = read_all(port)
        body = bytes.fromhex(hexstr).decode("utf-8", "ignore")
        report["fixture_readback"] = body == FIXTURE
        report["owner_bytes"] = len(hexstr) // 2

        # 2. 源码模式截图
        shot_source = shot("01-source")
        report["source_shot"] = shot_source

        # 3. 切预览 → 截图 → 度量预览行数（预览为多节点 fragments）
        geo_btn = node_geometry(pid_rows(pid), "pharos-preview")
        if not geo_btn:
            report["fatal"] = "preview button not found"
            json.dump(report, open(os.path.join(OUT, "result.json"), "w"), ensure_ascii=False, indent=2)
            return 2
        rect, (ox, oy, density) = geo_btn
        bx = int(ox + (rect[0] + rect[2]) / 2 * density)
        by = int(oy + (rect[1] + rect[3]) / 2 * density)
        uitest("click", str(bx), str(by))
        time.sleep(1.2)
        shot_preview = shot("02-preview")
        report["preview_shot"] = shot_preview
        # 预览 accepted 节点语义（每片段一个 pharos-editor-block）= 预览真实提交
        rows_after = pid_rows(pid)
        report["preview_fragments_accepted"] = any(
            "semantic=pharos-editor-block " in r for r in rows_after)
        # 预览画面与源码画面必须可区分（标题/强调/代码底色导致行布局不同）
        report["preview_differs_source"] = crop_diff_ratio(
            shot_source, shot_preview,
            (0, int(oy + 40 * density), int(ox + 377 * density), int(oy + 300 * density))) > 0.02

        # 4. 切回源码 → 建立非空选区（longClick 选中词）
        uitest("click", str(bx), str(by))
        time.sleep(0.8)
        editor = node_geometry(pid_rows(pid), "pharos-editor-body")
        if not editor:
            report["fatal"] = "editor not found"
        else:
            erect, _ = editor
            # 落点：编辑器第二行（含 SELECT_WORD 的行）中部
            ex = int(ox + (erect[0] + 60) * density)
            ey = int(oy + (erect[1] + (erect[3] - erect[1]) * 0.22) * density)
            rows_before = pid_rows(pid)
            uitest("longClick", str(ex), str(ey))
            time.sleep(1.2)
            rows_sel = pid_rows(pid)
            report["selection_established"] = len(selection_lines(rows_sel)) > len(selection_lines(rows_before))
            shot_selected = shot("03-selected")
            report["selected_shot"] = shot_selected

            # 5. 带选区切预览 → 切回 → 选区恢复对比（同一裁剪区域）
            uitest("click", str(bx), str(by))
            time.sleep(1.0)
            shot_sel_preview = shot("04-selected-preview")
            report["selected_preview_shot"] = shot_sel_preview
            uitest("click", str(bx), str(by))
            time.sleep(1.0)
            shot_back = shot("05-back-with-selection")
            report["back_shot"] = shot_back
            # 选区恢复判据（2026-10-01 修正）：长按把手只在触摸时出现，程序化
            # 恢复只有同词高亮——不能要求 03/05 逐像素相等。以 01（无选区的
            # 源码态）为平面基准：正文区域内与 01 不同的像素 = 选区痕迹
            # （高亮/把手/光标）。05 的痕迹量 ≥ 03 的 40% 且 > 0.5% 视为
            # 非空选区保留；把手差异解释其余差量。
            def mark_pixels(path, ref_path, box):
                from PIL import Image
                a = Image.open(path).convert("RGB").crop(box)
                b = Image.open(ref_path).convert("RGB").crop(box)
                pa, pb = a.load(), b.load()
                w, h = a.size
                diff = sum(1 for y in range(h) for x in range(w) if pa[x, y] != pb[x, y])
                return diff / float(w * h)

            body_box = (int(ox + erect[0] * density), int(oy + erect[1] * density),
                        int(ox + erect[2] * density), int(oy + (erect[1] + (erect[3] - erect[1]) * 0.4) * density))
            m03 = mark_pixels(shot_selected, shot_source, body_box)
            m05 = mark_pixels(shot_back, shot_source, body_box)
            report["selection_mark_ratio_03"] = m03
            report["selection_mark_ratio_05"] = m05
            report["selection_restored"] = (m03 > 0.005 and m05 >= m03 * 0.4)
            # 预览态同区域：只读 fragments，不含选区高亮 → 应与选区态不同
            report["preview_no_selection_highlight"] = crop_diff_ratio(
                shot_selected, shot_sel_preview, body_box) > 0.02
    finally:
        hdc("fport", "rm", f"tcp:{port}", "tcp:7856")

    checks = {
        "fixture_applied": report.get("fixture_applied") is True,
        "fixture_readback": report.get("fixture_readback") is True,
        "preview_fragments_accepted": report.get("preview_fragments_accepted") is True,
        "preview_differs_source": report.get("preview_differs_source") is True,
        "selection_established": report.get("selection_established") is True,
        "selection_restored": report.get("selection_restored") is True,
        "preview_no_selection_highlight": report.get("preview_no_selection_highlight") is True,
    }
    report["checks"] = checks
    report["pass"] = all(checks.values())
    with open(os.path.join(OUT, "result.json"), "w") as f:
        json.dump(report, f, ensure_ascii=False, indent=2)
    print(json.dumps({"pass": report["pass"],
                      "failed": [k for k, v in checks.items() if not v]},
                     ensure_ascii=False))
    return 0 if report["pass"] else 1


if __name__ == "__main__":
    sys.exit(main())

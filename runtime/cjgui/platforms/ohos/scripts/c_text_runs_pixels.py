#!/usr/bin/env python3
"""C（h-source-preview-next）：textStyleRuns 的可区分像素/计数判别。

第二消费者（thermo）经 cjguiComposableText 的 textStyleRuns 声明消费混合
样式；本驱动在真实模拟器画面上按阶段取证：
  阶段 0 混合生效 → 1 修改 → 2 倒置(拒绝保旧) → 3 重叠(拒绝保旧)
  → 4 超 64(拒绝保旧) → 5 清除(空 runs)。
判据（与 hilog 计数互证）：
  - p1 与 p0 的节点裁剪区域像素不同（run 修改真实可见）；
  - p2/p3 与 p1 逐像素一致（倒置/重叠整批拒绝、保旧）；
  - p4 与 p1 一致（65-run 批次按数量上限拒绝、保旧；节点 11 重声明合法批）；
  - p5 与此前所有阶段都不同（清除生效）；
  - 每阶段窗口内 hilog：applied/cleared/refused 计数与预期一一对应。
"""

import json
import os
import re
import subprocess
import sys
import time

HDC = "/Applications/DevEco-Studio.app/Contents/sdk/default/openharmony/toolchains/hdc"
TARGET = "127.0.0.1:5555"
BUNDLE = "com.example.cjguithermo"
OUT = ("/Users/jiangxuanyang/Desktop/cangjie/artifacts/h-source-preview-20260930/"
       "c-runs-pixels")

PHASE_LABELS = {
    0: "p0-mixed", 1: "p1-modified", 2: "p2-inverted-refused",
    3: "p3-overlap-refused", 4: "p4-over64-refused", 5: "p5-cleared",
}


def hdc(*args, timeout=30):
    r = subprocess.run([HDC, "-t", TARGET] + list(args), capture_output=True,
                       text=True, errors="replace", timeout=timeout)
    return r


def uitest(*args, timeout=30):
    return hdc("shell", "uitest", "uiInput", *args, timeout=timeout)


def hilog_rows():
    r = hdc("shell", "hilog -x", timeout=20)
    return (r.stdout or "").splitlines()


def device_pid():
    out = hdc("shell", f"pidof {BUNDLE}").stdout.strip()
    return out.split()[0] if out else ""


def ensure_foreground():
    pid = device_pid()
    if not pid:
        hdc("shell", f"aa start -a EntryAbility -b {BUNDLE}")
        time.sleep(4)
        pid = device_pid()
    hdc("shell", "uitest", "dumpLayout", "-p", "/data/local/tmp/fg.json")
    raw = hdc("shell", "cat", "/data/local/tmp/fg.json").stdout
    m = re.search(r'"bundleName":"([^"]+)"', raw)
    fg = (m.group(1) if m else "") == BUNDLE
    return fg, pid


def pid_rows(pid):
    rows = hilog_rows()
    return [r for r in rows if f" {pid} " in r] or rows


RECT_PAT = re.compile(r"node-rect id=(-?\d+) x=(-?\d+) y=(-?\d+) w=(\d+) h=(\d+) "
                      r"clip=\((-?\d+),(-?\d+),(-?\d+),(-?\d+)\)")


def node_id_of(rows, semantic):
    nid = None
    for row in rows:
        if "accepted node=" in row and f"semantic={semantic} " in row:
            m = re.search(r"accepted node=(-?\d+)", row)
            if m:
                nid = m.group(1)
    return nid


def node_rect_vp(rows, nid):
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
    return last


def surface_facts(rows):
    """XComponent 原点(px) 与密度(px/vp)：密度=XC宽px ÷ 根节点宽vp。"""
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
    return ox, oy, density


def crop_px(facts, rect_vp, margin_px=2):
    ox, oy, density = facts
    left, top, right, bottom = rect_vp
    return (int(ox + left * density) - margin_px, int(oy + top * density) - margin_px,
            int(ox + right * density) + margin_px, int(oy + bottom * density) + margin_px)


def screenshot(label):
    remote = f"/data/local/tmp/c-runs-{label}.jpeg"
    hdc("shell", f"snapshot_display -f {remote}", timeout=45)
    time.sleep(0.4)
    local = os.path.join(OUT, f"{label}.jpeg")
    hdc("file", "recv", remote, local, timeout=45)
    if not os.path.isfile(local):
        raise RuntimeError(f"missing screenshot {local}")
    hdc("shell", f"rm -f {remote}")
    return local


def window_counts(rows):
    """本窗口内三类准入行的计数。"""
    return {
        "applied": sum(1 for r in rows if "text runs applied" in r),
        "cleared": sum(1 for r in rows if "text runs cleared node=" in r),
        "refused_invalid": sum(1 for r in rows if "text runs refused: invalid/overlapping/over-budget" in r),
        "refused_past_end": sum(1 for r in rows if "text runs refused: range past text" in r
                                or "text runs refused at stage" in r),
    }


def phase_rows_since(pid, marker_row, rows):
    """marker（THERMO_STYLE_PHASE）之后到当前的行（含 marker 之后发生的准入）。"""
    try:
        idx = rows.index(marker_row)
    except ValueError:
        idx = -1
    return [r for r in rows[idx + 1:] if f" {pid} " in r]


def find_phase_marker(rows, phase):
    for row in rows:
        if f"THERMO_STYLE_PHASE phase={phase}" in row:
            return row
    return None


def crop_image(path, box):
    from PIL import Image
    img = Image.open(path).convert("RGB")
    return img.crop(box)


def diff_pixels(a, b):
    """不同像素比例（0=完全一致）。"""
    if a.size != b.size:
        return 1.0
    pa, pb = a.load(), b.load()
    w, h = a.size
    diff = 0
    for y in range(h):
        for x in range(w):
            if pa[x, y] != pb[x, y]:
                diff += 1
    return diff / float(w * h)


def main():
    os.makedirs(OUT, exist_ok=True)
    fg, pid = ensure_foreground()
    if not fg:
        print(json.dumps({"fatal": "not foreground", "bundle": BUNDLE}, ensure_ascii=False))
        return 2
    print(f"foreground ok pid={pid}")

    # 不清 hilog：节点几何需要启动以来的 accepted/node-rect 行；阶段 0 的计数
    # 窗口 = 本次启动以来（marker 不存在时回退全量，启动期无拒绝行）。
    rows = pid_rows(pid)
    facts = surface_facts(rows)
    if not facts:
        print(json.dumps({"fatal": "no surface facts"}))
        return 2
    print(f"surface ox={facts[0]} oy={facts[1]} density={facts[2]:.3f}")

    sems = {"mixed": "thermo-mixed", "stress": "thermo-runs-stress", "button": "thermo-style-phase"}
    nids = {}
    rects = {}
    for key, sem in sems.items():
        nid = node_id_of(rows, sem)
        if nid is None:
            print(json.dumps({"fatal": f"node not accepted: {sem}"}))
            return 2
        rect = node_rect_vp(rows, nid)
        if rect is None:
            print(json.dumps({"fatal": f"node rect missing: {sem}"}))
            return 2
        nids[key], rects[key] = nid, rect
        print(f"{sem}: node={nid} rect_vp={rect}")

    btn_px = crop_px(facts, rects["button"])
    btn_click = ((btn_px[0] + btn_px[2]) // 2, (btn_px[1] + btn_px[3]) // 2)
    boxes = {k: crop_px(facts, rects[k]) for k in ("mixed", "stress")}

    crops = {}
    shots = {}
    counts = {}
    report = {"pid": pid, "density": facts[2], "button_click_px": btn_click,
              "rects_vp": rects, "crop_boxes_px": boxes, "phases": {}}

    def capture(phase):
        rows_now = pid_rows(pid)
        marker = find_phase_marker(rows_now, phase)
        win = phase_rows_since(pid, marker, rows_now) if marker else rows_now
        counts[phase] = window_counts(win)
        shots[phase] = screenshot(PHASE_LABELS[phase])
        crops[phase] = {k: crop_image(shots[phase], boxes[k]) for k in ("mixed", "stress")}
        report["phases"][phase] = {"label": PHASE_LABELS[phase], "counts": counts[phase],
                                   "marker_found": marker is not None}
        print(f"phase {phase}: {PHASE_LABELS[phase]} counts={counts[phase]}")

    capture(0)
    for phase in (1, 2, 3, 4, 5):
        uitest("click", str(btn_click[0]), str(btn_click[1]))
        deadline = time.time() + 8
        while time.time() < deadline:
            rows_now = pid_rows(pid)
            if find_phase_marker(rows_now, phase):
                break
            time.sleep(0.4)
        time.sleep(0.8)  # 等待场景提交与新帧落盘
        capture(phase)

    # 像素判据
    verdicts = {}
    for node in ("mixed", "stress"):
        d = {f"p{a}_vs_p{b}": diff_pixels(crops[a][node], crops[b][node])
             for a, b in ((0, 1), (1, 2), (1, 3), (1, 4), (1, 5), (0, 5))}
        verdicts[node] = d
    report["pixel_diff_ratio"] = verdicts

    checks = {
        "mixed_p1_differs_p0": verdicts["mixed"]["p0_vs_p1"] > 0.002,
        "mixed_p2_keeps_p1": verdicts["mixed"]["p1_vs_p2"] < 0.001,
        "mixed_p3_keeps_p1": verdicts["mixed"]["p1_vs_p3"] < 0.001,
        "mixed_p4_keeps_p1": verdicts["mixed"]["p1_vs_p4"] < 0.001,
        "mixed_p5_differs_p1": verdicts["mixed"]["p1_vs_p5"] > 0.002,
        "stress_p1_same_as_p0": verdicts["stress"]["p0_vs_p1"] < 0.001,  # 两阶段同为2段样式
        "stress_p2_keeps_p1": verdicts["stress"]["p1_vs_p2"] < 0.001,
        "stress_p3_keeps_p1": verdicts["stress"]["p1_vs_p3"] < 0.001,
        "stress_p4_keeps_p1_over64_refused": verdicts["stress"]["p1_vs_p4"] < 0.001,
        "stress_p5_differs_p1": verdicts["stress"]["p1_vs_p5"] > 0.002,
        "counts_p0_applied": counts[0]["applied"] >= 2 and counts[0]["refused_invalid"] == 0,
        "counts_p1_applied": counts[1]["applied"] >= 2 and counts[1]["refused_invalid"] == 0,
        "counts_p2_refused": counts[2]["refused_invalid"] >= 1,
        "counts_p3_refused": counts[3]["refused_invalid"] >= 1,
        "counts_p4_refused": counts[4]["refused_invalid"] >= 1,
        "counts_p5_cleared": counts[5]["cleared"] >= 2,
    }
    report["checks"] = checks
    report["pass"] = all(checks.values())
    with open(os.path.join(OUT, "verdict.json"), "w") as f:
        json.dump(report, f, ensure_ascii=False, indent=2)
    print(json.dumps({"pass": report["pass"], "failed": [k for k, v in checks.items() if not v]},
                     ensure_ascii=False))
    return 0 if report["pass"] else 1


if __name__ == "__main__":
    sys.exit(main())

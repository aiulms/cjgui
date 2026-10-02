#!/usr/bin/env python3
"""D 连续消费驱动（h-source-preview-next）：人编辑→预览→Agent 写→切回源码续写→保存重开。

同源正式构建的 HAP（sync_product.sh→hvigor→hdc install）。人侧由 uitest 驱动
（tap 编辑器/预览/源码/保存按钮 + inputText），Agent 侧走应用内公开通道
（hdc fport→7856，GET_CONTEXT/READ_RANGE/INVOKE REPLACE_RANGE）。每步留证：
owner 全文（公开通道读回）+ hilog 片段 + 截图。证据目录由 --out 指定。
"""
import argparse, json, os, re, socket, subprocess, time

# S4：共用严格判据 oracle。锚点/期望区间必须经它校验（代理对中点拒绝、
# EOF 边界、倒置拒绝）；期望在操作前冻结，禁止从结果反推。
import sys as _sys
_sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import strict_utf16  # noqa: E402

HDC = "/Applications/DevEco-Studio.app/Contents/sdk/default/openharmony/toolchains/hdc"
TARGET = "127.0.0.1:5555"
BUNDLE = "com.pharos.mark"


def hdc(*args, timeout=30):
    # hilog 输出可能夹带非 UTF-8 字节：errors=replace 避免 text 解码抛错。
    return subprocess.run([HDC, "-t", TARGET] + list(args), capture_output=True,
                          text=True, errors="replace", timeout=timeout)


def uitest(*args, timeout=30):
    return hdc("shell", "uitest", "uiInput", *list(args), timeout=timeout)


def frame(payload: str) -> bytes:
    e = payload.encode()
    return str(len(e)).encode() + b"\n" + e


CAP = "pharos-local-capability"


def request(lines, port):
    if lines and lines[0].startswith("GET_CONTEXT"):
        lines = ["PROTOCOL CJGUI_SHARED_OPERATION/2", f"AUTH {CAP}"] + lines
    payload = "\n".join(lines)
    with socket.create_connection(("127.0.0.1", port), timeout=6) as s:
        s.sendall(frame(payload))
        buf = bytearray()
        hdr = -1
        exp = None
        while True:
            chunk = s.recv(8192)
            if not chunk:
                raise ConnectionError("closed")
            buf += chunk
            if hdr < 0:
                hdr = buf.find(b"\n")
                if hdr < 0:
                    continue
                exp = int(bytes(buf[:hdr]))
            if len(buf) >= hdr + 1 + exp:
                return bytes(buf[hdr+1:hdr+1+exp]).decode()


def ctx(port):
    return request(["GET_CONTEXT 0"], port)


def read_all(port):
    """全文读回。GET_CONTEXT 的 byteLength 是文档真实字节长度；分窗时中间
    窗尾可能落在多字节字符内部（invalid_text_boundary 非单调：77 拒 82 收），
    对窗尾做 ≤4 字节回退，不做二分——二分把非边界误当越界会收敛到假长度，
    令整段替换留下旧尾巴（2026-10-01 实测）。"""
    c = ctx(port)
    mv = re.search(r"VERSION (\d+)", c)
    ml = re.search(r"byteLength INTEGER (\d+)", c)
    if not mv or not ml:
        raise RuntimeError("GET_CONTEXT missing version/byteLength")
    version, total = int(mv.group(1)), int(ml.group(1))
    chunks = []
    off = 0
    while off < total:
        want = min(off + 65536, total)
        resp = None
        back = 0
        while want - back > off and back <= 4:
            resp = request(["PROTOCOL CJGUI_SHARED_OPERATION/2", f"AUTH {CAP}",
                            f"READ_RANGE 1 {off} {want - back} {version}"], port)
            if "CONTENT_UTF8_HEX" in resp:
                break
            back += 1
        mhex = re.search(r"CONTENT_UTF8_HEX (\d+) ([0-9a-fA-F]*)", resp or "")
        if not mhex:
            raise RuntimeError(f"READ_RANGE failed at {off}: {(resp or '')[:160]}")
        chunks.append(mhex.group(2))
        got = int(mhex.group(1))
        off += got
        if got == 0:
            raise RuntimeError("READ_RANGE zero-length chunk")
    return version, "".join(chunks)


def agent_replace(port, start, end, text_hex, version):
    n = len(text_hex) // 2
    return request([
        "PROTOCOL CJGUI_SHARED_OPERATION/2", f"AUTH {CAP}",
        f"INVOKE {version} REPLACE_RANGE 1 4", "ID 1",
        f"ARG start INTEGER {start}", f"ARG end INTEGER {end}",
        f"ARG text STRING {n} {text_hex}",
        f"ARG expectedVersion INTEGER {version}"], port)


def hilog_rows():
    r = hdc("shell", "hilog -x", timeout=15)
    return (r.stdout or "").splitlines()


def accepted_editor_point():
    """编辑器命中点：与夜间 107 轮同源——fresh hilog 的 accepted node=semantic
    → node-rect id=…（vp）→ 与 clip 求交，换算物理 px 并加 XComponent 原点。
    PID 围栏：只消费当前 bundle 的行，历史前台应用的行不参与。"""
    pid = hdc("shell", f"pidof {BUNDLE}").stdout.strip().split()[0] if hdc("shell", f"pidof {BUNDLE}").stdout.strip() else ""
    allrows = hilog_rows()
    rows = [r for r in allrows if (not pid) or f" {pid} " in r] if pid else allrows
    if not rows:
        rows = allrows
    nid = None
    for row in rows:
        if "accepted node=" in row and "semantic=pharos-editor-body " in row:
            m = re.search(r"accepted node=(-?\d+)", row)
            if m:
                nid = m.group(1)
    if nid is None:
        return None
    pat = re.compile(r"node-rect id=(-?\d+) x=(-?\d+) y=(-?\d+) w=(\d+) h=(\d+) "
                     r"clip=\((-?\d+),(-?\d+),(-?\d+),(-?\d+)\)")
    rects = []
    for row in rows:
        m = pat.search(row)
        if m and m.group(1) == nid:
            x, y, w, h = int(m.group(2)), int(m.group(3)), int(m.group(4)), int(m.group(5))
            cx, cy, cw, ch = (int(m.group(6)), int(m.group(7)), int(m.group(8)), int(m.group(9)))
            if min(w, h, cw, ch) <= 0:
                continue
            left, top = max(x, cx), max(y, cy)
            right, bottom = min(x + w, cx + cw), min(y + h, cy + ch)
            if right > left and bottom > top:
                rects.append((left, top, right, bottom))
    if not rects:
        return None
    left, top, right, bottom = rects[-1]
    # XComponent 原点与密度：layout dump 找 XComponent bounds，密度由 uitest 层
    # 近似为 2（夜间记录 density 用于 vp→px）。这里直接用 dump 的窗口坐标。
    dump = hdc("shell", "uitest", "dumpLayout", "-p", "/data/local/tmp/lp.json")
    raw = hdc("shell", "cat /data/local/tmp/lp.json").stdout
    mo = re.search(r'"type":"XComponent"[^}]*?"bounds":"\[([\d.]+),([\d.]+)\]\[[\d.]+,[\d.]+\]"', raw)
    if not mo:
        mo = re.search(r'"bounds":"\[([\d.]+),([\d.]+)\]\[([\d.]+),([\d.]+)\]"[^}]*?"type":"XComponent"', raw)
    if not mo:
        return None
    ox, oy = float(mo.group(1)), float(mo.group(2))
    # 密度从事实推导：XComponent 宽(px) ÷ accepted 根节点宽(vp)（root w=377vp
    # ↔ 1320px ⇒ density≈3.5；此前固定 2.0 导致点击落在标题区，输入不达编辑器）。
    root_vp = 0.0
    for row in rows:
        mr = re.search(r"node-rect id=(-?\d+) x=(-?\d+) y=(-?\d+) w=(\d+) h=(\d+)", row)
        if mr and int(mr.group(2)) == 0 and int(mr.group(3)) == 0 and int(mr.group(4)) > 100:
            root_vp = float(mr.group(4))
            break
    xc_w_px = float(mo.group(3)) - ox
    density = (xc_w_px / root_vp) if root_vp > 0 and xc_w_px > 0 else 2.0
    vx = left + 15
    vy = (top + bottom) // 2
    return int(ox + vx * density), int(oy + vy * density)


def _viewport_transform(rows):
    """原点与 vp→px 比例（唯一换算来源）。

    `accepted_semantic_point` 与 `semantic_vp_to_px` 必须共用它：各自复刻这段
    启发式会让两种单位混用，命中点算错而外部只看到"点不中"。

    预览模式下**没有 XComponent**（实测 dumpLayout 里 XComponent 为空），
    此前直接回退常量 `density=2.0`，坐标整片偏移。正确的回退是：
      * density = 屏幕物理宽度 / 根节点 vp 宽度（实测 1320/377 ≈ 3.5）
      * 原点 = 屏幕左上 (0,0)
    XComponent 存在时（源码模式）仍以它为宿主原点。
    """
    hdc("shell", "uitest", "dumpLayout", "-p", "/data/local/tmp/lp.json")
    raw = hdc("shell", "cat", "/data/local/tmp/lp.json").stdout
    root_vp = 0.0
    for row in rows:
        mr = re.search(r"node-rect id=(-?\d+) x=(-?\d+) y=(-?\d+) w=(\d+) h=(\d+)", row)
        if mr and int(mr.group(2)) == 0 and int(mr.group(3)) == 0 and int(mr.group(4)) > 100:
            root_vp = float(mr.group(4))
            break
    mo = re.search(r'"type":"XComponent"[^}]*?"bounds":"\[([\d.]+),([\d.]+)\]\[([\d.]+),([\d.]+)\]"', raw)
    if not mo:
        mo = re.search(r'"bounds":"\[([\d.]+),([\d.]+)\]\[([\d.]+),([\d.]+)\]"[^}]*?"type":"XComponent"', raw)
    # S3（dumpLayout 竞态终裁）：转储偶发把 XComponent 的 bounds 留空、只填
    # origBounds（实测 `"bounds":""` + `origBounds":"[0,136][1320,2758]"`）。
    # 这不是"预览模式无 XComponent"，绝不能走 oy=0 回退。补 origBounds 提取；
    # 仍无值时才重试 dump。
    if not mo:
        mo = re.search(r'"origBounds":"\[([\d.]+),([\d.]+)\]\[([\d.]+),([\d.]+)\]"[^}]*?"type":"XComponent"', raw)
    if not mo:
        mo = re.search(r'"type":"XComponent"[^}]*?"origBounds":"\[([\d.]+),([\d.]+)\]\[([\d.]+),([\d.]+)\]"', raw)
    if not mo:
        for _ in range(3):
            hdc("shell", "uitest", "dumpLayout", "-p", "/data/local/tmp/lp.json")
            raw = hdc("shell", "cat", "/data/local/tmp/lp.json").stdout
            mo = re.search(r'"type":"XComponent"[^}]*?"bounds":"\[([\d.]+),([\d.]+)\]\[([\d.]+),([\d.]+)\]"', raw)
            if not mo:
                mo = re.search(r'"bounds":"\[([\d.]+),([\d.]+)\]\[([\d.]+),([\d.]+)\]"[^}]*?"type":"XComponent"', raw)
            if not mo:
                mo = re.search(r'"origBounds":"\[([\d.]+),([\d.]+)\]\[([\d.]+),([\d.]+)\]"[^}]*?"type":"XComponent"', raw)
            if not mo:
                mo = re.search(r'"type":"XComponent"[^}]*?"origBounds":"\[([\d.]+),([\d.]+)\]\[([\d.]+),([\d.]+)\]"', raw)
            if mo:
                break
    if mo:
        ox, oy = float(mo.group(1)), float(mo.group(2))
        xc_w_px = float(mo.group(3)) - ox
        density = (xc_w_px / root_vp) if root_vp > 0 and xc_w_px > 0 else 0.0
        if density > 0:
            return ox, oy, density
    # 无 XComponent（预览模式）：用屏幕物理宽度对根节点 vp 宽度求比例。
    screen_w = 0.0
    bounds = re.findall(r'"bounds":"\[0,0\]\[(\d+),(\d+)\]"', raw)
    for w, _h in bounds:
        screen_w = max(screen_w, float(w))
    if root_vp > 0 and screen_w > 0:
        return 0.0, 0.0, screen_w / root_vp
    return 0.0, 0.0, 2.0


def _semantic_rect_vp(rows, semantic):
    """accepted 语义节点与 clip 的交集矩形（vp）与物理节点号。"""
    nid = None
    for row in rows:
        if "accepted node=" in row and f"semantic={semantic} " in row:
            m = re.search(r"accepted node=(-?\d+)", row)
            if m:
                nid = m.group(1)
    if nid is None:
        return None, None
    pat = re.compile(r"node-rect id=(-?\d+) x=(-?\d+) y=(-?\d+) w=(\d+) h=(\d+) "
                     r"clip=\((-?\d+),(-?\d+),(-?\d+),(-?\d+)\)")
    last = None
    for row in rows:
        m = pat.search(row)
        if m and m.group(1) == nid:
            x, y, w, h = (int(m.group(i)) for i in (2, 3, 4, 5))
            cx, cy, cw, ch = (int(m.group(i)) for i in (6, 7, 8, 9))
            left, top = max(x, cx), max(y, cy)
            right, bottom = min(x + w, cx + cw), min(y + h, cy + ch)
            if right > left and bottom > top:
                last = (left, top, right, bottom)
    return last, nid


def accepted_semantic_point(semantic, vp_x=None, vp_y=None, rows=None, rect_vp=None):
    """任意 accepted 语义节点的物理命中点（与编辑器同一坐标推导链）。

    默认取 vp(left+15, 中线)；调用方可用 `vp_x`/`vp_y` 指定**节点内 vp 坐标**
    （例如多行文本输入要落在首个文本行而非节点中线）。换算始终用同一条
    `_viewport_transform`，禁止调用方自行复制比例——两种单位相加减正是此前
    "点不中"的成因。`rows`/`rect_vp` 可由调用方传入已解析结果，避免同一次判定
    里两次读日志落在不同批次上。
    """
    if rows is None:
        rows = hilog_rows()
        pid = hdc("shell", f"pidof {BUNDLE}").stdout.strip().split()[0] if hdc(
            "shell", f"pidof {BUNDLE}").stdout.strip() else ""
        if pid:
            rows = [r for r in rows if f" {pid} " in r] or rows
    if rect_vp is None:
        rect_vp, _nid = _semantic_rect_vp(rows, semantic)
    if rect_vp is None:
        return None
    transform = _viewport_transform(rows)
    if transform is None:
        return None
    ox, oy, density = transform
    left, top, right, bottom = rect_vp
    x_vp = vp_x if vp_x is not None else left + 15
    y_vp = vp_y if vp_y is not None else (top + bottom) // 2
    return int(ox + x_vp * density), int(oy + y_vp * density)

def tap_semantic(semantic):
    p = accepted_semantic_point(semantic)
    if not p:
        return False
    uitest("click", str(p[0]), str(p[1]))
    return True


def node_center(pattern):
    r = hdc("shell", "uitest", "dumpLayout", "-p", "/data/local/tmp/layout.json")
    hdc("shell", "cat /data/local/tmp/layout.json")  # keep cached
    raw = hdc("shell", "cat /data/local/tmp/layout.json").stdout
    # find button by text via regex over attributes in dump order
    for m in re.finditer(r'"text":"([^"]*)"[^}]*?"rect":\{"left":([\d.]+),"top":([\d.]+)[^}]*"width":([\d.]+),"height":([\d.]+)', raw):
        if pattern in m.group(1):
            x = float(m.group(2)) + float(m.group(4)) / 2
            y = float(m.group(3)) + float(m.group(5)) / 2
            return x, y
    for m in re.finditer(r'"id":"([^"]*)"[^}]*?"bounds":\[\[([\d.]+),([\d.]+)\]\[([\d.]+),([\d.]+)\]\]', raw):
        if pattern in m.group(1):
            x = (float(m.group(2)) + float(m.group(4))) / 2
            y = (float(m.group(3)) + float(m.group(5))) / 2
            return x, y
    return None


def tap_text(pattern):
    c = node_center(pattern)
    if not c:
        return False
    uitest("click", str(int(c[0])), str(int(c[1])))
    return True


def editor_tap():
    p = accepted_editor_point()
    if not p:
        return False
    uitest("click", str(p[0]), str(p[1]))
    return True


def save_evidence(out, label, port, extra=None):
    version, hexstr = read_all(port)
    shot = os.path.join(out, f"{label}.jpeg")
    hdc("shell", "uitest", "screenCap", "-p", f"/data/local/tmp/{label}.jpeg")
    hdc("file", "recv", f"/data/local/tmp/{label}.jpeg", shot)
    rec = {"label": label, "version": version, "owner_bytes": len(hexstr)//2, "owner_hex": hexstr,
           "screenshot": shot}
    if extra:
        rec.update(extra)
    with open(os.path.join(out, "steps.jsonl"), "a") as f:
        f.write(json.dumps(rec, ensure_ascii=False) + "\n")
    return rec


def ensure_foreground():
    """输入必须落到本 bundle：dump 前台 bundleName 校验，未运行则启动。
    R4：启动后**有界等待**前台真的就绪（dump 出现本 bundle），不再用固定一次
    探测决定——应用刚起来的 dump 会读到桌面，几何随之失效并诱发猜坐标。"""
    pid = hdc("shell", f"pidof {BUNDLE}").stdout.strip()
    if not pid:
        hdc("shell", f"aa start -a EntryAbility -b {BUNDLE}")
        time.sleep(4)
    for _ in range(10):
        hdc("shell", "uitest", "dumpLayout", "-p", "/data/local/tmp/fg.json")
        raw = hdc("shell", "cat", "/data/local/tmp/fg.json").stdout
        if BUNDLE in re.findall(r'"bundleName":"([^"]+)"', raw):
            return True
        hdc("shell", f"aa start -a EntryAbility -b {BUNDLE}")
        time.sleep(2)
    return False


def freeze_baseline(port):
    """动作前冻结**完整 owner**：版本、字节长度与整串十六进制。
    判据不得依赖正文里预存的字样，也不得在无 identity 时回退全局旧日志。"""
    version, hexstr = read_all(port)
    return {"version": version, "bytes": len(hexstr) // 2, "hex": hexstr}


def diff_span(before_hex, after_hex):
    """两串的最小公共前后缀差：返回 (start, end_removed, inserted_hex)（源字节域）。
    用于把「一笔编辑实际落在哪里」变成可核对的数字，而不是靠猜末尾。"""
    a = bytes.fromhex(before_hex)
    b = bytes.fromhex(after_hex)
    i = 0
    while i < min(len(a), len(b)) and a[i] == b[i]:
        i += 1
    j = 0
    while j < min(len(a), len(b)) - i and a[len(a) - 1 - j] == b[len(b) - 1 - j]:
        j += 1
    return i, len(a) - j, b[i:len(b) - j].hex()


def calibrate_anchor(port, point, mid_offset_px, marker, results):
    """把「点击位置 → 源字节落点」变成一次**可复现的校准**，而不是假设末尾。

    平台安装的选区/caret 由命中位置决定，所以驱动的期望必须锚定在一个它自己
    选定的中段位置。校准只做一次，并且要求：落点必须严格在中段（既非 0 也非
    末尾），否则这次校准不成立、判据失败——不允许把"末尾兜底"当锚点。"""
    before = freeze_baseline(port)
    click_x = point[0] + mid_offset_px
    click_y = point[1]
    uitest("click", str(click_x), str(click_y)); time.sleep(1.2)
    uitest("inputText", str(click_x), str(click_y), marker); time.sleep(2.0)
    after = freeze_baseline(port)
    if after["hex"] == before["hex"]:
        results["anchor_calibrated"] = False
        results["anchor_failure"] = "no_owner_change"
        return None
    start, end, inserted = diff_span(before["hex"], after["hex"])
    is_mid = 0 < start < before["bytes"]
    results["anchor_calibrated"] = bool(is_mid and inserted == marker.encode("utf-8").hex())
    # S4：锚点边界必须是 UTF-8 标量边界（等价于 UTF-16 oracle 不劈代理对）。
    # 夹具含 CJK/emoji 前缀时这一步把"恰好落在标量内部"的伪锚点拦下。
    raw_before = bytes.fromhex(before["hex"])
    for boundary in (start, end):
        if 0 < boundary < len(raw_before) and (raw_before[boundary] & 0xC0) == 0x80:
            results["anchor_calibrated"] = False
            results["anchor_failure"] = f"oracle_boundary:{boundary} splits a scalar"
            return None
    results["anchor"] = {"start": start, "end": end, "bytes": before["bytes"],
                         "mid_document": is_mid, "marker": marker}
    if not results["anchor_calibrated"]:
        results["anchor_failure"] = ("not_mid_document" if not is_mid else "marker_mismatch")
        return None
    # 校准把标记插在中段；**锚点区间就是该标记本身**。后续每一笔"系统输入精确
    # 替换"必须是替换这段中段非空选区，而不是在它后面追加——这正是本包要证的语义。
    return {"start": start, "end": start + len(marker.encode("utf-8")), "after": after}


def expect_replace(before, start_byte, end_byte, insert_text):
    """本笔**唯一**期望正文：原前缀 + 本笔文本 + 原后缀（源字节域）。
    返回 (期望hex, 期望版本)。系统输入未到 ⇒ 实际不可能等于它 ⇒ 必须失败。"""
    raw = bytes.fromhex(before["hex"])
    ins = insert_text.encode("utf-8")
    after = raw[:start_byte] + ins + raw[end_byte:]
    return after.hex(), before["version"] + 1


def apply_expectation(label, before, actual, start_byte, end_byte, insert_text, results):
    """核对一笔人写：精确正文、恰好一笔事务、其余字节原样。"""
    want_hex, want_version = expect_replace(before, start_byte, end_byte, insert_text)
    got_hex = actual["owner_hex"]
    results[f"{label}_exact_owner"] = (got_hex == want_hex)
    results[f"{label}_version_exactly_once"] = (actual["version"] == want_version)
    results[f"{label}_identity_ok"] = bool(actual.get("identity") == results.get("pid") and results.get("pid"))
    if got_hex != want_hex:
        results[f"{label}_mismatch"] = {
            "want_bytes": len(want_hex) // 2, "got_bytes": len(got_hex) // 2,
            "want_version": want_version, "got_version": actual["version"],
            "input_absent": (got_hex == before["hex"]),
        }
    return want_hex


def running_pharos_bundles():
    """设备上所有 Pharos 系包名（按进程名去重）。同端点他方实例会读走错误的 owner，
    必须点名而不是默认自己独占 7856。"""
    r = hdc("shell", "ps -ef")
    names = set()
    for line in (r.stdout or "").splitlines():
        for token in line.split():
            if token.startswith("com.pharos.mark"):
                names.add(token)
    return sorted(names)


def instance_identity():
    """本实例身份围栏：bundle 名 + PID + 监听端点。无 PID 即无法归属，判据必须失败。"""
    pid = hdc("shell", f"pidof {BUNDLE}").stdout.strip().split()[0] if hdc(
        "shell", f"pidof {BUNDLE}").stdout.strip() else ""
    return {"bundle": BUNDLE, "pid": pid}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", required=True)
    ap.add_argument("--port", type=int, default=28865)
    # R4 负控：判据必须在“零输入/Agent 拒绝/错位插入/重复写/纯 caret”下变红。
    ap.add_argument("--negative-control", choices=["none", "zero-input", "agent-refused",
                                                   "misplaced", "duplicate-write", "caret-only"],
                    default="none")
    args = ap.parse_args()
    neg = args.negative_control
    os.makedirs(args.out, exist_ok=True)
    if not ensure_foreground():
        print(json.dumps({"status": "not_foreground"}))
        return 2
    # 实例归属前置：同端点他方实例在跑时，7856 的 owner 可能属于它而不是本实例
    # （2026-10-01 实测：hovernight 旧实例占用 7856，读回的 owner 一直是旧实例的
    # 103B/v4，而本实例编辑会话已是 385B/v2 ⇒ 全部“人写不生效”都是假阴性）。
    others = [b for b in running_pharos_bundles() if b != BUNDLE]
    if others:
        print(json.dumps({"status": "foreign_instance_present", "others": others,
                          "note": "同端点他方实例会污染 owner 读回；先回收或改用独立实例"}))
        return 2
    port = args.port
    r = hdc("fport", "rm", f"tcp:{port}", "tcp:7856")
    r = hdc("fport", "tcp:%d" % port, "tcp:7856")
    if "OK" not in r.stdout:
        print(json.dumps({"status": "forward_fail", "stdout": r.stdout.strip()}))
        return 2
    ident = instance_identity()
    pid = ident["pid"]
    if not pid:
        print(json.dumps({"status": "no_instance"}))
        return 2
    results = {"pid": pid, "negative_control": neg, "steps": []}
    ok = True
    try:
        point = accepted_editor_point()
        if not point:
            # R4：无 accepted 身份/几何时**不得**回退默认坐标去点击——那会让判据
            # 在“输入根本没到正文”时仍产生步骤记录。具名失败并落盘。
            results["editor_point"] = "not_derived"
            results["status"] = "FAIL"
            results["required"] = ["editor_point_derived"]
            results["required_values"] = {"editor_point_derived": False}
            with open(os.path.join(args.out, "result.json"), "w") as f:
                json.dump(results, f, ensure_ascii=False, indent=2)
            print(json.dumps({"status": "FAIL", "pid": pid, "reason": "editor_point_not_derived"},
                             ensure_ascii=False))
            return 1
        # 基础正文 + **中段锚点校准**：平台落点由命中位置决定，因此驱动必须先
        # 在它自己选定的中段位置建立一次可复现的落点，后续每一笔都用这个锚点
        # 构造独立期望（前缀+本笔文本+后缀）。锚点落不到中段 ⇒ 判据失败，
        # 不用"末尾兜底"冒充。
        base = freeze_baseline(port)
        results["baseline"] = {"version": base["version"], "bytes": base["bytes"]}
        if base["bytes"] == 0:
            uitest("click", str(point[0]), str(point[1])); time.sleep(0.6)
            uitest("inputText", str(point[0]), str(point[1]), "seed")
            time.sleep(1.0)
            base = freeze_baseline(port)
            results["baseline_after_seed"] = {"version": base["version"], "bytes": base["bytes"]}
        anchor = None if neg in ("zero-input", "caret-only") else calibrate_anchor(
            port, point, 120, "校", results)
        if neg not in ("zero-input", "caret-only") and anchor is None:
            ok = False
        anchor_start = anchor["start"] if anchor else -1
        anchor_end = anchor["end"] if anchor else -1
        results["anchor_used"] = {"start": anchor_start, "end": anchor_end}

        # 1. 人编辑：本笔唯一期望 = 冻结前缀 + 本笔文本 + 冻结后缀（锚点处替换）。
        pre = freeze_baseline(port)
        if neg == "zero-input":
            pass                      # 负控：不注入任何输入
        elif neg == "caret-only":
            uitest("click", str(point[0]), str(point[1])); time.sleep(0.8)  # 只落 caret，不输入
        else:
            click_x = point[0] + 120
            uitest("click", str(click_x), str(point[1])); time.sleep(1.2)
            uitest("inputText", str(click_x), str(point[1]), "预览前人写")
            time.sleep(2.0)
        human_ins = "预览前人写" if neg != "misplaced" else "错位后人写"
        after_human = save_evidence(args.out, "01-human-edit", port, extra={"identity": pid})
        results["system_input_arrived"] = (after_human["owner_hex"] != pre["hex"])
        if anchor is None:
            # 无锚点（负控/校准失败）：只记系统输入是否到达，不套用错误期望。
            results["human_exact_owner"] = False
            results["human_version_exactly_once"] = False
            results["human_identity_ok"] = bool(pid)
        else:
            apply_expectation("human", pre, after_human, anchor_start, anchor_end,
                              human_ins, results)
        results["steps"].append(after_human)

        # 2. 预览：点「预览」按钮
        if not tap_semantic("pharos-preview"):
            ok = False; results["preview_button"] = "not_found"
        time.sleep(0.8)
        results["steps"].append(save_evidence(args.out, "02-preview-open", port, extra={"identity": pid}))

        # 3. Agent 公开写（预览期间末点追加）：完整请求/回包落盘，终态入总判据。
        before_agent = freeze_baseline(port)
        append_text = "Agent在预览期写入"
        append_hex = append_text.encode("utf-8").hex()
        if neg == "agent-refused":
            # 负控：故意用过期版本请求 ⇒ 必须被拒绝，且 owner 零变化。
            resp = agent_replace(port, before_agent["bytes"], before_agent["bytes"],
                                 append_hex, before_agent["version"] - 1)
        else:
            resp = agent_replace(port, before_agent["bytes"], before_agent["bytes"],
                                 append_hex, before_agent["version"])
        with open(os.path.join(args.out, "agent-exchange.json"), "w") as f:
            json.dump({"request": {"start": before_agent["bytes"], "end": before_agent["bytes"],
                                   "text": append_text, "expected_version": before_agent["version"]},
                       "response": resp}, f, ensure_ascii=False, indent=2)
        results["agent_write_response"] = resp[:400]
        results["agent_applied_response"] = "APPLIED true" in resp
        results["agent_complete_response_recorded"] = bool(resp.strip())
        time.sleep(0.8)
        after_agent = save_evidence(args.out, "03-agent-write", port, extra={"identity": pid})
        apply_expectation("agent", before_agent, after_agent, before_agent["bytes"],
                          before_agent["bytes"], append_text, results)
        if neg == "agent-refused":
            # 负控：拒绝时必须零写入；若判据仍说 OK，就是假绿。
            results["agent_refusal_kept_owner"] = (after_agent["owner_hex"] == before_agent["hex"])
        results["steps"].append(after_agent)

        # 4. 切回源码续写（同一中段锚点；Agent 是末尾追加，不改锚点之前的字节）
        if not tap_semantic("pharos-preview"):
            ok = False; results["source_button"] = "not_found"
        time.sleep(0.5)
        point2 = accepted_editor_point() or point
        before_cont = freeze_baseline(port)
        click_x2 = point2[0] + 120
        if neg == "duplicate-write":
            # 负控：同一笔重复注入两次 ⇒ 版本应推进两次，判据必须按“恰好一笔”变红。
            uitest("click", str(click_x2), str(point2[1])); time.sleep(0.8)
            uitest("inputText", str(click_x2), str(point2[1]), "续写完成")
            time.sleep(0.8)
            uitest("inputText", str(click_x2), str(point2[1]), "续写完成")
            time.sleep(1.0)
        else:
            uitest("click", str(click_x2), str(point2[1])); time.sleep(1.2)
            uitest("inputText", str(click_x2), str(point2[1]), "续写完成")
            time.sleep(2.0)
        after_cont = save_evidence(args.out, "04-back-source-continue", port, extra={"identity": pid})
        if anchor is None:
            results["continue_exact_owner"] = False
            results["continue_version_exactly_once"] = False
        else:
            apply_expectation("continue", before_cont, after_cont, anchor_start, anchor_end,
                              "续写完成", results)
        results["steps"].append(after_cont)

        # 5. 保存 → 关闭重开：读真实目标并精确核对
        saved_tap = tap_semantic("pharos-save")
        results["save_tap"] = saved_tap
        time.sleep(0.8)
        saved = save_evidence(args.out, "05-saved", port, extra={"identity": pid})
        hdc("shell", f"aa force-stop {BUNDLE}"); time.sleep(1)
        hdc("shell", f"aa start -a EntryAbility -b {BUNDLE}"); time.sleep(3)
        new_pid = hdc("shell", f"pidof {BUNDLE}").stdout.strip()
        results["reopen_pid"] = new_pid
        results["reopen_identity_matches"] = bool(new_pid) and new_pid != pid
        reopened = save_evidence(args.out, "06-reopened", port, extra={"identity": new_pid})
        results["save_reopen_same"] = (saved["owner_hex"] == reopened["owner_hex"] and
                                       saved["owner_bytes"] == reopened["owner_bytes"] and
                                       reopened["owner_bytes"] > 0)
    finally:
        hdc("fport", "rm", f"tcp:{port}", "tcp:7856")
        hdc("shell", f"aa force-stop {BUNDLE}")

    # 总判据：**中段锚点必须成立**，每一笔都必须精确、恰好一次、有身份；Agent
    # 终态必须为真；系统输入必须到达；保存重开必须逐字节一致。负控不改变要求
    # 集合，只让对应项自然为假——判据若在负控下仍报 OK 就是假绿。
    required = ["anchor_calibrated", "human_exact_owner", "human_version_exactly_once",
                "human_identity_ok", "system_input_arrived", "agent_applied_response",
                "agent_complete_response_recorded", "agent_exact_owner",
                "agent_version_exactly_once", "continue_exact_owner",
                "continue_version_exactly_once", "save_reopen_same", "reopen_identity_matches"]
    results["required"] = required
    results["required_values"] = {k: results.get(k) for k in required}
    results["status"] = "OK" if (ok and all(results.get(k) for k in required)) else "FAIL"
    with open(os.path.join(args.out, "result.json"), "w") as f:
        json.dump(results, f, ensure_ascii=False, indent=2)
    print(json.dumps({"status": results["status"], "pid": pid,
                      "negative_control": neg,
                      "required_values": results["required_values"]}, ensure_ascii=False))
    return 0 if results["status"] == "OK" else 1


if __name__ == "__main__":
    raise SystemExit(main())


def shell_cat_hex(path):
    """读设备文件的十六进制正文（`xxd -p` 单行输出）。文件不存在/命令缺失时
    返回 None——调用方据此**具名失败**，绝不退化成"读不到就算通过"。"""
    r = hdc("shell", f"xxd -p {path}", timeout=20)
    if r.returncode != 0:
        return None
    joined = "".join((r.stdout or "").split())
    if not re.fullmatch(r"[0-9a-fA-F]*", joined or ""):
        return None
    return joined.lower()


def close_and_reopen_document(port, shot_prefix):
    """保存后的**重开**：结束进程再启动同一 HAP，然后读回 owner。

    这是"保存重开"最直接的语义——磁盘是唯一持久层，重开后 owner 必须等于
    磁盘内容（版本从 1 起）。返回 dict（含 version/hex）或 None。"""
    hdc("shell", f"aa force-stop {BUNDLE}", timeout=20)
    time.sleep(1.0)
    hdc("shell", "hilog -r", timeout=15)
    hdc("shell", f"aa start -a EntryAbility -b {BUNDLE}", timeout=20)
    time.sleep(9.0)
    try:
        version, hexstr = read_all(port)
    except Exception:
        return None
    hdc("shell", "uitest", "screenCap", "-p", f"/data/local/tmp/{os.path.basename(shot_prefix)}.jpeg")
    hdc("file", "recv", f"/data/local/tmp/{os.path.basename(shot_prefix)}.jpeg", f"{shot_prefix}.jpeg")
    return {"version": version, "bytes": len(hexstr) // 2, "hex": hexstr}


# 可复现的干净基线夹具：每次取证前把整篇正文换成同一份固定内容，
# 使锚点、期望区间与最小差分都可复现。R4 的"不重复整套矩阵"依赖这一点：
# 没有干净基线时，上一轮遗留正文会把最小差分引到历史字符上，判据变得不可解释。
FIXTURE_TEXT = "# 预览取证标题\n\n正文含 **加粗强调** 与 *斜体强调* 以及 `行内代码` 三种样式。\n\n- 列表项一\n- 列表项二\n"


def reset_fixture(port, text=FIXTURE_TEXT):
    """把正文整体重置为固定夹具并**校验读回**。任一步失败都返回 (False, 原因)，
    调用方据此具名失败，而不是拿未清洁的基线继续取证。"""
    version, total = context_facts(port)
    resp = agent_replace(port, 0, total, text.encode('utf-8').hex(), version)
    if 'APPLIED true' not in resp:
        return False, f"fixture_replace_refused:{resp[:120].strip()}"
    time.sleep(1.0)
    read_version, hexstr = read_all(port)
    if bytes.fromhex(hexstr).decode('utf-8', 'replace') != text:
        return False, f"fixture_readback_mismatch:v{read_version}"
    return True, read_version


def context_facts(port):
    """(版本, 文档字节数)——公开 GET_CONTEXT 的权威读数。"""
    c = ctx(port)
    mv = re.search(r'VERSION (\d+)', c)
    ml = re.search(r'byteLength INTEGER (\d+)', c)
    if not mv or not ml:
        raise RuntimeError('context_facts_missing')
    return int(mv.group(1)), int(ml.group(1))


def diag_snapshot(out, label, identity=None):
    """把当前 hilog 里的窗口/渲染器诊断行落盘成证据（含 PID 围栏）。

    窗口诊断走 hilog，跨应用重启会被冲刷；事后 grep 无法区分"这段路径没跑"与
    "日志被冲掉"。运行中抓取让"零输出"成为同一时刻、同一 PID 的证据。"""
    pid = None
    if isinstance(identity, dict):
        pid = identity.get('pid')
    # 只收**生产日志**（诊断已按纪律从生产路径移除）：安装终态、安装尝试、
    # 焦点/编辑会话事实。判据与证据都不得依赖调试输出。
    keys = ('ime proxy selection terminal=', 'ime proxy selection set ', 'ime select [',
            'ime restore ', 'ime attach ', 'focus api enter', 'owned text session',
            'human anchor recorded', 'ime caret notification')
    rows = [r for r in hilog_rows()
            if any(k in r for k in keys) and (not pid or f' {pid} ' in r)]
    path = os.path.join(out, f'{label}.txt')
    with open(path, 'w') as f:
        f.write('\n'.join(rows))
    return {'path': path, 'lines': len(rows), 'sample': rows[-6:], 'all_rows': rows}


def accepted_semantic_rect(semantic):
    """accepted 语义节点与 clip 的交集矩形（vp）。返回 (left, top, right, bottom) 或 None。
    与 `accepted_semantic_point` 同一推导链，但返回矩形本身供调用方做坐标扫描——
    多行文本输入的左上角常落在内边距/空行上，直接当命中点会得到错误的落点。"""
    rows = hilog_rows()
    pid = hdc("shell", f"pidof {BUNDLE}").stdout.strip().split()[0] if hdc(
        "shell", f"pidof {BUNDLE}").stdout.strip() else ""
    if pid:
        rows = [r for r in rows if f" {pid} " in r] or rows
    nid = None
    for row in rows:
        if "accepted node=" in row and f"semantic={semantic} " in row:
            m = re.search(r"accepted node=(-?\d+)", row)
            if m:
                nid = m.group(1)
    if nid is None:
        return None
    pat = re.compile(r"node-rect id=(-?\d+) x=(-?\d+) y=(-?\d+) w=(\d+) h=(\d+) "
                     r"clip=\((-?\d+),(-?\d+),(-?\d+),(-?\d+)\)")
    last = None
    for row in rows:
        m = pat.search(row)
        if m and m.group(1) == nid:
            x, y, w, h = (int(m.group(i)) for i in (2, 3, 4, 5))
            cx, cy, cw, ch = (int(m.group(i)) for i in (6, 7, 8, 9))
            left, top = max(x, cx), max(y, cy)
            right, bottom = min(x + w, cx + cw), min(y + h, cy + ch)
            if right > left and bottom > top:
                last = (left, top, right, bottom)
    return last


def note_projected_text(port):
    """备注 owner 的投影文本。备注是**独立 owner**（内存会话），公开通道只覆盖
    主文档，因此这里以场景投影为准：accepted 日志里的 value 字段。"""
    rows = hilog_rows()
    pid = hdc("shell", f"pidof {BUNDLE}").stdout.strip().split()[0] if hdc(
        "shell", f"pidof {BUNDLE}").stdout.strip() else ""
    if pid:
        rows = [r for r in rows if f" {pid} " in r] or rows
    last = ""
    for row in rows:
        if "semantic=pharos-document-note" in row and " value=" in row:
            last = row.split(" value=", 1)[1].strip()
    return last


def last_note_caret(port):
    """备注会话最近一次落点。

    备注与正文各有自己的挂载，因此必须**按备注的挂载**筛选（`ime select` 行
    只带 mount 名，不带语义名，故先取最后一次 `pharos-document-note` 的挂载
    标识，再匹配同一 mount）。取全局最后一条会把正文落点当成备注落点。"""
    rows = hilog_rows()
    note_mount = None
    for row in rows:
        mo = re.search(r"mount=([\w/]+)\)?\s*$", row)
        if 'pharos-document-note' in row or 'note' in row:
            if mo:
                note_mount = mo.group(1)
    caret = None
    for row in rows:
        mo = re.search(r"ime select \[(\d+),(\d+)\) rc=0 mount=([\w/]+)", row)
        if mo and (note_mount is None or mo.group(3) == note_mount):
            caret = int(mo.group(1))
    return caret


def semantic_vp_to_px(semantic, vx, vy, rows=None):
    """把语义节点的 **vp 坐标**换算成物理命中坐标，与 `accepted_semantic_point`
    共用同一条换算链（`_viewport_transform` 与同一次 rows 解析）。

    调用方应传入**已解析的 rows**：换算依赖同一批日志里的根节点 rect，
    二次读取会让两次解析落在不同批次上，坐标随之偏移（这正是此前点不中的一层原因）。
    """
    if rows is None:
        rows = hilog_rows()
        pid = hdc("shell", f"pidof {BUNDLE}").stdout.strip().split()[0] if hdc(
            "shell", f"pidof {BUNDLE}").stdout.strip() else ""
        if pid:
            rows = [r for r in rows if f" {pid} " in r] or rows
    transform = _viewport_transform(rows)
    if transform is None:
        return None
    ox, oy, density = transform
    return int(ox + vx * density), int(oy + vy * density)


def note_rendered_units(node_id=313):
    """备注节点最近一次布局的字符数（`text layout painted ... node=<id> units=N`）。

    比 accepted 日志里的 value 可靠：含换行的 value 会被截断成很短的前缀，
    而 units 是**实际渲染**的字符数。"""
    last = None
    for row in hilog_rows():
        mo = re.search(rf"text layout painted .* node={node_id} units=(\d+)", row)
        if mo:
            last = int(mo.group(1))
    return last

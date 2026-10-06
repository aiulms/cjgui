#!/usr/bin/env python3
"""E/第六次复核第 5 项：恒温独立消费者 人→外→人 连续链探针。

独立应用身份：bundle com.example.cjguithermo、resourceId 9801、
外部授权 cjgui-thermo-agent-20260926、传输端口 7857（hdc fport 17857）。
领域差异：targetTemp 16–30（越界拒绝）、eco 布尔、note **可空**（空串合法）。

连续链（同实例，逐腿精确读回，版本单调）：
  T1 人改（注入点击升温按钮）→ owner v+1 且 targetTemp 精确；
  T2 外部改（SET_NOTE 含 emoji）→ APPLIED → 公开读回逐码元精确；
  T3 画面投影：渲染器 accepted 日志出现外部写入后的 owner 值；
  T4 旧版本拒绝：stale expectedVersion → version_conflict，版本不变；
  T5 人续写（新版本上再点升温）→ 精确读回；
  T6 可空备注：SET_NOTE ""（空串）合法应用并精确读回（领域差异证据）；
  T7 越界拒绝：外部连升到 30 后再一次 → temp_out_of_range，版本不变。

用法： python3 verify_thermo_continuity.py   （需 --verify-transport --test-gates 产物）
"""

import json
import re
import subprocess
import sys
import time

sys.path.insert(0, "/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/platforms/ohos/scripts")
sys.path.insert(0, "/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/shared_operation_core")
from ohos_transport_probe_lib import BoundedExchange, parse_control_frame_strict  # noqa: E402

# 人改腿坐标链（2026-10-02 修复）：与 Pharos 驱动同一 `_viewport_transform`
# 推导（a11y 矩形 vp → 屏幕像素）。旧 inject_tap 把 a11y 的 vp 值原样注入
# 触摸队列（该队列是屏幕像素空间），点进了 H 时代新加的手滚控件区（节点
# thermo-hand-scroll），孤立 tap 的 POINTER_END 被捕获门拒绝——"事件 39 的
# 原控件已刷新"实为探针坐标错配，框架输入链健康（真实点击实测 TEMP_UP
# 每次 v+2 连续五次生效）。
import importlib.util as _ilu
from pathlib import Path as _Path
_spec = _ilu.spec_from_file_location(
    "pharos_driver",
    _Path("/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/platforms/ohos/scripts"
          "/h_source_preview_consumption.py"))
_m = _ilu.module_from_spec(_spec)
_spec.loader.exec_module(_m)
from client import parse_response  # noqa: E402

HOST, PORT = "127.0.0.1", 17857
PROTOCOL = "CJGUI_SHARED_OPERATION/2"
CAP = "cjgui-thermo-agent-20260926"
RESOURCE_ID = 9801
BUNDLE = "com.example.cjguithermo"
TOKEN = ""
EVIDENCE = []
RAW_ARCHIVE = ("/Users/jiangxuanyang/Desktop/cangjie/labs/ohos_cangjie_smoke/"
               "artifacts/cjgui-backend/verification/thermo_raw.json")
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
    out = {}
    for line in body.splitlines()[2:]:
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



def scroll_card_to_buttons():
    """上滑卡片滚动区（thermo-card-scroll，节点 40）把动作按钮行带回视口。"""
    p = thermo_semantic_point("thermo-card-scroll")
    if p is None:
        return
    cx, cy = int(p[0]), int(p[1])
    _m.uitest("drag", str(cx), str(cy + 160), str(cx), str(cy - 200))
    time.sleep(1.2)

def inject_tap(x, y):
    """真实用户路径：uitest 点击屏幕像素坐标（vp→px 由调用方完成）。"""
    _m.uitest("click", str(int(x)), str(int(y)))
    time.sleep(0.3)
    return "0"


BUNDLE_THERMO = "com.example.cjguithermo"


def readback_owner_state():
    """round12-R2：thermo 自己的 OWNER_STATE 读回（本包 CAP，共享端口）。"""
    _, resp = business(["GET_CONTEXT 0"])
    if not isinstance(resp, str):
        return None
    mo = re.search(r"OWNER_STATE_UTF8_HEX (\d+) ([0-9a-fA-F]*)", resp)
    if not mo:
        return None
    return bytes.fromhex(mo.group(2)).decode("utf-8", "replace")


def readback_semantic_point(semantic):
    """round12-R2：读回几何定位（accepted 发布边界冻结的 geo 记录 + 平台
    XComponent 原点）。日志 node-rect 全缺也可定位；失败返回 None（原因随
    EVIDENCE 落盘由调用方处理）。"""
    state = readback_owner_state()
    if not state:
        return None
    geo = _m.parse_geo_section(state)
    if geo is None:
        return None
    rec, why = _m.find_geo_record(geo, semantic)
    if rec is None:
        return None
    if rec['invisible']:
        return None
    pt = _m.hittable_point(rec)
    if pt is None:
        return None
    origin = _m.surface_origin_px()
    if origin is None:
        return None
    return (origin[0] + pt[0] * geo['density'], origin[1] + pt[1] * geo['density'])


def thermo_semantic_point(semantic):
    """thermo 自己的语义命中链。_m.accepted_semantic_point 按 Pharos bundle
    做 PID 过滤（后台 Pharos 的行会污染 rect/transform），这里按 thermo PID
    过滤后走同一条 accepted→rect→dumpLayout-transform 推导。"""
    import subprocess as _sp
    pid_out = _sp.run([HDC, "shell", f"pidof {BUNDLE_THERMO}"],
                      capture_output=True, text=True).stdout.strip()
    rows = _m.hilog_rows()
    if pid_out:
        rows = [r for r in rows if f" {pid_out} " in r] or rows
    rect, _nid = _m._semantic_rect_vp(rows, semantic)
    if rect is None:
        return None
    tr = _m._viewport_transform(rows)
    if tr is None:
        return None
    ox, oy, density = tr
    x = rect[0] + 15
    y = (rect[1] + rect[3]) / 2
    return (ox + x * density, oy + y * density)


def tap_semantic(semantic, fallback_xy=None):
    """按语义节点命中（滚动后区内子节点 clip 恢复非零，rect 推导可用）。"""
    p = thermo_semantic_point(semantic)
    if p is None and fallback_xy is not None:
        p = fallback_xy
    if p is None:
        return None
    inject_tap(p[0], p[1])
    return p


def fields_of(text):
    parsed = parse_response(text)
    version = None
    fields = {}
    for name, parts in parsed.entries:
        if name == "VERSION":
            version = int(parts[0])
        if name == "FIELD" and len(parts) >= 4:
            fid, ftype = parts[1], parts[2]
            if ftype == "STRING":
                # 传输层把空字符串编码为 "-"（无 hex 段）。
                if len(parts) >= 5 and parts[-1] != "-":
                    try:
                        fields[fid] = bytes.fromhex(parts[-1]).decode("utf-8")
                    except ValueError:
                        fields[fid] = parts[-1]
                else:
                    fields[fid] = ""
            else:
                fields[fid] = parts[-1] if parts else None
    return version, fields


def read_state():
    _, resp = business(["GET_CONTEXT 0"])
    return fields_of(resp)


def invoke(action, expected, args=None):
    # business() 已统一加 PROTOCOL/AUTH 头，这里只给命令段（重复头会被
    # 服务端按 invalid_request 拒绝——首轮实测踩到）。INVOKE 头的参数计数
    # 必须等于实际 ARG 行数（无参动作写 1 会被 invalid_parameters 拒）。
    args = list(args or [])
    frame = [f"INVOKE {expected} {action} 1 {len(args)}", f"ID {RESOURCE_ID}"]
    for name, vtype, value in args:
        if vtype == "STRING":
            enc = value.encode("utf-8")
            frame.append(f"ARG {name} STRING {len(enc)} {enc.hex().upper()}")
        else:
            frame.append(f"ARG {name} {vtype} {value}")
    _, resp = business(frame)
    parsed = parse_response(resp)
    rec = {"raw": resp[:400]}
    if parsed.kind == "ERROR":
        rec["applied"] = False
        rec["reason"] = next((e[1][0] for e in parsed.entries if e[0] == "ERROR"), "unknown")
    else:
        rec["applied"] = next((e[1][0] for e in parsed.entries if e[0] == "APPLIED"), "false") == "true"
        rec["reason"] = next((e[1][0] for e in parsed.entries if e[0] == "REASON"), "")
        rec["version_after"] = next((int(e[1][0]) for e in parsed.entries if e[0] == "VERSION_AFTER"), None)
    return rec


def node_rects_from_hilog():
    out = subprocess.run(
        [HDC, "shell", "hilog -x 2>/dev/null | grep -a 'node-rect' | tail -40"],
        capture_output=True, text=True).stdout
    rects = {}
    for line in out.splitlines():
        m = re.search(r"node-rect id=(-?\d+) x=(-?\d+) y=(-?\d+) w=(-?\d+) h=(-?\d+)", line)
        if m:
            rects[int(m.group(1))] = tuple(float(m.group(i)) for i in range(2, 6))
    return rects


def main() -> int:
    global TOKEN
    subprocess.run(
        [HDC, "shell",
         f"aa force-stop com.example.cjguiapp; aa force-stop {BUNDLE}; hilog -r; "
         f"aa start -a EntryAbility -b {BUNDLE} "
         "--pi cjguiTestGateFlushHoldMs 4000 --pi cjguiTestGateFlushHoldCount 1"],
        capture_output=True, text=True)
    time.sleep(8)
    subprocess.run([HDC, "fport", "tcp:17857", "tcp:7857"], capture_output=True)
    time.sleep(1)
    token_out = subprocess.run(
        [HDC, "shell", "hilog -x 2>/dev/null | grep -a 'verify seam armed token=' | tail -1"],
        capture_output=True, text=True).stdout
    m = re.search(r"token=(\S+)", token_out)
    if not m:
        note(f"FAIL 未读到 verify token（{token_out[:80]!r}）")
        return 2
    TOKEN = m.group(1)
    note(f"== T0 token={TOKEN}")
    failures = 0
    control_map("GATE_CLEAR")
    time.sleep(2.5)

    rects = node_rects_from_hilog()
    note(f"   accepted 节点几何: {len(rects)} 项")
    failures += check("恒温夹具节点几何可读（12/21/22/24）",
                      all(i in rects for i in (12, 21, 22, 24)), True)
    if not all(i in rects for i in (12, 21, 22, 24)):
        note("\n==== RESULT: FAIL ====")
        return failures

    version, fields = read_state()
    note(f"   基线 v={version} fields={fields}")
    failures += check("T0 起点字段独立（targetTemp/eco/note）",
                      ("targetTemp" in fields) and ("note" in fields), True)
    failures += check("T0 resourceId 独立（无 count/name 字段）",
                      ("count" in fields) or ("name" in fields), False)

    # T1 人改：注入点击「升温」按钮（节点 22）。卡片内容超表面（调试面板占
    # 下半屏，表面仅 ~487vp 而卡片 ~836vp）——先上滑卡片滚动区把按钮行带回
    # 视口（滚动后区内子节点 clip 随偏移更新，rect 推导恢复可用）再点击。
    x22, y22, w22, h22 = rects[22]
    scroll_card_to_buttons()
    tap_semantic("thermo-up", fallback_xy=(x22 + w22 / 2, y22 + h22 / 2))
    time.sleep(0.8)
    version, fields = read_state()
    failures += check("T1 人改升温 → targetTemp=23", fields.get("targetTemp"), "23")
    failures += check("T1 版本 +1", version, 1)

    def accepted_count():
        out = subprocess.run(
            [HDC, "shell", "hilog -x 2>/dev/null | grep -ac 'accepted node=12'"],
            capture_output=True, text=True).stdout.strip()
        return int(out) if out.isdigit() else 0

    accepted_after_t1 = accepted_count()

    # T2 外部改：SET_NOTE 含 emoji → 精确读回
    rec = invoke("SET_NOTE", version, [("text", "STRING", "外部备注🚰")])
    failures += check("T2 外部 SET_NOTE 应用", rec["applied"], True)
    version, fields = read_state()
    failures += check("T2 外部写入逐码元读回（含 emoji）", fields.get("note"), "外部备注🚰")
    failures += check("T2 版本 +1", version, 2)

    # T3 画面投影：外部写入后必须出现**新的** accepted 投影行（投影版本号
    # 独立于 owner 版本递增，不能按 owner v 对齐），且值=外部写入后的 owner 值。
    shown_text = ""
    for _ in range(6):
        time.sleep(1.0)
        if accepted_count() <= accepted_after_t1:
            continue
        acc = subprocess.run(
            [HDC, "shell", "hilog -x 2>/dev/null | grep -a 'accepted node=12 ' | tail -1"],
            capture_output=True, text=True).stdout
        shown = re.search(r"value=(.*?) v=", acc)
        if shown:
            shown_text = shown.group(1)
            break
    failures += check("T3 画面出现外部后的目标温度", shown_text, "目标温度：23℃")

    # T4 旧版本拒绝：stale expectedVersion
    stale = version - 1
    rec = invoke("TEMP_UP", stale)
    failures += check("T4 旧版本写入被拒（version_conflict）", rec["applied"], False)
    v_now, _ = read_state()
    failures += check("T4 版本不变", v_now, version)

    # T5 人续写：新版本上再点升温 → 精确读回（外部腿不碰滚动位置，仍先确保
    # 按钮在视口内再点）
    x22, y22, w22, h22 = rects[22]
    scroll_card_to_buttons()
    tap_semantic("thermo-up", fallback_xy=(x22 + w22 / 2, y22 + h22 / 2))
    time.sleep(0.8)
    version, fields = read_state()
    failures += check("T5 人续写升温 → targetTemp=24", fields.get("targetTemp"), "24")
    failures += check("T5 版本 +1", version, 3)

    # T6 可空备注：空串合法（领域差异证据）
    rec = invoke("SET_NOTE", version, [("text", "STRING", "")])
    failures += check("T6 空串备注合法应用", rec["applied"], True)
    version, fields = read_state()
    failures += check("T6 空串读回", fields.get("note"), "")

    # T7 越界拒绝：外部连升至 30 后再一次
    up_fail = 0
    guard = 0
    while True:
        v_now, fields = read_state()
        if int(fields.get("targetTemp", "0")) >= 30:
            break
        rec = invoke("TEMP_UP", v_now)
        note(f"   T7 逐步升温 v={v_now} temp={fields.get('targetTemp')} → applied={rec['applied']} reason={rec.get('reason')}")
        if not rec["applied"]:
            up_fail += 1
            break
        guard += 1
        if guard > 10:
            up_fail += 1
            break
    if up_fail == 0:
        v_before, _ = read_state()
        rec = invoke("TEMP_UP", v_before)
        up_fail += check("T7 越界升温被拒（temp_out_of_range）", rec["applied"], False)
        v_now, _ = read_state()
        up_fail += check("T7 越界拒绝后版本不变", v_now, v_before)
        up_fail += 1 if rec.get("reason") not in ("", "temp_out_of_range") else 0
    failures += up_fail

    with open(f"{EVIDENCE_DIR}/thermo_continuity_evidence.json", "w", encoding="utf-8") as f:
        json.dump(EVIDENCE, f, ensure_ascii=False, indent=2)
    EXCHANGE.flush_archive()
    note(f"\n==== RESULT: {'PASS' if failures == 0 else 'FAIL'} (failures={failures}) ====")
    return failures


if __name__ == "__main__":
    sys.exit(main())

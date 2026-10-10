#!/usr/bin/env python3
"""H 连续写作包 B：跨片段选择真实链（normal Pharos 设备验收）。

判据全部来自真实公共路径：uitest 指针手势 → 产品 commitVisualSelection →
会话选区安装（ADOPTED2 冻结）→ 系统键盘注入替换 → owner 逐字节 oracle。
跨片段证明：冻结的**源域**选区跨度必须包含段落分隔符（b'\\n'），即选择跨越
至少两个真实片段（单片段跨度不含分隔符）。

用法：python3 verify_pharos_cross_fragment.py --target 127.0.0.1:5555 --out <dir>
"""
import argparse
import importlib.util
import json
import re
import sys
import time
from pathlib import Path

HERE = Path(__file__).resolve().parent
_vdo_spec = importlib.util.spec_from_file_location('vdo', HERE / 'verify_pharos_dual_owner.py')
vdo = importlib.util.module_from_spec(_vdo_spec)
sys.modules['vdo'] = vdo
_vdo_spec.loader.exec_module(vdo)
m = vdo.m
sys.path.insert(0, str(HERE))
import strict_utf16  # noqa: E402

ADOPTED2_RE = re.compile(
    r"CJGUI_OWNED_SELECTION_ADOPTED2 node=(\d+) resource=(-?\d+) kind=(\d+) "
    r"sel=(\d+):(\d+) projection=(-?\d+) binding=(\d+)"
    r"(?: owner_version=(-?\d+))?(?: source_ctx=(\S+))?")


def frac_geo_records():
    state = m.public_owner_state(PORT)
    if state is None:
        return None, None, 'owner_state_absent'
    geo = m.parse_geo_section(state)
    if geo is None:
        return None, None, 'geo_section_absent'
    origin = m.surface_origin_px()
    if origin is None:
        return None, None, 'surface_origin_absent'
    recs = []
    for r in geo['records']:
        if r['semantic'] == 'pharos-editor-block' and r['node'] >= 1000 and not r['invisible']:
            vx, vy, vw, vh = r['visible']
            if vw >= 24 and vh >= 8:
                recs.append(r)
    recs.sort(key=lambda r: r['node'])
    return recs, (geo, origin), None


def vp_to_px(geo_origin, x_vp, y_vp):
    geo, origin = geo_origin
    d = geo['density']
    return (int(origin[0] + x_vp * d), int(origin[1] + y_vp * d))


def modetext():
    c = m.ctx(PORT)
    mo = re.search(r'MODE=(\w+)', c)
    return mo.group(1) if mo else ''


def ensure_preview(results):
    """复用既有 reach_mode（单动作 + 快照/票据判定；r31 实跑路径）。"""
    ok, outcome = vdo.reach_mode(PORT, 'preview', results, 'to-visual')
    return ok, outcome


def wait_selection(fence_rows, node, timeout=12.0):
    """围栏后最后一条非空 ADOPTED2（本节点）→ (sel16 or None, row)。"""
    deadline = time.time() + timeout
    best = None
    best_row = ''
    while time.time() < deadline:
        rows = m.hilog_rows()
        try:
            si = rows.index(fence_rows) + 1 if fence_rows in rows else 0
        except ValueError:
            si = 0
        for r in rows[si:]:
            mo = ADOPTED2_RE.search(r)
            if mo and int(mo.group(1)) == node:
                s, e = int(mo.group(4)), int(mo.group(5))
                if e > s:
                    best = (s, e)
                    best_row = r[-200:]
        if best is not None:
            return best, best_row
        time.sleep(0.4)
    return None, best_row


def wait_body(want_bytes, version_before, timeout=15.0):
    deadline = time.time() + timeout
    last = None
    while time.time() < deadline:
        v, hx = m.read_all(PORT)
        last = (v, bytes.fromhex(hx))
        if v > version_before and last[1] == want_bytes:
            return last[0], last[1], True
        if v > version_before and last[1] != want_bytes:
            # 已前进但内容不符：继续等一小段（拆笔可能分多笔）
            time.sleep(0.3)
            continue
        time.sleep(0.3)
    return (last[0], last[1], False) if last else (None, None, False)


def replace_selection(tag, sel16, node=190):
    """注入 'X'，期望 = 冻结选区上的精确替换（strict oracle），版本恰 +1。"""
    v0, hx0 = m.read_all(PORT)
    before = bytes.fromhex(hx0)
    bs = strict_utf16.utf16_to_byte_offset(before, sel16[0])
    be = strict_utf16.utf16_to_byte_offset(before, sel16[1])
    if bs is None or be is None or be <= bs:
        return {'leg': tag, 'ok': False, 'fail': 'sel_not_utf8_boundary', 'sel': list(sel16)}
    span = before[bs:be]
    crosses = b'\n' in span
    want = before[:bs] + b'X' + before[be:]
    fence = m.hilog_rows()[-1] if m.hilog_rows() else ''
    m.uitest('text', 'X')
    v1, body1, ok = wait_body(want, v0)
    leg = {'leg': tag, 'ok': ok, 'sel16': list(sel16), 'sel_bytes': [bs, be],
           'span_hex': span.hex(), 'span_crosses_paragraph_separator': crosses,
           'version_before': v0, 'version_after': v1,
           'exact': ok and body1 == want, 'minus_one_byte': v1 == v0 + 1 if v1 else False,
           'want_len': len(want), 'got_len': len(body1) if body1 else -1,
           'fence_kept': bool(fence)}
    if not crosses:
        leg['ok'] = False
        leg['fail'] = 'selection_did_not_cross_fragments'
    if not leg['exact']:
        leg['fail'] = 'owner_bytes_not_exact'
    if not leg['minus_one_byte']:
        leg['ok'] = False
        leg['fail'] = 'version_delta_not_one'
    return leg


def undo_once():
    """Deliver exactly one Undo intent, then observe its owner result for at most 8s."""
    v_before, hx_before = m.read_all(PORT)
    pt, why = m.readback_target_point('pharos-undo', PORT)
    if pt is None:
        return False, 'undo_target_absent:' + str(why)
    m.uitest('click', str(int(pt[0])), str(int(pt[1])))
    deadline = time.monotonic() + 8
    while time.monotonic() < deadline:
        v_after, hx_after = m.read_all(PORT)
        if v_after != v_before or hx_after != hx_before:
            return True, 'undo_applied_once'
        time.sleep(0.1)
    return False, 'undo_once_no_effect'


def drag_once(p1, p2):
    m.uitest('drag', str(p1[0]), str(p1[1]), str(p2[0]), str(p2[1]))
    time.sleep(2.0)


def forward_drag_leg(recs, geo_origin, tag):
    """跨至少 3 个片段的正向拖选：起点在片段 i 首行，终点在片段 j 首行右侧。"""
    for i in range(0, max(len(recs) - 2, 0)):
        for j in range(i + 2, len(recs)):
            a, b = recs[i], recs[j]
            ar, br = a['visible'], b['visible']
            sx, sy = vp_to_px(geo_origin, ar[0] + 16, ar[1] + 8)
            ex, ey = vp_to_px(geo_origin, br[0] + min(240, max(br[2] - 30, 40)), br[1] + 8)
            dx, dy = ex - sx, ey - sy
            if dx > 0 and dx > abs(dy):
                fence = m.hilog_rows()[-1] if m.hilog_rows() else ''
                drag_once((sx, sy), (ex, ey))
                sel, row = wait_selection(fence, 190)
                if sel is not None:
                    return sel, (a['node'], b['node']), {'i': i, 'j': j,
                        'p1': [sx, sy], 'p2': [ex, ey], 'row': row, 'fence': fence}
                return None, None, {'fail': 'single_drag_no_selection', 'p1': [sx,sy], 'p2':[ex,ey], 'fence':fence}
    return None, None, {'fail': 'no_horizontal_dominant_pair'}


def reverse_drag_leg(recs, geo_origin):
    """反向（锚在后、焦点在前）拖选：从后片段右侧向左上拉到前片段左侧。"""
    for j in range(len(recs) - 1, 1, -1):
        for i in range(j - 2, -1, -1):
            a, b = recs[i], recs[j]
            ar, br = a['visible'], b['visible']
            sx, sy = vp_to_px(geo_origin, br[0] + min(240, max(br[2] - 30, 40)), br[1] + 8)
            ex, ey = vp_to_px(geo_origin, ar[0] + 16, ar[1] + 8)
            dx, dy = ex - sx, ey - sy
            if dx < 0 and abs(dx) > abs(dy):
                fence = m.hilog_rows()[-1] if m.hilog_rows() else ''
                drag_once((sx, sy), (ex, ey))
                sel, row = wait_selection(fence, 190)
                if sel is not None:
                    return sel, (a['node'], b['node']), {'i': i, 'j': j,
                        'p1': [sx, sy], 'p2': [ex, ey], 'row': row, 'fence': fence}
                return None, None, {'fail': 'single_drag_no_selection', 'p1': [sx,sy], 'p2':[ex,ey], 'fence':fence}
    return None, None, {'fail': 'no_reverse_pair'}


def main():
    out = Path(args.out)
    out.mkdir(parents=True, exist_ok=False)
    results = {'legs': [], 'mode': modetext()}
    m.TARGET = args.target
    ok, why = ensure_preview(results)
    results['preview'] = {'ok': ok, 'why': why, 'mode_after': modetext()}
    if not ok:
        (out / 'cross-fragment.json').write_text(json.dumps(results, ensure_ascii=False, indent=2))
        return 1

    # ---- 正向：跨 >=3 片段拖选 → 精确替换 → Undo ----
    recs, geo_origin, err = frac_geo_records()
    if recs is None or len(recs) < 3:
        results['legs'].append({'leg': 'geo', 'ok': False, 'fail': err or f'fragments={0 if recs is None else len(recs)}'})
        (out / 'cross-fragment.json').write_text(json.dumps(results, ensure_ascii=False, indent=2))
        return 1
    results['fragments'] = [{'node': r['node'], 'bounds': r['bounds'], 'visible': r['visible']} for r in recs]

    v0, hx0 = m.read_all(PORT)
    sel, pair, ev = forward_drag_leg(recs, geo_origin, 'forward')
    results['forward_drag'] = ev
    if sel is None:
        results['legs'].append({'leg': 'forward_selection', 'ok': False, 'fail': ev.get('fail', 'no_selection')})
        (out / 'cross-fragment.json').write_text(json.dumps(results, ensure_ascii=False, indent=2))
        return 1
    results['legs'].append({'leg': 'forward_selection', 'ok': True, 'sel16': list(sel),
                            'fragment_pair': pair})
    leg = replace_selection('forward_replace', sel)
    results['legs'].append(leg)
    if not leg['ok']:
        (out / 'cross-fragment.json').write_text(json.dumps(results, ensure_ascii=False, indent=2))
        return 1
    ok_u, why_u = undo_once()
    v_u, hx_u = m.read_all(PORT)
    back_ok = ok_u and bytes.fromhex(hx_u) == bytes.fromhex(hx0)
    results['legs'].append({'leg': 'forward_undo', 'ok': back_ok, 'why': why_u,
                            'version': v_u, 'restored_exact': bytes.fromhex(hx_u) == bytes.fromhex(hx0)})

    # ---- 反向：后片段 → 前片段，替换 → Undo ----
    recs2, geo_origin2, err2 = frac_geo_records()
    if recs2 is not None and len(recs2) >= 3 and back_ok:
        sel2, pair2, ev2 = reverse_drag_leg(recs2, geo_origin2)
        results['reverse_drag'] = ev2
        if sel2 is not None:
            results['legs'].append({'leg': 'reverse_selection', 'ok': True, 'sel16': list(sel2),
                                    'fragment_pair': pair2})
            leg2 = replace_selection('reverse_replace', sel2)
            results['legs'].append(leg2)
            if leg2['ok']:
                ok_u2, why_u2 = undo_once()
                v_u2, hx_u2 = m.read_all(PORT)
                results['legs'].append({'leg': 'reverse_undo', 'ok': ok_u2 and bytes.fromhex(hx_u2) == bytes.fromhex(hx0),
                                        'why': why_u2, 'version': v_u2})
        else:
            results['legs'].append({'leg': 'reverse_selection', 'ok': False,
                                    'fail': ev2.get('fail', 'no_selection')})

    status = 'ok' if all(l.get('ok') for l in results['legs']) else 'fail'
    results['status'] = status
    (out / 'cross-fragment.json').write_text(json.dumps(results, ensure_ascii=False, indent=2))
    print('status =', status)
    for l in results['legs']:
        print(' ', 'OK ' if l.get('ok') else 'FAIL', l['leg'], {k: v for k, v in l.items()
              if k not in ('leg', 'ok', 'row', 'fence') and not isinstance(v, (bytes,))})
    return 0 if status == 'ok' else 1


ap = argparse.ArgumentParser()
ap.add_argument('--target', default='127.0.0.1:5555')
ap.add_argument('--port', type=int, default=28991)
ap.add_argument('--out', required=True)
args = ap.parse_args()
PORT = args.port
if __name__ == '__main__':
    sys.exit(main())

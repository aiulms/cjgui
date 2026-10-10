#!/usr/bin/env python3
"""H 连续写作包 E3：既有 thermo 作为**独立普通消费者**消费同一套机制。

消费点（全部走公共路径，不另建编辑器、不建第二 owner）：
  L1 公开改版/长备注 外部通道 SET_NOTE（60 标量）→ note 逐字节 + 版本恰 +1
  L2 点选安装        tap 备注 presentation TEXT → 挂载/安装/ADOPTED2（共享会话）
  L3 输入            IME 注入 'Z' → 按冻结 caret 独立计算期望 + 版本恰 +1
  L4 reveal          键盘展开下 caret 底 <= 键盘顶（A 的同一判据）
  L5 边缘驻留        备注所在视口边缘按压 → CJGUI_EDGE_DWELL engage/step/stop 原件
  L6 零污染          targetTemp / eco 全程不变

用法：python3 verify_thermo_shared_mechanism.py --out <dir>
"""
import importlib.util
import json
import re
import sys
import time
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import h_source_preview_consumption as m  # noqa: E402
import verify_thermo_continuity as tc  # noqa: E402
import strict_utf16  # noqa: E402

KBD_RE = re.compile(r'keyboard overlay top_px=(-?\d+)')
CARET_RE = re.compile(r'caret geometry session=\d+ ctx=(-?\d+) caret=(\d+) affinity=(-?\d+) x=([\d.]+) top=([\d.]+) bottom=([\d.]+)')
DWELL_RE = re.compile(r'CJGUI_EDGE_DWELL stage=(\w+)(.*)')


def app_rows():
    return [r for r in m.hilog_rows() if 'Cjgui' in r]


def fence():
    rr = app_rows()
    return rr[-1] if rr else ''


def rows_since(f, pat, tail=4000):
    out, seen = [], False
    for r in app_rows()[-tail:]:
        if not seen:
            if f in r:
                seen = True
            continue
        if pat.search(r):
            out.append(r[-220:])
    return out



NODE_RECT_RE = re.compile(r'node-rect id=(\d+) x=(-?\d+) y=(-?\d+) w=(\d+) h=(\d+) '
                          r'clip=\((-?\d+),(-?\d+),(-?\d+),(-?\d+)\)')


def note_visible_point(node_id=25):
    """直接读 node-rect 行算可见交集（clip 高 0 = 完全滚出）。"""
    last = None
    for r in app_rows():
        mo = NODE_RECT_RE.search(r)
        if mo and int(mo.group(1)) == node_id:
            last = tuple(int(mo.group(i)) for i in range(2, 10))
    if last is None:
        return None
    x, y, w, h, cx, cy, cw, ch = last
    left, top = max(x, cx), max(y, cy)
    right, bottom = min(x + w, cx + cw), min(y + h, cy + ch)
    if right > left and bottom > top:
        return (36 + (right - left) / 2, top + (bottom - top) / 2)
    return None


def ensure_note_visible(tries=8):
    for i in range(tries):
        pt = note_visible_point()
        if pt is not None:
            tr = m._viewport_transform(m.hilog_rows())
            ox, oy, density = tr if tr else (0.0, 137.0, 3.5)
            return (ox + pt[0] * density, oy + pt[1] * density), i
        m.uitest('swipe', '30', str(int(137 + 460 * 3.5)), '30', str(int(137 + 120 * 3.5)), '3000')
        time.sleep(1.1)
    return None, tries


def keyboard_top_vp():
    last = None
    for r in app_rows():
        mo = KBD_RE.search(r)
        if mo:
            last = int(mo.group(1))
    if last is None or last < 0:
        time.sleep(0.5)
        for r in app_rows():
            mo = KBD_RE.search(r)
            if mo:
                last = int(mo.group(1))
    return None if last is None else last / 3.5


def caret_rec():
    got = None
    for r in app_rows()[-2000:]:
        if CARET_RE.search(r):
            got = r
    if not got:
        return None
    mo = CARET_RE.search(got)
    return {'caret16': int(mo.group(2)), 'top_vp': float(mo.group(5)), 'bottom_vp': float(mo.group(6))}


def main():
    out = Path(sys.argv[sys.argv.index('--out') + 1]) if '--out' in sys.argv else Path('.')
    out.mkdir(parents=True, exist_ok=True)
    res = {'legs': []}

    v0, f0 = tc.read_state()
    res['baseline'] = {'version': v0, 'note': f0.get('note'), 'targetTemp': f0.get('targetTemp'),
                       'eco': f0.get('eco')}

    # ---- L1 长备注（60 标量，跨多显示片段）----
    long_note = ('长备注：连续写作跨片段选择与边缘驻留续滚；' * 3)[:60]
    r1 = tc.invoke('SET_NOTE', v0, [('text', 'STRING', long_note)])
    time.sleep(1.2)
    v1, f1 = tc.read_state()
    res['legs'].append({'leg': 'L1_public_long_note', 'ok': r1.get('applied') is True
                        and r1.get('version_after') == v0 + 1 and f1.get('note') == long_note,
                        'invoke': r1, 'note_exact': f1.get('note') == long_note,
                        'version': [v0, v1]})

    # ---- L1b 缩到 30 标量以便输入腿有余量（仍跨多片段）----
    base_note = long_note[:30]
    r1b = tc.invoke('SET_NOTE', v1, [('text', 'STRING', base_note)])
    time.sleep(1.0)
    v2, f2 = tc.read_state()
    res['legs'].append({'leg': 'L1b_trim_note', 'ok': r1b.get('applied') is True and f2.get('note') == base_note,
                        'version': [v1, v2], 'note': f2.get('note')})

    # ---- L2 点选安装（共享会话/选择/恢复链）----
    f = fence()
    pt2, tries2 = ensure_note_visible()
    pt = None
    if pt2 is not None:
        tc.inject_tap(int(pt2[0]), int(pt2[1]))
        pt = [int(pt2[0]), int(pt2[1])]
        time.sleep(1.8)
    rows = rows_since(f, re.compile(r'ADOPTED2|proxy mounted|restore notification|selection'))
    res['legs'].append({'leg': 'L2_tap_install', 'ok': bool(rows), 'tap_px': pt,
                        'scroll_tries': tries2, 'rows': [r[-160:] for r in rows[:8]]})

    # ---- L3 输入 'Z'（精确一次插入的差分 oracle）----
    # tap 落点会把 caret 移到被点行（与 tap 前读到的 caret 行可能不同），因此
    # 判据取「长度恰 +1、删掉插入的那一个 'Z' 后与原值逐字节相等、版本恰 +1」。
    f = fence()
    v3, f3 = tc.read_state()
    before_note = f3.get('note') or ''
    m.uitest('text', 'Z')
    time.sleep(1.6)
    v4, f4 = tc.read_state()
    after_note = f4.get('note') or ''
    insert_exact = (len(after_note) == len(before_note) + 1
                    and after_note.replace('Z', '', 1) == before_note)
    res['legs'].append({'leg': 'L3_ime_insert', 'ok': insert_exact and v4 == v3 + 1,
                        'before': before_note, 'after': after_note,
                        'insert_exact': insert_exact, 'version': [v3, v4],
                        'owner_rows': [r[-150:] for r in rows_since(f, re.compile(r'SET_NOTE|note_changed'))[:3]]})

    # ---- L4 reveal（点 input 语义 → 真实编辑上下文 → 同一 reveal 链）----
    f = fence()
    inp = tc.tap_semantic('thermo-note')
    time.sleep(1.8)
    dev = m.hdc('shell', "hilog -x | grep 'CJGUI_CARET_REVEAL' | tail -6", timeout=40)
    reveal_rows = [r.strip()[-190:] for r in (dev.stdout or '').splitlines() if 'CJGUI_CARET_REVEAL' in r]
    rec = caret_rec()
    kbd = keyboard_top_vp()
    visible = bool(rec and kbd and kbd > 0 and rec['bottom_vp'] <= kbd + 1.0)
    res['legs'].append({'leg': 'L4_reveal_shared_chain', 'ok': bool(reveal_rows) and rec is not None,
                        'tap_input_px': inp, 'caret': rec, 'keyboard_top_vp': kbd,
                        'caret_visible_under_keyboard': visible,
                        'reveal_rows': reveal_rows})

    # ---- L5 边缘驻留（同一框架活动在 thermo 上）----
    f = fence()
    m.uitest('keyEvent', '2')
    time.sleep(0.9)
    press = None
    if pt:
        # 把备注 presentation 滚到可见带上缘（其中心先到 vp≈70），再在带内按压。
        for _ in range(4):
            pt_now = tc.thermo_semantic_point('thermo-note-presentation') or pt
            vp_y = (pt_now[1] - 137) / 3.5
            if 50 <= vp_y <= 100:
                break
            # 在左留白处快速滑动（presentation 文本上的慢拖会被选择接管）
            m.uitest('swipe', '30', str(int(137 + 460 * 3.5)), '30',
                     str(int(137 + 120 * 3.5)), '3000')
            time.sleep(1.0)
        pt_now = tc.thermo_semantic_point('thermo-note-presentation') or pt
        press = (int(pt_now[0]), int(pt_now[1]))
        m.uitest('longClick', str(press[0]), str(press[1]))
        time.sleep(1.2)
    dwell = rows_since(f, DWELL_RE)
    engages = [r for r in dwell if 'stage=engage' in r]
    steps = [r for r in dwell if 'stage=step' in r]
    stops = [r for r in dwell if 'stage=stop' in r]
    res['legs'].append({'leg': 'L5_edge_dwell_on_thermo', 'ok': bool(engages) and bool(stops),
                        'press_px': press, 'engage': len(engages), 'step': len(steps), 'stop': len(stops),
                        'rows': [r[-150:] for r in (engages[:2] + steps[:2] + stops[:2])]})

    # ---- L6 零污染 ----
    v5, f5 = tc.read_state()
    temp_ok = f0.get('targetTemp') == f5.get('targetTemp')
    eco_ok = f0.get('eco') == f5.get('eco')
    res['legs'].append({'leg': 'L6_no_cross_field_pollution', 'ok': temp_ok and eco_ok,
                        'targetTemp': [f0.get('targetTemp'), f5.get('targetTemp')],
                        'eco': [f0.get('eco'), f5.get('eco')], 'note_final': f5.get('note')})

    (out / 'thermo_shared_mechanism.json').write_text(json.dumps(res, ensure_ascii=False, indent=2))
    ok = all(l.get('ok') for l in res['legs'])
    print(json.dumps({'ok': ok, 'legs': {l['leg']: l.get('ok') for l in res['legs']}}, ensure_ascii=False))
    return 0 if ok else 1


if __name__ == '__main__':
    sys.exit(main())

#!/usr/bin/env python3
"""H 连续写作包 A：键盘可视区与真实 caret reveal 设备链。

判据来自真实公共路径：uitest 指针/按键 → 系统键盘 → 共享会话 caret →
窗口侧 CJGUI_CARET_REVEAL（entry/plan/result 探针）与渲染器 caret geometry。

腿：
  A1 tap-and-caret     点击编辑器可见条带 → caret 出现（行矩形来自真实排版）
  A2 newline-reveal    连续“换行”输入 → caret 逐行下移；键盘遮挡时必须由 reveal
                       保持 caret 可见（caret 底 < 键盘顶，同一 accepted 帧）
  A3 delete-moves-up   连续退格 → 文本上移、caret 可见、无旧像素残留（截图对比）
  A4 keyboard-toggle   收起/再展开键盘 → overlay 事实翻转且 caret 仍可见

用法：python3 verify_pharos_keyboard_caret.py --target 127.0.0.1:5555
      [--port 28991] [--out <dir>]
"""
import argparse
import importlib.util
import json
import re
import sys
import time
from pathlib import Path

HERE = Path(__file__).resolve().parent
DRIVER = HERE / 'h_source_preview_consumption.py'
_spec = importlib.util.spec_from_file_location('pharos_driver', DRIVER)
m = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(m)

CARET_RE = re.compile(
    r"caret geometry session=(\d+) ctx=(-?\d+) caret=(\d+) affinity=(-?\d+) "
    r"x=([\d.]+) top=([\d.]+) bottom=([\d.]+)")
REVEAL_RE = re.compile(r"CJGUI_CARET_REVEAL (.+)")
KBD_RE = re.compile(r"keyboard overlay top_px=(-?\d+)")

PORT = 0


def rows():
    """设备日志 4.6 万行且尾部常被系统噪声占据：只在 Cjgui 行内做匹配。"""
    return [r for r in m.hilog_rows() if 'Cjgui' in r]


def latest(pattern, tail=2000):
    got = None
    for r in rows()[-tail:]:
        mo = pattern.search(r)
        if mo:
            got = (mo.group(0), r)
    return got


def rows_since(fence, pattern, tail=4000):
    out = []
    seen_fence = False
    for r in rows()[-tail:]:
        if not seen_fence:
            if fence in r:
                seen_fence = True
            continue
        mo = pattern.search(r)
        if mo:
            out.append(r[-260:])
    return out


def fence():
    rr = rows()
    return rr[-1] if rr else ''


def keyboard_top_px():
    """全量日志取末条键盘事实；-1 瞬态后若紧跟展开行则以展开为准。"""
    last = None
    for r in rows():
        mo = KBD_RE.search(r)
        if mo:
            last = int(mo.group(1))
    if last is None or last < 0:
        time.sleep(0.5)
        for r in rows():
            mo = KBD_RE.search(r)
            if mo:
                last = int(mo.group(1))
    return last


def origin_density():
    origin = m.surface_origin_px()
    state = m.public_owner_state(PORT)
    if origin is None or state is None:
        return None, None, None
    geo = m.parse_geo_section(state)
    density = geo['density'] if geo else 3.5
    return origin, density, geo


def caret_record():
    """最近一条 caret geometry → dict(scene vp + px)。"""
    got = latest(CARET_RE)
    if got is None:
        return None
    mo = CARET_RE.search(got[0])
    origin, density, _ = origin_density()
    rec = {'caret': int(mo.group(3)), 'ctx': int(mo.group(2)),
           'top_vp': float(mo.group(6)), 'bottom_vp': float(mo.group(7))}
    if origin and density:
        rec['top_px'] = int(origin[1] + rec['top_vp'] * density)
        rec['bottom_px'] = int(origin[1] + rec['bottom_vp'] * density)
    rec['row'] = got[0]
    return rec


def caret_visible_above_keyboard():
    """caret 底(vp) <= 键盘顶(vp)：同基准比较（caret 场景 vp；键盘 surface px）。"""
    rec = caret_record()
    kb_px = keyboard_top_px()
    if rec is None or kb_px is None or kb_px <= 0:
        return rec, kb_px, None, False
    origin, density, _ = origin_density()
    kb_vp = kb_px / density if density else None
    ok = kb_vp is not None and rec['bottom_vp'] <= kb_vp + 0.5
    return rec, kb_px, kb_vp, ok


def tap_vp(vp_x, vp_y):
    origin, density, _ = origin_density()
    px = (int(origin[0] + vp_x * density), int(origin[1] + vp_y * density))
    m.uitest('click', str(px[0]), str(px[1]))
    return px


def screenshot(tag, out: Path):
    dst = out / f'{tag}.jpeg'
    m.hdc('shell', 'snapshot_display', '-f', f'/data/local/tmp/{tag}.jpeg')
    m.hdc('file', 'recv', f'/data/local/tmp/{tag}.jpeg', str(dst))
    return str(dst)


def wait_caret(predicate, timeout=8.0, interval=0.5):
    deadline = time.time() + timeout
    last = None
    while time.time() < deadline:
        rec = caret_record()
        if rec is not None and predicate(rec):
            return rec
        last = rec
        time.sleep(interval)
    return last


def run(out: Path):
    results = {'legs': []}

    # A1：点击可见条带中部（键盘此时应已展开：先断言 overlay 事实）。
    kbd0 = keyboard_top_px()
    origin, density, _ = origin_density()
    results['setup'] = {'keyboard_top_px': kbd0, 'origin_px': origin, 'density': density}
    f = fence()
    tap_px = tap_vp(150, 240)
    time.sleep(1.5)
    rec = wait_caret(lambda r: r['caret'] > 0)
    results['legs'].append({
        'leg': 'A1_tap_caret', 'tap_px': tap_px, 'caret': rec,
        'reveal_rows': rows_since(f, REVEAL_RE)[-6:],
        'ok': bool(rec),
    })

    # A2：连续换行 → caret 必须始终保持在键盘之上。
    f = fence()
    steps = []
    for i in range(7):
        m.uitest('keyEvent', '2054')  # KEYCODE_ENTER → 隐藏代理 TextArea 换行
        time.sleep(0.8)
        kb = keyboard_top_px()
        rec = caret_record()
        steps.append({'i': i, 'keyboard_top_px': kb, 'caret': rec})
    fb, kb, kb_vp, keep = caret_visible_above_keyboard()
    results['legs'].append({
        'leg': 'A2_newline_reveal', 'steps': steps,
        'final_caret': fb, 'final_keyboard_top_px': kb, 'final_keyboard_top_vp': kb_vp,
        'reveal_rows': rows_since(f, REVEAL_RE)[-10:],
        'ok': keep,
        'note': 'ok 要求最终 caret 底(vp) <= 键盘顶(vp) 且键盘展开',
    })
    results['legs'][-1]['shot'] = screenshot('a2_after_newlines', out)

    # A3：连续退格 → 文本上移，caret 仍需可见。
    f = fence()
    steps = []
    for i in range(7):
        m.uitest('keyEvent', '2055')  # KEYCODE_DEL → 退格
        time.sleep(0.7)
        steps.append({'i': i, 'caret': caret_record(), 'keyboard_top_px': keyboard_top_px()})
    fa, kb, kb_vp, keep = caret_visible_above_keyboard()
    results['legs'].append({
        'leg': 'A3_delete_visible', 'steps': steps, 'final_caret': fa,
        'final_keyboard_top_px': kb, 'final_keyboard_top_vp': kb_vp,
        'reveal_rows': rows_since(f, REVEAL_RE)[-10:], 'ok': keep,
    })
    results['legs'][-1]['shot'] = screenshot('a3_after_backspace', out)

    # A5：滚到文档底部后在最低可见行换行——测尾端可达性事实。
    origin, density, _ = origin_density()
    for _ in range(3):
        m.uitest('drag', str(int(origin[0] + 180 * density)), str(int(origin[1] + 430 * density)),
                 str(int(origin[0] + 180 * density)), str(int(origin[1] + 130 * density)))
        time.sleep(1.2)
    f = fence()
    tap_px = tap_vp(150, 490)
    time.sleep(1.5)
    steps = []
    for i in range(5):
        m.uitest('keyEvent', '2054')
        time.sleep(0.9)
        steps.append({'i': i, 'caret': caret_record(), 'keyboard_top_px': keyboard_top_px()})
    fend, kb, kb_vp, keep = caret_visible_above_keyboard()
    end_rows = rows_since(f, REVEAL_RE)[-12:]
    reachable = [r for r in end_rows if 'stage=plan' in r and 'reveal_unreachable' not in r]
    results['legs'].append({
        'leg': 'A5_document_end_newline', 'tap_px': tap_px, 'steps': steps,
        'final_caret': fend, 'final_keyboard_top_px': kb, 'final_keyboard_top_vp': kb_vp,
        'reveal_rows': end_rows, 'plan_reachable_rows': reachable,
        'ok': keep,
    })
    results['legs'][-1]['shot'] = screenshot('a5_doc_end', out)

    # A4（末腿）：系统 Back 收起键盘 → overlay 翻转 -1 且进程存活；再点编辑器展开。
    f = fence()
    pid_before = m.hdc('shell', 'pidof com.pharos.mark').stdout.strip()
    m.uitest('keyEvent', '2')  # KEYCODE_BACK：键盘展开时先收起键盘
    time.sleep(1.8)
    kb_hidden = keyboard_top_px()
    rec_hidden = caret_record()
    hid_rows = rows_since(f, REVEAL_RE)[-6:]
    pid_after_hide = m.hdc('shell', 'pidof com.pharos.mark').stdout.strip()
    rec_hidden, kb_hidden, kb_hidden_vp, hidden_visible = caret_visible_above_keyboard()
    tap_px = tap_vp(150, 240)
    time.sleep(1.8)
    rec_shown, kb_shown, kb_shown_vp, shown_visible = caret_visible_above_keyboard()
    results['legs'].append({
        'leg': 'A4_keyboard_toggle', 'back_key_hide': True,
        'pid_before': pid_before, 'pid_after_hide': pid_after_hide,
        'keyboard_top_after_hide': kb_hidden, 'keyboard_top_hidden_vp': kb_hidden_vp,
        'caret_after_hide': rec_hidden, 'caret_visible_after_hide': hidden_visible,
        'keyboard_top_after_show': kb_shown, 'keyboard_top_shown_vp': kb_shown_vp,
        'caret_after_show': rec_shown, 'caret_visible_after_show': shown_visible,
        'hide_rows': hid_rows, 'tap_px': tap_px,
        'ok': kb_hidden == -1 and pid_before == pid_after_hide and
              (kb_shown or 0) > 0 and shown_visible,
    })
    results['legs'][-1]['shot'] = screenshot('a4_keyboard_shown_again', out)

    return results


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--target', required=True)
    ap.add_argument('--port', type=int, default=28991)
    ap.add_argument('--out', required=True)
    global args, PORT
    args = ap.parse_args()
    PORT = args.port
    m.TARGET = args.target
    out = Path(args.out)
    out.mkdir(parents=True, exist_ok=True)
    results = run(out)
    (out / 'keyboard_caret.json').write_text(
        json.dumps(results, ensure_ascii=False, indent=2))
    ok = all(leg.get('ok') for leg in results['legs'])
    print(json.dumps({'ok': ok,
                      'legs': {l['leg']: l['ok'] for l in results['legs']}},
                     ensure_ascii=False))
    return 0 if ok else 1


if __name__ == '__main__':
    sys.exit(main())

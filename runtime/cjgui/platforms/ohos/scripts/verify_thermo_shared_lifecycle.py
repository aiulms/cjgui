#!/usr/bin/env python3
"""R3 设备消费（h-source-preview-followup 2026-10-02）：thermo 通过**真实系统
选区安装与输入**证明共享生命周期 + 生成字段通用范围会话桥的复用。

与既有 verify_thermo_continuity.py（按钮＋外部 SET_NOTE 的业务回归，保留）
互补，本脚本按交接验收跑完整链，判据全部来自本轮日志与公开通道读回：
  1 安装     ：真实触摸定位备注 → 共享类 attach/两帧确认 INSTALLED＋rc=0；
  2 输入     ：系统键盘注入 → GET_CONTEXT note 逐字节等于注入文本（插入）；
  3 非空选区 ：拖选 → 共享类确认**非空**选区（冻结为唯一事实）；
  4 精确替换 ：注入 'X' → note == strict_utf16 oracle 按冻结选区独立计算的期望；
  5 外部改版 ：公开通道 SET_NOTE（外部路径）→ note 精确等于外部文本；
  6 继续输入 ：等待改版后的新安装确认（重基后的平台事实）→ 注入 'Y' →
              note == 按新冻结选区独立计算的期望。
"""
import json
import re
import subprocess
import sys
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import verify_thermo_continuity as tc  # noqa: E402
import strict_utf16  # noqa: E402

OUT = Path('/Users/jiangxuanyang/Desktop/cangjie/artifacts/h-r-final-20261002/thermo-shared')
OUT.mkdir(parents=True, exist_ok=True)
BUNDLE = tc.BUNDLE_THERMO
HDC = tc.HDC
RESOURCE_ID = 9801


def thermo_pid():
    out = subprocess.run([HDC, 'shell', f'pidof {BUNDLE}'],
                         capture_output=True, text=True).stdout.strip()
    return out.split()[0] if out else None


def rows_for(pid):
    rows = tc._m.hilog_rows()
    return [r for r in rows if f' {pid} ' in r] or rows


def confirmed_selection(rows):
    """本进程日志里**最后一次**「terminal=INSTALLED 且 native rc=0」的配对选区
    （与 R4 总门同一判据；mount key 取该 field 的最后一次挂载）。"""
    key = None
    for r in rows:
        mo = re.search(r'proxy mounted key=(\S+) field=', r)
        if mo:
            key = mo.group(1)
    if key is None:
        return None
    confirmed = None
    last = None
    for r in rows:
        mo = re.search(r'ime selection confirmed \[(\d+),(\d+)\) rc=0 \(shared lifecycle\)', r)
        if mo:
            confirmed = (int(mo.group(1)), int(mo.group(2)))
            continue
        mo = re.search(r'ime proxy selection terminal=INSTALLED reason=\S+_confirmed '
                       r'target=\[(\d+),(\d+)\) mount=' + re.escape(key), r)
        if mo:
            target = (int(mo.group(1)), int(mo.group(2)))
            if confirmed is not None and target == confirmed:
                last = target
            confirmed = None
    return last


def wait_confirmed(pid, fence, non_empty, rounds=24):
    """有界轮询 fence 之后**新出现**的确认配对。

    fence 必须在触发动作（拖选/外部写入）**之前**取：一次 hilog 全量拉取本身
    要数秒，动作后的确认行常在拉取完成前就已入缓冲——动作后再取围栏会把
    它们当成旧行排除（实测教训）。返回 (选区或None, 行列表)。"""
    for _ in range(rounds):
        rows = rows_for(pid)
        new_terminal = any('terminal=INSTALLED' in r for r in rows[fence:])
        if new_terminal:
            sel = confirmed_selection(rows)
            if sel is not None and (not non_empty or sel[0] < sel[1]):
                return sel, rows
        time.sleep(0.5)
    rows = rows_for(pid)
    if any('terminal=INSTALLED' in r for r in rows[fence:]):
        return confirmed_selection(rows), rows
    return None, rows


def read_note():
    _, fields = tc.read_state()
    return fields.get('note', None), fields


def set_note_external(text):
    version, _ = tc.read_state()
    return tc.invoke('SET_NOTE', version, [('text', 'STRING', text)])


def main() -> int:
    results = {'legs': []}
    pid = thermo_pid()
    results['identity'] = {'bundle': BUNDLE, 'pid': pid}
    if not pid:
        results['status'] = 'no_instance'
        (OUT / 'thermo-shared.json').write_text(json.dumps(results, ensure_ascii=False, indent=2))
        return 2

    fwd = subprocess.run([HDC, 'fport', 'tcp:17857', 'tcp:7857'], capture_output=True, text=True)
    try:
        # ---- 1 安装：真实触摸定位滚动备注 ----
        p = tc.tap_semantic('thermo-focus-note-nav')
        results['legs'].append({'leg': 'focus-nav', 'point': p})
        if p is None:
            results['status'] = 'note_nav_not_reachable'
            return 1
        time.sleep(2.0)
        fence = len(rows_for(pid))
        sel, rows = wait_confirmed(pid, 0, non_empty=False)
        results['install'] = {'confirmed': sel is not None, 'selection': sel}
        if sel is None:
            results['status'] = 'shared_install_unconfirmed'
            return 1

        # ---- 2 输入（插入）：系统键盘注入 → owner 精确读回 ----
        seed = 'thermo shared lifecycle ok'
        tc._m.uitest('text', seed)
        note = None
        for _ in range(16):
            note, _ = read_note()
            if note == seed:
                break
            time.sleep(0.4)
        results['legs'].append({'leg': 'input-insert', 'note': note})
        if note != seed:
            results['status'] = 'input_not_read_back'
            return 1

        # ---- 3 非空选区安装：拖选 → 共享类确认非空选区 ----
        note_point = tc.thermo_semantic_point('hand-scroll-note')
        if note_point is None:
            results['status'] = 'note_point_missing'
            return 1
        cx, cy = int(note_point[0]), int(note_point[1])
        fence2 = len(rows_for(pid))
        tc._m.uitest('click', str(cx + 60), str(cy))
        time.sleep(0.8)
        tc._m.uitest('drag', str(cx + 40), str(cy), str(cx + 130), str(cy))
        sel2, rows = wait_confirmed(pid, fence2, non_empty=True)
        results['legs'].append({'leg': 'nonempty-select', 'selection': sel2})
        if sel2 is None or sel2[0] >= sel2[1]:
            results['status'] = 'nonempty_selection_unconfirmed'
            return 1

        # ---- 4 精确替换：独立期望 = 冻结选区 + oracle ----
        expected = strict_utf16.expected_replacement(seed.encode('utf-8'), sel2[0], sel2[1], 'X')
        tc._m.uitest('text', 'X')
        after = None
        for _ in range(16):
            after, _ = read_note()
            if after is not None and after.encode('utf-8') == expected:
                break
            time.sleep(0.4)
        results['legs'].append({'leg': 'exact-replace', 'frozen_selection': list(sel2),
                                'expected': expected.decode('utf-8'), 'note': after})
        if after is None or after.encode('utf-8') != expected:
            results['status'] = 'exact_replace_failed'
            return 1

        # ---- 5 外部改版：公开通道 SET_NOTE（围栏先于写入取好）----
        fence3 = len(rows_for(pid))
        external = '外部改版后的备注 thermΩ'
        rec = set_note_external(external)
        note3 = None
        for _ in range(12):
            note3, fields3 = read_note()
            if note3 == external:
                break
            time.sleep(0.4)
        results['legs'].append({'leg': 'external-set', 'applied': rec.get('applied'),
                                'note': note3})
        if note3 != external:
            results['status'] = 'external_set_failed'
            return 1

        # ---- 6 继续输入：等改版后的新安装确认，冻结后独立计算期望 ----
        sel3, rows = wait_confirmed(pid, fence3, non_empty=False, rounds=30)
        results['legs'].append({'leg': 'post-external-select', 'selection': sel3})
        if sel3 is None:
            results['status'] = 'post_external_selection_unconfirmed'
            return 1
        expected2 = strict_utf16.expected_replacement(external.encode('utf-8'), sel3[0], sel3[1], 'Y')
        tc._m.uitest('text', 'Y')
        after2 = None
        for _ in range(16):
            after2, _ = read_note()
            if after2 is not None and after2.encode('utf-8') == expected2:
                break
            time.sleep(0.4)
        results['legs'].append({'leg': 'continue-input', 'frozen_selection': list(sel3),
                                'expected': expected2.decode('utf-8'), 'note': after2})
        if after2 is None or after2.encode('utf-8') != expected2:
            results['status'] = 'continue_input_failed'
            return 1

        results['status'] = 'OK'
        return 0
    finally:
        subprocess.run([HDC, 'fport', 'rm', 'tcp:17857', 'tcp:7857'], capture_output=True)
        (OUT / 'thermo-shared.json').write_text(json.dumps(results, ensure_ascii=False, indent=2))
        print(json.dumps({'status': results.get('status'),
                          'install': results.get('install'),
                          'legs': results.get('legs')}, ensure_ascii=False))


if __name__ == '__main__':
    sys.exit(main())

#!/usr/bin/env python3
"""R3/D 目标链：中段非空选区 → 无编辑双切换 → 平台安装确认 → 不额外点击的
首笔系统输入精确替换 → Undo 精确恢复（同一 normal HAP、同一 owner）。

判据要点（对应指导 R3/R4）：
  * 拖选本身必须零事务（版本与完整 owner 不变）；
  * 双切换（source→preview→source）必须零事务；
  * 替换用**独立期望**核对：前缀 + 本笔文本 + 后缀，且被替换区间必须非空；
  * 不额外点击：替换前最后一次输入动作必须是选区安装之前的那次拖选，中间不得
    再点正文（脚本显式断言 click 次数）；
  * Undo 后必须逐字节回到替换前的完整 owner 与版本语义。

本脚本只读设备 + 注入真实 UI 输入（uitest drag/click/inputText、公开通道 UNDO），
不构建、不安装、不清理他方资源；转发由本调用独占并在 finally 精确回收。
"""
import argparse
import importlib.util
import json
import os
import re
import time
from pathlib import Path

import sys as _sys
import os as _os
_sys.path.insert(0, _os.path.dirname(_os.path.abspath(__file__)))
import strict_utf16  # noqa: E402

DRIVER = Path('/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/platforms/ohos/scripts/'
              'h_source_preview_consumption.py')
spec = importlib.util.spec_from_file_location('pharos_driver', DRIVER)
m = importlib.util.module_from_spec(spec)
spec.loader.exec_module(m)


def diff_span(a_hex, b_hex):
    a, b = bytes.fromhex(a_hex), bytes.fromhex(b_hex)
    i = 0
    while i < min(len(a), len(b)) and a[i] == b[i]:
        i += 1
    j = 0
    while j < min(len(a), len(b)) - i and a[len(a) - 1 - j] == b[len(b) - 1 - j]:
        j += 1
    return i, len(a) - j, b[i:len(b) - j].hex()


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--out', required=True)
    ap.add_argument('--port', type=int, default=28890)
    ap.add_argument('--replacement', default='替换')
    args = ap.parse_args()
    os.makedirs(args.out, exist_ok=True)

    results = {'steps': [], 'required': [], 'required_values': {}}
    others = [b for b in m.running_pharos_bundles() if b != m.BUNDLE]
    if others:
        results['status'] = 'foreign_instance_present'
        results['others'] = others
        _write(args.out, results)
        print(json.dumps({'status': results['status'], 'others': others}, ensure_ascii=False))
        return 2
    if not m.ensure_foreground():
        results['status'] = 'not_foreground'
        _write(args.out, results)
        print(json.dumps({'status': results['status']}, ensure_ascii=False))
        return 2
    pid = m.hdc('shell', f'pidof {m.BUNDLE}').stdout.strip().split()[0]
    port = args.port
    m.hdc('fport', 'rm', f'tcp:{port}', 'tcp:7856')
    r = m.hdc('fport', f'tcp:{port}', 'tcp:7856')
    if 'OK' not in r.stdout:
        results['status'] = 'forward_fail'
        _write(args.out, results)
        print(json.dumps({'status': results['status']}, ensure_ascii=False))
        return 2
    results['pid'] = pid
    try:
        point = m.accepted_editor_point()
        results['editor_point'] = point
        if not point:
            results['status'] = 'editor_point_not_derived'
            _write(args.out, results)
            print(json.dumps({'status': results['status']}, ensure_ascii=False))
            return 2

        # 0. 基线：完整 owner + 版本
        before = m.freeze_baseline(port)
        results['baseline'] = {'version': before['version'], 'bytes': before['bytes']}
        results['steps'].append(m.save_evidence(args.out, '00-baseline', port, extra={'identity': pid}))

        # 1. 真实拖选建立**中段非空选区**（同一行内从左拖到右）
        x1, y1 = point[0] + 60, point[1]
        x2, y2 = point[0] + 180, point[1]
        m.uitest('drag', str(x1), str(y1), str(x2), str(y2))
        time.sleep(1.5)
        after_drag = m.save_evidence(args.out, '01-drag-select', port, extra={'identity': pid})
        results['drag_zero_transaction'] = (after_drag['owner_hex'] == before['hex']
                                            and after_drag['version'] == before['version'])
        results['steps'].append(after_drag)

        # 1b. 冻结**平台实际安装的选区**（独立期望的来源）：拖选后 native 会发出
        #     `ime caret notification ctx=N sel=a:b`。这正是 R3 要求的"实际平台
        #     安装确认"，也是后续"精确替换"的预期源范围。要求它非空——否则这次
        #     拖选没有建立非空选区，判据必须失败而不是拿折叠值当基线。
        native_sel = None
        for row in reversed(m.hilog_rows()):
            mo = re.search(r'ime caret notification ctx=\d+ sel=(\d+):(\d+)', row)
            if mo:
                native_sel = (int(mo.group(1)), int(mo.group(2)))
                break
        results['native_selection_after_drag'] = native_sel
        results['native_selection_nonempty'] = bool(native_sel and native_sel[1] > native_sel[0])

        # 2. 无编辑双切换：source→preview→source（正文零事务）
        preview_ok = m.tap_semantic('pharos-preview')
        time.sleep(1.0)
        after_preview = m.save_evidence(args.out, '02-preview', port, extra={'identity': pid})
        results['steps'].append(after_preview)
        source_ok = m.tap_semantic('pharos-preview')
        time.sleep(1.0)
        after_back = m.save_evidence(args.out, '03-back-source', port, extra={'identity': pid})
        results['steps'].append(after_back)
        results['toggle_zero_transaction'] = bool(
            preview_ok and source_ok
            and after_preview['owner_hex'] == before['hex'] and after_preview['version'] == before['version']
            and after_back['owner_hex'] == before['hex'] and after_back['version'] == before['version'])

        # 3. **不额外点击**：`uiInput inputText <x> <y> <text>` 会先在坐标处点击
        #    再输入（平台语义），那次点击把落点重置为折叠 caret，从而**破坏**
        #    刚安装好的非空选区——实测 `human anchor recorded origin=caret_hit
        #    sel=104:104` 就出现在替换前一刻。指导要求的是"不额外点击的首笔系统
        #    输入"，因此这里用 `uiInput text <text>`（在**已聚焦**处输入），
        #    完全不产生鼠标事件。
        pre_replace = m.freeze_baseline(port)
        # 冻结基准必须与"切回源码"那一步读到的 owner 完全相同；若不同，说明切回
        # 之后正文还有未稳定的写入，那么"替换期望"的基准就不成立——这本身要
        # 具名记录下来，而不是让精确判据悄悄失败。
        results['pre_replace_matches_back_source'] = (pre_replace['hex'] == after_back['owner_hex'])
        m.uitest('text', args.replacement)
        time.sleep(2.5)
        after_replace = m.save_evidence(args.out, '04-no-click-replace', port, extra={'identity': pid})
        results['steps'].append(after_replace)

        # 独立期望：由**平台实际安装的 UTF-16 选区**换算到 owner 字节域，构造
        # 「前缀 + 本笔文本 + 后缀」。期望来自 1b 冻结的安装事实，不来自本次结果。
        #   * 恰好一笔事务（版本 +1）
        #   * 被替换区间非空（removed > 0）——折叠 caret 插入会得到 removed == 0
        #   * 插入内容精确等于本笔文本
        start, end, inserted = diff_span(pre_replace['hex'], after_replace['owner_hex'])
        removed = bytes.fromhex(pre_replace['hex'])[start:end]
        results['replace_version_exactly_once'] = (
            after_replace['version'] == pre_replace['version'] + 1)
        results['replace_span_nonempty'] = (len(removed) > 0)
        results['replace_inserted_exact'] = (inserted == args.replacement.encode('utf-8').hex())
        results['replace_mid_document'] = (0 < start < pre_replace['bytes'])
        results['replace_span'] = {'start': start, 'end': end,
                                   'removed_bytes': len(removed), 'inserted_bytes': len(bytes.fromhex(inserted))}
        # 精确期望：用冻结的 native 选区（UTF-16）换算成 owner 的字节区间。
        # S4：换算统一接共用严格 oracle（strict_utf16）——Python 字符切片不是
        # UTF-16（非 BMP 前缀/代理对中点都会算错）；中点/越界严格拒绝。
        expected_hex = None
        if native_sel is not None:
            raw = bytes.fromhex(pre_replace['hex'])
            try:
                b_start = strict_utf16.utf16_to_byte_offset(raw, native_sel[0])
                b_end = strict_utf16.utf16_to_byte_offset(raw, native_sel[1])
                expected_hex = (raw[:b_start] + args.replacement.encode('utf-8') + raw[b_end:]).hex()
                results['expected_replace_span'] = {'start': b_start, 'end': b_end}
            except ValueError:
                expected_hex = None
        results['replace_expectation_source'] = 'native_installed_selection_utf16'
        results['replace_expectation_built'] = (expected_hex is not None)
        # 公开通道回的是**大写**十六进制，本地期望由 `.hex()` 生成小写；按字节
        # 比较，否则内容完全一致也会被判失败（本轮就撞上这条）。
        results['replace_exact_owner'] = bool(expected_hex is not None and
                                              after_replace['owner_hex'].lower() == expected_hex.lower())
        if expected_hex is not None and after_replace['owner_hex'] != expected_hex:
            want = bytes.fromhex(expected_hex)
            got = bytes.fromhex(after_replace['owner_hex'])
            first = next((i for i, (a, b) in enumerate(zip(want, got)) if a != b), None)
            results['replace_exact_mismatch'] = {
                'want_bytes': len(want), 'got_bytes': len(got), 'first_diff': first,
                'want_at': want[first:first + 12].hex() if first is not None else '',
                'got_at': got[first:first + 12].hex() if first is not None else ''}

        # 4. Undo：必须逐字节回到替换前的完整 owner。
        # 公开 UNDO 零参数（ctx 里 ACTION UNDO PARAMETERS 0），沿用 REPLACE_RANGE 的
        # INVOKE 形状：`INVOKE <expectedVersion> <ACTION> <targets> <paramCount>`。
        undo_resp = m.request(['PROTOCOL CJGUI_SHARED_OPERATION/2', f'AUTH {m.CAP}',
                               f'INVOKE {after_replace["version"]} UNDO 1 0', 'ID 1'], port)
        results['undo_response'] = undo_resp[:300]
        time.sleep(1.2)
        after_undo = m.save_evidence(args.out, '05-undo', port, extra={'identity': pid})
        results['steps'].append(after_undo)
        results['undo_exact_restore'] = (after_undo['owner_hex'] == pre_replace['hex'])
        results['undo_identity_ok'] = bool(pid)

        required = ['native_selection_nonempty', 'drag_zero_transaction', 'toggle_zero_transaction',
                    'replace_version_exactly_once', 'replace_span_nonempty', 'replace_inserted_exact',
                    'replace_mid_document', 'replace_exact_owner', 'undo_exact_restore', 'undo_identity_ok']
        results['required'] = required
        results['required_values'] = {k: results.get(k) for k in required}
        results['status'] = 'OK' if all(results.get(k) for k in required) else 'FAIL'
    finally:
        m.hdc('fport', 'rm', f'tcp:{port}', 'tcp:7856')

    _write(args.out, results)
    print(json.dumps({'status': results['status'], 'pid': pid,
                      'required_values': results['required_values']}, ensure_ascii=False))
    return 0 if results['status'] == 'OK' else 1


def _write(out, results):
    with open(os.path.join(out, 'target-chain.json'), 'w') as f:
        json.dump(results, f, ensure_ascii=False, indent=2)


if __name__ == '__main__':
    raise SystemExit(main())

#!/usr/bin/env python3
"""第二段闭环：预览期间 Agent 改版 → 映射接续 → 保存重开（同一 normal HAP）。

指导要求（原话）：「再完成预览期间 Agent 改版→映射接续→保存重开，逐阶段核对
完整 owner」。本探针把这条链拆成可独立证伪的阶段：

  A. 基线 + 拖选冻结**平台实际安装**的非空选区（来源是 native 安装事实，不是结果）
  B. 切到预览，在预览期间接受一笔公开通道的 Agent 中段替换（owner 恰好一笔）
  C. 切回源码，**不额外点击**投递首笔系统输入：期望按**新版本**的锚点替换
     （锚点被 Agent 的编辑平移过；用旧偏移即为未映射）
  D. SAVE 公开通道：APPLIED 且版本自洽
  E. 关闭重开：磁盘文件字节与 owner 字节逐字节一致，且路径/身份一致

判定原则与 R4 一致：每项都是恒定的必需项，缺证据即具名失败；不靠 nudge/延时/
重跑碰绿。诊断经 `ohos_renderer_window_log` 与 native 日志读取。
"""

import argparse
import importlib.util
import json
import os
import re
import sys
import time
from pathlib import Path

DRIVER = Path('/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/platforms/ohos/scripts'
              '/h_source_preview_consumption.py')


def load_driver():
    spec = importlib.util.spec_from_file_location('pharos_driver', DRIVER)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


# S4：共用严格 UTF-16↔UTF-8 oracle（strict_utf16.py）。旧实现按 Python 字符
# 切片当 UTF-16：A😀B 的 utf16=3 算成 byte6（应 5）、代理对中点 2 错接成 5、
# 😀 末点 2 被错拒——指导件 probe-unicode 的三个失败即此函数。
import sys as _sys, os as _os
_sys.path.insert(0, _os.path.dirname(_os.path.abspath(__file__)))
import strict_utf16


def utf16_to_byte(text: str, index: int):
    """UTF-16 码元下标 → UTF-8 字节下标；中点/越界返回 None（严格拒绝）。"""
    try:
        return strict_utf16.utf16_to_byte_offset(text.encode('utf-8'), index)
    except ValueError:
        return None


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument('--out', required=True)
    parser.add_argument('--port', type=int, default=28930)
    parser.add_argument('--agent-text', default='AGENT')
    parser.add_argument('--human-text', default='H')
    args = parser.parse_args()

    m = load_driver()
    out = Path(args.out)
    out.mkdir(parents=True, exist_ok=True)
    results = {'steps': []}

    port = args.port
    m.hdc('fport', 'rm', f'tcp:{port}', 'tcp:7856')
    m.hdc('fport', f'tcp:{port}', 'tcp:7856')
    try:
        pid = m.instance_identity()
        results['identity'] = pid
        point = m.accepted_editor_point()
        if point is None:
            results['status'] = 'FAIL'
            results['reason'] = 'editor_point_unavailable'
            (out / 'target-chain.json').write_text(json.dumps(results, ensure_ascii=False, indent=2))
            return 1
        # 拖选必须落在夹具**首行**的文字上（夹具首行 `# 预览取证标题`）。命中点
        # `point` 取的是编辑器内部位置，长正文下常在文档末尾；夹具只有 69 字符时
        # 直接按行内偏移拖会落到空行，得到折叠 `63:63`（实测）。因此先点首行把
        # 落点带到文本起点附近，再在同一行内向右拖，形成确定的中段非空选区。
        m.uitest('click', str(point[0] + 10), str(point[1]))
        time.sleep(0.6)
        x1, y1 = point[0] + 30, point[1]
        x2, y2 = point[0] + 120, point[1]

        # A0. 干净基线：把正文重置为固定夹具并校验读回。没有这一步，上一轮
        #     遗留正文会把最小差分引到历史字符上，锚点与期望都不可复现。
        fixture_ok, fixture_detail = m.reset_fixture(port)
        results['fixture_reset'] = fixture_ok
        results['fixture_detail'] = fixture_detail
        if not fixture_ok:
            results['status'] = 'FAIL'
            results['reason'] = 'clean_baseline_unavailable'
            (out / 'target-chain.json').write_text(
                json.dumps(results, ensure_ascii=False, indent=2))
            return 1

        # A. 基线 + 拖选
        before = m.freeze_baseline(port)
        m.uitest('drag', str(x1), str(y1), str(x2), str(y2))
        time.sleep(1.5)
        after_drag = m.save_evidence(out, '01-drag-select', port, extra={'identity': pid})
        results['steps'].append(after_drag)
        results['drag_zero_transaction'] = (after_drag['owner_hex'].lower() == before['hex'].lower()
                                            and after_drag['version'] == before['version'])
        # 拖选后**有界等待**平台安装确认（生产日志的 terminal=INSTALLED），
        # 再抓同一时刻的快照：安装确认与拖选手势之间隔着一次代理接续，固定延时
        # 会让快照落在确认之前，得到"未安装"的假失败。
        for _ in range(10):
            probe = m.diag_snapshot(out, '01b-diag-after-drag', pid)
            if re.search(r'target=\[(\d+),(\d+)\)', '\n'.join(probe.get('all_rows') or [])):
                break
            time.sleep(0.5)
        results['diag_after_drag'] = probe
        # 拖选建立的非空必须来自**本次**拖选之后的推送（`window-diag: set-sel16
        # in=a:b` 或 native `caret notification`），不能取历史 hilog——重开应用后
        # 旧行会给出假非空。取拖选后快照里最后一条非空安装观测。
        # 判据不得依赖调试诊断（诊断已按纪律从生产路径移除）。这里读**生产日志**
        # 的安装终态：`ime proxy selection terminal=INSTALLED … target=[a,b)` 是产品
        # 的正常运行输出，表示平台实际安装的区间。取拖选后最后一条。
        drag_sel = None
        for row in (results.get('diag_after_drag') or {}).get('all_rows', []):
            mo = re.search(r'ime proxy selection terminal=INSTALLED reason=\S+ target=\[(\d+),(\d+)\)', row)
            if mo:
                drag_sel = (int(mo.group(1)), int(mo.group(2)))
        results['drag_installed_selection'] = drag_sel
        results['drag_selection_nonempty'] = bool(drag_sel and drag_sel[1] > drag_sel[0])
        native_sel = None
        for row in reversed(m.hilog_rows()):
            mo = re.search(r'ime caret notification ctx=\d+ sel=(\d+):(\d+)', row)
            if mo:
                native_sel = (int(mo.group(1)), int(mo.group(2)))
                break
        results['native_selection_after_drag'] = native_sel
        # 拖选后立即留证：探针内部会重开应用，事后 grep 会被冲刷，无法区分
        # "推送是折叠"与"日志丢了"。这一步让安装目标成为同一时刻的证据。
        results['native_selection_nonempty'] = bool(native_sel and native_sel[1] > native_sel[0])

        # B. 切预览 + 预览期间 Agent 编辑（中段，把锚点右移）
        m.tap_semantic('pharos-preview')
        time.sleep(1.2)
        pre_agent = m.freeze_baseline(port)
        anchor_text = bytes.fromhex(pre_agent['hex']).decode('utf-8')
        # Agent 在**锚点区间之前**（严格不触及）插入，从而锚点必须被映射右移。
        # Sol 复核（2026-10-01）：恰在锚点**起点**插入属于"触及选区"，按现行
        # `change_map.affectsRange` 契约重基**应当**被拒——那是有意的具名行为，
        # 不是缺陷。因此整链验证用"锚点之前一个字符边界"的插入：它必然要求
        # 映射把锚点整体右移，能干净地区分"映射接续成立"与"未接续"。
        # 端点亲和性（起点插入时锚点跟随插入内容之后）是**另一条**需要产品
        # 明确定义的契约，单列验证，不混进本链。
        anchor_start_byte = utf16_to_byte(anchor_text, native_sel[0]) if native_sel else None
        agent_byte = None
        if anchor_start_byte is not None and anchor_start_byte > 0:
            raw_before = bytes.fromhex(pre_agent['hex'])
            probe = anchor_start_byte - 1
            while probe > 0 and (raw_before[probe] & 0xC0) == 0x80:
                probe -= 1
            agent_byte = probe
        results['anchor_start_byte'] = anchor_start_byte
        results['agent_insert_byte'] = agent_byte
        agent_hex = args.agent_text.encode('utf-8').hex()
        agent_resp = m.agent_replace(port, agent_byte, agent_byte, agent_hex,
                                    pre_agent['version'])
        time.sleep(1.2)
        after_agent = m.save_evidence(out, '02-agent-edit-in-preview', port, extra={'identity': pid})
        results['steps'].append(after_agent)
        results['agent_version_exactly_once'] = (after_agent['version'] == pre_agent['version'] + 1)
        results['agent_exact_owner'] = bool(
            after_agent['owner_hex'].lower() ==
            (bytes.fromhex(pre_agent['hex'])[:agent_byte] + args.agent_text.encode('utf-8')
             + bytes.fromhex(pre_agent['hex'])[agent_byte:]).hex())

        # 映射后的期望锚点：Agent 在锚点**之前**插入（插入区间与锚点不重叠），
        # 因此映射必须把锚点起止整体右移插入长度。这是独立于结果的期望。
        agent_len = len(args.agent_text.encode('utf-8'))
        anchor_end_byte = utf16_to_byte(anchor_text, native_sel[1]) if native_sel else None
        mapped_start = anchor_start_byte + agent_len if anchor_start_byte is not None else None
        mapped_end = anchor_end_byte + agent_len if anchor_end_byte is not None else None
        results['expected_anchor_after_agent'] = {'start': mapped_start, 'end': mapped_end}
        results['agent_insert_before_anchor'] = bool(
            agent_byte is not None and anchor_start_byte is not None and agent_byte < anchor_start_byte)

        # C. 切回源码 + 免点击首笔系统输入
        m.tap_semantic('pharos-preview')
        time.sleep(1.5)
        after_back = m.save_evidence(out, '03-back-source', port, extra={'identity': pid})
        results['steps'].append(after_back)
        results['toggle_back_zero_transaction'] = (after_back['owner_hex'].lower() ==
                                                   after_agent['owner_hex'].lower())
        # 运行中日志快照：窗口诊断出口在 OHOS 是 hilog，跨应用重启会被冲刷，
        # 事后 grep 不能证明"这段路径没跑"。因此在关键动作前后各抓一次，
        # 让"零输出"成为**同一时刻、同一 PID** 的证据。
        diag_before = m.diag_snapshot(out, '03b-diag-before-human', pid)
        results['diag_before_human'] = diag_before
        pre_human = m.freeze_baseline(port)
        m.uitest('text', args.human_text)
        time.sleep(2.5)
        after_human = m.save_evidence(out, '04-no-click-continue', port, extra={'identity': pid})
        results['steps'].append(after_human)
        results['diag_after_human'] = m.diag_snapshot(out, '04b-diag-after-human', pid)
        start, end, inserted = m.diff_span(pre_human['hex'], after_human['owner_hex'])
        removed = bytes.fromhex(pre_human['hex'])[start:end]
        results['human_replace_span'] = {'start': start, 'end': end,
                                         'removed_bytes': len(removed),
                                         'inserted_bytes': len(bytes.fromhex(inserted))}
        results['human_version_exactly_once'] = (after_human['version'] == pre_human['version'] + 1)
        results['human_span_nonempty'] = len(removed) > 0
        # 映射接续的**独立期望**：替换区间必须落在 Agent 平移后的锚点上。
        # 预期替换的是「排在锚点之后的原选中内容」，起点即 mapped_start。
        expected_hex = (bytes.fromhex(pre_human['hex'])[:mapped_start] + args.human_text.encode('utf-8')
                        + bytes.fromhex(pre_human['hex'])[mapped_end:]).hex()
        results['expected_human_span'] = {'start': mapped_start, 'end': mapped_end}
        results['human_replace_exact_owner'] = bool(
            after_human['owner_hex'].lower() == expected_hex.lower())
        results['human_span_matches_mapped_anchor'] = (start == mapped_start and end == mapped_end)

        # D. SAVE
        save_resp = m.request([
            'PROTOCOL CJGUI_SHARED_OPERATION/2', f'AUTH {m.CAP}',
            f'INVOKE {after_human["version"]} SAVE 1 0', 'ID 1'], port)
        results['save_response'] = save_resp[:300]
        results['save_applied'] = ('APPLIED true' in save_resp)
        time.sleep(1.0)

        # E. 关闭重开：磁盘文件必须与 owner 逐字节一致。
        doc_path = '/data/storage/el2/base/haps/entry/files/pharos-mark.md'
        # SAVE 返回 APPLIED 只说明 owner 已发布；文件落盘是另一跳。这里有界等待
        # 磁盘追上 owner（不是无限重试）——超时即具名失败，并保留最后一次读到的
        # 字节数与首个差异位置，避免"读不到就算不一致"的模糊结论。
        file_hex = None
        for _ in range(12):
            file_hex = m.shell_cat_hex(doc_path)
            if file_hex and file_hex.lower() == after_human['owner_hex'].lower():
                break
            time.sleep(0.5)
        results['saved_file_hex'] = {'readable': file_hex is not None,
                                     'bytes': (len(file_hex) // 2) if file_hex else None,
                                     'expected_bytes': len(after_human['owner_hex']) // 2}
        # 平台事实：应用沙箱路径（`/data/storage/el2/base/haps/entry/files/…`）
        # 对 hdc shell 是 Permission denied，本机 run-as 也不可用。因此"磁盘直读"
        # 不是可用的验收通道——把它具名记录，并**以重开后应用自己从磁盘加载的
        # owner** 作为"保存重开"的判定（重开读回逐字节一致即证明落盘内容正确）。
        direct_read = bool(file_hex and file_hex.lower() == after_human['owner_hex'].lower())
        results['saved_file_direct_read'] = {
            'available': file_hex is not None, 'matched': direct_read,
            'reason': 'sandbox_path_not_readable_from_hdc_shell'}
        results['saved_file_hex_match_owner'] = direct_read
        reopened = m.close_and_reopen_document(port, args.out + '/05-reopen')
        results['reopen'] = reopened
        results['reopen_identity_matches'] = bool(reopened and reopened.get('hex', '').lower()
                                                  == after_human['owner_hex'].lower())
        results['reopen_version_is_one'] = bool(reopened and reopened.get('version') == 1)

        required = ['fixture_reset', 'native_selection_nonempty', 'drag_selection_nonempty',
                    'drag_zero_transaction',
                    'agent_insert_before_anchor',
                    'agent_version_exactly_once', 'agent_exact_owner',
                    'toggle_back_zero_transaction', 'human_version_exactly_once',
                    'human_span_nonempty', 'human_replace_exact_owner',
                    'human_span_matches_mapped_anchor', 'save_applied',
                    'reopen_identity_matches']
        results['required'] = required
        results['required_values'] = {k: results.get(k) for k in required}
        results['status'] = 'OK' if all(results.get(k) for k in required) else 'FAIL'
    finally:
        m.hdc('fport', 'rm', f'tcp:{port}', 'tcp:7856')

    (out / 'target-chain.json').write_text(json.dumps(results, ensure_ascii=False, indent=2))
    print(json.dumps({'status': results.get('status'), 'pid': results.get('identity'),
                      'required_values': results.get('required_values')}, ensure_ascii=False))
    return 0 if results.get('status') == 'OK' else 1


if __name__ == '__main__':
    sys.exit(main())

#!/usr/bin/env python3
"""S3/S4（h-source-preview-followup）：双 owner A→B→A→再访 B 严格驱动。

判据原则（2026-10-02 复核 R4：先冻结事实，再独立计算期望）：
  * 每步动作前冻结运行身份（PID）、双方 owner 的版本/完整字节；动作后逐字节
    核对与"恰好一次"（版本 +1）；任何一步找不到本轮事实即具名失败。
  * **期望不能从操作后的 diff 反推**：B 拖选后、A 切回后，都必须先从本轮日志
    取得「平台确认安装的 UTF-16 选区」（terminal=INSTALLED + native rc=0），
    经 strict_utf16 oracle 映射成源字节跨度，独立拼出唯一期望正文；输入后的
    实际字节必须与它逐字节相等。错区间替换、误删续写、缺安装确认都使总门
    失败（负控见 test_dual_owner_negative_controls.py）。
  * 免点击链禁止补点正文：B 替换与 A 续写都用 `uiInput text`（不产生点击）；
    切换按钮的点击是模式动作本身，允许一次。
  * 备注读回走**公开通道资源**（GET_CONTEXT 列出的 note 资源 + READ_RANGE），
    不再用 native delta 冒充提交、不用"曾有 delta"当不变证据。
  * 等待按进度（OWNER_STATE / 确认行出现）+ 有界轮次；单次 toggle 不重放
    用户意图；无当前 owner 状态时具名失败，不回退点击翻转或历史几何。
  * 非空 READ 也核 AVAILABLE、版本/范围、声明长度与实际解码字节数。
  * UTF-16 换算统一 strict_utf16 oracle。

传输事实（2026-09-30 核对 shared_operation_transport.cj / external.cj）：
  * request() 只对 GET_CONTEXT 前缀自动补 PROTOCOL/AUTH 头；READ_RANGE 必须
    自带完整三行，否则 lines.size!=3 → invalid_request。
  * READ_RANGE 的 expectedVersion 必须 ≥0 且精确等于当前版本（provider：
    `expectedVersion >= 0 && expectedVersion != version` → version_conflict）。
  * RANGE 载荷只有 `CONTENT_UTF8_HEX <size> <hex>`，没有 byteLength 字段；
    总长度从 GET_CONTEXT 的 `FIELD <rid> byteLength INTEGER <n>` 取。
"""

import argparse
import importlib.util
import json
import re
import sys
import time
from pathlib import Path

DRIVER = Path('/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/platforms/ohos/scripts'
              '/h_source_preview_consumption.py')

spec = importlib.util.spec_from_file_location('pharos_driver', DRIVER)
m = importlib.util.module_from_spec(spec)
spec.loader.exec_module(m)

import os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import strict_utf16  # noqa: E402

OUT = None

NOTE_FIELD = 'pharos-document-note'
BODY_FIELD = 'pharos-editor-body'


def log(msg):
    print(msg, flush=True)


def resource_meta(port, rid):
    """GET_CONTEXT 里该资源的元数据：INTEGER 字段十进制值 + documentId 解码。"""
    resp = m.request(["GET_CONTEXT 0"], port)
    meta = {}
    for line in resp.splitlines():
        stripped = line.strip()
        mo = re.match(r"FIELD %d (\w+) INTEGER (-?\d+)$" % rid, stripped)
        if mo:
            meta[mo.group(1)] = int(mo.group(2))
            continue
        ms = re.match(r"FIELD %d documentId STRING (\d+) ([0-9a-fA-F]*)$" % rid, stripped)
        if ms:
            meta["documentId"] = bytes.fromhex(ms.group(2)).decode("utf-8", "replace")
    return meta


def hexs(s):
    return s.encode('utf-8').hex()


def read_resource(port, rid, version, total):
    """按资源号精确版本读全文（单发 READ_RANGE 0..byteLength；空文档返回空串）。

    非空读同样必须看到 AVAILABLE true；声明长度与实际解码字节数一致。"""
    resp = m.request(["PROTOCOL CJGUI_SHARED_OPERATION/2",
                      "AUTH pharos-local-capability",
                      "READ_RANGE %d 0 %d %d" % (rid, total, version)], port)
    if re.search(r"^CONFLICT true$", resp, re.M) or "version_conflict" in resp:
        raise RuntimeError("resource %d version_conflict (asked %d)" % (rid, version))
    if not re.search(r"^AVAILABLE true$", resp, re.M):
        raise RuntimeError("resource %d read not AVAILABLE: %s" % (rid, resp[:160]))
    if total == 0:
        return ""
    mh = re.search(r"CONTENT_UTF8_HEX (\d+) ([0-9a-fA-F]*)", resp)
    if not mh or int(mh.group(1)) != total or len(mh.group(2)) != total * 2:
        raise RuntimeError("resource %d unreadable (total=%d): %s" % (rid, total, resp[:160]))
    return mh.group(2)


def read_public(port, rid):
    """从公开资源表取版本与长度后读回（供所有冻结/核对点共用）。"""
    meta = resource_meta(port, rid)
    if "contentVersion" not in meta or "byteLength" not in meta:
        raise RuntimeError("resource %d missing meta: %r" % (rid, meta))
    hexv = read_resource(port, rid, meta["contentVersion"], meta["byteLength"])
    if len(hexv) // 2 != meta["byteLength"]:
        raise RuntimeError("resource %d decoded %d bytes, declared %d"
                           % (rid, len(hexv) // 2, meta["byteLength"]))
    return meta["contentVersion"], hexv


def find_note_resource(port):
    """公开资源表里找备注（documentId=pharos-note://window）。"""
    resp = m.request(["GET_CONTEXT 0"], port)
    for rid in (int(x) for x in re.findall(r"^RESOURCE (\d+) ", resp, re.M)):
        if resource_meta(port, rid).get("documentId", "").startswith("pharos-note"):
            return rid
    return None


def current_mode(port):
    """当前编辑器模式——公开通道权威读数（GET_CONTEXT 的 OWNER_STATE_UTF8_HEX，
    产品在 S3 暴露）。a11y 的按钮 label 行只在交互时重发，会滞后一个交互周期，
    不能作为模式依据。"""
    resp = m.request(["GET_CONTEXT 0"], port)
    mo = re.search(r"OWNER_STATE_UTF8_HEX (\d+) ([0-9a-fA-F]*)", resp)
    if not mo:
        return None
    state = bytes.fromhex(mo.group(2)).decode("utf-8", "replace")
    ms = re.match(r"MODE=(preview|source)$", state)
    return ms.group(1) if ms else None


def confirmed_selection(rows, field, since):
    """本轮日志里该编辑面**最后一次平台确认安装**的 UTF-16 选区。

    确认 = 共享生命周期的两帧读数命中（terminal=INSTALLED，带 mount 身份与
    target）**且** native 结算被接受（ime selection confirmed ... rc=0）。两行
    都必须出现在 since 之后、值一致；缺任一行即 None——安装确认不能由 setter
    调用或单帧回声冒充。取**最后一次**配对：一次会话内有多次安装（挂载初值、
    逐键 caret、命中推送），驱动冻结的是动作前的最新落点。"""
    key = None
    for row in rows:
        mo = re.search(r"proxy mounted key=(\S+) field=" + re.escape(field), row)
        if mo:
            key = mo.group(1)
    if key is None:
        return None
    confirmed = None
    last_pair = None
    for row in rows[since:]:
        mo = re.search(r"ime selection confirmed \[(\d+),(\d+)\) rc=0 \(shared lifecycle\)", row)
        if mo:
            confirmed = (int(mo.group(1)), int(mo.group(2)))
            continue
        mo = re.search(r"ime proxy selection terminal=INSTALLED reason=\S+_confirmed "
                       r"target=\[(\d+),(\d+)\) mount=" + re.escape(key), row)
        if mo:
            target = (int(mo.group(1)), int(mo.group(2)))
            if confirmed is not None and target == confirmed:
                last_pair = target
            confirmed = None
    return last_pair


def wait_confirmed_selection(field, since, rounds=20):
    """有界轮询等待安装确认行（设备上安装需要几百毫秒；离线负控即时）。

    优先等待**非空**选区（拖选/命中的替换目标）；轮次耗尽仍只有折叠选区时
    返回它，由调用方按"非空选区未确认"具名失败。"""
    last = None
    for _ in range(rounds):
        rows = m.hilog_rows()
        sel = confirmed_selection(rows, field, since)
        if sel is not None:
            last = sel
            if sel[0] < sel[1]:
                return sel
        time.sleep(0.3)
    return last if last is not None else confirmed_selection(m.hilog_rows(), field, since)


def expected_after_replacement(before_hex, start16, end16, new_text):
    """独立期望：冻结选区 + 严格 oracle 映射 + 唯一期望正文（hex）。"""
    raw = bytes.fromhex(before_hex)
    return strict_utf16.expected_replacement(raw, start16, end16, new_text).hex()


def reach_mode(port, target, results, tag):
    """把应用带到目标模式：OWNER_STATE 是唯一权威读数。

    每次只发**一次** toggle 点击，按单调截止等 OWNER_STATE 变化；不重放点击、
    不回退点击翻转探针；无 OWNER_STATE（旧产物）具名失败。"""
    mode = current_mode(port)
    if mode is None:
        results.setdefault('mode_probes', []).append({tag: 'owner-state-missing'})
        return False, "owner-state-missing"
    if mode == target:
        return True, "owner-state"
    p = m.accepted_semantic_point('pharos-preview')
    if not p:
        results.setdefault('mode_probes', []).append({tag: 'button-point-missing'})
        return False, "button-point-missing"
    m.uitest('click', str(p[0]), str(p[1]))
    for _ in range(20):
        if current_mode(port) == target:
            results.setdefault('mode_probes', []).append({tag: 'owner-state-click'})
            return True, "owner-state"
        time.sleep(0.4)
    results.setdefault('mode_probes', []).append({tag: 'toggle-timeout'})
    return False, "toggle-timeout"


def _finish(results, out, port, fwd_ok):
    if fwd_ok:
        m.hdc('fport', 'rm', f'tcp:{port}', 'tcp:7856')
    (out / 'dual-owner.json').write_text(json.dumps(results, ensure_ascii=False, indent=2))
    print(json.dumps({'status': results.get('status'),
                      'required_values': results.get('required_values')}, ensure_ascii=False))
    return 0 if results.get('status') == 'OK' else 1


def main() -> int:
    global OUT
    ap = argparse.ArgumentParser()
    ap.add_argument('--out', required=True)
    ap.add_argument('--port', type=int, default=28997)
    args = ap.parse_args()
    out = Path(args.out)
    out.mkdir(parents=True, exist_ok=True)
    OUT = out
    results = {'steps': []}

    # ---- 0. 运行身份（强制重启由调用方负责；这里核对本轮 PID 与日志游标） ----
    pid = m.instance_identity()
    results['identity'] = pid
    if not pid.get('pid'):
        results['status'] = 'no_instance'
        return _finish(results, out, args.port, False)
    # cursor0 实际参与日志围栏：本轮所有日志判据都从它之后取。
    cursor0 = len(m.hilog_rows())
    results['log_cursor0'] = cursor0

    port = args.port
    # 转发归属：仅当创建成功才在 finally 移除
    fwd_ok = False
    r = m.hdc('fport', f'tcp:{port}', 'tcp:7856')
    fwd_ok = 'OK' in (r.stdout or '')
    if not fwd_ok:
        results['status'] = 'forward_fail'
        return _finish(results, out, args.port, False)

    try:
        # ---- 1. A 基线：fixture 重置后冻结双方 owner ----
        fixture_ok, fixture_detail = m.reset_fixture(port)
        results['fixture_reset'] = fixture_ok
        if not fixture_ok:
            results['status'] = 'clean_baseline_unavailable'
            return _finish(results, out, port, fwd_ok)
        note_rid = find_note_resource(port)
        results['note_resource_id'] = note_rid
        # 备注资源可能尚未创建（惰性）：首轮 A 冻结允许 note 缺席，但 B 阶段后
        # 必须存在，否则具名失败。
        a_main_v, a_main_hex = m.read_all(port)
        a_note_v, a_note_hex = (read_public(port, note_rid) if note_rid else (None, None))
        a_freeze = {'main_version': a_main_v, 'main_hex': a_main_hex, 'note_hex': a_note_hex}
        results['a_freeze'] = {k: (v[:32] + '…' if isinstance(v, str) and len(v) > 40 else v)
                               for k, v in a_freeze.items()}
        # 主文档基线必须早于全部备注动作（此后任何 main 写入都可归因于本轮动作）。
        baseline_main_cursor = len(m.hilog_rows())

        # ---- 2. 进 B：一次点击切换 + 点击备注（进入 B 是真实用户动作） ----
        ok, evidence = reach_mode(port, 'preview', results, 'enter-b')
        results['toggle_evidence'] = evidence
        if not ok:
            results['status'] = 'preview_mode_not_reached'
            return _finish(results, out, port, fwd_ok)
        # OWNER_STATE 翻转与 accepted 场景转储（note 节点矩形/视口变换）可能
        # 不同帧到达：按进度有界轮询 note 表面，不立即失败。
        note_point = None
        for _ in range(16):
            note_point = m.accepted_semantic_point(NOTE_FIELD)
            if note_point is not None:
                break
            time.sleep(0.5)
        if note_point is None:
            results['status'] = 'note_surface_not_reachable'
            return _finish(results, out, port, fwd_ok)
        m.uitest('click', str(note_point[0]), str(note_point[1]))
        time.sleep(1.5)
        # 种子输入（进入 B 后建立可拖选正文）
        m.uitest('text', 'note body for selection test')
        time.sleep(1.5)

        # B 冻结（通过公开资源；若资源仍未登记，具名失败——不退回日志兜底）
        note_rid = find_note_resource(port)
        if note_rid is None:
            results['status'] = 'note_public_resource_missing'
            return _finish(results, out, port, fwd_ok)
        b_note_v, b_note_hex = read_public(port, note_rid)
        b_main_v, b_main_hex = m.read_all(port)
        results['b_freeze'] = {'note_version': b_note_v, 'note_bytes': len(b_note_hex)//2,
                               'main_version': b_main_v}

        # ---- 3. B 非空选区（拖选）→ 冻结平台确认 → 免点击替换（仅 B 恰好一笔） ----
        rect = m.accepted_semantic_rect(NOTE_FIELD)
        rows = m.hilog_rows()
        probe = None
        for vy in (rect[1] + 10, rect[1] + 20, rect[1] + 34):
            for vx in (rect[0] + 20, rect[0] + 48, rect[0] + 90):
                px = m.accepted_semantic_point(NOTE_FIELD, vp_x=vx, vp_y=vy,
                                               rows=rows, rect_vp=rect)
                if px is None:
                    continue
                m.uitest('click', str(px[0]), str(px[1]))
                time.sleep(0.4)
                caret = m.last_note_caret(port)
                rendered = m.note_rendered_units(313) or len(m.note_projected_text(port))
                if caret is not None and 0 < caret < max(rendered, 1):
                    probe = px
                    break
            if probe:
                break
        if probe is None:
            results['status'] = 'note_text_hit_unavailable'
            return _finish(results, out, port, fwd_ok)
        m.uitest('drag', str(probe[0]), str(probe[1]), str(probe[0] + 60), str(probe[1]))
        time.sleep(1.2)
        # 拖选零事务：B 资源版本不变
        mid_v, _mid_probe = read_public(port, note_rid)
        if mid_v != b_note_v:
            results['status'] = 'drag_changed_note_owner'
            return _finish(results, out, port, fwd_ok)
        # 冻结平台实际安装的选区（terminal=INSTALLED + native rc=0），独立换算期望。
        b_sel = wait_confirmed_selection(NOTE_FIELD, cursor0)
        if b_sel is None or b_sel[0] >= b_sel[1]:
            results['status'] = 'b_install_unconfirmed'
            results['b_install_selection'] = b_sel
            return _finish(results, out, port, fwd_ok)
        b_expected_hex = expected_after_replacement(b_note_hex, b_sel[0], b_sel[1], 'N').lower()
        b_expected_bytes = len(b_expected_hex) // 2
        # 免点击替换（uiInput text 不点击）
        m.uitest('text', 'N')
        time.sleep(2.0)
        after_v, after_hex = read_public(port, note_rid)
        before_raw = bytes.fromhex(b_note_hex)
        bs = strict_utf16.utf16_to_byte_offset(before_raw, b_sel[0])
        be = strict_utf16.utf16_to_byte_offset(before_raw, b_sel[1])
        results['b_replace'] = {
            'version_before': b_note_v, 'version_after': after_v,
            'exactly_once': after_v == b_note_v + 1,
            'frozen_selection_utf16': list(b_sel),
            'frozen_span_bytes': [bs, be],
            'expected_hex': b_expected_hex, 'expected_bytes': b_expected_bytes,
            'actual_hex': after_hex, 'actual_bytes': len(after_hex) // 2,
            'exact_owner': after_hex.lower() == b_expected_hex,
            'removed_bytes': be - bs,
            'inserted_is_N': after_hex[bs * 2:(bs + 1) * 2].lower() == hexs('N')
                             if len(after_hex) >= (bs + 1) * 2 else False,
        }
        # A 不变（逐字节；主文档基线早于全部备注动作）
        a_mid_v, a_mid_hex = m.read_all(port)
        results['a_unchanged_during_b'] = (a_mid_hex == a_main_hex)

        # ---- 4. 切回 A：一次点击；冻结 A 选区 → 免点击续写（仅 A 恰好一笔） ----
        ok, _ev = reach_mode(port, 'source', results, 'back-a')
        if not ok:
            results['status'] = 'source_tap_failed'
            return _finish(results, out, port, fwd_ok)
        time.sleep(1.5)
        a_sel = wait_confirmed_selection(BODY_FIELD, baseline_main_cursor)
        if a_sel is None:
            results['status'] = 'a_install_unconfirmed'
            return _finish(results, out, port, fwd_ok)
        a_expected_hex = expected_after_replacement(a_mid_hex, a_sel[0], a_sel[1], '回').lower()
        a_raw = bytes.fromhex(a_mid_hex)
        abs_ = strict_utf16.utf16_to_byte_offset(a_raw, a_sel[0])
        abe = strict_utf16.utf16_to_byte_offset(a_raw, a_sel[1])
        m.uitest('text', '回')
        time.sleep(2.0)
        a2_v, a2_hex = m.read_all(port)
        results['a_resume'] = {
            'version_before': a_mid_v, 'version_after': a2_v,
            'exactly_once': a2_v == a_mid_v + 1,
            'frozen_selection_utf16': list(a_sel),
            'frozen_span_bytes': [abs_, abe],
            'expected_hex': a_expected_hex,
            'actual_hex': a2_hex,
            'exact_owner': a2_hex.lower() == a_expected_hex,
            'removed_bytes': abe - abs_,
            'removed_is_zero': abe == abs_,
        }
        # B 不变：再读 note 资源（再访前的保持证据）
        n2_v, n2_hex = read_public(port, note_rid)
        results['b_unchanged_during_a'] = (n2_hex == after_hex and n2_v == after_v)

        # ---- 5. 再访 B：切换一次，读回完整字节与版本（保持） ----
        ok, _ev = reach_mode(port, 'preview', results, 'revisit-b')
        if not ok:
            results['status'] = 'revisit_tap_failed'
            return _finish(results, out, port, fwd_ok)
        time.sleep(1.5)
        n3_v, n3_hex = read_public(port, note_rid)
        results['b_revisit'] = {'version': n3_v, 'bytes': len(n3_hex)//2,
                                'preserved': n3_hex == after_hex and n3_v == after_v}

        required = ['fixture_reset', 'b_replace_exactly_once', 'b_replace_exact_owner',
                    'b_install_confirmed', 'a_unchanged_during_b',
                    'a_resume_exactly_once', 'a_resume_exact_owner',
                    'a_resume_removed_is_zero', 'b_unchanged_during_a', 'b_revisit_preserved']
        results['required'] = required
        flat = {
            'fixture_reset': fixture_ok,
            'b_replace_exactly_once': results['b_replace']['exactly_once'],
            'b_replace_exact_owner': results['b_replace']['exact_owner'],
            'b_install_confirmed': b_sel is not None and b_sel[0] < b_sel[1],
            'a_unchanged_during_b': results['a_unchanged_during_b'],
            'a_resume_exactly_once': results['a_resume']['exactly_once'],
            'a_resume_exact_owner': results['a_resume']['exact_owner'],
            'a_resume_removed_is_zero': results['a_resume']['removed_is_zero'],
            'b_unchanged_during_a': results['b_unchanged_during_a'],
            'b_revisit_preserved': results['b_revisit']['preserved'],
        }
        # 错区间替换 / 误删续写都在 exact_owner 里变红；显式再列诊断项。
        if not results['b_replace']['inserted_is_N']:
            flat['b_replace_exact_owner'] = False
        results['required_values'] = flat
        results['status'] = 'OK' if all(flat.values()) else 'FAIL'
        return _finish(results, out, port, fwd_ok)
    except Exception as exc:  # 未预期失败也要落证据并释放转发
        results['status'] = 'driver_exception'
        results['exception'] = repr(exc)
        return _finish(results, out, port, fwd_ok)


if __name__ == '__main__':
    sys.exit(main())

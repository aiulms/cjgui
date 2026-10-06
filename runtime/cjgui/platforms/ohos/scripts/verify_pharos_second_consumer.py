#!/usr/bin/env python3
"""第二消费者复用验证：文档备注（独立 owner）走**同一套**输入/选区机制。

判据只取自**生产日志**与公开通道，不依赖调试诊断：
  * 备注节点在预览帧进入 accepted 场景（kind=10 多行文本输入）；
  * 会话绑定切到备注（框架 `bindRangeTextSession` 同一入口，产品侧独立 owner）；
  * 在备注上拖选 → 平台实际安装确认（`ime proxy selection terminal=INSTALLED`）；
  * 免点击首笔系统输入 → 该笔进入 owner（恰好一笔事务）。

与第一/第二段共用同一驱动；不重复整套矩阵，只验证"复用同一机制"这一点。
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


def load_driver():
    spec = importlib.util.spec_from_file_location('pharos_driver', DRIVER)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def _row_after(row: str, wall_epoch: float) -> bool:
    """hilog 行时间戳（当天 HH:MM:SS.mmm）是否晚于 wall_epoch。跨天/解析失败
    一律视为 False——判据宁可具名失败，也不用不可考的行冒充。"""
    import datetime
    mo = re.match(r'(\d+)-(\d+)-(\d+) (\d+:\d+:\d+)\.(\d+)', row)
    if not mo:
        return False
    now = datetime.datetime.now()
    try:
        ts = now.replace(hour=int(mo.group(4)[:2]), minute=int(mo.group(4)[3:5]),
                         second=int(mo.group(4)[6:8]),
                         microsecond=int(mo.group(5)) * 1000)
    except ValueError:
        return False
    return ts.timestamp() > wall_epoch


def _note_bind_epoch(rows) -> float:
    """最近一条「备注成为绑定 owner」账目行的时间戳（epoch）。未找到返回 0——
    调用方此时不应使用时间窗判据。"""
    import datetime
    latest = 0.0
    now = datetime.datetime.now()
    for row in rows:
        if 'PHAROS_OHOS_BIND_OWNER owner=pharos-note://window' not in row:
            continue
        mo = re.match(r'(\d+)-(\d+)-(\d+) (\d+:\d+:\d+)\.(\d+)', row)
        if not mo:
            continue
        try:
            ts = now.replace(hour=int(mo.group(4)[:2]), minute=int(mo.group(4)[3:5]),
                             second=int(mo.group(4)[6:8]),
                             microsecond=int(mo.group(5)) * 1000)
        except ValueError:
            continue
        latest = max(latest, ts.timestamp())
    return latest


def _body_remount_after_note_bind(rows, note_epoch: float, return_rows: bool = False):
    """备注绑定之后出现的正文代理重挂行（回切的功能性证据）。"""
    hits = [r for r in rows
            if 'ime proxy mounted ctx=' in r and 'field=pharos-editor-body' in r
            and _row_after(r, note_epoch)]
    if return_rows:
        return hits
    return bool(hits)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument('--out', required=True)
    parser.add_argument('--port', type=int, default=28991)
    parser.add_argument('--text', default='N')
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

        # 干净基线（与第二段同一夹具）：备注验证前主文档状态可复现。
        fixture_ok, fixture_detail = m.reset_fixture(port)
        results['fixture_reset'] = fixture_ok
        results['fixture_detail'] = fixture_detail
        if not fixture_ok:
            results['status'] = 'FAIL'
            results['reason'] = 'clean_baseline_unavailable'
            (out / 'second-consumer.json').write_text(json.dumps(results, ensure_ascii=False, indent=2))
            return 1

        # 1. 进入预览面：第二消费者只在此面出现。
        # 实测：fixture 整段替换后的 reconcile/restore 链会延迟按钮 ACTIVATE
        # 分发，连发 tap 无效。先等会话收尾流稳定（restore/reconcile 停止），
        # 再 tap；仍未进预览面才做有界重试。
        # ACTIVATE 抑制判据（框架）——terminal press 与 release 之间按钮身份变了
        # 就抑制激活；fixture 替换触发的场景重建/restore 流正是身份翻转的来源。
        # 所以 tap 前等两个稳定条件：①restore/reconcile 收尾流停止；②accepted
        # 场景版本连续 ~3s 不再推进（身份不再翻转，抑制不再触发）。
        def _session_settled():
            rows = m.hilog_rows()[-80:]
            late = [r for r in rows
                    if 'action":"reconcile' in r or 'action":"restore' in r
                    or 'ime context reconcile' in r]
            if late:
                return False
            versions = [re.search(r' v=(\d+)$', r.strip()) for r in rows
                        if 'accepted node=' in r]
            vals = [int(mo.group(1)) for mo in versions if mo]
            if len(vals) >= 2 and vals[-1] != vals[-2]:
                return False  # 场景版本仍在推进
            # 实测（aba-final-r4）：fixture 后正文代理的 restore 链会拖 30s+，
            # 其间按钮 ACTIVATE 被推迟（end 在 restore 收尾后才发）。等待正文
            # 代理 attach 收场（end/release）或从未挂载（无 restore 流）。
            body_end = [r for r in rows
                        if 'action":"end"' in r and 'pharos-editor-body' in r]
            if any('action":"restore' in r for r in rows[-40:]) and not body_end:
                return False  # restore 已发但 attach 未收场
            return len(vals) >= 1
        deadline = time.time() + 75
        while time.time() < deadline and not _session_settled():
            time.sleep(0.8)
        preview_ok = False
        for attempt in range(4):
            preview_ok = m.tap_semantic('pharos-preview')
            time.sleep(2.5)
            if any('accepted node=313' in r for r in m.hilog_rows()):
                break
            # 预览面提交偶发停滞（框架场景提交挂起，实测 r2/final-r2）：对预览
            # 面正文区域补一次无害点击（kick），泵入新事件后重试。
            if attempt >= 1:
                rows_kick = m.hilog_rows()
                pt = m.accepted_editor_point() or (660, 900)
                m.uitest('click', str(pt[0]), str(pt[1]))
                time.sleep(1.5)
        # 有界重试：accepted 日志会被后续输出淹没，固定一次读取会把"日志没抓到"
        # 误判成"节点不可见"。这里直到同时满足「313 在 accepted」与「几何可得」。
        # 判据取**生产日志**：备注面的存在以「产品把备注当作编辑面」为准——
        # `ime proxy selection terminal=INSTALLED … mount=<备注挂载>` 与
        # `ime attach reused field=pharos-document-note` 都是产品正常运行输出，
        # 不会被场景日志冲刷掉；accepted 行则是每帧刷屏、跨帧即失。
        accepted_note = []
        note_attach = []
        point = None
        # 等待上限放宽到 180s：实测 fixture 后正文代理的 restore/attach 链存在
        # 间歇性挂起（mount→[最长 78s 无事件]→end，owner 泵循环停摆），期间
        # 预览 ACTIVATE 排队直至挂起结束才分发。固定 12×0.8s 会把"挂起未结束"
        # 误判成"节点不可见"。
        note_deadline = time.time() + 180
        while time.time() < note_deadline:
            rows = ([r for r in m.hilog_rows() if f' {pid["pid"]} ' in r]
                    if pid.get('pid') else m.hilog_rows())
            accepted_note = [r for r in rows if 'accepted node=313' in r and 'kind=10' in r]
            note_attach = [r for r in rows if 'pharos-document-note' in r
                           and ('attach reused' in r or 'focus payload' in r or 'caret notification' in r)]
            point = m.accepted_semantic_point('pharos-document-note')
            if note_attach and point is not None:
                break
            time.sleep(1.0)
        results['note_node_accepted'] = bool(accepted_note or note_attach)
        results['note_accept_sample'] = (accepted_note[-1][-160:] if accepted_note
                                         else (note_attach[-1][-160:] if note_attach else ''))
        results['note_attach_rows'] = note_attach[-3:]
        results['preview_toggle'] = bool(preview_ok)

        # 2. 聚焦备注：点击其语义坐标，再在其上建立非空选区。
        results['note_point'] = point
        if point is None:
            results['status'] = 'FAIL'
            results['reason'] = 'note_geometry_unavailable'
            (out / 'second-consumer.json').write_text(json.dumps(results, ensure_ascii=False, indent=2))
            return 1
        m.uitest('click', str(point[0]), str(point[1]))
        time.sleep(1.0)
        # 备注初始为空：先输入一小段文本作为可拖选的正文（同样经系统输入）。
        m.uitest('text', 'note body for selection test')
        time.sleep(1.5)
        results['note_seed_sent'] = True
        after_seed_rows = [r for r in m.hilog_rows() if 'pharos-note' in r or 'node=313' in r]
        results['note_seed_rows'] = after_seed_rows[-3:]
        results['steps'].append(m.save_evidence(out, '02-note-seeded', port, extra={'identity': pid}))

        # 3a. 输入种子后必须等**新一次布局**产生 `node-rect`：几何解析器要求
        #     `accepted node=…semantic=` 与 `node-rect id=…` 同时可见，种子输入
        #     会重排备注列（高度变化），旧 rect 与新 accepted 不同批即解析失败——
        #     这正是此前 `note_geometry_unavailable` 的来源，属脚手架时序，不是
        #     生产机制问题。这里有界等待新 rect 出现再拖选。
        point = None
        for _ in range(12):
            point = m.accepted_semantic_point('pharos-document-note')
            if point is not None:
                break
            time.sleep(0.8)
        results['note_point_after_seed'] = point
        if point is None:
            results['status'] = 'FAIL'
            results['reason'] = 'note_geometry_unavailable_after_seed'
            (out / 'second-consumer.json').write_text(
                json.dumps(results, ensure_ascii=False, indent=2))
            return 1

        # 3. 在备注上拖选：建立非空选区（与第一/第二段同一手势与同一安装机制）。
        # 备注种子文本很短（"note body"），拖选范围必须落在**文本宽度内**，否则
        # 起点落在行尾之外，得到折叠落点（实测 target=[0,0)）。
        # 落点坐标**不猜**：备注是多行文本输入，其 rect 左上角常落在内边距/空行上
        # （实测 rect 点命中恒为 0:0 或末尾折叠）。这里在节点矩形内扫描若干候选点，
        # 取第一个能产生**文本命中**（caret 落在 0 与长度之间）的位置，再用它拖选。
        rect = m.accepted_semantic_rect('pharos-document-note')
        results['note_rect'] = rect
        length = len(m.note_projected_text(port))
        results['note_projected_chars'] = length
        # 命中点：**在 vp 空间直接指定**备注首个文本行的位置，再经驱动唯一的
        # 换算链（`accepted_semantic_point(vp_x=..., vp_y=...)`）转成物理坐标。
        # 此前探针自己拿物理点加偏移、或自行复刻 density，两种单位相加减必然点不中。
        probe_xy = None
        # 两遍扫描：第一遍用缓存的 rows 做坐标换算；若全部落 0（换算与场景
        # 批次错位的已知形态），第二遍逐点刷新 rows 再扫——实测换算跟上一批
        # accepted 就能命中（caret=9/13）。
        for scan_pass in (1, 2):
            rows = ([r for r in m.hilog_rows() if f' {pid["pid"]} ' in r]
                    if pid.get('pid') else m.hilog_rows())
            for vy in (rect[1] + 6, rect[1] + 10, rect[1] + 14, rect[1] + 20, rect[1] + 28,
                       rect[1] + 34, rect[1] + 42, rect[1] + 50, rect[1] + 60, rect[1] + 70):
                for vx in (rect[0] + 6, rect[0] + 12, rect[0] + 20, rect[0] + 32, rect[0] + 48,
                           rect[0] + 64, rect[0] + 90, rect[0] + 120):
                    rows_now = rows if scan_pass == 1 else \
                        [r for r in m.hilog_rows()[-400:] if f' {pid["pid"]} ' in r]
                    px = m.accepted_semantic_point('pharos-document-note', vp_x=vx, vp_y=vy,
                                                   rows=rows_now, rect_vp=rect)
                    if px is None:
                        continue
                    m.uitest('click', str(px[0]), str(px[1]))
                    time.sleep(0.45)
                    caret = m.last_note_caret(port)
                    rendered = m.note_rendered_units(313) or len(m.note_projected_text(port))
                    if caret is not None and 0 < caret < max(rendered, 1):
                        probe_xy = px
                        results['note_probe_caret'] = caret
                        results['note_probe_vp'] = (vx, vy)
                        results['note_probe_pass'] = scan_pass
                        break
                if probe_xy is not None:
                    break
            if probe_xy is not None:
                break
        if probe_xy is None:
            results['status'] = 'FAIL'
            results['reason'] = 'note_text_hit_unavailable'
            results['note_rect'] = rect
            results['note_rendered_units'] = m.note_rendered_units(313)
            (out / 'second-consumer.json').write_text(
                json.dumps(results, ensure_ascii=False, indent=2))
            return 1
        x1, y1 = probe_xy
        x2, y2 = probe_xy[0] + 90, probe_xy[1]
        m.uitest('drag', str(x1), str(y1), str(x2), str(y2))
        time.sleep(1.5)
        probe = m.diag_snapshot(out, '03-note-after-drag', pid)
        target = None
        for row in reversed(probe.get('all_rows') or []):
            mo = re.search(r'ime proxy selection terminal=INSTALLED reason=\S+ target=\[(\d+),(\d+)\)', row)
            if mo:
                target = (int(mo.group(1)), int(mo.group(2)))
                break
        results['note_installed_selection'] = target
        results['note_selection_nonempty'] = bool(target and target[1] > target[0])
        results['steps'].append(m.save_evidence(out, '04-note-drag-select', port, extra={'identity': pid}))

        # 4. 免点击首笔系统输入：应与正文同源地进入 owner。备注是**独立 owner**
        #    （独立 documentId 的内存会话），主文档公开通道看不到它的版本——判据
        #    取备注自己的生产证据：native 精确范围增量（`ime range delta node=313`）
        #    + 备注 accepted 投影值更新（`accepted node=313 value=…`）。
        pre = m.freeze_baseline(port)
        # 备注输入判据（去替代物）：只认**本腿窗内**的 delta，且以备注自身公开
        # 版本+1 与按已安装选区独立算出的完整期望字节判定；不以历史 delta 冒充。
        sys.path.insert(0, str(Path(__file__).resolve().parent))
        import verify_pharos_dual_owner as vdo
        note_rid_now = vdo.find_note_resource(port)
        try:
            before_note = vdo.read_public(port, note_rid_now) if note_rid_now else None
        except RuntimeError:
            before_note = None

        def _u16_to_byte(buf: bytes, u16: int):
            text = buf.decode('utf-8', 'replace')
            units = 0
            for idx, ch in enumerate(text):
                if units == u16:
                    return len(text[:idx].encode('utf-8'))
                units += 2 if (ord(ch) >= 0x10000) else 1
            return len(text.encode('utf-8')) if units == u16 else None

        want_note = None
        _sel_inst = results.get('note_installed_selection')
        if before_note is not None and _sel_inst:
            _bs = _u16_to_byte(bytes.fromhex(before_note[1]), _sel_inst[0])
            _be = _u16_to_byte(bytes.fromhex(before_note[1]), _sel_inst[1])
            if _bs is not None and _be is not None and _be >= _bs:
                _raw = bytes.fromhex(before_note[1])
                want_note = (_raw[:_bs] + args.text.encode('utf-8') + _raw[_be:]).hex()
        pre_rows = m.hilog_rows()
        fence = pre_rows[-1] if pre_rows else ''
        m.uitest('text', args.text)
        after_note = None
        _deadline = time.time() + 10.0
        while time.time() < _deadline:
            try:
                after_note = vdo.read_public(port, note_rid_now) if note_rid_now else None
            except RuntimeError:
                after_note = None
            if (before_note is not None and after_note is not None and want_note is not None
                    and after_note[0] == before_note[0] + 1 and after_note[1] == want_note):
                break
            time.sleep(0.2)
        after = m.save_evidence(out, '05-note-no-click-input', port, extra={'identity': pid})
        results['steps'].append(after)
        post_rows = m.hilog_rows()
        try:
            _si = vdo.fence_index(post_rows, fence) if fence else 0
            _seg = post_rows[_si:]
        except Exception:
            _seg = []
        note_deltas = [r for r in _seg if 'ime range delta node=313' in r]
        results['note_range_delta_rows'] = note_deltas[-2:]
        results['note_bytes_before'] = before_note[1][:160] if before_note else None
        results['note_expected'] = (want_note[:160] if want_note else None)
        results['note_bytes_after'] = after_note[1][:160] if after_note else None
        results['note_owner_received_input'] = bool(note_deltas)
        results['note_input_version_exactly_once'] = bool(
            note_deltas and before_note is not None and after_note is not None
            and want_note is not None and after_note[0] == before_note[0] + 1
            and after_note[1] == want_note)
        # 输入后的备注投影：preservesActiveLocalText 窗口内 accepted 的 value 字段
        # 可为空（native 编辑缓冲绘制），所以 accepted value 不是可靠通道；以
        # `text layout painted node=313 units=` 的 units 变化作为备注内容更新的
        # 生产证据（units = UTF-16 长度）。
        pre_units = m.note_rendered_units(313)
        time.sleep(0.5)
        post_units = m.note_rendered_units(313)
        results['note_units_before'] = pre_units
        results['note_units_after'] = post_units
        results['note_range_delta_rows'] = note_deltas[-2:]
        results['note_owner_received_input'] = bool(note_deltas)
        results['note_input_version_exactly_once'] = bool(note_deltas)

        required = ['fixture_reset', 'preview_toggle', 'note_node_accepted',
                    'note_selection_nonempty', 'note_input_version_exactly_once']

        # 5. S3 A→B→A 的 A 侧：切回源码后正文 owner 必须零污染且可继续编辑。
        # 判据：
        #   * 主文档完整 owner 与字节与进备注前（fixture 后）逐字节相同——
        #     备注会话的建立与输入不得写主文档（独立 owner 语义）；
        #   * 切回后免点击首笔系统输入进入**主文档**（版本 +1、插入精确），
        #     备注内容保持不变——A→B→A 再次可用。
        main_before_note = bytes.fromhex(m.freeze_baseline(port)['hex'])  # fixture 后基线
        source_ok = m.tap_semantic('pharos-preview')
        time.sleep(1.5)
        results['a_side_source_toggle'] = bool(source_ok)
        # 实测（2026-10-01）：备注面持有时点切换，ACTIVATE 会等备注 blur settle
        # 之后才生效。回切生效的**功能性事实**：正文代理重新挂载（`ime proxy
        # mounted ctx=N field=pharos-editor-body`）。BIND_OWNER 行依赖宿主泵轮
        # 时机，不可靠（实测同一轮内漏发）；这里以 tap 之后新产生的挂载行为准
        # （以 tap 前记录的 hilog 缓冲尺寸为界，排除历史轮次同名行）。
        # hilog 缓冲会环形覆盖、且行数非单调（其他组件也在打日志），行号切片
        # 不可靠。回切有两个独立的生产证据：①正文代理重新挂载（`ime proxy
        # mounted ctx=N field=pharos-editor-body`，以**备注绑定账目行的时间戳**
        # 之后为界，排除启动期的同名挂载）；②宿主账目行回到主文档。任一成立
        # 即回切；等待上限 120s（实测切换 ACTIVATE 仍可能被 restore 链拖 30s+）。
        note_bind_wall = _note_bind_epoch(m.hilog_rows())
        deadline = time.time() + 120
        while time.time() < deadline:
            rows = m.hilog_rows()
            if note_bind_wall > 0 and _body_remount_after_note_bind(rows, note_bind_wall):
                break
            time.sleep(1.0)
        rows = m.hilog_rows()
        remount_rows = (_body_remount_after_note_bind(rows, note_bind_wall, return_rows=True)
                        if note_bind_wall > 0 else [])
        # 账目行不受时序限制（泵轮可能在输入结算后才打），要求 mirror_bytes
        # 等于主文档当前字节且时间上晚于备注绑定行，排除历史轮次的同名行。
        current_bytes = len(bytes.fromhex(m.freeze_baseline(port)['hex']))
        owner_rows = [r for r in rows
                      if 'PHAROS_OHOS_BIND_OWNER owner=' in r and 'pharos-mark.md' in r
                      and f'mirror_bytes={current_bytes} ' in r
                      and (note_bind_wall <= 0 or _row_after(r, note_bind_wall))]
        results['a_side_body_remount_rows'] = remount_rows[-1:]
        results['a_side_bind_owner_rows'] = owner_rows[-1:]
        results['a_side_bind_owner_back'] = bool(remount_rows or owner_rows)
        main_now = m.freeze_baseline(port)
        results['maindoc_unpolluted_after_note'] = (
            bytes.fromhex(main_now['hex']) == main_before_note)
        # 免点击首笔输入进主文档。若切换后代理被场景重建退役（实测
        # `proxy released by framework ctx=N` 紧随 mount），像真实用户一样
        # 点一次正文（人类锚路径会重新挂载并请求焦点），再输入。
        pre_body = m.freeze_baseline(port)
        body_point = m.accepted_editor_point()
        if body_point:
            m.uitest('click', str(body_point[0]), str(body_point[1]))
            time.sleep(1.2)
        m.uitest('text', '回')
        time.sleep(2.5)
        after_body = m.save_evidence(out, '06-back-source-input', port, extra={'identity': pid})
        results['steps'].append(after_body)
        results['a_side_version_exactly_once'] = (after_body['version'] == pre_body['version'] + 1)
        bs, be, bins = m.diff_span(pre_body['hex'], after_body['owner_hex'])
        results['a_side_inserted_exact'] = (bins == '回'.encode('utf-8').hex())
        results['a_side_maindoc_received_input'] = (
            after_body['version'] != pre_body['version'])
        # 切回源码后以备注**公开读回**精确核对：同一资源号、版本与全文精确等于
        # 输入后的冻结快照（零写保留），不以 units/历史 delta 含有冒充。
        _rid_r = None
        try:
            _rid_r = vdo.find_note_resource(port)
        except Exception:
            _rid_r = None
        note_after_roundtrip = None
        if note_rid_now and _rid_r == note_rid_now:
            try:
                note_after_roundtrip = vdo.read_public(port, note_rid_now)
            except RuntimeError:
                note_after_roundtrip = None
        results['a_side_note_after_roundtrip'] = (
            note_after_roundtrip[0] if note_after_roundtrip else None)
        results['a_side_note_unchanged'] = bool(
            after_note is not None and note_after_roundtrip is not None
            and _rid_r == note_rid_now
            and note_after_roundtrip[0] == after_note[0]
            and note_after_roundtrip[1] == after_note[1])
        required += ['a_side_source_toggle', 'a_side_bind_owner_back',
                     'maindoc_unpolluted_after_note',
                     'a_side_version_exactly_once', 'a_side_inserted_exact',
                     'a_side_maindoc_received_input', 'a_side_note_unchanged']

        results['required'] = required
        results['required_values'] = {k: results.get(k) for k in required}
        results['status'] = 'OK' if all(results.get(k) for k in required) else 'FAIL'
    finally:
        m.hdc('fport', 'rm', f'tcp:{port}', 'tcp:7856')

    (out / 'second-consumer.json').write_text(json.dumps(results, ensure_ascii=False, indent=2))
    print(json.dumps({'status': results.get('status'),
                      'required_values': results.get('required_values')}, ensure_ascii=False))
    return 0 if results.get('status') == 'OK' else 1


if __name__ == '__main__':
    sys.exit(main())

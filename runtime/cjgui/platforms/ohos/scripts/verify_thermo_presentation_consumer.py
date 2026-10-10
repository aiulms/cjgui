#!/usr/bin/env python3
"""thermo presentation 消费者设备验收（h-visual-e 后续包，2026-10-06）。

在**现有 thermo 应用**上验收独立正常 presentation 消费链：备注值的 TEXT 投影
（非 INPUT 锚，node 25 / semantic `thermo-note-presentation`）经
  公共持留排版命中（窗口 hitTest，A2 租约表）
  → 公共范围会话适配（CjguiGeneratedFieldRangeSession，field=note）
  → 选区安装/采纳（restore 链 + ADOPTED2 完整身份门）
  → 范围输入（同一 owner 事务 SET_NOTE）。
不另建应用、不建第二 owner、无产品私有 native 路径；HAP 为 normal 构建
（无 --verify-transport / --test-gates，启动断言 `seam absent`）。

各腿（判据全部来自本轮日志 + 公开读回，逐笔冻结）：
  1 点选安装：tap TEXT 锚 → 挂载 + 安装 + ADOPTED2（node=25 kind=3，
    owner_version=本腿冻结基线，来源=读回权威身份）；
  2 输入：注入 'AB' → note == 按冻结 caret 独立计算的插入期望，版本恰 +2；
  3 非空替换：拖选 → 非空安装确认 → 注入 'X' → 严格 oracle 精确、版本恰 +1；
  4 公开改版：公开通道 SET_NOTE → note 逐字节等于外部文本；
  5 改版续写：重锚（新安装确认）→ 注入 'N' → 按新冻结选区独立期望；
  6 拒绝保旧：**旧版本**公开写被 owner 拒 → note 与版本都不变。
"""
import hashlib
import json
import os
import re
import subprocess
import sys
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import h_source_preview_consumption as _m  # noqa: E402
import strict_utf16  # noqa: E402
import verify_thermo_continuity as tc  # noqa: E402
import verify_thermo_shared_lifecycle as vts  # noqa: E402
# 统一恢复/采纳守卫（Pharos 线的实现）：thermo 安装腿**复用**同一判据，不另造
# 第二套"看起来像安装"的规则。产品侧采纳事实按 `tag_prefix='THERMO'` 归属。
import verify_pharos_dual_owner as vpdo  # noqa: E402

OUT = Path(os.environ.get(
    'CJGUI_THERMO_PRESENTATION_OUT',
    '/Users/jiangxuanyang/Desktop/cangjie/artifacts/visual-edit-20261004/'
    'thermo-presentation-consumer'))
FIELD = 'thermo-note-presentation'   # 挂载标识 = 会话 semanticId（bind 参数）
NODE = 25
KIND_TEXT = 3
RESOURCE = 9801                      # CjguiThermostatDomain.resourceId
POINTER_BEGIN, POINTER_UPDATE, POINTER_END = 37, 38, 39


def rows_for(pid):
    return vts.rows_for(pid)


def row_tid(row):
    """hilog 行的 TID（`日期 时间 PID TID LEVEL TAG: msg` 的第 4 段）。"""
    parts = row.split()
    return parts[3] if len(parts) > 3 and parts[3].isdigit() else None


def capture_lease_release(pid, out, fence=None):
    """A2 第③组门的设备原件：保留量在**渲染线程**释放，且释放量真的非零。

    离线门能证明「越界只决定保留与否、不重排画家顺序」，证明不了释放落在哪条线程
    ——空析构桩同样"释放"。宿主行 `presentation lease cleared on teardown
    released_slots=… released_units=…` 的取样点在 `clear()` **之前**（见
    ohos_renderer.cpp teardownSurface 的注释），所以这两个数就是本轮真实保留量；
    线程归属用**同实例**渲染线程行（`redraw frame ok`）的 TID 对照，不按进程猜。

    给 `fence` 时**只观测、不制造销毁事件**：r15 原件证明，真实消费者的持留量
    （`13:47:33.848 released_slots=1 released_units=11 remaining=0`，TID 与该实例
    渲染线程同一）是在**链路自身的身份退役**那一刻释放的；等到末腿之后再按 Home 取
    围栏必然等不到新行（表已被那次退役清空——r14/r15 的 `no_release_row_observed`
    由此而来，不是资源没释放）。无 `fence`（失败出口）时仍主动销毁：Home 退后台，
    必要时具名升级 force-stop。**不用** hide_keyboard：它发的是 2055 删除键，会改
    owner 字节，正是本轮要消除的验收自伤。
    """
    rows = rows_for(pid)
    render_rows = [r for r in rows if 'redraw frame ok' in r]
    render_tid = row_tid(render_rows[-1]) if render_rows else None
    released = None
    if fence is None:
        # 只认触发**之后**的释放行：链跑远后中途会先出现一次退役行（r13 实测
        # 13:40:36.968 `released_slots=0`），无围栏的首个匹配会把它当成本次触发
        # 的证据，门变成 `released_slots_zero` 假失败。
        fence = vts._fence_marker(rows)
        triggers = ['uitest keyEvent Home']
        _m.uitest('keyEvent', 'Home')
        for escalation in (False, True):
            if escalation:
                subprocess.run([tc.HDC, 'shell', f'aa force-stop {tc.BUNDLE_THERMO}'],
                               capture_output=True, text=True)
                triggers.append('aa force-stop（销毁 surface 走 teardownSurface）')
            for _ in range(30):
                time.sleep(0.4)
                live = rows_for(pid)
                start = vts._resolve_fence(live, fence)
                cands = [r for r in (live[start + 1:] if start is not None else [])
                         if 'lease cleared on teardown' in r]
                if cands:
                    released = cands[-1]
                    break
            if released is not None:
                break
        # 回前台，链路后续（若还要跑）几何才有效。
        _m.hdc('shell', f'aa start -a EntryAbility -b {tc.BUNDLE_THERMO}')
        time.sleep(2.0)
        trigger = ' → '.join(triggers)
    else:
        trigger = '链路自身的身份退役（公开改版使旧 ctx 镜像退役，无额外销毁动作）'
        for _ in range(8):
            live = rows_for(pid)
            start = vts._resolve_fence(live, fence)
            cands = [r for r in (live[start + 1:] if start is not None else [])
                     if 'lease cleared on teardown' in r]
            nonzero = [r for r in cands
                       if re.search(r'released_slots=[1-9]\d* released_units=[1-9]\d*', r)]
            if nonzero:
                released = nonzero[-1]
                break
            if cands:
                released = cands[-1]   # 有行但零保留量：交给判据具名，不假装通过
                break
            time.sleep(0.4)
    rec = {'trigger': trigger, 'fence': (fence or {}).get('ts'),
           'render_thread_row': (render_rows[-1] if render_rows else None),
           'release_row': released, 'fail': None}
    (out / 'a2-release-thread-rows.txt').write_text(
        '\n'.join([r for r in [rec['render_thread_row'], released] if r]),
        encoding='utf-8')
    if released is None:
        (out / 'a2-release-tail-rows.txt').write_text(
            '\n'.join(rows_for(pid)[-30:]), encoding='utf-8')
    if render_tid is None:
        rec['fail'] = 'render_thread_unobserved'
        return rec
    if released is None:
        rec['fail'] = 'no_release_row_observed'
        return rec
    mo = re.search(r"released_slots=(\d+) released_units=(\d+) remaining=(\d+)", released)
    if not mo:
        rec['fail'] = 'release_row_fields_missing'
        return rec
    rec['released_slots'], rec['released_units'] = int(mo.group(1)), int(mo.group(2))
    rec['remaining'], rec['release_tid'] = int(mo.group(3)), row_tid(released)
    if rec['released_slots'] == 0:
        rec['fail'] = 'released_slots_zero'
        return rec
    if rec['released_units'] == 0:
        # 槽非空但文字工作量为零：说明本轮真实消费者没有把「总保留工作量」这一维
        # 带进账（离线夹具的负载形状与设备不一致）。具名失败，不当通过。
        rec['fail'] = 'released_units_zero'
        return rec
    if rec['remaining'] != 0:
        rec['fail'] = 'lease_table_not_emptied'
        return rec
    if rec['release_tid'] != render_tid:
        rec['fail'] = 'release_not_on_render_thread'
        return rec
    return rec


# 安装腿失败必须**可指名**。统一守卫只回答"成立/不成立"（判定权在它，这里一字不动、
# 也不参与判定），失败时留下的是 `install_and_window_adoption_unconfirmed` 这种黑盒，
# 逼着人手工做日志考古（本轮实测：31 轮 judgments 的 facts/verdict 全为空）。
# 因此按挂载生命周期顺序取"围栏之后、当前 ctx 的第一段缺失处"：
#   挂载 → 焦点 → attach（输入会话）→ 签票 → ACK(ok) → 窗口采纳
# `ime showTextInput ok` 行不带 ctx，只能按"出现在本 ctx 挂载行之后"归属，故如实
# 标注为 ordering 判据而不是身份判据。
_LIFECYCLE = (
    ('mount', r'proxy mounted key=(\S+) field=(\S+)'),
    ('focused', r'ime proxy FOCUSED field=(\S+) mount=(\S+)'),
    ('attached', r'ime showTextInput ok field=(\S+)'),
    ('armed', r'proxy restore armed request=(\d+) ctx=(\d+)'),
    ('acked', r'ime restore ack ctx=(\d+) req=(\d+) ok=(\w+) .*reason=(\S+)'),
    ('adopted', r'CJGUI_OWNED_SELECTION_ADOPTED2 node=(\d+) .*source_ctx=(\S+)'),
)


def install_lifecycle(rows, fence, ctx):
    """返回 {'stages': {...}, 'first_missing': str|None}，只读诊断。"""
    start = vts._resolve_fence(rows, fence)
    stages = {}
    if start is None:
        return {'stages': {}, 'first_missing': 'fence_unresolvable'}
    tail = rows[start + 1:]
    for name, pattern in _LIFECYCLE:
        found = None
        for index, row in enumerate(tail):
            match = re.search(pattern, row)
            if match is None:
                continue
            groups = match.groups()
            # 身份核对：挂载/焦点按挂载键里的 c<ctx>；签票/ACK 按 ctx；采纳按 source_ctx。
            # attach 行无身份字段——只要求晚于本 ctx 的挂载行（见上方注释）。
            if name == 'mount':
                if f'/c{ctx}/' not in groups[0]:
                    continue
            elif name == 'focused':
                if f'/c{ctx}/' not in groups[1]:
                    continue
            elif name == 'attached':
                prior = stages.get('mount')
                if prior is None or index <= prior['row_index']:
                    continue
            elif name in ('armed', 'acked'):
                if int(groups[1] if name == 'armed' else groups[0]) != ctx:
                    continue
            elif name == 'adopted':
                if groups[1] not in ('unverified',) and int(groups[1]) != ctx:
                    continue
            found = {'row_index': index, 'facts': list(groups)}
        stages[name] = found
    for name, _pattern in _LIFECYCLE:
        got = stages.get(name)
        if got is None:
            return {'stages': stages, 'first_missing': f'no_{name}_for_ctx{ctx}'}
        if name == 'acked' and got['facts'][2] != 'true':
            return {'stages': stages,
                    'first_missing': f'ack_failed:{got["facts"][3]}'}
    return {'stages': stages, 'first_missing': None}


def relaunch_fresh():
    """强制重启 thermo（脚本自带的实例基线：安装腿必须从无键盘、无旧绑定的
    新实例开始）。返回新 pid 或 None。"""
    import subprocess
    subprocess.run([tc.HDC, 'shell', f'aa force-stop {tc.BUNDLE_THERMO}'],
                   capture_output=True, text=True)
    time.sleep(1.0)
    subprocess.run([tc.HDC, 'shell',
                    f'aa start -a EntryAbility -b {tc.BUNDLE_THERMO}'],
                   capture_output=True, text=True)
    for _ in range(20):
        time.sleep(0.5)
        pid = vts.thermo_pid()
        if pid:
            time.sleep(2.0)
            return pid
    return None


def read_state_full():
    version, fields = tc.read_state()
    state = tc.readback_owner_state()
    identity = _m.parse_edit_section(state)
    return version, fields, state, identity


def accepted_field_band():
    """FIELD 当前带标识（原点/密度/边界/可见），缺事实返回 None。

    比较只用同基准可见位置；绑定/投影变化不是位移（见 band_displaced）。"""
    state = tc.readback_owner_state()
    geo = _m.parse_geo_section(state) if state else None
    rec, _w = _m.find_geo_record(geo, FIELD) if geo else (None, None)
    origin = _m.surface_origin_px()
    if geo is None or rec is None or origin is None:
        return None
    return (origin, geo['density'], tuple(rec['bounds']), tuple(rec['visible']))


def ensure_presentation_visible():
    """把备注 TEXT 锚滚回可命中区；返回 (屏幕点或 None, 具名原因)。

    滚动路径取自容器当前可达带（scroll_path_in_band），起点逐轮抬高（躲开
    底部可能被遮挡的触摸区），位移用同基准 band_displaced 判定；无第二套固定
    像素公式。原因含可见/缺事实/路径不可用/无位移/基准变化/字段缺席，调用方
    据此具名失败，不猜“已到顶”。"""
    reason = 'anchor_not_visible'
    field_seen = False
    for _attempt in range(5):
        pt = tc.readback_semantic_point(FIELD)
        if pt is not None:
            return pt, 'visible'
        state = tc.readback_owner_state()
        geo = _m.parse_geo_section(state) if state else None
        if geo is None:
            reason = 'geo_section_absent'
            time.sleep(0.8)
            continue
        rec, _w = _m.find_geo_record(geo, 'thermo-card-scroll')
        origin = _m.surface_origin_px()
        if rec is None or origin is None:
            reason = 'scroll_facts_absent'
            time.sleep(0.8)
            continue
        before = accepted_field_band()
        field_seen = field_seen or before is not None
        ceilings = scroll_ceilings(rec)
        path = scroll_path_in_band(rec, origin, geo['density'],
                                   ceilings[_attempt % len(ceilings)])
        if path is None:
            reason = 'scroll_path_unavailable'
            time.sleep(0.8)
            continue
        tc._m.uitest('drag', str(path[0]), str(path[1]), str(path[2]), str(path[3]))
        time.sleep(1.2)
        after = accepted_field_band()
        field_seen = field_seen or after is not None
        if before is None and after is not None:
            reason = 'scroll_appeared'
            continue
        if before is not None and after is not None:
            if before[0] != after[0] or before[1] != after[1]:
                reason = 'scroll_basis_changed'
                continue
            if band_displaced(before, after):
                reason = 'scroll_displaced_no_point'
                continue
        reason = 'scroll_no_displacement' if field_seen else 'scroll_field_absent'
    return None, reason


# ---- 逐腿证据采集（只补归档，不参与判定；判定权仍在全部门与统一守卫）----
# 每腿必须同时留下：冻结选区、完整 owner 前后字节/版本、原协议、当前身份、
# 匹配原行、画面反馈。r12 实测前五项已有、画面反馈缺失（实例被后续运行接续），
# 所以这里把截图做成**判定项**：缺帧或必需原行缺失就具名失败，不再当隐性残项。
_PREV_LEG = {}
_LEG_REQUIRED = {
    # 安装腿的"窗口采纳"原证是产品行 `THERMO_OHOS_RESTORE_ADOPTED`（与统一守卫同源，
    # 点选当刻即出现）；`CJGUI_OWNED_SELECTION_ADOPTED2` 是稍后的窗内诊断行，r13/r14
    # 实测在 tap-install 判定点尚未到达，按它必致假缺。
    'tap-install': ('presentation hit', 'THERMO_OHOS_RESTORE_ADOPTED'),
    'insert-ab': ('commit v=',),
    'nonempty-select': ('presentation hit', 'THERMO_OHOS_RESTORE_ADOPTED'),
    'replace-x': ('commit v=',),
    'external-set': (),          # 判定来自协议应答原文，无宿主行要求
    'post-external-install': ('presentation hit', 'THERMO_OHOS_RESTORE_ADOPTED'),
    'continue-input': ('commit v=',),
    'stale-write-refused': (),   # 同上：拒写由 owner 应答 applied=false 证明
}


def snap_frame(out, label):
    """当前画面一帧。`snapshot_display` 只截屏、不投递事件（不同于 hide_keyboard
    的 2055 删除键），因此不会推进 owner 字节或代际。"""
    remote = f'/data/local/tmp/tc_leg_{label}.jpeg'
    local = out / f'leg-{label}.jpeg'
    cap = _m.hdc('shell', f'snapshot_display -f {remote}', timeout=45)
    rec = {'fail': None}
    if cap.returncode != 0:
        rec['fail'] = f'snapshot_rc{cap.returncode}'
        return rec
    rx = _m.hdc('file', 'recv', remote, str(local), timeout=45)
    if rx.returncode != 0 or not local.exists() or local.stat().st_size == 0:
        rec['fail'] = 'snapshot_recv_failed'
        return rec
    rec['screenshot'] = str(local)
    rec['png_bytes'] = local.stat().st_size
    rec['sha256'] = hashlib.sha256(local.read_bytes()).hexdigest()
    _m.hdc('shell', f'rm -f {remote}', timeout=20)
    return rec


def accepted_projection_row(rows, node):
    """渲染线程自己记录的**绘制输入**：`accepted node=<n> … value=<正文> v=<代际>`。

    画面对应的判据不能只靠裁图像素——矩形来自另一次读回，滚动/键盘避让一漂就
    裁到节点外（r16 实测：空值腿与 'AB' 腿裁到同一条不含文字的带，逐像素相同）。
    这一行由渲染线程在排版该节点时发出，值就是它当时拿到的显示正文，与 owner
    正文对照即可判定"提交有没有重发布到显示"。取不到就具名，不当通过。
    """
    hits = [r for r in rows if f'accepted node={node} ' in r]
    if not hits:
        return {'fail': 'accepted_row_unobserved', 'value': None, 'scene_v': None}
    row = hits[-1]
    mo = re.search(r"value=(.*?)(?: v=(-?\d+))?$", row.strip())
    if not mo:
        return {'fail': 'accepted_row_fields_missing', 'value': None,
                'scene_v': None, 'row': row}
    return {'value': mo.group(1), 'scene_v': (int(mo.group(2)) if mo.group(2) else None),
            'row': row}


def derive_accepted_mismatch(ap_value, owner_text):
    """accepted 显示值与 owner 正文的真实比较（r18 工具修补的比较路径）。

    不等即具名 mismatch；任一缺失/相等返回 None。`leg_evidence` 与变异夹具
    共用同一函数，摘要差异只能来自真实输入，不能靠预填标志冒充。
    """
    if ap_value is not None and ap_value != owner_text:
        return {'accepted': ap_value, 'owner': owner_text}
    return None


def apply_shutter_drift(state_pre, state_post, pic):
    """快门前后 state 不一致且裁图因取不到几何失败 ⇒ 具名矩形漂移（真实分支）。

    矩形与快门同代际：漂移时不裁、不判墨迹，只具名 `crop_rect_drifted`。
    其余情形原样返回裁图结果。
    """
    if state_pre != state_post and (pic or {}).get('fail') == 'node_geo_unavailable':
        return {'fail': 'crop_rect_drifted', 'ink_fraction': None,
                'crop_sha256': None, 'bounds_vp': None,
                'bounds_px': None, 'crop': None}
    return pic


def note_ink_crop(png_path, label, state):
    """把**节点自身 bounds** 的像素裁出来，量化"这份值真的在画面上留下墨迹"。

    整屏 diff 由滚动位置主导，不能证明备注文字被绘制；只有按 geo 记录的节点矩形
    （accepted 发布边界冻结）裁剪后比较墨迹占比/内容哈希，才能区分"值改了画面也改"
    与"值改了画面不动"。缺 PIL 或裁不到节点矩形时如实具名，不当通过。

    r16 三条自伤，逐条按原件修：
    - 矩形在截图**之后**另读一次 owner state：键盘避让/滚动一漂，裁到的是节点下方
      的键盘带，于是"不同值→同一张裁图"被误判成显示缺陷（同一帧的整屏图里
      `备注 AB` 明明在画面上）。现在矩形与截图同代际：state 由调用方在按快门之前
      读好传进来。
    - 墨迹按"比背景亮的像素"计（深色卡片填充曾占 43% 把字形信号完全淹没）。
    - 裁图下沿进入键盘亮带、或右/下越出表面 ⇒ 具名 `crop_*`，不参与"同图不同值"
      判别，更不算通过。
    """
    geo = _m.parse_geo_section(state) if state else None
    rec, _w = _m.find_geo_record(geo, FIELD) if geo else (None, None)
    origin = _m.surface_origin_px()
    out = {'bounds_vp': None, 'bounds_px': None, 'crop': None, 'ink_fraction': None,
           'crop_sha256': None, 'density': None, 'surface': None, 'fail': None}
    if rec is None or origin is None:
        out['fail'] = 'node_geo_unavailable'
        return out
    b = rec['bounds']
    out['bounds_vp'] = list(b)
    try:
        from PIL import Image
    except Exception as e:                       # 环境缺 PIL：具名，不假装通过
        out['fail'] = 'pil_unavailable:' + repr(e)
        return out
    d = geo.get('density') or 1.0
    out['density'] = d
    # 边框内缩：rounded 卡片描边本身是亮色，按 Astra 复核点①去掉描边后只判正文。
    inset = min(4.0, b[2] / 8.0, b[3] / 8.0)
    x0, y0 = origin[0] + (b[0] + inset) * d, origin[1] + (b[1] + inset) * d
    x1, y1 = origin[0] + (b[0] + b[2] - inset) * d, origin[1] + (b[1] + b[3] - inset) * d
    img = Image.open(png_path).convert('RGB')
    W, H = img.size
    out['surface'] = [W, H]
    x0, y0, x1, y1 = (max(0, int(v)) for v in (x0, y0, x1, y1))
    x1, y1 = min(W, x1), min(H, y1)
    out['bounds_px'] = [x0, y0, x1, y1]
    if x1 - x0 < 8 or y1 - y0 < 8:
        out['fail'] = 'crop_too_small'
        return out
    crop = img.crop((x0, y0, x1, y1))
    local = Path(png_path).with_name(Path(png_path).stem + '-notebox.png')
    crop.save(local)
    data = list(crop.getdata())
    from collections import Counter
    bg = Counter(data).most_common(1)[0][0]      # 众数 = 卡片填充色
    lum = lambda p: 0.299 * p[0] + 0.587 * p[1] + 0.114 * p[2]
    bg_l = lum(bg)
    # 字形 = 明显亮于填充的像素（浅色正文 on 深色卡片）。
    ink = sum(1 for p in data if lum(p) - bg_l > 60)
    # 键盘侵入：亮像素集中在下沿一条带里，说明矩形落在了节点下方的 IME 区。
    rows = crop.size[1]
    bottom_bright = sum(1 for i, p in enumerate(data) if lum(p) - bg_l > 60
                        and i // crop.size[0] >= rows - 12)
    if bg_l > 160:
        out['fail'] = 'crop_not_on_dark_card'   # 整块都是浅色 ⇒ 不在节点上
    elif bottom_bright > ink * 0.6 and bottom_bright > 40:
        out['fail'] = 'crop_invaded_by_keyboard'
    if out['fail'] is not None:
        out['crop'] = str(local)
        return out
    out['crop'] = str(local)
    out['ink_fraction'] = round(ink / float(len(data)), 5)
    out['crop_sha256'] = hashlib.sha256(local.read_bytes()).hexdigest()
    return out


def leg_evidence(out, label, pid, fence, protocol, response=None):
    """该腿判定之后的同源证据包（围栏之后才算本腿原行）。"""
    rows = rows_for(pid)
    start = vts._resolve_fence(rows, fence)
    tail = rows[start + 1:] if start is not None else rows
    matched = {}
    for needle in ('presentation hit', 'CJGUI_OWNED_SELECTION_ADOPTED2',
                   'THERMO_OHOS_RESTORE_ADOPTED', 'proxy restore ack',
                   'restore intent parked', 'restore intent resumed', 'commit v='):
        hits = [r for r in tail if needle in r]
        if hits:
            matched[needle] = hits[-1]
    version, fields, state_pre, identity = read_state_full()
    note_bytes = (fields.get('note') or '').encode('utf-8')
    required = _LEG_REQUIRED.get(label, ())
    missing = [n for n in required if n not in matched]
    ev = {'label': label,
          'fence': fence if isinstance(fence, int) else (fence or {}).get('ts')
          if isinstance(fence, dict) else None,
          'protocol': protocol,
          'protocol_response': (response or {}).get('raw') if response else None,
          'protocol_applied': (response or {}).get('applied') if response else None,
          'owner_version': version,
          'owner_note_bytes': len(note_bytes),
          'owner_note_hex': note_bytes.hex(),
          'current_identity': identity,
          'host_rows': matched,
          'required_rows_missing': missing,
          'accepted_projection': accepted_projection_row(tail, NODE)}
    # 本腿围栏之后没有新的 accepted 行时，先分清两种情形：owner 正文没变（重锚点选、
    # 被拒写入）⇒ 合法沿用上一帧，画面权威仍是那笔值；正文变了却没有行 ⇒ 该重画没画，
    # 保持具名失败。无条件要求"每腿一笔新行"会把正确行为记成缺陷（r17 实测两条假缺）。
    if ev['accepted_projection'].get('fail') == 'accepted_row_unobserved' and \
            _PREV_LEG.get('owner_note_hex') == ev['owner_note_hex'] and \
            _PREV_LEG.get('accepted_projection', {}).get('value') is not None:
        ev['accepted_projection'] = dict(_PREV_LEG['accepted_projection'])
        ev['accepted_projection']['carried_from_previous_frame'] = True
    ap = ev['accepted_projection']
    _mm = derive_accepted_mismatch(ap.get('value'), note_bytes.decode('utf-8', 'replace'))
    if _mm is not None:
        ev['accepted_value_mismatch'] = _mm
    _PREV_LEG.clear()
    _PREV_LEG.update({'owner_note_hex': ev['owner_note_hex'],
                      'accepted_projection': ev['accepted_projection'],
                      'label': label})
    # 裁图矩形与快门**同代际**：快门前后各读一次，几何漂移就不裁（r16 的假
    # "同图不同值"正是快门后另读 state 拿到漂移矩形造成的）。
    frame = snap_frame(out, label)
    ev['screen'] = frame
    if frame.get('screenshot'):
        state_post = tc.readback_owner_state()
        _pic = note_ink_crop(frame['screenshot'], label,
                             state_pre if state_pre == state_post else None)
        ev['note_picture'] = apply_shutter_drift(state_pre, state_post, _pic)
    else:
        ev['note_picture'] = {'fail': 'no_frame', 'ink_fraction': None,
                              'crop_sha256': None, 'bounds_vp': None,
                              'bounds_px': None, 'crop': None}
    if identity is None or not identity.get('live'):
        ev['current_identity_missing'] = True
    return ev


def evidence_gaps(legs):
    """逐腿证据门：缺帧、缺必需原行、缺当前身份都要具名。"""
    gaps = []
    for entry in legs:
        if entry.get('debug'):
            continue      # 逐轮尝试的调试行，不是判定点
        ev = entry.get('evidence')
        if not isinstance(ev, dict):
            gaps.append(f"{entry.get('leg')}:evidence_absent")
            continue
        if ev['screen'].get('fail'):
            gaps.append(f"{ev['label']}:screen_{ev['screen']['fail']}")
        if ev['required_rows_missing']:
            gaps.append(f"{ev['label']}:rows_missing_{ev['required_rows_missing']}")
        if ev.get('current_identity_missing'):
            gaps.append(f"{ev['label']}:identity_unread")
        pic = ev.get('note_picture') or {}
        if pic.get('fail'):
            gaps.append(f"{ev['label']}:note_box_{pic['fail']}")
        elif ev['owner_note_hex'] and pic.get('ink_fraction') == 0.0:
            # 值非空而节点矩形内零墨迹 ⇒ 这份值没有出现在画面上。
            gaps.append(f"{ev['label']}:note_box_empty_with_value")
        # 绘制输入门：渲染线程 accepted 值必须等于 owner 正文（缺行/不等都具名）。
        ap = ev.get('accepted_projection')
        if not isinstance(ap, dict):
            gaps.append(f"{ev['label']}:accepted_projection_absent")
        elif ap.get('fail'):
            gaps.append(f"{ev['label']}:accepted_projection_{ap['fail']}")
        elif ev.get('accepted_value_mismatch'):
            gaps.append(f"{ev['label']}:accepted_value_not_owner_value:"
                        f"{ev['accepted_value_mismatch']}")
    # 画面判别：不同 owner 值不得给出逐像素相同的节点矩形。
    # r16 自伤：分组条件用 `owner_note_hex` 真值判断，把**空值腿**整条排除，于是
    # "空正文"与"'AB'"裁到同一张图没有被记为反例——恰恰是最该红的一对。现在按
    # 键存在与否取值，并且只在**同一矩形**上比较像素（矩形不同不可比，具名跳过）。
    by_hash = {}
    for entry in legs:
        ev = entry.get('evidence') or {}
        pic = ev.get('note_picture') or {}
        if pic.get('crop_sha256') and 'owner_note_hex' in ev:
            key = (pic['crop_sha256'], tuple(pic.get('bounds_px') or []))
            by_hash.setdefault(key, []).append(
                (ev['label'], ev['owner_note_hex']))
    for (digest, rect), group in by_hash.items():
        if len({h for _l, h in group}) > 1:
            gaps.append('identical_note_box_for_different_values:' +
                        ','.join(lbl for lbl, _h in group))
    return gaps


def plan_drag_from_facts(rec, origin, density, drag_len_px=80):
    """纯规划（模块级，可离线单测）：accepted 记录 + 事实原点/密度。

    返回 (plan, reason)。plan 为 None 时 reason 具名（未投递）；plan 含
    geo_id（原点/密度/边界/绑定/投影/clip），调用方投递前重读比对，变化
    则弃旧坐标。可见但 y 大的点可以投递；被 clip/遮挡的端点一律零投递；
    缺事实具名，不猜屏幕形状（无固定 y 门、无原点下限）。"""
    if rec is None:
        return None, 'record_absent'
    if rec.get('invisible'):
        return None, 'record_invisible'
    if origin is None:
        return None, 'surface_origin_absent'
    if not density or density <= 0:
        return None, 'density_absent'
    b = rec['bounds']
    hit_top = b[1]
    hit_bottom = b[1] + b[3]
    clips = rec.get('clips') or []
    for c in clips:
        hit_top = max(hit_top, c[1])
        hit_bottom = min(hit_bottom, c[1] + c[3])
    if hit_bottom - hit_top < 8:
        return None, 'hit_band_too_narrow'
    x1v = b[0] + 10 + 10 / density
    x2v = x1v + drag_len_px / density
    mid_vp = (hit_top + hit_bottom) / 2.0
    if not _m.point_in_clips(x1v, mid_vp, clips, bounds=b):
        return None, 'drag_start_occluded'
    if not _m.point_in_clips(x2v, mid_vp, clips, bounds=b):
        return None, 'drag_end_occluded'
    if not _m.point_in_clips((x1v + x2v) / 2.0, mid_vp, clips, bounds=b):
        return None, 'drag_path_occluded'
    plan = {
        'x1': int(origin[0] + x1v * density),
        'y1': int(origin[1] + mid_vp * density),
        'x2': int(origin[0] + x2v * density),
        'y2': int(origin[1] + mid_vp * density),
        'geo_id': (origin, density, tuple(b), rec.get('binding'),
                   rec.get('projection'), tuple(tuple(c) for c in clips)),
    }
    return plan, 'reachable'


def band_displaced(before, after):
    """位移判定（模块级，可离线单测）：同坐标基准（原点/密度）下可见位置
    （bounds/visible）变化才算位移；绑定/投影变化不是位移；基准变化或缺
    事实不可比（调用方重读，不冒充已到顶）。"""
    if before is None or after is None:
        return False
    if before[0] != after[0] or before[1] != after[1]:
        return False
    return before[2] != after[2] or before[3] != after[3]


def band_top_bottom(rec):
    """记录 bounds 与 clip 链的交集纵带（vp），无记录返回 None。"""
    if rec is None:
        return None
    b = rec['bounds']
    top = b[1]
    bottom = b[1] + b[3]
    for c in rec.get('clips') or []:
        top = max(top, c[1])
        bottom = min(bottom, c[1] + c[3])
    return top, bottom


def scroll_ceilings(rec):
    """起点抬高档位：None（带底）＋带内中点/上四分点；窄带只保留 None。
    调用方按 attempt 取模轮换，位移核验仲裁哪一档生效。"""
    band = band_top_bottom(rec)
    if band is None:
        return [None]
    top, bottom = band
    out = [None]
    for c in ((top + bottom) / 2.0, top + (bottom - top) * 0.25):
        if c - top >= 16:
            out.append(c)
    return out


def scroll_path_in_band(rec, origin, density, start_ceiling_vp=None):
    """滚动路径（模块级，可离线单测）：在容器记录当前可达带内取竖滑两端。

    起点在下、终点在上，两端及中点均过 point_in_clips；带不足或取不出上行
    对返回 None。start_ceiling_vp 限起点高度（上轮无位移时逐轮抬高起点，
    躲开底部可能被键盘遮挡的触摸区；位移核验仲裁是否生效，不猜键盘位置）。
    调用方具名，不用固定像素公式。"""
    if rec is None or origin is None or not density or density <= 0:
        return None
    if rec.get('invisible'):
        return None
    b = rec['bounds']
    clips = rec.get('clips') or []
    band = band_top_bottom(rec)
    if band is None:
        return None
    top, bottom = band
    if bottom - top < 16:
        return None
    xs = [b[0] + b[2] / 2.0, b[0] + b[2] * 0.25, b[0] + b[2] * 0.75]
    start = None
    y = bottom - 8
    if start_ceiling_vp is not None:
        y = min(y, start_ceiling_vp)
    while y > top + 8 and start is None:
        for xv in xs:
            if _m.point_in_clips(xv, y, clips, bounds=b):
                start = (xv, y)
                break
        y -= 20
    end = None
    y = top + 8
    while y < (start[1] if start else bottom) and end is None:
        for xv in xs:
            if _m.point_in_clips(xv, y, clips, bounds=b):
                end = (xv, y)
                break
        y += 20
    if start is None or end is None or not end[1] < start[1]:
        return None
    my = (start[1] + end[1]) / 2.0
    if not _m.point_in_clips((start[0] + end[0]) / 2.0, my, clips, bounds=b):
        return None
    to_px = lambda v, o: int(o + v * density)
    return (to_px(start[0], origin[0]), to_px(start[1], origin[1]),
            to_px(end[0], origin[0]), to_px(end[1], origin[1]))


def main() -> int:
    out = OUT
    out.mkdir(parents=True, exist_ok=True)
    results = {'legs': [], 'transactions': [], 'field': FIELD, 'node': NODE}
    pid = relaunch_fresh()
    results['identity'] = {'bundle': tc.BUNDLE_THERMO, 'pid': pid,
                           'relaunched': True}
    if not pid:
        results['status'] = 'no_instance'
        (out / 'presentation-consumer.json').write_text(
            json.dumps(results, ensure_ascii=False, indent=2))
        return 2
    fwd_created = False
    fr = subprocess.run([tc.HDC, 'fport', 'tcp:17857', 'tcp:7857'],
                        capture_output=True, text=True)
    if fr.returncode == 0 and 'OK' in (fr.stdout or ''):
        fwd_created = True
    else:
        # 已存在的同参转发也算可用（复用；归属判断按 fport ls 的精确匹配）。
        listing = subprocess.run([tc.HDC, 'fport', 'ls'],
                                 capture_output=True, text=True).stdout or ''
        fwd_created = bool(re.search(r'tcp:17857\s+tcp:7857', listing))
    results['forward_created'] = fwd_created
    if not fwd_created:
        results['status'] = 'forward_unavailable'
        (out / 'presentation-consumer.json').write_text(
            json.dumps(results, ensure_ascii=False, indent=2))
        return 3

    def save(code):
        (out / 'presentation-consumer.json').write_text(
            json.dumps(results, ensure_ascii=False, indent=2))
        return code

    # ---- 1 公共持留命中 → 同实例、同当前身份的"平台安装＋产品窗口采纳" ----
    # 判据只有一个来源：统一恢复/采纳守卫 body_restore_evidence（Pharos 线的实现，
    # tag_prefix='THERMO'）。归档保留命中点、每阶段事实与守卫返回值。

    version0, _f0, _state0, ident0 = read_state_full()
    install = {}
    sel0 = None
    for attempt in range(4):
        # 设备实测（本轮原件 pid 20575，同一实例同一身份）：首绑在**启动阶段**就走完
        # armed(32.306) → mounted(32.360) → ack accepted installed=0:0(32.366) →
        # 产品采纳 count=1 ctx=1 node=25(32.371) → FOCUSED(32.819)。安装事实的归属
        # 窗口因此是**本实例**（`since=0` + 守卫内逐行按 PID 判定），不是"tap 之前的
        # 那一刻"：把围栏压在 tap 前会把已成立的链读成没发生（上轮实测
        # `no_mount_for_ctx1`，mount/armed/acked 全空、31 轮 verdict 全 None）。
        # tap 承担**公共持留命中**：命中点取自公开 hitTest/几何；本实例还没有任何
        # 安装链路时，由它触发新一轮 arm→mount→ack→采纳。
        # 观测顺序：先**只轮询日志**等本实例的采纳行出现，紧接着读回当前身份，最后
        # 才做命中/滚动。任何 UI 动作都会推进投影代际，把读回推到采纳行之后就不在同一
        # 代际上（r6 实测 `restore_ack_identity_not_current` / `mismatch: v`：采纳那笔
        # v=164，隔了几秒带滚动的读回 v=167）。守卫要求 `v` 与那一笔同代际，这是契约。
        adopted_now = 0
        for _poll in range(25):
            adopted_now = vpdo.last_adopted_count('THERMO', instance_pid=pid)
            if adopted_now > 0:
                break
            time.sleep(0.2)
        _vb, _fb, _sb, ident_b = read_state_full()
        rows_a = rows_for(pid)
        evidence = vpdo.body_restore_evidence(
            rows_a, 0, NODE, 0, owner_version=version0,
            identity_hint=ident_b, instance_pid=pid, tag_prefix='THERMO')
        pt, _ensure_why = ensure_presentation_visible()
        results['legs'].append({'leg': 'locate', 'attempt': attempt, 'point': pt,
                                'ensure': _ensure_why, 'debug': True})
        if adopted_now == 0 and pt is not None:
            # 本实例还没有任何安装链路：由点选触发新一轮 arm→mount→ack→采纳。
            tc.inject_tap(pt[0], pt[1])
        life = install_lifecycle(rows_a, 0, (ident_b or {}).get('ctx') or -1)
        stages = life['stages']
        install = {'attempt': attempt, 'instance_pid': pid,
                   'hit_point': list(pt) if pt else None,
                   'mount': (stages.get('mount') or {}).get('facts'),
                   'armed': (stages.get('armed') or {}).get('facts'),
                   'acked': (stages.get('acked') or {}).get('facts'),
                   'lifecycle_first_missing': life['first_missing'],
                   'adoption_count_instance': adopted_now,
                   'guard': 'body_restore_evidence(same instance + current identity + '
                            'product THERMO adoption)',
                   'product_adoption': evidence,
                   'selection': list(evidence['sel']) if isinstance(evidence, dict)
                   and evidence.get('source') == 'restore_ack' else None,
                   'readback': ident_b}
        # 失败指名：只读诊断与判据分开，判定权仍在统一守卫。
        if ident_b is None or ident_b.get('node') != NODE or ident_b.get('field') != FIELD:
            install['fail'] = 'current_identity_not_target'
            sel0 = None
            continue
        if not (isinstance(evidence, dict) and evidence.get('source') == 'restore_ack'):
            # 缺这一笔就只是"平台装了"，不是"独立消费者采用了"：同请求号的
            # `proxy restore ack accepted` 必须与 `THERMO_OHOS_RESTORE_ADOPTED`
            # （controller.takeRestoreAdoptionFact 经宿主 hilog 发出）逐字段相等，
            # ctx/node/v 等于读回权威当前身份，owner_version 等于本轮冻结基线。
            install['fail'] = 'window_adoption_not_product_confirmed'
            sel0 = None
            continue
        if _vb != version0:
            install['fail'] = 'install_advanced_owner'
            sel0 = None
            continue
        sel0 = list(evidence['sel'])
        install['fail'] = None
        break
    results['legs'].append({'leg': 'tap-install', 'selection': sel0,
                            'baseline_version': version0, 'install': install})
    if sel0 is None or install.get('fail') is not None:
        results['status'] = 'tap_install_unconfirmed'
        return save(1)
    _v0c, _fc, _sc, _ic = read_state_full()
    if _v0c != version0:
        results['status'] = 'install_advanced_owner'
        return save(1)
    results['legs'][-1]['evidence'] = leg_evidence(
        out, 'tap-install', pid, 0,
        {'sent': 'inject_tap(公共持留命中点) → arm→mount→ack→窗口采纳',
         'point': install.get('hit_point'), 'guard': install['guard'],
         'adoption_count_instance': install['adoption_count_instance'],
         'owner_version_before_leg': version0})
    # 键盘避让只影响表面原点；几何在每腿派生前重新读取，不在此投递任何按键
    # （旧实现发 2055=KEYCODE_DEL，会真删正文，属于验收自伤）。

    # ---- 2 输入：冻结 caret 上的插入，逐字节 + 版本恰 +2 ----
    version1, fields1, _s1, ident1 = read_state_full()
    note1 = fields1.get('note') or ''
    caret16 = sel0[0]
    byte_at = strict_utf16.utf16_to_byte_offset(note1.encode('utf-8'), caret16)
    expected1 = note1.encode('utf-8')[:byte_at] + b'AB' + note1.encode('utf-8')[byte_at:]
    fence_ab = vts._fence_marker(rows_for(pid))
    tc._m.uitest('text', 'AB')
    results['transactions'].append({'leg': 'insert-ab', 'version_before': version1,
                                    'fence': fence_ab.get('ts')})
    note2 = None
    fields2 = {}
    for _ in range(16):
        note2, fields2 = vts.read_note()
        if note2 is not None and note2.encode('utf-8') == expected1:
            break
        time.sleep(0.4)
    entry1 = {'leg': 'insert-ab', 'expected': expected1.decode('utf-8', 'replace'),
              'note': note2, 'version_before': version1,
              'version_after': fields2.get('_version')}
    entry1['version_delta'] = (fields2.get('_version', 0) - version1)
    entry1['exactly_once'] = entry1['version_delta'] == 2
    entry1['evidence'] = leg_evidence(
        out, 'insert-ab', pid, fence_ab,
        {'sent': "uitest uiInput text 'AB'（单次投递）", 'deliveries': 1,
         'frozen_caret_utf16': caret16, 'owner_version_before': version1})
    results['legs'].append(entry1)
    if note2 is None or note2.encode('utf-8') != expected1:
        results['status'] = 'insert_ab_not_read_back'
        return save(1)
    if not entry1['exactly_once']:
        entry1['fail'] = 'version_delta_mismatch'
        results['status'] = 'insert_ab_version_delta'
        return save(1)

    # ---- 拖选规划（accepted geo 事实，无固定屏幕阈值） ----
    # 输入腿可能把焦点交回输入框（node 24 同 field）：先核读回身份，不是本锚点
    # 就点一下切回（控制器会把绑定切回 TEXT 锚）。拖选坐标取**节点左缘文本区**
    # （"AB" 只有约 40vp 宽，以中心为基会两侧都钳到字尾 → 空选区）。
    _REACHABILITY_REASONS = frozenset((
        'hit_band_too_narrow', 'drag_start_occluded', 'drag_end_occluded',
        'drag_path_occluded'))

    def read_field_band_id():
        return accepted_field_band()

    def read_drag_plan():
        """读一次 live 事实并规划，返回 (plan, reason)。"""
        state = tc.readback_owner_state()
        geo = _m.parse_geo_section(state) if state else None
        if geo is None:
            return None, 'geo_section_absent'
        rec, why = _m.find_geo_record(geo, FIELD)
        if rec is None:
            return None, why or 'record_absent'
        origin = _m.surface_origin_px()
        return plan_drag_from_facts(rec, origin, geo['density'])

    def scroll_card_for_reachability():
        """无可达带时才滚动：路径取自容器当前可达带，起点逐轮抬高（躲开底部
        可能被遮挡的触摸区），每次核位移。

        返回 'displaced'（已移动，需重规划）、'scroll_basis_changed'（基准
        变化，重读事实）或具名原因；FIELD 始终不在几何里具名 field_absent，
        在位不动具名 no_displacement，都不称到顶。"""
        field_seen = False
        for _attempt in range(3):
            before = read_field_band_id()
            field_seen = field_seen or before is not None
            state = tc.readback_owner_state()
            geo = _m.parse_geo_section(state) if state else None
            rec, _w = _m.find_geo_record(geo, 'thermo-card-scroll') if geo else (None, None)
            origin = _m.surface_origin_px()
            if geo is None or rec is None or origin is None:
                time.sleep(0.8)
                continue
            ceilings = scroll_ceilings(rec)
            path = scroll_path_in_band(rec, origin, geo['density'],
                                       ceilings[_attempt % len(ceilings)])
            if path is None:
                return 'scroll_path_unavailable'
            tc._m.uitest('drag', str(path[0]), str(path[1]), str(path[2]), str(path[3]))
            time.sleep(1.2)
            after = read_field_band_id()
            field_seen = field_seen or after is not None
            if before is None or after is None:
                continue
            if before[0] != after[0] or before[1] != after[1]:
                return 'scroll_basis_changed'
            if band_displaced(before, after):
                return 'displaced'
        if not field_seen:
            return 'scroll_field_absent'
        return 'scroll_no_displacement'

    # ---- 3 非空替换：拖选非空安装 → 严格 oracle ----
    sel3 = None
    fence_sel3 = None
    delivery = {'delivered': False, 'reason': 'not_attempted', 'sends': 0}
    sent_plan = None
    sent_fence = None
    sent_version = None
    for round_i in range(3):
        # 身份预检（输入腿可能把焦点交回同 field 的输入框）：点锚切回并等稳。
        pt3, _why3 = ensure_presentation_visible()
        if pt3 is None:
            delivery['reason'] = _why3
            break
        _vs, _fs2, _ss2, ident_s = read_state_full()
        if ident_s is None or ident_s.get('node') != NODE:
            tc.inject_tap(pt3[0], pt3[1])
            time.sleep(1.5)
            _vs, _fs2, _ss2, ident_s = read_state_full()
            if ident_s is None or ident_s.get('node') != NODE:
                delivery['reason'] = 'identity_not_on_anchor'
                break
        # 事实规划：无可达带才滚动（核位移），有带则投递前重读核代际。
        # 未发送前允许重新读事实；一旦发送就退出规划循环（单手势）。
        plan, why = read_drag_plan()
        if plan is None:
            if why in _REACHABILITY_REASONS:
                scrolled = scroll_card_for_reachability()
                if scrolled in ('displaced', 'scroll_basis_changed'):
                    continue
                delivery['reason'] = scrolled
            else:
                delivery['reason'] = why
            break
        plan2, why2 = read_drag_plan()
        if plan2 is None or plan2['geo_id'] != plan['geo_id']:
            delivery['reason'] = why2 if plan2 is None else 'geo_changed_during_plan'
            continue
        plan = plan2
        version_s, _fs3, _ss3, _is3 = read_state_full()
        fence_s = vts._fence_marker(rows_for(pid))
        tc._m.uitest('drag', str(plan['x1']), str(plan['y1']),
                     str(plan['x2']), str(plan['y2']))
        delivery['delivered'] = True
        delivery['sends'] += 1
        delivery['reason'] = 'sent_awaiting_adopt'
        sent_plan = plan
        sent_fence = fence_s
        sent_version = version_s
        break
    if not delivery['delivered']:
        # 未投递：几何/事实原因具名，连同 A2 原件一起归档。
        results['nonempty_select_delivery'] = delivery
        results['a2_release_gate'] = capture_lease_release(pid, out)
        results['status'] = 'nonempty_select_undelivered:' + delivery['reason']
        return save(1)
    # 已投递后只观察：有界等待一次采纳，不再发任何手势，不收键盘不改选区。
    sel3, _rows3 = vts.wait_confirmed(pid, sent_fence, non_empty=True, rounds=10,
                                      expect={'field': FIELD, 'owner_version': sent_version},
                                      archive={'dir': out, 'required': []},
                                      leg='3-nonempty-select')
    results['legs'].append({'leg': 'nonempty-select', 'selection': sel3,
                            'delivered': True,
                            'drag': [sent_plan['x1'], sent_plan['y1'],
                                     sent_plan['x2'], sent_plan['y2']],
                            'debug': True})
    if sel3 is None or sel3[0] >= sel3[1]:
        # 链路到此为止，顺手取 A2 第③组门的设备原件（放在失败出口而不是链路中间：
        # Home/回前台会换掉编辑会话条件，成功路径上不该受它影响）。
        delivery['reason'] = 'sent_unadopted'
        results['nonempty_select_delivery'] = delivery
        results['a2_release_gate'] = capture_lease_release(pid, out)
        results['status'] = 'nonempty_selection_unconfirmed'
        return save(1)
    fence_sel3 = sent_fence
    results['legs'].append({
        'leg': 'nonempty-select', 'selection': sel3,
        'evidence': leg_evidence(out, 'nonempty-select', pid, fence_sel3,
                                 {'sent': 'uitest uiInput drag 左缘文本区 → +80px（非空拖选）',
                                  'frozen_selection': list(sel3),
                                  'judgment_rows_archive':
                                      str(out / '3-nonempty-select-judgment-rows.txt')})})
    note3, _f3 = vts.read_note()
    if note3 is None:
        results['status'] = 'note_unreadable_before_replace'
        return save(1)
    expected3 = strict_utf16.expected_replacement(note3.encode('utf-8'),
                                                  sel3[0], sel3[1], 'X')
    version3, _fv3 = tc.read_state()
    fence_x = vts._fence_marker(rows_for(pid))
    tc._m.uitest('text', 'X')
    results['transactions'].append({'leg': 'replace-x', 'version_before': version3,
                                    'frozen_selection': list(sel3)})
    note4 = None
    fields4 = {}
    for _ in range(16):
        note4, fields4 = vts.read_note()
        if note4 is not None and note4.encode('utf-8') == expected3:
            break
        time.sleep(0.4)
    entry3 = {'leg': 'replace-x', 'expected': expected3.decode('utf-8', 'replace'),
              'note': note4, 'frozen_selection': list(sel3),
              'version_delta': fields4.get('_version', 0) - version3}
    entry3['evidence'] = leg_evidence(
        out, 'replace-x', pid, fence_x,
        {'sent': "uitest uiInput text 'X'（单次投递，替换冻结非空选区）", 'deliveries': 1,
         'frozen_selection': list(sel3), 'owner_version_before': version3})
    results['legs'].append(entry3)
    if note4 is None or note4.encode('utf-8') != expected3:
        results['status'] = 'exact_replace_failed'
        return save(1)
    if entry3['version_delta'] != 1:
        entry3['fail'] = 'version_delta_mismatch'
        results['status'] = 'replace_version_delta'
        return save(1)

    # ---- 4 公开改版：公开通道 SET_NOTE（外部路径） ----
    external = '外部改版 thermΩ'
    version5, _f5 = tc.read_state()
    fence_ext = vts._fence_marker(rows_for(pid))
    rec = vts.set_note_external(external)
    results['transactions'].append({'leg': 'external-set', 'applied': rec.get('applied')})
    if not rec.get('applied'):
        results['status'] = 'external_set_refused'
        return save(1)
    note5 = None
    for _ in range(12):
        note5, _ff5 = vts.read_note()
        if note5 == external:
            break
        time.sleep(0.4)
    results['legs'].append({
        'leg': 'external-set', 'note': note5,
        'evidence': leg_evidence(out, 'external-set', pid, fence_ext,
                                 {'sent': 'INVOKE <当前版本> SET_NOTE（公开通道外部改版）',
                                  'expected_version': version5,
                                  'text_hex': external.encode('utf-8').hex()},
                                 rec)})
    if note5 != external:
        results['status'] = 'external_set_failed'
        return save(1)

    # ---- 5 改版续写：重锚（新安装确认，基线=改版后版本）→ 注入 'N' ----
    pt5, _why5 = ensure_presentation_visible()
    if pt5 is None:
        results['status'] = 'presentation_anchor_lost_after_external:' + _why5
        return save(1)
    version_pe, _fp, _sp, _ip = read_state_full()
    fence5 = vts._fence_marker(rows_for(pid))
    tc.inject_tap(pt5[0], pt5[1])
    sel5, _rows5 = vts.wait_confirmed(pid, fence5, non_empty=False, rounds=30,
                                      expect={'field': FIELD, 'owner_version': version_pe},
                                      archive={'dir': out, 'required': []},
                                      leg='5-post-external-install')
    results['legs'].append({
        'leg': 'post-external-install', 'selection': sel5,
        'evidence': leg_evidence(out, 'post-external-install', pid, fence5,
                                 {'sent': 'inject_tap(改版后重锚) → 新安装确认',
                                  'owner_version_before_leg': version_pe,
                                  'judgment_rows_archive':
                                      str(out / '5-post-external-install-judgment-rows.txt')})})
    if sel5 is None:
        results['status'] = 'post_external_install_unconfirmed'
        return save(1)
    expected5 = strict_utf16.expected_replacement(external.encode('utf-8'),
                                                  sel5[0], sel5[1], 'N')
    version6, _f6 = tc.read_state()
    fence_n = vts._fence_marker(rows_for(pid))
    tc._m.uitest('text', 'N')
    results['transactions'].append({'leg': 'continue-input', 'version_before': version6})
    note6 = None
    fields6 = {}
    for _ in range(16):
        note6, fields6 = vts.read_note()
        if note6 is not None and note6.encode('utf-8') == expected5:
            break
        time.sleep(0.4)
    entry5 = {'leg': 'continue-input', 'expected': expected5.decode('utf-8', 'replace'),
              'note': note6, 'frozen_selection': list(sel5),
              'version_delta': fields6.get('_version', 0) - version6}
    entry5['evidence'] = leg_evidence(
        out, 'continue-input', pid, fence_n,
        {'sent': "uitest uiInput text 'N'（改版后单次续写）", 'deliveries': 1,
         'frozen_selection': list(sel5), 'owner_version_before': version6})
    results['legs'].append(entry5)
    if note6 is None or note6.encode('utf-8') != expected5:
        results['status'] = 'continue_input_failed'
        return save(1)
    if entry5['version_delta'] != 1:
        entry5['fail'] = 'version_delta_mismatch'
        results['status'] = 'continue_version_delta'
        return save(1)

    # ---- 6 拒绝保旧：旧版本公开写被 owner 拒，note 与版本都不变 ----
    version7, fields7 = tc.read_state()
    stale = version7 - 1
    fence7 = vts._fence_marker(rows_for(pid))
    rec7 = tc.invoke('SET_NOTE', stale, [('text', 'STRING', '过期写入')])
    note7, _ff7 = vts.read_note()
    version8, _f8 = tc.read_state()
    entry6 = {'leg': 'stale-write-refused', 'applied': rec7.get('applied'),
              'note_kept': note7 == (fields7.get('note')),
              'version_kept': version8 == version7,
              'evidence': leg_evidence(
                  out, 'stale-write-refused', pid, fence7,
                  {'sent': 'INVOKE <version-1> SET_NOTE（陈旧版本外部写）',
                   'expected_version': stale, 'owner_version_before': version7,
                   'owner_version_after': version8},
                  rec7)}
    results['legs'].append(entry6)
    if rec7.get('applied'):
        entry6['fail'] = 'stale_write_accepted'
        results['status'] = 'stale_write_not_refused'
        return save(1)
    if not entry6['note_kept'] or not entry6['version_kept']:
        results['status'] = 'stale_write_mutated_owner'
        return save(1)

    # A2 第③组门的设备原件在**成功路径**上也必须取，且按链路自身的退役围栏观测
    # （r14/r15：末腿后再 Home 只能等到"表已空"，真实持留量在改版退役那刻释放）。
    results['a2_release_gate'] = capture_lease_release(pid, out, fence_ext)
    if results['a2_release_gate'].get('fail'):
        results['status'] = 'a2_release_gate_failed'
        return save(1)
    results['evidence_gaps'] = evidence_gaps(results['legs'])
    if results['evidence_gaps']:
        results['status'] = 'per_leg_evidence_incomplete'
        return save(1)
    results['status'] = 'ok'
    return save(0)


if __name__ == '__main__':
    sys.exit(main())

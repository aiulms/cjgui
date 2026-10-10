#!/usr/bin/env python3
"""Pharos 鸿蒙可视编辑闭环设备验收（2026-10-05 D 组重写，非草稿）。

同一最终 normal HAP（--target 上的当前实例；不硬编码 bundle/PID）：
  源码基线 → 可视点击定位 → 中文/emoji/多标量簇注入 → 同片段非空替换 →
  退格删除 → Undo/Redo（toolbar，版本单调推进+精确前后态）→ 公开 Agent
  REPLACE_RANGE → 改版后免点击续写（硬失败门）→ 正文/备注往返（P2 隔离）→
  无编辑双模式往返（P1）→ 切源码 → 保存（完整回包）→ 正常关闭/新实例重开
  （按解析到的 bundle，新 PID）→ 全文精确 → 继续编辑。

严格判据：每次注入前冻结 owner 版本+hex，期望正文由 strict oracle 独立计算
（UTF-16 范围 × UTF-8 存储），实际必须**逐字节等于**期望且版本 +1；不匹配即
硬失败。事务计数按注入意图配对（一次注入可产生多笔 kind51）。转发仅在 truly
本轮创建时登记，finally 只释放自己的三元组。

用法：python3 verify_pharos_visual_edit.py --target 127.0.0.1:5555 --out <dir>
"""
import argparse
import hashlib
import importlib.util
import json
import os
import re
import subprocess
import sys
import time
from pathlib import Path

HERE = Path(__file__).resolve().parent

# 画面反馈开关（显式，不改默认行为）：设 `PHAROS_VISUAL_EDIT_SHOTS=1` 后，每条判据
# 在判定当刻额外截一帧全屏（`snapshot_display` 只截屏、不投递事件），路径与 sha256
# 记进该条 leg。AGENTS 的"可见编辑需正常窗口输入、实际正文读回与画面对应"由此可
# 逐条复核，而不是只看字节读回。
SHOT = {'dir': None, 'target': None}


def capture_frame(label):
    if SHOT['dir'] is None or SHOT['target'] is None:
        return None
    slug = re.sub(r'[^A-Za-z0-9_.-]+', '_', label)[:44]
    remote = f'/data/local/tmp/pve_{slug}.jpeg'
    local = SHOT['dir'] / f"{_frame_serial['n']}-{slug}.jpeg"
    _frame_serial['n'] += 1
    try:
        cap = subprocess.run([HDC, '-t', SHOT['target'], 'shell',
                              f'snapshot_display -f {remote}'],
                             capture_output=True, text=True, timeout=45)
        if cap.returncode != 0:
            return {'fail': f'snapshot_rc{cap.returncode}'}
        rx = subprocess.run([HDC, '-t', SHOT['target'], 'file', 'recv', remote, str(local)],
                            capture_output=True, text=True, timeout=45)
        if rx.returncode != 0 or not local.exists() or local.stat().st_size == 0:
            return {'fail': 'snapshot_recv_failed'}
        subprocess.run([HDC, '-t', SHOT['target'], 'shell', f'rm -f {remote}'],
                       capture_output=True, timeout=20)
        return {'screen': local.name, 'screen_bytes': local.stat().st_size,
                'screen_sha256': hashlib.sha256(local.read_bytes()).hexdigest()}
    except Exception as e:
        return {'fail': repr(e)}


_frame_serial = {'n': 0}


def _frame_evidence_gate():
    """Shots-enabled runs only: every leg must carry a unique SHA-verified frame.

    r18 工具修补：`capture_frame` 曾以 `len(_frame_serial)`（字典长度恒 1）当序号，
    重复 label 会覆盖同一文件（58 条记录只有 57 个独立文件）。序号修为单调计数后，
    这里最终再核：路径唯一、文件存在且非空、字节数与 SHA256 与记录一致。缺帧具名
    为缺失（`frame_missing` / `frame_<fail>`），不拿后截图补造旧时刻。未开快门
    （`PHAROS_VISUAL_EDIT_SHOTS` 未设）的旧链路如实记 `shots: disabled`，不判红。
    返回具名缺口列表；调用方把它并入 `failures`。
    """
    gaps = []
    try:
        legs = results.get('legs', [])
    except Exception:
        return ['frame_results_unreadable']
    if SHOT.get('dir') is None:
        try:
            results['frame_evidence'] = {'shots': 'disabled',
                                         'legs': len(legs)}
        except Exception:
            pass
        return gaps
    seen = {}
    dups = set()
    for leg in legs:
        name = leg.get('check', '?') if isinstance(leg, dict) else '?'
        fb = leg.get('screen_feedback') if isinstance(leg, dict) else None
        if not isinstance(fb, dict):
            gaps.append(f'{name}:frame_missing')
            continue
        if fb.get('fail'):
            gaps.append(f"{name}:frame_{fb['fail']}")
            continue
        fn = fb.get('screen')
        if not fn:
            gaps.append(f'{name}:frame_name_absent')
            continue
        if fn in seen:
            dups.add(fn)
        else:
            seen[fn] = name
        p = SHOT['dir'] / fn
        try:
            data = p.read_bytes()
        except Exception:
            gaps.append(f'{name}:frame_unreadable:{fn}')
            continue
        if not data:
            gaps.append(f'{name}:frame_empty:{fn}')
            continue
        try:
            want_n = int(fb.get('screen_bytes', len(data)))
        except Exception:
            want_n = len(data)
        if len(data) != want_n:
            gaps.append(f'{name}:frame_bytes_mismatch:{fn}')
        if hashlib.sha256(data).hexdigest() != fb.get('screen_sha256'):
            gaps.append(f'{name}:frame_sha_mismatch:{fn}')
    for fn in sorted(dups):
        gaps.append(f'frame_path_not_unique:{fn}')
    try:
        results['frame_evidence'] = {'shots': 'enabled',
                                     'legs': len(legs),
                                     'frames': len(seen),
                                     'gaps': gaps}
    except Exception:
        pass
    return gaps

ap = argparse.ArgumentParser()
ap.add_argument('--target', required=('--self-test-negative' not in sys.argv))
ap.add_argument('--out', required=('--self-test-negative' not in sys.argv))
ap.add_argument('--port', type=int, default=28991)
ap.add_argument('--negative-control', choices=['none', 'zero-input'], default='none',
                help='zero-input：全部注入/点击/拖动改为 no-op——验收必须整体变红，'
                     '证明判据对「零输入」有判别力（负控反演）。')
args, _unknown = ap.parse_known_args()
KEEP_GOING = '--keep-going' in sys.argv

SELF_TEST = '--self-test-negative' in sys.argv

# 自检模式**不碰设备**：--target/--out 在该模式下非必填，因此不能解析它们、
# 不能建输出目录、也不能导入 host 模块。设备接线整体在此守卫之内。
# 判据自检一律走文件末尾的 _self_test()，它调用的是本模块真实判定函数
# （expected_insert / utf16_to_byte / grapheme_cluster_before /
# latest_installed_selection），不再另立一份影子副本。
if not SELF_TEST:
    target = args.target.strip()
    OUT = Path(args.out)
    OUT.mkdir(parents=True, exist_ok=True)
    if os.environ.get('PHAROS_VISUAL_EDIT_SHOTS'):
        SHOT['dir'] = OUT
        SHOT['target'] = target
    PORT = args.port
    failures = []

    spec = importlib.util.spec_from_file_location('vdo', HERE / 'verify_pharos_dual_owner.py')
    vdo = importlib.util.module_from_spec(spec)
    sys.modules['vdo'] = vdo
    spec.loader.exec_module(vdo)
    m = vdo.m

    HDC = m.HDC

    NEG = args.negative_control == 'zero-input'
    _real_uitest = m.uitest


def uitest_maybe(*a, **kw):
    """零输入负控开关：NEG 时全部系统注入 no-op，验收必须整体变红。"""
    if NEG:
        return None
    return _real_uitest(*a, **kw)
BODY = 'pharos-editor-block'
failures = []
results = {'legs': [], 'cost': {}}
# 本腿当前启动实例；每次（重）启动确认后刷新。freeze/保存证据据此限定同实例行。
ACTIVE_INSTANCE = {'pid': None, 'fence': None}
t0 = time.time()


def check(name, ok, detail='', snapshot=None):
    print(f"  {'OK  ' if ok else 'FAIL'} {name}" + (f': {detail}' if detail else ''))
    # E 复核：每条判据作为最小事实包记录，连同 run.json 一起归档——可独立复判，
    # 不靠摘要。snapshot 为判定点的冻结快照 (version, hex) 或完整 dict，由调用方
    # 在判定当时传入。**本函数绝不另读 owner**——重读只能得到检查时刻的状态，
    # 不能冒充判定快照（复核禁令）。无快照时如实标记缺失，不捏造版本号，
    # 更不只存 hash 字符串代替完整正文。
    leg = {'check': name, 'ok': bool(ok), 'detail': str(detail),
           'ts': round(time.time() - t0, 3)}
    if snapshot is not None:
        try:
            if isinstance(snapshot, (list, tuple)) and len(snapshot) == 2:
                sv, shx = snapshot
                leg['owner_version'] = sv
                leg['owner_hex'] = shx
            elif isinstance(snapshot, dict):
                if 'owner_version' in snapshot:
                    leg['owner_version'] = snapshot['owner_version']
                if 'owner_hex' in snapshot:
                    leg['owner_hex'] = snapshot['owner_hex']
                if 'version' in snapshot and 'owner_version' not in leg:
                    leg['owner_version'] = snapshot['version']
                if 'hex' in snapshot and 'owner_hex' not in leg:
                    leg['owner_hex'] = snapshot['hex']
            else:
                leg['owner_snapshot_unparseable'] = True
        except Exception as e:
            leg['owner_snapshot_error'] = repr(e)
    else:
        leg['owner_snapshot_absent'] = True
    frame = capture_frame(name)
    if frame is not None:
        leg['screen_feedback'] = frame
    results['legs'].append(leg)
    if not ok:
        failures.append(name)
    return ok


def owner():
    v, hx = m.read_all(PORT)
    return v, hx


def body_of(hexstr):
    return bytes.fromhex(hexstr).decode('utf-8', 'replace')


def wait_owner_advance(prev_v, timeout=15.0):
    """有界等待 owner 版本 > prev_v；返回 (v, hex) 或 (None, None)。"""
    deadline = time.time() + timeout
    while time.time() < deadline:
        v, hx = owner()
        if v is not None and v > prev_v:
            return v, hx
        time.sleep(0.25)
    return None, None


def wait_owner_value(prev_v, want, timeout=10.0):
    """有界等待 owner 版本 > prev_v 且全文精确等于 want；返回 (v, hex, ok)。"""
    deadline = time.time() + timeout
    lv, lh = None, None
    while time.time() < deadline:
        v, hx = owner()
        lv, lh = v, hx
        if (v is not None and v > prev_v and hx is not None
                and bytes.fromhex(hx) == want):
            return v, hx, True
        time.sleep(0.1)
    return lv, lh, False


def _utf16_units(s):
    units = 0
    for c in s:
        units += 2 if ord(c) >= 0x10000 else 1
    return units


def _take_chunk(text, start, nbytes):
    """text[start:] 取总 UTF-8 字节恰为 nbytes 的整字符前缀；无则 None。
    UTF-8 首字节定长，合法划分唯一。"""
    acc = 0
    i = start
    while i < len(text):
        acc += len(text[i].encode('utf-8'))
        i += 1
        if acc == nbytes:
            return text[start:i]
        if acc > nbytes:
            return None
    return None


def verify_stroke_walk(prev_bytes, caret16, span16, text, strokes, prev_v):
    """纯判定：按观测笔序核**各笔范围链/版本链/合法输入前缀**。
    strokes 为 [((a16,b16), nbytes, owner_v)] 观测序；range 取平台本笔范围，
    各笔范围自成一坐标系（正文/备注腿实测：delta 范围与冻结 caret 可不同基准），
    最终位置由调用方以冻结跨度独立算出的期望全文精确钉住，天然拒绝错位注入。
    返回 (ok, reason, end_caret16)。"""
    if not text:
        return False, 'empty_text', None
    if not strokes:
        return False, 'no_strokes_observed', None
    if len(strokes) > len(text):
        return False, 'more_strokes_than_chars', None
    if strokes[0][2] != prev_v + 1:
        return False, 'first_stroke_not_next_version', None
    if utf16_to_byte(prev_bytes, caret16) is None:
        return False, 'caret_splits_scalar', None
    if span16 is not None:
        if span16[0] != caret16:
            return False, 'span_start_not_caret', None
        e_by = utf16_to_byte(prev_bytes, span16[1])
        if e_by is None or e_by < utf16_to_byte(prev_bytes, span16[0]):
            return False, 'span_splits_scalar', None
    run16 = None
    consumed = 0
    for i, ((a16, b16), n, v) in enumerate(strokes):
        if v != prev_v + i + 1:
            return False, 'version_chain_gap', None
        if i == 0:
            if span16 is not None:
                if (a16, b16) != (span16[0], span16[1]):
                    return False, 'first_range_not_frozen_span', None
                run16 = span16[0]
            else:
                if a16 != b16 or a16 < 0:
                    return False, 'insert_first_range_not_collapsed', None
                run16 = a16
        elif (a16, b16) != (run16, run16):
            return False, 'range_not_at_running_caret', None
        chunk = _take_chunk(text, consumed, n)
        if chunk is None:
            return False, 'chunk_not_legal_prefix', None
        consumed += len(chunk)
        run16 = run16 + _utf16_units(chunk)
    if consumed != len(text):
        return False, 'input_not_fully_consumed', None
    return True, 'ok', run16


def pair_injection_strokes(node, prev_v, prev_hex, caret16, span16, text,
                           reader=None, timeout=15.0, identity=None):
    """单次投递 text 并逐笔配对。span16=None 表纯插入，否则首笔为替换跨度。
    逐笔事实取自同窗 `ime range delta`（范围/字节）与同笔 ADOPTED2（owner_version
    与采纳后折叠落点），两者按序 1:1；不依赖 EDIT 行（该行仅部分路径写）。
    reader 读被投递 owner 的 (版本, 全文字节)，缺省正文 owner（备注腿传备注读法）。
    identity 为本腿权威当前身份（读回 live 编辑身份：ctx/gen/binding/kind），提供时
    每笔采纳行的冻结来源必须与之相等（unverified/缺失/错ctx/gen/binding 具名拒绝），
    且采纳 sel 必须按冻结意图推进（插入自 caret16、替换自 span16[0]，按每笔真实
    字节取合法前缀累计 UTF-16 单位）。
    返回 (ok, detail, final_v, final_hx)。detail 含逐笔原行快照与失败原因。
    """
    read = reader if reader is not None else owner
    base = bytes.fromhex(prev_hex)
    want = expected_insert(base, caret16, span16[1] if span16 else caret16, text)
    if want is None:
        return False, {'fail': 'expectation_not_computable', 'strokes': []}, prev_v, prev_hex
    rows_pre = m.hilog_rows()
    fence = rows_pre[-1] if rows_pre else ''
    uitest_maybe('text', text)
    t0 = time.time()
    while time.time() - t0 < timeout:
        try:
            v, hx = read()
        except Exception:
            v, hx = None, None
        if (v is not None and v > prev_v and hx is not None
                and bytes.fromhex(hx) == want):
            break
        time.sleep(0.1)
    else:
        return False, {'fail': 'settle_timeout', 'strokes': []}, prev_v, prev_hex
    time.sleep(1.0)
    try:
        final_v, final_hx = read()
    except Exception:
        final_v, final_hx = None, None
    if final_hx is None or bytes.fromhex(final_hx) != want:
        return False, {'fail': 'final_moved_during_quiet', 'strokes': []}, final_v, final_hx
    rows = m.hilog_rows()
    try:
        si = vdo.fence_index(rows, fence) if fence else 0
    except Exception as e:
        return False, {'fail': 'fence_evicted', 'strokes': [], 'reason': repr(e)}, final_v, final_hx
    pid = ACTIVE_INSTANCE.get('pid')
    ad_re = re.compile(
        r"CJGUI_OWNED_SELECTION_ADOPTED2 node=(-?\d+) resource=(-?\d+) kind=(\d+) "
        r"sel=(\d+):(\d+) projection=(-?\d+) binding=(\d+)"
        r"(?: owner_version=(-?\d+))?(?: source_ctx=(\S+) source_gen=(\S+))?")
    deltas, adoptions = [], []
    for r in rows[si:]:
        if pid is not None and vdo.row_pid(r) != pid:
            continue
        m1 = re.search(r"ime range delta node=(\d+) range=(\d+):(\d+) bytes=(\d+)", r)
        if m1 and int(m1.group(1)) == node:
            deltas.append({'range': (int(m1.group(2)), int(m1.group(3))),
                           'nbytes': int(m1.group(4)), 'row': r[-220:]})
            continue
        m2 = ad_re.search(r)
        if m2 and int(m2.group(1)) == node:
            if m2.group(8) is None:
                return False, {'fail': 'adoption_missing_owner_version',
                               'strokes': []}, final_v, final_hx
            adoptions.append({'sel': (int(m2.group(4)), int(m2.group(5))),
                              'owner_version': int(m2.group(8)),
                              'source_ctx': m2.group(9), 'source_gen': m2.group(10),
                              'binding': int(m2.group(7)), 'projection': int(m2.group(6)),
                              'resource': int(m2.group(2)), 'kind': int(m2.group(3)),
                              'row': r[-220:]})
            continue
        if ('PHAROS_OHOS_EDIT_REFUSED' in r or 'local_projection_stale' in r
                or re.search(r"PHAROS_OHOS_EDIT\b.*\bapplied=false\b", r)):
            return False, {'fail': 'refused_edit_in_window', 'strokes': [],
                           'row': r[-220:]}, final_v, final_hx
    if not deltas or len(deltas) > len(text):
        return False, {'fail': 'delta_count_out_of_range', 'strokes': [],
                       'ndeltas': len(deltas)}, final_v, final_hx
    if len(adoptions) != len(deltas):
        return False, {'fail': 'adoption_count_mismatch', 'strokes': [],
                       'ndeltas': len(deltas),
                       'nadoptions': len(adoptions)}, final_v, final_hx
    strokes = [(d['range'], d['nbytes'], a['owner_version'])
               for d, a in zip(deltas, adoptions)]
    if strokes[-1][2] != final_v:
        return False, {'fail': 'last_stroke_not_final_version', 'strokes': [],
                       'last_v': strokes[-1][2]}, final_v, final_hx
    ok, reason, end16 = verify_stroke_walk(
        base, caret16, span16, text, strokes, prev_v)
    # 有限修（2026-10-06）：范围链/合法前缀之外，逐笔核对采纳的**来源身份**与
    # **caret 推进**。二者都以冻结意图与读回权威身份为基准，不采纳行自身可缺省。
    src_fail = None
    if ok and identity is not None:
        for a in adoptions:
            if a['source_ctx'] is None or a['source_gen'] is None:
                src_fail = 'adoption_source_missing'
                break
            try:
                sctx, sgen = int(a['source_ctx']), int(a['source_gen'])
            except ValueError:
                src_fail = 'adoption_source_unverified'
                break
            if ((identity.get('ctx') is not None and sctx != identity['ctx'])
                    or (identity.get('gen') is not None and sgen != identity['gen'])):
                src_fail = 'adoption_source_not_authoritative'
                break
            if (identity.get('binding') is not None
                    and a['binding'] != identity['binding']):
                src_fail = 'adoption_binding_not_authoritative'
                break
    caret_fail = None
    if ok:
        run16 = span16[0] if span16 else caret16
        consumed = 0
        for dd, ad in zip(deltas, adoptions):
            chunk = _take_chunk(text, consumed, dd['nbytes'])
            if chunk is None:
                caret_fail = 'adoption_caret_chunk_not_legal_prefix'
                break
            consumed += len(chunk)
            run16 += _utf16_units(chunk)
            if ad['sel'] != (run16, run16):
                caret_fail = 'adoption_caret_not_intent_progression'
                break
    detail = {'fail': None if ok else reason,
              'want': want.hex(),
              'before_hex': prev_hex,
              'after_hex': final_hx,
              'end_caret16': end16,
              'strokes': [{'v': st[2], 'range': [st[0][0], st[0][1]], 'nbytes': st[1],
                           'sel': list(ad['sel']),
                           'source_ctx': ad['source_ctx'], 'source_gen': ad['source_gen'],
                           'binding': ad['binding'], 'projection': ad['projection'],
                           'delta_row': dd['row'], 'adoption_row': ad['row']}
                          for st, dd, ad in zip(strokes, deltas, adoptions)]}
    if not ok:
        return False, detail, final_v, final_hx
    if src_fail or caret_fail:
        detail['fail'] = src_fail or caret_fail
        detail['authority'] = {k: identity.get(k) for k in
                               ('ctx', 'gen', 'binding')} if identity else None
        return False, detail, final_v, final_hx
    detail['settle_s'] = round(time.time() - t0, 2)
    detail['summary'] = ';'.join(
        'v%d[%d:%d]+%dB' % (v, a, b, n) for ((a, b), n, v) in strokes)
    return True, detail, final_v, final_hx


# ---- 纯 oracle（D 复核：动作前冻结，独立计算期望；可离线负控） ----

def utf16_to_byte(body: bytes, u16: int):
    """owner UTF-8 字节串上的 UTF-16 码元偏移 → 字节偏移；越界/劈开代理对 None。"""
    text = body.decode('utf-8', errors='replace')
    units = 0
    for idx, ch in enumerate(text):
        if units == u16:
            return len(text[:idx].encode('utf-8'))
        units += 2 if (ord(ch) >= 0x10000) else 1
    if units == u16:
        return len(text.encode('utf-8'))
    return None


def expected_insert(body: bytes, s16: int, e16: int, text: str):
    """冻结 UTF-16 选区 [s16,e16) 上 text 的插入（s==e）或替换 → 期望 UTF-8
    字节。端点劈开代理对/越界 → None（具名拒绝，不猜目标）。"""
    bs = utf16_to_byte(body, s16)
    be = utf16_to_byte(body, e16)
    if bs is None or be is None or be < bs:
        return None
    return body[:bs] + text.encode('utf-8') + body[be:]


def grapheme_cluster_before(body: bytes, byte_caret: int):
    """caret 字节位前的一个字素簇（RI 对 / ZWJ 链 / 组合链 / 单标量）。
    返回 (start, cluster_str)；边界非法时 None。"""
    import unicodedata
    text = body.decode('utf-8', errors='replace')
    chars = len(body[:byte_caret].decode('utf-8', errors='ignore'))
    if chars == 0 or chars > len(text):
        return None
    end = chars
    start = end - 1
    if start < 0:
        return None

    def is_extend(ch):
        return unicodedata.combining(ch) != 0 or ch in ('\u200d', '\ufe0f', '\ufe0e')

    while start > 0 and is_extend(text[start]):
        start -= 1

    def is_ri(ch):
        return '\U0001F1E6' <= ch <= '\U0001F1FF'

    if is_ri(text[end - 1]) and start > 0 and is_ri(text[start - 1]) and end - start == 1:
        start -= 1
    while start > 0 and text[start - 1] == '\u200d':
        start -= 2
        while start > 0 and is_extend(text[start]):
            start -= 1
    return start, text[start:end]


# 冻结选区不再自行拼接日志。直接调用既有 `vdo.body_restore_evidence` 及共享
# 身份/生命周期原语（`_mount_lifecycle`、`_identity_mismatch` 在其内部使用），
# 保留两条合法路径：
#   ① 显式恢复票 ACK + 同请求窗口 ADOPTED；
#   ② 挂载观测 + 匹配窗口采纳。
# 使用同次公开回包的当前身份（identity_hint）、冻结 owner 版本（owner_version）、
# 每腿预期表面→（节点，字段，owner 域）的显式路由表。调用方必须按本腿预期
# 传入 surface，不得全局默认、不得接受任意当前焦点：
#   source  正文源码面（107/body，main owner）；
#   visual  正文可视面（190/scroll-content，main owner；rebindPreviewSession 绑定）；
#   note    备注面（313/note-field，note owner；当前备注流用直接注入未调 freeze，
#           接入时调用方须显式传 surface='note' 并提供 note 版本）。
# （指导：不能全局把107改190；正文与备注使用各自 owner。）
SURFACE_TARGETS = {
    'source': {'node': 107, 'field': 'pharos-editor-body', 'owner': 'main'},
    'visual': {'node': 190, 'field': 'pharos-editor-scroll-content', 'owner': 'main'},
    'note': {'node': 313, 'field': 'pharos-document-note', 'owner': 'note'},
}
BODY_NODE = 107


def freeze_body_selection(prev_v=None, timeout_s=3.0,
                        use_action_fence=False, surface=None,
                        instance_pid=None, instance_fence=None):
    """经既有恢复证据机制冻结当前可写落点，返回 (sel, decision, aux).

    sel 为 (start16, end16) 或 None；decision 为 body_restore_evidence 的原样
    返回（成功或具名拒绝）；aux 含 fence/adopted_before/surface/body_node 及
    同次判定的 decision_snap/confirm_snap 原回包，供调用方归档（归档失败具名）。
    每轮用新鲜 hilog + 同轮公开回包重判；身份在观察期间变化则继续等待而非借用.
    surface 必显式指定（'source'|'visual'|'note'），据路由表取对应节点；
    None 或未知值直接具名拒绝（防止误收任意当前焦点）。
    owner_version 缺省时读当前对应 owner；调用方已有冻结基线时应显式传入。
    use_action_fence=True 时另设时间围栏与采纳计数基线（仅"本动作新建证据"
    场景用；稳定挂载注入不得设，否则把当前有效采纳当历史排除）。
    本函数只做**新建冻结**（要求采纳与版本精确匹配）。同一挂载上的连续续写
    以调用方维护的已核对后像链推进，换焦/换绑/外部改版后必须重新调用本函数。
    """
    if surface not in SURFACE_TARGETS:
        return None, {'source': 'freeze_surface_unspecified',
                      'reason': f'surface must be one of {sorted(SURFACE_TARGETS)}'}, \
               {'fence': '', 'adopted_before': 0, 'decision_snap': None,
                'confirm_snap': None, 'surface': surface, 'body_node': None}
    body_node = SURFACE_TARGETS[surface]['node']
    _ip = instance_pid if instance_pid is not None else ACTIVE_INSTANCE.get('pid')
    if _ip is not None:
        _ip = int(_ip)
    if prev_v is None:
        prev_v, _hx = owner()
    if use_action_fence:
        fence = vdo.log_fence()
        adopted_before = vdo.last_adopted_count()
    elif instance_fence is not None:
        fence = instance_fence
        adopted_before = 0
    else:
        _fb = ACTIVE_INSTANCE.get('fence')
        fence = _fb if _fb else ''
        adopted_before = 0
    deadline = time.time() + timeout_s
    last_decision = None
    last_aux = {'fence': fence, 'adopted_before': adopted_before,
                'decision_snap': None, 'confirm_snap': None, 'surface': surface,
                'body_node': body_node, 'instance_pid': _ip}
    while time.time() < deadline:
        rows = m.hilog_rows()
        try:
            since = vdo.fence_index(rows, fence)
        except Exception as e:
            last_decision = {'source': 'fence_evidence_lost', 'reason': repr(e)}
            break
        snap = vdo.public_snapshot(PORT) or {}
        hint = snap.get('editing')
        last_aux['decision_snap'] = snap
        decision = vdo.body_restore_evidence(rows, since, body_node, adopted_before,
                                             None, prev_v, identity_hint=hint,
                                             instance_pid=_ip)
        last_decision = decision
        src = (decision or {}).get('source')
        if src in ('restore_ack', 'mount_snapshot'):
            confirm = vdo.public_snapshot(PORT) or {}
            last_aux['confirm_snap'] = confirm
            if confirm.get('editing') != hint:
                time.sleep(0.4)
                continue
            sel = (decision or {}).get('sel')
            if sel is not None:
                return tuple(sel), decision, dict(last_aux)
            return None, decision, dict(last_aux)
        if src is not None and 'no_current_identity' in src:
            return None, decision, dict(last_aux)
        time.sleep(0.8)
    return None, last_decision, dict(last_aux)




def inject_text(prev_v, prev_hex, text, label, surface=None,
                instance_pid=None, instance_fence=None):
    """D 复核：动作前经既有恢复证据机制冻结可写落点与 owner 版本/全文，独立计算
    期望正文（UTF-16 拼接），要求版本**恰 +1**、字节逐字节相等。判定包原样存档。
    surface 必显式指定（本腿预期表面），透传给 freeze 做节点路由。仅用于焦点
    新建/切换后的首笔输入；同一挂载上的连续续写由调用方以后像链推进（见主循环
    字符续写段），不得重复调用本函数借旧采纳。"""
    sel, decision, aux = freeze_body_selection(prev_v, surface=surface,
                                              instance_pid=instance_pid,
                                              instance_fence=instance_fence)
    if sel is None:
        src = (decision or {}).get('source', 'no_freeze')
        reason = (decision or {}).get('reason', '')
        results.setdefault('freeze_refusals', []).append(
            {'label': label, 'decision': decision, 'base_version': prev_v,
             'aux': aux})
        check(f'{label}: frozen installed selection', False, f'{src} {reason}',
              snapshot=(prev_v, prev_hex))
        return False, prev_v, prev_hex
    # 保持调用方契约：返回 (ok, v, hx)。判定包已在 freeze 内归档，此处只记 span。
    results.setdefault('freeze_decisions', []).append(
        {'label': label, 'decision': decision, 'span': list(sel), 'aux': aux})
    s16, e16 = sel
    t0 = time.time()
    uitest_maybe('text', text)
    v, hx = wait_owner_advance(prev_v)
    latency = time.time() - t0
    if v is None:
        return check(f'{label}: owner advanced', False, f'v stayed {prev_v}',
                     snapshot=(prev_v, prev_hex)), prev_v, prev_hex
    if v != prev_v + 1:
        return check(f'{label}: version exactly +1', False,
                     f'{prev_v}->{v}（多笔/漏事务都拒绝）',
                     snapshot=(v, hx)), v, hx
    before = bytes.fromhex(prev_hex)
    want = expected_insert(before, s16, e16, text)
    if want is None:
        return check(f'{label}: expectation computable', False,
                     f'span [{s16},{e16}) splits scalar',
                     snapshot=(v, hx)), v, hx
    got = bytes.fromhex(hx)
    ok = got == want
    check(f'{label}: exact frozen-span edit', ok,
          f'v {prev_v}->{v} span=[{s16},{e16}) latency={latency:.2f}s',
          snapshot=(v, hx) if ok else (prev_v, prev_hex))
    return ok, v, hx


NOTE_ADOPTED_RE = re.compile(
    r"CJGUI_OWNED_SELECTION_ADOPTED2 node=(\d+) resource=(-?\d+) kind=(\d+) "
    r"sel=(\d+):(\d+) projection=(-?\d+) binding=(\d+)"
    r"(?: owner_version=(-?\d+))?(?: source_ctx=(\S+) source_gen=(\S+))?")


def freeze_adopted_caret(rows, node, auth, owner_version, pid, pid_of_row=None):
    """**实际冻结调用点**：从本轮日志段里取"该编辑面已被窗口采纳的 caret + owner 版本"。

    一条 ADOPTED2 只有同时满足下列全部事实才是来源，任一不满足都具名拒绝：
      * 行属于**本轮实例**（`pid` 在场时按 PID 归属，别的进程的数值重合不计）；
      * `node/resource/kind/binding` 等于权威当前读数 `auth`（别的资源或别的绑定
        的采纳不属于本会话，不能借计数）；
      * `source_ctx/source_gen` 等于 `auth` 的**当前** ctx/gen（旧 ctx 的采纳
        不能解锁新会话；缺来源字段或来源为 `unverified` 的行不作来源）；
      * `owner_version` 等于本次冻结基线版本（跨版本的历史采纳不算当前落点）；
      * 落点折叠（`start == end`）——非空选区的采纳不是 caret。
    取**最后**一条合格行（同会话内后发生的采纳覆盖先前落点）。

    `pid_of_row` 只是 hilog 取列的边界适配器：设备路径默认用与本验证器其余判据
    同一个 `vdo.row_pid`；离线自检显式注入，因此被检验的**归属决策**仍是这里。
    """
    matched = None
    refusals = []
    parse_pid = pid_of_row if pid_of_row is not None else vdo.row_pid
    for row in rows or []:
        mo = NOTE_ADOPTED_RE.search(row)
        if not mo:
            continue
        if pid is not None and parse_pid(row) != pid:
            refusals.append(f"foreign_pid:{row[:60]}")
            continue
        if mo.group(8) is None or mo.group(9) is None or mo.group(10) is None:
            refusals.append("adoption_source_identity_absent")
            continue
        try:
            seen = {"node": int(mo.group(1)), "resource": int(mo.group(2)),
                    "kind": int(mo.group(3)), "selection": (int(mo.group(4)), int(mo.group(5))),
                    "projection": int(mo.group(6)), "binding": int(mo.group(7)),
                    "owner_version": int(mo.group(8)), "source_ctx": int(mo.group(9)),
                    "source_gen": int(mo.group(10))}
        except ValueError:
            refusals.append("adoption_source_not_numeric")
            continue
        if seen["node"] != node:
            refusals.append(f"node!={node}")
            continue
        for field, want in (("resource", auth.get('resource')), ("kind", auth.get('kind')),
                            ("binding", auth.get('binding')),
                            # 采纳行的来源身份字段名与公开读回不同域：ADOPTED2 打
                            # `source_ctx/source_gen`，公开 `editing` 读数里是 `ctx/gen`。
                            ("source_ctx", auth.get('ctx')), ("source_gen", auth.get('gen'))):
            if seen[field] != want:
                refusals.append(f"{field}_mismatch:{seen[field]}!={want}")
                break
        else:
            if seen["owner_version"] != owner_version:
                refusals.append(f"owner_version_mismatch:{seen['owner_version']}")
            elif seen["selection"][0] != seen["selection"][1]:
                refusals.append(f"non_collapsed:{seen['selection']}")
            else:
                matched = dict(seen, row=row)
    if matched is None:
        return None, ("note_adopted_caret_source_missing:"
                      + (refusals[-1] if refusals else "no_adopted_row"))
    return matched, None


def _main_impl():
    # ---- 0. 当前实例身份 + 转发（本轮创建才登记） ----
    ident = m.instance_identity()
    results['identity'] = ident
    if not ident.get('pid'):
        print('FAIL 无运行实例'); return 2
    fwd_ok, fwd_basis = vdo.acquire_forward(PORT)
    owned_forward = fwd_ok
    ACTIVE_INSTANCE['pid'] = int(ident.get('pid'))
    _lr = m.hilog_rows()
    ACTIVE_INSTANCE['fence'] = _lr[-1] if _lr else ''
    try:
        # ---- 0b. 前台归属门（注入之前）----
        # `uitest click/drag/text` 落在**屏幕**上，不是落在本进程上：实例在后台时
        # 那一次模式动作会打到别的窗口，本实例既不产票也不换面——设备原件实测形状
        # 是 `mode_not_at_target` 且 `last` 与基线同值（票号零前进），读回 socket 却
        # 仍正常应答，所以只看读回会把它误判成产品切换缺陷。前台门用既有机制
        # （dump 前台 bundleName，未就绪有界重试），不在验收侧另造判据。
        fg = m.ensure_foreground()
        check('target instance foreground', fg,
              f'bundle={m.BUNDLE} pid={ident.get("pid")}（输入落点必须属于本实例）')
        if not fg:
            return 3
        # ---- 1. 源码基线 ----
        m.reset_fixture(PORT); time.sleep(1.0)
        v0, hx0 = owner()
        check('baseline fixture', b'# ' in bytes.fromhex(hx0), f'v={v0} bytes={len(hx0)//2}')
        # ---- 2. 可视 + 点击定位 ----
        ok, ev = vdo.reach_mode(PORT, 'preview', results, 'to-visual')
        check('reach visual', ok, str(ev))
        time.sleep(2.0)
        pt, why = m.readback_target_point(BODY, PORT)
        check('caret point resolvable', pt is not None, str(why))
        if pt is None:
            return 3
        click_t0 = time.time()
        uitest_maybe('click', str(pt[0]), str(pt[1])); time.sleep(2.0)
        last_click = (pt[0], pt[1])
        results['cost']['click_to_ready_s'] = round(time.time() - click_t0, 3)
        # ---- 3. 注入：中文 / emoji / 多标量簇（ZWJ 家族 + 旗帜） ----
        # 首字经既有恢复证据机制建立（要求采纳与版本精确匹配）；后续字是同一挂载
        # 上的连续本地续写，以上一笔已核对精确后像为依据（挂载未换、无释放、版本
        # 仅由本链推进），每笔仍验 version+1 与逐字节精确。期间任何挂载变化、
        # 释放或外部版本推进都立即中止（不借旧落点），须重新建立。
        _chain_caret, _chain_version = None, None
        _chain_fence = None
        _chain_identity = None
        for _i, text in enumerate(('文', '😀', '👩‍🚀', '🇺🇳')):
            if _i == 0:
                ok, v0, hx0 = inject_text(v0, hx0, text, f'inject {text!r}',
                                     surface='visual')
                if not ok:
                    return 4
                # 建立后像：caret 取注入点末端（纯插入），版本与正文来自已核对返回。
                _base_rows = m.hilog_rows()
                _chain_fence = _base_rows[-1] if _base_rows else ''
                _chain_caret = None  # 由 span 推导，见下
                # 从本次冻结决策取 span 末端为后像 caret（inject 已验精确）。
                _last_dec = (results.get('freeze_decisions') or [{}])[-1].get('decision') or {}
                _last_sel = _last_dec.get('sel')
                if _last_sel is not None:
                    _chain_caret = int(_last_sel[1]) + sum(
                        2 if ord(c) >= 0x10000 else 1 for c in text)
                _chain_version = v0
                _chain_identity = _last_dec.get('current_identity')
            else:
                # 续写：验证挂载稳定（无新挂载、无释放、版本未被外部推进），用后像
                # caret 直接注入；任一不符即中止，不借旧安装选区。
                _rows_now = m.hilog_rows()
                try:
                    _since = _rows_now.index(_chain_fence) + 1 if _chain_fence in _rows_now else 0
                except ValueError:
                    _since = 0
                _new_rows = _rows_now[_since:]
                _mount_changed = any('proxy mounted key=' in r for r in _new_rows)
                _released = any('proxy released by framework' in r for r in _new_rows)
                _v_now, _hx_now = owner()
                if _chain_caret is None or _mount_changed or _released or _v_now != _chain_version:
                    check(f'inject {text!r}: continuation basis lost', False,
                          f'mount_changed={_mount_changed} released={_released} '
                          f'v_now={_v_now} expected={_chain_version}')
                    return 4
                _want = expected_insert(bytes.fromhex(_hx_now), _chain_caret, _chain_caret, text)
                if _want is None:
                    check(f'inject {text!r}: continuation caret splits scalar', False,
                          f'caret={_chain_caret}')
                    return 4
                _t0 = time.time()
                _ok, _detail, _v, _hx = pair_injection_strokes(
                    SURFACE_TARGETS['visual']['node'], _chain_version, _hx_now,
                    _chain_caret, None, text, identity=_chain_identity)
                results.setdefault('stroke_pairs', []).append(
                    {'label': f'inject {text!r}', 'detail': _detail})
                if not _ok:
                    check(f'inject {text!r}: continuation exact', False,
                          f'v {_chain_version}->{_v} fail={_detail.get("fail")} '
                          f'strokes={_detail.get("summary", "")}')
                    return 4
                check(f'inject {text!r}: continuation exact', True,
                      f'v {_chain_version}->{_v} strokes={_detail.get("summary", "")} '
                      f'latency={time.time()-_t0:.2f}s')
                v0, hx0 = _v, _hx
                _chain_caret = _detail['end_caret16']
                _chain_version = _v
                _chain_fence = (m.hilog_rows() or [''])[-1]
                if text == '👩‍🚀':
                    # r26 回归：ZWJ 中段输入后不重点击，直接续写哨兵“哨”。
                    # 若暂态文尾被装回平台，哨兵将落在错误位置（全文/版本失配）
                    # 或采纳配对失配；核安装/采纳位置、owner 精确范围/版本/全文，
                    # 画面帧由 check() 经快门自动附带。
                    _sb = '哨'
                    _sb_want = expected_insert(bytes.fromhex(hx0), _chain_caret,
                                               _chain_caret, _sb)
                    if _sb_want is None:
                        check('sentinel after ZWJ: caret splits scalar', False,
                              f'caret={_chain_caret}')
                        return 4
                    _sbt0 = time.time()
                    _sok, _sdetail, _sv, _shx = pair_injection_strokes(
                        SURFACE_TARGETS['visual']['node'], _chain_version, hx0,
                        _chain_caret, None, _sb, identity=_chain_identity)
                    _sb_end = (_sdetail or {}).get('end_caret16')
                    _sb_ok = (_sok and _sb_end == _chain_caret + 1 and
                              bytes.fromhex(_shx) == _sb_want)
                    check('sentinel after ZWJ: exact position/version/full-text', _sb_ok,
                          f'v {_chain_version}->{_sv} end={_sb_end} '
                          f'latency={time.time()-_sbt0:.2f}s',
                          snapshot=(_sv, _shx))
                    if not _sb_ok:
                        return 4
                    # 删哨兵恢复链尾（精确移除），后继 RI/整删腿的链端假设不变。
                    uitest_maybe('keyEvent', '2055')
                    _rv, _rh, _rok = wait_owner_value(_sv, bytes.fromhex(hx0))
                    check('sentinel removed exactly (bytes+version)',
                          _rok and _rv == _sv + 1, f'v {_sv}->{_rv}')
                    if not (_rok and _rv == _sv + 1):
                        return 4
                    v0, hx0 = _rv, _rh
                    _chain_version = _rv
                    _chain_fence = (m.hilog_rows() or [''])[-1]
        # ---- 3b. 两类多标量簇整删 + Undo（链尾即已知簇末：先 RI 对、再 ZWJ 链） ----
        def _cluster_delete_expect(buf, caret16, want_text):
            cb = utf16_to_byte(buf, caret16)
            cl = grapheme_cluster_before(buf, cb) if cb is not None else None
            if cl is None or cl[0] is None or cl[1] != want_text:
                return None, cl
            start = len(buf[:cb].decode('utf-8', 'ignore')[:cl[0]].encode('utf-8'))
            return buf[:start] + buf[cb:], cl

        _cb_bytes = bytes.fromhex(hx0)
        _ri_want, _ri_cl = _cluster_delete_expect(_cb_bytes, _chain_caret, '🇺🇳')
        check('cluster oracle RI pair at chain end', _ri_want is not None, str(_ri_cl))
        if _ri_want is None:
            return 4
        uitest_maybe('keyEvent', '2055')
        _v1, _h1, _ok1 = wait_owner_value(v0, _ri_want)
        check('backspace removes RI pair exactly (bytes+version)',
              _ok1 and _v1 == v0 + 1, f'v {v0}->{_v1}')
        if not (_ok1 and _v1 == v0 + 1):
            return 4
        _zwj_caret = _chain_caret - _utf16_units('🇺🇳')
        _zwj_want, _zwj_cl = _cluster_delete_expect(_ri_want, _zwj_caret, '👩\u200d🚀')
        check('cluster oracle ZWJ chain at known cluster end', _zwj_want is not None, str(_zwj_cl))
        if _zwj_want is None:
            return 4
        uitest_maybe('keyEvent', '2055')
        _v2, _h2, _ok2 = wait_owner_value(_v1, _zwj_want)
        check('backspace removes ZWJ chain exactly (bytes+version)',
              _ok2 and _v2 == _v1 + 1, f'v {_v1}->{_v2}')
        if not (_ok2 and _v2 == _v1 + 1):
            return 4
        _up, _w = m.readback_target_point('pharos-undo', PORT)
        check('undo reachable after cluster deletes', _up is not None)
        if _up is None:
            return 4
        uitest_maybe('click', str(_up[0]), str(_up[1])); time.sleep(0.5)
        _v3, _h3, _ok3 = wait_owner_value(_v2, _ri_want)
        check('undo restores ZWJ chain exactly', _ok3 and _v3 == _v2 + 1, f'v {_v2}->{_v3}')
        if not (_ok3 and _v3 == _v2 + 1):
            return 4
        _up2, _w = m.readback_target_point('pharos-undo', PORT)
        uitest_maybe('click', str(_up2[0]), str(_up2[1])); time.sleep(0.5)
        _v4, _h4, _ok4 = wait_owner_value(_v3, _cb_bytes)
        check('undo restores RI pair exactly', _ok4 and _v4 == _v3 + 1, f'v {_v3}->{_v4}')
        if not (_ok4 and _v4 == _v3 + 1):
            return 4
        v0, hx0 = _v4, _h4
        # ---- 4. 同片段非空替换：拖选 + 输入替换（D 复核：必须**非空选区替换**，
        # 冻结已安装源选区 [s,e) s<e，期望=QQ 替换该跨度，版本恰 +1、字节精确） ----
        # 拖选锚定**行首**：长标题会折行，锚点在行尾时两端都钳到行末（实测全塌缩）。
        # 节点屏幕原点 = 上次点击屏幕坐标 − 命中回执的 tap 相对坐标（hilog 原件）。
        rows = m.hilog_rows()
        origin = None
        for r in reversed(rows):
            mm = re.search(r'presentation hit node=(\d+) caret=\d+ .*tap=\((-?[\d.]+),(-?[\d.]+)\)', r)
            if mm and last_click is not None:
                origin = (last_click[0] - float(mm.group(2)),
                          last_click[1] - float(mm.group(3)))
                break
        check('replace: node origin from hit receipt', origin is not None,
              f'origin={origin}')
        if origin is None:
            return 40
        sel = None
        for span_px in (80, 160, 240):
            uitest_maybe('click', str(int(origin[0] + 24)), str(int(origin[1] + 20))); time.sleep(1.2)
            uitest_maybe('drag', str(int(origin[0] + 24)), str(int(origin[1] + 20)),
                         str(int(origin[0] + 24 + span_px)), str(int(origin[1] + 20))); time.sleep(1.6)
            rows = m.hilog_rows()
            sel, _dec, _aux = freeze_body_selection(surface='visual')
            if sel is not None and sel[1] > sel[0]:
                break
        rep_frozen = sel is not None and sel[1] > sel[0]
        check('replace: frozen NON-EMPTY installed span', rep_frozen, f'sel={sel}')
        if not rep_frozen:
            return 41
        s16, e16 = sel
        v_pre, hx_pre = owner()
        _ok, _detail, v_rep, hx_rep = pair_injection_strokes(
            SURFACE_TARGETS['visual']['node'], v_pre, hx_pre, s16, (s16, e16), 'QQ',
            identity=(_dec or {}).get('current_identity'))
        results.setdefault('stroke_pairs', []).append(
            {'label': 'replace QQ', 'detail': _detail})
        rep_ok = _ok
        check('replace: exact frozen-span QQ (per-stroke paired)', rep_ok,
              f'v {v_pre}->{v_rep} span=[{s16},{e16}) strokes={_detail.get("summary", "")} '
              f'fail={_detail.get("fail")}')
        if not rep_ok:
            return 42
        results['replace'] = {'span': [s16, e16], 'before_v': v_pre, 'after_v': v_rep}
        v0, hx0 = v_rep, hx_rep
        # ---- 4a. 大范围替换后免点击续写（r27 收缩回归腿） ----
        # 沿编辑器可见区纵拖选中大跨度（旧 end 须超出替换后新文长），替换成单字
        # 后不点击直接续写哨兵：若收缩钳位被装回平台，续写将落错位置（全文/版本
        # 失配）或采纳失配。起笔在标题之下以保留正文头 '##'（后继 agent 腿
        # 依赖）；跨度与端点算术冻结核验，不猜布局。画面帧由 check() 经快门附带。
        _lr_rect, _lr_why = m.readback_target_rect('pharos-editor-scroll-content', PORT)
        _lr_okrect = (_lr_rect is not None and _lr_rect[3] >= 160)
        check('large-replace: editor rect measurable', _lr_okrect,
              f'rect={_lr_rect} why={_lr_why}')
        if not _lr_okrect:
            return 44
        _rx, _ry, _rw, _rh = _lr_rect
        # 点按扫描定行＋横拖/对角拖选（纵向长拖会被滚动视图吃掉；横向无滚动容器，
        # 同 §4 已证的点按建焦＋横拖形状）：沿编辑器纵向点按 4 处并冻结 caret，
        # 对每处做同行横拖＋下拉两行对角拖，取旧端超出新文长余量（margin）最大者。
        # margin = old_end - (total - (end-start) + inserted_units)，即旧 end 超出
        # 替换后新文长的单位数（本腿插入 1 单位，故亦为 2e - s - 1 - total）；
        # 点按/拖选都不改正文，全程冻结核验。起笔须在正文头 '##' 之后
        # （后继 agent 腿依赖 [0,2)）。
        _lsel = None
        _ldec = None
        _laux = None
        _lmargin = None
        for _pyv in (_ry + 40, _ry + _rh * 0.35, _ry + _rh * 0.6, _ry + _rh * 0.85):
            _pp, _pw = m.readback_target_point('pharos-editor-scroll-content', PORT,
                                               vp_x=_rx + 60, vp_y=_pyv)
            if _pp is None:
                continue
            _pe, _we = m.readback_target_point('pharos-editor-scroll-content', PORT,
                                               vp_x=_rx + _rw - 10, vp_y=_pyv)
            _pe2, _we2 = m.readback_target_point('pharos-editor-scroll-content', PORT,
                                                 vp_x=_rx + _rw - 10, vp_y=_pyv + 80)
            for _tgt in (_pe, _pe2):
                if _tgt is None:
                    continue
                uitest_maybe('click', str(_pp[0]), str(_pp[1])); time.sleep(1.0)
                _csel, _, _ = freeze_body_selection(surface='visual')
                if _csel is None or _csel[0] != _csel[1]:
                    continue
                uitest_maybe('drag', str(_pp[0]), str(_pp[1]),
                             str(_tgt[0]), str(_tgt[1])); time.sleep(1.6)
                _rows_lr = m.hilog_rows()
                _cand, _cdec, _caux = freeze_body_selection(surface='visual')
                if _cand is not None and _cand[1] > _cand[0] and _cand[0] >= 2:
                    _cv, _chx = owner()
                    _ct = sum(2 if ord(c) >= 0x10000 else 1
                              for c in bytes.fromhex(_chx).decode('utf-8'))
                    _marg = 2 * _cand[1] - _cand[0] - 1 - _ct
                    if _lmargin is None or _marg > _lmargin:
                        _lsel, _ldec, _laux, _lmargin = _cand, _cdec, _caux, _marg
            if _lsel is not None and _lmargin is not None and _lmargin >= 10:
                break
        _lv_pre, _lhx_pre = owner()
        _ltext = bytes.fromhex(_lhx_pre).decode('utf-8')
        _ltotal = sum(2 if ord(c) >= 0x10000 else 1 for c in _ltext)
        _lspan_ok = (_lsel is not None and _lsel[1] > _lsel[0] and _lsel[0] >= 2 and
                     _lmargin is not None and _lmargin >= 10 and
                     _lsel[1] > _ltotal - (_lsel[1] - _lsel[0]) + 1)
        check('large-replace: frozen NON-EMPTY large span (old end exceeds new length)',
              _lspan_ok, f'sel={_lsel} total={_ltotal} margin={_lmargin}')
        if not _lspan_ok:
            return 45
        _ls16, _le16 = _lsel
        _lok, _ldetail, _lv_rep, _lhx_rep = pair_injection_strokes(
            SURFACE_TARGETS['visual']['node'], _lv_pre, _lhx_pre, _ls16, (_ls16, _le16), 'Q',
            identity=(_ldec or {}).get('current_identity'))
        results.setdefault('stroke_pairs', []).append(
            {'label': 'large replace Q', 'detail': _ldetail})
        check('large-replace: exact frozen-span Q (per-stroke paired)', _lok,
              f'v {_lv_pre}->{_lv_rep} span=[{_ls16},{_le16}) '
              f'strokes={_ldetail.get("summary", "")} fail={_ldetail.get("fail")}')
        if not _lok:
            return 46
        # 替换后不点击直接续写（同挂载连续续写形状：以后像 caret 为准，不重建冻结；
        # 若收缩钳位被装回平台，哨兵将落错位置或采纳失配）。
        # Q 为单码元，替换采纳落点 = span 起点 + 1。
        _lc = _ls16 + 1
        _cok, _cdetail, _cv, _chx = pair_injection_strokes(
            SURFACE_TARGETS['visual']['node'], _lv_rep, _lhx_rep, _lc, None, '标',
            identity=(_ldec or {}).get('current_identity'))
        _cend = (_cdetail or {}).get('end_caret16')
        _cok_full = (_cok and _cend == _lc + 1)
        check('continue after large replace: exact position/version/full-text', _cok_full,
              f'v {_lv_rep}->{_cv} caret={_lc} end={_cend} '
              f'strokes={(_cdetail or {}).get("summary", "")} '
              f'fail={(_cdetail or {}).get("fail")}',
              snapshot=(_cv, _chx))
        if not _cok_full:
            return 46
        v0, hx0 = _cv, _chx
        # ---- 4b. QQQ 单次投递（三字符；允许拆笔，逐笔核范围/版本链/合法前缀/采纳落点） ----
        # 折叠 caret 冻结后一次投递：QQ 已覆盖非空替换路径，此处专验三字符拆笔逐笔。
        sel = None
        for _tap_dx in (0, 120, 240):
            uitest_maybe('click', str(int(origin[0] + 24 + _tap_dx)), str(int(origin[1] + 20))); time.sleep(1.2)
            rows = m.hilog_rows()
            sel, _dec, _aux = freeze_body_selection(surface='visual')
            if sel is not None and sel[0] == sel[1] and sel[0] > 0:
                break
        qqq_frozen = sel is not None and sel[0] == sel[1] and sel[0] > 0
        check('QQQ: frozen collapsed caret', qqq_frozen, f'sel={sel}')
        if not qqq_frozen:
            return 43
        # 安装稳定性复核：静置后重冻必须一致，否则本次 tap 安装不可信。
        time.sleep(1.0)
        _sel2, _, _ = freeze_body_selection(surface='visual')
        _stable = _sel2 == sel
        check('QQQ: installed caret stable across settle', _stable, f'sel={sel} resel={_sel2}')
        if not _stable:
            return 43
        qc16 = sel[0]
        qv_pre, qhx_pre = owner()
        _qok, _qdetail, qv, qhx = pair_injection_strokes(
            SURFACE_TARGETS['visual']['node'], qv_pre, qhx_pre, qc16, None, 'QQQ',
            identity=(_dec or {}).get('current_identity'))
        results.setdefault('stroke_pairs', []).append(
            {'label': 'replace QQQ', 'detail': _qdetail})
        check('inject QQQ: per-stroke paired', _qok,
              f'v {qv_pre}->{qv} caret=[{qc16},{qc16}) '
              f'strokes={_qdetail.get("summary", "")} fail={_qdetail.get("fail")}')
        if not _qok:
            return 43
        v0, hx0 = qv, qhx
        # ---- 5. 退格删除：冻结 caret（已安装折叠选区 [c,c)），期望=删除 caret 前
        # 的**一个字素簇**（RI 对/ZWJ 链按整簇），版本恰 +1、字节精确。 ----
        # 先折叠 caret：QQ 替换后已安装的是被替换跨度（非空），折叠 caret 从未建立。
        # 沿用 replace 腿的 establish-then-freeze 做法——行内 tap 后再 freeze；c>0
        # 保证删的是真实字素簇。断言本身不变。
        sel = None
        for _tap_dx in (0, 120, 240):
            uitest_maybe('click', str(int(origin[0] + 24 + _tap_dx)), str(int(origin[1] + 20))); time.sleep(1.2)
            rows = m.hilog_rows()
            sel, _dec, _aux = freeze_body_selection(surface='visual')
            if sel is not None and sel[0] == sel[1] and sel[0] > 0:
                break
        del_frozen = sel is not None and sel[0] == sel[1] and sel[0] > 0
        check('delete: frozen collapsed caret', del_frozen, f'sel={sel}')
        if not del_frozen:
            return 5
        c16 = sel[0]
        v_pre, hx_pre = owner()
        before = bytes.fromhex(hx_pre)
        caret_byte = utf16_to_byte(before, c16)
        cluster = grapheme_cluster_before(before, caret_byte) if caret_byte is not None else None
        exp_ok = cluster is not None and cluster[0] is not None
        check('delete: cluster computable from frozen caret', exp_ok,
              f'caret={caret_byte} cluster={cluster[1]!r}' if cluster else f'caret={caret_byte}')
        if not exp_ok:
            return 5
        uitest_maybe('keyEvent', '2055'); time.sleep(2.5)
        v_del, hx_del = wait_owner_advance(v_pre)
        # cluster[0] 是**字符**下标 → 换算字节下标后再比对。
        cluster_byte_start = len(text_of(before)[:cluster[0]].encode('utf-8')) \
            if (text_of := lambda b: b.decode('utf-8', errors='replace')) else -1
        del_ok = v_del == v_pre + 1 and bytes.fromhex(hx_del) == \
            before[:cluster_byte_start] + before[caret_byte:]
        check('backspace removes exactly the frozen cluster', del_ok,
              f'v {v_pre}->{v_del} cluster={cluster[1]!r}')
        if not del_ok:
            return 5
        v0, hx0 = v_del, hx_del
        # ---- 6. Undo / Redo（版本单调推进 + 精确前后态） ----
        undo_pt, _w = m.readback_target_point('pharos-undo', PORT)
        check('undo button reachable', undo_pt is not None)
        if undo_pt is None:
            return 6
        pre_hex = hx0
        uitest_maybe('click', str(undo_pt[0]), str(undo_pt[1])); time.sleep(2.5)
        v_undo, hx_undo = wait_owner_advance(v0)
        undo_ok = v_undo is not None and v_undo == v0 + 1  # 单调推进，版本不回退
        undo_ok = undo_ok and hx_undo == hx_pre  # 精确前态：Undo 后 == 删除前
        check('undo: monotonic version + exact prior body', undo_ok,
              f'{v0}->{v_undo} exact={hx_undo == hx_pre}')
        if not undo_ok:
            return 7
        redo_pt, _w = m.readback_target_point('pharos-redo', PORT)
        uitest_maybe('click', str(redo_pt[0]), str(redo_pt[1])); time.sleep(2.5)
        v_redo, hx_redo = wait_owner_advance(v_undo)
        redo_ok = v_redo == v_undo + 1 and hx_redo == pre_hex
        check('redo: monotonic version + exact restored body', redo_ok,
              f'{v_undo}->{v_redo} exact={hx_redo == pre_hex}')
        if not redo_ok:
            return 8
        v0, hx0 = v_redo, hx_redo
        # ---- 7. 公开 Agent REPLACE_RANGE（合法跨度：标题标记 [0,2)） ----
        r = m.agent_replace(PORT, 0, 2, '2323', v0)
        reply = str(r)
        applied = 'APPLIED true' in reply
        v_ag, hx_ag = wait_owner_advance(v0)
        ag_ok = applied and v_ag == v0 + 1 and bytes.fromhex(hx_ag).startswith(b'##')
        check('agent replace [0,2)->##', ag_ok, f'{v0}->{v_ag} applied={applied}')
        if not ag_ok:
            return 9
        # ---- 8. 改版后免点击续写（硬失败门） ----
        ok, v0, hx0 = inject_text(v_ag, hx_ag, '续', 'continue after agent', surface='visual')
        if not ok:
            return 10
        # ---- 9. 正文/备注往返（P2 隔离） ----
        note_pt, why = m.readback_target_point('pharos-document-note', PORT)
        check('note surface reachable', note_pt is not None, str(why))
        if note_pt is not None:
            main_before_v, main_before = v0, hx0
            rows_pre_note = m.hilog_rows()
            uitest_maybe('click', str(note_pt[0]), str(note_pt[1]))
            # 点击后有界等 hilog 出现备注 BIND_OWNER（会话真换到备注），再注入。
            note_bound = False
            for _ in range(16):
                time.sleep(0.5)
                rows_now = m.hilog_rows()
                known = set(rows_pre_note)
                if any('BIND_OWNER owner=pharos-note' in r and r not in known
                       for r in rows_now):
                    note_bound = True
                    break
            check('note session bound after click', note_bound)
            # 备注公开资源随会话惰性发布（动态 rid）：绑定后再解析，绑定前查不到。
            # 有界等发布；版本+1 与 NB 后缀断言不变。
            note_rid = None
            for _ in range(6):
                note_rid = vdo.find_note_resource(PORT)
                if note_rid:
                    break
                time.sleep(1.0)
            check('note resource published after bind', note_rid is not None)
            if note_rid is None:
                return 11
            try:
                note_before = vdo.read_public(PORT, note_rid)
            except RuntimeError as e:
                check('note baseline readable', False, repr(e)[:160])
                return 11
            # 冻结备注本轮已采纳选区：只认点击后的本实例行，且采纳来源必须等于
            # 权威当前身份（读回 live 编辑身份，node=313）。历史 restore-armed
            # 行可缺省，不构成身份来源；读回缺位/非 live/非本节点一律具名拒绝。
            _fence_rows = m.hilog_rows()
            try:
                _si = vdo.fence_index(_fence_rows, rows_pre_note[-1]) if rows_pre_note else 0
                _seg = _fence_rows[_si:]
            except Exception:
                _seg = []
            _note_edit = vdo.public_snapshot(PORT).get('editing')
            _note_auth = None
            if (_note_edit is not None and _note_edit.get('live') is True
                    and all(_note_edit.get(k) is not None for k in
                            ('ctx', 'gen', 'node', 'resource', 'kind', 'binding'))):
                if _note_edit.get('node') == 313:
                    _note_auth = _note_edit
                else:
                    check('note adopted caret frozen', False,
                          f'readback editing node={_note_edit.get("node")} != 313')
                    return 11
            else:
                check('note adopted caret frozen', False,
                      f'readback editing not live/complete: {_note_edit}')
                return 11
            _ctx = _note_auth.get('ctx')
            # 冻结来源**只**走实际调用点 `freeze_adopted_caret`：同实例、同
            # resource/kind/binding、来源 ctx/gen 等于权威当前读数、owner 版本等于
            # 冻结基线、落点折叠。任一不满足都具名不通过（`--self-test-negative`
            # 直接驱动这个函数做正控与错来源拒绝，不再另造 helper 判据）。
            _frozen, _freeze_fail = freeze_adopted_caret(
                _seg, 313, _note_auth, note_before[0], ACTIVE_INSTANCE.get('pid'))
            note_caret_frozen = _frozen is not None
            check('note adopted caret frozen', note_caret_frozen,
                  f'{_freeze_fail or _frozen} auth_ctx={_ctx} want_owner_v={note_before[0]}')
            if not note_caret_frozen:
                return 11
            _nc, _nv = _frozen['selection'], _frozen['owner_version']
            # NB 单次投递并逐笔配对（拆笔核范围/版本链/合法前缀/来源身份/采纳推进，
            # 与正文腿同一接缝；身份用上面的读回权威身份）。
            _nb_ok, _nb_detail, _nb_v, _nb_hx = pair_injection_strokes(
                313, note_before[0], note_before[1], _nc[0], None, 'NB',
                reader=lambda: vdo.read_public(PORT, note_rid), identity=_note_auth)
            results.setdefault('stroke_pairs', []).append(
                {'label': 'note NB', 'detail': _nb_detail})
            check('note owner advanced with NB', _nb_ok,
                  f'note v {note_before[0]}->{_nb_v} strokes={_nb_detail.get("summary", "")} '
                  f'fail={_nb_detail.get("fail")}')
            if not _nb_ok and not KEEP_GOING:
                return 11
            note_frozen_v, note_frozen_hx = (_nb_v, _nb_hx) if _nb_ok else (None, None)
            # 正文零事务：备注输入期间主文档版本/全文不变。
            v_during, hx_during = owner()
            check('main zero-write during note typing',
                  v_during == main_before_v and hx_during == main_before,
                  f'main v {main_before_v}->{v_during}')
            if v_during != main_before_v or hx_during != main_before:
                return 11
            pt, _w = m.readback_target_point(BODY, PORT)
            uitest_maybe('click', str(pt[0]), str(pt[1])); time.sleep(2.5)
            ok, v0, hx0 = inject_text(v_during, hx_during, '正', 'body after note roundtrip', surface='visual')
            if not ok:
                return 11
            # 回正文后备注版本与全文必须等于 NB 提交后的冻结快照（精确相等）。
            note_rid2 = vdo.find_note_resource(PORT)
            try:
                note_final = vdo.read_public(PORT, note_rid2) if note_rid2 else None
            except RuntimeError:
                note_final = None
            note_kept = (_nb_ok and note_rid2 == note_rid and note_final is not None
                         and note_final[0] == note_frozen_v and note_final[1] == note_frozen_hx)
            check('note text kept after body edit', note_kept,
                  f'rid {note_rid}->{note_rid2} v {note_frozen_v}->{note_final[0] if note_final else "?"}')
        # ---- 10. 无编辑双模式往返（P1） ----
        vdo.reach_mode(PORT, 'source', results, 'roundtrip-source'); time.sleep(1.5)
        vdo.reach_mode(PORT, 'preview', results, 'roundtrip-visual'); time.sleep(1.5)
        pt, _w = m.readback_target_point(BODY, PORT)
        uitest_maybe('click', str(pt[0]), str(pt[1])); time.sleep(2.0)
        ok, v0, hx0 = inject_text(v0, hx0, '回', 'type after no-edit roundtrip', surface='visual')
        if not ok:
            return 12
        # ---- 11. 切源码 + 保存（完整回包） ----
        vdo.reach_mode(PORT, 'source', results, 'to-source'); time.sleep(1.5)
        v_s, hx_s = owner()
        check('source body == visual body', hx_s == hx0, f'v={v_s}')
        # 主文档资源号动态解析（资源 1 固定钉在首次寻址的实例上；备注注册后
        # 主文档可能持其他号）：扫 id 1..8，READ_RANGE 与 owner 全文一致者为主。
        main_rid = None
        for rid in range(1, 9):
            vv, hh = vdo.read_public(PORT, rid)
            if hh and hh.lower() == hx_s.lower():
                main_rid = rid
                break
        check('main document resource id resolved', main_rid is not None, str(main_rid))
        if main_rid is None:
            return 13
        # 保存走**正常界面路径**：source 模式下点 toolbar 保存按钮（同步 owner
        # 事务），以 hilog `PHAROS_OHOS_COMMAND … SAVE applied=true persisted=true
        # saved=<v> bytes=<n>` 为完整成功回执；bytes 必须等于当前 owner 字节数。
        save_btn, _w = m.readback_target_point('pharos-save', PORT)
        check('save button reachable', save_btn is not None)
        if save_btn is None:
            return 13
        rows_pre = m.hilog_rows()
        uitest_maybe('click', str(save_btn[0]), str(save_btn[1])); time.sleep(3.0)
        rows = m.hilog_rows()
        known = set(rows_pre)
        seg = [r for r in rows if r not in known]
        save_row = None
        for r in seg:
            if vdo.row_pid(r) != ACTIVE_INSTANCE.get('pid'):
                continue
            if 'PHAROS_OHOS_COMMAND' in r and 'SAVE applied=true persisted=true' in r:
                save_row = r
        save_ok = save_row is not None
        if save_row:
            mm = re.search(r'saved=(\d+) bytes=(\d+)', save_row)
            save_ok = mm is not None and int(mm.group(2)) == len(hx_s) // 2 and \
                int(mm.group(1)) == v_s
        check('toolbar save persisted full owner (saved==frozen v, bytes==owner)', save_ok,
              (save_row or 'no SAVE row').replace(chr(10), ' | ')[-110:])
        if not save_ok:
            return 13
        results['save_row'] = save_row or ''
        saved_hex, saved_v = hx_s, v_s
        # ---- 12. 正常关闭 / 新实例重开（解析 bundle，不硬编码） ----
        pid0 = ident.get('pid')
        # bundle 从**当前进程表**解析（不得硬编码）：先按 PID 查进程名。
        ps = subprocess.run([HDC, '-t', target, 'shell',
                             f'ps -ef | grep {pid0} | grep -v grep'],
                            capture_output=True, text=True).stdout.strip()
        bundle = None
        if ps:
            last = ps.split('\n')[0].split()[-1]
            if '.' in last and not last.isdigit():
                bundle = last
        check('bundle resolved from current process', bundle is not None, str(bundle))
        if bundle is None:
            return 16
        check('bundle resolved', bundle is not None, str(bundle))
        # 先收起键盘（前台输入会话会延迟 aa force-stop），再强停；必要时 kill -9。
        uitest_maybe('keyEvent', 'Back'); time.sleep(1.0)
        stopped = False
        for attempt in range(3):
            subprocess.run([HDC, '-t', target, 'shell', f'aa force-stop {bundle}'], capture_output=True)
            for _ in range(8):
                cur = subprocess.run([HDC, '-t', target, 'shell', f'pidof {bundle}'],
                                     capture_output=True, text=True).stdout.strip()
                if not cur:
                    stopped = True
                    break
                time.sleep(0.5)
            if stopped:
                break
            cur = subprocess.run([HDC, '-t', target, 'shell', f'pidof {bundle}'],
                                 capture_output=True, text=True).stdout.strip()
            if cur:
                subprocess.run([HDC, '-t', target, 'shell', f'kill -9 {cur}'], capture_output=True)
                time.sleep(1.0)
                cur = subprocess.run([HDC, '-t', target, 'shell', f'pidof {bundle}'],
                                     capture_output=True, text=True).stdout.strip()
                if not cur:
                    stopped = True
                    break
        check('force-stop observed', stopped)
        subprocess.run([HDC, '-t', target, 'shell', f'aa start -a EntryAbility -b {bundle}'],
                       capture_output=True)
        pid1 = None
        for _ in range(120):
            time.sleep(0.5)
            cur = subprocess.run([HDC, '-t', target, 'shell', f'pidof {bundle}'],
                                 capture_output=True, text=True).stdout.strip()
            if cur and cur != str(pid0):
                pid1 = int(cur)
                break
        check('new instance launched', pid1 is not None, f'{pid0} -> {pid1}')
        if pid1 is None:
            return 17
        time.sleep(6.0)
        ident2 = {'pid': pid1, 'bundle': bundle}
        check('reopen is a NEW instance', pid1 != pid0, f'{pid0} -> {pid1}')
        ACTIVE_INSTANCE['pid'] = pid1
        _lr = m.hilog_rows()
        ACTIVE_INSTANCE['fence'] = _lr[-1] if _lr else ''
        fwd2, _ = vdo.acquire_forward(PORT)
        v_r, hx_r = owner()
        reopen_ok = v_r is not None and hx_r == saved_hex
        check('reopen body exact', reopen_ok, f'v={v_r} equal={hx_r == saved_hex}')
        if not reopen_ok:
            return 14
        # ---- 13. 重开后继续编辑 ----
        vdo.reach_mode(PORT, 'preview', {}, 'reopen-visual'); time.sleep(2.0)
        pt, _w = m.readback_target_point(BODY, PORT)
        uitest_maybe('click', str(pt[0]), str(pt[1])); time.sleep(2.0)
        ok, v_r, hx_r = inject_text(v_r, hx_r, '后', 'edit after reopen', surface='visual')
        if not ok:
            return 15
        # ---- 13b. 第一次公开 SAVE（外部通道 INVOKE，非工具栏点击） ----
        # APPLIED 只证明 owner 已发布启动；终态以异步终端行
        # `PHAROS_OHOS_SAVE_POLL applied=true persisted=true saved=<v> bytes=<n>`
        # 为准（INVOKE 只 start，终态由宿主 poll 发布；COMMAND+SAVE 行专属同步
        # 工具栏路径，异步路径永不产生，勿用其过滤）。saved 必须等于调用时的
        # 目标版本、bytes 等于 owner 字节数；再以同实例 owner 读回证明终端对应
        # 真实状态。判定包存完整正文、版本、期望与原协议行，不只存 APPLIED。
        rows_pre = m.hilog_rows()
        save1_resp = m.request(['PROTOCOL CJGUI_SHARED_OPERATION/2', f'AUTH {m.CAP}',
                                f'INVOKE {v_r} SAVE 1 0', 'ID 1'], PORT)
        save1_applied = 'APPLIED true' in save1_resp
        check('public save 1 APPLIED (start only)', save1_applied,
              save1_resp[:160].replace(chr(10), ' | '))
        time.sleep(3.0)
        rows = m.hilog_rows()
        known = set(rows_pre)
        save1_row = None
        for r in rows:
            if r in known:
                continue
            if vdo.row_pid(r) != ACTIVE_INSTANCE.get('pid'):
                continue
            if 'PHAROS_OHOS_SAVE_POLL' in r and 'applied=true persisted=true' in r:
                save1_row = r
        save1_ok = save1_row is not None
        save1_saved_v, save1_saved_n = None, None
        if save1_row:
            mm = re.search(r'saved=(\d+) bytes=(\d+)', save1_row)
            if mm:
                save1_saved_v, save1_saved_n = int(mm.group(1)), int(mm.group(2))
                save1_ok = save1_saved_v == v_r and save1_saved_n == len(hx_r) // 2
        check('public save 1 persisted terminal (saved==target v, bytes==owner)', save1_ok,
              (save1_row or 'no SAVE terminal row').replace(chr(10), ' | ')[-160:])
        if not save1_ok:
            return 15
        v_chk, hx_chk = owner()
        check('public save 1 terminal matches live owner', v_chk == v_r and hx_chk == hx_r,
              f'owner v={v_chk} terminal saved v={save1_saved_v}')
        if v_chk != v_r or hx_chk != hx_r:
            return 15
        results['public_save_1'] = {'invoke_applied': save1_applied,
                                    'terminal_row': save1_row,
                                    'target_version': v_r,
                                    'owner_version': v_chk, 'owner_hex': hx_chk,
                                    'expected_bytes': len(hx_r) // 2}
        # ---- 13b-2. 第一次公开 SAVE 的新实例完整读回（早于下一次改版；文件不可经
        # shell 读，取新实例读回） ----
        pid_s1 = ACTIVE_INSTANCE['pid']
        uitest_maybe('keyEvent', 'Back'); time.sleep(1.0)
        subprocess.run([HDC, '-t', target, 'shell', f'aa force-stop {bundle}'],
                       capture_output=True)
        for _ in range(60):
            time.sleep(0.5)
            cur = subprocess.run([HDC, '-t', target, 'shell', f'pidof {bundle}'],
                                 capture_output=True, text=True).stdout.strip()
            if not cur:
                break
        subprocess.run([HDC, '-t', target, 'shell', f'aa start -a EntryAbility -b {bundle}'],
                       capture_output=True)
        pid_s1b = None
        for _ in range(120):
            time.sleep(0.5)
            cur = subprocess.run([HDC, '-t', target, 'shell', f'pidof {bundle}'],
                                 capture_output=True, text=True).stdout.strip()
            if cur and cur != str(pid_s1):
                pid_s1b = int(cur)
                break
        check('save 1 readback: new instance', pid_s1b is not None, f'{pid_s1} -> {pid_s1b}')
        if pid_s1b is None:
            return 17
        ACTIVE_INSTANCE['pid'] = pid_s1b
        _lr = m.hilog_rows()
        ACTIVE_INSTANCE['fence'] = _lr[-1] if _lr else ''
        time.sleep(6.0)
        vdo.acquire_forward(PORT)
        v_s1, hx_s1 = owner()
        s1_ok = v_s1 is not None and hx_s1 == hx_chk
        check('save 1 persisted to disk (new-instance full readback)', s1_ok,
              f'v={v_s1} equal={hx_s1 == hx_chk}')
        if not s1_ok:
            return 15
        ident2 = {'pid': pid_s1b, 'bundle': bundle}
        vdo.reach_mode(PORT, 'preview', {}, 'save1-reopen-visual'); time.sleep(2.0)
        # 两次公开 SAVE 之间必须推进版本，否则第二次只是在重复证明同一终态。
        # 与其它 inject 点一致：先点击正文建立本轮采纳，再冻结注入（SAVE 不产生新采纳）。
        pt, _w = m.readback_target_point(BODY, PORT)
        uitest_maybe('click', str(pt[0]), str(pt[1])); time.sleep(2.0)
        ok, v_r2, hx_r2 = inject_text(v_s1, hx_s1, '公', 'edit before second public save', surface='visual')
        if not ok:
            return 15
        # ---- 13c. 第二次公开 SAVE（新目标版本）+ 新实例重开读回 ----
        rows_pre = m.hilog_rows()
        save2_resp = m.request(['PROTOCOL CJGUI_SHARED_OPERATION/2', f'AUTH {m.CAP}',
                                f'INVOKE {v_r2} SAVE 1 0', 'ID 1'], PORT)
        save2_applied = 'APPLIED true' in save2_resp
        check('public save 2 APPLIED (start only)', save2_applied,
              save2_resp[:160].replace(chr(10), ' | '))
        time.sleep(3.0)
        rows = m.hilog_rows()
        known = set(rows_pre)
        save2_row = None
        for r in rows:
            if r in known:
                continue
            if vdo.row_pid(r) != ACTIVE_INSTANCE.get('pid'):
                continue
            if 'PHAROS_OHOS_SAVE_POLL' in r and 'applied=true persisted=true' in r:
                save2_row = r
        save2_ok = save2_row is not None
        save2_saved_v, save2_saved_n = None, None
        if save2_row:
            mm = re.search(r'saved=(\d+) bytes=(\d+)', save2_row)
            if mm:
                save2_saved_v, save2_saved_n = int(mm.group(1)), int(mm.group(2))
                save2_ok = save2_saved_v == v_r2 and save2_saved_n == len(hx_r2) // 2
        check('public save 2 persisted terminal (saved==target v, bytes==owner)', save2_ok,
              (save2_row or 'no SAVE terminal row').replace(chr(10), ' | ')[-160:])
        if not save2_ok:
            return 15
        results['public_save_2'] = {'invoke_applied': save2_applied,
                                    'terminal_row': save2_row,
                                    'target_version': v_r2,
                                    'owner_version': v_r2, 'owner_hex': hx_r2,
                                    'expected_bytes': len(hx_r2) // 2}
        pid_before_reopen2 = ident2['pid']
        uitest_maybe('keyEvent', 'Back'); time.sleep(1.0)
        subprocess.run([HDC, '-t', target, 'shell', f'aa force-stop {bundle}'],
                       capture_output=True)
        pid2 = None
        for _ in range(120):
            time.sleep(0.5)
            cur = subprocess.run([HDC, '-t', target, 'shell', f'pidof {bundle}'],
                                 capture_output=True, text=True).stdout.strip()
            if cur:
                subprocess.run([HDC, '-t', target, 'shell', f'kill -9 {cur}'],
                               capture_output=True)
                time.sleep(1.0)
                continue
            break
        subprocess.run([HDC, '-t', target, 'shell', f'aa start -a EntryAbility -b {bundle}'],
                       capture_output=True)
        for _ in range(120):
            time.sleep(0.5)
            cur = subprocess.run([HDC, '-t', target, 'shell', f'pidof {bundle}'],
                                 capture_output=True, text=True).stdout.strip()
            if cur and cur != str(pid_before_reopen2):
                pid2 = int(cur)
                break
        check('second reopen is a NEW instance', pid2 is not None and pid2 != pid_before_reopen2,
              f'{pid_before_reopen2} -> {pid2}')
        if pid2 is None:
            return 17
        ACTIVE_INSTANCE['pid'] = pid2
        _lr = m.hilog_rows()
        ACTIVE_INSTANCE['fence'] = _lr[-1] if _lr else ''
        time.sleep(6.0)
        fwd3, _ = vdo.acquire_forward(PORT)
        v_r3, hx_r3 = owner()
        check('second reopen body exact (save 2 persisted to disk)', v_r3 is not None and hx_r3 == hx_r2,
              f'v={v_r3} equal={hx_r3 == hx_r2}')
        if v_r3 is None or hx_r3 != hx_r2:
            return 14
        results['public_save_2']['reopen_pid'] = pid2
        results['public_save_2']['reopen_version'] = v_r3
        v_r, hx_r = v_r3, hx_r3
        # ---- 14. 成本原数（只收数，不落盘——落盘统一走 main 尾部归档，
        # 成功/失败/异常同路径，避免前置 return 绕过归档） ----
        rows = m.hilog_rows()
        results['cost']['preview_builds'] = len([r for r in rows if 'PREVIEW_BUILD ok' in r])
        try:
            rss = subprocess.run([HDC, '-t', target, 'shell',
                                  f'cat /proc/{ident2["pid"]}/status | grep VmRSS'],
                                 capture_output=True, text=True).stdout.strip()
        except Exception as e:
            rss = f'unavailable:{e!r}'
        results['cost']['rss_reopen'] = rss
        results['cost']['total_s'] = round(time.time() - t0, 1)
        for _fg in _frame_evidence_gate():
            failures.append(_fg)
        return 1 if failures else 0
    finally:
        if owned_forward:
            vdo.release_forward(PORT)


def _archive_epilogue(exit_code):
    """成功/失败/异常统一归档：保存最后判定点原回包、日志、身份、冻结基线和原因。

    只写 `results` 里已冻结的事实（判定包、身份、基线）与新鲜 hilog 行；
    **绝不另读 owner**冒充判定快照。归档本身失败具名非零（99）。返回最终退出码。
    """
    results['exit_code'] = exit_code
    try:
        results['failures'] = list(failures)
    except Exception:
        results['failures'] = ['failures_unreadable']
    archive_ok = True
    archive_note = ''
    try:
        hilog_text = '\n'.join(m.hilog_rows())
    except Exception as e:
        hilog_text = ''
        archive_note = f'hilog_unavailable:{e!r}'
        archive_ok = False
    try:
        (OUT / 'hilog-rows.txt').write_text(hilog_text)
    except Exception as e:
        archive_note = (archive_note + f' hilog_write_failed:{e!r}').strip()
        archive_ok = False
    try:
        (OUT / 'run.json').write_text(json.dumps(results, ensure_ascii=False, indent=2))
        archived = json.loads((OUT / 'run.json').read_text())
        if 'cost' not in archived:
            archive_note = (archive_note + ' run_json_missing_cost').strip()
            archive_ok = False
    except Exception as e:
        archive_note = (archive_note + f' run_json_failed:{e!r}').strip()
        archive_ok = False
    if archive_note:
        results['archive_note'] = archive_note
    print(json.dumps({'failures': results['failures'],
                      'exit_code': exit_code,
                      'archive_ok': archive_ok,
                      'archive_note': archive_note}, ensure_ascii=False))
    if not archive_ok:
        return 99
    return exit_code


def main():
    try:
        code = _main_impl()
    except Exception as e:
        code = 98
        try:
            results.setdefault('fatal', []).append(repr(e))
        except Exception:
            pass
    return _archive_epilogue(code)


def _self_test():
    body = 'abc'.encode()
    # 1) 冻结 caret=1 插 X → 期望 aXbc；错落点 abcX 必须判否
    want = expected_insert(body, 1, 1, 'X')
    assert want == 'aXbc'.encode(), want
    wrong = expected_insert(body, 0, 0, 'X')
    assert wrong == 'Xabc'.encode()
    assert want != wrong
    # 2) 非空选区 [1,2) 替换 QQ → aQQc
    want_r = expected_insert(body, 1, 2, 'QQ')
    assert want_r == 'aQQc'.encode(), want_r
    # 3) 标量边界（调实际 oracle）：😀 占 2 个 UTF-16 码元 / 4 个 UTF-8 字节，
    #    偏移 1 落在低代理上必须 None；旧实现在此写的是恒真断言。
    emoji = '😀'.encode()
    assert utf16_to_byte(emoji, 0) == 0
    assert utf16_to_byte(emoji, 1) is None
    assert utf16_to_byte(emoji, 2) == 4
    assert expected_insert('a😀b'.encode(), 2, 2, 'X') is None
    # 4) RI 对簇：a + 🇺🇳 = 3 码元，退格整对移除（调实际簇 oracle）
    pair = 'a\U0001F1FA\U0001F1F3b'.encode()
    # a(1) + RI(2) + RI(2) = 5 码元才是"整对之后"；偏移 3 落在两个 RI **之间**，
    # 那是拆分位置，不能用来证明整对删除。
    caret = utf16_to_byte(pair, 5)
    assert caret == 9, caret
    cl = grapheme_cluster_before(pair, caret)
    assert cl is not None and cl[1] == '\U0001F1FA\U0001F1F3', cl
    # 4b) 逐笔配对纯判定（调真实 walk/U16 工具）：各笔范围链/版本链/合法前缀逐笔核。
    _wprev = 'abcdef'.encode()
    _ok, _rs, _ec = verify_stroke_walk(_wprev, 3, (3, 4), 'QQ', [((3, 4), 2, 11)], 10)
    assert _ok and _ec == 5, (_rs, _ec)
    _ok, _rs, _ec = verify_stroke_walk(_wprev, 3, (3, 4), 'QQ',
                                       [((3, 4), 1, 11), ((4, 4), 1, 12)], 10)
    assert _ok and _ec == 5, (_rs, _ec)
    _ok, _rs, _ec = verify_stroke_walk('ab'.encode(), 1, None, '😀', [((1, 1), 4, 21)], 20)
    assert _ok and _ec == 3, (_rs, _ec)
    _ok, _rs, _ec = verify_stroke_walk(''.encode(), 0, None, '👩\u200d🚀',
                                       [((0, 0), 4, 31), ((2, 2), 7, 32)], 30)
    assert _ok and _ec == 5, (_rs, _ec)
    _ok, _rs, _ec = verify_stroke_walk(_wprev, 3, None, 'QQQ',
                                       [((8, 8), 1, 41), ((9, 9), 1, 42), ((10, 10), 1, 43)], 40)
    assert _ok and _ec == 11, (_rs, _ec)
    _bad, _rs, _ = verify_stroke_walk(_wprev, 3, (3, 4), 'QQ',
                                      [((3, 4), 1, 11), ((4, 4), 1, 13)], 10)
    assert not _bad and _rs == 'version_chain_gap', _rs
    _bad, _rs, _ = verify_stroke_walk(_wprev, 3, (3, 4), 'QQ', [((3, 4), 2, 15)], 10)
    assert not _bad and _rs == 'first_stroke_not_next_version', _rs
    _bad, _rs, _ = verify_stroke_walk(_wprev, 3, (3, 4), 'QQ', [((2, 4), 2, 11)], 10)
    assert not _bad and _rs == 'first_range_not_frozen_span', _rs
    _bad, _rs, _ = verify_stroke_walk('Aé'.encode(), 0, None, 'Aé', [((0, 0), 2, 11)], 10)
    assert not _bad and _rs == 'chunk_not_legal_prefix', _rs
    # 4c) **实际备注冻结调用点** `freeze_adopted_caret`：正控与逐类错来源拒绝。
    #     旧实现正则 9 组却读 group(10)，合法 ADOPTED2 行在这里必抛 IndexError，
    #     冻结永远不成立（round5 后复核复现）。现在这些形状全部经过生产同一函数。
    _auth = {'node': 313, 'resource': 7, 'kind': 10, 'binding': 9, 'ctx': 26, 'gen': 1}
    # hilog 取列的**边界**适配器（设备路径用同一个 `vdo.row_pid`）；被检验的
    # 归属决策在被测函数内部，不在这里。
    _hilog_pid = lambda r: int(r.split()[2])

    def _adopted(**kw):
        f = {'node': 313, 'resource': 7, 'kind': 10, 'sel': '0:0', 'projection': 51,
             'binding': 9, 'owner_version': 1, 'source_ctx': 26, 'source_gen': 1}
        f.update(kw)
        return ('10-06 01:00:00.000 27682 27860 I A00000/CjguiWindow: '
                'CJGUI_OWNED_SELECTION_ADOPTED2 node=%(node)d resource=%(resource)d '
                'kind=%(kind)d sel=%(sel)s projection=%(projection)d '
                'binding=%(binding)d owner_version=%(owner_version)d '
                'source_ctx=%(source_ctx)s source_gen=%(source_gen)s' % f)

    _hit, _why = freeze_adopted_caret([_adopted(sel='6:6')], 313, _auth, 1, 27682,
                                      pid_of_row=_hilog_pid)
    assert _hit is not None and _hit['selection'] == (6, 6) and _hit['owner_version'] == 1, \
        (_hit, _why)
    for _name, _row, _want in [
            ('旧 ctx 的采纳不解锁新会话', _adopted(source_ctx=99, sel='6:6'), 'source_ctx_mismatch'),
            ('旧 gen 的采纳不解锁新会话', _adopted(source_gen=88, sel='6:6'), 'source_gen_mismatch'),
            ('别的 resource 的采纳计数不可借', _adopted(resource=8, sel='6:6'), 'resource_mismatch'),
            ('别的 kind 的采纳计数不可借', _adopted(kind=1, sel='6:6'), 'kind_mismatch'),
            ('同 node 换绑不算当前采纳', _adopted(binding=77, sel='6:6'), 'binding_mismatch'),
            ('owner 版本已推进不算当前落点', _adopted(owner_version=2, sel='6:6'),
             'owner_version_mismatch'),
            ('非空选区的采纳不是 caret', _adopted(sel='6:9'), 'non_collapsed'),
            ('别的实例的数值重合不计', _adopted(sel='6:6').replace(' 27682 ', ' 99999 ', 1),
             'foreign_pid')]:
        _badf, _badr = freeze_adopted_caret([_row], 313, _auth, 1, 27682,
                                            pid_of_row=_hilog_pid)
        assert _badf is None and _want in (_badr or ''), (_name, _badr)
    # 缺 owner 版本 / 缺来源身份 / 来源为 `unverified` 的行一律不作冻结来源。
    _miss, _why = freeze_adopted_caret(
        ['10-06 01:00:00.000 27682 27860 I A00000/CjguiWindow: '
         'CJGUI_OWNED_SELECTION_ADOPTED2 node=313 resource=7 kind=10 sel=6:6 '
         'projection=51 binding=9'], 313, _auth, 1, 27682, pid_of_row=_hilog_pid)
    assert _miss is None and 'adoption_source_identity_absent' in (_why or ''), _why
    _unv, _why = freeze_adopted_caret(
        [_adopted(sel='6:6', source_ctx='unverified', source_gen='unverified')],
        313, _auth, 1, 27682, pid_of_row=_hilog_pid)
    assert _unv is None and 'adoption_source_not_numeric' in (_why or ''), _why
    assert freeze_adopted_caret([], 313, _auth, 1, 27682, pid_of_row=_hilog_pid)[0] is None
    _bad, _rs, _ = verify_stroke_walk(_wprev, 3, None, 'QQ', [((3, 4), 2, 11)], 10)
    assert not _bad and _rs == 'insert_first_range_not_collapsed', _rs
    _bad, _rs, _ = verify_stroke_walk(_wprev, 3, (3, 4), 'QQ',
                                      [((3, 4), 1, 11), ((4, 4), 1, 12), ((5, 5), 1, 13)], 10)
    assert not _bad and _rs == 'more_strokes_than_chars', _rs
    _bad, _rs, _ = verify_stroke_walk(_wprev, 3, (3, 4), 'QQ',
                                      [((3, 4), 1, 11), ((9, 9), 1, 12)], 10)
    assert not _bad and _rs == 'range_not_at_running_caret', _rs
    _bad, _rs, _ = verify_stroke_walk('a😀b'.encode(), 2, None, 'X', [((2, 2), 1, 11)], 10)
    assert not _bad and _rs == 'caret_splits_scalar', _rs
    _bad, _rs, _ = verify_stroke_walk(_wprev, 3, None, 'QQ', [((3, 3), 1, 11)], 10)
    assert not _bad and _rs == 'input_not_fully_consumed', _rs
    # 5) 恢复证据门（调**既有真实**判定函数，非字面量断言，更非自行拼接日志）。
    # 直接调用 vdo.body_restore_evidence 及共享原语，保留两条合法路径：
    # ①显式恢复票ACK＋同请求窗口ADOPTED；②挂载观测＋匹配窗口采纳。
    # 为避免执行 vdo 模块（有 import 时副作用），与指导 replay 同样做 AST 提取。
    import ast as _ast
    _dual_src = HERE / 'verify_pharos_dual_owner.py'
    _tree = _ast.parse(_dual_src.read_text(encoding='utf-8'))
    _names = {'_mount_lifecycle', '_identity_mismatch', 'body_restore_evidence',
              '_version_behind'}
    _funcs = [n for n in _tree.body if isinstance(n, _ast.FunctionDef) and n.name in _names]
    assert {n.name for n in _funcs} == _names
    _ns = {'re': re, 'BODY_FIELD': 'pharos-editor-body'}
    exec(compile(_ast.Module(body=_funcs, type_ignores=[]), str(_dual_src), 'exec'), _ns)
    _body = _ns['body_restore_evidence']
    _focus = ('platform focus node=107 ctx=7 field=pharos-editor-body '
              'resource=54 kind=10 binding=6 v=36')
    _key = 'app1/s1/c7/e1/m1'
    _mount = 'proxy mounted key=%s field=pharos-editor-body' % _key
    _confirmed = ('ime selection confirmed [3,3) rc=0 (shared lifecycle) '
                  'mount=%s field=pharos-editor-body' % _key)
    _installed = ('ime proxy selection terminal=INSTALLED reason=attach_confirmed '
                  'target=[3,3) mount=%s field=pharos-editor-body' % _key)
    _hint = {'ctx': 7, 'node': 107, 'field': 'pharos-editor-body', 'resource': 54,
             'kind': 10, 'binding': 6, 'v': 36, 'gen': 1, 'live': True}
    _base = [_focus, _mount, _confirmed, _installed]
    # 5a) confirmed＋INSTALLED 无窗口采纳 ⇒ 拒绝（返回 None）。
    _r = _body(_base, 0, 107, 1, 'main', owner_version=2, identity_hint=_hint)
    assert _r is None, _r
    # 5b) 历史安装俱在但当前读回 edit=none ⇒ 拒绝（不借旧日志）。
    # 行集含 ack+ADOPTED（与指导反例一致），但 identity_hint 明确无当前编辑。
    _r = _body(_base + [
        'proxy restore ack accepted request=4 ctx=7 node=107 installed=3:3 v=36',
        ('PHAROS_OHOS_RESTORE_ADOPTED count=2 request=4 ctx=7 node=107 '
         'adopted=3:3 owner_version=2 v=36'),
    ], 0, 107, 1, 'main', owner_version=2, identity_hint={'live': False})
    assert _r is not None and _r.get('source') == 'restore_ack_no_current_identity', _r
    # 5c) 合法显式恢复票（UNCONFIRMED 让位＋ACK＋同请求 ADOPTED）⇒ 接受 [3,3]。
    _explicit = [_focus, _mount,
                 ('ime proxy selection terminal=UNCONFIRMED reason=restore_task_took_over '
                  'target=[3,3) mount=%s field=pharos-editor-body' % _key),
                 ('proxy restore ack accepted request=4 ctx=7 node=107 installed=3:3 v=36'),
                 ('PHAROS_OHOS_RESTORE_ADOPTED count=2 request=4 ctx=7 node=107 '
                  'adopted=3:3 owner_version=2 v=36')]
    _r = _body(_explicit, 0, 107, 1, 'main', owner_version=2, identity_hint=_hint)
    assert _r is not None and _r.get('source') == 'restore_ack', _r
    assert tuple(_r.get('sel')) == (3, 3), _r
    # 6) 路由层经真实 freeze 调用点（非仅底层守卫）：surface 缺失/未知必须在触及
    #    设备前具名拒绝；映射表必须与生产绑定一致（visual=190 carrier，source=107）。
    assert SURFACE_TARGETS['visual']['node'] == 190
    assert SURFACE_TARGETS['source']['node'] == 107
    assert SURFACE_TARGETS['note']['node'] == 313
    _r, _d, _a = freeze_body_selection(prev_v=1, surface=None)
    assert _r is None and _d.get('source') == 'freeze_surface_unspecified', (_r, _d)
    _r, _d, _a = freeze_body_selection(prev_v=1, surface='bogus-surface')
    assert _r is None and _d.get('source') == 'freeze_surface_unspecified', (_r, _d)
    print(json.dumps({'self_test': 'ok'}))
    return 0


if __name__ == '__main__':
    if '--self-test-negative' in sys.argv:
        sys.exit(_self_test())
    sys.exit(main())

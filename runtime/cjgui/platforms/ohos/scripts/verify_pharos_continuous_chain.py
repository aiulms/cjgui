#!/usr/bin/env python3
"""H 连续写作包 E2：多屏文档整条连续链（normal Pharos 设备）。

链（同一次会话内连续执行，全部判据来自公开路径）：
  L1 baseline   working copy 逐字节 == 多屏夹具（2971B/25 段）
  L2 ime-edit   IME 输入标记 → owner 逐字节 oracle + 版本恰 +1
  L3 kb-caret   键盘展开下换行 → caret 始终在键盘之上（A 的可见性判据）
  L4 cross-sel  可视面跨段落拖选 → 冻结源域跨段落分隔符 → 精确替换 → Undo 精确复原
  L5 scroll-edit 滚动离开再回来 → 立即输入落到正确绝对源位置
  L6 agent-edit 公开通道 REPLACE_RANGE 追加段落后 → 人继续输入不丢落点
  L7 persist    SAVE → 工作文件落盘逐字节一致 → 正常关闭新实例 → 读回仍一致

用法：python3 verify_pharos_continuous_chain.py --target 127.0.0.1:5555
      --port 28991 --out <dir>
"""
import argparse
import importlib.util
import json
import re
import sys
import time
from pathlib import Path

HERE = Path(__file__).resolve().parent
_spec = importlib.util.spec_from_file_location(
    'pharos_driver', HERE / 'h_source_preview_consumption.py')
m = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(m)
_vdo_spec = importlib.util.spec_from_file_location('vdo', HERE / 'verify_pharos_dual_owner.py')
vdo = importlib.util.module_from_spec(_vdo_spec)
sys.modules['vdo'] = vdo
_vdo_spec.loader.exec_module(vdo)
sys.path.insert(0, str(HERE))
import strict_utf16  # noqa: E402

PORT = 0
FIXTURE = Path('/tmp/continuous-writing-fixture.md')
ADOPTED2_RE = re.compile(
    r"CJGUI_OWNED_SELECTION_ADOPTED2 node=(\d+) resource=(-?\d+) kind=(\d+) "
    r"sel=(\d+):(\d+) projection=(-?\d+) binding=(\d+)")
CARET_RE = re.compile(
    r"caret geometry session=(\d+) ctx=(-?\d+) caret=(\d+) affinity=(-?\d+) "
    r"x=([\d.]+) top=([\d.]+) bottom=([\d.]+)")
KBD_RE = re.compile(r"keyboard overlay top_px=(-?\d+)")


def app_rows():
    return [r for r in m.hilog_rows() if 'Cjgui' in r]


def fence():
    rr = app_rows()
    return rr[-1] if rr else ''


def rows_since(f, pat, tail=6000):
    out, seen = [], False
    for r in app_rows()[-tail:]:
        if not seen:
            if f in r:
                seen = True
            continue
        if pat.search(r):
            out.append(r[-220:])
    return out


def read_doc():
    v, hx = m.read_all(PORT)
    return v, bytes.fromhex(hx)


def save_doc():
    v, _ = read_doc()
    before = fence()
    resource=m.current_document_resource(m.ctx(PORT))
    resp = m.request(["PROTOCOL CJGUI_SHARED_OPERATION/2", f"AUTH {m.CAP}",
                      f"INVOKE {v} SAVE 1 0", f"ID {resource}"], PORT)
    deadline = time.time() + 15
    while time.time() < deadline:
        hits = rows_since(before, re.compile(r'SAVE_POLL.*persisted=true'))
        if hits:
            mo = re.search(r'saved=(\d+) bytes=(\d+)', hits[-1])
            return (resp or '')[:120], (mo.groups() if mo else None), hits[-1][-140:]
        time.sleep(0.4)
    return (resp or '')[:120], None, 'no_save_row'


def type_text(text):
    m.uitest('text', text)


def focus_editor(tap_vp=(150, 300)):
    origin = m.surface_origin_px() or (0.0, 137.0)
    m.uitest('click', str(int(origin[0] + tap_vp[0] * 3.5)), str(int(origin[1] + tap_vp[1] * 3.5)))
    time.sleep(1.4)


def hide_keyboard():
    m.uitest('keyEvent', '2')
    time.sleep(1.0)


def caret_rec():
    got = None
    for r in app_rows()[-2000:]:
        if CARET_RE.search(r):
            got = r
    if not got:
        return None
    mo = CARET_RE.search(got)
    origin = m.surface_origin_px() or (0.0, 137.0)
    return {'caret': int(mo.group(3)), 'top_vp': float(mo.group(6)), 'bottom_vp': float(mo.group(7))}


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


def wait_body_exact(want: bytes, version_before, timeout=12.0):
    deadline = time.time() + timeout
    last = None
    while time.time() < deadline:
        v, cur = read_doc()
        last = (v, cur)
        if v > version_before:
            if cur == want:
                return v, True
            time.sleep(0.3)
            continue
        time.sleep(0.25)
    return (last[0] if last else None), False


def utf16_to_bytes(buf: bytes, off16: int):
    return strict_utf16.utf16_to_byte_offset(buf, off16)


def geo_blocks():
    state = m.public_owner_state(PORT)
    geo = m.parse_geo_section(state) if state else None
    if not geo:
        return None, None
    origin = m.surface_origin_px()
    recs = [r for r in geo['records'] if r['semantic'] == 'pharos-editor-block'
            and r['node'] >= 1000 and not r['invisible'] and r['visible'][2] >= 24 and r['visible'][3] >= 8]
    recs.sort(key=lambda r: r['node'])
    return recs, (geo, origin)


def vp_to_px(geo_origin, x_vp, y_vp):
    geo, origin = geo_origin
    d = geo['density']
    return (int(origin[0] + x_vp * d), int(origin[1] + y_vp * d))


def ensure_preview(results, tag='chain-to-visual'):
    return vdo.reach_mode(PORT, 'preview', results, tag)


def arm_presentation_drag():
    """设备实测前置：presentation BEGIN 的接受依赖「最近的编辑焦点 + 键盘收起」。"""
    focus_editor()
    hide_keyboard()


def run(out: Path):
    res = {'legs': []}

    def ime_health(tag: str, force: bool = False) -> bool:
        """One input intent; failure preserves the instance and stops this acceptance chain."""
        hv, hbody = read_doc()
        focus_editor()
        hcaret = None
        for _ in range(8):
            hcaret = caret_rec()
            if hcaret:
                break
            time.sleep(0.35)
        hbs = utf16_to_bytes(hbody, (hcaret or {'caret': 0})['caret'])
        if hbs is None:
            return False
        hwant = hbody[:hbs] + '健'.encode() + hbody[hbs:]
        type_text('健')
        hv2, ok = wait_body_exact(hwant, hv, timeout=8.0)
        if ok:
            res['legs'].append({'leg': 'health_' + tag, 'ok': True, 'version': [hv, hv2]})
            return True
        m.diag_snapshot(out, 'health-failed-' + tag)
        res['legs'].append({'leg': 'health_' + tag, 'ok': False,
                            'note': 'single input failed; same-instance evidence preserved'})
        return False

    fixture = FIXTURE.read_bytes()

    # The current private document must already be imported through the system picker.
    v_seed, body_seed = read_doc()
    if body_seed != fixture:
        res['legs'].append({'leg':'L0_imported_fixture','ok':False,'reason':'current_document_differs; no_reseed'})
        return res

    # ---- L1 baseline ----
    v0, cur = read_doc()
    res['legs'].append({'leg': 'L1_baseline', 'ok': cur == fixture,
                        'version': v0, 'bytes': len(cur), 'fixture_bytes': len(fixture)})

    # ---- 链头单次健康检查：失败保留同实例原始证据 ----
    if not ime_health('pre_write'):
        return res

    # ---- L2 IME 单笔输入（owner 逐字节 oracle，版本恰 +1）----
    focus_editor()
    v_before, before = read_doc()
    caret = None
    for _ in range(10):
        caret = caret_rec()
        if caret:
            break
        time.sleep(0.4)
    caret = caret or {'caret': 0}
    ins_off16 = caret.get('caret', 0)
    bs = utf16_to_bytes(before, ins_off16)
    marker = '甲'
    want = before[:bs] + marker.encode() + before[bs:] if bs is not None else b''
    type_text(marker)
    v_after, ok_exact = wait_body_exact(want, v_before)
    res['legs'].append({'leg': 'L2_ime_edit', 'ok': ok_exact and v_after == v_before + 1,
                        'version': [v_before, v_after], 'insert_byte': bs,
                        'caret16': ins_off16, 'marker': marker,
                        'exact': ok_exact, 'delta_one': v_after == v_before + 1})

    # ---- L3 键盘展开下换行：caret 始终在键盘之上 ----
    steps = []
    for i in range(4):
        m.uitest('keyEvent', '2054')
        time.sleep(0.8)
        got = None
        for _ in range(6):
            got = caret_rec()
            if got:
                break
            time.sleep(0.3)
        steps.append({'i': i, 'caret': got, 'kbd_vp': keyboard_top_vp()})
    rec = steps[-1]['caret'] if steps else None
    kbd = keyboard_top_vp()
    ok3 = bool(rec and kbd and rec['bottom_vp'] <= kbd + 1.0)
    res['legs'].append({'leg': 'L3_keyboard_newline', 'ok': ok3, 'steps': steps,
                        'final_caret': rec, 'keyboard_top_vp': kbd})
    # 把换行退掉，链的后续腿基于同一正文
    for i in range(4):
        m.uitest('keyEvent', '2055')
        time.sleep(0.5)
    v_chk, cur_chk = read_doc()
    res['legs'][-1]['body_restored'] = cur_chk == want
    res['legs'][-1]['ok'] = ok3 and cur_chk == want

    # ---- L5 滚动往返后立即输入 ----
    focus_editor()
    base_v, base_body = read_doc()
    cur_caret = caret_rec() or {'caret': 0}
    off16 = cur_caret['caret']
    origin = m.surface_origin_px() or (0.0, 137.0)
    for _ in range(2):
        m.uitest('swipe', str(int(origin[0] + 180 * 3.5)), str(int(origin[1] + 420 * 3.5)),
                 str(int(origin[0] + 180 * 3.5)), str(int(origin[1] + 120 * 3.5)), '300')
        time.sleep(0.8)
    for _ in range(2):
        m.uitest('swipe', str(int(origin[0] + 180 * 3.5)), str(int(origin[1] + 120 * 3.5)),
                 str(int(origin[0] + 180 * 3.5)), str(int(origin[1] + 420 * 3.5)), '300')
        time.sleep(0.8)
    focus_editor(tap_vp=(150, 300))
    caret5 = caret_rec() or {'caret': 0}
    bs5 = utf16_to_bytes(base_body, caret5['caret'])
    want5 = base_body[:bs5] + '乙'.encode() + base_body[bs5:] if bs5 is not None else b''
    type_text('乙')
    v5, ok5 = wait_body_exact(want5, base_v)
    res['legs'].append({'leg': 'L5_scroll_then_edit', 'ok': ok5 and v5 == base_v + 1,
                        'caret16_after_scroll_roundtrip': caret5['caret'],
                        'insert_byte': bs5, 'exact': ok5, 'version': [base_v, v5]})
    v5b, body5 = read_doc()

    # ---- L6 Agent 改版后继续输入 ----
    add = '\n\n第六节：Agent 追加段落。链上继续输入应落到正确绝对源位置。\n'
    resp = m.agent_replace(PORT, len(body5), len(body5), add.encode().hex(), v5b)
    time.sleep(1.2)
    v6a, body6a = read_doc()
    appended = body6a == body5 + add.encode()
    caret6 = caret_rec() or {'caret': 0}
    bs6 = utf16_to_bytes(body6a, caret6['caret'])
    want6 = body6a[:bs6] + '丁'.encode() + body6a[bs6:] if bs6 is not None else b''
    type_text('丁')
    v6, ok6 = wait_body_exact(want6, v6a)
    res['legs'].append({'leg': 'L6_agent_then_human_edit', 'ok': appended and ok6 and v6 == v6a + 1,
                        'agent_resp': (resp or '')[:100], 'appended_exact': appended,
                        'caret16_after_agent': caret6['caret'], 'insert_byte': bs6,
                        'exact': ok6, 'versions': [v5b, v6a, v6]})
    v7, body7 = read_doc()

    # ---- L4 跨段落选择 → 精确替换 → Undo（复用已验证 6/6 的判定器，同文档同路径）----
    import subprocess
    # 设备实测：模式切换按钮的点击在**键盘展开时不生效**，先收起键盘并稳定。
    hide_keyboard()
    time.sleep(1.0)
    l4_out = out / 'l4-crossfragment'
    l4_out.parent.mkdir(parents=True, exist_ok=True)
    l4 = subprocess.run([sys.executable, str(HERE / 'verify_pharos_cross_fragment.py'),
                         '--target', args.target, '--out', str(l4_out)],
                        capture_output=True, text=True, timeout=900)
    l4_json = l4_out / 'cross-fragment.json'
    l4_data = json.loads(l4_json.read_text()) if l4_json.exists() else {}
    l4_legs = l4_data.get('legs', [])
    l4_ok = bool(l4_legs) and all(x.get('ok') for x in l4_legs)
    res['legs'].append({'leg': 'L4_cross_select_replace_undo', 'ok': l4_ok,
                        'rc': l4.returncode,
                        'summary': {x.get('leg'): x.get('ok') for x in l4_legs},
                        'stdout_tail': (l4.stdout or '')[-200:],
                        'detail': l4_data.get('legs', [])})

    # 回到 source 面继续写作腿
    hide_keyboard()
    ok_src, outcome_src = vdo.reach_mode(PORT, 'source', res, 'chain-to-source')
    time.sleep(1.0)
    v_now, body_now = read_doc()

    # ---- L7 保存 → 落盘一致 → 新实例重开全文一致 ----
    save_resp, saved_pair, save_row = save_doc()
    context=m.ctx(PORT)
    resource=m.current_document_resource(context)
    path_hex=re.search(rf'FIELD {resource} filePath STRING \d+ ([0-9A-Fa-f]+)',context).group(1)
    work_path=bytes.fromhex(path_hex).decode().replace('/data/storage/el2/base/haps/entry/files','/data/app/el2/100/base/com.pharos.mark/haps/entry/files',1)
    disk_path=out/'working-copy-readback.md'
    m.hdc('file','recv',work_path,str(disk_path))
    disk=disk_path.read_bytes() if disk_path.exists() else b''
    pers_ok=disk==body7
    before_pid=m.hdc('shell','pidof','com.pharos.mark').stdout.strip()
    close_result=m.close_current_recent_task('com.pharos.mark',out)
    res['normal_close']=close_result
    if not close_result['closed']:
        res['legs'].append({'leg':'L7_normal_close','ok':False,'pid':before_pid})
        return res
    m.hdc('shell','aa','start','-a','EntryAbility','-b','com.pharos.mark')
    deadline=time.monotonic()+12
    reopen_ok=False
    v8=-1;body8=b''
    while time.monotonic()<deadline:
        try:
            v8,body8=read_doc()
            reopen_ok=body8==body7
            if reopen_ok:break
        except (OSError,RuntimeError,ConnectionError):pass
        time.sleep(.2)
    res['legs'].append({'leg': 'L7_save_reopen', 'ok': pers_ok and reopen_ok,
                        'save_resp': save_resp, 'save_row': save_row,
                        'disk_exact': pers_ok, 'disk_bytes': len(disk),
                        'reopen_exact': reopen_ok, 'reopen_version': v8,
                        'expected_bytes': len(body7)})
    res['final_body_sha256_prefix'] = __import__('hashlib').sha256(body7).hexdigest()[:16]
    return res


def main():
    global args, PORT
    ap = argparse.ArgumentParser()
    ap.add_argument('--target', required=True)
    ap.add_argument('--port', type=int, default=28991)
    ap.add_argument('--out', required=True)
    args = ap.parse_args()
    PORT = args.port
    m.TARGET = args.target
    out = Path(args.out)
    out.mkdir(parents=True, exist_ok=False)
    res = run(out)
    (out / 'continuous_chain.json').write_text(json.dumps(res, ensure_ascii=False, indent=2))
    ok = all(leg.get('ok') for leg in res['legs'])
    print(json.dumps({'ok': ok, 'legs': {l['leg']: l['ok'] for l in res['legs']}}, ensure_ascii=False))
    return 0 if ok else 1


if __name__ == '__main__':
    sys.exit(main())

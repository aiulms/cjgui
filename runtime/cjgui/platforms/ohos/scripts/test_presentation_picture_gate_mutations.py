#!/usr/bin/env python3
"""显示契约验收门的变异判别（离线，不动设备、不构建）。

r16 的教训：一条"看起来在核画面"的门可以在**矩形错位、墨迹被卡片填充淹没、空值腿
被真值判断整条排除**三种情况下全绿，而画面其实是空的。本夹具不测产品，只测判据
本身——把已归档的 r16 事实包按每种失败方式改一笔，门必须点名它。

三种变异各对应一处真实自伤：
1. 换帧：把某腿的截图/裁图换成上一腿的（Astra 建议的廉价负控）⇒ 必须报
   `identical_note_box_for_different_values`，且**包含空值腿**（旧实现因
   `owner_note_hex` 真值判断把空正文整条排除，这一对当年没红）。
2. accepted 值被省略成空：owner 有正文、渲染线程 accepted 值为空 ⇒ 必须报
   `accepted_value_not_owner_value`（这就是本次根因的判别面）。
3. 裁图矩形漂移/被键盘侵入：state 在快门前后不一致 ⇒ `note_box_crop_rect_drifted`，
   不得当成"墨迹为 0 所以画面空"或"墨迹非 0 所以有字"。

用法：python3 test_presentation_picture_gate_mutations.py <r16 presentation-consumer.json>
"""
import copy
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import verify_thermo_presentation_consumer as V    # noqa: E402

fails = []


def check(name, ok, detail=''):
    print(f"  {'OK  ' if ok else 'FAIL'} {name}" + (f': {detail}' if detail else ''))
    if not ok:
        fails.append(name)


def gaps_of(legs):
    return V.evidence_gaps(legs)


def main(path):
    doc = json.load(open(path))
    legs = [e for e in doc['legs'] if isinstance(e.get('evidence'), dict)]
    check('fixture_has_legs', len(legs) >= 4, f'{len(legs)} legs with evidence')

    # --- 变异 1：换帧（本腿裁图 = 上一腿裁图），值不同 ⇒ 必须红 ---
    m1 = copy.deepcopy(legs)
    for i in range(1, len(m1)):
        prev, cur = legs[i - 1]['evidence'], m1[i]['evidence']
        if prev['note_picture'].get('crop_sha256'):
            cur['note_picture']['crop_sha256'] = prev['note_picture']['crop_sha256']
            cur['note_picture']['bounds_px'] = prev['note_picture'].get('bounds_px')
    g1 = gaps_of(m1)
    hit = [g for g in g1 if g.startswith('identical_note_box_for_different_values')]
    check('mutation_swap_frame_detected', bool(hit), str(hit)[:160])
    # 空正文腿必须参与比较（r16 真实漏判：v=0 与 v='AB' 同图没被记）。
    names = ' '.join(hit)
    pair = [e['evidence']['label'] for e in m1
            if e['evidence'].get('owner_note_hex') == '']
    check('empty_value_leg_participates', bool(pair) and all(p in names for p in pair),
          f'empty legs={pair} in {names[:120]}')

    # --- 变异 2：原始 accepted 行被改为空值 ⇒ 真实解析 + 真实比较必须红 ---
    m2 = copy.deepcopy(legs)
    for e in m2:
        ev = e['evidence']
        if ev.get('owner_note_hex'):
            raw = (f"10-06 14:00:00.000 1 2 I A00000/CjguiRenderer: "
                   f"accepted node={V.NODE} ctx=9 value= v=999")
            ap = V.accepted_projection_row([raw], V.NODE)
            ev['accepted_projection'] = ap
            owner_text = bytes.fromhex(ev['owner_note_hex']).decode('utf-8', 'replace')
            mm = V.derive_accepted_mismatch(ap.get('value'), owner_text)
            if mm is not None:
                ev['accepted_value_mismatch'] = mm
            else:
                ev.pop('accepted_value_mismatch', None)
    g2 = gaps_of(m2)
    hit2 = [g for g in g2 if 'accepted_value_not_owner_value' in g]
    check('mutation_omitted_display_value_detected', bool(hit2), str(hit2)[:160])

    # --- 变异 3：矩形漂移（快门前后 state 不一致）⇒ 具名，不当通过 ---
    drift = V.note_ink_crop.__doc__ is not None
    _probe = V.note_ink_crop('/nonexistent-drift-probe.png', 'drift-probe', None)
    _pic = V.apply_shutter_drift({'snap': 'pre'}, {'snap': 'post'}, _probe)
    m3 = copy.deepcopy(legs)
    m3[0]['evidence']['note_picture'] = _pic
    g3 = gaps_of(m3)
    check('mutation_rect_drift_named',
          any('note_box_crop_rect_drifted' in g for g in g3), str(g3)[:160])
    check('crop_helper_takes_state_arg', drift and 'state' in
          V.note_ink_crop.__code__.co_varnames[:4],
          str(V.note_ink_crop.__code__.co_varnames[:4]))

    # --- 反-self-fulfilling：原样 r16 必须**已经**是红的（根因真实存在） ---
    g0 = gaps_of(legs)
    check('r16_original_is_red', bool(g0), str(g0)[:200])
    print('\n' + ('ALL MUTATIONS CAUGHT' if not fails else 'MUTATIONS MISSED: ' + str(fails)))
    return 0 if not fails else 1


if __name__ == '__main__':
    sys.exit(main(sys.argv[1] if len(sys.argv) > 1 else
                  '/Users/jiangxuanyang/Desktop/cangjie/artifacts/visual-edit-20261004/'
                  'guidance-review-20261005/h-viz-final-20261006/'
                  'thermo-consumer-r16/presentation-consumer.json'))

#!/usr/bin/env python3
"""thermo 拖选规划离线门：纯函数 plan_drag_from_facts 的判别全集。

无设备、无网络。覆盖指导固定判别：r25 可见点（y>1300）仍可单次投递；
真实遮挡/裁剪无效点零投递；origin/density/投影变化后 geo_id 必变（旧点
不得消费）；缺事实具名零投递；规划函数内无固定屏幕阈值。
"""
import inspect
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import verify_thermo_presentation_consumer as V
import h_source_preview_consumption as _m

FAILS = []


def check(name, cond, detail=''):
    print(('CASE_OK ' if cond else 'CASE_FAIL ') + name +
          ('' if cond else f' :: {detail}'))
    if not cond:
        FAILS.append(name)


R25B = {'bounds': (36, 397, 305, 64), 'visible': (36, 397, 305, 64),
        'invisible': False, 'binding': 1, 'projection': 153,
        'clips': [(0.0, 0.0, 377.0, 461.0, 0.0),
                  (12.0, 310.0, 353.0, 340.0, 0.0)]}
ORIGIN = (0.0, 137.0)


def main():
    # 1 r25b 原事实：中线 1638px（>1300）但可见 → 可单次投递，坐标与实证一致。
    plan, why = V.plan_drag_from_facts(R25B, ORIGIN, 3.5)
    check('r25-visible-deliverable', plan is not None and why == 'reachable',
          f'{plan} {why}')
    check('r25-coords', plan is not None and
          (plan['x1'], plan['y1'], plan['x2'], plan['y2']) == (171, 1638, 250, 1638),
          f'{plan}')

    # 2 真实遮挡：命中带被 clip 压到不足 8vp → 零投递具名。
    squashed = dict(R25B, clips=[(12.0, 425.0, 353.0, 5.0, 0.0)])
    plan, why = V.plan_drag_from_facts(squashed, ORIGIN, 3.5)
    check('clipped-band-undelivered', plan is None and why == 'hit_band_too_narrow',
          f'{plan} {why}')

    # 3 右端被圆角 clip 切掉 → 零投递具名（起点仍在带内，终点出界）。
    cut = dict(R25B, clips=[(0.0, 0.0, 377.0, 461.0, 0.0),
                            (12.0, 310.0, 40.0, 340.0, 0.0)])
    plan, why = V.plan_drag_from_facts(cut, ORIGIN, 3.5)
    check('end-occluded-undelivered', plan is None and why == 'drag_end_occluded',
          f'{plan} {why}')

    # 4 缺事实具名零投递：记录缺席/不可见/原点缺席/密度缺席。
    for rec, origin, density, want in (
            (None, ORIGIN, 3.5, 'record_absent'),
            (dict(R25B, invisible=True), ORIGIN, 3.5, 'record_invisible'),
            (R25B, None, 3.5, 'surface_origin_absent'),
            (R25B, ORIGIN, 0, 'density_absent')):
        plan, why = V.plan_drag_from_facts(rec, origin, density)
        check(f'missing-facts-{want}', plan is None and why == want,
              f'{plan} {why}')

    # 5 代际：origin/density/投影任一变化 → geo_id 必变（旧点不得消费）。
    base = V.plan_drag_from_facts(R25B, ORIGIN, 3.5)[0]['geo_id']
    moved = V.plan_drag_from_facts(R25B, (0.0, 140.0), 3.5)[0]['geo_id']
    scaled = V.plan_drag_from_facts(R25B, ORIGIN, 3.0)[0]['geo_id']
    reproj = V.plan_drag_from_facts(dict(R25B, projection=154), ORIGIN, 3.5)[0]['geo_id']
    check('geo-id-tracks-facts', moved != base and scaled != base and reproj != base,
          'stale point reusable')
    same = V.plan_drag_from_facts(R25B, ORIGIN, 3.5)[0]['geo_id']
    check('geo-id-stable', same == base, 'identical facts differ')

    # 6 规划函数内无固定屏幕阈值（结构钉）。
    src = inspect.getsource(V.plan_drag_from_facts)
    check('no-fixed-threshold', '1300' not in src and '< 50' not in src, 'hardcoded gate')

    # 7 位移只认同基准可见位置：投影/绑定变化不是位移；基准变化不可比。
    band = ((0.0, 137.0), 3.5, (36, 397, 305, 64), (36, 397, 305, 64))
    check('same-band-no-displacement', V.band_displaced(band, band) is False, 'identical moved')
    reproj = ((0.0, 137.0), 3.5, (36, 397, 305, 64), (36, 397, 305, 64))
    check('projection-not-displacement', V.band_displaced(band, reproj) is False,
          'projection change misread')
    moved = ((0.0, 137.0), 3.5, (36, 310, 305, 64), (36, 310, 305, 64))
    check('visible-move-is-displacement', V.band_displaced(band, moved) is True, 'real move missed')
    rebased = ((0.0, 140.0), 3.5, (36, 397, 305, 64), (36, 397, 305, 64))
    check('basis-change-not-displacement', V.band_displaced(band, rebased) is False,
          'rebase misread')
    check('missing-not-displacement', V.band_displaced(None, moved) is False, 'None moved')

    # 8 滚动路径取自容器可达带：两端上行且过 clip；带不足/取不出具名 None。
    cont = {'bounds': (12, 310, 353, 340), 'visible': (12, 310, 353, 340),
            'invisible': False, 'binding': 1, 'projection': 7,
            'clips': [(0.0, 0.0, 377.0, 461.0, 0.0), (12.0, 310.0, 353.0, 340.0, 0.0)]}
    path = V.scroll_path_in_band(cont, ORIGIN, 3.5)
    ok_path = (path is not None and path[3] < path[1] and
               _m.point_in_clips((path[0] - ORIGIN[0]) / 3.5, (path[1] - ORIGIN[1]) / 3.5,
                                 cont['clips'], bounds=cont['bounds']) and
               _m.point_in_clips((path[2] - ORIGIN[0]) / 3.5, (path[3] - ORIGIN[1]) / 3.5,
                                 cont['clips'], bounds=cont['bounds']))
    check('scroll-path-in-band', ok_path, f'{path}')
    thin = dict(cont, clips=[(12.0, 400.0, 353.0, 5.0, 0.0)])
    check('scroll-path-unavailable', V.scroll_path_in_band(thin, ORIGIN, 3.5) is None,
          'squeezed band gave path')
    check('scroll-path-no-facts', V.scroll_path_in_band(None, ORIGIN, 3.5) is None,
          'missing record gave path')
    # 9 旧可见性入口反例经实际入口：窄可见带 [0,40,100,20] 下，真实
    # ensure_presentation_visible 发出的手势两端必须在带内（新 helper 给出
    # (50,52)→(50,48)）；旧固定公式的 (50,250)→(50,-170) 不得出现。
    # 全 IO 为替身（semantic/owner/origin/uitest/sleep），解析与路径为真实函数。
    import unittest.mock as _mock
    _owner = ("OWNER_STATE v=0 geo units=vp density=1.0 viewport=100x200 "
              "used=1 truncated=0 "
              "G1:thermo-card-scroll,b=1,p=7,c=1,i=0,40,100,20,"
              "v=0,40,100,20,vis=0,q=0,40,100,20,0")
    _drags = []
    # 注意：verifier 经 tc 调的 uitest 与 V._m 不是同一模块对象（tc 侧为独立
    # 装载副本）；origin 取自 V._m，uitest 取自 V.tc._m；两者都要替身。
    with _mock.patch.object(V.tc, 'readback_semantic_point', return_value=None), \
         _mock.patch.object(V.tc, 'readback_owner_state', return_value=_owner), \
         _mock.patch.object(V._m, 'surface_origin_px', return_value=(0.0, 0.0)), \
         _mock.patch.object(V.tc._m, 'surface_origin_px', return_value=(0.0, 0.0)), \
         _mock.patch.object(V.tc._m, 'uitest',
                            side_effect=lambda *a: _drags.append(a)), \
         _mock.patch('time.sleep', return_value=None):
        _pt, _why = V.ensure_presentation_visible()
    check('ensure-narrow-band-named', _pt is None and _why == 'scroll_field_absent',
          f'{_pt} {_why}')
    check('ensure-five-sends', len(_drags) == 5, f'{len(_drags)}')
    _in_band = all(
        len(a) == 5 and a[0] == 'drag' and
        all(v not in ('250', '-170') for v in a[1:]) and
        0 <= float(a[1]) < 100 and 40 <= float(a[2]) < 60 and
        0 <= float(a[3]) < 100 and 40 <= float(a[4]) < 60
        for a in _drags)
    check('ensure-drags-in-band', _in_band, f'{_drags[:2]}')
    check('ensure-exact-path', all(a[1:] == ('50', '52', '50', '48') for a in _drags),
          f'{_drags[:1]}')
    # 10 起点抬高：同一容器带，ceiling 压低起点后路径起点随之上移且仍在带内。
    tall = {'bounds': (12, 310, 353, 340), 'visible': (12, 310, 353, 165),
            'invisible': False, 'binding': 1, 'projection': 7,
            'clips': [(0.0, 0.0, 377.0, 475.0, 0.0)]}
    p0 = V.scroll_path_in_band(tall, (0.0, 137.0), 3.5)
    p1 = V.scroll_path_in_band(tall, (0.0, 137.0), 3.5, 392.5)
    check('scroll-ceiling-raises-start',
          p0 is not None and p1 is not None and p1[1] < p0[1] and
          310 <= (p1[1] - 137.0) / 3.5 < 475 and 310 <= (p1[3] - 137.0) / 3.5 < 475,
          f'{p0} {p1}')
    # 11 高带 ensure 集成：档位轮换，起点逐次抬高且始终在带内。
    _tall_owner = ("OWNER_STATE v=0 geo units=vp density=3.5 viewport=1320x2856 "
                   "used=1 truncated=0 "
                   "G1:thermo-card-scroll,b=1,p=7,c=1,i=12,310,353,340,"
                   "v=12,310,353,165,vis=0,q=0,0,377,475,0")
    _tdrags = []
    with _mock.patch.object(V.tc, 'readback_semantic_point', return_value=None), \
         _mock.patch.object(V.tc, 'readback_owner_state', return_value=_tall_owner), \
         _mock.patch.object(V._m, 'surface_origin_px', return_value=(0.0, 137.0)), \
         _mock.patch.object(V.tc._m, 'surface_origin_px', return_value=(0.0, 137.0)), \
         _mock.patch.object(V.tc._m, 'uitest',
                            side_effect=lambda *a: _tdrags.append(a)), \
         _mock.patch('time.sleep', return_value=None):
        _tpt, _twhy = V.ensure_presentation_visible()
    _starts = sorted({a[2] for a in _tdrags})
    check('ensure-tall-cycles-starts',
          _tpt is None and len(_tdrags) == 5 and len(_starts) == 3 and
          all(1250 <= int(y) <= 1771 for y in _starts),
          f'{_tpt} {_twhy} {_starts}')
    # 快乐路径：锚点可读回时零手势。
    with _mock.patch.object(V.tc, 'readback_semantic_point', return_value=(50, 50)), \
         _mock.patch.object(V.tc._m, 'uitest',
                            side_effect=lambda *a: _drags.append(a)), \
         _mock.patch('time.sleep', return_value=None):
        _n0 = len(_drags)
        _pt2, _why2 = V.ensure_presentation_visible()
    check('ensure-visible-no-drag', _pt2 == (50, 50) and _why2 == 'visible' and
          len(_drags) == _n0, f'{_pt2} {_why2}')

    if FAILS:
        print(f'DRAG_PLANNING_FAILED {len(FAILS)}')
        return 1
    print('DRAG_PLANNING_ALL_HOLD')
    return 0


if __name__ == '__main__':
    sys.exit(main())

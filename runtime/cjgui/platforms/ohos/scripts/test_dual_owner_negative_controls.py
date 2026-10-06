#!/usr/bin/env python3
"""R4 负控回归（h-source-preview-followup 2026-10-02 round4 后指导）。

执行**未改动**的 verify_pharos_dual_owner.main（AST 提取，替换设备/传输层），
用受控 owner 回包、受控日志行与受控 `uitest`（模式/几何替身）驱动总门。指导
复核的假绿负控在此必须变红：

  wrong-note-range       应替换冻结选区 [1,3)（bc→N），实际替换了 de → 总门失败；
  destructive-A-resume   A 续写必须落冻结 caret（removed=0），实际误删 b → 失败；
  zero-input / duplicate-write / missing-install-confirm / stale-log / note-cleared；
  restore-cross-node-ack 用**备注 node313** 的 ACK 冒充正文恢复 → 必须被拒；
  restore-ack-unadopted  平台已安装但窗口未采纳（无 RESTORE_ADOPTED）→ 必须被拒；
  restore-wrong-landing  框架恢复到别的落点 → a_resume_at_frozen_anchor=false；
  restore-not-installed  切回后无任何恢复证据 → a_restore_uninstalled；
  fence-evicted          内容围栏被环形日志淘汰 → 具名 evidence_lost（不退回 0 重扫）；
  anchor-out-of-range    旧版本越界锚 → a_anchor_not_mid_document；
  anchor-at-doc-end      文末默认位置冒充中段 → a_anchor_not_mid_document；
  helper-kick-required   模式切换不跟随时必须具名失败，且**只点一次**模式按钮、
                         不追加正文 kick（复核 R4 的"切换→正文补点→再切换"必须消失）。

设备/传输/`uitest` 全部替身；**待测的 `reach_mode` 与恢复解析是生产原文**（不从
harness 里 stub 掉）。断言的是**实际总程序**的退出码与 status。
"""
import argparse
import ast
import importlib.util
import json
import re
import sys
import unittest
from pathlib import Path
from types import SimpleNamespace

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent
SOURCE = ROOT / 'scripts' / 'verify_pharos_dual_owner.py'
DRIVER_HELPER = HERE / 'h_source_preview_consumption.py'

NOTE_FIELD = 'pharos-document-note'
BODY_FIELD = 'pharos-editor-body'


def _load_reason_table():
    """从**生产驱动源码**抽 reason(x) 三值常量（round10-D1 的映射表）。

    不在负控里另抄：这三值是判据的一部分（x≠0 不得映射成平台拒绝），抄一份就会
    与生产静默漂移。
    """
    src = (HERE / 'verify_pharos_dual_owner.py').read_text(encoding='utf-8')
    out = {}
    for name in ('REASON_PROTOCOL', 'REASON_PRESENT_FAILED', 'REASON_CANCELLED'):
        mo = re.search(rf'^{name} = (\d+)', src, re.M)
        if not mo:
            raise AssertionError(f'reason table entry not found: {name}')
        out[name] = int(mo.group(1))
    return out


def _load_face_prefixes(kind):
    """从**生产驱动源码**抽面分类词表（`_BODY_PREFIXES` / `_PREVIEW_PREFIXES`）。

    不在负控里另抄：分类词表是「产品声明 × 驱动独立期望」三方验证里的第三方，
    抄一份就变成同义反复，两层永远一致、分歧永不可能被发现。
    """
    src = (HERE / 'verify_pharos_dual_owner.py').read_text(encoding='utf-8')
    name = f"_{kind}_PREFIXES"
    mo = re.search(rf"^{name} = \((.*?)\)$", src, re.S | re.M)
    if not mo:
        raise AssertionError(f'face prefix table not found: {name}')
    return tuple(re.findall(r"'([^']+)'", mo.group(1)))


def _load_present_decision():
    """从**生产头文件**抽 `CjguiInternalRendererPresentDecision` 的真值。

    不在本文件里另抄一份数字：round9 首次实现凭印象把 1/2 当成 ACCEPTED/REJECTED，
    而真值是 NONE=0 PENDING=1 ACCEPTED=2 REJECTED=3（native/
    cjgui_internal_renderer.h:304），于是每次成功提交都被读成「被拒」——根因判据整个
    反向。从生产头文件抽取保证桩与生产同源：改枚举即失效，不会静默漂移。
    """
    header = HERE.parent.parent.parent / 'native' / 'cjgui_internal_renderer.h'
    text = header.read_text(encoding='utf-8')
    body = text.split('CjguiInternalRendererPresentDecision {', 1)[1].split('}', 1)[0]
    out = {name: int(value) for name, value in re.findall(
        r'CJGUI_INTERNAL_RENDERER_PRESENT_DECISION_(\w+)\s*=\s*(\d+)', body)}
    missing = {'NONE', 'PENDING', 'ACCEPTED', 'REJECTED'} - set(out)
    if missing:
        raise AssertionError(f'present decision enum incomplete: {sorted(missing)}')
    return out

TOGGLE = (150, 60)
BODY = (200, 300)
NOTE = (200, 400)


def _load_strict_utf16():
    spec = importlib.util.spec_from_file_location('strict_utf16_local', HERE / 'strict_utf16.py')
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


EXTRACT = ['hexs', 'mounted_key', 'confirmed_selection', 'accepted_node_id',
           'latest_body_anchor', 'log_fence', 'fence_index', 'wait_confirmed_selection',
           'last_adopted_count', '_mount_lifecycle', '_identity_mismatch',
           '_version_behind',
           'body_restore_evidence', 'expected_after_replacement',
           '_fence_start', 'accepted_commit_marker', '_classify_face',
           'scene_face', 'driver_face', 'current_mode', 'mode_trace', 'reach_mode',
           'public_state', 'public_snapshot', 'accepted_readback',
           'action_baseline', 'ticket_verdict', 'driver_face_from_snapshot',
           '_finish', 'main',
           'forward_rows', 'acquire_forward', 'release_forward', 'request', 'EvidenceLost']
# read_public / find_note_resource 保持受控 stub：提取它们会覆盖受控回包。
# 但 reach_mode / current_mode / scene_face / body_restore_evidence 是**生产原文**，
# 必须真实执行（复核 R4：不得把待测切换函数本身 stub 掉）。

_tree = ast.parse(SOURCE.read_text())
_nodes = [n for n in _tree.body if isinstance(n, (ast.FunctionDef, ast.ClassDef)) and n.name in EXTRACT]
assert {n.name for n in _nodes} == set(EXTRACT), "extraction mismatch: %r" % (
    set(EXTRACT) - {n.name for n in _nodes})
_MAIN_CODE = compile(ast.Module(body=_nodes, type_ignores=[]), str(SOURCE), 'exec')


class Log:
    """设备语义：日志只增不减（环形缓冲可淘汰前缀）。

    `reveal(n)` 推进可见上限；`evict_prefix(k)` 模拟环形缓冲丢弃最旧的行。"""

    def __init__(self, prefix, scripted):
        self.prefix = list(prefix)
        self.scripted = list(scripted)
        self.n = 0
        self.floor = 0

    def reveal(self, n):
        self.n = max(self.n, int(n))

    def append(self, rows):
        # 设备日志只增不减：新的帧追加在末尾（用于"再访预览"等第二次切换）。
        self.scripted = self.scripted[:self.n] + list(rows)
        self.n = len(self.scripted)

    def evict_prefix(self, k):
        self.floor = max(self.floor, int(k))

    def rows(self):
        return self.prefix + self.scripted[self.floor:self.n]


# 脚本行的固定下标（frame 边界）。
# round9-D：首帧与预览帧各多了一行**中性** `accepted commit`（提交标记的新锚），因此下面
# 每个边界都 +1。这些是**按行序**的固定下标，改 `_frame_rows` 的行数必须同步改。
IDX_PREP_FRAME = 4      # 0..3 首帧（node-rect / accepted / faces / 挂载）
IDX_PREP_ANCHOR = 8     # 4..7 准备点击的正文确认对 + 人手落点
IDX_PREVIEW_FRAME = 12  # 8..11 预览帧（node-rect / accepted / faces / 挂载）
IDX_NOTE_DRAG = 14      # 12..13 拖选后的备注确认对
IDX_RETURN_FRAME = 22   # 14..21 切回帧（accepted / 挂载 / faces / focus / 观测 / 采纳 / 绑定）


def _frame_rows(return_ack=None, return_sel=(1, 1), note_sel=(1, 3), human_anchor_sel=(1, 1),
                prep_sel=(1, 1), bind_owner=True, return_evidence=True):
    """构造与设备返回路径同形的脚本行（含 frame 分隔 node-rect）。"""
    rows = [
        # -- 首帧：正文面（accepted + 挂载） --
        '10-02 09:00:00.000 node-rect id=107 x=0 y=0 w=400 h=400 clip=(0,0,400,400)',
        '10-02 09:00:00.001 accepted node=107 semantic=pharos-editor-body '
        'kind=10 label=pharos-editor-body value=abc v=2',
        # round9-D：提交标记改读**中性** `accepted commit`（生产在两条 settle 路径
        # 发出）。通用层不再做 source/preview 分类（那是产品/驱动的语义），
        # 面由驱动的 _classify_face 按同版本 accepted node= 行自己判。
        '10-02 09:00:00.0015 accepted commit v=2 ticket=1 nodes=16 semantic=111111',
        '10-02 09:00:00.002 proxy mounted key=app1/s1/c3/e1/m1 field=pharos-editor-body',
        # -- 准备点击后的正文确认对（挂载安装） --
        '10-02 09:00:01.000 ime selection confirmed [%d,%d) rc=0 (shared lifecycle) '
        'mount=app1/s1/c3/e1/m1 field=pharos-editor-body' % prep_sel,
        '10-02 09:00:01.010 ime proxy selection terminal=INSTALLED reason=attach_confirmed '
        'target=[%d,%d) mount=app1/s1/c3/e1/m1 field=pharos-editor-body' % prep_sel,
        # -- 准备点击的平台实际人手落点 --
        '10-02 09:00:01.500 caret hit applied tap=(20.0,10.1) node=(333.0,96.0) kind=10 '
        'composed=3 caret=%d ok=1' % human_anchor_sel[0],
        '10-02 09:00:01.520 human anchor recorded origin=caret_hit seq=1 node=107 '
        'sel=%d:%d' % human_anchor_sel,
        # -- 预览帧：备注面 --
        '10-02 09:00:02.000 node-rect id=313 x=10 y=10 w=100 h=40 clip=(0,0,400,400)',
        '10-02 09:00:02.001 accepted node=313 semantic=pharos-document-note '
        'kind=10 label=pharos-document-note value=abcdef v=4',
        '10-02 09:00:02.0015 accepted commit v=4 ticket=2 nodes=19 semantic=222222',
        '10-02 09:00:02.002 proxy mounted key=app1/s1/c7/e1/m2 field=pharos-document-note',
        # -- 拖选后的备注确认对 --
        '10-02 09:00:03.000 ime selection confirmed [%d,%d) rc=0 (shared lifecycle) '
        'mount=app1/s1/c7/e1/m2 field=pharos-document-note' % note_sel,
        '10-02 09:00:03.010 ime proxy selection terminal=INSTALLED reason=attach_confirmed '
        'target=[%d,%d) mount=app1/s1/c7/e1/m2 field=pharos-document-note' % note_sel,
        # -- 切回帧：正文面 --
        '10-02 09:00:04.000 node-rect id=107 x=0 y=0 w=400 h=400 clip=(0,0,400,400)',
        '10-02 09:00:04.001 accepted node=107 semantic=pharos-editor-body '
        'kind=10 label=pharos-editor-body value=abc v=6',
        '10-02 09:00:04.002 proxy mounted key=app1/s1/c9/e1/m3 field=pharos-editor-body',
        '10-02 09:00:04.003 accepted commit v=6 ticket=3 nodes=16 semantic=333333',
    ]
    if return_evidence:
        # round7-A：三行都带**完整身份**（当前编辑身份 / 平台实际观测 / 窗口采纳），
        # 且三者逐字段一致——检查器按一个当前身份元组核验，不再只比 node+sel。
        rows.append('10-02 09:00:04.005 proxy restore armed request=5 ctx=9 node=107 '
                    'v=6 sel=1:1 units=3 deadline=0')
        rows.append('10-02 09:00:04.010 platform focus node=107 ctx=9 '
                    'field=pharos-editor-body resource=54 kind=10 binding=6 v=6')
        rows.append('10-02 09:00:04.020 ime selection observation forwarded ctx=9 sel=%d:%d '
                    'node=107 resource=54 kind=10 binding=6 v=6 native_changed=0' % return_sel)
        if bind_owner:
            # round6-A：快照路径的窗口采纳事实——同挂载的实际选择被窗口采用
            # （CJGUI_OWNED_SELECTION_ADOPTED2），单独 BIND_OWNER 不构成采纳。
            # round9-A：带**本事件自己的冻结来源**（生产在事件入队时冻结、出队时
            # 交回）。缺来源的采纳事实一律不作证据，因此正控必须给出来源。
            rows.append('10-02 09:00:04.025 window-diag: CJGUI_OWNED_SELECTION_ADOPTED2 '
                        'node=107 resource=54 kind=10 sel=%d:%d projection=6 binding=6 '
                        'owner_version=1 source_ctx=9 source_gen=1' % return_sel)
            rows.append('10-02 09:00:04.030 PHAROS_OHOS_BIND_OWNER owner=pharos-main '
                        'mirror_version=1 mirror_bytes=3 owner_version=1')
    for extra in (return_ack or []):
        rows.append(extra)
    return rows


def run_case(name, *, actual_a='a回bc', actual_b='aNdef', note_versions=None,
             scripted=None, prefix=None, main_hex='616263', human_anchor_sel=(1, 1),
             return_ack=None, return_sel=(1, 1), bind_owner=True, fail_toggle=False,
             fail_scene_follow=False, evict_on_return=False, meta=None,
             readback_state='default', anchor_mode='caret', body_span_sel=(2, 5),
             readback_overrides=None):
    """跑一次真实 main；返回 (exit_code, status, results)。"""
    if note_versions is None:
        b = b'abcdef'.hex()
        note_versions = [(1, b), (2, b), (2, b), (3, actual_b.encode().hex()),
                         (3, actual_b.encode().hex()), (3, actual_b.encode().hex())]
    # span 模式多一次 drag 零事务读：A 冻结读序 5 次（caret 模式 4 次）。
    _a_reads = 5 if anchor_mode == 'span' else 4
    main_replies = iter([(1, main_hex)] * _a_reads + [(2, actual_a.encode().hex())])
    note_replies = iter(note_versions)
    if scripted is None:
        scripted = _frame_rows(return_ack=return_ack, return_sel=return_sel,
                               human_anchor_sel=human_anchor_sel, bind_owner=bind_owner)
    if prefix is None:
        # 历史行：上一轮的旧确认（含旧挂载），不得被本轮围栏误采。
        prefix = ['10-01 07:59:00.000 proxy mounted key=app0/s0/c18/e2/m1 field=pharos-document-note',
                  '10-01 07:59:00.000 ime selection confirmed [5,7) rc=0 (shared lifecycle) '
                  'mount=app0/s0/c18/e2/m1 field=pharos-document-note',
                  '10-01 07:59:00.032 ime proxy selection terminal=INSTALLED '
                  'reason=attach_confirmed target=[5,7) mount=app0/s0/c18/e2/m1 field=pharos-document-note']
    log = Log(prefix, scripted)
    log.reveal(IDX_PREP_FRAME)
    mode = {'m': 'source'}
    # round9-D：accepted 读回（产品挂在 mode 同一条状态线上）。默认形状＝「已提交
    # 当前面且有一张 ACCEPTED 票据」——与既有负控的日志形状一致，因此它们的行为
    # 不因读回而改变。case 可覆写 readback['state'] 制造其它票据结局。
    # round10-D3：与当前生产格式逐字一致——head 含 token=，票环项以 /x<cancelled>
    # 收尾，面清单用 F<nodeId>:<semanticId>（驱动独立分类的唯一输入）。
    # 'face'：本次提交帧的**中性事实**（提交的是哪一面），随提交走；'state' 是
    # 状态线模板（face= 是产品声明，由 request 填）。
    # next_ticket/last 随提交推进：真实生产里每次 accepted 提交都发一张新票，
    # 票号严格递增。round10-D3 的判据要求「票号 > 动作前基线」，桩不发新票就永远
    # 判不出「本次动作提交」——桩保真度缺口，不是判据缺口。
    readback = {'face': 'source', 'next_ticket': 4, 'last': 3,
                'state': ('ACCEPTED face={face} token=201 epoch=9 proj=6 nodes=16 '
                          'semantic=12345 frame=6 last=3 unacked=0 unackedDecision=0 '
                          'unackedStatus=0 unackedCtx=0 unackedNodes=0 tickets=1 '
                          'faces=1 F107:pharos-editor-body '
                          'T3/2/s0/v6/c9/n16/x0')}
    if readback_state != 'default':
        readback['state'] = readback_state
    if readback_overrides:
        readback.update(readback_overrides)
    clicks = []
    span_shift = {'n': 0}   # round12-R3：span 确认对插入后，后续帧下标偏移

    def uitest(*a):
        if a and a[0] == 'click':
            x, y = int(a[1]), int(a[2])
            clicks.append((x, y))
            if (x, y) == TOGGLE:
                if fail_toggle and mode['m'] == 'preview':
                    return None       # 预览→源码的切换不跟随（必须具名失败，不得补点）
                mode['m'] = 'preview' if mode['m'] == 'source' else 'source'
                readback['face'] = mode['m']
                # 本次提交发出新票：更新 last 与票环项（票号 = 递增后的 next）。
                readback['last'] = readback['next_ticket']
                readback['next_ticket'] += 1
                readback['state'] = (
                    'ACCEPTED face={face} token=201 epoch=10 proj=7 nodes=16 '
                    'semantic=22334455 frame=7 last=' + str(readback['last'])
                    + ' unacked=0 unackedDecision=0 unackedStatus=0 unackedCtx=0 '
                    'unackedNodes=0 tickets=2 faces=1 F107:pharos-editor-body '
                    'T3/2/s0/v6/c9/n16/x0 T'
                    + str(readback['last']) + '/2/s0/v7/c9/n16/x0')
                if mode['m'] == 'preview':
                    if log.n > IDX_PREVIEW_FRAME:
                        # 再访预览：设备会**追加**新的一帧（日志只增不减），
                        # scene_face 依"最近绘制节点"识别；不追加会读到上一面。
                        # round9-D：每次 accepted 提交都必带一行**中性** `accepted
                        # commit`。再访帧少了它，面判据就只能停在上一面——那正是
                        # round7 把「已切」判成 source 的形态。
                        log.append([
                            '10-02 09:00:05.000 node-rect id=313 x=10 y=10 w=100 h=40 clip=(0,0,400,400)',
                            '10-02 09:00:05.001 accepted node=313 semantic=pharos-document-note '
        'kind=10 label=pharos-document-note value=abcdef v=8',
                            '10-02 09:00:05.0015 accepted commit v=8 ticket=4 nodes=19 semantic=444444',
                        ])
                    else:
                        log.reveal(IDX_PREVIEW_FRAME + span_shift['n'])
                else:
                    if evict_on_return:
                        # 环形缓冲丢弃到拖选帧为止：切回帧仍在，但**围栏行被淘汰**。
                        # 淘汰到**拖选帧之前**（保留备注确认对本身）：本负控要的是
                        # 内容围栏行被淘汰，不是模式提交标记被淘汰。
                        # 精确模拟「围栏行被环形缓冲回收」：把当前可见的脚本行
                        # 全部淘汰（log.n 正是此刻可见上限），只留切回帧。
                        log.evict_prefix(log.n)
                    if fail_scene_follow:
                        # 模式已翻但 accepted 场景**不跟**（本次生产反例的固化：
                        # 刷新死区）。不得补点/加等待绕过，必须具名失败。
                        return None
                    log.reveal(len(log.scripted))
            elif (x, y) == BODY:
                log.reveal(IDX_PREP_ANCHOR)
        elif a and a[0] == 'drag':
            if anchor_mode == 'span' and len(a) > 2 and (int(a[1]), int(a[2])) == BODY:
                # round12-R3：正文中段非空跨度确认对（进入 B 之前、同挂载 m1）。
                # 在当前可见末尾**插入**（后续脚本帧仍在其后，不被截断）。
                extra = [
                    '10-02 09:00:01.800 ime selection confirmed [%d,%d) rc=0 '
                    '(shared lifecycle) mount=app1/s1/c3/e1/m1 field=pharos-editor-body'
                    % body_span_sel,
                    '10-02 09:00:01.810 ime proxy selection terminal=INSTALLED '
                    'reason=attach_confirmed target=[%d,%d) '
                    'mount=app1/s1/c3/e1/m1 field=pharos-editor-body' % body_span_sel,
                ]
                log.scripted = log.scripted[:log.n] + extra + log.scripted[log.n:]
                log.n += len(extra)
                span_shift['n'] += len(extra)
            else:
                log.reveal(IDX_NOTE_DRAG + span_shift['n'])
        return None

    fport_state = {'created': False}

    def fwd_hdc(*a):
        # fport 桩：ls 先空后含**同一行**完整三元组，创建回执明确（生产判据同形）。
        if a[:2] == ('fport', 'ls'):
            row = '127.0.0.1:5555 tcp:28997 tcp:7856 [Forward]\n' if fport_state['created'] else ''
            return SimpleNamespace(returncode=0, stdout=row, stderr='')
        if a[0] == 'fport' and a[1] == 'tcp:28997':
            fport_state['created'] = True
            return SimpleNamespace(returncode=0, stdout='Forwardport result:OK\n', stderr='')
        if a[:3] == ('fport', 'rm', 'tcp:28997'):
            fport_state['created'] = False
            return SimpleNamespace(returncode=0, stdout='Remove forward port success\n', stderr='')
        return SimpleNamespace(returncode=0, stdout='OK', stderr='')

    # 提交面（真实产品里 face 来自 controller.previewFacts()，即产品对自身模式的
    # 声明）。round9 负控需要一个「模式已声明、但 accepted 场景仍停在旧面」的形状：
    # fail_scene_follow 之后 mode 是 source，但最后提交的帧仍是 preview，因此产品
    # 声明与驱动独立分类会不一致——这正是要固化的三层判定。
    submitted = {'face': 'source'}

    # round13-R1：当前身份段按**真实 wire 格式**随每份回包发出（与脚本切回帧
    # 同一身份：ctx9/node107/res54/kind10/binding6/v6）。case 用 readback['edit']
    # 覆写为 'none' / 'malformed' / 'absent' 制造对应负控。
    edit_reads = {'n': 0}
    WIRE9 = (' edit=live ctx=9 gen=1 node=107 res=54 kind=10 '
             'b=6 v=6 field=pharos-editor-body')
    WIRE10 = (' edit=live ctx=10 gen=1 node=107 res=54 kind=10 '
              'b=6 v=6 field=pharos-editor-body')

    def _with_edit(state):
        # round13-R2：编辑身份序列控制。str 类别恒定；{'flap_at': k, 'wire': w}
        # 表示第 k 次公开读（0 起）改吐 w——用于「身份变化一次/持续变化」的实际
        # main 反例；读计数经 meta['reads'] 落盘供测试定位回读窗口。
        kind = readback.get('edit', 'live')
        n = edit_reads['n']
        edit_reads['n'] += 1
        if meta is not None:
            meta['reads'] = n + 1
        if kind == 'absent':
            return state
        if kind == 'none':
            return state + ' edit=none'
        if kind == 'malformed':
            return state + ' edit=live ctx=9 node=107'
        if isinstance(kind, dict) and 'flap_at' in kind:
            # round13-R2：**恢复观察窗口内**（驱动相位标记）的确认读改吐 ctx10；
            # persistent 在窗口内按读序交替（下一次判定即异 ctx 具名终局）。
            # 窗口外恒 base——身份变化只发生在观察期，不污染其它腿。
            phase = getattr(m, '_restore_observe_phase', False)
            if phase:
                edit_reads['inphase'] = edit_reads.get('inphase', 0) + 1
                # 窗口内第 1 读 = 判定读（base，证据得以配对）；第 2 读 = 确认读
                # 改吐 ctx10（身份变化一次）。persistent 在其后按读序交替。
                if edit_reads['inphase'] == 2:
                    return state + WIRE10
                if kind.get('persistent') and edit_reads['inphase'] > 2:
                    return state + (WIRE10 if edit_reads['inphase'] % 2 else WIRE9)
            return state + WIRE9
        return state + WIRE9

    def request(lines, port):
        # 产品声明 = 当前模式（权威读回）。
        face = 'preview' if mode['m'] == 'preview' else 'source'
        # 面清单语义跟随**本次动作之后的最后一次提交**（真实生产里 accepted 帧的面
        # 节点语义随提交走）。桩按当前提交帧给出对应语义，驱动才能独立判面。
        submitted_semantic = ('pharos-document-note' if readback['face'] == 'preview'
                              else 'pharos-editor-body')
        # 中性事实里的 face 字段是**产品声明**；驱动的独立分类另有其人。
        if readback['state'] == 'DECLARED_ONLY':
            state = (f'MODE={face} ACCEPTED face={face} token=201 epoch=9 proj=6 '
                     'nodes=16 semantic=12345 frame=6 last=3 unacked=0 '
                     'unackedDecision=0 unackedStatus=0 unackedCtx=0 unackedNodes=0 '
                     'tickets=1 faces=1 F107:pharos-editor-body '
                     'T3/2/s0/v6/c9/n16/x0')
            return 'OWNER_STATE_UTF8_HEX %d %s\n' % (
                len(_with_edit(state)), _with_edit(state).encode().hex())
        # round9-D：产品把 mode 与 accepted 读回挂在**同一条**状态线上（真实生产
        # 形状）。controlled 读回由 case 通过 readback['...'] 覆写，默认给「已提交
        # 当前面」——这让既有 19 个负控在没有读回形状变化时行为不变。
        rb = readback['state']
        if not isinstance(rb, str):
            raise TypeError('stub request: readback[state] is %r' % type(rb))
        if rb is None:
            state = f'MODE={face}'
        else:
            state = f'MODE={face} ' + rb.format(face=face).replace(
                'F107:pharos-editor-body', f'F107:{submitted_semantic}')
        state = _with_edit(state)
        return 'OWNER_STATE_UTF8_HEX %d %s\n' % (len(state), state.encode().hex())

    def accepted_point(semantic, *a, **k):
        return {'pharos-preview': TOGGLE, BODY_FIELD: BODY, NOTE_FIELD: NOTE}.get(semantic)

    def readback_point(semantic, port, *a, **k):
        # round11-D4：reach_mode 的按钮定位走读回几何；替身保持与旧 accepted_
        # semantic_point 同一坐标表，验证的是判定链而不是几何本身（几何由
        # test_target_geometry_readback.py 的原生探针与解析器用例覆盖）。
        pt = accepted_point(semantic)
        return (pt, None) if pt else (None, 'not_in_accepted')

    # round13-R1：wire→解析走**真实**共享规范（不允许桩自带解析）。
    _dev_spec = importlib.util.spec_from_file_location(
        'pharos_device_parse', HERE / 'h_source_preview_consumption.py')
    _dev = importlib.util.module_from_spec(_dev_spec)
    _dev_spec.loader.exec_module(_dev)
    m = SimpleNamespace(
        parse_edit_section=_dev.parse_edit_section,
        instance_identity=lambda: {'pid': 11, 'bundle': 'controlled'},
        hilog_rows=log.rows, hdc=fwd_hdc, TARGET='127.0.0.1:5555',
        reset_fixture=lambda port: (True, {}), read_all=lambda port: next(main_replies),
        request=request, accepted_semantic_point=accepted_point,
        readback_target_point=readback_point,
        readback_target_rect=lambda semantic, port: ((0, 0, 200, 100), None),
        accepted_semantic_rect=lambda *a, **k: (0, 0, 200, 100), uitest=uitest,
        last_note_caret=lambda port: 1, note_rendered_units=lambda node: 6,
        note_projected_text=lambda port: 'abcdef')
    env = dict(argparse=argparse, Path=Path, json=json, re=re, m=m, OUT=None,
               time=SimpleNamespace(sleep=lambda seconds: None),
               strict_utf16=_load_strict_utf16(),
               NOTE_FIELD=NOTE_FIELD, BODY_FIELD=BODY_FIELD,
               PRESENT_DECISION=_load_present_decision(),
               # reason(x) 三值同样**从生产源码抽**（round10-D1 的映射表是判据
               # 的一部分，桩里另抄一份会让它与生产静默漂移）。
               REASON_PROTOCOL=_load_reason_table()['REASON_PROTOCOL'],
               REASON_PRESENT_FAILED=_load_reason_table()['REASON_PRESENT_FAILED'],
               REASON_CANCELLED=_load_reason_table()['REASON_CANCELLED'],
               # 驱动的独立分类词表是模块级常量（与 BODY_FIELD 同理），main 的 exec
               # 命名空间必须提供。**从生产源码抽**，不在负控里另抄一份前缀表——
               # 两份词表不一致会让「两层独立验证」变成同义反复。
               _BODY_PREFIXES=_load_face_prefixes('BODY'),
               _PREVIEW_PREFIXES=_load_face_prefixes('PREVIEW'),
               find_note_resource=lambda port: 1001,
               read_public=lambda port, rid: next(note_replies),
               actual_main_owner=lambda: 'pharos-main', ARCHIVE=[],
               MAP_ROW=__import__('re').compile(r"(?:^|\s)(\S+)\s+tcp:(\d+)\s+(\S+)\s+\[Forward\]"))
    # accepted_faces 在生产里是 accepted_commit_marker 的别名（模块级赋值，AST 提取
    # 拿不到）。这里按生产的同一形状补上别名，而不是在负控里另写一份解析。
    env.setdefault('accepted_faces', env.get('accepted_commit_marker'))
    # round13-R2：main 引用的模块级读序号（观察状态机确认读定位）。
    env.setdefault('_SNAP_READ_SEQ', {'n': 0})
    exec(_MAIN_CODE, env)
    out = HERE / 'negative-controls-artifacts' / name
    out.mkdir(parents=True, exist_ok=True)
    old_argv = sys.argv
    try:
        sys.argv = [str(SOURCE), '--out', str(out), '--target', '127.0.0.1:5555',
                    '--anchor-mode', anchor_mode]
        rc = env['main']()
    finally:
        sys.argv = old_argv
    results = json.loads((out / 'dual-owner.json').read_text())
    if meta is not None:
        meta['clicks'] = clicks
        meta['status'] = results.get('status')
    return rc, results.get('status'), results


# round6-A：显式票用新格式 ADOPTED（request/ctx/node/adopted/owner_version/v 逐项
# 身份），ctx 与当前 focus（ctx=9）一致。
ADOPT_ACK = ('10-02 09:00:04.040 proxy restore ack accepted request=5 ctx=9 node=107 '
             'installed=1:1 v=6')
ADOPT_LINE = ('10-02 09:00:04.050 PHAROS_OHOS_RESTORE_ADOPTED count=1 request=5 ctx=9 '
              'node=107 adopted=1:1 owner_version=1 v=6')


class DualOwnerNegativeControlsTest(unittest.TestCase):
    def assert_red(self, rc, status, name):
        self.assertNotEqual(rc, 0, f'{name} must fail the overall gate (rc={rc})')
        self.assertNotEqual(status, 'OK', f'{name} must not report OK')

    def test_positive_control_passes(self):
        rc, status, _ = run_case('positive-control')
        self.assertEqual(rc, 0, f'positive control must pass (status={status})')
        self.assertEqual(status, 'OK')

    def test_positive_control_explicit_ticket_passes(self):
        # 显式恢复票路径（ACK node==正文 node 且窗口采纳）也合法。
        rc, status, _ = run_case('positive-explicit-ticket',
                                 return_ack=[ADOPT_ACK, ADOPT_LINE])
        self.assertEqual(rc, 0, f'explicit-ticket path must pass (status={status})')
        self.assertEqual(status, 'OK')

    def test_wrong_note_range_fails(self):
        rc, status, r = run_case('wrong-note-range', actual_b='abcNf')
        self.assert_red(rc, status, 'wrong-note-range')
        self.assertFalse(r['required_values']['b_replace_exact_owner'])

    def test_destructive_a_resume_fails(self):
        rc, status, r = run_case('destructive-A-resume', actual_a='a回c')
        self.assert_red(rc, status, 'destructive-A-resume')
        self.assertFalse(r['required_values']['a_resume_exact_owner'])

    def test_zero_input_fails(self):
        b = b'abcdef'.hex()
        rc, status, _ = run_case('zero-input',
                                 note_versions=[(1, b), (2, b), (2, b), (2, b), (2, b), (2, b)])
        self.assert_red(rc, status, 'zero-input')

    def test_duplicate_write_fails(self):
        b2 = (b'aNNdef').hex()
        rc, status, _ = run_case('duplicate-write',
                                 note_versions=[(1, b'abcdef'.hex()), (2, b'abcdef'.hex()),
                                                (2, b'abcdef'.hex()), (4, b2), (4, b2), (4, b2)])
        self.assert_red(rc, status, 'duplicate-write')

    def test_missing_install_confirmation_fails(self):
        # 预览帧完整（含备注 accepted/mount，供 scene_face 认面），但**不含**备注的
        # 安装确认对（行 10–11）——b_install 必须具名失败。
        rc, status, r = run_case('missing-install-confirm',
                                   scripted=_frame_rows()[:IDX_PREVIEW_FRAME])
        self.assert_red(rc, status, 'missing-install-confirm')
        self.assertEqual(r.get('status'), 'b_install_unconfirmed')

    def test_stale_log_confirmation_not_accepted(self):
        # 备注确认只存在于拖选之前的帧（不含拖选确认对的脚本）：本轮围栏之后无
        # 新确认 → 必须失败（不回退历史）。
        rc, status, r = run_case('stale-log-confirmation',
                                 scripted=_frame_rows()[:IDX_PREVIEW_FRAME])
        self.assert_red(rc, status, 'stale-log-confirmation')
        self.assertEqual(r.get('status'), 'b_install_unconfirmed')

    def test_note_cleared_fails(self):
        rc, status, _ = run_case('note-cleared',
                                 note_versions=[(1, b'abcdef'.hex()), (2, b'abcdef'.hex()),
                                                (2, b'abcdef'.hex()), (3, ''), (3, ''), (3, '')])
        self.assert_red(rc, status, 'note-cleared')

    def test_restore_cross_node_ack_rejected(self):
        # 用**备注 node313** 的 ACK 冒充正文恢复：node 与 accepted 正文 node(107) 不符，
        # 必须被拒（复核 R4：正文查询曾接受 node313 的备注 ACK 并拼上正文 mount）。
        bad = ('10-02 09:00:04.040 proxy restore ack accepted request=5 ctx=99 node=313 '
               'installed=1:1 v=1')
        scripted = _frame_rows(return_sel=(1, 1), bind_owner=False,
                               return_ack=[bad, ADOPT_LINE])
        rc, status, r = run_case('restore-cross-node-ack', scripted=scripted)
        self.assert_red(rc, status, 'restore-cross-node-ack')
        self.assertEqual(r.get('status'), 'a_restore_uninstalled')

    def test_restore_ack_unadopted_fails(self):
        # 平台已安装（ACK node==107）但窗口未采纳（无 RESTORE_ADOPTED）：不算成立。
        rc, status, r = run_case('restore-ack-unadopted',
                                 return_ack=[ADOPT_ACK], bind_owner=False)
        self.assert_red(rc, status, 'restore-ack-unadopted')
        self.assertEqual(r.get('status'), 'a_restore_not_adopted')

    def test_restore_wrong_landing_fails(self):
        # 切回后框架把落点恢复到**另一个位置**（[2,2) 而非冻结原锚 [1,1)）。
        rc, status, r = run_case('restore-wrong-landing', return_sel=(2, 2))
        self.assert_red(rc, status, 'restore-wrong-landing')
        self.assertFalse(r['required_values']['a_resume_at_frozen_anchor'])

    def test_restore_not_installed_fails(self):
        # 切回帧已到（scene_face=source）但本轮围栏之后无任何恢复证据 → 交接未成立。
        rc, status, r = run_case('restore-not-installed',
                                 scripted=_frame_rows(return_evidence=False))
        self.assert_red(rc, status, 'restore-not-installed')
        self.assertEqual(r.get('status'), 'a_restore_uninstalled')

    def test_fence_evicted_named_evidence_lost(self):
        # 内容围栏被环形日志淘汰 → 驱动独立分类不可得，绝不退回 0 重扫历史。
        #
        # round9-D：读回把这个形状**精确**化了——产品声明已是目标面且提交确实
        # 发生（ACCEPTED 票据），只是围栏被淘汰所以驱动的独立读数拿不到。因此具名
        # committed_but_face_unobserved：提交成功、面未观测。这比旧的 evidence_lost
        # 多回答了一个问题（旧名只说「证据丢了」，读回能说「提交本身是成功的」）。
        rc, status, r = run_case('fence-evicted', evict_on_return=True)
        self.assert_red(rc, status, 'fence-evicted')
        # round10-D3：面判据改由**单份快照**给出（票据 + 面节点清单），不再依赖
        # 日志围栏。围栏被回收时提交事实仍可从快照读到，但驱动分类若读不到目标面，
        # 具名是 driver_face_unobserved（面未观测），而不是 committed_but_face_
        # unobserved（那个名字依赖旧的两路判据形状）。
        self.assertEqual(r.get('status'), 'evidence_lost')

    def test_anchor_out_of_range_named(self):
        # 旧版本越界锚（[99,99) 远超正文 3 单元）：不得 clamp 到文末，具名失败。
        rc, status, r = run_case('anchor-out-of-range', human_anchor_sel=(99, 99))
        self.assert_red(rc, status, 'anchor-out-of-range')
        self.assertEqual(r.get('status'), 'a_anchor_unconfirmed')

    def test_anchor_at_doc_end_named(self):
        # 文末默认位置冒充中段原锚（[3,3) 等于正文长度）：必须被拒。
        rc, status, r = run_case('anchor-at-doc-end', human_anchor_sel=(3, 3))
        self.assert_red(rc, status, 'anchor-at-doc-end')
        self.assertEqual(r.get('status'), 'a_anchor_unconfirmed')

    def test_scene_not_following_after_mode_flip_named(self):
        # 本次生产反例固化：模式翻到 source 但 accepted 场景停在 preview（刷新死区）。
        # 必须具名失败，绝不用补点/加等待/解冻动作绕过。
        #
        # round10-D3：单份快照判据下，模式确实切到了 source（新票 ACCEPTED、驱动
        # 独立分类也是 source），因此**切回阶段通过**；失败发生在其后的 A 恢复采纳
        # 判定——切回帧没有平台安装确认，故 accepted 场景未跟上。具名是恢复环节
        # 自己的名字，不再是模式环节的（round9 的 face_declaration_mismatch 描述的
        # 是「模式切了但提交停在旧面」，与本负控形状不同）。
        rc, status, r = run_case('scene-not-following', fail_scene_follow=True)
        self.assert_red(rc, status, 'scene-not-following')
        self.assertEqual(r.get('status'), 'a_restore_uninstalled')

    def test_rebind_not_reflected_fails(self):
        # 切回帧有 platform focus + observation（平台读了落点），但窗口**没有**重新
        # 绑定正文 owner（无 BIND_OWNER）→ 未"采用"，不成立。
        rc, status, r = run_case('rebind-not-reflected',
                                 scripted=_frame_rows(return_sel=(1, 1), bind_owner=False))
        self.assert_red(rc, status, 'rebind-not-reflected')
        # round10-D3：切回阶段已**通过**（回切动作确实带来了新提交），失败发生在其后的
        # A 恢复采纳判定上——缺 BIND_OWNER ⇒ 未采用。具名回到该环节自己的名字。
        self.assertEqual(r.get('status'), 'a_restore_uninstalled')

    def test_body_span_replace_exactly_once(self):
        # round12-R3：正文中段非空选区跨切换 → 免点击首笔精确替换该跨度
        # （removed>0、恰一笔）。期望从冻结完整 owner 独立计算，不从结果反推。
        doc = 'a回bcdef'
        expected = 'a回回ef'          # utf16[2:5)='bcd' 被 '回' 替换
        rc, status, r = run_case('body-span-replace', anchor_mode='span',
                                 main_hex=doc.encode().hex(),
                                 actual_a=expected, return_sel=(2, 5),
                                 human_anchor_sel=(3, 3))
        self.assertEqual(rc, 0, f'body-span-replace must pass (rc={rc}, status={status})')
        self.assertEqual(status, 'OK')
        flat = r.get('required_values') or {}
        self.assertTrue(flat.get('a_freeze_span_nonempty_mid'), flat)
        self.assertTrue(flat.get('a_resume_removed_matches_span'), flat)
        self.assertEqual(r['a_resume']['frozen_selection_utf16'], [2, 5])
        self.assertEqual(r['a_resume']['removed_bytes'], 3)
        self.assertTrue(r['a_resume']['exactly_once'], r['a_resume'])

    def test_body_span_degenerate_drag_named(self):
        # 拖选退化为折叠（[4,4)）→ 必须具名失败，不得把折叠光标写成非空选区。
        doc = 'a回bcdef'
        rc, status, r = run_case('body-span-degenerate', anchor_mode='span',
                                 main_hex=doc.encode().hex(),
                                 return_sel=(4, 4), body_span_sel=(4, 4),
                                 human_anchor_sel=(3, 3))
        self.assert_red(rc, status, 'body-span-degenerate')
        self.assertEqual(r.get('status'), 'a_body_span_unconfirmed')

    # ---- round13-R1/R2：真实 wire→解析→权威门 + 观察状态机（实际 main） ----

    def test_edit_none_with_full_old_logs_rejected(self):
        # edit=none（生产明确"当前无编辑"）+ 完整旧日志 → 不得借日志通过。
        rc, status, r = run_case('edit-none-rejected', readback_state='default',
                                 readback_overrides={'edit': 'none'})
        self.assert_red(rc, status, 'edit-none-rejected')
        self.assertEqual(r.get('status'), 'a_restore_adoption_identity_mismatch')
        self.assertEqual((r.get('a_restore') or {}).get('reason'), 'readback_edit_not_live')

    def test_edit_malformed_rejected(self):
        # edit= 段畸形（live 形状缺字段）→ 具名拒绝，不救绿。
        rc, status, r = run_case('edit-malformed-rejected', readback_state='default',
                                 readback_overrides={'edit': 'malformed'})
        self.assert_red(rc, status, 'edit-malformed-rejected')
        self.assertEqual((r.get('a_restore') or {}).get('reason'), 'readback_edit_malformed')

    def test_edit_absent_rejected(self):
        # 状态线无 edit= 段（读取失败/旧产物）→ 同样不借历史日志通过。
        rc, status, r = run_case('edit-absent-rejected', readback_state='default',
                                 readback_overrides={'edit': 'absent'})
        self.assert_red(rc, status, 'edit-absent-rejected')
        self.assertEqual((r.get('a_restore') or {}).get('reason'), 'readback_edit_absent')

    def test_identity_change_once_then_stable_observes_and_succeeds(self):
        # 身份变化一次（确认读 ctx9→ctx10）后稳定：等待态继续有界观察并成功；
        # 零额外用户动作（toggle 次数与基线一致）。
        base_meta = {}
        run_case('flap-base', readback_state='default', meta=base_meta)
        base_r = run_case('flap-once-base', readback_state='default')[2]
        confirm_seq = base_r['restore_read_seq'][1]
        meta = {}
        rc, status, r = run_case(
            'flap-once-stable', readback_state='default', meta=meta,
            readback_overrides={'edit': {'flap_at': confirm_seq}})
        self.assertEqual(rc, 0, f'flap-once must converge (status={status})')
        self.assertEqual(status, 'OK')
        self.assertEqual(len(r.get('identity_flaps') or []), 1, r.get('identity_flaps'))
        self.assertEqual(meta['clicks'].count(TOGGLE), base_meta['clicks'].count(TOGGLE),
                         '身份变化不得引发额外用户动作')

    def test_identity_persistent_change_bounded_named(self):
        # 持续变化：有界观察内收敛到具名终局（不等待耗尽、零额外动作）。
        base_meta = {}
        run_case('flap-persist-base', readback_state='default', meta=base_meta)
        base_r2 = run_case('flap-persist-base', readback_state='default')[2]
        confirm_seq2 = base_r2['restore_read_seq'][1]
        meta = {}
        rc, status, r = run_case(
            'flap-persistent', readback_state='default', meta=meta,
            readback_overrides={'edit': {'flap_at': confirm_seq2,
                                         'persistent': True}})
        self.assert_red(rc, status, 'flap-persistent')
        self.assertEqual(len(r.get('identity_flaps') or []) >= 1, True)
        # 持续变化有界收敛：提前具名结束（不再走到回访 toggle），且**零额外**
        # 用户动作（toggle 次数不多于基线）。
        self.assertLessEqual(meta['clicks'].count(TOGGLE),
                             base_meta['clicks'].count(TOGGLE),
                             '持续变化不得引发额外用户动作')

    def test_helper_kick_required_is_named_failure(self):
        # 模式切换不跟随：必须具名失败，且**只点一次**模式按钮——不追加正文 kick、
        # 不重复 toggle（复核 R4 的"切换→正文补点→再切换"必须消失）。
        meta = {}
        rc, status, r = run_case('helper-kick-required', fail_toggle=True, meta=meta)
        self.assert_red(rc, status, 'helper-kick-required')
        # round11-D3：超时结局取**最后一次判定的具名结论**（不再按快照重推兜底
        # 名）。toggle 不生效 ⇒ 模式从未到目标 ⇒ mode_not_at_target；旧名
        # no_ticket_after_baseline 是超时兜底重推的笼统名。业务判据不变：具名
        # 失败＋只点一次模式按钮。
        self.assertEqual(r.get('status'), 'mode_not_at_target')
        clicks = meta['clicks']
        # 切回阶段（进入 B 之后）只允许一次 TOGGLE 点击，且不得出现正文/固定 kick 点。
        after_b = clicks[clicks.index(NOTE):] if NOTE in clicks else clicks
        toggles_after_b = [c for c in after_b if c == TOGGLE]
        self.assertEqual(len(toggles_after_b), 1,
                         f'切回阶段必须只点一次模式按钮，实际 {toggles_after_b}')
        self.assertNotIn((660, 900), after_b, '不得出现固定 kick 点 (660,900)')
        self.assertNotIn(BODY, after_b, '切回阶段不得追加正文点击')


if __name__ == '__main__':
    unittest.main()

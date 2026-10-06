#!/usr/bin/env python3
"""S3/S4（h-source-preview-followup）：双 owner A→B→A→再访 B 严格驱动。

判据原则（2026-10-02 round4 后指导：先冻结事实，再独立计算期望）：
  * 每步动作前冻结运行身份（PID）、双方 owner 的版本/完整字节；动作后逐字节
    核对与"恰好一次"（版本 +1）；任何一步找不到本轮事实即具名失败。
  * **期望不能从操作后的 diff 反推**：B 拖选后、A 切回后，都必须先从本轮日志
    取得「平台确认安装的 UTF-16 选区」（terminal=INSTALLED + native rc=0），
    经 strict_utf16 oracle 映射成源字节跨度，独立拼出唯一期望正文；输入后的
    实际字节必须与它逐字节相等。错区间替换、误删续写、缺安装确认都使总门
    失败（负控见 test_dual_owner_negative_controls.py）。
  * **准备阶段允许一次真实点击正文中段建立原锚**（用自有固定夹具，中段有可
    区别内容）：先确认当前 owner 版本/完整字节与 accepted 正文 node，再取平台
    实际选区冻结**源字节 caret**。准备点击不产生 owner 事务，且不计作切回后的补点。
    越界／版本不合／身份缺失**具名失败**——不从旧日志找位置、不 clamp 旧锚、
    不用文末默认位置替代中段恢复。
  * 免点击链禁止补点正文：B 替换与 A 续写都用 `uiInput text`（不产生点击）；
    切换按钮的点击是模式动作本身，允许**一次**。**切回 A 后不得追加正文
    click/tap/focus、不重发用户输入、不用新落点重新定义期望**；模式定位本体也
    不做 kick、不重复 toggle（`reach_mode` 只点一次，超时具名失败并记 trace）。
    切回后由框架的恢复路径自行安装，检查器只等待并核对它落回该原锚
    （required: `a_resume_at_frozen_anchor`；围栏取在切换动作之前）。
  * **恢复证据按完整目标配对**：显式恢复票的 ACK node 必须等于本轮 accepted 正文
    node；挂载快照必须 `platform focus`/观测落在同一正文 node 且窗口采纳事实
    （`PHAROS_OHOS_BIND_OWNER`）。备注（node313）的 ACK 不得拼到正文的挂载上；
    排队/安装 ≠ 采用。围栏淘汰由 `fence_index` 具名抛 `EvidenceLost`（不退回 0 重扫）。
  * 备注读回走**公开通道资源**（GET_CONTEXT 列出的 note 资源 + READ_RANGE），
    不再用 native delta 冒充提交、不用"曾有 delta"当不变证据。
  * 等待按进度（OWNER_STATE / 确认行出现）+ 有界轮次；无当前 owner 状态时具名
    失败，不回退点击翻转或历史几何。
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
# 每一次公开通道请求的完整原回包（round5 后指导 A：不截断、不只留摘要）。
ARCHIVE = []


def request(lines, port):
    """走 `h_source_preview_consumption.request` 并归档**完整**请求与回包。

    复核 round5：判据只留 120 字符摘要时，指导无法离线重判一次配对到底取了哪行
    日志。归档原样文本，落盘在 `raw-responses.json`，与 dual-owner.json 同行号引用。"""
    resp = m.request(lines, port)
    ARCHIVE.append({'request': list(lines), 'response': resp})
    return resp

NOTE_FIELD = 'pharos-document-note'
BODY_FIELD = 'pharos-editor-body'


def log(msg):
    print(msg, flush=True)


def resource_meta(port, rid):
    """GET_CONTEXT 里该资源的元数据：INTEGER 字段十进制值 + documentId 解码。"""
    resp = request(["GET_CONTEXT 0"], port)
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
    resp = request(["PROTOCOL CJGUI_SHARED_OPERATION/2",
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
    resp = request(["GET_CONTEXT 0"], port)
    for rid in (int(x) for x in re.findall(r"^RESOURCE (\d+) ", resp, re.M)):
        if resource_meta(port, rid).get("documentId", "").startswith("pharos-note"):
            return rid
    return None


def current_mode(port):
    """当前编辑器模式——公开通道权威读数（GET_CONTEXT 的 OWNER_STATE_UTF8_HEX，
    产品在 S3 暴露）。a11y 的按钮 label 行只在交互时重发，会滞后一个交互周期，
    不能作为模式依据。"""
    state = public_state(port)
    ms = re.search(r"MODE=(preview|source)", state)
    return ms.group(1) if ms else None


# CjguiInternalRendererPresentDecision（native/cjgui_internal_renderer.h:304）。
# 逐字对应，**不接受凭印象推断**——round9 首次实现把 1/2 误当 ACCEPTED/REJECTED，
# 每次成功提交都被读成「被拒」，根因判据整个反向。
PRESENT_DECISION = {'NONE': 0, 'PENDING': 1, 'ACCEPTED': 2, 'REJECTED': 3}


def public_state(port):
    """公开上下文载荷（GET_CONTEXT 的 OWNER_STATE_UTF8_HEX 解码后原文）。

    round9-D：产品把 mode 与 accepted 读回挂在**同一条**状态线上，因此模式与提交
    事实来自同一次读回，不会出现「模式已切换、提交事实取自另一时刻」的错配。
    """
    resp = request(["GET_CONTEXT 0"], port)
    if not isinstance(resp, str):
        raise TypeError("public_state: request returned %r" % type(resp))
    mo = re.search(r"OWNER_STATE_UTF8_HEX (\d+) ([0-9a-fA-F]*)", resp)
    if not mo:
        return ""
    return bytes.fromhex(mo.group(2)).decode("utf-8", "replace")


_SNAP_READ_SEQ = {"n": 0}


def public_snapshot(port):
    """**一次**取回 + **一次**解析的同身份快照（round10-D3）。

    `seq` 是本进程内 GET_CONTEXT 的单调读序号（round13-R2：观察状态机的
    身份变化注入按它定位确认读）。

    这是判定的唯一事实来源：一次判定内**只**调它一次，之后 mode / accepted 身份 /
    票据 / 节点全部从这**同一个** dict 读出。

    为什么必须（round10 假绿反例）：旧 `settled()` 在一次判定内分三次
    `GET_CONTEXT`（current_mode / ticket_outcome / driver_face），再由
    `settledTwice` 整体重做一遍。6 份响应**各自**都不满足
    「MODE=preview 且 accepted 为 preview」，拼起来却判成成功——把三份互不一致的
    快照当成一份。
    """
    state = public_state(port)
    snap = {
        'raw': state,
        'mode': None,
        'token': None,
        'epoch': None,
        'frame': None,
        'last': None,
        'unacked': None,
        'proj': None,
        'nodes': None,
        'tickets': [],
        'face_nodes': [],
        'face_list_truncated': None,
        'editing': None,
        'readable': False,
    }
    ms = re.search(r"MODE=(preview|source)", state)
    snap['mode'] = ms.group(1) if ms else None
    if 'ACCEPTED' not in state:
        return snap
    head = state.split(' T', 1)[0]
    fields = dict(re.findall(r"(\w+)=(\S+)", head))
    snap['readable'] = True
    for key in ('token', 'epoch', 'proj', 'nodes', 'frame', 'last', 'unacked'):
        if key in fields:
            snap[key] = int(fields[key])
    # 面清单：F<nodeId>:<semanticId>，faces=N 是**已列出**的条数
    snap['face_nodes'] = [{'node': int(n), 'semantic': sem}
                          for n, sem in re.findall(r'F(\d+):(\S+)', state)]
    # `faces=N` 是本次**列出的**条数，**不是**「目标不存在」的判据：目标完全可能
    # 排在第 9 项之后而没被列出（D4 缺陷）。真正的截断信号由生产显式给出
    # （`facesTruncated=1`，见 acceptedStateSummary），只有它为 1 时才允许把
    # 「清单里没有目标」解释成「可能在未列出的部分」。
    fm = re.search(r'faces=(\d+)', head)
    if fm:
        snap['face_list_count'] = int(fm.group(1))
    tm = re.search(r'facesTruncated=(\d+)', head)
    snap['face_list_truncated'] = bool(tm and tm.group(1) == '1')
    # 票据环：吃满 7 段并**锚定**（旧正则未锚定，遇到 /x 尾缀会静默丢 x）。
    for chunk in re.findall(
            r' T(\d+)/(\d+)/s(-?\d+)/v(\d+)/c(\d+)/n(\d+)(?:/x(\d+))?(?=\s|$)',
            state):
        tickets = snap['tickets']
        tickets.append({
            'ticket': int(chunk[0]), 'decision': int(chunk[1]),
            'terminal_status': int(chunk[2]),
            'accepted_projection': int(chunk[3]),
            'source_ctx': int(chunk[4]), 'published_nodes': int(chunk[5]),
            # x 缺失＝**未知**，不得默认 0（那会把「未标注」读成「协议内结算」）。
            # 可选组在未参与匹配时是空串（不是 None），两者都要归「未知」。
            'reason': (int(chunk[6]) if chunk[6] else None),
        })
    # round13-R1：当前编辑身份经**共享规范**解析（m.parse_edit_section）：
    # live（含 gen）/ none / malformed / absent 四类互不混淆——旧正则要求
    # `ctx=… node=…` 紧邻，native 加 gen 后 24 条 live 全部漏析（round13 反例）。
    snap['editing'] = m.parse_edit_section(state)
    _SNAP_READ_SEQ['n'] += 1
    snap['seq'] = _SNAP_READ_SEQ['n']
    return snap


def accepted_readback(port, snapshot=None):
    """产品公开状态线里的 accepted 读回（中性事实 + 产品分类）。

    round10-D3：**不再自己取响应**。传入 `snapshot` 时直接从中派生（判定路径必须
    这样做：一次判定只允许一份事实）；不传时自取一份（仅供日志/trace 单独展示）。
    """
    snap = snapshot if snapshot is not None else public_snapshot(port)
    if not snap.get('readable'):
        return None
    out = {
        'token': snap.get('token'),
        'epoch': snap.get('epoch'),
        'proj': snap.get('proj'),
        'nodes': snap.get('nodes'),
        'frame': snap.get('frame'),
        'last': snap.get('last'),
        'unacked': snap.get('unacked'),
        'unackedDecision': None,
        'unackedStatus': None,
        'unackedCtx': None,
        'unackedNodes': None,
        'tickets': snap.get('tickets'),
        'face_nodes': snap.get('face_nodes'),
        'face_list_truncated': snap.get('face_list_truncated'),
        'phase': 'ok',
        # 产品对自身模式的**声明**（解析自 MODE=），不是 accepted 事实。
        'face': snap.get('mode'),
    }
    return out


def action_baseline(port):
    """动作前基线：本次模式动作要跟它比。

    round10-D3（Pi 咨询 §4.2）：`create` 会把 epoch 归零、票号从 1 重新发，因此
    只比 `proj` 或「任意历史 ACCEPTED」都不够。基线必须含 **token**（槽绑定的
    会话身份）与 `last`（环内最大票号）。

    round11-D3（撤回 round10 错误前提）：旧注释称「产品模式切换一次就换一个
    token（6→8→10）」——round11 复核证实那是**格式串错位**（`src.token` 实参被
    删后字段整体偏移出的假象），不是会话重建。epoch 是**槽内发布修订**（create
    归零），不是跨 session 身份。同一动作的基线与结果必须**同 token**；若后续
    真实证据需要跨 session 接续，必须先定义显式交接凭据，不能以
    epoch/frame/ticket 计数更大放行。
    """
    snap = public_snapshot(port)
    tickets = snap.get('tickets') or []
    return {
        'token': snap.get('token'),
        'mode': snap.get('mode'),
        'epoch': snap.get('epoch'),
        'frame': snap.get('frame'),
        'last': snap.get('last'),
        'max_ticket': max((t['ticket'] for t in tickets), default=0),
        'readable': snap.get('readable'),
    }


# 票据 reason（x）→ 驱动分类。四值契约下 decision 只说「没成功」，真实原因在 x。
REASON_PROTOCOL = 0        # 协议内结算：延迟 commit / 延迟 rollback
REASON_PRESENT_FAILED = 1  # present 同步终态失败（phase=Done 且 status≠OK）
REASON_CANCELLED = 2       # phase==Cancelled（渲染线程准入拒绝 / 停机清理）


def ticket_verdict(entry, target, baseline, snap):
    """按**同一份快照**判定一张票对本次动作的意义。

    返回 (verdict, facts)。verdict：
      'this_action_submitted'    本次动作之后、ACCEPTED 且 reason=0
      'other_face_submitted'     ACCEPTED，但驱动分类不是目标面
      'rollback_rejected'        协议内结算的拒绝（reason=0）——平台 rollback
      'present_failed'           present 同步终态失败（reason=1）
      'cancelled'                phase==Cancelled（reason=2）
      'reason_unknown'           reason 缺失/越界——不猜，具名未证实
      'stale_token'              token ≠ 基线 ⇒ 不是同一会话的结果（round11-D3：
                                 即使 epoch/frame/ticket 更大也拒绝；跨 session
                                 接续须显式交接凭据，不按计数放行）
      'stale_epoch'              epoch 倒退 ⇒ 同 token 下读到更早修订
      'not_after_baseline'       票号 ≤ 基线 ⇒ 动作之前的历史票，不能冒充本次

    round11-D3：身份守卫主判据是 **token 相等**。round10 的「epoch 单调性代替
    token 相等」建立在已撤回的前提上（token 6→8→10 实为格式串错位，不是产品
    重建会话），该实现曾放行无关 token 999 冒充本次动作结果。epoch 倒退在
    同 token 下仍是独立异常，单独具名。
    """
    facts = {'ticket': entry.get('ticket'), 'decision': entry.get('decision'),
             'reason': entry.get('reason'), 'baseline_token': baseline.get('token'),
             'snapshot_token': snap.get('token')}
    if (baseline.get('token') is not None and snap.get('token') is not None
            and snap['token'] != baseline['token']):
        return 'stale_token', facts
    if (baseline.get('epoch') is not None and snap.get('epoch') is not None
            and snap['epoch'] < baseline['epoch']):
        return 'stale_epoch', facts
    floor = max(baseline.get('max_ticket') or 0, baseline.get('last') or 0)
    if entry['ticket'] <= floor:
        return 'not_after_baseline', facts
    if entry['decision'] == PRESENT_DECISION['ACCEPTED']:
        if entry.get('reason') not in (None, REASON_PROTOCOL):
            return ('present_failed' if entry['reason'] == REASON_PRESENT_FAILED
                    else 'cancelled'), facts
        if entry.get('reason') is None:
            return 'reason_unknown', facts
        face = driver_face_from_snapshot(snap)
        return ('this_action_submitted' if face == target else 'other_face_submitted'), facts
    if entry['decision'] == PRESENT_DECISION['REJECTED']:
        if entry.get('reason') is None:
            return 'reason_unknown', facts
        return ('rollback_rejected' if entry['reason'] == REASON_PROTOCOL
                else ('present_failed' if entry['reason'] == REASON_PRESENT_FAILED
                      else 'cancelled')), facts
    if entry['decision'] == PRESENT_DECISION['PENDING']:
        return 'in_flight', facts
    return 'reason_unknown', facts


def driver_face_from_snapshot(snap):
    """驱动的**独立**面分类：只用这一份快照里的面节点清单。

    round10-D3：清单优先于逐节点日志（指纹门会压掉日志行），但**多面并存时不得取
    第一个前缀就宣告成立**——必须所有可分类面都指向同一个面，否则具名歧义。
    """
    faces = {_classify_face(item['semantic']) for item in (snap.get('face_nodes') or [])}
    faces.discard(None)
    if len(faces) == 1:
        return next(iter(faces))
    if not faces:
        return None
    return 'ambiguous:' + ','.join(sorted(faces))


def mounted_key(rows, field):
    """该**字段**当前（可见范围内最后一次）挂载键 `appA/sS/cC/eE/mM`。

    键里内嵌上下文号（`cC`），是字段↔上下文的独立绑定来源。只取本字段的
    `proxy mounted ... field=<field>` 行——复核 R4：正文查询曾把备注（node313）
    的 ACK 拼上正文挂载，根因就是取挂载时不校验字段。挂载是字段级稳定事实，
    可在围栏之前；但配对行（confirmed/terminal）必须与本键一致且落在围栏之后。"""
    key = None
    for row in rows:
        mo = re.search(r"proxy mounted key=(\S+) field=" + re.escape(field) + r"\s*$", row)
        if mo:
            key = mo.group(1)
    return key


def accepted_node_id(semantic, rows=None):
    """accepted 场景里该语义节点的物理 node id（`accepted node=N semantic=<s>`）。

    这是与「恢复 ACK 的 node」独立的一行来源：用它把恢复目标钉到**正文面**，
    而不是靠 ACK 自己声称。"""
    rows = m.hilog_rows() if rows is None else rows
    nid = None
    for row in rows:
        if "accepted node=" in row and ("semantic=%s " % semantic) in row:
            mo = re.search(r"accepted node=(-?\d+)", row)
            if mo:
                nid = int(mo.group(1))
    return nid


def latest_body_anchor(rows, since, body_node):
    """本轮（since 之后）平台记录的**人手落点**：`human anchor recorded origin=...
    seq=N node=<body_node> sel=A:B`。这是平台实际选区（tap 结果），node 必须等于
    正文节点——与 accepted 正文 node 独立的一行来源。返回 (start,end) 或 None。"""
    last = None
    for row in rows[since:]:
        mo = re.search(r"human anchor recorded origin=\S+ seq=(\d+) node=(\d+) "
                       r"sel=(\d+):(\d+)", row)
        if mo and (body_node is None or int(mo.group(2)) == body_node):
            last = (int(mo.group(3)), int(mo.group(4)))
    return last


def confirmed_selection(rows, field, since):
    """本轮日志里该**字段**最后一次平台确认安装的 UTF-16 选区。

    确认 = 共享生命周期的两帧读数命中（terminal=INSTALLED，带 mount 身份与
    target）**且** native 结算被接受（ime selection confirmed ... rc=0）。**两行
    都必须带同一个 `mount=K field=<field>`**——复核 R4：此前只按 `(shared
    lifecycle)` 的裸行匹配，正文查询会采到备注（node313）的确认行。两行必须
    出现在 since 之后、值一致；缺任一行即 None。取**最后一次**配对：一次会话内
    有多次安装（挂载初值、逐键 caret、命中推送），驱动冻结的是动作前的最新落点。"""
    key = mounted_key(rows, field)
    if key is None:
        return None
    confirmed = None
    last_pair = None
    for row in rows[since:]:
        mo = re.search(r"ime selection confirmed \[(\d+),(\d+)\) rc=0 \(shared lifecycle\) "
                       r"mount=" + re.escape(key) + r" field=" + re.escape(field) + r"\s*$", row)
        if mo:
            confirmed = (int(mo.group(1)), int(mo.group(2)))
            continue
        mo = re.search(r"ime proxy selection terminal=INSTALLED reason=\S+_confirmed "
                       r"target=\[(\d+),(\d+)\) mount=" + re.escape(key) +
                       r" field=" + re.escape(field) + r"\s*$", row)
        if mo:
            target = (int(mo.group(1)), int(mo.group(2)))
            if confirmed is not None and target == confirmed:
                last_pair = target
            confirmed = None
    return last_pair


class EvidenceLost(RuntimeError):
    """内容围栏在本次读取里已被环形日志淘汰。

    2026-10-02 round4 后指导：围栏淘汰**必须具名**，不能自动退回 0 重扫整段历史
    （那会拿上一轮的旧确认冒充本次事实）。调用方据此具名失败，不用历史兜底。"""


def log_fence(rows=None):
    """内容围栏：当前设备日志的**末行文本**。

    设备 hilog 是环形缓冲：新行到达会丢弃最旧的行，既有行的**绝对下标会下移**。
    实测驱动在启动时记下的行号 272762 到判据时刻已落在读取窗口之外，同一个
    确认对用 since=0 能取到、用 since=272762 取不到——行号围栏在环形日志上
    不是稳定身份。改为记录末行内容，读取时按内容重新定位起点。"""
    rows = m.hilog_rows() if rows is None else rows
    return rows[-1] if rows else ''


def fence_index(rows, fence):
    """把内容围栏解析成当前读取里的起始下标。

    围栏行已被环形淘汰时**抛出 `EvidenceLost`**（具名失败），绝不退回 0 去扫
    整段历史——那正是复核认定的假绿来源（旧确认被当成本轮事实）。空围栏只在
    显式要求「不设围栏」时使用（调用方传 `''`）。"""
    if not fence:
        return 0
    for i in range(len(rows) - 1, -1, -1):
        if rows[i] == fence:
            return i + 1
    raise EvidenceLost('fence_evicted')


def wait_confirmed_selection(field, fence, rounds=20, require_nonempty=True):
    """有界轮询等待安装确认行（设备上安装需要几百毫秒；离线负控即时）。

    `require_nonempty=True` 时优先等待**非空**选区（拖选/命中的替换目标）；
    轮次耗尽仍只有折叠选区时返回它，由调用方按"非空选区未确认"具名失败。
    锚点冻结（正文中段 caret）传 `False`：折叠 caret 正是要冻结的落点。
    `fence` 是内容围栏（见 `log_fence`）；绝对行号在环形设备日志上不可靠，
    每轮按内容重新定位起点（围栏淘汰抛 `EvidenceLost`）。"""
    last = None
    for _ in range(rounds):
        rows = m.hilog_rows()
        sel = confirmed_selection(rows, field, fence_index(rows, fence))
        if sel is not None:
            last = sel
            if not require_nonempty or sel[0] < sel[1]:
                return sel
        time.sleep(0.3)
    return last


def last_adopted_count(tag_prefix='PHAROS', instance_pid=None):
    """当前窗口采纳计数（`{tag}_OHOS_RESTORE_ADOPTED count=N` 的最近值；无则 0）。

    这个计数只在**窗口采纳成功**之后前进（平台安装成功但窗口拒绝采纳只记 failed），
    因此可作为「窗口采用」的独立事实，而不是排队/结算冒充。
    `tag_prefix` 让第二个独立消费者（thermo 用 `THERMO`）复用同一个计数事实，
    而不是另造一条判据。`instance_pid` 给定时只统计该实例的行：hilog 缓冲跨轮
    不清空，旧实例的计数会把新实例的真实一笔压成「未前进」。"""
    last = 0
    for row in m.hilog_rows():
        if instance_pid is not None and str(row_pid(row)) != str(instance_pid):
            continue
        mo = re.search(rf"{tag_prefix}_OHOS_RESTORE_ADOPTED count=(\d+)", row)
        if mo:
            last = int(mo.group(1))
    return last


def actual_main_owner():
    """正文 owner 的**真实** documentId：启动行 `document opened path=... owner=<id>`
    （GLM 咨询：不要猜字面量 "pharos-main"）。读不到时 None——路径二不能用猜测值。"""
    for row in m.hilog_rows():
        mo = re.search(r"document opened path=\S+ .*owner=(\S+)$", row)
        if mo:
            return mo.group(1)
    return None


def row_pid(row):
    parts = row.split()
    if len(parts) < 4 or not parts[2].isdigit():
        return None
    return int(parts[2])


def _mount_lifecycle(rows, since, body_node, adopted_before=None,
                     main_owner=None, identity_hint=None, instance_pid=None,
                     tag_prefix='PHAROS'):
    """按**事件顺序**维护当前有效编辑挂载，返回逐条带来源的观测。

    round9-A 修的是 round8 的**语义错误**，不是判据松紧。round8 把三类在生产里
    **不改变当前编辑挂载**的事件一律当成「换代」，于是把已完整成立的证据清空：

    1. **幂等聚焦**：`beginEditingOnNodeLocked`（ohos_renderer.cpp:4903）对
       `wasEditing && sameBindingAsBefore && editingContextLive` **直接 return**，
       不换 `editingContextId`；但外层调用点仍会打印一行 `platform focus`。
       所以「同身份再 focus」= 同一挂载的幂等重复，**不开新代**。
    2. **迟到的旧挂载释放**：`proxy released by framework ctx=C` 是 ArkTS 侧
       TextInputProxy 的销毁通知，与 native 聚焦**不在同一执行阶段**。它只能终结
       **它所指的那个 ctx**；当前 ctx 不同就不动（不能「按最后看到的行一律退役」）。
    3. **恢复请求终结**：`recordHumanSelectionAnchorLocked` 只终结一笔**恢复请求**
       （`proxy restore terminated reason=human_anchor_supersedes`），输入上下文
       仍然有效。**请求生命周期 ≠ 挂载生命周期**，它不换代号。

    与 round8 相反的核心变化：采纳事实的归属**不再按到达时的当前代号盖章**，而是按
    生产在事件入队时冻结的来源（`CJGUI_OWNED_SELECTION_ADOPTED2 … source_ctx=
    source_gen=`）。没有来源（`source=none`）的采纳事实**一律不作证据**——按值猜
    或按当前代号盖章都无法区分「旧挂载的迟到采纳」和「新挂载的采纳」，因此宁可
    具名未证实。

    返回 `{'identity': {...}|None, 'reason': str, 'acked': [...], 'adopted': [...],
    'adopted2': {...}|None, 'observation': {...}|None, 'bind_versions': [...]}`。
    """
    state = {
        'identity': None,
        'reason': 'no_platform_focus_row',
        'acked': [],
        'adopted': [],
        'adopted2': None,
        'observation': None,
        'bind_versions': [],
        'retired_ctx': [],
        'rejected_adoption_reason': None,
    }
    # round11-D4 汇合：读回编辑身份作为**扫描种子**。`platform focus` 身份行会被
    # hilog 环形缓冲在提交突发里淘汰（设备实测：恢复成功却判 no_current_identity）
    # ——种子让扫描中段的 ACK/观测/采纳配对仍有当前身份可用。行内焦点行随后
    # 照常覆盖/换代（行内事实优先）；无行时种子就是「查询时刻的当前身份」。
    if identity_hint and identity_hint.get('live') and all(
            identity_hint.get(k) is not None
            for k in ('ctx', 'gen', 'node', 'resource', 'kind', 'binding', 'v', 'field')):
        state['identity'] = {
            'ctx': identity_hint.get('ctx'), 'node': identity_hint.get('node'),
            'field': identity_hint.get('field', ''),
            'resource': identity_hint.get('resource'),
            'kind': identity_hint.get('kind'), 'binding': identity_hint.get('binding'),
            'v': identity_hint.get('v'), 'gen': identity_hint.get('gen'),
            'basis': 'readback_edit_identity',
        }
        state['reason'] = 'identity_seeded_from_readback'

    def same_identity(identity, node, ctx, field, resource, kind, binding, v):
        """是不是**同一个挂载**：只看稳定分量，`v` 不在其中。

        `v` 是「该节点最近一次被接受发布的投影版本」，keep-ctx 发布（local-
        continuation / pure-geometry / local-accept）会在 ctx 不变的前提下推进它，
        而 `platform focus` 行打印的又是**现值**。把 v 当身份分量会把「同 ctx、v
        前进」的合法再聚焦误判成换绑，清空 ADOPTED2／观测／BIND_OWNER 候选——这
        与读回侧 `mismatch:"v"` 是同一个错误的两半。换挂载的判别力在 ctx（+
        resource/kind/binding/node/field）：生产任何真换挂载都无条件换 ctx。
        """
        return (identity is not None
                and identity['node'] == node and identity['ctx'] == ctx
                and identity['field'] == field and identity['resource'] == resource
                and identity['kind'] == kind and identity['binding'] == binding)

    for row in rows[since:]:
        # 实例边界：只看本腿当前启动实例的行；旧实例同票号行不得遮蔽配对。
        # 两侧都按字符串比：hilog 行解析出的 PID 是 int，而消费者脚本（thermo 的
        # `thermo_pid()`）拿到的是 str——直接 `!=` 会把**所有**行滤掉，守卫于是
        # 永远"未观测到"，看起来像设备没装成功，其实是类型不匹配。
        if instance_pid is not None and str(row_pid(row)) != str(instance_pid):
            continue
        # ---- 1. 焦点行：区分「同一挂载」与「换绑/换焦」 ----
        mo = re.search(r"platform focus node=(-?\d+) ctx=(-?\d+) field=(\S+)"
                       r"(?: resource=(-?\d+) kind=(\d+) binding=(\d+) v=(\d+))?", row)
        if mo:
            node, ctx, field = int(mo.group(1)), int(mo.group(2)), mo.group(3)
            complete = all(mo.group(i) is not None for i in (4, 5, 6, 7))
            if not complete:
                # 身份分量缺失：这一行不足以成为身份锚点（真实负控之一就是把
                # resource/binding 整段删掉）。不猜、不按部分字段匹配。
                state['identity'] = None
                state['reason'] = 'focus_identity_incomplete'
                state['adopted2'] = None
                state['observation'] = None
                state['bind_versions'] = []
                continue
            resource, kind, binding, v = (int(mo.group(4)), int(mo.group(5)),
                                          int(mo.group(6)), int(mo.group(7)))
            if same_identity(state['identity'], node, ctx, field, resource, kind,
                            binding, v):
                # 同一挂载：幂等重复，或 keep-ctx 发布之后的再聚焦（v 前进）。
                # 只把现值带上，**不**作废任何候选——生产没换上下文编号。
                if state['identity'].get('v') != v:
                    state['identity']['v'] = v
                continue
            # 到达这里说明**稳定分量**至少有一处不同（同挂载已在上面的
            # `same_identity` 早退处理）——ctx、node、field、resource、kind 还是
            # binding 变了，生产都换了一个挂载：换绑走
            # cancelProxyRestoreRequest + 新 editingContextId；换焦走
            # pushPendingEnd + 新编号；外部换版也换编号。旧挂载累积的一切候选
            # （ADOPTED2 / 观测 / BIND_OWNER）随之作废。
            #
            # round9 修的真实缺陷：round8 把清空挂在三个条件的分支里，于是
            # 「同 node/field、ctx 变了」这条路径没清 —— 旧挂载的 bind_versions 被
            # 留给了新挂载，旧 owner 绑定因此能补齐新挂载（复核第 5 条反例）。
            state['adopted2'] = None
            state['observation'] = None
            state['bind_versions'] = []
            if body_node is not None and node != body_node:
                state['identity'] = None
                state['reason'] = f'focus_moved_to_node_{node}_{field}'
                continue
            if field != BODY_FIELD:
                state['identity'] = None
                state['reason'] = f'focus_field_{field}'
                continue
            state['reason'] = 'current_mount'
            state['identity'] = {'ctx': ctx, 'node': node, 'field': field,
                                 'resource': resource, 'kind': kind,
                                 'binding': binding, 'v': v}
            # round13-R1：focus 行没有 gen（读回独有字段）。行与权威读回在同
            # 一挂载上全字段一致时，把读回的 gen 带上——当前身份保持**完整**
            # 元组；gen 不符说明读回已换代，行是旧历史，不作继承。
            if (identity_hint and identity_hint.get('live')
                    and identity_hint.get('ctx') == ctx
                    and identity_hint.get('node') == node
                    and identity_hint.get('field') == field
                    and identity_hint.get('resource') == resource
                    and identity_hint.get('kind') == kind
                    and identity_hint.get('binding') == binding
                    and identity_hint.get('v') == v
                    and identity_hint.get('gen') is not None):
                state['identity']['gen'] = identity_hint['gen']
            continue

        # ---- 2. 挂载释放：只终结**它所指的那个 ctx** ----
        mo = re.search(r"proxy released by framework ctx=(-?\d+)", row)
        if mo:
            released = int(mo.group(1))
            state['retired_ctx'].append(released)
            if state['identity'] is not None and state['identity']['ctx'] == released:
                # 当前挂载确实被框架释放：退役。
                state['identity'] = None
                state['reason'] = f'mount_released_ctx_{released}'
                state['adopted2'] = None
                state['observation'] = None
                state['bind_versions'] = []
            # 当前 ctx 不是被释放的那个：native 已切到新上下文，迟到通知不动它。
            continue

        # ---- 3. 恢复请求终结：请求生命周期，不是挂载生命周期 ----
        mo = re.search(r"proxy restore terminated reason=(\S+) request=(\d+) ctx=(-?\d+)", row)
        if mo:
            # 有意**不**改身份：人亲手放了落点，输入上下文仍然有效。被终结的
            # 恢复票只是不能再作为「平台已安装」的证据。
            state['reason'] = state['reason'] if state['identity'] is not None \
                else f'restore_terminated_{mo.group(1)}_no_current_identity'
            continue

        # ---- 以下事实按**冻结来源**归属，不按到达时的当前挂载 ----
        # 产品标签前缀可换（PHAROS / THERMO …）：判据只有一套，独立消费者复用
        # 同一个守卫，而不是自己写一条更松的。
        bind_tag = f'{tag_prefix}_OHOS_BIND_OWNER'
        adopted_tag = f'{tag_prefix}_OHOS_RESTORE_ADOPTED'
        if bind_tag in row:
            mo = re.search(rf"{bind_tag} owner=(\S+).*?owner_version=(-?\d+)", row)
            if mo and (main_owner is None or mo.group(1) == main_owner):
                # BIND_OWNER 是**产品**行，产品侧未在行上带 ctx。它只在**当前**挂载
                # 建立/换绑之后才算当前挂载的绑定证据；挂载一变就清空，因此旧挂载
                # 的 BIND_OWNER 不会被拿来补齐新挂载（round9 反例第 5 条）。
                state['bind_versions'].append(int(mo.group(2)))
            continue

        if adopted_tag in row:
            # 生产真实格式（round8-A 修复保留）：
            #   `... RESTORE_ADOPTED count=N failed=N pending=bool request=R ctx=C ...`
            # `failed=` / `pending=` 夹在 count 与 request 之间，因此按**具名字段**
            # 解析、顺序无关；具名身份字段缺一即不作证据（不猜、不按 count 兜底）。
            mo = re.search(rf"{adopted_tag}\b(?P<rest>.*)$", row)
            if not mo:
                continue
            fields = dict(re.findall(r"(\w+)=(\S+)", mo.group('rest')))
            try:
                count = int(fields.get('count', '-1'))
                fact = {'ticket': int(fields['request']), 'ctx': int(fields['ctx']),
                        'node': int(fields['node']),
                        'sel': tuple(int(x) for x in fields['adopted'].split(':')),
                        'owner_version': int(fields['owner_version']),
                        'version': int(fields['v'])}
            except (KeyError, ValueError):
                continue
            if count <= (adopted_before or 0):
                continue
            if body_node is None or fact['node'] == body_node:
                state['adopted'].append(fact)
            continue

        mo = re.search(r"proxy restore ack accepted request=(\d+) ctx=(-?\d+) node=(\d+) "
                       r"installed=(\d+):(\d+) v=(\d+)\s*$", row)
        if mo:
            node = int(mo.group(3))
            if body_node is None or node == body_node:
                state['acked'].append({
                    'ticket': int(mo.group(1)), 'ctx': int(mo.group(2)), 'node': node,
                    'version': int(mo.group(6)),
                    'sel': (int(mo.group(4)), int(mo.group(5)))})
            continue

        mo = re.search(r"ime selection observation forwarded ctx=(-?\d+) sel=(\d+):(\d+)"
                       r"(?: node=(-?\d+) resource=(-?\d+) kind=(\d+) binding=(\d+) v=(\d+))?", row)
        if mo:
            if state['identity'] is not None and int(mo.group(1)) != state['identity']['ctx']:
                # 静默换上下文的通道（外部换版直接换 ctx、不打 focus 行）：落在别的
                # ctx 上的观测不能与当前身份配对。
                continue
            obs = {'ctx': int(mo.group(1)), 'sel': (int(mo.group(2)), int(mo.group(3))),
                   'complete': all(mo.group(i) is not None for i in (4, 5, 6, 7, 8))}
            if obs['complete']:
                obs.update({'node': int(mo.group(4)), 'resource': int(mo.group(5)),
                            'kind': int(mo.group(6)), 'binding': int(mo.group(7)),
                            'v': int(mo.group(8))})
            state['observation'] = obs
            continue

        mo = re.search(r"CJGUI_OWNED_SELECTION_ADOPTED2 node=(-?\d+) resource=(-?\d+) "
                       r"kind=(\d+) sel=(\d+):(\d+) projection=(-?\d+) binding=(\d+)"
                       r"(?: owner_version=(-?\d+))?(?: source_ctx=(\S+) source_gen=(\S+))?",
                       row)
        if mo and state['identity'] is not None and int(mo.group(1)) == state['identity']['node']:
            fact = {'node': int(mo.group(1)), 'resource': int(mo.group(2)),
                    'kind': int(mo.group(3)), 'sel': (int(mo.group(4)), int(mo.group(5))),
                    'projection': int(mo.group(6)), 'binding': int(mo.group(7))}
            # owner_version 必须存在（round8 起为必填，保留）。
            if mo.group(8) is None:
                state['adopted2'] = None
                state['rejected_adoption_reason'] = 'adopted2_missing_owner_version'
                state['reason'] = 'adopted2_missing_owner_version'
                continue
            fact['owner_version'] = int(mo.group(8))
            # round9-A：必须带**本事件自己的**冻结来源。`source=none`（生产未给出
            # 来源）一律不作证据——无法区分旧挂载的迟到采纳与新挂载的采纳。
            if mo.group(9) is None or mo.group(10) is None:
                state['adopted2'] = None
                state['rejected_adoption_reason'] = 'adopted2_missing_frozen_source'
                state['reason'] = 'adopted2_missing_frozen_source'
                continue
            try:
                fact['source_ctx'] = int(mo.group(9))
                fact['source_gen'] = int(mo.group(10))
            except ValueError:
                state['adopted2'] = None
                state['rejected_adoption_reason'] = 'adopted2_source_not_numeric'
                state['reason'] = 'adopted2_source_not_numeric'
                continue
            # 来源必须**就是**当前挂载：不是则这条采纳属于别的挂载，不可用。
            if fact['source_ctx'] != state['identity']['ctx']:
                state['adopted2'] = None
                state['rejected_adoption_reason'] = 'adopted2_source_not_current_mount'
                state['reason'] = 'adopted2_source_not_current_mount'
                continue
            state['adopted2'] = fact
    return state


def body_restore_evidence(rows, since, body_node, adopted_before, main_owner=None,
                          owner_version=None, identity_hint=None,
                          instance_pid=None, tag_prefix='PHAROS'):
    """切回 A 后**框架自行**建立的可写落点（免点击交接的核心证据）。

    round9-A：按生产真实状态转移判定「当前有效编辑挂载」，并要求采纳事实带**生产
    在事件入队时冻结的来源**。三类不改变挂载的事件（幂等聚焦、迟到的旧挂载释放、
    恢复请求终结）不再作废已成立的证据；换焦/换绑/当前挂载被释放才真正换挂载。

    两条合法路径。版本比较的铁律是**同域且同刻**：签发时刻冻结的投影版本（armed /
    ack / adopted 三次打印同一份 `acceptedProjectionVersion`）之间才做等式；跨到
    读回（查询时刻现值）只做单调不等式，见 `_version_behind`：

      * **显式恢复票**：同请求的 `proxy restore ack accepted request=R ctx=C node=N
        installed=A:B v=V` 与同一 R 的 `PHAROS_OHOS_RESTORE_ADOPTED`（真实格式，
        具名 `request/ctx/node/adopted/owner_version/v`）逐字段相等、count>本轮起点，
        且 ctx/node 与当前身份元组一致、读回现值不回退。
      * **挂载快照**：当前身份元组 ＋ 同 ctx 的平台实际观测（含完整身份）＋ **带
        冻结来源且来源就是当前挂载**的窗口采纳事实 ADOPTED2（resource/kind/
        binding/projection/sel 逐字段等于那份观测——那是同一事件入队/出队的两次
        打印，因此合法；owner_version 必填且等于本轮冻结 owner 版本）＋ **当前挂载**
        的 `PHAROS_OHOS_BIND_OWNER`。

    当前身份缺失/被撤销、缺冻结来源、来源不属当前挂载、缺当前挂载的 owner 绑定、
    owner_version 跨域、投影版本倒退——一律**具名拒绝**，不借旧记录、不按值猜、
    不与「未观测到」混叠。
    """
    st = _mount_lifecycle(rows, since, body_node, adopted_before, main_owner,
                         identity_hint=identity_hint, instance_pid=instance_pid,
                         tag_prefix=tag_prefix)
    # round12-R1：读回身份是**权威当前快照**（查询时刻的 Session 现值）——提供且
    # 完整时，最终配对必须与它一致，历史 focus 行不能覆盖；提供但 live=False
    # （显式无当前编辑）或字段不完整时，日志里再完整的旧证据也不能救绿。
    # 记录时配对（source_ctx 与扫描内代号）仍按既有生命周期语义执行。
    # round13-R1：读回身份四类——live（完整）/ none / malformed / absent。
    # 只有 live+完整可作权威；其余三类一律**不借历史日志**通过，各自具名。
    authoritative = None
    authoritative_absent_reason = None
    if identity_hint is None:
        authoritative_absent_reason = 'readback_edit_absent'
    elif identity_hint.get('malformed'):
        authoritative_absent_reason = 'readback_edit_malformed'
    elif identity_hint.get('live') is True and all(
            identity_hint.get(k) is not None
            for k in ('ctx', 'gen', 'node', 'resource', 'kind', 'binding', 'v', 'field')):
        authoritative = identity_hint
    elif identity_hint.get('live') is False:
        # 生产明确报告「当前无编辑」：none 类，不借日志。
        authoritative_absent_reason = 'readback_edit_not_live'
    else:
        # live=True 但字段不完整：畸形，视同不可用。
        authoritative_absent_reason = 'readback_edit_malformed'
    identity = st['identity']
    # round12-R1：扫描内历史 focus/release 行可能把代际身份退役到 None（设备实测：
    # 备注换焦 ctx4→release 后，正文 ctx5 的恢复证据到达时 identity=None）。权威
    # 当前快照（读回）在此**补位**——它是查询时刻的现值，比任何历史行都新；最终
    # 配对仍逐字段对它核验。
    if authoritative is not None and authoritative.get('live') and identity is None:
        identity = dict(authoritative)
    acks = st['acked']
    adopted = st['adopted']
    observation = st['observation']
    adopted2 = st['adopted2']
    bind_versions = st['bind_versions']

    # round12/13：权威快照不可用（none/malformed/absent）时，任何已收集的恢复/
    # 采纳证据都拒绝——历史 focus/ACK/采纳行不能把「无当前身份」拼回成功。
    if ((authoritative is not None and not authoritative.get('live'))
            or authoritative_absent_reason is not None):
        if acks or adopted or st.get('adopted2') is not None \
                or st.get('observation') is not None:
            return {'source': ('restore_ack_no_current_identity' if (acks or adopted)
                               else 'mount_snapshot_no_current_identity'),
                    'reason': (authoritative_absent_reason or 'readback_edit_not_live'),
                    'current_identity': None,
                    'retired_ctx': st.get('retired_ctx', [])[-3:]}

    # ---- 路径一：显式恢复票 ----
    ticket_mismatch = None
    for ack in reversed(acks):
        # 票号按实例/会话重起而 hilog 跨轮不清空：同号旧采纳会遮蔽当前采纳，
        # 必须取最新（字段相等仍逐项核验，单代行为不变）。
        fact = next((a for a in reversed(adopted) if a['ticket'] == ack['ticket']), None)
        if fact is None:
            continue
        # **票内**等式保留：armed↔ack↔adopted 是同一签发时刻冻结值的三次打印，
        # 同刻同域才可相等；这一处不符是真异常（也是「产品按当前代际重认领」这类
        # 改法的证伪器），具名上报而不是静默换下一条票。
        if not (fact['ctx'] == ack['ctx'] and fact['node'] == ack['node']
                and fact['sel'] == ack['sel'] and fact['version'] == ack['version']):
            ticket_mismatch = {
                'source': 'restore_ack_ticket_fields_mismatch', 'sel': ack['sel'],
                'node': ack['node'], 'ctx': ack['ctx'], 'ticket': ack['ticket'],
                'version': ack['version'], 'adopted_version': fact['version'],
                'adopted_sel': fact['sel'], 'adopted_ctx': fact['ctx']}
            continue
        if owner_version is not None and fact['owner_version'] != owner_version:
            continue
        if identity is None:
            return {'source': 'restore_ack_no_current_identity', 'sel': ack['sel'],
                    'node': ack['node'], 'ctx': ack['ctx'], 'ticket': ack['ticket'],
                    'version': ack['version'], 'reason': st['reason']}
        # 跨时刻**不核 v 等式**（见 `_version_behind`）：稳定分量决定是不是同一个
        # 挂载，投影版本按单调核。换挂载的判别力全在 ctx 上——生产任何真换挂载都
        # 无条件换 ctx，旧挂载的采纳因此必然在 ctx 这一处具名拒绝。
        mismatch = _identity_mismatch(identity, ctx=ack['ctx'], node=ack['node'])
        if mismatch:
            return {'source': 'restore_ack_identity_not_current', 'sel': ack['sel'],
                    'node': ack['node'], 'ctx': ack['ctx'], 'ticket': ack['ticket'],
                    'version': ack['version'], 'mismatch': mismatch,
                    'current_identity': identity}
        if _version_behind(identity.get('v'), ack['version']):
            return {'source': 'restore_ack_version_behind_current', 'sel': ack['sel'],
                    'node': ack['node'], 'ctx': ack['ctx'], 'ticket': ack['ticket'],
                    'version': ack['version'], 'current_version': identity.get('v'),
                    'current_identity': identity}
        if authoritative is not None:
            amiss = _identity_mismatch(authoritative, ctx=ack['ctx'], node=ack['node'])
            if amiss:
                return {'source': 'restore_ack_identity_not_current', 'sel': ack['sel'],
                        'node': ack['node'], 'ctx': ack['ctx'], 'ticket': ack['ticket'],
                        'version': ack['version'], 'mismatch': amiss,
                        'current_identity': authoritative,
                        'basis': 'readback_authoritative_identity'}
            if _version_behind(authoritative.get('v'), ack['version']):
                return {'source': 'restore_ack_version_behind_current', 'sel': ack['sel'],
                        'node': ack['node'], 'ctx': ack['ctx'], 'ticket': ack['ticket'],
                        'version': ack['version'],
                        'current_version': authoritative.get('v'),
                        'current_identity': authoritative,
                        'basis': 'readback_authoritative_identity'}
        return {'source': 'restore_ack', 'sel': ack['sel'], 'node': ack['node'],
                'ctx': ack['ctx'], 'ticket': ack['ticket'], 'version': ack['version'],
                'owner_version': fact['owner_version'], 'current_identity': identity,
                'adoption_count_basis': 'same-request+current-mount'}

    # ---- 路径二：挂载快照 ----
    if identity is None:
        if st['rejected_adoption_reason'] is not None:
            return {'source': st['rejected_adoption_reason'],
                    'reason': st['rejected_adoption_reason']}
        if acks or adopted or st['adopted2'] is not None:
            return {'source': 'mount_snapshot_no_current_identity', 'reason': st['reason'],
                    'retired_ctx': st['retired_ctx'][-3:]}
        return None
    if adopted2 is None and st['rejected_adoption_reason'] is not None \
            and st['identity'] is not None:
        # round9：采纳事实存在但**被拒**（缺冻结来源 / 来源不属当前挂载 / 缺
        # owner_version）。这是「未证实」，不是「未观测到」——必须具名上报，
        # 否则调用方会把两者混叠成同一条静默丢弃。
        return {'source': st['rejected_adoption_reason'],
                'current_identity': identity,
                'reason': st['rejected_adoption_reason']}
    if adopted2 is not None:
        if observation is None:
            return {'source': 'mount_snapshot_no_platform_observation',
                    'current_identity': identity}
        if not observation.get('complete'):
            return {'source': 'mount_snapshot_observation_identity_incomplete',
                    'current_identity': identity, 'observed': observation}
        if observation['sel'] != adopted2['sel']:
            return {'source': 'mount_snapshot_selection_mismatch',
                    'current_identity': identity, 'observed': observation,
                    'adopted2': adopted2}
        for key in ('node', 'resource', 'kind', 'binding', 'v'):
            other = 'projection' if key == 'v' else key
            if observation[key] != adopted2[other]:
                return {'source': f'mount_snapshot_{key}_mismatch',
                        'current_identity': identity, 'observed': observation,
                        'adopted2': adopted2}
        stale = _identity_mismatch(identity, node=adopted2['node'],
                                   resource=adopted2['resource'], kind=adopted2['kind'],
                                   binding=adopted2['binding'])
        if stale:
            return {'source': 'mount_snapshot_not_current_identity', 'mismatch': stale,
                    'current_identity': identity, 'observed': observation, 'adopted2': adopted2}
        if owner_version is not None and adopted2['owner_version'] != owner_version:
            return {'source': 'mount_snapshot_owner_version_mismatch',
                    'current_identity': identity, 'observed': observation,
                    'adopted2': adopted2, 'frozen_owner_version': owner_version}
        # round9-A：当前挂载**必须**有 owner 绑定。round8 的 `if bind_versions` 在
        # 空列表时整段跳过检查，等于「缺 BIND_OWNER 也算完整挂载证明」。
        if not bind_versions:
            return {'source': 'mount_snapshot_no_current_owner_binding',
                    'current_identity': identity, 'observed': observation,
                    'adopted2': adopted2}
        if adopted2['owner_version'] not in bind_versions:
            return {'source': 'mount_snapshot_owner_version_not_bound',
                    'current_identity': identity, 'observed': observation,
                    'adopted2': adopted2, 'bind_owner_versions': bind_versions}
        if authoritative is not None:
            amiss = _identity_mismatch(authoritative, ctx=identity['ctx'],
                                       node=adopted2['node'],
                                       resource=adopted2['resource'],
                                       kind=adopted2['kind'],
                                       binding=adopted2['binding'])
            if amiss:
                return {'source': 'mount_snapshot_not_current_identity', 'mismatch': amiss,
                        'current_identity': authoritative, 'observed': observation,
                        'adopted2': adopted2, 'basis': 'readback_authoritative_identity'}
        return {'source': 'mount_snapshot', 'sel': adopted2['sel'], 'node': identity['node'],
                'ctx': identity['ctx'], 'ticket': None, 'version': None,
                'owner_version': adopted2['owner_version'], 'current_identity': identity,
                'observed': observation, 'adopted2': adopted2,
                'adoption_count_basis': 'frozen-source+window-adoption-fact+identity-tuple'}
    if acks and not adopted:
        ack = acks[-1]
        return {'source': 'restore_ack_unadopted', 'sel': ack['sel'], 'node': ack['node'],
                'ctx': ack['ctx'], 'ticket': ack['ticket'], 'version': ack['version']}
    if ticket_mismatch is not None:
        # 采纳事实存在、也有平台回执，但同一请求号在票内互相矛盾（签发冻结值被
        # 打印成了两个不同的 v/sel/ctx）。这是「未证实」，不是「未观测到」。
        return ticket_mismatch
    if acks:
        ack = acks[-1]
        return {'source': 'restore_ack_identity_mismatch', 'sel': ack['sel'],
                'node': ack['node'], 'ctx': ack['ctx'], 'ticket': ack['ticket'],
                'version': ack['version'], 'adopted_tickets': [a['ticket'] for a in adopted]}
    return None


def _identity_mismatch(identity, ctx=None, node=None, version=None, sel=None,
                       resource=None, kind=None, binding=None):
    """逐字段比较当前身份元组，返回第一处不符的字段名（全部相符则 None）。

    身份元组里投影版本的键是 `v`（与 `platform focus` 行同名），这里对外用
    `projection` 指代，避免与 owner 内容版本域混淆——两者分属不同域，绝不相比。

    **同域还必须同刻**：`v` 只有在「同一事件/同一票据冻结值的两次打印」之间才可做
    等式比较（路径二的 ADOPTED2.projection ↔ 观测行、票内 armed↔ack↔adopted）。
    跨时刻（签发冻结值 ↔ 读回查询现值）只能做单调不等式，调用方**不得**把 `version`
    传进来，改用 `_version_behind`；不传即不比较。
    """
    pairs = (('ctx', ctx), ('node', node), ('resource', resource), ('kind', kind),
             ('binding', binding), ('v', version), ('selection', sel))
    for key, value in pairs:
        if value is None:
            continue
        if identity.get(key) != value:
            return key
    return None


def _version_behind(current, frozen):
    """跨时刻的投影版本只核**单调**：现值不得低于该票据签发时冻结的值。

    为什么不能核等式（本轮设备原件推翻的正是等式）：

    * 读回 `v` 是**查询时刻**的 Session 现值——`cjguiOhosEditingIdentityOf` 直接取
      `s.editingProjectionVersion`，host 侧注释明写「只在查询时从 Session 现值读取」。
    * 采纳/ACK 行的 `v` 是**签发时刻**冻结值（`req.acceptedProjectionVersion`）。
    * 生产不变量：任何**真换挂载**都无条件换 ctx（`beginEditingOnNodeLocked` 取
      `g_nextEditingContextId.fetch_add(1)`），而 keep-ctx 发布（local-continuation /
      pure-geometry / local-accept）推进 `editingProjectionVersion` 却**不换 ctx**。
    * 更要紧的是「采纳成功」这个动作**自身**会 `interactionVersion += 1` 调度下一次
      发布——所以读回必然落在更晚的代际（实测 159↔161、164↔167，差值不恒定）。
      等式不是「难赢的竞态」，是被生产结构性地保证不可能成立，且对串票零判别力。

    保留的不等式抓的是残留形状：ctx 计数是进程级原子不重置，而窗口重建会重置场景版本
    计数，因此「同 pid 内旧窗口的采纳串进新窗口」会表现为现值**倒退**，具名拒绝。
    """
    if current is None or frozen is None:
        return False
    return current < frozen


def expected_after_replacement(before_hex, start16, end16, new_text):
    """独立期望：冻结选区 + 严格 oracle 映射 + 唯一期望正文（hex）。"""
    raw = bytes.fromhex(before_hex)
    return strict_utf16.expected_replacement(raw, start16, end16, new_text).hex()


def _fence_start(rows, fence):
    """内容围栏 → 起始下标。围栏行已被环形淘汰时返回 None（**不**退回 0 重扫历史）。

    round8-D：围栏必须按**行文本**而不是绝对下标——设备 hilog 是环形缓冲，下标会
    随新行到达与前缀淘汰漂移。围栏被淘汰时宁可答「未观测」，也不拿淘汰前的旧提交
    行冒充当前面（那正是 round7 的错法）。
    """
    if not fence:
        return 0
    for i in range(len(rows) - 1, -1, -1):
        if rows[i] == fence:
            return i + 1
    return None


def accepted_commit_marker(rows, fence=None):
    """`fence` 之后最近一条**中性**提交标记 `accepted commit v=V ticket=T nodes=K`。

    round9-D：round8 的对应函数叫 `accepted_faces`，解析的是
    `accepted faces … source=N preview=M` ——那三个字段是**产品语义**，由通用
    renderer 硬编码 pharos-* 前缀算出来。round9 撤掉了那层（任务第 4 条：通用
    renderer 只报不解释，分类归产品或驱动），因此驱动现在自己分类：先用这条中性
    行确定「哪个投影版本已 accepted 提交」，再用**同一版本**的 `accepted node=`
    行按驱动自己的前缀表判面。

    `fence` 是模式动作之前那一行的**文本**（不是下标：环形缓冲会淘汰前缀，下标漂移）。
    没有围栏时最近一条提交行可能属于切换**之前**——那正是 round7 把「已切」读成
    source 的形态。围栏行本身被回收时返回 None（未观测），**不**退回 0 重扫历史。

    返回 `(version, nodes, row_index)`；没有则 None。
    """
    start = _fence_start(rows, fence)
    if start is None:
        return None
    for i in range(len(rows) - 1, start - 1, -1):
        mo = re.search(r"accepted commit v=(\d+) ticket=(\d+) nodes=(\d+)", rows[i])
        if mo:
            return (int(mo.group(1)), int(mo.group(3)), i)
    return None


# 旧名保留为别名：负控与既有调用点仍按 accepted_faces 取提交标记。语义已变（不再
# 返回 source/preview 计数），调用点一律只取其中的 version。
accepted_faces = accepted_commit_marker


# 驱动的**独立**面分类（产品语义留在这里，与产品 state 线的声明互为独立验证）。
_BODY_PREFIXES = ('pharos-editor-body',)
_PREVIEW_PREFIXES = ('pharos-document-note', 'pharos-editor-block')


def _classify_face(semantic):
    """按语义标签判面。返回 'source' / 'preview' / None（不属任一面）。

    这是**驱动自己的**词表，与产品 `previewFacts()` 的声明互相独立：两层不一致
    即 `face_declaration_mismatch`，不单信一层（咨询第 4 节）。
    """
    if semantic.startswith(_BODY_PREFIXES):
        return 'source'
    if semantic.startswith(_PREVIEW_PREFIXES):
        return 'preview'
    return None


def scene_face(rows, fence=None):
    """`fence` 围栏之后当前 accepted 投影的**面**；未观测到返回 None（绝不沿用旧面）。

    判据链：中性提交标记（哪个版本已提交）→ 同版本的 `accepted node=` 逐节点
    语义 → 驱动自己的前缀分类。

    两条硬约束（round8 起未变，round9 保留）：
      * **未观测到就返回 None**，绝不沿用旧面。设备 hilog 是环形缓冲，「没看到」
        推不出「没发生」——那正是 round7/��und8 反复误判的根源。
      * node→semantic 映射只允许来自**同一提交版本**的转储行。旧实现扫全历史取
        最后一条，换绑/重挂导致 node id 复用时映射整体过期。
    """
    marker = accepted_commit_marker(rows, fence)
    if marker is None:
        return None
    version, _nodes, anchor = marker
    # 逐节点行打印在 `accepted commit` **标记之前**（转储与摘要是同一次提交的两半，
    # 摘要在转储之后收口）。本次提交的行区间因此是「上一条提交标记之后 → 本条
    # 标记」。若这是可见窗口里的**第一条**提交标记，就没有上一条，区间下界取动作
    # 围栏（没有围栏则取 0）——否则会从标记行往后扫，永远扫不到自己的节点行，
    # 面恒为 None（round9 首次实现正是这个错）。
    scan_from = _fence_start(rows, fence) or 0
    for i in range(anchor - 1, scan_from - 1, -1):
        if 'accepted commit v=' in rows[i]:
            scan_from = i + 1
            break
    sem = {}
    for r in rows[scan_from:]:
        mo = re.search(r'accepted node=(-?\d+) semantic=(\S+) .*? v=(\d+)', r)
        if mo and int(mo.group(3)) == version:
            sem[int(mo.group(1))] = mo.group(2)
    # 提交点之后可能还有同版本的逐节点行（转储按内容指纹重发，提交标记恒定一行）。
    face = None
    for r in rows[scan_from:]:
        mo = re.search(r'text layout painted \S+ ctx=-?\d+ ticket=(\d+) node=(-?\d+)', r)
        if mo:
            face = _classify_face(sem.get(int(mo.group(2)), '')) or face
            continue
        mo = re.search(r'accepted node=(-?\d+) semantic=(\S+) .*? v=(\d+)', r)
        if mo and int(mo.group(3)) == version:
            face = _classify_face(mo.group(2)) or face
    return face


def driver_face(port, fence=None, snapshot=None):
    """驱动的**独立**面分类。传入 `snapshot` 时只用那一份（判定路径必须如此）。

    清单优先的原因：accepted 全量转储按内容指纹门控，内容未变时不重发逐节点行，
    日志路径因此在「提交已发生但内容没变」时恒读不到面；清单是中性事实且有界。
    """
    snap = snapshot if snapshot is not None else public_snapshot(port)
    face = driver_face_from_snapshot(snap)
    if face is not None and not str(face).startswith('ambiguous:'):
        return face
    return scene_face(m.hilog_rows(), fence)

def mode_trace(port, target):
    """一次有界模式定位记录（失败时用）：命令入队→模式读数→accepted 场景面→
    焦点/挂载→恢复行。用于按断点定位真实问题，不用补点或加等待掩盖。"""
    rows = m.hilog_rows()
    marker = accepted_commit_marker(rows)
    rb = accepted_readback(port)
    return {
        'target': target,
        'owner_state': current_mode(port),
        'scene_face': scene_face(rows),
        'driver_face': driver_face(port, None),
        # round9-D：把「已提交但面未知」与「未提交」分开，并**并列**给出读回事实
        # （产品声明的 face + 票据阶段），使失败记录本身就能定位断点。
        'accepted_marker': (None if marker is None else
                            {'v': marker[0], 'nodes': marker[1]}),
        'accepted_readback': rb,
        'owner_alive': [r for r in rows[-60:] if 'stage=owner-claim' in r][-2:],
        'loglimit': [r for r in rows[-400:] if 'LOGLIMIT' in r][-2:],
        'focus_or_mount': [r for r in rows[-40:] if
                           ('platform focus node=' in r or 'proxy mounted key=' in r
                            or 'proxy restore' in r or 'ime proxy restore' in r)][-6:],
        'tail': rows[-8:],
    }


def reach_mode(port, target, results, tag, rounds=24):
    """把应用带到目标模式：**一次**模式动作 + 有界等待，每轮判定只用一份快照。

    **免点击纪律（2026-10-02 round4 后指导）**：不对正文补点、不做 kick、不重复
    toggle。已处于目标模式则只等待事实成立；否则**只点一次**模式按钮，然后有界
    轮询。超时具名失败并记定位 trace，不用补点、加等待或「设备抖动」收口。

    round10-D3（三条硬纪律）：
      1. **单份响应**：一次判定内只调 `public_snapshot` 一次，mode / accepted 身份 /
         票据 / 节点全部从这同一个 dict 读。旧实现一次判定取三份再拼，round10 的
         6 份互不一致响应因此被判成成功。
      2. **动作关联**：动作前取 `action_baseline`（含 **token**），判定要求票据
         票号 > 基线且 token 相同；动作之前的历史 ACCEPTED 不能冒充本次，异 token
         即使计数更大也具名拒绝（round11-D3）。
      3. **无动作确认单列**：已在目标模式、当前 accepted 面就是目标面且 token
         未变时记 `already-at-target`，只免除新票要求，不免除字段完整与面一致；
         MODE 声明到位而 accepted 还是旧面 → 具名 `accepted_face_not_target`，
         等待或失败，不反向 toggle。
    """
    # 模式动作前那一行的**文本**围栏（面判据的日志侧下界，按文本而非下标：
    # 环形缓冲会淘汰前缀，绝对下标会漂移）。
    action_fence = {'text': None}
    baseline = action_baseline(port)

    def judge():
        """一次判定：取**一份**快照，返回 (ok, outcome, facts, snap)。"""
        snap = public_snapshot(port)
        facts = {
            'token': snap.get('token'), 'epoch': snap.get('epoch'),
            'frame': snap.get('frame'), 'last': snap.get('last'),
            'unacked': snap.get('unacked'),
            'baseline_token': baseline.get('token'),
            'baseline_max_ticket': baseline.get('max_ticket'),
            'driver_face': driver_face_from_snapshot(snap),
            'face_list_truncated': snap.get('face_list_truncated'),
        }
        if not snap.get('readable'):
            return False, 'readback_unavailable', facts, snap
        if snap.get('mode') != target:
            return False, 'mode_not_at_target', facts, snap
        if snap.get('unacked') not in (None, 0):
            return False, 'ticket_in_flight', facts, snap
        # 驱动独立分类：清单多面并存不得取第一个前缀
        face = driver_face_from_snapshot(snap)
        if face is None:
            return False, 'driver_face_unobserved', facts, snap
        if str(face).startswith('ambiguous:'):
            return False, 'driver_face_ambiguous', facts, snap
        # round11-D3：同一动作的结果必须**同 token**（round10 的「产品重建会话」
        # 前提已撤回——token 6→8→10 实为格式串错位）。异 token 即使
        # epoch/frame/ticket 更大也拒绝；跨 session 接续须显式交接凭据。
        if (baseline.get('token') is not None and snap.get('token') is not None
                and snap['token'] != baseline['token']):
            return False, 'stale_token', facts, snap
        # 同 token 下 epoch 倒退是独立异常（槽内发布修订不应回退）。
        if (baseline.get('epoch') is not None and snap.get('epoch') is not None
                and snap['epoch'] < baseline['epoch']):
            return False, 'stale_epoch', facts, snap
        # 本次动作之后的票（票号 > 基线）
        after = [t for t in (snap.get('tickets') or [])
                 if t['ticket'] > max(baseline.get('max_ticket') or 0,
                                      baseline.get('last') or 0)]
        if not after:
            # 没有本次动作之后的票：仅当基线本来就在目标、且**当前** accepted 面
            # 就是目标面时才是无动作确认——already_at_target 只免除新票要求，
            # 不免除字段完整与目标面一致（round11 反例：MODE=preview 而清单里
            # 只有 source 也被放行）。面证据缺失/歧义已在上方具名返回。
            if baseline.get('mode') == target and baseline.get('readable'):
                if face != target:
                    return False, 'accepted_face_not_target', facts, snap
                return True, 'already_at_target', facts, snap
            return False, 'no_ticket_after_baseline', facts, snap
        verdict, vfacts = ticket_verdict(after[-1], target, baseline, snap)
        facts.update(vfacts)
        if verdict == 'this_action_submitted' and face == target:
            return True, 'submitted_target', facts, snap
        return False, verdict, facts, snap

    def settled():
        """一次判定只用一份快照；外层再整体重做一次做稳定复检。"""
        ok, outcome, facts, _snap = judge()
        return ok, outcome, facts

    def settledTwice():
        ok1, o1, f1 = settled()
        if not ok1:
            return False, o1, f1
        time.sleep(0.6)
        ok2, o2, f2 = settled()          # 第二次**独立**判定，各自单份自洽
        return (ok2, o2, f2) if ok2 else (False, f'unstable:{o1}->{o2}', f2)

    # ---- 1. 已在目标模式：不制造无效提交，单列确认 ----
    ok, outcome, facts = settled()
    if ok:
        results.setdefault('mode_probes', []).append({tag: outcome, **facts})
        results.setdefault('baseline', {})[tag] = baseline
        return True, outcome

    # ---- 2. 一次模式动作（仅当模式确实不在目标）----
    # round11-D3：模式**声明**已在目标而 accepted 未到位（旧面/在途/证据缺失）时，
    # 再点 toggle 会把已到位的模式**反向切走**——只能有界等待当前请求结算或具名
    # 失败（零额外动作）；模式确实不在目标时才发那一次动作。
    if baseline.get('mode') != target:
        # round11-D4：按钮定位走**读回几何**（accepted 发布边界冻结的 ` geo ` 段
        # + 平台 XComponent 原点），不读 hilog node-rect、不按屏幕猜比例。失败
        # 具名记录，绝不用旧坐标或日志推导回退。
        p, geo_reason = m.readback_target_point('pharos-preview', port)
        if not p:
            results.setdefault('mode_probes', []).append(
                {tag: 'button-geometry', 'reason': geo_reason})
            results.setdefault('mode_trace', []).append(mode_trace(port, target))
            return False, "button-point-missing"
        _pre = m.hilog_rows()
        action_fence['text'] = _pre[-1] if _pre else ''
        # 动作**前**再取一次基线：点击本身可能已引发第一次提交。
        baseline = action_baseline(port)
        m.uitest('click', str(p[0]), str(p[1]))

    for _ in range(rounds):
        ok, outcome, facts = settledTwice()
        if ok:
            results.setdefault('mode_probes', []).append({tag: outcome, **facts})
            results.setdefault('baseline', {})[tag] = baseline
            return True, outcome
        time.sleep(0.4)

    # 超时：用**本轮最后一份**快照的事实具名上报，不用日志围栏代替票据结局。
    # round11-D3：结局名优先取**最后一次判定的具名结论**（accepted_face_not_target /
    # driver_face_ambiguous / stale_token 等）——按快照重推的兜底名会把真实失败
    # 掩盖成更弱的观察缺失名。
    last_outcome = outcome
    snap = public_snapshot(port)
    facts = {
        'token': snap.get('token'), 'epoch': snap.get('epoch'),
        'frame': snap.get('frame'), 'last': snap.get('last'),
        'unacked': snap.get('unacked'),
        'baseline_token': baseline.get('token'),
        'baseline_max_ticket': baseline.get('max_ticket'),
        'driver_face': driver_face_from_snapshot(snap),
        'face_list_truncated': snap.get('face_list_truncated'),
    }
    after = [t for t in (snap.get('tickets') or [])
             if t['ticket'] > max(baseline.get('max_ticket') or 0,
                                  baseline.get('last') or 0)]
    if after:
        verdict, vfacts = ticket_verdict(after[-1], target, baseline, snap)
        facts.update(vfacts)
        outcome = verdict
    else:
        outcome = last_outcome
    fence_alive = _fence_start(m.hilog_rows(), action_fence['text']) is not None
    results.setdefault('mode_probes', []).append(
        {'tag': outcome, 'fence_alive': fence_alive, **facts})
    trace = mode_trace(port, target)
    trace['ticket_outcome'] = outcome
    trace['ticket_facts'] = facts
    trace['baseline'] = baseline
    results.setdefault('mode_trace', []).append(trace)
    return False, outcome


MAP_ROW = re.compile(r"(?:^|\s)(\S+)\s+tcp:(\d+)\s+(\S+)\s+\[Forward\]")


def forward_rows(listing, local_port):
    """`fport ls` 每行是一条完整映射 `(target, local, remote)`。

    必须**同一行**取三元组：跨行拼接会把别人的端口或远端读成本轮事实（round5
    后指导 B 的跨行反例）。"""
    return [(mo.group(1), int(mo.group(2)), mo.group(3))
            for line in (listing or '').splitlines()
            if (mo := MAP_ROW.search(line)) and int(mo.group(2)) == local_port]


def acquire_forward(port, remote_port=7856):
    """取得本轮转发清理权：读列表 rc=0 ＋ 端口原为空 ＋ 创建 rc=0 ＋ 明确回执
    ＋ 复查同一行 `target/tcp:port/tcp:remote` 精确相等。任一不满足都不认领。"""
    first = m.hdc("fport", "ls")
    if first.returncode != 0:
        return False, f"forward_list_failed_rc={first.returncode}"
    if forward_rows(first.stdout, port):
        return False, f"forward_port_occupied:{forward_rows(first.stdout, port)}"
    r = m.hdc("fport", f"tcp:{port}", f"tcp:{remote_port}")
    blob = ((r.stdout or "") + (r.stderr or "")).strip()
    if r.returncode != 0:
        return False, f"forward_fail_rc={r.returncode}:{blob[:160]}"
    if "Forwardport result:OK" not in (r.stdout or "") or "[Fail]" in blob:
        return False, f"forward_no_receipt:{blob[:160]}"
    again = m.hdc("fport", "ls")
    if again.returncode != 0:
        return False, f"forward_relist_failed_rc={again.returncode}"
    expect = [(m.TARGET, port, f"tcp:{remote_port}")]
    if forward_rows(again.stdout, port) != expect:
        return False, f"forward_mapping_mismatch:{forward_rows(again.stdout, port)}"
    return True, "created+verified"


def release_forward(port, remote_port=7856):
    """清理前再核验同一行完整映射；不匹配就不动别人的映射，也不先 rm。"""
    ls = m.hdc("fport", "ls")
    if ls.returncode != 0:
        return f"forward_cleanup_skipped_list_rc={ls.returncode}"
    rows = forward_rows(ls.stdout, port)
    if not rows:
        return "already_absent"
    expect = [(m.TARGET, port, f"tcp:{remote_port}")]
    if rows != expect:
        return f"forward_cleanup_skipped_mismatch:{rows}"
    m.hdc("fport", "rm", f"tcp:{port}", f"tcp:{remote_port}")
    return "removed"


def _finish(results, out, port, fwd_ok):
    if fwd_ok:
        results['forward_cleanup'] = release_forward(port)
    (out / 'raw-responses.json').write_text(json.dumps(ARCHIVE, ensure_ascii=False, indent=2))
    # 关联日志整段落盘（指导 A：离线重判要能看到判据读到的每一行原文）。
    try:
        (out / 'hilog_rows.txt').write_text('\n'.join(m.hilog_rows()) + '\n')
    except Exception:  # noqa: BLE001
        pass
    (out / 'dual-owner.json').write_text(json.dumps(results, ensure_ascii=False, indent=2))
    print(json.dumps({'status': results.get('status'),
                      'required_values': results.get('required_values')}, ensure_ascii=False))
    return 0 if results.get('status') == 'OK' else 1


def main() -> int:
    global OUT
    ap = argparse.ArgumentParser()
    ap.add_argument('--out', required=True)
    ap.add_argument('--port', type=int, default=28997)
    ap.add_argument('--anchor-mode', choices=['caret', 'span'], default='caret',
                    help='A 冻结锚：caret=原折叠 caret 正控；span=正文中段非空选区'
                         '（round12-R3 新增必需腿，removed>0 恰一笔）')
    # round7-B：target 必填，且是**所有**设备命令的唯一来源（共享 helper 的模块
    # 常量不再是目标来源）。缺参数时 argparse 直接非 0 退出，零设备命令。
    ap.add_argument('--target', required=True,
                    help='hdc target (e.g. 127.0.0.1:5555)')
    args = ap.parse_args()
    target = args.target.strip()
    if not target:
        log('FAIL --target 为空：设备目标未配置，零设备命令')
        return 2
    m.TARGET = target
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
    # 日志围栏用**内容**（末行文本），不用绝对行号：设备 hilog 是环形缓冲，
    # 行号会随新行到达而漂移。本轮所有日志判据都从围栏之后取。
    fence0 = log_fence()
    results['log_fence0'] = fence0[-120:]

    port = args.port
    # round12-R2：本包**全部**目标几何（正文/备注/模式按钮）走同一读回入口，
    # 不再读 hilog node-rect、不按屏幕猜比例；查询次数随结果落盘（有界成本）。
    def rb_point(semantic, vp_x=None, vp_y=None):
        results['geo_query_count'] = results.get('geo_query_count', 0) + 1
        pt, _why = m.readback_target_point(semantic, port, vp_x=vp_x, vp_y=vp_y)
        return pt

    def rb_rect(semantic):
        results['geo_query_count'] = results.get('geo_query_count', 0) + 1
        rect, _why = m.readback_target_rect(semantic, port)
        return rect

    # 转发归属：只有本轮显式创建、且同一行 (target, local, remote) 精确匹配才认领清理权。
    fwd_ok, fwd_why = acquire_forward(port)
    results['forward'] = {'owned': fwd_ok, 'basis': fwd_why}
    if not fwd_ok:
        results['status'] = 'forward_not_owned'
        return _finish(results, out, port, False)

    try:
        # ---- 1. A 基线：fixture 重置后冻结双方 owner ----
        fixture_ok, fixture_detail = m.reset_fixture(port)
        results['fixture_reset'] = fixture_ok
        if not fixture_ok:
            results['status'] = 'clean_baseline_unavailable'
            return _finish(results, out, port, fwd_ok)
        # A 阶段必须在**正文面**：上一轮可能停在预览。已处于 source 则不点击；
        # 否则做一次模式动作进入正文（守卫式，不重复 toggle）。正文面未跟即具名失败。
        if not reach_mode(port, 'source', results, 'ensure-source')[0]:
            results['status'] = 'source_mode_not_reached'
            return _finish(results, out, port, fwd_ok)
        results['main_owner'] = actual_main_owner()
        note_rid = find_note_resource(port)
        results['note_resource_id'] = note_rid
        # 备注资源可能尚未创建（惰性）：首轮 A 冻结允许 note 缺席，但 B 阶段后
        # 必须存在，否则具名失败。
        a_main_v, a_main_hex = m.read_all(port)
        a_note_v, a_note_hex = (read_public(port, note_rid) if note_rid else (None, None))
        a_freeze = {'main_version': a_main_v, 'main_hex': a_main_hex, 'note_hex': a_note_hex}
        # 冻结基线**完整**落盘（round5 后指导 A：复核需要能独立重判原始字节，
        # 截断成 32 字符的摘要不能证明基线本身）。
        results['a_freeze'] = dict(a_freeze)
        results['a_freeze']['main_bytes'] = len(a_main_hex) // 2
        # ---- 1b. 准备阶段：一次真实点击正文中段建立原锚 ----
        # 2026-10-02 round4 后指导：允许**一次**真实点击正文中段建立锚点（不计作
        # 切回后的补点）。使用自有临时夹具（reset_fixture 已写回固定内容，前后有可
        # 区别的中段），重置后先确认当前 owner 版本/完整字节、accepted 正文绑定
        # （正文 node），取得平台**实际选区**后冻结源字节 caret。
        # 不做历史扫描、不做 clamp：越界/版本不合/身份缺失一律具名失败，不以文末
        # 默认位置替代中段恢复。
        body_node = accepted_node_id(BODY_FIELD)
        results['body_node'] = body_node
        rect_body = rb_rect(BODY_FIELD)
        if body_node is None or rect_body is None:
            results['status'] = 'body_surface_unreachable'
            return _finish(results, out, port, fwd_ok)
        anchor_len16 = len(bytes.fromhex(a_main_hex).decode('utf-8').encode('utf-16-le')) // 2
        results['a_anchor_doc_len16'] = anchor_len16
        # 正文节点（107）覆盖整个编辑区，中线常落在文字下方的空白里。按文本行
        # 位置由上向下探测若干命中点，读平台实际落点（`human anchor recorded ...
        # node=107`），取一个**严格中段**的折叠 caret（既非 0 也非文末）。探测
        # 全部发生在准备阶段，不计作切回后的补点；不成立即具名失败，不 clamp。
        a_anchor_sel = None
        a_anchor_probe = []
        for vy in range(18, 96, 6):
            for vx in (20, 60, 110, 170):
                hit = rb_point(BODY_FIELD, vp_x=vx, vp_y=vy)
                if hit is None:
                    continue
                f = log_fence()
                m.uitest('click', str(hit[0]), str(hit[1]))
                time.sleep(0.8)
                sel = None
                for _ in range(4):
                    rows = m.hilog_rows()
                    sel = latest_body_anchor(rows, fence_index(rows, f), body_node)
                    if sel is not None:
                        break
                    time.sleep(0.3)
                a_anchor_probe.append({'vp': [vx, vy], 'sel': list(sel) if sel else None})
                if sel is not None and 0 < sel[0] == sel[1] < anchor_len16:
                    a_anchor_sel = sel
                    break
            if a_anchor_sel is not None:
                break
        results['a_anchor_probe'] = a_anchor_probe
        results['a_anchor'] = {'sel': list(a_anchor_sel) if a_anchor_sel else None,
                               'node': body_node}
        if a_anchor_sel is None:
            results['status'] = 'a_anchor_unconfirmed'
            return _finish(results, out, port, fwd_ok)
        # 准备点击不产生 owner 事务：正文版本与字节必须逐字节不变。
        a_main_v, a_main_hex = m.read_all(port)
        if a_main_hex != a_freeze['main_hex']:
            results['status'] = 'prep_click_changed_owner'
            return _finish(results, out, port, fwd_ok)
        results['a_freeze']['main_version'] = a_main_v

        # ---- 1c. span 模式：从中段 caret 同行拖选出**非空中段跨度**并冻结 ----
        # round12-R3：原任务要求的正文中段非空选区。期望全文在动作前从冻结字节
        # 独立计算；恢复后免点击首笔必须精确替换该跨度（removed>0、恰一笔）。
        span_mode = (args.anchor_mode == 'span')
        results['anchor_mode'] = args.anchor_mode
        a_span_sel = None
        if span_mode:
            hit = None
            for probe in reversed(results.get('a_anchor_probe') or []):
                if probe.get('sel'):
                    hit = probe
                    break
            if hit is None:
                results['status'] = 'a_span_probe_missing'
                return _finish(results, out, port, fwd_ok)
            vx0, vy0 = hit['vp']
            start_pt = rb_point(BODY_FIELD, vp_x=vx0, vp_y=vy0)
            if start_pt is None:
                results['status'] = 'a_span_point_missing'
                return _finish(results, out, port, fwd_ok)
            span_fence = log_fence()
            m.uitest('drag', str(start_pt[0]), str(start_pt[1]),
                     str(start_pt[0] + 60), str(start_pt[1]))
            time.sleep(1.2)
            drag_v, drag_hex = m.read_all(port)
            if drag_hex != a_freeze['main_hex'] or drag_v != a_main_v:
                results['status'] = 'prep_drag_changed_owner'
                return _finish(results, out, port, fwd_ok)
            a_span_sel = wait_confirmed_selection(BODY_FIELD, span_fence)
            if a_span_sel is None or not (0 < a_span_sel[0] < a_span_sel[1] < anchor_len16):
                results['status'] = 'a_body_span_unconfirmed'
                results['a_body_span_selection'] = a_span_sel
                return _finish(results, out, port, fwd_ok)
            a_anchor_sel = a_span_sel          # 恢复/替换判据统一锚到冻结跨度
            a_freeze['span_utf16'] = list(a_span_sel)
            results['a_freeze'] = dict(a_freeze)   # 副本随冻结刷新（复核可见跨度）
        results['a_freeze']['anchor_utf16'] = list(a_anchor_sel)

        # ---- 2. 进 B：一次点击切换 + 点击备注（进入 B 是真实用户动作） ----
        ok, evidence = reach_mode(port, 'preview', results, 'enter-b')
        results['toggle_evidence'] = evidence
        if not ok:
            # round10-D3：同 back-a——票据结局具名原样上报，不再一律叫
            # preview_mode_not_reached（那会把「提交被拒」与「面没跟」混成一个）。
            results['status'] = evidence if evidence in (
                'ticket_in_flight', 'in_flight', 'rollback_rejected', 'ticket_rejected',
                'present_failed', 'cancelled', 'reason_unknown', 'stale_token',
                'no_ticket_after_baseline', 'not_after_baseline',
                'other_face_submitted', 'submitted_other_face',
                'driver_face_unobserved', 'driver_face_ambiguous', 'mode_not_at_target',
                'readback_unavailable', 'face_declaration_mismatch') \
                else 'preview_mode_not_reached'
            return _finish(results, out, port, fwd_ok)
        # OWNER_STATE 翻转与 accepted 场景转储（note 节点矩形/视口变换）可能
        # 不同帧到达：按进度有界轮询 note 表面，不立即失败。
        note_point = None
        for _ in range(16):
            note_point = rb_point(NOTE_FIELD)
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
        rect = rb_rect(NOTE_FIELD)
        probe = None
        # 备注常为**单行**（种子 27 字符），行高约 6vp；偏移必须落在首行文字上，
        # 否则点击落到文字下方空白、caret 不动（实测 caret 停在末尾 → 探针耗尽）。
        for vy in (rect[1] + 2, rect[1] + 5, rect[1] + 8, rect[1] + 11, rect[1] + 16):
            for vx in (rect[0] + 8, rect[0] + 24, rect[0] + 48, rect[0] + 90):
                px = rb_point(NOTE_FIELD, vp_x=vx, vp_y=vy)
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
        b_fence = log_fence()
        m.uitest('drag', str(probe[0]), str(probe[1]), str(probe[0] + 60), str(probe[1]))
        time.sleep(1.2)
        # 拖选零事务：B 资源版本不变
        mid_v, _mid_probe = read_public(port, note_rid)
        if mid_v != b_note_v:
            results['status'] = 'drag_changed_note_owner'
            return _finish(results, out, port, fwd_ok)
        # 冻结平台实际安装的选区（terminal=INSTALLED + native rc=0），独立换算期望。
        # 围栏取在本次拖选**之前**：只认本次安装确认，不回退历史。
        b_sel = wait_confirmed_selection(NOTE_FIELD, b_fence)
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
        # A 不变：**版本与完整字节同时**核（round5 后指导 A：只看内容相等会把
        # 「换版又换回同一内容」或「版本没动但字节变了」都放过）。
        a_mid_v, a_mid_hex = m.read_all(port)
        results['a_unchanged_during_b'] = {
            'version_before': a_freeze['main_version'], 'version_after': a_mid_v,
            'version_equal': a_mid_v == a_freeze['main_version'],
            'bytes_equal': a_mid_hex == a_main_hex,
            'bytes_before': len(a_main_hex) // 2, 'bytes_after': len(a_mid_hex) // 2,
            'hex_after': a_mid_hex,
        }

        # ---- 4. 切回 A：只允许本来那次切换动作；框架须自行恢复原锚（禁止补点） ----
        # 免点击交接：检查器不追加正文 click/tap/focus、不重发用户输入、不用新落点
        # 重新定义期望。切回后的安装必须由框架的恢复路径自行完成，且落回离开前
        # 冻结的源锚。围栏取在切换动作**之前**——不得回退到基线以来的旧确认；
        # 围栏淘汰由 fence_index 具名抛出（不退回 0 重扫历史）。
        adopted_before = last_adopted_count()
        return_fence = log_fence()
        ok, ev = reach_mode(port, 'source', results, 'back-a')
        if not ok:
            # round10-D3：票据结局类具名**原样**作为 status——它们是生产侧结论
            # （在途 / 平台 rollback / present 终态失败 / 被取消 / 提交了错面 /
            # 会话换代 / 读回不可用）。只有「观察缺失」类才退回 source_tap_failed。
            _ticket_statuses = (
                # 票据与提交阶段
                'ticket_in_flight', 'in_flight', 'rollback_rejected', 'ticket_rejected',
                'present_failed', 'cancelled', 'reason_unknown',
                # 本次动作关联
                'stale_token', 'stale_epoch', 'accepted_face_not_target',
                'no_ticket_after_baseline', 'not_after_baseline',
                # 面与观察
                'other_face_submitted', 'submitted_other_face', 'driver_face_unobserved',
                'driver_face_ambiguous', 'mode_not_at_target',
                'readback_unavailable', 'evidence_lost', 'evidence_dropped',
                'face_declaration_mismatch', 'face_list_truncated',
                'identity_changed_during_observation',
            )
            results['status'] = (ev if ev in _ticket_statuses else 'source_tap_failed')
            return _finish(results, out, port, fwd_ok)
        main_owner = results.get('main_owner')
        # round13-R2：观察**状态机**——成功/等待/具名终态三态明确。
        # 成功：同身份双读稳定 → 携 sel 返回。等待：身份变化（继续有界观察）、
        # 采纳未到（restore_ack_unadopted）、无证据、请求在途。终态：有界窗口
        # 耗尽 → 保存最后未证实原因具名结束；**不读不存在的 sel、不重投动作**。
        a_restore = None
        last_unproven = None
        m._restore_observe_phase = True   # round13-R2：观察窗口相位（工具注入用）
        for _ in range(40):
            rows = m.hilog_rows()
            decision_snap = public_snapshot(port) or {}
            edit_hint = decision_snap.get('editing')
            a_restore = body_restore_evidence(rows, fence_index(rows, return_fence), body_node,
                                              adopted_before, main_owner, a_mid_v,
                                              identity_hint=edit_hint)
            src_now = (a_restore or {}).get('source')
            if src_now in ('restore_ack', 'mount_snapshot'):
                # 观察期间身份必须稳定：判定 hint 与复核 hint 不一致 → 等待态
                # （继续观察，不 break、不读 sel、不重投用户动作）。
                confirm_snap = public_snapshot(port) or {}
                confirm_hint = confirm_snap.get('editing')
                results['restore_read_seq'] = [
                    decision_snap.get('seq'), confirm_snap.get('seq')]
                m._restore_observe_phase = False
                if confirm_hint != edit_hint:
                    results.setdefault('identity_flaps', []).append(
                        {'at_decision': edit_hint, 'at_confirm': confirm_hint})
                    last_unproven = a_restore = {
                        'source': 'identity_changed_during_observation',
                        'at_decision': edit_hint, 'at_confirm': confirm_hint}
                    m._restore_observe_phase = True
                    time.sleep(0.4)
                    continue
                break
            if src_now is not None and src_now not in (
                    'restore_ack_unadopted', 'identity_changed_during_observation'):
                last_unproven = a_restore
                # 身份缺失类结论在**恢复请求仍在途**时不是终局：按同身份请求号
                # 判序（最大 armed request > 最大 terminated request ⇒ 在途），
                # 不比较整行字符串的字典序。
                if src_now in ('restore_ack_no_current_identity',
                               'mount_snapshot_no_current_identity'):
                    armed_reqs = [int(mo.group(1)) for r in rows
                                  for mo in [re.search(r'proxy restore armed request=(\d+)', r)]
                                  if mo]
                    term_reqs = [int(mo.group(1)) for r in rows
                                 for mo in [re.search(r'proxy restore terminated reason=\S+ request=(\d+)', r)]
                                 if mo]
                    if armed_reqs and (not term_reqs or max(armed_reqs) > max(term_reqs)):
                        time.sleep(0.4)
                        continue        # 在途：等待态，继续观察
                break                    # 其余具名结论：终态，立即结束
            # 等待：无证据 / 采纳未到 / 身份变化——有界继续观察。
            time.sleep(0.4)
        m._restore_observe_phase = False
        if a_restore is not None and \
                a_restore.get('source') == 'identity_changed_during_observation':
            # 有界窗口耗尽且仍处于身份变化等待态：转具名耗尽（保存最后未证实
            # 原因）；无证据/采纳未到沿用各自既具名的终局，不被覆盖。
            a_restore = {'source': 'observe_window_exhausted',
                         'last_unproven': 'identity_changed_during_observation',
                         'detail': last_unproven}
        results['a_restore'] = a_restore
        results['a_restore_adopted_before'] = adopted_before
        if a_restore is None:
            results['status'] = 'a_restore_uninstalled'
            return _finish(results, out, port, fwd_ok)
        if a_restore.get('source') == 'restore_ack_unadopted':
            # 平台已安装但窗口尚未采纳：不算本交接成立（排队/安装 ≠ 采用）。
            results['status'] = 'a_restore_not_adopted'
            return _finish(results, out, port, fwd_ok)
        if a_restore.get('source') in ('observe_window_exhausted',
                                       'identity_changed_during_observation'):
            # round13-R2：有界观察耗尽（含持续身份变化）：保存最后未证实原因，
            # 具名结束——无异常、不读 sel、不借旧证据、不重投动作。
            results['status'] = 'a_restore_observe_unproven'
            return _finish(results, out, port, fwd_ok)
        if a_restore.get('source') in ('restore_ack_identity_mismatch',
                                       'restore_ack_stale_context',
                                       'restore_ack_identity_not_current',
                                       'restore_ack_no_current_identity',
                                       'mount_snapshot_not_current_identity',
                                       'mount_snapshot_no_current_identity'):
            # 有采纳事实但不属于**当前有效身份元组**（旧上下文、换焦后、资源/
            # 绑定/投影/owner 版本任一不符，或当前身份缺失）：具名拒绝，不借
            # 别的目标的计数，也不因 `focus is None` 跳过校验。
            results['status'] = 'a_restore_adoption_identity_mismatch'
            return _finish(results, out, port, fwd_ok)
        if a_restore.get('source', '').startswith('mount_snapshot_') and \
                a_restore.get('source') != 'mount_snapshot':
            # 挂载路径的身份不符/观测缺失：同样不成立，逐项写进结果供复核。
            results['status'] = 'a_restore_mount_identity_mismatch'
            return _finish(results, out, port, fwd_ok)
        a_sel = a_restore['sel']
        restored_to_anchor = (tuple(a_sel) == tuple(a_anchor_sel))
        results['a_restored_to_frozen_anchor'] = restored_to_anchor
        results['a_restore_bind_basis'] = ('node=%s/%s source=%s'
                                           % (body_node, a_restore.get('node'),
                                              a_restore.get('source')))
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
            'anchor_utf16': list(a_anchor_sel),
            'restored_to_anchor': restored_to_anchor,
            'restore_source': a_restore.get('source'),
            'restore_ticket': a_restore.get('ticket'),
            'anchor_doc_len16': anchor_len16,
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
                    'a_resume_removed_is_zero', 'a_resume_at_frozen_anchor',
                    'b_unchanged_during_a', 'b_revisit_preserved']
        flat = {
            'fixture_reset': fixture_ok,
            'b_replace_exactly_once': results['b_replace']['exactly_once'],
            'b_replace_exact_owner': results['b_replace']['exact_owner'],
            'b_install_confirmed': b_sel is not None and b_sel[0] < b_sel[1],
            'a_unchanged_during_b': (results['a_unchanged_during_b']['version_equal']
                                     and results['a_unchanged_during_b']['bytes_equal']),
            'a_resume_exactly_once': results['a_resume']['exactly_once'],
            'a_resume_exact_owner': results['a_resume']['exact_owner'],
            'a_resume_removed_is_zero': results['a_resume']['removed_is_zero'],
            'a_resume_at_frozen_anchor': restored_to_anchor,
            'b_unchanged_during_a': results['b_unchanged_during_a'],
            'b_revisit_preserved': results['b_revisit']['preserved'],
        }
        if span_mode:
            # round12-R3：span 模式的 removed 判据 = 恰好移除冻结跨度（>0）。
            required[required.index('a_resume_removed_is_zero')] = 'a_resume_removed_matches_span'
            flat.pop('a_resume_removed_is_zero', None)
            flat['a_freeze_span_nonempty_mid'] = bool(
                a_freeze.get('span_utf16') and a_freeze['span_utf16'][0] < a_freeze['span_utf16'][1])
            r_ = results['a_resume']
            flat['a_resume_removed_matches_span'] = (
                r_['removed_bytes'] == r_['frozen_span_bytes'][1] - r_['frozen_span_bytes'][0]
                and r_['removed_bytes'] > 0)
        # 错区间替换 / 误删续写都在 exact_owner 里变红；显式再列诊断项。
        if not results['b_replace']['inserted_is_N']:
            flat['b_replace_exact_owner'] = False
        results['required_values'] = flat
        results['status'] = 'OK' if all(flat.values()) else 'FAIL'
        return _finish(results, out, port, fwd_ok)
    except EvidenceLost:
        # 内容围栏已被环形日志淘汰：具名失败，绝不退回 0 重扫历史。
        results['status'] = 'evidence_lost'
        return _finish(results, out, port, fwd_ok)
    except Exception as exc:  # 未预期失败也要落证据并释放转发
        import traceback
        results['status'] = 'driver_exception'
        results['exception'] = repr(exc)
        results['traceback'] = traceback.format_exc()
        return _finish(results, out, port, fwd_ok)


if __name__ == '__main__':
    sys.exit(main())

#!/usr/bin/env python3
"""R3 设备消费（h-source-preview-followup 2026-10-02）：thermo 通过**真实系统
选区安装与输入**证明共享生命周期 + 生成字段通用范围会话桥的复用。

与既有 verify_thermo_continuity.py（按钮＋外部 SET_NOTE 的业务回归，保留）
互补，本脚本按交接验收跑完整链，判据全部来自本轮日志与公开通道读回：
  1 安装     ：真实触摸定位备注 → 共享类 attach/两帧确认 INSTALLED＋rc=0；
  2 输入     ：系统键盘注入 → GET_CONTEXT note 逐字节等于注入文本（插入）；
  3 非空选区 ：拖选 → 共享类确认**非空**选区（冻结为唯一事实）；
  4 精确替换 ：注入 'X' → note == strict_utf16 oracle 按冻结选区独立计算的期望；
  5 外部改版 ：公开通道 SET_NOTE（外部路径）→ note 精确等于外部文本；
  6 继续输入 ：等待改版后的新安装确认（重基后的平台事实）→ 注入 'Y' →
              note == 按新冻结选区独立计算的期望。

round14（2026-10-04 指导复核后收尾）：
  A 两种安装来源（标准 terminal 配对 / 等价链 select 行）只作为不同的安装
    凭据，统一走 _final_adoption_identity_gate 的安装→观测→窗口采纳→当前
    身份单一出口；native 人锚不再是采纳证据。
  B wait_confirmed 在**判定点**归档每轮原回包（GET_CONTEXT 原文/owner 版本/
    读回原文与解析身份）、围栏、匹配事实（挂载键/安装凭据/观测/采纳行号）、
    冻结 owner 基线与判定轮完整日志行；必需归档失败具名终结，不吞异常。
"""
import json
import os
import re
import subprocess
import sys
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import verify_thermo_continuity as tc  # noqa: E402
import strict_utf16  # noqa: E402

# 每轮独立输出目录：默认历史证据路径，但可经环境变量重定向。离线负控/正控
# 必须显式指向临时目录，绝不覆盖真实设备证据（指导复核：旧负控会覆写固定
# thermo-shared.json）。显式传入 output_dir 的行内调用优先于环境变量。
DEFAULT_OUT = '/Users/jiangxuanyang/Desktop/cangjie/artifacts/h-r-final-20261002/thermo-shared'
OUT = Path(os.environ.get('CJGUI_H_THERMO_SHARED_OUT', DEFAULT_OUT))
BUNDLE = tc.BUNDLE_THERMO
HDC = tc.HDC
RESOURCE_ID = 9801
# 本轮实测设备粒度：uitest 文本注入逐字符提交（每个 ASCII 码元一笔 owner
# 事务）。这不是跨 Unicode 通用事务数——非 ASCII/组合输入必须另行冻结粒度，
# 不得以 Python 字符数或 UTF-16 码元数替代真实回调计数。
ASCII_CHAR_TXNS = 1


def thermo_pid():
    out = subprocess.run([HDC, 'shell', f'pidof {BUNDLE}'],
                         capture_output=True, text=True).stdout.strip()
    return out.split()[0] if out else None


# hilog 行格式：MM-DD HH:MM:SS.mmm <PID> <TID> <LEVEL> ...。PID 是第 3 个空白
# 分隔字段；子串匹配会把消息正文里的同款数字当成本进程（指导反例：PID 9999 的
# 无关行被 1234 的子串过滤放行）。无 PID 或行格式异常的行一律不属于本轮。
_HILOG_PID = re.compile(r'^\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d+\s+(\d+)\s+\d+\s')

# 行首时间戳（hilog 行格式固定宽度，字典序即时序）。
_ROW_TS = re.compile(r'^(\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d+)')


def _row_ts(row):
    mo = _ROW_TS.match(row)
    return mo.group(1) if mo else None


def _fence_marker(rows):
    """round15-B：动作前围栏的**可核对排他游标**。

    优先记录末行原文（`row`）+ 时间戳（`ts`）+ 原快照行号（`index`）：新快照里
    该原文行**唯一出现**处即排他边界（其后才算新证据，同毫秒后行因位置可证而
    保留）；原文行缺失（轮转）→ 回退 ts 排他边界（ts 严格大于，整个同毫秒窗
    口视为不可证明而排除）；完全无时间戳行 → {'index': len(rows)}（仅 0 有
    "空快照无历史"语义，非 0 由 resolver 具名未证实）。"""
    for i in range(len(rows) - 1, -1, -1):
        ts = _row_ts(rows[i])
        if ts is not None:
            return {'ts': ts, 'index': i, 'row': rows[i]}
    return {'index': len(rows)}


def _resolve_fence(rows, fence):
    """把围栏解析成**当前快照**的行号；无法证明边界时返回 None（具名未证实，
    调用方不得回退 0 重开历史）。

    * int：原样（兼容既有用例；0 = 显式初始安装围栏，保留启动用途）。
    * {'ts','row'}：原围栏行在新快照中唯一出现 → 该位置**之后**（排他，位置
      可证）；多处出现 → None（同文歧义）；零出现（轮转）→ 回退 ts 排他：
      第一条 ts 严格大于锚的行，没有则 len(rows)。
    * 仅 {'ts'}：同毫秒先后无法证明 → 整个同毫秒窗口排除，取第一条 ts 严格
      大于锚的行；没有则 len(rows)。
    * 仅 {'index'}：0 = 空快照标记 → 0；非 0 行号跨快照不稳定 → None。
    * 其它/未知形状 → None。"""
    if fence is None:
        return 0
    if isinstance(fence, int):
        return max(0, min(fence, len(rows)))
    if isinstance(fence, dict) and 'ts' in fence:
        ts0 = fence['ts']
        row_anchor = fence.get('row')
        if row_anchor is not None:
            hits = [i for i, r in enumerate(rows) if r == row_anchor]
            if len(hits) == 1:
                return hits[0] + 1          # 排他：围栏行本身与其之前不算新证据
            if len(hits) > 1:
                return None                 # 同文歧义：边界无法证明
            # 原文行已轮转：回退 ts 排他边界（ts 关联仍在）。
        for i, r in enumerate(rows):
            ts = _row_ts(r)
            if ts is not None and ts > ts0:
                return i                    # 排他：同毫秒窗口整段排除
        return len(rows)
    if isinstance(fence, dict) and set(fence) == {'index'}:
        return 0 if fence['index'] == 0 else None
    return None


def rows_for(pid):
    if not pid:
        return []
    rows = tc._m.hilog_rows()
    return [r for r in rows
            if (mo := _HILOG_PID.match(r)) is not None and mo.group(1) == pid]


# round14-A：挂载键 = CjguiProxyKey.describe() 的精确形状
# （runtime/cjgui/platforms/ohos/arkts/cjgui-text-proxy.ets）：
#   app<appInstance>/s<sessionToken>/c<contextId>/e<editGeneration>/m<mountGeneration>
# contextId 即观测/读回的 ctx，editGeneration 即读回 gen。不符合该形状的 key
# 一律不构成挂载身份（指导反例：mount ctx99 与观测/当前 ctx3 不符曾被接受）。
_PROXY_KEY_RE = re.compile(r'^app(-?\d+)/s(-?\d+)/c(-?\d+)/e(-?\d+)/m(-?\d+)$')

_OBS_RE = re.compile(
    r'ime selection observation forwarded ctx=(-?\d+) sel=(\d+):(\d+) '
    r'node=(\d+) resource=(-?\d+) kind=(\d+) binding=(\d+) v=(\d+)')

_ADOPTED_RE = re.compile(
    r'CJGUI_OWNED_SELECTION_ADOPTED2 node=(-?\d+) resource=(-?\d+) kind=(\d+) '
    r'sel=(\d+):(\d+) projection=(-?\d+) binding=(\d+)'
    r'(?: owner_version=(-?\d+))?(?: source_ctx=(\S+) source_gen=(\S+))?')


def _final_adoption_identity_gate(rows, fence, key, field, install,
                                  readback_identity, owner_baseline,
                                  facts=None):
    """round14-A：**归一后的唯一最终守卫**——两种平台安装凭据（标准 terminal
    配对 / 等价链 `ime select rc=0`）只作为不同的安装凭据进入本门，此后共用
    同一套判据、同一个出口。不加宽松 OR 支路。

    逐字段契约（任何冲突/缺项即 None，不用当前值回填旧事件来源）：
      ① 挂载身份：key 必须符合 CjguiProxyKey.describe()；其 contextId 必须
         等于读回 ctx，editGeneration 必须等于读回 gen。
      ② 权威当前身份：读回 edit=live 完整元组（含 gen/field），field 与期望
         一致。缺读回/none/malformed 一律不成立。
      ③ 同挂载完整身份观测：`ime selection observation forwarded ctx=C
         sel=a:b node=N resource=R kind=K binding=B v=V`——sel 必须等于安装
         凭据目标选区，ctx 必须等于挂载 ctx；旧挂载/其它选区的观测不参与配对。
      ④ 窗口采纳：ADOPTED2 node/resource/kind/sel/projection/binding/
         owner_version/source_ctx/source_gen **全部在**且与观测逐字段相等
         （v==projection、source_ctx==ctx）；source_gen 必须是数字且等于读回
         gen（unverified/999 拒绝）；owner_version 必须等于本腿冻结基线
         （-1/999/仅存在不充分；基线来自调用方在该腿动作前冻结的公开 owner
         读回，不从待验证 ADOPTED2 反推）。
      ⑤ 有序流：观测 ≤ 采纳（流内配对；App 侧 select/terminal 与 native 观测
         的先后不当作跨线程语义顺序，不作判据）。
      ⑥ `human anchor recorded` 只是 native 冻结待消费锚，**不是窗口采纳**：
         本门不设人锚分支（round14 撤回，设备原件第 19601 行人锚后第 20073 行
         才有真正 ADOPTED2）。
    `v` 是投影版本（每次 accepted 发布推进），当前读回 v 允许比安装时新，
    不参与比较（不恢复"当前 v 必须等于安装 v"的旧误拒）。
    """
    if not install or install.get('sel') is None:
        return None
    sel_target = tuple(install['sel'])
    mo = _PROXY_KEY_RE.match(key or '')
    if mo is None:
        return None                                   # ① 挂载键形状不符
    key_ctx = int(mo.group(3))
    key_gen = int(mo.group(4))
    # ② 权威当前身份。
    if not readback_identity or not readback_identity.get('live'):
        return None
    if (key_ctx != readback_identity.get('ctx')
            or key_gen != readback_identity.get('gen')
            or readback_identity.get('field') != field):
        return None
    # 冻结 owner 基线：必须由调用方提供（该腿实际公开 owner 读回或既有冻结
    # 请求），缺失/非法即不判——不存在"无基线放行"的路径。
    if (not isinstance(owner_baseline, int) or isinstance(owner_baseline, bool)
            or owner_baseline < 0):
        return None
    span = rows[fence:]
    obs = None
    obs_idx = None
    obs_ctx_rows = 0
    verdict = None
    for i, r in enumerate(span):
        mo = _OBS_RE.search(r)
        if mo:
            if int(mo.group(1)) == key_ctx:
                # 任何 sel 的本挂载观测行都计数：观测行一旦在场（无论取值/
                # 位置），采纳补位即被阻断，伪造流只能落回严格路径。
                obs_ctx_rows += 1
                if (int(mo.group(2)), int(mo.group(3))) == sel_target:
                    # ctx 与挂载不符的观测是旧挂载迟到证据，不参与配对。
                    obs = {'ctx': int(mo.group(1)), 'sel': sel_target,
                           'node': int(mo.group(4)), 'resource': int(mo.group(5)),
                           'kind': int(mo.group(6)), 'binding': int(mo.group(7)),
                           'v': int(mo.group(8))}
                    obs_idx = i
            continue
        mo = _ADOPTED_RE.search(r)
        if not mo or obs is None:
            continue
        try:
            adopted = {'node': int(mo.group(1)), 'resource': int(mo.group(2)),
                       'kind': int(mo.group(3)),
                       'sel': (int(mo.group(4)), int(mo.group(5))),
                       'projection': int(mo.group(6)),
                       'binding': int(mo.group(7)),
                       'owner_version': int(mo.group(8)),
                       'source_ctx': int(mo.group(9)),
                       'source_gen': int(mo.group(10))}
        except (TypeError, ValueError):
            continue          # owner_version/来源缺项或 unverified：不作证据
        if (adopted['sel'] != obs['sel'] or adopted['node'] != obs['node']
                or adopted['resource'] != obs['resource']
                or adopted['kind'] != obs['kind']
                or adopted['projection'] != obs['v']
                or adopted['binding'] != obs['binding']
                or adopted['source_ctx'] != obs['ctx']):
            continue
        if adopted['source_gen'] != readback_identity.get('gen'):
            continue          # ④ 冻结来源代次必须等于当前读回 gen
        if adopted['owner_version'] != owner_baseline:
            continue          # ④ owner 版本必须对应本腿冻结基线
        for k in ('node', 'resource', 'kind', 'binding'):
            if obs[k] != readback_identity.get(k):
                break
        else:
            # ⑤ 观测 ≤ 采纳由流内顺序保证（obs 只取本 ADOPTED2 之前的行）。
            verdict = {'sel': obs['sel'], 'mount_key': key,
                       'install': dict(install), 'observation': dict(obs),
                       'observation_source': 'obs_row',
                       'obs_rows_in_span': obs_ctx_rows,
                       'obs_row_idx': fence + obs_idx, 'adopted': adopted,
                       'adopted_row_idx': fence + i,
                       'owner_baseline': owner_baseline}
    if verdict is None and obs_ctx_rows == 0:
        # 采纳补位（round14-B 设备复跑 leg6 实测形态；Pi→精确 GLM5.3 独立
        # 只读咨询裁决 artifacts/consultations/h-round14-leg6-obs-20261004/）：
        # 严格路径不成立**且** span 内不存在任何本挂载观测行时——生产侧
        # kind-33 唯一生产者必然伴打观测行（ohos_renderer.cpp 10857-10869
        # 无条件 RLOGI），ADOPTED2(source_ctx) 存在即证明该行曾被打印；本
        # 复跑实测该行被 hilog 流控整组丢弃（同窗口 LOGLIMIT 5654 行标记）。
        # 此时 attach_confirmed 终态对（平台对实际选区的确认读，rc=0）作为
        # 平台观测事实补位。缺一不可：
        #   ① 安装凭据来自 terminal 配对且 reason==attach_confirmed；
        #   ② ADOPTED2 全字段数字解析（unverified/缺项照旧拒绝）且 sel==安装
        #      凭据选区、source_ctx==挂载 ctx、source_gen==读回 gen、
        #      owner_version==冻结基线、node/resource/kind/binding==读回身份；
        #   ③ 采纳行序 ≤ 确认行序（attach 语义下结构性强制：采纳消费挂载回声
        #      转发的 kind-33，确认行等 attach 完成后才打印）。
        # 观测行在场（任意 sel/位置）即不启用补位——RED「观测选区不符」与
        # 「先采纳后观测」的形状全部落回严格路径拒绝。
        if (isinstance(install, dict) and install.get('kind') == 'terminal'
                and install.get('reason') == 'attach_confirmed'
                and install.get('confirmed_idx') is not None):
            for i, r in enumerate(span):
                mo = _ADOPTED_RE.search(r)
                if not mo:
                    continue
                try:
                    adopted = {'node': int(mo.group(1)),
                               'resource': int(mo.group(2)),
                               'kind': int(mo.group(3)),
                               'sel': (int(mo.group(4)), int(mo.group(5))),
                               'projection': int(mo.group(6)),
                               'binding': int(mo.group(7)),
                               'owner_version': int(mo.group(8)),
                               'source_ctx': int(mo.group(9)),
                               'source_gen': int(mo.group(10))}
                except (TypeError, ValueError):
                    continue
                if (adopted['sel'] != sel_target
                        or adopted['source_ctx'] != key_ctx
                        or adopted['source_gen'] != readback_identity.get('gen')
                        or adopted['owner_version'] != owner_baseline):
                    continue
                if (adopted['node'] != readback_identity.get('node')
                        or adopted['resource'] != readback_identity.get('resource')
                        or adopted['kind'] != readback_identity.get('kind')
                        or adopted['binding'] != readback_identity.get('binding')):
                    continue
                if fence + i > install['confirmed_idx']:
                    continue      # ③ 采纳必须不晚于平台确认行
                verdict = {'sel': sel_target, 'mount_key': key,
                           'install': dict(install), 'observation': None,
                           'observation_source': 'attach_confirmed',
                           'obs_rows_in_span': 0,
                           'adopted': adopted, 'adopted_row_idx': fence + i,
                           'confirmed_idx': install['confirmed_idx'],
                           'owner_baseline': owner_baseline}
                break
    if verdict is None:
        return None
    if facts is not None:
        facts.update(verdict)
    return verdict['sel']


def confirmed_selection(rows, fence=0, expect=None, facts=None):
    """**围栏之后**按**选择轮次**折叠本挂载证据，只认最后一轮的完整链。

    round16-A：同一挂载内的有序证据（观测 / `ime select` / terminal 配对 /
    ADOPTED2）按序折叠为**选择轮次**——sel 变化（含回到历史坐标的 ABA）即开
    新轮次，旧轮次退出当前状态；`sel` 相同只是同一轮次的延续，**不是**跨历史
    去重或复活的依据。每轮收集自己的安装凭据（等价 select 或标准 terminal
    配对，二者只是同一轮次的安装凭据来源）、观测与采纳；逐轮送入同一个
    `_final_adoption_identity_gate`（唯一最终守卫，证据窗口限于本轮起点到下
    一轮起点——不能扫整段围栏历史为新轮次借旧采纳）。

    判定：**只认最后一轮**。最后一轮过完整门 → 返回该 sel，facts 的行号属于
    该轮；最后一轮未采纳/来源冲突/证据不全 → None（等待或具名未证实），旧
    完整轮次不复活。无关挂载噪声（ctx 不符）不参与折叠。同轮重复凭据（相同
    sel 的重复行）属同一轮次，不另开轮次。

    expect 必填：{'field': str, 'mount': str|None, 'owner_version': int,
    'readback_identity': dict}。缺身份或缺 owner 基线即具名拒绝（返回 None
    并抛 KeyError 由调用方判定）。

    配对两行都必须在围栏之后：动作围栏在触发动作**之前**取；围栏前只允许取
    mount 身份。围栏解析无法证明边界（round15-B）时同样具名未证实。"""
    if not expect or not expect.get('field'):
        raise ValueError('confirmed_selection requires expect[field] identity')
    field = expect['field']
    # 挂载行是**身份发现**（外部改版会换新挂载）：只认该 field 的最后一次挂载。
    key = None
    for r in rows:
        mo = re.search(r'proxy mounted key=(\S+) field=(\S+)', r)
        if mo and mo.group(2) == field:
            key = mo.group(1)
    if key is None:
        return None
    if expect.get('mount') is not None and expect['mount'] != key:
        return None
    # 围栏解析成**当前快照**的行号（round15-B：排他边界）；无法证明边界 →
    # 具名未证实，不回退 0 重开历史。
    fence = _resolve_fence(rows, fence)
    if fence is None:
        return None
    mo_key = _PROXY_KEY_RE.match(key or '')
    if mo_key is None:
        return None
    key_ctx = int(mo_key.group(3))

    # ---- round18-A：按有序证据折叠**选择轮次**——OBS/select/confirmed/
    # terminal 四个分支**实际共用同一个迁移入口** `_transition(sel, idx)`：
    # sel 变化即开新轮次（统一退役异 sel 的 pending 采纳与 last_confirmed，
    # 回旧坐标不复活）；同 sel 延续当前轮。confirmed 先迁移/延续轮次，**再**
    # 保存自身供本轮 terminal 一次配对（不丢弃新值）。terminal 只消费本轮
    # 一次有效配对；未配对仅记录状态，不遮蔽轮内合法 select；重复回执保留
    # 已成立凭据。pending 采纳（ADOPTED2 先于 app 侧行到达的跨线程顺序）
    # 在同 sel 新轮次开始时归入且窗口起点前移到采纳行；异 sel 状态即退役。
    # 无关挂载噪声（mount/ctx/field 不符）不进入迁移。
    span = rows[fence:]
    rounds = []          # 每轮：{start, sel, select, terminal, adopted, adopted_idx}
    state = {'cur': None, 'pending': None, 'confirmed': None}

    def _transition(sel, idx):
        """统一轮次迁移：sel 变化开新轮次并退役异 sel 的 pending/confirmed；
        同 sel 延续。返回（可能是新的）当前轮 dict。"""
        cur = state['cur']
        if cur is None or cur['sel'] != sel:
            if state['pending'] and state['pending'][0]['sel'] != sel:
                state['pending'] = None       # 异 sel：pending 退役
            if state['confirmed'] and state['confirmed'][0] != sel:
                state['confirmed'] = None    # 异 sel：confirmed 退役
            cur = {'start': idx, 'sel': sel, 'select': None, 'terminal': None,
                   'adopted': None, 'adopted_idx': None, 'confirmed_idx': None,
                   'obs': False}
            rounds.append(cur)
            if state['pending']:
                cur['adopted'] = state['pending'][0]
                cur['adopted_idx'] = state['pending'][1]
                cur['start'] = state['pending'][1]   # 窗口起点前移到采纳行
                state['pending'] = None
        state['cur'] = cur
        return cur

    for i, r in enumerate(span):
        abs_i = fence + i
        mo = _OBS_RE.search(r)
        if mo and int(mo.group(1)) == key_ctx:
            cur = _transition((int(mo.group(2)), int(mo.group(3))), abs_i)
            cur['obs'] = True
            continue
        mo = re.search(r'ime select \[(\d+),(\d+)\) rc=0 mount=(\S+)', r)
        if mo and mo.group(3) == key:
            sel_sel = (int(mo.group(1)), int(mo.group(2)))
            cur = _transition(sel_sel, abs_i)
            cur['select'] = {'kind': 'select', 'sel': sel_sel,
                             'idx': abs_i, 'row': r}
            continue
        mo = re.search(r'ime proxy selection terminal=INSTALLED reason=(\S+) '
                       r'target=\[(\d+),(\d+)\) mount=(\S+) field=(\S+)', r)
        if mo and mo.group(4) == key and mo.group(5) == field:
            sel_t = (int(mo.group(2)), int(mo.group(3)))
            cur = _transition(sel_t, abs_i)
            # round18-B：terminal 与**本轮尚未消费**的 confirmed（同挂载/
            # field/sel）配对后才是安装凭据；配对一次即消费。未配对仅记录
            # 状态，不提供安装资格、不遮蔽轮内合法 select；重复回执不新造
            # 凭据、不抹掉已成立凭据。
            if (state['confirmed'] and state['confirmed'][0] == sel_t
                    and cur['terminal'] is None):
                cur['terminal'] = {'kind': 'terminal', 'sel': sel_t,
                                   'idx': abs_i, 'row': r, 'reason': mo.group(1),
                                   'confirmed_idx': state['confirmed'][1]}
                state['confirmed'] = None          # 配对即消费
            else:
                cur['terminal_unpaired'] = True
            continue
        mo = re.search(r'ime selection confirmed \[(\d+),(\d+)\) rc=0 '
                       r'\(shared lifecycle\) mount=(\S+) field=(\S+)', r)
        if mo:
            if mo.group(3) != key or mo.group(4) != field:
                continue                  # 异挂载/异 field 噪声：不进入迁移
            sel_c = (int(mo.group(1)), int(mo.group(2)))
            # round18：confirmed **先**推进/延续轮次（含退役异 sel 的 pending/
            # 旧 confirmed），**再**保存自身——供本轮 terminal 一次配对。
            _transition(sel_c, abs_i)
            state['confirmed'] = (sel_c, abs_i)
            continue
        mo = _ADOPTED_RE.search(r)
        if mo:
            try:
                adopted = {'node': int(mo.group(1)), 'resource': int(mo.group(2)),
                           'kind': int(mo.group(3)),
                           'sel': (int(mo.group(4)), int(mo.group(5))),
                           'projection': int(mo.group(6)),
                           'binding': int(mo.group(7)),
                           'owner_version': int(mo.group(8)),
                           'source_ctx': int(mo.group(9)),
                           'source_gen': int(mo.group(10))}
            except (TypeError, ValueError):
                continue          # owner_version/来源缺项或 unverified：不作证据
            cur = state['cur']
            if cur is not None and adopted['sel'] == cur['sel']:
                cur['adopted'] = adopted
                cur['adopted_idx'] = abs_i
                state['pending'] = None
            elif cur is not None:
                # round18：当前已有活动轮而采纳 sel 不符 ⇒ 该采纳属于已被
                # 取代/不可观测的选择状态（合法顺序下 obs 先于采纳到达并已
                # 切轮；无 obs 的异 sel 采纳正是矛盾形状）——丢弃，不得挂
                # pending 借给后续回到该坐标的新轮次（round14 冻结 RED：
                # 「观测是另一选区」不得经补位复活）。
                pass
            elif (state['pending'] is None
                  or state['pending'][0]['sel'] != adopted['sel']):
                state['pending'] = (adopted, abs_i)
            continue
    if not rounds:
        return None
    # ---- round16-A：只评估**最后一轮**——证据窗口限于本轮起点到快照末尾
    # （不能借旧轮次采纳）。最后一轮过完整门 ⇒ 返回该轮 sel 与该轮事实；
    # 最后一轮未采纳/来源冲突/证据不全 ⇒ 旧完整轮次不复活，返回 None
    # （等待/具名未证实）。较旧轮次无论过门与否都不参与判定。
    rd = rounds[-1]
    # round16-A：安装凭据——轮内有 terminal 配对（平台回执）优先；否则用等价
    # select。缺两者 → 本轮不成立（守卫的补位/严格分支自行判定）。
    install = rd['terminal'] or rd['select']
    if install is None:
        return None               # 只有观测、无安装凭据的轮次：本轮不成立
    rd_facts = {}
    got = _final_adoption_identity_gate(rows, rd['start'], key, field, install,
                                        expect.get('readback_identity'),
                                        expect.get('owner_version'),
                                        facts=rd_facts)
    verdict = got
    verdict_facts = rd_facts
    if verdict is None:
        return None
    if facts is not None and verdict_facts is not None:
        facts.update(verdict_facts)
    return verdict
class ArchiveRequiredError(RuntimeError):
    """round14-B：必需归档写入失败——具名终结，不允许业务照常宣布验收 OK。"""


def _readback_full():
    """单次 GET_CONTEXT：同一响应里的 VERSION、note 字节与 OWNER_STATE 原文
    一起取回（round14-B：判定使用的身份/版本/字节同源，不事后补读）。"""
    _, resp = tc.business(["GET_CONTEXT 0"])
    if not isinstance(resp, str):
        return None
    version, _fields = tc.fields_of(resp)
    state = None
    mo = re.search(r"OWNER_STATE_UTF8_HEX (\d+) ([0-9a-fA-F]*)", resp)
    if mo:
        state = bytes.fromhex(mo.group(2)).decode('utf-8', 'replace')
    return {'raw': resp, 'version': version, 'state': state}


def _archive_leg_judgment(archive, leg, fence, expect, judgments, rows, sel):
    """round14-B：把**判定真正使用的原件**落盘——每轮公开原回包（请求原文、
    owner 版本、读回原文与解析身份）、动作前围栏、匹配的安装/观测/采纳事实
    与行号、冻结 owner 基线，以及判定轮使用的完整有序日志行。必需归档写入
    失败 → ArchiveRequiredError（调用方具名终结，不吞异常继续宣布 OK）。"""
    d = Path(archive['dir'])
    try:
        d.mkdir(parents=True, exist_ok=True)
        payload = {'leg': leg, 'fence': fence,
                   'expect_field': expect.get('field'),
                   'expect_owner_version': expect.get('owner_version'),
                   'verdict': list(sel) if sel is not None else None,
                   'judgments': judgments}
        jf = d / f'{leg}-judgment.json'
        rf = d / f'{leg}-judgment-rows.txt'
        jf.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + '\n')
        rf.write_text('\n'.join(rows) + '\n')
    except OSError as exc:
        raise ArchiveRequiredError(
            f'archive_write_failed leg={leg} dir={d}: {exc}') from exc
    archive.setdefault('required', []).extend([str(jf), str(rf)])


# 腿 no-op 时的归因必须来自**围栏之后**的具名宿主拒绝原行，不靠人事后再从整份
# hilog 里挑（本轮反例：输入腿逐字符采纳 `sel=1:1 ov=1`/`sel=2:2 ov=2` 被误读成
# 拖选产物）。前缀是宿主 RLOGW 的稳定字面量；围栏解析不了时具名
# `refusal_fence_unresolved`，绝不回退 0 重开历史。
_HOST_REFUSAL_PREFIXES = ('caret hit refused:', 'presentation hit refused:',
                          'proxy restore ticket rejected:', 'layout_not_retained',
                          'layout_budget_exceeded', 'transient_peak_over_budget')


def named_refusals(rows, fence, limit=6):
    start = _resolve_fence(rows, fence)
    if start is None:
        return ['refusal_fence_unresolved']
    hits = [r for r in rows[start:] if any(p in r for p in _HOST_REFUSAL_PREFIXES)]
    return hits[:limit] if hits else ['no_named_refusal_after_fence']


def wait_confirmed(pid, fence, non_empty, expect, rounds=24, archive=None,
                   leg='leg'):
    """有界轮询 fence 之后**新出现**的、身份匹配的确认配对（配对本身限于
    围栏之后，见 confirmed_selection）。fence 必须在触发动作之前取。返回
    (选区或None, 行)。

    round14-B：每轮判定使用**同一次** GET_CONTEXT 响应（原文/owner 版本/
    OWNER_STATE 原文/解析身份同源）与本轮日志行；禁止用最后一次读回补早前
    身份。`archive` 给定时，在判定点（成功或终结轮）把每轮原回包、围栏、
    匹配事实（挂载键/安装凭据/观测/采纳行号）、冻结 owner 基线和判定轮完整
    日志行落盘；必需归档失败具名终结。expect 需含该腿动作前冻结的
    'owner_version' 基线（统一最终守卫要求）。"""
    judgments = []
    seq = 0
    sel = None
    final_rows = []

    def _judge_round(k, rows):
        nonlocal seq
        e = dict(expect)
        rb = None
        try:
            rb = _readback_full()
        except Exception as exc:  # noqa: BLE001 —— 读取失败按本轮不可用处理
            rb = {'raw': None, 'version': None, 'state': None,
                  'error': repr(exc)}
        # round15-C：_readback_full 返回 None（合法失败出口）与其他不可用形状
        # 统一归一——本轮不可用，判定照走（无身份 → 不成立），归档记 error。
        if rb is None:
            rb = {'raw': None, 'version': None, 'state': None,
                  'error': 'readback_none'}
        round_reason = None
        ident = None
        if rb.get('state'):
            try:
                ident = tc._m.parse_edit_section(rb['state'])
            except Exception as exc:  # noqa: BLE001 —— 畸形 state 按不可用
                ident = None
                rb['error'] = f'readback_malformed: {exc!r}'
        if ident:
            e['readback_identity'] = ident
        else:
            round_reason = rb.get('error') or 'readback_unavailable'
        # round15/16-C：当次公开 owner 版本必须**存在且等于**本腿冻结基线。
        # VERSION 缺失/非法（round16-B 反例：真实归档回包只删 VERSION 行经
        # parse_response→fields_of 得 None）与已推进（正文变化）一律具名不可
        # 通过，不借 expect 旧值、不自动更新基线；projection v（readback 身份
        # 内）不是 owner 版本，推进不受此限。
        cur_version = rb.get('version')
        base_version = expect.get('owner_version')
        if isinstance(base_version, int) and not isinstance(base_version, bool):
            cur_valid = (isinstance(cur_version, int)
                         and not isinstance(cur_version, bool))
            if not cur_valid:
                round_reason = 'owner_version_missing'
            elif cur_version != base_version:
                round_reason = 'owner_version_advanced'
        if round_reason is not None:
            e.pop('readback_identity', None)
        seq += 1
        facts = {}
        got = confirmed_selection(rows, fence, e, facts=facts)
        judgments.append({
            'round': k, 'read_seq': seq, 'fence': fence,
            'readback': {'raw': rb.get('raw'), 'version': rb.get('version'),
                         'state': rb.get('state'), 'identity': ident,
                         'error': rb.get('error')},
            'round_reason': round_reason,
            'verdict': list(got) if got is not None else None,
            'facts': facts})
        return got, rows

    for k in range(rounds):
        rows = rows_for(pid)
        sel, final_rows = _judge_round(k, rows)
        if sel is not None and (not non_empty or sel[0] < sel[1]):
            break
        time.sleep(0.5)
    if sel is None or (non_empty and sel[0] >= sel[1]):
        # 终结轮：额外一次完整读取 + 判定（与既有语义一致），无论结果如何
        # 都按终结判定归档。
        rows = rows_for(pid)
        sel, final_rows = _judge_round(rounds, rows)
    if sel is None or (non_empty and sel[0] >= sel[1]):
        # 未成立腿：把围栏之后的具名宿主拒绝原行钉进最后一轮判定，使 no-op 的
        # 归因留在证据内（成功腿不附加，既有归档形状不变）。
        judgments[-1]['host_refusals'] = named_refusals(final_rows, fence)
    if archive is not None:
        _archive_leg_judgment(archive, leg, fence, expect, judgments,
                              final_rows, sel)
    return sel, final_rows


def wait_note_exact(expected_bytes, version_before, rounds=16):
    """有界轮询 owner 读回逐字节等于期望（期望与版本基线均在动作前冻结）。

    返回 (note或None, fields)：note 命中期望时 fields['_version'] 是同一观察的
    版本，供恰好一笔核对；未命中返回 None。"""
    last = None
    for _ in range(rounds):
        note, fields = read_note()
        last = fields
        if note is not None and note.encode('utf-8') == expected_bytes:
            return note, fields
        time.sleep(0.4)
    note, fields = read_note()
    if note is not None and note.encode('utf-8') == expected_bytes:
        return note, fields
    return None, fields


def read_note():
    """同一次 GET_CONTEXT 观察：版本与完整字段一起返回（版本账目与字节同源）。"""
    version, fields = tc.read_state()
    return fields.get('note', None), {'note': fields.get('note', None), '_version': version}


def set_note_external(text):
    version, _ = tc.read_state()
    return tc.invoke('SET_NOTE', version, [('text', 'STRING', text)])


def main(output_dir=None) -> int:
    out = Path(output_dir) if output_dir else OUT
    out.mkdir(parents=True, exist_ok=True)
    results = {'legs': [], 'transactions': []}
    # round14-B：判定点归档槽（必需归档清单由 _archive_leg_judgment 回填）。
    archive_sink = {'dir': out, 'required': []}
    pid = thermo_pid()
    results['identity'] = {'bundle': BUNDLE, 'pid': pid,
                           # round14-C：round13 已核哈希 normal HAP 原样复用，本轮不重建。
                           'hap': 'f1ae83d2 (reused, hash verified in round13)'}
    if not pid:
        results['status'] = 'no_instance'
        (out / 'thermo-shared.json').write_text(json.dumps(results, ensure_ascii=False, indent=2))
        return 2

    # 转发归属：创建确认成功才取得清理权；创建失败**不继续**借固定端点写应用
    # （可能是他方映射/归属不明）。创建失败 → 具名拒绝，不执行任何应用动作。
    fwd_created = False
    fwd = subprocess.run([HDC, 'fport', 'tcp:17857', 'tcp:7857'], capture_output=True, text=True)
    if fwd.returncode == 0 and 'OK' in (fwd.stdout or ''):
        listing = subprocess.run([HDC, 'fport', 'ls'], capture_output=True, text=True).stdout or ''
        if re.search(r'tcp:17857\s+tcp:7857', listing):
            fwd_created = True
    results['forward_created'] = fwd_created
    if not fwd_created:
        results['status'] = 'forward_unavailable'
        (out / 'thermo-shared.json').write_text(json.dumps(results, ensure_ascii=False, indent=2))
        return 3
    try:
        def expect_exactly_once(tag, version_before, action, expected_bytes,
                                expected_txns):
            """动作前冻结版本与完整字节；动作后核 owner 逐字节等于期望，且版本
            增量恰好等于**声明的**事务数 expected_txns。事务数由调用方按真实
            回调/owner粒度显式冻结，不在此处用 len(text)/UTF-16 长度推断。
            任何失配具名失败并带完整账目。"""
            action()
            results['transactions'].append({'leg': tag,
                                            'version_before': version_before})
            note, fields = wait_note_exact(expected_bytes, version_before)
            entry = {'leg': tag, 'version_before': version_before,
                     'expected': expected_bytes.decode('utf-8', 'replace'), 'note': note}
            if note is None:
                entry['fail'] = 'owner_never_matched'
                results['legs'].append(entry)
                return None, entry
            version_after = fields.get('_version')
            entry['version_after'] = version_after
            entry['version_delta'] = version_after - version_before
            entry['expected_txns'] = expected_txns
            entry['exactly_once'] = (version_after - version_before == expected_txns)
            results['legs'].append(entry)
            if not entry['exactly_once']:
                entry['fail'] = 'version_delta_mismatch'
            return note, entry

        # ---- 1 安装：真实触摸定位滚动备注 ----
        # 手写备注编辑器与生成编辑器是两个绑定/挂载，确认链必须按期望 field
        # 绑定，不能只凭坐标相等（同坐标跨 mount 拼接反例）。
        NOTE_FIELD = 'hand-scroll-note'
        # 生成编辑器的 IME field 由宿主编排：editingFieldName = node.semanticId
        # （ohos_renderer.cpp 两处赋值），生成管线的 semantic 是自动编号
        # （如 component-2-1），**不是**候选声明的 `field=note` 属性——该属性是
        # 共享操作字段绑定，不参与 IME 挂载标识。确认链因此在发现生成节点后
        # 以 gen_semantic 期望，不臆断声明值。
        version0, _fields0 = tc.read_state()
        results['baseline_version'] = version0
        p = tc.readback_semantic_point('thermo-focus-note-nav')
        if p is not None:
            tc.inject_tap(p[0], p[1])
        results['legs'].append({'leg': 'focus-nav', 'point': p})
        if p is None:
            results['status'] = 'note_nav_not_reachable'
            return 1
        time.sleep(2.0)
        # round14-A：安装腿 owner 基线 = 启动后冻结的 version0（attach 安装
        # ADOPTED2 owner_version 必须与之相等）。
        sel, rows = wait_confirmed(pid, 0, non_empty=False,
                                   expect={'field': NOTE_FIELD,
                                           'owner_version': version0},
                                   archive=archive_sink, leg='1-install')
        results['install'] = {'confirmed': sel is not None, 'selection': sel}
        if sel is None:
            results['status'] = 'shared_install_unconfirmed'
            return 1

        # ---- 2 输入（插入）----
        version1, _f1 = tc.read_state()
        seed = 'thermo shared lifecycle ok'
        note, entry = expect_exactly_once(
            'input-insert', version1, lambda: tc._m.uitest('text', seed),
            seed.encode('utf-8'), expected_txns=ASCII_CHAR_TXNS * len(seed))
        if note is None or entry.get('fail'):
            results['status'] = entry.get('fail', 'input_not_read_back') if entry else 'input_not_read_back'
            return 1

        # ---- 3 非空选区安装：拖选 → 共享类确认非空选区 ----
        note_point = tc.readback_semantic_point('hand-scroll-note')
        if note_point is None:
            results['status'] = 'note_point_missing'
            return 1
        cx, cy = int(note_point[0]), int(note_point[1])
        # round14-A：拖选腿 owner 基线在动作前冻结（拖选不产生 owner 事务，
        # 采纳 ADOPTED2 owner_version 必须等于该基线）。
        version_s2, _fs2 = tc.read_state()
        fence2 = _fence_marker(rows_for(pid))
        tc._m.uitest('click', str(cx + 60), str(cy))
        time.sleep(0.8)
        tc._m.uitest('drag', str(cx + 40), str(cy), str(cx + 130), str(cy))
        sel2, rows = wait_confirmed(pid, fence2, non_empty=True,
                                    expect={'field': NOTE_FIELD,
                                            'owner_version': version_s2},
                                    archive=archive_sink, leg='3-nonempty-select')
        results['legs'].append({'leg': 'nonempty-select', 'selection': sel2})
        if sel2 is None or sel2[0] >= sel2[1]:
            results['status'] = 'nonempty_selection_unconfirmed'
            return 1

        # ---- 4 精确替换：独立期望 = 冻结选区 + oracle ----
        expected = strict_utf16.expected_replacement(seed.encode('utf-8'), sel2[0], sel2[1], 'X')
        version2, _f2 = tc.read_state()
        after, entry = expect_exactly_once(
            'exact-replace', version2, lambda: tc._m.uitest('text', 'X'), expected,
            expected_txns=1)
        if after is None or entry.get('fail'):
            results['status'] = entry.get('fail', 'exact_replace_failed')
            results['legs'][-1]['frozen_selection'] = list(sel2)
            return 1
        results['legs'][-1]['frozen_selection'] = list(sel2)

        # ---- 5 外部改版：公开通道 SET_NOTE（围栏先于写入取好）----
        fence3 = _fence_marker(rows_for(pid))
        external = '外部改版后的备注 thermΩ'
        version3, _f3 = tc.read_state()
        rec = set_note_external(external)
        results['transactions'].append({'leg': 'external-set', 'applied': rec.get('applied')})
        if not rec.get('applied'):
            results['status'] = 'external_set_refused'
            return 1
        note3 = None
        for _ in range(12):
            note3, _fields3 = read_note()
            if note3 == external:
                break
            time.sleep(0.4)
        results['legs'].append({'leg': 'external-set', 'note': note3})
        if note3 != external:
            results['status'] = 'external_set_failed'
            return 1

        # ---- 6 继续输入：等改版后的新安装确认，冻结后独立计算期望 ----
        # round14-A：重挂载安装腿 owner 基线在观察前冻结（外部改版恰好一笔，
        # 基线 = 改版后的版本）。
        version_pe, _fpe = tc.read_state()
        sel3, rows = wait_confirmed(pid, fence3, non_empty=False, rounds=30,
                                    expect={'field': NOTE_FIELD,
                                            'owner_version': version_pe},
                                    archive=archive_sink,
                                    leg='6-post-external-select')
        results['legs'].append({'leg': 'post-external-select', 'selection': sel3})
        if sel3 is None:
            results['status'] = 'post_external_selection_unconfirmed'
            return 1
        expected2 = strict_utf16.expected_replacement(external.encode('utf-8'), sel3[0], sel3[1], 'Y')
        version4, _f4 = tc.read_state()
        after2, entry = expect_exactly_once(
            'continue-input', version4, lambda: tc._m.uitest('text', 'Y'), expected2,
            expected_txns=1)
        if after2 is None or entry.get('fail'):
            results['status'] = entry.get('fail', 'continue_input_failed')
            results['legs'][-1]['frozen_selection'] = list(sel3)
            return 1
        results['legs'][-1]['frozen_selection'] = list(sel3)

        # ---- 7-9 生成 TEXT 字段与编辑面回访（R3补轮：真正公共候选生成消费）----
        # 7a 公共候选提交：SUBMIT_GENERATED_UI（携带 textInput field=note）。
        get_rows = tc.business(["GET_GENERATED_UI_CANDIDATE 0"])[1]
        mo = re.search(r"CANDIDATE_VERSION (\d+)", get_rows)
        if not mo:
            results['status'] = 'candidate_version_unavailable'
            results['transactions'].append({'leg': 'candidate-version', 'resp': get_rows[:200]})
            return 1
        structure_version = int(mo.group(1))
        candidate = ("GENERATED_UI_STRUCTURE 1\n"
                     "NODE 0 gen-root-r3 vertical\n"
                     "PROPERTY 0 gen-root-r3 fixedHeight 140\n"
                     "PROPERTY 0 gen-root-r3 padding 12\n"
                     "NODE 1 gen-note-r3 textInput field=note\n"
                     "PROPERTY 1 gen-note-r3 label thermo-generated-note-r3\n"
                     "PROPERTY 1 gen-note-r3 fixedHeight 64\n"
                     "PROPERTY 1 gen-note-r3 growX 1\n"
                     "END")
        submit_lines = ["SUBMIT_GENERATED_UI %d" % structure_version] + candidate.split("\n")
        # 候选节点发现绑定**本次候选**：围栏在提交之前取，只认本围栏之后出现的
        # accepted 行，不取历史同 semantic/label 行（指导复核：不能借旧行冒充
        # 本轮候选的安装身份）。
        fence_cand = _fence_marker(rows_for(pid))
        _, submit_resp = tc.business(submit_lines)
        applied = re.search(r"^APPLIED true$", submit_resp, re.M) is not None
        cand_ok = re.search(r"^CANDIDATE_ACCEPTED true$", submit_resp, re.M) is not None
        # 场景接受是异步的（下一 scene 事务提交）：回包只要求候选被接受；真实
        # 接受由下方 accepted 日志轮询证明（accepted 节点出现 = 场景已提交）。
        results['transactions'].append({'leg': 'candidate-submit',
                                        'structure_version': structure_version,
                                        'applied': applied, 'candidate_accepted': cand_ok,
                                        'resp': submit_resp[:240]})
        if not (applied and cand_ok):
            results['status'] = 'candidate_submit_failed'
            return 1

        def find_generated_semantic(pid, marker, fence, rounds=16):
            """**本次候选围栏之后**出现的 accepted 日志里，label 标记对应的生成
            编辑器 semantic 与节点号（不取历史同 semantic/label 行）。"""
            for _ in range(rounds):
                rows = rows_for(pid)
                # round15-B：边界无法证明（轮转/歧义）→ 本轮跳过重扫（等待态），
                # 绝不回退 0 把候选前历史当新证据。
                f0 = _resolve_fence(rows, fence)
                if f0 is None:
                    time.sleep(0.5)
                    continue
                for r in rows[f0:]:
                    # kind 号随产品输入风格不同（单行=5、多行=10），以 label 标记
                    # 定位生成编辑器的 accepted 行。
                    if ('accepted node=' in r and marker in r):
                        mo = re.search(r'accepted node=(\d+) semantic=(\S+)', r)
                        if mo:
                            return int(mo.group(1)), mo.group(2)
                time.sleep(0.5)
            return None, None

        gen_node, gen_semantic = find_generated_semantic(pid, 'thermo-generated-note-r3', fence_cand)
        results['legs'].append({'leg': 'generated-node', 'node': gen_node,
                                'semantic': gen_semantic})
        if gen_semantic is None:
            results['status'] = 'generated_node_not_accepted'
            return 1
        gen_point = tc.readback_semantic_point(gen_semantic)
        results['legs'].append({'leg': 'generated-point', 'point': gen_point})
        if gen_point is None:
            results['status'] = 'generated_point_missing'
            return 1

        def confirmed_after(fence, expect, leg):
            return wait_confirmed(pid, fence, non_empty=False, expect=expect,
                                  archive=archive_sink, leg=leg)

        # 7b 生成编辑器聚焦（触摸）→ 共享类安装确认（新挂载）→ 输入追加。
        # round14-A：生成安装腿 owner 基线在动作前冻结。
        version_g0, _fg0 = tc.read_state()
        fence_g = _fence_marker(rows_for(pid))
        tc._m.uitest('click', str(int(gen_point[0])), str(int(gen_point[1])))
        sel_g, _rows = confirmed_after(fence_g, {'field': gen_semantic,
                                                 'owner_version': version_g0},
                                       leg='7b-generated-select')
        results['legs'].append({'leg': 'generated-select', 'selection': sel_g})
        if sel_g is None:
            results['status'] = 'generated_install_unconfirmed'
            return 1
        current, _fields = read_note()
        if current is None:
            results['status'] = 'owner_unreadable_before_generated_input'
            return 1
        # 用户落点即真实意图：生成编辑器确认安装在 [a,b)（触摸点击位置决定），
        # 键入 'G1' 必须精确插在该 caret——按冻结选区的 oracle 独立计算期望，
        # 不假设“追加到末尾”。
        expected_g = strict_utf16.expected_replacement(
            current.encode('utf-8'), sel_g[0], sel_g[1], 'G1')
        version_g, _fg = tc.read_state()
        after_g, entry_g = expect_exactly_once(
            'generated-input', version_g, lambda: tc._m.uitest('text', 'G1'),
            expected_g, expected_txns=ASCII_CHAR_TXNS * len('G1'))
        if after_g is None or entry_g.get('fail'):
            results['status'] = entry_g.get('fail', 'generated_input_failed')
            return 1

        # 8 编辑面回访腿1：切到手写备注编辑器（另一个绑定/挂载）。
        hand_point = tc.readback_semantic_point('hand-scroll-note')
        if hand_point is None:
            results['status'] = 'hand_point_missing'
            return 1
        fence_h = _fence_marker(rows_for(pid))
        # round14-A：回访腿 owner 基线在动作前冻结。
        version_h0, _fh0 = tc.read_state()
        tc._m.uitest('click', str(int(hand_point[0])), str(int(hand_point[1])))
        sel_h, _rows = confirmed_after(fence_h, {'field': NOTE_FIELD,
                                                 'owner_version': version_h0},
                                       leg='8-hand-revisit-select')
        results['legs'].append({'leg': 'hand-revisit-select', 'selection': sel_h})
        if sel_h is None:
            results['status'] = 'hand_revisit_install_unconfirmed'
            return 1
        current_h, _fh = read_note()
        expected_h = strict_utf16.expected_replacement(
            current_h.encode('utf-8'), sel_h[0], sel_h[1], 'H')
        version_h, _fh2 = tc.read_state()
        after_h, entry_h = expect_exactly_once(
            'hand-revisit-input', version_h, lambda: tc._m.uitest('text', 'H'),
            expected_h, expected_txns=1)
        if after_h is None or entry_h.get('fail'):
            results['status'] = entry_h.get('fail', 'hand_revisit_input_failed')
            return 1

        # 9 回访腿2：回到生成编辑器（A→B→A 活动绑定在设备上成立）。
        # round12-R2：重新取**当前发布**的读回几何——前腿输入已让上方文本增长，
        # 生成节点随布局下移，旧点会点空（失败具名，不复用旧坐标）。
        gen_point2 = tc.readback_semantic_point(gen_semantic)
        if gen_point2 is None:
            results['status'] = 'generated_revisit_point_missing'
            return 1
        results['legs'].append({'leg': 'generated-revisit-point', 'point': gen_point2})
        # round14-A：生成回访腿 owner 基线在动作前冻结。
        version_g20, _fg20 = tc.read_state()
        fence_g2 = _fence_marker(rows_for(pid))
        tc._m.uitest('click', str(int(gen_point2[0])), str(int(gen_point2[1])))
        sel_g2, _rows = confirmed_after(fence_g2, {'field': gen_semantic,
                                                   'owner_version': version_g20},
                                        leg='9-generated-revisit-select')
        results['legs'].append({'leg': 'generated-revisit-select', 'selection': sel_g2})
        if sel_g2 is None:
            results['status'] = 'generated_revisit_install_unconfirmed'
            return 1
        current_g2, _fg2 = read_note()
        expected_g2 = strict_utf16.expected_replacement(
            current_g2.encode('utf-8'), sel_g2[0], sel_g2[1], 'G2')
        version_g2, _fg3 = tc.read_state()
        after_g2, entry_g2 = expect_exactly_once(
            'generated-revisit-input', version_g2, lambda: tc._m.uitest('text', 'G2'),
            expected_g2, expected_txns=ASCII_CHAR_TXNS * len('G2'))
        if after_g2 is None or entry_g2.get('fail'):
            results['status'] = entry_g2.get('fail', 'generated_revisit_input_failed')
            return 1

        # round14-B：验收 OK 之前先核必需归档——缺件/空件一律具名终结，
        # 不允许业务 OK 配缺失原件。
        results['archive_required'] = list(archive_sink['required'])
        missing = [p for p in archive_sink['required']
                   if not Path(p).exists() or Path(p).stat().st_size == 0]
        if missing:
            results['status'] = 'archive_incomplete'
            results['archive_missing'] = missing
            return 1
        results['status'] = 'OK'
        return 0
    except ArchiveRequiredError as exc:
        results['status'] = 'archive_write_failed'
        results['archive_error'] = str(exc)
        return 1
    finally:
        # round13-R3：**有序原件落盘**（先于转发清理）——安装/观测/ADOPTED2/
        # 当时读回四件套必须可离线重判。round14-B：落盘失败不再吞掉——
        # 具名 archive_incomplete 并以非零退出码终结。
        final_ok = True
        try:
            all_rows = rows_for(pid)
            (out / 'hilog_cjgui_rows.txt').write_text('\n'.join(all_rows) + '\n')
            try:
                state = tc.readback_owner_state()
            except Exception as exc:  # noqa: BLE001
                state = None
                results['final_readback_error'] = repr(exc)
            if state:
                (out / 'owner_state_final.txt').write_text(state + '\n')
            (out / 'identity.txt').write_text(json.dumps(results.get('identity'), ensure_ascii=False))
        except Exception as exc:  # noqa: BLE001
            final_ok = False
            results['status'] = 'archive_incomplete'
            results['final_archive_error'] = repr(exc)
        results['archive_required'] = list(archive_sink['required'])
        if fwd_created:
            listing = subprocess.run([HDC, 'fport', 'ls'], capture_output=True, text=True).stdout or ''
            if re.search(r'tcp:17857\s+tcp:7857', listing):
                subprocess.run([HDC, 'fport', 'rm', 'tcp:17857', 'tcp:7857'], capture_output=True)
        (out / 'thermo-shared.json').write_text(json.dumps(results, ensure_ascii=False, indent=2))
        print(json.dumps({'status': results.get('status'),
                          'install': results.get('install'),
                          'legs': results.get('legs')}, ensure_ascii=False))
        if not final_ok:
            return 1

if __name__ == '__main__':
    # 可选 argv[1]：本轮独立输出目录（离线/复跑必须显式给出，避免覆盖证据）。
    sys.exit(main(sys.argv[1] if len(sys.argv) > 1 else None))

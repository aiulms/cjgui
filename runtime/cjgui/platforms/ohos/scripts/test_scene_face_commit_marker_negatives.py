#!/usr/bin/env python3
"""round9-D 提交标记与面判定反例（直接抽取当前 `accepted_commit_marker` /
`_classify_face` / `scene_face`）。

与 round8 版的差别（判据方向未放松，形状随生产改动迁移）：

* 提交标记从 `accepted faces … source=N preview=M` 换成**中性**
  `accepted commit v=… ticket=… nodes=… semantic=…`。通用 renderer 不再做产品
  分类（本轮任务第 4 条），因此提交标记里**没有**面信息。
* 面由**驱动自己的**词表（`_classify_face`）按**同一提交版本**的
  `accepted node=… semantic=… v=V` 行判定。
* 额外固化一条 round9 修掉的真实缺陷：本次提交的行区间是「上一条提交标记之后 →
  本条标记」，逐节点行打印在标记**之前**；首次实现从标记行往后扫，面恒为 None。

沿用的反例（一条未减）：已提交 preview / 未提交 / 只有 candidate / 切回 source /
围栏被回收 / 跨版本映射不得使用。
"""
import ast
import re
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
SOURCE = HERE / 'verify_pharos_dual_owner.py'

NAMES = ('_fence_start', 'accepted_commit_marker', '_classify_face', 'scene_face')

FAILURES = []


def load():
    tree = ast.parse(SOURCE.read_text(encoding='utf-8'))
    nodes = [n for n in tree.body if isinstance(n, ast.FunctionDef) and n.name in NAMES]
    missing = {n for n in NAMES} - {n.name for n in nodes}
    if missing:
        raise SystemExit(f'missing functions: {sorted(missing)}')
    src = SOURCE.read_text(encoding='utf-8')
    ns = {'re': re}
    exec(compile(ast.Module(body=nodes, type_ignores=[]), str(SOURCE), 'exec'), ns)
    # 分类词表是模块级常量，测试从**生产源码**抽，不另抄一份。
    for kind in ('BODY', 'PREVIEW'):
        name = f'_{kind}_PREFIXES'
        mo = re.search(rf'^{name} = \((.*?)\)$', src, re.S | re.M)
        if not mo:
            raise SystemExit(f'face prefix table not found: {name}')
        ns[name] = tuple(re.findall(r"'([^']+)'", mo.group(1)))
    return ns


NS = load()
accepted_commit_marker = NS['accepted_commit_marker']
scene_face = NS['scene_face']


def check(name, got, want):
    ok = got == want
    print(f"   {'OK  ' if ok else 'FAIL'} {name} -> {got!r} (want {want!r})")
    if not ok:
        FAILURES.append(name)


def commit_row(v, nodes=16):
    """中性提交标记（通用层只有事实，没有面）。"""
    return (f"CjguiRenderer: accepted commit v={v} ticket={v} nodes={nodes} "
            f"semantic={v * 7}")


def node_row(node, semantic, v, value='abc'):
    return (f"CjguiRenderer: accepted node={node} semantic={semantic} kind=10 "
            f"label={semantic} value={value} v={v}")


# 切换前的 source 提交 + 其后的绘制行（这三行就是 round7 误沿用的「旧面」）。
BEFORE = [
    node_row(107, 'pharos-editor-body', 41),
    commit_row(41),
    "CjguiRenderer: text layout painted serial=416 ctx=10 ticket=41 node=107 units=63",
]
# 切换动作本身（点击已送达、已分发）——不决定面，只说明动作到了。
TOGGLE = [
    "CjguiRenderer: activate enqueue node=961 projection=42 tap=(313,21) queue=0",
    "CjguiRenderer: activate dequeue node=961 projection=42 binding=1 lift=6",
    "CjguiRenderer: present wait enter session=1 ticket=42 seq=250",
]
# 已提交的 preview：逐节点行在**提交标记之前**（与生产同序）。
COMMITTED_PREVIEW = [
    node_row(313, 'pharos-document-note', 42, 'abcdef'),
    commit_row(42, 19),
    "CjguiRenderer: present frame ok (nodes=19) layouts=3686 layoutBytes=89324",
]

FENCE = BEFORE[-1]

# 1) 已提交 preview：面必须是 preview（round7 在这里读到 source）。
check('committed-preview', scene_face(BEFORE + TOGGLE + COMMITTED_PREVIEW, FENCE), 'preview')
# 2) 生产没提交（无提交标记）：**未观测**，绝不沿用旧 source 面。
check('not-committed-unobserved', scene_face(BEFORE + TOGGLE, FENCE), None)
# 3) 只有 candidate 被画过（present frame ok 但无提交标记）：未观测。
check('candidate-only-unobserved',
      scene_face(BEFORE + TOGGLE + COMMITTED_PREVIEW[1:], FENCE), None)
# 4) 切回 source 的提交：面回到 source（不是沿用）。
BACK_TO_SOURCE = [
    node_row(107, 'pharos-editor-body', 43),
    commit_row(43),
]
check('committed-back-to-source',
      scene_face(BEFORE + TOGGLE + COMMITTED_PREVIEW + BACK_TO_SOURCE,
                 COMMITTED_PREVIEW[-1]), 'source')
# 5) 提交标记给出「哪个版本已提交」（判别「已提交但面未知」的那一刀）。
m = accepted_commit_marker(BEFORE + TOGGLE + COMMITTED_PREVIEW, FENCE)
check('commit-marker', None if m is None else (m[0], m[1]), (42, 19))
check('marker-absent-after-fence', accepted_commit_marker(BEFORE + TOGGLE, FENCE), None)
# 6) 围栏行被环形回收 ⇒ 未观测，**不**退回 0 重扫历史。
check('fence-evicted-unobserved', scene_face(BEFORE + TOGGLE, '已淘汰的行'), None)
check('fence-evicted-marker-none', accepted_commit_marker(BEFORE + TOGGLE, '已淘汰的行'), None)
# 7) node→semantic 映射只允许来自**同一提交版本**（旧实现扫全历史取最后一条）。
CROSS_VERSION = [
    node_row(107, 'pharos-editor-body', 41),      # 旧版本的节点行
    commit_row(50),                              # 当前提交版本没有节点行
    "CjguiRenderer: text layout painted serial=1 ctx=1 ticket=1 node=107 units=1",
]
check('stale-version-mapping-not-used', scene_face(CROSS_VERSION, ''), None)
# 8) 只有本版本节点行时可判面（回归：扫描窗口下界不得从标记行起算）。
check('same-version-node-row-classifies',
      scene_face([node_row(107, 'pharos-editor-body', 7), commit_row(7)], ''), 'source')

print(f"== 结果 failures={len(FAILURES)}")
raise SystemExit(1 if FAILURES else 0)

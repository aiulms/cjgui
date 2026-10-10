#!/usr/bin/env python3
"""round10/11 D1+D2：**编译并运行**当前 renderer 的发布/查询实现，验证终态一致性。

抽取的都是生产原文（不是测试改写）：

  * 结构体 `OhosTicketFact` / `OhosFaceNode` / `OhosAcceptedFact` /
    `OhosAcceptedFactSlot` / `PendingSettlement` 逐字；
  * 发布器 `cjguiOhosPublishSettlement` / `cjguiOhosPublishTicketTerminal` /
    `cjguiOhosPublishInFlight` 与摘要函数逐字；
  * 查询器 `ohos_renderer_accepted_state` **整个函数体逐字**（round11 反例：旧版
    只抽格式串、实参由测试手抄，生产实参被删后生成 C++ 逐字不变）。探针用
    `-Werror=format` 编译，生产格式串与实参任何错位都在此翻红。

对照反例：
  1. sync_success    frame 发布早于递增 → head.frame 必须等于真值
  2. delayed_success decision 发布早于落定 → 必须 ACCEPTED 且 frame 真值
  3. delayed_reject  只终结票据 → accepted 保旧、不标 cancelled
  4. sync_fail       先在途后失败 → 终态发布、清在途、cancelled 区分拒绝
  5. slot reuse      新 token 读旧事实 → 槽绑 token 且 create 复位
  6. 新实例未提交即无事实
  7. round11 RING_WRAP：取消票占槽 → 8 次成功环绕后，第 9 张成功票的
     id/decision/status/reason/frame/accepted 全属本票（不继承 x2）
  8. 重复查询不制造第二终态（只读：ringCount/epoch 不因查询增长）

变异负控证明判别力（都是内存改写，不落盘生产文件）：
  * 删掉生产查询的 `src.token` 实参 → 探针必须**编译失败**（-Werror=format）；
  * 把成功发布器的完整新记录改回环槽继承 → RING_WRAP 断言必须翻红。
"""
import re
import subprocess
import sys
import tempfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
# scripts → ohos → platforms → cjgui → runtime → 仓根
ROOT = HERE.parent.parent.parent.parent.parent
HOST = ROOT / 'runtime/cjgui/platforms/ohos/host/ohos_renderer.cpp'

failures = []


def check(name, got, want):
    ok = got == want
    print(f"  {'OK  ' if ok else 'FAIL'} {name}: {got!r}" + ('' if ok else f' (want {want!r})'))
    if not ok:
        failures.append(name)


def span(text, begin, end):
    i = text.index(begin)
    j = text.index(end, i) + len(end)
    return text[i:j]


def balanced(text, start):
    i = text.index('{', start)
    depth = 0
    for k in range(i, len(text)):
        if text[k] == '{':
            depth += 1
        elif text[k] == '}':
            depth -= 1
            if depth == 0:
                return text[start:k + 1]
    raise ValueError('unbalanced')


PROLOGUE = r'''
#include <algorithm>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <deque>
#include <map>
#include <memory>
#include <mutex>
#include <string>
#include <vector>

struct SceneNode {
    // round11-D4：几何记录需要裁剪链/交互/投影/绑定字段（与生产 pod 同名同型，
    // 只留发布/查询真正读到的成员）。
    struct Pod {
        uint64_t nodeId; uint64_t projectionVersion; uint64_t acceptedBindingEpoch;
        int64_t x, y, width, height;
        int64_t clipX, clipY, clipWidth, clipHeight;
        uint32_t nodeKind; uint32_t isInteractive; uint32_t clipConstraintCount;
        int64_t clip0X, clip0Y, clip0Width, clip0Height;
        double clip0CornerRadius;
        int64_t clip1X, clip1Y, clip1Width, clip1Height;
        double clip1CornerRadius;
        int64_t clip2X, clip2Y, clip2Width, clip2Height;
        double clip2CornerRadius;
        int64_t clip3X, clip3Y, clip3Width, clip3Height;
        double clip3CornerRadius;
        double clipCornerRadius;
    } pod;
    std::string semanticId;
    std::string value;
};
// 生产里 SceneNode::pod 即 CjguiInternalRendererComposableNode（见
// cjgui_internal_renderer.h）；探针用同名别名让逐字抽取的裁剪函数原样编译。
using CjguiInternalRendererComposableNode = SceneNode::Pod;

constexpr size_t kOhosTicketRing = 8;
constexpr size_t kOhosAcceptedRing = 8;
constexpr uint32_t kOhosFaceTextKind = 10;
constexpr uint32_t kKindText = 3;
constexpr size_t kOhosFaceNodeCap = 8;
enum CjguiInternalRendererPresentDecision {
    CJGUI_INTERNAL_RENDERER_PRESENT_DECISION_NONE = 0,
    CJGUI_INTERNAL_RENDERER_PRESENT_DECISION_PENDING = 1,
    CJGUI_INTERNAL_RENDERER_PRESENT_DECISION_ACCEPTED = 2,
    CJGUI_INTERNAL_RENDERER_PRESENT_DECISION_REJECTED = 3
};

// 极小 Session 替身：只提供发布/查询实现真正读到的字段。查询器逐字使用
// g_sessions.lock，因此替身带同形锁成员。
struct Session {
    uint64_t token = 0;
    uint64_t acceptedProjectionVersion = 0;
    uint64_t submittedFrameIndex = 0;
    uint64_t unackedTicketId = 0;
    std::vector<SceneNode> accepted;
    // round12-R1：getter 在查询时刻读取的当前编辑身份字段（与生产 Session 同名）。
    bool editing = false, editingContextLive = false, editorRetired = false;
    int64_t editingContextId = 0, editingContextGeneration = 0, editingResourceId = 0;
    uint64_t editingNodeId = 0, editingAcceptedBindingEpoch = 0, editingProjectionVersion = 0;
    uint32_t editingNodeKind = 0;
    std::string editingFieldName;
};
struct Sessions { std::mutex lock; } g_sessions;
static std::vector<Session *> g_allSessions;
static int sessionSlotLocked(uint64_t token) {
    for (size_t i = 0; i < g_allSessions.size(); ++i)
        if (g_allSessions[i]->token == token) return static_cast<int>(i);
    return -1;
}
static Session *lookupSessionLocked(uint64_t token) {
    for (size_t i = 0; i < g_allSessions.size(); ++i)
        if (g_allSessions[i]->token == token) return g_allSessions[i];
    return nullptr;
}
static std::mutex g_acceptedFactLock;
'''

# 槽复位/销毁替身：依赖结构体与槽数组，必须排在其后。
SLOT_HELPERS = r'''
static void factCreateSlot(size_t slot, uint64_t token) {
    std::lock_guard<std::mutex> g(g_acceptedFactLock);
    g_acceptedFact[slot].token = token;
    g_acceptedFact[slot].epoch = 0;
    g_acceptedFact[slot].fact = OhosAcceptedFact();
}

static void factDestroySlot(size_t slot) {
    std::lock_guard<std::mutex> g(g_acceptedFactLock);
    g_acceptedFact[slot].token = 0;
    g_acceptedFact[slot].epoch = 0;
    g_acceptedFact[slot].fact = OhosAcceptedFact();
}
'''

MAIN = r'''
static SceneNode mkNode(uint64_t id, const char *semantic, int64_t x, int64_t y,
                        int64_t w, int64_t h, uint32_t kind, uint32_t interactive = 1u) {
    SceneNode n{};
    n.pod.nodeId = id; n.pod.x = x; n.pod.y = y; n.pod.width = w; n.pod.height = h;
    n.pod.nodeKind = kind; n.pod.isInteractive = interactive;
    n.pod.projectionVersion = 20; n.pod.acceptedBindingEpoch = 6;
    // 无裁剪祖先：单 clip 槽（count=0 的回退路径）给包含 bounds 的保守矩形。
    n.pod.clipX = 0; n.pod.clipY = 0; n.pod.clipWidth = 8192; n.pod.clipHeight = 8192;
    n.semanticId = semantic; n.value = "abc";
    return n;
}
static void show(const char *tag, uint64_t token) {
    const char *row = ohos_renderer_accepted_state(token);
    printf("%s %s\n", tag, row ? row : "");
}
static void publishSuccess(uint64_t token, PendingSettlement &p,
                           std::vector<SceneNode> &accepted,
                           uint64_t ticket, uint64_t frame) {
    std::lock_guard<std::mutex> g(g_sessions.lock);
    p.ticketId = ticket;
    p.decision = CJGUI_INTERNAL_RENDERER_PRESENT_DECISION_ACCEPTED;
    p.terminalStatus = 0;
    p.frameIndex = frame;
    p.settled = true;
    cjguiOhosPublishSettlement(token, p, accepted);
}
int main() {
    Session s; s.token = 201;
    g_allSessions.push_back(&s);
    factCreateSlot(0, s.token);

    SceneNode text = mkNode(107, "pharos-editor-body", 0, 0, 400, 400, kOhosFaceTextKind);
    SceneNode other = mkNode(110, "pharos-editor-status", 0, 0, 10, 10, 2, 0u);
    s.accepted = {text, other};
    s.acceptedProjectionVersion = 20;
    s.submittedFrameIndex = 7;

    PendingSettlement p;
    p.valid = true; p.settled = true; p.ticketId = 11;
    p.decision = CJGUI_INTERNAL_RENDERER_PRESENT_DECISION_ACCEPTED;
    p.terminalStatus = 0; p.projectionVersion = 20; p.frameIndex = 0;
    p.sourceEditingContextId = 7;
    p.drawableWidth = 1260; p.drawableHeight = 2720; p.density = 3.0;

    // 1. 同步成功：帧号递增之后才发布。
    {
        std::lock_guard<std::mutex> g(g_sessions.lock);
        s.submittedFrameIndex += 1;                 // 真值 8
        p.frameIndex = s.submittedFrameIndex;
        cjguiOhosPublishSettlement(s.token, p, s.accepted);
    }
    show("SYNC", s.token);

    // 2. 延迟成功：四字段全部落定之后才发布。
    {
        std::lock_guard<std::mutex> g(g_sessions.lock);
        PendingSettlement d = p;
        d.ticketId = 13;
        s.submittedFrameIndex += 1;                 // 真值 9
        d.frameIndex = s.submittedFrameIndex;
        d.decision = CJGUI_INTERNAL_RENDERER_PRESENT_DECISION_ACCEPTED;
        d.terminalStatus = 0;
        d.settled = true;
        cjguiOhosPublishSettlement(s.token, d, s.accepted);
    }
    show("DELAYED", s.token);

    // 3. 延迟拒绝：只终结票据，accepted 保旧。
    {
        std::lock_guard<std::mutex> g(g_sessions.lock);
        PendingSettlement r;
        r.valid = true; r.settled = true; r.ticketId = 14;
        r.decision = CJGUI_INTERNAL_RENDERER_PRESENT_DECISION_REJECTED;
        r.terminalStatus = 99;
        r.projectionVersion = s.acceptedProjectionVersion;
        r.frameIndex = s.submittedFrameIndex;
        r.sourceEditingContextId = 7;
        cjguiOhosPublishTicketTerminal(s.token, r, false);
    }
    show("REJECT", s.token);

    // 4. 同步失败/取消：先在途，失败后发布终态并清在途。
    {
        std::lock_guard<std::mutex> g(g_sessions.lock);
        cjguiOhosPublishInFlight(s.token, 15,
            CJGUI_INTERNAL_RENDERER_PRESENT_DECISION_PENDING, 0, 7, 19);
        s.unackedTicketId = 15;
    }
    show("INFLIGHT", s.token);
    {
        std::lock_guard<std::mutex> g(g_sessions.lock);
        PendingSettlement f;
        f.valid = true; f.settled = true; f.ticketId = 15;
        f.decision = CJGUI_INTERNAL_RENDERER_PRESENT_DECISION_REJECTED;
        f.terminalStatus = 99;
        f.projectionVersion = s.acceptedProjectionVersion;
        f.frameIndex = s.submittedFrameIndex;
        f.sourceEditingContextId = 7;
        cjguiOhosPublishTicketTerminal(s.token, f, true);
        if (s.unackedTicketId == 15) s.unackedTicketId = 0;
    }
    show("FAILCASE", s.token);

    // 5. 槽复用：新实例不得读到旧实例事实；旧 token 读回为空。
    factCreateSlot(0, s.token);
    show("FRESH", s.token);
    g_allSessions.clear();
    show("DESTROYED", s.token);
    factDestroySlot(0);

    // 6. 全新实例：未提交即无事实。
    Session s2; s2.token = 202;
    g_allSessions.push_back(&s2);
    factCreateSlot(0, s2.token);
    show("NEW", s2.token);
    s2.accepted = {text, other};
    s2.acceptedProjectionVersion = 20;
    s2.submittedFrameIndex = 7;

    // 7. round11 RING_WRAP：取消票占槽 → 超过 K=8 次成功发布环绕后，
    //    成功票必须是完整新记录（不继承取消原因 x2）。
    PendingSettlement w;
    w.valid = true; w.settled = true;
    w.decision = CJGUI_INTERNAL_RENDERER_PRESENT_DECISION_REJECTED;
    w.terminalStatus = 99;
    w.projectionVersion = 20;
    w.sourceEditingContextId = 7;
    w.frameIndex = s2.submittedFrameIndex;
    {
        std::lock_guard<std::mutex> g(g_sessions.lock);
        w.ticketId = 1;
        cjguiOhosPublishTicketTerminal(s2.token, w, true);   // reason=2 取消
    }
    for (uint64_t t = 2; t <= 9; ++t) {
        s2.submittedFrameIndex += 1;
        s2.acceptedProjectionVersion += 1;
        w.projectionVersion = s2.acceptedProjectionVersion;
        publishSuccess(s2.token, w, s2.accepted, t, s2.submittedFrameIndex);
    }
    show("RINGWRAP", s2.token);
    // 8. 重复查询是只读：ringCount / epoch 不因查询增长（无第二终态）。
    {
        const char *a = ohos_renderer_accepted_state(s2.token);
        std::string first = a ? a : "";
        for (int i = 0; i < 3; ++i) {
            const char *b = ohos_renderer_accepted_state(s2.token);
            std::string again = b ? b : "";
            if (again != first) { printf("QUERYMUTATED %s|%s\n", first.c_str(), again.c_str()); return 0; }
        }
        printf("QUERYSTABLE %s\n", first.c_str());
    }

    // 9. round12-R1：当前输入身份 = 查询时刻 Session 现值。
    // 9a 换焦无新帧：Session.editingContextId 7→9 后，读回必须报 ctx=9，
    //    accepted 投影事实保持不变。
    {
        std::lock_guard<std::mutex> g(g_sessions.lock);
        s2.editing = true; s2.editingContextLive = true;
        s2.editingContextId = 7; s2.editingNodeId = 107; s2.editingResourceId = 107;
        s2.editingNodeKind = kOhosFaceTextKind; s2.editingAcceptedBindingEpoch = 6;
        s2.editingProjectionVersion = 20; s2.editingFieldName = "pharos-editor-body";
    }
    show("EDIT7", s2.token);
    {
        std::lock_guard<std::mutex> g(g_sessions.lock);
        s2.editingContextId = 9;                      // 新焦点，无新发布
    }
    show("EDIT9", s2.token);
    // 9b 结束编辑无新帧：live=false 必须显式表达为 edit=none。
    {
        std::lock_guard<std::mutex> g(g_sessions.lock);
        s2.editingContextLive = false;
    }
    show("EDITDEAD", s2.token);

    // 10. round12-R2：9 面发布后 1 面发布，facesTruncated 必须复位。
    {
        std::lock_guard<std::mutex> g(g_acceptedFactLock);
        g_acceptedFact[0].fact = OhosAcceptedFact();   // 复位 s2 槽再走 9→1 序列
        g_acceptedFact[0].epoch = 0;
    }
    {
        std::vector<SceneNode> nine;
        for (uint64_t i = 0; i < 9; ++i)
            nine.push_back(mkNode(600 + i, "pharos-editor-body", 0, 0, 10, 10, kOhosFaceTextKind));
        PendingSettlement np = p; np.ticketId = 21; np.frameIndex = 21;
        std::lock_guard<std::mutex> g(g_sessions.lock);
        cjguiOhosPublishSettlement(s2.token, np, nine);
    }
    show("NINE", s2.token);
    {
        std::vector<SceneNode> one{mkNode(600, "pharos-editor-body", 0, 0, 10, 10, kOhosFaceTextKind)};
        PendingSettlement op = p; op.ticketId = 22; op.frameIndex = 22;
        std::lock_guard<std::mutex> g(g_sessions.lock);
        cjguiOhosPublishSettlement(s2.token, op, one);
    }
    show("ONE", s2.token);
    return 0;
}
'''


def build_probe(src):
    pset = span(src, 'struct PendingSettlement {', '\n};')
    pset = re.sub(r'//.*', '', pset)
    pset = pset.replace('    JobRef job;', '    std::shared_ptr<int> job;')
    pset = pset.replace('std::map<uint64_t, Session::TextRunBinding> runTable;',
                        'std::map<uint64_t, int> runTable;')

    fact = span(src, 'struct OhosTicketFact {', '\n};')
    face = span(src, 'struct OhosFaceNode {', '\n};')
    accepted = span(src, 'struct OhosAcceptedFact {', '\n};')
    slot = span(src, 'struct OhosAcceptedFactSlot {', '\n};')
    # geo 段连同其后两个 cap 常量一起抽（发布器直接引用它们）。常量搜索必须从
    # 结构体**闭合之后**开始——struct 内注释里也出现了常量名。
    geo_start = src.index('struct OhosGeoClipConstraint {')
    # 两个 cap 常量按 **constexpr 行**定位（结构体注释里也出现常量名，不能按名搜）。
    cap_line = src.index('constexpr size_t kOhosGeoNodeCap')
    geo_end = src.index('\n', src.index('constexpr size_t kOhosGeoSemanticBytes', cap_line)) + 1
    geo = src[geo_start:geo_end]
    # round11-D4 汇合：编辑身份结构（accepted fact 的成员；助手依赖 Session 不抽）。
    edit_ident = span(src, 'struct OhosEditingIdentity {', '\n};')

    def fn(name):
        return balanced(src, src.index(f'static void {name}('))

    def free_fn(prefix, name):
        return balanced(src, src.index(f'static {prefix} {name}('))

    digest = balanced(src, src.index('static uint64_t cjguiOhosSemanticDigest('))
    vhash = balanced(src, src.index('static uint64_t cjguiOhosValueHash('))
    # round11-D4：发布器的几何计算依赖两个文件级裁剪函数，一并逐字抽取。
    clip_at = free_fn('void', 'cjguiOhosClipConstraintAt')
    clip_agg = free_fn('bool', 'cjguiOhosAggregateClipRect')
    pub_settle = fn('cjguiOhosPublishSettlement')
    pub_terminal = fn('cjguiOhosPublishTicketTerminal')
    pub_inflight = fn('cjguiOhosPublishInFlight')
    # round11-D2：查询器**整个函数体**逐字（格式串与实参一起抽，不再手抄实参）。
    accepted_state = balanced(
        src, src.index('extern "C" const char *ohos_renderer_accepted_state('))
    edit_of = balanced(src, src.index('static OhosEditingIdentity cjguiOhosEditingIdentityOf('))

    return ''.join([PROLOGUE, '\n', pset, '\n', fact, '\n', face, '\n', geo, '\n', edit_ident, '\n', edit_of, '\n\n',
                    accepted, '\n', slot, '\n',
                    'static OhosAcceptedFactSlot g_acceptedFact[4];\n',
                    SLOT_HELPERS, '\n',
                    digest, '\n', vhash, '\n\n', clip_at, '\n\n', clip_agg, '\n\n',
                    pub_settle, '\n\n', pub_terminal,
                    '\n\n', pub_inflight, '\n\n', accepted_state, '\n', MAIN])


COMPILE_FLAGS = ['-std=c++17', '-O0', '-Werror=format']


def compile_probe(code, td, name='probe'):
    cpp = Path(td) / f'{name}.cpp'
    cpp.write_text(code)
    exe = Path(td) / name
    cc = subprocess.run(['clang++'] + COMPILE_FLAGS + ['-o', str(exe), str(cpp)],
                        capture_output=True, text=True)
    return cc, exe


def run_probe(src):
    """编译并运行真实源码的探针；返回 {tag: row}。编译失败即异常。"""
    code = build_probe(src)
    with tempfile.TemporaryDirectory() as td:
        cc, exe = compile_probe(code, td)
        if cc.returncode != 0:
            print(cc.stderr[:2500])
            raise SystemExit('probe compile failed')
        run = subprocess.run([str(exe)], capture_output=True, text=True)
        if run.returncode != 0:
            print(run.stdout[-1500:], run.stderr[-1500:])
            raise SystemExit('probe run failed')
        out = {}
        for line in run.stdout.splitlines():
            if ' ' in line:
                k, v = line.split(' ', 1)
                out[k] = v
        return out


def _fn_span(text, signature):
    """返回 (函数起点, 函数体结束) 下标。"""
    i = text.index(signature)
    d = 0
    for k in range(text.index('{', i), len(text)):
        if text[k] == '{':
            d += 1
        elif text[k] == '}':
            d -= 1
            if d == 0:
                return i, k
    raise ValueError('unbalanced function: ' + signature)


# 终态四字段与 accepted 投影的**关键写入**标记（生产里逐字出现的语句片段）。
TERMINAL_WRITES = (
    'p.frameIndex = s->submittedFrameIndex;',
    'p.terminalStatus = CJGUI_INTERNAL_RENDERER_OK;',
    'p.decision = CJGUI_INTERNAL_RENDERER_PRESENT_DECISION_ACCEPTED;',
    's->submittedFrameIndex += 1;',
    's->accepted.swap(',
    's->acceptedProjectionVersion =',
)


def check_publish_order(src):
    """检查真实生产调用点的**发布时机**（补充判据，不声称覆盖完整运行路径）。"""
    out = []

    # ---- 延迟结算 ----
    a, b = _fn_span(src, 'static uint32_t settlePendingTicketLocked')
    body = src[a:b]
    pub = body.find('cjguiOhosPublishSettlement(s->token, p, s->accepted')
    if pub < 0:
        out.append(('order-delayed-success-publish-present', False, '找不到延迟成功发布调用'))
    else:
        missing = [w for w in TERMINAL_WRITES if w not in body[:pub]]
        out.append(('order-delayed-success-publish-after-terminal-writes',
                    not missing, f'发布早于: {missing}'))
    rej_dec = body.find('p.decision = CJGUI_INTERNAL_RENDERER_PRESENT_DECISION_REJECTED;')
    rej_pub = body.find('cjguiOhosPublishTicketTerminal(s->token, p, ')
    out.append(('order-delayed-reject-publish-after-rejected-decision',
                (rej_dec >= 0 and rej_pub > rej_dec),
                f'REJECTED@{rej_dec} 发布@{rej_pub}'))

    # ---- 同步成功 ----
    a2, b2 = _fn_span(
        src, 'CjguiInternalRendererStatus cjgui_internal_renderer_present_composable_scene')
    body2 = src[a2:b2]
    assign = body2.find('syncDone.frameIndex = s->submittedFrameIndex;')
    pub2 = body2.find('cjguiOhosPublishSettlement(s->token, syncDone, s->accepted')
    inc = body2.find('s->submittedFrameIndex += 1;')
    out.append(('order-sync-success-publish-after-frame-assign',
                (assign >= 0 and pub2 > assign), f'帧号赋值@{assign} 发布@{pub2}'))
    out.append(('order-sync-success-no-publish-before-increment',
                (inc >= 0 and pub2 > inc), f'递增@{inc} 发布@{pub2}'))
    # round11-D4：同步成功路径必须把表面事实（宽高/density）填进 syncDone 再发布
    # ——漏填会让几何读回把 vp 当 px（设备实测 density=1.0/viewport=0x0 假点）。
    density_fill = body2.find('syncDone.density = s->surfaceDensity;')
    out.append(('order-sync-success-surface-facts-before-publish',
                (density_fill >= 0 and pub2 > density_fill),
                f'density填值@{density_fill} 发布@{pub2}'))

    # ---- 拒绝/失败不得调用成功发布器 ----
    r = body.find('pending settlement aborted')
    if r >= 0:
        seg = body[r:r + 900]
        out.append(('order-delayed-reject-uses-terminal-publisher-only',
                    'cjguiOhosPublishSettlement' not in seg
                    and 'cjguiOhosPublishTicketTerminal' in seg,
                    '拒绝出口调用了成功发布器或未发布终态'))
    return out


def token_arg_removed_mutant(src):
    """round11 反例的原样变异：删掉生产查询的 src.token 实参（仅内存）。"""
    needle = '                      (unsigned long long)src.token,\n'
    assert src.count(needle) == 1
    return src.replace(needle, '', 1)


def ring_inheritance_mutant(src):
    """D1 判别变异：成功发布器改回「环槽继承」的旧形状（仅内存）。"""
    a, b = _fn_span(src, 'static void cjguiOhosPublishSettlement')
    body = src[a:b]
    assert body.count('OhosTicketFact t{};') == 1
    broken_body = body.replace('OhosTicketFact t{};',
                               'OhosTicketFact t = f.ring[f.ringHead];', 1)
    return src[:a] + broken_body + src[b:]


def main():
    src = HOST.read_text(encoding='utf-8')
    out = run_probe(src)

    def f(s, k):
        m = re.search(rf'(?:^|\s){re.escape(k)}=(-?\d+)', s)
        return int(m.group(1)) if m else None

    def last_ticket(s):
        p = s.rfind(' T')
        if p < 0:
            return ''
        e = s.find(' ', p + 2)
        return s[p + 2: e if e >= 0 else len(s)]

    def parts(t):
        seg = t.split('/')
        return {'id': seg[0], 'decision': seg[1], 'status': seg[2].lstrip('s'),
                'ver': seg[3].lstrip('v'), 'ctx': seg[4].lstrip('c'),
                'nodes': seg[5].lstrip('n'), 'cancelled': seg[6].lstrip('x')}

    sync, delayed = out['SYNC'], out['DELAYED']
    rej, failcase, inflight = out['REJECT'], out['FAILCASE'], out['INFLIGHT']
    fresh, new, wrap = out['FRESH'], out['NEW'], out['RINGWRAP']

    print('== round10/11 D1+D2 生产发布/查询一致性 ==')
    check('1-sync-success-frame-matches-native', f(sync, 'frame'), 8)
    check('1-sync-success-decision-ACCEPTED', parts(last_ticket(sync))['decision'], '2')
    check('1-sync-success-last-ticket', f(sync, 'last'), 11)
    d2 = parts(last_ticket(delayed))
    check('2-delayed-success-decision-ACCEPTED', d2['decision'], '2')
    # 票据项的 v= 是该票终结时的 acceptedProjection（20），**不是**帧号；帧号在
    # head 的 frame=。
    check('2-delayed-success-head-frame-matches-native', f(delayed, 'frame'), 9)
    check('2-delayed-success-ticket-accepted-projection', d2['ver'], '20')
    check('2-delayed-success-not-inflight', f(delayed, 'unacked'), 0)
    r3 = parts(last_ticket(rej))
    check('3-delayed-reject-decision-REJECTED', r3['decision'], '3')
    check('3-delayed-reject-not-inflight', f(rej, 'unacked'), 0)
    check('3-delayed-reject-keeps-accepted-projection', f(rej, 'proj'), 20)
    check('3-delayed-reject-not-marked-cancelled', r3['cancelled'], '0')
    check('4-sync-fail-inflight-published', f(inflight, 'unacked'), 15)
    c4 = parts(last_ticket(failcase))
    check('4-sync-fail-decision-REJECTED', c4['decision'], '3')
    check('4-sync-fail-not-inflight', f(failcase, 'unacked'), 0)
    check('4-sync-fail-cancelled-distinguishes-from-reject', c4['cancelled'], '1')
    check('4-sync-fail-keeps-accepted-projection', f(failcase, 'proj'), 20)
    check('5-reused-slot-no-stale-projection', f(fresh, 'proj'), 0)
    check('5-reused-slot-no-stale-tickets', f(fresh, 'tickets'), 0)
    check('5-destroyed-token-readback-empty', out.get('DESTROYED', ''), '')
    check('6-new-instance-no-projection', f(new, 'proj'), 0)
    check('6-new-instance-no-tickets', f(new, 'tickets'), 0)

    # 7. 环复用：取消票(1,x2) → 成功票 2..9 环绕。第 9 张成功票的字段全属本票。
    w9 = parts(last_ticket(wrap))
    check('7-ringwrap-last-ticket-id', w9['id'], '9')
    check('7-ringwrap-success-decision-ACCEPTED', w9['decision'], '2')
    check('7-ringwrap-success-status-ok', w9['status'], '0')
    check('7-ringwrap-success-reason-normal-not-inherited',
          w9['cancelled'], '0')
    check('7-ringwrap-frame-matches-native', f(wrap, 'frame'), 15)
    check('7-ringwrap-last-accepted-ticket', f(wrap, 'last'), 9)
    check('7-ringwrap-ring-capped-at-K', f(wrap, 'tickets'), 8)
    # 取消票 1 已被环绕淘汰：环内只剩 2..9。
    check('7-ringwrap-cancelled-ticket-evicted',
          ' T1/' in wrap, False)
    # 8. 查询只读：重复读回逐字节相同（无第二终态）。
    check('8-repeat-query-stable', 'QUERYSTABLE' in out and 'QUERYMUTATED' not in out, True)

    # 9. round12-R1：当前输入身份 = 查询时刻 Session 现值。
    check('9a-edit7-live-ctx7', f(out['EDIT7'], None) if False else
          bool(re.search(r'edit=live ctx=7 gen=\d+ node=107 res=107 kind=10 b=6 v=20 field=pharos-editor-body',
                         out['EDIT7'])), True)
    check('9a-focus-without-frame-shows-ctx9',
          bool(re.search(r'edit=live ctx=9 ', out['EDIT9'])), True)
    check('9a-accepted-facts-unchanged-by-focus',
          (f(out['EDIT7'], 'proj'), f(out['EDIT9'], 'proj')), (28, 28))
    check('9a-epoch-unchanged-by-focus', (f(out['EDIT7'], 'epoch'), f(out['EDIT9'], 'epoch')), (9, 9))
    check('9b-retire-without-frame-explicit-none',
          'edit=none' in out['EDITDEAD'], True)
    check('9b-accepted-facts-survive-retire', f(out['EDITDEAD'], 'proj'), 28)

    # 10. round12-R2：截断标志随每次发布整组复位。
    check('10-nine-faces-truncated', bool(re.search(r'faces=8 facesTruncated=1', out['NINE'])), True)
    check('10-one-face-truncation-reset', bool(re.search(r'faces=1 facesTruncated=0', out['ONE'])), True)

    # ---- 源码级发布时机检查（补充判据） ----
    for name, ok, detail in check_publish_order(src):
        if ok:
            check(name, True, True)
        else:
            check(name, detail, True)

    # ---- 变异负控：判别力 ----
    print('== 变异负控 ==')
    with tempfile.TemporaryDirectory() as td:
        cc, _ = compile_probe(build_probe(token_arg_removed_mutant(src)), td, 'mut-token')
        check('mutant-token-arg-removed-fails-compile', cc.returncode != 0, True)
        if cc.returncode == 0:
            print('    (unexpected compile success; stderr was empty)')
    mutant_out = run_probe(ring_inheritance_mutant(src))
    mw = parts(last_ticket(mutant_out['RINGWRAP']))
    check('mutant-ring-inheritance-detected', mw['cancelled'] != '0', True)

    print()
    if failures:
        print(f'FAILURES: {len(failures)} -> {failures}')
        sys.exit(1)
    print('round10/11 D1+D2 生产发布/查询一致性: OK（全部符合预期，含变异负控）')


if __name__ == '__main__':
    main()

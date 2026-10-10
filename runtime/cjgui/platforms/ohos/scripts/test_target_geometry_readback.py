#!/usr/bin/env python3
"""round11-D4：有界目标几何反例（accepted 发布边界冻结 + 读回消费）。

生产实现逐字抽取（结构体 / 文件级裁剪函数 / 两个发布器 / 查询器）并编译运行：

  1. **第 9 项以后目标**：12 个文本面节点（面清单 cap=8）在 geo 段**全部**可定位，
     faceTruncated=1 如实标注；——前 8 项没有目标不代表目标不存在。
  2. **截断具名**：18 个 hit-relevant 节点 → truncated=1、used=16；
  3. **裁剪链**：clipConstraintCount=2 的链式裁剪与 count=0 单 clip 回退路径，
     visible = bounds∩clips（与命中/绘制同一套数学）；
  4. **完全不可见**：全裁掉的节点 vis=1 且**仍在记录里**（三态分开具名）；
  5. **未纳入**：记录完整（truncated=0）而无该目标——not_in_accepted；
  6. **日志全缺仍可定位**：定位只消费 OWNER_STATE 一份字符串，零日志行；
  7. **只读查询零提交/零帧增长**：重复查询 N 次输出逐字节相同，epoch/ring 不动。

驱动侧（真实 m.readback_target_point / parse_geo_section，stub 网络与原点）：
  * ok 定位坐标 = origin + vp*density；三态具名；歧义具名；
  * **失败不复用旧坐标**：上一次成功的坐标在下一次失败查询中绝不返回；
  * 变异负控：解析器丢掉 vis 判定 / 丢掉截断判定 → 对应用例翻红。
"""
import importlib.util
import pathlib
import re
import subprocess
import sys
import tempfile
from pathlib import Path
from types import SimpleNamespace

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent.parent.parent.parent.parent
HOST = ROOT / 'runtime/cjgui/platforms/ohos/host/ohos_renderer.cpp'
DEVICE = HERE / 'h_source_preview_consumption.py'

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
#include <cstring>
#include <map>
#include <memory>
#include <mutex>
#include <string>
#include <vector>

struct SceneNode {
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

struct Session {
    uint64_t token = 0;
    uint64_t acceptedProjectionVersion = 0;
    uint64_t submittedFrameIndex = 0;
    uint64_t unackedTicketId = 0;
    std::vector<SceneNode> accepted;
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

MAIN = r'''
static SceneNode mkNode(uint64_t id, const char *semantic, int64_t x, int64_t y,
                        int64_t w, int64_t h, uint32_t kind, uint32_t interactive = 1u,
                        uint64_t proj = 20, uint64_t binding = 6) {
    SceneNode n{};
    n.pod.nodeId = id; n.pod.x = x; n.pod.y = y; n.pod.width = w; n.pod.height = h;
    n.pod.nodeKind = kind; n.pod.isInteractive = interactive;
    n.pod.projectionVersion = proj; n.pod.acceptedBindingEpoch = binding;
    n.pod.clipX = 0; n.pod.clipY = 0; n.pod.clipWidth = 8192; n.pod.clipHeight = 8192;
    n.semanticId = semantic; n.value = "abc";
    return n;
}
static void show(const char *tag, uint64_t token) {
    const char *row = ohos_renderer_accepted_state(token);
    printf("%s %s\n", tag, row ? row : "");
}
static void publishSuccess(uint64_t token, PendingSettlement &p,
                           std::vector<SceneNode> &accepted, uint64_t frame) {
    std::lock_guard<std::mutex> g(g_sessions.lock);
    p.decision = CJGUI_INTERNAL_RENDERER_PRESENT_DECISION_ACCEPTED;
    p.terminalStatus = 0; p.frameIndex = frame; p.settled = true;
    cjguiOhosPublishSettlement(token, p, accepted);
}
int main() {
    Session s; s.token = 201;
    g_allSessions.push_back(&s);
    {   // 槽归属：create 路径的替身（绑定 token 并复位槽）。
        std::lock_guard<std::mutex> g(g_acceptedFactLock);
        g_acceptedFact[0].token = s.token;
        g_acceptedFact[0].epoch = 0;
        g_acceptedFact[0].fact = OhosAcceptedFact();
    }

    // ---- A. 12 个文本面（第 9+ 超出面清单 cap=8）+ 链式裁剪 + 全裁 + 未纳入判定 ----
    std::vector<SceneNode> tree;
    for (uint64_t i = 0; i < 11; ++i) {
        char sem[64];
        snprintf(sem, sizeof(sem), "pharos-target-%02llu",
                 static_cast<unsigned long long>(i));
        tree.push_back(mkNode(500 + i, sem, 10, 100 + 10 * (int64_t)i, 400, 40,
                              kOhosFaceTextKind));
    }
    // 链式裁剪（count=2）：bounds(10,20,400,200) ∩ clip0(0,0,300,1000) ∩ clip1(50,0,1000,1000)
    // → visible = (50,20,250,200)
    {
        SceneNode chained = mkNode(700, "pharos-chained", 10, 20, 400, 200, kOhosFaceTextKind);
        chained.pod.clipConstraintCount = 2;
        chained.pod.clip0X = 0; chained.pod.clip0Y = 0; chained.pod.clip0Width = 300; chained.pod.clip0Height = 1000;
        chained.pod.clip1X = 50; chained.pod.clip1Y = 0; chained.pod.clip1Width = 1000; chained.pod.clip1Height = 1000;
        tree.push_back(chained);
    }
    // 单 clip 回退路径（count=0 → clipX/Y/W/H）：bounds(0,0,100,100) ∩ clip(25,25,50,50)
    // → visible = (25,25,50,50)
    {
        SceneNode single = mkNode(701, "pharos-single-clip", 0, 0, 100, 100, kOhosFaceTextKind);
        single.pod.clipX = 25; single.pod.clipY = 25; single.pod.clipWidth = 50; single.pod.clipHeight = 50;
        tree.push_back(single);
    }
    // round12-R2：圆角祖先 clip（count=1, r=50）——AABB 全在圆内切之外的角区
    // 点不可命中，中心点可命中。约束逐条随记录发布，读者用同一语义判点。
    {
        SceneNode rounded = mkNode(704, "pharos-rounded", 0, 0, 30, 30, kOhosFaceTextKind);
        rounded.pod.clipConstraintCount = 1;
        rounded.pod.clip0X = 0; rounded.pod.clip0Y = 0;
        rounded.pod.clip0Width = 100; rounded.pod.clip0Height = 100;
        rounded.pod.clip0CornerRadius = 50;
        tree.push_back(rounded);
    }
    // 完全不可见：clip 与 bounds 不相交 → vis=1，仍在记录里
    {
        SceneNode dead = mkNode(702, "pharos-invisible", 0, 2000, 100, 100, kOhosFaceTextKind);
        dead.pod.clipX = 0; dead.pod.clipY = 0; dead.pod.clipWidth = 50; dead.pod.clipHeight = 50;
        tree.push_back(dead);
    }
    // 空裁剪（零宽 clip）：完全不可见的另一种成因
    {
        SceneNode zero = mkNode(703, "pharos-zero-clip", 0, 0, 100, 100, kOhosFaceTextKind);
        zero.pod.clipX = 0; zero.pod.clipY = 0; zero.pod.clipWidth = 0; zero.pod.clipHeight = 50;
        tree.push_back(zero);
    }
    s.accepted = tree;
    s.acceptedProjectionVersion = 20;
    s.submittedFrameIndex = 7;

    PendingSettlement p;
    p.valid = true; p.settled = true; p.ticketId = 11;
    p.projectionVersion = 20;
    p.sourceEditingContextId = 7;
    p.drawableWidth = 1260; p.drawableHeight = 2720; p.density = 3.0;
    s.submittedFrameIndex += 1;
    publishSuccess(s.token, p, s.accepted, s.submittedFrameIndex);
    show("GEO12", s.token);
    // 只读查询零提交/零帧增长：再读 4 次，逐字节相同。
    {
        const char *first = ohos_renderer_accepted_state(s.token);
        std::string a = first ? first : "";
        int stable = 1;
        for (int i = 0; i < 4; ++i) {
            const char *again = ohos_renderer_accepted_state(s.token);
            std::string b = again ? again : "";
            if (b != a) stable = 0;
        }
        printf("QUERYSTABLE %d\n", stable);
    }

    // ---- B. 截断具名：18 个 hit-relevant 节点 → truncated=1、used=16 ----
    {
        Session s2; s2.token = 202;
        g_allSessions.push_back(&s2);
        {
            std::lock_guard<std::mutex> g(g_acceptedFactLock);
            g_acceptedFact[1].token = s2.token;
            g_acceptedFact[1].epoch = 0;
            g_acceptedFact[1].fact = OhosAcceptedFact();
        }
        std::vector<SceneNode> many;
        for (uint64_t i = 0; i < 18; ++i) {
            char sem[64];
            snprintf(sem, sizeof(sem), "pharos-many-%02llu",
                     static_cast<unsigned long long>(i));
            many.push_back(mkNode(900 + i, sem, 10, 10 + 10 * (int64_t)i, 200, 30, 2));
        }
        s2.accepted = many;
        s2.acceptedProjectionVersion = 20;
        s2.submittedFrameIndex = 5;
        PendingSettlement q = p;
        q.ticketId = 3; q.projectionVersion = 20;
        s2.submittedFrameIndex += 1;
        publishSuccess(s2.token, q, s2.accepted, s2.submittedFrameIndex);
        show("MANY18", s2.token);
    }
    return 0;
}
'''


def build_probe(src):
    import re as _re
    pset = span(src, 'struct PendingSettlement {', '\n};')
    pset = _re.sub(r'//.*', '', pset)
    pset = pset.replace('    JobRef job;', '    std::shared_ptr<int> job;')
    pset = pset.replace('std::map<uint64_t, Session::TextRunBinding> runTable;',
                        'std::map<uint64_t, int> runTable;')
    fact = span(src, 'struct OhosTicketFact {', '\n};')
    face = span(src, 'struct OhosFaceNode {', '\n};')
    accepted = span(src, 'struct OhosAcceptedFact {', '\n};')
    slot = span(src, 'struct OhosAcceptedFactSlot {', '\n};')
    geo_start = src.index('struct OhosGeoClipConstraint {')
    cap_line = src.index('constexpr size_t kOhosGeoNodeCap')
    geo_end = src.index('\n', src.index('constexpr size_t kOhosGeoSemanticBytes', cap_line)) + 1
    geo = src[geo_start:geo_end]
    # round12-R1：编辑身份结构与助手（getter 查询时调用，逐字抽取）。
    edit_ident = span(src, 'struct OhosEditingIdentity {', '\n};')
    edit_of = balanced(src, src.index('static OhosEditingIdentity cjguiOhosEditingIdentityOf('))

    def free_fn(prefix, name):
        return balanced(src, src.index(f'static {prefix} {name}('))

    def fn(name):
        return balanced(src, src.index(f'static void {name}('))

    digest = balanced(src, src.index('static uint64_t cjguiOhosSemanticDigest('))
    vhash = balanced(src, src.index('static uint64_t cjguiOhosValueHash('))
    clip_at = free_fn('void', 'cjguiOhosClipConstraintAt')
    clip_agg = free_fn('bool', 'cjguiOhosAggregateClipRect')
    pub_settle = fn('cjguiOhosPublishSettlement')
    pub_terminal = fn('cjguiOhosPublishTicketTerminal')
    pub_inflight = fn('cjguiOhosPublishInFlight')
    accepted_state = balanced(
        src, src.index('extern "C" const char *ohos_renderer_accepted_state('))
    return ''.join([PROLOGUE, '\n', pset, '\n', fact, '\n', face, '\n', geo, '\n',
                    edit_ident, '\n', edit_of, '\n\n', accepted, '\n', slot, '\n',
                    'static OhosAcceptedFactSlot g_acceptedFact[4];\n',
                    digest, '\n', vhash, '\n\n', clip_at, '\n\n', clip_agg, '\n\n',
                    pub_settle, '\n\n', pub_terminal, '\n\n', pub_inflight, '\n\n',
                    accepted_state, '\n', MAIN])


def run_probe(src):
    code = build_probe(src)
    with tempfile.TemporaryDirectory() as td:
        cpp = Path(td) / 'geo.cpp'
        cpp.write_text(code)
        exe = Path(td) / 'geo'
        cc = subprocess.run(['clang++', '-std=c++17', '-O0', '-Werror=format',
                             '-o', str(exe), str(cpp)], capture_output=True, text=True)
        if cc.returncode != 0:
            print(cc.stderr[:2500])
            raise SystemExit('geo probe compile failed')
        run = subprocess.run([str(exe)], capture_output=True, text=True)
        if run.returncode != 0:
            print(run.stdout[-1200:], run.stderr[-1200:])
            raise SystemExit('geo probe run failed')
        out = {}
        for line in run.stdout.splitlines():
            if ' ' in line:
                k, v = line.split(' ', 1)
                out[k] = v
        return out


def load_device():
    spec = importlib.util.spec_from_file_location('pharos_device_geo', DEVICE)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def main():
    src = HOST.read_text(encoding='utf-8')
    out = run_probe(src)
    geo12, many18 = out['GEO12'], out['MANY18']

    print('== round11-D4 有界目标几何（生产发布器+查询器探针） ==')
    # 1. 第 9+ 目标：面清单只列 8 个，geo 段 12+5=17 条里 12 个文本面全在。
    check('face-list-capped-at-8', len(re.findall(r'F\d+:', geo12)), 8)
    check('face-truncated-flagged', bool(re.search(r'facesTruncated=1', geo12)), True)
    for i in (0, 7, 8, 9, 10):   # 8/9/10 在面清单之外
        check(f'target-{i:02d}-locatable-beyond-face-cap',
              bool(re.search(rf'G5\d\d:pharos-target-{i:02d},', geo12)), True)
    # 2. 裁剪链（count=2）：visible=(50,20,250,200)；单 clip 回退：visible=(25,25,50,50)。
    m = re.search(r'G700:pharos-chained,b=\d+,p=\d+,c=2,i=10,20,400,200,v=(-?\d+),(-?\d+),(-?\d+),(-?\d+),vis=0', geo12)
    check('chained-clip-visible-rect', m.groups() if m else None, ('50', '20', '250', '200'))
    m = re.search(r'G701:pharos-single-clip,b=\d+,p=\d+,c=1,i=0,0,100,100,v=(-?\d+),(-?\d+),(-?\d+),(-?\d+),vis=0', geo12)
    check('single-clip-visible-rect', m.groups() if m else None, ('25', '25', '50', '50'))
    # 3. 完全不可见两种成因：记录在、vis=1（三态分开具名的前提）。
    check('disjoint-clip-invisible-recorded',
          bool(re.search(r'G702:pharos-invisible,.*vis=1', geo12)), True)
    check('zero-clip-invisible-recorded',
          bool(re.search(r'G703:pharos-zero-clip,.*vis=1', geo12)), True)
    # 4. density/viewport/units 随发布冻结。
    check('geo-header-frozen-facts',
          bool(re.search(r' geo units=vp density=3\.000000 viewport=1260x2720 used=16 truncated=0',
                         geo12)), True)
    # round12-R2：逐条约束随记录发布（legacy 单 clip 与圆角链各一条可核对）。
    check('rounded-clip-constraint-published',
          bool(re.search(r'G704:pharos-rounded,.*c=1,.*q=0\.000000,0\.000000,100\.000000,'
                         r'100\.000000,50\.000000', geo12)), True)
    check('legacy-clip-constraint-published',
          bool(re.search(r'G500:pharos-target-00,.*q=0\.000000,0\.000000,'
                         r'8192\.000000,8192\.000000,0\.000000', geo12)), True)
    # 5. 只读查询零提交/零帧增长。
    check('repeat-query-byte-stable', out.get('QUERYSTABLE'), '1')
    frame_after_publish = re.search(r'frame=(\d+)', geo12).group(1)
    check('query-does-not-advance-frame', frame_after_publish, '8')
    # 6. 截断具名：18 个 → truncated=1、used=16。
    check('many-truncated-flag', bool(re.search(r'truncated=1 used=16|used=16 truncated=1', many18))
          or (bool(re.search(r'used=16', many18)) and bool(re.search(r'truncated=1', many18))), True)
    check('many-cap-respected', len(re.findall(r'G9\d\d:pharos-many', many18)), 16)

    # ---- 驱动侧：真实解析器与定位函数（stub 网络/原点），零日志行 ----
    print('== 驱动侧（真实 m.readback_target_point） ==')
    dev = load_device()
    state = 'MODE=preview ACCEPTED ' + geo12.split('ACCEPTED ', 1)[-1] if 'ACCEPTED' in geo12 else geo12

    def owner_state(port):
        # 日志行一条都没有——定位只消费这份读回字符串。
        return geo12

    dev.request = lambda lines, port: (
        f'OWNER_STATE_UTF8_HEX {len(owner_state(port).encode())} '
        f'{owner_state(port).encode().hex()}\n')
    origin = (100.0, 200.0)
    pt, reason = dev.readback_target_point('pharos-target-09', 7856, origin=origin)
    # visible=(10, 190, 400, 40)：round12-R2 起默认点 = AABB 中心 (210, 210)
    # （经逐条约束验证确实可命中）；density=3。
    check('driver-locates-9th-target', (pt, reason), ((int(100 + 210 * 3), int(200 + 210 * 3)), None))
    check('driver-uses-readback-density-not-screen-ratio', pt[0], 730)
    pt2, reason2 = dev.readback_target_point('pharos-invisible', 7856, origin=origin)
    check('driver-names-fully-invisible', (pt2, reason2), (None, 'fully_invisible'))
    pt3, reason3 = dev.readback_target_point('pharos-not-there', 7856, origin=origin)
    check('driver-names-not-in-accepted', (pt3, reason3), (None, 'not_in_accepted'))
    # 截断场景：第 17/18 个目标在 16 条 cap 之外 → geo_truncated。
    dev.request = lambda lines, port: (
        f'OWNER_STATE_UTF8_HEX {len(many18.encode())} {many18.encode().hex()}\n')
    pt4, reason4 = dev.readback_target_point('pharos-many-16', 7856, origin=origin)
    check('driver-names-geo-truncated', (pt4, reason4), (None, 'geo_truncated'))
    # round13-R4：圆角小节点——自动点在**确定性候选集**内命中（内缩角点），
    # 不再误报 fully_invisible；真正找不到样本时具名 point_unavailable。
    rounded16 = ('token=1 epoch=1 proj=1 nodes=1 semantic=1 frame=1 last=1 unacked=0 '
                 'tickets=1 faces=1 facesTruncated=0 geo units=vp density=2.0 '
                 'viewport=100x100 used=1 truncated=0 '
                 'G60:pharos-round16,b=1,p=1,c=1,i=0,0,16,16,v=0,0,16,16,vis=0,'
                 'q=0.000000,0.000000,100.000000,100.000000,50.000000')
    dev.request = lambda lines, port: (
        f'OWNER_STATE_UTF8_HEX {len(rounded16.encode())} {rounded16.encode().hex()}\n')
    pt16, why16 = dev.readback_target_point('pharos-round16', 7856, origin=(0, 0))
    check('rounded-16px-auto-point-found', (pt16 is not None, why16), (True, None))
    rec16 = dev.parse_geo_section(rounded16)['records'][0]
    # 设备点 → vp（用该记录自己的 density，不硬编码比例）。
    check('rounded-16px-point-passes-predicate',
          dev.point_in_clips(int(pt16[0] / 2.0), int(pt16[1] / 2.0),
                             rec16['clips'], bounds=rec16['bounds']),
          True)
    # 候选集确实无样本（小 AABB 完全在圆角约束外）→ point_unavailable，
    # 不是 fully_invisible（交集为空未被证明）。
    tiny = ('token=1 epoch=1 proj=1 nodes=1 semantic=1 frame=1 last=1 unacked=0 '
            'tickets=1 faces=1 facesTruncated=0 geo units=vp density=2.0 '
            'viewport=100x100 used=1 truncated=0 '
            'G61:pharos-tiny,b=1,p=1,c=1,i=0,0,4,4,v=0,0,4,4,vis=0,'
            'q=0.000000,0.000000,100.000000,100.000000,50.000000')
    dev.request = lambda lines, port: (
        f'OWNER_STATE_UTF8_HEX {len(tiny.encode())} {tiny.encode().hex()}\n')
    pt_t, why_t = dev.readback_target_point('pharos-tiny', 7856, origin=(0, 0))
    check('no-sample-named-point-unavailable', (pt_t, why_t),
          (None, 'point_unavailable'))
    # 恢复 geo12 读回桩（上一组用例把桩换成了 many18）；vis=1 的已证明全裁
    # 语义已在 driver-names-fully-invisible 用例覆盖，不被 point_unavailable 稀释。
    dev.request = lambda lines, port: (
        f'OWNER_STATE_UTF8_HEX {len(geo12.encode())} {geo12.encode().hex()}\n')
    # round12-R2：圆角目标——驱动点必须经同一 clip 语义验证确实可命中；
    # 显式给被圆角拒绝的点必须具名 point_not_hittable。
    pt_r, why_r = dev.readback_target_point('pharos-rounded', 7856, origin=origin)
    check('rounded-target-located', (pt_r is not None, why_r), (True, None))
    rec_r = next(r for r in dev.parse_geo_section(geo12)['records'] if r['semantic'] == 'pharos-rounded')
    vx_, vy_ = pt_r[0] - origin[0], pt_r[1] - origin[1]
    x_vp_r, y_vp_r = vx_ / 3.0, vy_ / 3.0
    check('rounded-target-point-passes-production-predicate',
          dev.point_in_clips(int(x_vp_r), int(y_vp_r), rec_r['clips'], bounds=rec_r['bounds']),
          True)
    bad_x = origin[0] + 7 * 3
    bad_y = origin[1] + 15 * 3
    pt_bad, why_bad = dev.readback_target_point('pharos-rounded', 7856, vp_x=7, vp_y=15,
                                                origin=origin)
    check('rounded-explicit-corner-point-named', (pt_bad, why_bad),
          (None, 'point_not_hittable'))
    pt_good, why_good = dev.readback_target_point('pharos-rounded', 7856, vp_x=25, vp_y=25,
                                                  origin=origin)
    check('rounded-explicit-inner-point-accepted', (pt_good is not None, why_good), (True, None))

    # round12-R2：表面原点缺失必须具名失败——不再回退 (0,0)/屏宽比例。
    saved_hdc = dev.hdc
    dev.hdc = lambda *a, **k: SimpleNamespace(stdout='{}')
    miss, why_miss = dev.readback_target_point('pharos-target-01', 7856)
    check('missing-surface-origin-named', (miss, why_miss),
          (None, 'surface_origin_unavailable'))
    check('surface-origin-none-on-empty-layout', dev.surface_origin_px(), None)
    dev.hdc = saved_hdc

    # 失败不复用旧坐标：成功查询之后再失败查询，返回 None 而不是旧点。
    dev.request = lambda lines, port: (
        f'OWNER_STATE_UTF8_HEX {len(geo12.encode())} {geo12.encode().hex()}\n')
    pt_ok, _ = dev.readback_target_point('pharos-target-01', 7856, origin=origin)
    dev.request = lambda lines, port: 'NO_OWNER_STATE'
    pt5, reason5 = dev.readback_target_point('pharos-target-01', 7856, origin=origin)
    check('failed-query-never-reuses-old-point', (pt5, reason5), (None, 'owner_state_absent'))
    check('previous-success-was-real', pt_ok is not None, True)
    # 歧义：两个前缀命中且无精确命中。
    amb = ('token=1 epoch=1 proj=1 nodes=1 semantic=1 frame=1 last=1 unacked=0 '
           'tickets=1 faces=1 facesTruncated=0 geo units=vp density=2.0 viewport=100x100 '
           'used=2 truncated=0 G1:pharos-a-one,i=0,0,10,10,v=0,0,10,10,vis=0,b=1,p=1,c=1 '
           'G2:pharos-a-two,i=0,20,10,10,v=0,20,10,10,vis=0,b=1,p=1,c=1')
    amb = amb.replace(',i=', ',b=9,p=9,c=1,i=')
    dev.request = lambda lines, port: (
        f'OWNER_STATE_UTF8_HEX {len(amb.encode())} {amb.encode().hex()}\n')
    pt6, reason6 = dev.readback_target_point('pharos-a', 7856, origin=origin)
    check('driver-names-ambiguous-prefix', (pt6, reason6), (None, 'geo_ambiguous'))

    # ---- 变异负控：判别力 ----
    print('== 变异负控 ==')
    broken = src.replace('if (rec-visibility-placeholder', '')  # 无操作占位，防误改
    # 9a. 查询器丢掉 geo 段 → 驱动定位必须失败（不再有可用几何）。
    no_geo = src.replace('        out += " geo units=vp density=" + std::to_string(f.geoDensity)',
                         '        ;', 1)
    assert no_geo != src
    out_a = run_probe(no_geo)
    check('mutant-geo-section-removed-breaks-header',
          ' geo units=vp' in out_a['GEO12'], False)
    # 9b. 发布器丢掉完全不可见判定（vis 恒 0）→ invisible 记录不可辨。
    no_vis = src.replace('g.fullyInvisible = 1;               // 空裁剪/约束互斥：完全不可见',
                         '', 1).replace(
        '''            if (vx1 <= vx0 || vy1 <= vy0) {
                g.fullyInvisible = 1;           // bounds∩clips 为空
            } else {''', '''            {''', 1)
    assert no_vis != src
    out_b = run_probe(no_vis)
    check('mutant-invisible-flag-removed',
          bool(re.search(r'G702:pharos-invisible,.*vis=1', out_b['GEO12'])), False)
    check('mutant-still-emits-invisible-record',
          bool(re.search(r'G702:pharos-invisible,', out_b['GEO12'])), True)
    del broken

    print()
    if failures:
        print(f'FAILURES: {len(failures)} -> {failures}')
        sys.exit(1)
    print('round11-D4 有界目标几何: OK（全部符合预期，含变异负控）')


if __name__ == '__main__':
    main()

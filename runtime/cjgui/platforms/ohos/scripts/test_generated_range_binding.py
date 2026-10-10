#!/usr/bin/env python3
"""R3补轮回归（2026-10-02 指导复核）：生成范围会话的**活动绑定**判定。

抽取 snapshot 生成 region 的真实 `bindFieldRangeSessionIfFocused`（与主树同源
文件），用最小窗口替身编译并断言指导反例全部闭合：

  1 正控：A(942/field-A) 首次绑定 binds=1；
  2 同绑定重复聚焦：不重绑（binds 仍 1，组合/选区保留）；
  3 A→B→A：窗口被其他消费方改绑 B(313) 后回 A，必须重绑 A（反例曾 actual=313）；
  4 同 node 换 semantic（accepted 已更新为 replacement-semantic）：真正换绑，
    必须重绑（反例曾沿用旧 field-A）；
  5 迟到旧 FOCUS：accepted 场景已无该节点 → 具名拒绝，不夺走当前会话；
  6 迟到旧 FOCUS：accepted 场景该节点 semantic 与事件不一致 → 拒绝；
  7 关闭/重开（窗口会话已清空，region 记忆仍在）→ 必须重绑；
  8 非 TEXT 字段 / provider 不支持 → 不绑定（行为与之前一致）。

窗口替身如实建模：bindRangeTextSession 释放旧绑定并记录当前绑定；
acceptedSceneNodes 返回当前 accepted 场景；ownedTextSessionBoundNodeId 返回
当前会话节点。负控（变异）：去掉窗口会话检查 → 反例 3 翻红；去掉 memo
semantic 比较 → 反例 4 翻红。
"""
import pathlib
import shutil
import subprocess
import tempfile
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]
REGION = ROOT / "snapshot" / "src" / "composable_ui_generated_region.cj"
CJC = pathlib.Path("/Users/jiangxuanyang/cangjie-toolchains/cangjie-1.1.3/bin/cjc")

HARNESS = r'''
package review
import std.collection.*
let CJGUI_COMPOSABLE_UI_EVENT_FOCUS: Int64 = 31
func generatedRegionDiagLog(value: String): Unit { let _ = value }
class Node {
    public let nodeId: Int64
    public let semanticId: String
    public let nodeKind: Int64
    public let fieldId: String
    public let operationActionName: String
    public let resourceId: Int64
    public let operationResourceId: Int64
    public init(id: Int64, semantic: String, kind: Int64, field: String, writer: String,
        resource: Int64, ownerTarget: Int64) {
        nodeId = id; semanticId = semantic; nodeKind = kind; fieldId = field
        operationActionName = writer; resourceId = resource; operationResourceId = ownerTarget
    }
}
class Field {
    public let fieldId: String
    public let editorKind: String
    public let writeActionName: String
    public let resourceId: Int64
    public init(fieldId: String, editorKind: String, writeActionName: String, resourceId: Int64) {
        this.fieldId = fieldId; this.editorKind = editorKind
        this.writeActionName = writeActionName; this.resourceId = resourceId
    }
}
class Catalog {
    public func fieldFor(id: String): ?Field {
        if (id == "note") { return Some(Field("note", "TEXT", "SET_NOTE", 9801)) }
        if (id == "eco") { return Some(Field("eco", "BOOLEAN", "SET_ECO", 9801)) }
        return None
    }
}
class Binding {
    public var supported = true
    public func rangeTextEditSupported(id: String): Bool { return supported }
}
class CjguiGeneratedFieldRangeSession { public init(b: Binding, id: String) {} }
class SceneNode {
    public let nodeId: Int64
    public let semanticId: String
    public let nodeKind: Int64
    public let resourceId: Int64
    public let fieldId: String
    public let operationActionName: String
    public let operationResourceId: Int64
    public init(n: Node) {
        nodeId = n.nodeId; semanticId = n.semanticId; nodeKind = n.nodeKind
        resourceId = n.resourceId; fieldId = n.fieldId
        operationActionName = n.operationActionName; operationResourceId = n.operationResourceId
    }
}
class Window {
    public var boundNodeId: Int64 = -1
    public var boundSemantic: String = ""
    public var binds: Int64 = 0
    public var scene: ArrayList<SceneNode> = ArrayList<SceneNode>()
    public func acceptedSceneNodes(): ArrayList<SceneNode> { return scene }
    public func ownedTextSessionBoundNodeId(): Int64 { return boundNodeId }
    public func bindRangeTextSession(id: Int64, semanticId: String,
        source: CjguiGeneratedFieldRangeSession, sink: CjguiGeneratedFieldRangeSession,
        resource: Int64, kind: Int64): Int64 {
        boundNodeId = id; boundSemantic = semanticId; binds += 1
        return binds
    }
}
class CjguiComposableUiEvent {
    public let node: Node
    public let eventKind: Int64 = 31
    public init(n: Node) { node = n }
}
class Gate {
    private let catalog = Catalog()
    public let binding = Binding()
    private let attachedWindow: ?Window
    private var rangeSessionNodeId: Int64 = -1
    private var rangeSessionSemanticId: String = ""
    private var rangeSessionNodeKind: Int64 = -1
    private var rangeSessionFieldId: String = ""
    private var rangeSessionWriterOperation: String = ""
    private var rangeSessionFieldResource: Int64 = -1
    private var rangeSessionOwnerTarget: Int64 = -1
    public init(window: Window) { attachedWindow = Some(window) }
    public func focus(node: Node): Unit { bindFieldRangeSessionIfFocused(CjguiComposableUiEvent(node)) }
__PRODUCTION_METHOD__
}
main(): Int64 {
    let w = Window()
    let g = Gate(w)
    let a = Node(942, "field-A", 7, "note", "SET_NOTE", 9801, 9801)
    w.scene.add(SceneNode(a))
    g.focus(a)
    if (w.boundNodeId != 942 || w.binds != 1) { return 1 }          // 正控首绑
    g.focus(a)
    if (w.binds != 1) { return 2 }                                   // 重复聚焦不重绑
    // A→B→A：其他消费方直接改绑 B（窗口会话换走），回 A 必须重绑。
    let b = CjguiGeneratedFieldRangeSession(Binding(), "other")
    let _ = w.bindRangeTextSession(313, "other-owner", b, b, 123, 7)
    g.focus(a)
    if (w.boundNodeId != 942 || w.binds != 3) { return 3 }           // 反例曾 actual=313
    // 同 node 换 semantic：accepted 已更新为新语义，必须重绑。
    let rebound = Node(942, "replacement-semantic", 7, "note", "SET_NOTE", 9801, 9801)
    w.scene = ArrayList<SceneNode>()
    w.scene.add(SceneNode(rebound))
    g.focus(rebound)
    if (w.boundSemantic != "replacement-semantic" || w.binds != 4) { return 4 }  // 反例曾 field-A
    // 迟到旧 FOCUS：accepted 已无该节点（节点移除）。
    let stale = Node(942, "replacement-semantic", 7, "note", "SET_NOTE", 9801, 9801)
    w.scene = ArrayList<SceneNode>()
    let beforeStale = w.binds
    g.focus(stale)
    if (w.binds != beforeStale) { return 5 }
    // 迟到旧 FOCUS：accepted 语义与事件不一致（事件携带旧语义）。
    let current = Node(942, "current-semantic", 7, "note", "SET_NOTE", 9801, 9801)
    w.scene.add(SceneNode(current))
    let oldEcho = Node(942, "replacement-semantic", 7, "note", "SET_NOTE", 9801, 9801)
    g.focus(oldEcho)
    if (w.binds != beforeStale) { return 6 }
    // 关闭/重开：窗口会话清空（-1），region 记忆仍在 → 必须重绑。
    w.boundNodeId = -1
    g.focus(current)
    if (w.boundNodeId != 942 || w.binds != beforeStale + 1) { return 7 }
    // 非 TEXT 字段 / provider 不支持：不绑定。
    let w2 = Window()
    let g2 = Gate(w2)
    g2.binding.supported = false
    let eco = Node(55, "eco-editor", 7, "eco", "SET_ECO", 9801, 9801)
    w2.scene.add(SceneNode(eco))
    g2.focus(eco)
    if (w2.binds != 0) { return 8 }
    println("ok")
    return 0
}
'''


def build_harness(source, mutation=None):
    start = source.index('    private func bindFieldRangeSessionIfFocused(')
    end = source.index('\n    public func capabilitiesPayload()', start)
    method = source[start:end]
    if mutation:
        old, new = mutation
        assert old in method, mutation[0][:60]
        method = method.replace(old, new, 1)
    return HARNESS.replace('__PRODUCTION_METHOD__', method)


class GeneratedRangeBindingTest(unittest.TestCase):
    def run_harness(self, text):
        with tempfile.TemporaryDirectory(prefix='cjgui-range-bind-') as d:
            src = pathlib.Path(d) / 'binding.cj'
            exe = pathlib.Path(d) / 'binding'
            src.write_text(text)
            # cjc 链接与产物运行都依赖 envsetup 的运行库路径，同一 bash 环境内完成。
            cmd = (f'source /Users/jiangxuanyang/cangjie-toolchains/cangjie-1.1.3/envsetup.sh >/dev/null 2>&1 && '
                   f'cjc {src} -Woff all -o {exe} && {exe}')
            run = subprocess.run(['bash', '-c', cmd], capture_output=True, text=True)
            # 编译失败时 stderr 带 cjc 诊断；运行失败时返回码即用例号。
            return run.returncode, run.stdout + run.stderr

    def test_binding_counterexamples_closed(self):
        rc, out = self.run_harness(build_harness(REGION.read_text()))
        self.assertEqual(rc, 0, out)

    def test_negative_without_window_session_check(self):
        source = REGION.read_text()
        old = ('if (window.ownedTextSessionBoundNodeId() == node.nodeId &&\n'
               '            rangeSessionNodeId == node.nodeId')
        new = ('if (true &&\n            rangeSessionNodeId == node.nodeId')
        rc, out = self.run_harness(build_harness(source, (old, new)))
        self.assertNotEqual(rc, 0, 'A->B->A counterexample escaped: ' + out)

    def test_negative_without_memo_semantic_comparison(self):
        source = REGION.read_text()
        old = 'rangeSessionNodeId == node.nodeId && rangeSessionSemanticId == node.semanticId &&\n            rangeSessionNodeKind == node.nodeKind'
        new = 'rangeSessionNodeId == node.nodeId && rangeSessionSemanticId == rangeSessionSemanticId &&\n            rangeSessionNodeKind == node.nodeKind'
        rc, out = self.run_harness(build_harness(source, (old, new)))
        self.assertNotEqual(rc, 0, 'semantic rebind counterexample escaped: ' + out)


if __name__ == '__main__':
    unittest.main()

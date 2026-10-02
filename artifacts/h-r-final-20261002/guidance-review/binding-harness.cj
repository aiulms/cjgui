
package review
let CJGUI_COMPOSABLE_UI_EVENT_FOCUS: Int64 = 31
func internalRendererWindowLog(value: String): Unit { let _ = value }
class Node {
    public let nodeId: Int64
    public let semanticId: String
    public let nodeKind: Int64
    public let fieldId = "note"
    public let operationActionName = "SET_NOTE"
    public let resourceId: Int64 = 9801
    public let operationResourceId: Int64 = 9801
    public init(id: Int64, semantic: String, kind: Int64) {
        nodeId = id; semanticId = semantic; nodeKind = kind
    }
}
class Field {
    public let fieldId = "note"
    public let editorKind = "TEXT"
    public let writeActionName = "SET_NOTE"
    public let resourceId: Int64 = 9801
}
class Catalog { public func fieldFor(id: String): ?Field { return Some(Field()) } }
class Binding { public func rangeTextEditSupported(id: String): Bool { return true } }
class CjguiGeneratedFieldRangeSession { public init(b: Binding, id: String) {} }
class Window {
    public var node: Int64 = -1
    public var semantic: String = ""
    public var binds: Int64 = 0
    public func bindRangeTextSession(id: Int64, semanticId: String,
        source: CjguiGeneratedFieldRangeSession, sink: CjguiGeneratedFieldRangeSession,
        resource: Int64, kind: Int64): Int64 {
        node = id; semantic = semanticId; binds += 1
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
    private let binding = Binding()
    private let attachedWindow: ?Window
    private var rangeSessionNodeId: Int64 = -1
    private var rangeSessionFieldId: String = ""
    private var rangeSessionWriterOperation: String = ""
    private var rangeSessionFieldResource: Int64 = -1
    public init(window: Window) { attachedWindow = Some(window) }
    public func focus(node: Node): Unit { bindFieldRangeSessionIfFocused(CjguiComposableUiEvent(node)) }
    private func bindFieldRangeSessionIfFocused(event: CjguiComposableUiEvent): Unit {
        if (event.eventKind != CJGUI_COMPOSABLE_UI_EVENT_FOCUS) {
            return
        }
        let node = event.node
        if (node.fieldId.size == 0) {
            return
        }
        let window = match (attachedWindow) {
            case Some(value) => value
            case None => return
        }
        if (catalog.fieldFor(node.fieldId).isNone()) {
            internalRendererWindowLog(
                "GEN_RANGE_BIND_SKIP node=${node.nodeId} field=${node.fieldId} reason=unknown_field")
            return
        }
        let field = match (catalog.fieldFor(node.fieldId)) {
            case Some(value) => value
            case None => return
        }
        // 与 resolveIntent 的 ordinary 路径同一套身份核对：事件节点的绑定事实
        // 必须与当前字段声明一致，换绑/迟到的旧节点不给新 owner 绑会话。
        if (field.editorKind != "TEXT" || field.writeActionName.size == 0 ||
            node.operationActionName != field.writeActionName ||
            node.resourceId != field.resourceId || node.operationResourceId < 0) {
            internalRendererWindowLog("GEN_RANGE_BIND_SKIP node=${node.nodeId} field=${node.fieldId} " +
                "reason=binding_mismatch editor=${field.editorKind} writer=${field.writeActionName} " +
                "nodeWriter=${node.operationActionName} fieldRes=${field.resourceId} nodeRes=${node.resourceId} " +
                "ownerTarget=${node.operationResourceId}")
            return
        }
        if (!binding.rangeTextEditSupported(field.fieldId)) {
            internalRendererWindowLog("GEN_RANGE_BIND_SKIP node=${node.nodeId} field=${node.fieldId} " +
                "reason=provider_unsupported")
            return
        }
        if (rangeSessionNodeId == node.nodeId && rangeSessionFieldId == field.fieldId &&
            rangeSessionWriterOperation == field.writeActionName &&
            rangeSessionFieldResource == field.resourceId) {
            return // 同一绑定的重复聚焦：不推进会话代次
        }
        let session = CjguiGeneratedFieldRangeSession(binding, field.fieldId)
        let _ = window.bindRangeTextSession(node.nodeId, node.semanticId, session, session,
            field.resourceId, node.nodeKind)
        rangeSessionNodeId = node.nodeId
        rangeSessionFieldId = field.fieldId
        rangeSessionWriterOperation = field.writeActionName
        rangeSessionFieldResource = field.resourceId
    }

}
main(): Int64 {
    let w = Window()
    let g = Gate(w)
    let a = Node(942, "field-A", 7)
    g.focus(a)
    println("positive_initial_node=${w.node} binds=${w.binds}")
    g.focus(a)
    println("positive_idempotent_binds=${w.binds}")
    let b = CjguiGeneratedFieldRangeSession(Binding(), "other")
    let _ = w.bindRangeTextSession(313, "other-owner", b, b, 123, 7)
    g.focus(a)
    println("return_to_A_expected=942 actual=${w.node} binds=${w.binds}")
    let w2 = Window()
    let g2 = Gate(w2)
    g2.focus(a)
    g2.focus(Node(942, "replacement-semantic", 7))
    println("semantic_rebind_expected=replacement-semantic actual=${w2.semantic} binds=${w2.binds}")
    return 0
}

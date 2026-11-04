package cjgui

import cjgui_shared_operation_core.*
import std.collection.*
import std.env.*
import std.runtime.*
import std.time.*
import std.unittest.*
import std.unittest.testmacro.*

private class TransferBindingCostController <: CjguiComposableUiController & CjguiComposableUiDataTransferProvider {
    let declarations: ArrayList<CjguiComposableUiDataTransferDeclaration>
    init(declarations: ArrayList<CjguiComposableUiDataTransferDeclaration>) {
        this.declarations = declarations
    }
    public func uiSceneVersion(): Int64 { return 1 }
    public func buildUi(): CjguiComposableUiNode {
        return cjguiComposableVertical(1, "transfer-binding-root", CjguiComposableUiStyle())
    }
    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        let _ = event
        return CjguiComposableUiDispatchResult(false)
    }
    public func rejectUiEvent(kind: Int64, node: Int64): CjguiComposableUiDispatchResult {
        let _ = kind; let _ = node
        return CjguiComposableUiDispatchResult(false)
    }
    public func requestWindowClose(): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(true, shouldClose: true)
    }
    public func dataTransferDeclarations(): ArrayList<CjguiComposableUiDataTransferDeclaration> {
        return ArrayList<CjguiComposableUiDataTransferDeclaration>(declarations)
    }
    public func applyDataTransfer(event: CjguiComposableUiDataTransferEvent): CjguiComposableUiDispatchResult {
        let _ = event
        return CjguiComposableUiDispatchResult(false)
    }
}

private func transferBindingCostNode(id: Int64, semantic: String, enabled!: Bool = true,
    readOnly!: Bool = false): CjguiComposableUiLayoutNode {
    let rect = CjguiComposableUiRect(0, id, 120, 1)
    let kind = if (readOnly) { CJGUI_COMPOSABLE_UI_TEXT_INPUT } else { CJGUI_COMPOSABLE_UI_BUTTON }
    let node = CjguiComposableUiNode(id, semantic, kind, "", "", "PRESS", id,
        CjguiComposableUiStyle(fixedHeight: 1), enabled: enabled, readOnly: readOnly)
    return CjguiComposableUiLayoutNode(node, rect, rect)
}

private func transferBindingCostScene(nodes: ArrayList<CjguiComposableUiLayoutNode>): CjguiComposableUiScene {
    return CjguiComposableUiScene(1, CjguiComposableUiRect(0, 0, 120, 1024), nodes)
}

private func transferBindingCostDeclaration(semantic: String): CjguiComposableUiDataTransferDeclaration {
    return CjguiComposableUiDataTransferDeclaration.target(semantic,
        CjguiSharedOperationTransferFormat.utf8Text())
}

// Exercise the real candidate binder at the production scene ceiling, without
// native rendering or a timing threshold. Live-heap growth plus collected
// bytes bounds allocation even when GC runs during the call. Fixture creation
// and one warm call stay outside the measured interval in both candidates.
@Test
func transferBindingMaximumSceneKeepsAllocationBounded(): Unit {
    let nodes = ArrayList<CjguiComposableUiLayoutNode>()
    for (index in 1..1025) { nodes.add(transferBindingCostNode(index, "transfer-binding-${index}")) }
    let scene = transferBindingCostScene(nodes)
    let controller = TransferBindingCostController(ArrayList<CjguiComposableUiDataTransferDeclaration>([
        transferBindingCostDeclaration("transfer-binding-1023"),
        transferBindingCostDeclaration("transfer-binding-1024")]))
    let window = CjguiComposableUiWindow(controller)
    @Assert(window.dataTransferBindingsFor(scene).getOrThrow().size, 2)
    gc(heavy: true)
    var allocationBounded = true
    for (sample in 0..5) {
        let freedBefore = getGCFreedSize()
        let heapBefore = getAllocatedHeapSize()
        let started = MonoTime.now()
        let bindings = window.dataTransferBindingsFor(scene).getOrThrow()
        let elapsed = (MonoTime.now() - started).toNanoseconds()
        let heapAfter = getAllocatedHeapSize()
        let freedAfter = getGCFreedSize()
        let allocated = heapAfter - heapBefore + freedAfter - freedBefore
        @Assert(bindings.size, 2)
        @Assert(bindings[0].node.nodeId, 1023)
        @Assert(bindings[1].node.nodeId, 1024)
        getStdOut().writeln("CJGUI_TRANSFER_BINDING_COST nodes=1024 declarations=2 sample=${sample} " +
            "elapsed_ns=${elapsed} allocation_bytes=${allocated}")
        allocationBounded = allocationBounded && allocated >= 0 && allocated <= 4 * 1024 * 1024
    }
    @Assert(allocationBounded, true)
}

@Test
func transferBindingEmptyDeclarationKeepsAllocationConstant(): Unit {
    let nodes = ArrayList<CjguiComposableUiLayoutNode>()
    for (index in 1..1025) { nodes.add(transferBindingCostNode(index, "empty-transfer-${index}")) }
    let scene = transferBindingCostScene(nodes)
    let controller = TransferBindingCostController(ArrayList<CjguiComposableUiDataTransferDeclaration>())
    let window = CjguiComposableUiWindow(controller)
    @Assert(window.dataTransferBindingsFor(scene).getOrThrow().isEmpty(), true)
    gc(heavy: true)
    let freedBefore = getGCFreedSize()
    let heapBefore = getAllocatedHeapSize()
    let bindings = window.dataTransferBindingsFor(scene).getOrThrow()
    let heapAfter = getAllocatedHeapSize()
    let freedAfter = getGCFreedSize()
    let allocated = heapAfter - heapBefore + freedAfter - freedBefore
    @Assert(bindings.isEmpty(), true)
    getStdOut().writeln("CJGUI_TRANSFER_BINDING_EMPTY_COST nodes=1024 declarations=0 allocation_bytes=${allocated}")
    // No offer must remain constant-cost even at the production scene limit.
    // The allowance covers scalar/list bookkeeping, but not a scene copy.
    @Assert(allocated >= 0 && allocated <= 4096, true)
}

@Test
func transferBindingSnapshotPreservesCandidateRejections(): Unit {
    let declaration = transferBindingCostDeclaration("target")
    let controller = TransferBindingCostController(ArrayList<CjguiComposableUiDataTransferDeclaration>([declaration]))
    let window = CjguiComposableUiWindow(controller)
    let enabled = transferBindingCostNode(1, "target")
    let accepted = window.dataTransferBindingsFor(transferBindingCostScene(
        ArrayList<CjguiComposableUiLayoutNode>([enabled]))).getOrThrow()
    @Assert(accepted.size, 1)
    @Assert(accepted[0].node.nodeId, 1)
    @Assert(accepted[0].bindingEpoch > 0u64, true)
    @Assert(accepted[0].nativeFormat, "text/plain")
    @Assert(window.dataTransferBindingsFor(transferBindingCostScene(
        ArrayList<CjguiComposableUiLayoutNode>([enabled, transferBindingCostNode(2, "target")]))).isNone(), true)
    @Assert(window.dataTransferBindingsFor(transferBindingCostScene(
        ArrayList<CjguiComposableUiLayoutNode>([transferBindingCostNode(1, "other")]))).isNone(), true)
    @Assert(window.dataTransferBindingsFor(transferBindingCostScene(
        ArrayList<CjguiComposableUiLayoutNode>([transferBindingCostNode(1, "target", enabled: false)])))
        .getOrThrow().size, 0)
    @Assert(window.dataTransferBindingsFor(transferBindingCostScene(
        ArrayList<CjguiComposableUiLayoutNode>([transferBindingCostNode(1, "target", readOnly: true)]))).isNone(), true)
    controller.declarations.add(declaration)
    @Assert(window.dataTransferBindingsFor(transferBindingCostScene(
        ArrayList<CjguiComposableUiLayoutNode>([enabled]))).isNone(), true)
}

// Test-only cross-window drag probe. Two production Cangjie windows are
// opened side by side (the normal layout keeps them disjoint): window A
// declares a transfer source, window B declares the target. The verifier
// performs a REAL mouse drag between them; this probe only waits and then
// reports what the target owner received. It is linked against the
// CJGUI_INTERNAL_TESTING renderer like the window-integration probe, but the
// drag session itself is the operating system's.
package cjgui

import cjgui_shared_operation_core.*
import std.collection.*
import std.env.*
import std.overflow.*
import std.time.*

private let CROSS_DOCUMENT_ID_A: Int64 = 7401
private let CROSS_DOCUMENT_ID_B: Int64 = 7402
private let CROSS_SOURCE_NODE: Int64 = 13
private let CROSS_TARGET_NODE: Int64 = 14

private class CrossWindowController <: CjguiComposableUiController & CjguiComposableUiDataTransferProvider {
    private let workspace: CjguiTextDocumentWorkspace
    private let documentId: Int64
    private var revision: Int64
    private var sourcePayload: String
    var accepted: Int64
    var rejected: Int64

    init(workspace: CjguiTextDocumentWorkspace, documentId: Int64) {
        this.workspace = workspace
        this.documentId = documentId
        this.revision = 1
        this.sourcePayload = ""
        this.accepted = 0
        this.rejected = 0
    }

    public func uiSceneVersion(): Int64 {
        return workspace.contextSnapshot().version.saturatingAdd(revision)
    }

    public func buildUi(): CjguiComposableUiNode {
        let root = cjguiComposableVertical(1, "cross-transfer-root",
            CjguiComposableUiStyle(padding: 12, gap: 8))
        root.add(cjguiComposableText(2, "cross-transfer-title", "跨窗传输",
            CjguiComposableUiStyle(fontSize: 15.0)))
        root.add(cjguiComposableButton(CROSS_SOURCE_NODE, "cross-transfer-source",
            "拖动源", "TRANSFER_COPY", documentId,
            CjguiComposableUiStyle(fixedHeight: 32), enabled: sourcePayload.size > 0))
        root.add(cjguiComposableButton(CROSS_TARGET_NODE, "cross-transfer-target",
            "拖动目标", "TRANSFER_DROP", documentId,
            CjguiComposableUiStyle(fixedHeight: 32), enabled: true))
        return root
    }

    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(false)
    }

    public func rejectUiEvent(eventKind: Int64, nodeId: Int64): CjguiComposableUiDispatchResult {
        rejected += 1
        revision += 1
        return CjguiComposableUiDispatchResult(false)
    }

    public func requestWindowClose(): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(true, shouldClose: true)
    }

    public func dataTransferDeclarations(): ArrayList<CjguiComposableUiDataTransferDeclaration> {
        let declarations = ArrayList<CjguiComposableUiDataTransferDeclaration>()
        if (sourcePayload.size > 0) {
            if (let Some(offer) <- CjguiSharedOperationTransferOffer.create(
                "COPY", "cross_source_window", "cross-source-session", documentId,
                CjguiSharedOperationTransferFormat.utf8Text(), sourcePayload)) {
                declarations.add(CjguiComposableUiDataTransferDeclaration.source(
                    "cross-transfer-source", offer))
            }
        }
        declarations.add(CjguiComposableUiDataTransferDeclaration.target(
            "cross-transfer-target", CjguiSharedOperationTransferFormat.utf8Text()))
        return declarations
    }

    public func applyDataTransfer(event: CjguiComposableUiDataTransferEvent): CjguiComposableUiDispatchResult {
        if (event.eventKind == CJGUI_COMPOSABLE_UI_EVENT_DATA_TRANSFER_COPY) {
            revision += 1
            return CjguiComposableUiDispatchResult(true)
        }
        if (event.eventKind != CJGUI_COMPOSABLE_UI_EVENT_DATA_TRANSFER_DROP ||
            event.node.nodeId != CROSS_TARGET_NODE || event.format.kind != "UTF8_TEXT") {
            rejected += 1
            revision += 1
            return CjguiComposableUiDispatchResult(false)
        }
        let snapshot = workspace.documentSnapshot(documentId)
        let length = if (let Some(value) <- snapshot) {
            value.content.size
        } else {
            0
        }
        let result = workspace.acceptTextTransferFromHuman(documentId,
            CjguiTextDocumentRange(length, length), event.offer)
        if (result.applied) {
            accepted += 1
            revision += 1
            return CjguiComposableUiDispatchResult(true)
        }
        rejected += 1
        revision += 1
        return CjguiComposableUiDispatchResult(false)
    }

    public func setSourcePayload(payload: String): Unit {
        sourcePayload = payload
        revision += 1
    }
}

private func contentOf(workspace: CjguiTextDocumentWorkspace, documentId: Int64): String {
    if (let Some(snapshot) <- workspace.documentSnapshot(documentId)) {
        return snapshot.content
    }
    return ""
}

main(): Int64 {
    let workspaceA = CjguiTextDocumentWorkspace(ArrayList<CjguiTextDocument>([
        CjguiTextDocument(CROSS_DOCUMENT_ID_A, "源", "源文档")
    ]))
    let workspaceB = CjguiTextDocumentWorkspace(ArrayList<CjguiTextDocument>([
        CjguiTextDocument(CROSS_DOCUMENT_ID_B, "目标", "目标:")
    ]))
    let controllerA = CrossWindowController(workspaceA, CROSS_DOCUMENT_ID_A)
    let controllerB = CrossWindowController(workspaceB, CROSS_DOCUMENT_ID_B)
    let windowA = CjguiComposableUiWindow(controllerA)
    let windowB = CjguiComposableUiWindow(controllerB)
    if (!windowA.start() || !windowB.start()) {
        windowA.close()
        windowB.close()
        return 2
    }
    controllerA.setSourcePayload("CROSS-WINDOW-PAYLOAD")
    if (!windowA.refresh() || !windowB.refresh()) {
        windowA.close()
        windowB.close()
        return 2
    }
    println("CJGUI_CROSS_WINDOW_READY a=${windowA.testSessionToken()} b=${windowB.testSessionToken()}")
    getStdOut().flush()
    // The verifier performs the real mouse drag while this probe waits.
    let started = MonoTime.now()
    while ((MonoTime.now() - started).toNanoseconds() < 25_000_000_000 && controllerB.accepted == 0) {
        let _ = windowA.pump(0u32)
        let _ = windowB.pump(0u32)
        sleep(Duration.millisecond * 8)
    }
    let contentB = contentOf(workspaceB, CROSS_DOCUMENT_ID_B)
    let contentA = contentOf(workspaceA, CROSS_DOCUMENT_ID_A)
    let passed = (controllerB.accepted == 1 && contentB == "目标:CROSS-WINDOW-PAYLOAD") ||
        (controllerA.accepted == 1 && contentA == "源文档CROSS-WINDOW-PAYLOAD")
    println("CJGUI_CROSS_WINDOW_RESULT accepted_b=${controllerB.accepted} accepted_a=${controllerA.accepted} " +
        "content_b=${contentB} content_a=${contentA} passed=${passed}")
    getStdOut().flush()
    windowA.close()
    windowB.close()
    return if (passed) { 0 } else { 1 }
}

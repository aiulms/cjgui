package cjgui_ui_only_starter

import cjgui.*
import cjgui_shared_operation_core.*
import std.collection.*
import std.env.*
import std.time.*

// This source is copied only after the framework preview is exported and
// relocated. It intentionally uses only the public value/controller/window
// surface. The verifier drives the visible windows through AppKit events;
// this process only pumps the normal application FIFO and reads projections.

private let PREVIEW_TEXT_FORMAT = CjguiSharedOperationTransferFormat.utf8Text(maximumBytes: 64)
private let PREVIEW_STRUCTURED_FORMAT = CjguiSharedOperationTransferFormat.structured(
    "application/vnd.cjgui.preview.transfer.record", maximumBytes: 64)

private class PreviewTransferReadback {
    var sourceTextCopies: Int64 = 0
    var sourceStructuredCopies: Int64 = 0
    var targetExternalTextPastes: Int64 = 0
    var targetStructuredPastes: Int64 = 0
    var targetStructuredDrops: Int64 = 0
    var rejectedEvents: Int64 = 0
    var textValue: String = ""
    var structuredValue: String = ""
    var lastTargetSession: String = ""
}

private class PreviewTransferSourceOwner <: CjguiComposableUiController & CjguiComposableUiDataTransferProvider {
    private let readback: PreviewTransferReadback
    private var revision: Int64 = 1

    init(readback: PreviewTransferReadback) { this.readback = readback }

    public func uiSceneVersion(): Int64 { return revision }

    public func buildUi(): CjguiComposableUiNode {
        let root = cjguiComposableVertical(1, "preview-transfer-source-root",
            CjguiComposableUiStyle(padding: 16, gap: 10))
        root.add(cjguiComposableText(2, "preview-transfer-source-title", "传输源窗口",
            CjguiComposableUiStyle(fixedHeight: 24)))
        root.add(cjguiComposableButton(3, "preview-transfer-source-text", "文本源（64 字节上限）",
            "TRANSFER_COPY", 21, CjguiComposableUiStyle(fixedHeight: 32)))
        root.add(cjguiComposableButton(4, "preview-transfer-source-structured", "结构化源",
            "TRANSFER_COPY", 22, CjguiComposableUiStyle(fixedHeight: 32)))
        return root
    }

    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        let _ = event
        return CjguiComposableUiDispatchResult(false)
    }

    public func rejectUiEvent(eventKind: Int64, nodeId: Int64): CjguiComposableUiDispatchResult {
        let _ = eventKind
        let _ = nodeId
        readback.rejectedEvents += 1
        return CjguiComposableUiDispatchResult(false)
    }

    public func requestWindowClose(): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(true, shouldClose: true)
    }

    public func dataTransferDeclarations(): ArrayList<CjguiComposableUiDataTransferDeclaration> {
        let declarations = ArrayList<CjguiComposableUiDataTransferDeclaration>()
        if (let Some(textOffer) <- CjguiSharedOperationTransferOffer.create(
            "COPY", "preview_source_window", "preview-source-session", 21, PREVIEW_TEXT_FORMAT,
            "source-text")) {
            declarations.add(CjguiComposableUiDataTransferDeclaration.source(
                "preview-transfer-source-text", textOffer))
        }
        if (let Some(structuredOffer) <- CjguiSharedOperationTransferOffer.create(
            "COPY", "preview_source_window", "preview-source-session", 22, PREVIEW_STRUCTURED_FORMAT,
            "record-42")) {
            declarations.add(CjguiComposableUiDataTransferDeclaration.source(
                "preview-transfer-source-structured", structuredOffer))
        }
        return declarations
    }

    public func applyDataTransfer(event: CjguiComposableUiDataTransferEvent): CjguiComposableUiDispatchResult {
        if (event.eventKind != CJGUI_COMPOSABLE_UI_EVENT_DATA_TRANSFER_COPY ||
            event.offer.sourceKind != "preview_source_window" ||
            event.offer.sourceIdentity != "preview-source-session") {
            readback.rejectedEvents += 1
            return CjguiComposableUiDispatchResult(false)
        }
        if (event.node.semanticId == "preview-transfer-source-text" &&
            event.format.identifier == PREVIEW_TEXT_FORMAT.identifier && event.offer.payload == "source-text") {
            readback.sourceTextCopies += 1
            return CjguiComposableUiDispatchResult(true)
        }
        if (event.node.semanticId == "preview-transfer-source-structured" &&
            event.format.identifier == PREVIEW_STRUCTURED_FORMAT.identifier && event.offer.payload == "record-42") {
            readback.sourceStructuredCopies += 1
            return CjguiComposableUiDispatchResult(true)
        }
        readback.rejectedEvents += 1
        return CjguiComposableUiDispatchResult(false)
    }
}

private class PreviewTransferTargetOwner <: CjguiComposableUiController & CjguiComposableUiDataTransferProvider {
    private let readback: PreviewTransferReadback
    private var revision: Int64 = 1

    init(readback: PreviewTransferReadback) { this.readback = readback }

    public func uiSceneVersion(): Int64 { return revision }

    public func buildUi(): CjguiComposableUiNode {
        let root = cjguiComposableVertical(11, "preview-transfer-target-root",
            CjguiComposableUiStyle(padding: 16, gap: 10))
        root.add(cjguiComposableText(12, "preview-transfer-target-title", "传输目标窗口",
            CjguiComposableUiStyle(fixedHeight: 24)))
        root.add(cjguiComposableButton(13, "preview-transfer-target-text", "接收文本",
            "TRANSFER_PASTE", 31, CjguiComposableUiStyle(fixedHeight: 32)))
        root.add(cjguiComposableButton(14, "preview-transfer-target-structured", "接收结构化记录",
            "TRANSFER_PASTE", 32, CjguiComposableUiStyle(fixedHeight: 32)))
        return root
    }

    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        let _ = event
        return CjguiComposableUiDispatchResult(false)
    }

    public func rejectUiEvent(eventKind: Int64, nodeId: Int64): CjguiComposableUiDispatchResult {
        let _ = eventKind
        let _ = nodeId
        readback.rejectedEvents += 1
        return CjguiComposableUiDispatchResult(false)
    }

    public func requestWindowClose(): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(true, shouldClose: true)
    }

    public func dataTransferDeclarations(): ArrayList<CjguiComposableUiDataTransferDeclaration> {
        return ArrayList<CjguiComposableUiDataTransferDeclaration>([
            CjguiComposableUiDataTransferDeclaration.target(
                "preview-transfer-target-text", PREVIEW_TEXT_FORMAT),
            CjguiComposableUiDataTransferDeclaration.target(
                "preview-transfer-target-structured", PREVIEW_STRUCTURED_FORMAT)
        ])
    }

    public func applyDataTransfer(event: CjguiComposableUiDataTransferEvent): CjguiComposableUiDispatchResult {
        if ((event.eventKind != CJGUI_COMPOSABLE_UI_EVENT_DATA_TRANSFER_PASTE &&
            event.eventKind != CJGUI_COMPOSABLE_UI_EVENT_DATA_TRANSFER_DROP) ||
            event.node.semanticId.size == 0) {
            readback.rejectedEvents += 1
            return CjguiComposableUiDispatchResult(false)
        }
        let targetProjection = event.node.semanticId
        if (targetProjection == "preview-transfer-target-text" &&
            event.format.identifier == PREVIEW_TEXT_FORMAT.identifier &&
            PREVIEW_TEXT_FORMAT.acceptsPayload(event.offer.payload) &&
            event.offer.payload == "external-text") {
            if (event.offer.sourceKind != "external_pasteboard" || event.offer.sourceIdentity != "macos") {
                readback.rejectedEvents += 1
                return CjguiComposableUiDispatchResult(false)
            }
            readback.targetExternalTextPastes += 1
            readback.textValue = event.offer.payload
            readback.lastTargetSession = "target-window"
            revision += 1
            return CjguiComposableUiDispatchResult(true)
        }
        if (targetProjection == "preview-transfer-target-structured" &&
            event.format.identifier == PREVIEW_STRUCTURED_FORMAT.identifier &&
            PREVIEW_STRUCTURED_FORMAT.acceptsPayload(event.offer.payload) &&
            event.offer.payload == "record-42" &&
            event.offer.sourceKind == "preview_source_window" &&
            event.offer.sourceIdentity == "preview-source-session" && event.offer.sourceId == 22) {
            if (event.eventKind == CJGUI_COMPOSABLE_UI_EVENT_DATA_TRANSFER_DROP) {
                readback.targetStructuredDrops += 1
            } else {
                readback.targetStructuredPastes += 1
            }
            readback.structuredValue = event.offer.payload
            readback.lastTargetSession = "target-window"
            revision += 1
            return CjguiComposableUiDispatchResult(true)
        }
        readback.rejectedEvents += 1
        return CjguiComposableUiDispatchResult(false)
    }
}

/// A declared endpoint may be temporarily unavailable without invalidating the
/// rest of an ordinary scene. This probe keeps the declaration present while
/// its only target is disabled, so the public window acceptance path must
/// retain a healthy projection but stage no actionable transfer endpoint.
private class PreviewDisabledTransferTargetOwner <: CjguiComposableUiController & CjguiComposableUiDataTransferProvider {
    private var revision: Int64 = 1
    private var targetEnabled: Bool = true
    private var transferEventsWhileDisabled: Int64 = 0
    private var acceptedTransferEvents: Int64 = 0

    public func uiSceneVersion(): Int64 { return revision }

    func disableTarget(): Unit {
        targetEnabled = false
        revision += 1
    }

    func enableTarget(): Unit {
        targetEnabled = true
        revision += 1
    }

    func disabledTransferEventCount(): Int64 { return transferEventsWhileDisabled }

    func acceptedTransferEventCount(): Int64 { return acceptedTransferEvents }

    public func buildUi(): CjguiComposableUiNode {
        let root = cjguiComposableVertical(21, "preview-disabled-transfer-root",
            CjguiComposableUiStyle(padding: 16, gap: 10))
        root.add(cjguiComposableText(22, "preview-disabled-transfer-title", "禁用传输目标",
            CjguiComposableUiStyle(fixedHeight: 24)))
        root.add(cjguiComposableButton(23, "preview-disabled-transfer-target", "暂不可接收",
            "TRANSFER_PASTE", 41, CjguiComposableUiStyle(fixedHeight: 32), enabled: targetEnabled))
        return root
    }

    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        let _ = event
        return CjguiComposableUiDispatchResult(false)
    }

    public func rejectUiEvent(eventKind: Int64, nodeId: Int64): CjguiComposableUiDispatchResult {
        let _ = eventKind
        let _ = nodeId
        return CjguiComposableUiDispatchResult(false)
    }

    public func requestWindowClose(): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(true, shouldClose: true)
    }

    public func dataTransferDeclarations(): ArrayList<CjguiComposableUiDataTransferDeclaration> {
        return ArrayList<CjguiComposableUiDataTransferDeclaration>([
            CjguiComposableUiDataTransferDeclaration.target(
                "preview-disabled-transfer-target", PREVIEW_TEXT_FORMAT)
        ])
    }

    public func applyDataTransfer(event: CjguiComposableUiDataTransferEvent): CjguiComposableUiDispatchResult {
        if (event.eventKind != CJGUI_COMPOSABLE_UI_EVENT_DATA_TRANSFER_PASTE ||
            event.node.semanticId != "preview-disabled-transfer-target" ||
            event.format.identifier != PREVIEW_TEXT_FORMAT.identifier || event.offer.payload != "external-text") {
            return CjguiComposableUiDispatchResult(false)
        }
        if (!targetEnabled) {
            transferEventsWhileDisabled += 1
            return CjguiComposableUiDispatchResult(false)
        }
        acceptedTransferEvents += 1
        revision += 1
        return CjguiComposableUiDispatchResult(true)
    }
}

private func projectionIsReady(window: CjguiComposableUiWindow): Bool {
    let projection = window.windowProjection()
    return projection.isActive && projection.sessionIdentity.size > 0 && projection.nodes.size >= 3
}

private func verifyDataTransferConsumer(expectDrop: Bool): Bool {
    let readback = PreviewTransferReadback()
    let application = CjguiMacosApplication(maximumWindowCount: 2)
    let source = PreviewTransferSourceOwner(readback)
    let target = PreviewTransferTargetOwner(readback)
    let sourceOpen = application.openWindow(source,
        configuration: CjguiMacosApplicationWindowConfiguration("Preview Transfer Source", 420u32, 220u32))
    let targetOpen = application.openWindow(target,
        configuration: CjguiMacosApplicationWindowConfiguration("Preview Transfer Target", 420u32, 220u32))
    if (!sourceOpen.didOpen || !targetOpen.didOpen) {
        application.close()
        return false
    }
    let sourceId = if (let Some(value) <- sourceOpen.identifier) { value } else { application.close(); return false }
    let targetId = if (let Some(value) <- targetOpen.identifier) { value } else { application.close(); return false }
    let sourceWindow = if (let Some(value) <- application.window(sourceId)) { value } else { application.close(); return false }
    let targetWindow = if (let Some(value) <- application.window(targetId)) { value } else { application.close(); return false }

    // This is a normal application host loop. The shell verifier sends real
    // AppKit click/Command-C/Command-V events after this marker. No test seam,
    // synthetic event constructor, or owner callback is used here.
    let _ = application.pumpOneTurn(turnBudgetMs: 4u32)
    let ready = projectionIsReady(sourceWindow) && projectionIsReady(targetWindow)
    let sourceSession = sourceWindow.windowProjection().sessionIdentity
    let targetSession = targetWindow.windowProjection().sessionIdentity
    getStdOut().writeln("CJGUI_PREVIEW_DATA_TRANSFER_READY source_session=${sourceSession} target_session=${targetSession} projections_ready=${ready}")
    getStdOut().flush()
    if (!ready || sourceSession == targetSession) {
        application.close()
        return false
    }

    // A cross-window desktop drag must hand AppKit's nested drag loop back to
    // the normal Cangjie pump. Leave extra time only for that verifier mode;
    // it still exits immediately once the public owner receives DROP.
    // Cross-window desktop verification may first separate two self-owned
    // windows and then cross AppKit's nested drag loop. Clipboard proof stays
    // bounded at ten seconds; leave the isolated DROP probe enough time for
    // that explicit platform setup without changing application semantics.
    let timeoutMs: Int64 = if (expectDrop) { 90000 } else { 10000 }
    let started = MonoTime.now()
    while (application.isOpen() && (MonoTime.now() - started).toMilliseconds() < timeoutMs) {
        let turn = application.pumpOneTurn(turnBudgetMs: 16u32)
        if (!turn.isOpen) { break }
        let structuredArrived = if (expectDrop) {
            readback.targetStructuredDrops > 0
        } else {
            readback.sourceStructuredCopies > 0 && readback.targetStructuredPastes > 0
        }
        if (structuredArrived && readback.targetExternalTextPastes > 0) {
            break
        }
    }
    let targetProjection = targetWindow.windowProjection()
    let projectedTarget = targetProjection.sessionIdentity == targetSession && targetProjection.isActive
    let structuredPassed = if (expectDrop) {
        readback.targetStructuredDrops == 1 && readback.targetStructuredPastes == 0
    } else {
        readback.sourceStructuredCopies == 1 && readback.targetStructuredPastes == 1 &&
            readback.targetStructuredDrops == 0
    }
    let passed = structuredPassed &&
        readback.targetExternalTextPastes == 1 && readback.textValue == "external-text" &&
        readback.structuredValue == "record-42" && readback.lastTargetSession == "target-window" &&
        projectedTarget && readback.rejectedEvents == 0
    let mode = if (expectDrop) { "drop" } else { "clipboard" }
    getStdOut().writeln("CJGUI_PREVIEW_DATA_TRANSFER mode=${mode} " +
        "platform_copy=${readback.sourceStructuredCopies == 1} platform_drop=${readback.targetStructuredDrops == 1} " +
        "external_text_paste=${readback.targetExternalTextPastes == 1} fifo_dispatch=${structuredPassed} " +
        "source_session=${sourceSession} target_session=${targetSession} target_projection=${projectedTarget} " +
        "text_value=${readback.textValue} structured_value=${readback.structuredValue} rejected=${readback.rejectedEvents} passed=${passed}")
    getStdOut().flush()
    application.close()
    return passed
}

private func verifyDisabledDataTransferBinding(): Bool {
    let owner = PreviewDisabledTransferTargetOwner()
    let window = CjguiComposableUiWindow(owner)
    let started = window.start()
    owner.disableTarget()
    let disabledRefresh = started && window.refresh()
    let projection = window.windowProjection()
    let passed = started && disabledRefresh && projection.isActive && projection.nodes.size >= 3 &&
        projection.sessionIdentity.size > 0
    getStdOut().writeln("CJGUI_PREVIEW_DATA_TRANSFER_DISABLED_BINDING " +
        "initial_started=${started} disabled_refresh=${disabledRefresh} projection_active=${projection.isActive} " +
        "node_count=${projection.nodes.size} passed=${passed}")
    getStdOut().flush()
    window.close()
    return passed
}

private func verifyDisabledDataTransferPlatform(): Bool {
    let owner = PreviewDisabledTransferTargetOwner()
    owner.disableTarget()
    let application = CjguiMacosApplication(maximumWindowCount: 1)
    let opened = application.openWindow(owner,
        configuration: CjguiMacosApplicationWindowConfiguration("Preview Disabled Transfer Target", 420u32, 220u32))
    if (!opened.didOpen) {
        application.close()
        return false
    }
    let identifier = if (let Some(value) <- opened.identifier) { value } else { application.close(); return false }
    let window = if (let Some(value) <- application.window(identifier)) { value } else { application.close(); return false }
    let _ = application.pumpOneTurn(turnBudgetMs: 4u32)
    let ready = projectionIsReady(window)
    let session = window.windowProjection().sessionIdentity
    getStdOut().writeln("CJGUI_PREVIEW_DATA_TRANSFER_DISABLED_PLATFORM_READY " +
        "session=${session} projection_ready=${ready} phase=disabled")
    getStdOut().flush()
    if (!ready) {
        application.close()
        return false
    }

    let started = MonoTime.now()
    var enabled = false
    var enableRefresh = false
    while (application.isOpen() && (MonoTime.now() - started).toMilliseconds() < 6500) {
        if (!enabled && (MonoTime.now() - started).toMilliseconds() >= 2200) {
            owner.enableTarget()
            enableRefresh = window.refresh()
            enabled = enableRefresh
            getStdOut().writeln("CJGUI_PREVIEW_DATA_TRANSFER_DISABLED_PLATFORM_READY " +
                "session=${session} projection_ready=${window.windowProjection().isActive} phase=enabled refresh=${enableRefresh}")
            getStdOut().flush()
        }
        let turn = application.pumpOneTurn(turnBudgetMs: 16u32)
        if (!turn.isOpen) { break }
        if (enabled && owner.acceptedTransferEventCount() > 0) { break }
    }
    let projection = window.windowProjection()
    let passed = enabled && enableRefresh && owner.disabledTransferEventCount() == 0 &&
        owner.acceptedTransferEventCount() == 1 && projection.isActive && projection.sessionIdentity == session
    getStdOut().writeln("CJGUI_PREVIEW_DATA_TRANSFER_DISABLED_PLATFORM " +
        "disabled_events=${owner.disabledTransferEventCount()} enabled_events=${owner.acceptedTransferEventCount()} " +
        "projection_active=${projection.isActive} passed=${passed}")
    getStdOut().flush()
    application.close()
    return passed
}

main(args: Array<String>): Int64 {
    if (args.size != 1) { return 2 }
    if (args[0] == "--verify-data-transfer") {
        return if (verifyDataTransferConsumer(false)) { 0 } else { 1 }
    }
    if (args[0] == "--verify-data-transfer-drop") {
        return if (verifyDataTransferConsumer(true)) { 0 } else { 1 }
    }
    if (args[0] == "--verify-data-transfer-disabled-binding") {
        return if (verifyDisabledDataTransferBinding()) { 0 } else { 1 }
    }
    if (args[0] == "--verify-data-transfer-disabled-platform") {
        return if (verifyDisabledDataTransferPlatform()) { 0 } else { 1 }
    }
    return 2
}

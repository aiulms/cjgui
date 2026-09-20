package cjgui_ui_only_starter

import cjgui.*
import std.env.*

// This source is copied only into the export-consumption fixture.  It uses the
// public framework surface and its bundle-local PNG; no renderer test seam or
// native object is part of the consumer contract.
private class PreviewImageController <: CjguiComposableUiController {
    private let name: String

    init(name: String) { this.name = name }

    public func uiSceneVersion(): Int64 { return 1 }

    public func buildUi(): CjguiComposableUiNode {
        let root = cjguiComposableVertical(1, "preview-image-root-${name}", CjguiComposableUiStyle(padding: 12, gap: 6))
        root.add(cjguiComposableText(2, "preview-image-label-${name}", "预览图片消费者 ${name}",
            CjguiComposableUiStyle(fixedHeight: 20)))
        root.add(cjguiComposableImage(3, "preview-image-beacon-${name}", "composable-beacon.png",
            CjguiComposableUiStyle(fixedWidth: 96, fixedHeight: 72, cornerRadius: 12, clipsContent: true),
            imageResourceId: "preview-shared-beacon", imageResourceVersion: 1))
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
}

private func imageState(application: CjguiMacosApplication, identifier: CjguiMacosApplicationWindowIdentifier): String {
    if (let Some(window) <- application.window(identifier)) {
        return window.imageResourceStatus("composable-beacon.png", "preview-shared-beacon", 1).state
    }
    return "closed"
}

private func verifyTwoWindows(): Bool {
    let application = CjguiMacosApplication()
    let openedA = application.openWindow(PreviewImageController("A"),
        configuration: CjguiMacosApplicationWindowConfiguration("Preview 图片 A", 360u32, 240u32))
    let openedB = application.openWindow(PreviewImageController("B"),
        configuration: CjguiMacosApplicationWindowConfiguration("Preview 图片 B", 360u32, 240u32))
    if (!openedA.didOpen || !openedB.didOpen) {
        application.close()
        return false
    }
    let identifierA = if (let Some(value) <- openedA.identifier) { value } else { application.close(); return false }
    let identifierB = if (let Some(value) <- openedB.identifier) { value } else { application.close(); return false }
    var turns: Int64 = 0
    var aState = imageState(application, identifierA)
    var bState = imageState(application, identifierB)
    while (turns < 160 && (aState != "ready" || bState != "ready")) {
        let turn = application.pumpOneTurn(turnBudgetMs: 4u32)
        if (!turn.isOpen) { break }
        aState = imageState(application, identifierA)
        bState = imageState(application, identifierB)
        turns += 1
    }
    let closedA = application.requestClose(identifierA)
    let bTurnAfterAClosed = application.pumpOneTurn(turnBudgetMs: 4u32)
    let bAfterClose = imageState(application, identifierB)
    let passed = aState == "ready" && bState == "ready" && closedA && bTurnAfterAClosed.isOpen && bAfterClose == "ready"
    getStdOut().writeln("CJGUI_PREVIEW_IMAGE_MULTIWINDOW a_state=${aState} b_state=${bState} b_after_a_close=${bAfterClose} b_open=${bTurnAfterAClosed.isOpen} turns=${turns} passed=${passed}")
    getStdOut().flush()
    application.close()
    return passed
}

main(args: Array<String>): Int64 {
    if (args.size != 1 || args[0] != "--verify-image-domain") { return 2 }
    return if (verifyTwoWindows()) { 0 } else { 1 }
}

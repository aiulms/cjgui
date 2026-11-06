package cjgui

@Test
func layoutExplanationNamesEmptyReservationAndOverflowWithoutCopyingText(): Unit {
    let root = cjguiComposableVertical(82001, "panel", CjguiComposableUiStyle(padding: 8))
    root.add(cjguiComposableText(82002, "reserved", "", CjguiComposableUiStyle(fixedHeight: 54)))
    root.add(cjguiComposableText(82003, "long", "Private body", CjguiComposableUiStyle(fixedWidth: 240)))
    let scene = CjguiComposableUiLayoutEngine.layout(root, CjguiComposableUiRect(0, 0, 180, 200), 1)
    let parent = scene.nodeForId(82001)
    let empty = CjguiComposableUiDiagnosticLayout.fromNode(scene.nodeForId(82002), Some(parent), scene.viewport, 0)
    @Assert(empty.labelAndValueEmpty, true)
    @Assert(empty.declaredStyle.fixedHeight, 54)
    @Assert(empty.parentContentBounds.width, 164)
    @Assert(empty.constraintSummary().contains("fixed=0/54"), true)
    let overflow = CjguiComposableUiDiagnosticLayout.fromNode(scene.nodeForId(82003), Some(parent), scene.viewport,
        CjguiComposableUiInteractionState.SELECTED | CjguiComposableUiInteractionState.FOCUSED)
    @Assert(overflow.overflowsParentContent, true)
    @Assert(overflow.stateSummary().contains("selected"), true)
    @Assert(overflow.stateSummary().contains("focused"), true)
    @Assert(overflow.constraintSummary().contains("Private body"), false)
}

@Test
func viewportBoundsAreUnavailableBeforeStart(): Unit {
    let window = CjguiComposableUiWindow(LayoutDiagnosticsController())
    @Assert(window.contentBounds().isNone(), true)
}

@When[os == "macOS"]
@Test
func inspectorCanSelectLayoutFactsWithoutInvalidatingItsOwnScene(): Unit {
    cjguiMacosOwnerTest({ => inspectorLayoutFactsBody() })
}

private func inspectorLayoutFactsBody(): Unit {
    let app = CjguiMacosApplication()
    try {
        let opened = app.openWindow(LayoutDiagnosticsController(), configuration:
            CjguiMacosApplicationWindowConfiguration("CJGUI usability diagnostic test", 320u32, 220u32))
        @Assert(opened.didOpen, true)
        let window = app.window(opened.identifier.getOrThrow()).getOrThrow()
        for (_ in 0..360) {
            if (window.displayedSceneVersion() > 0) { break }
            let _ = app.pumpOneTurn()
        }
        @Assert(window.displayedSceneVersion() > 0, true)
        @Assert(window.contentBounds().getOrThrow().width, 320)
        let before = window.diagnosticScalarSnapshot()
        let page = window.diagnosticSnapshot(includeNonVisible: true)
        @Assert(page.status, "ok")
        @Assert(page.nodes.size > 0, true)
        let panel = CjguiComposableUiInspectorPanel(window)
        let inspectorOpen = app.openWindow(panel, configuration:
            CjguiMacosApplicationWindowConfiguration("CJGUI usability inspector test", 1100u32, 800u32))
        @Assert(inspectorOpen.didOpen, true)
        let inspector = app.window(inspectorOpen.identifier.getOrThrow()).getOrThrow()
        for (_ in 0..360) {
            if (inspector.displayedSceneVersion() > 0) { break }
            let _ = app.pumpOneTurn()
        }
        @Assert(inspector.displayedSceneVersion() > 0, true)
        let initial = inspector.displayedSceneVersion()
        var selected = false
        for (node in inspector.acceptedSceneNodes()) {
            if (node.actionName == "INSPECT_SELECT") {
                let _ = panel.applyUiEvent(CjguiComposableUiEvent(node, CJGUI_COMPOSABLE_UI_EVENT_ACTIVATE, "", 0, 0, initial))
                selected = true
                break
            }
        }
        @Assert(selected, true)
        for (_ in 0..360) {
            if (inspector.displayedSceneVersion() > initial) { break }
            let _ = app.pumpOneTurn()
        }
        @Assert(inspector.displayedSceneVersion() > initial, true)
        var explains = false
        for (node in inspector.acceptedSceneNodes()) {
            if (node.semanticId == "inspector-constraints") { explains = true }
        }
        @Assert(explains, true)
        @Assert(window.diagnosticScalarSnapshot().buildPassCount, before.buildPassCount)
    } finally { app.close() }
}

private class LayoutDiagnosticsController <: CjguiComposableUiController {
    public func uiSceneVersion(): Int64 { return 1 }
    public func buildUi(): CjguiComposableUiNode {
        let root = cjguiComposableVertical(82001, "root", CjguiComposableUiStyle())
        root.add(cjguiComposableButton(82002, "diagnostic-action", "Inspect", "INSPECT", 1,
            CjguiComposableUiStyle(fixedWidth: 100, fixedHeight: 32)))
        return root
    }
    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(false)
    }
    public func rejectUiEvent(eventKind: Int64, nodeId: Int64): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(false)
    }
    public func requestWindowClose(): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(false, shouldClose: true)
    }
}

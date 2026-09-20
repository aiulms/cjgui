package cjgui

// This probe deliberately drives the normal CjguiComposableUiWindow and its
// AppKit text proxy. The theme switch changes paint only: geometry, text,
// font, enabled state and the document value remain identical.
foreign {
    func cjgui_internal_renderer_test_request_composable_drawable_pixel(
        session: UInt64, pointX: UInt32, pointY: UInt32
    ): Int32
    func cjgui_internal_renderer_test_composable_drawable_pixel(
        session: UInt64, outBlue: CPointer<UInt8>, outGreen: CPointer<UInt8>,
        outRed: CPointer<UInt8>, outAlpha: CPointer<UInt8>
    ): Int32
    func cjgui_internal_renderer_test_set_composable_selection(
        session: UInt64, nodeIndex: UInt32, selectionStart: UInt32, selectionEnd: UInt32
    ): Int32
    func cjgui_internal_renderer_test_scroll_composable_multiline(
        session: UInt64, deltaY: Float32, outScrollOffset: CPointer<Float32>,
        outVisibleGlyphCount: CPointer<UInt32>
    ): Int32
    func cjgui_internal_renderer_test_press_composable_node(
        session: UInt64, nodeIndex: UInt32
    ): Int32
    func cjgui_internal_renderer_test_set_composable_present_failures(
        session: UInt64, failureCount: UInt32
    ): Int32
}

private let THEME_TEXT = "第一行 UTF16 selection\n第二行 keeps scrolling\n第三行 stable content\n第四行 stable content\n第五行 stable content\n第六行 stable content\n第七行 stable content\n第八行 stable content\n第九行 stable content\n第十行 stable content\n第十一行 stable content\n第十二行 stable content"

private class ThemeContinuityController <: CjguiComposableUiController {
    private var sceneRevision: Int64
    private var darkTheme: Bool
    private var captureRevision: Int64
    private var actionCountValue: Int64

    init() {
        this.sceneRevision = 1
        this.darkTheme = false
        this.captureRevision = 0
        this.actionCountValue = 0
    }

    public func uiSceneVersion(): Int64 { return sceneRevision }

    private func theme(): CjguiComposableUiTheme {
        return if (darkTheme) {
            CjguiComposableUiTheme.beaconDark()
        } else {
            CjguiComposableUiTheme.paperLight()
        }
    }

    public func buildUi(): CjguiComposableUiNode {
        // No fontFamily/fontSize is changed by this switch. fixedHeight and
        // every text value stay constant, so this is a paint-only transition.
        let selectedTheme = theme()
        let page = selectedTheme.page.background
        let ink = selectedTheme.body.textColor
        let root = cjguiComposableVertical(1, "theme-continuity-root",
            CjguiComposableUiStyle(fixedWidth: 360, fixedHeight: 220, padding: 8, gap: 6,
                background: page, textColor: ink))
        root.add(cjguiComposableMultilineTextInput(2, "theme-text", "", THEME_TEXT, 4401,
            // Keep the probe's geometry and typography fixed; only the public
            // theme's input paint is consumed here.
            CjguiComposableUiStyle(fixedHeight: 128, background: selectedTheme.input.background, textColor: ink),
            enabled: true, readOnly: false, tabInsertsText: false))
        root.add(cjguiComposableButton(3, "theme-action", "Keep action", "THEME_ACTION", 4401,
            CjguiComposableUiStyle(fixedHeight: 28, background: selectedTheme.primaryAction.background,
                border: selectedTheme.primaryAction.border, textColor: selectedTheme.primaryAction.textColor)))
        // A capture request needs one ordinary submitted frame. Its text is
        // outside the sampled page pixel and leaves the text proxy's geometry,
        // value, focus and selection untouched.
        root.add(cjguiComposableText(4, "theme-capture", "capture ${captureRevision}",
            CjguiComposableUiStyle(fixedHeight: 1)))
        return root
    }

    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        if (event.eventKind == 27 && event.node.actionName == "THEME_ACTION") {
            actionCountValue += 1
            return CjguiComposableUiDispatchResult(true)
        }
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

    public func togglePaintOnlyTheme(): Unit {
        darkTheme = !darkTheme
        sceneRevision += 1
    }

    public func requestDrawableCapture(): Unit {
        captureRevision += 1
        sceneRevision += 1
    }

    public func actionCount(): Int64 { return actionCountValue }
}

private class ThemePixel {
    let status: Int32
    let red: UInt8
    let green: UInt8
    let blue: UInt8
    let alpha: UInt8

    init(status: Int32, red: UInt8, green: UInt8, blue: UInt8, alpha: UInt8) {
        this.status = status
        this.red = red
        this.green = green
        this.blue = blue
        this.alpha = alpha
    }
}

private func pixel(session: UInt64): ThemePixel {
    var blue: UInt8 = 0u8
    var green: UInt8 = 0u8
    var red: UInt8 = 0u8
    var alpha: UInt8 = 0u8
    let status = unsafe {
        cjgui_internal_renderer_test_composable_drawable_pixel(session, inout blue, inout green,
            inout red, inout alpha)
    }
    return ThemePixel(status, red, green, blue, alpha)
}

private func selectText(window: CjguiComposableUiWindow): Bool {
    let status = unsafe {
        cjgui_internal_renderer_test_set_composable_selection(
            window.testSessionToken(), 1u32, 2u32, 11u32
        )
    }
    return status == CJGUI_INTERNAL_RENDERER_OK && !window.pump(0u32).didApplyHumanAction
}

private func readScroll(window: CjguiComposableUiWindow, deltaY: Float32): Float32 {
    var offset: Float32 = 0.0f32
    var glyphs: UInt32 = 0u32
    let status = unsafe {
        cjgui_internal_renderer_test_scroll_composable_multiline(
            window.testSessionToken(), deltaY, inout offset, inout glyphs
        )
    }
    return if (status == CJGUI_INTERNAL_RENDERER_OK && glyphs > 0u32) { offset } else { -1.0f32 }
}

main(): Int64 {
    let controller = ThemeContinuityController()
    let window = CjguiComposableUiWindow(controller)
    if (!window.start()) { return 2 }
    let session = window.testSessionToken()
    let beforeRequest = unsafe {
        cjgui_internal_renderer_test_request_composable_drawable_pixel(session, 5u32, 5u32)
    }
    controller.requestDrawableCapture()
    if (beforeRequest != CJGUI_INTERNAL_RENDERER_OK || !window.refresh()) { window.close(); return 5 }
    let beforeTheme = window.windowProjection()
    let beforePixel = pixel(session)
    if (!selectText(window)) { window.close(); return 3 }
    let beforeSelection = window.windowProjection()
    let beforeScroll = readScroll(window, -48.0f32)
    let beforeScrolled = window.windowProjection()
    if (beforeScroll <= 0.0f32 || beforeSelection.focusedControlId != "theme-text" ||
        !beforeSelection.hasTextSelection || beforeSelection.selectionStart != 2 ||
        beforeSelection.selectionEnd != 11) {
        window.close()
        return 4
    }

    // RED/GREEN contract: one normal owner refresh changes only paint and
    // keeps the real AppKit text proxy's UTF-16 selection, focus and scroll.
    let afterRequest = unsafe {
        cjgui_internal_renderer_test_request_composable_drawable_pixel(session, 5u32, 5u32)
    }
    controller.togglePaintOnlyTheme()
    let themeRefresh = window.refresh()
    let afterTheme = window.windowProjection()
    let afterScroll = readScroll(window, 0.0f32)
    let afterPixel = pixel(session)
    let themeChanged = afterRequest == CJGUI_INTERNAL_RENDERER_OK && themeRefresh && afterTheme.sceneVersion > beforeTheme.sceneVersion &&
        beforePixel.status == CJGUI_INTERNAL_RENDERER_OK && afterPixel.status == CJGUI_INTERNAL_RENDERER_OK &&
        (beforePixel.red != afterPixel.red || beforePixel.green != afterPixel.green || beforePixel.blue != afterPixel.blue)
    let selectionPreserved = afterTheme.focusedControlId == beforeScrolled.focusedControlId &&
        afterTheme.hasTextSelection && afterTheme.selectionStart == beforeScrolled.selectionStart &&
        afterTheme.selectionEnd == beforeScrolled.selectionEnd
    let focusPreserved = afterTheme.focusedControlId == "theme-text"
    let scrollPreserved = afterScroll == beforeScroll

    // An unchanged owner must not cause another scene submission after the
    // successful theme transaction.
    let idleBefore = window.windowProjection()
    let idleRefresh = window.refreshIfNeeded()
    let idleAfter = window.windowProjection()
    let idleNoWork = idleRefresh && idleAfter.buildPassCount == idleBefore.buildPassCount &&
        idleAfter.layoutPassCount == idleBefore.layoutPassCount &&
        idleAfter.nativeSubmissionCount == idleBefore.nativeSubmissionCount &&
        idleAfter.submittedFrameIndex == idleBefore.submittedFrameIndex

    // A failed candidate must leave the accepted paint, focused proxy and old
    // action usable. The controlled present seam rejects this exact complete
    // candidate after staging, without creating a second application owner.
    let oldAcceptedScene = window.displayedSceneVersion()
    let oldSubmissionCount = idleAfter.nativeSubmissionCount
    let forceFailure = unsafe {
        cjgui_internal_renderer_test_set_composable_present_failures(session, 1u32)
    }
    controller.togglePaintOnlyTheme()
    let failedRefresh = window.refresh()
    let failedProjection = window.windowProjection()
    // The previous requested submission is the last accepted frame. Do not
    // issue another capture request here: that would require a healthy render
    // and could accidentally turn this retained-frame assertion into a retry.
    let failedPixel = pixel(session)
    let failedCandidateRetained = forceFailure == CJGUI_INTERNAL_RENDERER_OK && !failedRefresh &&
        failedProjection.acceptedSceneVersion == oldAcceptedScene &&
        failedProjection.nativeSubmissionCount == oldSubmissionCount &&
        failedProjection.pendingRefreshReason != "none" &&
        failedProjection.lastNativeFailure != "none" &&
        failedPixel.status == afterPixel.status && failedPixel.red == afterPixel.red &&
        failedPixel.green == afterPixel.green && failedPixel.blue == afterPixel.blue &&
        failedProjection.focusedControlId == afterTheme.focusedControlId &&
        failedProjection.selectionStart == afterTheme.selectionStart &&
        failedProjection.selectionEnd == afterTheme.selectionEnd
    let oldActionPress = unsafe { cjgui_internal_renderer_test_press_composable_node(session, 2u32) }
    let oldActionTurn = window.pump(0u32)
    let actionPreserved = oldActionPress == CJGUI_INTERNAL_RENDERER_OK &&
        oldActionTurn.didApplyHumanAction && controller.actionCount() == 1

    let recovered = window.refresh()
    let recoveredProjection = window.windowProjection()
    let recoveredHealthy = recovered && recoveredProjection.pendingRefreshReason == "none" &&
        recoveredProjection.lastNativeFailure == "none" &&
        recoveredProjection.acceptedSceneVersion > oldAcceptedScene
    let valid = themeChanged && selectionPreserved && focusPreserved && scrollPreserved && idleNoWork &&
        failedCandidateRetained && actionPreserved && recoveredHealthy
    println("CJGUI_INTERACTION_STYLE_THEME_CONTINUITY theme_changed=${themeChanged} selection_preserved=${selectionPreserved} focus_preserved=${focusPreserved} scroll_preserved=${scrollPreserved} idle_no_work=${idleNoWork} failed_candidate_retained=${failedCandidateRetained} action_preserved=${actionPreserved} recovered=${recoveredHealthy} valid=${valid}")
    window.close()
    return if (valid) { 0 } else { 1 }
}

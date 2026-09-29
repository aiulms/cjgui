package cjgui

private class OhosPendingRevealController <: CjguiComposableUiController {
    let outer: CjguiComposableUiScrollViewport
    let inner: CjguiComposableUiScrollViewport
    let outerSpacerCount: Int64
    let targetRow: Int64
    var revision: Int64 = 1
    var incarnation: Int64 = 1

    init(outer: CjguiComposableUiScrollViewport, inner: CjguiComposableUiScrollViewport, outerSpacerCount: Int64,
        targetRow: Int64) {
        this.outer = outer
        this.inner = inner
        this.outerSpacerCount = outerSpacerCount
        this.targetRow = targetRow
    }
    public func uiSceneVersion(): Int64 {
        return revision
    }
    public func buildUi(): CjguiComposableUiNode {
        let outerContent = cjguiComposableVertical(9400, "ohos-reveal-outer-content", CjguiComposableUiStyle())
        var index: Int64 = 0
        while (index < outerSpacerCount) {
            outerContent.add(
                cjguiComposableText(9410 + index, "ohos-reveal-spacer-${index}", "上",
                    CjguiComposableUiStyle(fixedHeight: 24)))
            index += 1
        }
        let innerContent = cjguiComposableVertical(9500, "ohos-reveal-inner-content", CjguiComposableUiStyle())
        index = 0
        while (index < 40) {
            if (index == targetRow) {
                let editor = cjguiComposableTextInput(9600 + index, "ohos-reveal-target", "目标", "draft", 9901,
                    CjguiComposableUiStyle(fixedHeight: 24))
                editor.semanticIncarnation = incarnation
                innerContent.add(editor)
            } else {
                innerContent.add(
                    cjguiComposableText(9600 + index, "ohos-reveal-row-${index}", "内",
                        CjguiComposableUiStyle(fixedHeight: 24)))
            }
            index += 1
        }
        let innerScroll = cjguiComposableScrollArea(9501, "ohos-reveal-inner", inner,
            CjguiComposableUiStyle(fixedHeight: 200, growX: 1))
        innerScroll.add(innerContent)
        outerContent.add(innerScroll)
        index = 0
        while (index < 30) {
            outerContent.add(
                cjguiComposableText(9700 + index, "ohos-reveal-tail-${index}", "下",
                    CjguiComposableUiStyle(fixedHeight: 24)))
            index += 1
        }
        let outerScroll = cjguiComposableScrollArea(9401, "ohos-reveal-outer", outer,
            CjguiComposableUiStyle(fixedHeight: 120, growX: 1))
        outerScroll.add(outerContent)
        return outerScroll
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

private func ohosRevealNode(window: CjguiComposableUiWindow, semanticId: String): CjguiComposableUiLayoutNode {
    for (node in window.acceptedSceneNodes()) {
        if (node.semanticId == semanticId) {
            return node
        }
    }
    return CjguiComposableUiLayoutNode.missing()
}

@Test
func ohosRevealReplacesInfeasiblePendingInnerAndExposesTargetThroughBothClips(): Unit {
    let outer = CjguiComposableUiScrollViewport()
    let inner = CjguiComposableUiScrollViewport()
    let controller = OhosPendingRevealController(outer, inner, 8, 0)
    let window = CjguiComposableUiWindow(controller)
    @Assert(window.start(), true)
    @Assert(inner.requestOffset(100), true)
    @Assert(window.focusAcceptedSemanticNode("ohos-reveal-target"), true)
    @Assert(inner.offset(), 0)
    @Assert(outer.offset(), 100)
    controller.revision += 1
    @Assert(window.refresh(), true)
    let target = ohosRevealNode(window, "ohos-reveal-target")
    let innerNode = ohosRevealNode(window, "ohos-reveal-inner")
    let outerNode = ohosRevealNode(window, "ohos-reveal-outer")
    @Assert(inner.acceptedOffset(), 0)
    @Assert(outer.acceptedOffset(), 100)
    @Assert(target.bounds.y >= innerNode.bounds.y, true)
    @Assert(target.bounds.y + target.bounds.height <= innerNode.bounds.y + innerNode.bounds.height, true)
    @Assert(target.bounds.y >= outerNode.bounds.y, true)
    @Assert(target.bounds.y + target.bounds.height <= outerNode.bounds.y + outerNode.bounds.height, true)
    window.close()
}

@Test
func ohosPendingFocusRejectsSameValueNewIncarnationAndAba(): Unit {
    let outer = CjguiComposableUiScrollViewport()
    let inner = CjguiComposableUiScrollViewport()
    let controller = OhosPendingRevealController(outer, inner, 8, 39)
    let window = CjguiComposableUiWindow(controller)
    @Assert(window.start(), true)
    @Assert(window.focusAcceptedSemanticNode("ohos-reveal-target"), true)
    @Assert(inner.offset() > 0, true)

    // Numeric node id, visible strings and domain resource are unchanged.
    // Only the declarative incarnation changes before reveal is accepted.
    controller.incarnation = 2
    controller.revision += 1
    @Assert(window.refresh(), true)
    @Assert(window.windowProgress().focusedControlId, "none")

    controller.incarnation = 1
    controller.revision += 1
    @Assert(window.refresh(), true)
    @Assert(window.windowProgress().focusedControlId, "none")
    window.close()
}

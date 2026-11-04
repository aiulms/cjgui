// App-local routing regression for the hand-built collection's legacy viewport.
// The event node is taken from the window's accepted scene; direct controller
// dispatch below tests the app router, not native key delivery.
package cjgui_mixed_form_starter

import cjgui.*
import std.time.*
import std.unittest.*
import std.unittest.testmacro.*

private func keyboardRouterAcceptedNode(window: CjguiComposableUiWindow,
    semanticId: String): CjguiComposableUiLayoutNode {
    for (node in window.acceptedSceneNodes()) {
        if (node.semanticId == semanticId) {
            return node
        }
    }
    return CjguiComposableUiLayoutNode.missing()
}

private func keyboardRouterAwaitFirstAccepted(window: CjguiComposableUiWindow,
    budget: CjguiOwnerTurnBudget): Unit {
    let deadline = MonoTime.now() + 5 * Duration.second
    var turns: Int64 = 0
    while (window.isOpen() && window.windowProgress().acceptedSceneVersion < 1 &&
        turns < 240 && MonoTime.now() < deadline) {
        @Assert(budget.begin(), true)
        try {
            let _ = window.refreshIfNeeded()
            let _ = window.pump(0u32)
            let _ = budget.finishScheduling()
        } finally { budget.end() }
        turns += 1
    }
    @Assert(window.windowProgress().acceptedSceneVersion >= 1, true)
}

@When[os == "macOS"]
@Test
func mixedLegacyBusinessCollectionRoutesEndToItsExactViewport(): Unit {
    cjguiMacosOwnerTest({ =>
        let domain = PrintPresetDomain()
        let controller = MixedFormController(domain)
        let window = CjguiComposableUiWindow(controller)
        controller.attachWindow(window)
        let budget = CjguiOwnerTurnBudget()
        try {
            window.useOwnerTurnBudget(budget)
            @Assert(window.start(), true)
            keyboardRouterAwaitFirstAccepted(window, budget)
            let projection = window.windowProgress().acceptedSceneVersion
            let node = keyboardRouterAcceptedNode(window, "preset-business-collection")
            @Assert(node.nodeId, 3004)
            @Assert(node.nodeKind, CJGUI_COMPOSABLE_UI_SCROLL_AREA)
            @Assert(node.scrollViewport.isSome(), true)
            let expectedList = PresetCardList(domain.cards, {=> mixedFormTheme(true)})
            let order = expectedList.collection.order()
            @Assert(order.count() > 1, true)
            let expectedKey = order.keyAt(order.count() - 1)
            let beforeSelected = domain.cards.selectedKey()
            let result = controller.applyUiEvent(CjguiComposableUiEvent(node, 35, "end", 0, 0, projection))
            @Assert(result.didApply, true)
            @Assert(domain.cards.selectedKey(), expectedKey)
            @Assert(domain.cards.selectedKey() != beforeSelected, true)
        } finally {
            budget.end()
            window.close()
        }
    })
}

@When[os == "macOS"]
@Test
func mixedLegacyBusinessCollectionRejectsForeignAndNonCollectionEvents(): Unit {
    cjguiMacosOwnerTest({ =>
        let domain = PrintPresetDomain()
        let controller = MixedFormController(domain)
        let window = CjguiComposableUiWindow(controller)
        controller.attachWindow(window)
        let budget = CjguiOwnerTurnBudget()
        try {
            window.useOwnerTurnBudget(budget)
            @Assert(window.start(), true)
            keyboardRouterAwaitFirstAccepted(window, budget)
            let projection = window.windowProgress().acceptedSceneVersion
            let accepted = keyboardRouterAcceptedNode(window, "preset-business-collection")
            @Assert(accepted.nodeId, 3004)
            let beforeSelected = domain.cards.selectedKey()
            let beforeVersion = domain.formSnapshot().contextVersion

            let foreignViewport = CjguiComposableUiScrollViewport()
            let foreignNode = cjguiComposableScrollArea(9101, "preset-business-collection", foreignViewport,
                CjguiComposableUiStyle())
            @Assert(controller.applyUiEvent(CjguiComposableUiEvent(
                CjguiComposableUiLayoutNode(foreignNode, CjguiComposableUiRect(0, 0, 320, 200),
                    CjguiComposableUiRect(0, 0, 320, 200)), 35, "end", 0, 0, projection)).didApply, false)

            let wrongSemantic = cjguiComposableScrollArea(9102, "other-business-collection",
                accepted.scrollViewport.getOrThrow(), CjguiComposableUiStyle())
            @Assert(controller.applyUiEvent(CjguiComposableUiEvent(
                CjguiComposableUiLayoutNode(wrongSemantic, CjguiComposableUiRect(0, 0, 320, 200),
                    CjguiComposableUiRect(0, 0, 320, 200)), 35, "end", 0, 0, projection)).didApply, false)

            let textInput = cjguiComposableTextInput(9103, "preset-business-filter", "筛选对象", "", -1,
                CjguiComposableUiStyle())
            @Assert(controller.applyUiEvent(CjguiComposableUiEvent(
                CjguiComposableUiLayoutNode(textInput, CjguiComposableUiRect(0, 0, 320, 200),
                    CjguiComposableUiRect(0, 0, 320, 200)), 35, "end", 0, 0, projection)).didApply, false)
            @Assert(controller.applyUiEvent(CjguiComposableUiEvent(accepted, 28, "end", 0, 0,
                projection)).didApply, false)

            @Assert(domain.cards.selectedKey(), beforeSelected)
            @Assert(domain.formSnapshot().contextVersion, beforeVersion)
        } finally {
            budget.end()
            window.close()
        }
    })
}

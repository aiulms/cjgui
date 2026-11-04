package cjgui

import std.unittest.*
import std.unittest.testmacro.*

private func inputScopeEvent(): CjguiComposableUiEvent {
    let node = CjguiComposableUiNode(1, "field", CJGUI_COMPOSABLE_UI_SCROLL_AREA, "", "", "", -1,
        CjguiComposableUiStyle())
    let bounds = CjguiComposableUiRect(0, 0, 20, 20)
    return CjguiComposableUiEvent(CjguiComposableUiLayoutNode(node, bounds, bounds), 28, "x", 0, 0, 1)
}

@Test
func inputScopeRejectsDifferentEventAndNestedScope(): Unit {
    let first = inputScopeEvent()
    let equalFields = inputScopeEvent()
    let outer = cjguiInputLinkBeginDispatch(first, "window", 1u64, 1u64, 1u64, 1u64)
    try {
        @Expect(cjguiInputLinkCurrentDispatch(first).isSome(), true)
        @Expect(cjguiInputLinkCurrentDispatch(equalFields).isNone(), true)
        let nested = cjguiInputLinkBeginDispatch(equalFields, "window", 1u64, 1u64, 2u64, 2u64)
        try {
            @Expect(cjguiInputLinkCurrentDispatch(first).isNone(), true)
            @Expect(cjguiInputLinkCurrentDispatch(equalFields).isNone(), true)
        } finally { @Expect(cjguiInputLinkEndDispatch(nested), false) }
        @Expect(cjguiInputLinkCurrentDispatch(first).isNone(), true)
    } finally { @Expect(cjguiInputLinkEndDispatch(outer), false) }
    @Expect(cjguiInputLinkCurrentDispatch(first).isNone(), true)
}

@Test
func inputScopeRestoresAfterThrowAndDoesNotCrossThread(): Unit {
    let event = inputScopeEvent()
    try {
        let scope = cjguiInputLinkBeginDispatch(event, "window", 1u64, 1u64, 1u64, 1u64)
        try {
            let observed = spawn { cjguiInputLinkCurrentDispatch(event).isNone() }
            @Expect(observed.get(), true)
            throw Exception("expected")
        } finally { @Expect(cjguiInputLinkEndDispatch(scope), true) }
    } catch (_: Exception) {}
    @Expect(cjguiInputLinkCurrentDispatch(event).isNone(), true)
}

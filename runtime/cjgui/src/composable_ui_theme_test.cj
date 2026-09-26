// Theme readability contract tests.
//
// A theme must give normal usable text an explicit foreground for BOTH the
// base style and the interaction states a component consumes. The dark
// theme's primary action previously declared a background only, so a consumer
// that passed the base style (or read the base foreground for hover/pressed)
// rendered near-black text on a dark blue button.
package cjgui

import std.math.*

private func themeTextLuminance(color: CjguiComposableUiColor): Float64 {
    return color.red * 0.2126 + color.green * 0.7152 + color.blue * 0.0722
}

private func themeAssertReadableOnDark(color: CjguiComposableUiColor): Bool {
    return color.alpha >= 0.99 && themeTextLuminance(color) >= 0.6
}

private func themeAssertReadableOnLight(color: CjguiComposableUiColor): Bool {
    return color.alpha >= 0.99 && themeTextLuminance(color) <= 0.35
}

@Test
func beaconDarkPrimaryActionDeclaresReadableForegroundOnBaseAndStates(): Unit {
    let theme = CjguiComposableUiTheme.beaconDark()
    // The base style itself must carry the readable foreground: a consumer that
    // never touches the interaction table still renders readable text.
    @Assert(themeAssertReadableOnDark(theme.primaryAction.textColor), true)
    // Hover and pressed do not re-declare the foreground; resolution keeps the
    // base foreground instead of falling back to the framework default.
    let hover = theme.primaryActionInteraction.resolve(theme.primaryAction,
        CjguiComposableUiInteractionState.HOVER)
    @Assert(themeAssertReadableOnDark(hover.textColor), true)
    let pressed = theme.primaryActionInteraction.resolve(theme.primaryAction,
        CjguiComposableUiInteractionState.PRESSED)
    @Assert(themeAssertReadableOnDark(pressed.textColor), true)
    let normal = theme.primaryActionInteraction.resolve(theme.primaryAction,
        CjguiComposableUiInteractionState.NONE)
    @Assert(themeAssertReadableOnDark(normal.textColor), true)
}

@Test
func paperLightPrimaryActionKeepsReadableForegroundOnBaseAndStates(): Unit {
    let theme = CjguiComposableUiTheme.paperLight()
    @Assert(themeAssertReadableOnDark(theme.primaryAction.textColor), true)
    let hover = theme.primaryActionInteraction.resolve(theme.primaryAction,
        CjguiComposableUiInteractionState.HOVER)
    @Assert(themeAssertReadableOnDark(hover.textColor), true)
    let pressed = theme.primaryActionInteraction.resolve(theme.primaryAction,
        CjguiComposableUiInteractionState.PRESSED)
    @Assert(themeAssertReadableOnDark(pressed.textColor), true)
}

@Test
func themeInputForegroundStaysDarkOnItsLightBackground(): Unit {
    // The fix must NOT turn every default text white: the dark theme's input is
    // a light surface and its normal paint declares a dark foreground.
    let theme = CjguiComposableUiTheme.beaconDark()
    @Assert(themeTextLuminance(theme.input.background) >= 0.6, true)
    let normal = theme.inputInteraction.resolve(theme.input,
        CjguiComposableUiInteractionState.NONE)
    @Assert(themeAssertReadableOnLight(normal.textColor), true)
    let hover = theme.inputInteraction.resolve(theme.input,
        CjguiComposableUiInteractionState.HOVER)
    @Assert(themeAssertReadableOnLight(hover.textColor), true)
}

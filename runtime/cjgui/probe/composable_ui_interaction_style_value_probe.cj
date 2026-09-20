package cjgui

private func expect(condition: Bool, message: String): Bool {
    if (!condition) {
        println("CJGUI_INTERACTION_STYLE_VALUE_PROBE_FAIL ${message}")
    }
    return condition
}

private func color(red: Float64, green: Float64, blue: Float64, alpha: Float64): CjguiComposableUiColor {
    return CjguiComposableUiColor(red, green, blue, alpha)
}

main(): Int64 {
    let base = CjguiComposableUiStyle(
        background: color(0.10, 0.12, 0.16, 1.0),
        border: color(0.20, 0.24, 0.32, 1.0),
        textColor: color(0.92, 0.94, 0.98, 1.0),
        padding: 11, fixedHeight: 31, borderWidth: 1, cornerRadius: 7)
    let states = CjguiComposableUiInteractionStyle(
        normal: CjguiComposableUiPaintStyle(textColor: Some(color(0.80, 0.82, 0.86, 1.0))),
        selected: CjguiComposableUiPaintStyle(background: Some(color(0.18, 0.32, 0.54, 1.0))),
        checked: CjguiComposableUiPaintStyle(border: Some(color(0.20, 0.86, 0.56, 1.0))),
        focused: CjguiComposableUiPaintStyle(borderWidth: Some(3)),
        hover: CjguiComposableUiPaintStyle(background: Some(color(0.24, 0.38, 0.66, 1.0))),
        pressed: CjguiComposableUiPaintStyle(background: Some(color(0.10, 0.20, 0.48, 1.0))),
        disabled: CjguiComposableUiPaintStyle(textColor: Some(color(0.50, 0.52, 0.56, 1.0))))
    let combined = states.resolve(base,
        CjguiComposableUiInteractionState.SELECTED |
        CjguiComposableUiInteractionState.CHECKED |
        CjguiComposableUiInteractionState.FOCUSED |
        CjguiComposableUiInteractionState.HOVER |
        CjguiComposableUiInteractionState.PRESSED)
    if (!expect(combined.background.red == 0.10 && combined.background.green == 0.20 &&
        combined.background.blue == 0.48 && combined.border.green == 0.86 && combined.borderWidth == 3 &&
        combined.textColor.red == 0.80, "composed paint priority")) { return 1 }
    if (!expect(combined.padding == base.padding && combined.fixedHeight == base.fixedHeight &&
        combined.cornerRadius == base.cornerRadius, "paint style cannot change geometry")) { return 2 }
    let disabled = states.resolve(base, CjguiComposableUiInteractionState.DISABLED |
        CjguiComposableUiInteractionState.PRESSED | CjguiComposableUiInteractionState.HOVER)
    if (!expect(disabled.textColor.red == 0.50 && disabled.background.red == 0.10,
        "disabled paint wins only declared fields")) { return 3 }
    if (!expect(CjguiComposableUiInteractionState.ownerBits(
        CjguiComposableUiInteractionState.SELECTED | CjguiComposableUiInteractionState.CHECKED |
        CjguiComposableUiInteractionState.HOVER) == (CjguiComposableUiInteractionState.SELECTED |
        CjguiComposableUiInteractionState.CHECKED), "owner state filter")) { return 4 }
    println("CJGUI_INTERACTION_STYLE_VALUE_PROBE_PASS composed=1 geometry_stable=1 disabled=1 owner_filter=1")
    return 0
}

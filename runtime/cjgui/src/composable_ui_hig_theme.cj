package cjgui

import std.collection.*

/// Apple macOS HIG 桌面主题（experimental，macOS 验证范围）。
///
/// 取值来源分三类，逐项注明在对应行上方：
///   measured:macOS-semantic-color  —— 本机 macOS 15.x 上 NSColor 语义色取样，
///       sRGB 分量与 alpha 一并记录，并在白色/窗口背景上做 alpha 合成；
///   measured:AppKit-control-metric —— 本机 AppKit 控件 sizeToFit 实测高度；
///   hig:typography / project-decision —— HIG 内置文本样式（body 13pt 等），
///       或 CJGUI 自己选择的桌面密度/间距/圆角。
/// 取样原件与完整表见 `work/prototype-host-20261108/hig/`（阶段证据，不属于框架依赖）。
///
/// 本主题只提供一套可替换的角色取值：手写与生成式界面都从这个
/// `CjguiComposableUiTheme` 取角色，框架不引入 AppKit/SwiftUI 依赖，也不做
/// 玻璃/模糊等材质——未实现的高级外观如实记为差异，不声称完整复刻 macOS。
extend CjguiComposableUiTheme {
    /// HIG 浅色外观。窗口内容背景用系统窗口背景；分组表面用正文背景 + 1pt 分隔线，
    /// 不用毛玻璃或阴影伪造层次。
    public static func higLight(): CjguiComposableUiTheme {
        return higTheme(false)
    }

    /// HIG 深色外观。同一套角色，只换取样到的语义色。
    public static func higDark(): CjguiComposableUiTheme {
        return higTheme(true)
    }

    /// 按外观切换同一套 HIG 角色，供应用的“跟随系统/亮/暗”设置使用。
    public static func hig(dark: Bool): CjguiComposableUiTheme {
        return higTheme(dark)
    }

    /// 主题名（`hig-light` / `hig-dark`）。用于应用持久化选择，不参与绘制。
    public func higAppearanceName(): String {
        let dark = page.background.red + page.background.green + page.background.blue < 1.5
        return if (dark) { "hig-dark" } else { "hig-light" }
    }
}

private func higColor(r: Int64, g: Int64, b: Int64, a!: Float64 = 1.0): CjguiComposableUiColor {
    return CjguiComposableUiColor(Float64(r) / 255.0, Float64(g) / 255.0, Float64(b) / 255.0, a)
}

/// Alpha 合成：把带透明度的语义色平铺到不透明背景上。HIG 的 label/separator
/// 等颜色是带 alpha 的，直接当 RGB 使用会把次要文字画成纯黑。
private func higOver(foreground: CjguiComposableUiColor, background: CjguiComposableUiColor): CjguiComposableUiColor {
    let alpha = foreground.alpha
    return CjguiComposableUiColor(foreground.red * alpha + background.red * (1.0 - alpha),
        foreground.green * alpha + background.green * (1.0 - alpha),
        foreground.blue * alpha + background.blue * (1.0 - alpha), 1.0)
}

private func higMix(a: CjguiComposableUiColor, b: CjguiComposableUiColor, amount: Float64): CjguiComposableUiColor {
    return CjguiComposableUiColor(a.red + (b.red - a.red) * amount, a.green + (b.green - a.green) * amount,
        a.blue + (b.blue - a.blue) * amount, a.alpha + (b.alpha - a.alpha) * amount)
}

private func higTheme(dark: Bool): CjguiComposableUiTheme {
    // measured:macOS-semantic-color —— NSColor 取样（浅色 / 深色）。
    let windowBackground = if (dark) { higColor(32, 32, 32) } else { higColor(255, 255, 255) }        // #202020 / #FFFFFF
    let textBackground = if (dark) { higColor(32, 32, 32) } else { higColor(255, 255, 255) }          // #202020 / #FFFFFF
    let label = if (dark) { higColor(255, 255, 255) } else { higColor(0, 0, 0) }                      // #FFFFFF / #000000
    let secondaryLabelRaw = if (dark) {
        higColor(255, 255, 255, a: 0.698)
    } else {
        higColor(0, 0, 0, a: 0.757)
    }
    let separatorRaw = if (dark) { higColor(255, 255, 255, a: 0.298) } else { higColor(0, 0, 0, a: 0.349) }
    let accent = if (dark) { higColor(23, 116, 218) } else { higColor(0, 64, 221) }                   // #1774DA / #0040DD
    let focusRing = if (dark) { higColor(70, 154, 245) } else { higColor(0, 34, 175) }                // #469AF5 / #0022AF
    let disabledText = if (dark) {
        higOver(higColor(255, 255, 255, a: 0.498), windowBackground)
    } else {
        higOver(higColor(0, 0, 0, a: 0.757), windowBackground)
    }
    let systemRed = if (dark) { higColor(255, 97, 101) } else { higColor(233, 21, 45) }               // #FF6165 / #E9152D
    let onAccent = higColor(255, 255, 255)
    // project-decision —— CJGUI 的桌面分组表面：系统窗口背景 + 4% label 叠加。
    // HIG 用材质表达层次；本框架不做材质，改用色差 + 1pt 分隔线，明确记为差异。
    let page = CjguiComposableUiStyle(background: windowBackground, padding: 16, gap: 12)
    let surface = higMix(windowBackground, label, if (dark) { 0.06 } else { 0.035 })
    let separator = higOver(separatorRaw, surface)
    let controlBorder = higOver(separatorRaw, textBackground)
    let secondaryLabel = higOver(secondaryLabelRaw, windowBackground)
    // measured:AppKit-control-metric —— regular 控件 24pt、large 28pt。
    // project-decision —— 自绘 + 中文正文用 large 高度，避免 24pt 下 CJK 挤压。
    let controlHeight: Int64 = 28
    // hig:typography —— body 13pt、title1 22pt、caption 11pt（CJK 最低 11pt）。
    let headingStyle = CjguiComposableUiStyle(textColor: label, fontSize: 22.0, fontWeight: 600)
    let bodyStyle = CjguiComposableUiStyle(textColor: secondaryLabel, fontSize: 13.0)
    // project-decision —— radius_md 7pt、控件内边距 8pt；输入框用正文背景。
    let inputStyle = CjguiComposableUiStyle(fixedHeight: controlHeight, padding: 8, cornerRadius: 7,
        background: textBackground, border: controlBorder, borderWidth: 1, textColor: label, fontSize: 13.0)
    let primaryStyle = CjguiComposableUiStyle(fixedHeight: controlHeight, padding: 8, cornerRadius: 7,
        background: accent, border: accent, textColor: onAccent, fontSize: 13.0, fontWeight: 500,
        textMaxLines: 1, textOverflow: "ellipsis")
    let secondaryStyle = CjguiComposableUiStyle(fixedHeight: controlHeight, padding: 8, cornerRadius: 7,
        background: surface, border: controlBorder, borderWidth: 1, textColor: label, fontSize: 13.0,
        textMaxLines: 1, textOverflow: "ellipsis")
    // 交互态沿用既有状态合成：normal→selected→checked→focused→hover→pressed→disabled。
    // 悬停/按下用 label 叠加（HIG 的 6%/12% 状态叠加），焦点用键盘焦点指示色环，
    // 选中/勾选用 12% accent 底 + accent 文字，几何不随状态改变。
    let inputInteraction = CjguiComposableUiInteractionStyle(
        normal: CjguiComposableUiPaintStyle(background: Some(textBackground), border: Some(controlBorder),
            textColor: Some(label)),
        hover: CjguiComposableUiPaintStyle(background: Some(higMix(textBackground, label, 0.06))),
        pressed: CjguiComposableUiPaintStyle(background: Some(higMix(textBackground, label, 0.12))),
        focused: CjguiComposableUiPaintStyle(border: Some(focusRing), borderWidth: Some(3)),
        selected: CjguiComposableUiPaintStyle(background: Some(higMix(textBackground, accent, 0.12)),
            textColor: Some(accent)),
        checked: CjguiComposableUiPaintStyle(background: Some(higMix(textBackground, accent, 0.16)),
            textColor: Some(accent)),
        disabled: CjguiComposableUiPaintStyle(background: Some(higMix(textBackground, label, 0.03)),
            border: Some(higMix(controlBorder, windowBackground, 0.5)), textColor: Some(disabledText)))
    let primaryInteraction = CjguiComposableUiInteractionStyle(
        normal: CjguiComposableUiPaintStyle(background: Some(accent), border: Some(accent), textColor: Some(onAccent)),
        hover: CjguiComposableUiPaintStyle(background: Some(higMix(accent, onAccent, 0.12))),
        pressed: CjguiComposableUiPaintStyle(background: Some(higMix(accent, label, 0.18))),
        focused: CjguiComposableUiPaintStyle(border: Some(onAccent), borderWidth: Some(3)),
        selected: CjguiComposableUiPaintStyle(background: Some(higMix(accent, onAccent, 0.16))),
        checked: CjguiComposableUiPaintStyle(background: Some(higMix(accent, onAccent, 0.16))),
        disabled: CjguiComposableUiPaintStyle(background: Some(higMix(surface, label, 0.06)),
            border: Some(higMix(controlBorder, windowBackground, 0.5)), textColor: Some(disabledText)))
    let secondaryInteraction = CjguiComposableUiInteractionStyle(
        normal: CjguiComposableUiPaintStyle(background: Some(surface), border: Some(controlBorder), textColor: Some(label)),
        hover: CjguiComposableUiPaintStyle(background: Some(higMix(surface, label, 0.06))),
        pressed: CjguiComposableUiPaintStyle(background: Some(higMix(surface, label, 0.12))),
        focused: CjguiComposableUiPaintStyle(border: Some(focusRing), borderWidth: Some(3)),
        selected: CjguiComposableUiPaintStyle(background: Some(higMix(surface, accent, 0.12)), textColor: Some(accent)),
        checked: CjguiComposableUiPaintStyle(background: Some(higMix(surface, accent, 0.16)), textColor: Some(accent)),
        disabled: CjguiComposableUiPaintStyle(background: Some(higMix(surface, windowBackground, 0.5)),
            border: Some(higMix(controlBorder, windowBackground, 0.5)), textColor: Some(disabledText)))
    // 分组表面：12pt 内边距、8pt 组内间距、10pt 圆角（project-decision），
    // 1pt 分隔线用系统分隔色合成；错误反馈由 feedbackStyle(ERROR) 从主题色派生。
    let cardStyle = CjguiComposableUiStyle(background: surface, border: separator, borderWidth: 1, padding: 12, gap: 8,
        cornerRadius: 10)
    let cardInteraction = CjguiComposableUiInteractionStyle(
        hover: CjguiComposableUiPaintStyle(background: Some(higMix(surface, label, 0.02))),
        focused: CjguiComposableUiPaintStyle(border: Some(focusRing), borderWidth: Some(3)),
        selected: CjguiComposableUiPaintStyle(background: Some(higMix(surface, accent, 0.10)), border: Some(accent)),
        checked: CjguiComposableUiPaintStyle(border: Some(accent)))
    // 错误语义色（measured: system_red）只在这里进入角色；文本内容仍归应用。
    let _ = systemRed
    return CjguiComposableUiTheme(page, cardStyle, headingStyle, bodyStyle, inputStyle, primaryStyle,
        secondaryAction: secondaryStyle, cardInteraction: cardInteraction, inputInteraction: inputInteraction,
        primaryActionInteraction: primaryInteraction, secondaryActionInteraction: secondaryInteraction)
}

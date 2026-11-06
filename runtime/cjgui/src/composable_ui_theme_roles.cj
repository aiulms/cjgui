package cjgui

import std.collection.*

/// Experimental semantic feedback. Content and retry actions remain with the
/// application owner; these roles never infer status from message text.
public enum CjguiComposableUiFeedbackKind {
    EMPTY | LOADING | ERROR | SUCCESS
}

/// Theme the existing feedback compositions, preserving their textual kind
/// markers, action routing and no-data/no-match distinction.
extend CjguiStatusMessageStyle {
    public static func themed(theme: CjguiComposableUiTheme, kind: String): CjguiStatusMessageStyle {
        let role = theme.feedbackStyle(if (kind == CJGUI_STATUS_ERROR) {
            CjguiComposableUiFeedbackKind.ERROR
        } else if (kind == CJGUI_STATUS_SUCCESS) {
            CjguiComposableUiFeedbackKind.SUCCESS
        } else {
            CjguiComposableUiFeedbackKind.EMPTY
        })
        let action = theme.actionStyle().boundStyle()
        return CjguiStatusMessageStyle(container: role.base,
            chip: CjguiComposableUiStyle(fixedWidth: 52, fixedHeight: 22, fontSize: 11.0, textColor: role
                .base
                .textColor, fontWeight: 600),
            text: CjguiComposableUiStyle(fontSize: 12.0, textColor: role.base.textColor), action: action.style,
            actionInteraction: action.interaction, gap: 8, rowGap: 4)
    }
}

extend CjguiContentStateStyle {
    public static func themed(theme: CjguiComposableUiTheme, kind: String): CjguiContentStateStyle {
        let role = theme.feedbackStyle(
            if (kind == CJGUI_CONTENT_ERROR) {
                CjguiComposableUiFeedbackKind.ERROR
            } else if (kind == CJGUI_CONTENT_LOADING) {
                CjguiComposableUiFeedbackKind.LOADING
            } else {
                CjguiComposableUiFeedbackKind.EMPTY
            })
        let action = theme.actionStyle().boundStyle()
        return CjguiContentStateStyle(container: role.base,
            title: CjguiComposableUiStyle(fontSize: 14.0, fontWeight: 600, textColor: role.base.textColor),
            detail: CjguiComposableUiStyle(fontSize: 12.0, textColor: theme.body.textColor), action: action.style,
            actionInteraction: action.interaction, gap: 8)
    }
}

private func themeRoleMix(a: CjguiComposableUiColor, b: CjguiComposableUiColor, amount: Float64): CjguiComposableUiColor {
    return CjguiComposableUiColor(a.red + (b.red - a.red) * amount, a.green + (b.green - a.green) * amount,
        a.blue + (b.blue - a.blue) * amount, a.alpha + (b.alpha - a.alpha) * amount)
}

private func themeRoleInteraction(base: CjguiComposableUiStyle, accent: CjguiComposableUiColor,
    surface: CjguiComposableUiColor, foreground: CjguiComposableUiColor, selectable!: Bool = false): CjguiComposableUiInteractionStyle {
    let soft = themeRoleMix(surface, accent, 0.12)
    return CjguiComposableUiInteractionStyle(
        // Normal is the declared base: a local geometry override cannot repaint
        // a secondary command as primary, and switching palettes is one value.
        hover: if (selectable) {
        CjguiComposableUiPaintStyle(textColor: Some(accent))
    } else {
        CjguiComposableUiPaintStyle(background: Some(themeRoleMix(base.background, foreground, 0.07)))
    }, pressed: CjguiComposableUiPaintStyle(background: Some(themeRoleMix(base.background, foreground, 0.13))),
        focused: CjguiComposableUiPaintStyle(border: Some(accent), borderWidth: Some(2)),
        selected: CjguiComposableUiPaintStyle(background: Some(soft), textColor: Some(accent)),
        checked: CjguiComposableUiPaintStyle(background: Some(soft), textColor: Some(accent)),
        disabled: CjguiComposableUiPaintStyle(background: Some(surface),
            textColor: Some(themeRoleMix(surface, foreground, 0.44)),
            border: Some(themeRoleMix(surface, foreground, 0.14)), borderWidth: Some(1)))
}

/// A small desktop vocabulary on the existing Theme, NamedStyle and BoundStyle
/// paths. 32-point actions and the 4/8/12/16 spacing rhythm are CJGUI desktop
/// adaptations, not claimed HarmonyOS token values. No layout or interaction
/// engine is introduced here; generated and handwritten nodes share the same
/// named definitions. Existing Theme fields/constructors remain compatible.
extend CjguiComposableUiTheme {
    public static func warmPaper(): CjguiComposableUiTheme {
        let paper = CjguiComposableUiColor(0.973, 0.961, 0.941, 1.0)
        let panel = CjguiComposableUiColor(0.945, 0.929, 0.902, 1.0)
        let ink = CjguiComposableUiColor(0.180, 0.169, 0.153, 1.0)
        let muted = CjguiComposableUiColor(0.420, 0.396, 0.361, 1.0)
        let line = CjguiComposableUiColor(0.851, 0.824, 0.784, 1.0)
        let accent = CjguiComposableUiColor(0.545, 0.196, 0.153, 1.0)
        let primary = CjguiComposableUiStyle(fixedHeight: 32, padding: 8, cornerRadius: 8, background: accent,
            border: accent, textColor: paper, fontSize: 12.0, fontWeight: 500, textMaxLines: 1, textOverflow: "ellipsis")
        let secondary = CjguiComposableUiStyle(fixedHeight: 32, padding: 8, cornerRadius: 8, background: paper,
            border: line, textColor: ink, fontSize: 12.0, textMaxLines: 1, textOverflow: "ellipsis")
        let input = CjguiComposableUiStyle(fixedHeight: 32, padding: 8, cornerRadius: 8, background: paper, border: line,
            textColor: ink, fontSize: 12.0)
        return CjguiComposableUiTheme(CjguiComposableUiStyle(background: paper, padding: 16, gap: 12),
            CjguiComposableUiStyle(background: panel, border: line, padding: 12, gap: 8, cornerRadius: 10),
            CjguiComposableUiStyle(textColor: ink, fontSize: 20.0, fontWeight: 600),
            CjguiComposableUiStyle(textColor: muted, fontSize: 13.0), input, primary, secondaryAction: secondary,
            inputInteraction: themeRoleInteraction(input, accent, panel, ink),
            primaryActionInteraction: themeRoleInteraction(primary, ink, panel, paper),
            secondaryActionInteraction: themeRoleInteraction(secondary, accent, panel, ink))
    }

    /// Navigation occupies the available row width. Its selection fill survives
    /// hover; focus adds a border without replacing selection or moving layout.
    public func navigationRow(): CjguiComposableUiNamedStyle {
        let base = CjguiComposableUiStyle(growX: 1, fixedHeight: 32, padding: 8, cornerRadius: 8,
            textColor: heading.textColor, fontSize: 12.0, textMaxLines: 1, textOverflow: "ellipsis", clipsContent: true,
            border: CjguiComposableUiColor(0.0, 0.0, 0.0, 0.0))
        return CjguiComposableUiNamedStyle("navigation", base,
            interaction: themeRoleInteraction(base, primaryAction.background, card.background, heading.textColor,
                selectable: true), purpose: "Navigation row; owner selects, window focuses")
    }

    /// Data/related-item rows use a quiet surface and can wrap to two lines.
    public func itemRow(): CjguiComposableUiNamedStyle {
        let base = CjguiComposableUiStyle(growX: 1, minHeight: 36, padding: 8, cornerRadius: 8,
            background: input.background, border: card.border, textColor: heading.textColor, fontSize: 12.0,
            textMaxLines: 2, textOverflow: "ellipsis", clipsContent: true)
        return CjguiComposableUiNamedStyle("item", base,
            interaction: themeRoleInteraction(base, primaryAction.background, card.background, heading.textColor,
                selectable: true), purpose: "Related item or selectable data row")
    }

    public func actionStyle(primary!: Bool = false, quiet!: Bool = false): CjguiComposableUiNamedStyle {
        let name = if (primary) {
            "primary_action"
        } else if (quiet) {
            "quiet_action"
        } else {
            "secondary_action"
        }
        let authored = if (primary) {
            primaryAction
        } else {
            secondaryAction
        }
        let base = if (quiet && !primary) {
            CjguiComposableUiStyle(fixedHeight: 32, padding: 8, cornerRadius: 8, textColor: heading.textColor,
                fontSize: 12.0, textMaxLines: 1, textOverflow: "ellipsis")
        } else {
            CjguiComposableUiNamedStyle(name, authored).localStyle(fixedHeight: Some(32), padding: Some(8),
                cornerRadius: Some(8), fontSize: Some(12.0), textMaxLines: Some(1), textOverflow: Some("ellipsis"))
        }
        return CjguiComposableUiNamedStyle(name, base,
            interaction: themeRoleInteraction(base, if (primary) {
                heading.textColor
            } else {
                primaryAction.background
            }, card.background, if (primary) {
                primaryAction.textColor
            } else {
                heading.textColor
            }), purpose: "Desktop command")
    }

    public func fieldStyle(): CjguiComposableUiNamedStyle {
        let base = CjguiComposableUiNamedStyle("input", input).localStyle(fixedHeight: Some(32), padding: Some(8),
            cornerRadius: Some(8), fontSize: Some(12.0))
        return CjguiComposableUiNamedStyle("input", base,
            interaction: themeRoleInteraction(base, primaryAction.background, card.background, heading.textColor),
            purpose: "Editable field; value and validation remain owner controlled")
    }

    public func surfaceStyle(): CjguiComposableUiNamedStyle {
        return CjguiComposableUiNamedStyle("card", card, purpose: "Grouped content surface")
    }

    public func captionStyle(): CjguiComposableUiNamedStyle {
        return CjguiComposableUiNamedStyle("caption", CjguiComposableUiStyle(textColor: body.textColor, fontSize: 11.0),
            purpose: "Supporting metadata")
    }

    public func feedbackStyle(kind: CjguiComposableUiFeedbackKind): CjguiComposableUiNamedStyle {
        let dark = page.background.red + page.background.green + page.background.blue < 1.5
        let (name, tone) = match (kind) {
            case CjguiComposableUiFeedbackKind.EMPTY => ("empty", body.textColor)
            case CjguiComposableUiFeedbackKind.LOADING => ("loading", primaryAction.background)
            case CjguiComposableUiFeedbackKind.ERROR => ("error", if (dark) {
                    CjguiComposableUiColor(1.0, 0.60, 0.56, 1.0)
                } else {
                    CjguiComposableUiColor(0.68, 0.18, 0.16, 1.0)
                })
            case CjguiComposableUiFeedbackKind.SUCCESS => ("success", if (dark) {
                    CjguiComposableUiColor(0.48, 0.84, 0.66, 1.0)
                } else {
                    CjguiComposableUiColor(0.18, 0.40, 0.30, 1.0)
                })
        }
        return CjguiComposableUiNamedStyle(name,
            CjguiComposableUiStyle(growX: 1, padding: 8, cornerRadius: 8, fontSize: 12.0,
                background: themeRoleMix(card.background, tone, 0.05), border: themeRoleMix(card.background, tone, 0.25),
                textColor: tone), purpose: "Owner-declared ${name} feedback; natural content height")
    }

    /// Register these in the existing capability catalog to expose exactly the
    /// same roles to a generated/mixed interface. No implicit global theme.
    public func namedStyles(): ArrayList<CjguiComposableUiNamedStyle> {
        return ArrayList<CjguiComposableUiNamedStyle>(
            [
                navigationRow(),
                itemRow(),
                actionStyle(primary: true),
                actionStyle(),
                actionStyle(quiet: true),
                fieldStyle(),
                surfaceStyle(),
                CjguiComposableUiNamedStyle("heading", heading),
                CjguiComposableUiNamedStyle("body", body),
                captionStyle(),
                feedbackStyle(CjguiComposableUiFeedbackKind.EMPTY),
                feedbackStyle(CjguiComposableUiFeedbackKind.LOADING),
                feedbackStyle(CjguiComposableUiFeedbackKind.ERROR),
                feedbackStyle(CjguiComposableUiFeedbackKind.SUCCESS)
            ]
        )
    }
}

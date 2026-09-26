// Shared named visual styles: ONE application definition that handwritten
// helpers, generated nodes and registered composites all resolve through.
//
// A named style is an immutable base `CjguiComposableUiStyle` plus the existing
// `CjguiComposableUiInteractionStyle` paint overrides. Nothing here re-implements
// the interaction state machine, the paint fast path, the theme type or the
// layout engine: the catalog is a discoverable, validated declaration of the same
// values an application already passes directly, so an external author can
// reference a style by name instead of guessing colors or duplicating a theme.
package cjgui

import std.collection.*

/// A whole-group binding value: the resolved base style AND the interaction
/// paint overrides a component should install together. A component accepting
/// this value needs exactly one style argument — picking the named role once
/// also brings hover/pressed/focused/disabled along.
public struct CjguiComposableUiBoundStyle {
    public let style: CjguiComposableUiStyle
    public let interaction: CjguiComposableUiInteractionStyle

    public init(style: CjguiComposableUiStyle, interaction: CjguiComposableUiInteractionStyle) {
        this.style = style
        this.interaction = interaction
    }
}

/// A reusable named style: a base style plus the interaction-state paint
/// overrides every presentation already understands.
public class CjguiComposableUiNamedStyle {
    public let name: String
    public let base: CjguiComposableUiStyle
    public let interaction: CjguiComposableUiInteractionStyle
    public let purpose: String

    public init(name: String, base: CjguiComposableUiStyle,
                interaction!: CjguiComposableUiInteractionStyle = CjguiComposableUiInteractionStyle(),
                purpose!: String = "") {
        this.name = name
        this.base = base
        this.interaction = interaction
        this.purpose = purpose
    }

    /// The style ONE consumption site uses: this named definition with optional
    /// LOCAL geometry/typography adjustments. This is the framework's one-shot
    /// consumption entry - a developer picks the named style once and passes
    /// `localStyle(...)` plus `interaction` to the same component, instead of
    /// re-assembling base fields at every call site.
    ///
    /// Paint coverage order is fixed and single-sourced: background, border,
    /// textColor and borderWidth ALWAYS come from the definition's base (they
    /// are not parameters here), and the interaction states resolve their paint
    /// on top of that base through the existing `resolve` order. A local site
    /// may adjust layout and typography only, and the definition itself is
    /// never mutated.
    public func localStyle(fontSize!: ?Float64 = None, fontWeight!: ?Int64 = None,
        padding!: ?Int64 = None, gap!: ?Int64 = None, fixedWidth!: ?Int64 = None,
        fixedHeight!: ?Int64 = None, growX!: ?Int64 = None, growY!: ?Int64 = None,
        minWidth!: ?Int64 = None, maxWidth!: ?Int64 = None, minHeight!: ?Int64 = None,
        maxHeight!: ?Int64 = None, alignX!: ?Int64 = None, alignY!: ?Int64 = None,
        cornerRadius!: ?Int64 = None, fontFamily!: ?String = None): CjguiComposableUiStyle {
        return CjguiComposableUiStyle(
            background: base.background,
            border: base.border,
            textColor: base.textColor,
            padding: match (padding) { case Some(value) => value case None => base.padding },
            gap: match (gap) { case Some(value) => value case None => base.gap },
            fixedWidth: match (fixedWidth) { case Some(value) => value case None => base.fixedWidth },
            fixedHeight: match (fixedHeight) { case Some(value) => value case None => base.fixedHeight },
            growX: match (growX) { case Some(value) => value case None => base.growX },
            growY: match (growY) { case Some(value) => value case None => base.growY },
            borderWidth: base.borderWidth,
            fontSize: match (fontSize) { case Some(value) => value case None => base.fontSize },
            fontWeight: match (fontWeight) { case Some(value) => value case None => base.fontWeight },
            minWidth: match (minWidth) { case Some(value) => value case None => base.minWidth },
            maxWidth: match (maxWidth) { case Some(value) => value case None => base.maxWidth },
            minHeight: match (minHeight) { case Some(value) => value case None => base.minHeight },
            maxHeight: match (maxHeight) { case Some(value) => value case None => base.maxHeight },
            alignX: match (alignX) { case Some(value) => value case None => base.alignX },
            alignY: match (alignY) { case Some(value) => value case None => base.alignY },
            cornerRadius: match (cornerRadius) { case Some(value) => value case None => base.cornerRadius },
            clipsContent: base.clipsContent,
            fontFamily: match (fontFamily) { case Some(value) => value case None => base.fontFamily })
    }

    /// The whole-group binding entry: the SAME local geometry resolution as
    /// `localStyle`, packaged with the definition's interaction paint so a
    /// component installs base + interaction from ONE argument. Paint coverage
    /// order is identical to `localStyle` (background/border/textColor/
    /// borderWidth always from the definition); the definition is never mutated.
    public func boundStyle(fontSize!: ?Float64 = None, fontWeight!: ?Int64 = None,
        padding!: ?Int64 = None, gap!: ?Int64 = None, fixedWidth!: ?Int64 = None,
        fixedHeight!: ?Int64 = None, growX!: ?Int64 = None, growY!: ?Int64 = None,
        minWidth!: ?Int64 = None, maxWidth!: ?Int64 = None, minHeight!: ?Int64 = None,
        maxHeight!: ?Int64 = None, alignX!: ?Int64 = None, alignY!: ?Int64 = None,
        cornerRadius!: ?Int64 = None, fontFamily!: ?String = None): CjguiComposableUiBoundStyle {
        return CjguiComposableUiBoundStyle(
            localStyle(fontSize: fontSize, fontWeight: fontWeight, padding: padding, gap: gap,
                fixedWidth: fixedWidth, fixedHeight: fixedHeight, growX: growX, growY: growY,
                minWidth: minWidth, maxWidth: maxWidth, minHeight: minHeight, maxHeight: maxHeight,
                alignX: alignX, alignY: alignY, cornerRadius: cornerRadius, fontFamily: fontFamily),
            interaction)
    }
}

private let CJGUI_NAMED_STYLE_HEX = "0123456789abcdef"

private func namedStyleByte(value: Float64): Int64 {
    var scaled = value * 255.0
    if (scaled < 0.0) { scaled = 0.0 }
    if (scaled > 255.0) { scaled = 255.0 }
    // Round to nearest so a value that came from a token round-trips exactly.
    return Int64(scaled + 0.5)
}

/// Strict, publicly explainable color encoding: `#RRGGBB` or `#RRGGBBAA`, two
/// hex digits per channel. The same token appears in discovery and in a submitted
/// property, so an external author never sends a float quadruple, a platform
/// color object or a theme name.
public func cjguiComposableUiColorToken(color: CjguiComposableUiColor): String {
    var builder = StringBuilder()
    builder.append("#")
    for (channel in [color.red, color.green, color.blue, color.alpha]) {
        let byte = namedStyleByte(channel)
        builder.append(CJGUI_NAMED_STYLE_HEX[(byte / 16)..(byte / 16 + 1)])
        builder.append(CJGUI_NAMED_STYLE_HEX[(byte % 16)..(byte % 16 + 1)])
    }
    return builder.toString()
}

/// Bounded uppercase hex for an arbitrary purpose string, so discovery can
/// publish human text on ONE protocol line without leaking spaces or newlines.
private func namedStyleHexEncode(text: String): String {
    if (text.size == 0) {
        return "-"
    }
    let digits = "0123456789ABCDEF"
    let builder = StringBuilder()
    for (byte in text.toArray()) {
        let value = Int64(byte)
        builder.append(digits[(value / 16)..(value / 16 + 1)])
        builder.append(digits[(value % 16)..(value % 16 + 1)])
    }
    return builder.toString()
}

/// The public alignment token for a resolved alignment value, so discovery never
/// publishes a raw enum number.
private func namedStyleAlignmentToken(alignment: Int64): String {
    if (alignment == CJGUI_COMPOSABLE_UI_ALIGN_START) { return "start" }
    if (alignment == CJGUI_COMPOSABLE_UI_ALIGN_CENTER) { return "center" }
    if (alignment == CJGUI_COMPOSABLE_UI_ALIGN_END) { return "end" }
    return "stretch"
}

private func namedStyleHexDigit(byte: UInt8): Int64 {
    if (byte >= 48 && byte <= 57) { return Int64(byte - 48) }
    if (byte >= 97 && byte <= 102) { return Int64(byte - 97 + 10) }
    if (byte >= 65 && byte <= 70) { return Int64(byte - 65 + 10) }
    return -1
}

/// Parses exactly `#RRGGBB` or `#RRGGBBAA`. Any other length, a missing `#`, a
/// non-hex digit or an empty token returns None: an illegal color is refused by
/// the caller instead of being silently replaced by a default.
public func cjguiComposableUiParseColorToken(token: String): ?CjguiComposableUiColor {
    let bytes = token.toArray()
    if (bytes.size != 7 && bytes.size != 9) {
        return None
    }
    if (bytes[0] != 35) {
        return None
    }
    var channels = ArrayList<Int64>()
    var index = 1
    while (index + 1 < bytes.size) {
        let high = namedStyleHexDigit(bytes[index])
        let low = namedStyleHexDigit(bytes[index + 1])
        if (high < 0 || low < 0) {
            return None
        }
        channels.add(high * 16 + low)
        index += 2
    }
    if (channels.size != 3 && channels.size != 4) {
        return None
    }
    let alpha = if (channels.size == 4) { channels[3] } else { 255 }
    return Some(CjguiComposableUiColor(
        Float64(channels[0]) / 255.0, Float64(channels[1]) / 255.0,
        Float64(channels[2]) / 255.0, Float64(alpha) / 255.0))
}

/// Application-owned registry of named styles. Register/update/remove all feed
/// ONE revision and ONE discovery text, so an external reader never needs a
/// second hand-maintained style table.
public class CjguiComposableUiNamedStyleCatalog {
    private var styles: HashMap<String, CjguiComposableUiNamedStyle>
    private var order: ArrayList<String>
    private var issue: String

    public init() {
        this.styles = HashMap<String, CjguiComposableUiNamedStyle>()
        this.order = ArrayList<String>()
        this.issue = ""
    }

    /// A published reference: a bounded protocol identifier, never free text.
    public static func isValidName(name: String): Bool {
        if (name.size == 0 || name.size > 64) {
            return false
        }
        let bytes = name.toArray()
        let first = bytes[0]
        let firstOk = (first >= 65 && first <= 90) || (first >= 97 && first <= 122) || first == 95
        if (!firstOk) {
            return false
        }
        for (byte in bytes) {
            let ok = (byte >= 65 && byte <= 90) || (byte >= 97 && byte <= 122) ||
                (byte >= 48 && byte <= 57) || byte == 95 || byte == 45
            if (!ok) {
                return false
            }
        }
        return true
    }

    /// Machine-readable reason of the last refused operation ("" when it worked).
    public func lastIssue(): String {
        return issue
    }

    public func register(style: CjguiComposableUiNamedStyle): Bool {
        if (!CjguiComposableUiNamedStyleCatalog.isValidName(style.name)) {
            issue = "named_style_name_invalid"
            return false
        }
        if (styles.contains(style.name)) {
            issue = "duplicate_named_style"
            return false
        }
        styles.add(style.name, style)
        order.add(style.name)
        issue = ""
        return true
    }

    /// Replaces the definition of an existing name. A metadata/geometry change is
    /// a real definition change, so discovery and observation move with it.
    public func update(style: CjguiComposableUiNamedStyle): Bool {
        if (!styles.contains(style.name)) {
            issue = "named_style_not_registered"
            return false
        }
        styles.add(style.name, style)
        issue = ""
        return true
    }

    public func remove(name: String): Bool {
        if (!styles.contains(name)) {
            issue = "named_style_not_registered"
            return false
        }
        let _ = styles.remove(name)
        var index = 0
        while (index < order.size) {
            if (order[index] == name) {
                let _ = order.remove(at: index)
                break
            }
            index += 1
        }
        issue = ""
        return true
    }

    public func forName(name: String): ?CjguiComposableUiNamedStyle {
        return styles.get(name)
    }

    /// Registered names in registration order.
    public func names(): ArrayList<String> {
        let result = ArrayList<String>()
        for (name in order) {
            result.add(name)
        }
        return result
    }

    public func size(): Int64 {
        return order.size
    }

    /// Deterministic fingerprint of every definition (inputs, interaction paints
    /// and purpose). Registration, update and removal all move it.
    public func revision(): Int64 {
        var hash: Int64 = 23
        for (name in order) {
            let styleOption = styles.get(name)
            if (let Some(style) <- styleOption) {
                for (byte in name.toArray()) {
                    hash = (hash * 131 + Int64(byte)) % 2147483647
                }
                let base = style.base
                for (text in [cjguiComposableUiColorToken(base.background),
                    cjguiComposableUiColorToken(base.border), cjguiComposableUiColorToken(base.textColor)]) {
                    for (byte in text.toArray()) {
                        hash = (hash * 131 + Int64(byte)) % 2147483647
                    }
                }
                for (value in [base.borderWidth, base.padding, base.gap, base.fixedWidth, base.fixedHeight,
                    base.growX, base.growY, base.fontWeight, base.minWidth, base.maxWidth, base.minHeight,
                    base.maxHeight, base.alignX, base.alignY, base.cornerRadius]) {
                    hash = (hash * 131 + value) % 2147483647
                }
                hash = (hash * 131 + Int64(base.fontSize * 100.0)) % 2147483647
                hash = (hash * 131 + if (base.clipsContent) { 1 } else { 0 }) % 2147483647
                for (byte in style.purpose.toArray()) {
                    hash = (hash * 131 + Int64(byte)) % 2147483647
                }
                for (paint in [style.interaction.normal, style.interaction.hover, style.interaction.pressed,
                    style.interaction.focused, style.interaction.disabled, style.interaction.selected,
                    style.interaction.checked]) {
                    for (label in ["background", "border", "textColor"]) {
                        for (byte in label.toArray()) {
                            hash = (hash * 131 + Int64(byte)) % 2147483647
                        }
                        let color = if (label == "background") { paint.background }
                            else if (label == "border") { paint.border } else { paint.textColor }
                        match (color) {
                            case Some(value) =>
                                for (byte in cjguiComposableUiColorToken(value).toArray()) {
                                    hash = (hash * 131 + Int64(byte)) % 2147483647
                                }
                            case None => hash = (hash * 131 + 7) % 2147483647
                        }
                    }
                    match (paint.borderWidth) {
                        case Some(value) => hash = (hash * 131 + value) % 2147483647
                        case None => hash = (hash * 131 + 11) % 2147483647
                    }
                }
            }
        }
        return hash
    }

    private static func paintTokens(paint: CjguiComposableUiPaintStyle): String {
        let background = match (paint.background) {
            case Some(color) => cjguiComposableUiColorToken(color)
            case None => "-"
        }
        let border = match (paint.border) {
            case Some(color) => cjguiComposableUiColorToken(color)
            case None => "-"
        }
        let textColor = match (paint.textColor) {
            case Some(color) => cjguiComposableUiColorToken(color)
            case None => "-"
        }
        let borderWidth = match (paint.borderWidth) {
            case Some(value) => "${value}"
            case None => "-"
        }
        return "background=${background} border=${border} textColor=${textColor} borderWidth=${borderWidth}"
    }

    /// Discovery derived from the registered definitions: one line per name with
    /// the real base values and the interaction paint overrides. It never exposes
    /// a platform object or a native handle.
    public func describe(): String {
        let builder = StringBuilder()
        for (name in order) {
            let styleOption = styles.get(name)
            if (let None <- styleOption) {
                continue
            }
            let style = match (styleOption) {
                case Some(value) => value
                case None => CjguiComposableUiNamedStyle(name, CjguiComposableUiStyle())
            }
            let base = style.base
            builder.append("STYLE ${name} " +
                "background=${cjguiComposableUiColorToken(base.background)} " +
                "border=${cjguiComposableUiColorToken(base.border)} " +
                "textColor=${cjguiComposableUiColorToken(base.textColor)} " +
                "borderWidth=${base.borderWidth} padding=${base.padding} gap=${base.gap} " +
                "fixedWidth=${base.fixedWidth} fixedHeight=${base.fixedHeight} " +
                "growX=${base.growX} growY=${base.growY} fontSize=${Int64(base.fontSize)} " +
                "fontWeight=${base.fontWeight} minWidth=${base.minWidth} maxWidth=${base.maxWidth} " +
                "minHeight=${base.minHeight} maxHeight=${base.maxHeight} " +
                "alignX=${namedStyleAlignmentToken(base.alignX)} " +
                "alignY=${namedStyleAlignmentToken(base.alignY)} " +
                "purpose_hex=${if (style.purpose.size > 0) { namedStyleHexEncode(style.purpose) } else { "-" }}\n")
            builder.append("STYLE_STATE ${name} normal[${CjguiComposableUiNamedStyleCatalog.paintTokens(style.interaction.normal)}] " +
                "hover[${CjguiComposableUiNamedStyleCatalog.paintTokens(style.interaction.hover)}] " +
                "pressed[${CjguiComposableUiNamedStyleCatalog.paintTokens(style.interaction.pressed)}] " +
                "focused[${CjguiComposableUiNamedStyleCatalog.paintTokens(style.interaction.focused)}] " +
                "disabled[${CjguiComposableUiNamedStyleCatalog.paintTokens(style.interaction.disabled)}] " +
                "selected[${CjguiComposableUiNamedStyleCatalog.paintTokens(style.interaction.selected)}] " +
                "checked[${CjguiComposableUiNamedStyleCatalog.paintTokens(style.interaction.checked)}]\n")
        }
        return builder.toString()
    }
}

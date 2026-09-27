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
        interaction!: CjguiComposableUiInteractionStyle = CjguiComposableUiInteractionStyle(), purpose!: String = "") {
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
    public func localStyle(fontSize!: ?Float64 = None, fontWeight!: ?Int64 = None, padding!: ?Int64 = None,
        gap!: ?Int64 = None, fixedWidth!: ?Int64 = None, fixedHeight!: ?Int64 = None, growX!: ?Int64 = None,
        growY!: ?Int64 = None, minWidth!: ?Int64 = None, maxWidth!: ?Int64 = None, minHeight!: ?Int64 = None,
        maxHeight!: ?Int64 = None, alignX!: ?Int64 = None, alignY!: ?Int64 = None, cornerRadius!: ?Int64 = None,
        fontFamily!: ?String = None): CjguiComposableUiStyle {
        return CjguiComposableUiStyle(background: base.background, border: base.border, textColor: base.textColor,
            padding: match (padding) {
                case Some(value) => value
                case None => base.padding
            }, gap: match (gap) {
                case Some(value) => value
                case None => base.gap
            }, fixedWidth: match (fixedWidth) {
                case Some(value) => value
                case None => base.fixedWidth
            }, fixedHeight: match (fixedHeight) {
                case Some(value) => value
                case None => base.fixedHeight
            }, growX: match (growX) {
                case Some(value) => value
                case None => base.growX
            }, growY: match (growY) {
                case Some(value) => value
                case None => base.growY
            }, borderWidth: base.borderWidth, fontSize: match (fontSize) {
                case Some(value) => value
                case None => base.fontSize
            }, fontWeight: match (fontWeight) {
                case Some(value) => value
                case None => base.fontWeight
            }, minWidth: match (minWidth) {
                case Some(value) => value
                case None => base.minWidth
            }, maxWidth: match (maxWidth) {
                case Some(value) => value
                case None => base.maxWidth
            }, minHeight: match (minHeight) {
                case Some(value) => value
                case None => base.minHeight
            }, maxHeight: match (maxHeight) {
                case Some(value) => value
                case None => base.maxHeight
            }, alignX: match (alignX) {
                case Some(value) => value
                case None => base.alignX
            }, alignY: match (alignY) {
                case Some(value) => value
                case None => base.alignY
            }, cornerRadius: match (cornerRadius) {
                case Some(value) => value
                case None => base.cornerRadius
            }, clipsContent: base.clipsContent, shadow: base.shadow, gradient: base.gradient,
            effectGroup: base.effectGroup,
            effectRejection: base.effectRejection, fontFamily: match (fontFamily) {
                case Some(value) => value
                case None => base.fontFamily
            })
    }

    /// The whole-group binding entry: the SAME local geometry resolution as
    /// `localStyle`, packaged with the definition's interaction paint so a
    /// component installs base + interaction from ONE argument. Paint coverage
    /// order is identical to `localStyle` (background/border/textColor/
    /// borderWidth always from the definition); the definition is never mutated.
    public func boundStyle(fontSize!: ?Float64 = None, fontWeight!: ?Int64 = None, padding!: ?Int64 = None,
        gap!: ?Int64 = None, fixedWidth!: ?Int64 = None, fixedHeight!: ?Int64 = None, growX!: ?Int64 = None,
        growY!: ?Int64 = None, minWidth!: ?Int64 = None, maxWidth!: ?Int64 = None, minHeight!: ?Int64 = None,
        maxHeight!: ?Int64 = None, alignX!: ?Int64 = None, alignY!: ?Int64 = None, cornerRadius!: ?Int64 = None,
        fontFamily!: ?String = None): CjguiComposableUiBoundStyle {
        return CjguiComposableUiBoundStyle(
            localStyle(fontSize: fontSize, fontWeight: fontWeight, padding: padding, gap: gap, fixedWidth: fixedWidth,
                fixedHeight: fixedHeight, growX: growX, growY: growY, minWidth: minWidth, maxWidth: maxWidth,
                minHeight: minHeight, maxHeight: maxHeight, alignX: alignX, alignY: alignY, cornerRadius: cornerRadius,
                fontFamily: fontFamily), interaction)
    }
}

private let CJGUI_NAMED_STYLE_HEX = "0123456789abcdef"

private func namedStyleByte(value: Float64): Int64 {
    var scaled = value * 255.0
    if (scaled < 0.0) {
        scaled = 0.0
    }
    if (scaled > 255.0) {
        scaled = 255.0
    }
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
    if (alignment == CJGUI_COMPOSABLE_UI_ALIGN_START) {
        return "start"
    }
    if (alignment == CJGUI_COMPOSABLE_UI_ALIGN_CENTER) {
        return "center"
    }
    if (alignment == CJGUI_COMPOSABLE_UI_ALIGN_END) {
        return "end"
    }
    return "stretch"
}

private func namedStyleHexDigit(byte: UInt8): Int64 {
    if (byte >= 48 && byte <= 57) {
        return Int64(byte - 48)
    }
    if (byte >= 97 && byte <= 102) {
        return Int64(byte - 97 + 10)
    }
    if (byte >= 65 && byte <= 70) {
        return Int64(byte - 65 + 10)
    }
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
    let alpha = if (channels.size == 4) {
        channels[3]
    } else {
        255
    }
    return Some(
        CjguiComposableUiColor(Float64(channels[0]) / 255.0, Float64(channels[1]) / 255.0, Float64(channels[2]) / 255.0,
            Float64(alpha) / 255.0))
}

/// The declaration token for an explicit effect CLEAR: the empty string and the
/// literal `none` both mean "clear the effect" (they map to None), while an
/// ABSENT property means "inherit the base". This is the ONE empty-string
/// semantics: the generated `shadow`/`gradient` properties and the handwritten
/// token path both use it, so `none` and "" are interchangeable and never mean
/// "keep the previous effect".
public func cjguiComposableUiEffectTokenIsNone(token: String): Bool {
    return token.size == 0 || token == "none"
}

/// Bounded integer literal for an effect token. An empty field, a lone sign or
/// a non-digit returns None so a malformed effect is refused whole instead of
/// being read from a partial value. Range is checked by the CALLER, which knows
/// the unit (logical points versus percent).
private func cjguiComposableUiParseEffectInt(token: String): ?Int64 {
    if (token.size == 0) {
        return None
    }
    var result: Int64 = 0
    var negative = false
    var index = 0
    for (byte in token.toArray()) {
        if (index == 0 && byte == 45) {
            negative = true
            index += 1
            continue
        }
        if (byte < 48 || byte > 57) {
            return None
        }
        let digit = Int64(byte - 48)
        // 累加前判界：`result*10+digit` 超出 Int64 时会先触发算术异常，而不是
        // 返回具名的 invalid 路径。超界与其它畸形 token 一样按无法解析处理。
        if (result > (9223372036854775807 - digit) / 10) {
            return None
        }
        result = result * 10 + digit
        index += 1
    }
    if (index == 0 || (index == 1 && negative)) {
        return None
    }
    return Some(if (negative) {
        -result
    } else {
        result
    })
}

/// Parses an outer-shadow declaration on the shared protocol line:
/// `offsetX,offsetY,blurRadius,spread,<#RRGGBBAA>` - exactly five
/// comma-separated fields whose first four are signed logical points and whose
/// last is a strict color token. `none` and the empty string mean "clear the
/// shadow" and yield None, exactly like the explicit clear value; any other
/// malformed text also yields None so the caller refuses the whole candidate
/// instead of staging a half-declared one. The shared effect contract is
/// applied here too: an offset outside +/-4096, a blur outside 0..256, a spread
/// outside 0..128 or a non-finite color is refused by name and yields None.
/// The result is re-declarable by `cjguiComposableUiShadowToken` (round-trip).
public func cjguiComposableUiParseShadowToken(token: String): ?CjguiComposableUiShadowStyle {
    if (cjguiComposableUiEffectTokenIsNone(token)) {
        return None
    }
    let fields = token.split(",")
    if (fields.size != 5) {
        return None
    }
    let offsetX = match (cjguiComposableUiParseEffectInt(fields[0])) {
        case Some(value) => value
        case None => return None
    }
    let offsetY = match (cjguiComposableUiParseEffectInt(fields[1])) {
        case Some(value) => value
        case None => return None
    }
    let blurRadius = match (cjguiComposableUiParseEffectInt(fields[2])) {
        case Some(value) => value
        case None => return None
    }
    let spread = match (cjguiComposableUiParseEffectInt(fields[3])) {
        case Some(value) => value
        case None => return None
    }
    let color = match (cjguiComposableUiParseColorToken(fields[4])) {
        case Some(value) => value
        case None => return None
    }
    let shadow = CjguiComposableUiShadowStyle(color: color, offsetX: offsetX, offsetY: offsetY, blurRadius: blurRadius,
        spread: spread)
    // The SAME shared predicate the handwritten constructor uses: a scalar
    // outside its published bound (or a non-finite color) makes the whole token
    // unparseable rather than a silently clamped shadow.
    if (let Some(_) <- shadow.rejectionReason()) {
        return None
    }
    return Some(shadow)
}

/// Encodes a shadow back to the same protocol token, so a named style's
/// published text carries an effect a reader can feed back unchanged. A shadow
/// that violates the shared contract is not describable and encodes as `none`,
/// which keeps the discovery text parseable (round-trip safe).
public func cjguiComposableUiShadowToken(shadow: CjguiComposableUiShadowStyle): String {
    if (let Some(_) <- shadow.rejectionReason()) {
        return "none"
    }
    return "${shadow.offsetX},${shadow.offsetY},${shadow.blurRadius},${shadow.spread}," + cjguiComposableUiColorToken(
        shadow.color)
}

/// Parses a linear-gradient declaration on the shared protocol line:
/// `sx,sy,ex,ey,<pos>:<color>|<pos>:<color>|...` - four 0..100 percent integer
/// coordinates, then two to four pipe-separated stops, each `percent:#RRGGBBAA`.
/// Percent is the wire unit; the normalized [0,1] value the renderer consumes
/// is derived by division, so the declaration never carries a device pixel.
/// `none` and the empty string mean "no gradient". A coordinate outside 0..100,
/// a wrong field/stop count or a malformed stop yields None: a bad gradient is
/// refused whole rather than silently clamped from a partial read.
public func cjguiComposableUiParseGradientToken(token: String): ?CjguiComposableUiLinearGradient {
    if (cjguiComposableUiEffectTokenIsNone(token)) {
        return None
    }
    let fields = token.split(",")
    if (fields.size != 5) {
        return None
    }
    var coordinates = ArrayList<Int64>()
    var coordinateIndex = 0
    while (coordinateIndex < 4) {
        let value = match (cjguiComposableUiParseEffectInt(fields[coordinateIndex])) {
            case Some(number) => number
            case None => return None
        }
        if (value < 0 || value > 100) {
            return None
        }
        coordinates.add(value)
        coordinateIndex += 1
    }
    let stopFields = fields[4].split("|")
    if (stopFields.size < 2 || stopFields.size > 4) {
        return None
    }
    var stops = ArrayList<CjguiComposableUiGradientStop>()
    for (stopField in stopFields) {
        let parts = stopField.split(":")
        if (parts.size != 2) {
            return None
        }
        let position = match (cjguiComposableUiParseEffectInt(parts[0])) {
            case Some(number) => number
            case None => return None
        }
        if (position < 0 || position > 100) {
            return None
        }
        let color = match (cjguiComposableUiParseColorToken(parts[1])) {
            case Some(value) => value
            case None => return None
        }
        stops.add(CjguiComposableUiGradientStop(position: Float64(position) / 100.0, color: color))
    }
    let gradient = CjguiComposableUiLinearGradient(startX: Float64(coordinates[0]) / 100.0,
        startY: Float64(coordinates[1]) / 100.0, endX: Float64(coordinates[2]) / 100.0,
        endY: Float64(coordinates[3]) / 100.0, stops: stops.toArray())
    // The SAME shared predicate the handwritten constructor uses, so a token
    // the generated side accepts is exactly a gradient a handwritten Style
    // accepts (and vice versa).
    if (let Some(_) <- gradient.rejectionReason()) {
        return None
    }
    return Some(gradient)
}

/// Encodes a gradient back to the same protocol token (percent integers), so a
/// named style's published text is re-declarable without a second format. A
/// gradient with fewer than two stops is not describable and encodes as `none`.
public func cjguiComposableUiGradientToken(gradient: CjguiComposableUiLinearGradient): String {
    // A gradient the shared contract refuses (wrong stop count, out-of-range
    // coordinate/position, non-finite color) is not describable and encodes as
    // `none`, so the published text always parses back (round-trip safe).
    if (let Some(_) <- gradient.rejectionReason()) {
        return "none"
    }
    let builder = StringBuilder()
    builder.append(
        "${cjguiComposableUiPercent(gradient.startX)},${cjguiComposableUiPercent(gradient.startY)}," +
            "${cjguiComposableUiPercent(gradient.endX)},${cjguiComposableUiPercent(gradient.endY)},")
    var index = 0
    while (index < gradient.stops.size) {
        if (index > 0) {
            builder.append("|")
        }
        let stop = gradient.stops[index]
        builder.append("${cjguiComposableUiPercent(stop.position)}:${cjguiComposableUiColorToken(stop.color)}")
        index += 1
    }
    return builder.toString()
}

/// Parses the generated P4 effect group token. The legacy three-field prefix
/// remains stable; an optional `;blur=radiusPoints,unblurred` suffix carries
/// the bounded backdrop blur declaration.
public func cjguiComposableUiParseEffectGroupToken(token: String): ?CjguiComposableUiEffectGroup {
    if (cjguiComposableUiEffectTokenIsNone(token)) {
        return None
    }
    let tokenParts = token.split(";blur=", 2)
    if (tokenParts.size > 2) {
        return None
    }
    let fields = tokenParts[0].split(",", 3)
    if (fields.size != 3) {
        return None
    }
    let opacityPercent = match (cjguiComposableUiParseEffectInt(fields[0])) {
        case Some(value) => value
        case None => return None
    }
    if (opacityPercent < 0 || opacityPercent > 100) {
        return None
    }
    if (fields[1] != "normal" && fields[1] != "multiply") {
        return None
    }
    var blurRadiusPoints: Int64 = 0
    var blurFallback = "unblurred"
    if (tokenParts.size == 2) {
        let blurFields = tokenParts[1].split(",", 2)
        if (blurFields.size != 2 || blurFields[1] != "unblurred") {
            return None
        }
        blurRadiusPoints = match (cjguiComposableUiParseEffectInt(blurFields[0])) {
            case Some(value) => value
            case None => return None
        }
        if (blurRadiusPoints < 0 || blurRadiusPoints > 16) {
            return None
        }
        blurFallback = blurFields[1]
    }
    var mask: ?CjguiComposableUiLinearAlphaMask = None
    if (fields[2] != "none") {
        let maskFields = fields[2].split(",", 5)
        if (maskFields.size != 5) {
            return None
        }
        let coordinates = ArrayList<Int64>()
        var coordinateIndex = 0
        while (coordinateIndex < 4) {
            let value = match (cjguiComposableUiParseEffectInt(maskFields[coordinateIndex])) {
                case Some(number) => number
                case None => return None
            }
            if (value < 0 || value > 100) {
                return None
            }
            coordinates.add(value)
            coordinateIndex += 1
        }
        let stopFields = maskFields[4].split("|")
        if (stopFields.size < CjguiComposableUiEffectValidation.MIN_ALPHA_MASK_STOPS ||
            stopFields.size > CjguiComposableUiEffectValidation.MAX_ALPHA_MASK_STOPS) {
            return None
        }
        let stops = ArrayList<CjguiComposableUiAlphaMaskStop>()
        for (stopField in stopFields) {
            let parts = stopField.split(":")
            if (parts.size != 2) {
                return None
            }
            let position = match (cjguiComposableUiParseEffectInt(parts[0])) {
                case Some(value) => value
                case None => return None
            }
            let alpha = match (cjguiComposableUiParseEffectInt(parts[1])) {
                case Some(value) => value
                case None => return None
            }
            if (position < 0 || position > 100 || alpha < 0 || alpha > 100) {
                return None
            }
            stops.add(CjguiComposableUiAlphaMaskStop(position: Float64(position) / 100.0,
                alpha: Float64(alpha) / 100.0))
        }
        let parsedMask = CjguiComposableUiLinearAlphaMask(startX: Float64(coordinates[0]) / 100.0,
            startY: Float64(coordinates[1]) / 100.0, endX: Float64(coordinates[2]) / 100.0,
            endY: Float64(coordinates[3]) / 100.0, stops: stops.toArray())
        if (parsedMask.rejectionReason().isSome()) {
            return None
        }
        mask = Some(parsedMask)
    }
    let group = CjguiComposableUiEffectGroup(opacity: Float64(opacityPercent) / 100.0, blendMode: fields[1],
        mask: mask, backdropBlurRadiusPoints: blurRadiusPoints, backdropBlurFallback: blurFallback)
    if (group.rejectionReason().isSome()) {
        return None
    }
    return Some(group)
}

/// Encodes the same bounded grammar consumed by generated candidates and
/// published in capability discovery. A malformed in-memory value is not
/// described as a legal effect and encodes as the explicit clear token.
public func cjguiComposableUiEffectGroupToken(group: CjguiComposableUiEffectGroup): String {
    if (group.rejectionReason().isSome()) {
        return "none"
    }
    let builder = StringBuilder()
    builder.append("${cjguiComposableUiPercent(group.opacity)},${group.blendMode},")
    if (let Some(mask) <- group.mask) {
        builder.append("${cjguiComposableUiPercent(mask.startX)},${cjguiComposableUiPercent(mask.startY)}," +
            "${cjguiComposableUiPercent(mask.endX)},${cjguiComposableUiPercent(mask.endY)},")
        var index = 0
        while (index < mask.stops.size) {
            if (index > 0) {
                builder.append("|")
            }
            let stop = mask.stops[index]
            builder.append("${cjguiComposableUiPercent(stop.position)}:${cjguiComposableUiPercent(stop.alpha)}")
            index += 1
        }
    } else {
        builder.append("none")
    }
    if (group.backdropBlurRadiusPoints > 0) {
        builder.append(";blur=${group.backdropBlurRadiusPoints},${group.backdropBlurFallback}")
    }
    return builder.toString()
}

/// Rounds a normalized [0,1] coordinate to the 0..100 percent wire unit.
private func cjguiComposableUiPercent(value: Float64): Int64 {
    var percent = value * 100.0 + 0.5
    if (percent < 0.0) {
        percent = 0.0
    }
    if (percent > 100.0) {
        percent = 100.0
    }
    return Int64(percent)
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
            let ok = (byte >= 65 && byte <= 90) || (byte >= 97 && byte <= 122) || (byte >= 48 && byte <= 57) || byte ==
                95 || byte == 45
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

    /// Registers one definition. A definition whose base carries a refused
    /// effect (`effectRejection`) is rejected BY NAME with the SAME vocabulary
    /// the handwritten constructor and the generated token path use, before the
    /// directory is touched: an illegal `blur=257` can never enter the catalog
    /// and be laundered into a legal style through a named reference.
    public func register(style: CjguiComposableUiNamedStyle): Bool {
        if (!CjguiComposableUiNamedStyleCatalog.isValidName(style.name)) {
            issue = "named_style_name_invalid"
            return false
        }
        if (let Some(rejection) <- style.base.effectRejection) {
            issue = rejection.reason
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
    /// a real definition change, so discovery and observation move with it. The
    /// same effect admission as `register` applies: a refused definition is
    /// reported by name and the PREVIOUS definition stays registered (the update
    /// is atomic - nothing is written on a refusal).
    public func update(style: CjguiComposableUiNamedStyle): Bool {
        if (let Some(rejection) <- style.base.effectRejection) {
            issue = rejection.reason
            return false
        }
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

    /// Deterministic fingerprint of every definition (inputs, interaction paints,
    /// purpose AND the shared effect semantics). Registration, update and removal
    /// all move it.
    ///
    /// The effect contribution uses the SAME normalized encoding the discovery
    /// text publishes (`cjguiComposableUiShadowToken` /
    /// `cjguiComposableUiGradientToken`), so two declarations that normalize to
    /// the same shadow/gradient produce the same revision: a reordered stop list
    /// and a colour spelled with an equivalent float both hash alike, because the
    /// style layer already ordered admitted stops and the token rounds to bytes.
    /// A refused declaration is also fingerprinted, so an illegal definition can
    /// never look like a clean "no effect" one; a transparent/invisible shadow is
    /// normalized to None by the style layer and therefore hashes exactly like an
    /// absent one, which is the published clear/invisible rule.
    public func revision(): Int64 {
        var hash: Int64 = 23
        for (name in order) {
            let styleOption = styles.get(name)
            if (let Some(style) <- styleOption) {
                for (byte in name.toArray()) {
                    hash = (hash * 131 + Int64(byte)) % 2147483647
                }
                let base = style.base
                for (text in [cjguiComposableUiColorToken(base.background), cjguiComposableUiColorToken(base.border),
                    cjguiComposableUiColorToken(base.textColor)]) {
                    for (byte in text.toArray()) {
                        hash = (hash * 131 + Int64(byte)) % 2147483647
                    }
                }
                for (value in [base.borderWidth, base.padding, base.gap, base.fixedWidth, base.fixedHeight, base.growX,
                    base.growY, base.fontWeight, base.minWidth, base.maxWidth, base.minHeight, base.maxHeight,
                    base.alignX, base.alignY, base.cornerRadius]) {
                    hash = (hash * 131 + value) % 2147483647
                }
                hash = (hash * 131 + Int64(base.fontSize * 100.0)) % 2147483647
                hash = (hash * 131 + if (base.clipsContent) {
                    1
                } else {
                    0
                }) % 2147483647
                for (byte in style.purpose.toArray()) {
                    hash = (hash * 131 + Int64(byte)) % 2147483647
                }
                // The shared effect semantics are their OWN input: a shadow blur
                // or a single gradient stop is a real definition change and must
                // move the revision, so a client is told to re-read the STYLES
                // section instead of never learning about it.
                for (byte in CjguiComposableUiNamedStyleCatalog.effectRevisionToken(base).toArray()) {
                    hash = (hash * 131 + Int64(byte)) % 2147483647
                }
                for (paint in [style.interaction.normal, style.interaction.hover, style.interaction.pressed,
                    style.interaction.focused, style.interaction.disabled, style.interaction.selected,
                    style.interaction.checked]) {
                    for (label in ["background", "border", "textColor"]) {
                        for (byte in label.toArray()) {
                            hash = (hash * 131 + Int64(byte)) % 2147483647
                        }
                        let color = if (label == "background") {
                            paint.background
                        } else if (label == "border") {
                            paint.border
                        } else {
                            paint.textColor
                        }
                        match (color) {
                            case Some(value) => for (byte in cjguiComposableUiColorToken(value).toArray()) {
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

    /// The normalized effect encoding of one base style for the revision hash.
    /// It is built from the SAME tokens the discovery text publishes, so a
    /// semantic "same effect" is a byte-identical encoding (and a different
    /// effect is a different one). A refused declaration keeps its named reason
    /// and path, so it never collapses onto the clean "no effect" encoding.
    private static func effectRevisionToken(base: CjguiComposableUiStyle): String {
        let shadow = match (base.shadow) {
            case Some(value) => cjguiComposableUiShadowToken(value)
            case None => "-"
        }
        let gradient = match (base.gradient) {
            case Some(value) => cjguiComposableUiGradientToken(value)
            case None => "-"
        }
        let effectGroup = match (base.effectGroup) {
            case Some(value) => cjguiComposableUiEffectGroupToken(value)
            case None => "-"
        }
        let rejection = match (base.effectRejection) {
            case Some(value) => "${value.reason}@${value.path}"
            case None => "-"
        }
        return "shadow=${shadow} gradient=${gradient} effectGroup=${effectGroup} rejection=${rejection}"
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
            // Published effect summary: a reader learns whether the style
            // carries an outer shadow / linear gradient without a second table.
            let shadowToken = match (base.shadow) {
                case Some(value) => cjguiComposableUiShadowToken(value)
                case None => "-"
            }
            let gradientToken = match (base.gradient) {
                case Some(value) => cjguiComposableUiGradientToken(value)
                case None => "-"
            }
            let effectGroupToken = match (base.effectGroup) {
                case Some(value) => cjguiComposableUiEffectGroupToken(value)
                case None => "-"
            }
            builder.append(
                "STYLE ${name} " + "background=${cjguiComposableUiColorToken(base.background)} " +
                    "border=${cjguiComposableUiColorToken(base.border)} " +
                    "textColor=${cjguiComposableUiColorToken(base.textColor)} " +
                    "borderWidth=${base.borderWidth} padding=${base.padding} gap=${base.gap} " +
                    "fixedWidth=${base.fixedWidth} fixedHeight=${base.fixedHeight} " +
                    "growX=${base.growX} growY=${base.growY} fontSize=${Int64(base.fontSize)} " +
                    "fontWeight=${base.fontWeight} minWidth=${base.minWidth} maxWidth=${base.maxWidth} " +
                    "minHeight=${base.minHeight} maxHeight=${base.maxHeight} " +
                    "alignX=${namedStyleAlignmentToken(base.alignX)} " +
                    "alignY=${namedStyleAlignmentToken(base.alignY)} " +
                    "shadow=${shadowToken} gradient=${gradientToken} effectGroup=${effectGroupToken} " +
                    "purpose_hex=${if (style.purpose.size > 0) { namedStyleHexEncode(style.purpose) } else { "-" }}\n")
            builder.append(
                "STYLE_STATE ${name} normal[${CjguiComposableUiNamedStyleCatalog.paintTokens(style.interaction.normal)}] " +
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

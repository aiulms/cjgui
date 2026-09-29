package cjgui

import cjgui_shared_operation_core.*
import std.collection.*
import std.math.*
import std.time.*
import std.convert.*
import std.overflow.*
import std.sync.*

// Experimental composable UI value model.  It is deliberately platform free:
// consumers describe components, visual style, resource/action relationships,
// and tree structure in Cangjie; this file resolves the one canonical layout
// that rendering, hit testing, focus and accessibility later consume.

public let CJGUI_COMPOSABLE_UI_VERTICAL: Int64 = 1
public let CJGUI_COMPOSABLE_UI_HORIZONTAL: Int64 = 2
public let CJGUI_COMPOSABLE_UI_TEXT: Int64 = 3
public let CJGUI_COMPOSABLE_UI_BUTTON: Int64 = 4
public let CJGUI_COMPOSABLE_UI_TEXT_INPUT: Int64 = 5
public let CJGUI_COMPOSABLE_UI_INTEGER_INPUT: Int64 = 6
public let CJGUI_COMPOSABLE_UI_BOOLEAN_INPUT: Int64 = 7
public let CJGUI_COMPOSABLE_UI_SCROLL_AREA: Int64 = 8
public let CJGUI_COMPOSABLE_UI_IMAGE: Int64 = 9
/// A bounded plain-text editor. The document remains Cangjie-owned; native
/// code receives only its currently rendered value and returns input intent.
public let CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT: Int64 = 10
/// A layer host is a Cangjie-only composition boundary. Native sees the
/// resolved children in ordinary z order and never receives a menu/dialog
/// product type or application command branch.
public let CJGUI_COMPOSABLE_UI_LAYER_HOST: Int64 = 11
/// A transparent-to-business input shield used below a modal layer. It has a
/// generic visual `LAYER_OUTSIDE` intent and cannot be focusable.
public let CJGUI_COMPOSABLE_UI_LAYER_BACKDROP: Int64 = 12
/// A split handle is the only input node used by the public split-view
/// composition helper. The split container itself remains an ordinary
/// horizontal/vertical layout node; capture targets the handle identity.
public let CJGUI_COMPOSABLE_UI_SPLIT_HANDLE: Int64 = 13
/// A scalar slider is a value projection. Its owner remains the consumer's
/// domain; the framework only normalizes pointer/keyboard geometry.
public let CJGUI_COMPOSABLE_UI_SLIDER: Int64 = 14
/// A bounded public vector component. Its immutable Geometry value remains
/// Cangjie-owned; native receives only the existing copied scene projection.
public let CJGUI_COMPOSABLE_UI_VECTOR_GRAPHIC: Int64 = 15
/// A bounded public tab container: one title row plus 2-3 pages, exactly ONE of
/// which is the active page laid out, hit-tested, measured and drawn. A hidden
/// page keeps its stable identity and its own view state without taking part in
/// the active scene, so hiding is never deletion and never a business write.
public let CJGUI_COMPOSABLE_UI_TABS: Int64 = 16
/// One tab TITLE inside a tab container's title row. Its stable identity comes
/// from the container's scope, and activating it is the ordinary view intent
/// shared by pointer and keyboard.
public let CJGUI_COMPOSABLE_UI_TAB_TITLE: Int64 = 17
/// Horizontal inset shared by the component layout content width and the
/// native AppKit text drawing rectangle. The native bridge applies 7pt on
/// each side, so text measurement must reserve 14pt before wrapping.
public let CJGUI_COMPOSABLE_UI_TEXT_HORIZONTAL_INSET: Int64 = 7

public class CjguiComposableUiSplitAxis {
    public static let HORIZONTAL: Int64 = 1
    public static let VERTICAL: Int64 = 2
}

/// Stateless split geometry. Keeping this math separate from a controller
/// makes bounds behavior testable and prevents the UI framework from owning a
/// pane-size value that belongs to an application or shared-operation owner.
public class CjguiComposableUiSplitGeometry {
    public static func firstSizeForPointer(pointer: Int64, trackOrigin: Int64, trackLength: Int64,
        handleThickness: Int64, minFirst: Int64, minSecond: Int64): Int64 {
        let safeTrack = if (trackLength > 0) {
            trackLength
        } else {
            0
        }
        let safeHandle = if (handleThickness > 0) {
            handleThickness
        } else {
            1
        }
        let available = if (safeTrack > safeHandle) {
            safeTrack - safeHandle
        } else {
            0
        }
        let lower = if (minFirst > 0) {
            minFirst
        } else {
            0
        }
        let requestedUpper = if (available <= 0) {
            0
        } else if (minSecond > 0) {
            // The second pane keeps ITS declared minimum, so the first pane stops
            // that much before the end of the track.
            if (available > minSecond) {
                available - minSecond
            } else {
                0
            }
        } else {
            // No second minimum declared: the whole available track is legal. A
            // missing bound must not collapse the first pane to zero.
            available
        }
        let upper = if (requestedUpper >= lower) {
            requestedUpper
        } else {
            lower
        }
        let requested = pointer - trackOrigin
        if (requested < lower) {
            return lower
        }
        if (requested > upper) {
            return upper
        }
        return requested
    }

    public static func firstSizeForTrack(requested: Int64, trackLength: Int64, handleThickness: Int64, minFirst: Int64,
        minSecond: Int64): Int64 {
        return firstSizeForPointer(requested, 0, trackLength, handleThickness, minFirst, minSecond)
    }
}

/// Stateless slider geometry shared by pointer and keyboard consumers.
public class CjguiComposableUiSliderGeometry {
    public static func clampValue(value: Int64, minimum: Int64, maximum: Int64): Int64 {
        let upper = if (maximum >= minimum) {
            maximum
        } else {
            minimum
        }
        if (value < minimum) {
            return minimum
        }
        if (value > upper) {
            return upper
        }
        return value
    }

    public static func adjustValue(value: Int64, direction: Int64, minimum: Int64, maximum: Int64, step: Int64): Int64 {
        let safeStep = if (step > 0) {
            step
        } else {
            1
        }
        return clampValue(value.saturatingAdd(direction.saturatingMul(safeStep)), minimum, maximum)
    }

    public static func valueForPointer(pointer: Int64, trackOrigin: Int64, trackLength: Int64, minimum: Int64,
        maximum: Int64, step: Int64): Int64 {
        let upper = if (maximum >= minimum) {
            maximum
        } else {
            minimum
        }
        let span = if (trackLength > 0) {
            trackLength
        } else {
            1
        }
        let offset = if (pointer <= trackOrigin) {
            0
        } else if (pointer >= trackOrigin + span) {
            span
        } else {
            pointer - trackOrigin
        }
        let raw = minimum.saturatingAdd((upper - minimum).saturatingMul(offset).saturatingAdd(span / 2) / span)
        let safeStep = if (step > 0) {
            step
        } else {
            1
        }
        let stepped = minimum + ((raw - minimum) / safeStep) * safeStep
        return clampValue(stepped, minimum, upper)
    }
}

/// Cross-axis alignment for row/column children.  Start is the historical
/// default, stretch uses the available cross-axis size, and center/end leave
/// deliberate breathing room without changing node identity.
public let CJGUI_COMPOSABLE_UI_ALIGN_START: Int64 = 1
public let CJGUI_COMPOSABLE_UI_ALIGN_CENTER: Int64 = 2
public let CJGUI_COMPOSABLE_UI_ALIGN_END: Int64 = 3
public let CJGUI_COMPOSABLE_UI_ALIGN_STRETCH: Int64 = 4
// The native composable-scene ABI has a fixed 1,024-node ceiling. A virtual
// list therefore keeps a substantially smaller hard cap for its own rows,
// leaving room for the surrounding application tree and for a row to contain
// more than one node. This is a projection bound only; it never truncates the
// logical source count or changes its selection/scroll truth.
public let CJGUI_COMPOSABLE_UI_MAX_VIRTUAL_MATERIALIZED_ROWS: Int64 = 128

public class CjguiComposableUiColor {
    public let red: Float64
    public let green: Float64
    public let blue: Float64
    public let alpha: Float64
    public init(red: Float64, green: Float64, blue: Float64, alpha: Float64) {
        this.red = red
        this.green = green
        this.blue = blue
        this.alpha = alpha
    }
}

public class CjguiComposableUiRect {
    public let x: Int64
    public let y: Int64
    public let width: Int64
    public let height: Int64
    public init(x: Int64, y: Int64, width: Int64, height: Int64) {
        this.x = x
        this.y = y
        this.width = if (width < 0) {
            0
        } else {
            width
        }
        this.height = if (height < 0) {
            0
        } else {
            height
        }
    }
    public func contains(x: Int64, y: Int64): Bool {
        return x >= this.x && y >= this.y && x < this.x + width && y < this.y + height
    }
    public func intersect(other: CjguiComposableUiRect): CjguiComposableUiRect {
        let left = if (x > other.x) {
            x
        } else {
            other.x
        }
        let top = if (y > other.y) {
            y
        } else {
            other.y
        }
        let rightValue = if (x + width < other.x + other.width) {
            x + width
        } else {
            other.x + other.width
        }
        let bottomValue = if (y + height < other.y + other.height) {
            y + height
        } else {
            other.y + other.height
        }
        return CjguiComposableUiRect(left, top, rightValue - left, bottomValue - top)
    }
}

/// One original clipping shape in the resolved scene.  Keeping this separate
/// from the intersection bounding box avoids changing a rounded ancestor into
/// a smaller, incorrectly rounded rectangle when descendants are offset.
/// The native bridge carries the same bounded sequence; it never recreates an
/// AppKit containment tree.
///
/// `ownerIdentity` names the node that CREATED this clip, so a consumer can
/// resolve the real ancestor chain by identity instead of guessing it from equal
/// rectangles. Two siblings can overlap exactly, and equal geometry is not
/// evidence of containment.
public class CjguiComposableUiClipConstraint {
    public let rect: CjguiComposableUiRect
    public let cornerRadius: Int64
    /// Stable identity of the clipping node (`CjguiComposableUiLayoutNode.identityKey`),
    /// empty only for a constraint built by hand outside the layout engine.
    public let ownerIdentity: String
    public init(rect: CjguiComposableUiRect, cornerRadius!: Int64 = 0, ownerIdentity!: String = "") {
        this.rect = rect
        this.ownerIdentity = ownerIdentity
        let limit = if (rect.width < rect.height) {
            rect.width / 2
        } else {
            rect.height / 2
        }
        let nonnegative = if (cornerRadius < 0) {
            0
        } else {
            cornerRadius
        }
        this.cornerRadius = if (nonnegative > limit) {
            limit
        } else {
            nonnegative
        }
    }
    public func contains(x: Int64, y: Int64): Bool {
        if (!rect.contains(x, y) || cornerRadius <= 0) {
            return rect.contains(x, y)
        }
        let left = rect.x;
        let top = rect.y
        let right = rect.x + rect.width;
        let bottom = rect.y + rect.height
        let centreX = if (x < left + cornerRadius) {
            left + cornerRadius
        } else if (x >= right - cornerRadius) {
            right - cornerRadius - 1
        } else {
            x
        }
        let centreY = if (y < top + cornerRadius) {
            top + cornerRadius
        } else if (y >= bottom - cornerRadius) {
            bottom - cornerRadius - 1
        } else {
            y
        }
        let dx = x - centreX;
        let dy = y - centreY
        return dx * dx + dy * dy <= cornerRadius * cornerRadius
    }
}

private let CJGUI_COMPOSABLE_UI_MAX_CLIP_CONSTRAINTS: Int64 = 4

public class CjguiComposableUiStyle {
    public let background: CjguiComposableUiColor
    public let border: CjguiComposableUiColor
    public let textColor: CjguiComposableUiColor
    public let padding: Int64
    public let gap: Int64
    public let fixedWidth: Int64
    public let fixedHeight: Int64
    public let growX: Int64
    public let growY: Int64
    public let borderWidth: Int64
    /// Rounded corners are declarative geometry in logical points.  The
    /// renderer clamps this to the resolved box; it is never an AppKit view
    /// property or a platform-specific control skin.
    public let cornerRadius: Int64
    /// When set, children inherit this component's padded content clip.  The
    /// scene carries both the rectangular bounds and its corner radius so
    /// Metal, hit testing and accessibility resolve one projection.
    public let clipsContent: Bool
    /// Opt a non-input node into pointer delivery. A read-only presentation
    /// surface (the editor's visual mode) needs click coordinates but must not be
    /// an editable text target; without this a plain TEXT node receives no
    /// pointer event at all.
    public let pointerInteractive: Bool
    /// Points, not device pixels. The same declared font is supplied to the
    /// production AppKit measurer and draw layer.
    public let fontSize: Float64
    public let fontWeight: Int64
    /// Deliberately small cross-platform font descriptor. Unknown requested
    /// names are normalized to the system family before the native boundary.
    public let fontFamily: String
    public let minWidth: Int64
    public let maxWidth: Int64
    public let idealWidth: Int64
    public let minHeight: Int64
    public let maxHeight: Int64
    public let idealHeight: Int64
    public let alignX: Int64
    public let alignY: Int64
    public init(
        background!: CjguiComposableUiColor = CjguiComposableUiColor(0.0, 0.0, 0.0, 0.0),
        border!: CjguiComposableUiColor = CjguiComposableUiColor(0.0, 0.0, 0.0, 0.0),
        textColor!: CjguiComposableUiColor = CjguiComposableUiColor(0.12, 0.13, 0.16, 1.0),
        padding!: Int64 = 0,
        gap!: Int64 = 0,
        fixedWidth!: Int64 = 0,
        fixedHeight!: Int64 = 0,
        growX!: Int64 = 0,
        growY!: Int64 = 0,
        borderWidth!: Int64 = 1,
        fontSize!: Float64 = 13.0,
        fontWeight!: Int64 = 0,
        fontFamily!: String = "system",
        minWidth!: Int64 = 0,
        maxWidth!: Int64 = 0,
        idealWidth!: Int64 = 0,
        minHeight!: Int64 = 0,
        maxHeight!: Int64 = 0,
        idealHeight!: Int64 = 0,
        alignX!: Int64 = CJGUI_COMPOSABLE_UI_ALIGN_STRETCH,
        alignY!: Int64 = CJGUI_COMPOSABLE_UI_ALIGN_START,
        cornerRadius!: Int64 = 0,
        clipsContent!: Bool = false,
        pointerInteractive!: Bool = false
    ) {
        this.background = background
        this.border = border
        this.textColor = textColor
        this.padding = if (padding < 0) {
            0
        } else {
            padding
        }
        this.gap = if (gap < 0) {
            0
        } else {
            gap
        }
        this.fixedWidth = if (fixedWidth < 0) {
            0
        } else {
            fixedWidth
        }
        this.fixedHeight = if (fixedHeight < 0) {
            0
        } else {
            fixedHeight
        }
        this.growX = if (growX < 0) {
            0
        } else {
            growX
        }
        this.growY = if (growY < 0) {
            0
        } else {
            growY
        }
        this.borderWidth = if (borderWidth < 0) {
            0
        } else {
            borderWidth
        }
        this.cornerRadius = if (cornerRadius < 0) {
            0
        } else if (cornerRadius > 4096) {
            4096
        } else {
            cornerRadius
        }
        this.clipsContent = clipsContent
        this.pointerInteractive = pointerInteractive
        this.fontSize = if (fontSize < 6.0) {
            6.0
        } else if (fontSize > 144.0) {
            144.0
        } else {
            fontSize
        }
        // Font weight carries BOTH the legacy boolean form and the numeric
        // scale: 0 is regular and 1 still means bold, but values from 100 up are
        // preserved as weights (400 regular, 500 medium, 600 semibold, 700+ bold).
        // Collapsing anything above 1 to 1 silently turned body text bold.
        this.fontWeight = if (fontWeight < 0) {
            0
        } else if (fontWeight > 1 && fontWeight < 100) {
            1
        } else {
            fontWeight
        }
        // Font family also carries the italic request: the renderer already
        // receives one family code per run, so italic rides that field instead of
        // widening the native node struct.
        this.fontFamily = if (fontFamily == "monospaced") {
            "monospaced"
        } else if (fontFamily == "system-italic") {
            "system-italic"
        } else if (fontFamily == "monospaced-italic") {
            "monospaced-italic"
        } else {
            "system"
        }
        this.minWidth = if (minWidth < 0) {
            0
        } else {
            minWidth
        }
        this.maxWidth = if (maxWidth > 0 && maxWidth < this.minWidth) {
            this.minWidth
        } else {
            if (maxWidth < 0) {
                0
            } else {
                maxWidth
            }
        }
        this.idealWidth = if (idealWidth < 0) {
            0
        } else {
            idealWidth
        }
        this.minHeight = if (minHeight < 0) {
            0
        } else {
            minHeight
        }
        this.maxHeight = if (maxHeight > 0 && maxHeight < this.minHeight) {
            this.minHeight
        } else {
            if (maxHeight < 0) {
                0
            } else {
                maxHeight
            }
        }
        this.idealHeight = if (idealHeight < 0) {
            0
        } else {
            idealHeight
        }
        this.alignX = if (alignX == CJGUI_COMPOSABLE_UI_ALIGN_START || alignX == CJGUI_COMPOSABLE_UI_ALIGN_CENTER ||
            alignX == CJGUI_COMPOSABLE_UI_ALIGN_END || alignX == CJGUI_COMPOSABLE_UI_ALIGN_STRETCH) {
            alignX
        } else {
            CJGUI_COMPOSABLE_UI_ALIGN_START
        }
        this.alignY = if (alignY == CJGUI_COMPOSABLE_UI_ALIGN_START || alignY == CJGUI_COMPOSABLE_UI_ALIGN_CENTER ||
            alignY == CJGUI_COMPOSABLE_UI_ALIGN_END || alignY == CJGUI_COMPOSABLE_UI_ALIGN_STRETCH) {
            alignY
        } else {
            CJGUI_COMPOSABLE_UI_ALIGN_START
        }
    }
}

/// A paint-only override for one interaction state.  The optional fields are
/// intentionally limited to the properties that can change without a layout
/// pass; geometry, typography and content metrics remain owned by the base
/// `CjguiComposableUiStyle`.
/// Paint-only overlay used by applications and composites: the BASE's geometry,
/// typography and layout are kept exactly as authored, while the OVERLAY's
/// background/border/textColor/borderWidth replace the paint. A named style can
/// therefore be a pure paint role whose switching never moves layout, re-measures
/// text or rebuilds identity.
public func cjguiComposableUiPaintOverlay(base: CjguiComposableUiStyle,
                                          paint: CjguiComposableUiStyle): CjguiComposableUiStyle {
    return CjguiComposableUiStyle(
        background: paint.background, border: paint.border, textColor: paint.textColor,
        padding: base.padding, gap: base.gap, fixedWidth: base.fixedWidth, fixedHeight: base.fixedHeight,
        growX: base.growX, growY: base.growY, borderWidth: paint.borderWidth,
        fontSize: base.fontSize, fontWeight: base.fontWeight, fontFamily: base.fontFamily,
        minWidth: base.minWidth, maxWidth: base.maxWidth, idealWidth: base.idealWidth,
        minHeight: base.minHeight, maxHeight: base.maxHeight, idealHeight: base.idealHeight,
        alignX: base.alignX, alignY: base.alignY, cornerRadius: base.cornerRadius,
        clipsContent: base.clipsContent)
}

public class CjguiComposableUiPaintStyle {
    public let background: Option<CjguiComposableUiColor>
    public let border: Option<CjguiComposableUiColor>
    public let textColor: Option<CjguiComposableUiColor>
    public let borderWidth: Option<Int64>
    public init(
        background!: Option<CjguiComposableUiColor> = None,
        border!: Option<CjguiComposableUiColor> = None,
        textColor!: Option<CjguiComposableUiColor> = None,
        borderWidth!: Option<Int64> = None
    ) {
        this.background = background
        this.border = border
        this.textColor = textColor
        this.borderWidth = borderWidth
    }
}

/// Framework-owned interaction bits are projected from identity, hit
/// testing, focus and pointer capture.  Only SELECTED and CHECKED may be
/// supplied by an application owner; the other bits are filtered here so an
/// owner cannot create a second interaction state machine.
public class CjguiComposableUiInteractionState {
    public static let NONE: Int64 = 0
    public static let HOVER: Int64 = 1
    public static let PRESSED: Int64 = 2
    public static let FOCUSED: Int64 = 4
    public static let DISABLED: Int64 = 8
    public static let SELECTED: Int64 = 16
    public static let CHECKED: Int64 = 32
    private static let OWNER_MASK: Int64 = SELECTED | CHECKED

    public static func ownerBits(value: Int64): Int64 {
        return value & OWNER_MASK
    }
}

/// Paint state composition for a component.  Resolution is deterministic:
/// base -> normal -> selected -> checked -> focused -> hover -> pressed ->
/// disabled.  Each state only replaces fields it declares, so a component
/// can opt into one paint detail without disturbing another state or any
/// layout/typography field.
public class CjguiComposableUiInteractionStyle {
    public let normal: CjguiComposableUiPaintStyle
    public let hover: CjguiComposableUiPaintStyle
    public let pressed: CjguiComposableUiPaintStyle
    public let focused: CjguiComposableUiPaintStyle
    public let disabled: CjguiComposableUiPaintStyle
    public let selected: CjguiComposableUiPaintStyle
    public let checked: CjguiComposableUiPaintStyle

    public init(
        normal!: CjguiComposableUiPaintStyle = CjguiComposableUiPaintStyle(),
        hover!: CjguiComposableUiPaintStyle = CjguiComposableUiPaintStyle(),
        pressed!: CjguiComposableUiPaintStyle = CjguiComposableUiPaintStyle(),
        focused!: CjguiComposableUiPaintStyle = CjguiComposableUiPaintStyle(),
        disabled!: CjguiComposableUiPaintStyle = CjguiComposableUiPaintStyle(),
        selected!: CjguiComposableUiPaintStyle = CjguiComposableUiPaintStyle(),
        checked!: CjguiComposableUiPaintStyle = CjguiComposableUiPaintStyle()
    ) {
        this.normal = normal
        this.hover = hover
        this.pressed = pressed
        this.focused = focused
        this.disabled = disabled
        this.selected = selected
        this.checked = checked
    }

    private static func applyPaint(base: CjguiComposableUiStyle,
        paint: CjguiComposableUiPaintStyle): CjguiComposableUiStyle {
        let background = if (let Some(value) <- paint.background) { value } else { base.background }
        let border = if (let Some(value) <- paint.border) { value } else { base.border }
        let textColor = if (let Some(value) <- paint.textColor) { value } else { base.textColor }
        let borderWidth = if (let Some(value) <- paint.borderWidth) { value } else { base.borderWidth }
        return CjguiComposableUiStyle(
            background: background,
            border: border,
            textColor: textColor,
            padding: base.padding,
            gap: base.gap,
            fixedWidth: base.fixedWidth,
            fixedHeight: base.fixedHeight,
            growX: base.growX,
            growY: base.growY,
            borderWidth: borderWidth,
            fontSize: base.fontSize,
            fontWeight: base.fontWeight,
            fontFamily: base.fontFamily,
            minWidth: base.minWidth,
            maxWidth: base.maxWidth,
            idealWidth: base.idealWidth,
            minHeight: base.minHeight,
            maxHeight: base.maxHeight,
            idealHeight: base.idealHeight,
            alignX: base.alignX,
            alignY: base.alignY,
            cornerRadius: base.cornerRadius,
            clipsContent: base.clipsContent
        )
    }

    public func resolve(base: CjguiComposableUiStyle, state: Int64): CjguiComposableUiStyle {
        var result = CjguiComposableUiInteractionStyle.applyPaint(base, normal)
        if ((state & CjguiComposableUiInteractionState.SELECTED) != 0) {
            result = CjguiComposableUiInteractionStyle.applyPaint(result, selected)
        }
        if ((state & CjguiComposableUiInteractionState.CHECKED) != 0) {
            result = CjguiComposableUiInteractionStyle.applyPaint(result, checked)
        }
        if ((state & CjguiComposableUiInteractionState.FOCUSED) != 0) {
            result = CjguiComposableUiInteractionStyle.applyPaint(result, focused)
        }
        if ((state & CjguiComposableUiInteractionState.HOVER) != 0) {
            result = CjguiComposableUiInteractionStyle.applyPaint(result, hover)
        }
        if ((state & CjguiComposableUiInteractionState.PRESSED) != 0) {
            result = CjguiComposableUiInteractionStyle.applyPaint(result, pressed)
        }
        if ((state & CjguiComposableUiInteractionState.DISABLED) != 0) {
            result = CjguiComposableUiInteractionStyle.applyPaint(result, disabled)
        }
        return result
    }
}

/// The application can reuse one of these immutable style collections across
/// windows. Theme selection changes data in the Cangjie tree; native receives
/// only the final, copied component style.
public class CjguiComposableUiTheme {
    public let page: CjguiComposableUiStyle
    public let card: CjguiComposableUiStyle
    public let heading: CjguiComposableUiStyle
    public let body: CjguiComposableUiStyle
    public let input: CjguiComposableUiStyle
    public let primaryAction: CjguiComposableUiStyle
    public let pageInteraction: CjguiComposableUiInteractionStyle
    public let cardInteraction: CjguiComposableUiInteractionStyle
    public let headingInteraction: CjguiComposableUiInteractionStyle
    public let bodyInteraction: CjguiComposableUiInteractionStyle
    public let inputInteraction: CjguiComposableUiInteractionStyle
    public let primaryActionInteraction: CjguiComposableUiInteractionStyle
    public init(page: CjguiComposableUiStyle, card: CjguiComposableUiStyle, heading: CjguiComposableUiStyle,
        body: CjguiComposableUiStyle, input: CjguiComposableUiStyle, primaryAction: CjguiComposableUiStyle,
        pageInteraction!: CjguiComposableUiInteractionStyle = CjguiComposableUiInteractionStyle(),
        cardInteraction!: CjguiComposableUiInteractionStyle = CjguiComposableUiInteractionStyle(),
        headingInteraction!: CjguiComposableUiInteractionStyle = CjguiComposableUiInteractionStyle(),
        bodyInteraction!: CjguiComposableUiInteractionStyle = CjguiComposableUiInteractionStyle(),
        inputInteraction!: CjguiComposableUiInteractionStyle = CjguiComposableUiInteractionStyle(),
        primaryActionInteraction!: CjguiComposableUiInteractionStyle = CjguiComposableUiInteractionStyle()) {
        this.page = page
        this.card = card
        this.heading = heading
        this.body = body
        this.input = input
        this.primaryAction = primaryAction
        this.pageInteraction = pageInteraction
        this.cardInteraction = cardInteraction
        this.headingInteraction = headingInteraction
        this.bodyInteraction = bodyInteraction
        this.inputInteraction = inputInteraction
        this.primaryActionInteraction = primaryActionInteraction
    }
    public static func beaconDark(): CjguiComposableUiTheme {
        return CjguiComposableUiTheme(
            CjguiComposableUiStyle(background: CjguiComposableUiColor(0.06, 0.10, 0.18, 1.0), padding: 20, gap: 14),
            CjguiComposableUiStyle(background: CjguiComposableUiColor(0.12, 0.18, 0.30, 1.0),
                border: CjguiComposableUiColor(0.25, 0.38, 0.60, 1.0), padding: 14, gap: 10),
            CjguiComposableUiStyle(textColor: CjguiComposableUiColor(0.92, 0.95, 1.0, 1.0), fontSize: 20.0,
                fontWeight: 1),
            CjguiComposableUiStyle(textColor: CjguiComposableUiColor(0.66, 0.74, 0.88, 1.0), fontSize: 13.0),
            CjguiComposableUiStyle(fixedHeight: 42, background: CjguiComposableUiColor(0.96, 0.98, 1.0, 1.0),
                border: CjguiComposableUiColor(0.42, 0.56, 0.80, 1.0)),
            // The base action style declares its own readable foreground. The
            // interaction states below keep it (they override background and
            // border only), so a consumer that passes the base style - or a
            // named style built from it - never falls back to the near-black
            // default text on this dark blue surface.
            CjguiComposableUiStyle(fixedHeight: 34, background: CjguiComposableUiColor(0.20, 0.45, 0.82, 1.0),
                border: CjguiComposableUiColor(0.36, 0.58, 0.96, 1.0),
                textColor: CjguiComposableUiColor(0.96, 0.98, 1.0, 1.0), fontWeight: 1),
            inputInteraction: CjguiComposableUiInteractionStyle(
                normal: CjguiComposableUiPaintStyle(
                    border: Some(CjguiComposableUiColor(0.42, 0.56, 0.80, 1.0)),
                    textColor: Some(CjguiComposableUiColor(0.12, 0.16, 0.24, 1.0))),
                hover: CjguiComposableUiPaintStyle(
                    background: Some(CjguiComposableUiColor(0.90, 0.94, 1.0, 1.0)),
                    border: Some(CjguiComposableUiColor(0.36, 0.62, 0.96, 1.0))),
                pressed: CjguiComposableUiPaintStyle(
                    background: Some(CjguiComposableUiColor(0.84, 0.90, 1.0, 1.0))),
                focused: CjguiComposableUiPaintStyle(
                    border: Some(CjguiComposableUiColor(0.24, 0.72, 1.0, 1.0)), borderWidth: Some(2)),
                disabled: CjguiComposableUiPaintStyle(
                    background: Some(CjguiComposableUiColor(0.34, 0.39, 0.48, 1.0)),
                    border: Some(CjguiComposableUiColor(0.28, 0.32, 0.40, 1.0)),
                    textColor: Some(CjguiComposableUiColor(0.60, 0.64, 0.72, 1.0))),
                selected: CjguiComposableUiPaintStyle(
                    background: Some(CjguiComposableUiColor(0.22, 0.36, 0.58, 1.0))),
                checked: CjguiComposableUiPaintStyle(
                    border: Some(CjguiComposableUiColor(0.32, 0.88, 0.68, 1.0)))),
            primaryActionInteraction: CjguiComposableUiInteractionStyle(
                normal: CjguiComposableUiPaintStyle(
                    background: Some(CjguiComposableUiColor(0.20, 0.45, 0.82, 1.0)),
                    border: Some(CjguiComposableUiColor(0.36, 0.58, 0.96, 1.0)),
                    textColor: Some(CjguiComposableUiColor(0.96, 0.98, 1.0, 1.0))),
                hover: CjguiComposableUiPaintStyle(
                    background: Some(CjguiComposableUiColor(0.28, 0.56, 0.94, 1.0)),
                    border: Some(CjguiComposableUiColor(0.52, 0.74, 1.0, 1.0))),
                pressed: CjguiComposableUiPaintStyle(
                    background: Some(CjguiComposableUiColor(0.12, 0.30, 0.68, 1.0))),
                focused: CjguiComposableUiPaintStyle(
                    border: Some(CjguiComposableUiColor(0.62, 0.86, 1.0, 1.0)), borderWidth: Some(2)),
                disabled: CjguiComposableUiPaintStyle(
                    background: Some(CjguiComposableUiColor(0.24, 0.28, 0.36, 1.0)),
                    border: Some(CjguiComposableUiColor(0.28, 0.34, 0.44, 1.0)),
                    textColor: Some(CjguiComposableUiColor(0.56, 0.62, 0.72, 1.0))),
                selected: CjguiComposableUiPaintStyle(
                    background: Some(CjguiComposableUiColor(0.30, 0.60, 0.92, 1.0))),
                checked: CjguiComposableUiPaintStyle(
                    border: Some(CjguiComposableUiColor(0.44, 0.94, 0.78, 1.0))))
        )
    }
    public static func paperLight(): CjguiComposableUiTheme {
        return CjguiComposableUiTheme(
            CjguiComposableUiStyle(background: CjguiComposableUiColor(0.94, 0.95, 0.97, 1.0), padding: 14, gap: 10),
            CjguiComposableUiStyle(background: CjguiComposableUiColor(1.0, 1.0, 1.0, 1.0),
                border: CjguiComposableUiColor(0.72, 0.74, 0.78, 1.0), padding: 10, gap: 8),
            CjguiComposableUiStyle(textColor: CjguiComposableUiColor(0.12, 0.16, 0.23, 1.0), fontSize: 18.0,
                fontWeight: 1),
            CjguiComposableUiStyle(textColor: CjguiComposableUiColor(0.30, 0.34, 0.40, 1.0), fontSize: 13.0),
            CjguiComposableUiStyle(fixedHeight: 38, background: CjguiComposableUiColor(1.0, 1.0, 1.0, 1.0),
                border: CjguiComposableUiColor(0.64, 0.68, 0.75, 1.0)),
            CjguiComposableUiStyle(fixedHeight: 30, background: CjguiComposableUiColor(0.20, 0.45, 0.82, 1.0),
                border: CjguiComposableUiColor(0.12, 0.32, 0.68, 1.0),
                textColor: CjguiComposableUiColor(1.0, 1.0, 1.0, 1.0), fontWeight: 1),
            inputInteraction: CjguiComposableUiInteractionStyle(
                normal: CjguiComposableUiPaintStyle(
                    border: Some(CjguiComposableUiColor(0.64, 0.68, 0.75, 1.0)),
                    textColor: Some(CjguiComposableUiColor(0.18, 0.22, 0.30, 1.0))),
                hover: CjguiComposableUiPaintStyle(
                    background: Some(CjguiComposableUiColor(0.96, 0.98, 1.0, 1.0)),
                    border: Some(CjguiComposableUiColor(0.38, 0.54, 0.86, 1.0))),
                pressed: CjguiComposableUiPaintStyle(
                    background: Some(CjguiComposableUiColor(0.90, 0.94, 1.0, 1.0))),
                focused: CjguiComposableUiPaintStyle(
                    border: Some(CjguiComposableUiColor(0.18, 0.42, 0.84, 1.0)), borderWidth: Some(2)),
                disabled: CjguiComposableUiPaintStyle(
                    background: Some(CjguiComposableUiColor(0.88, 0.89, 0.92, 1.0)),
                    border: Some(CjguiComposableUiColor(0.76, 0.78, 0.82, 1.0)),
                    textColor: Some(CjguiComposableUiColor(0.52, 0.54, 0.60, 1.0))),
                selected: CjguiComposableUiPaintStyle(
                    background: Some(CjguiComposableUiColor(0.84, 0.90, 1.0, 1.0))),
                checked: CjguiComposableUiPaintStyle(
                    border: Some(CjguiComposableUiColor(0.12, 0.62, 0.38, 1.0)))),
            primaryActionInteraction: CjguiComposableUiInteractionStyle(
                normal: CjguiComposableUiPaintStyle(
                    background: Some(CjguiComposableUiColor(0.20, 0.45, 0.82, 1.0)),
                    border: Some(CjguiComposableUiColor(0.12, 0.32, 0.68, 1.0)),
                    textColor: Some(CjguiComposableUiColor(1.0, 1.0, 1.0, 1.0))),
                hover: CjguiComposableUiPaintStyle(
                    background: Some(CjguiComposableUiColor(0.28, 0.56, 0.94, 1.0)),
                    border: Some(CjguiComposableUiColor(0.18, 0.40, 0.84, 1.0))),
                pressed: CjguiComposableUiPaintStyle(
                    background: Some(CjguiComposableUiColor(0.14, 0.34, 0.70, 1.0))),
                focused: CjguiComposableUiPaintStyle(
                    border: Some(CjguiComposableUiColor(0.10, 0.26, 0.62, 1.0)), borderWidth: Some(2)),
                disabled: CjguiComposableUiPaintStyle(
                    background: Some(CjguiComposableUiColor(0.72, 0.74, 0.78, 1.0)),
                    border: Some(CjguiComposableUiColor(0.64, 0.66, 0.70, 1.0)),
                    textColor: Some(CjguiComposableUiColor(0.86, 0.87, 0.90, 1.0))),
                selected: CjguiComposableUiPaintStyle(
                    background: Some(CjguiComposableUiColor(0.34, 0.58, 0.92, 1.0))),
                checked: CjguiComposableUiPaintStyle(
                    border: Some(CjguiComposableUiColor(0.10, 0.52, 0.30, 1.0))))
        )
    }
}

/// One logical fixed-row collection item. The framework treats `key` as the
/// item's durable UI identity; `resourceId` remains application-owned data
/// used by a row's ordinary action binding.
public class CjguiComposableUiVirtualListItem {
    public let key: String
    public let resourceId: Int64
    public let title: String
    public init(key: String, resourceId: Int64, title: String) {
        this.key = key
        this.resourceId = resourceId
        this.title = title
    }
    public static func missing(): CjguiComposableUiVirtualListItem {
        return CjguiComposableUiVirtualListItem("", -1, "")
    }
}

/// Range-addressable data and row construction for a fixed-row virtual list.
/// Implementors must return stable keys and node identities for live items;
/// this interface intentionally has no business fields or native handles.
public interface CjguiComposableUiVirtualListSource {
    func itemCount(): Int64
    func itemAt(index: Int64): CjguiComposableUiVirtualListItem
    func indexForKey(key: String): Int64
    func buildRow(item: CjguiComposableUiVirtualListItem, isSelected: Bool, isFocused: Bool): CjguiComposableUiNode
}

/// One logical row for the experimental variable-height collection API.
/// `layoutRevision` is owned by the source and must advance when this row's
/// ordinary subtree can measure differently. `estimatedHeight` is only the
/// bounded index's fallback until the row is revealed and measured; it is not
/// a native layout command or business-state field.
public class CjguiComposableUiVariableHeightListItem {
    public let key: String
    public let resourceId: Int64
    public let title: String
    public let layoutRevision: Int64
    public let estimatedHeight: Int64
    public init(key: String, resourceId: Int64, title: String, layoutRevision: Int64, estimatedHeight!: Int64 = 0) {
        this.key = key
        this.resourceId = resourceId
        this.title = title
        this.layoutRevision = if (layoutRevision >= 0) {
            layoutRevision
        } else {
            0
        }
        this.estimatedHeight = if (estimatedHeight > 0) {
            estimatedHeight
        } else {
            0
        }
    }
    public static func missing(): CjguiComposableUiVariableHeightListItem {
        return CjguiComposableUiVariableHeightListItem("", -1, "", 0)
    }
}

/// Experimental range source for rows whose final height is derived by the
/// regular Cangjie layout solver. The source owns key lookup, item revisions
/// and typography generation; the framework owns only a bounded derived
/// measurement cache. `measurementGeneration` changes when a shared layout
/// constraint such as font metrics changes, while a single content mutation
/// advances only that item's `layoutRevision`.
public interface CjguiComposableUiVariableHeightListSource {
    func itemCount(): Int64
    func itemAt(index: Int64): CjguiComposableUiVariableHeightListItem
    func indexForKey(key: String): Int64
    func measurementGeneration(): Int64
    func buildRow(item: CjguiComposableUiVariableHeightListItem, isSelected: Bool, isFocused: Bool): CjguiComposableUiNode
}

/// A sparse measured-height entry. It never retains a row subtree or source
/// content; at most the current materialization budget is retained and the
/// stable key is re-resolved once per layout pass.
private class CjguiComposableUiVariableHeightCacheEntry {
    let key: String
    var title: String
    var layoutRevision: Int64
    var resolvedHeight: Int64
    var measured: Bool
    var liveIndex: Int64
    init(key: String, title: String, layoutRevision: Int64, resolvedHeight: Int64, measured: Bool, liveIndex: Int64) {
        this.key = key
        this.title = title
        this.layoutRevision = layoutRevision
        this.resolvedHeight = if (resolvedHeight > 0) {
            resolvedHeight
        } else {
            1
        }
        this.measured = measured
        this.liveIndex = liveIndex
    }
}

/// Allocates the lifetime identity of one shared view-state object (scroll
/// viewport, split size, active tab page). The identity is what lets a window
/// release exactly the objects its accepted structure no longer references
/// without depending on language-level reference equality.
class CjguiComposableUiViewStateAllocator {
    private static let allocationLock = Mutex()
    private static var nextIdentity: Int64 = 1

    public static func allocate(): Int64 {
        return synchronized(CjguiComposableUiViewStateAllocator.allocationLock) {
            let identity = CjguiComposableUiViewStateAllocator.nextIdentity
            CjguiComposableUiViewStateAllocator.nextIdentity += 1
            return identity
        }
    }
}

/// Cangjie-owned view state for ONE generated split instance: the first pane's
/// current size plus both minimums. The declaration only SEEDS it; after that the
/// framework's single size rule (divider drag and keyboard) updates it, so
/// re-submitting the same structure, a theme change or a resize never silently
/// resets the layout a person just chose.
///
/// Stability: experimental. Together with the public scroll viewport this is the
/// minimal seam that lets a generated split share ONE view state with the window;
/// the shape may change, and it is never a business write permission.
public class CjguiComposableUiSplitState {
    // Per-window view state: see CjguiComposableUiScrollViewport.claimOwner.
    private var ownerWindowTokenValue: Int64 = 0
    // Lifetime identity of this view-state object. Two references are the same
    // object exactly when their identities are equal, which is what lets a window
    // release the objects its accepted structure no longer references without
    // depending on language-level reference equality.
    private let viewStateIdentityValue: Int64 = CjguiComposableUiViewStateAllocator.allocate()
    // Generation stamp of the last accepted-structure walk that saw this object.
    private var liveStampValue: Int64 = 0
    // CANDIDATE staging for a re-declaration: the bounds AND size in force before
    // the in-flight candidate first touched this instance. A rejected attempt
    // restores them, so a candidate that is never accepted cannot leave its
    // declaration or the geometry it solved with behind in an object the accepted
    // scene is still using.
    private var boundsRollbackArmedValue: Bool = false
    private var boundsRollbackFirstMinimumValue: Int64 = 0
    private var boundsRollbackSecondMinimumValue: Int64 = 0
    private var boundsRollbackFirstSizeValue: Int64 = 0
    private var firstSizeValue: Int64
    private var firstMinimumValue: Int64
    private var secondMinimumValue: Int64
    /// The track (handle included) the ACCEPTED scene really solved. Zero until
    /// a layout was accepted, so no sample width is ever invented here.
    private var acceptedTrackValue: Int64 = 0
    private var acceptedHandleValue: Int64 = 1
    private var acceptedFirstSizeValue: Int64 = 0

    public init(firstSize: Int64, firstMinimum: Int64, secondMinimum: Int64) {
        this.firstSizeValue = if (firstSize > 0) {
            firstSize
        } else {
            0
        }
        this.firstMinimumValue = if (firstMinimum > 0) {
            firstMinimum
        } else {
            0
        }
        this.secondMinimumValue = if (secondMinimum > 0) {
            secondMinimum
        } else {
            0
        }
    }

    /// Claims this split state for one window instance; see
    /// `CjguiComposableUiScrollViewport.claimOwner`.
    public func claimOwner(windowToken: Int64): Bool {
        if (windowToken <= 0) {
            return false
        }
        if (ownerWindowTokenValue == 0) {
            ownerWindowTokenValue = windowToken
            return true
        }
        return ownerWindowTokenValue == windowToken
    }
    public func ownerWindowToken(): Int64 {
        return ownerWindowTokenValue
    }
    public func firstSize(): Int64 {
        return firstSizeValue
    }
    public func firstMinimum(): Int64 {
        return firstMinimumValue
    }
    public func secondMinimum(): Int64 {
        return secondMinimumValue
    }

    /// Consumes a NEW declaration of the two minimums for an instance that already
    /// exists. The person's current size is untouched: the next solve clamps it
    /// with the ONE size rule against the real track and the new minimums, so a
    /// legal re-declaration of the constraints is honoured instead of silently
    /// keeping the old bounds.
    ///
    /// Both values are EXPLICIT declarations: `0` is a legal minimum ("no bound"),
    /// not "undeclared". A declaration absent from the description is expressed by
    /// NOT calling this at all, so removing a property can fall back to the public
    /// default instead of silently keeping an older value, and a read-only size
    /// query can never rewrite the constraints.
    public func declareBounds(firstMinimum: Int64, secondMinimum: Int64): Unit {
        firstMinimumValue = if (firstMinimum > 0) {
            firstMinimum
        } else {
            0
        }
        secondMinimumValue = if (secondMinimum > 0) {
            secondMinimum
        } else {
            0
        }
    }

    /// Candidate counterpart of `declareBounds`: applies the new declaration for
    /// THIS build while remembering the values in force before the candidate first
    /// touched this instance. `commitStagedBoundsDeclaration` keeps the new
    /// values; `discardStagedBoundsDeclaration` puts the old ones back, so a
    /// rejected candidate cannot rewrite the bounds an accepted split is using.
    public func stageBoundsDeclaration(firstMinimum: Int64, secondMinimum: Int64): Unit {
        if (!boundsRollbackArmedValue) {
            boundsRollbackArmedValue = true
            boundsRollbackFirstMinimumValue = firstMinimumValue
            boundsRollbackSecondMinimumValue = secondMinimumValue
            boundsRollbackFirstSizeValue = firstSizeValue
        }
        declareBounds(firstMinimum, secondMinimum)
    }

    /// Publishes the staged declaration together with the accepted scene.
    public func commitStagedBoundsDeclaration(): Unit {
        boundsRollbackArmedValue = false
    }

    /// Gives the pre-candidate bounds and size back when the attempt is rejected.
    /// The size is included because the candidate's own solve writes the size it
    /// clamped against the candidate bounds; a rejected attempt must leave the
    /// accepted instance's own size as the person left it.
    public func discardStagedBoundsDeclaration(): Unit {
        if (boundsRollbackArmedValue) {
            firstMinimumValue = boundsRollbackFirstMinimumValue
            secondMinimumValue = boundsRollbackSecondMinimumValue
            firstSizeValue = boundsRollbackFirstSizeValue
            boundsRollbackArmedValue = false
        }
    }

    /// True while a candidate declaration is applied but not yet accepted.
    public func hasStagedBoundsDeclaration(): Bool {
        return boundsRollbackArmedValue
    }

    /// Releases this instance for the window that owned it. Only the owning window
    /// token may release, so a rejected or foreign window can never drop another
    /// window's rights.
    public func releaseOwner(windowToken: Int64): Bool {
        if (windowToken <= 0 || ownerWindowTokenValue != windowToken) {
            return false
        }
        ownerWindowTokenValue = 0
        return true
    }

    /// Lifetime identity; see `viewStateIdentityValue`.
    public func viewStateIdentity(): Int64 {
        return viewStateIdentityValue
    }

    /// Framework bookkeeping for one accepted-structure walk.
    func markLive(stamp: Int64): Unit {
        liveStampValue = stamp
    }

    func liveStamp(): Int64 {
        return liveStampValue
    }

    /// The ONE size rule shared by the divider drag, the keyboard and the layout:
    /// `CjguiComposableUiSplitGeometry.firstSizeForTrack` already bounds the
    /// requested size by BOTH declared minimums and by the track that is really
    /// available, so the value recorded here is exactly the value the layout
    /// solves. Keeping a second, subtly different rule here made the state record
    /// a size the accepted geometry never used (and then poisoned the drag origin
    /// derived from it).
    public func applyFirstSize(requested: Int64, track: Int64, handleSize: Int64): Int64 {
        let bounded = CjguiComposableUiSplitGeometry.firstSizeForTrack(requested, track, handleSize,
            firstMinimumValue, secondMinimumValue)
        firstSizeValue = bounded
        advanceCaptureRevision()
        return bounded
    }

    /// The track and handle thickness of the ACCEPTED scene. Candidate solves
    /// only stage these facts, so a rejected attempt can never move the bounds a
    /// real drag is clamped against.
    public func acceptSplitTrack(track: Int64, handleSize: Int64, firstSize: Int64): Unit {
        acceptedTrackValue = if (track > 0) {
            track
        } else {
            0
        }
        acceptedHandleValue = if (handleSize > 0) {
            handleSize
        } else {
            1
        }
        acceptedFirstSizeValue = if (firstSize > 0) {
            firstSize
        } else {
            0
        }
    }
    public func acceptedTrack(): Int64 {
        return acceptedTrackValue
    }
    public func acceptedHandleSize(): Int64 {
        return acceptedHandleValue
    }
    /// The first pane width the ACCEPTED scene really allocated. Zero until a
    /// layout was accepted, so geometry derived from it can never use a request.
    public func acceptedFirstSize(): Int64 {
        return acceptedFirstSizeValue
    }

    /// Applies the framework's ONE size rule to a requested size. Before any
    /// layout was accepted the track is unknown, so only the declared minimums
    /// bound the value instead of an invented sample track.
    // A（复核修）：split 真修订 CAS（从主树移植）——外部 split 写推进修订，
    // 拖动相位携带捕获时修订比较；无关业务版本不影响。
    private var captureRevisionValue: Int64 = 0

    public func captureRevision(): Int64 { return captureRevisionValue }

    private func advanceCaptureRevision(): Unit {
        if (captureRevisionValue == Int64.Max) {
            captureRevisionValue = 1
        } else {
            captureRevisionValue += 1
        }
    }

    public func applyCapturedFirstSize(expectedRevision: Int64, requested: Int64, track: Int64,
        handleSize: Int64): ?Int64 {
        if (expectedRevision != captureRevisionValue) { return None }
        let _ = applyFirstSize(requested, track, handleSize)
        return Some(captureRevisionValue)
    }

    public func applyAcceptedFirstSize(requested: Int64): Int64 {
        if (acceptedTrackValue <= 0) {
            var bounded = if (requested < firstMinimumValue) {
                firstMinimumValue
            } else {
                requested
            }
            if (bounded < 0) {
                bounded = 0
            }
            firstSizeValue = bounded
            return bounded
        }
        advanceCaptureRevision()
        return applyFirstSize(requested, acceptedTrackValue, acceptedHandleValue)
    }

    /// Stores an already-bounded size, such as the layout's own clamp result.
    public func setFirstSize(size: Int64): Unit {
        firstSizeValue = if (size > 0) {
            size
        } else {
            0
        }
    }
}

/// One CANDIDATE split fact of a solve: the instance's view state plus the track
/// the solver really used. The window promotes it with the scene it accepts and
/// discards it with a rejected candidate, so a trial layout never publishes.
public class CjguiComposableUiSplitTrackFact {
    public let state: CjguiComposableUiSplitState
    public let track: Int64
    public let handleSize: Int64
    /// The first pane's width this solve really allocated. The window promotes it
    /// with the same scene, so a drag origin (or a keyboard base) can use the
    /// ACCEPTED geometry instead of a request that may never have been solved.
    public let firstSize: Int64
    public init(state: CjguiComposableUiSplitState, track: Int64, handleSize: Int64, firstSize: Int64) {
        this.state = state
        this.track = track
        this.handleSize = handleSize
        this.firstSize = firstSize
    }
}

/// Cangjie-owned view state for ONE tab container instance: which page is
/// ACTIVE. Selecting a page is a WINDOW view fact, never a business write: the
/// declaration's initial page only seeds a NEW instance, so re-submitting the
/// same structure (a reorder, a style change or an ordinary field refresh) can
/// never silently move a person back to the declared page.
///
/// Stability: experimental. This is the minimal public seam for generated and
/// handwritten tab containers; the shape may change, and it never carries a
/// business value.
public class CjguiComposableUiTabsState {
    // Per-window view state: see CjguiComposableUiScrollViewport.claimOwner.
    private var ownerWindowTokenValue: Int64 = 0
    // Lifetime identity / accepted-structure stamp; see
    // CjguiComposableUiSplitState.
    private let viewStateIdentityValue: Int64 = CjguiComposableUiViewStateAllocator.allocate()
    private var liveStampValue: Int64 = 0
    private var activeKeyValue: String = ""
    /// The page the DECLARATION asked for when this instance was created. It is
    /// kept separate from the active page so a later legal re-declaration that
    /// changes only the initial page cannot override a person's selection.
    private var declaredKeyValue: String = ""
    // CANDIDATE reconcile staging. A candidate build may drop the active page,
    // which must move the CANDIDATE scene to the fallback page; the live value
    // (a person's selection, or the last accepted page) is published only when
    // the scene containing it is accepted. A rejected candidate therefore cannot
    // move an accepted container, and a newer legal selection made while the
    // candidate was in flight is never overwritten by an older staging pass.
    private var stagedReconcileActiveValue: Bool = false
    private var stagedActiveKeyValue: String = ""
    private var stagedDeclaredKeyValue: String = ""
    private var stagedAvailableKeysValue: ArrayList<String> = ArrayList<String>()

    public init(initialPage: String) {
        this.activeKeyValue = initialPage
        this.declaredKeyValue = initialPage
    }

    /// The page this instance currently shows. Empty only before the first
    /// declaration seeded it.
    /// Claims this tab state for one window instance; see
    /// `CjguiComposableUiScrollViewport.claimOwner`.
    public func claimOwner(windowToken: Int64): Bool {
        if (windowToken <= 0) {
            return false
        }
        if (ownerWindowTokenValue == 0) {
            ownerWindowTokenValue = windowToken
            return true
        }
        return ownerWindowTokenValue == windowToken
    }
    public func ownerWindowToken(): Int64 {
        return ownerWindowTokenValue
    }

    /// Releases this instance for the window that owned it. Only the owning
    /// window token may release.
    public func releaseOwner(windowToken: Int64): Bool {
        if (windowToken <= 0 || ownerWindowTokenValue != windowToken) {
            return false
        }
        ownerWindowTokenValue = 0
        return true
    }

    /// Lifetime identity; see `viewStateIdentityValue`.
    public func viewStateIdentity(): Int64 {
        return viewStateIdentityValue
    }

    /// Framework bookkeeping for one accepted-structure walk.
    func markLive(stamp: Int64): Unit {
        liveStampValue = stamp
    }

    func liveStamp(): Int64 {
        return liveStampValue
    }

    /// The page this instance currently shows. While a candidate reconcile is
    /// staged, this is the page the CANDIDATE scene uses; the accepted value is
    /// restored/discarded at the same transaction boundary.
    public func activeKey(): String {
        return if (stagedReconcileActiveValue) {
            stagedActiveKeyValue
        } else {
            activeKeyValue
        }
    }

    public func declaredKey(): String {
        return if (stagedReconcileActiveValue) {
            stagedDeclaredKeyValue
        } else {
            declaredKeyValue
        }
    }

    /// True while a candidate reconcile is applied but not yet accepted.
    public func hasStagedReconcile(): Bool {
        return stagedReconcileActiveValue
    }

    /// Selects a page for the next accepted scene. Returns true when the
    /// selection moved, so a caller only requests a projection when something
    /// really changed.
    public func select(key: String): Bool {
        if (key.size == 0 || key == activeKeyValue) {
            return false
        }
        activeKeyValue = key
        return true
    }

    /// Keeps a page the instance already shows, or adopts the declared one when
    /// the current selection is no longer part of the description (a removed
    /// page must not leave the container pointing at nothing). Returns true when
    /// the active page changed.
    public func reconcile(availableKeys: ArrayList<String>, declaredKey: String): Bool {
        declaredKeyValue = declaredKey
        for (key in availableKeys) {
            if (key == activeKeyValue) {
                return false
            }
        }
        let fallback = if (declaredKey.size > 0) {
            declaredKey
        } else if (availableKeys.size > 0) {
            availableKeys[0]
        } else {
            ""
        }
        if (fallback == activeKeyValue) {
            return false
        }
        activeKeyValue = fallback
        return true
    }

    /// Candidate counterpart of `reconcile`: computes the page the candidate
    /// scene must show and remembers it without publishing it. Returns true when
    /// the candidate's active page differs from the accepted one.
    public func stageReconcile(availableKeys: ArrayList<String>, declaredKey: String): Bool {
        stagedReconcileActiveValue = true
        stagedDeclaredKeyValue = declaredKey
        stagedAvailableKeysValue = ArrayList<String>(availableKeys)
        var effective = activeKeyValue
        var found = false
        for (key in availableKeys) {
            if (key == activeKeyValue) {
                found = true
            }
        }
        if (!found) {
            effective = if (declaredKey.size > 0) {
                declaredKey
            } else if (availableKeys.size > 0) {
                availableKeys[0]
            } else {
                ""
            }
        }
        stagedActiveKeyValue = effective
        return effective != activeKeyValue
    }

    /// Publishes the staged reconcile with the accepted scene. A page the person
    /// selected while the candidate was in flight and that is still part of the
    /// accepted description wins over the older staging pass; otherwise the
    /// staged fallback is adopted so a removed page cannot leave the container
    /// pointing at nothing.
    public func commitStagedReconcile(): Unit {
        if (!stagedReconcileActiveValue) {
            return
        }
        declaredKeyValue = stagedDeclaredKeyValue
        var liveStillAvailable = false
        for (key in stagedAvailableKeysValue) {
            if (key == activeKeyValue) {
                liveStillAvailable = true
            }
        }
        if (!liveStillAvailable) {
            activeKeyValue = stagedActiveKeyValue
        }
        stagedReconcileActiveValue = false
        stagedAvailableKeysValue = ArrayList<String>()
    }

    /// Drops the staged reconcile of a rejected/abandoned attempt. The accepted
    /// active page and the person's pending selection are untouched.
    public func discardStagedReconcile(): Unit {
        stagedReconcileActiveValue = false
        stagedAvailableKeysValue = ArrayList<String>()
    }
}

/// Cangjie-owned vertical viewport for ORDINARY content. It deliberately does
/// not reuse the virtual-list state: it carries no selection, row or
/// materialization semantics, so a handwritten, generated or composite author
/// shares ONE viewport without inheriting list behavior.
///
/// Requested and accepted facts are kept apart: a wheel gesture only raises a
/// request, and the layout reports the extents and clamped offset it really
/// solved. A caller can therefore never read a pending request as accepted, and
/// content that shrank never leaves an out-of-range offset behind.
///
/// Stability: experimental. This is the minimal public seam for shared view
/// state while the generated scroll/split layout package evolves; the shape may
/// change, and applications should keep owning their business values.
// B/C（惯性包）：滚动物理策略全局开关——手写与生成 scrollArea 共同消费
// 的框架能力声明。稳定性 experimental；默认关闭，由窗口/应用显式启用。
public var cjguiComposableInertialScrollEnabled: Bool = false

public class CjguiComposableUiScrollViewport {
    // The window INSTANCE that accepted a scene containing this viewport. A
    // viewport is per-window view state: sharing ONE mutable object between two
    // windows would let either window's wheel/edit silently move the other's
    // accepted geometry, so a second window's candidate is refused instead.
    private var ownerWindowTokenValue: Int64 = 0
    // Lifetime identity / accepted-structure stamp; see
    // CjguiComposableUiSplitState.
    private let viewStateIdentityValue: Int64 = CjguiComposableUiViewStateAllocator.allocate()
    private var liveStampValue: Int64 = 0
    private var requestedOffsetValue: Int64 = 0
    private var acceptedOffsetValue: Int64 = 0
    private var contentExtentValue: Int64 = 0
    private var viewportExtentValue: Int64 = 0
    private var acceptedSolveCountValue: Int64 = 0
    // The layout's CANDIDATE facts for the solve currently in flight. They are
    // promoted only when the window accepts the scene that contains this
    // viewport, so a rejected/early-returned candidate can never leak into the
    // accepted facts the previous scene is still using.
    private var stagedContentExtentValue: Int64 = 0
    private var stagedViewportExtentValue: Int64 = 0
    private var stagedOffsetValue: Int64 = 0
    private var stagedSolvedValue: Bool = false

    /// The offset the next build should use.
    public func offset(): Int64 {
        return requestedOffsetValue
    }
    /// The offset the current accepted scene was laid out with.
    public func acceptedOffset(): Int64 {
        return acceptedOffsetValue
    }
    public func contentExtent(): Int64 {
        return contentExtentValue
    }
    /// Claims this viewport for one window instance. Returns false when a
    /// DIFFERENT window already accepted a scene containing it: the caller must
    /// refuse its own candidate rather than let two windows share one mutable
    /// view object.
    public func claimOwner(windowToken: Int64): Bool {
        if (windowToken <= 0) {
            return false
        }
        if (ownerWindowTokenValue == 0) {
            ownerWindowTokenValue = windowToken
            return true
        }
        return ownerWindowTokenValue == windowToken
    }
    /// The window instance that owns this viewport, or 0 while unclaimed.
    public func ownerWindowToken(): Int64 {
        return ownerWindowTokenValue
    }
    /// Releases this viewport for the window that owned it. Only the owning
    /// window token may release, so a rejected or foreign window can never drop
    /// another window's rights.
    public func releaseOwner(windowToken: Int64): Bool {
        if (windowToken <= 0 || ownerWindowTokenValue != windowToken) {
            return false
        }
        ownerWindowTokenValue = 0
        return true
    }
    /// Lifetime identity; see `viewStateIdentityValue`.
    public func viewStateIdentity(): Int64 {
        return viewStateIdentityValue
    }
    /// Framework bookkeeping for one accepted-structure walk.
    func markLive(stamp: Int64): Unit {
        liveStampValue = stamp
    }
    func liveStamp(): Int64 {
        return liveStampValue
    }
    public func viewportExtent(): Int64 {
        return viewportExtentValue
    }
    public func acceptedSolveCount(): Int64 {
        return acceptedSolveCountValue
    }
    public func maximumOffset(): Int64 {
        let span = contentExtentValue - viewportExtentValue
        return if (span > 0) {
            span
        } else {
            0
        }
    }
    public func hasPendingRequest(): Bool {
        return requestedOffsetValue != acceptedOffsetValue
    }
    /// Requests an offset for the NEXT build. It is clamped to the extents the
    /// layout last accepted and is never reported as accepted by itself.
    public func requestOffset(offset: Int64): Bool {
        let clamped = clamp(offset)
        if (clamped == requestedOffsetValue) {
            return false
        }
        requestedOffsetValue = clamped
        return true
    }
    /// The declaration's INITIAL value for a brand-new instance. Unlike
    /// `requestOffset` it does not clamp against extents that are not known yet:
    /// the first accepted solve clamps it like any other request, so a later
    /// refresh that re-submits the same structure cannot reset the view state of
    /// an instance that already exists.
    public func requestInitialOffset(offset: Int64): Unit {
        requestedOffsetValue = if (offset > 0) {
            offset
        } else {
            0
        }
    }

    public func scrollBy(delta: Int64): Bool {
        return requestOffset(requestedOffsetValue.saturatingAdd(delta))
    }

    // B/C（惯性包）：松手减速滚动活动。固定容量速度窗 + 边界夹紧的解析
    // 衰减模型；使用显式单调时间，不逐帧乘系数。活动属于本 viewport（窗口
    // 实例 + 稳定身份），新触摸/程序化定位/换绑即退役旧活动。
    // 实验性声明：稳定性等级 experimental，默认关闭；由手写与生成 scrollArea
    // 共同消费（同一份策略，不在样例分别调 native 常量）。
    private var inertialVelocityPxPerMs: Float64 = 0.0
    private var inertialLastTick: MonoTime = MonoTime.now()
    private var inertialGeneration: Int64 = 0

    /// 滚动物理策略（experimental）：速度低于该值（px/ms）即停止。
    public static let inertialStopVelocityPxPerMs: Float64 = 0.01
    /// 指数衰减时间常数（ms）：每经过 τ，速度乘 1/e（解析衰减，帧率无关）。
    public static let inertialDecayTauMs: Float64 = 325.0
    /// 单次惯性总时长上界（ms），防止极端输入长跑。
    public static let inertialMaxDurationMs: Int64 = 2500

    /// 记录一次松手速度（由速度估计器在 END 后写入；正方向 = 内容向上滚动）。
    /// 返回 true 表示启动了惯性活动。
    public func beginInertialScroll(velocityPxPerMs: Float64, now: MonoTime): Bool {
        if (!isWindowInertialScrollEnabled()) {
            return false
        }
        // NaN/Inf 准入拒绝（复核反例：不制造速度）。
        if (velocityPxPerMs != velocityPxPerMs || abs(velocityPxPerMs) > 1.0e300) {
            return false
        }
        if (velocityPxPerMs < CjguiComposableUiScrollViewport.inertialStopVelocityPxPerMs &&
            velocityPxPerMs > -CjguiComposableUiScrollViewport.inertialStopVelocityPxPerMs) {
            return false
        }
        inertialVelocityPxPerMs = velocityPxPerMs
        inertialLastTick = now
        inertialSubPixelRemainder = 0.0
        inertialElapsedNs = 0
        inertialGeneration += 1
        return true
    }

    // C（复核修）：亚像素累计余量——集中量化，避免 Int64 截断随帧率丢距离。
    private var inertialSubPixelRemainder: Float64 = 0.0
    // C（复核修）：活动累计时长（ns），用于 2500ms 工作上界。
    private var inertialElapsedNs: Int64 = 0

    /// 一次惯性推进（由窗口 pump 周期调用）：解析衰减积分 + 集中量化。
    /// 帧率无关：位移由 (v0, τ, dt) 解析决定，Int64 量化只发生在亚像素
    /// 余量累计后。停止条件（按序评估）：NaN/Inf 准入拒绝、总时长上界、
    /// 速度耗尽（积分到明确定义的停止时刻）、边界夹紧。
    public func stepInertialScroll(now: MonoTime): Bool {
        if (inertialVelocityPxPerMs == 0.0) {
            return false
        }
        // NaN/Inf 准入：不制造速度（复核反例）。
        if (inertialVelocityPxPerMs != inertialVelocityPxPerMs || abs(inertialVelocityPxPerMs) > 1.0e300) {
            inertialVelocityPxPerMs = 0.0
            inertialSubPixelRemainder = 0.0
            inertialElapsedNs = 0
            return false
        }
        let elapsedNs = (now - inertialLastTick).toNanoseconds()
        if (elapsedNs < 0) {
            // 时钟倒退：终结活动（不制造位移）。
            inertialVelocityPxPerMs = 0.0
            inertialSubPixelRemainder = 0.0
            inertialElapsedNs = 0
            return false
        }
        if (elapsedNs == 0) {
            return true  // 时钟重复：跳过本帧，不制造位移
        }
        // 工作上界：总时长超过 inertialMaxDurationMs 即终结。
        inertialElapsedNs += elapsedNs
        if (inertialElapsedNs > CjguiComposableUiScrollViewport.inertialMaxDurationMs * 1_000_000) {
            inertialVelocityPxPerMs = 0.0
            inertialSubPixelRemainder = 0.0
            inertialElapsedNs = 0
            return false
        }
        let elapsedMs = Float64(elapsedNs) / 1_000_000.0
        // 解析衰减 v(t) = v0 * exp(-t/τ)（帧率无关）。
        let decay = exp(-elapsedMs / CjguiComposableUiScrollViewport.inertialDecayTauMs)
        let newVelocity = inertialVelocityPxPerMs * decay
        // 解析积分位移 = v0*τ*(1-e^(-t/τ))（本段积分，帧率无关）。
        let displacement = inertialVelocityPxPerMs *
            CjguiComposableUiScrollViewport.inertialDecayTauMs * (1.0 - decay)
        inertialVelocityPxPerMs = newVelocity
        inertialLastTick = now
        // 集中量化：亚像素余量跨帧累计，整数部分一次交付。
        inertialSubPixelRemainder += displacement
        let wholeF = if (inertialSubPixelRemainder >= 0.0) {
            floor(inertialSubPixelRemainder)
        } else {
            ceil(inertialSubPixelRemainder)
        }
        let whole = Int64(wholeF)
        if (whole != 0) {
            inertialSubPixelRemainder -= Float64(whole)
            let moved = scrollBy(whole)
            if (!moved) {
                // 到达边界（夹紧后无变化）：活动结束。
                stopInertialScroll()
                return false
            }
        }
        // 速度耗尽：积分已交付到停止时刻（余量保留但不继续推进）。
        if (newVelocity < CjguiComposableUiScrollViewport.inertialStopVelocityPxPerMs &&
            newVelocity > -CjguiComposableUiScrollViewport.inertialStopVelocityPxPerMs) {
            inertialVelocityPxPerMs = 0.0
            inertialElapsedNs = 0
            return false
        }
        return true
    }

    /// 新触摸/程序化定位立即停止惯性（外部不重复调用）。
    public func stopInertialScroll(): Unit {
        inertialVelocityPxPerMs = 0.0
        inertialSubPixelRemainder = 0.0
        inertialElapsedNs = 0
        inertialGeneration += 1
    }

    public func isInertialScrollActive(): Bool {
        return inertialVelocityPxPerMs != 0.0
    }

    private func isWindowInertialScrollEnabled(): Bool {
        // 共同声明：默认关闭，由窗口的统一策略开关控制（手写/生成同源）。
        return cjguiComposableInertialScrollEnabled
    }
    /// One wheel step: `next` moves toward the end of the content, `previous`
    /// toward the start. An unknown direction is not a scroll.
    public func step(direction: String, step: Int64): Bool {
        let unit = if (step > 0) {
            step
        } else {
            1
        }
        if (direction == "next") {
            return scrollBy(unit)
        }
        if (direction == "previous") {
            return scrollBy(0 - unit)
        }
        return false
    }
    /// Reveals [start, end) of the content. Returns true when the request moved,
    /// so "already visible" and "a new scene is needed" stay distinguishable.
    public func reveal(start: Int64, end: Int64, margin!: Int64 = 0): Bool {
        let top = if (start - margin > 0) {
            start - margin
        } else {
            0
        }
        let bottom = end + margin
        if (top < acceptedOffsetValue) {
            return requestOffset(top)
        }
        let visibleEnd = acceptedOffsetValue + viewportExtentValue
        if (bottom > visibleEnd) {
            return requestOffset(bottom - viewportExtentValue)
        }
        return false
    }
    /// Called by the layout with what THIS solve measured. These are candidate
    /// facts: they do not become accepted until the window accepts the scene that
    /// contains this viewport (`commitStagedExtents`). An empty scroll area stages
    /// zero content and a zero offset while keeping the viewport's real geometry.
    public func stageExtents(content: Int64, viewport: Int64, offset: Int64): Unit {
        stagedContentExtentValue = if (content > 0) {
            content
        } else {
            0
        }
        stagedViewportExtentValue = if (viewport > 0) {
            viewport
        } else {
            0
        }
        stagedOffsetValue = if (offset > 0) {
            offset
        } else {
            0
        }
        stagedSolvedValue = true
    }

    /// Whether a solve staged facts that are not yet accepted.
    public func hasStagedExtents(): Bool {
        return stagedSolvedValue
    }

    /// Promotes the staged solve to the accepted facts. The pending request
    /// converges to the clamped offset the accepted scene really used, so a
    /// request is never reported as accepted before this point.
    public func commitStagedExtents(): Unit {
        if (!stagedSolvedValue) {
            return
        }
        let span = stagedContentExtentValue - stagedViewportExtentValue
        let maximum = if (span > 0) {
            span
        } else {
            0
        }
        let clamped = if (stagedOffsetValue > maximum) {
            maximum
        } else {
            stagedOffsetValue
        }
        contentExtentValue = stagedContentExtentValue
        viewportExtentValue = stagedViewportExtentValue
        acceptedOffsetValue = if (clamped > 0) {
            clamped
        } else {
            0
        }
        // The request has been presented; it is no longer pending.
        requestedOffsetValue = acceptedOffsetValue
        acceptedSolveCountValue += 1
        stagedSolvedValue = false
    }

    /// Drops the staged solve of a candidate the window did NOT accept. The
    /// accepted facts stay exactly as the previous scene left them and the
    /// pending request is preserved, so the next legal refresh can present it
    /// instead of silently forgetting or mislabelling it.
    public func discardStagedExtents(): Unit {
        stagedSolvedValue = false
    }
    /// Content can shrink or disappear: the requested offset never keeps an
    /// out-of-range value that would show blank space.
    public func clampToAccepted(): Unit {
        requestedOffsetValue = clamp(requestedOffsetValue)
    }
    private func clamp(offset: Int64): Int64 {
        if (offset < 0) {
            return 0
        }
        let maximum = maximumOffset()
        return if (offset > maximum) {
            maximum
        } else {
            offset
        }
    }
}

/// Cangjie-owned view state for one virtual list. Selection, focus and anchor
/// are stable keys, never currently materialized row indexes. The application
/// remains responsible for applying a selected row to its domain truth.
public class CjguiComposableUiVirtualListState {
    private var scrollOffsetValue: Int64
    private var selectedKeyValue: String
    private var focusedKeyValue: String
    private var anchorKeyValue: String
    private var materializedStartValue: Int64
    private var materializedEndValue: Int64
    private var lastViewportHeight: Int64
    private var lastRowStride: Int64
    private var anchorIntraRowOffsetValue: Int64
    private var hasPendingUserScroll: Bool
    private var lastDataIssueValue: String
    // Variable-height entries are a sparse, bounded correction index over a
    // uniform unseen-row estimate. They contain no component tree or domain
    // content, so a 10,000-row source never becomes a 10,000-row UI cache.
    private var variableHeightCache: ArrayList<CjguiComposableUiVariableHeightCacheEntry>
    private var variableMeasurementWidth: Int64
    private var variableMeasurementGeneration: Int64
    private var variableAnchorIndexValue: Int64
    private var variableMaterializedOriginValue: Int64
    private var variableEstimatedHeightValue: Int64
    private var variableRowGapValue: Int64

    public init() {
        this.scrollOffsetValue = 0
        this.selectedKeyValue = ""
        this.focusedKeyValue = ""
        this.anchorKeyValue = ""
        this.materializedStartValue = 0
        this.materializedEndValue = 0
        this.lastViewportHeight = 0
        this.lastRowStride = 1
        this.anchorIntraRowOffsetValue = 0
        this.hasPendingUserScroll = false
        this.lastDataIssueValue = ""
        this.variableHeightCache = ArrayList<CjguiComposableUiVariableHeightCacheEntry>()
        this.variableMeasurementWidth = -1
        this.variableMeasurementGeneration = -1
        this.variableAnchorIndexValue = 0
        this.variableMaterializedOriginValue = 0
        this.variableEstimatedHeightValue = 1
        this.variableRowGapValue = 0
    }

    public func scrollOffset(): Int64 {
        return scrollOffsetValue
    }
    public func selectedKey(): String {
        return selectedKeyValue
    }
    public func focusedKey(): String {
        return focusedKeyValue
    }
    public func anchorKey(): String {
        return anchorKeyValue
    }
    public func materializedStart(): Int64 {
        return materializedStartValue
    }
    /// Exclusive end index of the current component range.
    public func materializedEnd(): Int64 {
        return materializedEndValue
    }
    /// Logical y coordinate of the first materialized variable row. Fixed
    /// lists continue to derive the same value from their constant stride.
    func variableMaterializedOrigin(): Int64 {
        return variableMaterializedOriginValue
    }
    /// Empty means every materialized identity was usable.  Invalid source
    /// rows reserve their fixed stride rather than being rebound to a sibling.
    public func lastDataIssue(): String {
        return lastDataIssueValue
    }
    public func setSelectedKey(key: String) {
        selectedKeyValue = key
    }
    public func setFocusedKey(key: String) {
        focusedKeyValue = key
    }

    /// A user scroll changes only local viewport state. It does not claim a
    /// content/domain version and is clamped on the next layout against the
    /// then-current logical collection size.
    public func scrollByViewport(direction: String) {
        let delta = if (lastViewportHeight > 0) {
            lastViewportHeight
        } else {
            lastRowStride
        }
        if (direction == "next") {
            scrollOffsetValue = scrollOffsetValue.saturatingAdd(delta)
        } else if (direction == "previous") {
            scrollOffsetValue = if (scrollOffsetValue > delta) {
                scrollOffsetValue - delta
            } else {
                0
            }
        }
        hasPendingUserScroll = true
    }

    public func scrollToIndex(index: Int64) {
        if (index <= 0) {
            scrollOffsetValue = 0
            hasPendingUserScroll = true
            return
        }
        scrollOffsetValue = index.saturatingMul(if (lastRowStride > 0) {
            lastRowStride
        } else {
            1
        })
        hasPendingUserScroll = true
    }

    public func revealKey(source: CjguiComposableUiVirtualListSource, key: String): Bool {
        let index = source.indexForKey(key)
        if (index < 0 || index >= normalizedCount(source.itemCount())) {
            return false
        }
        anchorKeyValue = key
        scrollToIndex(index)
        hasPendingUserScroll = false
        anchorIntraRowOffsetValue = 0
        return true
    }

    /// Resolve one collection navigation command without relying on a row's
    /// transient materialized index. The caller turns the returned item into
    /// its ordinary select/action operation.
    public func moveFocus(source: CjguiComposableUiVirtualListSource, command: String): CjguiComposableUiVirtualListItem {
        let count = normalizedCount(source.itemCount())
        if (count == 0) {
            focusedKeyValue = ""
            anchorKeyValue = ""
            return CjguiComposableUiVirtualListItem.missing()
        }
        var current = source.indexForKey(focusedKeyValue)
        if (current < 0 || current >= count) {
            current = source.indexForKey(selectedKeyValue)
        }
        if (current < 0 || current >= count) {
            current = 0
        }
        let page = if (lastViewportHeight > 0 && lastRowStride > 0) {
            maxValue(1, (lastViewportHeight + lastRowStride - 1) / lastRowStride)
        } else {
            1
        }
        if (command == "up") {
            current = if (current > 0) {
                current - 1
            } else {
                0
            }
        } else if (command == "down") {
            current = if (current + 1 < count) {
                current + 1
            } else {
                count - 1
            }
        } else if (command == "page_up") {
            current = if (current > page) {
                current - page
            } else {
                0
            }
        } else if (command == "page_down") {
            current = if (current.saturatingAdd(page) < count) {
                current + page
            } else {
                count - 1
            }
        } else if (command == "home") {
            current = 0
        } else if (command == "end") {
            current = count - 1
        }
        let item = source.itemAt(current)
        if (item.key.size == 0) {
            return CjguiComposableUiVirtualListItem.missing()
        }
        focusedKeyValue = item.key
        anchorKeyValue = item.key
        scrollToIndex(current)
        hasPendingUserScroll = false
        anchorIntraRowOffsetValue = 0
        return item
    }

    /// Called by the layout owner with actual viewport geometry. It clamps a
    /// large offset safely, calculates the logical total height, and records
    /// only the inclusive visible range plus a small caller-chosen buffer.
    func updateMaterializedRange(source: CjguiComposableUiVirtualListSource, rowHeight: Int64, rowGap: Int64,
        viewportHeight: Int64, overscan: Int64): Int64 {
        let count = normalizedCount(source.itemCount())
        let height = if (rowHeight > 0) {
            rowHeight
        } else {
            1
        }
        let gap = if (rowGap > 0) {
            rowGap
        } else {
            0
        }
        let stride = height.saturatingAdd(gap)
        let viewport = if (viewportHeight > 0) {
            viewportHeight
        } else {
            1
        }
        let buffer = if (overscan > 0) {
            overscan
        } else {
            0
        }
        let totalHeight = if (count == 0) {
            0
        } else {
            height.saturatingMul(count).saturatingAdd(gap.saturatingMul(count - 1))
        }
        let maximumOffset = if (totalHeight > viewport) {
            totalHeight - viewport
        } else {
            0
        }
        if (scrollOffsetValue > maximumOffset) {
            scrollOffsetValue = maximumOffset
        }
        if (scrollOffsetValue < 0) {
            scrollOffsetValue = 0
        }
        lastDataIssueValue = ""
        // A scroll gesture deliberately chooses a new anchor on this pass.
        // Otherwise preserve the existing stable key across insertion,
        // deletion-before, reordering and filtering without translating it
        // through the old materialized index.
        if (!hasPendingUserScroll && anchorKeyValue.size > 0) {
            let anchorIndex = liveIndexForKey(source, count, anchorKeyValue)
            if (anchorIndex >= 0) {
                scrollOffsetValue = anchorIndex.saturatingMul(stride).saturatingAdd(anchorIntraRowOffsetValue)
            } else {
                anchorKeyValue = ""
                anchorIntraRowOffsetValue = 0
                lastDataIssueValue = "anchor_missing"
            }
        }
        // Selection and focus are independent stable identities. A refresh
        // may remove either while preserving the viewport anchor, so never
        // carry it to whatever row inherited the prior materialized index.
        if (selectedKeyValue.size > 0 && liveIndexForKey(source, count, selectedKeyValue) < 0) {
            selectedKeyValue = ""
            noteDataIssue("selected_missing")
        }
        if (focusedKeyValue.size > 0 && liveIndexForKey(source, count, focusedKeyValue) < 0) {
            focusedKeyValue = ""
            noteDataIssue("focused_missing")
        }
        if (scrollOffsetValue > maximumOffset) {
            scrollOffsetValue = maximumOffset
        }
        if (scrollOffsetValue < 0) {
            scrollOffsetValue = 0
        }
        lastViewportHeight = viewport
        lastRowStride = if (stride > 0) {
            stride
        } else {
            1
        }
        if (count == 0) {
            materializedStartValue = 0
            materializedEndValue = 0
            return totalHeight
        }
        let firstVisible = if (stride > 0) {
            scrollOffsetValue / stride
        } else {
            0
        }
        let firstItem = source.itemAt(firstVisible)
        if (hasPendingUserScroll || anchorKeyValue.size == 0) {
            if (firstItem.key.size > 0 && source.indexForKey(firstItem.key) == firstVisible) {
                anchorKeyValue = firstItem.key
                anchorIntraRowOffsetValue = scrollOffsetValue % stride
            } else {
                anchorKeyValue = ""
                anchorIntraRowOffsetValue = 0
                // An empty item is directly identifiable here. A non-empty
                // key with a contradictory reverse lookup may instead be a
                // duplicate, which materialization diagnoses precisely.
                if (firstItem.key.size == 0 && lastDataIssueValue.size == 0) {
                    lastDataIssueValue = "missing_key"
                }
            }
        } else {
            anchorIntraRowOffsetValue = scrollOffsetValue % stride
        }
        hasPendingUserScroll = false
        let visibleRows = maxValue(1, (viewport.saturatingAdd(stride - 1)) / stride)
        materializedStartValue = if (firstVisible > buffer) {
            firstVisible - buffer
        } else {
            0
        }
        // `overscan` is the total bounded allowance: earlier rows consume it
        // first around a scrolled anchor, with the remainder extending after
        // the visible range. This retains the historical seven-row first
        // viewport for a five-row list with an allowance of two.
        let requestedRows = visibleRows.saturatingAdd(buffer)
        let boundedRows = if (requestedRows < CJGUI_COMPOSABLE_UI_MAX_VIRTUAL_MATERIALIZED_ROWS) {
            requestedRows
        } else {
            CJGUI_COMPOSABLE_UI_MAX_VIRTUAL_MATERIALIZED_ROWS
        }
        let afterVisible = materializedStartValue.saturatingAdd(boundedRows)
        materializedEndValue = if (afterVisible < count) {
            afterVisible
        } else {
            count
        }
        return totalHeight
    }

    /// Variable-height reveal follows the same stable-key contract as the
    /// fixed-row overload, but resolves the key through the sparse cumulative
    /// index rather than multiplying a fixed stride.
    public func revealKey(source: CjguiComposableUiVariableHeightListSource, key: String): Bool {
        let count = normalizedCount(source.itemCount())
        let index = liveVariableIndexForKey(source, count, key)
        if (index < 0) {
            return false
        }
        anchorKeyValue = key
        variableAnchorIndexValue = index
        anchorIntraRowOffsetValue = 0
        scrollOffsetValue = variableOffsetForIndex(count, index, variableEstimatedHeightValue, variableRowGapValue)
        hasPendingUserScroll = false
        return true
    }

    /// Keyboard navigation retains source-owned identity. Page commands use
    /// the last actual/estimated geometry rather than a fixed row count.
    public func moveFocus(source: CjguiComposableUiVariableHeightListSource, command: String): CjguiComposableUiVariableHeightListItem {
        let count = normalizedCount(source.itemCount())
        if (count == 0) {
            focusedKeyValue = ""
            anchorKeyValue = ""
            return CjguiComposableUiVariableHeightListItem.missing()
        }
        var current = liveVariableIndexForKey(source, count, focusedKeyValue)
        if (current < 0) {
            current = liveVariableIndexForKey(source, count, selectedKeyValue)
        }
        if (current < 0) {
            current = 0
        }
        if (command == "up") {
            current = if (current > 0) {
                current - 1
            } else {
                0
            }
        } else if (command == "down") {
            current = if (current + 1 < count) {
                current + 1
            } else {
                count - 1
            }
        } else if (command == "page_up") {
            let target = if (scrollOffsetValue > lastViewportHeight) {
                scrollOffsetValue - lastViewportHeight
            } else {
                0
            }
            current = variableIndexForOffset(count, target, variableEstimatedHeightValue, variableRowGapValue)
        } else if (command == "page_down") {
            current = variableIndexForOffset(count, scrollOffsetValue.saturatingAdd(lastViewportHeight),
                variableEstimatedHeightValue, variableRowGapValue)
        } else if (command == "home") {
            current = 0
        } else if (command == "end") {
            current = count - 1
        }
        let item = source.itemAt(current)
        if (item.key.size == 0 || source.indexForKey(item.key) != current) {
            return CjguiComposableUiVariableHeightListItem.missing()
        }
        focusedKeyValue = item.key
        anchorKeyValue = item.key
        variableAnchorIndexValue = current
        anchorIntraRowOffsetValue = 0
        scrollOffsetValue = variableOffsetForIndex(count, current, variableEstimatedHeightValue, variableRowGapValue)
        hasPendingUserScroll = false
        return item
    }

    /// Width and shared typography generation are real measurement inputs.
    /// A change clears only this derived sparse cache; item-specific changes
    /// below retain all unaffected entries and are refreshed lazily.
    func prepareVariableMeasurementContext(source: CjguiComposableUiVariableHeightListSource, width: Int64): Unit {
        let safeWidth = if (width > 0) {
            width
        } else {
            1
        }
        let generation = source.measurementGeneration()
        if (safeWidth != variableMeasurementWidth || generation != variableMeasurementGeneration) {
            variableHeightCache = ArrayList<CjguiComposableUiVariableHeightCacheEntry>()
            variableMeasurementWidth = safeWidth
            variableMeasurementGeneration = generation
            return
        }
        var index: Int64 = 0
        while (index < variableHeightCache.size) {
            let entry = variableHeightCache[index]
            let live = source.indexForKey(entry.key)
            if (live < 0 || live >= normalizedCount(source.itemCount())) {
                entry.liveIndex = -1
            } else {
                let item = source.itemAt(live)
                if (item.key != entry.key) {
                    entry.liveIndex = -1
                } else {
                    entry.liveIndex = live
                    if (item.layoutRevision != entry.layoutRevision || item.title != entry.title) {
                        entry.title = item.title
                        entry.layoutRevision = item.layoutRevision
                        entry.resolvedHeight = variableEstimateForItem(item, variableEstimatedHeightValue)
                        entry.measured = false
                    }
                }
            }
            index += 1
        }
    }

    /// Resolve logical total height and the one bounded materialized range.
    /// The offset locator uses a binary search over the uniform estimate plus
    /// at most 128 sparse corrections; it never asks for every source item.
    func updateVariableMaterializedRange(source: CjguiComposableUiVariableHeightListSource, estimatedHeight: Int64,
        rowGap: Int64, viewportHeight: Int64, overscan: Int64): Int64 {
        let count = normalizedCount(source.itemCount())
        let estimate = if (estimatedHeight > 0) {
            estimatedHeight
        } else {
            1
        }
        let gap = if (rowGap > 0) {
            rowGap
        } else {
            0
        }
        let viewport = if (viewportHeight > 0) {
            viewportHeight
        } else {
            1
        }
        let buffer = if (overscan > 0) {
            overscan
        } else {
            0
        }
        variableEstimatedHeightValue = estimate
        variableRowGapValue = gap
        lastDataIssueValue = ""
        let totalHeight = variableTotalHeight(count, estimate, gap)
        let maximumOffset = if (totalHeight > viewport) {
            totalHeight - viewport
        } else {
            0
        }
        if (!hasPendingUserScroll && anchorKeyValue.size > 0) {
            let anchorIndex = liveVariableIndexForKey(source, count, anchorKeyValue)
            if (anchorIndex >= 0) {
                variableAnchorIndexValue = anchorIndex
                let rowHeight = variableHeightAtIndex(anchorIndex, estimate)
                let intra = if (anchorIntraRowOffsetValue < rowHeight) {
                    anchorIntraRowOffsetValue
                } else {
                    0
                }
                anchorIntraRowOffsetValue = intra
                scrollOffsetValue = variableOffsetForIndex(count, anchorIndex, estimate, gap).saturatingAdd(intra)
            } else {
                // Deletion selects the successor at the previous logical
                // position; when the tail was deleted it selects its prior
                // neighbour. The fallback remains a viewport identity only,
                // never a replacement selection/focus decision.
                let fallback = if (count > 0) {
                    if (variableAnchorIndexValue < count) {
                        variableAnchorIndexValue
                    } else {
                        count - 1
                    }
                } else {
                    -1
                }
                let candidate = if (fallback >= 0) {
                    source.itemAt(fallback)
                } else {
                    CjguiComposableUiVariableHeightListItem.missing()
                }
                if (candidate.key.size > 0 && source.indexForKey(candidate.key) == fallback) {
                    anchorKeyValue = candidate.key
                    variableAnchorIndexValue = fallback
                    anchorIntraRowOffsetValue = 0
                    scrollOffsetValue = variableOffsetForIndex(count, fallback, estimate, gap)
                    lastDataIssueValue = "anchor_deleted_next"
                } else {
                    anchorKeyValue = ""
                    anchorIntraRowOffsetValue = 0
                    variableAnchorIndexValue = 0
                    lastDataIssueValue = "anchor_missing"
                }
            }
        }
        if (selectedKeyValue.size > 0 && liveVariableIndexForKey(source, count, selectedKeyValue) < 0) {
            selectedKeyValue = ""
            noteDataIssue("selected_missing")
        }
        if (focusedKeyValue.size > 0 && liveVariableIndexForKey(source, count, focusedKeyValue) < 0) {
            focusedKeyValue = ""
            noteDataIssue("focused_missing")
        }
        if (scrollOffsetValue > maximumOffset) {
            scrollOffsetValue = maximumOffset
        }
        if (scrollOffsetValue < 0) {
            scrollOffsetValue = 0
        }
        lastViewportHeight = viewport
        lastRowStride = estimate.saturatingAdd(gap)
        if (count == 0) {
            materializedStartValue = 0
            materializedEndValue = 0
            variableMaterializedOriginValue = 0
            return totalHeight
        }
        let firstVisible = variableIndexForOffset(count, scrollOffsetValue, estimate, gap)
        let firstItem = source.itemAt(firstVisible)
        if (hasPendingUserScroll || anchorKeyValue.size == 0) {
            if (firstItem.key.size > 0 && source.indexForKey(firstItem.key) == firstVisible) {
                anchorKeyValue = firstItem.key
                variableAnchorIndexValue = firstVisible
                let firstOffset = variableOffsetForIndex(count, firstVisible, estimate, gap)
                anchorIntraRowOffsetValue = if (scrollOffsetValue > firstOffset) {
                    scrollOffsetValue - firstOffset
                } else {
                    0
                }
            } else {
                anchorKeyValue = ""
                anchorIntraRowOffsetValue = 0
                if (firstItem.key.size == 0 && lastDataIssueValue.size == 0) {
                    lastDataIssueValue = "missing_key"
                }
            }
        }
        hasPendingUserScroll = false
        // Reserve the visible interval before accepting any overscan. A large
        // caller request must never let a prefix buffer consume the row cap
        // or be appended after the cap was already enforced.
        var visibleEnd = firstVisible
        let visibleEndOffset = scrollOffsetValue.saturatingAdd(viewport)
        while (visibleEnd < count && visibleEnd - firstVisible < CJGUI_COMPOSABLE_UI_MAX_VIRTUAL_MATERIALIZED_ROWS &&
                variableOffsetForIndex(count, visibleEnd, estimate, gap) < visibleEndOffset) {
            visibleEnd += 1
        }
        if (visibleEnd <= firstVisible) {
            visibleEnd = firstVisible + 1
        }
        let visibleRows = visibleEnd - firstVisible
        let remainingBudget = if (CJGUI_COMPOSABLE_UI_MAX_VIRTUAL_MATERIALIZED_ROWS > visibleRows) {
            CJGUI_COMPOSABLE_UI_MAX_VIRTUAL_MATERIALIZED_ROWS - visibleRows
        } else {
            0
        }
        // The variable path deliberately keeps the bounded buffer after the
        // visible interval. Before-viewport estimates may collapse after
        // measurement; reserving them would force a second, different range
        // in the same pass and defeat row reuse. Fixed-height lists preserve
        // their historical symmetric buffer independently.
        let afterBuffer = if (buffer < remainingBudget) {
            buffer
        } else {
            remainingBudget
        }
        materializedStartValue = firstVisible
        let endWithBuffer = visibleEnd.saturatingAdd(afterBuffer)
        materializedEndValue = if (endWithBuffer < count) {
            endWithBuffer
        } else {
            count
        }
        variableMaterializedOriginValue = variableOffsetForIndex(count, materializedStartValue, estimate, gap)
        return totalHeight
    }

    /// The variable materializer may add one ordinary row at a time when a
    /// tall estimate turns out to be short. This is a fixed projection
    /// budget, not another source traversal or an unbounded layout loop.
    func extendVariableMaterializedEnd(count: Int64): Bool {
        let safeCount = normalizedCount(count)
        if (materializedEndValue < materializedStartValue) {
            materializedEndValue = materializedStartValue
        }
        if (materializedEndValue >= safeCount || materializedEndValue - materializedStartValue >=
            CJGUI_COMPOSABLE_UI_MAX_VIRTUAL_MATERIALIZED_ROWS) {
            return false
        }
        materializedEndValue += 1
        return true
    }

    /// The materializer calls this only after building an ordinary visible
    /// subtree and asking the existing text/layout measurer for its height.
    func recordVariableMeasurement(item: CjguiComposableUiVariableHeightListItem, height: Int64, index: Int64): Unit {
        if (item.key.size == 0) {
            return
        }
        let resolved = if (height > 0) {
            height
        } else {
            variableEstimateForItem(item, variableEstimatedHeightValue)
        }
        let cacheIndex = variableCacheIndexForKey(item.key)
        if (cacheIndex >= 0) {
            let entry = variableHeightCache[cacheIndex]
            entry.title = item.title
            entry.layoutRevision = item.layoutRevision
            entry.resolvedHeight = resolved
            entry.measured = true
            entry.liveIndex = index
            return
        }
        if (variableHeightCache.size >= 128) {
            let _ = variableHeightCache.remove(at: 0)
        }
        variableHeightCache.add(
            CjguiComposableUiVariableHeightCacheEntry(
                item.key,
                item.title,
                item.layoutRevision,
                resolved,
                true,
                index
            )
        )
    }

    private func variableTotalHeight(count: Int64, estimate: Int64, gap: Int64): Int64 {
        if (count <= 0) {
            return 0
        }
        var total = estimate.saturatingMul(count).saturatingAdd(gap.saturatingMul(count - 1))
        for (entry in variableHeightCache) {
            if (entry.liveIndex >= 0 && entry.liveIndex < count) {
                total = total.saturatingAdd(entry.resolvedHeight - estimate)
            }
        }
        return if (total > 0) {
            total
        } else {
            0
        }
    }

    private func variableOffsetForIndex(count: Int64, requestedIndex: Int64, estimate: Int64, gap: Int64): Int64 {
        let index = if (requestedIndex < 0) {
            0
        } else if (requestedIndex > count) {
            count
        } else {
            requestedIndex
        }
        var offset = index.saturatingMul(estimate.saturatingAdd(gap))
        for (entry in variableHeightCache) {
            if (entry.liveIndex >= 0 && entry.liveIndex < index) {
                offset = offset.saturatingAdd(entry.resolvedHeight - estimate)
            }
        }
        return if (offset > 0) {
            offset
        } else {
            0
        }
    }

    private func variableIndexForOffset(count: Int64, requestedOffset: Int64, estimate: Int64, gap: Int64): Int64 {
        if (count <= 1 || requestedOffset <= 0) {
            return 0
        }
        var low: Int64 = 0;
        var high = count
        while (low + 1 < high) {
            let middle = low + (high - low) / 2
            if (variableOffsetForIndex(count, middle, estimate, gap) <= requestedOffset) {
                low = middle
            } else {
                high = middle
            }
        }
        return low
    }

    private func variableHeightAtIndex(index: Int64, estimate: Int64): Int64 {
        for (entry in variableHeightCache) {
            if (entry.liveIndex == index) {
                return entry.resolvedHeight
            }
        }
        return estimate
    }

    private func variableEstimateForItem(item: CjguiComposableUiVariableHeightListItem, fallback: Int64): Int64 {
        return if (item.estimatedHeight > 0) {
            item.estimatedHeight
        } else {
            if (fallback > 0) {
                fallback
            } else {
                1
            }
        }
    }

    private func variableCacheIndexForKey(key: String): Int64 {
        var index: Int64 = 0
        while (index < variableHeightCache.size) {
            if (variableHeightCache[index].key == key) {
                return index
            }
            index += 1
        }
        return -1
    }

    private func liveVariableIndexForKey(source: CjguiComposableUiVariableHeightListSource, count: Int64, key: String): Int64 {
        let index = source.indexForKey(key)
        if (index < 0 || index >= count) {
            return -1
        }
        return if (source.itemAt(index).key == key) {
            index
        } else {
            -1
        }
    }

    private func normalizedCount(value: Int64): Int64 {
        return if (value > 0) {
            value
        } else {
            0
        }
    }
    private func liveIndexForKey(source: CjguiComposableUiVirtualListSource, count: Int64, key: String): Int64 {
        let index = source.indexForKey(key)
        if (index < 0 || index >= count) {
            return -1
        }
        return if (source.itemAt(index).key == key) {
            index
        } else {
            -1
        }
    }
    private func maxValue(left: Int64, right: Int64): Int64 {
        return if (left > right) {
            left
        } else {
            right
        }
    }
    func noteDataIssue(issue: String): Unit {
        if (lastDataIssueValue.size == 0) {
            lastDataIssueValue = issue
        }
    }
}

/// A caller-owned, value-only component scope.  It is deliberately separate
/// from a business resource, semantic label or window session: those values
/// retain their existing ownership while this scope names one reusable UI
/// instance below a single window build context.
public class CjguiComposableUiIdentityScope {
    private let canonicalPathValue: String
    private let diagnosticPathValue: String
    private let validValue: Bool

    public init(scopeKey: String) {
        this.canonicalPathValue = segmentFor(scopeKey)
        this.diagnosticPathValue = scopeKey
        this.validValue = validSegment(scopeKey)
    }

    private init(canonicalPath: String, diagnosticPath: String, valid: Bool) {
        this.canonicalPathValue = canonicalPath
        this.diagnosticPathValue = diagnosticPath
        this.validValue = valid
    }

    /// A child may reuse every local key from its siblings without relying on
    /// construction order or a caller-reserved numeric range.
    public func child(localKey: String): CjguiComposableUiIdentityScope {
        let childValid = validValue && validSegment(localKey) && canonicalPathValue.size + localKey.size + 8 <= 256
        return CjguiComposableUiIdentityScope(
            "${canonicalPathValue}/${segmentFor(localKey)}",
            if (diagnosticPathValue.size > 0) {
                "${diagnosticPathValue}--${localKey}"
            } else {
                localKey
            },
            childValid
        )
    }

    public func local(localKey: String): CjguiComposableUiIdentity {
        return CjguiComposableUiIdentity(this, localKey)
    }

    func canonicalPath(): String {
        return canonicalPathValue
    }
    func diagnosticPath(): String {
        return diagnosticPathValue
    }
    func isValid(): Bool {
        return validValue
    }

    static func validSegment(value: String): Bool {
        if (value.size == 0 || value.size > 96 || !value.isAscii()) {
            return false
        }
        for (byte in value) {
            let isLetter = (byte >= b'a' && byte <= b'z') || (byte >= b'A' && byte <= b'Z')
            let isDigit = byte >= b'0' && byte <= b'9'
            if (!isLetter && !isDigit && byte != b'_' && byte != b'-') {
                return false
            }
        }
        return true
    }

    private static func segmentFor(value: String): String {
        return "${value.size}:${value}"
    }
}

/// A local identity is pure Cangjie data. It cannot carry a native object or
/// select a domain resource; the window registry resolves it only while a
/// candidate component tree is being assembled.
public class CjguiComposableUiIdentity {
    private let scopeValue: CjguiComposableUiIdentityScope
    private let localKeyValue: String

    public init(scope: CjguiComposableUiIdentityScope, localKey: String) {
        this.scopeValue = scope
        this.localKeyValue = localKey
    }

    func canonicalKey(): String {
        return "${scopeValue.canonicalPath()}/${localKeyValue.size}:${localKeyValue}"
    }

    func diagnosticKey(): String {
        return if (scopeValue.diagnosticPath().size > 0) {
            "${scopeValue.diagnosticPath()}--${localKeyValue}"
        } else {
            localKeyValue
        }
    }

    func diagnosticScope(): String {
        return scopeValue.diagnosticPath()
    }
    func localKey(): String {
        return localKeyValue
    }

    func isValid(): Bool {
        return scopeValue.isValid() && CjguiComposableUiIdentityScope.validSegment(localKeyValue) &&
            canonicalKey().size <= 384
    }
}

/// A value-only declaration that names a component node within the current
/// window candidate. It deliberately accepts either an existing manual node
/// ID or the same scope/key vocabulary used by reusable components; it never
/// carries a native handle, a window lookup table, or business ownership.
public class CjguiComposableUiNodeReference {
    private let manualNodeIdValue: Int64
    private let scopedIdentityValue: ?CjguiComposableUiIdentity

    private init(manualNodeId: Int64, scopedIdentity: ?CjguiComposableUiIdentity) {
        this.manualNodeIdValue = manualNodeId
        this.scopedIdentityValue = scopedIdentity
    }

    public static func manual(nodeId: Int64): CjguiComposableUiNodeReference {
        return CjguiComposableUiNodeReference(nodeId, None)
    }

    public static func scoped(scope: CjguiComposableUiIdentityScope, localKey: String): CjguiComposableUiNodeReference {
        return CjguiComposableUiNodeReference(-1, Some(scope.local(localKey)))
    }

    func manualNodeId(): Int64 {
        return manualNodeIdValue
    }

    func scopedIdentity(): ?CjguiComposableUiIdentity {
        return scopedIdentityValue
    }

    func isValid(): Bool {
        if (let Some(identity) <- scopedIdentityValue) {
            return identity.isValid()
        }
        return manualNodeIdValue >= 0
    }

    func missingIssue(): String {
        if (let Some(identity) <- scopedIdentityValue) {
            if (identity.isValid()) {
                return "identity_reference_missing_scope_${identity.diagnosticScope()}_key_${identity.localKey()}"
            }
        }
        return "identity_reference_invalid"
    }
}

/// One presentation style run of a text node: a UTF-8 display byte range plus the
/// attributes the renderer applies over it. Runs are flat and non-overlapping:
/// the product composes nesting before sending them, so no overlapping layers
/// ever reach the renderer.
public class CjguiComposableUiTextStyleRun {
    public let start: Int64
    public let end: Int64
    public let fontSize: Float64
    public let fontWeight: Int64
    public let fontFamily: String
    public let red: Float64
    public let green: Float64
    public let blue: Float64
    public let alpha: Float64
    /// Optional background for this run (inline code). `hasBackground` separates
    /// "no background" from "fully transparent".
    public let hasBackground: Bool
    public let backgroundRed: Float64
    public let backgroundGreen: Float64
    public let backgroundBlue: Float64
    public let backgroundAlpha: Float64

    public init(start: Int64, end: Int64, fontSize: Float64, fontWeight: Int64,
        fontFamily: String, red: Float64, green: Float64, blue: Float64, alpha: Float64,
        hasBackground!: Bool = false, backgroundRed!: Float64 = 0.0, backgroundGreen!: Float64 = 0.0,
        backgroundBlue!: Float64 = 0.0, backgroundAlpha!: Float64 = 1.0) {
        this.start = start
        this.end = end
        this.fontSize = fontSize
        this.fontWeight = fontWeight
        this.fontFamily = fontFamily
        this.red = red
        this.green = green
        this.blue = blue
        this.alpha = alpha
        this.hasBackground = hasBackground
        this.backgroundRed = backgroundRed
        this.backgroundGreen = backgroundGreen
        this.backgroundBlue = backgroundBlue
        this.backgroundAlpha = backgroundAlpha
    }

    /// The wire form the renderer accepts: one run per `;`, fields separated by
    /// `:` as start:end:fontSize:weight:family:r:g:b:a.
    public func encoded(): String {
        let family = if (this.fontFamily == "monospaced") {
            1u32
        } else if (this.fontFamily == "system-italic") {
            2u32
        } else if (this.fontFamily == "monospaced-italic") {
            3u32
        } else {
            0u32
        }
        let background = if (this.hasBackground) {
            1
        } else {
            0
        }
        return "${this.start}:${this.end}:${this.fontSize}:${this.fontWeight}:${family}:" +
            "${this.red}:${this.green}:${this.blue}:${this.alpha}:${background}:" +
            "${this.backgroundRed}:${this.backgroundGreen}:${this.backgroundBlue}:${this.backgroundAlpha}"
    }
}

/// One Cangjie-owned component declaration.  `resourceId` and `actionName`
/// form a common-operation semantic relation; neither is interpreted by this
/// framework as a business command.
public class CjguiComposableUiNode {
    public var nodeId: Int64
    public let semanticId: String
    public let nodeKind: Int64
    public let label: String
    public var value: String
    public let actionName: String
    public let resourceId: Int64
    /// Author-owned binding incarnation. Equal labels and keys may still name
    /// a newly mounted action or editor after a generated replacement.
    public var semanticIncarnation: Int64
    /// An application-declared domain field. It is absent for purely visual
    /// nodes and controls that invoke an action without editing a field.
    public let fieldId: String
    /// The externally discoverable business action, intentionally separate
    /// from the controller-local UI branch name.
    public let operationActionName: String
    /// The business resource targeted by the declared field/action. It may
    /// differ from `resourceId` when a controller uses a stable local field
    /// slot while editing the currently selected business record.
    public let operationResourceId: Int64
    /// Explicit state role for a projected field value. It is never inferred
    /// from semantic/control names: normal editors declare `draft`, summaries
    /// declare `applied`, and unrelated visual text leaves it empty.
    public let displayValueRole: String
    /// A package-local raster path used only by the generic image component.
    /// The native side copies it, decodes it into a private Metal texture and
    /// never returns an NSImage/texture handle across this boundary.
    public let imageResourcePath: String
    /// Stable Cangjie-owned identity for a local raster resource. It is not a
    /// native handle: incrementing `imageResourceVersion` explicitly replaces
    /// same-path content without inventing a new business object.
    public let imageResourceId: String
    public let imageResourceVersion: Int64
    public let imageContentMode: Int64
    public let style: CjguiComposableUiStyle
    /// Optional presentation style runs for this node. Empty means "use the
    /// single `style` exactly as before", so no existing consumer changes.
    public let textStyleRuns: Array<CjguiComposableUiTextStyleRun>
    /// Paint-only state declarations live with the Cangjie component. Native
    /// receives only the resolved style of one accepted scene generation.
    public let interactionStyle: CjguiComposableUiInteractionStyle
    /// The application owns only selected/checked data. Hover, pressed,
    /// focus and disabled are derived by the framework at projection time.
    public let ownerInteractionState: Int64
    /// Enabled controls can receive UI intents. Read-only applies only to
    /// editable field kinds and is distinct from invisible/absent nodes.
    public let isEnabled: Bool
    public let isReadOnly: Bool
    /// Multi-line editors navigate by Tab by default. Applications that need
    /// literal indentation opt in explicitly for that individual editor.
    public let tabInsertsText: Bool
    /// Pointer-control metadata is declarative and copied into the resolved
    /// scene. It contains no capture/session state and no business value
    /// owner; consumers route updates through their existing owner path.
    public let pointerControlRole: String
    public let pointerControlAxis: Int64
    public let pointerControlMinimum: Int64
    public let pointerControlMaximum: Int64
    public let pointerControlStep: Int64
    public let pointerControlHandleThickness: Int64
    public let pointerControlFirstSize: Int64
    public let pointerControlSecondMinimum: Int64
    public var scrollOffset: Int64
    /// The public vertical viewport a `SCROLL` area shares with its author. It
    /// is an ordinary Cangjie object with no native handle, and `None` keeps the
    /// plain value-based scroll area unchanged.
    public let scrollViewport: ?CjguiComposableUiScrollViewport
    /// The shared view state of a generated split instance, kept for the same
    /// reason as the viewport: the framework's single size rule updates it.
    public let splitState: ?CjguiComposableUiSplitState
    /// The tab container's shared view state, when this node IS a tab container.
    public let tabsState: ?CjguiComposableUiTabsState
    /// The stable page key when this node is one PAGE of a tab container (empty
    /// otherwise). A hidden page keeps its key, so its identity and its own view
    /// state can be restored without being part of the active scene.
    public let tabsPageKey: String
    /// True when this page is the container's ACTIVE page in the declared tree.
    /// The layout only measures, hit-tests and draws active pages.
    public let tabsPageActive: Bool
    /// Height of the title row of a tab container, in logical points.
    public let tabsTitleHeight: Int64
    // Virtual-list metadata stays wholly in the Cangjie layout layer. The
    // renderer sees only rows materialized for the current range, never this
    // source or a logical collection's full contents.
    private let virtualListSourceValue: ?CjguiComposableUiVirtualListSource
    private let variableHeightListSourceValue: ?CjguiComposableUiVariableHeightListSource
    private let virtualListStateValue: ?CjguiComposableUiVirtualListState
    private let virtualListContentNodeIdValue: Int64
    private let virtualListRowHeightValue: Int64
    private let virtualListRowGapValue: Int64
    private let virtualListOverscanValue: Int64
    private let virtualContentHeightValue: Int64
    private let virtualVerticalOriginValue: Int64
    // Layer metadata remains entirely in Cangjie. `layerId` is a stable
    // identity, while `layerKind` is a descriptive projection value rather
    // than a native menu/dialog switch.
    private let layerIdValue: String
    private let layerKindValue: String
    private let layerOwnerSemanticIdValue: String
    private let layerAnchorSemanticIdValue: String
    private var layerAnchorNodeIdValue: Int64
    private let layerAnchorReferenceValue: ?CjguiComposableUiNodeReference
    private let layerIsModalValue: Bool
    private var layerInitialFocusNodeIdValue: Int64
    private let layerInitialFocusReferenceValue: ?CjguiComposableUiNodeReference
    // A component instance may establish an ordinary Cangjie focus domain
    // without pretending to be a native menu or modal layer.
    private let explicitInputScopeIdValue: String
    /// Optional, caller-owned revision for an entire stable layout region.
    /// An empty value uses the engine's complete structural signature. A
    /// non-empty value is an explicit contract that it changes whenever any
    /// descendant layout, semantic, clip or input output could change.
    private let layoutReuseKeyValue: String
    // Scoped declarations are resolved by the owning window's candidate
    // registry. Manual nodes keep this empty and retain their public numeric
    // identity exactly as before.
    private let scopedIdentityValue: ?CjguiComposableUiIdentity
    private var layoutHeightOverrideValue: Int64
    private let childNodes: ArrayList<CjguiComposableUiNode>

    public init(nodeId: Int64, semanticId: String, nodeKind: Int64, label: String, value: String, actionName: String,
        resourceId: Int64, style: CjguiComposableUiStyle, scrollOffset!: Int64 = 0,
        scrollViewport!: ?CjguiComposableUiScrollViewport = None,
        splitState!: ?CjguiComposableUiSplitState = None, enabled!: Bool = true,
        tabsState!: ?CjguiComposableUiTabsState = None, tabsPageKey!: String = "", tabsPageActive!: Bool = false,
        tabsTitleHeight!: Int64 = 0,
        textStyleRuns!: Array<CjguiComposableUiTextStyleRun> = Array<CjguiComposableUiTextStyleRun>(),
        readOnly!: Bool = false, fieldId!: String = "", operationActionName!: String = "",
        operationResourceId!: Int64 = -1, displayValueRole!: String = "", imageResourcePath!: String = "",
        imageResourceId!: String = "", imageResourceVersion!: Int64 = 0, imageContentMode!: Int64 = 1,
        tabInsertsText!: Bool = false, virtualListSource!: ?CjguiComposableUiVirtualListSource = None,
        variableHeightListSource!: ?CjguiComposableUiVariableHeightListSource = None,
        virtualListState!: ?CjguiComposableUiVirtualListState = None, virtualListContentNodeId!: Int64 = -1,
        virtualListRowHeight!: Int64 = 0, virtualListRowGap!: Int64 = 0, virtualListOverscan!: Int64 = 0,
        virtualContentHeight!: Int64 = 0, virtualVerticalOrigin!: Int64 = 0, layerId!: String = "",
        layerKind!: String = "", layerOwnerSemanticId!: String = "", layerAnchorSemanticId!: String = "",
        layerAnchorNodeId!: Int64 = -1, layerAnchorReference!: ?CjguiComposableUiNodeReference = None,
        layerIsModal!: Bool = false, layerInitialFocusNodeId!: Int64 = -1,
        layerInitialFocusReference!: ?CjguiComposableUiNodeReference = None,
        layoutHeightOverride!: Int64 = 0, inputScopeId!: String = "", layoutReuseKey!: String = "",
        pointerControlRole!: String = "", pointerControlAxis!: Int64 = CjguiComposableUiSplitAxis.HORIZONTAL,
        pointerControlMinimum!: Int64 = 0, pointerControlMaximum!: Int64 = 0, pointerControlStep!: Int64 = 1,
        pointerControlHandleThickness!: Int64 = 8, pointerControlFirstSize!: Int64 = 0,
        pointerControlSecondMinimum!: Int64 = 0,
        interactionStyle!: CjguiComposableUiInteractionStyle = CjguiComposableUiInteractionStyle(),
        ownerInteractionState!: Int64 = CjguiComposableUiInteractionState.NONE,
        semanticIncarnation!: Int64 = 0,
        identity!: ?CjguiComposableUiIdentity = None) {
        this.nodeId = nodeId
        this.semanticId = semanticId
        this.nodeKind = nodeKind
        this.label = label
        this.value = value
        this.actionName = actionName
        this.resourceId = resourceId
        this.semanticIncarnation = semanticIncarnation
        this.fieldId = fieldId
        this.operationActionName = operationActionName
        this.operationResourceId = operationResourceId
        this.displayValueRole = displayValueRole
        this.imageResourcePath = imageResourcePath
        this.imageResourceId = if (imageResourceId.size > 0) {
            imageResourceId
        } else {
            imageResourcePath
        }
        this.imageResourceVersion = if (imageResourceVersion < 0) {
            0
        } else {
            imageResourceVersion
        }
        this.imageContentMode = if (imageContentMode == 2) {
            2
        } else {
            1
        }
        this.style = style
        this.textStyleRuns = textStyleRuns
        this.interactionStyle = interactionStyle
        this.ownerInteractionState = CjguiComposableUiInteractionState.ownerBits(ownerInteractionState)
        this.scrollOffset = if (scrollOffset < 0) {
            0
        } else {
            scrollOffset
        }
        this.scrollViewport = scrollViewport
        this.splitState = splitState
        this.tabsState = tabsState
        this.tabsPageKey = tabsPageKey
        this.tabsPageActive = tabsPageActive
        this.tabsTitleHeight = if (tabsTitleHeight > 0) {
            tabsTitleHeight
        } else {
            0
        }
        this.isEnabled = enabled
        this.isReadOnly = readOnly && (nodeKind == CJGUI_COMPOSABLE_UI_TEXT_INPUT || nodeKind ==
            CJGUI_COMPOSABLE_UI_INTEGER_INPUT || nodeKind == CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT)
        this.tabInsertsText = tabInsertsText && nodeKind == CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT
        this.pointerControlRole = pointerControlRole
        this.pointerControlAxis = if (pointerControlAxis == CjguiComposableUiSplitAxis.VERTICAL) {
            CjguiComposableUiSplitAxis.VERTICAL
        } else {
            CjguiComposableUiSplitAxis.HORIZONTAL
        }
        this.pointerControlMinimum = pointerControlMinimum
        this.pointerControlMaximum = pointerControlMaximum
        this.pointerControlStep = if (pointerControlStep > 0) {
            pointerControlStep
        } else {
            1
        }
        this.pointerControlHandleThickness = if (pointerControlHandleThickness > 0) {
            pointerControlHandleThickness
        } else {
            1
        }
        this.pointerControlFirstSize = if (pointerControlFirstSize > 0) {
            pointerControlFirstSize
        } else {
            0
        }
        this.pointerControlSecondMinimum = if (pointerControlSecondMinimum > 0) {
            pointerControlSecondMinimum
        } else {
            0
        }
        this.virtualListSourceValue = if (nodeKind == CJGUI_COMPOSABLE_UI_SCROLL_AREA) {
            virtualListSource
        } else {
            None
        }
        this.variableHeightListSourceValue = if (nodeKind == CJGUI_COMPOSABLE_UI_SCROLL_AREA) {
            variableHeightListSource
        } else {
            None
        }
        this.virtualListStateValue = if (nodeKind == CJGUI_COMPOSABLE_UI_SCROLL_AREA) {
            virtualListState
        } else {
            None
        }
        this.virtualListContentNodeIdValue = virtualListContentNodeId
        this.virtualListRowHeightValue = if (virtualListRowHeight > 0) {
            virtualListRowHeight
        } else {
            1
        }
        this.virtualListRowGapValue = if (virtualListRowGap > 0) {
            virtualListRowGap
        } else {
            0
        }
        this.virtualListOverscanValue = if (virtualListOverscan > 0) {
            virtualListOverscan
        } else {
            0
        }
        this.virtualContentHeightValue = if (virtualContentHeight > 0) {
            virtualContentHeight
        } else {
            0
        }
        this.virtualVerticalOriginValue = if (virtualVerticalOrigin > 0) {
            virtualVerticalOrigin
        } else {
            0
        }
        this.layerIdValue = layerId
        this.layerKindValue = if (layerKind == "menu" || layerKind == "popup" || layerKind == "dialog") {
            layerKind
        } else {
            ""
        }
        this.layerOwnerSemanticIdValue = layerOwnerSemanticId
        this.layerAnchorSemanticIdValue = layerAnchorSemanticId
        this.layerAnchorNodeIdValue = layerAnchorNodeId
        this.layerAnchorReferenceValue = layerAnchorReference
        this.layerIsModalValue = layerIsModal && this.layerKindValue == "dialog"
        this.layerInitialFocusNodeIdValue = layerInitialFocusNodeId
        this.layerInitialFocusReferenceValue = layerInitialFocusReference
        this.explicitInputScopeIdValue = inputScopeId
        this.layoutReuseKeyValue = layoutReuseKey
        this.scopedIdentityValue = identity
        this.layoutHeightOverrideValue = if (layoutHeightOverride > 0) {
            layoutHeightOverride
        } else {
            0
        }
        this.childNodes = ArrayList<CjguiComposableUiNode>()
    }
    public func add(child: CjguiComposableUiNode) {
        childNodes.add(child)
    }
    public func children(): ArrayList<CjguiComposableUiNode> {
        return ArrayList<CjguiComposableUiNode>(childNodes)
    }
    /// Package consumers normally compose by `add`; the layout engine alone
    /// replaces a virtual list's transient materialized child range.
    func replaceChildren(children: ArrayList<CjguiComposableUiNode>) {
        childNodes.clear()
        childNodes.add(all: children)
    }
    func virtualListSource(): ?CjguiComposableUiVirtualListSource {
        return virtualListSourceValue
    }
    func variableHeightListSource(): ?CjguiComposableUiVariableHeightListSource {
        return variableHeightListSourceValue
    }
    func virtualListState(): ?CjguiComposableUiVirtualListState {
        return virtualListStateValue
    }
    func virtualListContentNodeId(): Int64 {
        return virtualListContentNodeIdValue
    }
    func virtualListRowHeight(): Int64 {
        return virtualListRowHeightValue
    }
    func virtualListRowGap(): Int64 {
        return virtualListRowGapValue
    }
    func virtualListOverscan(): Int64 {
        return virtualListOverscanValue
    }
    func virtualContentHeight(): Int64 {
        return virtualContentHeightValue
    }
    func virtualVerticalOrigin(): Int64 {
        return virtualVerticalOriginValue
    }
    public func layerId(): String {
        return layerIdValue
    }
    public func layerKind(): String {
        return layerKindValue
    }
    public func layerOwnerSemanticId(): String {
        return layerOwnerSemanticIdValue
    }
    public func layerAnchorSemanticId(): String {
        return layerAnchorSemanticIdValue
    }
    public func layerAnchorNodeId(): Int64 {
        return layerAnchorNodeIdValue
    }
    func layerAnchorReference(): ?CjguiComposableUiNodeReference {
        return layerAnchorReferenceValue
    }
    func resolveLayerAnchorNodeId(nodeId: Int64): Unit {
        layerAnchorNodeIdValue = nodeId
    }
    public func layerIsModal(): Bool {
        return layerIsModalValue
    }
    public func layerInitialFocusNodeId(): Int64 {
        return layerInitialFocusNodeIdValue
    }
    func layerInitialFocusReference(): ?CjguiComposableUiNodeReference {
        return layerInitialFocusReferenceValue
    }
    func resolveLayerInitialFocusNodeId(nodeId: Int64): Unit {
        layerInitialFocusNodeIdValue = nodeId
    }
    public func explicitInputScopeId(): String {
        return explicitInputScopeIdValue
    }
    public func isSplitView(): Bool {
        return pointerControlRole == "split_view"
    }
    /// Whether this node is the container of a public tab component.
    public func isTabsContainer(): Bool {
        return nodeKind == CJGUI_COMPOSABLE_UI_TABS
    }
    /// Whether this node is one PAGE of a tab container.
    public func isTabPage(): Bool {
        return tabsPageKey.size > 0
    }
    /// Whether this node is a tab TITLE.
    public func isTabTitle(): Bool {
        return nodeKind == CJGUI_COMPOSABLE_UI_TAB_TITLE
    }
    func scopedIdentity(): ?CjguiComposableUiIdentity {
        return scopedIdentityValue
    }
    func hasUnresolvedScopedIdentity(): Bool {
        if (let Some(_) <- scopedIdentityValue) {
            return nodeId < 0
        }
        return false
    }
    public func splitAxis(): Int64 {
        return pointerControlAxis
    }
    public func splitFirstSize(): Int64 {
        return pointerControlFirstSize
    }
    public func splitMinFirst(): Int64 {
        return pointerControlMinimum
    }
    public func splitMinSecond(): Int64 {
        return pointerControlSecondMinimum
    }
    public func splitHandleThickness(): Int64 {
        return pointerControlHandleThickness
    }
    /// Experimental opt-in for a bounded derived layout cache. It is never a
    /// domain revision owner and does not permit object-identity reuse.
    public func layoutReuseKey(): String {
        return layoutReuseKeyValue
    }
    func layoutHeightOverride(): Int64 {
        return layoutHeightOverrideValue
    }
    /// Layout-only constraint installed by a virtual list after a source has
    /// built its ordinary row. It preserves the row's subtree and semantics.
    func forceLayoutHeight(height: Int64): Unit {
        layoutHeightOverrideValue = if (height > 0) {
            height
        } else {
            1
        }
    }

    /// A window accepts its own snapshot of a caller declaration. Identity
    /// resolution may write transient numeric IDs and virtual layout replaces
    /// visible children; retaining the caller's object would let another
    /// window rewrite an already-accepted public projection. Sources and
    /// their domain-owned list state remain references, while transient
    /// materialised rows are rebuilt only for this candidate.
    func cloneForWindowCandidate(): CjguiComposableUiNode {
        let cloned = CjguiComposableUiNode(nodeId, semanticId, nodeKind, label, value, actionName, resourceId, style,
            // The window snapshots the declaration; presentation runs are part of
            // the declaration and must survive the snapshot, otherwise every
            // accepted node silently loses its inline styles.
            textStyleRuns: textStyleRuns,
            scrollOffset: scrollOffset, scrollViewport: scrollViewport, splitState: splitState,
            tabsState: tabsState, tabsPageKey: tabsPageKey, tabsPageActive: tabsPageActive,
            tabsTitleHeight: tabsTitleHeight,
            enabled: isEnabled, readOnly: isReadOnly,
            fieldId: fieldId,
            operationActionName: operationActionName, operationResourceId: operationResourceId,
            displayValueRole: displayValueRole, imageResourcePath: imageResourcePath, imageResourceId: imageResourceId,
            imageResourceVersion: imageResourceVersion, imageContentMode: imageContentMode,
            tabInsertsText: tabInsertsText, virtualListSource: virtualListSourceValue,
            variableHeightListSource: variableHeightListSourceValue, virtualListState: virtualListStateValue,
            virtualListContentNodeId: virtualListContentNodeIdValue, virtualListRowHeight: virtualListRowHeightValue,
            virtualListRowGap: virtualListRowGapValue, virtualListOverscan: virtualListOverscanValue,
            virtualContentHeight: virtualContentHeightValue, virtualVerticalOrigin: virtualVerticalOriginValue,
            layerId: layerIdValue, layerKind: layerKindValue, layerOwnerSemanticId: layerOwnerSemanticIdValue,
            layerAnchorSemanticId: layerAnchorSemanticIdValue, layerAnchorNodeId: layerAnchorNodeIdValue,
            layerAnchorReference: layerAnchorReferenceValue, layerIsModal: layerIsModalValue,
            layerInitialFocusNodeId: layerInitialFocusNodeIdValue,
            layerInitialFocusReference: layerInitialFocusReferenceValue, layoutHeightOverride: layoutHeightOverrideValue,
            inputScopeId: explicitInputScopeIdValue, layoutReuseKey: layoutReuseKeyValue,
            pointerControlRole: pointerControlRole, pointerControlAxis: pointerControlAxis,
            pointerControlMinimum: pointerControlMinimum, pointerControlMaximum: pointerControlMaximum,
            pointerControlStep: pointerControlStep, pointerControlHandleThickness: pointerControlHandleThickness,
            pointerControlFirstSize: pointerControlFirstSize, pointerControlSecondMinimum: pointerControlSecondMinimum,
            interactionStyle: interactionStyle, ownerInteractionState: ownerInteractionState,
            semanticIncarnation: semanticIncarnation,
            identity: scopedIdentityValue)
        var ownsVirtualChildren = false
        if (let Some(_) <- virtualListSourceValue) { ownsVirtualChildren = true }
        if (let Some(_) <- variableHeightListSourceValue) { ownsVirtualChildren = true }
        if (!ownsVirtualChildren) {
            for (child in childNodes) {
                cloned.add(child.cloneForWindowCandidate())
            }
        }
        return cloned
    }
}

private class CjguiComposableUiIdentityEntry {
    let canonicalKey: String
    let diagnosticKey: String
    let nodeId: Int64

    init(canonicalKey: String, diagnosticKey: String, nodeId: Int64) {
        this.canonicalKey = canonicalKey
        this.diagnosticKey = diagnosticKey
        this.nodeId = nodeId
    }
}

/// Per-window candidate registry for scoped component identities. The
/// accepted table is bounded by the native scene capacity; it contains only
/// identities in the live accepted tree, never a process-wide history. A
/// monotonic scalar generation supplies a fresh layout node ID when a removed
/// key later returns, while scene/projection generations continue to reject
/// delayed input from the removed declaration.
public class CjguiComposableUiIdentityRegistry {
    private static let firstScopedNodeId: Int64 = 8000000000000000000
    private static let maximumScopedIdentityCount: Int64 = 1024

    private let acceptedEntries: ArrayList<CjguiComposableUiIdentityEntry>
    private let acceptedByKey: HashMap<String, Int64>
    private let candidateEntries: ArrayList<CjguiComposableUiIdentityEntry>
    private let candidateByKey: HashMap<String, Int64>
    private let candidateManualNodeIds: HashMap<Int64, String>
    private var candidateRootValue: ?CjguiComposableUiNode
    private var nextScopedNodeIdValue: Int64
    private var candidateNextScopedNodeId: Int64
    private var candidateOpenValue: Bool
    private var candidateResolvedValue: Bool
    private var candidatePreparedValue: Bool
    private var issueValue: String

    public init() {
        this.acceptedEntries = ArrayList<CjguiComposableUiIdentityEntry>()
        this.acceptedByKey = HashMap<String, Int64>()
        this.candidateEntries = ArrayList<CjguiComposableUiIdentityEntry>()
        this.candidateByKey = HashMap<String, Int64>()
        this.candidateManualNodeIds = HashMap<Int64, String>()
        this.candidateRootValue = None
        this.nextScopedNodeIdValue = CjguiComposableUiIdentityRegistry.firstScopedNodeId
        this.candidateNextScopedNodeId = CjguiComposableUiIdentityRegistry.firstScopedNodeId
        this.candidateOpenValue = false
        this.candidateResolvedValue = false
        this.candidatePreparedValue = false
        this.issueValue = ""
    }

    /// Opens one candidate tree. All mapping mutation stays provisional until
    /// the window has accepted its Cangjie and native scene transaction.
    public func beginCandidate(): Bool {
        if (candidateOpenValue || candidatePreparedValue) {
            issueValue = "identity_candidate_already_open"
            return false
        }
        candidateEntries.clear()
        candidateByKey.clear()
        candidateManualNodeIds.clear()
        candidateRootValue = None
        candidateNextScopedNodeId = nextScopedNodeIdValue
        candidateOpenValue = true
        candidateResolvedValue = false
        issueValue = ""
        return true
    }

    /// Resolves every scoped declaration in the candidate root. Repeated
    /// local keys in one scope and manual/scoped numeric collisions fail with
    /// a precise scoped diagnostic before native staging can begin.
    public func resolveCandidate(root: CjguiComposableUiNode): String {
        if (!candidateOpenValue || candidateResolvedValue) {
            issueValue = "identity_candidate_not_open"
            return issueValue
        }
        candidateRootValue = Some(root)
        let _ = resolveNode(root, candidateManualNodeIds)
        validateManualCollisions()
        resolveAvailableReferences(root)
        candidateResolvedValue = true
        return issueValue
    }

    /// Variable-list rows are declared only after layout has narrowed the
    /// visible range. They join the same still-open candidate as the root;
    /// no screen-off row is constructed merely to obtain an identity.
    public func resolveDynamicNode(root: CjguiComposableUiNode): String {
        if (!candidateOpenValue || !candidateResolvedValue || candidatePreparedValue) {
            issueValue = "identity_dynamic_candidate_not_open"
            return issueValue
        }
        let _ = resolveNode(root, candidateManualNodeIds)
        validateManualCollisions()
        resolveAvailableReferences(root)
        return issueValue
    }

    /// Switch the candidate root to the window-owned declaration snapshot
    /// after its caller object has supplied any command IDs. The identity map
    /// remains the same transaction; only future dynamic materialisation and
    /// accepted projection ownership move to the isolated tree.
    public func replaceCandidateRoot(root: CjguiComposableUiNode): String {
        if (!candidateOpenValue || !candidateResolvedValue || candidatePreparedValue) {
            issueValue = "identity_candidate_root_replace_not_open"
            return issueValue
        }
        candidateRootValue = Some(root)
        resolveAvailableReferences(root)
        return issueValue
    }

    /// Materialisation may attach its row subtrees only after their bounded
    /// range is known. Revisit deferred root references then, without
    /// resolving identities a second time or constructing screen-off rows.
    public func resolveAvailableReferences(): String {
        if (!candidateOpenValue || !candidateResolvedValue || candidatePreparedValue) {
            issueValue = "identity_reference_candidate_not_open"
            return issueValue
        }
        if (let Some(root) <- candidateRootValue) {
            resolveAvailableReferences(root)
        } else {
            issueValue = "identity_reference_candidate_root_missing"
        }
        return issueValue
    }

    /// Completes the Cangjie-only candidate phase. The caller must follow a
    /// successful prepare with exactly one commit or rollback.
    public func prepareCandidate(): Bool {
        if (!candidateOpenValue || !candidateResolvedValue) {
            issueValue = "identity_candidate_not_resolved"
            return false
        }
        if (let Some(root) <- candidateRootValue) {
            resolveRequiredReferences(root)
        } else {
            issueValue = "identity_reference_candidate_root_missing"
        }
        candidateOpenValue = false
        candidatePreparedValue = issueValue.size == 0
        return candidatePreparedValue
    }

    /// Promotes only the current live candidate. Removed keys release their
    /// registry entry; their old scene identity remains protected by the
    /// existing projection-version and target checks, and a later rebuild
    /// receives a fresh generated node ID.
    public func commitCandidate(): Unit {
        if (!candidatePreparedValue) {
            issueValue = "identity_candidate_not_prepared"
            return
        }
        acceptedEntries.clear()
        acceptedByKey.clear()
        for (entry in candidateEntries) {
            acceptedByKey.add(entry.canonicalKey, acceptedEntries.size)
            acceptedEntries.add(entry)
        }
        nextScopedNodeIdValue = candidateNextScopedNodeId
        clearCandidate()
        issueValue = ""
    }

    /// Leaves the accepted mapping untouched. The unaccepted candidate has no
    /// native target and does not consume a generation.
    public func rollbackCandidate(): Unit {
        clearCandidate()
    }

    /// A closed window owns no live scoped declaration. Clear both accepted
    /// and candidate values so a reopened native session starts a new,
    /// independent identity generation.
    public func clear(): Unit {
        acceptedEntries.clear()
        acceptedByKey.clear()
        candidateEntries.clear()
        candidateByKey.clear()
        candidateManualNodeIds.clear()
        candidateRootValue = None
        nextScopedNodeIdValue = CjguiComposableUiIdentityRegistry.firstScopedNodeId
        candidateNextScopedNodeId = CjguiComposableUiIdentityRegistry.firstScopedNodeId
        candidateOpenValue = false
        candidateResolvedValue = false
        candidatePreparedValue = false
        issueValue = ""
    }

    public func liveCount(): Int64 {
        return acceptedEntries.size
    }
    public func candidateCount(): Int64 {
        return candidateEntries.size
    }

    /// Resolve a reference only while the current candidate is completely
    /// prepared.  Consumers such as command declarations use this after
    /// layout, before the candidate becomes visible, and must never cause a
    /// second identity-allocation pass merely to obtain a target node.
    func candidateNodeIdForReference(reference: CjguiComposableUiNodeReference): Int64 {
        if (!candidatePreparedValue || !reference.isValid()) {
            return -1
        }
        if (let Some(identity) <- reference.scopedIdentity()) {
            if (let Some(index) <- candidateByKey.get(identity.canonicalKey())) {
                return candidateEntries[index].nodeId
            }
            return -1
        }
        let manualNodeId = reference.manualNodeId()
        if (let Some(_) <- candidateManualNodeIds.get(manualNodeId)) {
            return manualNodeId
        }
        return -1
    }

    /// Resolve a reference against the accepted mapping.  This deliberately
    /// has no candidate fallback: delayed menu and shortcut callbacks may
    /// only address the generation currently owned by the accepted scene.
    func acceptedNodeIdForReference(reference: CjguiComposableUiNodeReference): Int64 {
        if (!reference.isValid()) {
            return -1
        }
        if (let Some(identity) <- reference.scopedIdentity()) {
            if (let Some(index) <- acceptedByKey.get(identity.canonicalKey())) {
                return acceptedEntries[index].nodeId
            }
            return -1
        }
        return reference.manualNodeId()
    }

    public func liveRetainedStringBytes(): Int64 {
        return retainedIdentityStringBytes(acceptedEntries)
    }
    public func candidateRetainedStringBytes(): Int64 {
        return retainedIdentityStringBytes(candidateEntries)
    }
    public func lastIssue(): String {
        return issueValue
    }

    private func retainedIdentityStringBytes(entries: ArrayList<CjguiComposableUiIdentityEntry>): Int64 {
        var total: Int64 = 0
        for (entry in entries) {
            total = total.saturatingAdd(entry.canonicalKey.size).saturatingAdd(entry.diagnosticKey.size)
        }
        return total
    }

    private func resolveNode(node: CjguiComposableUiNode, manualNodeIds: HashMap<Int64, String>): Bool {
        if (let Some(identity) <- node.scopedIdentity()) {
            if (!identity.isValid()) {
                issueValue = "identity_invalid_scope_or_key"
                return false
            }
            let canonicalKey = identity.canonicalKey()
            if (let Some(_) <- candidateByKey.get(canonicalKey)) {
                issueValue = identityIssue("identity_duplicate", identity)
                return false
            }
            // Candidate size, rather than just fresh allocation, is the
            // public upper bound. A new declaration may appear before 1,024
            // accepted keys, so reusing an old mapping cannot be allowed to
            // append the 1,025th candidate entry.
            if (candidateEntries.size >= CjguiComposableUiIdentityRegistry.maximumScopedIdentityCount) {
                issueValue = "identity_capacity_scope_key_${identity.diagnosticKey()}"
                return false
            }
            let nodeId = if (let Some(existingIndex) <- acceptedByKey.get(canonicalKey)) {
                acceptedEntries[existingIndex].nodeId
            } else {
                allocateCandidateNodeId(identity.diagnosticKey())
            }
            if (nodeId < 0) {
                return false
            }
            candidateByKey.add(canonicalKey, candidateEntries.size)
            candidateEntries.add(CjguiComposableUiIdentityEntry(canonicalKey, identity.diagnosticKey(), nodeId))
            node.nodeId = nodeId
        } else {
            // Preserve legacy numeric IDs unchanged. The later canonical
            // duplicate check still diagnoses two manual nodes exactly as it
            // did before scoped composition existed.
            if (node.nodeId >= 0) {
                let _ = manualNodeIds.add(node.nodeId, node.semanticId)
            }
        }
        for (child in node.children()) {
            if (!resolveNode(child, manualNodeIds)) {
                return false
            }
        }
        return true
    }

    private func allocateCandidateNodeId(diagnosticKey: String): Int64 {
        if (candidateEntries.size >= CjguiComposableUiIdentityRegistry.maximumScopedIdentityCount ||
            candidateNextScopedNodeId >= 8999999999999998976) {
            issueValue = "identity_capacity_scope_key_${diagnosticKey}"
            return -1
        }
        let allocated = candidateNextScopedNodeId
        candidateNextScopedNodeId += 1
        return allocated
    }

    private func validateManualCollisions(): Unit {
        if (issueValue.size > 0) {
            return
        }
        for (entry in candidateEntries) {
            if (let Some(_) <- candidateManualNodeIds.get(entry.nodeId)) {
                issueValue = "identity_manual_scope_key_${entry.diagnosticKey}"
                return
            }
        }
    }

    /// Resolve the references that are already present in the candidate. A
    /// root layer is allowed to name a visible virtual row that has not been
    /// built yet, so absence is deferred to `prepareCandidate`; malformed
    /// declarations still fail immediately and safely.
    private func resolveAvailableReferences(node: CjguiComposableUiNode): Unit {
        if (issueValue.size > 0) {
            return
        }
        if (let Some(reference) <- node.layerAnchorReference()) {
            let resolved = resolveReference(reference)
            if (issueValue.size > 0) {
                return
            }
            if (resolved >= 0) {
                node.resolveLayerAnchorNodeId(resolved)
            }
        }
        if (let Some(reference) <- node.layerInitialFocusReference()) {
            let resolved = resolveReference(reference)
            if (issueValue.size > 0) {
                return
            }
            if (resolved >= 0) {
                node.resolveLayerInitialFocusNodeId(resolved)
            }
        }
        for (child in node.children()) {
            resolveAvailableReferences(child)
            if (issueValue.size > 0) {
                return
            }
        }
    }

    /// The acceptance boundary is strict: a referenced declaration must be
    /// in this live candidate. There is no fallback to the previous scene,
    /// an arbitrary layout node, or a process-global identity table.
    private func resolveRequiredReferences(node: CjguiComposableUiNode): Unit {
        if (issueValue.size > 0) {
            return
        }
        if (let Some(reference) <- node.layerAnchorReference()) {
            let resolved = resolveReference(reference)
            if (issueValue.size > 0) {
                return
            }
            if (resolved < 0) {
                issueValue = reference.missingIssue()
                return
            }
            node.resolveLayerAnchorNodeId(resolved)
        }
        if (let Some(reference) <- node.layerInitialFocusReference()) {
            let resolved = resolveReference(reference)
            if (issueValue.size > 0) {
                return
            }
            if (resolved < 0) {
                issueValue = reference.missingIssue()
                return
            }
            node.resolveLayerInitialFocusNodeId(resolved)
        }
        for (child in node.children()) {
            resolveRequiredReferences(child)
            if (issueValue.size > 0) {
                return
            }
        }
    }

    private func resolveReference(reference: CjguiComposableUiNodeReference): Int64 {
        if (!reference.isValid()) {
            issueValue = "identity_reference_invalid"
            return -1
        }
        if (let Some(identity) <- reference.scopedIdentity()) {
            if (let Some(index) <- candidateByKey.get(identity.canonicalKey())) {
                return candidateEntries[index].nodeId
            }
            return -1
        }
        let manualNodeId = reference.manualNodeId()
        if (let Some(_) <- candidateManualNodeIds.get(manualNodeId)) {
            return manualNodeId
        }
        return -1
    }

    private func clearCandidate(): Unit {
        candidateEntries.clear()
        candidateByKey.clear()
        candidateManualNodeIds.clear()
        candidateRootValue = None
        candidateOpenValue = false
        candidateResolvedValue = false
        candidatePreparedValue = false
        candidateNextScopedNodeId = nextScopedNodeIdValue
    }

    private func identityIssue(prefix: String, identity: CjguiComposableUiIdentity): String {
        return "${prefix}_scope_${identity.diagnosticScope()}_key_${identity.localKey()}"
    }
}

public func cjguiComposableVertical(nodeId: Int64, semanticId: String, style: CjguiComposableUiStyle,
    inputScopeId!: String = "", layoutReuseKey!: String = "",
    identity!: ?CjguiComposableUiIdentity = None): CjguiComposableUiNode {
    return CjguiComposableUiNode(nodeId, semanticId, CJGUI_COMPOSABLE_UI_VERTICAL, "", "", "", -1, style,
        inputScopeId: inputScopeId, layoutReuseKey: layoutReuseKey, identity: identity)
}

public func cjguiComposableHorizontal(nodeId: Int64, semanticId: String, style: CjguiComposableUiStyle,
    inputScopeId!: String = "", layoutReuseKey!: String = "",
    identity!: ?CjguiComposableUiIdentity = None): CjguiComposableUiNode {
    return CjguiComposableUiNode(nodeId, semanticId, CJGUI_COMPOSABLE_UI_HORIZONTAL, "", "", "", -1, style,
        inputScopeId: inputScopeId, layoutReuseKey: layoutReuseKey, identity: identity)
}

/// Compose a split view from two ordinary child subtrees. The generated
/// handle is a normal Cangjie node (node id `nodeId + 2`) and therefore shares
/// the canonical layout, hit-test and semantic projection. `firstSize` is a
/// logical-point hint; every layout pass clamps it against both pane minima.
public func cjguiComposableSplitView(nodeId: Int64, semanticId: String, first: CjguiComposableUiNode,
    second: CjguiComposableUiNode, axis: Int64, firstSize: Int64, minFirst: Int64, minSecond: Int64,
    style: CjguiComposableUiStyle, operationActionName!: String = "SET_SPLIT_SIZE", operationResourceId!: Int64 = -1,
    handleNodeId!: Int64 = -1, handleThickness!: Int64 = 8): CjguiComposableUiNode {
    let safeAxis = if (axis == CjguiComposableUiSplitAxis.VERTICAL) {
        CjguiComposableUiSplitAxis.VERTICAL
    } else {
        CjguiComposableUiSplitAxis.HORIZONTAL
    }
    let resolvedHandleId = if (handleNodeId >= 0) {
        handleNodeId
    } else {
        nodeId + 2
    }
    let handleStyle = if (safeAxis == CjguiComposableUiSplitAxis.VERTICAL) {
        CjguiComposableUiStyle(fixedHeight: if (handleThickness > 0) {
            handleThickness
        } else {
            1
        }, growX: 1)
    } else {
        CjguiComposableUiStyle(fixedWidth: if (handleThickness > 0) {
            handleThickness
        } else {
            1
        }, growY: 1)
    }
    let handle = CjguiComposableUiNode(resolvedHandleId, "${semanticId}-handle", CJGUI_COMPOSABLE_UI_SPLIT_HANDLE, "",
        "", "SPLIT_HANDLE", operationResourceId, handleStyle, operationActionName: operationActionName,
        operationResourceId: operationResourceId, pointerControlRole: "split_handle", pointerControlAxis: safeAxis,
        pointerControlMinimum: minFirst, pointerControlFirstSize: firstSize,
        pointerControlHandleThickness: if (handleThickness > 0) {
            handleThickness
        } else {
            1
        }, pointerControlSecondMinimum: minSecond)
    let containerKind = if (safeAxis == CjguiComposableUiSplitAxis.VERTICAL) {
        CJGUI_COMPOSABLE_UI_VERTICAL
    } else {
        CJGUI_COMPOSABLE_UI_HORIZONTAL
    }
    let container = CjguiComposableUiNode(nodeId, semanticId, containerKind, "", "", "", -1, style,
        operationActionName: operationActionName, operationResourceId: operationResourceId,
        pointerControlRole: "split_view", pointerControlAxis: safeAxis, pointerControlMinimum: minFirst,
        pointerControlFirstSize: firstSize, pointerControlHandleThickness: if (handleThickness > 0) {
            handleThickness
        } else {
            1
        }, pointerControlSecondMinimum: minSecond)
    container.add(first)
    container.add(handle)
    container.add(second)
    return container
}

/// ONE declared page of a public tab container: a stable page key, the title a
/// person reads, whether the container may switch to it, and the subtree it
/// presents. The key is the ONLY stable identity a caller needs; the container's
/// scope allocates the page's and the title's framework identities.
public class CjguiComposableUiTabPage {
    public let key: String
    public let title: String
    public let enabled: Bool
    public let content: CjguiComposableUiNode

    public init(key: String, title: String, content: CjguiComposableUiNode, enabled!: Bool = true) {
        this.key = key
        this.title = title
        this.content = content
        this.enabled = enabled
    }
}

/// The public tab container: a bounded set of pages (2..3 is the supported
/// working set) of which exactly ONE is active. `state` holds the active page as
/// WINDOW view state: the declared page only seeds a new instance, so a reorder,
/// a style change or an ordinary field refresh never moves a person back.
///
/// A hidden page keeps its scoped identity and its own view state, but it is NOT
/// measured, hit-tested or drawn: hiding is never deletion, and it is never a
/// business write. Both authors (handwritten and generated) build through this
/// ONE component, and the title row's identities come from `scope`, so no caller
/// owns an implementation-defined node id.
public func cjguiComposableTabs(scope: CjguiComposableUiIdentityScope, semanticId: String,
    pages: ArrayList<CjguiComposableUiTabPage>, state: CjguiComposableUiTabsState,
    style: CjguiComposableUiStyle, titleHeight!: Int64 = 28,
    titleStyle!: CjguiComposableUiStyle = CjguiComposableUiStyle(),
    titleInteraction!: CjguiComposableUiInteractionStyle = CjguiComposableUiInteractionStyle(),
    containerNodeId!: Int64 = -1): CjguiComposableUiNode {
    let safeTitleHeight = if (titleHeight > 0) {
        titleHeight
    } else {
        1
    }
    let titleRowStyle = CjguiComposableUiStyle(fixedHeight: safeTitleHeight, growX: 1)
    // Generated authors already reserve a stable numeric ID for this declared
    // container. Keep that exact ID so accepted-instance lookup and event
    // routing use the same identity; handwritten callers keep scoped identity.
    let containerIdentity: ?CjguiComposableUiIdentity = if (containerNodeId >= 0) {
        None
    } else {
        Some(scope.local("container"))
    }
    let container = CjguiComposableUiNode(containerNodeId, semanticId, CJGUI_COMPOSABLE_UI_TABS,
        "", "", "", -1, style, tabsState: state, tabsTitleHeight: safeTitleHeight,
        identity: containerIdentity)
    let titleRow = CjguiComposableUiNode(-1, "${semanticId}-titles", CJGUI_COMPOSABLE_UI_HORIZONTAL, "", "", "", -1,
        titleRowStyle, identity: scope.local("titles"))
    // A title keeps the row's own centred geometry and takes only PAINT from
    // `titleStyle`/`titleInteraction`. The default pair is the empty style and
    // the empty interaction paint, so a caller that passes neither keeps the
    // exact title it had before (implicit defaults); a dark-surface consumer can
    // make its titles readable without a second focus owner or an inherited
    // colour system.
    let titleNodeStyle = CjguiComposableUiStyle(
        background: titleStyle.background,
        border: titleStyle.border,
        textColor: titleStyle.textColor,
        borderWidth: titleStyle.borderWidth,
        fontSize: titleStyle.fontSize,
        fontWeight: titleStyle.fontWeight,
        growX: 1,
        alignX: CJGUI_COMPOSABLE_UI_ALIGN_CENTER)
    var index = 0
    while (index < pages.size) {
        let page = pages[index]
        let title = CjguiComposableUiNode(-1, "${semanticId}-tab-${page.key}", CJGUI_COMPOSABLE_UI_TAB_TITLE,
            page.title, page.key, "ACTIVATE_TAB", -1,
            titleNodeStyle, enabled: page.enabled,
            tabsState: state, tabsPageKey: page.key, tabsTitleHeight: safeTitleHeight,
            interactionStyle: titleInteraction,
            identity: scope.local("tab-${page.key}"))
        titleRow.add(title)
        index += 1
    }
    container.add(titleRow)
    index = 0
    while (index < pages.size) {
        let page = pages[index]
        let active = page.key == state.activeKey()
        // The page keeps the caller's subtree, and the ACTIVE flag lives on the
        // page root so the layout presents exactly one page.
        let pageRoot = CjguiComposableUiNode(-1, page.content.semanticId, CJGUI_COMPOSABLE_UI_VERTICAL, "", "", "",
            -1, CjguiComposableUiStyle(growX: 1), tabsState: state, tabsPageKey: page.key, tabsPageActive: active,
            identity: scope.local("page-${page.key}"))
        pageRoot.add(page.content)
        container.add(pageRoot)
        index += 1
    }
    return container
}

/// Safe split composition. Unlike the legacy numeric overload, the container
/// and handle are local identities below `scope`; no implementation detail
/// claims a caller-owned `nodeId + offset` range. The owning window resolves
/// them atomically with the rest of its candidate scene.
public func cjguiComposableScopedSplitView(scope: CjguiComposableUiIdentityScope, semanticId: String,
    first: CjguiComposableUiNode, second: CjguiComposableUiNode, axis: Int64, firstSize: Int64, minFirst: Int64,
    minSecond: Int64, style: CjguiComposableUiStyle, operationActionName!: String = "SET_SPLIT_SIZE",
    operationResourceId!: Int64 = -1, handleThickness!: Int64 = 8,
    splitState!: ?CjguiComposableUiSplitState = None): CjguiComposableUiNode {
    let safeAxis = if (axis == CjguiComposableUiSplitAxis.VERTICAL) {
        CjguiComposableUiSplitAxis.VERTICAL
    } else {
        CjguiComposableUiSplitAxis.HORIZONTAL
    }
    let safeThickness = if (handleThickness > 0) {
        handleThickness
    } else {
        1
    }
    let handleStyle = if (safeAxis == CjguiComposableUiSplitAxis.VERTICAL) {
        CjguiComposableUiStyle(fixedHeight: safeThickness, growX: 1)
    } else {
        CjguiComposableUiStyle(fixedWidth: safeThickness, growY: 1)
    }
    let handle = CjguiComposableUiNode(-1, "${semanticId}-handle", CJGUI_COMPOSABLE_UI_SPLIT_HANDLE, "", "",
        "SPLIT_HANDLE", operationResourceId, handleStyle, operationActionName: operationActionName,
        operationResourceId: operationResourceId, pointerControlRole: "split_handle", pointerControlAxis: safeAxis,
        pointerControlMinimum: minFirst, pointerControlFirstSize: firstSize,
        pointerControlHandleThickness: safeThickness, pointerControlSecondMinimum: minSecond,
        identity: scope.local("handle"), splitState: splitState)
    let containerKind = if (safeAxis == CjguiComposableUiSplitAxis.VERTICAL) {
        CJGUI_COMPOSABLE_UI_VERTICAL
    } else {
        CJGUI_COMPOSABLE_UI_HORIZONTAL
    }
    let container = CjguiComposableUiNode(-1, semanticId, containerKind, "", "", "", -1, style,
        operationActionName: operationActionName, operationResourceId: operationResourceId,
        pointerControlRole: "split_view", pointerControlAxis: safeAxis, pointerControlMinimum: minFirst,
        pointerControlFirstSize: firstSize, pointerControlHandleThickness: safeThickness,
        pointerControlSecondMinimum: minSecond, identity: scope.local("container"), splitState: splitState)
    container.add(first)
    container.add(handle)
    container.add(second)
    return container
}

/// One action declaration for `cjguiComposableScopedActionRow`. It carries
/// exactly the normal button's public value fields, not a native callback or
/// a new application command owner.
public class CjguiComposableUiActionItem {
    public let localKey: String
    /// Optional stable semantic name. When omitted, the row derives one from
    /// its own semantic id and `localKey` for newly authored consumers.
    public let semanticId: String
    public let label: String
    public let actionName: String
    public let resourceId: Int64
    public let style: CjguiComposableUiStyle
    public let isEnabled: Bool
    public let operationActionName: String
    public let operationResourceId: Int64

    public init(localKey: String, label: String, actionName: String, resourceId: Int64, style: CjguiComposableUiStyle,
        enabled!: Bool = true, operationActionName!: String = "", operationResourceId!: Int64 = -1,
        semanticId!: String = "") {
        this.localKey = localKey
        this.semanticId = semanticId
        this.label = label
        this.actionName = actionName
        this.resourceId = resourceId
        this.style = style
        this.isEnabled = enabled
        this.operationActionName = operationActionName
        this.operationResourceId = operationResourceId
    }
}

/// A safe multi-action composite. Its row and each child button receive local
/// scoped identity, so repeating the same action component under sibling
/// scopes neither overwrites input routing nor reserves numeric ID ranges.
public func cjguiComposableScopedActionRow(scope: CjguiComposableUiIdentityScope, semanticId: String,
    items: ArrayList<CjguiComposableUiActionItem>, style: CjguiComposableUiStyle): CjguiComposableUiNode {
    let row = CjguiComposableUiNode(-1, semanticId, CJGUI_COMPOSABLE_UI_HORIZONTAL, "", "", "", -1, style,
        identity: scope.local("row"))
    let itemScope = scope.child("item")
    for (item in items) {
        let itemSemanticId = if (item.semanticId.size > 0) {
            item.semanticId
        } else {
            "${semanticId}-${item.localKey}"
        }
        row.add(
            CjguiComposableUiNode(-1, itemSemanticId, CJGUI_COMPOSABLE_UI_BUTTON, item.label, item.label,
                item.actionName, item.resourceId, item.style, enabled: item.isEnabled,
                operationActionName: item.operationActionName, operationResourceId: item.operationResourceId,
                identity: itemScope.local(item.localKey)))
    }
    return row
}

/// Compose a slider leaf. The value is deliberately supplied by the consumer
/// on every declaration; this helper retains no mutable slider value.
public func cjguiComposableSlider(nodeId: Int64, semanticId: String, value: Int64, minimum: Int64, maximum: Int64,
    step: Int64, style: CjguiComposableUiStyle, operationActionName!: String = "SET_SLIDER_VALUE",
    operationResourceId!: Int64 = -1,
    interactionStyle!: CjguiComposableUiInteractionStyle = CjguiComposableUiInteractionStyle(),
    ownerInteractionState!: Int64 = CjguiComposableUiInteractionState.NONE): CjguiComposableUiNode {
    let upper = if (maximum >= minimum) {
        maximum
    } else {
        minimum
    }
    let safeValue = CjguiComposableUiSliderGeometry.clampValue(value, minimum, upper)
    return CjguiComposableUiNode(nodeId, semanticId, CJGUI_COMPOSABLE_UI_SLIDER, semanticId, safeValue.toString(),
        "SLIDER_VALUE", operationResourceId, style, operationActionName: operationActionName,
        operationResourceId: operationResourceId, pointerControlRole: "slider", pointerControlMinimum: minimum,
        pointerControlMaximum: upper, pointerControlStep: if (step > 0) {
            step
        } else {
            1
        }, interactionStyle: interactionStyle, ownerInteractionState: ownerInteractionState)
}

public func cjguiComposableText(nodeId: Int64, semanticId: String, value: String, style: CjguiComposableUiStyle,
    resourceId!: Int64 = -1, fieldId!: String = "", displayValueRole!: String = "", operationResourceId!: Int64 = -1,
    interactionStyle!: CjguiComposableUiInteractionStyle = CjguiComposableUiInteractionStyle(),
    ownerInteractionState!: Int64 = CjguiComposableUiInteractionState.NONE,
    identity!: ?CjguiComposableUiIdentity = None,
    textStyleRuns!: Array<CjguiComposableUiTextStyleRun> = Array<CjguiComposableUiTextStyleRun>()): CjguiComposableUiNode {
    return CjguiComposableUiNode(nodeId, semanticId, CJGUI_COMPOSABLE_UI_TEXT, "", value, "", resourceId, style,
        textStyleRuns: textStyleRuns,
        fieldId: fieldId, operationResourceId: operationResourceId, displayValueRole: displayValueRole,
        interactionStyle: interactionStyle, ownerInteractionState: ownerInteractionState, identity: identity)
}

/// Whole-group binding for a static text node (same one-argument contract as
/// the button overload).
public func cjguiComposableText(nodeId: Int64, semanticId: String, value: String,
    boundStyle: CjguiComposableUiBoundStyle, resourceId!: Int64 = -1, fieldId!: String = "",
    displayValueRole!: String = "", operationResourceId!: Int64 = -1,
    ownerInteractionState!: Int64 = CjguiComposableUiInteractionState.NONE,
    identity!: ?CjguiComposableUiIdentity = None): CjguiComposableUiNode {
    return cjguiComposableText(nodeId, semanticId, value, boundStyle.style,
        resourceId: resourceId, fieldId: fieldId, displayValueRole: displayValueRole,
        operationResourceId: operationResourceId, interactionStyle: boundStyle.interaction,
        ownerInteractionState: ownerInteractionState, identity: identity)
}

/// Whole-group binding: the component receives ONE bound value carrying both
/// the resolved base style and the interaction paint, so picking the named
/// role once brings hover/pressed/focused/disabled along. Old explicit
/// `style`+`interactionStyle` parameters remain fully compatible; the bound
/// value's fields install in the same order as the explicit pair.
// NODE IDS ARE OPAQUE IDENTITIES, NOT A PROTOCOL (corrected 2026-09-27).
// A press is routed by the node's KIND plus its `isInteractive` / `isReadOnly` flags
// (`CjguiComposableNodeIsPressable` in the native renderer), never by the numeric value of
// `nodeId`. The one id rule the framework enforces is UNIQUENESS: a scene with a duplicated id
// is rejected by name (`duplicate_node_id`), because a hit test and every later event would
// otherwise be ambiguous.
// Range conventions (e.g. "chrome below 1000, document fragments above it") belong to the
// PRODUCT, which routes its own pointer events by those ranges. A control whose id lands inside
// a range the product claims before its activate handler runs has its press consumed there; that
// is a product-side allocation rule, not a framework id space. (Measured 2026-09-25: two
// buttons at 312/313 never activated while identical ones at 116/117 did -- the product's own
// fragment router claimed 312/313 first. Recorded in Pharos Mark's
// `packages/app_services/src/node_id_ranges.cj`.)
public func cjguiComposableButton(nodeId: Int64, semanticId: String, label: String, actionName: String,
    resourceId: Int64, boundStyle: CjguiComposableUiBoundStyle, enabled!: Bool = true,
    operationActionName!: String = "", operationResourceId!: Int64 = -1,
    ownerInteractionState!: Int64 = CjguiComposableUiInteractionState.NONE,
    identity!: ?CjguiComposableUiIdentity = None): CjguiComposableUiNode {
    return cjguiComposableButton(nodeId, semanticId, label, actionName, resourceId,
        boundStyle.style, enabled: enabled, operationActionName: operationActionName,
        operationResourceId: operationResourceId, interactionStyle: boundStyle.interaction,
        ownerInteractionState: ownerInteractionState, identity: identity)
}

public func cjguiComposableButton(nodeId: Int64, semanticId: String, label: String, actionName: String,
    resourceId: Int64, style: CjguiComposableUiStyle, enabled!: Bool = true, operationActionName!: String = "",
    operationResourceId!: Int64 = -1,
    interactionStyle!: CjguiComposableUiInteractionStyle = CjguiComposableUiInteractionStyle(),
    ownerInteractionState!: Int64 = CjguiComposableUiInteractionState.NONE,
    identity!: ?CjguiComposableUiIdentity = None): CjguiComposableUiNode {
    return CjguiComposableUiNode(nodeId, semanticId, CJGUI_COMPOSABLE_UI_BUTTON, label, label, actionName, resourceId,
        style, enabled: enabled, operationActionName: operationActionName, operationResourceId: operationResourceId,
        interactionStyle: interactionStyle, ownerInteractionState: ownerInteractionState, identity: identity)
}

public func cjguiComposableTextInput(nodeId: Int64, semanticId: String, label: String, value: String, resourceId: Int64,
    style: CjguiComposableUiStyle, enabled!: Bool = true, readOnly!: Bool = false, fieldId!: String = "",
    operationActionName!: String = "", operationResourceId!: Int64 = -1, displayValueRole!: String = "draft",
    interactionStyle!: CjguiComposableUiInteractionStyle = CjguiComposableUiInteractionStyle(),
    ownerInteractionState!: Int64 = CjguiComposableUiInteractionState.NONE): CjguiComposableUiNode {
    return CjguiComposableUiNode(nodeId, semanticId, CJGUI_COMPOSABLE_UI_TEXT_INPUT, label, value, "EDIT_TEXT",
        resourceId, style, enabled: enabled, readOnly: readOnly, fieldId: fieldId,
        operationActionName: operationActionName, operationResourceId: operationResourceId,
        displayValueRole: displayValueRole, interactionStyle: interactionStyle,
        ownerInteractionState: ownerInteractionState)
}

/// Whole-group binding for a text input (same one-argument contract as the
/// button overload).
public func cjguiComposableTextInput(nodeId: Int64, semanticId: String, label: String, value: String,
    resourceId: Int64, boundStyle: CjguiComposableUiBoundStyle, enabled!: Bool = true,
    readOnly!: Bool = false, fieldId!: String = "", operationActionName!: String = "",
    operationResourceId!: Int64 = -1, displayValueRole!: String = "draft",
    ownerInteractionState!: Int64 = CjguiComposableUiInteractionState.NONE): CjguiComposableUiNode {
    return cjguiComposableTextInput(nodeId, semanticId, label, value, resourceId,
        boundStyle.style, enabled: enabled, readOnly: readOnly, fieldId: fieldId,
        operationActionName: operationActionName, operationResourceId: operationResourceId,
        displayValueRole: displayValueRole, interactionStyle: boundStyle.interaction,
        ownerInteractionState: ownerInteractionState)
}

public func cjguiComposableIntegerInput(nodeId: Int64, semanticId: String, label: String, value: String,
    resourceId: Int64, style: CjguiComposableUiStyle, enabled!: Bool = true, readOnly!: Bool = false,
    fieldId!: String = "", operationActionName!: String = "", operationResourceId!: Int64 = -1,
    displayValueRole!: String = "draft", interactionStyle!: CjguiComposableUiInteractionStyle = CjguiComposableUiInteractionStyle(),
    ownerInteractionState!: Int64 = CjguiComposableUiInteractionState.NONE): CjguiComposableUiNode {
    return CjguiComposableUiNode(nodeId, semanticId, CJGUI_COMPOSABLE_UI_INTEGER_INPUT, label, value, "EDIT_INTEGER",
        resourceId, style, enabled: enabled, readOnly: readOnly, fieldId: fieldId,
        operationActionName: operationActionName, operationResourceId: operationResourceId,
        displayValueRole: displayValueRole, interactionStyle: interactionStyle,
        ownerInteractionState: ownerInteractionState)
}
/// Composes an ordinary multi-line plain-text editor into the same layout,
/// focus, event and semantic-projection path as existing inputs. Its value is
/// a projection only; a consumer routes returned text to its document truth.
public func cjguiComposableMultilineTextInput(nodeId: Int64, semanticId: String, label: String, value: String,
    resourceId: Int64, style: CjguiComposableUiStyle, enabled!: Bool = true, readOnly!: Bool = false,
    fieldId!: String = "", operationActionName!: String = "", operationResourceId!: Int64 = -1,
    displayValueRole!: String = "document", tabInsertsText!: Bool = false,
    interactionStyle!: CjguiComposableUiInteractionStyle = CjguiComposableUiInteractionStyle(),
    ownerInteractionState!: Int64 = CjguiComposableUiInteractionState.NONE): CjguiComposableUiNode {
    return CjguiComposableUiNode(nodeId, semanticId, CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT, label, value,
        "EDIT_MULTILINE_TEXT", resourceId, style, enabled: enabled, readOnly: readOnly, fieldId: fieldId,
        operationActionName: operationActionName, operationResourceId: operationResourceId,
        displayValueRole: displayValueRole, tabInsertsText: tabInsertsText, interactionStyle: interactionStyle,
        ownerInteractionState: ownerInteractionState)
}

public func cjguiComposableBooleanInput(nodeId: Int64, semanticId: String, label: String, value: Bool,
    resourceId: Int64, style: CjguiComposableUiStyle, enabled!: Bool = true, fieldId!: String = "",
    operationActionName!: String = "", operationResourceId!: Int64 = -1, displayValueRole!: String = "draft",
    interactionStyle!: CjguiComposableUiInteractionStyle = CjguiComposableUiInteractionStyle(),
    ownerInteractionState!: Int64 = CjguiComposableUiInteractionState.NONE): CjguiComposableUiNode {
    return CjguiComposableUiNode(nodeId, semanticId, CJGUI_COMPOSABLE_UI_BOOLEAN_INPUT, label, if (value) {
        "true"
    } else {
        "false"
    }, "EDIT_BOOLEAN", resourceId, style, enabled: enabled, fieldId: fieldId, operationActionName: operationActionName,
        operationResourceId: operationResourceId, displayValueRole: displayValueRole,
        interactionStyle: interactionStyle, ownerInteractionState: ownerInteractionState)
}

/// Compose one application-owned form descriptor and its current field
/// projection through the ordinary input primitives.  The descriptor supplies
/// the stable field identity and accessible label; the projection supplies
/// only current draft/validation data.  `operationResourceId` is the selected
/// domain record, so human input and external window projection share the
/// same field/action relationship without a second app-maintained mapping.
///
/// This is experimental Cangjie composition, not a validation engine: field
/// rules, permissions and draft writes still enter the application's domain.
private func userFacingBoundFieldValidationMessage(descriptor: CjguiSharedFormFieldDescriptor, validationError: String): String {
    // Domains preserve their stable machine reason for external callers and
    // tests.  A normal human-facing field must not expose that implementation
    // vocabulary, so derive a concise message from the public field label.
    if (validationError.contains("required")) {
        return "请填写${descriptor.label}"
    }
    if (validationError.contains("range") || validationError.contains("count")) {
        return "${descriptor.label}超出允许范围"
    }
    if (validationError.contains("invalid") || validationError.contains("format")) {
        return "${descriptor.label}格式无效"
    }
    return "请检查${descriptor.label}"
}

public func cjguiComposableBoundFormField(
    containerNodeId: Int64,
    containerSemanticId: String,
    editorNodeId: Int64,
    validationNodeId: Int64,
    descriptor: CjguiSharedFormFieldDescriptor,
    field: CjguiSharedFormFieldProjection,
    operationResourceId: Int64,
    editorStyle: CjguiComposableUiStyle,
    validationStyle: CjguiComposableUiStyle,
    editorSemanticId!: String = "",
    validationSemanticId!: String = "",
    // A domain may supply its own human wording while retaining the stable
    // machine validation reason in the shared field projection. An empty
    // value keeps the compatibility Chinese fallback below.
    validationDisplayMessage!: String = "",
    enabled!: Bool = true,
    readOnly!: Bool = false,
    textOperationActionName!: String = "EDIT_DRAFT_TEXT",
    booleanOperationActionName!: String = "EDIT_DRAFT_BOOLEAN"
): CjguiComposableUiNode {
    if (descriptor.resourceId != field.resourceId || descriptor.fieldId != field.fieldId) {
        throw IllegalArgumentException("composable_bound_form_field_identity_mismatch")
    }
    let group = cjguiComposableVertical(containerNodeId, containerSemanticId, CjguiComposableUiStyle(gap: 3, growX: 1))
    let resolvedEditorSemanticId = if (editorSemanticId.size > 0) {
        editorSemanticId
    } else {
        "${containerSemanticId}-editor"
    }
    let resolvedValidationSemanticId = if (validationSemanticId.size > 0) {
        validationSemanticId
    } else {
        "${containerSemanticId}-validation"
    }
    if (descriptor.editorKind == "BOOLEAN") {
        // A boolean has no separate read-only platform role.  Keep it visible
        // but non-interactive rather than allowing a visually read-only
        // switch to dispatch an edit intent.
        group.add(
            cjguiComposableBooleanInput(editorNodeId, resolvedEditorSemanticId, descriptor.label,
                field.draftText == "true", descriptor.resourceId, editorStyle, enabled: enabled && !readOnly,
                fieldId: descriptor.fieldId, operationActionName: booleanOperationActionName,
                operationResourceId: operationResourceId, displayValueRole: "draft"))
    } else if (descriptor.editorKind == "INTEGER") {
        group.add(
            cjguiComposableIntegerInput(editorNodeId, resolvedEditorSemanticId, descriptor.label, field.draftText,
                descriptor.resourceId, editorStyle, enabled: enabled, readOnly: readOnly, fieldId: descriptor.fieldId,
                operationActionName: textOperationActionName, operationResourceId: operationResourceId,
                displayValueRole: "draft"))
    } else if (descriptor.editorKind == "TEXT") {
        group.add(
            cjguiComposableTextInput(editorNodeId, resolvedEditorSemanticId, descriptor.label, field.draftText,
                descriptor.resourceId, editorStyle, enabled: enabled, readOnly: readOnly, fieldId: descriptor.fieldId,
                operationActionName: textOperationActionName, operationResourceId: operationResourceId,
                displayValueRole: "draft"))
    } else {
        throw IllegalArgumentException("composable_bound_form_field_unknown_editor")
    }
    if (field.validationError.size > 0) {
        group.add(
            cjguiComposableText(validationNodeId, resolvedValidationSemanticId,
                if (validationDisplayMessage.size > 0) {
                    validationDisplayMessage
                } else {
                    userFacingBoundFieldValidationMessage(descriptor, field.validationError)
                }, validationStyle, resourceId: descriptor.resourceId, fieldId: descriptor.fieldId,
                displayValueRole: "validation", operationResourceId: operationResourceId))
    }
    return group
}

/// One generic selectable-list row.  The caller owns range lookup and domain
/// selection, while this helper keeps the item's accessible label, displayed
/// title and externally discoverable action/resource relation identical.
public func cjguiComposableSelectableListRow(
    nodeId: Int64,
    semanticId: String,
    item: CjguiComposableUiVirtualListItem,
    actionName: String,
    normalStyle: CjguiComposableUiStyle,
    selectedStyle: CjguiComposableUiStyle,
    isSelected: Bool,
    isFocused: Bool,
    enabled!: Bool = true,
    operationActionName!: String = ""
): CjguiComposableUiNode {
    return cjguiComposableButton(nodeId, semanticId, item.title, actionName, item.resourceId,
        if (isSelected || isFocused) {
            selectedStyle
        } else {
            normalStyle
        }, enabled: enabled, operationActionName: if (operationActionName.size > 0) {
            operationActionName
        } else {
            actionName
        }, operationResourceId: item.resourceId)
}

public func cjguiComposableImage(nodeId: Int64, semanticId: String, localRasterPath: String,
    style: CjguiComposableUiStyle, contentMode!: Int64 = 1, imageResourceId!: String = "",
    imageResourceVersion!: Int64 = 0,
    interactionStyle!: CjguiComposableUiInteractionStyle = CjguiComposableUiInteractionStyle(),
    ownerInteractionState!: Int64 = CjguiComposableUiInteractionState.NONE): CjguiComposableUiNode {
    return CjguiComposableUiNode(nodeId, semanticId, CJGUI_COMPOSABLE_UI_IMAGE, "", "", "", -1, style,
        imageResourcePath: localRasterPath, imageResourceId: imageResourceId, imageResourceVersion: imageResourceVersion,
        interactionStyle: interactionStyle, ownerInteractionState: ownerInteractionState,
        imageContentMode: contentMode)
}

public func cjguiComposableScrollArea(nodeId: Int64, semanticId: String, scrollOffset: Int64,
    style: CjguiComposableUiStyle, enabled!: Bool = true): CjguiComposableUiNode {
    return CjguiComposableUiNode(nodeId, semanticId, CJGUI_COMPOSABLE_UI_SCROLL_AREA, "", "", "SCROLL", -1, style,
        scrollOffset: scrollOffset, enabled: enabled)
}

/// The SAME public scroll container bound to a shared viewport state. The build
/// reads the viewport's requested offset, and the layout reports the accepted
/// extents back through the same object, so a wheel gesture, a reveal and a
/// theme change all flow through ONE definition instead of each author computing
/// coordinates.
public func cjguiComposableScrollArea(nodeId: Int64, semanticId: String, viewport: CjguiComposableUiScrollViewport,
    style: CjguiComposableUiStyle, enabled!: Bool = true): CjguiComposableUiNode {
    return CjguiComposableUiNode(nodeId, semanticId, CJGUI_COMPOSABLE_UI_SCROLL_AREA, "", "", "SCROLL", -1, style,
        scrollOffset: viewport.offset(), scrollViewport: Some(viewport), enabled: enabled)
}

/// Compose a fixed-row list without first creating every logical row. The
/// `contentNodeId` is caller-owned just like ordinary component IDs and must
/// not collide with a row node returned by the source.
public func cjguiComposableVirtualList(nodeId: Int64, semanticId: String, contentNodeId: Int64,
    source: CjguiComposableUiVirtualListSource, state: CjguiComposableUiVirtualListState, rowHeight: Int64,
    rowGap: Int64, overscan: Int64, style: CjguiComposableUiStyle, enabled!: Bool = true): CjguiComposableUiNode {
    return CjguiComposableUiNode(nodeId, semanticId, CJGUI_COMPOSABLE_UI_SCROLL_AREA, "", "", "SCROLL", -1, style,
        scrollOffset: state.scrollOffset(), enabled: enabled, virtualListSource: Some(source),
        virtualListState: Some(state), virtualListContentNodeId: contentNodeId, virtualListRowHeight: rowHeight,
        virtualListRowGap: rowGap, virtualListOverscan: overscan)
}

/// Compose an experimental variable-height list. The height argument is an
/// unseen-row estimate only: every revealed row is an ordinary Cangjie
/// subtree measured by the normal layout path before it is rendered, hit
/// tested or projected. The fixed-row entry above remains unchanged.
public func cjguiComposableVariableHeightList(nodeId: Int64, semanticId: String, contentNodeId: Int64,
    source: CjguiComposableUiVariableHeightListSource, state: CjguiComposableUiVirtualListState,
    estimatedRowHeight: Int64, rowGap: Int64, overscan: Int64, style: CjguiComposableUiStyle, enabled!: Bool = true): CjguiComposableUiNode {
    return CjguiComposableUiNode(nodeId, semanticId, CJGUI_COMPOSABLE_UI_SCROLL_AREA, "", "", "SCROLL", -1, style,
        scrollOffset: state.scrollOffset(), enabled: enabled, variableHeightListSource: Some(source),
        virtualListState: Some(state), virtualListContentNodeId: contentNodeId, virtualListRowHeight: estimatedRowHeight,
        virtualListRowGap: rowGap, virtualListOverscan: overscan)
}

/// The first child is ordinary base content; subsequent children made with
/// the layer helpers below are painted and hit-tested above it in declaration
/// order.  This is an experimental, Cangjie-owned composition API.
public func cjguiComposableLayerHost(nodeId: Int64, semanticId: String, style: CjguiComposableUiStyle): CjguiComposableUiNode {
    return CjguiComposableUiNode(nodeId, semanticId, CJGUI_COMPOSABLE_UI_LAYER_HOST, "", "", "", -1, style)
}

/// A popup/menu is placed below its live anchor when possible, otherwise
/// above it and within the host viewport. Its owner is projection context,
/// not a native routing target.
public func cjguiComposableAnchoredLayer(nodeId: Int64, semanticId: String, layerId: String, layerKind: String,
    ownerSemanticId: String, anchorNodeId: Int64, style: CjguiComposableUiStyle): CjguiComposableUiNode {
    return CjguiComposableUiNode(nodeId, semanticId, CJGUI_COMPOSABLE_UI_VERTICAL, "", "", "", -1, style,
        layerId: layerId, layerKind: if (layerKind == "popup") {
            "popup"
        } else {
            "menu"
        }, layerOwnerSemanticId: ownerSemanticId, layerAnchorSemanticId: ownerSemanticId,
        layerAnchorNodeId: anchorNodeId)
}

/// Declarative counterpart of `cjguiComposableAnchoredLayer`. The reference
/// is resolved by the owning candidate after any visible virtual rows have
/// been materialised; legacy numeric anchors above remain source-compatible.
public func cjguiComposableAnchoredLayerWithReference(nodeId: Int64, semanticId: String, layerId: String,
    layerKind: String, ownerSemanticId: String, anchor: CjguiComposableUiNodeReference,
    style: CjguiComposableUiStyle): CjguiComposableUiNode {
    return CjguiComposableUiNode(nodeId, semanticId, CJGUI_COMPOSABLE_UI_VERTICAL, "", "", "", -1, style,
        layerId: layerId, layerKind: if (layerKind == "popup") {
            "popup"
        } else {
            "menu"
        }, layerOwnerSemanticId: ownerSemanticId, layerAnchorSemanticId: ownerSemanticId,
        layerAnchorReference: Some(anchor))
}

/// A dialog centers in the host and contributes an input-blocking backdrop.
/// Closing it is still the controller's ordinary state transition; the host
/// does not invent business confirmation or authorization.
public func cjguiComposableDialogLayer(nodeId: Int64, semanticId: String, layerId: String, ownerSemanticId: String,
    ownerNodeId: Int64, style: CjguiComposableUiStyle, initialFocusNodeId!: Int64 = -1): CjguiComposableUiNode {
    return CjguiComposableUiNode(nodeId, semanticId, CJGUI_COMPOSABLE_UI_VERTICAL, "", "", "", -1, style,
        layerId: layerId, layerKind: "dialog", layerOwnerSemanticId: ownerSemanticId,
        layerAnchorSemanticId: ownerSemanticId, layerAnchorNodeId: ownerNodeId, layerIsModal: true,
        layerInitialFocusNodeId: initialFocusNodeId)
}

/// Declarative dialog owner/initial-focus references join the same candidate
/// identity transaction as reusable child components. A missing target rejects
/// the candidate before native staging rather than restoring focus by index.
public func cjguiComposableDialogLayerWithReference(nodeId: Int64, semanticId: String, layerId: String,
    ownerSemanticId: String, owner: CjguiComposableUiNodeReference, style: CjguiComposableUiStyle,
    initialFocus!: ?CjguiComposableUiNodeReference = None): CjguiComposableUiNode {
    return CjguiComposableUiNode(nodeId, semanticId, CJGUI_COMPOSABLE_UI_VERTICAL, "", "", "", -1, style,
        layerId: layerId, layerKind: "dialog", layerOwnerSemanticId: ownerSemanticId,
        layerAnchorSemanticId: ownerSemanticId, layerAnchorReference: Some(owner), layerIsModal: true,
        layerInitialFocusReference: initialFocus)
}

/// Resolved output shared verbatim by the renderer bridge, native hit test,
/// focus plumbing and accessibility projection.
public class CjguiComposableUiLayoutNode {
    public let nodeId: Int64
    public let semanticId: String
    public let nodeKind: Int64
    public let label: String
    public let value: String
    public let actionName: String
    public let resourceId: Int64
    public let semanticIncarnation: Int64
    public let fieldId: String
    public let operationActionName: String
    public let operationResourceId: Int64
    public let displayValueRole: String
    public let imageResourcePath: String
    public let imageResourceId: String
    public let imageResourceVersion: Int64
    public let imageContentMode: Int64
    public let isEnabled: Bool
    public let isReadOnly: Bool
    public let tabInsertsText: Bool
    public let pointerControlRole: String
    public let pointerControlAxis: Int64
    public let pointerControlMinimum: Int64
    public let pointerControlMaximum: Int64
    public let pointerControlStep: Int64
    public let pointerControlHandleThickness: Int64
    public let pointerControlFirstSize: Int64
    public let pointerControlSecondMinimum: Int64
    public let bounds: CjguiComposableUiRect
    /// The shared viewport of this scroll area, when its author bound one. The
    /// layout reports the accepted extents through it; the value-based scroll
    /// area keeps `None`.
    public let scrollViewport: ?CjguiComposableUiScrollViewport
    /// The shared view state of a generated split instance, kept for the same
    /// reason as the viewport: the framework's single size rule updates it.
    public let splitState: ?CjguiComposableUiSplitState
    /// Tab-container facts carried onto the resolved layout node: the shared view
    /// state, this node's page key (when it is a page) and whether that page is
    /// the ACTIVE one the scene really presents.
    public let tabsState: ?CjguiComposableUiTabsState
    public let tabsPageKey: String
    public let tabsPageActive: Bool
    public let tabsTitleHeight: Int64
    /// Axis-aligned intersection of `clipConstraints`, retained for cheap
    /// bounds, AX frames and resource visibility. It is not a substitute for
    /// the original rounded shapes below.
    public let clip: CjguiComposableUiRect
    /// Compatibility view of the newest constraint. Consumers that need an
    /// exact clip must use `clipConstraints()`; native receives every entry.
    public let clipCornerRadius: Int64
    private let resolvedClipConstraints: ArrayList<CjguiComposableUiClipConstraint>
    /// The immutable declaration is retained separately from the currently
    /// resolved paint so interaction-only presentation can reuse geometry.
    public let declaredStyle: CjguiComposableUiStyle
    public let style: CjguiComposableUiStyle
    /// Presentation runs carried from the source component, so the scene
    /// projection can install them for the renderer.
    public let textStyleRuns: Array<CjguiComposableUiTextStyleRun>
    public let interactionStyle: CjguiComposableUiInteractionStyle
    public let ownerInteractionState: Int64
    /// A non-empty scope traps native focus navigation to a currently visible
    /// layer. It is derived during Cangjie layout, never guessed by AppKit.
    public let inputScopeId: String
    public let layerId: String
    public let layerKind: String
    /// Stable identity of the declaration this node was resolved from. It is the
    /// scoped canonical key when the author declared one, otherwise the semantic
    /// id, otherwise the resolved node id: never empty, and unique within one
    /// accepted scene. Consumers use it to resolve a real ancestor chain (for
    /// example the clip owners of a reveal) without comparing geometry.
    public let identityKey: String
    private let scopedIdentityValue: ?CjguiComposableUiIdentity
    public init(node: CjguiComposableUiNode, bounds: CjguiComposableUiRect, clip: CjguiComposableUiRect,
        inputScopeId!: String = "", clipCornerRadius!: Int64 = 0,
        clipConstraints!: ArrayList<CjguiComposableUiClipConstraint> = ArrayList<CjguiComposableUiClipConstraint>(),
        resolvedPaintStyle!: Option<CjguiComposableUiStyle> = None) {
        this.nodeId = node.nodeId
        this.semanticId = node.semanticId
        this.nodeKind = node.nodeKind
        this.label = node.label
        this.value = node.value
        this.actionName = node.actionName
        this.resourceId = node.resourceId
        this.semanticIncarnation = node.semanticIncarnation
        this.fieldId = node.fieldId
        this.operationActionName = node.operationActionName
        this.operationResourceId = node.operationResourceId
        this.displayValueRole = node.displayValueRole
        this.imageResourcePath = node.imageResourcePath
        this.imageResourceId = node.imageResourceId
        this.imageResourceVersion = node.imageResourceVersion
        this.imageContentMode = node.imageContentMode
        this.isEnabled = node.isEnabled
        this.isReadOnly = node.isReadOnly
        this.tabInsertsText = node.tabInsertsText
        this.pointerControlRole = node.pointerControlRole
        this.pointerControlAxis = node.pointerControlAxis
        this.pointerControlMinimum = node.pointerControlMinimum
        this.pointerControlMaximum = node.pointerControlMaximum
        this.pointerControlStep = node.pointerControlStep
        this.pointerControlHandleThickness = node.pointerControlHandleThickness
        this.pointerControlFirstSize = node.pointerControlFirstSize
        this.pointerControlSecondMinimum = node.pointerControlSecondMinimum
        this.scrollViewport = node.scrollViewport
        this.splitState = node.splitState
        this.tabsState = node.tabsState
        this.tabsPageKey = node.tabsPageKey
        this.tabsPageActive = node.tabsPageActive
        this.tabsTitleHeight = node.tabsTitleHeight
        this.bounds = bounds
        this.clip = clip
        this.clipCornerRadius = if (clipCornerRadius < 0) {
            0
        } else {
            clipCornerRadius
        }
        this.resolvedClipConstraints = ArrayList<CjguiComposableUiClipConstraint>(clipConstraints)
        this.declaredStyle = node.style
        this.style = if (let Some(value) <- resolvedPaintStyle) { value } else { node.style }
        this.textStyleRuns = node.textStyleRuns
        this.interactionStyle = node.interactionStyle
        this.ownerInteractionState = node.ownerInteractionState
        this.inputScopeId = if (node.layerId().size > 0) {
            node.layerId()
        } else {
            inputScopeId
        }
        this.layerId = node.layerId()
        this.layerKind = node.layerKind()
        this.identityKey = CjguiComposableUiLayoutNode.identityKeyFor(node)
        this.scopedIdentityValue = node.scopedIdentity()
    }

    /// The stable identity rule used by `identityKey` and by the clip constraint
    /// the layout engine records for a clipping node. Scoped declarations use
    /// their canonical scope/key; otherwise the semantic id, and only a node with
    /// neither falls back to its resolved numeric id.
    static func identityKeyFor(node: CjguiComposableUiNode): String {
        if (let Some(identity) <- node.scopedIdentity()) {
            if (identity.isValid()) {
                return identity.canonicalKey()
            }
        }
        if (node.semanticId.size > 0) {
            return "semantic:${node.semanticId}"
        }
        return "node:${node.nodeId}"
    }
    public static func missing(): CjguiComposableUiLayoutNode {
        return CjguiComposableUiLayoutNode(
            CjguiComposableUiNode(-1, "", CJGUI_COMPOSABLE_UI_TEXT, "", "", "", -1, CjguiComposableUiStyle()),
            CjguiComposableUiRect(0, 0, 0, 0),
            CjguiComposableUiRect(0, 0, 0, 0)
        )
    }
    public func acceptsInput(): Bool {
        return nodeKind == CJGUI_COMPOSABLE_UI_BUTTON || nodeKind == CJGUI_COMPOSABLE_UI_TEXT_INPUT || nodeKind ==
            CJGUI_COMPOSABLE_UI_INTEGER_INPUT || nodeKind == CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT || nodeKind ==
            CJGUI_COMPOSABLE_UI_BOOLEAN_INPUT || nodeKind == CJGUI_COMPOSABLE_UI_LAYER_BACKDROP || nodeKind ==
            CJGUI_COMPOSABLE_UI_SCROLL_AREA || nodeKind == CJGUI_COMPOSABLE_UI_SPLIT_HANDLE || nodeKind ==
            CJGUI_COMPOSABLE_UI_SLIDER || nodeKind == CJGUI_COMPOSABLE_UI_TAB_TITLE ||
            (nodeKind == CJGUI_COMPOSABLE_UI_VECTOR_GRAPHIC && actionName.size > 0)
    }
    public func clipConstraints(): ArrayList<CjguiComposableUiClipConstraint> {
        return ArrayList<CjguiComposableUiClipConstraint>(resolvedClipConstraints)
    }
    /// Create a paint-only snapshot for an already resolved layout node. This
    /// deliberately rebuilds no geometry or text metrics: every structural
    /// field is copied verbatim and callers supply only a style produced by
    /// `CjguiComposableUiInteractionStyle.resolve`.
    public func withResolvedPaintStyle(resolvedStyle: CjguiComposableUiStyle): CjguiComposableUiLayoutNode {
        let projectionNode = CjguiComposableUiNode(
            nodeId, semanticId, nodeKind, label, value, actionName, resourceId, declaredStyle,
            scrollViewport: scrollViewport, splitState: splitState,
            enabled: isEnabled, readOnly: isReadOnly, fieldId: fieldId,
            tabsState: tabsState, tabsPageKey: tabsPageKey, tabsPageActive: tabsPageActive,
            tabsTitleHeight: tabsTitleHeight,
            operationActionName: operationActionName, operationResourceId: operationResourceId,
            displayValueRole: displayValueRole, imageResourcePath: imageResourcePath,
            imageResourceId: imageResourceId, imageResourceVersion: imageResourceVersion,
            imageContentMode: imageContentMode, tabInsertsText: tabInsertsText,
            layerId: layerId, layerKind: layerKind, inputScopeId: inputScopeId,
            pointerControlRole: pointerControlRole, pointerControlAxis: pointerControlAxis,
            pointerControlMinimum: pointerControlMinimum, pointerControlMaximum: pointerControlMaximum,
            pointerControlStep: pointerControlStep, pointerControlHandleThickness: pointerControlHandleThickness,
            pointerControlFirstSize: pointerControlFirstSize, pointerControlSecondMinimum: pointerControlSecondMinimum,
            interactionStyle: interactionStyle, ownerInteractionState: ownerInteractionState,
            semanticIncarnation: semanticIncarnation,
            identity: scopedIdentityValue)
        return CjguiComposableUiLayoutNode(
            projectionNode, bounds, clip, inputScopeId: inputScopeId,
            clipCornerRadius: clipCornerRadius, clipConstraints: resolvedClipConstraints,
            resolvedPaintStyle: Some(resolvedStyle))
    }
    public func containsResolvedClip(x: Int64, y: Int64): Bool {
        if (!clip.contains(x, y)) {
            return false
        }
        for (constraint in resolvedClipConstraints) {
            if (!constraint.contains(x, y)) {
                return false
            }
        }
        return true
    }
    public func canReceiveInput(): Bool {
        return acceptsInput() && isEnabled && !isReadOnly
    }
    /// Read-only text remains a platform text target for focus, selection and
    /// copy.  It intentionally does not pass editable input events back to
    /// the controller.
    /// Whether this accepted node is a tab TITLE whose container bound shared tab
    /// view state. Activation is then a framework-owned view intent.
    public func isTabTitle(): Bool {
        return nodeKind == CJGUI_COMPOSABLE_UI_TAB_TITLE
    }
    /// Whether this accepted node IS a public tab container.
    public func isTabsContainer(): Bool {
        return nodeKind == CJGUI_COMPOSABLE_UI_TABS
    }
    /// Whether this accepted node is one PAGE of a tab container.
    public func isTabPage(): Bool {
        return tabsPageKey.size > 0
    }
    public func canReceiveFocus(): Bool {
        if (nodeKind == CJGUI_COMPOSABLE_UI_LAYER_BACKDROP) {
            return false
        }
        if (!isEnabled) {
            return false
        }
        // A pointer-interactive PRESENTATION text node owns a caret and receives product
        // key intents (e.g. Tab for table cell navigation), so it is focusable even though
        // it is not an editable input. Without this, the focus a click establishes is lost
        // on the next projection change and key intents have no target at all.
        if (nodeKind == CJGUI_COMPOSABLE_UI_TEXT && this.style.pointerInteractive) {
            return true
        }
        if (!isReadOnly) {
            return acceptsInput()
        }
        return nodeKind == CJGUI_COMPOSABLE_UI_TEXT_INPUT || nodeKind == CJGUI_COMPOSABLE_UI_INTEGER_INPUT ||
            nodeKind == CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT
    }
}

public class CjguiComposableUiScene {
    public let version: Int64
    public let viewport: CjguiComposableUiRect
    private let resolvedNodes: ArrayList<CjguiComposableUiLayoutNode>
    private let validValue: Bool
    private let layoutErrorValue: String
    public init(version: Int64, viewport: CjguiComposableUiRect, nodes: ArrayList<CjguiComposableUiLayoutNode>,
        valid!: Bool = true, layoutError!: String = "") {
        this.version = version
        this.viewport = viewport
        this.resolvedNodes = ArrayList<CjguiComposableUiLayoutNode>(nodes)
        this.validValue = valid
        this.layoutErrorValue = layoutError
    }
    public func nodes(): ArrayList<CjguiComposableUiLayoutNode> {
        return ArrayList<CjguiComposableUiLayoutNode>(resolvedNodes)
    }
    public func isValid(): Bool {
        return validValue
    }
    public func layoutError(): String {
        return layoutErrorValue
    }
    public func nodeForId(nodeId: Int64): CjguiComposableUiLayoutNode {
        for (node in resolvedNodes) {
            if (node.nodeId == nodeId) {
                return node
            }
        }
        return CjguiComposableUiLayoutNode.missing()
    }
    public func resolveInput(nodeId: Int64, resourceId: Int64, nodeKind: Int64, projectionVersion: Int64): CjguiComposableUiLayoutNode {
        if (!validValue || projectionVersion != version) {
            return CjguiComposableUiLayoutNode.missing()
        }
        let node = nodeForId(nodeId)
        if (!node.canReceiveInput() || node.resourceId != resourceId || node.nodeKind != nodeKind) {
            return CjguiComposableUiLayoutNode.missing()
        }
        return node
    }
    /// Resolve a node that opted into pointer reporting but is deliberately NOT
    /// an input. A read-only presentation surface needs click coordinates, yet
    /// `resolveInput` refuses anything that cannot receive editable input, which
    /// left its ACTIVATE/FOCUS events rejected before reaching the controller.
    /// Identity and version checks stay identical to `resolveInput`.
    public func resolvePointerTarget(nodeId: Int64, resourceId: Int64, nodeKind: Int64,
        projectionVersion: Int64): CjguiComposableUiLayoutNode {
        if (!validValue || projectionVersion != version) {
            return CjguiComposableUiLayoutNode.missing()
        }
        let node = nodeForId(nodeId)
        if (node.resourceId != resourceId || node.nodeKind != nodeKind) {
            return CjguiComposableUiLayoutNode.missing()
        }
        if (!node.canReceiveInput() && !node.style.pointerInteractive) {
            return CjguiComposableUiLayoutNode.missing()
        }
        return node
    }
    /// Platform-owned selection is not an edit. Allow it for an enabled
    /// read-only text field while retaining the same full identity/version
    /// check used for editable input.
    public func resolveSelection(nodeId: Int64, resourceId: Int64, nodeKind: Int64, projectionVersion: Int64): CjguiComposableUiLayoutNode {
        if (!validValue || projectionVersion != version) {
            return CjguiComposableUiLayoutNode.missing()
        }
        let node = nodeForId(nodeId)
        let isText = node.nodeKind == CJGUI_COMPOSABLE_UI_TEXT_INPUT || node.nodeKind ==
            CJGUI_COMPOSABLE_UI_INTEGER_INPUT || node.nodeKind == CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT
        if (!isText || !node.isEnabled || node.resourceId != resourceId || node.nodeKind != nodeKind) {
            return CjguiComposableUiLayoutNode.missing()
        }
        return node
    }
    public func hitTest(x: Int64, y: Int64): CjguiComposableUiLayoutNode {
        if (!validValue) {
            return CjguiComposableUiLayoutNode.missing()
        }
        // Prefer the INNERMOST input-capable node under the point, not merely the last node in resolved
        // order. A scroll area / column that CONTAINS interactive text is itself input-capable, so it used
        // to win this loop and swallow clicks meant for the text inside it (measured 2026-09-25: a click on
        // a body fragment delivered the event to the scroll node 311 and the caret never moved). The
        // smallest containing area is the innermost target; ties keep the previous topmost preference.
        var best = CjguiComposableUiLayoutNode.missing()
        var bestArea: Int64 = 0
        var found = false
        var index = resolvedNodes.size - 1
        while (index >= 0) {
            let node = resolvedNodes[index]
            if (node.canReceiveInput() && node.bounds.contains(x, y) && node.containsResolvedClip(x, y)) {
                let area = node.bounds.width * node.bounds.height
                if (!found || area < bestArea) {
                    best = node
                    bestArea = area
                    found = true
                }
            }
            index -= 1
        }
        return best
    }
    public func focusScopeForNode(nodeId: Int64): String {
        return nodeForId(nodeId).inputScopeId
    }
}

/// Per-turn drain bound shared by the window event loop and its platform-free
/// probe.  Native keeps the FIFO bounded too, but this second bound ensures a
/// continuous producer cannot prevent projection, external connection work or
/// the next macOS run-loop turn from running.
public class CjguiComposableUiEventDrainBudget {
    private var remaining: Int64
    public init(limit!: Int64 = 64) {
        this.remaining = if (limit > 0) {
            limit
        } else {
            1
        }
    }
    public func consumeOne(): Bool {
        if (remaining <= 0) {
            return false
        }
        remaining -= 1
        return true
    }
}

/// A measurement result is deliberately scalar and platform-neutral.  The
/// normal macOS window injects an AppKit implementation; tests and headless
/// component construction use the rune-aware fallback below.
public class CjguiComposableUiTextMeasurement {
    public let width: Int64
    public let height: Int64
    public let lineHeight: Int64
    public let baseline: Int64
    public init(width: Int64, height: Int64, lineHeight: Int64, baseline: Int64) {
        this.width = if (width < 0) {
            0
        } else {
            width
        }
        this.height = if (height < 0) {
            0
        } else {
            height
        }
        this.lineHeight = if (lineHeight < 1) {
            1
        } else {
            lineHeight
        }
        this.baseline = if (baseline < 0) {
            0
        } else {
            baseline
        }
    }
}

public interface CjguiComposableUiTextMeasurer {
    func measure(value: String, style: CjguiComposableUiStyle, maximumWidth: Int64): CjguiComposableUiTextMeasurement
}

/// Preview opt-in for the content height of a multiline input at its resolved
/// content width. The four-metric text query retains its existing semantics.
/// `None` means this query failed; callers may calculate a temporary fallback,
/// but a production measurer must reject the candidate through its status.
public interface CjguiComposableUiMultilineNaturalHeightMeasurer {
    func multilineNaturalContentHeight(value: String, style: CjguiComposableUiStyle,
        contentWidth: Int64): ?Int64
}

/// An opt-in invalidation contract for a cross-pass layout cache. A text
/// measurer that cannot provide a stable value for its actual font/platform
/// environment remains fully usable, but its regions stay canonical across
/// passes. Implementors must advance this key when any measurement result can
/// change independently of the Cangjie component tree.
public interface CjguiComposableUiLayoutMeasurementEnvironment {
    func layoutMeasurementEnvironmentKey(): String
}

/// A deterministic fallback for non-AppKit execution.  It counts Unicode
/// runes (not UTF-8 bytes), joins combining marks with their base glyph, and
/// intentionally treats wide CJK ranges as two text units. Production layout
/// never relies on this estimate once a renderer session exists.
public class CjguiComposableUiFallbackTextMeasurer <: CjguiComposableUiTextMeasurer & CjguiComposableUiLayoutMeasurementEnvironment {
    public func layoutMeasurementEnvironmentKey(): String {
        return "cjgui-fallback-text-v1"
    }
    public func measure(value: String, style: CjguiComposableUiStyle, maximumWidth: Int64): CjguiComposableUiTextMeasurement {
        let lineHeight = if (Int64(style.fontSize * 1.30) > 1) {
            Int64(style.fontSize * 1.30)
        } else {
            1
        }
        let baseline = if (Int64(style.fontSize * 0.98) > 0) {
            Int64(style.fontSize * 0.98)
        } else {
            0
        }
        var units: Int64 = 0
        for (rune in value.runes()) {
            let scalar = UInt32(rune)
            if (scalar >= 0x0300u32 && scalar <= 0x036Fu32) {
                continue
            }
            if ((scalar >= 0x1100u32 && scalar <= 0x115Fu32) || (scalar >= 0x2E80u32 && scalar <= 0xA4CFu32) || (scalar >=
                0xAC00u32 && scalar <= 0xD7A3u32) || (scalar >= 0xF900u32 && scalar <= 0xFAFFu32) || (scalar >= 0xFE10u32 &&
                scalar <= 0xFE6Fu32) || (scalar >= 0xFF01u32 && scalar <= 0xFF60u32)) {
                units += 2
            } else {
                units += 1
            }
        }
        let glyphUnit = if (Int64(style.fontSize * 0.55) > 1) {
            Int64(style.fontSize * 0.55)
        } else {
            1
        }
        let intrinsic = units * glyphUnit
        let constrained = if (maximumWidth > 0 && maximumWidth < intrinsic) {
            maximumWidth
        } else {
            intrinsic
        }
        let lines = if (maximumWidth > 0 && intrinsic > maximumWidth) {
            (intrinsic + maximumWidth - 1) / maximumWidth
        } else {
            1
        }
        return CjguiComposableUiTextMeasurement(constrained, lines * lineHeight, lineHeight, baseline)
    }
}

/// Read-only work observed while resolving one component tree. These counters
/// describe derived calculation only; they are never stored in a component,
/// renderer scene, or application domain.
public class CjguiComposableUiLayoutMetrics {
    public let measurementRequestCount: Int64
    public let measurerCallCount: Int64
    public let measurementReuseHitCount: Int64
    public let recursiveNodeLayoutCount: Int64
    public let verticalContainerSolveCount: Int64
    public let horizontalContainerSolveCount: Int64
    public let layerHostSolveCount: Int64
    public let scrollAreaSolveCount: Int64
    /// A cross-pass region hit replays immutable resolved layout nodes. It
    /// never means the controller skipped building its current value tree.
    public let subtreeReuseHitCount: Int64
    public let subtreeReuseMissCount: Int64
    /// Signature traversal is reported separately from solver recursion so a
    /// cache hit cannot be presented as no Cangjie work at all.
    public let subtreeReuseRevalidationNodeCount: Int64
    public let subtreeReuseReplayedNodeCount: Int64
    public let subtreeReuseEntryCount: Int64
    /// All retained values are scalar layout output. These counts include
    /// copied node/string payload estimates rather than only signature text.
    public let subtreeReuseRetainedNodeCount: Int64
    public let subtreeReuseRetainedStringBytes: Int64
    public let subtreeReuseRetainedBytes: Int64
    /// Pending candidates are never accepted state. They are exposed only so
    /// test/report paths can prove the same bounds apply before commit.
    public let subtreeReusePendingNodeCount: Int64
    public let subtreeReusePendingStringBytes: Int64
    public let subtreeReusePendingBytes: Int64
    public let subtreeReuseBudgetSkipCount: Int64
    public init(
        measurementRequestCount: Int64,
        measurerCallCount: Int64,
        measurementReuseHitCount: Int64,
        recursiveNodeLayoutCount: Int64,
        verticalContainerSolveCount: Int64,
        horizontalContainerSolveCount: Int64,
        layerHostSolveCount: Int64,
        scrollAreaSolveCount: Int64,
        subtreeReuseHitCount!: Int64 = 0,
        subtreeReuseMissCount!: Int64 = 0,
        subtreeReuseRevalidationNodeCount!: Int64 = 0,
        subtreeReuseReplayedNodeCount!: Int64 = 0,
        subtreeReuseEntryCount!: Int64 = 0,
        subtreeReuseRetainedNodeCount!: Int64 = 0,
        subtreeReuseRetainedStringBytes!: Int64 = 0,
        subtreeReuseRetainedBytes!: Int64 = 0,
        subtreeReusePendingNodeCount!: Int64 = 0,
        subtreeReusePendingStringBytes!: Int64 = 0,
        subtreeReusePendingBytes!: Int64 = 0,
        subtreeReuseBudgetSkipCount!: Int64 = 0
    ) {
        this.measurementRequestCount = measurementRequestCount
        this.measurerCallCount = measurerCallCount
        this.measurementReuseHitCount = measurementReuseHitCount
        this.recursiveNodeLayoutCount = recursiveNodeLayoutCount
        this.verticalContainerSolveCount = verticalContainerSolveCount
        this.horizontalContainerSolveCount = horizontalContainerSolveCount
        this.layerHostSolveCount = layerHostSolveCount
        this.scrollAreaSolveCount = scrollAreaSolveCount
        this.subtreeReuseHitCount = subtreeReuseHitCount
        this.subtreeReuseMissCount = subtreeReuseMissCount
        this.subtreeReuseRevalidationNodeCount = subtreeReuseRevalidationNodeCount
        this.subtreeReuseReplayedNodeCount = subtreeReuseReplayedNodeCount
        this.subtreeReuseEntryCount = subtreeReuseEntryCount
        this.subtreeReuseRetainedNodeCount = subtreeReuseRetainedNodeCount
        this.subtreeReuseRetainedStringBytes = subtreeReuseRetainedStringBytes
        this.subtreeReuseRetainedBytes = subtreeReuseRetainedBytes
        this.subtreeReusePendingNodeCount = subtreeReusePendingNodeCount
        this.subtreeReusePendingStringBytes = subtreeReusePendingStringBytes
        this.subtreeReusePendingBytes = subtreeReusePendingBytes
        this.subtreeReuseBudgetSkipCount = subtreeReuseBudgetSkipCount
    }
}

/// Experimental diagnostic result. Normal application paths continue to use
/// `layout` and retain only the returned canonical scene.
public class CjguiComposableUiLayoutResult {
    public let scene: CjguiComposableUiScene
    public let metrics: CjguiComposableUiLayoutMetrics
    /// The public scroll viewports this solve STAGED candidate facts for. The
    /// window promotes them with the scene it accepts and discards them when it
    /// rejects the candidate, so no caller has to remember a rollback.
    public let viewports: ArrayList<CjguiComposableUiScrollViewport>
    /// The public split instances this solve STAGED candidate track facts for,
    /// promoted and discarded with the same scene as `viewports`.
    public let splitTracks: ArrayList<CjguiComposableUiSplitTrackFact>
    public init(scene: CjguiComposableUiScene, metrics: CjguiComposableUiLayoutMetrics,
        viewports!: ArrayList<CjguiComposableUiScrollViewport> = ArrayList<CjguiComposableUiScrollViewport>(),
        splitTracks!: ArrayList<CjguiComposableUiSplitTrackFact> = ArrayList<CjguiComposableUiSplitTrackFact>()) {
        this.scene = scene
        this.metrics = metrics
        this.viewports = viewports
        this.splitTracks = splitTracks
    }
}

private class CjguiComposableUiLayoutWorkCounter {
    var recursiveNodeLayoutCount: Int64 = 0
    var verticalContainerSolveCount: Int64 = 0
    var horizontalContainerSolveCount: Int64 = 0
    var layerHostSolveCount: Int64 = 0
    var scrollAreaSolveCount: Int64 = 0
    /// Hidden tab pages this solve presented WITHOUT measuring or drawing them.
    var hiddenTabPageCount: Int64 = 0
    var clipConstraintCapacityExceeded: Bool = false
    var dynamicIdentityIssue: String = ""
    /// Distinct public viewports staged by this solve.
    var stagedViewports: ArrayList<CjguiComposableUiScrollViewport> = ArrayList<CjguiComposableUiScrollViewport>()
    /// Candidate split track facts staged by this solve.
    var stagedSplitTracks: ArrayList<CjguiComposableUiSplitTrackFact> =
        ArrayList<CjguiComposableUiSplitTrackFact>()
}

/// One immutable, Cangjie-owned entry for a stable top-level composition
/// region. It retains resolved scalar layout nodes, never a component node,
/// native handle, renderer scene, or business owner.
private class CjguiComposableUiLayoutReuseCacheEntry {
    let regionNodeId: Int64
    let signature: String
    let nodes: ArrayList<CjguiComposableUiLayoutNode>
    let retainedNodeCount: Int64
    let retainedStringBytes: Int64
    let retainedBytes: Int64
    init(regionNodeId: Int64, signature: String, nodes: ArrayList<CjguiComposableUiLayoutNode>,
        retainedNodeCount: Int64, retainedStringBytes: Int64, retainedBytes: Int64) {
        this.regionNodeId = regionNodeId
        this.signature = signature
        this.nodes = ArrayList<CjguiComposableUiLayoutNode>(nodes)
        this.retainedNodeCount = retainedNodeCount
        this.retainedStringBytes = retainedStringBytes
        this.retainedBytes = retainedBytes
    }
}

/// Exact string payload accounting plus a conservative scalar-node envelope.
/// It is intentionally derived from resolved output instead of from the
/// signature: a short caller key must never evade the retained-output cap.
private class CjguiComposableUiLayoutReuseRetention {
    let nodeCount: Int64
    let stringBytes: Int64
    let totalBytes: Int64
    init(nodeCount: Int64, stringBytes: Int64, totalBytes: Int64) {
        this.nodeCount = nodeCount
        this.stringBytes = stringBytes
        this.totalBytes = totalBytes
    }
}

class CjguiComposableUiLayoutReuseSignature {
    let regionNodeId: Int64
    let isCacheable: Bool
    let value: String
    let nodeCount: Int64
    init(regionNodeId: Int64, isCacheable: Bool, value: String, nodeCount: Int64) {
        this.regionNodeId = regionNodeId
        this.isCacheable = isCacheable
        this.value = value
        this.nodeCount = nodeCount
    }
}

/// Optional cross-pass cache for stable composition regions. The canonical
/// solver still owns every resolved scene; this cache only replays a prior
/// region when its current value-derived signature, bounds, clip chain and
/// inherited input scope are all exact matches. The fixed entry and byte caps
/// deliberately decline reuse for unbounded text rather than retaining it.
public class CjguiComposableUiLayoutReuseCache {
    private let maximumEntryCount: Int64
    private let maximumSignatureBytes: Int64
    private let maximumRetainedNodeCount: Int64
    private let maximumRetainedStringBytes: Int64
    private let maximumRetainedBytes: Int64
    // Full structural signatures walk and encode every direct region. They
    // remain available only for diagnostics; production caches require the
    // caller's explicit stable-region key before doing cross-pass work.
    private let permitsStructuralSignatures: Bool
    private var entries: ArrayList<CjguiComposableUiLayoutReuseCacheEntry>
    private var pendingEntries: ArrayList<CjguiComposableUiLayoutReuseCacheEntry>
    private var passHitCountValue: Int64
    private var passMissCountValue: Int64
    private var passRevalidationNodeCountValue: Int64
    private var passReplayedNodeCountValue: Int64
    private var retainedNodeCountValue: Int64
    private var retainedStringBytesValue: Int64
    private var retainedBytesValue: Int64
    private var pendingNodeCountValue: Int64
    private var pendingStringBytesValue: Int64
    private var pendingBytesValue: Int64
    private var passBudgetSkipCountValue: Int64

    public init(maxEntries!: Int64 = 4, maxSignatureBytes!: Int64 = 262144, maxRetainedNodes!: Int64 = 1024,
        maxRetainedStringBytes!: Int64 = 262144, maxRetainedBytes!: Int64 = 524288,
        allowStructuralSignatures!: Bool = false) {
        this.maximumEntryCount = if (maxEntries < 1) {
            1
        } else if (maxEntries > 8) {
            8
        } else {
            maxEntries
        }
        this.maximumSignatureBytes = if (maxSignatureBytes < 1024) {
            1024
        } else if (maxSignatureBytes > 524288) {
            524288
        } else {
            maxSignatureBytes
        }
        this.maximumRetainedNodeCount = if (maxRetainedNodes < 1) {
            1
        } else if (maxRetainedNodes > 8192) {
            8192
        } else {
            maxRetainedNodes
        }
        this.maximumRetainedStringBytes = if (maxRetainedStringBytes < 1024) {
            1024
        } else if (maxRetainedStringBytes > 524288) {
            524288
        } else {
            maxRetainedStringBytes
        }
        this.maximumRetainedBytes = if (maxRetainedBytes < 4096) {
            4096
        } else if (maxRetainedBytes > 1048576) {
            1048576
        } else {
            maxRetainedBytes
        }
        this.permitsStructuralSignatures = allowStructuralSignatures
        this.entries = ArrayList<CjguiComposableUiLayoutReuseCacheEntry>()
        this.pendingEntries = ArrayList<CjguiComposableUiLayoutReuseCacheEntry>()
        this.passHitCountValue = 0
        this.passMissCountValue = 0
        this.passRevalidationNodeCountValue = 0
        this.passReplayedNodeCountValue = 0
        this.retainedNodeCountValue = 0
        this.retainedStringBytesValue = 0
        this.retainedBytesValue = 0
        this.pendingNodeCountValue = 0
        this.pendingStringBytesValue = 0
        this.pendingBytesValue = 0
        this.passBudgetSkipCountValue = 0
    }

    /// A failed solve never promotes its candidate entries. Existing accepted
    /// entries remain derived data and can only be used after their full
    /// signature is revalidated on a later successful solve.
    func beginPass(): Unit {
        pendingEntries.clear()
        pendingNodeCountValue = 0
        pendingStringBytesValue = 0
        pendingBytesValue = 0
        passHitCountValue = 0
        passMissCountValue = 0
        passRevalidationNodeCountValue = 0
        passReplayedNodeCountValue = 0
        passBudgetSkipCountValue = 0
    }

    func discardPass(): Unit {
        pendingEntries.clear()
        pendingNodeCountValue = 0
        pendingStringBytesValue = 0
        pendingBytesValue = 0
    }

    func commitPass(): Unit {
        for (candidate in pendingEntries) {
            var existingIndex: Int64 = 0
            while (existingIndex < entries.size) {
                if (entries[existingIndex].regionNodeId == candidate.regionNodeId) {
                    removeAcceptedEntry(existingIndex)
                    break
                }
                existingIndex += 1
            }
            while (entries.size >= maximumEntryCount || retainedNodeCountValue + candidate.retainedNodeCount >
                    maximumRetainedNodeCount || retainedStringBytesValue + candidate.retainedStringBytes >
                    maximumRetainedStringBytes || retainedBytesValue + candidate.retainedBytes > maximumRetainedBytes) {
                if (entries.size == 0) {
                    passBudgetSkipCountValue += 1
                    break
                }
                removeAcceptedEntry(0)
            }
            if (candidateFits(candidate)) {
                entries.add(candidate)
                retainedNodeCountValue += candidate.retainedNodeCount
                retainedStringBytesValue += candidate.retainedStringBytes
                retainedBytesValue += candidate.retainedBytes
            }
        }
        pendingEntries.clear()
        pendingNodeCountValue = 0
        pendingStringBytesValue = 0
        pendingBytesValue = 0
    }

    func signatureFor(node: CjguiComposableUiNode, bounds: CjguiComposableUiRect,
        parentClipConstraints: ArrayList<CjguiComposableUiClipConstraint>, inheritedInputScope: String,
        measurementEnvironmentKey: String): CjguiComposableUiLayoutReuseSignature {
        // An arbitrary `TextMeasurer` has no identity or generation contract.
        // Declining it is the only safe public default for a shared cache.
        if (measurementEnvironmentKey.size == 0) {
            return CjguiComposableUiLayoutReuseSignature(node.nodeId, false, "", 0)
        }
        let explicitReuseKey = node.layoutReuseKey()
        if (explicitReuseKey.size == 0 && !permitsStructuralSignatures) {
            return CjguiComposableUiLayoutReuseSignature(node.nodeId, false, "", 0)
        }
        let builder = StringBuilder(256)
        let byteCount = ArrayList<Int64>([0])
        let nodeCount = ArrayList<Int64>([0])
        let cacheable = ArrayList<Bool>([true])
        appendString(builder, byteCount, cacheable, "layout-region-v2")
        appendString(builder, byteCount, cacheable, measurementEnvironmentKey)
        appendRect(builder, byteCount, cacheable, bounds)
        appendString(builder, byteCount, cacheable, inheritedInputScope)
        appendInt(builder, byteCount, cacheable, parentClipConstraints.size)
        for (constraint in parentClipConstraints) {
            appendRect(builder, byteCount, cacheable, constraint.rect)
            appendInt(builder, byteCount, cacheable, constraint.cornerRadius)
        }
        // Opt-in keys are only accepted for ordinary regions. The caller
        // must include every relevant descendant input in the key; bounds,
        // clipping and inherited scope remain engine-owned and are always
        // included above. Layer hosts and scroll areas stay canonical because
        // their output depends on anchor ordering or mutable materialization.
        if (explicitReuseKey.size > 0 && node.nodeKind != CJGUI_COMPOSABLE_UI_SCROLL_AREA && node.nodeKind !=
            CJGUI_COMPOSABLE_UI_LAYER_HOST && node.layerId().size == 0 && node.layerKind().size == 0 &&
            !containsNonCacheableDescendant(node, nodeCount)) {
            appendString(builder, byteCount, cacheable, "layout-region-key-v1")
            appendInt(builder, byteCount, cacheable, node.nodeId)
            appendInt(builder, byteCount, cacheable, node.nodeKind)
            appendString(builder, byteCount, cacheable, node.semanticId)
            appendString(builder, byteCount, cacheable, explicitReuseKey)
        } else {
            if (!permitsStructuralSignatures) {
                // An explicit key may still have required a descendant scan
                // before it was rejected (for example nested scroll/layer).
                // Keep that actual safety work visible in the pass metrics.
                return CjguiComposableUiLayoutReuseSignature(node.nodeId, false, "", nodeCount[0])
            }
            appendNode(builder, byteCount, nodeCount, cacheable, node)
        }
        return CjguiComposableUiLayoutReuseSignature(node.nodeId, cacheable[0], if (cacheable[0]) {
            builder.toString()
        } else {
            ""
        }, nodeCount[0])
    }

    func replay(signature: CjguiComposableUiLayoutReuseSignature): ?ArrayList<CjguiComposableUiLayoutNode> {
        passRevalidationNodeCountValue += signature.nodeCount
        if (!signature.isCacheable) {
            return None
        }
        for (entry in entries) {
            if (entry.signature == signature.value) {
                passHitCountValue += 1
                passReplayedNodeCountValue += entry.nodes.size
                return Some(ArrayList<CjguiComposableUiLayoutNode>(entry.nodes))
            }
        }
        passMissCountValue += 1
        return None
    }

    func stage(signature: CjguiComposableUiLayoutReuseSignature, nodes: ArrayList<CjguiComposableUiLayoutNode>): Unit {
        if (!signature.isCacheable || nodes.size == 0) {
            return
        }
        let retention = retentionFor(nodes, signature.value.size)
        let candidate = CjguiComposableUiLayoutReuseCacheEntry(signature.regionNodeId, signature.value, nodes,
            retention.nodeCount, retention.stringBytes, retention.totalBytes)
        var existingIndex: Int64 = 0
        var priorNodeCount: Int64 = 0
        var priorStringBytes: Int64 = 0
        var priorBytes: Int64 = 0
        while (existingIndex < pendingEntries.size) {
            let existing = pendingEntries[existingIndex]
            if (existing.regionNodeId == signature.regionNodeId) {
                priorNodeCount = existing.retainedNodeCount
                priorStringBytes = existing.retainedStringBytes
                priorBytes = existing.retainedBytes
                break
            }
            existingIndex += 1
        }
        if (!candidateFits(candidate) || pendingNodeCountValue - priorNodeCount + candidate.retainedNodeCount >
            maximumRetainedNodeCount || pendingStringBytesValue - priorStringBytes + candidate.retainedStringBytes >
            maximumRetainedStringBytes || pendingBytesValue - priorBytes + candidate.retainedBytes > maximumRetainedBytes) {
            passBudgetSkipCountValue += 1
            return
        }
        if (existingIndex < pendingEntries.size) {
            let _ = pendingEntries.remove(at: existingIndex)
            pendingNodeCountValue -= priorNodeCount
            pendingStringBytesValue -= priorStringBytes
            pendingBytesValue -= priorBytes
        }
        pendingEntries.add(candidate)
        pendingNodeCountValue += candidate.retainedNodeCount
        pendingStringBytesValue += candidate.retainedStringBytes
        pendingBytesValue += candidate.retainedBytes
    }

    func passHitCount(): Int64 {
        return passHitCountValue
    }
    func passMissCount(): Int64 {
        return passMissCountValue
    }
    func passRevalidationNodeCount(): Int64 {
        return passRevalidationNodeCountValue
    }
    func passReplayedNodeCount(): Int64 {
        return passReplayedNodeCountValue
    }
    func entryCount(): Int64 {
        return entries.size
    }
    func retainedNodeCount(): Int64 {
        return retainedNodeCountValue
    }
    func retainedStringBytes(): Int64 {
        return retainedStringBytesValue
    }
    func retainedBytes(): Int64 {
        return retainedBytesValue
    }
    func pendingNodeCount(): Int64 {
        return pendingNodeCountValue
    }
    func pendingStringBytes(): Int64 {
        return pendingStringBytesValue
    }
    func pendingBytes(): Int64 {
        return pendingBytesValue
    }
    func passBudgetSkipCount(): Int64 {
        return passBudgetSkipCountValue
    }

    private func candidateFits(candidate: CjguiComposableUiLayoutReuseCacheEntry): Bool {
        return candidate.retainedNodeCount <= maximumRetainedNodeCount && candidate.retainedStringBytes <=
            maximumRetainedStringBytes && candidate.retainedBytes <= maximumRetainedBytes
    }

    private func removeAcceptedEntry(index: Int64): Unit {
        let removed = entries.remove(at: index)
        retainedNodeCountValue -= removed.retainedNodeCount
        retainedStringBytesValue -= removed.retainedStringBytes
        retainedBytesValue -= removed.retainedBytes
    }

    private func retentionFor(nodes: ArrayList<CjguiComposableUiLayoutNode>, signatureBytes: Int64): CjguiComposableUiLayoutReuseRetention {
        var stringBytes: Int64 = 0
        var scalarBytes: Int64 = signatureBytes
        for (node in nodes) {
            stringBytes += node.semanticId.size + node.label.size + node.value.size + node.actionName.size + node
                .fieldId
                .size + node.operationActionName.size + node.displayValueRole.size + node.imageResourcePath.size + node
                .imageResourceId
                .size + node.style.fontFamily.size + node.inputScopeId.size + node.layerId.size + node.layerKind.size
            // Fixed scalar/array headers plus all retained clipping scalars.
            scalarBytes += 320 + node.clipConstraints().size * 40
        }
        return CjguiComposableUiLayoutReuseRetention(nodes.size, stringBytes, scalarBytes + stringBytes)
    }

    private func containsNonCacheableDescendant(node: CjguiComposableUiNode, nodeCount: ArrayList<Int64>): Bool {
        nodeCount[0] += 1
        if (node.nodeKind == CJGUI_COMPOSABLE_UI_SCROLL_AREA || node.nodeKind == CJGUI_COMPOSABLE_UI_LAYER_HOST ||
            node.layerId().size > 0 || node.layerKind().size > 0) {
            return true
        }
        for (child in node.children()) {
            if (containsNonCacheableDescendant(child, nodeCount)) {
                return true
            }
        }
        return false
    }

    private func appendNode(builder: StringBuilder, byteCount: ArrayList<Int64>, nodeCount: ArrayList<Int64>,
        cacheable: ArrayList<Bool>, node: CjguiComposableUiNode): Unit {
        if (!cacheable[0]) {
            return
        }
        nodeCount[0] += 1
        // Virtual materialization mutates its transient child range during a
        // solve, while layer bounds depend on sibling anchor output. Neither
        // is safe to replay as an independent region.
        if (node.nodeKind == CJGUI_COMPOSABLE_UI_SCROLL_AREA || node.nodeKind == CJGUI_COMPOSABLE_UI_LAYER_HOST ||
            node.layerId().size > 0 || node.layerKind().size > 0) {
            cacheable[0] = false
            return
        }
        appendInt(builder, byteCount, cacheable, node.nodeId)
        appendInt(builder, byteCount, cacheable, node.nodeKind)
        appendString(builder, byteCount, cacheable, node.semanticId)
        appendString(builder, byteCount, cacheable, node.label)
        appendString(builder, byteCount, cacheable, node.value)
        appendString(builder, byteCount, cacheable, node.actionName)
        appendInt(builder, byteCount, cacheable, node.resourceId)
        appendInt(builder, byteCount, cacheable, node.semanticIncarnation)
        appendString(builder, byteCount, cacheable, node.fieldId)
        appendString(builder, byteCount, cacheable, node.operationActionName)
        appendInt(builder, byteCount, cacheable, node.operationResourceId)
        appendString(builder, byteCount, cacheable, node.displayValueRole)
        appendString(builder, byteCount, cacheable, node.imageResourcePath)
        appendString(builder, byteCount, cacheable, node.imageResourceId)
        appendInt(builder, byteCount, cacheable, node.imageResourceVersion)
        appendInt(builder, byteCount, cacheable, node.imageContentMode)
        appendBool(builder, byteCount, cacheable, node.isEnabled)
        appendBool(builder, byteCount, cacheable, node.isReadOnly)
        appendBool(builder, byteCount, cacheable, node.tabInsertsText)
        appendInt(builder, byteCount, cacheable, node.scrollOffset)
        // A split's current first-pane size lives in its shared view state, not
        // in the declaration, so a divider size change must invalidate a cached
        // region even though the node tree itself was not rebuilt.
        appendInt(builder, byteCount, cacheable, if (let Some(state) <- node.splitState) {
            state.firstSize()
        } else {
            0
        })
        appendInt(builder, byteCount, cacheable, node.layoutHeightOverride())
        appendInt(builder, byteCount, cacheable, node.virtualContentHeight())
        appendInt(builder, byteCount, cacheable, node.virtualVerticalOrigin())
        appendString(builder, byteCount, cacheable, node.explicitInputScopeId())
        appendStyle(builder, byteCount, cacheable, node.style)
        let children = node.children()
        appendInt(builder, byteCount, cacheable, children.size)
        for (child in children) {
            appendNode(builder, byteCount, nodeCount, cacheable, child)
        }
    }

    private func appendStyle(builder: StringBuilder, byteCount: ArrayList<Int64>, cacheable: ArrayList<Bool>,
        style: CjguiComposableUiStyle): Unit {
        appendColor(builder, byteCount, cacheable, style.background)
        appendColor(builder, byteCount, cacheable, style.border)
        appendColor(builder, byteCount, cacheable, style.textColor)
        appendInt(builder, byteCount, cacheable, style.padding)
        appendInt(builder, byteCount, cacheable, style.gap)
        appendInt(builder, byteCount, cacheable, style.fixedWidth)
        appendInt(builder, byteCount, cacheable, style.fixedHeight)
        appendInt(builder, byteCount, cacheable, style.growX)
        appendInt(builder, byteCount, cacheable, style.growY)
        appendInt(builder, byteCount, cacheable, style.borderWidth)
        appendInt(builder, byteCount, cacheable, style.cornerRadius)
        appendBool(builder, byteCount, cacheable, style.clipsContent)
        appendFloat(builder, byteCount, cacheable, style.fontSize)
        appendInt(builder, byteCount, cacheable, style.fontWeight)
        appendString(builder, byteCount, cacheable, style.fontFamily)
        appendInt(builder, byteCount, cacheable, style.minWidth)
        appendInt(builder, byteCount, cacheable, style.maxWidth)
        appendInt(builder, byteCount, cacheable, style.idealWidth)
        appendInt(builder, byteCount, cacheable, style.minHeight)
        appendInt(builder, byteCount, cacheable, style.maxHeight)
        appendInt(builder, byteCount, cacheable, style.idealHeight)
        appendInt(builder, byteCount, cacheable, style.alignX)
        appendInt(builder, byteCount, cacheable, style.alignY)
    }

    private func appendColor(builder: StringBuilder, byteCount: ArrayList<Int64>, cacheable: ArrayList<Bool>,
        color: CjguiComposableUiColor): Unit {
        appendFloat(builder, byteCount, cacheable, color.red)
        appendFloat(builder, byteCount, cacheable, color.green)
        appendFloat(builder, byteCount, cacheable, color.blue)
        appendFloat(builder, byteCount, cacheable, color.alpha)
    }

    private func appendRect(builder: StringBuilder, byteCount: ArrayList<Int64>, cacheable: ArrayList<Bool>,
        rect: CjguiComposableUiRect): Unit {
        appendInt(builder, byteCount, cacheable, rect.x)
        appendInt(builder, byteCount, cacheable, rect.y)
        appendInt(builder, byteCount, cacheable, rect.width)
        appendInt(builder, byteCount, cacheable, rect.height)
    }

    private func appendBool(builder: StringBuilder, byteCount: ArrayList<Int64>, cacheable: ArrayList<Bool>, value: Bool): Unit {
        appendInt(builder, byteCount, cacheable, if (value) {
            1
        } else {
            0
        })
    }

    private func appendInt(builder: StringBuilder, byteCount: ArrayList<Int64>, cacheable: ArrayList<Bool>, value: Int64): Unit {
        appendScalar(builder, byteCount, cacheable, value.toString())
    }

    private func appendFloat(builder: StringBuilder, byteCount: ArrayList<Int64>, cacheable: ArrayList<Bool>,
        value: Float64): Unit {
        appendScalar(builder, byteCount, cacheable, value.toString())
    }

    /// Numeric values are emitted in a fixed field order with an unambiguous
    /// delimiter, so their exact UTF-8 bytes can count toward the cache cap
    /// without the deliberately conservative string-field framing overhead.
    private func appendScalar(builder: StringBuilder, byteCount: ArrayList<Int64>, cacheable: ArrayList<Bool>,
        value: String): Unit {
        if (!cacheable[0]) {
            return
        }
        byteCount[0] += value.size + 1
        if (byteCount[0] > maximumSignatureBytes) {
            cacheable[0] = false
            return
        }
        builder.append(value)
        builder.append("|")
    }

    private func appendString(builder: StringBuilder, byteCount: ArrayList<Int64>, cacheable: ArrayList<Bool>,
        value: String): Unit {
        if (!cacheable[0]) {
            return
        }
        // The decimal byte length, colon and trailing separator are all
        // counted. `String.size` is UTF-8 byte length in this runtime.
        byteCount[0] += value.size + value.size.toString().size + 2
        if (byteCount[0] > maximumSignatureBytes) {
            cacheable[0] = false
            return
        }
        builder.append(value.size)
        builder.append(":")
        builder.append(value)
        builder.append("|")
    }
}

/// A layout invocation is allowed to ask intrinsic and final-size questions
/// about the same leaf while resolving nested rows and columns. Keep that
/// reuse local to one solve: it is derived data, has no invalidation protocol,
/// and cannot become a second mutable component tree.
private class CjguiComposableUiLayoutMeasurementCacheEntry {
    let value: String
    let style: CjguiComposableUiStyle
    let maximumWidth: Int64
    let queryKind: Int64
    let measurement: CjguiComposableUiTextMeasurement
    init(value: String, style: CjguiComposableUiStyle, maximumWidth: Int64, queryKind: Int64,
        measurement: CjguiComposableUiTextMeasurement) {
        this.value = value
        this.style = style
        this.maximumWidth = maximumWidth
        this.queryKind = queryKind
        this.measurement = measurement
    }
    func matches(value: String, style: CjguiComposableUiStyle, maximumWidth: Int64, queryKind: Int64): Bool {
        return this.queryKind == queryKind && this.value == value && this.maximumWidth == maximumWidth && this.style.background.red == style
            .background
            .red && this.style.background.green == style.background.green && this.style.background.blue == style
            .background
            .blue && this.style.background.alpha == style.background.alpha && this.style.border.red == style
            .border
            .red && this.style.border.green == style.border.green && this.style.border.blue == style.border.blue &&
            this.style.border.alpha == style.border.alpha && this.style.textColor.red == style.textColor.red &&
            this.style.textColor.green == style.textColor.green && this.style.textColor.blue == style.textColor.blue &&
            this.style.textColor.alpha == style.textColor.alpha && this.style.padding == style.padding &&
            this.style.gap == style.gap && this.style.fixedWidth == style.fixedWidth && this.style.fixedHeight == style
            .fixedHeight && this.style.growX == style.growX && this.style.growY == style.growY &&
            this.style.borderWidth == style.borderWidth && this.style.fontSize == style.fontSize &&
            this.style.fontWeight == style.fontWeight && this.style.fontFamily == style.fontFamily &&
            this.style.minWidth == style.minWidth && this.style.maxWidth == style.maxWidth && this.style.idealWidth == style
            .idealWidth && this.style.minHeight == style.minHeight && this.style.maxHeight == style.maxHeight &&
            this.style.idealHeight == style.idealHeight && this.style.alignX == style.alignX && this.style.alignY == style
            .alignY
    }
}

private class CjguiComposableUiLayoutMeasurer <: CjguiComposableUiTextMeasurer &
    CjguiComposableUiMultilineNaturalHeightMeasurer & CjguiComposableUiLayoutMeasurementEnvironment {
    // This bounded cache has one measurer identity because a wrapper belongs
    // to exactly one `layout` call. A later layout starts empty and asks the
    // supplied measurer again, so a changed font/session/generation cannot be
    // hidden by this local optimization.
    private let baseMeasurer: CjguiComposableUiTextMeasurer
    private let reuseMeasurements: Bool
    private var cache: ArrayList<CjguiComposableUiLayoutMeasurementCacheEntry>
    private var measurementRequestCount: Int64
    private var measurerCallCount: Int64
    private var measurementReuseHitCount: Int64
    init(baseMeasurer: CjguiComposableUiTextMeasurer, reuseMeasurements!: Bool = true) {
        this.baseMeasurer = baseMeasurer
        this.reuseMeasurements = reuseMeasurements
        this.cache = ArrayList<CjguiComposableUiLayoutMeasurementCacheEntry>()
        this.measurementRequestCount = 0
        this.measurerCallCount = 0
        this.measurementReuseHitCount = 0
    }
    public func layoutMeasurementEnvironmentKey(): String {
        let environment = baseMeasurer as CjguiComposableUiLayoutMeasurementEnvironment
        return if (let Some(value) <- environment) {
            value.layoutMeasurementEnvironmentKey()
        } else {
            ""
        }
    }
    public func measure(value: String, style: CjguiComposableUiStyle, maximumWidth: Int64): CjguiComposableUiTextMeasurement {
        measurementRequestCount += 1
        if (reuseMeasurements) {
            var index: Int64 = 0
            while (index < cache.size) {
                let entry = cache[index]
                if (entry.matches(value, style, maximumWidth, 0)) {
                    measurementReuseHitCount += 1
                    return entry.measurement
                }
                index += 1
            }
        }
        measurerCallCount += 1
        let measurement = baseMeasurer.measure(value, style, maximumWidth)
        // Production submission already caps a scene at 1,024 nodes. The
        // standalone layout API has no such limit, so evict all local entries
        // at the same fixed bound instead of retaining arbitrary documents.
        if (reuseMeasurements) {
            if (cache.size >= 1024) {
                cache = ArrayList<CjguiComposableUiLayoutMeasurementCacheEntry>()
            }
            cache.add(CjguiComposableUiLayoutMeasurementCacheEntry(value, style, maximumWidth, 0, measurement))
        }
        return measurement
    }
    public func multilineNaturalContentHeight(value: String, style: CjguiComposableUiStyle,
        contentWidth: Int64): ?Int64 {
        let capable = baseMeasurer as CjguiComposableUiMultilineNaturalHeightMeasurer
        if (let Some(multiline) <- capable) {
            measurementRequestCount += 1
            if (reuseMeasurements) {
                var index: Int64 = 0
                while (index < cache.size) {
                    let entry = cache[index]
                    if (entry.matches(value, style, contentWidth, 1)) {
                        measurementReuseHitCount += 1
                        return Some(entry.measurement.height)
                    }
                    index += 1
                }
            }
            measurerCallCount += 1
            let height = multiline.multilineNaturalContentHeight(value, style, contentWidth)
            if (let Some(result) <- height) {
                if (reuseMeasurements) {
                    if (cache.size >= 1024) {
                        cache = ArrayList<CjguiComposableUiLayoutMeasurementCacheEntry>()
                    }
                    cache.add(CjguiComposableUiLayoutMeasurementCacheEntry(value, style, contentWidth, 1,
                        CjguiComposableUiTextMeasurement(0, result, 1, 0)))
                }
            }
            return height
        }
        return Some(measure(value, style, contentWidth).height)
    }
    func metrics(work: CjguiComposableUiLayoutWorkCounter, reuseCache!: ?CjguiComposableUiLayoutReuseCache = None): CjguiComposableUiLayoutMetrics {
        let reuseHits = if (let Some(cache) <- reuseCache) {
            cache.passHitCount()
        } else {
            0
        }
        let reuseMisses = if (let Some(cache) <- reuseCache) {
            cache.passMissCount()
        } else {
            0
        }
        let reuseRevalidationNodes = if (let Some(cache) <- reuseCache) {
            cache.passRevalidationNodeCount()
        } else {
            0
        }
        let reuseReplayedNodes = if (let Some(cache) <- reuseCache) {
            cache.passReplayedNodeCount()
        } else {
            0
        }
        let reuseEntries = if (let Some(cache) <- reuseCache) {
            cache.entryCount()
        } else {
            0
        }
        let reuseRetainedNodes = if (let Some(cache) <- reuseCache) {
            cache.retainedNodeCount()
        } else {
            0
        }
        let reuseRetainedStringBytes = if (let Some(cache) <- reuseCache) {
            cache.retainedStringBytes()
        } else {
            0
        }
        let reuseRetainedBytes = if (let Some(cache) <- reuseCache) {
            cache.retainedBytes()
        } else {
            0
        }
        let reusePendingNodes = if (let Some(cache) <- reuseCache) {
            cache.pendingNodeCount()
        } else {
            0
        }
        let reusePendingStringBytes = if (let Some(cache) <- reuseCache) {
            cache.pendingStringBytes()
        } else {
            0
        }
        let reusePendingBytes = if (let Some(cache) <- reuseCache) {
            cache.pendingBytes()
        } else {
            0
        }
        let reuseBudgetSkips = if (let Some(cache) <- reuseCache) {
            cache.passBudgetSkipCount()
        } else {
            0
        }
        return CjguiComposableUiLayoutMetrics(
            measurementRequestCount,
            measurerCallCount,
            measurementReuseHitCount,
            work.recursiveNodeLayoutCount,
            work.verticalContainerSolveCount,
            work.horizontalContainerSolveCount,
            work.layerHostSolveCount,
            work.scrollAreaSolveCount,
            subtreeReuseHitCount: reuseHits,
            subtreeReuseMissCount: reuseMisses,
            subtreeReuseRevalidationNodeCount: reuseRevalidationNodes,
            subtreeReuseReplayedNodeCount: reuseReplayedNodes,
            subtreeReuseEntryCount: reuseEntries,
            subtreeReuseRetainedNodeCount: reuseRetainedNodes,
            subtreeReuseRetainedStringBytes: reuseRetainedStringBytes,
            subtreeReuseRetainedBytes: reuseRetainedBytes,
            subtreeReusePendingNodeCount: reusePendingNodes,
            subtreeReusePendingStringBytes: reusePendingStringBytes,
            subtreeReusePendingBytes: reusePendingBytes,
            subtreeReuseBudgetSkipCount: reuseBudgetSkips
        )
    }
}

public class CjguiComposableUiLayoutEngine {
    public static func layout(root: CjguiComposableUiNode, viewport: CjguiComposableUiRect, version: Int64): CjguiComposableUiScene {
        return layoutWithMetrics(root, viewport, version, CjguiComposableUiFallbackTextMeasurer()).scene
    }
    public static func layout(root: CjguiComposableUiNode, viewport: CjguiComposableUiRect, version: Int64,
        measurer: CjguiComposableUiTextMeasurer, reuseCache!: ?CjguiComposableUiLayoutReuseCache = None,
        commitReusePass!: Bool = true): CjguiComposableUiScene {
        return layoutWithMetrics(root, viewport, version, measurer, reuseCache: reuseCache,
            commitReusePass: commitReusePass).scene
    }
    /// Runs the canonical solver and returns ephemeral cost counters. Passing
    /// `reuseMeasurements: false` provides a cache-free reference for tests;
    /// it is not a second production scene or state owner.
    public static func layoutWithMetrics(root: CjguiComposableUiNode, viewport: CjguiComposableUiRect, version: Int64,
        measurer: CjguiComposableUiTextMeasurer, reuseMeasurements!: Bool = true,
        reuseCache!: ?CjguiComposableUiLayoutReuseCache = None, commitReusePass!: Bool = true,
        identityRegistry!: ?CjguiComposableUiIdentityRegistry = None): CjguiComposableUiLayoutResult {
        let nodes = ArrayList<CjguiComposableUiLayoutNode>()
        let work = CjguiComposableUiLayoutWorkCounter()
        let layoutMeasurer = CjguiComposableUiLayoutMeasurer(measurer, reuseMeasurements: reuseMeasurements)
        if (let Some(cache) <- reuseCache) {
            cache.beginPass()
        }
        // A scoped composite is intentionally resolved by the per-window
        // candidate registry, never by traversal order in the layout solver.
        // Direct platform-free callers must make that same boundary explicit
        // rather than accidentally emitting repeated sentinel node IDs.
        let initialClipConstraints = ArrayList<CjguiComposableUiClipConstraint>(
            [CjguiComposableUiClipConstraint(viewport)])
        layoutNode(root, viewport, initialClipConstraints, nodes, layoutMeasurer, "", work, reuseCache: reuseCache,
            reuseDepth: 0, identityRegistry: identityRegistry)
        let unresolvedIdentityIssue = if (work.dynamicIdentityIssue.size > 0) {
            work.dynamicIdentityIssue
        } else {
            firstUnresolvedScopedIdentity(root)
        }
        var error = if (unresolvedIdentityIssue.size > 0) {
            unresolvedIdentityIssue
        } else {
            firstDuplicateNodeId(nodes)
        }
        if (error.size == 0 && work.clipConstraintCapacityExceeded) {
            error = "clip_constraint_capacity"
        }
        if (let Some(cache) <- reuseCache) {
            if (error.size == 0) {
                if (commitReusePass) {
                    cache.commitPass()
                }
            } else {
                cache.discardPass()
            }
        }
        let scene = CjguiComposableUiScene(version, viewport, nodes, valid: error.size == 0, layoutError: error)
        return CjguiComposableUiLayoutResult(scene, layoutMeasurer.metrics(work, reuseCache: reuseCache),
            viewports: work.stagedViewports, splitTracks: work.stagedSplitTracks)
    }

    private static func layoutNode(node: CjguiComposableUiNode, bounds: CjguiComposableUiRect,
        parentClipConstraints: ArrayList<CjguiComposableUiClipConstraint>,
        output: ArrayList<CjguiComposableUiLayoutNode>, measurer: CjguiComposableUiTextMeasurer,
        inheritedInputScope: String, work: CjguiComposableUiLayoutWorkCounter,
        reuseCache!: ?CjguiComposableUiLayoutReuseCache = None, reuseDepth!: Int64 = 0,
        identityRegistry!: ?CjguiComposableUiIdentityRegistry = None): Unit {
        work.recursiveNodeLayoutCount += 1
        let nodeClip = clipConstraintBounds(parentClipConstraints).intersect(bounds)
        let inputScope = if (node.layerId().size > 0) {
            node.layerId()
        } else if (node.explicitInputScopeId().size > 0) {
            node.explicitInputScopeId()
        } else {
            inheritedInputScope
        }
        let newestClipRadius = if (parentClipConstraints.size > 0) {
            parentClipConstraints[parentClipConstraints.size - 1].cornerRadius
        } else {
            0
        }
        output.add(
            CjguiComposableUiLayoutNode(node, bounds, nodeClip, inputScopeId: inputScope,
                clipCornerRadius: newestClipRadius, clipConstraints: parentClipConstraints))
        let padding = node.style.padding
        let inner = CjguiComposableUiRect(bounds.x + padding, bounds.y + padding, bounds.width - padding * 2,
            bounds.height - padding * 2)
        let clipsChildren = node.style.clipsContent || node.nodeKind == CJGUI_COMPOSABLE_UI_SCROLL_AREA
        let childClipConstraints = ArrayList<CjguiComposableUiClipConstraint>(parentClipConstraints)
        if (clipsChildren) {
            let interior = node.style.cornerRadius - padding
            let radius = if (interior < 0) {
                0
            } else {
                interior
            }
            if (childClipConstraints.size >= CJGUI_COMPOSABLE_UI_MAX_CLIP_CONSTRAINTS) {
                work.clipConstraintCapacityExceeded = true
            } else {
                childClipConstraints.add(CjguiComposableUiClipConstraint(inner, cornerRadius: radius,
                    ownerIdentity: CjguiComposableUiLayoutNode.identityKeyFor(node)))
            }
        }
        if (node.nodeKind == CJGUI_COMPOSABLE_UI_LAYER_HOST) {
            layoutLayerHost(node, bounds, childClipConstraints, output, measurer, work, reuseCache, reuseDepth,
                identityRegistry)
            return
        }
        if (node.nodeKind == CJGUI_COMPOSABLE_UI_SCROLL_AREA) {
            work.scrollAreaSolveCount += 1
            materializeVirtualList(node, inner, measurer, work, identityRegistry)
            if (work.dynamicIdentityIssue.size > 0) {
                return
            }
        }
        let children = node.children()
        if (children.size == 0) {
            if (node.nodeKind == CJGUI_COMPOSABLE_UI_SCROLL_AREA) {
                // An empty scroll area is a real viewport with no content: zero
                // content and zero offset, but its own geometry is preserved
                // instead of leaving a stale extent from an earlier solve.
                if (let Some(viewport) <- node.scrollViewport) {
                    viewport.stageExtents(0, inner.height, 0)
                    CjguiComposableUiLayoutEngine.recordStagedViewport(work, viewport)
                }
            }
            return
        }
        if (node.nodeKind == CJGUI_COMPOSABLE_UI_SCROLL_AREA) {
            let content = children[0]
            let natural = if (content.virtualContentHeight() > 0) {
                content.virtualContentHeight()
            } else {
                naturalHeight(content, inner.width, measurer)
            }
            let maximumOffset = if (natural > inner.height) {
                natural - inner.height
            } else {
                0
            }
            let offset = if (let Some(viewport) <- node.scrollViewport) {
                // A viewport-bound scroll area takes its offset from the PUBLIC
                // viewport: that ONE view state is shared by the author, the
                // wheel, the keyboard reveal and the accepted scene. The
                // declaration's `scrollOffset` only seeds a brand-new viewport, so
                // a window that clones its declared tree for a projection still
                // MOVES the content instead of publishing an offset the layout
                // never used.
                let requested = viewport.offset()
                if (requested > maximumOffset) {
                    maximumOffset
                } else if (requested < 0) {
                    0
                } else {
                    requested
                }
            } else if (node.scrollOffset > maximumOffset) {
                maximumOffset
            } else if (node.scrollOffset < 0) {
                0
            } else {
                node.scrollOffset
            }
            if (let Some(viewport) <- node.scrollViewport) {
                // CANDIDATE facts: they become accepted only when the window
                // accepts the scene that contains this viewport, so a wheel
                // request can never be read as accepted while the layer is still
                // a candidate.
                viewport.stageExtents(natural, inner.height, offset)
                CjguiComposableUiLayoutEngine.recordStagedViewport(work, viewport)
            }
            let contentBounds = CjguiComposableUiRect(inner.x, inner.y - offset, inner.width, natural)
            // The virtual content was just materialized from mutable source
            // state. It remains on the canonical path for this solve rather
            // than entering the stable-region cache.
            layoutNode(content, contentBounds, childClipConstraints, output, measurer, inputScope, work,
                reuseCache: reuseCache, reuseDepth: reuseDepth + 1, identityRegistry: identityRegistry)
            return
        }
        if (node.isTabsContainer()) {
            layoutTabs(node, children, inner, childClipConstraints, output, measurer, inputScope, work, reuseCache,
                reuseDepth, identityRegistry)
            return
        }
        if (node.isSplitView()) {
            layoutSplitView(node, children, inner, childClipConstraints, output, measurer, inputScope, work, reuseCache,
                reuseDepth, identityRegistry)
            return
        }
        if (node.nodeKind == CJGUI_COMPOSABLE_UI_HORIZONTAL) {
            layoutHorizontal(children, inner, childClipConstraints, node.style.gap, output, measurer, inputScope, work,
                reuseCache, reuseDepth, identityRegistry)
            return
        }
        layoutVertical(node, children, inner, childClipConstraints, node.style.gap, output, measurer, inputScope, work,
            reuseCache, reuseDepth, identityRegistry)
    }

    /// Only direct regions below the declared root are independently cached.
    /// That keeps retained output bounded (at most eight regions) and avoids
    /// turning every nested component into an O(n²) cache. A hit appends the
    /// immutable canonical layout nodes in their original traversal order.
    private static func layoutNodeOrReuse(node: CjguiComposableUiNode, bounds: CjguiComposableUiRect,
        parentClipConstraints: ArrayList<CjguiComposableUiClipConstraint>,
        output: ArrayList<CjguiComposableUiLayoutNode>, measurer: CjguiComposableUiTextMeasurer,
        inheritedInputScope: String, work: CjguiComposableUiLayoutWorkCounter,
        reuseCache: ?CjguiComposableUiLayoutReuseCache, reuseDepth: Int64,
        identityRegistry: ?CjguiComposableUiIdentityRegistry): Unit {
        if (reuseDepth == 1) {
            if (let Some(cache) <- reuseCache) {
                let measurementEnvironment = measurer as CjguiComposableUiLayoutMeasurementEnvironment
                let measurementEnvironmentKey = if (let Some(value) <- measurementEnvironment) {
                    value.layoutMeasurementEnvironmentKey()
                } else {
                    ""
                }
                let signature = cache.signatureFor(node, bounds, parentClipConstraints, inheritedInputScope,
                    measurementEnvironmentKey)
                if (let Some(replayed) <- cache.replay(signature)) {
                    output.add(all: replayed)
                    return
                }
                let start = output.size
                layoutNode(node, bounds, parentClipConstraints, output, measurer, inheritedInputScope, work,
                    reuseCache: reuseCache, reuseDepth: reuseDepth, identityRegistry: identityRegistry)
                let captured = ArrayList<CjguiComposableUiLayoutNode>()
                var index = start
                while (index < output.size) {
                    captured.add(output[index])
                    index += 1
                }
                cache.stage(signature, captured)
                return
            }
        }
        layoutNode(node, bounds, parentClipConstraints, output, measurer, inheritedInputScope, work,
            reuseCache: reuseCache, reuseDepth: reuseDepth, identityRegistry: identityRegistry)
    }

    /// Resolve base content first, then layers in declaration order. The
    /// resulting array is the sole render, semantic and hit-test order.  A
    /// dialog inserts only a generic Cangjie backdrop; native does not know
    /// whether an application is confirming, editing, or invoking a command.
    private static func layoutLayerHost(host: CjguiComposableUiNode, bounds: CjguiComposableUiRect,
        clipConstraints: ArrayList<CjguiComposableUiClipConstraint>, output: ArrayList<CjguiComposableUiLayoutNode>,
        measurer: CjguiComposableUiTextMeasurer, work: CjguiComposableUiLayoutWorkCounter,
        reuseCache: ?CjguiComposableUiLayoutReuseCache, reuseDepth: Int64,
        identityRegistry: ?CjguiComposableUiIdentityRegistry): Unit {
        work.layerHostSolveCount += 1
        let children = host.children()
        if (children.size == 0) {
            return
        }
        let base = children[0]
        // A layer host itself remains canonical: layer bounds depend on base
        // output. Its ordinary base receives the same depth so the base's
        // direct stable regions are eligible for the bounded cache.
        layoutNode(base, bounds, clipConstraints, output, measurer, "", work, reuseCache: reuseCache,
            reuseDepth: reuseDepth, identityRegistry: identityRegistry)
        var index: Int64 = 1
        var layerCount: Int64 = 0
        while (index < children.size && layerCount < 8) {
            let layer = children[index]
            if (layer.layerId().size > 0 && layer.layerKind().size > 0) {
                if (layer.layerIsModal()) {
                    let backdrop = CjguiComposableUiNode(
                        nextGeneratedBackdropNodeId(output),
                        "${host.semanticId}-backdrop-${layer.layerId()}",
                        CJGUI_COMPOSABLE_UI_LAYER_BACKDROP,
                        "",
                        "",
                        "LAYER_OUTSIDE",
                        -1,
                        CjguiComposableUiStyle(background: CjguiComposableUiColor(0.0, 0.0, 0.0, 0.32))
                    )
                    layoutNode(backdrop, bounds, clipConstraints, output, measurer, layer.layerId(), work,
                        reuseCache: None, reuseDepth: reuseDepth + 1, identityRegistry: identityRegistry)
                }
                let layerBounds = resolvedLayerBounds(layer, bounds, output, measurer)
                layoutNode(layer, layerBounds, clipConstraints, output, measurer, layer.layerId(), work,
                    reuseCache: None, reuseDepth: reuseDepth + 1, identityRegistry: identityRegistry)
                layerCount += 1
            }
            index += 1
        }
    }

    /// Generated backdrop controls must still cross the existing UInt64 ABI
    /// as ordinary scene identities. Pick a high positive, currently unused
    /// ID instead of encoding the host as a negative implementation detail.
    private static func nextGeneratedBackdropNodeId(output: ArrayList<CjguiComposableUiLayoutNode>): Int64 {
        var candidate: Int64 = 9000000000000000000
        while (layoutNodeForId(output, candidate).nodeId >= 0) {
            candidate -= 1
        }
        return candidate
    }

    private static func resolvedLayerBounds(layer: CjguiComposableUiNode, hostBounds: CjguiComposableUiRect,
        output: ArrayList<CjguiComposableUiLayoutNode>, measurer: CjguiComposableUiTextMeasurer): CjguiComposableUiRect {
        let naturalWidth = preferredWidth(layer, measurer)
        let requestedWidth = if (layer.style.fixedWidth > 0) {
            layer.style.fixedWidth
        } else {
            naturalWidth
        }
        let width = if (requestedWidth > hostBounds.width) {
            hostBounds.width
        } else {
            requestedWidth
        }
        let naturalHeightValue = naturalHeight(layer, width, measurer)
        let requestedHeight = if (layer.style.fixedHeight > 0) {
            layer.style.fixedHeight
        } else {
            naturalHeightValue
        }
        let height = if (requestedHeight > hostBounds.height) {
            hostBounds.height
        } else {
            requestedHeight
        }
        if (layer.layerKind() == "dialog") {
            return CjguiComposableUiRect(hostBounds.x + (hostBounds.width - width) / 2,
                hostBounds.y + (hostBounds.height - height) / 2, width, height)
        }
        let anchor = layoutNodeForId(output, layer.layerAnchorNodeId())
        if (anchor.nodeId < 0) {
            // An anchor replaced by an external update closes at controller
            // level on its next declaration. Until then this layer is clipped
            // at a deterministic host corner rather than targeting a reused
            // node at the former index.
            return CjguiComposableUiRect(hostBounds.x, hostBounds.y, width, height)
        }
        var x = anchor.bounds.x
        if (x + width > hostBounds.x + hostBounds.width) {
            x = hostBounds.x + hostBounds.width - width
        }
        if (x < hostBounds.x) {
            x = hostBounds.x
        }
        var y = anchor.bounds.y + anchor.bounds.height
        if (y + height > hostBounds.y + hostBounds.height) {
            y = anchor.bounds.y - height
        }
        if (y < hostBounds.y) {
            y = hostBounds.y
        }
        return CjguiComposableUiRect(x, y, width, height)
    }

    private static func layoutNodeForId(nodes: ArrayList<CjguiComposableUiLayoutNode>, nodeId: Int64): CjguiComposableUiLayoutNode {
        var index = nodes.size - 1
        while (index >= 0) {
            if (nodes[index].nodeId == nodeId) {
                return nodes[index]
            }
            index -= 1
        }
        return CjguiComposableUiLayoutNode.missing()
    }

    /// Build only the current virtual range after actual scroll bounds are
    /// known. The logical content height remains the full collection, while
    /// the resolved scene contains solely visible rows and a bounded buffer.
    /// Records one staged viewport per solve, so the window promotes or discards
    /// exactly the viewports this candidate touched.
    private static func recordStagedViewport(work: CjguiComposableUiLayoutWorkCounter,
        viewport: CjguiComposableUiScrollViewport): Unit {
        // One entry per scroll-area node in this solve. Promoting or discarding a
        // viewport twice is a no-op, so no identity comparison is needed.
        work.stagedViewports.add(viewport)
    }

    /// Records one candidate track fact per split instance in this solve. The
    /// window promotes exactly these facts with the scene it accepts, so a trial
    /// layout of a rejected candidate can never widen the bounds of a real drag.
    private static func recordStagedSplitTrack(work: CjguiComposableUiLayoutWorkCounter,
        state: CjguiComposableUiSplitState, track: Int64, handleSize: Int64, firstSize: Int64): Unit {
        work.stagedSplitTracks.add(CjguiComposableUiSplitTrackFact(state, track, handleSize, firstSize))
    }

    private static func materializeVirtualList(node: CjguiComposableUiNode, inner: CjguiComposableUiRect,
        measurer: CjguiComposableUiTextMeasurer, work: CjguiComposableUiLayoutWorkCounter,
        identityRegistry: ?CjguiComposableUiIdentityRegistry): Unit {
        if (let Some(variableSource) <- node.variableHeightListSource()) {
            if (let Some(state) <- node.virtualListState()) {
                materializeVariableHeightList(node, variableSource, state, inner, measurer, work, identityRegistry)
                return
            }
        }
        if (let Some(source) <- node.virtualListSource()) {
            if (let Some(state) <- node.virtualListState()) {
                let totalHeight = state.updateMaterializedRange(source, node.virtualListRowHeight(),
                    node.virtualListRowGap(), inner.height, node.virtualListOverscan())
                node.scrollOffset = state.scrollOffset()
                let content = CjguiComposableUiNode(
                    node.virtualListContentNodeId(),
                    "${node.semanticId}_materialized",
                    CJGUI_COMPOSABLE_UI_VERTICAL,
                    "",
                    "",
                    "",
                    -1,
                    CjguiComposableUiStyle(gap: node.virtualListRowGap()),
                    virtualContentHeight: totalHeight,
                    virtualVerticalOrigin: state
                        .materializedStart()
                        .saturatingMul(node.virtualListRowHeight().saturatingAdd(node.virtualListRowGap()))
                )
                var index = state.materializedStart()
                let seenKeys = ArrayList<String>()
                while (index < state.materializedEnd()) {
                    let item = source.itemAt(index)
                    let isDuplicateKey = containsString(seenKeys, item.key)
                    if (item.key.size > 0 && !isDuplicateKey) {
                        seenKeys.add(item.key)
                        let row = source.buildRow(item, item.key == state.selectedKey(), item.key == state.focusedKey())
                        let identityIssue = resolveMaterializedIdentity(row, identityRegistry)
                        if (identityIssue.size > 0) {
                            work.dynamicIdentityIssue = identityIssue
                            return
                        }
                        row.forceLayoutHeight(node.virtualListRowHeight())
                        content.add(row)
                    } else {
                        state.noteDataIssue(if (item.key.size == 0) {
                            "missing_key"
                        } else {
                            "duplicate_key"
                        })
                        content.add(
                            CjguiComposableUiNode(-1000000000 - index, "${node.semanticId}-placeholder-${index}",
                                CJGUI_COMPOSABLE_UI_VERTICAL, "", "", "", -1,
                                CjguiComposableUiStyle(fixedHeight: node.virtualListRowHeight()),
                                layoutHeightOverride: node.virtualListRowHeight()))
                    }
                    index += 1
                }
                node.replaceChildren(ArrayList<CjguiComposableUiNode>([content]))
                if (let Some(registry) <- identityRegistry) {
                    let referenceIssue = registry.resolveAvailableReferences()
                    if (referenceIssue.size > 0) {
                        work.dynamicIdentityIssue = referenceIssue
                    }
                }
            }
        }
    }

    /// Solve an estimated range, then consume the remaining bounded row
    /// budget only while ordinary measured rows fail to cover the viewport.
    /// A final range solve publishes the total/origin from that same measured
    /// snapshot; it is deliberately not a measure-refresh feedback loop.
    private static func materializeVariableHeightList(node: CjguiComposableUiNode,
        source: CjguiComposableUiVariableHeightListSource, state: CjguiComposableUiVirtualListState,
        inner: CjguiComposableUiRect, measurer: CjguiComposableUiTextMeasurer,
        work: CjguiComposableUiLayoutWorkCounter, identityRegistry: ?CjguiComposableUiIdentityRegistry): Unit {
        state.prepareVariableMeasurementContext(source, inner.width)
        let _ = state.updateVariableMaterializedRange(source, node.virtualListRowHeight(), node.virtualListRowGap(),
            inner.height, node.virtualListOverscan())
        let count = if (source.itemCount() > 0) {
            source.itemCount()
        } else {
            0
        }
        let builtStart = state.materializedStart()
        var builtEnd = state.materializedEnd()
        let measuredRows = buildVariableHeightRows(node, source, state, builtStart, builtEnd, inner.width, measurer,
            work, identityRegistry)
        if (work.dynamicIdentityIssue.size > 0) {
            return
        }
        let viewportEnd = state.scrollOffset().saturatingAdd(if (inner.height > 0) {
            inner.height
        } else {
            1
        })
        var measuredEnd = variableRowsPhysicalEnd(state.variableMaterializedOrigin(), measuredRows,
            node.virtualListRowGap())
        // An estimate may initially request only one row although that row is
        // genuinely short. Append and measure no more than the existing 128
        // row projection budget until the actual layout reaches the viewport.
        while (measuredEnd < viewportEnd && state.extendVariableMaterializedEnd(count)) {
            let nextEnd = state.materializedEnd()
            let appended = buildVariableHeightRows(node, source, state, builtEnd, nextEnd, inner.width, measurer,
                work, identityRegistry)
            measuredRows.add(all: appended)
            if (work.dynamicIdentityIssue.size > 0) {
                return
            }
            builtEnd = nextEnd
            measuredEnd = variableRowsPhysicalEnd(state.variableMaterializedOrigin(), measuredRows,
                node.virtualListRowGap())
        }
        // Keep the requested post-viewport row buffer when capacity remains.
        // The initial range already retained its permitted prefix buffer.
        var appendedBuffer: Int64 = 0
        while (appendedBuffer < node.virtualListOverscan() && state.extendVariableMaterializedEnd(count)) {
            let nextEnd = state.materializedEnd()
            measuredRows.add(all: buildVariableHeightRows(node, source, state, builtEnd, nextEnd, inner.width, measurer,
                work, identityRegistry))
            if (work.dynamicIdentityIssue.size > 0) {
                return
            }
            builtEnd = nextEnd
            appendedBuffer += 1
        }
        // A structural fallback (for example, deleted anchor -> successor)
        // happens before this pass's measurements. Keep that diagnostic
        // through the final geometry solve rather than erasing it merely
        // because the successor is now live.
        let firstIssue = state.lastDataIssue()
        var totalHeight = state.updateVariableMaterializedRange(source, node.virtualListRowHeight(),
            node.virtualListRowGap(), inner.height, node.virtualListOverscan())
        if (firstIssue.size > 0) {
            state.noteDataIssue(firstIssue)
        }
        let finalStart = state.materializedStart();
        let finalEnd = state.materializedEnd()
        let finalRows = ArrayList<CjguiComposableUiNode>()
        if (finalStart >= builtStart && finalEnd <= builtEnd) {
            var index = finalStart
            while (index < finalEnd) {
                finalRows.add(measuredRows[index - builtStart])
                index += 1
            }
        } else {
            // A source that changes its order while a single layout is being
            // measured cannot share a snapshot with the first pass. Rebuild
            // just the current bounded range and publish its own final total;
            // normal stable sources always take the reuse branch above.
            state.noteDataIssue("range_changed_during_measurement")
            finalRows.add(all: buildVariableHeightRows(node, source, state, finalStart, finalEnd, inner.width, measurer,
                work, identityRegistry))
            if (work.dynamicIdentityIssue.size > 0) {
                return
            }
            totalHeight = state.updateVariableMaterializedRange(source, node.virtualListRowHeight(),
                node.virtualListRowGap(), inner.height, node.virtualListOverscan())
        }
        node.scrollOffset = state.scrollOffset()
        let content = CjguiComposableUiNode(
            node.virtualListContentNodeId(),
            "${node.semanticId}_materialized",
            CJGUI_COMPOSABLE_UI_VERTICAL,
            "",
            "",
            "",
            -1,
            CjguiComposableUiStyle(gap: node.virtualListRowGap()),
            virtualContentHeight: totalHeight,
            virtualVerticalOrigin: state.variableMaterializedOrigin()
        )
        content.replaceChildren(finalRows)
        node.replaceChildren(ArrayList<CjguiComposableUiNode>([content]))
        if (let Some(registry) <- identityRegistry) {
            let referenceIssue = registry.resolveAvailableReferences()
            if (referenceIssue.size > 0) {
                work.dynamicIdentityIssue = referenceIssue
            }
        }
    }

    private static func variableRowsPhysicalEnd(origin: Int64, rows: ArrayList<CjguiComposableUiNode>, gap: Int64): Int64 {
        var end = origin
        let safeGap = if (gap > 0) {
            gap
        } else {
            0
        }
        for (row in rows) {
            end = end.saturatingAdd(row.layoutHeightOverride()).saturatingAdd(safeGap)
        }
        return end
    }

    private static func buildVariableHeightRows(node: CjguiComposableUiNode,
        source: CjguiComposableUiVariableHeightListSource, state: CjguiComposableUiVirtualListState, start: Int64,
        end: Int64, availableWidth: Int64, measurer: CjguiComposableUiTextMeasurer,
        work: CjguiComposableUiLayoutWorkCounter,
        identityRegistry: ?CjguiComposableUiIdentityRegistry): ArrayList<CjguiComposableUiNode> {
        let rows = ArrayList<CjguiComposableUiNode>()
        let seenKeys = ArrayList<String>()
        var index = start
        while (index < end) {
            let item = source.itemAt(index)
            let isDuplicateKey = containsString(seenKeys, item.key)
            if (item.key.size > 0 && !isDuplicateKey && source.indexForKey(item.key) == index) {
                seenKeys.add(item.key)
                let row = source.buildRow(item, item.key == state.selectedKey(), item.key == state.focusedKey())
                let identityIssue = resolveMaterializedIdentity(row, identityRegistry)
                if (identityIssue.size > 0) {
                    work.dynamicIdentityIssue = identityIssue
                    return rows
                }
                let measuredHeight = preferredHeight(row, availableWidth, measurer)
                row.forceLayoutHeight(measuredHeight)
                state.recordVariableMeasurement(item, measuredHeight, index)
                rows.add(row)
            } else {
                state.noteDataIssue(if (item.key.size == 0) {
                    "missing_key"
                } else {
                    "duplicate_key"
                })
                let estimate = if (item.estimatedHeight > 0) {
                    item.estimatedHeight
                } else {
                    node.virtualListRowHeight()
                }
                rows.add(
                    CjguiComposableUiNode(-1200000000 - index, "${node.semanticId}-placeholder-${index}",
                        CJGUI_COMPOSABLE_UI_VERTICAL, "", "", "", -1, CjguiComposableUiStyle(fixedHeight: estimate),
                        layoutHeightOverride: estimate))
            }
            index += 1
        }
        return rows
    }

    private static func resolveMaterializedIdentity(node: CjguiComposableUiNode,
        identityRegistry: ?CjguiComposableUiIdentityRegistry): String {
        if (let Some(registry) <- identityRegistry) {
            return registry.resolveDynamicNode(node)
        }
        return firstUnresolvedScopedIdentity(node)
    }

    private static func layoutVertical(owner: CjguiComposableUiNode, children: ArrayList<CjguiComposableUiNode>,
        inner: CjguiComposableUiRect, clipConstraints: ArrayList<CjguiComposableUiClipConstraint>, gap: Int64,
        output: ArrayList<CjguiComposableUiLayoutNode>, measurer: CjguiComposableUiTextMeasurer, inputScope: String,
        work: CjguiComposableUiLayoutWorkCounter, reuseCache: ?CjguiComposableUiLayoutReuseCache, reuseDepth: Int64,
        identityRegistry: ?CjguiComposableUiIdentityRegistry): Unit {
        work.verticalContainerSolveCount += 1
        let widths = ArrayList<Int64>()
        for (child in children) {
            // Natural height must wrap at the width this child actually gets.
            widths.add(crossAxisLength(child, inner.width, inner.width, true, measurer))
        }
        let heights = ArrayList<Int64>()
        var fixedTotal: Int64 = if (children.size > 1) {
            gap * (children.size - 1)
        } else {
            0
        }
        var flexibleIndex: Int64 = -1
        var definiteAllocation = children.size > 0
        var index: Int64 = 0
        while (index < children.size) {
            let child = children[index]
            if (child.layoutHeightOverride() > 0) {
                definiteAllocation = false
                break
            }
            if (child.style.fixedHeight > 0) {
                fixedTotal += child.style.fixedHeight
            } else if (flexibleIndex < 0 && child.style.growY > 0 && child.style.minHeight >= 0 && (child
                .style
                .maxHeight <= 0 || child.style.maxHeight >= child.style.minHeight)) {
                flexibleIndex = index
            } else {
                definiteAllocation = false
                break
            }
            index += 1
        }
        if (definiteAllocation && flexibleIndex >= 0) {
            index = 0
            while (index < children.size) {
                let child = children[index]
                heights.add(if (index == flexibleIndex) {
                    // With one growable child and only fixed-height siblings,
                    // growth or shrink always resolves to this bounded space.
                    // Its intrinsic text height cannot affect the result.
                    constrainedLength(inner.height - fixedTotal, 0, child.style.minHeight, child.style.maxHeight, 0)
                } else {
                    child.style.fixedHeight
                })
                index += 1
            }
        } else {
            var total: Int64 = if (children.size > 1) {
                gap * (children.size - 1)
            } else {
                0
            }
            var grow: Int64 = 0
            index = 0
            while (index < children.size) {
                let child = children[index]
                let height = preferredHeight(child, widths[index], measurer)
                heights.add(height)
                total += height
                grow += child.style.growY
                index += 1
            }
            distributeGrowth(heights, children, if (inner.height > total) {
                inner.height - total
            } else {
                0
            }, grow, false)
            shrinkToFit(heights, children, if (total > inner.height) {
                total - inner.height
            } else {
                0
            }, false)
        }
        var cursor = inner.y + owner.virtualVerticalOrigin()
        index = 0
        while (index < children.size) {
            let child = children[index];
            let height = heights[index]
            let width = widths[index]
            let x = alignedOrigin(inner.x, inner.width, width, child.style.alignX)
            layoutNodeOrReuse(child, CjguiComposableUiRect(x, cursor, width, height), clipConstraints, output, measurer,
                inputScope, work, reuseCache, reuseDepth + 1, identityRegistry)
            cursor += height + gap
            index += 1
        }
    }

    private static func layoutHorizontal(children: ArrayList<CjguiComposableUiNode>, inner: CjguiComposableUiRect,
        clipConstraints: ArrayList<CjguiComposableUiClipConstraint>, gap: Int64,
        output: ArrayList<CjguiComposableUiLayoutNode>, measurer: CjguiComposableUiTextMeasurer, inputScope: String,
        work: CjguiComposableUiLayoutWorkCounter, reuseCache: ?CjguiComposableUiLayoutReuseCache, reuseDepth: Int64,
        identityRegistry: ?CjguiComposableUiIdentityRegistry): Unit {
        work.horizontalContainerSolveCount += 1
        let widths = resolvedHorizontalWidths(children, inner.width, gap, measurer)
        var cursor = inner.x
        var index: Int64 = 0
        while (index < children.size) {
            let child = children[index];
            let width = widths[index]
            // A horizontal child receives its own resolved width for natural
            // text measurement, but stretch must consume the row's actual
            // cross-axis height. Keeping these inputs distinct prevents an
            // 80-point-wide child from incorrectly stretching to 80 points
            // high in a taller row.
            let height = crossAxisLength(child, inner.height, width, false, measurer)
            let y = alignedOrigin(inner.y, inner.height, height, child.style.alignY)
            layoutNodeOrReuse(child, CjguiComposableUiRect(cursor, y, width, height), clipConstraints, output, measurer,
                inputScope, work, reuseCache, reuseDepth + 1, identityRegistry)
            cursor += width + gap
            index += 1
        }
    }

    /// Allocate the two panes and handle from one bounded track. The handle
    /// receives the exact middle bounds even when the window is smaller than
    /// both requested minima; no negative or overflowing geometry escapes the
    /// canonical scene.
    private static func layoutSplitView(owner: CjguiComposableUiNode, children: ArrayList<CjguiComposableUiNode>,
        inner: CjguiComposableUiRect, clipConstraints: ArrayList<CjguiComposableUiClipConstraint>,
        output: ArrayList<CjguiComposableUiLayoutNode>, measurer: CjguiComposableUiTextMeasurer, inputScope: String,
        work: CjguiComposableUiLayoutWorkCounter, reuseCache: ?CjguiComposableUiLayoutReuseCache, reuseDepth: Int64,
        identityRegistry: ?CjguiComposableUiIdentityRegistry): Unit {
        if (children.size < 3) {
            return
        }
        let handleSize = if (owner.splitHandleThickness() > 0) {
            owner.splitHandleThickness()
        } else {
            1
        }
        let track = if (owner.splitAxis() == CjguiComposableUiSplitAxis.VERTICAL) {
            inner.height
        } else {
            inner.width
        }
        // A split whose author bound shared view state takes its current size from
        // that state, so a divider drag changes geometry without rebuilding the
        // structure or inventing a business version.
        let requestedFirst = if (let Some(state) <- owner.splitState) {
            state.firstSize()
        } else {
            owner.splitFirstSize()
        }
        let firstSize = CjguiComposableUiSplitGeometry.firstSizeForTrack(requestedFirst, track, handleSize,
            owner.splitMinFirst(), owner.splitMinSecond())
        let available = if (track > handleSize) {
            track - handleSize
        } else {
            0
        }
        let boundedFirst = if (firstSize > available) {
            available
        } else if (firstSize < 0) {
            0
        } else {
            firstSize
        }
        if (let Some(state) <- owner.splitState) {
            // The staged fact carries the width this solve REALLY allocated, so the
            // accepted geometry (drag origin, keyboard base) never has to be derived
            // from a request that may never have been solved.
            CjguiComposableUiLayoutEngine.recordStagedSplitTrack(work, state, track, handleSize, boundedFirst)
        }
        let secondSize = if (available > boundedFirst) {
            available - boundedFirst
        } else {
            0
        }
        if (owner.splitAxis() == CjguiComposableUiSplitAxis.VERTICAL) {
            layoutNodeOrReuse(children[0], CjguiComposableUiRect(inner.x, inner.y, inner.width, boundedFirst),
                clipConstraints, output, measurer, inputScope, work, reuseCache, reuseDepth + 1, identityRegistry)
            layoutNodeOrReuse(children[1], CjguiComposableUiRect(inner.x, inner.y + boundedFirst, inner.width,
                handleSize), clipConstraints, output, measurer, inputScope, work, reuseCache, reuseDepth + 1,
                identityRegistry)
            layoutNodeOrReuse(children[2],
                CjguiComposableUiRect(inner.x, inner.y + boundedFirst + handleSize, inner.width, secondSize),
                clipConstraints, output, measurer, inputScope, work, reuseCache, reuseDepth + 1, identityRegistry)
            return
        }
        layoutNodeOrReuse(children[0], CjguiComposableUiRect(inner.x, inner.y, boundedFirst, inner.height),
            clipConstraints, output, measurer, inputScope, work, reuseCache, reuseDepth + 1, identityRegistry)
        layoutNodeOrReuse(children[1], CjguiComposableUiRect(inner.x + boundedFirst, inner.y, handleSize, inner.height),
            clipConstraints, output, measurer, inputScope, work, reuseCache, reuseDepth + 1, identityRegistry)
        layoutNodeOrReuse(children[2],
            CjguiComposableUiRect(inner.x + boundedFirst + handleSize, inner.y, secondSize, inner.height),
            clipConstraints, output, measurer, inputScope, work, reuseCache, reuseDepth + 1, identityRegistry)
    }

    /// A tab container presents exactly ONE page: the title row on top and the
    /// ACTIVE page below it. Every other page is emitted as a ZERO-SIZE layout
    /// node that keeps its identity and its inactive marker, but its subtree is
    /// not measured, hit-tested or drawn — hiding is not deletion, and a hidden
    /// page never pays text measurement or paint cost.
    private static func tabsTitleBandHeight(owner: CjguiComposableUiNode): Int64 {
        return if (owner.tabsTitleHeight > 0) { owner.tabsTitleHeight } else { 1 }
    }

    private static func tabsPageGap(owner: CjguiComposableUiNode): Int64 {
        return if (owner.style.gap > 0) { owner.style.gap } else { 0 }
    }

    private static func tabsPageIsActive(owner: CjguiComposableUiNode, page: CjguiComposableUiNode): Bool {
        let activeKey = match (owner.tabsState) {
            case Some(state) => state.activeKey()
            case None => ""
        }
        return page.tabsPageActive || (activeKey.size > 0 && page.tabsPageKey == activeKey)
    }

    /// Intrinsic tabs height uses the same title, gap and active-page rules as
    /// layoutTabs. A hidden page cannot enlarge its parent scroll extent.
    private static func tabsNaturalHeight(owner: CjguiComposableUiNode, availableWidth: Int64,
        measurer: CjguiComposableUiTextMeasurer): Int64 {
        let children = owner.children()
        if (children.size == 0) {
            return owner.style.padding * 2
        }
        let innerWidth = maxValue(0, availableWidth - owner.style.padding * 2)
        var bodyHeight: Int64 = 0
        var hasActivePage = false
        var index = 1
        while (index < children.size) {
            if (tabsPageIsActive(owner, children[index])) {
                hasActivePage = true
                bodyHeight = maxValue(bodyHeight, preferredHeight(children[index], innerWidth, measurer))
            }
            index += 1
        }
        let activeContribution = if (hasActivePage) { tabsPageGap(owner) + bodyHeight } else { 0 }
        return owner.style.padding * 2 + tabsTitleBandHeight(owner) + activeContribution
    }

    private static func layoutTabs(owner: CjguiComposableUiNode, children: ArrayList<CjguiComposableUiNode>,
        inner: CjguiComposableUiRect, clipConstraints: ArrayList<CjguiComposableUiClipConstraint>,
        output: ArrayList<CjguiComposableUiLayoutNode>, measurer: CjguiComposableUiTextMeasurer, inputScope: String,
        work: CjguiComposableUiLayoutWorkCounter, reuseCache: ?CjguiComposableUiLayoutReuseCache, reuseDepth: Int64,
        identityRegistry: ?CjguiComposableUiIdentityRegistry): Unit {
        if (children.size == 0) {
            return
        }
        let titleHeight = tabsTitleBandHeight(owner)
        let boundedTitle = if (titleHeight > inner.height) {
            inner.height
        } else {
            titleHeight
        }
        layoutNodeOrReuse(children[0], CjguiComposableUiRect(inner.x, inner.y, inner.width, boundedTitle),
            clipConstraints, output, measurer, inputScope, work, reuseCache, reuseDepth + 1, identityRegistry)
        // The container's declared gap separates the title row from the page
        // body, so the property a declaration may carry is really consumed.
        let gap = tabsPageGap(owner)
        let bodyTop = inner.y + boundedTitle + gap
        let bodyHeight = if (inner.height > boundedTitle + gap) {
            inner.height - boundedTitle - gap
        } else {
            0
        }
        var index = 1
        while (index < children.size) {
            let page = children[index]
            if (tabsPageIsActive(owner, page)) {
                layoutNodeOrReuse(page, CjguiComposableUiRect(inner.x, bodyTop, inner.width, bodyHeight),
                    clipConstraints, output, measurer, inputScope, work, reuseCache, reuseDepth + 1, identityRegistry)
            } else {
                // A hidden page keeps its identity in the scene with an EMPTY rect:
                // the instance projection publishes it as inactive/invisible and
                // no text is measured for it.
                output.add(CjguiComposableUiLayoutNode(page, CjguiComposableUiRect(inner.x, bodyTop, 0, 0),
                    CjguiComposableUiRect(inner.x, bodyTop, 0, 0), inputScopeId: inputScope))
                work.hiddenTabPageCount += 1
            }
            index += 1
        }
    }

    private static func distributeGrowth(values: ArrayList<Int64>, children: ArrayList<CjguiComposableUiNode>,
        surplus: Int64, totalGrow: Int64, horizontal: Bool): Unit {
        if (surplus <= 0 || totalGrow <= 0) {
            return
        }
        var remaining = surplus
        while (remaining > 0) {
            // Recompute the denominator after each capped allocation.  A
            // child that has reached its maximum can no longer consume a
            // share, so its leftover belongs to the still-flexible siblings.
            var activeGrow: Int64 = 0
            var index: Int64 = 0
            while (index < values.size) {
                let child = children[index]
                let grow = if (horizontal) {
                    child.style.growX
                } else {
                    child.style.growY
                }
                let maximum = if (horizontal) {
                    maximumWidth(child)
                } else {
                    maximumHeight(child)
                }
                if (grow > 0 && (maximum <= 0 || values[index] < maximum)) {
                    activeGrow += grow
                }
                index += 1
            }
            if (activeGrow <= 0) {
                return
            }

            let roundSurplus = remaining
            var accepted: Int64 = 0
            index = 0
            while (index < values.size) {
                let child = children[index]
                let grow = if (horizontal) {
                    child.style.growX
                } else {
                    child.style.growY
                }
                let maximum = if (horizontal) {
                    maximumWidth(child)
                } else {
                    maximumHeight(child)
                }
                if (grow > 0 && (maximum <= 0 || values[index] < maximum)) {
                    let requested = roundSurplus * grow / activeGrow
                    let capacity = if (maximum > 0) {
                        maximum - values[index]
                    } else {
                        requested
                    }
                    let allocation = if (capacity < requested) {
                        capacity
                    } else {
                        requested
                    }
                    values[index] += allocation
                    accepted += allocation
                }
                index += 1
            }
            if (accepted > 0) {
                remaining -= accepted
            } else {
                // Integer division may leave fewer pixels than any weighted
                // share. Assign those one at a time in child order so a
                // layout is stable across frames while still consuming space.
                index = 0
                while (remaining > 0 && index < values.size) {
                    let child = children[index]
                    let grow = if (horizontal) {
                        child.style.growX
                    } else {
                        child.style.growY
                    }
                    let maximum = if (horizontal) {
                        maximumWidth(child)
                    } else {
                        maximumHeight(child)
                    }
                    if (grow > 0 && (maximum <= 0 || values[index] < maximum)) {
                        values[index] += 1
                        remaining -= 1
                    }
                    index += 1
                }
            }
        }
    }
    private static func shrinkToFit(values: ArrayList<Int64>, children: ArrayList<CjguiComposableUiNode>,
        overflow: Int64, horizontal: Bool): Unit {
        var remaining = overflow;
        var index: Int64 = 0
        while (remaining > 0 && index < values.size) {
            let minimum = if (horizontal) {
                minimumWidth(children[index])
            } else {
                minimumHeight(children[index])
            }
            let reducible = if (values[index] > minimum) {
                values[index] - minimum
            } else {
                0
            }
            let reduction = if (reducible < remaining) {
                reducible
            } else {
                remaining
            }
            values[index] -= reduction
            remaining -= reduction
            index += 1
        }
    }
    private static func preferredWidth(node: CjguiComposableUiNode, measurer: CjguiComposableUiTextMeasurer): Int64 {
        if (node.style.fixedWidth > 0) {
            return node.style.fixedWidth
        }
        let labelWidth = measurer.measure(node.label, node.style, 0).width
        let valueWidth = measurer.measure(node.value, node.style, 0).width
        let textWidth = maxValue(labelWidth, valueWidth)
        let intrinsic = if (node.nodeKind == CJGUI_COMPOSABLE_UI_TEXT) {
            // The draw path insets the glyph rect by
            // CJGUI_COMPOSABLE_UI_TEXT_HORIZONTAL_INSET on EACH side, so the
            // natural width must carry both insets. With a bare `+4` a text node
            // sized to its own text had ~10pt less drawable width than it needed
            // and clipped the trailing glyphs (visible in the editor's status
            // counters, where "行 21" lost its number).
            maxValue(16, valueWidth + CJGUI_COMPOSABLE_UI_TEXT_HORIZONTAL_INSET * 2)
        } else if (node.nodeKind == CJGUI_COMPOSABLE_UI_BUTTON) {
            maxValue(64, valueWidth + 20)
        } else if (node.nodeKind == CJGUI_COMPOSABLE_UI_BOOLEAN_INPUT) {
            maxValue(96, labelWidth + 38)
        } else if (node.nodeKind == CJGUI_COMPOSABLE_UI_TEXT_INPUT || node.nodeKind == CJGUI_COMPOSABLE_UI_INTEGER_INPUT ||
            node.nodeKind == CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT) {
            maxValue(140, textWidth + 36)
        } else if (node.nodeKind == CJGUI_COMPOSABLE_UI_IMAGE) {
            96
        } else {
            maxValue(24, textWidth + node.style.padding * 2)
        }
        return constrainedLength(intrinsic, node.style.fixedWidth, node.style.minWidth, node.style.maxWidth,
            node.style.idealWidth)
    }
    private static func preferredHeight(node: CjguiComposableUiNode, availableWidth: Int64,
        measurer: CjguiComposableUiTextMeasurer): Int64 {
        if (node.layoutHeightOverride() > 0) {
            return node.layoutHeightOverride()
        }
        if (node.style.fixedHeight > 0) {
            return node.style.fixedHeight
        }
        // Text receives a small, explicit vertical draw allowance. The
        // renderer uses the corresponding inset, so a measured line is never
        // clipped merely because the font's line box fills its node bounds.
        let intrinsic = if (node.nodeKind == CJGUI_COMPOSABLE_UI_TEXT) {
            measurer.measure(node.value, node.style, textContentWidth(availableWidth)).height + 4
        } else if (node.nodeKind == CJGUI_COMPOSABLE_UI_SCROLL_AREA) {
            120
        } else if (node.nodeKind == CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT) {
            let contentWidth = textContentWidth(availableWidth)
            let multiline = measurer as CjguiComposableUiMultilineNaturalHeightMeasurer
            let contentHeight = if (let Some(capable) <- multiline) {
                if (let Some(height) <- capable.multilineNaturalContentHeight(node.value, node.style, contentWidth)) {
                    height
                } else {
                    measurer.measure(node.value, node.style, contentWidth).height
                }
            } else {
                measurer.measure(node.value, node.style, contentWidth).height
            }
            maxValue(72, contentHeight + 12)
        } else if (node.isTabsContainer()) {
            tabsNaturalHeight(node, availableWidth, measurer)
        } else if (node.nodeKind == CJGUI_COMPOSABLE_UI_VERTICAL || node.nodeKind == CJGUI_COMPOSABLE_UI_HORIZONTAL) {
            naturalHeight(node, availableWidth, measurer)
        } else if (node.nodeKind == CJGUI_COMPOSABLE_UI_IMAGE) {
            96
        } else {
            maxValue(30, measurer.measure(node.value, node.style, availableWidth).lineHeight + 12)
        }
        return constrainedLength(intrinsic, node.style.fixedHeight, node.style.minHeight, node.style.maxHeight,
            node.style.idealHeight)
    }
    private static func naturalHeight(node: CjguiComposableUiNode, availableWidth: Int64,
        measurer: CjguiComposableUiTextMeasurer): Int64 {
        if (node.virtualContentHeight() > 0) {
            return node.virtualContentHeight()
        }
        if (node.style.fixedHeight > 0) {
            return node.style.fixedHeight
        }
        let children = node.children()
        if (children.size == 0) {
            return node.style.padding * 2
        }
        if (node.nodeKind == CJGUI_COMPOSABLE_UI_HORIZONTAL) {
            var maximum: Int64 = 0
            let innerWidth = if (availableWidth > node.style.padding * 2) {
                availableWidth - node.style.padding * 2
            } else {
                0
            }
            let widths = resolvedHorizontalWidths(children, innerWidth, node.style.gap, measurer)
            var index: Int64 = 0
            while (index < children.size) {
                maximum = maxValue(maximum, preferredHeight(children[index], widths[index], measurer))
                index += 1
            }
            return maximum + node.style.padding * 2
        }
        var total = node.style.padding * 2;
        var index: Int64 = 0
        let innerWidth = if (availableWidth > node.style.padding * 2) {
            availableWidth - node.style.padding * 2
        } else {
            0
        }
        while (index < children.size) {
            let childWidth = crossAxisLength(children[index], innerWidth, innerWidth, true, measurer)
            total += preferredHeight(children[index], childWidth, measurer)
            if (index + 1 < children.size) {
                total += node.style.gap
            };
            index += 1
        }
        return total
    }
    /// The same primary-axis allocation must drive both `layoutHorizontal`
    /// and a horizontal container's natural height.  In particular, wrapped
    /// descendants receive their final row width before their height is read.
    private static func resolvedHorizontalWidths(children: ArrayList<CjguiComposableUiNode>, availableWidth: Int64,
        gap: Int64, measurer: CjguiComposableUiTextMeasurer): ArrayList<Int64> {
        let widths = ArrayList<Int64>()
        var total: Int64 = if (children.size > 1) {
            gap * (children.size - 1)
        } else {
            0
        }
        var grow: Int64 = 0
        for (child in children) {
            let width = preferredWidth(child, measurer)
            widths.add(width);
            total += width
            grow += child.style.growX
        }
        distributeGrowth(widths, children, if (availableWidth > total) {
            availableWidth - total
        } else {
            0
        }, grow, true)
        shrinkToFit(widths, children, if (total > availableWidth) {
            total - availableWidth
        } else {
            0
        }, true)
        return widths
    }
    /// `crossAxisAvailable` is the parent space a stretch child can fill.
    /// `textMeasurementWidth` is intentionally separate: a row child may
    /// have a narrow allocated width but live in a tall row, so natural text
    /// height must wrap by width while stretch resolves by row height.
    private static func crossAxisLength(node: CjguiComposableUiNode, crossAxisAvailable: Int64,
        textMeasurementWidth: Int64, horizontalAxis: Bool, measurer: CjguiComposableUiTextMeasurer): Int64 {
        let alignment = if (horizontalAxis) {
            node.style.alignX
        } else {
            node.style.alignY
        }
        if (alignment == CJGUI_COMPOSABLE_UI_ALIGN_STRETCH) {
            return if (horizontalAxis) {
                constrainedLength(crossAxisAvailable, node.style.fixedWidth, node.style.minWidth, node.style.maxWidth, 0)
            } else {
                constrainedLength(crossAxisAvailable, node.style.fixedHeight, node.style.minHeight, node
                    .style
                    .maxHeight, 0)
            }
        }
        return if (horizontalAxis) {
            preferredWidth(node, measurer)
        } else {
            preferredHeight(node, textMeasurementWidth, measurer)
        }
    }
    private static func textContentWidth(outerWidth: Int64): Int64 {
        let inset = CJGUI_COMPOSABLE_UI_TEXT_HORIZONTAL_INSET * 2
        return if (outerWidth > inset) {
            outerWidth - inset
        } else {
            1
        }
    }
    private static func alignedOrigin(origin: Int64, available: Int64, size: Int64, alignment: Int64): Int64 {
        if (alignment == CJGUI_COMPOSABLE_UI_ALIGN_CENTER) {
            return origin + (available - size) / 2
        }
        if (alignment == CJGUI_COMPOSABLE_UI_ALIGN_END) {
            return origin + available - size
        }
        return origin
    }
    private static func constrainedLength(intrinsic: Int64, fixed: Int64, minimum: Int64, maximum: Int64, ideal: Int64): Int64 {
        var value = if (fixed > 0) {
            fixed
        } else if (ideal > 0) {
            ideal
        } else {
            intrinsic
        }
        if (value < minimum) {
            value = minimum
        }
        if (maximum > 0 && value > maximum) {
            value = maximum
        }
        return value
    }
    private static func minimumWidth(node: CjguiComposableUiNode): Int64 {
        return if (node.style.fixedWidth > 0) {
            node.style.fixedWidth
        } else {
            node.style.minWidth
        }
    }
    private static func maximumWidth(node: CjguiComposableUiNode): Int64 {
        return if (node.style.fixedWidth > 0) {
            node.style.fixedWidth
        } else {
            node.style.maxWidth
        }
    }
    private static func minimumHeight(node: CjguiComposableUiNode): Int64 {
        return if (node.style.fixedHeight > 0) {
            node.style.fixedHeight
        } else {
            node.style.minHeight
        }
    }
    private static func maximumHeight(node: CjguiComposableUiNode): Int64 {
        return if (node.style.fixedHeight > 0) {
            node.style.fixedHeight
        } else {
            node.style.maxHeight
        }
    }
    private static func maxValue(left: Int64, right: Int64): Int64 {
        return if (left > right) {
            left
        } else {
            right
        }
    }
    private static func clipConstraintBounds(constraints: ArrayList<CjguiComposableUiClipConstraint>): CjguiComposableUiRect {
        if (constraints.size == 0) {
            return CjguiComposableUiRect(0, 0, 0, 0)
        }
        var bounds = constraints[0].rect
        var index: Int64 = 1
        while (index < constraints.size) {
            bounds = bounds.intersect(constraints[index].rect)
            index += 1
        }
        return bounds
    }
    private static func containsString(values: ArrayList<String>, candidate: String): Bool {
        for (value in values) {
            if (value == candidate) {
                return true
            }
        }
        return false
    }
    private static func firstDuplicateNodeId(nodes: ArrayList<CjguiComposableUiLayoutNode>): String {
        var outer: Int64 = 0
        while (outer < nodes.size) {
            var inner = outer + 1
            while (inner < nodes.size) {
                if (nodes[outer].nodeId == nodes[inner].nodeId) {
                    // Keep the contract string unchanged (tests assert on it) but name
                    // the offending id for diagnosis.
                    println("PHAROS_DUPLICATE_NODE_ID id=${nodes[outer].nodeId} " +
                        "outer=${outer} inner=${inner} count=${nodes.size} " +
                        "a=${nodes[outer].semanticId} b=${nodes[inner].semanticId} " +
                        "ak=${nodes[outer].nodeKind} bk=${nodes[inner].nodeKind}")
                    return "duplicate_node_id"
                }
                inner += 1
            }
            outer += 1
        }
        return ""
    }

    private static func firstUnresolvedScopedIdentity(node: CjguiComposableUiNode): String {
        if (node.hasUnresolvedScopedIdentity()) {
            if (let Some(identity) <- node.scopedIdentity()) {
                return "identity_resolution_required_scope_key_${identity.diagnosticKey()}"
            }
        }
        for (child in node.children()) {
            let childIssue = firstUnresolvedScopedIdentity(child)
            if (childIssue.size > 0) {
                return childIssue
            }
        }
        return ""
    }
}

/// Derives the external read-only window context from the exact component
/// declaration passed to the layout engine. A consumer never maintains a
/// parallel window/group/control relation table: moving, adding or removing a
/// node changes this output on the next scene submission.
public class CjguiComposableUiWindowProjectionBuilder {
    public static func fromScene(
        root: CjguiComposableUiNode,
        scene: CjguiComposableUiScene,
        focusedNodeId!: Int64 = -1,
        selectionStart!: Int64 = 0,
        selectionEnd!: Int64 = 0,
        nativeSubmissionVersion!: Int64 = -1,
        sessionIdentity!: String = "unavailable",
        acceptedSceneVersion!: Int64 = 0,
        submittedSceneVersion!: Int64 = -1,
        submittedFrameIndex!: Int64 = -1,
        observedMetalCompletionFrameIndex!: Int64 = -1,
        observedMetalFailureFrameIndex!: Int64 = -1,
        observedMetalGpuDurationMicros!: Int64 = -1,
        overlayDrawnSceneVersion!: Int64 = -1,
        pendingRefreshReason!: String = "none",
        lastNativeFailure!: String = "none",
        buildPassCount!: Int64 = 0,
        layoutPassCount!: Int64 = 0,
        nativeSubmissionCount!: Int64 = 0,
        lastBuildElapsedMs!: Int64 = 0,
        lastLayoutElapsedMs!: Int64 = 0,
        lastNativeMeasurementElapsedMs!: Int64 = 0,
        lastNativeStageAndSubmitElapsedMs!: Int64 = 0,
        lastNativeMeasurementCallCount!: Int64 = 0,
        layoutReuseHitCount!: Int64 = 0,
        layoutReuseMissCount!: Int64 = 0,
        layoutReuseRevalidationNodeCount!: Int64 = 0,
        layoutReuseReplayedNodeCount!: Int64 = 0,
        layoutReuseEntryCount!: Int64 = 0
    ): CjguiSharedOperationWindowProjection {
        let nodes = ArrayList<CjguiSharedOperationWindowNode>()
        let relations = ArrayList<CjguiSharedOperationRelation>()
        let fieldValues = ArrayList<CjguiSharedOperationWindowFieldValue>()
        let collections = ArrayList<CjguiSharedOperationWindowCollection>()
        appendNode(root, "", "", true, nodes, relations, fieldValues, collections)
        let focused = scene.nodeForId(focusedNodeId)
        let focusId = if (focused.nodeId == focusedNodeId) {
            focused.semanticId
        } else {
            ""
        }
        let isTextSelection = focusId.size > 0 && (focused.nodeKind == CJGUI_COMPOSABLE_UI_TEXT_INPUT ||
            focused.nodeKind == CJGUI_COMPOSABLE_UI_INTEGER_INPUT || focused.nodeKind ==
            CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT)
        let start = if (selectionStart < 0) {
            0
        } else {
            selectionStart
        }
        let end = if (selectionEnd < start) {
            start
        } else {
            selectionEnd
        }
        return CjguiSharedOperationWindowProjection(
            true,
            scene.version,
            nativeSubmissionVersion,
            "unavailable",
            focusId,
            start,
            end,
            relations,
            nodes: nodes,
            fieldValues: fieldValues,
            collections: collections,
            hasTextSelection: isTextSelection,
            sessionIdentity: sessionIdentity,
            acceptedSceneVersion: acceptedSceneVersion,
            submittedSceneVersion: submittedSceneVersion,
            submittedFrameIndex: submittedFrameIndex,
            observedMetalCompletionFrameIndex: observedMetalCompletionFrameIndex,
            observedMetalFailureFrameIndex: observedMetalFailureFrameIndex,
            observedMetalGpuDurationMicros: observedMetalGpuDurationMicros,
            overlayDrawnSceneVersion: overlayDrawnSceneVersion,
            pendingRefreshReason: pendingRefreshReason,
            lastNativeFailure: lastNativeFailure,
            buildPassCount: buildPassCount,
            layoutPassCount: layoutPassCount,
            nativeSubmissionCount: nativeSubmissionCount,
            lastBuildElapsedMs: lastBuildElapsedMs,
            lastLayoutElapsedMs: lastLayoutElapsedMs,
            lastNativeMeasurementElapsedMs: lastNativeMeasurementElapsedMs,
            lastNativeStageAndSubmitElapsedMs: lastNativeStageAndSubmitElapsedMs,
            lastNativeMeasurementCallCount: lastNativeMeasurementCallCount,
            layoutReuseHitCount: layoutReuseHitCount,
            layoutReuseMissCount: layoutReuseMissCount,
            layoutReuseRevalidationNodeCount: layoutReuseRevalidationNodeCount,
            layoutReuseReplayedNodeCount: layoutReuseReplayedNodeCount,
            layoutReuseEntryCount: layoutReuseEntryCount
        )
    }

    private static func appendNode(
        node: CjguiComposableUiNode,
        parentKind: String,
        parentSemanticId: String,
        isRoot: Bool,
        outputNodes: ArrayList<CjguiSharedOperationWindowNode>,
        outputRelations: ArrayList<CjguiSharedOperationRelation>,
        outputFieldValues: ArrayList<CjguiSharedOperationWindowFieldValue>,
        outputCollections: ArrayList<CjguiSharedOperationWindowCollection>
    ): Unit {
        let kind = semanticNodeKind(node, isRoot)
        let resourceIds = nodeResourceIds(node)
        outputNodes.add(CjguiSharedOperationWindowNode(node.nodeId, node.semanticId, kind, resourceIds))
        if (!isRoot) {
            outputRelations.add(
                CjguiSharedOperationRelation(
                    parentKind,
                    parentSemanticId,
                    "CONTAINS",
                    kind,
                    node.semanticId,
                    resourceIds: resourceIds
                )
            )
        }
        if (node.layerId().size > 0 && node.layerKind().size > 0) {
            outputRelations.add(
                CjguiSharedOperationRelation(
                    "layer",
                    node.layerId(),
                    "HAS_KIND",
                    "layer_kind",
                    node.layerKind()
                )
            )
            outputRelations.add(
                CjguiSharedOperationRelation(
                    "layer",
                    node.layerId(),
                    "OWNS_CONTEXT",
                    "component",
                    node.layerOwnerSemanticId()
                )
            )
            if (node.layerAnchorSemanticId().size > 0) {
                outputRelations.add(
                    CjguiSharedOperationRelation(
                        "layer",
                        node.layerId(),
                        "ANCHORED_TO",
                        "component",
                        node.layerAnchorSemanticId()
                    )
                )
            }
            outputRelations.add(
                CjguiSharedOperationRelation(
                    "layer",
                    node.layerId(),
                    "FOCUS_SCOPE",
                    "scope",
                    node.layerId()
                )
            )
        }
        if (let Some(source) <- node.virtualListSource()) {
            if (let Some(state) <- node.virtualListState()) {
                outputCollections.add(
                    CjguiSharedOperationWindowCollection(
                        node.semanticId,
                        source.itemCount(),
                        state.materializedStart(),
                        state.materializedEnd(),
                        state.selectedKey(),
                        state.focusedKey()
                    )
                )
            }
        } else if (let Some(source) <- node.variableHeightListSource()) {
            if (let Some(state) <- node.virtualListState()) {
                outputCollections.add(
                    CjguiSharedOperationWindowCollection(
                        node.semanticId,
                        source.itemCount(),
                        state.materializedStart(),
                        state.materializedEnd(),
                        state.selectedKey(),
                        state.focusedKey()
                    )
                )
            }
        }
        let operationResourceId = projectedResourceId(node)
        // State role and shown value are direct component declarations. This
        // covers both controls and read-only text without forcing an external
        // client to parse underscores from an opaque relation target.
        if (operationResourceId >= 0 && node.fieldId.size > 0 && node.displayValueRole.size > 0) {
            outputFieldValues.add(
                CjguiSharedOperationWindowFieldValue(
                    node.semanticId,
                    operationResourceId,
                    node.fieldId,
                    node.displayValueRole,
                    "component_value",
                    CjguiSharedOperationValue.string(node.value)
                )
            )
        }
        // Pointer controls publish value/range facts as ordinary semantic
        // fields. They are read-only projections; an external write still
        // has to enter the consumer's existing owner/CAS action path.
        if (operationResourceId >= 0 && node.pointerControlRole == "slider") {
            let current = if (let Some(parsed) <- Int64.tryParse(node.value)) {
                parsed
            } else {
                node.pointerControlMinimum
            }
            outputFieldValues.add(
                CjguiSharedOperationWindowFieldValue(node.semanticId, operationResourceId, "value", "control",
                    "pointer_value", CjguiSharedOperationValue.integer(current)))
            outputFieldValues.add(
                CjguiSharedOperationWindowFieldValue(node.semanticId, operationResourceId, "minimum", "control",
                    "pointer_range", CjguiSharedOperationValue.integer(node.pointerControlMinimum)))
            outputFieldValues.add(
                CjguiSharedOperationWindowFieldValue(node.semanticId, operationResourceId, "maximum", "control",
                    "pointer_range", CjguiSharedOperationValue.integer(node.pointerControlMaximum)))
            outputFieldValues.add(
                CjguiSharedOperationWindowFieldValue(node.semanticId, operationResourceId, "step", "control",
                    "pointer_range", CjguiSharedOperationValue.integer(node.pointerControlStep)))
        } else if (operationResourceId >= 0 && node.pointerControlRole == "split_handle") {
            outputFieldValues.add(
                CjguiSharedOperationWindowFieldValue(node.semanticId, operationResourceId, "firstSize", "control",
                    "pointer_value", CjguiSharedOperationValue.integer(node.pointerControlFirstSize)))
            outputFieldValues.add(
                CjguiSharedOperationWindowFieldValue(node.semanticId, operationResourceId, "minimumFirst", "control",
                    "pointer_range", CjguiSharedOperationValue.integer(node.pointerControlMinimum)))
            outputFieldValues.add(
                CjguiSharedOperationWindowFieldValue(node.semanticId, operationResourceId, "minimumSecond", "control",
                    "pointer_range", CjguiSharedOperationValue.integer(node.pointerControlSecondMinimum)))
        }
        if (operationResourceId >= 0 && kind == "control") {
            let resourceSemanticId = "resource${operationResourceId}"
            outputRelations.add(
                CjguiSharedOperationRelation(
                    "control",
                    node.semanticId,
                    "TARGETS",
                    "resource",
                    resourceSemanticId,
                    resourceIds: resourceIds
                )
            )
            if (node.fieldId.size > 0) {
                outputRelations.add(
                    CjguiSharedOperationRelation(
                        "control",
                        node.semanticId,
                        "BINDS",
                        "field",
                        "${resourceSemanticId}_${node.fieldId}",
                        resourceIds: resourceIds
                    )
                )
            }
            if (node.operationActionName.size > 0) {
                outputRelations.add(
                    CjguiSharedOperationRelation(
                        "control",
                        node.semanticId,
                        "INVOKES",
                        "action",
                        node.operationActionName,
                        resourceIds: resourceIds
                    )
                )
            }
        }
        for (child in node.children()) {
            appendNode(child, kind, node.semanticId, false, outputNodes, outputRelations, outputFieldValues,
                outputCollections)
        }
    }

    private static func nodeResourceIds(node: CjguiComposableUiNode): ArrayList<Int64> {
        let resourceId = projectedResourceId(node)
        if (resourceId < 0) {
            return ArrayList<Int64>()
        }
        return ArrayList<Int64>([resourceId])
    }

    private static func projectedResourceId(node: CjguiComposableUiNode): Int64 {
        return if (node.operationResourceId >= 0) {
            node.operationResourceId
        } else {
            node.resourceId
        }
    }

    private static func semanticNodeKind(node: CjguiComposableUiNode, isRoot: Bool): String {
        if (isRoot) {
            return "window"
        }
        if (node.layerId().size > 0 && node.layerKind().size > 0) {
            return "layer"
        }
        let nodeKind = node.nodeKind
        if (nodeKind == CJGUI_COMPOSABLE_UI_BUTTON || nodeKind == CJGUI_COMPOSABLE_UI_TEXT_INPUT || nodeKind ==
            CJGUI_COMPOSABLE_UI_INTEGER_INPUT || nodeKind == CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT || nodeKind ==
            CJGUI_COMPOSABLE_UI_BOOLEAN_INPUT || nodeKind == CJGUI_COMPOSABLE_UI_SCROLL_AREA || nodeKind ==
            CJGUI_COMPOSABLE_UI_SPLIT_HANDLE || nodeKind == CJGUI_COMPOSABLE_UI_SLIDER) {
            return "control"
        }
        if (nodeKind == CJGUI_COMPOSABLE_UI_TEXT) {
            return "text"
        }
        return "group"
    }
}

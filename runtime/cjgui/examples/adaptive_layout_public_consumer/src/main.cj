package adaptive_layout_public_consumer

import cjgui.*
import cjgui_shared_operation_core.*
import std.collection.*
import std.env.*
import std.time.*

// Effect foundation consumption (P1).  This UI-only normal application declares
// the framework's outer-shadow and linear-gradient effects through the PUBLIC
// handwritten Style entry AND through ONE application named-style definition, so
// a reader can check that both consumption sites resolve the SAME single
// declaration instead of each re-authoring its own values.
//
// `AdaptiveEffects` is that single definition: the named-style base and the
// handwritten Style pass the very same optional effect values.  The controller
// therefore owns no second shadow/gradient table.

/// The application's ONE effect definition. Handwritten `CjguiComposableUiStyle`
/// call sites and the `CjguiComposableUiNamedStyleCatalog` base both resolve
/// their `shadow`/`gradient` here, so a variant change moves both together.
private class AdaptiveEffects {
    /// Three observable shadow variants (blur/offset/spread all move), plus the
    /// explicit "no shadow" form returned as None.
    static func shadowFor(visible: Bool, variant: Int64): ?CjguiComposableUiShadowStyle {
        if (!visible) {
            return None
        }
        if (variant == 0) {
            // Soft, low elevation.
            return Some(CjguiComposableUiShadowStyle(color: CjguiComposableUiColor(0.0, 0.0, 0.0, 0.45),
                offsetX: 0, offsetY: 3, blurRadius: 10, spread: 0))
        }
        if (variant == 1) {
            // Wider, heavier elevation.
            return Some(CjguiComposableUiShadowStyle(color: CjguiComposableUiColor(0.0, 0.0, 0.0, 0.55),
                offsetX: 0, offsetY: 8, blurRadius: 24, spread: 3))
        }
        // Coloured, offset elevation (a readable "floating above" cue).
        return Some(CjguiComposableUiShadowStyle(color: CjguiComposableUiColor(0.06, 0.12, 0.25, 0.70),
            offsetX: -6, offsetY: 8, blurRadius: 30, spread: 0))
    }

    /// Three observable gradient variants: the axis (horizontal/vertical/
    /// diagonal) and both endpoint colours all move.
    static func gradientFor(visible: Bool, variant: Int64): ?CjguiComposableUiLinearGradient {
        if (!visible) {
            return None
        }
        if (variant == 0) {
            return Some(CjguiComposableUiLinearGradient(startX: 0.0, startY: 0.0, endX: 1.0, endY: 0.0,
                stops: [
                    CjguiComposableUiGradientStop(position: 0.0,
                        color: CjguiComposableUiColor(0.11, 0.31, 0.57, 1.0)),
                    CjguiComposableUiGradientStop(position: 1.0,
                        color: CjguiComposableUiColor(0.25, 0.66, 0.96, 1.0))
                ]))
        }
        if (variant == 1) {
            return Some(CjguiComposableUiLinearGradient(startX: 0.0, startY: 0.0, endX: 0.0, endY: 1.0,
                stops: [
                    CjguiComposableUiGradientStop(position: 0.0,
                        color: CjguiComposableUiColor(0.24, 0.11, 0.52, 1.0)),
                    CjguiComposableUiGradientStop(position: 1.0,
                        color: CjguiComposableUiColor(0.68, 0.31, 0.94, 1.0))
                ]))
        }
        return Some(CjguiComposableUiLinearGradient(startX: 0.0, startY: 0.0, endX: 1.0, endY: 1.0,
            stops: [
                CjguiComposableUiGradientStop(position: 0.0,
                    color: CjguiComposableUiColor(0.05, 0.48, 0.40, 1.0)),
                CjguiComposableUiGradientStop(position: 1.0,
                    color: CjguiComposableUiColor(1.0, 0.82, 0.40, 1.0))
            ]))
    }

    /// The named style's base: an elevated card whose shadow and gradient both
    /// come from the same functions the handwritten Style below uses.
    static func cardBase(showShadow: Bool, showGradient: Bool, shadowVariant: Int64,
        gradientVariant: Int64): CjguiComposableUiStyle {
        return CjguiComposableUiStyle(
            background: CjguiComposableUiColor(0.16, 0.20, 0.30, 0.96),
            border: CjguiComposableUiColor(0.30, 0.42, 0.64, 0.90),
            textColor: CjguiComposableUiColor(0.93, 0.96, 1.0, 1.0),
            cornerRadius: 14, padding: 10, gap: 4,
            shadow: shadowFor(showShadow, shadowVariant),
            gradient: gradientFor(showGradient, gradientVariant))
    }

    /// Handwritten Style #1: a plain panel that floats through the SAME shadow
    /// definition the named style carries.
    static func handwrittenPanelStyle(showShadow: Bool, shadowVariant: Int64): CjguiComposableUiStyle {
        return CjguiComposableUiStyle(
            background: CjguiComposableUiColor(0.10, 0.14, 0.22, 0.94),
            border: CjguiComposableUiColor(0.26, 0.36, 0.56, 0.90),
            textColor: CjguiComposableUiColor(0.90, 0.94, 1.0, 1.0),
            cornerRadius: 10, padding: 8, gap: 4,
            shadow: shadowFor(showShadow, shadowVariant))
    }

    /// Handwritten Style #2: an ordinary button surface painted with the SAME
    /// gradient definition, with NO named-style indirection.
    static func handwrittenButtonStyle(showGradient: Bool, gradientVariant: Int64,
        accent!: ?CjguiComposableUiColor = None): CjguiComposableUiStyle {
        let border = match (accent) {
            case Some(value) => value
            case None => CjguiComposableUiColor(0.12, 0.16, 0.24, 1.0)
        }
        return CjguiComposableUiStyle(
            background: CjguiComposableUiColor(0.12, 0.16, 0.24, 1.0),
            border: border,
            textColor: CjguiComposableUiColor(0.98, 0.99, 1.0, 1.0),
            borderWidth: if (accent.isSome()) { 2 } else { 0 },
            cornerRadius: 8, padding: 6, gap: 0,
            gradient: gradientFor(showGradient, gradientVariant))
    }
}

// Stable node ids for the effect consumption surface. Control ids stay below
// 200 (the framework's control id space); the scroll container and its content
// use dedicated ids so a screenshot/annotation can address them by identity.
private let NODE_EFFECT_SCROLL: Int64 = 40
private let NODE_EFFECT_CONTENT: Int64 = 41
private let NODE_EFFECT_SPACER: Int64 = 42
private let NODE_EFFECT_CARD: Int64 = 43
private let NODE_EFFECT_CARD_TITLE: Int64 = 44
private let NODE_EFFECT_CARD_DETAIL: Int64 = 45
private let NODE_HANDWRITTEN_PANEL: Int64 = 46
private let NODE_HANDWRITTEN_PANEL_TITLE: Int64 = 47
private let NODE_HANDWRITTEN_BUTTON: Int64 = 48
private let NODE_EFFECT_OUTCOME: Int64 = 49
private let NODE_TOGGLE_SHADOW: Int64 = 50
private let NODE_TOGGLE_GRADIENT: Int64 = 51
private let NODE_CYCLE_SHADOW: Int64 = 52
private let NODE_CYCLE_GRADIENT: Int64 = 53
private let NODE_MOVE_CARD: Int64 = 54
private let NODE_SCROLL_PANE: Int64 = 55
private let NODE_REMOVE_EFFECTS: Int64 = 56
private let NODE_INVALID_EFFECT: Int64 = 57
private let NODE_RESTORE_EFFECTS: Int64 = 58
private let NODE_EFFECT_GROUP_OWNER: Int64 = 73
private let NODE_EFFECT_GROUP_OVERLAY: Int64 = 74
private let NODE_EFFECT_GROUP_TITLE: Int64 = 75
private let NODE_EFFECT_GROUP_IMAGE: Int64 = 76
private let NODE_EFFECT_GROUP_ACTION: Int64 = 77
private let NODE_EFFECT_GROUP_STATUS: Int64 = 78
private let NODE_EFFECT_GROUP_OPACITY: Int64 = 79
private let NODE_EFFECT_GROUP_MASK: Int64 = 80
private let NODE_EFFECT_GROUP_BLEND: Int64 = 81
private let NODE_EFFECT_GROUP_MOVE: Int64 = 82
private let NODE_EFFECT_GROUP_BLUR: Int64 = 87
private let NODE_SUBPOINT_TRANSLATION_TOGGLE: Int64 = 95
private let NODE_POSITION_MOTION: Int64 = 96
private let NODE_POSITION_MOTION_CLEAR: Int64 = 97
private let NODE_TRANSLATED_TITLE_INPUT: Int64 = 9708
private let NODE_PNG_TARGET: Int64 = 210
private let NODE_PNG_SOURCE: Int64 = 211
private let NODE_PNG_ROW: Int64 = 212
private let NODE_PNG_PREVIEW: Int64 = 213
private let NODE_PNG_STATUS: Int64 = 214
private let NODE_WINDOW_MATERIAL_TOGGLE: Int64 = 88
private let NODE_WINDOW_MATERIAL_CLEAR: Int64 = 89
private let NODE_EFFECT_GROUP_BASE_CARD: Int64 = 84
private let NODE_EFFECT_GROUP_OVERLAY_CARD: Int64 = 85
private let NODE_EFFECT_GROUP_OVERLAY_TITLE: Int64 = 86
private let NODE_EFFECT_GROUP_SEMANTIC: String = "adaptive-effect-group-owner"
private let NODE_EFFECT_GROUP_CARD_SEMANTIC: String = "adaptive-effect-group-base-card"
private let NODE_FILLER_A: Int64 = 70
private let NODE_FILLER_B: Int64 = 71
private let NODE_FILLER_C: Int64 = 72
// P2 hit/effect region: an interactive card whose OUTER shadow is clearly
// separated from its own frame. Activating the card inside its own bounds is a
// real action; clicking the shadow band (outside the frame) must NOT activate
// it. The two buttons drive the framework paint-alpha animation through the
// public window entry, and the probe prints the geometry/hit anchors.
private let NODE_SHADOW_HIT_ROW: Int64 = 60
private let NODE_SHADOW_HIT_CARD: Int64 = 61
private let NODE_SHADOW_HIT_STATUS: Int64 = 62
private let NODE_HOVER_TOGGLE: Int64 = 63
private let NODE_PRESS_TOGGLE: Int64 = 64
private let NODE_ANIMATION_PROBE: Int64 = 65
private let NODE_ANIMATION_OUTCOME: Int64 = 66
/// The card's semantic id, which is also the stable animation identity
/// (`semantic:<id>`), so the same node is addressed by hit testing and by the
/// paint-alpha animation without a second id table.
private let SHADOW_HIT_SEMANTIC: String = "adaptive-shadow-hit-card"
private let SHADOW_HIT_IDENTITY: String = "semantic:adaptive-shadow-hit-card"
/// Paint-alpha targets for the application's own hover/pressed states.
private let SHADOW_HIT_ALPHA_NORMAL: Float64 = 1.0
private let SHADOW_HIT_ALPHA_HOVER: Float64 = 0.72
private let SHADOW_HIT_ALPHA_PRESSED: Float64 = 0.45

// The P3 controls live in the existing UI-only owner. A tiny stable-key tree
// is enough to exercise an outline, logical row parents, a disabled item and
// reveal without allocating invisible AX rows.
private class AdaptiveControlTreeSource <: CjguiComposableUiTreeDataSource {
    public func childCount(parentKey: String): Int64 {
        if (parentKey == "") { return 2 }
        if (parentKey == "branch") { return 2 }
        return 0
    }

    public func childAt(parentKey: String, index: Int64): CjguiComposableUiTreeNode {
        if (parentKey == "") {
            if (index == 0) { return CjguiComposableUiTreeNode("branch", "操作组", 991, true) }
            return CjguiComposableUiTreeNode("disabled", "禁用条目", 994, false, selectable: false)
        }
        if (index == 0) { return CjguiComposableUiTreeNode("leaf-a", "首个条目", 992, false) }
        return CjguiComposableUiTreeNode("leaf-b", "第二条目", 993, false)
    }
}

class AdaptiveController <: CjguiComposableUiController & CjguiComposableUiSceneRefreshParticipant &
    CjguiComposableUiWindowBackgroundProvider & CjguiComposableUiPlatformAccentConsumer &
    CjguiComposableUiDataTransferProvider {
    let domain: CjguiSharedOperationList
    let componentRegistry: CjguiComposableUiComponentRegistry
    var localRevision: Int64 = 1
    private let pngOwner = CjguiSharedOperationImageOwner()
    private var pngReceiverIncarnation: Int64 = 1
    private var lastPngOutcome: String = "等待 PNG 粘贴或拖入"
    private var lastPngDecodeMicros: Int64 = 0
    var showsSecondaryToggle: Bool = true
    var primaryToggleNodeId: Int64 = -1
    var secondaryToggleNodeId: Int64 = -1
    var primaryToggleScope: String = ""
    var secondaryToggleScope: String = ""
    // --- effect consumption state -------------------------------------------
    /// ONE application definition of the two effects; the named style base and
    /// the handwritten Style both resolve their values from it.
    let namedStyles: CjguiComposableUiNamedStyleCatalog
    private let effectViewport: CjguiComposableUiScrollViewport
    private let translationViewport: CjguiComposableUiScrollViewport
    private let translationSplitState: CjguiComposableUiSplitState
    private let translationLongBody: String
    private var showShadow: Bool = true
    private var showGradient: Bool = true
    private var shadowVariant: Int64 = 0
    private var gradientVariant: Int64 = 0
    /// Card displacement inside the clipping scroll viewport, in logical points.
    /// 0 = visible; 60 = partly clipped edge; 200 = fully moved outside the
    /// ancestor clip (the effect leaves the clip rectangle with its element).
    private var cardShift: Int64 = 0
    private var effectOutcome: String = "初始：命名样式卡片带阴影/渐变，手写按钮带渐变"
    // P4: one handwritten effect-group declaration is owned by this controller.
    // Actions update this state, buildUi publishes it through the accepted scene,
    // and readback below observes the same window owner after layout/scroll.
    private var effectGroupOpacity: Float64 = 1.0
    private var effectGroupMaskEnabled: Bool = false
    private var effectGroupBlendMode: String = "normal"
    private var effectGroupBlurRadiusPoints: Int64 = 0
    private var effectGroupActionCount: Int64 = 0
    // F11: fractional, far and cleared accepted translations. The same group
    // contains a named-style card, image, text and composite action.
    private var translationVariant: Int64 = 0
    private var positionMotionHigh: Bool = false
    private var lastEffectGroupAcceptedLine: String = ""
    private var systemContentAreaRequested: Bool = false
    private var platformAccentColor: ?CjguiComposableUiColor = None
    private var platformAccentToken: String = ""
    private var platformAccentSource: String = ""
    private let controlTreeSource = AdaptiveControlTreeSource()
    private let controlTreeProjection: CjguiComposableUiTreeProjection
    private let controlTreeSelection: CjguiComposableUiTreeSelection
    private let controlTreeListState = CjguiComposableUiVirtualListState()
    private var activeControlTreeListSource: ?CjguiComposableUiTreeListSource = None
    private let controlTabs = CjguiComposableUiTabsState("outline")
    private var controlCheckboxValue: Bool = false
    private var controlActionCount: Int64 = 0
    // --- P2 hit/animation state ---------------------------------------------
    /// The window whose accepted scene carries the interactive shadow card.
    /// Attached once at startup, the same wiring the generated consumer uses.
    private var hitWindow: ?CjguiComposableUiWindow = None
    private var hoverActive: Bool = false
    private var pressedActive: Bool = false

    private var hitActivationCount: Int64 = 0
    private var lastHitProbe: String = "尚未探测"
    private var lastAnimationOutcome: String = "尚未驱动动效"
    /// Last displayed background alpha of the interactive card that was traced,
    /// so the real-pointer interaction observation prints exactly the frames in
    /// which the interaction-paint transition changed value.
    private var lastObservedInteractionAlpha: Float64 = -2.0

    init(domain: CjguiSharedOperationList) {
        this.domain = domain
        this.componentRegistry = CjguiComposableUiComponentRegistry()
        this.namedStyles = CjguiComposableUiNamedStyleCatalog()
        this.effectViewport = CjguiComposableUiScrollViewport()
        this.translationViewport = CjguiComposableUiScrollViewport()
        this.translationSplitState = CjguiComposableUiSplitState(360, 150, 150)
        var longBody = ""
        var line = 0
        while (line < 720) {
            longBody += "第${line}行：可见文字窗口 · 中文🙂 tile 连续性。\n"
            line += 1
        }
        this.translationLongBody = longBody
        this.controlTreeProjection = CjguiComposableUiTreeProjection(controlTreeSource)
        this.controlTreeSelection = CjguiComposableUiTreeSelection(controlTreeProjection)
        let _ = controlTreeProjection.toggleExpand("branch")
        // The named style is registered ONCE; every later build updates the same
        // definition, so the catalog really is the application's single source.
        let _ = this.namedStyles.register(CjguiComposableUiNamedStyle("adaptive_effect_card",
            AdaptiveEffects.cardBase(true, true, 0, 0), purpose: "效果卡片：阴影浮起 + 线性渐变表面"))
        let _ = this.namedStyles.register(CjguiComposableUiNamedStyle("adaptive_effect_button",
            AdaptiveEffects.handwrittenButtonStyle(true, 0), purpose: "效果按钮：渐变表面"))
    }

    public func candidateWindowBackground(): String {
        return if (systemContentAreaRequested) {
            CjguiWindowBackgroundPolicy.SYSTEM_CONTENT_AREA
        } else {
            CjguiWindowBackgroundPolicy.OPAQUE
        }
    }

    public func applyPlatformAccentColor(color: CjguiComposableUiColor, source: String): Bool {
        let token = cjguiComposableUiColorToken(color)
        if (token == platformAccentToken && source == platformAccentSource) { return false }
        if (!namedStyles.update(CjguiComposableUiNamedStyle("adaptive_effect_button",
            AdaptiveEffects.handwrittenButtonStyle(showGradient, gradientVariant, accent: Some(color)),
            purpose: "效果按钮：渐变表面与系统强调色边框"))) { return false }
        platformAccentColor = Some(color)
        platformAccentToken = token
        platformAccentSource = source
        localRevision += 1
        effectOutcome = "强调色 ${source} ${token} 等待画面接受"
        return true
    }

    /// Republish the named-style base for the current effect state, then consume
    /// it exactly like a handwritten Style (same `CjguiComposableUiStyle` type).
    private func resolveCardStyle(): CjguiComposableUiStyle {
        let _ = namedStyles.update(CjguiComposableUiNamedStyle("adaptive_effect_card",
            AdaptiveEffects.cardBase(showShadow, showGradient, shadowVariant, gradientVariant),
            purpose: "效果卡片：阴影浮起 + 线性渐变表面"))
        if (let Some(card) <- namedStyles.forName("adaptive_effect_card")) {
            return card.localStyle(fixedHeight: 92, growX: 1,
                translateX: Some(if (translationVariant == 2) { 0.0 } else { 0.125 }),
                translateY: Some(if (translationVariant == 2) { 0.0 } else { -0.25 }))
        }
        // Defensive fallback: the definition was never registered.
        return AdaptiveEffects.cardBase(showShadow, showGradient, shadowVariant, gradientVariant)
    }

    /// A left-to-right alpha fade in the effect group's normalized local space.
    /// RGB is deliberately absent: this mask controls alpha only.
    private func effectGroupMask(): CjguiComposableUiLinearAlphaMask {
        return CjguiComposableUiLinearAlphaMask(startX: 0.0, startY: 0.0, endX: 1.0, endY: 0.0,
            stops: [
                CjguiComposableUiAlphaMaskStop(position: 0.0, alpha: 0.0),
                CjguiComposableUiAlphaMaskStop(position: 0.5, alpha: 0.52),
                CjguiComposableUiAlphaMaskStop(position: 1.0, alpha: 1.0)
            ])
    }

    private func effectGroupDeclaration(): CjguiComposableUiEffectGroup {
        return CjguiComposableUiEffectGroup(opacity: effectGroupOpacity, blendMode: effectGroupBlendMode,
            mask: if (effectGroupMaskEnabled) { Some(effectGroupMask()) } else { None },
            backdropBlurRadiusPoints: effectGroupBlurRadiusPoints, backdropBlurFallback: "unblurred")
    }

    /// Return only accepted facts from the attached window. The group owner is
    /// stable while card geometry and the shared scroll viewport expose movement
    /// and scrolling; resize is reflected in the accepted group frame.
    public func effectGroupAcceptedLine(): String {
        let window = match (hitWindow) {
            case Some(value) => value
            case None => return ""
        }
        var foundGroup = false
        var groupX: Int64 = 0
        var groupY: Int64 = 0
        var groupWidth: Int64 = 0
        var groupHeight: Int64 = 0
        var ownerIdentity = ""
        var acceptedOpacity: Float64 = -1.0
        var acceptedBlend = "missing"
        var acceptedMask = false
        var acceptedBlurRadiusPoints: Int64 = -1
        var acceptedBlurFallback = "missing"
        var cardX: Int64 = 0
        var cardY: Int64 = 0
        var cardWidth: Int64 = 0
        var cardHeight: Int64 = 0
        var hasCard = false
        var scrollOffset: Int64 = 0
        for (node in window.acceptedSceneNodes()) {
            if (node.semanticId == NODE_EFFECT_GROUP_SEMANTIC) {
                foundGroup = true
                groupX = node.bounds.x
                groupY = node.bounds.y
                groupWidth = node.bounds.width
                groupHeight = node.bounds.height
                ownerIdentity = node.identityKey
                if (let Some(group) <- node.style.effectGroup) {
                    acceptedOpacity = group.opacity
                    acceptedBlend = group.blendMode
                    acceptedMask = group.mask.isSome()
                    acceptedBlurRadiusPoints = group.backdropBlurRadiusPoints
                    acceptedBlurFallback = group.backdropBlurFallback
                }
            } else if (node.semanticId == NODE_EFFECT_GROUP_CARD_SEMANTIC) {
                hasCard = true
                cardX = node.bounds.x
                cardY = node.bounds.y
                cardWidth = node.bounds.width
                cardHeight = node.bounds.height
            } else if (node.semanticId == "adaptive-effect-scroll") {
                if (let Some(viewport) <- node.scrollViewport) {
                    scrollOffset = viewport.offset()
                }
            }
        }
        if (!foundGroup) {
            return ""
        }
        let groupVisualFrame = match (window.acceptedNodeVisualBounds(NODE_EFFECT_GROUP_SEMANTIC)) {
            case Some(rect) => "${rect.x},${rect.y},${rect.width},${rect.height}"
            case None => "missing"
        }
        let actionVisualFrame = match (window.acceptedNodeVisualBounds("adaptive-effect-group-action")) {
            case Some(rect) => "${rect.x},${rect.y},${rect.width},${rect.height}"
            case None => "missing"
        }
        return "CJGUI_ADAPTIVE_EFFECT_GROUP_ACCEPTED owner=${ownerIdentity} " +
            "opacity=${acceptedOpacity} blend=${acceptedBlend} mask=${if (acceptedMask) { 1 } else { 0 }} " +
            "blurRadiusPoints=${acceptedBlurRadiusPoints} blurFallback=${acceptedBlurFallback} " +
            "groupFrame=${groupX},${groupY},${groupWidth},${groupHeight} " +
            "groupVisualFrame=${groupVisualFrame} actionVisualFrame=${actionVisualFrame} " +
            "cardFrame=${if (hasCard) { "${cardX},${cardY},${cardWidth},${cardHeight}" } else { "missing" }} " +
            "scrollOffset=${scrollOffset} actions=${effectGroupActionCount}"
    }

    /// Read the stable owner identity and declared group values from the
    /// accepted scene. Verification never treats the controller's candidate
    /// declaration as an accepted result.
    public func effectGroupAcceptedOwnerIdentity(): String {
        let window = match (hitWindow) {
            case Some(value) => value
            case None => return ""
        }
        for (node in window.acceptedSceneNodes()) {
            if (node.semanticId == NODE_EFFECT_GROUP_SEMANTIC && node.style.effectGroup.isSome()) {
                return node.identityKey
            }
        }
        return ""
    }

    public func effectGroupAcceptedStateIs(opacity: Float64, blend: String, maskEnabled: Bool): Bool {
        let window = match (hitWindow) {
            case Some(value) => value
            case None => return false
        }
        for (node in window.acceptedSceneNodes()) {
            if (node.semanticId == NODE_EFFECT_GROUP_SEMANTIC) {
                if (let Some(group) <- node.style.effectGroup) {
                    return group.opacity == opacity && group.blendMode == blend &&
                        group.mask.isSome() == maskEnabled && group.backdropBlurRadiusPoints == 0 &&
                        group.backdropBlurFallback == "unblurred"
                }
                return false
            }
        }
        return false
    }

    public func effectGroupAcceptedBlurRadiusIs(radiusPoints: Int64): Bool {
        let window = match (hitWindow) {
            case Some(value) => value
            case None => return false
        }
        for (node in window.acceptedSceneNodes()) {
            if (node.semanticId == NODE_EFFECT_GROUP_SEMANTIC) {
                if (let Some(group) <- node.style.effectGroup) {
                    return group.backdropBlurRadiusPoints == radiusPoints &&
                        group.backdropBlurFallback == "unblurred"
                }
                return false
            }
        }
        return false
    }

    /// Emit accepted state only when it changes, so geometry observations follow
    /// the normal accepted transaction rather than reporting a candidate early.
    public func takeEffectGroupAcceptedChange(): String {
        let current = effectGroupAcceptedLine()
        if (current.size == 0 || current == lastEffectGroupAcceptedLine) {
            return ""
        }
        lastEffectGroupAcceptedLine = current
        return current
    }

    /// Effect panel subtree: a clipping scroll viewport holding the elevated
    /// named-style card, a handwritten shadow panel and a handwritten gradient
    /// button, followed by filler content so a real wheel step is observable.
    private func buildTranslationContainers(): CjguiComposableUiNode {
        let scroll = cjguiComposableScrollArea(9701, "adaptive-translated-text-scroll", translationViewport,
            CjguiComposableUiStyle(growX: 1, fixedHeight: 174, clipsContent: true,
                background: CjguiComposableUiColor(0.07, 0.12, 0.19, 1.0)))
        let content = cjguiComposableVertical(9702, "adaptive-translated-text-content",
            CjguiComposableUiStyle(growX: 1, gap: 4))
        content.add(cjguiComposableText(9703, "adaptive-translated-long-text", translationLongBody,
            CjguiComposableUiStyle(growX: 1, fixedHeight: 10000, fontSize: 14.0,
                textColor: CjguiComposableUiColor(0.91, 0.95, 1.0, 1.0))))
        content.add(cjguiComposableButton(9704, "adaptive-translated-tail-action", "长文末尾：切换资源",
            "TOGGLE_RESOURCE", 0, CjguiComposableUiStyle(fixedHeight: 34, growX: 1,
                background: CjguiComposableUiColor(0.18, 0.39, 0.70, 1.0),
                textColor: CjguiComposableUiColor(1.0, 1.0, 1.0, 1.0))))
        scroll.add(content)
        let ownerPane = cjguiComposableVertical(9705, "adaptive-translated-owner-pane",
            CjguiComposableUiStyle(growX: 1, padding: 8, gap: 8,
                background: CjguiComposableUiColor(0.89, 0.93, 0.98, 1.0)))
        ownerPane.add(cjguiComposableText(9706, "adaptive-translated-owner-status",
            "平移分栏 · 首栏 ${translationSplitState.firstSize()} · 列表版本 ${domain.version()} · " +
            "资源 ${if (domain.snapshot().recordAt(0).isMarked) { "选中" } else { "未选中" }}",
            CjguiComposableUiStyle(growX: 1, fixedHeight: 62, fontSize: 14.0,
                textColor: CjguiComposableUiColor(0.08, 0.15, 0.25, 1.0))))
        ownerPane.add(cjguiComposableTextInput(NODE_TRANSLATED_TITLE_INPUT,
            "adaptive-translated-title-input", "资源标题", domain.snapshot().recordAt(0).title, 7101,
            CjguiComposableUiStyle(growX: 1, fixedHeight: 36, fontSize: 14.0,
                background: CjguiComposableUiColor(1.0, 1.0, 1.0, 1.0),
                textColor: CjguiComposableUiColor(0.08, 0.15, 0.25, 1.0),
                border: CjguiComposableUiColor(0.28, 0.44, 0.68, 1.0)),
            fieldId: "title", operationActionName: "SET_TITLE", displayValueRole: "applied"))
        ownerPane.add(cjguiComposableButton(9707, "adaptive-translated-owner-action", "切换同一资源",
            "TOGGLE_RESOURCE", 0, CjguiComposableUiStyle(growX: 1, fixedHeight: 36,
                background: CjguiComposableUiColor(0.19, 0.42, 0.73, 1.0),
                textColor: CjguiComposableUiColor(1.0, 1.0, 1.0, 1.0))))
        let shiftX = if (translationVariant == 2) { 0.0 } else if (translationVariant == 1) {
            30.25
        } else { 0.25 }
        let shiftY = if (translationVariant == 2) { 0.0 } else if (translationVariant == 1) {
            12.5
        } else { 0.5 }
        return cjguiComposableScopedSplitView(CjguiComposableUiIdentityScope("adaptive-translated-split"),
            "adaptive-translated-split", scroll, ownerPane, CjguiComposableUiSplitAxis.HORIZONTAL,
            translationSplitState.firstSize(), 150, 150,
            CjguiComposableUiStyle(growX: 1, fixedHeight: 180, translateX: shiftX, translateY: shiftY,
                border: CjguiComposableUiColor(0.28, 0.44, 0.68, 1.0)),
            splitState: translationSplitState)
    }

    private func buildEffectRegion(): CjguiComposableUiNode {
        let theme = CjguiComposableUiTheme.beaconDark()
        let groupOwner = cjguiComposableVertical(NODE_EFFECT_GROUP_OWNER, NODE_EFFECT_GROUP_SEMANTIC,
            CjguiComposableUiStyle(fixedHeight: 150, growX: 1,
                translateX: if (translationVariant == 2) { 0.0 } else if (translationVariant == 1) { 30.25 } else { 0.25 },
                translateY: if (translationVariant == 2) { 0.0 } else if (translationVariant == 1) { 12.5 } else { 0.5 },
                effectGroup: Some(effectGroupDeclaration())))
        let scroll = cjguiComposableScrollArea(NODE_EFFECT_SCROLL, "adaptive-effect-scroll", effectViewport,
            CjguiComposableUiStyle(fixedHeight: 150, growX: 1, cornerRadius: 12, clipsContent: true,
                background: CjguiComposableUiColor(0.05, 0.08, 0.14, 0.92),
                border: CjguiComposableUiColor(0.20, 0.30, 0.50, 0.90)))
        let content = cjguiComposableVertical(NODE_EFFECT_CONTENT, "adaptive-effect-content",
            CjguiComposableUiStyle(padding: 8, gap: 6, growX: 1))
        // Coarse layout displacement: a real spacer whose height moves the card,
        // so "the element moved" is a genuine layout change, not a paint offset.
        content.add(cjguiComposableVertical(NODE_EFFECT_SPACER, "adaptive-effect-spacer",
            CjguiComposableUiStyle(fixedHeight: cardShift, growX: 1)))
        // An ordinary layer host gives the two cards a real overlapping paint
        // order. The base remains the owner; the anchored popup starts below its
        // title and covers the lower part of that card while retaining its own
        // accepted identity and input route.
        let groupLayerHost = cjguiComposableLayerHost(NODE_EFFECT_GROUP_OVERLAY,
            "adaptive-effect-group-layer-host", CjguiComposableUiStyle(growX: 1, fixedHeight: 156))
        let baseCard = cjguiComposableVertical(NODE_EFFECT_GROUP_BASE_CARD, NODE_EFFECT_GROUP_CARD_SEMANTIC,
            CjguiComposableUiStyle(growX: 1, gap: 4, padding: 8, cornerRadius: 10,
                background: CjguiComposableUiColor(0.12, 0.19, 0.30, 0.98),
                border: CjguiComposableUiColor(0.39, 0.57, 0.82, 1.0)))
        let groupTitle = cjguiComposableText(NODE_EFFECT_GROUP_TITLE, "adaptive-effect-group-title",
            "重叠卡片 · 效果组 owner", theme.heading)
        baseCard.add(groupTitle)
        baseCard.add(cjguiComposableText(NODE_EFFECT_GROUP_STATUS, "adaptive-effect-group-status",
            "opacity=${effectGroupOpacity} mask=${if (effectGroupMaskEnabled) { "on" } else { "off" }} " +
                "blend=${effectGroupBlendMode}；文字、图片与控件共享同一组", theme.body))
        baseCard.add(cjguiComposableImage(NODE_EFFECT_GROUP_IMAGE, "adaptive-effect-group-image",
            "composable-beacon.png", CjguiComposableUiStyle(fixedWidth: 42, fixedHeight: 42),
            imageResourceId: "adaptive-effect-group-image", imageResourceVersion: domain.version() + 1))
        groupLayerHost.add(baseCard)
        let overlayCard = cjguiComposableAnchoredLayer(NODE_EFFECT_GROUP_OVERLAY_CARD,
            "adaptive-effect-group-overlay-card", "adaptive-effect-overlay", "popup",
            NODE_EFFECT_GROUP_CARD_SEMANTIC, NODE_EFFECT_GROUP_TITLE,
            CjguiComposableUiStyle(fixedWidth: 230, fixedHeight: 78, padding: 8, gap: 4,
                cornerRadius: 10, background: CjguiComposableUiColor(0.22, 0.32, 0.53, 0.98),
                border: CjguiComposableUiColor(0.70, 0.82, 1.0, 1.0)))
        overlayCard.add(cjguiComposableText(NODE_EFFECT_GROUP_OVERLAY_TITLE,
            "adaptive-effect-group-overlay-title", "上层卡片覆盖底卡内容", theme.body))
        overlayCard.add(cjguiComposableButton(NODE_EFFECT_GROUP_ACTION, "adaptive-effect-group-action",
            "同 owner 交互 · ${effectGroupActionCount}", "EFFECT_GROUP_ACTION", 0,
            CjguiComposableUiStyle(fixedHeight: 30, cornerRadius: 6, offsetX: 2,
                translateX: if (translationVariant == 2) { 0.0 } else { -0.75 },
                translateY: if (translationVariant == 2) { 0.0 } else { 0.25 },
                background: CjguiComposableUiColor(0.12, 0.22, 0.38, 1.0),
                textColor: CjguiComposableUiColor(1.0, 1.0, 1.0, 1.0)),
            interactionStyle: theme.primaryActionInteraction))
        groupLayerHost.add(overlayCard)
        content.add(groupLayerHost)
        let card = cjguiComposableVertical(NODE_EFFECT_CARD, "adaptive-effect-card", resolveCardStyle())
        card.add(cjguiComposableText(NODE_EFFECT_CARD_TITLE, "adaptive-effect-card-title",
            "命名样式卡片 · shadow=${if (showShadow) { "on" } else { "off" }}(v${shadowVariant}) " +
                "gradient=${if (showGradient) { "on" } else { "off" }}(v${gradientVariant})", theme.heading))
        card.add(cjguiComposableText(NODE_EFFECT_CARD_DETAIL, "adaptive-effect-card-detail",
            "同一份效果定义：命名样式承载，handwritten Style 复用", theme.body))
        content.add(card)
        // Handwritten shadow panel (no named-style indirection).
        let panel = cjguiComposableVertical(NODE_HANDWRITTEN_PANEL, "adaptive-effect-handwritten-panel",
            AdaptiveEffects.handwrittenPanelStyle(showShadow, shadowVariant))
        panel.add(cjguiComposableText(NODE_HANDWRITTEN_PANEL_TITLE, "adaptive-effect-handwritten-title",
            "手写 Style 面板 · 外阴影表达层级", theme.body))
        content.add(panel)
        // Handwritten gradient button surface.
        content.add(cjguiComposableButton(NODE_HANDWRITTEN_BUTTON, "adaptive-effect-handwritten-button",
            "手写渐变按钮", "EFFECT_HANDWRITTEN_NOOP", 0,
            AdaptiveEffects.handwrittenButtonStyle(showGradient, gradientVariant, accent: platformAccentColor)))
        content.add(cjguiComposableText(NODE_FILLER_A, "adaptive-effect-filler-a",
            "滚动内容 A：用于让视口产生真实的可滚动范围", theme.body))
        content.add(cjguiComposableText(NODE_FILLER_B, "adaptive-effect-filler-b",
            "滚动内容 B：wheel / 命令均通过同一个 viewport", theme.body))
        content.add(cjguiComposableText(NODE_FILLER_C, "adaptive-effect-filler-c",
            "滚动内容 C：滚动后卡片与效果位置可观测变化", theme.body))
        scroll.add(content)
        groupOwner.add(scroll)
        return groupOwner
    }

    /// Real-pointer interaction paint for the interactive shadow card. The
    /// framework resolves a real pointer hover/press into these states (a
    /// controller never sees those interaction intents), so a real pointer
    /// enter/leave/down/up/cancel changes the card's paint alpha directly:
    /// hover drops the paint to 0.72 and pressed to 0.45. The paint-alpha
    /// animation entry stays available for the deterministic regression buttons.
    private func shadowHitInteractionStyle(): CjguiComposableUiInteractionStyle {
        return CjguiComposableUiInteractionStyle(
            hover: CjguiComposableUiPaintStyle(
                background: CjguiComposableUiColor(0.20, 0.30, 0.52, SHADOW_HIT_ALPHA_HOVER),
                border: CjguiComposableUiColor(0.62, 0.78, 0.98, SHADOW_HIT_ALPHA_HOVER),
                textColor: CjguiComposableUiColor(1.0, 1.0, 1.0, SHADOW_HIT_ALPHA_HOVER)),
            pressed: CjguiComposableUiPaintStyle(
                background: CjguiComposableUiColor(0.20, 0.30, 0.52, SHADOW_HIT_ALPHA_PRESSED),
                border: CjguiComposableUiColor(0.62, 0.78, 0.98, SHADOW_HIT_ALPHA_PRESSED),
                textColor: CjguiComposableUiColor(1.0, 1.0, 1.0, SHADOW_HIT_ALPHA_PRESSED)))
    }

    /// P2 region: one interactive node with a large, separated outer shadow plus
    /// the two alpha-transition controls. The shadow is a real framework effect
    /// (handwritten style), the card's own paint alpha is animated through the
    /// public window entry, and the status line exposes the same values a
    /// screenshot/verification script reads.
    private func buildShadowHitRegion(): CjguiComposableUiNode {

        let row = cjguiComposableHorizontal(NODE_SHADOW_HIT_ROW, "adaptive-shadow-hit-row",
            CjguiComposableUiStyle(growX: 1, gap: 8, padding: 14, fixedHeight: 116,
                alignY: CJGUI_COMPOSABLE_UI_ALIGN_CENTER))
        // The card keeps its declared paint (background/border/shadow) as the
        // base. Its hover/pressed interaction style is what the REAL pointer
        // drives: the framework resolves HOVER_ENTER/LEAVE and
        // PRESS_BEGIN/END/CANCEL into the state, and the resolved paint alpha
        // drops for hover then pressed. The paint-alpha animation multiplies
        // that resolved paint; it never replaces the shadow declaration.
        let cardStyle = CjguiComposableUiStyle(
            background: CjguiComposableUiColor(0.20, 0.30, 0.52, 1.0),
            border: CjguiComposableUiColor(0.62, 0.78, 0.98, 1.0),
            textColor: CjguiComposableUiColor(1.0, 1.0, 1.0, 1.0),
            fixedWidth: 180, fixedHeight: 44, cornerRadius: 8, padding: 10,

            shadow: Some(CjguiComposableUiShadowStyle(color: CjguiComposableUiColor(0.02, 0.04, 0.10, 0.85),
                offsetX: 0, offsetY: 14, blurRadius: 12, spread: 2)))
        row.add(cjguiComposableButton(NODE_SHADOW_HIT_CARD, SHADOW_HIT_SEMANTIC,
            "阴影命中卡片（框内点击）", "SHADOW_HIT_TARGET", 0, cardStyle,
            interactionStyle: shadowHitInteractionStyle()))
        row.add(cjguiComposableButton(NODE_HOVER_TOGGLE, "adaptive-shadow-hit-hover",
            "hover 过渡", "EFFECT_HOVER_TOGGLE", 0,
            AdaptiveEffects.handwrittenButtonStyle(showGradient, gradientVariant)))
        row.add(cjguiComposableButton(NODE_PRESS_TOGGLE, "adaptive-shadow-hit-press",
            "pressed 过渡", "EFFECT_PRESS_TOGGLE", 0,
            AdaptiveEffects.handwrittenButtonStyle(showGradient, gradientVariant)))
        row.add(cjguiComposableButton(NODE_ANIMATION_PROBE, "adaptive-animation-probe",
            "动效/命中探针", "EFFECT_ANIMATION_PROBE", 0,
            AdaptiveEffects.handwrittenButtonStyle(showGradient, gradientVariant)))
        return row
    }

    /// Attach the window once at startup so the consumer can drive the public
    /// paint-alpha animation entry and read the accepted geometry back.
    public func attachWindow(window: CjguiComposableUiWindow): Unit {
        hitWindow = Some(window)
    }

    /// Public consumer entry running the same shadow hit negative control the
    /// probe button runs.
    public func runHitProbe(): String {
        return probeShadowHit()
    }

    /// Public consumer entry toggling the application hover target through the
    /// public window animation entry; returns the readable outcome line.
    public func driveHoverProbe(): String {
        hoverActive = !hoverActive
        let target = if (hoverActive) { SHADOW_HIT_ALPHA_HOVER } else { SHADOW_HIT_ALPHA_NORMAL }
        animateShadowHit(target, CjguiComposableUiAnimationSpec.tween(durationMs: 140,
            easing: CjguiComposableUiAnimationEasing.EASE_IN_OUT),
            "verify-hover=${if (hoverActive) { "on" } else { "off" }}")
        return lastAnimationOutcome
    }

    /// Reverses the current hover target mid-flight (the deterministic
    /// mid-flight reverse the acceptance asks for).
    public func driveReverseProbe(): String {
        hoverActive = !hoverActive
        let target = if (hoverActive) { SHADOW_HIT_ALPHA_HOVER } else { SHADOW_HIT_ALPHA_NORMAL }
        animateShadowHit(target, CjguiComposableUiAnimationSpec.spring(stiffness: 260.0, dampingRatio: 1.0),
            "verify-reverse=${if (hoverActive) { "on" } else { "off" }}")
        return lastAnimationOutcome
    }

    public func animationObservationLine(): String {
        return lastAnimationOutcome
    }

    /// B1: trace the interactive card's DISPLAYED paint alpha while a REAL
    /// pointer drives the framework interaction state. Each call returns one
    /// line only when the displayed value changed since the previous call, so a
    /// driver can see the transition progressing frame by frame (not an instant
    /// switch) and observe that a mid-flight reverse continues from the current
    /// visual value instead of jumping back to an endpoint. Returns "" when the
    /// value did not change (or the window/card is absent).
    public func interactionPaintTrace(): String {
        let window = match (hitWindow) {
            case Some(value) => value
            case None => return ""
        }
        for (node in window.acceptedSceneNodes()) {
            if (node.semanticId == SHADOW_HIT_SEMANTIC) {
                let alpha = node.style.background.alpha
                if (alpha != lastObservedInteractionAlpha) {
                    lastObservedInteractionAlpha = alpha
                    return "CJGUI_ADAPTIVE_INTERACTION_PAINT alpha=${alpha} " +
                        "identity=${node.identityKey}"
                }
                return ""
            }
        }
        return ""
    }

    /// Accepted geometry of the interactive card as scene points, so an
    /// external real-pointer driver can place a synthetic pointer exactly on
    /// the card (and on the shadow band) instead of guessing coordinates.
    public func hitCardBoundsLine(): String {
        match (hitWindow) {
            case Some(window) =>
                match (window.acceptedNodeBounds(SHADOW_HIT_SEMANTIC)) {
                    case Some(bounds) => return "CJGUI_ADAPTIVE_HIT_BOUNDS x=${bounds.x} y=${bounds.y} " +
                        "w=${bounds.width} h=${bounds.height}"
                    case None => return "CJGUI_ADAPTIVE_HIT_BOUNDS missing"
                }
            case None => return "CJGUI_ADAPTIVE_HIT_BOUNDS missing"
        }
    }

    private func buildControlSemantics(theme: CjguiComposableUiTheme): CjguiComposableUiNode {
        let rows = CjguiComposableUiTreeListSource(controlTreeProjection, controlTreeSelection,
            { row, isSelected, _ =>
                let identity = CjguiComposableUiIdentityScope("adaptive-control-rows").child(row.key).local("row")
                let prefix = if (row.isGroup) { if (row.expanded) { "▾ " } else { "▸ " } }
                    else { if (isSelected) { "◉ " } else { "○ " } }
                return cjguiComposableButton(-1, "adaptive-control-row-${row.key}", "${prefix}${row.label}",
                    "ADAPTIVE_TREE_ROW", row.resourceId,
                    CjguiComposableUiStyle(fixedHeight: 24, textColor: theme.body.textColor),
                    enabled: row.key != "disabled", interactionStyle: theme.primaryActionInteraction,
                    ownerInteractionState: if (isSelected) { CjguiComposableUiInteractionState.SELECTED }
                        else { CjguiComposableUiInteractionState.NONE }, identity: Some(identity))
            })
        activeControlTreeListSource = Some(rows)
        let outline = cjguiComposableVertical(191, "adaptive-control-outline-page",
            CjguiComposableUiStyle(growX: 1, fixedHeight: 82))
        outline.add(cjguiComposableTree(192, "adaptive-control-outline", 193, rows, controlTreeListState,
            24, 0, 2, CjguiComposableUiStyle(fixedHeight: 76, growX: 1)))
        let actions = cjguiComposableVertical(194, "adaptive-control-actions-page",
            CjguiComposableUiStyle(growX: 1, fixedHeight: 82, gap: 4))
        actions.add(cjguiComposableButton(195, "adaptive-control-button", "切换强调色", "ADAPTIVE_CONTROL_BUTTON",
            0, theme.primaryAction, interactionStyle: theme.primaryActionInteraction))
        actions.add(cjguiComposableBooleanInput(196, "adaptive-control-checkbox", "启用状态",
            controlCheckboxValue, 0, CjguiComposableUiStyle(fixedHeight: 28, textColor: theme.body.textColor),
            fieldId: "enabled", displayValueRole: "applied", interactionStyle: theme.inputInteraction))
        let pages = ArrayList<CjguiComposableUiTabPage>()
        pages.add(CjguiComposableUiTabPage("outline", "树", outline))
        pages.add(CjguiComposableUiTabPage("actions", "按钮与复选框", actions))
        return cjguiComposableTabs(CjguiComposableUiIdentityScope("adaptive-controls"),
            "adaptive-controls-tabs", pages, controlTabs,
            CjguiComposableUiStyle(growX: 1, fixedHeight: 112), titleHeight: 28,
            titleStyle: CjguiComposableUiStyle(textColor: theme.heading.textColor),
            titleInteraction: CjguiComposableUiInteractionStyle(focused: CjguiComposableUiPaintStyle(
                border: Some(theme.primaryAction.border), borderWidth: Some(2))))
    }

    // Self-verification selects the page through its shared view state so the
    // ordinary accepted button is present before testing its owner action.
    // Real AX and pointer page activation are checked in the desktop consumer.
    public func showControlActionsForVerification(): Bool {
        if (!controlTabs.select("actions")) { return false }
        localRevision += 1
        return true
    }

    public func buildUi(): CjguiComposableUiNode {
        // This normal app chooses the framework's dark theme and applies its
        // public paint-only state declarations to ordinary controls.
        let theme = CjguiComposableUiTheme.beaconDark()
        let style = CjguiComposableUiStyle(
            minWidth: 280,
            idealWidth: 640,
            maxWidth: 920,
            minHeight: 160,
            idealHeight: 700,
            maxHeight: 720
        )
        let root = cjguiComposableVertical(1, "adaptive-root", style)
        // Ordinary row geometry for the header/status/actions rows: they must NOT
        // inherit the root's size constraint (its idealHeight would reserve a
        // large empty band at the top). Text and controls use the theme's own
        // readable paint instead of the default dark text colour.
        let header = cjguiComposableHorizontal(2, "adaptive-header",
            CjguiComposableUiStyle(growX: 1, gap: 6, fixedHeight: 40))
        header.add(
            cjguiComposableText(
                10,
                "adaptive-title",
                "Adaptive layout · 横纵组合 / 特殊效果（阴影/渐变）/ 动态领域状态",
                theme.heading,
                resourceId: 0,
                fieldId: "",
                displayValueRole: "",
                operationResourceId: 0
            )
        )
        root.add(header)
        let status = cjguiComposableVertical(3, "adaptive-status-card",
            CjguiComposableUiStyle(growX: 1, gap: 3, fixedHeight: 60))
        status.add(
            cjguiComposableText(
                11,
                "adaptive-domain-status",
                "领域状态 / shared operation version = ${domain.version()}",
                theme.body,
                resourceId: 0,
                fieldId: "",
                displayValueRole: "",
                operationResourceId: 0
            )
        )
        status.add(
            cjguiComposableText(
                12,
                "adaptive-long-label",
                "长标签：这是一个较长的中文标签，用于验证窄宽约束下的换行与裁剪行为",
                theme.body,
                resourceId: 0,
                fieldId: "",
                displayValueRole: "",
                operationResourceId: 0
            )
        )
        root.add(status)
        let pngSnapshot = pngOwner.snapshot()
        let pngRow = cjguiComposableHorizontal(NODE_PNG_ROW, "adaptive-png-row",
            CjguiComposableUiStyle(growX: 1, gap: 8, fixedHeight: 42))
        let pngTargetStyle = CjguiComposableUiStyle(fixedWidth: 180, fixedHeight: 34,
            background: theme.primaryAction.background, border: theme.primaryAction.border,
            textColor: theme.primaryAction.textColor, fontWeight: theme.primaryAction.fontWeight,
            cornerRadius: 6)
        let pngSourceStyle = CjguiComposableUiStyle(fixedWidth: 160, fixedHeight: 34,
            background: theme.primaryAction.background, border: theme.primaryAction.border,
            textColor: theme.primaryAction.textColor, fontWeight: theme.primaryAction.fontWeight,
            cornerRadius: 6)
        pngRow.add(cjguiComposableButton(NODE_PNG_TARGET, "adaptive-png-target", "PNG 粘贴 / 拖入",
            "PNG_TARGET", 8801, pngTargetStyle, enabled: true,
            interactionStyle: theme.primaryActionInteraction))
        pngRow.add(cjguiComposableButton(NODE_PNG_SOURCE, "adaptive-png-source", "拖出当前 PNG",
            "PNG_SOURCE", 8801, pngSourceStyle, enabled: pngSnapshot.offer.isSome(),
            interactionStyle: theme.primaryActionInteraction))
        root.add(pngRow)
        let pngPreview = cjguiComposableHorizontal(NODE_PNG_PREVIEW, "adaptive-png-preview",
            CjguiComposableUiStyle(growX: 1, gap: 8, fixedHeight: 78))
        if (let Some(offer) <- pngSnapshot.offer) {
            pngPreview.add(cjguiComposableImageFromTransfer(215, "adaptive-png-image", offer,
                CjguiComposableUiStyle(fixedWidth: 72, fixedHeight: 72)))
        }
        pngPreview.add(cjguiComposableText(NODE_PNG_STATUS, "adaptive-png-status",
            "PNG v${pngSnapshot.version} ${pngSnapshot.width}×${pngSnapshot.height} " +
            "${pngSnapshot.encodedBytes} B · ${lastPngOutcome}", theme.body))
        root.add(pngPreview)
        root.add(buildControlSemantics(theme))
        root.add(cjguiComposableText(197, "adaptive-control-readback",
            "控件动作 ${controlActionCount} · 复选 ${if (controlCheckboxValue) { "true" } else { "false" }} · 树焦点 ${controlTreeSelection.focus()}",
            theme.body))
        // Keep P4 controls near the top of the normal window. They live outside
        // the effect group so lowering its opacity or applying its mask cannot
        // dim the controls that change it.
        let groupActions = cjguiComposableHorizontal(83, "adaptive-effect-group-controls",
            CjguiComposableUiStyle(growX: 1, gap: 6, fixedHeight: 44,
                alignY: CJGUI_COMPOSABLE_UI_ALIGN_CENTER))
        groupActions.add(cjguiComposableButton(NODE_EFFECT_GROUP_OPACITY, "adaptive-effect-group-opacity",
            "组透明度", "EFFECT_GROUP_OPACITY", 0, theme.primaryAction,
            interactionStyle: theme.primaryActionInteraction))
        groupActions.add(cjguiComposableButton(NODE_EFFECT_GROUP_MASK, "adaptive-effect-group-mask",
            "线性 alpha 遮罩", "EFFECT_GROUP_MASK", 0, theme.primaryAction,
            interactionStyle: theme.primaryActionInteraction))
        groupActions.add(cjguiComposableButton(NODE_EFFECT_GROUP_BLEND, "adaptive-effect-group-blend",
            "normal / multiply", "EFFECT_GROUP_BLEND", 0, theme.primaryAction,
            interactionStyle: theme.primaryActionInteraction))
        groupActions.add(cjguiComposableButton(NODE_EFFECT_GROUP_MOVE, "adaptive-effect-group-move",
            "移动组内容", "EFFECT_GROUP_MOVE", 0, theme.primaryAction,
            interactionStyle: theme.primaryActionInteraction))
        groupActions.add(cjguiComposableButton(NODE_EFFECT_GROUP_BLUR, "adaptive-effect-group-blur",
            "背景模糊 0 / 8", "EFFECT_GROUP_BLUR", 0, theme.primaryAction,
            interactionStyle: theme.primaryActionInteraction))
        root.add(groupActions)
        root.add(cjguiComposableButton(NODE_SUBPOINT_TRANSLATION_TOGGLE,
            "adaptive-subpoint-translation-toggle", "亚点平移：小数 / 远移 / 清除",
            "SUBPOINT_TRANSLATION_TOGGLE", 0,
            CjguiComposableUiStyle(fixedHeight: 32, growX: 1,
                background: CjguiComposableUiColor(0.20, 0.37, 0.64, 1.0),
                textColor: CjguiComposableUiColor(1.0, 1.0, 1.0, 1.0)),
            interactionStyle: theme.primaryActionInteraction))
        root.add(cjguiComposableButton(NODE_POSITION_MOTION, "adaptive-position-motion",
            "连续平移分栏：往返", "POSITION_MOTION_TOGGLE", 0,
            CjguiComposableUiStyle(fixedHeight: 32, growX: 1,
                background: CjguiComposableUiColor(0.20, 0.37, 0.64, 1.0),
                textColor: CjguiComposableUiColor(1.0, 1.0, 1.0, 1.0)),
            interactionStyle: theme.primaryActionInteraction))
        root.add(cjguiComposableButton(NODE_POSITION_MOTION_CLEAR, "adaptive-position-motion-clear",
            "清除连续平移", "POSITION_MOTION_CLEAR", 0,
            CjguiComposableUiStyle(fixedHeight: 32, growX: 1,
                background: CjguiComposableUiColor(0.20, 0.37, 0.64, 1.0),
                textColor: CjguiComposableUiColor(1.0, 1.0, 1.0, 1.0)),
            interactionStyle: theme.primaryActionInteraction))
        root.add(buildTranslationContainers())
        // P1 effect consumption surface (shadow / gradient).
        root.add(buildEffectRegion())
        root.add(
            cjguiComposableText(NODE_EFFECT_OUTCOME, "adaptive-effect-outcome", effectOutcome, theme.body))
        // P2 hit/effect surface (interactive shadow card + alpha animation).
        root.add(buildShadowHitRegion())
        root.add(cjguiComposableText(NODE_SHADOW_HIT_STATUS, "adaptive-shadow-hit-status",
            "命中 ${hitActivationCount} 次 · ${lastHitProbe}", theme.body))
        root.add(cjguiComposableText(NODE_ANIMATION_OUTCOME, "adaptive-animation-outcome",
            lastAnimationOutcome, theme.body))
        // Normal app bundles place declared rasters directly in
        // Contents/Resources; keep the scene path bundle-relative rather
        // than leaking the source-tree layout into the packaged executable.
        // The image is a projection of the same domain record that the
        // descriptor-gated SET_MARKED action mutates.  Its explicit resource
        // version follows the durable domain version, so an external write
        // cannot leave a stale local boolean or repaint the old pixels under
        // a new semantic state.
        let imageRecord = domain.snapshot().recordAt(0)
        let beaconPath = if (imageRecord.isMarked) {
            "composable-beacon-coral.png"
        } else {
            "composable-beacon.png"
        }
        let beaconVersion = domain.version() + 1
        root.add(
            cjguiComposableImage(15, "adaptive-resource-beacon", beaconPath,
                CjguiComposableUiStyle(fixedWidth: 64, fixedHeight: 64, alignX: CJGUI_COMPOSABLE_UI_ALIGN_CENTER),
                imageResourceId: "adaptive-resource-beacon", imageResourceVersion: beaconVersion))
        // This is an ordinary public vector component in the existing normal
        // application.  Its color is the same durable field as the raster
        // beacon, and activating the accepted ellipse uses the established
        // TOGGLE_RESOURCE action rather than a private renderer shortcut.
        let vectorFill = if (imageRecord.isMarked) {
            CjguiComposableUiVectorColor(0.95, 0.30, 0.23, 0.86)
        } else {
            CjguiComposableUiVectorColor(0.18, 0.52, 0.92, 0.86)
        }
        let vectorPaint = CjguiComposableUiVectorPaint(Some(vectorFill),
            Some(CjguiComposableUiVectorColor(0.96, 0.86, 0.30, 1.0)), 2.0,
            CJGUI_COMPOSABLE_UI_VECTOR_CAP_ROUND, CJGUI_COMPOSABLE_UI_VECTOR_JOIN_ROUND)
        if (let Some(vectorBeacon) <- CjguiComposableUiVectorGeometry.ellipse(80.0, 48.0,
            CjguiComposableUiVectorPoint(40.0, 24.0), 22.0, 14.0, vectorPaint)) {
            root.add(cjguiComposableVectorGraphic(18, "adaptive-vector-beacon", vectorBeacon,
                CjguiComposableUiStyle(fixedWidth: 80, fixedHeight: 48, alignX: CJGUI_COMPOSABLE_UI_ALIGN_CENTER),
                interactive: true, actionName: "TOGGLE_RESOURCE", resourceId: 7101,
                interactionStyle: theme.primaryActionInteraction,
                ownerInteractionState: if (imageRecord.isMarked) {
                    CjguiComposableUiInteractionState.CHECKED
                } else {
                    CjguiComposableUiInteractionState.NONE
                }))
        }
        let actions = cjguiComposableHorizontal(4, "adaptive-actions",
            CjguiComposableUiStyle(growX: 1, gap: 6, alignY: CJGUI_COMPOSABLE_UI_ALIGN_CENTER))
        actions.add(
            cjguiComposableButton(
                13,
                "adaptive-refresh",
                "刷新领域状态",
                "refresh-domain",
                0,
                theme.primaryAction,
                enabled: true,
                operationActionName: "SET_MARKED",
                operationResourceId: 7101,
                interactionStyle: theme.primaryActionInteraction
            )
        )
        actions.add(
            cjguiComposableButton(
                14,
                "adaptive-close",
                "请求关闭",
                "request-close",
                0,
                theme.primaryAction,
                enabled: true,
                operationActionName: "",
                operationResourceId: 0,
                interactionStyle: theme.primaryActionInteraction
            )
        )
        actions.add(
            cjguiComposableButton(
                16,
                "adaptive-resource-toggle",
                "切换资源",
                "TOGGLE_RESOURCE",
                0,
                theme.primaryAction,
                enabled: true,
                operationActionName: "",
                operationResourceId: 0,
                interactionStyle: theme.primaryActionInteraction,
                ownerInteractionState: if (imageRecord.isMarked) {
                    CjguiComposableUiInteractionState.CHECKED
                } else {
                    CjguiComposableUiInteractionState.NONE
                }
            )
        )
        actions.add(
            cjguiComposableButton(
                17,
                "adaptive-component-toggle",
                "显示/隐藏第二个组件",
                "TOGGLE_COMPONENT",
                0,
                theme.primaryAction,
                enabled: true,
                operationActionName: "",
                operationResourceId: 0,
                interactionStyle: theme.primaryActionInteraction,
                ownerInteractionState: if (showsSecondaryToggle) {
                    CjguiComposableUiInteractionState.SELECTED
                } else {
                    CjguiComposableUiInteractionState.NONE
                }
            )
        )
        // Effect controls: one ordinary button per real transition. Each carries
        // its own action name and is also the target of a global Command shortcut
        // (declared in componentCommands), so a person and a keyboard command
        // drive the very same accepted control.
        actions.add(cjguiComposableButton(NODE_TOGGLE_SHADOW, "adaptive-effect-toggle-shadow",
            "阴影开/关", "EFFECT_TOGGLE_SHADOW", 0,
            AdaptiveEffects.handwrittenButtonStyle(showGradient, gradientVariant),
            interactionStyle: theme.primaryActionInteraction))
        actions.add(cjguiComposableButton(NODE_TOGGLE_GRADIENT, "adaptive-effect-toggle-gradient",
            "渐变开/关", "EFFECT_TOGGLE_GRADIENT", 0,
            AdaptiveEffects.handwrittenButtonStyle(showGradient, gradientVariant),
            interactionStyle: theme.primaryActionInteraction))
        actions.add(cjguiComposableButton(NODE_CYCLE_SHADOW, "adaptive-effect-cycle-shadow",
            "阴影参数", "EFFECT_CYCLE_SHADOW", 0,
            AdaptiveEffects.handwrittenButtonStyle(showGradient, gradientVariant),
            interactionStyle: theme.primaryActionInteraction))
        actions.add(cjguiComposableButton(NODE_CYCLE_GRADIENT, "adaptive-effect-cycle-gradient",
            "渐变参数", "EFFECT_CYCLE_GRADIENT", 0,
            AdaptiveEffects.handwrittenButtonStyle(showGradient, gradientVariant),
            interactionStyle: theme.primaryActionInteraction))
        actions.add(cjguiComposableButton(NODE_MOVE_CARD, "adaptive-effect-move-card",
            "移动卡片", "EFFECT_MOVE_CARD", 0,
            AdaptiveEffects.handwrittenButtonStyle(showGradient, gradientVariant),
            interactionStyle: theme.primaryActionInteraction))
        actions.add(cjguiComposableButton(NODE_SCROLL_PANE, "adaptive-effect-scroll-step",
            "滚动效果区", "EFFECT_SCROLL_STEP", 0,
            AdaptiveEffects.handwrittenButtonStyle(showGradient, gradientVariant),
            interactionStyle: theme.primaryActionInteraction))
        actions.add(cjguiComposableButton(NODE_REMOVE_EFFECTS, "adaptive-effect-remove",
            "移除效果", "EFFECT_REMOVE", 0,
            AdaptiveEffects.handwrittenButtonStyle(showGradient, gradientVariant),
            interactionStyle: theme.primaryActionInteraction))
        actions.add(cjguiComposableButton(NODE_INVALID_EFFECT, "adaptive-effect-invalid",
            "非法效果候选", "EFFECT_INVALID_CANDIDATE", 0,
            AdaptiveEffects.handwrittenButtonStyle(showGradient, gradientVariant),
            interactionStyle: theme.primaryActionInteraction))
        actions.add(cjguiComposableButton(NODE_RESTORE_EFFECTS, "adaptive-effect-restore",
            "恢复效果", "EFFECT_RESTORE", 0,
            AdaptiveEffects.handwrittenButtonStyle(showGradient, gradientVariant),
            interactionStyle: theme.primaryActionInteraction))
        actions.add(cjguiComposableButton(NODE_WINDOW_MATERIAL_TOGGLE, "adaptive-window-material-toggle",
            "系统背景开/关", "TOGGLE_WINDOW_MATERIAL", 0,
            AdaptiveEffects.handwrittenButtonStyle(showGradient, gradientVariant),
            interactionStyle: theme.primaryActionInteraction))
        actions.add(cjguiComposableButton(NODE_WINDOW_MATERIAL_CLEAR, "adaptive-window-material-clear",
            "清除系统背景", "CLEAR_WINDOW_MATERIAL", 0,
            AdaptiveEffects.handwrittenButtonStyle(showGradient, gradientVariant),
            interactionStyle: theme.primaryActionInteraction))
        root.add(actions)
        // Repeated editor/action group: its local node IDs and scope derive
        // from stable business keys rather than a copied numeric range.
        primaryToggleNodeId = -1
        secondaryToggleNodeId = -1
        let primary = componentRegistry.use("adaptive-primary")
        if (primary.isLive()) {
            let group = cjguiComposableVertical(primary.nodeId("root"), primary.semanticId("root"),
                CjguiComposableUiStyle(padding: 6, gap: 3), inputScopeId: primary.focusScopeId())
            let toggle = cjguiComposableButton(primary.nodeId("toggle"), primary.semanticId("toggle"), "主组件切换资源",
                "TOGGLE_RESOURCE", 0, CjguiComposableUiStyle(fixedHeight: 28),
                interactionStyle: theme.primaryActionInteraction,
                ownerInteractionState: if (imageRecord.isMarked) { CjguiComposableUiInteractionState.CHECKED } else {
                    CjguiComposableUiInteractionState.NONE
                })
            group.add(toggle);
            root.add(group)
            primaryToggleNodeId = toggle.nodeId
            primaryToggleScope = primary.focusScopeId()
        }
        if (showsSecondaryToggle) {
            let secondary = componentRegistry.use("adaptive-secondary")
            if (secondary.isLive()) {
                let group = cjguiComposableVertical(secondary.nodeId("root"), secondary.semanticId("root"),
                    CjguiComposableUiStyle(padding: 6, gap: 3), inputScopeId: secondary.focusScopeId())
                let toggle = cjguiComposableButton(secondary.nodeId("toggle"), secondary.semanticId("toggle"),
                    "第二组件切换资源", "TOGGLE_RESOURCE", 0, CjguiComposableUiStyle(fixedHeight: 28),
                    interactionStyle: theme.primaryActionInteraction,
                    ownerInteractionState: if (imageRecord.isMarked) { CjguiComposableUiInteractionState.CHECKED } else {
                        CjguiComposableUiInteractionState.NONE
                    })
                group.add(toggle);
                root.add(group)
                secondaryToggleNodeId = toggle.nodeId
                secondaryToggleScope = secondary.focusScopeId()
            }
        }
        return root
    }

    public func uiSceneVersion(): Int64 {
        return domain.version() + localRevision + pngOwner.version()
    }

    public func imageOwner(): CjguiSharedOperationImageOwner { return pngOwner }

    /// Real, inspectable effect transitions. Each branch reaches the SAME public
    /// state the button's action name names; a global Command shortcut emits the
    /// same event as the button activation, so both paths are one transition.
    private func applyEffectAction(actionName: String): Bool {
        if (actionName == "EFFECT_TOGGLE_SHADOW") {
            showShadow = !showShadow
            effectOutcome = "阴影已${if (showShadow) { "开启" } else { "关闭" }}"
            return true
        }
        if (actionName == "EFFECT_TOGGLE_GRADIENT") {
            showGradient = !showGradient
            effectOutcome = "渐变已${if (showGradient) { "开启" } else { "关闭" }}"
            return true
        }
        if (actionName == "EFFECT_CYCLE_SHADOW") {
            shadowVariant = (shadowVariant + 1) % 3
            showShadow = true
            effectOutcome = "阴影参数 → v${shadowVariant}"
            return true
        }
        if (actionName == "EFFECT_CYCLE_GRADIENT") {
            gradientVariant = (gradientVariant + 1) % 3
            showGradient = true
            effectOutcome = "渐变参数 → v${gradientVariant}"
            return true
        }
        if (actionName == "EFFECT_MOVE_CARD") {
            // 0 -> 60 (partly past the clip edge) -> 200 (outside the clip).
            cardShift = if (cardShift == 0) {
                60
            } else if (cardShift == 60) {
                200
            } else {
                0
            }
            effectOutcome = "卡片位移 → ${cardShift}pt（裁剪区内/边缘/裁剪区外）"
            return true
        }
        if (actionName == "EFFECT_SCROLL_STEP") {
            let moved = effectViewport.step("next", 40)
            effectOutcome = if (moved) {
                "效果区已滚动，offset=${effectViewport.offset()}"
            } else {
                "效果区已在可滚动范围边界，offset=${effectViewport.offset()}"
            }
            return true
        }
        if (actionName == "EFFECT_GROUP_OPACITY") {
            effectGroupOpacity = if (effectGroupOpacity < 1.0) { 1.0 } else { 0.58 }
            effectOutcome = "效果组 opacity → ${effectGroupOpacity}"
            effectGroupActionCount += 1
            return true
        }
        if (actionName == "EFFECT_GROUP_MASK") {
            effectGroupMaskEnabled = !effectGroupMaskEnabled
            effectOutcome = "效果组 alpha mask → ${if (effectGroupMaskEnabled) { "on" } else { "off" }}"
            effectGroupActionCount += 1
            return true
        }
        if (actionName == "EFFECT_GROUP_BLEND") {
            effectGroupBlendMode = if (effectGroupBlendMode == "normal") { "multiply" } else { "normal" }
            effectOutcome = "效果组合成模式 → ${effectGroupBlendMode}"
            effectGroupActionCount += 1
            return true
        }
        if (actionName == "EFFECT_GROUP_MOVE") {
            cardShift = if (cardShift == 0) { 52 } else { 0 }
            effectOutcome = "效果组内容布局位移 → ${cardShift}pt"
            effectGroupActionCount += 1
            return true
        }
        if (actionName == "EFFECT_GROUP_BLUR") {
            effectGroupBlurRadiusPoints = if (effectGroupBlurRadiusPoints == 0) { 8 } else { 0 }
            effectOutcome = "效果组背景模糊 → ${effectGroupBlurRadiusPoints}pt，fallback=unblurred"
            effectGroupActionCount += 1
            return true
        }
        if (actionName == "EFFECT_GROUP_ACTION") {
            effectGroupActionCount += 1
            effectOutcome = "效果组内真实按钮已操作 ${effectGroupActionCount} 次"
            return true
        }
        if (actionName == "SUBPOINT_TRANSLATION_TOGGLE") {
            translationVariant = (translationVariant + 1) % 3
            effectOutcome = "亚点平移变体 ${translationVariant}（accepted 几何与点击同源）"
            return true
        }
        if (actionName == "POSITION_MOTION_TOGGLE") {
            let window = match (hitWindow) {
                case Some(value) => value
                case None => return false
            }
            var identity = ""
            var baseX = 0.0
            var baseY = 0.0
            for (node in window.acceptedSceneNodes()) {
                if (node.semanticId == "adaptive-translated-split") {
                    identity = node.identityKey
                    baseX = node.declaredStyle.translateX
                    baseY = node.declaredStyle.translateY
                }
            }
            if (identity.size == 0) { return false }
            let nextHigh = !positionMotionHigh
            let spec = CjguiGeneratedMotionRegistry.positionTransitionRule().spec() ??
                CjguiComposableUiAnimationSpec.tween(durationMs: 240)
            let targetX = baseX + (if (nextHigh) { 24.0 } else { 0.0 })
            let targetY = baseY + (if (nextHigh) { 12.0 } else { 0.0 })
            let started = window.animateNodeTranslation(identity, targetX, targetY, spec: spec,
                atTime: MonoTime.now())
            if (started) { positionMotionHigh = nextHigh }
            let status = window.animatedNodeTranslation(identity)
            let accepted = match (status) {
                case Some(value) => "${value.presented.x},${value.presented.y}"
                case None => "none"
            }
            effectOutcome = "连续平移 target=${targetX},${targetY} accepted=${accepted}"
            getStdOut().writeln("CJGUI_ADAPTIVE_POSITION_STATE identity=${identity} " +
                "started=${if (started) { 1 } else { 0 }} target=${targetX},${targetY} " +
                "accepted=${accepted} owner_version=${domain.version()}")
            getStdOut().flush()
            return started
        }
        if (actionName == "POSITION_MOTION_CLEAR") {
            let window = match (hitWindow) {
                case Some(value) => value
                case None => return false
            }
            for (node in window.acceptedSceneNodes()) {
                if (node.semanticId == "adaptive-translated-split") {
                    let cleared = window.cancelNodeTranslationAnimation(node.identityKey)
                    if (cleared) { positionMotionHigh = false }
                    effectOutcome = "连续平移清除=${if (cleared) { 1 } else { 0 }}"
                    return cleared
                }
            }
            return false
        }
        if (actionName == "EFFECT_REMOVE") {
            showShadow = false
            showGradient = false
            shadowVariant = 0
            gradientVariant = 0
            effectOutcome = "效果已移除：卡片无阴影、无渐变，手写入口同步无效果"
            return true
        }
        if (actionName == "EFFECT_RESTORE") {
            showShadow = true
            showGradient = true
            shadowVariant = 0
            gradientVariant = 0
            cardShift = 0
            let _ = effectViewport.requestOffset(0)
            effectOutcome = "效果已恢复：阴影+渐变，卡片回到裁剪区顶部"
            return true
        }
        if (actionName == "EFFECT_INVALID_CANDIDATE") {
            effectOutcome = rejectInvalidEffects()
            return true
        }
        // --- P2 hit test negative control + paint-alpha animation -------------
        if (actionName == "SHADOW_HIT_TARGET") {
            // Only a real activation that reached this node's own bounds runs
            // this branch; a click in the shadow band is never delivered here.
            hitActivationCount += 1
            lastHitProbe = probeShadowHit()
            getStdOut().writeln("CJGUI_SHADOW_HIT_STATE clicked=1 count=${hitActivationCount}")
            getStdOut().flush()
            return true
        }
        if (actionName == "EFFECT_HOVER_TOGGLE") {
            hoverActive = !hoverActive
            let target = if (hoverActive) { SHADOW_HIT_ALPHA_HOVER } else { SHADOW_HIT_ALPHA_NORMAL }
            animateShadowHit(target, CjguiComposableUiAnimationSpec.tween(durationMs: 140,
                easing: CjguiComposableUiAnimationEasing.EASE_IN_OUT), "hover=${if (hoverActive) { "on" } else { "off" }}")
            return true
        }
        if (actionName == "EFFECT_PRESS_TOGGLE") {
            pressedActive = !pressedActive
            let target = if (pressedActive) { SHADOW_HIT_ALPHA_PRESSED } else { SHADOW_HIT_ALPHA_NORMAL }
            animateShadowHit(target, CjguiComposableUiAnimationSpec.spring(stiffness: 260.0, dampingRatio: 1.0),
                "pressed=${if (pressedActive) { "on" } else { "off" }}")
            return true
        }
        if (actionName == "EFFECT_ANIMATION_PROBE") {
            lastHitProbe = probeShadowHit()
            emitAnimationObservation("probe")
            return true
        }
        return false
    }

    /// Drive the framework paint-alpha animation on the interactive card through
    /// the public window entry. The identity is the card's stable semantic
    /// identity, so a repeated, fast call is a retarget that keeps the current
    /// visual value (and spring velocity) instead of restarting from a stale
    /// origin — the deterministic mid-flight reverse the acceptance asks for.
    private func animateShadowHit(target: Float64, spec: CjguiComposableUiAnimationSpec, reason: String): Unit {
        match (hitWindow) {
            case Some(window) =>
                let started = window.animateNodeOpacity(SHADOW_HIT_IDENTITY, target,
                    spec: spec, atTime: MonoTime.now())
                let presented = window.animatedNodeOpacity(SHADOW_HIT_IDENTITY)
                let observed = match (presented) {
                    case Some(value) => value
                    case None => -1.0
                }
                lastAnimationOutcome = "动效 ${reason} 目标=${target} 当前=${observed} " +
                    "活动=${window.activeAnimationCount()} 绑定=${window.animationBindingCount()}"
                let reduceMotionToken = if (window.reduceMotionEnabled()) { 1 } else { 0 }
                getStdOut().writeln("CJGUI_ADAPTIVE_ANIMATION_STATE reason=${reason} " +
                    "identity=${SHADOW_HIT_IDENTITY} started=${if (started) { 1 } else { 0 }} target=${target} " +
                    "presented=${observed} active=${window.activeAnimationCount()} " +
                    "bindings=${window.animationBindingCount()} reduceMotion=${reduceMotionToken}")
                getStdOut().flush()
            case None =>
                lastAnimationOutcome = "动效 ${reason} 未驱动：窗口尚未接入"
        }
    }

    /// Read back the current target/presented alpha and activity from the window
    /// so an external reader can observe the animation without per-frame
    /// broadcasts.
    private func emitAnimationObservation(reason: String): Unit {
        match (hitWindow) {
            case Some(window) =>
                let presented = match (window.animatedNodeOpacity(SHADOW_HIT_IDENTITY)) {
                    case Some(value) => value
                    case None => -1.0
                }
                let target = match (window.animatedNodeOpacityTarget(SHADOW_HIT_IDENTITY)) {
                    case Some(value) => value
                    case None => -1.0
                }
                getStdOut().writeln("CJGUI_ADAPTIVE_ANIMATION_OBSERVED reason=${reason} " +
                    "identity=${SHADOW_HIT_IDENTITY} target=${target} presented=${presented} " +
                    "activeCount=${window.activeAnimationCount()} bindings=${window.animationBindingCount()}")
                getStdOut().flush()
            case None =>
                getStdOut().writeln("CJGUI_ADAPTIVE_ANIMATION_OBSERVED reason=${reason} window=none")
                getStdOut().flush()
        }
    }

    /// Consumer-level hit negative control. It reads the ACCEPTED scene and applies
    /// the same rule the framework uses for a hit: an enabled, input-capable node
    /// whose own `bounds` and resolved clip contain the point. It then checks a
    /// point inside the card and a point inside the shadow band (outside the
    /// card's own bounds but inside its `effectOutputBounds`): the inside point
    /// must resolve to the card, the shadow-band point must NOT. `bounds` never
    /// grows for a paint-only shadow, which is exactly what this proves.
    private func probeShadowHit(): String {
        let window = match (hitWindow) {
            case Some(value) => value
            case None => return "命中探针：窗口未接入"
        }
        var cardNode = CjguiComposableUiLayoutNode.missing()
        var found = false
        for (node in window.acceptedSceneNodes()) {
            if (node.semanticId == SHADOW_HIT_SEMANTIC) {
                cardNode = node
                found = true
            }
        }
        if (!found) {
            return "命中探针：accepted 场景暂无 ${SHADOW_HIT_SEMANTIC}"
        }
        let bounds = cardNode.bounds
        let output = cardNode.effectOutputBounds()
        let shadowOffsetY = match (cardNode.declaredStyle.shadow) {
            case Some(value) => value.offsetY
            case None => 0
        }
        let insideX = bounds.x + bounds.width / 2
        let insideY = bounds.y + bounds.height / 2
        // The shadow band sits below the card's own frame but inside the shadow
        // support domain; blurRadius*3 + spread keeps it clearly separated.
        let bandY = bounds.y + bounds.height + shadowOffsetY / 2 + 6
        let bandX = bounds.x + bounds.width / 2
        let insideTarget = hitNodeIdAt(window, insideX, insideY)
        let bandTarget = hitNodeIdAt(window, bandX, bandY)
        let insideIsCard = insideTarget == cardNode.nodeId
        let bandIsCard = bandTarget == cardNode.nodeId
        let shadowPresent = cardNode.declaredStyle.shadow.isSome()
        let separated = output.height > bounds.height
        let verdict = insideIsCard && !bandIsCard && shadowPresent && separated
        return "命中探针 定义=${SHADOW_HIT_SEMANTIC} 阴影=${if (shadowPresent) { 1 } else { 0 }} " +
            "输出高于本体=${if (separated) { 1 } else { 0 }} 框内命中=${if (insideIsCard) { 1 } else { 0 }} " +
            "阴影带命中=${if (bandIsCard) { 1 } else { 0 }} 判定=${if (verdict) { "PASS" } else { "FAIL" }} " +
            "框内点=(${insideX},${insideY}) 阴影点=(${bandX},${bandY})"
    }

    /// The framework's published hit rule (innermost enabled input-capable node
    /// whose bounds and clip contain the point) applied to the accepted scene.
    /// It reads the same public node geometry the window uses, so a point outside
    /// a node's own bounds can never resolve to it.
    private func hitNodeIdAt(window: CjguiComposableUiWindow, x: Int64, y: Int64): Int64 {
        var best = CjguiComposableUiLayoutNode.missing()
        var found = false
        for (node in window.acceptedSceneNodes()) {
            if (node.canReceiveInput() && node.bounds.contains(x, y) && node.containsResolvedClip(x, y)) {
                if (!found || node.bounds.width * node.bounds.height <= best.bounds.width * best.bounds.height) {
                    best = node
                    found = true
                }
            }
        }
        return if (found) { best.nodeId } else { -1 }
    }

    /// Attempts to declare malformed effects through the SAME public parsing and
    /// Style entries. The framework refuses each one (parse returns None / the
    /// style normalizes an invalid gradient away), the accepted state is
    /// untouched, and the application keeps operating.
    public func rejectInvalidEffects(): String {
        // Malformed shadow token: a non-integer field is refused whole.
        let badShadow = cjguiComposableUiParseShadowToken("12,oops,8,0,#000000")
        // Malformed gradient token: a coordinate outside 0..100 is refused whole.
        let badGradient = cjguiComposableUiParseGradientToken("0,0,140,0,0:#112233ff|100:#445566ff")
        // A gradient with a single stop is structurally invalid; the Style
        // constructor normalizes it to None instead of staging an illegal scene.
        let singleStop = CjguiComposableUiLinearGradient(stops: [
            CjguiComposableUiGradientStop(position: 0.5, color: CjguiComposableUiColor(1.0, 0.0, 0.0, 1.0))
        ])
        let normalized = CjguiComposableUiStyle(shadow: badShadow, gradient: singleStop)
        let shadowTokenRefused = badShadow.isNone()
        let gradientTokenRefused = badGradient.isNone()
        let styleShadowRefused = normalized.shadow.isNone()
        let styleGradientRefused = normalized.gradient.isNone()
        if (shadowTokenRefused && gradientTokenRefused && styleShadowRefused && styleGradientRefused) {
            return "非法效果候选均被拒绝（shadow token=${shadowTokenRefused} gradient token=${gradientTokenRefused} " +
                "style.shadow=${styleShadowRefused} style.gradient=${styleGradientRefused}），应用继续正常"
        }
        return "非法效果候选被拒绝但存在未覆盖分支"
    }

    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {

        if (event.eventKind == 28 && event.node.nodeId == NODE_TRANSLATED_TITLE_INPUT) {
            let changed = domain.setTitleFromHuman(7101, event.text)
            return CjguiComposableUiDispatchResult(changed.applied)
        }

        if (event.eventKind == 35 && event.node.nodeId == 192) {
            let moved = controlTreeSelection.navigate(event.text,
                (event.modifierFlags & CJGUI_UI_MODIFIER_SHIFT) != 0)
            if (!moved.didChange) { return CjguiComposableUiDispatchResult(false) }
            if (let Some(rows) <- activeControlTreeListSource) {
                let _ = controlTreeListState.revealKey(rows, moved.focus)
            }
            if (let Some(window) <- hitWindow) {
                let _ = window.focusScopedNode(
                    CjguiComposableUiIdentityScope("adaptive-control-rows").child(moved.focus), "row")
            }
            localRevision += 1
            return CjguiComposableUiDispatchResult(true)
        }
        if (event.eventKind == 30 && event.node.nodeId == 192) {
            let before = controlTreeListState.scrollOffset()
            controlTreeListState.scrollByViewport(event.text)
            if (before == controlTreeListState.scrollOffset()) { return CjguiComposableUiDispatchResult(false) }
            localRevision += 1
            return CjguiComposableUiDispatchResult(true)
        }
        if (event.eventKind == 27 && event.node.actionName == "ADAPTIVE_TREE_ROW") {
            let key = if (event.node.resourceId == 991) { "branch" }
                else if (event.node.resourceId == 992) { "leaf-a" }
                else if (event.node.resourceId == 993) { "leaf-b" } else { "" }
            if (key.size == 0) { return CjguiComposableUiDispatchResult(false) }
            if (key == "branch") {
                let _ = controlTreeProjection.toggleExpand(key)
                controlTreeSelection.ensureFocusVisible()
            } else {
                controlTreeSelection.click(key, false, false)
            }
            controlActionCount += 1
            getStdOut().writeln("CJGUI_ADAPTIVE_CONTROL action=tree key=${key} count=${controlActionCount}")
            localRevision += 1
            return CjguiComposableUiDispatchResult(true)
        }
        if (event.eventKind == 27 && event.node.actionName == "ADAPTIVE_CONTROL_BUTTON") {
            let window = match (hitWindow) {
                case Some(value) => value
                case None => return CjguiComposableUiDispatchResult(false)
            }
            let next = if (window.platformAccentStatus().preference == "system") { "#b02088ff" }
                else { "system" }
            if (!window.selectAccentPreference(next)) { return CjguiComposableUiDispatchResult(false) }
            controlActionCount += 1
            getStdOut().writeln("CJGUI_ADAPTIVE_CONTROL action=button accent_preference=${next} " +
                "count=${controlActionCount}")
            localRevision += 1
            return CjguiComposableUiDispatchResult(true)
        }
        if (event.eventKind == 29 && event.node.nodeId == 196) {
            controlCheckboxValue = event.text == "true"
            controlActionCount += 1
            getStdOut().writeln("CJGUI_ADAPTIVE_CONTROL action=checkbox value=${controlCheckboxValue} count=${controlActionCount}")
            localRevision += 1
            return CjguiComposableUiDispatchResult(true)
        }

        if (event.eventKind == 27 && event.node.actionName == "TOGGLE_RESOURCE") {
            let current = domain.snapshot().recordAt(0).isMarked
            let result = domain.setMarkedFromHuman(7101, !current)
            if (!result.applied) {
                return CjguiComposableUiDispatchResult(false, shouldClose: false)
            }
        }
        if (event.eventKind == 27 && event.node.actionName == "TOGGLE_COMPONENT") {
            showsSecondaryToggle = !showsSecondaryToggle
        }
        if (event.eventKind == 27 && applyEffectAction(event.node.actionName)) {
            emitEffectState()
        }
        if (event.eventKind == 27 && event.node.actionName == "TOGGLE_WINDOW_MATERIAL") {
            systemContentAreaRequested = !systemContentAreaRequested
            getStdOut().writeln("CJGUI_ADAPTIVE_WINDOW_MATERIAL_REQUEST ${candidateWindowBackground()}")
        }
        if (event.eventKind == 27 && event.node.actionName == "CLEAR_WINDOW_MATERIAL") {
            systemContentAreaRequested = false
            getStdOut().writeln("CJGUI_ADAPTIVE_WINDOW_MATERIAL_REQUEST ${candidateWindowBackground()}")
        }
        localRevision += 1
        return CjguiComposableUiDispatchResult(true, shouldClose: false)
    }

    /// One stable, greppable line per effect transition: the anchor a verification
    /// script can correlate with the on-screen accepted state.
    private func emitEffectState(): Unit {
        getStdOut().writeln("ADAPTIVE_EFFECT_STATE shadow=${if (showShadow) { 1 } else { 0 }} " +
            "gradient=${if (showGradient) { 1 } else { 0 }} shadowVariant=${shadowVariant} " +
            "gradientVariant=${gradientVariant} cardShift=${cardShift} " +
            "scrollOffset=${effectViewport.offset()} outcome=${effectOutcome}")
        getStdOut().flush()
    }

    public func rejectUiEvent(nodeId: Int64, eventKind: Int64): CjguiComposableUiDispatchResult {
        getStdErr().writeln("ADAPTIVE_UI_EVENT_REJECTED node=${nodeId} kind=${eventKind}")
        return CjguiComposableUiDispatchResult(false, shouldClose: false)
    }

    public func dataTransferDeclarations(): ArrayList<CjguiComposableUiDataTransferDeclaration> {
        let declarations = ArrayList<CjguiComposableUiDataTransferDeclaration>()
        declarations.add(CjguiComposableUiDataTransferDeclaration.target(
            "adaptive-png-target", CjguiSharedOperationTransferFormat.png(),
            receiverIncarnation: pngReceiverIncarnation, localPngFileAllowed: true))
        if (let Some(offer) <- pngOwner.snapshot().offer) {
            declarations.add(CjguiComposableUiDataTransferDeclaration.source("adaptive-png-source", offer))
        }
        return declarations
    }

    public func dataTransferOwnerVersion(node: CjguiComposableUiLayoutNode): Int64 {
        return if (node.semanticId == "adaptive-png-target") { pngOwner.version() } else { -1 }
    }

    public func applyDataTransfer(event: CjguiComposableUiDataTransferEvent): CjguiComposableUiDispatchResult {
        if (event.eventKind == CJGUI_COMPOSABLE_UI_EVENT_DATA_TRANSFER_COPY) {
            getStdOut().writeln("CJGUI_PNG_COPY consumer=adaptive version=${pngOwner.version()}")
            getStdOut().flush()
            return CjguiComposableUiDispatchResult(false)
        }
        let ownerStarted = MonoTime.now()
        let result = pngOwner.accept(event.offer, event.expectedOwnerVersion,
            event.imageWidth, event.imageHeight)
        let ownerMicros = (MonoTime.now() - ownerStarted).toMicroseconds()
        if (!result.applied) {
            let _ = rejectDataTransfer(event.node.nodeId, event.eventKind, result.reason)
            return CjguiComposableUiDispatchResult(false, transferResult: Some(result))
        }
        lastPngDecodeMicros = event.decodeMicros
        lastPngOutcome = "accepted ${event.offer.contentDigest}"
        localRevision += 1
        getStdOut().writeln("CJGUI_PNG_OWNER consumer=adaptive kind=${event.eventKind} " +
            "version=${pngOwner.version()} bytes=${event.offer.payloadByteCount} " +
            "digest=${event.offer.contentDigest} width=${event.imageWidth} height=${event.imageHeight} " +
            "decode_us=${event.decodeMicros} owner_us=${ownerMicros} epoch=${event.bindingEpoch}")
        getStdOut().flush()
        return CjguiComposableUiDispatchResult(true, transferResult: Some(result))
    }

    public func rejectDataTransfer(nodeId: Int64, eventKind: Int64, reason: String): CjguiComposableUiDispatchResult {
        lastPngOutcome = "rejected ${reason}"
        localRevision += 1
        getStdOut().writeln("CJGUI_PNG_REJECT consumer=adaptive kind=${eventKind} " +
            "node=${nodeId} reason=${reason} version=${pngOwner.version()}")
        getStdOut().flush()
        return CjguiComposableUiDispatchResult(false)
    }

    public func requestWindowClose(): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(true, shouldClose: true)
    }
    public func componentCommands(): ArrayList<CjguiComposableUiCommand> {
        let commands = ArrayList<CjguiComposableUiCommand>()
        if (primaryToggleNodeId >= 0) {
            commands.add(
                CjguiComposableUiCommand("adaptive.primary.toggle", primaryToggleNodeId, CjguiComposableUiShortcut("m"),
                    focusScopeId: primaryToggleScope))
        }
        if (secondaryToggleNodeId >= 0 && showsSecondaryToggle) {
            commands.add(
                CjguiComposableUiCommand("adaptive.secondary.toggle", secondaryToggleNodeId,
                    CjguiComposableUiShortcut("m"), focusScopeId: secondaryToggleScope))
        }
        // Global keyboard commands (Command+1..9) target the accepted effect
        // controls. Each declaration and each shortcut is unique within the empty
        // focus scope, so the accepted scene keeps all nine live.
        commands.add(CjguiComposableUiCommand("adaptive.effect.toggleShadow", NODE_TOGGLE_SHADOW,
            CjguiComposableUiShortcut("1")))
        commands.add(CjguiComposableUiCommand("adaptive.effect.toggleGradient", NODE_TOGGLE_GRADIENT,
            CjguiComposableUiShortcut("2")))
        commands.add(CjguiComposableUiCommand("adaptive.effect.cycleShadow", NODE_CYCLE_SHADOW,
            CjguiComposableUiShortcut("3")))
        commands.add(CjguiComposableUiCommand("adaptive.effect.cycleGradient", NODE_CYCLE_GRADIENT,
            CjguiComposableUiShortcut("4")))
        commands.add(CjguiComposableUiCommand("adaptive.effect.moveCard", NODE_MOVE_CARD,
            CjguiComposableUiShortcut("5")))
        commands.add(CjguiComposableUiCommand("adaptive.effect.scroll", NODE_SCROLL_PANE,
            CjguiComposableUiShortcut("6")))
        commands.add(CjguiComposableUiCommand("adaptive.effect.remove", NODE_REMOVE_EFFECTS,
            CjguiComposableUiShortcut("7")))
        commands.add(CjguiComposableUiCommand("adaptive.effect.invalid", NODE_INVALID_EFFECT,
            CjguiComposableUiShortcut("8")))
        commands.add(CjguiComposableUiCommand("adaptive.effect.restore", NODE_RESTORE_EFFECTS,
            CjguiComposableUiShortcut("9")))
        commands.add(CjguiComposableUiCommand("adaptive.windowMaterial.toggle", NODE_WINDOW_MATERIAL_TOGGLE,
            CjguiComposableUiShortcut("b")))
        commands.add(CjguiComposableUiCommand("adaptive.windowMaterial.clear", NODE_WINDOW_MATERIAL_CLEAR,
            CjguiComposableUiShortcut("n")))
        // P2 hit/animation commands. The keys avoid the system-reserved Cmd+H
        // (hide application): j/k/l are plain command shortcuts on this window.
        commands.add(CjguiComposableUiCommand("adaptive.hit.hover", NODE_HOVER_TOGGLE,
            CjguiComposableUiShortcut("j")))
        commands.add(CjguiComposableUiCommand("adaptive.hit.press", NODE_PRESS_TOGGLE,
            CjguiComposableUiShortcut("k")))
        commands.add(CjguiComposableUiCommand("adaptive.hit.probe", NODE_ANIMATION_PROBE,
            CjguiComposableUiShortcut("l")))
        commands.add(CjguiComposableUiCommand("adaptive.effectGroup.opacity", NODE_EFFECT_GROUP_OPACITY,
            CjguiComposableUiShortcut("u")))
        commands.add(CjguiComposableUiCommand("adaptive.effectGroup.mask", NODE_EFFECT_GROUP_MASK,
            CjguiComposableUiShortcut("i")))
        commands.add(CjguiComposableUiCommand("adaptive.effectGroup.blend", NODE_EFFECT_GROUP_BLEND,
            CjguiComposableUiShortcut("o")))
        commands.add(CjguiComposableUiCommand("adaptive.effectGroup.move", NODE_EFFECT_GROUP_MOVE,
            CjguiComposableUiShortcut("p")))
        return commands
    }
    public func beginSceneRefresh(): Bool {
        return componentRegistry.beginTransaction()
    }
    public func prepareSceneRefresh(): Bool {
        return componentRegistry.prepareTransaction()
    }
    public func candidateSceneCommands(): ArrayList<CjguiComposableUiCommand> {
        return componentCommands()
    }
    public func commitSceneRefresh(): Unit {
        componentRegistry.commitTransaction()
    }
    public func rollbackSceneRefresh(): Unit {
        componentRegistry.rollbackTransaction()
    }

    public func translationContainerObservation(): String {
        return "split=${translationSplitState.firstSize()}/${translationSplitState.acceptedFirstSize()} " +
            "viewport=${translationViewport.offset()}/${translationViewport.acceptedOffset()}"
    }
}

/// Float comparison helper for the consumer's own B3 assertions.
private func cjguiAdaptiveAbs(value: Float64): Float64 {
    return if (value < 0.0) { -value } else { value }
}

private func cjguiAdaptiveApprox(actual: Float64, expected: Float64, tolerance: Float64): Bool {
    return cjguiAdaptiveAbs(actual - expected) <= tolerance
}

private func cjguiAdaptiveVisualOffsetIs(window: CjguiComposableUiWindow,
    semanticId: String, expectedX: Float64, expectedY: Float64): Bool {
    if (let Some(layout) <- window.acceptedNodeBounds(semanticId)) {
        if (let Some(visual) <- window.acceptedNodeVisualBounds(semanticId)) {
            return cjguiAdaptiveApprox(visual.x - Float64(layout.x), expectedX, 0.0001) &&
                cjguiAdaptiveApprox(visual.y - Float64(layout.y), expectedY, 0.0001) &&
                cjguiAdaptiveApprox(visual.width, Float64(layout.width), 0.0001) &&
                cjguiAdaptiveApprox(visual.height, Float64(layout.height), 0.0001)
        }
    }
    return false
}

/// Resolve the ordinary button from the accepted scene, then dispatch the same
/// button event to the application's normal controller handler. This keeps the
/// verification action tied to the consumer's real node identity/action name.
private func cjguiAdaptiveActivateAcceptedButton(window: CjguiComposableUiWindow,
    controller: AdaptiveController, nodeId: Int64, actionName: String): Bool {
    for (node in window.acceptedSceneNodes()) {
        if (node.nodeId == nodeId && node.nodeKind == CJGUI_COMPOSABLE_UI_BUTTON &&
            node.actionName == actionName) {
            return controller.applyUiEvent(CjguiComposableUiEvent(node, 27, "", 0, 0, 0)).didApply
        }
    }
    return false
}

private func cjguiAdaptivePumpUntilEffectGroupState(host: CjguiMacosApplicationHost,
    controller: AdaptiveController, opacity: Float64, blend: String, maskEnabled: Bool): Bool {
    var turns = 0
    while (turns < 24 && host.isOpen() &&
        !controller.effectGroupAcceptedStateIs(opacity, blend, maskEnabled)) {
        let _ = host.pumpOneTurn()
        turns += 1
    }
    return controller.effectGroupAcceptedStateIs(opacity, blend, maskEnabled)
}

private func cjguiAdaptivePumpUntilEffectGroupBlur(host: CjguiMacosApplicationHost,
    controller: AdaptiveController, radiusPoints: Int64): Bool {
    var turns = 0
    while (turns < 24 && host.isOpen() &&
        !controller.effectGroupAcceptedBlurRadiusIs(radiusPoints)) {
        let _ = host.pumpOneTurn()
        turns += 1
    }
    return controller.effectGroupAcceptedBlurRadiusIs(radiusPoints)
}

/// Judge the native system-window receipt only through the public window
/// progress projection. Reduce Transparency has one declared opaque fallback;
/// otherwise macOS must report the installed AppKit behind-window host.
private func cjguiAdaptiveWindowMaterialMatches(progress: CjguiSharedOperationWindowProgress,
    requested: String, requireCurrentScene: Bool): Bool {
    let actualMatches = if (requested == CjguiWindowBackgroundPolicy.SYSTEM_CONTENT_AREA) {
        if (progress.windowBackgroundReduceTransparency) {
            progress.windowBackgroundActual == "opaque_fallback" &&
                progress.windowBackgroundFallbackReason == "reduce_transparency"
        } else {
            progress.windowBackgroundActual == "system_host_installed" &&
                progress.windowBackgroundFallbackReason == "none"
        }
    } else {
        progress.windowBackgroundActual == "opaque" &&
            progress.windowBackgroundFallbackReason == "not_requested"
    }
    let sceneMatches = !requireCurrentScene ||
        progress.windowBackgroundAcceptedSceneVersion == progress.acceptedSceneVersion
    return progress.isActive && progress.windowBackgroundIdentity == "window_content_background" &&
        progress.windowBackgroundRequested == requested &&
        progress.windowBackgroundBackend == "appkit_behind_window" &&
        progress.windowBackgroundFrameIndex >= 0 && progress.windowBackgroundCompletion == "succeeded" &&
        progress.windowBackgroundAcceptedSceneVersion >= 0 && sceneMatches && actualMatches
}

private func cjguiAdaptivePumpUntilWindowMaterial(host: CjguiMacosApplicationHost,
    window: CjguiComposableUiWindow, requested: String): CjguiSharedOperationWindowProgress {
    var progress = window.windowProgress()
    var turns = 0
    while (turns < 32 && host.isOpen() &&
        !cjguiAdaptiveWindowMaterialMatches(progress, requested, true)) {
        let _ = host.pumpOneTurn()
        progress = window.windowProgress()
        turns += 1
    }
    return progress
}

/// Dispatch one accepted material control through the consumer's ordinary
/// button handler, preserving the accepted node's identity and action name.
private func cjguiAdaptiveActivateWindowMaterialButton(window: CjguiComposableUiWindow,
    controller: AdaptiveController, nodeId: Int64, actionName: String): Bool {
    for (node in window.acceptedSceneNodes()) {
        if (node.nodeId == nodeId && node.nodeKind == CJGUI_COMPOSABLE_UI_BUTTON &&
            node.actionName == actionName) {
            return controller.applyUiEvent(CjguiComposableUiEvent(node, 27, "", 0, 0, 0)).didApply
        }
    }
    return false
}

private func cjguiAdaptivePumpUntilAcceptedSceneAdvance(host: CjguiMacosApplicationHost,
    window: CjguiComposableUiWindow, previousVersion: Int64): CjguiSharedOperationWindowProgress {
    var progress = window.windowProgress()
    var turns = 0
    while (turns < 32 && host.isOpen() && progress.acceptedSceneVersion <= previousVersion) {
        let _ = host.pumpOneTurn()
        progress = window.windowProgress()
        turns += 1
    }
    return progress
}

private func cjguiAdaptiveDiagnosticNode(snapshot: CjguiComposableUiDiagnosticSnapshot,
    identity: String): ?CjguiComposableUiDiagnosticNode {
    for (node in snapshot.nodes) {
        if (node.identityKey == identity) { return Some(node) }
    }
    return None
}

private func cjguiAdaptiveWaitDiagnosticIdle(host: CjguiMacosApplicationHost,
    window: CjguiComposableUiWindow): Int64 {
    var stable = 0
    var turns = 0
    var previous = window.diagnosticSnapshot(maximumNodes: 1).nativeSubmissionCount
    while (host.isOpen() && turns < 100 && stable < 4) {
        let _ = host.pumpOneTurn()
        let current = window.diagnosticSnapshot(maximumNodes: 1).nativeSubmissionCount
        if (current == previous && !window.needsAnimationTick()) {
            stable += 1
        } else {
            stable = 0
        }
        previous = current
        turns += 1
    }
    return turns
}

private func cjguiAdaptiveDiagnosticReadBatch(window: CjguiComposableUiWindow): Int64 {
    let started = MonoTime.now()
    var count = 0
    while (count < 24) {
        let _ = window.diagnosticSnapshot(maximumNodes: 256)
        count += 1
    }
    return (MonoTime.now() - started).toMicroseconds()
}

main(args: Array<String>): Int64 {
    // The self-verification entry takes no argument, but a verification script
    // may launch this instance with a round-unique token so the process that
    // belongs to THIS round can be identified by its own command line instead
    // of "first pid matching the binary path". `--inject-verify-failure` makes
    // one assertion fail on purpose, so the caller can prove the exit code and
    // the completion marker really fail the whole chain (never a silent pass).
    var verifiesHit = false
    var verifiesWindowMaterial = false
    var verifiesDiagnostics = false
    var verifiesTranslation = false
    var verifiesPositionMotion = false
    var observesDiagnostics = false
    var observesInteraction = false
    var instanceToken = ""
    var injectVerifyFailure = false
    var argIndex = 0
    while (argIndex < args.size) {
        if (args[argIndex] == "--verify-hit") {
            verifiesHit = true
        } else if (args[argIndex] == "--verify-window-material") {
            verifiesWindowMaterial = true
        } else if (args[argIndex] == "--verify-diagnostics") {
            verifiesDiagnostics = true
        } else if (args[argIndex] == "--verify-translation") {
            verifiesTranslation = true
        } else if (args[argIndex] == "--verify-position-motion") {
            verifiesPositionMotion = true
        } else if (args[argIndex] == "--observe-diagnostics") {
            observesDiagnostics = true
        } else if (args[argIndex] == "--observe-interaction") {
            observesInteraction = true
        } else if (args[argIndex] == "--inject-verify-failure") {
            injectVerifyFailure = true
        } else if (args[argIndex] == "--instance-token" && argIndex + 1 < args.size) {
            instanceToken = args[argIndex + 1]
            argIndex += 1
        } else {
            return 2
        }
        argIndex += 1
    }
    if ((verifiesHit && verifiesWindowMaterial) ||
        (verifiesDiagnostics && (verifiesHit || verifiesWindowMaterial || verifiesTranslation || verifiesPositionMotion)) ||
        (verifiesTranslation && (verifiesHit || verifiesWindowMaterial || verifiesPositionMotion)) ||
        (verifiesPositionMotion && (verifiesHit || verifiesWindowMaterial))) {
        return 2
    }
    let targetId: Int64 = 7101
    let domain = CjguiSharedOperationList(
        ArrayList<CjguiSharedOperationRecord>([CjguiSharedOperationRecord(targetId, "窄宽布局动态项目", false)]))
    let authorization = CjguiSharedOperationExternalAuthorization(
        "adaptive-public-consumer",
        "demo-only-authorized-local-capability",
        ArrayList<CjguiSharedOperationExternalActionScope>(
            [
                CjguiSharedOperationExternalActionScope("GET_CONTEXT", ArrayList<Int64>(), true),
                CjguiSharedOperationExternalActionScope("GET_WINDOW_PROGRESS", ArrayList<Int64>(), true),
                CjguiSharedOperationExternalActionScope("GET_WINDOW_INTERACTION", ArrayList<Int64>(), true),
                CjguiSharedOperationExternalActionScope("GET_NODE_TRANSLATION", ArrayList<Int64>(), true),
                CjguiSharedOperationExternalActionScope("SET_NODE_TRANSLATION", ArrayList<Int64>(), true),
                CjguiSharedOperationExternalActionScope("CLEAR_NODE_TRANSLATION", ArrayList<Int64>(), true),
                CjguiSharedOperationExternalActionScope("SET_MARKED", ArrayList<Int64>([targetId]), false)
            ]
        )
    )
    let controller = AdaptiveController(domain)
    // The F11 normal scroll/split section adds 180 points before this older
    // shadow-hit fixture. Keep the card and its separated shadow band inside
    // the accepted window clip when --verify-hit tests real hit ownership.
    let windowHeight = if (verifiesHit) { 900u32 } else { 700u32 }
    let host = CjguiMacosApplicationHost(
        controller,
        configuration: CjguiMacosApplicationWindowConfiguration(
            "Adaptive Layout Public Consumer",
            640u32,
            windowHeight
        )
    )
    let window = host.window()
    // This handwritten consumer deliberately uses the framework's fixed dark
    // palette. Give the native content-area material the same effective
    // appearance; the generated consumer exercises system-follow switching.
    let _ = host.setThemePreference(CJGUI_COMPOSABLE_UI_PLATFORM_THEME_DARK)
    // Wire the public paint-alpha animation entry to this window's accepted
    // scene. The system "reduce motion" preference is read once at startup and
    // forwarded, so an enabled preference converges any animation instead of
    // producing intermediate frames.
    controller.attachWindow(window)
    let _ = window.setReduceMotionEnabled(CjguiComposableUiReduceMotion.isEnabled())
    let connection = CjguiSharedOperationExternalConnection(domain, authorization, window)
    if (!connection.enableWindowProgressReads(window) || !connection.enableTransferReceiptReads(window) ||
        !connection.enablePositionMotion(window) ||
        !host.attachExternalConnection(connection) || !host.start()) {
        host.close()
        return 1
    }
    for (node in window.acceptedSceneNodes()) {
        if (node.semanticId == "adaptive-translated-split") {
            let _ = window.exposeAcceptedPositionMotionTarget(node.identityKey)
        }
    }
    let scaleReadStarted = MonoTime.now()
    let scaleProgress = window.windowProgress()
    let scaleDiagnostic = window.diagnosticSnapshot(maximumNodes: 1)
    let scaleReadMicros = (MonoTime.now() - scaleReadStarted).toMicroseconds()
    getStdOut().writeln("CJGUI_SCALE_CONSUMER consumer=adaptive session=${scaleProgress.sessionIdentity} " +
        "scene=${scaleProgress.acceptedSceneVersion} frame=${scaleProgress.geometry.submittedFrameIndex} " +
        "points=${scaleProgress.geometry.currentWidthPoints}x${scaleProgress.geometry.currentHeightPoints} " +
        "pixels=${scaleProgress.geometry.currentDrawableWidthPixels}x${scaleProgress.geometry.currentDrawableHeightPixels} " +
        "scale=${scaleProgress.geometry.currentBackingScale} revision=${scaleProgress.geometry.currentRevision} " +
        "diagnostic_same_revision=${if (scaleDiagnostic.geometry.currentRevision == scaleProgress.geometry.currentRevision) { 1 } else { 0 }} " +
        "read_us=${scaleReadMicros}")
    getStdOut().flush()
    // Register this instance's identity BEFORE any operation: a round-unique
    // token in the process command line lets a verifier bind the exact process
    // it launched (never "newest pid matching the binary path"), and the
    // window instance token names the accepted scene this process owns.
    getStdOut().writeln("CJGUI_ADAPTIVE_SELF instance_token=${instanceToken} pid=${getProcessId()} " +
        "role=adaptive-public-consumer verifyHit=${if (verifiesHit) { 1 } else { 0 }} " +
        "verifyWindowMaterial=${if (verifiesWindowMaterial) { 1 } else { 0 }}")
    getStdOut().flush()
    if (verifiesDiagnostics) {
        var failed = 0
        let initialIdleTurns = cjguiAdaptiveWaitDiagnosticIdle(host, window)
        let initialStarted = MonoTime.now()
        let initial = window.diagnosticSnapshot(maximumNodes: 256)
        let initialReadMicros = (MonoTime.now() - initialStarted).toMicroseconds()
        let offReadBatchMicros = cjguiAdaptiveDiagnosticReadBatch(window)
        let page = window.diagnosticSnapshot(startIndex: 1, maximumNodes: 4,
            expectedSessionIdentity: initial.sessionIdentity,
            expectedAcceptedSceneVersion: initial.acceptedSceneVersion)
        let groupKey = "semantic:${NODE_EFFECT_GROUP_SEMANTIC}"
        let firstGroup = cjguiAdaptiveDiagnosticNode(initial, groupKey)
        let bounded = initial.status == "ok" && initial.nodes.size <= 256 &&
            initial.totalNodes >= initial.nodes.size && initial.acceptedSceneVersion > 0 &&
            firstGroup.isSome() && initial.rasterCount == -1 && initial.effectInFlightBytes == -1 &&
            page.status == "ok" && page.nodes.size <= 4 && page.nextIndex > 1 && page.truncated
        if (!bounded) { failed += 1 }
        getStdOut().writeln("CJGUI_ADAPTIVE_DIAGNOSTIC_ASSERT name=bounded_accepted ok=${if (bounded) { 1 } else { 0 }} " +
            "session=${initial.sessionIdentity} scene=${initial.acceptedSceneVersion} " +
            "nodes=${initial.nodes.size}/${initial.totalNodes} live_bytes=${initial.effectLiveBytes} " +
            "raster=${initial.rasterCount} idle_turns=${initialIdleTurns} read_us=${initialReadMicros} " +
            "off_read_24_us=${offReadBatchMicros} page=${page.startIndex}/${page.nextIndex}/${page.nodes.size}")
        let enabled = window.setDiagnosticOverlay(CjguiComposableUiDiagnosticOverlayOptions(true,
            selectedIdentityKey: groupKey))
        let immediate = window.diagnosticSnapshot(maximumNodes: 1)
        var draws = 0
        while (draws < 4) { let _ = host.pumpOneTurn(); draws += 1 }
        let overlayStarted = MonoTime.now()
        let overlay = window.diagnosticSnapshot(maximumNodes: 256)
        let overlayReadMicros = (MonoTime.now() - overlayStarted).toMicroseconds()
        let onReadBatchMicros = cjguiAdaptiveDiagnosticReadBatch(window)
        let isolated = enabled && overlay.overlayEnabled && overlay.overlayDrawCount > initial.overlayDrawCount &&
            overlay.acceptedSceneVersion == initial.acceptedSceneVersion &&
            immediate.nativeSubmissionCount == initial.nativeSubmissionCount &&
            overlay.nativeSubmissionCount == initial.nativeSubmissionCount &&
            overlay.effectLiveBytes == initial.effectLiveBytes &&
            overlay.effectCachedBytes == initial.effectCachedBytes
        if (!isolated) { failed += 1 }
        getStdOut().writeln("CJGUI_ADAPTIVE_DIAGNOSTIC_ASSERT name=overlay_isolated ok=${if (isolated) { 1 } else { 0 }} " +
            "draws=${initial.overlayDrawCount}->${overlay.overlayDrawCount} " +
            "native_submissions=${initial.nativeSubmissionCount}->${overlay.nativeSubmissionCount} " +
            "read_us=${overlayReadMicros} on_read_24_us=${onReadBatchMicros} " +
            "live_bytes=${initial.effectLiveBytes}->${overlay.effectLiveBytes} " +
            "cached_bytes=${initial.effectCachedBytes}->${overlay.effectCachedBytes}")
        let priorVersion = overlay.acceptedSceneVersion
        // F-C: publish the bounded workload scalars for the next real control
        // change. Enabling costs nothing on the refresh path; the snapshot
        // reads below must not create work themselves.
        let workloadEnabled = window.setWorkloadDiagnostics(true)
        let workloadBefore = window.diagnosticSnapshot(maximumNodes: 1)
        let moved = cjguiAdaptiveActivateAcceptedButton(window, controller, NODE_SCROLL_PANE, "EFFECT_SCROLL_STEP")
        let _ = cjguiAdaptivePumpUntilAcceptedSceneAdvance(host, window, priorVersion)
        let scrolled = window.diagnosticSnapshot(maximumNodes: 256)
        let workloadAfter = window.diagnosticSnapshot(maximumNodes: 1)
        let workloadReread = window.diagnosticSnapshot(maximumNodes: 1)
        let stale = window.diagnosticSnapshot(maximumNodes: 8,
            expectedSessionIdentity: initial.sessionIdentity,
            expectedAcceptedSceneVersion: priorVersion)
        let afterGroup = cjguiAdaptiveDiagnosticNode(scrolled, groupKey)
        let scrollOk = moved && scrolled.acceptedSceneVersion > priorVersion && afterGroup.isSome() &&
            scrolled.sessionIdentity == initial.sessionIdentity && scrolled.overlayEnabled &&
            stale.status == "stale_accepted" && stale.nodes.size == 0
        if (!scrollOk) { failed += 1 }
        getStdOut().writeln("CJGUI_ADAPTIVE_DIAGNOSTIC_ASSERT name=scroll_accepted ok=${if (scrollOk) { 1 } else { 0 }} " +
            "scene=${priorVersion}->${scrolled.acceptedSceneVersion} " +
            "owner=${controller.effectGroupAcceptedLine()}")
        // The same control change must be attributable from the public
        // snapshot: an accepted attempt wrote and cloned a bounded part of the
        // scene, the cumulative totals advanced by at least that attempt, and
        // repeated reads neither add work nor submit anything.
        let workloadOk = workloadEnabled && workloadAfter.workloadEnabled &&
            workloadAfter.workloadStatus == "enabled" &&
            workloadAfter.lastAttemptWorkloadResult == "accepted" &&
            workloadBefore.nodeWriteCount >= 0 && workloadAfter.nodeWriteCount >= 0 &&
            workloadAfter.lastAttemptNodeWrites >= 1 &&
            workloadAfter.lastAttemptNodeWrites <= workloadAfter.totalNodes &&
            workloadAfter.lastAttemptNodeClones >= 1 &&
            workloadAfter.lastAttemptNodeClones <= workloadAfter.totalNodes &&
            workloadAfter.nodeWriteCount - workloadBefore.nodeWriteCount >= workloadAfter.lastAttemptNodeWrites &&
            workloadAfter.reusableResourceBytes >= 0 &&
            workloadReread.nodeWriteCount == workloadAfter.nodeWriteCount &&
            workloadReread.lastAttemptNodeWrites == workloadAfter.lastAttemptNodeWrites &&
            workloadReread.nativeSubmissionCount == workloadAfter.nativeSubmissionCount
        if (!workloadOk) { failed += 1 }
        let workloadReadsIdle = workloadReread.nodeWriteCount == workloadAfter.nodeWriteCount &&
            workloadReread.nativeSubmissionCount == workloadAfter.nativeSubmissionCount
        getStdOut().writeln("CJGUI_ADAPTIVE_DIAGNOSTIC_ASSERT name=workload_observed ok=${if (workloadOk) { 1 } else { 0 }} " +
            "status=${workloadAfter.workloadStatus} result=${workloadAfter.lastAttemptWorkloadResult} " +
            "attempt_writes=${workloadAfter.lastAttemptNodeWrites} attempt_clones=${workloadAfter.lastAttemptNodeClones} " +
            "attempt_allocations=${workloadAfter.lastAttemptNodeAllocations} " +
            "attempt_text_prepares=${workloadAfter.lastAttemptTextLayoutPreparations} " +
            "attempt_decode_starts=${workloadAfter.lastAttemptImageDecodeStarts} " +
            "cumulative=${workloadBefore.nodeWriteCount}->${workloadAfter.nodeWriteCount}/" +
            "${workloadAfter.nodeCloneCount}/${workloadAfter.nodeAllocationCount} " +
            "scene=${workloadAfter.workloadSceneVersion} reusable_bytes=${workloadAfter.reusableResourceBytes} " +
            "reads_idle=${if (workloadReadsIdle) { 1 } else { 0 }}")
        let rejected = controller.rejectInvalidEffects().contains("均被拒绝")
        let afterReject = window.diagnosticSnapshot(maximumNodes: 256)
        let rejectOld = rejected && afterReject.acceptedSceneVersion == scrolled.acceptedSceneVersion &&
            cjguiAdaptiveDiagnosticNode(afterReject, groupKey).isSome()
        if (!rejectOld) { failed += 1 }
        getStdOut().writeln("CJGUI_ADAPTIVE_DIAGNOSTIC_ASSERT name=rejection_keeps_accepted ok=${if (rejectOld) { 1 } else { 0 }} " +
            "scene=${afterReject.acceptedSceneVersion}")
        let preDisableIdleTurns = cjguiAdaptiveWaitDiagnosticIdle(host, window)
        let stopped = window.setDiagnosticOverlay(CjguiComposableUiDiagnosticOverlayOptions(false))
        let closedOverlay = window.diagnosticSnapshot(maximumNodes: 1)
        var idle = 0
        while (idle < 4) { let _ = host.pumpOneTurn(); idle += 1 }
        let settled = window.diagnosticSnapshot(maximumNodes: 1)
        let disabledReadBatchMicros = cjguiAdaptiveDiagnosticReadBatch(window)
        let stopOk = stopped && !settled.overlayEnabled &&
            settled.overlayDrawCount == closedOverlay.overlayDrawCount &&
            settled.nativeSubmissionCount == closedOverlay.nativeSubmissionCount
        if (!stopOk) { failed += 1 }
        getStdOut().writeln("CJGUI_ADAPTIVE_DIAGNOSTIC_ASSERT name=disable_idle ok=${if (stopOk) { 1 } else { 0 }} " +
            "draws=${closedOverlay.overlayDrawCount}->${settled.overlayDrawCount} " +
            "native_submissions=${closedOverlay.nativeSubmissionCount}->${settled.nativeSubmissionCount} " +
            "idle_turns=${preDisableIdleTurns} disabled_read_24_us=${disabledReadBatchMicros}")
        let workloadStopped = window.setWorkloadDiagnostics(false)
        let workloadDisabled = window.diagnosticSnapshot(maximumNodes: 1)
        var workloadIdleTurns = 0
        while (workloadIdleTurns < 2) { let _ = host.pumpOneTurn(); workloadIdleTurns += 1 }
        let workloadSettled = window.diagnosticSnapshot(maximumNodes: 1)
        let workloadDisabledOk = workloadStopped && !workloadDisabled.workloadEnabled &&
            workloadDisabled.workloadStatus == "disabled" && workloadDisabled.nodeWriteCount == -1 &&
            workloadDisabled.nodeCloneCount == -1 && workloadDisabled.lastAttemptNodeWrites == -1 &&
            workloadSettled.nativeSubmissionCount == workloadDisabled.nativeSubmissionCount
        if (!workloadDisabledOk) { failed += 1 }
        getStdOut().writeln("CJGUI_ADAPTIVE_DIAGNOSTIC_ASSERT name=workload_disabled ok=${if (workloadDisabledOk) { 1 } else { 0 }} " +
            "status=${workloadDisabled.workloadStatus} writes=${workloadDisabled.nodeWriteCount} " +
            "attempt_writes=${workloadDisabled.lastAttemptNodeWrites} " +
            "submissions=${workloadDisabled.nativeSubmissionCount}->${workloadSettled.nativeSubmissionCount}")
        if (injectVerifyFailure) { failed += 1 }
        getStdOut().writeln("CJGUI_ADAPTIVE_DIAGNOSTIC_DONE instance_token=${instanceToken} failed=${failed}")
        getStdOut().flush()
        if (failed != 0) { exit(1) }
        host.close()
        exit(0)
        return 0
    }
    if (let Some(info) <- connection.connectionInfo()) {
        getStdOut().writeln("ADAPTIVE_LAYOUT_READY DESCRIPTOR_PATH ${info.descriptorPath}")
        getStdOut().writeln("ADAPTIVE_LAYOUT_VECTOR_DECLARATION action=TOGGLE_RESOURCE state=blue")
        getStdOut().writeln("ADAPTIVE_EFFECT_READY shadow=1 gradient=1 shadowVariant=0 gradientVariant=0 cardShift=0 " +
            "scrollOffset=0 outcome=initial")
        getStdOut().writeln("CJGUI_ADAPTIVE_HIT_READY define=${SHADOW_HIT_SEMANTIC} identity=${SHADOW_HIT_IDENTITY} " +
            "alphaNormal=${SHADOW_HIT_ALPHA_NORMAL} alphaHover=${SHADOW_HIT_ALPHA_HOVER} " +
            "alphaPressed=${SHADOW_HIT_ALPHA_PRESSED} interactionStyle=hover,pressed " +
            "pointerDrive=framework-interaction " +
            "reduceMotion=${if (window.reduceMotionEnabled()) { 1 } else { 0 }}")
        // B1: the UI-only consumer consumes the FRAMEWORK color-transition and
        // interaction-transition definitions (one shared contract), not a local
        // copy of the interpolation rules.
        getStdOut().writeln("CJGUI_ADAPTIVE_INTERACTION_CONTRACT " +
            "interaction_rule=${CjguiGeneratedMotionRegistry.INTERACTION_TRANSITION} " +
            CjguiComposableUiColorInterpolation.describe())
        getStdOut().flush()
    }
    var observedDiagnosticVersion: Int64 = -1
    if (observesDiagnostics) {
        let sample = window.diagnosticSnapshot(maximumNodes: 256)
        let key = "semantic:${NODE_EFFECT_GROUP_SEMANTIC}"
        let enabled = window.setDiagnosticOverlay(CjguiComposableUiDiagnosticOverlayOptions(true,
            selectedIdentityKey: key))
        observedDiagnosticVersion = sample.acceptedSceneVersion
        getStdOut().writeln("CJGUI_ADAPTIVE_DIAGNOSTIC_LIVE enabled=${if (enabled) { 1 } else { 0 }} " +
            "instance_token=${instanceToken} session=${sample.sessionIdentity} " +
            "scene=${sample.acceptedSceneVersion} identity=${key} " +
            "nodes=${sample.nodes.size}/${sample.totalNodes}")
        getStdOut().flush()
    }
    // Publish the interactive card's accepted scene geometry and the window's
    // on-screen frame, so a real-pointer driver can convert a scene point to a
    // screen point deterministically instead of scanning for the card.
    var geometryWarmup = 0
    while (geometryWarmup < 5 && host.isOpen()) {
        let _ = host.pumpOneTurn()
        geometryWarmup += 1
    }
    getStdOut().writeln(controller.hitCardBoundsLine())
    let hitScreenLine = match (window.windowScreenFrame()) {
        case Some(frame) => "CJGUI_ADAPTIVE_HIT_SCREEN window_frame=${frame[0]},${frame[1]},${frame[2]},${frame[3]}"
        case None => "CJGUI_ADAPTIVE_HIT_SCREEN window_frame=none"
    }
    getStdOut().writeln(hitScreenLine)
    getStdOut().flush()
    let initialEffectGroupLine = controller.takeEffectGroupAcceptedChange()
    if (initialEffectGroupLine.size > 0) {
        getStdOut().writeln(initialEffectGroupLine)
        getStdOut().flush()
    }
    if (verifiesPositionMotion) {
        var failed = 0
        let _ = window.setReduceMotionEnabled(false)
        let _ = window.setWorkloadDiagnostics(true)
        let ownerBefore = domain.version()
        var splitIdentity = ""
        var baseX = 0.0
        var baseY = 0.0
        for (node in window.acceptedSceneNodes()) {
            if (node.semanticId == "adaptive-translated-split") {
                splitIdentity = node.identityKey
                baseX = node.declaredStyle.translateX
                baseY = node.declaredStyle.translateY
            }
        }
        let staticSample = window.diagnosticSnapshot(maximumNodes: 1)
        let first = cjguiAdaptiveActivateAcceptedButton(window, controller,
            NODE_POSITION_MOTION, "POSITION_MOTION_TOGGLE")
        var turns = 0
        while (turns < 4 && host.isOpen()) {
            let _ = host.pumpOneTurn()
            sleep(Duration.millisecond)
            turns += 1
        }
        let mid = window.animatedNodeTranslation(splitIdentity)
        let midX = match (mid) {
            case Some(value) => value.presented.x
            case None => -10000.0
        }
        let midScene = window.diagnosticSnapshot(maximumNodes: 1)
        let moving = first && midX > baseX && midX < baseX + 24.0 &&
            midScene.acceptedSceneVersion > staticSample.acceptedSceneVersion
        if (!moving) { failed += 1 }
        let reverse = cjguiAdaptiveActivateAcceptedButton(window, controller,
            NODE_POSITION_MOTION, "POSITION_MOTION_TOGGLE")
        let reverseAt = window.animatedNodeTranslation(splitIdentity)
        let continuous = reverse && (match (reverseAt) {
            case Some(value) => value.presented.x == midX && value.target.x == baseX
            case None => false
        })
        if (!continuous) { failed += 1 }
        turns = 0
        while (turns < 100 && host.isOpen() && window.needsAnimationTick()) {
            let _ = host.pumpOneTurn()
            sleep(Duration.millisecond)
            turns += 1
        }
        let within = window.diagnosticSnapshot(maximumNodes: 1)
        let terminal = window.animatedNodeTranslation(splitIdentity)
        let returned = match (terminal) {
            case Some(value) => value.presented.x == baseX && value.presented.y == baseY && !value.active
            case None => false
        }
        if (!returned || window.needsAnimationTick()) { failed += 1 }
        getStdOut().writeln("CJGUI_ADAPTIVE_POSITION_COST phase=within ok=${if (moving && continuous && returned) { 1 } else { 0 }} " +
            "build_ns=${within.totalBuildNanoseconds - staticSample.totalBuildNanoseconds} " +
            "layout_ns=${within.totalLayoutNanoseconds - staticSample.totalLayoutNanoseconds} " +
            "submit_ns=${within.totalNativeStageAndSubmitNanoseconds - staticSample.totalNativeStageAndSubmitNanoseconds} " +
            "text_prepares=${within.textLayoutPreparationCount - staticSample.textLayoutPreparationCount} " +
            "raster_tiles=${within.textRasterCount - staticSample.textRasterCount} " +
            "upload_tiles=${within.textUploadCount - staticSample.textUploadCount} " +
            "decode_starts=${within.imageDecodeStartCount - staticSample.imageDecodeStartCount} " +
            "live_bytes=${staticSample.textTextureLiveBytes}->${within.textTextureLiveBytes} " +
            "peak_bytes=${within.textCandidatePeakBytes} " +
            "scene=${staticSample.acceptedSceneVersion}->${within.acceptedSceneVersion} " +
            "submissions=${staticSample.nativeSubmissionCount}->${within.nativeSubmissionCount}")
        let spec = CjguiGeneratedMotionRegistry.positionTransitionRule().spec() ??
            CjguiComposableUiAnimationSpec.tween(durationMs: 240)
        let crossStarted = window.animateNodeTranslation(splitIdentity, baseX + 280.0, baseY,
            spec: spec, atTime: MonoTime.now())
        turns = 0
        while (turns < 100 && host.isOpen() && window.needsAnimationTick()) {
            let _ = host.pumpOneTurn()
            sleep(Duration.millisecond)
            turns += 1
        }
        let cross = window.diagnosticSnapshot(maximumNodes: 1)
        let crossStatus = window.animatedNodeTranslation(splitIdentity)
        let crossAccepted = crossStarted && (match (crossStatus) {
            case Some(value) => value.presented.x == baseX + 280.0 && !value.active
            case None => false
        }) && cross.totalBuildNanoseconds == within.totalBuildNanoseconds &&
            cross.totalLayoutNanoseconds == within.totalLayoutNanoseconds
        if (!crossAccepted) { failed += 1 }
        getStdOut().writeln("CJGUI_ADAPTIVE_POSITION_COST phase=cross_coverage ok=${if (crossAccepted) { 1 } else { 0 }} " +
            "build_ns=${cross.totalBuildNanoseconds - within.totalBuildNanoseconds} " +
            "layout_ns=${cross.totalLayoutNanoseconds - within.totalLayoutNanoseconds} " +
            "submit_ns=${cross.totalNativeStageAndSubmitNanoseconds - within.totalNativeStageAndSubmitNanoseconds} " +
            "text_prepares=${cross.textLayoutPreparationCount - within.textLayoutPreparationCount} " +
            "raster_tiles=${cross.textRasterCount - within.textRasterCount} " +
            "upload_tiles=${cross.textUploadCount - within.textUploadCount} " +
            "decode_starts=${cross.imageDecodeStartCount - within.imageDecodeStartCount} " +
            "live_bytes=${within.textTextureLiveBytes}->${cross.textTextureLiveBytes} " +
            "peak_bytes=${cross.textCandidatePeakBytes} " +
            "scene=${within.acceptedSceneVersion}->${cross.acceptedSceneVersion} " +
            "submissions=${within.nativeSubmissionCount}->${cross.nativeSubmissionCount}")
        let cleared = cjguiAdaptiveActivateAcceptedButton(window, controller,
            NODE_POSITION_MOTION_CLEAR, "POSITION_MOTION_CLEAR")
        let clearedOk = cleared && window.animatedNodeTranslation(splitIdentity).isNone() &&
            domain.version() == ownerBefore && !window.needsAnimationTick()
        if (!clearedOk || injectVerifyFailure) { failed += 1 }
        getStdOut().writeln("CJGUI_ADAPTIVE_POSITION_DONE instance_token=${instanceToken} " +
            "moving=${if (moving) { 1 } else { 0 }} reverse=${if (continuous) { 1 } else { 0 }} " +
            "terminal=${if (returned) { 1 } else { 0 }} cross=${if (crossAccepted) { 1 } else { 0 }} " +
            "clear=${if (clearedOk) { 1 } else { 0 }} owner=${ownerBefore}->${domain.version()} failed=${failed}")
        getStdOut().flush()
        host.close()
        return if (failed == 0) { 0 } else { 1 }
    }
    if (verifiesTranslation) {
        var failed = 0
        let ownerBefore = controller.effectGroupAcceptedOwnerIdentity()
        let initial = cjguiAdaptiveVisualOffsetIs(window, NODE_EFFECT_GROUP_SEMANTIC, 0.25, 0.5) &&
            cjguiAdaptiveVisualOffsetIs(window, NODE_EFFECT_GROUP_CARD_SEMANTIC, 0.25, 0.5) &&
            cjguiAdaptiveVisualOffsetIs(window, "adaptive-effect-card", 0.375, 0.25) &&
            cjguiAdaptiveVisualOffsetIs(window, "adaptive-effect-group-action", -0.5, 0.75) &&
            cjguiAdaptiveVisualOffsetIs(window, "adaptive-translated-split", 0.25, 0.5) &&
            window.acceptedNodeBounds("adaptive-translated-long-text").isSome() &&
            window.acceptedNodeBounds("adaptive-translated-tail-action").isSome()
        if (!initial) { failed += 1 }
        let _ = window.setWorkloadDiagnostics(true)
        let before = window.diagnosticSnapshot(maximumNodes: 1)
        let started = MonoTime.now()
        let moved = cjguiAdaptiveActivateAcceptedButton(window, controller,
            NODE_SUBPOINT_TRANSLATION_TOGGLE, "SUBPOINT_TRANSLATION_TOGGLE")
        var turns = 0
        while (turns < 40 && host.isOpen() &&
            !cjguiAdaptiveVisualOffsetIs(window, NODE_EFFECT_GROUP_SEMANTIC, 30.25, 12.5)) {
            let _ = host.pumpOneTurn()
            turns += 1
        }
        let after = window.diagnosticSnapshot(maximumNodes: 1)
        let movedOk = moved &&
            cjguiAdaptiveVisualOffsetIs(window, NODE_EFFECT_GROUP_SEMANTIC, 30.25, 12.5) &&
            cjguiAdaptiveVisualOffsetIs(window, "adaptive-effect-card", 30.375, 12.25) &&
            cjguiAdaptiveVisualOffsetIs(window, "adaptive-effect-group-action", 29.5, 12.75) &&
            cjguiAdaptiveVisualOffsetIs(window, "adaptive-translated-split", 30.25, 12.5) &&
            controller.effectGroupAcceptedOwnerIdentity() == ownerBefore &&
            after.acceptedSceneVersion > before.acceptedSceneVersion
        if (!movedOk) { failed += 1 }
        getStdOut().writeln("CJGUI_ADAPTIVE_TRANSLATION_SAMPLE phase=far ok=${if (movedOk) { 1 } else { 0 }} " +
            "scene=${before.acceptedSceneVersion}->${after.acceptedSceneVersion} " +
            "build_ns=${after.buildNanoseconds} layout_ns=${after.layoutNanoseconds} " +
            "submit_ns=${after.nativeStageAndSubmitNanoseconds} " +
            "text_prepares=${after.lastAttemptTextLayoutPreparations} " +
            "decode_starts=${after.lastAttemptImageDecodeStarts} " +
            "native_submissions=${before.nativeSubmissionCount}->${after.nativeSubmissionCount} " +
            "elapsed_us=${(MonoTime.now() - started).toMicroseconds()}")
        let cleared = cjguiAdaptiveActivateAcceptedButton(window, controller,
            NODE_SUBPOINT_TRANSLATION_TOGGLE, "SUBPOINT_TRANSLATION_TOGGLE")
        turns = 0
        while (turns < 40 && host.isOpen() &&
            !cjguiAdaptiveVisualOffsetIs(window, NODE_EFFECT_GROUP_SEMANTIC, 0.0, 0.0)) {
            let _ = host.pumpOneTurn()
            turns += 1
        }
        let clearSample = window.diagnosticSnapshot(maximumNodes: 1)
        let clearedOk = cleared &&
            cjguiAdaptiveVisualOffsetIs(window, NODE_EFFECT_GROUP_SEMANTIC, 0.0, 0.0) &&
            cjguiAdaptiveVisualOffsetIs(window, "adaptive-effect-card", 0.0, 0.0) &&
            cjguiAdaptiveVisualOffsetIs(window, "adaptive-effect-group-action", 0.0, 0.0) &&
            cjguiAdaptiveVisualOffsetIs(window, "adaptive-translated-split", 0.0, 0.0) &&
            controller.effectGroupAcceptedOwnerIdentity() == ownerBefore &&
            clearSample.acceptedSceneVersion > after.acceptedSceneVersion
        if (!clearedOk) { failed += 1 }
        // Fixed ordinary panel load: zero, the accepted static small/far
        // positions, then three cycles of continuous translation. Each line is
        // a real accepted refresh with its own build/layout/native costs.
        var costBefore = clearSample
        var costIndex = 0
        while (costIndex < 9 && host.isOpen()) {
            let variant = costIndex % 3
            let expectedX = if (variant == 0) { 0.25 } else if (variant == 1) { 30.25 } else { 0.0 }
            let expectedY = if (variant == 0) { 0.5 } else if (variant == 1) { 12.5 } else { 0.0 }
            let costStarted = MonoTime.now()
            let dispatched = cjguiAdaptiveActivateAcceptedButton(window, controller,
                NODE_SUBPOINT_TRANSLATION_TOGGLE, "SUBPOINT_TRANSLATION_TOGGLE")
            var costTurns = 0
            while (costTurns < 40 && host.isOpen() &&
                (window.windowProgress().acceptedSceneVersion <= costBefore.acceptedSceneVersion ||
                !cjguiAdaptiveVisualOffsetIs(window, NODE_EFFECT_GROUP_SEMANTIC, expectedX, expectedY))) {
                let _ = host.pumpOneTurn()
                costTurns += 1
            }
            let costAfter = window.diagnosticSnapshot(maximumNodes: 1)
            let costOk = dispatched &&
                cjguiAdaptiveVisualOffsetIs(window, NODE_EFFECT_GROUP_SEMANTIC, expectedX, expectedY) &&
                costAfter.acceptedSceneVersion > costBefore.acceptedSceneVersion &&
                costAfter.nativeSubmissionCount > costBefore.nativeSubmissionCount &&
                controller.effectGroupAcceptedOwnerIdentity() == ownerBefore
            if (!costOk) { failed += 1 }
            getStdOut().writeln("CJGUI_ADAPTIVE_TRANSLATION_COST sample=${costIndex} " +
                "variant=${variant} ok=${if (costOk) { 1 } else { 0 }} " +
                "operation_build_ns=${costAfter.totalBuildNanoseconds - costBefore.totalBuildNanoseconds} " +
                "operation_layout_ns=${costAfter.totalLayoutNanoseconds - costBefore.totalLayoutNanoseconds} " +
                "operation_submit_ns=${costAfter.totalNativeStageAndSubmitNanoseconds - costBefore.totalNativeStageAndSubmitNanoseconds} " +
                "last_refresh_build_ns=${costAfter.buildNanoseconds} " +
                "last_refresh_layout_ns=${costAfter.layoutNanoseconds} " +
                "last_refresh_submit_ns=${costAfter.nativeStageAndSubmitNanoseconds} " +
                "text_prepares=${costAfter.textLayoutPreparationCount - costBefore.textLayoutPreparationCount} " +
                "raster_tiles=${costAfter.textRasterCount - costBefore.textRasterCount} " +
                "raster_bytes=${costAfter.textRasterBytes - costBefore.textRasterBytes} " +
                "raster_us=${costAfter.textRasterMicros - costBefore.textRasterMicros} " +
                "upload_tiles=${costAfter.textUploadCount - costBefore.textUploadCount} " +
                "upload_bytes=${costAfter.textUploadBytes - costBefore.textUploadBytes} " +
                "upload_us=${costAfter.textUploadMicros - costBefore.textUploadMicros} " +
                "decode_starts=${costAfter.imageDecodeStartCount - costBefore.imageDecodeStartCount} " +
                "text_live_bytes=${costBefore.textTextureLiveBytes}->${costAfter.textTextureLiveBytes} " +
                "text_candidate_peak_bytes=${costAfter.textCandidatePeakBytes} " +
                "scene=${costBefore.acceptedSceneVersion}->${costAfter.acceptedSceneVersion} " +
                "submissions=${costBefore.nativeSubmissionCount}->${costAfter.nativeSubmissionCount} " +
                "elapsed_us=${(MonoTime.now() - costStarted).toMicroseconds()}")
            costBefore = costAfter
            costIndex += 1
        }
        var idleTurns = 0
        var stableTurns = 0
        var previousSubmissions = costBefore.nativeSubmissionCount
        let idleStarted = MonoTime.now()
        while (host.isOpen() && stableTurns < 4 &&
            (MonoTime.now() - idleStarted).toMilliseconds() < 1000) {
            let _ = host.pumpOneTurn()
            sleep(Duration.millisecond)
            let current = window.diagnosticSnapshot(maximumNodes: 1).nativeSubmissionCount
            if (current == previousSubmissions && !window.needsAnimationTick()) {
                stableTurns += 1
            } else { stableTurns = 0 }
            previousSubmissions = current
            idleTurns += 1
        }
        let settled = window.diagnosticSnapshot(maximumNodes: 1)
        var confirmationTurns = 0
        while (confirmationTurns < 4 && host.isOpen()) {
            let _ = host.pumpOneTurn()
            confirmationTurns += 1
        }
        let idle = window.diagnosticSnapshot(maximumNodes: 1)
        let idleOk = stableTurns == 4 && idle.nativeSubmissionCount == settled.nativeSubmissionCount
        if (!idleOk) { failed += 1 }
        if (injectVerifyFailure) { failed += 1 }
        getStdOut().writeln("CJGUI_ADAPTIVE_TRANSLATION_DONE instance_token=${instanceToken} " +
            "initial=${if (initial) { 1 } else { 0 }} moved=${if (movedOk) { 1 } else { 0 }} " +
            "cleared=${if (clearedOk) { 1 } else { 0 }} idle=${if (idleOk) { 1 } else { 0 }} " +
            "scene=${before.acceptedSceneVersion}->${after.acceptedSceneVersion}->${clearSample.acceptedSceneVersion} " +
            "submissions=${before.nativeSubmissionCount}->${after.nativeSubmissionCount}->" +
            "${clearSample.nativeSubmissionCount}->${costBefore.nativeSubmissionCount}->" +
            "${settled.nativeSubmissionCount}->${idle.nativeSubmissionCount} " +
            "idle_turns=${idleTurns} idle_ms=${(MonoTime.now() - idleStarted).toMilliseconds()} " +
            "failed=${failed}")
        getStdOut().flush()
        host.close()
        return if (failed != 0) { 1 } else { 0 }
    }
    // Consumer-level hit negative control + paint-alpha animation check. The
    // probe reads the ACCEPTED scene; the animation is driven through the same
    // public window entry the hover/pressed buttons use.
    if (verifiesHit) {
        // Every assertion below is evaluated and reported; any one of them
        // failing (or an injected failure) makes this process exit non-zero and
        // omits nothing: a caller can see which fact was not established.
        var failed = 0
        var waited = 0
        while (waited < 400 && host.isOpen() && window.acceptedNodeBounds(SHADOW_HIT_SEMANTIC).isNone()) {
            let _ = host.pumpOneTurn()
            waited += 1
        }
        // 1. the accepted scene really carries the interactive card.
        let nodeReady = window.acceptedNodeBounds(SHADOW_HIT_SEMANTIC).isSome()
        if (!nodeReady) { failed += 1 }
        getStdOut().writeln("CJGUI_ADAPTIVE_HIT_ASSERT name=accepted_card_ready ok=${if (nodeReady) { 1 } else { 0 }}")
        // 2. the consumer-level hit negative control (inside hit, shadow band not).
        let probe = controller.runHitProbe()
        let probePass = probe.contains("判定=PASS")
        if (!probePass) { failed += 1 }
        getStdOut().writeln("CJGUI_ADAPTIVE_HIT_ASSERT name=hit_negative_control " +
            "ok=${if (probePass) { 1 } else { 0 }} detail=[${probe}]")
        // 3. hover starts from the current visual value and really changes it.
        //    Before any binding exists the presented value is the base paint
        //    alpha; a first drive starts from that same value, so "no read yet"
        //    is the normal target, not a failure.
        let beforeHover = match (window.animatedNodeOpacity(SHADOW_HIT_IDENTITY)) {
            case Some(value) => value
            case None => SHADOW_HIT_ALPHA_NORMAL
        }
        let hoverOn = controller.driveHoverProbe()
        var frames = 0
        while (frames < 8 && host.isOpen()) {
            let _ = host.pumpOneTurn()
            frames += 1
        }
        let afterHover = match (window.animatedNodeOpacity(SHADOW_HIT_IDENTITY)) {
            case Some(value) => value
            case None => -1.0
        }
        let hoverChanged = beforeHover > 0.0 && afterHover >= 0.0 && afterHover < beforeHover
        if (!hoverChanged) { failed += 1 }
        getStdOut().writeln("CJGUI_ADAPTIVE_HIT_ASSERT name=hover_changed_from_current " +
            "ok=${if (hoverChanged) { 1 } else { 0 }} before=${beforeHover} after=${afterHover} drive=[${hoverOn}]")
        // 4. an explicit reverse continues from the current visual value.
        let reverse = controller.driveReverseProbe()
        var frames2 = 0
        while (frames2 < 8 && host.isOpen()) {
            let _ = host.pumpOneTurn()
            frames2 += 1
        }
        let afterReverse = match (window.animatedNodeOpacity(SHADOW_HIT_IDENTITY)) {
            case Some(value) => value
            case None => -1.0
        }
        let reverseContinued = afterReverse >= 0.0 && afterReverse > afterHover
        if (!reverseContinued) { failed += 1 }
        getStdOut().writeln("CJGUI_ADAPTIVE_HIT_ASSERT name=reverse_continues_current " +
            "ok=${if (reverseContinued) { 1 } else { 0 }} from=${afterHover} after=${afterReverse} drive=[${reverse}]")
        // 5. a refused malformed effect declaration leaves the accepted card
        //    untouched: the candidate is refused whole, not silently normalized.
        let rejection = controller.rejectInvalidEffects()
        let boundsAfterReject = window.acceptedNodeBounds(SHADOW_HIT_SEMANTIC)
        let rejectStable = rejection.contains("非法效果候选均被拒绝") && boundsAfterReject.isSome()
        if (!rejectStable) { failed += 1 }
        getStdOut().writeln("CJGUI_ADAPTIVE_HIT_ASSERT name=rejected_candidate_keeps_accepted " +
            "ok=${if (rejectStable) { 1 } else { 0 }} detail=[${rejection}]")
        // 6. B3 reduce-motion: an active paint-alpha transition converges to its
        //    terminal value, the terminal value is committed, and the window
        //    stops requesting frames. Turning the preference off resumes.
        let _ = window.setReduceMotionEnabled(false)
        let _ = controller.driveHoverProbe()
        var reduceFrames = 0
        while (reduceFrames < 3 && host.isOpen()) {
            let _ = host.pumpOneTurn()
            reduceFrames += 1
        }
        let midReduce = match (window.animatedNodeOpacity(SHADOW_HIT_IDENTITY)) {
            case Some(value) => value
            case None => -1.0
        }
        let _ = window.setReduceMotionEnabled(true)
        let _ = host.pumpOneTurn()
        let converged = match (window.animatedNodeOpacity(SHADOW_HIT_IDENTITY)) {
            case Some(value) => value
            case None => -1.0
        }
        let convergedTarget = match (window.animatedNodeOpacityTarget(SHADOW_HIT_IDENTITY)) {
            case Some(value) => value
            case None => -1.0
        }
        let reduceOk = midReduce >= 0.0 && midReduce < SHADOW_HIT_ALPHA_NORMAL &&
            cjguiAdaptiveApprox(converged, convergedTarget, 0.001) && !window.needsAnimationTick()
        if (!reduceOk) { failed += 1 }
        getStdOut().writeln("CJGUI_ADAPTIVE_HIT_ASSERT name=reduce_motion_converges_and_stops " +
            "ok=${if (reduceOk) { 1 } else { 0 }} mid=${midReduce} converged=${converged} " +
            "target=${convergedTarget} needsTick=${if (window.needsAnimationTick()) { 1 } else { 0 }}")
        // 7. B3 pause: an in-flight transition stops advancing and requesting
        //    frames, and resumes from the same value when unpaused.
        let _ = window.setReduceMotionEnabled(false)
        let _ = controller.driveHoverProbe()
        let _ = host.pumpOneTurn()
        let beforePause = match (window.animatedNodeOpacity(SHADOW_HIT_IDENTITY)) {
            case Some(value) => value
            case None => -1.0
        }
        window.setAnimationsPaused(true)
        let _ = host.pumpOneTurn()
        let pausedTick = window.needsAnimationTick()
        let afterPause = match (window.animatedNodeOpacity(SHADOW_HIT_IDENTITY)) {
            case Some(value) => value
            case None => -1.0
        }
        window.setAnimationsPaused(false)
        let pauseOk = beforePause >= 0.0 && !pausedTick &&
            cjguiAdaptiveApprox(afterPause, beforePause, 0.000000001)
        if (!pauseOk) { failed += 1 }
        getStdOut().writeln("CJGUI_ADAPTIVE_HIT_ASSERT name=pause_stops_and_resumes " +
            "ok=${if (pauseOk) { 1 } else { 0 }} before=${beforePause} after=${afterPause} " +
            "pausedTick=${if (pausedTick) { 1 } else { 0 }}")
        // 8. B3 controllable platform-state source (explicit facts only, never
        //    the user's global preference): only-change updates, visible advance,
        //    hidden/minimized converge, restore advance, fixed theme priority.
        let tracker = CjguiComposableUiPlatformStateTracker()
        let platformFirst = tracker.observe(reduceMotion: false, systemColorScheme: CjguiComposableUiColorScheme.Dark,
            themePreference: CjguiComposableUiThemePreference.SystemFollow, windowVisible: true, windowMinimized: false)
        let platformSame = tracker.observe(reduceMotion: false, systemColorScheme: CjguiComposableUiColorScheme.Dark,
            themePreference: CjguiComposableUiThemePreference.SystemFollow, windowVisible: true, windowMinimized: false)
        let visibleAdvance = match (tracker.accepted()) {
            case Some(snapshot) => !snapshot.motionConverges()
            case None => false
        }
        let _ = tracker.observe(reduceMotion: false, systemColorScheme: CjguiComposableUiColorScheme.Dark,
            themePreference: CjguiComposableUiThemePreference.SystemFollow, windowVisible: false, windowMinimized: false)
        let hiddenConverge = match (tracker.accepted()) {
            case Some(snapshot) => snapshot.motionConverges()
            case None => false
        }
        let _ = tracker.observe(reduceMotion: false, systemColorScheme: CjguiComposableUiColorScheme.Dark,
            themePreference: CjguiComposableUiThemePreference.SystemFollow, windowVisible: true, windowMinimized: true)
        let minimizedConverge = match (tracker.accepted()) {
            case Some(snapshot) => snapshot.motionConverges()
            case None => false
        }
        let _ = tracker.observe(reduceMotion: false, systemColorScheme: CjguiComposableUiColorScheme.Dark,
            themePreference: CjguiComposableUiThemePreference.SystemFollow, windowVisible: true, windowMinimized: false)
        let restoreAdvance = match (tracker.accepted()) {
            case Some(snapshot) => !snapshot.motionConverges()
            case None => false
        }
        let _ = tracker.observe(reduceMotion: false, systemColorScheme: CjguiComposableUiColorScheme.Dark,
            themePreference: CjguiComposableUiThemePreference.FixedDark, windowVisible: true, windowMinimized: false)
        let fixedThemeDark = match (tracker.accepted()) {
            case Some(snapshot) => CjguiComposableUiPlatformStateCodec.colorSchemeToken(
                snapshot.effectiveColorScheme()) == CJGUI_COMPOSABLE_UI_PLATFORM_COLOR_SCHEME_DARK
            case None => false
        }
        let unknownRejected = !tracker.selectThemePreference("neon") &&
            tracker.lastRejectionReason() == "unknown_theme_preference"
        let platformOk = platformFirst && !platformSame && visibleAdvance && hiddenConverge &&
            minimizedConverge && restoreAdvance && fixedThemeDark && unknownRejected
        if (!platformOk) { failed += 1 }
        getStdOut().writeln("CJGUI_ADAPTIVE_HIT_ASSERT name=platform_state_chain " +
            "ok=${if (platformOk) { 1 } else { 0 }} first=${if (platformFirst) { 1 } else { 0 }} " +
            "same=${if (platformSame) { 1 } else { 0 }} visibleAdvance=${if (visibleAdvance) { 1 } else { 0 }} " +
            "hiddenConverge=${if (hiddenConverge) { 1 } else { 0 }} minimizedConverge=${if (minimizedConverge) { 1 } else { 0 }} " +
            "restoreAdvance=${if (restoreAdvance) { 1 } else { 0 }} fixedThemeDark=${if (fixedThemeDark) { 1 } else { 0 }} " +
            "unknownRejected=${if (unknownRejected) { 1 } else { 0 }}")
        // 9. an explicit cancel drops the binding and requests no further frame.
        let _ = window.setReduceMotionEnabled(false)
        window.setAnimationsPaused(false)
        let cancelled = window.cancelNodeOpacityAnimation(SHADOW_HIT_IDENTITY)
        let activeAfterCancel = window.activeAnimationCount()
        let opacityBindingGone = window.animatedNodeOpacity(SHADOW_HIT_IDENTITY).isNone()
        let cancelSettled = activeAfterCancel == 0 && opacityBindingGone
        if (!cancelSettled) { failed += 1 }
        getStdOut().writeln("CJGUI_ADAPTIVE_HIT_ASSERT name=cancel_settles " +
            "ok=${if (cancelSettled) { 1 } else { 0 }} cancelled=${if (cancelled) { 1 } else { 0 }} " +
            "active=${activeAfterCancel} opacityBindingGone=${if (opacityBindingGone) { 1 } else { 0 }}")
        // P4: find each real button in the accepted scene, send its ordinary
        // button event through the application handler, pump a normal window
        // turn, then inspect the accepted EffectGroup on its stable owner.
        let groupOwnerBefore = controller.effectGroupAcceptedOwnerIdentity()
        let initialGroupAccepted = controller.effectGroupAcceptedStateIs(1.0, "normal", false)
        let opacityOnDispatched = cjguiAdaptiveActivateAcceptedButton(window, controller,
            NODE_EFFECT_GROUP_OPACITY, "EFFECT_GROUP_OPACITY")
        let opacityOnAccepted = opacityOnDispatched &&
            cjguiAdaptivePumpUntilEffectGroupState(host, controller, 0.58, "normal", false)
        let opacityOffDispatched = cjguiAdaptiveActivateAcceptedButton(window, controller,
            NODE_EFFECT_GROUP_OPACITY, "EFFECT_GROUP_OPACITY")
        let opacityOffAccepted = opacityOffDispatched &&
            cjguiAdaptivePumpUntilEffectGroupState(host, controller, 1.0, "normal", false)
        let opacityOwnerStable = groupOwnerBefore.size > 0 &&
            controller.effectGroupAcceptedOwnerIdentity() == groupOwnerBefore
        let opacityControlOk = initialGroupAccepted && opacityOnAccepted && opacityOffAccepted && opacityOwnerStable
        if (!opacityControlOk) { failed += 1 }
        getStdOut().writeln("CJGUI_ADAPTIVE_HIT_ASSERT name=effect_group_opacity_control " +
            "ok=${if (opacityControlOk) { 1 } else { 0 }} initial=${if (initialGroupAccepted) { 1 } else { 0 }} " +
            "on=${if (opacityOnAccepted) { 1 } else { 0 }} off=${if (opacityOffAccepted) { 1 } else { 0 }} " +
            "ownerStable=${if (opacityOwnerStable) { 1 } else { 0 }} owner=${groupOwnerBefore}")

        let maskOnDispatched = cjguiAdaptiveActivateAcceptedButton(window, controller,
            NODE_EFFECT_GROUP_MASK, "EFFECT_GROUP_MASK")
        let maskOnAccepted = maskOnDispatched &&
            cjguiAdaptivePumpUntilEffectGroupState(host, controller, 1.0, "normal", true)
        let maskOffDispatched = cjguiAdaptiveActivateAcceptedButton(window, controller,
            NODE_EFFECT_GROUP_MASK, "EFFECT_GROUP_MASK")
        let maskOffAccepted = maskOffDispatched &&
            cjguiAdaptivePumpUntilEffectGroupState(host, controller, 1.0, "normal", false)
        let maskOwnerStable = controller.effectGroupAcceptedOwnerIdentity() == groupOwnerBefore
        let maskControlOk = maskOnAccepted && maskOffAccepted && maskOwnerStable
        if (!maskControlOk) { failed += 1 }
        getStdOut().writeln("CJGUI_ADAPTIVE_HIT_ASSERT name=effect_group_mask_control " +
            "ok=${if (maskControlOk) { 1 } else { 0 }} on=${if (maskOnAccepted) { 1 } else { 0 }} " +
            "off=${if (maskOffAccepted) { 1 } else { 0 }} ownerStable=${if (maskOwnerStable) { 1 } else { 0 }}")

        let multiplyDispatched = cjguiAdaptiveActivateAcceptedButton(window, controller,
            NODE_EFFECT_GROUP_BLEND, "EFFECT_GROUP_BLEND")
        let multiplyAccepted = multiplyDispatched &&
            cjguiAdaptivePumpUntilEffectGroupState(host, controller, 1.0, "multiply", false)
        let normalDispatched = cjguiAdaptiveActivateAcceptedButton(window, controller,
            NODE_EFFECT_GROUP_BLEND, "EFFECT_GROUP_BLEND")
        let normalAccepted = normalDispatched &&
            cjguiAdaptivePumpUntilEffectGroupState(host, controller, 1.0, "normal", false)
        let blendOwnerStable = controller.effectGroupAcceptedOwnerIdentity() == groupOwnerBefore
        let blendControlOk = multiplyAccepted && normalAccepted && blendOwnerStable
        if (!blendControlOk) { failed += 1 }
        getStdOut().writeln("CJGUI_ADAPTIVE_HIT_ASSERT name=effect_group_blend_control " +
            "ok=${if (blendControlOk) { 1 } else { 0 }} multiply=${if (multiplyAccepted) { 1 } else { 0 }} " +
            "normal=${if (normalAccepted) { 1 } else { 0 }} ownerStable=${if (blendOwnerStable) { 1 } else { 0 }}")

        let blurOnDispatched = cjguiAdaptiveActivateAcceptedButton(window, controller,
            NODE_EFFECT_GROUP_BLUR, "EFFECT_GROUP_BLUR")
        let blurOnAccepted = blurOnDispatched && cjguiAdaptivePumpUntilEffectGroupBlur(host, controller, 8)
        let blurOffDispatched = cjguiAdaptiveActivateAcceptedButton(window, controller,
            NODE_EFFECT_GROUP_BLUR, "EFFECT_GROUP_BLUR")
        let blurOffAccepted = blurOffDispatched && cjguiAdaptivePumpUntilEffectGroupBlur(host, controller, 0)
        let blurOwnerStable = controller.effectGroupAcceptedOwnerIdentity() == groupOwnerBefore
        let blurControlOk = blurOnAccepted && blurOffAccepted && blurOwnerStable
        if (!blurControlOk) { failed += 1 }
        getStdOut().writeln("CJGUI_ADAPTIVE_HIT_ASSERT name=effect_group_blur_control " +
            "ok=${if (blurControlOk) { 1 } else { 0 }} blur8=${if (blurOnAccepted) { 1 } else { 0 }} " +
            "blur0=${if (blurOffAccepted) { 1 } else { 0 }} ownerStable=${if (blurOwnerStable) { 1 } else { 0 }}")

        let groupReadback = controller.effectGroupAcceptedLine()
        let groupOwnerReadbackOk = groupOwnerBefore.size > 0 && groupReadback.contains("owner=${groupOwnerBefore}") &&
            groupReadback.contains("groupFrame=") && groupReadback.contains("cardFrame=") &&
            groupReadback.contains("scrollOffset=") && groupReadback.contains("blend=normal mask=0") &&
            groupReadback.contains("blurRadiusPoints=0 blurFallback=unblurred")
        if (!groupOwnerReadbackOk) { failed += 1 }
        getStdOut().writeln("CJGUI_ADAPTIVE_HIT_ASSERT name=effect_group_owner_readback " +
            "ok=${if (groupOwnerReadbackOk) { 1 } else { 0 }} owner=${groupOwnerBefore} " +
            "accepted=[${groupReadback}]")

        // The handwritten button uses the same public policy and named-style
        // delivery as the generated consumer. Read acceptance from the window,
        // rather than treating the handler's return as a painted result.
        let actionsPageSelected = controller.showControlActionsForVerification()
        var actionsPageReady = window.acceptedNodeBounds("adaptive-control-button").isSome()
        var accentTurns = 0
        while (accentTurns < 32 && host.isOpen() && !actionsPageReady) {
            let _ = host.pumpOneTurn()
            actionsPageReady = window.acceptedNodeBounds("adaptive-control-button").isSome()
            accentTurns += 1
        }
        let accentBefore = window.platformAccentStatus()
        let fixedAccentDispatched = actionsPageSelected && actionsPageReady &&
            cjguiAdaptiveActivateAcceptedButton(window, controller,
            195, "ADAPTIVE_CONTROL_BUTTON")
        var fixedAccent = window.platformAccentStatus()
        accentTurns = 0
        while (accentTurns < 32 && host.isOpen() &&
            (fixedAccent.adoptedToken != "#b02088ff" || fixedAccent.adoptedSource != "fixed")) {
            let _ = host.pumpOneTurn()
            fixedAccent = window.platformAccentStatus()
            accentTurns += 1
        }
        let fixedStyleAccepted = if (let Some(style) <- controller.namedStyles.forName("adaptive_effect_button")) {
            cjguiComposableUiColorToken(style.base.border) == "#b02088ff"
        } else { false }
        let fixedAccentOk = fixedAccentDispatched && fixedStyleAccepted &&
            fixedAccent.preference == "fixed" && fixedAccent.adoptedToken == "#b02088ff" &&
            fixedAccent.adoptedSource == "fixed" &&
            fixedAccent.adoptedSceneVersion > accentBefore.adoptedSceneVersion
        let followAccentDispatched = cjguiAdaptiveActivateAcceptedButton(window, controller,
            195, "ADAPTIVE_CONTROL_BUTTON")
        var followedAccent = window.platformAccentStatus()
        accentTurns = 0
        while (accentTurns < 32 && host.isOpen() &&
            (followedAccent.adoptedSource != "system" ||
                followedAccent.adoptedToken != followedAccent.observedToken)) {
            let _ = host.pumpOneTurn()
            followedAccent = window.platformAccentStatus()
            accentTurns += 1
        }
        let followAccentOk = followAccentDispatched && followedAccent.observedStatus == "available" &&
            followedAccent.preference == "system" && followedAccent.adoptedSource == "system" &&
            followedAccent.adoptedToken == followedAccent.observedToken &&
            followedAccent.adoptedSceneVersion > fixedAccent.adoptedSceneVersion
        let accentControlOk = actionsPageSelected && actionsPageReady && fixedAccentOk && followAccentOk
        if (!accentControlOk) { failed += 1 }
        getStdOut().writeln("CJGUI_ADAPTIVE_HIT_ASSERT name=accent_control " +
            "ok=${if (accentControlOk) { 1 } else { 0 }} page=${if (actionsPageReady) { 1 } else { 0 }} " +
            "fixedDispatch=${if (fixedAccentDispatched) { 1 } else { 0 }} " +
            "fixed=${if (fixedAccentOk) { 1 } else { 0 }} " +
            "follow=${if (followAccentOk) { 1 } else { 0 }} fixedScene=${fixedAccent.adoptedSceneVersion} " +
            "followScene=${followedAccent.adoptedSceneVersion} observed=${followedAccent.observedToken}")
        // An injected failure proves the caller really reads this verdict: the
        // process must exit non-zero and the completion marker must say failed>0.
        if (injectVerifyFailure) { failed += 1 }
        getStdOut().writeln("CJGUI_ADAPTIVE_HIT_VERDICT assertions=15 failed=${failed} " +
            "inject=${if (injectVerifyFailure) { 1 } else { 0 }} " +
            "reduceMotion=${if (window.reduceMotionEnabled()) { 1 } else { 0 }}")
        getStdOut().writeln("CJGUI_ADAPTIVE_HIT_DONE instance_token=${instanceToken} failed=${failed}")
        getStdOut().flush()
        // The host owns the NSApplication run loop, so a graceful close can end
        // the process before any later return value is seen. A failing assertion
        // therefore exits explicitly, with the non-zero status the caller reads.
        if (failed != 0) {
            exit(1)
        }
        host.close()
        exit(0)
        return 0
    }
    // P4 system-window-material consumer verification is separate from the
    // existing --verify-hit entry. Each action begins at an
    // accepted button, runs through the consumer's normal owner, and reads the
    // accepted native result only from windowProgress().
    if (verifiesWindowMaterial) {
        var failed = 0
        let toggleControlReady = window.acceptedNodeBounds("adaptive-window-material-toggle").isSome()
        let clearControlReady = window.acceptedNodeBounds("adaptive-window-material-clear").isSome()
        let controlsReady = toggleControlReady && clearControlReady
        if (!controlsReady) { failed += 1 }
        getStdOut().writeln("CJGUI_ADAPTIVE_WINDOW_MATERIAL_ASSERT name=accepted_controls " +
            "ok=${if (controlsReady) { 1 } else { 0 }} toggle=${if (toggleControlReady) { 1 } else { 0 }} " +
            "clear=${if (clearControlReady) { 1 } else { 0 }}")

        let initial = cjguiAdaptivePumpUntilWindowMaterial(host, window,
            CjguiWindowBackgroundPolicy.OPAQUE)
        let initialOpaque = cjguiAdaptiveWindowMaterialMatches(initial,
            CjguiWindowBackgroundPolicy.OPAQUE, true)
        if (!initialOpaque) { failed += 1 }
        getStdOut().writeln("CJGUI_ADAPTIVE_WINDOW_MATERIAL_ASSERT name=initial_opaque " +
            "ok=${if (initialOpaque) { 1 } else { 0 }} requested=${initial.windowBackgroundRequested} " +
            "actual=${initial.windowBackgroundActual} backend=${initial.windowBackgroundBackend} " +
            "frame=${initial.windowBackgroundFrameIndex} scene=${initial.windowBackgroundAcceptedSceneVersion}/" +
            "${initial.acceptedSceneVersion} completion=${initial.windowBackgroundCompletion}")

        let ownerIdentity = initial.windowBackgroundIdentity
        let acceptedEnable = cjguiAdaptiveActivateWindowMaterialButton(window, controller,
            NODE_WINDOW_MATERIAL_TOGGLE, "TOGGLE_WINDOW_MATERIAL")
        let ownerEnabled = controller.candidateWindowBackground() == CjguiWindowBackgroundPolicy.SYSTEM_CONTENT_AREA
        let enabled = cjguiAdaptivePumpUntilWindowMaterial(host, window,
            CjguiWindowBackgroundPolicy.SYSTEM_CONTENT_AREA)
        let enableOk = acceptedEnable && ownerEnabled && ownerIdentity == enabled.windowBackgroundIdentity &&
            cjguiAdaptiveWindowMaterialMatches(enabled, CjguiWindowBackgroundPolicy.SYSTEM_CONTENT_AREA, true) &&
            enabled.windowBackgroundColorScheme == CJGUI_COMPOSABLE_UI_PLATFORM_COLOR_SCHEME_DARK &&
            enabled.windowBackgroundFrameIndex > initial.windowBackgroundFrameIndex &&
            enabled.windowBackgroundRequestRevision > initial.windowBackgroundRequestRevision
        if (!enableOk) { failed += 1 }
        getStdOut().writeln("CJGUI_ADAPTIVE_WINDOW_MATERIAL_ASSERT name=enable_system_content_area " +
            "ok=${if (enableOk) { 1 } else { 0 }} dispatched=${if (acceptedEnable) { 1 } else { 0 }} " +
            "owner=${controller.candidateWindowBackground()} requested=${enabled.windowBackgroundRequested} " +
            "actual=${enabled.windowBackgroundActual} reason=${enabled.windowBackgroundFallbackReason} " +
            "frame=${enabled.windowBackgroundFrameIndex} requestRevision=${enabled.windowBackgroundRequestRevision} " +
            "scene=${enabled.windowBackgroundAcceptedSceneVersion}/${enabled.acceptedSceneVersion}")

        let acceptedOpaque = cjguiAdaptiveActivateWindowMaterialButton(window, controller,
            NODE_WINDOW_MATERIAL_TOGGLE, "TOGGLE_WINDOW_MATERIAL")
        let ownerOpaque = controller.candidateWindowBackground() == CjguiWindowBackgroundPolicy.OPAQUE
        let opaque = cjguiAdaptivePumpUntilWindowMaterial(host, window, CjguiWindowBackgroundPolicy.OPAQUE)
        let opaqueOk = acceptedOpaque && ownerOpaque && ownerIdentity == opaque.windowBackgroundIdentity &&
            cjguiAdaptiveWindowMaterialMatches(opaque, CjguiWindowBackgroundPolicy.OPAQUE, true) &&
            opaque.windowBackgroundFrameIndex > enabled.windowBackgroundFrameIndex &&
            opaque.windowBackgroundRequestRevision > enabled.windowBackgroundRequestRevision
        if (!opaqueOk) { failed += 1 }
        getStdOut().writeln("CJGUI_ADAPTIVE_WINDOW_MATERIAL_ASSERT name=switch_back_to_opaque " +
            "ok=${if (opaqueOk) { 1 } else { 0 }} dispatched=${if (acceptedOpaque) { 1 } else { 0 }} " +
            "owner=${controller.candidateWindowBackground()} requested=${opaque.windowBackgroundRequested} " +
            "actual=${opaque.windowBackgroundActual} frame=${opaque.windowBackgroundFrameIndex} " +
            "requestRevision=${opaque.windowBackgroundRequestRevision} " +
            "scene=${opaque.windowBackgroundAcceptedSceneVersion}/${opaque.acceptedSceneVersion}")

        // An explicit clear while already opaque still reaches the owner. It
        // is an idempotent material request, so the accepted material frame
        // and request revision must remain stable after the host settles.
        let acceptedClear = cjguiAdaptiveActivateWindowMaterialButton(window, controller,
            NODE_WINDOW_MATERIAL_CLEAR, "CLEAR_WINDOW_MATERIAL")
        let ownerCleared = controller.candidateWindowBackground() == CjguiWindowBackgroundPolicy.OPAQUE
        let _ = host.pumpOneTurn()
        let cleared = window.windowProgress()
        let clearOk = acceptedClear && ownerCleared &&
            ownerIdentity == cleared.windowBackgroundIdentity &&
            cleared.windowBackgroundFrameIndex == opaque.windowBackgroundFrameIndex &&
            cleared.windowBackgroundRequestRevision == opaque.windowBackgroundRequestRevision &&
            cjguiAdaptiveWindowMaterialMatches(cleared, CjguiWindowBackgroundPolicy.OPAQUE, false)
        if (!clearOk) { failed += 1 }
        getStdOut().writeln("CJGUI_ADAPTIVE_WINDOW_MATERIAL_ASSERT name=explicit_clear_while_opaque " +
            "ok=${if (clearOk) { 1 } else { 0 }} dispatched=${if (acceptedClear) { 1 } else { 0 }} " +
            "owner=${controller.candidateWindowBackground()} requested=${cleared.windowBackgroundRequested} " +
            "actual=${cleared.windowBackgroundActual} frame=${cleared.windowBackgroundFrameIndex} " +
            "scene=${cleared.windowBackgroundAcceptedSceneVersion}/${cleared.acceptedSceneVersion}")

        let acceptedRestore = cjguiAdaptiveActivateWindowMaterialButton(window, controller,
            NODE_WINDOW_MATERIAL_TOGGLE, "TOGGLE_WINDOW_MATERIAL")
        let ownerRestored = controller.candidateWindowBackground() == CjguiWindowBackgroundPolicy.SYSTEM_CONTENT_AREA
        let restored = cjguiAdaptivePumpUntilWindowMaterial(host, window,
            CjguiWindowBackgroundPolicy.SYSTEM_CONTENT_AREA)
        let restoreOk = acceptedRestore && ownerRestored && ownerIdentity == restored.windowBackgroundIdentity &&
            cjguiAdaptiveWindowMaterialMatches(restored, CjguiWindowBackgroundPolicy.SYSTEM_CONTENT_AREA, true) &&
            restored.windowBackgroundColorScheme == CJGUI_COMPOSABLE_UI_PLATFORM_COLOR_SCHEME_DARK &&
            restored.windowBackgroundFrameIndex > cleared.windowBackgroundFrameIndex &&
            restored.windowBackgroundRequestRevision > opaque.windowBackgroundRequestRevision
        if (!restoreOk) { failed += 1 }
        getStdOut().writeln("CJGUI_ADAPTIVE_WINDOW_MATERIAL_ASSERT name=restore_system_content_area " +
            "ok=${if (restoreOk) { 1 } else { 0 }} dispatched=${if (acceptedRestore) { 1 } else { 0 }} " +
            "owner=${controller.candidateWindowBackground()} requested=${restored.windowBackgroundRequested} " +
            "actual=${restored.windowBackgroundActual} reason=${restored.windowBackgroundFallbackReason} " +
            "frame=${restored.windowBackgroundFrameIndex} requestRevision=${restored.windowBackgroundRequestRevision} " +
            "scene=${restored.windowBackgroundAcceptedSceneVersion}/${restored.acceptedSceneVersion}")

        // This controller has no public resize driver, no platform-theme
        // consumer, and no focused editable control. Keep this verdict within
        // the real material receipt and accepted-button owner path.
        if (injectVerifyFailure) { failed += 1 }
        getStdOut().writeln("CJGUI_ADAPTIVE_WINDOW_MATERIAL_VERDICT assertions=6 failed=${failed} " +
            "inject=${if (injectVerifyFailure) { 1 } else { 0 }} " +
            "resize=not_driven theme=not_consumed focus=not_driven " +
            "requested=${restored.windowBackgroundRequested} actual=${restored.windowBackgroundActual} " +
            "frame=${restored.windowBackgroundFrameIndex}")
        getStdOut().writeln("CJGUI_ADAPTIVE_WINDOW_MATERIAL_DONE instance_token=${instanceToken} failed=${failed}")
        getStdOut().flush()
        if (failed != 0) {
            exit(1)
        }
        host.close()
        exit(0)
        return 0
    }
    // This second endpoint uses the same public transport and authorization
    // boundary as the task owner. It exposes only images this application has
    // already imported; no external caller can read a system pasteboard here.
    let imageOwnerSlot: Int64 = 7199
    let imageAuthorization = CjguiSharedOperationExternalAuthorization(
        "adaptive-png-owner-client", "demo-only-authorized-image-capability",
        ArrayList<CjguiSharedOperationExternalActionScope>([
            CjguiSharedOperationExternalActionScope("GET_CONTEXT",
                ArrayList<Int64>([imageOwnerSlot]), false),
            CjguiSharedOperationExternalActionScope("SELECT_OWNED_IMAGE",
                ArrayList<Int64>([imageOwnerSlot]), false)
        ]))
    let imageConnection = CjguiSharedOperationExternalConnection(
        CjguiSharedOperationImageOwnerDomain(controller.imageOwner(), imageOwnerSlot), imageAuthorization)
    if (!host.adoptExternalConnectionForClose(imageConnection)) {
        imageConnection.close()
        host.close()
        return 1
    }
    if (!imageConnection.start()) { host.close(); return 1 }
    if (let Some(info) <- imageConnection.connectionInfo()) {
        getStdOut().writeln("CJGUI_PNG_EXTERNAL_READY consumer=adaptive descriptor=${info.descriptorPath} slot=${imageOwnerSlot}")
        getStdOut().flush()
    }
    while (host.isOpen()) {
        let _ = imageConnection.pumpBurst(4u32, 0u32, 0u32)
        if (imageConnection.consumeWindowRefreshRequest()) {
            let state = controller.imageOwner().snapshot()
            getStdOut().writeln("CJGUI_PNG_EXTERNAL_APPLIED consumer=adaptive version=${state.version} " +
                "digest=${state.contentDigest}")
            getStdOut().flush()
        }
        let _ = host.pumpOneTurn()
        if (observesDiagnostics) {
            let scene = window.windowProgress().acceptedSceneVersion
            if (scene != observedDiagnosticVersion) {
                let sample = window.diagnosticSnapshot(maximumNodes: 256)
                observedDiagnosticVersion = sample.acceptedSceneVersion
                getStdOut().writeln("CJGUI_ADAPTIVE_DIAGNOSTIC_LIVE_CHANGE instance_token=${instanceToken} " +
                    "session=${sample.sessionIdentity} scene=${sample.acceptedSceneVersion} " +
                    "nodes=${sample.nodes.size}/${sample.totalNodes} " +
                    "submissions=${sample.nativeSubmissionCount} draws=${sample.overlayDrawCount}")
                if (let Some(split) <- window.acceptedNodeVisualBounds("adaptive-translated-split")) {
                    getStdOut().writeln("CJGUI_F11_ADAPTIVE_CONTAINER scene=${sample.acceptedSceneVersion} " +
                        "${controller.translationContainerObservation()} " +
                        "visual=${split.x},${split.y},${split.width},${split.height} " +
                        "owner=${domain.version()}:${if (domain.snapshot().recordAt(0).isMarked) { 1 } else { 0 }}")
                }
                getStdOut().flush()
            }
        }
        let effectGroupLine = controller.takeEffectGroupAcceptedChange()
        if (effectGroupLine.size > 0) {
            getStdOut().writeln(effectGroupLine)
            getStdOut().flush()
        }
        if (observesInteraction) {
            let trace = controller.interactionPaintTrace()
            if (trace.size > 0) {
                getStdOut().writeln(trace)
                getStdOut().flush()
            }
        }
    }
    host.close()
    return 0
}

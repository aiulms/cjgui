// Public single-level context command menu assembled from the existing command
// collection. It is presentation only: request identity, selection, target
// versioning, layer installation, command execution and focus return stay in
// the existing window context-menu lifecycle.
//
// Usage: implement CjguiComposableUiContextMenuRequestHandler, call
// `CjguiContextCommandMenu.open` from `requestContextMenu`, attach it to the
// layer host in `buildUi`, and delegate `applyUiEvent` /
// `contextMenuRequestEnded` to the instance. The application passes the same
// command and metadata lists it already uses for the toolbar; it does not
// declare a second action table or reserve numeric item slots. Stability:
// experimental.
package cjgui

import std.collection.*
import std.convert.*

public let CJGUI_CONTEXT_COMMAND_STABILITY: String = "experimental"

/// A context-menu button carries this text. It names the live request and the
/// stable command id; the consumer routes it through
/// `window.invokeContextMenuCommand(requestId, commandId)`, never through the
/// ordinary command entry.
public let CJGUI_CONTEXT_COMMAND_ACTIVATION_PREFIX: String = "CJGUICONTEXTCOMMAND:"

/// The all-disabled menu still needs one live, discoverable keyboard stop
/// inside its own layer. The close entry is presented as an ordinary menu row;
/// activating it only ends this presentation layer through the existing
/// dismissal/reconciliation path and executes no command.
public let CJGUI_CONTEXT_COMMAND_CLOSE_PREFIX: String = "CJGUICONTEXTMENUCLOSE:"

public func cjguiContextCommandMenuCloseAction(requestId: Int64): String {
    if (requestId <= 0) {
        throw IllegalArgumentException("context command close request id must be positive")
    }
    return "${CJGUI_CONTEXT_COMMAND_CLOSE_PREFIX}${requestId}"
}

public func cjguiContextCommandMenuCloseRequest(actionName: String): ?Int64 {
    if (!actionName.startsWith(CJGUI_CONTEXT_COMMAND_CLOSE_PREFIX)) {
        return None
    }
    let rest = actionName[CJGUI_CONTEXT_COMMAND_CLOSE_PREFIX.size..]
    let requestId = match (Int64.tryParse(rest)) {
        case Some(value) => value
        case None => return None
    }
    if (requestId <= 0) {
        return None
    }
    return Some(requestId)
}

public class CjguiContextCommandInvocation {
    public let requestId: Int64
    public let commandId: String
    public init(requestId: Int64, commandId: String) {
        this.requestId = requestId
        this.commandId = commandId
    }
}

public func cjguiContextCommandActivationAction(requestId: Int64, commandId: String): String {
    if (requestId <= 0) {
        throw IllegalArgumentException("context command request id must be positive")
    }
    if (commandId.size == 0) {
        throw IllegalArgumentException("context command id is empty")
    }
    for (byte in commandId.toArray()) {
        if (byte <= 32 || byte == 127) {
            throw IllegalArgumentException("context command id carries control bytes: ${commandId}")
        }
    }
    return "${CJGUI_CONTEXT_COMMAND_ACTIVATION_PREFIX}${requestId}:${commandId}"
}

public func cjguiContextCommandInvocation(actionName: String): ?CjguiContextCommandInvocation {
    if (!actionName.startsWith(CJGUI_CONTEXT_COMMAND_ACTIVATION_PREFIX)) {
        return None
    }
    let rest = actionName[CJGUI_CONTEXT_COMMAND_ACTIVATION_PREFIX.size..]
    let parts = rest.split(":", 2)
    if (parts.size != 2 || parts[0].size == 0 || parts[1].size == 0) {
        return None
    }
    let requestId = match (Int64.tryParse(parts[0])) {
        case Some(value) => value
        case None => return None
    }
    if (requestId <= 0) {
        return None
    }
    return Some(CjguiContextCommandInvocation(requestId, parts[1]))
}

/// Presentation carried from the shared toolbar projection. The caller supplies
/// the same commands and metadata used by the toolbar/palette; `items` is the
/// exact projected state, and `declarations` are the enabled commands with their
/// original `targetReference`. Disabled commands stay visible in `items` but are
/// deliberately absent from `declarations`.
public class CjguiContextCommandMenuProjection {
    public let requestId: Int64
    public let items: ArrayList<CjguiCommandToolbarItem>
    public let declarations: ArrayList<CjguiComposableUiCommand>

    init(requestId: Int64, items: ArrayList<CjguiCommandToolbarItem>,
        declarations: ArrayList<CjguiComposableUiCommand>) {
        this.requestId = requestId
        this.items = ArrayList<CjguiCommandToolbarItem>(items)
        this.declarations = ArrayList<CjguiComposableUiCommand>(declarations)
    }

    public func declarationFor(commandId: String): ?CjguiComposableUiCommand {
        for (declaration in declarations) {
            if (declaration.id == commandId) {
                return Some(declaration)
            }
        }
        return None
    }
}

private func cjguiContextCommandReferenceKey(command: CjguiComposableUiCommand): String {
    if (let Some(identity) <- command.targetReference.scopedIdentity()) {
        return "scoped:${identity.canonicalKey()}"
    }
    return "manual:${command.targetReference.manualNodeId()}"
}

/// Project the same command collection used by the toolbar. The search command
/// is excluded when `searchCommandId` names it, because the search button is a
/// separate entry rather than a context action. Enabled commands keep their own
/// `targetReference`; the window resolves it against the accepted scene and
/// rejects any declaration whose target is not the request target.
public func cjguiContextCommandMenuProjection(request: CjguiComposableUiContextMenuRequest,
    commands: ArrayList<CjguiComposableUiCommand>, metadata: ArrayList<CjguiCommandToolbarMetadata>,
    searchCommandId!: String = ""): CjguiContextCommandMenuProjection {
    if (request.nodeId < 0) {
        throw IllegalArgumentException("context command request has no target")
    }
    let placement = cjguiCommandToolbarPlacement(commands, metadata, searchCommandId: searchCommandId)
    let byId = HashMap<String, CjguiComposableUiCommand>()
    for (command in commands) {
        byId.add(command.id, command)
    }
    let declarations = ArrayList<CjguiComposableUiCommand>()
    for (item in placement.items) {
        let source = match (byId.get(item.commandId)) {
            case Some(value) => value
            case None => throw IllegalArgumentException("context command has no declaration: ${item.commandId}")
        }
        if (item.enabled) {
            declarations.add(source)
        }
    }
    return CjguiContextCommandMenuProjection(request.requestId, placement.items, declarations)
}

private func cjguiContextCommandDeclarationMatches(left: CjguiComposableUiCommand,
    right: CjguiComposableUiCommand): Bool {
    return left.id == right.id &&
        cjguiContextCommandReferenceKey(left) == cjguiContextCommandReferenceKey(right) &&
        left.focusScopeId == right.focusScopeId &&
        cjguiCommandCompletionPolicyCode(left.completionPolicy) == cjguiCommandCompletionPolicyCode(right.completionPolicy)
}

private func cjguiContextCommandProjectionShapeMatches(left: CjguiContextCommandMenuProjection,
    right: CjguiContextCommandMenuProjection): Bool {
    if (left.items.size != right.items.size || left.declarations.size != right.declarations.size) {
        return false
    }
    var index = 0
    while (index < left.items.size) {
        if (left.items[index].commandId != right.items[index].commandId ||
            left.items[index].enabled != right.items[index].enabled) {
            return false
        }
        index += 1
    }
    for (declaration in left.declarations) {
        var found = false
        for (candidate in right.declarations) {
            if (cjguiContextCommandDeclarationMatches(declaration, candidate)) {
                found = true
                break
            }
        }
        if (!found) { return false }
    }
    return true
}

public class CjguiContextCommandMenuStyle {
    public let width: Int64
    public let rowHeight: Int64
    public let disabledRowHeight: Int64
    public let padding: Int64
    public let gap: Int64
    public let background: CjguiComposableUiColor
    public let border: CjguiComposableUiColor
    public let textColor: CjguiComposableUiColor
    public let reasonColor: CjguiComposableUiColor
    public let disabledTextColor: CjguiComposableUiColor
    /// Keyboard navigation paint for the focused row. It is a separate
    /// interaction channel from the owner's CHECKED flag and never touches the
    /// document selection.
    public let focusBackground: CjguiComposableUiColor
    public let focusBorder: CjguiComposableUiColor
    /// A checked row keeps the owner's CHECKED state plus a visible border;
    /// focus still wins while the row is the keyboard stop.
    public let checkedBorder: CjguiComposableUiColor
    /// 0 keeps the natural height. A positive value limits the menu body and
    /// turns it into a viewport-bound scroll area; the caller must provide a
    /// shared `CjguiComposableUiScrollViewport` in that case.
    public let maxHeight: Int64

    public init(width!: Int64 = 220, rowHeight!: Int64 = 34, disabledRowHeight!: Int64 = 52,
        padding!: Int64 = 6, gap!: Int64 = 2, maxHeight!: Int64 = 0,
        background!: CjguiComposableUiColor = CjguiComposableUiColor(0.11, 0.14, 0.2, 1.0),
        border!: CjguiComposableUiColor = CjguiComposableUiColor(0.34, 0.42, 0.56, 1.0),
        textColor!: CjguiComposableUiColor = CjguiComposableUiColor(0.91, 0.95, 1.0, 1.0),
        reasonColor!: CjguiComposableUiColor = CjguiComposableUiColor(0.85, 0.62, 0.58, 1.0),
        disabledTextColor!: CjguiComposableUiColor = CjguiComposableUiColor(0.91, 0.95, 1.0, 1.0),
        focusBackground!: CjguiComposableUiColor = CjguiComposableUiColor(0.19, 0.27, 0.4, 1.0),
        focusBorder!: CjguiComposableUiColor = CjguiComposableUiColor(0.55, 0.7, 0.92, 1.0),
        checkedBorder!: CjguiComposableUiColor = CjguiComposableUiColor(0.32, 0.88, 0.68, 1.0)) {
        if (width <= 0 || rowHeight <= 0 || disabledRowHeight < rowHeight || padding < 0 || gap < 0 ||
            maxHeight < 0 || (maxHeight > 0 && maxHeight < rowHeight + padding * 2)) {
            throw IllegalArgumentException("context command menu style is invalid")
        }
        this.width = width
        this.rowHeight = rowHeight
        this.disabledRowHeight = disabledRowHeight
        this.padding = padding
        this.gap = gap
        this.maxHeight = maxHeight
        this.background = background
        this.border = border
        this.textColor = textColor
        this.reasonColor = reasonColor
        this.disabledTextColor = disabledTextColor
        this.focusBackground = focusBackground
        this.focusBorder = focusBorder
        this.checkedBorder = checkedBorder
    }

    /// Derive menu paint from the existing immutable theme. Explicit colors
    /// passed to the primary initializer still work; this factory only reads
    /// the same theme the page and toolbar use.
    public static func themed(theme: CjguiComposableUiTheme, width!: Int64 = 220,
        rowHeight!: Int64 = 34, disabledRowHeight!: Int64 = 52, maxHeight!: Int64 = 0): CjguiContextCommandMenuStyle {
        let disabledBody = match (theme.bodyInteraction.disabled.textColor) {
            case Some(value) => value
            case None => theme.body.textColor
        }
        let focusBackground = match (theme.inputInteraction.selected.background) {
            case Some(value) => value
            case None => theme.primaryAction.background
        }
        let focusBorder = match (theme.inputInteraction.focused.border) {
            case Some(value) => value
            case None => theme.primaryAction.border
        }
        let checkedBorder = match (theme.inputInteraction.checked.border) {
            case Some(value) => value
            case None => theme.primaryAction.border
        }
        return CjguiContextCommandMenuStyle(width: width, rowHeight: rowHeight,
            disabledRowHeight: disabledRowHeight, maxHeight: maxHeight,
            background: theme.card.background, border: theme.card.border, textColor: theme.heading.textColor,
            reasonColor: disabledBody, disabledTextColor: disabledBody,
            focusBackground: focusBackground, focusBorder: focusBorder, checkedBorder: checkedBorder)
    }
}

private func cjguiContextCommandRowHeight(item: CjguiCommandToolbarItem,
    style: CjguiContextCommandMenuStyle): Int64 {
    return if (item.enabled) {
        style.rowHeight
    } else {
        style.disabledRowHeight
    }
}

/// Build the single-level menu layer from a projection. The layer identity and
/// every row/item/reason identity come from `scope`, so the same component can
/// be mounted twice without reserving numeric slots. The layer still uses the
/// request's frozen layer id and pointer anchor; this function never declares or
/// executes a command.
public func cjguiComposableContextCommandMenuLayer(scope: CjguiComposableUiIdentityScope,
    semanticId: String, request: CjguiComposableUiContextMenuRequest,
    projection: CjguiContextCommandMenuProjection, ownerSemanticId: String,
    style!: CjguiContextCommandMenuStyle = CjguiContextCommandMenuStyle(),
    scrollViewport!: ?CjguiComposableUiScrollViewport = None): CjguiComposableUiNode {
    if (!scope.isValid() || semanticId.size == 0 || ownerSemanticId.size == 0) {
        throw IllegalArgumentException("context command menu scope or identity is invalid")
    }
    if (request.requestId != projection.requestId || projection.items.size == 0) {
        throw IllegalArgumentException("context command menu projection does not match its request")
    }
    var height = style.padding * 2 + style.gap * (projection.items.size - 1)
    var enabledItems = 0
    var firstEnabledKey = ""
    for (item in projection.items) {
        height += cjguiContextCommandRowHeight(item, style)
        if (item.enabled) {
            enabledItems += 1
            if (firstEnabledKey.size == 0) { firstEnabledKey = item.key }
        }
    }
    // With no executable row the layer still needs one live, visible keyboard
    // stop; otherwise focus stays on the covered control and Enter would
    // operate it. The close row ends this layer through the ordinary dismissal
    // reconciliation and executes no command.
    if (enabledItems == 0) {
        height += style.gap + style.rowHeight
    }
    let scrollable = style.maxHeight > 0 && height > style.maxHeight
    let bodyHeight = if (scrollable) { style.maxHeight } else { height }
    let focusKey = if (firstEnabledKey.size > 0) { "item-${firstEnabledKey}" } else { "close" }
    let focusReference = Some(CjguiComposableUiNodeReference.scoped(scope, focusKey))
    let focusedPaint = CjguiComposableUiInteractionStyle(
        focused: CjguiComposableUiPaintStyle(background: Some(style.focusBackground),
            border: Some(style.focusBorder), borderWidth: Some(1)),
        checked: CjguiComposableUiPaintStyle(border: Some(style.checkedBorder), borderWidth: Some(1)),
        disabled: CjguiComposableUiPaintStyle(textColor: Some(style.disabledTextColor)))
    let rows = ArrayList<CjguiComposableUiNode>()
    if (enabledItems == 0) {
        // The all-disabled close entry leads the menu: it is the initial focus
        // target, and a constrained height must not clip the only live stop.
        let closeRow = cjguiComposableVertical(-1, "${semanticId}-close-row",
            CjguiComposableUiStyle(fixedHeight: style.rowHeight, growX: 1),
            identity: Some(scope.local("close-row")))
        closeRow.add(cjguiComposableButton(-1, "${semanticId}-close", "关闭菜单",
            cjguiContextCommandMenuCloseAction(request.requestId), request.nodeId,
            CjguiComposableUiStyle(fixedHeight: style.rowHeight - 4, growX: 1, fontSize: 13.0,
                textMaxLines: 1, textOverflow: "ellipsis", textColor: style.textColor),
            interactionStyle: focusedPaint, identity: Some(scope.local("close"))))
        rows.add(closeRow)
    }
    for (item in projection.items) {
        let row = cjguiComposableVertical(-1, "${semanticId}-row-${item.key}",
            CjguiComposableUiStyle(fixedHeight: cjguiContextCommandRowHeight(item, style), gap: 1, growX: 1),
            identity: Some(scope.local("row-${item.key}")))
        row.add(cjguiComposableButton(-1, "${semanticId}-item-${item.key}", cjguiCommandItemLabel(item),
            cjguiContextCommandActivationAction(request.requestId, item.commandId), item.resourceId,
            CjguiComposableUiStyle(fixedHeight: style.rowHeight - 4, growX: 1, fontSize: 13.0,
                textMaxLines: 1, textOverflow: "ellipsis", textColor: style.textColor), enabled: item.enabled,
            ownerInteractionState: if (item.checked) {
                CjguiComposableUiInteractionState.CHECKED
            } else {
                CjguiComposableUiInteractionState.NONE
            }, interactionStyle: focusedPaint,
            semanticRole: if (item.checkable) {
                CJGUI_COMPOSABLE_UI_SEMANTIC_CHECKBOX
            } else {
                CJGUI_COMPOSABLE_UI_SEMANTIC_BUTTON
            }, semanticHelp: if (item.enabled) { "" } else { item.disabledReason },
            identity: Some(scope.local("item-${item.key}"))))
        if (!item.enabled) {
            row.add(cjguiComposableText(-1, "${semanticId}-reason-${item.key}",
                if (item.disabledReason.size > 0) {
                    "不可用：${item.disabledReason}"
                } else {
                    "不可用"
                },
                CjguiComposableUiStyle(fixedHeight: 16, growX: 1, fontSize: 11.0, textMaxLines: 1,
                    textOverflow: "ellipsis", textColor: style.reasonColor),
                identity: Some(scope.local("reason-${item.key}"))))
        }
        rows.add(row)
    }
    let layerStyle = if (scrollable) {
        CjguiComposableUiStyle(fixedWidth: style.width, fixedHeight: bodyHeight, padding: 0, gap: 0,
            background: style.background, border: style.border, borderWidth: 1, textColor: style.textColor)
    } else {
        CjguiComposableUiStyle(fixedWidth: style.width, fixedHeight: bodyHeight, padding: style.padding,
            gap: style.gap, background: style.background, border: style.border, borderWidth: 1,
            textColor: style.textColor)
    }
    let menu = cjguiComposableContextMenuLayer(-1, "${semanticId}-menu", request.layerId,
        ownerSemanticId, request.nodeId, request.hostLocalX, request.hostLocalY, layerStyle,
        identity: Some(scope.local("menu")), initialFocusReference: focusReference)
    if (!scrollable) {
        for (row in rows) { menu.add(row) }
        return menu
    }
    let viewport = match (scrollViewport) {
        case Some(value) => value
        case None => throw IllegalArgumentException(
            "context command menu overflow requires a scroll viewport")
    }
    let scroll = CjguiComposableUiNode(-1, "${semanticId}-scroll", CJGUI_COMPOSABLE_UI_SCROLL_AREA,
        "", "", "SCROLL", -1, CjguiComposableUiStyle(fixedWidth: style.width, fixedHeight: bodyHeight,
            growX: 1, growY: 1), scrollOffset: viewport.offset(), scrollViewport: Some(viewport),
        identity: Some(scope.local("scroll")))
    let content = cjguiComposableVertical(-1, "${semanticId}-content",
        CjguiComposableUiStyle(fixedWidth: style.width, padding: style.padding, gap: style.gap, growX: 1),
        identity: Some(scope.local("content")))
    for (row in rows) { content.add(row) }
    scroll.add(content)
    menu.add(scroll)
    return menu
}

/// Thin owner of one context menu surface. It remembers the projection and
/// request identity only for presentation; the window remains the authority for
/// the request, accepted target and command validation.
public class CjguiContextCommandMenu {
    private let menuScope: CjguiComposableUiIdentityScope
    private let semanticId: String
    private var projectionValue: ?CjguiContextCommandMenuProjection = None
    private var requestValue: ?CjguiComposableUiContextMenuRequest = None
    private var ownerSemanticIdValue: String = ""
    private var styleValue: CjguiContextCommandMenuStyle = CjguiContextCommandMenuStyle()
    private var visibleValue: Bool = false
    // One viewport per open request. Its offset survives projection rebuilds;
    // the wheel, keyboard reveal and accepted-scene clamp all use this one
    // public scroll state instead of a second content-offset model.
    private var scrollViewportValue: ?CjguiComposableUiScrollViewport = None

    public init(scope: CjguiComposableUiIdentityScope, semanticId: String) {
        let menuScope = scope.child("context-menu")
        if (!menuScope.isValid() || semanticId.size == 0) {
            throw IllegalArgumentException("context command menu scope or semantic id is invalid")
        }
        this.menuScope = menuScope
        this.semanticId = semanticId
    }

    public func isOpen(): Bool {
        return visibleValue
    }

    public func currentRequestId(): Int64 {
        return match (requestValue) {
            case Some(value) => value.requestId
            case None => -1
        }
    }

    /// Declare every enabled command for this exact request, then expose the
    /// menu. Disabled commands remain visible but are never declared. The
    /// caller chooses how each row is authorized: `WindowCommand` (the default)
    /// requires the id to remain a live window command with the same target and
    /// scope, so a revoked or re-targeted binding is rejected rather than
    /// treated as request-local; `RequestLocal` is for rows that exist only for
    /// this request and have no window-level declaration. Neither source skips
    /// the accepted-target check, and a failed binding lookup never downgrades
    /// one to the other. If any enabled declaration is rejected (stale target,
    /// disabled target, changed binding), nothing is shown and the window
    /// retires the request normally.
    public func open(window: CjguiComposableUiWindow, request: CjguiComposableUiContextMenuRequest,
        commands: ArrayList<CjguiComposableUiCommand>, metadata: ArrayList<CjguiCommandToolbarMetadata>,
        ownerSemanticId: String, searchCommandId!: String = "",
        source!: CjguiContextMenuCommandSource = CjguiContextMenuCommandSource.WindowCommand,
        style!: CjguiContextCommandMenuStyle = CjguiContextCommandMenuStyle()): Bool {
        hide()
        if (request.nodeId < 0 || ownerSemanticId.size == 0) {
            return false
        }
        let projection = cjguiContextCommandMenuProjection(request, commands, metadata,
            searchCommandId: searchCommandId)
        if (projection.items.size == 0) {
            return false
        }
        for (declaration in projection.declarations) {
            if (!window.declareContextMenuCommand(request.requestId, declaration, source: source)) {
                return false
            }
        }
        this.projectionValue = Some(projection)
        this.requestValue = Some(request)
        this.ownerSemanticIdValue = ownerSemanticId
        this.styleValue = style
        this.scrollViewportValue = Some(CjguiComposableUiScrollViewport())
        this.visibleValue = true
        return true
    }

    /// Presentation overload: the caller passes the same declaration holder it
    /// uses for the toolbar and palette. Execution, declaration and request
    /// validation stay in the existing method below.
    public func open(window: CjguiComposableUiWindow, request: CjguiComposableUiContextMenuRequest,
        presentation: CjguiCommandPresentation, ownerSemanticId: String,
        source!: CjguiContextMenuCommandSource = CjguiContextMenuCommandSource.WindowCommand,
        style!: CjguiContextCommandMenuStyle = CjguiContextCommandMenuStyle()): Bool {
        return open(window, request, presentation.commands, presentation.metadata, ownerSemanticId,
            searchCommandId: presentation.searchCommandId, source: source, style: style)
    }

    /// Re-project the menu against the caller's current command collection
    /// while it is open. Label, checked state and disabled reason update in
    /// place. Any change to the executable command set (enabled/disabled,
    /// removed, re-targeted or re-scoped) retires the surface instead: the menu
    /// layer disappears on the caller's next accepted scene and the window ends
    /// the request through its ordinary lifecycle. The window independently
    /// revalidates an invoked id against its current command bindings, so a
    /// stale row or a direct old invocation cannot execute a revoked command.
    public func reconcile(window: CjguiComposableUiWindow,
        commands: ArrayList<CjguiComposableUiCommand>, metadata: ArrayList<CjguiCommandToolbarMetadata>,
        searchCommandId!: String = ""): Bool {
        if (!visibleValue) {
            return false
        }
        let request = match (requestValue) {
            case Some(value) => value
            case None => return false
        }
        let previous = match (projectionValue) {
            case Some(value) => value
            case None => return false
        }
        let current = cjguiContextCommandMenuProjection(request, commands, metadata,
            searchCommandId: searchCommandId)
        if (!cjguiContextCommandProjectionShapeMatches(previous, current)) {
            hide()
            window.requestRefresh()
            return false
        }
        projectionValue = Some(current)
        return true
    }

    /// Swap only the paint of an open menu. Request identity, projection,
    /// focus target and the shared scroll viewport stay untouched, so a theme
    /// change while open cannot reset the query-free navigation state or the
    /// wheel position. A hidden menu keeps the new style for its next open.
    public func restyle(style: CjguiContextCommandMenuStyle): Bool {
        if (!visibleValue) {
            return false
        }
        styleValue = style
        return true
    }

    /// Add the visible menu layer to the caller's layer host. A hidden or
    /// retired menu adds nothing.
    public func attachTo(host: CjguiComposableUiNode): CjguiComposableUiNode {
        if (!visibleValue) {
            return host
        }
        let request = match (requestValue) {
            case Some(value) => value
            case None => return host
        }
        let projection = match (projectionValue) {
            case Some(value) => value
            case None => return host
        }
        host.add(cjguiComposableContextCommandMenuLayer(menuScope, semanticId, request, projection,
            ownerSemanticIdValue, style: styleValue, scrollViewport: scrollViewportValue))
        return host
    }

    /// Consume menu activation and layer dismissal. A menu item is executed only
    /// through `invokeContextMenuCommand` with the request id frozen in its
    /// button; a stale request is never rebound to the current target.
    public func applyUiEvent(event: CjguiComposableUiEvent,
        window: CjguiComposableUiWindow): ?CjguiComposableUiDispatchResult {
        if (!visibleValue) {
            return None
        }
        let requestId = currentRequestId()
        if (event.eventKind == 36 &&
            (event.text == "escape:${requestId}" || event.text == "outside:${requestId}")) {
            hide()
            window.requestRefresh()
            return Some(CjguiComposableUiDispatchResult(true))
        }
        if (event.eventKind != 27) {
            return None
        }
        if (let Some(closeRequest) <- cjguiContextCommandMenuCloseRequest(event.node.actionName)) {
            // The all-disabled close row is a presentation-only keyboard stop.
            // It ends this layer through the same dismissal/refresh path as an
            // executed row and executes no business command; a stale close
            // action from an older request is refused.
            if (closeRequest != requestId) {
                return Some(CjguiComposableUiDispatchResult(false))
            }
            hide()
            window.requestRefresh()
            return Some(CjguiComposableUiDispatchResult(true))
        }
        let invocation = match (cjguiContextCommandInvocation(event.node.actionName)) {
            case Some(value) => value
            case None => return None
        }
        if (invocation.requestId != requestId) {
            return Some(CjguiComposableUiDispatchResult(false))
        }
        let projection = match (projectionValue) {
            case Some(value) => value
            case None => return Some(CjguiComposableUiDispatchResult(false))
        }
        if (projection.declarationFor(invocation.commandId).isNone()) {
            return Some(CjguiComposableUiDispatchResult(false))
        }
        let applied = window.invokeContextMenuCommand(invocation.requestId, invocation.commandId)
        hide()
        window.requestRefresh()
        return Some(CjguiComposableUiDispatchResult(applied))
    }

    /// The window reports superseded, outside, escape, stale-target and
    /// native-guard endings here. Presentation clears; command declarations and
    /// focus return remain the window's responsibility.
    public func requestEnded(requestId: Int64): Bool {
        if (!visibleValue || currentRequestId() != requestId) {
            return false
        }
        hide()
        return true
    }

    private func hide(): Unit {
        visibleValue = false
        projectionValue = None
        requestValue = None
        ownerSemanticIdValue = ""
        scrollViewportValue = None
    }
}

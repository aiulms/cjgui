// Public command toolbar and its bridge to the existing searchable panel.
//
// The caller owns one CjguiComposableUiCommand list. The toolbar and palette
// derive label, target node, enabled state and shortcut from that list; the
// application adds only presentation metadata (action name it already handles,
// resource, detail). The palette releases the stable command id and the caller
// invokes it through the window's common command entry. Stability: experimental.
//
// Dynamic collections: rebuild the command and metadata lists on every scene
// build and project them again with `cjguiCommandToolbarPlacement`. Adding or
// removing commands (including all of them) is valid; an empty projection
// composes an empty toolbar. If the palette is open, call `updateItems` with
// the new projection so rows and enabled/checked state move together. The
// search command is projected into `CjguiCommandToolbarPlacement.searchItem`;
// removing it removes the search button, disabling it disables the button.
//
// The search button always keeps the owner action supplied in metadata. It is
// deliberately not wrapped in `CJGUICOMMAND:`: the command target is the search
// button itself, and routing its own action through `invokeCommand` would
// re-enter the same button and recurse. The common command entry may target the
// button and dispatch that owner action once; the button does not route back.
package cjgui

import std.collection.*

public let CJGUI_COMMAND_TOOLBAR_STABILITY: String = "experimental"

/// A scoped toolbar button carries this action text. The consumer routes it
/// through `window.invokeCommand` by the embedded id; the trigger never owns
/// a second business action or a parallel command table.
public let CJGUI_COMMAND_TOOLBAR_ACTIVATION_PREFIX: String = "CJGUICOMMAND:"

public func cjguiCommandToolbarActivationAction(commandId: String): String {
    if (commandId.size == 0) {
        throw IllegalArgumentException("command id is empty")
    }
    for (byte in commandId.toArray()) {
        if (byte <= 32 || byte == 127) {
            throw IllegalArgumentException("command id carries control bytes: ${commandId}")
        }
    }
    return CJGUI_COMMAND_TOOLBAR_ACTIVATION_PREFIX + commandId
}

public func cjguiCommandToolbarCommandId(actionName: String): ?String {
    if (!actionName.startsWith(CJGUI_COMMAND_TOOLBAR_ACTIVATION_PREFIX)) {
        return None
    }
    let commandId = actionName[CJGUI_COMMAND_TOOLBAR_ACTIVATION_PREFIX.size..]
    if (commandId.size == 0) {
        return None
    }
    return Some(commandId)
}

/// Presentation metadata for one declared command. It never carries an
/// execution definition: label, enabled, checked, shortcut and target node are
/// read from `CjguiComposableUiCommand`.
public class CjguiCommandToolbarMetadata {
    public let commandId: String
    public let actionName: String
    public let resourceId: Int64
    public let detail: String
    public let disabledReason: String

    public init(commandId: String, actionName: String, resourceId: Int64, detail!: String = "",
        disabledReason!: String = "") {
        this.commandId = commandId
        this.actionName = actionName
        this.resourceId = resourceId
        this.detail = detail
        this.disabledReason = disabledReason
    }
}

/// Presentation key derived from a command id. Semantic ids and the public
/// window projection accept only `[A-Za-z_][A-Za-z0-9_-]*`, while execution
/// keeps the original command id. Dots and other separators become '-'; an id
/// that still cannot form a safe key is a declaration error.
public func cjguiCommandToolbarKey(commandId: String): String {
    if (commandId.size == 0) {
        throw IllegalArgumentException("command id is empty")
    }
    var key = commandId.replace(".", "-")
    let bytes = key.toArray()
    var index = 0
    for (byte in bytes) {
        let letter = (byte >= 65 && byte <= 90) || (byte >= 97 && byte <= 122) || byte == 95
        let continuation = (byte >= 48 && byte <= 57) || byte == 45
        if (!letter && !(index > 0 && continuation)) {
            throw IllegalArgumentException("command id has no safe presentation key: ${commandId}")
        }
        index += 1
    }
    return key
}

/// One projected toolbar item. `commandId` is the only execution identity the
/// palette returns; `nodeBase` is the manual command target (-1 for a scoped
/// command) and `targetReference` is the declaration the window resolves.
public class CjguiCommandToolbarItem {
    public let key: String
    public let commandId: String
    public let label: String
    public let detail: String
    public let shortcut: String
    public let actionName: String
    public let resourceId: Int64
    public let nodeBase: Int64
    public let targetReference: CjguiComposableUiNodeReference
    public let enabled: Bool
    public let disabledReason: String
    /// The declaration's checked state, projected unchanged into the toolbar
    /// and palette. It is not a second value owner.
    public let checked: Bool
    /// The declaration's own checkable bit. It decides the semantic role and
    /// state a reader sees; a checked value on a plain action never does.
    public let checkable: Bool

    public init(commandId: String, label: String, actionName: String, resourceId: Int64, nodeBase: Int64,
        detail!: String = "", shortcut!: String = "", enabled!: Bool = true, disabledReason!: String = "",
        checked!: Bool = false, checkable!: Bool = false, targetReference!: ?CjguiComposableUiNodeReference = None) {
        this.key = cjguiCommandToolbarKey(commandId)
        this.commandId = commandId
        this.label = label
        this.actionName = actionName
        this.resourceId = resourceId
        this.nodeBase = nodeBase
        this.targetReference = match (targetReference) {
            case Some(value) => value
            case None =>
                if (nodeBase < 0) {
                    throw IllegalArgumentException("toolbar item needs a manual or scoped target: ${commandId}")
                }
                CjguiComposableUiNodeReference.manual(nodeBase)
        }
        this.detail = detail
        this.shortcut = shortcut
        this.enabled = enabled
        this.disabledReason = disabledReason
        this.checked = checked
        this.checkable = checkable
    }
}

/// Order is presentation only. Duplicate command ids or reused button slots
/// are declaration errors, not runtime fallbacks. Slot uniqueness belongs to
/// the toolbar composer that materializes buttons; a context menu may
/// legitimately project several commands that share one manual target node.
public class CjguiCommandToolbarPlacement {
    public let items: ArrayList<CjguiCommandToolbarItem>
    public let searchNodeBase: Int64
    public let searchCommandId: String
    /// Projection of the search command. It carries the declaration's enabled,
    /// checked and disabled reason; the search button still uses the owner
    /// action from metadata rather than the command activation bridge.
    public let searchItem: ?CjguiCommandToolbarItem

    public init(items: ArrayList<CjguiCommandToolbarItem>, searchNodeBase!: Int64 = -1,
        searchCommandId!: String = "", searchItem!: ?CjguiCommandToolbarItem = None) {
        let keys = HashSet<String>()
        let copied = ArrayList<CjguiCommandToolbarItem>(items)
        for (item in copied) {
            if (item.commandId.size == 0 || item.label.size == 0 || item.actionName.size == 0 ||
                item.nodeBase < -1 || !item.targetReference.isValid()) {
                throw IllegalArgumentException("command toolbar item is invalid")
            }
            if (!keys.add(item.key)) {
                throw IllegalArgumentException("command toolbar key must be unique")
            }
        }
        if (let Some(search) <- searchItem) {
            if (searchCommandId.size == 0 || search.commandId != searchCommandId ||
                search.nodeBase != searchNodeBase || search.actionName.size == 0 || search.resourceId < 0 ||
                !search.targetReference.isValid()) {
                throw IllegalArgumentException("command toolbar search item is inconsistent")
            }
            // The search command targets the search button itself. Its action
            // must stay the owner action; wrapping it in the activation prefix
            // would make invokeCommand re-enter the same button.
            if (search.actionName.startsWith(CJGUI_COMMAND_TOOLBAR_ACTIVATION_PREFIX)) {
                throw IllegalArgumentException("search button must keep its owner action")
            }
        }
        this.items = copied
        this.searchNodeBase = searchNodeBase
        this.searchCommandId = searchCommandId
        this.searchItem = searchItem
    }

    public func itemForKey(key: String): ?CjguiCommandToolbarItem {
        for (item in items) {
            if (item.key == key) {
                return Some(item)
            }
        }
        return None
    }

    public func itemForCommand(commandId: String): ?CjguiCommandToolbarItem {
        for (item in items) {
            if (item.commandId == commandId) {
                return Some(item)
            }
        }
        return None
    }
}

/// Project commands into toolbar items. Every command must name one manual or
/// scoped toolbar target; commands without metadata are declaration errors.
/// The optional search command is projected as the toolbar's search button.
public func cjguiCommandToolbarPlacement(commands: ArrayList<CjguiComposableUiCommand>,
    metadata: ArrayList<CjguiCommandToolbarMetadata>, searchCommandId!: String = ""): CjguiCommandToolbarPlacement {
    let items = ArrayList<CjguiCommandToolbarItem>()
    let consumed = HashSet<String>()
    var searchNode = -1
    var searchItem: ?CjguiCommandToolbarItem = None
    for (command in commands) {
        var declaration: ?CjguiCommandToolbarMetadata = None
        for (entry in metadata) {
            if (entry.commandId == command.id) {
                declaration = Some(entry)
            }
        }
        let entry = match (declaration) {
            case Some(value) => value
            case None => throw IllegalArgumentException("toolbar command has no metadata: ${command.id}")
        }
        let reference = command.targetReference
        let targetNode = command.manualTargetNodeId()
        let scoped = reference.scopedIdentity().isSome()
        if (!reference.isValid() || (!scoped && targetNode < 0)) {
            throw IllegalArgumentException("toolbar command needs a manual or scoped target: ${command.id}")
        }
        if (!consumed.add(command.id)) {
            throw IllegalArgumentException("toolbar command is duplicated: ${command.id}")
        }
        if (command.id == searchCommandId) {
            if (!scoped) {
                searchNode = targetNode
            }
            searchItem = Some(CjguiCommandToolbarItem(command.id, command.displayName, entry.actionName,
                entry.resourceId, targetNode, detail: entry.detail,
                shortcut: cjguiCommandShortcutDisplay(command), enabled: command.isEnabled,
                disabledReason: entry.disabledReason, checked: command.isChecked,
                checkable: command.isCheckable, targetReference: reference))
        } else {
            items.add(CjguiCommandToolbarItem(command.id, command.displayName, entry.actionName,
                entry.resourceId, targetNode, detail: entry.detail,
                shortcut: cjguiCommandShortcutDisplay(command), enabled: command.isEnabled,
                disabledReason: entry.disabledReason, checked: command.isChecked,
                checkable: command.isCheckable, targetReference: reference))
        }
    }
    for (entry in metadata) {
        if (!consumed.contains(entry.commandId)) {
            throw IllegalArgumentException("toolbar metadata has no command: ${entry.commandId}")
        }
    }
    // A removed search declaration removes the button: keep no stale command
    // id that would otherwise compose an enabled search entry.
    let projectedSearchId = if (searchItem.isSome()) {
        searchCommandId
    } else {
        ""
    }
    return CjguiCommandToolbarPlacement(items, searchNodeBase: searchNode,
        searchCommandId: projectedSearchId, searchItem: searchItem)
}

/// Display-only projection of a declared shortcut. Execution still uses the
/// command id, never this text.
private func cjguiCommandShortcutDisplay(command: CjguiComposableUiCommand): String {
    if (!command.hasShortcut()) {
        return ""
    }
    let shortcut = command.shortcut
    if (!shortcut.usesCommand && !shortcut.usesControl && !shortcut.usesOption && !shortcut.usesShift) {
        return shortcut.key
    }
    var text = ""
    if (shortcut.usesControl) {
        text += "⌃"
    }
    if (shortcut.usesOption) {
        text += "⌥"
    }
    if (shortcut.usesShift) {
        text += "⇧"
    }
    if (shortcut.usesCommand) {
        text += "⌘"
    }
    return text + shortcut.key
}

public class CjguiCommandToolbarStyle {
    public let bar: CjguiComposableUiStyle
    public let item: CjguiComposableUiStyle
    public let search: CjguiComposableUiStyle
    /// Paint for hover/focus/disabled/checked feedback. Explicit callers may
    /// keep the empty default; `themed` supplies the existing theme channel.
    public let itemInteraction: CjguiComposableUiInteractionStyle

    public init(bar!: CjguiComposableUiStyle = CjguiComposableUiStyle(gap: 8, growX: 1),
        item!: CjguiComposableUiStyle = CjguiComposableUiStyle(fixedHeight: 32, fontSize: 14.0),
        search!: CjguiComposableUiStyle = CjguiComposableUiStyle(fixedHeight: 32, fontSize: 14.0),
        itemInteraction!: CjguiComposableUiInteractionStyle = CjguiComposableUiInteractionStyle()) {
        this.bar = bar
        this.item = item
        this.search = search
        this.itemInteraction = itemInteraction
    }

    /// Derive toolbar paint from the existing immutable theme. No second theme
    /// system: explicit styles passed by a caller still win because `themed` is
    /// only a factory. The base colors stay on the style so an interaction
    /// state that does not declare a field keeps readable text.
    public static func themed(theme: CjguiComposableUiTheme, rowHeight!: Int64 = 32): CjguiCommandToolbarStyle {
        if (rowHeight <= 0) {
            throw IllegalArgumentException("command toolbar row height must be positive")
        }
        let itemInteraction = CjguiComposableUiInteractionStyle(
            hover: theme.inputInteraction.hover,
            pressed: theme.inputInteraction.pressed,
            focused: theme.inputInteraction.focused,
            disabled: theme.inputInteraction.disabled,
            selected: theme.inputInteraction.selected,
            checked: theme.inputInteraction.checked)
        return CjguiCommandToolbarStyle(
            bar: CjguiComposableUiStyle(gap: 8, growX: 1),
            item: CjguiComposableUiStyle(fixedHeight: rowHeight, fontSize: 14.0,
                background: theme.card.background, border: theme.card.border, borderWidth: 1,
                textColor: theme.heading.textColor),
            search: CjguiComposableUiStyle(fixedHeight: rowHeight, fontSize: 14.0,
                background: theme.input.background, border: theme.input.border, borderWidth: 1,
                textColor: theme.heading.textColor),
            itemInteraction: itemInteraction)
    }
}

/// One declaration list plus its presentation metadata. This is a thin value
/// holder for the three existing surfaces: `placement()` feeds the toolbar and
/// palette, `contextMenuProjection(request)` feeds the context menu. It owns no
/// action table, execution path, state or second command authority; the
/// application still supplies the same `CjguiComposableUiCommand` list and its
/// own business actions.
public class CjguiCommandPresentation {
    public let commands: ArrayList<CjguiComposableUiCommand>
    public let metadata: ArrayList<CjguiCommandToolbarMetadata>
    public let searchCommandId: String

    public init(commands: ArrayList<CjguiComposableUiCommand>,
        metadata: ArrayList<CjguiCommandToolbarMetadata>, searchCommandId!: String = "") {
        this.commands = ArrayList<CjguiComposableUiCommand>(commands)
        this.metadata = ArrayList<CjguiCommandToolbarMetadata>(metadata)
        this.searchCommandId = searchCommandId
    }

    public func placement(): CjguiCommandToolbarPlacement {
        return cjguiCommandToolbarPlacement(commands, metadata, searchCommandId: searchCommandId)
    }

    public func paletteItems(): ArrayList<CjguiSearchableSelectionItem> {
        return cjguiCommandPaletteItems(placement())
    }

    public func contextMenuProjection(
        request: CjguiComposableUiContextMenuRequest): CjguiContextCommandMenuProjection {
        return cjguiContextCommandMenuProjection(request, commands, metadata,
            searchCommandId: searchCommandId)
    }
}

/// Compose the toolbar as the existing wrapping flow. Buttons carry the same
/// action name and stable resource the owner already dispatches; disabled items
/// stay visible and wrap instead of truncating in a narrow window. This manual
/// form keeps the legacy numeric node ids; scoped commands use the overload
/// below so their trigger identities come from the component scope.
public func cjguiComposableCommandToolbar(nodeId: Int64, semanticId: String,
    placement: CjguiCommandToolbarPlacement, style!: CjguiCommandToolbarStyle = CjguiCommandToolbarStyle(),
    searchLabel!: String = "搜索命令", searchActionName!: String = "SEARCH_COMMANDS",
    searchResourceId!: Int64 = -1): CjguiComposableUiNode {
    for (item in placement.items) {
        if (item.nodeBase < 0) {
            throw IllegalArgumentException(
                "scoped command needs the scoped toolbar composer: ${item.commandId}")
        }
    }
    // Two buttons cannot own one scene identity. Context/palette projections
    // may share a manual target, but this materialized toolbar may not.
    let slots = HashSet<Int64>()
    for (item in placement.items) {
        if (!slots.add(item.nodeBase)) {
            throw IllegalArgumentException("command toolbar manual slot must be unique")
        }
    }
    if (placement.searchNodeBase >= 0 && !slots.add(placement.searchNodeBase)) {
        throw IllegalArgumentException("command toolbar search slot must be unique")
    }
    if (placement.searchCommandId.size > 0 && placement.searchNodeBase < 0) {
        throw IllegalArgumentException(
            "scoped search needs the scoped toolbar composer: ${placement.searchCommandId}")
    }
    let searchEnabled = match (placement.searchItem) {
        case Some(item) => item.enabled
        case None => true
    }
    // The search button is the command target itself; it keeps the owner
    // action from metadata so invokeCommand cannot re-enter this button.
    let searchAction = match (placement.searchItem) {
        case Some(item) => item.actionName
        case None => searchActionName
    }
    let searchResource = match (placement.searchItem) {
        case Some(item) => item.resourceId
        case None => searchResourceId
    }
    if (placement.searchNodeBase >= 0 && (searchAction.size == 0 || searchResource < 0)) {
        throw IllegalArgumentException("toolbar search needs its action and owning resource")
    }
    if (searchAction.startsWith(CJGUI_COMMAND_TOOLBAR_ACTIVATION_PREFIX)) {
        throw IllegalArgumentException("search button must keep its owner action")
    }
    let bar = cjguiComposableWrap(nodeId, semanticId, style.bar)
    for (item in placement.items) {
        let visibleLabel = cjguiCommandToolbarVisibleLabel(item)
        bar.add(cjguiComposableButton(item.nodeBase, "${semanticId}-${item.key}", visibleLabel, item.actionName,
            item.resourceId, style.item, enabled: item.enabled, operationActionName: item.actionName,
            operationResourceId: item.resourceId,
            interactionStyle: style.itemInteraction,
            ownerInteractionState: if (item.checked) {
                CjguiComposableUiInteractionState.CHECKED
            } else {
                CjguiComposableUiInteractionState.NONE
            },
            semanticRole: if (item.checkable) {
                CJGUI_COMPOSABLE_UI_SEMANTIC_CHECKBOX
            } else {
                CJGUI_COMPOSABLE_UI_SEMANTIC_BUTTON
            }, semanticHelp: item.disabledReason))
    }
    if (placement.searchNodeBase >= 0) {
        bar.add(cjguiComposableButton(placement.searchNodeBase, "${semanticId}-search", searchLabel,
            searchAction, searchResource, style.search, enabled: searchEnabled,
            operationActionName: searchAction, operationResourceId: searchResource,
            interactionStyle: style.itemInteraction))
    }
    return bar
}

/// Scoped command toolbar. Every node identity is allocated from the supplied
/// component scope, so two mounts of one component can declare the same local
/// keys without a caller-reserved numeric range. A trigger's action is the
/// reserved command activation text; the consumer routes that text through
/// `window.invokeCommand`, keeping the declared command and its owner target
/// as the only execution definition.
public func cjguiComposableCommandToolbar(scope: CjguiComposableUiIdentityScope, semanticId: String,
    placement: CjguiCommandToolbarPlacement, style!: CjguiCommandToolbarStyle = CjguiCommandToolbarStyle(),
    searchLabel!: String = "搜索命令", searchActionName!: String = "SEARCH_COMMANDS",
    searchResourceId!: Int64 = -1): CjguiComposableUiNode {
    let searchEnabled = match (placement.searchItem) {
        case Some(item) => item.enabled
        case None => true
    }
    let searchAction = match (placement.searchItem) {
        case Some(item) => item.actionName
        case None => searchActionName
    }
    let searchResource = match (placement.searchItem) {
        case Some(item) => item.resourceId
        case None => searchResourceId
    }
    if (placement.searchCommandId.size > 0 && (searchAction.size == 0 || searchResource < 0)) {
        throw IllegalArgumentException("toolbar search needs its action and owning resource")
    }
    if (searchAction.startsWith(CJGUI_COMMAND_TOOLBAR_ACTIVATION_PREFIX)) {
        throw IllegalArgumentException("search button must keep its owner action")
    }
    let bar = cjguiComposableWrap(-1, semanticId, style.bar, identity: Some(scope.local("bar")))
    for (item in placement.items) {
        let localKey = "item-${item.key}"
        if (localKey.size > 96) {
            throw IllegalArgumentException("scoped toolbar key exceeds 96 characters: ${item.commandId}")
        }
        bar.add(cjguiComposableButton(-1, "${semanticId}-${item.key}", cjguiCommandToolbarVisibleLabel(item),
            cjguiCommandToolbarActivationAction(item.commandId), item.resourceId, style.item,
            enabled: item.enabled,
            interactionStyle: style.itemInteraction,
            ownerInteractionState: if (item.checked) {
                CjguiComposableUiInteractionState.CHECKED
            } else {
                CjguiComposableUiInteractionState.NONE
            },
            semanticRole: if (item.checkable) {
                CJGUI_COMPOSABLE_UI_SEMANTIC_CHECKBOX
            } else {
                CJGUI_COMPOSABLE_UI_SEMANTIC_BUTTON
            }, semanticHelp: item.disabledReason,
            identity: Some(scope.local(localKey))))
    }
    if (placement.searchCommandId.size > 0) {
        bar.add(cjguiComposableButton(-1, "${semanticId}-search", searchLabel, searchAction,
            searchResource, style.search, enabled: searchEnabled, interactionStyle: style.itemInteraction,
            identity: Some(scope.local("search"))))
    }
    return bar
}

private func cjguiCommandToolbarVisibleLabel(item: CjguiCommandToolbarItem): String {
    let label = if (item.shortcut.size > 0) {
        "${item.label}  ${item.shortcut}"
    } else {
        item.label
    }
    return if (item.checked) {
        "✓ ${label}"
    } else {
        label
    }
}

/// Presentation label shared by toolbar, palette and context-menu projections.
/// It is derived only from the already projected item; it owns no state.
public func cjguiCommandItemLabel(item: CjguiCommandToolbarItem): String {
    return cjguiCommandToolbarVisibleLabel(item)
}

/// The palette reads the same projection as the toolbar, so labels, enabled
/// states, shortcut hints and command ids cannot drift.
public func cjguiCommandPaletteItems(placement: CjguiCommandToolbarPlacement): ArrayList<CjguiSearchableSelectionItem> {
    let items = ArrayList<CjguiSearchableSelectionItem>()
    for (item in placement.items) {
        items.add(CjguiSearchableSelectionItem(item.key, item.label, detail: item.detail, shortcut: item.shortcut,
            keywords: "${item.actionName} ${item.commandId}", isEnabled: item.enabled,
            disabledReason: item.disabledReason, checked: item.checked, checkable: item.checkable))
    }
    return items
}

/// Thin owner of the existing searchable panel. It adds command-id lookup and
/// nothing else: filtering, navigation, modal return and focus restoration stay
/// in CjguiSearchableSelectionPanel.
public class CjguiCommandPalette {
    private let panel: CjguiSearchableSelectionPanel
    private var placement = CjguiCommandToolbarPlacement(ArrayList<CjguiCommandToolbarItem>(), searchNodeBase: 0)

    public init(scopeKey: String) {
        this.panel = CjguiSearchableSelectionPanel(scopeKey)
    }

    public func revision(): Int64 {
        return panel.revision()
    }
    public func isOpen(): Bool {
        return panel.isOpen()
    }
    public func resultCount(): Int64 {
        return panel.resultCount()
    }
    public func highlightedKey(): String {
        return panel.highlightedKey()
    }

    public func open(title: String, placement: CjguiCommandToolbarPlacement,
        restoreTarget: CjguiComposableUiNodeReference, hint!: String = ""): Unit {
        this.placement = placement
        panel.open(title, cjguiCommandPaletteItems(placement), restoreTarget, hint: hint)
    }

    /// Re-project the owner declarations while the panel is open. Only checked
    /// / enabled / label state moves; query text and the current navigation key
    /// stay with the panel.
    public func updateItems(placement: CjguiCommandToolbarPlacement): Unit {
        this.placement = placement
        panel.updateItems(cjguiCommandPaletteItems(placement))
    }

    public func commands(): ArrayList<CjguiComposableUiCommand> {
        return panel.commands()
    }

    public func applyUiEvent(event: CjguiComposableUiEvent): ?CjguiComposableUiDispatchResult {
        return panel.applyUiEvent(event)
    }

    public func attachTo(base: CjguiComposableUiNode, currentTheme: CjguiComposableUiTheme): CjguiComposableUiNode {
        return panel.attachTo(base, currentTheme)
    }

    public func takeConfirmed(window: CjguiComposableUiWindow): ?CjguiCommandToolbarItem {
        let confirmed = panel.takeConfirmed(window)
        return match (confirmed) {
            case Some(value) => placement.itemForKey(value.key)
            case None => None
        }
    }

    public func takeConfirmationFailure(): String {
        return panel.takeConfirmationFailure()
    }
}

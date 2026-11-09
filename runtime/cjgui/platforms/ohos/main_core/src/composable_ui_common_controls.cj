// Ordinary-application controls composed from the accepted framework pieces:
// scoped identity, anchored layers, field writers, the shared scroll viewport
// and the existing pointer/keyboard input path. These builders project state;
// they do not own a business value or a second scroll position.
package cjgui

import std.collection.*
import std.convert.*
import std.math.*

public let CJGUI_SELECT_TOGGLE_SUFFIX: String = "-toggle"
public let CJGUI_SELECT_CHOOSE_SUFFIX: String = "-choose:"
public let CJGUI_SELECT_OUTSIDE_SUFFIX: String = "-outside"

/// Shared option validation for every choice presentation of one field. The
/// stable-key rule is the field's own contract, so the dropdown, the radio
/// group and the segmented bar reject the same malformed list at the same
/// place instead of each keeping a private copy.
func cjguiChoiceOptionIssue(items: ArrayList<CjguiSelectOption>, scope: CjguiComposableUiIdentityScope): String {
    if (items.size == 0) { return "" }
    let keys = HashSet<String>()
    let values = HashSet<String>()
    let derived = HashSet<String>()
    for (item in items) {
        if (item.key.size == 0 || item.label.size == 0 || item.value.size == 0) {
            return "select_option_identity_required"
        }
        if (!keys.add(item.key)) { return "select_duplicate_key:${item.key}" }
        if (!values.add(item.value)) { return "select_duplicate_value:${item.value}" }
        let localKey = "option-${cjguiCommonControlKey(item.key)}"
        if (!derived.add(localKey)) { return "select_derived_identity_collision:${item.key}" }
        if (!scope.local(localKey).isValid()) { return "select_identity_unbounded:${item.key}" }
    }
    return ""
}

func cjguiCommonControlHash(value: String): String {
    var hash: Int64 = 2166136261
    for (byte in value.toArray()) {
        hash = (hash ^ Int64(byte)) * 16777619
        hash = hash & 0xFFFFFFFF
    }
    if (hash == 0) { return "0" }
    let digits = "0123456789abcdef"
    var current = hash
    var result = ""
    while (current > 0) {
        let digit = current % 16
        result = String.fromUtf8([digits.toArray()[digit]]) + result
        current = current / 16
    }
    return result
}

/// Bounded, collision-resistant local identity for a stable business key.
/// The readable prefix is capped; a hash over the WHOLE key distinguishes
/// `.` from `_46` and long keys that share a prefix. The raw key remains the
/// business identity used for confirmation and owner writes.
func cjguiCommonControlKey(value: String): String {
    if (value.size == 0) { return "empty-0" }
    var safe = ""
    for (byte in value.toArray()) {
        if (safe.size >= 40) { break }
        let letter = (byte >= b'a' && byte <= b'z') || (byte >= b'A' && byte <= b'Z')
        let digit = byte >= b'0' && byte <= b'9'
        if (letter || digit || byte == b'_' || byte == b'-') {
            safe += String.fromUtf8([byte])
        } else {
            safe += "_"
        }
    }
    if (safe.size == 0) { safe = "k" }
    return "${safe}-${cjguiCommonControlHash(value)}"
}

/// One stable identity in a Select. Display order and row index are never
/// consulted on confirmation; only `key` and `value` are.
public class CjguiSelectOption {
    public let key: String
    public let label: String
    public let value: String
    public let enabled: Bool
    public let disabledReason: String

    public init(key: String, label: String, value: String, enabled!: Bool = true, disabledReason!: String = "") {
        this.key = key
        this.label = label
        this.value = value
        this.enabled = enabled
        this.disabledReason = disabledReason
    }

    func sameAs(other: CjguiSelectOption): Bool {
        return key == other.key && label == other.label && value == other.value &&
            enabled == other.enabled && disabledReason == other.disabledReason
    }
}

public class CjguiSelectStyle {
    public let trigger: CjguiComposableUiStyle
    public let layer: CjguiComposableUiStyle
    public let row: CjguiComposableUiStyle
    public let rowInteraction: CjguiComposableUiInteractionStyle
    public let empty: CjguiComposableUiStyle
    public let unmatched: CjguiComposableUiStyle
    public let maxHeight: Int64
    public let layerWidth: Int64

    public init(trigger!: CjguiComposableUiStyle = CjguiComposableUiStyle(fixedHeight: 32, padding: 6,
            background: CjguiComposableUiColor(0.96, 0.97, 0.99, 1.0),
            border: CjguiComposableUiColor(0.72, 0.76, 0.84, 1.0), borderWidth: 1, cornerRadius: 4),
        layer!: CjguiComposableUiStyle = CjguiComposableUiStyle(padding: 4, gap: 2,
            background: CjguiComposableUiColor(1.0, 1.0, 1.0, 1.0),
            border: CjguiComposableUiColor(0.66, 0.70, 0.78, 1.0), borderWidth: 1, cornerRadius: 5),
        row!: CjguiComposableUiStyle = CjguiComposableUiStyle(fixedHeight: 28, growX: 1, padding: 4,
            cornerRadius: 3),
        rowInteraction!: CjguiComposableUiInteractionStyle = CjguiComposableUiInteractionStyle(
            hover: CjguiComposableUiPaintStyle(background: Some(CjguiComposableUiColor(0.92, 0.95, 1.0, 1.0))),
            pressed: CjguiComposableUiPaintStyle(background: Some(CjguiComposableUiColor(0.84, 0.90, 1.0, 1.0))),
            focused: CjguiComposableUiPaintStyle(background: Some(CjguiComposableUiColor(0.88, 0.93, 1.0, 1.0)),
                border: Some(CjguiComposableUiColor(0.22, 0.52, 0.95, 1.0)), borderWidth: Some(1)),
            selected: CjguiComposableUiPaintStyle(background: Some(CjguiComposableUiColor(0.86, 0.92, 1.0, 1.0))),
            disabled: CjguiComposableUiPaintStyle(textColor: Some(CjguiComposableUiColor(0.55, 0.58, 0.64, 1.0)))),
        empty!: CjguiComposableUiStyle = CjguiComposableUiStyle(fixedHeight: 26, growX: 1,
            textColor: CjguiComposableUiColor(0.45, 0.48, 0.54, 1.0)),
        unmatched!: CjguiComposableUiStyle = CjguiComposableUiStyle(fixedHeight: 18, fontSize: 10.5,
            textColor: CjguiComposableUiColor(0.55, 0.36, 0.20, 1.0)),
        maxHeight!: Int64 = 240, layerWidth!: Int64 = 240) {
        this.trigger = trigger
        this.layer = layer
        this.row = row
        this.rowInteraction = rowInteraction
        this.empty = empty
        this.unmatched = unmatched
        this.maxHeight = if (maxHeight > 0) { maxHeight } else { 240 }
        this.layerWidth = if (layerWidth > 0) { layerWidth } else { 240 }
    }

    public static func fromTheme(theme: CjguiComposableUiTheme): CjguiSelectStyle {
        return CjguiSelectStyle(
            trigger: CjguiComposableUiStyle(fixedHeight: 32, padding: 6, background: theme.input.background,
                border: theme.input.border, borderWidth: 1, cornerRadius: 4, textColor: theme.input.textColor),
            layer: CjguiComposableUiStyle(padding: 4, gap: 2, background: theme.card.background,
                border: theme.card.border, borderWidth: 1, cornerRadius: 5),
            row: CjguiComposableUiStyle(fixedHeight: 28, growX: 1, padding: 4, cornerRadius: 3,
                textColor: theme.body.textColor))
    }
}

/// Stable-key dropdown over existing field writers. The controller owns only
/// open/highlight presentation; confirming returns the stable key so the
/// application invokes the same field transaction it already uses.
public class CjguiSelect {
    private let scope: CjguiComposableUiIdentityScope
    private let prefix: String
    private let layerId: String
    private let ownerSemanticId: String
    private var options = ArrayList<CjguiSelectOption>()
    private var currentValueValue: String = ""
    private var enabledValue: Bool = true
    private var readOnlyValue: Bool = false
    private var openValue: Bool = false
    private var revisionValue: Int64 = 0
    private var highlightedKeyValue: String = ""
    private var pendingValue: ?CjguiSelectOption = None
    private var anchorValue: ?CjguiComposableUiNodeReference = None
    private var styleValue: CjguiSelectStyle = CjguiSelectStyle()
    private var themeValue: CjguiComposableUiTheme = CjguiComposableUiTheme.beaconDark()
    private var placeholderValue: String = "请选择"
    private var emptyTextValue: String = "没有可选项"
    private var searchableValue: Bool = false
    private var queryValue: String = ""
    private var viewportValue: ?CjguiComposableUiScrollViewport = None
    private var errorValue: String = ""
    /// Reference of the trigger the LAST `trigger()` build produced. The open
    /// position and the post-close focus return belong to the presentation
    /// instance that is actually on screen; a generated-only mount never had
    /// the handwritten scoped trigger.
    private var presentationAnchorValue: ?CjguiComposableUiNodeReference = None
    /// Reveal is requested only by open, keyboard navigation and a repaired
    /// highlight. An ordinary owner refresh while the user scrolled away must
    /// keep the accepted viewport offset.
    private var revealArmedValue: Bool = false

    public init(scopeKey: String, semanticId: String) {
        this.scope = CjguiComposableUiIdentityScope(scopeKey)
        this.prefix = semanticId
        this.layerId = "cjgui-select-${scopeKey}"
        this.ownerSemanticId = "${semanticId}-owner"
    }

    public func scopeKey(): CjguiComposableUiIdentityScope { return scope }
    public func revision(): Int64 { return revisionValue }
    public func isOpen(): Bool { return openValue }
    public func highlightedKey(): String { return highlightedKeyValue }
    public func currentValue(): String { return currentValueValue }
    public func isEnabled(): Bool { return enabledValue && !readOnlyValue }
    public func layer(): String { return layerId }
    public func isSearchable(): Bool { return searchableValue }
    public func query(): String { return queryValue }

    public func optionIssue(items: ArrayList<CjguiSelectOption>): String {
        return cjguiChoiceOptionIssue(items, scope)
    }

    private func rowLocalKey(key: String): String {
        return "option-${cjguiCommonControlKey(key)}"
    }

    /// Scoped local key of the highlighted row (or "cancel"). Keyboard
    /// navigation uses it to keep native focus on the row that the highlight
    /// just moved to.
    public func highlightedLocalKey(): String {
        if (!openValue) { return "" }
        if (highlightedKeyValue.size == 0) { return "cancel" }
        return rowLocalKey(highlightedKeyValue)
    }

    /// Re-declare options while open or closed. The previous row index is never
    /// reused: a removed or disabled highlighted option is repaired by key.
    /// An open searchable query is preserved; it only narrows the projection.
    /// `error` is the owner's CURRENT validation fact for this field; it is
    /// presentation input, never written back by the control.
    public func update(items: ArrayList<CjguiSelectOption>, currentValue: String, enabled!: Bool = true,
        readOnly!: Bool = false, placeholder!: String = "请选择", emptyText!: String = "没有可选项",
        style!: ?CjguiSelectStyle = None, theme!: ?CjguiComposableUiTheme = None,
        searchable!: Bool = false, error!: String = ""): Unit {
        let issue = optionIssue(items)
        if (issue.size > 0) { throw IllegalArgumentException(issue) }
        var changed = items.size != options.size || currentValue != currentValueValue ||
            enabled != enabledValue || readOnly != readOnlyValue || searchable != searchableValue ||
            error != errorValue
        var index = 0
        while (!changed && index < items.size) {
            if (!options[index].sameAs(items[index])) { changed = true }
            index += 1
        }
        options = ArrayList<CjguiSelectOption>(items)
        currentValueValue = currentValue
        enabledValue = enabled
        readOnlyValue = readOnly
        placeholderValue = placeholder
        emptyTextValue = emptyText
        searchableValue = searchable
        errorValue = error
        if (let Some(value) <- style) { styleValue = value }
        if (let Some(value) <- theme) { themeValue = value }
        if (!searchableValue) { queryValue = "" }
        if (repairHighlight()) { revealArmedValue = true }
        if (changed) { revisionValue += 1 }
    }

    private func optionForKey(key: String): ?CjguiSelectOption {
        for (item in options) { if (item.key == key) { return Some(item) } }
        return None
    }

    private func keyForValue(value: String): String {
        if (value.size == 0) { return "" }
        for (item in options) { if (item.value == value) { return item.key } }
        return ""
    }

    private func matchesQuery(item: CjguiSelectOption): Bool {
        if (!searchableValue || queryValue.size == 0) { return true }
        let needle = queryValue.toAsciiLower()
        return item.label.toAsciiLower().contains(needle) || item.key.toAsciiLower().contains(needle) ||
            item.value.toAsciiLower().contains(needle)
    }

    /// Current projection in declaration order. Filtering never renames an
    /// option and never turns a visible row index into an action.
    public func visibleOptions(): ArrayList<CjguiSelectOption> {
        let result = ArrayList<CjguiSelectOption>()
        for (item in options) { if (matchesQuery(item)) { result.add(item) } }
        return result
    }

    private func firstEnabledVisibleKey(): String {
        for (item in visibleOptions()) { if (item.enabled) { return item.key } }
        return ""
    }

    private func firstEnabledKey(): String {
        for (item in options) { if (item.enabled) { return item.key } }
        return ""
    }

    /// Repair an unusable highlight (removed, disabled or hidden by the query)
    /// to the first enabled visible option. Returns whether the key moved; a
    /// move is the ONLY refresh-sourced reason to request a reveal.
    private func repairHighlight(): Bool {
        if (highlightedKeyValue.size > 0) {
            let current = optionForKey(highlightedKeyValue)
            if (let Some(item) <- current) {
                if (item.enabled && matchesQuery(item)) { return false }
            }
        }
        let repaired = firstEnabledVisibleKey()
        if (repaired == highlightedKeyValue) { return false }
        highlightedKeyValue = repaired
        return true
    }

    public func selectedLabel(): String {
        let key = keyForValue(currentValueValue)
        if (key.size == 0) {
            return if (currentValueValue.size > 0) { "未匹配：${currentValueValue}" } else { placeholderValue }
        }
        return match (optionForKey(key)) { case Some(item) => item.label; case None => placeholderValue }
    }

    private func reference(localKey: String): CjguiComposableUiNodeReference {
        return CjguiComposableUiNodeReference.scoped(scope, localKey)
    }

    private func anchorReference(): CjguiComposableUiNodeReference {
        return reference("trigger")
    }

    public func triggerReference(): CjguiComposableUiNodeReference {
        return anchorReference()
    }

    /// Whether this build of `root` actually presents this select. A window can
    /// mount one shared select controller through more than one region; a region
    /// whose accepted scene has no trigger for it must not attach a second popup
    /// host, or the window scene rejects the duplicate scope identity.
    public func presentedIn(root: CjguiComposableUiNode): Bool {
        let toggle = "${prefix}${CJGUI_SELECT_TOGGLE_SUFFIX}"
        if (root.actionName == toggle) { return true }
        for (child in root.children()) {
            if (presentedIn(child)) { return true }
        }
        return false
    }

    /// The trigger is an ordinary button; activation opens/ closes the popup.
    /// A generated factory passes its allocated node id/semantic id so the
    /// accepted scene refresh and the component keep ONE trigger identity.
    public func trigger(nodeId!: Int64 = -1, semanticId!: String = ""): CjguiComposableUiNode {
        let label = selectedLabel() + "  ▾"
        let id = if (semanticId.size > 0) { semanticId } else { "${prefix}-trigger" }
        // A generated factory already allocated this node's identity. Reusing
        // the handwritten select scope there would collide with the manual
        // trigger when both presentations are in one window.
        let identity: ?CjguiComposableUiIdentity = if (semanticId.size > 0) {
            None
        } else {
            Some(scope.local("trigger"))
        }
        // The presentation that is on screen owns the open position and the
        // focus return: remember the reference THIS build produced. Only a
        // REAL allocated node id is a manual reference; a scoped registry id
        // keeps the scoped trigger anchor. A real activation still carries its
        // own node, which wins over this default.
        presentationAnchorValue = if (nodeId >= 0 && nodeId < CJGUI_COMPOSABLE_UI_FIRST_SCOPED_NODE_ID) {
            Some(CjguiComposableUiNodeReference.manual(nodeId))
        } else {
            Some(anchorReference())
        }
        let trigger = cjguiComposableButton(nodeId, id, label,
            "${prefix}${CJGUI_SELECT_TOGGLE_SUFFIX}", 0, styleValue.trigger,
            enabled: isEnabled(), identity: identity)
        trigger.semanticRole = CJGUI_COMPOSABLE_UI_SEMANTIC_BUTTON
        trigger.semanticLabel = "${prefix}：${selectedLabel()}"
        trigger.semanticExpandable = true
        trigger.semanticExpanded = openValue
        if (errorValue.size > 0) { trigger.semanticHelp = errorValue }
        return trigger
    }

    public func open(restoreTarget!: ?CjguiComposableUiNodeReference = None): Bool {
        if (!isEnabled()) { return false }
        // The anchor is the presentation instance that actually activated (or,
        // for a programmatic open, the last trigger this controller built).
        // The handwritten scoped trigger is only the compatibility fallback.
        anchorValue = if (let Some(value) <- restoreTarget) {
            Some(value)
        } else if (let Some(value) <- presentationAnchorValue) {
            Some(value)
        } else {
            Some(anchorReference())
        }
        openValue = true
        queryValue = ""
        revealArmedValue = true
        let selected = keyForValue(currentValueValue)
        if (let Some(item) <- optionForKey(selected)) {
            highlightedKeyValue = if (item.enabled) { item.key } else { firstEnabledVisibleKey() }
        } else {
            highlightedKeyValue = firstEnabledVisibleKey()
        }
        revisionValue += 1
        return true
    }

    public func close(): Unit {
        if (!openValue) { return }
        openValue = false
        pendingValue = None
        queryValue = ""
        revisionValue += 1
    }

    public func toggle(): Bool {
        if (openValue) {
            close()
        } else {
            let _ = open()
        }
        return true
    }

    /// Presentation-only query. It filters the popup projection and cannot
    /// produce a value; confirmation still names a declared option key.
    public func setQuery(value: String): Unit {
        if (!openValue || !searchableValue || queryValue == value) { return }
        queryValue = value
        if (repairHighlight()) { revealArmedValue = true }
        revisionValue += 1
    }

    public func moveHighlight(direction: String): Bool {
        if (!openValue) { return false }
        let visible = visibleOptions()
        if (visible.size == 0) { return false }
        var enabled = ArrayList<CjguiSelectOption>()
        for (item in visible) { if (item.enabled) { enabled.add(item) } }
        if (enabled.size == 0) { return false }
        var index = -1
        var cursor = 0
        for (item in enabled) {
            if (item.key == highlightedKeyValue) { index = cursor }
            cursor += 1
        }
        if (direction == "up") {
            index = if (index <= 0) { enabled.size - 1 } else { index - 1 }
        } else if (direction == "down") {
            index = if (index < 0 || index + 1 >= enabled.size) { 0 } else { index + 1 }
        } else { return false }
        highlightedKeyValue = enabled[index].key
        revealArmedValue = true
        revisionValue += 1
        return true
    }

    /// Confirm by stable key. The caller then invokes its existing field
    /// writer with `pending.value()`; no select-specific owner is created.
    /// A disabled/read-only select, a removed row and a row hidden by the
    /// current query all fail without producing a pending write.
    public func confirmHighlighted(): Bool {
        if (!openValue || !isEnabled() || highlightedKeyValue.size == 0) { return false }
        if (!matchesQueryKey(highlightedKeyValue)) { return false }
        let item = optionForKey(highlightedKeyValue)
        if (let Some(option) <- item) {
            if (!option.enabled) { return false }
            pendingValue = Some(CjguiSelectOption(option.key, option.label, option.value,
                enabled: option.enabled, disabledReason: option.disabledReason))
            openValue = false
            queryValue = ""
            revisionValue += 1
            return true
        }
        return false
    }

    private func matchesQueryKey(key: String): Bool {
        if (!searchableValue || queryValue.size == 0) { return true }
        if (let Some(item) <- optionForKey(key)) { return matchesQuery(item) }
        return false
    }

    public func takeConfirmed(): ?CjguiSelectOption {
        let result = pendingValue
        pendingValue = None
        return result
    }

    public func confirmKey(key: String): Bool {
        if (!openValue || !isEnabled()) { return false }
        if (!matchesQueryKey(key)) { return false }
        let item = optionForKey(key)
        if (let Some(option) <- item) {
            if (!option.enabled) { return false }
            highlightedKeyValue = key
            return confirmHighlighted()
        }
        return false
    }

    private func commandTargetLocalKey(): String {
        let visible = visibleOptions()
        for (item in visible) {
            if (item.key == highlightedKeyValue && item.enabled) { return rowLocalKey(item.key) }
        }
        for (item in visible) {
            if (item.enabled) { return rowLocalKey(item.key) }
        }
        return "cancel"
    }

    public func commands(): ArrayList<CjguiComposableUiCommand> {
        let result = ArrayList<CjguiComposableUiCommand>()
        if (!openValue) { return result }
        let target = reference(commandTargetLocalKey())
        let hasRow = commandTargetLocalKey() != "cancel"
        if (hasRow) {
            for (key in ["up", "down", "enter"]) {
                result.add(CjguiComposableUiCommand("${layerId}-${key}", target, key,
                    CjguiComposableUiShortcut(key, usesCommand: false), "", 0, true, false, focusScopeId: layerId))
            }
        }
        result.add(CjguiComposableUiCommand("${layerId}-escape", target, "escape",
            CjguiComposableUiShortcut("escape", usesCommand: false), "", 0, true, false, focusScopeId: layerId))
        return result
    }

    /// Consume trigger, row, search, guard and keyboard intents. Other
    /// application events return None so the owner's ordinary dispatch
    /// continues unchanged. Once a surface belongs to this select, a rejected
    /// intent is consumed rather than leaking to a covered control.
    /// A declared shortcut reaches the component as the activation of its
    /// target plus the shortcut text. Up/Down/Enter share the highlighted row
    /// as target, so the text is what distinguishes them from a row click.
    private func keyboardIntent(text: String): String {
        let commandPrefix = "${layerId}-"
        let key = if (text.startsWith(commandPrefix)) {
            text[commandPrefix.size..]
        } else if (text.startsWith("shortcut:")) {
            text["shortcut:".size..]
        } else {
            ""
        }
        if (key == "up" || key == "down" || key == "enter" || key == "escape") { return key }
        return ""
    }

    public func applyUiEvent(event: CjguiComposableUiEvent): ?CjguiComposableUiDispatchResult {
        let action = event.node.actionName
        let outsideAction = "${prefix}${CJGUI_SELECT_OUTSIDE_SUFFIX}"
        let pointerOutside = (event.eventKind == CJGUI_COMPOSABLE_UI_EVENT_POINTER_BEGIN ||
            event.eventKind == CJGUI_COMPOSABLE_UI_EVENT_PRESS_BEGIN) && event.node.inputScopeId != layerId
        if (openValue && (pointerOutside ||
            ((event.eventKind == CJGUI_COMPOSABLE_UI_EVENT_POINTER_BEGIN ||
                event.eventKind == CJGUI_COMPOSABLE_UI_EVENT_PRESS_BEGIN ||
                event.eventKind == CJGUI_COMPOSABLE_UI_EVENT_ACTIVATE) &&
                (action == outsideAction || event.node.semanticId.startsWith("${prefix}${CJGUI_SELECT_OUTSIDE_SUFFIX}"))))) {
            close()
            return Some(CjguiComposableUiDispatchResult(true))
        }
        if (event.eventKind == CJGUI_COMPOSABLE_UI_EVENT_TEXT_CHANGED && openValue && searchableValue &&
            event.node.semanticId == "${prefix}-search") {
            setQuery(event.text)
            return Some(CjguiComposableUiDispatchResult(true))
        }
        if (event.eventKind == CJGUI_COMPOSABLE_UI_EVENT_ACTIVATE) {
            if (openValue && event.node.inputScopeId == layerId) {
                let intent = keyboardIntent(event.text)
                if (intent.size > 0) {
                    // Escape always remains a legal way out. Navigation and
                    // confirmation belong to an enabled select only; a stale
                    // shortcut delivered after the owner turned it read-only or
                    // disabled must not write.
                    if (intent == "escape") {
                        close()
                        return Some(CjguiComposableUiDispatchResult(true))
                    }
                    if (!isEnabled() || !openValue) {
                        return Some(CjguiComposableUiDispatchResult(false))
                    }
                    if (intent == "up" || intent == "down") {
                        return Some(CjguiComposableUiDispatchResult(moveHighlight(intent)))
                    }
                    return Some(CjguiComposableUiDispatchResult(confirmHighlighted()))
                }
                if (action == "${prefix}-cancel") {
                    close()
                    return Some(CjguiComposableUiDispatchResult(true))
                }
            }
            if (action == "${prefix}${CJGUI_SELECT_TOGGLE_SUFFIX}") {
                // The activated presentation instance owns the popup position
                // and the focus return. A generated node names itself by its
                // REAL allocated node id; a scoped handwritten trigger carries
                // a virtual registry id, which is not a manual reference - it
                // keeps the scoped trigger anchor.
                let activatedAnchor = if (event.node.nodeId >= 0 &&
                    event.node.nodeId < CJGUI_COMPOSABLE_UI_FIRST_SCOPED_NODE_ID) {
                    CjguiComposableUiNodeReference.manual(event.node.nodeId)
                } else {
                    anchorReference()
                }
                if (openValue) {
                    close()
                } else {
                    let _ = open(restoreTarget: activatedAnchor)
                }
                return Some(CjguiComposableUiDispatchResult(true))
            }
            let helperPrefix = "${prefix}${CJGUI_SELECT_CHOOSE_SUFFIX}"
            if (action.startsWith(helperPrefix)) {
                if (!openValue) {
                    return Some(CjguiComposableUiDispatchResult(false))
                }
                let key = action[helperPrefix.size..]
                return Some(CjguiComposableUiDispatchResult(confirmKey(key)))
            }
            return None
        }
        if ((event.eventKind == 35 || event.eventKind == 36) && event.text == "escape" && openValue) {
            close()
            return Some(CjguiComposableUiDispatchResult(true))
        }
        if (event.eventKind == 35 && openValue) {
            if (event.text == "up" || event.text == "down") {
                let _ = moveHighlight(event.text)
                return Some(CjguiComposableUiDispatchResult(true))
            }
            if (event.text == "enter") {
                let _ = confirmHighlighted()
                return Some(CjguiComposableUiDispatchResult(true))
            }
        }
        return None
    }

    private func rowHeight(): Int64 {
        return if (styleValue.row.fixedHeight > 0) { styleValue.row.fixedHeight } else { 28 }
    }

    /// Owner paint bits survive only SELECTED/CHECKED; HOVER belongs to the
    /// pointer. A keyboard highlight therefore travels as the selected paint,
    /// while an accepted row keeps the ordinary selected paint.
    private func rowInteractionStyle(highlighted: Bool): CjguiComposableUiInteractionStyle {
        let base = styleValue.rowInteraction
        let selectedPaint = if (highlighted) { base.hover } else { base.selected }
        return CjguiComposableUiInteractionStyle(normal: base.normal, hover: base.hover, pressed: base.pressed,
            focused: base.focused, disabled: base.disabled, selected: selectedPaint, checked: base.checked)
    }

    private func revealHighlighted(viewport: CjguiComposableUiScrollViewport): Unit {
        let visible = visibleOptions()
        if (visible.size == 0) { return }
        var index: Int64 = -1
        var cursor: Int64 = 0
        for (item in visible) {
            if (item.key == highlightedKeyValue) { index = cursor }
            cursor += 1
        }
        if (index < 0) { return }
        let height = rowHeight()
        let start = index * (height + styleValue.layer.gap)
        let _ = viewport.reveal(start, start + height, margin: styleValue.layer.gap)
    }

    /// Verification probe: the viewport the popup shares with the accepted
    /// scroll area, so a test can observe reveal gating without a window.
    func revealViewportProbe(): ?CjguiComposableUiScrollViewport {
        return viewportValue
    }

    private func initialFocusLocalKey(): String {
        // The highlighted row is the legal in-layer focus target. The search
        // field is reached by Tab/click; auto-focusing it would let the text
        // editor consume the arrow/Enter chords the component declares.
        let visible = visibleOptions()
        for (item in visible) {
            if (item.key == highlightedKeyValue && item.enabled) { return rowLocalKey(item.key) }
        }
        for (item in visible) {
            if (item.enabled) { return rowLocalKey(item.key) }
        }
        return "cancel"
    }

    /// Wrap the accepted base scene with the popup layers while open. The
    /// outside guard is a backdrop: the framework keeps it above every
    /// smaller base control for hit testing, so a click anywhere outside the
    /// popup is delivered as an ordinary dismissal intent. Focus starts INSIDE
    /// the popup (the highlighted row, or the cancel row) instead of the
    /// covered trigger.
    private func hasAttachedHost(node: CjguiComposableUiNode): Bool {
        let hostKey = scope.local("host").canonicalKey()
        if (let Some(identity) <- node.scopedIdentity()) {
            if (identity.canonicalKey() == hostKey) { return true }
        }
        for (child in node.children()) {
            if (hasAttachedHost(child)) { return true }
        }
        return false
    }

    public func attachTo(base: CjguiComposableUiNode): CjguiComposableUiNode {
        if (!openValue) { return base }
        // One controller can be presented by more than one mounted field (for
        // example a handwritten trigger plus a generated select). The generated
        // region already attaches this popup to its scene; wrapping the whole
        // window again would declare the same host identity twice and the scene
        // would be rejected. Keep the one popup that is already present.
        if (hasAttachedHost(base)) { return base }
        themeValue = themeValue
        let anchor = match (anchorValue) { case Some(value) => value; case None => anchorReference() }
        let host = CjguiComposableUiNode(-1, "${prefix}-host", CJGUI_COMPOSABLE_UI_LAYER_HOST, "", "", "", -1,
            CjguiComposableUiStyle(growX: 1, growY: 1), identity: Some(scope.local("host")))
        host.add(base)
        let guard = CjguiComposableUiNode(-1, "${prefix}${CJGUI_SELECT_OUTSIDE_SUFFIX}-guard",
            CJGUI_COMPOSABLE_UI_LAYER_BACKDROP, "", "", "${prefix}${CJGUI_SELECT_OUTSIDE_SUFFIX}", 0,
            CjguiComposableUiStyle(fixedWidth: 100000, fixedHeight: 100000,
                background: CjguiComposableUiColor(0.0, 0.0, 0.0, 0.0)),
            identity: Some(scope.local("outside")))
        let guardLayer = CjguiComposableUiNode(-1, "${prefix}-outside-layer", CJGUI_COMPOSABLE_UI_VERTICAL,
            "", "", "", -1, CjguiComposableUiStyle(fixedWidth: 100000, fixedHeight: 100000),
            layerId: "${layerId}-outside", layerKind: "popup", layerOwnerSemanticId: ownerSemanticId,
            layerAnchorAtPoint: true, layerAnchorPointX: 0, layerAnchorPointY: 0,
            identity: Some(scope.local("outside-layer")))
        guardLayer.add(guard)
        host.add(guardLayer)
        let visible = visibleOptions()
        let focusKey = initialFocusLocalKey()
        let layer = CjguiComposableUiNode(-1, "${prefix}-popup", CJGUI_COMPOSABLE_UI_VERTICAL,
            "", "", "", -1, CjguiComposableUiStyle(fixedWidth: styleValue.layerWidth, padding: styleValue.layer.padding,
                gap: styleValue.layer.gap, background: styleValue.layer.background,
                border: styleValue.layer.border, borderWidth: styleValue.layer.borderWidth,
                cornerRadius: styleValue.layer.cornerRadius),
            layerId: layerId, layerKind: "popup", layerOwnerSemanticId: ownerSemanticId,
            layerAnchorSemanticId: ownerSemanticId, layerAnchorReference: Some(anchor),
            layerInitialFocusReference: Some(reference(focusKey)),
            identity: Some(scope.local("popup")))
        if (searchableValue) {
            let searchStyle = CjguiComposableUiStyle(fixedHeight: 30, padding: 4, cornerRadius: 3,
                background: themeValue.input.background, border: themeValue.input.border, borderWidth: 1,
                textColor: themeValue.input.textColor)
            layer.add(CjguiComposableUiNode(-1, "${prefix}-search", CJGUI_COMPOSABLE_UI_TEXT_INPUT, "搜索选项",
                queryValue, "EDIT_TEXT", 0, searchStyle, identity: Some(scope.local("search"))))
        }
        if (visible.size == 0) {
            let noMatch = searchableValue && queryValue.size > 0
            layer.add(cjguiComposableText(-1, "${prefix}-empty",
                if (noMatch) { "没有匹配：${queryValue}" } else { emptyTextValue },
                if (noMatch) { styleValue.unmatched } else { styleValue.empty },
                identity: Some(scope.local("empty"))))
        } else {
            let viewport = match (viewportValue) {
                case Some(value) => value
                case None =>
                    let created = CjguiComposableUiScrollViewport()
                    viewportValue = Some(created)
                    created
            }
            // Reveal only for open, keyboard navigation or a repaired
            // highlight. A plain refresh keeps the offset the user scrolled
            // to; the viewport request is not re-armed by rebuilding.
            if (revealArmedValue) {
                revealHighlighted(viewport)
                revealArmedValue = false
            }
            let height = rowHeight()
            var natural: Int64 = 0
            for (item in visible) { natural += height + styleValue.layer.gap }
            let scrollHeight = if (natural > styleValue.maxHeight) { styleValue.maxHeight } else { natural }
            let scroll = CjguiComposableUiNode(-1, "${prefix}-scroll", CJGUI_COMPOSABLE_UI_SCROLL_AREA,
                "", "", "", -1, CjguiComposableUiStyle(fixedWidth: styleValue.layerWidth, fixedHeight: scrollHeight),
                scrollOffset: viewport.offset(), scrollViewport: Some(viewport),
                identity: Some(scope.local("scroll")))
            let list = CjguiComposableUiNode(-1, "${prefix}-options", CJGUI_COMPOSABLE_UI_VERTICAL,
                "", "", "", -1, CjguiComposableUiStyle(fixedWidth: styleValue.layerWidth, gap: styleValue.layer.gap),
                identity: Some(scope.local("options")))
            for (item in visible) {
                let localKey = rowLocalKey(item.key)
                let selected = item.value == currentValueValue
                let highlighted = item.key == highlightedKeyValue
                let label = if (selected) { "✓ ${item.label}" } else { item.label }
                let row = cjguiComposableButton(-1, "${prefix}-${localKey}", label,
                    "${prefix}${CJGUI_SELECT_CHOOSE_SUFFIX}${item.key}", 0, styleValue.row,
                    enabled: item.enabled && enabledValue && !readOnlyValue,
                    interactionStyle: rowInteractionStyle(highlighted),
                    ownerInteractionState: if (highlighted) {
                        CjguiComposableUiInteractionState.SELECTED
                    } else {
                        CjguiComposableUiInteractionState.NONE
                    },
                    identity: Some(scope.local(localKey)))
                row.semanticLabel = item.label
                row.semanticHelp = item.disabledReason
                row.semanticSelected = selected
                list.add(row)
            }
            scroll.add(list)
            layer.add(scroll)
        }
        let cancel = cjguiComposableButton(-1, "${prefix}-cancel", "取消 Esc", "${prefix}-cancel", 0,
            CjguiComposableUiStyle(fixedHeight: 24, padding: 4, cornerRadius: 3,
                textColor: themeValue.body.textColor),
            identity: Some(scope.local("cancel")))
        cancel.semanticLabel = "取消选择"
        layer.add(cancel)
        host.add(layer)
        return host
    }
}

/// ONE declared option source for a field, shared by every choice
/// presentation (Select, RadioGroup, Segmented). The controller owns
/// presentation only; the caller's commit closure is the same owner
/// transaction all presentations use.
public class CjguiSelectFieldBinding {
    public let fieldId: String
    public let select: CjguiSelect
    private let optionsValue: ArrayList<CjguiSelectOption>
    private let commitOperation: (CjguiSelectOption) -> Bool
    private let searchableValue: Bool
    private var lastFailureValue: String = ""
    // The last declared field facts. ONE projection feeds every presentation
    // of this field so a frame can never mix value from one owner version with
    // availability from another.
    private var declaredValue: String = ""
    private var declaredInitialized: Bool = false
    private var declaredEnabled: Bool = true
    private var declaredReadOnly: Bool = false
    private var declaredPlaceholder: String = "请选择"
    private var declaredError: String = ""
    private var declaredStyle: ?CjguiSelectStyle = None
    private var declaredTheme: ?CjguiComposableUiTheme = None
    /// The constructor's declaration is only the fallback. A presentation that
    /// names the property owns the CURRENT value, including an explicit false
    /// that withdraws an earlier true; a presentation that omits it (None) must
    /// not reset what another presentation of the same field just declared.
    private var explicitSearchable: ?Bool = None
    /// Semantic ids of the always-visible choice presentations built for this
    /// field; event routing matches their stable-key action family.
    private let choicePresentationPrefixes: ArrayList<String>
    private var choicePendingValue: ?CjguiSelectOption = None

    public init(fieldId: String, scopeKey: String, semanticId: String,
        options: ArrayList<CjguiSelectOption>, commit!: (CjguiSelectOption) -> Bool, searchable!: Bool = false) {
        this.fieldId = fieldId
        this.select = CjguiSelect(scopeKey, semanticId)
        this.optionsValue = ArrayList<CjguiSelectOption>(options)
        this.commitOperation = commit
        this.searchableValue = searchable
        this.choicePresentationPrefixes = ArrayList<String>()
        let issue = this.select.optionIssue(options)
        if (issue.size > 0) { throw IllegalArgumentException(issue) }
    }

    public func options(): ArrayList<CjguiSelectOption> {
        return ArrayList<CjguiSelectOption>(optionsValue)
    }

    public func isSearchable(): Bool {
        return match (explicitSearchable) {
            case Some(value) => value
            case None => searchableValue
        }
    }

    public func currentValue(): String { return declaredValue }
    public func fieldEnabled(): Bool { return declaredEnabled && !declaredReadOnly }
    public func fieldReadOnly(): Bool { return declaredReadOnly }
    public func fieldError(): String { return declaredError }

    /// Replace the option list of a LIVE field (dynamic options). The same
    /// bounded-identity rule as construction applies; a refusal leaves the
    /// previous options and the current business value untouched. A current
    /// value that no longer matches an option stays exactly as the owner
    /// holds it - presentations explain it, they never rewrite it.
    public func updateOptions(items: ArrayList<CjguiSelectOption>): String {
        let issue = select.optionIssue(items)
        if (issue.size > 0) { return issue }
        optionsValue.clear()
        for (item in items) { optionsValue.add(item) }
        if (declaredInitialized) {
            pushDeclaredFacts()
        }
        return ""
    }

    private func pushDeclaredFacts(): Unit {
        select.update(optionsValue, declaredValue, enabled: declaredEnabled, readOnly: declaredReadOnly,
            placeholder: declaredPlaceholder, style: declaredStyle, theme: declaredTheme,
            searchable: isSearchable(), error: declaredError)
    }

    /// Declare the field facts once per frame. `searchable` is resolved from
    /// the CURRENT declaration set: an explicit value replaces the previous
    /// one (so false withdraws an earlier true), while a presentation that
    /// omits the property leaves the current explicit value untouched.
    /// `error` is the owner's current validation fact.
    public func declare(currentValue: String, enabled!: Bool = true, readOnly!: Bool = false,
        placeholder!: String = "请选择", style!: ?CjguiSelectStyle = None,
        theme!: ?CjguiComposableUiTheme = None, searchable!: ?Bool = None, error!: String = ""): Unit {
        declaredValue = currentValue
        declaredInitialized = true
        declaredEnabled = enabled
        declaredReadOnly = readOnly
        declaredPlaceholder = placeholder
        declaredError = error
        declaredStyle = style
        declaredTheme = theme
        match (searchable) {
            case Some(value) => explicitSearchable = Some(value)
            case None => ()
        }
        pushDeclaredFacts()
    }

    /// The always-visible radio presentation of this field, composed from the
    /// ONE public choice group over the SAME declared facts. The rows carry
    /// the select's stable-key action family, so pointer, keyboard and AX
    /// reach the same staged confirmation the popup uses.
    public func radioGroupNode(scopeKey: String, semanticId: String, label!: String = "",
        nodeId!: Int64 = -1, style!: ?CjguiChoiceGroupStyle = None): CjguiComposableUiNode {
        registerChoicePrefix(semanticId)
        let themeStyle = match (style) {
            case Some(value) => value
            case None => match (declaredTheme) {
                case Some(theme) => CjguiChoiceGroupStyleTheme.fromTheme(theme)
                case None => CjguiChoiceGroupStyle()
            }
        }
        return buildChoiceGroupPresentation(nodeId, semanticId, label, themeStyle, true)
    }

    /// The segmented presentation of the same field: the choice group's
    /// default wrapped row, which stays readable on a narrow window.
    public func segmentedNode(scopeKey: String, semanticId: String, label!: String = "",
        nodeId!: Int64 = -1, style!: ?CjguiChoiceGroupStyle = None): CjguiComposableUiNode {
        registerChoicePrefix(semanticId)
        let themeStyle = match (style) {
            case Some(value) => value
            case None => match (declaredTheme) {
                case Some(theme) => CjguiChoiceGroupStyleTheme.fromTheme(theme)
                case None => CjguiChoiceGroupStyle()
            }
        }
        return buildChoiceGroupPresentation(nodeId, semanticId, label, themeStyle, false)
    }

    private func registerChoicePrefix(semanticId: String): Unit {
        for (existing in choicePresentationPrefixes) {
            if (existing == semanticId) { return }
        }
        choicePresentationPrefixes.add(semanticId)
    }

    private func choiceOptionNodes(prefix: String): ArrayList<CjguiChoiceOption> {
        let result = ArrayList<CjguiChoiceOption>()
        for (item in optionsValue) {
            result.add(CjguiChoiceOption(item.key, -1, item.label, item.value,
                "${prefix}${CJGUI_SELECT_CHOOSE_SUFFIX}${item.key}",
                semanticId: "${prefix}-option-${cjguiCommonControlKey(item.key)}",
                enabled: item.enabled && fieldEnabled(), disabledReason: item.disabledReason))
        }
        return result
    }

    private func buildChoiceGroupPresentation(nodeId: Int64, semanticId: String, label: String,
        style: CjguiChoiceGroupStyle, vertical: Bool): CjguiComposableUiNode {
        if (!declaredInitialized) { declare("") }
        // Every node of the presentation carries a scoped identity, so a
        // scene may hold several choice presentations without duplicate ids.
        let scope = CjguiComposableUiIdentityScope(semanticId)
        let container = cjguiComposableVertical(nodeId, semanticId, CjguiComposableUiStyle(gap: 4, growX: 1),
            identity: Some(scope.local("container")))
        if (label.size > 0) {
            container.add(cjguiComposableText(-1, "${semanticId}-label", label,
                CjguiComposableUiStyle(fixedHeight: 18, fontSize: 12.0,
                    textColor: CjguiComposableUiColor(0.35, 0.38, 0.44, 1.0)),
                identity: Some(scope.local("label"))))
        }
        if (optionsValue.size == 0) {
            // An empty option set is a legal field state, not a declaration
            // error: the presentation shows its empty state and refuses writes.
            container.add(cjguiComposableText(-1, "${semanticId}-empty", "没有可选项",
                CjguiComposableUiStyle(fixedHeight: 26, growX: 1,
                    textColor: CjguiComposableUiColor(0.45, 0.48, 0.54, 1.0)),
                identity: Some(scope.local("empty"))))
        } else {
            container.add(CjguiChoiceGroup.build(-1, "${semanticId}-group", -1, choiceOptionNodes(semanticId),
                declaredValue, -1, unmatchedPrefix: "当前值未在选项中", style: style, radioSemantics: true,
                verticalRows: vertical, errorNodeId: -1, errorText: declaredError,
                identityScope: Some(scope)))
            // A current value that matches no option is explained beside the
            // rows; the business value itself is never rewritten.
            var matched = false
            for (item in optionsValue) {
                if (item.value == declaredValue) { matched = true }
            }
            if (!matched && declaredValue.size > 0) {
                container.add(cjguiComposableText(-1, "${semanticId}-unmatched",
                    "当前值未在选项中：${declaredValue}",
                    CjguiComposableUiStyle(fixedHeight: 18, fontSize: 10.5, growX: 1,
                        textColor: CjguiComposableUiColor(0.55, 0.36, 0.20, 1.0)),
                    identity: Some(scope.local("unmatched"))))
            }
        }
        if (declaredError.size > 0) {
            container.add(cjguiComposableText(-1, "${semanticId}-error", declaredError,
                cjguiComposableFormValidationStyle(), identity: Some(scope.local("error"))))
        }
        return container
    }

    /// Route an activation or raw arrow key at one of this field's choice
    /// rows. Confirmation stages the SAME stable-key option the Select popup
    /// stages; the caller commits through `takeConfirmed` + `commit`.
    private func applyChoiceEvent(event: CjguiComposableUiEvent): ?CjguiComposableUiDispatchResult {
        if (event.eventKind == CJGUI_COMPOSABLE_UI_EVENT_ACTIVATE) {
            for (prefix in choicePresentationPrefixes) {
                let helperPrefix = "${prefix}${CJGUI_SELECT_CHOOSE_SUFFIX}"
                if (event.node.actionName.startsWith(helperPrefix)) {
                    let key = event.node.actionName[helperPrefix.size..]
                    var option: ?CjguiSelectOption = None
                    for (item in optionsValue) { if (item.key == key) { option = Some(item) } }
                    if (let Some(value) <- option) {
                        if (!fieldEnabled() || !value.enabled) {
                            return Some(CjguiComposableUiDispatchResult(false))
                        }
                        choicePendingValue = Some(value)
                        return Some(CjguiComposableUiDispatchResult(true))
                    }
                    return Some(CjguiComposableUiDispatchResult(false))
                }
            }
            return None
        }
        if (event.eventKind == 35) {
            var owns = false
            for (prefix in choicePresentationPrefixes) {
                if (event.node.semanticId.startsWith("${prefix}-option-") ||
                    event.node.actionName.startsWith("${prefix}${CJGUI_SELECT_CHOOSE_SUFFIX}")) {
                    owns = true
                }
            }
            if (!owns) { return None }
            var direction = ""
            if (event.text == "up") { direction = "previous" } else if (event.text == "down") { direction = "next" }
            if (direction.size == 0) {
                if (event.text == "left") { direction = "previous" } else if (event.text == "right") {
                    direction = "next"
                }
            }
            if (direction.size == 0) { return None }
            if (!fieldEnabled()) { return Some(CjguiComposableUiDispatchResult(false)) }
            var enabled = ArrayList<CjguiSelectOption>()
            for (item in optionsValue) { if (item.enabled) { enabled.add(item) } }
            if (enabled.size == 0) { return Some(CjguiComposableUiDispatchResult(false)) }
            var index = -1
            var cursor = 0
            var currentKey = ""
            for (item in optionsValue) { if (item.value == declaredValue) { currentKey = item.key } }
            for (item in enabled) {
                if (item.key == currentKey) { index = cursor }
                cursor += 1
            }
            if (direction == "previous") {
                index = if (index <= 0) { enabled.size - 1 } else { index - 1 }
            } else {
                index = if (index < 0 || index + 1 >= enabled.size) { 0 } else { index + 1 }
            }
            let target = enabled[index]
            if (target.key == currentKey) { return Some(CjguiComposableUiDispatchResult(true)) }
            choicePendingValue = Some(target)
            return Some(CjguiComposableUiDispatchResult(true))
        }
        return None
    }

    /// Route one event to every presentation of this field. The first
    /// presentation that claims the event wins; unrelated events return None
    /// so the caller's ordinary dispatch continues.
    public func applyUiEvent(event: CjguiComposableUiEvent): ?CjguiComposableUiDispatchResult {
        if (let Some(result) <- select.applyUiEvent(event)) { return Some(result) }
        return applyChoiceEvent(event)
    }

    /// Take the option any presentation confirmed. The caller then invokes
    /// `commit`; all three presentations share that one owner transaction.
    public func takeConfirmed(): ?CjguiSelectOption {
        if (let Some(option) <- select.takeConfirmed()) { return Some(option) }
        let staged = choicePendingValue
        choicePendingValue = None
        return staged
    }

    public func commit(option: CjguiSelectOption): Bool {
        let applied = commitOperation(option)
        lastFailureValue = if (applied) { "" } else { "select_commit_refused" }
        return applied
    }

    public func lastFailure(): String { return lastFailureValue }
}

public class CjguiPopover {
    private let scope: CjguiComposableUiIdentityScope
    private let prefix: String
    private let layerId: String
    private let ownerSemanticId: String
    private var openValue: Bool = false
    private var revisionValue: Int64 = 0
    private var anchorValue: ?CjguiComposableUiNodeReference = None
    private var styleValue: CjguiComposableUiStyle = CjguiComposableUiStyle(fixedWidth: 300, padding: 12, gap: 8,
        background: CjguiComposableUiColor(1.0, 1.0, 1.0, 1.0),
        border: CjguiComposableUiColor(0.66, 0.70, 0.78, 1.0), borderWidth: 1, cornerRadius: 6)
    private var dismissedValue: Bool = false

    public init(scopeKey: String, semanticId: String) {
        this.scope = CjguiComposableUiIdentityScope(scopeKey)
        this.prefix = semanticId
        this.layerId = "cjgui-popover-${scopeKey}"
        this.ownerSemanticId = "${semanticId}-owner"
    }

    public func revision(): Int64 { return revisionValue }
    public func isOpen(): Bool { return openValue }
    public func layer(): String { return layerId }

    public func open(anchor: CjguiComposableUiNodeReference, style!: ?CjguiComposableUiStyle = None): Unit {
        anchorValue = Some(anchor)
        if (let Some(value) <- style) { styleValue = value }
        openValue = true
        dismissedValue = false
        revisionValue += 1
    }

    public func close(): Unit {
        if (!openValue) { return }
        openValue = false
        dismissedValue = true
        revisionValue += 1
    }

    public func takeDismissed(): Bool {
        let result = dismissedValue
        dismissedValue = false
        return result
    }

    public func applyUiEvent(event: CjguiComposableUiEvent): ?CjguiComposableUiDispatchResult {
        if (!openValue) { return None }
        if (event.eventKind == CJGUI_COMPOSABLE_UI_EVENT_POINTER_BEGIN &&
            event.node.actionName == "${prefix}${CJGUI_SELECT_OUTSIDE_SUFFIX}") {
            close()
            return Some(CjguiComposableUiDispatchResult(true))
        }
        if ((event.eventKind == 35 || event.eventKind == 36) && event.text == "escape") {
            close()
            return Some(CjguiComposableUiDispatchResult(true))
        }
        return None
    }

    public func attachTo(base: CjguiComposableUiNode, content: CjguiComposableUiNode,
        initialFocus!: ?CjguiComposableUiNodeReference = None): CjguiComposableUiNode {
        if (!openValue) { return base }
        let anchor = match (anchorValue) { case Some(value) => value; case None => return base }
        let host = CjguiComposableUiNode(-1, "${prefix}-host", CJGUI_COMPOSABLE_UI_LAYER_HOST, "", "", "", -1,
            CjguiComposableUiStyle(growX: 1, growY: 1), identity: Some(scope.local("host")))
        host.add(base)
        let guard = cjguiComposableButton(-1, "${prefix}${CJGUI_SELECT_OUTSIDE_SUFFIX}-guard", "",
            "${prefix}${CJGUI_SELECT_OUTSIDE_SUFFIX}", 0,
            CjguiComposableUiStyle(fixedWidth: 100000, fixedHeight: 100000, pointerInteractive: true,
                background: CjguiComposableUiColor(0.0, 0.0, 0.0, 0.0)),
            identity: Some(scope.local("outside")))
        let guardLayer = CjguiComposableUiNode(-1, "${prefix}-outside-layer", CJGUI_COMPOSABLE_UI_VERTICAL,
            "", "", "", -1, CjguiComposableUiStyle(fixedWidth: 100000, fixedHeight: 100000),
            layerId: "${layerId}-outside", layerKind: "popup", layerOwnerSemanticId: ownerSemanticId,
            layerAnchorAtPoint: true, layerAnchorPointX: 0, layerAnchorPointY: 0,
            identity: Some(scope.local("outside-layer")))
        guardLayer.add(guard)
        host.add(guardLayer)
        let layer = CjguiComposableUiNode(-1, "${prefix}-popup", CJGUI_COMPOSABLE_UI_VERTICAL,
            "", "", "", -1, styleValue, layerId: layerId, layerKind: "popup",
            layerOwnerSemanticId: ownerSemanticId, layerAnchorSemanticId: ownerSemanticId,
            layerAnchorReference: Some(anchor), layerInitialFocusReference: initialFocus,
            identity: Some(scope.local("popup")))
        layer.add(content)
        host.add(layer)
        return host
    }
}

/// Tooltip text is an ordinary semantic help value (reachable by accessibility
/// and keyboard readers) plus an optional visual anchored layer. The visual
/// layer has no focusable child, so showing it never takes input focus.
public class CjguiTooltip {
    private let scope: CjguiComposableUiIdentityScope
    private let prefix: String
    private let layerId: String
    private let ownerSemanticId: String
    private var textValue: String = ""
    private var openValue: Bool = false
    private var revisionValue: Int64 = 0
    private var anchorValue: ?CjguiComposableUiNodeReference = None
    private var boundActionValue: String = ""
    private var boundReferenceValue: ?CjguiComposableUiNodeReference = None
    /// Accepted scene semantic identity of the bound trigger. Two anchors may
    /// reuse the same business action; this identity, not the action name,
    /// decides whose help is shown or hidden.
    private var boundSemanticIdValue: String = ""

    public init(scopeKey: String, semanticId: String) {
        this.scope = CjguiComposableUiIdentityScope(scopeKey)
        this.prefix = semanticId
        this.layerId = "cjgui-tooltip-${scopeKey}"
        this.ownerSemanticId = "${semanticId}-owner"
    }

    public func revision(): Int64 { return revisionValue }
    public func isOpen(): Bool { return openValue }
    public func text(): String { return textValue }
    public func layer(): String { return layerId }

    /// Attach the same help value to a trigger the caller already built. The
    /// trigger keeps its action and focus; the tooltip adds no input target.
    public func bind(trigger: CjguiComposableUiNode, text: String,
        reference!: ?CjguiComposableUiNodeReference = None): CjguiComposableUiNode {
        trigger.semanticHelp = text
        textValue = text
        boundActionValue = trigger.actionName
        boundReferenceValue = reference
        boundSemanticIdValue = trigger.semanticId
        return trigger
    }

    private func showBound(): Bool {
        if (textValue.size == 0) { return false }
        let reference = match (boundReferenceValue) {
            case Some(value) => value
            case None => return false
        }
        if (openValue) { return false }
        anchorValue = Some(reference)
        openValue = true
        revisionValue += 1
        return true
    }

    public func show(anchor: CjguiComposableUiNodeReference): Unit {
        anchorValue = Some(anchor)
        openValue = textValue.size > 0
        revisionValue += 1
    }

    public func hide(): Unit {
        if (!openValue) { return }
        openValue = false
        revisionValue += 1
    }

    private func matchesBound(node: CjguiComposableUiLayoutNode): Bool {
        if (boundSemanticIdValue.size > 0) {
            return node.semanticId == boundSemanticIdValue
        }
        // Legacy callers that supplied no identity keep the action-name rule.
        return boundActionValue.size > 0 && node.actionName == boundActionValue
    }

    public func applyUiEvent(event: CjguiComposableUiEvent): ?CjguiComposableUiDispatchResult {
        if (boundSemanticIdValue.size == 0 && boundActionValue.size == 0) {
            return None
        }
        if (event.eventKind == CJGUI_COMPOSABLE_UI_EVENT_HOVER_ENTER && matchesBound(event.node)) {
            if (showBound()) { return Some(CjguiComposableUiDispatchResult(true)) }
            return None
        }
        if (event.eventKind == CJGUI_COMPOSABLE_UI_EVENT_HOVER_LEAVE && openValue && matchesBound(event.node)) {
            hide()
            return Some(CjguiComposableUiDispatchResult(true))
        }
        if (event.eventKind == CJGUI_COMPOSABLE_UI_EVENT_FOCUS) {
            if (matchesBound(event.node)) {
                if (showBound()) { return Some(CjguiComposableUiDispatchResult(true)) }
                return None
            }
            if (openValue) {
                hide()
                return Some(CjguiComposableUiDispatchResult(true))
            }
        }
        if ((event.eventKind == 35 || event.eventKind == 36) && event.text == "escape" && openValue) {
            hide()
            return Some(CjguiComposableUiDispatchResult(true))
        }
        return None
    }

    public func attachTo(base: CjguiComposableUiNode): CjguiComposableUiNode {
        if (!openValue || textValue.size == 0) { return base }
        let anchor = match (anchorValue) { case Some(value) => value; case None => return base }
        let host = CjguiComposableUiNode(-1, "${prefix}-host", CJGUI_COMPOSABLE_UI_LAYER_HOST, "", "", "", -1,
            CjguiComposableUiStyle(growX: 1, growY: 1), identity: Some(scope.local("host")))
        host.add(base)
        let layer = CjguiComposableUiNode(-1, "${prefix}-popup", CJGUI_COMPOSABLE_UI_VERTICAL,
            "", "", "", -1, CjguiComposableUiStyle(fixedWidth: 260, padding: 6, gap: 0,
                background: CjguiComposableUiColor(0.16, 0.18, 0.22, 1.0),
                border: CjguiComposableUiColor(0.32, 0.35, 0.42, 1.0), borderWidth: 1, cornerRadius: 5,
                textColor: CjguiComposableUiColor(0.96, 0.97, 1.0, 1.0), fontSize: 12.0),
            layerId: layerId, layerKind: "popup", layerOwnerSemanticId: ownerSemanticId,
            layerAnchorSemanticId: ownerSemanticId, layerAnchorReference: Some(anchor),
            identity: Some(scope.local("popup")))
        layer.add(cjguiComposableText(-1, "${prefix}-text", textValue,
            CjguiComposableUiStyle(fontSize: 12.0, textColor: CjguiComposableUiColor(0.96, 0.97, 1.0, 1.0)),
            identity: Some(scope.local("text"))))
        host.add(layer)
        return host
    }
}

public class CjguiScrollbarStyle {
    public let track: CjguiComposableUiStyle
    public let thumb: CjguiComposableUiStyle
    public let minimumThumb: Int64

    public init(track!: CjguiComposableUiStyle = CjguiComposableUiStyle(
            background: CjguiComposableUiColor(0.80, 0.82, 0.86, 0.45), cornerRadius: 4),
        thumb!: CjguiComposableUiStyle = CjguiComposableUiStyle(
            background: CjguiComposableUiColor(0.42, 0.46, 0.54, 0.80), cornerRadius: 4),
        minimumThumb!: Int64 = 24) {
        this.track = track
        this.thumb = thumb
        this.minimumThumb = if (minimumThumb > 0) { minimumThumb } else { 24 }
    }

    public static func fromTheme(theme: CjguiComposableUiTheme): CjguiScrollbarStyle {
        return CjguiScrollbarStyle(
            track: CjguiComposableUiStyle(background: theme.card.border, cornerRadius: 4),
            thumb: CjguiComposableUiStyle(background: theme.body.textColor, cornerRadius: 4))
    }
}

/// The visible vertical scrollbar for one shared viewport. Position and thumb
/// length come from the accepted extents; a drag writes the SAME viewport
/// request used by the wheel and keyboard reveal.
public func cjguiComposableScrollBar(nodeId: Int64, semanticId: String,
    viewport: CjguiComposableUiScrollViewport, width: Int64,
    style!: CjguiScrollbarStyle = CjguiScrollbarStyle(), enabled!: Bool = true): CjguiComposableUiNode {
    let minimum = viewport.minimumOffset()
    let maximum = viewport.maximumOffset()
    let safeMaximum = if (maximum > minimum) { maximum } else { minimum }
    let value = viewport.offset()
    let safeValue = if (value < minimum) { minimum } else if (value > safeMaximum) { safeMaximum } else { value }
    let bar = CjguiComposableUiNode(nodeId, semanticId, CJGUI_COMPOSABLE_UI_SLIDER, "",
        safeValue.toString(), "SCROLLBAR_VALUE", -1,
        CjguiComposableUiStyle(fixedWidth: if (width > 0) { width } else { 10 }, growY: 1,
            alignY: CJGUI_COMPOSABLE_UI_ALIGN_STRETCH),
        scrollViewport: Some(viewport), enabled: enabled && safeMaximum > minimum,
        pointerControlRole: "scrollbar", pointerControlAxis: CjguiComposableUiSplitAxis.VERTICAL,
        pointerControlMinimum: minimum, pointerControlMaximum: safeMaximum, pointerControlStep: 1,
        pointerControlHandleThickness: style.minimumThumb,
        interactionStyle: CjguiComposableUiInteractionStyle(),
        semanticLabel: "滚动")
    let trackScope = CjguiComposableUiIdentityScope("cjgui-scrollbar-${nodeId}")
    let track = CjguiComposableUiNode(-1, "${semanticId}-track", CJGUI_COMPOSABLE_UI_HORIZONTAL, "", "", "", -1,
        style.track, identity: Some(trackScope.local("track")))
    let empty = CjguiComposableUiNode(-1, "${semanticId}-fill", CJGUI_COMPOSABLE_UI_HORIZONTAL, "", "", "", -1,
        CjguiComposableUiStyle(fixedHeight: 0), identity: Some(trackScope.local("fill")))
    let thumb = CjguiComposableUiNode(-1, "${semanticId}-thumb", CJGUI_COMPOSABLE_UI_HORIZONTAL, "", "", "", -1,
        style.thumb, identity: Some(trackScope.local("thumb")))
    bar.add(track)
    bar.add(empty)
    bar.add(thumb)
    return bar
}

/// Vertical slider geometry for the scrollbar role. It uses the SAME viewport
/// extents as layout and hit testing, never a second content-size estimate.
public func cjguiScrollbarPaintBounds(node: CjguiComposableUiNode,
    bounds: CjguiComposableUiRect): Array<CjguiComposableUiRect> {
    if (bounds.width <= 0 || bounds.height <= 0) {
        return [CjguiComposableUiRect(bounds.x, bounds.y, 0, 0), CjguiComposableUiRect(bounds.x, bounds.y, 0, 0),
            CjguiComposableUiRect(bounds.x, bounds.y, 0, 0)]
    }
    let viewport = match (node.scrollViewport) {
        case Some(value) => value
        case None =>
            return [CjguiComposableUiRect(bounds.x, bounds.y, bounds.width, bounds.height),
                CjguiComposableUiRect(bounds.x, bounds.y, 0, 0),
                CjguiComposableUiRect(bounds.x, bounds.y, bounds.width, 0)]
    }
    let content = viewport.contentExtent()
    let visible = viewport.viewportExtent()
    let trackWidth = if (bounds.width > 0) { bounds.width } else { 1 }
    let minimum = node.pointerControlMinimum
    let maximum = node.pointerControlMaximum
    let total = if (maximum > minimum) { maximum - minimum } else { 0 }
    if (content <= visible || total <= 0) {
        return [CjguiComposableUiRect(bounds.x, bounds.y, trackWidth, bounds.height),
            CjguiComposableUiRect(bounds.x, bounds.y, 0, 0),
            CjguiComposableUiRect(bounds.x, bounds.y, trackWidth, 0)]
    }
    var thumbLength = (bounds.height * visible) / content
    if (thumbLength < node.pointerControlHandleThickness) {
        thumbLength = node.pointerControlHandleThickness
    }
    if (thumbLength > bounds.height) { thumbLength = bounds.height }
    let value = Int64.tryParse(node.value) ?? minimum
    let clamped = if (value < minimum) { minimum } else if (value > maximum) { maximum } else { value }
    let travel = bounds.height - thumbLength
    let fraction = if (total > 0) { Float64(clamped - minimum) / Float64(total) } else { 0.0 }
    let thumbY = bounds.y + Int64(Float64(travel) * fraction)
    return [CjguiComposableUiRect(bounds.x, bounds.y, trackWidth, bounds.height),
        CjguiComposableUiRect(bounds.x, bounds.y, 0, 0),
        CjguiComposableUiRect(bounds.x, thumbY, trackWidth, thumbLength)]
}

/// Requested offset for one vertical thumb drag. The caller passes the
/// ACCEPTED node bounds and extents; the result is clamped by requestOffset.
public func cjguiScrollbarOffsetForPointer(pointerY: Float64, grabOffset: Float64,
    bounds: CjguiComposableUiRect, minimum: Int64, maximum: Int64, thumbLength: Int64): Int64 {
    if (maximum <= minimum) { return minimum }
    var thumb = thumbLength
    if (thumb < 1) { thumb = 1 }
    if (thumb > bounds.height) { thumb = bounds.height }
    let travel = Float64(bounds.height - thumb)
    if (travel <= 0.0) { return minimum }
    let raw = (pointerY - Float64(bounds.y) - grabOffset) / travel
    let fraction = if (raw < 0.0) { 0.0 } else if (raw > 1.0) { 1.0 } else { raw }
    let span = Float64(maximum - minimum)
    return minimum + Int64(round(span * fraction))
}

public func cjguiGeneratedSelectComponent(): CjguiGeneratedUiComponentSpec {
    let properties = ArrayList<CjguiGeneratedUiPropertySpec>()
    for (property in CjguiGeneratedUiPresentation.leafStyleProperties()) {
        if (property.name != "letterSpacing" && property.name != "lineHeight") { properties.add(property) }
    }
    properties.add(CjguiGeneratedUiPropertySpec("label", "STRING", maxLength: 80))
    properties.add(CjguiGeneratedUiPropertySpec("placeholder", "STRING", maxLength: 80,
        defaultValue: "请选择"))
    properties.add(CjguiGeneratedUiPropertySpec("searchable", "BOOLEAN", defaultValue: "false"))
    return CjguiGeneratedUiComponentSpec("select", properties, false)
}

/// The always-visible radio presentation of a choice field. It consumes the
/// same label/style vocabulary; `searchable`/`placeholder` belong to the
/// dropdown presentation only and are deliberately NOT declared here, so a
/// declaration naming them is rejected instead of silently ignored.
public func cjguiGeneratedRadioGroupComponent(): CjguiGeneratedUiComponentSpec {
    let properties = ArrayList<CjguiGeneratedUiPropertySpec>()
    for (property in CjguiGeneratedUiPresentation.leafStyleProperties()) {
        if (property.name != "letterSpacing" && property.name != "lineHeight") { properties.add(property) }
    }
    properties.add(CjguiGeneratedUiPropertySpec("label", "STRING", maxLength: 80))
    return CjguiGeneratedUiComponentSpec("radioGroup", properties, false)
}

/// The segmented single-choice presentation of a choice field, with the same
/// deliberate property vocabulary as the radio group.
public func cjguiGeneratedSegmentedComponent(): CjguiGeneratedUiComponentSpec {
    let properties = ArrayList<CjguiGeneratedUiPropertySpec>()
    for (property in CjguiGeneratedUiPresentation.leafStyleProperties()) {
        if (property.name != "letterSpacing" && property.name != "lineHeight") { properties.add(property) }
    }
    properties.add(CjguiGeneratedUiPropertySpec("label", "STRING", maxLength: 80))
    return CjguiGeneratedUiComponentSpec("segmented", properties, false)
}

public func cjguiGeneratedPopoverComponent(): CjguiGeneratedUiComponentSpec {
    let properties = ArrayList<CjguiGeneratedUiPropertySpec>()
    for (property in CjguiGeneratedUiPresentation.leafStyleProperties()) {
        if (property.name != "letterSpacing" && property.name != "lineHeight") { properties.add(property) }
    }
    properties.add(CjguiGeneratedUiPropertySpec("label", "STRING", maxLength: 80))
    return CjguiGeneratedUiComponentSpec("popover", properties, true)
}

public func cjguiGeneratedTooltipComponent(): CjguiGeneratedUiComponentSpec {
    let properties = ArrayList<CjguiGeneratedUiPropertySpec>()
    properties.add(CjguiGeneratedUiPropertySpec("text", "STRING", maxLength: 240))
    return CjguiGeneratedUiComponentSpec("tooltip", properties, false)
}

public func cjguiGeneratedScrollBarComponent(): CjguiGeneratedUiComponentSpec {
    let properties = ArrayList<CjguiGeneratedUiPropertySpec>()
    properties.add(CjguiGeneratedUiPropertySpec("width", "INTEGER", minimum: 1, maximum: 32, defaultValue: "10"))
    return CjguiGeneratedUiComponentSpec("scrollBar", properties, false)
}

package cjgui

import std.collection.*

/// Experimental searchable-choice value. The key belongs to the application;
/// filtering never changes its identity or turns a displayed row index into an action.
public class CjguiSearchableSelectionItem {
    public let key: String
    public let title: String
    public let detail: String
    public let shortcut: String
    public let keywords: String
    public let isEnabled: Bool
    public let disabledReason: String

    public init(key: String, title: String, detail!: String = "", shortcut!: String = "", keywords!: String = "",
        isEnabled!: Bool = true, disabledReason!: String = "") {
        this.key = key
        this.title = title
        this.detail = detail
        this.shortcut = shortcut
        this.keywords = keywords
        this.isEnabled = isEnabled
        this.disabledReason = disabledReason
    }
}

/// Predictable substring matching: ASCII case-insensitive, other scripts exact.
/// An application can supply its own metadata-only matcher to `open`.
public func cjguiSearchableSelectionMatches(item: CjguiSearchableSelectionItem, query: String): Bool {
    return query.size == 0 || (item
        .title + " " + item
        .detail + " " + item
        .keywords)
        .toAsciiLower()
        .contains(query.toAsciiLower())
}

/// Experimental modal assembled from the normal input, virtual list, identity,
/// theme, scoped command and layer-focus mechanisms. It owns presentation only.
/// Call `takeConfirmed(window)` after each normal window turn; it releases an
/// action only after the closed layer was accepted and focus restoration finished.
public class CjguiSearchableSelectionPanel <: CjguiComposableUiVirtualListSource {
    private let scope: CjguiComposableUiIdentityScope
    private let prefix: String
    private let layer: String
    private var generation: Int64 = 0
    private var revisionValue: Int64 = 0
    private var openValue: Bool = false
    private var titleValue: String = ""
    private var queryValue: String = ""
    private var hintValue: String = ""
    private var anchor: ?CjguiComposableUiNodeReference = None
    private var entries = ArrayList<CjguiSearchableSelectionItem>()
    private var results = ArrayList<Int64>()
    private var listState = CjguiComposableUiVirtualListState()
    private var matcher: (CjguiSearchableSelectionItem, String) -> Bool = cjguiSearchableSelectionMatches
    private var pending: ?CjguiSearchableSelectionItem = None
    private var awaitingReturn: Bool = false
    private var confirmationFailure: String = ""
    private var theme = CjguiComposableUiTheme.beaconDark()

    public init(scopeKey: String) {
        this.scope = CjguiComposableUiIdentityScope(scopeKey)
        this.prefix = "search-panel-${scopeKey}"
        this.layer = "search-panel-${scopeKey}"
        if (!scope.isValid()) {
            throw IllegalArgumentException("search_panel_invalid_scope")
        }
    }

    public func revision(): Int64 {
        return revisionValue
    }
    public func isOpen(): Bool {
        return openValue
    }
    public func query(): String {
        return queryValue
    }
    public func resultCount(): Int64 {
        return results.size
    }
    public func highlightedKey(): String {
        return listState.focusedKey()
    }

    public func open(title: String, items: ArrayList<CjguiSearchableSelectionItem>,
        restoreTarget: CjguiComposableUiNodeReference,
        matches!: (CjguiSearchableSelectionItem, String) -> Bool = cjguiSearchableSelectionMatches, hint!: String = ""): Unit {
        let keys = HashSet<String>()
        for (item in items) {
            if (item.key.size == 0 || !keys.add(item.key)) {
                throw IllegalArgumentException("search_panel_duplicate_or_empty_key")
            }
        }
        entries = ArrayList<CjguiSearchableSelectionItem>(items)
        matcher = matches
        anchor = Some(restoreTarget)
        titleValue = title
        hintValue = hint
        generation += 1
        pending = None
        awaitingReturn = false
        confirmationFailure = ""
        openValue = true
        queryValue = ""
        listState = CjguiComposableUiVirtualListState()
        filterResults();
        revisionValue += 1
    }

    public func setQuery(value: String): Unit {
        if (!openValue || queryValue == value) {
            return
        }
        queryValue = value
        filterResults();
        revisionValue += 1
    }

    private func filterResults(): Unit {
        results.clear()
        var index: Int64 = 0
        for (entry in entries) {
            if (matcher(entry, queryValue)) {
                results.add(index)
            }
            index += 1
        }
        var key = listState.focusedKey()
        if (indexForKey(key) < 0) {
            key = if (results.size > 0) {
                entries[results[0]].key
            } else {
                ""
            }
        }
        listState.setFocusedKey(key);
        listState.setSelectedKey(key)
        if (key.size > 0) {
            let _ = listState.revealKey(this, key)
        } else {
            listState.scrollToIndex(0)
        }
    }

    public func moveHighlight(direction: String): Unit {
        if (!openValue || (direction != "up" && direction != "down")) {
            return
        }
        let item = listState.moveFocus(this, direction)
        listState.setSelectedKey(item.key);
        revisionValue += 1
    }

    /// Disabled entries stay discoverable, including their reason, but cannot
    /// produce a pending action. Native text composition never invokes this command.
    public func requestConfirm(): Bool {
        if (!openValue) {
            return false
        }
        let index = indexForKey(listState.focusedKey())
        if (index < 0) {
            return false
        }
        let item = entries[results[index]]
        if (!item.isEnabled) {
            return false
        }
        pending = Some(item)
        awaitingReturn = true
        openValue = false
        revisionValue += 1
        return true
    }

    public func cancel(): Unit {
        if (!openValue) {
            return
        }
        pending = None
        awaitingReturn = true
        openValue = false
        revisionValue += 1
    }

    public func takeConfirmed(window: CjguiComposableUiWindow): ?CjguiSearchableSelectionItem {
        if (openValue || !awaitingReturn || window.hasAcceptedLayer(layer)) {
            return None
        }
        if (!window.isOpen()) {
            pending = None
            awaitingReturn = false
            return None
        }
        let target = match (anchor) {
            case Some(value) => value;
            case None => return None
        }
        let state = window.modalReturnPositionState(target)
        if (state == "pending") {
            return None
        }
        awaitingReturn = false
        if (state != "installed" && state != "focused") {
            pending = None
            confirmationFailure = state
            revisionValue += 1
            return None
        }
        let result = pending;
        pending = None
        return result
    }

    /// A terminal return failure consumes the confirmation, never its business
    /// action. The host can show this reason and let the user reopen the panel.
    public func takeConfirmationFailure(): String {
        let result = confirmationFailure;
        confirmationFailure = ""
        return result
    }

    private func reference(key: String): CjguiComposableUiNodeReference {
        return CjguiComposableUiNodeReference.scoped(scope, key)
    }

    public func commands(): ArrayList<CjguiComposableUiCommand> {
        let commands = ArrayList<CjguiComposableUiCommand>()
        if (!openValue) {
            return commands
        }
        for (key in ["up", "down", "enter", "escape"]) {
            commands.add(
                CjguiComposableUiCommand("${prefix}-${key}", reference(key), key,
                    CjguiComposableUiShortcut(key, usesCommand: false), "", 0, true, false, focusScopeId: layer))
        }
        return commands
    }

    /// Returns None for other components' events. Query typing, wheel input,
    /// mouse confirmation and declared keyboard commands use the same state.
    public func applyUiEvent(event: CjguiComposableUiEvent): ?CjguiComposableUiDispatchResult {
        if (!openValue || !event.node.semanticId.startsWith(prefix + "-")) {
            return None
        }
        if (event.eventKind == CJGUI_COMPOSABLE_UI_EVENT_TEXT_CHANGED && event.node.semanticId == prefix + "-query") {
            setQuery(event.text)
        } else if (event.eventKind == CJGUI_COMPOSABLE_UI_EVENT_SCROLL) {
            listState.scrollByViewport(event.text);
            revisionValue += 1
        } else if (event.eventKind == CJGUI_COMPOSABLE_UI_EVENT_ACTIVATE) {
            let action = event.node.actionName
            if (action == prefix + "-choose") {
                let index = event.node.resourceId
                if (index >= 0 && index < entries.size && indexForKey(entries[index].key) >= 0) {
                    listState.setFocusedKey(entries[index].key)
                    let _ = requestConfirm()
                }
            } else if (action == prefix + "-up") {
                moveHighlight("up")
            } else if (action == prefix + "-down") {
                moveHighlight("down")
            } else if (action == prefix + "-enter") {
                let _ = requestConfirm()
            } else if (action == prefix + "-escape") {
                cancel()
            }
        } else if (event.eventKind == 35 && event.text == "escape") {
            cancel()
        }
        return Some(CjguiComposableUiDispatchResult(true))
    }

    /// Mount as a direct sibling of the application's complete base scene.
    public func attachTo(base: CjguiComposableUiNode, currentTheme: CjguiComposableUiTheme): CjguiComposableUiNode {
        if (!openValue) {
            return base
        }
        theme = currentTheme
        let host = CjguiComposableUiNode(-1, prefix + "-host", CJGUI_COMPOSABLE_UI_LAYER_HOST, "", "", "", -1,
            CjguiComposableUiStyle(growX: 1, growY: 1), identity: Some(scope.local("host")))
        host.add(base)
        let dialog = CjguiComposableUiNode(-1, prefix + "-dialog", CJGUI_COMPOSABLE_UI_VERTICAL, "", "", "", -1,
            CjguiComposableUiStyle(fixedWidth: 620, fixedHeight: 438, padding: 16, gap: 8,
                background: theme.card.background, border: theme.card.border, borderWidth: 1), layerId: layer,
            layerKind: "dialog", layerIsModal: true, layerAnchorReference: anchor,
            layerInitialFocusReference: Some(reference("query")), identity: Some(scope.local("dialog")))
        dialog.add(
            cjguiComposableText(-1, prefix + "-title", titleValue,
                CjguiComposableUiStyle(fixedHeight: 28, textMaxLines: 1, textOverflow: "ellipsis", fontSize: 18.0,
                    textColor: theme.heading.textColor), identity: Some(scope.local("title"))))
        dialog.add(
            CjguiComposableUiNode(-1, prefix + "-query", CJGUI_COMPOSABLE_UI_TEXT_INPUT, "搜索", queryValue, "EDIT_TEXT",
                0,
                CjguiComposableUiStyle(fixedHeight: 36, padding: 6, fontSize: 14.0, textColor: theme.input.textColor,
                    background: theme.input.background, border: theme.input.border, borderWidth: 1),
                identity: Some(scope.local("query"))))
        if (results.size == 0) {
            dialog.add(
                cjguiComposableText(-1, prefix + "-empty", "没有匹配的结果",
                    CjguiComposableUiStyle(growY: 1, textColor: theme.body.textColor, fontSize: 14.0),
                    identity: Some(scope.local("empty"))))
        } else {
            dialog.add(
                CjguiComposableUiNode(-1, prefix + "-list", CJGUI_COMPOSABLE_UI_SCROLL_AREA, "", "", "SCROLL", -1,
                    CjguiComposableUiStyle(growY: 1, growX: 1), scrollOffset: listState.scrollOffset(),
                    virtualListSource: Some(this), virtualListState: Some(listState), virtualListRowHeight: 54,
                    virtualListRowGap: 2, virtualListOverscan: 1, identity: Some(scope.local("list"))))
        }
        let footer = CjguiComposableUiNode(-1, prefix + "-footer", CJGUI_COMPOSABLE_UI_HORIZONTAL, "", "", "", -1,
            CjguiComposableUiStyle(fixedHeight: 30, gap: 8), identity: Some(scope.local("footer")))
        for ((key, label) in [("up", "↑"), ("down", "↓"), ("enter", "确认 ↵"), ("escape", "取消 Esc")]) {
            footer.add(
                cjguiComposableButton(-1, prefix + "-" + key, label, prefix + "-" + key, 0,
                    CjguiComposableUiStyle(fixedWidth: if (key == "up" || key == "down") {
                        36
                    } else {
                        96
                    }, fixedHeight: 30, fontSize: 12.0, textColor: theme.body.textColor,
                        background: theme.input.background, border: theme.card.border, borderWidth: 1),
                    identity: Some(scope.local(key))))
        }
        footer.add(
            cjguiComposableText(-1, prefix + "-count", "${results.size} 项",
                CjguiComposableUiStyle(growX: 1, fontSize: 12.0, textColor: theme.body.textColor),
                identity: Some(scope.local("count"))))
        dialog.add(footer)
        dialog.add(
            cjguiComposableText(-1, prefix + "-hint", hintValue,
                CjguiComposableUiStyle(fixedHeight: 20, textMaxLines: 1, textOverflow: "ellipsis", fontSize: 11.0,
                    textColor: theme.body.textColor), identity: Some(scope.local("hint"))))
        host.add(dialog)
        return host
    }

    public func itemCount(): Int64 {
        return results.size
    }
    public func indexForKey(key: String): Int64 {
        var index: Int64 = 0
        for (original in results) {
            if (entries[original].key == key) {
                return index
            };
            index += 1
        }
        return -1
    }
    public func itemAt(index: Int64): CjguiComposableUiVirtualListItem {
        if (index < 0 || index >= results.size) {
            return CjguiComposableUiVirtualListItem.missing()
        }
        let original = results[index];
        let entry = entries[original]
        return CjguiComposableUiVirtualListItem(entry.key, original, entry.title)
    }
    public func buildRow(item: CjguiComposableUiVirtualListItem, isSelected: Bool, isFocused: Bool): CjguiComposableUiNode {
        let entry = entries[item.resourceId]
        // The immutable source ordinal names the row for this open lifecycle;
        // query results never renumber it. Business identity remains entry.key.
        let rows = scope.child("open-${generation}")
        let selected = isSelected || isFocused
        let row = CjguiComposableUiNode(-1, prefix + "-row-${item.resourceId}", CJGUI_COMPOSABLE_UI_VERTICAL, "", "", "",
            -1, CjguiComposableUiStyle(fixedHeight: 54, gap: 2, background: if (selected) {
                theme.primaryAction.background
            } else {
                theme.card.background
            }), identity: Some(rows.local("row-${item.resourceId}")), semanticKey: entry.key, semanticSelected: selected)
        let heading = CjguiComposableUiNode(-1, prefix + "-heading-${item.resourceId}", CJGUI_COMPOSABLE_UI_HORIZONTAL,
            "", "", "", -1, CjguiComposableUiStyle(fixedHeight: 28, gap: 4),
            identity: Some(rows.local("heading-${item.resourceId}")))
        heading.add(
            cjguiComposableButton(-1, prefix + "-choose-${item.resourceId}", entry.title, prefix + "-choose",
                item.resourceId,
                CjguiComposableUiStyle(fixedHeight: 28, growX: 1, textMaxLines: 1, textOverflow: "ellipsis",
                    fontSize: 14.0, textColor: if (selected) {
                        theme.primaryAction.textColor
                    } else {
                        theme.body.textColor
                    }), enabled: entry.isEnabled, identity: Some(rows.local("choose-${item.resourceId}"))))
        if (entry.shortcut.size > 0) {
            heading.add(
                cjguiComposableText(-1, prefix + "-shortcut-${item.resourceId}", entry.shortcut,
                    CjguiComposableUiStyle(fixedWidth: 88, fixedHeight: 28, fontSize: 12.0,
                        textColor: if (selected) {
                            theme.primaryAction.textColor
                        } else {
                            theme.body.textColor
                        }), identity: Some(rows.local("shortcut-${item.resourceId}"))))
        }
        row.add(heading)
        row.add(
            cjguiComposableText(-1, prefix + "-detail-${item.resourceId}", if (entry.isEnabled) {
                entry.detail
            } else {
                "不可用：${entry.disabledReason}"
            },
                CjguiComposableUiStyle(fixedHeight: 20, textMaxLines: 1, textOverflow: "ellipsis", fontSize: 11.0,
                    textColor: if (selected) {
                        theme.primaryAction.textColor
                    } else {
                        theme.body.textColor
                    }), identity: Some(rows.local("detail-${item.resourceId}"))))
        return row
    }
}

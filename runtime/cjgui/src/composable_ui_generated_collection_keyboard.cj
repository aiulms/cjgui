package cjgui

/// Value-only feedback: a view request is distinct from a selection change,
/// and neither is proof of an actually presented frame.
public class CjguiGeneratedCollectionKeyboardResult {
    public let isHandled: Bool
    public let didChange: Bool
    /// Both the stable-key reveal and the existing scope focus were accepted.
    public let didAcceptViewFocus: Bool
    public let focus: String
    init(handled: Bool, changed: Bool, requested: Bool, focus: String) {
        this.isHandled = handled
        this.didChange = changed
        this.didAcceptViewFocus = requested
        this.focus = focus
    }
}

/// Reuses CollectionSelection's vocabulary. A recognized edge key still
/// reveals focus after an independent scroll even if the key did not change.
public func cjguiNavigateGeneratedCollection(collection: CjguiGeneratedUiCollection, event: CjguiComposableUiEvent,
    window: ?CjguiComposableUiWindow): CjguiGeneratedCollectionKeyboardResult {
    if (event.eventKind != 35 || event.node.nodeKind != CJGUI_COMPOSABLE_UI_SCROLL_AREA) {
        return CjguiGeneratedCollectionKeyboardResult(false, false, false, collection.selection.focus())
    }
    let viewport = match (event.node.scrollViewport) {
        case Some(value) => value
        case None => return CjguiGeneratedCollectionKeyboardResult(false, false, false, collection.selection.focus())
    }
    let supported = event.text == "up" || event.text == "down" || event.text == "page_up" || event.text == "page_down" ||
        event.text == "home" || event.text == "end" || event.text == "select_all"
    if (!supported || !refEq(viewport, collection.viewport)) {
        return CjguiGeneratedCollectionKeyboardResult(false, false, false, collection.selection.focus())
    }
    let navigation = collection
        .selection
        .navigate(event.text, (event.modifierFlags & CJGUI_UI_MODIFIER_SHIFT) != 0, collection.order())
    let requested = if (let Some(value) <- window) {
        cjguiRevealGeneratedCollectionFocus(collection, value, event.node.semanticId)
    } else {
        false
    }
    return CjguiGeneratedCollectionKeyboardResult(true, navigation.didChange, requested, navigation.focus)
}

/// Experimental keyboard wiring for the compiled collection projection. The
/// caller uses CollectionSelection.navigate and its ordinary business select.
/// Source-key framing stays here with the collection adapter, never in apps.
/// Keeping native focus on the surviving scroll scope lets the next arrow
/// work even when the previously materialized row leaves the viewport.
public func cjguiRevealGeneratedCollectionFocus(collection: CjguiGeneratedUiCollection, window: CjguiComposableUiWindow,
    scopeSemanticId: String): Bool {
    let key = collection.selection.focus()
    if (key.isEmpty() || collection.table.indexForKey(key) < 0) {
        return false
    }
    if (!window.revealVirtualListItem(scopeSemanticId, "data:${key}", collection.viewport)) {
        return false
    }
    return window.focusAcceptedSemanticNode(scopeSemanticId)
}

// Focused contracts for the public virtual card grid and the rule-set mode
// entry. The grid tests use a simple non-rule-set card definition, so they
// prove the component is reusable rather than coupled to this application.
package cjgui_rule_set_window_app

import cjgui.*
import cjgui_rule_set_application.*
import cjgui_shared_operation_core.*
import std.collection.*
import std.convert.*
import std.unittest.*
import std.unittest.testmacro.*

private class CardGridTestRecorder {
    var builtKeys = ArrayList<String>()
    var builtCards: Int64 = 0
}

private class CardGridTestSource <: CjguiComposableUiVariableHeightListSource {
    private let items: Array<CjguiComposableUiVariableHeightListItem>
    var itemReads: Int64 = 0

    init(count: Int64) {
        let rows = ArrayList<CjguiComposableUiVariableHeightListItem>()
        var index: Int64 = 0
        while (index < count) {
            rows.add(CjguiComposableUiVariableHeightListItem("item_${index}", index,
                "item ${index}", 0, estimatedHeight: 60))
            index += 1
        }
        this.items = rows.toArray()
    }

    public func itemCount(): Int64 {
        return items.size
    }

    public func itemAt(index: Int64): CjguiComposableUiVariableHeightListItem {
        itemReads += 1
        if (index < 0 || index >= items.size) {
            return CjguiComposableUiVariableHeightListItem.missing()
        }
        return items[index]
    }

    public func indexForKey(key: String): Int64 {
        if (key.startsWith("item_")) {
            let parts = key.split("item_")
            if (parts.size == 2) {
                if (let Some(index) <- Int64.tryParse(parts[1])) {
                    if (index >= 0 && index < items.size) {
                        return index
                    }
                }
            }
        }
        return -1
    }

    public func measurementGeneration(): Int64 {
        return 0
    }

    public func buildRow(item: CjguiComposableUiVariableHeightListItem, isSelected: Bool,
        isFocused: Bool): CjguiComposableUiNode {
        return cjguiComposableText(-1, "base-row-${item.key}", item.title,
            CjguiComposableUiStyle(fixedHeight: 60))
    }
}

private class CardGridKeyedSource <: CjguiComposableUiVariableHeightListSource {
    private let keys: Array<String>

    init(keys: Array<String>) {
        this.keys = keys
    }

    public func itemCount(): Int64 {
        return keys.size
    }

    public func itemAt(index: Int64): CjguiComposableUiVariableHeightListItem {
        if (index < 0 || index >= keys.size) {
            return CjguiComposableUiVariableHeightListItem.missing()
        }
        let key = keys[index]
        return CjguiComposableUiVariableHeightListItem(key, index, key, 0, estimatedHeight: 60)
    }

    public func indexForKey(key: String): Int64 {
        var index: Int64 = 0
        while (index < keys.size) {
            if (keys[index] == key) {
                return index
            }
            index += 1
        }
        return -1
    }

    public func measurementGeneration(): Int64 {
        return 0
    }

    public func buildRow(item: CjguiComposableUiVariableHeightListItem, isSelected: Bool,
        isFocused: Bool): CjguiComposableUiNode {
        return cjguiComposableText(-1, "keyed-base-row-${item.key}", item.title,
            CjguiComposableUiStyle(fixedHeight: 60))
    }
}

private func cardModeCreateRule(domain: CjguiRuleSetEditingDomain, label: String,
    retention: Int64, requestId: String): Unit {
    let result = domain.executeFromExternal(CjguiRuleSetInvocationFactory.create(
        domain.snapshot().version, label, true, retention, "cache", requestId))
    if (!result.applied) {
        throw IllegalArgumentException("card mode test rule create failed: ${result.reason}")
    }
}

private func cardGridTestStyle(): CjguiComposableUiStyle {
    return CjguiComposableUiStyle(fixedWidth: 100, fixedHeight: 60, padding: 4,
        background: CjguiComposableUiColor(1.0, 1.0, 1.0, 1.0),
        border: CjguiComposableUiColor(0.8, 0.8, 0.8, 1.0))
}

private func cardGridTestScene(source: CjguiComposableUiCardGridSource,
    state: CjguiComposableUiVirtualListState, version: Int64): CjguiComposableUiScene {
    let root = cjguiComposableVertical(920000, "card-grid-test-root",
        CjguiComposableUiStyle(growX: 1, growY: 1))
    root.add(cjguiComposableVariableHeightList(920001, "card-grid-test-list", 920002,
        source, state, 60, 10, 2, CjguiComposableUiStyle(fixedHeight: 300, growX: 1)))
    let rect = CjguiComposableUiRect(0, 0, 400, 300)
    let registry = CjguiComposableUiIdentityRegistry()
    if (!registry.beginCandidate()) {
        return CjguiComposableUiLayoutEngine.layout(root, rect, version)
    }
    let _ = registry.resolveCandidate(root)
    let _ = registry.replaceCandidateRoot(root)
    let scene = CjguiComposableUiLayoutEngine.layoutWithMetrics(root, rect, version,
        CjguiComposableUiFallbackTextMeasurer(), identityRegistry: Some(registry)).scene
    let _ = registry.prepareCandidate()
    return scene
}

@Test
func cardGridColumnsTailAndReflowKeepItemIdentity(): Unit {
    let base = CardGridTestSource(10)
    let recorder = CardGridTestRecorder()
    let grid = CjguiComposableUiCardGridSource(base, "grid-contract",
        CjguiComposableUiCardGridSpec(100, 60, columnGap: 10, rowGap: 10),
        { item, context =>
            recorder.builtKeys.add(context.key)
            let card = cjguiComposableVertical(-1, "simple-card-${item.key}",
                CjguiComposableUiStyle(fixedWidth: context.cardWidth, fixedHeight: context.cardHeight,
                    padding: 4, background: CjguiComposableUiColor(1.0, 1.0, 1.0, 1.0)),
                identity: Some(context.identity.local("card")))
            card.add(cjguiComposableText(-1, "simple-card-title-${item.key}", item.title,
                CjguiComposableUiStyle(fixedHeight: 50, textColor: CjguiComposableUiColor(0.1, 0.1, 0.1, 1.0)),
                identity: Some(context.identity.local("title"))))
            card
        })
    @Assert(grid.setAvailableWidth(430), true)
    @Assert(grid.columns(), 4)
    @Assert(grid.cardWidth(), 100)
    @Assert(grid.rowCount(), 3)
    @Assert(grid.indexForKey(grid.rowKeyForItem("item_7")), 1)
    // Tail row keeps four rectangular slots but builds only the two real cards.
    recorder.builtKeys.clear()
    let tail = grid.buildRow(grid.itemAt(2), false, false)
    @Assert(tail.children().size, 4)
    @Assert(recorder.builtKeys.size, 2)
    @Assert(recorder.builtKeys[0], "item_8")
    @Assert(recorder.builtKeys[1], "item_9")

    // Narrowing reflows the same business items; the key-to-row mapping moves,
    // the item keys do not.
    @Assert(grid.setAvailableWidth(290), true)
    @Assert(grid.columns(), 2)
    @Assert(grid.cardWidth(), 140)
    @Assert(grid.rowCount(), 5)
    @Assert(grid.indexForKey(grid.rowKeyForItem("item_7")), 3)
    @Assert(grid.itemKeyForRowStart(3), "item_6")
    recorder.builtKeys.clear()
    let reflowed = grid.buildRow(grid.itemAt(3), false, false)
    @Assert(reflowed.children().size, 2)
    @Assert(recorder.builtKeys, ArrayList<String>(["item_6", "item_7"]))
    @Assert(grid.setAvailableWidth(120), true)
    @Assert(grid.columns(), 1)
    @Assert(grid.cardWidth(), 120)
    @Assert(grid.rowCount(), 10)
}

@Test
func cardGridBusinessKeyThatLooksLikeInternalRowKeyUsesBasePosition(): Unit {
    let trapKey = "cjgui.grid.grid-trap.row.1"
    let base = CardGridKeyedSource(["first", trapKey, "third", "fourth"])
    let recorder = CardGridTestRecorder()
    let grid = CjguiComposableUiCardGridSource(base, "grid-trap",
        CjguiComposableUiCardGridSpec(100, 60, columnGap: 10, rowGap: 10),
        { item, context =>
            recorder.builtKeys.add(context.key)
            recorder.builtCards += 1
            cjguiComposableText(-1, "trap-card-${context.key}", item.title,
                CjguiComposableUiStyle(fixedWidth: context.cardWidth, fixedHeight: context.cardHeight,
                    padding: 4, textColor: CjguiComposableUiColor(0.1, 0.1, 0.1, 1.0)),
                identity: Some(context.identity.local("label")))
        })
    @Assert(grid.setAvailableWidth(210), true)
    @Assert(grid.columns(), 2)

    // The business key is byte-for-byte the internal row key for row 1.
    // Business lookup must use base position (index 1 -> row 0), never the
    // row-key syntax of the string.
    let mappedRowKey = grid.rowKeyForItem(trapKey)
    @Assert(mappedRowKey, "cjgui.grid.grid-trap.row.0")
    @Assert(grid.indexForKey(mappedRowKey), 0)

    let row = grid.buildRow(grid.itemAt(0), false, false)
    @Assert(row.children().size, 2)
    @Assert(recorder.builtKeys, ArrayList<String>(["first", trapKey]))
    @Assert(grid.lastIdentityIssue(), "")
}

private func cardGridFixedKey(byteCount: Int64): String {
    let builder = StringBuilder()
    var index: Int64 = 0
    while (index < byteCount) {
        builder.append("k")
        index += 1
    }
    return builder.toString()
}

@Test
func cardGridIdentityLengthBoundaryAcceptsOrRefusesExplicitly(): Unit {
    let acceptedKey = cardGridFixedKey(48)
    let rejectedKey = cardGridFixedKey(49)
    var acceptedToken = ""
    if (let Some(token) <- CjguiComposableUiCardGridIdentity.tokenForItem(acceptedKey)) {
        acceptedToken = token
    }
    @Assert(acceptedToken.size, CjguiComposableUiCardGridIdentity.MAXIMUM_TOKEN_CHARS)
    @Assert(CjguiComposableUiCardGridIdentity.issueForItem(acceptedKey), "")
    @Assert(CjguiComposableUiCardGridIdentity.tokenForItem(rejectedKey).isNone(), true)
    @Assert(CjguiComposableUiCardGridIdentity.issueForItem(rejectedKey),
        CjguiComposableUiCardGridIdentity.ISSUE_KEY_TOO_LONG)

    let base = CardGridKeyedSource([acceptedKey, rejectedKey, "legal-after"])
    let recorder = CardGridTestRecorder()
    let grid = CjguiComposableUiCardGridSource(base, "grid-identity-boundary",
        CjguiComposableUiCardGridSpec(100, 60, columnGap: 10, rowGap: 10),
        { item, context =>
            recorder.builtCards += 1
            cjguiComposableText(-1, "identity-card-${item.resourceId}", item.title,
                CjguiComposableUiStyle(fixedWidth: context.cardWidth, fixedHeight: context.cardHeight,
                    padding: 4, textColor: CjguiComposableUiColor(0.1, 0.1, 0.1, 1.0)),
                identity: Some(context.identity.local("label")))
        })
    @Assert(grid.setAvailableWidth(100), true)
    @Assert(grid.columns(), 1)
    let acceptedRow = grid.buildRow(grid.itemAt(0), false, false)
    @Assert(recorder.builtCards, 1)
    @Assert(acceptedRow.children().size, 1)
    @Assert(grid.lastIdentityIssue(), "")

    // A 49-byte key is refused by name. Its slot carries an invalid identity;
    // it must not become a valid placeholder or a hash-derived card.
    let rejectedRow = grid.buildRow(grid.itemAt(1), false, false)
    @Assert(recorder.builtCards, 1)
    @Assert(rejectedRow.children().size, 1)
    @Assert(grid.lastIdentityIssue(), CjguiComposableUiCardGridIdentity.ISSUE_KEY_TOO_LONG)
    @Assert(grid.identityIssueForKey(rejectedKey),
        CjguiComposableUiCardGridIdentity.ISSUE_KEY_TOO_LONG)
    let legalRow = grid.buildRow(grid.itemAt(2), false, false)
    @Assert(recorder.builtCards, 2)

    // 48B goes through the real candidate transaction and commits.
    let registry = CjguiComposableUiIdentityRegistry()
    let acceptedRoot = cjguiComposableVertical(930100, "identity-accepted-root",
        CjguiComposableUiStyle(growX: 1, growY: 1))
    acceptedRoot.add(acceptedRow)
    @Assert(registry.beginCandidate(), true)
    @Assert(registry.resolveCandidate(acceptedRoot), "")
    @Assert(registry.prepareCandidate(), true)
    registry.commitCandidate()
    let acceptedCount = registry.liveCount()
    @Assert(acceptedCount > 0, true)

    // The rejected candidate contains a legal row after the invalid one, but
    // still fails candidate resolution. Rolling back preserves the accepted
    // identity mapping; no empty-slot candidate is accepted.
    let rejectedRoot = cjguiComposableVertical(930101, "identity-rejected-root",
        CjguiComposableUiStyle(growX: 1, growY: 1))
    rejectedRoot.add(rejectedRow)
    rejectedRoot.add(legalRow)
    @Assert(registry.beginCandidate(), true)
    @Assert(registry.resolveCandidate(rejectedRoot), "identity_invalid_scope_or_key")
    @Assert(registry.prepareCandidate(), false)
    registry.rollbackCandidate()
    @Assert(registry.liveCount(), acceptedCount)
    @Assert(registry.candidateCount(), 0)
}

@Test
func cardGridReflowRevealsPreviousTopBusinessItem(): Unit {
    let base = CardGridTestSource(100)
    let grid = CjguiComposableUiCardGridSource(base, "grid-reflow-anchor",
        CjguiComposableUiCardGridSpec(100, 60, columnGap: 10, rowGap: 10),
        { item, context =>
            cjguiComposableText(-1, "reflow-card-${item.key}", item.title,
                CjguiComposableUiStyle(fixedWidth: context.cardWidth, fixedHeight: context.cardHeight,
                    padding: 4, textColor: CjguiComposableUiColor(0.1, 0.1, 0.1, 1.0)),
                identity: Some(context.identity.local("label")))
        })
    @Assert(grid.setAvailableWidth(430), true)
    let state = CjguiComposableUiVirtualListState()
    let _ = cardGridTestScene(grid, state, 1)
    state.scrollByViewport("next")
    let _ = cardGridTestScene(grid, state, 2)
    let start = state.materializedStart()
    @Assert(start > 0, true)
    let anchor = grid.itemKeyForRowStart(start)
    @Assert(anchor.size > 0, true)

    // The consumer re-anchors with the previous top business item, then the
    // existing variable-list reveal resolves its CURRENT row key.
    @Assert(grid.setAvailableWidth(290), true)
    let anchorRowKey = grid.rowKeyForItem(anchor)
    @Assert(anchorRowKey.size > 0, true)
    @Assert(state.revealKey(grid, anchorRowKey), true)
    let _ = cardGridTestScene(grid, state, 3)
    @Assert(state.materializedStart(), grid.indexForKey(anchorRowKey))
    @Assert(grid.itemKeyForRowStart(state.materializedStart()), anchor)
}

@Test
func cardGridNavigationUsesCurrentOrderAndKeepsHiddenSelection(): Unit {
    let base = CardGridTestSource(10)
    let order = CjguiComposableUiFlatCollectionOrder(base, { item => item.resourceId >= 0 })
    let selection = CjguiComposableUiCollectionSelection()
    selection.click("item_5", false, false, order)
    @Assert(CjguiComposableUiCardGridNavigation.targetKey(order, "item_5", "left", 4), "item_4")
    @Assert(CjguiComposableUiCardGridNavigation.targetKey(order, "item_5", "right", 4), "item_6")
    @Assert(CjguiComposableUiCardGridNavigation.targetKey(order, "item_5", "up", 4), "item_1")
    @Assert(CjguiComposableUiCardGridNavigation.targetKey(order, "item_5", "down", 4), "item_9")
    @Assert(CjguiComposableUiCardGridNavigation.targetKey(order, "item_5", "home", 4), "item_0")
    @Assert(CjguiComposableUiCardGridNavigation.targetKey(order, "item_5", "end", 4), "item_9")
    // Shift extends over the current row-major order.
    selection.click("item_2", false, false, order)
    selection.moveFocus("item_9", true, order)
    @Assert(selection.selectedCount(), 8)
    // Filtering hides the selected keys but does not remove them.
    let filtered = CjguiComposableUiFilteredListSource(base, { item => item.title })
    @Assert(filtered.setQuery("item 5"), true)
    let filteredOrder = CjguiComposableUiFlatCollectionOrder(filtered, { item => item.resourceId >= 0 })
    @Assert(filteredOrder.count(), 1)
    @Assert(selection.hiddenCount(filteredOrder), 7)
    @Assert(selection.selectedCount(), 8)
}

@Test
func cardGridMaterializesOnlyVisibleRowsWithDifferentContent(): Unit {
    let base = CardGridTestSource(200)
    let recorder = CardGridTestRecorder()
    let grid = CjguiComposableUiCardGridSource(base, "grid-materialization",
        CjguiComposableUiCardGridSpec(100, 60, columnGap: 10, rowGap: 10),
        { item, context =>
            recorder.builtCards += 1
            cjguiComposableText(-1, "materialized-card-${item.key}", item.title,
                CjguiComposableUiStyle(fixedWidth: context.cardWidth, fixedHeight: context.cardHeight,
                    padding: 4, textColor: CjguiComposableUiColor(0.1, 0.1, 0.1, 1.0)),
                identity: Some(context.identity.local("label")))
        })
    @Assert(grid.setAvailableWidth(400), true)
    @Assert(grid.columns(), 3)
    @Assert(grid.rowCount(), 67)
    let scene = cardGridTestScene(grid, CjguiComposableUiVirtualListState(), 1)
    @Assert(scene.nodes().size > 0, true)
    @Assert(recorder.builtCards > 0, true)
    @Assert(recorder.builtCards < 60, true)
    @Assert(recorder.builtCards < 200, true)
}

@Test
func cardViewModeUsesExistingViewStateEntryAndRejectsUnknownMode(): Unit {
    let domain = CjguiRuleSetEditingDomain.newUntitled()
    cardModeCreateRule(domain, "Card A", 10, "card-mode-1")
    let controller = CjguiRuleSetComposableController(domain)
    let view = controller.collectionViewState()
    let arguments = ArrayList<CjguiSharedOperationActionArgument>([
        CjguiSharedOperationActionArgument("mode", CjguiSharedOperationValue.string("grid"))
    ])
    let setGrid = domain.executeFromExternal(CjguiSharedOperationActionInvocation(
        "SET_COLLECTION_VIEW_MODE", view.revision(),
        ArrayList<Int64>([CjguiRuleSetEditingDomain.ruleSetResourceId]), arguments))
    @Assert(setGrid.applied, true)
    @Assert(setGrid.reason, "view_mode_set")
    @Assert(view.mode(), "grid")
    let unknownArguments = ArrayList<CjguiSharedOperationActionArgument>([
        CjguiSharedOperationActionArgument("mode", CjguiSharedOperationValue.string("cards"))
    ])
    let unknown = domain.executeFromExternal(CjguiSharedOperationActionInvocation(
        "SET_COLLECTION_VIEW_MODE", view.revision(),
        ArrayList<Int64>([CjguiRuleSetEditingDomain.ruleSetResourceId]), unknownArguments))
    @Assert(unknown.applied, false)
    @Assert(unknown.reason, "unknown_view_mode")
    @Assert(view.mode(), "grid")
}

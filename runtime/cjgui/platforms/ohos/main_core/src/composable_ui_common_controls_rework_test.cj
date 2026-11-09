// Focused regressions for the common Select rework: bounded identities,
// in-layer initial focus, guarded confirmation, query-only filtering and the
// previously ignored row/minimumThumb geometry. These tests exercise component
// state directly; the real keyboard/AX chain is verified on the app candidate.

package cjgui

import std.collection.*

private func testFindNode(root: CjguiComposableUiNode, semanticId: String): ?CjguiComposableUiNode {
    if (root.semanticId == semanticId) { return Some(root) }
    for (child in root.children()) {
        if (let Some(found) <- testFindNode(child, semanticId)) { return Some(found) }
    }
    return None
}

private func testOptions(): ArrayList<CjguiSelectOption> {
    let items = ArrayList<CjguiSelectOption>()
    items.add(CjguiSelectOption("single", "单面", "false"))
    items.add(CjguiSelectOption("double", "双面", "true"))
    return items
}

@Test
func testCommonSelectIdentityIsBoundedAndDistinct(): Unit {
    let dotted = cjguiCommonControlKey(".")
    let literal = cjguiCommonControlKey("_46")
    @Assert(dotted != literal)
    let prefix = "this-is-a-long-stable-business-key-that-is-identical-"
    let first = cjguiCommonControlKey(prefix + "alpha")
    let second = cjguiCommonControlKey(prefix + "beta")
    @Assert(first != second)
    @Assert(first.size <= 64)
    @Assert(cjguiCommonControlKey(prefix + "alpha") == first)
    let select = CjguiSelect("identity-test", "identity-select")
    let items = ArrayList<CjguiSelectOption>()
    items.add(CjguiSelectOption(".", "点", "dot"))
    items.add(CjguiSelectOption("_46", "下划线", "u46"))
    @Assert(select.optionIssue(items) == "")
}

@Test
func testCommonSelectConfirmRejectsCollisionProneDerivedIdentity(): Unit {
    let select = CjguiSelect("collision-test", "collision-select")
    let items = ArrayList<CjguiSelectOption>()
    items.add(CjguiSelectOption("a.b", "一", "1"))
    items.add(CjguiSelectOption("a_b", "二", "2"))
    // Distinct hashes keep both; the old encoder would map both to a_b.
    @Assert(select.optionIssue(items) == "")
    select.update(items, "")
    @Assert(select.open())
    @Assert(select.confirmKey("a.b"))
    @Assert(select.takeConfirmed().getOrThrow().value == "1")
}

@Test
func testCommonSelectInitialFocusIsInsidePopup(): Unit {
    let select = CjguiSelect("focus-test", "focus-select")
    select.update(testOptions(), "false")
    @Assert(select.open())
    let scene = select.attachTo(cjguiComposableVertical(-1, "base", CjguiComposableUiStyle()))
    let popup = testFindNode(scene, "focus-select-popup").getOrThrow()
    let reference = popup.layerInitialFocusReference().getOrThrow()
    let identity = reference.scopedIdentity().getOrThrow()
    @Assert(identity.localKey(), "option-${cjguiCommonControlKey("single")}")
    // The highlighted row exists in the same popup layer.
    @Assert(testFindNode(popup, "focus-select-option-${cjguiCommonControlKey("single")}").isSome())
}

@Test
func testCommonSelectEmptyAndAllDisabledCanCancel(): Unit {
    let empty = CjguiSelect("empty-test", "empty-select")
    empty.update(ArrayList<CjguiSelectOption>(), "")
    @Assert(empty.open())
    let emptyScene = empty.attachTo(cjguiComposableVertical(-1, "base", CjguiComposableUiStyle()))
    let emptyPopup = testFindNode(emptyScene, "empty-select-popup").getOrThrow()
    @Assert(emptyPopup.layerInitialFocusReference().getOrThrow().scopedIdentity().getOrThrow().localKey(), "cancel")
    @Assert(empty.commands().size, 1)
    @Assert(empty.commands()[0].id, "cjgui-select-empty-test-escape")
    empty.close()
    @Assert(!empty.isOpen())

    let all = CjguiSelect("all-test", "all-select")
    let items = ArrayList<CjguiSelectOption>()
    items.add(CjguiSelectOption("one", "一", "1", enabled: false))
    items.add(CjguiSelectOption("two", "二", "2", enabled: false))
    all.update(items, "")
    @Assert(all.open())
    let allScene = all.attachTo(cjguiComposableVertical(-1, "base", CjguiComposableUiStyle()))
    let allPopup = testFindNode(allScene, "all-select-popup").getOrThrow()
    @Assert(allPopup.layerInitialFocusReference().getOrThrow().scopedIdentity().getOrThrow().localKey(), "cancel")
    @Assert(!all.confirmHighlighted())
    @Assert(all.commands().size, 1)
    all.close()
}

@Test
func testCommonSelectReadOnlyAndDisabledRejectThenRecover(): Unit {
    let select = CjguiSelect("guard-test", "guard-select")
    select.update(testOptions(), "false")
    @Assert(select.open())
    select.update(testOptions(), "false", readOnly: true)
    @Assert(!select.confirmHighlighted())
    @Assert(!select.confirmKey("double"))
    @Assert(select.isOpen())
    select.update(testOptions(), "false", enabled: false)
    @Assert(!select.confirmKey("double"))
    @Assert(select.isOpen())
    select.update(testOptions(), "false")
    @Assert(select.confirmKey("double"))
    let confirmed = select.takeConfirmed().getOrThrow()
    @Assert(confirmed.key, "double")
    @Assert(confirmed.value, "true")
    @Assert(!select.isOpen())
}

@Test
func testCommonSelectRemovedDisabledAndReorderedHighlightRepairs(): Unit {
    let select = CjguiSelect("repair-test", "repair-select")
    select.update(testOptions(), "false")
    @Assert(select.open())
    @Assert(select.highlightedKey(), "single")
    @Assert(select.moveHighlight("down"))
    @Assert(select.highlightedKey(), "double")
    let disabled = ArrayList<CjguiSelectOption>()
    disabled.add(CjguiSelectOption("single", "单面", "false"))
    disabled.add(CjguiSelectOption("double", "双面", "true", enabled: false))
    select.update(disabled, "false")
    @Assert(select.highlightedKey(), "single")
    @Assert(!select.confirmKey("double"))
    let removed = ArrayList<CjguiSelectOption>()
    removed.add(CjguiSelectOption("double", "双面", "true"))
    select.update(removed, "false")
    @Assert(select.highlightedKey(), "double")
    @Assert(select.confirmKey("double"))
    @Assert(select.takeConfirmed().getOrThrow().key, "double")

    let reorder = CjguiSelect("reorder-test", "reorder-select")
    reorder.update(testOptions(), "false")
    @Assert(reorder.open())
    let before = reorder.commands()[0].targetReference.scopedIdentity().getOrThrow().localKey()
    let reversed = ArrayList<CjguiSelectOption>()
    reversed.add(CjguiSelectOption("double", "双面", "true"))
    reversed.add(CjguiSelectOption("single", "单面", "false"))
    reorder.update(reversed, "false")
    let after = reorder.commands()[0].targetReference.scopedIdentity().getOrThrow().localKey()
    @Assert(before, after)
}

@Test
func testCommonSelectSearchFiltersButOnlyConfirmWrites(): Unit {
    let select = CjguiSelect("search-test", "search-select")
    select.update(testOptions(), "false", searchable: true)
    @Assert(select.open())
    select.setQuery("双")
    @Assert(select.visibleOptions().size, 1)
    @Assert(select.visibleOptions()[0].key, "double")
    @Assert(select.highlightedKey(), "double")
    // A key hidden by the query cannot be confirmed.
    @Assert(!select.confirmKey("single"))
    select.setQuery("单")
    @Assert(select.query(), "单")
    @Assert(select.confirmHighlighted())
    @Assert(select.takeConfirmed().getOrThrow().value, "false")
    @Assert(!select.isOpen())
}

@Test
func testCommonSelectOutsidePointerDismissesFromCoveredSurface(): Unit {
    let select = CjguiSelect("outside-test", "outside-select")
    select.update(testOptions(), "false")
    @Assert(select.open())
    let scene = select.attachTo(cjguiComposableVertical(-1, "base", CjguiComposableUiStyle()))
    let guard = testFindNode(scene, "outside-select-outside-guard").getOrThrow()
    @Assert(guard.nodeKind, CJGUI_COMPOSABLE_UI_LAYER_BACKDROP)
    let bounds = CjguiComposableUiRect(0, 0, 400, 300)
    let guardLayout = CjguiComposableUiLayoutNode(guard, bounds, bounds,
        inputScopeId: "cjgui-select-outside-test-outside")
    let press = CjguiComposableUiEvent(guardLayout, 37, "", 0, 0, 1)
    @Assert(select.applyUiEvent(press).getOrThrow().didApply)
    @Assert(!select.isOpen())
    @Assert(select.takeConfirmed().isNone())
    // Once closed the guard is gone; the same pointer intent is not consumed.
    @Assert(select.applyUiEvent(press).isNone())
}

@Test
func testCommonSelectRowStyleAndThumbApply(): Unit {
    let select = CjguiSelect("style-test", "style-select")
    select.update(testOptions(), "false",
        style: CjguiSelectStyle(row: CjguiComposableUiStyle(fixedHeight: 44, growX: 1, padding: 2)))
    @Assert(select.open())
    let scene = select.attachTo(cjguiComposableVertical(-1, "base", CjguiComposableUiStyle()))
    let row = testFindNode(scene, "style-select-option-${cjguiCommonControlKey("single")}").getOrThrow()
    @Assert(row.style.fixedHeight, 44)
    // The keyboard highlight must reach paint: owner bits keep only
    // SELECTED/CHECKED, so the highlighted row travels as selected paint.
    @Assert((row.ownerInteractionState & CjguiComposableUiInteractionState.SELECTED) != 0)
    let other = testFindNode(scene, "style-select-option-${cjguiCommonControlKey("double")}").getOrThrow()
    @Assert((other.ownerInteractionState & CjguiComposableUiInteractionState.SELECTED) == 0)
    @Assert(other.semanticSelected, false)
    let bar = cjguiComposableScrollBar(77, "bar", CjguiComposableUiScrollViewport(), 10,
        style: CjguiScrollbarStyle(minimumThumb: 40))
    @Assert(bar.pointerControlHandleThickness, 40)
}

@Test
func testCommonSelectShortcutTextSeparatesNavigationConfirmAndCancel(): Unit {
    let select = CjguiSelect("shortcut-test", "shortcut-select")
    select.update(testOptions(), "false")
    @Assert(select.open())
    let scene = select.attachTo(cjguiComposableVertical(-1, "base", CjguiComposableUiStyle()))
    let row = testFindNode(scene, "shortcut-select-option-${cjguiCommonControlKey("single")}").getOrThrow()
    let bounds = CjguiComposableUiRect(0, 0, 120, 30)
    let triggerEvent = CjguiComposableUiEvent(
        CjguiComposableUiLayoutNode(select.trigger(), bounds, bounds), 27, "", 0, 0, 1)
    let rowLayout = CjguiComposableUiLayoutNode(row, bounds, bounds, inputScopeId: select.layer())
    // A mouse/AX row activation carries no shortcut text and writes at once.
    let click = CjguiComposableUiEvent(rowLayout, 27, "", 0, 0, 1)
    @Assert(select.applyUiEvent(click).getOrThrow().didApply)
    @Assert(select.takeConfirmed().getOrThrow().key, "single")
    @Assert(!select.isOpen())
    // The renderer stamps the declared shortcut on command activation so
    // shared targets can distinguish arrows from confirmation.
    @Assert(select.applyUiEvent(triggerEvent).getOrThrow().didApply)
    @Assert(select.isOpen())
    @Assert(select.applyUiEvent(CjguiComposableUiEvent(
        rowLayout, 27, "shortcut:down", 0, 0, 1)).getOrThrow().didApply)
    @Assert(select.highlightedKey(), "double")
    @Assert(select.applyUiEvent(CjguiComposableUiEvent(
        rowLayout, 27, "shortcut:escape", 0, 0, 1)).getOrThrow().didApply)
    @Assert(!select.isOpen())
    @Assert(select.takeConfirmed().isNone())
    @Assert(select.applyUiEvent(CjguiComposableUiEvent(
        triggerEvent.node, 27, "", 0, 0, 1)).getOrThrow().didApply)
    @Assert(select.isOpen())
    select.update(testOptions(), "false", readOnly: true)
    @Assert(!select.applyUiEvent(CjguiComposableUiEvent(
        rowLayout, 27, "shortcut:enter", 0, 0, 1)).getOrThrow().didApply)
    @Assert(select.isOpen())
    @Assert(select.takeConfirmed().isNone())
}

@Test
func testCommonTooltipIdentitySeparatesAnchorsSharingAnAction(): Unit {
    let tooltip = CjguiTooltip("tip-test", "tip")
    let a = cjguiComposableButton(-1, "anchor-a", "帮助 A", "OPEN_HELP", 0, CjguiComposableUiStyle())
    let b = cjguiComposableButton(-1, "anchor-b", "帮助 B", "OPEN_HELP", 0, CjguiComposableUiStyle())
    let _ = tooltip.bind(a, "A 的帮助", reference: CjguiComposableUiNodeReference.manual(1))
    let bounds = CjguiComposableUiRect(0, 0, 80, 28)
    let aLayout = CjguiComposableUiLayoutNode(a, bounds, bounds)
    let bLayout = CjguiComposableUiLayoutNode(b, bounds, bounds)
    // The same business action on another anchor neither opens nor keeps this
    // anchor's help.
    @Assert(tooltip.applyUiEvent(CjguiComposableUiEvent(bLayout, 43, "", 0, 0, 1)).isNone())
    @Assert(!tooltip.isOpen())
    @Assert(tooltip.applyUiEvent(CjguiComposableUiEvent(
        aLayout, 43, "", 0, 0, 2)).getOrThrow().didApply)
    @Assert(tooltip.isOpen())
    @Assert(tooltip.applyUiEvent(CjguiComposableUiEvent(bLayout, 44, "", 0, 0, 3)).isNone())
    @Assert(tooltip.isOpen())
    // Focusing the other instance replaces the help instead of leaving the
    // previous anchor's popup attached.
    @Assert(tooltip.applyUiEvent(CjguiComposableUiEvent(
        bLayout, 31, "", 0, 0, 4)).getOrThrow().didApply)
    @Assert(!tooltip.isOpen())
}

@Test
func testGeneratedFieldDeclaredSelectInputKindWins(): Unit {
    let spec = CjguiGeneratedUiFieldSpec("duplex", "双面打印", "BOOLEAN", 6203,
        declaredInputKind: "select")
    @Assert(spec.inputKind(), "select")
    // The writer stays the field's own transaction, never the select's.
    @Assert(spec.writeActionName, "EDIT_DRAFT_BOOLEAN")
    let plain = CjguiGeneratedUiFieldSpec("duplex", "双面打印", "BOOLEAN", 6203)
    @Assert(plain.inputKind(), "booleanInput")
}

@Test
func testCommonSelectAnchorsToTheActuallyActivatedPresentation(): Unit {
    // Generated-only mount: the factory trigger carries an allocated node id.
    // Opening must anchor and return THERE, not at the handwritten scoped
    // trigger that was never built in such a window.
    let select = CjguiSelect("anchor-test", "anchor-select")
    select.update(testOptions(), "false")
    let generatedTrigger = select.trigger(nodeId: 771, semanticId: "gen-node-771")
    let bounds = CjguiComposableUiRect(0, 0, 120, 30)
    let generatedLayout = CjguiComposableUiLayoutNode(generatedTrigger, bounds, bounds)
    @Assert(select.applyUiEvent(CjguiComposableUiEvent(generatedLayout, 27, "", 0, 0, 1)).getOrThrow().didApply)
    @Assert(select.isOpen())
    let generatedScene = select.attachTo(cjguiComposableVertical(-1, "base", CjguiComposableUiStyle()))
    let generatedPopup = testFindNode(generatedScene, "anchor-select-popup").getOrThrow()
    let generatedAnchor = generatedPopup.layerAnchorReference().getOrThrow()
    @Assert(generatedAnchor.manualNodeId(), 771)
    select.close()

    // Handwritten activation (node id -1) keeps the scoped trigger anchor, so
    // a dual-presentation field anchors at whichever instance was activated.
    let manual = select.trigger()
    let manualLayout = CjguiComposableUiLayoutNode(manual, bounds, bounds)
    @Assert(select.applyUiEvent(CjguiComposableUiEvent(manualLayout, 27, "", 0, 0, 2)).getOrThrow().didApply)
    @Assert(select.isOpen())
    let manualScene = select.attachTo(cjguiComposableVertical(-1, "base", CjguiComposableUiStyle()))
    let manualPopup = testFindNode(manualScene, "anchor-select-popup").getOrThrow()
    let manualAnchor = manualPopup.layerAnchorReference().getOrThrow()
    @Assert(manualAnchor.scopedIdentity().getOrThrow().localKey(), "trigger")

    // Programmatic open defaults to the presentation built LAST, which in a
    // generated-only window is the generated node, never a hidden manual one.
    let _ = select.trigger(nodeId: 772, semanticId: "gen-node-772")
    select.close()
    @Assert(select.open())
    let defaultScene = select.attachTo(cjguiComposableVertical(-1, "base", CjguiComposableUiStyle()))
    let defaultPopup = testFindNode(defaultScene, "anchor-select-popup").getOrThrow()
    @Assert(defaultPopup.layerAnchorReference().getOrThrow().manualNodeId(), 772)

    // A scoped registry id is NOT a manual reference: a handwritten trigger
    // whose accepted node carries a virtual identity id keeps the scoped
    // anchor instead of an unresolvable manual one.
    let virtualNode = CjguiComposableUiNode(CJGUI_COMPOSABLE_UI_FIRST_SCOPED_NODE_ID + 7,
        "anchor-select-trigger", 6, "双面  ▾", "", "anchor-select-toggle", 0, CjguiComposableUiStyle())
    let virtualLayout = CjguiComposableUiLayoutNode(virtualNode, bounds, bounds)
    select.close()
    @Assert(select.applyUiEvent(CjguiComposableUiEvent(virtualLayout, 27, "", 0, 0, 3)).getOrThrow().didApply)
    @Assert(select.isOpen())
    let virtualScene = select.attachTo(cjguiComposableVertical(-1, "base", CjguiComposableUiStyle()))
    let virtualPopup = testFindNode(virtualScene, "anchor-select-popup").getOrThrow()
    @Assert(virtualPopup.layerAnchorReference().getOrThrow().scopedIdentity().getOrThrow().localKey(), "trigger")
}


@Test
func testCommonSelectDualPresentationAttachesOnePopup(): Unit {
    // A handwritten trigger and a generated select can present the same field
    // controller in one window. The generated region attaches the popup first;
    // the window-level attach must not declare a second host identity.
    let select = CjguiSelect("dual-attach", "dual-attach-select")
    select.update(testOptions(), "false")
    @Assert(select.open())
    let once = select.attachTo(cjguiComposableVertical(-1, "base", CjguiComposableUiStyle()))
    @Assert(once.semanticId, "dual-attach-select-host")
    let twice = select.attachTo(once)
    @Assert(twice.semanticId, "dual-attach-select-host")
    @Assert(testCountNode(twice, "dual-attach-select-popup"), 1)
    select.close()
    let closed = select.attachTo(cjguiComposableVertical(-1, "base", CjguiComposableUiStyle()))
    @Assert(closed.semanticId, "base")
}

private func testCountNode(root: CjguiComposableUiNode, semanticId: String): Int64 {
    var count: Int64 = if (root.semanticId == semanticId) { 1 } else { 0 }
    for (child in root.children()) {
        count += testCountNode(child, semanticId)
    }
    return count
}

private func testFindChoiceRow(root: CjguiComposableUiNode, action: String): ?CjguiComposableUiNode {
    if (root.actionName == action) { return Some(root) }
    for (child in root.children()) {
        if (let Some(found) <- testFindChoiceRow(child, action)) { return Some(found) }
    }
    return None
}

private func longTestOptions(): ArrayList<CjguiSelectOption> {
    let items = ArrayList<CjguiSelectOption>()
    var index = 0
    while (index < 12) {
        items.add(CjguiSelectOption("opt-${index}", "选项 ${index}", "${index}"))
        index += 1
    }
    return items
}

@Test
func testCommonSelectRevealOnlyForOpenNavigationAndRepair(): Unit {
    let select = CjguiSelect("reveal-test", "reveal-select")
    select.update(longTestOptions(), "0")
    @Assert(select.open())
    let _ = select.attachTo(cjguiComposableVertical(-1, "base", CjguiComposableUiStyle()))
    let viewport = select.revealViewportProbe().getOrThrow()
    // Simulate the accepted layout: 12 rows of content, a short viewport.
    viewport.stageExtents(12 * 30, 100, 0)
    viewport.commitStagedExtents()
    // The user scrolls far away from the highlight.
    @Assert(viewport.requestOffset(240))
    viewport.stageExtents(12 * 30, 100, 240)
    viewport.commitStagedExtents()
    @Assert(viewport.offset(), 240)
    // An unrelated owner refresh (same facts) must not pull the viewport back.
    select.update(longTestOptions(), "0")
    let _ = select.attachTo(cjguiComposableVertical(-1, "base", CjguiComposableUiStyle()))
    @Assert(viewport.offset(), 240)
    @Assert(!viewport.hasPendingRequest())
    // Keyboard navigation arms the reveal again; the highlight row comes back.
    @Assert(select.moveHighlight("down"))
    @Assert(select.highlightedKey(), "opt-1")
    let _ = select.attachTo(cjguiComposableVertical(-1, "base", CjguiComposableUiStyle()))
    @Assert(viewport.hasPendingRequest())
    viewport.stageExtents(12 * 30, 100, 0)
    viewport.commitStagedExtents()
    // Scrolling away again, then disabling the highlighted option is the ONE
    // refresh-sourced reason to repair and reveal.
    @Assert(viewport.requestOffset(240))
    viewport.stageExtents(12 * 30, 100, 240)
    viewport.commitStagedExtents()
    @Assert(viewport.offset(), 240)
    var repaired = longTestOptions()
    repaired[1] = CjguiSelectOption("opt-1", "选项 1", "1", enabled: false)
    select.update(repaired, "0")
    @Assert(select.highlightedKey(), "opt-0")
    let _ = select.attachTo(cjguiComposableVertical(-1, "base", CjguiComposableUiStyle()))
    @Assert(viewport.hasPendingRequest())
}

private class TestChoiceWriteCounter {
    var lastValue: String = ""
    var refusedCount: Int64 = 0
}

@Test
func testChoiceBindingSharesFactsAndCommitsAcrossPresentations(): Unit {
    let counter = TestChoiceWriteCounter()
    let binding = CjguiSelectFieldBinding("duplex", "share-test", "share-duplex",
        ArrayList<CjguiSelectOption>([
            CjguiSelectOption("single", "单面", "false"),
            CjguiSelectOption("double", "双面", "true")]),
        commit: { option =>
            counter.lastValue = option.value
            return true
        })
    binding.declare("false", error: "示例错误")
    @Assert(binding.fieldError(), "示例错误")
    // The error fact reaches the shared select projection.
    @Assert(binding.select.trigger().semanticHelp, "示例错误")

    // All three presentations exist for ONE field and share the declared facts.
    binding.declare("true")
    @Assert(binding.currentValue(), "true")
    @Assert(binding.select.currentValue(), "true")
    @Assert(binding.fieldError(), "")

    // A radio row activation stages the SAME stable-key confirmation the
    // select uses, and the binding's shared commit is the one owner write.
    let radioGroupNode = binding.radioGroupNode("share-radio", "share-duplex-radio")
    let row = testFindChoiceRow(radioGroupNode, "share-duplex-radio-choose:single").getOrThrow()
    let bounds = CjguiComposableUiRect(0, 0, 120, 30)
    let routed = binding.applyUiEvent(CjguiComposableUiEvent(
        CjguiComposableUiLayoutNode(row, bounds, bounds), 27, "", 0, 0, 1))
    @Assert(routed.getOrThrow().didApply)
    let option = binding.takeConfirmed().getOrThrow()
    @Assert(option.key, "single")
    @Assert(binding.commit(option), true)
    @Assert(counter.lastValue, "false")
    // Nothing else is pending afterwards.
    @Assert(binding.takeConfirmed().isNone())
}

@Test
func testChoiceDynamicOptionsDisableDeleteAndExternalValue(): Unit {
    let counter = TestChoiceWriteCounter()
    let binding = CjguiSelectFieldBinding("duplex", "dyn-test", "dyn-duplex",
        ArrayList<CjguiSelectOption>([
            CjguiSelectOption("single", "单面", "false"),
            CjguiSelectOption("double", "双面", "true"),
            CjguiSelectOption("book", "小册子", "book")]),
        commit: { option =>
            if (option.key == "book") {
                counter.refusedCount += 1
                return false
            }
            return true
        })
    binding.declare("book")
    let radioGroupNode = binding.radioGroupNode("dyn-radio", "dyn-duplex-radio")
    let segmentedNode = binding.segmentedNode("dyn-seg", "dyn-duplex-seg")

    // Deleting the option that holds the current value explains it instead of
    // rewriting the business value.
    var reduced = ArrayList<CjguiSelectOption>()
    reduced.add(CjguiSelectOption("single", "单面", "false"))
    reduced.add(CjguiSelectOption("double", "双面", "true"))
    @Assert(binding.updateOptions(reduced), "")
    @Assert(binding.currentValue(), "book")
    @Assert(binding.select.selectedLabel().startsWith("未匹配"))
    let radioNode = binding.radioGroupNode("dyn-radio", "dyn-duplex-radio")
    @Assert(testFindChoiceRow(radioNode, "dyn-duplex-radio-unmatched").isSome() ||
        testFindNode(radioNode, "dyn-duplex-radio-unmatched").isSome(), true)

    // A duplicate replacement is refused by name and keeps the previous list.
    let bad = ArrayList<CjguiSelectOption>()
    bad.add(CjguiSelectOption("single", "单面", "false"))
    bad.add(CjguiSelectOption("single", "又单面", "x"))
    @Assert(binding.updateOptions(bad).size > 0, true)
    @Assert(binding.options().size, 2)

    // Disabling the only remaining option blocks confirmation everywhere.
    var disabled = ArrayList<CjguiSelectOption>()
    disabled.add(CjguiSelectOption("single", "单面", "false"))
    disabled.add(CjguiSelectOption("double", "双面", "true", enabled: false, disabledReason: "维护中"))
    @Assert(binding.updateOptions(disabled), "")
    let bounds = CjguiComposableUiRect(0, 0, 120, 30)
    let segmentedBar = binding.segmentedNode("dyn-seg", "dyn-duplex-seg")
    let doubleRow = testFindChoiceRow(segmentedBar, "dyn-duplex-seg-choose:double").getOrThrow()
    let refusedEvent = binding.applyUiEvent(CjguiComposableUiEvent(
        CjguiComposableUiLayoutNode(doubleRow, bounds, bounds), 27, "", 0, 0, 2))
    @Assert(refusedEvent.getOrThrow().didApply, false)
    @Assert(binding.takeConfirmed().isNone(), true)
    // The disabled reason is the row's help.
    @Assert(testFindChoiceRow(segmentedBar, "dyn-duplex-seg-choose:double").getOrThrow().semanticHelp, "维护中")

    // A refused owner commit does not strand the presentations: the next
    // legal write still goes through the same transaction.
    let ok = ArrayList<CjguiSelectOption>()
    ok.add(CjguiSelectOption("single", "单面", "false"))
    ok.add(CjguiSelectOption("book", "小册子", "book"))
    @Assert(binding.updateOptions(ok), "")
    let segmentedBar2 = binding.segmentedNode("dyn-seg", "dyn-duplex-seg")
    let bookRow = testFindChoiceRow(segmentedBar2, "dyn-duplex-seg-choose:book").getOrThrow()
    let refusedAgain = binding.applyUiEvent(CjguiComposableUiEvent(
        CjguiComposableUiLayoutNode(bookRow, bounds, bounds), 27, "", 0, 0, 3))
    @Assert(refusedAgain.getOrThrow().didApply, true)
    let refusedOption = binding.takeConfirmed().getOrThrow()
    @Assert(binding.commit(refusedOption), false)
    @Assert(counter.refusedCount, 1)
    // Continue after the refusal with a legal choice.
    let segmentedBar3 = binding.segmentedNode("dyn-seg", "dyn-duplex-seg")
    let singleRow = testFindChoiceRow(segmentedBar3, "dyn-duplex-seg-choose:single").getOrThrow()
    let recovered = binding.applyUiEvent(CjguiComposableUiEvent(
        CjguiComposableUiLayoutNode(singleRow, bounds, bounds), 27, "", 0, 0, 4))
    @Assert(recovered.getOrThrow().didApply, true)
    @Assert(binding.commit(binding.takeConfirmed().getOrThrow()), true)
}

@Test
func testChoiceRowPresentationsKeyboardAndSemantics(): Unit {
    let binding = CjguiSelectFieldBinding("mode", "kb-test", "kb-mode",
        ArrayList<CjguiSelectOption>([
            CjguiSelectOption("a", "甲", "a"),
            CjguiSelectOption("b", "乙", "b"),
            CjguiSelectOption("c", "丙", "c")]),
        commit: { option => true })
    binding.declare("a")
    let radioNode = binding.radioGroupNode("kb-radio", "kb-mode-radio", label: "模式")
    let segmentedNode = binding.segmentedNode("kb-seg", "kb-mode-seg")

    // Rows carry the radio transport semantic, checked paint and the label.
    let row = testFindChoiceRow(radioNode, "kb-mode-radio-choose:a").getOrThrow()
    @Assert(row.semanticRole, CJGUI_COMPOSABLE_UI_SEMANTIC_TAB)
    @Assert(row.semanticSelected, true)
    @Assert((row.ownerInteractionState & CjguiComposableUiInteractionState.SELECTED) != 0)

    // Arrow keys at one of the group's own rows move the selection through the
    // same staged confirmation; a key at an unrelated node is not consumed.
    let bounds = CjguiComposableUiRect(0, 0, 120, 30)
    let rowLayout = CjguiComposableUiLayoutNode(row, bounds, bounds)
    @Assert(binding.applyUiEvent(CjguiComposableUiEvent(rowLayout, 35, "down", 0, 0, 1)).getOrThrow().didApply)
    @Assert(binding.takeConfirmed().getOrThrow().key, "b")
    // Segmented also accepts Left/Right.
    let segRow = testFindChoiceRow(segmentedNode, "kb-mode-seg-choose:a").getOrThrow()
    let segLayout = CjguiComposableUiLayoutNode(segRow, bounds, bounds)
    @Assert(binding.applyUiEvent(CjguiComposableUiEvent(segLayout, 35, "right", 0, 0, 2)).getOrThrow().didApply)
    @Assert(binding.takeConfirmed().getOrThrow().key, "b")
    // Up from "a" wraps to the last enabled option.
    @Assert(binding.applyUiEvent(CjguiComposableUiEvent(segLayout, 35, "left", 0, 0, 3)).getOrThrow().didApply)
    @Assert(binding.takeConfirmed().getOrThrow().key, "c")
    let unrelated = cjguiComposableButton(-1, "other", "别处", "OTHER", 0, CjguiComposableUiStyle())
    @Assert(binding.applyUiEvent(CjguiComposableUiEvent(
        CjguiComposableUiLayoutNode(unrelated, bounds, bounds), 35, "down", 0, 0, 4)).isNone())

    // An empty option set renders the empty state and refuses writes.
    let emptyBinding = CjguiSelectFieldBinding("mode", "kb-empty", "kb-empty-mode",
        ArrayList<CjguiSelectOption>([]), commit: { option => true })
    emptyBinding.declare("")
    let emptyNode = emptyBinding.radioGroupNode("kb-empty-radio", "kb-empty-mode-radio")
    @Assert(testFindNode(emptyNode, "kb-empty-mode-radio-empty").isSome() ||
        testFindChoiceRow(emptyNode, "kb-empty-mode-radio-empty").isSome(), true)
}

@Test
func testGeneratedChoicePresentationVocabularyIsNamed(): Unit {
    // The generated radio/segmented kinds map to their presentations.
    @Assert(CjguiGeneratedUiPresentation.forBuiltInKind("radioGroup"), "FIELD_RADIO_GROUP")
    @Assert(CjguiGeneratedUiPresentation.forBuiltInKind("segmented"), "FIELD_SEGMENTED")
    @Assert(CjguiGeneratedUiPresentation.isImplemented("FIELD_RADIO_GROUP"), true)
    // Properties the always-visible presentations do not consume are rejected
    // by name instead of passing validation and being ignored.
    @Assert(CjguiGeneratedUiPresentation.isPropertyImplemented("FIELD_RADIO_GROUP", "searchable", "BOOLEAN"), false)
    @Assert(CjguiGeneratedUiPresentation.isPropertyImplemented("FIELD_SEGMENTED", "placeholder", "STRING"), false)
    @Assert(CjguiGeneratedUiPresentation.isPropertyImplemented("FIELD_RADIO_GROUP", "label", "STRING"), true)
    // The select keeps its declared searchable property, now actually consumed.
    @Assert(CjguiGeneratedUiPresentation.isPropertyImplemented("FIELD_SELECT", "searchable", "BOOLEAN"), true)
    let radioSpec = cjguiGeneratedRadioGroupComponent()
    @Assert(radioSpec.presentation, "FIELD_RADIO_GROUP")
    let segmentedSpec = cjguiGeneratedSegmentedComponent()
    @Assert(segmentedSpec.presentation, "FIELD_SEGMENTED")
}

@Test
func testChoiceBindingSearchableDeclarationCombinesSources(): Unit {
    let binding = CjguiSelectFieldBinding("duplex", "searchable-test", "searchable-duplex",
        ArrayList<CjguiSelectOption>([CjguiSelectOption("single", "单面", "false")]),
        commit: { option => true })
    // Constructor-declared searchable keeps working (old binding usage).
    @Assert(binding.isSearchable(), false)
    binding.declare("false")
    @Assert(binding.select.isSearchable(), false)
    // A generated node declaring searchable=true turns it on for the field,
    // and a later declare without the property (another presentation of the
    // same field) must not reset it.
    binding.declare("false", searchable: Some(true))
    @Assert(binding.select.isSearchable(), true)
    binding.declare("false")
    @Assert(binding.select.isSearchable(), true)
    let searchableBinding = CjguiSelectFieldBinding("duplex", "searchable-test-2", "searchable-duplex-2",
        ArrayList<CjguiSelectOption>([CjguiSelectOption("single", "单面", "false")]),
        commit: { option => true }, searchable: true)
    searchableBinding.declare("false")
    @Assert(searchableBinding.select.isSearchable(), true)
}

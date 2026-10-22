package cjgui

import std.collection.*
import std.unittest.*
import std.unittest.testmacro.*

private func commandCheckedNodeById(root: CjguiComposableUiNode,
    semanticId: String): ?CjguiComposableUiNode {
    if (root.semanticId == semanticId) {
        return Some(root)
    }
    for (child in root.children()) {
        if (let Some(found) <- commandCheckedNodeById(child, semanticId)) {
            return Some(found)
        }
    }
    return None
}

@Test
func commandToolbarAndPaletteProjectCheckedFromTheDeclaration(): Unit {
    let commands = ArrayList<CjguiComposableUiCommand>([
        CjguiComposableUiCommand("test.toggle", CjguiComposableUiNodeReference.manual(20), "切换代理",
            "", 0, true, true),
        CjguiComposableUiCommand("test.other", CjguiComposableUiNodeReference.manual(21), "其他",
            "", 0, true, false)
    ])
    let metadata = ArrayList<CjguiCommandToolbarMetadata>([
        CjguiCommandToolbarMetadata("test.toggle", "TOGGLE", 7),
        CjguiCommandToolbarMetadata("test.other", "OTHER", 7)
    ])
    let placement = cjguiCommandToolbarPlacement(commands, metadata)
    let item = placement.itemForCommand("test.toggle").getOrThrow()
    @Assert(item.checked, true)
    let toolbar = cjguiComposableCommandToolbar(30, "checked-actions", placement)
    let button = commandCheckedNodeById(toolbar, "checked-actions-${item.key}").getOrThrow()
    @Assert(button.label.startsWith("✓"), true)
    @Assert((button.ownerInteractionState & CjguiComposableUiInteractionState.CHECKED) != 0, true)
    let other = commandCheckedNodeById(toolbar, "checked-actions-test-other").getOrThrow()
    @Assert(other.label.startsWith("✓"), false)
    @Assert((other.ownerInteractionState & CjguiComposableUiInteractionState.CHECKED) != 0, false)
    var paletteChecked = false
    var paletteOther = true
    for (entry in cjguiCommandPaletteItems(placement)) {
        if (entry.key == item.key) {
            paletteChecked = entry.checked
        }
        if (entry.key == "test-other") {
            paletteOther = entry.checked
        }
    }
    @Assert(paletteChecked, true)
    @Assert(paletteOther, false)
}

@Test
func commandCheckableDeclarationDrivesRolesNotLabelGlyphs(): Unit {
    // Unchecked-checkable and plain action are two declared facts; a checked
    // value on a plain action must not turn it into a checkbox.
    let commands = ArrayList<CjguiComposableUiCommand>([
        CjguiComposableUiCommand("sem.checkable.on", CjguiComposableUiNodeReference.manual(20), "勾选开",
            "", 0, true, true, isCheckable: true),
        CjguiComposableUiCommand("sem.checkable.off", CjguiComposableUiNodeReference.manual(21), "勾选关",
            "", 1, true, false, isCheckable: true),
        CjguiComposableUiCommand("sem.action.plain", CjguiComposableUiNodeReference.manual(22), "普通动作",
            "", 2, true, false),
        CjguiComposableUiCommand("sem.action.legacy", CjguiComposableUiNodeReference.manual(23), "旧值",
            "", 3, true, true)
    ])
    let metadata = ArrayList<CjguiCommandToolbarMetadata>([
        CjguiCommandToolbarMetadata("sem.checkable.on", "ON", 7),
        CjguiCommandToolbarMetadata("sem.checkable.off", "OFF", 7),
        CjguiCommandToolbarMetadata("sem.action.plain", "PLAIN", 7, disabledReason: "外部禁用"),
        CjguiCommandToolbarMetadata("sem.action.legacy", "LEGACY", 7)
    ])
    let placement = cjguiCommandToolbarPlacement(commands, metadata)
    @Assert(placement.itemForCommand("sem.checkable.on").getOrThrow().checkable, true)
    @Assert(placement.itemForCommand("sem.checkable.off").getOrThrow().checkable, true)
    @Assert(placement.itemForCommand("sem.action.plain").getOrThrow().checkable, false)
    // Palette items carry the same two facts.
    var sawOn = false
    var sawOff = false
    var sawPlain = false
    for (entry in cjguiCommandPaletteItems(placement)) {
        if (entry.key == "sem-checkable-on") { sawOn = entry.checkable && entry.checked }
        if (entry.key == "sem-checkable-off") { sawOff = entry.checkable && !entry.checked }
        if (entry.key == "sem-action-plain") { sawPlain = !entry.checkable && !entry.checked }
    }
    @Assert(sawOn, true)
    @Assert(sawOff, true)
    @Assert(sawPlain, true)
    // Toolbar materialization: the checkable bit alone picks the checkbox
    // semantic role; the disabled reason travels as the element's help.
    let toolbar = cjguiComposableCommandToolbar(30, "sem-actions", placement)
    let on = commandCheckedNodeById(toolbar, "sem-actions-sem-checkable-on").getOrThrow()
    @Assert(on.semanticRole, CJGUI_COMPOSABLE_UI_SEMANTIC_CHECKBOX)
    let off = commandCheckedNodeById(toolbar, "sem-actions-sem-checkable-off").getOrThrow()
    @Assert(off.semanticRole, CJGUI_COMPOSABLE_UI_SEMANTIC_CHECKBOX)
    @Assert((off.ownerInteractionState & CjguiComposableUiInteractionState.CHECKED) != 0, false)
    let plain = commandCheckedNodeById(toolbar, "sem-actions-sem-action-plain").getOrThrow()
    @Assert(plain.semanticRole, CJGUI_COMPOSABLE_UI_SEMANTIC_BUTTON)
    @Assert(plain.semanticHelp, "外部禁用")
    let legacy = commandCheckedNodeById(toolbar, "sem-actions-sem-action-legacy").getOrThrow()
    @Assert(legacy.semanticRole, CJGUI_COMPOSABLE_UI_SEMANTIC_BUTTON)
    // The scoped composer keeps the same derivation.
    let scope = CjguiComposableUiIdentityScope("sem-scoped")
    let scopedBar = cjguiComposableCommandToolbar(scope, "sem-scoped-actions", placement)
    let scopedOn = commandCheckedNodeById(scopedBar, "sem-scoped-actions-sem-checkable-on").getOrThrow()
    @Assert(scopedOn.semanticRole, CJGUI_COMPOSABLE_UI_SEMANTIC_CHECKBOX)
}

@Test
func commandPanelUpdatePreservesQueryAndNavigationWhileCheckedChanges(): Unit {
    let panel = CjguiSearchableSelectionPanel("checked-panel")
    let initial = ArrayList<CjguiSearchableSelectionItem>([
        CjguiSearchableSelectionItem("proxy", "使用代理", detail: "代理开关"),
        CjguiSearchableSelectionItem("close", "关闭", detail: "关闭窗口")
    ])
    panel.open("命令", initial, CjguiComposableUiNodeReference.manual(9))
    panel.setQuery("代理")
    @Assert(panel.resultCount(), 1)
    @Assert(panel.highlightedKey(), "proxy")
    let updated = ArrayList<CjguiSearchableSelectionItem>([
        CjguiSearchableSelectionItem("proxy", "使用代理", detail: "代理开关", checked: true),
        CjguiSearchableSelectionItem("close", "关闭", detail: "关闭窗口")
    ])
    let before = panel.revision()
    panel.updateItems(updated)
    @Assert(panel.query(), "代理")
    @Assert(panel.resultCount(), 1)
    @Assert(panel.highlightedKey(), "proxy")
    @Assert(panel.revision() > before, true)
    let stable = panel.revision()
    panel.updateItems(updated)
    @Assert(panel.revision(), stable)
    // Checked renders as its own marker; navigation highlight stays the
    // separate row-selected fact.
    let row = panel.buildRow(panel.itemAt(0), false, false)
    @Assert(row.semanticSelected, false)
    let marker = commandCheckedNodeById(row, "search-panel-checked-panel-checked-0").getOrThrow()
    @Assert(marker.value, "✓")
    let highlighted = panel.buildRow(panel.itemAt(0), true, false)
    @Assert(highlighted.semanticSelected, true)
}

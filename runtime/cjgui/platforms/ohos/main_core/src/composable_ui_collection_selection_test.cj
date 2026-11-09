// Correctness tests for the hierarchy-independent collection selection
// (composable_ui_collection_selection.cj). Pure standard Cangjie: no window
// and no native module is needed.
package cjgui

import std.collection.*

class CollectionTestOrder <: CjguiComposableUiCollectionOrder {
    var keys: ArrayList<String>
    var keyReads: Int64 = 0
    let unselectable: HashSet<String>

    init(keys: ArrayList<String>, unselectableKeys!: ArrayList<String> = ArrayList<String>()) {
        this.keys = keys
        this.unselectable = HashSet<String>(unselectableKeys)
    }

    public func count(): Int64 {
        return keys.size
    }

    public func keyAt(index: Int64): String {
        keyReads += 1
        if (index < 0 || index >= keys.size) {
            return ""
        }
        return keys[index]
    }

    public func indexOfKey(key: String): Int64 {
        var index: Int64 = 0
        while (index < keys.size) {
            if (keys[index] == key) {
                return index
            }
            index += 1
        }
        return -1
    }

    public func isSelectableAt(index: Int64): Bool {
        if (index < 0 || index >= keys.size) {
            return false
        }
        return !unselectable.contains(keys[index])
    }

    func replaceWith(newKeys: ArrayList<String>): Unit {
        keys = newKeys
    }
}

@Test
func collectionEligibilityPruneReadsOnlyUntilTrackedKeysAreResolved(): Unit {
    let order = CollectionTestOrder(collectionKeys("r", 2000))
    let selection = CjguiComposableUiCollectionSelection()
    selection.pruneToEligible(order)
    @Assert(order.keyReads, 0)
    selection.click("r4", false, false, order)
    order.keyReads = 0
    let version = selection.selectionVersion()
    selection.pruneToEligible(order)
    @Assert(order.keyReads, 5)
    @Assert(selection.selectionVersion(), version)
    // A view filter is intentionally absent from this eligibility order.
    // Disabling or deleting the original record still prunes key/focus/anchor.
    order.unselectable.add("r4")
    selection.pruneToEligible(order)
    @Assert(selection.selectedKeysInOrder().size, 0)
    @Assert(selection.focus(), "")
    @Assert(selection.anchor(), "")
    selection.click("r8", false, false, order)
    order.keys.remove(at: 8)
    selection.pruneToEligible(order)
    @Assert(selection.selectedKeysInOrder().size, 0)
    @Assert(selection.focus(), "")
}

private func collectionKeys(prefix: String, count: Int64): ArrayList<String> {
    let result = ArrayList<String>()
    var index: Int64 = 0
    while (index < count) {
        result.add("${prefix}${index}")
        index += 1
    }
    return result
}

@Test
func collectionPlainAndCommandClickKeepStableKeys(): Unit {
    let order = CollectionTestOrder(collectionKeys("r", 5))
    let selection = CjguiComposableUiCollectionSelection()
    selection.click("r2", false, false, order)
    @Assert(selection.selectedKeysInOrder(), ArrayList<String>(["r2"]))
    @Assert(selection.focus(), "r2")
    @Assert(selection.anchor(), "r2")
    // Command-click adds, Command-click again removes; focus stays on the
    // interacted row while the anchor moves with it.
    selection.click("r4", true, false, order)
    @Assert(selection.selectedKeysInOrder(), ArrayList<String>(["r2", "r4"]))
    selection.click("r2", true, false, order)
    @Assert(selection.selectedKeysInOrder(), ArrayList<String>(["r4"]))
    @Assert(selection.focus(), "r2")
    @Assert(selection.anchor(), "r2")
}

@Test
func collectionShiftRangeFollowsCurrentOrderInBothDirections(): Unit {
    let order = CollectionTestOrder(collectionKeys("r", 6))
    let selection = CjguiComposableUiCollectionSelection()
    selection.click("r3", false, false, order)
    selection.click("r5", false, true, order)
    @Assert(selection.selectedKeysInOrder(), ArrayList<String>(["r3", "r4", "r5"]))
    // Reverse range: the anchor stays r3, the visible interval is r1..r3.
    selection.click("r1", false, true, order)
    @Assert(selection.selectedKeysInOrder(), ArrayList<String>(["r1", "r2", "r3"]))
    @Assert(selection.anchor(), "r3")
    @Assert(selection.focus(), "r1")
}

@Test
func collectionSortedOrderKeepsSelectionAndRangesOnNewOrder(): Unit {
    let fullOrder = collectionKeys("r", 4)
    let order = CollectionTestOrder(fullOrder)
    let selection = CjguiComposableUiCollectionSelection()
    selection.click("r1", false, false, order)
    selection.click("r2", false, true, order)
    @Assert(selection.selectedKeysInOrder(), ArrayList<String>(["r1", "r2"]))
    // A sort only changes the projection. Existing selected business keys are
    // untouched and no old display row number is reinterpreted.
    order.replaceWith(ArrayList<String>(["r3", "r0", "r2"]))
    @Assert(selection.selectedKeysInOrder(), ArrayList<String>(["r1", "r2"]))
    @Assert(selection.hiddenCount(order), 1) // r1 is missing from this order
    // The anchor r1 is hidden, so a Shift click starts a new range at the
    // clicked row instead of reusing an old position.
    selection.click("r3", false, true, order)
    @Assert(selection.selectedKeysInOrder(), ArrayList<String>(["r3"]))
    @Assert(selection.anchor(), "r3")
    // A fresh plain click resets the anchor; the next Shift range covers the
    // CURRENT displayed interval r0..r2.
    selection.click("r0", false, false, order)
    selection.click("r2", false, true, order)
    @Assert(selection.selectedKeysInOrder(), ArrayList<String>(["r0", "r2"]))
    @Assert(selection.hiddenCount(order), 0)
}

@Test
func collectionHiddenAnchorStartsANewRangeAtTheGestureTarget(): Unit {
    let order = CollectionTestOrder(collectionKeys("r", 5))
    let selection = CjguiComposableUiCollectionSelection()
    selection.click("r1", false, false, order)
    selection.click("r3", false, true, order)
    // Filter hides the anchor r1 and r2; r0,r3,r4 remain visible.
    order.replaceWith(ArrayList<String>(["r0", "r3", "r4"]))
    @Assert(selection.hiddenCount(order), 2)
    @Assert(selection.selectedKeysInOrder(), ArrayList<String>(["r1", "r2", "r3"]))
    selection.click("r4", false, true, order)
    // The hidden anchor cannot supply an old position: the range starts at
    // the clicked row, and that row becomes the new anchor.
    @Assert(selection.selectedKeysInOrder(), ArrayList<String>(["r4"]))
    @Assert(selection.anchor(), "r4")
}

@Test
func collectionSelectAllCoversTheWholeOrderAndSkipsUnselectable(): Unit {
    let keys = collectionKeys("r", 240)
    let order = CollectionTestOrder(keys, unselectableKeys: ArrayList<String>(["r7", "r100"]))
    let selection = CjguiComposableUiCollectionSelection()
    selection.click("r1", false, false, order)
    selection.selectAll(order)
    @Assert(selection.selectedCount(), 238)
    @Assert(selection.isSelected("r0"), true)
    @Assert(selection.isSelected("r239"), true) // beyond any viewport
    @Assert(selection.isSelected("r7"), false)
    @Assert(selection.hiddenCount(order), 0)
}

@Test
func collectionPruneDistinguishesHiddenFromDeleted(): Unit {
    let order = CollectionTestOrder(collectionKeys("r", 4))
    let selection = CjguiComposableUiCollectionSelection()
    selection.selectAll(order)
    selection.click("r1", true, false, order)
    selection.click("r2", true, false, order)
    @Assert(selection.selectedKeysInOrder(), ArrayList<String>(["r0", "r3"]))
    // Filter hides r0; eligibility still contains it, so it must stay
    // selected and be reported as hidden.
    order.replaceWith(ArrayList<String>(["r3"]))
    selection.pruneToEligible(ArrayList<String>(["r0", "r3"]))
    @Assert(selection.isSelected("r0"), true)
    @Assert(selection.hiddenCount(order), 1)
    // The anchor/focus r2 is no longer eligible, so its repair also advances
    // the version even though the selected keys set did not change.
    @Assert(selection.selectionVersion(), 4)
    // A real deletion drops it; focus/anchor die with the vanished key.
    selection.pruneToEligible(ArrayList<String>(["r3"]))
    @Assert(selection.isSelected("r0"), false)
    @Assert(selection.selectedKeysInOrder(), ArrayList<String>(["r3"]))
    @Assert(selection.selectionVersion(), 5)
}

@Test
func collectionSharedInstanceServesListAndTableOrders(): Unit {
    let listOrder = CollectionTestOrder(collectionKeys("r", 4))
    let tableOrder = CollectionTestOrder(ArrayList<String>(["r3", "r2", "r1", "r0"]))
    let selection = CjguiComposableUiCollectionSelection()
    // Chosen in the list view...
    selection.click("r2", false, false, listOrder)
    selection.click("r3", true, false, listOrder)
    @Assert(selection.selectedKeysInOrder(), ArrayList<String>(["r2", "r3"]))
    // ...the same keys are already selected in the table projection; the
    // shared instance never re-derives them from display positions.
    @Assert(selection.isSelected("r2"), true)
    @Assert(selection.isSelected("r3"), true)
    @Assert(selection.hiddenCount(tableOrder), 0)
    // External-style range through the table order uses that order: anchor r3
    // at index 0, target r0 at index 3.
    selection.click("r0", false, true, tableOrder)
    @Assert(selection.selectedKeysInOrder(), ArrayList<String>(["r3", "r2", "r1", "r0"]))
}

@Test
func collectionKeyboardNavigationExtendsFromFocusAndRepairsHiddenFocus(): Unit {
    let order = CollectionTestOrder(collectionKeys("r", 6))
    let selection = CjguiComposableUiCollectionSelection()
    let down = selection.navigate("down", false, order)
    @Assert(down.didChange, true)
    @Assert(down.focus, "r0")
    let extension = selection.navigate("down", true, order)
    @Assert(extension.focus, "r1")
    @Assert(selection.selectedKeysInOrder(), ArrayList<String>(["r0", "r1"]))
    // Filter hides the focus. Repair falls back to the visible anchor first,
    // then to the first selectable row; the selected keys stay.
    order.replaceWith(ArrayList<String>(["r2", "r3", "r4", "r5"]))
    selection.ensureFocusInOrder(order)
    @Assert(selection.focus(), "r2")
    @Assert(selection.selectedKeysInOrder(), ArrayList<String>(["r0", "r1"]))
    @Assert(selection.hiddenCount(order), 2)
}

@Test
func collectionSnapshotReportsKeysFocusAnchorAndVersions(): Unit {
    let order = CollectionTestOrder(collectionKeys("r", 3))
    let selection = CjguiComposableUiCollectionSelection()
    selection.click("r1", false, false, order)
    selection.click("r2", false, true, order)
    let snapshot = selection.snapshot(42)
    @Assert(snapshot.keys, ArrayList<String>(["r1", "r2"]))
    @Assert(snapshot.focus, "r2")
    @Assert(snapshot.anchor, "r1")
    @Assert(snapshot.selectionVersion, selection.selectionVersion())
    @Assert(snapshot.viewVersion, 42)
}

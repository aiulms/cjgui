package cjgui

private func require(condition: Bool, message: String): Bool {
    if (!condition) {
        println("pointer-controls-probe: FAIL ${message}")
    }
    return condition
}

/// A tiny owner seam used only to prove the interleave contract. Real rule
/// and document consumers substitute their existing shared-operation owner;
/// the pointer helper never stores this value itself.
private class ProbeCasOwner {
    var version: Int64
    var splitSize: Int64
    init() {
        this.version = 0
        this.splitSize = 240
    }
    func writeSplit(value: Int64, expectedVersion: Int64): Bool {
        if (expectedVersion != version) { return false }
        splitSize = value
        version += 1
        return true
    }
}

/// Platform-free red/green probe for the public split and slider contracts.
/// It intentionally drives geometry directly, so no native event or second
/// state owner can make this probe appear green.
main(): Int64 {
    let first = cjguiComposableText(101, "split-first", "左侧", CjguiComposableUiStyle())
    let second = cjguiComposableText(103, "split-second", "右侧", CjguiComposableUiStyle())
    let split = cjguiComposableSplitView(100, "rule-set-split", first, second,
        CjguiComposableUiSplitAxis.HORIZONTAL, 180, 120, 160,
        CjguiComposableUiStyle(growX: 1, growY: 1), operationResourceId: 8000)
    let scene = CjguiComposableUiLayoutEngine.layout(split, CjguiComposableUiRect(0, 0, 600, 240), 1)
    if (!require(scene.isValid(), "split scene valid")) { return 1 }
    let handle = scene.nodeForId(102)
    if (!require(handle.nodeKind == CJGUI_COMPOSABLE_UI_SPLIT_HANDLE, "split handle kind")) { return 1 }
    if (!require(handle.bounds.x >= 120 && handle.bounds.x <= 320, "split min/max geometry")) { return 1 }
    if (!require(handle.canReceiveInput(), "split handle input")) { return 1 }
    let splitProjection = CjguiComposableUiWindowProjectionBuilder.fromScene(split, scene)
    if (!require(splitProjection.fieldValues.size >= 3, "split semantic range projection")) { return 1 }
    let moved = CjguiComposableUiSplitGeometry.firstSizeForPointer(520, 0, 600, 8, 120, 160)
    if (!require(moved == 432, "split pointer clamps to second minimum")) { return 1 }
    let reversed = CjguiComposableUiSplitGeometry.firstSizeForPointer(-10, 0, 600, 8, 120, 160)
    if (!require(reversed == 120, "split pointer clamps to first minimum")) { return 1 }

    let slider = cjguiComposableSlider(200, "document-preview-limit", 50, 0, 100, 5,
        CjguiComposableUiStyle(fixedWidth: 240, fixedHeight: 28), operationResourceId: 7101)
    if (!require(slider.nodeKind == CJGUI_COMPOSABLE_UI_SLIDER, "slider kind")) { return 1 }
    let sliderScene = CjguiComposableUiLayoutEngine.layout(slider, CjguiComposableUiRect(0, 0, 240, 28), 2)
    if (!require(sliderScene.nodeForId(200).canReceiveInput(), "slider input")) { return 1 }
    let sliderProjection = CjguiComposableUiWindowProjectionBuilder.fromScene(slider, sliderScene)
    if (!require(sliderProjection.fieldValues.size >= 4, "slider semantic range projection")) { return 1 }
    if (!require(CjguiComposableUiSliderGeometry.valueForPointer(120, 0, 240, 0, 100, 5) == 50,
        "slider pointer value")) { return 1 }
    if (!require(CjguiComposableUiSliderGeometry.adjustValue(98, 1, 0, 100, 5) == 100,
        "slider keyboard upper bound")) { return 1 }
    if (!require(CjguiComposableUiSliderGeometry.adjustValue(2, -1, 0, 100, 5) == 0,
        "slider keyboard lower bound")) { return 1 }
    let owner = ProbeCasOwner()
    if (!require(owner.writeSplit(280, 0), "owner accepts initial pointer write")) { return 1 }
    let ownerVersion = owner.version
    if (!require(owner.writeSplit(340, ownerVersion), "owner accepts external CAS write")) { return 1 }
    if (!require(!owner.writeSplit(180, ownerVersion), "stale pointer write rejected")) { return 1 }
    if (!require(owner.splitSize == 340, "stale pointer cannot overwrite external value")) { return 1 }
    if (!require(owner.writeSplit(200, owner.version), "fresh pointer resumes after external write")) { return 1 }
    println("pointer-controls-probe: PASS split=1 slider=1 cas-interleave=1 keyboard-bounds=1 consumer-contract=1")
    return 0
}

package cjgui

@Test
func contextMenuAnchorStaysInsideHostWhenPointerIsNearBottomRight(): Unit {
    let host = CjguiComposableUiRect(10, 20, 100, 80)
    let actual = cjguiComposableContextMenuBounds(host, 105, 95, 40, 30)
    @Assert(actual.x, 70)
    @Assert(actual.y, 70)
    @Assert(actual.width, 40)
    @Assert(actual.height, 30)
}

@Test
func contextMenuAnchorClampsToHostOrigin(): Unit {
    let host = CjguiComposableUiRect(10, 20, 100, 80)
    let actual = cjguiComposableContextMenuBounds(host, -5, -3, 40, 30)
    @Assert(actual.x, 10)
    @Assert(actual.y, 20)
}

@Test
func contextMenuLargerThanHostUsesHostBounds(): Unit {
    let host = CjguiComposableUiRect(10, 20, 100, 80)
    let actual = cjguiComposableContextMenuBounds(host, 80, 90, 140, 100)
    @Assert(actual.x, 10)
    @Assert(actual.y, 20)
    @Assert(actual.width, 100)
    @Assert(actual.height, 80)
}

@Test
func contextMenuLayerRetainsFrozenOwnerAndHostLocalPoint(): Unit {
    let layer = cjguiComposableContextMenuLayer(90, "context-layer", "context-menu-7", "editor", 12,
        35, 46, CjguiComposableUiStyle())
    @Assert(layer.layerId(), "context-menu-7")
    @Assert(layer.layerAnchorNodeId(), 12)
    @Assert(layer.layerAnchorAtPoint(), true)
    @Assert(layer.layerAnchorPointX(), 35)
    @Assert(layer.layerAnchorPointY(), 46)
}

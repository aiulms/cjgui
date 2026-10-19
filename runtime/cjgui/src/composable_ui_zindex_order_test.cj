// zIndex 是绘制次序，不是布局输入：兄弟子树按整块稳定排序，几何与子树区间不变。
package cjgui

import std.collection.*
import std.unittest.*
import std.unittest.testmacro.*

@Test
func zIndexStableSortKeepsGeometryAndAuthoredTies(): Unit {
    let root = cjguiComposableVertical(8100, "z-root", CjguiComposableUiStyle())
    root.add(cjguiComposableVertical(8101, "z-a", CjguiComposableUiStyle(fixedHeight: 20, zIndex: 5)))
    root.add(cjguiComposableVertical(8102, "z-b", CjguiComposableUiStyle(fixedHeight: 20, zIndex: 1)))
    root.add(cjguiComposableVertical(8103, "z-c", CjguiComposableUiStyle(fixedHeight: 20, zIndex: 1)))
    root.add(cjguiComposableVertical(8104, "z-d", CjguiComposableUiStyle(fixedHeight: 20)))
    let scene = CjguiComposableUiLayoutEngine.layout(root, CjguiComposableUiRect(0, 0, 200, 200), 1)
    @Assert(scene.isValid(), true)
    let nodes = scene.nodes()
    @Assert(nodes.size, 5)
    @Assert(nodes[0].nodeId, 8100)
    // 0 < 1 <= 1 < 5; the two equal ranks keep b before c.
    @Assert(nodes[1].nodeId, 8104)
    @Assert(nodes[2].nodeId, 8102)
    @Assert(nodes[3].nodeId, 8103)
    @Assert(nodes[4].nodeId, 8101)
    // Paint order changed, layout did not: b still owns the second row.
    @Assert(nodes[2].bounds.y, 20)
    @Assert(nodes[4].bounds.y, 0)
}

@Test
func zIndexMovesAnEffectGroupSubtreeAsOneBlock(): Unit {
    let root = cjguiComposableVertical(8110, "z-block-root", CjguiComposableUiStyle())
    let raised = cjguiComposableVertical(8111, "z-block-raised", CjguiComposableUiStyle(fixedHeight: 20,
        zIndex: 9))
    raised.add(cjguiComposableVertical(8112, "z-block-child", CjguiComposableUiStyle(fixedHeight: 10)))
    root.add(raised)
    root.add(cjguiComposableVertical(8113, "z-block-plain", CjguiComposableUiStyle(fixedHeight: 20)))
    let scene = CjguiComposableUiLayoutEngine.layout(root, CjguiComposableUiRect(0, 0, 200, 200), 1)
    @Assert(scene.isValid(), true)
    let nodes = scene.nodes()
    @Assert(nodes.size, 4)
    // The parent and its child stay adjacent: the group interval never splits.
    @Assert(nodes[1].nodeId, 8113)
    @Assert(nodes[2].nodeId, 8111)
    @Assert(nodes[3].nodeId, 8112)
    @Assert(nodes[2].subtreeNodeCount, 2)
}

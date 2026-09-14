package cjgui_rule_set_window_app

import cjgui.*
import cjgui_rule_set_application.*
import std.unittest.*
import std.unittest.testmacro.*

@Test
func selectionOnlyInvalidatesAffectedRuleMeasurements(): Unit {
    let domain = CjguiRuleSetEditingDomain.newUntitled()
    var index: Int64 = 1
    while (index <= 20) {
        let label = if (index == 1) {
            "锚点规则-这是一个用于验证无关行测量缓存与滚动锚点稳定性的长文本-"
        } else {
            "规则${index}"
        }
        @Assert(domain.createRecordFromHuman(label, true, 7, "cache", "consumer-${index}").applied, true)
        index += 1
    }
    @Assert(domain.selectRecordFromHuman(10).applied, true)
    @Assert(domain.editTextForCollectionItemFromHuman(10, CjguiRuleSetEditingDomain.formLabelResourceId,
        "规则10的超长草稿摘要", 0, 0).applied, true)

    let theme = CjguiComposableUiTheme.paperLight()
    let source = CjguiRuleSetVirtualListSource(domain, theme, theme.body)
    let state = CjguiComposableUiVirtualListState()
    let root = cjguiComposableVertical(9010, "selection-consumer-root", CjguiComposableUiStyle())
    root.add(
        cjguiComposableVariableHeightList(9011, "selection-consumer-list", 9012, source, state, 76, 5, 1,
            CjguiComposableUiStyle(fixedWidth: 250, fixedHeight: 1200)))

    let _ = CjguiComposableUiLayoutEngine.layout(root, CjguiComposableUiRect(0, 0, 250, 1200), 1)
    @Assert(state.materializedStart(), 0)
    @Assert(state.materializedEnd() >= 12, true)
    @Assert(state.revealKey(source, "rule_1"), true)
    let anchoredFirst = CjguiComposableUiLayoutEngine.layout(root, CjguiComposableUiRect(0, 0, 250, 1200), 2)
    let generationA = source.measurementGeneration()
    let revisionASelected = source.itemAt(9).layoutRevision
    let revisionBUnselected = source.itemAt(10).layoutRevision
    let revisionCUnselected = source.itemAt(0).layoutRevision
    let cBefore = anchoredFirst.nodeForId(10000001).bounds

    @Assert(domain.selectRecordFromHuman(11).applied, true)
    state.setSelectedKey("rule_11")
    let second = CjguiComposableUiLayoutEngine.layout(root, CjguiComposableUiRect(0, 0, 250, 1200), 3)
    let generationB = source.measurementGeneration()
    let revisionAUnselected = source.itemAt(9).layoutRevision
    let revisionBSelected = source.itemAt(10).layoutRevision
    let revisionCAfter = source.itemAt(0).layoutRevision
    let cAfter = second.nodeForId(10000001).bounds

    @Assert(generationB, generationA)
    @Assert(revisionAUnselected != revisionASelected, true)
    @Assert(revisionBSelected != revisionBUnselected, true)
    @Assert(revisionCAfter, revisionCUnselected)
    @Assert(cAfter.y, cBefore.y)
    @Assert(cAfter.height, cBefore.height)
    @Assert(cBefore.height > 76, true)

    // Keep the consumer's manual virtual-list content id at 22 while the
    // composite split allocates its container/handle from a separate scope.
    // Resolve the candidate exactly as a window does so this test proves the
    // generated handle does not claim the caller-owned content id.
    let identityState = CjguiComposableUiVirtualListState()
    let identityRoot = cjguiComposableVertical(9020, "identity-consumer-root", CjguiComposableUiStyle())
    let identityScope = CjguiComposableUiIdentityScope("rule-set-content-test")
    identityRoot.add(
        cjguiComposableScopedSplitView(identityScope, "rule-set-content-test",
            cjguiComposableVariableHeightList(9011, "rule-list-scroll", 22, source, identityState, 76, 5, 3,
                CjguiComposableUiStyle(fixedWidth: 250, fixedHeight: 1200)),
            cjguiComposableText(9030, "identity-consumer-detail", "详情", CjguiComposableUiStyle()),
            CjguiComposableUiSplitAxis.HORIZONTAL, 120, 40, 40, CjguiComposableUiStyle()))
    let identityRegistry = CjguiComposableUiIdentityRegistry()
    @Assert(identityRegistry.beginCandidate(), true)
    @Assert(identityRegistry.resolveCandidate(identityRoot), "")
    @Assert(identityRegistry.prepareCandidate(), true)
    let identityScene = CjguiComposableUiLayoutEngine.layout(identityRoot, CjguiComposableUiRect(0, 0, 520, 1200), 4)
    var splitHandleNodeId: Int64 = -1
    for (node in identityScene.nodes()) {
        if (node.semanticId == "rule-set-content-test-handle") {
            splitHandleNodeId = node.nodeId
        }
    }
    @Assert(identityScene.isValid(), true)
    @Assert(identityScene.layoutError(), "")
    @Assert(identityScene.nodeForId(22).semanticId, "rule-list-scroll_materialized")
    @Assert(splitHandleNodeId > 0, true)
    @Assert(splitHandleNodeId != 22, true)
    identityRegistry.commitCandidate()
}

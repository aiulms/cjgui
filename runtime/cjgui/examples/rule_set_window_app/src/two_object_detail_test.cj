package cjgui_rule_set_window_app

import cjgui.*
import cjgui_rule_set_application.*
import std.collection.*
import std.unittest.*
import std.unittest.testmacro.*

/// The SECOND domain proves the shared detail seam: two rule records use the
/// same public builder and the same shared form binding/snapshot, with no copy
/// of the print preset's layout or business calls.
private func testTheme(): CjguiComposableUiTheme {
    let style = CjguiComposableUiStyle()
    return CjguiComposableUiTheme(style, style, style, style, style, style)
}

private func detailFieldValue(node: CjguiComposableUiNode, fieldId: String): String {
    for (child in node.children()) {
        if (child.fieldId == fieldId) {
            return child.value
        }
        let nested = detailFieldValue(child, fieldId)
        if (nested != "<absent>") {
            return nested
        }
    }
    return "<absent>"
}

private func detailStatus(node: CjguiComposableUiNode): String {
    for (child in node.children()) {
        if (child.semanticId.endsWith("-status")) {
            return child.value
        }
    }
    return "<absent>"
}

private func buildDetail(domain: CjguiRuleSetEditingDomain): CjguiComposableUiNode {
    let snapshot = domain.formSnapshot()
    return cjguiSharedEditableDetailFields(20000, 20010, 20009, "rule-detail", 7100,
        domain.formBinding(), snapshot, { _ => CjguiSharedDetailFieldState(true) },
        snapshot.statusMessage, testTheme())
}

private func seedTwoRecords(domain: CjguiRuleSetEditingDomain): (Int64, Int64) {
    @Assert(domain.createCollectionItemFromHuman().applied, true)
    let first = domain.selectedRecordId()
    @Assert(domain.editTextFromHuman(CjguiRuleSetEditingDomain.formLabelResourceId, "规则甲", 0, 0).applied, true)
    @Assert(domain.createCollectionItemFromHuman().applied, true)
    let second = domain.selectedRecordId()
    @Assert(domain.editTextFromHuman(CjguiRuleSetEditingDomain.formLabelResourceId, "规则乙", 0, 0).applied, true)
    return (first, second)
}

@Test
func twoObjectDetailUsesTheSharedBuilderAndBinding(): Unit {
    let domain = CjguiRuleSetEditingDomain.newUntitled()
    let (first, second) = seedTwoRecords(domain)
    @Assert(first != second, true)

    @Assert(domain.selectCollectionItemFromHuman(first).applied, true)
    let firstNode = buildDetail(domain)
    @Assert(detailFieldValue(firstNode, "label"), "规则甲")
    @Assert(detailFieldValue(firstNode, "enabled"), "true")

    @Assert(domain.selectCollectionItemFromHuman(second).applied, true)
    let secondNode = buildDetail(domain)
    @Assert(detailFieldValue(secondNode, "label"), "规则乙")
    // The two presentations are distinct objects over the SAME builder.
    @Assert(firstNode.semanticId, secondNode.semanticId)
    @Assert(firstNode.nodeId, secondNode.nodeId)

    // Edit through the ordinary shared form contract: only the selected record
    // changes, and a rebuild shows it without re-seeding anything.
    @Assert(domain.editTextFromHuman(CjguiRuleSetEditingDomain.formLabelResourceId, "规则乙二", 0, 0).applied, true)
    let secondAfter = buildDetail(domain)
    @Assert(detailFieldValue(secondAfter, "label"), "规则乙二")

    @Assert(domain.selectCollectionItemFromHuman(first).applied, true)
    let firstAfter = buildDetail(domain)
    @Assert(detailFieldValue(firstAfter, "label"), "规则甲")
    @Assert(detailStatus(firstAfter).size > 0, true)
}

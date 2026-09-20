// The task consumer's own composite component, exercised end to end:
//   * registering a second kind does not touch the framework's kind dispatch -
//     it changes this consumer's registration plus its component file only;
//   * the card's two editors write the SAME declared fields as every other
//     entry point, and the field's declared rule is enforced for EVERY write
//     target (a second record is not implicitly trusted);
//   * the handwritten region can call the same build implementation.
package cjgui_collaboration_starter

import cjgui.*
import cjgui_shared_operation_core.*
import std.collection.*

private let TASK_CARD_STRUCTURE = """
GENERATED_UI_STRUCTURE 1
NODE 0 board vertical
NODE 1 card taskEditCard
PROPERTY 1 card caption 任务编辑卡
END"""

private func cardDomain(): CjguiSharedOperationList {
    return CjguiSharedOperationList(ArrayList<CjguiSharedOperationRecord>([
        CjguiSharedOperationRecord(1, "第一条", false),
        CjguiSharedOperationRecord(2, "第二条", false)
    ]))
}

private func titleFor(domain: CjguiSharedOperationList, recordId: Int64): String {
    for (record in domain.snapshot().records) {
        if (record.id == recordId) {
            return record.title
        }
    }
    return "<missing>"
}

private func notesFor(domain: CjguiSharedOperationList, recordId: Int64): String {
    for (record in domain.snapshot().records) {
        if (record.id == recordId) {
            return record.notes
        }
    }
    return "<missing>"
}

/// Accepts the card structure the way the window does.
private func acceptCard(region: CjguiTaskGeneratedRegion): Bool {
    return acceptCardAgain(region) && region.acceptedStructureVersion() == 1
}

/// Re-accepts the same card at the CURRENT version, so its accepted nodes carry
/// the currently selected write target.
private func acceptCardAgain(region: CjguiTaskGeneratedRegion): Bool {
    if (!region.submitStructure(TASK_CARD_STRUCTURE, region.acceptedStructureVersion()).candidateAccepted) {
        return false
    }
    if (!region.beginSceneRefresh()) {
        return false
    }
    let _ = region.buildSection(CjguiComposableUiTheme.beaconDark())
    if (!region.prepareSceneRefresh()) {
        return false
    }
    region.commitSceneRefresh()
    return true
}

/// A real control event on one accepted composite element.
private func cardEvent(region: CjguiTaskGeneratedRegion, elementKey: String, eventKind: Int64,
                       text: String): CjguiComposableUiEvent {
    let nodeId = region.acceptedCompositeElementNodeId("card", elementKey)
    let bounds = CjguiComposableUiRect(0, 0, 200, 26)
    let declared = cjguiComposableTextInput(nodeId, "card-${elementKey}", "", "", 0,
        CjguiComposableUiStyle(fixedHeight: 26))
    return CjguiComposableUiEvent(CjguiComposableUiLayoutNode(declared, bounds, bounds), eventKind,
        text, 0, 0, 1)
}

private func repeatedText(text: String, count: Int64): String {
    let builder = StringBuilder()
    var index: Int64 = 0
    while (index < count) {
        builder.append(text)
        index += 1
    }
    return builder.toString()
}

@Test
func taskEditCardRegistersAndExpandsThroughThePublicSeam(): Unit {
    let domain = cardDomain()
    let _ = CjguiTaskFields.installInto(domain, 1)
    let _ = CjguiTaskFields.installInto(domain, 2)
    let _ = domain.selectFromHuman(1)
    let region = CjguiTaskGeneratedRegion(domain, CjguiTaskFields.titleResourceId)
    @Assert(acceptCard(region), true)
    // The card expands into four framework-identified nodes (container, caption,
    // title editor, notes editor) and every element resolves.
    @Assert(region.acceptedCompositeElementNodeId("card", "root") > 0, true)
    @Assert(region.acceptedCompositeElementNodeId("card", "caption") > 0, true)
    @Assert(region.acceptedCompositeElementNodeId("card", "title") > 0, true)
    @Assert(region.acceptedCompositeElementNodeId("card", "notes") > 0, true)
    @Assert(region.acceptedCompositeElementNodeId("card", "missing"), -1)
    // Unknown kinds and properties are still refused: the extension did not
    // loosen the existing generation rules.
    let unknownKind = region.submitStructure("""
GENERATED_UI_STRUCTURE 1
NODE 0 board vertical
NODE 1 bad noSuchKind
END""", region.acceptedStructureVersion())
    @Assert(unknownKind.candidateAccepted, false)
    @Assert(unknownKind.reason, "unknown_component")
    let unknownProperty = region.submitStructure("""
GENERATED_UI_STRUCTURE 1
NODE 0 board vertical
NODE 1 card taskEditCard
PROPERTY 1 card nope 1
END""", region.acceptedStructureVersion())
    @Assert(unknownProperty.candidateAccepted, false)
    @Assert(unknownProperty.reason, "unknown_property")
}

@Test
func taskEditCardWritesReachTheOwnerForEveryWriteTarget(): Unit {
    let domain = cardDomain()
    // The application installs its declared rules for BOTH records: every
    // exposed write target resolves its own authoritative rule.
    @Assert(CjguiTaskFields.installInto(domain, 1), true)
    @Assert(CjguiTaskFields.installInto(domain, 2), true)
    @Assert(domain.selectFromHuman(1).applied, true)
    let region = CjguiTaskGeneratedRegion(domain, CjguiTaskFields.titleResourceId)
    @Assert(acceptCard(region), true)

    // Record 1: the card's title editor writes through the owner.
    @Assert(region.handleEvent(cardEvent(region, "title",
        CJGUI_COMPOSABLE_UI_EVENT_TEXT_CHANGED, "卡内标题一")).didApply, true)
    @Assert(titleFor(domain, 1), "卡内标题一")
    // The notes editor writes its own declared field on the same record.
    @Assert(region.handleEvent(cardEvent(region, "notes",
        CJGUI_COMPOSABLE_UI_EVENT_TEXT_CHANGED, "备注一")).didApply, true)
    @Assert(notesFor(domain, 1), "备注一")

    // Record 2: switch selection, re-accept so the accepted node carries the new
    // target, then the SAME interactions must be enforced for that record too.
    @Assert(domain.selectFromHuman(2).applied, true)
    @Assert(acceptCardAgain(region), true)
    @Assert(region.handleEvent(cardEvent(region, "title",
        CJGUI_COMPOSABLE_UI_EVENT_TEXT_CHANGED, "卡内标题二")).didApply, true)
    @Assert(titleFor(domain, 2), "卡内标题二")
    @Assert(titleFor(domain, 1), "卡内标题一")
    // Out-of-range on the SECOND record is refused by the same rule, not silently
    // accepted because only the first record had one.
    let before = domain.version()
    @Assert(region.handleEvent(cardEvent(region, "title",
        CJGUI_COMPOSABLE_UI_EVENT_TEXT_CHANGED, repeatedText("字", 121))).didApply, false)
    @Assert(titleFor(domain, 2), "卡内标题二")
    @Assert(domain.version(), before)

    // Business freeze on the SECOND record: submit it and the same legal title
    // write is refused by the field's own condition.
    let markedRule = CjguiTaskFields.definition("marked").rule(2)
    @Assert(domain.writeDeclaredFieldFromHuman(markedRule, 2,
        CjguiSharedOperationValue.boolean(true)).applied, true)
    @Assert(acceptCardAgain(region), true)
    @Assert(region.handleEvent(cardEvent(region, "title",
        CJGUI_COMPOSABLE_UI_EVENT_TEXT_CHANGED, "冻结后")).didApply, false)
    @Assert(titleFor(domain, 2), "卡内标题二")
    @Assert(titleFor(domain, 1), "卡内标题一")
}

/// The owner only applies a field rule for a (writer, target) pair that was
/// really installed, so the application's wiring is load-bearing: with the
/// app-level helper every exposed record is gated, and a target that was never
/// wired has no rule to enforce.
@Test
func taskEditCardRulesCoverEveryExposedRecord(): Unit {
    let domain = cardDomain()
    // Before wiring, neither target has an authoritative rule.
    @Assert(domain.fieldRule("SET_TITLE", 1).isNone(), true)
    @Assert(domain.fieldRule("SET_TITLE", 2).isNone(), true)
    // The application's own helper wires every exposed record.
    @Assert(CjguiTaskFields.installIntoEveryRecord(domain), true)
    @Assert(domain.fieldRule("SET_TITLE", 1).isSome(), true)
    @Assert(domain.fieldRule("SET_TITLE", 2).isSome(), true)
    @Assert(domain.fieldRule("SET_NOTES", 2).isSome(), true)

    // With record 1 wired and record 2 deliberately left unwired, the same legal
    // request is gated on 1 and ungated on 2: an un-wired target has no rule, so
    // the application must wire every target it exposes.
    let partial = cardDomain()
    @Assert(CjguiTaskFields.installInto(partial, 1), true)
    let titleRule = CjguiTaskFields.definition("title").rule(1)
    let overLong = repeatedText("字", 121)
    @Assert(partial.writeDeclaredFieldFromHuman(titleRule, 1,
        CjguiSharedOperationValue.string(overLong)).applied, false)
    @Assert(partial.installFieldRule(CjguiTaskFields.definition("title").rule(2)), true)
    @Assert(partial.writeDeclaredFieldFromHuman(titleRule, 2,
        CjguiSharedOperationValue.string(overLong)).applied, false)
}

/// The handwritten region can use the same implementation: the card's node shape
/// is identical whichever side builds it.
@Test
func taskEditCardHandwrittenRowMatchesTheGeneratedExpansion(): Unit {
    let direct = CjguiTaskEditCardComposite.buildCard(1, "handwritten-card", 2, 3, 4, "任务编辑卡",
        "当前任务", "值一", "SET_TITLE", CjguiTaskFields.titleResourceId, 1, "备注", "值二",
        "SET_NOTES", CjguiTaskFields.notesResourceId, 1,
        style: CjguiComposableUiStyle(fixedHeight: 26))
    let shape = cardShape(direct)

    let domain = cardDomain()
    let _ = CjguiTaskFields.installInto(domain, 1)
    let _ = CjguiTaskFields.installInto(domain, 2)
    let _ = domain.selectFromHuman(1)
    let region = CjguiTaskGeneratedRegion(domain, CjguiTaskFields.titleResourceId)
    @Assert(acceptCard(region), true)
    // The generated card exposes the same business-facing attributes: caption
    // text, then title and notes editors bound to their declared fields/writers.
    @Assert(shape[0], "")       // the card container itself has no text
    @Assert(shape[1], "任务编辑卡") // the declared caption
    @Assert(region.acceptedCompositeElementSummary("card", "title"),
        "当前任务|title|SET_TITLE|field")
    @Assert(region.acceptedCompositeElementSummary("card", "notes"),
        "备注|notes|SET_NOTES|field")
    @Assert(shape.size, 4)
}

private func cardShape(node: CjguiComposableUiNode): ArrayList<String> {
    let lines = ArrayList<String>()
    collectCardShape(node, lines)
    return lines
}

private func collectCardShape(node: CjguiComposableUiNode, into: ArrayList<String>): Unit {
    into.add(if (node.label.size > 0) { node.label } else { node.value })
    for (child in node.children()) {
        collectCardShape(child, into)
    }
}

/// A same-key reorder keeps the card's element identities, so a queued event
/// from the previous scene still writes the object it was rendered for.
@Test
func taskEditCardKeepsElementIdentityAcrossReorder(): Unit {
    let domain = cardDomain()
    @Assert(CjguiTaskFields.installIntoEveryRecord(domain), true)
    @Assert(domain.selectFromHuman(1).applied, true)
    let region = CjguiTaskGeneratedRegion(domain, CjguiTaskFields.titleResourceId)
    @Assert(acceptCard(region), true)
    let titleElementBefore = region.acceptedCompositeElementNodeId("card", "title")
    @Assert(titleElementBefore > 0, true)

    // Same key, different position: the card instance keeps its identity.
    let reordered = """
GENERATED_UI_STRUCTURE 1
NODE 0 board vertical
NODE 1 spacer label
PROPERTY 1 spacer text 先行占位
NODE 1 card taskEditCard
PROPERTY 1 card caption 任务编辑卡
END"""
    @Assert(region.submitStructure(reordered, region.acceptedStructureVersion()).candidateAccepted, true)
    @Assert(region.beginSceneRefresh(), true)
    let _ = region.buildSection(CjguiComposableUiTheme.beaconDark())
    @Assert(region.prepareSceneRefresh(), true)
    region.commitSceneRefresh()
    @Assert(region.acceptedStructureVersion(), 2)
    @Assert(region.acceptedCompositeElementNodeId("card", "title"), titleElementBefore)

    // A queued event built from the PREVIOUS scene still resolves to the same
    // field and record.
    let staleNode = CjguiComposableUiLayoutNode(
        cjguiComposableTextInput(titleElementBefore, "card-title", "", "", 0,
            CjguiComposableUiStyle(fixedHeight: 26)),
        CjguiComposableUiRect(0, 0, 200, 26), CjguiComposableUiRect(0, 0, 200, 26))
    @Assert(region.handleEvent(CjguiComposableUiEvent(staleNode,
        CJGUI_COMPOSABLE_UI_EVENT_TEXT_CHANGED, "重排后写入", 0, 0, 2)).didApply, true)
    @Assert(titleFor(domain, 1), "重排后写入")

    // A rejected candidate leaves the accepted card (and its identities) usable.
    let invalid = region.submitStructure("""
GENERATED_UI_STRUCTURE 1
NODE 0 board vertical
NODE 1 card taskEditCard
PROPERTY 1 card nope 1
END""", region.acceptedStructureVersion())
    @Assert(invalid.candidateAccepted, false)
    @Assert(region.acceptedStructureVersion(), 2)
    @Assert(region.acceptedCompositeElementNodeId("card", "title"), titleElementBefore)
    @Assert(region.handleEvent(CjguiComposableUiEvent(staleNode,
        CJGUI_COMPOSABLE_UI_EVENT_TEXT_CHANGED, "拒绝后仍可写", 0, 0, 2)).didApply, true)
    @Assert(titleFor(domain, 1), "拒绝后仍可写")
}

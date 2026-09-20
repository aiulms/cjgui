// Second-consumer regression: the generated editors write through the domain's
// own human owner operation.
//
// This domain applies immediately (there is no draft layer), so a generated
// text editor must call `setTitleFromHuman` and a generated boolean editor must
// call `setMarkedFromHuman` on the record the accepted node was rendered for.
// The events here enter through the region's real event entry with the accepted
// node identity, exactly as the window delivers them after native input; native
// delivery itself is covered by the desktop verifier.
package cjgui_collaboration_starter

import cjgui.*
import cjgui_shared_operation_core.*
import std.collection.*

/// The exact title of one record, read back from the domain's own snapshot.
private func titleOfRecord(domain: CjguiSharedOperationList, recordId: Int64): String {
    for (record in domain.snapshot().records) {
        if (record.id == recordId) {
            return record.title
        }
    }
    return "<missing>"
}

private func panelWithEditor(): (CjguiSharedOperationList, CjguiTaskGeneratedRegion) {
    let domain = CjguiSharedOperationList(ArrayList<CjguiSharedOperationRecord>([
        CjguiSharedOperationRecord(1, "初始标题", false)
    ]))
    // Production wiring: the application installs its declared field rules on
    // the owner before any entry point can write. Tests that skipped this would
    // not exercise the rule the handwritten pane, the generated editor and an
    // external caller all hit.
    let _ = CjguiTaskFields.installInto(domain, 1)
    let _ = domain.selectFromHuman(1)
    let region = CjguiTaskGeneratedRegion(domain, CjguiTaskFields.titleResourceId)
    return (domain, region)
}

private func repeated(text: String, count: Int64): String {
    let builder = StringBuilder()
    var index: Int64 = 0
    while (index < count) {
        builder.append(text)
        index += 1
    }
    return builder.toString()
}

private func notesOfRecord(domain: CjguiSharedOperationList, recordId: Int64): String {
    for (record in domain.snapshot().records) {
        if (record.id == recordId) {
            return record.notes
        }
    }
    return "<missing>"
}

private let EDITOR_STRUCTURE = """
GENERATED_UI_STRUCTURE 1
NODE 0 board vertical
NODE 1 titleEditor textInput field=title
PROPERTY 1 titleEditor label 任务标题编辑
NODE 1 markedEditor booleanInput field=marked
PROPERTY 1 markedEditor label 提交状态编辑
END"""

/// Drives the region's scene-refresh transaction the way the window does:
/// candidate -> build -> prepare -> commit.
private func acceptEditorStructure(region: CjguiTaskGeneratedRegion): Bool {
    if (!region.submitStructure(EDITOR_STRUCTURE, region.acceptedStructureVersion()).candidateAccepted) {
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
    return region.acceptedStructureVersion() == 1
}

private func editorNode(region: CjguiTaskGeneratedRegion, key: String, fieldId: String, resourceId: Int64,
                        writer: String, target: Int64, kind: Int64): CjguiComposableUiLayoutNode {
    let nodeId = region.acceptedNodeIdForKey(key)
    let bounds = CjguiComposableUiRect(0, 0, 200, 26)
    let semanticId = "generated-${key}"
    let declared = if (kind == CJGUI_COMPOSABLE_UI_BOOLEAN_INPUT) {
        cjguiComposableBooleanInput(nodeId, semanticId, "编辑", false, resourceId,
            CjguiComposableUiStyle(fixedHeight: 26), fieldId: fieldId, operationActionName: writer,
            operationResourceId: target, displayValueRole: "draft")
    } else {
        cjguiComposableTextInput(nodeId, semanticId, "编辑", "", resourceId,
            CjguiComposableUiStyle(fixedHeight: 26), fieldId: fieldId, operationActionName: writer,
            operationResourceId: target, displayValueRole: "draft")
    }
    return CjguiComposableUiLayoutNode(declared, bounds, bounds)
}

@Test
func generatedTextEditorWritesThroughImmediateOwner(): Unit {
    let (domain, region) = panelWithEditor()
    @Assert(acceptEditorStructure(region), true)
    let nodeId = region.acceptedNodeIdForKey("titleEditor")
    @Assert(nodeId > 0, true)
    let event = CjguiComposableUiEvent(editorNode(region, "titleEditor", "title",
        CjguiTaskFields.titleResourceId, "SET_TITLE", 1, CJGUI_COMPOSABLE_UI_TEXT_INPUT), 28,
        "人写标题", 0, 0, 1)
    @Assert(region.handleEvent(event).didApply, true)
    // The owner applied immediately: the domain truth changed.
    var title = ""
    for (record in domain.snapshot().records) {
        if (record.id == 1) {
            title = record.title
        }
    }
    @Assert(title, "人写标题")
    // Public readback shows the same owner value.
    let fields = region.fieldsPayload()
    @Assert(fields.contains("FIELD title"), true)
    @Assert(fields.contains("APPLIED_HEX"), true)
}

@Test
func generatedBooleanEditorTogglesItsOwnField(): Unit {
    let (domain, region) = panelWithEditor()
    @Assert(acceptEditorStructure(region), true)
    let node = editorNode(region, "markedEditor", "marked",
        CjguiTaskFields.markedResourceId, "SET_MARKED", 1, CJGUI_COMPOSABLE_UI_BOOLEAN_INPUT)
    // The native bridge reports a toggled boolean as a boolean change carrying
    // the projected next value - not as an activation. Dispatching an
    // activation here is a real-input regression, so it is asserted separately
    // below.
    let event = CjguiComposableUiEvent(node, CJGUI_COMPOSABLE_UI_EVENT_BOOLEAN_CHANGED, "true", 0, 0, 1)
    @Assert(region.handleEvent(event).didApply, true)
    var marked = false
    for (record in domain.snapshot().records) {
        if (record.id == 1) {
            marked = record.isMarked
        }
    }
    @Assert(marked, true)
    // The boolean field's own key read answers the marked state (the earlier
    // implementation read the text field's id here).
    @Assert(region.draftBoolean("marked"), Some(true))
    @Assert(region.draftBoolean("title").isNone(), true)
    // The projected value is honored, not blindly toggled: a change that
    // reports "false" writes false even though the owner currently says true.
    let back = CjguiComposableUiEvent(node, CJGUI_COMPOSABLE_UI_EVENT_BOOLEAN_CHANGED, "false", 0, 0, 1)
    @Assert(region.handleEvent(back).didApply, true)
    @Assert(region.draftBoolean("marked"), Some(false))
    // A bare activation is not a boolean change for this field kind.
    let activation = CjguiComposableUiEvent(node, CJGUI_COMPOSABLE_UI_EVENT_ACTIVATE, "", 0, 0, 1)
    @Assert(region.handleEvent(activation).didApply, false)
    @Assert(region.draftBoolean("marked"), Some(false))
    // Neither is an activation for a text field, and a text change is not a
    // boolean change.
    let titleNode = editorNode(region, "titleEditor", "title", CjguiTaskFields.titleResourceId,
        "SET_TITLE", 1, CJGUI_COMPOSABLE_UI_TEXT_INPUT)
    @Assert(region.handleEvent(CjguiComposableUiEvent(titleNode, CJGUI_COMPOSABLE_UI_EVENT_ACTIVATE,
        "", 0, 0, 1)).didApply, false)
    @Assert(region.handleEvent(CjguiComposableUiEvent(node, CJGUI_COMPOSABLE_UI_EVENT_TEXT_CHANGED,
        "true", 0, 0, 1)).didApply, false)
}

@Test
func generatedEditorRejectsWrongFieldOrWriter(): Unit {
    let (domain, region) = panelWithEditor()
    @Assert(acceptEditorStructure(region), true)
    // Same accepted node id, but the event claims another writer/field: it must
    // be refused without touching the owner.
    let node = editorNode(region, "titleEditor", "title", CjguiTaskFields.titleResourceId,
        "SET_MARKED", 1, CJGUI_COMPOSABLE_UI_TEXT_INPUT)
    @Assert(region.handleEvent(CjguiComposableUiEvent(node, 28, "不应写入", 0, 0, 1)).didApply, false)
    let wrongField = editorNode(region, "titleEditor", "marked", CjguiTaskFields.titleResourceId,
        "SET_TITLE", 1, CJGUI_COMPOSABLE_UI_TEXT_INPUT)
    @Assert(region.handleEvent(CjguiComposableUiEvent(wrongField, 28, "不应写入", 0, 0, 1)).didApply, false)
    // A forged node id is refused too.
    let forged = CjguiComposableUiLayoutNode(
        cjguiComposableTextInput(1234567, "generated-forged", "编辑", "", CjguiTaskFields.titleResourceId,
            CjguiComposableUiStyle(), fieldId: "title", operationActionName: "SET_TITLE",
            operationResourceId: 1, displayValueRole: "draft"),
        CjguiComposableUiRect(0, 0, 200, 26), CjguiComposableUiRect(0, 0, 200, 26))
    @Assert(region.handleEvent(CjguiComposableUiEvent(forged, 28, "不应写入", 0, 0, 1)).didApply, false)
    var title = ""
    for (record in domain.snapshot().records) {
        if (record.id == 1) {
            title = record.title
        }
    }
    @Assert(title, "初始标题")
}

/// The reordered structure keeps the same field/edit continuation, and a
/// refused candidate leaves the accepted editors operable.
private let REORDERED_STRUCTURE = """
GENERATED_UI_STRUCTURE 1
NODE 0 board2 horizontal
NODE 1 markedEditor booleanInput field=marked
PROPERTY 1 markedEditor label 提交状态编辑
NODE 1 titleEditor textInput field=title
PROPERTY 1 titleEditor label 任务标题编辑
END"""

private let ILLEGAL_STRUCTURE = """
GENERATED_UI_STRUCTURE 1
NODE 0 board3 vertical
NODE 1 unknownEditor textInput field=notRegistered
END"""

@Test
func generatedEditorContinuesAfterReorderAndRefusedCandidate(): Unit {
    let (domain, region) = panelWithEditor()
    @Assert(acceptEditorStructure(region), true)
    let titleNode = region.acceptedNodeIdForKey("titleEditor")
    @Assert(titleNode > 0, true)

    // Same keys in a different order: identity and edit continuation survive.
    @Assert(region.submitStructure(REORDERED_STRUCTURE, 1).candidateAccepted, true)
    @Assert(region.beginSceneRefresh(), true)
    let _ = region.buildSection(CjguiComposableUiTheme.beaconDark())
    @Assert(region.prepareSceneRefresh(), true)
    region.commitSceneRefresh()
    @Assert(region.acceptedStructureVersion(), 2)
    @Assert(region.acceptedNodeIdForKey("titleEditor"), titleNode)

    let edit = CjguiComposableUiEvent(editorNode(region, "titleEditor", "title",
        CjguiTaskFields.titleResourceId, "SET_TITLE", 1, CJGUI_COMPOSABLE_UI_TEXT_INPUT), 28,
        "重排后继续", 0, 0, 2)
    @Assert(region.handleEvent(edit).didApply, true)
    var title = ""
    for (record in domain.snapshot().records) {
        if (record.id == 1) {
            title = record.title
        }
    }
    @Assert(title, "重排后继续")

    // An illegal candidate is refused and changes nothing.
    let refused = region.submitStructure(ILLEGAL_STRUCTURE, 2)
    @Assert(refused.candidateAccepted, false)
    @Assert(refused.reason, "unknown_field")
    @Assert(region.acceptedStructureVersion(), 2)
    @Assert(region.acceptedNodeIdForKey("titleEditor"), titleNode)
    // The accepted structure allows the next structure version again.
    @Assert(region.submitStructure(REORDERED_STRUCTURE, 2).candidateAccepted, true)
}

/// One definition, three consumers: the field list, the writers and the declared
/// rule are authored once, and the handwritten binding, the generated specs and
/// the external capability description all read that same object. A new field
/// added to `definitions()` appears in all three without a second edit.
@Test
func oneDefinitionDrivesHandwrittenGeneratedAndExternalEntries(): Unit {
    let binding = CjguiTaskFields.definition()
    let specs = CjguiTaskFields.generatedSpecs()
    @Assert(binding.allFields().size, CjguiTaskFields.definitions().size)
    @Assert(specs.size, CjguiTaskFields.definitions().size)
    for (spec in specs) {
        let field = CjguiTaskFields.definition(spec.fieldId)
        @Assert(field.fieldId.size > 0, true)
        @Assert(field.resourceId, spec.resourceId)
        @Assert(field.writer, spec.writeActionName)
        @Assert(field.required, spec.required)
    }
    // The declared rule answers the same way for the handwritten pane and for
    // the owner-facing write; an empty required value is named, not silent.
    let title = CjguiTaskFields.definition("title")
    @Assert(title.rejectionFor(""), "title_required")
    @Assert(title.rejectionFor("任务"), "")
    @Assert(CjguiTaskFields.definition("marked").rejectionFor(""), "")
    // The external capability description publishes the same contract.
    let (_, region) = panelWithEditor()
    let payload = region.capabilitiesPayload()
    @Assert(payload.contains("FIELD title TEXT resource=8101 writer=SET_TITLE required=1"), true)
    @Assert(payload.contains("FIELD marked BOOLEAN resource=8102 writer=SET_MARKED required=0"), true)
    @Assert(payload.contains("maxlen=120"), true)
}

private func externalWrite(domain: CjguiSharedOperationList, action: String, argument: String,
    value: CjguiSharedOperationValue): CjguiSharedOperationActionResult {
    return domain.executeFromExternal(CjguiSharedOperationActionInvocation(action, domain.version(),
        ArrayList<Int64>([1]),
        ArrayList<CjguiSharedOperationActionArgument>([
            CjguiSharedOperationActionArgument(argument, value)
        ])))
}

/// One rule, three entry points: a rule declared once is enforced by the owner no
/// matter which entry point sends the write. The generated editor, the declared
/// owner entry the handwritten pane calls, and a real external invocation all get
/// the same reason; a refusal changes neither the value nor the version, and a
/// legal write still applies afterwards.
@Test
func oneRuleRefusesEveryEntryPointWithoutPartialWrite(): Unit {
    let (domain, region) = panelWithEditor()
    @Assert(acceptEditorStructure(region), true)
    let tooLong = repeated("字", 121)
    let versionBefore = domain.version()
    // 1. generated editor event
    let generated = CjguiComposableUiEvent(editorNode(region, "titleEditor", "title",
        CjguiTaskFields.titleResourceId, "SET_TITLE", 1, CJGUI_COMPOSABLE_UI_TEXT_INPUT), 28,
        tooLong, 0, 0, 1)
    @Assert(region.handleEvent(generated).didApply, false)
    // 2. the declared owner entry the handwritten pane calls
    let titleRule = CjguiTaskFields.definition("title").rule(1)
    let handwritten = domain.writeDeclaredFieldFromHuman(titleRule, 1,
        CjguiSharedOperationValue.string(tooLong))
    @Assert(handwritten.applied, false)
    @Assert(handwritten.reason, "title_too_long")
    // 3. real external invocation (public protocol shape, version pre-check passed)
    let external = externalWrite(domain, "SET_TITLE", "title", CjguiSharedOperationValue.string(tooLong))
    @Assert(external.applied, false)
    @Assert(external.reason, "title_too_long")
    // No partial write and no version bump from any refusal.
    @Assert(titleOfRecord(domain, 1), "初始标题")
    @Assert(domain.version(), versionBefore)
    // The same three entries accept a legal value.
    @Assert(domain.writeDeclaredFieldFromHuman(titleRule, 1,
        CjguiSharedOperationValue.string("合法标题")).applied, true)
    @Assert(titleOfRecord(domain, 1), "合法标题")
    let generatedLegal = CjguiComposableUiEvent(editorNode(region, "titleEditor", "title",
        CjguiTaskFields.titleResourceId, "SET_TITLE", 1, CJGUI_COMPOSABLE_UI_TEXT_INPUT), 28,
        "生成合法标题", 0, 0, 1)
    @Assert(region.handleEvent(generatedLegal).didApply, true)
    @Assert(titleOfRecord(domain, 1), "生成合法标题")
    @Assert(externalWrite(domain, "SET_TITLE", "title",
        CjguiSharedOperationValue.string("外部合法标题")).applied, true)
    @Assert(titleOfRecord(domain, 1), "外部合法标题")
}

/// A legal request can still be refused when the BUSINESS CONDITION changes: once
/// the task is submitted its title is frozen. The refusal names the condition, the
/// stored value and version stay untouched, and reopening the task makes the very
/// same request succeed. This is deliberately not a version conflict.
@Test
func businessConditionChangeRefusesLegalTitleUntilReopened(): Unit {
    let (domain, _) = panelWithEditor()
    let titleRule = CjguiTaskFields.definition("title").rule(1)
    let markedRule = CjguiTaskFields.definition("marked").rule(1)
    // Legal under the current condition.
    @Assert(domain.writeDeclaredFieldFromHuman(titleRule, 1,
        CjguiSharedOperationValue.string("第一版")).applied, true)
    // Submit through the same declared entry the submit button uses.
    @Assert(domain.writeDeclaredFieldFromHuman(markedRule, 1,
        CjguiSharedOperationValue.boolean(true)).applied, true)
    let frozenVersion = domain.version()
    // Same field, legal value, correct version - refused by the business condition.
    let refused = domain.writeDeclaredFieldFromHuman(titleRule, 1,
        CjguiSharedOperationValue.string("第二版"))
    @Assert(refused.applied, false)
    @Assert(refused.reason, "title_frozen_after_submit")
    @Assert(refused.isVersionConflict, false)
    @Assert(titleOfRecord(domain, 1), "第一版")
    @Assert(domain.version(), frozenVersion)
    // The external entry sees exactly the same business refusal.
    let external = externalWrite(domain, "SET_TITLE", "title", CjguiSharedOperationValue.string("第二版"))
    @Assert(external.applied, false)
    @Assert(external.reason, "title_frozen_after_submit")
    @Assert(titleOfRecord(domain, 1), "第一版")
    // Reopening removes the condition; the same request now applies.
    @Assert(domain.writeDeclaredFieldFromHuman(markedRule, 1,
        CjguiSharedOperationValue.boolean(false)).applied, true)
    @Assert(domain.writeDeclaredFieldFromHuman(titleRule, 1,
        CjguiSharedOperationValue.string("第二版")).applied, true)
    @Assert(titleOfRecord(domain, 1), "第二版")
}

/// The declared length unit is Unicode scalar values, not UTF-8 bytes: a 120
/// character CJK title is accepted even though it is 360 bytes, and 121 is
/// refused. The pane's feedback and the owner's verdict use the same rule object.
@Test
func declaredTitleLengthIsMeasuredInScalarValues(): Unit {
    let (domain, _) = panelWithEditor()
    let title = CjguiTaskFields.definition("title")
    @Assert(title.rejectionFor(repeated("字", 120)), "")
    @Assert(title.rejectionFor(repeated("字", 121)), "title_too_long")
    let rule = title.rule(1)
    @Assert(domain.writeDeclaredFieldFromHuman(rule, 1,
        CjguiSharedOperationValue.string(repeated("字", 120))).applied, true)
    let tooLong = domain.writeDeclaredFieldFromHuman(rule, 1,
        CjguiSharedOperationValue.string(repeated("字", 121)))
    @Assert(tooLong.applied, false)
    @Assert(tooLong.reason, "title_too_long")
}

/// `required` is enforced by the owner at the WRITE boundary (this domain writes
/// immediately and has no draft layer), and the clear-transient rule is
/// consistent across entry points: a required field refuses a blank write, an
/// optional declared field accepts a legal clear through the same entry.
@Test
func requiredIsEnforcedAtTheOwnerWriteBoundary(): Unit {
    let (domain, _) = panelWithEditor()
    let titleRule = CjguiTaskFields.definition("title").rule(1)
    let blank = domain.writeDeclaredFieldFromHuman(titleRule, 1, CjguiSharedOperationValue.string("   "))
    @Assert(blank.applied, false)
    @Assert(blank.reason, "title_required")
    @Assert(titleOfRecord(domain, 1), "初始标题")
    let notesRule = CjguiTaskFields.definition("notes").rule(1)
    @Assert(domain.writeDeclaredFieldFromHuman(notesRule, 1,
        CjguiSharedOperationValue.string("备注内容")).applied, true)
    @Assert(domain.writeDeclaredFieldFromHuman(notesRule, 1,
        CjguiSharedOperationValue.string("")).applied, true)
    @Assert(notesOfRecord(domain, 1), "")
}

private let NOTES_STRUCTURE = """
GENERATED_UI_STRUCTURE 1
NODE 0 boardNotes vertical
NODE 1 notesEditor textInput field=notes
PROPERTY 1 notesEditor label 备注编辑
END"""

/// A newly declared field is served by every entry point without a
/// generation-specific switch: it appears in the generated catalog and the
/// external capability description, its owner rule is enforced on the external
/// invocation, and a generated editor built only from its declaration writes it.
@Test
func newlyDeclaredFieldFlowsThroughGenerationAndOwner(): Unit {
    let (domain, region) = panelWithEditor()
    @Assert(CjguiTaskFields.definitions().size, 3)
    let payload = region.capabilitiesPayload()
    @Assert(payload.contains(
        "FIELD notes TEXT resource=8103 writer=SET_NOTES required=0 min=0 max=0 maxlen=200 callable=1"), true)
    // Owner rule on the external path: 200 scalar values accepted, 201 refused.
    let over = externalWrite(domain, "SET_NOTES", "notes",
        CjguiSharedOperationValue.string(repeated("n", 201)))
    @Assert(over.applied, false)
    @Assert(over.reason, "notes_too_long")
    @Assert(externalWrite(domain, "SET_NOTES", "notes",
        CjguiSharedOperationValue.string(repeated("n", 200))).applied, true)
    @Assert(notesOfRecord(domain, 1), repeated("n", 200))
    // A declared writer invoked with another argument is refused, never routed to
    // the title writer by default.
    let wrongArgument = externalWrite(domain, "SET_NOTES", "title",
        CjguiSharedOperationValue.string("串到标题"))
    @Assert(wrongArgument.applied, false)
    @Assert(wrongArgument.reason, "unknown_argument")
    @Assert(titleOfRecord(domain, 1), "初始标题")
    // The generated path serves the new field from its declaration alone.
    @Assert(region.submitStructure(NOTES_STRUCTURE, region.acceptedStructureVersion()).candidateAccepted, true)
    @Assert(region.beginSceneRefresh(), true)
    let _ = region.buildSection(CjguiComposableUiTheme.beaconDark())
    @Assert(region.prepareSceneRefresh(), true)
    region.commitSceneRefresh()
    let notesEvent = CjguiComposableUiEvent(editorNode(region, "notesEditor", "notes",
        CjguiTaskFields.notesResourceId, "SET_NOTES", 1, CJGUI_COMPOSABLE_UI_TEXT_INPUT), 28,
        "生成写备注", 0, 0, 1)
    @Assert(region.handleEvent(notesEvent).didApply, true)
    @Assert(notesOfRecord(domain, 1), "生成写备注")
}

/// Same key, different object: a queued event keeps the object it was rendered
/// for. The accepted binding may move to object B, but the old event's own
/// target still decides which owner record is written - and the object it was
/// NOT rendered for stays untouched. A rejected candidate changes nothing.
@Test
func sameKeyRebindingKeepsQueuedEventOnItsOriginalObject(): Unit {
    let domain = CjguiSharedOperationList(ArrayList<CjguiSharedOperationRecord>([
        CjguiSharedOperationRecord(1, "对象甲", false),
        CjguiSharedOperationRecord(2, "对象乙", false)
    ]))
    let _ = domain.selectFromHuman(1)
    let region = CjguiTaskGeneratedRegion(domain, CjguiTaskFields.titleResourceId)
    @Assert(acceptEditorStructure(region), true)
    // The event that was rendered while object 1 was the selected target.
    let queuedForOne = editorNode(region, "titleEditor", "title", CjguiTaskFields.titleResourceId,
        "SET_TITLE", 1, CJGUI_COMPOSABLE_UI_TEXT_INPUT)
    // The selection moves to object 2 and the same key is re-accepted.
    @Assert(domain.selectFromHuman(2).applied, true)
    @Assert(region.submitStructure(EDITOR_STRUCTURE, region.acceptedStructureVersion()).candidateAccepted, true)
    @Assert(region.beginSceneRefresh(), true)
    let _ = region.buildSection(CjguiComposableUiTheme.beaconDark())
    @Assert(region.prepareSceneRefresh(), true)
    region.commitSceneRefresh()
    @Assert(region.acceptedStructureVersion(), 2)
    // A rejected candidate must not change the accepted binding either.
    let rejected = region.submitStructure("GENERATED_UI_STRUCTURE 1\nNODE 0 a vertical\nNODE 1 a vertical\nEND",
        region.acceptedStructureVersion())
    @Assert(rejected.candidateAccepted, false)
    // The queued event still writes its own object, not the newly bound one.
    @Assert(region.handleEvent(CjguiComposableUiEvent(queuedForOne, 28, "排队事件的标题", 0, 0, 1)).didApply, true)
    @Assert(titleOfRecord(domain, 1), "排队事件的标题")
    @Assert(titleOfRecord(domain, 2), "对象乙")
    // A current event for the re-bound key writes the new object.
    let current = editorNode(region, "titleEditor", "title", CjguiTaskFields.titleResourceId,
        "SET_TITLE", 2, CJGUI_COMPOSABLE_UI_TEXT_INPUT)
    @Assert(region.handleEvent(CjguiComposableUiEvent(current, 28, "新绑定的标题", 0, 0, 2)).didApply, true)
    @Assert(titleOfRecord(domain, 1), "排队事件的标题")
    @Assert(titleOfRecord(domain, 2), "新绑定的标题")
}

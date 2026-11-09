package cjgui_prototype_host

import cjgui.*
import cjgui_shared_operation_core.*
import std.collection.*
import std.unittest.*
import std.unittest.testmacro.*

// R9 收口反例：
// 1) 生成式步进器的内部输入节点使用新的元素 node ID，必须接入生成式字段身份映射，
//    键入事件按普通字段路径路由到 owner（此前解析为 unknown_node，键入不达草稿）；
// 2) 步进去重按事件身份：同一原生 inputSequence 的重复投递只步进一次，
//    两次独立点击（不同序列）即使之间没有刷新也各自步进——不按刷新代合并。

private func prototypeStepperTestSession(): PrototypeSession {
    let declaration = "{\"schema\":\"cjgui.prototype-project.v1\",\"id\":\"stepper-project\"," +
        "\"title\":\"步进项目\",\"fields\":[{\"id\":\"interval\",\"label\":\"提醒间隔\",\"kind\":\"integer\"," +
        "\"minimum\":1,\"maximum\":60,\"value\":15}]}"
    let root = prototypeTestTempProject(declaration)
    return PrototypeSession(PrototypeProjectLoader.load(root), false)
}

private let prototypeStepperStructure: String = """
GENERATED_UI_STRUCTURE 1
NODE 0 stepper-root vertical
NODE 1 stepper-field integerInput field=interval
PROPERTY 1 stepper-field stepper true
END
"""

private func prototypeStepperInstall(session: PrototypeSession): CjguiComposableUiNode {
    // 提交发生在场景事务之外（事务内提交会被 scene_transaction_busy 拒绝），
    // 再按真实窗口顺序：begin → build（候选表）→ commit（提升为 accepted）。
    let submit = session.region.submitStructure(prototypeStepperStructure,
        session.region.acceptedStructureVersion())
    @Assert(submit.candidateAccepted, true)
    @Assert(session.region.beginSceneRefresh(), true)
    let root = session.region.buildNode()
    session.region.commitSceneRefresh()
    return root
}

private func prototypeStepperFindNode(root: CjguiComposableUiNode, kind: Int64,
    actionPrefix: String): ?CjguiComposableUiLayoutNode {
    var found: ?CjguiComposableUiLayoutNode = None
    let stack = ArrayList<CjguiComposableUiNode>()
    stack.add(root)
    while (stack.size > 0) {
        let current = stack.remove(at: stack.size - 1)
        if (current.nodeKind == kind &&
            (actionPrefix.size == 0 || current.actionName.startsWith(actionPrefix))) {
            found = Some(CjguiComposableUiLayoutNode(current, CjguiComposableUiRect(0, 0, 100, 32),
                CjguiComposableUiRect(0, 0, 100, 32)))
        }
        for (child in current.children()) {
            stack.add(child)
        }
    }
    return found
}

@Test
func prototypeStepperInputTypingReachesOwnerThroughIdentityTable(): Unit {
    let session = prototypeStepperTestSession()
    let root = prototypeStepperInstall(session)
    let input = match (prototypeStepperFindNode(root, CJGUI_COMPOSABLE_UI_INTEGER_INPUT, "")) {
        case Some(value) => value
        case None =>
            @Assert(false)
            return
    }
    // 内部输入节点携带同一字段的 writer/owner 路由。
    @Assert(input.fieldId, "interval")
    @Assert(input.operationResourceId >= 0, true)
    // 键入的整值经普通生成式字段路径写入草稿，而不是 unknown_node。
    let typed = session.region.handleEventIfClaimed(CjguiComposableUiEvent(input,
        CJGUI_COMPOSABLE_UI_EVENT_TEXT_CHANGED, "30", 0, 0, 1))
    @Assert(typed.isSome(), true)
    @Assert(typed.getOrThrow().didApply, true)
    @Assert(session.binding.draftText("interval"), "30")
    session.close()
}

@Test
func prototypeStepperDedupFollowsEventIdentityNotRefreshGeneration(): Unit {
    let session = prototypeStepperTestSession()
    let root = prototypeStepperInstall(session)
    let increment = match (prototypeStepperFindNode(root, CJGUI_COMPOSABLE_UI_BUTTON,
        "cjgui-step-increment:")) {
        case Some(value) => value
        case None =>
            @Assert(false)
            return
    }
    @Assert(session.binding.draftText("interval"), "15")
    // 实测一次物理按压以“FOCUS(31) + ACTIVATE(27)”两个事件到达本分支，两个
    // 事件都携带步进 actionName；只有激活（kind 27）允许步进，其余不步进。
    let focusPair = session.region.handleEventIfClaimed(CjguiComposableUiEvent(increment,
        CJGUI_COMPOSABLE_UI_EVENT_FOCUS, "", 0, 0, 1, inputSessionGeneration: 7u64, inputSequence: 101u64))
    @Assert(focusPair.getOrThrow().didApply, false)
    @Assert(session.binding.draftText("interval"), "15")
    // 两次独立点击（不同原生序列）：即使之间没有刷新推进任何代，也各自步进。
    let first = session.region.handleEventIfClaimed(CjguiComposableUiEvent(increment,
        CJGUI_COMPOSABLE_UI_EVENT_ACTIVATE, "", 0, 0, 1, inputSessionGeneration: 7u64, inputSequence: 101u64))
    @Assert(first.getOrThrow().didApply, true)
    let second = session.region.handleEventIfClaimed(CjguiComposableUiEvent(increment,
        CJGUI_COMPOSABLE_UI_EVENT_ACTIVATE, "", 0, 0, 1, inputSessionGeneration: 7u64, inputSequence: 102u64))
    @Assert(second.getOrThrow().didApply, true)
    @Assert(session.binding.draftText("interval"), "17")
    // 同一物理按压经两个投影重复投递（同序列）：只消费一次，不重复写入。
    let duplicate = session.region.handleEventIfClaimed(CjguiComposableUiEvent(increment,
        CJGUI_COMPOSABLE_UI_EVENT_ACTIVATE, "", 0, 0, 1, inputSessionGeneration: 7u64, inputSequence: 102u64))
    @Assert(duplicate.isSome(), true)
    @Assert(session.binding.draftText("interval"), "17")
    // 越界拒绝保持：达到上限后再加不写入（60 为上限）。
    var guardIndex: Int64 = 0
    while (guardIndex < 100) {
        let next = session.region.handleEventIfClaimed(CjguiComposableUiEvent(increment,
            CJGUI_COMPOSABLE_UI_EVENT_ACTIVATE, "", 0, 0, 1, inputSessionGeneration: 7u64,
            inputSequence: 200u64 + UInt64(guardIndex)))
        if (!next.getOrThrow().didApply) {
            break
        }
        guardIndex += 1
    }
    @Assert(session.binding.draftText("interval"), "60")
    session.close()
}

// R7 绑定字段隐藏标签：外部标签列绘制文本，控件内可见标签为空且不回退
// descriptor.label；声明的 label 仍作为 semanticLabel（AX 名）随节点发布。
@Test
func prototypeBoundFieldHiddenLabelKeepsAxNameOnEditor(): Unit {
    let declaration = "{\"schema\":\"cjgui.prototype-project.v1\",\"id\":\"r7-project\"," +
        "\"title\":\"隐藏标签项目\",\"fields\":[{\"id\":\"alpha\",\"label\":\"甲\",\"kind\":\"text\"," +
        "\"value\":\"a0\"}]}"
    let projectRoot = prototypeTestTempProject(declaration)
    let session = PrototypeSession(PrototypeProjectLoader.load(projectRoot), false)
    let structure = """
GENERATED_UI_STRUCTURE 1
NODE 0 r7-root vertical
NODE 1 field-alpha textInput field=alpha
PROPERTY 1 field-alpha label Alpha
PROPERTY 1 field-alpha labelVisible false
END
"""
    let submit = session.region.submitStructure(structure, session.region.acceptedStructureVersion())
    @Assert(submit.reason, "")
    @Assert(session.region.beginSceneRefresh(), true)
    let built = session.region.buildNode()
    session.region.commitSceneRefresh()
    var editor: ?CjguiComposableUiNode = None
    let stack = ArrayList<CjguiComposableUiNode>()
    stack.add(built)
    while (stack.size > 0) {
        let current = stack.remove(at: stack.size - 1)
        if (current.nodeKind == CJGUI_COMPOSABLE_UI_TEXT_INPUT) {
            editor = Some(current)
        }
        for (child in current.children()) {
            stack.add(child)
        }
    }
    match (editor) {
        case Some(input) =>
            // 可见标签为空（不回退声明 label），AX 名为声明 label。
            @Assert(input.label, "")
            @Assert(input.semanticLabel, "Alpha")
            @Assert(input.fieldId, "alpha")
        case None => @Assert(false)
    }
    session.close()
}

// ——— B：只读公开事实与单一来源 ———

private func prototypeReadOnlySession(): PrototypeSession {
    let declaration = "{\"schema\":\"cjgui.prototype-project.v1\",\"id\":\"readonly-project\"," +
        "\"title\":\"只读项目\",\"fields\":[" +
        "{\"id\":\"code\",\"label\":\"只读编号\",\"kind\":\"text\",\"value\":\"A-001\",\"readonly\":true}," +
        "{\"id\":\"quota\",\"label\":\"只读额度\",\"kind\":\"integer\",\"minimum\":1,\"maximum\":999," +
        "\"value\":10,\"readonly\":true}," +
        "{\"id\":\"title\",\"label\":\"标题\",\"kind\":\"text\",\"value\":\"可写\"}]}"
    let root = prototypeTestTempProject(declaration)
    return PrototypeSession(PrototypeProjectLoader.load(root), false)
}

private let prototypeReadOnlyStructure: String = """
GENERATED_UI_STRUCTURE 1
NODE 0 readonly-root vertical
NODE 1 field-code textInput field=code
PROPERTY 1 field-code label 只读编号
PROPERTY 1 field-code labelVisible false
NODE 1 field-quota integerInput field=quota
PROPERTY 1 field-quota label 只读额度
PROPERTY 1 field-quota labelVisible false
PROPERTY 1 field-quota stepper true
NODE 1 field-title textInput field=title
PROPERTY 1 field-title label 标题
PROPERTY 1 field-title labelVisible false
END
"""

@Test
func prototypeReadOnlyFactTravelsFromDeclarationToPublicProjection(): Unit {
    let session = prototypeReadOnlySession()
    let binding = prototypeFormBinding(session.project)
    let descriptors = binding.allFields()
    var codeReadOnly = false
    var quotaReadOnly = false
    var titleReadOnly = true
    for (descriptor in descriptors) {
        if (descriptor.fieldId == "code") { codeReadOnly = descriptor.readOnly }
        if (descriptor.fieldId == "quota") { quotaReadOnly = descriptor.readOnly }
        if (descriptor.fieldId == "title") { titleReadOnly = descriptor.readOnly }
    }
    @Assert(codeReadOnly, true)
    @Assert(quotaReadOnly, true)
    @Assert(titleReadOnly, false)
    // Default-compatible construction keeps existing callers writable.
    @Assert(CjguiSharedFormFieldDescriptor(1, "legacy", "旧字段", "TEXT").readOnly, false)
    // Owner refuses the write even when a path bypasses the editor.
    var codeResource: Int64 = -1
    var quotaResource: Int64 = -1
    for (field in session.project.fields) {
        if (field.id == "code") { codeResource = field.resourceId }
        if (field.id == "quota") { quotaResource = field.resourceId }
    }
    @Assert(codeResource > 0, true)
    let beforeDraft = session.domain.activeObject().draftText("code")
    let refused = session.domain.activeObject().editTextFromHuman(codeResource, "B-002", 0, 0)
    @Assert(refused.applied, false)
    @Assert(refused.reason, "field_read_only")
    @Assert(session.domain.activeObject().draftText("code"), beforeDraft)
    let refusedBoolean = session.domain.activeObject().editTextFromHuman(quotaResource, "99", 0, 0)
    @Assert(refusedBoolean.applied, false)
    @Assert(refusedBoolean.reason, "field_read_only")
    session.close()
}

@Test
func prototypeReadOnlyGeneratedConsumptionRejectsTypingAndSteps(): Unit {
    let session = prototypeReadOnlySession()
    let submit = session.region.submitStructure(prototypeReadOnlyStructure,
        session.region.acceptedStructureVersion())
    @Assert(submit.candidateAccepted, true)
    @Assert(session.region.beginSceneRefresh(), true)
    let root = session.region.buildNode()
    session.region.commitSceneRefresh()
    // The public field projection publishes the SAME fact the declaration has.
    let payload = session.region.fieldsPayload()
    @Assert(payload.contains("FIELD code "), true)
    @Assert(payload.contains("READONLY 1"), true)
    // A read-only integer stepper exists and refuses both typing and + steps.
    let quotaInput = match (prototypeStepperFindNode(root, CJGUI_COMPOSABLE_UI_INTEGER_INPUT,
        "")) { case Some(value) => value; case None => @Assert(false); return }
    let typed = session.region.handleEventIfClaimed(CjguiComposableUiEvent(quotaInput,
        CJGUI_COMPOSABLE_UI_EVENT_TEXT_CHANGED, "99", 0, 0, 1))
    @Assert(typed.isSome(), true)
    @Assert(typed.getOrThrow().didApply, false)
    @Assert(session.binding.draftText("quota"), "10")
    let stepUp = match (prototypeStepperFindNode(root, CJGUI_COMPOSABLE_UI_BUTTON,
        "cjgui-step-increment:")) { case Some(value) => value; case None => @Assert(false); return }
    let stepped = session.region.handleEventIfClaimed(CjguiComposableUiEvent(stepUp,
        CJGUI_COMPOSABLE_UI_EVENT_ACTIVATE, "", 0, 0, 1, inputSessionGeneration: 3u64,
        inputSequence: 40u64))
    @Assert(stepped.isSome(), true)
    @Assert(stepped.getOrThrow().didApply, false)
    @Assert(session.binding.draftText("quota"), "10")
    // A writable field in the same structure still accepts typing.
    var writableNode: ?CjguiComposableUiNode = None
    let pending = ArrayList<CjguiComposableUiNode>()
    pending.add(root)
    while (pending.size > 0) {
        let current = pending.remove(at: pending.size - 1)
        if (current.nodeKind == CJGUI_COMPOSABLE_UI_TEXT_INPUT && current.fieldId == "title") {
            writableNode = Some(current)
        }
        for (child in current.children()) { pending.add(child) }
    }
    let writable = CjguiComposableUiLayoutNode(match (writableNode) {
        case Some(value) => value
        case None => @Assert(false); return
    }, CjguiComposableUiRect(0, 0, 100, 32), CjguiComposableUiRect(0, 0, 100, 32))
    let writableEdit = session.region.handleEventIfClaimed(CjguiComposableUiEvent(writable,
        CJGUI_COMPOSABLE_UI_EVENT_TEXT_CHANGED, "可写-新", 0, 0, 1))
    @Assert(writableEdit.getOrThrow().didApply, true)
    @Assert(session.binding.draftText("title"), "可写-新")
    session.close()
}

@Test
func prototypeGeneratedStructureCannotFlipDeclaredReadOnly(): Unit {
    let session = prototypeReadOnlySession()
    // A generated candidate may not turn the business read-only fact writable.
    let override = """
GENERATED_UI_STRUCTURE 1
NODE 0 ro-root vertical
NODE 1 field-code textInput field=code
PROPERTY 1 field-code label 只读编号
PROPERTY 1 field-code readOnly true
END
"""
    let submit = session.region.submitStructure(override, session.region.acceptedStructureVersion())
    @Assert(submit.candidateAccepted, false)
    // The catalog still reports the DECLARED fact after the refused override.
    let payload = session.region.fieldsPayload()
    @Assert(payload.contains("READONLY 1"), true)
    session.close()
}

// Candidate B regression: assert the rendered facts, not merely owner refusal.
@Test
func prototypeReadOnlyStepperRendersReadOnlyInputAndDisabledButtons(): Unit {
    let session = prototypeReadOnlySession()
    let submit = session.region.submitStructure(prototypeReadOnlyStructure, session.region.acceptedStructureVersion())
    @Assert(submit.candidateAccepted, true)
    @Assert(session.region.beginSceneRefresh(), true)
    let root = session.region.buildNode()
    session.region.commitSceneRefresh()
    let input = prototypeStepperFindNode(root, CJGUI_COMPOSABLE_UI_INTEGER_INPUT, "").getOrThrow()
    @Assert(input.isReadOnly, true)
    @Assert(input.isEnabled, true) // viewing/selection remains available
    let up = prototypeStepperFindNode(root, CJGUI_COMPOSABLE_UI_BUTTON, "cjgui-step-increment:").getOrThrow()
    let down = prototypeStepperFindNode(root, CJGUI_COMPOSABLE_UI_BUTTON, "cjgui-step-decrement:").getOrThrow()
    @Assert(up.isEnabled, false)
    @Assert(down.isEnabled, false)
    let text = prototypeStepperFindNode(root, CJGUI_COMPOSABLE_UI_TEXT_INPUT, "").getOrThrow()
    @Assert(text.isEnabled, true)
    session.close()
}

@Test
func prototypeHandwrittenHelperInheritsDescriptorReadOnly(): Unit {
    let session = prototypeReadOnlySession()
    let snapshot = session.domain.activeObject().formSnapshot()
    for (descriptor in prototypeFormBinding(session.project).allFields()) {
        let built = cjguiComposableBoundFormField(810, "manual", 811, 812, descriptor,
            snapshot.fieldForResourceId(descriptor.resourceId), session.binding.fieldOperationResourceId(descriptor.fieldId),
            CjguiComposableUiStyle(), CjguiComposableUiStyle())
        let input = built.children()[0]
        @Assert(input.isReadOnly, descriptor.readOnly)
        @Assert(input.isEnabled, true)
        let tightened = cjguiComposableBoundFormField(820, "manual-tight", 821, 822, descriptor,
            snapshot.fieldForResourceId(descriptor.resourceId), session.binding.fieldOperationResourceId(descriptor.fieldId),
            CjguiComposableUiStyle(), CjguiComposableUiStyle(), readOnly: true)
        @Assert(tightened.children()[0].isReadOnly, true)
        let disabled = cjguiComposableBoundFormField(830, "manual-disabled", 831, 832, descriptor,
            snapshot.fieldForResourceId(descriptor.resourceId), session.binding.fieldOperationResourceId(descriptor.fieldId),
            CjguiComposableUiStyle(), CjguiComposableUiStyle(), enabled: false)
        @Assert(disabled.children()[0].isEnabled, false)
    }
    session.close()
}

@Test
func prototypeReadOnlyAvailabilityAgreesWithOwnerAndDiscovery(): Unit {
    let session = prototypeReadOnlySession()
    let state = session.binding.fieldAvailability("quota")
    @Assert(state.known, true)
    @Assert(state.isAvailable, false)
    @Assert(state.reason, "field_read_only")
    @Assert(session.binding.fieldAvailability("title").isAvailable, true)
    @Assert(session.binding.fieldAvailability("missing").known, false)
    let capabilities = session.region.capabilitiesPayload()
    for (line in capabilities.split("\n")) {
        if (line.startsWith("FIELD quota ")) { @Assert(line.contains("callable=0"), true) }
        if (line.startsWith("FIELD title ")) { @Assert(line.contains("callable=1"), true) }
    }
    session.close()
}

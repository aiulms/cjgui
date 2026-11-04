// Consumer contract for the mixed form's accessible field and Apply state.
// This checks the application's ordinary semantic projection and owner route;
// it is not a VoiceOver navigation or speech test. Those require the separately
// retained system-caption evidence in the normal app.
package cjgui_mixed_form_starter

import cjgui.*
import std.unittest.*
import std.unittest.testmacro.*

private func mixedAccessibilityScene(controller: MixedFormController, version: Int64): CjguiComposableUiScene {
    let root = controller.buildUi()
    let rect = CjguiComposableUiRect(0, 0, 1000, 680)
    let identity = CjguiComposableUiIdentityRegistry()
    if (!identity.beginCandidate()) {
        throw IllegalStateException("mixed_accessibility_identity_candidate")
    }
    let _ = identity.resolveCandidate(root)
    let _ = identity.replaceCandidateRoot(root)
    let scene = CjguiComposableUiLayoutEngine.layoutWithMetrics(root, rect, version,
        CjguiComposableUiFallbackTextMeasurer(), identityRegistry: Some(identity)).scene
    if (!identity.prepareCandidate()) {
        throw IllegalStateException("mixed_accessibility_identity_prepare")
    }
    return scene
}

private func mixedAccessibilityField(scene: CjguiComposableUiScene, ownerId: Int64): CjguiComposableUiLayoutNode {
    for (node in scene.nodes()) {
        if (node.fieldId == "jobName" && node.operationResourceId == ownerId) {
            return node
        }
    }
    throw IllegalStateException("mixed_accessibility_job_name_field_missing")
}

private func mixedAccessibilityAction(scene: CjguiComposableUiScene, actionName: String,
    ownerId: Int64): CjguiComposableUiLayoutNode {
    for (node in scene.nodes()) {
        if (node.actionName == actionName && node.resourceId == ownerId) {
            return node
        }
    }
    throw IllegalStateException("mixed_accessibility_action_missing:${actionName}")
}

@Test
func mixedAccessibleFieldAndApplyStayBoundToCardOwner(): Unit {
    let domain = PrintPresetDomain()
    let card = domain.cards.card("cardA").getOrThrow()
    let controller = MixedFormController(domain)
    let initial = mixedAccessibilityScene(controller, 1)
    let fieldBefore = mixedAccessibilityField(initial, card.ownerId)
    let applyBefore = mixedAccessibilityAction(initial, "APPLY_DRAFT", card.ownerId)
    let cancelBefore = mixedAccessibilityAction(initial, "CANCEL_DRAFT", card.ownerId)

    @Assert(fieldBefore.nodeKind, CJGUI_COMPOSABLE_UI_TEXT_INPUT)
    @Assert(fieldBefore.label, "打印任务")
    @Assert(fieldBefore.value, "资料 A")
    @Assert(fieldBefore.semanticRole, CJGUI_COMPOSABLE_UI_SEMANTIC_AUTO)
    @Assert(fieldBefore.isEnabled, true)
    @Assert(fieldBefore.operationActionName, "EDIT_DRAFT_TEXT")
    @Assert(fieldBefore.operationResourceId, card.ownerId)
    @Assert(fieldBefore.semanticHelp.size > 0, true)

    @Assert(applyBefore.nodeKind, CJGUI_COMPOSABLE_UI_BUTTON)
    @Assert(applyBefore.semanticRole, CJGUI_COMPOSABLE_UI_SEMANTIC_BUTTON)
    @Assert(applyBefore.label, "应用")
    @Assert(applyBefore.actionName, "APPLY_DRAFT")
    @Assert(applyBefore.resourceId, card.ownerId)
    @Assert(applyBefore.isEnabled, true)
    @Assert(cancelBefore.semanticRole, CJGUI_COMPOSABLE_UI_SEMANTIC_BUTTON)
    @Assert(cancelBefore.label, "还原")
    @Assert(cancelBefore.resourceId, card.ownerId)
    @Assert(cancelBefore.isEnabled, false)
    @Assert(card.draftText("jobName"), card.appliedText("jobName"))

    @Assert(card.setText("jobName", "VO正文检查"), true)
    @Assert(card.draftText("jobName"), "VO正文检查")
    @Assert(card.appliedText("jobName"), "资料 A")

    let dirty = mixedAccessibilityScene(controller, 2)
    let fieldDirty = mixedAccessibilityField(dirty, card.ownerId)
    let applyDirty = mixedAccessibilityAction(dirty, "APPLY_DRAFT", card.ownerId)
    let cancelDirty = mixedAccessibilityAction(dirty, "CANCEL_DRAFT", card.ownerId)
    @Assert(fieldDirty.label, "打印任务")
    @Assert(fieldDirty.value, "VO正文检查")
    @Assert(fieldDirty.operationResourceId, card.ownerId)
    @Assert(applyDirty.label, "应用")
    @Assert(applyDirty.semanticRole, CJGUI_COMPOSABLE_UI_SEMANTIC_BUTTON)
    @Assert(applyDirty.resourceId, card.ownerId)
    @Assert(applyDirty.isEnabled, true)
    @Assert(cancelDirty.isEnabled, true)

    let action = controller.applyUiEvent(CjguiComposableUiEvent(applyDirty,
        CJGUI_COMPOSABLE_UI_EVENT_ACTIVATE, "", 0, 0, 2))
    @Assert(action.didApply, true)
    @Assert(card.draftText("jobName"), "VO正文检查")
    @Assert(card.appliedText("jobName"), "VO正文检查")

    let applied = mixedAccessibilityScene(controller, 3)
    let fieldApplied = mixedAccessibilityField(applied, card.ownerId)
    let applyApplied = mixedAccessibilityAction(applied, "APPLY_DRAFT", card.ownerId)
    let cancelApplied = mixedAccessibilityAction(applied, "CANCEL_DRAFT", card.ownerId)
    @Assert(fieldApplied.label, "打印任务")
    @Assert(fieldApplied.value, "VO正文检查")
    @Assert(fieldApplied.operationResourceId, card.ownerId)
    @Assert(applyApplied.isEnabled, true)
    @Assert(cancelApplied.isEnabled, false)
}

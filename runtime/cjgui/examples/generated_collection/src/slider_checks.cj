package cjgui_generated_collection

import cjgui.*
import cjgui_shared_operation_core.*
import std.collection.*

func checkSliderVisual(): Int64 {
    let slider = cjguiComposableSlider(901, "check-slider", 50, 0, 100, 5,
        CjguiComposableUiStyle(fixedWidth: 200, fixedHeight: 28))
    let root = cjguiComposableVertical(900, "slider-check-root", CjguiComposableUiStyle())
    root.add(slider)
    let standalone = CjguiComposableUiLayoutEngine.layout(root, CjguiComposableUiRect(0, 0, 200, 28), 1)
    if (!standalone.isValid() || standalone.nodes().size != 5) { return 205 }
    let identities = CjguiComposableUiIdentityRegistry()
    if (!identities.beginCandidate() || identities.resolveCandidate(root).size > 0) { return 200 }
    let scene = CjguiComposableUiLayoutEngine.layoutWithMetrics(root, CjguiComposableUiRect(0, 0, 200, 28),
        1, CjguiComposableUiFallbackTextMeasurer(), identityRegistry: Some(identities)).scene
    if (!scene.isValid() || slider.children().size != 3 || scene.nodes().size != 5) {
        println("SLIDER_RED missing common track/fill/thumb")
        return 201
    }
    var painted: Int64 = 0
    for (node in scene.nodes()) {
        if (node.nodeId != 900 && node.nodeId != 901 && node.style.background.alpha > 0.0 &&
            node.bounds.width > 0 && node.bounds.height > 0) { painted += 1 }
    }
    if (painted != 3) { return 202 }
    let bounds = CjguiComposableUiRect(10, 20, 200, 28)
    if (cjguiSliderThumbBounds(bounds, 0, 0, 100).x != 10 ||
        cjguiSliderThumbBounds(bounds, 100, 0, 100).x != 194 ||
        cjguiSliderValueForPointer(-20, bounds, 0, 100, 30) != 0 ||
        cjguiSliderValueForPointer(300, bounds, 0, 100, 30) != 100 ||
        cjguiSliderValueForPointer(110, bounds, -50, 50, 5) != 0) { return 206 }
    let disabled = cjguiComposableSlider(902, "disabled-slider", 5, 0, 10, 1,
        CjguiComposableUiStyle(fixedHeight: 28), enabled: false)
    if (disabled.children()[0].style.background.alpha >= slider.children()[0].style.background.alpha ||
        CjguiComposableUiLayoutNode(disabled, bounds, bounds).canReceiveInput()) { return 207 }
    println("SLIDER_VISUAL_CHECKS_OK common_three_primitives standalone_layout geometry_endpoints negative_range disabled")
    return 0
}

func checkSliderGeneratedRegistration(): Int64 {
    let catalog = CjguiGeneratedUiCapabilityCatalog()
    if (!catalog.registerComponent(cjguiGeneratedSliderComponent())) {
        println("SLIDER_RED generated slider registration rejected ${catalog.lastRegistrationRejection()}")
        return 203
    }
    let _ = catalog.registerField(CjguiGeneratedUiFieldSpec("count", "Count", "INTEGER", 123,
        minimum: 0, maximum: 100))
    let validation = CjguiGeneratedUiValidator(catalog).validate(
        CjguiGeneratedUiNodeSpec("count-slider", "slider", fieldId: "count"))
    if (!validation.accepted) { return 204 }
    let invalidStep = HashMap<String, String>()
    invalidStep.add("step", "0")
    if (CjguiGeneratedUiValidator(catalog).validate(CjguiGeneratedUiNodeSpec("bad-step", "slider",
        properties: invalidStep, fieldId: "count")).accepted) { return 208 }
    let boundsOverride = HashMap<String, String>()
    boundsOverride.add("maximum", "900")
    if (CjguiGeneratedUiValidator(catalog).validate(CjguiGeneratedUiNodeSpec("bad-bounds", "slider",
        properties: boundsOverride, fieldId: "count")).accepted) { return 209 }
    let _ = catalog.registerField(CjguiGeneratedUiFieldSpec("name", "Name", "TEXT", 124))
    if (CjguiGeneratedUiValidator(catalog).validate(CjguiGeneratedUiNodeSpec("wrong-field", "slider",
        fieldId: "name")).accepted) { return 210 }
    println("SLIDER_GENERATED_CHECKS_OK integer_field registered_constraints positive_step no_bounds_override")
    return 0
}

func sliderCheckNode(controller: CollectionController, step!: Int64 = 1): CjguiComposableUiLayoutNode {
    let field = controller.catalog.fieldFor("retentionCount").getOrThrow()
    let node = cjguiComposableFieldSlider(62, "manual-retention-slider", field, controller.binding,
        CjguiComposableUiStyle(fixedHeight: 32), step: step)
    let bounds = CjguiComposableUiRect(0, 0, 200, 32)
    return CjguiComposableUiLayoutNode(node, bounds, bounds)
}

func sliderCheckWrite(controller: CollectionController, text: String): Bool {
    let field = controller.catalog.fieldFor("retentionCount").getOrThrow()
    return controller.binding.applyFieldIntent(CjguiGeneratedUiIntent(CJGUI_GENERATED_INTENT_FIELD_EDIT,
        "slider-check", "", fieldId: field.fieldId, writerOperation: field.writeActionName,
        ownerTargetResourceId: controller.binding.fieldOperationResourceId(field.fieldId),
        argumentName: field.argumentName, value: CjguiSharedOperationValue.string(text))).didApply
}

func checkSliderBinding(controller: CollectionController): Int64 {
    let original = sliderCheckNode(controller)
    if (!controller.region.handleFieldSliderEvent(CjguiComposableUiEvent(original, 35, "right", 0, 0, 1)).didApply ||
        controller.binding.draftText("retentionCount") != "8" ||
        controller.binding.appliedText("retentionCount") != "7") { return 211 }
    let frozen = controller.region.sliderCaptureMapping(original)
    if (frozen.isNone() || frozen.getOrThrow().value != 7) { return 212 }
    let after = controller.domain.version()
    if (controller.region.handleFieldSliderEvent(CjguiComposableUiEvent(original, 35, "right", 0, 0, 1)).didApply ||
        controller.domain.version() != after) { return 213 }
    if (!sliderCheckWrite(controller, "007")) { return 214 }
    if (!controller.region.handleFieldSliderEvent(CjguiComposableUiEvent(sliderCheckNode(controller, step: 5),
        35, "right", 0, 0, 2)).didApply || controller.binding.draftText("retentionCount") != "12") { return 215 }
    if (!sliderCheckWrite(controller, "90") ||
        !controller.region.handleFieldSliderEvent(CjguiComposableUiEvent(sliderCheckNode(controller),
        35, "right", 0, 0, 3)).didApply || controller.binding.draftText("retentionCount") != "90") { return 216 }
    let field = controller.catalog.fieldFor("retentionCount").getOrThrow()
    for (draft in ["", "-", "abc", "9223372036854775808", "0", "91"]) {
        if (!sliderCheckWrite(controller, draft)) { return 217 }
        let invalid = cjguiComposableFieldSlider(62, "invalid-slider", field, controller.binding,
            CjguiComposableUiStyle(fixedHeight: 32))
        if (invalid.nodeKind == CJGUI_COMPOSABLE_UI_SLIDER || invalid.value.size == 0 ||
            controller.binding.draftText(field.fieldId) != draft) { return 218 }
    }
    if (!sliderCheckWrite(controller, "9")) { return 219 }
    let beforeReject = controller.domain.version()
    let rect = CjguiComposableUiRect(0, 0, 200, 32)
    for (enabled in [true, false]) {
        let bad = cjguiComposableSlider(62, "bad-slider", 9, field.minimum, field.maximum, 1,
            CjguiComposableUiStyle(), fieldId: field.fieldId, resourceId: field.resourceId,
            operationActionName: field.writeActionName,
            operationResourceId: if (enabled) { 99999 } else { controller.binding.fieldOperationResourceId(field.fieldId) },
            enabled: enabled)
        if (controller.region.handleFieldSliderEvent(CjguiComposableUiEvent(
            CjguiComposableUiLayoutNode(bad, rect, rect), 35, "right", 0, 0, 4)).didApply ||
            controller.domain.version() != beforeReject) { return 220 }
    }
    println("SLIDER_BINDING_CHECKS_OK exact_owner frozen_projection stale_node_rejected step_bounds noncanonical_decimal invalid_drafts disabled foreign_owner")
    return 0
}

class SliderCheckProjection <: CjguiSharedOperationWindowProjectionProvider {
    let projection: CjguiSharedOperationWindowProjection
    init(projection: CjguiSharedOperationWindowProjection) { this.projection = projection }
    public func windowProjection(): CjguiSharedOperationWindowProjection { return projection }
}

func checkSliderContext(controller: CollectionController): Int64 {
    let root = controller.buildUi()
    let identities = CjguiComposableUiIdentityRegistry()
    if (!identities.beginCandidate() || identities.resolveCandidate(root).size > 0) { return 221 }
    let scene = CjguiComposableUiLayoutEngine.layoutWithMetrics(root, CjguiComposableUiRect(0, 0, 1000, 640),
        1, CjguiComposableUiFallbackTextMeasurer(), identityRegistry: Some(identities)).scene
    if (!scene.isValid()) { println("SLIDER_CONTEXT invalid_layout"); return 222 }
    return checkSliderProjection(controller, CjguiComposableUiWindowProjectionBuilder.fromScene(root, scene))
}

func checkSliderProjection(controller: CollectionController, projection: CjguiSharedOperationWindowProjection): Int64 {
    let scopes = ArrayList<CjguiSharedOperationExternalActionScope>([
        CjguiSharedOperationExternalActionScope("GET_CONTEXT", ArrayList<Int64>(), true),
        CjguiSharedOperationExternalActionScope("EDIT_DRAFT_TEXT", ArrayList<Int64>(), true)])
    let connection = CjguiSharedOperationExternalConnection(controller.domain,
        CjguiSharedOperationExternalAuthorization("slider-check", "slider-check", scopes), SliderCheckProjection(projection))
    let response = connection.dispatchPayload("PROTOCOL CJGUI_SHARED_OPERATION/2\nAUTH slider-check\nGET_CONTEXT 0")
    if (response.contains("KIND ERROR")) {
        println("SLIDER_CONTEXT_RED ${response}")
        let headless = CjguiSharedOperationExternalConnection(controller.domain,
            CjguiSharedOperationExternalAuthorization("slider-check", "slider-check", scopes))
        let domainResponse = headless.dispatchPayload("PROTOCOL CJGUI_SHARED_OPERATION/2\nAUTH slider-check\nGET_CONTEXT 0")
        println("CONTEXT_DOMAIN valid=${!domainResponse.contains("KIND ERROR")}")
        let snapshot = controller.domain.contextSnapshot()
        println("CONTEXT_SNAPSHOT type=${snapshot.resourceType} stream=${snapshot.streamIdentity} name=${snapshot.contextName}")
        println("CONTEXT_PROGRESS active=${projection.isActive} scene=${projection.sceneVersion} native=${projection.nativeSubmissionVersion} " +
            "state=${projection.presentationState} session=${projection.sessionIdentity} accepted=${projection.acceptedSceneVersion} " +
            "submitted=${projection.submittedSceneVersion} frame=${projection.submittedFrameIndex} " +
            "pending=${projection.pendingRefreshReason} failure=${projection.lastNativeFailure}")
        for (field in projection.fieldValues) {
            println("CONTEXT_FIELD ${field.nodeSemanticId} ${field.resourceId} ${field.fieldId} ${field.displayValueRole} ${field.valueSource} ${field.value.valueType}")
        }
        for (collection in projection.collections) {
            println("CONTEXT_COLLECTION ${collection.semanticId} ${collection.totalCount} ${collection.materializedStart} ${collection.materializedEnd} ${collection.selectedKey} ${collection.focusedKey}")
        }
        for (node in projection.nodes) { println("CONTEXT_NODE ${node.nodeId} ${node.semanticId} ${node.nodeKind}") }
        for (relation in projection.relations) {
            println("CONTEXT_RELATION ${relation.sourceKind} ${relation.sourceId} ${relation.relation} ${relation.targetKind} ${relation.targetId}")
        }
        return 223
    }
    if (!response.contains("ACTION EDIT_DRAFT_TEXT PARAMETERS")) { return 224 }
    println("SLIDER_CONTEXT_CHECKS_OK production_transport exact_projection field_writer_metadata")
    return 0
}

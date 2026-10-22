package cjgui

import cjgui_shared_operation_core.*
import std.collection.*
import std.convert.*
import std.math.*
import std.overflow.*

/// Experimental, value-only slider paint. It uses ordinary rounded rectangles;
/// the slider's existing input node remains the only hit/focus/AX target.
public class CjguiComposableUiSliderAppearance {
    public let track: CjguiComposableUiColor
    public let fill: CjguiComposableUiColor
    public let thumb: CjguiComposableUiColor
    public let thumbDiameter: Int64
    public let trackThickness: Int64
    public init(track!: CjguiComposableUiColor = CjguiComposableUiColor(0.30, 0.35, 0.44, 1.0),
        fill!: CjguiComposableUiColor = CjguiComposableUiColor(0.22, 0.52, 0.95, 1.0),
        thumb!: CjguiComposableUiColor = CjguiComposableUiColor(0.95, 0.97, 1.0, 1.0),
        thumbDiameter!: Int64 = 16, trackThickness!: Int64 = 4) {
        this.track = track; this.fill = fill; this.thumb = thumb
        this.thumbDiameter = if (thumbDiameter > 0 && thumbDiameter <= 64) { thumbDiameter } else { 16 }
        this.trackThickness = if (trackThickness > 0 && trackThickness <= 16) { trackThickness } else { 4 }
    }
    public static func fromTheme(theme: CjguiComposableUiTheme): CjguiComposableUiSliderAppearance {
        return CjguiComposableUiSliderAppearance(track: theme.card.border, fill: theme.primaryAction.background,
            thumb: theme.heading.textColor)
    }
}

public func cjguiComposableSliderInteractionStyle(): CjguiComposableUiInteractionStyle {
    let accent = CjguiComposableUiColor(0.22, 0.52, 0.95, 1.0)
    return CjguiComposableUiInteractionStyle(
        hover: CjguiComposableUiPaintStyle(border: Some(accent), borderWidth: Some(1)),
        pressed: CjguiComposableUiPaintStyle(border: Some(accent), borderWidth: Some(2)),
        focused: CjguiComposableUiPaintStyle(border: Some(accent), borderWidth: Some(2)))
}

func cjguiSliderOpacity(color: CjguiComposableUiColor, enabled: Bool): CjguiComposableUiColor {
    return CjguiComposableUiColor(color.red, color.green, color.blue, color.alpha * if (enabled) { 1.0 } else { 0.4 })
}

func cjguiAddSliderPaint(node: CjguiComposableUiNode, appearance: CjguiComposableUiSliderAppearance): Unit {
    let scope = CjguiComposableUiIdentityScope("cjgui-slider-${node.nodeId}")
    let colors = [appearance.track, appearance.fill, appearance.thumb]
    let names = ["track", "fill", "thumb"]
    for (index in 0..3) {
        let style = CjguiComposableUiStyle(fixedHeight: appearance.trackThickness,
            background: cjguiSliderOpacity(colors[index], node.isEnabled),
            border: if (index == 2) { cjguiSliderOpacity(appearance.fill, node.isEnabled) }
                else { CjguiComposableUiColor(0.0, 0.0, 0.0, 0.0) },
            borderWidth: if (index == 2) { 2 } else { 0 },
            cornerRadius: if (index == 2) { appearance.thumbDiameter / 2 } else { appearance.trackThickness / 2 })
        node.add(CjguiComposableUiNode(-1, "slider-${node.nodeId}-${names[index]}", CJGUI_COMPOSABLE_UI_HORIZONTAL,
            "", "", "", -1, style, identity: Some(scope.local(names[index]))))
    }
}

public func cjguiSliderThumbLength(bounds: CjguiComposableUiRect, requested: Int64): Int64 {
    var length = if (requested > 0) { requested } else { 16 }
    if (length > bounds.width) { length = bounds.width }
    if (length > bounds.height) { length = bounds.height }
    return if (length > 0) { length } else { 0 }
}

public func cjguiSliderThumbBounds(bounds: CjguiComposableUiRect, value: Int64, minimum: Int64,
    maximum: Int64, thumbDiameter!: Int64 = 16): CjguiComposableUiRect {
    let size = cjguiSliderThumbLength(bounds, thumbDiameter)
    let fraction = if (maximum > minimum) {
        (Float64(CjguiComposableUiSliderGeometry.clampValue(value, minimum, maximum)) - Float64(minimum)) /
            (Float64(maximum) - Float64(minimum))
    } else { 0.0 }
    return CjguiComposableUiRect(bounds.x + Int64(Float64(bounds.width - size) * fraction),
        bounds.y + (bounds.height - size) / 2, size, size)
}

public func cjguiSliderValueForPointer(pointer: Int64, bounds: CjguiComposableUiRect, minimum: Int64,
    maximum: Int64, step: Int64, thumbDiameter!: Int64 = 16): Int64 {
    let size = cjguiSliderThumbLength(bounds, thumbDiameter)
    let travel = bounds.width - size
    let fraction = if (travel > 0) {
        (Float64(pointer) - Float64(bounds.x) - Float64(size) / 2.0) / Float64(travel)
    } else { 0.0 }
    return cjguiSliderValueForFraction(fraction, minimum, maximum, step)
}

func cjguiSliderValueForFraction(fraction: Float64, minimum: Int64, maximum: Int64, step: Int64): Int64 {
    if (maximum <= minimum || fraction <= 0.0) { return minimum }
    if (fraction >= 1.0) { return maximum }
    let safeStep = if (step > 0) { step } else { 1 }
    let steps = round((Float64(maximum) - Float64(minimum)) * fraction / Float64(safeStep))
    let value = Float64(minimum) + steps * Float64(safeStep)
    if (value <= Float64(minimum)) { return minimum }
    if (value >= Float64(maximum)) { return maximum }
    return Int64(value)
}

// A previously leaf-only manual slider also works through layout(root,...).
// Resolve only framework paint identities in an otherwise manual tree. User
// scoped declarations still require the caller's explicit candidate registry.
func cjguiStandaloneSliderTree(node: CjguiComposableUiNode): (Bool, Bool) {
    if (node.scopedIdentity().isSome()) { return (false, false) }
    let children = node.children()
    if (node.nodeKind == CJGUI_COMPOSABLE_UI_SLIDER && children.size == 3) {
        let names = ["track", "fill", "thumb"]
        for (index in 0..3) {
            if (children[index].semanticId != "slider-${node.nodeId}-${names[index]}" ||
                children[index].nodeKind != CJGUI_COMPOSABLE_UI_HORIZONTAL ||
                children[index].children().size != 0) { return (false, false) }
        }
        return (true, true)
    }
    var hasSlider = false
    for (child in children) {
        let (manual, slider) = cjguiStandaloneSliderTree(child)
        if (!manual) { return (false, false) }
        hasSlider = hasSlider || slider
    }
    return (true, hasSlider)
}

func cjguiStandaloneSliderRegistry(root: CjguiComposableUiNode): ?CjguiComposableUiIdentityRegistry {
    let (manual, hasSlider) = cjguiStandaloneSliderTree(root)
    if (!manual || !hasSlider) { return None }
    let registry = CjguiComposableUiIdentityRegistry()
    if (!registry.beginCandidate() || registry.resolveCandidate(root).size > 0) { return None }
    return Some(registry)
}

func cjguiSliderPaintBounds(node: CjguiComposableUiNode, bounds: CjguiComposableUiRect): Array<CjguiComposableUiRect> {
    let thumb = cjguiSliderThumbBounds(bounds, Int64.tryParse(node.value) ?? node.pointerControlMinimum,
        node.pointerControlMinimum, node.pointerControlMaximum, thumbDiameter: node.pointerControlHandleThickness)
    let thickness = if (node.children()[0].style.fixedHeight < bounds.height) {
        node.children()[0].style.fixedHeight
    } else { bounds.height }
    let x = bounds.x + thumb.width / 2
    let y = bounds.y + (bounds.height - thickness) / 2
    return [CjguiComposableUiRect(x, y, bounds.width - thumb.width, thickness),
        CjguiComposableUiRect(x, y, thumb.x - bounds.x, thickness), thumb]
}

/// Strict decimal drafts retain their original text. Empty, sign-only,
/// overflow and non-decimal drafts never acquire a numeric zero projection.
func cjguiSliderDraft(text: String): ?Int64 {
    if (text.size == 0 || text == "-") { return None }
    var index: Int64 = 0
    for (byte in text.toArray()) {
        if (index == 0 && byte == b'-') { index += 1; continue }
        if (byte < b'0' || byte > b'9') { return None }
        index += 1
    }
    return Int64.tryParse(text)
}

public func cjguiComposableFieldSlider(nodeId: Int64, semanticId: String, field: CjguiGeneratedUiFieldSpec,
    provider: CjguiGeneratedUiBindingProvider, style: CjguiComposableUiStyle, step!: Int64 = 1,
    appearance!: CjguiComposableUiSliderAppearance = CjguiComposableUiSliderAppearance(),
    interactionStyle!: CjguiComposableUiInteractionStyle = cjguiComposableSliderInteractionStyle()): CjguiComposableUiNode {
    let draft = provider.draftText(field.fieldId)
    let parsed = cjguiSliderDraft(draft)
    let owner = provider.fieldOperationResourceId(field.fieldId)
    let availability = provider.fieldAvailability(field.fieldId)
    let valid = field.editorKind == "INTEGER" && field.maximum >= field.minimum && parsed.isSome() &&
        (parsed.getOrThrow() >= field.minimum && parsed.getOrThrow() <= field.maximum)
    if (!valid) {
        return cjguiComposableText(nodeId, semanticId, "${field.label}：无效整数草稿「${draft}」", style,
            resourceId: field.resourceId, fieldId: field.fieldId, displayValueRole: "invalid_draft", readOnly: true)
    }
    let node = cjguiComposableSlider(nodeId, semanticId, parsed.getOrThrow(), field.minimum, field.maximum,
        step, style, enabled: owner >= 0 && (!availability.known || availability.isAvailable),
        fieldId: field.fieldId, resourceId: field.resourceId, operationActionName: field.writeActionName,
        operationResourceId: owner, appearance: appearance, interactionStyle: interactionStyle)
    node.semanticLabel = field.label
    if (let Some(feedback) <- provider.formFeedback()) {
        if (let Some(descriptor) <- feedback.descriptorFor(field.fieldId)) {
            if (let Some(projection) <- feedback.fieldFor(field.fieldId)) {
                node.semanticHelp = cjguiComposableFormFieldHelp(descriptor, projection,
                    enabled: node.isEnabled, unavailableReason: availability.reason)
            }
        }
    }
    return node
}

/// Register this existing-field presentation explicitly in a capability catalog.
/// Bounds come from INTEGER FieldSpec, never a second generated schema.
public func cjguiGeneratedSliderComponent(): CjguiGeneratedUiComponentSpec {
    let properties = ArrayList<CjguiGeneratedUiPropertySpec>()
    for (property in CjguiGeneratedUiPresentation.leafStyleProperties()) {
        if (property.name != "letterSpacing" && property.name != "lineHeight") { properties.add(property) }
    }
    properties.add(CjguiGeneratedUiPropertySpec("label", "STRING", maxLength: 80))
    properties.add(CjguiGeneratedUiPropertySpec("step", "INTEGER", minimum: 1, maximum: 1000000, defaultValue: "1"))
    properties.add(CjguiGeneratedUiPropertySpec("thumbDiameter", "INTEGER", minimum: 1, maximum: 64, defaultValue: "16"))
    properties.add(CjguiGeneratedUiPropertySpec("trackThickness", "INTEGER", minimum: 1, maximum: 16, defaultValue: "4"))
    for (name in ["trackColor", "fillColor", "thumbColor"]) {
        properties.add(CjguiGeneratedUiPropertySpec(name, "STRING", maxLength: 40))
    }
    return CjguiGeneratedUiComponentSpec("slider", properties, false)
}

// Adapts the existing capture receipt protocol to the existing field writer.
// Only receipts and an independent-operation revision are retained. The owner
// remains the sole source of every draft, bound, availability and actual value.
class CjguiFieldSliderAdapter {
    let binding: CjguiGeneratedUiRegionBinding
    let fieldFor: (String) -> ?CjguiGeneratedUiFieldSpec
    var observedOwnerRevision: Int64 = -1
    var captureRevision: Int64 = 0
    let receipts = HashMap<String, CjguiComposableUiSliderCaptureReceipt>()
    init(binding: CjguiGeneratedUiRegionBinding, fieldFor: (String) -> ?CjguiGeneratedUiFieldSpec) {
        this.binding = binding; this.fieldFor = fieldFor
    }
    private func observeIndependentOwner(): Unit {
        let revision = binding.ownerRevision()
        if (revision != observedOwnerRevision) {
            captureRevision = captureRevision.saturatingAdd(1)
            observedOwnerRevision = revision
            receipts.clear()
        }
    }
    func version(): Int64 { observeIndependentOwner(); return captureRevision }
    private func matches(node: CjguiComposableUiLayoutNode, field: CjguiGeneratedUiFieldSpec): Bool {
        let available = binding.fieldAvailability(field.fieldId)
        return node.nodeKind == CJGUI_COMPOSABLE_UI_SLIDER && node.isEnabled && !node.isReadOnly &&
            field.editorKind == "INTEGER" && field.fieldId == node.fieldId && field.resourceId == node.resourceId &&
            field.writeActionName.size > 0 && field.writeActionName == node.operationActionName &&
            field.argumentName.size > 0 && node.operationResourceId >= 0 &&
            binding.fieldOperationResourceId(field.fieldId) == node.operationResourceId &&
            (!available.known || available.isAvailable) && node.pointerControlMinimum == field.minimum &&
            node.pointerControlMaximum == field.maximum && node.pointerControlStep > 0
    }
    func mapping(node: CjguiComposableUiLayoutNode): ?CjguiComposableUiSliderCaptureMapping {
        observeIndependentOwner()
        let field = match (fieldFor(node.fieldId)) { case Some(value) => value; case None => return None }
        if (!matches(node, field)) { return None }
        // Publication facts belong to the accepted node. The actual owner may
        // already contain this intent's output before its redraw is accepted.
        // commit reads that output separately through the existing receipt API.
        let value = match (cjguiSliderDraft(node.value)) {
            case Some(parsed) => parsed; case None => return None
        }
        if (value < field.minimum || value > field.maximum) { return None }
        let thumb = cjguiSliderThumbBounds(node.bounds, value, field.minimum, field.maximum,
            thumbDiameter: node.pointerControlHandleThickness)
        return Some(CjguiComposableUiSliderCaptureMapping(captureRevision, Float64(node.bounds.x),
            Float64(node.bounds.width), Float64(thumb.width), Float64(thumb.x), value,
            isVertical: false, outputReceipt: receipts.get(field.fieldId),
            outputReadback: Some({=> cjguiSliderDraft(binding.draftText(field.fieldId))})))
    }
    func handle(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        observeIndependentOwner()
        let node = event.node
        let field = match (fieldFor(node.fieldId)) {
            case Some(value) => value; case None => return CjguiComposableUiDispatchResult(false)
        }
        if (!matches(node, field)) { return CjguiComposableUiDispatchResult(false) }
        let current = match (cjguiSliderDraft(binding.draftText(field.fieldId))) {
            case Some(value) => value; case None => return CjguiComposableUiDispatchResult(false)
        }
        if (current < field.minimum || current > field.maximum) { return CjguiComposableUiDispatchResult(false) }
        if ((event.sliderCaptureIntent.isNone() || event.eventKind == CJGUI_COMPOSABLE_UI_EVENT_POINTER_BEGIN) &&
            cjguiSliderDraft(node.value) != Some(current)) { return CjguiComposableUiDispatchResult(false) }
        var next = current
        if (event.eventKind == 35) {
            let direction = if (event.text == "left" || event.text == "down") { -1 }
                else if (event.text == "right" || event.text == "up") { 1 } else { 0 }
            if (direction == 0) { return CjguiComposableUiDispatchResult(false) }
            next = CjguiComposableUiSliderGeometry.adjustValue(current, direction, field.minimum,
                field.maximum, node.pointerControlStep)
        } else if (event.eventKind == CJGUI_COMPOSABLE_UI_EVENT_POINTER_BEGIN ||
            event.eventKind == CJGUI_COMPOSABLE_UI_EVENT_POINTER_UPDATE ||
            event.eventKind == CJGUI_COMPOSABLE_UI_EVENT_POINTER_END) {
            if (let Some(capture) <- event.sliderCaptureIntent) {
                if (!capture.isCurrent()) { return CjguiComposableUiDispatchResult(false) }
                next = cjguiSliderValueForFraction(capture.fraction(), field.minimum, field.maximum,
                    node.pointerControlStep)
                let thumb = cjguiSliderThumbBounds(node.bounds, current, field.minimum, field.maximum,
                    thumbDiameter: node.pointerControlHandleThickness)
                if (event.eventKind == CJGUI_COMPOSABLE_UI_EVENT_POINTER_BEGIN &&
                    event.pointerX >= thumb.x && event.pointerX < thumb.x + thumb.width) { next = current }
            } else {
                next = cjguiSliderValueForPointer(event.pointerX, node.bounds, field.minimum, field.maximum,
                    node.pointerControlStep, thumbDiameter: node.pointerControlHandleThickness)
            }
        } else if (event.eventKind == CJGUI_COMPOSABLE_UI_EVENT_POINTER_CANCEL) {
            return CjguiComposableUiDispatchResult(true)
        } else { return CjguiComposableUiDispatchResult(false) }
        next = CjguiComposableUiSliderGeometry.clampValue(next, field.minimum, field.maximum)
        let intent = CjguiGeneratedUiIntent(CJGUI_GENERATED_INTENT_FIELD_EDIT, node.semanticId, "",
            fieldId: field.fieldId, writerOperation: field.writeActionName,
            ownerTargetResourceId: node.operationResourceId, argumentName: field.argumentName,
            value: CjguiSharedOperationValue.string(next.toString()))
        let result = binding.applyFieldIntent(intent)
        if (!result.didApply) { return result }
        // The serialized writer has completed. Acknowledge only that real
        // owner revision, then commit the existing input intent's readback.
        observedOwnerRevision = binding.ownerRevision()
        if (let Some(capture) <- event.sliderCaptureIntent) {
            if (let Some(receipt) <- capture.commit(next)) { receipts.add(field.fieldId, receipt) }
        } else {
            captureRevision = captureRevision.saturatingAdd(1)
            receipts.clear()
        }
        return result
    }
}

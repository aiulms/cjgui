// Retention integer editor: application configuration around the shared
// CjguiNumericStepper builder. The public builder owns the ordinary input,
// step buttons and preset layout; this application file owns the retention
// field name, declared presets and the owner actions.
package cjgui_rule_set_window_app

import cjgui.*
import cjgui_rule_set_application.*
import cjgui_shared_operation_core.*
import std.collection.*

/// One declared preset: the caption shown on the button and the constant it
/// writes. It is typed application configuration, never parsed from a UI string.
public class CjguiRetentionPreset {
    public let label: String
    public let value: String

    public init(label: String, value: String) {
        this.label = label
        this.value = value
    }
}

/// The declared preset set for the retention editor. `fromDeclaredBounds`
/// derives the presets from the field's own declared minimum/maximum (the single
/// business definition), while `explicit` exists for a dedicated negative
/// control that must hand the owner an out-of-range value.
public class CjguiRetentionPresetConfig {
    public let presets: ArrayList<CjguiRetentionPreset>

    public init(presets: ArrayList<CjguiRetentionPreset>) {
        this.presets = presets
    }

    public static func fromDeclaredBounds(minimum: Int64, maximum: Int64): CjguiRetentionPresetConfig {
        let presets = ArrayList<CjguiRetentionPreset>()
        if (maximum > minimum) {
            presets.add(CjguiRetentionPreset("设为 ${maximum}", "${maximum}"))
            presets.add(CjguiRetentionPreset("设为 ${(minimum + maximum) / 2}", "${(minimum + maximum) / 2}"))
        } else {
            presets.add(CjguiRetentionPreset("设为 ${maximum}", "${maximum}"))
        }
        return CjguiRetentionPresetConfig(presets)
    }

    /// A configuration whose single preset is deliberately outside the declared
    /// range, used only to prove the owner's rule refuses it.
    public static func explicit(value: String, label!: String = ""): CjguiRetentionPresetConfig {
        let presets = ArrayList<CjguiRetentionPreset>()
        presets.add(CjguiRetentionPreset(if (label.size > 0) { label } else { "设为 ${value}" }, value))
        return CjguiRetentionPresetConfig(presets)
    }

    public func primary(): CjguiRetentionPreset {
        return presets[0]
    }
}

/// The shared integer-edit composite. It delegates the actual ordinary-node
/// composition to `CjguiNumericStepper`; both the handwritten dialog and the
/// generated region call this same entry with different identities/bindings.
public class CjguiRetentionIntegerEditComposite <: CjguiCompositeComponentFactory {
    public static let KIND: String = "retentionIntegerEdit"
    public static let PRESET_ACTION: String = "APPLY_RETENTION_PRESET"
    public static let STEP_DOWN_ACTION: String = "STEP_RETENTION_DOWN"
    public static let STEP_UP_ACTION: String = "STEP_RETENTION_UP"

    private let config: CjguiRetentionPresetConfig
    private let minimum: Int64
    private let maximum: Int64
    private let step: Int64

    public init(config: CjguiRetentionPresetConfig, minimum!: Int64 = 1, maximum!: Int64 = 1000000,
                step!: Int64 = 1) {
        this.config = config
        this.minimum = minimum
        this.maximum = maximum
        this.step = if (step > 0) { step } else { 1 }
    }

    /// Registers the composite kind with the field/action references the window
    /// really exposes. The framework validates every reference.
    public static func registerInto(catalog: CjguiGeneratedUiCapabilityCatalog,
                                    config: CjguiRetentionPresetConfig,
                                    draftTextArgument: String): Bool {
        let field = match (catalog.fieldFor("retentionCount")) {
            case Some(value) => value
            case None => return false
        }
        let factory = CjguiRetentionIntegerEditComposite(config, minimum: field.minimum,
            maximum: field.maximum, step: 1)
        let properties = ArrayList<CjguiGeneratedUiPropertySpec>()
        properties.add(CjguiGeneratedUiPropertySpec("gap", "INTEGER", minimum: 0, maximum: 32))
        properties.add(CjguiGeneratedUiPropertySpec("presetLabel", "STRING", maxLength: 40))
        for (property in CjguiGeneratedUiPresentation.leafStyleProperties()) {
            properties.add(property)
        }
        let elements = ArrayList<CjguiCompositeElementSpec>()
        elements.add(CjguiCompositeElementSpec("root", CJGUI_COMPOSITE_ELEMENT_CONTAINER))
        elements.add(CjguiCompositeElementSpec("row", CJGUI_COMPOSITE_ELEMENT_CONTAINER, parentKey: "root"))
        elements.add(CjguiCompositeElementSpec("presets", CJGUI_COMPOSITE_ELEMENT_CONTAINER, parentKey: "root"))
        elements.add(CjguiCompositeElementSpec("edit", CJGUI_COMPOSITE_ELEMENT_FIELD,
            fieldId: "retentionCount", argumentName: draftTextArgument, parentKey: "row"))
        elements.add(CjguiCompositeElementSpec("decrement", CJGUI_COMPOSITE_ELEMENT_ACTION,
            actionName: STEP_DOWN_ACTION, parentKey: "row"))
        elements.add(CjguiCompositeElementSpec("increment", CJGUI_COMPOSITE_ELEMENT_ACTION,
            actionName: STEP_UP_ACTION, parentKey: "row"))
        let primary = config.primary()
        elements.add(CjguiCompositeElementSpec("preset", CJGUI_COMPOSITE_ELEMENT_PRESET,
            fieldId: "retentionCount", argumentName: draftTextArgument, presetValue: primary.value,
            label: primary.label, parentKey: "presets"))
        let _ = catalog.registerAction(CjguiGeneratedUiActionSpec(STEP_DOWN_ACTION, "减少保留天数",
            parameterNames: ArrayList<String>(["expectedDraftVersion"])))
        let _ = catalog.registerAction(CjguiGeneratedUiActionSpec(STEP_UP_ACTION, "增加保留天数",
            parameterNames: ArrayList<String>(["expectedDraftVersion"])))
        return catalog.registerComposite(
            CjguiCompositeComponentSpec(KIND, properties, elements,
                expandedNodeLimit: 16, expandedDepthLimit: 4), factory)
    }

    /// The single build entry used by both regions. The caller supplies the
    /// resolved binding, configured presets and style; no business value is
    /// stored here.
    public static func buildEditor(binding: CjguiNumericStepperBinding,
                                   presets: ArrayList<CjguiNumericStepperPreset>,
                                   style: CjguiNumericStepperStyle): CjguiComposableUiNode {
        return CjguiNumericStepper.build(binding, presets: presets, style: style)
    }

    /// Generated path: the framework already allocated the element identities and
    /// resolved the owner binding, so this only wires them into the shared build.
    public func buildComposite(context: CjguiCompositeBuildContext): CjguiComposableUiNode {
        let root = context.element("root") ?? CjguiCompositeElementBinding("root",
            CJGUI_COMPOSITE_ELEMENT_CONTAINER, -1, "", "")
        let row = context.element("row") ?? CjguiCompositeElementBinding("row",
            CJGUI_COMPOSITE_ELEMENT_CONTAINER, -1, "", "")
        let presetsBox = context.element("presets") ?? CjguiCompositeElementBinding("presets",
            CJGUI_COMPOSITE_ELEMENT_CONTAINER, -1, "", "")
        let edit = context.element("edit") ?? CjguiCompositeElementBinding("edit",
            CJGUI_COMPOSITE_ELEMENT_FIELD, -1, "", "")
        let decrement = context.element("decrement") ?? CjguiCompositeElementBinding("decrement",
            CJGUI_COMPOSITE_ELEMENT_ACTION, -1, "", "")
        let increment = context.element("increment") ?? CjguiCompositeElementBinding("increment",
            CJGUI_COMPOSITE_ELEMENT_ACTION, -1, "", "")
        let declaredLabel = context.property("presetLabel")
        let rowGap = context.propertyInteger("gap", fallback: 6)
        let declared = context.resolvedStyle
        let editorStyle = CjguiComposableUiStyle(fixedWidth: declared.fixedWidth,
            fixedHeight: if (declared.fixedHeight > 0) { declared.fixedHeight } else { 26 },
            growX: declared.growX, growY: declared.growY, fontSize: declared.fontSize,
            fontWeight: declared.fontWeight, minWidth: declared.minWidth, maxWidth: declared.maxWidth,
            minHeight: declared.minHeight, maxHeight: declared.maxHeight, alignX: declared.alignX,
            alignY: declared.alignY)
        let presetList = ArrayList<CjguiNumericStepperPreset>()
        var index: Int64 = 0
        for (configured in config.presets) {
            let key = if (index == 0) { "preset" } else { "preset${index}" }
            if (let Some(preset) <- context.element(key)) {
                let label = if (index == 0 && declaredLabel.size > 0) { declaredLabel } else {
                    if (preset.label.size > 0) { preset.label } else { configured.label }
                }
                presetList.add(CjguiNumericStepperPreset(key, preset.nodeId, label, preset.presetValue,
                    actionName: PRESET_ACTION, writerOperation: preset.writerOperation,
                    bindingResourceId: preset.bindingResourceId,
                    ownerTargetResourceId: preset.ownerTargetResourceId,
                    enabled: preset.ownerAvailable))
            }
            index += 1
        }
        let binding = CjguiNumericStepperBinding(root.nodeId, root.semanticId, row.nodeId, presetsBox.nodeId,
            edit.nodeId, edit.semanticId, decrement.nodeId, decrement.semanticId,
            increment.nodeId, increment.semanticId, edit.label, edit.draftText, minimum, maximum, step,
            edit.fieldId, edit.writerOperation, edit.bindingResourceId, edit.ownerTargetResourceId,
            "GENERATED_ACTION", "GENERATED_ACTION",
            enabled: edit.ownerAvailable && edit.ownerTargetResourceId >= 0,
            readOnly: false, feedback: if (edit.ownerAvailable) { "" } else { edit.blockedReason })
        let numericStyle = CjguiNumericStepperStyle(input: editorStyle,
            button: CjguiComposableUiStyle(fixedWidth: 30, fixedHeight: 26),
            preset: editorStyle, rowGap: rowGap)
        return buildEditor(binding, presetList, numericStyle)
    }
}

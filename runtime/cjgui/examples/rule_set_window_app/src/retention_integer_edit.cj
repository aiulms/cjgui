// ONE reusable integer-edit composite for the retention field: a numeric input
// plus a preset button, built by a single Cangjie implementation that BOTH the
// handwritten dialog and the runtime-generated region call.
//
// Why it lives here: the preset values are application business configuration,
// not framework knowledge. They are derived from the SAME declared field bounds
// the handwritten form and the external capability already use, so the app never
// keeps a second copy of the business limit. A dedicated negative-control
// configuration can declare an out-of-range preset; that value is sent to the
// owner unchanged, so the owner's rule refuses it instead of this widget
// silently clamping it.
//
// The write path is unchanged: the input writes the draft through the declared
// field writer, and the preset button resolves to the same field edit with its
// declared constant.
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
            // Bounds come from the shared field declaration; the midpoint is
            // derived, not copied.
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

/// The shared integer-edit composite. `buildEditor` is the ONE build
/// implementation; the generated region reaches it through
/// `buildComposite` (the framework passes framework-allocated identities and
/// resolved owner bindings), while the handwritten region calls it directly with
/// its own node ids.
public class CjguiRetentionIntegerEditComposite <: CjguiCompositeComponentFactory {
    public static let KIND: String = "retentionIntegerEdit"
    /// The preset button's declared action name. The generated region resolves
    /// the press through the framework's composite binding (element role
    /// `preset`), so this name never has to be interpreted by the framework; the
    /// handwritten region dispatches it to the same owner entry.
    public static let PRESET_ACTION: String = "APPLY_RETENTION_PRESET"

    private let config: CjguiRetentionPresetConfig

    public init(config: CjguiRetentionPresetConfig) {
        this.config = config
    }

    /// Registers the composite kind with the field/action references the window
    /// really exposes. The framework validates every reference.
    public static func registerInto(catalog: CjguiGeneratedUiCapabilityCatalog,
                                    config: CjguiRetentionPresetConfig): Bool {
        let properties = ArrayList<CjguiGeneratedUiPropertySpec>()
        properties.add(CjguiGeneratedUiPropertySpec("gap", "INTEGER", minimum: 0, maximum: 32))
        // The declared caption for the preset button. A generated description may
        // set it (the value is data, never code); empty keeps the configured
        // caption. It also lets one window present two unambiguous controls.
        properties.add(CjguiGeneratedUiPropertySpec("presetLabel", "STRING", maxLength: 40))
        let elements = ArrayList<CjguiCompositeElementSpec>()
        elements.add(CjguiCompositeElementSpec("root", CJGUI_COMPOSITE_ELEMENT_CONTAINER))
        elements.add(CjguiCompositeElementSpec("edit", CJGUI_COMPOSITE_ELEMENT_FIELD,
            fieldId: "retentionCount", parentKey: "root"))
        elements.add(CjguiCompositeElementSpec("preset", CJGUI_COMPOSITE_ELEMENT_PRESET,
            fieldId: "retentionCount", presetValue: config.primary().value,
            label: config.primary().label, parentKey: "root"))
        return catalog.registerComposite(
            CjguiCompositeComponentSpec(KIND, properties, elements,
                expandedNodeLimit: 4, expandedDepthLimit: 3),
            CjguiRetentionIntegerEditComposite(config))
    }

    /// The single build implementation. Both regions call this; only the ids and
    /// the resolved owner binding differ.
    public static func buildEditor(nodeId: Int64, semanticId: String, editorNodeId: Int64,
                                   presetNodeId: Int64, label: String, value: String, fieldId: String,
                                   writerOperation: String, bindingResourceId: Int64,
                                   ownerTargetResourceId: Int64, presetLabel: String,
                                   enabled!: Bool = true,
                                   style!: CjguiComposableUiStyle = CjguiComposableUiStyle()): CjguiComposableUiNode {
        let group = cjguiComposableHorizontal(nodeId, semanticId, CjguiComposableUiStyle(gap: 6))
        group.add(cjguiComposableIntegerInput(editorNodeId, "${semanticId}-editor", label, value,
            bindingResourceId, style, enabled: enabled && ownerTargetResourceId >= 0, fieldId: fieldId,
            operationActionName: writerOperation, operationResourceId: ownerTargetResourceId,
            displayValueRole: "draft"))
        // The preset button carries its resolved owner target, exactly like the
        // input: a late activation therefore writes the record it was rendered
        // for, never a later selection.
        group.add(cjguiComposableButton(presetNodeId, "${semanticId}-preset", presetLabel, PRESET_ACTION,
            bindingResourceId, style, enabled: enabled && ownerTargetResourceId >= 0,
            operationResourceId: ownerTargetResourceId))
        return group
    }

    /// Generated path: the framework already allocated the element identities and
    /// resolved the owner binding, so this only wires them into the shared build.
    public func buildComposite(context: CjguiCompositeBuildContext): CjguiComposableUiNode {
        let root = match (context.element("root")) {
            case Some(value) => value
            case None => CjguiCompositeElementBinding("root", CJGUI_COMPOSITE_ELEMENT_CONTAINER, -1, "", "")
        }
        let edit = match (context.element("edit")) {
            case Some(value) => value
            case None => CjguiCompositeElementBinding("edit", CJGUI_COMPOSITE_ELEMENT_FIELD, -1, "", "")
        }
        let preset = match (context.element("preset")) {
            case Some(value) => value
            case None => CjguiCompositeElementBinding("preset", CJGUI_COMPOSITE_ELEMENT_PRESET, -1, "", "")
        }
        let declaredLabel = context.property("presetLabel")
        let presetLabel = if (declaredLabel.size > 0) { declaredLabel } else { preset.label }
        return buildEditor(root.nodeId, root.semanticId, edit.nodeId, preset.nodeId, edit.label,
            edit.draftText, edit.fieldId, edit.writerOperation, edit.bindingResourceId,
            edit.ownerTargetResourceId, presetLabel,
            style: CjguiComposableUiStyle(fixedHeight: 26))
    }
}

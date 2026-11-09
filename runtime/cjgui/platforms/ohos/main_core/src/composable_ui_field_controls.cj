// Reusable ordinary-application field compositions.
//
// These are projections built from the existing composable nodes: an integer
// editor plus step/preset buttons, and a stable-key single-choice group. They do
// not own a business value, execute an action, create a timer or add a native
// control. The application supplies the field writer/owner target and action
// names; the same builder is used by handwritten and generated regions.
package cjgui

import cjgui_shared_operation_core.*
import std.collection.*
import std.overflow.*

public let CJGUI_NUMERIC_STEP_DOWN: Int64 = -1
public let CJGUI_NUMERIC_STEP_UP: Int64 = 1

/// One optional numeric preset. The value is application configuration, never
/// parsed from the visible label.
public class CjguiNumericStepperPreset {
    public let key: String
    public let nodeId: Int64
    public let semanticId: String
    public let label: String
    public let value: String
    public let actionName: String
    public let writerOperation: String
    public let bindingResourceId: Int64
    public let ownerTargetResourceId: Int64
    public let enabled: Bool

    public init(key: String, nodeId: Int64, label: String, value: String, actionName!: String = "",
                semanticId!: String = "", writerOperation!: String = "", bindingResourceId!: Int64 = -1,
                ownerTargetResourceId!: Int64 = -1, enabled!: Bool = true) {
        this.key = key
        this.nodeId = nodeId
        this.semanticId = semanticId
        this.label = label
        this.value = value
        this.actionName = actionName
        this.writerOperation = writerOperation
        this.bindingResourceId = bindingResourceId
        this.ownerTargetResourceId = ownerTargetResourceId
        this.enabled = enabled
    }
}

/// The one numeric step result. `issue` is a machine-facing reason; the caller
/// decides how to display it. An out-of-range target is refused, never clamped
/// into a value the owner did not accept.
public class CjguiNumericStepResult {
    public let text: String
    public let issue: String
    public let value: Int64

    public init(text: String, issue: String, value: Int64) {
        this.text = text
        this.issue = issue
        this.value = value
    }

    public func canWrite(): Bool {
        return issue.size == 0
    }
}

public class CjguiNumericStepperBinding {
    public let rootNodeId: Int64
    public let rootSemanticId: String
    public let rowNodeId: Int64
    public let presetsNodeId: Int64
    public let inputNodeId: Int64
    public let inputSemanticId: String
    public let decrementNodeId: Int64
    public let decrementSemanticId: String
    public let incrementNodeId: Int64
    public let incrementSemanticId: String
    public let feedbackNodeId: Int64
    public let label: String
    public let value: String
    public let minimum: Int64
    public let maximum: Int64
    public let step: Int64
    public let fieldId: String
    public let writerOperation: String
    public let bindingResourceId: Int64
    public let ownerTargetResourceId: Int64
    public let decrementAction: String
    public let incrementAction: String
    public let enabled: Bool
    public let readOnly: Bool
    public let feedback: String

    public init(rootNodeId: Int64, rootSemanticId: String, rowNodeId: Int64, presetsNodeId: Int64,
                inputNodeId: Int64, inputSemanticId: String,
                decrementNodeId: Int64, decrementSemanticId: String, incrementNodeId: Int64,
                incrementSemanticId: String, label: String, value: String, minimum: Int64, maximum: Int64,
                step: Int64, fieldId: String, writerOperation: String, bindingResourceId: Int64,
                ownerTargetResourceId: Int64, decrementAction: String, incrementAction: String,
                feedbackNodeId!: Int64 = -1, enabled!: Bool = true, readOnly!: Bool = false,
                feedback!: String = "") {
        this.rootNodeId = rootNodeId
        this.rootSemanticId = rootSemanticId
        this.rowNodeId = rowNodeId
        this.presetsNodeId = presetsNodeId
        this.inputNodeId = inputNodeId
        this.inputSemanticId = inputSemanticId
        this.decrementNodeId = decrementNodeId
        this.decrementSemanticId = decrementSemanticId
        this.incrementNodeId = incrementNodeId
        this.incrementSemanticId = incrementSemanticId
        this.feedbackNodeId = feedbackNodeId
        this.label = label
        this.value = value
        this.minimum = minimum
        this.maximum = maximum
        this.step = step
        this.fieldId = fieldId
        this.writerOperation = writerOperation
        this.bindingResourceId = bindingResourceId
        this.ownerTargetResourceId = ownerTargetResourceId
        this.decrementAction = decrementAction
        this.incrementAction = incrementAction
        this.enabled = enabled
        this.readOnly = readOnly
        this.feedback = feedback
    }
}

public class CjguiNumericStepperStyle {
    public let input: CjguiComposableUiStyle
    public let button: CjguiComposableUiStyle
    public let preset: CjguiComposableUiStyle
    public let feedback: CjguiComposableUiStyle
    public let buttonInteraction: CjguiComposableUiInteractionStyle
    public let rowGap: Int64

    public init(input!: CjguiComposableUiStyle = CjguiComposableUiStyle(fixedHeight: 26, growX: 1),
                button!: CjguiComposableUiStyle = CjguiComposableUiStyle(fixedWidth: 30, fixedHeight: 26),
                preset!: CjguiComposableUiStyle = CjguiComposableUiStyle(fixedHeight: 24),
                feedback!: CjguiComposableUiStyle = CjguiComposableUiStyle(fixedHeight: 18, fontSize: 10.5),
                buttonInteraction!: CjguiComposableUiInteractionStyle = CjguiComposableUiInteractionStyle(),
                rowGap!: Int64 = 6) {
        this.input = input
        this.button = button
        this.preset = preset
        this.feedback = feedback
        this.buttonInteraction = buttonInteraction
        this.rowGap = if (rowGap > 0) { rowGap } else { 6 }
    }
}

public class CjguiNumericStepper {
    public static let PRESET_ACTION: String = "NUMERIC_PRESET"

    /// Resolve one button step against the caller's declared bounds. Invalid
    /// current text, an invalid step and both boundaries are explicit issues;
    /// this function never clamps a target into range.
    public static func resolve(currentText: String, direction: Int64, minimum: Int64, maximum: Int64,
        step: Int64): CjguiNumericStepResult {
        let result = CjguiSharedNumericStep.resolve(currentText, direction, minimum, maximum, step)
        return CjguiNumericStepResult(result.text, result.issue, result.value)
    }

    public static func canStep(currentText: String, direction: Int64, minimum: Int64, maximum: Int64,
        step: Int64): Bool {
        return resolve(currentText, direction, minimum, maximum, step).canWrite()
    }

    /// Build the ordinary integer input, two step buttons and optional presets.
    /// Every control carries the resolved owner writer where it has one; the
    /// step actions are dispatched by the caller through the same owner path.
    public static func build(binding: CjguiNumericStepperBinding,
        presets!: ArrayList<CjguiNumericStepperPreset> = ArrayList<CjguiNumericStepperPreset>(),
        style!: CjguiNumericStepperStyle = CjguiNumericStepperStyle()): CjguiComposableUiNode {
        let root = cjguiComposableVertical(binding.rootNodeId, binding.rootSemanticId,
            CjguiComposableUiStyle(gap: style.rowGap))
        let row = cjguiComposableHorizontal(binding.rowNodeId, "${binding.rootSemanticId}-row",
            CjguiComposableUiStyle(gap: style.rowGap))
        let inputEnabled = binding.enabled && !binding.readOnly && binding.ownerTargetResourceId >= 0
        row.add(cjguiComposableIntegerInput(binding.inputNodeId, binding.inputSemanticId, binding.label,
            binding.value, binding.bindingResourceId, style.input, enabled: inputEnabled,
            readOnly: binding.readOnly, fieldId: binding.fieldId,
            operationActionName: binding.writerOperation, operationResourceId: binding.ownerTargetResourceId,
            displayValueRole: "draft"))
        let stepEnabled = binding.enabled && !binding.readOnly && binding.ownerTargetResourceId >= 0
        row.add(cjguiComposableButton(binding.decrementNodeId, binding.decrementSemanticId, "−",
            binding.decrementAction, binding.bindingResourceId, style.button, enabled: stepEnabled,
            operationResourceId: binding.ownerTargetResourceId, interactionStyle: style.buttonInteraction))
        row.add(cjguiComposableButton(binding.incrementNodeId, binding.incrementSemanticId, "+",
            binding.incrementAction, binding.bindingResourceId, style.button, enabled: stepEnabled,
            operationResourceId: binding.ownerTargetResourceId, interactionStyle: style.buttonInteraction))
        root.add(row)
        if (presets.size > 0) {
            let presetRow = cjguiComposableWrap(binding.presetsNodeId, "${binding.rootSemanticId}-presets",
                CjguiComposableUiStyle(gap: style.rowGap), rowGap: style.rowGap)
            for (preset in presets) {
                let semanticId = if (preset.semanticId.size > 0) {
                    preset.semanticId
                } else {
                    "${binding.rootSemanticId}-preset-${preset.key}"
                }
                let action = if (preset.actionName.size > 0) { preset.actionName } else { PRESET_ACTION }
                let target = if (preset.ownerTargetResourceId >= 0) {
                    preset.ownerTargetResourceId
                } else {
                    binding.ownerTargetResourceId
                }
                let resource = if (preset.bindingResourceId >= 0) {
                    preset.bindingResourceId
                } else {
                    binding.bindingResourceId
                }
                let writer = if (preset.writerOperation.size > 0) {
                    preset.writerOperation
                } else {
                    binding.writerOperation
                }
                presetRow.add(cjguiComposableButton(preset.nodeId, semanticId, preset.label, action, resource,
                    style.preset, enabled: preset.enabled && binding.enabled && !binding.readOnly && target >= 0,
                    operationActionName: writer, operationResourceId: target,
                    interactionStyle: style.buttonInteraction))
            }
            root.add(presetRow)
        }
        if (binding.feedback.size > 0 && binding.feedbackNodeId > 0) {
            root.add(cjguiComposableText(binding.feedbackNodeId, "${binding.rootSemanticId}-feedback",
                binding.feedback, style.feedback))
        }
        return root
    }
}

/// One choice option. `key` is the stable identity; `value` is the business
/// value compared with the caller's current value. Display order is irrelevant.
public class CjguiChoiceOption {
    public let key: String
    public let nodeId: Int64
    public let semanticId: String
    public let label: String
    public let value: String
    public let actionName: String
    public let writerOperation: String
    public let bindingResourceId: Int64
    public let ownerTargetResourceId: Int64
    public let enabled: Bool

    public let disabledReason: String

    public init(key: String, nodeId: Int64, label: String, value: String, actionName: String,
                semanticId!: String = "", writerOperation!: String = "", bindingResourceId!: Int64 = -1,
                ownerTargetResourceId!: Int64 = -1, enabled!: Bool = true, disabledReason!: String = "") {
        this.key = key
        this.nodeId = nodeId
        this.semanticId = semanticId
        this.label = label
        this.value = value
        this.actionName = actionName
        this.writerOperation = writerOperation
        this.bindingResourceId = bindingResourceId
        this.ownerTargetResourceId = ownerTargetResourceId
        this.enabled = enabled
        this.disabledReason = disabledReason
    }
}

public class CjguiChoiceGroupStyle {
    public let container: CjguiComposableUiStyle
    public let button: CjguiComposableUiStyle
    public let interaction: CjguiComposableUiInteractionStyle
    public let unmatched: CjguiComposableUiStyle
    public let gap: Int64
    public let rowGap: Int64

    public init(container!: CjguiComposableUiStyle = CjguiComposableUiStyle(),
                button!: CjguiComposableUiStyle = CjguiComposableUiStyle(fixedHeight: 28, padding: 6,
                    background: CjguiComposableUiColor(0.96, 0.97, 0.99, 1.0),
                    border: CjguiComposableUiColor(0.72, 0.76, 0.84, 1.0), borderWidth: 1,
                    cornerRadius: 4),
                interaction!: CjguiComposableUiInteractionStyle = CjguiComposableUiInteractionStyle(
                    selected: CjguiComposableUiPaintStyle(
                        background: Some(CjguiComposableUiColor(0.78, 0.86, 0.98, 1.0)),
                        border: Some(CjguiComposableUiColor(0.22, 0.45, 0.82, 1.0)))),
                unmatched!: CjguiComposableUiStyle = CjguiComposableUiStyle(fixedHeight: 18, fontSize: 10.5),
                gap!: Int64 = 4, rowGap!: Int64 = 4) {
        this.container = container
        this.button = button
        this.interaction = interaction
        this.unmatched = unmatched
        this.gap = gap
        this.rowGap = rowGap
    }
}

public class CjguiChoiceGroupStyleTheme {
    public static func fromTheme(theme: CjguiComposableUiTheme): CjguiChoiceGroupStyle {
        return CjguiChoiceGroupStyle(
            button: CjguiComposableUiStyle(fixedHeight: 30, padding: 6, cornerRadius: 4,
                background: theme.input.background, border: theme.input.border,
                borderWidth: theme.input.borderWidth, textColor: theme.input.textColor))
    }

    /// Maps one node's framework-resolved style (the same `CjguiComposableUiStyle`
    /// every generated leaf receives) onto the choice group's real container and
    /// rows. The declaration's size/growth/paint belongs to the container; the
    /// row height/paint/font belongs to each option button, so a declared style
    /// is painted instead of merely parsed.
    public static func fromResolvedStyle(style: CjguiComposableUiStyle,
        interaction!: CjguiComposableUiInteractionStyle = CjguiComposableUiInteractionStyle()): CjguiChoiceGroupStyle {
        let rowGap = if (style.gap > 0) { style.gap } else { 4 }
        let rowHeight = if (style.fixedHeight > 0) { style.fixedHeight } else { 28 }
        let container = CjguiComposableUiStyle(
            background: style.background, border: style.border, padding: style.padding, gap: style.gap,
            fixedWidth: style.fixedWidth, growX: style.growX, growY: style.growY, borderWidth: style.borderWidth,
            cornerRadius: style.cornerRadius, minWidth: style.minWidth, maxWidth: style.maxWidth,
            minHeight: style.minHeight, maxHeight: style.maxHeight, alignX: style.alignX, alignY: style.alignY)
        let button = CjguiComposableUiStyle(
            background: style.background, border: style.border, textColor: style.textColor,
            padding: style.padding, fixedHeight: rowHeight, borderWidth: style.borderWidth,
            cornerRadius: style.cornerRadius, fontSize: style.fontSize, fontWeight: style.fontWeight,
            letterSpacing: style.letterSpacing, lineHeight: style.lineHeight, fontFamily: style.fontFamily)
        return CjguiChoiceGroupStyle(container: container, button: button, interaction: interaction,
            rowGap: rowGap, gap: rowGap)
    }
}

public class CjguiChoiceGroup {
    /// Empty string means the declaration is usable. Duplicate values are
    /// rejected because they cannot be distinguished by the current value.
    public static func issue(options: ArrayList<CjguiChoiceOption>): String {
        if (options.size == 0) {
            return "choice_options_empty"
        }
        let keys = HashSet<String>()
        let values = HashSet<String>()
        for (option in options) {
            if (option.key.size == 0 || option.label.size == 0 || option.value.size == 0) {
                return "choice_option_identity_required"
            }
            if (option.actionName.size == 0) {
                return "choice_option_action_required"
            }
            if (keys.contains(option.key)) {
                return "choice_duplicate_key:${option.key}"
            }
            if (values.contains(option.value)) {
                return "choice_duplicate_value:${option.value}"
            }
            keys.add(option.key)
            values.add(option.value)
        }
        return ""
    }

    /// Build a segmented/radio-like group. The selected option is chosen by
    /// VALUE, never by index. A current value absent from the options leaves
    /// every option unselected and adds an explicit unmatched line.
    /// `radioSemantics` exposes each option through the existing transport
    /// role the native layer already maps to a radio button, with
    /// selected/disabled/help from the same declaration; `verticalRows` lays
    /// the options one per row (radio list) instead of the default wrapped
    /// segmented row.
    public static func build(nodeId: Int64, semanticId: String, optionsNodeId: Int64,
        options: ArrayList<CjguiChoiceOption>, currentValue: String, unmatchedNodeId: Int64,
        unmatchedPrefix!: String = "未匹配选项",
        style!: CjguiChoiceGroupStyle = CjguiChoiceGroupStyle(), radioSemantics!: Bool = false,
        verticalRows!: Bool = false, errorNodeId!: Int64 = -1, errorText!: String = "",
        identityScope!: ?CjguiComposableUiIdentityScope = None): CjguiComposableUiNode {
        let declarationIssue = issue(options)
        if (declarationIssue.size > 0) {
            return cjguiComposableText(nodeId, semanticId, "选项声明无效：${declarationIssue}",
                CjguiComposableUiStyle(fixedHeight: 24, fontSize: 11.0))
        }
        let groupIdentity: ?CjguiComposableUiIdentity = if (let Some(scope) <- identityScope) {
            Some(scope.local("group"))
        } else {
            None
        }
        let group = CjguiComposableUiNode(nodeId, semanticId, CJGUI_COMPOSABLE_UI_VERTICAL, "", "", "", -1,
            CjguiComposableUiStyle(fixedWidth: style.container.fixedWidth, growX: style.container.growX,
                growY: style.container.growY, padding: style.container.padding, gap: style.rowGap),
            identity: groupIdentity)
        var matched = false
        for (option in options) {
            if (currentValue.size > 0 && option.value == currentValue) {
                matched = true
            }
        }
        if (unmatchedNodeId > 0) {
            if (!matched && currentValue.size > 0) {
                group.add(cjguiComposableText(unmatchedNodeId, "${semanticId}-unmatched",
                    "${unmatchedPrefix}：${currentValue}", style.unmatched))
            } else {
                group.add(cjguiComposableVertical(unmatchedNodeId, "${semanticId}-unmatched-empty",
                    CjguiComposableUiStyle(fixedHeight: 0)))
            }
        }
        if (errorNodeId != -1 && errorText.size > 0) {
            group.add(cjguiComposableText(errorNodeId, "${semanticId}-error", errorText,
                cjguiComposableFormValidationStyle()))
        }
        if (options.size == 0) {
            group.add(cjguiComposableText(-1, "${semanticId}-empty", "没有可选项",
                CjguiComposableUiStyle(fixedHeight: 26, growX: 1,
                    textColor: CjguiComposableUiColor(0.45, 0.48, 0.54, 1.0))))
            return group
        }
        let optionSemanticBase = semanticId
        let optionsIdentity: ?CjguiComposableUiIdentity = if (let Some(scope) <- identityScope) {
            Some(scope.local("options"))
        } else {
            None
        }
        if (verticalRows) {
            let list = CjguiComposableUiNode(optionsNodeId, "${optionSemanticBase}-options",
                CJGUI_COMPOSABLE_UI_VERTICAL, "", "", "", -1,
                CjguiComposableUiStyle(gap: style.rowGap, growX: 1), identity: optionsIdentity)
            appendOptionRows(list, options, currentValue, optionSemanticBase, style, radioSemantics, identityScope)
            group.add(list)
            return group
        }
        let row = CjguiComposableUiNode(optionsNodeId, "${optionSemanticBase}-options",
            CJGUI_COMPOSABLE_UI_HORIZONTAL, "", "", "", -1,
            CjguiComposableUiStyle(gap: style.gap), identity: optionsIdentity,
            layoutSpec: Some(CjguiComposableUiLayoutSpec(CJGUI_COMPOSABLE_UI_LAYOUT_WRAP, rowGap: style.rowGap)))
        appendOptionRows(row, options, currentValue, optionSemanticBase, style, radioSemantics, identityScope)
        group.add(row)
        return group
    }

    private static func appendOptionRows(row: CjguiComposableUiNode, options: ArrayList<CjguiChoiceOption>,
        currentValue: String, semanticId: String, style: CjguiChoiceGroupStyle, radioSemantics: Bool,
        identityScope: ?CjguiComposableUiIdentityScope): Unit {
        for (option in options) {
            let selected = currentValue.size > 0 && option.value == currentValue
            let optionSemantic = if (option.semanticId.size > 0) {
                option.semanticId
            } else {
                "${semanticId}-option-${option.key}"
            }
            let buttonIdentity: ?CjguiComposableUiIdentity = if (let Some(scope) <- identityScope) {
                if (option.semanticId.size > 0) { Some(scope.local(option.semanticId)) } else { None }
            } else {
                None
            }
            let button = cjguiComposableButton(option.nodeId, optionSemantic, option.label, option.actionName,
                option.bindingResourceId, style.button, enabled: option.enabled,
                operationActionName: option.writerOperation,
                operationResourceId: option.ownerTargetResourceId,
                interactionStyle: style.interaction,
                ownerInteractionState: if (selected) {
                    CjguiComposableUiInteractionState.SELECTED
                } else {
                    CjguiComposableUiInteractionState.NONE
                }, identity: buttonIdentity)
            if (radioSemantics) {
                button.semanticRole = CJGUI_COMPOSABLE_UI_SEMANTIC_TAB
                button.semanticLabel = option.label
                button.semanticHelp = if (option.disabledReason.size > 0) { option.disabledReason } else { option.label }
                button.semanticSelected = selected
            }
            row.add(button)
        }
    }
}

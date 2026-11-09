// Framework-neutral numeric stepping contract. The UI field control and an
// application owner resolve the same current value/bounds through this function;
// it never clamps an out-of-range target into a value the owner did not accept,
// and a target outside Int64 reports `step_overflow` instead of saturating.
package cjgui_shared_operation_core

import std.convert.*
import std.overflow.*

public class CjguiSharedNumericStepResult {
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

public class CjguiSharedNumericStep {
    public static func resolve(currentText: String, direction: Int64, minimum: Int64, maximum: Int64,
        step: Int64): CjguiSharedNumericStepResult {
        if (step <= 0) {
            return CjguiSharedNumericStepResult(currentText, "invalid_step", 0)
        }
        let current = match (Int64.tryParse(currentText)) {
            case Some(value) => value
            case None => return CjguiSharedNumericStepResult(currentText, "invalid_current_value", 0)
        }
        let hasBounds = maximum > minimum
        if (hasBounds && (current < minimum || current > maximum)) {
            return CjguiSharedNumericStepResult(currentText, "current_out_of_bounds", current)
        }
        if (direction == 0) {
            return CjguiSharedNumericStepResult(currentText, "invalid_direction", current)
        }
        let target = match (current.checkedAdd(if (direction > 0) { step } else { -step })) {
            case Some(value) => value
            case None => return CjguiSharedNumericStepResult(currentText, "step_overflow", current)
        }
        if (hasBounds && target < minimum) {
            return CjguiSharedNumericStepResult(currentText, "below_minimum", current)
        }
        if (hasBounds && target > maximum) {
            return CjguiSharedNumericStepResult(currentText, "above_maximum", current)
        }
        return CjguiSharedNumericStepResult("${target}", "", target)
    }
}

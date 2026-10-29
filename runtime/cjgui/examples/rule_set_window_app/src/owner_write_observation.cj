// Optional bounded observations at the existing owner writer's RETURN.
// No continuation provider, business revision, admission or extra write.
package cjgui_rule_set_window_app
import cjgui.*
import cjgui_rule_set_application.*
import cjgui_shared_operation_core.*
import std.env.*
import std.collection.*

class RuleSetOwnerWriteFacts {
    let contextVersion: Int64
    let draftVersion: Int64
    let fieldBasisVersion: Int64
    let selectionStart: Int64
    let selectionEnd: Int64
    init(domain: CjguiRuleSetEditingDomain, owner: Int64, resource: Int64) {
        var context: Int64 = -1; var draft: Int64 = -1; var basis: Int64 = -1
        var start: Int64 = -1; var end: Int64 = -1
        // recordsById lookup + FIVE declared fields, never the 1000-record snapshot.
        if (let Some(form) <- domain.formSnapshotForRecord(owner)) {
            context = form.contextVersion; draft = form.draftVersion
            for (field in form.allFields()) {
                if (field.resourceId == resource) {
                    basis = field.draftFieldVersion
                    start = field.selectionStart; end = field.selectionEnd
                }
            }
        }
        contextVersion = context; draftVersion = draft; fieldBasisVersion = basis
        selectionStart = start; selectionEnd = end
    }
}

class RuleSetOwnerWriteStart {
    let serial: Int64
    let before: RuleSetOwnerWriteFacts
    let startedMicros: Int64
    init(serial: Int64, before: RuleSetOwnerWriteFacts, startedMicros: Int64) {
        this.serial = serial; this.before = before
        this.startedMicros = startedMicros
    }
}

class RuleSetOwnerWriteObservation {
    private let enabled: Bool
    private let clock: RuleSetOwnerWriteClock
    init() {
        let enabled = getVariable("CJGUI_RULE_SET_OWNER_WRITE_DIAGNOSTICS") == Some("1")
        this.enabled = enabled
        clock = RuleSetOwnerWriteClock(enabled)
    }
    private var count: Int64 = 0
    func begin(domain: CjguiRuleSetEditingDomain, owner: Int64, resource: Int64): ?RuleSetOwnerWriteStart {
        if (!enabled || count >= 256) { return None }
        count += 1
        let before = RuleSetOwnerWriteFacts(domain, owner, resource)
        return Some(RuleSetOwnerWriteStart(count, before, clock.micros()))
    }
    func finish(start: ?RuleSetOwnerWriteStart, event: CjguiComposableUiEvent,
        owner: Int64, resource: Int64, result: CjguiSharedOperationActionResult,
        domain: CjguiRuleSetEditingDomain): Unit {
        if (let Some(sample) <- start) {
            let completed = clock.micros()
            emit(sample, event, owner, resource, domain, completed, "writer_return",
                if (result.applied) { "true" } else { "false" }, result.reason, result.versionAfter, "unknown")
        }
    }
    func finishBinding(start: ?RuleSetOwnerWriteStart, event: CjguiComposableUiEvent,
        owner: Int64, resource: Int64, result: CjguiComposableUiDispatchResult,
        domain: CjguiRuleSetEditingDomain): Unit {
        if (let Some(sample) <- start) {
            let returned = clock.micros()
            emit(sample, event, owner, resource, domain, returned, "generated_binding_return",
                "unknown", "unknown", -1, if (result.didApply) { "true" } else { "false" })
        }
    }
    private func emit(sample: RuleSetOwnerWriteStart, event: CjguiComposableUiEvent,
        owner: Int64, resource: Int64, domain: CjguiRuleSetEditingDomain,
        returned: Int64, boundary: String, writerApplied: String, writerReason: String,
        resultVersion: Int64, bindingApplied: String): Unit {
        let after = RuleSetOwnerWriteFacts(domain, owner, resource)
        let before = sample.before
        let writeStarted = if (boundary == "writer_return") { sample.startedMicros } else { -1 }
        let writeCompleted = if (boundary == "writer_return") { returned } else { -1 }
        getStdOut().writeln("RULE_SET_OWNER_OBSERVATION boundary=${boundary} serial=${sample.serial} kind=${event.eventKind} " +
            "input_session=${event.inputSessionGeneration} input_sequence=${event.inputSequence} " +
            "input_previous=${event.inputPreviousSequence} node=${event.node.nodeId} " +
            "owner=${owner} resource=${resource} writer_applied=${writerApplied} writer_reason=${writerReason} " +
            "result_version=${resultVersion} binding_did_apply=${bindingApplied} context_before=${before.contextVersion} " +
            "context_after=${after.contextVersion} draft_before=${before.draftVersion} draft_after=${after.draftVersion} " +
            "field_basis_before=${before.fieldBasisVersion} field_basis_after=${after.fieldBasisVersion} " +
            "selection_before=${before.selectionStart}:${before.selectionEnd} " +
            "selection_after=${after.selectionStart}:${after.selectionEnd} size=${event.text.size} " +
            "write_started_us=${writeStarted} write_completed_us=${writeCompleted} " +
            "observed_started_us=${sample.startedMicros} observed_returned_us=${returned} clock=mach_absolute_us")
        getStdOut().flush()
    }
}

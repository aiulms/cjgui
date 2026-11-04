package cjgui_mixed_form_starter

import cjgui.*
import cjgui_shared_operation_core.*
import std.collection.*
import std.unittest.*
import std.unittest.testmacro.*

private func mixedObservationRequest(capability: String, command: String): String {
    return "PROTOCOL CJGUI_SHARED_OPERATION/2\nAUTH ${capability}\n${command}"
}

private func mixedWindowObservationAuthorization(): CjguiSharedOperationExternalAuthorization {
    let scopes = ArrayList<CjguiSharedOperationExternalActionScope>([
        CjguiSharedOperationExternalActionScope("GET_CONTEXT", ArrayList<Int64>(), true),
        CjguiSharedOperationExternalActionScope("GET_WINDOW_TARGETS", ArrayList<Int64>(), true),
        CjguiSharedOperationExternalActionScope("GET_WINDOW_PROGRESS", ArrayList<Int64>(), true),
        CjguiSharedOperationExternalActionScope("GET_WINDOW_INTERACTION", ArrayList<Int64>(), true)
    ])
    return CjguiSharedOperationExternalAuthorization(
        "mixed-window-observation-test", "mixed-window-observation-test-capability", scopes)
}

@Test
func mixedFormWindowObservationIsAnExplicitReadOnlyGrant(): Unit {
    let authorization = mixedFormLocalAuthorization()
    for (action in ["GET_WINDOW_TARGETS", "GET_WINDOW_PROGRESS", "GET_WINDOW_INTERACTION"]) {
        @Assert(authorization.permitsAction(action), true)
        @Assert(authorization.allowsAllResources(action), true)
    }
    // The current example needs an opaque target and compact progress/interaction
    // facts, not a second window-bound business-context capability.
    @Assert(authorization.permitsAction("GET_WINDOW_CONTEXT"), false)
}

@Test
func mixedFormMissingWindowGrantAndUnknownTargetStayRefused(): Unit {
    let domain = PrintPresetDomain()
    let app = CjguiMacosApplication(maximumWindowCount: 2)
    // This in-process transport fixture registers only the providers it tests.
    // The application-wide grants are asserted separately above; reusing them
    // here would require also registering Generated UI providers that are
    // intentionally irrelevant to this window-read contract.
    let authorization = mixedWindowObservationAuthorization()
    let observed = CjguiSharedOperationExternalConnection(domain, authorization)
    @Assert(observed.enableWindowProjectionTargetReads(app), true)
    @Assert(observed.enableWindowProgressTargetReads(app), true)

    let targets = observed.dispatchPayload(
        mixedObservationRequest(authorization.capabilityForGrantedCaller(), "GET_WINDOW_TARGETS"))
    @Assert(targets.contains("KIND WINDOW_TARGETS"), true)
    @Assert(targets.contains("WINDOW_TARGETS 0"), true)

    let missingProgress = observed.dispatchPayload(
        mixedObservationRequest(authorization.capabilityForGrantedCaller(), "GET_WINDOW_PROGRESS foreign_window_1"))
    @Assert(missingProgress.contains("ERROR unknown_window_target"), true)
    let missingInteraction = observed.dispatchPayload(
        mixedObservationRequest(authorization.capabilityForGrantedCaller(), "GET_WINDOW_INTERACTION foreign_window_1"))
    @Assert(missingInteraction.contains("ERROR unknown_window_target"), true)
    let noContextGrant = observed.dispatchPayload(
        mixedObservationRequest(authorization.capabilityForGrantedCaller(), "GET_WINDOW_CONTEXT foreign_window_1"))
    @Assert(noContextGrant.contains("ERROR unauthorized_action"), true)

    let noWindowRead = CjguiSharedOperationExternalAuthorization("mixed-no-window-read",
        "mixed-no-window-read-capability",
        ArrayList<CjguiSharedOperationExternalActionScope>(
            [CjguiSharedOperationExternalActionScope("GET_CONTEXT", ArrayList<Int64>(), true)]))
    let denied = CjguiSharedOperationExternalConnection(domain, noWindowRead)
    @Assert(denied.enableWindowProjectionTargetReads(app), true)
    @Assert(denied.enableWindowProgressTargetReads(app), true)
    let deniedTargets = denied.dispatchPayload(
        mixedObservationRequest(noWindowRead.capabilityForGrantedCaller(), "GET_WINDOW_TARGETS"))
    @Assert(deniedTargets.contains("ERROR unauthorized_action"), true)
    let deniedProgress = denied.dispatchPayload(
        mixedObservationRequest(noWindowRead.capabilityForGrantedCaller(), "GET_WINDOW_PROGRESS foreign_window_1"))
    @Assert(deniedProgress.contains("ERROR unauthorized_action"), true)
    let deniedInteraction = denied.dispatchPayload(
        mixedObservationRequest(noWindowRead.capabilityForGrantedCaller(), "GET_WINDOW_INTERACTION foreign_window_1"))
    @Assert(deniedInteraction.contains("ERROR unauthorized_action"), true)
}

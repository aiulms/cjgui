// Generated motion declarations must be discoverable, validated as candidates,
// and exposed only after their scene transaction is accepted.
package cjgui

import std.collection.*

private class GeneratedMotionTestProvider <: CjguiGeneratedUiBindingProvider {
    public func fieldResourceId(fieldId: String): Int64 { return -1 }
    public func fieldOperationResourceId(fieldId: String): Int64 { return -1 }
    public func draftText(fieldId: String): String { return "" }
    public func appliedText(fieldId: String): String { return "" }
    public func draftBoolean(fieldId: String): ?Bool { return None }
    public func executeAction(actionName: String, nodeKey: String): CjguiGeneratedUiActionResult {
        return CjguiGeneratedUiActionResult(false, "test_noop")
    }
    public func actionAvailable(actionName: String): Bool { return true }
}

private func generatedMotionTestCatalog(): CjguiGeneratedUiCapabilityCatalog {
    let catalog = CjguiGeneratedUiCapabilityCatalog()
    let properties = ArrayList<CjguiGeneratedUiPropertySpec>([
        CjguiGeneratedUiPropertySpec("label", "STRING", maxLength: 40),
        CjguiGeneratedUiPropertySpec("action", "STRING", maxLength: 40),
        CjguiGeneratedUiPropertySpec("motion", "STRING", maxLength: 64,
            stability: "experimental", backendSupport: "accepted generated action reference")
    ])
    let _ = catalog.registerComponent(CjguiGeneratedUiComponentSpec("action", properties, false))
    let _ = catalog.registerAction(CjguiGeneratedUiActionSpec("ANIMATE", "Animate"))
    return catalog
}

private func generatedMotionAction(key: String, motion: String): CjguiGeneratedUiNodeSpec {
    let properties = HashMap<String, String>()
    properties.add("label", "Animate")
    properties.add("action", "ANIMATE")
    properties.add("motion", motion)
    return CjguiGeneratedUiNodeSpec(key, "action", properties: properties, actionName: "ANIMATE")
}

@Test
func generatedMotionRegistryIsApplicationOwnedAndPublishesRegisteredValues(): Unit {
    let catalog = generatedMotionTestCatalog()
    let rule = CjguiGeneratedMotionRule("generated.opacity", 240,
        CjguiGeneratedMotionRule.TOKEN_EASE_OUT)
    @Assert(catalog.registerMotionRule(rule), true)
    @Assert(catalog.registerMotionRule(rule), false)
    let description = CjguiGeneratedUiEncoding.describe(catalog)
    @Assert(description.contains("MOTION_RULE generated.opacity duration_ms=240 easing=ease_out"), true)
    // A fresh app catalog has no generated rule until its owner registers one.
    let isolated = generatedMotionTestCatalog()
    @Assert(isolated.motionRuleRegistry().ruleFor("generated.opacity").isNone(), true)
    let invalid = CjguiGeneratedMotionRule("bad name", 200, CjguiGeneratedMotionRule.TOKEN_EASE_OUT)
    @Assert(invalid.rejectionReason(), "motion_name_invalid")
    @Assert(isolated.registerMotionRule(invalid), false)
}

@Test
func generatedMotionReferenceRejectsUnknownAndCommitsTheAcceptedRuleByKey(): Unit {
    let catalog = generatedMotionTestCatalog()
    let rule = CjguiGeneratedMotionRule("generated.opacity", 240,
        CjguiGeneratedMotionRule.TOKEN_EASE_OUT)
    @Assert(catalog.registerMotionRule(rule), true)
    let holder = CjguiGeneratedUiStructureHolder(catalog)
    let provider = GeneratedMotionTestProvider()
    let valid = holder.submit(generatedMotionAction("animate", "generated.opacity"), provider)
    @Assert(valid.candidateAccepted, true)
    // Submission only stages the reference; it is not yet available to a real
    // control until the matching generated scene transaction is committed.
    @Assert(holder.acceptedMotionRuleForKey("animate").isNone(), true)
    @Assert(holder.beginCandidateRefresh(), true)
    let _ = holder.buildRefreshNode(provider)
    @Assert(holder.prepareCandidateRefresh(), true)
    @Assert(holder.commitCandidateRefresh(), true)
    let acceptedRule = holder.acceptedMotionRuleForKey("animate")
    @Assert(acceptedRule.isSome(), true)
    let resolvedRule = match (acceptedRule) {
        case Some(value) => value
        case None => CjguiGeneratedMotionRule("", 0, "")
    }
    @Assert(resolvedRule.name, "generated.opacity")
    @Assert(resolvedRule.durationMs, 240)

    let acceptedVersion = holder.structureVersion()
    let bad = holder.submit(generatedMotionAction("animate", "generated.unknown"), provider)
    @Assert(bad.candidateAccepted, false)
    @Assert(bad.reason, "motion_rule_unregistered")
    @Assert(holder.structureVersion(), acceptedVersion)
    let retainedRule = holder.acceptedMotionRuleForKey("animate")
    @Assert(retainedRule.isSome(), true)
    let oldScene = holder.buildAccepted(provider)
    @Assert(oldScene.nodeKind, CJGUI_COMPOSABLE_UI_BUTTON)
}

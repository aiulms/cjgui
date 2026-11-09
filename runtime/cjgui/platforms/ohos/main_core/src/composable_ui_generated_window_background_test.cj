// Generated window background is an explicitly enabled, root-only declaration
// whose value follows the holder's ordinary scene acceptance boundary.
package cjgui

import std.collection.*

private class GeneratedWindowBackgroundTestProvider <: CjguiGeneratedUiBindingProvider {
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

private func generatedWindowBackgroundTestCatalog(optIn!: Bool = false): CjguiGeneratedUiCapabilityCatalog {
    let catalog = CjguiGeneratedUiCapabilityCatalog()
    if (optIn) {
        catalog.enableWindowBackground()
    }
    let _ = catalog.registerComponent(CjguiGeneratedUiComponentSpec("vertical",
        CjguiGeneratedUiPresentation.containerStyleProperties(), true, childLimit: 8))
    let labelProperties = CjguiGeneratedUiPresentation.leafStyleProperties()
    labelProperties.add(CjguiGeneratedUiPropertySpec("text", "STRING", maxLength: 40))
    let _ = catalog.registerComponent(CjguiGeneratedUiComponentSpec("label", labelProperties, false))
    return catalog
}

private func generatedWindowBackgroundRoot(token: String): CjguiGeneratedUiNodeSpec {
    let properties = HashMap<String, String>()
    properties.add("windowBackground", token)
    return CjguiGeneratedUiNodeSpec("window-root", "vertical", properties: properties)
}

private func generatedWindowBackgroundAccept(holder: CjguiGeneratedUiStructureHolder,
    provider: GeneratedWindowBackgroundTestProvider, root: CjguiGeneratedUiNodeSpec): Bool {
    if (!holder.submit(root, provider).candidateAccepted || !holder.beginCandidateRefresh()) {
        return false
    }
    let _ = holder.buildRefreshNode(provider)
    return holder.prepareCandidateRefresh() && holder.commitCandidateRefresh()
}

@Test
func generatedWindowBackgroundRequiresCatalogOptInAndPublishesItsGrammar(): Unit {
    let catalog = generatedWindowBackgroundTestCatalog()
    let description = CjguiGeneratedUiEncoding.describe(catalog)
    @Assert(catalog.windowBackgroundEnabled(), false)
    @Assert(description.contains("WINDOW_BACKGROUND_PROPERTY"), false)
    let disabledResult = CjguiGeneratedUiValidator(catalog).validate(generatedWindowBackgroundRoot("opaque"))
    @Assert(disabledResult.accepted, false)
    @Assert(disabledResult.reason, "window_background_not_enabled")

    let enabled = generatedWindowBackgroundTestCatalog(optIn: true)
    let enabledDescription = CjguiGeneratedUiEncoding.describe(enabled)
    @Assert(enabledDescription.contains("root_only=1 encoding=opaque|system_content_area"), true)
    @Assert(enabledDescription.contains("default=opaque omitted=opaque stability=experimental"), true)
    @Assert(enabledDescription.contains("support=macos:experimental_supported,ohos:unpublished_snapshot"), true)
    @Assert(CjguiGeneratedUiValidator(enabled).validate(generatedWindowBackgroundRoot("system_content_area")).accepted,
        true)
}

@Test
func generatedWindowBackgroundRejectsInvalidAndNestedDeclarationsWithoutReplacingAccepted(): Unit {
    let catalog = generatedWindowBackgroundTestCatalog(optIn: true)
    let holder = CjguiGeneratedUiStructureHolder(catalog)
    let provider = GeneratedWindowBackgroundTestProvider()
    @Assert(generatedWindowBackgroundAccept(holder, provider, generatedWindowBackgroundRoot("system_content_area")), true)
    @Assert(holder.candidateWindowBackground(), "system_content_area")
    @Assert(holder.acceptedWindowBackground(), "system_content_area")

    let pendingOpaque = holder.submit(generatedWindowBackgroundRoot("opaque"), provider)
    @Assert(pendingOpaque.candidateAccepted, true)
    @Assert(holder.candidateWindowBackground(), "opaque")
    @Assert(holder.acceptedWindowBackground(), "system_content_area")
    @Assert(holder.beginCandidateRefresh(), true)
    let _ = holder.buildRefreshNode(provider)
    @Assert(holder.prepareCandidateRefresh(), true)
    @Assert(holder.acceptedWindowBackground(), "system_content_area")
    @Assert(holder.commitCandidateRefresh(), true)
    @Assert(holder.acceptedWindowBackground(), "opaque")

    let invalid = holder.submit(generatedWindowBackgroundRoot("vibrant_material"), provider)
    @Assert(invalid.candidateAccepted, false)
    @Assert(invalid.reason, "window_background_value_invalid")
    @Assert(holder.acceptedWindowBackground(), "opaque")

    let nestedProperties = HashMap<String, String>()
    nestedProperties.add("windowBackground", "opaque")
    let nested = CjguiGeneratedUiNodeSpec("nested-window", "vertical", properties: nestedProperties)
    let nestedRoot = CjguiGeneratedUiNodeSpec("window-root", "vertical",
        children: ArrayList<CjguiGeneratedUiNodeSpec>([nested]))
    let nestedResult = holder.submit(nestedRoot, provider)
    @Assert(nestedResult.candidateAccepted, false)
    @Assert(nestedResult.reason, "window_background_root_only")
    @Assert(holder.acceptedWindowBackground(), "opaque")

    // An omitted declaration is an explicit opaque effective value, even when
    // the previously accepted root requested the system content area.
    let cleared = CjguiGeneratedUiNodeSpec("window-root", "vertical")
    @Assert(generatedWindowBackgroundAccept(holder, provider, cleared), true)
    @Assert(holder.candidateWindowBackground(), CjguiWindowBackgroundPolicy.OPAQUE)
    @Assert(holder.acceptedWindowBackground(), CjguiWindowBackgroundPolicy.OPAQUE)
}

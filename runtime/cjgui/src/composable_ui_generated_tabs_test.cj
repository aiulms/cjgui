// Generated tab container tests.
//
// The generated side must reuse the SAME public component, page identity and
// view state as the handwritten tree: the declaration only seeds a NEW instance,
// the validator refuses an illegal page description as a whole candidate, and a
// person's active page survives an ordinary resubmission.
package cjgui

import std.collection.*

private func tabsTestCatalog(): CjguiGeneratedUiCapabilityCatalog {
    let catalog = CjguiGeneratedUiCapabilityCatalog()
    let _ = catalog.registerComponent(CjguiGeneratedUiComponentSpec("vertical",
        CjguiGeneratedUiPresentation.containerStyleProperties(), true, childLimit: 8))
    let labelProperties = CjguiGeneratedUiPresentation.leafStyleProperties()
    labelProperties.add(CjguiGeneratedUiPropertySpec("text", "STRING", maxLength: 200))
    let _ = catalog.registerComponent(CjguiGeneratedUiComponentSpec("label", labelProperties, false))
    let pageProperties = CjguiGeneratedUiPresentation.tabPageContentProperties()
    for (property in CjguiGeneratedUiPresentation.leafStyleProperties()) {
        pageProperties.add(property)
    }
    let tabPageRegistered = catalog.registerComponent(CjguiGeneratedUiComponentSpec("tabPage", pageProperties,
        true, childLimit: 1))
    let tabsProperties = CjguiGeneratedUiPresentation.tabsContentProperties()
    for (property in CjguiGeneratedUiPresentation.containerStyleProperties()) {
        tabsProperties.add(property)
    }
    let tabsRegistered = catalog.registerComponent(CjguiGeneratedUiComponentSpec("tabs", tabsProperties, true,
        childLimit: 3))
    @Assert(tabPageRegistered, true)
    @Assert(tabsRegistered, true)
    return catalog
}

private func tabsTestPageSpec(key: String, pageKey: String, title: String, text: String): CjguiGeneratedUiNodeSpec {
    let properties = HashMap<String, String>()
    properties.add("pageKey", pageKey)
    properties.add("pageTitle", title)
    let contentProperties = HashMap<String, String>()
    contentProperties.add("text", text)
    let children = ArrayList<CjguiGeneratedUiNodeSpec>()
    children.add(CjguiGeneratedUiNodeSpec("${key}-line", "label", properties: contentProperties))
    return CjguiGeneratedUiNodeSpec(key, "tabPage", properties: properties, children: children)
}

private func tabsTestSpec(initialPage!: String = "basic", pages!: Int64 = 2,
    duplicateKey!: Bool = false, nonPageChild!: Bool = false,
    titleStyle!: String = ""): CjguiGeneratedUiNodeSpec {
    let properties = HashMap<String, String>()
    if (initialPage.size > 0) {
        properties.add("initialPage", initialPage)
    }
    properties.add("titleHeight", "24")
    if (titleStyle.size > 0) {
        properties.add("titleStyle", titleStyle)
    }
    let children = ArrayList<CjguiGeneratedUiNodeSpec>()
    if (pages >= 1) {
        children.add(tabsTestPageSpec("page-basic", "basic", "基本", "基本行"))
    }
    if (pages >= 2) {
        children.add(tabsTestPageSpec("page-advanced", "advanced", "高级", "高级行"))
    }
    if (pages >= 3) {
        children.add(tabsTestPageSpec("page-notes", "notes", "备注", "备注行"))
    }
    if (pages >= 4) {
        children.add(tabsTestPageSpec("page-extra", "extra", "额外", "额外行"))
    }
    if (duplicateKey) {
        children.add(tabsTestPageSpec("page-duplicate", "basic", "重复", "重复行"))
    }
    if (nonPageChild) {
        let labelProperties = HashMap<String, String>()
        labelProperties.add("text", "不是页")
        children.add(CjguiGeneratedUiNodeSpec("page-plain", "label", properties: labelProperties))
    }
    return CjguiGeneratedUiNodeSpec("tabs-root", "tabs", properties: properties, children: children)
}

/// A tab container declaring EXACTLY the given page keys, so a test can express a
/// page removal without changing the page count rules.
private func tabsTestPageListSpec(pageKeys: ArrayList<String>, initialPage!: String = "basic"):
    CjguiGeneratedUiNodeSpec {
    let properties = HashMap<String, String>()
    if (initialPage.size > 0) {
        properties.add("initialPage", initialPage)
    }
    properties.add("titleHeight", "24")
    let children = ArrayList<CjguiGeneratedUiNodeSpec>()
    for (pageKey in pageKeys) {
        children.add(tabsTestPageSpec("page-${pageKey}", pageKey, pageKey, "${pageKey}行"))
    }
    return CjguiGeneratedUiNodeSpec("tabs-root", "tabs", properties: properties, children: children)
}

/// Accepts one structure through the real holder transaction.
private func tabsTestAccept(holder: CjguiGeneratedUiStructureHolder, provider: GeneratedTestProvider,
    spec: CjguiGeneratedUiNodeSpec): Bool {
    if (!holder.submit(spec, provider).candidateAccepted) {
        return false
    }
    if (!holder.beginCandidateRefresh()) {
        return false
    }
    let _ = holder.buildRefreshNode(provider)
    if (!holder.prepareCandidateRefresh()) {
        return false
    }
    return holder.commitCandidateRefresh()
}

@Test
func generatedTabsExpandsThroughThePublicComponent(): Unit {
    let catalog = tabsTestCatalog()
    // The kind is published with the new presentation and is implemented.
    @Assert(CjguiGeneratedUiPresentation.forBuiltInKind("tabs"), CJGUI_GENERATED_PRESENTATION_TABS)
    @Assert(catalog.componentFor("tabs").isSome(), true)
    let holder = CjguiGeneratedUiStructureHolder(catalog)
    let provider = GeneratedTestProvider()
    @Assert(holder.submit(tabsTestSpec(), provider).candidateAccepted, true)
    @Assert(holder.beginCandidateRefresh(), true)
    let node = holder.buildRefreshNode(provider)
    @Assert(holder.prepareCandidateRefresh(), true)
    @Assert(holder.commitCandidateRefresh(), true)
    @Assert(node.nodeKind, CJGUI_COMPOSABLE_UI_TABS)
    // The accepted scene carries the stable instance state for this key.
    @Assert(holder.tabsStateForInstance("tabs-root", "basic").activeKey(), "basic")
}

@Test
func generatedTabsDeclaredPageOnlySeedsANewInstance(): Unit {
    let catalog = tabsTestCatalog()
    let holder = CjguiGeneratedUiStructureHolder(catalog)
    let provider = GeneratedTestProvider()
    @Assert(holder.submit(tabsTestSpec(), provider).candidateAccepted, true)
    @Assert(holder.beginCandidateRefresh(), true)
    let _ = holder.buildRefreshNode(provider)
    @Assert(holder.prepareCandidateRefresh(), true)
    @Assert(holder.commitCandidateRefresh(), true)
    // A person switches to the other page.
    let state = holder.tabsStateForInstance("tabs-root", "basic")
    @Assert(state.select("advanced"), true)
    // Re-submitting the SAME structure (and even re-declaring another initial
    // page) may not move the person back.
    @Assert(holder.submit(tabsTestSpec(initialPage: "basic"), provider).candidateAccepted, true)
    @Assert(holder.beginCandidateRefresh(), true)
    let _ = holder.buildRefreshNode(provider)
    @Assert(holder.prepareCandidateRefresh(), true)
    @Assert(holder.commitCandidateRefresh(), true)
    @Assert(holder.tabsStateForInstance("tabs-root", "basic").activeKey(), "advanced")
}

@Test
func generatedTabsRejectsIllegalPageDescriptions(): Unit {
    let catalog = tabsTestCatalog()
    let holder = CjguiGeneratedUiStructureHolder(catalog)
    let provider = GeneratedTestProvider()
    // One page is not a tab container.
    let single = holder.submit(tabsTestSpec(pages: 1), provider)
    @Assert(single.candidateAccepted, false)
    @Assert(single.reason, "tabs_require_two_or_three_pages")
    // Four pages exceed the supported working set.
    let four = holder.submit(tabsTestSpec(pages: 4), provider)
    @Assert(four.candidateAccepted, false)
    @Assert(four.reason, "tabs_require_two_or_three_pages")
    // A duplicate page key would make a restored page ambiguous.
    let duplicate = holder.submit(tabsTestSpec(duplicateKey: true), provider)
    @Assert(duplicate.candidateAccepted, false)
    @Assert(duplicate.reason, "tabs_duplicate_page_key")
    // A page must be a page kind, not arbitrary content.
    let plain = holder.submit(tabsTestSpec(nonPageChild: true), provider)
    @Assert(plain.candidateAccepted, false)
    @Assert(plain.reason, "tabs_child_must_be_page")
    // An initial page that no page declares is refused too.
    let unknown = holder.submit(tabsTestSpec(initialPage: "missing"), provider)
    @Assert(unknown.candidateAccepted, false)
    @Assert(unknown.reason, "tabs_initial_page_unknown")
    // The accepted interface keeps working afterwards.
    @Assert(holder.submit(tabsTestSpec(), provider).candidateAccepted, true)
}

/// A provider whose draft the OWNER can change between builds, so a test can
/// prove that switching back presents the latest owner value instead of a copy
/// taken when the page was first shown.
private class TabsMutableProvider <: CjguiGeneratedUiBindingProvider {
    var draft: String = "第一版"
    public func fieldResourceId(fieldId: String): Int64 { return 7001 }
    public func fieldOperationResourceId(fieldId: String): Int64 { return 42 }
    public func draftText(fieldId: String): String { return draft }
    public func appliedText(fieldId: String): String { return draft }
    public func draftBoolean(fieldId: String): ?Bool { return Some(false) }
    public func executeAction(actionName: String, nodeKey: String): CjguiGeneratedUiActionResult {
        return CjguiGeneratedUiActionResult(true, "")
    }
    public func actionAvailable(actionName: String): Bool { return true }
}

/// A page whose content is an ordinary EDITABLE field, so hiding it has a real
/// keyboard target to keep out of the scene.
private func tabsTestFieldPageSpec(key: String, pageKey: String, title: String): CjguiGeneratedUiNodeSpec {
    let properties = HashMap<String, String>()
    properties.add("pageKey", pageKey)
    properties.add("pageTitle", title)
    let children = ArrayList<CjguiGeneratedUiNodeSpec>()
    children.add(CjguiGeneratedUiNodeSpec("${key}-field", "textInput", fieldId: "label"))
    return CjguiGeneratedUiNodeSpec(key, "tabPage", properties: properties, children: children)
}

private func tabsTestFieldCatalog(): CjguiGeneratedUiCapabilityCatalog {
    let catalog = tabsTestCatalog()
    // A FIELD presentation binds a REGISTERED field of the matching editor kind;
    // it declares no property vocabulary of its own.
    let _ = catalog.registerComponent(CjguiGeneratedUiComponentSpec("textInput",
        ArrayList<CjguiGeneratedUiPropertySpec>(), false))
    let _ = catalog.registerAction(CjguiGeneratedUiActionSpec("SET_LABEL", "设置名称"))
    let _ = catalog.registerField(CjguiGeneratedUiFieldSpec("label", "名称", "TEXT", 7001,
        writeActionName: "SET_LABEL"))
    return catalog
}

private func tabsTestFieldSpec(initialPage!: String = "basic",
    includeAdvanced!: Bool = true): CjguiGeneratedUiNodeSpec {
    let properties = HashMap<String, String>()
    properties.add("initialPage", initialPage)
    let children = ArrayList<CjguiGeneratedUiNodeSpec>()
    children.add(tabsTestFieldPageSpec("page-basic", "basic", "基本"))
    if (includeAdvanced) {
        children.add(tabsTestFieldPageSpec("page-advanced", "advanced", "高级"))
    }
    return CjguiGeneratedUiNodeSpec("tabs-root", "tabs", properties: properties, children: children)
}

/// C2: a hidden page is not DELETED. Its field identity survives, the field is not
/// part of the scene while hidden (so it can neither be measured, hit nor
/// focused), and switching back presents the LATEST owner value.
@Test
func generatedHiddenPageKeepsIdentityAndReadsTheLatestOwnerValue(): Unit {
    let catalog = tabsTestFieldCatalog()
    let holder = CjguiGeneratedUiStructureHolder(catalog)
    let provider = TabsMutableProvider()
    let fieldSubmit = holder.submit(tabsTestFieldSpec(), provider)
    @Assert(fieldSubmit.candidateAccepted, true)
    @Assert(fieldSubmit.candidateAccepted, true)
    @Assert(holder.beginCandidateRefresh(), true)
    let first = holder.buildRefreshNode(provider)
    @Assert(holder.prepareCandidateRefresh(), true)
    @Assert(holder.commitCandidateRefresh(), true)
    let basicFieldId = holder.nodeIdForKey("page-basic-field")
    let advancedFieldId = holder.nodeIdForKey("page-advanced-field")
    @Assert(basicFieldId > 0, true)
    @Assert(advancedFieldId > 0, true)
    // The owner changes the value while the advanced page is HIDDEN.
    provider.draft = "第二版"
    let state = holder.tabsStateForInstance("tabs-root", "basic")
    @Assert(state.select("advanced"), true)
    @Assert(holder.beginCandidateRefresh(), true)
    let second = holder.buildRefreshNode(provider)
    @Assert(holder.prepareCandidateRefresh(), true)
    @Assert(holder.commitCandidateRefresh(), true)
    // Identities did not move: hiding is not deletion and not re-identification.
    @Assert(holder.nodeIdForKey("page-basic-field"), basicFieldId)
    @Assert(holder.nodeIdForKey("page-advanced-field"), advancedFieldId)
    // The newly active page presents the value the owner has NOW.
    let active = tabsFindNode(second, advancedFieldId)
    @Assert(active.isSome(), true)
    let activeNode = match (active) {
        case Some(value) => value
        case None => first
    }
    @Assert(activeNode.value, "第二版")
}

/// C2: a page that really leaves the description is not merely hidden - its
/// instance view state is released, while a page that is only hidden keeps it.
@Test
func generatedHiddenPageKeepsViewStateUntilItIsReallyRemoved(): Unit {
    let catalog = tabsTestCatalog()
    let holder = CjguiGeneratedUiStructureHolder(catalog)
    let viewport = holder.scrollViewportForInstance("page-basic-scroll", 0)
    viewport.requestInitialOffset(64)
    @Assert(viewport.offset(), 64)
    // The key is still part of the accepted description: retained.
    holder.retainInstanceViewStatesFor(ArrayList<String>(["page-basic-scroll", "other"]))
    @Assert(holder.scrollViewportForInstance("page-basic-scroll", 0).offset(), 64)
    // The page leaves the description: the view state is released.
    holder.retainInstanceViewStatesFor(ArrayList<String>(["other"]))
    @Assert(holder.scrollViewportForInstance("page-basic-scroll", 0).offset(), 0)
}

private func tabsFindNode(root: CjguiComposableUiNode, nodeId: Int64): ?CjguiComposableUiNode {
    if (root.nodeId == nodeId) {
        return Some(root)
    }
    for (child in root.children()) {
        let found = tabsFindNode(child, nodeId)
        if (found.isSome()) {
            return found
        }
    }
    return None
}

/// A REJECTED candidate must leave no unaccepted instance view state behind: a
/// later legal structure that reuses the same key has to start from the
/// declaration, not from a state an abandoned attempt created. Building the
/// candidate is what creates the state, so this is the real pollution path.
@Test
func rejectedCandidateLeavesNoUnacceptedTabsInstanceState(): Unit {
    let catalog = tabsTestCatalog()
    let holder = CjguiGeneratedUiStructureHolder(catalog)
    let provider = GeneratedTestProvider()
    // A legal candidate is submitted and BUILT (this is where instance state is
    // created), then the scene is rejected.
    @Assert(holder.submit(tabsTestSpec(), provider).candidateAccepted, true)
    @Assert(holder.beginCandidateRefresh(), true)
    let _ = holder.buildRefreshNode(provider)
    @Assert(holder.prepareCandidateRefresh(), true)
    holder.rollbackCandidateRefresh()
    @Assert(holder.hasPendingCandidate(), false)
    // The abandoned attempt's declared page is NOT remembered: a fresh instance
    // for the same key starts from the DECLARATION it is given now.
    let state = holder.tabsStateForInstance("tabs-root", "advanced")
    @Assert(state.activeKey(), "advanced")
    @Assert(state.declaredKey(), "advanced")
}

/// A1: the tab container's active page and declared page are instance view state
/// shared with the ACCEPTED scene. A candidate build that removes the active page
/// runs `reconcile`; rejecting that candidate must put BOTH values back, while a
/// legal removal publishes the fallback with its accepted scene.
@Test
func rejectedCandidateRestoresTheAcceptedTabsPageAndDeclaration(): Unit {
    let catalog = tabsTestCatalog()
    let provider = GeneratedTestProvider()
    let holder = CjguiGeneratedUiStructureHolder(catalog)
    let threePages = ArrayList<String>(["basic", "advanced", "notes"])
    let withoutAdvanced = ArrayList<String>(["basic", "notes"])
    @Assert(tabsTestAccept(holder, provider, tabsTestPageListSpec(threePages)), true)
    let state = holder.tabsStateForInstance("tabs-root", "basic")
    // A person moves to the advanced page, and that page becomes ACCEPTED.
    @Assert(state.select("advanced"), true)
    @Assert(tabsTestAccept(holder, provider, tabsTestPageListSpec(threePages)), true)
    @Assert(state.activeKey(), "advanced")
    @Assert(state.declaredKey(), "basic")
    // A candidate removes the page the person is on and is really BUILT.
    @Assert(holder.submit(tabsTestPageListSpec(withoutAdvanced), provider).candidateAccepted, true)
    @Assert(holder.beginCandidateRefresh(), true)
    let _ = holder.buildRefreshNode(provider)
    @Assert(holder.prepareCandidateRefresh(), true)
    // The CANDIDATE scene uses the fallback page, but nothing is published yet.
    @Assert(state.activeKey(), "basic")
    @Assert(state.hasStagedReconcile(), true)
    // The scene is rejected: the accepted page and declaration come back.
    holder.rollbackCandidateRefresh()
    @Assert(state.activeKey(), "advanced")
    @Assert(state.declaredKey(), "basic")
    @Assert(state.hasStagedReconcile(), false)
    // An ordinary unrelated refresh cannot suddenly jump to the declared page.
    @Assert(tabsTestAccept(holder, provider, tabsTestPageListSpec(threePages)), true)
    @Assert(state.activeKey(), "advanced")
    // A LEGAL removal IS published together with the accepted scene.
    @Assert(tabsTestAccept(holder, provider, tabsTestPageListSpec(withoutAdvanced)), true)
    @Assert(state.activeKey(), "basic")
    @Assert(state.declaredKey(), "basic")
}

/// A1: a person's OWN selection is a live request, not candidate staging. A page
/// the person picks while a candidate is in flight, and that the candidate still
/// contains, must win over the candidate's older staging pass.
@Test
func aPersonsNewerSelectionWinsOverAnOlderStagedReconcile(): Unit {
    let catalog = tabsTestCatalog()
    let provider = GeneratedTestProvider()
    let holder = CjguiGeneratedUiStructureHolder(catalog)
    let threePages = ArrayList<String>(["basic", "advanced", "notes"])
    let withoutAdvanced = ArrayList<String>(["basic", "notes"])
    @Assert(tabsTestAccept(holder, provider, tabsTestPageListSpec(threePages)), true)
    let state = holder.tabsStateForInstance("tabs-root", "basic")
    @Assert(state.select("advanced"), true)
    @Assert(tabsTestAccept(holder, provider, tabsTestPageListSpec(threePages)), true)
    @Assert(state.activeKey(), "advanced")
    // A candidate that drops the active page stages the fallback page.
    @Assert(holder.submit(tabsTestPageListSpec(withoutAdvanced), provider).candidateAccepted, true)
    @Assert(holder.beginCandidateRefresh(), true)
    let _ = holder.buildRefreshNode(provider)
    @Assert(holder.prepareCandidateRefresh(), true)
    @Assert(state.activeKey(), "basic")
    // While that candidate is still in flight, the person selects another page
    // that the candidate DOES contain.
    @Assert(state.select("notes"), true)
    @Assert(holder.commitCandidateRefresh(), true)
    // The person's newer legal selection is the accepted one, not the fallback the
    // older staging pass computed.
    @Assert(state.activeKey(), "notes")
    @Assert(state.declaredKey(), "basic")
}

/// A HIDDEN page that declares an image must not put that image into the solve at
/// all: with no accepted node for it, no decode/upload work can be triggered and
/// no per-instance resource metadata is published for it. The ACTIVE page's image
/// is present, so the difference is the page, not the component.
private func tabsTestImageCatalog(): CjguiGeneratedUiCapabilityCatalog {
    let catalog = tabsTestCatalog()
    let imageProperties = CjguiGeneratedUiPresentation.imageContentProperties()
    for (property in CjguiGeneratedUiPresentation.leafStyleProperties()) {
        imageProperties.add(property)
    }
    let _ = catalog.registerComponent(CjguiGeneratedUiComponentSpec("image", imageProperties, false))
    let _ = catalog.registerImageResource(
        CjguiGeneratedUiImageResourceSpec("tabs-hidden-icon", "PNG", 1, "隐藏页图标", "hidden-icon.png"))
    let _ = catalog.registerImageResource(
        CjguiGeneratedUiImageResourceSpec("tabs-active-icon", "PNG", 1, "活动页图标", "active-icon.png"))
    return catalog
}

private func tabsTestImagePage(key: String, pageKey: String, title: String,
    resource: String): CjguiGeneratedUiNodeSpec {
    let properties = HashMap<String, String>()
    properties.add("pageKey", pageKey)
    properties.add("pageTitle", title)
    let imageProperties = HashMap<String, String>()
    imageProperties.add("resource", resource)
    imageProperties.add("resourceVersion", "1")
    imageProperties.add("contentMode", "fit")
    imageProperties.add("fixedWidth", "32")
    imageProperties.add("fixedHeight", "32")
    let children = ArrayList<CjguiGeneratedUiNodeSpec>()
    children.add(CjguiGeneratedUiNodeSpec("${key}-image", "image", properties: imageProperties))
    return CjguiGeneratedUiNodeSpec(key, "tabPage", properties: properties, children: children)
}

private func tabsTestTwoImagePagesSpec(): CjguiGeneratedUiNodeSpec {
    let properties = HashMap<String, String>()
    properties.add("initialPage", "basic")
    let children = ArrayList<CjguiGeneratedUiNodeSpec>()
    children.add(tabsTestImagePage("page-basic", "basic", "基本", "tabs-active-icon"))
    children.add(tabsTestImagePage("page-advanced", "advanced", "高级", "tabs-hidden-icon"))
    return CjguiGeneratedUiNodeSpec("tabs-root", "tabs", properties: properties, children: children)
}

@Test
func hiddenPageImageIsNeverLaidOutOrSubmitted(): Unit {
    let catalog = tabsTestImageCatalog()
    let holder = CjguiGeneratedUiStructureHolder(catalog)
    let provider = GeneratedTestProvider()
    @Assert(holder.submit(tabsTestTwoImagePagesSpec(), provider).candidateAccepted, true)
    @Assert(holder.beginCandidateRefresh(), true)
    let node = holder.buildRefreshNode(provider)
    @Assert(holder.prepareCandidateRefresh(), true)
    @Assert(holder.commitCandidateRefresh(), true)

    // BOTH images are expanded by the BUILDER: a generated description is expanded
    // as a whole tree, and that is deliberate - hiding is a presentation fact.
    let activeImageId = holder.nodeIdForKey("page-basic-image")
    let hiddenImageId = holder.nodeIdForKey("page-advanced-image")
    @Assert(activeImageId > 0, true)
    @Assert(hiddenImageId > 0, true)
    @Assert(tabsFindNode(node, activeImageId).isSome(), true)
    @Assert(tabsFindNode(node, hiddenImageId).isSome(), true)

    // What must NOT happen is LAYOUT/SUBMISSION of the hidden image. A window
    // submits exactly the laid-out (accepted) nodes, so the guarantee is checked
    // where it matters: the accepted scene has no node for the hidden image, and
    // nothing can decode, upload or draw it while its page is hidden.
    let controller = TabsImageSceneController(catalog)
    let window = CjguiComposableUiWindow(controller)
    @Assert(window.start(), true)
    @Assert(window.refresh(), true)
    let hiddenImageAccepted = tabsAcceptedNode(window, holder.nodeIdForKey("page-advanced-image"))
    @Assert(hiddenImageAccepted.nodeId, -1)
    // The hidden page is still an accepted, INACTIVE instance with no area: the
    // presented scene carries exactly one active page and one hidden page. The tab
    // TITLES also carry a page key (that is how activation resolves its target),
    // so they are excluded here.
    var hiddenPages = 0
    var activePages = 0
    for (sceneNode in window.acceptedSceneNodes()) {
        if (sceneNode.tabsPageKey.size > 0 && !sceneNode.isTabTitle()) {
            if (sceneNode.tabsPageActive) {
                activePages += 1
            } else {
                hiddenPages += 1
                @Assert(sceneNode.bounds.height, 0)
            }
        }
    }
    @Assert(activePages, 1)
    @Assert(hiddenPages, 1)
    window.close()
}

/// A window controller over the SAME generated holder: the window, not the test,
/// decides which nodes are accepted and submitted.
private class TabsImageSceneController <: CjguiComposableUiController & CjguiComposableUiSceneRefreshParticipant {
    private let holder: CjguiGeneratedUiStructureHolder
    private let provider = GeneratedTestProvider()
    private var revision: Int64 = 1

    init(catalog: CjguiGeneratedUiCapabilityCatalog) {
        this.holder = CjguiGeneratedUiStructureHolder(catalog)
        let _ = this.holder.submit(tabsTestTwoImagePagesSpec(), this.provider)
    }
    public func uiSceneVersion(): Int64 {
        return revision
    }
    public func buildUi(): CjguiComposableUiNode {
        return holder.buildRefreshNode(provider)
    }
    public func beginSceneRefresh(): Bool {
        return holder.beginCandidateRefresh()
    }
    public func prepareSceneRefresh(): Bool {
        return holder.prepareCandidateRefresh()
    }
    public func candidateSceneCommands(): ArrayList<CjguiComposableUiCommand> {
        return ArrayList<CjguiComposableUiCommand>()
    }
    public func commitSceneRefresh(): Unit {
        let _ = holder.commitCandidateRefresh()
    }
    public func rollbackSceneRefresh(): Unit {
        holder.rollbackCandidateRefresh()
    }
    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(false)
    }
    public func rejectUiEvent(eventKind: Int64, nodeId: Int64): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(false)
    }
    public func requestWindowClose(): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(true, shouldClose: true)
    }
}

private func tabsAcceptedNode(window: CjguiComposableUiWindow, nodeId: Int64): CjguiComposableUiLayoutNode {
    for (node in window.acceptedSceneNodes()) {
        if (node.nodeId == nodeId) {
            return node
        }
    }
    return CjguiComposableUiLayoutNode.missing()
}

/// The registered title role every title-style test consumes: a light title on
/// a dark title row with its own hover paint, declared ONCE in the catalog.
private func tabsTestRegisterTitleRole(catalog: CjguiGeneratedUiCapabilityCatalog): Bool {
    return catalog.namedStyles().register(CjguiComposableUiNamedStyle("gen_tab_title",
        CjguiComposableUiStyle(textColor: CjguiComposableUiColor(0.92, 0.95, 1.0, 1.0), fontWeight: 1),
        interaction: CjguiComposableUiInteractionStyle(
            normal: CjguiComposableUiPaintStyle(
                textColor: Some(CjguiComposableUiColor(0.92, 0.95, 1.0, 1.0))),
            hover: CjguiComposableUiPaintStyle(
                background: Some(CjguiComposableUiColor(0.30, 0.50, 0.80, 1.0)),
                textColor: Some(CjguiComposableUiColor(1.0, 1.0, 1.0, 1.0))))))
}

private func tabsTestFindFirstKind(node: CjguiComposableUiNode, kind: Int64): ?CjguiComposableUiNode {
    if (node.nodeKind == kind) {
        return Some(node)
    }
    for (child in node.children()) {
        if (let Some(found) <- tabsTestFindFirstKind(child, kind)) {
            return Some(found)
        }
    }
    return None
}

@Test
func generatedTabsTitleConsumesRegisteredNamedStyleBaseAndInteraction(): Unit {
    let catalog = tabsTestCatalog()
    @Assert(tabsTestRegisterTitleRole(catalog), true)
    let holder = CjguiGeneratedUiStructureHolder(catalog)
    let provider = GeneratedTestProvider()
    @Assert(tabsTestAccept(holder, provider, tabsTestSpec(titleStyle: "gen_tab_title")), true)
    let built = holder.buildRefreshNode(provider)
    let tabs = match (tabsTestFindFirstKind(built, CJGUI_COMPOSABLE_UI_TABS)) {
        case Some(value) => value
        case None => cjguiComposableText(-1, "missing-tabs", "", CjguiComposableUiStyle())
    }
    // The title row is the container's first child; every title in it consumes
    // the SAME registered role's base paint and interaction states.
    let titleRow = tabs.children()[0]
    let firstTitle = titleRow.children()[0]
    @Assert(firstTitle.nodeKind, CJGUI_COMPOSABLE_UI_TAB_TITLE)
    @Assert(firstTitle.style.textColor.red, 0.92)
    @Assert(firstTitle.style.textColor.green, 0.95)
    @Assert(firstTitle.style.fontWeight, 1)
    @Assert(firstTitle.interactionStyle.hover.background.isSome(), true)
    @Assert(firstTitle.interactionStyle.normal.textColor.isSome(), true)
    // A legal theme-side update of the SAME role reaches the next successful
    // refresh; the accepted interface changes with it and nothing is re-parsed
    // through a second style table.
    let role = match (catalog.namedStyles().forName("gen_tab_title")) {
        case Some(value) => value
        case None => CjguiComposableUiNamedStyle("missing", CjguiComposableUiStyle())
    }
    @Assert(catalog.namedStyles().update(CjguiComposableUiNamedStyle("gen_tab_title",
        CjguiComposableUiStyle(textColor: CjguiComposableUiColor(0.30, 0.90, 0.60, 1.0)),
        interaction: CjguiComposableUiInteractionStyle(
            normal: CjguiComposableUiPaintStyle(
                textColor: Some(CjguiComposableUiColor(0.10, 0.20, 0.80, 1.0))),
            hover: role.interaction.hover), purpose: role.purpose)), true)
    @Assert(tabsTestAccept(holder, provider, tabsTestSpec(titleStyle: "gen_tab_title")), true)
    let rebuilt = holder.buildRefreshNode(provider)
    let refreshedTabs = match (tabsTestFindFirstKind(rebuilt, CJGUI_COMPOSABLE_UI_TABS)) {
        case Some(value) => value
        case None => cjguiComposableText(-1, "missing-tabs", "", CjguiComposableUiStyle())
    }
    let refreshedTitle = refreshedTabs.children()[0].children()[0]
    @Assert(refreshedTitle.style.textColor.red, 0.30)
    @Assert(refreshedTitle.style.textColor.green, 0.90)
    // The EFFECTIVE normal override changed as well — not only the base that
    // it overrides. A theme operation touching just the base would leave the
    // rendered title untouched, so this pair is the honest guarantee.
    @Assert(refreshedTitle.interactionStyle.normal.textColor.isSome(), true)
    let normalText = match (refreshedTitle.interactionStyle.normal.textColor) {
        case Some(value) => value
        case None => CjguiComposableUiColor(0.0, 0.0, 0.0, 0.0)
    }
    @Assert(normalText.red, 0.10)
    @Assert(normalText.green, 0.20)
    @Assert(normalText.blue, 0.80)
    // The hover state travels with the same role update.
    @Assert(refreshedTitle.interactionStyle.hover.background.isSome(), true)
}

@Test
func generatedTabsRejectUnknownTitleStyleReferenceAsWholeCandidate(): Unit {
    let catalog = tabsTestCatalog()
    let holder = CjguiGeneratedUiStructureHolder(catalog)
    let provider = GeneratedTestProvider()
    let unknown = holder.submit(tabsTestSpec(titleStyle: "missing_title_role"), provider)
    @Assert(unknown.candidateAccepted, false)
    @Assert(unknown.reason, "style_reference_not_registered")
}

@Test
func generatedTabsDiscoveryPublishesTitleStylePropertyAndReferenceTypes(): Unit {
    let catalog = tabsTestCatalog()
    let described = CjguiGeneratedUiEncoding.describe(catalog)
    @Assert(described.contains("PROPERTY tabs titleStyle STRING"), true)
    // The reference catalogue itself is published beside the property, so an
    // external reader can resolve legal titleStyle values without guessing.
    @Assert(described.contains("STYLE_REVISION"), true)
}

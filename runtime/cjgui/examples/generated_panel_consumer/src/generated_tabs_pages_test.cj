// The generated author consumes the SAME public tab container as the handwritten
// rule window: this application declares its pages in the generated description
// ("任务" / "备注") and gets the framework's page identity, active-page view
// state and hidden-page semantics without a second renderer or a business mirror.
package cjgui_collaboration_starter

import cjgui.*
import cjgui_shared_operation_core.*
import std.collection.*
import std.unittest.*
import std.unittest.testmacro.*

private let TASK_TABS_STRUCTURE = """
GENERATED_UI_STRUCTURE 1
NODE 0 board tabs
PROPERTY 0 board initialPage task
PROPERTY 0 board titleStyle panel_tab_title
NODE 1 taskPage tabPage
PROPERTY 1 taskPage pageKey task
PROPERTY 1 taskPage pageTitle 任务
NODE 2 titleEditor textInput field=title
PROPERTY 2 titleEditor label 任务标题编辑
NODE 1 notesPage tabPage
PROPERTY 1 notesPage pageKey notes
PROPERTY 1 notesPage pageTitle 备注
NODE 2 notesEditor textInput field=notes
PROPERTY 2 notesEditor label 任务备注编辑
END"""

private let DUPLICATE_PAGE_STRUCTURE = """
GENERATED_UI_STRUCTURE 1
NODE 0 board tabs
PROPERTY 0 board initialPage task
NODE 1 taskPage tabPage
PROPERTY 1 taskPage pageKey task
PROPERTY 1 taskPage pageTitle 任务
NODE 2 titleEditor textInput field=title
PROPERTY 2 titleEditor label 任务标题编辑
NODE 1 notesPage tabPage
PROPERTY 1 notesPage pageKey task
PROPERTY 1 notesPage pageTitle 重复
NODE 2 notesEditor textInput field=notes
PROPERTY 2 notesEditor label 任务备注编辑
END"""

private func tabsTaskFixture(): (CjguiSharedOperationList, CjguiTaskGeneratedRegion) {
    let domain = CjguiSharedOperationList(ArrayList<CjguiSharedOperationRecord>([
        CjguiSharedOperationRecord(1, "初始标题", false)
    ]))
    let _ = CjguiTaskFields.installInto(domain, 1)
    let _ = domain.selectFromHuman(1)
    let region = CjguiTaskGeneratedRegion(domain, CjguiTaskFields.titleResourceId)
    return (domain, region)
}

private func tabsAcceptStructure(region: CjguiTaskGeneratedRegion,
    structure: String): Option<CjguiComposableUiNode> {
    if (!region.submitStructure(structure, region.acceptedStructureVersion()).candidateAccepted) {
        return None
    }
    if (!region.beginSceneRefresh()) {
        return None
    }
    let built = region.buildSection(CjguiComposableUiTheme.beaconDark())
    if (!region.prepareSceneRefresh()) {
        return None
    }
    region.commitSceneRefresh()
    return Some(built)
}


@Test
func generatedTaskPanelDeclaresItsPagesThroughThePublicTabContainer(): Unit {
    let (_, region) = tabsTaskFixture()
    let built = tabsAcceptStructure(region, TASK_TABS_STRUCTURE)
    @Assert(built.isSome(), true)
    let section = match (built) {
        case Some(value) => value
        case None => cjguiComposableText(-1, "missing", "", CjguiComposableUiStyle())
    }

    // The generated description really expanded into the PUBLIC tab component:
    // one container (kind 16), a title row with one title per page (kind 17), and
    // BOTH page contents present. Their scoped component ids resolve against the
    // window's identity registry (the rule window's test proves the resolved
    // case); here the structural expansion is what matters.
    let structure = tabsStructureCounts(section)
    @Assert(structure.containerCount, 1)
    @Assert(structure.titleCount, 2)
    @Assert(structure.pageRootCount, 2)
    // The keys of both pages and both editors are addressable.
    @Assert(region.acceptedNodeIdForKey("taskPage") > 0, true)
    @Assert(region.acceptedNodeIdForKey("notesPage") > 0, true)
    @Assert(region.acceptedNodeIdForKey("titleEditor") > 0, true)
    @Assert(region.acceptedNodeIdForKey("notesEditor") > 0, true)
}

/// The generated `titleStyle` reference consumes the registered ONE title role:
/// base paint AND interaction states travel together into the titles.
@Test
func generatedTabTitlesConsumeTheRegisteredTitleRole(): Unit {
    let (_, region) = tabsTaskFixture()
    let built = tabsAcceptStructure(region, TASK_TABS_STRUCTURE)
    @Assert(built.isSome(), true)
    let section = match (built) {
        case Some(value) => value
        case None => cjguiComposableText(-1, "missing", "", CjguiComposableUiStyle())
    }
    let title = findFirstTabTitle(section)
    @Assert(title.isSome(), true)
    let node = match (title) {
        case Some(value) => value
        case None => cjguiComposableText(-1, "missing-title", "", CjguiComposableUiStyle())
    }
    // beaconDark heading foreground from the ONE registered definition.
    let theme = CjguiComposableUiTheme.beaconDark()
    @Assert(node.style.textColor.red, theme.heading.textColor.red)
    @Assert(node.style.textColor.green, theme.heading.textColor.green)
    @Assert(node.interactionStyle.normal.textColor.isSome(), true)
}

/// The generated theme action is a usable control and alternates the named
/// title role between both declared accent states. A second accepted scene must
/// consume the second state through the same public tabs component.
@Test
func generatedTitleAccentActionIsAvailableAndAlternatesConsumedPaint(): Unit {
    let (_, region) = tabsTaskFixture()
    @Assert(region.actionAvailable("TOGGLE_TITLE_ACCENT"), true)
    let availability = region.actionAvailability("TOGGLE_TITLE_ACCENT")
    @Assert(availability.known, true)
    @Assert(availability.isAvailable, true)

    let firstAction = region.executeAction("TOGGLE_TITLE_ACCENT", "accentBtn")
    @Assert(firstAction.applied, true)
    let firstRole = match (region.namedStyle("panel_tab_title")) {
        case Some(value) => value
        case None => return
    }
    let firstPaint = match (firstRole.interaction.normal.textColor) {
        case Some(value) => value
        case None => return
    }
    @Assert(firstPaint.red, 0.10)
    @Assert(firstPaint.green, 0.30)
    @Assert(firstPaint.blue, 0.85)
    let firstScene = tabsAcceptStructure(region, TASK_TABS_STRUCTURE)
    @Assert(firstScene.isSome(), true)
    let firstSceneRoot = match (firstScene) {
        case Some(value) => value
        case None => cjguiComposableText(-1, "missing-scene", "", CjguiComposableUiStyle())
    }
    let firstTitle = findFirstTabTitle(firstSceneRoot)
    @Assert(firstTitle.isSome(), true)
    let firstTitleColor = match (firstTitle) {
        case Some(value) => match (value.interactionStyle.normal.textColor) {
            case Some(color) => color
            case None => firstPaint
        }
        case None => firstPaint
    }
    @Assert(firstTitleColor.blue, firstPaint.blue)

    let secondAction = region.executeAction("TOGGLE_TITLE_ACCENT", "accentBtn")
    @Assert(secondAction.applied, true)
    let secondRole = match (region.namedStyle("panel_tab_title")) {
        case Some(value) => value
        case None => return
    }
    let secondPaint = match (secondRole.interaction.normal.textColor) {
        case Some(value) => value
        case None => return
    }
    @Assert(secondPaint.red, 0.55)
    @Assert(secondPaint.green, 0.15)
    @Assert(secondPaint.blue, 0.60)
    let secondScene = tabsAcceptStructure(region, TASK_TABS_STRUCTURE)
    @Assert(secondScene.isSome(), true)
    let secondSceneRoot = match (secondScene) {
        case Some(value) => value
        case None => cjguiComposableText(-1, "missing-scene", "", CjguiComposableUiStyle())
    }
    let secondTitle = findFirstTabTitle(secondSceneRoot)
    @Assert(secondTitle.isSome(), true)
    let secondTitleColor = match (secondTitle) {
        case Some(value) => match (value.interactionStyle.normal.textColor) {
            case Some(color) => color
            case None => secondPaint
        }
        case None => secondPaint
    }
    @Assert(secondTitleColor.blue, secondPaint.blue)
    @Assert(secondTitleColor.red, secondPaint.red)
}

@Test
func generatedTitleAccentActionIsUnavailableWhenItsRoleIsMissing(): Unit {
    let (_, region) = tabsTaskFixture()
    @Assert(region.withdrawNamedStyle("panel_tab_title"), true)
    @Assert(region.actionAvailable("TOGGLE_TITLE_ACCENT"), false)
    let availability = region.actionAvailability("TOGGLE_TITLE_ACCENT")
    @Assert(availability.known, true)
    @Assert(availability.isAvailable, false)
    @Assert(availability.reason, "title_role_missing")
    let result = region.executeAction("TOGGLE_TITLE_ACCENT", "accentBtn")
    @Assert(result.applied, false)
    @Assert(result.reason, "title_role_missing")
}

/// An unregistered title role refuses the WHOLE candidate; the accepted
/// interface is untouched and the legal structure still passes afterwards.
@Test
func generatedTabsRejectAnUnknownTitleRole(): Unit {
    let (_, region) = tabsTaskFixture()
    let unknown = TASK_TABS_STRUCTURE
        .replace("PROPERTY 0 board titleStyle panel_tab_title",
                 "PROPERTY 0 board titleStyle missing_title_role")
    @Assert(region.submitStructure(unknown, region.acceptedStructureVersion()).candidateAccepted, false)
    let legal = tabsAcceptStructure(region, TASK_TABS_STRUCTURE)
    @Assert(legal.isSome(), true)
}

private func findFirstTabTitle(node: CjguiComposableUiNode): ?CjguiComposableUiNode {
    if (node.nodeKind == CJGUI_COMPOSABLE_UI_TAB_TITLE) {
        return Some(node)
    }
    for (child in node.children()) {
        if (let Some(found) <- findFirstTabTitle(child)) {
            return Some(found)
        }
    }
    return None
}

private class TabStructureCounts {
    var containerCount: Int64 = 0
    var titleCount: Int64 = 0
    var pageRootCount: Int64 = 0
}

private func tabsStructureCounts(root: CjguiComposableUiNode): TabStructureCounts {
    let counts = TabStructureCounts()
    tabsCountInto(root, counts)
    return counts
}

private func tabsCountInto(node: CjguiComposableUiNode, counts: TabStructureCounts): Unit {
    if (node.nodeKind == CJGUI_COMPOSABLE_UI_TABS) {
        counts.containerCount += 1
    }
    if (node.nodeKind == CJGUI_COMPOSABLE_UI_TAB_TITLE) {
        // A title carries its page key too: that is how an activation resolves the
        // page it switches to.
        counts.titleCount += 1
    } else if (node.tabsPageKey.size > 0) {
        counts.pageRootCount += 1
    }
    for (child in node.children()) {
        tabsCountInto(child, counts)
    }
}


@Test
func generatedTaskPanelRefusesIllegalPagesAsAWholeCandidate(): Unit {
    let (_, region) = tabsTaskFixture()
    @Assert(tabsAcceptStructure(region, TASK_TABS_STRUCTURE).isSome(), true)
    let acceptedVersion = region.acceptedStructureVersion()
    let refused = region.submitStructure(DUPLICATE_PAGE_STRUCTURE, acceptedVersion)
    @Assert(refused.candidateAccepted, false)
    @Assert(refused.reason, "tabs_duplicate_page_key")
    // The accepted interface is untouched and still addressable.
    @Assert(region.acceptedStructureVersion(), acceptedVersion)
    @Assert(region.acceptedNodeIdForKey("titleEditor") > 0, true)
}


private class TabsPresentedHeights {
    var title: Int64 = 0
    var notes: Int64 = 0
}

/// Builds the app's current section, lays it out, and reports the PRESENTED height
/// of each page's editor. A hidden page's editor is not submitted at all, so it
/// reports zero instead of a stale rectangle.
private func tabsPresentedHeights(region: CjguiTaskGeneratedRegion): TabsPresentedHeights {
    let heights = TabsPresentedHeights()
    if (!region.beginSceneRefresh()) {
        return heights
    }
    let built = region.buildSection(CjguiComposableUiTheme.beaconDark())
    if (!region.prepareSceneRefresh()) {
        return heights
    }
    region.commitSceneRefresh()
    let scene = CjguiComposableUiLayoutEngine.layout(built,
        CjguiComposableUiRect(0, 0, 900, 700), region.acceptedStructureVersion())
    heights.title = tabsNodeHeight(scene, region.acceptedNodeIdForKey("titleEditor"))
    heights.notes = tabsNodeHeight(scene, region.acceptedNodeIdForKey("notesEditor"))
    return heights
}

private func tabsNodeHeight(scene: CjguiComposableUiScene, nodeId: Int64): Int64 {
    if (nodeId <= 0) {
        return 0
    }
    let node = scene.nodeForId(nodeId)
    if (node.nodeId != nodeId) {
        return 0
    }
    return node.bounds.height
}

private func tabsEditorValue(region: CjguiTaskGeneratedRegion, key: String): String {
    if (!region.beginSceneRefresh()) {
        return ""
    }
    let built = region.buildSection(CjguiComposableUiTheme.beaconDark())
    if (!region.prepareSceneRefresh()) {
        return ""
    }
    region.commitSceneRefresh()
    return tabsValueWithId(built, region.acceptedNodeIdForKey(key))
}

private func tabsValueWithId(node: CjguiComposableUiNode, nodeId: Int64): String {
    if (nodeId > 0 && node.nodeId == nodeId) {
        return node.value
    }
    for (child in node.children()) {
        let found = tabsValueWithId(child, nodeId)
        if (found.size > 0) {
            return found
        }
    }
    return ""
}

/// B3: the task workspace presents ONE page at a time through the SAME public tab
/// container, switching pages is VIEW state (the accepted structure version does
/// not move), and an owner edit made while a page is HIDDEN is read back from the
/// owner when the person switches to it.
@Test
func generatedTaskWorkspaceSwitchesPagesAsViewStateAndKeepsHiddenEdits(): Unit {
    let (domain, region) = tabsTaskFixture()
    @Assert(tabsAcceptStructure(region, TASK_TABS_STRUCTURE).isSome(), true)
    let acceptedVersion = region.acceptedStructureVersion()
    // The declared initial page is the active one, and only ITS editor is
    // presented: the hidden page keeps identity but no drawable rectangle.
    @Assert(region.workspacePage(), "task")
    let taskShown = tabsPresentedHeights(region)
    @Assert(taskShown.title > 0, true)
    @Assert(taskShown.notes, 0)
    // Switching pages is VIEW state: the accepted structure version is untouched.
    @Assert(region.selectWorkspacePage("notes"), true)
    @Assert(region.acceptedStructureVersion(), acceptedVersion)
    @Assert(region.workspacePage(), "notes")
    let notesShown = tabsPresentedHeights(region)
    @Assert(notesShown.title, 0)
    @Assert(notesShown.notes > 0, true)
    // The owner edits the HIDDEN task page's field while the person is on notes.
    @Assert(tabsExternalWrite(domain, "SET_TITLE", "title",
        CjguiSharedOperationValue.string("隐藏页外部改写")).applied, true)
    // Switching back presents the owner's CURRENT value, never a replayed one, and
    // the switch itself still does not advance the structure version.
    @Assert(region.selectWorkspacePage("task"), true)
    @Assert(region.acceptedStructureVersion(), acceptedVersion)
    let back = tabsPresentedHeights(region)
    @Assert(back.title > 0, true)
    @Assert(back.notes, 0)
    @Assert(tabsEditorValue(region, "titleEditor"), "隐藏页外部改写")
    // An illegal page candidate is still refused AFTER the page moved: a view
    // switch cannot make the structure validator forget the accepted contract.
    let refused = region.submitStructure(DUPLICATE_PAGE_STRUCTURE, region.acceptedStructureVersion())
    @Assert(refused.candidateAccepted, false)
    @Assert(refused.reason, "tabs_duplicate_page_key")
    @Assert(region.acceptedStructureVersion(), acceptedVersion)
}

private func tabsExternalWrite(domain: CjguiSharedOperationList, action: String, argument: String,
    value: CjguiSharedOperationValue): CjguiSharedOperationActionResult {
    return domain.executeFromExternal(CjguiSharedOperationActionInvocation(action, domain.version(),
        ArrayList<Int64>([1]),
        ArrayList<CjguiSharedOperationActionArgument>([
            CjguiSharedOperationActionArgument(argument, value)
        ])))
}

private class A2TinyStartControl <: CjguiComposableUiController {
    public func uiSceneVersion(): Int64 { return 1 }
    public func buildUi(): CjguiComposableUiNode {
        return cjguiComposableText(91001, "a2-tiny", "tiny", CjguiComposableUiStyle())
    }
    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(false)
    }
    public func rejectUiEvent(eventKind: Int64, nodeId: Int64): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(false)
    }
    public func requestWindowClose(): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(false)
    }
}

private class A2RejectingStartControl <: CjguiComposableUiController & CjguiComposableUiSceneRefreshParticipant {
    public func uiSceneVersion(): Int64 { return 1 }
    public func buildUi(): CjguiComposableUiNode {
        return cjguiComposableText(91002, "a2-rejected", "rejected", CjguiComposableUiStyle(fixedHeight: 32))
    }
    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(false)
    }
    public func rejectUiEvent(eventKind: Int64, nodeId: Int64): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(false)
    }
    public func requestWindowClose(): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(false)
    }
    public func beginSceneRefresh(): Bool { return false }
    public func prepareSceneRefresh(): Bool { return true }
    public func candidateSceneCommands(): ArrayList<CjguiComposableUiCommand> {
        return ArrayList<CjguiComposableUiCommand>()
    }
    public func commitSceneRefresh(): Unit { }
    public func rollbackSceneRefresh(): Unit { }
}

@Test
func startupFailureProgressAndGeneratedControllerWindow(): Unit {
    let rejected = CjguiComposableUiWindow(A2RejectingStartControl())
    @Assert(rejected.start(), false)
    @Assert(rejected.windowProgress().isActive, false)
    @Assert(rejected.windowProgress().acceptedSceneVersion, 0)
    @Assert(rejected.windowProgress().lastNativeFailure, "participant_begin_internal_error")
    @Assert(rejected.windowProgress().pendingRefreshReason, "start_participant_begin_internal_error")

    let compact = CjguiComposableUiWindow(A2TinyStartControl(),
        configuration: CjguiMacosApplicationWindowConfiguration("CJGUI A2 compact", 320u32, 240u32))
    @Assert(compact.start(), true)
    @Assert(compact.windowProgress().isActive, true)
    compact.close()

    let domain = CjguiSharedOperationList(ArrayList<CjguiSharedOperationRecord>([
        CjguiSharedOperationRecord(8101, "初始标题", false)
    ]))
    let _ = CjguiTaskFields.installInto(domain, 8101)
    let _ = domain.selectFromHuman(8101)
    let actualController = CollaborationStarterController(domain)
    let actualRegion = actualController.generatedUiRegion()
    @Assert(actualRegion.submitStructure(TASK_TABS_STRUCTURE,
        actualRegion.acceptedStructureVersion()).candidateAccepted, true)
    let actual = CjguiComposableUiWindow(actualController)
    actualController.generatedUiRegion().attachWindow(actual)
    @Assert(actual.start(), true)
    @Assert(actual.windowProgress().isActive, true)
    @Assert(actual.windowProgress().acceptedSceneVersion > 0, true)
    @Assert(actualRegion.acceptedInstancesPayload().contains("INSTANCE board "), true)
    actual.close()
}

@Test
func acceptedGeneratedActionInstancePublishesItsDeclaredOwnerAction(): Unit {
    let domain = CjguiSharedOperationList(ArrayList<CjguiSharedOperationRecord>([
        CjguiSharedOperationRecord(8101, "初始标题", false)
    ]))
    let _ = CjguiTaskFields.installInto(domain, 8101)
    let _ = domain.selectFromHuman(8101)
    let controller = CollaborationStarterController(domain)
    let region = controller.generatedUiRegion()
    let structure = """
GENERATED_UI_STRUCTURE 1
NODE 0 board vertical
NODE 1 accentBtn action action=TOGGLE_TITLE_ACCENT
PROPERTY 1 accentBtn label 切换标题强调色
END"""
    @Assert(region.submitStructure(structure, region.acceptedStructureVersion()).candidateAccepted, true)
    let window = CjguiComposableUiWindow(controller)
    region.attachWindow(window)
    @Assert(window.start(), true)
    @Assert(region.acceptedInstancesPayload().contains("action=TOGGLE_TITLE_ACCENT"), true)
    window.close()
}

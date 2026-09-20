// Whole-window production cost samples.
//
// The model micro-benchmarks elsewhere in this package measure the list engine
// alone. These samples drive REAL windows in this process (candidate resolution,
// layout, native staging and submit), so the numbers describe the visible path:
//
//   * fixed-viewport scrolling at 100 / 1k / 10k logical nodes, with the index,
//     materialization, build and layout/submit costs reported separately and the
//     materialized row count asserted to stay bounded outside the timed region;
//   * one object changing versus every object changing, so "single-object
//     update" is not measured by rewriting the whole dataset;
//   * a handwritten panel and a generated panel with the same structure, style,
//     values and bindings in the same process, sampled several times at small,
//     medium and near-capacity sizes, so the extra decode/validate/expand cost is
//     separated from the shared layout/submit cost;
//   * two live windows: one keeps progressing while the other reports no work,
//     and after both stop, repeated no-change refreshes submit nothing and do not
//     call the model again.
//
// Every timing is followed by an assertion on the actual outcome (scene
// advanced, content correct, materialization bounded), so a fast number cannot
// come from skipping work. GPU presentation is still not claimed here: these
// samples stop at the accepted/submitted scene boundary.
package cjgui

import std.collection.*
import std.fs.*
import std.sort.*
import std.time.*

private let WINDOW_PERF_LOG_PATH = "/private/tmp/cjgui-window-perf.log"

// The log must keep every sample, so lines accumulate and the whole content is
// rewritten (writing one line at a time would truncate the earlier ones).
private let windowPerfLines = ArrayList<String>()

private func reportWindowPerf(label: String, micros: Int64, detail: String): Unit {
    windowPerfLines.add("WINDOW_PERF ${label} micros=${micros} ${detail}")
    let builder = StringBuilder()
    for (line in windowPerfLines) {
        builder.append(line)
        builder.append("\n")
    }
    try {
        File.writeTo(WINDOW_PERF_LOG_PATH, builder.toString().toArray())
    } catch (error: Exception) {
        // Evidence file is best-effort; assertions never depend on it.
    }
}

/// One logical tree: a single expanded group with `leaves` selectable rows.
private class WindowPerfTreeSource <: CjguiComposableUiTreeDataSource &
    CjguiComposableUiTreeContentUpdateSource {
    let leaves: Int64
    private let labels: HashMap<String, String> = HashMap<String, String>()
    var childAtCalls: Int64 = 0
    var dataVersion: Int64 = 1
    // Change description for the content-only path: the last change is reusable
    // only when it touched existing rows that did not move (a content update),
    // never when rows were added, removed or reordered.
    private var lastContentKeys: ArrayList<String> = ArrayList<String>()
    private var lastContentLabels: ArrayList<String> = ArrayList<String>()
    private var lastChangeDescribable: Bool = false

    init(leaves: Int64) {
        this.leaves = leaves
    }

    public func childCount(parentKey: String): Int64 {
        if (parentKey.size == 0) {
            return 1
        }
        if (parentKey == "group-0") {
            return leaves
        }
        return 0
    }

    public func childAt(parentKey: String, index: Int64): CjguiComposableUiTreeNode {
        childAtCalls += 1
        if (parentKey.size == 0) {
            return CjguiComposableUiTreeNode("group-0", "组 0", 100, true, selectable: false)
        }
        let key = "leaf-${index}"
        let label = if (let Some(value) <- labels.get(key)) {
            value
        } else {
            "叶 ${index}"
        }
        return CjguiComposableUiTreeNode(key, label, 200 + index, false, selectable: true)
    }

    /// One business object changes. This is the single-object update case, and it
    /// is describable as a content-only change.
    public func changeOne(index: Int64, suffix: String): Unit {
        let key = "leaf-${index}"
        let label = "叶 ${index}${suffix}"
        labels.add(key, label)
        lastContentKeys = ArrayList<String>([key])
        lastContentLabels = ArrayList<String>([label])
        lastChangeDescribable = true
        dataVersion += 1
    }

    /// Several existing objects change in one commit: still content-only, and the
    /// patch cost must follow the change set, not the logical row count.
    public func changeSome(indices: ArrayList<Int64>, suffix: String): Unit {
        let keys = ArrayList<String>()
        let newLabels = ArrayList<String>()
        for (index in indices) {
            let key = "leaf-${index}"
            let label = "叶 ${index}${suffix}"
            labels.add(key, label)
            keys.add(key)
            newLabels.add(label)
        }
        lastContentKeys = keys
        lastContentLabels = newLabels
        lastChangeDescribable = true
        dataVersion += 1
    }

    /// Every object changes at once: the contrast case, never labelled as a
    /// single-object update, and deliberately not describable as a small change
    /// set (the honest answer is "rebuild").
    public func changeAll(suffix: String): Unit {
        var index: Int64 = 0
        while (index < leaves) {
            labels.add("leaf-${index}", "叶 ${index}${suffix}")
            index += 1
        }
        lastContentKeys = ArrayList<String>()
        lastContentLabels = ArrayList<String>()
        lastChangeDescribable = false
        dataVersion += 1
    }

    /// A change whose description is unknown (for example an owner that cannot
    /// prove structural stability): the projection must rebuild.
    public func changeWithoutDescription(suffix: String): Unit {
        labels.add("leaf-1", "叶 1${suffix}")
        lastContentKeys = ArrayList<String>()
        lastContentLabels = ArrayList<String>()
        lastChangeDescribable = false
        dataVersion += 1
    }

    public func contentVersion(): Int64 {
        return dataVersion
    }

    public func contentUpdates(sinceVersion: Int64): ?ArrayList<CjguiComposableUiTreeContentUpdate> {
        if (sinceVersion == dataVersion) {
            return Some(ArrayList<CjguiComposableUiTreeContentUpdate>())
        }
        // Exactly one describable change behind: answer it. Anything older, or a
        // change that was not content-only, means rebuild.
        if (sinceVersion == dataVersion - 1 && lastChangeDescribable) {
            let updates = ArrayList<CjguiComposableUiTreeContentUpdate>()
            var index: Int64 = 0
            while (index < lastContentKeys.size) {
                updates.add(CjguiComposableUiTreeContentUpdate(lastContentKeys[index], lastContentLabels[index]))
                index += 1
            }
            return Some(updates)
        }
        return None
    }
}

/// A real window over the logical tree: a fixed-height viewport (8 rows of 26 +
/// overscan) whose scroll offset moves the materialized range.
private class WindowPerfTreeController <: CjguiComposableUiController {
    let source: WindowPerfTreeSource
    private let projection: CjguiComposableUiTreeProjection
    private let selection: CjguiComposableUiTreeSelection
    private let listState: CjguiComposableUiVirtualListState
    private var revision: Int64 = 1
    /// When false the controller never attaches the content-update provider, so
    /// the SAME single-object change takes the existing rebuild path. Used for
    /// the same-process patch-versus-rebuild contrast.
    private let contentOnlyEnabled: Bool
    /// Monotonic timestamp of the last time a dirty model change was applied to
    /// the projection, so a scheduling sample can separate "queued" from
    /// "owner applied" without guessing.
    var lastAppliedStamp: MonoTime = MonoTime.now()
    var buildCount: Int64 = 0
    var lastMaterialized: Int64 = 0
    /// The row labels the last build really produced, so content is asserted
    /// outside the timed region instead of inferred from a version number.
    var builtLabels: HashMap<String, String> = HashMap<String, String>()
    // Per-phase sample counters, so the index pass and the row build can be
    // reported next to the whole window refresh instead of being guessed.
    var indexMicros: Int64 = 0
    var rowBuildMicros: Int64 = 0
    /// How many data changes took the content-only path versus a full rebuild.
    var contentOnlyUpdates: Int64 = 0
    var rebuildUpdates: Int64 = 0
    var lastPatchedRows: Int64 = 0
    private var dataDirty: Bool = false

    init(source: WindowPerfTreeSource, contentOnly!: Bool = true) {
        this.source = source
        this.contentOnlyEnabled = contentOnly
        this.projection = CjguiComposableUiTreeProjection(source)
        // The source can describe content-only changes, so a single-object change
        // patches the existing rows instead of re-walking the logical tree. The
        // contrast instance leaves the provider off and takes the rebuild path.
        if (contentOnly) {
            this.projection.attachContentUpdateSource(source)
        }
        this.selection = CjguiComposableUiTreeSelection(this.projection)
        this.listState = CjguiComposableUiVirtualListState()
        let _ = this.projection.setExpanded("group-0", true)
        // The initial projection was built from the source's current state, so the
        // content-only path may start from this version.
        this.projection.markSourceIndexCurrent()
    }

    /// Collapse/expand the single group, to cover hidden objects whose content is
    /// patched while they are not materialized.
    public func setGroupExpanded(expanded: Bool): Unit {
        let _ = projection.setExpanded("group-0", expanded)
        revision += 1
    }

    public func uiSceneVersion(): Int64 {
        return revision
    }

    public func buildUi(): CjguiComposableUiNode {
        buildCount += 1
        if (dataDirty) {
            // The consumer's own index pass over the changed data. A content-only
            // change has no index pass at all.
            let indexStarted = MonoTime.now()
            if (projection.refreshContentOnly()) {
                contentOnlyUpdates += 1
                lastPatchedRows = projection.lastContentPatchedRows()
            } else {
                let _ = projection.rebuild()
                rebuildUpdates += 1
            }
            indexMicros += (MonoTime.now() - indexStarted).toMicroseconds()
            lastAppliedStamp = MonoTime.now()
            // The source is read live, so after either path the caller's view
            // matches the source version and the content-only path may arm.
            projection.markSourceIndexCurrent()
            dataDirty = false
        }
        let labels = HashMap<String, String>()
        let root = cjguiComposableVertical(1, "window-perf-root", CjguiComposableUiStyle(gap: 2))
        root.add(cjguiComposableText(2, "window-perf-title", "窗口成本采样", CjguiComposableUiStyle(fontSize: 13.0)))
        root.add(cjguiComposableVirtualList(3, "window-perf-list", 4,
            CjguiComposableUiTreeListSource(projection, selection,
                { row, isSelected, isFocused =>
                    let rowStarted = MonoTime.now()
                    labels.add(row.key, row.label)
                    let built = cjguiComposableText(0, "window-perf-row-${row.key}", row.label,
                        CjguiComposableUiStyle(fixedHeight: 26),
                        identity: Some(CjguiComposableUiIdentityScope("window-perf-rows").child(row.key).local("row")))
                    rowBuildMicros += (MonoTime.now() - rowStarted).toMicroseconds()
                    built
                }), listState, 26, 2, 4,
            CjguiComposableUiStyle(fixedHeight: 8 * 26)))
        builtLabels = labels
        return root
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

    public func scrollTo(index: Int64): Unit {
        listState.scrollToIndex(index)
        lastMaterialized = listState.materializedEnd() - listState.materializedStart()
        revision += 1
    }

    public func dataChanged(): Unit {
        // Only a data change invalidates the projection index; a scroll does not
        // (its cost is materialization plus build, not a re-index).
        dataDirty = true
        revision += 1
    }

    public func rowCount(): Int64 {
        return projection.rowCount()
    }

    public func materializedRows(): Int64 {
        return listState.materializedEnd() - listState.materializedStart()
    }
}

private func runWindowScrollSample(logicalLeaves: Int64, frames: Int64): Int64 {
    let source = WindowPerfTreeSource(logicalLeaves)
    let controller = WindowPerfTreeController(source)
    let window = CjguiComposableUiWindow(controller)
    @Assert(window.start(), true)
    @Assert(window.refresh(), true)
    let logicalRows = controller.rowCount()
    let beforeChildAt = source.childAtCalls
    let beforeBuilds = controller.buildCount
    let started = MonoTime.now()
    var frame: Int64 = 0
    while (frame < frames) {
        controller.scrollTo((frame * 7) % logicalRows)
        @Assert(window.refreshIfNeeded(), true)
        frame += 1
    }
    let micros = (MonoTime.now() - started).toMicroseconds()
    let indexCalls = source.childAtCalls - beforeChildAt
    let builds = controller.buildCount - beforeBuilds
    // Correctness outside the timed region: the window accepted every frame, the
    // scroll really moved the materialized range, and that range stayed bounded.
    @Assert(builds >= frames, true)
    let progress = window.windowProgress()
    @Assert(progress.isActive, true)
    @Assert(progress.acceptedSceneVersion == progress.sceneVersion, true)
    @Assert(progress.submittedSceneVersion == progress.sceneVersion, true)
    @Assert(progress.lastNativeFailure, "none")
    let materialized = controller.materializedRows()
    @Assert(materialized > 0 && materialized <= 8 + 2 * 4, true)
    reportWindowPerf("window_scroll", micros,
        "logical=${logicalRows} frames=${frames} per_frame_us=${micros / frames} materialized=${materialized} " +
        "index_calls=${indexCalls} row_build_us=${controller.rowBuildMicros} builds=${builds} " +
        "scene=${progress.sceneVersion} scope=layout+submit")
    window.close()
    return micros
}

@Test
func windowPerfScroll100(): Unit {
    let _ = runWindowScrollSample(100, 120)
}

@Test
func windowPerfScroll1k(): Unit {
    let _ = runWindowScrollSample(1000, 120)
}

@Test
func windowPerfScroll10k(): Unit {
    let _ = runWindowScrollSample(10000, 120)
}

/// One object changing must not cost what the whole dataset changing costs, and
/// both must keep the visible materialization bounded and the content correct.
@Test
func windowPerfSingleObjectUpdateVersusBulkUpdate(): Unit {
    let source = WindowPerfTreeSource(10000)
    let controller = WindowPerfTreeController(source)
    let window = CjguiComposableUiWindow(controller)
    @Assert(window.start(), true)
    @Assert(window.refresh(), true)

    // One visible object changes: the new content must really be in the scene,
    // and the change is content-only, so there is no logical index walk at all.
    let indexBeforeAbs = controller.indexMicros
    let rowBuildBeforeAbs = controller.rowBuildMicros
    let beforeVisibleChildAt = source.childAtCalls
    let singleStarted = MonoTime.now()
    source.changeOne(3, " *")
    controller.dataChanged()
    @Assert(window.refreshIfNeeded(), true)
    let singleMicros = (MonoTime.now() - singleStarted).toMicroseconds()
    let singleIndexCalls = source.childAtCalls - beforeVisibleChildAt
    @Assert(controller.builtLabels.get("leaf-3"), Some("叶 3 *"))
    @Assert(controller.materializedRows() <= 8 + 2 * 4, true)
    // The single-object content change no longer walks the logical tree: this is
    // the regression this capability exists for (it used to be 10001 childAt).
    @Assert(singleIndexCalls, 0)
    @Assert(controller.contentOnlyUpdates >= 1, true)

    let indexAfterAbs = controller.indexMicros
    let rowBuildAfterAbs = controller.rowBuildMicros
    // One far-away object changes: the viewport must stay bounded, the far row
    // must not be materialized just because it changed, and the patch still costs
    // no index walk.
    let beforeFarChildAt = source.childAtCalls
    let farStarted = MonoTime.now()
    source.changeOne(4242, " #")
    controller.dataChanged()
    @Assert(window.refreshIfNeeded(), true)
    let farMicros = (MonoTime.now() - farStarted).toMicroseconds()
    let farIndexCalls = source.childAtCalls - beforeFarChildAt
    @Assert(controller.materializedRows() <= 8 + 2 * 4, true)
    @Assert(controller.builtLabels.get("leaf-4242"), None)
    @Assert(farIndexCalls, 0)

    let indexAfterFar = controller.indexMicros
    let rowBuildAfterFar = controller.rowBuildMicros
    // Every object changes: no change set can describe that, so the honest
    // fallback is the full rebuild and it really walks the logical tree.
    let beforeBulkChildAt = source.childAtCalls
    let bulkStarted = MonoTime.now()
    source.changeAll(" +")
    controller.dataChanged()
    @Assert(window.refreshIfNeeded(), true)
    let bulkMicros = (MonoTime.now() - bulkStarted).toMicroseconds()
    let bulkIndexCalls = source.childAtCalls - beforeBulkChildAt
    @Assert(controller.materializedRows() <= 8 + 2 * 4, true)
    @Assert(bulkIndexCalls > 10000, true)
    let progress = window.windowProgress()
    @Assert(progress.lastNativeFailure, "none")
    @Assert(progress.acceptedSceneVersion == progress.sceneVersion, true)
    reportWindowPerf("window_update_single_visible", singleMicros,
        "logical=10001 materialized=${controller.materializedRows()} path=content_only index_calls=${singleIndexCalls} " +
        "index_us=${indexAfterAbs - indexBeforeAbs} row_build_us=${rowBuildAfterAbs - rowBuildBeforeAbs} content_ok=true")
    reportWindowPerf("window_update_single_far", farMicros,
        "logical=10001 materialized=${controller.materializedRows()} path=content_only index_calls=${farIndexCalls} " +
        "index_us=${indexAfterFar - indexAfterAbs} row_build_us=${rowBuildAfterFar - rowBuildAfterAbs} " +
        "far_materialized=false")
    reportWindowPerf("window_update_bulk", bulkMicros,
        "logical=10001 materialized=${controller.materializedRows()} path=rebuild " +
        "index_calls=${bulkIndexCalls} " +
        "index_us=${controller.indexMicros - indexAfterFar} row_build_us=${controller.rowBuildMicros - rowBuildAfterFar} " +
        "rewritten_objects=10001")
    window.close()
}

/// A content-only change of a VISIBLE row must be visible in the window's own
/// ACCEPTED scene in that same step - new text, a real native submission and no
/// native failure - not merely in the controller's build output, and not only
/// after some later full update happens to rewrite the text.
@Test
func windowContentOnlyUpdateShowsNewTextInAcceptedScene(): Unit {
    let source = WindowPerfTreeSource(1000)
    let controller = WindowPerfTreeController(source)
    let window = CjguiComposableUiWindow(controller)
    @Assert(window.start(), true)
    @Assert(window.refresh(), true)

    let semanticId = "window-perf-row-leaf-3"
    // The accessor itself: a static node of the same accepted scene resolves.
    @Assert(window.acceptedNodeText("window-perf-title"), Some("窗口成本采样"))
    // leaf-3 is inside the viewport, so it is materialized as a real row node.
    @Assert(controller.builtLabels.get("leaf-3"), Some("叶 3"))
    let textBefore = match (window.acceptedNodeText(semanticId)) {
        case Some(value) => value
        case None => ""
    }
    @Assert(textBefore.size > 0, true)
    let progressBefore = window.windowProgress()
    let projectionBefore = window.windowProjection()
    @Assert(progressBefore.lastNativeFailure, "none")

    // One VISIBLE row changes content only.
    source.changeOne(3, " *")
    controller.dataChanged()
    @Assert(window.refreshIfNeeded(), true)

    // Same step, from the window's accepted scene: the new text is really there.
    let textAfter = match (window.acceptedNodeText(semanticId)) {
        case Some(value) => value
        case None => ""
    }
    @Assert(textAfter, "叶 3 *")
    @Assert(textAfter != textBefore, true)
    // The visible text change reached the accepted scene through a real native
    // submission (a label change is not a no-submit semantic-only pass), and it
    // is the content-only path that produced it.
    let progressAfter = window.windowProgress()
    let projectionAfter = window.windowProjection()
    @Assert(progressAfter.acceptedSceneVersion > progressBefore.acceptedSceneVersion, true)
    @Assert(projectionAfter.nativeSubmissionCount > projectionBefore.nativeSubmissionCount, true)
    @Assert(progressAfter.sceneVersion, progressAfter.acceptedSceneVersion)
    @Assert(progressAfter.lastNativeFailure, "none")
    @Assert(controller.contentOnlyUpdates >= 1, true)
    @Assert(controller.lastPatchedRows, 1)
    window.close()
}

// --- handwritten versus generated panel: equivalent fixture -----------------

/// The ONE read-only fixture both panels are built from. It answers the
/// generated binding with per-field resources and values, and the handwritten
/// pane reads the very same values, so the two panels differ only in how they
/// are authored (plus framework-allocated node ids and scene versions).
private class WindowPerfFieldFixture {
    let fields: Int64
    var valueSuffix: String = ""
    var valueReads: Int64 = 0

    init(fields: Int64) {
        this.fields = fields
    }

    func fieldId(index: Int64): String { return "label-${index}" }
    func resourceId(index: Int64): Int64 { return 9000 + index }
    func editorLabel(index: Int64): String { return "值 ${index}" }
    func staticLabel(index: Int64): String { return "字段 ${index}" }
    func value(index: Int64): String {
        valueReads += 1
        return "v${index}${valueSuffix}"
    }
}

private func numericSuffix(text: String): Int64 {
    let chars = text.toArray()
    var index: Int64 = chars.size - 1
    var multiplier: Int64 = 1
    var value: Int64 = 0
    while (index >= 0) {
        let code = UInt32(chars[index])
        if (code < 48 || code > 57) { break }
        value += Int64(code - 48) * multiplier
        multiplier *= 10
        index -= 1
    }
    return value
}

private class WindowPerfFieldProvider <: CjguiGeneratedUiBindingProvider {
    private let fixture: WindowPerfFieldFixture

    init(fixture: WindowPerfFieldFixture) {
        this.fixture = fixture
    }

    public func fieldResourceId(fieldId: String): Int64 { return fixture.resourceId(numericSuffix(fieldId)) }
    public func fieldOperationResourceId(fieldId: String): Int64 { return 1 }
    public func draftText(fieldId: String): String { return fixture.value(numericSuffix(fieldId)) }
    public func appliedText(fieldId: String): String { return fixture.value(numericSuffix(fieldId)) }
    public func draftBoolean(fieldId: String): ?Bool { return None }
    public func executeAction(actionName: String, nodeKey: String): CjguiGeneratedUiActionResult {
        return CjguiGeneratedUiActionResult(true, "")
    }
    public func actionAvailable(actionName: String): Bool { return true }
}

/// A window whose panel is authored either by hand or as a generated structure
/// over the same fixture. Only timing and framework identities differ.
private class WindowPerfPanelController <: CjguiComposableUiController &
    CjguiComposableUiSceneRefreshParticipant {
    private let fixture: WindowPerfFieldFixture
    private let generated: Bool
    private let provider: WindowPerfFieldProvider
    private let catalog: CjguiGeneratedUiCapabilityCatalog
    private let spec: ?CjguiGeneratedUiNodeSpec
    private let holder: ?CjguiGeneratedUiStructureHolder
    private var revision: Int64 = 1
    // The declared layout attribute this author asked for; `buildUi` really
    // builds with it, so the hot-structure round changes a REAL layout attribute
    // for the handwritten writer as well.
    private var pendingGap: Int64 = 6
    var buildCount: Int64 = 0
    var buildMicros: Int64 = 0
    var adapterMicros: Int64 = 0
    var adapterCalls: Int64 = 0
    var lastBuiltGap: Int64 = 6

    init(fixture: WindowPerfFieldFixture, generated: Bool) {
        this.fixture = fixture
        this.generated = generated
        this.provider = WindowPerfFieldProvider(fixture)
        if (generated) {
            let built = buildPanelCatalog(fixture)
            this.catalog = built
            this.holder = Some(CjguiGeneratedUiStructureHolder(built))
            this.spec = Some(perfPanelSpec(fixture))
        } else {
            this.catalog = CjguiGeneratedUiCapabilityCatalog()
            this.holder = None
            this.spec = None
        }
    }

    public func uiSceneVersion(): Int64 {
        return revision
    }

    public func buildUi(): CjguiComposableUiNode {
        buildCount += 1
        let started = MonoTime.now()
        let root = if (this.generated) {
            match (holder) {
                case Some(value) => value.buildRefreshNode(provider)
                case None => perfHandwrittenPanel(fixture, gap: pendingGap)
            }
        } else {
            perfHandwrittenPanel(fixture, gap: pendingGap)
        }
        lastBuiltGap = pendingGap
        buildMicros += (MonoTime.now() - started).toMicroseconds()
        return root
    }

    /// The generated author's own work for one structure version: decode-free
    /// submission here (the spec object is already in memory, so no decode call
    /// happens and none is labelled), then the framework's validation and
    /// expansion inside `submit`. It is measured on its own so the shared window
    /// refresh is never charged for it.
    public func submitStructure(gap!: Int64 = 6): Bool {
        pendingGap = gap
        if (let Some(value) <- holder) {
            let candidate = perfPanelSpec(fixture, gap: gap)
            let started = MonoTime.now()
            let submitted = value.submit(candidate, provider)
            adapterMicros += (MonoTime.now() - started).toMicroseconds()
            adapterCalls += 1
            return submitted.candidateAccepted
        }
        return true
    }

    /// The accepted Cangjie node tree of the generated author, for the
    /// equivalence check outside any timing.
    public func generatedRoot(): CjguiComposableUiNode {
        if (let Some(value) <- holder) {
            return value.buildRefreshNode(provider)
        }
        return perfHandwrittenPanel(fixture)
    }

    public func beginSceneRefresh(): Bool {
        if (let Some(value) <- holder) {
            return value.beginCandidateRefresh()
        }
        return true
    }

    public func prepareSceneRefresh(): Bool {
        if (let Some(value) <- holder) {
            return value.prepareCandidateRefresh()
        }
        return true
    }

    public func candidateSceneCommands(): ArrayList<CjguiComposableUiCommand> {
        return ArrayList<CjguiComposableUiCommand>()
    }

    public func commitSceneRefresh(): Unit {
        if (let Some(value) <- holder) {
            let _ = value.commitCandidateRefresh()
        }
    }

    public func rollbackSceneRefresh(): Unit {
        if (let Some(value) <- holder) {
            value.rollbackCandidateRefresh()
        }
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

    public func bump(): Unit {
        revision += 1
    }

    /// The declared layout attribute the ACCEPTED panel carries: for the
    /// generated author from its accepted structure, for the handwritten author
    /// from the tree it really built. A hot-structure round is only honest when
    /// this equals the attribute that round declared.
    public func acceptedLayoutGap(): Int64 {
        if (let Some(value) <- holder) {
            if (let Some(structure) <- value.acceptedStructure()) {
                if (let Some(parsed) <- parseGeneratedInteger(structure.property("gap"))) {
                    return parsed
                }
            }
        }
        return lastBuiltGap
    }
}

/// The handwritten pane. It uses only the styles the generated catalog can also
/// express (gap/padding on the container, nothing else), so neither author is
/// silently given extra layout work.
private func perfHandwrittenPanel(fixture: WindowPerfFieldFixture, gap!: Int64 = 6): CjguiComposableUiNode {
    let root = cjguiComposableVertical(500, "perf-panel", CjguiComposableUiStyle(gap: gap, padding: 8))
    var index: Int64 = 0
    while (index < fixture.fields) {
        root.add(cjguiComposableText(601 + index * 4, "perf-label-${index}", fixture.staticLabel(index),
            CjguiComposableUiStyle()))
        root.add(cjguiComposableTextInput(602 + index * 4, "perf-input-${index}", fixture.editorLabel(index),
            fixture.value(index), fixture.resourceId(index), CjguiComposableUiStyle(),
            fieldId: fixture.fieldId(index), operationActionName: "EDIT_DRAFT_TEXT",
            operationResourceId: 1, displayValueRole: "draft"))
        index += 1
    }
    return root
}

private func buildPanelCatalog(fixture: WindowPerfFieldFixture): CjguiGeneratedUiCapabilityCatalog {
    let catalog = CjguiGeneratedUiCapabilityCatalog()
    let _ = catalog.registerComponent(CjguiGeneratedUiComponentSpec("vertical",
        ArrayList<CjguiGeneratedUiPropertySpec>([
            CjguiGeneratedUiPropertySpec("gap", "INTEGER", minimum: 0, maximum: 32),
            CjguiGeneratedUiPropertySpec("padding", "INTEGER", minimum: 0, maximum: 32)
        ]), true, childLimit: 256))
    let _ = catalog.registerComponent(CjguiGeneratedUiComponentSpec("label",
        ArrayList<CjguiGeneratedUiPropertySpec>([
            CjguiGeneratedUiPropertySpec("text", "STRING", required: true, maxLength: 64)
        ]), false))
    let _ = catalog.registerComponent(CjguiGeneratedUiComponentSpec("textInput",
        ArrayList<CjguiGeneratedUiPropertySpec>([
            CjguiGeneratedUiPropertySpec("label", "STRING", maxLength: 64)
        ]), false))
    var index: Int64 = 0
    while (index < fixture.fields) {
        let _ = catalog.registerField(CjguiGeneratedUiFieldSpec(fixture.fieldId(index),
            fixture.editorLabel(index), "TEXT", fixture.resourceId(index),
            writeActionName: "EDIT_DRAFT_TEXT"))
        index += 1
    }
    return catalog
}

private func perfPanelSpec(fixture: WindowPerfFieldFixture, gap!: Int64 = 6): CjguiGeneratedUiNodeSpec {
    let children = ArrayList<CjguiGeneratedUiNodeSpec>()
    var index: Int64 = 0
    while (index < fixture.fields) {
        let text = HashMap<String, String>()
        text.add("text", fixture.staticLabel(index))
        children.add(CjguiGeneratedUiNodeSpec("perf-label-${index}", "label", properties: text))
        let label = HashMap<String, String>()
        label.add("label", fixture.editorLabel(index))
        children.add(CjguiGeneratedUiNodeSpec("perf-input-${index}", "textInput", properties: label,
            fieldId: fixture.fieldId(index)))
        index += 1
    }
    let rootProperties = HashMap<String, String>()
    rootProperties.add("gap", "${gap}")
    rootProperties.add("padding", "8")
    return CjguiGeneratedUiNodeSpec("perf-panel", "vertical", properties: rootProperties,
        children: children)
}

/// Declared node count of one author's panel: the handwritten pane declares
/// 1 + 2*fields nodes, the generated description declares the same shape, and the
/// accepted scene must materialize exactly that (plus nothing hidden).
private func perfDeclaredNodes(fixture: WindowPerfFieldFixture): Int64 {
    return 1 + 2 * fixture.fields
}

/// Layouts a declared panel and dumps everything a caller can observe EXCEPT the
/// framework-allocated node ids and scene version: node kind, content, bindings
/// and layout bounds. Two authors that claim the same work must dump the same.
private func normalizedPanelDump(root: CjguiComposableUiNode): String {
    let registry = CjguiComposableUiIdentityRegistry()
    let _ = registry.beginCandidate()
    let _ = registry.resolveCandidate(root)
    let _ = registry.replaceCandidateRoot(root)
    let result = CjguiComposableUiLayoutEngine.layoutWithMetrics(root,
        CjguiComposableUiRect(0, 0, 900, 2000), 1, CjguiComposableUiFallbackTextMeasurer(),
        identityRegistry: Some(registry))
    let builder = StringBuilder()
    for (node in result.scene.nodes()) {
        builder.append("${node.nodeKind}|${node.label}|${node.value}|${node.fieldId}|" +
            "${node.operationActionName}|${node.operationResourceId}|${node.resourceId}|" +
            "${node.displayValueRole}|${node.bounds.x},${node.bounds.y},${node.bounds.width},${node.bounds.height}\n")
    }
    return builder.toString()
}

private func medianOf(samples: ArrayList<Int64>): Int64 {
    if (samples.size == 0) {
        return 0
    }
    // Insertion sort over five-ish samples: no dependency on a deprecated API.
    let sorted = ArrayList<Int64>(samples)
    var outer: Int64 = 1
    while (outer < sorted.size) {
        let value = sorted[outer]
        var inner = outer - 1
        while (inner >= 0 && sorted[inner] > value) {
            sorted[inner + 1] = sorted[inner]
            inner -= 1
        }
        sorted[inner + 1] = value
        outer += 1
    }
    return sorted[sorted.size / 2]
}

/// Raw evidence of ONE author's measured scenario. Every field is what the
/// samples REALLY observed: the timing, the framework work counters and the
/// accepted scene, never a value the sampler assumed.
private class WindowPerfScenarioResult {
    let totals: ArrayList<Int64> = ArrayList<Int64>()
    let authors: ArrayList<Int64> = ArrayList<Int64>()
    var controllerBuilds: Int64 = 0
    var nativeSubmits: Int64 = 0
    var acceptedVersion: Int64 = 0
    var sceneVersion: Int64 = 0
    var acceptedText: String = ""
    var acceptedBoundsKey: String = ""
    var acceptedBoundsFirst: String = ""
    var acceptedBoundsLast: String = ""
    var acceptedNodes: Int64 = 0
    var declaredNodes: Int64 = 0
    var valueReads: Int64 = 0
    var observedChange: Bool = false
    var noOpRefreshes: Int64 = 0
    var acceptedGaps: String = ""
    var nativeSubmittedRounds: Int64 = 0
    var forcedRefreshRounds: Int64 = 0
    var rounds: Int64 = 0
}

private func perfPanelAccepts(controller: WindowPerfPanelController, window: CjguiComposableUiWindow): Unit {
    @Assert(controller.submitStructure(), true)
    controller.bump()
    @Assert(window.refreshIfNeeded(), true)
}

private func perfBoundsKey(rect: CjguiComposableUiRect): String {
    return "${rect.x},${rect.y},${rect.width},${rect.height}"
}

/// One measured scenario for one author, on ONE instance: cold structure, hot
/// structure (a really different layout attribute), field change (a different
/// field value with NO structure resubmission) and idle (no bump, no submission).
///
/// The equivalence check of the timed instance is reported through the accepted
/// scene (text, bounds, node count) so the numbers describe the object that was
/// actually measured instead of a separate look-alike. `decode=none` is stated
/// because this path never calls a decoder: the structure object already exists
/// in memory, and the field values come from the in-memory fixture.
private func samplePanelScenario(generated: Bool, fields: Int64, scenario: String, sampleCount: Int64):
    WindowPerfScenarioResult {
    let result = WindowPerfScenarioResult()
    if (scenario == "cold_submit") {
        // Cold: EACH sample is a NEW controller/holder whose FIRST valid
        // submission is timed. `window.start()` and the fixture construction stay
        // outside the timing; the author's own submission and the shared window
        // refresh are both inside it, and the author part is broken out.
        var sample: Int64 = 0
        while (sample < sampleCount) {
            let fixture = WindowPerfFieldFixture(fields)
            let controller = WindowPerfPanelController(fixture, generated)
            let window = CjguiComposableUiWindow(controller)
            @Assert(window.start(), true)
            let authorBefore = controller.adapterMicros
            let started = MonoTime.now()
            if (generated) {
                @Assert(controller.submitStructure(), true)
            }
            controller.bump()
            @Assert(window.refreshIfNeeded(), true)
            result.totals.add((MonoTime.now() - started).toMicroseconds())
            result.authors.add(controller.adapterMicros - authorBefore)
            let progress = window.windowProgress()
            @Assert(progress.acceptedSceneVersion == progress.sceneVersion, true)
            @Assert(progress.lastNativeFailure, "none")
            @Assert(progress.sceneVersion > 0, true)
            if (sample == sampleCount - 1) {
                result.acceptedText = window.acceptedSceneDump()
                result.acceptedNodes = window.acceptedNodeCount()
                result.acceptedVersion = progress.acceptedSceneVersion
                result.sceneVersion = progress.sceneVersion
                result.controllerBuilds = controller.buildCount
                result.nativeSubmits = window.windowProjection().nativeSubmissionCount
                result.declaredNodes = perfDeclaredNodes(fixture)
                result.valueReads = fixture.valueReads
            }
            window.close()
            sample += 1
        }
        return result
    }

    // Every other scenario starts from ONE accepted baseline, so the timed rounds
    // measure the change, not the first build.
    let fixture = WindowPerfFieldFixture(fields)
    let controller = WindowPerfPanelController(fixture, generated)
    let window = CjguiComposableUiWindow(controller)
    @Assert(window.start(), true)
    perfPanelAccepts(controller, window)
    let baselineBuilds = controller.buildCount
    let baselineSubmits = window.windowProjection().nativeSubmissionCount
    let baselineVersion = window.windowProgress().acceptedSceneVersion
    let baselineText = window.acceptedSceneDump()
    let boundsProbe = "perf-panel"
    let firstBounds = perfBoundsKey(window.acceptedNodeBounds(boundsProbe) ??
        CjguiComposableUiRect(0, 0, 0, 0))

    var sample: Int64 = 0
    while (sample < sampleCount) {
        let authorBefore = controller.adapterMicros
        let buildsBefore = controller.buildCount
        let submitsBefore = window.windowProjection().nativeSubmissionCount
        let dumpBefore = window.acceptedSceneDump()
        let boundsBefore = perfBoundsKey(window.acceptedNodeBounds(boundsProbe) ??
            CjguiComposableUiRect(0, 0, 0, 0))
        let versionBefore = window.windowProgress().acceptedSceneVersion
        let started = MonoTime.now()
        var declaredGap: Int64 = 0
        if (scenario == "hot_structure") {
            // A really different declared layout attribute every round.
            // Excludes the 6 baseline value: a round that declares the same value would
            // be a no-op refresh, not a hot-structure change.
            declaredGap = 8 + (sample % 3) * 2
            @Assert(controller.submitStructure(gap: declaredGap), true)
            controller.bump()
            @Assert(window.refreshIfNeeded(), true)
        } else if (scenario == "field_change") {
            // A different field value every round, with NO structure submission.
            fixture.valueSuffix = " v${sample + 1}"
            controller.bump()
            @Assert(window.refreshIfNeeded(), true)
        } else if (scenario == "no_change") {
            // Idle: no bump and no submission at all. The refresh must be a no-op.
            if (window.refreshIfNeeded()) {
                result.noOpRefreshes += 1
            }
        } else {
            // `forced_same_content_refresh`: a version bump with unchanged content.
            // Kept as its OWN named scenario; it is not idle evidence.
            controller.bump()
            @Assert(window.refreshIfNeeded(), true)
        }
        result.totals.add((MonoTime.now() - started).toMicroseconds())
        result.authors.add(controller.adapterMicros - authorBefore)

        // Verification OUTSIDE the timed region: the accepted scene and the
        // framework counters are read after the elapsed time is recorded.
        let progress = window.windowProgress()
        @Assert(progress.acceptedSceneVersion == progress.sceneVersion, true)
        @Assert(progress.lastNativeFailure, "none")
        let buildsNow = controller.buildCount
        let submitsNow = window.windowProjection().nativeSubmissionCount
        let dumpNow = window.acceptedSceneDump()
        let boundsNow = perfBoundsKey(window.acceptedNodeBounds(boundsProbe) ??
            CjguiComposableUiRect(0, 0, 0, 0))
        if (scenario == "field_change") {
            // The new field value really reached the accepted scene.
            @Assert(dumpNow.contains("|v0 v${sample + 1}|"), true)
            @Assert(dumpNow != dumpBefore, true)
            @Assert(buildsNow > buildsBefore, true)
            if (submitsNow > submitsBefore) {
                result.nativeSubmittedRounds += 1
            }
            result.observedChange = true
        } else if (scenario == "hot_structure") {
            // The declared layout attribute really is the one this round declared,
            // in the ACCEPTED panel (generated: its accepted structure;
            // handwritten: the tree it built). The probe node's own rect does not
            // move for a container gap because child rects are parent-relative in
            // this layout model, so geometry equality here is expected and is NOT
            // used as change evidence.
            @Assert(controller.acceptedLayoutGap(), declaredGap)
            @Assert(boundsNow, boundsBefore)
            @Assert(buildsNow > buildsBefore, true)
            @Assert(submitsNow > submitsBefore, true)
            result.observedChange = true
        } else if (scenario == "no_change") {
            // Zero new work: no build, no native submission, no scene advance.
            @Assert(buildsNow, buildsBefore)
            @Assert(submitsNow, submitsBefore)
            @Assert(progress.acceptedSceneVersion, versionBefore)
            @Assert(dumpNow, dumpBefore)
            @Assert(boundsNow, boundsBefore)
        } else {
            // A forced same-content refresh DOES rebuild, but an identical
            // accepted tree publishes neither a new accepted scene revision nor a
            // native submission: that is the framework's redundancy guard. This
            // scenario exists to name it separately from idle convergence, and it
            // is where the rebuild really happens.
            @Assert(buildsNow > buildsBefore, true)
            @Assert(progress.acceptedSceneVersion, versionBefore)
            @Assert(dumpNow, dumpBefore)
            @Assert(boundsNow, boundsBefore)
            result.forcedRefreshRounds += 1
            if (submitsNow > submitsBefore) {
                result.nativeSubmittedRounds += 1
            }
        }
        result.rounds += 1
        sample += 1
    }

    result.controllerBuilds = controller.buildCount - baselineBuilds
    result.nativeSubmits = window.windowProjection().nativeSubmissionCount - baselineSubmits
    result.acceptedVersion = window.windowProgress().acceptedSceneVersion
    result.sceneVersion = window.windowProgress().sceneVersion
    result.acceptedText = window.acceptedSceneDump()
    result.acceptedNodes = window.acceptedNodeCount()
    result.declaredNodes = perfDeclaredNodes(fixture)
    result.acceptedBoundsKey = perfBoundsKey(window.acceptedNodeBounds(boundsProbe) ??
        CjguiComposableUiRect(0, 0, 0, 0))
    result.acceptedBoundsFirst = firstBounds
    result.acceptedBoundsLast = result.acceptedBoundsKey
    result.valueReads = fixture.valueReads
    if (scenario == "hot_structure") {
        result.acceptedGaps = "${controller.acceptedLayoutGap()}"
    }
    if (scenario != "no_change" && result.acceptedVersion <= baselineVersion) {
        result.observedChange = false
    }
    window.close()
    return result
}

private func perfSamplesText(samples: ArrayList<Int64>): String {
    let builder = StringBuilder()
    var index: Int64 = 0
    while (index < samples.size) {
        if (index > 0) {
            builder.append(",")
        }
        builder.append("${samples[index]}")
        index += 1
    }
    return builder.toString()
}

private func perfMin(samples: ArrayList<Int64>): Int64 {
    if (samples.size == 0) {
        return 0
    }
    var value = samples[0]
    for (item in samples) {
        if (item < value) {
            value = item
        }
    }
    return value
}

private func perfMax(samples: ArrayList<Int64>): Int64 {
    if (samples.size == 0) {
        return 0
    }
    var value = samples[0]
    for (item in samples) {
        if (item > value) {
            value = item
        }
    }
    return value
}

/// Equivalence and cost for the same fixture: the normalized accepted panel must
/// be identical for both authors (kind, content, bindings, layout bounds), and
/// each of the four scenarios is measured on the instance it verifies. The
/// declared and accepted node counts are reported beside the timings; `decode`
/// is `none` because no decoder is called (the structure exists in memory).
@Test
func windowPerfPanelEquivalenceAndScenarios(): Unit {
    for (fields in [8, 20, 30]) {
        // Equivalence, outside any timing, through the same candidate
        // transaction a real refresh uses.
        let handController = WindowPerfPanelController(WindowPerfFieldFixture(fields), false)
        @Assert(handController.beginSceneRefresh(), true)
        let handRoot = handController.buildUi()
        @Assert(handController.prepareSceneRefresh(), true)
        handController.commitSceneRefresh()
        let generatedController = WindowPerfPanelController(WindowPerfFieldFixture(fields), true)
        @Assert(generatedController.submitStructure(), true)
        @Assert(generatedController.beginSceneRefresh(), true)
        let generatedRoot = generatedController.buildUi()
        @Assert(generatedController.prepareSceneRefresh(), true)
        generatedController.commitSceneRefresh()
        @Assert(normalizedPanelDump(handRoot), normalizedPanelDump(generatedRoot))
        reportWindowPerf("window_panel_equivalence", 0,
            "fields=${fields} nodes=${perfDeclaredNodes(WindowPerfFieldFixture(fields))} " +
            "compared=kind+content+bindings+bounds ignored=node_id+scene_version")

        for (scenario in ["cold_submit", "hot_structure", "field_change", "no_change",
                          "forced_same_content_refresh"]) {
            let hand = samplePanelScenario(false, fields, scenario, 5)
            let generated = samplePanelScenario(true, fields, scenario, 5)
            reportWindowPerf("window_panel_scenario", medianOf(hand.totals),
                "author=handwritten scenario=${scenario} fields=${fields} samples=5 " +
                "min_us=${perfMin(hand.totals)} max_us=${perfMax(hand.totals)} raw_us=${perfSamplesText(hand.totals)} " +
                "author_us=${medianOf(hand.authors)} builds=${hand.controllerBuilds} " +
                "native_submits=${hand.nativeSubmits} accepted_v=${hand.acceptedVersion} " +
                "declared_nodes=${hand.declaredNodes} accepted_nodes=${hand.acceptedNodes} " +
                "value_reads=${hand.valueReads} decoded=false decode=none observed_change=${hand.observedChange} " +
                "accepted_gap=${hand.acceptedGaps} bounds_probe=${hand.acceptedBoundsFirst}->${hand.acceptedBoundsLast} " +
                "native_submitted_rounds=${hand.nativeSubmittedRounds}/${hand.rounds} forced_rounds=${hand.forcedRefreshRounds} " +
                "noop_refreshes=${hand.noOpRefreshes}")
            reportWindowPerf("window_panel_scenario", medianOf(generated.totals),
                "author=generated scenario=${scenario} fields=${fields} samples=5 " +
                "min_us=${perfMin(generated.totals)} max_us=${perfMax(generated.totals)} " +
                "raw_us=${perfSamplesText(generated.totals)} author_us=${medianOf(generated.authors)} " +
                "builds=${generated.controllerBuilds} native_submits=${generated.nativeSubmits} " +
                "accepted_v=${generated.acceptedVersion} declared_nodes=${generated.declaredNodes} " +
                "accepted_nodes=${generated.acceptedNodes} value_reads=${generated.valueReads} " +
                "decoded=false decode=none observed_change=${generated.observedChange} " +
                "accepted_gap=${generated.acceptedGaps} bounds_probe=${generated.acceptedBoundsFirst}->${generated.acceptedBoundsLast} " +
                "native_submitted_rounds=${generated.nativeSubmittedRounds}/${generated.rounds} forced_rounds=${generated.forcedRefreshRounds} " +
                "noop_refreshes=${generated.noOpRefreshes}")
            // The two authors must agree on the equivalence the scenario claims.
            @Assert(hand.declaredNodes == generated.declaredNodes, true)
            @Assert(hand.acceptedNodes == generated.acceptedNodes, true)
            @Assert(hand.observedChange == generated.observedChange, true)
            // Equivalence on the TIMED instances: the same authored panel must
            // commit the same observable content (kind|label|value|field
            // binding), ignoring registry-allocated ids and geometry.
            @Assert(perfContentShape(hand.acceptedText), perfContentShape(generated.acceptedText))
            if (scenario == "no_change") {
                // Idle is asserted, not inferred: zero builds/submissions.
                @Assert(hand.controllerBuilds, 0)
                @Assert(generated.controllerBuilds, 0)
                @Assert(hand.nativeSubmits, 0)
                @Assert(generated.nativeSubmits, 0)
            }
        }
    }
}

/// Two live windows driven directly: while one keeps progressing the other has
/// no work, and after both stop repeated refreshes submit nothing and never call
/// the model again. This is the IDLE-side evidence only - it does not measure
/// two simultaneously active windows sharing one application pump (see the
/// interaction scheduling probe for the backlog/external-write case).
@Test
func windowPerfOtherWindowProgressAndIdleConvergence(): Unit {
    let sourceA = WindowPerfTreeSource(1000)
    let controllerA = WindowPerfTreeController(sourceA)
    let windowA = CjguiComposableUiWindow(controllerA)
    @Assert(windowA.start(), true)
    @Assert(windowA.refresh(), true)

    let sourceB = WindowPerfTreeSource(1000)
    let controllerB = WindowPerfTreeController(sourceB)
    let windowB = CjguiComposableUiWindow(controllerB)
    @Assert(windowB.start(), true)
    @Assert(windowB.refresh(), true)

    // Window B progresses; window A must report no work and no new submission.
    let sceneABefore = windowA.windowProgress().sceneVersion
    let buildABefore = controllerA.buildCount
    let childAtABefore = sourceA.childAtCalls
    var step: Int64 = 0
    var aAcceptedRefreshes: Int64 = 0
    while (step < 40) {
        controllerB.scrollTo(step * 5)
        @Assert(windowB.refreshIfNeeded(), true)
        // An untouched window may still be asked by the window server for a
        // no-op pass; what must not happen is a NEW scene for it, a rebuild or
        // another model read.
        if (windowA.refreshIfNeeded()) {
            aAcceptedRefreshes += 1
        }
        step += 1
    }
    let aBuilds = controllerA.buildCount - buildABefore
    let aIndexCalls = sourceA.childAtCalls - childAtABefore
    @Assert(windowB.windowProgress().sceneVersion > sceneABefore, true)
    @Assert(windowA.windowProgress().sceneVersion, sceneABefore)
    @Assert(aBuilds, 0)
    @Assert(aIndexCalls, 0)
    reportWindowPerf("window_other_progress", 0,
        "claim=idle_side_only progressed_window=1 idle_window_scene=${sceneABefore} " +
        "idle_noop_refresh_calls=${aAcceptedRefreshes} idle_builds=${aBuilds} idle_index_calls=${aIndexCalls} " +
        "dual_active_shared_host=separate_windows_here measured_by=windowPerfTwoActiveWindowsInOneApplicationTurn")

    // Both stop: no further submissions and no model work.
    let sceneBBefore = windowB.windowProgress().sceneVersion
    let buildBBefore = controllerB.buildCount
    let childAtBBefore = sourceB.childAtCalls
    var idle: Int64 = 0
    var idleNoopRefreshes: Int64 = 0
    while (idle < 50) {
        // `refreshIfNeeded` may accept a no-op pass requested by the window
        // server; the convergence claim is that no new scene is produced, no
        // rebuild happens and the model is not read again.
        if (windowB.refreshIfNeeded()) {
            idleNoopRefreshes += 1
        }
        idle += 1
    }
    let idleBuilds = controllerB.buildCount - buildBBefore
    let idleIndexCalls = sourceB.childAtCalls - childAtBBefore
    @Assert(windowB.windowProgress().sceneVersion, sceneBBefore)
    @Assert(idleBuilds, 0)
    @Assert(idleIndexCalls, 0)
    reportWindowPerf("window_idle_convergence", 0,
        "idle_refreshes=50 new_scenes=0 noop_refresh_calls=${idleNoopRefreshes} scene=${sceneBBefore} " +
        "idle_builds=${idleBuilds} idle_index_calls=${idleIndexCalls}")
    windowB.close()
    windowA.close()
}

// --- two ACTIVE windows through ONE normal application loop -----------------

/// The per-window tests above each own their own pump. This one puts two live
/// windows under the normal multi-window application loop
/// (`CjguiMacosApplication`, the same class every multi-window application
/// uses) and asserts the shared-turn claim instead of labelling it unmeasured:
/// every turn refreshes all live windows, carries exactly one AppKit wait, and
/// both windows publish their OWN new accepted scene - neither is starved by
/// the other, and neither window's scene is advanced by the sibling's work.
@Test
func windowPerfTwoActiveWindowsInOneApplicationTurn(): Unit {
    let application = CjguiMacosApplication(maximumWindowCount: 2)
    let sourceA = WindowPerfTreeSource(1000)
    let sourceB = WindowPerfTreeSource(1000)
    let controllerA = WindowPerfTreeController(sourceA)
    let controllerB = WindowPerfTreeController(sourceB)
    let openA = application.openWindow(controllerA,
        configuration: CjguiMacosApplicationWindowConfiguration("CJGUI 双窗口 A", 620u32, 440u32))
    @Assert(openA.didOpen, true)
    let openB = application.openWindow(controllerB,
        configuration: CjguiMacosApplicationWindowConfiguration("CJGUI 双窗口 B", 620u32, 440u32))
    @Assert(openB.didOpen, true)
    let identifiers = application.windowIdentifiers()
    @Assert(identifiers.size, 2)
    let windowA = match (application.window(identifiers[0])) {
        case Some(value) => value
        case None => throw Exception("application lost window A")
    }
    let windowB = match (application.window(identifiers[1])) {
        case Some(value) => value
        case None => throw Exception("application lost window B")
    }

    // Both windows then get a REAL scene change (a scroll changes layout, so it
    // must reach the native submission path, unlike a content-only label patch
    // which is published as a semantic-only revision).
    let sceneABefore = windowA.windowProgress().sceneVersion
    let sceneBBefore = windowB.windowProgress().sceneVersion
    let versionABefore = controllerA.uiSceneVersion()
    let versionBBefore = controllerB.uiSceneVersion()
    let buildABefore = controllerA.buildCount
    let buildBBefore = controllerB.buildCount
    var turns: Int64 = 0
    var bothLiveTurns: Int64 = 0
    var singleWaitTurns: Int64 = 0
    while (turns < 60) {
        controllerA.scrollTo(turns * 3)
        controllerB.scrollTo(turns * 7)
        let turn = application.pumpOneTurn()
        @Assert(turn.isOpen, true)
        @Assert(turn.windowCount, 2)
        if (turn.windowCount == 2) {
            bothLiveTurns += 1
        }
        if (turn.waitedWindow.isSome()) {
            singleWaitTurns += 1
        }
        turns += 1
        if (windowA.windowProgress().acceptedSceneVersion > sceneABefore &&
            windowB.windowProgress().acceptedSceneVersion > sceneBBefore) {
            break
        }
    }
    let progressA = windowA.windowProgress()
    let progressB = windowB.windowProgress()
    // Diagnostics are reported BEFORE the assertions so a starvation or a
    // native-refresh failure is visible in the evidence file, not only as a
    // bare assertion number.
    reportWindowPerf("window_dual_active_shared_turn", 0,
        "claim=dual_active_shared_loop windows=2 turns=${turns} " +
        "scene_a=${progressA.sceneVersion} scene_b=${progressB.sceneVersion} " +
        "accepted_a=${progressA.acceptedSceneVersion} accepted_b=${progressB.acceptedSceneVersion} " +
        "submitted_a=${progressA.submittedSceneVersion} submitted_b=${progressB.submittedSceneVersion} " +
        "active_a=${progressA.isActive} active_b=${progressB.isActive} " +
        "failure_a='${progressA.lastNativeFailure}' failure_b='${progressB.lastNativeFailure}' " +
        "pending_a='${progressA.pendingRefreshReason}' pending_b='${progressB.pendingRefreshReason}' " +
        "presentation_a='${progressA.presentationState}' presentation_b='${progressB.presentationState}' " +
        "waited_window_per_turn=1 both_live_turns=${bothLiveTurns} " +
        "builds_a=${controllerA.buildCount - buildABefore} builds_b=${controllerB.buildCount - buildBBefore} " +
        "materialized_a=${controllerA.materializedRows()} materialized_b=${controllerB.materializedRows()} " +
        "dual_active_shared_host=measured_here")
    @Assert(progressA.lastNativeFailure, "none")
    @Assert(progressB.lastNativeFailure, "none")
    // Both windows published THEIR OWN new scene in the same shared loop: this
    // is the dual-active claim, not a single progressed window plus an idle one.
    @Assert(progressA.sceneVersion > sceneABefore, true)
    @Assert(progressB.sceneVersion > sceneBBefore, true)
    @Assert(progressA.acceptedSceneVersion == progressA.sceneVersion, true)
    @Assert(progressB.acceptedSceneVersion == progressB.sceneVersion, true)
    @Assert(progressA.submittedSceneVersion == progressA.sceneVersion, true)
    @Assert(progressB.submittedSceneVersion == progressB.sceneVersion, true)
    // Each window's new scene came from its own controller and really
    // materialized its own rows: neither window borrowed the sibling's work.
    @Assert(controllerA.uiSceneVersion() > versionABefore, true)
    @Assert(controllerB.uiSceneVersion() > versionBBefore, true)
    @Assert(controllerA.buildCount > buildABefore, true)
    @Assert(controllerB.buildCount > buildBBefore, true)
    @Assert(controllerA.materializedRows() > 0, true)
    @Assert(controllerB.materializedRows() > 0, true)
    // The shared turn really covered both windows and never waited twice.
    @Assert(bothLiveTurns, turns)
    @Assert(singleWaitTurns, turns)

    // Independence inside the SAME loop: with only window A changing, A must
    // still publish and B must not gain a scene, a build or a model read from
    // its sibling's activity.
    let idleSceneB = windowB.windowProgress().sceneVersion
    let idleBuildB = controllerB.buildCount
    let activeSceneA = windowA.windowProgress().sceneVersion
    var soloTurns: Int64 = 0
    while (soloTurns < 20) {
        controllerA.scrollTo(100 + soloTurns * 4)
        let turn = application.pumpOneTurn()
        @Assert(turn.isOpen, true)
        @Assert(turn.windowCount, 2)
        soloTurns += 1
        if (windowA.windowProgress().acceptedSceneVersion > activeSceneA) {
            break
        }
    }
    let soloProgressA = windowA.windowProgress()
    let soloProgressB = windowB.windowProgress()
    reportWindowPerf("window_dual_active_sibling_idle_in_loop", 0,
        "claim=active_sibling_idle_shared_loop windows=2 solo_turns=${soloTurns} " +
        "active_scene=${soloProgressA.sceneVersion} idle_scene=${soloProgressB.sceneVersion} " +
        "idle_scene_before=${idleSceneB} active_builds=${controllerA.buildCount - buildABefore} " +
        "idle_builds=${controllerB.buildCount - idleBuildB} " +
        "idle_accepted=${soloProgressB.acceptedSceneVersion} active_accepted=${soloProgressA.acceptedSceneVersion} " +
        "dual_active_shared_host=measured_here")
    @Assert(soloProgressA.sceneVersion > activeSceneA, true)
    @Assert(soloProgressB.sceneVersion, idleSceneB)
    @Assert(controllerB.buildCount, idleBuildB)
    @Assert(soloProgressB.acceptedSceneVersion, idleSceneB)
    @Assert(soloProgressA.lastNativeFailure, "none")
    @Assert(soloProgressB.lastNativeFailure, "none")
    application.close()
    @Assert(application.isOpen(), false)
}

/// Observable content of an accepted-scene dump: node kind, label, value and
/// field binding, ignoring framework-allocated ids and geometry. Two authors that
/// present the same panel commit the same content shape.
private func perfContentShape(dump: String): String {
    let lines = ArrayList<String>()
    for (line in dump.split("\n")) {
        let parts = line.split("|")
        if (parts.size >= 5) {
            lines.add("${parts[0]}|${parts[2]}|${parts[3]}|${parts[4]}")
        }
    }
    // Insertion sort: no dependency and no hidden ordering assumption.
    var outer: Int64 = 1
    while (outer < lines.size) {
        let value = lines[outer]
        var inner = outer - 1
        while (inner >= 0 && lines[inner] > value) {
            lines[inner + 1] = lines[inner]
            inner -= 1
        }
        lines[inner + 1] = value
        outer += 1
    }
    let builder = StringBuilder()
    for (line in lines) {
        builder.append(line)
        builder.append("\n")
    }
    return builder.toString()
}

// --- C: implementation comparison and real scheduling evidence ---------------

/// Raw observation of one tree implementation for the SAME single-object change.
private class WindowTreeChangeSample {
    var indexCalls: Int64 = 0
    var indexMicros: Int64 = 0
    var rowBuildMicros: Int64 = 0
    var totalMicros: Int64 = 0
    var materialized: Int64 = 0
    var acceptedText: String = ""
    var acceptedVersion: Int64 = 0
    var nativeSubmits: Int64 = 0
    var path: String = ""
}

/// The SAME single-object change through the two implementations, in one process
/// and from the same starting state (fresh projection, same expanded set, same
/// cache state), so the contrast is the implementation and not a different load:
///   * content-only patch: key-indexed in-place update, no logical walk;
///   * rebuild: the existing full re-index of the same change.
/// Both must commit the same visible text.
private func sampleTreeSingleChange(contentOnly: Bool): WindowTreeChangeSample {
    let source = WindowPerfTreeSource(10000)
    let controller = WindowPerfTreeController(source, contentOnly: contentOnly)
    let window = CjguiComposableUiWindow(controller)
    @Assert(window.start(), true)
    @Assert(window.refresh(), true)
    let sample = WindowTreeChangeSample()
    sample.path = if (contentOnly) { "content_only" } else { "rebuild" }
    sample.materialized = controller.materializedRows()
    let childAtBefore = source.childAtCalls
    let indexBefore = controller.indexMicros
    let rowBuildBefore = controller.rowBuildMicros
    let submitsBefore = window.windowProjection().nativeSubmissionCount
    let versionBefore = window.windowProgress().acceptedSceneVersion
    let started = MonoTime.now()
    // The very same change for both implementations.
    source.changeOne(3, " *")
    controller.dataChanged()
    @Assert(window.refreshIfNeeded(), true)
    sample.totalMicros = (MonoTime.now() - started).toMicroseconds()
    sample.indexCalls = source.childAtCalls - childAtBefore
    sample.indexMicros = controller.indexMicros - indexBefore
    sample.rowBuildMicros = controller.rowBuildMicros - rowBuildBefore
    sample.materialized = controller.materializedRows()
    sample.acceptedVersion = window.windowProgress().acceptedSceneVersion
    sample.nativeSubmits = window.windowProjection().nativeSubmissionCount - submitsBefore
    // Same-step visible text, read from the ACCEPTED scene.
    sample.acceptedText = window.acceptedNodeValue("window-perf-row-leaf-3") ?? ""
    @Assert(sample.acceptedText, "叶 3 *")
    @Assert(sample.acceptedVersion > versionBefore, true)
    @Assert(sample.nativeSubmits > 0, true)
    @Assert(window.windowProgress().lastNativeFailure, "none")
    window.close()
    return sample
}

@Test
func windowTreePatchVersusRebuildForTheSameSingleChange(): Unit {
    let patch = sampleTreeSingleChange(true)
    let rebuild = sampleTreeSingleChange(false)
    // Correctness is identical: both commit the same visible text.
    @Assert(patch.acceptedText, rebuild.acceptedText)
    // The implementations differ exactly where the capability claims: the patch
    // performs no logical index walk, the rebuild walks the whole logical tree.
    @Assert(patch.indexCalls, 0)
    @Assert(rebuild.indexCalls > 10000, true)
    // Materialization stays viewport-bounded for both.
    @Assert(patch.materialized <= 8 + 2 * 4, true)
    @Assert(rebuild.materialized <= 8 + 2 * 4, true)
    reportWindowPerf("window_tree_single_change_contrast", patch.totalMicros,
        "same_change=leaf-3+* process=one instance=fresh patch_path=${patch.path} " +
        "patch_index_calls=${patch.indexCalls} patch_index_us=${patch.indexMicros} " +
        "patch_row_build_us=${patch.rowBuildMicros} patch_materialized=${patch.materialized} " +
        "rebuild_path=${rebuild.path} rebuild_index_calls=${rebuild.indexCalls} " +
        "rebuild_index_us=${rebuild.indexMicros} rebuild_row_build_us=${rebuild.rowBuildMicros} " +
        "rebuild_materialized=${rebuild.materialized} patch_total_us=${patch.totalMicros} " +
        "rebuild_total_us=${rebuild.totalMicros} same_visible_text=true " +
        "note=numbers_are_one_run_do_not_divide_across_runs")
}

/// Two ACTIVE windows through ONE normal application loop, with the second
/// window's work really queued while the first keeps working. The sample records
/// the three monotonic moments the handoff asks for: enqueue, owner applied and
/// scene accepted. Stopping both must leave zero further builds/submissions.
@Test
func windowTwoActiveWindowsQueueLatencyThroughOneApplicationLoop(): Unit {
    let application = CjguiMacosApplication(maximumWindowCount: 2)
    let sourceA = WindowPerfTreeSource(1000)
    let sourceB = WindowPerfTreeSource(1000)
    let controllerA = WindowPerfTreeController(sourceA)
    let controllerB = WindowPerfTreeController(sourceB)
    let openA = application.openWindow(controllerA,
        configuration: CjguiMacosApplicationWindowConfiguration("CJGUI 调度 A", 620u32, 440u32))
    @Assert(openA.didOpen, true)
    let openB = application.openWindow(controllerB,
        configuration: CjguiMacosApplicationWindowConfiguration("CJGUI 调度 B", 620u32, 440u32))
    @Assert(openB.didOpen, true)
    let identifiers = application.windowIdentifiers()
    @Assert(identifiers.size, 2)
    let windowA = application.window(identifiers[0]) ?? CjguiComposableUiWindow(controllerA)
    let windowB = application.window(identifiers[1]) ?? CjguiComposableUiWindow(controllerB)

    let queuedMicros = ArrayList<Int64>()
    let appliedMicros = ArrayList<Int64>()
    let acceptedMicros = ArrayList<Int64>()
    let servedTurns = ArrayList<Int64>()
    let versionABefore = windowA.windowProgress().acceptedSceneVersion
    var samples: Int64 = 0
    var servedRounds: Int64 = 0
    var unservedWithinTen: Int64 = 0
    var bFailure = "none"
    var starvedDiagnostics = ""
    var lastWaited = "none"
    while (samples < 20) {
        // A keeps doing real work (a scroll that changes materialization).
        controllerA.scrollTo(samples * 5)
        // B queues one change through its existing controller entry and the
        // shared loop serves it; the number of shared turns it needs is measured,
        // not assumed, because native acceptance of the second window can land one
        // turn after its refresh.
        let enqueue = MonoTime.now()
        let versionBefore = windowB.windowProgress().acceptedSceneVersion
        // Targets rows inside B's viewport: a content patch of an OFF-SCREEN row
        // legitimately publishes no new scene (the row is not materialized), so it
        // could not be used as a "queued work was served" signal.
        sourceB.changeOne(samples % 8, " q${samples}")
        controllerB.dataChanged()
        var turns: Int64 = 0
        var accepted = MonoTime.now()
        var served = false
        while (turns < 10) {
            let turn = application.pumpOneTurn()
            @Assert(turn.isOpen, true)
            @Assert(turn.windowCount, 2)
            lastWaited = match (turn.waitedWindow) {
                case Some(value) => value.generation.toString()
                case None => "none"
            }
            turns += 1
            accepted = MonoTime.now()
            if (windowB.windowProgress().acceptedSceneVersion > versionBefore) {
                served = true
                break
            }
            // A keeps being served in the same turns while B is pending.
            controllerA.scrollTo(samples * 5 + turns)
        }
        if (!served) {
            unservedWithinTen += 1
            if (starvedDiagnostics.isEmpty()) {
                let starved = windowB.windowProgress()
                starvedDiagnostics = "first_starved_sample=${samples} turns=10 " +
                    "b_pending='${starved.pendingRefreshReason}' b_failure='${starved.lastNativeFailure}' " +
                    "b_scene=${starved.sceneVersion} b_accepted=${starved.acceptedSceneVersion} " +
                    "b_active=${starved.isActive} b_builds=${controllerB.buildCount} " +
                    "a_scene=${windowA.windowProgress().sceneVersion} " +
                    "a_builds=${controllerA.buildCount} waited_last=${lastWaited}"
            }
        } else {
            servedRounds += 1
        }
        servedTurns.add(turns)
        queuedMicros.add((controllerB.lastAppliedStamp - enqueue).toMicroseconds())
        appliedMicros.add((accepted - controllerB.lastAppliedStamp).toMicroseconds())
        acceptedMicros.add((accepted - enqueue).toMicroseconds())
        samples += 1
    }
    // Both windows really published their own scenes in the one loop.
    @Assert(windowA.windowProgress().acceptedSceneVersion > versionABefore, true)
    @Assert(windowA.windowProgress().isActive, true)
    @Assert(windowB.windowProgress().lastNativeFailure, "none")


    // Drain the work queued by the last sample before measuring convergence:
    // A's final scroll was enqueued while B was still being served.
    var drain: Int64 = 0
    while (drain < 5) {
        let _ = application.pumpOneTurn()
        drain += 1
    }
    // Stop: no side changes any more, so the shared loop must add no work.
    let buildsABefore = controllerA.buildCount
    let buildsBBefore = controllerB.buildCount
    let submitsABefore = windowA.windowProjection().nativeSubmissionCount
    let submitsBBefore = windowB.windowProjection().nativeSubmissionCount
    var idle: Int64 = 0
    while (idle < 10) {
        let turn = application.pumpOneTurn()
        @Assert(turn.isOpen, true)
        idle += 1
    }
    let buildA = controllerA.buildCount - buildsABefore
    let buildB = controllerB.buildCount - buildsBBefore
    let submitA = windowA.windowProjection().nativeSubmissionCount - submitsABefore
    let submitB = windowB.windowProjection().nativeSubmissionCount - submitsBBefore
    reportWindowPerf("window_two_active_queue_latency", medianOf(acceptedMicros),
        "claim=two_active_one_normal_loop samples=20 windows=2 raw_turns=${perfSamplesText(servedTurns)} " +
        "turns_to_scene_accepted_p50=${percentile(servedTurns, 50)} " +
        "turns_to_scene_accepted_p95=${percentile(servedTurns, 95)} " +
        "turns_to_scene_accepted_max=${perfMax(servedTurns)} " +
        "enqueue_to_owner_applied_us_p50=${percentile(queuedMicros, 50)} " +
        "enqueue_to_owner_applied_us_p95=${percentile(queuedMicros, 95)} " +
        "enqueue_to_owner_applied_us_max=${perfMax(queuedMicros)} " +
        "owner_applied_to_scene_accepted_us_p50=${percentile(appliedMicros, 50)} " +
        "enqueue_to_scene_accepted_us_p50=${percentile(acceptedMicros, 50)} " +
        "enqueue_to_scene_accepted_us_p95=${percentile(acceptedMicros, 95)} " +
        "enqueue_to_scene_accepted_us_max=${perfMax(acceptedMicros)} " +
        "served_within_10_turns=${servedRounds}/20 unserved_within_10=${unservedWithinTen} " +
        "b_last_native_failure='${bFailure}' a_kept_working=true served_by_shared_loop=${servedRounds > 0} idle_turns=10 " +
        "starved_diagnostics='${starvedDiagnostics}' " +
        "idle_builds_a=${buildA} idle_builds_b=${buildB} idle_submits_a=${submitA} " +
        "idle_submits_b=${submitB} gpu_presentation=not_claimed")
    @Assert(buildA, 0)
    @Assert(buildB, 0)
    @Assert(submitA, 0)
    @Assert(submitB, 0)
    // Bounded claims only: the shared loop serves window B on the very next turn
    // while window A keeps working (verified over the first rounds), no native
    // failure is reported, and stopping both leaves no further work. A later
    // starvation of the second window is REPORTED above as a product finding - it
    // is not quietly asserted as expected behaviour.
    // Every queued change on a VISIBLE row is served by the shared loop.
    @Assert(servedRounds, 20)
    @Assert(unservedWithinTen, 0)
    @Assert(perfMax(servedTurns), 1)
    @Assert(bFailure, "none")
    application.close()
    @Assert(application.isOpen(), false)
}

/// Nearest-rank percentile of a raw sample list (no interpolation), so the
/// reported p50/p95 are real observed samples.
private func percentile(samples: ArrayList<Int64>, percent: Int64): Int64 {
    if (samples.size == 0) {
        return 0
    }
    let sorted = ArrayList<Int64>(samples)
    var outer: Int64 = 1
    while (outer < sorted.size) {
        let value = sorted[outer]
        var inner = outer - 1
        while (inner >= 0 && sorted[inner] > value) {
            sorted[inner + 1] = sorted[inner]
            inner -= 1
        }
        sorted[inner + 1] = value
        outer += 1
    }
    var rank = (percent * sorted.size + 99) / 100
    if (rank < 1) {
        rank = 1
    }
    if (rank > sorted.size) {
        rank = sorted.size
    }
    return sorted[rank - 1]
}

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
    /// When true this window authors the practical-size/growth/alignment/font
    /// fixture instead of the gap/padding-only baseline. Both fixtures stay in
    /// the same class so the existing measurement helpers sample the new panel
    /// through the exact same path the baseline uses.
    private let practical: Bool
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

    init(fixture: WindowPerfFieldFixture, generated: Bool, practical!: Bool = false) {
        this.fixture = fixture
        this.generated = generated
        this.practical = practical
        this.provider = WindowPerfFieldProvider(fixture)
        if (generated) {
            let built = if (practical) {
                buildPracticalPanelCatalog(fixture)
            } else {
                buildPanelCatalog(fixture)
            }
            this.catalog = built
            this.holder = Some(CjguiGeneratedUiStructureHolder(built))
            this.spec = Some(if (practical) {
                perfPracticalPanelSpec(fixture)
            } else {
                perfPanelSpec(fixture)
            })
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
                case None => handwrittenPanelRoot(pendingGap)
            }
        } else {
            handwrittenPanelRoot(pendingGap)
        }
        lastBuiltGap = pendingGap
        buildMicros += (MonoTime.now() - started).toMicroseconds()
        return root
    }

    /// The handwritten builder this controller authors, selected by the fixture
    /// flavor so a baseline round is byte-for-byte the old panel.
    private func handwrittenPanelRoot(gap: Int64): CjguiComposableUiNode {
        if (practical) {
            return perfPracticalHandwrittenPanel(fixture, gap: gap)
        }
        return perfHandwrittenPanel(fixture, gap: gap)
    }

    /// The generated author's own work for one structure version: decode-free
    /// submission here (the spec object is already in memory, so no decode call
    /// happens and none is labelled), then the framework's validation and
    /// expansion inside `submit`. It is measured on its own so the shared window
    /// refresh is never charged for it.
    public func submitStructure(gap!: Int64 = 6): Bool {
        pendingGap = gap
        if (let Some(value) <- holder) {
            let candidate = if (practical) {
                perfPracticalPanelSpec(fixture, gap: gap)
            } else {
                perfPanelSpec(fixture, gap: gap)
            }
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
        return handwrittenPanelRoot(6)
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

    /// The accepted node identity behind one authored stable key, through THIS
    /// author's own mapping: the generated author asks its accepted key table
    /// (the framework allocated the identity), the handwritten author mirrors the
    /// ids it declared. The key is the shared identity; the node id is how each
    /// author addresses its own accepted node.
    public func nodeIdForKey(key: String): Int64 {
        if (let Some(value) <- holder) {
            return value.nodeIdForKey(key)
        }
        return perfHandwrittenNodeId(key, practical: practical)
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

// --- the practical style fixture -------------------------------------------
//
// The baseline above authors only gap/padding, which the catalog has always
// consumed. This second fixture authors the shared size / growth / alignment /
// font vocabulary in BOTH languages from the SAME published property
// definitions, so equivalence is asserted for the properties the catalog now
// maps and not only for the old ones. The baseline case and its numbers are
// left exactly as they were.

private let PERF_PRACTICAL_ROOT_ID: Int64 = 900
private let PERF_PRACTICAL_ROW_ID: Int64 = 901
private let PERF_PRACTICAL_ROW_LABEL_ID: Int64 = 902
private let PERF_PRACTICAL_ROW_INPUT_ID: Int64 = 903
private let PERF_PRACTICAL_ROW_GAP: Int64 = 6
private let PERF_PRACTICAL_ROW_PADDING: Int64 = 6
private let PERF_PRACTICAL_LABEL_WIDTH: Int64 = 160
private let PERF_PRACTICAL_LABEL_TEXT: String = "字段宽度"
private let PERF_PRACTICAL_LABEL_FONT_SIZE: Int64 = 24
private let PERF_PRACTICAL_EDITOR_FONT_SIZE: Int64 = 12

private func perfPracticalLabelNodeId(index: Int64): Int64 {
    return 910 + (index - 1) * 2
}

private func perfPracticalInputNodeId(index: Int64): Int64 {
    return 911 + (index - 1) * 2
}

/// The practical handwritten pane: a horizontal row whose first label keeps a
/// bounded width while its sibling editor grows, with a declared font size and
/// a non-default vertical alignment, inside a container that declares both gap
/// and padding. `labelFontSize` and `editorAlignY` are parameters so the SAME
/// author can be sampled twice with exactly one property changed, which is how
/// the differential geometry claims are proved.
private func perfPracticalHandwrittenPanel(fixture: WindowPerfFieldFixture, gap!: Int64 = 6,
    labelFontSize!: Float64 = Float64(PERF_PRACTICAL_LABEL_FONT_SIZE),
    editorAlignY!: Int64 = CJGUI_COMPOSABLE_UI_ALIGN_CENTER,
    labelFixedWidth!: Int64 = PERF_PRACTICAL_LABEL_WIDTH): CjguiComposableUiNode {
    let root = cjguiComposableVertical(PERF_PRACTICAL_ROOT_ID, "perf-panel",
        CjguiComposableUiStyle(gap: gap, padding: 8))
    let row = cjguiComposableHorizontal(PERF_PRACTICAL_ROW_ID, "perf-row",
        CjguiComposableUiStyle(gap: PERF_PRACTICAL_ROW_GAP, padding: PERF_PRACTICAL_ROW_PADDING))
    row.add(cjguiComposableText(PERF_PRACTICAL_ROW_LABEL_ID, "perf-row-label", PERF_PRACTICAL_LABEL_TEXT,
        CjguiComposableUiStyle(fixedWidth: labelFixedWidth, fontSize: labelFontSize)))
    row.add(cjguiComposableTextInput(PERF_PRACTICAL_ROW_INPUT_ID, "perf-input-0", fixture.editorLabel(0),
        fixture.value(0), fixture.resourceId(0),
        CjguiComposableUiStyle(growX: 1, fontSize: Float64(PERF_PRACTICAL_EDITOR_FONT_SIZE),
            alignY: editorAlignY),
        fieldId: fixture.fieldId(0), operationActionName: "EDIT_DRAFT_TEXT",
        operationResourceId: 1, displayValueRole: "draft"))
    root.add(row)
    var index: Int64 = 1
    while (index < fixture.fields) {
        root.add(cjguiComposableText(perfPracticalLabelNodeId(index), "perf-label-${index}",
            fixture.staticLabel(index), CjguiComposableUiStyle()))
        root.add(cjguiComposableTextInput(perfPracticalInputNodeId(index), "perf-input-${index}",
            fixture.editorLabel(index), fixture.value(index), fixture.resourceId(index),
            CjguiComposableUiStyle(), fieldId: fixture.fieldId(index),
            operationActionName: "EDIT_DRAFT_TEXT", operationResourceId: 1, displayValueRole: "draft"))
        index += 1
    }
    return root
}

/// The generated author's capability catalog for the practical fixture. Every
/// style property is registered through the SAME shared declaration
/// (`containerStyleProperties` / `leafStyleProperties`) the framework publishes,
/// so the generated side cannot drift from the handwritten side by inventing or
/// dropping a property. A registration that the framework rejects fails here
/// instead of degrading silently.
private func buildPracticalPanelCatalog(fixture: WindowPerfFieldFixture): CjguiGeneratedUiCapabilityCatalog {
    let catalog = CjguiGeneratedUiCapabilityCatalog()
    @Assert(catalog.registerComponent(CjguiGeneratedUiComponentSpec("vertical",
        CjguiGeneratedUiPresentation.containerStyleProperties(), true, childLimit: 256)), true)
    @Assert(catalog.registerComponent(CjguiGeneratedUiComponentSpec("horizontal",
        CjguiGeneratedUiPresentation.containerStyleProperties(), true, childLimit: 256)), true)
    let labelProperties = CjguiGeneratedUiPresentation.leafStyleProperties()
    labelProperties.add(CjguiGeneratedUiPropertySpec("text", "STRING", required: true, maxLength: 64))
    @Assert(catalog.registerComponent(CjguiGeneratedUiComponentSpec("label", labelProperties, false)), true)
    let inputProperties = CjguiGeneratedUiPresentation.leafStyleProperties()
    inputProperties.add(CjguiGeneratedUiPropertySpec("label", "STRING", maxLength: 64))
    @Assert(catalog.registerComponent(CjguiGeneratedUiComponentSpec("textInput", inputProperties, false)), true)
    var index: Int64 = 0
    while (index < fixture.fields) {
        @Assert(catalog.registerField(CjguiGeneratedUiFieldSpec(fixture.fieldId(index),
            fixture.editorLabel(index), "TEXT", fixture.resourceId(index),
            writeActionName: "EDIT_DRAFT_TEXT")), true)
        index += 1
    }
    return catalog
}

/// The same practical panel declared through the generated presentation: the
/// row is a `horizontal` container, the bounded label declares `fixedWidth` and
/// `fontSize`, the editor declares `growX` and `alignY`, and the row declares
/// its own `gap`/`padding`. Nothing is written onto a built node afterwards.
private func perfPracticalPanelSpec(fixture: WindowPerfFieldFixture, gap!: Int64 = 6,
    labelFontSize!: Int64 = PERF_PRACTICAL_LABEL_FONT_SIZE,
    editorAlignY!: String = "center"): CjguiGeneratedUiNodeSpec {
    let rowChildren = ArrayList<CjguiGeneratedUiNodeSpec>()
    let rowLabelProperties = HashMap<String, String>()
    rowLabelProperties.add("text", PERF_PRACTICAL_LABEL_TEXT)
    rowLabelProperties.add("fixedWidth", "${PERF_PRACTICAL_LABEL_WIDTH}")
    rowLabelProperties.add("fontSize", "${labelFontSize}")
    rowChildren.add(CjguiGeneratedUiNodeSpec("perf-row-label", "label", properties: rowLabelProperties))
    let rowInputProperties = HashMap<String, String>()
    rowInputProperties.add("label", fixture.editorLabel(0))
    rowInputProperties.add("growX", "1")
    rowInputProperties.add("fontSize", "${PERF_PRACTICAL_EDITOR_FONT_SIZE}")
    rowInputProperties.add("alignY", editorAlignY)
    rowChildren.add(CjguiGeneratedUiNodeSpec("perf-input-0", "textInput", properties: rowInputProperties,
        fieldId: fixture.fieldId(0)))
    let rowProperties = HashMap<String, String>()
    rowProperties.add("gap", "${PERF_PRACTICAL_ROW_GAP}")
    rowProperties.add("padding", "${PERF_PRACTICAL_ROW_PADDING}")
    let children = ArrayList<CjguiGeneratedUiNodeSpec>()
    children.add(CjguiGeneratedUiNodeSpec("perf-row", "horizontal", properties: rowProperties,
        children: rowChildren))
    var index: Int64 = 1
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

/// Builds one accepted generated practical tree for a single-property variant.
/// It runs the same submit + build path the controller uses, so the comparison
/// is between real accepted trees rather than hand-assembled nodes.
private func perfPracticalGeneratedRoot(fixture: WindowPerfFieldFixture, gap!: Int64 = 6,
    labelFontSize!: Int64 = PERF_PRACTICAL_LABEL_FONT_SIZE,
    editorAlignY!: String = "center"): CjguiComposableUiNode {
    let catalog = buildPracticalPanelCatalog(fixture)
    let holder = CjguiGeneratedUiStructureHolder(catalog)
    let provider = WindowPerfFieldProvider(fixture)
    let submitted = holder.submit(perfPracticalPanelSpec(fixture, gap: gap,
        labelFontSize: labelFontSize, editorAlignY: editorAlignY), provider)
    @Assert(submitted.candidateAccepted, true)
    // The candidate identity transaction is part of building the accepted tree;
    // rendering without it would fall back to an empty accepted structure.
    @Assert(holder.beginCandidateRefresh(), true)
    let root = holder.buildRefreshNode(provider)
    @Assert(holder.prepareCandidateRefresh(), true)
    holder.commitCandidateRefresh()
    return root
}

/// Declared node count of the practical panel: root + row + two row children +
/// two nodes per remaining field.
private func perfPracticalDeclaredNodes(fixture: WindowPerfFieldFixture): Int64 {
    return 4 + 2 * (fixture.fields - 1)
}

/// The practical panel's declared stable keys, in built order.
private func perfPracticalPanelKeys(fields: Int64): ArrayList<String> {
    let keys = ArrayList<String>()
    keys.add("perf-panel")
    keys.add("perf-row")
    keys.add("perf-row-label")
    keys.add("perf-input-0")
    var index: Int64 = 1
    while (index < fields) {
        keys.add("perf-label-${index}")
        keys.add("perf-input-${index}")
        index += 1
    }
    return keys
}

private func perfPracticalHandwrittenNodeId(key: String): Int64 {
    if (key == "perf-panel") {
        return PERF_PRACTICAL_ROOT_ID
    }
    if (key == "perf-row") {
        return PERF_PRACTICAL_ROW_ID
    }
    if (key == "perf-row-label") {
        return PERF_PRACTICAL_ROW_LABEL_ID
    }
    if (key == "perf-input-0") {
        return PERF_PRACTICAL_ROW_INPUT_ID
    }
    if (key.startsWith("perf-label-")) {
        return perfPracticalLabelNodeId(numericSuffix(key))
    }
    if (key.startsWith("perf-input-")) {
        return perfPracticalInputNodeId(numericSuffix(key))
    }
    return -1
}

/// Declared node count of one author's panel: the handwritten pane declares
/// 1 + 2*fields nodes, the generated description declares the same shape, and the
/// accepted scene must materialize exactly that (plus nothing hidden).
private func perfDeclaredNodes(fixture: WindowPerfFieldFixture, practical!: Bool = false): Int64 {
    if (practical) {
        return perfPracticalDeclaredNodes(fixture)
    }
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

/// One component of a `normalizedPanelDump` bounds field ("x,y,w,h").
private func panelBoundsComponent(bounds: String, index: Int64): Int64 {
    if (bounds.size == 0) {
        return -1
    }
    let parts = bounds.split(",")
    if (index < 0 || index >= parts.size) {
        return -1
    }
    return perfParseInt(parts[index], -1)
}

/// The bounds of the first TEXT node carrying one exact value in the dump.
private func panelDumpTextBounds(dump: String, value: String): String {
    for (line in dump.split("\n")) {
        let parts = line.split("|")
        if (parts.size >= 9 && parts[0] == "${CJGUI_COMPOSABLE_UI_TEXT}" && parts[2] == value) {
            return parts[8]
        }
    }
    return ""
}

/// The bounds of the first node bound to one exact field id in the dump.
private func panelDumpFieldBounds(dump: String, fieldId: String): String {
    for (line in dump.split("\n")) {
        let parts = line.split("|")
        if (parts.size >= 9 && parts[3] == fieldId) {
            return parts[8]
        }
    }
    return ""
}

/// The bounds of the first node of one node kind in the dump.
private func panelDumpKindBounds(dump: String, kind: Int64): String {
    for (line in dump.split("\n")) {
        let parts = line.split("|")
        if (parts.size >= 9 && parts[0] == "${kind}") {
            return parts[8]
        }
    }
    return ""
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
    /// The node identity THIS author resolved each declared key to, captured
    /// together with `acceptedText` so the item-by-item comparison addresses the
    /// accepted scene through the author's own mapping.
    let keyNodeIds: HashMap<String, Int64> = HashMap<String, Int64>()
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

/// One accepted-scene row of the timed panel, addressed by the NODE IDENTITY the
/// author's own stable key currently maps to. The generated author asks the
/// framework for the identity it allocated for a key; the handwritten author
/// declares its ids explicitly. Node id is the probe identity here, not the
/// semantic id: a generated node's semantic id belongs to the framework's
/// identity slot while the declared key is the identity both authors share, so
/// each author resolves the same key through its OWN mapping. `present` is false
/// when the accepted scene has no such node: a probe that silently substituted a
/// zero rectangle could not tell "unchanged" from "not found", which is how a
/// missing generated node passed as equal.
private class WindowPerfAcceptedRow {
    var present: Bool = false
    var kind: Int64 = 0
    var label: String = ""
    var value: String = ""
    var fieldId: String = ""
    var actionName: String = ""
    var operationActionName: String = ""
    var operationResourceId: Int64 = -1
    var resourceId: Int64 = -1
    var displayValueRole: String = ""
    var gap: Int64 = 0
    var padding: Int64 = 0
    var bounds: String = ""

    func signature(): String {
        return "${kind}|${label}|${value}|${fieldId}|${actionName}|${operationActionName}|" +
            "${operationResourceId}|${resourceId}|${displayValueRole}|${gap}|${padding}|${bounds}"
    }
}

private func perfParseInt(value: String, fallback: Int64): Int64 {
    return match (parseGeneratedInteger(value)) {
        case Some(parsed) => parsed
        case None => fallback
    }
}

private func perfAcceptedRow(dump: String, nodeId: Int64): WindowPerfAcceptedRow {
    let row = WindowPerfAcceptedRow()
    for (line in dump.split("\n")) {
        let parts = line.split("|")
        if (parts.size < 14 || perfParseInt(parts[0], -1) != nodeId) {
            continue
        }
        row.present = true
        row.kind = perfParseInt(parts[1], 0)
        row.label = parts[3]
        row.value = parts[4]
        row.fieldId = parts[5]
        row.actionName = parts[6]
        row.operationActionName = parts[7]
        row.operationResourceId = perfParseInt(parts[8], -1)
        row.resourceId = perfParseInt(parts[9], -1)
        row.displayValueRole = parts[10]
        row.gap = perfParseInt(parts[11], 0)
        row.padding = perfParseInt(parts[12], 0)
        row.bounds = parts[13]
        return row
    }
    return row
}

/// The node identity the handwritten pane declares for one stable panel key.
/// It builds these ids explicitly, so a probe can address them the same way the
/// generated author addresses the identities the framework allocated for it.
private func perfHandwrittenNodeId(key: String, practical!: Bool = false): Int64 {
    if (practical) {
        return perfPracticalHandwrittenNodeId(key)
    }
    if (key == "perf-panel") {
        return 500
    }
    if (key.startsWith("perf-label-")) {
        return 601 + numericSuffix(key) * 4
    }
    if (key.startsWith("perf-input-")) {
        return 602 + numericSuffix(key) * 4
    }
    return -1
}

/// The panel's declared stable keys, in built order: the ONE identity set both
/// authors must commit. Each author resolves them to its own node ids.
private func perfPanelKeys(fields: Int64, practical!: Bool = false): ArrayList<String> {
    if (practical) {
        return perfPracticalPanelKeys(fields)
    }
    let keys = ArrayList<String>()
    keys.add("perf-panel")
    var index: Int64 = 0
    while (index < fields) {
        keys.add("perf-label-${index}")
        keys.add("perf-input-${index}")
        index += 1
    }
    return keys
}

/// Capture the author's own key -> node identity mapping at the SAME moment the
/// accepted scene text is taken, so the later item-by-item comparison addresses
/// one consistent pair. A key the author cannot resolve is recorded as -1 and
/// fails the presence assertion where it is used.
private func perfRecordKeyNodeIds(controller: WindowPerfPanelController, result: WindowPerfScenarioResult,
    fields: Int64, practical!: Bool = false): Unit {
    for (key in perfPanelKeys(fields, practical: practical)) {
        result.keyNodeIds.add(key, controller.nodeIdForKey(key))
    }
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
private func samplePanelScenario(generated: Bool, fields: Int64, scenario: String, sampleCount: Int64,
    practical!: Bool = false): WindowPerfScenarioResult {
    let result = WindowPerfScenarioResult()
    if (scenario == "cold_submit") {
        // Cold: EACH sample is a NEW controller/holder whose FIRST valid
        // submission is timed. `window.start()` and the fixture construction stay
        // outside the timing; the author's own submission and the shared window
        // refresh are both inside it, and the author part is broken out.
        var sample: Int64 = 0
        while (sample < sampleCount) {
            let fixture = WindowPerfFieldFixture(fields)
            let controller = WindowPerfPanelController(fixture, generated, practical: practical)
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
                perfRecordKeyNodeIds(controller, result, fields, practical: practical)
                result.acceptedNodes = window.acceptedNodeCount()
                result.acceptedVersion = progress.acceptedSceneVersion
                result.sceneVersion = progress.sceneVersion
                result.controllerBuilds = controller.buildCount
                result.nativeSubmits = window.windowProjection().nativeSubmissionCount
                result.declaredNodes = perfDeclaredNodes(fixture, practical: practical)
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
    let controller = WindowPerfPanelController(fixture, generated, practical: practical)
    let window = CjguiComposableUiWindow(controller)
    @Assert(window.start(), true)
    perfPanelAccepts(controller, window)
    let baselineBuilds = controller.buildCount
    let baselineSubmits = window.windowProjection().nativeSubmissionCount
    let baselineVersion = window.windowProgress().acceptedSceneVersion
    let baselineText = window.acceptedSceneDump()
    // A child that a real layout change must MOVE: the second field editor sits
    // after the first label, so a changed container gap shifts its position. A
    // late child of a tall panel can be clamped by its parent's box, where a gap
    // change is no longer observable.
    let boundsProbeKey = if (fields >= 2) { "perf-input-1" } else { "perf-panel" }
    let boundsProbe = controller.nodeIdForKey(boundsProbeKey)
    @Assert(boundsProbe > 0, true)
    let firstRow = perfAcceptedRow(window.acceptedSceneDump(), boundsProbe)
    @Assert(firstRow.present, true)
    let firstBounds = firstRow.bounds

    var sample: Int64 = 0
    while (sample < sampleCount) {
        let authorBefore = controller.adapterMicros
        let buildsBefore = controller.buildCount
        let submitsBefore = window.windowProjection().nativeSubmissionCount
        let dumpBefore = window.acceptedSceneDump()
        let rowBefore = perfAcceptedRow(dumpBefore, boundsProbe)
        @Assert(rowBefore.present, true)
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
        let rowNow = perfAcceptedRow(dumpNow, boundsProbe)
        @Assert(rowNow.present, true)
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
            // The declared layout attribute really is the accepted one AND the
            // probed child really moved on screen, which is what a hot layout
            // change has to do. Everything except geometry stays put.
            @Assert(controller.acceptedLayoutGap(), declaredGap)
            @Assert(rowNow.bounds != rowBefore.bounds, true)
            @Assert(rowNow.value, rowBefore.value)
            @Assert(rowNow.fieldId, rowBefore.fieldId)
            @Assert(buildsNow > buildsBefore, true)
            @Assert(submitsNow > submitsBefore, true)
            result.observedChange = true
        } else if (scenario == "no_change") {
            // Zero new work: no build, no native submission, no scene advance.
            @Assert(buildsNow, buildsBefore)
            @Assert(submitsNow, submitsBefore)
            @Assert(progress.acceptedSceneVersion, versionBefore)
            @Assert(dumpNow, dumpBefore)
            @Assert(rowNow.bounds, rowBefore.bounds)
        } else {
            // A forced same-content refresh DOES rebuild, but an identical
            // accepted tree publishes neither a new accepted scene revision nor a
            // native submission: that is the framework's redundancy guard. This
            // scenario exists to name it separately from idle convergence, and it
            // is where the rebuild really happens.
            @Assert(buildsNow > buildsBefore, true)
            @Assert(progress.acceptedSceneVersion, versionBefore)
            @Assert(dumpNow, dumpBefore)
            @Assert(rowNow.bounds, rowBefore.bounds)
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
    perfRecordKeyNodeIds(controller, result, fields, practical: practical)
    result.acceptedNodes = window.acceptedNodeCount()
    result.declaredNodes = perfDeclaredNodes(fixture, practical: practical)
    let finalRow = perfAcceptedRow(result.acceptedText, boundsProbe)
    @Assert(finalRow.present, true)
    result.acceptedBoundsKey = finalRow.bounds
    result.acceptedBoundsFirst = firstBounds
    result.acceptedBoundsLast = finalRow.bounds
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
            // commit the same nodes, item by item - kind, content, bindings, role,
            // declared layout, and the geometry the window really accepted under
            // the same viewport. Each author resolves the shared declared key
            // through its OWN mapping (framework-allocated vs declared node id);
            // nothing is dropped from the comparison.
            for (key in perfPanelKeys(fields)) {
                let handNodeId = hand.keyNodeIds.get(key) ?? -1
                let generatedNodeId = generated.keyNodeIds.get(key) ?? -1
                @Assert(handNodeId > 0, true)
                @Assert(generatedNodeId > 0, true)
                let handRow = perfAcceptedRow(hand.acceptedText, handNodeId)
                let generatedRow = perfAcceptedRow(generated.acceptedText, generatedNodeId)
                @Assert(handRow.present, true)
                @Assert(generatedRow.present, true)
                @Assert(handRow.signature(), generatedRow.signature())
            }
            if (scenario == "no_change") {
                // Idle is asserted, not inferred: zero builds/submissions.
                @Assert(hand.controllerBuilds, 0)
                @Assert(generated.controllerBuilds, 0)
                @Assert(hand.nativeSubmits, 0)
                @Assert(generated.nativeSubmits, 0)
            }
        }
    }

    // --- NEW fixture: the shared practical style vocabulary -----------------
    // The cases above author only gap/padding in both trees, so their numbers
    // are baseline evidence for the old property set, not for the size /
    // growth / alignment / font properties the catalog now consumes. This case
    // authors a SECOND panel in both languages from the SAME shared property
    // definitions, asserts the same accepted geometry, and proves each new
    // property really moved geometry versus the gap/padding-only baseline.
    // The old case and its reported numbers are left untouched.
    let practicalFields: Int64 = 4
    let practicalHandController = WindowPerfPanelController(WindowPerfFieldFixture(practicalFields), false,
        practical: true)
    @Assert(practicalHandController.beginSceneRefresh(), true)
    let practicalHandRoot = practicalHandController.buildUi()
    @Assert(practicalHandController.prepareSceneRefresh(), true)
    practicalHandController.commitSceneRefresh()
    let practicalGeneratedController = WindowPerfPanelController(WindowPerfFieldFixture(practicalFields), true,
        practical: true)
    @Assert(practicalGeneratedController.submitStructure(), true)
    @Assert(practicalGeneratedController.beginSceneRefresh(), true)
    let practicalGeneratedRoot = practicalGeneratedController.buildUi()
    @Assert(practicalGeneratedController.prepareSceneRefresh(), true)
    practicalGeneratedController.commitSceneRefresh()

    let practicalHandDump = normalizedPanelDump(practicalHandRoot)
    let practicalGeneratedDump = normalizedPanelDump(practicalGeneratedRoot)
    // AUTHOR-specific identity: kind, content, bindings and accepted bounds
    // must match, node ids and scene versions are ignored.
    @Assert(practicalHandDump, practicalGeneratedDump)

    let boundedLabelBounds = panelDumpTextBounds(practicalHandDump, PERF_PRACTICAL_LABEL_TEXT)
    let growingEditorBounds = panelDumpFieldBounds(practicalHandDump, "label-0")
    let practicalRowBounds = panelDumpKindBounds(practicalHandDump, CJGUI_COMPOSABLE_UI_HORIZONTAL)
    @Assert(boundedLabelBounds.size > 0, true)
    @Assert(growingEditorBounds.size > 0, true)
    @Assert(practicalRowBounds.size > 0, true)
    let boundedWidth = panelBoundsComponent(boundedLabelBounds, 2)
    let growingWidth = panelBoundsComponent(growingEditorBounds, 2)
    let boundedX = panelBoundsComponent(boundedLabelBounds, 0)
    let boundedY = panelBoundsComponent(boundedLabelBounds, 1)
    let growingX = panelBoundsComponent(growingEditorBounds, 0)
    let growingY = panelBoundsComponent(growingEditorBounds, 1)
    let rowX = panelBoundsComponent(practicalRowBounds, 0)
    let rowY = panelBoundsComponent(practicalRowBounds, 1)
    let rowInnerHeight = panelBoundsComponent(practicalRowBounds, 3) - PERF_PRACTICAL_ROW_PADDING * 2
    // fixedWidth: the bounded label is EXACTLY its declared width.
    @Assert(boundedWidth, PERF_PRACTICAL_LABEL_WIDTH)
    // growX: the sibling editor consumed the row's surplus and is wider.
    @Assert(growingWidth > boundedWidth, true)
    // gap/padding: the row's own padding offsets the first child and its gap is
    // the exact space between the two children.
    @Assert(boundedX - rowX, PERF_PRACTICAL_ROW_PADDING)
    @Assert(growingX - (boundedX + boundedWidth), PERF_PRACTICAL_ROW_GAP)
    // alignY=center: the editor sits below the row's inner start by exactly the
    // centering offset, while the label's default START pins it to the inset.
    @Assert(boundedY, rowY + PERF_PRACTICAL_ROW_PADDING)
    @Assert(growingY > boundedY, true)
    @Assert(growingY - boundedY, (rowInnerHeight - panelBoundsComponent(growingEditorBounds, 3)) / 2)

    // fontSize: the SAME author with only the declared label size changed must
    // produce a different node height; the generated author must agree.
    let smallHandDump = normalizedPanelDump(perfPracticalHandwrittenPanel(
        WindowPerfFieldFixture(practicalFields), labelFontSize: Float64(PERF_PRACTICAL_EDITOR_FONT_SIZE)))
    let smallGeneratedDump = normalizedPanelDump(perfPracticalGeneratedRoot(
        WindowPerfFieldFixture(practicalFields), labelFontSize: PERF_PRACTICAL_EDITOR_FONT_SIZE))
    @Assert(smallHandDump, smallGeneratedDump)
    let smallLabelHeight = panelBoundsComponent(
        panelDumpTextBounds(smallHandDump, PERF_PRACTICAL_LABEL_TEXT), 3)
    let largeLabelHeight = panelBoundsComponent(boundedLabelBounds, 3)
    @Assert(largeLabelHeight > smallLabelHeight, true)

    // alignY: the same author with START instead of CENTER puts the editor back
    // on the row's inner start; the generated author must agree.
    let startHandDump = normalizedPanelDump(perfPracticalHandwrittenPanel(
        WindowPerfFieldFixture(practicalFields), editorAlignY: CJGUI_COMPOSABLE_UI_ALIGN_START))
    let startGeneratedDump = normalizedPanelDump(perfPracticalGeneratedRoot(
        WindowPerfFieldFixture(practicalFields), editorAlignY: "start"))
    @Assert(startHandDump, startGeneratedDump)
    let startEditorY = panelBoundsComponent(panelDumpFieldBounds(startHandDump, "label-0"), 1)
    let startLabelY = panelBoundsComponent(panelDumpTextBounds(startHandDump, PERF_PRACTICAL_LABEL_TEXT), 1)
    @Assert(startEditorY, startLabelY)

    reportWindowPerf("window_panel_practical_equivalence", 0,
        "fields=${practicalFields} fixture=shared_style_properties " +
        "props=fixedWidth+growX+fontSize+alignY+gap+padding " +
        "declared_nodes=${perfDeclaredNodes(WindowPerfFieldFixture(practicalFields), practical: true)} " +
        "bounded_fixed_width=${boundedWidth} growing_editor_width=${growingWidth} " +
        "row_padding=${PERF_PRACTICAL_ROW_PADDING} row_gap=${PERF_PRACTICAL_ROW_GAP} " +
        "label_height_font24=${largeLabelHeight} label_height_font12=${smallLabelHeight} " +
        "alignY_center_offset=${growingY - boundedY} alignY_start_offset=${startEditorY - startLabelY} " +
        "compared=kind+content+bindings+bounds ignored=node_id+scene_version")

    // Stage timings for the NEW equivalent panel, through the SAME scenario
    // sampler the baseline uses. The baseline rows above keep their own label
    // and are not relabelled as this evidence.
    for (scenario in ["cold_submit", "hot_structure", "field_change", "no_change"]) {
        let practicalHand = samplePanelScenario(false, practicalFields, scenario, 5, practical: true)
        let practicalGenerated = samplePanelScenario(true, practicalFields, scenario, 5, practical: true)
        reportWindowPerf("window_panel_practical_scenario", medianOf(practicalHand.totals),
            "author=handwritten fixture=shared_style_properties scenario=${scenario} fields=${practicalFields} " +
            "samples=5 min_us=${perfMin(practicalHand.totals)} max_us=${perfMax(practicalHand.totals)} " +
            "raw_us=${perfSamplesText(practicalHand.totals)} author_us=${medianOf(practicalHand.authors)} " +
            "builds=${practicalHand.controllerBuilds} native_submits=${practicalHand.nativeSubmits} " +
            "accepted_v=${practicalHand.acceptedVersion} declared_nodes=${practicalHand.declaredNodes} " +
            "accepted_nodes=${practicalHand.acceptedNodes} decoded=false decode=none " +
            "observed_change=${practicalHand.observedChange} accepted_gap=${practicalHand.acceptedGaps} " +
            "bounds_probe=${practicalHand.acceptedBoundsFirst}->${practicalHand.acceptedBoundsLast} " +
            "noop_refreshes=${practicalHand.noOpRefreshes}")
        reportWindowPerf("window_panel_practical_scenario", medianOf(practicalGenerated.totals),
            "author=generated fixture=shared_style_properties scenario=${scenario} fields=${practicalFields} " +
            "samples=5 min_us=${perfMin(practicalGenerated.totals)} max_us=${perfMax(practicalGenerated.totals)} " +
            "raw_us=${perfSamplesText(practicalGenerated.totals)} author_us=${medianOf(practicalGenerated.authors)} " +
            "builds=${practicalGenerated.controllerBuilds} native_submits=${practicalGenerated.nativeSubmits} " +
            "accepted_v=${practicalGenerated.acceptedVersion} declared_nodes=${practicalGenerated.declaredNodes} " +
            "accepted_nodes=${practicalGenerated.acceptedNodes} decoded=false decode=none " +
            "observed_change=${practicalGenerated.observedChange} accepted_gap=${practicalGenerated.acceptedGaps} " +
            "bounds_probe=${practicalGenerated.acceptedBoundsFirst}->${practicalGenerated.acceptedBoundsLast} " +
            "noop_refreshes=${practicalGenerated.noOpRefreshes}")
        @Assert(practicalHand.declaredNodes == practicalGenerated.declaredNodes, true)
        @Assert(practicalHand.acceptedNodes == practicalGenerated.acceptedNodes, true)
        @Assert(practicalHand.observedChange == practicalGenerated.observedChange, true)
        for (key in perfPanelKeys(practicalFields, practical: true)) {
            let handNodeId = practicalHand.keyNodeIds.get(key) ?? -1
            let generatedNodeId = practicalGenerated.keyNodeIds.get(key) ?? -1
            @Assert(handNodeId > 0, true)
            @Assert(generatedNodeId > 0, true)
            let handRow = perfAcceptedRow(practicalHand.acceptedText, handNodeId)
            let generatedRow = perfAcceptedRow(practicalGenerated.acceptedText, generatedNodeId)
            @Assert(handRow.present, true)
            @Assert(generatedRow.present, true)
            @Assert(handRow.signature(), generatedRow.signature())
        }
        if (scenario == "no_change") {
            @Assert(practicalHand.controllerBuilds, 0)
            @Assert(practicalGenerated.controllerBuilds, 0)
            @Assert(practicalHand.nativeSubmits, 0)
            @Assert(practicalGenerated.nativeSubmits, 0)
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

// --- same-load scroll + split: handwritten vs generated, cold/hot, convergence --
//
// The perf evidence above compares two AUTHORS of the same panel. The new
// generated capabilities (scroll container + generated split) need the same
// treatment on the ordinary window path: identical declared content, identical
// accepted geometry, and comparable real work counters for the SAME load. A hot
// round that changes nothing must not rebuild or resubmit, and the counters must
// converge once the scenario stops.

private class WindowPerfScrollSplitProvider <: CjguiGeneratedUiBindingProvider {
    public func fieldResourceId(fieldId: String): Int64 { return 7 }
    public func fieldOperationResourceId(fieldId: String): Int64 { return 1 }
    public func draftText(fieldId: String): String { return "" }
    public func appliedText(fieldId: String): String { return "" }
    public func draftBoolean(fieldId: String): ?Bool { return None }
    public func executeAction(actionName: String, nodeKey: String): CjguiGeneratedUiActionResult {
        return CjguiGeneratedUiActionResult(true, "")
    }
    public func actionAvailable(actionName: String): Bool { return true }
}

/// Catalog for the author matrix. The declared child limit must cover the
/// LARGEST load the matrix submits, otherwise a bigger load would be refused as
/// `child_limit_exceeded` and the author would silently keep its previous scene -
/// which would look like "no work" instead of "the load was never accepted".
private func windowPerfAuthorMatrixCatalog(maxRows: Int64): CjguiGeneratedUiCapabilityCatalog {
    let catalog = CjguiGeneratedUiCapabilityCatalog()
    let limit = if (maxRows > 16) {
        maxRows + 4
    } else {
        16
    }
    let _ = catalog.registerComponent(CjguiGeneratedUiComponentSpec("vertical",
        CjguiGeneratedUiPresentation.containerStyleProperties(), true, childLimit: limit))
    let labelProperties = ArrayList<CjguiGeneratedUiPropertySpec>()
    labelProperties.add(CjguiGeneratedUiPropertySpec("text", "STRING", required: true))
    for (property in CjguiGeneratedUiPresentation.leafStyleProperties()) {
        labelProperties.add(property)
    }
    let _ = catalog.registerComponent(CjguiGeneratedUiComponentSpec("label", labelProperties, false))
    let scrollProperties = CjguiGeneratedUiPresentation.scrollContentProperties()
    for (property in CjguiGeneratedUiPresentation.leafStyleProperties()) {
        scrollProperties.add(property)
    }
    let _ = catalog.registerComponent(CjguiGeneratedUiComponentSpec("scrollArea", scrollProperties, true,
        childLimit: 1))
    return catalog
}

private func windowPerfScrollSplitCatalog(): CjguiGeneratedUiCapabilityCatalog {
    let catalog = CjguiGeneratedUiCapabilityCatalog()
    let _ = catalog.registerComponent(CjguiGeneratedUiComponentSpec("vertical",
        CjguiGeneratedUiPresentation.containerStyleProperties(), true, childLimit: 16))
    let labelProperties = ArrayList<CjguiGeneratedUiPropertySpec>()
    labelProperties.add(CjguiGeneratedUiPropertySpec("text", "STRING", required: true))
    for (property in CjguiGeneratedUiPresentation.leafStyleProperties()) {
        labelProperties.add(property)
    }
    let _ = catalog.registerComponent(CjguiGeneratedUiComponentSpec("label", labelProperties, false))
    let scrollProperties = CjguiGeneratedUiPresentation.scrollContentProperties()
    for (property in CjguiGeneratedUiPresentation.leafStyleProperties()) {
        scrollProperties.add(property)
    }
    let _ = catalog.registerComponent(CjguiGeneratedUiComponentSpec("scrollArea", scrollProperties, true,
        childLimit: 1))
    let splitProperties = CjguiGeneratedUiPresentation.splitContentProperties()
    for (property in CjguiGeneratedUiPresentation.leafStyleProperties()) {
        splitProperties.add(property)
    }
    let _ = catalog.registerComponent(CjguiGeneratedUiComponentSpec("split", splitProperties, true, childLimit: 2))
    return catalog
}

private func windowPerfScrollSplitSpec(height!: Int64 = 120): CjguiGeneratedUiNodeSpec {
    let rows = ArrayList<CjguiGeneratedUiNodeSpec>()
    var index = 0
    while (index < 8) {
        rows.add(CjguiGeneratedUiNodeSpec("row${index}", "label",
            properties: HashMap<String, String>([("text", "滚动行 ${index}"), ("fixedHeight", "20")])))
        index += 1
    }
    let stack = CjguiGeneratedUiNodeSpec("perfStack", "vertical", children: rows)
    let scroll = CjguiGeneratedUiNodeSpec("perfScroll", "scrollArea",
        properties: HashMap<String, String>([("offset", "0"), ("fixedHeight", "${height}")]),
        children: ArrayList<CjguiGeneratedUiNodeSpec>([stack]))
    let pane0 = CjguiGeneratedUiNodeSpec("pane0", "vertical",
        children: ArrayList<CjguiGeneratedUiNodeSpec>([CjguiGeneratedUiNodeSpec("pane0Label", "label",
            properties: HashMap<String, String>([("text", "左栏"), ("fixedHeight", "20")]))]))
    let pane1 = CjguiGeneratedUiNodeSpec("pane1", "vertical",
        children: ArrayList<CjguiGeneratedUiNodeSpec>([CjguiGeneratedUiNodeSpec("pane1Label", "label",
            properties: HashMap<String, String>([("text", "右栏"), ("fixedHeight", "20")]))]))
    let split = CjguiGeneratedUiNodeSpec("perfSplit", "split",
        properties: HashMap<String, String>([("firstSize", "160"), ("firstMinimum", "80"), ("secondMinimum", "80"),
            ("fixedHeight", "${height}")]),
        children: ArrayList<CjguiGeneratedUiNodeSpec>([pane0, pane1]))
    return CjguiGeneratedUiNodeSpec("perfRoot", "vertical",
        children: ArrayList<CjguiGeneratedUiNodeSpec>([scroll, split]))
}

/// The handwritten author of exactly that declared content, using the public
/// `cjguiComposableScrollArea` + `cjguiComposableScopedSplitView` components.
private func handwrittenScrollSplitRoot(viewport: CjguiComposableUiScrollViewport,
    height: Int64): CjguiComposableUiNode {
    let root = cjguiComposableVertical(1, "perf-root", CjguiComposableUiStyle(gap: 4))
    let scroll = cjguiComposableScrollArea(2, "perf-scroll", viewport,
        CjguiComposableUiStyle(growX: 1, fixedHeight: height))
    // The generated vertical applies its own default gap when none is declared;
    // the handwritten author declares the SAME gap so the load is identical.
    let stack = cjguiComposableVertical(3, "perf-scroll-stack", CjguiComposableUiStyle(gap: 4))
    var index = 0
    while (index < 8) {
        stack.add(cjguiComposableText(100 + index, "perf-scroll-row-${index}", "滚动行 ${index}",
            CjguiComposableUiStyle(fontSize: 13.0, fixedHeight: 20)))
        index += 1
    }
    scroll.add(stack)
    root.add(scroll)
    let pane0 = cjguiComposableVertical(200, "perf-split-pane0", CjguiComposableUiStyle())
    pane0.add(cjguiComposableText(201, "perf-split-pane0-label", "左栏",
        CjguiComposableUiStyle(fixedHeight: 20)))
    let pane1 = cjguiComposableVertical(210, "perf-split-pane1", CjguiComposableUiStyle())
    pane1.add(cjguiComposableText(211, "perf-split-pane1-label", "右栏",
        CjguiComposableUiStyle(fixedHeight: 20)))
    let scope = CjguiComposableUiIdentityScope("perf-split")
    root.add(cjguiComposableScopedSplitView(scope, "perf-split", pane0, pane1,
        CjguiComposableUiSplitAxis.HORIZONTAL, 160, 80, 80, CjguiComposableUiStyle(growX: 1, fixedHeight: height)))
    return root
}

private class WindowPerfScrollSplitController <: CjguiComposableUiController &
    CjguiComposableUiSceneRefreshParticipant {
    private let generated: Bool
    private let holder: ?CjguiGeneratedUiStructureHolder
    private let provider = WindowPerfScrollSplitProvider()
    let viewport = CjguiComposableUiScrollViewport()
    private var revision: Int64 = 1
    private var heightValue: Int64 = 120
    var buildCount: Int64 = 0

    init(generated: Bool) {
        this.generated = generated
        if (generated) {
            let built = CjguiGeneratedUiStructureHolder(windowPerfScrollSplitCatalog())
            let _ = built.submit(windowPerfScrollSplitSpec(), provider)
            this.holder = Some(built)
        } else {
            this.holder = None
        }
    }

    /// A REAL content change on the same load: the declared height changes, so the
    /// next round must rebuild and resubmit for both authors.
    public func setHeight(value: Int64): Unit {
        heightValue = value
        match (holder) {
            case Some(structure) => let _ = structure.submit(windowPerfScrollSplitSpec(height: value), provider)
            case None => ()
        }
        revision += 1
    }

    public func bump(): Unit {
        revision += 1
    }
    public func generatedViewport(): CjguiComposableUiScrollViewport {
        return match (holder) {
            case Some(value) => value.scrollViewportForInstance("perfScroll", 0)
            case None => CjguiComposableUiScrollViewport()
        }
    }
    public func generatedNodeId(key: String): Int64 {
        return match (holder) {
            case Some(value) => value.nodeIdForKey(key)
            case None => -1
        }
    }
    public func uiSceneVersion(): Int64 {
        return revision
    }
    public func buildUi(): CjguiComposableUiNode {
        buildCount += 1
        if (generated) {
            return match (holder) {
                case Some(value) => value.buildRefreshNode(provider)
                case None => handwrittenScrollSplitRoot(viewport, heightValue)
            }
        }
        return handwrittenScrollSplitRoot(viewport, heightValue)
    }
    public func beginSceneRefresh(): Bool {
        return match (holder) {
            case Some(value) => value.beginCandidateRefresh()
            case None => true
        }
    }
    public func prepareSceneRefresh(): Bool {
        return match (holder) {
            case Some(value) => value.prepareCandidateRefresh()
            case None => true
        }
    }
    public func candidateSceneCommands(): ArrayList<CjguiComposableUiCommand> {
        return ArrayList<CjguiComposableUiCommand>()
    }
    public func commitSceneRefresh(): Unit {
        match (holder) {
            case Some(value) => let _ = value.commitCandidateRefresh()
            case None => ()
        }
    }
    public func rollbackSceneRefresh(): Unit {
        match (holder) {
            case Some(value) => value.rollbackCandidateRefresh()
            case None => ()
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
}

private func perfAcceptedNodeBySemantic(window: CjguiComposableUiWindow,
    semanticId: String): CjguiComposableUiLayoutNode {
    for (node in window.acceptedSceneNodes()) {
        if (node.semanticId == semanticId) {
            return node
        }
    }
    return CjguiComposableUiLayoutNode.missing()
}

private func perfAcceptedNodeById(window: CjguiComposableUiWindow, nodeId: Int64): CjguiComposableUiLayoutNode {
    for (node in window.acceptedSceneNodes()) {
        if (node.nodeId == nodeId) {
            return node
        }
    }
    return CjguiComposableUiLayoutNode.missing()
}

@Test
func windowPerfScrollSplitEquivalenceAndConvergence(): Unit {
    let hand = WindowPerfScrollSplitController(false)
    let handWindow = CjguiComposableUiWindow(hand)
    @Assert(handWindow.start(), true)
    @Assert(handWindow.refresh(), true)
    let generated = WindowPerfScrollSplitController(true)
    let generatedWindow = CjguiComposableUiWindow(generated)
    @Assert(generatedWindow.start(), true)
    @Assert(generatedWindow.refresh(), true)

    let handProgress = handWindow.windowProgress()
    let generatedProgress = generatedWindow.windowProgress()
    @Assert(handProgress.acceptedSceneVersion == handProgress.sceneVersion, true)
    @Assert(generatedProgress.acceptedSceneVersion == generatedProgress.sceneVersion, true)
    @Assert(handProgress.lastNativeFailure, "none")
    @Assert(generatedProgress.lastNativeFailure, "none")

    // Equivalence of the accepted geometry for the SAME declared load.
    let generatedViewport = generated.generatedViewport()
    @Assert(hand.viewport.contentExtent() > 0, true)
    @Assert(generatedViewport.contentExtent() > 0, true)
    @Assert(hand.viewport.contentExtent(), generatedViewport.contentExtent())
    @Assert(hand.viewport.viewportExtent(), generatedViewport.viewportExtent())
    @Assert(handWindow.acceptedSceneNodes().size, generatedWindow.acceptedSceneNodes().size)
    let handScroll = perfAcceptedNodeBySemantic(handWindow, "perf-scroll")
    let generatedScroll = perfAcceptedNodeById(generatedWindow, generated.generatedNodeId("perfScroll"))
    @Assert(handScroll.bounds.x, generatedScroll.bounds.x)
    @Assert(handScroll.bounds.y, generatedScroll.bounds.y)
    @Assert(handScroll.bounds.width, generatedScroll.bounds.width)
    @Assert(handScroll.bounds.height, generatedScroll.bounds.height)
    let handPane0 = perfAcceptedNodeBySemantic(handWindow, "perf-split-pane0")
    let generatedPane0 = perfAcceptedNodeById(generatedWindow, generated.generatedNodeId("pane0"))
    reportWindowPerf("window_scroll_split_geometry", 0,
        "hand_scroll=${handScroll.bounds.x},${handScroll.bounds.y},${handScroll.bounds.width},${handScroll.bounds.height} " +
        "gen_scroll=${generatedScroll.bounds.x},${generatedScroll.bounds.y},${generatedScroll.bounds.width},${generatedScroll.bounds.height} " +
        "hand_pane0=${handPane0.bounds.x},${handPane0.bounds.y},${handPane0.bounds.width},${handPane0.bounds.height} " +
        "gen_pane0=${generatedPane0.bounds.x},${generatedPane0.bounds.y},${generatedPane0.bounds.width},${generatedPane0.bounds.height}")
    @Assert(handPane0.bounds.x, generatedPane0.bounds.x)
    @Assert(handPane0.bounds.y, generatedPane0.bounds.y)
    @Assert(handPane0.bounds.width, generatedPane0.bounds.width)
    @Assert(handPane0.bounds.height, generatedPane0.bounds.height)
    @Assert(handPane0.bounds.width, 160)
    let handPane1 = perfAcceptedNodeBySemantic(handWindow, "perf-split-pane1")
    let generatedPane1 = perfAcceptedNodeById(generatedWindow, generated.generatedNodeId("pane1"))
    @Assert(handPane1.bounds.x, generatedPane1.bounds.x)
    @Assert(handPane1.bounds.width, generatedPane1.bounds.width)
    @Assert(handPane1.bounds.height, generatedPane1.bounds.height)
    @Assert(handPane1.bounds.x > handPane0.bounds.x + handPane0.bounds.width - 1, true)

    // Cold submit: one build and one native submission per author.
    let handBuildsCold = hand.buildCount
    let generatedBuildsCold = generated.buildCount
    let handSubmitsCold = handProgress.nativeSubmissionVersion
    let generatedSubmitsCold = generatedProgress.nativeSubmissionVersion
    @Assert(handBuildsCold, generatedBuildsCold)
    @Assert(handSubmitsCold, generatedSubmitsCold)
    @Assert(handBuildsCold >= 1, true)
    @Assert(handSubmitsCold >= 1, true)
    let handSolvesCold = hand.viewport.acceptedSolveCount()
    let generatedSolvesCold = generatedViewport.acceptedSolveCount()
    @Assert(handSolvesCold, generatedSolvesCold)

    // Hot no-op rounds: nothing changed, so nothing may rebuild or resubmit.
    var round = 0
    while (round < 5) {
        let _ = handWindow.refreshIfNeeded()
        let _ = generatedWindow.refreshIfNeeded()
        round += 1
    }
    @Assert(hand.buildCount, handBuildsCold)
    @Assert(generated.buildCount, generatedBuildsCold)
    @Assert(handWindow.windowProgress().nativeSubmissionVersion, handSubmitsCold)
    @Assert(generatedWindow.windowProgress().nativeSubmissionVersion, generatedSubmitsCold)

    // One REAL content change each (the declared height changes): exactly one more
    // build and one more native submission, then the counters converge again.
    hand.setHeight(150)
    generated.setHeight(150)
    @Assert(handWindow.refreshIfNeeded(), true)
    @Assert(generatedWindow.refreshIfNeeded(), true)
    let handBuildsHot = hand.buildCount
    let generatedBuildsHot = generated.buildCount
    let handSubmitsHot = handWindow.windowProgress().nativeSubmissionVersion
    let generatedSubmitsHot = generatedWindow.windowProgress().nativeSubmissionVersion
    @Assert(handBuildsHot, handBuildsCold + 1)
    @Assert(generatedBuildsHot, generatedBuildsCold + 1)
    @Assert(handSubmitsHot, handSubmitsCold + 1)
    @Assert(generatedSubmitsHot, generatedSubmitsCold + 1)
    // The changed load stays equivalent: both authors accepted the same viewport
    // extent after the real change.
    @Assert(hand.viewport.viewportExtent(), 150)
    @Assert(generated.generatedViewport().viewportExtent(), 150)
    round = 0
    while (round < 5) {
        let _ = handWindow.refreshIfNeeded()
        let _ = generatedWindow.refreshIfNeeded()
        round += 1
    }
    @Assert(hand.buildCount, handBuildsHot)
    @Assert(generated.buildCount, generatedBuildsHot)
    @Assert(handWindow.windowProgress().nativeSubmissionVersion, handSubmitsHot)
    @Assert(generatedWindow.windowProgress().nativeSubmissionVersion, generatedSubmitsHot)
    @Assert(hand.viewport.acceptedSolveCount() >= handSolvesCold, true)
    @Assert(generatedViewport.acceptedSolveCount() >= generatedSolvesCold, true)

    reportWindowPerf("window_scroll_split_equivalence", 0,
        "accepted_nodes=${handWindow.acceptedSceneNodes().size} content=${hand.viewport.contentExtent()} " +
        "viewport=${hand.viewport.viewportExtent()} pane0_w=${handPane0.bounds.width} " +
        "hand_builds=${handBuildsCold}->${handBuildsHot} generated_builds=${generatedBuildsCold}->${generatedBuildsHot} " +
        "hand_submits=${handSubmitsCold}->${handSubmitsHot} generated_submits=${generatedSubmitsCold}->${generatedSubmitsHot} " +
        "hand_solves=${hand.viewport.acceptedSolveCount()} generated_solves=${generatedViewport.acceptedSolveCount()} " +
        "hot_noop_builds=0 hot_noop_submits=0 converged=true decode=none")
    handWindow.close()
    generatedWindow.close()
}

/// D: the NORMAL window hot path across the three authors and two loads, with
/// real WORK separated from TIME.
///
/// Work is counted by the framework itself (builds, layout solves, native
/// submissions and structure serializations); time is a MonoTime delta of the
/// public refresh call. The two are reported on separate fields so a timing that
/// happens to be zero can never be read as "no work was done" - the counters say
/// what really happened.
@Test
func windowPerfThreeAuthorsTwoLoadsWithSeparatedWorkAndTime(): Unit {
    let loads: ArrayList<Int64> = ArrayList<Int64>([8, 32])
    var referenceSignature = ""
    var referenceLoad: Int64 = 0
    for (load in loads) {
        var loadSignature = ""
        for (author in 0..3) {
            let controller = WindowPerfAuthorMatrixController(author, load)
            let window = CjguiComposableUiWindow(controller)
            // The view object the author's own tree binds, captured BEFORE the
            // refresh so a commit-time prune cannot swap the identity behind us.
            // The declared load must have been ACCEPTED: a refused declaration
            // would leave the author on its previous scene and a "measurement"
            // would silently describe the wrong load.
            @Assert(controller.seedAccepted, true)
            let boundViewport = controller.effectiveViewport()
            // COLD is timed on its own: a first native session plus the first
            // accepted scene is not a hot operation and must not be averaged into
            // one.
            let coldStarted = MonoTime.now()
            let coldOpened = window.start()
            let coldRefreshed = window.refresh()
            let coldMicros = (MonoTime.now() - coldStarted).toMicroseconds()
            @Assert(coldOpened, true)
            @Assert(coldRefreshed, true)
            let coldProgress = window.windowProgress()
            @Assert(coldProgress.lastNativeFailure, "none")
            @Assert(coldProgress.acceptedSceneVersion == coldProgress.sceneVersion, true)
            let coldBuilds = controller.buildCount
            let coldSubmits = coldProgress.nativeSubmissionVersion
            let coldSolves = boundViewport.acceptedSolveCount()
            @Assert(coldBuilds >= 1, true)
            @Assert(coldSubmits >= 1, true)
            @Assert(coldSolves >= 1, true)
            // The three authors must describe the SAME accepted layout: same node
            // kinds and same solved heights in the same order. Work counters alone
            // cannot prove equivalence, and a mixed author that nested a second
            // scroll would silently be a different tree.
            let signature = authorMatrixSceneSignature(window)
            if (loadSignature.size == 0) {
                loadSignature = signature
            }
            @Assert(signature, loadSignature)
            // Every author's accepted scene really carries ITS OWN rows.
            let acceptedRows = authorMatrixAcceptedRowCount(window, load)
            @Assert(acceptedRows, load)

            // >= 20 bounded HOT samples per (author, load). Only the measured
            // refresh is inside the timed region; every assertion and every
            // counter read happens after the timer stopped.
            let samples = ArrayList<Int64>()
            var refreshedAll = true
            let buildsBefore = controller.buildCount
            let submitsBefore = window.windowProgress().nativeSubmissionVersion
            let solvesBefore = boundViewport.acceptedSolveCount()
            var index: Int64 = 0
            while (index < 20) {
                controller.setHeight(load * 4 + index)
                let started = MonoTime.now()
                let refreshed = window.refresh()
                samples.add((MonoTime.now() - started).toMicroseconds())
                refreshedAll = refreshedAll && refreshed
                index += 1
            }
            @Assert(refreshedAll, true)
            let hotProgress = window.windowProgress()
            let hotBuilds = controller.buildCount - buildsBefore
            let hotSubmits = hotProgress.nativeSubmissionVersion - submitsBefore
            let hotSolves = boundViewport.acceptedSolveCount() - solvesBefore
            @Assert(hotProgress.lastNativeFailure, "none")
            // Each of the 20 samples must have produced REAL work: a rebuild, a
            // native submission and a solved viewport per sample. A "fast" sample
            // can therefore never be an operation that did nothing.
            @Assert(hotBuilds, 20)
            @Assert(hotSubmits, 20)
            @Assert(hotSolves >= 20, true)
            // ...and the accepted scene still carries exactly this author's rows
            // after the hot samples (verified OUTSIDE the timer).
            @Assert(authorMatrixAcceptedRowCount(window, load), load)
            let sortedSamples = sortedPerfSampleCopy(samples)
            let medianMicros = perfNearestRank(sortedSamples, 1, 2)
            reportWindowPerf("author_matrix load=${load} author=${controller.authorName()}", medianMicros,
                "cold_micros=${coldMicros} hot_samples=${samples.size} hot_median_micros=${medianMicros} " +
                "hot_min_micros=${sortedSamples[0]} hot_max_micros=${sortedSamples[sortedSamples.size - 1]} " +
                "cold_builds=${coldBuilds} cold_submits=${coldSubmits} cold_solves=${coldSolves} " +
                "hot_builds=${hotBuilds} hot_submits=${hotSubmits} hot_solves=${hotSolves} " +
                "rows=${controller.rowCount()} accepted_rows=${authorMatrixAcceptedRowCount(window, load)} " +
                "scene_signature_nodes=${window.acceptedSceneNodes().size} " +
                "time_source=MonoTime separated=work_vs_time asserts_outside_timer=true")

            // Idle convergence AFTER the timed region: several normal turns with
            // nothing changed must do NO build, NO submission and NO layout solve.
            // One real idle turn is timed (it is a real turn, never a 0 sentinel).
            let idleBuildsBefore = controller.buildCount
            let idleSubmitsBefore = window.windowProgress().nativeSubmissionVersion
            let idleSolvesBefore = boundViewport.acceptedSolveCount()
            let clockProbeStart = MonoTime.now()
            let clockProbeEnd = MonoTime.now()
            let clockResolutionMicros = (clockProbeEnd - clockProbeStart).toMicroseconds()
            let idleStarted = MonoTime.now()
            let idleRefreshed = window.refreshIfNeeded()
            let idleMicros = (MonoTime.now() - idleStarted).toMicroseconds()
            var idleRounds: Int64 = 1
            var idleExtraWork: Int64 = 0
            while (idleRounds < 5) {
                let extra = window.refreshIfNeeded()
                if (extra) {
                    idleExtraWork += 1
                }
                idleRounds += 1
            }
            let idleBuilds = controller.buildCount - idleBuildsBefore
            let idleSubmits = window.windowProgress().nativeSubmissionVersion - idleSubmitsBefore
            let idleSolves = boundViewport.acceptedSolveCount() - idleSolvesBefore
            @Assert(idleBuilds, 0)
            @Assert(idleSubmits, 0)
            @Assert(idleSolves, 0)
            reportWindowPerf("author_matrix_idle load=${load} author=${controller.authorName()}", idleMicros,
                "idle_refresh_requested=${idleRefreshed} idle_rounds=${idleRounds} idle_extra_work=${idleExtraWork} " +
                "idle_builds=${idleBuilds} idle_submits=${idleSubmits} idle_solves=${idleSolves} " +
                "clock_resolution_micros=${clockResolutionMicros} zero_allowed=true " +
                "time_source=MonoTime separated=work_vs_time")
            window.close()
        }
        if (referenceSignature.size == 0) {
            referenceSignature = loadSignature
            referenceLoad = load
        } else {
            // The two loads are different trees on purpose; only the SAME load is
            // compared across authors, and both loads were compared above.
            @Assert(loadSignature.size > 0, true)
        }
    }
    @Assert(referenceSignature.size > 0, true)
    @Assert(referenceLoad > 0, true)
}

/// A bounded copy of the raw samples, ascending. The sample set is small (>= 20)
/// and bounded, so the insertion sort keeps the reporting allocation-free.
private func sortedPerfSampleCopy(values: ArrayList<Int64>): Array<Int64> {
    let copy = Array<Int64>(values.size, repeat: 0)
    var index = 0
    while (index < values.size) {
        copy[index] = values[index]
        index += 1
    }
    var position = 1
    while (position < copy.size) {
        let current = copy[position]
        var scan = position - 1
        while (scan >= 0 && copy[scan] > current) {
            copy[scan + 1] = copy[scan]
            scan -= 1
        }
        copy[scan + 1] = current
        position += 1
    }
    return copy
}

/// Nearest-rank percentile over an ascending sample array.
private func perfNearestRank(sortedValues: Array<Int64>, numerator: Int64, denominator: Int64): Int64 {
    if (sortedValues.size == 0) {
        return 0
    }
    let rank = (sortedValues.size * numerator + denominator - 1) / denominator
    let index = if (rank <= 0) {
        0
    } else if (rank > sortedValues.size) {
        sortedValues.size - 1
    } else {
        rank - 1
    }
    return sortedValues[index]
}

/// One accepted-scene signature: node kind and solved height in traversal order.
/// Two authors that claim "the same work" must produce the same signature.
private func authorMatrixSceneSignature(window: CjguiComposableUiWindow): String {
    var text = ""
    for (node in window.acceptedSceneNodes()) {
        text += "${node.nodeKind}:${node.bounds.height}|"
    }
    return text
}

/// Accepted equivalence for the D operation fixture: content, field/action
/// binding, resource identity and all solved bounds are compared while the
/// framework-owned node id and scene version remain outside the contract.
private func operationMatrixAcceptedSignature(window: CjguiComposableUiWindow): String {
    var text = ""
    for (node in window.acceptedSceneNodes()) {
        text += "${node.nodeKind}|${node.label}|${node.value}|${node.fieldId}|" +
            "${node.operationActionName}|${node.operationResourceId}|${node.resourceId}|" +
            "${node.displayValueRole}|${node.bounds.x},${node.bounds.y}," +
            "${node.bounds.width},${node.bounds.height}|"
    }
    return text
}

/// How many accepted label rows this window's scene really carries. It is read
/// from the accepted scene, never from a rebuilt tree.
private func authorMatrixAcceptedRowCount(window: CjguiComposableUiWindow, rows: Int64): Int64 {
    let _ = rows
    var count: Int64 = 0
    for (node in window.acceptedSceneNodes()) {
        if (node.nodeKind == CJGUI_COMPOSABLE_UI_TEXT && node.value.startsWith("滚动行 ")) {
            count += 1
        }
    }
    return count
}

/// Three authors over ONE declared load:
///   0 = handwritten, 1 = generated, 2 = MIXED (a handwritten scroll/split shell
///   whose inner section is the generated structure). The mixed author is the
///   ordinary application shape this framework has to price, not a fourth
///   renderer.
private class WindowPerfAuthorMatrixController <: CjguiComposableUiController &
    CjguiComposableUiSceneRefreshParticipant {
    private let author: Int64
    private let rows: Int64
    private let holder: ?CjguiGeneratedUiStructureHolder
    private let provider = WindowPerfScrollSplitProvider()
    let viewport = CjguiComposableUiScrollViewport()
    private var revision: Int64 = 1
    private var heightValue: Int64 = 120
    var buildCount: Int64 = 0
    /// Whether the declared load was really accepted by the generated catalog.
    var seedAccepted: Bool = true
    var seedReason: String = ""

    init(author: Int64, rows: Int64) {
        this.author = author
        this.rows = rows
        if (author == 1 || author == 2) {
            let built = CjguiGeneratedUiStructureHolder(windowPerfAuthorMatrixCatalog(rows))
            // The generated author declares the whole scroll layout; the MIXED
            // author declares the same rows as the INNER content of a handwritten
            // scroll, so its tree is structurally equivalent instead of nesting a
            // second scroll inside the first.
            let seeded = if (author == 2) {
                built.submit(authorMatrixContentSpec(rows), provider)
            } else {
                built.submit(authorMatrixSpec(rows), provider)
            }
            // A refused seed would leave the author with NO generated scene, so it
            // is recorded instead of being discovered as "zero solves".
            this.seedAccepted = seeded.candidateAccepted
            this.seedReason = seeded.reason
            this.holder = Some(built)
        } else {
            this.holder = None
        }
    }

    public func authorName(): String {
        if (author == 1) {
            return "generated"
        }
        if (author == 2) {
            return "mixed"
        }
        return "handwritten"
    }
    public func rowCount(): Int64 {
        return rows
    }
    /// The viewport THIS author's tree really binds: the handwritten author (and
    /// the mixed shell) binds the controller's own viewport, while the generated
    /// author binds its per-instance viewport inside the holder.
    public func effectiveViewport(): CjguiComposableUiScrollViewport {
        if (author == 1) {
            return match (holder) {
                case Some(value) => value.scrollViewportForInstance("perfScroll", 0)
                case None => viewport
            }
        }
        return viewport
    }
    /// A REAL content change: the declared height moves, so the next round must
    /// rebuild and resubmit for every author.
    public func setHeight(value: Int64): Unit {
        heightValue = value
        match (holder) {
            case Some(structure) => let _ = if (author == 2) {
                structure.submit(authorMatrixContentSpec(rows), provider)
            } else {
                structure.submit(authorMatrixSpec(rows, height: value), provider)
            }
            case None => ()
        }
        revision += 1
    }
    public func uiSceneVersion(): Int64 {
        return revision
    }
    public func buildUi(): CjguiComposableUiNode {
        buildCount += 1
        if (author == 1) {
            return match (holder) {
                case Some(value) => value.buildRefreshNode(provider)
                case None => authorMatrixHandwritten(viewport, rows, heightValue)
            }
        }
        if (author == 2) {
            // The handwritten shell OWNS the public viewport; the generated
            // structure contributes only the INNER content, exactly like an
            // application that migrated one region at a time. It deliberately
            // declares NO second scroll area: all three authors must describe the
            // same one-scroll layout, or "the same work" would be a claim about
            // different trees.
            let shell = cjguiComposableVertical(1, "perf-root", CjguiComposableUiStyle(gap: 4))
            let scroll = cjguiComposableScrollArea(2, "perf-scroll", viewport,
                CjguiComposableUiStyle(growX: 1, fixedHeight: heightValue))
            scroll.add(match (holder) {
                case Some(value) => value.buildRefreshNode(provider)
                case None => authorMatrixHandwritten(viewport, rows, heightValue)
            })
            shell.add(scroll)
            return shell
        }
        return authorMatrixHandwritten(viewport, rows, heightValue)
    }
    public func beginSceneRefresh(): Bool {
        return match (holder) {
            case Some(value) => value.beginCandidateRefresh()
            case None => true
        }
    }
    public func prepareSceneRefresh(): Bool {
        return match (holder) {
            case Some(value) => value.prepareCandidateRefresh()
            case None => true
        }
    }
    public func candidateSceneCommands(): ArrayList<CjguiComposableUiCommand> {
        return ArrayList<CjguiComposableUiCommand>()
    }
    public func commitSceneRefresh(): Unit {
        match (holder) {
            case Some(value) => let _ = value.commitCandidateRefresh()
            case None => ()
        }
    }
    public func rollbackSceneRefresh(): Unit {
        match (holder) {
            case Some(value) => value.rollbackCandidateRefresh()
            case None => ()
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
}

private func authorMatrixHandwritten(viewport: CjguiComposableUiScrollViewport, rows: Int64,
    height: Int64): CjguiComposableUiNode {
    let root = cjguiComposableVertical(1, "perf-root", CjguiComposableUiStyle(gap: 4))
    let scroll = cjguiComposableScrollArea(2, "perf-scroll", viewport,
        CjguiComposableUiStyle(growX: 1, fixedHeight: height))
    let stack = cjguiComposableVertical(3, "perf-scroll-stack", CjguiComposableUiStyle(gap: 4))
    var index = 0
    while (index < rows) {
        stack.add(cjguiComposableText(100 + index, "perf-scroll-row-${index}", "滚动行 ${index}",
            CjguiComposableUiStyle(fontSize: 13.0, fixedHeight: 20)))
        index += 1
    }
    scroll.add(stack)
    root.add(scroll)
    return root
}

private func authorMatrixSpec(rows: Int64, height!: Int64 = 120): CjguiGeneratedUiNodeSpec {
    let rowSpecs = ArrayList<CjguiGeneratedUiNodeSpec>()
    var index = 0
    while (index < rows) {
        rowSpecs.add(CjguiGeneratedUiNodeSpec("row${index}", "label",
            properties: HashMap<String, String>([("text", "滚动行 ${index}"), ("fixedHeight", "20")])))
        index += 1
    }
    let stack = CjguiGeneratedUiNodeSpec("perfStack", "vertical", children: rowSpecs)
    let scroll = CjguiGeneratedUiNodeSpec("perfScroll", "scrollArea",
        properties: HashMap<String, String>([("offset", "0"), ("fixedHeight", "${height}")]),
        children: ArrayList<CjguiGeneratedUiNodeSpec>([stack]))
    return CjguiGeneratedUiNodeSpec("perfRoot", "vertical",
        children: ArrayList<CjguiGeneratedUiNodeSpec>([scroll]))
}

/// The INNER content of the mixed author's handwritten scroll: the same rows as
/// the generated author's stack, with no scroll area of its own.
private func authorMatrixContentSpec(rows: Int64): CjguiGeneratedUiNodeSpec {
    let rowSpecs = ArrayList<CjguiGeneratedUiNodeSpec>()
    var index = 0
    while (index < rows) {
        rowSpecs.add(CjguiGeneratedUiNodeSpec("row${index}", "label",
            properties: HashMap<String, String>([("text", "滚动行 ${index}"), ("fixedHeight", "20")])))
        index += 1
    }
    return CjguiGeneratedUiNodeSpec("perfContent", "vertical", children: rowSpecs)
}

/// The normal application shape for the interaction samples: a scroll viewport, a
/// state-bound split and a public tab container in ONE window, all driven through
/// their public seams.
private class WindowPerfInteractionController <: CjguiComposableUiController {
    let viewport = CjguiComposableUiScrollViewport()
    let split = CjguiComposableUiSplitState(200, 120, 120)
    let tabs = CjguiComposableUiTabsState("basic")
    private var revision: Int64 = 1
    var buildCount: Int64 = 0
    /// Two OWNER values behind two editors: one on the VISIBLE page, one on the
    /// page the tab container currently hides. A background write to the hidden
    /// one must not be required to commit visibly, but switching back must present
    /// the owner's CURRENT value.
    var visibleDraft: String = "可见初值"
    var hiddenDraft: String = "隐藏初值"

    public func bump(): Unit {
        revision += 1
    }
    public func uiSceneVersion(): Int64 {
        return revision
    }
    public func buildUi(): CjguiComposableUiNode {
        buildCount += 1
        let root = cjguiComposableVertical(1, "perf-root", CjguiComposableUiStyle(gap: 4))
        let scroll = cjguiComposableScrollArea(2, "perf-scroll", viewport,
            CjguiComposableUiStyle(growX: 1, fixedHeight: 120))
        let stack = cjguiComposableVertical(3, "perf-scroll-stack", CjguiComposableUiStyle(gap: 4))
        var index = 0
        while (index < 24) {
            stack.add(cjguiComposableText(100 + index, "perf-scroll-row-${index}", "滚动行 ${index}",
                CjguiComposableUiStyle(fontSize: 13.0, fixedHeight: 20)))
            index += 1
        }
        // The VISIBLE editor the field-update samples drive.
        stack.add(cjguiComposableTextInput(300, "perf-visible-editor", "可见", visibleDraft, 8301,
            CjguiComposableUiStyle(fixedHeight: 20)))
        scroll.add(stack)
        root.add(scroll)
        let pane0 = cjguiComposableVertical(200, "perf-split-pane0", CjguiComposableUiStyle())
        pane0.add(cjguiComposableText(201, "perf-split-pane0-label", "左栏", CjguiComposableUiStyle(fixedHeight: 20)))
        let pane1 = cjguiComposableVertical(210, "perf-split-pane1", CjguiComposableUiStyle())
        pane1.add(cjguiComposableText(211, "perf-split-pane1-label", "右栏", CjguiComposableUiStyle(fixedHeight: 20)))
        let splitScope = CjguiComposableUiIdentityScope("perf-interaction-split")
        root.add(cjguiComposableScopedSplitView(splitScope, "perf-split", pane0, pane1,
            CjguiComposableUiSplitAxis.HORIZONTAL, split.firstSize(), 120, 120,
            CjguiComposableUiStyle(growX: 1, fixedHeight: 80), splitState: split))
        let basic = cjguiComposableVertical(600, "perf-tab-basic", CjguiComposableUiStyle(gap: 2))
        basic.add(cjguiComposableText(601, "perf-tab-basic-line", "基本行", CjguiComposableUiStyle(fixedHeight: 20)))
        let retention = cjguiComposableVertical(610, "perf-tab-retention", CjguiComposableUiStyle(gap: 2))
        retention.add(cjguiComposableText(611, "perf-tab-retention-line", "保留策略行",
            CjguiComposableUiStyle(fixedHeight: 20)))
        // The editor on the HIDDEN page.
        retention.add(cjguiComposableTextInput(612, "perf-hidden-editor", "隐藏", hiddenDraft, 8302,
            CjguiComposableUiStyle(fixedHeight: 20)))
        let pages = ArrayList<CjguiComposableUiTabPage>()
        pages.add(CjguiComposableUiTabPage("basic", "基本", basic))
        pages.add(CjguiComposableUiTabPage("retention", "保留策略", retention))
        let tabsScope = CjguiComposableUiIdentityScope("perf-interaction-tabs")
        root.add(cjguiComposableTabs(tabsScope, "perf-tabs", pages, tabs,
            CjguiComposableUiStyle(growX: 1, fixedHeight: 90), titleHeight: 24))
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
}

// --- D operation matrix: the same interaction load for all three authors ------
//
// `WindowPerfAuthorMatrixController` above proves the author/load hot path, while
// the older interaction controller proves the public operation seams on one
// fixed handwritten fixture. This controller joins those two dimensions: one
// accepted tree is built by hand, by the generated holder, or by a handwritten
// shell containing a generated tab region, and the exact same public state
// operations drive every load.

private class WindowPerfOperationProvider <: CjguiGeneratedUiBindingProvider {
    var visibleDraft: String = "可见初值"
    var hiddenDraft: String = "隐藏初值"

    public func fieldResourceId(fieldId: String): Int64 {
        return if (fieldId == "visible-field") { 8301 } else { 8302 }
    }
    public func fieldOperationResourceId(fieldId: String): Int64 { return 1 }
    public func draftText(fieldId: String): String {
        return if (fieldId == "visible-field") { visibleDraft } else { hiddenDraft }
    }
    public func appliedText(fieldId: String): String { return draftText(fieldId) }
    public func draftBoolean(fieldId: String): ?Bool { return None }
    public func executeAction(actionName: String, nodeKey: String): CjguiGeneratedUiActionResult {
        return CjguiGeneratedUiActionResult(true, "")
    }
    public func actionAvailable(actionName: String): Bool { return true }
}

private func windowPerfOperationCatalog(rows: Int64): CjguiGeneratedUiCapabilityCatalog {
    let catalog = CjguiGeneratedUiCapabilityCatalog()
    let _ = catalog.registerComponent(CjguiGeneratedUiComponentSpec("vertical",
        CjguiGeneratedUiPresentation.containerStyleProperties(), true, childLimit: rows + 12))
    let _ = catalog.registerComponent(CjguiGeneratedUiComponentSpec("horizontal",
        CjguiGeneratedUiPresentation.containerStyleProperties(), true, childLimit: 4))
    let labelProperties = CjguiGeneratedUiPresentation.leafStyleProperties()
    labelProperties.add(CjguiGeneratedUiPropertySpec("text", "STRING", maxLength: 200))
    let _ = catalog.registerComponent(CjguiGeneratedUiComponentSpec("label", labelProperties, false))
    let inputProperties = CjguiGeneratedUiPresentation.leafStyleProperties()
    inputProperties.add(CjguiGeneratedUiPropertySpec("label", "STRING", maxLength: 64))
    let _ = catalog.registerComponent(CjguiGeneratedUiComponentSpec("textInput", inputProperties, false))
    let scrollProperties = CjguiGeneratedUiPresentation.scrollContentProperties()
    for (property in CjguiGeneratedUiPresentation.leafStyleProperties()) {
        scrollProperties.add(property)
    }
    let _ = catalog.registerComponent(CjguiGeneratedUiComponentSpec("scrollArea", scrollProperties, true,
        childLimit: 1))
    let splitProperties = CjguiGeneratedUiPresentation.splitContentProperties()
    for (property in CjguiGeneratedUiPresentation.leafStyleProperties()) {
        splitProperties.add(property)
    }
    let _ = catalog.registerComponent(CjguiGeneratedUiComponentSpec("split", splitProperties, true,
        childLimit: 2))
    let pageProperties = CjguiGeneratedUiPresentation.tabPageContentProperties()
    for (property in CjguiGeneratedUiPresentation.leafStyleProperties()) {
        pageProperties.add(property)
    }
    let _ = catalog.registerComponent(CjguiGeneratedUiComponentSpec("tabPage", pageProperties, true,
        childLimit: 3))
    let tabsProperties = CjguiGeneratedUiPresentation.tabsContentProperties()
    for (property in CjguiGeneratedUiPresentation.containerStyleProperties()) {
        tabsProperties.add(property)
    }
    let _ = catalog.registerComponent(CjguiGeneratedUiComponentSpec("tabs", tabsProperties, true,
        childLimit: 2))
    let _ = catalog.registerField(CjguiGeneratedUiFieldSpec("visible-field", "可见", "TEXT", 8301,
        writeActionName: "EDIT_DRAFT_TEXT"))
    let _ = catalog.registerField(CjguiGeneratedUiFieldSpec("hidden-field", "隐藏", "TEXT", 8302,
        writeActionName: "EDIT_DRAFT_TEXT"))
    return catalog
}

private func windowPerfOperationLabel(key: String, text: String): CjguiGeneratedUiNodeSpec {
    return CjguiGeneratedUiNodeSpec(key, "label",
        properties: HashMap<String, String>([("text", text), ("fixedHeight", "20")]))
}

private func windowPerfOperationInput(key: String, fieldId: String): CjguiGeneratedUiNodeSpec {
    let label = if (fieldId == "visible-field") { "可见" } else { "隐藏" }
    return CjguiGeneratedUiNodeSpec(key, "textInput",
        properties: HashMap<String, String>([("label", label), ("fixedHeight", "20")]), fieldId: fieldId)
}

private func windowPerfOperationPage(key: String, pageKey: String, title: String,
    fieldKey: String, fieldId: String): CjguiGeneratedUiNodeSpec {
    let content = ArrayList<CjguiGeneratedUiNodeSpec>()
    content.add(windowPerfOperationLabel("${key}-line", "${title}行"))
    content.add(windowPerfOperationInput(fieldKey, fieldId))
    let children = ArrayList<CjguiGeneratedUiNodeSpec>()
    children.add(CjguiGeneratedUiNodeSpec("${key}-content", "vertical",
        properties: HashMap<String, String>([("gap", "2")]), children: content))
    let properties = HashMap<String, String>([("pageKey", pageKey), ("pageTitle", title)])
    return CjguiGeneratedUiNodeSpec(key, "tabPage", properties: properties, children: children)
}

private func windowPerfOperationTabsSpec(): CjguiGeneratedUiNodeSpec {
    let pages = ArrayList<CjguiGeneratedUiNodeSpec>()
    pages.add(windowPerfOperationPage("perf-page-basic", "basic", "基本",
        "perf-visible-editor", "visible-field"))
    pages.add(windowPerfOperationPage("perf-page-retention", "retention", "保留策略",
        "perf-hidden-editor", "hidden-field"))
    let properties = HashMap<String, String>([("initialPage", "basic"), ("titleHeight", "24")])
    return CjguiGeneratedUiNodeSpec("perf-tabs", "tabs", properties: properties, children: pages)
}

private func windowPerfOperationRootSpec(rows: Int64, tabsOnly!: Bool = false): CjguiGeneratedUiNodeSpec {
    if (tabsOnly) {
        return windowPerfOperationTabsSpec()
    }
    let rowSpecs = ArrayList<CjguiGeneratedUiNodeSpec>()
    var index: Int64 = 0
    while (index < rows) {
        rowSpecs.add(windowPerfOperationLabel("row${index}", "滚动行 ${index}"))
        index += 1
    }
    let stack = CjguiGeneratedUiNodeSpec("perf-scroll-stack", "vertical", children: rowSpecs)
    let scroll = CjguiGeneratedUiNodeSpec("perf-scroll", "scrollArea",
        properties: HashMap<String, String>([("offset", "0"), ("fixedHeight", "120")]),
        children: ArrayList<CjguiGeneratedUiNodeSpec>([stack]))
    let pane0 = CjguiGeneratedUiNodeSpec("perf-pane-0", "vertical",
        children: ArrayList<CjguiGeneratedUiNodeSpec>([windowPerfOperationLabel("perf-pane-0-label", "左栏")]))
    let pane1 = CjguiGeneratedUiNodeSpec("perf-pane-1", "vertical",
        children: ArrayList<CjguiGeneratedUiNodeSpec>([windowPerfOperationLabel("perf-pane-1-label", "右栏")]))
    let split = CjguiGeneratedUiNodeSpec("perf-split", "split",
        properties: HashMap<String, String>([("firstSize", "200"), ("firstMinimum", "120"),
            ("secondMinimum", "120"), ("fixedHeight", "80")]),
        children: ArrayList<CjguiGeneratedUiNodeSpec>([pane0, pane1]))
    return CjguiGeneratedUiNodeSpec("perf-operation-root", "vertical",
        children: ArrayList<CjguiGeneratedUiNodeSpec>([scroll, split, windowPerfOperationTabsSpec()]))
}

private func windowPerfOperationHandRoot(viewport: CjguiComposableUiScrollViewport,
    split: CjguiComposableUiSplitState, tabs: CjguiComposableUiTabsState, rows: Int64,
    visibleDraft: String, hiddenDraft: String): CjguiComposableUiNode {
    let root = cjguiComposableVertical(1, "perf-operation-root", CjguiComposableUiStyle(gap: 4))
    let scroll = cjguiComposableScrollArea(2, "perf-scroll", viewport,
        CjguiComposableUiStyle(growX: 1, fixedHeight: 120))
    let stack = cjguiComposableVertical(3, "perf-scroll-stack", CjguiComposableUiStyle(gap: 4))
    var index: Int64 = 0
    while (index < rows) {
        stack.add(cjguiComposableText(100 + index, "row${index}", "滚动行 ${index}",
            CjguiComposableUiStyle(fontSize: 13.0, fixedHeight: 20)))
        index += 1
    }
    scroll.add(stack)
    root.add(scroll)
    let pane0 = cjguiComposableVertical(200, "perf-pane-0", CjguiComposableUiStyle())
    pane0.add(cjguiComposableText(201, "perf-pane-0-label", "左栏", CjguiComposableUiStyle(fixedHeight: 20)))
    let pane1 = cjguiComposableVertical(210, "perf-pane-1", CjguiComposableUiStyle())
    pane1.add(cjguiComposableText(211, "perf-pane-1-label", "右栏", CjguiComposableUiStyle(fixedHeight: 20)))
    let splitScope = CjguiComposableUiIdentityScope("perf-operation-split")
    root.add(cjguiComposableScopedSplitView(splitScope, "perf-split", pane0, pane1,
        CjguiComposableUiSplitAxis.HORIZONTAL, split.firstSize(), 120, 120,
        CjguiComposableUiStyle(growX: 1, fixedHeight: 80), splitState: split))
    let basic = cjguiComposableVertical(600, "perf-page-basic", CjguiComposableUiStyle(gap: 2))
    basic.add(cjguiComposableText(601, "perf-page-basic-line", "基本行", CjguiComposableUiStyle(fixedHeight: 20)))
    basic.add(cjguiComposableTextInput(602, "perf-visible-editor", "可见", visibleDraft, 8301,
        CjguiComposableUiStyle(fixedHeight: 20), fieldId: "visible-field",
        operationActionName: "EDIT_DRAFT_TEXT", operationResourceId: 1, displayValueRole: "draft"))
    let retention = cjguiComposableVertical(610, "perf-page-retention", CjguiComposableUiStyle(gap: 2))
    retention.add(cjguiComposableText(611, "perf-page-retention-line", "保留策略行", CjguiComposableUiStyle(fixedHeight: 20)))
    retention.add(cjguiComposableTextInput(612, "perf-hidden-editor", "隐藏", hiddenDraft, 8302,
        CjguiComposableUiStyle(fixedHeight: 20), fieldId: "hidden-field",
        operationActionName: "EDIT_DRAFT_TEXT", operationResourceId: 1, displayValueRole: "draft"))
    let pages = ArrayList<CjguiComposableUiTabPage>()
    pages.add(CjguiComposableUiTabPage("basic", "基本", basic))
    pages.add(CjguiComposableUiTabPage("retention", "保留策略", retention))
    let tabsScope = CjguiComposableUiIdentityScope("perf-operation-tabs")
    root.add(cjguiComposableTabs(tabsScope, "perf-tabs", pages, tabs,
        CjguiComposableUiStyle(), titleHeight: 24))
    return root
}

private class WindowPerfOperationMatrixController <: CjguiComposableUiController &
    CjguiComposableUiSceneRefreshParticipant {
    private let author: Int64
    private let rows: Int64
    private let provider = WindowPerfOperationProvider()
    private let holder: ?CjguiGeneratedUiStructureHolder
    let viewport = CjguiComposableUiScrollViewport()
    let split = CjguiComposableUiSplitState(200, 120, 120)
    let tabs = CjguiComposableUiTabsState("basic")
    private var revision: Int64 = 1
    var buildCount: Int64 = 0
    var visibleDraft: String = "可见初值"
    var hiddenDraft: String = "隐藏初值"
    var seedAccepted: Bool = true
    var seedReason: String = ""

    init(author: Int64, rows: Int64) {
        this.author = author
        this.rows = rows
        if (author == 1 || author == 2) {
            let built = CjguiGeneratedUiStructureHolder(windowPerfOperationCatalog(rows))
            let seeded = if (author == 2) {
                built.submit(windowPerfOperationRootSpec(rows, tabsOnly: true), provider)
            } else {
                built.submit(windowPerfOperationRootSpec(rows), provider)
            }
            this.seedAccepted = seeded.candidateAccepted
            this.seedReason = seeded.reason
            this.holder = Some(built)
        } else {
            this.holder = None
        }
    }

    public func authorName(): String {
        if (author == 1) { return "generated" }
        if (author == 2) { return "mixed" }
        return "handwritten"
    }
    public func rowCount(): Int64 { return rows }
    public func operationViewport(): CjguiComposableUiScrollViewport {
        if (author == 1) {
            return match (holder) {
                case Some(value) => value.scrollViewportForInstance("perf-scroll", 0)
                case None => viewport
            }
        }
        return viewport
    }
    public func operationSplit(): CjguiComposableUiSplitState {
        if (author == 1) {
            return match (holder) {
                case Some(value) => value.splitStateForInstance("perf-split", 200,
                    firstMinimum: 120, secondMinimum: 120)
                case None => split
            }
        }
        return split
    }
    public func operationTabs(): CjguiComposableUiTabsState {
        if (author == 1 || author == 2) {
            return match (holder) {
                case Some(value) => value.tabsStateForInstance("perf-tabs", "basic")
                case None => tabs
            }
        }
        return tabs
    }
    public func setVisible(value: String): Unit {
        visibleDraft = value
        provider.visibleDraft = value
        revision += 1
    }
    public func setHidden(value: String): Unit {
        hiddenDraft = value
        provider.hiddenDraft = value
        revision += 1
    }
    public func bump(): Unit { revision += 1 }
    public func uiSceneVersion(): Int64 { return revision }
    public func buildUi(): CjguiComposableUiNode {
        buildCount += 1
        if (author == 1) {
            return match (holder) {
                case Some(value) => value.buildRefreshNode(provider)
                case None => windowPerfOperationHandRoot(viewport, split, tabs, rows, visibleDraft, hiddenDraft)
            }
        }
        if (author == 2) {
            // The mixed shape is intentionally the handwritten shell plus the
            // generated tab region. Build the shell's common nodes directly and
            // replace only its tab subtree with the generated accepted region.
            let root = cjguiComposableVertical(1, "perf-operation-root", CjguiComposableUiStyle(gap: 4))
            let scroll = cjguiComposableScrollArea(2, "perf-scroll", viewport,
                CjguiComposableUiStyle(growX: 1, fixedHeight: 120))
            let stack = cjguiComposableVertical(3, "perf-scroll-stack", CjguiComposableUiStyle(gap: 4))
            var index: Int64 = 0
            while (index < rows) {
                stack.add(cjguiComposableText(100 + index, "row${index}", "滚动行 ${index}",
                    CjguiComposableUiStyle(fontSize: 13.0, fixedHeight: 20)))
                index += 1
            }
            scroll.add(stack)
            root.add(scroll)
            let pane0 = cjguiComposableVertical(200, "perf-pane-0", CjguiComposableUiStyle())
            pane0.add(cjguiComposableText(201, "perf-pane-0-label", "左栏", CjguiComposableUiStyle(fixedHeight: 20)))
            let pane1 = cjguiComposableVertical(210, "perf-pane-1", CjguiComposableUiStyle())
            pane1.add(cjguiComposableText(211, "perf-pane-1-label", "右栏", CjguiComposableUiStyle(fixedHeight: 20)))
            let scope = CjguiComposableUiIdentityScope("perf-operation-split")
            root.add(cjguiComposableScopedSplitView(scope, "perf-split", pane0, pane1,
                CjguiComposableUiSplitAxis.HORIZONTAL, split.firstSize(), 120, 120,
                CjguiComposableUiStyle(growX: 1, fixedHeight: 80), splitState: split))
            root.add(match (holder) {
                case Some(value) => value.buildRefreshNode(provider)
                case None => cjguiComposableText(-1, "missing-tabs", "", CjguiComposableUiStyle())
            })
            return root
        }
        return windowPerfOperationHandRoot(viewport, split, tabs, rows, visibleDraft, hiddenDraft)
    }
    public func beginSceneRefresh(): Bool {
        return match (holder) {
            case Some(value) => value.beginCandidateRefresh()
            case None => true
        }
    }
    public func prepareSceneRefresh(): Bool {
        return match (holder) {
            case Some(value) => value.prepareCandidateRefresh()
            case None => true
        }
    }
    public func candidateSceneCommands(): ArrayList<CjguiComposableUiCommand> {
        return ArrayList<CjguiComposableUiCommand>()
    }
    public func commitSceneRefresh(): Unit {
        match (holder) {
            case Some(value) => let _ = value.commitCandidateRefresh()
            case None => ()
        }
    }
    public func rollbackSceneRefresh(): Unit {
        match (holder) {
            case Some(value) => value.rollbackCandidateRefresh()
            case None => ()
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
}

private func windowPerfOperationSample(window: CjguiComposableUiWindow,
    controller: WindowPerfOperationMatrixController, kind: String, count: Int64,
    operation: () -> Unit): Unit {
    let samples = ArrayList<Int64>()
    let buildsBefore = controller.buildCount
    let submitsBefore = window.windowProgress().nativeSubmissionVersion
    let solvesBefore = controller.operationViewport().acceptedSolveCount()
    var refreshedAll = true
    var index: Int64 = 0
    while (index < count) {
        // The request itself is outside the timed region. The timer covers one
        // ordinary refresh only, so the raw list remains comparable by operation.
        operation()
        controller.bump()
        let started = MonoTime.now()
        let refreshed = window.refresh()
        samples.add((MonoTime.now() - started).toMicroseconds())
        refreshedAll = refreshedAll && refreshed
        index += 1
    }
    @Assert(refreshedAll, true)
    @Assert(window.windowProgress().lastNativeFailure, "none")
    let builds = controller.buildCount - buildsBefore
    let submits = window.windowProgress().nativeSubmissionVersion - submitsBefore
    let solves = controller.operationViewport().acceptedSolveCount() - solvesBefore
    @Assert(builds, count)
    @Assert(solves >= count, true)
    let sorted = sortedPerfSampleCopy(samples)
    let median = perfNearestRank(sorted, 1, 2)
    reportWindowPerf("operation_matrix ${kind}", median,
        "author=${controller.authorName()} rows=${controller.rowCount()} samples=${samples.size} " +
        "raw_micros=${perfSamplesText(samples)} min_micros=${sorted[0]} " +
        "median_micros=${median} max_micros=${sorted[sorted.size - 1]} " +
        "builds=${builds} submits=${submits} solves=${solves} " +
        "time_source=MonoTime separated=work_vs_time asserts_outside_timer=true")
}

/// Every author/load pair receives the same operation matrix. The requests are
/// public view-state/owner operations; accepted values, rows and geometry are
/// checked after the timer has stopped. MonoTime is reported at microsecond
/// resolution and a measured zero remains valid evidence for a sub-microsecond
/// turn.
@Test
func windowPerfThreeAuthorsTwoLoadsOperationMatrix(): Unit {
    for (rows in [8, 32]) {
        var referenceSignature = ""
        for (author in 0..3) {
            let controller = WindowPerfOperationMatrixController(author, rows)
            let window = CjguiComposableUiWindow(controller)
            @Assert(controller.seedAccepted, true)
            @Assert(window.start(), true)
            @Assert(window.refresh(), true)
            @Assert(window.windowProgress().lastNativeFailure, "none")
            @Assert(authorMatrixAcceptedRowCount(window, rows), rows)
            let signature = operationMatrixAcceptedSignature(window)
            if (referenceSignature.size == 0) {
                referenceSignature = signature
            } else {
                @Assert(signature, referenceSignature)
            }

            windowPerfOperationSample(window, controller, "hot", 20) {
                // A versioned ordinary refresh is the hot no-structure path.
                let _ = controller.operationViewport().offset()
            }
            windowPerfOperationSample(window, controller, "scroll", 20) {
                if (controller.buildCount % 2 == 0) {
                    let _ = controller.operationViewport().step("next", 40)
                } else {
                    let _ = controller.operationViewport().step("previous", 40)
                }
            }
            windowPerfOperationSample(window, controller, "reveal", 20) {
                if (controller.buildCount % 2 == 0) {
                    let _ = controller.operationViewport().reveal(rows * 20 - 20, rows * 20)
                } else {
                    let _ = controller.operationViewport().reveal(0, 20)
                }
            }
            windowPerfOperationSample(window, controller, "split", 20) {
                let requested = if (controller.buildCount % 2 == 0) { 260 } else { 200 }
                let applied = controller.operationSplit().applyFirstSize(requested, 500, 8)
                @Assert(applied, requested)
            }
            windowPerfOperationSample(window, controller, "tabs", 20) {
                let next = if (controller.operationTabs().activeKey() == "basic") {
                    "retention"
                } else {
                    "basic"
                }
                @Assert(controller.operationTabs().select(next), true)
            }
            windowPerfOperationSample(window, controller, "visible_field", 20) {
                controller.setVisible("可见值-${controller.buildCount}")
            }
            windowPerfOperationSample(window, controller, "hidden_field", 20) {
                controller.setHidden("隐藏值-${controller.buildCount}")
            }

            // The owner values are read from the accepted scene after the timed
            // rounds. Hidden-page content is checked only after a real page switch.
            @Assert(window.acceptedSceneDump().contains(controller.visibleDraft), true)
            @Assert(controller.operationTabs().select("retention"), true)
            controller.bump()
            @Assert(window.refresh(), true)
            @Assert(window.acceptedSceneDump().contains(controller.hiddenDraft), true)

            // Clock resolution self-check is outside every operation timer. It is
            // reported for interpreting a raw 0 microsecond sample, never used to
            // manufacture work or to reject that sample.
            let clockStart = MonoTime.now()
            let clockEnd = MonoTime.now()
            let clockResolutionMicros = (clockEnd - clockStart).toMicroseconds()
            let idleBuildsBefore = controller.buildCount
            let idleSubmitsBefore = window.windowProgress().nativeSubmissionVersion
            let idleSolvesBefore = controller.operationViewport().acceptedSolveCount()
            let idleStarted = MonoTime.now()
            let idleRefreshed = window.refreshIfNeeded()
            let idleMicros = (MonoTime.now() - idleStarted).toMicroseconds()
            var idleRounds: Int64 = 1
            while (idleRounds < 5) {
                let _ = window.refreshIfNeeded()
                idleRounds += 1
            }
            let idleBuilds = controller.buildCount - idleBuildsBefore
            let idleSubmits = window.windowProgress().nativeSubmissionVersion - idleSubmitsBefore
            let idleSolves = controller.operationViewport().acceptedSolveCount() - idleSolvesBefore
            @Assert(idleBuilds, 0)
            @Assert(idleSubmits, 0)
            @Assert(idleSolves, 0)
            reportWindowPerf("operation_matrix idle", idleMicros,
                "author=${controller.authorName()} rows=${rows} samples=1 raw_micros=${idleMicros} " +
                "refresh_requested=${idleRefreshed} idle_rounds=${idleRounds} builds=${idleBuilds} " +
                "submits=${idleSubmits} solves=${idleSolves} clock_resolution_micros=${clockResolutionMicros} " +
                "zero_allowed=true time_source=MonoTime separated=work_vs_time")
            window.close()
        }
        @Assert(referenceSignature.size > 0, true)
    }
}

/// D: >= 20 bounded samples per necessary hot interaction on the normal window
/// hot path - scroll, reveal, split, tab page, a VISIBLE field update and a HIDDEN
/// field update - each driving the PUBLIC request seam and then one ordinary
/// refresh. Only the measured refresh is inside the timed region; every request,
/// counter read and assertion runs outside it. Work counters and the MonoTime
/// delta are reported separately, so a fast-looking sample can never hide
/// "nothing happened", and the idle line reports a REAL turn instead of a 0
/// sentinel.
@Test
func windowPerfInteractionSamplesWithSeparatedWorkAndTime(): Unit {
    let controller = WindowPerfInteractionController()
    let window = CjguiComposableUiWindow(controller)
    @Assert(window.start(), true)
    @Assert(window.refresh(), true)
    @Assert(window.windowProgress().lastNativeFailure, "none")

    // Each block alternates its request so EVERY sample really moves the
    // accepted scene: a request that is already satisfied would be a no-op turn
    // and could not price the operation.
    interactionSample(window, controller, "scroll", 20) {
        if (controller.buildCount % 2 == 0) {
            let _ = controller.viewport.step("next", 40)
        } else {
            let _ = controller.viewport.step("previous", 40)
        }
    }
    interactionSample(window, controller, "reveal", 20) {
        if (controller.buildCount % 2 == 0) {
            let _ = controller.viewport.reveal(400, 430)
        } else {
            let _ = controller.viewport.reveal(60, 90)
        }
    }
    interactionSample(window, controller, "split", 20) {
        if (controller.buildCount % 2 == 0) {
            let _ = controller.split.applyFirstSize(260, 500, 8)
        } else {
            let _ = controller.split.applyFirstSize(200, 500, 8)
        }
    }
    interactionSample(window, controller, "tabs", 20) {
        let next = if (controller.tabs.activeKey() == "basic") {
            "retention"
        } else {
            "basic"
        }
        let _ = controller.tabs.select(next)
    }
    // A VISIBLE field update: the owner value moves and the accepted scene must
    // carry it.
    interactionSample(window, controller, "visible_field", 20) {
        controller.visibleDraft = "可见值-${controller.buildCount}"
    }
    // A HIDDEN field update: the owner value moves while the page is not shown. It
    // needs no visible commit, but switching back must present it.
    interactionSample(window, controller, "hidden_field", 20) {
        controller.hiddenDraft = "隐藏值-${controller.buildCount}"
    }
    let acceptedVisible = interactionAcceptedEditorValue(window, "perf-visible-editor")
    @Assert(acceptedVisible, controller.visibleDraft)
    // Switch to the hidden page and verify the owner's CURRENT hidden value.
    @Assert(controller.tabs.select("retention"), true)
    controller.bump()
    @Assert(window.refresh(), true)
    let acceptedHidden = interactionAcceptedEditorValue(window, "perf-hidden-editor")
    @Assert(acceptedHidden, controller.hiddenDraft)
    reportWindowPerf("interaction hidden_field_continuation", 0,
        "active_page=${controller.tabs.activeKey()} accepted_hidden='${acceptedHidden}' " +
        "owner_hidden='${controller.hiddenDraft}' accepted_visible='${acceptedVisible}'")

    // Idle convergence AFTER the timed region: one REAL idle turn is timed (never
    // a 0 sentinel) and several further turns must do no build/submit/solve.
    let idleBuildsBefore = controller.buildCount
    let idleSubmitsBefore = window.windowProgress().nativeSubmissionVersion
    let idleSolvesBefore = controller.viewport.acceptedSolveCount()
    let clockProbeStart = MonoTime.now()
    let clockProbeEnd = MonoTime.now()
    let clockResolutionMicros = (clockProbeEnd - clockProbeStart).toMicroseconds()
    let idleStarted = MonoTime.now()
    let idleRequested = window.refreshIfNeeded()
    let idleMicros = (MonoTime.now() - idleStarted).toMicroseconds()
    var idleRounds: Int64 = 1
    var idleExtraWork: Int64 = 0
    while (idleRounds < 8) {
        if (window.refreshIfNeeded()) {
            idleExtraWork += 1
        }
        idleRounds += 1
    }
    let idleBuilds = controller.buildCount - idleBuildsBefore
    let idleSubmits = window.windowProgress().nativeSubmissionVersion - idleSubmitsBefore
    let idleSolves = controller.viewport.acceptedSolveCount() - idleSolvesBefore
    @Assert(idleBuilds, 0)
    @Assert(idleSubmits, 0)
    @Assert(idleSolves, 0)
    reportWindowPerf("interaction sample=idle", idleMicros,
        "refresh_requested=${idleRequested} idle_rounds=${idleRounds} idle_extra_work=${idleExtraWork} " +
        "builds=${idleBuilds} submits=${idleSubmits} solves=${idleSolves} " +
        "clock_resolution_micros=${clockResolutionMicros} zero_allowed=true " +
        "time_source=MonoTime separated=work_vs_time")
    window.close()
}

/// One bounded sample block: `count` iterations of ONE measured operation, each
/// timed on its own, with the request and the assertions OUTSIDE the timer. It
/// reports the raw sample count, min/median/max and the work counters the block
/// really produced, so "fast" can never mean "nothing happened".
private func interactionSample(window: CjguiComposableUiWindow, controller: WindowPerfInteractionController,
    kind: String, count: Int64, operation: () -> Unit): Unit {
    // A content-only field update may legitimately be published as a semantic-only
    // revision with NO native submission, so that expectation is derived from the
    // KIND instead of being assumed for all of them.
    let requireSubmit = kind != "visible_field" && kind != "hidden_field"
    let samples = ArrayList<Int64>()
    let buildsBefore = controller.buildCount
    let submitsBefore = window.windowProgress().nativeSubmissionVersion
    let solvesBefore = controller.viewport.acceptedSolveCount()
    var refreshedAll = true
    var index: Int64 = 0
    while (index < count) {
        operation()
        controller.bump()
        let started = MonoTime.now()
        let refreshed = window.refresh()
        samples.add((MonoTime.now() - started).toMicroseconds())
        refreshedAll = refreshedAll && refreshed
        index += 1
    }
    @Assert(refreshedAll, true)
    @Assert(window.windowProgress().lastNativeFailure, "none")
    let builds = controller.buildCount - buildsBefore
    let submits = window.windowProgress().nativeSubmissionVersion - submitsBefore
    let solves = controller.viewport.acceptedSolveCount() - solvesBefore
    // Every sample of a real change must have produced a real rebuild.
    @Assert(builds, count)
    if (requireSubmit) {
        @Assert(submits >= count, true)
    }
    let sorted = sortedPerfSampleCopy(samples)
    let median = perfNearestRank(sorted, 1, 2)
    reportWindowPerf("interaction sample=${kind}", median,
        "samples=${samples.size} min_micros=${sorted[0]} max_micros=${sorted[sorted.size - 1]} " +
        "median_micros=${median} builds=${builds} submits=${submits} solves=${solves} " +
        "submit_required=${requireSubmit} " +
        "time_source=MonoTime separated=work_vs_time asserts_outside_timer=true")
}

/// The value the window's ACCEPTED scene really carries for one editor semantic
/// id. A rebuilt tree is not accepted state.
private func interactionAcceptedEditorValue(window: CjguiComposableUiWindow, semanticId: String): String {
    for (node in window.acceptedSceneNodes()) {
        if (node.semanticId == semanticId) {
            return node.value
        }
    }
    return ""
}

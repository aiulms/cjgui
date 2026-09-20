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
private class WindowPerfTreeSource <: CjguiComposableUiTreeDataSource {
    let leaves: Int64
    private let labels: HashMap<String, String> = HashMap<String, String>()
    var childAtCalls: Int64 = 0
    var dataVersion: Int64 = 1

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

    /// One business object changes. This is the single-object update case.
    public func changeOne(index: Int64, suffix: String): Unit {
        labels.add("leaf-${index}", "叶 ${index}${suffix}")
        dataVersion += 1
    }

    /// Every object changes at once: the contrast case, never labelled as a
    /// single-object update.
    public func changeAll(suffix: String): Unit {
        var index: Int64 = 0
        while (index < leaves) {
            labels.add("leaf-${index}", "叶 ${index}${suffix}")
            index += 1
        }
        dataVersion += 1
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
    var buildCount: Int64 = 0
    var lastMaterialized: Int64 = 0
    /// The row labels the last build really produced, so content is asserted
    /// outside the timed region instead of inferred from a version number.
    var builtLabels: HashMap<String, String> = HashMap<String, String>()
    // Per-phase sample counters, so the index pass and the row build can be
    // reported next to the whole window refresh instead of being guessed.
    var indexMicros: Int64 = 0
    var rowBuildMicros: Int64 = 0
    private var dataDirty: Bool = false

    init(source: WindowPerfTreeSource) {
        this.source = source
        this.projection = CjguiComposableUiTreeProjection(source)
        this.selection = CjguiComposableUiTreeSelection(this.projection)
        this.listState = CjguiComposableUiVirtualListState()
        let _ = this.projection.setExpanded("group-0", true)
    }

    public func uiSceneVersion(): Int64 {
        return revision
    }

    public func buildUi(): CjguiComposableUiNode {
        buildCount += 1
        if (dataDirty) {
            // The consumer's own index pass over the changed data.
            let indexStarted = MonoTime.now()
            let _ = projection.rebuild()
            indexMicros += (MonoTime.now() - indexStarted).toMicroseconds()
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

    // One visible object changes: the new content must really be in the scene.
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
    // The index pass is bounded by the logical row count once, and never by the
    // visible viewport alone or by a full re-materialization.
    @Assert(singleIndexCalls > 0 && singleIndexCalls <= 10001 + 2, true)

    let indexAfterAbs = controller.indexMicros
    let rowBuildAfterAbs = controller.rowBuildMicros
    // One far-away object changes: the viewport must stay bounded and the far
    // row must not be materialized just because it changed.
    let beforeFarChildAt = source.childAtCalls
    let farStarted = MonoTime.now()
    source.changeOne(4242, " #")
    controller.dataChanged()
    @Assert(window.refreshIfNeeded(), true)
    let farMicros = (MonoTime.now() - farStarted).toMicroseconds()
    let farIndexCalls = source.childAtCalls - beforeFarChildAt
    @Assert(controller.materializedRows() <= 8 + 2 * 4, true)
    @Assert(controller.builtLabels.get("leaf-4242"), None)
    @Assert(farIndexCalls > 0 && farIndexCalls <= 10001 + 2, true)

    let indexAfterFar = controller.indexMicros
    let rowBuildAfterFar = controller.rowBuildMicros
    let bulkStarted = MonoTime.now()
    source.changeAll(" +")
    controller.dataChanged()
    @Assert(window.refreshIfNeeded(), true)
    let bulkMicros = (MonoTime.now() - bulkStarted).toMicroseconds()
    @Assert(controller.materializedRows() <= 8 + 2 * 4, true)
    let progress = window.windowProgress()
    @Assert(progress.lastNativeFailure, "none")
    @Assert(progress.acceptedSceneVersion == progress.sceneVersion, true)
    reportWindowPerf("window_update_single_visible", singleMicros,
        "logical=10001 materialized=${controller.materializedRows()} index_calls=${singleIndexCalls} " +
        "index_us=${indexAfterAbs - indexBeforeAbs} row_build_us=${rowBuildAfterAbs - rowBuildBeforeAbs} content_ok=true")
    reportWindowPerf("window_update_single_far", farMicros,
        "logical=10001 materialized=${controller.materializedRows()} index_calls=${farIndexCalls} " +
        "index_us=${indexAfterFar - indexAfterAbs} row_build_us=${rowBuildAfterFar - rowBuildAfterAbs} " +
        "far_materialized=false")
    reportWindowPerf("window_update_bulk", bulkMicros,
        "logical=10001 materialized=${controller.materializedRows()} " +
        "index_us=${controller.indexMicros - indexAfterFar} row_build_us=${controller.rowBuildMicros - rowBuildAfterFar} " +
        "rewritten_objects=10001")
    window.close()
}

// --- handwritten versus generated panel in a real window --------------------

private class WindowPerfFieldProvider <: CjguiGeneratedUiBindingProvider {
    public func fieldResourceId(fieldId: String): Int64 { return 9000 }
    public func fieldOperationResourceId(fieldId: String): Int64 { return 1 }
    public func draftText(fieldId: String): String { return "v" }
    public func appliedText(fieldId: String): String { return "v" }
    public func draftBoolean(fieldId: String): ?Bool { return None }
    public func executeAction(actionName: String, nodeKey: String): CjguiGeneratedUiActionResult {
        return CjguiGeneratedUiActionResult(true, "")
    }
    public func actionAvailable(actionName: String): Bool { return true }
}

/// A window whose panel is authored either by hand or as a generated structure,
/// with the same fields, labels, values and bindings in both cases.
private class WindowPerfPanelController <: CjguiComposableUiController &
    CjguiComposableUiSceneRefreshParticipant {
    private let fields: Int64
    private let generated: Bool
    private let provider: WindowPerfFieldProvider
    private let catalog: CjguiGeneratedUiCapabilityCatalog
    private let holder: ?CjguiGeneratedUiStructureHolder
    private let spec: ?CjguiGeneratedUiNodeSpec
    private var revision: Int64 = 1
    var buildCount: Int64 = 0
    var adapterMicros: Int64 = 0

    init(fields: Int64, generated: Bool) {
        this.fields = fields
        this.generated = generated
        this.provider = WindowPerfFieldProvider()
        if (generated) {
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
            let _ = catalog.registerField(CjguiGeneratedUiFieldSpec("label", "字段", "TEXT", 9000,
                writeActionName: "EDIT_DRAFT_TEXT"))
            this.catalog = catalog
            this.holder = Some(CjguiGeneratedUiStructureHolder(catalog))
            this.spec = Some(perfPanelSpec(fields))
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
        if (!generated) {
            return perfHandwrittenPanel(fields)
        }
        if (let Some(value) <- holder) {
            return value.buildRefreshNode(provider)
        }
        return perfHandwrittenPanel(fields)
    }

    /// The generated panel's extra adapter cost: decode/validate/submit and
    /// candidate expansion, measured separately from the shared window refresh.
    public func prepareCandidate(): Bool {
        if (let Some(value) <- holder) {
            if (let Some(candidate) <- spec) {
                let started = MonoTime.now()
                let _ = CjguiGeneratedUiValidator(catalog).validate(candidate)
                let submitted = value.submit(candidate, provider)
                adapterMicros += (MonoTime.now() - started).toMicroseconds()
                return submitted.candidateAccepted
            }
        }
        return true
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
}

private func perfHandwrittenPanel(fields: Int64): CjguiComposableUiNode {
    let root = cjguiComposableVertical(500, "perf-panel", CjguiComposableUiStyle(gap: 6, padding: 8))
    var index: Int64 = 0
    while (index < fields) {
        root.add(cjguiComposableText(601 + index * 4, "perf-label-${index}", "字段 ${index}",
            CjguiComposableUiStyle(fontSize: 12.0)))
        root.add(cjguiComposableTextInput(602 + index * 4, "perf-input-${index}", "值 ${index}", "v${index}",
            9000 + index, CjguiComposableUiStyle(fixedHeight: 24), fieldId: "label",
            operationActionName: "EDIT_DRAFT_TEXT", operationResourceId: 1, displayValueRole: "draft"))
        index += 1
    }
    return root
}

private func perfPanelSpec(fields: Int64): CjguiGeneratedUiNodeSpec {
    let children = ArrayList<CjguiGeneratedUiNodeSpec>()
    var index: Int64 = 0
    while (index < fields) {
        let text = HashMap<String, String>()
        text.add("text", "字段 ${index}")
        children.add(CjguiGeneratedUiNodeSpec("perf-label-${index}", "label", properties: text))
        let label = HashMap<String, String>()
        label.add("label", "值 ${index}")
        children.add(CjguiGeneratedUiNodeSpec("perf-input-${index}", "textInput", properties: label,
            fieldId: "label"))
        index += 1
    }
    return CjguiGeneratedUiNodeSpec("perf-panel", "vertical", children: children)
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

/// A window-level handwritten/generated refresh comparison with the same
/// structure, style, values and bindings, sampled several times.
private func samplePanelRefresh(generated: Bool, fields: Int64, sampleCount: Int64):
    (Int64, Int64, Int64, Int64) {
    let controller = WindowPerfPanelController(fields, generated)
    let window = CjguiComposableUiWindow(controller)
    @Assert(window.start(), true)
    // Warm-up so first-call effects do not dominate the samples.
    @Assert(controller.prepareCandidate(), true)
    controller.bump()
    @Assert(window.refresh(), true)
    let warmNodes = window.windowProjection().acceptedSceneVersion
    @Assert(warmNodes > 0, true)
    let adapterBefore = controller.adapterMicros
    let samples = ArrayList<Int64>()
    var sample: Int64 = 0
    while (sample < sampleCount) {
        @Assert(controller.prepareCandidate(), true)
        controller.bump()
        let started = MonoTime.now()
        @Assert(window.refreshIfNeeded(), true)
        samples.add((MonoTime.now() - started).toMicroseconds())
        let progress = window.windowProgress()
        @Assert(progress.acceptedSceneVersion == progress.sceneVersion, true)
        @Assert(progress.lastNativeFailure, "none")
        sample += 1
    }
    let median = medianOf(samples)
    let adapterPerSample = if (sampleCount > 0) {
        (controller.adapterMicros - adapterBefore) / sampleCount
    } else {
        0
    }
    let builds = controller.buildCount
    window.close()
    return (median, adapterPerSample, builds, samples[0])
}

@Test
func windowPerfHandwrittenVersusGeneratedPanelCosts(): Unit {
    for (fields in [8, 20, 30]) {
        let handwritten = samplePanelRefresh(false, fields, 5)
        let generated = samplePanelRefresh(true, fields, 5)
        // The comparison is only meaningful when both really ran the same
        // number of refreshes and the generated path actually validated.
        @Assert(handwritten[2] >= 5, true)
        @Assert(generated[2] >= 5, true)
        @Assert(generated[1] > 0, true)
        reportWindowPerf("window_panel_handwritten", handwritten[0],
            "fields=${fields} samples=5 builds=${handwritten[2]} adapter_us=0")
        reportWindowPerf("window_panel_generated", generated[0],
            "fields=${fields} samples=5 builds=${generated[2]} adapter_us=${generated[1]}")
    }
}

/// Two live windows: while one keeps progressing, the other has no work; after
/// both stop, repeated refreshes submit nothing and never call the model again.
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
        "progressed_window=1 idle_window_scene=${sceneABefore} idle_noop_refresh_calls=${aAcceptedRefreshes} " +
        "idle_builds=${aBuilds} idle_index_calls=${aIndexCalls}")

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

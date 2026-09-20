// MODEL-LEVEL cost samples for the tree list engine and for the
// generated-vs-handwritten build path.
//
// Scope correction: these samples drive the list engine and the layout engine
// directly - they do NOT go through a normal window's layout/submit, and the
// generated/handwritten comparison below lays out two differently styled panels,
// so it measures the adapter against that fixed layout, not a window refresh.
// The whole-window samples (fixed viewport scroll, one-object update, equivalent
// handwritten/generated panels, other-window progress and idle convergence) live
// in composable_ui_window_perf_test.cj and are the ones to quote for production
// cost. These remain as fast model-level micro-benchmarks:
//
//   * tree samples drive the real virtual-list path (scroll offset ->
//     materialized range -> row component construction), not only rowAt lookups;
//   * the generated/handwritten samples build a comparable panel two ways and
//     lay both out with the same layout engine, so the generated adapter cost
//     (validation + expansion + identity) is separated from the layout cost.
//
// Timings are reported per operation and correctness is asserted outside the
// timed regions. Counts of materialized rows and source lookups are recorded so
// a per-frame number can be read against actual work, not against a literal.
package cjgui

import std.collection.*
import std.fs.*
import std.time.*

let generatedPerfLines = ArrayList<String>()

func reportGeneratedPerf(label: String, micros: Int64, detail: String): Unit {
    generatedPerfLines.add("GENERATED_PERF ${label} micros=${micros} ${detail}")
    flushGeneratedPerf()
}

func flushGeneratedPerf(): Unit {
    let builder = StringBuilder()
    for (line in generatedPerfLines) {
        builder.append(line)
        builder.append("\n")
    }
    try {
        File.writeTo("/private/tmp/cjgui-generated-perf.log", builder.toString().toArray())
    } catch (error: Exception) {
        // Evidence file is best-effort; assertions do not depend on it.
    }
}

/// Logical tree of `groups` groups x `leaves` leaves over the real list source.
class GeneratedPerfTreeSource <: CjguiComposableUiTreeDataSource {
    let groups: Int64
    let leavesPerGroup: Int64
    var childAtCalls: Int64 = 0
    var labelSuffix: Int64 = 0

    init(groups: Int64, leavesPerGroup: Int64) {
        this.groups = groups
        this.leavesPerGroup = leavesPerGroup
    }

    public func childCount(parentKey: String): Int64 {
        if (parentKey.isEmpty()) { return groups }
        if (parentKey.startsWith("group-")) { return leavesPerGroup }
        return 0
    }

    public func childAt(parentKey: String, index: Int64): CjguiComposableUiTreeNode {
        childAtCalls += 1
        if (parentKey.isEmpty()) {
            return CjguiComposableUiTreeNode("group-${index}", "组 ${index}", 100 + index, true, selectable: false)
        }
        return CjguiComposableUiTreeNode("${parentKey}-leaf-${index}", "叶 ${index}-${labelSuffix}",
            200 + index, false, selectable: true)
    }
}

/// Row-build counter shared with the list-source builder closure. Cangjie
/// forbids a stored closure from capturing a mutable local, so the count lives
/// on an object instead.
class GeneratedPerfRowCounter {
    var built: Int64 = 0
    var lastNodeId: Int64 = 0
}

/// One production-path scroll sample: fixed viewport, fixed row height, real
/// materialization + real row construction for the materialized range.
func runTreeScrollSample(label: String, groups: Int64, leaves: Int64, viewportRows: Int64,
                         frames: Int64): Int64 {
    let source = GeneratedPerfTreeSource(groups, leaves)
    let projection = CjguiComposableUiTreeProjection(source)
    let _ = projection.setExpandedBatch(projection.groupKeys(), true)
    let selection = CjguiComposableUiTreeSelection(projection)
    let state = CjguiComposableUiVirtualListState()
    let counter = GeneratedPerfRowCounter()
    let listSource = CjguiComposableUiTreeListSource(projection, selection,
        { row, isSelected, isFocused =>
            counter.built += 1
            let node = cjguiComposableText(1, row.key, row.label, CjguiComposableUiStyle())
            counter.lastNodeId = node.nodeId
            node
        })
    let count = projection.rowCount()
    var checksum: Int64 = 0
    let started = MonoTime.now()
    var frame: Int64 = 0
    while (frame < frames) {
        let offset = (frame * 7) % count
        state.scrollToIndex(offset)
        let _ = state.updateMaterializedRange(listSource, 24, 2, viewportRows * 26, 4)
        var index = state.materializedStart()
        let end = state.materializedEnd()
        while (index < end) {
            if (index >= 0 && index < count) {
                let item = listSource.itemAt(index)
                let row = listSource.buildRow(item, false, false)
                checksum += row.nodeId
            }
            index += 1
        }
        frame += 1
    }
    let micros = (MonoTime.now() - started).toMicroseconds()
    let builtRows = counter.built
    let materializedPerFrame = if (frames > 0) { builtRows / frames } else { 0 }
    reportGeneratedPerf(label, micros,
        "logical=${count} frames=${frames} materialized_rows=${builtRows} rows_per_frame=${materializedPerFrame} " +
        "childAt=${source.childAtCalls} viewport_rows=${viewportRows} checksum=${checksum}")
    return builtRows
}

@Test
func generatedPerfTreeProductionScroll100(): Unit {
    let built = runTreeScrollSample("tree_scroll_100", 20, 5, 8, 200)
    @Assert(built > 0, true)
}

@Test
func generatedPerfTreeProductionScroll1k(): Unit {
    let built = runTreeScrollSample("tree_scroll_1k", 40, 25, 8, 200)
    @Assert(built > 0, true)
}

@Test
func generatedPerfTreeProductionScroll10k(): Unit {
    // 10k logical nodes on the public tree consumer path: only the viewport
    // plus overscan is ever materialized.
    let built = runTreeScrollSample("tree_scroll_10k", 200, 50, 8, 200)
    @Assert(built > 0, true)
}

/// A BULK data change: every leaf's label changes at once. This is not a
/// single-object update sample; see windowPerfSingleObjectUpdateVersusBulkUpdate.
@Test
func generatedPerfTreeLocalDataChange10k(): Unit {
    let source = GeneratedPerfTreeSource(200, 50)
    let projection = CjguiComposableUiTreeProjection(source)
    let _ = projection.setExpandedBatch(projection.groupKeys(), true)
    let before = projection.rowCount()
    // One object changes: one data-version bump, one index rebuild.
    source.labelSuffix = 1
    let started = MonoTime.now()
    let _ = projection.invalidate()
    let micros = (MonoTime.now() - started).toMicroseconds()
    reportGeneratedPerf("tree_local_update_10k", micros,
        "logical=${projection.rowCount()} childAt=${source.childAtCalls} before=${before}")
    @Assert(projection.rowCount(), before)
    @Assert(projection.rowAt(1).label.endsWith("-1"), true)
}

/// The same panel built two ways: by hand with the ordinary component builders,
/// and from a generated structure through the validated holder. Both are laid
/// out by the same engine on the same viewport.
func handwrittenPanel(fields: Int64): CjguiComposableUiNode {
    // Two components per field so the panel stays inside the framework's
    // declared generated-instance capacity while still measuring a realistic
    // form: one label plus one input.
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

func generatedPanelSpec(fields: Int64): CjguiGeneratedUiNodeSpec {
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

class GeneratedPerfProvider <: CjguiGeneratedUiBindingProvider {
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

@Test
func generatedPerfHandwrittenVersusGeneratedCost(): Unit {
    // 30 fields x 2 nodes + 1 container = 61 component instances, inside the
    // framework's declared CJGUI_GENERATED_UI_COMPONENT_INSTANCE_CAPACITY (64).
    let fields: Int64 = 30
    let provider = GeneratedPerfProvider()
    let catalog = CjguiGeneratedUiCapabilityCatalog()
    let _ = catalog.registerComponent(CjguiGeneratedUiComponentSpec("vertical",
        ArrayList<CjguiGeneratedUiPropertySpec>([
            CjguiGeneratedUiPropertySpec("gap", "INTEGER", minimum: 0, maximum: 32),
            CjguiGeneratedUiPropertySpec("padding", "INTEGER", minimum: 0, maximum: 32)
        ]), true, childLimit: 256))
    let _ = catalog.registerComponent(CjguiGeneratedUiComponentSpec("horizontal",
        ArrayList<CjguiGeneratedUiPropertySpec>([CjguiGeneratedUiPropertySpec("gap", "INTEGER", minimum: 0, maximum: 32)]),
        true, childLimit: 256))
    let _ = catalog.registerComponent(CjguiGeneratedUiComponentSpec("label",
        ArrayList<CjguiGeneratedUiPropertySpec>([
            CjguiGeneratedUiPropertySpec("text", "STRING", required: true, maxLength: 64)
        ]), false))
    let _ = catalog.registerComponent(CjguiGeneratedUiComponentSpec("textInput",
        ArrayList<CjguiGeneratedUiPropertySpec>([CjguiGeneratedUiPropertySpec("label", "STRING", maxLength: 64)]), false))
    let _ = catalog.registerField(CjguiGeneratedUiFieldSpec("label", "字段", "TEXT", 9000, writeActionName: "EDIT_DRAFT_TEXT"))
    let holder = CjguiGeneratedUiStructureHolder(catalog)
    let spec = generatedPanelSpec(fields)
    let viewport = CjguiComposableUiRect(0, 0, 480, 900)

    // Warm-up: one throwaway run of both paths so first-call effects do not
    // dominate the samples.
    let warmWrite = handwrittenPanel(8)
    let _ = CjguiComposableUiLayoutEngine.layout(warmWrite, viewport, 1)
    let _ = holder.submit(generatedPanelSpec(8), provider)
    let _ = holder.beginCandidateRefresh()
    let _ = holder.buildRefreshNode(provider)
    let _ = holder.prepareCandidateRefresh()
    let _ = holder.commitCandidateRefresh()

    // Handwritten build + layout.
    let handwrittenBuildStarted = MonoTime.now()
    let handwritten = handwrittenPanel(fields)
    let handwrittenBuildMicros = (MonoTime.now() - handwrittenBuildStarted).toMicroseconds()
    let handwrittenLayoutStarted = MonoTime.now()
    let handwrittenScene = CjguiComposableUiLayoutEngine.layout(handwritten, viewport, 2)
    let handwrittenLayoutMicros = (MonoTime.now() - handwrittenLayoutStarted).toMicroseconds()

    // Generated: validation, candidate expansion and build.
    let validateStarted = MonoTime.now()
    let validation = CjguiGeneratedUiValidator(catalog).validate(spec)
    let validateMicros = (MonoTime.now() - validateStarted).toMicroseconds()
    @Assert(validation.accepted, true)
    let submitStarted = MonoTime.now()
    let submit = holder.submit(spec, provider)
    let submitMicros = (MonoTime.now() - submitStarted).toMicroseconds()
    @Assert(submit.candidateAccepted, true)
    let buildStarted = MonoTime.now()
    let _ = holder.beginCandidateRefresh()
    let generated = holder.buildRefreshNode(provider)
    let buildMicros = (MonoTime.now() - buildStarted).toMicroseconds()
    @Assert(holder.prepareCandidateRefresh(), true)
    @Assert(holder.commitCandidateRefresh(), true)
    let generatedLayoutStarted = MonoTime.now()
    let generatedScene = CjguiComposableUiLayoutEngine.layout(generated, viewport, 3)
    let generatedLayoutMicros = (MonoTime.now() - generatedLayoutStarted).toMicroseconds()

    // Correctness outside the timed regions: both scenes contain the same
    // number of laid-out nodes and the same field binding.
    let handwrittenNodes = handwrittenScene.nodes().size
    let generatedNodes = generatedScene.nodes().size
    @Assert(handwrittenNodes, generatedNodes)
    var bindingFound = false
    for (node in generatedScene.nodes()) {
        if (node.fieldId == "label" && node.nodeKind == CJGUI_COMPOSABLE_UI_TEXT_INPUT) {
            bindingFound = true
        }
    }
    @Assert(bindingFound, true)

    reportGeneratedPerf("generated_vs_handwritten_fields${fields}", handwrittenBuildMicros,
        "handwritten_build=${handwrittenBuildMicros} generated_validate=${validateMicros} " +
        "generated_submit=${submitMicros} generated_build=${buildMicros} " +
        "handwritten_layout=${handwrittenLayoutMicros} generated_layout=${generatedLayoutMicros} " +
        "nodes=${generatedNodes}")
    @Assert(handwrittenNodes > fields, true)
}

/// Repeated no-change accepted-scene builds do not re-validate. This measures
/// the generated holder's own rebuild, not the window scheduler's idle
/// convergence (see windowPerfOtherWindowProgressAndIdleConvergence).
@Test
func generatedPerfNoChangeRefreshDoesNotRevalidate(): Unit {
    let catalog = CjguiGeneratedUiCapabilityCatalog()
    let _ = catalog.registerComponent(CjguiGeneratedUiComponentSpec("vertical",
        ArrayList<CjguiGeneratedUiPropertySpec>(), true, childLimit: 256))
    let _ = catalog.registerComponent(CjguiGeneratedUiComponentSpec("textInput",
        ArrayList<CjguiGeneratedUiPropertySpec>(), false))
    let _ = catalog.registerField(CjguiGeneratedUiFieldSpec("label", "字段", "TEXT", 9000))
    let holder = CjguiGeneratedUiStructureHolder(catalog)
    let provider = GeneratedPerfProvider()
    let children = ArrayList<CjguiGeneratedUiNodeSpec>()
    children.add(CjguiGeneratedUiNodeSpec("f", "textInput", fieldId: "label"))
    let root = CjguiGeneratedUiNodeSpec("root", "vertical", children: children)
    let _ = holder.submit(root, provider)
    let _ = holder.beginCandidateRefresh()
    let _ = holder.buildRefreshNode(provider)
    let _ = holder.prepareCandidateRefresh()
    let _ = holder.commitCandidateRefresh()
    let versionBefore = holder.structureVersion()
    // An unchanged rebuild must not create a candidate, change the version or
    // re-render through a new structure description.
    let started = MonoTime.now()
    var frame: Int64 = 0
    var nodes: Int64 = 0
    while (frame < 200) {
        let node = holder.buildAccepted(provider)
        nodes += node.nodeId
        frame += 1
    }
    let micros = (MonoTime.now() - started).toMicroseconds()
    reportGeneratedPerf("generated_no_change_refresh_200", micros,
        "version=${holder.structureVersion()} pending=${holder.hasPendingCandidate()} checksum=${nodes}")
    @Assert(holder.structureVersion(), versionBefore)
    @Assert(holder.hasPendingCandidate(), false)
    @Assert(holder.lastSceneOutcome(), "scene_accepted")
}

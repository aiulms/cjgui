package cjgui

import cjgui_shared_operation_core.*
import std.collection.*

// This probe is compiled only with CJGUI_INTERNAL_TESTING. It measures a
// normal Cangjie controller/window transaction; native values are scalar
// counters, not Objective-C objects or a public renderer API.
foreign {
    func cjgui_internal_renderer_test_composable_scene_submission_stats(
        session: UInt64, outCloneCount: CPointer<UInt64>, outNodeAllocationCount: CPointer<UInt64>,
        outConfigureMicros: CPointer<UInt64>, outSetMicros: CPointer<UInt64>, outCommitMicros: CPointer<UInt64>
    ): Int32
    func cjgui_internal_renderer_test_set_composable_scene_node_failures(session: UInt64, failureCount: UInt32): Int32
    func cjgui_internal_renderer_test_resize_composable_window(session: UInt64, outResizeVersion: CPointer<UInt64>): Int32
}

private class CjguiSceneSubmissionStats {
    let status: Int32
    let clones: UInt64
    let allocations: UInt64
    let configureMicros: UInt64
    let setMicros: UInt64
    let commitMicros: UInt64
    init(status: Int32, clones: UInt64, allocations: UInt64, configureMicros: UInt64, setMicros: UInt64,
        commitMicros: UInt64) {
        this.status = status
        this.clones = clones
        this.allocations = allocations
        this.configureMicros = configureMicros
        this.setMicros = setMicros
        this.commitMicros = commitMicros
    }
}

private func submissionStats(window: CjguiComposableUiWindow): CjguiSceneSubmissionStats {
    var clones: UInt64 = 0u64
    var allocations: UInt64 = 0u64
    var configureMicros: UInt64 = 0u64
    var setMicros: UInt64 = 0u64
    var commitMicros: UInt64 = 0u64
    let status = unsafe {
        cjgui_internal_renderer_test_composable_scene_submission_stats(
            window.testSessionToken(), inout clones, inout allocations, inout configureMicros, inout setMicros,
            inout commitMicros)
    }
    return CjguiSceneSubmissionStats(status, clones, allocations, configureMicros, setMicros, commitMicros)
}

private class SceneSubmissionScaleController <: CjguiComposableUiController {
    private let baseNodeCount: Int64
    private var revision: Int64
    private var accent: Bool
    private var extraNode: Bool
    private var reverseRows: Bool
    private var imageVersion: Int64

    init(baseNodeCount: Int64) {
        this.baseNodeCount = baseNodeCount
        this.revision = 1
        this.accent = false
        this.extraNode = false
        this.reverseRows = false
        this.imageVersion = 1
    }

    public func uiSceneVersion(): Int64 { return revision }
    public func currentImageVersion(): Int64 { return imageVersion }

    public func buildUi(): CjguiComposableUiNode {
        let root = cjguiComposableVertical(700000, "scene-scale-root", CjguiComposableUiStyle(padding: 2, gap: 0))
        root.add(cjguiComposableImage(700001, "scene-scale-image", "runtime/cjgui/resources/composable-beacon.png",
            CjguiComposableUiStyle(fixedWidth: 10, fixedHeight: 10), imageResourceId: "scene-scale-image",
            imageResourceVersion: imageVersion))
        let rows = baseNodeCount - 2 + if (extraNode) { 1 } else { 0 }
        var position: Int64 = 0
        while (position < rows) {
            let logical = if (reverseRows) { rows - position - 1 } else { position }
            let isAccent = logical == 0 && accent
            root.add(cjguiComposableText(701000 + logical, "scene-scale-row-${logical}",
                if (logical == 0) { if (isAccent) { "accent-on" } else { "accent-off" } } else { "row-${logical}" },
                CjguiComposableUiStyle(fixedHeight: 14, fontSize: 10.0,
                    textColor: if (isAccent) { CjguiComposableUiColor(0.85, 0.15, 0.15, 1.0) } else {
                        CjguiComposableUiColor(0.85, 0.85, 0.85, 1.0)
                    })))
            position += 1
        }
        return root
    }

    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        let _ = event
        return CjguiComposableUiDispatchResult(false)
    }
    public func rejectUiEvent(eventKind: Int64, nodeId: Int64): CjguiComposableUiDispatchResult {
        let _ = eventKind
        let _ = nodeId
        return CjguiComposableUiDispatchResult(false)
    }
    public func requestWindowClose(): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(true, shouldClose: true)
    }

    public func advance(mode: String): Unit {
        if (mode == "local_color") {
            accent = !accent
        } else if (mode == "component_add_remove") {
            extraNode = !extraNode
        } else if (mode == "reorder") {
            reverseRows = !reverseRows
        } else if (mode == "image_replace") {
            // This is a COW scene-scale probe, not an unbounded resource
            // admission test. Alternate two declared versions so each sample
            // rebinds the image node after their initial asynchronous loads,
            // without manufacturing a backlog that would consume the
            // resource pipeline's deliberate pending-capacity budget.
            imageVersion = if (imageVersion == 1) { 2 } else { 1 }
        }
        revision += 1
    }
}

// The scale samples deliberately measure a controller refresh, while image
// preparation continues through the normal AppKit pump.  Drain only the
// currently referenced image before declaring the final observation idle;
// otherwise an unrelated pending completion could be misreported as idle
// submission work.
private func settleActiveImage(window: CjguiComposableUiWindow,
    controller: SceneSubmissionScaleController): Bool {
    var turns: Int64 = 0
    while (turns < 100) {
        let resource = window.imageResourceStatus("runtime/cjgui/resources/composable-beacon.png",
            "scene-scale-image", controller.currentImageVersion())
        if (resource.state == "failed") { return false }
        if (resource.state == "ready") {
            return window.refreshIfNeeded()
        }
        let _ = CjguiComposableUiWindowTurnScheduler.pumpWithoutExternal(window, turnBudgetMs: 4u32)
        turns += 1
    }
    return false
}

private func printSample(mode: String, requestedNodes: Int64, sample: Int64, before: CjguiSceneSubmissionStats,
    after: CjguiSceneSubmissionStats, projection: CjguiSharedOperationWindowProjection): Unit {
    println("CJGUI_SCENE_SCALE_SAMPLE mode=${mode} requested_nodes=${requestedNodes} sample=${sample} committed_nodes=${projection.nodes.size} clone_delta=${after.clones - before.clones} allocation_delta=${after.allocations - before.allocations} configure_us=${after.configureMicros - before.configureMicros} setter_us=${after.setMicros - before.setMicros} commit_us=${after.commitMicros - before.commitMicros} build_ms=${projection.lastBuildElapsedMs} layout_ms=${projection.lastLayoutElapsedMs} stage_submit_ms=${projection.lastNativeStageAndSubmitElapsedMs} submitted_frame=${projection.submittedFrameIndex} metal_completed=${projection.observedMetalCompletionFrameIndex} metal_gpu_us=${projection.observedMetalGpuDurationMicros}")
}

private func runMode(requestedNodes: Int64, mode: String): Bool {
    let controller = SceneSubmissionScaleController(requestedNodes)
    let window = CjguiComposableUiWindow(controller)
    if (!window.start()) { window.close(); return false }
    let initial = window.windowProjection()
    if (initial.nodes.size != requestedNodes || initial.submittedFrameIndex <= 0) { window.close(); return false }
    var sample: Int64 = 0
    while (sample < 30) {
        let before = submissionStats(window)
        if (before.status != CJGUI_INTERNAL_RENDERER_OK) { window.close(); return false }
        if (mode == "resize") {
            var resizeVersion: UInt64 = 0u64
            let resize = unsafe { cjgui_internal_renderer_test_resize_composable_window(window.testSessionToken(), inout resizeVersion) }
            if (resize != CJGUI_INTERNAL_RENDERER_OK || resizeVersion == 0u64) { window.close(); return false }
            if (!window.refreshIfNeeded()) { window.close(); return false }
        } else {
            controller.advance(mode)
            if (!window.refresh()) { window.close(); return false }
        }
        let after = submissionStats(window)
        let projection = window.windowProjection()
        if (after.status != CJGUI_INTERNAL_RENDERER_OK || projection.nodes.size < requestedNodes ||
            projection.submittedFrameIndex <= initial.submittedFrameIndex) { window.close(); return false }
        printSample(mode, requestedNodes, sample, before, after, projection)
        sample += 1
    }
    if (!settleActiveImage(window, controller)) { window.close(); return false }
    // A cheap ordinary observation must stay outside the submission path.
    let beforeIdle = submissionStats(window)
    let idleProjection = window.windowProjection()
    let idle = window.refreshIfNeeded()
    let afterIdle = submissionStats(window)
    let afterIdleProjection = window.windowProjection()
    println("CJGUI_SCENE_SCALE_IDLE mode=${mode} requested_nodes=${requestedNodes} accepted=${idle} clone_delta=${afterIdle.clones - beforeIdle.clones} allocation_delta=${afterIdle.allocations - beforeIdle.allocations} configure_us=${afterIdle.configureMicros - beforeIdle.configureMicros} setter_us=${afterIdle.setMicros - beforeIdle.setMicros} commit_us=${afterIdle.commitMicros - beforeIdle.commitMicros} build_delta=${afterIdleProjection.buildPassCount - idleProjection.buildPassCount} layout_delta=${afterIdleProjection.layoutPassCount - idleProjection.layoutPassCount} submit_delta=${afterIdleProjection.nativeSubmissionCount - idleProjection.nativeSubmissionCount}")
    // One real staged-node failure retains the accepted scene; the next
    // explicit retry must commit normally rather than leaking a staged array.
    let acceptedBeforeFailure = window.displayedSceneVersion()
    controller.advance("local_color")
    let forced = unsafe { cjgui_internal_renderer_test_set_composable_scene_node_failures(window.testSessionToken(), 1u32) }
    let failed = window.refresh()
    let acceptedAfterFailure = window.displayedSceneVersion()
    let recovered = window.refresh()
    println("CJGUI_SCENE_SCALE_RECOVERY mode=${mode} requested_nodes=${requestedNodes} forced=${forced == CJGUI_INTERNAL_RENDERER_OK} failed=${failed} retained=${acceptedAfterFailure == acceptedBeforeFailure} recovered=${recovered} accepted_after=${window.displayedSceneVersion()}")
    let valid = forced == CJGUI_INTERNAL_RENDERER_OK && !failed && acceptedAfterFailure == acceptedBeforeFailure && recovered
    window.close()
    return valid
}

main(args: Array<String>): Int64 {
    if (args.size != 0) { return 2 }
    let sizes = ArrayList<Int64>([32, 256, 960])
    let modes = ArrayList<String>(["local_color", "component_add_remove", "reorder", "image_replace", "resize"])
    for (size in sizes) {
        for (mode in modes) {
            if (!runMode(size, mode)) { return 3 }
        }
    }
    println("cjgui scene submission scale probe: passed")
    return 0
}

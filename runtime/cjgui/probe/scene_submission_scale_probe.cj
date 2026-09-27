package cjgui

import cjgui_shared_operation_core.*
import std.collection.*

import std.time.*

// This probe is compiled only with CJGUI_INTERNAL_TESTING. It measures a
// normal Cangjie controller/window transaction; native values are scalar
// counters, not Objective-C objects or a public renderer API.
//
// Mode families:
//   * legacy scene mutations   -- local_color / component_add_remove / reorder /
//                                 image_replace / resize (unchanged behaviour);
//   * effect comparison        -- no_effect / effect_static.  Both build the
//                                 exact same node tree (count, sizes, depth and
//                                 surface styling); only the shadow/gradient
//                                 declarations differ, so the difference measures
//                                 the effects themselves;
//   * animation_active         -- effect_static plus a live paint-alpha
//                                 animation advanced by an explicit timestamp
//                                 per sample, followed by a stop-and-converge
//                                 idleness measurement.
foreign {
    func cjgui_internal_renderer_test_composable_scene_submission_stats(
        session: UInt64, outCloneCount: CPointer<UInt64>, outNodeAllocationCount: CPointer<UInt64>,
        outConfigureMicros: CPointer<UInt64>, outSetMicros: CPointer<UInt64>, outCommitMicros: CPointer<UInt64>
    ): Int32
    func cjgui_internal_renderer_test_set_composable_scene_node_failures(session: UInt64, failureCount: UInt32): Int32
    func cjgui_internal_renderer_test_resize_composable_window(session: UInt64, outResizeVersion: CPointer<UInt64>): Int32
    // Latest submitted composable frame's encoder-work scalars: how many
    // nodes/batches actually carried shape geometry, how many explicit texture
    // draws crossed painter order, and the generic shape vertex bytes.  These
    // are per-frame observations, not cumulative totals, and never expose a
    // Metal object.
    func cjgui_internal_renderer_test_composable_encoder_stats(
        session: UInt64, outShapeNodeCount: CPointer<UInt32>, outShapeBatchCount: CPointer<UInt32>,
        outTextureDrawCount: CPointer<UInt32>, outShapeVertexBytes: CPointer<UInt64>
    ): Int32
    // Actual generic vertex stride and largest single setVertexBytes submission.
    // Total shapeVertexBytes may span several ordered submissions at the
    // documented Metal 4 KiB input ceiling, so the largest single upload is
    // reported separately instead of being inferred.
    func cjgui_internal_renderer_test_composable_encoder_batch_stats(
        session: UInt64, outVertexStride: CPointer<UInt32>, outMaxShapeBatchVertexBytes: CPointer<UInt64>
    ): Int32
    // Cumulative text-work counters (TESTING-only). Raster is the offscreen
    // bitmap + normalization pass; upload is the texture replaceRegion pass.
    // A paint-alpha change must be a draw-time multiplier, so neither counter
    // may advance while only the alpha animation is being advanced.
    func cjgui_internal_renderer_test_composable_text_work_stats(
        session: UInt64, outRasterCount: CPointer<UInt64>, outRasterBytes: CPointer<UInt64>,
        outRasterMicros: CPointer<UInt64>, outUploadCount: CPointer<UInt64>, outUploadBytes: CPointer<UInt64>,
        outUploadMicros: CPointer<UInt64>
    ): Int32
}

// Deterministic explicit animation clock step.  30 samples * 16 ms = 480 ms of
// animation; the 600 ms tween is retargeted every sample, so the channel stays
// active for the whole window instead of settling mid-run.
private let CJGUI_SCENE_SCALE_ANIMATION_STEP_MS: Int64 = 16
private let CJGUI_SCENE_SCALE_SAMPLE_COUNT: Int64 = 30
private let CJGUI_SCENE_SCALE_ANIMATION_ROW_COUNT: Int64 = 4

private func sceneScaleAnimationIdentity(logical: Int64): String {
    // Matches CjguiComposableUiLayoutNode.identityKeyFor: a node with a semantic
    // id is addressed as "semantic:<semanticId>".
    return "semantic:scene-scale-row-${logical}"
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

private class CjguiSceneEncoderStats {
    let status: Int32
    let shapeNodes: UInt32
    let shapeBatches: UInt32
    let textureDraws: UInt32
    let shapeVertexBytes: UInt64
    let vertexStride: UInt32
    let maxShapeBatchVertexBytes: UInt64
    init(status: Int32, shapeNodes: UInt32, shapeBatches: UInt32, textureDraws: UInt32, shapeVertexBytes: UInt64,
        vertexStride: UInt32, maxShapeBatchVertexBytes: UInt64) {
        this.status = status
        this.shapeNodes = shapeNodes
        this.shapeBatches = shapeBatches
        this.textureDraws = textureDraws
        this.shapeVertexBytes = shapeVertexBytes
        this.vertexStride = vertexStride
        this.maxShapeBatchVertexBytes = maxShapeBatchVertexBytes
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

private func encoderStats(window: CjguiComposableUiWindow): CjguiSceneEncoderStats {
    var shapeNodes: UInt32 = 0u32
    var shapeBatches: UInt32 = 0u32
    var textureDraws: UInt32 = 0u32
    var shapeVertexBytes: UInt64 = 0u64
    let infoStatus = unsafe {
        cjgui_internal_renderer_test_composable_encoder_stats(window.testSessionToken(), inout shapeNodes,
            inout shapeBatches, inout textureDraws, inout shapeVertexBytes)
    }
    var vertexStride: UInt32 = 0u32
    var maxShapeBatchVertexBytes: UInt64 = 0u64
    let batchStatus = unsafe {
        cjgui_internal_renderer_test_composable_encoder_batch_stats(window.testSessionToken(), inout vertexStride,
            inout maxShapeBatchVertexBytes)
    }
    let status = if (infoStatus == CJGUI_INTERNAL_RENDERER_OK) { batchStatus } else { infoStatus }
    return CjguiSceneEncoderStats(status, shapeNodes, shapeBatches, textureDraws, shapeVertexBytes, vertexStride,
        maxShapeBatchVertexBytes)
}

private class CjguiSceneTextWork {
    let status: Int32
    let rasterCount: UInt64
    let rasterBytes: UInt64
    let uploadCount: UInt64
    let uploadBytes: UInt64
    init(status: Int32, rasterCount: UInt64, rasterBytes: UInt64, uploadCount: UInt64, uploadBytes: UInt64) {
        this.status = status
        this.rasterCount = rasterCount
        this.rasterBytes = rasterBytes
        this.uploadCount = uploadCount
        this.uploadBytes = uploadBytes
    }
}

private func textWorkStats(window: CjguiComposableUiWindow): CjguiSceneTextWork {
    var rasterCount: UInt64 = 0u64
    var rasterBytes: UInt64 = 0u64
    var rasterMicros: UInt64 = 0u64
    var uploadCount: UInt64 = 0u64
    var uploadBytes: UInt64 = 0u64
    var uploadMicros: UInt64 = 0u64
    let status = unsafe {
        cjgui_internal_renderer_test_composable_text_work_stats(window.testSessionToken(), inout rasterCount,
            inout rasterBytes, inout rasterMicros, inout uploadCount, inout uploadBytes, inout uploadMicros)
    }
    return CjguiSceneTextWork(status, rasterCount, rasterBytes, uploadCount, uploadBytes)
}

private class SceneSubmissionScaleController <: CjguiComposableUiController {
    private let baseNodeCount: Int64
    // Surface styling (background + rounded corners) is shared by the three
    // comparison modes so that no_effect and effect_static differ ONLY in the
    // shadow/gradient declarations.  Legacy modes keep their original tree.
    private let surfaceStyling: Bool
    private let effectEnabled: Bool
    private var revision: Int64
    private var accent: Bool
    private var extraNode: Bool
    private var reverseRows: Bool
    private var imageVersion: Int64

    init(baseNodeCount: Int64, surfaceStyling: Bool, effectEnabled: Bool) {
        this.baseNodeCount = baseNodeCount
        this.surfaceStyling = surfaceStyling
        this.effectEnabled = effectEnabled
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
            let textColor = if (isAccent) { CjguiComposableUiColor(0.85, 0.15, 0.15, 1.0) } else {
                CjguiComposableUiColor(0.85, 0.85, 0.85, 1.0)
            }
            root.add(cjguiComposableText(701000 + logical, "scene-scale-row-${logical}",
                if (logical == 0) { if (isAccent) { "accent-on" } else { "accent-off" } } else { "row-${logical}" },
                rowStyle(logical, textColor)))
            position += 1
        }
        return root
    }

    /// A row's style.  The legacy branch is byte-for-byte the original style.
    /// The comparison branch adds one on-screen surface (background plus an
    /// alternating rectangular/rounded silhouette); the effect variants only
    /// toggle the shadow and gradient declarations on top of it, keeping node
    /// count, sizes and hierarchy identical across no_effect/effect_static/
    /// animation_active.
    private func rowStyle(logical: Int64, textColor: CjguiComposableUiColor): CjguiComposableUiStyle {
        if (!surfaceStyling) {
            return CjguiComposableUiStyle(fixedHeight: 14, fontSize: 10.0, textColor: textColor)
        }
        let rounded = logical % 2 != 0
        let shadow: ?CjguiComposableUiShadowStyle = if (effectEnabled &&
            logical < CJGUI_SCENE_SCALE_ANIMATION_ROW_COUNT) {
            Some(CjguiComposableUiShadowStyle(color: CjguiComposableUiColor(0.0, 0.0, 0.0, 0.35), offsetX: 0,
                offsetY: 2, blurRadius: 8, spread: 0))
        } else {
            None
        }
        let gradient: ?CjguiComposableUiLinearGradient = if (effectEnabled && (logical == 0 || logical == 2)) {
            Some(CjguiComposableUiLinearGradient(startX: 0.0, startY: 0.0, endX: 1.0, endY: 1.0,
                stops: [
                    CjguiComposableUiGradientStop(position: 0.0, color: CjguiComposableUiColor(0.20, 0.42, 0.78, 1.0)),
                    CjguiComposableUiGradientStop(position: 1.0, color: CjguiComposableUiColor(0.10, 0.18, 0.36, 1.0))]))
        } else {
            None
        }
        return CjguiComposableUiStyle(background: CjguiComposableUiColor(0.16, 0.17, 0.20, 1.0), textColor: textColor,
            fixedHeight: 14, fontSize: 10.0, cornerRadius: if (rounded) { 6 } else { 0 }, shadow: shadow,
            gradient: gradient)
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
        if (mode == "local_color" || mode == "no_effect" || mode == "effect_static") {
            // The effect-comparison modes drive the same visible mutation as the
            // legacy local_color baseline (an accent text-colour flip).  Node
            // tree, sizes, hierarchy and mutation sequence are identical; only
            // the shadow/gradient declarations differ, and every sample still
            // produces a real native submission instead of being skipped as an
            // unchanged output.
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
    after: CjguiSceneSubmissionStats, encoder: CjguiSceneEncoderStats,
    projection: CjguiSharedOperationWindowProjection, window: CjguiComposableUiWindow): Unit {
    println("CJGUI_SCENE_SCALE_SAMPLE mode=${mode} requested_nodes=${requestedNodes} sample=${sample} committed_nodes=${projection.nodes.size} clone_delta=${after.clones - before.clones} allocation_delta=${after.allocations - before.allocations} configure_us=${after.configureMicros - before.configureMicros} setter_us=${after.setMicros - before.setMicros} commit_us=${after.commitMicros - before.commitMicros} build_ms=${projection.lastBuildElapsedMs} layout_ms=${projection.lastLayoutElapsedMs} stage_submit_ms=${projection.lastNativeStageAndSubmitElapsedMs} submitted_frame=${projection.submittedFrameIndex} metal_completed=${projection.observedMetalCompletionFrameIndex} metal_gpu_us=${projection.observedMetalGpuDurationMicros} shape_nodes=${encoder.shapeNodes} shape_batches=${encoder.shapeBatches} texture_draws=${encoder.textureDraws} shape_vertex_bytes=${encoder.shapeVertexBytes} vertex_stride=${encoder.vertexStride} max_shape_batch_vertex_bytes=${encoder.maxShapeBatchVertexBytes} encoder_ok=${if (encoder.status == CJGUI_INTERNAL_RENDERER_OK) { 1 } else { 0 }} anim_bound=${window.animationBindingCount()} anim_active=${window.activeAnimationCount()}")
}

private func runMode(requestedNodes: Int64, mode: String): Bool {
    let surfaceStyling = mode == "no_effect" || mode == "effect_static" || mode == "animation_active"
    let effectEnabled = mode == "effect_static" || mode == "animation_active"
    let controller = SceneSubmissionScaleController(requestedNodes, surfaceStyling, effectEnabled)
    let window = CjguiComposableUiWindow(controller)
    if (!window.start()) { window.close(); return false }
    let initial = window.windowProjection()
    if (initial.nodes.size != requestedNodes || initial.submittedFrameIndex <= 0) { window.close(); return false }
    // Deterministic animation clock: every sample feeds an explicit timestamp
    // derived from one base instant, never the wall clock of the loop.
    let animationBase = MonoTime.now()
    let animationSpec = CjguiComposableUiAnimationSpec.tween(durationMs: 600,
        easing: CjguiComposableUiAnimationEasing.EASE_IN_OUT)
    // Text work must not advance while only the paint alpha is animated: a
    // per-frame alpha change is a draw multiplier, not a re-raster/re-upload.
    var previousTextWork: ?CjguiSceneTextWork = None
    var textRasterDelta: UInt64 = 0u64
    var textUploadDelta: UInt64 = 0u64
    var textWorkFrames: Int64 = 0
    var textWorkOk = true
    var sample: Int64 = 0
    while (sample < CJGUI_SCENE_SCALE_SAMPLE_COUNT) {
        let before = submissionStats(window)
        if (before.status != CJGUI_INTERNAL_RENDERER_OK) { window.close(); return false }
        if (mode == "resize") {
            var resizeVersion: UInt64 = 0u64
            let resize = unsafe { cjgui_internal_renderer_test_resize_composable_window(window.testSessionToken(), inout resizeVersion) }
            if (resize != CJGUI_INTERNAL_RENDERER_OK || resizeVersion == 0u64) { window.close(); return false }
            if (!window.refreshIfNeeded()) { window.close(); return false }
        } else if (mode == "animation_active") {
            // Retarget from the current presented value every sample and advance
            // by one explicit step, so the channel stays active for the whole
            // 30-sample window instead of settling after the first tween.
            let retargetAt = animationBase + Duration.millisecond * (sample * CJGUI_SCENE_SCALE_ANIMATION_STEP_MS)
            let advanceAt = animationBase + Duration.millisecond * ((sample + 1) * CJGUI_SCENE_SCALE_ANIMATION_STEP_MS)
            let target = if (sample % 2 == 0) { 0.35 } else { 1.0 }
            var row: Int64 = 0
            while (row < CJGUI_SCENE_SCALE_ANIMATION_ROW_COUNT) {
                let bound = window.animateNodeOpacity(sceneScaleAnimationIdentity(row), target,
                    spec: animationSpec, atTime: retargetAt)
                if (!bound) { window.close(); return false }
                row += 1
            }
            if (!window.advanceAnimations(atTime: advanceAt)) { window.close(); return false }
        } else {
            controller.advance(mode)
            if (!window.refresh()) { window.close(); return false }
        }
        let after = submissionStats(window)
        let encoder = encoderStats(window)
        let projection = window.windowProjection()
        if (mode == "animation_active") {
            let textWork = textWorkStats(window)
            if (textWork.status == CJGUI_INTERNAL_RENDERER_OK) {
                match (previousTextWork) {
                    case Some(previous) =>
                        textRasterDelta += textWork.rasterCount - previous.rasterCount
                        textUploadDelta += textWork.uploadCount - previous.uploadCount
                        textWorkFrames += 1
                    case None => ()
                }
                previousTextWork = Some(textWork)
            } else {
                textWorkOk = false
            }
        }
        if (after.status != CJGUI_INTERNAL_RENDERER_OK || projection.nodes.size < requestedNodes ||
            projection.submittedFrameIndex <= initial.submittedFrameIndex) { window.close(); return false }
        printSample(mode, requestedNodes, sample, before, after, encoder, projection, window)
        sample += 1
    }
    // Stop-and-converge measurement: cancel every paint-alpha channel, then
    // prove that the next explicit animation advance returns no active work and
    // that an ordinary refresh commits nothing.  submitted_frame_delta is the
    // change of the submitted-frame index (not a frame-request counter), and it
    // must be zero together with the build/layout/submit deltas.
    var animationStopValid = true
    if (mode == "animation_active") {
        let activePreStop = window.activeAnimationCount()
        var cancelled = true
        var row: Int64 = 0
        while (row < CJGUI_SCENE_SCALE_ANIMATION_ROW_COUNT) {
            if (!window.cancelNodeOpacityAnimation(sceneScaleAnimationIdentity(row))) { cancelled = false }
            row += 1
        }
        let stopBefore = submissionStats(window)
        let stopBeforeProjection = window.windowProjection()
        let activeAfterCancel = window.activeAnimationCount()
        let advancedReturn = window.advanceAnimations(atTime: animationBase + Duration.millisecond *
            ((CJGUI_SCENE_SCALE_SAMPLE_COUNT + 1) * CJGUI_SCENE_SCALE_ANIMATION_STEP_MS))
        let stopAccepted = window.refreshIfNeeded()
        let activeAfterAdvance = window.activeAnimationCount()
        let stopAfter = submissionStats(window)
        let stopAfterProjection = window.windowProjection()
        let submittedFrameDelta = stopAfterProjection.submittedFrameIndex - stopBeforeProjection.submittedFrameIndex
        let cloneDelta = stopAfter.clones - stopBefore.clones
        let allocationDelta = stopAfter.allocations - stopBefore.allocations
        let configureDelta = stopAfter.configureMicros - stopBefore.configureMicros
        let setterDelta = stopAfter.setMicros - stopBefore.setMicros
        let commitDelta = stopAfter.commitMicros - stopBefore.commitMicros
        let buildDelta = stopAfterProjection.buildPassCount - stopBeforeProjection.buildPassCount
        let layoutDelta = stopAfterProjection.layoutPassCount - stopBeforeProjection.layoutPassCount
        let submitDelta = stopAfterProjection.nativeSubmissionCount - stopBeforeProjection.nativeSubmissionCount
        println("CJGUI_SCENE_SCALE_ANIMATION_STOP mode=${mode} requested_nodes=${requestedNodes} active_pre_stop=${activePreStop} cancelled=${if (cancelled) { 1 } else { 0 }} active_after_cancel=${activeAfterCancel} advanced_return=${if (advancedReturn) { 1 } else { 0 }} active_after_advance=${activeAfterAdvance} accepted=${stopAccepted} clone_delta=${cloneDelta} allocation_delta=${allocationDelta} configure_us=${configureDelta} setter_us=${setterDelta} commit_us=${commitDelta} build_delta=${buildDelta} layout_delta=${layoutDelta} submit_delta=${submitDelta} submitted_frame_delta=${submittedFrameDelta}")
        animationStopValid = activePreStop > 0 && cancelled && activeAfterCancel == 0 && !advancedReturn &&
            activeAfterAdvance == 0 && stopAccepted && submittedFrameDelta == 0 && cloneDelta == 0 && allocationDelta == 0 &&
            configureDelta == 0 && setterDelta == 0 && commitDelta == 0 && buildDelta == 0 && layoutDelta == 0 &&
            submitDelta == 0
    }
    // Text-work stability: after the first animated frame the text was already
    // rasterized/uploaded; every later frame only changes the paint alpha, so
    // both text-work counters must stay put. This is the work-boundary assertion
    // the Cangjie unit tests cannot make (the TESTING-only text-work ABI is not
    // linked into `cjpm test`).
    if (mode == "animation_active") {
        let textWorkFrameValid = textWorkOk && textWorkFrames > 0 && textRasterDelta == 0u64 && textUploadDelta == 0u64
        println("CJGUI_SCENE_SCALE_TEXT_WORK mode=${mode} requested_nodes=${requestedNodes} frames=${textWorkFrames} " +
            "raster_delta=${textRasterDelta} upload_delta=${textUploadDelta} text_ok=${if (textWorkFrameValid) { 1 } else { 0 }}")
        if (!textWorkFrameValid) { animationStopValid = false }
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
    return valid && animationStopValid
}

private func defaultModes(): ArrayList<String> {
    return ArrayList<String>(["local_color", "component_add_remove", "reorder", "image_replace", "resize",
        "no_effect", "effect_static", "animation_active"])
}

// The runner may select a subset with `--modes=a,b,c` so that the legacy
// baseline and the new comparison modes can be run (and reported) separately.
// No arguments keeps the full default set, preserving the original invocation.
main(args: Array<String>): Int64 {
    let sizes = ArrayList<Int64>([32, 256, 960])
    let modes = ArrayList<String>()
    if (args.size == 0) {
        for (mode in defaultModes()) { modes.add(mode) }
    } else {
        var index = 0
        while (index < args.size) {
            let parts = args[index].split("=")
            if (parts.size == 2 && parts[0] == "--modes") {
                for (part in parts[1].split(",")) {
                    if (part.size > 0) { modes.add(part) }
                }
            } else {
                return 2
            }
            index += 1
        }
    }
    if (modes.size == 0) { return 2 }
    for (size in sizes) {
        for (mode in modes) {
            if (!runMode(size, mode)) { return 3 }
        }
    }
    println("cjgui scene submission scale probe: passed")
    return 0
}

package cjgui_rule_set_window_app

import cjgui.*
import cjgui_rule_set_application.*
import std.env.*
import std.time.*

// Opt-in workload declaration over the existing catalog and original owner.
// The ordinary startup remains empty; no separate performance data store.
func seedRuleSetPerformanceScene(region: CjguiRuleSetGeneratedRegion): Bool {
    let payload = "GENERATED_UI_STRUCTURE 1\nNODE 0 perfForm vertical\n" +
        "NODE 1 perfName textInput field=label\nPROPERTY 1 perfName label 生成名称\n" +
        "NODE 1 perfEnabled booleanInput field=enabled\nPROPERTY 1 perfEnabled label 生成启用\n" +
        "NODE 1 perfRetention integerInput field=retentionCount\nPROPERTY 1 perfRetention label 生成保留数\n" +
        "NODE 1 perfBeacon image\nPROPERTY 1 perfBeacon resource rule-set-beacon\n" +
        "PROPERTY 1 perfBeacon resourceVersion 1\nPROPERTY 1 perfBeacon fixedHeight 48\nEND"
    return region.submitStructure(payload, region.acceptedStructureVersion()).candidateAccepted
}

// Sparse boundary observations reuse diagnosticSnapshot and its collection
// settings. No per-frame output, timer, or second diagnostic protocol.
class RuleSetCostObservation {
    private let window: CjguiComposableUiWindow
    private let domain: CjguiRuleSetEditingDomain
    private var enabled: Bool
    private let originalWorkload: Bool
    private let originalTiming: Bool
    private var samples: Int64 = 0
    private var lastOwner: Int64 = -1
    private var lastFrame: Int64 = -1
    private var lastSample: MonoTime = MonoTime.now()

    init(window: CjguiComposableUiWindow, domain: CjguiRuleSetEditingDomain, enabled: Bool) {
        this.window = window
        this.domain = domain
        this.enabled = enabled
        let settings = window.diagnosticCollectionSettings()
        originalWorkload = settings[0]
        originalTiming = settings[1]
        if (enabled) {
            let workload = window.setWorkloadDiagnostics(true)
            let timing = window.setTimingDiagnostics(true)
            getStdOut().writeln("RULE_SET_COST_ENABLED workload=${workload} timing=${timing}")
        }
    }

    func sample(phase: String): Unit {
        if (!enabled || samples >= 96 || !window.isOpen()) { return }
        let s = window.diagnosticSnapshot(maximumNodes: 1)
        samples += 1
        getStdOut().writeln("RULE_SET_COST sample=${samples} phase=${phase} owner=${domain.version()} status=${s.status} scene=${s.acceptedSceneVersion} submitted=${s.submittedSceneVersion} frame=${s.submittedFrameIndex} completed=${s.completedFrameIndex} failed=${s.failedFrameIndex} gpu_us=${s.gpuDurationMicros} nodes=${s.totalNodes} builds=${s.buildPassCount} layouts=${s.layoutPassCount} submissions=${s.nativeSubmissionCount} build_ns=${s.totalBuildNanoseconds} layout_ns=${s.totalLayoutNanoseconds} native_ns=${s.totalNativeStageAndSubmitNanoseconds} writes=${s.nodeWriteCount} clones=${s.nodeCloneCount} allocations=${s.nodeAllocationCount} text_preparations=${s.textLayoutPreparationCount} line_builds=${s.positionLineBuildCount} line_hits=${s.positionCacheHitCount} raster_count=${s.textRasterCount} raster_bytes=${s.textRasterBytes} raster_us=${s.textRasterMicros} upload_count=${s.textUploadCount} upload_bytes=${s.textUploadBytes} upload_us=${s.textUploadMicros} text_live=${s.textTextureLiveBytes} text_candidate_peak=${s.textCandidatePeakBytes} reusable=${s.reusableResourceBytes} effect_live=${s.effectLiveBytes} effect_cached=${s.effectCachedBytes} effect_flight=${s.effectInFlightBytes} timing_reads=${s.timingReadCount} timing_read_ns=${s.timingReadNanoseconds}")
        getStdOut().flush()
        lastOwner = domain.version()
        lastFrame = s.submittedFrameIndex
        lastSample = MonoTime.now()
    }

    func poll(): Unit {
        if (!enabled || samples >= 96 || !window.isOpen()) { return }
        let owner = domain.version()
        if (owner != lastOwner) { sample("owner"); return }
        if ((MonoTime.now() - lastSample).toMilliseconds() >= 1000 &&
            window.windowProjection().submittedFrameIndex != lastFrame) { sample("activity") }
    }

    func finish(): Unit {
        if (!enabled) { return }
        sample("before_close")
        enabled = false
        if (window.isOpen()) {
            let _ = window.setWorkloadDiagnostics(originalWorkload)
            let _ = window.setTimingDiagnostics(originalTiming)
        }
    }
}

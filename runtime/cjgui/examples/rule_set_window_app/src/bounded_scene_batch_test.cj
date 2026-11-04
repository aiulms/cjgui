// Bounded scene-transfer counterexamples.
//
// A candidate that does not fit one owner-thread chunk must yield at a
// resumable boundary, keep the accepted scene live, and continue on later
// owner turns. A native per-slot failure after earlier slots were staged must
// discard the candidate generation, and a close mid-transfer must never commit
// the late chunks. These tests use the existing window/host entry and the
// testing-only native seams; no production flag is introduced.
package cjgui_rule_set_window_app

import cjgui.*
import std.collection.*
import std.overflow.*
import std.posix.*
import std.time.*
import std.unittest.*
import std.unittest.testmacro.*

foreign func setenv(name: CString, value: CString, overwrite: Int32): Int32

foreign {
    func cjgui_internal_renderer_test_set_scene_batch_fail_after(after: UInt32): Unit
    func cjgui_internal_renderer_test_reset_scene_batch_chunk_calls(): Unit
    func cjgui_internal_renderer_test_scene_batch_chunk_calls(): UInt32
    func cjgui_internal_renderer_test_scene_batch_chunk_last_count(): UInt32
    func cjgui_internal_renderer_test_scene_batch_chunk_max_count(): UInt32
    func cjgui_internal_renderer_test_scene_batch_chunk_last_string_bytes(): UInt64
    func cjgui_internal_renderer_test_scene_batch_chunk_max_string_bytes(): UInt64
    func cjgui_internal_renderer_test_scene_batch_chunk_total_string_bytes(): UInt64
    func cjgui_internal_renderer_test_scene_batch_chunk_last_payload_bytes(): UInt32
    func cjgui_internal_renderer_test_staged_scene_node_row_key_hash(nodeIndex: UInt32,
        outLength: CPointer<UInt64>): UInt64
    func cjgui_internal_renderer_test_staged_scene_candidate_nodes(): UInt32
}

private func boundedBatchResetChunks(): Unit {
    unsafe { cjgui_internal_renderer_test_reset_scene_batch_chunk_calls() }
}

private func boundedBatchChunkCalls(): UInt32 {
    return unsafe { cjgui_internal_renderer_test_scene_batch_chunk_calls() }
}

private func boundedBatchStagedNodes(): UInt32 {
    return unsafe { cjgui_internal_renderer_test_staged_scene_candidate_nodes() }
}

private func boundedBatchChunkMaxCount(): UInt32 {
    return unsafe { cjgui_internal_renderer_test_scene_batch_chunk_max_count() }
}

private func boundedBatchChunkMaxStringBytes(): UInt64 {
    return unsafe { cjgui_internal_renderer_test_scene_batch_chunk_max_string_bytes() }
}

private func boundedBatchChunkLastStringBytes(): UInt64 {
    return unsafe { cjgui_internal_renderer_test_scene_batch_chunk_last_string_bytes() }
}

private func boundedBatchChunkTotalStringBytes(): UInt64 {
    return unsafe { cjgui_internal_renderer_test_scene_batch_chunk_total_string_bytes() }
}

private func boundedBatchChunkLastPayloadBytes(): UInt32 {
    return unsafe { cjgui_internal_renderer_test_scene_batch_chunk_last_payload_bytes() }
}

private func boundedBatchStagedRowKey(nodeIndex: UInt32): (UInt64, UInt64) {
    var length: UInt64 = 0u64
    let hash = unsafe {
        cjgui_internal_renderer_test_staged_scene_node_row_key_hash(nodeIndex, inout length)
    }
    return (hash, length)
}

private func boundedBatchRowKeyHash(text: String): UInt64 {
    var hash: UInt64 = 14695981039346656037
    for (value in text.toArray()) {
        hash = (hash ^ UInt64(value)).wrappingMul(1099511628211)
    }
    return hash
}

private func boundedBatchFailAfter(value: UInt32): Unit {
    unsafe { cjgui_internal_renderer_test_set_scene_batch_fail_after(value) }
}

private func boundedBatchEnv(name: String, value: String): Unit {
    unsafe {
        let key = LibC.mallocCString(name)
        let text = LibC.mallocCString(value)
        let _ = setenv(key, text, 1)
    }
}

private func boundedBatchLargeText(bytes: Int64): String {
    return String.fromUtf8(Array<Byte>(bytes, repeat: 97u8))
}

private func boundedBatchLargeKey(index: Int64, bytes: Int64): String {
    let prefix = "K${index}:"
    let prefixBytes = prefix.toArray().size
    if (bytes <= Int64(prefixBytes)) {
        return prefix
    }
    return prefix + String.fromUtf8(Array<Byte>(bytes - Int64(prefixBytes), repeat: 97u8))
}

private class CjguiBoundedBatchController <: CjguiComposableUiController {
    private var versionValue: Int64 = 1
    public var nodeCount: Int64 = 7
    public var suffix: String = ""
    public var rowKey: String = ""
    public var help: String = ""
    // Independent, legal per-node identity fields for the cross-byte budget.
    public var largeRowKeyBytes: Int64 = 0

    public func bump(): Unit {
        versionValue += 1
    }

    public func uiSceneVersion(): Int64 {
        return versionValue
    }

    public func buildUi(): CjguiComposableUiNode {
        let root = cjguiComposableVertical(1, "batch-root", CjguiComposableUiStyle())
        var index: Int64 = 0
        while (index < nodeCount) {
            let nodeId = index + 2
            let label = "L${index}${suffix}"
            let semanticKey = if (largeRowKeyBytes > 0) {
                boundedBatchLargeKey(index, largeRowKeyBytes)
            } else if (index == 0) {
                rowKey
            } else {
                ""
            }
            root.add(CjguiComposableUiNode(nodeId, "batch-${index}", CJGUI_COMPOSABLE_UI_BUTTON, label, label,
                "BATCH_${index}", -1, CjguiComposableUiStyle(fixedHeight: 24),
                semanticKey: semanticKey,
                semanticHelp: if (index == 0) { help } else { "" }))
            index += 1
        }
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

private func boundedBatchPumpAccepted(host: CjguiMacosApplicationHost, window: CjguiComposableUiWindow,
    atLeast!: Int64 = 1, turns!: Int64 = 128): Bool {
    var count: Int64 = 0
    while (count < turns) {
        let progress = window.windowProgress()
        if (progress.acceptedSceneVersion >= atLeast && progress.pendingRefreshReason == "none") {
            return true
        }
        if (!host.isOpen() || !window.isOpen()) {
            break
        }
        let _ = host.pumpOneTurn()
        count += 1
    }
    let progress = window.windowProgress()
    return progress.acceptedSceneVersion >= atLeast && progress.pendingRefreshReason == "none"
}

@Test
func boundedBatchYieldsAndAnotherWindowKeepsProgressing(): Unit {
    cjguiMacosOwnerTest({
        =>
        // A must stay mid-candidate across owner turns, so it needs many more
        // chunks than one turn can drain; B is deliberately small.
        boundedBatchEnv("CJGUI_SCENE_BATCH_CHUNK_NODES", "2")
        let first = CjguiBoundedBatchController()
        first.nodeCount = 600
        let second = CjguiBoundedBatchController()
        second.nodeCount = 3
        let hostA = CjguiMacosApplicationHost(first,
            configuration: CjguiMacosApplicationWindowConfiguration("Bounded batch A", 900u32, 620u32))
        let hostB = CjguiMacosApplicationHost(second,
            configuration: CjguiMacosApplicationWindowConfiguration("Bounded batch B", 760u32, 480u32))
        let windowA = hostA.window()
        let windowB = hostB.window()
        boundedBatchResetChunks()
        try {
            @Assert(hostA.start(), true)
            @Assert(hostB.start(), true)
            let _ = windowA.refresh()
            let _ = windowB.refresh()
            var servedSecondWhileFirstPending = false
            var turns: Int64 = 0
            while (turns < 2400) {
                let firstProgress = windowA.windowProgress()
                let secondProgress = windowB.windowProgress()
                if (!servedSecondWhileFirstPending && firstProgress.acceptedSceneVersion <= 0 &&
                    secondProgress.acceptedSceneVersion > 0) {
                    servedSecondWhileFirstPending = true
                }
                if (firstProgress.acceptedSceneVersion > 0 && secondProgress.acceptedSceneVersion > 0) {
                    break
                }
                let _ = hostA.pumpOneTurn()
                let _ = hostB.pumpOneTurn()
                turns += 1
            }
            let progressA = windowA.windowProgress()
            let progressB = windowB.windowProgress()
            let statusA = "A accepted=${progressA.acceptedSceneVersion} submitted=${progressA.submittedSceneVersion} " +
                "pending=${progressA.pendingRefreshReason} failure=${progressA.lastNativeFailure} turns=${turns}"
            let statusB = "B accepted=${progressB.acceptedSceneVersion} submitted=${progressB.submittedSceneVersion} " +
                "pending=${progressB.pendingRefreshReason} failure=${progressB.lastNativeFailure}"
            println(statusA)
            println(statusB)
            @Assert(progressA.acceptedSceneVersion > 0 && progressA.pendingRefreshReason == "none" && progressA.lastNativeFailure == "none", true)
            @Assert(progressB.acceptedSceneVersion > 0 && progressB.pendingRefreshReason == "none" && progressB.lastNativeFailure == "none", true)
            println("fairness served=${servedSecondWhileFirstPending} chunks=${boundedBatchChunkCalls()}")
            @Assert(boundedBatchChunkCalls() >= 20, true)
            @Assert(servedSecondWhileFirstPending, true)
        } finally {
            windowA.close()
            windowB.close()
        }
    })
}
@Test
func boundedBatchYieldsBeforeCompletionThenResumes(): Unit {
    cjguiMacosOwnerTest({
        =>
        boundedBatchEnv("CJGUI_SCENE_BATCH_CHUNK_NODES", "2")
        boundedBatchEnv("CJGUI_PREPARE_FAILURE_TRACE", "1")
        let controller = CjguiBoundedBatchController()
        controller.nodeCount = 8
        let host = CjguiMacosApplicationHost(controller,
            configuration: CjguiMacosApplicationWindowConfiguration("Bounded batch resume", 900u32, 620u32))
        let window = host.window()
        try {
            @Assert(host.start(), true)
            let _ = window.refresh()
            let initialAccepted = boundedBatchPumpAccepted(host, window)
            let initialProgress = window.windowProgress()
            println("initial accepted=${initialAccepted} version=${initialProgress.acceptedSceneVersion} " +
                "submitted=${initialProgress.submittedSceneVersion} pending=${initialProgress.pendingRefreshReason} " +
                "failure=${initialProgress.lastNativeFailure}")
            @Assert(initialAccepted && initialProgress.pendingRefreshReason == "none" &&
                initialProgress.lastNativeFailure == "none", true)
            let accepted = window.windowProgress()
            controller.suffix = "-resume"
            controller.bump()
            let _ = window.refreshIfNeeded()
            var sawYield = false
            var turns: Int64 = 0
            while (turns < 64 && window.windowProgress().acceptedSceneVersion == accepted.acceptedSceneVersion) {
                if (window.windowProgress().pendingRefreshReason == "refresh_preparing_scene_batch") {
                    sawYield = true
                }
                if (!host.pumpOneTurn()) { break }
                turns += 1
            }
            @Assert(sawYield, true)
            @Assert(boundedBatchPumpAccepted(host, window, atLeast: accepted.acceptedSceneVersion + 1), true)
            @Assert(window.windowProgress().lastNativeFailure, "none")
        } finally {
            window.close()
        }
    })
}
@Test
func midBatchNativeFailureKeepsAcceptedSceneAndReleasesCandidate(): Unit {
    cjguiMacosOwnerTest({
        =>
        boundedBatchEnv("CJGUI_SCENE_BATCH_CHUNK_NODES", "2")
        let controller = CjguiBoundedBatchController()
        controller.nodeCount = 8
        let host = CjguiMacosApplicationHost(controller,
            configuration: CjguiMacosApplicationWindowConfiguration("Bounded batch failure", 900u32, 620u32))
        let window = host.window()
        try {
            @Assert(host.start(), true)
            let _ = window.refresh()
            @Assert(boundedBatchPumpAccepted(host, window), true)
            let accepted = window.windowProgress()
            // Fail the second successful per-slot write, after the first chunk was
            // already staged into this candidate generation.
            boundedBatchFailAfter(3)
            controller.suffix = "-fail"
            controller.bump()
            let _ = window.refreshIfNeeded()
            var failed = false
            var turns: Int64 = 0
            while (turns < 96) {
                let progress = window.windowProgress()
                if (progress.lastNativeFailure != "none") {
                    failed = true
                    break
                }
                if (!host.pumpOneTurn()) { break }
                turns += 1
            }
            @Assert(failed, true)
            @Assert(window.windowProgress().acceptedSceneVersion, accepted.acceptedSceneVersion)
            @Assert(window.windowProgress().submittedSceneVersion, accepted.submittedSceneVersion)
            @Assert(boundedBatchStagedNodes(), 0u32)
            // The next ordinary projection must build a fresh generation and be
            // accepted; no failed candidate is resumed.
            boundedBatchFailAfter(0)
            controller.suffix = "-recovered"
            controller.bump()
            let _ = window.refreshIfNeeded()
            @Assert(boundedBatchPumpAccepted(host, window, atLeast: accepted.acceptedSceneVersion + 1), true)
            @Assert(window.windowProgress().lastNativeFailure, "none")
        } finally {
            window.close()
        }
    })
}
@Test
func closingWindowMidBatchDoesNotCommitLateChunks(): Unit {
    cjguiMacosOwnerTest({
        =>
        boundedBatchEnv("CJGUI_SCENE_BATCH_CHUNK_NODES", "1")
        let controller = CjguiBoundedBatchController()
        controller.nodeCount = 9
        let host = CjguiMacosApplicationHost(controller,
            configuration: CjguiMacosApplicationWindowConfiguration("Bounded batch close", 900u32, 620u32))
        let window = host.window()
        try {
            @Assert(host.start(), true)
            let _ = window.refresh()
            @Assert(boundedBatchPumpAccepted(host, window), true)
            let accepted = window.windowProgress()
            controller.suffix = "-late"
            controller.bump()
            let _ = window.refreshIfNeeded()
            var sawPendingCandidate = false
            var turns: Int64 = 0
            while (turns < 32 && window.windowProgress().acceptedSceneVersion == accepted.acceptedSceneVersion) {
                if (window.windowProgress().pendingRefreshReason == "refresh_preparing_scene_batch") {
                    sawPendingCandidate = true
                }
                if (!host.pumpOneTurn()) { break }
                turns += 1
            }
            @Assert(sawPendingCandidate, true)
            window.close()
            var settleTurns: Int64 = 0
            while (settleTurns < 16 && window.isOpen()) {
                let _ = host.pumpOneTurn()
                settleTurns += 1
            }
            let finalVersion = window.windowProgress().acceptedSceneVersion
            println("close final accepted=${finalVersion} old=${accepted.acceptedSceneVersion}")
            @Assert(finalVersion == 0 || finalVersion == accepted.acceptedSceneVersion, true)
        } finally {
            window.close()
        }
    })
}
@Test
func oversizedStringIsRejectedBeforeTransfer(): Unit {
    cjguiMacosOwnerTest({
        =>
        boundedBatchEnv("CJGUI_SCENE_BATCH_CHUNK_NODES", "2")
        let controller = CjguiBoundedBatchController()
        controller.nodeCount = 3
        let host = CjguiMacosApplicationHost(controller,
            configuration: CjguiMacosApplicationWindowConfiguration("Bounded batch budget", 900u32, 620u32))
        let window = host.window()
        try {
            @Assert(host.start(), true)
            let _ = window.refresh()
            @Assert(boundedBatchPumpAccepted(host, window), true)
            let accepted = window.windowProgress()
            // One field above the native per-field limit is refused by the
            // pre-allocation check; the accepted scene and owner stay intact.
            controller.rowKey = boundedBatchLargeText(2 * 1024 * 1024 + 1)
            controller.bump()
            let _ = window.refreshIfNeeded()
            var failed = false
            var turns: Int64 = 0
            while (turns < 96) {
                if (window.windowProgress().lastNativeFailure != "none") {
                    failed = true
                    break
                }
                if (!host.pumpOneTurn()) { break }
                turns += 1
            }
            @Assert(failed, true)
            @Assert(window.windowProgress().lastNativeFailure, "text_resource_budget_exceeded")
            @Assert(window.windowProgress().acceptedSceneVersion, accepted.acceptedSceneVersion)
            @Assert(boundedBatchStagedNodes(), 0u32)
        } finally {
            window.close()
        }
    })
}
@Test
func legitimateStringsCrossBatchTotalsWithoutWholeSceneRefusal(): Unit {
    cjguiMacosOwnerTest({
        =>
        // Keep the default 512-node chunk. Eighteen children carry independent
        // legal identity fields of 500,000 bytes each (binding key + row key
        // are both sent); the row-key total alone exceeds 8 MiB, so only the
        // 2 MiB chunk string-byte gate can make this scene transferable.
        boundedBatchEnv("CJGUI_SCENE_BATCH_CHUNK_NODES", "512")
        let controller = CjguiBoundedBatchController()
        controller.nodeCount = 18
        controller.largeRowKeyBytes = 500000
        let host = CjguiMacosApplicationHost(controller,
            configuration: CjguiMacosApplicationWindowConfiguration("Bounded batch cross", 900u32, 620u32))
        let window = host.window()
        try {
            @Assert(host.start(), true)
            boundedBatchResetChunks()
            let _ = window.refresh()
            @Assert(boundedBatchPumpAccepted(host, window, turns: 256), true)
            let progress = window.windowProgress()
            let calls = boundedBatchChunkCalls()
            let maxCount = boundedBatchChunkMaxCount()
            let maxStringBytes = boundedBatchChunkMaxStringBytes()
            let totalStringBytes = boundedBatchChunkTotalStringBytes()
            let lastStringBytes = boundedBatchChunkLastStringBytes()
            let lastPayloadBytes = boundedBatchChunkLastPayloadBytes()
            println("cross-batch accepted=${progress.acceptedSceneVersion} calls=${calls} max_count=${maxCount} " +
                "max_string_bytes=${maxStringBytes} total_string_bytes=${totalStringBytes} " +
                "last_string_bytes=${lastStringBytes} last_payload=${lastPayloadBytes} " +
                "failure=${progress.lastNativeFailure}")
            @Assert(progress.acceptedSceneVersion > 0 && progress.pendingRefreshReason == "none" &&
                progress.lastNativeFailure == "none", true)
            // Nineteen transfer slots against the default 512-node chunk would
            // be one call without the byte gate; the byte gate must split this
            // scene into multiple multi-slot chunks, each within its 2 MiB
            // string budget.
            @Assert(calls >= 8u32, true)
            @Assert(maxCount >= 2u32 && maxCount <= 512u32, true)
            @Assert(maxStringBytes <= UInt64(2 * 1024 * 1024), true)
            @Assert(lastStringBytes <= UInt64(2 * 1024 * 1024), true)
            @Assert(totalStringBytes > UInt64(8 * 1024 * 1024), true)
            @Assert(lastPayloadBytes <= 2u32 * 1024u32 * 1024u32, true)
            // Every child's native row key must be the complete value, not a
            // truncated prefix from an earlier chunk.
            var index: Int64 = 1
            while (index <= controller.nodeCount) {
                let expected = boundedBatchLargeKey(index - 1, controller.largeRowKeyBytes)
                let expectedHash = boundedBatchRowKeyHash(expected)
                let (hash, length) = boundedBatchStagedRowKey(UInt32(index))
                let expectedLength = UInt64(expected.toArray().size)
                if (length != expectedLength || hash != expectedHash) {
                    println("cross-batch row key mismatch index=${index} length=${length} " +
                        "expected_length=${expectedLength} hash=${hash} expected_hash=${expectedHash}")
                }
                @Assert(length, expectedLength)
                @Assert(hash, expectedHash)
                index += 1
            }
        } finally {
            window.close()
        }
    })
}

@Test
func singleLegalEntryAboveSoftChunkBudgetStaysTransferable(): Unit {
    cjguiMacosOwnerTest({
        =>
        boundedBatchSoftFallback()
    })
}

private func boundedBatchSoftFallback(): Unit {
    boundedBatchEnv("CJGUI_SCENE_BATCH_CHUNK_NODES", "512")
    let controller = CjguiBoundedBatchController()
    controller.nodeCount = 2
    // One legal entry (identity field below the 2 MiB per-field limit) costs
    // about 2.7 MiB once its binding key and row key are both sent. It exceeds
    // the soft 2 MiB chunk budget on its own, so the soft gate must let that
    // single entry through as its own chunk instead of rejecting or dropping
    // previously legal content; the native 8 MiB per-call limit still bounds it.
    controller.largeRowKeyBytes = 1363149
    let host = CjguiMacosApplicationHost(controller,
        configuration: CjguiMacosApplicationWindowConfiguration("Bounded batch soft", 900u32, 620u32))
    let window = host.window()
    try {
        @Assert(host.start(), true)
        boundedBatchResetChunks()
        let _ = window.refresh()
        @Assert(boundedBatchPumpAccepted(host, window, turns: 64), true)
        let progress = window.windowProgress()
        let maxStringBytes = boundedBatchChunkMaxStringBytes()
        println("soft-fallback accepted=${progress.acceptedSceneVersion} calls=${boundedBatchChunkCalls()} " +
            "max_count=${boundedBatchChunkMaxCount()} max_string_bytes=${maxStringBytes} " +
            "failure=${progress.lastNativeFailure}")
        @Assert(progress.acceptedSceneVersion > 0 && progress.lastNativeFailure == "none", true)
        @Assert(maxStringBytes > UInt64(2 * 1024 * 1024), true)
        @Assert(maxStringBytes <= UInt64(8 * 1024 * 1024), true)
        var index: Int64 = 1
        while (index <= controller.nodeCount) {
            let expected = boundedBatchLargeKey(index - 1, controller.largeRowKeyBytes)
            let expectedHash = boundedBatchRowKeyHash(expected)
            let (hash, length) = boundedBatchStagedRowKey(UInt32(index))
            @Assert(length, UInt64(expected.toArray().size))
            @Assert(hash, expectedHash)
            index += 1
        }
    } finally {
        window.close()
    }
}

@Test
func mixedReuseAndRewriteStayWithinChunkSlotLimit(): Unit {
    cjguiMacosOwnerTest({
        =>
        boundedBatchEnv("CJGUI_SCENE_BATCH_CHUNK_NODES", "2")
        let controller = CjguiBoundedBatchController()
        controller.nodeCount = 2
        let host = CjguiMacosApplicationHost(controller,
            configuration: CjguiMacosApplicationWindowConfiguration("Bounded batch mixed", 900u32, 620u32))
        let window = host.window()
        try {
            @Assert(host.start(), true)
            let _ = window.refresh()
            @Assert(boundedBatchPumpAccepted(host, window), true)
            let accepted = window.windowProgress()
            boundedBatchResetChunks()
            // The unchanged root reuses its native node as a geometry-only
            // slot; both children are rewritten. Three transfer slots against
            // a two-slot chunk limit used to admit all three in one call.
            controller.suffix = "-mix"
            controller.bump()
            let _ = window.refreshIfNeeded()
            @Assert(boundedBatchPumpAccepted(host, window, atLeast: accepted.acceptedSceneVersion + 1), true)
            let progress = window.windowProgress()
            let calls = boundedBatchChunkCalls()
            let maxCount = boundedBatchChunkMaxCount()
            println("mixed calls=${calls} max_count=${maxCount} accepted=${progress.acceptedSceneVersion} " +
                "failure=${progress.lastNativeFailure}")
            @Assert(progress.lastNativeFailure, "none")
            @Assert(progress.pendingRefreshReason, "none")
            @Assert(calls >= 2u32, true)
            @Assert(maxCount <= 2u32, true)
            var sawFirstChild = false
            var sawSecondChild = false
            for (node in window.acceptedSceneNodes()) {
                if (node.label == "L0-mix") { sawFirstChild = true }
                if (node.label == "L1-mix") { sawSecondChild = true }
            }
            @Assert(sawFirstChild && sawSecondChild, true)
        } finally {
            window.close()
        }
    })
}

@Test
func interactionPaintOverChunkBudgetDefersToResumableCandidate(): Unit {
    cjguiMacosOwnerTest({
        =>
        boundedBatchEnv("CJGUI_SCENE_BATCH_CHUNK_NODES", "512")
        let controller = CjguiBoundedBatchController()
        controller.nodeCount = 600
        let host = CjguiMacosApplicationHost(controller,
            configuration: CjguiMacosApplicationWindowConfiguration("Bounded batch paint", 900u32, 620u32))
        let window = host.window()
        try {
            @Assert(host.start(), true)
            let _ = window.refresh()
            @Assert(boundedBatchPumpAccepted(host, window, turns: 192), true)
            let accepted = window.windowProgress()
            @Assert(accepted.acceptedSceneVersion > 0 && accepted.lastNativeFailure == "none", true)
            // 601 transfer slots no longer fit one 512-slot chunk. The overlay
            // animation stays live: paint must transfer nothing synchronously,
            // keep the accepted scene, and continue through the same resumable
            // candidate used by ordinary refreshes.
            var paintKey = ""
            for (node in window.acceptedSceneNodes()) {
                if (node.nodeId == 2) { paintKey = node.identityKey }
            }
            println("interaction key=[${paintKey}] bindings=${window.animationBindingCount()}")
            @Assert(paintKey.size > 0, true)
            let started = MonoTime.now()
            @Assert(window.animateNodeOpacity(paintKey, 0.5,
                spec: CjguiComposableUiAnimationSpec.tween(durationMs: 5000), atTime: started), true)
            boundedBatchResetChunks()
            let _ = window.advanceAnimations(atTime: started + 2 * Duration.second)
            let immediate = window.windowProgress()
            let immediateCalls = boundedBatchChunkCalls()
            println("interaction immediate accepted=${immediate.acceptedSceneVersion} " +
                "pending=${immediate.pendingRefreshReason} failure=${immediate.lastNativeFailure} " +
                "chunks=${immediateCalls}")
            @Assert(immediate.acceptedSceneVersion, accepted.acceptedSceneVersion)
            @Assert(immediate.lastNativeFailure, "none")
            @Assert(immediateCalls, 0u32)
            // Continue the same intent through the ordinary resumable refresh
            // candidate and observe its retained scene-batch boundary while
            // the old accepted scene stays live.
            let _ = window.refreshIfNeeded()
            var sawResumableCandidate = false
            var reasons: ArrayList<String> = ArrayList<String>()
            var turns: Int64 = 0
            while (turns < 256) {
                let progress = window.windowProgress()
                if (progress.acceptedSceneVersion == accepted.acceptedSceneVersion &&
                    progress.pendingRefreshReason != "none") {
                    sawResumableCandidate = true
                    if (!reasons.contains(progress.pendingRefreshReason)) {
                        reasons.add(progress.pendingRefreshReason)
                    }
                }
                if (progress.acceptedSceneVersion > accepted.acceptedSceneVersion &&
                    progress.pendingRefreshReason == "none") {
                    break
                }
                if (!host.pumpOneTurn()) { break }
                turns += 1
            }
            let settled = window.windowProgress()
            println("interaction settled accepted=${settled.acceptedSceneVersion} " +
                "pending=${settled.pendingRefreshReason} failure=${settled.lastNativeFailure} " +
                "saw_resumable=${sawResumableCandidate} reasons=${reasons} chunks=${boundedBatchChunkCalls()}")
            @Assert(sawResumableCandidate, true)
            @Assert(reasons.contains("refresh_preparing_scene_batch"), true)
            @Assert(settled.acceptedSceneVersion > accepted.acceptedSceneVersion, true)
            @Assert(settled.pendingRefreshReason, "none")
            @Assert(settled.lastNativeFailure, "none")
            @Assert(boundedBatchChunkCalls() >= 2u32, true)
            @Assert(window.hasActiveAnimations(), true)
        } finally {
            window.close()
        }
    })
}

package cjgui_prototype_host

import cjgui.*
import cjgui_shared_operation_core.*
import std.collection.*
import std.env.*
import std.time.*

/// 默认关闭的只读因果观测。起点在业务处理之前取，owner 前后与真正携带该状态的
/// accepted 候选按版本身份关联；inputSequence 为 0 时用内部有界观测 ID，不改公共
/// 版本或业务协议。容量有界：溢出与超时具名记录，不覆盖 pending、不丢慢输入。
class PrototypeMeasurementRecord {
    let id: Int64
    let source: String
    let field: String
    let sequence: UInt64
    let startNs: Int64
    let ownerBefore: Int64
    let acceptedBefore: Int64
    let contentBefore: Int64
    var ownerAfter: Int64 = -1
    var ownerNs: Int64 = -1
    var expectedSceneVersion: Int64 = -1
    var applied: Bool = false
    var tracked: Bool = true
    var reason: String = ""

    init(id: Int64, source: String, field: String, sequence: UInt64, startNs: Int64,
        ownerBefore: Int64, acceptedBefore: Int64, contentBefore: Int64) {
        this.id = id
        this.source = source
        this.field = field
        this.sequence = sequence
        this.startNs = startNs
        this.ownerBefore = ownerBefore
        this.acceptedBefore = acceptedBefore
        this.contentBefore = contentBefore
    }
}

class PrototypeMeasurementRecorder {
    private let origin: MonoTime
    private let capacity: Int64 = 64
    private let timeoutNs: Int64 = 2000000000
    private let clockIntervalNs: Int64 = 50000000
    private var nextId: Int64 = 1
    private var pending = ArrayList<PrototypeMeasurementRecord>()
    private var overflowCount: Int64 = 0
    private var lastClockNs: Int64 = -1000000000
    private var sceneVersionProvider: () -> Int64
    private var ownerRevisionProvider: () -> Int64
    // 主线程每轮 pump 写入的只读缓存。公开提交在运输线程 begin，只能读到最近一次
    // pump 的接受身份；它只用于“确实出现了新的接受内容”这一必要条件，真正的身份
    // 判定仍在主线程用刚读到的 contentVersionForGeometry 完成。
    private var cachedAccepted: Int64 = -1
    private var cachedContent: Int64 = -1

    init(origin: MonoTime, sceneVersionProvider: () -> Int64, ownerRevisionProvider: () -> Int64) {
        this.origin = origin
        this.sceneVersionProvider = sceneVersionProvider
        this.ownerRevisionProvider = ownerRevisionProvider
    }

    func elapsedNs(): Int64 {
        return (MonoTime.now() - origin).toNanoseconds()
    }

    func overflow(): Int64 {
        return overflowCount
    }

    /// 在业务处理之前调用；返回的观测 ID 与公共 inputSequence 分列。
    func begin(source: String, field: String, sequence: UInt64): ?PrototypeMeasurementRecord {
        let record = PrototypeMeasurementRecord(nextId, source, field, sequence, elapsedNs(),
            ownerRevisionProvider(), cachedAccepted, cachedContent)
        nextId += 1
        if (pending.size >= capacity) {
            overflowCount += 1
            getStdOut().writeln("CANDIDATE_INPUT_OVERFLOW obs=${record.id} source=${source} field=${field} " +
                "pending=${pending.size} capacity=${capacity} dropped_total=${overflowCount} " +
                "input_start_ns=${record.startNs} association=not_tracked")
            getStdOut().flush()
            return None
        }
        pending.add(record)
        return Some(record)
    }

    /// 业务处理之后立刻取 owner 与候选版本；此时还没有任何 accepted 查询。
    func complete(record: ?PrototypeMeasurementRecord, applied: Bool, reason: String): Unit {
        if (let Some(value) <- record) {
            value.applied = applied
            value.reason = reason
            value.ownerAfter = ownerRevisionProvider()
            value.ownerNs = elapsedNs() - value.startNs
            value.expectedSceneVersion = sceneVersionProvider()
            getStdOut().writeln("CANDIDATE_INPUT obs=${value.id} source=${value.source} field=${value.field} " +
                "sequence=${value.sequence} input_start_ns=${value.startNs} applied=${applied} reason=${reason} " +
                "owner_before=${value.ownerBefore} owner_after=${value.ownerAfter} owner_ns=${value.ownerNs} " +
                "expected_scene=${value.expectedSceneVersion} accepted_before=${value.acceptedBefore} " +
                "content_before=${value.contentBefore} start_point=before_business_processing")
            getStdOut().flush()
            if (!applied) {
                value.tracked = false
            }
        }
    }

    func observe(value: CjguiComposableUiWindow): Unit {
        let now = elapsedNs()
        let progress = value.windowProgress()
        let contentVersion = value.contentVersionForGeometry()
        cachedAccepted = progress.acceptedSceneVersion
        cachedContent = contentVersion
        if (now - lastClockNs >= clockIntervalNs) {
            lastClockNs = now
            // 与采集器的 epoch 观测成对，用于把本进程 MonoTime 段映射到公共时钟域。
            getStdOut().writeln("CANDIDATE_CLOCK elapsed_ns=${now} pending=${pending.size} overflow=${overflowCount}")
            getStdOut().flush()
        }
        if (pending.size == 0) { return }
        let submission = value.testLastNativeSubmissionSnapshot()
        let ownerNow = ownerRevisionProvider()
        var kept = ArrayList<PrototypeMeasurementRecord>()
        for (record in pending) {
            if (!record.tracked) { continue }
            if (record.expectedSceneVersion > 0 && contentVersion >= record.expectedSceneVersion &&
                contentVersion > record.contentBefore) {
                var carried: Int64 = -1
                var submissionCount: Int64 = -1
                var submissionNs: Int64 = -1
                var submissionMatches = false
                if (let Some(snapshot) <- submission) {
                    carried = snapshot.acceptedSceneVersion
                    submissionCount = snapshot.submissionCount
                    submissionMatches = snapshot.acceptedSceneVersion == progress.acceptedSceneVersion
                    if (submissionMatches) {
                        submissionNs = (snapshot.time - origin).toNanoseconds()
                    }
                }
                let association = if (contentVersion == record.expectedSceneVersion) {
                    "exact_candidate"
                } else {
                    "merged_later_candidate"
                }
                let ownerCarried = ownerNow >= record.ownerAfter
                getStdOut().writeln("CANDIDATE_INPUT_ACCEPTED obs=${record.id} source=${record.source} " +
                    "field=${record.field} sequence=${record.sequence} input_start_ns=${record.startNs} " +
                    "owner_before=${record.ownerBefore} owner_after=${record.ownerAfter} owner_ns=${record.ownerNs} " +
                    "expected_scene=${record.expectedSceneVersion} accepted_before=${record.acceptedBefore} " +
                    "content_before=${record.contentBefore} accepted_content=${contentVersion} " +
                    "accepted_after=${progress.acceptedSceneVersion} carried_scene=${carried} " +
                    "association=${association} owner_carried=${ownerCarried} owner_now=${ownerNow} " +
                    "submission_count=${submissionCount} submission_matches_accepted=${submissionMatches} " +
                    "submission_ns=${submissionNs} " +
                    "input_to_submission_ns=${if (submissionNs >= 0) { submissionNs - record.startNs } else { -1 }} " +
                    "resolved_ns=${now} input_to_observation_ns=${now - record.startNs} " +
                    "session=${progress.sessionIdentity}")
                getStdOut().flush()
            } else if (now - record.startNs > timeoutNs) {
                getStdOut().writeln("CANDIDATE_INPUT_TIMEOUT obs=${record.id} source=${record.source} " +
                    "field=${record.field} sequence=${record.sequence} input_start_ns=${record.startNs} " +
                    "expected_scene=${record.expectedSceneVersion} content_before=${record.contentBefore} " +
                    "accepted_content_now=${contentVersion} accepted_now=${progress.acceptedSceneVersion} " +
                    "owner_after=${record.ownerAfter} owner_now=${ownerNow} waited_ns=${now - record.startNs} " +
                    "timeout_ns=${timeoutNs} outcome=unresolved")
                getStdOut().flush()
            } else {
                kept.add(record)
            }
        }
        pending = kept
    }

    func flushUnresolved(): Unit {
        let now = elapsedNs()
        for (record in pending) {
            getStdOut().writeln("CANDIDATE_INPUT_UNRESOLVED obs=${record.id} source=${record.source} " +
                "field=${record.field} input_start_ns=${record.startNs} expected_scene=${record.expectedSceneVersion} " +
                "owner_after=${record.ownerAfter} waited_ns=${now - record.startNs} outcome=window_closed")
        }
        getStdOut().flush()
        pending = ArrayList<PrototypeMeasurementRecord>()
    }
}
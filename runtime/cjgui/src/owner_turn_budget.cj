package cjgui

import std.overflow.*
import std.collection.*
import std.time.*

@When[os == "macOS"]
func cjguiOwnerTraceBoundary(session: UInt64, turn: UInt64, stage: UInt32, relatedKind: UInt32, relatedPhase: UInt32,
    value: UInt64, managedId: UInt64): Unit {
    unsafe { cjgui_internal_renderer_owner_trace_boundary(session, turn, stage, relatedKind, relatedPhase, value,
        managedId) }
}

@When[os != "macOS"]
func cjguiOwnerTraceBoundary(session: UInt64, turn: UInt64, stage: UInt32, relatedKind: UInt32, relatedPhase: UInt32,
    value: UInt64, managedId: UInt64): Unit {}

// Trace calls are private macOS diagnostics. Other platform builds retain the
// same owner budget while compiling these helpers to inert values.
@When[os == "macOS"]
func cjguiOwnerTraceRecord(kind: UInt32, session: UInt64, turn: UInt64, request: UInt64, dispatch: UInt64,
    generation: UInt64, phase: UInt32, span: UInt64): UInt64 {
    // Only the disputed return/turn path needs these extra fixed records.
    // Native timestamps share one clock; Cj values are elapsed durations,
    // never absolute timestamps implicitly joined to that clock.
    let boundary = kind == 2u32 || phase == 88u32 || phase == 18u32
    if (boundary) {
        cjguiOwnerTraceBoundary(session, turn, 132u32, kind, phase, 0u64, UInt64.Max)
        cjguiOwnerTraceBoundary(session, turn, 133u32, kind, phase, 0u64, UInt64.Max)
    }
    let enabled = unsafe { cjgui_internal_renderer_owner_trace_ns() } != 0u64
    if (!enabled) {
        return 0u64
    }
    var localStart: ?MonoTime = None
    if (boundary) {
        cjguiOwnerTraceBoundary(session, turn, 134u32, kind, phase, 0u64, UInt64.Max)
        localStart = Some(MonoTime.now())
        cjguiOwnerTraceBoundary(session, turn, 135u32, kind, phase, 0u64, UInt64.Max)
    }
    let current = Thread.currentThread.id
    let managedId = if (current >= 0) {
        UInt64(current)
    } else {
        UInt64.Max
    }
    if (let Some(started) <- localStart) {
        cjguiOwnerTraceBoundary(session, turn, 136u32, kind, phase, UInt64((MonoTime.now() - started).toNanoseconds()),
            managedId)
        localStart = Some(MonoTime.now())
        cjguiOwnerTraceBoundary(session, turn, 137u32, kind, phase, 0u64, managedId)
    }
    // Narrow attribution boundaries must not add a sampler watch whose own
    // synchronous reclamation could become the wait being diagnosed.
    let withWatch: UInt8 = if ((phase >= 83u32 && phase <= 90u32) || (phase >= 97u32 && phase <= 112u32)) {
        0u8
    } else {
        1u8
    }
    let result = unsafe { cjgui_internal_renderer_owner_trace_managed_record(kind, session, turn, request, dispatch,
        generation, phase, span, managedId, withWatch) }
    if (let Some(started) <- localStart) {
        cjguiOwnerTraceBoundary(session, turn, 139u32, kind, phase, UInt64((MonoTime.now() - started).toNanoseconds()),
            managedId)
    }
    return result
}

@When[os == "macOS"]
func cjguiOwnerTraceLegacySpan(session: UInt64, turn: UInt64, request: UInt64, generation: UInt64, phase: UInt32,
    startedNs: UInt64): Unit {
    unsafe { cjgui_internal_renderer_owner_trace_legacy_span(session, turn, request, generation, phase, startedNs) }
}

@When[os != "macOS"]
func cjguiOwnerTraceLegacySpan(session: UInt64, turn: UInt64, request: UInt64, generation: UInt64, phase: UInt32,
    startedNs: UInt64): Unit {}

@When[os != "macOS"]
func cjguiOwnerTraceRecord(kind: UInt32, session: UInt64, turn: UInt64, request: UInt64, dispatch: UInt64,
    generation: UInt64, phase: UInt32, span: UInt64): UInt64 {
    return 0u64
}

@When[os == "macOS"]
func cjguiOwnerTraceSetTurn(turn: UInt64): Unit {
    unsafe { cjgui_internal_renderer_owner_trace_set_turn(turn) }
}

@When[os != "macOS"]
func cjguiOwnerTraceSetTurn(turn: UInt64): Unit {}

@When[os == "macOS"]
func cjguiOwnerTraceExport(): Unit {
    unsafe { cjgui_internal_renderer_owner_trace_export() }
}

@When[os != "macOS"]
func cjguiOwnerTraceExport(): Unit {}

/// Experimental owner pacing. All windows on one serialized owner loop share
/// this object. Only measured waits made by their event pumps are credited;
/// dispatch, callbacks, accepted publication and resource preparation count.
public class CjguiOwnerTurnBudget {
    private var active: Bool = false
    private var startedNs: Int64 = 0
    private var limitNs: Int64 = 0
    private var idleNs: Int64 = 0
    private var turn: Int64 = 0
    private let preparedOwners = ArrayList<UInt64>()
    // A window deferred behind an earlier sibling keeps its turn in this
    // bounded queue. Input is still drained against each accepted scene;
    // only beginning another expensive refresh is ordered here.
    private let refreshWaiters = ArrayList<UInt64>()
    private var refreshPriority: UInt64 = 0u64
    private var priorityVisited: Bool = false
    private var now: () -> Int64 = {=> Int64(unsafe { cjgui_internal_renderer_owner_clock_ns() })}

    public init() {}

    /// Experimental observation. CPU is separate from the wall/idle budget.
    public func observationThreadCpuNanoseconds(): Int64 {
        return Int64(unsafe { cjgui_internal_renderer_owner_thread_cpu_ns() })
    }

    /// Nested callbacks cannot open a second allowance.
    public func begin(budgetMicroseconds!: Int64 = 16000): Bool {
        if (active || budgetMicroseconds <= 0) {
            return false
        }
        startedNs = now()
        limitNs = budgetMicroseconds.saturatingMul(1000)
        idleNs = 0
        turn += 1
        refreshPriority = if (refreshWaiters.size > 0) {
            refreshWaiters[0]
        } else {
            0u64
        }
        priorityVisited = false
        active = true
        cjguiOwnerTraceSetTurn(UInt64(turn))
        return true
    }

    public func end(): Unit {
        // A closed/detached window cannot strand live siblings. Its priority
        // is retired after exactly one turn in which it made no admission call.
        if (refreshPriority != 0u64 && !priorityVisited) {
            removeRefreshWaiter(refreshPriority)
        }
        active = false
        cjguiOwnerTraceSetTurn(0u64)
    }

    public func remainingMicroseconds(): Int64 {
        if (!active) {
            return Int64.Max
        }
        let current = now()
        let elapsed = if (current > startedNs) {
            current - startedNs
        } else {
            0
        }
        let idle = if (idleNs < elapsed) {
            idleNs
        } else {
            elapsed
        }
        let work = elapsed - idle
        return if (work >= limitNs) {
            0
        } else {
            (limitNs - work) / 1000
        }
    }

    /// Diagnostic elapsed owner work for the active turn, excluding only
    /// pump idle time that was explicitly credited by this budget.
    func elapsedWorkMicroseconds(): Int64 {
        if (!active) { return 0 }
        let current = now()
        let elapsed = if (current > startedNs) { current - startedNs } else { 0 }
        let idle = if (idleNs < elapsed) { idleNs } else { elapsed }
        return (elapsed - idle) / 1000
    }

    func admits(reserveMicroseconds: Int64): Bool {
        return !active || remainingMicroseconds() >= reserveMicroseconds
    }

    func isActive(): Bool {
        return active
    }
    /// Read-only identity for correlating traces and prepared work with the
    /// currently allocated (or most recently allocated) owner turn.
    public func turnIdentity(): Int64 {
        return turn
    }
    func hasPreparedWork(): Bool {
        // Source installation has a separate bounded holder from a scene
        // candidate. Native close clears its scalar gate, so no H close or
        // terminal function needs to own this E pacing cleanup.
        var i: Int64 = 0
        while (i < preparedOwners.size) {
            let owner = preparedOwners[i]
            if (owner >= 0x8000000000000000u64 &&
                unsafe { cjgui_internal_renderer_source_install_pending_scalar(owner - 0x8000000000000000u64) } == 0u8) {
                preparedOwners.remove(at: i)
            } else {
                i += 1
            }
        }
        return preparedOwners.size > 0
    }

    func retainPreparedOwner(owner: UInt64): Bool {
        for (value in preparedOwners) {
            if (value == owner) {
                return true
            }
        }
        if (owner == 0u64 || preparedOwners.size >= 32) {
            return false
        }
        preparedOwners.add(owner)
        return true
    }

    func releasePreparedOwner(owner: UInt64): Unit {
        var index: Int64 = 0
        while (index < preparedOwners.size) {
            if (preparedOwners[index] == owner) {
                preparedOwners.remove(at: index);
                return
            }
            index += 1
        }
    }

    private func enqueueRefreshWaiter(owner: UInt64): Unit {
        for (item in refreshWaiters) {
            if (item == owner) {
                return
            }
        }
        if (owner != 0u64 && refreshWaiters.size < 32) {
            refreshWaiters.add(owner)
        }
    }

    private func removeRefreshWaiter(owner: UInt64): Unit {
        var i: Int64 = 0
        while (i < refreshWaiters.size) {
            if (refreshWaiters[i] == owner) {
                refreshWaiters.remove(at: i);
                return
            }
            i += 1
        }
    }

    func admitsRefresh(owner: UInt64, reserveMicroseconds: Int64): Bool {
        if (!active) {
            return true
        }
        if (owner == refreshPriority) {
            priorityVisited = true
        }
        if ((refreshPriority != 0u64 && owner != refreshPriority) || !admits(reserveMicroseconds)) {
            enqueueRefreshWaiter(owner)
            return false
        }
        removeRefreshWaiter(owner)
        if (owner == refreshPriority) {
            refreshPriority = 0u64
        }
        return true
    }

    func creditPumpIdle(nanoseconds: Int64): Unit {
        if (active && nanoseconds > 0) {
            idleNs = idleNs.saturatingAdd(nanoseconds)
        }
    }

    func deadlineNs(): UInt64 {
        if (!active) {
            return 0u64
        }
        return UInt64(startedNs.saturatingAdd(limitNs).saturatingAdd(idleNs))
    }

    func testUseClock(clock: () -> Int64): Unit {
        now = clock
    }
}

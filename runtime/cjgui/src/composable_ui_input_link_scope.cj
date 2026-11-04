package cjgui

import std.sync.*

/// Experimental, opt-in diagnostic scalars for the currently executing
/// controller event. Session/generation identify an observation, not a handle.
public class CjguiInputLinkDispatchSnapshot {
    public let windowIdentity: String
    public let session: UInt64
    public let generation: UInt64
    public let raw: UInt64
    public let ordinal: UInt64
    public let cookie: UInt64
    public let managedThread: String
    init(windowIdentity: String, session: UInt64, generation: UInt64, raw: UInt64,
        ordinal: UInt64, cookie: UInt64, managedThread: String) {
        this.windowIdentity = windowIdentity; this.session = session; this.generation = generation
        this.raw = raw; this.ordinal = ordinal; this.cookie = cookie; this.managedThread = managedThread
    }
    public static func unknown(): CjguiInputLinkDispatchSnapshot {
        return CjguiInputLinkDispatchSnapshot("unknown", 0u64, 0u64, 0u64, 0u64, 0u64, "unknown")
    }
    public func sameIdentity(other: CjguiInputLinkDispatchSnapshot): Bool {
        return cookie == other.cookie && windowIdentity == other.windowIdentity && session == other.session &&
            generation == other.generation && raw == other.raw && ordinal == other.ordinal &&
            managedThread == other.managedThread
    }
}

class CjguiInputLinkDispatchScope {
    var event: ?CjguiComposableUiEvent
    let snapshot: CjguiInputLinkDispatchSnapshot
    var previous: ?CjguiInputLinkDispatchScope
    var conflicted: Bool
    init(event: CjguiComposableUiEvent, snapshot: CjguiInputLinkDispatchSnapshot,
        previous: ?CjguiInputLinkDispatchScope) {
        this.event = Some(event); this.snapshot = snapshot; this.previous = previous
        this.conflicted = previous.isSome()
        if (let Some(value) <- previous) { value.conflicted = true }
    }
}

private let inputLinkScopeLock = Mutex()
private var inputLinkScopeStorage: ?ThreadLocal<CjguiInputLinkDispatchScope> = None
private var inputLinkScopeCookie: UInt64 = 0u64

func cjguiInputLinkBeginDispatch(event: CjguiComposableUiEvent, window: String, session: UInt64,
    generation: UInt64, raw: UInt64, ordinal: UInt64): ?CjguiInputLinkDispatchScope {
    let valid = raw != 0u64 && ordinal != 0u64 && generation != 0u64 && session != 0u64 && window != ""
    let allocation = synchronized(inputLinkScopeLock) {
        if (inputLinkScopeStorage.isNone()) {
            inputLinkScopeStorage = Some(ThreadLocal<CjguiInputLinkDispatchScope>())
        }
        if (!valid || inputLinkScopeCookie == UInt64.Max) { (inputLinkScopeStorage, 0u64) }
        else { inputLinkScopeCookie += 1u64; (inputLinkScopeStorage, inputLinkScopeCookie) }
    }
    let storage = allocation[0].getOrThrow()
    let snapshot = CjguiInputLinkDispatchSnapshot(window, session, generation, raw, ordinal,
        allocation[1], "${Thread.currentThread.id}")
    let frame = CjguiInputLinkDispatchScope(event, snapshot, storage.get())
    storage.set(Some(frame))
    return Some(frame)
}

func cjguiInputLinkEndDispatch(scope: ?CjguiInputLinkDispatchScope): Bool {
    if (let Some(frame) <- scope) {
        let storage = synchronized(inputLinkScopeLock) { inputLinkScopeStorage }.getOrThrow()
        if (let Some(current) <- storage.get()) {
            if (refEq(current, frame)) {
                let exact = frame.snapshot.cookie != 0u64 && !frame.conflicted &&
                    frame.snapshot.managedThread == "${Thread.currentThread.id}"
                let previous = frame.previous
                frame.event = None
                frame.previous = None
                storage.set(previous)
                return exact
            }
        }
        frame.conflicted = true
        frame.event = None
        frame.previous = None
        storage.set(None)
    }
    return false
}

/// Returns an immutable scalar snapshot only for the identical live event on
/// its executing managed thread. Missing, nested or conflicting scopes return None.
public func cjguiInputLinkCurrentDispatch(event: CjguiComposableUiEvent): ?CjguiInputLinkDispatchSnapshot {
    let storage = synchronized(inputLinkScopeLock) { inputLinkScopeStorage }
    if (let Some(local) <- storage) {
        if (let Some(scope) <- local.get()) {
            if (let Some(activeEvent) <- scope.event) {
                if (scope.snapshot.cookie != 0u64 && !scope.conflicted && refEq(activeEvent, event) &&
                    scope.snapshot.managedThread == "${Thread.currentThread.id}") { return Some(scope.snapshot) }
            }
        }
    }
    return None
}

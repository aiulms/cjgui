package cjgui

import std.collection.*

// One sealed, actually queued macOS callback prefix. NONE and owner budget
// yields are not FIFO completion. Each member retains its own input identity.
class CjguiMacActivationPrefixGate {
    private var active: ?InternalRendererActivationPrefix = None
    private var nextOrdinal: UInt32 = 0u32
    // FIFO64 plus the single READY ticket; no unbounded cancellation history.
    private let cancelled = ArrayList<InternalRendererActivationPrefix>()
    private var exhausted: Bool = false
    private var completedGeneration: UInt64 = 0u64
    private var completedNonce: UInt64 = 0u64
    private var observedGeneration: UInt64 = 0u64

    func pending(): Bool {
        active.isSome()
    }
    func snapshot(): InternalRendererActivationPrefix {
        return match (active) {
            case Some(p) => p;
            case None => InternalRendererActivationPrefix()
        }
    }
    private func common(a: InternalRendererActivationPrefix, b: InternalRendererActivationPrefix): Bool {
        let commonKey = a.sessionGeneration == b.sessionGeneration && a.nonce == b.nonce && a.sceneVersion == b
            .sceneVersion && a.bindingEpoch == b.bindingEpoch && a.memberCount == b.memberCount && a.secondKind == b
            .secondKind
        return commonKey && (a.secondKind == 45u32 || (a.nodeId == b.nodeId && a.resourceId == b.resourceId &&
            a.nodeKind == b.nodeKind))
    }
    private func terminalMatches(a: InternalRendererActivationPrefix, b: InternalRendererActivationPrefix): Bool {
        return common(a, b) && b.ordinal == a.memberCount && b.memberKind == a.secondKind
    }
    private func retire(p: InternalRendererActivationPrefix): Unit {
        if (p.sessionGeneration > completedGeneration) {
            completedGeneration = p.sessionGeneration
            completedNonce = p.nonce
        } else if (p.sessionGeneration == completedGeneration && p.nonce > completedNonce) {
            completedNonce = p.nonce
        }
    }
    func cancel(): Unit {
        if (let Some(value) <- active) {
            if (cancelled.size < 65) {
                cancelled.add(value)
            } else {
                exhausted = true
            }
        }
        active = None
        nextOrdinal = 0u32
    }
    private func physicalKind(p: InternalRendererActivationPrefix): Bool {
        if (p.ordinal == p.memberCount) {
            return p.memberKind == 45u32
        }
        return p.memberKind == 43u32 || p.memberKind == 44u32 || p.memberKind == 31u32 || p.memberKind == 47u32
    }

    // -1 rejected; 0 independent; 1 admitted nonterminal; 2 admitted terminal.
    // These are member states, never the producer's ordinal.
    func admit(event: InternalRendererPumpResult, binding: UInt64, targetReady: Bool): Int64 {
        let p = event.activationPrefix
        if (event.eventKind == 0u32) {
            return 0
        }
        let physical = p.secondKind == 45u32
        let shaped = p.nonce != 0u64 && p.sessionGeneration != 0u64 && p.memberKind == event.eventKind &&
            p.memberCount > 0u32 && p.memberCount <= 64u32 && p.ordinal > 0u32 && p.ordinal <= p.memberCount && (if (physical) {
            physicalKind(p)
        } else {
            p.memberCount == 2u32 && (p.secondKind == 27u32 || p.secondKind == 29u32) && (if (p.ordinal == 1u32) {
                p.memberKind == 31u32
            } else {
                p.memberKind == p.secondKind
            })
        })
        // A retained 47 may name a removed node. It grants cleanup of its old
        // sequence only; the ordinary lease terminal handler remains decisive.
        let ready = targetReady || (physical && event.eventKind == 47u32 && event.bindingEpoch != 0u64)
        let exact = shaped && p.sceneVersion == event.projectionVersion && p.nodeId == event.nodeId && p.resourceId == event
            .resourceId && p.nodeKind == event.nodeKind && (p.bindingEpoch == 0u64 || p.bindingEpoch == binding) && ready
        // The private native allocator never reuses a renderer generation.
        // A terminated session's suffix cannot revoke a newer active prefix.
        if (p.nonce != 0u64 && p.sessionGeneration < observedGeneration) {
            return -1
        }
        if (exact && p.ordinal == 1u32 && p.sessionGeneration > observedGeneration) {
            cancel()
            observedGeneration = p.sessionGeneration
            var oldIndex: Int64 = 0
            while (oldIndex < cancelled.size) {
                if (cancelled[oldIndex].sessionGeneration < observedGeneration) {
                    cancelled.remove(at: oldIndex)
                } else {
                    oldIndex += 1
                }
            }
            exhausted = false
        }
        if (let Some(previous) <- active) {
            if (!exhausted && exact && common(previous, p) && p.ordinal == nextOrdinal) {
                nextOrdinal += 1u32
                return if (p.ordinal == p.memberCount) {
                    2
                } else {
                    1
                }
            }
            cancel()
        }
        var index: Int64 = 0
        while (index < cancelled.size) {
            let old = cancelled[index]
            if (old.sessionGeneration == p.sessionGeneration && old.nonce == p.nonce) {
                // The retained descriptor, not a malformed packet's self-claimed
                // last ordinal/count, determines suffix reclamation.
                if (terminalMatches(old, p) && p.memberKind == event.eventKind) {
                    retire(old)
                    cancelled.remove(at: index)
                }
                return -1
            }
            index += 1
        }
        if (p.nonce == 0u64) {
            return 0
        }
        if (exhausted || !exact || p.ordinal != 1u32 || p.sessionGeneration < completedGeneration || (completedGeneration ==
            p.sessionGeneration && p.nonce <= completedNonce)) {
            return -1
        }
        active = Some(p)
        nextOrdinal = 2u32
        return if (p.memberCount == 1u32) {
            2
        } else {
            1
        }
    }
    func settleTerminal(p: InternalRendererActivationPrefix): Unit {
        if (let Some(previous) <- active) {
            if (terminalMatches(previous, p) && nextOrdinal == previous.memberCount + 1u32) {
                retire(previous)
                active = None
                nextOrdinal = 0u32
            }
        } else {
            var index: Int64 = 0
            while (index < cancelled.size) {
                if (terminalMatches(cancelled[index], p)) {
                    retire(cancelled[index])
                    cancelled.remove(at: index)
                    return
                }
                index += 1
            }
        }
    }
    // Existing pair consumers retain their package-only convenience.
    func settleSecond(): Unit {
        var terminal = snapshot()
        terminal.ordinal = terminal.memberCount
        terminal.memberKind = terminal.secondKind
        settleTerminal(terminal)
    }
}

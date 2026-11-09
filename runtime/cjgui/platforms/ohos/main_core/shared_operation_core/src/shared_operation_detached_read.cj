package cjgui_shared_operation_core

import std.collection.*
import std.sync.*

// Connection lifetime, shared by its active and retiring IoStates. Stop is
// never a release. Only the holder of a reservation returns its own identity.
internal class CjguiDetachedReadBudgetEntry {
    let id: Int64
    let generation: Int64
    let lease: Int64
    let bytes: Int64
    init(id: Int64, generation: Int64, lease: Int64, bytes: Int64) {
        this.id = id; this.generation = generation; this.lease = lease; this.bytes = bytes
    }
}
internal class CjguiDetachedReadBudget {
    private let lock = Mutex()
    private let entries = ArrayList<CjguiDetachedReadBudgetEntry>()
    private var capacity: Int64 = 8 * 1024 * 1024
    private var next: Int64 = 1
    private var held: Int64 = 0
    private var peak: Int64 = 0
    private var refused: Int64 = 0
    private var releases: Int64 = 0

    // Explicit conservative simultaneous-buffer reservation: original framed
    // request, independent UTF8 body/copy, builder/hex, payload interpolation,
    // framed String/Array and write slice. GC allocation/RSS is not this ledger.
    func reserve(generation: Int64, lease: Int64, requestBytes: Int64,
        bodyBytes: Int64): ?CjguiDetachedReadReservation {
        return synchronized(lock) {
            if (requestBytes < 0 || bodyBytes < 0 || bodyBytes > 65536) { return None }
            let cost = requestBytes + 16 * bodyBytes + 8192
            if (entries.size >= 64 || cost > capacity || held > capacity - cost) {
                refused += 1; return None
            }
            let id = next; next += 1
            entries.add(CjguiDetachedReadBudgetEntry(id, generation, lease, cost))
            held += cost
            if (held > peak) { peak = held }
            return Some(CjguiDetachedReadReservation(this, id, generation, lease, cost))
        }
    }
    func release(id: Int64, generation: Int64, lease: Int64): Unit {
        synchronized(lock) {
            for (i in 0..entries.size) {
                let row = entries[i]
                if (row.id == id && row.generation == generation && row.lease == lease) {
                    held -= row.bytes; let _ = entries.remove(at: i); releases += 1; return
                }
            }
        }
    }
    func snapshot(): Array<Int64> {
        return synchronized(lock) { [capacity, held, peak, Int64(entries.size), refused, releases] }
    }
    func configure(capacity: Int64): Bool {
        return synchronized(lock) {
            if (entries.size != 0 || capacity < 0 || capacity > 8 * 1024 * 1024) { false }
            else { this.capacity = capacity; true }
        }
    }
}
internal class CjguiDetachedReadReservation {
    private let budget: CjguiDetachedReadBudget
    private let lock = Mutex()
    private var returned: Bool = false
    let id: Int64
    let generation: Int64
    let lease: Int64
    let bytes: Int64
    init(budget: CjguiDetachedReadBudget, id: Int64, generation: Int64, lease: Int64, bytes: Int64) {
        this.budget = budget; this.id = id; this.generation = generation; this.lease = lease; this.bytes = bytes
    }
    func release(): Unit {
        synchronized(lock) {
            if (!returned) { returned = true; budget.release(id, generation, lease) }
        }
    }
}

// Contains values only. Never a provider, live document, snapshot handle,
// native object, owner callback, or an encoder closure capturing a connection.
internal class CjguiDetachedRangeValue {
    let range: CjguiSharedOperationRangeRead
    let requestedResource: Int64
    let requestedStart: Int64
    let requestedEnd: Int64
    init(range: CjguiSharedOperationRangeRead, resource: Int64, start: Int64, end: Int64) {
        // One bounded independent copy prevents a custom provider's String
        // slice from retaining an unrelated large backing through the worker.
        let content = String.fromUtf8(range.content.toArray())
        this.range = CjguiSharedOperationRangeRead(range.isAvailable, range.isVersionConflict,
            range.resourceId, range.version, range.start, range.end, content, String.fromUtf8(range.reason.toArray()))
        requestedResource = resource; requestedStart = start; requestedEnd = end
    }
}
internal class CjguiSharedOperationPendingResponse {
    var wire: ?String
    private var detached: ?CjguiDetachedRangeValue
    private let reservation: ?CjguiDetachedReadReservation
    init(wire: String, reservation!: ?CjguiDetachedReadReservation = None) { this.wire = Some(wire); detached = None; this.reservation = reservation }
    init(range: CjguiDetachedRangeValue, reservation: CjguiDetachedReadReservation) {
        wire = None; detached = Some(range); this.reservation = Some(reservation)
    }
    // After the queue transfers it, this object has one physical consumer.
    func takeRange(): ?CjguiDetachedRangeValue { let value = detached; detached = None; return value }
    func discard(): Unit {
        detached = None; wire = None
        if (let Some(lease) <- reservation) { lease.release() }
    }
}

// Internal deterministic test seam. A normal connection never supplies one.
// It is called outside all transport/lifecycle/diagnostic locks.
internal interface CjguiDetachedReadEncodingProbe {
    func beforeEncoding(lease: Int64): Unit
}

internal interface CjguiDetachedReadBeforeTakeProbe {
    func beforeResponseTake(lease: Int64): Unit
}

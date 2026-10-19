package cjgui_shared_operation_core

import std.convert.*
import std.env.*
import std.fs.*
import std.sync.*
import std.time.*

// Opt-in observation only. Neither this recorder nor its lock calls a domain,
// a native API, another recorder, or a business lock. No payload/token is kept.
// 160 records: up to 32 active and 128 closed; first timeout freezes eviction.
internal class CjguiSharedRequestDiagnosticRow {
    var lease: Int64 = 0
    var op: Int64 = 0
    var resource: Int64 = -1
    var expected: Int64 = -1
    var start: Int64 = -1
    var end: Int64 = -1
    var bytes: Int64 = 0
    var depth: Int64 = 0
    var predecessor: Int64 = 0
    var pump: Int64 = 0
    var terminal: Int64 = 0
    let times = Array<Int64>(24, repeat: -1)

    func reset(): Unit {
        lease = 0; op = 0; resource = -1; expected = -1; start = -1; end = -1
        bytes = 0; depth = 0; predecessor = 0; pump = 0; terminal = 0
        for (i in 0..times.size) { times[i] = -1 }
    }
    func copyFrom(row: CjguiSharedRequestDiagnosticRow): Unit {
        lease = row.lease; op = row.op; resource = row.resource; expected = row.expected
        start = row.start; end = row.end; bytes = row.bytes; depth = row.depth
        predecessor = row.predecessor; pump = row.pump; terminal = row.terminal
        for (i in 0..times.size) { times[i] = row.times[i] }
    }
}

internal class CjguiSharedRequestDiagnostic {
    let endpoint: String
    let generation: Int64
    private let origin = MonoTime.now()
    private let lock = Mutex()
    private let rows = Array<CjguiSharedRequestDiagnosticRow>(160, { _ => CjguiSharedRequestDiagnosticRow() })
    private let firstSlow = Array<CjguiSharedRequestDiagnosticRow>(160, { _ => CjguiSharedRequestDiagnosticRow() })
    // pump id and timestamps: entry, transport acquired, purge begin/end,
    // ready begin/end, return. First slow pump is independently retained.
    private let pumps = Array<Array<Int64>>(128, { _ => Array<Int64>(15, repeat: -1) })
    private let slowPump = Array<Int64>(15, repeat: -1)
    private var cursor: Int64 = 0
    private var pumpSequence: Int64 = 0
    private var dropped: Int64 = 0
    private var overwritten: Int64 = 0
    private var firstTimeoutLease: Int64 = 0
    private var dumped: Bool = false

    init(endpoint: String, generation: Int64) {
        this.endpoint = endpoint; this.generation = generation
    }

    func elapsedAt(time: MonoTime): Int64 { return (time - origin).toNanoseconds() }

    // Called in the established state queue lock after its existing lease
    // assignment. The diagnostic lock is always the last lock acquired.
    func queued(lease: Int64, payload: String, readyOrigin: MonoTime,
        depth: Int64, predecessor: Int64): Unit {
        synchronized(lock) {
            var active: Int64 = 0
            for (row in rows) { if (row.lease != 0 && row.terminal == 0) { active += 1 } }
            if (active >= 32) { dropped += 1; return }
            var chosen: Int64 = -1
            for (i in 0..rows.size) {
                let index = (cursor + i) % rows.size
                if (rows[index].lease == 0 ||
                    (firstTimeoutLease == 0 && rows[index].terminal != 0)) { chosen = index; break }
            }
            if (chosen < 0) { dropped += 1; return }
            let row = rows[chosen]
            if (row.lease != 0) { overwritten += 1 }
            row.reset(); row.lease = lease; row.bytes = payload.size
            row.depth = depth; row.predecessor = predecessor
            row.times[0] = elapsedAt(readyOrigin); row.times[1] = elapsedAt(MonoTime.now())
            // Only the public command line is decoded; line 1 is a secret and
            // is neither copied to a record nor printed.
            let lines = payload.split("\n")
            if (lines.size >= 3) {
                let command = lines[2].split(" ")
                if (command.size == 5 && command[0] == "READ_RANGE") {
                    row.op = 1
                    row.resource = Int64.tryParse(command[1]) ?? -1
                    row.start = Int64.tryParse(command[2]) ?? -1
                    row.end = Int64.tryParse(command[3]) ?? -1
                    row.expected = Int64.tryParse(command[4]) ?? -1
                } else if (command.size > 0 && command[0] == "INVOKE") { row.op = 2 }
            }
            cursor = (chosen + 1) % rows.size
        }
    }

    func mark(lease: Int64, phase: Int64, pump!: Int64 = 0, terminal!: Int64 = 0): Unit {
        let time = elapsedAt(MonoTime.now())
        synchronized(lock) {
            for (row in rows) {
                if (row.lease == lease) {
                    if (phase >= 0 && phase < row.times.size && row.times[phase] < 0) { row.times[phase] = time }
                    if (pump > 0) { row.pump = pump }
                    if (terminal != 0) { row.terminal = terminal }
                    if (terminal == 2 && firstTimeoutLease == 0) { firstTimeoutLease = lease }
                    if (slowPump[0] > 0) {
                        for (saved in firstSlow) {
                            if (saved.lease == lease) {
                                if (phase >= 0 && phase < saved.times.size && saved.times[phase] < 0) { saved.times[phase] = time }
                                if (terminal != 0) { saved.terminal = terminal }
                                break
                            }
                        }
                    }
                    // Bound closed retention independently of the 32 active
                    // slots. A latched timeout forbids any further eviction.
                    if (terminal != 0 && firstTimeoutLease == 0) {
                        var closed: Int64 = 0; var oldest: Int64 = -1
                        for (i in 0..rows.size) {
                            if (rows[i].lease != 0 && rows[i].terminal != 0) {
                                closed += 1
                                if (oldest < 0 || rows[i].lease < rows[oldest].lease) { oldest = i }
                            }
                        }
                        if (closed > 128 && oldest >= 0) { rows[oldest].reset(); overwritten += 1 }
                    }
                    return
                }
            }
            dropped += 1
        }
    }

    func beginPump(): Int64 {
        synchronized(lock) {
            pumpSequence += 1
            let row = pumps[pumpSequence % pumps.size]
            for (i in 0..row.size) { row[i] = -1 }
            row[0] = pumpSequence; row[1] = elapsedAt(MonoTime.now())
            return pumpSequence
        }
    }
    func pumpPhase(sequence: Int64, phase: Int64): Unit {
        let time = elapsedAt(MonoTime.now())
        synchronized(lock) {
            let row = pumps[sequence % pumps.size]
            if (row[0] != sequence) { dropped += 1; return }
            row[phase] = time
            if (phase == 7 && time - row[1] > 16000000 && slowPump[0] < 0) {
                for (i in 0..row.size) { slowPump[i] = row[i] }
                for (i in 0..rows.size) { firstSlow[i].copyFrom(rows[i]) }
            }
        }
    }
    func pumpCounts(sequence: Int64, active: Int64, cleanup: Int64, after: Bool): Unit {
        synchronized(lock) {
            let row = pumps[sequence % pumps.size]
            if (row[0] == sequence) { row[if (after) { 13 } else { 11 }] = active; row[if (after) { 14 } else { 12 }] = cleanup }
        }
    }

    // Owner shutdown only, after the existing bounded worker convergence.
    // It may include still-active rows, explicitly reported by terminal=0.
    func dump(): Unit {
        // Allocate detached fixed-capacity storage before taking the recorder
        // lock. Only scalar copying happens in the lock; no format or file IO.
        let saved = Array<CjguiSharedRequestDiagnosticRow>(320, { _ => CjguiSharedRequestDiagnosticRow() })
        let savedPumps = Array<Array<Int64>>(129, { _ => Array<Int64>(15, repeat: -1) })
        let meta = Array<Int64>(4, repeat: 0)
        let captured = synchronized(lock) {
            if (dumped) { false } else {
                dumped = true
                for (i in 0..rows.size) { saved[i].copyFrom(rows[i]); saved[i + rows.size].copyFrom(firstSlow[i]) }
                for (i in 0..pumps.size) { for (j in 0..pumps[i].size) { savedPumps[i][j] = pumps[i][j] } }
                for (j in 0..slowPump.size) { savedPumps[128][j] = slowPump[j] }
                meta[0] = firstTimeoutLease; meta[1] = slowPump[0]; meta[2] = dropped; meta[3] = overwritten
                true
            }
        }
        if (!captured) { return }
        let builder = StringBuilder()
        builder.append("CJGUI_REQUEST_DIAG_SUMMARY endpoint=${endpoint} generation=${generation} snapshot=1 " +
            "capacity=160 active_limit=32 terminal_limit=128 phase_slots=24 pump_capacity=128 " +
            "first_timeout=${meta[0]} first_slow=${meta[1]} dropped=${meta[2]} overwritten=${meta[3]} clock=relative_MonoTime_ns\n")
        builder.append("CJGUI_REQUEST_DIAG_PHASES 0=deadline_origin 1=queued 2=claim_try 3=claimed " +
            "4=claim_refused 5=cancel_unclaimed 6=dispatch_begin 7=dispatch_end 8=owner_response_published " +
            "9=io_response_taken 10=frame_encode_begin 11=frame_encode_end 12=provider_begin " +
            "13=provider_end 14=range_validate_begin 15=range_validate_end 16=hex_begin " +
            "17=hex_end 18=range_wrap_end 19=socket_begin 20=socket_end 21=io_terminal 22=cancel\n")
        builder.append("CJGUI_REQUEST_DIAG_PUMP_SLOTS 0=id 1=entry 2=transport_lock_acquired 3=purge_begin " +
            "4=purge_end 5=ready_begin 6=ready_end 7=return 8=state_lock_try 9=state_lock_acquired " +
            "10=state_lock_released 11=active_before 12=cleanup_before 13=active_after 14=cleanup_after\n")
        var count: Int64 = 0; var pumpCount: Int64 = 0
        for (i in 0..saved.size) {
            if (saved[i].lease != 0) { count += 1 }
            dumpRow(builder, saved[i], if (i < 160) { "recent" } else { "first_slow" })
        }
        for (i in 0..128) { if (savedPumps[i][0] > 0) { pumpCount += 1; builder.append("CJGUI_REQUEST_DIAG_PUMP ${savedPumps[i]}\n") } }
        if (savedPumps[128][0] > 0) { builder.append("CJGUI_REQUEST_DIAG_SLOW_PUMP ${savedPumps[128]}\n") }
        builder.append("CJGUI_REQUEST_DIAG_COMPLETE endpoint=${endpoint} generation=${generation} snapshot=1 records=${count} pumps=${pumpCount}\n")
        let payload = builder.toString()
        if (payload.size > 1024 * 1024) { println("CJGUI_REQUEST_DIAG_EXPORT error=over_capacity"); return }
        if (let Some(prefix) <- getVariable("CJGUI_REQUEST_DIAGNOSTIC_OUTPUT")) {
            let path = "${prefix}.${endpoint}.${generation}.txt"
            if (exists(path)) { println("CJGUI_REQUEST_DIAG_EXPORT error=path_exists"); return }
            try (output = File.create(path)) {
                output.write(payload.toArray())
                println("CJGUI_REQUEST_DIAG_EXPORT bytes=${payload.size} destination=owned_file")
            } catch (_: Exception) { println("CJGUI_REQUEST_DIAG_EXPORT error=write_failed") }
        } else { print(payload) }
    }
    private func dumpRow(builder: StringBuilder, row: CjguiSharedRequestDiagnosticRow, cohort: String): Unit {
        if (row.lease == 0) { return }
        builder.append("CJGUI_REQUEST_DIAG cohort=${cohort} lease=${row.lease} op=${row.op} resource=${row.resource} " +
            "expected=${row.expected} start=${row.start} end=${row.end} bytes=${row.bytes} depth=${row.depth} " +
            "predecessor=${row.predecessor} pump=${row.pump} terminal=${row.terminal} times=${row.times}\n")
    }
}

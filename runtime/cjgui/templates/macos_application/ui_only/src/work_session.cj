package cjgui_ui_only_starter

import std.collection.*
import std.convert.*

/// This application's optional payload. The framework only stores validated
/// bytes; it does not know the note, counter, or view revision.
class UiOnlyWorkState {
    var note: String
    var count: Int64
    var revision: Int64

    init(note: String, count: Int64, revision: Int64) {
        this.note = note
        this.count = count
        this.revision = revision
    }

    func payload(): String {
        let digits = "0123456789ABCDEF".toArray()
        let encoded = ArrayList<UInt8>()
        for (byte in note) {
            encoded.add(digits[Int64(byte) / 16])
            encoded.add(digits[Int64(byte) % 16])
        }
        let text = if (encoded.size == 0) { "-" } else { String.fromUtf8(encoded.toArray()) }
        return "ui-only.note-counter.v1\n${count}\n${revision}\n${text}"
    }
}

private func uiOnlyNonnegativeInteger(value: String): Int64 {
    if (value.size == 0) { return -1 }
    for (byte in value) {
        if (byte < b'0' || byte > b'9') { return -1 }
    }
    return try { Int64.parse(value) } catch (_) { -1 }
}

private func uiOnlyHexDigit(value: Byte): Int64 {
    if (value >= b'0' && value <= b'9') { return Int64(value) - Int64(b'0') }
    if (value >= b'A' && value <= b'F') { return Int64(value) - Int64(b'A') + 10 }
    return -1
}

func uiOnlyDecodeWorkPayload(payload: String): ?UiOnlyWorkState {
    if (payload.size > 16500) { return None }
    let parts = payload.split("\n")
    if (parts.size != 4 || parts[0] != "ui-only.note-counter.v1") { return None }
    let count = uiOnlyNonnegativeInteger(parts[1])
    let revision = uiOnlyNonnegativeInteger(parts[2])
    // App payloads retain a large increment margin; process-scoped renderer
    // counters are never restored from this file.
    if (count < 0 || count > 1000000 || revision < 1 || revision > 1000000000000) { return None }
    let encoded = parts[3].toArray()
    if (parts[3] != "-" && (encoded.size == 0 || encoded.size % 2 != 0 || encoded.size > 16384)) {
        return None
    }
    let bytes = ArrayList<UInt8>()
    if (parts[3] != "-") {
        var index: Int64 = 0
        while (index < encoded.size) {
            let high = uiOnlyHexDigit(encoded[index])
            let low = uiOnlyHexDigit(encoded[index + 1])
            if (high < 0 || low < 0) { return None }
            bytes.add(UInt8(high * 16 + low))
            index += 2
        }
    }
    try {
        let candidate = UiOnlyWorkState(String.fromUtf8(bytes.toArray()), count, revision)
        if (candidate.payload() != payload) { return None }
        return Some(candidate)
    } catch (_) {
        return None
    }
}

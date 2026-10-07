// E/macOS: package-private provenance for a real, installed bounded source proxy.
// Native freezes preBody before TextKit mutation. This is not a public alignment bypass.
package cjgui

import std.collection.ArrayList

// The private native queue charges retained payload plus the two caller
// copies before allowing TextKit mutation. A full 64 KiB mirror may grow by
// a small edit; materialization capacity is not a post-edit body limit.
let CJGUI_INSTALLED_RANGE_PAYLOAD_BUDGET: Int64 = 4 * 1024 * 1024
let CJGUI_INSTALLED_RANGE_PAYLOAD_COPIES: Int64 = 3

class CjguiInstalledRangeBasis {
    let nonce: UInt64
    let document: UInt64
    let binding: UInt64
    let context: Int64
    let mirror: Int64
    let ownerVersion: Int64
    let sourceStart: Int64
    let sourceEnd: Int64
    let text: String
    init(nonce: UInt64, document: UInt64, binding: UInt64, context: Int64,
        mirror: Int64, ownerVersion: Int64, sourceStart: Int64, sourceEnd: Int64, text: String) {
        this.nonce = nonce; this.document = document; this.binding = binding
        this.context = context; this.mirror = mirror; this.ownerVersion = ownerVersion
        this.sourceStart = sourceStart; this.sourceEnd = sourceEnd; this.text = text
    }
}

class CjguiInstalledRangeInput {
    let basis: CjguiInstalledRangeBasis
    let proxyGeneration: UInt64
    let sequence: UInt64
    let previousSequence: UInt64
    let observedAckSequence: UInt64
    let observedAckVersion: Int64
    let preBody: String
    let start16: Int64
    let end16: Int64
    let wholeChoiceNonce: UInt64
    let wholeChoicePrevious: UInt64
    init(basis: CjguiInstalledRangeBasis, proxyGeneration: UInt64, sequence: UInt64,
        previousSequence: UInt64, observedAckSequence: UInt64, observedAckVersion: Int64,
        preBody: String, start16: Int64, end16: Int64,
        wholeChoiceNonce!: UInt64 = 0, wholeChoicePrevious!: UInt64 = 0) {
        this.basis = basis; this.proxyGeneration = proxyGeneration; this.sequence = sequence
        this.previousSequence = previousSequence; this.observedAckSequence = observedAckSequence
        this.observedAckVersion = observedAckVersion; this.preBody = preBody
        this.start16 = start16; this.end16 = end16
        this.wholeChoiceNonce = wholeChoiceNonce; this.wholeChoicePrevious = wholeChoicePrevious
    }
}

class CjguiInstalledRangeChain {
    let basis: CjguiInstalledRangeBasis
    let proxyGeneration: UInt64
    var acceptedSequence: UInt64 = 0
    var acceptedVersion: Int64
    var acceptedSourceStart: Int64
    var lastWholeChoiceNonce: UInt64 = 0
    var postBody: String
    var closed: Bool = false
    let receipts: ArrayList<(UInt64, Int64, Int64, Int64)> = ArrayList<(UInt64, Int64, Int64, Int64)>()
    init(basis: CjguiInstalledRangeBasis, proxyGeneration: UInt64) {
        this.basis = basis; this.proxyGeneration = proxyGeneration
        this.acceptedVersion = basis.ownerVersion; this.postBody = basis.text
        this.acceptedSourceStart = basis.sourceStart
    }
    func matches(input: CjguiInstalledRangeInput): Bool {
        let b = input.basis
        return b.nonce == basis.nonce && b.document == basis.document && b.binding == basis.binding &&
            b.context == basis.context && b.mirror == basis.mirror && b.ownerVersion == basis.ownerVersion &&
            input.proxyGeneration == proxyGeneration
    }
    func observedAckMatches(input: CjguiInstalledRangeInput): Bool {
        if (input.observedAckSequence == 0) {
            return input.observedAckVersion == basis.ownerVersion &&
                input.basis.sourceStart == basis.sourceStart && input.basis.sourceEnd == basis.sourceEnd
        }
        for ((seq, ver, start, end) in receipts) {
            if (seq == input.observedAckSequence) {
                return ver == input.observedAckVersion && input.basis.sourceStart == start && input.basis.sourceEnd == end
            }
        }
        return false
    }
    func accept(input: CjguiInstalledRangeInput, version: Int64, body: String): Unit {
        acceptedSequence = input.sequence; acceptedVersion = version; postBody = body
        if (receipts.size >= 256) { receipts.remove(at: 0) }
        receipts.add((input.sequence, version, acceptedSourceStart, acceptedSourceStart + cjguiUtf8Length(body)))
    }
}

/// Read-only owner snapshot for a cross-fragment selection transfer. The
/// native receipt remains the authority that proves this body was actually
/// installed; this value only supplies the exact owner-ACKed bytes and source
/// scope to compare with that receipt.
class CjguiInstalledSelectionSourceSnapshot {
    let basis: CjguiInstalledRangeBasis
    let acceptedSequence: UInt64
    let acceptedVersion: Int64
    let sourceStart: Int64
    let sourceEnd: Int64
    let proxyGeneration: UInt64
    let body: String
    init(basis: CjguiInstalledRangeBasis, acceptedSequence: UInt64, acceptedVersion: Int64,
        sourceStart: Int64, sourceEnd: Int64, proxyGeneration: UInt64, body: String) {
        this.basis = basis; this.acceptedSequence = acceptedSequence
        this.acceptedVersion = acceptedVersion; this.sourceStart = sourceStart
        this.sourceEnd = sourceEnd; this.proxyGeneration = proxyGeneration; this.body = body
    }
}

package cjgui

import std.collection.*

/// Experimental macOS opt-in for a public Slider whose continuous input may
/// cross accepted redraws. The producer supplies the actual accepted transfer
/// function and a non-reused revision for every independent navigation or
/// mapping transition, including transitions restored before a scene publish.
/// Controllers without this contract retain conservative scene admission.
public interface CjguiComposableUiSliderCaptureProvider {
    func sliderCaptureMapping(node: CjguiComposableUiLayoutNode): ?CjguiComposableUiSliderCaptureMapping
}

/// Track/thumb coordinates use the target's accepted layout coordinate domain.
/// Thumb position and value are outputs; thumb extent changes interpretation.
/// This contains no platform object or renderer session identifier.
public class CjguiComposableUiSliderCaptureMapping {
    public let revision: Int64
    public let trackStart: Float64
    public let trackLength: Float64
    public let thumbLength: Float64
    public let thumbStart: Float64
    public let value: Int64
    public let outputReceipt: ?CjguiComposableUiSliderCaptureReceipt
    public let isVertical: Bool
    public init(revision: Int64, trackStart: Float64, trackLength: Float64,
        thumbLength: Float64, thumbStart: Float64, value: Int64,
        outputReceipt!: ?CjguiComposableUiSliderCaptureReceipt = None, isVertical!: Bool = true) {
        this.revision = revision
        this.trackStart = trackStart
        this.trackLength = trackLength
        this.thumbLength = thumbLength
        this.thumbStart = thumbStart
        this.value = value
        this.outputReceipt = outputReceipt
        this.isVertical = isVertical
    }
    func valid(node: CjguiComposableUiLayoutNode): Bool {
        return revision >= 0 && CjguiComposableUiEffectValidation.isFinite(trackStart) &&
            CjguiComposableUiEffectValidation.isFinite(trackLength) &&
            CjguiComposableUiEffectValidation.isFinite(thumbLength) &&
            CjguiComposableUiEffectValidation.isFinite(thumbStart) && trackLength > 0.0 &&
            thumbLength >= 0.0 && thumbLength <= trackLength &&
            value >= node.pointerControlMinimum && value <= node.pointerControlMaximum
    }
    func sameTransfer(other: CjguiComposableUiSliderCaptureMapping): Bool {
        return revision == other.revision && trackStart == other.trackStart &&
            trackLength == other.trackLength && thumbLength == other.thumbLength &&
            isVertical == other.isVertical
    }
}

/// Immutable receipt created by the framework's one current input intent.
/// Its constructor is package-private; producers retain the actual returned
/// object in their serialized owner state before publishing a scene.
public class CjguiComposableUiSliderCaptureReceipt {
    public let value: Int64
    public let predecessor: UInt64
    public let generation: UInt64
    let captureSerial: UInt64
    let operationSerial: UInt64
    let ownerRevision: Int64
    let mappingRevision: Int64
    init(value: Int64, predecessor: UInt64, generation: UInt64, captureSerial: UInt64,
        operationSerial: UInt64, ownerRevision: Int64, mappingRevision: Int64) {
        this.value = value
        this.predecessor = predecessor
        this.generation = generation
        this.captureSerial = captureSerial
        this.operationSerial = operationSerial
        this.ownerRevision = ownerRevision
        this.mappingRevision = mappingRevision
    }
    func sameAs(other: CjguiComposableUiSliderCaptureReceipt): Bool {
        return value == other.value && predecessor == other.predecessor && generation == other.generation &&
            captureSerial == other.captureSerial && operationSerial == other.operationSerial &&
            ownerRevision == other.ownerRevision && mappingRevision == other.mappingRevision
    }
}

/// One admitted input operation, issued before the business callback. It has
/// no native handle. Commit only after the actual owner mutation, while still
/// on the serialized owner path and before any scene containing it is accepted.
/// Each intent can commit once; failure never manufactures an output receipt.
public class CjguiComposableUiSliderCaptureIntent {
    private let position: Float64
    private let facts: CjguiMacSliderCaptureFacts
    private let operation: UInt64
    private let guard: () -> Bool
    private let readOutput: () -> ?Int64
    private var used: Bool = false
    init(position: Float64, facts: CjguiMacSliderCaptureFacts, operation: UInt64,
        guard: () -> Bool, readOutput: () -> ?Int64) {
        this.position = position
        this.facts = facts
        this.operation = operation
        this.guard = guard
        this.readOutput = readOutput
    }
    public func isCurrent(): Bool {
        return !used && facts.base.revokedReason.size == 0 && guard()
    }
    public func fraction(): Float64 {
        let travel = facts.mapping.trackLength - facts.mapping.thumbLength
        if (travel <= 0.0) { return 0.0 }
        let raw = (position - facts.mapping.trackStart - facts.grabOffset) / travel
        return if (raw < 0.0) { 0.0 } else if (raw > 1.0) { 1.0 } else { raw }
    }
    public func commit(value: Int64): ?CjguiComposableUiSliderCaptureReceipt {
        if (!isCurrent() || facts.operationSerial != operation || facts.outputGeneration == UInt64.Max ||
            facts.outputs.size >= 1024) { return None }
        let actual = readOutput()
        if (actual.isNone() || actual.getOrThrow() != value || !guard()) { return None }
        used = true
        let next = CjguiComposableUiSliderCaptureReceipt(value, facts.outputGeneration,
            facts.outputGeneration + 1u64, facts.base.serial, operation,
            facts.base.ownerRevision, facts.mapping.revision)
        facts.outputGeneration = next.generation
        facts.outputs.add(next)
        return Some(next)
    }
}

class CjguiMacSliderPointerFifo {
    let generation: UInt64
    let binding: UInt64
    let first: UInt64
    let last: UInt64
    let previous: UInt64
    let phase: UInt32
    init(generation: UInt64, binding: UInt64, first: UInt64, last: UInt64,
        previous: UInt64, phase: UInt32) {
        this.generation = generation
        this.binding = binding
        this.first = first
        this.last = last
        this.previous = previous
        this.phase = phase
    }
    func follows(cursor: UInt64, expectedGeneration: UInt64, expectedBinding: UInt64,
        kind: UInt32): Bool {
        return generation != 0u64 && generation == expectedGeneration && binding == expectedBinding &&
            cursor != UInt64.Max && first == cursor + 1u64 && previous == cursor && last >= first && phase == kind
    }
}

class CjguiMacSliderCaptureFacts {
    let base: CjguiMacTextCaptureFacts
    let mapping: CjguiComposableUiSliderCaptureMapping
    let grabOffset: Float64
    let minimum: Int64
    let maximum: Int64
    let step: Int64
    let axis: Int64
    let handle: Int64
    let role: String
    let initialOutput: Int64
    let outputs = ArrayList<CjguiComposableUiSliderCaptureReceipt>()
    var outputGeneration: UInt64 = 0u64
    var operationSerial: UInt64 = 0u64
    var fifoCursor: UInt64 = 0u64
    init(base: CjguiMacTextCaptureFacts, mapping: CjguiComposableUiSliderCaptureMapping,
        position: Float64) {
        this.base = base
        this.mapping = mapping
        this.minimum = base.node.pointerControlMinimum
        this.maximum = base.node.pointerControlMaximum
        this.step = base.node.pointerControlStep
        this.axis = base.node.pointerControlAxis
        this.handle = base.node.pointerControlHandleThickness
        this.role = base.node.pointerControlRole
        this.initialOutput = mapping.value
        let relative = position - mapping.thumbStart
        this.grabOffset = if (relative >= 0.0 && relative < mapping.thumbLength) {
            relative
        } else { mapping.thumbLength / 2.0 }
    }
    func latestReceiptMatches(receipt: ?CjguiComposableUiSliderCaptureReceipt, value: Int64): Bool {
        if (outputs.size == 0) { return value == initialOutput }
        if (let Some(actual) <- receipt) {
            let expected = outputs[outputs.size - 1]
            return expected.sameAs(actual) && value == expected.value
        }
        return false
    }
}

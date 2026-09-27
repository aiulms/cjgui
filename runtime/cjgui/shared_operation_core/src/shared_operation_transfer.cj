package cjgui_shared_operation_core

import std.sync.*

private const CJGUI_SHARED_OPERATION_TRANSFER_TEXT_FORMAT: String = "text/utf-8"
private const CJGUI_SHARED_OPERATION_TRANSFER_PNG_FORMAT: String = "image/png"
private const CJGUI_SHARED_OPERATION_TRANSFER_MAXIMUM_BYTES: Int64 = 512 * 1024
private const CJGUI_SHARED_OPERATION_TRANSFER_MAX_IDENTIFIER_BYTES: Int64 = 128
private const CJGUI_SHARED_OPERATION_TRANSFER_MAX_IDENTITY_BYTES: Int64 = 256
private let CJGUI_TRANSFER_OFFER_ID_LOCK = Mutex()
private var cjguiTransferOfferSequence: Int64 = 0

private func nextTransferOfferIdentity(): Int64 {
    return synchronized(CJGUI_TRANSFER_OFFER_ID_LOCK) {
        // Once exhausted, fail closed instead of reusing an image identity.
        if (cjguiTransferOfferSequence >= 0x7FFFFFFFFFFFFFFE) {
            throw IllegalArgumentException("transfer_offer_identity_exhausted")
        }
        cjguiTransferOfferSequence += 1
        cjguiTransferOfferSequence
    }
}

private func copyTransferBytes(source: Array<Byte>): Array<Byte> {
    let copy = Array<Byte>(source.size, repeat: 0)
    var index: Int64 = 0
    while (index < source.size) {
        copy[index] = source[index]
        index += 1
    }
    return copy
}

// A deterministic content checksum for readback and diagnostics. It is not an
// authorization token; consumers comparing untrusted content must compare the
// bytes as well. The bounded 30-bit lanes avoid checked integer overflow.
private func transferContentDigest(bytes: Array<Byte>): String {
    var first: Int64 = 2166136261 & 0x3FFFFFFF
    var second: Int64 = 0x185AC1D
    var index: Int64 = 0
    while (index < bytes.size) {
        let value = Int64(bytes[index])
        first = ((first ^ value) * 16777619) & 0x3FFFFFFF
        second = ((second ^ (value + index)) * 65599) & 0x3FFFFFFF
        index += 1
    }
    return "fnv30x2:${first}:${second}:${bytes.size}"
}

/// Experimental format declaration for one bounded transfer payload.  The
/// transfer layer validates framing and size only; structured payload fields
/// remain owned and interpreted by the receiving application domain.
public class CjguiSharedOperationTransferFormat {
    public let kind: String
    public let identifier: String
    public let version: Int64
    public let maximumBytes: Int64

    private init(kind: String, identifier: String, version: Int64, maximumBytes: Int64) {
        this.kind = kind
        this.identifier = identifier
        this.version = version
        this.maximumBytes = maximumBytes
    }

    public static func utf8Text(maximumBytes!: Int64 = CJGUI_SHARED_OPERATION_TRANSFER_MAXIMUM_BYTES): CjguiSharedOperationTransferFormat {
        return CjguiSharedOperationTransferFormat(
            "UTF8_TEXT", CJGUI_SHARED_OPERATION_TRANSFER_TEXT_FORMAT, 1, maximumBytes)
    }

    /// The application supplies one stable identifier for its structured
    /// payload.  This generic layer never parses that payload as a command.
    public static func structured(
        identifier: String,
        version!: Int64 = 1,
        maximumBytes!: Int64 = CJGUI_SHARED_OPERATION_TRANSFER_MAXIMUM_BYTES
    ): CjguiSharedOperationTransferFormat {
        return CjguiSharedOperationTransferFormat("STRUCTURED", identifier, version, maximumBytes)
    }

    /// Binary formats remain distinct from UTF-8 and structured text. The
    /// platform adapter decides which system representation maps to each ID.
    public static func binary(
        identifier: String,
        version!: Int64 = 1,
        maximumBytes!: Int64 = CJGUI_SHARED_OPERATION_TRANSFER_MAXIMUM_BYTES
    ): CjguiSharedOperationTransferFormat {
        return CjguiSharedOperationTransferFormat("BINARY", identifier, version, maximumBytes)
    }

    public static func png(maximumBytes!: Int64 = CJGUI_SHARED_OPERATION_TRANSFER_MAXIMUM_BYTES): CjguiSharedOperationTransferFormat {
        return binary(CJGUI_SHARED_OPERATION_TRANSFER_PNG_FORMAT, maximumBytes: maximumBytes)
    }

    public func isValid(): Bool {
        if (kind != "UTF8_TEXT" && kind != "STRUCTURED" && kind != "BINARY") { return false }
        if (identifier.size == 0 || identifier.size > CJGUI_SHARED_OPERATION_TRANSFER_MAX_IDENTIFIER_BYTES ||
            version <= 0 || maximumBytes <= 0 || maximumBytes > CJGUI_SHARED_OPERATION_TRANSFER_MAXIMUM_BYTES) {
            return false
        }
        if (kind == "UTF8_TEXT") {
            return identifier == CJGUI_SHARED_OPERATION_TRANSFER_TEXT_FORMAT && version == 1
        }
        return identifier != CJGUI_SHARED_OPERATION_TRANSFER_TEXT_FORMAT
    }

    public func acceptsPayload(payload: String): Bool {
        return kind != "BINARY" && isValid() && payload.size <= maximumBytes
    }

    public func acceptsBinaryPayload(bytes: Array<Byte>): Bool {
        return kind == "BINARY" && isValid() && bytes.size > 0 && bytes.size <= maximumBytes
    }
}

/// Immutable copy offer.  It is a bounded value packet, not a retained
/// pasteboard or dragging object and does not own or mutate application data.
public class CjguiSharedOperationTransferOffer {
    public let operation: String
    public let sourceKind: String
    public let sourceIdentity: String
    public let sourceId: Int64
    public let format: CjguiSharedOperationTransferFormat
    public let payload: String
    public let payloadByteCount: Int64
    public let contentDigest: String
    /// Process-local immutable incarnation, used for scene/resource signatures.
    /// Content equality is still checked by bytes; this is not authority.
    public let offerIdentity: Int64
    private let binaryPayload: Array<Byte>

    private init(
        operation: String,
        sourceKind: String,
        sourceIdentity: String,
        sourceId: Int64,
        format: CjguiSharedOperationTransferFormat,
        payload: String,
        binaryPayload: Array<Byte>
    ) {
        this.operation = operation
        this.sourceKind = sourceKind
        this.sourceIdentity = sourceIdentity
        this.sourceId = sourceId
        this.format = format
        this.payload = payload
        this.binaryPayload = binaryPayload
        this.payloadByteCount = if (format.kind == "BINARY") { binaryPayload.size } else { payload.size }
        this.contentDigest = if (format.kind == "BINARY") { transferContentDigest(binaryPayload) } else { "" }
        this.offerIdentity = nextTransferOfferIdentity()
    }

    public static func create(
        operation: String,
        sourceKind: String,
        sourceIdentity: String,
        sourceId: Int64,
        format: CjguiSharedOperationTransferFormat,
        payload: String
    ): ?CjguiSharedOperationTransferOffer {
        if (operation != "COPY" || sourceKind.size == 0 || sourceIdentity.size == 0 || sourceId < 0 ||
            sourceKind.size > CJGUI_SHARED_OPERATION_TRANSFER_MAX_IDENTIFIER_BYTES ||
            sourceIdentity.size > CJGUI_SHARED_OPERATION_TRANSFER_MAX_IDENTITY_BYTES ||
            !format.acceptsPayload(payload)) {
            return None
        }
        return Some(CjguiSharedOperationTransferOffer(
            operation, sourceKind, sourceIdentity, sourceId, format, payload, Array<Byte>()))
    }

    public static func createBinary(
        operation: String,
        sourceKind: String,
        sourceIdentity: String,
        sourceId: Int64,
        format: CjguiSharedOperationTransferFormat,
        bytes: Array<Byte>
    ): ?CjguiSharedOperationTransferOffer {
        if (operation != "COPY" || sourceKind.size == 0 || sourceIdentity.size == 0 || sourceId < 0 ||
            sourceKind.size > CJGUI_SHARED_OPERATION_TRANSFER_MAX_IDENTIFIER_BYTES ||
            sourceIdentity.size > CJGUI_SHARED_OPERATION_TRANSFER_MAX_IDENTITY_BYTES ||
            !format.acceptsBinaryPayload(bytes)) {
            return None
        }
        return Some(CjguiSharedOperationTransferOffer(
            operation, sourceKind, sourceIdentity, sourceId, format, "", copyTransferBytes(bytes)))
    }

    /// Never expose the stored mutable array. Native and application callers
    /// each receive their own bounded copy with no pointer lifetime contract.
    public func binaryBytes(): Array<Byte> {
        return copyTransferBytes(binaryPayload)
    }

    public func fitsFormat(format: CjguiSharedOperationTransferFormat): Bool {
        return if (this.format.kind == "BINARY") {
            format.acceptsBinaryPayload(binaryPayload)
        } else {
            format.acceptsPayload(payload)
        }
    }
}

/// Target-bound acceptance request.  A consumer creates it only after it has
/// selected a live target and the owner version it intends to protect.
public class CjguiSharedOperationTransferAcceptRequest {
    public let targetKind: String
    public let targetIdentity: String
    public let targetId: Int64
    public let offer: CjguiSharedOperationTransferOffer
    public let acceptedFormat: CjguiSharedOperationTransferFormat
    public let expectedVersion: Int64

    private init(
        targetKind: String,
        targetIdentity: String,
        targetId: Int64,
        offer: CjguiSharedOperationTransferOffer,
        acceptedFormat: CjguiSharedOperationTransferFormat,
        expectedVersion: Int64
    ) {
        this.targetKind = targetKind
        this.targetIdentity = targetIdentity
        this.targetId = targetId
        this.offer = offer
        this.acceptedFormat = acceptedFormat
        this.expectedVersion = expectedVersion
    }

    public static func create(
        targetKind: String,
        targetIdentity: String,
        targetId: Int64,
        offer: CjguiSharedOperationTransferOffer,
        acceptedFormat: CjguiSharedOperationTransferFormat,
        expectedVersion: Int64
    ): ?CjguiSharedOperationTransferAcceptRequest {
        if (targetKind.size == 0 || targetIdentity.size == 0 || targetId < 0 || expectedVersion < 0 ||
            targetKind.size > CJGUI_SHARED_OPERATION_TRANSFER_MAX_IDENTIFIER_BYTES ||
            targetIdentity.size > CJGUI_SHARED_OPERATION_TRANSFER_MAX_IDENTITY_BYTES ||
            !acceptedFormat.isValid() || !offer.format.isValid() ||
            acceptedFormat.kind != offer.format.kind ||
            acceptedFormat.identifier != offer.format.identifier ||
            acceptedFormat.version != offer.format.version ||
            !offer.fitsFormat(acceptedFormat)) {
            return None
        }
        return Some(CjguiSharedOperationTransferAcceptRequest(
            targetKind, targetIdentity, targetId, offer, acceptedFormat, expectedVersion))
    }
}

/// Result adapter preserving the receiving domain's existing CAS outcome.
/// A transfer result is a projection of the owner action, never a second
/// mutation record or a claim that a platform drop was physically visible.
public class CjguiSharedOperationTransferResult {
    public let applied: Bool
    public let isVersionConflict: Bool
    public let versionBefore: Int64
    public let versionAfter: Int64
    public let formatKind: String
    public let formatIdentifier: String
    public let reason: String

    public init(
        applied: Bool,
        isVersionConflict: Bool,
        versionBefore: Int64,
        versionAfter: Int64,
        formatKind: String,
        formatIdentifier: String,
        reason: String
    ) {
        this.applied = applied
        this.isVersionConflict = isVersionConflict
        this.versionBefore = versionBefore
        this.versionAfter = versionAfter
        this.formatKind = formatKind
        this.formatIdentifier = formatIdentifier
        this.reason = reason
    }

    public static func fromActionResult(
        result: CjguiSharedOperationActionResult,
        offer: CjguiSharedOperationTransferOffer
    ): CjguiSharedOperationTransferResult {
        return CjguiSharedOperationTransferResult(
            result.applied, result.isVersionConflict, result.versionBefore, result.versionAfter,
            offer.format.kind, offer.format.identifier, result.reason)
    }

    public static func rejected(
        version: Int64,
        reason: String,
        format!: ?CjguiSharedOperationTransferFormat = None,
        isVersionConflict!: Bool = false
    ): CjguiSharedOperationTransferResult {
        let kind = if (let Some(value) <- format) { value.kind } else { "" }
        let identifier = if (let Some(value) <- format) { value.identifier } else { "" }
        return CjguiSharedOperationTransferResult(
            false, isVersionConflict, version, version, kind, identifier, reason)
    }
}

package cjgui_shared_operation_core

private const CJGUI_SHARED_OPERATION_TRANSFER_TEXT_FORMAT: String = "text/utf-8"
private const CJGUI_SHARED_OPERATION_TRANSFER_MAXIMUM_BYTES: Int64 = 512 * 1024
private const CJGUI_SHARED_OPERATION_TRANSFER_MAX_IDENTIFIER_BYTES: Int64 = 128
private const CJGUI_SHARED_OPERATION_TRANSFER_MAX_IDENTITY_BYTES: Int64 = 256

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

    public func isValid(): Bool {
        if (kind != "UTF8_TEXT" && kind != "STRUCTURED") { return false }
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
        return isValid() && payload.size <= maximumBytes
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

    private init(
        operation: String,
        sourceKind: String,
        sourceIdentity: String,
        sourceId: Int64,
        format: CjguiSharedOperationTransferFormat,
        payload: String
    ) {
        this.operation = operation
        this.sourceKind = sourceKind
        this.sourceIdentity = sourceIdentity
        this.sourceId = sourceId
        this.format = format
        this.payload = payload
        this.payloadByteCount = payload.size
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
            operation, sourceKind, sourceIdentity, sourceId, format, payload))
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
            !acceptedFormat.acceptsPayload(offer.payload)) {
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

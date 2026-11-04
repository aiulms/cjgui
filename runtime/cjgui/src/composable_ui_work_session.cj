// Optional persistence for application-owned business work. The application
// defines and validates its payload; this layer only frames, bounds and binds
// it to the trusted text-file atomic save path.
package cjgui

import cjgui_shared_operation_core.*
import std.collection.*
import std.convert.*

public class CjguiComposableUiWorkSessionResult {
    public let ok: Bool
    public let reason: String
    /// Present only after a complete load or save of a validated payload.
    public let payload: String

    public init(ok: Bool, reason: String, payload!: String = "") {
        this.ok = ok
        this.reason = reason
        this.payload = payload
    }
}

/// Experimental API. One explicit, optional application work-session file. It restores only the
/// caller's business payload; native windows, endpoint identities, tickets and
/// other process-scoped state never enter this envelope.
public class CjguiComposableUiWorkSession {
    private let pathValue: String
    private let schemaValue: String
    private let maximumBytesValue: Int64
    private let validatePayloadValue: (String) -> Bool
    private let binding: CjguiTextDocumentFileBinding
    private var baselinePayload: ?String = None

    public init(path: String, schema: String, maximumBytes: Int64,
        validatePayload: (String) -> Bool) {
        this.pathValue = path
        this.schemaValue = schema
        this.maximumBytesValue = maximumBytes
        this.validatePayloadValue = validatePayload
        this.binding = CjguiTextDocumentFileBinding()
    }

    /// A missing/invalid file is a refusal; no default application state is
    /// mutated and no rejected bytes become a trusted overwrite baseline.
    public func load(): CjguiComposableUiWorkSessionResult {
        if (pathValue.size == 0) {
            return CjguiComposableUiWorkSessionResult(false, "no_file_path")
        }
        if (maximumBytesValue < 0) {
            return CjguiComposableUiWorkSessionResult(false, "invalid_byte_limit")
        }
        let validations = ArrayList<CjguiComposableUiWorkSessionResult>()
        let opened = binding.openValidatedWithReasonFromHuman(0, "Business work session", pathValue,
            maximumBytesValue, { envelope =>
                let validated = decodeEnvelope(envelope)
                validations.add(validated)
                if (validated.ok) { "" } else { validated.reason }
            })
        if (!opened.applied) {
            if (validations.size == 1) { return validations[0] }
            return CjguiComposableUiWorkSessionResult(false, opened.reason)
        }
        if (validations.size != 1 || !validations[0].ok) {
            // The binding may adopt bytes only after this one complete result
            // accepts them. Never call app code again after adoption.
            return CjguiComposableUiWorkSessionResult(false, "work_session_envelope")
        }
        let decoded = validations[0]
        baselinePayload = Some(decoded.payload)
        return decoded
    }

    /// Save is explicit. Invalid schema payloads, oversize frames, external
    /// rewrites and failed writes leave the prior file and dirty baseline intact.
    public func save(payload: String): CjguiComposableUiWorkSessionResult {
        if (pathValue.size == 0) {
            return CjguiComposableUiWorkSessionResult(false, "no_file_path")
        }
        if (maximumBytesValue < 0) {
            return CjguiComposableUiWorkSessionResult(false, "invalid_byte_limit")
        }
        let schemaBytes = schemaValue.size
        let payloadBytes = payload.size
        if (schemaBytes > maximumBytesValue || payloadBytes > maximumBytesValue ||
            estimatedWorkSessionEnvelopeBytes(schemaBytes, payloadBytes) > maximumBytesValue) {
            return CjguiComposableUiWorkSessionResult(false, "work_session_too_large")
        }
        let valid = try { validatePayloadValue(payload) } catch (_) { false }
        if (!valid) {
            return CjguiComposableUiWorkSessionResult(false, "work_session_payload_refused")
        }
        let envelope = encodeEnvelope(payload)
        if (envelope.size > maximumBytesValue) {
            return CjguiComposableUiWorkSessionResult(false, "work_session_too_large")
        }
        let document = CjguiTextDocument(0, "Business work session", envelope)
        let written = binding.saveBoundedFromHuman(document.snapshot(), pathValue, maximumBytesValue)
        if (!written.applied) {
            return CjguiComposableUiWorkSessionResult(false, written.reason)
        }
        baselinePayload = Some(payload)
        return CjguiComposableUiWorkSessionResult(true, "saved", payload: payload)
    }

    /// Explicit dirty state against the last fully validated load or successful
    /// atomic save. Before either operation the current app state is unsaved.
    public func isDirty(payload: String): Bool {
        match (baselinePayload) {
            case Some(saved) => saved != payload
            case None => true
        }
    }

    private func encodeEnvelope(payload: String): String {
        let schemaHex = CjguiSharedOperationFrame.encodeUtf8Hex(schemaValue)
        let payloadHex = CjguiSharedOperationFrame.encodeUtf8Hex(payload)
        return "CJGUI_WORK_SESSION 1\n" +
            "SCHEMA ${schemaValue.size} ${schemaHex}\n" +
            "PAYLOAD ${payload.size} ${payloadHex}\n" +
            "END"
    }

    private func decodeEnvelope(envelope: String): CjguiComposableUiWorkSessionResult {
        let lines = envelope.split("\n")
        if (lines.size != 4 || lines[0] != "CJGUI_WORK_SESSION 1") {
            return CjguiComposableUiWorkSessionResult(false, "work_session_envelope")
        }
        let schemaParts = lines[1].split(" ")
        let payloadParts = lines[2].split(" ")
        if (schemaParts.size != 3 || schemaParts[0] != "SCHEMA" ||
            payloadParts.size != 3 || payloadParts[0] != "PAYLOAD" || lines[3] != "END") {
            return CjguiComposableUiWorkSessionResult(false, "work_session_envelope")
        }
        let schemaBytes = parseNonnegative(schemaParts[1])
        let payloadBytes = parseNonnegative(payloadParts[1])
        if (schemaBytes < 0 || payloadBytes < 0) {
            return CjguiComposableUiWorkSessionResult(false, "work_session_envelope")
        }
        let decodedSchema = decodeUtf8Hex(schemaParts[2], schemaBytes)
        let decodedPayload = decodeUtf8Hex(payloadParts[2], payloadBytes)
        if (decodedSchema.isNone() || decodedPayload.isNone()) {
            return CjguiComposableUiWorkSessionResult(false, "work_session_envelope")
        }
        let schema = decodedSchema.getOrThrow()
        if (schema != schemaValue) {
            return CjguiComposableUiWorkSessionResult(false, "work_session_schema")
        }
        let payload = decodedPayload.getOrThrow()
        let valid = try { validatePayloadValue(payload) } catch (_) { false }
        if (!valid) {
            return CjguiComposableUiWorkSessionResult(false, "work_session_payload_refused")
        }
        return CjguiComposableUiWorkSessionResult(true, "loaded", payload: payload)
    }

}

private func estimatedWorkSessionEnvelopeBytes(schemaBytes: Int64, payloadBytes: Int64): Int64 {
    let schemaHexBytes = if (schemaBytes == 0) { 1 } else { schemaBytes * 2 }
    let payloadHexBytes = if (payloadBytes == 0) { 1 } else { payloadBytes * 2 }
    let schemaLineBytes = "SCHEMA ".size + schemaBytes.toString().size + 1 + schemaHexBytes + 1
    let payloadLineBytes = "PAYLOAD ".size + payloadBytes.toString().size + 1 + payloadHexBytes + 1
    return "CJGUI_WORK_SESSION 1\n".size + schemaLineBytes + payloadLineBytes + "END".size
}

private func parseNonnegative(value: String): Int64 {
    if (value.size == 0) { return -1 }
    for (byte in value) {
        if (byte < b'0' || byte > b'9') { return -1 }
    }
    try {
        return Int64.parse(value)
    } catch (_) {
        return -1
    }
}

private func decodeUtf8Hex(encoded: String, byteCount: Int64): ?String {
    if (byteCount == 0 && encoded == "-") { return Some("") }
    if (byteCount < 0 || encoded.size != byteCount * 2) { return None }
    let source = encoded.toArray()
    let bytes = ArrayList<UInt8>()
    var index: Int64 = 0
    while (index < source.size) {
        let high = workSessionHexValue(source[index])
        let low = workSessionHexValue(source[index + 1])
        if (high < 0 || low < 0) { return None }
        bytes.add(UInt8(high * 16 + low))
        index += 2
    }
    try {
        return Some(String.fromUtf8(bytes.toArray()))
    } catch (_) {
        return None
    }
}

private func workSessionHexValue(value: Byte): Int64 {
    if (value >= b'0' && value <= b'9') { return Int64(value) - Int64(b'0') }
    if (value >= b'A' && value <= b'F') { return Int64(value) - Int64(b'A') + 10 }
    return -1
}

package cjgui

import cjgui_shared_operation_core.*

// First public surface declaration for the generated-UI contract. These are
// framework facts, emitted beside the existing catalog description so a client
// can distinguish "this capability is registered and admission will accept it"
// from "this delivery was actually observed for the target backend".
public let CJGUI_GENERATED_UI_SURFACE_VERSION: String = "1.0"
public let CJGUI_GENERATED_UI_SURFACE_STABILITY: String = "experimental"
public let CJGUI_GENERATED_UI_SURFACE_COMPATIBILITY: String = "additive_only"
public let CJGUI_GENERATED_UI_PUBLIC_SUBSET: String =
    "host,layout,fields,commands,identity,generated,read_write"

public let CJGUI_GENERATED_UI_SUPPORT_STATES: String = "available,fallback,unavailable,unverified"
public let CJGUI_GENERATED_UI_EVIDENCE_STATES: String = "verified,unverified"
public let CJGUI_GENERATED_UI_SUPPORT_ITEM_MAX_BYTES: Int64 = 128
public let CJGUI_GENERATED_UI_SUPPORT_REASON_MAX_BYTES: Int64 = 512
public let CJGUI_GENERATED_UI_EVIDENCE_ITEM_MAX_BYTES: Int64 = 192
public let CJGUI_GENERATED_UI_EVIDENCE_REASON_MAX_BYTES: Int64 = 512

/// A discovery token stays on one line and cannot be mistaken for a
/// key=value token. Unsafe text (spaces, non-ASCII, controls) is carried as
/// `u8:<hex>`; a legacy reader still sees one opaque token, while a current
/// reader decodes it. The byte budget is checked before encoding.
public func cjguiGeneratedUiTextTokenIsSafe(value: String): Bool {
    if (value.size == 0 || value.startsWith("u8:")) {
        return false
    }
    for (rune in value.runes()) {
        let scalar = UInt32(rune)
        if (scalar < 0x21 || scalar > 0x7E || scalar == 0x3D) {
            return false
        }
    }
    return true
}

public func cjguiGeneratedUiEncodeTextToken(value: String): String {
    if (cjguiGeneratedUiTextTokenIsSafe(value)) {
        return value
    }
    return "u8:" + CjguiSharedOperationFrame.encodeUtf8Hex(value)
}

public func cjguiGeneratedUiTextFits(value: String, maxBytes: Int64): Bool {
    return value.toArray().size <= maxBytes
}

/// Discovery text is bounded and single-line before it can be encoded. The
/// encoder handles spaces and non-ASCII; this check only refuses empty text,
/// controls and over-budget values.
public func cjguiGeneratedUiDiscoveryTextIsValid(value: String, maxBytes: Int64): Bool {
    if (value.size == 0 || !cjguiGeneratedUiTextFits(value, maxBytes)) {
        return false
    }
    for (rune in value.runes()) {
        let scalar = UInt32(rune)
        if (scalar < 0x20 || scalar == 0x7F) {
            return false
        }
    }
    return true
}

public func cjguiGeneratedUiSupportStateIsKnown(state: String): Bool {
    return state == "available" || state == "fallback" || state == "unavailable" || state == "unverified"
}

public func cjguiGeneratedUiEvidenceStateIsKnown(state: String): Bool {
    return state == "verified" || state == "unverified"
}

/// One discovery fact for a registered catalog item. `available` is produced
/// only from the same registration/admission table that accepts the item; it is
/// not a free-text backend claim. Delivery evidence is a separate EVIDENCE
/// record, so `available` never implies "verified on this backend".
public class CjguiGeneratedUiSupportFact {
    public let kind: String
    public let item: String
    public let state: String
    public let reason: String
    public let source: String

    public init(kind: String, item: String, state: String, reason: String, source: String) {
        this.kind = kind
        this.item = item
        this.state = state
        this.reason = reason
        this.source = source
    }
}

/// App-declared delivery evidence for one discovered item. The framework never
/// upgrades evidence on its own; an absent record is published as unverified.
public class CjguiGeneratedUiDeliveryEvidence {
    public let item: String
    public let state: String
    public let reason: String

    public init(item: String, state: String, reason: String) {
        this.item = item
        this.state = state
        this.reason = reason
    }
}

@When[os == "macOS"]
public class CjguiComposableUiRuntimeBackend {
    public static let TOKEN: String = "macos_appkit"
}

@When[os == "Windows"]
public class CjguiComposableUiRuntimeBackend {
    public static let TOKEN: String = "windows_native"
}

@When[os == "Linux"]
public class CjguiComposableUiRuntimeBackend {
    public static let TOKEN: String = "linux_x11"
}

@When[os != "macOS" && os != "Windows" && os != "Linux"]
public class CjguiComposableUiRuntimeBackend {
    public static let TOKEN: String = "portable_backend"
}

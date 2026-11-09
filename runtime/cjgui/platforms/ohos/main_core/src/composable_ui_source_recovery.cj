package cjgui

import std.collection.*

/// Experimental: a complete held Windows input record. Source identity remains
/// explicit; receiving it grants no authority to replay it into another binding.
public class CjguiSourceInstallRecoveryRecord {
    public let windowSession: UInt64
    public let sessionGeneration: UInt64
    public let recordId: UInt64
    public let reason: UInt32
    public let outcome: UInt32
    public let inputId: UInt64
    public let bindingEpoch: UInt64
    public let requestId: UInt64
    public let kind: UInt32
    public let modifiers: Int64
    public let repeatCount: UInt32
    public let compositionId: UInt64
    public let phase: UInt32
    public let cursor16: UInt32
    public let handledParts: UInt32
    public let text: String
    public let extraText: String
    init(session: UInt64, meta: Array<UInt64>, text: String, extraText: String) {
        this.windowSession = session
        this.sessionGeneration = meta[15]
        this.recordId = meta[0]
        this.reason = UInt32(meta[1])
        this.outcome = UInt32(meta[2])
        this.inputId = meta[3]
        this.bindingEpoch = meta[4]
        this.requestId = meta[5]
        this.kind = UInt32(meta[6])
        this.modifiers = Int64(meta[7])
        this.repeatCount = UInt32(meta[8])
        this.compositionId = meta[9]
        this.phase = UInt32(meta[10])
        this.cursor16 = UInt32(meta[11])
        this.handledParts = UInt32(meta[14])
        this.text = text
        this.extraText = extraText
    }
}

/// Experimental: true means the consumer owns the entire record durably.
/// Repeated delivery of the same session/generation/record must be idempotent.
/// False or an exception retains the native record and prevents destructive close.
public interface CjguiComposableUiSourceRecoveryProvider {
    func receiveSourceInstallRecovery(record: CjguiSourceInstallRecoveryRecord): Bool
}

@When[os == "Windows"]
foreign {
    func cjgui_internal_renderer_peek_install_recovery_v1(session: UInt64,
        meta: CPointer<UInt64>, bytes: CPointer<UInt8>, capacity: UInt32,
        extra: CPointer<UInt8>, extraCapacity: UInt32): Int32
    func cjgui_internal_renderer_ack_install_recovery_v1(session: UInt64, recordId: UInt64): Int32
}

@When[os == "Windows"]
func internalRendererPeekSourceInstallRecovery(session: UInt64): (Int32, ?CjguiSourceInstallRecoveryRecord) {
    let meta = Array<UInt64>(16, repeat: 0u64)
    let bytes = Array<UInt8>(262144, repeat: 0u8)
    let extra = Array<UInt8>(65536, repeat: 0u8)
    let status = unsafe {
        let m = acquireArrayRawData(meta)
        let b = acquireArrayRawData(bytes)
        let e = acquireArrayRawData(extra)
        let st = cjgui_internal_renderer_peek_install_recovery_v1(session,
            m.pointer, b.pointer, 262144u32, e.pointer, 65536u32)
        releaseArrayRawData(e)
        releaseArrayRawData(b)
        releaseArrayRawData(m)
        st
    }
    if (status != CJGUI_INTERNAL_RENDERER_OK || meta[0] == 0u64) { return (status, None) }
    return (status, Some(CjguiSourceInstallRecoveryRecord(session, meta,
        String.fromUtf8(bytes.slice(0, Int64(meta[12]))),
        String.fromUtf8(extra.slice(0, Int64(meta[13]))))))
}
@When[os != "Windows"]
func internalRendererPeekSourceInstallRecovery(session: UInt64): (Int32, ?CjguiSourceInstallRecoveryRecord) {
    let _ = session
    return (CJGUI_INTERNAL_RENDERER_OK, None)
}
@When[os == "Windows"]
func internalRendererAckSourceInstallRecovery(session: UInt64, recordId: UInt64): Int32 {
    return unsafe { cjgui_internal_renderer_ack_install_recovery_v1(session, recordId) }
}
@When[os != "Windows"]
func internalRendererAckSourceInstallRecovery(session: UInt64, recordId: UInt64): Int32 {
    let _ = session
    let _ = recordId
    return CJGUI_INTERNAL_RENDERER_OK
}

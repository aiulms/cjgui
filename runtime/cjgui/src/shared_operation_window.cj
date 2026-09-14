package cjgui

import cjgui_shared_operation_core.*

// The native renderer is deliberately a small, fixed-size projection. This
// limit never constrains the Cangjie list, whose record identities remain the
// source of truth for both visible and screen-off actions.
private let CJGUI_SHARED_OPERATION_MAX_VISIBLE_RECORDS: Int64 = 8
private let CJGUI_SHARED_OPERATION_MAX_NATIVE_TOTAL_RECORDS: Int64 = 4294967295

/// Experimental API: one bounded pump outcome from the native shared-operation
/// window. The public value contains application facts only; it never exposes
/// a native window, view, Metal object, or C pointer.
public class CjguiSharedOperationWindowPumpResult {
    public let isOpen: Bool
    public let didApplyHumanAction: Bool
    public let nativeStatus: Int32

    public init(isOpen: Bool, didApplyHumanAction: Bool, nativeStatus: Int32) {
        this.isOpen = isOpen
        this.didApplyHumanAction = didApplyHumanAction
        this.nativeStatus = nativeStatus
    }
}

/// Experimental API: a normal CJGUI consumer-facing window for an arbitrary
/// bounded list. The Cangjie list remains the mutable truth owner; this class
/// projects at most eight rows at once and returns human intent to the same
/// list methods used by the external connection.
public class CjguiSharedOperationWindow {
    private let list: CjguiSharedOperationList
    private var sessionToken: UInt64
    private var isWindowOpen: Bool
    private var lastNativeStatus: Int32
    private var viewportStart: Int64

    public init(list: CjguiSharedOperationList) {
        this.list = list
        this.sessionToken = CJGUI_INTERNAL_RENDERER_INVALID_SESSION_TOKEN
        this.isWindowOpen = false
        this.lastNativeStatus = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
        this.viewportStart = 0
    }

    /// Creates and presents the window. The native view receives only its
    /// current 1–8-row viewport; the list itself may contain many more stable
    /// records and is never copied into native mutable state.
    public func start(): Bool {
        if (isWindowOpen) {
            return true
        }

        let snapshot = list.snapshot()
        if (!hasNativeRepresentableRecordCount(snapshot)) {
            lastNativeStatus = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
            return false
        }
        viewportStart = 0

        let config = CjguiInternalRendererConfig(
            windowWidth: 720u32,
            // Eight visible rows need space below the last row for the
            // version/selection footer; this remains a small fixed viewport.
            windowHeight: 480u32,
            clearColorRed: 0.94,
            clearColorGreen: 0.95,
            clearColorBlue: 0.97,
            clearColorAlpha: 1.0
        )
        let created = internalRendererCreate(config)
        if (created.status != CJGUI_INTERNAL_RENDERER_OK || created.token ==
            CJGUI_INTERNAL_RENDERER_INVALID_SESSION_TOKEN) {
            lastNativeStatus = created.status
            return false
        }

        sessionToken = created.token
        lastNativeStatus = internalRendererConfigureSharedOperation(
            sessionToken,
            UInt32(visibleRecordCount(snapshot))
        )
        if (lastNativeStatus != CJGUI_INTERNAL_RENDERER_OK) {
            discardSession()
            return false
        }

        let frame = internalRendererPresentClear(
            sessionToken,
            CjguiInternalRendererClearColor(
                red: 0.94,
                green: 0.95,
                blue: 0.97,
                alpha: 1.0
            )
        )
        if (frame.status != CJGUI_INTERNAL_RENDERER_OK) {
            lastNativeStatus = frame.status
            discardSession()
            return false
        }

        isWindowOpen = true
        if (!syncProjection()) {
            discardSession()
            return false
        }
        return true
    }

    /// Pumps one bounded native event and immediately projects the actual list
    /// state. It is safe to call repeatedly while an external connection is
    /// updating the list from a different Cangjie thread.
    public func pump(timeoutMs: UInt32): CjguiSharedOperationWindowPumpResult {
        if (!isWindowOpen) {
            return CjguiSharedOperationWindowPumpResult(false, false, lastNativeStatus)
        }

        let event = internalRendererPumpEvent(sessionToken, timeoutMs)
        lastNativeStatus = event.status
        if (event.status != CJGUI_INTERNAL_RENDERER_OK) {
            discardSession()
            return CjguiSharedOperationWindowPumpResult(false, false, lastNativeStatus)
        }
        if (event.eventKind == 1u32) {
            discardSession()
            return CjguiSharedOperationWindowPumpResult(false, false, lastNativeStatus)
        }

        var didApplyHumanAction = false
        let snapshot = list.snapshot()
        if (event.eventKind == 4u32) {
            let _ = moveViewportForHumanBrowsing(snapshot, false)
        } else if (event.eventKind == 5u32) {
            let _ = moveViewportForHumanBrowsing(snapshot, true)
        }
        if (event.eventKind == 2u32 || event.eventKind == 3u32) {
            if (let Some(recordId) <- visibleRecordId(snapshot, Int64(event.recordIndex))) {
                if (event.eventKind == 2u32) {
                    let result = list.selectFromHuman(recordId)
                    didApplyHumanAction = result.applied
                } else {
                    let result = list.toggleFromHuman(recordId)
                    didApplyHumanAction = result.applied
                }
            }
        }

        if (!syncProjection()) {
            discardSession()
            return CjguiSharedOperationWindowPumpResult(false, didApplyHumanAction, lastNativeStatus)
        }
        return CjguiSharedOperationWindowPumpResult(true, didApplyHumanAction, lastNativeStatus)
    }

    /// Requests native close and releases the bounded internal renderer slot.
    public func close() {
        if (isWindowOpen) {
            let closeStatus = internalRendererRequestClose(sessionToken)
            if (closeStatus != CJGUI_INTERNAL_RENDERER_OK) {
                lastNativeStatus = closeStatus
            }
        }
        discardSession()
    }

    public func isOpen(): Bool {
        return isWindowOpen
    }

    /// Returns the most recent internal renderer status without leaking the
    /// renderer session token or another native object.
    public func nativeStatus(): Int32 {
        return lastNativeStatus
    }

    // Package-internal viewport operations keep the native bridge testable
    // without promoting view state to the experimental public list contract.
    // `towardNext` changes only which stable list records are projected; it
    // never changes selected or marked application state.
    func moveViewportForHumanBrowsing(
        snapshot: CjguiSharedOperationSnapshot,
        towardNext: Bool
    ): Bool {
        clampViewportStart(snapshot)
        let maximumStart = maximumViewportStart(snapshot)
        if (towardNext) {
            if (viewportStart >= maximumStart) {
                return false
            }
            viewportStart += 1
            return true
        }
        if (viewportStart == 0) {
            return false
        }
        viewportStart -= 1
        return true
    }

    // Package-internal so focused tests can prove that a visual row is mapped
    // through the current viewport to a stable application record identity.
    func visibleRecordId(
        snapshot: CjguiSharedOperationSnapshot,
        visibleIndex: Int64
    ): ?Int64 {
        clampViewportStart(snapshot)
        if (visibleIndex < 0 || visibleIndex >= visibleRecordCount(snapshot)) {
            return None
        }
        return snapshot.recordAt(viewportStart + visibleIndex).id
    }

    private func syncProjection(): Bool {
        let snapshot = list.snapshot()
        if (!hasNativeRepresentableRecordCount(snapshot)) {
            lastNativeStatus = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR
            return false
        }
        clampViewportStart(snapshot)
        let visibleCount = visibleRecordCount(snapshot)
        var markedMask: UInt64 = 0
        var factor: UInt64 = 1
        var selectedIndex: UInt32 = 4294967295u32
        var visibleIndex: Int64 = 0
        while (visibleIndex < visibleCount) {
            let record = snapshot.recordAt(viewportStart + visibleIndex)
            lastNativeStatus = internalRendererSetSharedOperationTitle(
                sessionToken,
                UInt32(visibleIndex),
                record.title
            )
            if (lastNativeStatus != CJGUI_INTERNAL_RENDERER_OK) {
                return false
            }
            if (record.isMarked) {
                markedMask += factor
            }
            if (record.id == snapshot.selectedRecordId) {
                selectedIndex = UInt32(visibleIndex)
            }
            factor *= 2
            visibleIndex += 1
        }

        lastNativeStatus = internalRendererSetSharedOperationState(
            sessionToken,
            CjguiInternalRendererSharedOperationState(
                selectedRecordId: snapshot.selectedRecordId,
                markedRecordMask: markedMask,
                version: UInt64(snapshot.version),
                selectedRecordIndex: selectedIndex,
                recordCount: UInt32(visibleCount),
                viewportStart: UInt32(viewportStart),
                totalRecordCount: UInt32(snapshot.records.size)
            )
        )
        return lastNativeStatus == CJGUI_INTERNAL_RENDERER_OK
    }

    private func hasNativeRepresentableRecordCount(snapshot: CjguiSharedOperationSnapshot): Bool {
        return snapshot.records.size > 0 && snapshot.records.size <= CJGUI_SHARED_OPERATION_MAX_NATIVE_TOTAL_RECORDS
    }

    private func maximumViewportStart(snapshot: CjguiSharedOperationSnapshot): Int64 {
        if (snapshot.records.size <= CJGUI_SHARED_OPERATION_MAX_VISIBLE_RECORDS) {
            return 0
        }
        return snapshot.records.size - CJGUI_SHARED_OPERATION_MAX_VISIBLE_RECORDS
    }

    private func clampViewportStart(snapshot: CjguiSharedOperationSnapshot) {
        let maximumStart = maximumViewportStart(snapshot)
        if (viewportStart > maximumStart) {
            viewportStart = maximumStart
        }
        if (viewportStart < 0) {
            viewportStart = 0
        }
    }

    private func visibleRecordCount(snapshot: CjguiSharedOperationSnapshot): Int64 {
        let remaining = snapshot.records.size - viewportStart
        if (remaining < CJGUI_SHARED_OPERATION_MAX_VISIBLE_RECORDS) {
            return remaining
        }
        return CJGUI_SHARED_OPERATION_MAX_VISIBLE_RECORDS
    }

    private func discardSession() {
        if (sessionToken != CJGUI_INTERNAL_RENDERER_INVALID_SESSION_TOKEN) {
            let destroyStatus = internalRendererDestroy(sessionToken)
            if (destroyStatus != CJGUI_INTERNAL_RENDERER_OK) {
                lastNativeStatus = destroyStatus
            }
        }
        sessionToken = CJGUI_INTERNAL_RENDERER_INVALID_SESSION_TOKEN
        isWindowOpen = false
    }
}

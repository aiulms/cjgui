// 中文维护注释：本文件是 visible-window production harness NSWindow native first-slice owner。
// Owner: runtime renderer internal visible-window NSWindow harness FFI call owner。
// Truth: 只消费 CjguiInternalRendererNoVisibleWindowProductionHarnessReadiness，
// 调用 token-backed NSWindow harness create / classify / destroy C ABI，并把结果脱水为
// internal readiness facts。
// Stop-line: 不返回 Class / id / pointer / handle，不调用 production nextDrawable，
// 不创建 command buffer / render command encoder，不 draw，不 commit，不 present，不提交 GPU work，
// 不执行 render，不写 runtime_state.cj，不扩 public API。
// Same-shape Boundary Brake: 不得把本 owner 包成 drawable-ready、render-ready、
// backend-ready、renderer state write、receipt、record 或 publication wrapper。
package cjgui

foreign func cjgui_native_bridge_nswindow_harness_table_capacity(): UInt32
foreign func cjgui_native_bridge_nswindow_harness_table_enabled(): UInt32
foreign func cjgui_native_bridge_nswindow_harness_table_occupied_count(): UInt32
foreign func cjgui_native_bridge_nswindow_harness_create(
    outWindowToken: CPointer<UInt64>
): Int32
foreign func cjgui_native_bridge_nswindow_harness_destroy(
    windowToken: UInt64
): Int32
foreign func cjgui_native_bridge_nswindow_harness_token_classify(
    windowToken: UInt64
): Int32
foreign func cjgui_native_bridge_nswindow_harness_double_destroy_classify(
    windowToken: UInt64
): Int32
foreign func cjgui_native_bridge_nswindow_harness_create_requires_main_thread():
    Int32
foreign func cjgui_native_bridge_nswindow_harness_destroy_requires_main_thread():
    Int32
foreign func cjgui_native_bridge_nswindow_harness_next_drawable_still_blocked():
    Int32
foreign func
cjgui_native_bridge_nswindow_harness_command_buffer_still_blocked(): Int32
foreign func
cjgui_native_bridge_nswindow_harness_render_encoder_still_blocked(): Int32
foreign func cjgui_native_bridge_nswindow_harness_present_still_blocked():
    Int32

struct CjguiInternalRendererVisibleWindowNsWindowHarnessObservation {
    let tableCapacityValue: UInt32
    let tableEnabledValue: UInt32
    let occupiedBeforeValue: UInt32
    let createStatusValue: Int32
    let createdWindowTokenValue: UInt64
    let validTokenClassValue: Int32
    let invalidDestroyStatusValue: Int32
    let createRequiresMainThreadValue: Int32
    let destroyRequiresMainThreadValue: Int32
    let nextDrawableBlockedValue: Int32
    let commandBufferBlockedValue: Int32
    let renderEncoderBlockedValue: Int32
    let presentBlockedValue: Int32
    let destroyStatusValue: Int32
    let occupiedAfterCreateValue: UInt32
    let occupiedAfterDestroyValue: UInt32
    let destroyedTokenClassValue: Int32
    let doubleDestroyClassValue: Int32
    let didObserveFixedCapacityTable: Bool
    let didObserveTableEnabled: Bool
    let didObserveMainThreadCreateDestroyLifecycle: Bool
    let didObserveOpaqueWindowToken: Bool
    let didObserveValidWindowTokenClass: Bool
    let didObserveOccupiedCountLifecycle: Bool
    let didObserveDestroyedWindowTokenStale: Bool
    let didObserveDoubleDestroyFailClosed: Bool
    let didObserveInvalidTokenFailClosed: Bool
    let didConfirmNextDrawableStillBlocked: Bool
    let didConfirmCommandBufferStillBlocked: Bool
    let didConfirmRenderEncoderStillBlocked: Bool
    let didConfirmPresentStillBlocked: Bool
    let didConfirmNoPointerHandleClassIdReturn: Bool

    init(
        tableCapacityValue: UInt32,
        tableEnabledValue: UInt32,
        occupiedBeforeValue: UInt32,
        createStatusValue: Int32,
        createdWindowTokenValue: UInt64,
        validTokenClassValue: Int32,
        invalidDestroyStatusValue: Int32,
        createRequiresMainThreadValue: Int32,
        destroyRequiresMainThreadValue: Int32,
        nextDrawableBlockedValue: Int32,
        commandBufferBlockedValue: Int32,
        renderEncoderBlockedValue: Int32,
        presentBlockedValue: Int32,
        destroyStatusValue: Int32,
        occupiedAfterCreateValue: UInt32,
        occupiedAfterDestroyValue: UInt32,
        destroyedTokenClassValue: Int32,
        doubleDestroyClassValue: Int32,
        didObserveFixedCapacityTable: Bool,
        didObserveTableEnabled: Bool,
        didObserveMainThreadCreateDestroyLifecycle: Bool,
        didObserveOpaqueWindowToken: Bool,
        didObserveValidWindowTokenClass: Bool,
        didObserveOccupiedCountLifecycle: Bool,
        didObserveDestroyedWindowTokenStale: Bool,
        didObserveDoubleDestroyFailClosed: Bool,
        didObserveInvalidTokenFailClosed: Bool,
        didConfirmNextDrawableStillBlocked: Bool,
        didConfirmCommandBufferStillBlocked: Bool,
        didConfirmRenderEncoderStillBlocked: Bool,
        didConfirmPresentStillBlocked: Bool,
        didConfirmNoPointerHandleClassIdReturn: Bool
    ) {
        this.tableCapacityValue = tableCapacityValue
        this.tableEnabledValue = tableEnabledValue
        this.occupiedBeforeValue = occupiedBeforeValue
        this.createStatusValue = createStatusValue
        this.createdWindowTokenValue = createdWindowTokenValue
        this.validTokenClassValue = validTokenClassValue
        this.invalidDestroyStatusValue = invalidDestroyStatusValue
        this.createRequiresMainThreadValue = createRequiresMainThreadValue
        this.destroyRequiresMainThreadValue = destroyRequiresMainThreadValue
        this.nextDrawableBlockedValue = nextDrawableBlockedValue
        this.commandBufferBlockedValue = commandBufferBlockedValue
        this.renderEncoderBlockedValue = renderEncoderBlockedValue
        this.presentBlockedValue = presentBlockedValue
        this.destroyStatusValue = destroyStatusValue
        this.occupiedAfterCreateValue = occupiedAfterCreateValue
        this.occupiedAfterDestroyValue = occupiedAfterDestroyValue
        this.destroyedTokenClassValue = destroyedTokenClassValue
        this.doubleDestroyClassValue = doubleDestroyClassValue
        this.didObserveFixedCapacityTable = didObserveFixedCapacityTable
        this.didObserveTableEnabled = didObserveTableEnabled
        this.didObserveMainThreadCreateDestroyLifecycle =
            didObserveMainThreadCreateDestroyLifecycle
        this.didObserveOpaqueWindowToken = didObserveOpaqueWindowToken
        this.didObserveValidWindowTokenClass = didObserveValidWindowTokenClass
        this.didObserveOccupiedCountLifecycle =
            didObserveOccupiedCountLifecycle
        this.didObserveDestroyedWindowTokenStale =
            didObserveDestroyedWindowTokenStale
        this.didObserveDoubleDestroyFailClosed =
            didObserveDoubleDestroyFailClosed
        this.didObserveInvalidTokenFailClosed =
            didObserveInvalidTokenFailClosed
        this.didConfirmNextDrawableStillBlocked =
            didConfirmNextDrawableStillBlocked
        this.didConfirmCommandBufferStillBlocked =
            didConfirmCommandBufferStillBlocked
        this.didConfirmRenderEncoderStillBlocked =
            didConfirmRenderEncoderStillBlocked
        this.didConfirmPresentStillBlocked = didConfirmPresentStillBlocked
        this.didConfirmNoPointerHandleClassIdReturn =
            didConfirmNoPointerHandleClassIdReturn
    }
}

struct CjguiInternalRendererVisibleWindowNsWindowHarnessReadiness {
    let visibleWindowProductionHarnessReadiness:
        CjguiInternalRendererNoVisibleWindowProductionHarnessReadiness
    let nsWindowHarnessObservation:
        CjguiInternalRendererVisibleWindowNsWindowHarnessObservation
    let didPrepareRendererVisibleWindowNsWindowHarnessReadiness: Bool
    let shouldDeferRendererVisibleWindowNsWindowHarnessReadiness: Bool
    let shouldReportRendererVisibleWindowNsWindowHarnessBlocked: Bool
    let didPreserveVisibleWindowProductionHarnessPolicyReadiness: Bool
    let didConfirmNativeNsWindowHarnessUnlockedByCurrentStage: Bool
    let didConfirmTokenBackedNsWindowCreateDestroy: Bool
    let didConfirmFixedCapacityNsWindowTable: Bool
    let didConfirmMainThreadCreateDestroyGate: Bool
    let didConfirmOpaqueTokenIdentity: Bool
    let didConfirmTokenNotPointer: Bool
    let didConfirmDestroyedTokenStale: Bool
    let didConfirmDoubleDestroyFailClosed: Bool
    let didConfirmInvalidTokenFailClosed: Bool
    let didConfirmProductionNextDrawableStillBlocked: Bool
    let didConfirmCommandBufferEncoderCommitPresentGpuRenderBlocked: Bool
    let didConfirmNoPublicSurface: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didConfirmNoBackendReadyTruth: Bool
    let didKeepNsWindowHarnessReadinessDehydrated: Bool
    let didAvoidDrawableReadyWrapper: Bool
    let didAvoidRenderPermissionWrapper: Bool
    let didAvoidReceiptRecordPublication: Bool
    let didAvoidThinWrapper: Bool

    init(
        visibleWindowProductionHarnessReadiness:
            CjguiInternalRendererNoVisibleWindowProductionHarnessReadiness,
        nsWindowHarnessObservation:
            CjguiInternalRendererVisibleWindowNsWindowHarnessObservation,
        didPrepareRendererVisibleWindowNsWindowHarnessReadiness: Bool,
        shouldDeferRendererVisibleWindowNsWindowHarnessReadiness: Bool,
        shouldReportRendererVisibleWindowNsWindowHarnessBlocked: Bool,
        didPreserveVisibleWindowProductionHarnessPolicyReadiness: Bool,
        didConfirmNativeNsWindowHarnessUnlockedByCurrentStage: Bool,
        didConfirmTokenBackedNsWindowCreateDestroy: Bool,
        didConfirmFixedCapacityNsWindowTable: Bool,
        didConfirmMainThreadCreateDestroyGate: Bool,
        didConfirmOpaqueTokenIdentity: Bool,
        didConfirmTokenNotPointer: Bool,
        didConfirmDestroyedTokenStale: Bool,
        didConfirmDoubleDestroyFailClosed: Bool,
        didConfirmInvalidTokenFailClosed: Bool,
        didConfirmProductionNextDrawableStillBlocked: Bool,
        didConfirmCommandBufferEncoderCommitPresentGpuRenderBlocked: Bool,
        didConfirmNoPublicSurface: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didConfirmNoBackendReadyTruth: Bool,
        didKeepNsWindowHarnessReadinessDehydrated: Bool,
        didAvoidDrawableReadyWrapper: Bool,
        didAvoidRenderPermissionWrapper: Bool,
        didAvoidReceiptRecordPublication: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.visibleWindowProductionHarnessReadiness =
            visibleWindowProductionHarnessReadiness
        this.nsWindowHarnessObservation = nsWindowHarnessObservation
        this.didPrepareRendererVisibleWindowNsWindowHarnessReadiness =
            didPrepareRendererVisibleWindowNsWindowHarnessReadiness
        this.shouldDeferRendererVisibleWindowNsWindowHarnessReadiness =
            shouldDeferRendererVisibleWindowNsWindowHarnessReadiness
        this.shouldReportRendererVisibleWindowNsWindowHarnessBlocked =
            shouldReportRendererVisibleWindowNsWindowHarnessBlocked
        this.didPreserveVisibleWindowProductionHarnessPolicyReadiness =
            didPreserveVisibleWindowProductionHarnessPolicyReadiness
        this.didConfirmNativeNsWindowHarnessUnlockedByCurrentStage =
            didConfirmNativeNsWindowHarnessUnlockedByCurrentStage
        this.didConfirmTokenBackedNsWindowCreateDestroy =
            didConfirmTokenBackedNsWindowCreateDestroy
        this.didConfirmFixedCapacityNsWindowTable =
            didConfirmFixedCapacityNsWindowTable
        this.didConfirmMainThreadCreateDestroyGate =
            didConfirmMainThreadCreateDestroyGate
        this.didConfirmOpaqueTokenIdentity = didConfirmOpaqueTokenIdentity
        this.didConfirmTokenNotPointer = didConfirmTokenNotPointer
        this.didConfirmDestroyedTokenStale = didConfirmDestroyedTokenStale
        this.didConfirmDoubleDestroyFailClosed =
            didConfirmDoubleDestroyFailClosed
        this.didConfirmInvalidTokenFailClosed =
            didConfirmInvalidTokenFailClosed
        this.didConfirmProductionNextDrawableStillBlocked =
            didConfirmProductionNextDrawableStillBlocked
        this.didConfirmCommandBufferEncoderCommitPresentGpuRenderBlocked =
            didConfirmCommandBufferEncoderCommitPresentGpuRenderBlocked
        this.didConfirmNoPublicSurface = didConfirmNoPublicSurface
        this.didConfirmNoRendererStateWrite = didConfirmNoRendererStateWrite
        this.didConfirmNoBackendReadyTruth = didConfirmNoBackendReadyTruth
        this.didKeepNsWindowHarnessReadinessDehydrated =
            didKeepNsWindowHarnessReadinessDehydrated
        this.didAvoidDrawableReadyWrapper = didAvoidDrawableReadyWrapper
        this.didAvoidRenderPermissionWrapper = didAvoidRenderPermissionWrapper
        this.didAvoidReceiptRecordPublication = didAvoidReceiptRecordPublication
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

func cjguiInternalObserveRendererVisibleWindowNsWindowHarnessValues():
    CjguiInternalRendererVisibleWindowNsWindowHarnessObservation {
    let tableCapacity = unsafe {
        cjgui_native_bridge_nswindow_harness_table_capacity()
    }
    let tableEnabled = unsafe {
        cjgui_native_bridge_nswindow_harness_table_enabled()
    }
    let occupiedBefore = unsafe {
        cjgui_native_bridge_nswindow_harness_table_occupied_count()
    }
    var createdWindowToken = UInt64(0)
    let createStatus = unsafe {
        cjgui_native_bridge_nswindow_harness_create(inout createdWindowToken)
    }
    let occupiedAfterCreate = unsafe {
        cjgui_native_bridge_nswindow_harness_table_occupied_count()
    }
    let validTokenClass = unsafe {
        cjgui_native_bridge_nswindow_harness_token_classify(createdWindowToken)
    }
    let invalidDestroyStatus = unsafe {
        cjgui_native_bridge_nswindow_harness_destroy(UInt64(0))
    }
    let createRequiresMainThread = unsafe {
        cjgui_native_bridge_nswindow_harness_create_requires_main_thread()
    }
    let destroyRequiresMainThread = unsafe {
        cjgui_native_bridge_nswindow_harness_destroy_requires_main_thread()
    }
    let nextDrawableBlocked = unsafe {
        cjgui_native_bridge_nswindow_harness_next_drawable_still_blocked()
    }
    let commandBufferBlocked = unsafe {
        cjgui_native_bridge_nswindow_harness_command_buffer_still_blocked()
    }
    let renderEncoderBlocked = unsafe {
        cjgui_native_bridge_nswindow_harness_render_encoder_still_blocked()
    }
    let presentBlocked = unsafe {
        cjgui_native_bridge_nswindow_harness_present_still_blocked()
    }
    let destroyStatus = unsafe {
        cjgui_native_bridge_nswindow_harness_destroy(createdWindowToken)
    }
    let occupiedAfterDestroy = unsafe {
        cjgui_native_bridge_nswindow_harness_table_occupied_count()
    }
    let destroyedTokenClass = unsafe {
        cjgui_native_bridge_nswindow_harness_token_classify(createdWindowToken)
    }
    let doubleDestroyClass = unsafe {
        cjgui_native_bridge_nswindow_harness_double_destroy_classify(
            createdWindowToken
        )
    }

    return CjguiInternalRendererVisibleWindowNsWindowHarnessObservation(
        tableCapacity,
        tableEnabled,
        occupiedBefore,
        createStatus,
        createdWindowToken,
        validTokenClass,
        invalidDestroyStatus,
        createRequiresMainThread,
        destroyRequiresMainThread,
        nextDrawableBlocked,
        commandBufferBlocked,
        renderEncoderBlocked,
        presentBlocked,
        destroyStatus,
        occupiedAfterCreate,
        occupiedAfterDestroy,
        destroyedTokenClass,
        doubleDestroyClass,
        tableCapacity == UInt32(2),
        tableEnabled == UInt32(1),
        createStatus == Int32(0) && destroyStatus == Int32(0),
        createdWindowToken != UInt64(0),
        validTokenClass == Int32(360),
        occupiedBefore == UInt32(0) &&
            occupiedAfterCreate == UInt32(1) &&
            occupiedAfterDestroy == UInt32(0),
        destroyedTokenClass == Int32(-363),
        doubleDestroyClass == Int32(-366),
        invalidDestroyStatus == Int32(-362),
        nextDrawableBlocked == Int32(-369),
        commandBufferBlocked == Int32(-370),
        renderEncoderBlocked == Int32(-371),
        presentBlocked == Int32(-372),
        true
    )
}

func cjguiInternalBuildRendererVisibleWindowNsWindowHarnessReadiness(
    visibleWindowProductionHarnessReadiness:
        CjguiInternalRendererNoVisibleWindowProductionHarnessReadiness,
    nsWindowHarnessObservation:
        CjguiInternalRendererVisibleWindowNsWindowHarnessObservation
): CjguiInternalRendererVisibleWindowNsWindowHarnessReadiness {
    let upstreamReady =
        visibleWindowProductionHarnessReadiness
            .didPrepareRendererNoVisibleWindowProductionHarnessReadiness &&
        visibleWindowProductionHarnessReadiness
            .canEvaluateFutureNativeVisibleWindowHarnessPreflight &&
        visibleWindowProductionHarnessReadiness
            .didConfirmNativeNsWindowHarnessStillBlocked &&
        visibleWindowProductionHarnessReadiness
            .didConfirmProductionNextDrawableStillBlocked &&
        visibleWindowProductionHarnessReadiness
            .didConfirmColorAttachmentEncoderDrawCommitPresentGpuOrRenderBlocked &&
        visibleWindowProductionHarnessReadiness.didConfirmNoPublicSurface &&
        visibleWindowProductionHarnessReadiness.didConfirmNoRendererStateWrite &&
        visibleWindowProductionHarnessReadiness.didConfirmNoBackendReadyTruth
    let observationReady =
        nsWindowHarnessObservation.didObserveFixedCapacityTable &&
        nsWindowHarnessObservation.didObserveTableEnabled &&
        nsWindowHarnessObservation.didObserveMainThreadCreateDestroyLifecycle &&
        nsWindowHarnessObservation.didObserveOpaqueWindowToken &&
        nsWindowHarnessObservation.didObserveValidWindowTokenClass &&
        nsWindowHarnessObservation.didObserveOccupiedCountLifecycle &&
        nsWindowHarnessObservation.didObserveDestroyedWindowTokenStale &&
        nsWindowHarnessObservation.didObserveDoubleDestroyFailClosed &&
        nsWindowHarnessObservation.didObserveInvalidTokenFailClosed &&
        nsWindowHarnessObservation.didConfirmNextDrawableStillBlocked &&
        nsWindowHarnessObservation.didConfirmCommandBufferStillBlocked &&
        nsWindowHarnessObservation.didConfirmRenderEncoderStillBlocked &&
        nsWindowHarnessObservation.didConfirmPresentStillBlocked &&
        nsWindowHarnessObservation.didConfirmNoPointerHandleClassIdReturn
    let readinessReady = upstreamReady && observationReady

    return CjguiInternalRendererVisibleWindowNsWindowHarnessReadiness(
        visibleWindowProductionHarnessReadiness,
        nsWindowHarnessObservation,
        readinessReady,
        !readinessReady,
        !readinessReady,
        upstreamReady,
        readinessReady,
        nsWindowHarnessObservation.didObserveMainThreadCreateDestroyLifecycle,
        nsWindowHarnessObservation.didObserveFixedCapacityTable,
        nsWindowHarnessObservation.didObserveMainThreadCreateDestroyLifecycle,
        nsWindowHarnessObservation.didObserveOpaqueWindowToken,
        nsWindowHarnessObservation.createdWindowTokenValue < UInt64(4294967296),
        nsWindowHarnessObservation.didObserveDestroyedWindowTokenStale,
        nsWindowHarnessObservation.didObserveDoubleDestroyFailClosed,
        nsWindowHarnessObservation.didObserveInvalidTokenFailClosed,
        nsWindowHarnessObservation.didConfirmNextDrawableStillBlocked,
        nsWindowHarnessObservation.didConfirmCommandBufferStillBlocked &&
            nsWindowHarnessObservation.didConfirmRenderEncoderStillBlocked &&
            nsWindowHarnessObservation.didConfirmPresentStillBlocked,
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        true
    )
}

func cjguiInternalExecuteDefaultRendererVisibleWindowNsWindowHarnessDraft():
    CjguiInternalRendererVisibleWindowNsWindowHarnessReadiness {
    let visibleWindowProductionHarnessReadiness =
        cjguiInternalExecuteDefaultRendererVisibleWindowProductionHarnessDraft()
    let nsWindowHarnessObservation =
        cjguiInternalObserveRendererVisibleWindowNsWindowHarnessValues()
    return cjguiInternalBuildRendererVisibleWindowNsWindowHarnessReadiness(
        visibleWindowProductionHarnessReadiness,
        nsWindowHarnessObservation
    )
}

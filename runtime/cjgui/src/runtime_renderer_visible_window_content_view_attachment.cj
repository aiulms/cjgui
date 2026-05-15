// 中文维护注释：本文件是 visible-window production harness NSWindow
// content-view attachment first-slice owner。
// Owner: runtime renderer internal NSWindow content-view attachment FFI call owner。
// Truth: 只消费 CjguiInternalRendererVisibleWindowNsWindowHarnessReadiness，
// 调用 token-backed NSWindow.contentView attach / classify / detach C ABI，
// 并把结果脱水为 internal readiness facts。
// Stop-line: 不 visible order，不调用 production nextDrawable，不创建 render encoder，
// 不 draw，不 commit，不 present，不提交 GPU work，不执行 render，不返回 Class / id /
// pointer / handle，不写 runtime_state.cj，不扩 public API。
// Same-shape Boundary Brake: 不得把本 owner 包成 visible-ready、drawable-ready、
// render-ready、backend-ready、renderer state write、receipt、record 或 publication wrapper。
package cjgui

foreign func cjgui_native_bridge_nswindow_harness_content_view_attach(
    windowToken: UInt64,
    viewToken: UInt64
): Int32
foreign func cjgui_native_bridge_nswindow_harness_content_view_detach(
    windowToken: UInt64,
    viewToken: UInt64
): Int32
foreign func
cjgui_native_bridge_nswindow_harness_content_view_attachment_classify(
    windowToken: UInt64,
    viewToken: UInt64
): Int32
foreign func
cjgui_native_bridge_nswindow_harness_content_view_double_attach_classify(
    windowToken: UInt64,
    viewToken: UInt64
): Int32
foreign func
cjgui_native_bridge_nswindow_harness_content_view_double_detach_classify(
    windowToken: UInt64,
    viewToken: UInt64
): Int32
foreign func
cjgui_native_bridge_nswindow_harness_content_view_attach_requires_main_thread():
    Int32
foreign func
cjgui_native_bridge_nswindow_harness_content_view_visible_order_still_blocked():
    Int32

struct CjguiInternalRendererVisibleWindowContentViewAttachmentObservation {
    let windowOccupiedBeforeValue: UInt32
    let viewOccupiedBeforeValue: UInt32
    let windowCreateStatusValue: Int32
    let viewCreateStatusValue: Int32
    let windowTokenValue: UInt64
    let viewTokenValue: UInt64
    let attachRequiresMainThreadValue: Int32
    let visibleOrderBlockedValue: Int32
    let nextDrawableBlockedValue: Int32
    let invalidAttachStatusValue: Int32
    let attachStatusValue: Int32
    let attachedClassValue: Int32
    let doubleAttachStatusValue: Int32
    let doubleAttachClassValue: Int32
    let windowDestroyWhileAttachedValue: Int32
    let viewDestroyWhileAttachedValue: Int32
    let detachStatusValue: Int32
    let detachedClassValue: Int32
    let doubleDetachStatusValue: Int32
    let doubleDetachClassValue: Int32
    let viewDestroyStatusValue: Int32
    let windowDestroyStatusValue: Int32
    let windowOccupiedAfterCleanupValue: UInt32
    let viewOccupiedAfterCleanupValue: UInt32
    let staleWindowAttachmentClassValue: Int32
    let staleViewAttachmentClassValue: Int32
    let didObserveCreateTokens: Bool
    let didObserveAttach: Bool
    let didObserveAttachedClassification: Bool
    let didObserveDoubleAttachFailClosed: Bool
    let didObserveDestroyBeforeDetachFailClosed: Bool
    let didObserveDetach: Bool
    let didObserveDetachedClassification: Bool
    let didObserveDoubleDetachFailClosed: Bool
    let didObserveInvalidTokensFailClosed: Bool
    let didObserveStaleTokensFailClosed: Bool
    let didObserveCleanupCounts: Bool
    let didObserveMainThreadRequired: Bool
    let didObserveVisibleOrderStillBlocked: Bool
    let didObserveNextDrawableStillBlocked: Bool
    let didKeepTokensFunctionLocal: Bool
    let didConfirmNoPointerHandleClassIdReturn: Bool
    let didConfirmNoVisibleOrderDrawableRenderOrPresent: Bool

    init(
        windowOccupiedBeforeValue: UInt32,
        viewOccupiedBeforeValue: UInt32,
        windowCreateStatusValue: Int32,
        viewCreateStatusValue: Int32,
        windowTokenValue: UInt64,
        viewTokenValue: UInt64,
        attachRequiresMainThreadValue: Int32,
        visibleOrderBlockedValue: Int32,
        nextDrawableBlockedValue: Int32,
        invalidAttachStatusValue: Int32,
        attachStatusValue: Int32,
        attachedClassValue: Int32,
        doubleAttachStatusValue: Int32,
        doubleAttachClassValue: Int32,
        windowDestroyWhileAttachedValue: Int32,
        viewDestroyWhileAttachedValue: Int32,
        detachStatusValue: Int32,
        detachedClassValue: Int32,
        doubleDetachStatusValue: Int32,
        doubleDetachClassValue: Int32,
        viewDestroyStatusValue: Int32,
        windowDestroyStatusValue: Int32,
        windowOccupiedAfterCleanupValue: UInt32,
        viewOccupiedAfterCleanupValue: UInt32,
        staleWindowAttachmentClassValue: Int32,
        staleViewAttachmentClassValue: Int32,
        didObserveCreateTokens: Bool,
        didObserveAttach: Bool,
        didObserveAttachedClassification: Bool,
        didObserveDoubleAttachFailClosed: Bool,
        didObserveDestroyBeforeDetachFailClosed: Bool,
        didObserveDetach: Bool,
        didObserveDetachedClassification: Bool,
        didObserveDoubleDetachFailClosed: Bool,
        didObserveInvalidTokensFailClosed: Bool,
        didObserveStaleTokensFailClosed: Bool,
        didObserveCleanupCounts: Bool,
        didObserveMainThreadRequired: Bool,
        didObserveVisibleOrderStillBlocked: Bool,
        didObserveNextDrawableStillBlocked: Bool,
        didKeepTokensFunctionLocal: Bool,
        didConfirmNoPointerHandleClassIdReturn: Bool,
        didConfirmNoVisibleOrderDrawableRenderOrPresent: Bool
    ) {
        this.windowOccupiedBeforeValue = windowOccupiedBeforeValue
        this.viewOccupiedBeforeValue = viewOccupiedBeforeValue
        this.windowCreateStatusValue = windowCreateStatusValue
        this.viewCreateStatusValue = viewCreateStatusValue
        this.windowTokenValue = windowTokenValue
        this.viewTokenValue = viewTokenValue
        this.attachRequiresMainThreadValue = attachRequiresMainThreadValue
        this.visibleOrderBlockedValue = visibleOrderBlockedValue
        this.nextDrawableBlockedValue = nextDrawableBlockedValue
        this.invalidAttachStatusValue = invalidAttachStatusValue
        this.attachStatusValue = attachStatusValue
        this.attachedClassValue = attachedClassValue
        this.doubleAttachStatusValue = doubleAttachStatusValue
        this.doubleAttachClassValue = doubleAttachClassValue
        this.windowDestroyWhileAttachedValue = windowDestroyWhileAttachedValue
        this.viewDestroyWhileAttachedValue = viewDestroyWhileAttachedValue
        this.detachStatusValue = detachStatusValue
        this.detachedClassValue = detachedClassValue
        this.doubleDetachStatusValue = doubleDetachStatusValue
        this.doubleDetachClassValue = doubleDetachClassValue
        this.viewDestroyStatusValue = viewDestroyStatusValue
        this.windowDestroyStatusValue = windowDestroyStatusValue
        this.windowOccupiedAfterCleanupValue =
            windowOccupiedAfterCleanupValue
        this.viewOccupiedAfterCleanupValue = viewOccupiedAfterCleanupValue
        this.staleWindowAttachmentClassValue =
            staleWindowAttachmentClassValue
        this.staleViewAttachmentClassValue = staleViewAttachmentClassValue
        this.didObserveCreateTokens = didObserveCreateTokens
        this.didObserveAttach = didObserveAttach
        this.didObserveAttachedClassification =
            didObserveAttachedClassification
        this.didObserveDoubleAttachFailClosed =
            didObserveDoubleAttachFailClosed
        this.didObserveDestroyBeforeDetachFailClosed =
            didObserveDestroyBeforeDetachFailClosed
        this.didObserveDetach = didObserveDetach
        this.didObserveDetachedClassification =
            didObserveDetachedClassification
        this.didObserveDoubleDetachFailClosed =
            didObserveDoubleDetachFailClosed
        this.didObserveInvalidTokensFailClosed =
            didObserveInvalidTokensFailClosed
        this.didObserveStaleTokensFailClosed = didObserveStaleTokensFailClosed
        this.didObserveCleanupCounts = didObserveCleanupCounts
        this.didObserveMainThreadRequired = didObserveMainThreadRequired
        this.didObserveVisibleOrderStillBlocked =
            didObserveVisibleOrderStillBlocked
        this.didObserveNextDrawableStillBlocked =
            didObserveNextDrawableStillBlocked
        this.didKeepTokensFunctionLocal = didKeepTokensFunctionLocal
        this.didConfirmNoPointerHandleClassIdReturn =
            didConfirmNoPointerHandleClassIdReturn
        this.didConfirmNoVisibleOrderDrawableRenderOrPresent =
            didConfirmNoVisibleOrderDrawableRenderOrPresent
    }
}

struct CjguiInternalRendererVisibleWindowContentViewAttachmentReadiness {
    let nsWindowHarnessReadiness:
        CjguiInternalRendererVisibleWindowNsWindowHarnessReadiness
    let contentViewAttachmentObservation:
        CjguiInternalRendererVisibleWindowContentViewAttachmentObservation
    let didPrepareRendererVisibleWindowContentViewAttachmentReadiness: Bool
    let shouldDeferRendererVisibleWindowContentViewAttachmentReadiness: Bool
    let shouldReportRendererVisibleWindowContentViewAttachmentBlocked: Bool
    let didPreserveRendererVisibleWindowNsWindowHarnessReadiness: Bool
    let didConfirmRuntimeInternalContentViewCallExecuted: Bool
    let didConfirmTokensStayedFunctionLocal: Bool
    let didConfirmContentViewAttachClassifyDetachLifecycle: Bool
    let didConfirmDoubleAttachDetachFailClosed: Bool
    let didConfirmDestroyBeforeDetachFailClosed: Bool
    let didConfirmCleanupCountsReturnToZero: Bool
    let didConfirmMainThreadContentViewGate: Bool
    let didConfirmVisibleOrderStillBlocked: Bool
    let didConfirmProductionNextDrawableStillBlocked: Bool
    let didConfirmNoCommandBufferEncoderCommitPresentGpuRender: Bool
    let didConfirmNoPointerHandleClassIdReturn: Bool
    let didConfirmNoPublicSurface: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didConfirmNoBackendReadyTruth: Bool
    let didKeepContentViewAttachmentReadinessDehydrated: Bool
    let didAvoidVisibleReadyWrapper: Bool
    let didAvoidDrawableReadyWrapper: Bool
    let didAvoidReceiptRecordPublication: Bool
    let didAvoidThinWrapper: Bool

    init(
        nsWindowHarnessReadiness:
            CjguiInternalRendererVisibleWindowNsWindowHarnessReadiness,
        contentViewAttachmentObservation:
            CjguiInternalRendererVisibleWindowContentViewAttachmentObservation,
        didPrepareRendererVisibleWindowContentViewAttachmentReadiness: Bool,
        shouldDeferRendererVisibleWindowContentViewAttachmentReadiness: Bool,
        shouldReportRendererVisibleWindowContentViewAttachmentBlocked: Bool,
        didPreserveRendererVisibleWindowNsWindowHarnessReadiness: Bool,
        didConfirmRuntimeInternalContentViewCallExecuted: Bool,
        didConfirmTokensStayedFunctionLocal: Bool,
        didConfirmContentViewAttachClassifyDetachLifecycle: Bool,
        didConfirmDoubleAttachDetachFailClosed: Bool,
        didConfirmDestroyBeforeDetachFailClosed: Bool,
        didConfirmCleanupCountsReturnToZero: Bool,
        didConfirmMainThreadContentViewGate: Bool,
        didConfirmVisibleOrderStillBlocked: Bool,
        didConfirmProductionNextDrawableStillBlocked: Bool,
        didConfirmNoCommandBufferEncoderCommitPresentGpuRender: Bool,
        didConfirmNoPointerHandleClassIdReturn: Bool,
        didConfirmNoPublicSurface: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didConfirmNoBackendReadyTruth: Bool,
        didKeepContentViewAttachmentReadinessDehydrated: Bool,
        didAvoidVisibleReadyWrapper: Bool,
        didAvoidDrawableReadyWrapper: Bool,
        didAvoidReceiptRecordPublication: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.nsWindowHarnessReadiness = nsWindowHarnessReadiness
        this.contentViewAttachmentObservation =
            contentViewAttachmentObservation
        this
            .didPrepareRendererVisibleWindowContentViewAttachmentReadiness =
            didPrepareRendererVisibleWindowContentViewAttachmentReadiness
        this.shouldDeferRendererVisibleWindowContentViewAttachmentReadiness =
            shouldDeferRendererVisibleWindowContentViewAttachmentReadiness
        this.shouldReportRendererVisibleWindowContentViewAttachmentBlocked =
            shouldReportRendererVisibleWindowContentViewAttachmentBlocked
        this.didPreserveRendererVisibleWindowNsWindowHarnessReadiness =
            didPreserveRendererVisibleWindowNsWindowHarnessReadiness
        this.didConfirmRuntimeInternalContentViewCallExecuted =
            didConfirmRuntimeInternalContentViewCallExecuted
        this.didConfirmTokensStayedFunctionLocal =
            didConfirmTokensStayedFunctionLocal
        this.didConfirmContentViewAttachClassifyDetachLifecycle =
            didConfirmContentViewAttachClassifyDetachLifecycle
        this.didConfirmDoubleAttachDetachFailClosed =
            didConfirmDoubleAttachDetachFailClosed
        this.didConfirmDestroyBeforeDetachFailClosed =
            didConfirmDestroyBeforeDetachFailClosed
        this.didConfirmCleanupCountsReturnToZero =
            didConfirmCleanupCountsReturnToZero
        this.didConfirmMainThreadContentViewGate =
            didConfirmMainThreadContentViewGate
        this.didConfirmVisibleOrderStillBlocked =
            didConfirmVisibleOrderStillBlocked
        this.didConfirmProductionNextDrawableStillBlocked =
            didConfirmProductionNextDrawableStillBlocked
        this.didConfirmNoCommandBufferEncoderCommitPresentGpuRender =
            didConfirmNoCommandBufferEncoderCommitPresentGpuRender
        this.didConfirmNoPointerHandleClassIdReturn =
            didConfirmNoPointerHandleClassIdReturn
        this.didConfirmNoPublicSurface = didConfirmNoPublicSurface
        this.didConfirmNoRendererStateWrite = didConfirmNoRendererStateWrite
        this.didConfirmNoBackendReadyTruth = didConfirmNoBackendReadyTruth
        this.didKeepContentViewAttachmentReadinessDehydrated =
            didKeepContentViewAttachmentReadinessDehydrated
        this.didAvoidVisibleReadyWrapper = didAvoidVisibleReadyWrapper
        this.didAvoidDrawableReadyWrapper = didAvoidDrawableReadyWrapper
        this.didAvoidReceiptRecordPublication = didAvoidReceiptRecordPublication
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

func cjguiInternalObserveRendererVisibleWindowContentViewAttachmentValues():
    CjguiInternalRendererVisibleWindowContentViewAttachmentObservation {
    let windowOccupiedBefore = unsafe {
        cjgui_native_bridge_nswindow_harness_table_occupied_count()
    }
    let viewOccupiedBefore = unsafe {
        cjgui_native_bridge_nsview_table_occupied_count()
    }
    var windowToken = UInt64(0)
    var viewToken = UInt64(0)
    let windowCreateStatus = unsafe {
        cjgui_native_bridge_nswindow_harness_create(inout windowToken)
    }
    let viewCreateStatus = unsafe {
        cjgui_native_bridge_nsview_create(inout viewToken)
    }
    let attachRequiresMainThread = unsafe {
        cjgui_native_bridge_nswindow_harness_content_view_attach_requires_main_thread()
    }
    let visibleOrderBlocked = unsafe {
        cjgui_native_bridge_nswindow_harness_content_view_visible_order_still_blocked()
    }
    let nextDrawableBlocked = unsafe {
        cjgui_native_bridge_nswindow_harness_next_drawable_still_blocked()
    }
    let invalidAttachStatus = unsafe {
        cjgui_native_bridge_nswindow_harness_content_view_attach(
            UInt64(0),
            viewToken
        )
    }
    let attachStatus = unsafe {
        cjgui_native_bridge_nswindow_harness_content_view_attach(
            windowToken,
            viewToken
        )
    }
    let attachedClass = unsafe {
        cjgui_native_bridge_nswindow_harness_content_view_attachment_classify(
            windowToken,
            viewToken
        )
    }
    let doubleAttachStatus = unsafe {
        cjgui_native_bridge_nswindow_harness_content_view_attach(
            windowToken,
            viewToken
        )
    }
    let doubleAttachClass = unsafe {
        cjgui_native_bridge_nswindow_harness_content_view_double_attach_classify(
            windowToken,
            viewToken
        )
    }
    let windowDestroyWhileAttached = unsafe {
        cjgui_native_bridge_nswindow_harness_destroy(windowToken)
    }
    let viewDestroyWhileAttached = unsafe {
        cjgui_native_bridge_nsview_destroy(viewToken)
    }
    let detachStatus = unsafe {
        cjgui_native_bridge_nswindow_harness_content_view_detach(
            windowToken,
            viewToken
        )
    }
    let detachedClass = unsafe {
        cjgui_native_bridge_nswindow_harness_content_view_attachment_classify(
            windowToken,
            viewToken
        )
    }
    let doubleDetachStatus = unsafe {
        cjgui_native_bridge_nswindow_harness_content_view_detach(
            windowToken,
            viewToken
        )
    }
    let doubleDetachClass = unsafe {
        cjgui_native_bridge_nswindow_harness_content_view_double_detach_classify(
            windowToken,
            viewToken
        )
    }
    let viewDestroyStatus = unsafe {
        cjgui_native_bridge_nsview_destroy(viewToken)
    }
    let windowDestroyStatus = unsafe {
        cjgui_native_bridge_nswindow_harness_destroy(windowToken)
    }
    let windowOccupiedAfterCleanup = unsafe {
        cjgui_native_bridge_nswindow_harness_table_occupied_count()
    }
    let viewOccupiedAfterCleanup = unsafe {
        cjgui_native_bridge_nsview_table_occupied_count()
    }
    let staleWindowAttachmentClass = unsafe {
        cjgui_native_bridge_nswindow_harness_content_view_attachment_classify(
            windowToken,
            viewToken
        )
    }
    let staleViewAttachmentClass = unsafe {
        cjgui_native_bridge_nswindow_harness_content_view_attachment_classify(
            UInt64(0),
            viewToken
        )
    }

    return CjguiInternalRendererVisibleWindowContentViewAttachmentObservation(
        windowOccupiedBefore,
        viewOccupiedBefore,
        windowCreateStatus,
        viewCreateStatus,
        windowToken,
        viewToken,
        attachRequiresMainThread,
        visibleOrderBlocked,
        nextDrawableBlocked,
        invalidAttachStatus,
        attachStatus,
        attachedClass,
        doubleAttachStatus,
        doubleAttachClass,
        windowDestroyWhileAttached,
        viewDestroyWhileAttached,
        detachStatus,
        detachedClass,
        doubleDetachStatus,
        doubleDetachClass,
        viewDestroyStatus,
        windowDestroyStatus,
        windowOccupiedAfterCleanup,
        viewOccupiedAfterCleanup,
        staleWindowAttachmentClass,
        staleViewAttachmentClass,
        windowCreateStatus == Int32(0) &&
            viewCreateStatus == Int32(0) &&
            windowToken != UInt64(0) &&
            viewToken != UInt64(0),
        attachStatus == Int32(0),
        attachedClass == Int32(380),
        doubleAttachStatus == Int32(-388) &&
            doubleAttachClass == Int32(-388),
        windowDestroyWhileAttached == Int32(-390) &&
            viewDestroyWhileAttached == Int32(-391),
        detachStatus == Int32(0),
        detachedClass == Int32(-380),
        doubleDetachStatus == Int32(-389) &&
            doubleDetachClass == Int32(-389),
        invalidAttachStatus == Int32(-382) &&
            staleViewAttachmentClass == Int32(-382),
        staleWindowAttachmentClass == Int32(-383),
        windowOccupiedBefore == UInt32(0) &&
            viewOccupiedBefore == UInt32(0) &&
            windowOccupiedAfterCleanup == UInt32(0) &&
            viewOccupiedAfterCleanup == UInt32(0),
        attachRequiresMainThread == Int32(-381),
        visibleOrderBlocked == Int32(-392),
        nextDrawableBlocked == Int32(-369),
        true,
        true,
        true
    )
}

func cjguiInternalBuildRendererVisibleWindowContentViewAttachmentReadiness(
    nsWindowHarnessReadiness:
        CjguiInternalRendererVisibleWindowNsWindowHarnessReadiness,
    contentViewAttachmentObservation:
        CjguiInternalRendererVisibleWindowContentViewAttachmentObservation
): CjguiInternalRendererVisibleWindowContentViewAttachmentReadiness {
    let upstreamReady =
        nsWindowHarnessReadiness
            .didPrepareRendererVisibleWindowNsWindowHarnessReadiness &&
        nsWindowHarnessReadiness
            .didConfirmNativeNsWindowHarnessUnlockedByCurrentStage &&
        nsWindowHarnessReadiness
            .didConfirmTokenBackedNsWindowCreateDestroy &&
        nsWindowHarnessReadiness
            .didConfirmProductionNextDrawableStillBlocked &&
        nsWindowHarnessReadiness
            .didConfirmCommandBufferEncoderCommitPresentGpuRenderBlocked &&
        nsWindowHarnessReadiness.didConfirmNoPublicSurface &&
        nsWindowHarnessReadiness.didConfirmNoRendererStateWrite &&
        nsWindowHarnessReadiness.didConfirmNoBackendReadyTruth
    let observationReady =
        contentViewAttachmentObservation.didObserveCreateTokens &&
        contentViewAttachmentObservation.didObserveAttach &&
        contentViewAttachmentObservation.didObserveAttachedClassification &&
        contentViewAttachmentObservation.didObserveDoubleAttachFailClosed &&
        contentViewAttachmentObservation
            .didObserveDestroyBeforeDetachFailClosed &&
        contentViewAttachmentObservation.didObserveDetach &&
        contentViewAttachmentObservation.didObserveDetachedClassification &&
        contentViewAttachmentObservation.didObserveDoubleDetachFailClosed &&
        contentViewAttachmentObservation.didObserveInvalidTokensFailClosed &&
        contentViewAttachmentObservation.didObserveStaleTokensFailClosed &&
        contentViewAttachmentObservation.didObserveCleanupCounts &&
        contentViewAttachmentObservation.didObserveMainThreadRequired &&
        contentViewAttachmentObservation.didObserveVisibleOrderStillBlocked &&
        contentViewAttachmentObservation.didObserveNextDrawableStillBlocked &&
        contentViewAttachmentObservation.didKeepTokensFunctionLocal &&
        contentViewAttachmentObservation.didConfirmNoPointerHandleClassIdReturn &&
        contentViewAttachmentObservation
            .didConfirmNoVisibleOrderDrawableRenderOrPresent
    let readinessReady = upstreamReady && observationReady

    return CjguiInternalRendererVisibleWindowContentViewAttachmentReadiness(
        nsWindowHarnessReadiness,
        contentViewAttachmentObservation,
        readinessReady,
        !readinessReady,
        !readinessReady,
        upstreamReady,
        readinessReady,
        contentViewAttachmentObservation.didKeepTokensFunctionLocal,
        contentViewAttachmentObservation.didObserveAttach &&
            contentViewAttachmentObservation.didObserveDetach &&
            contentViewAttachmentObservation.didObserveAttachedClassification &&
            contentViewAttachmentObservation.didObserveDetachedClassification,
        contentViewAttachmentObservation.didObserveDoubleAttachFailClosed &&
            contentViewAttachmentObservation.didObserveDoubleDetachFailClosed,
        contentViewAttachmentObservation
            .didObserveDestroyBeforeDetachFailClosed,
        contentViewAttachmentObservation.didObserveCleanupCounts,
        contentViewAttachmentObservation.didObserveMainThreadRequired,
        contentViewAttachmentObservation.didObserveVisibleOrderStillBlocked,
        contentViewAttachmentObservation.didObserveNextDrawableStillBlocked,
        true,
        contentViewAttachmentObservation.didConfirmNoPointerHandleClassIdReturn,
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

func cjguiInternalExecuteDefaultRendererVisibleWindowContentViewAttachmentDraft():
    CjguiInternalRendererVisibleWindowContentViewAttachmentReadiness {
    let nsWindowHarnessReadiness =
        cjguiInternalExecuteDefaultRendererVisibleWindowNsWindowHarnessDraft()
    let contentViewAttachmentObservation =
        cjguiInternalObserveRendererVisibleWindowContentViewAttachmentValues()
    return cjguiInternalBuildRendererVisibleWindowContentViewAttachmentReadiness(
        nsWindowHarnessReadiness,
        contentViewAttachmentObservation
    )
}

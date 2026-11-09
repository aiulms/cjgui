// 中文维护注释：本文件是 visible-window production harness NSApplication
// native guard no-side-effect owner。
// Owner: runtime renderer internal NSApplication native guard FFI call owner。
// Truth: 只消费 CjguiInternalRendererVisibleWindowApplicationActivationPolicyReadiness，
// 调用 no-side-effect native guard C ABI，并脱水为 application ownership、main-thread、
// creation deferred、activation deferred、activation policy deferred、event loop
// deferred、bounded run loop、auto-close、headless fail-closed、visible-order /
// drawable / render still-blocked facts。
// Stop-line: 不创建 NSApplication，不 activation，不运行 event loop，不做 native
// visible order implementation，不获取 drawable，不创建 encoder，不 draw，不提交 GPU
// work，不执行 render，不返回 Class / id / pointer / handle，不写 runtime_state.cj，
// 不扩 public API。
// Same-shape Boundary Brake: 不得把本 owner 包成 application-ready、visible-ready、
// drawable-ready、render-ready、backend-ready、renderer state write、receipt、record
// 或 publication wrapper。
package cjgui

foreign func cjgui_native_bridge_nsapplication_guard_ownership_required():
    Int32
foreign func cjgui_native_bridge_nsapplication_guard_main_thread_required():
    Int32
foreign func cjgui_native_bridge_nsapplication_guard_creation_deferred():
    Int32
foreign func cjgui_native_bridge_nsapplication_guard_activation_deferred():
    Int32
foreign func cjgui_native_bridge_nsapplication_guard_activation_policy_deferred():
    Int32
foreign func cjgui_native_bridge_nsapplication_guard_event_loop_deferred():
    Int32
foreign func cjgui_native_bridge_nsapplication_guard_bounded_run_loop_required():
    Int32
foreign func cjgui_native_bridge_nsapplication_guard_auto_close_required():
    Int32
foreign func cjgui_native_bridge_nsapplication_guard_headless_fail_closed():
    Int32
foreign func cjgui_native_bridge_nsapplication_guard_visible_order_still_blocked():
    Int32
foreign func cjgui_native_bridge_nsapplication_guard_drawable_still_blocked():
    Int32
foreign func cjgui_native_bridge_nsapplication_guard_render_still_blocked():
    Int32

struct CjguiInternalRendererVisibleWindowNsApplicationNativeGuardObservation {
    let ownershipRequiredValue: Int32
    let mainThreadRequiredValue: Int32
    let creationDeferredValue: Int32
    let activationDeferredValue: Int32
    let activationPolicyDeferredValue: Int32
    let eventLoopDeferredValue: Int32
    let boundedRunLoopRequiredValue: Int32
    let autoCloseRequiredValue: Int32
    let headlessFailClosedValue: Int32
    let visibleOrderStillBlockedValue: Int32
    let drawableStillBlockedValue: Int32
    let renderStillBlockedValue: Int32
    let didObserveOwnershipRequired: Bool
    let didObserveMainThreadRequired: Bool
    let didObserveCreationDeferred: Bool
    let didObserveActivationDeferred: Bool
    let didObserveActivationPolicyDeferred: Bool
    let didObserveEventLoopDeferred: Bool
    let didObserveBoundedRunLoopRequired: Bool
    let didObserveAutoCloseRequired: Bool
    let didObserveHeadlessFailClosed: Bool
    let didObserveVisibleOrderStillBlocked: Bool
    let didObserveDrawableStillBlocked: Bool
    let didObserveRenderStillBlocked: Bool
    let didConfirmNoApplicationSideEffect: Bool
    let didConfirmNoPointerHandleClassIdReturn: Bool

    init(
        ownershipRequiredValue: Int32,
        mainThreadRequiredValue: Int32,
        creationDeferredValue: Int32,
        activationDeferredValue: Int32,
        activationPolicyDeferredValue: Int32,
        eventLoopDeferredValue: Int32,
        boundedRunLoopRequiredValue: Int32,
        autoCloseRequiredValue: Int32,
        headlessFailClosedValue: Int32,
        visibleOrderStillBlockedValue: Int32,
        drawableStillBlockedValue: Int32,
        renderStillBlockedValue: Int32,
        didObserveOwnershipRequired: Bool,
        didObserveMainThreadRequired: Bool,
        didObserveCreationDeferred: Bool,
        didObserveActivationDeferred: Bool,
        didObserveActivationPolicyDeferred: Bool,
        didObserveEventLoopDeferred: Bool,
        didObserveBoundedRunLoopRequired: Bool,
        didObserveAutoCloseRequired: Bool,
        didObserveHeadlessFailClosed: Bool,
        didObserveVisibleOrderStillBlocked: Bool,
        didObserveDrawableStillBlocked: Bool,
        didObserveRenderStillBlocked: Bool,
        didConfirmNoApplicationSideEffect: Bool,
        didConfirmNoPointerHandleClassIdReturn: Bool
    ) {
        this.ownershipRequiredValue = ownershipRequiredValue
        this.mainThreadRequiredValue = mainThreadRequiredValue
        this.creationDeferredValue = creationDeferredValue
        this.activationDeferredValue = activationDeferredValue
        this.activationPolicyDeferredValue = activationPolicyDeferredValue
        this.eventLoopDeferredValue = eventLoopDeferredValue
        this.boundedRunLoopRequiredValue = boundedRunLoopRequiredValue
        this.autoCloseRequiredValue = autoCloseRequiredValue
        this.headlessFailClosedValue = headlessFailClosedValue
        this.visibleOrderStillBlockedValue = visibleOrderStillBlockedValue
        this.drawableStillBlockedValue = drawableStillBlockedValue
        this.renderStillBlockedValue = renderStillBlockedValue
        this.didObserveOwnershipRequired = didObserveOwnershipRequired
        this.didObserveMainThreadRequired = didObserveMainThreadRequired
        this.didObserveCreationDeferred = didObserveCreationDeferred
        this.didObserveActivationDeferred = didObserveActivationDeferred
        this.didObserveActivationPolicyDeferred =
            didObserveActivationPolicyDeferred
        this.didObserveEventLoopDeferred = didObserveEventLoopDeferred
        this.didObserveBoundedRunLoopRequired =
            didObserveBoundedRunLoopRequired
        this.didObserveAutoCloseRequired = didObserveAutoCloseRequired
        this.didObserveHeadlessFailClosed = didObserveHeadlessFailClosed
        this.didObserveVisibleOrderStillBlocked =
            didObserveVisibleOrderStillBlocked
        this.didObserveDrawableStillBlocked = didObserveDrawableStillBlocked
        this.didObserveRenderStillBlocked = didObserveRenderStillBlocked
        this.didConfirmNoApplicationSideEffect =
            didConfirmNoApplicationSideEffect
        this.didConfirmNoPointerHandleClassIdReturn =
            didConfirmNoPointerHandleClassIdReturn
    }
}

struct CjguiInternalRendererVisibleWindowNsApplicationNativeGuardReadiness {
    let applicationActivationPolicyReadiness:
        CjguiInternalRendererVisibleWindowApplicationActivationPolicyReadiness
    let nativeGuardObservation:
        CjguiInternalRendererVisibleWindowNsApplicationNativeGuardObservation
    let didPrepareRendererVisibleWindowNsApplicationNativeGuardReadiness:
        Bool
    let shouldDeferRendererVisibleWindowNsApplicationNativeGuardReadiness:
        Bool
    let shouldReportRendererVisibleWindowNsApplicationNativeGuardBlocked:
        Bool
    let didPreserveApplicationActivationPolicyReadiness: Bool
    let didConfirmRuntimeInternalNativeGuardCallExecuted: Bool
    let didConfirmApplicationOwnershipRequired: Bool
    let didConfirmMainThreadGateRequired: Bool
    let didConfirmApplicationCreationStillDeferred: Bool
    let didConfirmActivationStillDeferred: Bool
    let didConfirmActivationPolicyStillDeferred: Bool
    let didConfirmEventLoopStillDeferred: Bool
    let didConfirmBoundedRunLoopStillRequired: Bool
    let didConfirmAutoCloseStillRequired: Bool
    let didConfirmHeadlessCiFailClosedRoute: Bool
    let didConfirmNativeVisibleOrderStillBlocked: Bool
    let didConfirmProductionDrawableStillBlocked: Bool
    let didConfirmRenderStillBlocked: Bool
    let didConfirmNoApplicationCreationOrActivation: Bool
    let didConfirmNoPointerHandleClassIdReturn: Bool
    let didConfirmNoPublicSurface: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didConfirmNoBackendReadyTruth: Bool
    let didKeepNativeGuardReadinessDehydrated: Bool
    let didAvoidApplicationReadyWrapper: Bool
    let didAvoidVisibleReadyWrapper: Bool
    let didAvoidDrawableReadyWrapper: Bool
    let didAvoidReceiptRecordPublication: Bool
    let didAvoidThinWrapper: Bool

    init(
        applicationActivationPolicyReadiness:
            CjguiInternalRendererVisibleWindowApplicationActivationPolicyReadiness,
        nativeGuardObservation:
            CjguiInternalRendererVisibleWindowNsApplicationNativeGuardObservation,
        didPrepareRendererVisibleWindowNsApplicationNativeGuardReadiness:
            Bool,
        shouldDeferRendererVisibleWindowNsApplicationNativeGuardReadiness:
            Bool,
        shouldReportRendererVisibleWindowNsApplicationNativeGuardBlocked:
            Bool,
        didPreserveApplicationActivationPolicyReadiness: Bool,
        didConfirmRuntimeInternalNativeGuardCallExecuted: Bool,
        didConfirmApplicationOwnershipRequired: Bool,
        didConfirmMainThreadGateRequired: Bool,
        didConfirmApplicationCreationStillDeferred: Bool,
        didConfirmActivationStillDeferred: Bool,
        didConfirmActivationPolicyStillDeferred: Bool,
        didConfirmEventLoopStillDeferred: Bool,
        didConfirmBoundedRunLoopStillRequired: Bool,
        didConfirmAutoCloseStillRequired: Bool,
        didConfirmHeadlessCiFailClosedRoute: Bool,
        didConfirmNativeVisibleOrderStillBlocked: Bool,
        didConfirmProductionDrawableStillBlocked: Bool,
        didConfirmRenderStillBlocked: Bool,
        didConfirmNoApplicationCreationOrActivation: Bool,
        didConfirmNoPointerHandleClassIdReturn: Bool,
        didConfirmNoPublicSurface: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didConfirmNoBackendReadyTruth: Bool,
        didKeepNativeGuardReadinessDehydrated: Bool,
        didAvoidApplicationReadyWrapper: Bool,
        didAvoidVisibleReadyWrapper: Bool,
        didAvoidDrawableReadyWrapper: Bool,
        didAvoidReceiptRecordPublication: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.applicationActivationPolicyReadiness =
            applicationActivationPolicyReadiness
        this.nativeGuardObservation = nativeGuardObservation
        this.didPrepareRendererVisibleWindowNsApplicationNativeGuardReadiness =
            didPrepareRendererVisibleWindowNsApplicationNativeGuardReadiness
        this.shouldDeferRendererVisibleWindowNsApplicationNativeGuardReadiness =
            shouldDeferRendererVisibleWindowNsApplicationNativeGuardReadiness
        this.shouldReportRendererVisibleWindowNsApplicationNativeGuardBlocked =
            shouldReportRendererVisibleWindowNsApplicationNativeGuardBlocked
        this.didPreserveApplicationActivationPolicyReadiness =
            didPreserveApplicationActivationPolicyReadiness
        this.didConfirmRuntimeInternalNativeGuardCallExecuted =
            didConfirmRuntimeInternalNativeGuardCallExecuted
        this.didConfirmApplicationOwnershipRequired =
            didConfirmApplicationOwnershipRequired
        this.didConfirmMainThreadGateRequired =
            didConfirmMainThreadGateRequired
        this.didConfirmApplicationCreationStillDeferred =
            didConfirmApplicationCreationStillDeferred
        this.didConfirmActivationStillDeferred =
            didConfirmActivationStillDeferred
        this.didConfirmActivationPolicyStillDeferred =
            didConfirmActivationPolicyStillDeferred
        this.didConfirmEventLoopStillDeferred =
            didConfirmEventLoopStillDeferred
        this.didConfirmBoundedRunLoopStillRequired =
            didConfirmBoundedRunLoopStillRequired
        this.didConfirmAutoCloseStillRequired =
            didConfirmAutoCloseStillRequired
        this.didConfirmHeadlessCiFailClosedRoute =
            didConfirmHeadlessCiFailClosedRoute
        this.didConfirmNativeVisibleOrderStillBlocked =
            didConfirmNativeVisibleOrderStillBlocked
        this.didConfirmProductionDrawableStillBlocked =
            didConfirmProductionDrawableStillBlocked
        this.didConfirmRenderStillBlocked = didConfirmRenderStillBlocked
        this.didConfirmNoApplicationCreationOrActivation =
            didConfirmNoApplicationCreationOrActivation
        this.didConfirmNoPointerHandleClassIdReturn =
            didConfirmNoPointerHandleClassIdReturn
        this.didConfirmNoPublicSurface = didConfirmNoPublicSurface
        this.didConfirmNoRendererStateWrite = didConfirmNoRendererStateWrite
        this.didConfirmNoBackendReadyTruth = didConfirmNoBackendReadyTruth
        this.didKeepNativeGuardReadinessDehydrated =
            didKeepNativeGuardReadinessDehydrated
        this.didAvoidApplicationReadyWrapper = didAvoidApplicationReadyWrapper
        this.didAvoidVisibleReadyWrapper = didAvoidVisibleReadyWrapper
        this.didAvoidDrawableReadyWrapper = didAvoidDrawableReadyWrapper
        this.didAvoidReceiptRecordPublication = didAvoidReceiptRecordPublication
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

func cjguiInternalObserveRendererVisibleWindowNsApplicationNativeGuardValues():
    CjguiInternalRendererVisibleWindowNsApplicationNativeGuardObservation {
    let ownershipRequired = unsafe {
        cjgui_native_bridge_nsapplication_guard_ownership_required()
    }
    let mainThreadRequired = unsafe {
        cjgui_native_bridge_nsapplication_guard_main_thread_required()
    }
    let creationDeferred = unsafe {
        cjgui_native_bridge_nsapplication_guard_creation_deferred()
    }
    let activationDeferred = unsafe {
        cjgui_native_bridge_nsapplication_guard_activation_deferred()
    }
    let activationPolicyDeferred = unsafe {
        cjgui_native_bridge_nsapplication_guard_activation_policy_deferred()
    }
    let eventLoopDeferred = unsafe {
        cjgui_native_bridge_nsapplication_guard_event_loop_deferred()
    }
    let boundedRunLoopRequired = unsafe {
        cjgui_native_bridge_nsapplication_guard_bounded_run_loop_required()
    }
    let autoCloseRequired = unsafe {
        cjgui_native_bridge_nsapplication_guard_auto_close_required()
    }
    let headlessFailClosed = unsafe {
        cjgui_native_bridge_nsapplication_guard_headless_fail_closed()
    }
    let visibleOrderBlocked = unsafe {
        cjgui_native_bridge_nsapplication_guard_visible_order_still_blocked()
    }
    let drawableBlocked = unsafe {
        cjgui_native_bridge_nsapplication_guard_drawable_still_blocked()
    }
    let renderBlocked = unsafe {
        cjgui_native_bridge_nsapplication_guard_render_still_blocked()
    }

    return CjguiInternalRendererVisibleWindowNsApplicationNativeGuardObservation(
        ownershipRequired,
        mainThreadRequired,
        creationDeferred,
        activationDeferred,
        activationPolicyDeferred,
        eventLoopDeferred,
        boundedRunLoopRequired,
        autoCloseRequired,
        headlessFailClosed,
        visibleOrderBlocked,
        drawableBlocked,
        renderBlocked,
        ownershipRequired == 420,
        mainThreadRequired == 421,
        creationDeferred == -421,
        activationDeferred == -422,
        activationPolicyDeferred == -423,
        eventLoopDeferred == -424,
        boundedRunLoopRequired == 422,
        autoCloseRequired == 423,
        headlessFailClosed == -420,
        visibleOrderBlocked == -425,
        drawableBlocked == -426,
        renderBlocked == -427,
        true,
        true
    )
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationNativeGuardReadiness(
    applicationActivationPolicyReadiness:
        CjguiInternalRendererVisibleWindowApplicationActivationPolicyReadiness,
    nativeGuardObservation:
        CjguiInternalRendererVisibleWindowNsApplicationNativeGuardObservation
): CjguiInternalRendererVisibleWindowNsApplicationNativeGuardReadiness {
    let upstreamReady =
        applicationActivationPolicyReadiness
            .didPrepareRendererVisibleWindowApplicationActivationPolicyReadiness &&
        applicationActivationPolicyReadiness
            .didConfirmApplicationOwnershipScopeOnly &&
        applicationActivationPolicyReadiness
            .didConfirmApplicationCreationStillDeferred &&
        applicationActivationPolicyReadiness
            .didConfirmActivationStillDeferred &&
        applicationActivationPolicyReadiness
            .didConfirmMainThreadGateRequired &&
        applicationActivationPolicyReadiness
            .didConfirmBoundedRunLoopRequired &&
        applicationActivationPolicyReadiness.didConfirmAutoCloseRequired &&
        applicationActivationPolicyReadiness.didKeepHeadlessCiFailClosedRoute &&
        applicationActivationPolicyReadiness
            .didConfirmNoNativeVisibleOrderImplementation &&
        applicationActivationPolicyReadiness
            .didConfirmNoProductionDrawablePermission &&
        applicationActivationPolicyReadiness
            .didConfirmNoCommandBufferEncoderSubmissionRender &&
        applicationActivationPolicyReadiness
            .didConfirmNoPointerHandleClassIdReturn &&
        applicationActivationPolicyReadiness.didConfirmNoPublicSurface &&
        applicationActivationPolicyReadiness.didConfirmNoRendererStateWrite &&
        applicationActivationPolicyReadiness.didConfirmNoBackendReadyTruth
    let guardReady =
        nativeGuardObservation.didObserveOwnershipRequired &&
        nativeGuardObservation.didObserveMainThreadRequired &&
        nativeGuardObservation.didObserveCreationDeferred &&
        nativeGuardObservation.didObserveActivationDeferred &&
        nativeGuardObservation.didObserveActivationPolicyDeferred &&
        nativeGuardObservation.didObserveEventLoopDeferred &&
        nativeGuardObservation.didObserveBoundedRunLoopRequired &&
        nativeGuardObservation.didObserveAutoCloseRequired &&
        nativeGuardObservation.didObserveHeadlessFailClosed &&
        nativeGuardObservation.didObserveVisibleOrderStillBlocked &&
        nativeGuardObservation.didObserveDrawableStillBlocked &&
        nativeGuardObservation.didObserveRenderStillBlocked &&
        nativeGuardObservation.didConfirmNoApplicationSideEffect &&
        nativeGuardObservation.didConfirmNoPointerHandleClassIdReturn
    let readinessReady = upstreamReady && guardReady

    return CjguiInternalRendererVisibleWindowNsApplicationNativeGuardReadiness(
        applicationActivationPolicyReadiness,
        nativeGuardObservation,
        readinessReady,
        !readinessReady,
        !readinessReady,
        upstreamReady,
        guardReady,
        nativeGuardObservation.didObserveOwnershipRequired,
        nativeGuardObservation.didObserveMainThreadRequired,
        nativeGuardObservation.didObserveCreationDeferred,
        nativeGuardObservation.didObserveActivationDeferred,
        nativeGuardObservation.didObserveActivationPolicyDeferred,
        nativeGuardObservation.didObserveEventLoopDeferred,
        nativeGuardObservation.didObserveBoundedRunLoopRequired,
        nativeGuardObservation.didObserveAutoCloseRequired,
        nativeGuardObservation.didObserveHeadlessFailClosed,
        nativeGuardObservation.didObserveVisibleOrderStillBlocked,
        nativeGuardObservation.didObserveDrawableStillBlocked,
        nativeGuardObservation.didObserveRenderStillBlocked,
        nativeGuardObservation.didConfirmNoApplicationSideEffect,
        nativeGuardObservation.didConfirmNoPointerHandleClassIdReturn,
        applicationActivationPolicyReadiness.didConfirmNoPublicSurface,
        applicationActivationPolicyReadiness.didConfirmNoRendererStateWrite,
        applicationActivationPolicyReadiness.didConfirmNoBackendReadyTruth,
        true,
        true,
        true,
        true,
        true,
        true
    )
}

func cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationNativeGuardDraft():
    CjguiInternalRendererVisibleWindowNsApplicationNativeGuardReadiness {
    let applicationPolicyReadiness =
        cjguiInternalExecuteDefaultRendererVisibleWindowApplicationActivationPolicyDraft()
    let observation =
        cjguiInternalObserveRendererVisibleWindowNsApplicationNativeGuardValues()
    return cjguiInternalBuildRendererVisibleWindowNsApplicationNativeGuardReadiness(
        applicationPolicyReadiness,
        observation
    )
}

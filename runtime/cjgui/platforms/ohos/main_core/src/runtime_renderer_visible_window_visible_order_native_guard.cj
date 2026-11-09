// 中文维护注释：本文件是 visible-window production harness visible-order
// native guard no-side-effect owner。
// Owner: runtime renderer internal visible-order native guard FFI call owner。
// Truth: 只消费 CjguiInternalRendererVisibleWindowVisibleOrderPolicyReadiness，
// 调用 visible-order native guard C ABI，并脱水为 application ownership、creation
// deferred、activation deferred、bounded run loop、auto-close、headless fail-closed、
// content-view prerequisite、drawable/render still-blocked facts。
// Stop-line: 不做 native visible order implementation，不创建 NSApplication，
// 不 activation，不运行 event loop，不获取 drawable，不创建 encoder，不 draw，
// 不提交 GPU work，不执行 render，不返回 Class / id / pointer / handle，
// 不写 runtime_state.cj，不扩 public API。
// Same-shape Boundary Brake: 不得把本 owner 包成 visible-ready、drawable-ready、
// render-ready、backend-ready、renderer state write、receipt、record 或 publication wrapper。
package cjgui

foreign func
cjgui_native_bridge_nswindow_visible_order_application_ownership_required():
    Int32
foreign func
cjgui_native_bridge_nswindow_visible_order_application_creation_deferred():
    Int32
foreign func cjgui_native_bridge_nswindow_visible_order_activation_deferred():
    Int32
foreign func
cjgui_native_bridge_nswindow_visible_order_bounded_run_loop_required():
    Int32
foreign func cjgui_native_bridge_nswindow_visible_order_auto_close_required():
    Int32
foreign func cjgui_native_bridge_nswindow_visible_order_headless_fail_closed():
    Int32
foreign func cjgui_native_bridge_nswindow_visible_order_content_view_required():
    Int32
foreign func cjgui_native_bridge_nswindow_visible_order_still_blocked(): Int32
foreign func cjgui_native_bridge_nswindow_visible_order_drawable_still_blocked():
    Int32
foreign func cjgui_native_bridge_nswindow_visible_order_render_still_blocked():
    Int32

struct CjguiInternalRendererVisibleWindowVisibleOrderNativeGuardObservation {
    let applicationOwnershipRequiredValue: Int32
    let applicationCreationDeferredValue: Int32
    let activationDeferredValue: Int32
    let boundedRunLoopRequiredValue: Int32
    let autoCloseRequiredValue: Int32
    let headlessFailClosedValue: Int32
    let contentViewRequiredValue: Int32
    let visibleOrderStillBlockedValue: Int32
    let drawableStillBlockedValue: Int32
    let renderStillBlockedValue: Int32
    let didObserveApplicationOwnershipRequired: Bool
    let didObserveApplicationCreationDeferred: Bool
    let didObserveActivationDeferred: Bool
    let didObserveBoundedRunLoopRequired: Bool
    let didObserveAutoCloseRequired: Bool
    let didObserveHeadlessFailClosed: Bool
    let didObserveContentViewRequired: Bool
    let didObserveVisibleOrderStillBlocked: Bool
    let didObserveDrawableStillBlocked: Bool
    let didObserveRenderStillBlocked: Bool
    let didConfirmNoApplicationSideEffect: Bool
    let didConfirmNoPointerHandleClassIdReturn: Bool

    init(
        applicationOwnershipRequiredValue: Int32,
        applicationCreationDeferredValue: Int32,
        activationDeferredValue: Int32,
        boundedRunLoopRequiredValue: Int32,
        autoCloseRequiredValue: Int32,
        headlessFailClosedValue: Int32,
        contentViewRequiredValue: Int32,
        visibleOrderStillBlockedValue: Int32,
        drawableStillBlockedValue: Int32,
        renderStillBlockedValue: Int32,
        didObserveApplicationOwnershipRequired: Bool,
        didObserveApplicationCreationDeferred: Bool,
        didObserveActivationDeferred: Bool,
        didObserveBoundedRunLoopRequired: Bool,
        didObserveAutoCloseRequired: Bool,
        didObserveHeadlessFailClosed: Bool,
        didObserveContentViewRequired: Bool,
        didObserveVisibleOrderStillBlocked: Bool,
        didObserveDrawableStillBlocked: Bool,
        didObserveRenderStillBlocked: Bool,
        didConfirmNoApplicationSideEffect: Bool,
        didConfirmNoPointerHandleClassIdReturn: Bool
    ) {
        this.applicationOwnershipRequiredValue =
            applicationOwnershipRequiredValue
        this.applicationCreationDeferredValue =
            applicationCreationDeferredValue
        this.activationDeferredValue = activationDeferredValue
        this.boundedRunLoopRequiredValue = boundedRunLoopRequiredValue
        this.autoCloseRequiredValue = autoCloseRequiredValue
        this.headlessFailClosedValue = headlessFailClosedValue
        this.contentViewRequiredValue = contentViewRequiredValue
        this.visibleOrderStillBlockedValue = visibleOrderStillBlockedValue
        this.drawableStillBlockedValue = drawableStillBlockedValue
        this.renderStillBlockedValue = renderStillBlockedValue
        this.didObserveApplicationOwnershipRequired =
            didObserveApplicationOwnershipRequired
        this.didObserveApplicationCreationDeferred =
            didObserveApplicationCreationDeferred
        this.didObserveActivationDeferred = didObserveActivationDeferred
        this.didObserveBoundedRunLoopRequired =
            didObserveBoundedRunLoopRequired
        this.didObserveAutoCloseRequired = didObserveAutoCloseRequired
        this.didObserveHeadlessFailClosed = didObserveHeadlessFailClosed
        this.didObserveContentViewRequired = didObserveContentViewRequired
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

struct CjguiInternalRendererVisibleWindowVisibleOrderNativeGuardReadiness {
    let visibleOrderPolicyReadiness:
        CjguiInternalRendererVisibleWindowVisibleOrderPolicyReadiness
    let nativeGuardObservation:
        CjguiInternalRendererVisibleWindowVisibleOrderNativeGuardObservation
    let didPrepareRendererVisibleWindowVisibleOrderNativeGuardReadiness: Bool
    let shouldDeferRendererVisibleWindowVisibleOrderNativeGuardReadiness: Bool
    let shouldReportRendererVisibleWindowVisibleOrderNativeGuardBlocked: Bool
    let didPreserveVisibleOrderPolicyReadiness: Bool
    let didConfirmRuntimeInternalNativeGuardCallExecuted: Bool
    let didConfirmApplicationOwnershipRequired: Bool
    let didConfirmApplicationCreationStillDeferred: Bool
    let didConfirmActivationStillDeferred: Bool
    let didConfirmBoundedRunLoopStillRequired: Bool
    let didConfirmAutoCloseStillRequired: Bool
    let didConfirmHeadlessCiFailClosedRoute: Bool
    let didConfirmContentViewPrerequisiteStillRequired: Bool
    let didConfirmNativeVisibleOrderStillBlocked: Bool
    let didConfirmProductionDrawableStillBlocked: Bool
    let didConfirmRenderStillBlocked: Bool
    let didConfirmNoApplicationCreationOrActivation: Bool
    let didConfirmNoPointerHandleClassIdReturn: Bool
    let didConfirmNoPublicSurface: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didConfirmNoBackendReadyTruth: Bool
    let didKeepNativeGuardReadinessDehydrated: Bool
    let didAvoidVisibleReadyWrapper: Bool
    let didAvoidDrawableReadyWrapper: Bool
    let didAvoidReceiptRecordPublication: Bool
    let didAvoidThinWrapper: Bool

    init(
        visibleOrderPolicyReadiness:
            CjguiInternalRendererVisibleWindowVisibleOrderPolicyReadiness,
        nativeGuardObservation:
            CjguiInternalRendererVisibleWindowVisibleOrderNativeGuardObservation,
        didPrepareRendererVisibleWindowVisibleOrderNativeGuardReadiness: Bool,
        shouldDeferRendererVisibleWindowVisibleOrderNativeGuardReadiness: Bool,
        shouldReportRendererVisibleWindowVisibleOrderNativeGuardBlocked: Bool,
        didPreserveVisibleOrderPolicyReadiness: Bool,
        didConfirmRuntimeInternalNativeGuardCallExecuted: Bool,
        didConfirmApplicationOwnershipRequired: Bool,
        didConfirmApplicationCreationStillDeferred: Bool,
        didConfirmActivationStillDeferred: Bool,
        didConfirmBoundedRunLoopStillRequired: Bool,
        didConfirmAutoCloseStillRequired: Bool,
        didConfirmHeadlessCiFailClosedRoute: Bool,
        didConfirmContentViewPrerequisiteStillRequired: Bool,
        didConfirmNativeVisibleOrderStillBlocked: Bool,
        didConfirmProductionDrawableStillBlocked: Bool,
        didConfirmRenderStillBlocked: Bool,
        didConfirmNoApplicationCreationOrActivation: Bool,
        didConfirmNoPointerHandleClassIdReturn: Bool,
        didConfirmNoPublicSurface: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didConfirmNoBackendReadyTruth: Bool,
        didKeepNativeGuardReadinessDehydrated: Bool,
        didAvoidVisibleReadyWrapper: Bool,
        didAvoidDrawableReadyWrapper: Bool,
        didAvoidReceiptRecordPublication: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.visibleOrderPolicyReadiness = visibleOrderPolicyReadiness
        this.nativeGuardObservation = nativeGuardObservation
        this.didPrepareRendererVisibleWindowVisibleOrderNativeGuardReadiness =
            didPrepareRendererVisibleWindowVisibleOrderNativeGuardReadiness
        this.shouldDeferRendererVisibleWindowVisibleOrderNativeGuardReadiness =
            shouldDeferRendererVisibleWindowVisibleOrderNativeGuardReadiness
        this.shouldReportRendererVisibleWindowVisibleOrderNativeGuardBlocked =
            shouldReportRendererVisibleWindowVisibleOrderNativeGuardBlocked
        this.didPreserveVisibleOrderPolicyReadiness =
            didPreserveVisibleOrderPolicyReadiness
        this.didConfirmRuntimeInternalNativeGuardCallExecuted =
            didConfirmRuntimeInternalNativeGuardCallExecuted
        this.didConfirmApplicationOwnershipRequired =
            didConfirmApplicationOwnershipRequired
        this.didConfirmApplicationCreationStillDeferred =
            didConfirmApplicationCreationStillDeferred
        this.didConfirmActivationStillDeferred =
            didConfirmActivationStillDeferred
        this.didConfirmBoundedRunLoopStillRequired =
            didConfirmBoundedRunLoopStillRequired
        this.didConfirmAutoCloseStillRequired =
            didConfirmAutoCloseStillRequired
        this.didConfirmHeadlessCiFailClosedRoute =
            didConfirmHeadlessCiFailClosedRoute
        this.didConfirmContentViewPrerequisiteStillRequired =
            didConfirmContentViewPrerequisiteStillRequired
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
        this.didAvoidVisibleReadyWrapper = didAvoidVisibleReadyWrapper
        this.didAvoidDrawableReadyWrapper = didAvoidDrawableReadyWrapper
        this.didAvoidReceiptRecordPublication = didAvoidReceiptRecordPublication
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

func cjguiInternalObserveRendererVisibleWindowVisibleOrderNativeGuardValues():
    CjguiInternalRendererVisibleWindowVisibleOrderNativeGuardObservation {
    let ownershipRequired = unsafe {
        cjgui_native_bridge_nswindow_visible_order_application_ownership_required()
    }
    let creationDeferred = unsafe {
        cjgui_native_bridge_nswindow_visible_order_application_creation_deferred()
    }
    let activationDeferred = unsafe {
        cjgui_native_bridge_nswindow_visible_order_activation_deferred()
    }
    let boundedRunLoopRequired = unsafe {
        cjgui_native_bridge_nswindow_visible_order_bounded_run_loop_required()
    }
    let autoCloseRequired = unsafe {
        cjgui_native_bridge_nswindow_visible_order_auto_close_required()
    }
    let headlessFailClosed = unsafe {
        cjgui_native_bridge_nswindow_visible_order_headless_fail_closed()
    }
    let contentViewRequired = unsafe {
        cjgui_native_bridge_nswindow_visible_order_content_view_required()
    }
    let visibleOrderBlocked = unsafe {
        cjgui_native_bridge_nswindow_visible_order_still_blocked()
    }
    let drawableBlocked = unsafe {
        cjgui_native_bridge_nswindow_visible_order_drawable_still_blocked()
    }
    let renderBlocked = unsafe {
        cjgui_native_bridge_nswindow_visible_order_render_still_blocked()
    }

    return CjguiInternalRendererVisibleWindowVisibleOrderNativeGuardObservation(
        ownershipRequired,
        creationDeferred,
        activationDeferred,
        boundedRunLoopRequired,
        autoCloseRequired,
        headlessFailClosed,
        contentViewRequired,
        visibleOrderBlocked,
        drawableBlocked,
        renderBlocked,
        ownershipRequired == 400,
        creationDeferred == -401,
        activationDeferred == -402,
        boundedRunLoopRequired == 401,
        autoCloseRequired == 402,
        headlessFailClosed == -400,
        contentViewRequired == -403,
        visibleOrderBlocked == -404,
        drawableBlocked == -405,
        renderBlocked == -406,
        true,
        true
    )
}

func cjguiInternalBuildRendererVisibleWindowVisibleOrderNativeGuardReadiness(
    visibleOrderPolicyReadiness:
        CjguiInternalRendererVisibleWindowVisibleOrderPolicyReadiness,
    nativeGuardObservation:
        CjguiInternalRendererVisibleWindowVisibleOrderNativeGuardObservation
): CjguiInternalRendererVisibleWindowVisibleOrderNativeGuardReadiness {
    let upstreamReady =
        visibleOrderPolicyReadiness
            .didPrepareRendererVisibleWindowVisibleOrderPolicyReadiness &&
        visibleOrderPolicyReadiness
            .didConfirmApplicationOwnershipStillPolicyOnly &&
        visibleOrderPolicyReadiness
            .didConfirmApplicationCreationStillDeferred &&
        visibleOrderPolicyReadiness.didConfirmActivationStillDeferred &&
        visibleOrderPolicyReadiness.didRequireBoundedRunLoopBeforeVisibleOrder &&
        visibleOrderPolicyReadiness.didRequireAutoCloseBeforeVisibleOrderSmoke &&
        visibleOrderPolicyReadiness.didKeepHeadlessCiFailClosedRoute &&
        visibleOrderPolicyReadiness
            .didConfirmNoNativeVisibleOrderImplementation &&
        visibleOrderPolicyReadiness.didConfirmNoProductionDrawablePermission &&
        visibleOrderPolicyReadiness.didConfirmNoRendererStateWrite &&
        visibleOrderPolicyReadiness.didConfirmNoBackendReadyTruth
    let guardReady =
        nativeGuardObservation.didObserveApplicationOwnershipRequired &&
        nativeGuardObservation.didObserveApplicationCreationDeferred &&
        nativeGuardObservation.didObserveActivationDeferred &&
        nativeGuardObservation.didObserveBoundedRunLoopRequired &&
        nativeGuardObservation.didObserveAutoCloseRequired &&
        nativeGuardObservation.didObserveHeadlessFailClosed &&
        nativeGuardObservation.didObserveContentViewRequired &&
        nativeGuardObservation.didObserveVisibleOrderStillBlocked &&
        nativeGuardObservation.didObserveDrawableStillBlocked &&
        nativeGuardObservation.didObserveRenderStillBlocked &&
        nativeGuardObservation.didConfirmNoApplicationSideEffect &&
        nativeGuardObservation.didConfirmNoPointerHandleClassIdReturn
    let readinessReady = upstreamReady && guardReady

    return CjguiInternalRendererVisibleWindowVisibleOrderNativeGuardReadiness(
        visibleOrderPolicyReadiness,
        nativeGuardObservation,
        readinessReady,
        !readinessReady,
        !readinessReady,
        upstreamReady,
        guardReady,
        nativeGuardObservation.didObserveApplicationOwnershipRequired,
        nativeGuardObservation.didObserveApplicationCreationDeferred,
        nativeGuardObservation.didObserveActivationDeferred,
        nativeGuardObservation.didObserveBoundedRunLoopRequired,
        nativeGuardObservation.didObserveAutoCloseRequired,
        nativeGuardObservation.didObserveHeadlessFailClosed,
        nativeGuardObservation.didObserveContentViewRequired,
        nativeGuardObservation.didObserveVisibleOrderStillBlocked,
        nativeGuardObservation.didObserveDrawableStillBlocked,
        nativeGuardObservation.didObserveRenderStillBlocked,
        nativeGuardObservation.didConfirmNoApplicationSideEffect,
        nativeGuardObservation.didConfirmNoPointerHandleClassIdReturn,
        visibleOrderPolicyReadiness.didConfirmNoPublicSurface,
        visibleOrderPolicyReadiness.didConfirmNoRendererStateWrite,
        visibleOrderPolicyReadiness.didConfirmNoBackendReadyTruth,
        true,
        true,
        true,
        true,
        true
    )
}

func cjguiInternalExecuteDefaultRendererVisibleWindowVisibleOrderNativeGuardDraft():
    CjguiInternalRendererVisibleWindowVisibleOrderNativeGuardReadiness {
    let policyReadiness =
        cjguiInternalExecuteDefaultRendererVisibleWindowVisibleOrderPolicyDraft()
    let observation =
        cjguiInternalObserveRendererVisibleWindowVisibleOrderNativeGuardValues()
    return cjguiInternalBuildRendererVisibleWindowVisibleOrderNativeGuardReadiness(
        policyReadiness,
        observation
    )
}

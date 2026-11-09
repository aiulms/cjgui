// 中文维护注释：本文件是 visible-window production harness NSApplication
// shared-application accessor native guard no-side-effect owner。
// Owner: runtime renderer internal NSApplication shared-application accessor
// native guard FFI observation owner。
// Truth: 只消费 CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorScopeReadiness，
// 复用既有 no-side-effect shared-application guard C ABI，并脱水为 accessor
// call、accessor scope、singleton creation、main-thread、bounded run loop、
// auto-close、teardown / non-user-visible mode、activation policy / activation /
// event loop blocked、visible-order / drawable / render still-blocked facts。
// Stop-line: 不调用 application singleton accessor，不创建 NSApplication，不
// activation，不修改 activation policy，不运行 event loop，不做 native visible
// order implementation，不获取 drawable，不创建 encoder，不 draw，不提交 GPU work，
// 不执行 render，不返回 Class / id / pointer / handle，不写 runtime_state.cj，
// 不扩 public API，不新增 native bridge C ABI。
// Same-shape Boundary Brake: 不得把本 owner 包成 application-ready、visible-ready、
// drawable-ready、render-ready、backend-ready、renderer state write、receipt、record
// 或 publication wrapper。
package cjgui

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorNativeGuardObservation {
    let accessorCallBlockedValue: Int32
    let singletonCreationBlockedValue: Int32
    let mainThreadRequiredValue: Int32
    let boundedRunLoopRequiredValue: Int32
    let autoCloseRequiredValue: Int32
    let headlessFailClosedValue: Int32
    let teardownBeforeVisibleRequiredValue: Int32
    let nonUserVisibleRequiredValue: Int32
    let activationPolicyBlockedValue: Int32
    let activationBlockedValue: Int32
    let eventLoopBlockedValue: Int32
    let visibleOrderStillBlockedValue: Int32
    let drawableStillBlockedValue: Int32
    let renderStillBlockedValue: Int32
    let didObserveApplicationSingletonAccessorCallBlocked: Bool
    let didObserveApplicationSingletonCreationBlocked: Bool
    let didObserveMainThreadRequired: Bool
    let didObserveBoundedRunLoopRequired: Bool
    let didObserveAutoCloseRequired: Bool
    let didObserveHeadlessFailClosed: Bool
    let didObserveTeardownBeforeVisibleRequired: Bool
    let didObserveNonUserVisibleRequired: Bool
    let didObserveActivationPolicyBlocked: Bool
    let didObserveActivationBlocked: Bool
    let didObserveEventLoopBlocked: Bool
    let didObserveVisibleOrderStillBlocked: Bool
    let didObserveDrawableStillBlocked: Bool
    let didObserveRenderStillBlocked: Bool
    let didConfirmNoApplicationSideEffect: Bool
    let didConfirmNoPointerHandleClassIdReturn: Bool

    init(
        accessorCallBlockedValue: Int32,
        singletonCreationBlockedValue: Int32,
        mainThreadRequiredValue: Int32,
        boundedRunLoopRequiredValue: Int32,
        autoCloseRequiredValue: Int32,
        headlessFailClosedValue: Int32,
        teardownBeforeVisibleRequiredValue: Int32,
        nonUserVisibleRequiredValue: Int32,
        activationPolicyBlockedValue: Int32,
        activationBlockedValue: Int32,
        eventLoopBlockedValue: Int32,
        visibleOrderStillBlockedValue: Int32,
        drawableStillBlockedValue: Int32,
        renderStillBlockedValue: Int32,
        didObserveApplicationSingletonAccessorCallBlocked: Bool,
        didObserveApplicationSingletonCreationBlocked: Bool,
        didObserveMainThreadRequired: Bool,
        didObserveBoundedRunLoopRequired: Bool,
        didObserveAutoCloseRequired: Bool,
        didObserveHeadlessFailClosed: Bool,
        didObserveTeardownBeforeVisibleRequired: Bool,
        didObserveNonUserVisibleRequired: Bool,
        didObserveActivationPolicyBlocked: Bool,
        didObserveActivationBlocked: Bool,
        didObserveEventLoopBlocked: Bool,
        didObserveVisibleOrderStillBlocked: Bool,
        didObserveDrawableStillBlocked: Bool,
        didObserveRenderStillBlocked: Bool,
        didConfirmNoApplicationSideEffect: Bool,
        didConfirmNoPointerHandleClassIdReturn: Bool
    ) {
        this.accessorCallBlockedValue = accessorCallBlockedValue
        this.singletonCreationBlockedValue = singletonCreationBlockedValue
        this.mainThreadRequiredValue = mainThreadRequiredValue
        this.boundedRunLoopRequiredValue = boundedRunLoopRequiredValue
        this.autoCloseRequiredValue = autoCloseRequiredValue
        this.headlessFailClosedValue = headlessFailClosedValue
        this.teardownBeforeVisibleRequiredValue =
            teardownBeforeVisibleRequiredValue
        this.nonUserVisibleRequiredValue = nonUserVisibleRequiredValue
        this.activationPolicyBlockedValue = activationPolicyBlockedValue
        this.activationBlockedValue = activationBlockedValue
        this.eventLoopBlockedValue = eventLoopBlockedValue
        this.visibleOrderStillBlockedValue = visibleOrderStillBlockedValue
        this.drawableStillBlockedValue = drawableStillBlockedValue
        this.renderStillBlockedValue = renderStillBlockedValue
        this.didObserveApplicationSingletonAccessorCallBlocked =
            didObserveApplicationSingletonAccessorCallBlocked
        this.didObserveApplicationSingletonCreationBlocked =
            didObserveApplicationSingletonCreationBlocked
        this.didObserveMainThreadRequired = didObserveMainThreadRequired
        this.didObserveBoundedRunLoopRequired =
            didObserveBoundedRunLoopRequired
        this.didObserveAutoCloseRequired = didObserveAutoCloseRequired
        this.didObserveHeadlessFailClosed = didObserveHeadlessFailClosed
        this.didObserveTeardownBeforeVisibleRequired =
            didObserveTeardownBeforeVisibleRequired
        this.didObserveNonUserVisibleRequired =
            didObserveNonUserVisibleRequired
        this.didObserveActivationPolicyBlocked =
            didObserveActivationPolicyBlocked
        this.didObserveActivationBlocked = didObserveActivationBlocked
        this.didObserveEventLoopBlocked = didObserveEventLoopBlocked
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

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorNativeGuardReadiness {
    let nsApplicationSharedApplicationAccessorScopeReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorScopeReadiness
    let accessorNativeGuardObservation:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorNativeGuardObservation
    let didPrepareRendererVisibleWindowNsApplicationSharedApplicationAccessorNativeGuardReadiness:
        Bool
    let shouldDeferRendererVisibleWindowNsApplicationSharedApplicationAccessorNativeGuardReadiness:
        Bool
    let shouldReportRendererVisibleWindowNsApplicationSharedApplicationAccessorNativeGuardBlocked:
        Bool
    let didPreserveNsApplicationSharedApplicationAccessorScopeReadiness: Bool
    let didConfirmRuntimeInternalAccessorNativeGuardCallExecuted: Bool
    let didConfirmApplicationSingletonAccessorCallStillBlocked: Bool
    let didConfirmApplicationSingletonAccessorScopeStillBlocked: Bool
    let didConfirmApplicationSingletonCreationStillBlocked: Bool
    let didConfirmSharedApplicationMainThreadGateRequired: Bool
    let didConfirmBoundedRunLoopPrerequisiteRequired: Bool
    let didConfirmAutoClosePrerequisiteRequired: Bool
    let didConfirmHeadlessCiFailClosedRoute: Bool
    let didConfirmTeardownBeforeVisibleModeRequired: Bool
    let didConfirmNonUserVisibleModeRequired: Bool
    let didConfirmActivationPolicyMutationStillBlocked: Bool
    let didConfirmApplicationActivationStillBlocked: Bool
    let didConfirmEventLoopStillBlocked: Bool
    let didConfirmNativeVisibleOrderStillBlocked: Bool
    let didConfirmProductionDrawableStillBlocked: Bool
    let didConfirmRenderStillBlocked: Bool
    let didConfirmNoApplicationSingletonAccessorCall: Bool
    let didConfirmNoApplicationCreationOrActivation: Bool
    let didConfirmNoPointerHandleClassIdReturn: Bool
    let didConfirmNoPublicSurface: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didConfirmNoBackendReadyTruth: Bool
    let didKeepNsApplicationSharedApplicationAccessorNativeGuardReadinessDehydrated:
        Bool
    let didAvoidApplicationReadyWrapper: Bool
    let didAvoidVisibleReadyWrapper: Bool
    let didAvoidDrawableReadyWrapper: Bool
    let didAvoidReceiptRecordPublication: Bool
    let didAvoidThinWrapper: Bool

    init(
        nsApplicationSharedApplicationAccessorScopeReadiness:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorScopeReadiness,
        accessorNativeGuardObservation:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorNativeGuardObservation,
        didPrepareRendererVisibleWindowNsApplicationSharedApplicationAccessorNativeGuardReadiness:
            Bool,
        shouldDeferRendererVisibleWindowNsApplicationSharedApplicationAccessorNativeGuardReadiness:
            Bool,
        shouldReportRendererVisibleWindowNsApplicationSharedApplicationAccessorNativeGuardBlocked:
            Bool,
        didPreserveNsApplicationSharedApplicationAccessorScopeReadiness: Bool,
        didConfirmRuntimeInternalAccessorNativeGuardCallExecuted: Bool,
        didConfirmApplicationSingletonAccessorCallStillBlocked: Bool,
        didConfirmApplicationSingletonAccessorScopeStillBlocked: Bool,
        didConfirmApplicationSingletonCreationStillBlocked: Bool,
        didConfirmSharedApplicationMainThreadGateRequired: Bool,
        didConfirmBoundedRunLoopPrerequisiteRequired: Bool,
        didConfirmAutoClosePrerequisiteRequired: Bool,
        didConfirmHeadlessCiFailClosedRoute: Bool,
        didConfirmTeardownBeforeVisibleModeRequired: Bool,
        didConfirmNonUserVisibleModeRequired: Bool,
        didConfirmActivationPolicyMutationStillBlocked: Bool,
        didConfirmApplicationActivationStillBlocked: Bool,
        didConfirmEventLoopStillBlocked: Bool,
        didConfirmNativeVisibleOrderStillBlocked: Bool,
        didConfirmProductionDrawableStillBlocked: Bool,
        didConfirmRenderStillBlocked: Bool,
        didConfirmNoApplicationSingletonAccessorCall: Bool,
        didConfirmNoApplicationCreationOrActivation: Bool,
        didConfirmNoPointerHandleClassIdReturn: Bool,
        didConfirmNoPublicSurface: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didConfirmNoBackendReadyTruth: Bool,
        didKeepNsApplicationSharedApplicationAccessorNativeGuardReadinessDehydrated:
            Bool,
        didAvoidApplicationReadyWrapper: Bool,
        didAvoidVisibleReadyWrapper: Bool,
        didAvoidDrawableReadyWrapper: Bool,
        didAvoidReceiptRecordPublication: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.nsApplicationSharedApplicationAccessorScopeReadiness =
            nsApplicationSharedApplicationAccessorScopeReadiness
        this.accessorNativeGuardObservation = accessorNativeGuardObservation
        this.didPrepareRendererVisibleWindowNsApplicationSharedApplicationAccessorNativeGuardReadiness =
            didPrepareRendererVisibleWindowNsApplicationSharedApplicationAccessorNativeGuardReadiness
        this.shouldDeferRendererVisibleWindowNsApplicationSharedApplicationAccessorNativeGuardReadiness =
            shouldDeferRendererVisibleWindowNsApplicationSharedApplicationAccessorNativeGuardReadiness
        this.shouldReportRendererVisibleWindowNsApplicationSharedApplicationAccessorNativeGuardBlocked =
            shouldReportRendererVisibleWindowNsApplicationSharedApplicationAccessorNativeGuardBlocked
        this.didPreserveNsApplicationSharedApplicationAccessorScopeReadiness =
            didPreserveNsApplicationSharedApplicationAccessorScopeReadiness
        this.didConfirmRuntimeInternalAccessorNativeGuardCallExecuted =
            didConfirmRuntimeInternalAccessorNativeGuardCallExecuted
        this.didConfirmApplicationSingletonAccessorCallStillBlocked =
            didConfirmApplicationSingletonAccessorCallStillBlocked
        this.didConfirmApplicationSingletonAccessorScopeStillBlocked =
            didConfirmApplicationSingletonAccessorScopeStillBlocked
        this.didConfirmApplicationSingletonCreationStillBlocked =
            didConfirmApplicationSingletonCreationStillBlocked
        this.didConfirmSharedApplicationMainThreadGateRequired =
            didConfirmSharedApplicationMainThreadGateRequired
        this.didConfirmBoundedRunLoopPrerequisiteRequired =
            didConfirmBoundedRunLoopPrerequisiteRequired
        this.didConfirmAutoClosePrerequisiteRequired =
            didConfirmAutoClosePrerequisiteRequired
        this.didConfirmHeadlessCiFailClosedRoute =
            didConfirmHeadlessCiFailClosedRoute
        this.didConfirmTeardownBeforeVisibleModeRequired =
            didConfirmTeardownBeforeVisibleModeRequired
        this.didConfirmNonUserVisibleModeRequired =
            didConfirmNonUserVisibleModeRequired
        this.didConfirmActivationPolicyMutationStillBlocked =
            didConfirmActivationPolicyMutationStillBlocked
        this.didConfirmApplicationActivationStillBlocked =
            didConfirmApplicationActivationStillBlocked
        this.didConfirmEventLoopStillBlocked = didConfirmEventLoopStillBlocked
        this.didConfirmNativeVisibleOrderStillBlocked =
            didConfirmNativeVisibleOrderStillBlocked
        this.didConfirmProductionDrawableStillBlocked =
            didConfirmProductionDrawableStillBlocked
        this.didConfirmRenderStillBlocked = didConfirmRenderStillBlocked
        this.didConfirmNoApplicationSingletonAccessorCall =
            didConfirmNoApplicationSingletonAccessorCall
        this.didConfirmNoApplicationCreationOrActivation =
            didConfirmNoApplicationCreationOrActivation
        this.didConfirmNoPointerHandleClassIdReturn =
            didConfirmNoPointerHandleClassIdReturn
        this.didConfirmNoPublicSurface = didConfirmNoPublicSurface
        this.didConfirmNoRendererStateWrite = didConfirmNoRendererStateWrite
        this.didConfirmNoBackendReadyTruth = didConfirmNoBackendReadyTruth
        this.didKeepNsApplicationSharedApplicationAccessorNativeGuardReadinessDehydrated =
            didKeepNsApplicationSharedApplicationAccessorNativeGuardReadinessDehydrated
        this.didAvoidApplicationReadyWrapper = didAvoidApplicationReadyWrapper
        this.didAvoidVisibleReadyWrapper = didAvoidVisibleReadyWrapper
        this.didAvoidDrawableReadyWrapper = didAvoidDrawableReadyWrapper
        this.didAvoidReceiptRecordPublication = didAvoidReceiptRecordPublication
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

func cjguiInternalObserveRendererVisibleWindowNsApplicationSharedApplicationAccessorNativeGuardValues():
    CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorNativeGuardObservation {
    let accessorCallBlocked = unsafe {
        cjgui_native_bridge_nsapplication_shared_application_guard_accessor_blocked()
    }
    let singletonCreationBlocked = unsafe {
        cjgui_native_bridge_nsapplication_shared_application_guard_singleton_creation_blocked()
    }
    let mainThreadRequired = unsafe {
        cjgui_native_bridge_nsapplication_shared_application_guard_main_thread_required()
    }
    let boundedRunLoopRequired = unsafe {
        cjgui_native_bridge_nsapplication_shared_application_guard_bounded_run_loop_required()
    }
    let autoCloseRequired = unsafe {
        cjgui_native_bridge_nsapplication_shared_application_guard_auto_close_required()
    }
    let headlessFailClosed = unsafe {
        cjgui_native_bridge_nsapplication_shared_application_guard_headless_fail_closed()
    }
    let teardownRequired = unsafe {
        cjgui_native_bridge_nsapplication_shared_application_guard_teardown_before_visible_required()
    }
    let nonUserVisibleRequired = unsafe {
        cjgui_native_bridge_nsapplication_shared_application_guard_non_user_visible_required()
    }
    let activationPolicyBlocked = unsafe {
        cjgui_native_bridge_nsapplication_shared_application_guard_activation_policy_blocked()
    }
    let activationBlocked = unsafe {
        cjgui_native_bridge_nsapplication_shared_application_guard_activation_blocked()
    }
    let eventLoopBlocked = unsafe {
        cjgui_native_bridge_nsapplication_shared_application_guard_event_loop_blocked()
    }
    let visibleOrderBlocked = unsafe {
        cjgui_native_bridge_nsapplication_shared_application_guard_visible_order_still_blocked()
    }
    let drawableBlocked = unsafe {
        cjgui_native_bridge_nsapplication_shared_application_guard_drawable_still_blocked()
    }
    let renderBlocked = unsafe {
        cjgui_native_bridge_nsapplication_shared_application_guard_render_still_blocked()
    }

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorNativeGuardObservation(
        accessorCallBlocked,
        singletonCreationBlocked,
        mainThreadRequired,
        boundedRunLoopRequired,
        autoCloseRequired,
        headlessFailClosed,
        teardownRequired,
        nonUserVisibleRequired,
        activationPolicyBlocked,
        activationBlocked,
        eventLoopBlocked,
        visibleOrderBlocked,
        drawableBlocked,
        renderBlocked,
        accessorCallBlocked == -430,
        singletonCreationBlocked == -431,
        mainThreadRequired == 430,
        boundedRunLoopRequired == 431,
        autoCloseRequired == 432,
        headlessFailClosed == -432,
        teardownRequired == 433,
        nonUserVisibleRequired == 434,
        activationPolicyBlocked == -433,
        activationBlocked == -434,
        eventLoopBlocked == -435,
        visibleOrderBlocked == -436,
        drawableBlocked == -437,
        renderBlocked == -438,
        true,
        true
    )
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationAccessorNativeGuardReadiness(
    nsApplicationSharedApplicationAccessorScopeReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorScopeReadiness,
    accessorNativeGuardObservation:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorNativeGuardObservation
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorNativeGuardReadiness {
    let upstreamReady =
        nsApplicationSharedApplicationAccessorScopeReadiness
            .didPrepareRendererVisibleWindowNsApplicationSharedApplicationAccessorScopeReadiness &&
        nsApplicationSharedApplicationAccessorScopeReadiness
            .didConfirmApplicationSingletonAccessorScopeStillBlocked &&
        nsApplicationSharedApplicationAccessorScopeReadiness
            .didConfirmApplicationSingletonAccessorStillBlocked &&
        nsApplicationSharedApplicationAccessorScopeReadiness
            .didConfirmApplicationSingletonCreationStillBlocked &&
        nsApplicationSharedApplicationAccessorScopeReadiness
            .didConfirmSharedApplicationMainThreadGateRequired &&
        nsApplicationSharedApplicationAccessorScopeReadiness
            .didConfirmBoundedRunLoopPrerequisiteRequired &&
        nsApplicationSharedApplicationAccessorScopeReadiness
            .didConfirmAutoClosePrerequisiteRequired &&
        nsApplicationSharedApplicationAccessorScopeReadiness
            .didKeepHeadlessCiFailClosedRoute &&
        nsApplicationSharedApplicationAccessorScopeReadiness
            .didConfirmTeardownBeforeVisibleModeRequired &&
        nsApplicationSharedApplicationAccessorScopeReadiness
            .didConfirmNonUserVisibleModeRequired &&
        nsApplicationSharedApplicationAccessorScopeReadiness
            .didConfirmActivationPolicyMutationStillBlocked &&
        nsApplicationSharedApplicationAccessorScopeReadiness
            .didConfirmApplicationActivationStillBlocked &&
        nsApplicationSharedApplicationAccessorScopeReadiness
            .didConfirmEventLoopStillBlocked &&
        nsApplicationSharedApplicationAccessorScopeReadiness
            .didConfirmNativeVisibleOrderStillBlocked &&
        nsApplicationSharedApplicationAccessorScopeReadiness
            .didConfirmProductionDrawableStillBlocked &&
        nsApplicationSharedApplicationAccessorScopeReadiness
            .didConfirmRenderStillBlocked &&
        nsApplicationSharedApplicationAccessorScopeReadiness
            .didConfirmNoApplicationSingletonAccessorCall &&
        nsApplicationSharedApplicationAccessorScopeReadiness
            .didConfirmNoApplicationCreationOrActivation &&
        nsApplicationSharedApplicationAccessorScopeReadiness
            .didConfirmNoPointerHandleClassIdReturn &&
        nsApplicationSharedApplicationAccessorScopeReadiness
            .didConfirmNoPublicSurface &&
        nsApplicationSharedApplicationAccessorScopeReadiness
            .didConfirmNoRendererStateWrite &&
        nsApplicationSharedApplicationAccessorScopeReadiness
            .didConfirmNoBackendReadyTruth &&
        nsApplicationSharedApplicationAccessorScopeReadiness
            .didKeepNsApplicationSharedApplicationAccessorScopeReadinessDehydrated
    let guardReady =
        accessorNativeGuardObservation
            .didObserveApplicationSingletonAccessorCallBlocked &&
        accessorNativeGuardObservation
            .didObserveApplicationSingletonCreationBlocked &&
        accessorNativeGuardObservation.didObserveMainThreadRequired &&
        accessorNativeGuardObservation.didObserveBoundedRunLoopRequired &&
        accessorNativeGuardObservation.didObserveAutoCloseRequired &&
        accessorNativeGuardObservation.didObserveHeadlessFailClosed &&
        accessorNativeGuardObservation.didObserveTeardownBeforeVisibleRequired &&
        accessorNativeGuardObservation.didObserveNonUserVisibleRequired &&
        accessorNativeGuardObservation.didObserveActivationPolicyBlocked &&
        accessorNativeGuardObservation.didObserveActivationBlocked &&
        accessorNativeGuardObservation.didObserveEventLoopBlocked &&
        accessorNativeGuardObservation.didObserveVisibleOrderStillBlocked &&
        accessorNativeGuardObservation.didObserveDrawableStillBlocked &&
        accessorNativeGuardObservation.didObserveRenderStillBlocked &&
        accessorNativeGuardObservation.didConfirmNoApplicationSideEffect &&
        accessorNativeGuardObservation.didConfirmNoPointerHandleClassIdReturn
    let readinessReady = upstreamReady && guardReady

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorNativeGuardReadiness(
        nsApplicationSharedApplicationAccessorScopeReadiness,
        accessorNativeGuardObservation,
        readinessReady,
        !readinessReady,
        !readinessReady,
        upstreamReady,
        guardReady,
        accessorNativeGuardObservation
            .didObserveApplicationSingletonAccessorCallBlocked,
        nsApplicationSharedApplicationAccessorScopeReadiness
            .didConfirmApplicationSingletonAccessorScopeStillBlocked,
        accessorNativeGuardObservation
            .didObserveApplicationSingletonCreationBlocked,
        accessorNativeGuardObservation.didObserveMainThreadRequired,
        accessorNativeGuardObservation.didObserveBoundedRunLoopRequired,
        accessorNativeGuardObservation.didObserveAutoCloseRequired,
        accessorNativeGuardObservation.didObserveHeadlessFailClosed,
        accessorNativeGuardObservation.didObserveTeardownBeforeVisibleRequired,
        accessorNativeGuardObservation.didObserveNonUserVisibleRequired,
        accessorNativeGuardObservation.didObserveActivationPolicyBlocked,
        accessorNativeGuardObservation.didObserveActivationBlocked,
        accessorNativeGuardObservation.didObserveEventLoopBlocked,
        accessorNativeGuardObservation.didObserveVisibleOrderStillBlocked,
        accessorNativeGuardObservation.didObserveDrawableStillBlocked,
        accessorNativeGuardObservation.didObserveRenderStillBlocked,
        nsApplicationSharedApplicationAccessorScopeReadiness
            .didConfirmNoApplicationSingletonAccessorCall,
        accessorNativeGuardObservation.didConfirmNoApplicationSideEffect,
        accessorNativeGuardObservation.didConfirmNoPointerHandleClassIdReturn,
        nsApplicationSharedApplicationAccessorScopeReadiness
            .didConfirmNoPublicSurface,
        nsApplicationSharedApplicationAccessorScopeReadiness
            .didConfirmNoRendererStateWrite,
        nsApplicationSharedApplicationAccessorScopeReadiness
            .didConfirmNoBackendReadyTruth,
        true,
        true,
        true,
        true,
        true,
        true
    )
}

func cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationAccessorNativeGuardDraft():
    CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorNativeGuardReadiness {
    let accessorScopeReadiness =
        cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationAccessorScopeDraft()
    let observation =
        cjguiInternalObserveRendererVisibleWindowNsApplicationSharedApplicationAccessorNativeGuardValues()
    return cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationAccessorNativeGuardReadiness(
        accessorScopeReadiness,
        observation
    )
}

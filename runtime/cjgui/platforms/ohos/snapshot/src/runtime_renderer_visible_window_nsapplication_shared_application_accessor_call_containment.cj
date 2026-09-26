// 中文维护注释：本文件是 visible-window production harness NSApplication
// shared-application accessor call native side-effect containment owner。
// Owner: runtime renderer internal NSApplication shared-application accessor
// call containment FFI observation owner。
// Truth: 只消费 CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorCallPreflightReadiness，
// 调用 no-call containment C ABI，并脱水为 accessor call blocked、no singleton
// accessor call、singleton creation blocked、main-thread、bounded run loop、
// auto-close、teardown / non-user-visible mode、application side effect blocked、
// activation policy / activation / event loop blocked、visible-order / drawable /
// render still-blocked facts。
// Stop-line: 不调用 application singleton accessor，不创建 NSApplication，不
// activation，不修改 activation policy，不运行 event loop，不做 native visible
// order implementation，不获取 drawable，不创建 encoder，不 draw，不提交 GPU work，
// 不执行 render，不返回 Class / id / pointer / handle，不写 runtime_state.cj，
// 不扩 public API。
// Same-shape Boundary Brake: 不得把本 owner 包成 application-ready、visible-ready、
// drawable-ready、render-ready、backend-ready、renderer state write、receipt、record
// 或 publication wrapper。
package cjgui

foreign func cjgui_native_bridge_nsapplication_shared_application_accessor_call_containment_accessor_blocked():
    Int32
foreign func cjgui_native_bridge_nsapplication_shared_application_accessor_call_containment_no_singleton_accessor_call():
    Int32
foreign func cjgui_native_bridge_nsapplication_shared_application_accessor_call_containment_singleton_creation_blocked():
    Int32
foreign func cjgui_native_bridge_nsapplication_shared_application_accessor_call_containment_main_thread_required():
    Int32
foreign func cjgui_native_bridge_nsapplication_shared_application_accessor_call_containment_bounded_run_loop_required():
    Int32
foreign func cjgui_native_bridge_nsapplication_shared_application_accessor_call_containment_auto_close_required():
    Int32
foreign func cjgui_native_bridge_nsapplication_shared_application_accessor_call_containment_teardown_before_visible_required():
    Int32
foreign func cjgui_native_bridge_nsapplication_shared_application_accessor_call_containment_non_user_visible_required():
    Int32
foreign func cjgui_native_bridge_nsapplication_shared_application_accessor_call_containment_application_side_effect_blocked():
    Int32
foreign func cjgui_native_bridge_nsapplication_shared_application_accessor_call_containment_activation_policy_blocked():
    Int32
foreign func cjgui_native_bridge_nsapplication_shared_application_accessor_call_containment_activation_blocked():
    Int32
foreign func cjgui_native_bridge_nsapplication_shared_application_accessor_call_containment_event_loop_blocked():
    Int32
foreign func cjgui_native_bridge_nsapplication_shared_application_accessor_call_containment_visible_order_blocked():
    Int32
foreign func cjgui_native_bridge_nsapplication_shared_application_accessor_call_containment_drawable_blocked():
    Int32
foreign func cjgui_native_bridge_nsapplication_shared_application_accessor_call_containment_render_blocked():
    Int32
foreign func cjgui_native_bridge_nsapplication_shared_application_accessor_call_containment_backend_ready_truth_blocked():
    Int32

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentObservation {
    let accessorCallBlockedValue: Int32
    let noSingletonAccessorCallValue: Int32
    let singletonCreationBlockedValue: Int32
    let mainThreadRequiredValue: Int32
    let boundedRunLoopRequiredValue: Int32
    let autoCloseRequiredValue: Int32
    let teardownBeforeVisibleRequiredValue: Int32
    let nonUserVisibleRequiredValue: Int32
    let applicationSideEffectBlockedValue: Int32
    let activationPolicyBlockedValue: Int32
    let activationBlockedValue: Int32
    let eventLoopBlockedValue: Int32
    let visibleOrderBlockedValue: Int32
    let drawableBlockedValue: Int32
    let renderBlockedValue: Int32
    let backendReadyTruthBlockedValue: Int32
    let didObserveApplicationSingletonAccessorCallBlocked: Bool
    let didObserveNoApplicationSingletonAccessorCall: Bool
    let didObserveApplicationSingletonCreationBlocked: Bool
    let didObserveMainThreadRequired: Bool
    let didObserveBoundedRunLoopRequired: Bool
    let didObserveAutoCloseRequired: Bool
    let didObserveTeardownBeforeVisibleRequired: Bool
    let didObserveNonUserVisibleRequired: Bool
    let didObserveApplicationSideEffectBlocked: Bool
    let didObserveActivationPolicyBlocked: Bool
    let didObserveActivationBlocked: Bool
    let didObserveEventLoopBlocked: Bool
    let didObserveVisibleOrderBlocked: Bool
    let didObserveDrawableBlocked: Bool
    let didObserveRenderBlocked: Bool
    let didObserveBackendReadyTruthBlocked: Bool
    let didConfirmNoPointerHandleClassIdReturn: Bool

    init(
        accessorCallBlockedValue: Int32,
        noSingletonAccessorCallValue: Int32,
        singletonCreationBlockedValue: Int32,
        mainThreadRequiredValue: Int32,
        boundedRunLoopRequiredValue: Int32,
        autoCloseRequiredValue: Int32,
        teardownBeforeVisibleRequiredValue: Int32,
        nonUserVisibleRequiredValue: Int32,
        applicationSideEffectBlockedValue: Int32,
        activationPolicyBlockedValue: Int32,
        activationBlockedValue: Int32,
        eventLoopBlockedValue: Int32,
        visibleOrderBlockedValue: Int32,
        drawableBlockedValue: Int32,
        renderBlockedValue: Int32,
        backendReadyTruthBlockedValue: Int32,
        didObserveApplicationSingletonAccessorCallBlocked: Bool,
        didObserveNoApplicationSingletonAccessorCall: Bool,
        didObserveApplicationSingletonCreationBlocked: Bool,
        didObserveMainThreadRequired: Bool,
        didObserveBoundedRunLoopRequired: Bool,
        didObserveAutoCloseRequired: Bool,
        didObserveTeardownBeforeVisibleRequired: Bool,
        didObserveNonUserVisibleRequired: Bool,
        didObserveApplicationSideEffectBlocked: Bool,
        didObserveActivationPolicyBlocked: Bool,
        didObserveActivationBlocked: Bool,
        didObserveEventLoopBlocked: Bool,
        didObserveVisibleOrderBlocked: Bool,
        didObserveDrawableBlocked: Bool,
        didObserveRenderBlocked: Bool,
        didObserveBackendReadyTruthBlocked: Bool,
        didConfirmNoPointerHandleClassIdReturn: Bool
    ) {
        this.accessorCallBlockedValue = accessorCallBlockedValue
        this.noSingletonAccessorCallValue = noSingletonAccessorCallValue
        this.singletonCreationBlockedValue = singletonCreationBlockedValue
        this.mainThreadRequiredValue = mainThreadRequiredValue
        this.boundedRunLoopRequiredValue = boundedRunLoopRequiredValue
        this.autoCloseRequiredValue = autoCloseRequiredValue
        this.teardownBeforeVisibleRequiredValue =
            teardownBeforeVisibleRequiredValue
        this.nonUserVisibleRequiredValue = nonUserVisibleRequiredValue
        this.applicationSideEffectBlockedValue =
            applicationSideEffectBlockedValue
        this.activationPolicyBlockedValue = activationPolicyBlockedValue
        this.activationBlockedValue = activationBlockedValue
        this.eventLoopBlockedValue = eventLoopBlockedValue
        this.visibleOrderBlockedValue = visibleOrderBlockedValue
        this.drawableBlockedValue = drawableBlockedValue
        this.renderBlockedValue = renderBlockedValue
        this.backendReadyTruthBlockedValue = backendReadyTruthBlockedValue
        this.didObserveApplicationSingletonAccessorCallBlocked =
            didObserveApplicationSingletonAccessorCallBlocked
        this.didObserveNoApplicationSingletonAccessorCall =
            didObserveNoApplicationSingletonAccessorCall
        this.didObserveApplicationSingletonCreationBlocked =
            didObserveApplicationSingletonCreationBlocked
        this.didObserveMainThreadRequired = didObserveMainThreadRequired
        this.didObserveBoundedRunLoopRequired =
            didObserveBoundedRunLoopRequired
        this.didObserveAutoCloseRequired = didObserveAutoCloseRequired
        this.didObserveTeardownBeforeVisibleRequired =
            didObserveTeardownBeforeVisibleRequired
        this.didObserveNonUserVisibleRequired =
            didObserveNonUserVisibleRequired
        this.didObserveApplicationSideEffectBlocked =
            didObserveApplicationSideEffectBlocked
        this.didObserveActivationPolicyBlocked =
            didObserveActivationPolicyBlocked
        this.didObserveActivationBlocked = didObserveActivationBlocked
        this.didObserveEventLoopBlocked = didObserveEventLoopBlocked
        this.didObserveVisibleOrderBlocked = didObserveVisibleOrderBlocked
        this.didObserveDrawableBlocked = didObserveDrawableBlocked
        this.didObserveRenderBlocked = didObserveRenderBlocked
        this.didObserveBackendReadyTruthBlocked =
            didObserveBackendReadyTruthBlocked
        this.didConfirmNoPointerHandleClassIdReturn =
            didConfirmNoPointerHandleClassIdReturn
    }
}

struct CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentReadiness {
    let nsApplicationSharedApplicationAccessorCallPreflightReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorCallPreflightReadiness
    let accessorCallContainmentObservation:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentObservation
    let didPrepareRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentReadiness:
        Bool
    let shouldDeferRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentReadiness:
        Bool
    let shouldReportRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentBlocked:
        Bool
    let didPreserveNsApplicationSharedApplicationAccessorCallPreflightReadiness:
        Bool
    let didConfirmRuntimeInternalAccessorCallContainmentExecuted: Bool
    let didConfirmApplicationSingletonAccessorCallStillBlocked: Bool
    let didConfirmNoApplicationSingletonAccessorCall: Bool
    let didConfirmApplicationSingletonCreationStillBlocked: Bool
    let didConfirmSharedApplicationMainThreadGateRequired: Bool
    let didConfirmBoundedRunLoopPrerequisiteRequired: Bool
    let didConfirmAutoClosePrerequisiteRequired: Bool
    let didConfirmTeardownBeforeVisibleModeRequired: Bool
    let didConfirmNonUserVisibleModeRequired: Bool
    let didConfirmApplicationSideEffectStillBlocked: Bool
    let didConfirmActivationPolicyMutationStillBlocked: Bool
    let didConfirmApplicationActivationStillBlocked: Bool
    let didConfirmEventLoopStillBlocked: Bool
    let didConfirmNativeVisibleOrderStillBlocked: Bool
    let didConfirmProductionDrawableStillBlocked: Bool
    let didConfirmRenderStillBlocked: Bool
    let didConfirmNoApplicationCreationOrActivation: Bool
    let didConfirmNoPointerHandleClassIdReturn: Bool
    let didConfirmNoPublicSurface: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didConfirmNoBackendReadyTruth: Bool
    let didKeepNsApplicationSharedApplicationAccessorCallContainmentReadinessDehydrated:
        Bool
    let didAvoidApplicationReadyWrapper: Bool
    let didAvoidVisibleReadyWrapper: Bool
    let didAvoidDrawableReadyWrapper: Bool
    let didAvoidReceiptRecordPublication: Bool
    let didAvoidThinWrapper: Bool

    init(
        nsApplicationSharedApplicationAccessorCallPreflightReadiness:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorCallPreflightReadiness,
        accessorCallContainmentObservation:
            CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentObservation,
        didPrepareRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentReadiness:
            Bool,
        shouldDeferRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentReadiness:
            Bool,
        shouldReportRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentBlocked:
            Bool,
        didPreserveNsApplicationSharedApplicationAccessorCallPreflightReadiness:
            Bool,
        didConfirmRuntimeInternalAccessorCallContainmentExecuted: Bool,
        didConfirmApplicationSingletonAccessorCallStillBlocked: Bool,
        didConfirmNoApplicationSingletonAccessorCall: Bool,
        didConfirmApplicationSingletonCreationStillBlocked: Bool,
        didConfirmSharedApplicationMainThreadGateRequired: Bool,
        didConfirmBoundedRunLoopPrerequisiteRequired: Bool,
        didConfirmAutoClosePrerequisiteRequired: Bool,
        didConfirmTeardownBeforeVisibleModeRequired: Bool,
        didConfirmNonUserVisibleModeRequired: Bool,
        didConfirmApplicationSideEffectStillBlocked: Bool,
        didConfirmActivationPolicyMutationStillBlocked: Bool,
        didConfirmApplicationActivationStillBlocked: Bool,
        didConfirmEventLoopStillBlocked: Bool,
        didConfirmNativeVisibleOrderStillBlocked: Bool,
        didConfirmProductionDrawableStillBlocked: Bool,
        didConfirmRenderStillBlocked: Bool,
        didConfirmNoApplicationCreationOrActivation: Bool,
        didConfirmNoPointerHandleClassIdReturn: Bool,
        didConfirmNoPublicSurface: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didConfirmNoBackendReadyTruth: Bool,
        didKeepNsApplicationSharedApplicationAccessorCallContainmentReadinessDehydrated:
            Bool,
        didAvoidApplicationReadyWrapper: Bool,
        didAvoidVisibleReadyWrapper: Bool,
        didAvoidDrawableReadyWrapper: Bool,
        didAvoidReceiptRecordPublication: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.nsApplicationSharedApplicationAccessorCallPreflightReadiness =
            nsApplicationSharedApplicationAccessorCallPreflightReadiness
        this.accessorCallContainmentObservation =
            accessorCallContainmentObservation
        this.didPrepareRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentReadiness =
            didPrepareRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentReadiness
        this.shouldDeferRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentReadiness =
            shouldDeferRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentReadiness
        this.shouldReportRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentBlocked =
            shouldReportRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentBlocked
        this.didPreserveNsApplicationSharedApplicationAccessorCallPreflightReadiness =
            didPreserveNsApplicationSharedApplicationAccessorCallPreflightReadiness
        this.didConfirmRuntimeInternalAccessorCallContainmentExecuted =
            didConfirmRuntimeInternalAccessorCallContainmentExecuted
        this.didConfirmApplicationSingletonAccessorCallStillBlocked =
            didConfirmApplicationSingletonAccessorCallStillBlocked
        this.didConfirmNoApplicationSingletonAccessorCall =
            didConfirmNoApplicationSingletonAccessorCall
        this.didConfirmApplicationSingletonCreationStillBlocked =
            didConfirmApplicationSingletonCreationStillBlocked
        this.didConfirmSharedApplicationMainThreadGateRequired =
            didConfirmSharedApplicationMainThreadGateRequired
        this.didConfirmBoundedRunLoopPrerequisiteRequired =
            didConfirmBoundedRunLoopPrerequisiteRequired
        this.didConfirmAutoClosePrerequisiteRequired =
            didConfirmAutoClosePrerequisiteRequired
        this.didConfirmTeardownBeforeVisibleModeRequired =
            didConfirmTeardownBeforeVisibleModeRequired
        this.didConfirmNonUserVisibleModeRequired =
            didConfirmNonUserVisibleModeRequired
        this.didConfirmApplicationSideEffectStillBlocked =
            didConfirmApplicationSideEffectStillBlocked
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
        this.didConfirmNoApplicationCreationOrActivation =
            didConfirmNoApplicationCreationOrActivation
        this.didConfirmNoPointerHandleClassIdReturn =
            didConfirmNoPointerHandleClassIdReturn
        this.didConfirmNoPublicSurface = didConfirmNoPublicSurface
        this.didConfirmNoRendererStateWrite = didConfirmNoRendererStateWrite
        this.didConfirmNoBackendReadyTruth = didConfirmNoBackendReadyTruth
        this.didKeepNsApplicationSharedApplicationAccessorCallContainmentReadinessDehydrated =
            didKeepNsApplicationSharedApplicationAccessorCallContainmentReadinessDehydrated
        this.didAvoidApplicationReadyWrapper = didAvoidApplicationReadyWrapper
        this.didAvoidVisibleReadyWrapper = didAvoidVisibleReadyWrapper
        this.didAvoidDrawableReadyWrapper = didAvoidDrawableReadyWrapper
        this.didAvoidReceiptRecordPublication = didAvoidReceiptRecordPublication
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

func cjguiInternalObserveRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentValues():
    CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentObservation {
    let accessorCallBlocked = unsafe {
        cjgui_native_bridge_nsapplication_shared_application_accessor_call_containment_accessor_blocked()
    }
    let noSingletonAccessorCall = unsafe {
        cjgui_native_bridge_nsapplication_shared_application_accessor_call_containment_no_singleton_accessor_call()
    }
    let singletonCreationBlocked = unsafe {
        cjgui_native_bridge_nsapplication_shared_application_accessor_call_containment_singleton_creation_blocked()
    }
    let mainThreadRequired = unsafe {
        cjgui_native_bridge_nsapplication_shared_application_accessor_call_containment_main_thread_required()
    }
    let boundedRunLoopRequired = unsafe {
        cjgui_native_bridge_nsapplication_shared_application_accessor_call_containment_bounded_run_loop_required()
    }
    let autoCloseRequired = unsafe {
        cjgui_native_bridge_nsapplication_shared_application_accessor_call_containment_auto_close_required()
    }
    let teardownRequired = unsafe {
        cjgui_native_bridge_nsapplication_shared_application_accessor_call_containment_teardown_before_visible_required()
    }
    let nonUserVisibleRequired = unsafe {
        cjgui_native_bridge_nsapplication_shared_application_accessor_call_containment_non_user_visible_required()
    }
    let applicationSideEffectBlocked = unsafe {
        cjgui_native_bridge_nsapplication_shared_application_accessor_call_containment_application_side_effect_blocked()
    }
    let activationPolicyBlocked = unsafe {
        cjgui_native_bridge_nsapplication_shared_application_accessor_call_containment_activation_policy_blocked()
    }
    let activationBlocked = unsafe {
        cjgui_native_bridge_nsapplication_shared_application_accessor_call_containment_activation_blocked()
    }
    let eventLoopBlocked = unsafe {
        cjgui_native_bridge_nsapplication_shared_application_accessor_call_containment_event_loop_blocked()
    }
    let visibleOrderBlocked = unsafe {
        cjgui_native_bridge_nsapplication_shared_application_accessor_call_containment_visible_order_blocked()
    }
    let drawableBlocked = unsafe {
        cjgui_native_bridge_nsapplication_shared_application_accessor_call_containment_drawable_blocked()
    }
    let renderBlocked = unsafe {
        cjgui_native_bridge_nsapplication_shared_application_accessor_call_containment_render_blocked()
    }
    let backendReadyTruthBlocked = unsafe {
        cjgui_native_bridge_nsapplication_shared_application_accessor_call_containment_backend_ready_truth_blocked()
    }

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentObservation(
        accessorCallBlocked,
        noSingletonAccessorCall,
        singletonCreationBlocked,
        mainThreadRequired,
        boundedRunLoopRequired,
        autoCloseRequired,
        teardownRequired,
        nonUserVisibleRequired,
        applicationSideEffectBlocked,
        activationPolicyBlocked,
        activationBlocked,
        eventLoopBlocked,
        visibleOrderBlocked,
        drawableBlocked,
        renderBlocked,
        backendReadyTruthBlocked,
        accessorCallBlocked == -440,
        noSingletonAccessorCall == 440,
        singletonCreationBlocked == -441,
        mainThreadRequired == 441,
        boundedRunLoopRequired == 442,
        autoCloseRequired == 443,
        teardownRequired == 444,
        nonUserVisibleRequired == 445,
        applicationSideEffectBlocked == -442,
        activationPolicyBlocked == -443,
        activationBlocked == -444,
        eventLoopBlocked == -445,
        visibleOrderBlocked == -446,
        drawableBlocked == -447,
        renderBlocked == -448,
        backendReadyTruthBlocked == -449,
        true
    )
}

func cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentReadiness(
    nsApplicationSharedApplicationAccessorCallPreflightReadiness:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorCallPreflightReadiness,
    accessorCallContainmentObservation:
        CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentObservation
): CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentReadiness {
    let upstreamReady =
        nsApplicationSharedApplicationAccessorCallPreflightReadiness
            .didPrepareRendererVisibleWindowNsApplicationSharedApplicationAccessorCallPreflightReadiness &&
        nsApplicationSharedApplicationAccessorCallPreflightReadiness
            .didConfirmActualApplicationSingletonAccessorCallStillBlocked &&
        nsApplicationSharedApplicationAccessorCallPreflightReadiness
            .didConfirmApplicationSingletonCreationStillBlocked &&
        nsApplicationSharedApplicationAccessorCallPreflightReadiness
            .didConfirmSharedApplicationMainThreadGateRequired &&
        nsApplicationSharedApplicationAccessorCallPreflightReadiness
            .didConfirmBoundedRunLoopPrerequisiteRequired &&
        nsApplicationSharedApplicationAccessorCallPreflightReadiness
            .didConfirmAutoClosePrerequisiteRequired &&
        nsApplicationSharedApplicationAccessorCallPreflightReadiness
            .didConfirmTeardownBeforeVisibleModeRequired &&
        nsApplicationSharedApplicationAccessorCallPreflightReadiness
            .didConfirmNonUserVisibleModeRequired &&
        nsApplicationSharedApplicationAccessorCallPreflightReadiness
            .didConfirmNoApplicationSingletonAccessorCall &&
        nsApplicationSharedApplicationAccessorCallPreflightReadiness
            .didConfirmNoApplicationCreationOrActivation &&
        nsApplicationSharedApplicationAccessorCallPreflightReadiness
            .didConfirmNoPointerHandleClassIdReturn &&
        nsApplicationSharedApplicationAccessorCallPreflightReadiness
            .didConfirmNoPublicSurface &&
        nsApplicationSharedApplicationAccessorCallPreflightReadiness
            .didConfirmNoRendererStateWrite &&
        nsApplicationSharedApplicationAccessorCallPreflightReadiness
            .didConfirmNoBackendReadyTruth
    let containmentReady =
        accessorCallContainmentObservation
            .didObserveApplicationSingletonAccessorCallBlocked &&
        accessorCallContainmentObservation
            .didObserveNoApplicationSingletonAccessorCall &&
        accessorCallContainmentObservation
            .didObserveApplicationSingletonCreationBlocked &&
        accessorCallContainmentObservation.didObserveMainThreadRequired &&
        accessorCallContainmentObservation.didObserveBoundedRunLoopRequired &&
        accessorCallContainmentObservation.didObserveAutoCloseRequired &&
        accessorCallContainmentObservation
            .didObserveTeardownBeforeVisibleRequired &&
        accessorCallContainmentObservation.didObserveNonUserVisibleRequired &&
        accessorCallContainmentObservation
            .didObserveApplicationSideEffectBlocked &&
        accessorCallContainmentObservation.didObserveActivationPolicyBlocked &&
        accessorCallContainmentObservation.didObserveActivationBlocked &&
        accessorCallContainmentObservation.didObserveEventLoopBlocked &&
        accessorCallContainmentObservation.didObserveVisibleOrderBlocked &&
        accessorCallContainmentObservation.didObserveDrawableBlocked &&
        accessorCallContainmentObservation.didObserveRenderBlocked &&
        accessorCallContainmentObservation.didObserveBackendReadyTruthBlocked &&
        accessorCallContainmentObservation.didConfirmNoPointerHandleClassIdReturn
    let ready = upstreamReady && containmentReady

    return CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentReadiness(
        nsApplicationSharedApplicationAccessorCallPreflightReadiness,
        accessorCallContainmentObservation,
        ready,
        !ready,
        !ready,
        upstreamReady,
        containmentReady,
        accessorCallContainmentObservation
            .didObserveApplicationSingletonAccessorCallBlocked,
        accessorCallContainmentObservation
            .didObserveNoApplicationSingletonAccessorCall,
        accessorCallContainmentObservation
            .didObserveApplicationSingletonCreationBlocked,
        accessorCallContainmentObservation.didObserveMainThreadRequired,
        accessorCallContainmentObservation.didObserveBoundedRunLoopRequired,
        accessorCallContainmentObservation.didObserveAutoCloseRequired,
        accessorCallContainmentObservation
            .didObserveTeardownBeforeVisibleRequired,
        accessorCallContainmentObservation.didObserveNonUserVisibleRequired,
        accessorCallContainmentObservation
            .didObserveApplicationSideEffectBlocked,
        accessorCallContainmentObservation.didObserveActivationPolicyBlocked,
        accessorCallContainmentObservation.didObserveActivationBlocked,
        accessorCallContainmentObservation.didObserveEventLoopBlocked,
        accessorCallContainmentObservation.didObserveVisibleOrderBlocked,
        accessorCallContainmentObservation.didObserveDrawableBlocked,
        accessorCallContainmentObservation.didObserveRenderBlocked,
        true,
        accessorCallContainmentObservation.didConfirmNoPointerHandleClassIdReturn,
        nsApplicationSharedApplicationAccessorCallPreflightReadiness
            .didConfirmNoPublicSurface,
        nsApplicationSharedApplicationAccessorCallPreflightReadiness
            .didConfirmNoRendererStateWrite,
        accessorCallContainmentObservation.didObserveBackendReadyTruthBlocked,
        true,
        true,
        true,
        true,
        true,
        true
    )
}

func cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentDraft():
    CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentReadiness {
    let preflightReadiness =
        cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationAccessorCallPreflightDraft()
    let observation =
        cjguiInternalObserveRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentValues()
    return cjguiInternalBuildRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentReadiness(
        preflightReadiness,
        observation
    )
}

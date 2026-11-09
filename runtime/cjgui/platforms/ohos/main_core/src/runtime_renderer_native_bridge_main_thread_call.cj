// Owner: native bridge main-thread no-resource callable owner。
// Truth: 只消费 CjguiInternalRendererNoNativeBridgeNoResourceRuntimeCallReadiness，
// 调用 cjgui_native_bridge_is_main_thread，并把当前线程分类脱水成 internal facts。
// Stop-line: 不扩 public API，不调用 resource callable，不创建 native object /
// handle / pointer，不改 runtime_state.cj，不把 main-thread query 解释成
// native bridge ready 或 backend-ready truth。
// Same-shape Boundary Brake: 不得把本 owner 包成 public API、resource
// callable、native object、AppKit/Metal、backend-ready、receipt、record 或
// publication wrapper。
package cjgui

foreign func cjgui_native_bridge_is_main_thread(): Int32

struct CjguiInternalRendererNativeBridgeMainThreadCallIntent {
    let noResourceRuntimeCallReadiness:
        CjguiInternalRendererNoNativeBridgeNoResourceRuntimeCallReadiness
    let didPrepareRendererNativeBridgeMainThreadCallIntent: Bool
    let shouldDeferRendererNativeBridgeMainThreadCallIntent: Bool
    let shouldReportRendererNativeBridgeMainThreadCallIntentBlocked: Bool
    let didPreserveRendererNativeBridgeNoResourceRuntimeCallReadiness: Bool
    let didConfirmMainThreadCallableIsNoResource: Bool
    let didConfirmPthreadRouteWithoutFoundation: Bool
    let didKeepMainThreadCallIntentInternalOnly: Bool
    let didAvoidNativeBridgeReadyWrapper: Bool
    let didAvoidThinWrapper: Bool

    init(
        noResourceRuntimeCallReadiness:
            CjguiInternalRendererNoNativeBridgeNoResourceRuntimeCallReadiness,
        didPrepareRendererNativeBridgeMainThreadCallIntent: Bool,
        shouldDeferRendererNativeBridgeMainThreadCallIntent: Bool,
        shouldReportRendererNativeBridgeMainThreadCallIntentBlocked: Bool,
        didPreserveRendererNativeBridgeNoResourceRuntimeCallReadiness: Bool,
        didConfirmMainThreadCallableIsNoResource: Bool,
        didConfirmPthreadRouteWithoutFoundation: Bool,
        didKeepMainThreadCallIntentInternalOnly: Bool,
        didAvoidNativeBridgeReadyWrapper: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.noResourceRuntimeCallReadiness = noResourceRuntimeCallReadiness
        this.didPrepareRendererNativeBridgeMainThreadCallIntent =
            didPrepareRendererNativeBridgeMainThreadCallIntent
        this.shouldDeferRendererNativeBridgeMainThreadCallIntent =
            shouldDeferRendererNativeBridgeMainThreadCallIntent
        this.shouldReportRendererNativeBridgeMainThreadCallIntentBlocked =
            shouldReportRendererNativeBridgeMainThreadCallIntentBlocked
        this
            .didPreserveRendererNativeBridgeNoResourceRuntimeCallReadiness =
            didPreserveRendererNativeBridgeNoResourceRuntimeCallReadiness
        this.didConfirmMainThreadCallableIsNoResource =
            didConfirmMainThreadCallableIsNoResource
        this.didConfirmPthreadRouteWithoutFoundation =
            didConfirmPthreadRouteWithoutFoundation
        this.didKeepMainThreadCallIntentInternalOnly =
            didKeepMainThreadCallIntentInternalOnly
        this.didAvoidNativeBridgeReadyWrapper =
            didAvoidNativeBridgeReadyWrapper
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

struct CjguiInternalRendererNativeBridgeMainThreadCallObservation {
    let mainThreadValue: Int32
    let didObserveMainThreadClassification: Bool
    let didObserveCurrentThreadIsMainThread: Bool
    let didObserveCurrentThreadIsNotMainThread: Bool
    let didFailClosedOnUnknownMainThreadResult: Bool
    let didKeepObservationSideEffectFree: Bool
    let didDenyNativePointerReturn: Bool
    let didAvoidResourceCallable: Bool

    init(
        mainThreadValue: Int32,
        didObserveMainThreadClassification: Bool,
        didObserveCurrentThreadIsMainThread: Bool,
        didObserveCurrentThreadIsNotMainThread: Bool,
        didFailClosedOnUnknownMainThreadResult: Bool,
        didKeepObservationSideEffectFree: Bool,
        didDenyNativePointerReturn: Bool,
        didAvoidResourceCallable: Bool
    ) {
        this.mainThreadValue = mainThreadValue
        this.didObserveMainThreadClassification =
            didObserveMainThreadClassification
        this.didObserveCurrentThreadIsMainThread =
            didObserveCurrentThreadIsMainThread
        this.didObserveCurrentThreadIsNotMainThread =
            didObserveCurrentThreadIsNotMainThread
        this.didFailClosedOnUnknownMainThreadResult =
            didFailClosedOnUnknownMainThreadResult
        this.didKeepObservationSideEffectFree =
            didKeepObservationSideEffectFree
        this.didDenyNativePointerReturn = didDenyNativePointerReturn
        this.didAvoidResourceCallable = didAvoidResourceCallable
    }
}

struct CjguiInternalRendererNoNativeBridgeMainThreadCallReadiness {
    let mainThreadCallIntent:
        CjguiInternalRendererNativeBridgeMainThreadCallIntent
    let mainThreadCallObservation:
        CjguiInternalRendererNativeBridgeMainThreadCallObservation
    let didPrepareRendererNoNativeBridgeMainThreadCallReadiness: Bool
    let shouldDeferRendererNoNativeBridgeMainThreadCallReadiness: Bool
    let shouldReportRendererNoNativeBridgeMainThreadCallReadinessBlocked:
        Bool
    let didPreserveRendererNativeBridgeMainThreadCallIntent: Bool
    let didPreserveRendererNativeBridgeMainThreadCallObservation: Bool
    let didConfirmMainThreadQueryObserved: Bool
    let didConfirmCurrentThreadIsMainThread: Bool
    let didConfirmNoPublicSurface: Bool
    let didConfirmNoResourceCallable: Bool
    let didConfirmNoNativeObjectHandleOrPointer: Bool
    let didConfirmNoFoundationCocoaMetalOrQuartzCoreImport: Bool
    let didConfirmNoRendererStateWrite: Bool
    let didConfirmNoBackendReadyTruth: Bool
    let didFailClosedOnUnknownMainThreadResult: Bool
    let didKeepNoNativeBridgeMainThreadCallReadinessDehydrated: Bool
    let didAvoidReceiptRecordPublication: Bool
    let didAvoidThinWrapper: Bool

    init(
        mainThreadCallIntent:
            CjguiInternalRendererNativeBridgeMainThreadCallIntent,
        mainThreadCallObservation:
            CjguiInternalRendererNativeBridgeMainThreadCallObservation,
        didPrepareRendererNoNativeBridgeMainThreadCallReadiness: Bool,
        shouldDeferRendererNoNativeBridgeMainThreadCallReadiness: Bool,
        shouldReportRendererNoNativeBridgeMainThreadCallReadinessBlocked:
            Bool,
        didPreserveRendererNativeBridgeMainThreadCallIntent: Bool,
        didPreserveRendererNativeBridgeMainThreadCallObservation: Bool,
        didConfirmMainThreadQueryObserved: Bool,
        didConfirmCurrentThreadIsMainThread: Bool,
        didConfirmNoPublicSurface: Bool,
        didConfirmNoResourceCallable: Bool,
        didConfirmNoNativeObjectHandleOrPointer: Bool,
        didConfirmNoFoundationCocoaMetalOrQuartzCoreImport: Bool,
        didConfirmNoRendererStateWrite: Bool,
        didConfirmNoBackendReadyTruth: Bool,
        didFailClosedOnUnknownMainThreadResult: Bool,
        didKeepNoNativeBridgeMainThreadCallReadinessDehydrated: Bool,
        didAvoidReceiptRecordPublication: Bool,
        didAvoidThinWrapper: Bool
    ) {
        this.mainThreadCallIntent = mainThreadCallIntent
        this.mainThreadCallObservation = mainThreadCallObservation
        this.didPrepareRendererNoNativeBridgeMainThreadCallReadiness =
            didPrepareRendererNoNativeBridgeMainThreadCallReadiness
        this.shouldDeferRendererNoNativeBridgeMainThreadCallReadiness =
            shouldDeferRendererNoNativeBridgeMainThreadCallReadiness
        this
            .shouldReportRendererNoNativeBridgeMainThreadCallReadinessBlocked =
            shouldReportRendererNoNativeBridgeMainThreadCallReadinessBlocked
        this.didPreserveRendererNativeBridgeMainThreadCallIntent =
            didPreserveRendererNativeBridgeMainThreadCallIntent
        this.didPreserveRendererNativeBridgeMainThreadCallObservation =
            didPreserveRendererNativeBridgeMainThreadCallObservation
        this.didConfirmMainThreadQueryObserved =
            didConfirmMainThreadQueryObserved
        this.didConfirmCurrentThreadIsMainThread =
            didConfirmCurrentThreadIsMainThread
        this.didConfirmNoPublicSurface = didConfirmNoPublicSurface
        this.didConfirmNoResourceCallable = didConfirmNoResourceCallable
        this.didConfirmNoNativeObjectHandleOrPointer =
            didConfirmNoNativeObjectHandleOrPointer
        this.didConfirmNoFoundationCocoaMetalOrQuartzCoreImport =
            didConfirmNoFoundationCocoaMetalOrQuartzCoreImport
        this.didConfirmNoRendererStateWrite =
            didConfirmNoRendererStateWrite
        this.didConfirmNoBackendReadyTruth = didConfirmNoBackendReadyTruth
        this.didFailClosedOnUnknownMainThreadResult =
            didFailClosedOnUnknownMainThreadResult
        this.didKeepNoNativeBridgeMainThreadCallReadinessDehydrated =
            didKeepNoNativeBridgeMainThreadCallReadinessDehydrated
        this.didAvoidReceiptRecordPublication =
            didAvoidReceiptRecordPublication
        this.didAvoidThinWrapper = didAvoidThinWrapper
    }
}

func cjguiInternalObserveRendererNativeBridgeMainThreadCallValue():
    CjguiInternalRendererNativeBridgeMainThreadCallObservation {
    let mainThreadValue = unsafe {
        cjgui_native_bridge_is_main_thread()
    }
    let observedCurrentThreadIsMain = mainThreadValue == Int32(1)
    let observedCurrentThreadIsNotMain = mainThreadValue == Int32(0)
    let observedClassification =
        observedCurrentThreadIsMain || observedCurrentThreadIsNotMain
    return CjguiInternalRendererNativeBridgeMainThreadCallObservation(
        mainThreadValue,
        observedClassification,
        observedCurrentThreadIsMain,
        observedCurrentThreadIsNotMain,
        !observedClassification,
        true,
        true,
        true
    )
}

func cjguiInternalBuildRendererNativeBridgeMainThreadCallReadiness(
    noResourceRuntimeCallReadiness:
        CjguiInternalRendererNoNativeBridgeNoResourceRuntimeCallReadiness,
    mainThreadCallObservation:
        CjguiInternalRendererNativeBridgeMainThreadCallObservation
): CjguiInternalRendererNoNativeBridgeMainThreadCallReadiness {
    let noResourceRuntimeReady =
        noResourceRuntimeCallReadiness
            .didPrepareRendererNoNativeBridgeNoResourceRuntimeCallReadiness &&
        noResourceRuntimeCallReadiness.didConfirmNoPublicSurface &&
        noResourceRuntimeCallReadiness.didConfirmNoResourceCallable &&
        noResourceRuntimeCallReadiness
            .didConfirmNoNativeObjectHandleOrPointer &&
        noResourceRuntimeCallReadiness.didConfirmNoMetalOrAppKitUsage &&
        noResourceRuntimeCallReadiness.didConfirmNoRendererStateWrite &&
        noResourceRuntimeCallReadiness.didConfirmNoBackendReadyTruth
    let observationReady =
        mainThreadCallObservation.didObserveMainThreadClassification &&
        mainThreadCallObservation.didKeepObservationSideEffectFree &&
        mainThreadCallObservation.didDenyNativePointerReturn &&
        mainThreadCallObservation.didAvoidResourceCallable
    let readinessReady = noResourceRuntimeReady && observationReady
    let intent = CjguiInternalRendererNativeBridgeMainThreadCallIntent(
        noResourceRuntimeCallReadiness,
        readinessReady,
        !readinessReady,
        !readinessReady,
        noResourceRuntimeReady,
        true,
        true,
        true,
        true,
        true
    )
    return CjguiInternalRendererNoNativeBridgeMainThreadCallReadiness(
        intent,
        mainThreadCallObservation,
        readinessReady,
        !readinessReady,
        !readinessReady,
        readinessReady,
        observationReady,
        mainThreadCallObservation.didObserveMainThreadClassification,
        mainThreadCallObservation.didObserveCurrentThreadIsMainThread,
        true,
        true,
        true,
        true,
        true,
        true,
        mainThreadCallObservation.didFailClosedOnUnknownMainThreadResult,
        true,
        true,
        true
    )
}

func cjguiInternalExecuteDefaultRendererNativeBridgeMainThreadCallDraft():
    CjguiInternalRendererNoNativeBridgeMainThreadCallReadiness {
    let noResourceRuntimeCallReadiness =
        cjguiInternalExecuteDefaultRendererNativeBridgeNoResourceRuntimeCallDraft()
    let mainThreadCallObservation =
        cjguiInternalObserveRendererNativeBridgeMainThreadCallValue()
    return cjguiInternalBuildRendererNativeBridgeMainThreadCallReadiness(
        noResourceRuntimeCallReadiness,
        mainThreadCallObservation
    )
}

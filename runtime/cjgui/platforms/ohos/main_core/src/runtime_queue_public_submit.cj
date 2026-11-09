package cjgui

// Internal Queue Experimental Submit Shell owner:
// - 本文件只消费 QueuePublicNoStableCompatibility。
// - Truth 是 experimental submit shell / request / admission / result value facts。
// - 开放可见性 allowlist 当前只允许 cjguiExperimentalQueueSubmitShellReady(): Bool；
//   任何第二个开放符号、结构化返回值或 internal owner type 签名都必须先经过新的 visibility decision。
// - Stop-line: submit shell 仍是实验性入口外壳，不承诺稳定兼容，不做真实队列写入；
//   不接收原始指针、原生句柄或平台对象，不写 process-wide queue storage，不创建 global mutable queue /
//   singleton，不做 item collection mutation，不 drain，不接 scheduler / event loop / platform callback / runtime
//   cycle，也不回塞 critical runtime_state.cj。

// Submit shell 只接收 no-stable-compatibility facts；它是实验性外壳 facts，
// 不是稳定公开 API contract，也不会绕过 Action Router / Queue gates。
struct CjguiInternalQueueExperimentalSubmitShell {
    let compatibility: CjguiInternalQueuePublicNoStableCompatibility
    let didPrepareQueueExperimentalSubmitShell: Bool
    let didKeepQueueExperimentalSubmitShellExperimental: Bool
    let didUseQueueSubmissionTerminology: Bool
    let didAvoidStableQueuePublicApiCompatibilityPromise: Bool
    let shouldDeferQueueExperimentalSubmitShell: Bool
    let shouldReportQueueExperimentalSubmitShellBlocked: Bool
    let shouldRejectQueueExperimentalSubmitShell: Bool
    let shouldReportQueueExperimentalSubmitShellIncompatible: Bool
    let shouldReportQueueExperimentalSubmitShellUnauthorized: Bool
    let didPreserveQueuePublicNoStableCompatibility: Bool
    let didPreserveQueuePublicExposureGate: Bool
    let didPreserveQueuePublicPermissionAndRollbackLinkage: Bool
    let didPreservePreviousQueueStoreSnapshot: Bool

    init(
        compatibility: CjguiInternalQueuePublicNoStableCompatibility,
        didPrepareQueueExperimentalSubmitShell: Bool,
        didKeepQueueExperimentalSubmitShellExperimental: Bool,
        didUseQueueSubmissionTerminology: Bool,
        didAvoidStableQueuePublicApiCompatibilityPromise: Bool,
        shouldDeferQueueExperimentalSubmitShell: Bool,
        shouldReportQueueExperimentalSubmitShellBlocked: Bool,
        shouldRejectQueueExperimentalSubmitShell: Bool,
        shouldReportQueueExperimentalSubmitShellIncompatible: Bool,
        shouldReportQueueExperimentalSubmitShellUnauthorized: Bool,
        didPreserveQueuePublicNoStableCompatibility: Bool,
        didPreserveQueuePublicExposureGate: Bool,
        didPreserveQueuePublicPermissionAndRollbackLinkage: Bool,
        didPreservePreviousQueueStoreSnapshot: Bool
    ) {
        this.compatibility = compatibility
        this.didPrepareQueueExperimentalSubmitShell = didPrepareQueueExperimentalSubmitShell
        this.didKeepQueueExperimentalSubmitShellExperimental = didKeepQueueExperimentalSubmitShellExperimental
        this.didUseQueueSubmissionTerminology = didUseQueueSubmissionTerminology
        this.didAvoidStableQueuePublicApiCompatibilityPromise =
            didAvoidStableQueuePublicApiCompatibilityPromise
        this.shouldDeferQueueExperimentalSubmitShell = shouldDeferQueueExperimentalSubmitShell
        this.shouldReportQueueExperimentalSubmitShellBlocked = shouldReportQueueExperimentalSubmitShellBlocked
        this.shouldRejectQueueExperimentalSubmitShell = shouldRejectQueueExperimentalSubmitShell
        this.shouldReportQueueExperimentalSubmitShellIncompatible =
            shouldReportQueueExperimentalSubmitShellIncompatible
        this.shouldReportQueueExperimentalSubmitShellUnauthorized =
            shouldReportQueueExperimentalSubmitShellUnauthorized
        this.didPreserveQueuePublicNoStableCompatibility = didPreserveQueuePublicNoStableCompatibility
        this.didPreserveQueuePublicExposureGate = didPreserveQueuePublicExposureGate
        this.didPreserveQueuePublicPermissionAndRollbackLinkage =
            didPreserveQueuePublicPermissionAndRollbackLinkage
        this.didPreservePreviousQueueStoreSnapshot = didPreservePreviousQueueStoreSnapshot
    }
}

// Submit request 只描述脱水 submission value facts；它不接受外部对象、句柄或平台对象。
struct CjguiInternalQueueExperimentalSubmitRequest {
    let shell: CjguiInternalQueueExperimentalSubmitShell
    let didPrepareQueueExperimentalSubmitRequest: Bool
    let didUseDehydratedQueueSubmissionValue: Bool
    let didAvoidExternalQueueObjectIntake: Bool
    let didAvoidStableQueuePublicApiCompatibilityPromise: Bool
    let shouldDeferQueueExperimentalSubmitRequest: Bool
    let shouldReportQueueExperimentalSubmitRequestBlocked: Bool
    let shouldRejectQueueExperimentalSubmitRequest: Bool
    let shouldReportQueueExperimentalSubmitRequestIncompatible: Bool
    let shouldReportQueueExperimentalSubmitRequestUnauthorized: Bool
    let didPreserveQueueExperimentalSubmitShell: Bool
    let didPreserveQueuePublicPermissionAndRollbackLinkage: Bool
    let didPreservePreviousQueueStoreSnapshot: Bool

    init(
        shell: CjguiInternalQueueExperimentalSubmitShell,
        didPrepareQueueExperimentalSubmitRequest: Bool,
        didUseDehydratedQueueSubmissionValue: Bool,
        didAvoidExternalQueueObjectIntake: Bool,
        didAvoidStableQueuePublicApiCompatibilityPromise: Bool,
        shouldDeferQueueExperimentalSubmitRequest: Bool,
        shouldReportQueueExperimentalSubmitRequestBlocked: Bool,
        shouldRejectQueueExperimentalSubmitRequest: Bool,
        shouldReportQueueExperimentalSubmitRequestIncompatible: Bool,
        shouldReportQueueExperimentalSubmitRequestUnauthorized: Bool,
        didPreserveQueueExperimentalSubmitShell: Bool,
        didPreserveQueuePublicPermissionAndRollbackLinkage: Bool,
        didPreservePreviousQueueStoreSnapshot: Bool
    ) {
        this.shell = shell
        this.didPrepareQueueExperimentalSubmitRequest = didPrepareQueueExperimentalSubmitRequest
        this.didUseDehydratedQueueSubmissionValue = didUseDehydratedQueueSubmissionValue
        this.didAvoidExternalQueueObjectIntake = didAvoidExternalQueueObjectIntake
        this.didAvoidStableQueuePublicApiCompatibilityPromise =
            didAvoidStableQueuePublicApiCompatibilityPromise
        this.shouldDeferQueueExperimentalSubmitRequest = shouldDeferQueueExperimentalSubmitRequest
        this.shouldReportQueueExperimentalSubmitRequestBlocked = shouldReportQueueExperimentalSubmitRequestBlocked
        this.shouldRejectQueueExperimentalSubmitRequest = shouldRejectQueueExperimentalSubmitRequest
        this.shouldReportQueueExperimentalSubmitRequestIncompatible =
            shouldReportQueueExperimentalSubmitRequestIncompatible
        this.shouldReportQueueExperimentalSubmitRequestUnauthorized =
            shouldReportQueueExperimentalSubmitRequestUnauthorized
        this.didPreserveQueueExperimentalSubmitShell = didPreserveQueueExperimentalSubmitShell
        this.didPreserveQueuePublicPermissionAndRollbackLinkage =
            didPreserveQueuePublicPermissionAndRollbackLinkage
        this.didPreservePreviousQueueStoreSnapshot = didPreservePreviousQueueStoreSnapshot
    }
}

// Submit admission 只说明 request 是否可形成实验性 submit result；
// 它不是实际队列写入 admission，也不是稳定授权副作用。
struct CjguiInternalQueueExperimentalSubmitAdmission {
    let request: CjguiInternalQueueExperimentalSubmitRequest
    let didPrepareQueueExperimentalSubmitAdmission: Bool
    let didAllowQueueExperimentalSubmitShell: Bool
    let didKeepQueueExperimentalSubmitExperimental: Bool
    let didAvoidStableQueuePublicApiCompatibilityPromise: Bool
    let shouldDeferQueueExperimentalSubmitAdmission: Bool
    let shouldReportQueueExperimentalSubmitAdmissionBlocked: Bool
    let shouldRejectQueueExperimentalSubmitAdmission: Bool
    let shouldReportQueueExperimentalSubmitAdmissionIncompatible: Bool
    let shouldReportQueueExperimentalSubmitAdmissionUnauthorized: Bool
    let didPreserveQueueExperimentalSubmitRequest: Bool
    let didPreserveQueuePublicPermissionAndRollbackLinkage: Bool
    let didPreservePreviousQueueStoreSnapshot: Bool

    init(
        request: CjguiInternalQueueExperimentalSubmitRequest,
        didPrepareQueueExperimentalSubmitAdmission: Bool,
        didAllowQueueExperimentalSubmitShell: Bool,
        didKeepQueueExperimentalSubmitExperimental: Bool,
        didAvoidStableQueuePublicApiCompatibilityPromise: Bool,
        shouldDeferQueueExperimentalSubmitAdmission: Bool,
        shouldReportQueueExperimentalSubmitAdmissionBlocked: Bool,
        shouldRejectQueueExperimentalSubmitAdmission: Bool,
        shouldReportQueueExperimentalSubmitAdmissionIncompatible: Bool,
        shouldReportQueueExperimentalSubmitAdmissionUnauthorized: Bool,
        didPreserveQueueExperimentalSubmitRequest: Bool,
        didPreserveQueuePublicPermissionAndRollbackLinkage: Bool,
        didPreservePreviousQueueStoreSnapshot: Bool
    ) {
        this.request = request
        this.didPrepareQueueExperimentalSubmitAdmission = didPrepareQueueExperimentalSubmitAdmission
        this.didAllowQueueExperimentalSubmitShell = didAllowQueueExperimentalSubmitShell
        this.didKeepQueueExperimentalSubmitExperimental = didKeepQueueExperimentalSubmitExperimental
        this.didAvoidStableQueuePublicApiCompatibilityPromise =
            didAvoidStableQueuePublicApiCompatibilityPromise
        this.shouldDeferQueueExperimentalSubmitAdmission = shouldDeferQueueExperimentalSubmitAdmission
        this.shouldReportQueueExperimentalSubmitAdmissionBlocked =
            shouldReportQueueExperimentalSubmitAdmissionBlocked
        this.shouldRejectQueueExperimentalSubmitAdmission = shouldRejectQueueExperimentalSubmitAdmission
        this.shouldReportQueueExperimentalSubmitAdmissionIncompatible =
            shouldReportQueueExperimentalSubmitAdmissionIncompatible
        this.shouldReportQueueExperimentalSubmitAdmissionUnauthorized =
            shouldReportQueueExperimentalSubmitAdmissionUnauthorized
        this.didPreserveQueueExperimentalSubmitRequest = didPreserveQueueExperimentalSubmitRequest
        this.didPreserveQueuePublicPermissionAndRollbackLinkage =
            didPreserveQueuePublicPermissionAndRollbackLinkage
        this.didPreservePreviousQueueStoreSnapshot = didPreservePreviousQueueStoreSnapshot
    }
}

// Submit result 是本轮 internal endpoint；它只报告 accepted / deferred / blocked / rejected 等 value facts，
// 不返回真实队列写入结果，也不暴露 lower-level owner facts。
struct CjguiInternalQueueExperimentalSubmitResult {
    let admission: CjguiInternalQueueExperimentalSubmitAdmission
    let didPrepareQueueExperimentalSubmitResult: Bool
    let didReportQueueExperimentalSubmitAccepted: Bool
    let didReportQueueExperimentalSubmitDeferred: Bool
    let didReportQueueExperimentalSubmitBlocked: Bool
    let didReportQueueExperimentalSubmitRejected: Bool
    let didReportQueueExperimentalSubmitIncompatible: Bool
    let didReportQueueExperimentalSubmitUnauthorized: Bool
    let didProjectQueueExperimentalSubmitResultEnvelope: Bool
    let didAvoidStableQueuePublicApiCompatibilityPromise: Bool
    let didPreserveQueueExperimentalSubmitAdmission: Bool
    let didPreservePreviousQueueStoreSnapshot: Bool

    init(
        admission: CjguiInternalQueueExperimentalSubmitAdmission,
        didPrepareQueueExperimentalSubmitResult: Bool,
        didReportQueueExperimentalSubmitAccepted: Bool,
        didReportQueueExperimentalSubmitDeferred: Bool,
        didReportQueueExperimentalSubmitBlocked: Bool,
        didReportQueueExperimentalSubmitRejected: Bool,
        didReportQueueExperimentalSubmitIncompatible: Bool,
        didReportQueueExperimentalSubmitUnauthorized: Bool,
        didProjectQueueExperimentalSubmitResultEnvelope: Bool,
        didAvoidStableQueuePublicApiCompatibilityPromise: Bool,
        didPreserveQueueExperimentalSubmitAdmission: Bool,
        didPreservePreviousQueueStoreSnapshot: Bool
    ) {
        this.admission = admission
        this.didPrepareQueueExperimentalSubmitResult = didPrepareQueueExperimentalSubmitResult
        this.didReportQueueExperimentalSubmitAccepted = didReportQueueExperimentalSubmitAccepted
        this.didReportQueueExperimentalSubmitDeferred = didReportQueueExperimentalSubmitDeferred
        this.didReportQueueExperimentalSubmitBlocked = didReportQueueExperimentalSubmitBlocked
        this.didReportQueueExperimentalSubmitRejected = didReportQueueExperimentalSubmitRejected
        this.didReportQueueExperimentalSubmitIncompatible = didReportQueueExperimentalSubmitIncompatible
        this.didReportQueueExperimentalSubmitUnauthorized = didReportQueueExperimentalSubmitUnauthorized
        this.didProjectQueueExperimentalSubmitResultEnvelope = didProjectQueueExperimentalSubmitResultEnvelope
        this.didAvoidStableQueuePublicApiCompatibilityPromise =
            didAvoidStableQueuePublicApiCompatibilityPromise
        this.didPreserveQueueExperimentalSubmitAdmission = didPreserveQueueExperimentalSubmitAdmission
        this.didPreservePreviousQueueStoreSnapshot = didPreservePreviousQueueStoreSnapshot
    }
}

func cjguiInternalBuildQueueExperimentalSubmitShell(
    compatibility: CjguiInternalQueuePublicNoStableCompatibility
): CjguiInternalQueueExperimentalSubmitShell {
    let compatibilityReady = compatibility.didPrepareQueuePublicNoStableCompatibility &&
        compatibility.hasStableQueuePublicApiCompatibilityPromise == false &&
        compatibility.didStateQueuePublicCompatibilityPromiseAbsent &&
        compatibility.didPreserveQueuePublicNamingPolicy &&
        compatibility.didPreserveQueuePublicExposureGate &&
        compatibility.didPreserveQueuePublicPermissionAndRollbackLinkage &&
        compatibility.didPreservePreviousQueueStoreSnapshot &&
        compatibility.shouldDeferQueuePublicNoStableCompatibility == false &&
        compatibility.shouldReportQueuePublicNoStableCompatibilityBlocked == false &&
        compatibility.shouldRejectQueuePublicNoStableCompatibility == false &&
        compatibility.shouldReportQueuePublicNoStableCompatibilityIncompatible == false &&
        compatibility.shouldReportQueuePublicNoStableCompatibilityUnauthorized == false
    let compatibilityDeferred = compatibility.didPrepareQueuePublicNoStableCompatibility == false &&
        compatibility.hasStableQueuePublicApiCompatibilityPromise == false &&
        compatibility.didStateQueuePublicCompatibilityPromiseAbsent == false &&
        compatibility.didPreserveQueuePublicNamingPolicy == false &&
        compatibility.didPreserveQueuePublicExposureGate == false &&
        compatibility.didPreserveQueuePublicPermissionAndRollbackLinkage == false &&
        compatibility.didPreservePreviousQueueStoreSnapshot &&
        compatibility.shouldDeferQueuePublicNoStableCompatibility &&
        compatibility.shouldReportQueuePublicNoStableCompatibilityBlocked == false &&
        compatibility.shouldRejectQueuePublicNoStableCompatibility == false &&
        compatibility.shouldReportQueuePublicNoStableCompatibilityIncompatible == false &&
        compatibility.shouldReportQueuePublicNoStableCompatibilityUnauthorized == false
    let compatibilityInconsistent = (
        compatibility.didPrepareQueuePublicNoStableCompatibility &&
            (
                compatibility.hasStableQueuePublicApiCompatibilityPromise ||
                compatibility.didStateQueuePublicCompatibilityPromiseAbsent == false ||
                compatibility.didPreserveQueuePublicNamingPolicy == false ||
                compatibility.didPreserveQueuePublicExposureGate == false ||
                compatibility.didPreserveQueuePublicPermissionAndRollbackLinkage == false ||
                compatibility.shouldDeferQueuePublicNoStableCompatibility ||
                compatibility.shouldReportQueuePublicNoStableCompatibilityBlocked ||
                compatibility.shouldRejectQueuePublicNoStableCompatibility ||
                compatibility.shouldReportQueuePublicNoStableCompatibilityIncompatible ||
                compatibility.shouldReportQueuePublicNoStableCompatibilityUnauthorized
            )
        ) ||
        (compatibility.hasStableQueuePublicApiCompatibilityPromise) ||
        (compatibility.didStateQueuePublicCompatibilityPromiseAbsent &&
            compatibility.didPrepareQueuePublicNoStableCompatibility == false) ||
        (compatibility.didPreserveQueuePublicNamingPolicy &&
            compatibility.didPrepareQueuePublicNoStableCompatibility == false) ||
        (compatibility.didPreserveQueuePublicExposureGate &&
            compatibility.didPrepareQueuePublicNoStableCompatibility == false) ||
        (compatibility.didPreserveQueuePublicPermissionAndRollbackLinkage &&
            compatibility.didPrepareQueuePublicNoStableCompatibility == false) ||
        (compatibility.didPreservePreviousQueueStoreSnapshot == false) ||
        (
            compatibility.shouldDeferQueuePublicNoStableCompatibility &&
            (
                compatibility.shouldReportQueuePublicNoStableCompatibilityBlocked ||
                compatibility.shouldRejectQueuePublicNoStableCompatibility ||
                compatibility.shouldReportQueuePublicNoStableCompatibilityIncompatible ||
                compatibility.shouldReportQueuePublicNoStableCompatibilityUnauthorized
            )
        )

    // no-stable-compatibility facts 不一致时必须 fail-closed，不能伪造 submit shell 可用。
    if (
        compatibility.shouldReportQueuePublicNoStableCompatibilityBlocked ||
        compatibility.shouldRejectQueuePublicNoStableCompatibility ||
        compatibility.shouldReportQueuePublicNoStableCompatibilityIncompatible ||
        compatibility.shouldReportQueuePublicNoStableCompatibilityUnauthorized ||
        compatibilityInconsistent
    ) {
        return CjguiInternalQueueExperimentalSubmitShell(
            compatibility,
            false,
            false,
            true,
            true,
            false,
            true,
            true,
            compatibility.shouldReportQueuePublicNoStableCompatibilityIncompatible || compatibilityInconsistent,
            compatibility.shouldReportQueuePublicNoStableCompatibilityUnauthorized,
            false,
            false,
            false,
            compatibility.didPreservePreviousQueueStoreSnapshot
        )
    }

    if (compatibilityReady) {
        return CjguiInternalQueueExperimentalSubmitShell(
            compatibility,
            true,
            true,
            true,
            true,
            false,
            false,
            false,
            false,
            false,
            true,
            true,
            true,
            true
        )
    }

    if (compatibilityDeferred) {
        return CjguiInternalQueueExperimentalSubmitShell(
            compatibility,
            false,
            false,
            true,
            true,
            true,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            true
        )
    }

    return CjguiInternalQueueExperimentalSubmitShell(
        compatibility,
        false,
        false,
        true,
        true,
        false,
        true,
        true,
        true,
        false,
        false,
        false,
        false,
        compatibility.didPreservePreviousQueueStoreSnapshot
    )
}

func cjguiInternalBuildQueueExperimentalSubmitRequest(
    shell: CjguiInternalQueueExperimentalSubmitShell
): CjguiInternalQueueExperimentalSubmitRequest {
    let shellReady = shell.didPrepareQueueExperimentalSubmitShell &&
        shell.didKeepQueueExperimentalSubmitShellExperimental &&
        shell.didUseQueueSubmissionTerminology &&
        shell.didAvoidStableQueuePublicApiCompatibilityPromise &&
        shell.didPreserveQueuePublicNoStableCompatibility &&
        shell.didPreserveQueuePublicExposureGate &&
        shell.didPreserveQueuePublicPermissionAndRollbackLinkage &&
        shell.didPreservePreviousQueueStoreSnapshot &&
        shell.shouldDeferQueueExperimentalSubmitShell == false &&
        shell.shouldReportQueueExperimentalSubmitShellBlocked == false &&
        shell.shouldRejectQueueExperimentalSubmitShell == false &&
        shell.shouldReportQueueExperimentalSubmitShellIncompatible == false &&
        shell.shouldReportQueueExperimentalSubmitShellUnauthorized == false
    let shellDeferred = shell.didPrepareQueueExperimentalSubmitShell == false &&
        shell.didKeepQueueExperimentalSubmitShellExperimental == false &&
        shell.didPreserveQueuePublicNoStableCompatibility == false &&
        shell.didPreserveQueuePublicExposureGate == false &&
        shell.didPreserveQueuePublicPermissionAndRollbackLinkage == false &&
        shell.didPreservePreviousQueueStoreSnapshot &&
        shell.shouldDeferQueueExperimentalSubmitShell &&
        shell.shouldReportQueueExperimentalSubmitShellBlocked == false &&
        shell.shouldRejectQueueExperimentalSubmitShell == false &&
        shell.shouldReportQueueExperimentalSubmitShellIncompatible == false &&
        shell.shouldReportQueueExperimentalSubmitShellUnauthorized == false
    let shellInconsistent = (
        shell.didPrepareQueueExperimentalSubmitShell &&
            (
                shell.didKeepQueueExperimentalSubmitShellExperimental == false ||
                shell.didUseQueueSubmissionTerminology == false ||
                shell.didAvoidStableQueuePublicApiCompatibilityPromise == false ||
                shell.didPreserveQueuePublicNoStableCompatibility == false ||
                shell.didPreserveQueuePublicExposureGate == false ||
                shell.didPreserveQueuePublicPermissionAndRollbackLinkage == false ||
                shell.shouldDeferQueueExperimentalSubmitShell ||
                shell.shouldReportQueueExperimentalSubmitShellBlocked ||
                shell.shouldRejectQueueExperimentalSubmitShell ||
                shell.shouldReportQueueExperimentalSubmitShellIncompatible ||
                shell.shouldReportQueueExperimentalSubmitShellUnauthorized
            )
        ) ||
        (shell.didUseQueueSubmissionTerminology == false) ||
        (shell.didAvoidStableQueuePublicApiCompatibilityPromise == false) ||
        (shell.didPreserveQueuePublicNoStableCompatibility &&
            shell.didPrepareQueueExperimentalSubmitShell == false) ||
        (shell.didPreserveQueuePublicExposureGate &&
            shell.didPrepareQueueExperimentalSubmitShell == false) ||
        (shell.didPreserveQueuePublicPermissionAndRollbackLinkage &&
            shell.didPrepareQueueExperimentalSubmitShell == false) ||
        (shell.didPreservePreviousQueueStoreSnapshot == false) ||
        (
            shell.shouldDeferQueueExperimentalSubmitShell &&
            (
                shell.shouldReportQueueExperimentalSubmitShellBlocked ||
                shell.shouldRejectQueueExperimentalSubmitShell ||
                shell.shouldReportQueueExperimentalSubmitShellIncompatible ||
                shell.shouldReportQueueExperimentalSubmitShellUnauthorized
            )
        )

    // submit shell 不一致时必须 fail-closed，request 不能伪造成功提交事实。
    if (
        shell.shouldReportQueueExperimentalSubmitShellBlocked ||
        shell.shouldRejectQueueExperimentalSubmitShell ||
        shell.shouldReportQueueExperimentalSubmitShellIncompatible ||
        shell.shouldReportQueueExperimentalSubmitShellUnauthorized ||
        shellInconsistent
    ) {
        return CjguiInternalQueueExperimentalSubmitRequest(
            shell,
            false,
            false,
            true,
            true,
            false,
            true,
            true,
            shell.shouldReportQueueExperimentalSubmitShellIncompatible || shellInconsistent,
            shell.shouldReportQueueExperimentalSubmitShellUnauthorized,
            false,
            false,
            shell.didPreservePreviousQueueStoreSnapshot
        )
    }

    if (shellReady) {
        return CjguiInternalQueueExperimentalSubmitRequest(
            shell,
            true,
            true,
            true,
            true,
            false,
            false,
            false,
            false,
            false,
            true,
            true,
            true
        )
    }

    if (shellDeferred) {
        return CjguiInternalQueueExperimentalSubmitRequest(
            shell,
            false,
            false,
            true,
            true,
            true,
            false,
            false,
            false,
            false,
            false,
            false,
            true
        )
    }

    return CjguiInternalQueueExperimentalSubmitRequest(
        shell,
        false,
        false,
        true,
        true,
        false,
        true,
        true,
        true,
        false,
        false,
        false,
        shell.didPreservePreviousQueueStoreSnapshot
    )
}

func cjguiInternalBuildQueueExperimentalSubmitAdmission(
    request: CjguiInternalQueueExperimentalSubmitRequest
): CjguiInternalQueueExperimentalSubmitAdmission {
    let requestReady = request.didPrepareQueueExperimentalSubmitRequest &&
        request.didUseDehydratedQueueSubmissionValue &&
        request.didAvoidExternalQueueObjectIntake &&
        request.didAvoidStableQueuePublicApiCompatibilityPromise &&
        request.didPreserveQueueExperimentalSubmitShell &&
        request.didPreserveQueuePublicPermissionAndRollbackLinkage &&
        request.didPreservePreviousQueueStoreSnapshot &&
        request.shouldDeferQueueExperimentalSubmitRequest == false &&
        request.shouldReportQueueExperimentalSubmitRequestBlocked == false &&
        request.shouldRejectQueueExperimentalSubmitRequest == false &&
        request.shouldReportQueueExperimentalSubmitRequestIncompatible == false &&
        request.shouldReportQueueExperimentalSubmitRequestUnauthorized == false
    let requestDeferred = request.didPrepareQueueExperimentalSubmitRequest == false &&
        request.didUseDehydratedQueueSubmissionValue == false &&
        request.didPreserveQueueExperimentalSubmitShell == false &&
        request.didPreserveQueuePublicPermissionAndRollbackLinkage == false &&
        request.didPreservePreviousQueueStoreSnapshot &&
        request.shouldDeferQueueExperimentalSubmitRequest &&
        request.shouldReportQueueExperimentalSubmitRequestBlocked == false &&
        request.shouldRejectQueueExperimentalSubmitRequest == false &&
        request.shouldReportQueueExperimentalSubmitRequestIncompatible == false &&
        request.shouldReportQueueExperimentalSubmitRequestUnauthorized == false
    let requestInconsistent = (
        request.didPrepareQueueExperimentalSubmitRequest &&
            (
                request.didUseDehydratedQueueSubmissionValue == false ||
                request.didAvoidExternalQueueObjectIntake == false ||
                request.didAvoidStableQueuePublicApiCompatibilityPromise == false ||
                request.didPreserveQueueExperimentalSubmitShell == false ||
                request.didPreserveQueuePublicPermissionAndRollbackLinkage == false ||
                request.shouldDeferQueueExperimentalSubmitRequest ||
                request.shouldReportQueueExperimentalSubmitRequestBlocked ||
                request.shouldRejectQueueExperimentalSubmitRequest ||
                request.shouldReportQueueExperimentalSubmitRequestIncompatible ||
                request.shouldReportQueueExperimentalSubmitRequestUnauthorized
            )
        ) ||
        (request.didAvoidExternalQueueObjectIntake == false) ||
        (request.didAvoidStableQueuePublicApiCompatibilityPromise == false) ||
        (request.didPreserveQueueExperimentalSubmitShell &&
            request.didPrepareQueueExperimentalSubmitRequest == false) ||
        (request.didPreserveQueuePublicPermissionAndRollbackLinkage &&
            request.didPrepareQueueExperimentalSubmitRequest == false) ||
        (request.didPreservePreviousQueueStoreSnapshot == false) ||
        (
            request.shouldDeferQueueExperimentalSubmitRequest &&
            (
                request.shouldReportQueueExperimentalSubmitRequestBlocked ||
                request.shouldRejectQueueExperimentalSubmitRequest ||
                request.shouldReportQueueExperimentalSubmitRequestIncompatible ||
                request.shouldReportQueueExperimentalSubmitRequestUnauthorized
            )
        )

    // request 不一致时必须 fail-closed，admission 不能绕过 internal pipeline。
    if (
        request.shouldReportQueueExperimentalSubmitRequestBlocked ||
        request.shouldRejectQueueExperimentalSubmitRequest ||
        request.shouldReportQueueExperimentalSubmitRequestIncompatible ||
        request.shouldReportQueueExperimentalSubmitRequestUnauthorized ||
        requestInconsistent
    ) {
        return CjguiInternalQueueExperimentalSubmitAdmission(
            request,
            false,
            false,
            false,
            true,
            false,
            true,
            true,
            request.shouldReportQueueExperimentalSubmitRequestIncompatible || requestInconsistent,
            request.shouldReportQueueExperimentalSubmitRequestUnauthorized,
            false,
            false,
            request.didPreservePreviousQueueStoreSnapshot
        )
    }

    if (requestReady) {
        return CjguiInternalQueueExperimentalSubmitAdmission(
            request,
            true,
            true,
            true,
            true,
            false,
            false,
            false,
            false,
            false,
            true,
            true,
            true
        )
    }

    if (requestDeferred) {
        return CjguiInternalQueueExperimentalSubmitAdmission(
            request,
            false,
            false,
            false,
            true,
            true,
            false,
            false,
            false,
            false,
            false,
            false,
            true
        )
    }

    return CjguiInternalQueueExperimentalSubmitAdmission(
        request,
        false,
        false,
        false,
        true,
        false,
        true,
        true,
        true,
        false,
        false,
        false,
        request.didPreservePreviousQueueStoreSnapshot
    )
}

func cjguiInternalBuildQueueExperimentalSubmitResult(
    admission: CjguiInternalQueueExperimentalSubmitAdmission
): CjguiInternalQueueExperimentalSubmitResult {
    let admissionReady = admission.didPrepareQueueExperimentalSubmitAdmission &&
        admission.didAllowQueueExperimentalSubmitShell &&
        admission.didKeepQueueExperimentalSubmitExperimental &&
        admission.didAvoidStableQueuePublicApiCompatibilityPromise &&
        admission.didPreserveQueueExperimentalSubmitRequest &&
        admission.didPreserveQueuePublicPermissionAndRollbackLinkage &&
        admission.didPreservePreviousQueueStoreSnapshot &&
        admission.shouldDeferQueueExperimentalSubmitAdmission == false &&
        admission.shouldReportQueueExperimentalSubmitAdmissionBlocked == false &&
        admission.shouldRejectQueueExperimentalSubmitAdmission == false &&
        admission.shouldReportQueueExperimentalSubmitAdmissionIncompatible == false &&
        admission.shouldReportQueueExperimentalSubmitAdmissionUnauthorized == false
    let admissionDeferred = admission.didPrepareQueueExperimentalSubmitAdmission == false &&
        admission.didAllowQueueExperimentalSubmitShell == false &&
        admission.didKeepQueueExperimentalSubmitExperimental == false &&
        admission.didPreserveQueueExperimentalSubmitRequest == false &&
        admission.didPreserveQueuePublicPermissionAndRollbackLinkage == false &&
        admission.didPreservePreviousQueueStoreSnapshot &&
        admission.shouldDeferQueueExperimentalSubmitAdmission &&
        admission.shouldReportQueueExperimentalSubmitAdmissionBlocked == false &&
        admission.shouldRejectQueueExperimentalSubmitAdmission == false &&
        admission.shouldReportQueueExperimentalSubmitAdmissionIncompatible == false &&
        admission.shouldReportQueueExperimentalSubmitAdmissionUnauthorized == false
    let admissionInconsistent = (
        admission.didPrepareQueueExperimentalSubmitAdmission &&
            (
                admission.didAllowQueueExperimentalSubmitShell == false ||
                admission.didKeepQueueExperimentalSubmitExperimental == false ||
                admission.didAvoidStableQueuePublicApiCompatibilityPromise == false ||
                admission.didPreserveQueueExperimentalSubmitRequest == false ||
                admission.didPreserveQueuePublicPermissionAndRollbackLinkage == false ||
                admission.shouldDeferQueueExperimentalSubmitAdmission ||
                admission.shouldReportQueueExperimentalSubmitAdmissionBlocked ||
                admission.shouldRejectQueueExperimentalSubmitAdmission ||
                admission.shouldReportQueueExperimentalSubmitAdmissionIncompatible ||
                admission.shouldReportQueueExperimentalSubmitAdmissionUnauthorized
            )
        ) ||
        (admission.didAvoidStableQueuePublicApiCompatibilityPromise == false) ||
        (admission.didPreserveQueueExperimentalSubmitRequest &&
            admission.didPrepareQueueExperimentalSubmitAdmission == false) ||
        (admission.didPreserveQueuePublicPermissionAndRollbackLinkage &&
            admission.didPrepareQueueExperimentalSubmitAdmission == false) ||
        (admission.didPreservePreviousQueueStoreSnapshot == false) ||
        (
            admission.shouldDeferQueueExperimentalSubmitAdmission &&
            (
                admission.shouldReportQueueExperimentalSubmitAdmissionBlocked ||
                admission.shouldRejectQueueExperimentalSubmitAdmission ||
                admission.shouldReportQueueExperimentalSubmitAdmissionIncompatible ||
                admission.shouldReportQueueExperimentalSubmitAdmissionUnauthorized
            )
        )

    // admission 不一致时必须 fail-closed，result 不能伪造 accepted。
    if (
        admission.shouldReportQueueExperimentalSubmitAdmissionBlocked ||
        admission.shouldRejectQueueExperimentalSubmitAdmission ||
        admission.shouldReportQueueExperimentalSubmitAdmissionIncompatible ||
        admission.shouldReportQueueExperimentalSubmitAdmissionUnauthorized ||
        admissionInconsistent
    ) {
        return CjguiInternalQueueExperimentalSubmitResult(
            admission,
            false,
            false,
            false,
            true,
            true,
            admission.shouldReportQueueExperimentalSubmitAdmissionIncompatible || admissionInconsistent,
            admission.shouldReportQueueExperimentalSubmitAdmissionUnauthorized,
            true,
            true,
            false,
            admission.didPreservePreviousQueueStoreSnapshot
        )
    }

    if (admissionReady) {
        return CjguiInternalQueueExperimentalSubmitResult(
            admission,
            true,
            true,
            false,
            false,
            false,
            false,
            false,
            true,
            true,
            true,
            true
        )
    }

    if (admissionDeferred) {
        return CjguiInternalQueueExperimentalSubmitResult(
            admission,
            false,
            false,
            true,
            false,
            false,
            false,
            false,
            true,
            true,
            false,
            true
        )
    }

    return CjguiInternalQueueExperimentalSubmitResult(
        admission,
        false,
        false,
        false,
        true,
        true,
        true,
        false,
        true,
        true,
        false,
        admission.didPreservePreviousQueueStoreSnapshot
    )
}

func cjguiInternalExecuteDefaultQueueExperimentalSubmitShellDraft(): CjguiInternalQueueExperimentalSubmitResult {
    // 默认 draft 只串联 experimental submit shell value facts；
    // 不是稳定公开 API，也不做真实队列写入或 storage mutation。
    let compatibility = cjguiInternalExecuteDefaultQueuePublicExposureDraft()
    let shell = cjguiInternalBuildQueueExperimentalSubmitShell(compatibility)
    let request = cjguiInternalBuildQueueExperimentalSubmitRequest(shell)
    let admission = cjguiInternalBuildQueueExperimentalSubmitAdmission(request)
    return cjguiInternalBuildQueueExperimentalSubmitResult(admission)
}

// 这是唯一允许的开放可见性 experimental submit shell：只返回 Bool readiness 投影。
// 维护约束：experimental、无稳定兼容承诺、不使用真实入队命名、不是 C 层二进制接口、
// 不产生真实副作用，也不暴露 internal owner facts。
public func cjguiExperimentalQueueSubmitShellReady(): Bool {
    let result = cjguiInternalExecuteDefaultQueueExperimentalSubmitShellDraft()
    return result.didPrepareQueueExperimentalSubmitResult &&
        result.didReportQueueExperimentalSubmitAccepted &&
        result.didProjectQueueExperimentalSubmitResultEnvelope &&
        result.didAvoidStableQueuePublicApiCompatibilityPromise &&
        result.didPreserveQueueExperimentalSubmitAdmission &&
        result.didPreservePreviousQueueStoreSnapshot &&
        result.didReportQueueExperimentalSubmitDeferred == false &&
        result.didReportQueueExperimentalSubmitBlocked == false &&
        result.didReportQueueExperimentalSubmitRejected == false &&
        result.didReportQueueExperimentalSubmitIncompatible == false &&
        result.didReportQueueExperimentalSubmitUnauthorized == false
}

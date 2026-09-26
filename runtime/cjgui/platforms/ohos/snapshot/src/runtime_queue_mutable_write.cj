package cjgui

// Internal Queue Mutable Store Write Admission owner:
// - 本文件只消费 QueueMutableStoreShell。
// - Truth 是 owner-local mutable write policy / version-check / admission / readiness 的内部 value facts。
// - Stop-line: 不做真实 item collection mutation、不写 process-wide queue storage、不创建 global mutable queue / singleton、
//   不 enqueue、不 drain、不接 event loop / scheduler / platform callback、不调用 runtime cycle，也不回塞 critical runtime_state.cj。

// Mutable write policy 只判断 owner-local mutable shell 是否可进入写入准入检查；
// 它不是实际 mutable write，也不是全局队列写入授权副作用。
struct CjguiInternalQueueMutableWritePolicy {
    let shell: CjguiInternalQueueMutableStoreShell
    let allowsOwnerLocalMutableWrite: Bool
    let shouldDeferQueueMutableWritePolicy: Bool
    let shouldReportQueueMutableWritePolicyBlocked: Bool
    let didPreserveQueueMutableStoreShell: Bool
    let didRequireQueueMutableWriteVersionCheck: Bool

    init(
        shell: CjguiInternalQueueMutableStoreShell,
        allowsOwnerLocalMutableWrite: Bool,
        shouldDeferQueueMutableWritePolicy: Bool,
        shouldReportQueueMutableWritePolicyBlocked: Bool,
        didPreserveQueueMutableStoreShell: Bool,
        didRequireQueueMutableWriteVersionCheck: Bool
    ) {
        this.shell = shell
        this.allowsOwnerLocalMutableWrite = allowsOwnerLocalMutableWrite
        this.shouldDeferQueueMutableWritePolicy = shouldDeferQueueMutableWritePolicy
        this.shouldReportQueueMutableWritePolicyBlocked = shouldReportQueueMutableWritePolicyBlocked
        this.didPreserveQueueMutableStoreShell = didPreserveQueueMutableStoreShell
        this.didRequireQueueMutableWriteVersionCheck = didRequireQueueMutableWriteVersionCheck
    }
}

// Mutable write version check 只比较 shell 内携带的 immutable version value；
// 它不会写入版本计数器，也不会暴露跨 owner mutable reference。
struct CjguiInternalQueueMutableWriteVersionCheck {
    let policy: CjguiInternalQueueMutableWritePolicy
    let expectedVersion: CjguiInternalQueueStoreVersion
    let observedVersion: CjguiInternalQueueStoreVersion
    let didPassQueueMutableWriteVersionCheck: Bool
    let shouldDeferQueueMutableWriteVersionCheck: Bool
    let shouldReportQueueMutableWriteVersionCheckBlocked: Bool
    let didPreserveQueueMutableWritePolicy: Bool

    init(
        policy: CjguiInternalQueueMutableWritePolicy,
        expectedVersion: CjguiInternalQueueStoreVersion,
        observedVersion: CjguiInternalQueueStoreVersion,
        didPassQueueMutableWriteVersionCheck: Bool,
        shouldDeferQueueMutableWriteVersionCheck: Bool,
        shouldReportQueueMutableWriteVersionCheckBlocked: Bool,
        didPreserveQueueMutableWritePolicy: Bool
    ) {
        this.policy = policy
        this.expectedVersion = expectedVersion
        this.observedVersion = observedVersion
        this.didPassQueueMutableWriteVersionCheck = didPassQueueMutableWriteVersionCheck
        this.shouldDeferQueueMutableWriteVersionCheck = shouldDeferQueueMutableWriteVersionCheck
        this.shouldReportQueueMutableWriteVersionCheckBlocked = shouldReportQueueMutableWriteVersionCheckBlocked
        this.didPreserveQueueMutableWritePolicy = didPreserveQueueMutableWritePolicy
    }
}

// Mutable write admission 是 owner-local 写入准入门；
// open 只表示 can-write facts 成立，不代表实际写入、enqueue 或 storage mutation。
struct CjguiInternalQueueMutableWriteAdmission {
    let versionCheck: CjguiInternalQueueMutableWriteVersionCheck
    let isQueueMutableWriteAdmissionOpen: Bool
    let shouldDeferQueueMutableWriteAdmission: Bool
    let shouldReportQueueMutableWriteAdmissionBlocked: Bool
    let didPreserveQueueMutableWriteVersionCheck: Bool

    init(
        versionCheck: CjguiInternalQueueMutableWriteVersionCheck,
        isQueueMutableWriteAdmissionOpen: Bool,
        shouldDeferQueueMutableWriteAdmission: Bool,
        shouldReportQueueMutableWriteAdmissionBlocked: Bool,
        didPreserveQueueMutableWriteVersionCheck: Bool
    ) {
        this.versionCheck = versionCheck
        this.isQueueMutableWriteAdmissionOpen = isQueueMutableWriteAdmissionOpen
        this.shouldDeferQueueMutableWriteAdmission = shouldDeferQueueMutableWriteAdmission
        this.shouldReportQueueMutableWriteAdmissionBlocked = shouldReportQueueMutableWriteAdmissionBlocked
        this.didPreserveQueueMutableWriteVersionCheck = didPreserveQueueMutableWriteVersionCheck
    }
}

// Mutable write readiness 是本轮 canonical endpoint；
// ready 只表示写入准入 value facts 已收束，不是真实 mutable write 结果。
struct CjguiInternalQueueMutableWriteReadiness {
    let admission: CjguiInternalQueueMutableWriteAdmission
    let isQueueMutableWriteReady: Bool
    let shouldDeferQueueMutableWriteReadiness: Bool
    let shouldReportQueueMutableWriteReadinessBlocked: Bool
    let didPreserveQueueMutableWriteAdmission: Bool

    init(
        admission: CjguiInternalQueueMutableWriteAdmission,
        isQueueMutableWriteReady: Bool,
        shouldDeferQueueMutableWriteReadiness: Bool,
        shouldReportQueueMutableWriteReadinessBlocked: Bool,
        didPreserveQueueMutableWriteAdmission: Bool
    ) {
        this.admission = admission
        this.isQueueMutableWriteReady = isQueueMutableWriteReady
        this.shouldDeferQueueMutableWriteReadiness = shouldDeferQueueMutableWriteReadiness
        this.shouldReportQueueMutableWriteReadinessBlocked = shouldReportQueueMutableWriteReadinessBlocked
        this.didPreserveQueueMutableWriteAdmission = didPreserveQueueMutableWriteAdmission
    }
}

func cjguiInternalBuildQueueMutableWritePolicy(
    shell: CjguiInternalQueueMutableStoreShell
): CjguiInternalQueueMutableWritePolicy {
    let shellReady = shell.isQueueMutableStoreShellReady &&
        shell.didPreserveQueueMutableStoreVersionMarker &&
        shell.didKeepQueueMutableStoreOwnerLocal &&
        shell.shouldDeferQueueMutableStoreShell == false &&
        shell.shouldReportQueueMutableStoreShellBlocked == false
    let shellDeferred = shell.isQueueMutableStoreShellReady == false &&
        shell.didPreserveQueueMutableStoreVersionMarker == false &&
        shell.didKeepQueueMutableStoreOwnerLocal &&
        shell.shouldDeferQueueMutableStoreShell &&
        shell.shouldReportQueueMutableStoreShellBlocked == false
    let shellInconsistent = (
        shell.isQueueMutableStoreShellReady &&
            (shell.shouldDeferQueueMutableStoreShell || shell.shouldReportQueueMutableStoreShellBlocked)
        ) ||
        (shell.didPreserveQueueMutableStoreVersionMarker &&
            shell.isQueueMutableStoreShellReady == false) ||
        (shell.didPreserveQueueMutableStoreVersionMarker == false &&
            shell.isQueueMutableStoreShellReady) ||
        (shell.didKeepQueueMutableStoreOwnerLocal == false) ||
        (shell.shouldDeferQueueMutableStoreShell && shell.shouldReportQueueMutableStoreShellBlocked)

    // shell facts 不一致时必须 fail-closed，避免把 owner-local shell 误当成真实 mutable write 准入。
    if (
        shell.shouldReportQueueMutableStoreShellBlocked ||
        shellInconsistent
    ) {
        return CjguiInternalQueueMutableWritePolicy(shell, false, false, true, false, false)
    }

    if (shellReady) {
        return CjguiInternalQueueMutableWritePolicy(shell, true, false, false, true, true)
    }

    if (shellDeferred) {
        return CjguiInternalQueueMutableWritePolicy(shell, false, true, false, false, false)
    }

    return CjguiInternalQueueMutableWritePolicy(shell, false, false, true, false, false)
}

func cjguiInternalBuildQueueMutableWriteVersionCheck(
    policy: CjguiInternalQueueMutableWritePolicy
): CjguiInternalQueueMutableWriteVersionCheck {
    let expectedVersion = policy.shell.versionMarker.holder.currentSnapshot.version
    let observedVersion = policy.shell.versionMarker.version
    let versionMatches = expectedVersion.value == observedVersion.value
    let policyReady = policy.allowsOwnerLocalMutableWrite &&
        policy.didPreserveQueueMutableStoreShell &&
        policy.didRequireQueueMutableWriteVersionCheck &&
        policy.shouldDeferQueueMutableWritePolicy == false &&
        policy.shouldReportQueueMutableWritePolicyBlocked == false
    let policyDeferred = policy.allowsOwnerLocalMutableWrite == false &&
        policy.didPreserveQueueMutableStoreShell == false &&
        policy.didRequireQueueMutableWriteVersionCheck == false &&
        policy.shouldDeferQueueMutableWritePolicy &&
        policy.shouldReportQueueMutableWritePolicyBlocked == false
    let policyInconsistent = (
        policy.allowsOwnerLocalMutableWrite &&
            (policy.shouldDeferQueueMutableWritePolicy || policy.shouldReportQueueMutableWritePolicyBlocked)
        ) ||
        (policy.didPreserveQueueMutableStoreShell &&
            policy.allowsOwnerLocalMutableWrite == false) ||
        (policy.didPreserveQueueMutableStoreShell == false &&
            policy.allowsOwnerLocalMutableWrite) ||
        (policy.didRequireQueueMutableWriteVersionCheck &&
            policy.allowsOwnerLocalMutableWrite == false) ||
        (policy.shouldDeferQueueMutableWritePolicy && policy.shouldReportQueueMutableWritePolicyBlocked)

    // policy facts 不一致时必须 fail-closed，version check 不能绕过写入准入门。
    if (
        policy.shouldReportQueueMutableWritePolicyBlocked ||
        policyInconsistent
    ) {
        return CjguiInternalQueueMutableWriteVersionCheck(
            policy,
            expectedVersion,
            observedVersion,
            false,
            false,
            true,
            false
        )
    }

    // version mismatch 必须 fail-closed，避免旧 shell 或错配 marker 被误当成可写状态。
    if (policyReady && versionMatches == false) {
        return CjguiInternalQueueMutableWriteVersionCheck(
            policy,
            expectedVersion,
            observedVersion,
            false,
            false,
            true,
            false
        )
    }

    if (policyReady) {
        return CjguiInternalQueueMutableWriteVersionCheck(
            policy,
            expectedVersion,
            observedVersion,
            true,
            false,
            false,
            true
        )
    }

    if (policyDeferred) {
        return CjguiInternalQueueMutableWriteVersionCheck(
            policy,
            expectedVersion,
            observedVersion,
            false,
            true,
            false,
            false
        )
    }

    return CjguiInternalQueueMutableWriteVersionCheck(
        policy,
        expectedVersion,
        observedVersion,
        false,
        false,
        true,
        false
    )
}

func cjguiInternalBuildQueueMutableWriteAdmission(
    versionCheck: CjguiInternalQueueMutableWriteVersionCheck
): CjguiInternalQueueMutableWriteAdmission {
    let checkReady = versionCheck.didPassQueueMutableWriteVersionCheck &&
        versionCheck.didPreserveQueueMutableWritePolicy &&
        versionCheck.shouldDeferQueueMutableWriteVersionCheck == false &&
        versionCheck.shouldReportQueueMutableWriteVersionCheckBlocked == false
    let checkDeferred = versionCheck.didPassQueueMutableWriteVersionCheck == false &&
        versionCheck.didPreserveQueueMutableWritePolicy == false &&
        versionCheck.shouldDeferQueueMutableWriteVersionCheck &&
        versionCheck.shouldReportQueueMutableWriteVersionCheckBlocked == false
    let checkInconsistent = (
        versionCheck.didPassQueueMutableWriteVersionCheck &&
            (
                versionCheck.shouldDeferQueueMutableWriteVersionCheck ||
                versionCheck.shouldReportQueueMutableWriteVersionCheckBlocked
            )
        ) ||
        (versionCheck.didPreserveQueueMutableWritePolicy &&
            versionCheck.didPassQueueMutableWriteVersionCheck == false) ||
        (versionCheck.didPreserveQueueMutableWritePolicy == false &&
            versionCheck.didPassQueueMutableWriteVersionCheck) ||
        (
            versionCheck.shouldDeferQueueMutableWriteVersionCheck &&
            versionCheck.shouldReportQueueMutableWriteVersionCheckBlocked
        )

    // version-check facts 不一致时必须 fail-closed，admission 不能伪造为 open。
    if (
        versionCheck.shouldReportQueueMutableWriteVersionCheckBlocked ||
        checkInconsistent
    ) {
        return CjguiInternalQueueMutableWriteAdmission(versionCheck, false, false, true, false)
    }

    if (checkReady) {
        return CjguiInternalQueueMutableWriteAdmission(versionCheck, true, false, false, true)
    }

    if (checkDeferred) {
        return CjguiInternalQueueMutableWriteAdmission(versionCheck, false, true, false, false)
    }

    return CjguiInternalQueueMutableWriteAdmission(versionCheck, false, false, true, false)
}

func cjguiInternalBuildQueueMutableWriteReadiness(
    admission: CjguiInternalQueueMutableWriteAdmission
): CjguiInternalQueueMutableWriteReadiness {
    let admissionReady = admission.isQueueMutableWriteAdmissionOpen &&
        admission.didPreserveQueueMutableWriteVersionCheck &&
        admission.shouldDeferQueueMutableWriteAdmission == false &&
        admission.shouldReportQueueMutableWriteAdmissionBlocked == false
    let admissionDeferred = admission.isQueueMutableWriteAdmissionOpen == false &&
        admission.didPreserveQueueMutableWriteVersionCheck == false &&
        admission.shouldDeferQueueMutableWriteAdmission &&
        admission.shouldReportQueueMutableWriteAdmissionBlocked == false
    let admissionInconsistent = (
        admission.isQueueMutableWriteAdmissionOpen &&
            (admission.shouldDeferQueueMutableWriteAdmission ||
                admission.shouldReportQueueMutableWriteAdmissionBlocked)
        ) ||
        (admission.didPreserveQueueMutableWriteVersionCheck &&
            admission.isQueueMutableWriteAdmissionOpen == false) ||
        (admission.didPreserveQueueMutableWriteVersionCheck == false &&
            admission.isQueueMutableWriteAdmissionOpen) ||
        (admission.shouldDeferQueueMutableWriteAdmission &&
            admission.shouldReportQueueMutableWriteAdmissionBlocked)

    // admission facts 不一致时必须 fail-closed，readiness 不代表真实 mutable write。
    if (
        admission.shouldReportQueueMutableWriteAdmissionBlocked ||
        admissionInconsistent
    ) {
        return CjguiInternalQueueMutableWriteReadiness(admission, false, false, true, false)
    }

    if (admissionReady) {
        return CjguiInternalQueueMutableWriteReadiness(admission, true, false, false, true)
    }

    if (admissionDeferred) {
        return CjguiInternalQueueMutableWriteReadiness(admission, false, true, false, false)
    }

    return CjguiInternalQueueMutableWriteReadiness(admission, false, false, true, false)
}

func cjguiInternalExecuteDefaultQueueMutableWriteAdmissionDraft(): CjguiInternalQueueMutableWriteReadiness {
    // 默认 draft 只串联 mutable shell -> write admission value pipeline，不写真实队列、不 enqueue、不 drain。
    let shell = cjguiInternalExecuteDefaultQueueMutableStoreShellDraft()
    let policy = cjguiInternalBuildQueueMutableWritePolicy(shell)
    let versionCheck = cjguiInternalBuildQueueMutableWriteVersionCheck(policy)
    let admission = cjguiInternalBuildQueueMutableWriteAdmission(versionCheck)
    return cjguiInternalBuildQueueMutableWriteReadiness(admission)
}

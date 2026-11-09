package cjgui

// Internal Queue Public API Shell owner:
// - 本文件只消费 QueuePublicCompatibilityNote。
// - Truth 是 internal-only API shell / submission entry / entry result / result handoff value facts。
// - Stop-line: API shell 是 internal-only，不是公开 API，不承诺 stable compatibility，不提供 C ABI，不执行真实入队；
//   不接收原始指针 / 原生句柄 / 平台对象，不写 process-wide queue storage，不创建 global mutable queue /
//   singleton，不做 item collection mutation，不 drain，不接 scheduler / event loop / platform callback / runtime
//   cycle，也不回塞 critical runtime_state.cj。

// API shell 只把 compatibility note 投影成内部入口外壳 facts；
// 它不是公开 API function，也不形成稳定兼容性承诺。
struct CjguiInternalQueuePublicApiShell {
    let compatibilityNote: CjguiInternalQueuePublicCompatibilityNote
    let didPrepareQueuePublicApiShell: Bool
    let didKeepQueuePublicApiShellInternalOnly: Bool
    let hasStableQueuePublicApiCompatibilityPromise: Bool
    let shouldDeferQueuePublicApiShell: Bool
    let shouldReportQueuePublicApiShellBlocked: Bool
    let shouldRejectQueuePublicApiShell: Bool
    let shouldReportQueuePublicApiShellIncompatible: Bool
    let shouldReportQueuePublicApiShellUnauthorized: Bool
    let didPreserveQueuePublicCompatibilityNote: Bool
    let didPreserveQueuePublicResultEnvelopeHandoff: Bool
    let didPreserveQueuePublicPermissionAndRollbackLinkage: Bool
    let didPreservePreviousQueueStoreSnapshot: Bool

    init(
        compatibilityNote: CjguiInternalQueuePublicCompatibilityNote,
        didPrepareQueuePublicApiShell: Bool,
        didKeepQueuePublicApiShellInternalOnly: Bool,
        hasStableQueuePublicApiCompatibilityPromise: Bool,
        shouldDeferQueuePublicApiShell: Bool,
        shouldReportQueuePublicApiShellBlocked: Bool,
        shouldRejectQueuePublicApiShell: Bool,
        shouldReportQueuePublicApiShellIncompatible: Bool,
        shouldReportQueuePublicApiShellUnauthorized: Bool,
        didPreserveQueuePublicCompatibilityNote: Bool,
        didPreserveQueuePublicResultEnvelopeHandoff: Bool,
        didPreserveQueuePublicPermissionAndRollbackLinkage: Bool,
        didPreservePreviousQueueStoreSnapshot: Bool
    ) {
        this.compatibilityNote = compatibilityNote
        this.didPrepareQueuePublicApiShell = didPrepareQueuePublicApiShell
        this.didKeepQueuePublicApiShellInternalOnly = didKeepQueuePublicApiShellInternalOnly
        this.hasStableQueuePublicApiCompatibilityPromise = hasStableQueuePublicApiCompatibilityPromise
        this.shouldDeferQueuePublicApiShell = shouldDeferQueuePublicApiShell
        this.shouldReportQueuePublicApiShellBlocked = shouldReportQueuePublicApiShellBlocked
        this.shouldRejectQueuePublicApiShell = shouldRejectQueuePublicApiShell
        this.shouldReportQueuePublicApiShellIncompatible = shouldReportQueuePublicApiShellIncompatible
        this.shouldReportQueuePublicApiShellUnauthorized = shouldReportQueuePublicApiShellUnauthorized
        this.didPreserveQueuePublicCompatibilityNote = didPreserveQueuePublicCompatibilityNote
        this.didPreserveQueuePublicResultEnvelopeHandoff = didPreserveQueuePublicResultEnvelopeHandoff
        this.didPreserveQueuePublicPermissionAndRollbackLinkage = didPreserveQueuePublicPermissionAndRollbackLinkage
        this.didPreservePreviousQueueStoreSnapshot = didPreservePreviousQueueStoreSnapshot
    }
}

// Submission entry 只描述内部 submission entry facts；它不接受原始指针、原生句柄或平台对象。
struct CjguiInternalQueuePublicSubmissionEntry {
    let shell: CjguiInternalQueuePublicApiShell
    let didPrepareQueuePublicSubmissionEntry: Bool
    let didUseQueuePublicSubmissionEntryTerminology: Bool
    let didAvoidStableQueuePublicApiCompatibilityPromise: Bool
    let shouldDeferQueuePublicSubmissionEntry: Bool
    let shouldReportQueuePublicSubmissionEntryBlocked: Bool
    let shouldRejectQueuePublicSubmissionEntry: Bool
    let shouldReportQueuePublicSubmissionEntryIncompatible: Bool
    let shouldReportQueuePublicSubmissionEntryUnauthorized: Bool
    let didPreserveQueuePublicApiShell: Bool
    let didPreserveQueuePublicResultEnvelopeHandoff: Bool
    let didPreserveQueuePublicPermissionAndRollbackLinkage: Bool
    let didPreservePreviousQueueStoreSnapshot: Bool

    init(
        shell: CjguiInternalQueuePublicApiShell,
        didPrepareQueuePublicSubmissionEntry: Bool,
        didUseQueuePublicSubmissionEntryTerminology: Bool,
        didAvoidStableQueuePublicApiCompatibilityPromise: Bool,
        shouldDeferQueuePublicSubmissionEntry: Bool,
        shouldReportQueuePublicSubmissionEntryBlocked: Bool,
        shouldRejectQueuePublicSubmissionEntry: Bool,
        shouldReportQueuePublicSubmissionEntryIncompatible: Bool,
        shouldReportQueuePublicSubmissionEntryUnauthorized: Bool,
        didPreserveQueuePublicApiShell: Bool,
        didPreserveQueuePublicResultEnvelopeHandoff: Bool,
        didPreserveQueuePublicPermissionAndRollbackLinkage: Bool,
        didPreservePreviousQueueStoreSnapshot: Bool
    ) {
        this.shell = shell
        this.didPrepareQueuePublicSubmissionEntry = didPrepareQueuePublicSubmissionEntry
        this.didUseQueuePublicSubmissionEntryTerminology = didUseQueuePublicSubmissionEntryTerminology
        this.didAvoidStableQueuePublicApiCompatibilityPromise = didAvoidStableQueuePublicApiCompatibilityPromise
        this.shouldDeferQueuePublicSubmissionEntry = shouldDeferQueuePublicSubmissionEntry
        this.shouldReportQueuePublicSubmissionEntryBlocked = shouldReportQueuePublicSubmissionEntryBlocked
        this.shouldRejectQueuePublicSubmissionEntry = shouldRejectQueuePublicSubmissionEntry
        this.shouldReportQueuePublicSubmissionEntryIncompatible =
            shouldReportQueuePublicSubmissionEntryIncompatible
        this.shouldReportQueuePublicSubmissionEntryUnauthorized =
            shouldReportQueuePublicSubmissionEntryUnauthorized
        this.didPreserveQueuePublicApiShell = didPreserveQueuePublicApiShell
        this.didPreserveQueuePublicResultEnvelopeHandoff = didPreserveQueuePublicResultEnvelopeHandoff
        this.didPreserveQueuePublicPermissionAndRollbackLinkage = didPreserveQueuePublicPermissionAndRollbackLinkage
        this.didPreservePreviousQueueStoreSnapshot = didPreservePreviousQueueStoreSnapshot
    }
}

// Entry result 只投影 result envelope / error projection / audit reference / compatibility note；
// 它不得直接暴露 lower-level owner facts。
struct CjguiInternalQueuePublicEntryResult {
    let entry: CjguiInternalQueuePublicSubmissionEntry
    let didPrepareQueuePublicEntryResult: Bool
    let didProjectQueuePublicResultEnvelope: Bool
    let didProjectQueuePublicErrorProjection: Bool
    let didProjectQueuePublicAuditReference: Bool
    let didProjectQueuePublicCompatibilityNote: Bool
    let didAvoidLowerLevelQueueOwnerFactExposure: Bool
    let shouldDeferQueuePublicEntryResult: Bool
    let shouldReportQueuePublicEntryResultBlocked: Bool
    let shouldRejectQueuePublicEntryResult: Bool
    let shouldReportQueuePublicEntryResultIncompatible: Bool
    let shouldReportQueuePublicEntryResultUnauthorized: Bool
    let didPreserveQueuePublicSubmissionEntry: Bool
    let didPreserveQueuePublicPermissionAndRollbackLinkage: Bool
    let didPreservePreviousQueueStoreSnapshot: Bool

    init(
        entry: CjguiInternalQueuePublicSubmissionEntry,
        didPrepareQueuePublicEntryResult: Bool,
        didProjectQueuePublicResultEnvelope: Bool,
        didProjectQueuePublicErrorProjection: Bool,
        didProjectQueuePublicAuditReference: Bool,
        didProjectQueuePublicCompatibilityNote: Bool,
        didAvoidLowerLevelQueueOwnerFactExposure: Bool,
        shouldDeferQueuePublicEntryResult: Bool,
        shouldReportQueuePublicEntryResultBlocked: Bool,
        shouldRejectQueuePublicEntryResult: Bool,
        shouldReportQueuePublicEntryResultIncompatible: Bool,
        shouldReportQueuePublicEntryResultUnauthorized: Bool,
        didPreserveQueuePublicSubmissionEntry: Bool,
        didPreserveQueuePublicPermissionAndRollbackLinkage: Bool,
        didPreservePreviousQueueStoreSnapshot: Bool
    ) {
        this.entry = entry
        this.didPrepareQueuePublicEntryResult = didPrepareQueuePublicEntryResult
        this.didProjectQueuePublicResultEnvelope = didProjectQueuePublicResultEnvelope
        this.didProjectQueuePublicErrorProjection = didProjectQueuePublicErrorProjection
        this.didProjectQueuePublicAuditReference = didProjectQueuePublicAuditReference
        this.didProjectQueuePublicCompatibilityNote = didProjectQueuePublicCompatibilityNote
        this.didAvoidLowerLevelQueueOwnerFactExposure = didAvoidLowerLevelQueueOwnerFactExposure
        this.shouldDeferQueuePublicEntryResult = shouldDeferQueuePublicEntryResult
        this.shouldReportQueuePublicEntryResultBlocked = shouldReportQueuePublicEntryResultBlocked
        this.shouldRejectQueuePublicEntryResult = shouldRejectQueuePublicEntryResult
        this.shouldReportQueuePublicEntryResultIncompatible = shouldReportQueuePublicEntryResultIncompatible
        this.shouldReportQueuePublicEntryResultUnauthorized = shouldReportQueuePublicEntryResultUnauthorized
        this.didPreserveQueuePublicSubmissionEntry = didPreserveQueuePublicSubmissionEntry
        this.didPreserveQueuePublicPermissionAndRollbackLinkage = didPreserveQueuePublicPermissionAndRollbackLinkage
        this.didPreservePreviousQueueStoreSnapshot = didPreservePreviousQueueStoreSnapshot
    }
}

// Entry result handoff 是当前 API shell endpoint；它只是内部 handoff facts，
// 不是公开发布、observer callback、C ABI result 或真实入队结果。
struct CjguiInternalQueuePublicEntryResultHandoff {
    let result: CjguiInternalQueuePublicEntryResult
    let didPrepareQueuePublicEntryResultHandoff: Bool
    let didKeepQueuePublicEntryResultHandoffInternalOnly: Bool
    let shouldDeferQueuePublicEntryResultHandoff: Bool
    let shouldReportQueuePublicEntryResultHandoffBlocked: Bool
    let shouldRejectQueuePublicEntryResultHandoff: Bool
    let shouldReportQueuePublicEntryResultHandoffIncompatible: Bool
    let shouldReportQueuePublicEntryResultHandoffUnauthorized: Bool
    let didPreserveQueuePublicEntryResult: Bool
    let didPreserveQueuePublicPermissionAndRollbackLinkage: Bool
    let didPreservePreviousQueueStoreSnapshot: Bool

    init(
        result: CjguiInternalQueuePublicEntryResult,
        didPrepareQueuePublicEntryResultHandoff: Bool,
        didKeepQueuePublicEntryResultHandoffInternalOnly: Bool,
        shouldDeferQueuePublicEntryResultHandoff: Bool,
        shouldReportQueuePublicEntryResultHandoffBlocked: Bool,
        shouldRejectQueuePublicEntryResultHandoff: Bool,
        shouldReportQueuePublicEntryResultHandoffIncompatible: Bool,
        shouldReportQueuePublicEntryResultHandoffUnauthorized: Bool,
        didPreserveQueuePublicEntryResult: Bool,
        didPreserveQueuePublicPermissionAndRollbackLinkage: Bool,
        didPreservePreviousQueueStoreSnapshot: Bool
    ) {
        this.result = result
        this.didPrepareQueuePublicEntryResultHandoff = didPrepareQueuePublicEntryResultHandoff
        this.didKeepQueuePublicEntryResultHandoffInternalOnly = didKeepQueuePublicEntryResultHandoffInternalOnly
        this.shouldDeferQueuePublicEntryResultHandoff = shouldDeferQueuePublicEntryResultHandoff
        this.shouldReportQueuePublicEntryResultHandoffBlocked = shouldReportQueuePublicEntryResultHandoffBlocked
        this.shouldRejectQueuePublicEntryResultHandoff = shouldRejectQueuePublicEntryResultHandoff
        this.shouldReportQueuePublicEntryResultHandoffIncompatible =
            shouldReportQueuePublicEntryResultHandoffIncompatible
        this.shouldReportQueuePublicEntryResultHandoffUnauthorized =
            shouldReportQueuePublicEntryResultHandoffUnauthorized
        this.didPreserveQueuePublicEntryResult = didPreserveQueuePublicEntryResult
        this.didPreserveQueuePublicPermissionAndRollbackLinkage = didPreserveQueuePublicPermissionAndRollbackLinkage
        this.didPreservePreviousQueueStoreSnapshot = didPreservePreviousQueueStoreSnapshot
    }
}

func cjguiInternalBuildQueuePublicApiShell(
    compatibilityNote: CjguiInternalQueuePublicCompatibilityNote
): CjguiInternalQueuePublicApiShell {
    let noteReady = compatibilityNote.didPrepareQueuePublicCompatibilityNote &&
        compatibilityNote.hasStableQueuePublicApiCompatibilityPromise == false &&
        compatibilityNote.didStateQueuePublicCompatibilityPromiseAbsent &&
        compatibilityNote.didPreserveQueuePublicAuditReference &&
        compatibilityNote.didPreserveQueuePublicPermissionAndRollbackLinkage &&
        compatibilityNote.didPreservePreviousQueueStoreSnapshot &&
        compatibilityNote.shouldDeferQueuePublicCompatibilityNote == false &&
        compatibilityNote.shouldReportQueuePublicCompatibilityNoteBlocked == false &&
        compatibilityNote.shouldRejectQueuePublicCompatibilityNote == false &&
        compatibilityNote.shouldReportQueuePublicCompatibilityNoteIncompatible == false &&
        compatibilityNote.shouldReportQueuePublicCompatibilityNoteUnauthorized == false
    let noteDeferred = compatibilityNote.didPrepareQueuePublicCompatibilityNote == false &&
        compatibilityNote.hasStableQueuePublicApiCompatibilityPromise == false &&
        compatibilityNote.didStateQueuePublicCompatibilityPromiseAbsent == false &&
        compatibilityNote.didPreserveQueuePublicAuditReference == false &&
        compatibilityNote.didPreserveQueuePublicPermissionAndRollbackLinkage == false &&
        compatibilityNote.didPreservePreviousQueueStoreSnapshot &&
        compatibilityNote.shouldDeferQueuePublicCompatibilityNote &&
        compatibilityNote.shouldReportQueuePublicCompatibilityNoteBlocked == false &&
        compatibilityNote.shouldRejectQueuePublicCompatibilityNote == false &&
        compatibilityNote.shouldReportQueuePublicCompatibilityNoteIncompatible == false &&
        compatibilityNote.shouldReportQueuePublicCompatibilityNoteUnauthorized == false
    let noteInconsistent = (
        compatibilityNote.didPrepareQueuePublicCompatibilityNote &&
            (
                compatibilityNote.hasStableQueuePublicApiCompatibilityPromise ||
                compatibilityNote.didStateQueuePublicCompatibilityPromiseAbsent == false ||
                compatibilityNote.shouldDeferQueuePublicCompatibilityNote ||
                compatibilityNote.shouldReportQueuePublicCompatibilityNoteBlocked ||
                compatibilityNote.shouldRejectQueuePublicCompatibilityNote ||
                compatibilityNote.shouldReportQueuePublicCompatibilityNoteIncompatible ||
                compatibilityNote.shouldReportQueuePublicCompatibilityNoteUnauthorized
            )
        ) ||
        compatibilityNote.hasStableQueuePublicApiCompatibilityPromise ||
        (compatibilityNote.didStateQueuePublicCompatibilityPromiseAbsent &&
            compatibilityNote.didPrepareQueuePublicCompatibilityNote == false) ||
        (compatibilityNote.didPreserveQueuePublicAuditReference &&
            compatibilityNote.didPrepareQueuePublicCompatibilityNote == false) ||
        (compatibilityNote.didPreserveQueuePublicAuditReference == false &&
            compatibilityNote.didPrepareQueuePublicCompatibilityNote) ||
        (compatibilityNote.didPreserveQueuePublicPermissionAndRollbackLinkage &&
            compatibilityNote.didPrepareQueuePublicCompatibilityNote == false) ||
        (compatibilityNote.didPreserveQueuePublicPermissionAndRollbackLinkage == false &&
            compatibilityNote.didPrepareQueuePublicCompatibilityNote) ||
        (compatibilityNote.didPreservePreviousQueueStoreSnapshot == false) ||
        (
            compatibilityNote.shouldDeferQueuePublicCompatibilityNote &&
            (
                compatibilityNote.shouldReportQueuePublicCompatibilityNoteBlocked ||
                compatibilityNote.shouldRejectQueuePublicCompatibilityNote ||
                compatibilityNote.shouldReportQueuePublicCompatibilityNoteIncompatible ||
                compatibilityNote.shouldReportQueuePublicCompatibilityNoteUnauthorized
            )
        )

    // compatibility note 不一致时必须 fail-closed，不能伪造 API shell ready。
    if (
        compatibilityNote.shouldReportQueuePublicCompatibilityNoteBlocked ||
        compatibilityNote.shouldRejectQueuePublicCompatibilityNote ||
        compatibilityNote.shouldReportQueuePublicCompatibilityNoteIncompatible ||
        compatibilityNote.shouldReportQueuePublicCompatibilityNoteUnauthorized ||
        noteInconsistent
    ) {
        return CjguiInternalQueuePublicApiShell(
            compatibilityNote,
            false,
            false,
            false,
            false,
            true,
            true,
            compatibilityNote.shouldReportQueuePublicCompatibilityNoteIncompatible || noteInconsistent,
            compatibilityNote.shouldReportQueuePublicCompatibilityNoteUnauthorized,
            false,
            false,
            false,
            compatibilityNote.didPreservePreviousQueueStoreSnapshot
        )
    }

    if (noteReady) {
        // 当前仍不承诺 stable 公开 API 兼容性；shell 只是 internal-only value facts。
        return CjguiInternalQueuePublicApiShell(
            compatibilityNote,
            true,
            true,
            false,
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

    if (noteDeferred) {
        return CjguiInternalQueuePublicApiShell(
            compatibilityNote,
            false,
            false,
            false,
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

    return CjguiInternalQueuePublicApiShell(
        compatibilityNote,
        false,
        false,
        false,
        false,
        true,
        true,
        true,
        false,
        false,
        false,
        false,
        compatibilityNote.didPreservePreviousQueueStoreSnapshot
    )
}

func cjguiInternalBuildQueuePublicSubmissionEntry(
    shell: CjguiInternalQueuePublicApiShell
): CjguiInternalQueuePublicSubmissionEntry {
    let shellReady = shell.didPrepareQueuePublicApiShell &&
        shell.didKeepQueuePublicApiShellInternalOnly &&
        shell.hasStableQueuePublicApiCompatibilityPromise == false &&
        shell.didPreserveQueuePublicCompatibilityNote &&
        shell.didPreserveQueuePublicResultEnvelopeHandoff &&
        shell.didPreserveQueuePublicPermissionAndRollbackLinkage &&
        shell.didPreservePreviousQueueStoreSnapshot &&
        shell.shouldDeferQueuePublicApiShell == false &&
        shell.shouldReportQueuePublicApiShellBlocked == false &&
        shell.shouldRejectQueuePublicApiShell == false &&
        shell.shouldReportQueuePublicApiShellIncompatible == false &&
        shell.shouldReportQueuePublicApiShellUnauthorized == false
    let shellDeferred = shell.didPrepareQueuePublicApiShell == false &&
        shell.didKeepQueuePublicApiShellInternalOnly == false &&
        shell.hasStableQueuePublicApiCompatibilityPromise == false &&
        shell.didPreserveQueuePublicCompatibilityNote == false &&
        shell.didPreserveQueuePublicResultEnvelopeHandoff == false &&
        shell.didPreserveQueuePublicPermissionAndRollbackLinkage == false &&
        shell.didPreservePreviousQueueStoreSnapshot &&
        shell.shouldDeferQueuePublicApiShell &&
        shell.shouldReportQueuePublicApiShellBlocked == false &&
        shell.shouldRejectQueuePublicApiShell == false &&
        shell.shouldReportQueuePublicApiShellIncompatible == false &&
        shell.shouldReportQueuePublicApiShellUnauthorized == false
    let shellInconsistent = (
        shell.didPrepareQueuePublicApiShell &&
            (
                shell.didKeepQueuePublicApiShellInternalOnly == false ||
                shell.hasStableQueuePublicApiCompatibilityPromise ||
                shell.shouldDeferQueuePublicApiShell ||
                shell.shouldReportQueuePublicApiShellBlocked ||
                shell.shouldRejectQueuePublicApiShell ||
                shell.shouldReportQueuePublicApiShellIncompatible ||
                shell.shouldReportQueuePublicApiShellUnauthorized
            )
        ) ||
        shell.hasStableQueuePublicApiCompatibilityPromise ||
        (shell.didKeepQueuePublicApiShellInternalOnly &&
            shell.didPrepareQueuePublicApiShell == false) ||
        (shell.didPreserveQueuePublicCompatibilityNote &&
            shell.didPrepareQueuePublicApiShell == false) ||
        (shell.didPreserveQueuePublicResultEnvelopeHandoff &&
            shell.didPrepareQueuePublicApiShell == false) ||
        (shell.didPreserveQueuePublicPermissionAndRollbackLinkage &&
            shell.didPrepareQueuePublicApiShell == false) ||
        (shell.didPreserveQueuePublicPermissionAndRollbackLinkage == false &&
            shell.didPrepareQueuePublicApiShell) ||
        (shell.didPreservePreviousQueueStoreSnapshot == false) ||
        (
            shell.shouldDeferQueuePublicApiShell &&
            (
                shell.shouldReportQueuePublicApiShellBlocked ||
                shell.shouldRejectQueuePublicApiShell ||
                shell.shouldReportQueuePublicApiShellIncompatible ||
                shell.shouldReportQueuePublicApiShellUnauthorized
            )
        )

    // API shell 不一致时必须 fail-closed，submission entry 不能绕过 internal-only shell。
    if (
        shell.shouldReportQueuePublicApiShellBlocked ||
        shell.shouldRejectQueuePublicApiShell ||
        shell.shouldReportQueuePublicApiShellIncompatible ||
        shell.shouldReportQueuePublicApiShellUnauthorized ||
        shellInconsistent
    ) {
        return CjguiInternalQueuePublicSubmissionEntry(
            shell,
            false,
            false,
            true,
            false,
            true,
            true,
            shell.shouldReportQueuePublicApiShellIncompatible || shellInconsistent,
            shell.shouldReportQueuePublicApiShellUnauthorized,
            false,
            false,
            false,
            shell.didPreservePreviousQueueStoreSnapshot
        )
    }

    if (shellReady) {
        return CjguiInternalQueuePublicSubmissionEntry(
            shell,
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

    if (shellDeferred) {
        return CjguiInternalQueuePublicSubmissionEntry(
            shell,
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
            false,
            true
        )
    }

    return CjguiInternalQueuePublicSubmissionEntry(
        shell,
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
        false,
        shell.didPreservePreviousQueueStoreSnapshot
    )
}

func cjguiInternalBuildQueuePublicEntryResult(
    entry: CjguiInternalQueuePublicSubmissionEntry
): CjguiInternalQueuePublicEntryResult {
    let entryReady = entry.didPrepareQueuePublicSubmissionEntry &&
        entry.didUseQueuePublicSubmissionEntryTerminology &&
        entry.didAvoidStableQueuePublicApiCompatibilityPromise &&
        entry.didPreserveQueuePublicApiShell &&
        entry.didPreserveQueuePublicResultEnvelopeHandoff &&
        entry.didPreserveQueuePublicPermissionAndRollbackLinkage &&
        entry.didPreservePreviousQueueStoreSnapshot &&
        entry.shouldDeferQueuePublicSubmissionEntry == false &&
        entry.shouldReportQueuePublicSubmissionEntryBlocked == false &&
        entry.shouldRejectQueuePublicSubmissionEntry == false &&
        entry.shouldReportQueuePublicSubmissionEntryIncompatible == false &&
        entry.shouldReportQueuePublicSubmissionEntryUnauthorized == false
    let entryDeferred = entry.didPrepareQueuePublicSubmissionEntry == false &&
        entry.didUseQueuePublicSubmissionEntryTerminology == false &&
        entry.didPreserveQueuePublicApiShell == false &&
        entry.didPreserveQueuePublicResultEnvelopeHandoff == false &&
        entry.didPreserveQueuePublicPermissionAndRollbackLinkage == false &&
        entry.didPreservePreviousQueueStoreSnapshot &&
        entry.shouldDeferQueuePublicSubmissionEntry &&
        entry.shouldReportQueuePublicSubmissionEntryBlocked == false &&
        entry.shouldRejectQueuePublicSubmissionEntry == false &&
        entry.shouldReportQueuePublicSubmissionEntryIncompatible == false &&
        entry.shouldReportQueuePublicSubmissionEntryUnauthorized == false
    let entryInconsistent = (
        entry.didPrepareQueuePublicSubmissionEntry &&
            (
                entry.didUseQueuePublicSubmissionEntryTerminology == false ||
                entry.didAvoidStableQueuePublicApiCompatibilityPromise == false ||
                entry.shouldDeferQueuePublicSubmissionEntry ||
                entry.shouldReportQueuePublicSubmissionEntryBlocked ||
                entry.shouldRejectQueuePublicSubmissionEntry ||
                entry.shouldReportQueuePublicSubmissionEntryIncompatible ||
                entry.shouldReportQueuePublicSubmissionEntryUnauthorized
            )
        ) ||
        (entry.didAvoidStableQueuePublicApiCompatibilityPromise == false) ||
        (entry.didUseQueuePublicSubmissionEntryTerminology &&
            entry.didPrepareQueuePublicSubmissionEntry == false) ||
        (entry.didPreserveQueuePublicApiShell &&
            entry.didPrepareQueuePublicSubmissionEntry == false) ||
        (entry.didPreserveQueuePublicResultEnvelopeHandoff &&
            entry.didPrepareQueuePublicSubmissionEntry == false) ||
        (entry.didPreserveQueuePublicPermissionAndRollbackLinkage &&
            entry.didPrepareQueuePublicSubmissionEntry == false) ||
        (entry.didPreserveQueuePublicPermissionAndRollbackLinkage == false &&
            entry.didPrepareQueuePublicSubmissionEntry) ||
        (entry.didPreservePreviousQueueStoreSnapshot == false) ||
        (
            entry.shouldDeferQueuePublicSubmissionEntry &&
            (
                entry.shouldReportQueuePublicSubmissionEntryBlocked ||
                entry.shouldRejectQueuePublicSubmissionEntry ||
                entry.shouldReportQueuePublicSubmissionEntryIncompatible ||
                entry.shouldReportQueuePublicSubmissionEntryUnauthorized
            )
        )

    // submission entry 不一致时必须 fail-closed，entry result 不能暴露 lower-level owner facts。
    if (
        entry.shouldReportQueuePublicSubmissionEntryBlocked ||
        entry.shouldRejectQueuePublicSubmissionEntry ||
        entry.shouldReportQueuePublicSubmissionEntryIncompatible ||
        entry.shouldReportQueuePublicSubmissionEntryUnauthorized ||
        entryInconsistent
    ) {
        return CjguiInternalQueuePublicEntryResult(
            entry,
            false,
            false,
            false,
            false,
            true,
            true,
            false,
            true,
            true,
            entry.shouldReportQueuePublicSubmissionEntryIncompatible || entryInconsistent,
            entry.shouldReportQueuePublicSubmissionEntryUnauthorized,
            false,
            false,
            entry.didPreservePreviousQueueStoreSnapshot
        )
    }

    if (entryReady) {
        return CjguiInternalQueuePublicEntryResult(
            entry,
            true,
            true,
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

    if (entryDeferred) {
        return CjguiInternalQueuePublicEntryResult(
            entry,
            false,
            false,
            false,
            false,
            false,
            false,
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

    return CjguiInternalQueuePublicEntryResult(
        entry,
        false,
        false,
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
        entry.didPreservePreviousQueueStoreSnapshot
    )
}

func cjguiInternalBuildQueuePublicEntryResultHandoff(
    result: CjguiInternalQueuePublicEntryResult
): CjguiInternalQueuePublicEntryResultHandoff {
    let resultReady = result.didPrepareQueuePublicEntryResult &&
        result.didProjectQueuePublicResultEnvelope &&
        result.didProjectQueuePublicErrorProjection &&
        result.didProjectQueuePublicAuditReference &&
        result.didProjectQueuePublicCompatibilityNote &&
        result.didAvoidLowerLevelQueueOwnerFactExposure &&
        result.didPreserveQueuePublicSubmissionEntry &&
        result.didPreserveQueuePublicPermissionAndRollbackLinkage &&
        result.didPreservePreviousQueueStoreSnapshot &&
        result.shouldDeferQueuePublicEntryResult == false &&
        result.shouldReportQueuePublicEntryResultBlocked == false &&
        result.shouldRejectQueuePublicEntryResult == false &&
        result.shouldReportQueuePublicEntryResultIncompatible == false &&
        result.shouldReportQueuePublicEntryResultUnauthorized == false
    let resultDeferred = result.didPrepareQueuePublicEntryResult == false &&
        result.didProjectQueuePublicResultEnvelope == false &&
        result.didProjectQueuePublicErrorProjection == false &&
        result.didProjectQueuePublicAuditReference == false &&
        result.didPreserveQueuePublicSubmissionEntry == false &&
        result.didPreserveQueuePublicPermissionAndRollbackLinkage == false &&
        result.didPreservePreviousQueueStoreSnapshot &&
        result.shouldDeferQueuePublicEntryResult &&
        result.shouldReportQueuePublicEntryResultBlocked == false &&
        result.shouldRejectQueuePublicEntryResult == false &&
        result.shouldReportQueuePublicEntryResultIncompatible == false &&
        result.shouldReportQueuePublicEntryResultUnauthorized == false
    let resultInconsistent = (
        result.didPrepareQueuePublicEntryResult &&
            (
                result.didProjectQueuePublicResultEnvelope == false ||
                result.didProjectQueuePublicErrorProjection == false ||
                result.didProjectQueuePublicAuditReference == false ||
                result.didProjectQueuePublicCompatibilityNote == false ||
                result.didAvoidLowerLevelQueueOwnerFactExposure == false ||
                result.shouldDeferQueuePublicEntryResult ||
                result.shouldReportQueuePublicEntryResultBlocked ||
                result.shouldRejectQueuePublicEntryResult ||
                result.shouldReportQueuePublicEntryResultIncompatible ||
                result.shouldReportQueuePublicEntryResultUnauthorized
            )
        ) ||
        (result.didAvoidLowerLevelQueueOwnerFactExposure == false &&
            result.didPrepareQueuePublicEntryResult) ||
        (result.didPreserveQueuePublicSubmissionEntry &&
            result.didPrepareQueuePublicEntryResult == false) ||
        (result.didPreserveQueuePublicPermissionAndRollbackLinkage &&
            result.didPrepareQueuePublicEntryResult == false) ||
        (result.didPreserveQueuePublicPermissionAndRollbackLinkage == false &&
            result.didPrepareQueuePublicEntryResult) ||
        (result.didPreservePreviousQueueStoreSnapshot == false) ||
        (
            result.shouldDeferQueuePublicEntryResult &&
            (
                result.shouldReportQueuePublicEntryResultBlocked ||
                result.shouldRejectQueuePublicEntryResult ||
                result.shouldReportQueuePublicEntryResultIncompatible ||
                result.shouldReportQueuePublicEntryResultUnauthorized
            )
        )

    // entry result 不一致时必须 fail-closed，handoff 不能伪造 API shell 成功。
    if (
        result.shouldReportQueuePublicEntryResultBlocked ||
        result.shouldRejectQueuePublicEntryResult ||
        result.shouldReportQueuePublicEntryResultIncompatible ||
        result.shouldReportQueuePublicEntryResultUnauthorized ||
        resultInconsistent
    ) {
        return CjguiInternalQueuePublicEntryResultHandoff(
            result,
            false,
            false,
            false,
            true,
            true,
            result.shouldReportQueuePublicEntryResultIncompatible || resultInconsistent,
            result.shouldReportQueuePublicEntryResultUnauthorized,
            false,
            false,
            result.didPreservePreviousQueueStoreSnapshot
        )
    }

    if (resultReady) {
        return CjguiInternalQueuePublicEntryResultHandoff(result, true, true, false, false, false, false, false, true, true, true)
    }

    if (resultDeferred) {
        return CjguiInternalQueuePublicEntryResultHandoff(
            result,
            false,
            false,
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

    return CjguiInternalQueuePublicEntryResultHandoff(
        result,
        false,
        false,
        false,
        true,
        true,
        true,
        false,
        false,
        false,
        result.didPreservePreviousQueueStoreSnapshot
    )
}

func cjguiInternalExecuteDefaultQueuePublicApiShellDraft(): CjguiInternalQueuePublicEntryResultHandoff {
    // 默认 draft 只串联 internal API shell value facts；
    // 不是公开 API / C ABI，也不执行真实入队或写 queue storage。
    let compatibilityNote = cjguiInternalExecuteDefaultQueuePublicResultShapeDraft()
    let shell = cjguiInternalBuildQueuePublicApiShell(compatibilityNote)
    let entry = cjguiInternalBuildQueuePublicSubmissionEntry(shell)
    let result = cjguiInternalBuildQueuePublicEntryResult(entry)
    return cjguiInternalBuildQueuePublicEntryResultHandoff(result)
}

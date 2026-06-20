// 中文维护注释：这是 CJGUI minimal UI framework demo 复用用的 experimental owner-local commit session。
// Scope: 为多个独立 demo 提供同一个 in-memory commit/readback/rollback-boundary value primitive。
// Stop-line: 只保存 demo process-local 状态，不写 runtime_state / renderer_state，不调用 native bridge，不发布 renderer truth。
package cjgui.demo_support

/// Experimental demo support API：表达一次 owner-local commit 后的读回、回滚边界与未发布状态。
public class CjguiExperimentalDemoCommitResult {
    /// 消费该 shared commit primitive 的 demo 名称。
    public let demoName: String
    /// 发起 commit 的 component 标识，只用于 demo-host 读回证据。
    public let componentId: String
    /// 发起 commit 的 action 名称，只用于 demo-host 读回证据。
    public let action: String
    /// commit 前的 owner-local 业务状态。
    public let beforeState: String
    /// commit 后请求写入的 owner-local 业务状态。
    public let afterState: String
    /// commit 后从 session 中读回的 owner-local 业务状态。
    public let readbackState: String
    /// 可回滚到的上一份 owner-local 状态快照；这里只表达边界，不自动发布。
    public let rollbackState: String
    /// 当前 session 已执行的 owner-local commit 次数。
    public let writeCount: Int64
    /// 本次 commit 是否完成 session-local 写入。
    public let committed: Bool
    /// 本次 commit 后 readback 是否等于 afterState。
    public let readbackOk: Bool
    /// 是否保留上一份状态作为 rollback boundary。
    public let rollbackAvailable: Bool
    /// 是否保持未发布到 runtime_state / renderer_state 的边界。
    public let notPublished: Bool
    /// 供 demo verifier 稳定断言的脱水摘要。
    public let summary: String

    public init(
        demoName: String,
        componentId: String,
        action: String,
        beforeState: String,
        afterState: String,
        readbackState: String,
        rollbackState: String,
        writeCount: Int64,
        committed: Bool,
        readbackOk: Bool,
        rollbackAvailable: Bool,
        notPublished: Bool,
        summary: String
    ) {
        this.demoName = demoName
        this.componentId = componentId
        this.action = action
        this.beforeState = beforeState
        this.afterState = afterState
        this.readbackState = readbackState
        this.rollbackState = rollbackState
        this.writeCount = writeCount
        this.committed = committed
        this.readbackOk = readbackOk
        this.rollbackAvailable = rollbackAvailable
        this.notPublished = notPublished
        this.summary = summary
    }
}

/// Experimental demo support API：只在 demo host 内存中提交、读回并保留回滚边界。
public class CjguiExperimentalDemoOwnerLocalCommitSession {
    /// Demo 名称保持 public，方便 verifier/readback 证明哪个 app 消费了 shared commit session。
    public let demoName: String
    private var currentState: String
    private var lastRollbackState: String
    private var writeCount: Int64

    public init(demoName: String, initialState: String) {
        this.demoName = demoName
        this.currentState = initialState
        this.lastRollbackState = initialState
        this.writeCount = 0
    }

    /// 提交一次 demo-host owner-local 状态变更，并返回不发布到 renderer/runtime 的脱水结果。
    public func commitComponentAction(
        componentId: String,
        action: String,
        afterState: String
    ): CjguiExperimentalDemoCommitResult {
        let beforeState = currentState
        lastRollbackState = beforeState
        currentState = afterState
        writeCount += 1
        let readbackState = currentState
        let readbackOk = readbackState == afterState
        let rollbackAvailable = lastRollbackState == beforeState
        let notPublished = true
        let summary = "demo=${demoName};component=${componentId};action=${action};committed=true;readback=${readbackOk};writes=${writeCount};before=${beforeState};after=${afterState};readback_state=${readbackState};rollback_state=${lastRollbackState};not_published=${notPublished}"
        return CjguiExperimentalDemoCommitResult(
            demoName,
            componentId,
            action,
            beforeState,
            afterState,
            readbackState,
            lastRollbackState,
            writeCount,
            true,
            readbackOk,
            rollbackAvailable,
            notPublished,
            summary
        )
    }

    /// 读回 session 当前 owner-local 状态；不读取 renderer/runtime 状态。
    public func readback(): String {
        return currentState
    }

    /// 读回上一份 rollback boundary；不执行真实回滚发布。
    public func rollbackBoundary(): String {
        return lastRollbackState
    }

    /// 返回当前 session-local commit 次数。
    public func writes(): Int64 {
        return writeCount
    }
}

/// Experimental demo support API：组合 owner-local commit session 与通用 result 校验，减少 demo-local wrapper。
public class CjguiExperimentalDemoCommitHarness {
    /// Demo 名称保持 public，方便 verifier 证明多个 demo 消费同一个 shared commit harness。
    public let demoName: String
    let session: CjguiExperimentalDemoOwnerLocalCommitSession

    public init(demoName: String, initialState: String) {
        this.demoName = demoName
        this.session = CjguiExperimentalDemoOwnerLocalCommitSession(demoName, initialState)
    }

    /// 提交一次 demo-host owner-local 状态变更；不发布 renderer/runtime truth。
    public func commitComponentAction(
        componentId: String,
        action: String,
        afterState: String
    ): CjguiExperimentalDemoCommitResult {
        return session.commitComponentAction(componentId, action, afterState)
    }

    /// 用 shared 规则校验 commit result、readback 与 rollback boundary 是否自洽。
    public func resultMatches(
        result: CjguiExperimentalDemoCommitResult,
        componentId: String,
        action: String,
        beforeState: String,
        afterState: String
    ): Bool {
        return result.demoName == demoName &&
            result.componentId == componentId &&
            result.action == action &&
            result.beforeState == beforeState &&
            result.afterState == afterState &&
            result.readbackState == afterState &&
            result.rollbackState == beforeState &&
            result.writeCount == writes() &&
            result.committed &&
            result.readbackOk &&
            result.rollbackAvailable &&
            result.notPublished &&
            readback() == afterState &&
            rollbackBoundary() == beforeState
    }

    /// 读回 session 当前 owner-local 状态；不读取 renderer/runtime 状态。
    public func readback(): String {
        return session.readback()
    }

    /// 读回上一份 rollback boundary；不执行真实回滚发布。
    public func rollbackBoundary(): String {
        return session.rollbackBoundary()
    }

    /// 返回当前 session-local commit 次数。
    public func writes(): Int64 {
        return session.writes()
    }
}

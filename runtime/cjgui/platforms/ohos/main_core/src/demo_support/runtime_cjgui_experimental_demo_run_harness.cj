// 中文维护注释：这是 CJGUI minimal UI framework demo 复用用的 experimental demo run harness。
// Scope: 为多个独立 demo 提供同一个 run/result value primitive，汇总 before/after/readback/commit 边界。
// Stop-line: 只构造 demo process-local 脱水事实，不写 runtime_state / renderer_state，不调用 native bridge，不扩 public C ABI。
package cjgui.demo_support

/// Experimental demo support API：表达一次 demo-host run 的 before/after、readback 与未发布边界。
public class CjguiExperimentalDemoRunResult {
    /// 消费 shared run harness 的 demo 名称。
    public let demoName: String
    /// Demo 在本次 run 前的进度状态。
    public let statusBefore: String
    /// Demo 在本次 run 后的进度状态。
    public let statusAfter: String
    /// Demo 业务状态的 before snapshot。
    public let beforeState: String
    /// Demo 业务状态的 after snapshot。
    public let afterState: String
    /// Shared component/action session 捕获的 action trace。
    public let actionTrace: String
    /// Shared component/action session 捕获的 component action facts。
    public let componentActionSummary: String
    /// Shared UI state core 的 layout/style/input/focus facts。
    public let uiStateSummary: String
    /// Demo 业务域摘要。
    public let domainSummary: String
    /// Shared commit harness 的脱水摘要。
    public let commitSummary: String
    /// Shared component/action session 捕获的 owner-local action write 次数。
    public let actionWriteCount: Int64
    /// Shared output readback 是否通过。
    public let readbackOk: Bool
    /// Shared commit result/readback/rollback boundary 是否通过。
    public let commitReadbackOk: Bool
    /// 是否保持不发布到 runtime_state / renderer_state。
    public let notPublished: Bool
    /// 本次 run 是否满足 runnable demo 的共享证据合同。
    public let runnable: Bool
    /// 供 demo verifier 稳定断言的脱水摘要。
    public let summary: String

    public init(
        demoName: String,
        statusBefore: String,
        statusAfter: String,
        beforeState: String,
        afterState: String,
        actionTrace: String,
        componentActionSummary: String,
        uiStateSummary: String,
        domainSummary: String,
        commitSummary: String,
        actionWriteCount: Int64,
        readbackOk: Bool,
        commitReadbackOk: Bool,
        notPublished: Bool,
        runnable: Bool,
        summary: String
    ) {
        this.demoName = demoName
        this.statusBefore = statusBefore
        this.statusAfter = statusAfter
        this.beforeState = beforeState
        this.afterState = afterState
        this.actionTrace = actionTrace
        this.componentActionSummary = componentActionSummary
        this.uiStateSummary = uiStateSummary
        this.domainSummary = domainSummary
        this.commitSummary = commitSummary
        this.actionWriteCount = actionWriteCount
        this.readbackOk = readbackOk
        this.commitReadbackOk = commitReadbackOk
        this.notPublished = notPublished
        this.runnable = runnable
        this.summary = summary
    }
}

/// Experimental demo support API：把 demo output 与 commit result 汇总成可复用 run result。
public class CjguiExperimentalDemoRunHarness {
    /// Demo 名称保持 public，方便 verifier 证明多个 demo 消费同一个 shared run harness。
    public let demoName: String

    public init(demoName: String) {
        this.demoName = demoName
    }

    /// 完成一次 demo-host run 汇总；不启动进程、不发布 renderer/runtime truth。
    public func finishRun(
        statusBefore: String,
        statusAfter: String,
        output: CjguiExperimentalDemoOutput,
        componentActionSummary: String,
        uiStateSummary: String,
        commitResult: CjguiExperimentalDemoCommitResult,
        commitReadbackOk: Bool
    ): CjguiExperimentalDemoRunResult {
        let sameDemo = output.demoName == demoName && commitResult.demoName == demoName
        let notPublished = commitResult.notPublished
        let runnable = sameDemo &&
            statusAfter == "runnable" &&
            output.readbackOk &&
            commitResult.readbackOk &&
            commitReadbackOk &&
            notPublished
        let summary = "demo=${demoName};status=${statusBefore}->${statusAfter};readback=${output.readbackOk};commit_readback=${commitReadbackOk};not_published=${notPublished};writes=${output.writeCount};actions=${output.actionTrace};before=${output.beforeState};after=${output.afterState};domain=${output.domainSummary}"
        return CjguiExperimentalDemoRunResult(
            demoName,
            statusBefore,
            statusAfter,
            output.beforeState,
            output.afterState,
            output.actionTrace,
            componentActionSummary,
            uiStateSummary,
            output.domainSummary,
            commitResult.summary,
            output.writeCount,
            output.readbackOk,
            commitReadbackOk,
            notPublished,
            runnable,
            summary
        )
    }

    /// 用 shared component/action session 直接完成 run 汇总，避免每个 demo 重复包装 component/ui facts。
    public func finishCommittedSessionRun(
        statusBefore: String,
        statusAfter: String,
        output: CjguiExperimentalDemoOutput,
        componentSession: CjguiExperimentalDemoComponentActionSession,
        commitResult: CjguiExperimentalDemoCommitResult,
        commitReadbackOk: Bool
    ): CjguiExperimentalDemoRunResult {
        return finishRun(
            statusBefore,
            statusAfter,
            output,
            componentSession.componentActionSummary(),
            componentSession.uiStateSummary(),
            commitResult,
            commitReadbackOk
        )
    }
}

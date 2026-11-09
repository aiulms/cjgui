// 中文维护注释：这是 CJGUI minimal UI framework demo 复用用的 experimental output builder。
// Scope: 为多个独立 demo 提供同一个 before/after/action/readback output model，减少 per-demo output API 重复。
// Stop-line: 只构造 demo process-local value facts，不写 runtime_state / renderer_state，不扩 public C ABI。
package cjgui.demo_support

public class CjguiExperimentalDemoOutput {
    public let demoName: String
    public let beforeState: String
    public let afterState: String
    public let actionTrace: String
    public let writeCount: Int64
    public let domainSummary: String
    public let readbackOk: Bool
    public let summary: String

    public init(
        demoName: String,
        beforeState: String,
        afterState: String,
        actionTrace: String,
        writeCount: Int64,
        domainSummary: String,
        readbackOk: Bool,
        summary: String
    ) {
        this.demoName = demoName
        this.beforeState = beforeState
        this.afterState = afterState
        this.actionTrace = actionTrace
        this.writeCount = writeCount
        this.domainSummary = domainSummary
        this.readbackOk = readbackOk
        this.summary = summary
    }
}

public class CjguiExperimentalDemoOutputBuilder {
    public init() {}

    public func buildFromTrace(
        trace: CjguiExperimentalDemoInteractionTrace,
        domainSummary: String,
        readbackOk: Bool
    ): CjguiExperimentalDemoOutput {
        let summary = "demo=${trace.demoName};readback=${readbackOk};writes=${trace.writes()};actions=${trace.actions()};before=${trace.before()};after=${trace.after()};summary=${domainSummary}"
        return CjguiExperimentalDemoOutput(
            trace.demoName,
            trace.before(),
            trace.after(),
            trace.actions(),
            trace.writes(),
            domainSummary,
            readbackOk,
            summary
        )
    }
}

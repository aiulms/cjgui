// 中文维护注释：这是 CJGUI minimal UI framework 转场用的 experimental shared demo harness API。
// Scope: 暴露非 Bool 的 shared demo harness output 领域类型与构造函数，供独立 harness demo 消费。
// Stop-line: 不调用 internal readiness draft，不写 runtime_state / renderer_state，不扩 public C ABI。
package cjgui

public class CjguiExperimentalSharedDemoHarnessOutput {
    public let harnessName: String
    public let servedDemo: String
    public let actionCount: Int64
    public let beforeState: String
    public let afterState: String
    public let interactionTrace: String
    public let focusTarget: String
    public let styleToken: String
    public let readbackOk: Bool
    public let summary: String

    public init(
        harnessName: String,
        servedDemo: String,
        actionCount: Int64,
        beforeState: String,
        afterState: String,
        interactionTrace: String,
        focusTarget: String,
        styleToken: String,
        readbackOk: Bool,
        summary: String
    ) {
        this.harnessName = harnessName
        this.servedDemo = servedDemo
        this.actionCount = actionCount
        this.beforeState = beforeState
        this.afterState = afterState
        this.interactionTrace = interactionTrace
        this.focusTarget = focusTarget
        this.styleToken = styleToken
        this.readbackOk = readbackOk
        this.summary = summary
    }
}

// 这是 experimental public API，不是 readiness projection。
// 它只把 shared demo harness 的业务运行结果脱水成领域输出对象，不写全局状态。
public func cjguiExperimentalBuildSharedDemoHarnessOutput(
    servedDemo: String,
    actionCount: Int64,
    beforeState: String,
    afterState: String,
    interactionTrace: String,
    focusTarget: String,
    styleToken: String,
    readbackOk: Bool
): CjguiExperimentalSharedDemoHarnessOutput {
    let summary = "harness=shared_demo_harness;served=${servedDemo};actions=${actionCount};before=${beforeState};after=${afterState};interaction=${interactionTrace};focus=${focusTarget};style=${styleToken};readback=${readbackOk}"
    return CjguiExperimentalSharedDemoHarnessOutput(
        "shared_demo_harness",
        servedDemo,
        actionCount,
        beforeState,
        afterState,
        interactionTrace,
        focusTarget,
        styleToken,
        readbackOk,
        summary
    )
}

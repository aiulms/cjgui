// 中文维护注释：这是 CJGUI minimal UI framework 转场用的 experimental shared multi-demo harness API。
// Scope: 暴露非 Bool 的 multi-demo harness output 领域类型与构造函数，供独立 harness demo 消费。
// Stop-line: 不调用 internal readiness draft，不写 runtime_state / renderer_state，不扩 public C ABI。
package cjgui

public class CjguiExperimentalSharedMultiDemoHarnessOutput {
    public let harnessName: String
    public let servedDemoCount: Int64
    public let servedDemos: String
    public let actionCount: Int64
    public let beforeState: String
    public let afterState: String
    public let interactionTrace: String
    public let focusRoute: String
    public let styleRoute: String
    public let readbackOk: Bool
    public let summary: String

    public init(
        harnessName: String,
        servedDemoCount: Int64,
        servedDemos: String,
        actionCount: Int64,
        beforeState: String,
        afterState: String,
        interactionTrace: String,
        focusRoute: String,
        styleRoute: String,
        readbackOk: Bool,
        summary: String
    ) {
        this.harnessName = harnessName
        this.servedDemoCount = servedDemoCount
        this.servedDemos = servedDemos
        this.actionCount = actionCount
        this.beforeState = beforeState
        this.afterState = afterState
        this.interactionTrace = interactionTrace
        this.focusRoute = focusRoute
        this.styleRoute = styleRoute
        this.readbackOk = readbackOk
        this.summary = summary
    }
}

// 这是 experimental public API，不是 readiness projection。
// 它只把 shared multi-demo harness 的业务运行结果脱水成领域输出对象，不写全局状态。
public func cjguiExperimentalBuildSharedMultiDemoHarnessOutput(
    servedDemoCount: Int64,
    servedDemos: String,
    actionCount: Int64,
    beforeState: String,
    afterState: String,
    interactionTrace: String,
    focusRoute: String,
    styleRoute: String,
    readbackOk: Bool
): CjguiExperimentalSharedMultiDemoHarnessOutput {
    let summary = "harness=shared_multi_demo_harness;served_count=${servedDemoCount};served=${servedDemos};actions=${actionCount};before=${beforeState};after=${afterState};interaction=${interactionTrace};focus_route=${focusRoute};style_route=${styleRoute};readback=${readbackOk}"
    return CjguiExperimentalSharedMultiDemoHarnessOutput(
        "shared_multi_demo_harness",
        servedDemoCount,
        servedDemos,
        actionCount,
        beforeState,
        afterState,
        interactionTrace,
        focusRoute,
        styleRoute,
        readbackOk,
        summary
    )
}

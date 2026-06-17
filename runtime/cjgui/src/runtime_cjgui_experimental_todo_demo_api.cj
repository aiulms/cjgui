// 中文维护注释：这是 CJGUI minimal UI framework 转场用的 experimental Todo demo API。
// Scope: 暴露非 Bool 的 demo output 领域类型与构造函数，供独立 Todo demo 消费。
// Stop-line: 不调用 internal readiness draft，不写 runtime_state / renderer_state，不扩 public C ABI。
package cjgui

public class CjguiExperimentalTodoDemoOutput {
    public let demoName: String
    public let itemCount: Int64
    public let completedCount: Int64
    public let firstTitle: String
    public let firstDone: Bool
    public let summary: String

    public init(
        demoName: String,
        itemCount: Int64,
        completedCount: Int64,
        firstTitle: String,
        firstDone: Bool,
        summary: String
    ) {
        this.demoName = demoName
        this.itemCount = itemCount
        this.completedCount = completedCount
        this.firstTitle = firstTitle
        this.firstDone = firstDone
        this.summary = summary
    }
}

// 这是 experimental public API，不是 readiness projection。
// 它只把 demo state 输入脱水成领域输出对象，不提交 owner acceptance，不写全局状态。
public func cjguiExperimentalBuildTodoDemoOutput(
    firstTitle: String,
    firstDone: Bool
): CjguiExperimentalTodoDemoOutput {
    let completedCount = if (firstDone) { 1 } else { 0 }
    let summary = "items=1;first=${firstTitle};first_done=${firstDone}"
    return CjguiExperimentalTodoDemoOutput(
        "todo",
        1,
        completedCount,
        firstTitle,
        firstDone,
        summary
    )
}

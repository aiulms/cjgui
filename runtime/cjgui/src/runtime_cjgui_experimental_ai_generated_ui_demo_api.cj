// 中文维护注释：这是 CJGUI minimal UI framework 转场用的 experimental AI-generated UI demo API。
// Scope: 暴露非 Bool 的 AI-generated UI demo output 领域类型与构造函数，供独立 AI-generated UI demo 消费。
// Stop-line: 不调用 internal readiness draft，不写 runtime_state / renderer_state，不扩 public C ABI。
package cjgui

public class CjguiExperimentalAiGeneratedUiDemoOutput {
    public let demoName: String
    public let componentCount: Int64
    public let accepted: Bool
    public let acceptedScreen: String
    public let diffSummary: String
    public let explainText: String
    public let focusTarget: String
    public let layoutKind: String
    public let styleToken: String
    public let summary: String

    public init(
        demoName: String,
        componentCount: Int64,
        accepted: Bool,
        acceptedScreen: String,
        diffSummary: String,
        explainText: String,
        focusTarget: String,
        layoutKind: String,
        styleToken: String,
        summary: String
    ) {
        this.demoName = demoName
        this.componentCount = componentCount
        this.accepted = accepted
        this.acceptedScreen = acceptedScreen
        this.diffSummary = diffSummary
        this.explainText = explainText
        this.focusTarget = focusTarget
        this.layoutKind = layoutKind
        this.styleToken = styleToken
        this.summary = summary
    }
}

// 这是 experimental public API，不是 readiness projection。
// 它只把 AI-generated UI demo 输入脱水成领域输出对象，不调度 Action，不提交 renderer。
public func cjguiExperimentalBuildAiGeneratedUiDemoOutput(
    componentCount: Int64,
    accepted: Bool,
    acceptedScreen: String,
    diffSummary: String,
    explainText: String,
    focusTarget: String,
    layoutKind: String,
    styleToken: String
): CjguiExperimentalAiGeneratedUiDemoOutput {
    let summary = "components=${componentCount};accepted=${accepted};screen=${acceptedScreen};diff=${diffSummary};explain=${explainText};focus=${focusTarget};layout=${layoutKind};style=${styleToken}"
    return CjguiExperimentalAiGeneratedUiDemoOutput(
        "ai_generated_ui",
        componentCount,
        accepted,
        acceptedScreen,
        diffSummary,
        explainText,
        focusTarget,
        layoutKind,
        styleToken,
        summary
    )
}

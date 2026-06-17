// 中文维护注释：这是 CJGUI minimal UI framework 转场用的 experimental Chat demo API。
// Scope: 暴露非 Bool 的 chat demo output 领域类型与构造函数，供独立 Chat demo 消费。
// Stop-line: 不调用 internal readiness draft，不写 runtime_state / renderer_state，不扩 public C ABI。
package cjgui

public class CjguiExperimentalChatDemoOutput {
    public let demoName: String
    public let messageCount: Int64
    public let lastSender: String
    public let lastText: String
    public let composerText: String
    public let focusTarget: String
    public let layoutKind: String
    public let summary: String

    public init(
        demoName: String,
        messageCount: Int64,
        lastSender: String,
        lastText: String,
        composerText: String,
        focusTarget: String,
        layoutKind: String,
        summary: String
    ) {
        this.demoName = demoName
        this.messageCount = messageCount
        this.lastSender = lastSender
        this.lastText = lastText
        this.composerText = composerText
        this.focusTarget = focusTarget
        this.layoutKind = layoutKind
        this.summary = summary
    }
}

// 这是 experimental public API，不是 readiness projection。
// 它只把 Chat demo 输入脱水成领域输出对象，不提交 owner acceptance，不写全局状态。
public func cjguiExperimentalBuildChatDemoOutput(
    messageCount: Int64,
    lastSender: String,
    lastText: String,
    composerText: String,
    focusTarget: String,
    layoutKind: String
): CjguiExperimentalChatDemoOutput {
    let summary = "messages=${messageCount};last=${lastSender}:${lastText};composer=${composerText};focus=${focusTarget};layout=${layoutKind}"
    return CjguiExperimentalChatDemoOutput(
        "chat",
        messageCount,
        lastSender,
        lastText,
        composerText,
        focusTarget,
        layoutKind,
        summary
    )
}

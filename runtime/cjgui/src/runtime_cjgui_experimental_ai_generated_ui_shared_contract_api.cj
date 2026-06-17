// 中文维护注释：这是 CJGUI minimal UI framework 转场用的 experimental AI-generated UI shared contract API。
// Scope: 暴露非 Bool 的 AI-generated UI accept refresh + shared layout/style/input/focus contract integration output。
// Stop-line: 不调用 internal readiness draft，不写 runtime_state / renderer_state，不扩 public C ABI。
package cjgui

public class CjguiExperimentalAiGeneratedUiSharedContractOutput {
    public let contractName: String
    public let acceptedScreen: String
    public let componentCount: Int64
    public let diffSummary: String
    public let explainText: String
    public let layoutBefore: String
    public let layoutAfter: String
    public let styleBefore: String
    public let styleAfter: String
    public let inputBefore: String
    public let inputAfter: String
    public let focusBefore: String
    public let focusAfter: String
    public let aiSummary: String
    public let sharedContractSummary: String
    public let readbackOk: Bool
    public let summary: String

    public init(
        contractName: String,
        acceptedScreen: String,
        componentCount: Int64,
        diffSummary: String,
        explainText: String,
        layoutBefore: String,
        layoutAfter: String,
        styleBefore: String,
        styleAfter: String,
        inputBefore: String,
        inputAfter: String,
        focusBefore: String,
        focusAfter: String,
        aiSummary: String,
        sharedContractSummary: String,
        readbackOk: Bool,
        summary: String
    ) {
        this.contractName = contractName
        this.acceptedScreen = acceptedScreen
        this.componentCount = componentCount
        this.diffSummary = diffSummary
        this.explainText = explainText
        this.layoutBefore = layoutBefore
        this.layoutAfter = layoutAfter
        this.styleBefore = styleBefore
        this.styleAfter = styleAfter
        this.inputBefore = inputBefore
        this.inputAfter = inputAfter
        this.focusBefore = focusBefore
        this.focusAfter = focusAfter
        this.aiSummary = aiSummary
        this.sharedContractSummary = sharedContractSummary
        this.readbackOk = readbackOk
        this.summary = summary
    }
}

// 这是 experimental public API，不是 readiness projection。
// 它只把 AI-generated UI accept refresh 与 shared UI contract readback 脱水成领域输出对象。
public func cjguiExperimentalBuildAiGeneratedUiSharedContractOutput(
    acceptedScreen: String,
    componentCount: Int64,
    diffSummary: String,
    explainText: String,
    layoutBefore: String,
    layoutAfter: String,
    styleBefore: String,
    styleAfter: String,
    inputBefore: String,
    inputAfter: String,
    focusBefore: String,
    focusAfter: String,
    aiSummary: String,
    sharedContractSummary: String,
    readbackOk: Bool
): CjguiExperimentalAiGeneratedUiSharedContractOutput {
    let summary = "contract=ai_generated_ui_shared_contract;screen=${acceptedScreen};components=${componentCount};diff=${diffSummary};explain=${explainText};layout=${layoutBefore}->${layoutAfter};style=${styleBefore}->${styleAfter};input=${inputBefore}->${inputAfter};focus=${focusBefore}->${focusAfter};ai_summary=${aiSummary};shared_contract=${sharedContractSummary};readback=${readbackOk}"
    return CjguiExperimentalAiGeneratedUiSharedContractOutput(
        "ai_generated_ui_shared_contract",
        acceptedScreen,
        componentCount,
        diffSummary,
        explainText,
        layoutBefore,
        layoutAfter,
        styleBefore,
        styleAfter,
        inputBefore,
        inputAfter,
        focusBefore,
        focusAfter,
        aiSummary,
        sharedContractSummary,
        readbackOk,
        summary
    )
}

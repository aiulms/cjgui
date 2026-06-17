// 中文维护注释：这是 CJGUI minimal UI framework 转场用的 experimental shared layout/style/input/focus contract API。
// Scope: 暴露非 Bool 的 layout/style/input/focus contract output 领域类型与构造函数，供独立 demo 消费。
// Stop-line: 不调用 internal readiness draft，不写 runtime_state / renderer_state，不扩 public C ABI。
package cjgui

public class CjguiExperimentalSharedLayoutStyleInputFocusContractOutput {
    public let contractName: String
    public let layoutBefore: String
    public let layoutAfter: String
    public let styleBefore: String
    public let styleAfter: String
    public let inputBefore: String
    public let inputAfter: String
    public let focusBefore: String
    public let focusAfter: String
    public let interactionTrace: String
    public let readbackOk: Bool
    public let summary: String

    public init(
        contractName: String,
        layoutBefore: String,
        layoutAfter: String,
        styleBefore: String,
        styleAfter: String,
        inputBefore: String,
        inputAfter: String,
        focusBefore: String,
        focusAfter: String,
        interactionTrace: String,
        readbackOk: Bool,
        summary: String
    ) {
        this.contractName = contractName
        this.layoutBefore = layoutBefore
        this.layoutAfter = layoutAfter
        this.styleBefore = styleBefore
        this.styleAfter = styleAfter
        this.inputBefore = inputBefore
        this.inputAfter = inputAfter
        this.focusBefore = focusBefore
        this.focusAfter = focusAfter
        this.interactionTrace = interactionTrace
        this.readbackOk = readbackOk
        this.summary = summary
    }
}

// 这是 experimental public API，不是 readiness projection。
// 它只把 shared layout/style/input/focus contract 的业务运行结果脱水成领域输出对象。
public func cjguiExperimentalBuildSharedLayoutStyleInputFocusContractOutput(
    layoutBefore: String,
    layoutAfter: String,
    styleBefore: String,
    styleAfter: String,
    inputBefore: String,
    inputAfter: String,
    focusBefore: String,
    focusAfter: String,
    interactionTrace: String,
    readbackOk: Bool
): CjguiExperimentalSharedLayoutStyleInputFocusContractOutput {
    let summary = "contract=shared_layout_style_input_focus;layout=${layoutBefore}->${layoutAfter};style=${styleBefore}->${styleAfter};input=${inputBefore}->${inputAfter};focus=${focusBefore}->${focusAfter};interaction=${interactionTrace};readback=${readbackOk}"
    return CjguiExperimentalSharedLayoutStyleInputFocusContractOutput(
        "shared_layout_style_input_focus",
        layoutBefore,
        layoutAfter,
        styleBefore,
        styleAfter,
        inputBefore,
        inputAfter,
        focusBefore,
        focusAfter,
        interactionTrace,
        readbackOk,
        summary
    )
}

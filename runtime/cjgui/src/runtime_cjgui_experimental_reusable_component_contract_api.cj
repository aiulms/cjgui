// 中文维护注释：这是 CJGUI minimal UI framework 转场用的 experimental reusable component contract API。
// Scope: 暴露非 Bool 的 reusable component contract output 领域类型与构造函数，供独立 demo 消费。
// Stop-line: 不调用 internal readiness draft，不写 runtime_state / renderer_state，不扩 public C ABI。
package cjgui

public class CjguiExperimentalReusableComponentContractOutput {
    public let contractName: String
    public let componentKinds: String
    public let reusedDemoCount: Int64
    public let reusedDemos: String
    public let componentCount: Int64
    public let beforeState: String
    public let afterState: String
    public let actionTrace: String
    public let layoutBefore: String
    public let layoutAfter: String
    public let styleBefore: String
    public let styleAfter: String
    public let inputBefore: String
    public let inputAfter: String
    public let focusBefore: String
    public let focusAfter: String
    public let readbackOk: Bool
    public let summary: String

    public init(
        contractName: String,
        componentKinds: String,
        reusedDemoCount: Int64,
        reusedDemos: String,
        componentCount: Int64,
        beforeState: String,
        afterState: String,
        actionTrace: String,
        layoutBefore: String,
        layoutAfter: String,
        styleBefore: String,
        styleAfter: String,
        inputBefore: String,
        inputAfter: String,
        focusBefore: String,
        focusAfter: String,
        readbackOk: Bool,
        summary: String
    ) {
        this.contractName = contractName
        this.componentKinds = componentKinds
        this.reusedDemoCount = reusedDemoCount
        this.reusedDemos = reusedDemos
        this.componentCount = componentCount
        this.beforeState = beforeState
        this.afterState = afterState
        this.actionTrace = actionTrace
        this.layoutBefore = layoutBefore
        this.layoutAfter = layoutAfter
        this.styleBefore = styleBefore
        this.styleAfter = styleAfter
        this.inputBefore = inputBefore
        this.inputAfter = inputAfter
        this.focusBefore = focusBefore
        this.focusAfter = focusAfter
        this.readbackOk = readbackOk
        this.summary = summary
    }
}

// 这是 experimental public API，不是 readiness projection。
// 它只把 reusable component contract 的业务运行结果脱水成领域输出对象，不写全局状态。
public func cjguiExperimentalBuildReusableComponentContractOutput(
    componentKinds: String,
    reusedDemoCount: Int64,
    reusedDemos: String,
    componentCount: Int64,
    beforeState: String,
    afterState: String,
    actionTrace: String,
    layoutBefore: String,
    layoutAfter: String,
    styleBefore: String,
    styleAfter: String,
    inputBefore: String,
    inputAfter: String,
    focusBefore: String,
    focusAfter: String,
    readbackOk: Bool
): CjguiExperimentalReusableComponentContractOutput {
    let summary = "contract=reusable_component_contract;components=${componentKinds};reused_count=${reusedDemoCount};reused=${reusedDemos};component_count=${componentCount};before=${beforeState};after=${afterState};actions=${actionTrace};layout=${layoutBefore}->${layoutAfter};style=${styleBefore}->${styleAfter};input=${inputBefore}->${inputAfter};focus=${focusBefore}->${focusAfter};readback=${readbackOk}"
    return CjguiExperimentalReusableComponentContractOutput(
        "reusable_component_contract",
        componentKinds,
        reusedDemoCount,
        reusedDemos,
        componentCount,
        beforeState,
        afterState,
        actionTrace,
        layoutBefore,
        layoutAfter,
        styleBefore,
        styleAfter,
        inputBefore,
        inputAfter,
        focusBefore,
        focusAfter,
        readbackOk,
        summary
    )
}

// 中文维护注释：这是 CJGUI minimal UI framework demo 复用用的 experimental interaction/state evidence value model。
// Scope: 用 typed value 承载 component interaction、state readback 与 owner-local write readback 事实，减少 demo-local 裸字符串模板。
// Stop-line: 只保存 demo process-local 脱水字符串 / Bool，不写 runtime_state / renderer_state，不调用 native bridge，不扩 public C ABI。
package cjgui.demo_support

/// Experimental demo support API：组件交互语义 evidence value。
public class CjguiExperimentalDemoComponentInteractionEvidence {
    /// 交互事实值保持脱水字符串，供现有 stdout evidence 兼容消费。
    public let interaction: String

    public init(interaction: String) {
        this.interaction = interaction
    }

    /// 转换为现有 `interaction` fact value。
    public func interactionValue(): String {
        return interaction
    }
}

/// Experimental demo support API：状态读回语义 evidence value。
public class CjguiExperimentalDemoStateReadbackEvidence {
    /// 状态变更前事实值保持脱水字符串。
    public let stateBefore: String
    /// 状态变更后事实值保持脱水字符串。
    public let stateAfter: String
    /// 读回结果保持 Bool，由 shared builder 脱水为现有 `state_readback` fact。
    public let readbackOk: Bool

    public init(stateBefore: String, stateAfter: String, readbackOk: Bool) {
        this.stateBefore = stateBefore
        this.stateAfter = stateAfter
        this.readbackOk = readbackOk
    }

    /// 转换为现有 `state_before` fact value。
    public func stateBeforeValue(): String {
        return stateBefore
    }

    /// 转换为现有 `state_after` fact value。
    public func stateAfterValue(): String {
        return stateAfter
    }

    /// 转换为现有 `state_readback` fact value。
    public func readbackOkValue(): Bool {
        return readbackOk
    }
}

/// Experimental demo support API：owner-local 写入读回语义 evidence value。
public class CjguiExperimentalDemoOwnerLocalWriteReadbackEvidence {
    /// owner-local 写入前摘要保持脱水字符串。
    public let summaryBefore: String
    /// owner-local add 后摘要保持脱水字符串。
    public let summaryAfterAdd: String
    /// owner-local complete 后摘要保持脱水字符串。
    public let summaryAfterComplete: String
    /// owner-local 读回结果保持 Bool。
    public let readbackOk: Bool

    public init(
        summaryBefore: String,
        summaryAfterAdd: String,
        summaryAfterComplete: String,
        readbackOk: Bool
    ) {
        this.summaryBefore = summaryBefore
        this.summaryAfterAdd = summaryAfterAdd
        this.summaryAfterComplete = summaryAfterComplete
        this.readbackOk = readbackOk
    }

    /// 转换为现有 `summary_before` fact value。
    public func summaryBeforeValue(): String {
        return summaryBefore
    }

    /// 转换为现有 `summary_after_add` fact value。
    public func summaryAfterAddValue(): String {
        return summaryAfterAdd
    }

    /// 转换为现有 `summary_after_complete` fact value。
    public func summaryAfterCompleteValue(): String {
        return summaryAfterComplete
    }

    /// 转换为现有 `owner_local_write_readback` fact value。
    public func readbackOkValue(): Bool {
        return readbackOk
    }
}

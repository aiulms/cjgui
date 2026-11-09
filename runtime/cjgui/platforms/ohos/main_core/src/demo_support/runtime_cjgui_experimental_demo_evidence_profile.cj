// 中文维护注释：这是 CJGUI minimal UI framework demo 复用用的 experimental evidence profile。
// Scope: 用结构化 profile 承载 demo identity、status transition、static facts 与 business facts，减少 demo-local presenter 调用序列。
// Stop-line: 只保存 demo process-local 脱水事实，不写 runtime_state / renderer_state，不调用 native bridge，不扩 public C ABI。
package cjgui.demo_support

import std.collection.*

/// Experimental demo support API：一条字符串 evidence fact。
public class CjguiExperimentalDemoTextEvidenceFact {
    /// Fact 名称保持稳定，供 focused verifier 匹配 stdout evidence。
    public let name: String
    /// Fact 值保持脱水字符串，不携带 runtime/native object。
    public let value: String

    public init(name: String, value: String) {
        this.name = name
        this.value = value
    }
}

/// Experimental demo support API：一条布尔 evidence fact。
public class CjguiExperimentalDemoBoolEvidenceFact {
    /// Fact 名称保持稳定，供 focused verifier 匹配 stdout evidence。
    public let name: String
    /// Fact 值保持脱水布尔值，不携带 runtime/native object。
    public let value: Bool

    public init(name: String, value: Bool) {
        this.name = name
        this.value = value
    }
}

/// Experimental demo support API：可批量渲染的 demo evidence profile。
public class CjguiExperimentalDemoEvidenceProfile {
    /// Demo identity 行中的名称。
    public let demoName: String
    /// Demo run 前状态。
    public let statusBefore: String
    /// Demo run 后状态。
    public let statusAfter: String
    let staticBoolFacts: ArrayList<CjguiExperimentalDemoBoolEvidenceFact>
    let textFacts: ArrayList<CjguiExperimentalDemoTextEvidenceFact>
    let boolFacts: ArrayList<CjguiExperimentalDemoBoolEvidenceFact>

    public init(demoName: String, statusBefore: String, statusAfter: String) {
        this.demoName = demoName
        this.statusBefore = statusBefore
        this.statusAfter = statusAfter
        this.staticBoolFacts = ArrayList<CjguiExperimentalDemoBoolEvidenceFact>()
        this.textFacts = ArrayList<CjguiExperimentalDemoTextEvidenceFact>()
        this.boolFacts = ArrayList<CjguiExperimentalDemoBoolEvidenceFact>()
    }

    /// 追加静态布尔事实，例如 main_declared / deterministic_output。
    public func addStaticBoolFact(name: String, value: Bool) {
        staticBoolFacts.add(CjguiExperimentalDemoBoolEvidenceFact(name, value))
    }

    /// 追加字符串业务事实，例如 state_before / state_after / summary_after。
    public func addTextFact(name: String, value: String) {
        textFacts.add(CjguiExperimentalDemoTextEvidenceFact(name, value))
    }

    /// 追加布尔业务事实，例如 state_readback / owner_local_write_readback。
    public func addBoolFact(name: String, value: Bool) {
        boolFacts.add(CjguiExperimentalDemoBoolEvidenceFact(name, value))
    }

    /// 静态布尔 fact 数量，用于 verifier 证明 batch profile 不是空壳。
    public func staticBoolFactCount(): Int64 {
        return staticBoolFacts.size
    }

    /// 字符串业务 fact 数量，用于 verifier 证明 business fact batching 生效。
    public func textFactCount(): Int64 {
        return textFacts.size
    }

    /// 布尔业务 fact 数量，用于 verifier 证明 readback fact batching 生效。
    public func boolFactCount(): Int64 {
        return boolFacts.size
    }
}

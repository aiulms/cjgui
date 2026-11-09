// 中文维护注释：这是 CJGUI minimal UI framework demo 复用用的 experimental evidence section builder。
// Scope: 把 profile 创建、常见 fact preset 与 typed section 创建下沉到 shared demo_support，减少 demo-local assembly。
// Stop-line: 只持有 demo process-local 脱水事实，不写 runtime_state / renderer_state，不调用 native bridge，不扩 public C ABI。
package cjgui.demo_support

/// Experimental demo support API：统一组装 demo evidence profile 与 typed section。
public class CjguiExperimentalDemoEvidenceSectionBuilder {
    let profile: CjguiExperimentalDemoEvidenceProfile

    public init(demoName: String, statusBefore: String, statusAfter: String) {
        this.profile = CjguiExperimentalDemoEvidenceProfile(demoName, statusBefore, statusAfter)
    }

    /// 追加静态布尔事实，例如 main_declared / deterministic_output。
    public func addStaticBoolFact(name: String, value: Bool) {
        profile.addStaticBoolFact(name, value)
    }

    /// 追加字符串业务事实，例如 state_before / state_after / interaction。
    public func addTextFact(name: String, value: String) {
        profile.addTextFact(name, value)
    }

    /// 追加布尔业务事实，例如 state_readback。
    public func addBoolFact(name: String, value: Bool) {
        profile.addBoolFact(name, value)
    }

    /// 追加交互事实，统一 demo 中高频的 interaction evidence key。
    public func addInteractionFact(value: String) {
        addTextFact("interaction", value)
    }

    /// 追加标准 state_before / state_after / state_readback 事实束。
    public func addStateReadbackFacts(stateBefore: String, stateAfter: String, readbackOk: Bool) {
        addTextFact("state_before", stateBefore)
        addTextFact("state_after", stateAfter)
        addBoolFact("state_readback", readbackOk)
    }

    /// 追加 Todo 风格 owner-local write readback 事实束，保持 before/add/complete/readback 输出顺序。
    public func addOwnerLocalWriteReadbackFacts(
        summaryBefore: String,
        summaryAfterAdd: String,
        summaryAfterComplete: String,
        readbackOk: Bool
    ) {
        addTextFact("summary_before", summaryBefore)
        addTextFact("summary_after_add", summaryAfterAdd)
        addTextFact("summary_after_complete", summaryAfterComplete)
        addBoolFact("owner_local_write_readback", readbackOk)
    }

    /// 追加布局事实，统一 layout evidence key。
    public func addLayoutFact(value: String) {
        addTextFact("layout", value)
    }

    /// 追加控件事实，统一 controls evidence key。
    public func addControlsFact(value: String) {
        addTextFact("controls", value)
    }

    /// 追加单 demo harness 服务事实，统一 served_demo evidence key。
    public func addServedDemoFact(value: String) {
        addTextFact("served_demo", value)
    }

    /// 追加多 demo harness 服务事实束，保持 served_demos / served_demo_count 输出顺序。
    public func addServedDemosFacts(servedDemos: String, servedDemoCount: String) {
        addTextFact("served_demos", servedDemos)
        addTextFact("served_demo_count", servedDemoCount)
    }

    /// 追加可复用组件合同事实束，保持 reused_demos / component_kinds 输出顺序。
    public func addReusableComponentFacts(reusedDemos: String, componentKinds: String) {
        addTextFact("reused_demos", reusedDemos)
        addTextFact("component_kinds", componentKinds)
    }

    /// 追加布局语义 evidence，统一从 typed value 脱水到 layout fact。
    public func addLayoutEvidence(value: CjguiExperimentalDemoLayoutEvidence) {
        addLayoutFact(value.factValue())
    }

    /// 追加控件语义 evidence，统一从 typed value 脱水到 controls fact。
    public func addControlsEvidence(value: CjguiExperimentalDemoControlsEvidence) {
        addControlsFact(value.factValue())
    }

    /// 追加单 demo harness 服务语义 evidence，统一从 typed value 脱水到 served_demo fact。
    public func addServedDemoEvidence(value: CjguiExperimentalDemoServedDemoEvidence) {
        addServedDemoFact(value.servedDemoValue())
    }

    /// 追加多 demo harness 服务语义 evidence，统一从 typed value 脱水到 served_demos fact bundle。
    public func addServedDemosEvidence(value: CjguiExperimentalDemoServedDemosEvidence) {
        addServedDemosFacts(value.servedDemosValue(), value.servedDemoCountValue())
    }

    /// 追加可复用组件语义 evidence，统一从 typed value 脱水到 reuse fact bundle。
    public func addReusableComponentEvidence(value: CjguiExperimentalDemoReusableComponentEvidence) {
        addReusableComponentFacts(value.reusedDemosValue(), value.componentKindsValue())
    }

    /// 追加组件交互语义 evidence，统一从 typed value 脱水到 interaction fact。
    public func addInteractionEvidence(value: CjguiExperimentalDemoComponentInteractionEvidence) {
        addInteractionFact(value.interactionValue())
    }

    /// 追加状态读回语义 evidence，统一从 typed value 脱水到 state readback fact bundle。
    public func addStateReadbackEvidence(value: CjguiExperimentalDemoStateReadbackEvidence) {
        addStateReadbackFacts(value.stateBeforeValue(), value.stateAfterValue(), value.readbackOkValue())
    }

    /// 追加 owner-local 写入读回语义 evidence，统一从 typed value 脱水到 write readback fact bundle。
    public func addOwnerLocalWriteReadbackEvidence(value: CjguiExperimentalDemoOwnerLocalWriteReadbackEvidence) {
        addOwnerLocalWriteReadbackFacts(
            value.summaryBeforeValue(),
            value.summaryAfterAddValue(),
            value.summaryAfterCompleteValue(),
            value.readbackOkValue()
        )
    }

    /// Builder 内部 profile fact 规模，供 verifier 防止空壳化。
    public func profileFactCount(): Int64 {
        return profile.staticBoolFactCount() + profile.textFactCount() + profile.boolFactCount()
    }

    /// 生成完整 typed evidence section，统一 profile 与 run/commit proof assembly。
    public func buildSection(
        output: CjguiExperimentalDemoOutput,
        componentSession: CjguiExperimentalDemoComponentActionSession,
        commitResult: CjguiExperimentalDemoCommitResult,
        commitHarness: CjguiExperimentalDemoCommitHarness,
        runResult: CjguiExperimentalDemoRunResult
    ): CjguiExperimentalDemoEvidenceSection {
        return CjguiExperimentalDemoEvidenceSection(
            profile,
            output,
            componentSession,
            commitResult,
            commitHarness,
            runResult
        )
    }
}

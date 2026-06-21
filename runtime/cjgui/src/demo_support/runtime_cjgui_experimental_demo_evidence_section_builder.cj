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

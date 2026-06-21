// 中文维护注释：这是 CJGUI minimal UI framework demo 复用用的 experimental evidence section builder。
// Scope: 把 profile 创建、fact 追加与 typed section 创建下沉到 shared demo_support，减少 demo-local assembly。
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

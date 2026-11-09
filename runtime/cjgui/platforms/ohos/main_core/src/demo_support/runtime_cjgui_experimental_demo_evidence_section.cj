// 中文维护注释：这是 CJGUI minimal UI framework demo 复用用的 experimental typed evidence section。
// Scope: 把 evidence profile 与 shared execution proof 组合成一个 typed section，减少 demo-local 尾部编排。
// Stop-line: 只持有 demo process-local 脱水证据引用，不写 runtime_state / renderer_state，不调用 native bridge，不扩 public C ABI。
package cjgui.demo_support

/// Experimental demo support API：一段完整 demo evidence section。
public class CjguiExperimentalDemoEvidenceSection {
    /// 承载 identity、status transition、static facts 与 business facts。
    public let profile: CjguiExperimentalDemoEvidenceProfile
    /// Shared demo output，仍只包含 demo-host 脱水结果。
    public let output: CjguiExperimentalDemoOutput
    /// Shared component/action session，用于输出 component action 与 UI state proof。
    public let componentSession: CjguiExperimentalDemoComponentActionSession
    /// Owner-local commit result，用于输出 readback / rollback / not-published proof。
    public let commitResult: CjguiExperimentalDemoCommitResult
    /// Shared commit harness，用于证明 demo-facing commit API 不暴露底层 primitive。
    public let commitHarness: CjguiExperimentalDemoCommitHarness
    /// Shared run result，用于输出 runnable/readback/not-published run proof。
    public let runResult: CjguiExperimentalDemoRunResult

    public init(
        profile: CjguiExperimentalDemoEvidenceProfile,
        output: CjguiExperimentalDemoOutput,
        componentSession: CjguiExperimentalDemoComponentActionSession,
        commitResult: CjguiExperimentalDemoCommitResult,
        commitHarness: CjguiExperimentalDemoCommitHarness,
        runResult: CjguiExperimentalDemoRunResult
    ) {
        this.profile = profile
        this.output = output
        this.componentSession = componentSession
        this.commitResult = commitResult
        this.commitHarness = commitHarness
        this.runResult = runResult
    }

    /// Section 内部可检查的 typed fact 规模，供 verifier 防止空壳化。
    public func profileFactCount(): Int64 {
        return profile.staticBoolFactCount() + profile.textFactCount() + profile.boolFactCount()
    }
}

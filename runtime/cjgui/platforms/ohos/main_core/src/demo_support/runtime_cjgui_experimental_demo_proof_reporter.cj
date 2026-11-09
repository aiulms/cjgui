// 中文维护注释：这是 CJGUI minimal UI framework demo 复用用的 experimental proof reporter。
// Scope: 为多个独立 demo 用同一个 stdout proof renderer 输出 public/component/state/commit evidence。
// Stop-line: 只打印 demo process-local 脱水事实，不写 runtime_state / renderer_state，不调用 native bridge，不扩 public C ABI。
package cjgui.demo_support

/// Experimental demo support API：统一渲染 shared primitive proof 的 stdout evidence。
public class CjguiExperimentalDemoProofReporter {
    let outputPrefix: String

    public init(outputPrefix: String) {
        this.outputPrefix = outputPrefix
    }

    /// 以 verifier 稳定断言的格式输出 public API、component action、UI state 与 commit proof。
    public func printSharedPrimitiveProof(
        output: CjguiExperimentalDemoOutput,
        componentSession: CjguiExperimentalDemoComponentActionSession,
        commitResult: CjguiExperimentalDemoCommitResult,
        commitHarness: CjguiExperimentalDemoCommitHarness
    ) {
        println("${outputPrefix}: public_api_consumed=true")
        println("${outputPrefix}: public_api_name=CjguiExperimentalDemoComponentActionSession")
        println("${outputPrefix}: public_api_output=${output.summary}")
        println("${outputPrefix}: shared_support=CjguiExperimentalDemoComponentActionSession")
        println("${outputPrefix}: shared_support_output=${componentSession.traceSummary()}")
        println("${outputPrefix}: shared_state_core=${componentSession.uiStateSummary()}")
        println("${outputPrefix}: shared_component_action_model=CjguiExperimentalDemoComponentActionSession")
        println("${outputPrefix}: shared_component_action_output=${componentSession.componentActionSummary()}")
        println("${outputPrefix}: shared_commit_harness=CjguiExperimentalDemoCommitHarness")
        println("${outputPrefix}: shared_commit_output=${commitResult.summary}")
        println("${outputPrefix}: shared_commit_readback=${commitHarness.readback()}")
        println("${outputPrefix}: shared_commit_rollback_boundary=${commitHarness.rollbackBoundary()}")
        println("${outputPrefix}: shared_commit_not_published=${commitResult.notPublished}")
    }
}

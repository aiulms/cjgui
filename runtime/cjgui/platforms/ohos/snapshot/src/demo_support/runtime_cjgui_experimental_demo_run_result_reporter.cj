// 中文维护注释：这是 CJGUI minimal UI framework demo 复用用的 experimental run result reporter。
// Scope: 为多个独立 demo 用同一个 stdout proof renderer 输出 shared run result，减少 demo-local 渲染重复。
// Stop-line: 只打印 demo process-local 脱水事实，不写 runtime_state / renderer_state，不调用 native bridge，不扩 public C ABI。
package cjgui.demo_support

/// Experimental demo support API：统一渲染 shared demo run result 的 stdout proof。
public class CjguiExperimentalDemoRunResultReporter {
    let outputPrefix: String

    public init(outputPrefix: String) {
        this.outputPrefix = outputPrefix
    }

    /// 以 verifier 稳定断言的四行格式输出 shared run result。
    public func printRunResult(runResult: CjguiExperimentalDemoRunResult) {
        println("${outputPrefix}: shared_run_harness=CjguiExperimentalDemoRunHarness")
        println("${outputPrefix}: shared_run_result=${runResult.summary}")
        println("${outputPrefix}: shared_run_readback=${runResult.runnable}")
        println("${outputPrefix}: shared_run_not_published=${runResult.notPublished}")
    }
}

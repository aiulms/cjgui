// 中文维护注释：这是 CJGUI minimal UI framework demo 复用用的 experimental business snapshot reporter。
// Scope: 为多个独立 demo 用同一个 stdout proof renderer 输出业务 before/after/readback 等脱水事实。
// Stop-line: 只打印 demo process-local 业务快照，不写 runtime_state / renderer_state，不调用 native bridge，不扩 public C ABI。
package cjgui.demo_support

/// Experimental demo support API：统一渲染 demo-local business snapshot 的 stdout evidence。
public class CjguiExperimentalDemoBusinessSnapshotReporter {
    let outputPrefix: String

    public init(outputPrefix: String) {
        this.outputPrefix = outputPrefix
    }

    /// 输出稳定的 status_before / status_after 行，保持各 demo verifier 的 before/after contract。
    public func printStatusTransition(statusBefore: String, statusAfter: String) {
        println("${outputPrefix}: status_before=${statusBefore}")
        println("${outputPrefix}: status_after=${statusAfter}")
    }

    /// 输出字符串业务事实，例如 state_before / state_after / summary_after。
    public func printTextFact(name: String, value: String) {
        println("${outputPrefix}: ${name}=${value}")
    }

    /// 输出布尔业务事实，例如 state_readback / owner_local_write_readback。
    public func printBoolFact(name: String, value: Bool) {
        println("${outputPrefix}: ${name}=${value}")
    }
}

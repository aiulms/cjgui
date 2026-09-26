// 中文维护注释：这是 CJGUI minimal UI framework demo 复用用的 experimental metadata reporter。
// Scope: 为多个独立 demo 用同一个 stdout proof renderer 输出 demo identity / static evidence。
// Stop-line: 只打印 demo process-local 脱水元数据，不写 runtime_state / renderer_state，不调用 native bridge，不扩 public C ABI。
package cjgui.demo_support

/// Experimental demo support API：统一渲染 demo identity 与静态 runnable evidence。
public class CjguiExperimentalDemoMetadataReporter {
    let outputPrefix: String

    public init(outputPrefix: String) {
        this.outputPrefix = outputPrefix
    }

    /// 输出稳定的 demo identity 行，减少各 demo 自己拼接 `demo=...` 的重复模板。
    public func printDemoIdentity(demoName: String) {
        println("${outputPrefix}: demo=${demoName}")
    }

    /// 输出静态布尔事实，例如 main_declared / deterministic_output。
    public func printStaticBoolFact(name: String, value: Bool) {
        println("${outputPrefix}: ${name}=${value}")
    }
}

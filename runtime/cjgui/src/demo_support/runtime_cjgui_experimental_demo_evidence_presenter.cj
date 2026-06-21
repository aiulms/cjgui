// 中文维护注释：这是 CJGUI minimal UI framework demo 复用用的 experimental evidence presenter。
// Scope: 为多个独立 demo 编排 metadata / business / proof / run result reporter，减少 demo-local reporter wiring 与 fact 调用序列。
// Stop-line: 只打印 demo process-local 脱水证据，不写 runtime_state / renderer_state，不调用 native bridge，不扩 public C ABI。
package cjgui.demo_support

/// Experimental demo support API：统一编排 demo evidence stdout renderer。
public class CjguiExperimentalDemoEvidencePresenter {
    let metadataReporter: CjguiExperimentalDemoMetadataReporter
    let businessReporter: CjguiExperimentalDemoBusinessSnapshotReporter
    let proofReporter: CjguiExperimentalDemoProofReporter
    let runReporter: CjguiExperimentalDemoRunResultReporter

    public init(outputPrefix: String) {
        this.metadataReporter = CjguiExperimentalDemoMetadataReporter(outputPrefix)
        this.businessReporter = CjguiExperimentalDemoBusinessSnapshotReporter(outputPrefix)
        this.proofReporter = CjguiExperimentalDemoProofReporter(outputPrefix)
        this.runReporter = CjguiExperimentalDemoRunResultReporter(outputPrefix)
    }

    /// 输出 demo identity，保持 focused verifier 的稳定首行证据。
    public func printDemoIdentity(demoName: String) {
        metadataReporter.printDemoIdentity(demoName)
    }

    /// 输出静态布尔事实，例如 Settings 的 main_declared / deterministic_output。
    public func printStaticBoolFact(name: String, value: Bool) {
        metadataReporter.printStaticBoolFact(name, value)
    }

    /// 输出 status_before / status_after。
    public func printStatusTransition(statusBefore: String, statusAfter: String) {
        businessReporter.printStatusTransition(statusBefore, statusAfter)
    }

    /// 输出字符串业务事实。
    public func printTextFact(name: String, value: String) {
        businessReporter.printTextFact(name, value)
    }

    /// 输出布尔业务事实。
    public func printBoolFact(name: String, value: Bool) {
        businessReporter.printBoolFact(name, value)
    }

    /// 批量输出 demo identity、状态迁移、静态 facts 与业务 facts，减少每个 demo 的 presenter 调用序列。
    public func printEvidenceProfile(profile: CjguiExperimentalDemoEvidenceProfile) {
        printDemoIdentity(profile.demoName)
        for (fact in profile.staticBoolFacts) {
            printStaticBoolFact(fact.name, fact.value)
        }
        printStatusTransition(profile.statusBefore, profile.statusAfter)
        for (fact in profile.textFacts) {
            printTextFact(fact.name, fact.value)
        }
        for (fact in profile.boolFacts) {
            printBoolFact(fact.name, fact.value)
        }
    }

    /// 输出 shared primitive proof 与 shared run result，减少每个 demo 的 reporter 尾部编排重复。
    public func printSharedExecutionProof(
        output: CjguiExperimentalDemoOutput,
        componentSession: CjguiExperimentalDemoComponentActionSession,
        commitResult: CjguiExperimentalDemoCommitResult,
        commitHarness: CjguiExperimentalDemoCommitHarness,
        runResult: CjguiExperimentalDemoRunResult
    ) {
        proofReporter.printSharedPrimitiveProof(output, componentSession, commitResult, commitHarness)
        runReporter.printRunResult(runResult)
    }
}

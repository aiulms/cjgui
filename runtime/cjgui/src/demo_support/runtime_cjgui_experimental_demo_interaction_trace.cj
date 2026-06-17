// 中文维护注释：这是 CJGUI minimal UI framework demo 复用用的 experimental interaction trace support。
// Scope: 为多个独立 demo 提供同一个 owner-local before/after/action trace core，减少每个 demo 自造状态追踪。
// Stop-line: 只保存 demo process-local in-memory 状态，不写 runtime_state / renderer_state，不扩 public C ABI。
package cjgui.demo_support

public class CjguiExperimentalDemoInteractionTrace {
    public let demoName: String
    private var beforeState: String
    private var afterState: String
    private var actionTrace: String
    private var writeCount: Int64

    public init(demoName: String, beforeState: String) {
        this.demoName = demoName
        this.beforeState = beforeState
        this.afterState = beforeState
        this.actionTrace = "idle"
        this.writeCount = 0
    }

    public func recordAction(action: String, afterState: String) {
        if (actionTrace == "idle") {
            actionTrace = action
        } else {
            actionTrace = "${actionTrace},${action}"
        }
        this.afterState = afterState
        writeCount += 1
    }

    public func before(): String {
        return beforeState
    }

    public func after(): String {
        return afterState
    }

    public func actions(): String {
        return actionTrace
    }

    public func writes(): Int64 {
        return writeCount
    }

    public func summary(): String {
        return "demo=${demoName};writes=${writeCount};actions=${actionTrace};before=${beforeState};after=${afterState}"
    }
}

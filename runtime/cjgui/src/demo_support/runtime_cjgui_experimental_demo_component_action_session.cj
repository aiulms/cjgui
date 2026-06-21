// 中文维护注释：这是 CJGUI minimal UI framework demo 复用用的 experimental component/action session。
// Scope: 为多个独立 demo 提供同一组 component action route、UI state core 与 output builder 串联 primitive。
// Stop-line: 只保存 demo process-local in-memory 状态，不写 runtime_state / renderer_state，不调用 native bridge。
package cjgui.demo_support

/// Experimental demo support API：组件身份与动作名称的 typed route value。
public class CjguiExperimentalDemoComponentActionRoute {
    /// 组件标识保持脱水字符串，避免把 demo route 误解为 renderer handle。
    public let componentId: String
    /// 动作名称保持脱水字符串，供 existing trace/output 兼容消费。
    public let action: String

    /// 创建只承载脱水 component/action 字符串的 route value。
    public init(componentId: String, action: String) {
        this.componentId = componentId
        this.action = action
    }

    /// 转换为现有 component id 字符串。
    public func componentIdValue(): String {
        return componentId
    }

    /// 转换为现有 action 字符串。
    public func actionValue(): String {
        return action
    }

    /// 转换为现有 `component:action` route fact。
    public func routeValue(): String {
        return "${componentId}:${action}"
    }
}

/// Experimental demo support API：把 component action、UI state core 与 output builder 组合成可复用 demo-host session。
public class CjguiExperimentalDemoComponentActionSession {
    /// Demo 名称保持 public，方便 verifier/readback 证明哪个 app 消费了 shared session。
    public let demoName: String
    let uiState: CjguiExperimentalDemoUiStateCore
    let trace: CjguiExperimentalDemoInteractionTrace
    private var componentActionTrace: String

    /// 为单个 demo 创建 process-local before-state、UI state 与 action trace session。
    public init(
        demoName: String,
        initialState: String,
        layoutMode: String,
        styleToken: String,
        inputText: String,
        focusTarget: String
    ) {
        this.demoName = demoName
        this.uiState = CjguiExperimentalDemoUiStateCore(layoutMode, styleToken, inputText, focusTarget)
        this.trace = CjguiExperimentalDemoInteractionTrace(demoName, initialState)
        this.componentActionTrace = "idle"
    }

    /// 供 demo 业务方法复用的 shared layout 写入 helper。
    public func applyLayout(mode: String) {
        uiState.applyLayout(mode)
    }

    /// 供 demo 业务方法复用的 shared style 写入 helper。
    public func applyStyle(token: String) {
        uiState.applyStyle(token)
    }

    /// 供 demo 业务方法复用的 shared text input 写入 helper。
    public func typeInput(text: String) {
        uiState.typeInput(text)
    }

    /// 供 demo 业务方法复用的 shared focus 写入 helper。
    public func moveFocus(target: String) {
        uiState.moveFocus(target)
    }

    /// 同时记录业务 action 顺序与 component/action route，不暴露 renderer state。
    public func recordComponentAction(componentId: String, action: String, afterState: String) {
        recordComponentActionRoute(CjguiExperimentalDemoComponentActionRoute(componentId, action), afterState)
    }

    /// 通过 typed route value 记录 component/action，减少 demo-local 裸字符串三参入口。
    public func recordComponentActionRoute(route: CjguiExperimentalDemoComponentActionRoute, afterState: String) {
        trace.recordAction(route.actionValue(), afterState)
        if (componentActionTrace == "idle") {
            componentActionTrace = route.routeValue()
        } else {
            componentActionTrace = "${componentActionTrace},${route.routeValue()}"
        }
    }

    /// 返回 shared trace 捕获的初始业务状态。
    public func before(): String {
        return trace.before()
    }

    /// 返回 shared trace 捕获的最新业务状态。
    public func after(): String {
        return trace.after()
    }

    /// 返回业务方法记录的 action 顺序。
    public func actions(): String {
        return trace.actions()
    }

    /// 返回业务方法记录的 owner-local 写入次数。
    public func writes(): Int64 {
        return trace.writes()
    }

    /// 返回业务方法记录的 component/action route 顺序。
    public func componentActions(): String {
        return componentActionTrace
    }

    /// 返回当前 shared layout fact。
    public func layout(): String {
        return uiState.layout()
    }

    /// 返回当前 shared style fact。
    public func style(): String {
        return uiState.style()
    }

    /// 返回当前 shared text input fact。
    public func textInput(): String {
        return uiState.textInput()
    }

    /// 返回当前 shared focus fact。
    public func focus(): String {
        return uiState.focus()
    }

    /// 用 common demo_support summary 格式返回 layout/style/input/focus facts。
    public func uiStateSummary(): String {
        return uiState.summary()
    }

    /// 用 common demo_support trace 格式返回 before/after/action/write facts。
    public func traceSummary(): String {
        return trace.summary()
    }

    /// 返回 component/action route facts 与 shared UI state facts。
    public func componentActionSummary(): String {
        return "demo=${demoName};component_actions=${componentActionTrace};ui=${uiState.summary()}"
    }

    /// 构造 shared demo output value，不创建 renderer/runtime publication truth。
    public func buildOutput(domainSummary: String, readbackOk: Bool): CjguiExperimentalDemoOutput {
        return CjguiExperimentalDemoOutputBuilder().buildFromTrace(trace, domainSummary, readbackOk)
    }
}

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

/// Experimental demo support API：集中维护 runnable demos 复用的 component/action route spelling。
public class CjguiExperimentalDemoComponentActionRouteCatalog {
    /// Catalog 无状态；实例化是为了让 demo 以 shared primitive 形式复用命名 route。
    public init() {}

    func route(componentId: String, action: String): CjguiExperimentalDemoComponentActionRoute {
        return CjguiExperimentalDemoComponentActionRoute(componentId, action)
    }

    /// Todo demo 的新增条目 route。
    public func todoAdd(): CjguiExperimentalDemoComponentActionRoute {
        return route("todo_input", "todo.add")
    }

    /// Todo demo 的完成条目 route。
    public func todoComplete(): CjguiExperimentalDemoComponentActionRoute {
        return route("todo_item", "todo.complete")
    }

    /// Settings demo 的 auto-save toggle route。
    public func settingsToggleAutoSave(): CjguiExperimentalDemoComponentActionRoute {
        return route("auto_save_toggle", "settings.toggle_auto_save")
    }

    /// Settings demo 的 theme selection route。
    public func settingsSelectTheme(): CjguiExperimentalDemoComponentActionRoute {
        return route("theme_select", "settings.select_theme")
    }

    /// Settings demo 的 username update route。
    public func settingsUpdateUsername(): CjguiExperimentalDemoComponentActionRoute {
        return route("username_field", "settings.update_username")
    }

    /// Settings demo 的 focus movement route，保留动态 target 但固定 action spelling。
    public func settingsMoveFocus(target: String): CjguiExperimentalDemoComponentActionRoute {
        return route(target, "settings.move_focus")
    }

    /// Chat demo 的 composer typing route。
    public func chatTypeMessage(): CjguiExperimentalDemoComponentActionRoute {
        return route("composer", "chat.type_message")
    }

    /// Chat demo 的 assistant reply append route。
    public func chatAppendReply(): CjguiExperimentalDemoComponentActionRoute {
        return route("message_list", "chat.append_reply")
    }

    /// Chat demo 的 send message route。
    public func chatSendMessage(): CjguiExperimentalDemoComponentActionRoute {
        return route("send_button", "chat.send_message")
    }

    /// Chat demo 的 focus movement route，保留动态 target 但固定 action spelling。
    public func chatMoveFocus(target: String): CjguiExperimentalDemoComponentActionRoute {
        return route(target, "chat.move_focus")
    }

    /// FileBrowser demo 的 folder expansion route。
    public func fileBrowserExpandFolder(): CjguiExperimentalDemoComponentActionRoute {
        return route("folder_tree", "file_browser.expand_folder")
    }

    /// FileBrowser demo 的 filter route。
    public func fileBrowserFilterEntries(): CjguiExperimentalDemoComponentActionRoute {
        return route("tree_filter", "file_browser.filter_entries")
    }

    /// FileBrowser demo 的 file selection route。
    public func fileBrowserSelectFile(): CjguiExperimentalDemoComponentActionRoute {
        return route("file_row", "file_browser.select_file")
    }

    /// FileBrowser demo 的 detail refresh route。
    public func fileBrowserRefreshDetail(): CjguiExperimentalDemoComponentActionRoute {
        return route("detail_pane", "file_browser.refresh_detail")
    }

    /// FileBrowser demo 的 focus movement route，保留动态 target 但固定 action spelling。
    public func fileBrowserMoveFocus(target: String): CjguiExperimentalDemoComponentActionRoute {
        return route(target, "file_browser.move_focus")
    }

    /// AI-generated UI demo 的 diff preview route。
    public func aiGeneratedUiPreviewDiff(): CjguiExperimentalDemoComponentActionRoute {
        return route("diff_panel", "ai_generated_ui.preview_diff")
    }

    /// AI-generated UI demo 的 explanation route。
    public func aiGeneratedUiExplainChanges(): CjguiExperimentalDemoComponentActionRoute {
        return route("explain_panel", "ai_generated_ui.explain_changes")
    }

    /// AI-generated UI demo 的 accept refresh route。
    public func aiGeneratedUiAcceptRefresh(): CjguiExperimentalDemoComponentActionRoute {
        return route("generated_form", "ai_generated_ui.accept_refresh")
    }

    /// AI-generated UI demo 的 focus movement route，保留动态 target 但固定 action spelling。
    public func aiGeneratedUiMoveFocus(target: String): CjguiExperimentalDemoComponentActionRoute {
        return route(target, "ai_generated_ui.move_focus")
    }

    /// Shared demo harness 的 add todo route。
    public func sharedDemoHarnessAddTodo(): CjguiExperimentalDemoComponentActionRoute {
        return route("todo_input", "shared_demo_harness.add_todo")
    }

    /// Shared demo harness 的 complete todo route。
    public func sharedDemoHarnessCompleteTodo(): CjguiExperimentalDemoComponentActionRoute {
        return route("todo_item", "shared_demo_harness.complete_todo")
    }

    /// Shared multi-demo harness 的 todo add route。
    public func sharedMultiDemoHarnessTodoAdd(): CjguiExperimentalDemoComponentActionRoute {
        return route("todo_input", "shared_multi_demo_harness.todo_add")
    }

    /// Shared multi-demo harness 的 todo complete route。
    public func sharedMultiDemoHarnessTodoComplete(): CjguiExperimentalDemoComponentActionRoute {
        return route("todo_item", "shared_multi_demo_harness.todo_complete")
    }

    /// Shared multi-demo harness 的 file expand route。
    public func sharedMultiDemoHarnessFileExpand(): CjguiExperimentalDemoComponentActionRoute {
        return route("file_tree", "shared_multi_demo_harness.file_expand")
    }

    /// Shared multi-demo harness 的 file filter route。
    public func sharedMultiDemoHarnessFileFilter(): CjguiExperimentalDemoComponentActionRoute {
        return route("file_filter", "shared_multi_demo_harness.file_filter")
    }

    /// Shared multi-demo harness 的 file select route。
    public func sharedMultiDemoHarnessFileSelect(): CjguiExperimentalDemoComponentActionRoute {
        return route("file_row", "shared_multi_demo_harness.file_select")
    }

    /// Shared multi-demo harness 的 file focus route。
    public func sharedMultiDemoHarnessFileFocus(): CjguiExperimentalDemoComponentActionRoute {
        return route("file_detail_pane", "shared_multi_demo_harness.file_focus")
    }

    /// Shared layout/style/input/focus contract 的 layout route。
    public func sharedLayoutStyleInputFocusApplyLayout(): CjguiExperimentalDemoComponentActionRoute {
        return route("layout_contract", "shared_layout_style_input_focus.apply_layout")
    }

    /// Shared layout/style/input/focus contract 的 style route。
    public func sharedLayoutStyleInputFocusApplyStyle(): CjguiExperimentalDemoComponentActionRoute {
        return route("style_contract", "shared_layout_style_input_focus.apply_style")
    }

    /// Shared layout/style/input/focus contract 的 text input route。
    public func sharedLayoutStyleInputFocusTypeInput(): CjguiExperimentalDemoComponentActionRoute {
        return route("text_input_contract", "shared_layout_style_input_focus.type_input")
    }

    /// Shared layout/style/input/focus contract 的 focus route。
    public func sharedLayoutStyleInputFocusMoveFocus(): CjguiExperimentalDemoComponentActionRoute {
        return route("focus_contract", "shared_layout_style_input_focus.move_focus")
    }

    /// AI-generated UI shared contract 的 spec generation route。
    public func aiGeneratedUiSharedContractGenerateSpec(): CjguiExperimentalDemoComponentActionRoute {
        return route("spec_generator", "generate_spec")
    }

    /// AI-generated UI shared contract 的 diff preview route。
    public func aiGeneratedUiSharedContractPreviewDiff(): CjguiExperimentalDemoComponentActionRoute {
        return route("diff_panel", "preview_diff")
    }

    /// AI-generated UI shared contract 的 explanation route。
    public func aiGeneratedUiSharedContractExplainChanges(): CjguiExperimentalDemoComponentActionRoute {
        return route("explain_panel", "explain_changes")
    }

    /// AI-generated UI shared contract 的 accept refresh route。
    public func aiGeneratedUiSharedContractAcceptRefresh(): CjguiExperimentalDemoComponentActionRoute {
        return route("generated_form", "accept_refresh")
    }

    /// AI-generated UI shared contract 的 focus movement route。
    public func aiGeneratedUiSharedContractMoveFocus(): CjguiExperimentalDemoComponentActionRoute {
        return route("save_button", "move_focus")
    }

    /// Reusable component contract 的 file row registration route。
    public func reusableComponentContractRegisterFileRow(): CjguiExperimentalDemoComponentActionRoute {
        return route("file_row", "register_file_row")
    }

    /// Reusable component contract 的 AI form registration route。
    public func reusableComponentContractRegisterAiForm(): CjguiExperimentalDemoComponentActionRoute {
        return route("ai_form", "register_ai_form")
    }

    /// Reusable component contract 的 Todo add route。
    public func reusableComponentContractTodoAdd(): CjguiExperimentalDemoComponentActionRoute {
        return route("task_row", "todo_add")
    }

    /// Reusable component contract 的 file select route。
    public func reusableComponentContractFileSelect(): CjguiExperimentalDemoComponentActionRoute {
        return route("file_row", "file_select")
    }

    /// Reusable component contract 的 AI accept route。
    public func reusableComponentContractAiAccept(): CjguiExperimentalDemoComponentActionRoute {
        return route("ai_form", "ai_accept")
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

// 中文维护注释：这是 CJGUI minimal UI framework demo 复用用的 experimental owner-local commit session。
// Scope: 为多个独立 demo 提供同一个 in-memory commit/readback/rollback-boundary value primitive。
// Stop-line: 只保存 demo process-local 状态，不写 runtime_state / renderer_state，不调用 native bridge，不发布 renderer truth。
package cjgui.demo_support

/// Experimental demo support API：表达一次 owner-local commit 后的读回、回滚边界与未发布状态。
public class CjguiExperimentalDemoCommitResult {
    /// 消费该 shared commit primitive 的 demo 名称。
    public let demoName: String
    /// 发起 commit 的 component 标识，只用于 demo-host 读回证据。
    public let componentId: String
    /// 发起 commit 的 action 名称，只用于 demo-host 读回证据。
    public let action: String
    /// commit 前的 owner-local 业务状态。
    public let beforeState: String
    /// commit 后请求写入的 owner-local 业务状态。
    public let afterState: String
    /// commit 后从 session 中读回的 owner-local 业务状态。
    public let readbackState: String
    /// 可回滚到的上一份 owner-local 状态快照；这里只表达边界，不自动发布。
    public let rollbackState: String
    /// 当前 session 已执行的 owner-local commit 次数。
    public let writeCount: Int64
    /// 本次 commit 是否完成 session-local 写入。
    public let committed: Bool
    /// 本次 commit 后 readback 是否等于 afterState。
    public let readbackOk: Bool
    /// 是否保留上一份状态作为 rollback boundary。
    public let rollbackAvailable: Bool
    /// 是否保持未发布到 runtime_state / renderer_state 的边界。
    public let notPublished: Bool
    /// 供 demo verifier 稳定断言的脱水摘要。
    public let summary: String

    public init(
        demoName: String,
        componentId: String,
        action: String,
        beforeState: String,
        afterState: String,
        readbackState: String,
        rollbackState: String,
        writeCount: Int64,
        committed: Bool,
        readbackOk: Bool,
        rollbackAvailable: Bool,
        notPublished: Bool,
        summary: String
    ) {
        this.demoName = demoName
        this.componentId = componentId
        this.action = action
        this.beforeState = beforeState
        this.afterState = afterState
        this.readbackState = readbackState
        this.rollbackState = rollbackState
        this.writeCount = writeCount
        this.committed = committed
        this.readbackOk = readbackOk
        this.rollbackAvailable = rollbackAvailable
        this.notPublished = notPublished
        this.summary = summary
    }
}

/// Experimental demo support API：owner-local commit 使用的 typed component/action route value。
public class CjguiExperimentalDemoCommitActionRoute {
    /// 组件标识保持脱水字符串，避免把 commit route 误解为 renderer handle。
    public let componentId: String
    /// 动作名称保持脱水字符串，供 commit result / readback 兼容消费。
    public let action: String

    /// 创建只承载脱水 component/action 字符串的 commit route value。
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

/// Experimental demo support API：集中维护 runnable demos 复用的 owner-local commit route spelling。
public class CjguiExperimentalDemoCommitActionRouteCatalog {
    /// Catalog 无状态；实例化是为了让 demo 以 shared primitive 形式复用命名 commit route。
    public init() {}

    func route(componentId: String, action: String): CjguiExperimentalDemoCommitActionRoute {
        return CjguiExperimentalDemoCommitActionRoute(componentId, action)
    }

    /// Todo demo 的完成条目 commit route。
    public func todoCommitComplete(): CjguiExperimentalDemoCommitActionRoute {
        return route("todo_item", "todo.commit_complete")
    }

    /// Settings demo 的偏好提交 commit route。
    public func settingsCommitPreferences(): CjguiExperimentalDemoCommitActionRoute {
        return route("theme_select", "settings.commit_preferences")
    }

    /// Chat demo 的 thread 提交 commit route。
    public func chatCommitThread(): CjguiExperimentalDemoCommitActionRoute {
        return route("message_list", "chat.commit_thread")
    }

    /// FileBrowser demo 的 detail 提交 commit route。
    public func fileBrowserCommitDetail(): CjguiExperimentalDemoCommitActionRoute {
        return route("detail_pane", "file_browser.commit_detail")
    }

    /// AI-generated UI demo 的 accept refresh 提交 commit route。
    public func aiGeneratedUiCommitAcceptRefresh(): CjguiExperimentalDemoCommitActionRoute {
        return route("save_button", "ai_generated_ui.commit_accept_refresh")
    }

    /// Shared demo harness 的 Todo flow commit route。
    public func sharedDemoHarnessCommitTodoFlow(): CjguiExperimentalDemoCommitActionRoute {
        return route("todo_item", "shared_demo_harness.commit_todo_flow")
    }

    /// Shared multi-demo harness 的 multi flow commit route。
    public func sharedMultiDemoHarnessCommitMultiFlow(): CjguiExperimentalDemoCommitActionRoute {
        return route("file_detail_pane", "shared_multi_demo_harness.commit_multi_flow")
    }

    /// Shared layout/style/input/focus contract 的 contract flow commit route。
    public func sharedLayoutStyleInputFocusCommitContractFlow(): CjguiExperimentalDemoCommitActionRoute {
        return route("focus_contract", "shared_layout_style_input_focus.commit_contract_flow")
    }

    /// AI-generated UI shared contract 的 accept refresh commit route。
    public func aiGeneratedUiSharedContractCommitAcceptRefresh(): CjguiExperimentalDemoCommitActionRoute {
        return route("save_button", "ai_generated_ui_shared_contract.commit_accept_refresh")
    }

    /// Reusable component contract 的 reuse flow commit route。
    public func reusableComponentContractCommitReuseFlow(): CjguiExperimentalDemoCommitActionRoute {
        return route("ai_form", "reusable_component_contract.commit_reuse_flow")
    }
}

/// Experimental demo support API：只在 demo host 内存中提交、读回并保留回滚边界。
public class CjguiExperimentalDemoOwnerLocalCommitSession {
    /// Demo 名称保持 public，方便 verifier/readback 证明哪个 app 消费了 shared commit session。
    public let demoName: String
    private var currentState: String
    private var lastRollbackState: String
    private var writeCount: Int64

    public init(demoName: String, initialState: String) {
        this.demoName = demoName
        this.currentState = initialState
        this.lastRollbackState = initialState
        this.writeCount = 0
    }

    /// 提交一次 demo-host owner-local 状态变更，并返回不发布到 renderer/runtime 的脱水结果。
    public func commitComponentAction(
        componentId: String,
        action: String,
        afterState: String
    ): CjguiExperimentalDemoCommitResult {
        let beforeState = currentState
        lastRollbackState = beforeState
        currentState = afterState
        writeCount += 1
        let readbackState = currentState
        let readbackOk = readbackState == afterState
        let rollbackAvailable = lastRollbackState == beforeState
        let notPublished = true
        let summary = "demo=${demoName};component=${componentId};action=${action};committed=true;readback=${readbackOk};writes=${writeCount};before=${beforeState};after=${afterState};readback_state=${readbackState};rollback_state=${lastRollbackState};not_published=${notPublished}"
        return CjguiExperimentalDemoCommitResult(
            demoName,
            componentId,
            action,
            beforeState,
            afterState,
            readbackState,
            lastRollbackState,
            writeCount,
            true,
            readbackOk,
            rollbackAvailable,
            notPublished,
            summary
        )
    }

    /// 用 shared commit route value 提交一次 demo-host owner-local 状态变更。
    public func commitComponentActionRoute(
        route: CjguiExperimentalDemoCommitActionRoute,
        afterState: String
    ): CjguiExperimentalDemoCommitResult {
        return commitComponentAction(route.componentIdValue(), route.actionValue(), afterState)
    }

    /// 读回 session 当前 owner-local 状态；不读取 renderer/runtime 状态。
    public func readback(): String {
        return currentState
    }

    /// 读回上一份 rollback boundary；不执行真实回滚发布。
    public func rollbackBoundary(): String {
        return lastRollbackState
    }

    /// 返回当前 session-local commit 次数。
    public func writes(): Int64 {
        return writeCount
    }
}

/// Experimental demo support API：组合 owner-local commit session 与通用 result 校验，减少 demo-local wrapper。
public class CjguiExperimentalDemoCommitHarness {
    /// Demo 名称保持 public，方便 verifier 证明多个 demo 消费同一个 shared commit harness。
    public let demoName: String
    let session: CjguiExperimentalDemoOwnerLocalCommitSession

    public init(demoName: String, initialState: String) {
        this.demoName = demoName
        this.session = CjguiExperimentalDemoOwnerLocalCommitSession(demoName, initialState)
    }

    /// 提交一次 demo-host owner-local 状态变更；不发布 renderer/runtime truth。
    public func commitComponentAction(
        componentId: String,
        action: String,
        afterState: String
    ): CjguiExperimentalDemoCommitResult {
        return session.commitComponentAction(componentId, action, afterState)
    }

    /// 用 shared commit route value 提交一次 demo-host owner-local 状态变更。
    public func commitComponentActionRoute(
        route: CjguiExperimentalDemoCommitActionRoute,
        afterState: String
    ): CjguiExperimentalDemoCommitResult {
        return session.commitComponentActionRoute(route, afterState)
    }

    /// 用 shared 规则校验 commit result、readback 与 rollback boundary 是否自洽。
    public func resultMatches(
        result: CjguiExperimentalDemoCommitResult,
        componentId: String,
        action: String,
        beforeState: String,
        afterState: String
    ): Bool {
        return result.demoName == demoName &&
            result.componentId == componentId &&
            result.action == action &&
            result.beforeState == beforeState &&
            result.afterState == afterState &&
            result.readbackState == afterState &&
            result.rollbackState == beforeState &&
            result.writeCount == writes() &&
            result.committed &&
            result.readbackOk &&
            result.rollbackAvailable &&
            result.notPublished &&
            readback() == afterState &&
            rollbackBoundary() == beforeState
    }

    /// 用 shared commit route value 校验 commit result、readback 与 rollback boundary 是否自洽。
    public func resultMatchesRoute(
        result: CjguiExperimentalDemoCommitResult,
        route: CjguiExperimentalDemoCommitActionRoute,
        beforeState: String,
        afterState: String
    ): Bool {
        return resultMatches(result, route.componentIdValue(), route.actionValue(), beforeState, afterState)
    }

    /// 读回 session 当前 owner-local 状态；不读取 renderer/runtime 状态。
    public func readback(): String {
        return session.readback()
    }

    /// 读回上一份 rollback boundary；不执行真实回滚发布。
    public func rollbackBoundary(): String {
        return session.rollbackBoundary()
    }

    /// 返回当前 session-local commit 次数。
    public func writes(): Int64 {
        return session.writes()
    }
}

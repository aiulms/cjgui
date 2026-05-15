# P1 Renderer 可见窗口 NSApplication Shared-Application Accessor Scope 预检决策

## 当前问题

当前上游 endpoint 是 `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationGuardPolicyReadiness` / `cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationGuardPolicyDraft()`。它只证明 shared-application guard policy facts：application singleton accessor 仍 blocked、application singleton creation 仍 blocked、main-thread gate、bounded run loop、auto-close、teardown before visible、non-user-visible、activation policy / activation / event loop blocked、native visible order blocked、drawable blocked、render blocked、no public surface、no renderer state write 与 no backend-ready truth。

本预检要判断是否能进入 `NSApplication` shared-application accessor scope。结论是只能打开 internal value-style scope boundary，不能直接调用 application singleton accessor。

## 决策

选择 A：进入 `P1 internal Renderer visible-window production harness NSApplication shared-application accessor scope value boundary implementation`。

理由：

- `sharedApplication` accessor 在 AppKit 语义上不能被当成无副作用查询；它可能创建或返回 process-wide application singleton。
- 当前 native guard / guard policy facts 只证明 accessor 仍 blocked，不证明 accessor call 可安全执行。
- 下一刀需要先把 accessor scope 与 singleton creation / activation / event loop 拆清楚，避免把 guard policy facts 误读为 application-ready truth。

## 下一刀允许做什么

- 新增 internal-only runtime owner，消费 `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationGuardPolicyReadiness`。
- 固定 value facts：accessor scope remains blocked、singleton creation remains blocked、main-thread gate required、bounded run loop required、auto-close required、teardown before visible required、non-user-visible required、activation policy / activation / event loop still blocked、native visible order / drawable / render still blocked。
- 新增 owner probe，验证 owner 符号、上游输入与停止线。
- 同步 README / tracker / plans README / runtime README / DESIGN_INTENT_INDEX / topic manifests。

## 停止线

不得调用 application singleton accessor；不得创建 `NSApplication`；不得 activation；不得修改 activation policy；不得运行 AppKit event loop；不得调用 `makeKeyAndOrderFront` / `orderFront`；不得调用 production `nextDrawable`；不得配置 color attachment；不得创建 render command encoder；不得 draw；不得 `commit` / `present`；不得提交 GPU work；不得执行 render；不得返回 pointer / handle / `Class` / `id`；不得新增 public API / public C ABI / diagnostics；不得写 renderer state；不得修改 [runtime_state.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_state.cj) 或 [cjpm.toml](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/cjpm.toml)。

## GitNexus 结果

预检 impact / context 对近期新增 symbols 返回 target not found / UNKNOWN，不能作为安全证明。本阶段按源码读取、owner probe、build、forbidden scan、manifest reachability 与 protected path scan 兜底。

## 当前唯一后续入口

`P1 internal Renderer visible-window production harness NSApplication shared-application accessor scope value boundary implementation`

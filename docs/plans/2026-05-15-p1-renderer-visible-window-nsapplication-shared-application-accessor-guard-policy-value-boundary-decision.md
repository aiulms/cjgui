# P1 Renderer 可见窗口 NSApplication Shared-Application Accessor Guard Policy Value Boundary 决策

## 决策结论

本阶段选择 A 路线：accessor native guard facts 不能直接升级为 application singleton accessor call、`NSApplication` creation、activation policy mutation、activation、event loop 或 user-visible ordering permission。下一刀只能新增 internal value-style policy owner，把 accessor native guard observation 脱水为 accessor guard policy facts。

原因是当前 accessor native guard 只证明 runtime owner 复用既有 no-side-effect native guard facts，观察到 accessor call blocked、accessor scope blocked、singleton creation blocked、main-thread gate required、bounded run loop required、auto-close required、teardown / non-user-visible required、activation policy / activation / event loop blocked、visible order blocked、drawable blocked 与 render blocked。它没有调用 `sharedApplication`，没有创建 `NSApplication`，没有调用 activation / activation policy API，也没有运行 AppKit event loop。

## 上游

- `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorNativeGuardReadiness`
- `cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationAccessorNativeGuardDraft()`

## 下一刀允许的实现面

- 新增 internal-only runtime owner，建议文件为 `runtime_renderer_visible_window_nsapplication_shared_application_accessor_guard_policy.cj`。
- 该 owner 只能消费 `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorNativeGuardReadiness`。
- 该 owner 只能表达 accessor guard policy facts：accessor call still blocked、accessor scope still blocked、application singleton creation still blocked、main-thread gate required、bounded run loop required、auto-close required、teardown before visible required、non-user-visible required、activation policy / activation / event loop still blocked、native visible order still blocked、production drawable still blocked、render still blocked 与 no backend-ready truth。
- 可新增 runtime owner probe，用于检查 owner symbols、upstream input、停止线和 forbidden tokens。
- 不新增 native C ABI、不修改 production native bridge、不新增 `foreign func`、不修改 build config。

## 停止线

下一刀仍不允许调用 `sharedApplication`、`setActivationPolicy`、`activateIgnoringOtherApps`、`run`、`makeKeyAndOrderFront`、`orderFront`、production `nextDrawable`、`renderCommandEncoder`、`drawPrimitives`、`commit`、`presentDrawable` 或任何真实 render execution。不得创建 `NSApplication`，不得 activation，不得运行 AppKit event loop，不得返回 pointer / handle / `id` / `Class`，不得新增 public declaration，仍不得修改 `runtime_state.cj` 或 `runtime/cjgui/cjpm.toml`。

## GitNexus 结果

GitNexus 对 `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorNativeGuardReadiness` 与 `cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationAccessorNativeGuardDraft()` 返回 not found / UNKNOWN。该结果只说明近期新增符号未被索引覆盖，不能作为安全证明；本阶段必须以源码读取、build、probe、forbidden scan、protected path scan 与 manifest reachability 兜底。

## 下一边界

若本决策 docs / scan 全部通过，下一 opening 转为：

`P1 internal Renderer visible-window production harness NSApplication shared-application accessor guard policy value boundary implementation`

该 next opening 仍不是 application singleton accessor、application creation / activation、visible order、drawable acquisition、GPU submission、render、renderer state write、backend-ready truth 或 public API permission。

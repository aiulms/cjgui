# P1 Renderer 可见窗口 NSApplication Shared-Application Cleanup / Headless Safety 预检决策

状态：preflight decision / internal value boundary candidate

## 决策结论

本阶段选择 A 路线：允许新增 internal value-style owner，消费 containment policy readiness，把 cleanup co-ownership、headless fail-closed、CI artifact policy、main-thread ownership proof 与 teardown proof 固化为 value facts。

本阶段仍不允许 actual application singleton accessor call，不允许 `NSApplication` creation / activation，不允许 activation policy mutation，不允许 AppKit event loop，不允许 native visible order、production drawable、render 或 renderer state write。

## 上游

- `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentPolicyReadiness`
- `cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentPolicyDraft()`

## 下一刀允许的实现面

- 新增 internal-only runtime owner：[runtime_renderer_visible_window_nsapplication_shared_application_cleanup_headless_safety.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_cleanup_headless_safety.cj)
- 新增 owner probe：[verify_renderer_visible_window_nsapplication_shared_application_cleanup_headless_safety_owner.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_cleanup_headless_safety_owner.sh)
- Owner 只能消费 containment policy readiness。
- Owner 只能表达 cleanup / headless safety value facts。
- 不新增 native C ABI、不修改 production native bridge、不新增 `foreign func`、不修改 build config。

## 停止线

不调用 application singleton accessor；不创建 `NSApplication`；不 activation；不修改 activation policy；不运行 AppKit event loop；不调用 `makeKeyAndOrderFront` / `orderFront`；不调用 production `nextDrawable`；不创建 command buffer / encoder；不 draw；不 `commit` / `present`；不提交 GPU work；不执行 render；不写 renderer state；不扩 public API / public C ABI；不修改 `runtime_state.cj` 或 `runtime/cjgui/cjpm.toml`。

## 下一 opening

若 implementation、owner probe、build、smoke / smoke environment classification 与 scans 全部通过，下一 opening 转为：

`P1 internal Renderer visible-window production harness NSApplication shared-application cleanup / headless safety stop-line reconciliation decision`

该 opening 仍不是 accessor call implementation。

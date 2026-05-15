# P1 内部 Renderer 可见窗口 NSApplication Native Guard 预检 Closure Review

## 复核结论

`NSApplication` native guard preflight 已选择 no-side-effect internal guard route。该路线只允许新增 deterministic integer facts，并继续把 application creation、activation、event loop、native visible order、drawable acquisition、GPU submission、render、renderer state write 与 backend-ready truth 留在停止线外。

## 已确认边界

- 允许新增 internal runtime owner 与 internal native C ABI guard callable。
- 允许新增 probe 与 allowlist 更新。
- 不允许 `NSApplication` singleton creation、activation policy mutation、activation、event loop 或 visible-order side effect。
- 不允许 pointer / handle / `id` / `Class` return。
- 不允许 public API、public diagnostics、`runtime_state.cj` 或 `runtime/cjgui/cjpm.toml` 变更。

## 当前 endpoint

- Upstream：`CjguiInternalRendererVisibleWindowApplicationActivationPolicyReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererVisibleWindowApplicationActivationPolicyDraft()`

## 下一 implementation scope

下一 implementation bundle 只能创建：

- `CjguiInternalRendererVisibleWindowNsApplicationNativeGuardReadiness`
- `cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationNativeGuardDraft()`
- `cjgui_native_bridge_nsapplication_guard_*` no-side-effect integer callables

## Closure 判定

本 closure 不授权直接实现 application creation / activation。它只确认当前链条可以进入 no-side-effect native guard implementation bundle，并要求 implementation 后继续写 manifest stabilization closure 与同步 tracker / README / topic manifests。

# P1 Renderer 可见窗口 NSApplication Shared-Application Accessor Native Guard 预检闭环审查

## 结论

Accessor native guard preflight 已完成，结论为 A：可以进入 internal-only accessor native guard owner，但必须复用既有 no-side-effect shared-application guard C ABI，不新增 native header / source symbol。

## 已确认边界

- 上游 endpoint 是 `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorScopeReadiness`。
- 既有 native evidence 是 `cjgui_native_bridge_nsapplication_shared_application_guard_*` deterministic integer facts。
- 下一刀只能把这些 facts 重新绑定到 accessor scope 之后，证明 accessor call 仍 blocked。
- 不得把 accessor scope facts 或 native guard facts升级为 application-ready、visible-ready、drawable-ready、render-ready、backend-ready、renderer state write、receipt、record 或 publication。

## 停止线复核

本预检未授权 application singleton accessor call、`NSApplication` creation、activation policy mutation、activation、event loop、native visible order implementation、production drawable acquisition、color attachment、encoder、draw、`commit` / `present`、GPU submission、render、renderer state write、public API、public C ABI 或 diagnostics。

## 下一步

`P1 internal Renderer visible-window production harness NSApplication shared-application accessor native guard implementation`

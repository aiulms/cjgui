# P1 内部 Renderer 可见窗口 NSApplication Native Guard 预检 Manifest 稳定化复核

## 稳定化结论

`NSApplication` native guard preflight manifest 已固定 no-side-effect implementation admission、truth、stop-line、canonical upstream 与 downstream next opening。该 manifest 不把 application activation policy facts 升级为 `NSApplication` creation / activation permission，也不把 visible-order native guard facts 包装成 backend-ready truth。

## 当前 canonical upstream

- `CjguiInternalRendererVisibleWindowApplicationActivationPolicyReadiness`
- `cjguiInternalExecuteDefaultRendererVisibleWindowApplicationActivationPolicyDraft()`
- Runtime input：`CjguiInternalRendererVisibleWindowVisibleOrderNativeGuardReadiness`

## 下一 opening

`P1 internal Renderer visible-window production harness NSApplication native guard no-side-effect implementation`

## 未改变项

- 尚未新增 native guard callable 或 runtime owner；它们只在下一 implementation bundle 中被允许。
- 未授权 `NSApplication` creation、activation、event loop、visible order、drawable、encoder、draw、GPU submission、render、renderer state write、backend-ready truth 或 public API。
- 未授权 `runtime/cjgui/cjpm.toml` 或 `runtime_state.cj` 变更。

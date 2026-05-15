# P1 内部 Renderer 可见窗口 Application Activation Policy Value Boundary Manifest 稳定化复核

## 稳定化结论

application activation policy value boundary manifest 已固定新 owner、truth、stop-line、canonical endpoint 与 downstream next opening。该 manifest 不把 application activation policy facts 升级为 `NSApplication` creation / activation permission，也不把 visible-order native guard facts 包装成 backend-ready truth。

## 当前 canonical endpoint

- `CjguiInternalRendererVisibleWindowApplicationActivationPolicyReadiness`
- `cjguiInternalExecuteDefaultRendererVisibleWindowApplicationActivationPolicyDraft()`
- Runtime input：`CjguiInternalRendererVisibleWindowVisibleOrderNativeGuardReadiness`

## 下一 opening

`P1 internal Renderer visible-window production harness NSApplication native guard preflight decision`

## 未改变项

- 未新增 native C ABI / `foreign func`。
- 未修改 production native bridge、`runtime/cjgui/cjpm.toml` 或 `runtime_state.cj`。
- 未授权 `NSApplication` creation、activation、event loop、visible order、drawable、encoder、draw、GPU submission、render、renderer state write、backend-ready truth 或 public API。


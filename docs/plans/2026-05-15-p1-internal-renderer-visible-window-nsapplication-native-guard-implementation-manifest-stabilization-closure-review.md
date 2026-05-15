# P1 内部 Renderer 可见窗口 NSApplication Native Guard Implementation Manifest 稳定化复核

## 稳定化结论

`NSApplication` native guard implementation manifest 已固定新 owner、truth、stop-line、canonical endpoint 与 downstream next opening。该 manifest 不把 native guard facts 升级为 application singleton creation、activation、event loop、visible order、drawable acquisition、GPU submission、render 或 backend-ready truth。

## 当前 canonical endpoint

- `CjguiInternalRendererVisibleWindowNsApplicationNativeGuardReadiness`
- `cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationNativeGuardDraft()`
- Runtime input：`CjguiInternalRendererVisibleWindowApplicationActivationPolicyReadiness`

## 下一 opening

`P1 internal Renderer visible-window production harness NSApplication native guard policy value boundary decision`

## 未改变项

- 未授权 application singleton creation、activation policy mutation、activation、event loop、visible order、drawable、encoder、draw、GPU submission、render、renderer state write、backend-ready truth 或 public API。
- 未修改 `runtime/cjgui/cjpm.toml` 或 `runtime_state.cj`。
- 新增 C ABI 仍是 internal native bridge guard facts，不是 public C ABI。

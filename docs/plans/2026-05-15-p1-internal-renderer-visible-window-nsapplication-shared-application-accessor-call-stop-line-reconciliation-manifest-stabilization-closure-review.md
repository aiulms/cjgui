# P1 内部 Renderer 可见窗口 NSApplication Shared-Application Accessor Call Stop-Line Reconciliation Manifest 稳定化复核

## 稳定化结论

`NSApplication` shared-application accessor call stop-line reconciliation manifest 已固定当前 upstream endpoint、runtime input、canonical endpoint、truth、stop-line 与 downstream next opening。该 manifest 不创建 application-ready truth，也不把 accessor guard policy facts 升级为 application singleton accessor call、application creation、activation policy mutation、activation、event loop、visible order、drawable、render 或 backend-ready permission。

## 当前 canonical endpoint

- `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorGuardPolicyReadiness`
- `cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationAccessorGuardPolicyDraft()`

## Runtime input

- `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorNativeGuardReadiness`

## 下一 opening

`P1 internal Renderer visible-window production harness NSApplication shared-application accessor call preflight decision`

## 未改变项

- 未新增 runtime owner。
- 未新增 native C ABI / `foreign func`。
- 未修改 production native bridge、`runtime/cjgui/cjpm.toml` 或 `runtime_state.cj`。
- 未授权 application singleton accessor call、`NSApplication` creation、activation policy mutation、activation、event loop、visible order、drawable、encoder、draw、GPU submission、render、renderer state write、backend-ready truth 或 public API。

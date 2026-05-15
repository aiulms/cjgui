# P1 内部 Renderer 可见窗口 NSApplication Native Guard Policy Value Boundary 决策 Manifest 稳定化复核

## 稳定化结论

`NSApplication` native guard policy value boundary decision manifest 已固定当前上游、truth、stop-line 与 downstream next opening。该 manifest 不创建新的 runtime truth，也不把 native guard integer facts 升级为 application-ready、visible-ready、drawable-ready、render-ready 或 backend-ready permission。

## 当前 canonical endpoint

- `CjguiInternalRendererVisibleWindowNsApplicationNativeGuardReadiness`
- `cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationNativeGuardDraft()`

## 下一 opening

`P1 internal Renderer visible-window production harness NSApplication native guard policy value boundary bundle implementation`

## 未改变项

- 未新增 runtime owner。
- 未新增 native C ABI / `foreign func`。
- 未修改 production native bridge、`runtime/cjgui/cjpm.toml` 或 `runtime_state.cj`。
- 未授权 `NSApplication` creation、activation policy mutation、activation、event loop、visible order、drawable、encoder、draw、GPU submission、render、renderer state write、backend-ready truth 或 public API。


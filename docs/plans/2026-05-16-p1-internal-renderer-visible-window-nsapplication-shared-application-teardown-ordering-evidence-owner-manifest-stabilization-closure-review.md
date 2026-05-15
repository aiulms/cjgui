# P1 internal Renderer visible-window NSApplication shared-application teardown ordering evidence owner manifest stabilization closure review

状态：manifest stabilization closure / no new runtime implementation

## 封账结论

[teardown ordering evidence owner manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-teardown-ordering-evidence-owner-manifest.md) 已固定 owner、endpoint、default draft、runtime input、truth、stop-line 与 Same-shape Boundary Brake。

当前 canonical endpoint：

- `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationTeardownOrderingEvidenceReadiness`
- `cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationTeardownOrderingEvidenceDraft()`

runtime input：

- `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRunLoopEvidenceReadiness`

## 不变边界

manifest stabilization 不新增代码、不改 native bridge、不新增 public API / public C ABI、不写 renderer state，不授权 actual teardown execution、actual AppKit event loop、bounded run-loop pump、application singleton accessor call、`NSApplication` creation / activation、activation policy mutation、visible order、drawable、render、GPU submission、backend-ready truth 或 public diagnostics。

## 当前唯一 next opening

`P1 internal Renderer visible-window production harness NSApplication shared-application teardown ordering evidence owner stop-line reconciliation decision`

# P1 Renderer visible-window NSApplication shared-application run-loop execution evidence owner stop-line reconciliation next-boundary decision

状态：docs-only / next-boundary decision / no runtime implementation

## 当前端点

- `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRunLoopEvidenceReadiness`
- `cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRunLoopEvidenceDraft()`

runtime input：

- `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationLifecycleEvidenceReadiness`

## 候选

A. teardown ordering evidence owner preflight
B. headless artifact policy hardening preflight
C. side-effect containment evidence hardening preflight
D. actual AppKit event loop / bounded pump implementation preflight
E. actual application singleton accessor call preflight
F. `NSApplication` creation / activation preflight

## 选择

选择 A：`P1 internal Renderer visible-window production harness NSApplication shared-application teardown ordering evidence owner preflight decision`。

理由：run-loop execution evidence owner 已把 event-loop / bounded pump 证据缺口显式化，但它仍不是 teardown ownership proof。下一个最小缺口是 teardown ordering evidence，尤其是 before-visible cleanup、bounded owner shutdown 和 fail-closed ordering 事实。该阶段仍应保持 value-style owner，不进入 actual AppKit event loop 或 accessor call。

## 拒绝项

D/E/F 仍无权限。B/C 是后续候选，但不能越过 teardown ordering evidence owner preflight。当前 endpoint 仍不批准 actual AppKit event loop、bounded run-loop pump、application singleton accessor call、`NSApplication` creation / activation、activation policy mutation、visible order、drawable、render、renderer state write、backend-ready truth、public diagnostics、public API 或 public C ABI。

## 当前唯一 next opening

`P1 internal Renderer visible-window production harness NSApplication shared-application teardown ordering evidence owner preflight decision`

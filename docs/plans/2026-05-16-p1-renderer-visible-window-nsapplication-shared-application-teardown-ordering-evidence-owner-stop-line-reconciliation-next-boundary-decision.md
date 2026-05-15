# P1 Renderer visible-window NSApplication shared-application teardown ordering evidence owner stop-line reconciliation next-boundary decision

状态：docs-only / next-boundary decision / no runtime implementation

## 当前端点

- `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationTeardownOrderingEvidenceReadiness`
- `cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationTeardownOrderingEvidenceDraft()`

runtime input：

- `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRunLoopEvidenceReadiness`

## 候选

A. headless artifact policy evidence owner preflight
B. side-effect containment evidence hardening preflight
C. actual teardown execution preflight
D. actual AppKit event loop / bounded pump implementation preflight
E. actual application singleton accessor call preflight
F. `NSApplication` creation / activation preflight

## 选择

选择 A：`P1 internal Renderer visible-window production harness NSApplication shared-application headless artifact policy evidence owner preflight decision`。

理由：teardown ordering evidence 已被 value-style owner 明确建模；下一个最小缺口是 headless artifact policy evidence。它仍必须先作为 evidence owner 固定 CI/headless artifact、non-user-visible mode、fail-closed artifact route 与 no-backend-ready truth，不能直接进入 actual teardown、event loop、accessor call 或 visible-order work。

## 拒绝项

C/D/E/F 仍无权限。B 是后续候选，但不能越过 headless artifact policy evidence owner preflight。当前 endpoint 仍不批准 actual teardown execution、actual AppKit event loop、bounded run-loop pump、application singleton accessor call、`NSApplication` creation / activation、activation policy mutation、visible order、drawable、render、renderer state write、backend-ready truth、public diagnostics、public API 或 public C ABI。

## 当前唯一 next opening

`P1 internal Renderer visible-window production harness NSApplication shared-application headless artifact policy evidence owner preflight decision`

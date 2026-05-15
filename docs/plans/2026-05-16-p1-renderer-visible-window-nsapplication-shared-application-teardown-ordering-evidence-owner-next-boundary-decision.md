# P1 Renderer visible-window NSApplication shared-application teardown ordering evidence owner next-boundary decision

状态：next-boundary decision / implementation follow-up / no new runtime implementation

## 当前端点

当前 canonical endpoint：

- `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationTeardownOrderingEvidenceReadiness`
- `cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationTeardownOrderingEvidenceDraft()`

runtime input：

- `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRunLoopEvidenceReadiness`

## 候选

A. teardown ordering evidence owner stop-line reconciliation decision
B. headless artifact policy hardening preflight decision
C. side-effect containment evidence hardening preflight decision
D. actual teardown execution preflight decision
E. actual AppKit event loop / bounded pump implementation preflight decision
F. actual application singleton accessor call preflight decision

## 选择

选择 A：先做 teardown ordering evidence owner stop-line reconciliation。

理由：本阶段新增了 teardown ordering evidence owner 与 probe，需要先确认 endpoint 是否足够作为 current teardown ordering evidence boundary，避免把 teardown-ordering facts 误读成 teardown execution、event-loop permission、bounded pump permission 或 accessor call permission。

## 拒绝项

D/E/F 仍无权限。B/C 是下游候选，但不能越过 teardown ordering evidence owner stop-line reconciliation。当前 endpoint 不批准 actual teardown execution、actual AppKit event loop、bounded run-loop pump、application singleton accessor call、`NSApplication` creation / activation、activation policy mutation、visible order、drawable、render、renderer state write、backend-ready truth、public diagnostics、public API 或 public C ABI。

## 当前唯一 next opening

`P1 internal Renderer visible-window production harness NSApplication shared-application teardown ordering evidence owner stop-line reconciliation decision`

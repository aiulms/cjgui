# P1 Renderer visible-window NSApplication shared-application run-loop execution evidence owner next-boundary decision

状态：next-boundary decision / implementation follow-up / no new runtime implementation

## 当前端点

当前 canonical endpoint：

- `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRunLoopEvidenceReadiness`
- `cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRunLoopEvidenceDraft()`

runtime input：

- `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationLifecycleEvidenceReadiness`

## 候选

A. run-loop execution evidence owner stop-line reconciliation decision
B. teardown ordering evidence owner preflight decision
C. headless artifact policy hardening preflight decision
D. side-effect containment evidence hardening preflight decision
E. actual AppKit event loop / bounded pump implementation preflight decision
F. actual application singleton accessor call preflight decision

## 选择

选择 A：先做 run-loop execution evidence owner stop-line reconciliation。

理由：本阶段新增了 run-loop evidence owner 与 probe，需要先确认 endpoint 是否足够作为 current run-loop evidence boundary，避免把 evidence facts 误读成 event-loop permission、bounded pump permission 或 accessor call permission。

## 拒绝项

E/F 仍无权限。B/C/D 是下游候选，但不能越过 run-loop evidence owner stop-line reconciliation。当前 endpoint 不批准 actual AppKit event loop、bounded run-loop pump、application singleton accessor call、`NSApplication` creation / activation、visible order、drawable、render、renderer state write、backend-ready truth、public API 或 public C ABI。

## 当前唯一 next opening

`P1 internal Renderer visible-window production harness NSApplication shared-application run-loop execution evidence owner stop-line reconciliation decision`

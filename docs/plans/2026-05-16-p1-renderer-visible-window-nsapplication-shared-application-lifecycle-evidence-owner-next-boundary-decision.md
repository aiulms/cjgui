# P1 Renderer visible-window NSApplication shared-application lifecycle evidence owner next-boundary decision

状态：next-boundary decision / implementation follow-up / no new runtime implementation

## 当前端点

当前 canonical endpoint：

- `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationLifecycleEvidenceReadiness`
- `cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationLifecycleEvidenceDraft()`

runtime input：

- `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCleanupHeadlessSafetyReadiness`

## 候选

A. lifecycle evidence owner stop-line reconciliation decision
B. bounded run-loop execution evidence owner preflight decision
C. teardown ordering evidence owner preflight decision
D. actual application singleton accessor call preflight decision
E. `NSApplication` creation / activation preflight decision

## 选择

选择 A：先做 lifecycle evidence owner stop-line reconciliation。

理由：本阶段新增了 runtime owner 与 probe，需要先确认它是否足够作为当前 lifecycle evidence endpoint，避免马上把 lifecycle facts误读成 run-loop permission、teardown permission 或 accessor call permission。

## 拒绝项

B/C 可作为 stop-line reconciliation 后的下游候选；D/E 仍无权限。当前 endpoint 不批准 actual application singleton accessor call、`NSApplication` creation / activation、activation policy mutation、AppKit event loop、native visible order、production drawable、render、renderer state write、backend-ready truth、public API 或 public C ABI。

## 当前唯一 next opening

`P1 internal Renderer visible-window production harness NSApplication shared-application lifecycle evidence owner stop-line reconciliation decision`

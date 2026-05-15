# P1 Renderer visible-window NSApplication shared-application lifecycle evidence owner stop-line reconciliation next-boundary decision

状态：docs-only / next-boundary decision / no runtime implementation

## 当前端点

- `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationLifecycleEvidenceReadiness`
- `cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationLifecycleEvidenceDraft()`

## 候选

A. run-loop execution evidence owner preflight
B. teardown ordering evidence owner preflight
C. headless artifact policy hardening preflight
D. side-effect containment evidence hardening preflight
E. actual application singleton accessor call preflight
F. `NSApplication` creation / activation preflight

## 选择

选择 A：`P1 internal Renderer visible-window production harness NSApplication shared-application run-loop execution evidence owner preflight decision`。

理由：lifecycle owner gap 已被 value-style owner 明确建模；下一个最小缺口是 run-loop execution evidence。它仍必须先做 evidence owner preflight，不能直接进入 AppKit event loop、bounded pump implementation 或 actual accessor call。

## 拒绝项

E/F 仍无权限。B/C/D 是后续候选，但不能越过 run-loop execution evidence owner preflight。当前 endpoint 仍不批准 event loop implementation、visible order、drawable、render、renderer state write、backend-ready truth、public API 或 public C ABI。

## 当前唯一 next opening

`P1 internal Renderer visible-window production harness NSApplication shared-application run-loop execution evidence owner preflight decision`

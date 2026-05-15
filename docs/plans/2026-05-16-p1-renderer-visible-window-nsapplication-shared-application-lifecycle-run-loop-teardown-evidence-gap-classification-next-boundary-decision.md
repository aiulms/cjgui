# P1 Renderer visible-window NSApplication shared-application lifecycle / run-loop / teardown evidence gap classification next-boundary decision

状态：docs-only / next-boundary decision / no runtime implementation

## 当前端点

当前 canonical endpoint 保持：

- `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCleanupHeadlessSafetyReadiness`
- `cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationCleanupHeadlessSafetyDraft()`

runtime input 保持：

- `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentPolicyReadiness`

## 候选

A. lifecycle evidence owner preflight
B. bounded run-loop evidence owner preflight
C. teardown ordering evidence owner preflight
D. headless artifact policy hardening preflight
E. actual `sharedApplication` accessor call preflight
F. `NSApplication` creation / activation preflight
G. event loop implementation preflight

## 选择

选择 A：`P1 internal Renderer visible-window production harness NSApplication shared-application lifecycle evidence owner preflight decision`。

理由：classification 已指出 lifecycle owner gap 是最上游缺口；若未来需要 runtime owner，也应先证明 owner scope、truth、stop-line 和 Same-shape Boundary Brake，而不是直接拆 run loop、teardown 或 accessor call。

## 拒绝项

本阶段拒绝 E/F/G。actual `sharedApplication` call、`NSApplication` creation / activation 与 event loop 仍没有权限。B/C/D 可作为 A 的下游备选，但不能越过 lifecycle owner preflight。

## 当前唯一 next opening

`P1 internal Renderer visible-window production harness NSApplication shared-application lifecycle evidence owner preflight decision`

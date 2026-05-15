# P1 Renderer NSApplication shared-application accessor call containment policy 下一边界决策

状态：next-boundary decision / docs-only stop-line reconciliation

## 决策

选择 A 路线：下一阶段进入 `P1 internal Renderer visible-window production harness NSApplication shared-application accessor call containment stop-line reconciliation decision`。

## 已有上游

当前 canonical endpoint 是 `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentPolicyReadiness` / `cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentPolicyDraft()`，runtime input 是 `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentReadiness`。

## 下一刀允许

下一刀只允许 docs-only stop-line reconciliation：

- 复核 containment policy facts 是否足够作为后续 stage 的唯一 runtime input。
- 明确 actual application singleton accessor call 仍 blocked。
- 明确 `NSApplication` creation / activation / activation policy mutation / event loop / native visible order / drawable / render / backend-ready truth 仍 blocked。
- 判定是否需要继续做 no-call admission 或保持 stop-line。

## 下一刀禁止

不得新增 runtime owner、native C ABI、`foreign func`、public API、public C ABI、diagnostics、probe、renderer state write、actual `sharedApplication` call、`NSApplication` creation、activation policy mutation、activation、event loop、native visible-order implementation、drawable acquisition、color attachment、encoder、draw、`commit`、`present`、GPU submission、render 或 backend-ready truth。

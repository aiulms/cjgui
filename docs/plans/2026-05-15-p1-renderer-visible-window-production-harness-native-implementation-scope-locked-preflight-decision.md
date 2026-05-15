# Renderer visible-window production harness native implementation 范围锁定预检裁定

## 裁定状态

状态：docs-only / scope-locked preflight / no native harness

本轮读取到的当前唯一 next opening 是：

`P1 internal Renderer visible-window production harness native implementation preflight decision`

用户在本轮明确追加约束：仍只做 visible-window production harness policy value boundary，不进入 native `NSWindow` harness。

因此本轮不能把 native implementation preflight 解释为 native harness 写集批准，也不能提前打开 production native bridge、`NSWindow` ownership implementation、bounded run loop implementation 或 production drawable acquire。

## 本轮裁定

选择 S 路线：scope-locked docs-only preflight reconciliation。

本轮只确认：

- policy value boundary 已经有 internal owner 与 manifest。
- 当前仓库文档把下一步指向 native implementation preflight decision。
- 在最新用户约束下，该 preflight 不能批准 implementation。
- native `NSWindow` harness 需要后续显式 scope unlock decision 才能继续。

本轮不批准：

- production native `.h` / `.m` 写集。
- native `NSWindow` harness。
- production `nextDrawable`。
- drawable acquire / release。
- color attachment。
- command buffer / render command encoder。
- encoder binding。
- draw。
- `commit` / `present`。
- GPU submission。
- render。
- renderer state write。
- public API / public diagnostics。

## 上游 truth

上游仍以 [visible-window production harness policy value boundary 清单](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-15-p1-renderer-visible-window-production-harness-policy-value-boundary-manifest.md) 为准。

当前 runtime endpoint 仍是：

- `CjguiInternalRendererNoVisibleWindowProductionHarnessReadiness`
- `cjguiInternalExecuteDefaultRendererVisibleWindowProductionHarnessDraft()`

该 endpoint 只表示 policy value facts，不是 native harness readiness、drawable-ready、render permission、GPU submission permission、backend-ready truth 或 renderer state write permission。

## 被锁住的实现范围

在用户显式解除本轮范围锁之前，后续自动化不得把本 preflight 当作 native implementation approval。

仍被锁住的范围包括：

- `NSWindow` / `NSApplication` production harness creation。
- production visible-window run loop ownership implementation。
- production `nextDrawable` acquire / classify / release。
- production drawable texture lifetime implementation。
- `MTLRenderPassDescriptor.colorAttachments[0]` 绑定。
- render command encoder creation。
- `setRenderPipelineState` / `setVertexBuffer` / draw。
- command buffer `commit`。
- drawable `present`。
- GPU submission / render execution。
- renderer state mutation。

## 后续唯一入口

`P1 internal Renderer visible-window production harness native NSWindow harness scope unlock decision`

该后续入口仍应是 docs-only decision。只有它显式解除“只做 policy value boundary”的范围锁，并重新列出允许写集、native C ABI、probe、verification 与 stop-line 后，才可以再进入真正的 native implementation preflight。

## 设计意图出口自检

- 本轮是否改变主题状态：是。native implementation preflight 在当前用户约束下被锁定为 docs-only reconciliation，不批准 implementation。
- 本轮是否改变 canonical tail / endpoint：否。仍使用 `CjguiInternalRendererNoVisibleWindowProductionHarnessReadiness` / `cjguiInternalExecuteDefaultRendererVisibleWindowProductionHarnessDraft()`。
- 本轮是否改变 owner / truth / stop-line：是。truth 增加“scope lock 未解除前不得把 native preflight 当 implementation approval”；stop-line 不放宽。
- 本轮是否改变唯一 next opening：是。后续转为 explicit scope unlock decision。
- 是否同步 topic manifest：需要同步 `renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md` 与 `macos-bridge-verification-smoke.md`。

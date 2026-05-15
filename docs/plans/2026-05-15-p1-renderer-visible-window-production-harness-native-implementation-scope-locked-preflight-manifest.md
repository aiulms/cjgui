# Renderer visible-window production harness native implementation 范围锁定预检清单

## 清单状态

状态：docs-only / scope lock / no implementation approval

本清单固定 native implementation preflight 在当前用户约束下的结论：仍只允许 visible-window production harness policy value boundary，不进入 native `NSWindow` harness。

## 上游固定点

- [visible-window production harness policy value boundary 清单](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-15-p1-renderer-visible-window-production-harness-policy-value-boundary-manifest.md)
- [visible-window production harness policy value boundary 下一边界裁定](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-15-p1-renderer-visible-window-production-harness-policy-value-boundary-next-boundary-decision.md)
- [visible-window production harness policy value boundary 收束复核](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-15-p1-internal-renderer-visible-window-production-harness-policy-value-boundary-closure-review.md)

## Canonical endpoint 固定点

- `CjguiInternalRendererNoVisibleWindowProductionHarnessReadiness`
- `cjguiInternalExecuteDefaultRendererVisibleWindowProductionHarnessDraft()`

## 当前 truth

当前 truth 只新增一条范围事实：

- native implementation preflight 已被当前用户约束锁定为 docs-only reconciliation，不批准 implementation。

除此以外，truth 仍完全继承 policy value boundary：

- visible-window production harness policy facts 已落地。
- native `NSWindow` harness 未实现。
- production `nextDrawable` 未批准。
- drawable acquire / color attachment / encoder / draw / `commit` / `present` / GPU submission / render 未批准。
- renderer state write 未批准。
- public API / public diagnostics 未批准。

## Stop-line 边界

本清单不放宽任何 stop-line。

仍不得：

- 修改 `runtime/cjgui/cjpm.toml`。
- 修改 `runtime/cjgui/src/runtime_state.cj`。
- 修改 smoke native files。
- 修改 production native `.h` / `.m`。
- 新增 native C ABI。
- 新增 `foreign func`。
- 新增 probe script。
- 创建 production `NSWindow` / `NSApplication`。
- 调用 production `nextDrawable`。
- 保存或返回 native pointer / handle / `id` / `Class`。
- 配置 `colorAttachments[0]`。
- 创建 command buffer / render command encoder。
- 调用 `setRenderPipelineState` / `setVertexBuffer`。
- 调用 `drawPrimitives` / `drawIndexedPrimitives`。
- 调用 `commit` / `present`。
- 提交 GPU work。
- 执行 render。
- 写 renderer state。
- 新增 public API / public diagnostics。

## Same-shape Boundary Brake 自检

本阶段不是新增 runtime wrapper，也不是把 policy endpoint 再包装成 receipt / record / publication。

本阶段只把当前 next opening 的解释范围收窄为“需要 explicit scope unlock”，避免自动化在用户明确禁止 native harness 的情况下继续堆叠 native implementation 文档或代码。

## 当前最终 next opening

`P1 internal Renderer visible-window production harness native NSWindow harness scope unlock decision`

## 设计意图出口自检

- 本轮是否改变主题状态：是。native implementation preflight 被 scope lock 截住。
- 本轮是否改变 canonical tail / endpoint：否。
- 本轮是否改变 owner / truth / stop-line：是。新增 scope lock truth；stop-line 未放宽。
- 本轮是否改变唯一 next opening：是。后续必须先做 scope unlock decision。
- 是否同步 topic manifest：需要同步。

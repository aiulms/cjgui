# MTLCommandBuffer 创建后续边界结论

日期：2026-05-11

## 当前固定尾点

- Endpoint：`CjguiInternalRendererNoCommandBufferRuntimeCallReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererCommandBufferRuntimeCallDraft()`
- Runtime input：`CjguiInternalRendererNoCommandBufferCreateDestroyReadiness`
- Upstream input：`CjguiInternalRendererNoCommandQueueRuntimeCallReadiness`

## 候选判断

选择 A：

`P1 internal Renderer command buffer creation runway manifest stabilization bundle`

选择理由：

- Native command buffer probe 已覆盖 create、classify、destroy、double destroy、invalid token、background-thread deny、occupied count cleanup 与 queue destroy ordering。
- Runtime-adjacent FFI call probe 已覆盖 device / queue / buffer local lifecycle，并确认 token 未持久化。
- `cjpm build --skip-script` 可构建新增 runtime owners。
- 当前证据足够封账 command buffer runtime call owner，但不足以打开 render pass descriptor implementation。

拒绝候选：

- 直接创建 render pass descriptor：尚未进入下一阶段 preflight。
- 创建 encoder / commit / present / GPU submission / render：未进入本阶段许可。
- public API / renderer state write：未进入本阶段许可。

## 后续入口

唯一后续入口当时固定为：

`P1 internal Renderer render pass descriptor planning preflight decision`

该后续入口仍只能先评估 render pass descriptor prerequisites，不代表允许创建 encoder、调用 `commit` / `present`、GPU submission、render execution 或 renderer state write。当前已由 [MTLRenderPassDescriptor 路线封账清单](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-render-pass-descriptor-runway-manifest.md) 接续，新的唯一 next opening 是 `P1 internal Renderer render pass descriptor color attachment preflight decision`。

## 设计意图出口自检

- 本轮是否改变主题状态：是，command buffer runtime call owner 已具备封账条件。
- 本轮是否改变 canonical tail / endpoint：是，tail 固定为 `CjguiInternalRendererNoCommandBufferRuntimeCallReadiness`。
- 本轮是否改变 owner / truth / stop-line：是，owner 固定为 command buffer create / destroy 与 runtime call owners；truth 不越界到 render pass / encoder / commit / present；stop-line 继续禁止 GPU / render / state / public。
- 本轮是否改变唯一 next opening：是，当时唯一 next opening 固定为 `P1 internal Renderer render pass descriptor planning preflight decision`；现已由 render pass descriptor runway 接续。
- 是否同步 topic manifest：需要并已纳入本阶段同步清单。
- 已同步哪些 topic manifest：`renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。

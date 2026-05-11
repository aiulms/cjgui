# MTLCommandQueue 创建后续边界结论

日期：2026-05-11

## 当前固定尾点

- Endpoint：`CjguiInternalRendererNoCommandQueueRuntimeCallReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererCommandQueueRuntimeCallDraft()`
- Runtime input：`CjguiInternalRendererNoCommandQueueCreateDestroyReadiness`
- Upstream input：`CjguiInternalRendererNoDrawableNoPresentAcquisitionReadiness`

## 候选判断

选择 A：

`P1 internal Renderer command queue creation runway manifest stabilization bundle`

选择理由：

- Native queue create / destroy probe 已覆盖 create、classify、destroy、double destroy、invalid token、background-thread deny、occupied count cleanup 与 device destroy ordering。
- Runtime-adjacent FFI call probe 已覆盖 device create、queue create、classify、command-buffer-still-blocked、queue destroy、double destroy 与 cleanup。
- `cjpm build --skip-script` 可构建新增 runtime owners。
- 当前证据足够封账 command queue runtime call owner，但不足以打开 command buffer creation implementation。

拒绝候选：

- 直接创建 command buffer：未进入本阶段许可。
- 直接提交 GPU work / render：未进入本阶段许可。
- public API / renderer state write：未进入本阶段许可。

## 后续入口

唯一后续入口固定为：

`P1 internal Renderer command buffer creation planning preflight decision`

该后续入口仍只能先评估 command buffer creation prerequisites，不代表允许调用 `commandBuffer`、创建 encoder、commit、present、GPU submission 或 render。

## 设计意图出口自检

- 本轮是否改变主题状态：是，command queue runtime call owner 已具备封账条件。
- 本轮是否改变 canonical tail / endpoint：是，tail 固定为 `CjguiInternalRendererNoCommandQueueRuntimeCallReadiness`。
- 本轮是否改变 owner / truth / stop-line：是，owner 固定为 command queue create / destroy 与 runtime call owners；truth 不越界到 command buffer；stop-line 继续禁止 GPU / render / state / public。
- 本轮是否改变唯一 next opening：是，唯一 next opening 固定为 `P1 internal Renderer command buffer creation planning preflight decision`。
- 是否同步 topic manifest：需要并已纳入本阶段同步清单。
- 已同步哪些 topic manifest：`renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。

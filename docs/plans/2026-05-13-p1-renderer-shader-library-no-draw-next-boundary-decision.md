# Shader library no-draw 下一步结论

日期：2026-05-13

状态：next-boundary / selected

## 候选

- A：`P1 internal Renderer shader library no-draw manifest stabilization bundle`
- B：`P1 internal Renderer pipeline state create/destroy no-draw preflight decision`
- C：`P1 internal Renderer shader library runtime call recovery decision`
- D：拒绝：直接创建 `MTLRenderPipelineState`、encoder、draw、commit、present、GPU submission 或 render。

## 选择

选择 A 完成 manifest stabilization，并在封账后唯一打开 B：`P1 internal Renderer pipeline state create/destroy no-draw preflight decision`。

理由：shader source contract、token-backed `MTLLibrary`、vertex / fragment `MTLFunction` lookup、runtime internal call 与 cleanup facts 已成立；下一步可以评估 pipeline state no-draw create/destroy，但必须重新预检 shader function 与 pipeline descriptor 的绑定合同。

## 继续禁止

本结论不授予 pipeline state 创建权限，不授予 encoder / draw / commit / present / GPU submission / render 权限，不授予 renderer state write 或 backend-ready truth。

## 设计意图出口自检

- 本轮是否改变主题状态：是，shader library no-draw 进入 manifest stabilization。
- 本轮是否改变 canonical tail / endpoint：是，尾点为 `CjguiInternalRendererNoShaderLibraryRuntimeCallReadiness`。
- 本轮是否改变 owner / truth / stop-line：否，truth 仍是 internal no-draw facts，stop-line 不放宽。
- 本轮是否改变唯一 next opening：是，固定为 `P1 internal Renderer pipeline state create/destroy no-draw preflight decision`。
- 是否同步 topic manifest：将在 manifest 同步。
- 已同步哪些 topic manifest：待同步。

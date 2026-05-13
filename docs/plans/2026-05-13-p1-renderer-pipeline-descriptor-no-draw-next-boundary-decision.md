# Pipeline descriptor no-draw 后续入口判断

日期：2026-05-13

状态：选择 shader library no-draw planning

## 当前尾点

当前 canonical endpoint 是 `CjguiInternalRendererNoPipelineDescriptorRuntimeCallReadiness`，default draft 是 `cjguiInternalExecuteDefaultRendererPipelineDescriptorRuntimeCallDraft()`，owner 是 [runtime_renderer_pipeline_descriptor_runtime_call.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_pipeline_descriptor_runtime_call.cj)。

## 候选判断

- 选择 A：`P1 internal Renderer shader library no-draw planning preflight decision`。
- 暂缓 B：`P1 internal Renderer pipeline state create/destroy no-draw preflight decision`，因为还没有 shader library / function facts。
- 暂缓 C：`P1 internal Renderer render command encoder planning preflight decision`，因为 drawable texture lifetime 与 color attachment 仍未成立。
- 拒绝 D：直接创建 pipeline state、encoder、draw、commit、present、GPU submission 或 public API。

## 选择原因

Pipeline descriptor 已经具备 token-backed create/destroy、no-draw configuration 与 runtime internal call facts。下一缺口不是 encoder，而是 shader library / vertex function / fragment function 的 no-draw planning。先进入 shader library planning 可以继续推进 pipeline contracts，同时保持不绑定 encoder、不 draw、不提交 GPU work。

## 已接续

已由 [shader library no-draw 清单](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-13-p1-renderer-shader-library-no-draw-manifest.md) 接续。当前唯一后续入口更新为：

`P1 internal Renderer pipeline state create/destroy no-draw preflight decision`

## 设计意图出口自检

- 本轮改变主题状态：是，pipeline descriptor no-draw 已封到 runtime call facts。
- 本轮改变 canonical tail / endpoint：是，tail 为 `CjguiInternalRendererNoPipelineDescriptorRuntimeCallReadiness`。
- 本轮改变 owner / truth / stop-line：是，后续 truth 转向 shader library no-draw planning；当前 stop-line 不变。
- 本轮改变唯一 next opening：是，当时转为 `P1 internal Renderer shader library no-draw planning preflight decision`；当前已由 shader library no-draw 接续并更新为 `P1 internal Renderer pipeline state create/destroy no-draw preflight decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。

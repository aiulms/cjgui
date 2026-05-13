# Pipeline descriptor no-draw 预检判断

日期：2026-05-13

状态：选择 A/B/C/D，允许进入 token-backed descriptor first slice

## 背景

上游 [pipeline state no-draw planning 清单](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-12-p1-renderer-pipeline-state-no-draw-planning-manifest.md) 已固定 `CjguiInternalRendererNoPipelineStateNoDrawPlanningReadiness`，并把 shader library、vertex function、fragment function、pipeline descriptor、pipeline state 与 encoder binding 的依赖拆开。本阶段 runtime input 固定为该 endpoint，上游 owner 是 [runtime_renderer_pipeline_state_no_draw_planning.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_pipeline_state_no_draw_planning.cj)。

## 预检结论

本轮选择 A/B/C/D：

- A：新增 pipeline descriptor planning owner，固定 `MTLRenderPipelineDescriptor` requirement facts。
- B：实现 token-backed `MTLRenderPipelineDescriptor` create/destroy first slice。
- C：实现 descriptor no-draw configuration facts：color pixel format、sample count、shader still-blocked、blending still-blocked、encoder binding still-blocked。
- D：新增 runtime internal FFI call owner，局部调用 create → configure → classify → destroy → double destroy。

本轮拒绝项保持不变：不创建 `MTLRenderPipelineState`，不创建 `MTLLibrary` / `MTLFunction`，不创建 render command encoder，不调用 `setRenderPipelineState`，不 draw，不创建 vertex buffer，不 `commit`，不 `present`，不提交 GPU work，不执行 render，不写 renderer state。

## 关键判断

- `MTLRenderPipelineDescriptor` 是 descriptor object，不是 pipeline state；创建它不会提交 GPU work，也不要求 encoder。
- Descriptor token 仍是 opaque integer，来自 token table，不是 pointer cast；native C ABI 不返回 pointer / handle / `id` / `Class`。
- Descriptor table 固定小容量，仅保存 bridge-local descriptor object；renderer 侧只接收 dehydrated facts，不成为 backend-ready truth。
- No-draw configuration 只设置 color pixel format 与 sample count；shader library/function 均保持 still-blocked。
- Blending 与 encoder binding 保持 blocked；不允许把 descriptor configuration 包装成 render permission。
- Runtime owner 中 token 只在函数局部存在，不写 module-level mutable var，不写 `runtime_state.cj`，不扩 public API。

## GitNexus 记录

对上游和新增符号运行 impact：

- `CjguiInternalRendererNoPipelineStateNoDrawPlanningReadiness`：not found / impactedCount `0` / risk `UNKNOWN`。
- `cjguiInternalExecuteDefaultRendererPipelineStateNoDrawPlanningDraft`：not found / impactedCount `0` / risk `UNKNOWN`。
- `CjguiInternalRendererNoPipelineDescriptorCreateDestroyReadiness`：not found / impactedCount `0` / risk `UNKNOWN`。
- `CjguiInternalRendererNoPipelineDescriptorConfigurationReadiness`：not found / impactedCount `0` / risk `UNKNOWN`。
- `CjguiInternalRendererNoPipelineDescriptorRuntimeCallReadiness`：not found / impactedCount `0` / risk `UNKNOWN`。
- `cjgui_native_bridge_pipeline_descriptor_create` / `destroy` / `configure_no_draw`：not found / impactedCount `0` / risk `UNKNOWN`。

该结果说明近期新增 owner / C ABI 尚未被图索引覆盖，不视为安全证明。本轮用源码阅读、`cjpm build`、native probes、runtime-adjacent FFI probe、forbidden scan 与 manifest 检查兜底。

## 停止线

不创建 `MTLRenderPipelineState`，不创建 `MTLLibrary` / `MTLFunction`，不创建 render command encoder，不调用 `setRenderPipelineState`，不 draw，不调用 `drawPrimitives` / `drawIndexedPrimitives`，不创建 vertex buffer，不 `commit`，不 `present`，不提交 GPU work，不执行 render，不写 renderer state，不触碰 `runtime_state.cj`，不修改 `runtime/cjgui/cjpm.toml`，不修改 smoke native files，不新增 public API / diagnostics，不返回 pointer / handle / `id` / `Class`。

## 选择结果

新增 runtime owner：

- [runtime_renderer_pipeline_descriptor_planning.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_pipeline_descriptor_planning.cj)
- [runtime_renderer_pipeline_descriptor_create_destroy.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_pipeline_descriptor_create_destroy.cj)
- [runtime_renderer_pipeline_descriptor_configuration.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_pipeline_descriptor_configuration.cj)
- [runtime_renderer_pipeline_descriptor_runtime_call.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_pipeline_descriptor_runtime_call.cj)

Canonical endpoint：

- `CjguiInternalRendererNoPipelineDescriptorRuntimeCallReadiness`

Default draft：

- `cjguiInternalExecuteDefaultRendererPipelineDescriptorRuntimeCallDraft()`

唯一后续入口：

`P1 internal Renderer shader library no-draw planning preflight decision`

## 设计意图出口自检

- 本轮改变主题状态：是，Renderer implementation admission chain 从 pipeline state no-draw planning 进入 pipeline descriptor no-draw runtime call。
- 本轮改变 canonical tail / endpoint：是，新增 pipeline descriptor runtime call endpoint。
- 本轮改变 owner / truth / stop-line：是，新增 planning / create-destroy / configuration / runtime-call owners；stop-line 继续禁止 pipeline state、shader library/function、encoder、draw、commit、present、GPU submission 与 render。
- 本轮改变唯一 next opening：是，转为 `P1 internal Renderer shader library no-draw planning preflight decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。

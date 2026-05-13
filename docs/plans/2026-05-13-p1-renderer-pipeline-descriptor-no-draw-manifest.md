# Pipeline descriptor no-draw 清单

日期：2026-05-13

状态：manifest / completed through B/C/D runtime internal call facts

## 固定尾点

- Endpoint：`CjguiInternalRendererNoPipelineDescriptorRuntimeCallReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererPipelineDescriptorRuntimeCallDraft()`
- Stage upstream input：`CjguiInternalRendererNoPipelineStateNoDrawPlanningReadiness`
- Runtime immediate input：`CjguiInternalRendererNoPipelineDescriptorConfigurationReadiness`
- Upstream owner：[runtime_renderer_pipeline_state_no_draw_planning.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_pipeline_state_no_draw_planning.cj)
- Owner：[runtime_renderer_pipeline_descriptor_runtime_call.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_pipeline_descriptor_runtime_call.cj)

## 实际路线

本阶段完成 A/B/C/D：

- Pipeline descriptor planning / requirement facts。
- Token-backed `MTLRenderPipelineDescriptor` create/destroy first slice。
- Descriptor no-draw configuration facts：color pixel format、sample count、shader still-blocked、blending still-blocked、encoder binding still-blocked。
- Runtime internal FFI call owner 与 runtime-adjacent verification。

## Native callable

- `cjgui_native_bridge_pipeline_descriptor_table_capacity`
- `cjgui_native_bridge_pipeline_descriptor_table_enabled`
- `cjgui_native_bridge_pipeline_descriptor_table_occupied_count`
- `cjgui_native_bridge_pipeline_descriptor_create`
- `cjgui_native_bridge_pipeline_descriptor_destroy`
- `cjgui_native_bridge_pipeline_descriptor_token_classify`
- `cjgui_native_bridge_pipeline_descriptor_double_destroy_classify`
- `cjgui_native_bridge_pipeline_descriptor_create_requires_main_thread`
- `cjgui_native_bridge_pipeline_descriptor_destroy_requires_main_thread`
- `cjgui_native_bridge_pipeline_descriptor_configure_requires_main_thread`
- `cjgui_native_bridge_pipeline_descriptor_configure_no_draw`
- `cjgui_native_bridge_pipeline_descriptor_color_pixel_format_classify`
- `cjgui_native_bridge_pipeline_descriptor_sample_count_classify`
- `cjgui_native_bridge_pipeline_descriptor_shader_library_still_blocked`
- `cjgui_native_bridge_pipeline_descriptor_vertex_function_still_blocked`
- `cjgui_native_bridge_pipeline_descriptor_fragment_function_still_blocked`
- `cjgui_native_bridge_pipeline_descriptor_blending_still_blocked`
- `cjgui_native_bridge_pipeline_descriptor_encoder_binding_still_blocked`
- `cjgui_native_bridge_pipeline_state_creation_still_blocked`

## 固定事实

- Descriptor table 固定小容量，token 是 opaque integer，不是 pointer cast。
- Descriptor create/destroy 必须 main-thread，destroy 后 token stale，double destroy fail-closed。
- Descriptor configuration 只允许 color pixel format 与 sample count facts。
- Shader library、vertex function、fragment function、pipeline state creation、blending 与 encoder binding 仍 blocked。
- Runtime call owner 只在函数局部使用 token，不持久化，不写 renderer state，不返回 token 到 public surface。

## 停止线

不创建 `MTLRenderPipelineState`，不创建 `MTLLibrary` / `MTLFunction`，不创建 render command encoder，不调用 `setRenderPipelineState`，不 draw，不创建 vertex buffer，不 `commit`，不 `present`，不提交 GPU work，不执行 render，不写 renderer state，不触碰 `runtime_state.cj`，不修改 `runtime/cjgui/cjpm.toml`，不修改 smoke native files，不新增 public API / diagnostics，不返回 pointer / handle / `id` / `Class`。

## 上游与下游

上游固定：

- [pipeline state no-draw planning 清单](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-12-p1-renderer-pipeline-state-no-draw-planning-manifest.md)
- [encoder 创建阻塞归因清单](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-render-command-encoder-creation-blocker-reconciliation-manifest.md)
- [Metal device binding runway 清单](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-metal-device-binding-runway-manifest.md)
- [command buffer creation runway 清单](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-command-buffer-creation-runway-manifest.md)

下游已接续：

- [shader library no-draw 清单](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-13-p1-renderer-shader-library-no-draw-manifest.md)

当前唯一后续入口：

`P1 internal Renderer pipeline state create/destroy no-draw preflight decision`

## GitNexus 记录

上游 endpoint / default draft 与新增 symbols 在当前索引中返回 `UNKNOWN` / not found / impactedCount `0`。本清单使用源码、build、probe、scan 与文档链兜底，不把图缺口解释为安全证明。

## 设计意图出口自检

- 本轮改变主题状态：是，pipeline descriptor no-draw 从 planning runway 推进到 create/destroy、configuration 与 runtime internal call facts。
- 本轮改变 canonical tail / endpoint：是，尾点固定为 `CjguiInternalRendererNoPipelineDescriptorRuntimeCallReadiness`。
- 本轮改变 owner / truth / stop-line：是，新增 owner 只表达 descriptor no-draw lifecycle/config/runtime-local facts；stop-line 继续禁止 pipeline state、shader library/function、encoder、draw、commit、present、GPU submission、render、renderer state 与 public API。
- 本轮改变唯一 next opening：是，当时唯一后续入口固定为 `P1 internal Renderer shader library no-draw planning preflight decision`；当前已由 shader library no-draw 接续并更新为 `P1 internal Renderer pipeline state create/destroy no-draw preflight decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。

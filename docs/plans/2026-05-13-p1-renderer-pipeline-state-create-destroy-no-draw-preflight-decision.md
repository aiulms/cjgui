# Pipeline state create/destroy no-draw 预检结论

日期：2026-05-13

状态：preflight / approved for B/C first slice

## 上游读取

本轮读取并继承以下上游事实：

- [shader library no-draw 清单](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-13-p1-renderer-shader-library-no-draw-manifest.md)
- [shader library no-draw 阶段收口复核](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-13-p1-internal-renderer-shader-library-no-draw-stage-closure-review.md)
- [shader library no-draw 清单稳定化复核](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-13-p1-internal-renderer-shader-library-no-draw-manifest-stabilization-closure-review.md)
- [pipeline descriptor no-draw 清单](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-13-p1-renderer-pipeline-descriptor-no-draw-manifest.md)
- [pipeline state no-draw planning 清单](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-12-p1-renderer-pipeline-state-no-draw-planning-manifest.md)
- [render command encoder 创建阻塞归因清单](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-render-command-encoder-creation-blocker-reconciliation-manifest.md)

上游 runtime input 固定为 `CjguiInternalRendererNoShaderLibraryRuntimeCallReadiness`，上游 default draft 固定为 `cjguiInternalExecuteDefaultRendererShaderLibraryRuntimeCallDraft()`。

## 判断

本轮可以推进 token-backed `MTLRenderPipelineState` create/destroy first slice。证据链已经具备：

- token-backed `MTLDevice` create/destroy 与 lifecycle classification。
- token-backed `MTLRenderPipelineDescriptor` create/config/destroy，已配置 pixel format 与 sample count。
- token-backed `MTLLibrary` create/destroy。
- token-backed vertex / fragment `MTLFunction` lookup/destroy。
- runtime internal FFI call 语法已通过 descriptor 与 shader library/function owners 验证。

`MTLRenderPipelineState` creation 不需要 render command encoder，不需要 `setRenderPipelineState`，不需要 vertex buffer、draw、`commit`、`present` 或 GPU submission。只要 pipeline state table 固定容量、main-thread confined、token opaque、destroy ordering fail-closed，就可以实现 B/C。

## 选择

选择 B/C：

- B：实现 token-backed `MTLRenderPipelineState` create/destroy/classify first slice。
- C：新增 runtime internal FFI call owner，只在函数局部 create/classify/destroy，并脱水为 internal facts。

不选择 A-only，因为上游 descriptor 与 shader facts 已足以进入 no-draw pipeline state lifecycle。若 build/probe 证明 pipeline creation 需要 drawable/color attachment 或 encoder，则立即回退到 implementation recovery。

## Native 合同

允许新增 production native C ABI：

- `cjgui_native_bridge_pipeline_state_table_capacity`
- `cjgui_native_bridge_pipeline_state_table_enabled`
- `cjgui_native_bridge_pipeline_state_table_occupied_count`
- `cjgui_native_bridge_pipeline_state_create`
- `cjgui_native_bridge_pipeline_state_destroy`
- `cjgui_native_bridge_pipeline_state_token_classify`
- `cjgui_native_bridge_pipeline_state_double_destroy_classify`
- `cjgui_native_bridge_pipeline_state_create_requires_main_thread`
- `cjgui_native_bridge_pipeline_state_destroy_requires_main_thread`
- `cjgui_native_bridge_pipeline_state_encoder_binding_still_blocked`
- `cjgui_native_bridge_pipeline_state_draw_still_blocked`

`create` 必须基于 token-backed device、descriptor、vertex function 与 fragment function。pipeline state 存活时，device、descriptor、function destroy 必须 fail-closed，避免上游 token 提前撤销。

## 停止线

不创建 render command encoder，不绑定 encoder，不调用 `setRenderPipelineState`，不 draw，不创建 vertex buffer，不 `commit`，不 `present`，不提交 GPU work，不执行 render，不写 renderer state，不触碰 `runtime_state.cj`，不修改 `runtime/cjgui/cjpm.toml`，不修改 smoke native files，不新增 public API / diagnostics，不返回 pointer / handle / `id` / `Class`。

旧阶段的 `pipeline_state_creation_still_blocked` / `shader_pipeline_state_creation_still_blocked` 只表示上游阶段自己的局部 stop-line，不再解释成本轮之后的全局禁止。

## GitNexus 记录

GitNexus impact 对 `CjguiInternalRendererNoShaderLibraryRuntimeCallReadiness`、`cjguiInternalExecuteDefaultRendererShaderLibraryRuntimeCallDraft()` 与新增 pipeline state symbols 返回 `UNKNOWN` / not found / impactedCount `0`。`cjgui_native_bridge_surface_capabilities` disambiguated impact 返回 low / affectedCount `0`。本轮继续用源码阅读、probe、build 与 forbidden scan 兜底，不把图谱缺口解释为安全证明。

## 设计意图出口自检

- 本轮是否改变主题状态：预检批准从 shader library no-draw runway 进入 pipeline state create/destroy no-draw first slice。
- 本轮是否改变 canonical tail / endpoint：预检阶段尚未封尾，目标尾点候选为 `CjguiInternalRendererNoPipelineStateRuntimeCallReadiness`。
- 本轮是否改变 owner / truth / stop-line：允许新增 pipeline state owner 与 native C ABI；truth 仍是 internal no-draw facts，stop-line 继续禁止 encoder、pipeline binding、draw、commit、present、GPU submission、render、renderer state 与 public API。
- 本轮是否改变唯一 next opening：目标为 `P1 internal Renderer pipeline state encoder binding blocker reconciliation decision`，需待 manifest 封账确认。
- 是否同步 topic manifest：预检后将在 manifest stabilization 同步。
- 已同步哪些 topic manifest：待同步 `renderer-implementation-admission-chain`、`renderer-backend-readiness-real-backend-runway`、`macos-bridge-verification-smoke`。

# Pipeline state create/destroy no-draw 阶段收口复核

日期：2026-05-13

状态：已收口 / B+C 路线完成

## 本轮落点

本轮在 `CjguiInternalRendererNoShaderLibraryRuntimeCallReadiness` 已封账后，完成 token-backed `MTLRenderPipelineState` create/destroy no-draw first slice，并新增 runtime internal FFI call owner。实际路线是 B/C：

- B：production native bridge 内新增固定容量 `MTLRenderPipelineState` table，支持 create / classify / destroy / double destroy / occupied count。
- C：新增 runtime owner，把 device / descriptor / shader / pipeline state create -> classify -> destroy 调用链脱水为 internal facts。

新增 owner：

- [runtime_renderer_pipeline_state_create_destroy_planning.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_pipeline_state_create_destroy_planning.cj)
- [runtime_renderer_pipeline_state_create_destroy.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_pipeline_state_create_destroy.cj)
- [runtime_renderer_pipeline_state_runtime_call.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_pipeline_state_runtime_call.cj)

新增验证：

- [verify_native_bridge_pipeline_state_runtime_call.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_native_bridge_pipeline_state_runtime_call.sh)

## Native callable

本轮固定的 production C ABI 只返回 status / classification 或通过 `uint64_t*` 输出 opaque token：

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

pipeline state 创建依赖 token-backed `MTLDevice`、已配置 no-draw 的 token-backed `MTLRenderPipelineDescriptor`、token-backed vertex function 与 token-backed fragment function。pipeline state 存活时，device / descriptor / shader function destroy 会 fail-closed，避免上游资源先被撤销。

## 停止线复核

本轮没有创建 render command encoder，没有绑定 encoder，没有调用 `setRenderPipelineState`，没有 draw，没有创建 vertex buffer，没有 `commit`，没有 `present`，没有提交 GPU work，没有执行 render，没有写 renderer state，没有触碰 `runtime_state.cj`，没有修改 `runtime/cjgui/cjpm.toml`，没有修改 smoke native files，没有新增 public API / diagnostics，也没有向仓颉 public surface 返回 pointer / handle / `id` / `Class`。

旧阶段的 `pipeline_state_creation_still_blocked` 与 `shader_pipeline_state_creation_still_blocked` 仍保留为上游阶段局部 stop-line facts；它们不再解释成本阶段之后的全局 pipeline state creation 禁令。

## 验证摘要

已通过：

- `runtime/cjgui/native/scripts/verify_native_bridge_pipeline_state_create_destroy.sh`
- `runtime/cjgui/native/scripts/verify_native_bridge_pipeline_state_runtime_call.sh`
- `cjpm build --target-dir /tmp/cjgui-pipeline-state-owner-syntax-target --skip-script`

验证显示 pipeline state token 为非零 opaque integer，create / classify / destroy / double destroy / cleanup 通过；encoder、`setRenderPipelineState`、draw、vertex buffer、commit、present、GPU submission 与 render 均保持未触发。

## GitNexus 记录

GitNexus impact 对上游 endpoint / default draft 与新增 pipeline state symbols 多数返回 `UNKNOWN` / not found / impactedCount `0`；`cjgui_native_bridge_surface_capabilities` 使用 disambiguated symbol impact 返回 low / affectedCount `0`。本轮不把图谱缺口当作安全证明，已用源码阅读、runtime build、native probe、runtime-adjacent probe 与 forbidden scan 兜底。

## 设计意图出口自检

- 本轮是否改变主题状态：是，从 shader library no-draw runtime call tail 推进到 pipeline state create/destroy no-draw runtime call tail。
- 本轮是否改变 canonical tail / endpoint：是，最新 endpoint 固定为 `CjguiInternalRendererNoPipelineStateRuntimeCallReadiness` / `cjguiInternalExecuteDefaultRendererPipelineStateRuntimeCallDraft()`。
- 本轮是否改变 owner / truth / stop-line：是，新增 pipeline state planning / lifecycle / runtime call owners；truth 限于 token-backed pipeline state no-draw lifecycle 与 runtime-local dehydrated facts；stop-line 继续禁止 encoder、pipeline binding、draw、commit、present、GPU submission、render、renderer state write、public API 与 pointer return。
- 本轮是否改变唯一 next opening：是，建议转为 `P1 internal Renderer pipeline state encoder binding blocker reconciliation decision`。
- 是否同步 topic manifest：是，已在后续 manifest stabilization 中同步。
- 已同步哪些 topic manifest：`renderer-implementation-admission-chain`、`renderer-backend-readiness-real-backend-runway`、`macos-bridge-verification-smoke`。

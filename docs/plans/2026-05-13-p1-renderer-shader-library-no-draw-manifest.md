# Shader library no-draw 清单

日期：2026-05-13

状态：manifest / sealed

## 实际路线

本阶段完成 A/B/C/D/E：

- planning owner：`runtime/cjgui/src/runtime_renderer_shader_library_no_draw_planning.cj`
- source contract owner：`runtime/cjgui/src/runtime_renderer_shader_source_contract.cj`
- library create/destroy owner：`runtime/cjgui/src/runtime_renderer_shader_library_create_destroy.cj`
- function lookup owner：`runtime/cjgui/src/runtime_renderer_shader_function_lookup.cj`
- runtime call owner：`runtime/cjgui/src/runtime_renderer_shader_library_runtime_call.cj`

## Canonical tail

- endpoint：`CjguiInternalRendererNoShaderLibraryRuntimeCallReadiness`
- default draft：`cjguiInternalExecuteDefaultRendererShaderLibraryRuntimeCallDraft()`
- runtime input：`CjguiInternalRendererNoPipelineDescriptorRuntimeCallReadiness`

## Native callable 清单

- `cjgui_native_bridge_shader_source_contract_available`
- `cjgui_native_bridge_shader_library_table_capacity`
- `cjgui_native_bridge_shader_library_table_enabled`
- `cjgui_native_bridge_shader_library_table_occupied_count`
- `cjgui_native_bridge_shader_library_create`
- `cjgui_native_bridge_shader_library_destroy`
- `cjgui_native_bridge_shader_library_token_classify`
- `cjgui_native_bridge_shader_library_double_destroy_classify`
- `cjgui_native_bridge_shader_library_create_requires_main_thread`
- `cjgui_native_bridge_shader_library_destroy_requires_main_thread`
- `cjgui_native_bridge_shader_function_table_capacity`
- `cjgui_native_bridge_shader_function_table_enabled`
- `cjgui_native_bridge_shader_function_table_occupied_count`
- `cjgui_native_bridge_shader_function_lookup_vertex`
- `cjgui_native_bridge_shader_function_lookup_fragment`
- `cjgui_native_bridge_shader_function_destroy`
- `cjgui_native_bridge_shader_function_token_classify`
- `cjgui_native_bridge_shader_function_double_destroy_classify`
- `cjgui_native_bridge_shader_function_lookup_requires_main_thread`
- `cjgui_native_bridge_shader_function_destroy_requires_main_thread`
- `cjgui_native_bridge_shader_function_missing_classify`
- `cjgui_native_bridge_shader_pipeline_state_creation_still_blocked`
- `cjgui_native_bridge_shader_encoder_binding_still_blocked`
- `cjgui_native_bridge_shader_draw_still_blocked`

## Token 与生命周期策略

`MTLLibrary` table 固定容量为 `2`，`MTLFunction` table 固定容量为 `4`。token 由 bridge-local token table 分配，token 不编码 pointer，不向仓颉 public surface 暴露 pointer / handle / `id` / `Class`。

`MTLLibrary` 必须基于 token-backed `MTLDevice` 创建。`MTLFunction` 必须基于 token-backed `MTLLibrary` lookup。library destroy 在 active function token 未销毁前 fail-closed，避免 dangling function token。

## Shader source contract

embedded minimal shader source 只用于 native no-draw compile evidence，包含 `cjgui_vertex_main` 与 `cjgui_fragment_main`。它不是 public shader API，不表示 pipeline-ready，也不表示 render-ready。

## 失败分类

invalid / stale / not-bound device token、library token、function token 均 fail-closed。capacity exhausted、double destroy、function missing、library destroy before function cleanup 均返回分类状态，不伪造 readiness。

## 停止线

不创建 `MTLRenderPipelineState`，不创建 render command encoder，不调用 `setRenderPipelineState`，不 draw，不创建 vertex buffer，不 `commit`，不 `present`，不提交 GPU work，不执行 render，不写 renderer state，不触碰 `runtime_state.cj`，不修改 `runtime/cjgui/cjpm.toml`，不修改 smoke native files，不新增 public API / diagnostics。

## 验证

- shader library create/destroy probe：通过。
- shader function lookup probe：通过。
- shader runtime call probe：通过。
- no-resource symbol probe：通过。
- `cjpm build --target-dir /tmp/cjgui-renderer-shader-library-no-draw-target --skip-script`：通过。

## 唯一 next opening

`P1 internal Renderer pipeline state create/destroy no-draw preflight decision`

## 设计意图出口自检

- 本轮是否改变主题状态：是，shader library/function no-draw first slice 已封账。
- 本轮是否改变 canonical tail / endpoint：是，canonical tail 固定为 `CjguiInternalRendererNoShaderLibraryRuntimeCallReadiness`。
- 本轮是否改变 owner / truth / stop-line：是，新增 shader owners 与 native C ABI；truth 仍是 internal facts，stop-line 未放宽到 pipeline state / encoder / draw / submit / render。
- 本轮是否改变唯一 next opening：是，固定为 `P1 internal Renderer pipeline state create/destroy no-draw preflight decision`。
- 是否同步 topic manifest：是，需同步三个 topic manifest。
- 已同步哪些 topic manifest：`renderer-implementation-admission-chain`、`renderer-backend-readiness-real-backend-runway`、`macos-bridge-verification-smoke`。

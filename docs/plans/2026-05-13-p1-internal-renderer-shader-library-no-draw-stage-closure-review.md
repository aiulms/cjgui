# Shader library no-draw 阶段收口复核

日期：2026-05-13

状态：stage closure / A-B-C-D-E 完成

## 本轮结果

本轮按预检批准路线完成 shader library no-draw runway：

- A：新增 `runtime/cjgui/src/runtime_renderer_shader_library_no_draw_planning.cj`，固定 shader source、library、function、pipeline state blocked、encoder blocked、draw blocked facts。
- B：新增 `runtime/cjgui/src/runtime_renderer_shader_source_contract.cj`，固定 embedded minimal shader source contract 只服务 native no-draw compile evidence。
- C：production native bridge 新增 token-backed `MTLLibrary` fixed-capacity table 与 create/destroy/classify/double-destroy C ABI。
- D：production native bridge 新增 token-backed vertex / fragment `MTLFunction` lookup/classify/destroy C ABI。
- E：新增 `runtime/cjgui/src/runtime_renderer_shader_library_runtime_call.cj`，局部执行 library create、function lookup、classify 与 cleanup，并脱水为 internal facts。

## Native 边界

新增 C ABI 只返回 `int32_t` / `uint32_t` / opaque `uint64_t` out-token。`MTLLibrary` 与 `MTLFunction` 只保存在 native fixed-capacity table 内，不返回 pointer、handle、`id` 或 `Class`。

本轮没有创建 `MTLRenderPipelineState`，没有创建 render command encoder，没有调用 `setRenderPipelineState`，没有 draw，没有创建 vertex buffer，没有 `commit` / `present`，没有 GPU submission，没有 render。

## Runtime 边界

新 runtime owners 只消费 `CjguiInternalRendererNoPipelineDescriptorRuntimeCallReadiness` 形成的上游链，所有 token 只在函数局部存在，不写 renderer state，不触碰 `runtime_state.cj`，不新增 public API / diagnostics。

## 验证记录

- 红线 probe 初始失败：`verify_native_bridge_shader_library_create_destroy.sh` 首次运行报告缺少 `cjgui_native_bridge_shader_source_contract_available`。
- `verify_native_bridge_shader_library_create_destroy.sh`：通过。
- `verify_native_bridge_shader_function_lookup.sh`：通过。
- `verify_native_bridge_shader_library_runtime_call.sh`：通过。
- `verify_native_bridge_no_resource_symbols.sh`：通过。
- `cjpm build --target-dir /tmp/cjgui-renderer-shader-library-no-draw-target --skip-script`：通过，只有既有 unused warnings。

## GitNexus 记录

GitNexus impact 对上游 endpoint、default draft 与新增 shader symbols 返回 `UNKNOWN` / not found / impactedCount `0`。本轮未把图谱缺口视为安全证明，已用源码阅读、probe、build 与 symbol scan 兜底。

## 停止线复核

本轮仍禁止 `MTLRenderPipelineState`、render command encoder、`setRenderPipelineState`、draw、vertex buffer、`commit`、`present`、GPU submission、render、renderer state write、`runtime_state.cj`、`runtime/cjgui/cjpm.toml`、smoke native edits、public API 与 pointer / handle / `id` / `Class` return。

## 设计意图出口自检

- 本轮是否改变主题状态：是，shader library no-draw 从 preflight 进入 first slice 完成态。
- 本轮是否改变 canonical tail / endpoint：是，阶段尾点固定为 `CjguiInternalRendererNoShaderLibraryRuntimeCallReadiness`。
- 本轮是否改变 owner / truth / stop-line：是，新增 shader planning/source/library/function/runtime call owners；truth 仍是 internal dehydrated facts，stop-line 继续禁止 pipeline state、encoder、draw、commit、present、GPU submission、render、renderer state 与 public API。
- 本轮是否改变唯一 next opening：是，建议 `P1 internal Renderer pipeline state create/destroy no-draw preflight decision`。
- 是否同步 topic manifest：将在 manifest stabilization 同步。
- 已同步哪些 topic manifest：待同步 `renderer-implementation-admission-chain`、`renderer-backend-readiness-real-backend-runway`、`macos-bridge-verification-smoke`。

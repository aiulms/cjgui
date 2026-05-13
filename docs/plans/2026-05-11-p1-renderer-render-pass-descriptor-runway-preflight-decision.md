# MTLRenderPassDescriptor 路线预检结论

日期：2026-05-11

## 上游固定

- Runtime input：`CjguiInternalRendererNoCommandBufferRuntimeCallReadiness`
- 上游 owner：[runtime_renderer_command_buffer_runtime_call.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_command_buffer_runtime_call.cj)
- 上游 default draft：`cjguiInternalExecuteDefaultRendererCommandBufferRuntimeCallDraft()`

## 预检判断

本阶段可以打开 `MTLRenderPassDescriptor` create / destroy first slice，但只能推进到 token-backed descriptor lifecycle facts：

- 允许 production native bridge 在 main thread 内创建 `MTLRenderPassDescriptor`。
- 允许固定容量很小的 descriptor table，容量固定为 `2`。
- 允许 opaque descriptor token 只作为 bridge-local identifier，不得编码 pointer。
- 允许 runtime internal owner 局部调用 create / classify / destroy / double-destroy，并只输出 dehydrated facts。
- 必须让 invalid token、stale token、double destroy 与 background-thread create / destroy fail-closed。
- 必须保留 color attachment、drawable texture 与 encoder creation still-blocked facts。

本阶段不得进入：

- color attachment configuration。
- drawable texture binding。
- render command encoder creation。
- `renderCommandEncoderWithDescriptor`。
- draw。
- `commit`。
- `present`。
- GPU submission。
- render execution。
- renderer state write。
- public API / public diagnostics。
- pointer / handle / `id` / `Class` return。

## 候选判断

选择 A/B 路线：

- A：固定 render pass descriptor planning / attachment requirement facts。
- B：实现 token-backed `MTLRenderPassDescriptor` create / destroy first slice。

暂缓 C/D：

- C：color attachment configuration 暂缓，因为 production drawable texture lifecycle 还没有进入可稳定消费的 token-backed contract。
- D：runtime internal FFI call owner 暂缓到 color attachment 之后的独立阶段；本轮 runtime owner 只覆盖 create / classify / destroy facts，不包装成 descriptor configured truth。

拒绝候选：

- 创建 render command encoder。
- 调用 `renderCommandEncoderWithDescriptor`。
- draw / `commit` / `present` / GPU submission。
- 返回 native pointer / handle / `id` / `Class`。
- 写 renderer state 或扩 public API。

## GitNexus 记录

已对以下上游与新增符号运行 impact：

- `CjguiInternalRendererNoCommandBufferRuntimeCallReadiness`
- `cjguiInternalExecuteDefaultRendererCommandBufferRuntimeCallDraft`
- `cjgui_native_bridge_surface_capabilities`
- `cjgui_native_bridge_render_pass_descriptor_create`
- `CjguiInternalRendererNoRenderPassDescriptorCreateDestroyReadiness`
- `cjguiInternalExecuteDefaultRendererRenderPassDescriptorCreateDestroyDraft`

结果为 `UNKNOWN` / not found / impactedCount `0`，符合近期新增 owner 与 native callable 未索引状态；本阶段使用源码、build、probe 与 scan 兜底。未出现 HIGH / CRITICAL 风险输出。

## 设计意图出口自检

- 本轮是否改变主题状态：是，从 command buffer runtime call runway 推进到 render pass descriptor create / destroy runway。
- 本轮是否改变 canonical tail / endpoint：预期变更为 `CjguiInternalRendererNoRenderPassDescriptorCreateDestroyReadiness`。
- 本轮是否改变 owner / truth / stop-line：是，新增 descriptor native table / runtime owner；truth 只到 create / classify / destroy facts；stop-line 继续禁止 color attachment / encoder / draw / commit / present / GPU / render / state / public。
- 本轮是否改变唯一 next opening：预期变更为 `P1 internal Renderer render pass descriptor color attachment preflight decision`。
- 是否同步 topic manifest：需要。
- 已同步哪些 topic manifest：本预检要求同步 `renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。


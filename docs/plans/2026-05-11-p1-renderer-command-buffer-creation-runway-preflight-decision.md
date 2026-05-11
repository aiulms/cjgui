# MTLCommandBuffer 创建路线预检结论

日期：2026-05-11

## 上游固定

- Runtime input：`CjguiInternalRendererNoCommandQueueRuntimeCallReadiness`
- 上游 owner：[runtime_renderer_command_queue_runtime_call.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_command_queue_runtime_call.cj)
- 上游 default draft：`cjguiInternalExecuteDefaultRendererCommandQueueRuntimeCallDraft()`

## 预检判断

本阶段可以打开 `MTLCommandBuffer` create / destroy first slice，但必须保持极窄：

- 允许从 token-backed `MTLCommandQueue` 调用 `commandBuffer` 创建短生命周期 command buffer token。
- 允许 production native bridge 持有固定容量很小的 command buffer table，容量固定为 `2`。
- 允许 runtime internal FFI owner 局部调用 create / classify / destroy / double-destroy，并只输出 dehydrated facts。
- 必须 main-thread create / destroy。
- 必须让 queue destroy 在仍有 command buffer 绑定时 fail-closed。
- 必须支持 invalid / stale / double-destroy fail-closed。

本阶段不得进入：

- `commit`。
- `present`。
- encoder creation。
- render pass descriptor creation。
- GPU submission。
- render execution。
- renderer state write。
- public API / public diagnostics。
- pointer / handle / `id` / `Class` return。

## 候选判断

选择 A/B/C 连续推进：

- A：固定 command buffer creation planning / availability facts。
- B：实现 token-backed `MTLCommandBuffer` create / destroy first slice。
- C：实现 runtime internal FFI call owner。

拒绝候选：

- 直接 `commit` / `present`。
- 创建 encoder / render pass。
- 返回 native pointer / handle / `id` / `Class`。
- 写 renderer state 或扩 public API。

## GitNexus 记录

已对以下上游与新增符号运行 impact：

- `CjguiInternalRendererNoCommandQueueRuntimeCallReadiness`
- `cjguiInternalExecuteDefaultRendererCommandQueueRuntimeCallDraft`
- `CjguiInternalRendererNoCommandBufferCreateDestroyReadiness`
- `cjguiInternalExecuteDefaultRendererCommandBufferCreateDestroyDraft`
- `CjguiInternalRendererNoCommandBufferRuntimeCallReadiness`
- `cjguiInternalExecuteDefaultRendererCommandBufferRuntimeCallDraft`
- `cjgui_native_bridge_command_buffer_create`
- `cjgui_native_bridge_command_buffer_destroy`
- `cjgui_native_bridge_command_buffer_token_classify`

结果为 `UNKNOWN` / not found / impactedCount `0`，符合近期新增 owner 与 native callable 未索引状态；本阶段使用源码、build、probe 与 scan 兜底。

## 设计意图出口自检

- 本轮是否改变主题状态：是，从 command queue runtime call runway 推进到 command buffer create / destroy runway。
- 本轮是否改变 canonical tail / endpoint：预期变更为 `CjguiInternalRendererNoCommandBufferRuntimeCallReadiness`。
- 本轮是否改变 owner / truth / stop-line：是，新增 command buffer native table / runtime owners；truth 只到 create / destroy / classify facts；stop-line 继续禁止 commit / present / encoder / render pass / GPU / render / state / public。
- 本轮是否改变唯一 next opening：预期变更为 `P1 internal Renderer render pass descriptor planning preflight decision`。
- 是否同步 topic manifest：需要。
- 已同步哪些 topic manifest：本预检要求同步 `renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。

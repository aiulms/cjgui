# MTLCommandQueue 创建清单稳定化封账

日期：2026-05-11

## 稳定化内容

- 固定 manifest：[Command queue creation 路线封账清单](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-command-queue-creation-runway-manifest.md)
- 固定 create / destroy owner：[runtime_renderer_command_queue_create_destroy.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_command_queue_create_destroy.cj)
- 固定 runtime call owner：[runtime_renderer_command_queue_runtime_call.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_command_queue_runtime_call.cj)
- 固定 native probe：[verify_native_bridge_command_queue_create_destroy.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_native_bridge_command_queue_create_destroy.sh)
- 固定 runtime call probe：[verify_native_bridge_command_queue_runtime_call.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_native_bridge_command_queue_runtime_call.sh)
- 固定 endpoint：`CjguiInternalRendererNoCommandQueueRuntimeCallReadiness`
- 固定 default draft：`cjguiInternalExecuteDefaultRendererCommandQueueRuntimeCallDraft()`
- 固定 runtime input：`CjguiInternalRendererNoCommandQueueCreateDestroyReadiness`

## 证据口径

本 manifest 只承认 command queue token lifecycle 与 runtime-local call facts：

- `MTLCommandQueue` 可以由 token-backed `MTLDevice` 创建。
- Queue token 可以 classify valid / stale / invalid。
- Queue destroy 可以清理 occupied count。
- Double destroy 与 invalid token fail-closed。
- Device destroy 受 queue lifecycle ordering 保护。
- Runtime owner 只在函数局部持有 token，不持久化，不写 renderer state。
- Command buffer creation 仍 blocked。

## 不改变的边界

- 不创建 command buffer。
- 不调用 `commandBuffer`。
- 不创建 encoder。
- 不调用 `commit`。
- 不 present。
- 不提交 GPU work。
- 不执行 render。
- 不写 renderer state。
- 不触碰 `runtime_state.cj`。
- 不新增 public API / diagnostics。
- 不返回 native pointer / handle / `id` / `Class`。
- 不把 command queue facts 包装成 backend-ready truth。

## 设计意图出口自检

- 本轮是否改变主题状态：是，command queue creation runway manifest 已稳定化。
- 本轮是否改变 canonical tail / endpoint：是，当前 tail 固定为 `CjguiInternalRendererNoCommandQueueRuntimeCallReadiness`。
- 本轮是否改变 owner / truth / stop-line：是，owner 固定为 command queue create / destroy 与 runtime call；truth 只限 queue lifecycle facts；stop-line 不放宽到 command buffer / present / GPU / render / state / public。
- 本轮是否改变唯一 next opening：是，唯一 next opening 固定为 `P1 internal Renderer command buffer creation planning preflight decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。

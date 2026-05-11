# MTLCommandBuffer 创建路线阶段封账复核

日期：2026-05-11

## 本轮结果

本阶段完成 A/B/C 路线：

- 新增 token-backed `MTLCommandBuffer` create / destroy first slice。
- 新增 command buffer runtime internal FFI call owner。
- 新增 native create / destroy probe 与 runtime-adjacent FFI probe。
- 更新旧 probe 边界：production bridge 允许 `commandBuffer` first slice，但仍禁止 `commit`、`present`、encoder、render pass、GPU submission、render、pointer return 与 public API。

## 新增 owner

- [runtime_renderer_command_buffer_create_destroy.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_command_buffer_create_destroy.cj)
- [runtime_renderer_command_buffer_runtime_call.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_command_buffer_runtime_call.cj)

Canonical endpoint：

- `CjguiInternalRendererNoCommandBufferRuntimeCallReadiness`

Default draft：

- `cjguiInternalExecuteDefaultRendererCommandBufferRuntimeCallDraft()`

Runtime input：

- `CjguiInternalRendererNoCommandBufferCreateDestroyReadiness`

上游 input：

- `CjguiInternalRendererNoCommandQueueRuntimeCallReadiness`

## 新增 native callable

- `cjgui_native_bridge_command_buffer_table_capacity`
- `cjgui_native_bridge_command_buffer_table_enabled`
- `cjgui_native_bridge_command_buffer_table_occupied_count`
- `cjgui_native_bridge_command_buffer_create`
- `cjgui_native_bridge_command_buffer_destroy`
- `cjgui_native_bridge_command_buffer_token_classify`
- `cjgui_native_bridge_command_buffer_double_destroy_classify`
- `cjgui_native_bridge_command_buffer_create_requires_main_thread`
- `cjgui_native_bridge_command_buffer_destroy_requires_main_thread`
- `cjgui_native_bridge_command_buffer_commit_still_blocked`
- `cjgui_native_bridge_command_buffer_encoder_creation_still_blocked`

## 验证摘要

已通过：

- [verify_native_bridge_command_buffer_create_destroy.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_native_bridge_command_buffer_create_destroy.sh)
- [verify_native_bridge_command_buffer_runtime_call.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_native_bridge_command_buffer_runtime_call.sh)
- `cjpm build --target-dir /tmp/cjgui-renderer-command-buffer-creation-runway-early-target --skip-script`
- no-resource symbol probe
- isolated FFI probe
- cjpm package link probe
- skeleton compile

关键观察：

- buffer create 返回 `0`。
- buffer classify 返回 `180`。
- destroy 后 classify 返回 `-183`。
- double destroy 返回 `-186`。
- queue destroy 在 active buffer 存在时返回 `-173`。
- `commit_still_blocked` 返回 `-189`。
- `encoder_creation_still_blocked` 返回 `-190`。
- cleanup 后 device / queue / buffer occupied count 回到起点。
- runtime-adjacent FFI probe 只局部持有 token，未持久化。

## 仍保持的停止线

本阶段没有调用 `commit`，没有 `present`，没有创建 encoder / render pass，没有提交 GPU work，没有执行 render，没有写 renderer state，没有触碰 `runtime_state.cj`，没有修改 `runtime/cjgui/cjpm.toml`，没有修改 smoke native files，没有新增 public API / public diagnostics，没有返回 native pointer / handle / `id` / `Class`。

## 设计意图出口自检

- 本轮是否改变主题状态：是，command buffer create / destroy 与 runtime internal FFI call owner 已完成。
- 本轮是否改变 canonical tail / endpoint：是，tail 固定为 `CjguiInternalRendererNoCommandBufferRuntimeCallReadiness`。
- 本轮是否改变 owner / truth / stop-line：是，owner 固定为 command buffer create / destroy 与 runtime call owners；truth 只到 local token lifecycle facts；stop-line 禁止 commit / present / encoder / render pass / GPU / render / state / public。
- 本轮是否改变唯一 next opening：是，唯一 next opening 固定为 `P1 internal Renderer render pass descriptor planning preflight decision`。
- 是否同步 topic manifest：需要并纳入本轮同步。
- 已同步哪些 topic manifest：`renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。

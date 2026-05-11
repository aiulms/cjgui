# MTLCommandQueue 创建路线阶段封账

日期：2026-05-11

## 本阶段完成

- 新增 native command queue probe：[verify_native_bridge_command_queue_create_destroy.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_native_bridge_command_queue_create_destroy.sh)
- 新增 runtime-adjacent FFI call probe：[verify_native_bridge_command_queue_runtime_call.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_native_bridge_command_queue_runtime_call.sh)
- 新增 runtime owner：[runtime_renderer_command_queue_create_destroy.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_command_queue_create_destroy.cj)
- 新增 runtime owner：[runtime_renderer_command_queue_runtime_call.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_command_queue_runtime_call.cj)
- 修改 production native bridge：[cjgui_native_bridge.h](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/cjgui_native_bridge.h) 与 [cjgui_native_bridge.m](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/cjgui_native_bridge.m)

## Native callable

- `cjgui_native_bridge_command_queue_table_capacity`
- `cjgui_native_bridge_command_queue_table_enabled`
- `cjgui_native_bridge_command_queue_table_occupied_count`
- `cjgui_native_bridge_command_queue_create`
- `cjgui_native_bridge_command_queue_destroy`
- `cjgui_native_bridge_command_queue_token_classify`
- `cjgui_native_bridge_command_queue_double_destroy_classify`
- `cjgui_native_bridge_command_queue_create_requires_main_thread`
- `cjgui_native_bridge_command_queue_destroy_requires_main_thread`
- `cjgui_native_bridge_command_buffer_creation_still_blocked`

## Runtime owner

- Endpoint：`CjguiInternalRendererNoCommandQueueCreateDestroyReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererCommandQueueCreateDestroyDraft()`
- Runtime input：`CjguiInternalRendererNoDrawableNoPresentAcquisitionReadiness`

以及：

- Endpoint：`CjguiInternalRendererNoCommandQueueRuntimeCallReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererCommandQueueRuntimeCallDraft()`
- Runtime input：`CjguiInternalRendererNoCommandQueueCreateDestroyReadiness`

## 观察事实

- Queue table 固定容量为 `2`。
- Queue token 为 opaque integer，不是 pointer cast。
- Queue create / destroy 受 main-thread gate 约束。
- Queue create 需要 valid token-backed `MTLDevice`。
- Device destroy 在 queue 仍绑定时 fail-closed，返回 command-queue-destroy-before-device-required 分类。
- Queue destroy 后 classify 进入 stale / destroyed 分类。
- Double destroy 与 invalid token fail-closed。
- Command buffer creation 仍明确 blocked。
- Runtime owner 的 token 只在函数局部使用，不持久化，不写 renderer state，不返回到 public surface。

## 明确未进入

- 不创建 command buffer。
- 不调用 `commandBuffer`。
- 不创建 encoder。
- 不调用 `commit`。
- 不 present。
- 不提交 GPU work。
- 不执行 render。
- 不写 renderer state。
- 不扩 public API / diagnostics。

## 设计意图出口自检

- 本轮是否改变主题状态：是，command queue 从 blocked / planning 进入 token-backed create / destroy 与 runtime internal call facts。
- 本轮是否改变 canonical tail / endpoint：是，tail 更新为 `CjguiInternalRendererNoCommandQueueRuntimeCallReadiness`。
- 本轮是否改变 owner / truth / stop-line：是，新增两个 command queue owner；truth 只限 command queue lifecycle / runtime-local FFI call facts；stop-line 未放宽到 command buffer、commit、present、GPU work、render、state write、public API。
- 本轮是否改变唯一 next opening：是，唯一后续入口更新为 `P1 internal Renderer command buffer creation planning preflight decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。

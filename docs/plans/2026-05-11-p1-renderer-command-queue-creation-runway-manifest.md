# MTLCommandQueue 创建路线封账清单

日期：2026-05-11

状态：manifest / completed through token-backed command queue create-destroy and runtime internal call facts

## 固定尾点

- Endpoint：`CjguiInternalRendererNoCommandQueueRuntimeCallReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererCommandQueueRuntimeCallDraft()`
- Runtime input：`CjguiInternalRendererNoCommandQueueCreateDestroyReadiness`
- Upstream endpoint：`CjguiInternalRendererNoDrawableNoPresentAcquisitionReadiness`
- Upstream owner：[runtime_renderer_drawable_no_present_acquisition.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_drawable_no_present_acquisition.cj)

## Owner 文件

- [runtime_renderer_command_queue_create_destroy.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_command_queue_create_destroy.cj)
- [runtime_renderer_command_queue_runtime_call.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_command_queue_runtime_call.cj)

## Probe

- [verify_native_bridge_command_queue_create_destroy.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_native_bridge_command_queue_create_destroy.sh)
- [verify_native_bridge_command_queue_runtime_call.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_native_bridge_command_queue_runtime_call.sh)

## Native callable list

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

## 实际路线

本阶段完成 B/C：

- token-backed `MTLCommandQueue` create / destroy first slice。
- runtime internal FFI call owner。

本阶段未进入：

- command buffer creation。
- `commandBuffer` 调用。
- encoder creation。
- `commit` / `present`。
- GPU submission。
- render。
- renderer state write。
- public API / diagnostics。

## 固定事实

- Queue table fixed capacity 为 `2`。
- Queue token 使用 opaque integer，不编码 native pointer。
- Queue table entry 仅由 production native bridge 持有，不暴露 pointer / handle / `id` / `Class`。
- Queue create 必须使用 valid token-backed `MTLDevice`。
- Queue create / destroy 必须 main-thread。
- Device destroy 必须在 bound queue destroy 之后。
- Invalid token、stale token、double destroy、background-thread create / destroy 均 fail-closed。
- Runtime internal owner 只在函数局部持有 token，并只输出 dehydrated facts。
- Command buffer creation 仍明确 blocked。

## GitNexus 记录

- 上游 endpoint / default draft 与新增 command queue owner 在当前索引中返回 `UNKNOWN` / not found / impactedCount `0`。
- 未出现 HIGH / CRITICAL 风险输出。
- 本阶段使用源码阅读、probe、`cjpm build`、native forbidden scan 与 public declaration scan 兜底。

## 上游与下游指向

上游固定：

- [Drawable no-present acquisition 清单](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-drawable-no-present-acquisition-manifest.md)
- [Metal device binding 路线封账清单](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-metal-device-binding-runway-manifest.md)
- [CAMetalLayer runtime attachment FFI call owner manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-cametallayer-runtime-attachment-ffi-call-owner-manifest.md)

下游实际接续：

- [Command buffer creation runway manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-command-buffer-creation-runway-manifest.md)
- [Command buffer creation runway closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-internal-renderer-command-buffer-creation-runway-stage-closure-review.md)

## 停止线

不创建 command buffer，不调用 `commandBuffer`，不创建 encoder，不调用 `commit`，不 present，不提交 GPU work，不执行 render，不写 renderer state，不触碰 `runtime_state.cj`，不修改 `runtime/cjgui/cjpm.toml`，不修改 smoke native files，不新增 public API / diagnostics，不返回 native pointer / handle / `id` / `Class`，不把 command queue lifecycle 或 runtime call facts 解释成 backend-ready truth、GPU submission permission、render permission 或 state write permission。

## 唯一后续入口

`P1 internal Renderer command buffer creation planning preflight decision`

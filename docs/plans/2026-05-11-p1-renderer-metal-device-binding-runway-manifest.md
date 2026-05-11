# Metal device binding 路线封账清单

## Canonical endpoint

- Endpoint：`CjguiInternalRendererNoMetalDeviceLayerBindingReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererMetalDeviceLayerBindingDraft()`
- Runtime input：`CjguiInternalRendererNoMetalDeviceCreateDestroyReadiness`
- Upstream fixed input：`CjguiInternalRendererNoCAMetalLayerAttachmentRuntimeCallReadiness`

## Owner

- [runtime_renderer_metal_device_availability.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_metal_device_availability.cj)
- [runtime_renderer_metal_device_create_destroy.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_metal_device_create_destroy.cj)
- [runtime_renderer_metal_device_layer_binding.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_metal_device_layer_binding.cj)

## Native callable list

- `cjgui_native_bridge_metal_import_available`
- `cjgui_native_bridge_metal_default_device_available`
- `cjgui_native_bridge_metal_device_no_command_queue_admission`
- `cjgui_native_bridge_metal_device_creation_still_blocked`
- `cjgui_native_bridge_metal_device_table_capacity`
- `cjgui_native_bridge_metal_device_table_enabled`
- `cjgui_native_bridge_metal_device_table_occupied_count`
- `cjgui_native_bridge_metal_default_device_create`
- `cjgui_native_bridge_metal_device_destroy`
- `cjgui_native_bridge_metal_device_token_classify`
- `cjgui_native_bridge_metal_device_double_destroy_classify`
- `cjgui_native_bridge_metal_device_create_requires_main_thread`
- `cjgui_native_bridge_metal_device_destroy_requires_main_thread`
- `cjgui_native_bridge_metal_device_command_queue_still_blocked`
- `cjgui_native_bridge_cametallayer_bind_metal_device`
- `cjgui_native_bridge_cametallayer_unbind_metal_device`
- `cjgui_native_bridge_cametallayer_device_binding_classify`
- `cjgui_native_bridge_cametallayer_double_unbind_device_classify`
- `cjgui_native_bridge_cametallayer_device_binding_requires_main_thread`
- `cjgui_native_bridge_cametallayer_drawable_acquisition_still_blocked`

## 固定事实

- Metal import 可编译。
- Default `MTLDevice` availability 可观察。
- `MTLDevice` create / destroy 使用 fixed-capacity token table。
- `CAMetalLayer.device` binding / unbinding 只接受 token-backed layer 与 token-backed device。
- Destroy device 前必须 unbind layer。
- Destroy layer 前必须 detach view 且 unbind device。
- Invalid / stale / destroyed token、double destroy、double unbind 均 fail-closed。
- Drawable acquisition 仍 blocked。
- Command queue creation 仍 blocked。

## Stop-line

不调用 `nextDrawable`，不获取 drawable，不创建 command queue / command buffer / encoder，不提交 GPU work，不执行 render，不写 renderer state，不触碰 `runtime_state.cj`，不修改 `runtime/cjgui/cjpm.toml`，不修改 smoke native files，不新增 public API / diagnostics，不返回 native pointer / handle / `id` / `Class`，不把 Metal device binding facts 解释成 backend-ready truth。

## 验证入口

- [verify_native_bridge_metal_device_layer_binding.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_native_bridge_metal_device_layer_binding.sh)

## 唯一后续入口

`P1 internal Renderer drawable acquisition planning preflight decision`

## 下游接续

已由 [Drawable acquisition 路线封账清单](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-drawable-acquisition-runway-manifest.md) 接续。本阶段下游只完成 planning / no-acquire 与 availability / still-blocked facts，未调用 `nextDrawable`，未获取 drawable，未创建 command queue / command buffer / encoder，未提交 GPU work，未执行 render。

Drawable 路线后续已由 [Drawable acquisition first implementation recovery 清单](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-drawable-acquisition-first-implementation-manifest.md) 与 [Drawable environment / window visibility planning 清单](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-drawable-environment-window-visibility-manifest.md) 接续。当前下游 tail 是 `CjguiInternalRendererNoDrawableEnvironmentVisibilityReadiness`，仍不调用 `nextDrawable`，不 present，不创建 command queue / command buffer / encoder。

后续又由 [Drawable no-present acquisition 清单](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-drawable-no-present-acquisition-manifest.md) 与 [Command queue creation 路线封账清单](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-command-queue-creation-runway-manifest.md) 接续。当前 command queue facts 只承认 token-backed `MTLCommandQueue` create / classify / destroy、device destroy ordering 与 runtime-local call；仍不创建 command buffer，不调用 `commandBuffer`，不创建 encoder，不 `commit` / `present`，不提交 GPU work，不执行 render。

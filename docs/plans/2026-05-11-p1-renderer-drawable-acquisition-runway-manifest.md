# Drawable acquisition 路线封账清单

## 固定尾点

- Endpoint：`CjguiInternalRendererNoDrawableAvailabilityReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererDrawableAvailabilityDraft()`
- Runtime input：`CjguiInternalRendererNoDrawableAcquisitionPlanningReadiness`
- Upstream fixed input：`CjguiInternalRendererNoMetalDeviceLayerBindingReadiness`

## Owner 文件

- [runtime_renderer_drawable_acquisition_planning.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_drawable_acquisition_planning.cj)
- [runtime_renderer_drawable_availability.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_drawable_availability.cj)

## 实际路线

本轮实际完成 A/B：

- A：drawable acquisition planning / no-acquire facts。
- B：drawable availability / still-blocked facts。

本轮未进入 C：没有调用 `nextDrawable`，没有获取 drawable，没有创建 drawable token table，也没有执行 immediate-release feasibility。

## 复用调用入口

本轮没有新增 production native C ABI。Availability owner 与 probe 复用既有 fail-closed callable：

- `cjgui_native_bridge_cametallayer_drawable_acquisition_still_blocked`
- `cjgui_native_bridge_metal_device_command_queue_still_blocked`
- `cjgui_native_bridge_cametallayer_device_binding_requires_main_thread`

## 固定事实

- Metal device layer binding evidence 已被 planning owner 接受为上游。
- Drawable acquisition 仍 blocked。
- Command queue creation 仍 blocked。
- Present path 仍 forbidden。
- `nextDrawable` 仍在 owner 与 probe 外部。
- Command queue / command buffer / encoder / render 仍是后续前置，不在本轮创建。
- All facts 只作为 internal dehydrated facts，不是 backend-ready truth。

## 探针入口

- [verify_native_bridge_drawable_acquisition_planning.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_native_bridge_drawable_acquisition_planning.sh)

观察事实：

- `drawable_acquisition_still_blocked=-150`
- `command_queue_still_blocked=-129`
- `binding_main_thread_required=-141`
- `next_drawable_called=false`
- `present_called=false`
- `command_buffer_created=false`
- `gpu_work_submitted=false`

## 停止线

不调用 `nextDrawable`，不获取 drawable，不调用 `present` / `presentDrawable`，不创建 command queue / command buffer / encoder，不提交 GPU work，不执行 render，不写 renderer state，不触碰 `runtime_state.cj`，不修改 `runtime/cjgui/cjpm.toml`，不修改 smoke native files，不新增 public API / diagnostics，不返回 native pointer / handle / `id` / `Class`，不把 drawable availability facts 解释成 backend-ready truth。

## 唯一后续入口

`P1 internal Renderer drawable acquisition first implementation recovery/preflight decision`

## 下游接续

该入口已由 [Drawable acquisition first implementation recovery 清单](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-drawable-acquisition-first-implementation-manifest.md) 接续。下游当前 canonical endpoint 是 `CjguiInternalRendererNoDrawableAcquisitionRecoveryReadiness` / `cjguiInternalExecuteDefaultRendererDrawableAcquisitionRecoveryDraft()`；该接续仍不调用 `nextDrawable`，只固定 visible window / display-backed layer / run loop non-blocking 缺口与 still-blocked recovery facts。

该 recovery 入口又已由 [Drawable environment / window visibility planning 清单](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-drawable-environment-window-visibility-manifest.md) 接续。当前下游 tail 是 `CjguiInternalRendererNoDrawableEnvironmentVisibilityReadiness` / `cjguiInternalExecuteDefaultRendererDrawableEnvironmentVisibilityDraft()`，仍只固定 window visibility / run loop / display backing planning facts，不授权 `nextDrawable` 或 present。

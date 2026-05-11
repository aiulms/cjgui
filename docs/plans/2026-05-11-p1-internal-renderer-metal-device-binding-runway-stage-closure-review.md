# Metal device binding 路线阶段收束复核

## 实际路线

本轮完成 A / B / C 三层 first slice：

- A：production bridge import Metal，并新增 default device availability / no-command-queue facts。
- B：新增固定容量 token-backed `MTLDevice` table，支持 create / classify / destroy / double-destroy fail-closed / occupied count。
- C：新增 `CAMetalLayer.device` bind / unbind / classify / double-unbind fail-closed，要求 main-thread，并继续阻断 drawable acquisition 与 command queue。

## 实际写集

- 修改 [cjgui_native_bridge.h](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/cjgui_native_bridge.h)，新增 Metal device availability、device lifecycle 与 device-layer binding C ABI。
- 修改 [cjgui_native_bridge.m](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/cjgui_native_bridge.m)，新增 fixed-capacity `MTLDevice` token table 与 layer device binding / unbinding 实现。
- 新增 [runtime_renderer_metal_device_availability.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_metal_device_availability.cj)。
- 新增 [runtime_renderer_metal_device_create_destroy.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_metal_device_create_destroy.cj)。
- 新增 [runtime_renderer_metal_device_layer_binding.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_metal_device_layer_binding.cj)。
- 新增 [verify_native_bridge_metal_device_layer_binding.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_native_bridge_metal_device_layer_binding.sh)。
- 更新既有 native probe allowlist / link flags，让它们允许本阶段 Metal import / `MTLDevice` facts，但继续禁止 `nextDrawable`、command queue / buffer / encoder、GPU submission、render 与 pointer return。

## 当前事实

- `MTLDevice` 只通过 opaque token 暴露给 runtime internal facts。
- Token 不编码 pointer，也不返回 pointer / handle / `id` / `Class`。
- `CAMetalLayer.device` binding 只在 token-backed layer 与 token-backed device 之间发生。
- Binding cleanup 后 device table / layer table / view table occupied count 回到进入前状态。
- `cjgui_native_bridge_cametallayer_drawable_acquisition_still_blocked()` 仍返回 fail-closed facts。
- `cjgui_native_bridge_metal_device_command_queue_still_blocked()` 仍返回 fail-closed facts。
- 当前仍不是 backend-ready truth，也不是 drawable / command queue / render permission。

## 已执行验证

- `runtime/cjgui/native/scripts/verify_native_bridge_metal_device_layer_binding.sh` 已通过，观察 `metal_device_binding_probe=passed` 与 `device_count_after=0`。
- `cjpm build --target-dir /tmp/cjgui-renderer-metal-device-binding-runway-target --skip-script` 已通过；输出仅包含项目既有 unused warnings。

## 设计意图出口自检

- 本轮是否改变主题状态：是，Metal device binding first slice 已进入 runtime internal evidence chain。
- 本轮是否改变 canonical tail / endpoint：是，新增 `CjguiInternalRendererNoMetalDeviceLayerBindingReadiness` / `cjguiInternalExecuteDefaultRendererMetalDeviceLayerBindingDraft()`。
- 本轮是否改变 owner / truth / stop-line：是，新增三个 owner；truth 限于 availability、token-backed device lifecycle、token-backed layer binding facts；stop-line 继续禁止 drawable / command queue / GPU work / render / renderer state write / public API。
- 本轮是否改变唯一 next opening：是，指向 `P1 internal Renderer drawable acquisition planning preflight decision`。
- 是否同步 topic manifest：需要同步。
- 已同步哪些 topic manifest：本轮同步 `renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。

## 下游接续

已由 [Drawable acquisition 路线阶段收束复核](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-internal-renderer-drawable-acquisition-runway-stage-closure-review.md) 接续。下游只固定 no-acquire / still-blocked facts，不把本阶段 Metal device binding facts 升级为 drawable permission、present permission、command queue permission、render permission或 backend-ready truth。

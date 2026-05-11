# P1 内部渲染器 CAMetalLayer allocation/table runway 阶段封账

日期：2026-05-11

状态：closure review / A+B+C 已实现

## 本轮完成

本轮完成到 C 路线：

- A：新增 `CAMetalLayer` allocation without attachment feasibility C ABI、runtime owner 与 probe。
- B：新增 `CAMetalLayer` token-backed table shell C ABI、runtime owner 与 probe。
- C：新增 `CAMetalLayer` token-backed create/destroy first slice C ABI、runtime owner 与 probe。

本轮未进入 attach/detach，不设置 `NSView.layer` / `wantsLayer`，不设置 `CAMetalLayer.device`，不 import Metal，不获取 drawable，不创建 command buffer，不 render，不写 renderer state。

## 实际 owner

- `runtime/cjgui/src/runtime_renderer_cametallayer_allocation.cj`
- `runtime/cjgui/src/runtime_renderer_cametallayer_object_table.cj`
- `runtime/cjgui/src/runtime_renderer_cametallayer_create_destroy.cj`

## 实际 endpoint

- `CjguiInternalRendererNoCAMetalLayerAllocationReadiness`
- `CjguiInternalRendererNoCAMetalLayerObjectTableReadiness`
- `CjguiInternalRendererNoCAMetalLayerCreateDestroyReadiness`

最终 canonical tail：

`CjguiInternalRendererNoCAMetalLayerCreateDestroyReadiness` / `cjguiInternalExecuteDefaultRendererCAMetalLayerCreateDestroyDraft()`

## Native callable

Allocation feasibility：

- `cjgui_native_bridge_cametallayer_allocation_feasible`
- `cjgui_native_bridge_cametallayer_allocation_requires_main_thread`
- `cjgui_native_bridge_cametallayer_allocation_no_attach_admission`
- `cjgui_native_bridge_cametallayer_allocation_device_binding_blocked`
- `cjgui_native_bridge_cametallayer_allocation_feasibility_probe`

Table shell：

- `cjgui_native_bridge_cametallayer_table_capacity`
- `cjgui_native_bridge_cametallayer_table_enabled`
- `cjgui_native_bridge_cametallayer_table_empty`
- `cjgui_native_bridge_cametallayer_table_token_classify`
- `cjgui_native_bridge_cametallayer_table_allocation_still_blocked`
- `cjgui_native_bridge_cametallayer_table_destroy_still_blocked`

Create/destroy first slice：

- `cjgui_native_bridge_cametallayer_create`
- `cjgui_native_bridge_cametallayer_destroy`
- `cjgui_native_bridge_cametallayer_token_classify`
- `cjgui_native_bridge_cametallayer_table_occupied_count`
- `cjgui_native_bridge_cametallayer_double_destroy_classify`
- `cjgui_native_bridge_cametallayer_destroy_requires_main_thread`

## Probe 证据

- `verify_native_bridge_cametallayer_allocation_feasibility.sh` 通过，确认 main-thread allocation feasibility、background denied、no attach、no device、no drawable、no pointer return。
- `verify_native_bridge_cametallayer_object_table.sh` 通过，确认 fixed capacity、enabled、empty fact、invalid token fail-closed、allocation/destroy blocked facts。
- `verify_native_bridge_cametallayer_create_destroy.sh` 通过，确认 create -> classify valid -> occupied count -> destroy -> stale -> double destroy fail-closed，且 background create/destroy denied。

## 边界确认

- 没有 attach 到 `NSView`。
- 没有设置 `NSView.layer` / `wantsLayer`。
- 没有 import Metal。
- 没有创建 `MTLDevice` / queue / drawable / command buffer。
- 没有设置 `CAMetalLayer.device`。
- 没有调用 `nextDrawable`。
- 没有 render / GPU submission。
- 没有 public API / diagnostics。
- 没有修改 `runtime/cjgui/cjpm.toml`。
- 没有修改 smoke native files。
- 没有触碰 `runtime_state.cj`。

## 设计意图出口自检

- 本轮是否改变主题状态：是，`CAMetalLayer` 从 no-attach class facts 推进到 allocation/table/create-destroy first slice。
- 本轮是否改变 canonical tail / endpoint：是，转为 `CjguiInternalRendererNoCAMetalLayerCreateDestroyReadiness`。
- 本轮是否改变 owner / truth / stop-line：是，新增三个 runtime owner；truth 限于 token-backed layer lifecycle facts；stop-line 继续禁止 attach、Metal、drawable、public、state write。
- 本轮是否改变唯一 next opening：是，转为 `P1 internal Renderer CAMetalLayer NSView attach/detach preflight decision`。
- 是否同步 topic manifest：是，已在本轮 manifest stabilization 同步。
- 已同步哪些 topic manifest：`renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。

# P1 渲染器 CAMetalLayer allocation/table runway 清单

日期：2026-05-11

状态：manifest / completed through create-destroy first slice

## 清单结论

`CAMetalLayer` allocation/table runway 已完成到 C 路线：production native bridge 可以在 main thread 内创建并持有 fixed-capacity `CAMetalLayer` table entry，以 opaque token 表示 layer 身份，并支持 destroy / classify / occupied count / double destroy fail-closed。该 token 不返回 pointer / handle / `id` / `Class`，不绑定 Metal device，不 attach 到 `NSView`，不获取 drawable。

本 manifest 不把 `CAMetalLayer` token lifecycle 包装成 attachment permission、Metal device permission、drawable permission、backend-ready truth、render permission、GPU submission 或 renderer state write permission。

## Runtime owner 链

- Allocation owner：`runtime/cjgui/src/runtime_renderer_cametallayer_allocation.cj`
- Allocation endpoint：`CjguiInternalRendererNoCAMetalLayerAllocationReadiness`
- Allocation default draft：`cjguiInternalExecuteDefaultRendererCAMetalLayerAllocationDraft()`
- Object table owner：`runtime/cjgui/src/runtime_renderer_cametallayer_object_table.cj`
- Object table endpoint：`CjguiInternalRendererNoCAMetalLayerObjectTableReadiness`
- Object table default draft：`cjguiInternalExecuteDefaultRendererCAMetalLayerObjectTableDraft()`
- Create/destroy owner：`runtime/cjgui/src/runtime_renderer_cametallayer_create_destroy.cj`
- Create/destroy endpoint：`CjguiInternalRendererNoCAMetalLayerCreateDestroyReadiness`
- Create/destroy default draft：`cjguiInternalExecuteDefaultRendererCAMetalLayerCreateDestroyDraft()`

唯一 runtime input 起点：

`CjguiInternalRendererNoCAMetalLayerNoAttachCallReadiness`

最终 canonical tail：

`CjguiInternalRendererNoCAMetalLayerCreateDestroyReadiness`

## 固定 facts

- QuartzCore import / `CAMetalLayer` class availability 由上游 no-attach owner 提供。
- Allocation feasibility observed。
- Main-thread allocation required observed。
- Device binding blocked observed。
- Fixed-capacity table capacity is `4`。
- Invalid token fail-closed observed。
- Create -> classify valid -> destroy -> stale lifecycle observed。
- Occupied count lifecycle observed。
- Background create / destroy denied observed。
- Double destroy fail-closed observed。
- Token is opaque integer and not pointer-like。

## Stop-line

- no `NSView` attach。
- no `NSView.layer` / `wantsLayer` mutation。
- no Metal import。
- no `MTLDevice` / command queue / drawable / command buffer。
- no `CAMetalLayer.device` binding。
- no `nextDrawable`。
- no render / GPU submission。
- no public API / diagnostics。
- no `runtime/cjgui/cjpm.toml` change。
- no smoke native edits。
- no `runtime_state.cj` touch。
- no backend-ready truth。

## Probe

- `runtime/cjgui/native/scripts/verify_native_bridge_cametallayer_allocation_feasibility.sh`
- `runtime/cjgui/native/scripts/verify_native_bridge_cametallayer_object_table.sh`
- `runtime/cjgui/native/scripts/verify_native_bridge_cametallayer_create_destroy.sh`

## Downstream

唯一后续入口：

`P1 internal Renderer CAMetalLayer NSView attach/detach preflight decision`

已由 [CAMetalLayer NSView attachment manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-cametallayer-nsview-attachment-manifest.md) 接续并完成 C 路线；随后 [CAMetalLayer runtime attachment FFI call owner manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-cametallayer-runtime-attachment-ffi-call-owner-manifest.md) 已完成。当前唯一后续入口转为 `P1 internal Renderer Metal device binding planning preflight decision`。

## 设计意图出口自检

- 本轮是否改变主题状态：是，`CAMetalLayer` allocation/table runway 已完成到 token-backed create/destroy first slice。
- 本轮是否改变 canonical tail / endpoint：是，固定 `CjguiInternalRendererNoCAMetalLayerCreateDestroyReadiness` / `cjguiInternalExecuteDefaultRendererCAMetalLayerCreateDestroyDraft()`。
- 本轮是否改变 owner / truth / stop-line：是，新增 allocation / object table / create-destroy owners；truth 限于 no-attach layer token lifecycle；stop-line 继续禁止 attach、Metal、drawable、state write、public。
- 本轮是否改变唯一 next opening：是，转为 `P1 internal Renderer CAMetalLayer NSView attach/detach preflight decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。

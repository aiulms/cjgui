# P1 渲染器 CAMetalLayer NSView attachment 清单

日期：2026-05-11

状态：manifest / completed through token-backed attach-detach first slice

## 清单结论

`CAMetalLayer` NSView attachment runway 已完成 C 路线：production native bridge 可以在 main thread 内把 token-backed `CAMetalLayer` attach 到 token-backed `NSView`，随后 detach 并清理 table occupied count；所有结果只通过 `int32_t` status / classification 与 internal dehydrated facts 表达。

该清单不把 attachment facts 包装成 Metal device permission、drawable permission、backend-ready truth、render permission、GPU submission、renderer state write permission、public API permission 或 publication。

## Runtime owner

- Owner：`runtime/cjgui/src/runtime_renderer_cametallayer_nsview_attachment.cj`
- Endpoint：`CjguiInternalRendererNoCAMetalLayerNSViewAttachmentReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererCAMetalLayerNSViewAttachmentDraft()`
- Runtime input：`CjguiInternalRendererNoCAMetalLayerCreateDestroyReadiness`

## Native callable

- `cjgui_native_bridge_cametallayer_attach_to_nsview`
- `cjgui_native_bridge_cametallayer_detach_from_nsview`
- `cjgui_native_bridge_cametallayer_attachment_classify`
- `cjgui_native_bridge_cametallayer_double_detach_classify`
- `cjgui_native_bridge_cametallayer_attach_requires_main_thread`
- `cjgui_native_bridge_cametallayer_device_binding_after_attach_still_blocked`

## 固定 facts

- Attach / detach 必须 main-thread。
- Invalid layer token / invalid view token fail-closed。
- Stale layer token / stale view token fail-closed。
- Double attach / double detach fail-closed。
- Detach-before-destroy 由 native classification 保留。
- Cleanup 后 `NSView` table 与 `CAMetalLayer` table occupied count 回到 `0`。
- Device binding after attach 仍 blocked。
- Token 仍是不透明整数，不是 pointer cast。

## Stop-line

- no Metal import。
- no `MTLDevice` / command queue / drawable / command buffer。
- no `CAMetalLayer.device` binding。
- no `nextDrawable`。
- no render / GPU submission。
- no public API / diagnostics。
- no `runtime/cjgui/cjpm.toml` change。
- no smoke native edits。
- no `runtime_state.cj` touch。
- no pointer / handle / `id` / `Class` return。
- no backend-ready truth。

## Probe

- `runtime/cjgui/native/scripts/verify_native_bridge_cametallayer_nsview_attachment.sh`

回归 probe 继续覆盖 CAMetalLayer create/destroy / object table / allocation / no-attach、NSView runtime call / create-destroy / object table / feasibility / no-object creation、AppKit import / class / main-thread、teardown、token issue/revoke、no-resource call、isolated FFI、package link、cjpm package link、skeleton compile、symbol probe 与 cjpm boundary。

## Downstream

唯一后续入口：

`P1 internal Renderer CAMetalLayer runtime attachment FFI call owner preflight decision`

后续 [CAMetalLayer runtime attachment FFI call owner manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-cametallayer-runtime-attachment-ffi-call-owner-manifest.md) 已完成。该下游新增 `runtime/cjgui/src/runtime_renderer_cametallayer_attachment_runtime_call.cj` 与 runtime-adjacent probe，复用本 manifest 固定的 attachment C ABI，只生成 internal dehydrated facts；它不修改 `runtime/cjgui/cjpm.toml`，不新增 public API，不 import Metal，不设置 `CAMetalLayer.device`，不获取 drawable，不写 renderer state，也不把 attachment runtime call 解释成 backend-ready truth。

## 设计意图出口自检

- 本轮是否改变主题状态：是，`CAMetalLayer` platform layer route 已完成到 token-backed `NSView` attach/detach first slice。
- 本轮是否改变 canonical tail / endpoint：是，固定 `CjguiInternalRendererNoCAMetalLayerNSViewAttachmentReadiness` / `cjguiInternalExecuteDefaultRendererCAMetalLayerNSViewAttachmentDraft()`。
- 本轮是否改变 owner / truth / stop-line：是，新增 attachment owner 与 C ABI；truth 限于 attachment lifecycle facts；stop-line 继续禁止 Metal、device、drawable、state write、public。
- 本轮是否改变唯一 next opening：是，转为 `P1 internal Renderer CAMetalLayer runtime attachment FFI call owner preflight decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。

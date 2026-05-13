# P1 渲染器 CAMetalLayer runtime attachment FFI call owner 清单

日期：2026-05-11

状态：manifest / completed

## 清单结论

`CAMetalLayer` runtime attachment FFI call owner 已完成。Runtime internal owner 可以调用 token-backed `CAMetalLayer` attach / detach / classify C ABI，并只把结果脱水成 internal facts。所有 token 均保持函数局部，不进入 module-level mutable state，不返回 public surface，不写 renderer state。

本清单不把 runtime attachment facts 包装成 Metal device permission、drawable permission、backend-ready truth、render permission、GPU submission、renderer state write permission、public API permission 或 publication。

## Runtime owner

- Owner：`runtime/cjgui/src/runtime_renderer_cametallayer_attachment_runtime_call.cj`
- Endpoint：`CjguiInternalRendererNoCAMetalLayerAttachmentRuntimeCallReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererCAMetalLayerAttachmentRuntimeCallDraft()`
- Runtime input：`CjguiInternalRendererNoCAMetalLayerNSViewAttachmentReadiness`

## Runtime call route

- 复用同 package 已验证的 internal `foreign func` declaration。
- `NSView` token 与 `CAMetalLayer` token 只在函数局部创建、使用、清理。
- Runtime owner 调用 attach -> classify attached -> detach -> double detach classify -> destroy cleanup。
- Runtime-adjacent probe 使用临时 `cjpm` package 复核同一调用路径。
- `runtime/cjgui/cjpm.toml` 未修改。

## Called C ABI

- `cjgui_native_bridge_nsview_create`
- `cjgui_native_bridge_nsview_destroy`
- `cjgui_native_bridge_nsview_table_occupied_count`
- `cjgui_native_bridge_cametallayer_create`
- `cjgui_native_bridge_cametallayer_destroy`
- `cjgui_native_bridge_cametallayer_table_occupied_count`
- `cjgui_native_bridge_cametallayer_attach_to_nsview`
- `cjgui_native_bridge_cametallayer_detach_from_nsview`
- `cjgui_native_bridge_cametallayer_attachment_classify`
- `cjgui_native_bridge_cametallayer_double_detach_classify`
- `cjgui_native_bridge_cametallayer_attach_requires_main_thread`
- `cjgui_native_bridge_cametallayer_device_binding_after_attach_still_blocked`

## 固定 facts

- Runtime attachment call path observed。
- Attach / detach 必须 main-thread。
- Attach 后 classify 为 attached。
- Detach 后 classify 为 not-attached。
- Double detach fail-closed。
- Cleanup 后 `NSView` table 与 `CAMetalLayer` table occupied count 为 `0`。
- Device binding after attach still blocked。
- No token persistence。
- No public API。
- No renderer state write。
- No Metal import / device / drawable / render。

## Probe

- `runtime/cjgui/native/scripts/verify_native_bridge_cametallayer_attachment_runtime_call.sh`

该 probe 只验证 runtime-adjacent FFI call path 与 source stop-line，不修改 package config，不替代 public API，也不证明 backend ready。

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

## Downstream

唯一后续入口：

`P1 internal Renderer Metal device binding planning preflight decision`

后续 [Metal device binding runway manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-metal-device-binding-runway-manifest.md) 已完成。该下游把本阶段的 token-backed `CAMetalLayer` attachment runtime facts 接续为 `Metal` import、default `MTLDevice` availability、token-backed `MTLDevice` create / destroy 与 `CAMetalLayer.device` bind / unbind first slice；下游仍不授权 `nextDrawable`、drawable acquisition、command queue、command buffer、GPU submission、render、renderer state write、public API 或 pointer / handle / `id` / `Class` return。

Metal device binding 后续又由 [Drawable acquisition 路线封账清单](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-drawable-acquisition-runway-manifest.md)、[Drawable acquisition recovery 清单](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-drawable-acquisition-first-implementation-manifest.md) 与 [Drawable environment / window visibility planning 清单](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-drawable-environment-window-visibility-manifest.md) 接续。当前下游仍只固定 environment / visibility planning facts，不调用 `nextDrawable`，不 present，不创建 command queue / command buffer / encoder。

后续还由 [production drawable texture lifetime 清单](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-production-drawable-texture-lifetime-manifest.md) 复核为 upstream evidence：attachment runtime facts 只证明 token-backed layer 可附着到 token-backed `NSView` 并 cleanup，不证明 production drawable texture lifetime、drawable release、descriptor cleanup co-ownership、color attachment、present、commit、GPU submission 或 render。

## 设计意图出口自检

- 本轮是否改变主题状态：是，`CAMetalLayer` route 已完成到 runtime internal attachment FFI call owner。
- 本轮是否改变 canonical tail / endpoint：是，固定 `CjguiInternalRendererNoCAMetalLayerAttachmentRuntimeCallReadiness` / `cjguiInternalExecuteDefaultRendererCAMetalLayerAttachmentRuntimeCallDraft()`。
- 本轮是否改变 owner / truth / stop-line：是，新增 runtime attachment call owner；truth 限于 internal attachment call facts；stop-line 继续禁止 Metal、device、drawable、render、public、state write。
- 本轮是否改变唯一 next opening：是，转为 `P1 internal Renderer Metal device binding planning preflight decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。

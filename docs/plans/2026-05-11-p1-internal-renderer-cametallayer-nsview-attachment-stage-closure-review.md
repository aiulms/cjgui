# P1 内部渲染器 CAMetalLayer NSView attachment 阶段封账

日期：2026-05-11

状态：stage closure / C 路线完成

## 封账结论

本轮完成 token-backed `CAMetalLayer` attach/detach 到 token-backed `NSView` 的 first slice。Production native bridge 新增 attachment C ABI，runtime 新增 internal owner，并通过 dedicated probe 验证 create `NSView` token、create `CAMetalLayer` token、attach、classify attached、detach、double detach fail-closed、invalid / stale token fail-closed 与 cleanup occupied count 归零。

该结果只证明 main-thread 内部 attachment lifecycle 可以被 token 与 fail-closed classification 管住；不证明 Metal device binding、drawable acquisition、render execution、GPU submission、backend-ready truth、renderer state write 或 public API permission。

## 实际写集

- Native header / source：`runtime/cjgui/native/cjgui_native_bridge.h`、`runtime/cjgui/native/cjgui_native_bridge.m`
- Runtime owner：`runtime/cjgui/src/runtime_renderer_cametallayer_nsview_attachment.cj`
- Probe：`runtime/cjgui/native/scripts/verify_native_bridge_cametallayer_nsview_attachment.sh`
- 回归脚本 allowlist / scan 收窄：只允许本阶段 attach C ABI，继续禁止 Metal、device、drawable、pointer return 与 public surface。
- 文档：本轮 preflight、closure、next-boundary、manifest 与 manifest closure。

## 新增 C ABI

- `cjgui_native_bridge_cametallayer_attach_to_nsview`
- `cjgui_native_bridge_cametallayer_detach_from_nsview`
- `cjgui_native_bridge_cametallayer_attachment_classify`
- `cjgui_native_bridge_cametallayer_double_detach_classify`
- `cjgui_native_bridge_cametallayer_attach_requires_main_thread`
- `cjgui_native_bridge_cametallayer_device_binding_after_attach_still_blocked`

所有 callable 只返回 `int32_t` status / classification；不返回 pointer、handle、`id` 或 `Class`。

## Runtime owner

- Owner：`runtime/cjgui/src/runtime_renderer_cametallayer_nsview_attachment.cj`
- Endpoint：`CjguiInternalRendererNoCAMetalLayerNSViewAttachmentReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererCAMetalLayerNSViewAttachmentDraft()`
- Runtime input：`CjguiInternalRendererNoCAMetalLayerCreateDestroyReadiness`

Owner 只在函数局部持有 token，调用 attach / detach / classify C ABI 并脱水为 internal facts；不保存 token，不写 renderer state，不新增 public API。

## 验证摘要

- 新 attachment probe 通过。
- `cjpm build --target-dir /tmp/cjgui-renderer-cametallayer-nsview-attachment-target --skip-script` 通过，仅保留既有 unused warnings。
- CAMetalLayer create/destroy、object table、allocation、no-attach；NSView runtime-call、create/destroy、object table、feasibility、no-object creation；AppKit import / class / main-thread；teardown；token issue/revoke；no-resource call；isolated FFI；package link；cjpm package link；skeleton compile；symbol probe；cjpm boundary 均已回归通过。

## Downstream

后续 [CAMetalLayer runtime attachment FFI call owner manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-cametallayer-runtime-attachment-ffi-call-owner-manifest.md) 已完成。该下游新增 runtime internal call owner 与 runtime-adjacent probe，继续禁止 Metal、device、drawable、public API、renderer state write 与 backend-ready truth。

## 保持的 stop-line

- 不 import Metal。
- 不创建 `MTLDevice` / command queue / drawable / command buffer。
- 不设置 `CAMetalLayer.device`。
- 不调用 `nextDrawable`。
- 不创建 `NSWindow` / `NSApplication`。
- 不返回 pointer / handle / `id` / `Class`。
- 不新增 public API / diagnostics。
- 不修改 `runtime/cjgui/cjpm.toml`。
- 不修改 smoke native files。
- 不触碰 `runtime_state.cj`。
- 不写 renderer state。
- 不创建 backend-ready truth。

## 设计意图出口自检

- 本轮是否改变主题状态：是，从 `CAMetalLayer` token lifecycle 推进到 token-backed `NSView` attachment first slice。
- 本轮是否改变 canonical tail / endpoint：是，tail 转为 `CjguiInternalRendererNoCAMetalLayerNSViewAttachmentReadiness` / `cjguiInternalExecuteDefaultRendererCAMetalLayerNSViewAttachmentDraft()`。
- 本轮是否改变 owner / truth / stop-line：是，新增 attachment owner 与 C ABI；truth 限于 main-thread attach/detach facts；stop-line 继续禁止 Metal、device、drawable、render、public、state write。
- 本轮是否改变唯一 next opening：是，若 manifest stabilization 成功则转为 `P1 internal Renderer CAMetalLayer runtime attachment FFI call owner preflight decision`。
- 是否同步 topic manifest：将在 manifest stabilization 同步。
- 已同步哪些 topic manifest：阶段 closure 记录为待同步。

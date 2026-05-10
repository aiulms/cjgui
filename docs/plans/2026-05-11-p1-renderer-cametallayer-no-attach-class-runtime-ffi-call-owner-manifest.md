# P1 渲染器 CAMetalLayer no-attach 类可见性与 runtime 调用清单

日期：2026-05-11

状态：manifest stabilization / no-attach class runtime owner

## 清单结论

`CAMetalLayer` no-attach class/runtime FFI call owner 已封账。Actual route 是 A：production bridge 允许 QuartzCore import，只做 `CAMetalLayer` class lookup、no-attach admission、allocation still blocked 与 Metal device binding still blocked facts；runtime internal owner 调用这些 C ABI 并脱水为 internal facts。

本 manifest 不把 QuartzCore import、class lookup、no-attach C ABI、runtime internal call 或 probe evidence 升格为 layer allocation permission、layer attachment permission、Metal device permission、drawable permission、backend-ready truth、render permission、GPU submission 或 renderer state write permission。

## Runtime owner

- Owner：`runtime/cjgui/src/runtime_renderer_cametallayer_no_attach_call.cj`
- Endpoint：`CjguiInternalRendererNoCAMetalLayerNoAttachCallReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererCAMetalLayerNoAttachCallDraft()`
- Runtime input：`CjguiInternalRendererNoCAMetalLayerAttachmentReadiness`

## Native callable

- `cjgui_native_bridge_quartzcore_import_available(void)` -> `int32_t`
- `cjgui_native_bridge_cametallayer_class_available(void)` -> `int32_t`
- `cjgui_native_bridge_cametallayer_no_attach_admission(void)` -> `int32_t`
- `cjgui_native_bridge_cametallayer_allocation_still_blocked(void)` -> `int32_t`
- `cjgui_native_bridge_cametallayer_device_binding_still_blocked(void)` -> `int32_t`

## 固定 facts

- QuartzCore import available observed。
- `CAMetalLayer` class available observed。
- no-attach admission observed。
- allocation still blocked observed。
- device binding still blocked observed。
- no layer object creation confirmed。
- no layer attachment confirmed。
- no Metal device / drawable confirmed。
- no pointer / handle / `id` / `Class` return confirmed。
- no public surface / diagnostics confirmed。
- no renderer state write confirmed。
- no backend-ready truth confirmed。

## Probe 与验证角色

新增 probe：

- `runtime/cjgui/native/scripts/verify_native_bridge_cametallayer_no_attach.sh`

该 probe 只证明 no-attach class lookup / C ABI / FFI call path 可复核。它检查符号存在、可调用、返回 no-attach facts，并扫描 source 中没有 `CAMetalLayer` / `CALayer` allocation、没有 `NSView.layer` attachment、没有 `wantsLayer`、没有 Metal import、没有 `MTLDevice` / queue / drawable / command buffer、没有 pointer / handle / `id` / `Class` return。

## 文档链

- [preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-cametallayer-no-attach-class-runtime-ffi-call-owner-preflight-decision.md)
- [closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-internal-renderer-cametallayer-no-attach-class-runtime-ffi-call-owner-stage-closure-review.md)
- [next-boundary](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-cametallayer-no-attach-class-runtime-ffi-call-owner-next-boundary-decision.md)
- [manifest closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-internal-renderer-cametallayer-no-attach-class-runtime-ffi-call-owner-manifest-stabilization-closure-review.md)

## 固定边界

- QuartzCore import is allowed only for no-attach class availability facts。
- no Metal import。
- no `CAMetalLayer` / `CALayer` allocation。
- no `NSView.layer` attachment。
- no `wantsLayer` mutation。
- no `MTLDevice` / `MTLCommandQueue`。
- no drawable / command buffer / GPU submission。
- no pointer / handle / `id` / `Class` return。
- no public API / diagnostics。
- no renderer state write。
- no `runtime_state.cj` touch。
- no backend-ready truth。

## 后续入口

唯一后续入口：

`P1 internal Renderer CAMetalLayer allocation without attachment preflight decision`

## 设计意图出口自检

- 本轮是否改变主题状态：是，`CAMetalLayer` no-attach class/runtime FFI call owner 已 manifest stabilization。
- 本轮是否改变 canonical tail / endpoint：是，固定 `CjguiInternalRendererNoCAMetalLayerNoAttachCallReadiness` / `cjguiInternalExecuteDefaultRendererCAMetalLayerNoAttachCallDraft()`。
- 本轮是否改变 owner / truth / stop-line：是，owner 固定为 `runtime_renderer_cametallayer_no_attach_call.cj`；truth 固定为 no-attach class lookup / runtime observed facts；stop-line 固定为 no layer allocation / no attachment / no Metal / no drawable / no state write / no public。
- 本轮是否改变唯一 next opening：是，转为 `P1 internal Renderer CAMetalLayer allocation without attachment preflight decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。

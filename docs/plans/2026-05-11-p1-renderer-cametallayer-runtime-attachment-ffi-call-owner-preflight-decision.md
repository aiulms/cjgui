# P1 渲染器 CAMetalLayer runtime attachment FFI call owner 预检

日期：2026-05-11

状态：preflight / 选择 A

## 预检结论

本阶段可以进入 `CAMetalLayer` attachment runtime FFI call owner first slice。上游 `CjguiInternalRendererNoCAMetalLayerNSViewAttachmentReadiness` 已封账，production native C ABI 已验证 token-backed `CAMetalLayer` attach / detach 到 token-backed `NSView` 的 main-thread lifecycle，并保持 cleanup occupied count 归零。

本轮不新增 production native C ABI，不修改 `runtime/cjgui/cjpm.toml`，不修改 smoke native files。Runtime owner 只复用同 package 已验证的 internal `foreign func` declaration 形态，局部执行 create `NSView` token、create `CAMetalLayer` token、attach、classify、detach、double-detach classify 与 cleanup destroy，并把结果脱水为 internal facts。

## 路线选择

选择 A：`P1 internal Renderer CAMetalLayer runtime attachment FFI call owner first implementation bundle`。

选择依据：

- `UInt64` token 参数与 `Int32` classification 返回值已在上游 owner、probe 与 `cjpm build --skip-script` 中稳定。
- `CPointer<UInt64>` / `inout` out-token 语法已由 `NSView` runtime call owner 与 `CAMetalLayer` create/destroy owner 复核。
- Attachment C ABI 已由 dedicated native probe 证明可在 main thread 内 attach / detach，并在 cleanup 后归零。
- 本阶段不需要持久化 token，也不需要修改 package config。

## Runtime owner 准入

- 新 owner：`runtime/cjgui/src/runtime_renderer_cametallayer_attachment_runtime_call.cj`
- Endpoint：`CjguiInternalRendererNoCAMetalLayerAttachmentRuntimeCallReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererCAMetalLayerAttachmentRuntimeCallDraft()`
- Runtime input：`CjguiInternalRendererNoCAMetalLayerNSViewAttachmentReadiness`

Owner 允许调用：

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

## 失败分类

- 任一 create 失败：runtime facts fail-closed。
- Attach 未返回成功或 classify 未返回 attached：runtime facts fail-closed。
- Detach 未返回成功或 double detach 未 fail-closed：runtime facts fail-closed。
- Cleanup 后 occupied count 未归零：runtime facts fail-closed。
- Device binding 不是 blocked：runtime facts fail-closed。

## GitNexus 预检

对上游 endpoint / default draft 与新增 endpoint / native attach symbol 运行 impact，结果均为近期新增符号未索引 / UNKNOWN，`impactedCount=0`，无 HIGH / CRITICAL。按阶段规则使用源码、build、runtime-adjacent probe 与 forbidden scan 兜底。

## Stop-line

- 不 import Metal。
- 不创建 `MTLDevice` / command queue / drawable / command buffer。
- 不设置 `CAMetalLayer.device`。
- 不调用 `nextDrawable`。
- 不写 renderer state。
- 不触碰 `runtime_state.cj`。
- 不修改 `runtime/cjgui/cjpm.toml`。
- 不修改 smoke native files。
- 不新增 public API / diagnostics。
- 不返回 pointer / handle / `id` / `Class`。
- 不把 runtime attachment facts 解释成 backend-ready truth、render permission、GPU submission permission 或 state write permission。

## 设计意图出口自检

- 本轮是否改变主题状态：预期改变，从 token-backed attachment first slice 进入 runtime internal FFI call owner。
- 本轮是否改变 canonical tail / endpoint：预期改变为 `CjguiInternalRendererNoCAMetalLayerAttachmentRuntimeCallReadiness`。
- 本轮是否改变 owner / truth / stop-line：预期新增 runtime owner；truth 仅限 internal dehydrated runtime call facts；stop-line 继续禁止 Metal、device、drawable、public、state write。
- 本轮是否改变唯一 next opening：预期完成后转为 `P1 internal Renderer Metal device binding planning preflight decision`。
- 是否同步 topic manifest：将在 manifest stabilization 同步。
- 已同步哪些 topic manifest：预检阶段记录为待同步。

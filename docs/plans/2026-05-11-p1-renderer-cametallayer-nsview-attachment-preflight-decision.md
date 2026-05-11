# P1 渲染器 CAMetalLayer NSView attachment 预检

日期：2026-05-11

状态：preflight decision / 选择 C 路线

## 预检结论

`CjguiInternalRendererNoCAMetalLayerCreateDestroyReadiness` 已封账，且上游 `NSView` create/destroy、`CAMetalLayer` create/destroy、token issue/revoke、teardown admission 与 backend NSView platform integration 均已提供可复核证据。本轮允许进入 C 路线：

`P1 internal Renderer CAMetalLayer NSView token-backed attach/detach first slice`

该选择只允许在 production native bridge 内部使用 token-backed `NSView` 与 token-backed `CAMetalLayer` 进行 main-thread attach/detach，并把结果脱水为 internal facts。它不授权 Metal、device、drawable、render、GPU submission、backend-ready truth、public API 或 renderer state write。

## 风险门判断

- 是否允许真实 attach/detach：允许，但仅限 C ABI 内部的 `NSView.wantsLayer` / `NSView.layer` mutation，并必须由 probe 证明 cleanup 后 table occupied count 归零。
- 是否允许 import Metal：不允许。
- 是否允许创建 `MTLDevice` / command queue / drawable / command buffer：不允许。
- 是否允许设置 `CAMetalLayer.device`：不允许。
- 是否允许调用 `nextDrawable`：不允许。
- 是否允许返回 pointer / handle / `id` / `Class`：不允许。
- 是否允许修改 `runtime/cjgui/cjpm.toml`：不允许。
- 是否允许写 `runtime_state.cj`：不允许。
- 是否允许新增 public API / diagnostics：不允许。

## 选择路线

选择 C：

- 新增 production native attach/detach C ABI。
- 新增 runtime internal owner `runtime_renderer_cametallayer_nsview_attachment.cj`。
- 新增 probe `verify_native_bridge_cametallayer_nsview_attachment.sh`。
- 验证 create `NSView` token -> create `CAMetalLayer` token -> attach -> classify attached -> detach -> double detach fail-closed -> destroy cleanup。

本轮拒绝直接进入 Metal device binding。原因是 attachment 只证明 `CAMetalLayer` 可被设置为 `NSView.layer`，不证明可绑定 device、不证明可获取 drawable、不证明可 render。

## GitNexus 预检

已对上游 endpoint / default draft 与相关 native symbol 运行 impact：

- `CjguiInternalRendererNoCAMetalLayerCreateDestroyReadiness`：not found / UNKNOWN。
- `cjguiInternalExecuteDefaultRendererCAMetalLayerCreateDestroyDraft`：not found / UNKNOWN。
- `cjgui_native_bridge_cametallayer_create`：not found / UNKNOWN。
- `cjgui_native_bridge_cametallayer_destroy`：not found / UNKNOWN。
- `cjgui_native_bridge_surface_capabilities`：not found / UNKNOWN。
- `cjgui_native_bridge_cametallayer_attach_to_nsview`：not found / UNKNOWN。
- `CjguiInternalRendererNoCAMetalLayerNSViewAttachmentReadiness`：not found / UNKNOWN。

记录为近期新增 native/runtime owner 尚未索引；本轮用源码、build、probe、scan 与最终 `detect_changes` 兜底。未收到 HIGH / CRITICAL blast radius。

## 设计意图出口自检

- 本轮是否改变主题状态：是，从 `CAMetalLayer` create/destroy first slice 进入 attachment runway。
- 本轮是否改变 canonical tail / endpoint：预检阶段准备转向 `CjguiInternalRendererNoCAMetalLayerNSViewAttachmentReadiness`。
- 本轮是否改变 owner / truth / stop-line：是，计划新增 attachment owner；truth 限于 token-backed attach/detach facts；stop-line 继续禁止 Metal、device、drawable、render、public、state write。
- 本轮是否改变唯一 next opening：是，若 C 成功则转向 `P1 internal Renderer CAMetalLayer runtime attachment FFI call owner preflight decision`。
- 是否同步 topic manifest：是，已在本轮 manifest stabilization 同步。
- 已同步哪些 topic manifest：`renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。

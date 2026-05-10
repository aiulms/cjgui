# P1 内部渲染器 CAMetalLayer attachment planning 阶段封账

日期：2026-05-10

状态：closure review / no-attach value owner 已落地

## 本轮结论

本轮完成 `P1 internal Renderer CAMetalLayer attachment planning stage bundle` 的 planning value owner。Actual route 是 no-attach value boundary：只消费 `CjguiInternalRendererNoBackendNsViewPlatformIntegrationReadiness`，固定 QuartzCore import admission policy、`CAMetalLayer` class availability observation policy、`NSView.layer` attachment still blocked、no Metal device binding、no drawable acquisition、main-thread attachment gate 与 detach-before-destroy dependency。

本轮没有新增 native C ABI，没有新增 probe，没有修改 production native bridge，没有修改 `runtime/cjgui/cjpm.toml`，也没有触碰 `runtime_state.cj`。没有创建 `CAMetalLayer` / `CALayer`，没有设置 `NSView.layer` / `wantsLayer`，没有导入 QuartzCore / Metal。

## 实际写集

- 新增 [runtime_renderer_cametallayer_attachment_planning.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_cametallayer_attachment_planning.cj)。
- 新增本阶段 preflight、closure、next-boundary、manifest 与 manifest closure。
- 同步 README、tracker、plans README、runtime README、设计意图索引与三个 topic manifest。
- 给上游 `NSView` backend integration、real Metal device-layer shell、native teardown admission 与 token issue/revoke 文档补 downstream 指向。

未修改：

- `runtime/cjgui/native/cjgui_native_bridge.h`
- `runtime/cjgui/native/cjgui_native_bridge.m`
- `runtime/cjgui/cjpm.toml`
- `runtime/cjgui/src/runtime_state.cj`
- `labs/macos_bridge_smoke` native files
- public runtime API / diagnostics

## Owner 与 truth

- Owner：`runtime/cjgui/src/runtime_renderer_cametallayer_attachment_planning.cj`
- Endpoint：`CjguiInternalRendererNoCAMetalLayerAttachmentReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererCAMetalLayerAttachmentDraft()`
- Runtime input：`CjguiInternalRendererNoBackendNsViewPlatformIntegrationReadiness`

Current truth 只包括：

- `CAMetalLayer` attachment intent。
- QuartzCore import 仍需后续 preflight。
- `CAMetalLayer` class availability observation policy。
- `CAMetalLayer` class availability probe optional。
- `NSView.layer` attachment still blocked。
- no `CAMetalLayer` / `CALayer` creation。
- no `wantsLayer` mutation。
- no Metal device binding。
- no drawable acquisition。
- main-thread attachment gate。
- detach-before-destroy dependency。
- class unavailable / background thread / invalid `NSView` token / attachment blocked fail-closed classification。
- no public surface / diagnostics。
- no renderer state write / backend-ready truth。

## 停止线

- 不 import QuartzCore / Metal。
- 不创建 `CAMetalLayer` / `CALayer`。
- 不设置 `NSView.layer` 或 `wantsLayer`。
- 不创建 `MTLDevice` / `MTLCommandQueue`。
- 不获取 drawable，不调用 `nextDrawable`。
- 不创建 command buffer，不调用 `commandBuffer` / `commit` / `present`。
- 不写 renderer state，不触碰 `runtime_state.cj`。
- 不修改 `runtime/cjgui/cjpm.toml`。
- 不新增 public API / diagnostics。
- 不把 planning facts 包装成 backend-ready、render permission、GPU submission、state write、receipt、record 或 publication。

## 下游入口

唯一 next opening：

`P1 internal Renderer CAMetalLayer no-attach class/runtime FFI call owner preflight decision`

该入口只能评估是否允许 no-attach class availability C ABI / runtime internal call owner；仍不得创建或 attach layer，不得导入 Metal，不得创建 `MTLDevice` / drawable，不得写 renderer state 或 public API。

下游已由 [2026-05-11 CAMetalLayer no-attach class/runtime FFI call owner manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-cametallayer-no-attach-class-runtime-ffi-call-owner-manifest.md) 承接。

## 设计意图出口自检

- 本轮是否改变主题状态：是，从 `NSView` backend shell integration 推进到 `CAMetalLayer` attachment planning no-attach value owner。
- 本轮是否改变 canonical tail / endpoint：是，最新 endpoint 为 `CjguiInternalRendererNoCAMetalLayerAttachmentReadiness` / `cjguiInternalExecuteDefaultRendererCAMetalLayerAttachmentDraft()`。
- 本轮是否改变 owner / truth / stop-line：是，新增 `runtime_renderer_cametallayer_attachment_planning.cj`；truth 限定为 planning facts；stop-line 继续禁止 QuartzCore / Metal import、layer creation / attachment、Metal device、drawable、renderer state write、public API。
- 本轮是否改变唯一 next opening：是，转为 `P1 internal Renderer CAMetalLayer no-attach class/runtime FFI call owner preflight decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。

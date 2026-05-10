# P1 内部渲染器 platform object NSView backend shell integration 清单稳定化封账

日期：2026-05-10

状态：manifest stabilization closure / 已封账

## 封账结论

本轮 manifest stabilization 完成。`runtime_renderer_backend_nsview_platform_integration.cj` 成为当前 `NSView` platform object 到 renderer backend shell integration 的 internal owner，canonical endpoint 固定为：

`CjguiInternalRendererNoBackendNsViewPlatformIntegrationReadiness` / `cjguiInternalExecuteDefaultRendererBackendNsViewPlatformIntegrationDraft()`

该 endpoint 只证明 backend shell integration facts 已被脱水表达，不证明 backend ready，不授权 renderer state write，不授权 `CAMetalLayer` attachment，不授权 Metal resource 创建。

## Actual route

- Route：runtime internal value owner。
- Runtime input：`CjguiInternalRendererNoPlatformObjectNsViewRuntimeCallReadiness`。
- Native C ABI：本轮未新增。
- Probe：本轮未新增，复用上游 full probe matrix。
- Package config：`runtime/cjgui/cjpm.toml` 未修改。
- Native bridge：production `.h/.m` 未修改。

## 固定 stop-line

- no public API / diagnostics。
- no renderer state write。
- no `runtime_state.cj` touch。
- no layer / Metal resource。
- no Metal / QuartzCore import。
- no token / pointer / handle / `id` / `Class` public exposure。
- no backend-ready truth。
- no GPU submission。
- no render execution。
- no receipt / record / publication wrapper。

## 后续入口

唯一 next opening：

`P1 internal Renderer CAMetalLayer attachment planning preflight decision`

该入口必须继续保持 planning-first；任何 `CALayer` / `CAMetalLayer` creation、QuartzCore / Metal import、`MTLDevice` / `MTLCommandQueue` creation、renderer state write、public API 或 backend-ready truth 都必须另开 preflight，不得由本清单隐含授权。

## 设计意图出口自检

- 本轮是否改变主题状态：是，`NSView` backend shell integration value owner 已封账。
- 本轮是否改变 canonical tail / endpoint：是，固定 `CjguiInternalRendererNoBackendNsViewPlatformIntegrationReadiness` / `cjguiInternalExecuteDefaultRendererBackendNsViewPlatformIntegrationDraft()`。
- 本轮是否改变 owner / truth / stop-line：是，owner / truth / stop-line 已在 manifest 中固定。
- 本轮是否改变唯一 next opening：是，固定为 `P1 internal Renderer CAMetalLayer attachment planning preflight decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。

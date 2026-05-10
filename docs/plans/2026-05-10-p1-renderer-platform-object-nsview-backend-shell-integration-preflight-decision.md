# P1 渲染器 platform object NSView backend shell integration 预检结论

日期：2026-05-10

状态：preflight decision / 选择 integration value owner

## 背景

上游 `CjguiInternalRendererNoPlatformObjectNsViewRuntimeCallReadiness` 已封账，`runtime_renderer_platform_object_nsview_runtime_call.cj` 已证明 runtime internal owner 可以在 internal-only 范围内观察 token-backed `NSView` create / classify / destroy / occupied-count / stale / double-destroy fail-closed facts。

本阶段目标不是创建新的 platform object，也不是把 `NSView` token 接进 renderer state，而是判断这些 runtime-call facts 是否可以进入 renderer backend shell integration facts。

## 预检判断

- package link / runtime call evidence 足够进入 backend shell integration value owner。
- 不需要新增 native C ABI；既有 `NSView` runtime call owner 与 probe 已覆盖需要的 upstream evidence。
- 不需要修改 `runtime/cjgui/cjpm.toml`；package config 仍不作为本阶段 truth。
- 不需要新增 renderer state write；本阶段只生成 internal dehydrated facts。
- 不允许创建 `CAMetalLayer` / `CALayer` / `MTLDevice` / `MTLCommandQueue`，也不允许导入 Metal / QuartzCore。
- 不允许把 `NSView` token 保存到 module-level mutable state，也不允许返回 token / pointer / handle 到 public surface。
- backend-ready truth 必须继续保持 false / blocked / not-admitted 语义。

## 选择路线

选择 A：

`P1 internal Renderer platform object NSView backend shell integration value owner`

实施方式：

- 新增 `runtime/cjgui/src/runtime_renderer_backend_nsview_platform_integration.cj`。
- 新增 endpoint `CjguiInternalRendererNoBackendNsViewPlatformIntegrationReadiness`。
- 新增 default draft `cjguiInternalExecuteDefaultRendererBackendNsViewPlatformIntegrationDraft()`。
- 唯一 runtime input 是 `CjguiInternalRendererNoPlatformObjectNsViewRuntimeCallReadiness`。
- 只表达 `NSView` runtime call evidence accepted、backend shell platform candidate intent、token locality preserved、no renderer-state-write、no Metal layer binding、no backend-ready truth、teardown-before-backend-ready dependency 与 main-thread backend platform admission guard。

## GitNexus 影响记录

- `CjguiInternalRendererNoPlatformObjectNsViewRuntimeCallReadiness`：GitNexus impact 返回 not found / `UNKNOWN` / impacted count `0`。
- `cjguiInternalExecuteDefaultRendererPlatformObjectNsViewRuntimeCallDraft`：GitNexus impact 返回 not found / `UNKNOWN` / impacted count `0`。

该结果按近期新增 owner 尚未索引处理。本阶段用源码阅读、主包 build、probe 矩阵、public declaration scan、native forbidden scan、protected path scan 与 GitNexus detect changes 兜底。

## 拒绝路线

- 拒绝新增 public API / diagnostics。
- 拒绝写 `runtime_state.cj` 或 renderer state。
- 拒绝新增 native C ABI。
- 拒绝创建 `CAMetalLayer` / `CALayer` / `MTLDevice` / `MTLCommandQueue`。
- 拒绝导入 Metal / QuartzCore。
- 拒绝跨函数持久化 token。
- 拒绝把 integration facts 包装成 backend-ready truth、render permission、GPU submission permission、renderer state write permission、receipt / record / publication。

## 设计意图出口自检

- 本轮是否改变主题状态：预期是，从 `NSView` runtime call owner 进入 backend shell integration value owner。
- 本轮是否改变 canonical tail / endpoint：预期是，若 build / scan 通过将转为 `CjguiInternalRendererNoBackendNsViewPlatformIntegrationReadiness`。
- 本轮是否改变 owner / truth / stop-line：预期是，新增 backend `NSView` platform integration owner；truth 只限 integration facts；stop-line 继续禁止 public / state write / layer / Metal / backend-ready。
- 本轮是否改变唯一 next opening：预期是，若封账成功转为 `P1 internal Renderer CAMetalLayer attachment planning preflight decision`。
- 是否同步 topic manifest：预期同步。
- 已同步哪些 topic manifest：待 closure 固定。

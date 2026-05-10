# P1 内部渲染器 platform object NSView backend shell integration 阶段封账

日期：2026-05-10

状态：closure review / value owner 已落地

## 本轮结论

本轮完成 `P1 internal Renderer platform object NSView renderer backend shell integration stage bundle` 的 value owner first slice。Actual route 是 runtime internal integration owner：只消费上游 `NSView` runtime-call readiness，把 `NSView` create / classify / destroy evidence 接入 renderer backend shell candidate facts。

本轮没有新增 native C ABI，没有新增 probe，没有修改 `runtime/cjgui/cjpm.toml`，也没有写 renderer state。`NSView` token 仍只属于上游 runtime-call owner 的局部事实，不进入 module-level mutable state，也不返回 public surface。

## 实际写集

- 新增 [runtime_renderer_backend_nsview_platform_integration.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_backend_nsview_platform_integration.cj)。
- 新增本阶段 preflight、closure、next-boundary、manifest 与 manifest closure。
- 同步 README、tracker、plans README、runtime README、设计意图索引与三个 topic manifest。
- 给上游 `NSView` runtime call、real backend shell、backend readiness shell 与 teardown admission 相关文档补 downstream 指向。

未修改：

- `runtime/cjgui/native/cjgui_native_bridge.h`
- `runtime/cjgui/native/cjgui_native_bridge.m`
- `runtime/cjgui/cjpm.toml`
- `runtime/cjgui/src/runtime_state.cj`
- `labs/macos_bridge_smoke` native files
- public runtime API / diagnostics

## Owner 与 truth

- Owner：`runtime/cjgui/src/runtime_renderer_backend_nsview_platform_integration.cj`
- Endpoint：`CjguiInternalRendererNoBackendNsViewPlatformIntegrationReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererBackendNsViewPlatformIntegrationDraft()`
- Runtime input：`CjguiInternalRendererNoPlatformObjectNsViewRuntimeCallReadiness`

Current truth 只包括：

- `NSView` runtime call evidence accepted。
- backend shell platform candidate intent。
- opaque token locality preserved。
- no renderer-state-write proof。
- no Metal layer binding proof。
- no backend-ready truth proof。
- teardown-before-backend-ready dependency。
- main-thread backend platform admission guard。
- invalid-token / destroyed-token / background-thread / table-unavailable fail-closed classification。
- no public surface。
- no diagnostics publication。
- no receipt / record / publication wrapper。

## GitNexus 影响记录

- `CjguiInternalRendererNoPlatformObjectNsViewRuntimeCallReadiness`：GitNexus impact 返回 not found / `UNKNOWN` / impacted count `0`。
- `cjguiInternalExecuteDefaultRendererPlatformObjectNsViewRuntimeCallDraft`：GitNexus impact 返回 not found / `UNKNOWN` / impacted count `0`。

该结果按近期新增 owner 尚未索引处理。本轮用源码阅读、主包 build、probe 矩阵、public declaration scan、native forbidden scan、protected path scan 与 GitNexus detect changes 兜底。

## 停止线

- 不新增 public API / diagnostics。
- 不写 `runtime_state.cj` 或 renderer state。
- 不新增 native C ABI。
- 不创建 `CAMetalLayer` / `CALayer` / `MTLDevice` / `MTLCommandQueue`。
- 不导入 Metal / QuartzCore。
- 不把 `NSView` token 保存到 module-level mutable state。
- 不返回 token / pointer / handle / `id` / `Class` 到 public surface。
- 不把 integration facts 包装成 backend-ready truth、render permission、GPU submission permission、renderer state write permission、receipt / record / publication。

## 下游入口

唯一 next opening：

`P1 internal Renderer CAMetalLayer attachment planning preflight decision`

该入口只能做 planning preflight，判断 `NSView` platform candidate 与 backend shell facts 是否足够进入 `CAMetalLayer` attachment planning；不得创建 `CALayer` / `CAMetalLayer`，不得导入 QuartzCore / Metal，不得创建 `MTLDevice` / `MTLCommandQueue`，不得写 renderer state，不得发布 backend-ready truth。

## 下游 CAMetalLayer attachment planning 已完成

本 closure 的后续入口已由 [CAMetalLayer attachment planning closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-internal-renderer-cametallayer-attachment-planning-stage-closure-review.md) 与 [manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-cametallayer-attachment-planning-manifest.md) 接续。下游最新 owner 是 [runtime_renderer_cametallayer_attachment_planning.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_cametallayer_attachment_planning.cj)，只固定 no-attach planning facts；不新增 native C ABI，不 import QuartzCore / Metal，不创建或 attach `CAMetalLayer` / `CALayer`，不写 renderer state，不发布 backend-ready truth。

## 设计意图出口自检

- 本轮是否改变主题状态：是，从 `NSView` runtime-call owner 推进到 backend shell integration value owner。
- 本轮是否改变 canonical tail / endpoint：是，最新 endpoint 为 `CjguiInternalRendererNoBackendNsViewPlatformIntegrationReadiness` / `cjguiInternalExecuteDefaultRendererBackendNsViewPlatformIntegrationDraft()`。
- 本轮是否改变 owner / truth / stop-line：是，新增 `runtime_renderer_backend_nsview_platform_integration.cj`；truth 限定为 backend shell integration facts；stop-line 继续禁止 public / state write / layer / Metal / backend-ready。
- 本轮是否改变唯一 next opening：是，转为 `P1 internal Renderer CAMetalLayer attachment planning preflight decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。

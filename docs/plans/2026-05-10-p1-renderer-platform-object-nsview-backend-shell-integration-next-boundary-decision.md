# P1 渲染器 platform object NSView backend shell integration 下一阶段选择

日期：2026-05-10

状态：next-boundary decision / 进入 CAMetalLayer attachment planning 预检

## 本轮选择

选择 A：

`P1 internal Renderer CAMetalLayer attachment planning preflight decision`

选择理由：

- `CjguiInternalRendererNoBackendNsViewPlatformIntegrationReadiness` 已成为当前 backend shell integration tail。
- 新 owner 只消费 `NSView` runtime-call facts，并确认 token locality、no renderer-state-write、no Metal layer binding 与 no backend-ready truth。
- 本阶段未新增 native C ABI，未修改 `runtime/cjgui/cjpm.toml`，未触碰 `runtime_state.cj`。
- `NSView` token 仍未公开，也未进入 module-level mutable runtime state。
- 当前剩余边界自然转向 `CAMetalLayer` attachment planning，但只能先做 planning，不得创建 layer / Metal resource。

## 拒绝路线

- 拒绝直接创建 `CALayer` / `CAMetalLayer`。
- 拒绝直接创建 `MTLDevice` / `MTLCommandQueue`。
- 拒绝导入 Metal / QuartzCore。
- 拒绝 public API / diagnostics。
- 拒绝写 renderer state 或触碰 `runtime_state.cj`。
- 拒绝直接进入 GPU submission、render execution 或 backend-ready truth。

## 下一阶段边界

下一阶段只能检查 `NSView` platform candidate、main-thread gate、token locality、teardown dependency 与 backend shell facts 是否足够进入 `CAMetalLayer` attachment planning。它不得新增 real layer binding，不得返回 pointer / handle，不得把 `NSView` token 解释成 renderer backend ready。

## 下游执行结果

该选择已由 [CAMetalLayer attachment planning preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-cametallayer-attachment-planning-preflight-decision.md)、[closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-internal-renderer-cametallayer-attachment-planning-stage-closure-review.md) 与 [manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-cametallayer-attachment-planning-manifest.md) 接续。下游选择 no-attach value boundary，不新增 native C ABI，不 import QuartzCore / Metal，不创建或 attach layer；新的唯一后续入口为 `P1 internal Renderer CAMetalLayer no-attach class/runtime FFI call owner preflight decision`。

## 设计意图出口自检

- 本轮是否改变主题状态：是，backend shell integration value owner 已封账，下一阶段转入 `CAMetalLayer` attachment planning 预检。
- 本轮是否改变 canonical tail / endpoint：是，当前 tail 为 `CjguiInternalRendererNoBackendNsViewPlatformIntegrationReadiness`。
- 本轮是否改变 owner / truth / stop-line：是，owner 为 `runtime_renderer_backend_nsview_platform_integration.cj`；truth 仅限 integration facts；stop-line 继续禁止 public / state write / layer / Metal / backend-ready。
- 本轮是否改变唯一 next opening：是，固定为 `P1 internal Renderer CAMetalLayer attachment planning preflight decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。

# P1 Renderer 可见窗口 NSApplication Shared-Application Production Singleton Ownership Preflight Decision

状态：preflight decision / docs-only / ownership boundary opened / no implementation

## 决策输入

用户已明确批准开启 production singleton ownership preflight，但范围仅限
docs / preflight / decision 阶段。本轮允许读取并消费现有 isolated accessor probe 与
throwaway creation probe evidence，评估 production singleton ownership 是否可以作为后续
runway 打开，并固定 owner boundary、main-thread confinement、cleanup
responsibility、headless fail-closed 与 no activation / no run-loop / no window /
no render stop-line。

本轮不实现 production singleton owner，不新增 runtime owner 表示 production singleton
ownership truth，不新增 native C ABI，不调用 `NSApplication.sharedApplication`，也不修改
`runtime/cjgui/src/runtime_state.cj` 或 `runtime/cjgui/cjpm.toml`。

## 上游证据

- [throwaway creation manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-throwaway-creation-probe-first-slice-manifest.md)
- [preexisting harness manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-isolated-actual-accessor-call-probe-preexisting-application-harness-manifest.md)
- [isolated actual accessor call first slice manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-isolated-actual-accessor-call-probe-first-slice-manifest.md)
- [production singleton ownership approval reconciliation manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-production-singleton-ownership-preflight-approval-reconciliation-manifest.md)

## 消费的事实

- no-create isolated actual accessor probe 在当前 automation 环境没有 preexisting
  `NSApplication` singleton 时 fail-closed：`accessor_call_attempted=false`、
  `application_created=false`、`classification=-240`、
  `side_effect_classification=fail_closed_preexisting_application_missing`。
- throwaway creation probe 证明 actual accessor 在无 preexisting singleton 时会返回
  nonnull 并创建 throwaway singleton：
  `accessor_call_attempted=true`、`accessor_returned_nonnull=true`、
  `throwaway_application_created=true`、`classification=241`、
  `side_effect_classification=throwaway_singleton_created_by_accessor`。
- preexisting harness decision 证明当前仓库没有可复用的同进程 preexisting
  singleton harness；`labs/macos_bridge_smoke` 不能搬入 production harness，因为它拥有
  creation、activation policy mutation、activation、visible order 与 AppKit run-loop
  行为。
- approval reconciliation 证明上一轮没有 production singleton ownership approval；
  本轮用户只批准 docs / preflight / decision，不批准 implementation。

## Decision

production singleton ownership runway 可以打开，但只能打开为 docs-only ownership
boundary / source-selection preflight。该 runway 的当前结论是：Renderer 不得把
throwaway singleton creation evidence 自动升级为 production singleton ownership；未来若要拥有
production singleton，必须先明确 singleton source、owner boundary、cleanup
responsibility、main-thread confinement 和 headless fail-closed 责任。

本轮不选择 production singleton owner implementation，不新增 runtime truth，也不引入
production actual accessor call site。runtime canonical endpoint 继续保持上游 throwaway
creation evidence endpoint；本轮只新增文档层 decision truth。

## Owner boundary

- production singleton ownership source 必须来自外部 app shell / user-controlled
  preexisting owner，或来自未来被单独批准的 production singleton owner slice。
- Renderer visible-window production harness 不得静默通过 throwaway accessor side effect
  成为 singleton owner。
- production singleton owner 若未来获批，必须与 renderer runtime owner、native bridge
  resource owner、visible-window owner、activation owner 和 teardown owner 分层，不得在同一刀内
  同时引入 window / view / layer / drawable / render ownership。
- cleanup responsibility 必须在 implementation 前固定：谁创建 singleton，谁负责
  shutdown / cleanup policy；本轮不执行 cleanup。

## Main-thread 与 headless policy

- future production ownership preflight 必须保持 main-thread confined。
- headless / CI / no display / no Metal device / no preexisting singleton 环境必须
  fail-closed，不得 fallback 到 hidden creation、activation、event-loop 或 artifact
  publication。
- cleanup, teardown, run-loop, activation, visible order, drawable 与 render 都不得被
  production singleton ownership preflight 隐式打开。

## Truth

- `production_singleton_ownership_preflight_opened=true`
- `production_singleton_ownership_truth=false`
- `production_singleton_owner_boundary_required=true`
- `production_singleton_source_selection_required=true`
- `production_singleton_cleanup_responsibility_required=true`
- `production_singleton_headless_fail_closed_required=true`
- `production_singleton_main_thread_confinement_required=true`
- `production_singleton_implementation_allowed=false`
- `production_actual_accessor_call_site_allowed=false`
- `production_public_c_abi_added=false`
- `public_api_modified=false`
- `runtime_state_write=false`
- `cjpm_toml_change=false`

## Stop-line

不实现 production singleton owner；不新增 runtime owner 表示 production singleton
ownership truth；不新增 native C ABI；不调用 `NSApplication.sharedApplication`；
不调用 `setActivationPolicy` / `activateIgnoringOtherApps` / `run` / `stop` /
`terminate`；不创建 `NSWindow` / `NSView` / `CAMetalLayer`；不 visible order；不
`nextDrawable`；不创建 command queue / command buffer / encoder；不 render / commit /
present / GPU submission；不写 artifact；不发布 diagnostics；不新增 public API /
public C ABI；不修改 `runtime_state.cj` 或 `runtime/cjgui/cjpm.toml`。

## 当前唯一 next opening

`P1 internal Renderer visible-window production harness NSApplication shared-application production singleton ownership source-and-cleanup boundary decision`

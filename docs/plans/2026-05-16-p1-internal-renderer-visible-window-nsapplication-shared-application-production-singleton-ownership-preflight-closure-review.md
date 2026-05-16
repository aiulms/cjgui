# P1 Internal Renderer 可见窗口 NSApplication Shared-Application Production Singleton Ownership Preflight Closure Review

状态：closure review / docs-only / preflight closed / no owner implementation

## Closure 范围

本 closure 关闭 production singleton ownership preflight decision 阶段。范围严格限于
文档、preflight 和 decision；没有实现 production singleton owner，没有新增 runtime
truth owner，没有新增 native C ABI，也没有调用 `NSApplication.sharedApplication`。

## 已完成

- 消费 isolated actual accessor call probe first slice 的 no-create fail-closed evidence。
- 消费 preexisting harness decision，确认当前仓库没有可复用的同进程 preexisting
  `NSApplication` singleton harness。
- 消费 throwaway creation probe evidence，确认 accessor side effect 可创建 throwaway
  singleton，但该 evidence 不是 production singleton ownership truth。
- 消费 approval reconciliation，确认上一轮没有 production singleton ownership approval。
- 记录本轮用户批准：production singleton ownership preflight 已打开，但仅限 docs /
  preflight / decision。
- 固定 owner boundary、main-thread confinement、cleanup responsibility、headless
  fail-closed 与 no activation / no run-loop / no window / no render stop-line。

## Canonical 状态

runtime canonical endpoint 保持不变：

- Canonical endpoint：
  `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationThrowawayCreationProbeEvidenceReadiness`
- Default draft：
  `cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationThrowawayCreationProbeEvidenceDraft()`
- Runtime input：
  `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationIsolatedActualAccessorCallProbeEvidenceReadiness`

本阶段的 docs-only current stage 是 production singleton ownership preflight；它没有新增
runtime endpoint。

## Closure truth

- `production_singleton_ownership_preflight_opened=true`
- `production_singleton_ownership_truth=false`
- `production_singleton_implementation_allowed=false`
- `production_actual_accessor_call_site_allowed=false`
- `production_singleton_source_selection_required=true`
- `production_singleton_cleanup_responsibility_required=true`
- `production_singleton_headless_fail_closed_required=true`
- `production_singleton_main_thread_confinement_required=true`

## 验收

该阶段可以封账，因为它只做 decision / boundary：

- 没有新增 `.cj` runtime owner。
- 没有修改 production native bridge。
- 没有新增 C ABI / FFI / public API。
- 没有调用 actual accessor。
- 没有创建或持有 `NSApplication`。
- 没有打开 activation、activation policy mutation、AppKit event loop、bounded pump、
  visible order、drawable、render、artifact publication 或 diagnostics publication。
- 没有修改 `runtime_state.cj` 或 `runtime/cjgui/cjpm.toml`。

## Remaining risk

当前风险仍在 production singleton source selection 与 cleanup responsibility。后续若把
runway 从 docs-only boundary 推向 implementation，必须先回答：

- singleton 是否由外部 app shell / user-controlled owner 提供。
- 如果 runtime 自建 singleton，谁拥有 teardown / cleanup 责任。
- headless / CI / no-display 环境如何 fail-closed。
- main-thread confinement 如何被 probe / owner 同时证明。

## 当前唯一 next opening

`P1 internal Renderer visible-window production harness NSApplication shared-application production singleton ownership source-and-cleanup boundary decision`

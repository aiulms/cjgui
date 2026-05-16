# P1 Renderer 可见窗口 NSApplication Shared-Application Production Singleton Ownership Source-Cleanup Boundary Next-Boundary Decision

状态：next-boundary decision / external source readiness selected / no implementation

## 上游

- [source-cleanup boundary decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-production-singleton-ownership-source-cleanup-boundary-decision.md)
- [source-cleanup boundary closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-internal-renderer-visible-window-nsapplication-shared-application-production-singleton-ownership-source-cleanup-boundary-closure-review.md)

## Boundary 选择

下一步选择：

`P1 internal Renderer visible-window production harness NSApplication shared-application external preexisting singleton source readiness preflight decision`

该 opening 仍是 preflight / decision / value-only 边界。它只允许定义 Renderer 如何消费
外部 app shell 或 user-controlled owner 提供的 preexisting singleton readiness，以及该 readiness
必须如何保持 main-thread confined、headless fail-closed、cleanup-owned-by-source 和 no
production creation truth。

## 仍不允许的路径

下一步不得直接进入：

- production singleton owner implementation。
- production actual accessor call site。
- native C ABI。
- activation / activation policy mutation。
- AppKit event loop / bounded pump。
- cleanup / teardown execution。
- `NSWindow` / `NSView` / `CAMetalLayer` creation。
- visible order。
- drawable acquisition。
- render / commit / present / GPU submission。
- artifact / diagnostics publication。
- public API / public C ABI。
- `runtime_state.cj` 或 `runtime/cjgui/cjpm.toml` 修改。

## Carry-forward truth

- `throwaway_singleton_rejected_as_production_source=true`
- `external_preexisting_singleton_source_required=true`
- `future_runtime_owner_explicit_approval_required=true`
- `cleanup_responsibility_before_implementation_required=true`
- `cleanup_execution_blocked=true`
- `production_singleton_ownership_truth=false`
- `production_singleton_implementation_allowed=false`

## 当前唯一 next opening

`P1 internal Renderer visible-window production harness NSApplication shared-application external preexisting singleton source readiness preflight decision`

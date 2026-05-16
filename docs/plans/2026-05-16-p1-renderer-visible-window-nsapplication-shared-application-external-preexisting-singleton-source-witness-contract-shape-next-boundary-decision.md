# P1 Renderer 可见窗口 NSApplication Shared-Application External Preexisting Singleton Source Witness Contract Shape Next-Boundary Decision

状态：next-boundary decision / witness admission policy selected / no implementation

## 上游

- [source witness contract shape decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-external-preexisting-singleton-source-witness-contract-shape-decision.md)
- [source witness contract shape closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-internal-renderer-visible-window-nsapplication-shared-application-external-preexisting-singleton-source-witness-contract-shape-closure-review.md)

## Boundary 选择

下一步选择：

`P1 internal Renderer visible-window production harness NSApplication shared-application external preexisting singleton source witness admission policy preflight decision`

该 opening 仍是 preflight / policy / value-only 边界。它只允许定义未来 source witness
admission policy：哪些 witness facts 可以被视为候选输入、哪些缺失必须 fail-closed、
哪些情况必须继续拒绝 production singleton ownership。

## 仍不允许的路径

下一步不得直接进入：

- production singleton owner implementation。
- production actual accessor call site。
- native C ABI。
- activation / activation policy mutation。
- AppKit event loop / bounded pump。
- cleanup / teardown execution。
- window / view / layer creation。
- visible order。
- drawable acquisition。
- render / commit / present / GPU submission。
- artifact / diagnostics publication。
- pointer / handle / `id` / `Class` return。
- public API / public C ABI。
- `runtime_state.cj` 或 `runtime/cjgui/cjpm.toml` 修改。

## Carry-forward truth

- `witness_provided_by_external_owner_required=true`
- `preexisting_singleton_before_renderer_observation_required=true`
- `witness_captured_before_runtime_owner_required=true`
- `main_thread_witness_declaration_required=true`
- `no_renderer_creation_invariant_required=true`
- `no_renderer_accessor_call_invariant_required=true`
- `cleanup_ownership_retained_by_external_source=true`
- `renderer_cleanup_execution_blocked=true`
- `external_preexisting_singleton_source_witness_truth=false`
- `external_preexisting_singleton_source_readiness_truth=false`
- `production_singleton_ownership_truth=false`
- `production_singleton_implementation_allowed=false`

## 当前唯一 next opening

`P1 internal Renderer visible-window production harness NSApplication shared-application external preexisting singleton source witness admission policy preflight decision`

# P1 Renderer 可见窗口 NSApplication Shared-Application External Preexisting Singleton Source Readiness Preflight Next-Boundary Decision

状态：next-boundary decision / witness contract selected / no implementation

## 上游

- [external source readiness preflight decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-external-preexisting-singleton-source-readiness-preflight-decision.md)
- [external source readiness preflight closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-internal-renderer-visible-window-nsapplication-shared-application-external-preexisting-singleton-source-readiness-preflight-closure-review.md)

## Boundary 选择

下一步选择：

`P1 internal Renderer visible-window production harness NSApplication shared-application external preexisting singleton source witness contract shape decision`

该 opening 仍是 preflight / decision / value-only 边界。它只允许定义 source witness
contract 的形状：如何证明外部 owner 已经拥有 preexisting singleton、如何声明 main-thread
confinement、source lifetime、cleanup ownership、headless fail-closed 与 non-creation
invariant。

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
- public API / public C ABI。
- `runtime_state.cj` 或 `runtime/cjgui/cjpm.toml` 修改。

## Carry-forward truth

- `external_owner_provided_preexisting_singleton_required=true`
- `external_source_witness_before_runtime_owner_required=true`
- `throwaway_singleton_rejected_as_external_source=true`
- `renderer_created_singleton_allowed=false`
- `cleanup_owned_by_external_source_required=true`
- `renderer_cleanup_execution_blocked=true`
- `external_preexisting_singleton_source_readiness_truth=false`
- `production_singleton_ownership_truth=false`
- `production_singleton_implementation_allowed=false`

## 当前唯一 next opening

`P1 internal Renderer visible-window production harness NSApplication shared-application external preexisting singleton source witness contract shape decision`

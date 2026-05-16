# P1 Renderer 可见窗口 NSApplication Shared-Application External Preexisting Singleton Source Witness Payload Validation Preflight Next Boundary Decision

状态：next-boundary / acceptance gate preflight only

## Decision

下一段仍不进入 production actual accessor call。当前 payload validation preflight 只定义 dehydrated payload 的字段 presence gate、classification propagation 与 validation result；它还没有定义 validated witness payload 如何进入 acceptance gate。

## 允许的下一步

下一步只能打开：

`P1 internal Renderer visible-window production harness NSApplication shared-application external preexisting singleton source witness acceptance gate preflight decision`

该阶段最多定义 acceptance gate / validated-payload carry-forward / witness truth still-false proof / source readiness still-false proof。

## 禁止项

下一步仍禁止：

- production actual accessor call；
- production singleton owner implementation；
- native C ABI；
- `NSApplication` creation / activation；
- activation policy mutation；
- AppKit event loop / bounded pump；
- cleanup / teardown execution；
- window / view / layer creation；
- visible order；
- drawable；
- command queue / buffer / encoder；
- render / commit / present / GPU submission；
- artifact / diagnostics publication；
- pointer / handle / `id` / `Class` return；
- public API / production C ABI；
- renderer state write / backend-ready truth；
- `runtime_state.cj` write；
- `cjpm.toml` change。

## 进入条件

进入 witness acceptance gate preflight 前，必须继续保护：

- `validation_before_witness_truth_required=true`
- `validation_result_remain_dehydrated_required=true`
- `external_preexisting_singleton_source_witness_truth=false`
- `external_preexisting_singleton_source_readiness_truth=false`
- `production_singleton_ownership_truth=false`
- `production_singleton_implementation_allowed=false`
- `production_actual_accessor_call_site_allowed=false`

## 当前唯一 next opening

`P1 internal Renderer visible-window production harness NSApplication shared-application external preexisting singleton source witness acceptance gate preflight decision`

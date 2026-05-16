# P1 Renderer 可见窗口 NSApplication Shared-Application External Preexisting Singleton Source Witness Acceptance Gate Preflight Next Boundary Decision

状态：next-boundary / witness truth admission preflight only

## Decision

下一段仍不进入 production actual accessor call。当前 acceptance gate preflight 只定义 validated payload carry-forward、pre-truth acceptance gate、fail-closed classification 与 dehydrated acceptance result；它还没有允许 witness truth、external source readiness truth 或 production singleton ownership truth。

## 允许的下一步

下一步只能打开：

`P1 internal Renderer visible-window production harness NSApplication shared-application external preexisting singleton source witness truth admission preflight decision`

该阶段最多定义 witness truth admission preflight / acceptance gate prerequisite / source readiness still-false proof / production ownership still-false proof。

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

进入 witness truth admission preflight 前，必须继续保护：

- `validated_payload_before_acceptance_gate_required=true`
- `payload_validation_readiness_carry_forward_required=true`
- `classification_propagation_to_acceptance_gate_required=true`
- `acceptance_gate_remain_pre_truth_required=true`
- `acceptance_gate_remain_dehydrated_required=true`
- `external_preexisting_singleton_source_witness_truth=false`
- `external_preexisting_singleton_source_readiness_truth=false`
- `production_singleton_ownership_truth=false`
- `production_singleton_implementation_allowed=false`
- `production_actual_accessor_call_site_allowed=false`

## 当前唯一 next opening

`P1 internal Renderer visible-window production harness NSApplication shared-application external preexisting singleton source witness truth admission preflight decision`

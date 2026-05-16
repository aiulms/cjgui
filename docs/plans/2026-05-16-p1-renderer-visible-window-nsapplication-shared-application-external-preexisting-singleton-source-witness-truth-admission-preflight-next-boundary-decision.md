# P1 Renderer 可见窗口 NSApplication Shared-Application External Preexisting Singleton Source Witness Truth Admission Preflight Next Boundary Decision

状态：next-boundary / source readiness admission preflight only

## Decision

下一段仍不进入 production actual accessor call。当前 witness truth admission preflight 只定义 acceptance gate prerequisite、accepted payload carry-forward、pre-truth admission result、source readiness still-false proof 与 production ownership still-false proof；它还没有允许 source readiness truth 或 production singleton ownership truth。

## 允许的下一步

下一步只能打开：

`P1 internal Renderer visible-window production harness NSApplication shared-application external preexisting singleton source readiness admission preflight decision`

该阶段最多定义 source readiness admission preflight / witness truth admission prerequisite / production ownership still-false proof。

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

进入 source readiness admission preflight 前，必须继续保护：

- `acceptance_gate_before_witness_truth_admission_required=true`
- `accepted_payload_readiness_carry_forward_required=true`
- `accepted_payload_remain_dehydrated_required=true`
- `acceptance_classification_carry_forward_required=true`
- `witness_truth_admission_remain_pre_truth_required=true`
- `witness_truth_admission_remain_dehydrated_required=true`
- `source_readiness_admission_deferred=true`
- `external_preexisting_singleton_source_witness_truth=false`
- `external_preexisting_singleton_source_readiness_truth=false`
- `production_singleton_ownership_truth=false`
- `production_singleton_implementation_allowed=false`
- `production_actual_accessor_call_site_allowed=false`

## 当前唯一 next opening

`P1 internal Renderer visible-window production harness NSApplication shared-application external preexisting singleton source readiness admission preflight decision`

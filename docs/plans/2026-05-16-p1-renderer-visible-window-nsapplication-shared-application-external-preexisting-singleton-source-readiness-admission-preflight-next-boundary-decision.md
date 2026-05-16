# P1 Renderer 可见窗口 NSApplication Shared-Application External Preexisting Singleton Source Readiness Admission Preflight Next Boundary Decision

状态：next-boundary / explicit source readiness truth approval only

## Decision

下一段仍不进入 production actual accessor call。当前 source readiness admission preflight 只定义 witness truth admission prerequisite、accepted dehydrated payload carry-forward、source readiness pre-truth result、source readiness still-false proof 与 production ownership still-false proof；它还没有允许 source readiness truth 或 production singleton ownership truth。

## 允许的下一步

下一步只能打开：

`P1 internal Renderer visible-window production harness NSApplication shared-application external preexisting singleton source readiness truth explicit approval decision`

该阶段最多判定是否允许 external preexisting singleton source readiness truth 进入下一条 value-only runway。没有明确批准时，必须保持 truth false / blocked。

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

进入 source readiness truth explicit approval decision 前，必须继续保护：

- `witness_truth_admission_before_source_readiness_admission_required=true`
- `witness_truth_admission_preflight_carry_forward_required=true`
- `witness_truth_admission_remain_pre_truth_carry_forward_required=true`
- `witness_truth_admission_remain_dehydrated_carry_forward_required=true`
- `accepted_payload_readiness_carry_forward_for_source_readiness_required=true`
- `accepted_payload_remain_dehydrated_for_source_readiness_required=true`
- `acceptance_classification_carry_forward_for_source_readiness_required=true`
- `source_readiness_admission_remain_pre_truth_required=true`
- `source_readiness_admission_remain_dehydrated_required=true`
- `production_singleton_ownership_admission_deferred=true`
- `external_preexisting_singleton_source_witness_truth=false`
- `external_preexisting_singleton_source_readiness_truth=false`
- `production_singleton_ownership_truth=false`
- `production_singleton_implementation_allowed=false`
- `production_actual_accessor_call_site_allowed=false`

## 当前唯一 next opening

`P1 internal Renderer visible-window production harness NSApplication shared-application external preexisting singleton source readiness truth explicit approval decision`

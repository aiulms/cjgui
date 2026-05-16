# P1 Renderer 可见窗口 NSApplication Shared-Application External Preexisting Singleton Source Witness Admission Policy Preflight Next Boundary Decision

状态：next-boundary / no-call continuation

## Decision

下一段不进入 production actual accessor call。当前 admission policy preflight 只说明 admission gate 需要哪些证明；它还没有定义可被 admission gate 消费的 external witness payload schema。

## 允许的下一步

下一步只能打开：

`P1 internal Renderer visible-window production harness NSApplication shared-application external preexisting singleton source witness payload schema preflight decision`

该阶段最多定义 payload schema / required fields / fail-closed classification / dehydration rules。

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
- public API / production C ABI；
- renderer state write / backend-ready truth；
- `runtime_state.cj` write；
- `cjpm.toml` change。

## 进入条件

进入 payload schema preflight 前，必须继续保护：

- `external_preexisting_singleton_source_witness_truth=false`
- `external_preexisting_singleton_source_readiness_truth=false`
- `production_singleton_ownership_truth=false`
- `production_singleton_implementation_allowed=false`
- `production_actual_accessor_call_site_allowed=false`

## 当前唯一 next opening

`P1 internal Renderer visible-window production harness NSApplication shared-application external preexisting singleton source witness payload schema preflight decision`

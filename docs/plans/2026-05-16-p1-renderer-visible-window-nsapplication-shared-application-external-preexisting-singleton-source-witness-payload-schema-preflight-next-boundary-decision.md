# P1 Renderer 可见窗口 NSApplication Shared-Application External Preexisting Singleton Source Witness Payload Schema Preflight Next Boundary Decision

状态：next-boundary / validation preflight only

## Decision

下一段不进入 production actual accessor call。当前 payload schema preflight 只定义 future witness payload 的必填字段、fail-closed classification 与 dehydration rules；它还没有定义 payload validation gate。

## 允许的下一步

下一步只能打开：

`P1 internal Renderer visible-window production harness NSApplication shared-application external preexisting singleton source witness payload validation preflight decision`

该阶段最多定义 validation gate / field presence checks / classification propagation / dehydrated validation result。

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

进入 payload validation preflight 前，必须继续保护：

- `payload_remain_dehydrated_required=true`
- `external_preexisting_singleton_source_witness_truth=false`
- `external_preexisting_singleton_source_readiness_truth=false`
- `production_singleton_ownership_truth=false`
- `production_singleton_implementation_allowed=false`
- `production_actual_accessor_call_site_allowed=false`

## 当前唯一 next opening

`P1 internal Renderer visible-window production harness NSApplication shared-application external preexisting singleton source witness payload validation preflight decision`

# P1 Renderer 可见窗口 NSApplication Shared-Application External Preexisting Singleton Source Witness Payload Schema Preflight Decision

状态：decision / preflight / no-call continuation

## Decision

本阶段继续 no-call audit branch，不进入 production actual accessor call。

上游 admission policy preflight 已确认 witness admission 前必须具备 external owner identity、preexisting singleton observation、main-thread proof、source lifetime proof、external cleanup ownership、witness fields complete、headless fail-closed 与 no Renderer creation / accessor call invariant。本阶段只把这些 admission prerequisites 固定为 future witness payload schema。

## 本阶段允许内容

- 定义 payload schema preflight owner；
- 固定 `payload_version`、external owner identity、preexisting singleton observed、main-thread observation、source lifetime、cleanup ownership、no Renderer accessor invariant、no Renderer creation invariant 与 headless fail-closed classification 字段；
- 固定 missing field、ambiguous owner、wrong thread、Renderer-created singleton 与 throwaway singleton 的 fail-closed classification；
- 保持 payload dehydrated，不携带 native object、pointer、handle、`Class`、`id`、artifact 或 diagnostics；
- 保持 `external_preexisting_singleton_source_witness_truth=false`、`external_preexisting_singleton_source_readiness_truth=false`、`production_singleton_ownership_truth=false`、`production_singleton_implementation_allowed=false` 与 `production_actual_accessor_call_site_allowed=false`。

## 禁止项

本阶段仍禁止：

- production singleton owner implementation；
- production actual accessor call site；
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

## Owner

本阶段 owner：

- [runtime_renderer_visible_window_nsapplication_shared_application_external_preexisting_singleton_source_witness_payload_schema_preflight.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_external_preexisting_singleton_source_witness_payload_schema_preflight.cj)

Owner probe：

- [verify_renderer_visible_window_nsapplication_shared_application_external_preexisting_singleton_source_witness_payload_schema_preflight_owner.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_external_preexisting_singleton_source_witness_payload_schema_preflight_owner.sh)

## Canonical Endpoint

- canonical endpoint：`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessPayloadSchemaPreflightReadiness`
- default draft：`cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessPayloadSchemaPreflightDraft()`
- runtime input：`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessAdmissionPolicyPreflightReadiness`

## Same-Shape Boundary Brake

不得把 payload schema preflight 包装成 application-ready、accessor-ready、singleton-owner-ready、visible-ready、drawable-ready、render-ready、backend-ready、renderer state write、receipt、record 或 publication wrapper。

# P1 Renderer 可见窗口 NSApplication Shared-Application External Preexisting Singleton Source Witness Payload Validation Preflight Decision

状态：decision / validation preflight / no-call continuation

## Decision

本阶段继续 no-call audit branch，不进入 production actual accessor call。

上游 payload schema preflight 已固定 future witness payload 的版本、external owner identity、preexisting singleton observed、main-thread observation、source lifetime、cleanup ownership、no Renderer accessor / creation invariant 与 headless fail-closed classification 字段。本阶段只把这些 schema 字段转成 validation gate：字段 presence checks、classification propagation 与 dehydrated validation result。

## 本阶段允许内容

- 定义 payload validation preflight owner；
- 固定 validation-before-witness-truth gate；
- 固定 payload version、external owner identity、preexisting singleton observed、main-thread observation、source lifetime 与 cleanup ownership 的 presence checks；
- 固定 no Renderer accessor invariant 与 no Renderer creation invariant validation；
- 固定 missing payload version、missing external owner identity、missing preexisting singleton observation、missing main-thread observation、missing source lifetime、missing cleanup ownership 与 invariant mismatch 的 fail-closed classification；
- 固定 classification propagation；
- 保持 validation result dehydrated，不携带 native object、pointer、handle、`Class`、`id`、artifact 或 diagnostics；
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

- [runtime_renderer_visible_window_nsapplication_shared_application_external_preexisting_singleton_source_witness_payload_validation_preflight.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_external_preexisting_singleton_source_witness_payload_validation_preflight.cj)

Owner probe：

- [verify_renderer_visible_window_nsapplication_shared_application_external_preexisting_singleton_source_witness_payload_validation_preflight_owner.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_external_preexisting_singleton_source_witness_payload_validation_preflight_owner.sh)

## Canonical Endpoint

- canonical endpoint：`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessPayloadValidationPreflightReadiness`
- default draft：`cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessPayloadValidationPreflightDraft()`
- runtime input：`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessPayloadSchemaPreflightReadiness`

## Same-Shape Boundary Brake

不得把 payload validation preflight 包装成 witness truth、source readiness truth、production singleton owner truth、application-ready、accessor-ready、singleton-owner-ready、visible-ready、drawable-ready、render-ready、backend-ready、renderer state write、receipt、record 或 publication wrapper。

# P1 Renderer 可见窗口 NSApplication Shared-Application External Preexisting Singleton Source Witness Acceptance Gate Preflight Decision

状态：decision / acceptance gate preflight / no-call continuation

## Decision

本阶段继续 no-call audit branch，不进入 production actual accessor call。

上游 payload validation preflight 已固定 validated dehydrated payload 的字段 presence checks、classification propagation 与 validation result。本阶段只定义 acceptance gate preflight：validated payload carry-forward、validation readiness carry-forward、acceptance gate pre-truth、fail-closed acceptance classification，以及 witness truth / source readiness 仍保持 false 的证明。

## 本阶段允许内容

- 定义 witness acceptance gate preflight owner；
- 固定 validated payload before acceptance gate；
- 固定 payload validation readiness carry-forward；
- 固定 validated payload version、external owner identity、preexisting singleton observation、main-thread observation、source lifetime 与 cleanup ownership carry-forward；
- 固定 no Renderer accessor invariant 与 no Renderer creation invariant carry-forward；
- 固定 classification propagation to acceptance gate；
- 固定 acceptance gate remain pre-truth；
- 固定 acceptance gate result remain dehydrated，不携带 native object、pointer、handle、`Class`、`id`、artifact 或 diagnostics；
- 固定 validation missing、validation blocked 与 invariant mismatch 的 fail-closed acceptance gate；
- 固定 headless acceptance failure 仍为 non-user-visible；
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

- [runtime_renderer_visible_window_nsapplication_shared_application_external_preexisting_singleton_source_witness_acceptance_gate_preflight.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_external_preexisting_singleton_source_witness_acceptance_gate_preflight.cj)

Owner probe：

- [verify_renderer_visible_window_nsapplication_shared_application_external_preexisting_singleton_source_witness_acceptance_gate_preflight_owner.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_external_preexisting_singleton_source_witness_acceptance_gate_preflight_owner.sh)

## Canonical Endpoint

- canonical endpoint：`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessAcceptanceGatePreflightReadiness`
- default draft：`cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessAcceptanceGatePreflightDraft()`
- runtime input：`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessPayloadValidationPreflightReadiness`

## Same-Shape Boundary Brake

不得把 acceptance gate preflight 包装成 witness truth、source readiness truth、production singleton owner truth、application-ready、accessor-ready、singleton-owner-ready、visible-ready、drawable-ready、render-ready、backend-ready、renderer state write、receipt、record 或 publication wrapper。

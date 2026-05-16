# P1 Renderer 可见窗口 NSApplication Shared-Application External Preexisting Singleton Source Witness Truth Admission Preflight Decision

状态：decision / no-call audit branch / witness truth admission preflight

## Decision

本阶段继续 no-call audit branch，不进入 production actual accessor call，也不打开 actual-call first slice。

witness truth admission preflight 只消费上一段 [witness acceptance gate preflight manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-external-preexisting-singleton-source-witness-acceptance-gate-preflight-manifest.md)，把 accepted dehydrated payload、acceptance gate prerequisite、classification carry-forward 与 pre-truth admission result 固定下来。它不是 witness truth 本身，也不是 source readiness truth，更不是 production singleton owner implementation。

## Branch Rule

本阶段只允许添加内部 value-only owner、owner probe 与文档闭环：

- acceptance gate 必须先于 witness truth admission；
- accepted payload readiness 必须 carry forward；
- accepted payload 必须保持 dehydrated；
- accepted payload version、external owner identity、preexisting singleton observation、main-thread observation、source lifetime、cleanup ownership、no Renderer accessor invariant 与 no Renderer creation invariant 必须 carry forward；
- acceptance classification 必须 carry forward；
- witness truth admission 必须保持 pre-truth 和 dehydrated；
- acceptance missing、acceptance blocked、payload ambiguous 与 headless 场景必须 fail closed；
- source readiness admission 必须 deferred；
- witness truth、external source readiness truth、production singleton ownership truth、production implementation 与 production actual accessor call site 继续保持 false / blocked。

## 禁止项

本阶段仍禁止：

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

## Owner / Probe

- Owner：
  [runtime_renderer_visible_window_nsapplication_shared_application_external_preexisting_singleton_source_witness_truth_admission_preflight.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_external_preexisting_singleton_source_witness_truth_admission_preflight.cj)
- Owner probe：
  [verify_renderer_visible_window_nsapplication_shared_application_external_preexisting_singleton_source_witness_truth_admission_preflight_owner.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_external_preexisting_singleton_source_witness_truth_admission_preflight_owner.sh)

## Canonical 状态

- Canonical endpoint：
  `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessTruthAdmissionPreflightReadiness`
- Default draft：
  `cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessTruthAdmissionPreflightDraft()`
- Runtime input：
  `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessAcceptanceGatePreflightReadiness`

## 当前唯一 next opening

`P1 internal Renderer visible-window production harness NSApplication shared-application external preexisting singleton source readiness admission preflight decision`

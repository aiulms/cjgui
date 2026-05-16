# P1 Renderer 可见窗口 NSApplication Shared-Application External Preexisting Singleton Source Readiness Admission Preflight Decision

状态：decision / no-call audit branch / source readiness admission preflight

## Decision

本阶段继续 no-call audit branch，不进入 production actual accessor call，也不打开 production singleton owner implementation。

source readiness admission preflight 只消费上一段 [witness truth admission preflight manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-external-preexisting-singleton-source-witness-truth-admission-preflight-manifest.md)，把 witness truth admission prerequisite、accepted dehydrated payload carry-forward、source readiness pre-truth admission result 与 production ownership still-false proof 固定下来。它不是 source readiness truth，也不是 production singleton ownership truth。

## Branch Rule

本阶段只允许添加内部 value-only owner、owner probe 与文档闭环：

- witness truth admission 必须先于 source readiness admission；
- witness truth admission preflight 必须 carry forward；
- witness truth admission 必须继续保持 pre-truth 和 dehydrated；
- accepted payload readiness、dehydrated payload、external owner identity、preexisting singleton observation、main-thread observation、source lifetime、cleanup ownership、no Renderer accessor invariant 与 no Renderer creation invariant 必须为 source readiness carry forward；
- acceptance classification 必须 carry forward；
- source readiness admission 必须保持 pre-truth 和 dehydrated；
- witness truth missing、witness truth blocked、payload ambiguous 与 headless 场景必须 fail closed；
- production singleton ownership admission 必须 deferred；
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
  [runtime_renderer_visible_window_nsapplication_shared_application_external_preexisting_singleton_source_readiness_admission_preflight.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_external_preexisting_singleton_source_readiness_admission_preflight.cj)
- Owner probe：
  [verify_renderer_visible_window_nsapplication_shared_application_external_preexisting_singleton_source_readiness_admission_preflight_owner.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_external_preexisting_singleton_source_readiness_admission_preflight_owner.sh)

## Canonical 状态

- Canonical endpoint：
  `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceReadinessAdmissionPreflightReadiness`
- Default draft：
  `cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceReadinessAdmissionPreflightDraft()`
- Runtime input：
  `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessTruthAdmissionPreflightReadiness`

## 当前唯一 next opening

`P1 internal Renderer visible-window production harness NSApplication shared-application external preexisting singleton source readiness truth explicit approval decision`

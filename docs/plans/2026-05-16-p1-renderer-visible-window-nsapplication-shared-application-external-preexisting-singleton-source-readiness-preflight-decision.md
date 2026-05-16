# P1 Renderer 可见窗口 NSApplication Shared-Application External Preexisting Singleton Source Readiness Preflight Decision

状态：preflight decision / value-only owner / no implementation

## 上游

- [source-cleanup boundary manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-production-singleton-ownership-source-cleanup-boundary-manifest.md)
- [throwaway creation manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-throwaway-creation-probe-first-slice-manifest.md)
- [preexisting harness manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-isolated-actual-accessor-call-probe-preexisting-application-harness-manifest.md)

## Decision

选择打开 external preexisting singleton source readiness preflight，但只作为
value-only readiness preflight。该阶段不创建 production singleton owner，不新增 native C ABI，
不调用 application singleton accessor，也不把 throwaway creation evidence 升级为 production
source。

当前决策：

- external source 必须由外部 app shell / user-controlled owner 提供。
- Renderer 不能创建 singleton，也不能把 isolated probe 造成的 throwaway singleton 当成
  production source。
- runtime owner 之前必须先有 source witness contract。
- source lifetime 必须覆盖 Renderer observation lifetime。
- cleanup responsibility 必须归外部 source owner；Renderer cleanup execution 仍 blocked。
- main-thread confinement 与 headless fail-closed 必须继续保留。
- 当前 external preexisting singleton source readiness truth 仍为 false。

## Owner / Probe

- Owner：
  [runtime_renderer_visible_window_nsapplication_shared_application_external_preexisting_singleton_source_readiness_preflight.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_external_preexisting_singleton_source_readiness_preflight.cj)
- Owner probe：
  [verify_renderer_visible_window_nsapplication_shared_application_external_preexisting_singleton_source_readiness_preflight_owner.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_external_preexisting_singleton_source_readiness_preflight_owner.sh)

## Canonical 状态

- Canonical endpoint：
  `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceReadinessPreflightReadiness`
- Default draft：
  `cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceReadinessPreflightDraft()`
- Runtime input：
  `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationProductionSingletonOwnershipSourceCleanupBoundaryReadiness`

## Stop-line

本阶段不授权：

- production singleton owner implementation。
- production actual accessor call site。
- native C ABI。
- `NSApplication` creation / activation。
- activation policy mutation。
- actual AppKit event loop / bounded run-loop pump。
- cleanup / teardown execution。
- `NSWindow` / `NSView` / `CAMetalLayer` creation。
- visible order。
- drawable acquisition。
- render / commit / present / GPU submission。
- artifact write / publication / public diagnostics。
- public API / production public C ABI。
- `runtime/cjgui/src/runtime_state.cj` 或 `runtime/cjgui/cjpm.toml` 修改。

## 当前唯一 next opening

`P1 internal Renderer visible-window production harness NSApplication shared-application external preexisting singleton source witness contract shape decision`

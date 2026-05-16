# P1 Renderer 可见窗口 NSApplication Shared-Application External Preexisting Singleton Source Witness Contract Shape Decision

状态：decision / value-only owner / no implementation

## 上游

- [external source readiness preflight manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-external-preexisting-singleton-source-readiness-preflight-manifest.md)
- [source-cleanup boundary manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-production-singleton-ownership-source-cleanup-boundary-manifest.md)
- [throwaway creation manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-throwaway-creation-probe-first-slice-manifest.md)

## Decision

选择打开 external preexisting singleton source witness contract shape，但只作为
value-only contract shape owner。该阶段定义未来 source witness 必须声明的事实，不接收
真实 `NSApplication` pointer / handle / `id` / `Class`，不调用 application singleton
accessor，也不把 witness shape 升级成 production singleton ownership truth。

当前 contract shape 固定：

- witness 必须由外部 app shell / user-controlled owner 提供。
- witness 必须证明 singleton 在 Renderer observation 之前已经存在。
- witness 必须先于 runtime singleton owner 被捕获。
- witness 必须声明 main-thread confinement。
- witness 必须声明 Renderer 未创建 singleton、未调用 accessor。
- source lifetime 必须覆盖 Renderer observation lifetime。
- cleanup ownership 必须保留在 external source owner，Renderer cleanup execution 仍 blocked。
- headless / CI-like 环境必须 fail-closed。
- throwaway singleton 与 `labs/macos_bridge_smoke` 不能作为 production witness。

## Owner / Probe

- Owner：
  [runtime_renderer_visible_window_nsapplication_shared_application_external_preexisting_singleton_source_witness_contract_shape.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_external_preexisting_singleton_source_witness_contract_shape.cj)
- Owner probe：
  [verify_renderer_visible_window_nsapplication_shared_application_external_preexisting_singleton_source_witness_contract_shape_owner.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_external_preexisting_singleton_source_witness_contract_shape_owner.sh)

## Canonical 状态

- Canonical endpoint：
  `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessContractShapeReadiness`
- Default draft：
  `cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessContractShapeDraft()`
- Runtime input：
  `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceReadinessPreflightReadiness`

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
- pointer / handle / `id` / `Class` return。
- public API / production public C ABI。
- `runtime/cjgui/src/runtime_state.cj` 或 `runtime/cjgui/cjpm.toml` 修改。

## 当前唯一 next opening

`P1 internal Renderer visible-window production harness NSApplication shared-application external preexisting singleton source witness admission policy preflight decision`

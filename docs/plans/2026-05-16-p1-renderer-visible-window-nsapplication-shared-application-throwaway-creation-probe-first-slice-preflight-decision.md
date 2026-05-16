# P1 Renderer 可见窗口 NSApplication Shared-Application Throwaway Creation Probe First Slice 预检决策

状态：preflight decision / approved narrow isolated native probe slice

## 决策

选择 A：打开极窄 throwaway creation probe first slice。

本阶段允许仅在 isolated native probe 中调用 `NSApplication.sharedApplication`，
并允许该 accessor 在没有 preexisting singleton 时触发 throwaway singleton
creation。该结果只作为 throwaway creation evidence，不是 production singleton
ownership truth。

## 进入依据

- 用户已明确批准 throwaway creation probe first slice。
- 上一段 preexisting harness decision 已确认当前 workspace 没有可复用的同进程
  preexisting `NSApplication` singleton harness。
- 上一段 no-create probe 已证明 fail-closed path 生效：
  `preexisting_application_present=false`、`accessor_call_attempted=false`、
  `application_created=false`、`classification=-240`。
- 本 slice 只观察 accessor return、singleton existence、main-thread confinement 与
  side-effect classification。

## 允许范围

- 仅新增 internal owner：
  [runtime_renderer_visible_window_nsapplication_shared_application_throwaway_creation_probe_evidence.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_throwaway_creation_probe_evidence.cj)。
- 仅新增 isolated native probe：
  [verify_native_bridge_nsapplication_shared_application_throwaway_creation_probe.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_native_bridge_nsapplication_shared_application_throwaway_creation_probe.sh)。
- 仅返回 integer classification 与 dehydrated facts。
- 必须 fail-closed。
- 必须记录 `throwaway_creation_evidence=true` 与
  `production_singleton_ownership_truth=false`。

## 禁止范围

- 不调用 `setActivationPolicy`。
- 不调用 `activateIgnoringOtherApps`。
- 不调用 `run` / `stop` / `terminate`。
- 不创建 `NSWindow` / `NSView` / `CAMetalLayer`。
- 不 visible order。
- 不 `nextDrawable`。
- 不创建 command queue / command buffer / encoder。
- 不 render / commit / present / GPU submission。
- 不写 artifact / diagnostics publication。
- 不新增 public API。
- 不新增 production public C ABI。
- 不修改 `runtime/cjgui/src/runtime_state.cj`。
- 不修改 `runtime/cjgui/cjpm.toml`。

## Canonical 目标

- 新 endpoint：
  `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationThrowawayCreationProbeEvidenceReadiness`
- 新 default draft：
  `cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationThrowawayCreationProbeEvidenceDraft()`
- Runtime input：
  `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationIsolatedActualAccessorCallProbeEvidenceReadiness`

## Same-shape Boundary Brake

本决策不是 application-ready、accessor-ready、visible-ready、drawable-ready、
render-ready、backend-ready、renderer state write、receipt、record 或 publication
wrapper。

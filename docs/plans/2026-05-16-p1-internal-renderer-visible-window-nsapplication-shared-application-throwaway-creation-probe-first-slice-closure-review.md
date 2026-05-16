# P1 Renderer 可见窗口 NSApplication Shared-Application Throwaway Creation Probe First Slice Closure Review

状态：closure review / implementation + probe landed / production ownership still blocked

## 完成内容

- 新增 internal throwaway creation evidence owner：
  [runtime_renderer_visible_window_nsapplication_shared_application_throwaway_creation_probe_evidence.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_throwaway_creation_probe_evidence.cj)。
- 新增 owner probe：
  [verify_renderer_visible_window_nsapplication_shared_application_throwaway_creation_probe_evidence_owner.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_throwaway_creation_probe_evidence_owner.sh)。
- 新增 isolated native probe：
  [verify_native_bridge_nsapplication_shared_application_throwaway_creation_probe.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_native_bridge_nsapplication_shared_application_throwaway_creation_probe.sh)。
- 完成 TDD RED：owner probe 首次运行失败于缺少 throwaway evidence owner。
- 完成 GREEN：owner probe、native probe 与 `cjpm build` 均通过。

## Observed Facts

本轮 isolated native probe 输出：

- `main_thread_confined=true`
- `preexisting_application_present=false`
- `accessor_call_attempted=true`
- `accessor_returned_nonnull=true`
- `singleton_exists_after=true`
- `throwaway_application_created=true`
- `classification=241`
- `side_effect_classification=throwaway_singleton_created_by_accessor`
- `throwaway_creation_evidence=true`
- `production_singleton_ownership_truth=false`
- `integer_classification_only=true`
- `dehydrated_facts_only=true`

## Canonical 状态

- Canonical endpoint：
  `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationThrowawayCreationProbeEvidenceReadiness`
- Default draft：
  `cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationThrowawayCreationProbeEvidenceDraft()`
- Runtime input：
  `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationIsolatedActualAccessorCallProbeEvidenceReadiness`

## Closure 判断

本阶段只证明 isolated native probe 中的 accessor 可在无 preexisting singleton 时
创建 throwaway singleton，并可用 integer classification / dehydrated facts 记录。

本阶段不证明：

- production runtime 可以拥有该 singleton。
- production runtime 可以复用该 singleton。
- production runtime 可以新增 application ownership truth。
- production runtime 可以 activation、run loop、visible order、drawable 或 render。

## Stop-line

Stop-line 保持：不调用 `setActivationPolicy`，不调用
`activateIgnoringOtherApps`，不调用 `run` / `stop` / `terminate`，不创建
`NSWindow` / `NSView` / `CAMetalLayer`，不 visible order，不 `nextDrawable`，
不创建 command queue / command buffer / encoder，不 render / commit / present /
GPU submission，不写 artifact / diagnostics publication，不新增 public API，不新增
production public C ABI，不修改 `runtime_state.cj` 或 `cjpm.toml`。

## Same-shape Boundary Brake

Throwaway creation evidence 不是 application-ready、accessor-ready、visible-ready、
drawable-ready、render-ready、backend-ready、renderer state write、receipt、record
或 publication wrapper。

# P1 Renderer 可见窗口 NSApplication Shared-Application Preexisting Harness Manifest

状态：manifest / docs-only / no-create blocker recorded

## 阶段定位

本 manifest 记录 isolated actual accessor call probe first slice 之后的
preexisting-application harness decision。它不引入新的 runtime owner 或 native
probe，只把当前真实 blocker 固定为：没有可复用的同进程 preexisting
`NSApplication` singleton harness。

## 上游

- [first slice manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-isolated-actual-accessor-call-probe-first-slice-manifest.md)
- [first slice closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-internal-renderer-visible-window-nsapplication-shared-application-isolated-actual-accessor-call-probe-first-slice-closure-review.md)
- [first slice next-boundary](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-isolated-actual-accessor-call-probe-first-slice-next-boundary-decision.md)

## 本阶段文档

- [preexisting harness decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-isolated-actual-accessor-call-probe-preexisting-application-harness-decision.md)
- [preexisting harness closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-internal-renderer-visible-window-nsapplication-shared-application-isolated-actual-accessor-call-probe-preexisting-application-harness-closure-review.md)
- [preexisting harness next-boundary](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-isolated-actual-accessor-call-probe-preexisting-application-harness-next-boundary-decision.md)

## Canonical 状态

- Canonical endpoint：
  `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationIsolatedActualAccessorCallProbeEvidenceReadiness`
- Default draft：
  `cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationIsolatedActualAccessorCallProbeEvidenceDraft()`
- Runtime input：
  `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationActualAccessorCallPreflightGuardReadiness`
- Owner file：
  [runtime_renderer_visible_window_nsapplication_shared_application_isolated_actual_accessor_call_probe_evidence.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_isolated_actual_accessor_call_probe_evidence.cj)
- Isolated native probe：
  [verify_native_bridge_nsapplication_shared_application_isolated_actual_accessor_call_probe.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_native_bridge_nsapplication_shared_application_isolated_actual_accessor_call_probe.sh)

## Truth

- Current automation environment has no preexisting `NSApplication` singleton.
- `accessor_call_attempted=false` remains the current observed value.
- `application_created=false` remains the current observed value.
- `classification=-240` remains fail-closed preexisting singleton missing evidence.
- `labs/macos_bridge_smoke` is not a reusable no-create harness because it owns
  creation / activation / run loop behavior.
- No production runtime or native bridge surface was opened in this stage.

## Stop-line

不授权 `NSApplication` creation / activation、activation policy mutation、actual
AppKit event loop、bounded pump、native visible order、production drawable、color
attachment、render command encoder、draw、commit、present、GPU submission、render、
renderer state write、backend-ready truth、artifact publication、public diagnostics、
public API、production public C ABI、pointer / handle / `id` / `Class` return、
`runtime_state.cj` write 或 `cjpm.toml` change。

## 当前唯一 next opening

`P1 internal Renderer visible-window production harness NSApplication shared-application isolated actual accessor call probe external preexisting singleton harness or throwaway creation approval decision`

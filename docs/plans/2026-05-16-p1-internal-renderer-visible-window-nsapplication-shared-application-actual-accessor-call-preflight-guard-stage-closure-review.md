# P1 Renderer 可见窗口 NSApplication Shared-Application Actual Accessor Call Preflight Guard 阶段 Closure 复核

状态：closure review / implementation / no actual accessor call

## Closure 范围

本 closure 复核 [actual accessor call preflight guard preflight decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-actual-accessor-call-preflight-guard-preflight-decision.md) 批准的 internal no-call preflight guard value owner 是否按边界落地。

## 本阶段新增

- Runtime owner：[runtime_renderer_visible_window_nsapplication_shared_application_actual_accessor_call_preflight_guard.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_actual_accessor_call_preflight_guard.cj)
- Owner probe：[verify_renderer_visible_window_nsapplication_shared_application_actual_accessor_call_preflight_guard_owner.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_actual_accessor_call_preflight_guard_owner.sh)

Canonical endpoint：

- `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationActualAccessorCallPreflightGuardReadiness`
- `cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationActualAccessorCallPreflightGuardDraft()`

Runtime input：

- `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationActualAccessorSideEffectAuditReadiness`

## Closure 复核

- Owner 只消费 actual accessor side-effect audit readiness。
- Owner 固定 actual-call first slice explicit approval missing、main-thread confined preflight required、isolated / probe-first route required、no activation policy mutation、no application activation、no AppKit event loop、no bounded pump、no visible order、no drawable、no render、no artifact publication、no public API、no `runtime_state.cj` write 与 no `cjpm.toml` change facts。
- Owner 继续固定 actual application singleton accessor call blocked、no singleton accessor call、application singleton creation blocked、actual teardown execution blocked、artifact write blocked、public diagnostics blocked、no pointer / handle / `Class` / `id` return、no public C ABI、no renderer state write 与 no backend-ready truth。
- Owner 未新增 `foreign func`、public declaration、native C ABI、public diagnostics 或 renderer state write。
- Owner 未修改 [runtime_state.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_state.cj) 或 [cjpm.toml](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/cjpm.toml)。

## TDD 记录

- RED：新增 owner probe 后运行 `zsh runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_actual_accessor_call_preflight_guard_owner.sh`，因 owner file missing 失败，exit 3。
- GREEN：新增 owner 后同一 probe 通过，确认 owner symbols、上游 input 与 stop-line。

## 初步验证

- Owner probe 已通过。
- Build 与 smoke 归入本轮最终 closure verification。

## GitNexus 结果

GitNexus 对 actual accessor side-effect audit endpoint / draft 与 actual accessor call preflight guard endpoint 均返回 target not found / UNKNOWN / 0 impacted。该结果只说明近期新增符号未被索引覆盖，不能作为安全证明；本阶段用 source reading、RED/GREEN owner probe、build 与后续 closure scans 兜底。

## Closure 结论

Actual accessor call preflight guard value owner 可以封账。下一步进入 stop-line reconciliation，确认该 owner 不被误读为 actual application singleton accessor call permission。

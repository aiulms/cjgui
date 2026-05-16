# P1 internal Renderer visible-window NSApplication shared-application 预授权 actual accessor first slice closure review

日期：2026-05-16

状态：closure / internal-only owner landed / value-only first slice

## 封账结论

本阶段已按当前自动化预授权继续推进，并新增 internal-only owner `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationPreauthorizedActualAccessorFirstSliceReadiness`。该 owner 只消费 post-witness-packet actual-call preflight 与 throwaway creation probe evidence，固定“预授权已覆盖上一轮 explicit approval blocker”这一事实，同时保持 actual accessor call 只在 isolated native probe 中出现。

## 当前 truth

- `didConsumeAutomationPreauthorizationForActualAccessorFirstSlice=true`
- `didResolvePreviousExplicitApprovalBlockerInsidePreauthorizedRunway=true`
- `didKeepActualAccessorCallInIsolatedNativeProbeOnly=true`
- `didConfirmThrowawayCreationEvidenceObserved=true`
- `didRejectThrowawayCreationAsProductionOwnershipTruth=true`
- `didConfirmNoProductionActualAccessorCallSite=true`
- `didConfirmNoProductionSingletonOwnerImplementation=true`
- `didKeepPreauthorizedActualAccessorFirstSliceValueOnly=true`

## 仍然没有批准

本阶段没有批准 production singleton owner implementation、production actual accessor call site、source readiness truth、production ownership truth、`NSApplication` activation、activation policy mutation、event loop / bounded pump、cleanup / teardown execution、visible order、drawable、render command encoder、draw / commit / present、GPU submission、renderer state write、public API、production C ABI、`runtime_state.cj` write 或 `cjpm.toml` mutation。

## 关联文件

- Owner：[runtime_renderer_visible_window_nsapplication_shared_application_preauthorized_actual_accessor_first_slice.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_preauthorized_actual_accessor_first_slice.cj)
- Owner probe：[verify_renderer_visible_window_nsapplication_shared_application_preauthorized_actual_accessor_first_slice_owner.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_preauthorized_actual_accessor_first_slice_owner.sh)
- Decision：[preauthorized actual accessor first slice decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-preauthorized-actual-accessor-first-slice-decision.md)

## 下一步

当前唯一 next opening 是 `P1 internal Renderer visible-window production harness NSApplication shared-application external preexisting singleton source readiness truth value boundary / internal readiness owner decision`。下一步只能继续 internal readiness / value boundary；不能把 isolated accessor 或 throwaway creation 证据直接升级为 production truth。


# P1 Renderer visible-window NSApplication shared-application 预授权 actual accessor first slice decision

日期：2026-05-16

状态：decision / internal-only first slice / preauthorized automation runway

## 结论

本轮选择 A：在用户本次自动化窗口给出的 visible-window / `NSApplication` runway 预授权范围内，继续推进 `actual accessor call first slice` 的 internal-only value owner。上一轮 explicit human approval blocker 已由本轮用户消息覆盖；但本阶段仍不新增 production actual accessor call site，不新增 native C ABI，不创建或激活 `NSApplication`，也不把 throwaway singleton creation evidence 升级成 production ownership truth。

本阶段 canonical endpoint 转为 `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationPreauthorizedActualAccessorFirstSliceReadiness` / `cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationPreauthorizedActualAccessorFirstSliceDraft()`。

## 上游输入

- `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationPostWitnessPacketActualAccessorCallPreflightReadiness`
- `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationThrowawayCreationProbeEvidenceReadiness`

其中 isolated actual accessor call 仍只存在于 probe 证据链内；throwaway creation probe 只证明 accessor 在 throwaway 上下文中可能创建 singleton，不能证明 production singleton ownership。

## 写集

- 新增 internal owner：[runtime_renderer_visible_window_nsapplication_shared_application_preauthorized_actual_accessor_first_slice.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_preauthorized_actual_accessor_first_slice.cj)
- 新增 owner probe：[verify_renderer_visible_window_nsapplication_shared_application_preauthorized_actual_accessor_first_slice_owner.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_preauthorized_actual_accessor_first_slice_owner.sh)

## Stop-line

继续禁止：`setActivationPolicy`、`activateIgnoringOtherApps`、`run` / `stop` / `terminate`、production visible `NSWindow` creation、`makeKeyAndOrderFront` / `orderFront`、AppKit event loop / bounded pump、production `nextDrawable`、production drawable texture color attachment、render command encoder、draw / commit / present、GPU submission、renderer state write、`runtime_state.cj` write、`runtime/cjgui/cjpm.toml` mutation、public API、public / production C ABI、pointer / handle / `id` / `Class` return、artifact / diagnostics publication。

## 当前唯一 next opening

`P1 internal Renderer visible-window production harness NSApplication shared-application external preexisting singleton source readiness truth value boundary / internal readiness owner decision`


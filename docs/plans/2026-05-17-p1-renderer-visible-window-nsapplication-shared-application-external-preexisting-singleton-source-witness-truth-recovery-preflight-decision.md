# P1 Renderer visible-window NSApplication shared-application source witness truth recovery preflight decision

状态：decision / preflight / internal owner selected

## 结论

本轮选择 A：在当前自动化窗口预授权范围内，推进 `external preexisting singleton source witness truth recovery preflight` 的 internal-only readiness owner。

该阶段只消费上一段 `production singleton ownership false-branch downstream` readiness，把 false branch 明确路由回 external preexisting singleton source witness truth recovery preflight。它不恢复 source witness truth，不恢复 source readiness truth，也不授权 production singleton ownership implementation 或 production actual accessor call site。

## 设计理由

- stage 60 已确认 ownership false branch 的阻断点是 source readiness / witness truth evidence gap，而不是继续新增 ownership wrapper。
- 当前 evidence 仍不足以证明 preexisting singleton 由外部 owner 提供、在 renderer 之前观察、由 main-thread/source lifetime/cleanup ownership 共同约束。
- isolated actual accessor probe 与 throwaway creation probe 只能保留为 evidence，不得升级为 source witness truth。

## 本轮允许事项

- 新增 internal-only owner：[runtime_renderer_visible_window_nsapplication_shared_application_external_preexisting_singleton_source_witness_truth_recovery_preflight.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_external_preexisting_singleton_source_witness_truth_recovery_preflight.cj)。
- 新增 owner probe：[verify_renderer_visible_window_nsapplication_shared_application_external_preexisting_singleton_source_witness_truth_recovery_preflight_owner.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_external_preexisting_singleton_source_witness_truth_recovery_preflight_owner.sh)。
- 固定 recovery preflight 所需 facts：external witness required、accepted witness packet required、preexisting singleton before renderer required、main-thread/source lifetime/cleanup ownership required、renderer non-creation / non-accessor invariant required、headless fail-closed required。

## 本轮禁止事项

不得调用 `setActivationPolicy`、`activateIgnoringOtherApps`、`run` / `stop` / `terminate`，不得创建 production visible `NSWindow`，不得调用 `makeKeyAndOrderFront` / `orderFront`，不得启动 AppKit event loop / bounded pump，不得调用 production `nextDrawable`，不得配置 production drawable texture color attachment，不得创建 render command encoder，不得 draw / commit / present，不得提交 GPU work，不得写 renderer state / `runtime_state.cj`，不得修改 `runtime/cjgui/cjpm.toml`，不得新增 public API 或 public / production C ABI。

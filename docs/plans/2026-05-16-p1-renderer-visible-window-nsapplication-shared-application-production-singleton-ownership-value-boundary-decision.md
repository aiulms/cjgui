# P1 Renderer visible-window NSApplication shared-application production singleton ownership value boundary decision

状态：decision / preflight / internal-only value boundary

## 结论

本阶段使用当前自动化窗口预授权继续推进，新增 internal-only runtime owner [runtime_renderer_visible_window_nsapplication_shared_application_production_singleton_ownership_value_boundary.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_production_singleton_ownership_value_boundary.cj)。

该 owner 只消费：

- `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceReadinessTruthValueBoundaryReadiness`
- `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationProductionSingletonOwnershipSourceCleanupBoundaryReadiness`

它只形成 production singleton ownership value boundary，不形成 production singleton ownership truth。

## Truth

- `production_singleton_ownership_value_boundary_opened=true`
- `source_readiness_truth_value=false`
- `external_preexisting_singleton_source_witness_truth=false`
- `production_singleton_ownership_truth=false`
- `production_singleton_implementation=false`
- `production_actual_accessor_call_site=false`
- `cleanup_teardown_execution=false`
- `runtime_state_write=false`
- `cjpm_toml_change=false`

## Stop-line

本阶段不调用 `setActivationPolicy`、`activateIgnoringOtherApps`、`run` / `stop` / `terminate`，不创建 production visible `NSWindow`，不调用 `makeKeyAndOrderFront` / `orderFront`，不启动 AppKit event loop / bounded pump，不调用 production `nextDrawable`，不配置 production drawable texture color attachment，不创建 render command encoder，不 draw / commit / present，不提交 GPU work，不写 renderer state / `runtime_state.cj`，不修改 `runtime/cjgui/cjpm.toml`，不新增 public API 或 public / production C ABI。

## GitNexus

`cangjie-live-codelattice` 对 stage 58 endpoint 与 source-cleanup endpoint 返回 UNKNOWN / not found / impactedCount 0；本阶段不把该结果当安全证明，改用源码读取、build、owner probe、forbidden scan 与 manifest reachability 兜底。

## 下一入口

`P1 internal Renderer visible-window production harness NSApplication shared-application production singleton ownership false-branch downstream decision / next readiness owner decision`

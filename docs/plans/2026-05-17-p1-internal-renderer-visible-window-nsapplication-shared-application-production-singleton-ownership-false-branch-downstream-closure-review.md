# P1 internal Renderer visible-window NSApplication shared-application production singleton ownership false-branch downstream closure review

状态：closure review / stage 60

## 完成内容

本轮在用户预授权范围内完成 false-branch downstream readiness owner：

- 新增 owner：[runtime_renderer_visible_window_nsapplication_shared_application_production_singleton_ownership_false_branch_downstream.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_production_singleton_ownership_false_branch_downstream.cj)
- 新增 owner probe：[verify_renderer_visible_window_nsapplication_shared_application_production_singleton_ownership_false_branch_downstream_owner.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_production_singleton_ownership_false_branch_downstream_owner.sh)

该 owner 只消费：

`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationProductionSingletonOwnershipValueBoundaryReadiness`

并固定：

- false ownership branch 已分类。
- 下游路由回 source readiness / witness truth evidence gap。
- `source_readiness_truth_value=false`。
- `external_preexisting_singleton_source_witness_truth=false`。
- `production_singleton_ownership_truth=false`。
- `production_singleton_implementation=false`。
- `production_actual_accessor_call_site=false`。

## TDD 记录

- RED：新增 owner probe 后先运行，失败在 missing owner。
- GREEN：新增 internal owner 后，owner probe 通过。

## 验证摘要

- `verify_renderer_visible_window_nsapplication_shared_application_production_singleton_ownership_false_branch_downstream_owner.sh`：通过。
- `cjpm build --target-dir /tmp/cjgui-false-branch-downstream-stage60-build --skip-script`：通过，保留既有 unused warnings。

`envsetup.sh` 在当前 automation sandbox 内直接读取 `ps` 会被拒绝；本轮 build 使用 shell-local `ps` function shim 后执行 `source /Users/jiangxuanyang/cangjie-toolchains/cangjie/envsetup.sh`，再运行 `cjpm build`。该 shim 不修改工具链文件或仓库文件。

## Stop-line

Stop-line 保持。未新增或调用：

- `setActivationPolicy`
- `activateIgnoringOtherApps`
- `run` / `stop` / `terminate`
- production visible `NSWindow`
- `makeKeyAndOrderFront` / `orderFront`
- AppKit event loop / bounded run-loop pump
- production `nextDrawable`
- production drawable texture color attachment
- render command encoder
- draw / commit / present / GPU submission
- `runtime/cjgui/src/runtime_state.cj` 写入
- `runtime/cjgui/cjpm.toml` 修改
- public API / public C ABI

## 结论

false-branch downstream owner 足够作为当前 production singleton ownership false branch 的 canonical endpoint。下一步应转向 external preexisting singleton source witness truth recovery preflight，而不是继续包装 ownership false branch。

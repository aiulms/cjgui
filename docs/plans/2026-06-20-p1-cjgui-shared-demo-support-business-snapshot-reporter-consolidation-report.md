# CJGUI 共享 demo_support 业务快照 reporter 收敛报告

日期：2026-06-20

状态：工程 checkpoint / demo_support reuse / demo business evidence cleanup

## 本轮结论

本轮新增 [runtime_cjgui_experimental_demo_business_snapshot_reporter.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/demo_support/runtime_cjgui_experimental_demo_business_snapshot_reporter.cj)，提供 `CjguiExperimentalDemoBusinessSnapshotReporter`。

当前 10 个 runnable demo 都通过同一个 shared reporter 渲染 status transition、business text facts 与 readback bool facts。原先分散在 demo-local `println("cjgui ...: status_before=...")`、`state_before`、`state_after`、`state_readback`、`summary_*`、`served_demo(s)`、`reused_demos`、`component_kinds`、`owner_local_write_readback`、`public_api_available` 等业务快照模板已退役。

## 代码范围

- 新增 shared reporter：[runtime_cjgui_experimental_demo_business_snapshot_reporter.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/demo_support/runtime_cjgui_experimental_demo_business_snapshot_reporter.cj)。
- 接入 10 个 demo app：[todo_app.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/demo/todo_app.cj)、[settings_app.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/demo/settings_app.cj)、[chat_app.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/demo/chat_app.cj)、[file_browser_app.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/demo/file_browser_app.cj)、[ai_generated_ui_app.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/demo/ai_generated_ui_app.cj)、[shared_demo_harness_app.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/demo/shared_demo_harness_app.cj)、[shared_multi_demo_harness_app.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/demo/shared_multi_demo_harness_app.cj)、[shared_layout_style_input_focus_contract_app.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/demo/shared_layout_style_input_focus_contract_app.cj)、[ai_generated_ui_shared_contract_app.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/demo/ai_generated_ui_shared_contract_app.cj)、[reusable_component_contract_app.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/demo/reusable_component_contract_app.cj)。
- 更新 10 个 focused verifier 与 aggregate verifier：[verify_cjgui_shared_demo_run_harness.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_cjgui_shared_demo_run_harness.sh)。

## 验证证据

- `runtime/cjgui/native/scripts/verify_cjgui_shared_demo_run_harness.sh` 通过，实际编译并运行 10 个 demo binary，回显 `cjgui_shared_demo_business_snapshot_reporter=CjguiExperimentalDemoBusinessSnapshotReporter`、`cjgui_shared_demo_business_snapshot_reporter_demo_count=10`、`cjgui_shared_demo_business_snapshot_output_rendering_shared=true` 与 `cjgui_shared_demo_local_business_snapshot_println_retired=true`。
- `runtime/cjgui/native/scripts/verify_cjgui_legacy_demo_output_api_retirement.sh` 通过。
- `runtime/cjgui/native/scripts/verify_cjgui_shared_contract_legacy_output_api_retirement.sh` 通过。
- `runtime/cjgui/native/scripts/verify_cjgui_shared_demo_commit_write_readback.sh` 通过。
- `cjpm build --target-dir /tmp/cjgui-shared-demo-business-snapshot-reporter-target --skip-script` 通过；仅出现既有 unused / stack-frame warnings。

## 图谱与边界

CodeLattice 工具在当前会话未暴露；`tool_search` 未找到可调用 CodeLattice 工具。GitNexus 对 `CjguiExperimentalDemoProofReporter` 与 `CjguiExperimentalDemoRunResultReporter` 返回 `UNKNOWN / not found`，按近期 demo_support 新符号未索引记录；本轮以源码读取、focused/aggregate binary verifier、`cjpm build` 与扫描兜底。

本轮不修改 `runtime_state.cj`，不写 renderer state，不调用 native bridge，不新增 public C ABI，不改变 Renderer canonical tail。`CjguiExperimentalDemoBusinessSnapshotReporter` 只服务 demo_support experimental evidence，不代表稳定 toolkit API。

## 后续入口

下一步建议进入：

`P1 CJGUI shared demo_support demo metadata reporter consolidation for identity/static evidence cleanup`

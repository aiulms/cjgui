# P1 CJGUI shared demo UI state core 覆盖完成报告

日期：2026-06-17

## 本次让什么真实前进

本次把 [runtime_cjgui_experimental_demo_ui_state_core.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/demo_support/runtime_cjgui_experimental_demo_ui_state_core.cj) / `CjguiExperimentalDemoUiStateCore` 从 6 个 demo 扩展到当前 10 个独立 runnable demo 全覆盖。

新增迁移的 demo：

- [todo_app.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/demo/todo_app.cj)：`TodoList` 现在用 shared core 承载 `layout=todo_list;style=completed_accent;input=Write first CJGUI todo;focus=todo_first_item`。
- [shared_demo_harness_app.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/demo/shared_demo_harness_app.cj)：`SharedDemoHarnessState` 现在用 shared core 替代 demo-local focus / style 字段。
- [shared_multi_demo_harness_app.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/demo/shared_multi_demo_harness_app.cj)：`SharedMultiDemoHarnessState` 现在用 shared core 管理当前 focus / style / input，同时保留 route history 作为 harness 业务 readback。
- [shared_layout_style_input_focus_contract_app.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/demo/shared_layout_style_input_focus_contract_app.cj)：该 contract demo 的 layout / style / input / focus 四类状态已整体收敛到 shared core。

这让 `CjguiExperimentalDemoUiStateCore` 不再只是代表 demo 的 shared helper，而是所有当前 runnable demo 的共同 UI 状态 primitive。它承载 owner-local layout / style / text input / focus 写入读回，不是 readiness Bool、report-only 名字或 renderer truth。

## 证据

- 红灯验证：四个目标 focused verifier 先失败于 missing shared UI state core import / `sharedUiState()`，证明验证脚本能捕捉缺口。
- Focused Todo verifier：`runtime/cjgui/native/scripts/verify_cjgui_todo_demo_app.sh` 通过，回显 `todo_shared_state_core_imported=true`。
- Focused Settings verifier：`runtime/cjgui/native/scripts/verify_cjgui_settings_demo_app.sh` 通过，回显 `settings_shared_state_core_imported=true`。
- Focused Chat verifier：`runtime/cjgui/native/scripts/verify_cjgui_chat_demo_app.sh` 通过，回显 `chat_shared_state_core_imported=true`。
- Focused FileBrowser verifier：`runtime/cjgui/native/scripts/verify_cjgui_file_browser_demo_app.sh` 通过，回显 `file_browser_shared_state_core_imported=true`。
- Focused AI-generated UI verifier：`runtime/cjgui/native/scripts/verify_cjgui_ai_generated_ui_demo_app.sh` 通过，回显 `ai_generated_ui_shared_state_core_imported=true`。
- Focused Shared demo harness verifier：`runtime/cjgui/native/scripts/verify_cjgui_shared_demo_harness_app.sh` 通过，回显 `shared_demo_harness_shared_state_core_imported=true`。
- Focused Shared multi-demo harness verifier：`runtime/cjgui/native/scripts/verify_cjgui_shared_multi_demo_harness_app.sh` 通过，回显 `shared_multi_demo_harness_shared_state_core_imported=true`。
- Focused Shared layout/style/input/focus contract verifier：`runtime/cjgui/native/scripts/verify_cjgui_shared_layout_style_input_focus_contract_app.sh` 通过，回显 `shared_layout_style_input_focus_contract_shared_state_core_imported=true`。
- Focused AI-generated UI shared contract verifier：`runtime/cjgui/native/scripts/verify_cjgui_ai_generated_ui_shared_contract_app.sh` 通过，回显 `ai_generated_ui_shared_contract_shared_state_core_imported=true`。
- Focused Reusable component contract verifier：`runtime/cjgui/native/scripts/verify_cjgui_reusable_component_contract_app.sh` 通过，回显 `reusable_component_contract_shared_state_core_imported=true`。

## 验证结果

- 10 个 focused verifier 均通过，且均实际编译并执行 demo 二进制，校验业务 before -> after / owner-local write readback / shared output / shared UI state core readback。
- `cjpm build --target-dir /tmp/cjgui-shared-demo-ui-state-core-coverage-target --skip-script`：通过。构建输出仍包含既有 stage owner 的 unused / stack frame warning，但没有本轮新增失败。
- `git diff --check`：通过。
- Markdown absolute link check：检查 2022 个 Markdown 文件、18877 个项目绝对链接，missing target 数量为 `0`。
- Protected path scan：`runtime/cjgui/src/runtime_state.cj` 仍为 `10065` 行；`runtime_state.cj`、`runtime/cjgui/cjpm.toml`、production native bridge 与 smoke native files 无 diff。
- Public declaration scan：`git diff -- '*.cj' | rg '^\+.*public'` 无匹配，本轮没有新增 public API。
- Native / renderer forbidden scan：demo 与 demo_support diff 中无 `foreign func`、native bridge、AppKit / Metal / drawable / command buffer / render / renderer state 写入路径。
- CodeLattice：`CjguiExperimentalDemoUiStateCore` 仍遇到 stale baseline / file_added，符号 context / impact 未覆盖；after-edit native review 为 static-only，production assist 风险 LOW，但 changed symbol 仍未被图谱识别。按 AGENTS 记录为图谱覆盖缺口，最终以源码、focused verifier、build 和扫描兜底。
- GitNexus `detect-changes --repo cangjie-live-codelattice --scope unstaged`：返回 15 files / 2 symbols / affected processes `0` / risk `low`。

## 边界

- 没有新增 public C ABI。
- 没有修改 `runtime/cjgui/src/runtime_state.cj` 或 `runtime/cjgui/cjpm.toml`。
- 没有调用 native bridge、AppKit、Metal、drawable、command buffer 或 render path。
- Shared UI state core 仍是 demo process-local owner-local value facts，不是 renderer state publication、backend-ready truth 或 stable toolkit API。

## 下一步最高价值目标

`P1 CJGUI shared component/action model first slice for Todo / Settings / Chat`

当前 output builder 与 UI state core 已覆盖全部 10 个 runnable demo；下一步应继续把 Todo / Settings / Chat 里的组件描述、动作输入与 commit/readback contract 收敛为 shared primitive，减少 per-demo State/API 复制，而不是继续新增同构 owner / readiness wrapper。

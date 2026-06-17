# CJGUI legacy demo Output API 退役第一切片报告

本次让 CJGUI 的 shared demo output 主路径真实前进：Todo、Settings、Chat、FileBrowser 与 AI-generated UI 五个代表 demo 的旧 demo-specific Output API public declaration 已退役，5 个 demo 继续通过 `CjguiExperimentalDemoComponentActionSession` / `CjguiExperimentalDemoOutput` 运行并读回业务 before / after / action facts。

证据是 5 个 legacy API 文件只保留 tombstone 注释与 `package cjgui`，不再声明 `CjguiExperimentalXxxDemoOutput` 或 `cjguiExperimentalBuildXxxDemoOutput(...)`；新增 verifier 实际调用 5 个代表 demo verifier，确认 demo 二进制仍运行，且回显 `legacy_output_api_direct_consumption=false` 与 `shared_component_action_session_imported=true`。

## 本次真实前进

- [runtime_cjgui_experimental_todo_demo_api.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_cjgui_experimental_todo_demo_api.cj)：退役 `CjguiExperimentalTodoDemoOutput` / `cjguiExperimentalBuildTodoDemoOutput(...)`。
- [runtime_cjgui_experimental_settings_demo_api.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_cjgui_experimental_settings_demo_api.cj)：退役 `CjguiExperimentalSettingsDemoOutput` / `cjguiExperimentalBuildSettingsDemoOutput(...)`。
- [runtime_cjgui_experimental_chat_demo_api.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_cjgui_experimental_chat_demo_api.cj)：退役 `CjguiExperimentalChatDemoOutput` / `cjguiExperimentalBuildChatDemoOutput(...)`。
- [runtime_cjgui_experimental_file_browser_demo_api.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_cjgui_experimental_file_browser_demo_api.cj)：退役 `CjguiExperimentalFileBrowserDemoOutput` / `cjguiExperimentalBuildFileBrowserDemoOutput(...)`。
- [runtime_cjgui_experimental_ai_generated_ui_demo_api.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_cjgui_experimental_ai_generated_ui_demo_api.cj)：退役 `CjguiExperimentalAiGeneratedUiDemoOutput` / `cjguiExperimentalBuildAiGeneratedUiDemoOutput(...)`。
- 新增 [verify_cjgui_legacy_demo_output_api_retirement.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_cjgui_legacy_demo_output_api_retirement.sh)，把 tombstone scan 与 5 个代表 demo binary verifier 串成一个 focused proof。

## before / after

- Before：5 个代表 demo 已不直接消费 legacy Output API，但 `runtime/cjgui/src` 仍公开 5 组 demo-specific output class / builder，shared output path 与旧 wrapper 并存。
- After：5 组代表 legacy public declarations 已消失，历史链接保留为 tombstone；demo runtime proof 仍来自 shared `demo_support`。
- Readback：Todo、Settings、Chat、FileBrowser 与 AI-generated UI verifier 继续实际编译运行 demo 二进制，回显 owner-local before / after / readback 与 shared session facts。

## 验证

- `runtime/cjgui/native/scripts/verify_cjgui_legacy_demo_output_api_retirement.sh`：通过，回显 `legacy_demo_output_api_retired_count=5`、`representative_demo_shared_output_path_verified=true`、`representative_demo_binary_verifier_count=5`。
- `runtime/cjgui/native/scripts/verify_cjgui_todo_demo_app.sh`：通过。
- `runtime/cjgui/native/scripts/verify_cjgui_settings_demo_app.sh`：通过。
- `runtime/cjgui/native/scripts/verify_cjgui_chat_demo_app.sh`：通过。
- `runtime/cjgui/native/scripts/verify_cjgui_file_browser_demo_app.sh`：通过。
- `runtime/cjgui/native/scripts/verify_cjgui_ai_generated_ui_demo_app.sh`：通过。
- 剩余 5 个 demo verifier：`verify_cjgui_shared_demo_harness_app.sh`、`verify_cjgui_shared_multi_demo_harness_app.sh`、`verify_cjgui_shared_layout_style_input_focus_contract_app.sh`、`verify_cjgui_ai_generated_ui_shared_contract_app.sh`、`verify_cjgui_reusable_component_contract_app.sh` 均通过，确认本轮退役未破坏 shared / contract demo。
- `cjpm build --target-dir /tmp/cjgui-legacy-demo-output-api-retirement-target --skip-script`：通过。
- `git diff --check`：通过。
- Markdown absolute link check：通过，项目 docs / README 范围 missing target 数量为 `0`。
- protected path scan：`runtime/cjgui/src/runtime_state.cj` 仍为 `10065` 行，本轮未修改 `runtime_state.cj`、`runtime/cjgui/cjpm.toml`、production native bridge 或 smoke native files。
- public declaration scan：本轮删除 10 个 demo-specific experimental public declarations；没有新增 public declaration。
- GitNexus impact：`CjguiExperimentalTodoDemoOutput`、`CjguiExperimentalSettingsDemoOutput`、`CjguiExperimentalChatDemoOutput`、`CjguiExperimentalFileBrowserDemoOutput` 与 `CjguiExperimentalAiGeneratedUiDemoOutput` 均返回 `UNKNOWN / not found`，按图谱未覆盖处理，不作为安全证明。
- GitNexus `detect-changes --repo cangjie-live-codelattice --scope unstaged`：通过；CodeLattice 对 `runtime/cjgui` 当前返回 stale baseline / sourceFileCount=0，按源码、verifier 与 build 兜底。

## 边界

本轮不新增 public C ABI，不写 `runtime_state.cj` / renderer state，不调用 native bridge，不声明 Renderer backend ready truth。Tombstone 文件只为历史链接稳定存在，不是 runtime truth，也不是新的 compatibility surface。

## 下一步最高价值目标

`P1 CJGUI shared/contract legacy Output API retirement second slice`

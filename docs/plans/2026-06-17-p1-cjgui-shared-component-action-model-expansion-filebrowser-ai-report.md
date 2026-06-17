# P1 CJGUI shared component/action model 扩展到 FileBrowser 与 AI-generated UI 报告

日期：2026-06-17

## 本次让什么真实前进

本次把 FileBrowser 与 AI-generated UI 两个代表 demo 从手写 `CjguiExperimentalDemoInteractionTrace` + `CjguiExperimentalDemoOutputBuilder` 串联，迁到 shared `CjguiExperimentalDemoComponentActionSession`。

迁移后，Todo、Settings、Chat、FileBrowser、AI-generated UI 五个代表 demo 都通过同一组 shared primitive 记录 component/action route、读回 shared UI state core，并构建 `CjguiExperimentalDemoOutput`。这让 CJGUI demo 主路径更像 framework：业务方法执行 owner-local 写入后直接记录组件动作，而不是每个 demo 在 `main` 中重复拼 trace / output。

## 代码证据

- [file_browser_app.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/demo/file_browser_app.cj)：`FileBrowserState` 现在持有 `CjguiExperimentalDemoComponentActionSession`，由 `expand`、`applyFilter`、`selectEntry`、`refreshDetail`、`moveFocus` 记录 `folder_tree:file_browser.expand_folder`、`tree_filter:file_browser.filter_entries`、`file_row:file_browser.select_file`、`detail_pane:file_browser.refresh_detail`、`detail_pane:file_browser.move_focus`。
- [ai_generated_ui_app.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/demo/ai_generated_ui_app.cj)：`AiGeneratedUiState` 现在持有 `CjguiExperimentalDemoComponentActionSession`，由 `previewDiff`、`explain`、`acceptAndRefresh`、`moveFocus` 记录 `diff_panel:ai_generated_ui.preview_diff`、`explain_panel:ai_generated_ui.explain_changes`、`generated_form:ai_generated_ui.accept_refresh`、`save_button:ai_generated_ui.move_focus`。
- [verify_cjgui_file_browser_demo_app.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_cjgui_file_browser_demo_app.sh) 与 [verify_cjgui_ai_generated_ui_demo_app.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_cjgui_ai_generated_ui_demo_app.sh) 都复制 shared session source 到临时 package，并实际编译 / 运行 demo 二进制。

## 验证结果

- `runtime/cjgui/native/scripts/verify_cjgui_todo_demo_app.sh`、`verify_cjgui_settings_demo_app.sh`、`verify_cjgui_chat_demo_app.sh`：通过，确认 first-slice 三个代表 demo 仍通过 `CjguiExperimentalDemoComponentActionSession` 运行。
- `runtime/cjgui/native/scripts/verify_cjgui_file_browser_demo_app.sh`：通过，回显 `file_browser_public_api_name=CjguiExperimentalDemoComponentActionSession`、`file_browser_shared_component_action_session_imported=true`、`file_browser_owner_local_write_readback=true`。
- `runtime/cjgui/native/scripts/verify_cjgui_ai_generated_ui_demo_app.sh`：通过，回显 `ai_generated_ui_public_api_name=CjguiExperimentalDemoComponentActionSession`、`ai_generated_ui_shared_component_action_session_imported=true`、`ai_generated_ui_owner_local_write_readback=true`。
- 五个 verifier 都执行 demo 二进制，并校验业务 before -> after / readback output；不是只靠 grep 或 `cjpm build`。
- `cjpm build --target-dir /tmp/cjgui-shared-component-action-model-expansion-target --skip-script`：通过。构建仍有既有 unused variable / stack frame warning，但没有本次 demo/session 迁移错误。
- `git diff --check`：通过。
- Markdown absolute link check：检查项目 docs / README 范围内 2025 个 Markdown 文件、17312 个项目绝对链接，missing target 数量为 `0`。
- protected path scan：`runtime/cjgui/src/runtime_state.cj` 仍为 `10065` 行；`runtime_state.cj`、`runtime/cjgui/cjpm.toml`、production native bridge 与 smoke native files 均无 diff。
- public declaration scan 与 native forbidden scan：无新增 public declaration、native bridge、AppKit / Metal、renderer state 或 GPU submission 相关匹配。
- CodeLattice：`native_review` 识别 FileBrowser / AI-generated UI demo 与 verifier 脚本 diff，但 baseline 对新 demo symbols 仍是 stale / unknown hunk；按源码阅读与 focused verifier 兜底。
- GitNexus `detect-changes --repo cangjie-live-codelattice --scope unstaged`：返回 affected processes `0` / risk `low`；图谱只识别 README 标题级 symbol，按源码、build、verifier 与 scan 兜底。

## 边界

- 没有新增 public C ABI。
- 没有新增 native bridge 调用。
- 没有写 `runtime_state.cj` / renderer state。
- 没有修改 `runtime/cjgui/cjpm.toml`。
- 没有把 demo output 包装成 renderer-ready truth。
- `CjguiExperimentalDemoComponentActionSession` 仍是 experimental demo support public class，只保存 demo process-local in-memory facts。

## 下一步最高价值目标

`P1 CJGUI shared component/action session coverage completion for shared harness and contract demos`

五个代表 demo 已经走到同一 shared component/action session 主路径。下一步应把 Shared demo harness、Shared multi-demo harness、Shared layout/style/input/focus contract、AI-generated UI shared contract 与 Reusable component contract 这些仍直接使用 trace / builder 的 demo 继续迁入 session，进一步减少同构 demo-local trace/output 串联。

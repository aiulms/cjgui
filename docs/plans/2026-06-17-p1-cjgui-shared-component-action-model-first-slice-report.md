# P1 CJGUI shared component/action model 第一刀报告

日期：2026-06-17

## 本次让什么真实前进

本次新增 [runtime_cjgui_experimental_demo_component_action_session.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/demo_support/runtime_cjgui_experimental_demo_component_action_session.cj) / `CjguiExperimentalDemoComponentActionSession`，并让 Todo、Settings、Chat 三个代表 demo 从各自 `main` 手写 `CjguiExperimentalDemoInteractionTrace` + `CjguiExperimentalDemoOutputBuilder` 串联，迁到 shared component/action session。

这次不是新增 readiness wrapper：`CjguiExperimentalDemoComponentActionSession` 真实持有 shared `CjguiExperimentalDemoUiStateCore` 与 `CjguiExperimentalDemoInteractionTrace`，提供 `recordComponentAction(componentId, action, afterState)`、shared UI state 读回、component/action route 读回，以及 `buildOutput(...)`。三个 demo 的业务 state 方法在执行 owner-local 写入后直接记录 component/action，而不是在 `main` 里重复拼 action trace。

迁移结果：

- [todo_app.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/demo/todo_app.cj)：`TodoList.add` / `TodoList.complete` 通过 shared session 记录 `todo_input:todo.add,todo_item:todo.complete`。
- [settings_app.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/demo/settings_app.cj)：`SettingsPanelState` 的 toggle / theme / username / focus 写入通过 shared session 记录 component action route。
- [chat_app.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/demo/chat_app.cj)：`ChatThreadState` 的 composer / send button / message list 写入通过 shared session 记录 component action route。

## 证据

- Todo focused verifier：`runtime/cjgui/native/scripts/verify_cjgui_todo_demo_app.sh` 通过，实际编译并运行 demo 二进制，回显 `todo_public_api_name=CjguiExperimentalDemoComponentActionSession`、`todo_shared_component_action_session_imported=true` 与 before -> after / readback output。
- Settings focused verifier：`runtime/cjgui/native/scripts/verify_cjgui_settings_demo_app.sh` 通过，实际编译并运行 demo 二进制，回显 `settings_public_api_name=CjguiExperimentalDemoComponentActionSession`、`settings_shared_component_action_session_imported=true` 与 before -> after / readback output。
- Chat focused verifier：`runtime/cjgui/native/scripts/verify_cjgui_chat_demo_app.sh` 通过，实际编译并运行 demo 二进制，回显 `chat_public_api_name=CjguiExperimentalDemoComponentActionSession`、`chat_shared_component_action_session_imported=true` 与 before -> after / readback output。
- 三个 verifier 都把 shared session source 复制进临时 `cjgui.demo_support` package 后再构建，避免只靠源码 grep 误判。

## 验证结果

- Focused verifier：Todo、Settings、Chat 均通过并执行 demo 二进制。
- `cjpm build --target-dir /tmp/cjgui-shared-component-action-model-target --skip-script`：通过。构建输出仍包含既有 stage owner 的 unused / stack frame warning，但没有本轮新增失败。
- `git diff --check`：通过。
- Markdown absolute link check：检查 4997 个 Markdown / README 文件、18956 个项目绝对链接，missing target 数量为 `0`。
- Protected path scan：`runtime/cjgui/src/runtime_state.cj` 仍为 `10065` 行；`runtime_state.cj`、`runtime/cjgui/cjpm.toml`、production native bridge 与 smoke native files 无 diff。
- Public declaration scan：本轮新增 experimental demo support public class `CjguiExperimentalDemoComponentActionSession`，包含 `recordComponentAction(componentId: String, action: String, afterState: String)` 与 `buildOutput(domainSummary: String, readbackOk: Bool): CjguiExperimentalDemoOutput`；demo source 自身没有新增 public declaration。
- Native / renderer forbidden scan：demo 与 demo_support diff 中无 `foreign func`、native bridge、AppKit / Metal / drawable / command buffer / render / renderer state 写入路径。
- CodeLattice：`native_review` / `production_assist` 返回 stale baseline / file_added，changed symbol 仍未被图谱覆盖；production assist 风险 LOW。按 AGENTS 记录为图谱覆盖缺口，最终以源码、focused verifier、build 和扫描兜底。
- GitNexus `detect-changes --repo cangjie-live-codelattice --scope unstaged`：返回 12 files / 3 symbols / affected processes `0` / risk `low`。

## 边界

- 新增的是 experimental Cangjie demo support public class，不是 stable public API。
- 没有新增 public C ABI。
- 没有修改 `runtime/cjgui/src/runtime_state.cj` 或 `runtime/cjgui/cjpm.toml`。
- 没有调用 native bridge、AppKit、Metal、drawable、command buffer 或 render path。
- `CjguiExperimentalDemoComponentActionSession` 只保存 demo process-local in-memory facts，不是 renderer state publication、backend-ready truth 或 toolkit 稳定 API。

## 下一步最高价值目标

`P1 CJGUI shared component/action model expansion for FileBrowser / AI-generated UI`

Todo / Settings / Chat 已经证明 shared component/action session 可以承载业务 action、UI state 与 output 构建。下一步应把 FileBrowser 和 AI-generated UI 也迁到同一路径，继续减少 demo-local action/output 串联，而不是新开同构 owner / readiness wrapper。

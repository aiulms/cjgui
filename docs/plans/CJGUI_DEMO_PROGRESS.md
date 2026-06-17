# CJGUI demo 进度看板

最后更新：2026-06-17

本看板只记录有代码证据的 demo app 进度。`runtime_renderer_stage*_internal_*_demo_*` owner / probe 不算独立 demo app；只有 `runtime/cjgui/demo/*_app.cj` 这类带 `main`、确定性输出或状态读回的文件才能推进状态。

## 状态规则

- `not_started`：没有独立 demo app 文件。
- `scaffolded`：存在独立 demo app 文件，且包含 `main` 与确定性输出或状态读回。
- `api_consumed`：demo 消费有效的非 Bool public API，且该 API 承载组件 / 动作 / 状态 / commit result / demo output，不是 readiness projection。
- `state_writable`：demo 内 owner-local / in-memory / demo-host 状态可写入并读回。
- `runnable`：focused script 可编译并运行 demo，且输出 before->after 证据。

## 当前进度

| Demo | 状态 | 代码证据 | before->after | 备注 |
| --- | --- | --- | --- | --- |
| Todo | `runnable` | [todo_app.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/demo/todo_app.cj)、[runtime_cjgui_experimental_todo_demo_api.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_cjgui_experimental_todo_demo_api.cj)、[verify_cjgui_todo_demo_app.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_cjgui_todo_demo_app.sh) | `state_writable -> runnable` | 独立 demo app 已包含 `main`、消费 experimental 非 Bool public API `cjguiExperimentalBuildTodoDemoOutput(firstTitle: String, firstDone: Bool): CjguiExperimentalTodoDemoOutput`，用 `TodoList` owner-local `var` 状态执行 add / complete 写入与 readback 输出，并由 focused verification 编译运行到 `runnable`；demo 输出已移除 stop-line false 字段，治理事实只由 verifier / report 记录。 |
| Settings | `runnable` | [settings_app.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/demo/settings_app.cj)、[runtime_cjgui_experimental_settings_demo_api.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_cjgui_experimental_settings_demo_api.cj)、[verify_cjgui_settings_demo_app.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_cjgui_settings_demo_app.sh) | `scaffolded -> runnable` | 独立 demo app 已消费非 Bool experimental API `cjguiExperimentalBuildSettingsDemoOutput(...) -> CjguiExperimentalSettingsDemoOutput`，并在 `SettingsPanelState` 内执行 auto-save toggle、theme select、username update、focus move 的 owner-local 写入读回；focused verifier 编译运行 demo，输出业务 before / after 与 API output。 |
| Chat | `runnable` | [chat_app.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/demo/chat_app.cj)、[runtime_cjgui_experimental_chat_demo_api.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_cjgui_experimental_chat_demo_api.cj)、[verify_cjgui_chat_demo_app.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_cjgui_chat_demo_app.sh) | `not_started -> runnable` | 独立 Chat demo 已包含 `main`，消费非 Bool experimental API `cjguiExperimentalBuildChatDemoOutput(...) -> CjguiExperimentalChatDemoOutput`，并在 `ChatThreadState` 内执行 type message、send、append reply、focus move 的 owner-local 写入读回；focused verifier 编译运行 demo，输出业务 before / after 与 API output。 |
| FileBrowser | `not_started` | 无独立 `file_browser_app.cj` | 无 | stage owner / probe 记录不算独立 demo app。 |
| AI-generated UI | `not_started` | 无独立 `ai_generated_ui_app.cj` | 无 | stage owner / probe 记录不算独立 demo app。 |

## 本轮白名单证据

- 白名单 1：Chat demo 从 `not_started` 前进到 `runnable`，证据是 [verify_cjgui_chat_demo_app.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_cjgui_chat_demo_app.sh) 编译并运行 [chat_app.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/demo/chat_app.cj)，回显 `chat_demo_progress_before=not_started` 与 `chat_demo_progress_after=runnable`。
- 白名单 2：Chat demo 消费非 Bool public API `cjguiExperimentalBuildChatDemoOutput(messageCount: Int64, lastSender: String, lastText: String, composerText: String, focusTarget: String, layoutKind: String): CjguiExperimentalChatDemoOutput`，返回领域输出对象而不是 readiness / Bool projection。
- 白名单 3：Chat demo 内 `ChatThreadState` 使用 owner-local `var` 字段与 `ArrayList<ChatMessage>` 执行 type message、send、append reply、focus move，并输出 `state_before=messages=1;last=assistant:Welcome to CJGUI;composer=;focus=composer` 与 `state_after=messages=3;last=assistant:Chat demo received;composer=;focus=message_list`。
- Demo 输出治理修正：Chat / Settings / Todo demo 输出只保留业务 before / after、interaction、state readback 与 API output；`runtime_state_write=false`、`renderer_state_write=false`、`public_c_abi_added=false` 等 stop-line 只保留在 verifier / report 验证段。

## 边界

本看板不是白名单证据本身，只索引已有代码证据。它不新增 public API，不写 `runtime_state.cj` / renderer state，不调用 native bridge，不声明 renderer ready truth。

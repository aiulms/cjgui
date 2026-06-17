# P1 CJGUI 最小 UI framework Chat runnable 阶段报告

日期：2026-06-17

## 本轮白名单证据

本轮白名单证据是 Chat 独立 demo app 从 `not_started` 前进到 `runnable`。

- Demo / API / state 前进：新增 [chat_app.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/demo/chat_app.cj)，新增 experimental 非 Bool public API `cjguiExperimentalBuildChatDemoOutput(...) -> CjguiExperimentalChatDemoOutput`，并用 `ChatThreadState` 执行 type message、send、append reply、focus move 的 owner-local 写入读回。
- Demo before→after：`state_before=messages=1;last=assistant:Welcome to CJGUI;composer=;focus=composer`，`state_after=messages=3;last=assistant:Chat demo received;composer=;focus=message_list`。
- 辅助验证：focused Chat / Todo / Settings verifier、`cjpm build --skip-script`、public / protected / forbidden scans、Markdown link / reachability、CodeLattice / GitNexus 检查都是辅助证据，不替代 Chat demo 业务输出。
- 验证结果：Chat focused verifier 已编译并运行 demo；Todo / Settings focused verifier 仍通过；`cjpm build --skip-script`、`git diff --check` 与保护扫描结果记录在本报告验证段。
- Next route：`P1 CJGUI FileBrowser runnable demo first slice`，或 `P1 CJGUI AI-generated UI accept-refresh demo first slice`；不要回到 owner/readiness/manager/surface/envelope 包装。
- 本轮未 stage / commit / push。

## Demo 业务输出

Chat demo 的业务输出现在像一个小聊天视图，而不是 stop-line 报告：

```text
cjgui chat demo app: demo=chat
cjgui chat demo app: status_before=not_started
cjgui chat demo app: status_after=runnable
cjgui chat demo app: layout=threaded_chat
cjgui chat demo app: interaction=type_message,send_message,append_reply,move_focus
cjgui chat demo app: state_before=messages=1;last=assistant:Welcome to CJGUI;composer=;focus=composer
cjgui chat demo app: state_after=messages=3;last=assistant:Chat demo received;composer=;focus=message_list
cjgui chat demo app: state_readback=true
cjgui chat demo app: public_api_consumed=true
cjgui chat demo app: public_api_name=cjguiExperimentalBuildChatDemoOutput
cjgui chat demo app: public_api_output=messages=3;last=assistant:Chat demo received;composer=;focus=message_list;layout=threaded_chat
```

`runtime_state_write=false`、`renderer_state_write=false`、`public_c_abi_added=false` 等 stop-line 不由 demo 输出；它们只在 verifier / report 的验证段记录。

## Public API 证据

新增 API：

```text
public class CjguiExperimentalChatDemoOutput
public func cjguiExperimentalBuildChatDemoOutput(
    messageCount: Int64,
    lastSender: String,
    lastText: String,
    composerText: String,
    focusTarget: String,
    layoutKind: String
): CjguiExperimentalChatDemoOutput
```

稳定性级别：`experimental_demo`。

非 Bool 证据：返回类型是 `CjguiExperimentalChatDemoOutput`，包含 `demoName`、`messageCount`、`lastSender`、`lastText`、`composerText`、`focusTarget`、`layoutKind` 与 `summary`。它不调用 internal readiness draft，不返回 Bool readiness，不写 `runtime_state.cj` / renderer state，也不扩 public C ABI。

Demo proof：`ChatThreadState.buildApiOutput()` 调用该 API，并在 demo main 中校验 output fields 与 `summary`。

## State write / readback

- Write scope：`ChatThreadState.messages`、`composerText`、`focusTarget`、`lastSender`、`lastText`。
- Before：`messages=1;last=assistant:Welcome to CJGUI;composer=;focus=composer`。
- Actions：`updateComposer("Ship Chat demo")`、`sendComposer("owner")`、`appendMessage("assistant", "Chat demo received")`、`moveFocus("message_list")`。
- After：`messages=3;last=assistant:Chat demo received;composer=;focus=message_list`。
- Readback：demo 用 `businessState()`、`messageCount()` 与 `CjguiExperimentalChatDemoOutput.summary` 校验写入结果。
- Rollback / not-published boundary：本轮状态只存在于 demo process-local in-memory class；进程退出即回收，没有持久化、没有 publication、没有 shared runtime state。

## 修改文件

- [chat_app.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/demo/chat_app.cj)
- [runtime_cjgui_experimental_chat_demo_api.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_cjgui_experimental_chat_demo_api.cj)
- [verify_cjgui_chat_demo_app.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_cjgui_chat_demo_app.sh)
- [todo_app.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/demo/todo_app.cj)
- [verify_cjgui_todo_demo_app.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_cjgui_todo_demo_app.sh)
- [CJGUI_DEMO_PROGRESS.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/CJGUI_DEMO_PROGRESS.md)
- [stage report](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-06-17-p1-cjgui-minimal-ui-framework-demo-app-stage-report.md)
- [README.md](/Users/jiangxuanyang/Desktop/cangjie/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)
- [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)
- [DESIGN_INTENT_INDEX.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/DESIGN_INTENT_INDEX.md)

## 验证结果

- Focused Chat verification：通过。`runtime/cjgui/native/scripts/verify_cjgui_chat_demo_app.sh` 输出 `cjgui_chat_demo_app_compiled=true`、`cjgui_chat_demo_app_ran=true`、`chat_demo_progress_before=not_started`、`chat_demo_progress_after=runnable`、`chat_non_bool_public_api_consumed=true`、`chat_owner_local_write_readback=true`。
- Focused Todo verification：通过。Todo demo 仍为 `runnable`，并已移除 demo 输出中的 governance stop-line false 字段；相关 stop-line 只由 verifier echo 记录。
- Focused Settings verification：通过。既有 Settings runnable 证据未被破坏。
- `cjpm build --skip-script`：通过。命令在 `runtime/cjgui` 下使用 target dir `/tmp/cjgui-minimal-ui-framework-chat-runnable-target`；输出仍可能包含仓库既有 unused / large stack-frame warnings，未阻断构建。
- Public declaration scan：本轮新增 `CjguiExperimentalChatDemoOutput` 与 `cjguiExperimentalBuildChatDemoOutput(...)`；没有新增 `xxxReady(): Bool` public API，也没有新增 public C ABI。
- Protected path scan：`runtime/cjgui/src/runtime_state.cj` 仍为 `10065` 行；`runtime_state.cj`、`runtime/cjgui/cjpm.toml`、production native bridge 与 smoke native files 本轮没有 diff。
- Forbidden scan：Chat / Todo / Settings demo source 未命中 `foreign func`、native bridge call、AppKit / Metal / drawable / command buffer / encoder / draw / render execution；demo 输出中没有 governance stop-line false 字段。
- Markdown absolute link check：项目 docs / README 范围未发现 missing target。
- Reachability：README、tracker、plans README、runtime README、DESIGN_INTENT_INDEX 与 demo progress 均能检索到 Chat `runnable` 或本 report 指针。
- CodeLattice：public API change workflow 标记 public API 变更需要源码与测试兜底；external API / breaking-change review 是 static-only，未执行代码，新增 symbol 在 stale graph 中仍需要 focused verifier / build 证明。
- GitNexus impact：`CjguiExperimentalChatDemoOutput` 与 `cjguiExperimentalBuildChatDemoOutput` 对旧图谱返回 not found / `UNKNOWN`，符合新增 demo artifact 未索引；按 focused verifier、build 与源码扫描兜底。
- GitNexus `detect-changes --repo cangjie-live-codelattice --scope unstaged`：若图谱未覆盖新增未跟踪 demo/API/script artifacts，则按 verifier、build 与 scan 兜底。

## Next route

下一步优先路线：`P1 CJGUI FileBrowser runnable demo first slice`。

Todo、Settings 与 Chat 现在都达到 `runnable`。后续应开始 FileBrowser / AI-generated UI 的独立 demo，或在现有 demo 上继续做更真实的 validation / rollback / accept-refresh readback；不要再用 owner/readiness/manager/surface/envelope 包装替代 demo 行为。

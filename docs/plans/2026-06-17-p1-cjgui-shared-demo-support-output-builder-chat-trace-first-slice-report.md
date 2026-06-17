# P1 CJGUI shared demo support output builder 与 Chat trace 阶段报告

日期：2026-06-17

## 本轮完成目标

- 目标 1 已完成：Chat 现在真实 import `cjgui.demo_support.{CjguiExperimentalDemoInteractionTrace}`，并把 type / send / reply / focus move 写入 shared trace。Todo、Settings、Chat 三个已有 demo 都消费同一个 shared interaction trace。
- 目标 2 已完成：新增 [runtime_cjgui_experimental_demo_output_builder.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/demo_support/runtime_cjgui_experimental_demo_output_builder.cj)，提供 `CjguiExperimentalDemoOutput` 与 `CjguiExperimentalDemoOutputBuilder`；Todo 与 Settings 已直接迁移到 shared output builder，不再直接调用旧 `cjguiExperimentalBuildTodoDemoOutput` / `cjguiExperimentalBuildSettingsDemoOutput`。
- 目标 3 未执行：本轮没有抽 `DemoStateCore`，因为目标 1 + 2 已经满足本轮成功标准；下一步可在真实复用形状清楚后推进 state core，避免写空抽象。

## 白名单证据

- 白名单 1：shared 模块被三个 demo 真实 import / call。Todo、Settings、Chat 均 import `cjgui.demo_support`，并调用 `CjguiExperimentalDemoInteractionTrace` / `recordAction(...)`。
- 白名单 2：重复 DemoOutput API 开始收敛。Todo 与 Settings 现在直接调用 `CjguiExperimentalDemoOutputBuilder().buildFromTrace(...)`，focused verifier 回显 `todo_legacy_output_api_direct_consumption=false` 与 `settings_legacy_output_api_direct_consumption=false`。
- 白名单 3：shared output builder 承载真实值模型：`demoName`、`beforeState`、`afterState`、`actionTrace`、`writeCount`、`domainSummary`、`readbackOk` 与 `summary`，不是 `Ready(): Bool`、marker 或 report-only wrapper。
- 白名单 4：Chat 的 shared trace 复用让 Todo / Settings / Chat 三个 demo 的 before / after / action trace 逻辑进入同一 support 子包，而不是继续复制 per-demo trace 拼接。

## Shared API 前进点

新增 experimental shared support API：

```text
public class CjguiExperimentalDemoOutput
public class CjguiExperimentalDemoOutputBuilder
public func buildFromTrace(trace: CjguiExperimentalDemoInteractionTrace, domainSummary: String, readbackOk: Bool): CjguiExperimentalDemoOutput
```

稳定性级别仍是 `experimental_demo_support`。它不新增 public C ABI，不调用 native bridge，不写 `runtime_state.cj` / renderer state，也不声明 production renderer truth。

## Demo 迁移结果

Todo 现在用 shared builder 输出：

```text
cjgui todo demo app: public_api_name=CjguiExperimentalDemoOutputBuilder
cjgui todo demo app: public_api_output=demo=todo;readback=true;writes=2;actions=todo.add,todo.complete;before=items=0;first=<none>;first_done=false;after=items=1;first=Write first CJGUI todo;first_done=true;summary=items=1;first=Write first CJGUI todo;first_done=true
```

Settings 现在用 shared builder 输出：

```text
cjgui settings demo app: public_api_name=CjguiExperimentalDemoOutputBuilder
cjgui settings demo app: public_api_output=demo=settings;readback=true;writes=4;actions=settings.toggle_auto_save,settings.select_theme,settings.update_username,settings.move_focus;before=autosave=false;theme=light;username=owner;focus=username_field;after=autosave=true;theme=dark;username=owner-updated;focus=theme_select;summary=demo=settings;layout=sectioned_form;controls=toggle:auto_save,select:theme,text:username;autosave=true;theme=dark;username=owner-updated;focus=theme_select
```

Chat 现在保留既有 Chat output API，但增加 shared trace 输出：

```text
cjgui chat demo app: shared_support=CjguiExperimentalDemoInteractionTrace
cjgui chat demo app: shared_support_output=demo=chat;writes=4;actions=chat.type_message,chat.send_message,chat.append_reply,chat.move_focus;before=messages=1;last=assistant:Welcome to CJGUI;composer=;focus=composer;after=messages=3;last=assistant:Chat demo received;composer=;focus=message_list
```

## State write / readback

- Write scope：`CjguiExperimentalDemoInteractionTrace.beforeState / afterState / actionTrace / writeCount`、shared output value construction，以及既有 `TodoList.items / nextId`、`SettingsPanelState.autoSaveEnabled / selectedTheme / usernameValue / focusTarget`、`ChatThreadState.messages / composerText / focusTarget / lastSender / lastText`。
- Todo before / after：`items=0;first=<none>;first_done=false` -> `items=1;first=Write first CJGUI todo;first_done=true`。
- Settings before / after：`autosave=false;theme=light;username=owner;focus=username_field` -> `autosave=true;theme=dark;username=owner-updated;focus=theme_select`。
- Chat before / after：`messages=1;last=assistant:Welcome to CJGUI;composer=;focus=composer` -> `messages=3;last=assistant:Chat demo received;composer=;focus=message_list`。
- Rollback / not-published boundary：shared trace 与 shared output 都是 demo process-local value facts；没有持久化、没有 runtime state publication、没有 renderer state write。

## 修改文件

- [runtime_cjgui_experimental_demo_output_builder.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/demo_support/runtime_cjgui_experimental_demo_output_builder.cj)
- [todo_app.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/demo/todo_app.cj)
- [settings_app.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/demo/settings_app.cj)
- [chat_app.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/demo/chat_app.cj)
- [verify_cjgui_todo_demo_app.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_cjgui_todo_demo_app.sh)
- [verify_cjgui_settings_demo_app.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_cjgui_settings_demo_app.sh)
- [verify_cjgui_chat_demo_app.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_cjgui_chat_demo_app.sh)
- [CJGUI_DEMO_PROGRESS.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/CJGUI_DEMO_PROGRESS.md)
- [README.md](/Users/jiangxuanyang/Desktop/cangjie/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)
- [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)
- [DESIGN_INTENT_INDEX.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/DESIGN_INTENT_INDEX.md)
- [本报告](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-06-17-p1-cjgui-shared-demo-support-output-builder-chat-trace-first-slice-report.md)

## 验证结果

- Focused Todo verifier：通过。输出 `todo_public_api_name=CjguiExperimentalDemoOutputBuilder`、`todo_public_api_return=CjguiExperimentalDemoOutput`、`todo_legacy_output_api_direct_consumption=false` 与 `todo_shared_support_imported=true`。
- Focused Settings verifier：通过。输出 `settings_public_api_name=CjguiExperimentalDemoOutputBuilder`、`settings_public_api_return=CjguiExperimentalDemoOutput`、`settings_legacy_output_api_direct_consumption=false` 与 `settings_shared_support_imported=true`。
- Focused Chat verifier：通过。输出 `chat_shared_support_imported=true` 与 `chat_shared_support_name=CjguiExperimentalDemoInteractionTrace`。
- Full build：通过。`cjpm build --target-dir /tmp/cjgui-shared-demo-output-builder-target --skip-script` 成功；保留既有 unused / stack-frame warning，未引入本轮编译错误。
- CodeLattice after-edit：完成。`native_review`、`docs_tests`、`config_examples` 三个静态 action 完成，风险 `medium`，并明确 `staticOnly=true` / `runtimeProof=false`；本轮以 focused verifier、full build 与 scans 提供 runtime 兜底。
- GitNexus detect-changes：完成。`detect-changes --repo cangjie-live-codelattice --scope unstaged` 返回 `Changes: 12 files, 2 symbols`、`Affected processes: 0`、`Risk level: low`；changed symbol 仍只识别到 Markdown 标题，按仓库规则视为辅助 evidence 而非完整安全证明。
- `git diff --check`：通过。
- Markdown absolute link check：通过。项目 docs / README 范围扫描 `2017` 个 Markdown 文件、`18823` 个项目绝对链接，missing target 为 `0`。
- Reachability：通过。README、tracker、plans README、runtime README、DESIGN_INTENT_INDEX、CJGUI_DEMO_PROGRESS 与本报告均可检索到 shared output builder、legacy output API 直连关闭证据和 next route。
- Protected path scan：通过。`runtime/cjgui/src/runtime_state.cj` 仍为 `10065` 行；`runtime_state.cj`、`runtime/cjgui/cjpm.toml`、production native bridge 与 smoke native paths 均无 diff。
- Public / forbidden scan：通过。新增 public declaration 仅在 `demo_support` experimental support API 内；changed demo / support 中没有 `Ready(): Bool`、`foreign func`、native bridge call、AppKit / Metal token 或 public C ABI；Todo / Settings 中未检出旧 output API 直接消费。

## 边界

- 本轮新增的是 experimental Cangjie shared support API，不是 public C ABI。
- 本轮没有新增 `Ready(): Bool`，没有 native bridge call，没有 `foreign func`，没有 renderer backend truth。
- Todo / Settings 的旧 per-demo output API 文件可以暂时作为 compatibility artifact 留存，但两个 demo 已不再直接消费它们；白名单只认 shared builder consumption。
- Chat 本轮只完成 shared trace 复用，尚未迁移到 shared output builder。

## 后续路线

下一步建议：`P1 CJGUI shared demo state core first slice`。

当前 shared trace + shared output builder 已经提供真实复用支点。后续如果抽 `DemoStateCore`，必须让至少两个 demo 真实实现 / 调用，并承载 before / after / summary / focus 等实质逻辑；不要写空接口或新的 readiness wrapper。

# P1 CJGUI shared demo support interaction trace first slice 阶段报告

日期：2026-06-17

## 本轮白名单证据

- 本轮白名单证据：新增 shared 模块 [runtime_cjgui_experimental_demo_interaction_trace.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/demo_support/runtime_cjgui_experimental_demo_interaction_trace.cj)，并让 Todo 与 Settings 两个已有独立 demo 真实 import `cjgui.demo_support.{CjguiExperimentalDemoInteractionTrace}` 后调用同一个 `CjguiExperimentalDemoInteractionTrace`。
- 哪个 shared / demo / API 前进：Todo 与 Settings 从“各自只维护 per-demo 状态追踪”前进到“共同消费同一 shared interaction trace support”；`CjguiExperimentalDemoInteractionTrace` 是非 Bool experimental shared support API，不是 readiness。
- 复用证据：[todo_app.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/demo/todo_app.cj) 与 [settings_app.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/demo/settings_app.cj) 均具名 import `cjgui.demo_support.{CjguiExperimentalDemoInteractionTrace}`，并出现 `sharedTrace.recordAction(...)`；两个 focused verifier 均按真实 `src/demo_support` 子包布局复制 shared support source 后编译运行，并回显 `*_shared_support_imported=true`。
- demo before→after：Todo shared trace 输出 `before=items=0;first=<none>;first_done=false` 到 `after=items=1;first=Write first CJGUI todo;first_done=true`；Settings shared trace 输出 `before=autosave=false;theme=light;username=owner;focus=username_field` 到 `after=autosave=true;theme=dark;username=owner-updated;focus=theme_select`。
- 哪些只是辅助验证：CodeLattice / GitNexus、public / protected / forbidden scans、Markdown link / reachability 与 full `cjpm build` 都是辅助验证，不替代 shared 代码被两个 demo 编译运行消费的事实。
- 验证结果：Todo / Settings focused verifier 已通过；full `cjpm build --skip-script`、public/protected/forbidden scans、Markdown / reachability、CodeLattice after-edit、GitNexus detect-changes 与 `git diff --check` 在最终验证段记录。
- next route：`P1 CJGUI shared demo support action model extraction first slice`，继续把重复的 action / state / before-after 追踪从孤立 demo 中抽到 shared 支持，而不是新增同构孤岛 demo。
- 本轮将提交/已提交的文件范围：shared demo support module、Todo / Settings demo 改造、Todo / Settings focused verifier 更新、CJGUI_DEMO_PROGRESS、README / tracker / plans README / runtime README / DESIGN_INTENT_INDEX 同步，以及本报告。

## Shared 复用切片

本轮新增 `CjguiExperimentalDemoInteractionTrace`，作为两个已有 demo 共享的 process-local interaction trace core。它保存 demo name、before state、after state、action trace 与 write count，并提供 `recordAction(...)`、`before()`、`after()`、`actions()`、`writes()` 与 `summary()`。

这不是新的 demo app，也不是 renderer truth。它的价值是让已有 demo 开始出现真实代码联系：Todo 和 Settings 不再各自只在本地拼接 action / before-after trace，而是复用同一个 shared support class。

## Demo 业务输出

Todo focused verifier 运行后要求并观察：

```text
cjgui todo demo app: shared_support=CjguiExperimentalDemoInteractionTrace
cjgui todo demo app: shared_support_output=demo=todo;writes=2;actions=todo.add,todo.complete;before=items=0;first=<none>;first_done=false;after=items=1;first=Write first CJGUI todo;first_done=true
```

Settings focused verifier 运行后要求并观察：

```text
cjgui settings demo app: shared_support=CjguiExperimentalDemoInteractionTrace
cjgui settings demo app: shared_support_output=demo=settings;writes=4;actions=settings.toggle_auto_save,settings.select_theme,settings.update_username,settings.move_focus;before=autosave=false;theme=light;username=owner;focus=username_field;after=autosave=true;theme=dark;username=owner-updated;focus=theme_select
```

这些输出是业务 before / after、shared support consumption 与 state readback，不包含 `runtime_state_write=false`、`renderer_state_write=false` 或 `public_c_abi_added=false` 这类治理字段。

## Public API 证据

新增 shared support API：

```text
public class CjguiExperimentalDemoInteractionTrace
public init(demoName: String, beforeState: String)
public func recordAction(action: String, afterState: String)
public func before(): String
public func after(): String
public func actions(): String
public func writes(): Int64
public func summary(): String
```

稳定性级别：`experimental_demo_support`。

非 Bool 证据：`CjguiExperimentalDemoInteractionTrace` 是领域类，保存并返回 demo name、action trace、write count、before / after state 与 summary。它不是 `Ready(): Bool`，不调用 internal readiness draft，不写 `runtime_state.cj` / renderer state，也不扩 public C ABI。

Demo proof：

- Todo 调用 `CjguiExperimentalDemoInteractionTrace("todo", before)`，并在 add / complete 后调用 `sharedTrace.recordAction(...)`。
- Settings 调用 `CjguiExperimentalDemoInteractionTrace("settings", before)`，并在 toggle / select / update / focus move 后调用 `sharedTrace.recordAction(...)`。

## State write / readback

- Write scope：`CjguiExperimentalDemoInteractionTrace.beforeState`、`afterState`、`actionTrace`、`writeCount`，以及既有 `TodoList.items / nextId`、`SettingsPanelState.autoSaveEnabled / selectedTheme / usernameValue / focusTarget`。
- Todo before / after：`items=0;first=<none>;first_done=false` -> `items=1;first=Write first CJGUI todo;first_done=true`。
- Settings before / after：`autosave=false;theme=light;username=owner;focus=username_field` -> `autosave=true;theme=dark;username=owner-updated;focus=theme_select`。
- Readback：Todo verifier 要求 `todo_shared_support_imported=true`；Settings verifier 要求 `settings_shared_support_imported=true`。Demo 内部同时检查 shared trace 的 before、after、actions 与 writes。
- Rollback / not-published boundary：shared trace 只存在于 demo process-local in-memory class；进程退出即回收，没有持久化、没有 publication、没有 shared runtime state。

## 修改文件

- [runtime_cjgui_experimental_demo_interaction_trace.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/demo_support/runtime_cjgui_experimental_demo_interaction_trace.cj)
- [todo_app.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/demo/todo_app.cj)
- [settings_app.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/demo/settings_app.cj)
- [verify_cjgui_todo_demo_app.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_cjgui_todo_demo_app.sh)
- [verify_cjgui_settings_demo_app.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_cjgui_settings_demo_app.sh)
- [CJGUI_DEMO_PROGRESS.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/CJGUI_DEMO_PROGRESS.md)
- [README.md](/Users/jiangxuanyang/Desktop/cangjie/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)
- [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)
- [DESIGN_INTENT_INDEX.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/DESIGN_INTENT_INDEX.md)
- [本报告](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-06-17-p1-cjgui-shared-demo-support-interaction-trace-first-slice-report.md)

## 验证结果

- Focused Todo verifier：通过。`runtime/cjgui/native/scripts/verify_cjgui_todo_demo_app.sh` 输出 `todo_shared_support_imported=true` 与 `todo_shared_support_name=CjguiExperimentalDemoInteractionTrace`。
- Focused Settings verifier：通过。`runtime/cjgui/native/scripts/verify_cjgui_settings_demo_app.sh` 输出 `settings_shared_support_imported=true` 与 `settings_shared_support_name=CjguiExperimentalDemoInteractionTrace`。
- CodeLattice pre-edit：`public_api_change` static-only 辅助检查完成，提示 public API change 需要 targeted verification 兜底；本轮用 focused verifier、build 与 scans 兜底。
- GitNexus impact pre-edit：`CjguiExperimentalDemoInteractionTrace` 返回 `UNKNOWN / target not found`，按仓库规则记录为新符号图谱非覆盖，不作为安全证明。
- Full build：通过。`cjpm build --target-dir /tmp/cjgui-shared-demo-support-interaction-trace-target --skip-script` 成功；第一次裸环境需要 source Cangjie toolchain，真实包布局修正为 `package cjgui.demo_support` 后构建通过。
- `git diff --check`：通过。
- Protected path scan：通过。`runtime/cjgui/src/runtime_state.cj` 仍为 `10065` 行；`runtime_state.cj`、`runtime/cjgui/cjpm.toml`、production native bridge 与 smoke native paths 均无 diff。
- Public / forbidden scan：通过。新增 public declaration 仅为 `public class CjguiExperimentalDemoInteractionTrace`；changed demo / support 中没有 `Ready(): Bool`、`foreign func`、native bridge call 或 public C ABI；governance stop-line 字段只在 verifier / report 出现，不进入 demo business output。
- Markdown / reachability：通过。项目 docs / README 范围内扫描 `4990` 个 Markdown 文件、`18867` 个项目绝对链接，missing target 为 `0`；README、tracker、plans README、runtime README、DESIGN_INTENT_INDEX、CJGUI_DEMO_PROGRESS 与本报告均能检索到 `CjguiExperimentalDemoInteractionTrace`、`todo_shared_support_imported=true` / `settings_shared_support_imported=true` 与下一路线。
- CodeLattice after-edit：完成。`native_review`、`docs_tests`、`config_examples` 三个静态 action 完成，风险 `medium`，并明确 `staticOnly=true` / `runtimeProof=false`；本轮以 focused verifier、full build 与 scans 提供 runtime 兜底。
- GitNexus detect-changes：完成。`detect-changes --repo cangjie-live-codelattice --scope unstaged` 返回 tracked changes `10 files`、`2 symbols`、affected processes `0`、risk `low`；新 shared support 符号图谱覆盖不足，按仓库规则记录为辅助 evidence 而非安全证明。

## 后续路线

下一步优先路线：`P1 CJGUI shared demo support action model extraction first slice`。

当前 shared trace 已经让两个 demo 产生真实代码联系。后续应继续抽取 action model、input/focus/layout/style state core 或 reusable component behavior trait，让更多既有 demo 复用同一 shared support；不要再用同构孤岛 demo 替代框架能力净增长。

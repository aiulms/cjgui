# P1 CJGUI shared demo harness multi-demo integration first slice 阶段报告

日期：2026-06-17

## 本轮白名单证据

- 本轮白名单证据：Shared multi-demo harness 独立 demo 从 `not_started` 前进到 `runnable`，同一 demo 运行 Todo 与 FileBrowser 两条业务流，并新增可编译运行的 demo app、非 Bool public API 与 focused verifier。
- 哪个 demo/API/state 前进：新增 [shared_multi_demo_harness_app.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/demo/shared_multi_demo_harness_app.cj)、[runtime_cjgui_experimental_shared_multi_demo_harness_api.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_cjgui_experimental_shared_multi_demo_harness_api.cj) 与 [verify_cjgui_shared_multi_demo_harness_app.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_cjgui_shared_multi_demo_harness_app.sh)；shared multi-demo harness first slice 直接服务 `served_demos=todo,file_browser`。
- demo before→after：Shared multi-demo harness 输出 `state_before=todo_items=0;todo_first=<none>;todo_done=false;file_selected=/workspace:folder;file_filter=;focus=todo_input;style=neutral_list` 与 `state_after=todo_items=1;todo_first=Write shared multi-demo harness;todo_done=true;file_selected=/workspace/src/main.cj:file;file_filter=main;focus=file_detail_pane;style=split_detail_accent`。
- 哪些只是辅助验证：CodeLattice / GitNexus、public / protected / forbidden scans、Markdown link / reachability 与 full `cjpm build` 都是辅助验证，不替代 demo 业务输出。
- 验证结果：shared multi-demo harness focused verifier、既有 demo verifier regression、`cjpm build --skip-script`、public/protected/forbidden scans、Markdown / reachability / 中文抽查与 `git diff --check` 均已通过。
- next route：`P1 CJGUI shared demo harness layout/style/input/focus contract first slice`，把本轮已经出现的 `focusRoute` / `styleRoute` 从单个 demo 汇总字段推进为可复用 demo runtime contract。
- 本轮将提交/已提交的文件范围：shared multi-demo harness demo/API/verifier，demo progress、README / tracker / plans index / runtime README / DESIGN_INTENT_INDEX 同步，以及本报告。

## Demo 业务输出

Shared multi-demo harness first slice 现在不是复制单 demo verifier，而是在同一 demo-host process 内服务 Todo 与 FileBrowser 两条真实业务流。

```text
cjgui shared multi-demo harness app: demo=shared_multi_demo_harness
cjgui shared multi-demo harness app: status_before=not_started
cjgui shared multi-demo harness app: status_after=runnable
cjgui shared multi-demo harness app: served_demos=todo,file_browser
cjgui shared multi-demo harness app: served_demo_count=2
cjgui shared multi-demo harness app: interaction=run_todo_add_complete,run_file_browser_select
cjgui shared multi-demo harness app: state_before=todo_items=0;todo_first=<none>;todo_done=false;file_selected=/workspace:folder;file_filter=;focus=todo_input;style=neutral_list
cjgui shared multi-demo harness app: state_after=todo_items=1;todo_first=Write shared multi-demo harness;todo_done=true;file_selected=/workspace/src/main.cj:file;file_filter=main;focus=file_detail_pane;style=split_detail_accent
cjgui shared multi-demo harness app: state_readback=true
cjgui shared multi-demo harness app: public_api_consumed=true
cjgui shared multi-demo harness app: public_api_name=cjguiExperimentalBuildSharedMultiDemoHarnessOutput
cjgui shared multi-demo harness app: public_api_output=harness=shared_multi_demo_harness;served_count=2;served=todo,file_browser;actions=6;before=todo_items=0;todo_first=<none>;todo_done=false;file_selected=/workspace:folder;file_filter=;focus=todo_input;style=neutral_list;after=todo_items=1;todo_first=Write shared multi-demo harness;todo_done=true;file_selected=/workspace/src/main.cj:file;file_filter=main;focus=file_detail_pane;style=split_detail_accent;interaction=todo_add,todo_complete,file_expand,file_filter,file_select,file_focus;focus_route=todo_input->todo_first_item->todo_first_item->file_tree->file_filter->file_detail_pane->file_detail_pane;style_route=neutral_list->todo_active_list->todo_completed_accent->split_detail_accent;readback=true
```

`runtime_state_write=false`、`renderer_state_write=false`、`public_c_abi_added=false` 等 stop-line 不由 demo 输出；它们只在 verifier / report 的验证段记录。

## Public API 证据

新增 API：

```text
public class CjguiExperimentalSharedMultiDemoHarnessOutput
public func cjguiExperimentalBuildSharedMultiDemoHarnessOutput(
    servedDemoCount: Int64,
    servedDemos: String,
    actionCount: Int64,
    beforeState: String,
    afterState: String,
    interactionTrace: String,
    focusRoute: String,
    styleRoute: String,
    readbackOk: Bool
): CjguiExperimentalSharedMultiDemoHarnessOutput
```

稳定性级别：`experimental_demo`。

非 Bool 证据：返回类型是 `CjguiExperimentalSharedMultiDemoHarnessOutput`，包含 `harnessName`、`servedDemoCount`、`servedDemos`、`actionCount`、`beforeState`、`afterState`、`interactionTrace`、`focusRoute`、`styleRoute`、`readbackOk` 与 `summary`。它不调用 internal readiness draft，不返回 Bool readiness，不写 `runtime_state.cj` / renderer state，也不扩 public C ABI。

Demo proof：`SharedMultiDemoHarnessState.buildHarnessOutput()` 调用该 API，并在 demo main 中校验 output fields 与 `summary`。

## State write / readback

- Write scope：`SharedMultiDemoHarnessState.todoItemCount`、`todoFirstTitle`、`todoFirstDone`、`fileExpandedPath`、`fileSelectedPath`、`fileSelectedKind`、`fileDetailTitle`、`fileFilterText`、`focusTarget`、`styleToken`、`interactionTrace`、`focusRoute`、`styleRoute`。
- Before：`todo_items=0;todo_first=<none>;todo_done=false;file_selected=/workspace:folder;file_filter=;focus=todo_input;style=neutral_list`。
- Actions：`runTodoAddComplete("Write shared multi-demo harness")` 执行 `todo_add` / `todo_complete`；`runFileBrowserSelect("main", "/workspace/src/main.cj", "main.cj")` 执行 `file_expand` / `file_filter` / `file_select` / `file_focus`。
- After：`todo_items=1;todo_first=Write shared multi-demo harness;todo_done=true;file_selected=/workspace/src/main.cj:file;file_filter=main;focus=file_detail_pane;style=split_detail_accent`。
- Readback：demo 用 `businessState()`、`servedDemoCount`、`servedDemos`、`actionCount`、`interactionTrace` 与 `CjguiExperimentalSharedMultiDemoHarnessOutput.summary` 校验写入结果。
- Rollback / not-published boundary：本轮状态只存在于 demo process-local in-memory class；进程退出即回收，没有持久化、没有 publication、没有 shared runtime state。

## 修改文件

- [shared_multi_demo_harness_app.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/demo/shared_multi_demo_harness_app.cj)
- [runtime_cjgui_experimental_shared_multi_demo_harness_api.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_cjgui_experimental_shared_multi_demo_harness_api.cj)
- [verify_cjgui_shared_multi_demo_harness_app.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_cjgui_shared_multi_demo_harness_app.sh)
- [CJGUI_DEMO_PROGRESS.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/CJGUI_DEMO_PROGRESS.md)
- [README.md](/Users/jiangxuanyang/Desktop/cangjie/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)
- [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)
- [DESIGN_INTENT_INDEX.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/DESIGN_INTENT_INDEX.md)
- [shared multi-demo harness report](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-06-17-p1-cjgui-shared-demo-harness-multi-demo-integration-first-slice-report.md)

## 验证结果

- Focused shared multi-demo harness verification：通过。`runtime/cjgui/native/scripts/verify_cjgui_shared_multi_demo_harness_app.sh` 输出 `cjgui_shared_multi_demo_harness_app_compiled=true`、`cjgui_shared_multi_demo_harness_app_ran=true`、`shared_multi_demo_harness_progress_before=not_started`、`shared_multi_demo_harness_progress_after=runnable`、`shared_multi_demo_harness_served_demos=todo,file_browser`、`shared_multi_demo_harness_non_bool_public_api_consumed=true`、`shared_multi_demo_harness_owner_local_write_readback=true`。
- Existing demo verifier regression：通过。Shared harness / Todo / Settings / Chat / FileBrowser / AI-generated UI focused verifier 均保持 `*_demo_app_compiled=true`、`*_demo_app_ran=true`、`*_non_bool_public_api_consumed=true` 与 owner-local write/readback 证据。
- `cjpm build --skip-script`：通过。`runtime/cjgui` 在 `/tmp/cjgui-shared-multi-demo-harness-target` 完成 build；输出仍包含既有 unused / stack-frame warning，但没有新增阻塞错误。
- Public declaration scan：通过。本轮新增 `CjguiExperimentalSharedMultiDemoHarnessOutput` 与 `cjguiExperimentalBuildSharedMultiDemoHarnessOutput(...)` 两个 shared multi-demo harness demo public declaration；返回值为非 Bool demo output。仓库仍有 3 个既有 `Ready(): Bool` public declaration，本轮没有新增 readiness Bool API。
- Protected path scan：通过。`runtime/cjgui/src/runtime_state.cj` 仍为 `10065` 行；`runtime_state.cj`、`runtime/cjgui/cjpm.toml`、production native bridge 与 smoke native path 均无 diff。
- Forbidden scan：通过。新增 demo/API 没有 `foreign func`、native bridge call、AppKit / Metal / drawable / command buffer / render / present / pointer surface；demo app 没有输出 governance stop-line fields。
- `git diff --check`：通过。
- Markdown / reachability / 中文正文检查：通过。项目 docs / README 范围内检查 `2012` 个 Markdown 文件、`18733` 个 absolute links，missing target 为 `0`；`README.md`、`GUI_TASK_TRACKER.md`、`docs/plans/README.md`、`runtime/cjgui/README.md`、`DESIGN_INTENT_INDEX.md`、`CJGUI_DEMO_PROGRESS.md` 与本报告均可达 Shared multi-demo harness runnable、new API 与 next route；本报告 / 进度看板主标题和正文抽查均为中文。
- CodeLattice：辅助检查为 static-only。`breaking_change` 对新增 shared multi-demo harness symbols 报 `unknownCount=2`、`staleReason=file_added`、compatibility risk `medium`，说明新符号尚未入图；本轮以源码阅读、focused verifier、full build、public/protected/forbidden scan 兜底。
- GitNexus：`detect-changes --repo cangjie-live-codelattice --scope unstaged` 返回 `risk_level=low`、`affected_count=0`、`changed_files=6`、`changed_symbols=2`；图谱只识别 README 标题级改动，未覆盖新增 untracked demo/API/verifier，按源码和 focused verification 兜底。

## 后续路线

下一步优先路线：`P1 CJGUI shared demo harness layout/style/input/focus contract first slice`。

Shared multi-demo harness 已服务两个真实业务 demo 场景 `todo,file_browser`。后续应把 `focusRoute`、`styleRoute`、layout token、input intent 与 text/focus result 从当前输出字段推进为可复用 demo runtime contract，并逐步接入 AI-generated UI accept refresh；不要回到 owner/readiness/manager/surface/envelope 包装替代 demo 行为。

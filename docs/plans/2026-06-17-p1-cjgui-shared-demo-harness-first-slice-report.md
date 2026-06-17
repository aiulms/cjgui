# P1 CJGUI shared demo harness first slice 阶段报告

日期：2026-06-17

## 本轮白名单证据

- 本轮白名单证据：Shared demo harness 独立 demo 从 `not_started` 前进到 `runnable`，并新增可编译运行的 demo app、非 Bool public API 与 focused verifier。
- 哪个 demo/API/state 前进：新增 [shared_demo_harness_app.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/demo/shared_demo_harness_app.cj)、[runtime_cjgui_experimental_shared_demo_harness_api.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_cjgui_experimental_shared_demo_harness_api.cj) 与 [verify_cjgui_shared_demo_harness_app.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_cjgui_shared_demo_harness_app.sh)；shared harness first slice 直接服务 `served_demo=todo`。
- demo before→after：Shared demo harness 输出 `state_before=items=0;first=<none>;first_done=false;focus=todo_input;style=neutral_list` 与 `state_after=items=1;first=Write shared CJGUI harness;first_done=true;focus=todo_first_item;style=completed_accent`。
- 哪些只是辅助验证：CodeLattice / GitNexus、public / protected / forbidden scans、Markdown link / reachability 与 full `cjpm build` 都是辅助验证，不替代 demo 业务输出。
- 验证结果：shared harness focused verifier、Todo / Settings / Chat / FileBrowser / AI-generated UI focused verifier、`cjpm build --skip-script`、public/protected/forbidden scans 与 `git diff --check` 均已通过。
- next route：`P1 CJGUI shared demo harness multi-demo integration first slice`，把 FileBrowser / AI-generated UI 等既有 runnable demo 接入同一 shared harness，减少同构 verifier / demo glue。
- 本轮将提交/已提交的文件范围：shared harness demo/API/verifier，demo progress、README / tracker / plans index / runtime README / DESIGN_INTENT_INDEX 同步，以及本报告。

## Demo 业务输出

Shared demo harness first slice 现在像一个真实 demo runner：它服务 Todo add / complete 业务流，并输出业务状态读回，而不是 stop-line 报告。

```text
cjgui shared demo harness app: demo=shared_demo_harness
cjgui shared demo harness app: status_before=not_started
cjgui shared demo harness app: status_after=runnable
cjgui shared demo harness app: served_demo=todo
cjgui shared demo harness app: interaction=run_todo_add_complete
cjgui shared demo harness app: state_before=items=0;first=<none>;first_done=false;focus=todo_input;style=neutral_list
cjgui shared demo harness app: state_after=items=1;first=Write shared CJGUI harness;first_done=true;focus=todo_first_item;style=completed_accent
cjgui shared demo harness app: state_readback=true
cjgui shared demo harness app: public_api_consumed=true
cjgui shared demo harness app: public_api_name=cjguiExperimentalBuildSharedDemoHarnessOutput
cjgui shared demo harness app: public_api_output=harness=shared_demo_harness;served=todo;actions=2;before=items=0;first=<none>;first_done=false;focus=todo_input;style=neutral_list;after=items=1;first=Write shared CJGUI harness;first_done=true;focus=todo_first_item;style=completed_accent;interaction=add_todo,complete_todo;focus=todo_first_item;style=completed_accent;readback=true
```

`runtime_state_write=false`、`renderer_state_write=false`、`public_c_abi_added=false` 等 stop-line 不由 demo 输出；它们只在 verifier / report 的验证段记录。

## Public API 证据

新增 API：

```text
public class CjguiExperimentalSharedDemoHarnessOutput
public func cjguiExperimentalBuildSharedDemoHarnessOutput(
    servedDemo: String,
    actionCount: Int64,
    beforeState: String,
    afterState: String,
    interactionTrace: String,
    focusTarget: String,
    styleToken: String,
    readbackOk: Bool
): CjguiExperimentalSharedDemoHarnessOutput
```

稳定性级别：`experimental_demo`。

非 Bool 证据：返回类型是 `CjguiExperimentalSharedDemoHarnessOutput`，包含 `harnessName`、`servedDemo`、`actionCount`、`beforeState`、`afterState`、`interactionTrace`、`focusTarget`、`styleToken`、`readbackOk` 与 `summary`。它不调用 internal readiness draft，不返回 Bool readiness，不写 `runtime_state.cj` / renderer state，也不扩 public C ABI。

Demo proof：`SharedDemoHarnessState.buildHarnessOutput()` 调用该 API，并在 demo main 中校验 output fields 与 `summary`。

## State write / readback

- Write scope：`SharedDemoHarnessState.actions`、`itemCount`、`firstTitle`、`firstDone`、`focusTarget`、`styleToken`、`interactionTrace`。
- Before：`items=0;first=<none>;first_done=false;focus=todo_input;style=neutral_list`。
- Actions：`runTodoAddComplete("Write shared CJGUI harness")` 内执行 `add_todo` 与 `complete_todo` 两个 action，并写入 action list / item state / focus / style。
- After：`items=1;first=Write shared CJGUI harness;first_done=true;focus=todo_first_item;style=completed_accent`。
- Readback：demo 用 `businessState()`、`actionCount()` 与 `CjguiExperimentalSharedDemoHarnessOutput.summary` 校验写入结果。
- Rollback / not-published boundary：本轮状态只存在于 demo process-local in-memory class；进程退出即回收，没有持久化、没有 publication、没有 shared runtime state。

## 修改文件

- [shared_demo_harness_app.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/demo/shared_demo_harness_app.cj)
- [runtime_cjgui_experimental_shared_demo_harness_api.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_cjgui_experimental_shared_demo_harness_api.cj)
- [verify_cjgui_shared_demo_harness_app.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_cjgui_shared_demo_harness_app.sh)
- [CJGUI_DEMO_PROGRESS.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/CJGUI_DEMO_PROGRESS.md)
- [shared demo harness report](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-06-17-p1-cjgui-shared-demo-harness-first-slice-report.md)
- [README.md](/Users/jiangxuanyang/Desktop/cangjie/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)
- [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)
- [DESIGN_INTENT_INDEX.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/DESIGN_INTENT_INDEX.md)

## 验证结果

- Focused shared harness verification：通过。`runtime/cjgui/native/scripts/verify_cjgui_shared_demo_harness_app.sh` 输出 `cjgui_shared_demo_harness_app_compiled=true`、`cjgui_shared_demo_harness_app_ran=true`、`shared_demo_harness_progress_before=not_started`、`shared_demo_harness_progress_after=runnable`、`shared_demo_harness_served_demo=todo`、`shared_demo_harness_non_bool_public_api_consumed=true`、`shared_demo_harness_owner_local_write_readback=true`。
- Existing demo verifier regression：通过。Todo / Settings / Chat / FileBrowser / AI-generated UI focused verifier 均保持 `*_demo_app_compiled=true`、`*_demo_app_ran=true`、`*_non_bool_public_api_consumed=true` 与 owner-local write/readback 证据。
- `cjpm build --skip-script`：通过。`runtime/cjgui` 在 `/tmp/cjgui-shared-demo-harness-first-slice-target` 完成 build；输出仍包含既有 unused / stack-frame warning，但没有新增阻塞错误。
- Public declaration scan：通过。本轮新增 `CjguiExperimentalSharedDemoHarnessOutput` 与 `cjguiExperimentalBuildSharedDemoHarnessOutput(...)` 两个 shared harness demo public declaration；返回值为非 Bool demo output。仓库仍有 3 个既有 `Ready(): Bool` public declaration，本轮没有新增 readiness Bool API。
- Protected path scan：通过。`runtime/cjgui/src/runtime_state.cj` 仍为 `10065` 行；`runtime_state.cj`、`runtime/cjgui/cjpm.toml`、production native bridge 与 smoke native path 均无 diff。
- Forbidden scan：通过。demo app 没有输出 governance stop-line fields；新增 demo/API 没有 `foreign func`、native bridge call、AppKit / Metal / drawable / command buffer / render / present / pointer surface。
- `git diff --check`：通过。
- Markdown / reachability / 中文正文检查：通过。项目 docs / README 范围内检查 `18713` 个 absolute links，missing target 为 `0`；`README.md`、`GUI_TASK_TRACKER.md`、`docs/plans/README.md`、`runtime/cjgui/README.md`、`DESIGN_INTENT_INDEX.md`、`CJGUI_DEMO_PROGRESS.md` 与本报告均可达 Shared demo harness runnable、new API 与 next route；主要 Markdown 均保留中文正文。
- CodeLattice：辅助检查为 static-only。`breaking_change` 对新增 shared harness symbols 报 `unknownCount=2`、`staleReason=file_added`、compatibility risk `medium`，说明新符号尚未入图；本轮以源码阅读、focused verifier、full build、public/protected/forbidden scan 兜底。
- GitNexus：`detect_changes(repo=cangjie-live-codelattice, scope=unstaged)` 返回 `risk_level=low`、`affected_count=0`、`changed_files=6`，但只识别到 README section touched；新增未跟踪 demo/API/verifier 仍以 focused verifier / build / scan 作为主证据。

## 后续路线

下一步优先路线：`P1 CJGUI shared demo harness multi-demo integration first slice`。

Shared harness 已服务第一个真实业务 demo 场景 `todo`。后续应把 FileBrowser / AI-generated UI 接入同一 harness，减少同构 demo verifier 模板，并逐步把 layout / style / text / input / focus interactions 变成可复用的 demo runtime 能力；不要回到 owner/readiness/manager/surface/envelope 包装替代 demo 行为。

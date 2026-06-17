# P1 CJGUI shared demo harness reusable component contract first slice 阶段报告

日期：2026-06-17

## 本轮白名单证据

- 本轮白名单证据：Reusable component contract 独立 demo 从 `not_started` 前进到 `runnable`，同一 demo 运行 register file row、register AI form、Todo add、FileBrowser select、AI accept，并新增可编译运行的 demo app、非 Bool public API 与 focused verifier。
- 哪个 demo/API/state 前进：新增 [reusable_component_contract_app.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/demo/reusable_component_contract_app.cj)、[runtime_cjgui_experimental_reusable_component_contract_api.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_cjgui_experimental_reusable_component_contract_api.cj) 与 [verify_cjgui_reusable_component_contract_app.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_cjgui_reusable_component_contract_app.sh)；该 demo 消费新的 reusable component contract API。
- demo before→after：Reusable component contract 输出 `state_before=components=1;demos=todo;todo=<empty>;file=<none>;ai=<none>;layout=single_column;style=neutral_list;input=<empty>;focus=todo_input` 与 `state_after=components=3;demos=todo,file_browser,ai_generated_ui;todo=buy_milk;file=src/main.cj;ai=settings_profile_form;layout=split_detail;style=sage_panel;input=filter:src,username;focus=save_button`。
- 哪些只是辅助验证：CodeLattice / GitNexus、public / protected / forbidden scans、Markdown link / reachability 与 full `cjpm build` 都是辅助验证，不替代 demo 业务输出。
- 验证结果：Reusable component contract focused verifier、相邻 shared contract / harness 回归、五个独立业务 demo 回归、full `cjpm build --skip-script`、public/protected/forbidden scans、Markdown / reachability、CodeLattice static review、GitNexus detect-changes 与 `git diff --check` 均已完成；详情见验证结果段。
- next route：`P1 CJGUI reusable component event routing first slice`，让 reusable component contract 继续服务点击 / 输入 / focus 的业务事件路由，而不是回到 owner/readiness/manager/surface/envelope 包装。
- 本轮将提交/已提交的文件范围：Reusable component contract demo/API/verifier，demo progress、README / tracker / plans index / runtime README / DESIGN_INTENT_INDEX 同步，以及本报告。

## Demo 业务输出

Reusable component contract first slice 把 Todo、FileBrowser 与 AI-generated UI 的组件形态收敛到同一个 demo-host in-memory contract。它不是 renderer truth，也不是 runtime state truth，而是独立 demo app 的 process-local business state。

```text
cjgui reusable component contract app: demo=reusable_component_contract
cjgui reusable component contract app: status_before=not_started
cjgui reusable component contract app: status_after=runnable
cjgui reusable component contract app: reused_demos=todo,file_browser,ai_generated_ui
cjgui reusable component contract app: component_kinds=task_row,file_row,ai_form
cjgui reusable component contract app: interaction=register_file_row,register_ai_form,todo_add,file_select,ai_accept
cjgui reusable component contract app: state_before=components=1;demos=todo;todo=<empty>;file=<none>;ai=<none>;layout=single_column;style=neutral_list;input=<empty>;focus=todo_input
cjgui reusable component contract app: state_after=components=3;demos=todo,file_browser,ai_generated_ui;todo=buy_milk;file=src/main.cj;ai=settings_profile_form;layout=split_detail;style=sage_panel;input=filter:src,username;focus=save_button
cjgui reusable component contract app: state_readback=true
cjgui reusable component contract app: public_api_consumed=true
cjgui reusable component contract app: public_api_name=cjguiExperimentalBuildReusableComponentContractOutput
cjgui reusable component contract app: public_api_output=contract=reusable_component_contract;components=task_row,file_row,ai_form;reused_count=3;reused=todo,file_browser,ai_generated_ui;component_count=3;before=components=1;demos=todo;todo=<empty>;file=<none>;ai=<none>;layout=single_column;style=neutral_list;input=<empty>;focus=todo_input;after=components=3;demos=todo,file_browser,ai_generated_ui;todo=buy_milk;file=src/main.cj;ai=settings_profile_form;layout=split_detail;style=sage_panel;input=filter:src,username;focus=save_button;actions=register_file_row,register_ai_form,todo_add,file_select,ai_accept;layout=single_column->split_detail;style=neutral_list->sage_panel;input=<empty>->filter:src,username;focus=todo_input->save_button;readback=true
```

`runtime_state_write=false`、`renderer_state_write=false`、`public_c_abi_added=false` 等 stop-line 不由 demo 输出；它们只在 verifier / report 的验证段记录。

## Public API 证据

新增 API：

```text
public class CjguiExperimentalReusableComponentContractOutput
public func cjguiExperimentalBuildReusableComponentContractOutput(
    componentKinds: String,
    reusedDemoCount: Int64,
    reusedDemos: String,
    componentCount: Int64,
    beforeState: String,
    afterState: String,
    actionTrace: String,
    layoutBefore: String,
    layoutAfter: String,
    styleBefore: String,
    styleAfter: String,
    inputBefore: String,
    inputAfter: String,
    focusBefore: String,
    focusAfter: String,
    readbackOk: Bool
): CjguiExperimentalReusableComponentContractOutput
```

稳定性级别：`experimental_demo`。

非 Bool 证据：返回类型是 `CjguiExperimentalReusableComponentContractOutput`，包含 reusable component kinds、reused demos、component count、business before / after、action trace、layout/style/input/focus before / after、readback 与 summary。它不调用 internal readiness draft，不返回 Bool readiness，不写 `runtime_state.cj` / renderer state，也不扩 public C ABI。

Demo proof：`ReusableComponentContractState.buildContractOutput()` 调用该 API；demo 用返回对象字段校验 component kinds、reused demos、state before / after、layout/style/input/focus 与 summary。

## State write / readback

- Write scope：`ReusableComponentContractState.componentCount`、`componentKinds`、`reusedDemoCount`、`reusedDemos`、`actionTrace`、`todoTitle`、`fileSelection`、`aiAcceptedScreen`、`layoutMode`、`styleToken`、`inputText`、`focusTarget`。
- Before：`components=1;demos=todo;todo=<empty>;file=<none>;ai=<none>;layout=single_column;style=neutral_list;input=<empty>;focus=todo_input`。
- Actions：`attachFileBrowserRow()`、`attachAiGeneratedForm()`、`runTodoAdd("buy_milk")`、`runFileSelect("src/main.cj")`、`runAiAccept("settings_profile_form")`。
- After：`components=3;demos=todo,file_browser,ai_generated_ui;todo=buy_milk;file=src/main.cj;ai=settings_profile_form;layout=split_detail;style=sage_panel;input=filter:src,username;focus=save_button`。
- Readback：demo 用 `businessState()`、`componentKinds`、`reusedDemoCount`、`actionTrace` 与 API output 校验写入结果。
- Rollback / not-published boundary：本轮状态只存在于 demo process-local in-memory class；进程退出即回收，没有持久化、没有 publication、没有 shared runtime state。

## 修改文件

- [reusable_component_contract_app.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/demo/reusable_component_contract_app.cj)
- [runtime_cjgui_experimental_reusable_component_contract_api.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_cjgui_experimental_reusable_component_contract_api.cj)
- [verify_cjgui_reusable_component_contract_app.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_cjgui_reusable_component_contract_app.sh)
- [CJGUI_DEMO_PROGRESS.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/CJGUI_DEMO_PROGRESS.md)
- [README.md](/Users/jiangxuanyang/Desktop/cangjie/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)
- [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)
- [DESIGN_INTENT_INDEX.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/DESIGN_INTENT_INDEX.md)
- [Reusable component contract report](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-06-17-p1-cjgui-shared-demo-harness-reusable-component-contract-first-slice-report.md)

## 验证结果

- Focused reusable component contract verification：通过。`runtime/cjgui/native/scripts/verify_cjgui_reusable_component_contract_app.sh` 输出 `cjgui_reusable_component_contract_app_compiled=true`、`cjgui_reusable_component_contract_app_ran=true`、`reusable_component_contract_progress_before=not_started`、`reusable_component_contract_progress_after=runnable`、`reusable_component_contract_non_bool_public_api_consumed=true` 与 `reusable_component_contract_owner_local_write_readback=true`。
- CodeLattice pre-edit：完成 `public_api_change` static-only 辅助检查，返回 `riskLevel=high` / `safeToProceed=unknown`；这是 public API 变更的静态风险提醒，不是 blocker，也不是 runtime proof。后续用 focused verifier、build 与 scan 验证。
- GitNexus impact pre-edit：`cjguiExperimentalBuildReusableComponentContractOutput` 返回 `UNKNOWN / target not found`，按仓库规则记录为新符号图谱非覆盖，不作为安全证明；后续用源码、focused verifier、build 与 scan 兜底。
- Regression verifiers：通过。已回归 `verify_cjgui_ai_generated_ui_shared_contract_app.sh`、`verify_cjgui_shared_multi_demo_harness_app.sh`、`verify_cjgui_shared_layout_style_input_focus_contract_app.sh`、`verify_cjgui_todo_demo_app.sh`、`verify_cjgui_settings_demo_app.sh`、`verify_cjgui_chat_demo_app.sh`、`verify_cjgui_file_browser_demo_app.sh`、`verify_cjgui_ai_generated_ui_demo_app.sh` 与 `verify_cjgui_shared_demo_harness_app.sh`，确认既有 runnable demo 仍可编译运行。
- Full build：通过。`source /Users/jiangxuanyang/cangjie-toolchains/cangjie/envsetup.sh && cjpm build --target-dir /tmp/cjgui-reusable-component-contract-target --skip-script` 在 [runtime/cjgui](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui) 下完成，最终输出 `cjpm build success`。首次 sandbox 内运行被 `envsetup.sh` 的 `ps` 访问限制挡住，随后按权限规则提权重跑；build warning 为仓库既有 unused / stack frame warning。
- `git diff --check`：通过。
- Protected path scan：`runtime/cjgui/src/runtime_state.cj` 仍为 `10065` 行；`runtime_state.cj`、`runtime/cjgui/cjpm.toml`、production native bridge 与 `labs/macos_bridge_smoke` 没有 diff。
- Public / forbidden scan：本轮新增 API 仅包含 `public class CjguiExperimentalReusableComponentContractOutput` 与 `public func cjguiExperimentalBuildReusableComponentContractOutput(...)`；未新增 `Ready(): Bool` public API，未新增 `foreign func`，未新增 `cjgui_native_bridge_` 调用。Demo source 不输出 `runtime_state_write=false`、`renderer_state_write=false`、`visibility_published=false` 或 `public_c_abi_added=false`；这些治理字段只在 verifier / report 中出现。
- Markdown / reachability：项目 docs / README 范围内检查 `2014` 个 Markdown 文件、`17205` 个项目绝对链接，missing target 为 `0`；README、tracker、plans README、runtime README、DESIGN_INTENT_INDEX、CJGUI_DEMO_PROGRESS 与本 report 均能检索到 reusable component contract、非 Bool API 与 next route。
- 中文标题正文抽查：本 report 与 CJGUI_DEMO_PROGRESS 均有中文主标题 / 正文，且不含验证占位 marker。
- CodeLattice review：`public_api_change` 与 `changed_symbols` 已运行，结果为 static-only，提示 public API compatibility 风险需要人工和 targeted verification 兜底；本轮已用 focused verifier、regression、build 与 scans 兜底。
- GitNexus：impact `cjguiExperimentalBuildReusableComponentContractOutput` 返回 `UNKNOWN / target not found / impactedCount 0`，按仓库规则记录为新符号图谱非覆盖；`detect-changes --repo cangjie-live-codelattice --scope unstaged` 返回 `6 files / 2 symbols / affected processes 0 / risk low`，同样只作为辅助证据。

## 后续路线

下一步优先路线：`P1 CJGUI reusable component event routing first slice`。

Reusable component contract 已证明 Todo、FileBrowser 与 AI-generated UI 能复用同一组件合同，并产生稳定 before / after / readback。后续应让该 contract 接入一个更接近真实 UI 的事件路由切片，例如 task row click、file row select、AI form accept 的业务事件归一化；不要回到 owner/readiness/manager/surface/envelope 包装替代 demo 行为。

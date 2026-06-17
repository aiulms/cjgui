# P1 CJGUI shared demo harness layout/style/input/focus contract first slice 阶段报告

日期：2026-06-17

## 本轮白名单证据

- 本轮白名单证据：Shared layout/style/input/focus contract 独立 demo 从 `not_started` 前进到 `runnable`，同一 demo 运行 layout、style、text input、focus 四类业务合同，并新增可编译运行的 demo app、非 Bool public API 与 focused verifier。
- 哪个 demo/API/state 前进：新增 [shared_layout_style_input_focus_contract_app.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/demo/shared_layout_style_input_focus_contract_app.cj)、[runtime_cjgui_experimental_shared_layout_style_input_focus_contract_api.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_cjgui_experimental_shared_layout_style_input_focus_contract_api.cj) 与 [verify_cjgui_shared_layout_style_input_focus_contract_app.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_cjgui_shared_layout_style_input_focus_contract_app.sh)；shared contract first slice 直接服务 `layout/style/input/focus` 四类 demo runtime contract。
- demo before→after：Shared layout/style/input/focus contract 输出 `state_before=layout=single_column;style=neutral_list;input=<empty>;focus=todo_input` 与 `state_after=layout=split_detail;style=focus_accent;input=main;focus=file_filter`。
- 哪些只是辅助验证：CodeLattice / GitNexus、public / protected / forbidden scans、Markdown link / reachability 与 full `cjpm build` 都是辅助验证，不替代 demo 业务输出。
- 验证结果：shared layout/style/input/focus contract focused verifier、既有 demo verifier regression、`cjpm build --skip-script`、public/protected/forbidden scans、Markdown / reachability / 中文抽查与 `git diff --check` 均已通过。
- next route：`P1 CJGUI shared demo harness AI-generated UI contract integration first slice`，把 AI-generated UI 的 generate / preview / explain / accept refresh 接入 shared contract 证据，而不是新增同构 readiness wrapper。
- 本轮将提交/已提交的文件范围：shared layout/style/input/focus contract demo/API/verifier，demo progress、README / tracker / plans index / runtime README / DESIGN_INTENT_INDEX 同步，以及本报告。

## Demo 业务输出

Shared layout/style/input/focus contract first slice 不是 Renderer stage owner 包装，而是独立 demo app 在同一 process-local state 中运行四类 UI framework 关键合同。

```text
cjgui shared layout-style-input-focus contract app: demo=shared_layout_style_input_focus_contract
cjgui shared layout-style-input-focus contract app: status_before=not_started
cjgui shared layout-style-input-focus contract app: status_after=runnable
cjgui shared layout-style-input-focus contract app: interaction=apply_layout,apply_style,type_input,move_focus
cjgui shared layout-style-input-focus contract app: state_before=layout=single_column;style=neutral_list;input=<empty>;focus=todo_input
cjgui shared layout-style-input-focus contract app: state_after=layout=split_detail;style=focus_accent;input=main;focus=file_filter
cjgui shared layout-style-input-focus contract app: state_readback=true
cjgui shared layout-style-input-focus contract app: public_api_consumed=true
cjgui shared layout-style-input-focus contract app: public_api_name=cjguiExperimentalBuildSharedLayoutStyleInputFocusContractOutput
cjgui shared layout-style-input-focus contract app: public_api_output=contract=shared_layout_style_input_focus;layout=single_column->split_detail;style=neutral_list->focus_accent;input=<empty>->main;focus=todo_input->file_filter;interaction=layout_split_detail,style_focus_accent,input_type_main,focus_file_filter;readback=true
```

`runtime_state_write=false`、`renderer_state_write=false`、`public_c_abi_added=false` 等 stop-line 不由 demo 输出；它们只在 verifier / report 的验证段记录。

## Public API 证据

新增 API：

```text
public class CjguiExperimentalSharedLayoutStyleInputFocusContractOutput
public func cjguiExperimentalBuildSharedLayoutStyleInputFocusContractOutput(
    layoutBefore: String,
    layoutAfter: String,
    styleBefore: String,
    styleAfter: String,
    inputBefore: String,
    inputAfter: String,
    focusBefore: String,
    focusAfter: String,
    interactionTrace: String,
    readbackOk: Bool
): CjguiExperimentalSharedLayoutStyleInputFocusContractOutput
```

稳定性级别：`experimental_demo`。

非 Bool 证据：返回类型是 `CjguiExperimentalSharedLayoutStyleInputFocusContractOutput`，包含 `contractName`、layout/style/input/focus 的 before / after 字段、`interactionTrace`、`readbackOk` 与 `summary`。它不调用 internal readiness draft，不返回 Bool readiness，不写 `runtime_state.cj` / renderer state，也不扩 public C ABI。

Demo proof：`SharedLayoutStyleInputFocusContractState.buildContractOutput()` 调用该 API，并在 demo main 中校验 output fields 与 `summary`。

## State write / readback

- Write scope：`SharedLayoutStyleInputFocusContractState.layoutMode`、`styleToken`、`inputText`、`focusTarget`、`interactionTrace`。
- Before：`layout=single_column;style=neutral_list;input=<empty>;focus=todo_input`。
- Actions：`applyLayout("split_detail")`、`applyStyle("focus_accent")`、`typeInput("main")`、`moveFocus("file_filter")`。
- After：`layout=split_detail;style=focus_accent;input=main;focus=file_filter`。
- Readback：demo 用 `businessState()`、individual before / after fields、`interactionTrace` 与 `CjguiExperimentalSharedLayoutStyleInputFocusContractOutput.summary` 校验写入结果。
- Rollback / not-published boundary：本轮状态只存在于 demo process-local in-memory class；进程退出即回收，没有持久化、没有 publication、没有 shared runtime state。

## 修改文件

- [shared_layout_style_input_focus_contract_app.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/demo/shared_layout_style_input_focus_contract_app.cj)
- [runtime_cjgui_experimental_shared_layout_style_input_focus_contract_api.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_cjgui_experimental_shared_layout_style_input_focus_contract_api.cj)
- [verify_cjgui_shared_layout_style_input_focus_contract_app.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_cjgui_shared_layout_style_input_focus_contract_app.sh)
- [CJGUI_DEMO_PROGRESS.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/CJGUI_DEMO_PROGRESS.md)
- [README.md](/Users/jiangxuanyang/Desktop/cangjie/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)
- [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)
- [DESIGN_INTENT_INDEX.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/DESIGN_INTENT_INDEX.md)
- [shared layout/style/input/focus contract report](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-06-17-p1-cjgui-shared-demo-harness-layout-style-input-focus-contract-first-slice-report.md)

## 验证结果

- Focused shared layout/style/input/focus contract verification：通过。`runtime/cjgui/native/scripts/verify_cjgui_shared_layout_style_input_focus_contract_app.sh` 输出 `cjgui_shared_layout_style_input_focus_contract_app_compiled=true`、`cjgui_shared_layout_style_input_focus_contract_app_ran=true`、`shared_layout_style_input_focus_contract_progress_before=not_started`、`shared_layout_style_input_focus_contract_progress_after=runnable`、`shared_layout_style_input_focus_contract_non_bool_public_api_consumed=true` 与 `shared_layout_style_input_focus_contract_owner_local_write_readback=true`。
- Existing demo verifier regression：通过。Shared multi-demo harness / Shared harness / Todo / Settings / Chat / FileBrowser / AI-generated UI focused verifier 均保持 `*_demo_app_compiled=true`、`*_demo_app_ran=true`、`*_non_bool_public_api_consumed=true` 与 owner-local write/readback 证据。
- `cjpm build --skip-script`：通过。`runtime/cjgui` 在 `/tmp/cjgui-shared-layout-style-input-focus-target` 完成 build；输出仍包含既有 unused / stack-frame warning，但没有新增阻塞错误。
- Public declaration scan：通过。本轮新增 `CjguiExperimentalSharedLayoutStyleInputFocusContractOutput` 与 `cjguiExperimentalBuildSharedLayoutStyleInputFocusContractOutput(...)` 两个 shared layout/style/input/focus contract demo public declaration；返回值为非 Bool demo output。仓库仍有 3 个既有 `Ready(): Bool` public declaration，本轮没有新增 readiness Bool API。
- Protected path scan：通过。`runtime/cjgui/src/runtime_state.cj` 仍为 `10065` 行；`runtime_state.cj`、`runtime/cjgui/cjpm.toml`、production native bridge 与 smoke native path 均无 diff。
- Forbidden scan：通过。新增 demo/API 没有 `foreign func`、native bridge call、AppKit / Metal / drawable / command buffer / render / present / pointer surface；demo app 没有输出 governance stop-line fields。
- `git diff --check`：通过。
- Markdown / reachability / 中文正文检查：通过。项目 docs / README 范围内检查 `4987` 个 Markdown 文件、`18816` 个 absolute links，missing target 为 `0`；`README.md`、`GUI_TASK_TRACKER.md`、`docs/plans/README.md`、`runtime/cjgui/README.md`、`DESIGN_INTENT_INDEX.md`、`CJGUI_DEMO_PROGRESS.md` 与本报告均可达 Shared layout/style/input/focus contract runnable、new API 与 next route；本报告 / 进度看板主标题和正文抽查均为中文。
- CodeLattice：辅助检查为 static-only。pre-edit 对新增 sibling experimental demo API 返回 `riskLevel=medium` / `safeToProceed=unknown`；after-edit 返回 native/docs/config review `riskLevel=medium`，说明新符号和新文件仍需 runtime verification 兜底。本轮以源码阅读、focused verifier、full build、public/protected/forbidden scan 兜底。
- GitNexus：`detect-changes --repo cangjie-live-codelattice --scope unstaged` 返回 `risk_level=low`、`affected_count=0`、`changed_files=6`、`changed_symbols=2`；图谱只识别 README 标题级改动，未覆盖新增 untracked demo/API/verifier，按源码和 focused verification 兜底。

## 后续路线

下一步优先路线：`P1 CJGUI shared demo harness AI-generated UI contract integration first slice`。

Shared layout/style/input/focus contract 已把 shared multi-demo harness 中已经出现的 focus / style 字段推进为可运行 demo runtime contract。后续应把 AI-generated UI 的 generate spec、preview diff、explain changes、accept refresh 与该 shared contract 合流，让 demo 继续朝真实 UI framework 能力前进；不要回到 owner/readiness/manager/surface/envelope 包装替代 demo 行为。

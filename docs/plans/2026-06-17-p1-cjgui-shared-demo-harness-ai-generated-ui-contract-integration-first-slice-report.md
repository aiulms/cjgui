# P1 CJGUI shared demo harness AI-generated UI contract integration first slice 阶段报告

日期：2026-06-17

## 本轮白名单证据

- 本轮白名单证据：AI-generated UI shared contract 独立 demo 从 `not_started` 前进到 `runnable`，同一 demo 运行 generate spec、preview diff、explain changes、accept refresh、move focus，并新增可编译运行的 demo app、非 Bool public API 与 focused verifier。
- 哪个 demo/API/state 前进：新增 [ai_generated_ui_shared_contract_app.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/demo/ai_generated_ui_shared_contract_app.cj)、[runtime_cjgui_experimental_ai_generated_ui_shared_contract_api.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_cjgui_experimental_ai_generated_ui_shared_contract_api.cj) 与 [verify_cjgui_ai_generated_ui_shared_contract_app.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_cjgui_ai_generated_ui_shared_contract_app.sh)；该 demo 同时消费既有 AI-generated UI API、既有 shared layout/style/input/focus contract API 与新的 integration API。
- demo before→after：AI-generated UI shared contract 输出 `state_before=components=2;accepted=false;screen=draft_settings_form;layout=single_column;style=neutral_wireframe;input=<empty>;focus=preview_card` 与 `state_after=components=4;accepted=true;screen=settings_profile_form;layout=split_detail;style=sage_panel;input=username;focus=save_button`。
- 哪些只是辅助验证：CodeLattice / GitNexus、public / protected / forbidden scans、Markdown link / reachability 与 full `cjpm build` 都是辅助验证，不替代 demo 业务输出。
- 验证结果：AI-generated UI shared contract focused verifier、既有 demo verifier regression、`cjpm build --skip-script`、public/protected/forbidden scans、Markdown / reachability / 中文抽查、CodeLattice after-edit、GitNexus detect-changes 与 `git diff --check` 均已完成；GitNexus 对新未跟踪符号覆盖不足，已用源码、focused verifier、build 与 scan 兜底。
- next route：`P1 CJGUI shared demo harness reusable component contract first slice`，把已经出现的 Todo / FileBrowser / AI-generated UI shared contract runtime 行为收敛到 reusable component contract，而不是新增同构 readiness wrapper。
- 本轮将提交/已提交的文件范围：AI-generated UI shared contract demo/API/verifier，demo progress、README / tracker / plans index / runtime README / DESIGN_INTENT_INDEX 同步，以及本报告。

## Demo 业务输出

AI-generated UI shared contract first slice 把 AI 生成 UI 的 accept refresh 接入 shared layout/style/input/focus contract。它不是 renderer truth，也不是 workflow truth，而是独立 demo app 的 process-local business state。

```text
cjgui ai-generated-ui shared contract app: demo=ai_generated_ui_shared_contract
cjgui ai-generated-ui shared contract app: status_before=not_started
cjgui ai-generated-ui shared contract app: status_after=runnable
cjgui ai-generated-ui shared contract app: interaction=generate_spec,preview_diff,explain_changes,accept_refresh,move_focus
cjgui ai-generated-ui shared contract app: state_before=components=2;accepted=false;screen=draft_settings_form;layout=single_column;style=neutral_wireframe;input=<empty>;focus=preview_card
cjgui ai-generated-ui shared contract app: state_after=components=4;accepted=true;screen=settings_profile_form;layout=split_detail;style=sage_panel;input=username;focus=save_button
cjgui ai-generated-ui shared contract app: state_readback=true
cjgui ai-generated-ui shared contract app: public_api_consumed=true
cjgui ai-generated-ui shared contract app: public_api_name=cjguiExperimentalBuildAiGeneratedUiSharedContractOutput
cjgui ai-generated-ui shared contract app: public_api_output=contract=ai_generated_ui_shared_contract;screen=settings_profile_form;components=4;diff=added_username_field,enabled_save_button;explain=owner accepted generated settings form refresh;layout=single_column->split_detail;style=neutral_wireframe->sage_panel;input=<empty>->username;focus=preview_card->save_button;ai_summary=components=4;accepted=true;screen=settings_profile_form;diff=added_username_field,enabled_save_button;explain=owner accepted generated settings form refresh;focus=save_button;layout=ai_form_preview;style=sage_panel;shared_contract=contract=shared_layout_style_input_focus;layout=single_column->split_detail;style=neutral_wireframe->sage_panel;input=<empty>->username;focus=preview_card->save_button;interaction=generate_spec,preview_diff,explain_changes,accept_refresh,move_focus;readback=true;readback=true
```

`runtime_state_write=false`、`renderer_state_write=false`、`public_c_abi_added=false` 等 stop-line 不由 demo 输出；它们只在 verifier / report 的验证段记录。

## Public API 证据

新增 API：

```text
public class CjguiExperimentalAiGeneratedUiSharedContractOutput
public func cjguiExperimentalBuildAiGeneratedUiSharedContractOutput(
    acceptedScreen: String,
    componentCount: Int64,
    diffSummary: String,
    explainText: String,
    layoutBefore: String,
    layoutAfter: String,
    styleBefore: String,
    styleAfter: String,
    inputBefore: String,
    inputAfter: String,
    focusBefore: String,
    focusAfter: String,
    aiSummary: String,
    sharedContractSummary: String,
    readbackOk: Bool
): CjguiExperimentalAiGeneratedUiSharedContractOutput
```

稳定性级别：`experimental_demo`。

非 Bool 证据：返回类型是 `CjguiExperimentalAiGeneratedUiSharedContractOutput`，包含 AI accept refresh、component count、layout/style/input/focus before / after、AI summary、shared contract summary、readback 与 integration summary。它不调用 internal readiness draft，不返回 Bool readiness，不写 `runtime_state.cj` / renderer state，也不扩 public C ABI。

Demo proof：`AiGeneratedUiSharedContractState.buildIntegrationOutput()` 调用该 API；同一 demo 还调用 `cjguiExperimentalBuildAiGeneratedUiDemoOutput(...)` 与 `cjguiExperimentalBuildSharedLayoutStyleInputFocusContractOutput(...)`，证明 integration 不是 isolated wrapper。

## State write / readback

- Write scope：`AiGeneratedUiSharedContractState.componentIds`、`accepted`、`acceptedScreen`、`diffSummary`、`explainText`、`layoutMode`、`styleToken`、`inputText`、`focusTarget`、`interactionTrace`。
- Before：`components=2;accepted=false;screen=draft_settings_form;layout=single_column;style=neutral_wireframe;input=<empty>;focus=preview_card`。
- Actions：`generateSpec()`、`previewDiff("added_username_field,enabled_save_button")`、`explain("owner accepted generated settings form refresh")`、`acceptRefresh("settings_profile_form")`、`moveFocus("save_button")`。
- After：`components=4;accepted=true;screen=settings_profile_form;layout=split_detail;style=sage_panel;input=username;focus=save_button`。
- Readback：demo 用 `businessState()`、`componentCount()`、`interactionTrace`、existing AI output、existing shared contract output 与 new integration output 校验写入结果。
- Rollback / not-published boundary：本轮状态只存在于 demo process-local in-memory class；进程退出即回收，没有持久化、没有 publication、没有 shared runtime state。

## 修改文件

- [ai_generated_ui_shared_contract_app.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/demo/ai_generated_ui_shared_contract_app.cj)
- [runtime_cjgui_experimental_ai_generated_ui_shared_contract_api.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_cjgui_experimental_ai_generated_ui_shared_contract_api.cj)
- [verify_cjgui_ai_generated_ui_shared_contract_app.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_cjgui_ai_generated_ui_shared_contract_app.sh)
- [CJGUI_DEMO_PROGRESS.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/CJGUI_DEMO_PROGRESS.md)
- [README.md](/Users/jiangxuanyang/Desktop/cangjie/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)
- [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)
- [DESIGN_INTENT_INDEX.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/DESIGN_INTENT_INDEX.md)
- [AI-generated UI shared contract report](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-06-17-p1-cjgui-shared-demo-harness-ai-generated-ui-contract-integration-first-slice-report.md)

## 验证结果

- Focused AI-generated UI shared contract verification：通过。`runtime/cjgui/native/scripts/verify_cjgui_ai_generated_ui_shared_contract_app.sh` 输出 `cjgui_ai_generated_ui_shared_contract_app_compiled=true`、`cjgui_ai_generated_ui_shared_contract_app_ran=true`、`ai_generated_ui_shared_contract_progress_before=not_started`、`ai_generated_ui_shared_contract_progress_after=runnable`、`ai_generated_ui_shared_contract_non_bool_public_api_consumed=true`、`ai_generated_ui_shared_contract_existing_ai_api_consumed=true`、`ai_generated_ui_shared_contract_existing_shared_contract_api_consumed=true` 与 `ai_generated_ui_shared_contract_owner_local_write_readback=true`。
- 既有 demo verifier regression：通过。已复跑 `verify_cjgui_ai_generated_ui_demo_app.sh`、`verify_cjgui_shared_layout_style_input_focus_contract_app.sh`、`verify_cjgui_shared_multi_demo_harness_app.sh`、`verify_cjgui_shared_demo_harness_app.sh`、`verify_cjgui_todo_demo_app.sh`、`verify_cjgui_settings_demo_app.sh`、`verify_cjgui_chat_demo_app.sh` 与 `verify_cjgui_file_browser_demo_app.sh`。
- Full package build：通过。`cjpm build --target-dir /tmp/cjgui-ai-generated-ui-shared-contract-target --skip-script` 完成，构建日志在 `/tmp/cjgui-ai-generated-ui-shared-contract-build.log`。
- CodeLattice after-edit：完成 static-only `native_review`、`docs_tests` 与 `config_examples` 辅助检查，返回 `riskLevel=medium` / `safeToProceed=unknown`。该结果不是 runtime proof；本轮以 focused verifier、demo regression、full build 与 scans 作为证明。
- GitNexus detect-changes：`repo=cangjie-live-codelattice`、`scope=unstaged` 返回 `changed_files=6`、`changed_count=2`、`affected_count=0`、`risk_level=low`。图谱只识别 README 标题级改动，未覆盖新未跟踪 demo/API/verifier 文件；已按 AGENTS.md 视作图谱非覆盖，并用源码、focused verifier、build 与 scans 兜底。
- Public declaration scan：新增范围仅有 `public class CjguiExperimentalAiGeneratedUiSharedContractOutput` 与 `public func cjguiExperimentalBuildAiGeneratedUiSharedContractOutput(...)`；新增 demo 文件无 public declaration。`Ready(): Bool` public scan 仍只看到既有 `cjguiExperimentalComponentCommitApiReady()`、`cjguiExperimentalComponentPreviewApiReady()` 与 `cjguiExperimentalQueueSubmitShellReady()`，本轮未新增 `xxxReady(): Bool`。
- Protected / forbidden scan：`runtime/cjgui/src/runtime_state.cj` 仍为 `10065` 行；`runtime_state.cj`、`runtime/cjgui/cjpm.toml`、production native bridge 与 smoke native files 无 diff。新增 API / demo 范围内没有 `foreign func`、`cjgui_native_bridge_`、AppKit / Metal / drawable / command buffer / render / present / pointer handle 路径；demo 输出不包含 `runtime_state_write=false`、`renderer_state_write=false`、`public_c_abi_added=false` 或 `visibility_published=false`。
- Markdown / reachability / whitespace：`git diff --check` 通过；Markdown absolute link check 扫描 `4988` 个 Markdown 文件、`18836` 个项目绝对链接，missing target 为 `0`；README、tracker、plans README、runtime README、DESIGN_INTENT_INDEX、CJGUI_DEMO_PROGRESS 与本报告均可检索到 AI-generated UI shared contract、`cjguiExperimentalBuildAiGeneratedUiSharedContractOutput` 与下一路线 `P1 CJGUI shared demo harness reusable component contract first slice`。

## 后续路线

下一步优先路线：`P1 CJGUI shared demo harness reusable component contract first slice`。

AI-generated UI shared contract 已证明 AI accept refresh 可以写入 shared layout/style/input/focus contract 并被 demo readback。后续应把 Todo / FileBrowser / AI-generated UI 已有动作、状态、layout、style、input、focus 字段收敛成 reusable component contract，减少每个 demo 各自定义 runtime 字段；不要回到 owner/readiness/manager/surface/envelope 包装替代 demo 行为。

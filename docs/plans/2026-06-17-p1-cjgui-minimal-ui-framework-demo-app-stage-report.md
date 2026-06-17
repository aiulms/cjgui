# P1 CJGUI 最小 UI framework demo app 阶段报告

日期：2026-06-17

## 本轮白名单证据

- 本轮白名单证据：AI-generated UI 独立 demo 从 `not_started` 前进到 `runnable`，并新增可编译运行的 demo app、非 Bool public API 与 focused verifier。
- 哪个 demo/API/state 前进：新增 [ai_generated_ui_app.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/demo/ai_generated_ui_app.cj)、[runtime_cjgui_experimental_ai_generated_ui_demo_api.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_cjgui_experimental_ai_generated_ui_demo_api.cj) 与 [verify_cjgui_ai_generated_ui_demo_app.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_cjgui_ai_generated_ui_demo_app.sh)；同步收口已有 FileBrowser demo 到 `runnable`。
- demo before→after：AI-generated UI 输出 `state_before=components=2;accepted=false;screen=draft_settings_form;diff=pending_review;focus=preview_card;style=neutral_wireframe` 与 `state_after=components=4;accepted=true;screen=settings_profile_form;diff=added_username_field,enabled_save_button;focus=save_button;style=sage_panel`。
- 哪些只是辅助验证：CodeLattice / GitNexus、public / protected / forbidden scans、Markdown link / reachability 与 full `cjpm build` 都是辅助验证，不替代 demo 业务输出。
- 验证结果：focused AI-generated UI verifier 已通过；FileBrowser verifier 已通过；后续验证段记录完整回归。
- next route：`P1 CJGUI shared demo harness first slice`，服务 Todo / Settings / Chat / FileBrowser / AI-generated UI 的统一运行与状态读回；不要回到 owner/readiness/manager/surface/envelope 包装。
- 本轮将提交/已提交的文件范围：AI-generated UI demo/API/verifier，FileBrowser 与 AI-generated UI 进度收口文档，README / tracker / plans index / runtime README / DESIGN_INTENT_INDEX 同步。

## Demo 业务输出

AI-generated UI demo 的业务输出现在像一个 owner 接受 AI 生成表单后的刷新，而不是 stop-line 报告：

```text
cjgui ai generated ui demo app: demo=ai_generated_ui
cjgui ai generated ui demo app: status_before=not_started
cjgui ai generated ui demo app: status_after=runnable
cjgui ai generated ui demo app: layout=ai_form_preview
cjgui ai generated ui demo app: interaction=generate_spec,preview_diff,explain_changes,accept_refresh,move_focus
cjgui ai generated ui demo app: state_before=components=2;accepted=false;screen=draft_settings_form;diff=pending_review;focus=preview_card;style=neutral_wireframe
cjgui ai generated ui demo app: state_after=components=4;accepted=true;screen=settings_profile_form;diff=added_username_field,enabled_save_button;focus=save_button;style=sage_panel
cjgui ai generated ui demo app: state_readback=true
cjgui ai generated ui demo app: public_api_consumed=true
cjgui ai generated ui demo app: public_api_name=cjguiExperimentalBuildAiGeneratedUiDemoOutput
cjgui ai generated ui demo app: public_api_output=components=4;accepted=true;screen=settings_profile_form;diff=added_username_field,enabled_save_button;explain=owner accepted generated settings form refresh;focus=save_button;layout=ai_form_preview;style=sage_panel
```

`runtime_state_write=false`、`renderer_state_write=false`、`public_c_abi_added=false` 等 stop-line 不由 demo 输出；它们只在 verifier / report 的验证段记录。

## Public API 证据

新增 API：

```text
public class CjguiExperimentalAiGeneratedUiDemoOutput
public func cjguiExperimentalBuildAiGeneratedUiDemoOutput(
    componentCount: Int64,
    accepted: Bool,
    acceptedScreen: String,
    diffSummary: String,
    explainText: String,
    focusTarget: String,
    layoutKind: String,
    styleToken: String
): CjguiExperimentalAiGeneratedUiDemoOutput
```

稳定性级别：`experimental_demo`。

非 Bool 证据：返回类型是 `CjguiExperimentalAiGeneratedUiDemoOutput`，包含 `demoName`、`componentCount`、`accepted`、`acceptedScreen`、`diffSummary`、`explainText`、`focusTarget`、`layoutKind`、`styleToken` 与 `summary`。它不调用 internal readiness draft，不返回 Bool readiness，不写 `runtime_state.cj` / renderer state，也不扩 public C ABI。

Demo proof：`AiGeneratedUiState.buildApiOutput()` 调用该 API，并在 demo main 中校验 output fields 与 `summary`。

## State write / readback

- Write scope：`AiGeneratedUiState.componentIds`、`accepted`、`acceptedScreen`、`diffSummary`、`explainText`、`focusTarget`、`styleToken`。
- Before：`components=2;accepted=false;screen=draft_settings_form;diff=pending_review;focus=preview_card;style=neutral_wireframe`。
- Actions：`previewDiff("added_username_field,enabled_save_button")`、`explain("owner accepted generated settings form refresh")`、`acceptAndRefresh("settings_profile_form", "sage_panel")`、`moveFocus("save_button")`。
- After：`components=4;accepted=true;screen=settings_profile_form;diff=added_username_field,enabled_save_button;focus=save_button;style=sage_panel`。
- Readback：demo 用 `businessState()`、`componentCount()` 与 `CjguiExperimentalAiGeneratedUiDemoOutput.summary` 校验写入结果。
- Rollback / not-published boundary：本轮状态只存在于 demo process-local in-memory class；进程退出即回收，没有持久化、没有 publication、没有 shared runtime state。

## FileBrowser 收口

FileBrowser 已有 independent demo artifact 本轮收口为 `runnable`：

- [file_browser_app.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/demo/file_browser_app.cj)
- [runtime_cjgui_experimental_file_browser_demo_api.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_cjgui_experimental_file_browser_demo_api.cj)
- [verify_cjgui_file_browser_demo_app.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_cjgui_file_browser_demo_app.sh)

Focused verifier 输出 `file_browser_demo_progress_before=not_started` 与 `file_browser_demo_progress_after=runnable`。该收口补齐 FileBrowser 验收 demo 的进度记录；本轮没有改 FileBrowser code。

## 修改文件

- [ai_generated_ui_app.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/demo/ai_generated_ui_app.cj)
- [runtime_cjgui_experimental_ai_generated_ui_demo_api.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_cjgui_experimental_ai_generated_ui_demo_api.cj)
- [verify_cjgui_ai_generated_ui_demo_app.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_cjgui_ai_generated_ui_demo_app.sh)
- [CJGUI_DEMO_PROGRESS.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/CJGUI_DEMO_PROGRESS.md)
- [stage report](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-06-17-p1-cjgui-minimal-ui-framework-demo-app-stage-report.md)
- [README.md](/Users/jiangxuanyang/Desktop/cangjie/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)
- [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)
- [DESIGN_INTENT_INDEX.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/DESIGN_INTENT_INDEX.md)

## 验证结果

- Focused AI-generated UI verification：通过。`runtime/cjgui/native/scripts/verify_cjgui_ai_generated_ui_demo_app.sh` 输出 `cjgui_ai_generated_ui_demo_app_compiled=true`、`cjgui_ai_generated_ui_demo_app_ran=true`、`ai_generated_ui_demo_progress_before=not_started`、`ai_generated_ui_demo_progress_after=runnable`、`ai_generated_ui_non_bool_public_api_consumed=true`、`ai_generated_ui_owner_local_write_readback=true`。
- Focused FileBrowser verification：通过。`runtime/cjgui/native/scripts/verify_cjgui_file_browser_demo_app.sh` 输出 `file_browser_demo_progress_before=not_started`、`file_browser_demo_progress_after=runnable`、`file_browser_non_bool_public_api_consumed=true` 与 `file_browser_owner_local_write_readback=true`。
- Focused Todo / Settings / Chat verification：通过。三个既有 demo verifier 均保持 `*_demo_app_compiled=true`、`*_demo_app_ran=true`、`*_non_bool_public_api_consumed=true` 与 owner-local write/readback 证据。
- `cjpm build --skip-script`：通过。`runtime/cjgui` 在 `/tmp/cjgui-minimal-ui-framework-ai-generated-ui-target` 完成 build；输出仍包含既有 warning，但没有新增阻塞错误。
- Public declaration scan：通过。本轮新增 `CjguiExperimentalAiGeneratedUiDemoOutput` 与 `cjguiExperimentalBuildAiGeneratedUiDemoOutput(...)` 两个 AI-generated UI demo public declaration；返回值为非 Bool demo output。仓库仍有 3 个既有 `Ready(): Bool` public declaration，本轮没有新增 readiness Bool API。
- Protected path scan：通过。`runtime/cjgui/src/runtime_state.cj` 仍为 `10065` 行；`runtime_state.cj`、`runtime/cjgui/cjpm.toml`、production native bridge 与 smoke native path 均无 diff。
- Forbidden scan：通过。demo app 没有输出 governance stop-line fields；新增 demo/API 没有 `foreign func`、native bridge call、AppKit / Metal / drawable / command buffer / render / present / pointer surface。
- Markdown absolute link check：通过。项目 docs / README 范围内检查 `18698` 个 absolute links，missing target 为 `0`。
- Reachability：通过。`README.md`、`GUI_TASK_TRACKER.md`、`docs/plans/README.md`、`runtime/cjgui/README.md`、`DESIGN_INTENT_INDEX.md`、`CJGUI_DEMO_PROGRESS.md` 与本报告均可达 AI-generated UI runnable、new API 与 next route。
- 中文标题正文抽查：通过。新增/触碰的主要 Markdown 均保留中文标题或中文正文。
- CodeLattice：辅助检查为 static-only。`breaking_change` 对新增 AI-generated UI symbols 报 `unknownCount=2`、`staleReason=file_added`、compatibility risk `medium`，说明新符号尚未入图；本轮以源码阅读、focused verifier、full build、public/protected/forbidden scan 兜底。
- GitNexus：`detect-changes --repo cangjie-live-codelattice --scope unstaged` 返回 `Risk level: low`、`Affected processes: 0`，但只识别到 7 个已跟踪文档文件；新增未跟踪 demo/API/verifier 仍以 focused verifier / build / scan 作为主证据。

## Next route

下一步优先路线：`P1 CJGUI shared demo harness first slice`。

Todo、Settings、Chat、FileBrowser 与 AI-generated UI 现在都达到 `runnable`。后续应减少同构 demo verifier 模板，建立 shared demo harness 或继续推进更真实的 layout / style / text / input / focus interactions；不要再用 owner/readiness/manager/surface/envelope 包装替代 demo 行为。

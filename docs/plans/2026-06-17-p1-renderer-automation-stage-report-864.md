# P1 Renderer Automation Stage Report 864

日期：2026-06-17

## Tail 校准

本轮启动后重新读取 `AGENTS.md`、`README.md`、`GUI_TASK_TRACKER.md`、`docs/plans/README.md`、`runtime/cjgui/README.md`、`docs/plans/DESIGN_INTENT_INDEX.md`、`docs/core/CJGUI_UI_FRAMEWORK_COMPLETENESS_CRITERIA.md` 与最新 `stage report 860`。真实 tail 是 stage860 `CjguiInternalRendererStage860OwnerLocalTextInputCommitRuntimeManagerReadiness`，next opening 是 `stage861_text_input_owner_acceptance_review_after_stage860`。仓库存在已报告但未 stage 的 stage849-860 owner/script/report artifacts；最高 owner、最高 suite 与最高 report 一致停在 stage860，因此没有需要先收口的更高 stage artifact。

本轮 tail 属于 owner-local text-input commit first-slice 之后的 owner acceptance review / decision boundary 链路。最近几轮已有 text-input commit preflight / rollback / inspection / runtime manager 与 owner-local commit runtime manager 的节奏，因此本轮触发能力收敛：不继续做 text-input commit runtime manager vNext，而是把 stage860 输出推进到 review gate、decision reducer、demo-host acceptance surface 与 shared owner acceptance runtime manager。关键 stop-line：不执行真实 input dispatch、不授予 owner acceptance、不提交 text mutation 或 state-store commit、不发布 visibility、不写 `runtime_state.cj` / renderer state、不扩 public API / public C ABI / native bridge。

## Four-Slice Macro Package

1. Slice 1 / stage861：新增 [runtime_renderer_stage861_text_input_owner_acceptance_review_gate.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_stage861_text_input_owner_acceptance_review_gate.cj)，消费 stage860 shared owner-local commit runtime manager，生成 owner acceptance review gate 与 accept / reject / request-changes / rollback snapshot review lanes。
2. Slice 2 / stage862：新增 [runtime_renderer_stage862_text_input_acceptance_decision_reducer.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_stage862_text_input_acceptance_decision_reducer.cj)，消费 stage861 review gate，生成 accepted / rejected / request-changes decision candidates、rollback snapshot selection 与 not-published acceptance receipt。
3. Slice 3 / stage863：新增 [runtime_renderer_stage863_text_input_acceptance_demo_host_surface.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_stage863_text_input_acceptance_demo_host_surface.cj)，消费 stage862 decision reducer，接入 Todo/settings/AI-generated settings/chat composer/file browser 五类 demo-host acceptance inspection surfaces、semantic diff rows 与 not-published boundary banner。
4. Slice 4 / stage864：新增 [runtime_renderer_stage864_text_input_owner_acceptance_runtime_manager.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_stage864_text_input_owner_acceptance_runtime_manager.cj)，消费 stage863 demo surface，抽出 shared text-input owner acceptance runtime manager/runtime contract/execution receipt contract、`owner_local_commit_review_decision_demo_runtime` cycle order、五类 demo runtime surfaces 与 stage865 public API consumption proof next route。

## 能力增量

真实能力增量是把 owner-local / in-memory commit first slice 推进成 owner-controlled acceptance review boundary：stage860 的可检查 owner-local commit result 现在能进入统一 review gate、non-dispatching decision reducer、五类 demo-host acceptance inspection surface 与 shared runtime manager。它让 Todo、settings、AI-generated settings、chat composer、file browser 共用同一 acceptance review / decision / surface / runtime contract，减少后续复制 per-demo owner acceptance 模板的必要性。

## 周期收敛

本轮触发周期收敛。stage864 final packet 固定 `future_per_demo_owner_acceptance_template_need_reduced=true`，后续可以从 shared owner acceptance runtime manager 转向 public API consumption proof、visibility publication preflight 或真实 demo write path 的下一层，而不是继续围绕 text-input commit preflight / rollback / inspection / owner-local commit manager 做同构 vNext。

## Public API

本轮没有推进 public API first slice，没有新增 public surface，没有新增 stable API，也没有扩 public C ABI。public declaration scan 只确认既有 experimental preview surface 保持可见：`cjguiExperimentalComponentPreviewApiReady()` 与 `cjguiExperimentalQueueSubmitShellReady()`；stage861-864 owner 均为 internal。

## Commit First Slice

本轮没有扩大 commit first slice。stage861-864 消费 stage860 的 owner-local / in-memory commit first slice，但只把它推进到 owner acceptance review / decision / demo-host surface / runtime contract。边界仍保持：`owner_acceptance_granted=false`、`text_input_commit_committed=false`、`state_store_commit_published=false`、`action_dispatch=false`、`state_update_committed=false`、`visibility_publication_admitted=false`、`visibility_published=false`、`renderer_submission=false`、`renderer_state_write=false`、`runtime_state_write=false`。

Rollback 路径由 stage861 rollback snapshot review lane、stage862 rollback snapshot selection、stage863 inspection rows 与 stage864 runtime contract carry-forward 表达；not-published 边界由 stage862 receipt、stage863 boundary banner 与 stage864 runtime receipt 表达。

## 辅助 Envelope / Readiness

辅助层包括四个 owner readiness、四个 owner probes、四个 focused suites 与 suite packet receipts。它们只证明 consumption chain、contract shape、owner acceptance review boundary、demo-host acceptance surface 和 stop-line，不代表 production truth、backend-ready truth、真实 input pipeline execution、真实 renderer submission、global state-store commit、owner acceptance grant 或 visibility publication。

## 修改文件

- [runtime_renderer_stage861_text_input_owner_acceptance_review_gate.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_stage861_text_input_owner_acceptance_review_gate.cj)
- [runtime_renderer_stage862_text_input_acceptance_decision_reducer.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_stage862_text_input_acceptance_decision_reducer.cj)
- [runtime_renderer_stage863_text_input_acceptance_demo_host_surface.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_stage863_text_input_acceptance_demo_host_surface.cj)
- [runtime_renderer_stage864_text_input_owner_acceptance_runtime_manager.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_stage864_text_input_owner_acceptance_runtime_manager.cj)
- [verify_renderer_stage861_text_input_owner_acceptance_review_gate_owner.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_stage861_text_input_owner_acceptance_review_gate_owner.sh)
- [verify_renderer_stage861_text_input_owner_acceptance_review_gate_suite.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_stage861_text_input_owner_acceptance_review_gate_suite.sh)
- [verify_renderer_stage862_text_input_acceptance_decision_reducer_owner.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_stage862_text_input_acceptance_decision_reducer_owner.sh)
- [verify_renderer_stage862_text_input_acceptance_decision_reducer_suite.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_stage862_text_input_acceptance_decision_reducer_suite.sh)
- [verify_renderer_stage863_text_input_acceptance_demo_host_surface_owner.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_stage863_text_input_acceptance_demo_host_surface_owner.sh)
- [verify_renderer_stage863_text_input_acceptance_demo_host_surface_suite.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_stage863_text_input_acceptance_demo_host_surface_suite.sh)
- [verify_renderer_stage864_text_input_owner_acceptance_runtime_manager_owner.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_stage864_text_input_owner_acceptance_runtime_manager_owner.sh)
- [verify_renderer_stage864_text_input_owner_acceptance_runtime_manager_suite.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_stage864_text_input_owner_acceptance_runtime_manager_suite.sh)
- [README.md](/Users/jiangxuanyang/Desktop/cangjie/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)
- [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)
- [DESIGN_INTENT_INDEX.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/DESIGN_INTENT_INDEX.md)
- [2026-06-17-p1-renderer-automation-stage-report-864.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-06-17-p1-renderer-automation-stage-report-864.md)

Pre-existing but untracked stage849-860 artifacts were retained and consumed; they were not reverted, staged, or committed.

## 验证结果

- RED：stage861 / 862 / 863 / 864 owner probes 先按 TDD 失败，失败原因为目标 owner source 缺失。
- GREEN：stage861 / 862 / 863 / 864 owner probes 均通过。
- Focused suite：stage864 suite 通过，并级联消费 stage861-863 suites；最终 packet 写入 `/private/tmp/cjgui-stage861-stage864/stage864/stage864-text-input-owner-acceptance-runtime-manager-suite.packet`。
- Format：四个新 `.cj` owner 已用 `cjfmt -f <file> -o <file>` 格式化。
- Build：`runtime/cjgui` 下 `cjpm build --target-dir /private/tmp/cjgui-stage861-stage864/stage864/target --skip-script` 通过；输出仍可能包含仓库既有 large stack-frame warnings，但未阻断构建。
- Script syntax：stage861-864 focused scripts 均通过 `zsh -n`。
- Public declaration scan：通过；stage861-864 未新增 public declaration。
- Forbidden native/render token scan：通过；未发现 forbidden native / renderer execution tokens。
- Protected path scan：通过；未修改 `runtime/cjgui/cjpm.toml`、`runtime/cjgui/src/runtime_state.cj` 或 native bridge headers / Objective-C files。
- `git diff --check`：通过。

Final stage864 packet 固定关键 facts：`stage863_text_input_acceptance_demo_host_surface_consumed=true`、`stage862_text_input_acceptance_decision_reducer_consumed_transitively=true`、`stage861_text_input_owner_acceptance_review_gate_consumed_transitively=true`、`stage860_owner_local_text_input_commit_runtime_manager_consumed_transitively=true`、`shared_text_input_owner_acceptance_runtime_manager_materialized=true`、`text_input_owner_acceptance_runtime_contract_materialized=true`、`text_input_owner_acceptance_execution_receipt_contract_materialized=true`、`cycle_order_owner_local_commit_review_decision_demo_runtime_materialized=true`、`todo_text_input_owner_acceptance_runtime_surface_materialized=true`、`settings_text_input_owner_acceptance_runtime_surface_materialized=true`、`ai_generated_settings_text_input_owner_acceptance_runtime_surface_materialized=true`、`chat_composer_text_input_owner_acceptance_runtime_surface_materialized=true`、`file_browser_text_input_owner_acceptance_runtime_surface_materialized=true`、`future_per_demo_owner_acceptance_template_need_reduced=true`、`stage865_text_input_commit_public_api_consumption_proof_prepared=true`、`owner_acceptance_granted=false`、`text_input_commit_committed=false`、`state_store_commit_published=false`、`action_dispatch=false`、`state_update_committed=false`、`visibility_publication_admitted=false`、`visibility_published=false`、`renderer_submission=false`、`renderer_state_write=false`、`runtime_state_write=false`、`new_public_surface_added=false`、`stable_public_api_added=false`、`public_c_abi_added=false`、`native_bridge_expansion=false`。

## GitNexus / CodeLattice

按 workspace 规则使用 `cangjie-live-codelattice`。编辑前 `context init` 返回 ambiguous `init` candidates，`impact CjguiInternalRendererStage860OwnerLocalTextInputCommitRuntimeManagerReadiness --repo cangjie-live-codelattice` 返回 target not found / UNKNOWN；不能作为安全证明。编辑后 `impact CjguiInternalRendererStage864TextInputOwnerAcceptanceRuntimeManagerReadiness --repo cangjie-live-codelattice` 仍返回 target not found / UNKNOWN。`detect-changes --repo cangjie-live-codelattice --scope all` 只跟踪到 5 个已索引文档文件 / 2 个 README section symbols，Affected processes 为 0，Risk 为 low，但未覆盖新增 untracked owner / script artifacts。`cangjie-production-alias-check.sh --status` 显示 live repo dirty/RED、untracked artifacts 存在。结论：graph 没覆盖本轮新增 targets，本轮安全性来自源码阅读、RED/GREEN probes、focused suite、build 与 public/protected/forbidden scans 兜底。

## Runtime Native Probe / Harness

本轮未执行 bounded runtime native probe，因为没有修改 native bridge、AppKit / Metal harness、`runtime_state.cj` 或 renderer submission path。未遇到新的 CJGUI harness 缺口或宿主限制。

## Stop-Line 与剩余差距

第一帧链路保持未推进；renderer-state write 与 runtime_state write 仍为 false。minimal UI framework 距离真实 demo 仍缺：owner acceptance grant 的真实策略、真实 text mutation commit、input dispatch、IME / shaping / selection integration、可见 renderer refresh、visibility publication boundary 与 public component API 对 commit / acceptance result 的自然消费 proof。

## Canonical Endpoint / Next Route

当前 canonical endpoint：

- `CjguiInternalRendererStage864TextInputOwnerAcceptanceRuntimeManagerReadiness`
- `cjguiInternalExecuteDefaultRendererStage864TextInputOwnerAcceptanceRuntimeManagerDraft()`

下一条最值得推进的工程目标：

- `stage865_text_input_commit_public_api_consumption_proof_after_stage864`

它应消费 stage864 shared owner acceptance runtime manager，推进 public component API consumption proof 或 minimal public API first-slice proof，并继续保持 no new stable API、no public C ABI、no runtime_state / renderer state / visibility publication write，除非下一轮明确以 API first slice 为目标并完整验证。

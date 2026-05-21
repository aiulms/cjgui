# P1 Renderer Automation Stage Report: Live First-Frame Truth Admission Refresh

日期：2026-05-20

## 主题阶段包

本轮主题是 `visible-window / AppKit / Metal live first-frame evidence -> truth admission -> baseline / semantic bridge -> production truth recheck -> renderer-state write readiness replay`。当前 shell 已有 Metal device，因此先正向重跑真实 bounded runtime native probe，再修复 packet bridge 断点，最后把 fresh positive first-frame fact 推到 stage156 renderer-state write first-slice readiness。

## 工程闭环

1. 真实 bounded first-frame probe refresh：直接执行 bounded first-frame observation native probe，观测 `isolated_metal_device_available=true`、`next_drawable_called=true`、`render_command_encoder_created=true`、`pipeline_state_created=true`、`draw_called=true`、`present_called=true`、`commit_called=true`、`bounded_gpu_submission_completed=true`、`frame_hash_nonzero=true`、`first_frame_observed=true`、`cleanup_observed=true`，但继续保持 `production_render_truth=false`、`renderer_state_write=false`。
2. stage141 -> stage142 bridge bugfix：stage141 packet 已有 `present_called=true` 与 `bounded_gpu_submission_completed=true`，但 stage141 suite 未转抄这两个字段，导致 stage142 fail-closed 为 `blocked_pending_present_scheduling_contract`。本轮修复 [verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_present_scheduling_after_commit_no_present_contract_first_slice_suite.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_present_scheduling_after_commit_no_present_contract_first_slice_suite.sh)，只新增 suite summary 字段转抄。
3. first-frame -> truth-admission -> write-decision refresh：用 fresh stage141 packet 重跑 stage142/143/144。stage142 变为 `first_frame_observation_after_present_scheduling_contract_ready`，stage143 变为 `truth_admission_after_first_frame_observation_contract_preflight_ready`，stage144 变为 `renderer_state_write_decision_denied_pending_production_truth_and_write_admission`。
4. baseline / semantic / production truth recheck refresh：重跑 stage145/148/149/150。stage145 现在固定 `truth_admission_preflight_ready=true`、`positive_first_frame_input_ready=true`、`baseline_semantic_verification_input_ready=true`；stage150 精确收敛为 `production_truth_recheck_blocked_missing_semantic_runtime_admission`，缺口是 `semantic_acceptance_runtime_admission,backend_ready_truth,result_envelope_promotion_token`。
5. renderer-state admission readiness replay：fresh stage150 继续推进 stage151-156。write token / mutation request / guarded executor / visibility / rollback / readiness 链路均消费新 packet 并通过；stage156 固定 `renderer_state_write_first_slice_source_ready=true`、`renderer_state_write_positive_dry_run_candidate_defined=true`、`renderer_state_write_first_slice_runtime_admitted=false`、`renderer_state_write=false`。

## 新增正向条件

- 当前 shell 不再是 no-device：bounded native probe 正向证明 Metal drawable / encoder / pipeline / vertex / draw / present / commit / first-frame capture / nonzero frame hash。
- stage141 suite 现在能向下游发布 `present_called=true` 与 `bounded_gpu_submission_completed=true`，解除 stage142 的误阻断。
- stage142/143/144 形成 fresh positive first-frame -> truth admission preflight -> write-decision denial packet 小链路。
- stage145/150 把生产 truth 缺口从宿主能力问题推进到明确 predicate：semantic runtime admission、backend-ready truth、result envelope promotion token。
- stage156 以 fresh upstream facts 重新生成 renderer-state write first-slice readiness，仍保持 non-mutating。

## 验证结果

- bounded runtime native probe：执行，通过；未持久化图片/hash，未升级 production truth。
- Focused suites：stage141、stage142、stage143、stage144、stage145、stage148、stage149、stage150、stage151、stage152、stage153、stage154、stage155、stage156 均通过。
- 关键 packets：
  - stage141: `/tmp/cjgui-stage141-present-scheduling-after-commit-suite-live-fix-57478/stage141-present-scheduling-after-commit-no-present-contract-suite.packet`
  - stage142: `/tmp/cjgui-stage142-first-frame-observation-after-present-scheduling-suite-live-fix-59399/stage142-first-frame-observation-after-present-scheduling-contract-suite.packet`
  - stage143: `/tmp/cjgui-stage143-truth-admission-after-first-frame-suite-live-fix-60560/stage143-truth-admission-after-first-frame-observation-contract-suite.packet`
  - stage144: `/tmp/cjgui-stage144-renderer-state-write-decision-suite-live-fix-60902/stage144-renderer-state-write-decision-after-truth-admission-contract-suite.packet`
  - stage150: `/tmp/cjgui-stage150-production-truth-recheck-suite-live-fix-64382/stage150-production-truth-recheck-after-semantic-comparator-bridge-suite.packet`
  - stage156: `/tmp/cjgui-stage156-renderer-state-write-readiness-suite-live-fix-67593/stage156-renderer-state-write-first-slice-readiness-contract-suite.packet`
- `zsh -n` touched script 通过；`git diff --check` 通过；protected path scan 通过；public / forbidden diff scan 通过。
- `cjpm build --skip-script` 显式重跑通过，保留既有 231 个 unused warnings。第一次显式 build 命令因临时目录写成字面量 `$$` 失败，修正命令后通过；该失败不是代码失败。
- GitNexus impact / context 对 touched shell route 名称返回 not found / UNKNOWN；`detect-changes --repo cangjie-live-codelattice --scope all` 未覆盖本脚本改动，不能当安全证明。本轮安全结论依赖源码读取、focused suites、build 与 scans。
- `runtime/cjgui/src/runtime_state.cj` 行数保持 10065；未修改 `runtime_state.cj`、`runtime/cjgui/cjpm.toml`、native bridge header/source 或 public C ABI。

## 当前 Endpoint 与 Next Route

本轮 fresh live-evidence endpoint 是 stage156 suite packet：

`/tmp/cjgui-stage156-renderer-state-write-readiness-suite-live-fix-67593/stage156-renderer-state-write-first-slice-readiness-contract-suite.packet`

仓库内 source canonical endpoint 仍保留上一轮 stage166 `CjguiInternalRendererStage166RendererStateWriteDecisionRecheckFirstSliceReadiness` / `cjguiInternalExecuteDefaultRendererStage166RendererStateWriteDecisionRecheckFirstSliceDraft()`；但 stage157-166 还需要用本轮 fresh stage156 packet 做一次下游 replay，之后再推进 stage167 renderer-state write first-slice contract，避免 stage167 消费旧 no-device 派生 packet。

最值得继续的工程目标：消费本轮 fresh stage156 packet，顺序重跑 stage157-166，确认 internal owner envelope / mutation dry-run / visibility result / write dry-run / admission ledger / precommit / executor / rollback / visibility / decision recheck 全部基于 live first-frame truth-admission preflight；随后才进入 stage167 non-mutating renderer-state write first-slice contract。

## 剩余缺口

第一帧链路剩余缺口：baseline comparison 尚未执行，semantic runtime admission 仍为 false，production render truth 仍不能由 isolated evidence 直接升级，backend-ready truth 仍为 false，frame hash 仍按策略 redacted / non-persisted。

renderer-state write / runtime_state write 剩余缺口：缺 `semantic_acceptance_runtime_admission`、`backend_ready_truth`、`result_envelope_promotion_token`、`production_write_admission`、write token allow、mutation request runtime admission、guarded executor runtime admission、visibility publication runtime admission、rollback boundary positive admission，以及 runtime_state 最小 schema / write-path 验证。本轮未做真实 state mutation，也未做 runtime_state write。

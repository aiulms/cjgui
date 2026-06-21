# CJGUI shared demo typed evidence section 合同报告

日期：2026-06-21

状态：已完成 / demo_support 复用收敛 / 不改变 Renderer truth

## 本轮目标

本轮接续 `P1 CJGUI shared demo_support typed evidence section contract for component/action/readback batching`，把当前 10 个 runnable demo 尾部重复的 `printEvidenceProfile(...)` + `printSharedExecutionProof(...)` 两段式编排下沉到 shared typed section。

新增的 `CjguiExperimentalDemoEvidenceSection` 把 evidence profile、shared demo output、component/action session、owner-local commit result、commit harness 与 run result 组合为一个 typed section；demo 只构造 section 并调用 `CjguiExperimentalDemoEvidencePresenter.printEvidenceSection(...)`。业务 before / after / readback 输出保持不变，但 demo-local 尾部 proof wiring 更少。

## 落地内容

- 新增 [runtime_cjgui_experimental_demo_evidence_section.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/demo_support/runtime_cjgui_experimental_demo_evidence_section.cj)，提供 `CjguiExperimentalDemoEvidenceSection` 与 `profileFactCount()`。
- 更新 [runtime_cjgui_experimental_demo_evidence_presenter.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/demo_support/runtime_cjgui_experimental_demo_evidence_presenter.cj)，新增 `printEvidenceSection(...)`，统一调用 profile batching 与 shared execution proof。
- 当前 10 个 runnable demo 全部改为构造 `CjguiExperimentalDemoEvidenceSection` 并调用 `evidencePresenter.printEvidenceSection(evidenceSection)`；demo-local direct profile/proof call 已退役。
- 当前 10 个 focused verifier 与 aggregate verifier 都新增 section source / usage / copy 检查，并拒绝 demo 回退到 direct profile/proof 调用。

## 验证事实

- [verify_cjgui_shared_demo_run_harness.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_cjgui_shared_demo_run_harness.sh)：通过，实际编译并运行当前全部 10 个 demo binary。
- [verify_cjgui_todo_demo_app.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_cjgui_todo_demo_app.sh)：通过，回显 `todo_shared_run_readback=true` 与 `todo_shared_run_not_published=true`。
- [verify_cjgui_ai_generated_ui_demo_app.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_cjgui_ai_generated_ui_demo_app.sh)：通过，回显 `ai_generated_ui_shared_run_readback=true` 与 `ai_generated_ui_shared_run_not_published=true`。
- `cjpm build --target-dir /tmp/cjgui-shared-demo-typed-evidence-section-target --skip-script`：通过，仅保留既有 unused / stack-frame warnings。

Aggregate verifier 新增并回显：

- `cjgui_shared_demo_evidence_section=CjguiExperimentalDemoEvidenceSection`
- `cjgui_shared_demo_evidence_section_demo_count=10`
- `cjgui_shared_demo_evidence_section_typed_execution_batching_shared=true`
- `cjgui_shared_demo_direct_profile_and_proof_calls_retired=true`

这些 facts 证明当前 10 个 demo 的 profile + component/action + commit/readback + run proof 尾部编排已经共享；它们不证明 Renderer backend、native bridge、state store、public C ABI 或 production render truth。

## 边界

- 不新增 public C ABI。
- 不修改 production native bridge。
- 不写 `runtime_state.cj`。
- 不写 renderer state。
- 不修改 `runtime/cjgui/cjpm.toml`。
- 不把 demo stdout evidence 解释成 Renderer canonical tail、backend-ready truth 或 production render truth。
- `CjguiExperimentalDemoEvidenceSection` 只服务 demo_support experimental 复用路径，不是稳定 toolkit surface。

## 设计意图出口自检

- 本轮是否改变主题状态：改变 CJGUI minimal UI framework demo_support 复用状态，完成 typed evidence section contract。
- 本轮是否改变 canonical tail / endpoint：不改变 Renderer canonical endpoint；仍为 `CjguiInternalRendererStage892ComponentCommitApiRuntimeManagerReadiness`。
- 本轮是否改变 owner / truth / stop-line：新增 demo_support experimental section type；不改变 Renderer truth、runtime truth、state write stop-line 或 native stop-line。
- 本轮是否改变唯一 next opening：改变 CJGUI minimal UI framework next opening，转向 evidence section builder / profile-run assembly；Renderer next opening 不变。
- 是否同步 topic manifest：本轮为 demo_support ordinary report，未同步 Renderer topic manifest；当前变化不改变 Renderer implementation admission、backend readiness 或 macOS smoke 主题状态。
- 已同步哪些 topic manifest：无。

## 后续入口

下一步建议进入：

`P1 CJGUI shared demo_support evidence section builder for profile/run assembly`

原因：typed section 已经统一 profile 与 shared execution proof，但每个 demo 仍手写 profile + section assembly。下一步可以把 section builder / factory 下沉到 `demo_support`，继续减少 demo-local 尾部模板，同时保留各 demo 的业务 facts 与 before / after / readback 证据。

## 下游接续

已由 [shared demo evidence section builder report](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-06-21-p1-cjgui-shared-demo-support-evidence-section-builder-report.md) 接续；当前全部 10 个 runnable demo 已改为通过 `CjguiExperimentalDemoEvidenceSectionBuilder` 统一创建 profile、追加 facts 并生成 typed section。当前下一步转为：

`P1 CJGUI shared demo_support evidence fact bundle presets for state/readback/interaction facts`

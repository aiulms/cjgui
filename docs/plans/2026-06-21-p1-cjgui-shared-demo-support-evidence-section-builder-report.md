# CJGUI shared demo evidence section builder 报告

日期：2026-06-21

状态：已完成 / demo_support 复用收敛 / 不改变 Renderer truth

## 本次推进

本次让 `CjguiExperimentalDemoEvidenceSectionBuilder` 成为当前 10 个 runnable demo 的 shared profile / section assembly 入口。它把 `CjguiExperimentalDemoEvidenceProfile(...)` 创建、业务 fact 追加与 `CjguiExperimentalDemoEvidenceSection(...)` 创建下沉到 `demo_support`，demo 只保留各自业务 fact 与 shared run / commit 输入。

这让 Todo、Settings、Chat、FileBrowser、AI-generated UI、Shared demo harness、Shared multi-demo harness、Shared layout/style/input/focus contract、AI-generated UI shared contract 与 Reusable component contract 不再直接 new profile / section；它们统一调用 `evidenceBuilder.buildSection(...)` 后交给 `CjguiExperimentalDemoEvidencePresenter.printEvidenceSection(...)` 输出 evidence。

## 代码证据

- 新增 [runtime_cjgui_experimental_demo_evidence_section_builder.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/demo_support/runtime_cjgui_experimental_demo_evidence_section_builder.cj)，提供 `CjguiExperimentalDemoEvidenceSectionBuilder`、`addStaticBoolFact(...)`、`addTextFact(...)`、`addBoolFact(...)` 与 `buildSection(...)`。
- 当前 10 个 runnable demo 全部 import `CjguiExperimentalDemoEvidenceSectionBuilder`，并用 `evidenceBuilder.add*Fact(...)` 与 `evidenceBuilder.buildSection(...)` 完成 evidence section assembly。
- 10 个 focused verifier 与 aggregate verifier 均复制 builder source 到临时 `cjgui.demo_support` package，要求 builder declaration / demo usage，并拒绝 demo 回退到 direct `CjguiExperimentalDemoEvidenceProfile(...)` 或 direct `CjguiExperimentalDemoEvidenceSection(...)` constructor。

## 验证结果

- [verify_cjgui_todo_demo_app.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_cjgui_todo_demo_app.sh)：通过，实际编译并运行 Todo demo binary，回显 `todo_owner_local_write_readback=true`、`todo_shared_run_readback=true` 与 `todo_shared_run_not_published=true`。
- [verify_cjgui_shared_demo_run_harness.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_cjgui_shared_demo_run_harness.sh)：通过，实际编译并运行当前全部 10 个 demo binary。
- `cjpm build --target-dir /tmp/cjgui-shared-demo-evidence-section-builder-target --skip-script`：通过，仅保留既有 unused / stack-frame warnings。

Aggregate verifier 新增并回显：

- `cjgui_shared_demo_evidence_section_builder=CjguiExperimentalDemoEvidenceSectionBuilder`
- `cjgui_shared_demo_evidence_section_builder_demo_count=10`
- `cjgui_shared_demo_evidence_section_builder_profile_run_assembly_shared=true`
- `cjgui_shared_demo_direct_profile_and_section_constructors_retired=true`

这些 facts 证明 profile / section assembly 已经共享；它们不证明 Renderer backend、native bridge、state store、public C ABI 或 production render truth。

## 边界

- 不新增 public C ABI。
- 不修改 production native bridge。
- 不写 `runtime_state.cj`。
- 不写 renderer state。
- 不修改 `runtime/cjgui/cjpm.toml`。
- 不把 demo stdout evidence 解释成 Renderer canonical tail、backend-ready truth 或 production render truth。
- `CjguiExperimentalDemoEvidenceSectionBuilder` 只服务 experimental demo_support 复用路径，不是稳定 toolkit surface。

## 设计意图出口自检

- 本轮是否改变主题状态：改变 CJGUI minimal UI framework demo_support 复用状态，完成 evidence section builder / profile-run assembly。
- 本轮是否改变 canonical tail / endpoint：不改变 Renderer canonical endpoint；仍为 `CjguiInternalRendererStage892ComponentCommitApiRuntimeManagerReadiness`。
- 本轮是否改变 owner / truth / stop-line：新增 demo_support experimental builder type；不改变 Renderer truth、runtime truth、state write stop-line 或 native stop-line。
- 本轮是否改变唯一 next opening：改变 CJGUI minimal UI framework next opening，转向 shared evidence fact preset / bundle builder。
- 是否同步 topic manifest：本轮为 demo_support ordinary report，未同步 Renderer topic manifest；当前变化不改变 Renderer implementation admission、backend readiness 或 macOS smoke 主题状态。
- 已同步哪些 topic manifest：无。

## 后续入口

下一步建议进入：

`P1 CJGUI shared demo_support evidence fact bundle presets for state/readback/interaction facts`

原因：profile / section assembly 已经共享，但每个 demo 仍重复手写 `interaction`、`state_before`、`state_after`、`state_readback` 等常见业务 facts。下一步可以把这些高频 evidence fact preset 下沉到 shared `demo_support`，继续减少 demo-local 模板，同时保留各 demo 的真实 before / after / readback 业务证据。

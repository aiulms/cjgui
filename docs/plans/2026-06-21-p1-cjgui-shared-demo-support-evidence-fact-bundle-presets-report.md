# CJGUI shared demo evidence fact bundle presets 报告

日期：2026-06-21

状态：已完成 / demo_support fact preset 复用收敛 / 不改变 Renderer truth

## 本次推进

本次让 `CjguiExperimentalDemoEvidenceSectionBuilder` 从“profile / section assembly builder”前进为当前 10 个 runnable demo 的 common evidence fact preset 入口。

新增并被 demo 实际消费的 preset：

- `addInteractionFact(...)`：统一 `interaction` fact。
- `addStateReadbackFacts(...)`：统一 `state_before` / `state_after` / `state_readback` fact bundle。
- `addOwnerLocalWriteReadbackFacts(...)`：统一 Todo 风格 `summary_before` / `summary_after_add` / `summary_after_complete` / `owner_local_write_readback` fact bundle，并保持输出顺序。

Todo、Settings、Chat、FileBrowser、AI-generated UI、Shared demo harness、Shared multi-demo harness、Shared layout/style/input/focus contract、AI-generated UI shared contract 与 Reusable component contract 现在都通过 shared preset 写入 interaction 与 readback facts；demo-local direct `evidenceBuilder.addTextFact("interaction", ...)`、`evidenceBuilder.addBoolFact("state_readback", ...)` 和 `evidenceBuilder.addBoolFact("owner_local_write_readback", ...)` 已退役。

## 红绿验证

先更新 aggregate verifier，要求 builder declaration / demo usage，并拒绝旧 direct interaction/readback wiring。实现前运行 [verify_cjgui_shared_demo_run_harness.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_cjgui_shared_demo_run_harness.sh) 得到预期红灯：

```text
cjgui shared demo run harness verification: missing expected evidence section builder declarations
```

随后实现 builder preset、迁移 10 个 demo、同步 focused verifier 后，aggregate verifier 通过并实际编译 / 运行 10 个 demo binary。

## 代码证据

- [runtime_cjgui_experimental_demo_evidence_section_builder.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/demo_support/runtime_cjgui_experimental_demo_evidence_section_builder.cj) 新增 `addInteractionFact(...)`、`addStateReadbackFacts(...)` 与 `addOwnerLocalWriteReadbackFacts(...)`。
- 当前 10 个 runnable demo 全部调用 `evidenceBuilder.addInteractionFact(...)`，并调用 `addStateReadbackFacts(...)` 或 `addOwnerLocalWriteReadbackFacts(...)`。
- 10 个 focused verifier 与 aggregate verifier 均要求 shared preset declaration / demo usage，并拒绝旧 direct interaction / readback fact wiring 回退。

## 验证结果

- [verify_cjgui_shared_demo_run_harness.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_cjgui_shared_demo_run_harness.sh)：通过，实际编译并运行当前全部 10 个 demo binary。

Aggregate verifier 新增并回显：

- `cjgui_shared_demo_evidence_fact_presets=CjguiExperimentalDemoEvidenceSectionBuilder`
- `cjgui_shared_demo_evidence_fact_preset_demo_count=10`
- `cjgui_shared_demo_interaction_fact_preset_shared=true`
- `cjgui_shared_demo_state_readback_fact_bundle_shared=true`
- `cjgui_shared_demo_direct_interaction_state_readback_fact_calls_retired=true`

这些 facts 证明 interaction / state readback evidence bundle 已经共享；它们不证明 Renderer backend、native bridge、state store、public C ABI 或 production render truth。

## 边界

- 不新增 public C ABI。
- 不修改 production native bridge。
- 不写 `runtime_state.cj`。
- 不写 renderer state。
- 不修改 `runtime/cjgui/cjpm.toml`。
- 不把 demo stdout evidence 解释成 Renderer canonical tail、backend-ready truth 或 production render truth。
- `CjguiExperimentalDemoEvidenceSectionBuilder` 仍只服务 experimental demo_support 复用路径，不是稳定 toolkit surface。

## 设计意图出口自检

- 本轮是否改变主题状态：改变 CJGUI minimal UI framework demo_support 复用状态，完成 high-frequency evidence fact presets。
- 本轮是否改变 canonical tail / endpoint：不改变 Renderer canonical endpoint；仍为 `CjguiInternalRendererStage892ComponentCommitApiRuntimeManagerReadiness`。
- 本轮是否改变 owner / truth / stop-line：扩展 demo_support experimental builder type；不改变 Renderer truth、runtime truth、state write stop-line 或 native stop-line。
- 本轮是否改变唯一 next opening：改变 CJGUI minimal UI framework next opening，转向 domain evidence presets。
- 是否同步 topic manifest：本轮为 demo_support ordinary report，未同步 Renderer topic manifest；当前变化不改变 Renderer implementation admission、backend readiness 或 macOS smoke 主题状态。
- 已同步哪些 topic manifest：无。

## 后续入口

下一步建议进入：

`P1 CJGUI shared demo_support domain evidence presets for layout/served/reuse facts`

原因：interaction 与 state/readback high-frequency facts 已经共享；剩余 demo-local `layout`、`controls`、`served_demo(s)`、`reused_demos`、`component_kinds` 等 domain facts 仍可继续下沉为更语义化的 shared demo_support presets，进一步减少 demo-local boilerplate，同时保持真实 before / after / readback 业务证据。

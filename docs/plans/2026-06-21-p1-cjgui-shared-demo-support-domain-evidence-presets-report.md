# CJGUI shared demo_support domain evidence presets 报告

日期：2026-06-21

状态：已完成 / demo_support domain fact preset 复用收敛 / 不改变 Renderer truth

## 本次推进

本次让 `CjguiExperimentalDemoEvidenceSectionBuilder` 继续从 high-frequency interaction / readback preset 前进到 demo domain evidence preset。

新增并被 demo 实际消费的 preset：

- `addLayoutFact(...)`：统一 `layout` fact，覆盖 Settings、Chat、FileBrowser 与 AI-generated UI。
- `addControlsFact(...)`：统一 Settings 的 `controls` fact。
- `addServedDemoFact(...)`：统一 single demo harness 的 `served_demo` fact。
- `addServedDemosFacts(...)`：统一 multi-demo harness 的 `served_demos` / `served_demo_count` fact bundle。
- `addReusableComponentFacts(...)`：统一 Reusable component contract 的 `reused_demos` / `component_kinds` fact bundle。

这让 layout / controls / served / reuse 这些 domain facts 从 demo-local direct `addTextFact(...)` 迁到 shared `demo_support`。输出 key、顺序和 demo binary 行为保持不变，但 assembly 入口现在由 shared builder 负责。

## 红绿验证

先更新 aggregate verifier，要求 builder declaration、demo usage，并拒绝旧 direct domain fact wiring。实现前运行 [verify_cjgui_shared_demo_run_harness.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_cjgui_shared_demo_run_harness.sh) 得到预期红灯：

```text
cjgui shared demo run harness verification: missing expected evidence section builder declarations
```

随后实现 builder preset、迁移相关 demo、同步 focused verifier 后，aggregate verifier 通过并实际编译 / 运行当前 10 个 demo binary。

## 代码证据

- [runtime_cjgui_experimental_demo_evidence_section_builder.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/demo_support/runtime_cjgui_experimental_demo_evidence_section_builder.cj) 新增 `addLayoutFact(...)`、`addControlsFact(...)`、`addServedDemoFact(...)`、`addServedDemosFacts(...)` 与 `addReusableComponentFacts(...)`。
- Settings、Chat、FileBrowser 与 AI-generated UI 现在通过 `addLayoutFact(...)` 写入 layout fact。
- Settings 通过 `addControlsFact(...)` 写入 controls fact。
- Shared demo harness 通过 `addServedDemoFact(...)` 写入 served demo fact。
- Shared multi-demo harness 通过 `addServedDemosFacts(...)` 写入 served demos fact bundle。
- Reusable component contract 通过 `addReusableComponentFacts(...)` 写入 reused demos / component kinds fact bundle。
- 相关 focused verifier 与 aggregate verifier 均要求 shared domain preset declaration / usage，并拒绝旧 direct domain fact wiring 回退。

## 验证结果

- [verify_cjgui_shared_demo_run_harness.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_cjgui_shared_demo_run_harness.sh)：通过，实际编译并运行当前全部 10 个 demo binary。

Aggregate verifier 新增并回显：

- `cjgui_shared_demo_domain_fact_presets=CjguiExperimentalDemoEvidenceSectionBuilder`
- `cjgui_shared_demo_domain_fact_preset_layout_demo_count=4`
- `cjgui_shared_demo_domain_fact_preset_served_demo_count=2`
- `cjgui_shared_demo_domain_fact_preset_reuse_demo_count=1`
- `cjgui_shared_demo_direct_domain_fact_wiring_retired=true`

这些 facts 证明 layout / controls / served / reuse domain evidence assembly 已经共享；它们不证明 Renderer backend、native bridge、state store、public C ABI 或 production render truth。

## 边界

- 不新增 public C ABI。
- 不修改 production native bridge。
- 不写 `runtime_state.cj`。
- 不写 renderer state。
- 不修改 `runtime/cjgui/cjpm.toml`。
- 不把 demo stdout evidence 解释成 Renderer canonical tail、backend-ready truth 或 production render truth。
- `CjguiExperimentalDemoEvidenceSectionBuilder` 仍只服务 experimental demo_support 复用路径，不是稳定 toolkit surface。

## 设计意图出口自检

- 本轮是否改变主题状态：改变 CJGUI minimal UI framework demo_support 复用状态，完成 domain evidence fact presets。
- 本轮是否改变 canonical tail / endpoint：不改变 Renderer canonical endpoint；仍为 `CjguiInternalRendererStage892ComponentCommitApiRuntimeManagerReadiness`。
- 本轮是否改变 owner / truth / stop-line：扩展 demo_support experimental builder type；不改变 Renderer truth、runtime truth、state write stop-line 或 native stop-line。
- 本轮是否改变唯一 next opening：改变 CJGUI minimal UI framework next opening，转向 semantic domain evidence value model。
- 是否同步 topic manifest：本轮为 demo_support ordinary report，未同步 Renderer topic manifest；当前变化不改变 Renderer implementation admission、backend readiness 或 macOS smoke 主题状态。
- 已同步哪些 topic manifest：无。

## 后续入口

下一步建议进入：

`P1 CJGUI shared demo_support semantic evidence value model for layout/control/served/reuse facts`

原因：domain fact key 的 assembly 已经共享；下一步应减少裸字符串事实在 demo 中散落，把 layout、controls、served demo、reused component kinds 进一步收敛为 typed / semantic demo_support value model，继续让 demo 更像运行在同一条 framework 主路径上，而不是复制 evidence 字符串模板。

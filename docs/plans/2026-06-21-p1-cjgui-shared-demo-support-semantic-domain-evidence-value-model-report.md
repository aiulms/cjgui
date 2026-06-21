# CJGUI shared demo_support semantic domain evidence value model 报告

日期：2026-06-21

状态：已完成 / semantic domain evidence value model / 10 个 demo runnable 回归通过

## 本次推进

本次让 `demo_support` 从“domain fact 字符串 preset”继续前进到 typed semantic evidence value model。

新增 shared 类型：

- `CjguiExperimentalDemoLayoutEvidence`
- `CjguiExperimentalDemoControlsEvidence`
- `CjguiExperimentalDemoServedDemoEvidence`
- `CjguiExperimentalDemoServedDemosEvidence`
- `CjguiExperimentalDemoReusableComponentEvidence`

`CjguiExperimentalDemoEvidenceSectionBuilder` 新增 typed API：

- `addLayoutEvidence(...)`
- `addControlsEvidence(...)`
- `addServedDemoEvidence(...)`
- `addServedDemosEvidence(...)`
- `addReusableComponentEvidence(...)`

Settings、Chat、FileBrowser、AI-generated UI、Shared demo harness、Shared multi-demo harness 与 Reusable component contract 已迁移到 semantic evidence object；demo 不再直接调用 `addLayoutFact(...)` / `addServedDemoFact(...)` 等字符串 domain preset。输出 key 与 stdout evidence 保持兼容，但 domain value 的入口已经从裸字符串模板变成 shared typed value。

## 红绿验证

先更新 aggregate verifier，要求新增 [runtime_cjgui_experimental_demo_domain_evidence.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/demo_support/runtime_cjgui_experimental_demo_domain_evidence.cj)、builder typed API、demo typed usage，并拒绝旧字符串 domain preset 调用。实现前运行 [verify_cjgui_shared_demo_run_harness.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_cjgui_shared_demo_run_harness.sh) 得到预期红灯：

```text
cjgui shared demo run harness verification: missing semantic domain evidence source /Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/demo_support/runtime_cjgui_experimental_demo_domain_evidence.cj
```

实现后 aggregate verifier 通过，并实际编译 / 运行当前全部 10 个 demo binary。

## 代码证据

- [runtime_cjgui_experimental_demo_domain_evidence.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/demo_support/runtime_cjgui_experimental_demo_domain_evidence.cj) 新增 typed semantic value model。
- [runtime_cjgui_experimental_demo_evidence_section_builder.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/demo_support/runtime_cjgui_experimental_demo_evidence_section_builder.cj) 新增 typed `add*Evidence(...)` API，并把 typed value 脱水为现有 stdout facts。
- Settings 使用 `CjguiExperimentalDemoLayoutEvidence` 与 `CjguiExperimentalDemoControlsEvidence`。
- Chat、FileBrowser 与 AI-generated UI 使用 `CjguiExperimentalDemoLayoutEvidence`。
- Shared demo harness 使用 `CjguiExperimentalDemoServedDemoEvidence`。
- Shared multi-demo harness 使用 `CjguiExperimentalDemoServedDemosEvidence`。
- Reusable component contract 使用 `CjguiExperimentalDemoReusableComponentEvidence`。

## 验证结果

- [verify_cjgui_shared_demo_run_harness.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_cjgui_shared_demo_run_harness.sh)：通过，实际编译并运行当前全部 10 个 demo binary。
- 10 个 focused demo verifier：通过，分别实际编译并运行 Todo、Settings、Chat、FileBrowser、AI-generated UI、Shared demo harness、Shared multi-demo harness、Shared layout/style/input/focus contract、AI-generated UI shared contract 与 Reusable component contract。
- `cjpm build --target-dir /tmp/cjgui-shared-demo-semantic-domain-evidence-target --skip-script`：通过；仍有既有 unused / stack-frame warnings，本次没有新增编译错误。
- Source scan：demo 中旧 `evidenceBuilder.addLayoutFact(...)`、`addControlsFact(...)`、`addServedDemoFact(...)`、`addServedDemosFacts(...)` 与 `addReusableComponentFacts(...)` 调用为 `0`。
- Protected path scan：`runtime/cjgui/src/runtime_state.cj` 仍为 `10065` 行；`runtime_state.cj`、`runtime/cjgui/cjpm.toml`、production native bridge 与 smoke native files 未修改。

Aggregate verifier 新增并回显：

- `cjgui_shared_demo_semantic_domain_evidence_model=CjguiExperimentalDemoDomainEvidence`
- `cjgui_shared_demo_semantic_layout_evidence_demo_count=4`
- `cjgui_shared_demo_semantic_served_evidence_demo_count=2`
- `cjgui_shared_demo_semantic_reuse_evidence_demo_count=1`
- `cjgui_shared_demo_string_domain_fact_preset_calls_retired=true`

这些 facts 证明 layout / controls / served / reuse domain evidence value 已进入 shared typed model；它们不证明 Renderer backend、native bridge、state store、public C ABI 或 production render truth。

## 边界

- 不新增 public C ABI。
- 不修改 production native bridge。
- 不写 `runtime_state.cj`。
- 不写 renderer state。
- 不修改 `runtime/cjgui/cjpm.toml`。
- 不把 demo stdout evidence 解释成 Renderer canonical tail、backend-ready truth 或 production render truth。
- 新增 public declarations 仅限 experimental `cjgui.demo_support`，服务 demo_support 复用路径，不是稳定 toolkit surface。

## 设计意图出口自检

- 本轮是否改变主题状态：改变 CJGUI minimal UI framework demo_support 复用状态，完成 semantic domain evidence value model。
- 本轮是否改变 canonical tail / endpoint：不改变 Renderer canonical endpoint；仍为 `CjguiInternalRendererStage892ComponentCommitApiRuntimeManagerReadiness`。
- 本轮是否改变 owner / truth / stop-line：扩展 demo_support experimental value model；不改变 Renderer truth、runtime truth、state write stop-line 或 native stop-line。
- 本轮是否改变唯一 next opening：改变 CJGUI minimal UI framework next opening，转向 interaction/state semantic evidence value model。
- 是否同步 topic manifest：本轮为 demo_support ordinary report，未同步 Renderer topic manifest；当前变化不改变 Renderer implementation admission、backend readiness 或 macOS smoke 主题状态。
- 已同步哪些 topic manifest：无。

## 后续入口

下一步建议进入：

`P1 CJGUI shared demo_support semantic interaction/state evidence value model for component action/readback facts`

原因：domain evidence 已经从字符串 preset 进入 typed value model；下一步应继续减少 interaction、state_before / state_after / state_readback、owner-local write readback 这些高频 facts 的裸字符串入口，让 component action / readback evidence 更像 shared framework data path，而不是 demo-local evidence 模板。

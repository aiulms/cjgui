# CJGUI shared demo evidence profile 批量合同报告

日期：2026-06-21

状态：已完成 / demo_support 复用收敛 / 不改变 Renderer truth

## 本轮目标

本轮接续 `P1 CJGUI shared demo_support demo evidence profile contract for business fact batching`，把当前 10 个 runnable demo 中仍然重复的 `evidencePresenter.printTextFact` / `printBoolFact` / status transition 调用序列下沉到 shared `CjguiExperimentalDemoEvidenceProfile`。

这让 demo app 只声明“本次 run 的 identity、状态迁移、静态 facts 与业务 facts”，由 `CjguiExperimentalDemoEvidencePresenter.printEvidenceProfile(...)` 统一渲染 stdout evidence。业务 before / after / readback 内容保持不变，但 demo-local stdout 组织模板进一步减少。

## 落地内容

- 新增 [runtime_cjgui_experimental_demo_evidence_profile.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/demo_support/runtime_cjgui_experimental_demo_evidence_profile.cj)，提供 `CjguiExperimentalDemoEvidenceProfile`、`CjguiExperimentalDemoTextEvidenceFact` 与 `CjguiExperimentalDemoBoolEvidenceFact`。
- [runtime_cjgui_experimental_demo_evidence_presenter.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/demo_support/runtime_cjgui_experimental_demo_evidence_presenter.cj) 新增 `printEvidenceProfile(...)`，批量输出 demo identity、static bool facts、status transition、text facts 与 bool facts。
- 当前 10 个 runnable demo 全部改为构造 `CjguiExperimentalDemoEvidenceProfile`，再调用 `evidencePresenter.printEvidenceProfile(evidenceProfile)`；demo-local 直接 presenter fact 调用序列已退役。
- 当前 10 个 focused verifier 和 aggregate verifier 都新增 profile source / usage / copy 检查，并拒绝 demo-local presenter fact sequence 回退。

## 验证事实

本轮 aggregate verifier [verify_cjgui_shared_demo_run_harness.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_cjgui_shared_demo_run_harness.sh) 已实际编译并运行当前全部 10 个 demo binary，并回显：

- `cjgui_shared_demo_run_demo_count=10`
- `cjgui_shared_demo_run_binary_execution=true`
- `cjgui_shared_demo_run_readback=true`
- `cjgui_shared_demo_run_not_published=true`
- `cjgui_shared_demo_evidence_profile=CjguiExperimentalDemoEvidenceProfile`
- `cjgui_shared_demo_evidence_profile_demo_count=10`
- `cjgui_shared_demo_evidence_profile_business_fact_batching_shared=true`
- `cjgui_shared_demo_direct_presenter_fact_sequence_retired=true`
- `cjgui_shared_demo_direct_reporter_wiring_retired=true`

这些 facts 证明当前 10 个 demo 的业务 evidence profile batching 已经共享；它们不证明 Renderer backend、native bridge、state store、public C ABI 或 production render truth。

## 边界

- 不新增 public C ABI。
- 不修改 production native bridge。
- 不写 `runtime_state.cj`。
- 不写 renderer state。
- 不修改 `runtime/cjgui/cjpm.toml`。
- 不把 demo stdout evidence 解释成 Renderer canonical tail、backend-ready truth 或 production render truth。
- `CjguiExperimentalDemoEvidenceProfile` 只服务 demo_support experimental 复用路径，不是稳定 toolkit surface。

## 设计意图出口自检

- 本轮是否改变主题状态：改变 CJGUI minimal UI framework demo_support 复用状态，完成 evidence profile batching。
- 本轮是否改变 canonical tail / endpoint：不改变 Renderer canonical endpoint；仍为 `CjguiInternalRendererStage892ComponentCommitApiRuntimeManagerReadiness`。
- 本轮是否改变 owner / truth / stop-line：新增 demo_support experimental owner；不改变 Renderer truth、runtime truth、state write stop-line 或 native stop-line。
- 本轮是否改变唯一 next opening：改变 CJGUI minimal UI framework next opening，转向 typed evidence section / component-action-readback batching；Renderer next opening 不变。
- 是否同步 topic manifest：本轮为 demo_support ordinary report，未同步 Renderer topic manifest；当前变化不改变 Renderer implementation admission、backend readiness 或 macOS smoke 主题状态。
- 已同步哪些 topic manifest：无。

## 后续入口

下一步建议进入：

`P1 CJGUI shared demo_support typed evidence section contract for component/action/readback batching`

原因：profile 已经把每个 demo 的 text / bool / static facts 批量交给 shared presenter；下一步可以把 component action、commit/readback、shared run proof 进一步分成 typed evidence section，减少 demo-local “先构造 profile、再手动补 shared proof 参数”的尾部编排。

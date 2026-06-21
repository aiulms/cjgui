# CJGUI shared demo evidence presenter 收敛报告

日期：2026-06-21

状态：已完成 / demo_support 复用收敛 / 不改变 Renderer truth

## 本轮目标

本轮接续 `P1 CJGUI shared demo_support demo evidence presenter consolidation for reporter orchestration cleanup`，把当前 10 个 runnable demo 中反复出现的 metadata / business snapshot / proof / run result reporter 装配下沉到 shared `CjguiExperimentalDemoEvidencePresenter`。

这让 CJGUI 更接近一个可复用 framework：demo 仍然保留自己的业务 before / after 和 action 语义，但不再各自手写 reporter wiring。stdout evidence 的组织入口变成一个 shared presenter，而不是散落在每个 demo app 中的四套 reporter 变量。

## 落地内容

- 新增 [runtime_cjgui_experimental_demo_evidence_presenter.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/demo_support/runtime_cjgui_experimental_demo_evidence_presenter.cj)，提供 `CjguiExperimentalDemoEvidencePresenter`。
- 当前 10 个 runnable demo 全部改为通过 `CjguiExperimentalDemoEvidencePresenter` 渲染 demo identity、static facts、business facts、shared proof 与 run result。
- 当前 10 个 focused verifier 和 aggregate verifier 都新增 presenter 检查，并拒绝 demo-local direct reporter wiring 回退。
- aggregate verifier 实际编译并运行 10 个 demo binary，不是 grep-only 证据。

## 验证事实

本轮 aggregate verifier [verify_cjgui_shared_demo_run_harness.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_cjgui_shared_demo_run_harness.sh) 已回显：

- `cjgui_shared_demo_run_demo_count=10`
- `cjgui_shared_demo_run_binary_execution=true`
- `cjgui_shared_demo_run_readback=true`
- `cjgui_shared_demo_run_not_published=true`
- `cjgui_shared_demo_evidence_presenter=CjguiExperimentalDemoEvidencePresenter`
- `cjgui_shared_demo_evidence_presenter_demo_count=10`
- `cjgui_shared_demo_evidence_presenter_output_orchestration_shared=true`
- `cjgui_shared_demo_direct_reporter_wiring_retired=true`

这些 facts 证明当前 10 个 demo 的 evidence stdout orchestration 已经共享，但不证明 Renderer backend、native bridge、state store 或 public API readiness。

## 边界

- 不新增 public C ABI。
- 不修改 production native bridge。
- 不写 `runtime_state.cj`。
- 不写 renderer state。
- 不修改 `runtime/cjgui/cjpm.toml`。
- 不把 demo stdout evidence 解释成 Renderer canonical tail、backend-ready truth 或 production render truth。

## 后续入口

该入口已由 [shared demo evidence profile batching report](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-06-21-p1-cjgui-shared-demo-support-demo-evidence-profile-contract-batching-report.md) 接续；当前 10 个 runnable demo 已迁移到 `CjguiExperimentalDemoEvidenceProfile` 与 `printEvidenceProfile(...)`。

下一步建议进入：

`P1 CJGUI shared demo_support demo evidence profile contract for business fact batching`

原因：presenter 已经把 reporter wiring 收敛成一个 shared 入口，但每个 demo 里仍然存在多组 `printTextFact` / `printBoolFact` / status transition 的调用序列。下一步应引入 evidence profile / business fact batching，让 demo 描述“这一组业务事实”，而不是逐行组织 stdout presenter 调用。

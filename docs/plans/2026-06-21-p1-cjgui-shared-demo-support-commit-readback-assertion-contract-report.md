# CJGUI shared demo_support commit/readback assertion contract 报告

日期：2026-06-21

状态：已完成 / owner-local commit readback assertion contract / 10 个 demo runnable 回归通过

## 本次推进

本次让 shared `demo_support` 的 owner-local commit/readback 校验从 demo-local 长布尔表达式前进到 typed assertion contract。

新增 shared assertion primitive：

- `CjguiExperimentalDemoCommitReadbackExpectation`
- `CjguiExperimentalDemoCommitReadbackAssertion`
- `CjguiExperimentalDemoCommitHarness.assertCommitReadbackRoute(...)`

当前 10 个独立 runnable demo 都构造 `CjguiExperimentalDemoCommitReadbackExpectation`，并通过 `commitHarness.assertCommitReadbackRoute(...)` 同时校验 shared `CjguiExperimentalDemoOutput`、owner-local commit result、state readback 与 not-published 边界。demo-local direct `commitHarness.resultMatchesRoute(...)` 调用已经退役。

这让 Todo、Settings、Chat、FileBrowser、AI-generated UI、shared harness 与 reusable component contract 的 commit/readback evidence 继续下沉到 shared framework primitive，而不是每个 demo 自己拼一套 output / result / rollback 断言。

## 证据

- [runtime_cjgui_experimental_demo_owner_local_commit_session.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/demo_support/runtime_cjgui_experimental_demo_owner_local_commit_session.cj) 新增 `CjguiExperimentalDemoCommitReadbackExpectation`、`CjguiExperimentalDemoCommitReadbackAssertion` 与 `assertCommitReadbackRoute(...)`。
- Todo、Settings、Chat、FileBrowser、AI-generated UI、Shared demo harness、Shared multi-demo harness、Shared layout/style/input/focus contract、AI-generated UI shared contract 与 Reusable component contract 均新增 `commitExpectation` / `commitAssertion` 路径，并用 `commitAssertion.isSatisfied()` 替代 demo-local 长断言。
- [verify_cjgui_shared_demo_commit_write_readback.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_cjgui_shared_demo_commit_write_readback.sh) 与 [verify_cjgui_shared_demo_run_harness.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_cjgui_shared_demo_run_harness.sh) 均新增 assertion contract declaration、usage count 与 direct `resultMatchesRoute` retired 检查。

## 验证结果

- [verify_cjgui_shared_demo_commit_write_readback.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_cjgui_shared_demo_commit_write_readback.sh)：通过，实际编译并运行当前全部 10 个 demo binary；回显 `cjgui_shared_demo_commit_readback_assertion_usage_count=10`、`cjgui_shared_demo_commit_readback_expectation_usage_count=10` 与 `cjgui_shared_demo_direct_commit_result_matches_route_call_retired=true`。
- [verify_cjgui_shared_demo_run_harness.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_cjgui_shared_demo_run_harness.sh)：通过，实际编译并运行当前全部 10 个 demo binary；回显 `cjgui_shared_demo_commit_readback_expectation=CjguiExperimentalDemoCommitReadbackExpectation`、`cjgui_shared_demo_commit_readback_assertion=CjguiExperimentalDemoCommitReadbackAssertion`、`cjgui_shared_demo_run_binary_execution=true`、`cjgui_shared_demo_run_readback=true` 与 `cjgui_shared_demo_run_not_published=true`。
- 10 个 focused demo verifier：通过，分别实际编译并运行 Todo、Settings、Chat、FileBrowser、AI-generated UI、Shared demo harness、Shared multi-demo harness、Shared layout/style/input/focus contract、AI-generated UI shared contract 与 Reusable component contract；各自继续回显 shared commit readback / not-published / run readback 证据。
- `cjpm build --target-dir /tmp/cjgui-shared-demo-commit-readback-assertion-contract-target --skip-script`：通过；仍有既有 unused / stack-frame warnings，本次没有新增编译错误。
- CodeLattice：`changed_symbols` 看到 23 个 demo / script / demo_support 文件改动，但 Cangjie 新符号处于 stale baseline，`changedSymbolCount=0` 且 hunk 多为 unknown；按 graph coverage gap 处理，不作为安全证明或 blocker。

## 边界

- 不新增 public C ABI。
- 不修改 production native bridge。
- 不写 `runtime_state.cj`。
- 不写 renderer state。
- 不修改 `runtime/cjgui/cjpm.toml`。
- 不把 demo stdout evidence 解释成 Renderer canonical tail、backend-ready truth、state-store publication 或 production render truth。
- 新增 public declarations 仅限 experimental `cjgui.demo_support`，服务 demo_support 复用路径，不是稳定 toolkit surface。

## 同步结果

- 已同步 [README.md](/Users/jiangxuanyang/Desktop/cangjie/README.md)。
- 已同步 [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)。
- 已同步 [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)。
- 已同步 [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)。
- 已同步 [DESIGN_INTENT_INDEX.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/DESIGN_INTENT_INDEX.md)。
- 已同步 [CJGUI_DEMO_PROGRESS.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/CJGUI_DEMO_PROGRESS.md)。

## 设计意图出口自检

- 本轮是否改变主题状态：改变 CJGUI minimal UI framework demo_support 复用状态，完成 owner-local commit/readback assertion contract。
- 本轮是否改变 canonical tail / endpoint：不改变 Renderer canonical endpoint；仍为 `CjguiInternalRendererStage892ComponentCommitApiRuntimeManagerReadiness`。
- 本轮是否改变 owner / truth / stop-line：扩展 demo_support experimental commit/readback assertion contract；不改变 Renderer truth、runtime truth、state write stop-line 或 native stop-line。
- 本轮是否改变唯一 next opening：改变 CJGUI minimal UI framework next opening，转向 assertion facts 进入 typed evidence section。
- 是否同步 topic manifest：本轮为 demo_support ordinary report，未同步 Renderer topic manifest；当前变化不改变 Renderer implementation admission、backend readiness 或 macOS smoke 主题状态。
- 已同步哪些 topic manifest：无。

## 后续入口

下一步建议进入：

`P1 CJGUI shared demo_support commit/readback assertion evidence section integration for owner-local result facts`

原因：commit/readback assertion 已进入 shared harness，但 assertion summary 仍只作为局部 Bool 输入 run result。下一步应把 `CjguiExperimentalDemoCommitReadbackAssertion` 作为 typed evidence section fact 输入，让 shared presenter 输出 assertion facts，继续减少 demo-local owner-local result proof 模板。

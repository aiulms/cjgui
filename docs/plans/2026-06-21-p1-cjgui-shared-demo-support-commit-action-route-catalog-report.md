# CJGUI shared demo_support commit action route catalog 报告

日期：2026-06-21

状态：已完成 / owner-local commit route catalog / 10 个 demo runnable 回归通过

## 本次推进

本次让 shared `demo_support` 的 owner-local commit harness 从 demo-local `(componentId, action)` 字符串调用前进到 typed commit route value 与 shared catalog。

新增 shared commit route primitive：

- `CjguiExperimentalDemoCommitActionRoute`
- `CjguiExperimentalDemoCommitActionRouteCatalog`

当前 10 个独立 runnable demo 都通过 `commitRouteCatalog.*` 取得 commit route，并调用 `commitHarness.commitComponentActionRoute(...)` 与 `commitHarness.resultMatchesRoute(...)` 完成 owner-local commit / readback / rollback 校验。demo 侧 direct `commitHarness.commitComponentAction("...", "...", ...)` 字符串调用已经退役。

这让 Todo、Settings、Chat、FileBrowser、AI-generated UI、shared harness 与 reusable component contract 的 commit evidence 也走 shared framework primitive，和上一轮 component/action route catalog 对齐。

## 证据

- [runtime_cjgui_experimental_demo_owner_local_commit_session.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/demo_support/runtime_cjgui_experimental_demo_owner_local_commit_session.cj) 新增 `CjguiExperimentalDemoCommitActionRoute`、`CjguiExperimentalDemoCommitActionRouteCatalog`、`commitComponentActionRoute(...)` 与 `resultMatchesRoute(...)`。
- Todo、Settings、Chat、FileBrowser、AI-generated UI、Shared demo harness、Shared multi-demo harness、Shared layout/style/input/focus contract、AI-generated UI shared contract 与 Reusable component contract 均新增 `commitRouteCatalog`，并用 catalog route 替代 direct commit string call。
- [verify_cjgui_shared_demo_commit_write_readback.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_cjgui_shared_demo_commit_write_readback.sh) 与 [verify_cjgui_shared_demo_run_harness.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_cjgui_shared_demo_run_harness.sh) 均新增 commit route catalog declaration、usage count 与 direct string call retired 检查。

## 验证结果

- [verify_cjgui_shared_demo_commit_write_readback.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_cjgui_shared_demo_commit_write_readback.sh)：通过，实际编译并运行当前全部 10 个 demo binary；回显 `cjgui_shared_demo_commit_action_route_usage_count=10`、`cjgui_shared_demo_commit_action_route_match_usage_count=10`、`cjgui_shared_demo_commit_action_route_catalog_usage_count=10` 与 `cjgui_shared_demo_direct_commit_component_action_string_call_retired=true`。
- [verify_cjgui_shared_demo_run_harness.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_cjgui_shared_demo_run_harness.sh)：通过，实际编译并运行当前全部 10 个 demo binary；回显 `cjgui_shared_demo_commit_action_route_model=CjguiExperimentalDemoCommitActionRoute` 与 `cjgui_shared_demo_commit_action_route_catalog=CjguiExperimentalDemoCommitActionRouteCatalog`。
- 10 个 focused demo verifier：通过，分别实际编译并运行 Todo、Settings、Chat、FileBrowser、AI-generated UI、Shared demo harness、Shared multi-demo harness、Shared layout/style/input/focus contract、AI-generated UI shared contract 与 Reusable component contract。
- `cjpm build --target-dir /tmp/cjgui-shared-demo-commit-action-route-catalog-target --skip-script`：通过；仍有既有 unused / stack-frame warnings，本次没有新增编译错误。
- CodeLattice：`CjguiExperimentalDemoCommitHarness` / `CjguiExperimentalDemoCommitActionRoute` 静态图谱处于 stale baseline，新增 Cangjie symbol 未被索引；按 graph coverage gap 处理，不作为安全证明或 blocker。

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

- 本轮是否改变主题状态：改变 CJGUI minimal UI framework demo_support 复用状态，完成 owner-local commit action route catalog。
- 本轮是否改变 canonical tail / endpoint：不改变 Renderer canonical endpoint；仍为 `CjguiInternalRendererStage892ComponentCommitApiRuntimeManagerReadiness`。
- 本轮是否改变 owner / truth / stop-line：扩展 demo_support experimental commit route catalog；不改变 Renderer truth、runtime truth、state write stop-line 或 native stop-line。
- 本轮是否改变唯一 next opening：改变 CJGUI minimal UI framework next opening，转向 commit/readback assertion contract。
- 是否同步 topic manifest：本轮为 demo_support ordinary report，未同步 Renderer topic manifest；当前变化不改变 Renderer implementation admission、backend readiness 或 macOS smoke 主题状态。
- 已同步哪些 topic manifest：无。

## 后续入口

下一步建议进入：

`P1 CJGUI shared demo_support commit/readback assertion contract for owner-local result checks`

原因：commit route spelling 已进入 shared catalog，但 10 个 demo 仍各自拼接 `commitReadbackOk = stateReadbackOk && apiOutput... && resultMatchesRoute(...)` 的长断言。下一步应把 commit result、shared output readback、rollback / not-published 组合校验继续下沉到 shared `demo_support`，减少 demo-local owner-local commit assertion 模板。

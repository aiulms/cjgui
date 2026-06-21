# CJGUI shared demo_support component action route catalog 报告

日期：2026-06-21

状态：已完成 / component action route catalog / 10 个 demo runnable 回归通过

## 本次推进

本次把上一轮已经 typed 化的 component/action route spelling 继续下沉到 shared `demo_support` catalog。

新增 shared route catalog：

- `CjguiExperimentalDemoComponentActionRouteCatalog`

当前 10 个独立 runnable demo 都持有 `routeCatalog: CjguiExperimentalDemoComponentActionRouteCatalog`，并通过命名 route factory 调用 `recordComponentActionRoute(...)`。demo 侧 direct `CjguiExperimentalDemoComponentActionRoute("...", "...")` 构造已经退役。

这让 Todo、Settings、Chat、FileBrowser、AI-generated UI、shared harness 与 reusable component contract 的 component/action spelling 从 demo-local 字符串表变成 shared framework primitive。后续新增 demo 可以复用 catalog route，而不是复制 route 字符串。

## 红绿验证

先更新 aggregate verifier，要求：

- `CjguiExperimentalDemoComponentActionRouteCatalog` 存在。
- catalog 至少暴露 Todo、Settings、Chat、FileBrowser、AI-generated UI 的代表 route factory。
- 10 个 demo 都 import / 使用 route catalog。
- demo 侧 direct `CjguiExperimentalDemoComponentActionRoute(...)` 构造退役。

实现前运行 [verify_cjgui_shared_demo_run_harness.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_cjgui_shared_demo_run_harness.sh) 得到预期红灯：

```text
cjgui shared demo run harness verification: missing component action route value model declarations
```

实现后 aggregate verifier 通过，并实际编译 / 运行当前全部 10 个 demo binary。

## 代码证据

- [runtime_cjgui_experimental_demo_component_action_session.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/demo_support/runtime_cjgui_experimental_demo_component_action_session.cj) 新增 `CjguiExperimentalDemoComponentActionRouteCatalog`。
- [verify_cjgui_shared_demo_run_harness.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_cjgui_shared_demo_run_harness.sh) 新增 route catalog 声明、usage count、direct constructor 退役检查。
- Todo、Settings、Chat、FileBrowser、AI-generated UI、Shared demo harness、Shared multi-demo harness、Shared layout/style/input/focus contract、AI-generated UI shared contract 与 Reusable component contract 均通过 `routeCatalog.*` 取得 route value。

## 验证结果

- [verify_cjgui_shared_demo_run_harness.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_cjgui_shared_demo_run_harness.sh)：通过，实际编译并运行当前全部 10 个 demo binary。
- 10 个 focused demo verifier：通过，分别实际编译并运行 Todo、Settings、Chat、FileBrowser、AI-generated UI、Shared demo harness、Shared multi-demo harness、Shared layout/style/input/focus contract、AI-generated UI shared contract 与 Reusable component contract。
- `cjpm build --target-dir /tmp/cjgui-shared-demo-component-action-route-catalog-target --skip-script`：通过；仍有既有 unused / stack-frame warnings，本次没有新增编译错误。
- Source scan：demo 侧 direct `CjguiExperimentalDemoComponentActionRoute(...)` 构造为 `0`。
- Route catalog usage scan：demo 侧 `routeCatalog.*` 为 `41`。
- Protected path scan：`runtime/cjgui/src/runtime_state.cj` 仍为 `10065` 行；`runtime_state.cj`、`runtime/cjgui/cjpm.toml`、production native bridge 与 smoke native files 未修改。
- CodeLattice：`CjguiExperimentalDemoComponentActionRouteCatalog` before-edit / changed-symbols 仅提供 static-only evidence，当前图谱对新增 Cangjie symbol 覆盖有限，不能替代 runtime verifier / build。
- GitNexus `detect-changes --repo cangjie-live-codelattice --scope unstaged`：`Affected processes: 0` / `Risk level: low`；同样只作为辅助交叉检查。

Aggregate verifier 新增并回显：

- `cjgui_shared_demo_component_action_route_catalog=CjguiExperimentalDemoComponentActionRouteCatalog`
- `cjgui_shared_demo_component_action_route_catalog_usage_count=41`
- `cjgui_shared_demo_direct_component_action_route_constructor_retired=true`

这些 facts 证明 component/action route spelling 已进入 shared catalog；它们不证明 Renderer backend、native bridge、state store、public C ABI 或 production render truth。

## 同步结果

- 已同步 [README.md](/Users/jiangxuanyang/Desktop/cangjie/README.md)。
- 已同步 [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)。
- 已同步 [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)。
- 已同步 [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)。
- 已同步 [DESIGN_INTENT_INDEX.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/DESIGN_INTENT_INDEX.md)。
- 已同步 [CJGUI_DEMO_PROGRESS.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/CJGUI_DEMO_PROGRESS.md)。

## 边界

- 不新增 public C ABI。
- 不修改 production native bridge。
- 不写 `runtime_state.cj`。
- 不写 renderer state。
- 不修改 `runtime/cjgui/cjpm.toml`。
- 不把 demo stdout evidence 解释成 Renderer canonical tail、backend-ready truth 或 production render truth。
- 新增 public declarations 仅限 experimental `cjgui.demo_support`，服务 demo_support 复用路径，不是稳定 toolkit surface。

## 设计意图出口自检

- 本轮是否改变主题状态：改变 CJGUI minimal UI framework demo_support 复用状态，完成 component action route catalog。
- 本轮是否改变 canonical tail / endpoint：不改变 Renderer canonical endpoint；仍为 `CjguiInternalRendererStage892ComponentCommitApiRuntimeManagerReadiness`。
- 本轮是否改变 owner / truth / stop-line：扩展 demo_support experimental route catalog；不改变 Renderer truth、runtime truth、state write stop-line 或 native stop-line。
- 本轮是否改变唯一 next opening：改变 CJGUI minimal UI framework next opening，转向 commit harness action route catalog。
- 是否同步 topic manifest：本轮为 demo_support ordinary report，未同步 Renderer topic manifest；当前变化不改变 Renderer implementation admission、backend readiness 或 macOS smoke 主题状态。
- 已同步哪些 topic manifest：无。

## 后续入口

下一步建议进入：

`P1 CJGUI shared demo_support commit action route catalog for owner-local commit harness`

原因：component/action session route spelling 已经由 shared catalog 托住，但 `commitHarness.commitComponentAction(componentId, action, afterState)` 仍由 demo 侧传入 component/action 字符串。下一步应把 commit harness action route 也收敛成 shared value / catalog，让 owner-local commit evidence 和 component action evidence 走同一类可复用 route primitive。

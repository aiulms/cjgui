# CJGUI shared demo_support component action route value model 报告

日期：2026-06-21

状态：已完成 / component action route value model / 10 个 demo runnable 回归通过

## 本次推进

本次让 `demo_support` 的 component/action recording 从 demo-local 三参字符串入口继续前进到 typed route value。

新增 shared 类型：

- `CjguiExperimentalDemoComponentActionRoute`

`CjguiExperimentalDemoComponentActionSession` 新增 typed API：

- `recordComponentActionRoute(route: CjguiExperimentalDemoComponentActionRoute, afterState: String)`

当前 10 个独立 runnable demo 都改为构造 `CjguiExperimentalDemoComponentActionRoute`，再通过 `recordComponentActionRoute(...)` 记录 component identity、action name 与 after-state readback。旧 `recordComponentAction(componentId, action, afterState)` 仍保留为兼容委托，但 demo 侧 direct string recording 已退役。

这让 component/action route 不再只是散落在每个 demo 的裸字符串三参调用里，而是进入 shared framework data path。后续可以继续把 route 字符串提升为 shared catalog / factory，不必再逐个 demo 发明 route spelling。

## 红绿验证

先更新 aggregate verifier，要求：

- `CjguiExperimentalDemoComponentActionRoute` 存在。
- `recordComponentActionRoute(...)` 存在。
- `componentIdValue()`、`actionValue()` 与 `routeValue()` 存在。
- 10 个 demo 都 import / 使用 route value。
- demo 侧 `componentSession.recordComponentAction(...)` 直接三参调用退役。

实现前运行 [verify_cjgui_shared_demo_run_harness.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_cjgui_shared_demo_run_harness.sh) 得到预期红灯：

```text
cjgui shared demo run harness verification: missing component action route value model declarations
```

实现后 aggregate verifier 通过，并实际编译 / 运行当前全部 10 个 demo binary。

## 代码证据

- [runtime_cjgui_experimental_demo_component_action_session.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/demo_support/runtime_cjgui_experimental_demo_component_action_session.cj) 新增 `CjguiExperimentalDemoComponentActionRoute` 与 `recordComponentActionRoute(...)`。
- [verify_cjgui_shared_demo_run_harness.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_cjgui_shared_demo_run_harness.sh) 新增 route value model 声明、demo usage、direct string recording 退役检查。
- Todo、Settings、Chat、FileBrowser、AI-generated UI、Shared demo harness、Shared multi-demo harness、Shared layout/style/input/focus contract、AI-generated UI shared contract 与 Reusable component contract 均使用 `CjguiExperimentalDemoComponentActionRoute`。

## 验证结果

- [verify_cjgui_shared_demo_run_harness.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_cjgui_shared_demo_run_harness.sh)：通过，实际编译并运行当前全部 10 个 demo binary。
- 10 个 focused demo verifier：通过，分别实际编译并运行 Todo、Settings、Chat、FileBrowser、AI-generated UI、Shared demo harness、Shared multi-demo harness、Shared layout/style/input/focus contract、AI-generated UI shared contract 与 Reusable component contract。
- `cjpm build --target-dir /tmp/cjgui-shared-demo-component-action-route-value-model-target --skip-script`：通过；仍有既有 unused / stack-frame warnings，本次没有新增编译错误。
- Source scan：demo 侧 `componentSession.recordComponentAction(...)` 直接三参调用为 `0`。
- Route usage scan：demo 侧 `componentSession.recordComponentActionRoute(...)` 为 `41`。
- Protected path scan：`runtime/cjgui/src/runtime_state.cj` 仍为 `10065` 行；`runtime_state.cj`、`runtime/cjgui/cjpm.toml`、production native bridge 与 smoke native files 未修改。

Aggregate verifier 新增并回显：

- `cjgui_shared_demo_component_action_route_model=CjguiExperimentalDemoComponentActionRoute`
- `cjgui_shared_demo_component_action_route_usage_count=41`
- `cjgui_shared_demo_direct_component_action_string_recording_retired=true`

这些 facts 证明 component/action session recording 已进入 shared route value model；它们不证明 Renderer backend、native bridge、state store、public C ABI 或 production render truth。

## 边界

- 不新增 public C ABI。
- 不修改 production native bridge。
- 不写 `runtime_state.cj`。
- 不写 renderer state。
- 不修改 `runtime/cjgui/cjpm.toml`。
- 不把 demo stdout evidence 解释成 Renderer canonical tail、backend-ready truth 或 production render truth。
- 新增 public declarations 仅限 experimental `cjgui.demo_support`，服务 demo_support 复用路径，不是稳定 toolkit surface。

## 设计意图出口自检

- 本轮是否改变主题状态：改变 CJGUI minimal UI framework demo_support 复用状态，完成 component action route value model。
- 本轮是否改变 canonical tail / endpoint：不改变 Renderer canonical endpoint；仍为 `CjguiInternalRendererStage892ComponentCommitApiRuntimeManagerReadiness`。
- 本轮是否改变 owner / truth / stop-line：扩展 demo_support experimental route value model；不改变 Renderer truth、runtime truth、state write stop-line 或 native stop-line。
- 本轮是否改变唯一 next opening：改变 CJGUI minimal UI framework next opening，转向 component action route catalog。
- 是否同步 topic manifest：本轮为 demo_support ordinary report，未同步 Renderer topic manifest；当前变化不改变 Renderer implementation admission、backend readiness 或 macOS smoke 主题状态。
- 已同步哪些 topic manifest：无。

## 后续入口

下一步建议进入：

`P1 CJGUI shared demo_support component action route catalog for reusable demo actions`

原因：route value 已经成为 shared data path，但 demos 仍然手写 route component/action 字符串。下一步应把常见 Todo、Settings、Chat、FileBrowser、AI-generated UI 与 shared contract routes 收敛为 shared catalog / factory，让下一位 AI 写新 demo 时复用 route primitives，而不是复制字符串 spelling。

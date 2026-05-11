# Drawable no-present acquisition 预检结论

日期：2026-05-11

## 上游固定

- Runtime input：`CjguiInternalRendererNoDrawableVisibleWindowProbeReadiness`
- 上游 owner：[runtime_renderer_drawable_visible_window_probe.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_drawable_visible_window_probe.cj)
- 上游 default draft：`cjguiInternalExecuteDefaultRendererDrawableVisibleWindowProbeDraft()`
- 上游事实：isolated visible-window、display-backed `CAMetalLayer`、bounded run loop 与 cleanup 已由 probe 证明。

## GitNexus 影响记录

- `CjguiInternalRendererNoDrawableVisibleWindowProbeReadiness`：`UNKNOWN` / target not found / impactedCount `0`。
- `cjguiInternalExecuteDefaultRendererDrawableVisibleWindowProbeDraft`：`UNKNOWN` / target not found / impactedCount `0`。
- 判定：近期新增 owner 尚未被 GitNexus 索引；无 HIGH / CRITICAL 风险输出。本轮必须用源码、probe、build 与 forbidden scan 兜底。

## 预检判断

本阶段可以尝试 isolated visible-window no-present `nextDrawable` acquisition，但不能把该 probe 解释成 production runtime truth。

允许的实际动作：

- 新增 isolated probe：[verify_native_bridge_drawable_no_present_acquisition.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_native_bridge_drawable_no_present_acquisition.sh)
- probe 内创建临时 `NSWindow` / `NSView` / `CAMetalLayer` / `MTLDevice`。
- probe 内调用 `nextDrawable`。
- 使用 `allowsNextDrawableTimeout` 与外层 alarm 做有界保护。
- 若返回 nil / timeout，只分类为 recovery facts。
- 若 acquisition 成功，只记录 no-present、no-command-buffer、no-GPU、cleanup facts。

禁止事项：

- 不 present。
- 不创建 command queue / command buffer / encoder。
- 不提交 GPU work。
- 不执行 render。
- 不写 renderer state。
- 不触碰 `runtime_state.cj`。
- 不修改 `runtime/cjgui/cjpm.toml`。
- 不修改 smoke native files。
- 不新增 public API / diagnostics。
- 不返回 native pointer / handle / `id` / `Class`。

## 路线选择

选择 B/C：

`P1 internal Renderer drawable no-present acquisition isolated probe and value facts bundle`

选择理由：

- 上游 visible-window environment 已稳定。
- 新 probe 具备 bounded `nextDrawable` 保护。
- 当前环境实际观察到 `drawable_acquired=true` 与 `next_drawable_elapsed_ms=1`。
- cleanup、no-present、no-command-buffer、no-GPU 与 table count zero 均可由 probe 输出复核。

拒绝路线：

- A recovery-only：当前 probe 未出现 nil / timeout / unstable。
- production runtime drawable path：未授权。
- command queue / command buffer / render：未授权。
- backend-ready truth：未授权。

## 设计意图出口自检

- 本轮是否改变主题状态：是，准备从 visible-window environment proof 进入 isolated no-present drawable acquisition facts。
- 本轮是否改变 canonical tail / endpoint：预检选择后将变更为 `CjguiInternalRendererNoDrawableNoPresentAcquisitionReadiness`。
- 本轮是否改变 owner / truth / stop-line：将新增 no-present acquisition value owner；truth 只限 isolated probe facts；stop-line 继续禁止 present、command queue / buffer、GPU work、render、state write、public API。
- 本轮是否改变唯一 next opening：若 acquisition facts 封账，后续转向 `P1 internal Renderer command queue creation planning preflight decision`。
- 是否同步 topic manifest：需要。
- 已同步哪些 topic manifest：本预检要求同步 `renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。

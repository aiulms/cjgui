# Drawable 环境与窗口可见性预检

## 上游事实

上游固定为 `CjguiInternalRendererNoDrawableAcquisitionRecoveryReadiness` / `cjguiInternalExecuteDefaultRendererDrawableAcquisitionRecoveryDraft()`，owner 是 [runtime_renderer_drawable_acquisition_recovery.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_drawable_acquisition_recovery.cj)。

上游已经证明 token-backed `NSView` / `CAMetalLayer` / `MTLDevice` attach-bind-cleanup 链路可以回零，并继续固定：

- `nextDrawable` 没有调用。
- `present` 仍 forbidden。
- command queue / command buffer / encoder 仍 blocked。
- visible window、display-backed layer 与 run loop non-blocking 证据仍缺失。

## 预检判断

本轮选择 A：environment / window visibility planning value boundary。

理由：

- production runtime 当前仍不创建 `NSWindow` / `NSApplication`，不能把 layer 视为 display-backed。
- isolated visible-window probe 可以作为后续验证方向，但若现在直接创建窗口并推进 `nextDrawable`，仍缺少 bounded run loop、窗口可见性稳定性、no-present cleanup 与 CI-like 环境稳定性证据。
- `nextDrawable` 在没有可见 window / display-backed layer / run loop 证据时存在阻塞或偶发风险。
- 本轮更适合先新增 planning owner 与 planning consistency probe，明确后续 visible-window acquisition probe 的前置条件。

## 本轮允许路线

- 新增 [runtime_renderer_drawable_environment_visibility.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_drawable_environment_visibility.cj)。
- 新增 [verify_native_bridge_drawable_visible_window_environment.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_native_bridge_drawable_visible_window_environment.sh)，但该脚本只做 planning consistency，不创建窗口，不调用 `nextDrawable`。
- 不修改 production native `.h` / `.m`。
- 不修改 `runtime/cjgui/cjpm.toml`。
- 不修改 smoke native files。

## 禁止路线

- 不进入 B 的 isolated visible-window 创建。
- 不进入 C 的 no-present `nextDrawable` acquisition。
- 不 present。
- 不创建 command queue / command buffer / encoder。
- 不提交 GPU work，不执行 render，不写 renderer state。
- 不新增 public API / diagnostics。
- 不返回 pointer / handle / `id` / `Class`。

## GitNexus 影响面

编辑 runtime symbol 前已对上游运行 GitNexus impact：

- `CjguiInternalRendererNoDrawableAcquisitionRecoveryReadiness`：not found / UNKNOWN / impacted count 0。
- `cjguiInternalExecuteDefaultRendererDrawableAcquisitionRecoveryDraft`：not found / UNKNOWN / impacted count 0。

这些 symbol 属近期新增 owner，GitNexus 尚未索引；本轮用源码读取、`cjpm build`、probe 与 scan 兜底。

## 设计意图出口自检

- 本轮是否改变主题状态：是，drawable acquisition 从 recovery facts 进入 environment / window visibility planning。
- 本轮是否改变 canonical tail / endpoint：预检选择新增 `CjguiInternalRendererNoDrawableEnvironmentVisibilityReadiness`。
- 本轮是否改变 owner / truth / stop-line：预检选择新增 environment visibility planning owner；truth 限 visible window / run loop / display backing requirement facts；stop-line 继续禁止 `nextDrawable`、present、command queue / buffer、GPU work、render、state write 与 public API。
- 本轮是否改变唯一 next opening：预检建议完成后转为 `P1 internal Renderer drawable visible-window acquisition probe recovery/preflight decision`。
- 是否同步 topic manifest：将在 closure / manifest 稳定化同步。
- 已同步哪些 topic manifest：待 closure 记录。

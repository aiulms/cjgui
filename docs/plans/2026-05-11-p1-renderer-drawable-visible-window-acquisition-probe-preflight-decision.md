# Drawable 可见窗口 probe 预检

## 上游固定

- Runtime input：`CjguiInternalRendererNoDrawableEnvironmentVisibilityReadiness`
- 上游 owner：[runtime_renderer_drawable_environment_visibility.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_drawable_environment_visibility.cj)
- 上游 default draft：`cjguiInternalExecuteDefaultRendererDrawableEnvironmentVisibilityDraft()`

## GitNexus 影响面

- `CjguiInternalRendererNoDrawableEnvironmentVisibilityReadiness`：GitNexus 当前返回 `target not found` / `UNKNOWN`，按近期新增 owner 未索引处理。
- `cjguiInternalExecuteDefaultRendererDrawableEnvironmentVisibilityDraft`：GitNexus 当前返回 `target not found` / `UNKNOWN`，按近期新增 owner 未索引处理。
- 兜底：本轮使用源码读取、`cjpm build`、isolated probe 与 forbidden scan 约束风险；未发现需要停在 `HIGH` / `CRITICAL` 的影响面。

## 预检判断

- 可以进入 A 路线：isolated visible-window environment probe。
- 本轮允许在 probe 内临时创建 `NSWindow` / `NSView` / `CAMetalLayer` / `MTLDevice`，并运行 bounded run loop。
- 本轮不调用 `nextDrawable`，因为 no-present acquisition 仍可能依赖可见窗口稳定性、run loop 与 cleanup 后续证据。
- 本轮不修改 production runtime window semantics，不新增 production public API / diagnostics，不修改 `runtime/cjgui/cjpm.toml`，不触碰 `runtime_state.cj`。
- Probe evidence 只作为 isolated environment facts，不是 production backend-ready truth。

## 本轮选择

选择 A：`isolated visible-window environment probe`。

不选择 B：本轮不调用 no-present `nextDrawable`。

不选择 C：当前 visible-window environment 可用，不需要停为 recovery blocker。

## 停止线

不 present，不创建 command queue / command buffer / encoder，不提交 GPU work，不执行 render，不返回 native pointer / handle / `id` / `Class`，不写 renderer state，不把 isolated probe facts 解释成 drawable-ready、backend-ready、render permission、GPU submission permission 或 state write permission。

## 设计意图出口自检

- 本轮是否改变主题状态：是，从 environment visibility planning 推进到 isolated visible-window environment probe。
- 本轮是否改变 canonical tail / endpoint：预期改变为 `CjguiInternalRendererNoDrawableVisibleWindowProbeReadiness`。
- 本轮是否改变 owner / truth / stop-line：预期新增 owner 与 probe facts；truth 只限 isolated window visibility / display-backed layer / bounded run loop / cleanup facts；stop-line 继续禁止 `nextDrawable`、present、command queue / buffer、GPU work、render 与 state write。
- 本轮是否改变唯一 next opening：若 A 完成，唯一 next opening 为 `P1 internal Renderer drawable no-present acquisition recovery/preflight decision`。
- 是否同步 topic manifest：需要同步。
- 已同步哪些 topic manifest：待 closure / manifest 阶段记录。

## 唯一接续

若 A 完成，进入：

`P1 internal Renderer drawable no-present acquisition recovery/preflight decision`

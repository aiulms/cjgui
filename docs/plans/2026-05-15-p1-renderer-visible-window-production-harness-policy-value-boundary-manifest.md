# Renderer visible-window production harness policy value boundary 清单

## 清单状态

状态：implementation / internal value owner / no native harness

本清单固定 visible-window production harness policy value boundary 的 owner、canonical endpoint、runtime input、current truth 与 stop-line。

## Owner 文件

- [runtime_renderer_visible_window_production_harness.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_visible_window_production_harness.cj)

## Canonical endpoint 固定点

- `CjguiInternalRendererNoVisibleWindowProductionHarnessReadiness`
- `cjguiInternalExecuteDefaultRendererVisibleWindowProductionHarnessDraft()`

## Runtime input 输入

本 owner 只消费：

- `CjguiInternalRendererNoDrawableTextureLifetimePlanningReadiness`
- `CjguiInternalRendererNoDrawInputBundleReadiness`

## 当前 truth

本阶段 truth 只包括：

- visible-window production harness policy facts。
- production visible `NSWindow` ownership policy。
- bounded run loop policy。
- display-backed `CAMetalLayer` prerequisite。
- token-backed `NSView` / `CAMetalLayer` / `MTLDevice` alignment policy。
- cleanup co-ownership policy。
- headless / CI-like fail-closed policy。
- no-native-harness readiness。
- no production `nextDrawable` / drawable acquire readiness。

该 truth 不表示 native `NSWindow` harness 已实现，不表示 production drawable acquire 可运行，不表示 color attachment、encoder、draw、GPU submission 或 render permission。

## Stop-line 边界

本阶段仍不得：

- 修改 `runtime/cjgui/cjpm.toml`。
- 修改 `runtime/cjgui/src/runtime_state.cj`。
- 修改 smoke native files。
- 修改 production native `.h` / `.m`。
- 新增 native C ABI。
- 新增 `foreign func`。
- 新增 probe script。
- 创建 production `NSWindow` / `NSView` / `CAMetalLayer` / `MTLDevice`。
- 调用 production `nextDrawable`。
- 保存或返回 native pointer / handle / `id` / `Class`。
- 配置 `colorAttachments[0]`。
- 创建 command buffer / render command encoder。
- 调用 `setRenderPipelineState` / `setVertexBuffer`。
- 调用 `drawPrimitives` / `drawIndexedPrimitives`。
- 调用 `commit` / `present`。
- 提交 GPU work。
- 执行 render。
- 写 renderer state。
- 新增 public API / public diagnostics。

## Same-shape Boundary Brake 自检

本阶段不是 harness receipt / record / publication wrapper。新增 owner 同时消费 drawable lifetime planning tail 与 no-submit draw input bundle tail，并将二者收束到 visible-window production harness policy facts。

后续不得把该 endpoint 再包装成 native harness readiness、drawable-ready、color attachment permission、render permission、GPU submission、backend-ready、renderer state write、receipt、record 或 publication。

## GitNexus 记录

修改前对上游 tail symbols 运行 GitNexus impact，均返回 `UNKNOWN / not found`，未返回 HIGH / CRITICAL。本阶段以源码读取、build、smoke 与 scan 兜底。

## 当前最终 next opening

`P1 internal Renderer visible-window production harness native implementation preflight decision`

## 设计意图出口自检

- 本轮是否改变主题状态：是。visible-window production harness policy value boundary 已有 internal owner 与 manifest。
- 本轮是否改变 canonical tail / endpoint：是。新增 `CjguiInternalRendererNoVisibleWindowProductionHarnessReadiness` / `cjguiInternalExecuteDefaultRendererVisibleWindowProductionHarnessDraft()`。
- 本轮是否改变 owner / truth / stop-line：是。新增 owner 与 policy truth；stop-line 未放宽。
- 本轮是否改变唯一 next opening：是。下一步转为 native implementation preflight decision。
- 是否同步 topic manifest：需要同步。

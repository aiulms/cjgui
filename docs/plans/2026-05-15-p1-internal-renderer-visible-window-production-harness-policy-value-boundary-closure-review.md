# Renderer visible-window production harness policy value boundary 收束复核

## 本轮结果

本轮完成 `P1 internal Renderer visible-window production harness policy value boundary bundle implementation`。

新增 internal owner：

- [runtime_renderer_visible_window_production_harness.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_visible_window_production_harness.cj)

新增 canonical endpoint：

- `CjguiInternalRendererNoVisibleWindowProductionHarnessReadiness`
- `cjguiInternalExecuteDefaultRendererVisibleWindowProductionHarnessDraft()`

该 owner 只消费两个已封账上游：

- `CjguiInternalRendererNoDrawableTextureLifetimePlanningReadiness`
- `CjguiInternalRendererNoDrawInputBundleReadiness`

## 固定 truth

本轮只固定 visible-window production harness 的 value policy facts：

- production visible `NSWindow` ownership policy 已记录。
- bounded run loop policy 已记录。
- display-backed `CAMetalLayer` prerequisite 已记录。
- token-backed `NSView` / `CAMetalLayer` / `MTLDevice` alignment policy 已记录。
- cleanup co-ownership policy 已记录。
- headless / CI-like fail-closed policy 已记录。
- native `NSWindow` harness 仍 blocked。
- production `nextDrawable` 与 drawable acquire 仍 blocked。
- color attachment、encoder、draw、`commit`、`present`、GPU submission 与 render 仍 blocked。

## 本轮未打开事项

本轮没有进入 native `NSWindow` harness。

本轮未修改 production native `.h` / `.m`，未新增 native C ABI，未新增 `foreign func`，未新增 probe script，未修改 `runtime/cjgui/cjpm.toml`，未修改 `runtime_state.cj`，未修改 smoke native files。

本轮没有创建 production `NSWindow` / `NSView` / `CAMetalLayer` / `MTLDevice`，没有调用 production `nextDrawable`，没有保存或返回 native pointer / handle / `id` / `Class`，没有配置 `colorAttachments[0]`，没有创建 command buffer / render command encoder，没有调用 `setRenderPipelineState` / `setVertexBuffer`，没有 draw，没有 `commit` / `present`，没有 GPU submission，没有 render，没有 renderer state write，也没有新增 public API / public diagnostics。

## GitNexus 结果

修改前按 `cangjie-live-codelattice` 对以下上游 symbols 运行 impact：

- `CjguiInternalRendererNoDrawableTextureLifetimePlanningReadiness`
- `cjguiInternalExecuteDefaultRendererDrawableTextureLifetimePlanningDraft`
- `CjguiInternalRendererNoDrawInputBundleReadiness`
- `cjguiInternalExecuteDefaultRendererDrawInputBundleDraft`

GitNexus 对这些近期 renderer symbols 均返回 `UNKNOWN / not found`，未返回 HIGH / CRITICAL。本轮不能把 UNKNOWN 当安全证明，因此用源码读取、`cjpm build`、smoke、protected path scan、public declaration scan 与 forbidden scan 兜底。

## 当前最终 next opening

`P1 internal Renderer visible-window production harness native implementation preflight decision`

下一步只允许先做 preflight decision。该 opening 不批准直接进入 native `NSWindow` harness implementation；若要触碰 production native bridge、`NSWindow` ownership、bounded run loop 或 production drawable acquire，必须先由该 preflight 明确批准写集和 stop-line。

## 设计意图出口自检

- 本轮是否改变主题状态：是。visible-window production harness 从 preflight-approved policy value boundary 进入已落地 internal owner 状态。
- 本轮是否改变 canonical tail / endpoint：是。新增 `CjguiInternalRendererNoVisibleWindowProductionHarnessReadiness` / `cjguiInternalExecuteDefaultRendererVisibleWindowProductionHarnessDraft()`。
- 本轮是否改变 owner / truth / stop-line：是。新增 owner file 与 harness policy facts；stop-line 没有放宽。
- 本轮是否改变唯一 next opening：是。下一步转为 `P1 internal Renderer visible-window production harness native implementation preflight decision`。
- 是否同步 topic manifest：需要同步。
- 已同步哪些 topic manifest：本轮应同步 `renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md` 与 `macos-bridge-verification-smoke.md`。

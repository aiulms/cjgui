# Renderer visible-window production harness native implementation 范围锁定预检收束复核

## 本轮结果

本轮完成 `P1 internal Renderer visible-window production harness native implementation preflight decision` 的 scope-locked docs-only reconciliation。

结论：当前仓库确实指向 native implementation preflight，但用户最新约束仍要求只做 visible-window production harness policy value boundary，不进入 native `NSWindow` harness。因此本轮不批准任何 native implementation 写集。

## 实际完成内容

- 新增 scope-locked preflight decision。
- 明确上一轮 policy value boundary report 已由用户本轮“继续”确认，不再作为 guard-stop。
- 明确当前 runtime endpoint 不变：
  - `CjguiInternalRendererNoVisibleWindowProductionHarnessReadiness`
  - `cjguiInternalExecuteDefaultRendererVisibleWindowProductionHarnessDraft()`
- 将后续入口改为显式 scope unlock decision，而不是 native implementation。

## 保持不变的 truth

上游 policy owner 仍是 [runtime_renderer_visible_window_production_harness.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_visible_window_production_harness.cj)。

它仍只固定：

- production visible `NSWindow` ownership policy。
- bounded run loop policy。
- display-backed `CAMetalLayer` prerequisite。
- token-backed `NSView` / `CAMetalLayer` / `MTLDevice` alignment policy。
- cleanup co-ownership policy。
- headless / CI-like fail-closed policy。
- no-native-harness readiness。
- no production `nextDrawable` / drawable acquire readiness。

## 本轮未打开事项

本轮没有进入 native `NSWindow` harness。

本轮未修改 `.cj` runtime owner、production native `.h` / `.m`、probe script、`runtime/cjgui/cjpm.toml`、`runtime_state.cj` 或 smoke native files。

本轮没有新增 native C ABI、`foreign func`、public API 或 public diagnostics。

本轮没有调用 production `nextDrawable`，没有配置 color attachment，没有创建 command buffer / render command encoder，没有调用 `setRenderPipelineState` / `setVertexBuffer`，没有 draw，没有 `commit` / `present`，没有 GPU submission，没有 render，也没有 renderer state write。

## 后续唯一入口

`P1 internal Renderer visible-window production harness native NSWindow harness scope unlock decision`

该入口只负责决定是否解除当前“只做 policy value boundary”的范围锁。未解除前，自动化不得继续叠加 native implementation preflight 或 native harness implementation。

## 设计意图出口自检

- 本轮是否改变主题状态：是。native implementation preflight 被记录为 scope-locked docs-only reconciliation。
- 本轮是否改变 canonical tail / endpoint：否。
- 本轮是否改变 owner / truth / stop-line：是。truth 增加 scope unlock 前不得批准 native implementation；stop-line 未放宽。
- 本轮是否改变唯一 next opening：是。
- 是否同步 topic manifest：需要同步。
- 已同步哪些 topic manifest：本轮应同步 `renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md` 与 `macos-bridge-verification-smoke.md`。

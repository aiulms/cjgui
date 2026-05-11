# Drawable acquisition first implementation 预检结论

## 结论

本轮选择 A：recovery/preflight only。

当前 `CjguiInternalRendererNoDrawableAvailabilityReadiness` 已证明 token-backed `CAMetalLayer` / `MTLDevice` 路线存在，且 drawable acquisition 与 command queue 仍 blocked；但 production bridge 仍没有可见 `NSWindow`、display-backed layer、run loop non-blocking、present-disabled acquisition lifecycle cleanup 或 command queue absence 的充分环境证据。直接调用 `nextDrawable` 可能依赖可见窗口 / run loop / display pipeline，在 CI-like shell 中存在阻塞或不稳定风险，因此本轮不调用 `nextDrawable`。

## 允许路线判断

- A：通过。本轮新增 recovery owner 与 recovery probe，固定 blocker facts。
- B：不进入。`nextDrawable` no-present feasibility 缺少 non-blocking / timeout 可证路径。
- C：不进入。drawable token-local table 需要先证明 acquisition lifecycle cleanup，不适合在本轮直接实现。
- D：保留。若未来环境证明 `nextDrawable` 在 headless / CI-like shell 不稳定，继续停 recovery。

## 固定 blocker

- 当前 production bridge 没有创建可见 `NSWindow` / `NSApplication`。
- 当前 layer 只证明 token-backed attach / device binding，不证明 display-backed。
- 当前 command queue 仍 blocked。
- 当前 present path 仍 forbidden。
- 当前不能把 no-acquire facts 解释成 drawable permission。

## 写集授权

- 允许新增 `runtime/cjgui/src/runtime_renderer_drawable_acquisition_recovery.cj`。
- 允许新增 `runtime/cjgui/native/scripts/verify_native_bridge_drawable_acquisition_recovery.sh`。
- 允许新增 / 修改 docs、closure、manifest 与导航索引。
- 不修改 production native `.h` / `.m`。
- 不修改 `runtime/cjgui/cjpm.toml`。
- 不修改 smoke native files。

## GitNexus 记录

GitNexus impact 对上游 endpoint `CjguiInternalRendererNoDrawableAvailabilityReadiness` 与 default draft `cjguiInternalExecuteDefaultRendererDrawableAvailabilityDraft` 返回近期新增 symbol 未索引 / not found，affected count 为 0，risk 记录为 UNKNOWN。本轮以源码读取、`cjpm build`、recovery probe 与 forbidden scan 兜底。

## 设计意图出口自检

- 本轮是否改变主题状态：是，从 drawable availability 进入 first implementation recovery / preflight。
- 本轮是否改变 canonical tail / endpoint：预检选择将 tail 推向 recovery endpoint。
- 本轮是否改变 owner / truth / stop-line：是，授权新增 recovery owner；truth 限 recovery / blocker facts；stop-line 继续禁止 `nextDrawable`、present、command queue / buffer、GPU work、render、state write 与 public API。
- 本轮是否改变唯一 next opening：预期改为 `P1 internal Renderer drawable acquisition environment/window visibility planning decision`。
- 是否同步 topic manifest：本文件创建时声明需要同步。
- 已同步哪些 topic manifest：待 closure 同步 `renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。

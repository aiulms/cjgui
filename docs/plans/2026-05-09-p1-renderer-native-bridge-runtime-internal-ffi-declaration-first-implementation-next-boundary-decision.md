# P1 渲染器 native bridge runtime internal FFI declaration 第一实现后续边界

日期：2026-05-09

状态：next-boundary / choose manifest stabilization

## 当前 endpoint 判断

`CjguiInternalRendererNoNativeBridgeRuntimeFfiCallReadiness` / `cjguiInternalExecuteDefaultRendererNativeBridgeRuntimeFfiDeclarationDraft()` 足够作为当前 runtime internal FFI declaration 第一实现 endpoint。

它只代表：

- 四个 no-resource C ABI 的 internal `foreign func` declaration 已存在。
- declaration 仍是 internal-only。
- runtime package link 仍未接入 production `.m` 到主包。
- runtime FFI call 仍被拒绝。
- public API、resource callable、native object、Metal / AppKit、renderer state write 与 backend-ready truth 仍被拒绝。

## 候选比较

- A 后续推荐：`P1 internal Renderer native bridge internal no-resource FFI call verification bundle`。只有在 manifest stabilization 封账后，才评估是否可以在 internal owner 内调用 no-resource FFI 并脱水结果。
- B 本轮选择：`P1 internal Renderer native bridge runtime internal FFI declaration manifest stabilization bundle`。先固定 actual owner、endpoint、declared callable list、no-call status 与 package link status。
- C 暂缓：`P1 internal Renderer native bridge package link config implementation preflight decision`。当前未修改 `runtime/cjgui/cjpm.toml`，且未调用 FFI；不在本轮扩大 build config。
- D 拒绝：public API / resource callable / native object / Metal / AppKit。

本轮选择 B，完成 manifest stabilization 后停止；唯一后续入口建议转为 A。

## 同形边界刹车

不得把 internal declaration、package link probe、isolated FFI probe 或 symbol probe 包装成 runtime FFI call permission、public API permission、resource callable permission、native object permission、Metal / AppKit permission、backend-ready permission、GPU-submission permission、render permission、renderer-state-write permission、receipt、record 或 publication。

## 设计意图出口自检

- 本轮是否改变主题状态：是，第一实现进入 manifest stabilization。
- 本轮是否改变 canonical tail / endpoint：是，当前 first-slice endpoint 为 `CjguiInternalRendererNoNativeBridgeRuntimeFfiCallReadiness`。
- 本轮是否改变 owner / truth / stop-line：是，新增 declaration owner；truth 限于 internal declaration / no-call facts；stop-line 不变。
- 本轮是否改变唯一 next opening：是，临时转为 manifest stabilization；封账后转为 internal no-resource FFI call verification bundle。
- 是否同步 topic manifest：是，随 manifest stabilization 同步。
- 已同步哪些 topic manifest：待 manifest stabilization 完成后同步 `renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。

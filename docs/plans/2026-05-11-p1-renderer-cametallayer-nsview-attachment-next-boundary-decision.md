# P1 渲染器 CAMetalLayer NSView attachment 下一阶段选择

日期：2026-05-11

状态：next-boundary decision / 进入 runtime attachment FFI call owner 前封账

## 本轮选择

选择下一阶段：

`P1 internal Renderer CAMetalLayer runtime attachment FFI call owner preflight decision`

选择理由：

- token-backed `NSView` create/destroy 已稳定。
- token-backed `CAMetalLayer` create/destroy 已稳定。
- Production native attach/detach C ABI 已通过 probe。
- Runtime internal owner 已能调用 attachment C ABI 并脱水 facts。
- Attachment 仍未引入 Metal、device、drawable、render、public API 或 renderer state write。

## 拒绝路线

- 拒绝直接进入 Metal device binding。
- 拒绝直接获取 drawable。
- 拒绝 renderer backend-ready truth。
- 拒绝 renderer state write。
- 拒绝 public API / diagnostics。
- 拒绝把 token 暴露到 public surface。

## 下一阶段必须回答

- attachment C ABI 是否需要单独 runtime-adjacent probe，还是当前 owner build 足够。
- runtime owner 是否只调用 attach / detach / classify 并保持 token 函数局部。
- package link 是否支持 attachment runtime call。
- 是否继续禁止 Metal import、`CAMetalLayer.device`、`nextDrawable`、public API 与 renderer state write。

## Downstream

后续 [CAMetalLayer runtime attachment FFI call owner manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-cametallayer-runtime-attachment-ffi-call-owner-manifest.md) 已完成，并将唯一 next opening 推进到 `P1 internal Renderer Metal device binding planning preflight decision`。

## 设计意图出口自检

- 本轮是否改变主题状态：是，attachment first slice 已完成。
- 本轮是否改变 canonical tail / endpoint：是，当前 tail 是 `CjguiInternalRendererNoCAMetalLayerNSViewAttachmentReadiness`。
- 本轮是否改变 owner / truth / stop-line：是，truth 限于 token-backed attachment lifecycle；stop-line 继续禁止 Metal、drawable、state write、public。
- 本轮是否改变唯一 next opening：是，固定为 `P1 internal Renderer CAMetalLayer runtime attachment FFI call owner preflight decision`。
- 是否同步 topic manifest：是，已在本轮 manifest stabilization 同步。
- 已同步哪些 topic manifest：`renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。

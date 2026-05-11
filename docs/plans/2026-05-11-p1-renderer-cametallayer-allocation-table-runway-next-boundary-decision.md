# P1 渲染器 CAMetalLayer allocation/table runway 下一阶段选择

日期：2026-05-11

状态：next-boundary decision / 进入 attach-detect 预检前封账

## 本轮选择

选择下一阶段：

`P1 internal Renderer CAMetalLayer NSView attach/detach preflight decision`

该入口已由 [CAMetalLayer NSView attachment preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-cametallayer-nsview-attachment-preflight-decision.md) 接续，并在 [CAMetalLayer NSView attachment manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-cametallayer-nsview-attachment-manifest.md) 中封账；后续 [CAMetalLayer runtime attachment FFI call owner manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-cametallayer-runtime-attachment-ffi-call-owner-manifest.md) 已完成。当前唯一后续入口转为 `P1 internal Renderer Metal device binding planning preflight decision`。

选择理由：

- `CAMetalLayer` allocation feasibility 已通过。
- fixed-capacity token-backed table shell 已通过。
- token-backed create/destroy first slice 已通过。
- create/destroy 仍未 attach 到 `NSView`，未设置 device，未获取 drawable。
- 下一风险门正是 `NSView.layer` / `wantsLayer` / attach / detach 语义，不应在本轮偷渡。

## 拒绝路线

- 拒绝直接进入 Metal device binding。
- 拒绝直接获取 drawable。
- 拒绝 renderer backend-ready truth。
- 拒绝 renderer state write。
- 拒绝 public API / diagnostics。

## 下一阶段必须回答

- 是否允许设置 `NSView.wantsLayer`。
- 是否允许把 token-backed `CAMetalLayer` attach 到 token-backed `NSView`。
- detach-before-destroy 如何 fail-closed。
- stale layer token / stale view token / double detach 如何分类。
- attachment 是否需要 Metal device；若需要，必须停止。

## 设计意图出口自检

- 本轮是否改变主题状态：是，allocation/table runway 已完成到 create-destroy first slice。
- 本轮是否改变 canonical tail / endpoint：是，当前 tail 为 `CjguiInternalRendererNoCAMetalLayerCreateDestroyReadiness`。
- 本轮是否改变 owner / truth / stop-line：是，truth 限于 token-backed `CAMetalLayer` lifecycle；stop-line 继续禁止 attach、Metal、drawable、state write、public。
- 本轮是否改变唯一 next opening：是，固定为 `P1 internal Renderer CAMetalLayer NSView attach/detach preflight decision`。
- 是否同步 topic manifest：是，已在本轮 manifest stabilization 同步。
- 已同步哪些 topic manifest：`renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。

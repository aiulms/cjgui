# Metal device binding 后续入口结论

## 结论

本阶段选择后续入口：

`P1 internal Renderer drawable acquisition planning preflight decision`

选择原因是 `CjguiInternalRendererNoMetalDeviceLayerBindingReadiness` 已固定 token-backed `MTLDevice` create / destroy 与 `CAMetalLayer.device` bind / unbind facts，但仍没有 drawable acquisition、command queue、command buffer、GPU submission、render execution 或 renderer state write。

## 不选择的路线

- 暂不进入 command queue first slice，因为 command queue 需要单独的 `newCommandQueue` / ownership / teardown / no-submit preflight。
- 暂不进入 render execution，因为仍没有 drawable、command buffer、encoder、pipeline 或 draw call。
- 拒绝把 device-layer binding facts 解释成 backend-ready truth。

## 后续入口前置

下一轮如果打开 drawable acquisition planning，只允许先评估 `CAMetalLayer.nextDrawable` 的 admission / fail-closed / lifecycle / presentation stop-line，不得直接获取 drawable，除非新的 preflight 明确证明 stable、main-thread、cleanup 与 no-render boundary。

## 下游接续

已由 [Drawable acquisition 路线预检结论](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-drawable-acquisition-runway-preflight-decision.md) 接续，并实际选择 A/B：planning / no-acquire facts 与 availability / still-blocked facts。下游未进入 `nextDrawable` acquisition。

## 设计意图出口自检

- 本轮是否改变主题状态：是。
- 本轮是否改变 canonical tail / endpoint：是，当前 tail 为 `CjguiInternalRendererNoMetalDeviceLayerBindingReadiness`。
- 本轮是否改变 owner / truth / stop-line：是，owner 变为 Metal device availability / create-destroy / layer binding 链；stop-line 继续禁止 drawable、queue、buffer、GPU submission、render、state write。
- 本轮是否改变唯一 next opening：是，唯一 next opening 为 `P1 internal Renderer drawable acquisition planning preflight decision`。
- 是否同步 topic manifest：需要同步。
- 已同步哪些 topic manifest：本轮同步 `renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。

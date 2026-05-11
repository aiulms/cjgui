# Drawable no-present acquisition 后续边界选择

日期：2026-05-11

## 当前结论

`CjguiInternalRendererNoDrawableNoPresentAcquisitionReadiness` 已足够作为当前 drawable no-present acquisition tail。它只证明 isolated visible-window probe 中 `nextDrawable` 可 bounded no-present acquire 并 cleanup，不证明 production renderer 可以渲染。

## 候选判断

- A：`P1 internal Renderer command queue creation planning preflight decision`
- B：`P1 internal Renderer drawable acquisition environment recovery decision`
- C：`P1 internal Renderer drawable token-local acquisition table preflight decision`
- D：拒绝直接进入 present / command buffer / render / backend-ready。

## 选择

选择 A：

`P1 internal Renderer command queue creation planning preflight decision`

## 下游已接续

该入口已由 [Command queue creation 路线封账清单](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-command-queue-creation-runway-manifest.md) 接续并封账；当前下游唯一入口已转为 `P1 internal Renderer command buffer creation planning preflight decision`。该接续不改变本阶段 no-present / no-command-buffer / no-render stop-line。

选择理由：

- 当前已证明 no-present `nextDrawable` feasibility。
- 下一项硬前置是 command queue / command buffer / encoder 路线判断。
- 不能绕过 command queue 直接 present 或 render。
- token-local drawable table 尚未必要；当前 drawable 仍保持局部短生命周期且未保存。

## 保持的停止线

不 present，不创建 command queue / command buffer / encoder，不提交 GPU work，不执行 render，不写 renderer state，不触碰 `runtime_state.cj`，不修改 `runtime/cjgui/cjpm.toml`，不修改 smoke native files，不新增 public API / diagnostics，不返回 native pointer / handle / `id` / `Class`，不把 no-present drawable acquisition facts 解释成 backend-ready truth。

## 设计意图出口自检

- 本轮是否改变主题状态：是，no-present drawable acquisition tail 已封账。
- 本轮是否改变 canonical tail / endpoint：是，固定 `CjguiInternalRendererNoDrawableNoPresentAcquisitionReadiness`。
- 本轮是否改变 owner / truth / stop-line：是，owner 固定为 `runtime_renderer_drawable_no_present_acquisition.cj`；truth 限 isolated no-present acquisition facts；stop-line 不放宽。
- 本轮是否改变唯一 next opening：是，转为 `P1 internal Renderer command queue creation planning preflight decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。

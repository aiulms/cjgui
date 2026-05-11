# P1 渲染器 CAMetalLayer runtime attachment FFI call owner 后续入口

日期：2026-05-11

状态：next-boundary / 选择 A

## 判断结论

`CAMetalLayer` runtime attachment FFI call owner 已完成。Runtime owner 与 runtime-adjacent probe 均证明 attach / classify / detach / cleanup 只产生 internal dehydrated facts，未引入 public API、renderer state write、Metal import、device binding、drawable acquisition 或 GPU submission。

## 候选选择

选择 A：`P1 internal Renderer CAMetalLayer runtime attachment FFI call owner manifest stabilization bundle`。

该选择只做本阶段 manifest stabilization，并将唯一后续入口固定为：

`P1 internal Renderer Metal device binding planning preflight decision`

后续 [Metal device binding runway manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-metal-device-binding-runway-manifest.md) 已完成；该 manifest 将本 next-boundary 的入口接续到 `CjguiInternalRendererNoMetalDeviceLayerBindingReadiness`，并把唯一后续入口更新为 `P1 internal Renderer drawable acquisition planning preflight decision`。

## 拒绝项

- 拒绝把 runtime attachment call 包装成 backend-ready truth。
- 拒绝直接进入 `MTLDevice` creation。
- 拒绝 render / drawable / command buffer / GPU submission。
- 拒绝 public API / diagnostics。
- 拒绝 renderer state write。

## 设计意图出口自检

- 本轮是否改变主题状态：是，runtime attachment call owner 已从 implementation 进入 manifest stabilization。
- 本轮是否改变 canonical tail / endpoint：是，固定 `CjguiInternalRendererNoCAMetalLayerAttachmentRuntimeCallReadiness`。
- 本轮是否改变 owner / truth / stop-line：是，owner 固定为 runtime attachment call owner；truth 仅限 internal FFI call facts；stop-line 不变。
- 本轮是否改变唯一 next opening：是，转为 `P1 internal Renderer Metal device binding planning preflight decision`。
- 是否同步 topic manifest：将在 manifest stabilization 同步。
- 已同步哪些 topic manifest：next-boundary 阶段记录为待同步。

# Metal device binding 路线封账复核

## 封账结论

本轮将 Metal device binding 路线封账到 `CjguiInternalRendererNoMetalDeviceLayerBindingReadiness`。该 endpoint 代表 token-backed `MTLDevice` 与 token-backed `CAMetalLayer` 的 main-thread bind / unbind / classify / cleanup facts，不代表 backend ready，不代表 drawable / command queue / render permission。

## Manifest 稳定项

- Actual route：A / B / C 完成。
- Canonical endpoint：`CjguiInternalRendererNoMetalDeviceLayerBindingReadiness`。
- Default draft：`cjguiInternalExecuteDefaultRendererMetalDeviceLayerBindingDraft()`。
- Runtime input：`CjguiInternalRendererNoMetalDeviceCreateDestroyReadiness`。
- Probe：`verify_native_bridge_metal_device_layer_binding.sh`。
- Package config：`runtime/cjgui/cjpm.toml` 未修改。
- Smoke native files：未修改。
- Public API：未新增。
- Renderer state：未写入。

## 设计意图出口自检

- 本轮是否改变主题状态：是。
- 本轮是否改变 canonical tail / endpoint：是，固定为 `CjguiInternalRendererNoMetalDeviceLayerBindingReadiness`。
- 本轮是否改变 owner / truth / stop-line：是，新增 Metal device availability / create-destroy / layer binding owner；truth 限于 internal dehydrated facts；stop-line 明确禁止 drawable、queue、buffer、GPU submission、render、state write、public API。
- 本轮是否改变唯一 next opening：是，固定为 `P1 internal Renderer drawable acquisition planning preflight decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。

## Same-shape 刹车

不得把 Metal device availability、token-backed `MTLDevice` lifecycle、`CAMetalLayer.device` binding、runtime owner facts、probe output、package link evidence 或 smoke evidence包装成 drawable permission、command queue permission、command buffer permission、GPU submission permission、render permission、renderer state write permission、backend-ready truth、public API、receipt / record / publication。

## 下游接续

已由 [Drawable acquisition 清单稳定化复核](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-internal-renderer-drawable-acquisition-runway-manifest-stabilization-closure-review.md) 接续。当前下游 tail 是 `CjguiInternalRendererNoDrawableAvailabilityReadiness`，仍不调用 `nextDrawable`，不 present，不创建 command queue / command buffer / encoder，不提交 GPU work，不执行 render。

# P1 内部渲染器 CAMetalLayer runtime attachment FFI call owner 清单稳定封账

日期：2026-05-11

状态：manifest stabilization closure / completed

## 稳定结论

本轮已完成 `CAMetalLayer` runtime attachment FFI call owner 的 manifest stabilization。Canonical tail 固定为 `CjguiInternalRendererNoCAMetalLayerAttachmentRuntimeCallReadiness`，唯一后续入口固定为 `P1 internal Renderer Metal device binding planning preflight decision`。

该封账不改变 public API，不修改 package config，不写 renderer state，不触碰 `runtime_state.cj`，不引入 Metal device / drawable / command buffer / render。

## 同步结果

- `README.md`
- `GUI_TASK_TRACKER.md`
- `docs/plans/README.md`
- `runtime/cjgui/README.md`
- `docs/plans/DESIGN_INTENT_INDEX.md`
- `docs/plans/topic-manifests/renderer-implementation-admission-chain.md`
- `docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md`
- `docs/plans/topic-manifests/macos-bridge-verification-smoke.md`

同时给上游 `CAMetalLayer` attachment manifest / closure / next-boundary 补 downstream 指向。

## 验证固定

- Runtime-adjacent attachment FFI call probe 通过。
- 主包 `cjpm build --skip-script` 通过。
- 后续全量 probe、文档、public scan、native forbidden scan、protected path scan 与 GitNexus detect changes 在最终验证阶段记录。

## Stop-line

- 不 import Metal。
- 不创建 `MTLDevice` / queue / drawable / command buffer。
- 不设置 `CAMetalLayer.device`。
- 不调用 `nextDrawable`。
- 不返回 pointer / handle / `id` / `Class`。
- 不新增 public API / diagnostics。
- 不写 renderer state。
- 不把 runtime attachment facts 包装成 backend-ready truth、render permission 或 GPU submission permission。

## 设计意图出口自检

- 本轮是否改变主题状态：是，runtime attachment FFI call owner 已完成 manifest stabilization。
- 本轮是否改变 canonical tail / endpoint：是，固定为 `CjguiInternalRendererNoCAMetalLayerAttachmentRuntimeCallReadiness`。
- 本轮是否改变 owner / truth / stop-line：是，owner 固定为 `runtime_renderer_cametallayer_attachment_runtime_call.cj`；truth 只限 runtime internal dehydrated facts；stop-line 不变。
- 本轮是否改变唯一 next opening：是，固定为 `P1 internal Renderer Metal device binding planning preflight decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。

# P1 内部渲染器 CAMetalLayer attachment planning 清单稳定化封账

日期：2026-05-10

状态：manifest stabilization closure / no-attach planning 已封账

## 封账结论

`CAMetalLayer` attachment planning 清单已稳定化。当前 actual route 是 planning value boundary，不是 no-attach native callable，不是 QuartzCore import，不是 layer creation，不是 attachment implementation。

最新 canonical tail：

- `CjguiInternalRendererNoCAMetalLayerAttachmentReadiness`
- `cjguiInternalExecuteDefaultRendererCAMetalLayerAttachmentDraft()`

## 证据与边界

- 上游 `NSView` backend shell integration evidence 已被保留。
- QuartzCore import 被记录为 future preflight requirement。
- `CAMetalLayer` class availability 仅作为 future observation policy。
- `NSView.layer` attachment 仍 blocked。
- `wantsLayer` mutation 仍 blocked。
- Metal device binding / drawable acquisition 仍 blocked。
- detach-before-destroy dependency 已记录，但不执行 detach / destroy。
- no public surface、no diagnostics、no renderer state write、no backend-ready truth 均保持。

本轮不新增 CAMetalLayer no-attach probe，原因是没有新增 native C ABI；后续若要验证 class availability，应单独进入 no-attach class/runtime FFI call owner preflight。

## 下游入口

唯一 next opening：

`P1 internal Renderer CAMetalLayer no-attach class/runtime FFI call owner preflight decision`

下游已由 [CAMetalLayer no-attach class/runtime FFI call owner stage](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-cametallayer-no-attach-class-runtime-ffi-call-owner-manifest.md) 承接；该 stage 只完成 no-attach A 路线，未进入 allocation / table / attach。

## 设计意图出口自检

- 本轮是否改变主题状态：是，`CAMetalLayer` attachment planning 从预检推进到 manifest stabilization closure。
- 本轮是否改变 canonical tail / endpoint：是，当前 tail 固定为 `CjguiInternalRendererNoCAMetalLayerAttachmentReadiness`。
- 本轮是否改变 owner / truth / stop-line：是，owner 为 `runtime_renderer_cametallayer_attachment_planning.cj`；truth 只含 no-attach planning facts；stop-line 禁止 QuartzCore / Metal import、layer creation / attachment、drawable、GPU work、state write、public API。
- 本轮是否改变唯一 next opening：是，固定为 `P1 internal Renderer CAMetalLayer no-attach class/runtime FFI call owner preflight decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。

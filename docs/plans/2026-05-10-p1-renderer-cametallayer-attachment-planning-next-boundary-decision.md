# P1 渲染器 CAMetalLayer attachment planning 下一阶段选择

日期：2026-05-10

状态：next-boundary decision / 进入 no-attach class/runtime FFI call owner 预检

## 本轮选择

选择 A：

`P1 internal Renderer CAMetalLayer no-attach class/runtime FFI call owner preflight decision`

选择理由：

- `CjguiInternalRendererNoCAMetalLayerAttachmentReadiness` 已成为当前 no-attach planning tail。
- 本轮只新增 internal value owner，没有新增 native C ABI、QuartzCore import、native probe、public API 或 renderer state write。
- `NSView.layer` attachment、`wantsLayer` mutation、`CAMetalLayer` / `CALayer` creation、Metal device binding 与 drawable acquisition 均继续 blocked。
- 下一阶段自然应先评估 no-attach class availability / runtime FFI call owner，而不是直接 attachment。

## 拒绝路线

- 拒绝直接创建 `CAMetalLayer` / `CALayer`。
- 拒绝直接设置 `NSView.layer` / `wantsLayer`。
- 拒绝直接 import Metal 或创建 `MTLDevice` / `MTLCommandQueue`。
- 拒绝获取 drawable、创建 command buffer、提交 GPU work 或执行 render。
- 拒绝 public API / diagnostics。
- 拒绝写 renderer state 或触碰 `runtime_state.cj`。

## 下一阶段边界

下一阶段只能判断是否允许新增 no-attach class availability callable / runtime internal call owner。即便允许，也只能返回整数 classification facts，不得返回 `Class` / `id` / pointer / handle，不得保存 native object，不得创建 layer，不得 attach 到 `NSView`。

## 下游接续

该入口已由 [CAMetalLayer no-attach class/runtime FFI call owner preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-cametallayer-no-attach-class-runtime-ffi-call-owner-preflight-decision.md) 承接，并在 [manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-cametallayer-no-attach-class-runtime-ffi-call-owner-manifest.md) 中封账为 A 路线。

## 设计意图出口自检

- 本轮是否改变主题状态：是，`CAMetalLayer` attachment planning 已封账，下一阶段转入 no-attach class/runtime FFI call owner 预检。
- 本轮是否改变 canonical tail / endpoint：是，当前 tail 为 `CjguiInternalRendererNoCAMetalLayerAttachmentReadiness`。
- 本轮是否改变 owner / truth / stop-line：是，owner 为 `runtime_renderer_cametallayer_attachment_planning.cj`；truth 仅限 no-attach planning facts；stop-line 继续禁止 layer creation / attachment、Metal、drawable、state write、public API。
- 本轮是否改变唯一 next opening：是，固定为 `P1 internal Renderer CAMetalLayer no-attach class/runtime FFI call owner preflight decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。

# 渲染通道描述符颜色附件预检结论

日期：2026-05-11

## 当前判断

本阶段可以打开 `MTLRenderPassDescriptor.colorAttachments[0]` 路线，但只能进入 planning / value boundary。原因是上游 `CjguiInternalRendererNoRenderPassDescriptorCreateDestroyReadiness` 已证明 descriptor token lifecycle，而 `CjguiInternalRendererNoDrawableNoPresentAcquisitionReadiness` 仍只来自 isolated visible-window probe，不是 production token-backed drawable texture lifecycle。

## 证据裁剪

- `MTLRenderPassDescriptor` 可在 production native bridge 内 create / classify / destroy，并已证明 cleanup count 归零。
- no-present `nextDrawable` 证据来自 isolated probe，允许临时 `NSWindow` / `NSView` / `CAMetalLayer` / `MTLDevice`，但不改变 production runtime window semantics。
- 当前没有 production drawable token table。
- 当前没有 production drawable texture ownership / release / cleanup contract。
- 当前没有 descriptor 与 drawable texture 的 shared lifecycle proof。
- 因此不能把 isolated drawable texture 配置到 production descriptor。

## 路线选择

选择 A：

- `P1 internal Renderer render pass descriptor color attachment planning / dependency facts`

本轮新增 runtime planning owner，不新增 native C ABI，不配置 `colorAttachments[0]`。

暂缓 B/C：

- descriptor color attachment configuration first slice。
- runtime internal FFI call owner for configured attachment。

拒绝 D：

- 创建 render command encoder。
- 调用 `renderCommandEncoderWithDescriptor`。
- draw / `commit` / `present`。
- GPU submission。
- renderer state write。
- public API / diagnostics。

## 停止线

不配置 `colorAttachments[0]`，不读取或绑定 production drawable texture，不创建 render command encoder，不调用 `renderCommandEncoderWithDescriptor`，不 draw，不调用 `commit`，不 present，不提交 GPU work，不执行 render，不写 renderer state，不触碰 `runtime_state.cj`，不修改 `runtime/cjgui/cjpm.toml`，不修改 smoke native files，不新增 public API / diagnostics，不返回 native pointer / handle / `id` / `Class`。

## 设计意图出口自检

- 本轮是否改变主题状态：是，color attachment 路线从 create / destroy tail 后打开到 planning。
- 本轮是否改变 canonical tail / endpoint：是，本轮 planning tail 预定为 `CjguiInternalRendererNoRenderPassDescriptorColorAttachmentPlanningReadiness`。
- 本轮是否改变 owner / truth / stop-line：是，新增 planning owner；truth 只到 dependency / blocker facts；stop-line 继续禁止 attachment configuration / encoder / draw / commit / present / GPU / render / state / public。
- 本轮是否改变唯一 next opening：是，若 planning 封账，唯一 next opening 为 `P1 internal Renderer render pass descriptor color attachment implementation recovery decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。

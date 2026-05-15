# No-submit 渲染管线分支归因裁定

## 本轮裁定

本轮选择 A + C：

- A：确认 no-submit render pipeline branch 已形成 milestone。
- C：下一主线回到 `P1 internal Renderer production drawable texture lifetime first slice preflight decision`。

本轮保持 docs-only，不新增 runtime owner，不新增 production native C ABI，不修改 `.cj`、`.h`、`.m` 或 probe script。

## 已具备事实

No-submit 分支已经具备以下 internal facts：

- Pipeline descriptor：token-backed `MTLRenderPipelineDescriptor` create / destroy / no-draw configuration / runtime-local call facts 已封账。
- Shader library：embedded shader source contract、token-backed `MTLLibrary` lifecycle、vertex / fragment `MTLFunction` lookup 与 runtime-local call facts 已封账。
- Pipeline state：token-backed `MTLRenderPipelineState` create / classify / destroy、dependency ordering、double destroy fail-closed 与 runtime-local call facts 已封账。
- Vertex buffer：token-backed `MTLBuffer` lifecycle、static triangle position / color data upload、layout facts 与 runtime-local call facts 已封账。
- Draw input：draw call still-blocked C ABI 与 `CjguiInternalRendererNoDrawInputBundleReadiness` 已把 pipeline state runtime facts 与 vertex buffer runtime facts 聚合为 internal dehydrated facts。

这些事实只说明未来 encoder / draw 前置输入已具备独立的 no-submit 证据。它们不代表 encoder 已存在，不代表 pipeline / vertex buffer 已绑定，不代表 draw 可执行。

## 仍然缺失

当前仍不能创建 render command encoder，原因不是 pipeline state、shader、descriptor 或 vertex buffer 缺失，而是 display-backed chain 尚未进入 production lifetime：

- Production drawable texture lifetime 未实现。
- `MTLRenderPassDescriptor.colorAttachments[0]` 尚未配置。
- Production drawable acquire / classify / release token lifecycle 尚未建立。
- Drawable / descriptor / layer / device cleanup co-ownership 尚未证明。
- Visible-window / bounded run loop / display-backed layer 在 production harness 中仍未被固定。

因此最小 blocker 是 production drawable texture lifetime，随后才是 render pass descriptor color attachment first slice。没有合法 drawable texture 与 color attachment 时，render command encoder creation 仍必须保持 fail-closed。

## 下一主线

下一主线优先回到：

`P1 internal Renderer production drawable texture lifetime first slice preflight decision`

选择 C 的原因是：isolated visible-window no-present probe 已经证明 `nextDrawable` 在隔离环境可观察，但 production runtime 仍缺 drawable token-local lifetime、release / stale / double-release 分类与 cleanup co-ownership。若直接回到 color attachment，会继续缺 production drawable texture 的 ownership 证据；当时更合适的下一刀是先做 production drawable texture lifetime first slice preflight，判断能否在不 present、不 command buffer、不 render 的前提下建立极窄 lifetime support。该下一刀已完成 blocker refresh，最新 recovery decision 已确认应把 visible-window production harness 拆为独立分支，当前唯一后续入口转为 `P1 internal Renderer visible-window production harness preflight decision`。

## 不再继续堆叠同构 no-submit wrapper

No-submit 分支已完成 pipeline descriptor、shader library、pipeline state、vertex buffer 与 draw input bundle 的事实闭环。继续新增同构 no-submit wrappers 不会解除 encoder blocker。后续应回到 drawable / color attachment / encoder 阻塞链，而不是继续包装 draw input bundle。

## 禁止误读

本轮不是 runtime truth，不授予 render command encoder creation、`renderCommandEncoderWithDescriptor`、`setRenderPipelineState`、`setVertexBuffer`、draw、`commit`、`present`、GPU submission、render、renderer state write、backend-ready truth、public API、public diagnostics、pointer / handle / `id` / `Class` return 权限。

No-submit branch 的价值是为未来 encoder / draw 提供 pipeline state、shader、descriptor、vertex buffer 与 draw input facts；它不替代 display-backed drawable chain，不替代 color attachment，不替代 render command encoder。

## 设计意图出口自检

- 本轮是否改变主题状态：是，no-submit render pipeline branch 从 draw input bundle 后续入口转为 milestone reconciliation。
- 本轮是否改变 canonical tail / endpoint：否，runtime canonical tail 仍为 `CjguiInternalRendererNoDrawInputBundleReadiness` / `cjguiInternalExecuteDefaultRendererDrawInputBundleDraft()`。
- 本轮是否改变 owner / truth / stop-line：是，truth 增加 docs-only branch milestone / blocker facts；stop-line 继续禁止 encoder、binding、draw、commit、present、GPU submission、render、state write 与 public API。
- 本轮是否改变唯一 next opening：是，唯一 next opening 更新为 `P1 internal Renderer production drawable texture lifetime first slice preflight decision`。
- 是否同步 topic manifest：需要同步。
- 已同步哪些 topic manifest：将在 closure 与 milestone 同步 `renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。

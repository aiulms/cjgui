# No-submit 渲染管线分支归因收束复核

## 收束结果

本轮完成 docs-only reconciliation，选择 A + C。No-submit render pipeline branch 作为 milestone 封住；当时下一主线回到 `P1 internal Renderer production drawable texture lifetime first slice preflight decision`，后续已由 first slice blocker refresh 与 recovery decision 转为 `P1 internal Renderer visible-window production harness preflight decision`。

本轮没有新增 runtime owner，没有新增 native C ABI，没有修改 production native bridge，没有新增 probe，没有运行 encoder / draw / commit / present / GPU work。

## 当前 milestone 价值

No-submit branch 的价值是把未来 draw 所需输入拆成可审计的 internal facts：

- `MTLRenderPipelineDescriptor` lifecycle 与 no-draw configuration facts。
- Embedded shader source、`MTLLibrary` 与 `MTLFunction` lookup facts。
- `MTLRenderPipelineState` lifecycle 与 runtime-local call facts。
- `MTLBuffer` lifecycle、static triangle data upload 与 runtime-local call facts。
- Draw call still-blocked classification 与 draw input bundle facts。

这些事实为未来 encoder / draw 准备输入合同，但不改变 display-backed drawable chain 的阻塞状态。

## 仍然不能做什么

当前仍不能创建 render command encoder，也不能 draw。直接原因是 `MTLRenderPassDescriptor.colorAttachments[0]` 未配置；更早的 root blocker 是 production drawable texture lifetime 未成立。isolated visible-window no-present drawable acquisition 只是 probe evidence，不是 production drawable token / texture lifetime truth。

因此本轮不选择直接进入 color attachment implementation，也不选择创建 encoder feasibility probe；下一步必须先验证 production drawable acquire / classify / release、cleanup co-ownership 与 fail-closed semantics 是否能成立。该入口随后已由 [production drawable texture lifetime first slice blocker refresh](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-15-p1-renderer-production-drawable-texture-lifetime-first-slice-manifest.md) 接续，并确认 implementation 仍需 recovery。

## 同步范围

本轮同步以下入口与主题：

- [README.md](/Users/jiangxuanyang/Desktop/cangjie/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)
- [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)
- [DESIGN_INTENT_INDEX.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/DESIGN_INTENT_INDEX.md)
- [renderer-implementation-admission-chain.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/renderer-implementation-admission-chain.md)
- [renderer-backend-readiness-real-backend-runway.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md)
- [macos-bridge-verification-smoke.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/macos-bridge-verification-smoke.md)

## 验证策略

本轮 docs-only，因此不运行 `cjpm build` / smoke。必须运行 `git diff --check`、Markdown absolute link check、reachability、中文标题正文抽查、public declaration scan、protected path scan 与 GitNexus detect-changes。

## 设计意图出口自检

- 本轮是否改变主题状态：是，no-submit branch 从继续推进入口转为 milestone + blocker reconciliation。
- 本轮是否改变 canonical tail / endpoint：否，仍是 `CjguiInternalRendererNoDrawInputBundleReadiness`。
- 本轮是否改变 owner / truth / stop-line：是，truth 新增 docs-only milestone / blocker / next-mainline facts；stop-line 不放宽。
- 本轮是否改变唯一 next opening：是，当时改为 `P1 internal Renderer production drawable texture lifetime first slice preflight decision`；后续已由 first slice blocker refresh 与 recovery decision 转为 `P1 internal Renderer visible-window production harness preflight decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。

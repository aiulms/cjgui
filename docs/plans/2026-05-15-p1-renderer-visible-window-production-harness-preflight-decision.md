# Renderer visible-window production harness 预检裁定

## 本轮裁定

本轮选择 A：打开 `visible-window production harness policy value boundary`，下一步只能先新增 internal value-style owner，固定 production visible-window harness 的 owner / truth / stop-line / fail-closed policy。

唯一后续入口：

`P1 internal Renderer visible-window production harness policy value boundary bundle implementation`

本轮不批准直接实现 production `NSWindow` harness，不新增 native C ABI，不修改 production native bridge，不新增 probe，不调用 production `nextDrawable`，不配置 render pass descriptor color attachment，不创建 command buffer / render command encoder，不 `commit` / `present`，不提交 GPU work，不执行 render，不写 renderer state，不扩 public API。

## 上游固定

本轮读取并复核以下上游：

- [Drawable texture lifetime 实现恢复清单](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-15-p1-renderer-drawable-texture-lifetime-implementation-recovery-manifest.md)
- [Drawable texture lifetime 实现恢复裁定](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-15-p1-renderer-drawable-texture-lifetime-implementation-recovery-decision.md)
- [生产 drawable texture lifetime 第一切片清单](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-15-p1-renderer-production-drawable-texture-lifetime-first-slice-manifest.md)
- [No-submit 渲染管线分支里程碑清单](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-15-p1-renderer-no-submit-render-pipeline-branch-milestone-manifest.md)
- [绘制调用 no-submit 清单](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-15-p1-renderer-draw-call-no-submit-manifest.md)
- [Drawable 可见窗口 probe 清单](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-drawable-visible-window-acquisition-probe-manifest.md)
- [Drawable no-present acquisition 清单](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-drawable-no-present-acquisition-manifest.md)
- [渲染通道描述符颜色附件恢复清单](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-render-pass-descriptor-color-attachment-recovery-manifest.md)
- [MTLCommandBuffer 创建路线封账清单](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-command-buffer-creation-runway-manifest.md)

## 预检结论

可以打开 visible-window production harness 分支，但第一刀不能是 native implementation。

原因是当前证据已经足够说明 display chain 的最小 blocker 是 production visible-window harness，而不是继续堆叠 no-submit facts；但证据仍不足以直接创建 production `NSWindow`、保存 platform object、运行 production bounded run loop 或把 isolated probe 迁入 runtime truth。

下一刀必须先在 runtime internal owner 中表达以下 value facts：

- visible-window harness intent。
- production `NSWindow` ownership policy。
- bounded run loop policy。
- display-backed `CAMetalLayer` prerequisite。
- token-backed `NSView` / `CAMetalLayer` / `MTLDevice` alignment policy。
- cleanup co-ownership policy。
- headless / CI-like shell fail-closed policy。
- no-drawable-acquire readiness facts。

## 路线选择

选择 A：`visible-window production harness policy value boundary bundle implementation`。

该路线只允许新增 internal `.cj` owner，默认候选为 `runtime/cjgui/src/runtime_renderer_visible_window_production_harness.cj`。它只消费已封账的 drawable texture lifetime planning / recovery facts 与 no-submit milestone facts，并输出 no-visible-window-harness-readiness value facts。

拒绝 B：直接进入 production native harness implementation。

原因是 production `NSWindow` ownership、bounded run loop ownership、display-backed layer ownership 与 cleanup co-ownership 尚未被 runtime owner 固定。直接改 native bridge 会把 isolated probe 的临时窗口语义搬进 production runtime。

拒绝 C：直接恢复 production drawable acquire / classify / release。

原因是 production drawable lifetime 仍缺 visible-window harness；直接调用 production `nextDrawable` 会越过当前 stop-line。

拒绝 D：继续堆叠 no-submit wrapper。

原因是 no-submit branch 已封为 milestone。继续新增 pipeline / vertex / draw 同构 facts 不会解除 display chain blocker。

拒绝 E：停止等待用户方向。

原因是上游 recovery manifest 已经明确下一块最小缺口；当前用户也确认旧 guard 不再阻塞本 stage autopilot。

## 下一刀写集

下一刀允许的最宽写集：

- `runtime/cjgui/src/runtime_renderer_visible_window_production_harness.cj`
- `docs/plans/` 中对应 closure / next-boundary / manifest
- [README.md](/Users/jiangxuanyang/Desktop/cangjie/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)
- [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)
- [DESIGN_INTENT_INDEX.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/DESIGN_INTENT_INDEX.md)
- [renderer-implementation-admission-chain.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/renderer-implementation-admission-chain.md)
- [renderer-backend-readiness-real-backend-runway.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md)
- [macos-bridge-verification-smoke.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/macos-bridge-verification-smoke.md)

下一刀若新增 `.cj` owner，必须包含中文文件头维护注释，说明 owner / truth / stop-line / Same-shape Boundary Brake。

## 下一刀禁止事项

下一刀仍不得：

- 修改 `runtime/cjgui/cjpm.toml`。
- 修改 `runtime/cjgui/src/runtime_state.cj`。
- 修改 smoke native files。
- 修改 production native `.h` / `.m`。
- 新增 native C ABI。
- 新增 `foreign func`。
- 新增 probe script。
- 创建 production `NSWindow` / `NSView` / `CAMetalLayer` / `MTLDevice`。
- 调用 production `nextDrawable`。
- 保存或返回 native pointer / handle / `id` / `Class`。
- 配置 `colorAttachments[0]`。
- 创建 command buffer / render command encoder。
- 调用 `setRenderPipelineState` / `setVertexBuffer`。
- 调用 `drawPrimitives` / `drawIndexedPrimitives`。
- 调用 `commit` / `present`。
- 提交 GPU work。
- 执行 render。
- 写 renderer state。
- 新增 public API / public diagnostics。

## 当前 truth

本轮只固定以下 truth：

- visible-window production harness 可以作为独立分支打开。
- 该分支第一刀必须是 value-style policy boundary。
- Isolated visible-window / no-present evidence 仍只能作为 feasibility evidence。
- No-submit milestone 仍是非显示链输入合同，不是 render permission。
- Production drawable lifetime 仍等待 harness policy owner 后再恢复。
- Render pass descriptor color attachment 仍等待 production drawable lifetime。

## 当前 canonical tail

本轮未新增 runtime endpoint。

当前可引用 tail 仍是：

- Drawable lifetime planning tail：`CjguiInternalRendererNoDrawableTextureLifetimePlanningReadiness` / `cjguiInternalExecuteDefaultRendererDrawableTextureLifetimePlanningDraft()`
- No-submit milestone tail：`CjguiInternalRendererNoDrawInputBundleReadiness` / `cjguiInternalExecuteDefaultRendererDrawInputBundleDraft()`

## 设计意图出口自检

- 本轮是否改变主题状态：是。visible-window production harness 从 recovery 后续入口进入已预检、可开 value boundary 的状态。
- 本轮是否改变 canonical tail / endpoint：否。本轮未新增 runtime owner 或 endpoint。
- 本轮是否改变 owner / truth / stop-line：是。truth 固定下一刀只能先做 harness policy value owner；stop-line 继续禁止 production `nextDrawable`、color attachment、encoder、draw、commit、present、GPU submission、render、renderer state write 与 public API。
- 本轮是否改变唯一 next opening：是。唯一后续入口转为 `P1 internal Renderer visible-window production harness policy value boundary bundle implementation`。
- 是否同步 topic manifest：需要同步。
- 已同步哪些 topic manifest：本轮应同步 `renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md` 与 `macos-bridge-verification-smoke.md`。

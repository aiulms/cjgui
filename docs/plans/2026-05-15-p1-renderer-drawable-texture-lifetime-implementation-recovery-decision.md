# 可绘制纹理生命周期实现恢复裁定

## 本轮裁定

本轮选择 A：`recovery decision only`，确认 production drawable lifetime 暂停，并把 visible-window ownership / bounded run loop / display backing / cleanup co-ownership 拆成独立后续分支。

唯一后续入口：

`P1 internal Renderer visible-window production harness preflight decision`

本轮不新增 production drawable acquire / classify / release C ABI，不新增 drawable token table，不调用 production `nextDrawable`，不配置 render pass descriptor color attachment，也不创建 command buffer / encoder。

## 上游固定

本轮读取并复核以下上游：

- [production drawable texture lifetime first slice manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-15-p1-renderer-production-drawable-texture-lifetime-first-slice-manifest.md)
- [production drawable texture lifetime first slice closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-15-p1-internal-renderer-production-drawable-texture-lifetime-first-slice-stage-closure-review.md)
- [production drawable texture lifetime first slice next-boundary](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-15-p1-renderer-production-drawable-texture-lifetime-first-slice-next-boundary-decision.md)
- [drawable texture lifetime implementation recovery manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-drawable-texture-lifetime-implementation-recovery-manifest.md)
- [drawable no-present acquisition manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-drawable-no-present-acquisition-manifest.md)
- [drawable visible-window probe manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-drawable-visible-window-acquisition-probe-manifest.md)
- [no-submit render pipeline branch milestone manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-15-p1-renderer-no-submit-render-pipeline-branch-milestone-manifest.md)
- [render pass descriptor color attachment recovery manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-render-pass-descriptor-color-attachment-recovery-manifest.md)
- [Metal device binding runway manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-metal-device-binding-runway-manifest.md)
- [CAMetalLayer runtime attachment manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-cametallayer-runtime-attachment-ffi-call-owner-manifest.md)

## runtime input 取舍

上一轮 first slice manifest 明确没有新增 `CjguiInternalRendererNoDrawableTextureLifetimeFirstSlicePlanningReadiness`。因此本轮不把该未创建 endpoint 当成 runtime input。

当前可引用的 tail 仍是：

- Drawable lifetime planning tail：`CjguiInternalRendererNoDrawableTextureLifetimePlanningReadiness` / `cjguiInternalExecuteDefaultRendererDrawableTextureLifetimePlanningDraft()`
- No-submit milestone tail：`CjguiInternalRendererNoDrawInputBundleReadiness` / `cjguiInternalExecuteDefaultRendererDrawInputBundleDraft()`

本轮不新增 runtime owner，因此不改变 canonical endpoint。

## 为什么 isolated evidence 不能升格

`CjguiInternalRendererNoDrawableVisibleWindowProbeReadiness` 和 `CjguiInternalRendererNoDrawableNoPresentAcquisitionReadiness` 只证明 isolated probe 可以临时创建可见窗口环境，并在 bounded path 中观察 no-present `nextDrawable`。

这些证据缺少 production runtime 必须承担的所有权：

- 没有 production visible `NSWindow` ownership。
- 没有 production bounded run loop ownership。
- 没有 production display-backed layer ownership。
- 没有 drawable token table。
- 没有 acquire / classify / release lifecycle。
- 没有 released / stale / double release fail-closed classification。
- 没有 descriptor / drawable / layer / device / view cleanup co-ownership。

因此 isolated probe 只能保留为 feasibility evidence，不能直接成为 production runtime truth。

## 是否继续尝试 acquire / release

不应继续在本阶段尝试 production drawable acquire / release。

如果直接新增 production acquire / release callable，会出现两种不安全形态：

- 在没有 production visible-window harness 的路径上调用 `nextDrawable`，这会重新落入 display backing / run loop 不稳定问题。
- 把 isolated visible-window probe 的临时窗口语义搬进 production bridge，这会绕过 harness preflight，污染 production runtime semantics。

两条路径都不满足当前 stop-line。

## 是否拆出独立分支

应该拆出独立分支：visible-window production harness。

该分支必须先回答 production 是否允许拥有可见窗口 harness、bounded run loop、display-backed `CAMetalLayer` 关系、cleanup order、headless / CI-like shell 降级策略，以及该 harness 是否仍保持 internal-only、不写 renderer state、不扩 public API。

在该分支封账前，不应打开 production drawable token-local acquire / release。

## no-submit branch 结论

No-submit branch 已足够作为非显示链 milestone。

它已经固定 pipeline descriptor、shader library / function、pipeline state、vertex buffer 与 draw input bundle facts；继续堆叠同构 no-submit wrapper 不会解除 display chain blocker。

当前最小 blocker 仍是 visible-window production harness；其后才是 production drawable texture lifetime，再后才是 render pass descriptor color attachment 与 render command encoder。

## 本轮不是 runtime truth

本轮只做 recovery decision，不新增 runtime owner，不新增 native C ABI，不新增 probe，不修改 package config。

本轮不授予：

- production drawable acquisition permission
- color attachment permission
- render command encoder permission
- command buffer creation permission
- present / commit permission
- GPU submission permission
- render permission
- renderer state write permission
- backend-ready truth
- public API / diagnostics permission

## 设计意图出口自检

- 本轮是否改变主题状态：是。drawable lifetime implementation recovery 从“继续追 first slice”转为“拆出 visible-window production harness 分支”。
- 本轮是否改变 canonical tail / endpoint：否。未新增 owner，仍引用 drawable lifetime planning tail 与 no-submit milestone tail。
- 本轮是否改变 owner / truth / stop-line：是。truth 增加“isolated evidence 不能升格，下一步必须先证明 visible-window production harness”；stop-line 继续禁止 production `nextDrawable`。
- 本轮是否改变唯一 next opening：是。唯一后续入口转为 `P1 internal Renderer visible-window production harness preflight decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md` 与 `macos-bridge-verification-smoke.md`。

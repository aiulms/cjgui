# Drawable texture lifetime 实现恢复清单

日期：2026-05-11

状态：manifest / completed through docs-only recovery decision

## 固定尾点

- Recovery route：B
- Runtime canonical endpoint：`CjguiInternalRendererNoDrawableTextureLifetimePlanningReadiness`
- Runtime canonical default draft：`cjguiInternalExecuteDefaultRendererDrawableTextureLifetimePlanningDraft()`
- Runtime input：`CjguiInternalRendererNoRenderPassDescriptorColorAttachmentRecoveryReadiness`
- Upstream owner：[runtime_renderer_drawable_texture_lifetime_planning.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_drawable_texture_lifetime_planning.cj)

## 实际路线

本阶段完成 recovery decision only：

- 确认 production drawable lifetime 暂停。
- 确认 visible-window production harness 应作为独立 recovery / experiment 分支。
- 确认 command buffer / descriptor 已能支持 render command encoder no-submit planning 的前置分析。
- 确认 encoder no-submit planning 不等于 encoder creation。

本阶段未进入：

- production drawable acquire / classify / release。
- production drawable token table。
- production `nextDrawable`。
- color attachment implementation。
- render command encoder creation。
- draw / `commit` / `present`。
- GPU submission。
- render。
- renderer state write。

## Blocker 清单

Production drawable lifetime 当前仍缺：

- visible `NSWindow` ownership。
- bounded run loop production harness。
- display-backed layer ownership。
- drawable token table。
- acquire / classify / release semantics。
- released / stale / double release fail-closed classification。
- descriptor / drawable / layer / device cleanup co-ownership。

## 可先行事项

Render command encoder no-submit planning 可以先行，前提是下一阶段仍保持：

- 只做 planning / admission facts。
- 不创建 render command encoder。
- 不配置 `colorAttachments[0]`。
- 不绑定 drawable texture。
- 不 draw。
- 不调用 `commit` / `present`。
- 不提交 GPU work。
- 不执行 render。
- 不写 renderer state。

## 上游与下游指向

上游固定：

- [production drawable texture lifetime manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-production-drawable-texture-lifetime-manifest.md)
- [color attachment recovery manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-render-pass-descriptor-color-attachment-recovery-manifest.md)
- [drawable no-present acquisition manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-drawable-no-present-acquisition-manifest.md)
- [drawable visible-window probe manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-drawable-visible-window-acquisition-probe-manifest.md)
- [command buffer creation manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-command-buffer-creation-runway-manifest.md)
- [command queue creation manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-command-queue-creation-runway-manifest.md)
- [render pass descriptor manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-render-pass-descriptor-runway-manifest.md)
- [Metal device binding manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-metal-device-binding-runway-manifest.md)
- [CAMetalLayer runtime attachment manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-cametallayer-runtime-attachment-ffi-call-owner-manifest.md)

下游已接续：

- [render command encoder no-submit planning manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-render-command-encoder-no-submit-planning-manifest.md)
- [render command encoder 创建阻塞归因清单](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-render-command-encoder-creation-blocker-reconciliation-manifest.md)
- [pipeline state encoder 绑定阻塞归因清单](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-14-p1-renderer-pipeline-state-encoder-binding-blocker-reconciliation-manifest.md)

该接续选择 A 后继续进入 blocker reconciliation：只新增 no-submit planning owner，不创建 encoder，不配置 color attachment，不绑定 drawable texture，也不新增 native C ABI；随后确认 production drawable texture lifetime 与 `colorAttachments[0]` 是 encoder creation 的双重缺口。后续 pipeline state encoder binding blocker reconciliation、vertex buffer no-submit、draw call no-submit 与 no-submit render pipeline branch milestone 均未解除 production drawable / color attachment blocker；当前主线已完成 [production drawable texture lifetime first slice blocker refresh](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-15-p1-renderer-production-drawable-texture-lifetime-first-slice-manifest.md)，并由 [latest drawable texture lifetime implementation recovery manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-15-p1-renderer-drawable-texture-lifetime-implementation-recovery-manifest.md) 确认 isolated visible-window no-present evidence 仍不能升格为 production runtime truth，唯一后续入口转为 `P1 internal Renderer visible-window production harness preflight decision`。

## 停止线

不 present，不调用 `presentDrawable` / `present`，不新增 production drawable acquire / classify / release C ABI，不调用 production `nextDrawable`，不配置 `colorAttachments[0]`，不创建 render command encoder，不 draw，不调用 `commit`，不提交 GPU work，不执行 render，不写 renderer state，不触碰 `runtime_state.cj`，不修改 `runtime/cjgui/cjpm.toml`，不修改 smoke native files，不新增 public API / diagnostics，不返回 native pointer / handle / `id` / `Class`，不把 recovery decision 包装成 render permission、GPU submission permission、backend-ready truth 或 state write permission。

## 唯一后续入口

`P1 internal Renderer drawable texture lifetime implementation recovery decision`

# Production drawable texture lifetime 清单

日期：2026-05-11

状态：manifest / completed through planning-only lifetime facts

## 固定尾点

- Endpoint：`CjguiInternalRendererNoDrawableTextureLifetimePlanningReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererDrawableTextureLifetimePlanningDraft()`
- Runtime input：`CjguiInternalRendererNoRenderPassDescriptorColorAttachmentRecoveryReadiness`
- Upstream endpoint：`CjguiInternalRendererNoRenderPassDescriptorColorAttachmentRecoveryReadiness`
- Upstream owner：[runtime_renderer_render_pass_descriptor_color_attachment_recovery.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_render_pass_descriptor_color_attachment_recovery.cj)

## Owner 文件

- [runtime_renderer_drawable_texture_lifetime_planning.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_drawable_texture_lifetime_planning.cj)

## Probe

- [verify_native_bridge_drawable_texture_lifetime.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_native_bridge_drawable_texture_lifetime.sh)

## 实际路线

本阶段完成 A：

- production drawable texture lifetime planning / ownership facts。
- 固定 production visible window semantics requirement。
- 固定 display-backed layer ownership requirement。
- 固定 token-local acquire / classify / release requirement。
- 固定 double release / stale drawable fail-closed requirement。
- 固定 descriptor / drawable / layer / device cleanup co-ownership requirement。

本阶段未进入：

- production drawable acquire / classify / release C ABI。
- production drawable token table。
- production `nextDrawable`。
- runtime FFI call owner。
- descriptor color attachment first slice。
- render command encoder。
- `commit` / `present`。
- GPU submission。
- render。
- renderer state write。

## 固定事实

- Isolated visible-window no-present probe 可以观察 drawable，但不是 production runtime truth。
- Production runtime 当前仍没有 drawable token / texture lifetime support。
- Production runtime 当前仍没有 drawable release / stale / double release classification。
- Production runtime 当前仍没有 descriptor / drawable / layer / device cleanup 共同所有权。
- 本阶段 probe 只验证 still-blocked C ABI 与 planning owner，不调用 `nextDrawable`。

## 上游与下游指向

上游固定：

- [Color attachment recovery manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-render-pass-descriptor-color-attachment-recovery-manifest.md)
- [Drawable no-present acquisition manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-drawable-no-present-acquisition-manifest.md)
- [Drawable visible-window acquisition probe manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-drawable-visible-window-acquisition-probe-manifest.md)
- [Drawable environment / window visibility manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-drawable-environment-window-visibility-manifest.md)
- [Metal device binding manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-metal-device-binding-runway-manifest.md)
- [CAMetalLayer runtime attachment FFI call owner manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-cametallayer-runtime-attachment-ffi-call-owner-manifest.md)
- [Native token issue / revoke manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-native-token-table-no-resource-issue-revoke-manifest.md)
- [Native bridge teardown admission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-native-bridge-teardown-callable-implementation-manifest.md)

下游已接续：

- [Drawable texture lifetime implementation recovery manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-drawable-texture-lifetime-implementation-recovery-manifest.md)

该接续选择 B：production drawable lifetime 暂停，visible-window production harness 作为独立 recovery / experiment 分支，主线下一步转向 render command encoder no-submit planning。随后 [render command encoder no-submit planning manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-render-command-encoder-no-submit-planning-manifest.md)、[render command encoder 创建阻塞归因清单](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-render-command-encoder-creation-blocker-reconciliation-manifest.md)、pipeline descriptor / shader / pipeline state / vertex buffer / draw input no-submit 链与 [No-submit 渲染管线分支里程碑清单](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-15-p1-renderer-no-submit-render-pipeline-branch-milestone-manifest.md) 已接续该入口；下游仍未新增 production drawable C ABI，未调用 production `nextDrawable`，未配置 color attachment，未创建 render command encoder，未 draw，未调用 `commit` / `present`，未提交 GPU work，未执行 render，未写 renderer state。当前主线已完成 [production drawable texture lifetime first slice blocker refresh](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-15-p1-renderer-production-drawable-texture-lifetime-first-slice-manifest.md)，并由 [latest drawable texture lifetime implementation recovery manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-15-p1-renderer-drawable-texture-lifetime-implementation-recovery-manifest.md) 确认该 blocker 需要拆成 visible-window production harness 分支。

## 停止线

不 present，不调用 `presentDrawable` / `present`，不创建 command buffer / encoder，不调用 `commit`，不提交 GPU work，不执行 render，不写 renderer state，不触碰 `runtime_state.cj`，不修改 `runtime/cjgui/cjpm.toml`，不修改 smoke native files，不新增 public API / diagnostics，不返回 native pointer / handle / `id` / `Class`，不把 planning facts 解释成 render permission、GPU submission permission、backend-ready truth 或 state write permission。

## 当时唯一后续入口

`P1 internal Renderer drawable texture lifetime implementation recovery decision`

## 当前下游入口

`P1 internal Renderer visible-window production harness preflight decision`

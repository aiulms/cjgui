# 渲染通道描述符颜色附件恢复清单

日期：2026-05-11

状态：manifest / completed through recovery blocker facts

## 固定尾点

- Endpoint：`CjguiInternalRendererNoRenderPassDescriptorColorAttachmentRecoveryReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererRenderPassDescriptorColorAttachmentRecoveryDraft()`
- Runtime input：`CjguiInternalRendererNoRenderPassDescriptorColorAttachmentPlanningReadiness`
- Upstream endpoint：`CjguiInternalRendererNoRenderPassDescriptorColorAttachmentPlanningReadiness`
- Upstream owner：[runtime_renderer_render_pass_descriptor_color_attachment.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_render_pass_descriptor_color_attachment.cj)

## Owner 文件

- [runtime_renderer_render_pass_descriptor_color_attachment_recovery.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_render_pass_descriptor_color_attachment_recovery.cj)

## Probe

- [verify_native_bridge_render_pass_descriptor_color_attachment_recovery.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_native_bridge_render_pass_descriptor_color_attachment_recovery.sh)

## 实际路线

本阶段完成 A：

- recovery analysis / blocker manifest。
- 固定 production drawable token / texture lifetime 缺口。
- 固定 descriptor / drawable / layer / device cleanup 共同所有权缺口。
- 固定 isolated no-present drawable evidence 不能作为 production descriptor truth。

本阶段未进入：

- production drawable token-local acquisition support。
- descriptor color attachment first slice。
- color attachment runtime FFI call owner。
- `colorAttachments[0]` configuration。
- drawable texture binding。
- load / store action configuration。
- clear color configuration。
- render command encoder creation。
- draw / `commit` / `present`。
- GPU submission。
- render。
- renderer state write。

## 固定事实

- 上游 `MTLRenderPassDescriptor` create / destroy lifecycle 已可观察，但只说明 descriptor token lifecycle。
- 上游 drawable no-present acquisition 是 isolated visible-window probe evidence。
- Production runtime 当前没有 drawable token table、drawable texture lifetime support 或 drawable release / cleanup callable。
- Production runtime 当前没有 descriptor / drawable / layer / device cleanup 共同所有权。
- Color attachment implementation 必须先进入 production drawable texture lifetime preflight。

## 上游与下游指向

上游固定：

- [Color attachment planning manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-render-pass-descriptor-color-attachment-manifest.md)
- [Render pass descriptor create / destroy manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-render-pass-descriptor-runway-manifest.md)
- [Drawable no-present acquisition manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-drawable-no-present-acquisition-manifest.md)
- [Command buffer creation manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-command-buffer-creation-runway-manifest.md)
- [Metal device binding manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-metal-device-binding-runway-manifest.md)

当时下游唯一接续：

- `P1 internal Renderer production drawable texture lifetime preflight decision`

## 下游已接续

本阶段已由 [production drawable texture lifetime 清单](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-production-drawable-texture-lifetime-manifest.md) 接续。下游只新增 planning owner 与 planning probe，固定 production visible window semantics、display-backed layer ownership、drawable token-local acquire / classify / release、double release / stale drawable fail-closed 与 descriptor / drawable / layer / device cleanup 共同所有权缺口；仍未新增 production drawable C ABI，未调用 production `nextDrawable`，未配置 color attachment，未 present，未创建 command buffer / encoder，未调用 `commit`，未提交 GPU work，未执行 render，未写 renderer state。

随后已由 [drawable texture lifetime implementation recovery manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-drawable-texture-lifetime-implementation-recovery-manifest.md) 接续。该恢复决策选择暂停 production drawable lifetime implementation，保留 visible-window production harness 为独立分支，并允许下一步只做 render command encoder no-submit planning；它不授权 color attachment、encoder creation、draw、`commit`、`present`、GPU submission、render、public API 或 renderer state write。

随后又由 [render command encoder no-submit planning manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-render-command-encoder-no-submit-planning-manifest.md)、[render command encoder 创建阻塞归因清单](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-render-command-encoder-creation-blocker-reconciliation-manifest.md)、[pipeline state encoder 绑定阻塞归因清单](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-14-p1-renderer-pipeline-state-encoder-binding-blocker-reconciliation-manifest.md) 与 [No-submit 渲染管线分支里程碑清单](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-15-p1-renderer-no-submit-render-pipeline-branch-milestone-manifest.md) 接续。该接续只记录 encoder / binding / no-submit milestone facts，并确认 production drawable texture lifetime 与 `colorAttachments[0]` 是双重缺口；不配置 color attachment，不绑定 drawable texture，不创建 encoder，不绑定 pipeline。

当前又由 [production drawable texture lifetime first slice 清单](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-15-p1-renderer-production-drawable-texture-lifetime-first-slice-manifest.md) 与 [latest drawable texture lifetime implementation recovery manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-15-p1-renderer-drawable-texture-lifetime-implementation-recovery-manifest.md) 复核：production drawable lifetime first slice 仍 blocked，因此 color attachment first slice 不能打开；当前唯一后续入口转为 `P1 internal Renderer visible-window production harness preflight decision`。

## 停止线

不配置 `colorAttachments[0]`，不绑定 drawable texture，不设置 load / store action，不设置 clear color，不创建 render command encoder，不调用 `renderCommandEncoderWithDescriptor`，不 draw，不调用 `commit`，不 present，不提交 GPU work，不执行 render，不写 renderer state，不触碰 `runtime_state.cj`，不修改 `runtime/cjgui/cjpm.toml`，不修改 smoke native files，不新增 public API / diagnostics，不返回 native pointer / handle / `id` / `Class`，不把 recovery facts 解释成 render permission、GPU submission permission、backend-ready truth 或 state write permission。

## 唯一后续入口

当时唯一后续入口为：

`P1 internal Renderer production drawable texture lifetime preflight decision`

当前已由 production drawable texture lifetime planning、implementation recovery、render command encoder no-submit planning、blocker reconciliation、pipeline descriptor no-draw、shader library no-draw、pipeline state create/destroy no-draw、pipeline state encoder binding blocker reconciliation、vertex buffer no-submit、draw call no-submit、no-submit branch milestone、production drawable texture lifetime first slice blocker refresh 与 latest implementation recovery decision 接续；当前主线唯一后续入口已转为：

`P1 internal Renderer visible-window production harness preflight decision`

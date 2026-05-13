# 渲染通道描述符颜色附件规划清单

日期：2026-05-11

状态：manifest / completed through color attachment planning facts

## 固定尾点

- Endpoint：`CjguiInternalRendererNoRenderPassDescriptorColorAttachmentPlanningReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererRenderPassDescriptorColorAttachmentPlanningDraft()`
- Runtime input：`CjguiInternalRendererNoRenderPassDescriptorCreateDestroyReadiness`
- Upstream endpoint：`CjguiInternalRendererNoRenderPassDescriptorCreateDestroyReadiness`
- Upstream owner：[runtime_renderer_render_pass_descriptor_create_destroy.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_render_pass_descriptor_create_destroy.cj)

## Owner 文件

- [runtime_renderer_render_pass_descriptor_color_attachment.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_render_pass_descriptor_color_attachment.cj)

## 实际路线

本阶段完成 A：

- color attachment planning / dependency facts。
- 固定 production drawable texture lifecycle 仍缺。
- 固定 isolated drawable acquisition evidence 不能配置 production descriptor。

本阶段未进入：

- production native C ABI。
- `colorAttachments[0]` configuration。
- drawable texture binding。
- load / store action configuration。
- clear color configuration。
- runtime FFI owner for configured descriptor。
- render command encoder creation。
- draw / `commit` / `present`。
- GPU submission。
- render。
- renderer state write。

## 固定事实

- Descriptor create / destroy tail 已由 `CjguiInternalRendererNoRenderPassDescriptorCreateDestroyReadiness` 保持。
- `colorAttachments[0]` 当前仍 blocked。
- Drawable texture 只有 isolated no-present probe evidence，不是 production token-backed drawable lifecycle。
- descriptor / drawable / layer / device cleanup 的共同所有权仍未进入 production contract。
- attachment implementation 必须先补 production drawable texture lifecycle 或明确 recovery path。
- 本 owner 不新增 native C ABI，不调用 native attachment callable，不持久化 token。

## 上游与下游指向

上游固定：

- [MTLRenderPassDescriptor 路线封账清单](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-render-pass-descriptor-runway-manifest.md)
- [Drawable no-present acquisition 清单](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-drawable-no-present-acquisition-manifest.md)
- [MTLCommandBuffer 创建路线封账清单](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-command-buffer-creation-runway-manifest.md)

下游已接续：

- [render pass descriptor color attachment recovery 清单](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-render-pass-descriptor-color-attachment-recovery-manifest.md)

该接续只固定 production drawable token / texture lifetime、descriptor / drawable / layer / device cleanup 共同所有权仍缺的 recovery facts；仍未配置 `colorAttachments[0]`。

## 停止线

不配置 `colorAttachments[0]`，不绑定 drawable texture，不设置 load / store action，不设置 clear color，不创建 render command encoder，不调用 `renderCommandEncoderWithDescriptor`，不 draw，不调用 `commit`，不 present，不提交 GPU work，不执行 render，不写 renderer state，不触碰 `runtime_state.cj`，不修改 `runtime/cjgui/cjpm.toml`，不修改 smoke native files，不新增 public API / diagnostics，不返回 native pointer / handle / `id` / `Class`，不把 planning facts 解释成 render permission、GPU submission permission、backend-ready truth 或 state write permission。

## 唯一后续入口

当时唯一后续入口为：

`P1 internal Renderer production drawable texture lifetime preflight decision`

该入口已由 production drawable texture lifetime planning、implementation recovery、no-submit planning 与 blocker reconciliation 接续；当前主线唯一后续入口已转为：

`P1 internal Renderer pipeline state no-draw planning preflight decision`

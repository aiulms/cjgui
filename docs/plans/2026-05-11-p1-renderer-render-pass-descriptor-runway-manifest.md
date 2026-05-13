# MTLRenderPassDescriptor 路线封账清单

日期：2026-05-11

状态：manifest / completed through token-backed render pass descriptor create-destroy facts

## 固定尾点

- Endpoint：`CjguiInternalRendererNoRenderPassDescriptorCreateDestroyReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererRenderPassDescriptorCreateDestroyDraft()`
- Runtime input：`CjguiInternalRendererNoCommandBufferRuntimeCallReadiness`
- Upstream endpoint：`CjguiInternalRendererNoCommandBufferRuntimeCallReadiness`
- Upstream owner：[runtime_renderer_command_buffer_runtime_call.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_command_buffer_runtime_call.cj)

## Owner 文件

- [runtime_renderer_render_pass_descriptor_create_destroy.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_render_pass_descriptor_create_destroy.cj)

## Probe

- [verify_native_bridge_render_pass_descriptor_create_destroy.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_native_bridge_render_pass_descriptor_create_destroy.sh)

## Native callable list

- `cjgui_native_bridge_render_pass_descriptor_table_capacity`
- `cjgui_native_bridge_render_pass_descriptor_table_enabled`
- `cjgui_native_bridge_render_pass_descriptor_table_occupied_count`
- `cjgui_native_bridge_render_pass_descriptor_create`
- `cjgui_native_bridge_render_pass_descriptor_destroy`
- `cjgui_native_bridge_render_pass_descriptor_token_classify`
- `cjgui_native_bridge_render_pass_descriptor_double_destroy_classify`
- `cjgui_native_bridge_render_pass_descriptor_create_requires_main_thread`
- `cjgui_native_bridge_render_pass_descriptor_destroy_requires_main_thread`
- `cjgui_native_bridge_render_pass_descriptor_color_attachment_still_blocked`
- `cjgui_native_bridge_render_pass_descriptor_encoder_creation_still_blocked`
- `cjgui_native_bridge_render_pass_descriptor_drawable_texture_still_blocked`

## 实际路线

本阶段完成 A/B：

- render pass descriptor planning / attachment requirement facts。
- token-backed `MTLRenderPassDescriptor` create / destroy first slice。

本阶段未进入：

- color attachment configuration。
- drawable texture binding。
- runtime FFI owner for configured descriptor。
- render command encoder creation。
- `draw` / `commit` / `present`。
- GPU submission。
- render。
- renderer state write。
- public API / diagnostics。

## 固定事实

- Descriptor table fixed capacity 为 `2`。
- Descriptor token 使用 opaque integer，不编码 native pointer。
- Descriptor table entry 仅由 production native bridge 持有，不暴露 pointer / handle / `id` / `Class`。
- Descriptor create / destroy 必须 main-thread。
- Invalid token、stale token、double destroy 与 background-thread create / destroy 均 fail-closed。
- Runtime internal owner 只在函数局部持有 token，并只输出 dehydrated facts。
- Color attachment、drawable texture 与 encoder creation 明确 still blocked。

## GitNexus 记录

- 上游 endpoint / default draft 与新增 descriptor owner / native callable 在当前索引中返回 `UNKNOWN` / not found / impactedCount `0`。
- 未出现 HIGH / CRITICAL 风险输出。
- 本阶段使用源码阅读、probe、`cjpm build`、native forbidden scan 与 public declaration scan 兜底。

## 上游与下游指向

上游固定：

- [Command buffer creation 路线封账清单](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-command-buffer-creation-runway-manifest.md)
- [Drawable no-present acquisition 清单](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-drawable-no-present-acquisition-manifest.md)
- [Metal device binding 路线封账清单](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-metal-device-binding-runway-manifest.md)

下游已接续：

- 已由 [render pass descriptor color attachment planning 清单](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-render-pass-descriptor-color-attachment-manifest.md) 接续。下游只新增 planning facts，确认 production drawable texture lifecycle 尚缺、isolated no-present drawable 不能作为 production descriptor truth、descriptor / drawable cleanup 共同所有权仍未证明；仍未配置 `colorAttachments[0]`。
- 已由 [render pass descriptor color attachment recovery 清单](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-render-pass-descriptor-color-attachment-recovery-manifest.md) 接续。该接续仍未配置 attachment，只把 production drawable token / texture lifetime 与 cleanup 共同所有权缺口固定为 recovery blocker。
- 已由 [drawable texture lifetime implementation recovery 清单](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-drawable-texture-lifetime-implementation-recovery-manifest.md) 接续。该接续确认 production drawable lifetime 暂停，descriptor lifecycle 可作为 encoder no-submit planning 上游，但不能配置 color attachment，也不能创建真实 render command encoder。
- 已由 [render command encoder no-submit planning 清单](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-render-command-encoder-no-submit-planning-manifest.md) 接续。该接续只固定 descriptor attachment missing 与 encoder creation blocked facts，不创建 encoder，不调用 `renderCommandEncoderWithDescriptor`。

## 停止线

不配置 color attachment，不绑定 drawable texture，不创建 render command encoder，不调用 `renderCommandEncoderWithDescriptor`，不 draw，不调用 `commit`，不 present，不提交 GPU work，不执行 render，不写 renderer state，不触碰 `runtime_state.cj`，不修改 `runtime/cjgui/cjpm.toml`，不修改 smoke native files，不新增 public API / diagnostics，不返回 native pointer / handle / `id` / `Class`，不把 descriptor lifecycle facts 解释成 render permission、GPU submission permission、backend-ready truth 或 state write permission。

## 唯一后续入口

`P1 internal Renderer pipeline state no-draw planning preflight decision`

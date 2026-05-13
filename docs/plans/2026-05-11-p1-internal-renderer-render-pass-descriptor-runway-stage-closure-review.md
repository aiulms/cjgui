# MTLRenderPassDescriptor 路线阶段封账复核

日期：2026-05-11

## 本轮结果

本阶段完成 A/B 路线：

- 新增 token-backed `MTLRenderPassDescriptor` create / destroy first slice。
- 新增 render pass descriptor runtime internal create / destroy owner。
- 新增 native create / destroy probe。
- 更新 command buffer probe 边界：production bridge 允许 descriptor create / destroy first slice，但仍禁止 encoder、draw、`commit`、`present`、GPU submission、render、pointer return 与 public API。

本阶段未进入 C/D：

- 未配置 color attachment。
- 未绑定 drawable texture。
- 未创建 render command encoder。
- 未新增 descriptor color attachment runtime call owner。

## 新增 owner

- [runtime_renderer_render_pass_descriptor_create_destroy.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_render_pass_descriptor_create_destroy.cj)

Canonical endpoint：

- `CjguiInternalRendererNoRenderPassDescriptorCreateDestroyReadiness`

Default draft：

- `cjguiInternalExecuteDefaultRendererRenderPassDescriptorCreateDestroyDraft()`

Runtime input：

- `CjguiInternalRendererNoCommandBufferRuntimeCallReadiness`

## 新增 native callable

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

## 验证摘要

已通过：

- [verify_native_bridge_render_pass_descriptor_create_destroy.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_native_bridge_render_pass_descriptor_create_destroy.sh)
- [verify_native_bridge_command_buffer_create_destroy.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_native_bridge_command_buffer_create_destroy.sh)
- [verify_native_bridge_command_buffer_runtime_call.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_native_bridge_command_buffer_runtime_call.sh)
- `cjpm build --target-dir /tmp/cjgui-renderer-render-pass-descriptor-early-target --skip-script`
- no-resource symbol probe

关键观察：

- descriptor create 返回 `0`。
- descriptor token 为非零 opaque integer。
- descriptor occupied count create 后 +1，destroy 后回到起点。
- descriptor classify 从 valid 变为 stale。
- double destroy fail-closed。
- invalid token destroy fail-closed。
- color attachment、encoder creation 与 drawable texture 仍返回 still-blocked classification。
- probe 未发现 encoder、draw、`commit`、`present`、GPU submission、render、pointer return 或 public API。

## 仍保持的停止线

本阶段没有配置 color attachment，没有绑定 drawable texture，没有创建 render command encoder，没有调用 `renderCommandEncoderWithDescriptor`，没有 draw，没有 `commit`，没有 `present`，没有提交 GPU work，没有执行 render，没有写 renderer state，没有触碰 `runtime_state.cj`，没有修改 `runtime/cjgui/cjpm.toml`，没有修改 smoke native files，没有新增 public API / public diagnostics，没有返回 native pointer / handle / `id` / `Class`。

## 设计意图出口自检

- 本轮是否改变主题状态：是，render pass descriptor create / destroy first slice 已完成。
- 本轮是否改变 canonical tail / endpoint：是，tail 固定为 `CjguiInternalRendererNoRenderPassDescriptorCreateDestroyReadiness`。
- 本轮是否改变 owner / truth / stop-line：是，owner 固定为 descriptor create / destroy owner；truth 只到 local token lifecycle facts；stop-line 禁止 color attachment / encoder / draw / commit / present / GPU / render / state / public。
- 本轮是否改变唯一 next opening：是，当时唯一 next opening 固定为 `P1 internal Renderer render pass descriptor color attachment preflight decision`；现已由 [render pass descriptor color attachment planning 清单](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-render-pass-descriptor-color-attachment-manifest.md) 接续。
- 是否同步 topic manifest：需要并纳入本轮同步。
- 已同步哪些 topic manifest：`renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。

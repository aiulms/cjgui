# 顶点缓冲 no-submit 阶段收束复核

本阶段完成 vertex buffer no-submit route A/B/C/D。新增 production native C ABI、runtime internal owner 与 probe，但仍不接 renderer backend truth。

## 本轮新增

- native callable：`cjgui_native_bridge_vertex_buffer_table_capacity`、`cjgui_native_bridge_vertex_buffer_table_enabled`、`cjgui_native_bridge_vertex_buffer_table_occupied_count`、`cjgui_native_bridge_vertex_buffer_create`、`cjgui_native_bridge_vertex_buffer_destroy`、`cjgui_native_bridge_vertex_buffer_token_classify`、`cjgui_native_bridge_vertex_buffer_double_destroy_classify`、`cjgui_native_bridge_vertex_buffer_upload_static_triangle`、`cjgui_native_bridge_vertex_buffer_data_classify`、`cjgui_native_bridge_vertex_buffer_create_requires_main_thread`、`cjgui_native_bridge_vertex_buffer_destroy_requires_main_thread`、`cjgui_native_bridge_vertex_buffer_upload_requires_main_thread`、`cjgui_native_bridge_vertex_buffer_layout_position_color`、`cjgui_native_bridge_vertex_buffer_encoder_binding_still_blocked`、`cjgui_native_bridge_vertex_buffer_draw_still_blocked`。
- runtime owner：[runtime_renderer_vertex_buffer_no_submit_planning.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_vertex_buffer_no_submit_planning.cj)、[runtime_renderer_vertex_buffer_create_destroy.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_vertex_buffer_create_destroy.cj)、[runtime_renderer_vertex_buffer_data_upload.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_vertex_buffer_data_upload.cj)、[runtime_renderer_vertex_buffer_runtime_call.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_vertex_buffer_runtime_call.cj)。
- native probe：[verify_native_bridge_vertex_buffer_create_destroy.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_native_bridge_vertex_buffer_create_destroy.sh)、[verify_native_bridge_vertex_buffer_data_upload.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_native_bridge_vertex_buffer_data_upload.sh)、[verify_native_bridge_vertex_buffer_runtime_call.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_native_bridge_vertex_buffer_runtime_call.sh)。

## 当前事实

`MTLBuffer` 由 token-backed fixed-capacity table 持有，容量固定为 2；token 来自既有 bridge-local generation token table，非 pointer cast。create / destroy / upload 均要求 main thread。device destroy 在 live vertex buffer 存在时 fail-closed。double destroy、stale token 与 invalid token 均 fail-closed。static triangle upload 只记录 position/color layout facts，不绑定 encoder，不执行 draw。

## 保持关闭

本阶段没有创建 render command encoder，没有调用 `setVertexBuffer`，没有 draw，没有 index buffer，没有 command buffer commit，没有 present，没有 GPU submission，没有 render，没有 renderer state write，没有 public API，没有 pointer / handle / `id` / `Class` return。

## 设计意图出口自检

- 本轮是否改变主题状态：是，vertex buffer 从 no-submit planning 进入 token-backed create / upload / runtime call facts。
- 本轮是否改变 canonical tail / endpoint：是，tail 更新为 `CjguiInternalRendererNoVertexBufferRuntimeCallReadiness` / `cjguiInternalExecuteDefaultRendererVertexBufferRuntimeCallDraft()`。
- 本轮是否改变 owner / truth / stop-line：是，新增 vertex buffer owner 与 native callable；stop-line 明确禁止 encoder、`setVertexBuffer`、draw、commit、present、GPU submission、render 与 state write。
- 本轮是否改变唯一 next opening：是，建议 `P1 internal Renderer draw call no-submit planning preflight decision`。
- 是否同步 topic manifest：需要同步。
- 已同步哪些 topic manifest：将在 manifest stabilization 中同步三个 Renderer 主题 manifest。

## 下游接续

本 closure 已由 [绘制调用 no-submit阶段收束复核](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-15-p1-internal-renderer-draw-call-no-submit-stage-closure-review.md) 接续。下游仍只保留 no-submit facts，不创建 encoder、不绑定 vertex buffer、不 draw、不提交 GPU work。

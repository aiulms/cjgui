# 顶点缓冲 no-submit 清单

## 阶段路线

本阶段完成 A/B/C/D：

- A：planning / data contract facts。
- B：token-backed `MTLBuffer` create / destroy first slice。
- C：static triangle vertex data upload / classify facts。
- D：runtime internal FFI call owner。

## 固定接口

Production native callable list 固定为：

- `cjgui_native_bridge_vertex_buffer_table_capacity(void)` -> `uint32_t`
- `cjgui_native_bridge_vertex_buffer_table_enabled(void)` -> `uint32_t`
- `cjgui_native_bridge_vertex_buffer_table_occupied_count(void)` -> `uint32_t`
- `cjgui_native_bridge_vertex_buffer_create(uint64_t device_token, uint64_t* out_buffer_token)` -> `int32_t`
- `cjgui_native_bridge_vertex_buffer_destroy(uint64_t buffer_token)` -> `int32_t`
- `cjgui_native_bridge_vertex_buffer_token_classify(uint64_t buffer_token)` -> `int32_t`
- `cjgui_native_bridge_vertex_buffer_double_destroy_classify(uint64_t buffer_token)` -> `int32_t`
- `cjgui_native_bridge_vertex_buffer_upload_static_triangle(uint64_t buffer_token)` -> `int32_t`
- `cjgui_native_bridge_vertex_buffer_data_classify(uint64_t buffer_token)` -> `int32_t`
- `cjgui_native_bridge_vertex_buffer_create_requires_main_thread(void)` -> `int32_t`
- `cjgui_native_bridge_vertex_buffer_destroy_requires_main_thread(void)` -> `int32_t`
- `cjgui_native_bridge_vertex_buffer_upload_requires_main_thread(void)` -> `int32_t`
- `cjgui_native_bridge_vertex_buffer_layout_position_color(void)` -> `int32_t`
- `cjgui_native_bridge_vertex_buffer_encoder_binding_still_blocked(void)` -> `int32_t`
- `cjgui_native_bridge_vertex_buffer_draw_still_blocked(void)` -> `int32_t`

## runtime tail

- endpoint：`CjguiInternalRendererNoVertexBufferRuntimeCallReadiness`
- default draft：`cjguiInternalExecuteDefaultRendererVertexBufferRuntimeCallDraft()`
- runtime input：`CjguiInternalRendererNoPipelineStateRuntimeCallReadiness`
- owner chain：[runtime_renderer_vertex_buffer_no_submit_planning.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_vertex_buffer_no_submit_planning.cj)、[runtime_renderer_vertex_buffer_create_destroy.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_vertex_buffer_create_destroy.cj)、[runtime_renderer_vertex_buffer_data_upload.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_vertex_buffer_data_upload.cj)、[runtime_renderer_vertex_buffer_runtime_call.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_vertex_buffer_runtime_call.cj)

## token 与生命周期

`MTLBuffer` table 容量固定为 2。token 仍来自既有 slot + generation opaque token table，不保存或返回 pointer。table entry 只在 native bridge 内保存 `MTLBuffer` strong reference 与 device token dependency。create / destroy / upload 均要求 main thread。destroy 会 revoke token；double destroy、invalid token、stale token、capacity exhausted 与 device dependency ordering 均 fail-closed。

## stop-line

本 manifest 不授权 render command encoder creation，不授权 `setVertexBuffer`，不授权 draw，不授权 index buffer，不授权 `commit` / `present`，不授权 GPU submission，不授权 render，不授权 renderer state write，不授权 backend-ready truth，不授权 public API / diagnostics，不授权 pointer / handle / `id` / `Class` return。

## 证据链

- Preflight：[顶点缓冲 no-submit 预检裁定](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-15-p1-renderer-vertex-buffer-no-submit-preflight-decision.md)
- Closure：[顶点缓冲 no-submit 阶段收束复核](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-15-p1-internal-renderer-vertex-buffer-no-submit-stage-closure-review.md)
- Next-boundary：[顶点缓冲 no-submit 下一口裁定](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-15-p1-renderer-vertex-buffer-no-submit-next-boundary-decision.md)

## 唯一后续入口

`P1 internal Renderer draw call no-submit planning preflight decision`

该下一步只能规划 draw call shape / vertex input contract / encoder prerequisite blocker，不得创建 encoder，不得绑定 vertex buffer，不得 draw，不得提交 GPU work。

## 下游已接续

本 manifest 已由 [绘制调用 no-submit 清单](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-15-p1-renderer-draw-call-no-submit-manifest.md) 接续。下游只聚合 pipeline state runtime facts 与 vertex buffer runtime facts，并新增 still-blocked classification；它没有创建 encoder，没有绑定 pipeline 或 vertex buffer，没有调用 draw，没有提交 GPU work，也没有生成 backend-ready truth。

随后已由 [No-submit 渲染管线分支里程碑清单](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-15-p1-renderer-no-submit-render-pipeline-branch-milestone-manifest.md)、[production drawable texture lifetime first slice manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-15-p1-renderer-production-drawable-texture-lifetime-first-slice-manifest.md) 与 [drawable texture lifetime implementation recovery manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-15-p1-renderer-drawable-texture-lifetime-implementation-recovery-manifest.md) 接续。当前主线转回 `P1 internal Renderer visible-window production harness preflight decision`；vertex buffer facts 仍只作为 draw input 上游证据，不授权 `setVertexBuffer`、encoder、draw、submit 或 render。

## 设计意图出口自检

- 本轮是否改变主题状态：是，顶点缓冲 no-submit 从规划推进到 token-backed create / destroy、data upload 与 runtime internal FFI call owner 封账。
- 本轮是否改变 canonical tail / endpoint：是，tail 固定为 `CjguiInternalRendererNoVertexBufferRuntimeCallReadiness`。
- 本轮是否改变 owner / truth / stop-line：是，新增 owner chain 只产出 internal dehydrated facts；truth 仍不写 renderer state；stop-line 继续禁止 encoder / bind / draw / commit / present / GPU submission / render。
- 本轮是否改变唯一 next opening：是，唯一后续入口固定为 `P1 internal Renderer draw call no-submit planning preflight decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。

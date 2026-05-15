# Pipeline state create/destroy no-draw 清单

日期：2026-05-13

状态：manifest / sealed

## 路线

实际完成路线：B/C。

- B：token-backed `MTLRenderPipelineState` create/destroy first slice。
- C：runtime internal FFI call owner。

## Runtime owner

最新 canonical endpoint：

- `CjguiInternalRendererNoPipelineStateRuntimeCallReadiness`
- `cjguiInternalExecuteDefaultRendererPipelineStateRuntimeCallDraft()`

Runtime input：

- `CjguiInternalRendererNoShaderLibraryRuntimeCallReadiness`
- `cjguiInternalExecuteDefaultRendererShaderLibraryRuntimeCallDraft()`

Owner files：

- [runtime_renderer_pipeline_state_create_destroy_planning.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_pipeline_state_create_destroy_planning.cj)
- [runtime_renderer_pipeline_state_create_destroy.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_pipeline_state_create_destroy.cj)
- [runtime_renderer_pipeline_state_runtime_call.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_pipeline_state_runtime_call.cj)

## Native callable 清单

- `cjgui_native_bridge_pipeline_state_table_capacity`
- `cjgui_native_bridge_pipeline_state_table_enabled`
- `cjgui_native_bridge_pipeline_state_table_occupied_count`
- `cjgui_native_bridge_pipeline_state_create`
- `cjgui_native_bridge_pipeline_state_destroy`
- `cjgui_native_bridge_pipeline_state_token_classify`
- `cjgui_native_bridge_pipeline_state_double_destroy_classify`
- `cjgui_native_bridge_pipeline_state_create_requires_main_thread`
- `cjgui_native_bridge_pipeline_state_destroy_requires_main_thread`
- `cjgui_native_bridge_pipeline_state_encoder_binding_still_blocked`
- `cjgui_native_bridge_pipeline_state_draw_still_blocked`

## Token 与 table policy

Pipeline state table 固定容量为 `2` 的 production native table。token 是 opaque integer，由 native token table issue/revoke 机制生成，不是 pointer cast。table entry 可以持有 `id<MTLRenderPipelineState>`，但该对象只存在于 production native bridge 内部，不返回给仓颉，不保存 raw pointer，不暴露 handle。

Create 必须 main-thread，并且要求 token-backed `MTLDevice`、token-backed `MTLRenderPipelineDescriptor`、token-backed vertex function 与 token-backed fragment function 均有效。Destroy 必须 main-thread，成功后撤销 token；invalid / stale / destroyed / double destroy 都 fail-closed。

## Dependency policy

Pipeline state 存活期间，device、descriptor 与 shader function destroy 会被拒绝，要求先 destroy pipeline state。该约束防止上游 token 在 pipeline state 仍存活时被提前撤销。

## Runtime facts

Runtime owner 只在函数局部创建 device / descriptor / library / functions / pipeline state token，执行 classify / destroy / double destroy / cleanup，并把结果脱水为 internal facts。token 不跨函数持久化，不写 module-level mutable var，不返回 public surface，不写 renderer state。

## 停止线

本 manifest 不授权 render command encoder creation，不授权 encoder binding，不授权 `setRenderPipelineState`，不授权 draw，不授权 vertex buffer，不授权 `commit` / `present`，不授权 GPU submission，不授权 render，不授权 backend-ready truth，不授权 renderer state write，不授权 public API / diagnostics，不授权 pointer / handle / `id` / `Class` return。

## 验证锚点

- [verify_native_bridge_pipeline_state_create_destroy.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_native_bridge_pipeline_state_create_destroy.sh)
- [verify_native_bridge_pipeline_state_runtime_call.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_native_bridge_pipeline_state_runtime_call.sh)
- `cjpm build --target-dir /tmp/cjgui-renderer-pipeline-state-create-destroy-no-draw-target --skip-script`

## 后续入口

唯一 next opening：

`P1 internal Renderer pipeline state encoder binding blocker reconciliation decision`

## 下游已接续

本 manifest 已由 [pipeline state encoder 绑定阻塞归因清单](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-14-p1-renderer-pipeline-state-encoder-binding-blocker-reconciliation-manifest.md)、[vertex buffer no-submit 清单](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-15-p1-renderer-vertex-buffer-no-submit-manifest.md)、[绘制调用 no-submit 清单](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-15-p1-renderer-draw-call-no-submit-manifest.md)、[No-submit 渲染管线分支里程碑清单](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-15-p1-renderer-no-submit-render-pipeline-branch-milestone-manifest.md) 与 [drawable texture lifetime implementation recovery manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-15-p1-renderer-drawable-texture-lifetime-implementation-recovery-manifest.md) 接续。最新下游已完成 token-backed `MTLBuffer` lifecycle、static triangle data upload、draw input bundle、no-submit branch milestone 与 drawable lifetime recovery decision facts；当前主线转为 `P1 internal Renderer visible-window production harness preflight decision`。这些下游不改变 pipeline state runtime owner 的 no-draw truth，也不授权 production `nextDrawable`、color attachment、encoder creation、encoder binding、`setRenderPipelineState`、`setVertexBuffer`、draw、`commit` / `present`、GPU submission 或 render。

## 设计意图出口自检

- 本轮是否改变主题状态：是，pipeline state create/destroy no-draw first slice 已封账。
- 本轮是否改变 canonical tail / endpoint：是，最新 canonical tail 是 `CjguiInternalRendererNoPipelineStateRuntimeCallReadiness` / `cjguiInternalExecuteDefaultRendererPipelineStateRuntimeCallDraft()`。
- 本轮是否改变 owner / truth / stop-line：是，新增 pipeline state lifecycle 与 runtime call owner；truth 限于 no-draw lifecycle facts；stop-line 保持 no encoder / no draw / no submit / no render。
- 本轮是否改变唯一 next opening：是，转为 `P1 internal Renderer pipeline state encoder binding blocker reconciliation decision`。
- 是否同步 topic manifest：是，已在 manifest stabilization closure 中同步。
- 已同步哪些 topic manifest：`renderer-implementation-admission-chain`、`renderer-backend-readiness-real-backend-runway`、`macos-bridge-verification-smoke`。

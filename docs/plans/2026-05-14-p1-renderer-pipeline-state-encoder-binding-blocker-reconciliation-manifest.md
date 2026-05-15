# Pipeline state encoder 绑定阻塞归因清单

日期：2026-05-14

状态：docs-only / manifest / sealed

## 路线

实际完成路线：A/D。

- A：确认 blocker = 缺 render command encoder，并继续追溯到 production drawable texture lifetime 与 color attachment 缺口。
- D：下一主线转向 vertex buffer / draw input no-submit planning。

## 固定尾端

Runtime canonical tail 不变：

- `CjguiInternalRendererNoPipelineStateRuntimeCallReadiness`
- `cjguiInternalExecuteDefaultRendererPipelineStateRuntimeCallDraft()`

Owner 不变：

- [runtime_renderer_pipeline_state_runtime_call.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_pipeline_state_runtime_call.cj)

Runtime input 不变：

- `CjguiInternalRendererNoShaderLibraryRuntimeCallReadiness`
- `cjguiInternalExecuteDefaultRendererShaderLibraryRuntimeCallDraft()`

## 已固定事实

Pipeline state 已完成 token-backed no-draw lifecycle 与 runtime-local call evidence：

- token-backed `MTLRenderPipelineState` create / destroy / classify。
- dependency destroy fail-closed。
- double destroy fail-closed。
- occupied count cleanup。
- token opaque，不返回 pointer / handle / `id` / `Class`。
- runtime token 仅函数局部存在，不持久化，不写 renderer state。

## 阻塞事实

Pipeline state encoder binding 仍被阻断：

- 没有 `MTLRenderCommandEncoder`。
- encoder creation 被 production drawable texture lifetime 缺口阻断。
- encoder creation 被 `MTLRenderPassDescriptor.colorAttachments[0]` 未配置阻断。
- 没有不依赖 drawable texture / color attachment 的稳定 encoder creation route。
- pipeline binding 必须等待 encoder creation gate 重新打开。

## 下一主线

唯一 next opening：

`P1 internal Renderer vertex buffer no-submit planning preflight decision`

该下一步只能规划 vertex buffer / draw input contracts。它不得创建 encoder，不得绑定 pipeline，不得 draw，不得提交 GPU work，不得写 renderer state。

## 停止线

本 manifest 不授权 render command encoder creation，不授权 `renderCommandEncoderWithDescriptor`，不授权 `setRenderPipelineState`，不授权 pipeline binding，不授权 vertex buffer creation / binding，不授权 draw，不授权 `commit` / `present`，不授权 GPU submission，不授权 render，不授权 backend-ready truth，不授权 renderer state write，不授权 public API / diagnostics，不授权 pointer / handle / `id` / `Class` return。

## 上游与下游

上游固定：

- [pipeline state create/destroy no-draw manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-13-p1-renderer-pipeline-state-create-destroy-no-draw-manifest.md)
- [shader library no-draw manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-13-p1-renderer-shader-library-no-draw-manifest.md)
- [pipeline descriptor no-draw manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-13-p1-renderer-pipeline-descriptor-no-draw-manifest.md)
- [render command encoder 创建阻塞归因清单](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-render-command-encoder-creation-blocker-reconciliation-manifest.md)
- [render command encoder no-submit planning manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-render-command-encoder-no-submit-planning-manifest.md)
- [render pass descriptor color attachment recovery manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-render-pass-descriptor-color-attachment-recovery-manifest.md)
- [drawable texture lifetime implementation recovery manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-drawable-texture-lifetime-implementation-recovery-manifest.md)

下游唯一入口：

- `P1 internal Renderer vertex buffer no-submit planning preflight decision`

## 下游已接续

本 manifest 已由 [vertex buffer no-submit manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-15-p1-renderer-vertex-buffer-no-submit-manifest.md)、[draw call no-submit manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-15-p1-renderer-draw-call-no-submit-manifest.md)、[No-submit 渲染管线分支里程碑清单](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-15-p1-renderer-no-submit-render-pipeline-branch-milestone-manifest.md) 与 [drawable texture lifetime implementation recovery manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-15-p1-renderer-drawable-texture-lifetime-implementation-recovery-manifest.md) 接续。下游已完成 token-backed `MTLBuffer` create / destroy / classify、static triangle data upload、draw call still-blocked C ABI、draw input bundle facts、no-submit branch milestone 与 drawable lifetime recovery decision；当前最新 next opening 已转为 `P1 internal Renderer visible-window production harness preflight decision`。

该接续不改变本 manifest 对 encoder blocker 的归因：pipeline / vertex buffer 都仍必须等待合法 `MTLRenderCommandEncoder`；当前仍不授权 encoder creation、encoder binding、`setRenderPipelineState`、`setVertexBuffer`、draw、`commit` / `present`、GPU submission、render、renderer state write、public API、pointer / handle / `id` / `Class` return。

## 设计意图出口自检

- 本轮是否改变主题状态：是，pipeline state encoder binding blocker 已固定为 docs-only reconciliation。
- 本轮是否改变 canonical tail / endpoint：否，runtime canonical tail 不变。
- 本轮是否改变 owner / truth / stop-line：是，truth 增加 blocker / next-mainline facts；stop-line 保持 no encoder / no binding / no draw / no submit / no render。
- 本轮是否改变唯一 next opening：是，转为 `P1 internal Renderer vertex buffer no-submit planning preflight decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`renderer-implementation-admission-chain`、`renderer-backend-readiness-real-backend-runway`、`macos-bridge-verification-smoke`。

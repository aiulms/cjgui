# Shader library no-draw 预检结论

日期：2026-05-13

状态：preflight / approved for A/B/C/D/E first slice

## 上游读取

本轮读取并继承以下上游事实：

- [pipeline descriptor no-draw 清单](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-13-p1-renderer-pipeline-descriptor-no-draw-manifest.md)
- [pipeline descriptor no-draw 清单稳定化复核](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-13-p1-internal-renderer-pipeline-descriptor-no-draw-manifest-stabilization-closure-review.md)
- [pipeline state no-draw planning 清单](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-12-p1-renderer-pipeline-state-no-draw-planning-manifest.md)
- [render command encoder 创建阻塞归因清单](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-render-command-encoder-creation-blocker-reconciliation-manifest.md)
- [Metal device binding runway 清单](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-metal-device-binding-runway-manifest.md)

上游 runtime input 固定为 `CjguiInternalRendererNoPipelineDescriptorRuntimeCallReadiness`，上游 default draft 固定为 `cjguiInternalExecuteDefaultRendererPipelineDescriptorRuntimeCallDraft()`。

## 判断

可以打开 shader library no-draw runway。理由是 pipeline descriptor no-draw 已经证明 descriptor lifecycle / configuration facts 可脱水，Metal device token table 已经存在，`MTLLibrary` 可以由 token-backed `MTLDevice` 作为输入创建，并且 vertex / fragment `MTLFunction` lookup 可以只形成 opaque token 与 classification facts。

本阶段不需要创建 `MTLRenderPipelineState`，不需要 render command encoder，不需要 `setRenderPipelineState`，不需要 vertex buffer、draw、`commit`、`present` 或 GPU submission。因此可继续推进 A/B/C/D/E。

## 批准路线

选择 A/B/C/D/E：

- A：新增 shader library no-draw planning owner。
- B：固定 embedded minimal shader source contract，只作为 native no-draw compilation evidence。
- C：实现 token-backed `MTLLibrary` create/destroy first slice。
- D：实现 token-backed vertex / fragment `MTLFunction` lookup/classify first slice。
- E：新增 runtime internal FFI call owner，局部执行 device create、library create、function lookup、classify 与 cleanup。

## Native 写集许可

允许修改 production native `cjgui_native_bridge.h/.m`，但仅限以下 C ABI：

- shader source contract status。
- shader library table capacity / enabled / occupied_count / create / destroy / classify / double destroy / main-thread facts。
- shader function table capacity / enabled / occupied_count / vertex lookup / fragment lookup / destroy / classify / double destroy / main-thread facts。
- pipeline state / encoder / draw still-blocked classification。

所有 callable 只能返回 `int32_t` / `uint32_t` / opaque `uint64_t` out-token，不得返回 pointer、handle、`id` 或 `Class`。

## 失败分类

- device token invalid / stale / not-bound 必须 fail-closed。
- library token invalid / stale / not-bound 必须 fail-closed。
- function token invalid / stale / not-bound 必须 fail-closed。
- capacity exhausted 必须 fail-closed。
- double destroy 必须 fail-closed。
- shader compile 或 function lookup 失败必须返回分类，不得伪造 readiness。
- library destroy 在 function token 未清理前必须被拒绝。

## 停止线

不创建 `MTLRenderPipelineState`，不创建 render command encoder，不调用 `setRenderPipelineState`，不 draw，不创建 vertex buffer，不 `commit`，不 `present`，不提交 GPU work，不执行 render，不写 renderer state，不触碰 `runtime_state.cj`，不修改 `runtime/cjgui/cjpm.toml`，不修改 smoke native files，不新增 public API / diagnostics，不返回 pointer / handle / `id` / `Class`。

## GitNexus 记录

GitNexus impact 对上游 endpoint / default draft 与拟新增 shader symbols 返回 `UNKNOWN` / not found / impactedCount `0`。本轮不把图谱缺口解释为安全证明，继续以源码阅读、build、probe、symbol scan、forbidden scan 与文档链兜底。

## 设计意图出口自检

- 本轮是否改变主题状态：是，允许 shader library no-draw 从 next opening 进入 first slice runway。
- 本轮是否改变 canonical tail / endpoint：预检阶段尚未封尾，目标尾点候选为 `CjguiInternalRendererNoShaderLibraryRuntimeCallReadiness`。
- 本轮是否改变 owner / truth / stop-line：是，预检批准新增 internal owners 与 native no-draw C ABI，但 stop-line 继续禁止 pipeline state、encoder、draw、commit、present、GPU submission、render、renderer state 与 public API。
- 本轮是否改变唯一 next opening：预检阶段暂定完成后进入 manifest stabilization；若 A/B/C/D/E 完成，后续入口为 `P1 internal Renderer pipeline state create/destroy no-draw preflight decision`。
- 是否同步 topic manifest：将在 closure / manifest 阶段同步。
- 已同步哪些 topic manifest：预检阶段尚未同步。

# Render command encoder 创建阻塞归因判断

日期：2026-05-11

状态：docs-only / reconciliation decision / no runtime truth

## 本轮结论

本轮选择路线 C：暂不回到 production drawable lifetime first slice，也不尝试创建 `MTLRenderCommandEncoder`，主线转向 `P1 internal Renderer pipeline state no-draw planning preflight decision`。

原因是 render command encoder creation 的直接阻塞已经足够明确：production drawable texture lifetime 尚未成立，`MTLRenderPassDescriptor.colorAttachments[0]` 尚未配置，因此没有稳定、可清理、可归属的 render pass descriptor 可以交给 `renderCommandEncoderWithDescriptor`。在这个缺口补齐前，任何 encoder feasibility 都会把 isolated drawable / visible-window evidence 错读成 production runtime truth。

本轮不新增 runtime owner，不新增 native C ABI，不创建 encoder，不配置 color attachment，不调用 draw / `commit` / `present`，不提交 GPU work，不写 renderer state。

## 已读取证据

- [render command encoder no-submit planning manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-render-command-encoder-no-submit-planning-manifest.md)
- [render command encoder no-submit planning closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-internal-renderer-render-command-encoder-no-submit-planning-stage-closure-review.md)
- [render pass descriptor color attachment recovery manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-render-pass-descriptor-color-attachment-recovery-manifest.md)
- [drawable texture lifetime implementation recovery manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-drawable-texture-lifetime-implementation-recovery-manifest.md)
- [production drawable texture lifetime manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-production-drawable-texture-lifetime-manifest.md)
- [render pass descriptor create / destroy runway manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-render-pass-descriptor-runway-manifest.md)
- [command buffer creation runway manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-command-buffer-creation-runway-manifest.md)
- [pipeline state lifecycle manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-pipeline-state-lifecycle-manifest.md)
- [pipeline state implementation admission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-pipeline-state-implementation-admission-manifest.md)
- [real pipeline state first implementation slice manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-renderer-real-pipeline-state-first-implementation-slice-manifest.md)
- [draw call implementation admission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-draw-call-implementation-admission-manifest.md)

## GitNexus 影响面

按工作区规则，对上游 endpoint / default draft 先运行 impact：

- `CjguiInternalRendererNoRenderCommandEncoderNoSubmitPlanningReadiness`
- `cjguiInternalExecuteDefaultRendererRenderCommandEncoderNoSubmitPlanningDraft`

当前 Tool CLI 在本地 repo 查询均返回 target not found / impactedCount 0 / risk UNKNOWN。该结果不视为安全证明；本轮按近期新增 owner 尚未被图谱索引记录，并用源码阅读、manifest 证据、docs-only 写集、diff / link / public-scan / protected-path scan 兜底。

## 阻塞归因

encoder creation 的最小缺口是双重缺口，而不是单一 command buffer 缺口：

- production drawable texture lifetime 缺口：现有 no-present drawable acquisition 是 isolated / visible-window probe evidence，尚不能证明 production drawable token、texture lifetime、release / cleanup 与 layer / device co-ownership。
- color attachment 缺口：`MTLRenderPassDescriptor.colorAttachments[0]` 尚未绑定 drawable texture，也未证明 load / store action、clear color 与 descriptor / drawable cleanup 的共同所有权。

因此，当前没有不依赖 drawable texture 的 encoder feasibility 路线。若直接创建 encoder，会隐式要求有效 color attachment；若绕开 attachment，则无法证明 `renderCommandEncoderWithDescriptor` 的输入合法性。该路线本轮明确拒绝。

## 路线判断

- A：仅做阻塞归因，成立，但不足以给下一步方向。
- B：回到 visible-window / drawable texture lifetime production harness，合理但会继续受环境、run loop、visible window 与 cleanup 证据约束。
- C：转向 pipeline state no-draw planning，选择。pipeline state no-draw 可以先固定 shader library、shader function、pipeline descriptor、pixel format compatibility 与 no-encoder-binding stop-line，不需要创建 encoder、不需要 drawable texture、不需要 color attachment。
- D：证据冲突 reconciliation scan，本轮不需要；当前证据一致指向 drawable lifetime + color attachment 缺口。

pipeline state no-draw planning 仍需自检：如果下一步要求真实 shader library / function creation、pipeline state creation、encoder binding、draw call、GPU submission 或 render，则必须停在 planning / blocker；它只能先固定 contract，不授予 pipeline implementation 权限。

## 停止线

- 不创建 `MTLRenderCommandEncoder`。
- 不调用 `renderCommandEncoderWithDescriptor`。
- 不配置 `colorAttachments[0]`。
- 不调用 draw / `drawPrimitives` / `drawIndexedPrimitives`。
- 不创建 pipeline state / vertex buffer。
- 不调用 `commit` / `present`。
- 不提交 GPU work，不执行 render。
- 不写 renderer state，不触碰 `runtime_state.cj`。
- 不新增 public API / diagnostics。
- 不返回 native pointer / handle / `id` / `Class`。

## 设计意图出口自检

- 本轮是否改变主题状态：是。Renderer implementation / backend runway 从 encoder no-submit planning 的 next opening 对账为 pipeline state no-draw planning。
- 本轮是否改变 canonical tail / endpoint：否。runtime canonical endpoint 仍是 `CjguiInternalRendererNoRenderCommandEncoderNoSubmitPlanningReadiness` / `cjguiInternalExecuteDefaultRendererRenderCommandEncoderNoSubmitPlanningDraft()`。
- 本轮是否改变 owner / truth / stop-line：是。没有新增 owner；truth 增加 docs-only blocker reconciliation facts；stop-line 明确禁止 encoder / color attachment / draw / commit / present。
- 本轮是否改变唯一 next opening：是，改为 `P1 internal Renderer pipeline state no-draw planning preflight decision`。
- 是否同步 topic manifest：需要同步。
- 已同步哪些 topic manifest：计划同步 `renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md` 与 `macos-bridge-verification-smoke.md`。

## 唯一后续入口

`P1 internal Renderer pipeline state no-draw planning preflight decision`

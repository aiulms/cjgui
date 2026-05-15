# Pipeline state encoder 绑定阻塞归因判断

日期：2026-05-14

状态：docs-only / reconciliation / no runtime truth

## 本轮结论

本轮选择 A + D：

- A：确认 pipeline state encoder binding 的直接 blocker 是 render command encoder 尚不存在。
- D：下一条主线转向 `P1 internal Renderer vertex buffer no-submit planning preflight decision`，先固定 vertex buffer / draw input contracts，不绑定 encoder。

这是一轮归因判断，不新增 runtime owner，不修改 native / `.cj` / script，不创建 encoder，不绑定 pipeline，不调用 `setRenderPipelineState`，不 draw，不 `commit` / `present`，不提交 GPU work，不执行 render。

## 已具备事实

上游 `CjguiInternalRendererNoPipelineStateRuntimeCallReadiness` / `cjguiInternalExecuteDefaultRendererPipelineStateRuntimeCallDraft()` 已经证明：

- production native bridge 可创建 token-backed `MTLRenderPipelineState`。
- pipeline state token 是 opaque integer，不是 pointer cast。
- pipeline state table 固定容量很小，并支持 classify / destroy / double destroy / occupied count cleanup。
- pipeline state 依赖 token-backed `MTLDevice`、`MTLRenderPipelineDescriptor`、vertex function 与 fragment function。
- dependency destroy 在 pipeline state 存活期间 fail-closed。
- runtime owner 只在函数局部创建和清理 token，并把结果脱水为 internal facts。
- 不返回 pointer / handle / `id` / `Class`，不扩 public API，不写 renderer state。

这些事实只说明 pipeline state lifecycle 可被 no-draw 调用链验证，不说明 pipeline 已可绑定到 encoder。

## 最小缺口

pipeline state encoder binding 的直接缺口是缺少 `MTLRenderCommandEncoder`。

encoder 又被两个更底层缺口阻断：

- production drawable texture lifetime 尚未成立。
- `MTLRenderPassDescriptor.colorAttachments[0]` 尚未配置。

目前没有不依赖 drawable texture 与 color attachment 的稳定 encoder creation route。缺少 encoder 时，pipeline state 不能被绑定；任何绑定都必须等到合法的 encoder creation gate 重新打开。

## 不采用的路线

本轮不选择回到 visible-window / drawable texture lifetime production harness 作为主线，因为该分支仍受 production window ownership、bounded run loop、drawable token release / cleanup 与 descriptor / drawable / layer / device co-ownership 约束。

本轮也不选择 render pass descriptor color attachment first slice，因为 color attachment 仍依赖 production drawable texture lifetime。

本轮拒绝直接创建 render command encoder、绑定 pipeline、调用 `setRenderPipelineState`、draw、commit、present 或 render。

## 选择 vertex buffer no-submit planning 的理由

vertex buffer / draw input no-submit planning 可以先作为 value boundary 推进，不需要 encoder creation，也不需要 drawable texture。下一阶段可以只固定：

- vertex payload shape。
- buffer ownership / token policy。
- pipeline input compatibility requirement。
- draw call input readiness policy。
- encoder binding required but still blocked。
- draw / commit / present / GPU submission still blocked。

若后续 vertex buffer / draw input planning 试图进入 encoder binding、真实 draw、GPU submit 或 renderer state write，必须立即停止。

## 后续入口

唯一 next opening：

`P1 internal Renderer vertex buffer no-submit planning preflight decision`

## 下游接续

本 decision 已由 [vertex buffer no-submit manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-15-p1-renderer-vertex-buffer-no-submit-manifest.md) 接续。下游已完成 token-backed `MTLBuffer` create / destroy / classify、static triangle data upload 与 runtime-local call facts；当前最新 next opening 已转为 `P1 internal Renderer draw call no-submit planning preflight decision`。该接续仍不授权 encoder creation、encoder binding、`setVertexBuffer`、draw、`commit` / `present`、GPU submission、render、renderer state write 或 public API。

## 禁止误读

本轮不是 runtime truth，不授权：

- 创建 `MTLRenderCommandEncoder`。
- 调用 `renderCommandEncoderWithDescriptor`。
- 调用 `setRenderPipelineState`。
- 绑定 pipeline 到 encoder。
- 创建或绑定 vertex buffer。
- 调用 draw / `commit` / `present`。
- 提交 GPU work 或执行 render。
- 写 renderer state 或触碰 `runtime_state.cj`。
- 新增 public API / diagnostics。
- 返回 pointer / handle / `id` / `Class`。

Pipeline state facts、shader library facts、pipeline descriptor facts、command buffer facts、isolated drawable facts 与 smoke evidence 都不得包装成 backend-ready truth。

## 设计意图出口自检

- 本轮是否改变主题状态：是，pipeline state encoder binding blocker 已完成 docs-only reconciliation。
- 本轮是否改变 canonical tail / endpoint：否，runtime canonical tail 仍是 `CjguiInternalRendererNoPipelineStateRuntimeCallReadiness` / `cjguiInternalExecuteDefaultRendererPipelineStateRuntimeCallDraft()`。
- 本轮是否改变 owner / truth / stop-line：是，新增 docs-only blocker truth；stop-line 继续禁止 encoder binding、draw、commit、present、GPU submission、render、state write 与 public API。
- 本轮是否改变唯一 next opening：是，转为 `P1 internal Renderer vertex buffer no-submit planning preflight decision`。
- 是否同步 topic manifest：是，本轮同步三个 Renderer 相关 topic manifest。
- 已同步哪些 topic manifest：`renderer-implementation-admission-chain`、`renderer-backend-readiness-real-backend-runway`、`macos-bridge-verification-smoke`。

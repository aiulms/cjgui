# Pipeline state create/destroy no-draw 后续边界选择

日期：2026-05-13

状态：已选择

## 当前结论

`MTLRenderPipelineState` create/destroy no-draw first slice 已完成 native lifecycle probe 与 runtime-adjacent FFI call probe。当前 pipeline state token 只代表 production native bridge 内部固定容量 table 的对象身份，不返回 pointer / handle / `id` / `Class`，不授权 encoder binding、draw、commit、present、GPU submission、render 或 backend-ready truth。

## 候选路线

- A：`P1 internal Renderer pipeline state encoder binding blocker reconciliation decision`
- B：`P1 internal Renderer render command encoder creation recovery decision`
- C：`P1 internal Renderer pipeline state runtime FFI call support recovery decision`
- D：拒绝直接进入 encoder binding / draw / commit / present / render implementation。

## 选择

选择 A：`P1 internal Renderer pipeline state encoder binding blocker reconciliation decision`。

原因：

- Pipeline state create/destroy 与 runtime-local call 已成立。
- Render command encoder 仍被 drawable texture lifetime 与 color attachment 缺口阻塞。
- 下一步应先归因 pipeline state 与 encoder binding 之间的最小缺口，而不是直接创建 encoder 或调用 `setRenderPipelineState`。

## 停止线

下一步仍不得创建 render command encoder，不得绑定 pipeline 到 encoder，不得调用 `setRenderPipelineState`，不得 draw，不得创建 vertex buffer，不得 `commit` / `present`，不得提交 GPU work，不得执行 render，不得写 renderer state，不得扩 public API，不得返回 pointer / handle / `id` / `Class`。

## 设计意图出口自检

- 本轮是否改变主题状态：是，pipeline state create/destroy no-draw first slice 已从实施转入后续边界选择。
- 本轮是否改变 canonical tail / endpoint：是，最新 endpoint 是 `CjguiInternalRendererNoPipelineStateRuntimeCallReadiness` / `cjguiInternalExecuteDefaultRendererPipelineStateRuntimeCallDraft()`。
- 本轮是否改变 owner / truth / stop-line：是，truth 变为 token-backed pipeline state no-draw lifecycle 与 runtime-local call facts；stop-line 仍禁止 encoder / draw / submit / render。
- 本轮是否改变唯一 next opening：是，唯一 next opening 固定为 `P1 internal Renderer pipeline state encoder binding blocker reconciliation decision`。
- 是否同步 topic manifest：是，已在后续 manifest stabilization 中同步。
- 已同步哪些 topic manifest：`renderer-implementation-admission-chain`、`renderer-backend-readiness-real-backend-runway`、`macos-bridge-verification-smoke`。

# 绘制调用 no-submit 预检裁定

本轮评估 `P1 internal Renderer draw call no-submit planning runway bundle`。上游固定为 `CjguiInternalRendererNoVertexBufferRuntimeCallReadiness` / `cjguiInternalExecuteDefaultRendererVertexBufferRuntimeCallDraft()`，并引用 [pipeline state encoder 绑定阻塞归因清单](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-14-p1-renderer-pipeline-state-encoder-binding-blocker-reconciliation-manifest.md) 与 [顶点缓冲 no-submit 清单](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-15-p1-renderer-vertex-buffer-no-submit-manifest.md)。

## 证据输入

- pipeline state runtime call 已成立，`MTLRenderPipelineState` 可以 token-backed create / classify / destroy，但尚未拥有 render command encoder。
- vertex buffer runtime call 已成立，`MTLBuffer` 可以 token-backed create / upload / classify / destroy，但尚未允许 `setVertexBuffer`。
- encoder creation blocker 仍是 production drawable texture lifetime 与 `colorAttachments[0]` 缺口。
- draw call 本轮只能表达输入合同、阻塞分类与 no-submit facts，不能跨过 encoder / binding gate。
- GitNexus impact 对上游 endpoint / default draft 返回 UNKNOWN / not found；按近期新增 owner 未索引记录，改用源码阅读、target build、native probe 与 forbidden scan 兜底。
- GitNexus impact 对新增 `cjgui_native_bridge_draw_call_*` callable 返回 UNKNOWN / not found；按新增 C ABI 未入图记录，使用 header / source / probe / build 兜底。

## 裁定

选择 A/B/C 连续推进：

- A：新增 draw call no-submit planning owner，固定 pipeline state available、vertex buffer available、encoder missing、binding blocked、draw blocked 与 GPU submit blocked facts。
- B：新增 production still-blocked native callable，只返回 `int32_t` 负向分类：encoder required、pipeline binding required、vertex binding required 与 draw still blocked。
- C：新增 draw input bundle planning owner，只聚合 pipeline state runtime facts 与 vertex buffer runtime facts，并继续固定 encoder missing / binding blocked / draw blocked。

## 继续禁止

本轮不创建 render command encoder，不调用 `setVertexBuffer`，不调用 `setRenderPipelineState`，不调用 `drawPrimitives` / `drawIndexedPrimitives`，不创建 index buffer，不调用 `commit` / `present`，不提交 GPU work，不执行 render，不写 renderer state，不触碰 `runtime_state.cj`，不修改 `runtime/cjgui/cjpm.toml`，不修改 smoke native files，不新增 public API / diagnostics，不返回 native pointer / handle / `id` / `Class`。

## 设计意图出口自检

- 本轮是否改变主题状态：是，从 vertex buffer no-submit runtime call 进入 draw call no-submit planning / still-blocked / draw input bundle。
- 本轮是否改变 canonical tail / endpoint：是，目标 endpoint 转为 `CjguiInternalRendererNoDrawInputBundleReadiness` / `cjguiInternalExecuteDefaultRendererDrawInputBundleDraft()`。
- 本轮是否改变 owner / truth / stop-line：是，新增 draw call planning、still-blocked call 与 draw input bundle owner；truth 只限 no-submit draw input facts。
- 本轮是否改变唯一 next opening：是，若全量验证通过，转为 `P1 internal Renderer no-submit render pipeline branch reconciliation decision`。
- 是否同步 topic manifest：需要同步。
- 已同步哪些 topic manifest：本文件创建时列为待同步，manifest stabilization 时同步 `renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md` 与 `macos-bridge-verification-smoke.md`。

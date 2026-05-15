# 顶点缓冲 no-submit 预检裁定

本轮评估 `P1 internal Renderer vertex buffer no-submit runway macro bundle`。上游固定为 `CjguiInternalRendererNoPipelineStateRuntimeCallReadiness` / `cjguiInternalExecuteDefaultRendererPipelineStateRuntimeCallDraft()`，并引用 [pipeline state encoder 绑定阻塞归因清单](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-14-p1-renderer-pipeline-state-encoder-binding-blocker-reconciliation-manifest.md)。

## 证据输入

- pipeline state no-draw runtime call 已成立，`MTLRenderPipelineState` 可以 token-backed create / classify / destroy，但尚无 render command encoder。
- encoder creation blocker 仍是 production drawable texture lifetime 与 `colorAttachments[0]` 缺口。
- vertex buffer / draw input contract 可以不依赖 encoder 或 drawable texture，先作为 no-submit resource runway 独立推进。
- GitNexus impact 对上游 endpoint / default draft 返回 UNKNOWN / not found；按近期新增 owner 未索引记录，改用源码阅读、build、probe 与 forbidden scan 兜底。
- GitNexus impact 对 `Function:native/cjgui_native_bridge.h:cjgui_native_bridge_surface_capabilities` 与 `Function:native/cjgui_native_bridge.h:cjgui_native_bridge_metal_device_destroy` 返回 LOW、affected_count 0。

## 裁定

选择 A/B/C/D 连续推进：

- A：新增 vertex buffer no-submit planning owner，固定 vertex layout、buffer ownership、encoder binding blocked、draw blocked 与 GPU submit blocked facts。
- B：新增 production token-backed `MTLBuffer` create / destroy first slice，固定容量为 2，token 仍为 opaque integer，不返回 pointer / `id` / handle。
- C：新增极小固定三角形 vertex data upload facts，layout 固定为 position/color；upload 内部仅瞬时写入，不保存 raw pointer，不暴露 bytes 到 public API。
- D：新增 runtime internal FFI call owner，局部执行 create -> upload -> classify -> destroy，并只生成 dehydrated facts。

## 继续禁止

本轮不创建 render command encoder，不调用 `setVertexBuffer`，不调用 `drawPrimitives` / `drawIndexedPrimitives`，不创建 index buffer，不调用 `commit` / `present`，不提交 GPU work，不执行 render，不写 renderer state，不触碰 `runtime_state.cj`，不修改 `runtime/cjgui/cjpm.toml`，不修改 smoke native files，不新增 public API / diagnostics，不返回 native pointer / handle / `id` / `Class`。

## 设计意图出口自检

- 本轮是否改变主题状态：是，从 pipeline state encoder binding blocker 进入 vertex buffer no-submit first slice。
- 本轮是否改变 canonical tail / endpoint：是，目标 endpoint 转为 `CjguiInternalRendererNoVertexBufferRuntimeCallReadiness` / `cjguiInternalExecuteDefaultRendererVertexBufferRuntimeCallDraft()`。
- 本轮是否改变 owner / truth / stop-line：是，新增 vertex buffer planning、create/destroy、data upload 与 runtime call owner；truth 只限 no-submit vertex buffer facts。
- 本轮是否改变唯一 next opening：是，若全量验证通过，转为 `P1 internal Renderer draw call no-submit planning preflight decision`。
- 是否同步 topic manifest：需要同步。
- 已同步哪些 topic manifest：本文件创建时列为待同步，manifest stabilization 时同步 `renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md` 与 `macos-bridge-verification-smoke.md`。

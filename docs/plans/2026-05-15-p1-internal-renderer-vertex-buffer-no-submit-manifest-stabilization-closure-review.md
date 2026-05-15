# 顶点缓冲 no-submit 清单稳定化复核

本复核确认 vertex buffer no-submit manifest 已封账：production native bridge、runtime internal owners、probe 与索引同步指向同一个 tail。

## 固定结果

- canonical tail：`CjguiInternalRendererNoVertexBufferRuntimeCallReadiness` / `cjguiInternalExecuteDefaultRendererVertexBufferRuntimeCallDraft()`。
- upstream：`CjguiInternalRendererNoPipelineStateRuntimeCallReadiness`。
- native surface：仅 `MTLBuffer` create / classify / upload / destroy / blocked classification C ABI。
- runtime truth：create / upload / classify / destroy cleanup 的 dehydrated facts。
- downstream：`P1 internal Renderer draw call no-submit planning preflight decision`。

## 验证说明

新增 probes 已覆盖 create/destroy、data upload 与 runtime-adjacent FFI call path。最终回归由本轮执行日志固定；如后续回归失败，必须停止到 recovery，不得保留 implementation truth。

## Same-shape 刹车

vertex buffer facts 不得包装成 encoder binding permission、`setVertexBuffer` permission、draw permission、render permission、GPU submission permission、backend-ready truth、renderer state write permission、public API permission、receipt / record / publication。

## 设计意图出口自检

- 本轮是否改变主题状态：是，vertex buffer no-submit first slice 已封账。
- 本轮是否改变 canonical tail / endpoint：是，tail 转为 `CjguiInternalRendererNoVertexBufferRuntimeCallReadiness`。
- 本轮是否改变 owner / truth / stop-line：是，新增 owner / native callable / probe；truth 仅限 no-submit vertex buffer facts。
- 本轮是否改变唯一 next opening：是，转为 `P1 internal Renderer draw call no-submit planning preflight decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。

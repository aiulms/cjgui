# P1 内部渲染器 native token table implementation 后续边界选择

日期：2026-05-10

状态：next-boundary / choose manifest stabilization

## 当前 endpoint 复核

`CjguiInternalRendererNoNativeTokenTableImplementationReadiness` / `cjguiInternalExecuteDefaultRendererNativeTokenTableImplementationDraft()` 足够作为当前 no-native-token-table-implementation endpoint。

该 endpoint 只表示 token table implementation shell 的 value boundary 已固定；它不表示 actual table exists，不表示 token 可以 issue / revoke，也不表示 future resource token 已可用。

## 候选比较

- A 选择：`P1 internal Renderer native token table implementation manifest stabilization bundle`。当前 owner、runtime input、truth、stop-line 已清楚，应该先封账。
- B 暂缓：`P1 internal Renderer native token table no-resource shell first implementation preflight decision`。这是封账后的唯一合理入口，但需要单独评估 native write set 与 table mutability。
- C 暂缓：`P1 internal Renderer platform object native callable preflight decision`。仍不得绕过 token table shell 与 teardown implementation。
- D 暂缓：`P1 internal Renderer native bridge teardown callable implementation preflight decision`。需要独立 preflight，不在本轮推进。
- E 拒绝：resource object table / public API / Metal / AppKit。

## 选择

本轮选择 A：

`P1 internal Renderer native token table implementation manifest stabilization bundle`

封账完成后的唯一后续入口建议为：

`P1 internal Renderer native token table no-resource shell first implementation preflight decision`

## 设计意图出口自检

- 本轮是否改变主题状态：是，native token table implementation value boundary 进入 manifest stabilization。
- 本轮是否改变 canonical tail / endpoint：是，tail 转为 `CjguiInternalRendererNoNativeTokenTableImplementationReadiness`。
- 本轮是否改变 owner / truth / stop-line：是，owner 为 `runtime_renderer_native_token_table_implementation.cj`；truth 限于 token table shell implementation facts；stop-line 继续禁止 actual table 与 native object。
- 本轮是否改变唯一 next opening：是，转为 `P1 internal Renderer native token table no-resource shell first implementation preflight decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`docs/plans/topic-manifests/renderer-implementation-admission-chain.md`、`docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md`、`docs/plans/topic-manifests/macos-bridge-verification-smoke.md`。

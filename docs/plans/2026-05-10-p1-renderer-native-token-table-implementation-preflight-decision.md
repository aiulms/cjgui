# P1 内部渲染器 native token table implementation 预检结论

日期：2026-05-10

状态：docs-only preflight / choose value boundary

## 预检问题

本轮从 [native bridge resource creation admission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-native-bridge-resource-creation-admission-manifest.md) 出发，评估是否可以打开 native token table implementation runway。

当前上游事实已经具备：

- no-resource callable `C ABI` 与 internal no-resource FFI call facts。
- main-thread no-resource callable 与 current-thread classification facts。
- native token callable planning facts。
- native token table ownership hardening facts。
- native bridge teardown callable planning facts。
- native resource creation admission prerequisites。

这些事实足够进入 token table implementation shell 的 value boundary，但不足以直接实现 native mutable table。

## 路线判断

本轮选择 A：

`P1 internal Renderer native token table implementation shell value boundary bundle`

理由：

- token table 是第一次靠近 native-side mutable state，直接修改 production native `.h` / `.m` 会提前打开 table mutability、capacity、slot reuse 与 failure classification 风险。
- 当前仍没有 resource object binding、destroy implementation、resource callable 或 package config integration，可以先固定 implementation admission facts。
- global / static mutable native table 不能在没有 table shell policy、generation / slot / epoch policy、capacity failure policy 和 no-second-truth proof 前进入实现。
- token ID 即使采用 monotonic counter、generation 或 slot index，也必须先证明它不是 pointer-like leakage。
- issue / revoke no-resource token 仍会产生 state mutation；本轮不批准。

## table shell 判断

后续若进入 native shell first implementation，第一切片必须仍是 table shell，而不是 resource table：

- table 只能是 production native bridge 私有 owner。
- entry 不得保存 raw pointer、native handle、Objective-C object identity 或 Metal object identity。
- token 必须是 bridge-local opaque identifier。
- generation / slot / epoch 必须防止 stale token、dangling token 与 reuse 混淆。
- capacity limit 与 allocation failure 必须 fail-closed。
- main-thread gate 与 single-thread / lock / atomic 策略必须在实现前被明确。

## 当前停止线

- no production native `.h` / `.m` modification。
- no native token C ABI。
- no token table implementation。
- no global mutable native table。
- no resource object table。
- no native object binding。
- no token-as-pointer pattern。
- no native handle / raw pointer。
- no native pointer return。
- no retain / release / destroy。
- no public API / diagnostics。
- no renderer state write。
- no `runtime_state.cj` modification。
- no backend-ready truth。

## 拒绝项

- B 暂缓：`P1 internal Renderer native token table no-resource shell first implementation bundle`。该路线需要单独证明 table shell mutability、capacity、slot / generation 与 main-thread policy。
- C 暂缓：`P1 internal Renderer native token table implementation blocker follow-up`。当前证据不足以实现 table，但足够先固定 value boundary。
- D 拒绝：resource object table / pointer handle / public API / Metal / AppKit。

## GitNexus impact

编辑 runtime owner 前，对上游入口运行 impact：

- `CjguiInternalRendererNoNativeResourceCreationAdmissionReadiness`：GitNexus 返回 UNKNOWN / not found，`impactedCount=0`。
- `cjguiInternalExecuteDefaultRendererNativeResourceCreationAdmissionDraft`：GitNexus 返回 UNKNOWN / not found，`impactedCount=0`。

按近期新增 owner 尚未被索引记录，继续用源码、build、probe 与 forbidden scan 兜底；未出现 HIGH / CRITICAL 风险。

## 设计意图出口自检

- 本轮是否改变主题状态：是，native token table implementation runway 进入 value boundary。
- 本轮是否改变 canonical tail / endpoint：预期改变为 `CjguiInternalRendererNoNativeTokenTableImplementationReadiness`。
- 本轮是否改变 owner / truth / stop-line：预期新增 `runtime_renderer_native_token_table_implementation.cj`，truth 限于 token table implementation shell policy facts，stop-line 继续禁止 actual table。
- 本轮是否改变唯一 next opening：预期转为 `P1 internal Renderer native token table no-resource shell first implementation preflight decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：执行后同步 `renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。

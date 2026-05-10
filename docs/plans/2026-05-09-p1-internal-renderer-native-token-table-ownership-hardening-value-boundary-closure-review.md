# P1 内部渲染器 native token table ownership hardening value boundary 复核

日期：2026-05-09

状态：closure review / value boundary completed

## 本轮结果

本轮新增 internal-only owner：

`runtime/cjgui/src/runtime_renderer_native_token_table_ownership.cj`

该 owner 只消费：

`CjguiInternalRendererNoNativeBridgeTokenCallableReadiness`

新增 endpoint：

`CjguiInternalRendererNoNativeTokenTableOwnershipReadiness`

新增 default draft：

`cjguiInternalExecuteDefaultRendererNativeTokenTableOwnershipDraft()`

## 固定事实

- 新 owner 只固定 native token table ownership intent、bridge-local opaque token table policy、table mutability confinement policy、generation / epoch invalidation policy、revoke-before-destroy ordering policy 与 double-revoke / dangling-token failure classification。
- 当前没有 token table implementation。
- 当前没有 native token C ABI。
- 当前没有 production native `.h` / `.m` 修改。
- 当前没有 scripts 修改。
- 当前没有 `runtime/cjgui/cjpm.toml` 修改。
- 当前没有 public API / diagnostics。
- 当前没有 native object、native handle、raw pointer 或 native pointer return。
- 当前没有 retain / release / destroy。
- 当前没有 renderer state write 或 backend-ready truth。

## GitNexus 记录

编辑前对上游入口运行 impact：

- `CjguiInternalRendererNoNativeBridgeTokenCallableReadiness`：GitNexus 返回 `UNKNOWN / not found`，affected count 为 `0`，按近期新增 owner 未索引处理。
- `cjguiInternalExecuteDefaultRendererNativeBridgeTokenCallableDraft`：GitNexus 返回 `UNKNOWN / not found`，affected count 为 `0`，按近期新增 owner 未索引处理。

未出现 HIGH / CRITICAL 风险信号。本轮继续使用源码、build、probe 与 scan 兜底。

## 同形边界刹车

不得把 `CjguiInternalRendererNoNativeTokenTableOwnershipReadiness` 包装成 token table implementation permission、native token C ABI permission、native handle permission、native object permission、destroy permission、Metal / AppKit permission、backend-ready permission、public API permission、receipt、record 或 publication。

## 设计意图出口自检

- 本轮是否改变主题状态：是，token table ownership hardening value boundary 已落地。
- 本轮是否改变 canonical tail / endpoint：是，新增 `CjguiInternalRendererNoNativeTokenTableOwnershipReadiness` / `cjguiInternalExecuteDefaultRendererNativeTokenTableOwnershipDraft()`。
- 本轮是否改变 owner / truth / stop-line：是，owner 为 `runtime_renderer_native_token_table_ownership.cj`；truth 为 token table ownership / mutability confinement / generation invalidation / revoke ordering / failure classification facts；stop-line 继续禁止 actual table、native token C ABI、public API、native object、pointer handle、Metal / AppKit、renderer state write 与 backend-ready truth。
- 本轮是否改变唯一 next opening：是，转入 `P1 internal Renderer native token table ownership hardening next-boundary decision`。
- 是否同步 topic manifest：是，manifest 阶段统一同步。
- 已同步哪些 topic manifest：待 manifest stabilization 同步 `docs/plans/topic-manifests/renderer-implementation-admission-chain.md`、`docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md`、`docs/plans/topic-manifests/macos-bridge-verification-smoke.md`。

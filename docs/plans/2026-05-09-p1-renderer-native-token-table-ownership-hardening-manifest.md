# P1 内部渲染器 native token table ownership hardening 清单

日期：2026-05-09

状态：manifest stabilization / value boundary

## 固定对象

- Owner：`runtime/cjgui/src/runtime_renderer_native_token_table_ownership.cj`
- Endpoint：`CjguiInternalRendererNoNativeTokenTableOwnershipReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererNativeTokenTableOwnershipDraft()`
- Runtime input：`CjguiInternalRendererNoNativeBridgeTokenCallableReadiness`
- Actual route：value boundary
- Native token table：无实现
- Native token C ABI：无新增

## table ownership policy

future token table 若进入 implementation runway，只能作为 production native bridge 私有 owner 的 bridge-local table。它不得成为 renderer truth source，不得成为 Objective-C truth source，不得被 public API 暴露，也不得绕过 runtime internal facts。

当前 owner 只固定 ownership intent，不创建 table。

## mutability confinement

future table mutability 若被批准，必须同时满足：

- bridge-private ownership。
- main-thread confinement。
- generation / epoch invalidation。
- fail-closed validation。
- no public token surface。
- no renderer state write。
- no backend-ready truth。

当前仍禁止 actual table、global mutable native table 与 module-level mutable runtime state。

## generation / epoch / invalidation

token 必须只作为 bridge-local opaque identifier。后续 table 必须记录 generation / epoch facts，避免 stale token、dangling token 与 token reuse 混淆。

任何 generation mismatch、stale token、dangling token 或 invalidation 缺失都必须 fail-closed。

## revoke / destroy ordering

future teardown 顺序必须保持：

- revoke token。
- destroy native object。
- invalidate table entry。
- classify failure。

当前 owner 不调用 destroy，不实现 destroy callback，不调用 retain / release，不修改 native lifecycle。

## runtime facts

Default draft 产出：

- `didConfirmBridgeLocalOpaqueTokenTablePolicy`
- `didConfirmTableMutabilityConfinementPolicy`
- `didConfirmNoSecondRendererTruthSource`
- `didConfirmGenerationEpochInvalidationPolicy`
- `didConfirmRevokeBeforeDestroyOrderingPolicy`
- `didConfirmDoubleRevokeDanglingTokenFailureClassification`
- `didConfirmMainThreadConfinementPolicy`
- `didConfirmNoActualTokenTable`
- `didConfirmNoNativeTokenCAbi`
- `didConfirmNoPublicSurface`
- `didConfirmNoResourceCallable`
- `didConfirmNoNativeObjectHandleOrPointer`
- `didConfirmNoRendererStateWrite`
- `didConfirmNoBackendReadyTruth`

这些 facts 只说明 token table ownership safety model 已被 internal owner 固定，不说明 token table exists。

## package / native 状态

- `runtime/cjgui/cjpm.toml` 未修改。
- `runtime/cjgui/native/cjgui_native_bridge.h` 未修改。
- `runtime/cjgui/native/cjgui_native_bridge.m` 未修改。
- probe scripts 未修改。
- smoke native files 未修改。
- production `.m` 仍未正式接入主包 package config。

## 停止线

- no native token C ABI。
- no token table implementation。
- no global mutable native table。
- no module-level mutable runtime state。
- no native object / handle / raw pointer。
- no native pointer return。
- no token-as-pointer。
- no public API / diagnostics。
- no resource callable。
- no production native `.h` / `.m` modification。
- no smoke native edits。
- no Cocoa / Metal / QuartzCore import。
- no AppKit / Metal object creation。
- no retain / release / destroy。
- no drawable / command buffer / `commit` / `present`。
- no GPU submission。
- no render execution。
- no renderer state write。
- no `runtime_state.cj` modification。
- no backend-ready truth。

## 证据链

- [native token callable manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-native-token-callable-manifest.md)
- [native token callable manifest closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-internal-renderer-native-bridge-native-token-callable-manifest-stabilization-closure-review.md)
- [native handle token ownership manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-handle-token-ownership-manifest.md)
- [native bridge teardown implementation planning manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-teardown-implementation-planning-manifest.md)
- [main-thread no-resource callable manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-main-thread-no-resource-callable-manifest.md)
- [no-resource runtime FFI call owner manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-no-resource-runtime-ffi-call-owner-manifest.md)
- [token table ownership hardening preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-token-table-ownership-hardening-preflight-decision.md)
- [token table ownership hardening value boundary closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-internal-renderer-native-token-table-ownership-hardening-value-boundary-closure-review.md)
- [token table ownership hardening next-boundary](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-token-table-ownership-hardening-next-boundary-decision.md)

## 后续入口

唯一后续入口：

`P1 internal Renderer native bridge teardown callable preflight decision`

该入口只能评估 no-resource / guarded teardown callable 前置条件、destroy / revoke ordering、double-destroy / dangling-token failure classification 与 main-thread confinement；不得直接创建 native object、native handle、raw pointer、Metal / AppKit resource、public API 或 backend-ready truth。

## 下游 teardown callable 封账

下游 [native bridge teardown callable manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-native-bridge-teardown-callable-manifest.md) 与 [manifest closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-internal-renderer-native-bridge-teardown-callable-manifest-stabilization-closure-review.md) 已完成。该 downstream 只把 `CjguiInternalRendererNoNativeTokenTableOwnershipReadiness` 作为 runtime input，并输出 `CjguiInternalRendererNoNativeBridgeTeardownCallableReadiness` / `cjguiInternalExecuteDefaultRendererNativeBridgeTeardownCallableDraft()`。

后续 [native bridge resource creation admission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-native-bridge-resource-creation-admission-manifest.md) 也已封账，但它仍不实现 token table，不创建 native object，不授权 resource callable。当前全局唯一后续入口已经转为 `P1 internal Renderer native token table implementation preflight decision`。

该 downstream 不把本 manifest 的 token table ownership facts 升格为 native teardown C ABI permission、token table implementation permission、destroy permission、retain / release permission、native object permission、native handle permission、raw pointer permission、Metal / AppKit permission、backend-ready permission、renderer state write、public diagnostics 或 public API permission。

新的 downstream 后续入口：

`P1 internal Renderer native bridge resource creation admission preflight decision`

## 设计意图出口自检

- 本轮是否改变主题状态：是，native token table ownership hardening 已 manifest stabilization。
- 本轮是否改变 canonical tail / endpoint：是，固定 `CjguiInternalRendererNoNativeTokenTableOwnershipReadiness` / `cjguiInternalExecuteDefaultRendererNativeTokenTableOwnershipDraft()`。
- 本轮是否改变 owner / truth / stop-line：是，owner 固定为 `runtime_renderer_native_token_table_ownership.cj`；truth 固定为 bridge-local opaque token table policy、mutability confinement、generation / epoch invalidation、revoke-before-destroy 与 failure classification facts；stop-line 继续禁止 actual table、native token C ABI、public API、native object、pointer handle、Metal / AppKit、renderer state write 与 backend-ready truth。
- 本轮是否改变唯一 next opening：是，转为 `P1 internal Renderer native bridge teardown callable preflight decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`docs/plans/topic-manifests/renderer-implementation-admission-chain.md`、`docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md`、`docs/plans/topic-manifests/macos-bridge-verification-smoke.md`。

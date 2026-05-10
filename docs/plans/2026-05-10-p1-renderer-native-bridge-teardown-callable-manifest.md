# P1 内部渲染器 native bridge teardown callable 清单

日期：2026-05-10

状态：manifest stabilization / planning value boundary

## 固定对象

- Owner：`runtime/cjgui/src/runtime_renderer_native_bridge_teardown_callable.cj`
- Endpoint：`CjguiInternalRendererNoNativeBridgeTeardownCallableReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererNativeBridgeTeardownCallableDraft()`
- Runtime input：`CjguiInternalRendererNoNativeTokenTableOwnershipReadiness`
- Actual route：planning value boundary
- Native teardown callable list：无新增

## no-destroy policy

当前 owner 只固定 no-destroy callable policy。它要求 future teardown callable 只能先表达 admission / classification，不得执行真实 destroy，不得调用 retain / release / destroy，不得实现 destroy callback。

当前没有修改 production native `.h/.m`，没有新增 `cjgui_native_bridge_teardown_admission`、`cjgui_native_bridge_destroy_not_supported` 或 `cjgui_native_bridge_revoke_before_destroy_required`。

## revoke-before-destroy policy

future teardown callable 必须保留 revoke-before-destroy ordering：

- revoke token。
- classify admission。
- 才能进入 future native lifecycle attempt。

当前没有 token table implementation，因此不执行 revoke，不执行 table mutation，不创建 second truth source。

## failure classification

当前 owner 只固定 classification policy：

- double-destroy fail-closed。
- dangling-token fail-closed。
- double-revoke fail-closed。
- missing token table fail-closed。

这些 classification 不发布 public diagnostics，不写 renderer state，不驱动 native lifecycle。

## main-thread destroy gate

main-thread destroy callable gate 只把现有 main-thread query 与 token table ownership facts 作为 evidence。它不调度主线程，不调用 AppKit / Metal / Objective-C，不创建 native object，也不批准 destroy。

## runtime facts

Default draft 产出：

- `didConfirmNoDestroyCallablePolicy`
- `didConfirmRevokeBeforeDestroyCallablePolicy`
- `didConfirmDoubleDestroyDanglingTokenClassification`
- `didConfirmMainThreadDestroyCallableGatePolicy`
- `didConfirmNoTeardownCAbiImplementation`
- `didConfirmNoActualDestroyRetainRelease`
- `didConfirmNoTokenTableImplementation`
- `didConfirmNoPublicSurface`
- `didConfirmNoResourceCallable`
- `didConfirmNoNativeObjectHandleOrPointer`
- `didConfirmNoMetalOrAppKitUsage`
- `didConfirmNoRendererStateWrite`
- `didConfirmNoBackendReadyTruth`

这些 facts 只说明 teardown callable safety boundary 已固定，不说明 teardown callable、destroy、native object 或 backend ready exists。

## package / native 状态

- `runtime/cjgui/cjpm.toml` 未修改。
- `runtime/cjgui/native/cjgui_native_bridge.h` 未修改。
- `runtime/cjgui/native/cjgui_native_bridge.m` 未修改。
- probe scripts 未修改。
- smoke native files 未修改。
- production `.m` 仍未正式接入主包 package config。

## 停止线

- no actual destroy。
- no retain / release / destroy call。
- no destroy callback implementation。
- no native teardown C ABI。
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
- no drawable / command buffer / `commit` / `present`。
- no GPU submission。
- no render execution。
- no renderer state write。
- no `runtime_state.cj` modification。
- no backend-ready truth。

## 证据链

- [teardown callable preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-native-bridge-teardown-callable-preflight-decision.md)
- [teardown callable closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-internal-renderer-native-bridge-teardown-callable-closure-review.md)
- [teardown callable next-boundary](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-native-bridge-teardown-callable-next-boundary-decision.md)
- [native token table ownership hardening manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-token-table-ownership-hardening-manifest.md)
- [native token table ownership hardening manifest closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-internal-renderer-native-token-table-ownership-hardening-manifest-stabilization-closure-review.md)
- [native bridge teardown implementation planning manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-teardown-implementation-planning-manifest.md)
- [native token callable manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-native-token-callable-manifest.md)
- [main-thread no-resource callable manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-main-thread-no-resource-callable-manifest.md)
- [no-resource runtime FFI call owner manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-no-resource-runtime-ffi-call-owner-manifest.md)

## 后续入口

唯一后续入口：

`P1 internal Renderer native bridge resource creation admission preflight decision`

该入口只能评估 resource creation admission 的前置条件、write set、token / teardown / main-thread gate 连接方式和 stop-line；不得直接创建 native object、native handle、raw pointer、AppKit / Metal resource、public API 或 backend-ready truth。

## 下游 resource creation admission 封账

下游 [native bridge resource creation admission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-native-bridge-resource-creation-admission-manifest.md) 与 [manifest closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-internal-renderer-native-bridge-resource-creation-admission-manifest-stabilization-closure-review.md) 已完成。该 downstream 只把 `CjguiInternalRendererNoNativeBridgeTeardownCallableReadiness` 作为 runtime input，并输出 `CjguiInternalRendererNoNativeResourceCreationAdmissionReadiness` / `cjguiInternalExecuteDefaultRendererNativeResourceCreationAdmissionDraft()`。

下游 [native bridge teardown callable implementation manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-native-bridge-teardown-callable-implementation-manifest.md) 与 [manifest closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-internal-renderer-native-bridge-teardown-callable-implementation-manifest-stabilization-closure-review.md) 也已完成，但它只新增 no-resource teardown admission classification callable，不改变本 planning owner 的 no-destroy stop-line，也不授权真实 destroy / retain / release。

当前全局唯一后续入口已经转为：

`P1 internal Renderer platform object AppKit import preflight decision`

该入口不是 resource creation permission、native object permission、actual destroy permission、public API permission、Metal / AppKit object permission 或 backend-ready truth。

## 设计意图出口自检

- 本轮是否改变主题状态：是，native bridge teardown callable 已 manifest stabilization。
- 本轮是否改变 canonical tail / endpoint：是，固定 `CjguiInternalRendererNoNativeBridgeTeardownCallableReadiness` / `cjguiInternalExecuteDefaultRendererNativeBridgeTeardownCallableDraft()`。
- 本轮是否改变 owner / truth / stop-line：是，owner 固定为 `runtime_renderer_native_bridge_teardown_callable.cj`；truth 固定为 no-destroy callable policy、revoke-before-destroy callable policy、double-destroy / dangling-token classification policy、main-thread destroy callable gate policy 与 no-native-bridge-teardown-callable readiness facts；stop-line 继续禁止 actual destroy、token table implementation、resource callable、native object、Metal / AppKit、public API、renderer state write 与 backend-ready truth。
- 本轮是否改变唯一 next opening：是，转为 `P1 internal Renderer native bridge resource creation admission preflight decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`docs/plans/topic-manifests/renderer-implementation-admission-chain.md`、`docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md`、`docs/plans/topic-manifests/macos-bridge-verification-smoke.md`。

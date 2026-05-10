# P1 内部渲染器 native bridge resource creation admission 清单

日期：2026-05-10

状态：manifest stabilization / value boundary

## 固定对象

- Owner：`runtime/cjgui/src/runtime_renderer_native_resource_creation_admission.cj`
- Endpoint：`CjguiInternalRendererNoNativeResourceCreationAdmissionReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererNativeResourceCreationAdmissionDraft()`
- Runtime input：`CjguiInternalRendererNoNativeBridgeTeardownCallableReadiness`
- Actual route：value boundary
- Native resource callable list：无新增

## resource creation prerequisites

future resource creation 必须先满足：

- main-thread gate prerequisite。
- token table prerequisite。
- teardown callable prerequisite。
- token-return-only future policy。
- no-resource fail-closed path。

当前 owner 只固定这些 prerequisites，不创建 native object，也不批准 future resource callable。

## main-thread gate

main-thread gate 来自 [main-thread no-resource callable manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-main-thread-no-resource-callable-manifest.md)。它只提供 current-thread classification facts，不调度主线程，不调用 AppKit / Metal，不创建 platform object。

## token table prerequisite

token table prerequisite 来自 [native token table ownership hardening manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-token-table-ownership-hardening-manifest.md)。当前仍没有 token table implementation；future resource creation 不得绕过 token table implementation preflight。

## teardown callable prerequisite

teardown callable prerequisite 来自 [native bridge teardown callable manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-native-bridge-teardown-callable-manifest.md)。当前仍没有 destroy implementation、retain / release call、token table revoke 或 destroy callback。

## token-return-only policy

future resource creation callable 如获批准，只能返回 opaque token / dehydrated status facts。它不得返回 native pointer、raw pointer、native handle、Objective-C object identity 或 Metal object identity。

## runtime facts

Default draft 产出：

- `didConfirmNativeResourceCreationAdmissionIntent`
- `didConfirmMainThreadGatePrerequisitePolicy`
- `didConfirmTokenTablePrerequisitePolicy`
- `didConfirmTeardownCallablePrerequisitePolicy`
- `didConfirmTokenReturnOnlyFuturePolicy`
- `didConfirmNoNativeResourceCallable`
- `didConfirmNoActualNativeResourceCreation`
- `didConfirmNoTokenTableImplementation`
- `didConfirmNoDestroyImplementation`
- `didConfirmNoPublicSurface`
- `didConfirmNoNativeObjectHandleOrPointer`
- `didConfirmNoMetalOrAppKitUsage`
- `didConfirmNoRendererStateWrite`
- `didConfirmNoBackendReadyTruth`

这些 facts 只说明 admission boundary 已固定，不说明 resource exists。

## package / native 状态

- `runtime/cjgui/cjpm.toml` 未修改。
- `runtime/cjgui/native/cjgui_native_bridge.h` 未修改。
- `runtime/cjgui/native/cjgui_native_bridge.m` 未修改。
- probe scripts 未修改。
- smoke native files 未修改。
- production `.m` 仍未正式接入主包 package config。

## 停止线

- no native resource C ABI。
- no native resource callable。
- no native object / handle / raw pointer。
- no native pointer return。
- no token table implementation。
- no retain / release / destroy。
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

- [resource creation admission preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-native-bridge-resource-creation-admission-preflight-decision.md)
- [resource creation admission value boundary closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-internal-renderer-native-bridge-resource-creation-admission-value-boundary-closure-review.md)
- [resource creation admission next-boundary](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-native-bridge-resource-creation-admission-next-boundary-decision.md)
- [native bridge teardown callable manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-native-bridge-teardown-callable-manifest.md)
- [native token table ownership hardening manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-token-table-ownership-hardening-manifest.md)
- [native token callable manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-native-token-callable-manifest.md)
- [main-thread no-resource callable manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-main-thread-no-resource-callable-manifest.md)
- [no-resource runtime FFI call owner manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-no-resource-runtime-ffi-call-owner-manifest.md)
- [native bridge C ABI surface contract manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-c-abi-surface-contract-manifest.md)

## 后续入口

唯一后续入口：

`P1 internal Renderer native token table implementation preflight decision`

该入口只能评估 token table implementation 的 owner、mutability confinement、generation / epoch、main-thread confinement、revoke / destroy ordering、write set 和 stop-line；不得直接创建 native object、native handle、raw pointer、AppKit / Metal resource、public API 或 backend-ready truth。

## 下游 token table implementation 封账

下游 [native token table implementation manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-native-token-table-implementation-manifest.md) 与 [manifest closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-internal-renderer-native-token-table-implementation-manifest-stabilization-closure-review.md) 已完成。该 downstream 只把 `CjguiInternalRendererNoNativeResourceCreationAdmissionReadiness` 作为 runtime input，并输出 `CjguiInternalRendererNoNativeTokenTableImplementationReadiness` / `cjguiInternalExecuteDefaultRendererNativeTokenTableImplementationDraft()`。

该 downstream 仍不实现 token table，不新增 native token C ABI，不修改 production native `.h` / `.m`，不创建 resource object table，不绑定 native object，不保存 raw pointer，不返回 native pointer，不新增 public API，不调用 resource callable，不创建 Metal / AppKit resource、renderer state write 或 backend-ready truth。

新的 downstream 后续入口：

`P1 internal Renderer native token table no-resource shell first implementation preflight decision`

## 设计意图出口自检

- 本轮是否改变主题状态：是，native bridge resource creation admission 已 manifest stabilization。
- 本轮是否改变 canonical tail / endpoint：是，固定 `CjguiInternalRendererNoNativeResourceCreationAdmissionReadiness` / `cjguiInternalExecuteDefaultRendererNativeResourceCreationAdmissionDraft()`。
- 本轮是否改变 owner / truth / stop-line：是，owner 固定为 `runtime_renderer_native_resource_creation_admission.cj`；truth 固定为 resource creation prerequisites、main-thread gate、token table prerequisite、teardown callable prerequisite 与 token-return-only policy；stop-line 继续禁止 resource creation、native object、public API、renderer state write 与 backend-ready truth。
- 本轮是否改变唯一 next opening：是，转为 `P1 internal Renderer native token table implementation preflight decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`docs/plans/topic-manifests/renderer-implementation-admission-chain.md`、`docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md`、`docs/plans/topic-manifests/macos-bridge-verification-smoke.md`。

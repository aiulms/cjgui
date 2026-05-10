# P1 渲染器 native handle token ownership manifest

日期：2026-05-09

状态：docs-only manifest stabilization / no native handle implementation

## 文件定位

本 manifest 固定 [runtime_renderer_native_handle_token.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_native_handle_token.cj) 的 owner、runtime input、canonical endpoint、default draft、current truth 与 stop-line。

本 manifest 不新增 runtime owner，不新增 production `.h` / `.m`，不修改 `labs/macos_bridge_smoke/native/*`，不实现 C ABI / FFI，不创建 native handle / raw pointer，不返回 native pointer，不创建 Metal resource，不创建 backend ready truth，不写 renderer state，不发布 public diagnostics 或 public API。

## 固定项

- owner file：`runtime/cjgui/src/runtime_renderer_native_handle_token.cj`
- runtime input：`CjguiInternalRendererNoNativeBridgeCAbiSurfaceReadiness`
- canonical endpoint：`CjguiInternalRendererNoNativeHandleTokenReadiness`
- default draft：`cjguiInternalExecuteDefaultRendererNativeHandleTokenDraft()`
- current truth：native handle token ownership intent / opaque token admission policy / token ownership domain policy / token invalidation / revocation policy / double-release / dangling pointer denial policy / no-native-handle-token readiness facts

## 当前事实

`NativeHandleTokenOwnershipIntent` 只表达 future native handle token ownership 的 planning intent，不创建 native handle，不返回 native pointer，不实现 C ABI / FFI。

`OpaqueTokenAdmissionPolicy` 只允许 token allocation admission planning，不执行 runtime native handle allocation，不暴露 raw pointer，不生成 public API shape。

`TokenOwnershipDomainPolicy` 固定 token 必须是 bridge-local identifier，并与 native pointer identity 分离；Objective-C 层不得成为 runtime truth source。

`TokenInvalidationRevocationPolicy` 只表达 token invalidation / revocation、main-thread confinement planning 与 destroy contract compatibility planning；它不调用 retain / release / destroy，不执行真实 native lifecycle。

`TokenSafetyDenialPolicy` 只表达 double-release denial、dangling pointer denial、stale token fail-closed 与 wrong-thread fail-closed。

`NoNativeHandleTokenReadiness` 不是 native handle permission、raw pointer permission、native bridge implementation permission、C ABI implementation permission、FFI permission、Metal permission、backend-ready permission、GPU-submission permission、render permission、renderer-state-write permission、public diagnostics permission 或 public API permission。

本轮 build 只证明 Cangjie internal value owner 可编译，不证明 production native handle、token runtime、C ABI、native bridge、Metal resource、backend ready truth、GPU submission、render、renderer state write 或 public diagnostics 可用。

## 同形边界刹车

本 manifest 只做封账，不新增 tail wrapper，不新增 receipt、record、publication、permission 字段或 public API。

不得把 `CjguiInternalRendererNoNativeHandleTokenReadiness` 包成 token-ready、native-handle-ready、bridge-ready、C-ABI-ready、Metal-ready、backend-ready、GPU-submission-ready、render permission、state-write permission、public diagnostics、receipt、record 或 publication wrapper。

## 停止线

- no `labs/macos_bridge_smoke/native/*` modification。
- no production `.h` / `.m`。
- no C ABI implementation。
- no FFI declaration。
- no native handle / raw pointer。
- no native pointer return。
- no backend ready truth。
- no backend object。
- no `MTLDevice` / `CAMetalLayer` / `MTLCommandQueue`。
- no drawable / `nextDrawable`。
- no command buffer / `commandBuffer`。
- no `commit` / `present`。
- no GPU submission。
- no render execution。
- no renderer state write。
- no `runtime_state.cj` modification。
- no public diagnostics。
- no public API / C ABI expansion。
- no native bridge / Objective-C / Metal / AppKit / FFI modification。
- no retain / release / destroy。
- no module-level mutable `var`。

## 证据链

- [native bridge C ABI surface contract manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-c-abi-surface-contract-manifest.md)
- [native bridge C ABI surface contract manifest closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-internal-renderer-native-bridge-c-abi-surface-contract-manifest-stabilization-closure-review.md)
- [native handle token ownership planning preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-handle-token-ownership-planning-preflight-decision.md)
- [native handle token ownership value boundary closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-internal-renderer-native-handle-token-ownership-value-boundary-closure-review.md)
- [native handle token ownership next-boundary decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-handle-token-ownership-next-boundary-decision.md)
- [native teardown contract hardening manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-native-teardown-contract-hardening-manifest.md)
- [native resource bridge manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-native-resource-bridge-manifest.md)
- [macOS bridge verification smoke topic manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/macos-bridge-verification-smoke.md)

## 唯一后续入口

`P1 internal Renderer native bridge teardown implementation planning preflight decision`

## 下游 native bridge teardown implementation planning 封账

下游 [native bridge teardown implementation planning manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-teardown-implementation-planning-manifest.md) 与 [manifest closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-internal-renderer-native-bridge-teardown-implementation-planning-manifest-stabilization-closure-review.md) 已完成。该 downstream 只把 `CjguiInternalRendererNoNativeHandleTokenReadiness` 作为 runtime input，并输出 `CjguiInternalRendererNoNativeBridgeTeardownImplementationReadiness` / `cjguiInternalExecuteDefaultRendererNativeBridgeTeardownPlanDraft()`。

该 downstream 不把本 manifest 的 token ownership facts 升格为 native bridge implementation permission、destroy permission、retain / release permission、native handle permission、raw pointer permission、native pointer return permission、C ABI implementation permission、FFI permission、Metal / AppKit permission、backend-ready permission、GPU submission、render、renderer state write、public diagnostics 或 public API permission。

新的 downstream 后续入口：

`P1 internal Renderer native bridge first production write-set preflight decision`

## 下游生产写集预检封账

下游 [native bridge first production write-set preflight decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-first-production-write-set-preflight-decision.md) 已完成。该 downstream 继续使用本 manifest 的 opaque token admission、ownership domain、token invalidation / revocation、double-release / dangling pointer denial 与 no-native-handle-token facts 作为 production bridge skeleton planning evidence。

该 downstream 不把 `CjguiInternalRendererNoNativeHandleTokenReadiness` 升格为 native handle permission、raw pointer permission、native pointer return permission、native bridge implementation permission、callable C ABI permission、FFI permission、Objective-C / Metal / AppKit permission、backend-ready permission、GPU submission、render、renderer state write、public diagnostics 或 public API permission。

新的 downstream 后续入口：

`P1 internal Renderer production native bridge skeleton write-set contract bundle`

## 下游 skeleton 写集封账

下游 [production native bridge skeleton write-set manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-production-native-bridge-skeleton-write-set-manifest.md) 与 [manifest closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-internal-renderer-production-native-bridge-skeleton-write-set-manifest-stabilization-closure-review.md) 已完成。该 downstream 使用本 manifest 的 opaque token admission、ownership domain、token invalidation / revocation、double-release / dangling pointer denial 与 no-native-handle-token facts 作为 production bridge skeleton planning evidence。

该 downstream 不把 `CjguiInternalRendererNoNativeHandleTokenReadiness` 升格为 native handle permission、raw pointer permission、native pointer return permission、native bridge implementation permission、callable C ABI permission、FFI permission、Objective-C / Metal / AppKit permission、backend-ready permission、GPU submission、render、renderer state write、public diagnostics、public API 或 build config modification permission。

新的 downstream 后续入口：

`P1 internal Renderer native bridge build system integration preflight decision`

## 下游 callable C ABI planning 封账

下游 [native bridge callable C ABI planning manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-callable-c-abi-planning-manifest.md) 与 [manifest closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-internal-renderer-native-bridge-callable-c-abi-planning-manifest-stabilization-closure-review.md) 已完成。该 downstream 继续使用本 manifest 的 opaque token admission、ownership domain、token invalidation / revocation、double-release / dangling pointer denial 与 no-native-handle-token facts 作为 no-resource callable guard 的 planning evidence。

该 downstream 不把 `CjguiInternalRendererNoNativeHandleTokenReadiness` 升格为 native handle permission、raw pointer permission、native pointer return permission、callable C ABI implementation permission、FFI permission、runtime `.cj` FFI declaration permission、native bridge implementation permission、Objective-C / Metal / AppKit permission、backend-ready permission、GPU submission、render、renderer state write、public diagnostics 或 public API permission。

新的 downstream 后续入口：

`P1 internal Renderer native bridge callable C ABI first implementation preflight decision`

## 下游 native token callable 封账

下游 [native bridge native token callable manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-native-token-callable-manifest.md) 与 [manifest closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-internal-renderer-native-bridge-native-token-callable-manifest-stabilization-closure-review.md) 已完成。该 downstream 继续使用本 manifest 的 opaque token admission、ownership domain、invalidation / revocation、double-release / dangling pointer denial 与 no-native-handle-token facts 作为 native token callable planning evidence。

该 downstream 不把 `CjguiInternalRendererNoNativeHandleTokenReadiness` 升格为 native token C ABI permission、token table permission、native handle permission、raw pointer permission、native pointer return permission、native bridge implementation permission、FFI permission、Objective-C / Metal / AppKit permission、backend-ready permission、GPU submission、render、renderer state write、public diagnostics 或 public API permission。

新的 downstream 后续入口：

`P1 internal Renderer native token table ownership hardening preflight decision`

## 下游 token table ownership hardening 封账

下游 [native token table ownership hardening manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-token-table-ownership-hardening-manifest.md) 与 [manifest closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-internal-renderer-native-token-table-ownership-hardening-manifest-stabilization-closure-review.md) 已完成。该 downstream 继续使用本 manifest 的 opaque token admission、ownership domain、invalidation / revocation、double-release / dangling pointer denial 与 no-native-handle-token facts 作为 token table ownership hardening evidence。

该 downstream 不把 `CjguiInternalRendererNoNativeHandleTokenReadiness` 升格为 native token C ABI permission、token table implementation permission、native handle permission、raw pointer permission、native pointer return permission、native bridge implementation permission、destroy permission、FFI permission、Objective-C / Metal / AppKit permission、backend-ready permission、GPU submission、render、renderer state write、public diagnostics 或 public API permission。

新的 downstream 后续入口：

`P1 internal Renderer native bridge teardown callable preflight decision`

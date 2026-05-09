# P1 内部渲染器 native bridge native token callable 清单

日期：2026-05-09

状态：manifest stabilization / planning value boundary

## 固定对象

- Owner：`runtime/cjgui/src/runtime_renderer_native_bridge_token_callable.cj`
- Endpoint：`CjguiInternalRendererNoNativeBridgeTokenCallableReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererNativeBridgeTokenCallableDraft()`
- Runtime input：`CjguiInternalRendererNoNativeBridgeMainThreadCallReadiness`
- Actual route：planning value boundary
- Native callable list：无新增

## token type policy

future token callable 只能使用 opaque integer token。当前 policy 固定为 `UInt64` / `uint64_t` 方向；struct token、native pointer token、`uintptr_t` token、Objective-C object identity token 和 raw handle token 继续禁止。

token 只能作为 future bridge-local identifier。token 不得编码 native pointer，不得由 native pointer cast 得来，不得作为 public API surface 泄漏。

## table mutability policy

本轮不创建 token table，也不新增 runtime 或 native global mutable state。

原因：

- 没有 table 的 issue / revoke 无法形成安全 validate 闭环。
- 有 table 的 issue / revoke 会引入 mutable ownership state，需要单独 preflight。
- 当前 stage 不允许 native handle / raw pointer / native object，也不允许 module-level mutable runtime state。

因此当前 owner 只固定 table mutability denial / fallback policy，并把 issue / revoke implementation deferred。

## revocation / destroy separation

revocation policy 必须与 destroy / release / retain 分离。

本轮只记录 revoke-without-destroy policy、double-revoke fail-closed policy 与 future main-thread gate requirement；不实现 destroy callback，不调用 retain / release / destroy，不触发 native lifecycle mutation。

## runtime facts

Default draft 产出：

- `didConfirmOpaqueTokenTypePolicy`
- `didConfirmNoPointerTokenPolicy`
- `didConfirmTokenTableMutabilityDenied`
- `didConfirmIssueRevokeImplementationDeferred`
- `didConfirmRevokeWithoutDestroyPolicy`
- `didConfirmMainThreadGatePreserved`
- `didConfirmNoPublicSurface`
- `didConfirmNoResourceCallable`
- `didConfirmNoNativeObjectHandleOrPointer`
- `didConfirmNoMetalOrAppKitUsage`
- `didConfirmNoRendererStateWrite`
- `didConfirmNoBackendReadyTruth`

这些 facts 只说明 native token callable 的安全模型已被 internal owner 固定，不说明 token implementation 已存在。

## package / native 状态

- `runtime/cjgui/cjpm.toml` 未修改。
- `runtime/cjgui/native/cjgui_native_bridge.h` 未因本轮新增 token callable。
- `runtime/cjgui/native/cjgui_native_bridge.m` 未因本轮新增 token callable。
- probe scripts 未因本轮新增 token symbol allowlist。
- production `.m` 未正式接入主包 package config。

## 停止线

- no public API / diagnostics。
- no resource callable。
- no native object / handle / raw pointer。
- no native pointer return。
- no token-as-pointer。
- no token table。
- no module-level mutable `var`。
- no production native token callable implementation。
- no Cocoa / Metal / QuartzCore import。
- no AppKit / Metal object creation。
- no retain / release / destroy。
- no drawable / command buffer / `commit` / `present`。
- no GPU submission。
- no render execution。
- no renderer state write。
- no `runtime_state.cj` modification。
- no smoke native edits。
- no backend-ready truth。

## 证据链

- [main-thread no-resource callable manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-main-thread-no-resource-callable-manifest.md)
- [main-thread no-resource callable manifest closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-internal-renderer-native-bridge-main-thread-no-resource-callable-manifest-stabilization-closure-review.md)
- [native handle token ownership manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-handle-token-ownership-manifest.md)
- [no-resource runtime FFI call owner manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-no-resource-runtime-ffi-call-owner-manifest.md)
- [native token callable preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-native-token-callable-preflight-decision.md)
- [native token callable closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-internal-renderer-native-bridge-native-token-callable-closure-review.md)
- [native token callable next-boundary](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-native-token-callable-next-boundary-decision.md)

## 后续入口

唯一后续入口：

`P1 internal Renderer native token table ownership hardening preflight decision`

该入口只能评估 token table ownership、mutability、main-thread confinement、fail-closed validate / revoke 与 teardown compatibility；不得直接创建 native object、native handle、raw pointer、Metal / AppKit resource、destroy callback、public API 或 backend-ready truth。

## 设计意图出口自检

- 本轮是否改变主题状态：是，native token callable 已 manifest stabilization。
- 本轮是否改变 canonical tail / endpoint：是，固定 `CjguiInternalRendererNoNativeBridgeTokenCallableReadiness` / `cjguiInternalExecuteDefaultRendererNativeBridgeTokenCallableDraft()`。
- 本轮是否改变 owner / truth / stop-line：是，owner 固定为 `runtime_renderer_native_bridge_token_callable.cj`；truth 固定为 opaque token planning、table mutability denial 与 revoke-without-destroy facts；stop-line 继续禁止 native object、pointer handle、public API、Metal / AppKit、renderer state write 与 backend-ready truth。
- 本轮是否改变唯一 next opening：是，转为 `P1 internal Renderer native token table ownership hardening preflight decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`docs/plans/topic-manifests/renderer-implementation-admission-chain.md`、`docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md`、`docs/plans/topic-manifests/macos-bridge-verification-smoke.md`。

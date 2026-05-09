# P1 渲染器 native bridge runtime internal FFI declaration 第一实现清单

日期：2026-05-09

状态：manifest stabilization / internal declaration only

## 文件定位

本 manifest 固定 runtime internal FFI declaration first implementation stage 的 actual write set、owner、endpoint、declared callable list、package link status、truth 与 stop-line。

本 manifest 不批准 runtime FFI call，不批准 public API，不批准 resource callable，不批准 native object，不批准 Metal / AppKit，不批准 backend-ready truth。

## 实际写集

- `runtime/cjgui/src/runtime_renderer_native_bridge_runtime_ffi_declaration.cj`
- `docs/plans/2026-05-09-p1-renderer-native-bridge-runtime-internal-ffi-declaration-first-implementation-preflight-decision.md`
- `docs/plans/2026-05-09-p1-internal-renderer-native-bridge-runtime-internal-ffi-declaration-first-implementation-closure-review.md`
- `docs/plans/2026-05-09-p1-renderer-native-bridge-runtime-internal-ffi-declaration-first-implementation-next-boundary-decision.md`
- `runtime/cjgui/native/scripts/verify_native_bridge_package_link_probe.sh`

## 固定项

- Runtime owner：`runtime/cjgui/src/runtime_renderer_native_bridge_runtime_ffi_declaration.cj`
- Runtime input：`CjguiInternalRendererNoNativeBridgeCjpmPackageLinkReadiness`
- Canonical endpoint：`CjguiInternalRendererNoNativeBridgeRuntimeFfiCallReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererNativeBridgeRuntimeFfiDeclarationDraft()`
- Existing planning owner preserved：`CjguiInternalRendererNoNativeBridgeFfiDeclarationReadiness` 仍代表旧 planning facts，不被翻译为 implementation permission。
- Package config status：`runtime/cjgui/cjpm.toml` 未修改。
- Runtime package link status：production native bridge object / static archive 未接入 `runtime/cjgui` 主包。
- Internal call status：没有 runtime FFI call。

## 已声明 callable

本阶段新增以下 internal-only `foreign func` declaration：

- `cjgui_native_bridge_surface_version(): UInt32`
- `cjgui_native_bridge_surface_capabilities(): UInt32`
- `cjgui_native_bridge_status_ok(): UInt32`
- `cjgui_native_bridge_no_resource_admission(): UInt32`

这些 declarations 没有被调用，没有 public wrapper，不返回 pointer，不创建 native object，不写 state。

## 禁止 callable

- `cjgui_app_run`
- `cjgui_last_error_*`
- create / destroy native object
- init AppKit / Metal
- create window / view / layer / device / queue
- return token / handle / pointer
- mutate state
- submit / render / present
- public runtime API

## 证据结论

`cjpm build --target-dir /tmp/cjgui-renderer-native-bridge-runtime-ffi-declaration-first-implementation-target --skip-script` 已通过，证明 declarations 可以留在 `runtime/cjgui` 内部而不触发当前主包 link requirement。

`verify_native_bridge_package_link_probe.sh` 只在 probe 执行环境中补充仓颉 runtime dylib path，以保证 package-adjacent direct link probe 可复核运行。该脚本修正不修改 `runtime/cjgui/cjpm.toml`，不接 production `.m` 到主包，不新增 runtime FFI call。

这仍不是 runtime FFI call。下一步若要调用这些 functions，必须先单独评估 internal no-resource FFI call verification owner、link route 与 failure classification。

## 同形边界刹车

不得把 internal FFI declaration、script-managed package link probe、direct `cjc` probe、isolated FFI probe、symbol probe 或本 manifest evidence 包装成 runtime FFI call permission、public API permission、resource callable permission、native object permission、Metal / AppKit permission、backend-ready permission、GPU-submission permission、render permission、renderer-state-write permission、receipt、record 或 publication。

Internal declaration 只证明 runtime 内部拥有 no-resource C ABI declaration shape，不证明 GUI backend ready。

## 停止线

- no public API。
- no public diagnostics。
- no runtime FFI call。
- no resource callable。
- no native object / handle / raw pointer。
- no native pointer return。
- no Cocoa / Metal / QuartzCore import in production bridge。
- no AppKit / Metal object creation。
- no retain / release / destroy。
- no drawable / command buffer / `commit` / `present`。
- no GPU submission。
- no render execution。
- no renderer state write。
- no `runtime_state.cj` modification。
- no smoke native edits。
- no backend-ready truth。

## 后续入口

`P1 internal Renderer native bridge internal no-resource FFI call verification bundle`

## 下游接续

下游 [no-resource FFI call verification manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-no-resource-ffi-call-verification-manifest.md) 与 [manifest closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-internal-renderer-native-bridge-no-resource-ffi-call-verification-manifest-stabilization-closure-review.md) 已完成。该下游没有新增 runtime owner call，而是通过 runtime-adjacent probe 观察四个 no-resource C ABI 返回 facts；它仍不修改 `runtime/cjgui/cjpm.toml`，不接入 production `.m` 到主包，不新增 public API，不调用 resource callable，不创建 native object 或 backend-ready truth。当前唯一后续入口已转为 `P1 internal Renderer native bridge runtime package link call support preflight decision`。

下游 [package config link route reconciliation scan](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-package-config-link-route-reconciliation-scan.md) 已完成。该 scan 确认本 manifest 固定的 internal-only `foreign func` declarations 仍只是 runtime internal declaration facts，不是 actual runtime FFI call owner、public API、resource callable、native object、Metal / AppKit、renderer state write 或 backend-ready truth；当前主线唯一后续入口已转为 `P1 internal Renderer native bridge internal no-resource runtime FFI call owner preflight decision`。

## 设计意图出口自检

- 本轮是否改变主题状态：是，runtime internal FFI declaration first implementation 已 manifest stabilization。
- 本轮是否改变 canonical tail / endpoint：是，新增并固定 `CjguiInternalRendererNoNativeBridgeRuntimeFfiCallReadiness`。
- 本轮是否改变 owner / truth / stop-line：是，新增 runtime owner；truth 仅限 internal declaration / no-runtime-call / package-link-required facts；stop-line 继续禁止 runtime FFI call、public API、resource callable、native object 与 backend-ready truth。
- 本轮是否改变唯一 next opening：是，转为 `P1 internal Renderer native bridge internal no-resource FFI call verification bundle`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`docs/plans/topic-manifests/renderer-implementation-admission-chain.md`、`docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md`、`docs/plans/topic-manifests/macos-bridge-verification-smoke.md`。

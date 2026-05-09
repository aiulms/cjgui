# P1 渲染器 native bridge runtime package link call support 清单

日期：2026-05-09

状态：manifest stabilization / no runtime package call support

## 文件定位

本 manifest 固定 runtime package link call support stage 的 actual owner、endpoint、runtime input、truth、package link / call blocker facts 与 stop-line。

本 manifest 不批准 actual runtime FFI call，不批准 public API，不批准 resource callable，不批准 native object，不批准 Metal / AppKit，不批准 renderer state write，也不批准 backend-ready truth。

## 实际路线

Actual route：internal value boundary。

本阶段新增 owner 表达 call support 条件与阻塞点；没有新增 runtime package-call-support probe，没有修改 `runtime/cjgui/cjpm.toml`，没有把 production `.m` 接入主包，也没有新增 runtime FFI call owner。

## 实际写集

- `runtime/cjgui/src/runtime_renderer_native_bridge_package_call_support.cj`
- `docs/plans/2026-05-09-p1-renderer-native-bridge-runtime-package-link-call-support-preflight-decision.md`
- `docs/plans/2026-05-09-p1-internal-renderer-native-bridge-runtime-package-link-call-support-value-boundary-closure-review.md`
- `docs/plans/2026-05-09-p1-renderer-native-bridge-runtime-package-link-call-support-next-boundary-decision.md`

## Runtime owner

- Owner file：`runtime/cjgui/src/runtime_renderer_native_bridge_package_call_support.cj`
- Endpoint：`CjguiInternalRendererNoNativeBridgePackageCallSupportReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererNativeBridgePackageCallSupportDraft()`
- Runtime input：`CjguiInternalRendererNoNativeBridgeRuntimeFfiCallReadiness`

## 当前 truth

本阶段只允许表达：

- runtime package call support intent。
- package link call support policy。
- dylib path / object path evidence policy。
- macOS-only call support gate。
- runtime-adjacent probe evidence policy。
- no-runtime-package-call-support readiness facts。

## Package link / call 状态

- `runtime/cjgui/cjpm.toml` 未修改。
- production `.m` 未接入 `runtime/cjgui` 主包。
- existing runtime-adjacent probe 已观察四个 no-resource callable。
- existing script-managed package link probe 仍是证据来源。
- actual runtime package call support 仍 blocked。

## 可观察 facts

本阶段 default draft 固定：

- `didConfirmRuntimeAdjacentNoResourceCallEvidence=true`
- `didConfirmRuntimePackageConfigStillDeferred=true`
- `didIdentifyRuntimePackageCallSupportBlocker=true`
- `didConfirmNoActualRuntimeFfiCall=true`
- `didConfirmNoPublicSurface=true`
- `didConfirmNoResourceCallable=true`
- `didConfirmNoNativeObjectHandleOrPointer=true`
- `didConfirmNoMetalOrAppKitUsage=true`
- `didConfirmNoRendererStateWrite=true`
- `didConfirmNoBackendReadyTruth=true`

## 停止线

- no actual runtime FFI call。
- no public API / diagnostics。
- no resource callable。
- no native object / handle / raw pointer。
- no native pointer return。
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

## 同形边界刹车

不得把 runtime package call support owner、runtime-adjacent call probe、package link evidence、internal `foreign func` declarations 或 no-resource C ABI facts 包装成 actual runtime FFI call permission、public API permission、resource callable permission、native object permission、Metal / AppKit permission、backend-ready permission、GPU-submission permission、render permission、renderer-state-write permission、receipt、record 或 publication。

Package call support facts 只证明主包通路条件与阻塞分类，不证明 GUI backend ready。

## 下游接续

唯一后续入口：

`P1 internal Renderer native bridge package config link implementation preflight decision`

下一步只允许 docs-first 判断是否、如何以 macOS-only / non-macOS fallback 的方式把 no-resource native bridge archive 接入 `runtime/cjgui` package config；不得直接进入 runtime FFI call owner、public API、resource callable、native object、Metal / AppKit 或 backend-ready truth。

## 下游接续记录

下游 [package config link implementation stage manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-package-config-link-implementation-stage-manifest.md) 已完成。该下游新增 `CjguiInternalRendererNoNativeBridgePackageConfigLinkReadiness` / `cjguiInternalExecuteDefaultRendererNativeBridgePackageConfigLinkDraft()`，采用 script-managed route stabilization，没有修改 `runtime/cjgui/cjpm.toml`，没有接入 production `.m` 到主包，也没有新增 actual runtime FFI call、public API、resource callable、native object、Metal / AppKit 或 backend-ready truth。

下游 [package config link route reconciliation scan](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-package-config-link-route-reconciliation-scan.md) 已完成。该 scan 继续确认 package call support facts 仍只是通路条件与 blocker 分类，不是 actual runtime FFI call permission、public API permission、resource callable permission、native object permission、Metal / AppKit permission 或 backend-ready truth；当前主线唯一后续入口已转为 `P1 internal Renderer native bridge internal no-resource runtime FFI call owner preflight decision`。

## 设计意图出口自检

- 本轮是否改变主题状态：是，runtime package link call support 已完成 value boundary 与 manifest stabilization。
- 本轮是否改变 canonical tail / endpoint：是，新增并固定 `CjguiInternalRendererNoNativeBridgePackageCallSupportReadiness` / `cjguiInternalExecuteDefaultRendererNativeBridgePackageCallSupportDraft()`。
- 本轮是否改变 owner / truth / stop-line：是，新增 package call support owner；truth 固定为 call support / blocker facts；stop-line 继续禁止 runtime call、public API、resource callable、native object、Metal / AppKit、renderer state write 与 backend-ready truth。
- 本轮是否改变唯一 next opening：是，转为 `P1 internal Renderer native bridge package config link implementation preflight decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`docs/plans/topic-manifests/renderer-implementation-admission-chain.md`、`docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md`、`docs/plans/topic-manifests/macos-bridge-verification-smoke.md`。

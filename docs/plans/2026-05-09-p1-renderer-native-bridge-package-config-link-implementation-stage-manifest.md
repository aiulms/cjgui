# P1 渲染器 native bridge package config link implementation 阶段清单

日期：2026-05-09

状态：manifest stabilization / script-managed route

## 文件定位

本 manifest 固定 native bridge package config link implementation stage 的 actual route、write set、owner、endpoint、artifact policy、package config status、truth 与 stop-line。

本 manifest 不批准 actual runtime FFI call，不批准 public API，不批准 resource callable，不批准 native object，不批准 Metal / AppKit，不批准 backend-ready truth。

## 实际路线

Actual route：script-managed link route stabilization。

本阶段没有修改 `runtime/cjgui/cjpm.toml`。原因是当前 no-resource static archive 仍由 probe 脚本生成；若直接在主包 `cjpm.toml` 写入 `link-option`，`cjpm build --skip-script` 无法稳定获得 artifact。

当前可复核 link evidence 仍来自：

- isolated FFI probe。
- script-managed temporary `cjpm` package link probe。
- runtime-adjacent no-resource call probe。
- main package `cjpm build --skip-script` 仍不依赖 production native archive。

## 实际写集

- `runtime/cjgui/src/runtime_renderer_native_bridge_package_config_link.cj`
- `docs/plans/2026-05-09-p1-renderer-native-bridge-package-config-link-implementation-preflight-decision.md`
- `docs/plans/2026-05-09-p1-internal-renderer-native-bridge-package-config-link-implementation-stage-closure-review.md`
- `docs/plans/2026-05-09-p1-renderer-native-bridge-package-config-link-implementation-stage-next-boundary-decision.md`

## 固定项

- Runtime owner：`runtime/cjgui/src/runtime_renderer_native_bridge_package_config_link.cj`
- Runtime input：`CjguiInternalRendererNoNativeBridgePackageCallSupportReadiness`
- Canonical endpoint：`CjguiInternalRendererNoNativeBridgePackageConfigLinkReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererNativeBridgePackageConfigLinkDraft()`
- Package config status：`runtime/cjgui/cjpm.toml` 未修改。
- Artifact generation policy：no-resource object / static archive 继续由 probe 脚本在 `/tmp` 生成。
- macOS-only gating：probe route 只在 macOS 执行。
- non-macOS fallback：主包配置未改变，非 macOS 不受 production native archive 影响。

## 允许 callable 清单

- `cjgui_native_bridge_surface_version`
- `cjgui_native_bridge_surface_capabilities`
- `cjgui_native_bridge_status_ok`
- `cjgui_native_bridge_no_resource_admission`

## 禁止 callable 清单

- `cjgui_app_run`
- `cjgui_last_error_*`
- create / destroy native object。
- init AppKit / Metal。
- create window / view / layer / device / queue。
- return token / handle / pointer。
- mutate state。
- submit / render / present。
- public runtime API。

## 可观察 facts

Default draft 固定：

- `didConfirmPackageConfigLinkStillDeferred=true`
- `didConfirmScriptManagedRouteStable=true`
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

不得把 package config link manifest、script-managed link route、package call support facts、temporary package success、runtime-adjacent call facts 或 no-resource callable 包装成 runtime FFI call permission、public API permission、resource callable permission、native object permission、Metal / AppKit permission、backend-ready permission、GPU-submission permission、render permission、renderer-state-write permission、receipt、record 或 publication。

Package config link facts 只证明当前主包配置仍 deferred 且 script-managed route 稳定，不证明 GUI backend ready。

## 后续入口

唯一后续入口：

`P1 internal Renderer native bridge package config link route reconciliation scan`

下一步应先扫描 package config still-deferred facts、script-managed route、runtime-adjacent no-resource call evidence 与 owner 链条是否已经足够，不得直接进入 public API、resource callable、native object、Metal / AppKit、renderer state write 或 backend-ready truth。

## 下游接续

下游 [package config link route reconciliation scan](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-package-config-link-route-reconciliation-scan.md) 已完成。该 scan 确认本 manifest 固定的 script-managed route、package config still-deferred facts、runtime-adjacent no-resource call evidence 与 owner 链条一致；它不改变本 manifest 的 canonical endpoint，也不把 package config link facts 升格为 actual runtime FFI call、public API、resource callable、native object、Metal / AppKit、renderer state write 或 backend-ready truth。再下游 [no-resource runtime FFI call owner manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-no-resource-runtime-ffi-call-owner-manifest.md) 已把新 canonical endpoint 推进为 `CjguiInternalRendererNoNativeBridgeNoResourceRuntimeCallReadiness`，但仍不改变本 manifest 的 package config still-deferred 结论。

## 设计意图出口自检

- 本轮是否改变主题状态：是，package config link implementation stage 已完成 script-managed route manifest stabilization。
- 本轮是否改变 canonical tail / endpoint：是，新增并固定 `CjguiInternalRendererNoNativeBridgePackageConfigLinkReadiness` / `cjguiInternalExecuteDefaultRendererNativeBridgePackageConfigLinkDraft()`。
- 本轮是否改变 owner / truth / stop-line：是，新增 package config link owner；truth 限定为 script-managed route、artifact generation policy、package config still deferred 与 no-package-config-link facts；stop-line 继续禁止 runtime call、public API、resource callable、native object、Metal / AppKit、renderer state write 与 backend-ready truth。
- 本轮是否改变唯一 next opening：是，转为 `P1 internal Renderer native bridge package config link route reconciliation scan`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`docs/plans/topic-manifests/renderer-implementation-admission-chain.md`、`docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md`、`docs/plans/topic-manifests/macos-bridge-verification-smoke.md`。

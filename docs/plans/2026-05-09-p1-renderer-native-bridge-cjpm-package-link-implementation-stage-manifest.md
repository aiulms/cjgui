# P1 渲染器 native bridge cjpm package link implementation 阶段清单

日期：2026-05-09

状态：manifest stabilization / script-managed cjpm package link route

## 文件定位

本 manifest 固定 native bridge `cjpm` package link implementation stage 的 actual route、write set、owner、endpoint、probe、package config status、truth 与 stop-line。

本 manifest 不批准 runtime FFI call，不批准 public API，不批准 resource callable，不批准 native object，不批准 Metal / AppKit，不批准 backend-ready truth。

## 实际路线

Actual route：script-managed temporary `cjpm` package link route。

本阶段没有修改 `runtime/cjgui/cjpm.toml`。新增 probe 会在 `/tmp/cjgui-native-bridge-cjpm-package-link-*` 下生成 production no-resource native bridge object / static archive 与临时仓颉 executable package，再通过该临时 package 的 `compile-option` / `link-option` 运行 `cjpm run --skip-script`。

该路线证明 `cjpm` package-level link 机制可链接当前 no-resource static archive，但仍不是 `runtime/cjgui` 主包 package config integration。

## 实际写集

- `runtime/cjgui/native/scripts/verify_native_bridge_cjpm_package_link_probe.sh`
- `runtime/cjgui/src/runtime_renderer_native_bridge_cjpm_package_link.cj`
- `docs/plans/2026-05-09-p1-renderer-native-bridge-cjpm-package-link-implementation-preflight-decision.md`
- `docs/plans/2026-05-09-p1-internal-renderer-native-bridge-cjpm-package-link-implementation-stage-closure-review.md`
- `docs/plans/2026-05-09-p1-renderer-native-bridge-cjpm-package-link-implementation-stage-next-boundary-decision.md`

## 固定项

- Runtime owner：`runtime/cjgui/src/runtime_renderer_native_bridge_cjpm_package_link.cj`
- Runtime input：`CjguiInternalRendererNoNativeBridgePackageLinkReadiness`
- Canonical endpoint：`CjguiInternalRendererNoNativeBridgeCjpmPackageLinkReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererNativeBridgeCjpmPackageLinkDraft()`
- Script-managed probe：`runtime/cjgui/native/scripts/verify_native_bridge_cjpm_package_link_probe.sh`
- Package config status：`runtime/cjgui/cjpm.toml` 未修改，未声明 `[ffi.c]`，未写入 `cjgui_native_bridge`、`link-option` 或 `compile-option`。
- macOS-only gating：当前 probe 只在 macOS 执行，非 macOS fail closed。
- non-macOS fallback：不修改 runtime package config，不影响 `cjpm build --skip-script`。

## 允许可调用项清单

- `cjgui_native_bridge_surface_version`
- `cjgui_native_bridge_surface_capabilities`
- `cjgui_native_bridge_status_ok`
- `cjgui_native_bridge_no_resource_admission`

## 禁止可调用项清单

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

新增 script-managed `cjpm` package link probe 已证明 no-resource static archive 可以被临时仓颉 package 的 `link-option` 链接，并通过 `cjpm run --skip-script` 调用四个 allowed callable。该 probe 同时确认 `runtime/cjgui/cjpm.toml` 未改变。

这仍不是 runtime package link integration。当前 runtime package 内没有真实 FFI declaration、没有 runtime FFI call，也没有 public surface。

## 同形边界刹车

不得把 script-managed `cjpm` package link probe、temporary package success、package link owner endpoint、direct `cjc` link evidence、FFI syntax evidence、symbol probe、no-resource callable 或 manifest evidence 包装成 runtime FFI call permission、public API permission、resource callable permission、native object permission、Metal / AppKit permission、backend-ready permission、GPU-submission permission、render permission、renderer-state-write permission、receipt、record 或 publication。

Package link route evidence 只证明 no-resource native bridge linkage path 可复核，不证明 GUI backend ready。

## 停止线

- no public API。
- no public diagnostics。
- no runtime FFI call。
- no `runtime/cjgui/cjpm.toml` modification。
- no runtime package / build config mutation。
- no production `.m` direct integration into `runtime/cjgui` package build。
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

`P1 internal Renderer native bridge runtime internal FFI declaration first implementation bundle`

## 下游接续记录

下游 [runtime internal FFI declaration first implementation manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-runtime-internal-ffi-declaration-first-implementation-manifest.md) 已完成。本 manifest 固定的 `CjguiInternalRendererNoNativeBridgeCjpmPackageLinkReadiness` 仅作为下游 internal declaration owner 的 runtime input；下游新增 endpoint 为 `CjguiInternalRendererNoNativeBridgeRuntimeFfiCallReadiness` / `cjguiInternalExecuteDefaultRendererNativeBridgeRuntimeFfiDeclarationDraft()`，并把唯一后续入口改为 `P1 internal Renderer native bridge internal no-resource FFI call verification bundle`。

## 设计意图出口自检

- 本轮是否改变主题状态：是，native bridge `cjpm` package link implementation stage 已完成 script-managed route 与 manifest stabilization。
- 本轮是否改变 canonical tail / endpoint：是，新增并固定 `CjguiInternalRendererNoNativeBridgeCjpmPackageLinkReadiness`。
- 本轮是否改变 owner / truth / stop-line：是，新增 runtime owner；truth 仅限 script-managed package link route、macOS-only gate、runtime package config fallback 与 no-resource link policy；stop-line 继续禁止 runtime FFI call、public API、resource callable、native object 与 backend-ready truth。
- 本轮是否改变唯一 next opening：是，转为 `P1 internal Renderer native bridge runtime internal FFI declaration first implementation bundle`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`docs/plans/topic-manifests/renderer-implementation-admission-chain.md`、`docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md`、`docs/plans/topic-manifests/macos-bridge-verification-smoke.md`。

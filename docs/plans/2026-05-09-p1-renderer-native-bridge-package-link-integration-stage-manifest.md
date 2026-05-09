# P1 渲染器 native bridge package link integration 阶段清单

日期：2026-05-09

状态：manifest stabilization / package-adjacent probe passed

## 文件定位

本 manifest 固定 native bridge package link integration stage 的 actual route、write set、owner、endpoint、probe、package config status、truth 与 stop-line。

本 manifest 不批准 public API，不批准 runtime FFI call，不批准 resource callable，不批准 native object，不批准 Metal / AppKit，不批准 backend-ready truth。

## 实际路线

Actual route：package-adjacent probe only。

本阶段新增 package-adjacent direct `cjc` link probe，证明 `runtime/cjgui` 语境旁路可以构建 production no-resource native bridge object / static archive，并通过临时仓颉 `foreign func` caller 链接调用四个 no-resource callable。

本阶段没有修改 `runtime/cjgui/cjpm.toml`，没有把 production `.m` 接入 `cjpm build`，没有新增 runtime FFI call。

## 实际写集

- `runtime/cjgui/native/scripts/verify_native_bridge_package_link_probe.sh`
- `runtime/cjgui/src/runtime_renderer_native_bridge_package_link.cj`
- `docs/plans/2026-05-09-p1-renderer-native-bridge-package-link-integration-preflight-decision.md`
- `docs/plans/2026-05-09-p1-internal-renderer-native-bridge-package-link-integration-stage-closure-review.md`
- `docs/plans/2026-05-09-p1-renderer-native-bridge-package-link-integration-stage-next-boundary-decision.md`

## 固定项

- Runtime owner：`runtime/cjgui/src/runtime_renderer_native_bridge_package_link.cj`
- Runtime input：`CjguiInternalRendererNoNativeBridgeFfiLinkReadiness`
- Canonical endpoint：`CjguiInternalRendererNoNativeBridgePackageLinkReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererNativeBridgePackageLinkDraft()`
- Package-adjacent probe：`runtime/cjgui/native/scripts/verify_native_bridge_package_link_probe.sh`
- Package config status：`runtime/cjgui/cjpm.toml` 未修改，未声明 `[ffi.c]`，未写入 `cjgui_native_bridge`、`link-option` 或 `compile-option`。
- macOS-only gating：当前 probe 只在 macOS 执行，非 macOS 应 fail closed。
- non-macOS fallback：不修改 package config，不影响 `cjpm build --skip-script`。

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

Package-adjacent probe 已证明 production no-resource native bridge skeleton 可在 `runtime/cjgui` 语境旁路形成 object / static archive，并可由临时仓颉 `foreign func` caller 通过 direct `cjc -L ... -l ...` 链接调用。

这仍不是 `cjpm` package integration。当前 package config 未接入 native object，runtime package 内没有真实 FFI call，也没有 public surface。

## 同形边界刹车

不得把 package-adjacent probe、package link planning endpoint、direct `cjc` link evidence、FFI syntax evidence、symbol probe、no-resource callable 或 manifest evidence 包装成 runtime FFI call permission、`cjpm` package integration permission、public API permission、resource callable permission、native object permission、Metal / AppKit permission、backend-ready permission、GPU-submission permission、render permission、renderer-state-write permission、receipt、record 或 publication。

Package link route evidence 只证明 no-resource native bridge linkage path可复核，不证明 GUI backend ready。

## 停止线

- no public API。
- no public diagnostics。
- no runtime FFI call。
- no `runtime/cjgui/cjpm.toml` modification。
- no package / build config mutation。
- no production `.m` cjpm integration。
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

`P1 internal Renderer native bridge cjpm package link implementation preflight decision`

## 下游接续

后续 native bridge `cjpm` package link implementation stage 已完成封账，新增 `runtime/cjgui/src/runtime_renderer_native_bridge_cjpm_package_link.cj` 与 `runtime/cjgui/native/scripts/verify_native_bridge_cjpm_package_link_probe.sh`，固定 `CjguiInternalRendererNoNativeBridgeCjpmPackageLinkReadiness` / `cjguiInternalExecuteDefaultRendererNativeBridgeCjpmPackageLinkDraft()`。该下游只证明 production no-resource native bridge static archive 可被临时仓颉 package 的 `compile-option` / `link-option` 通过 `cjpm run --skip-script` 链接调用；仍未修改 `runtime/cjgui/cjpm.toml`，未接 runtime FFI call，未创建 native object、native handle、raw pointer、Metal / AppKit resource、backend-ready truth、renderer state write 或 public API。

## 设计意图出口自检

- 本轮是否改变主题状态：是，native bridge package link integration stage 已完成 package-adjacent probe 与 manifest stabilization。
- 本轮是否改变 canonical tail / endpoint：是，新增并固定 `CjguiInternalRendererNoNativeBridgePackageLinkReadiness`。
- 本轮是否改变 owner / truth / stop-line：是，新增 runtime owner；truth 仅限 package-adjacent link route evidence、macOS-only package link gate、package config admission / fallback 与 no-resource callable link boundary；stop-line 继续禁止 runtime FFI call、public API、resource callable 与 native object。
- 本轮是否改变唯一 next opening：是，转为 `P1 internal Renderer native bridge cjpm package link implementation preflight decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`docs/plans/topic-manifests/renderer-implementation-admission-chain.md`、`docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md`、`docs/plans/topic-manifests/macos-bridge-verification-smoke.md`。

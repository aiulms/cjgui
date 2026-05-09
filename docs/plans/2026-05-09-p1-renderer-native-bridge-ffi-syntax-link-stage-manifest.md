# P1 渲染器 native bridge FFI 语法与链接阶段清单

日期：2026-05-09

状态：manifest stabilization / isolated FFI probe passed

## 文件定位

本清单固定 native bridge FFI syntax / link stage 的 actual write set、isolated probe、runtime owner、endpoint、truth、stop-line 与唯一后续入口。

本 manifest 不批准 public API，不批准 runtime FFI call，不批准 native object，不批准 package link integration，不批准 backend-ready truth。

## 实际写集

- `labs/native_bridge_ffi_probe/README.md`
- `labs/native_bridge_ffi_probe/src/main.cj`
- `labs/native_bridge_ffi_probe/scripts/env.sh`
- `labs/native_bridge_ffi_probe/scripts/build_and_run.sh`
- `runtime/cjgui/src/runtime_renderer_native_bridge_ffi_link.cj`
- `docs/plans/2026-05-09-p1-renderer-native-bridge-runtime-ffi-syntax-link-preflight-decision.md`
- `docs/plans/2026-05-09-p1-internal-renderer-isolated-no-resource-c-abi-ffi-probe-closure-review.md`
- `docs/plans/2026-05-09-p1-internal-renderer-native-bridge-ffi-syntax-link-stage-closure-review.md`
- `docs/plans/2026-05-09-p1-renderer-native-bridge-ffi-syntax-link-stage-next-boundary-decision.md`

## 固定项

- Runtime owner：`runtime/cjgui/src/runtime_renderer_native_bridge_ffi_link.cj`
- Runtime input：`CjguiInternalRendererNoNativeBridgeFfiDeclarationReadiness`
- Canonical endpoint：`CjguiInternalRendererNoNativeBridgeFfiLinkReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererNativeBridgeFfiLinkDraft()`
- Isolated probe：`labs/native_bridge_ffi_probe/scripts/build_and_run.sh`
- FFI syntax evidence：`foreign func` declarations in `labs/native_bridge_ffi_probe/src/main.cj`
- Link evidence：production skeleton object + static lib + direct `cjc -L ... -l ...`
- Runtime package link status：未接入。

## 允许 callable 清单

- `cjgui_native_bridge_surface_version`
- `cjgui_native_bridge_surface_capabilities`
- `cjgui_native_bridge_status_ok`
- `cjgui_native_bridge_no_resource_admission`

## 禁止 callable 清单

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

isolated probe 已证明 no-resource `C ABI` 可以被仓颉 `foreign func` 声明并通过 direct `cjc` link 调用。

runtime/cjgui package link 仍未接入。当前没有 `[ffi.c]`、没有 package config change、没有 runtime FFI call、没有 public API。

## 同形边界刹车

不得把 isolated FFI probe、FFI syntax evidence、direct link evidence、native symbol probe、C ABI callable 或 planning facts 包装成 public API permission、resource callable permission、native object permission、Metal / AppKit permission、backend-ready permission、GPU-submission permission、render permission、renderer-state-write permission、receipt、record 或 publication。

FFI syntax / link 只证明 no-resource interop feasibility，不证明 GUI backend ready。

## 停止线

- no public API。
- no public diagnostics。
- no runtime FFI call。
- no package link integration。
- no `runtime/cjgui/cjpm.toml` modification。
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

`P1 internal Renderer native bridge package link integration preflight decision`

## 下游接续

下游 [native bridge package link integration stage manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-package-link-integration-stage-manifest.md) 与 [manifest 稳定化复核](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-internal-renderer-native-bridge-package-link-integration-stage-manifest-stabilization-closure-review.md) 已完成。该下游只证明 production no-resource native bridge object / static archive 可在 `runtime/cjgui` 语境旁路 direct `cjc` link 调用；它没有修改 `runtime/cjgui/cjpm.toml`，没有把 production `.m` 接入 `cjpm build`，也没有新增 runtime FFI call、native object、native handle、raw pointer、renderer state write 或 public API。

当前唯一后续入口已由下游改为 `P1 internal Renderer native bridge cjpm package link implementation preflight decision`。

下游 [package config link route reconciliation scan](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-package-config-link-route-reconciliation-scan.md) 已完成。该 scan 确认本 stage 的 isolated FFI syntax / link evidence 仍只是 no-resource interop feasibility evidence，不是 actual runtime FFI call owner、public API、resource callable、native object、Metal / AppKit、renderer state write 或 backend-ready truth；当前主线唯一后续入口已转为 `P1 internal Renderer native bridge internal no-resource runtime FFI call owner preflight decision`。

## 设计意图出口自检

- 本轮是否改变主题状态：是，native bridge FFI syntax / link stage 已 manifest stabilization。
- 本轮是否改变 canonical tail / endpoint：是，新增并固定 `CjguiInternalRendererNoNativeBridgeFfiLinkReadiness`。
- 本轮是否改变 owner / truth / stop-line：是，新增 runtime owner 与 isolated probe；truth 只限 syntax / link evidence 与 package link fallback；stop-line 继续禁止 public / native resource / renderer state。
- 本轮是否改变唯一 next opening：是，转为 `P1 internal Renderer native bridge package link integration preflight decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`docs/plans/topic-manifests/renderer-implementation-admission-chain.md`、`docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md`、`docs/plans/topic-manifests/macos-bridge-verification-smoke.md`。

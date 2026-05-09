# P1 渲染器 native bridge no-resource callable runtime 接入阶段 manifest

日期：2026-05-09

状态：manifest stabilization / planning owner + symbol probe

## 文件定位

本 manifest 固定 no-resource callable runtime integration stage 的 actual write set、runtime owner、symbol probe、truth、stop-line 与后续入口。

本 manifest 不批准真实 runtime FFI declaration，不批准 runtime FFI call，不批准 public API，不批准 native object、native handle、raw pointer、Metal / AppKit、renderer state write 或 backend-ready truth。

## 固定项

- Runtime owner：`runtime/cjgui/src/runtime_renderer_native_bridge_ffi_declaration.cj`
- Runtime input：`CjguiInternalRendererNoCallableCAbiReadiness`
- Canonical endpoint：`CjguiInternalRendererNoNativeBridgeFfiDeclarationReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererNativeBridgeFfiDeclarationDraft()`
- Symbol probe：`runtime/cjgui/native/scripts/verify_native_bridge_no_resource_symbols.sh`
- Current truth：native bridge FFI declaration planning intent / internal-only callable declaration policy / no-resource callable allowlist / link separation fallback policy / no-public-surface policy / no-actual-FFI-declaration readiness facts

## 允许 callable 清单

- `cjgui_native_bridge_surface_version`
- `cjgui_native_bridge_surface_capabilities`
- `cjgui_native_bridge_status_ok`
- `cjgui_native_bridge_no_resource_admission`

本阶段只验证这些符号存在，不从仓颉 runtime 调用它们。

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

## FFI 与 link 状态

当前没有真实 FFI declaration。

当前没有 runtime FFI call。

当前没有 `runtime/cjgui/cjpm.toml` modification，也没有 `[ffi.c]` / production native source wiring。

当前 production `.m` 仍只由 isolated probe 编译，不参与 `cjpm build` package link。

## 同形边界刹车

不得把 no-resource C ABI、runtime declaration planning、symbol probe、build boundary 或 internal value facts 包装成 public API permission、native object permission、Metal / AppKit permission、backend-ready permission、GPU-submission permission、render permission、renderer-state-write permission、receipt、record 或 publication。

No-resource callable 只能证明 side-effect-free native surface 与内部验证链路，不证明 GUI backend ready。

## 停止线

- no public API。
- no public diagnostics。
- no actual runtime FFI declaration。
- no runtime FFI call。
- no `runtime/cjgui/cjpm.toml` modification。
- no package / build config modification。
- no production native source package link。
- no native handle / raw pointer。
- no native pointer return。
- no AppKit / Metal object creation。
- no Cocoa / Metal / QuartzCore import in production bridge。
- no retain / release / destroy。
- no drawable / command buffer / `commit` / `present`。
- no GPU submission。
- no render execution。
- no renderer state write。
- no `runtime_state.cj` modification。
- no smoke native edits。
- no module-level mutable runtime state。
- no backend-ready truth。

## 证据链

- [runtime FFI declaration stage preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-runtime-ffi-declaration-stage-preflight-decision.md)
- [runtime FFI declaration stage closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-internal-renderer-native-bridge-runtime-ffi-declaration-stage-closure-review.md)
- [stage next-boundary decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-no-resource-callable-runtime-integration-stage-next-boundary-decision.md)
- [callable C ABI first implementation manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-callable-c-abi-first-implementation-manifest.md)
- [callable C ABI planning manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-callable-c-abi-planning-manifest.md)
- [cjpm integration first implementation manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-cjpm-integration-first-implementation-manifest.md)

## 下游 FFI 语法与链接阶段封账

下游 [native bridge FFI syntax / link stage manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-ffi-syntax-link-stage-manifest.md) 与 [manifest closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-internal-renderer-native-bridge-ffi-syntax-link-stage-manifest-stabilization-closure-review.md) 已完成。该 downstream 使用本 manifest 固定的 `CjguiInternalRendererNoNativeBridgeFfiDeclarationReadiness` / `cjguiInternalExecuteDefaultRendererNativeBridgeFfiDeclarationDraft()` 作为 runtime input，并新增 `CjguiInternalRendererNoNativeBridgeFfiLinkReadiness` / `cjguiInternalExecuteDefaultRendererNativeBridgeFfiLinkDraft()` 记录 isolated `foreign func` syntax / direct `cjc` link evidence 与 runtime package link fallback。

该 downstream 不把本 manifest 的 declaration planning facts、symbol probe 或 no-resource callable allowlist 升格为 runtime package link permission、runtime FFI call permission、native bridge implementation permission、native object permission、native handle permission、raw pointer permission、Metal / AppKit permission、backend-ready permission、GPU submission、render、renderer state write、public diagnostics 或 public API permission。

## 唯一后续入口

`P1 internal Renderer native bridge package link integration preflight decision`

## 设计意图出口自检

- 本轮是否改变主题状态：是，runtime integration stage 已 manifest stabilization。
- 本轮是否改变 canonical tail / endpoint：是，新增 `CjguiInternalRendererNoNativeBridgeFfiDeclarationReadiness`。
- 本轮是否改变 owner / truth / stop-line：是，新增 runtime owner 与 symbol probe；truth 仅限 planning / allowlist / link separation facts；stop-line 继续禁止真实 FFI 与 public / native resource。
- 本轮是否改变唯一 next opening：是，本阶段原转为 `P1 internal Renderer native bridge runtime FFI syntax / link preflight decision`；下游 FFI syntax / link stage 已接续，当前唯一入口为 `P1 internal Renderer native bridge package link integration preflight decision`。
- 是否同步 topic manifest：是。
- 已同步的 topic manifest：`docs/plans/topic-manifests/renderer-implementation-admission-chain.md`、`docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md`、`docs/plans/topic-manifests/macos-bridge-verification-smoke.md`。

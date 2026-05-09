# P1 渲染器 production native bridge skeleton 写集 manifest

日期：2026-05-09

状态：manifest stabilization / no callable C ABI

## 文件定位

本 manifest 固定 production native bridge skeleton 写集的 allowed files、forbidden files、current truth 与 stop-line。

本 manifest 不是 runtime owner manifest，不新增 Cangjie runtime endpoint，不修改 `.cj`，不接 FFI，不修改 build config，不修改 smoke lab，不实现 callable C ABI，不创建 native object、native handle、Metal / AppKit resource、backend ready truth、GPU work、renderer state write 或 public API。

## 固定项

- production skeleton header：`runtime/cjgui/native/cjgui_native_bridge.h`
- production skeleton implementation：`runtime/cjgui/native/cjgui_native_bridge.m`
- build integration：无；本轮不修改 `runtime/cjgui/cjpm.toml` 或 package config。
- runtime FFI declaration：无；本轮不新增 runtime `.cj` FFI declaration。
- callable C ABI：无；本轮不声明或实现 runtime callable C ABI function。
- current truth：production native bridge skeleton write-set contract / internal status taxonomy skeleton / no-build-integration / no-callable-C-ABI facts

## 当前事实

`cjgui_native_bridge.h` 只承载 internal skeleton status / category enum 与 contract comments。它不声明 callable function，不暴露 public CJGUI API，不包含 native pointer / raw handle shape。

`cjgui_native_bridge.m` 只 import 自身 header，并保留 contract comments。它不导入 Cocoa、Metal、QuartzCore，不创建 Objective-C object，不保存 global mutable state，不实现可被 runtime 调用的 C ABI。

本轮没有修改 `labs/macos_bridge_smoke/native/*`。smoke header / implementation 中的 callable shape、global mutable last error、窗口与 Metal 操作仍停留在 lab evidence，不进入 production skeleton truth。

本轮未让 production `.m` 参与 `cjpm build`，也未修改任何 build system 配置。这是 manifest 固定的当前边界；后续如需集成 build，必须先进入 build system integration preflight。

## 允许写集

- `runtime/cjgui/native/cjgui_native_bridge.h`
- `runtime/cjgui/native/cjgui_native_bridge.m`
- 本 manifest 与配套 closure / next-boundary / README / tracker / topic manifest 同步。

## 禁止写集

- `labs/macos_bridge_smoke/native/*`
- `runtime/cjgui/src/runtime_state.cj`
- `runtime/cjgui/cjpm.toml`
- package / build config
- runtime `.cj` FFI declaration
- public API files
- unrelated renderer owners
- production native files outside `runtime/cjgui/native/cjgui_native_bridge.h` and `runtime/cjgui/native/cjgui_native_bridge.m`

## 同形边界刹车

本 manifest 只做 skeleton 写集封账，不新增 tail wrapper，不新增 runtime readiness endpoint，不新增 receipt、record、publication、permission 字段或 public API。

不得把 skeleton `.h` / `.m` 包装成 native bridge implementation permission、C ABI callable permission、FFI permission、native-handle permission、Metal / AppKit permission、backend-ready permission、GPU-submission permission、render permission、state-write permission、public diagnostics permission 或 public API permission。

## 停止线

- no callable C ABI implementation。
- no FFI declaration。
- no runtime `.cj` FFI declaration。
- no build config / package config modification。
- no native handle / raw pointer。
- no raw pointer return。
- no native object creation。
- no `NSWindow` / `NSView` / `CAMetalLayer` creation。
- no `MTLDevice` / `MTLCommandQueue` creation。
- no drawable / `nextDrawable`。
- no command buffer / `commandBuffer`。
- no `commit` / `present`。
- no retain / release / destroy。
- no GPU submission。
- no render execution。
- no renderer state write。
- no `runtime_state.cj` modification。
- no public diagnostics。
- no public API。
- no smoke lab native modification。

## 证据链

- [native bridge first production write-set preflight decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-first-production-write-set-preflight-decision.md)
- [production native bridge skeleton write-set closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-internal-renderer-production-native-bridge-skeleton-write-set-contract-closure-review.md)
- [production native bridge skeleton write-set next-boundary decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-production-native-bridge-skeleton-write-set-next-boundary-decision.md)
- [native bridge build system integration preflight decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-build-system-integration-preflight-decision.md)
- [native bridge build integration planning manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-build-integration-planning-manifest.md)
- [native bridge build probe manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-build-probe-manifest.md)
- [native bridge C ABI surface contract manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-c-abi-surface-contract-manifest.md)
- [native handle token ownership manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-handle-token-ownership-manifest.md)
- [native bridge teardown implementation planning manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-teardown-implementation-planning-manifest.md)
- [macOS bridge verification smoke topic manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/macos-bridge-verification-smoke.md)

## 下游后续入口

`P1 internal Renderer native bridge build probe manifest stabilization completed；native bridge build system integration implementation manifest stabilization completed；native bridge cjpm integration first implementation manifest stabilization completed；native bridge callable C ABI first implementation manifest stabilization completed；下游当前入口是 P1 internal Renderer native bridge runtime FFI syntax / link preflight decision`

## 下游 callable C ABI 第一实现封账

下游 [native bridge callable C ABI first implementation manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-callable-c-abi-first-implementation-manifest.md) 与 [manifest closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-internal-renderer-native-bridge-callable-c-abi-first-implementation-manifest-stabilization-closure-review.md) 已完成。该 downstream 修改 production skeleton `.h` / `.m`，但只新增 no-resource callable allowlist，不接 FFI，不新增 runtime `.cj` FFI declaration，不修改 build config，不创建 native object、native handle、raw pointer，不导入 Cocoa / Metal / QuartzCore，不搬运 smoke implementation。

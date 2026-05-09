# P1 渲染器 native bridge cjpm 接入第一实现 manifest

日期：2026-05-09

状态：manifest stabilization / build glue only

## 文件定位

本 manifest 固定 native bridge `cjpm` integration first implementation 的 actual write set、build/probe entry、macOS-only gating、non-macOS behavior、stop-line 与下游入口。

本 manifest 不批准 callable C ABI / FFI，不批准 runtime `.cj` FFI declaration，不批准 native object creation，不批准 public API，不批准把 production `.m` 接入 `cjpm.toml`。

## 固定项

- Actual write set：`runtime/cjgui/native/scripts/verify_native_bridge_cjpm_integration_boundary.sh`
- 上游 runtime endpoint：`CjguiInternalRendererNoNativeBridgeBuildSystemImplementationReadiness` / `cjguiInternalExecuteDefaultRendererNativeBridgeBuildSystemAdmissionDraft()`
- Build entry：`runtime/cjgui/native/scripts/verify_native_bridge_cjpm_integration_boundary.sh`
- Existing skeleton probe：`runtime/cjgui/native/scripts/verify_native_bridge_skeleton_compile.sh`
- Package build command：`cjpm build --target-dir <tmp> --skip-script`
- Current truth：native bridge `cjpm` integration boundary build glue / separated package build and skeleton compile / no-`cjpm.toml` modification / no-callable-C-ABI / no-FFI facts

## 当前事实

`verify_native_bridge_cjpm_integration_boundary.sh` 是本轮唯一新增 build glue。它只把 `cjpm build --skip-script` 与 production skeleton isolated compile 串成一个可重复入口，并在运行前扫描 forbidden wiring / forbidden native tokens。

该脚本不修改 source，不修改 package config，不链接 framework，不执行 app，不调用 C ABI，不接 runtime FFI，不读取或修改 smoke native 文件。

该脚本需要 `cjpm` 在 `PATH` 中；若 bare `cjpm` 不存在，调用者应先执行 `source /Users/jiangxuanyang/cangjie-toolchains/cangjie/envsetup.sh`。该行为与本仓库现有 build verification 方式保持一致。

## macOS-only 与 non-macOS 行为

`cjpm build --skip-script` 仍是普通 Cangjie package build，不依赖 Objective-C skeleton。

production skeleton compile 仍由 existing isolated probe 执行，并继承其 macOS-only guard：非 macOS 环境必须清晰失败，不得伪装为 runtime bridge ready。

本轮没有新增 non-macOS package integration fallback，因为 production `.m` 尚未纳入 `cjpm` build。

## 未改变项

本轮不修改：

- `runtime/cjgui/cjpm.toml`
- `runtime/cjgui/native/cjgui_native_bridge.h`
- `runtime/cjgui/native/cjgui_native_bridge.m`
- `labs/macos_bridge_smoke/native/*`
- runtime `.cj` FFI declaration
- public API files
- `runtime/cjgui/src/runtime_state.cj`

## 同形边界刹车

本 manifest 只做 build glue 封账，不新增 runtime tail wrapper，不新增 receipt、record、publication、permission 字段或 public API。

不得把 `cjpm` integration boundary script、build probe、skeleton compile、C ABI surface contract、build system admission 或 smoke evidence 包装成 callable C ABI permission、FFI permission、native bridge implementation permission、Metal / AppKit permission、backend-ready permission、public API permission、receipt、record 或 publication。

## 停止线

- no callable C ABI implementation。
- no FFI declaration。
- no runtime `.cj` FFI declaration。
- no `runtime/cjgui/cjpm.toml` modification。
- no production `.m` inclusion in `cjpm build`。
- no native handle / raw pointer。
- no raw pointer return。
- no AppKit / Metal object creation。
- no Cocoa / Metal / QuartzCore import in production skeleton。
- no retain / release / destroy。
- no GPU submission。
- no render execution。
- no renderer state write。
- no `runtime_state.cj` modification。
- no public diagnostics / API。
- no smoke native modification。

## 证据链

- [cjpm integration first implementation preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-cjpm-integration-first-implementation-preflight-decision.md)
- [cjpm integration first implementation closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-internal-renderer-native-bridge-cjpm-integration-first-implementation-closure-review.md)
- [cjpm integration first implementation next-boundary](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-cjpm-integration-first-implementation-next-boundary-decision.md)
- [native bridge build system integration implementation manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-build-system-integration-implementation-manifest.md)
- [native bridge build probe manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-build-probe-manifest.md)
- [production native bridge skeleton write-set manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-production-native-bridge-skeleton-write-set-manifest.md)

## 下游后续入口

`P1 internal Renderer native bridge runtime FFI syntax / link preflight decision`

## 下游 callable C ABI planning 封账

下游 [native bridge callable C ABI planning manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-callable-c-abi-planning-manifest.md) 与 [manifest closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-internal-renderer-native-bridge-callable-c-abi-planning-manifest-stabilization-closure-review.md) 已完成。该 downstream 使用本 manifest 的 build glue、skeleton compile 与 no-callable-C-ABI facts 作为 planning evidence，只新增 runtime-local callable planning owner。

该 downstream 不把 `verify_native_bridge_cjpm_integration_boundary.sh`、skeleton compile、build system admission 或本 manifest 升格为 callable C ABI implementation permission、FFI permission、runtime `.cj` FFI declaration permission、native bridge implementation permission、native object permission、native handle permission、raw pointer permission、Metal / AppKit permission、backend-ready permission、GPU submission、render、renderer state write、public diagnostics 或 public API permission。

## 下游 callable C ABI 第一实现封账

下游 [native bridge callable C ABI first implementation manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-callable-c-abi-first-implementation-manifest.md) 与 [manifest closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-internal-renderer-native-bridge-callable-c-abi-first-implementation-manifest-stabilization-closure-review.md) 已完成。该 downstream 继续使用本 manifest 的 build boundary 与 probe separation evidence，只新增 no-resource callable `C ABI`；`verify_native_bridge_cjpm_integration_boundary.sh` 仍证明 `cjpm build` 与 production native isolated compile 分离。

该 downstream 不把 `cjpm` integration、probe script 或 no-resource callable surface 升格为 runtime FFI permission、runtime `.cj` FFI declaration permission、native object permission、native handle permission、raw pointer permission、Metal / AppKit permission、backend-ready permission、GPU submission、render、renderer state write、public diagnostics 或 public API permission。

## 下游 runtime 接入阶段封账

下游 [native bridge no-resource callable runtime integration stage manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-no-resource-callable-runtime-integration-stage-manifest.md) 与 [manifest closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-internal-renderer-native-bridge-no-resource-callable-runtime-integration-stage-manifest-stabilization-closure-review.md) 已完成。该 downstream 继续使用本 manifest 的 build boundary 与 package-link separation evidence，只新增 planning owner 与 no-resource symbol probe；`cjpm build` 与 production native isolated compile 仍分离。

该 downstream 不把 `cjpm` integration、symbol probe、no-resource callable surface 或 planning owner 升格为真实 runtime FFI permission、runtime FFI call permission、production `.m` package integration permission、native object permission、native handle permission、raw pointer permission、Metal / AppKit permission、backend-ready permission、GPU submission、render、renderer state write、public diagnostics 或 public API permission。

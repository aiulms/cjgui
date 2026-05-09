# P1 渲染器 native bridge callable C ABI 第一实现 manifest

日期：2026-05-09

状态：manifest stabilization / no-resource callable only

## 文件定位

本 manifest 固定 production native bridge 第一批 no-resource callable `C ABI` 的 allowed callable list、forbidden callable list、probe scripts、truth 与 stop-line。

本 manifest 不新增 runtime `.cj` FFI declaration，不修改 build config，不接仓颉 FFI，不创建 native object，不创建 native handle / raw pointer，不创建 AppKit / Metal resource，不写 renderer state，不扩 public runtime API。

## 固定项

- Header file：`runtime/cjgui/native/cjgui_native_bridge.h`
- Implementation file：`runtime/cjgui/native/cjgui_native_bridge.m`
- Skeleton compile probe：`runtime/cjgui/native/scripts/verify_native_bridge_skeleton_compile.sh`
- Build boundary probe：`runtime/cjgui/native/scripts/verify_native_bridge_cjpm_integration_boundary.sh`
- Runtime FFI declaration：无。
- Build config change：无。
- Current truth：production native no-resource callable C ABI / deterministic integer facts / probe allowlist / no-runtime-FFI facts。

## 允许 callable

仅允许以下 callable：

- `cjgui_native_bridge_surface_version(void)`：返回当前 production native bridge surface version。
- `cjgui_native_bridge_surface_capabilities(void)`：返回 no-resource surface capability bitmask。
- `cjgui_native_bridge_status_ok(void)`：返回 status taxonomy 中的 OK 值。
- `cjgui_native_bridge_no_resource_admission(void)`：返回 no-resource admission 的 OK 值。

这些函数只返回 `uint32_t`，不返回 pointer，不访问 global mutable state，不创建 native object，不导入或调用 AppKit / Metal / QuartzCore，不提交 GPU work，不写 renderer state。

## 暂缓 callable

- main-thread query / classification：暂缓到独立 preflight。
- native handle / token query：暂缓。
- destroy / teardown callable：暂缓。
- resource creation admission callable：暂缓。
- runtime FFI declaration：暂缓。

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

## probe 与构建边界

`verify_native_bridge_skeleton_compile.sh` 现在会：

- 编译 `runtime/cjgui/native/cjgui_native_bridge.m` 到 `/tmp/cjgui-native-bridge-build-probe-*`。
- 扫描 forbidden imports / symbols。
- 扫描 callable allowlist。
- 使用 `nm` 检查 object exported `cjgui_*` symbols 仍在 allowlist 内。

`verify_native_bridge_cjpm_integration_boundary.sh` 现在会：

- 确认 `runtime/cjgui/cjpm.toml` 仍未接入 production native skeleton。
- 运行 `cjpm build --skip-script`。
- 运行 isolated production skeleton compile probe。
- 继续证明 `cjpm` package build 与 production skeleton compile 分离。

## 同形边界刹车

不得把 no-resource callable `C ABI` 包装成 FFI permission、runtime callable permission、native bridge implementation permission、native object permission、native handle permission、Metal / AppKit permission、backend-ready permission、GPU-submission permission、render permission、renderer-state-write permission、public API permission、receipt、record 或 publication。

First callable 只证明 production native surface 有 side-effect-free C functions，不证明 runtime bridge integrated。

## 停止线

- no FFI。
- no runtime `.cj` FFI declaration。
- no `runtime/cjgui/cjpm.toml` modification。
- no package / build config modification。
- no native handle / raw pointer。
- no native pointer return。
- no `NSWindow` / `NSView` / `CAMetalLayer`。
- no `MTLDevice` / `MTLCommandQueue`。
- no Cocoa / Metal / QuartzCore import in production skeleton。
- no retain / release / destroy。
- no drawable / `nextDrawable`。
- no command buffer / `commandBuffer`。
- no `commit` / `present`。
- no GPU submission。
- no render execution。
- no renderer state write。
- no `runtime_state.cj` modification。
- no public runtime API / diagnostics。
- no smoke native edits。
- no module-level mutable runtime state。

## 证据链

- [callable C ABI first implementation preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-callable-c-abi-first-implementation-preflight-decision.md)
- [callable C ABI first implementation closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-internal-renderer-native-bridge-callable-c-abi-first-implementation-closure-review.md)
- [callable C ABI first implementation next-boundary](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-callable-c-abi-first-implementation-next-boundary-decision.md)
- [callable C ABI planning manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-callable-c-abi-planning-manifest.md)
- [production native bridge skeleton write-set manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-production-native-bridge-skeleton-write-set-manifest.md)
- [native bridge cjpm integration first implementation manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-cjpm-integration-first-implementation-manifest.md)
- [native bridge C ABI surface contract manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-c-abi-surface-contract-manifest.md)
- [native bridge no-resource callable runtime integration stage manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-no-resource-callable-runtime-integration-stage-manifest.md)

## 下游 runtime 接入阶段封账

下游 [native bridge no-resource callable runtime integration stage manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-no-resource-callable-runtime-integration-stage-manifest.md) 与 [manifest closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-internal-renderer-native-bridge-no-resource-callable-runtime-integration-stage-manifest-stabilization-closure-review.md) 已完成。该 downstream 使用本 manifest 固定的四个 no-resource callable 作为 symbol probe allowlist，并新增 `CjguiInternalRendererNoNativeBridgeFfiDeclarationReadiness` / `cjguiInternalExecuteDefaultRendererNativeBridgeFfiDeclarationDraft()` 记录 FFI declaration planning facts。

该 downstream 不把本 manifest 的 no-resource callable surface 升格为真实 FFI declaration permission、runtime FFI call permission、native bridge implementation permission、native object permission、native handle permission、raw pointer permission、Metal / AppKit permission、backend-ready permission、GPU submission、render、renderer state write、public diagnostics 或 public API permission。

下游 [native bridge FFI syntax / link stage manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-ffi-syntax-link-stage-manifest.md) 已完成，isolated probe 证明本 manifest 固定的四个 no-resource callable 可由仓颉 `foreign func` 声明并通过 direct `cjc` link 调用。该 downstream 仍不表示 runtime package link 已接入，不表示 runtime FFI call permission，不表示 native object、Metal / AppKit、backend-ready truth、renderer state write、public diagnostics 或 public API permission。

## 唯一后续入口

`P1 internal Renderer native bridge package link integration preflight decision`

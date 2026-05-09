# P1 渲染器 native bridge 构建 probe manifest

日期：2026-05-09

状态：manifest stabilization / isolated build probe / no runtime truth

## 文件定位

本 manifest 固定 isolated native bridge build probe 的脚本路径、probe scope、临时输出策略、禁止接入范围与停止线。

本 manifest 不改变 runtime endpoint，不新增 runtime owner，不修改 build config，不修改 production native skeleton contract，不接入 `cjpm`，不实现 callable C ABI / FFI。

## 固定项

- Probe script：`runtime/cjgui/native/scripts/verify_native_bridge_skeleton_compile.sh`
- Probe source：`runtime/cjgui/native/cjgui_native_bridge.m`
- Temporary output policy：`/tmp/cjgui-native-bridge-build-probe-*`
- 上游 planning endpoint：`CjguiInternalRendererNoNativeBridgeBuildIntegrationReadiness` / `cjguiInternalExecuteDefaultRendererNativeBridgeBuildIntegrationDraft()`
- Current truth：isolated native bridge skeleton compile feasibility evidence / no-`cjpm`-integration evidence / no-callable-C-ABI evidence / no-runtime-bridge-readiness evidence

## 当前事实

probe 只验证 production skeleton `.m` 可被本机 Objective-C 工具链独立编译成临时对象文件。

probe 可以读取 `SDKROOT`、`xcrun` 与 `clang`，但不得修改项目配置。缺少 `clang`、`xcrun` 或 macOS SDK 时，probe 必须 fail with clear diagnostic。

probe 不链接 AppKit / Metal / QuartzCore，因为 skeleton `.m` 不 import / use frameworks。

probe 不执行 app，不调用 C ABI，不接仓颉 FFI，不读取或修改 smoke native 文件，不写 renderer state，不创建 native object、native handle、raw pointer 或 raw pointer return。

`runtime/cjgui/native/cjgui_native_bridge.m` 仍不参与 `cjpm build`，这是当前预期边界。probe 成功不能解释为 runtime bridge integrated、C ABI callable、FFI wired、backend-ready truth、renderer state write permission 或 public API permission。

## 同形边界刹车

本 manifest 只做 build probe 封账，不新增 runtime tail wrapper，不新增 receipt、record、publication、permission 字段或 public API。

不得把 build probe、skeleton compile、C ABI surface contract、build integration planning 或 smoke evidence 包装成 `cjpm` integration permission、callable C ABI permission、FFI permission、native bridge implementation permission、Metal / AppKit permission、backend-ready permission、GPU-submission permission、render permission、renderer-state-write permission、public diagnostics permission 或 public API permission。

## 停止线

- no `runtime/cjgui/cjpm.toml` modification。
- no package config modification。
- no production `.m` `cjpm` integration。
- no production skeleton contract modification。
- no smoke native modification。
- no callable C ABI implementation。
- no FFI declaration。
- no runtime `.cj` FFI declaration。
- no native handle / raw pointer。
- no raw pointer return。
- no AppKit / Metal object creation。
- no retain / release / destroy。
- no GPU submission。
- no render execution。
- no renderer state write。
- no `runtime_state.cj` modification。
- no public diagnostics / API。

## 证据链

- [native bridge build probe preflight decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-build-probe-preflight-decision.md)
- [native bridge build probe closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-internal-renderer-native-bridge-build-probe-closure-review.md)
- [native bridge build probe next-boundary decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-build-probe-next-boundary-decision.md)
- [native bridge build integration planning manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-build-integration-planning-manifest.md)
- [production native bridge skeleton write-set manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-production-native-bridge-skeleton-write-set-manifest.md)
- [macOS bridge verification smoke topic manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/macos-bridge-verification-smoke.md)

## 下游后续入口

`P1 internal Renderer native bridge build system integration implementation manifest stabilization completed；native bridge cjpm integration first implementation manifest stabilization completed；native bridge callable C ABI first implementation manifest stabilization completed；native bridge no-resource callable runtime integration stage manifest stabilization completed；下游当前入口是 P1 internal Renderer native bridge runtime FFI syntax / link preflight decision`

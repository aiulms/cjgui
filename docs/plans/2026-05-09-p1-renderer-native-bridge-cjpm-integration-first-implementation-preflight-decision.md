# P1 渲染器 native bridge cjpm 接入第一实现预检

日期：2026-05-09

状态：preflight decision / build glue only

## 文件定位

本预检判断 native bridge build system admission endpoint 封账后，是否可以打开 `cjpm` integration first implementation runway。

本轮不把 production `.m` 接入 `cjpm.toml`，不实现 callable C ABI / FFI，不新增 runtime `.cj` FFI declaration，不创建 native handle / raw pointer，不创建 AppKit / Metal object，不修改 `runtime_state.cj`，不修改 smoke native 文件，也不扩 public API。

## 读取依据

- [DESIGN_INTENT_INDEX.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/DESIGN_INTENT_INDEX.md)
- [renderer implementation admission chain](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/renderer-implementation-admission-chain.md)
- [renderer backend readiness runway](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md)
- [macOS bridge verification smoke topic manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/macos-bridge-verification-smoke.md)
- [设计意图导航出口协议](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-design-intent-navigation-exit-protocol.md)
- [native bridge build system integration implementation manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-build-system-integration-implementation-manifest.md)
- [native bridge build probe manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-build-probe-manifest.md)
- [production native bridge skeleton write-set manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-production-native-bridge-skeleton-write-set-manifest.md)
- `runtime/cjgui/cjpm.toml`
- `runtime/cjgui/native/cjgui_native_bridge.h`
- `runtime/cjgui/native/cjgui_native_bridge.m`
- `runtime/cjgui/native/scripts/verify_native_bridge_skeleton_compile.sh`

## 判断结果

可以打开第一实现 runway，但只能选择更窄的 B：新增 runtime/cjgui 内部 native build script / build probe bridge，不修改 `runtime/cjgui/cjpm.toml`，不把 production `.m` 纳入 `cjpm build`，不新增 build config / package config。

原因如下：

- `cjpm` 文档明确支持 C FFI、`link-option`、`compile-option` 与 `build.cj`，但没有给出稳定的 Objective-C source inclusion 形状。
- 本项目当前验证命令使用 `cjpm build --skip-script`，因此 `build.cj` 不能作为本轮可靠 first implementation 入口。
- production skeleton `.m` 当前不 import Cocoa / Metal / QuartzCore，不声明 callable C ABI function，也没有 runtime FFI declaration；直接接入 `cjpm.toml` 会把 build integration permission 提前解释成 package integration permission。
- isolated probe 已证明 Objective-C skeleton 可独立编译；下一刀应把 `cjpm build --skip-script` 与 skeleton compile 串成可重复 boundary check，而不是修改 package config。

## 候选比较

A 暂缓：修改最小 package / build config。当前 `cjpm.toml` 没有 Objective-C source inclusion 的明确 contract；若直接修改，容易越过 no callable C ABI / no FFI / no native source inclusion stop-line。

B 选择：新增 runtime/cjgui 内部 build probe bridge。该入口只运行 `cjpm build --skip-script` 与既有 production skeleton isolated compile，并扫描禁止项；它不修改 package config，不接 FFI，不创建 native object。

C 拒绝：只写 blocker / follow-up docs。当前已有 isolated probe 与 `cjpm build` 通过证据，足以做更窄的 build glue implementation。

D 拒绝：直接 callable C ABI / FFI implementation。

E 拒绝：直接 AppKit / Metal object creation。

F 拒绝：public API / renderer state write / backend-ready truth。

## 第一实现写集

允许新增：

- `runtime/cjgui/native/scripts/verify_native_bridge_cjpm_integration_boundary.sh`
- 本 preflight、closure、next-boundary、manifest、manifest closure。
- README / tracker / plans README / runtime README / DESIGN_INTENT_INDEX / topic manifest 同步。
- 相关 upstream / downstream 文档指向同步。

禁止修改：

- `runtime/cjgui/cjpm.toml`
- `runtime/cjgui/native/cjgui_native_bridge.h`
- `runtime/cjgui/native/cjgui_native_bridge.m`
- `labs/macos_bridge_smoke/native/*`
- runtime `.cj` FFI declaration
- public API files
- `runtime/cjgui/src/runtime_state.cj`

## 验证策略

第一实现必须证明：

- `cjpm build --skip-script` 对 Cangjie package 仍通过。
- production skeleton `.m` 仍可通过 isolated compile probe。
- 新 build glue script 不把 skeleton `.m` 接入 `cjpm build`，只串联独立验证。
- `runtime/cjgui/cjpm.toml` 未出现 `[ffi.c]`、`compile-option`、`link-option` 或 native skeleton wiring。
- production skeleton 仍不 import Cocoa / Metal / QuartzCore，不实现 callable `cjgui_*` C ABI function，不创建 AppKit / Metal object。
- public declaration allowlist 仍只有 `cjguiExperimentalQueueSubmitShellReady(): Bool`。

## 同形边界刹车

不得把 `cjpm` integration boundary script、build probe、skeleton compile、C ABI surface contract、build system admission 或 smoke evidence 包装成 callable C ABI permission、FFI permission、native bridge implementation permission、Metal / AppKit permission、backend-ready permission、public API permission、receipt、record 或 publication。

Build glue 只证明 skeleton build path 与 package build 可以被同一验证入口重复检查，不证明 runtime bridge ready。

## 设计意图出口自检

- 本轮是否改变主题状态：是。主题从 build system integration implementation manifest 推进到 `cjpm` integration first implementation preflight。
- 本轮是否改变 canonical tail / endpoint：否。最新 runtime endpoint 仍是 `CjguiInternalRendererNoNativeBridgeBuildSystemImplementationReadiness` / `cjguiInternalExecuteDefaultRendererNativeBridgeBuildSystemAdmissionDraft()`。
- 本轮是否改变 owner / truth / stop-line：是。预检批准新增 build glue script truth，但不改变 runtime owner。
- 本轮是否改变唯一 next opening：是，改为 `P1 internal Renderer native bridge cjpm integration first implementation build glue bundle`。
- 是否同步 topic manifest：是。
- 已同步的 topic manifest：`docs/plans/topic-manifests/renderer-implementation-admission-chain.md`、`docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md`、`docs/plans/topic-manifests/macos-bridge-verification-smoke.md`。

## 下游后续入口

`P1 internal Renderer native bridge cjpm integration first implementation build glue bundle`

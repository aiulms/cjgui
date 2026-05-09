# P1 内部渲染器 native bridge cjpm package link implementation 阶段复核

日期：2026-05-09

状态：closure review / script-managed cjpm package link probe passed

## 文件定位

本 closure 记录 native bridge `cjpm` package link implementation stage 的实际写集、GitNexus impact 结果、script-managed `cjpm` package link probe 与边界。

## 实际完成

- 新增 `runtime/cjgui/native/scripts/verify_native_bridge_cjpm_package_link_probe.sh`。
- 新增 `runtime/cjgui/src/runtime_renderer_native_bridge_cjpm_package_link.cj`。
- 未修改 `runtime/cjgui/cjpm.toml`。
- 未把 production `.m` 接入 `runtime/cjgui` 主包 build。
- 未新增 runtime FFI call、public API、resource callable、native object、Metal / AppKit 或 renderer state write。

## 链接证据

新增 probe 在 `/tmp/cjgui-native-bridge-cjpm-package-link-*` 下构建 production no-resource skeleton object 与 static archive，再生成临时仓颉 package。该临时 package 通过 `compile-option` 指定 `--sysroot`，通过 `link-option` 指向 static archive，并由 `cjpm run --skip-script` 调用四个 no-resource callable。

通过的脱水摘要包括：

- `runtime_package_config_modified=false`
- `surface_version_observed=true`
- `capabilities_observed=true`
- `status_ok_observed=true`
- `no_resource_admission_observed=true`
- `no_resource_symbols_linked=true`
- `success=true reason=none`
- `temporary_cjpm_package_linked=true`

## Runtime owner

- Owner：`runtime/cjgui/src/runtime_renderer_native_bridge_cjpm_package_link.cj`
- Runtime input：`CjguiInternalRendererNoNativeBridgePackageLinkReadiness`
- Canonical endpoint：`CjguiInternalRendererNoNativeBridgeCjpmPackageLinkReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererNativeBridgeCjpmPackageLinkDraft()`
- Truth：native bridge `cjpm` package link implementation intent、script-managed `cjpm` package link route、macOS-only gate、runtime package config admission / fallback、no-resource native object link policy、no-native-bridge-cjpm-package-link readiness facts。

## GitNexus 影响记录

编辑 runtime owner 前已对上游入口执行 impact：

- `CjguiInternalRendererNoNativeBridgePackageLinkReadiness`：GitNexus 返回 `UNKNOWN / not found`，`impactedCount=0`。
- `cjguiInternalExecuteDefaultRendererNativeBridgePackageLinkDraft`：GitNexus 返回 `UNKNOWN / not found`，`impactedCount=0`。

该结果按近期新增 owner 尚未索引处理。未出现 HIGH / CRITICAL 阻塞，后续用源码、probe、`cjpm build` 与 forbidden scan 兜底。

## 边界保持

- 未新增 public API / diagnostics。
- 未新增 runtime FFI call。
- 未修改 `runtime/cjgui/cjpm.toml`。
- 未修改 package / build config。
- 未修改 production no-resource callable behavior。
- 未修改 smoke native files。
- 未新增 resource callable。
- 未创建 native object、native handle、raw pointer。
- 未返回 native pointer。
- 未导入 Cocoa / Metal / QuartzCore 到 production bridge。
- 未提交 GPU work、未执行 render、未写 renderer state。
- 未修改 `runtime/cjgui/src/runtime_state.cj`。
- 未创建 backend-ready truth。

## 同形边界刹车

不得把本 closure、script-managed `cjpm` package link probe、owner endpoint、direct `cjc` evidence、temporary package success 或 no-resource callable facts 包装成 runtime FFI call permission、public API permission、resource callable permission、native object permission、Metal / AppKit permission、backend-ready permission、receipt、record 或 publication。

## 设计意图出口自检

- 本轮是否改变主题状态：是，native bridge `cjpm` package link implementation stage 已完成 script-managed route。
- 本轮是否改变 canonical tail / endpoint：是，新增 `CjguiInternalRendererNoNativeBridgeCjpmPackageLinkReadiness`。
- 本轮是否改变 owner / truth / stop-line：是，新增 owner；truth 仅限 script-managed `cjpm` package link evidence 与 package config fallback；stop-line 继续禁止 runtime FFI call、public API、resource callable、native object、Metal / AppKit 与 backend-ready truth。
- 本轮是否改变唯一 next opening：是，转为 `P1 internal Renderer native bridge runtime internal FFI declaration first implementation bundle`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`docs/plans/topic-manifests/renderer-implementation-admission-chain.md`、`docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md`、`docs/plans/topic-manifests/macos-bridge-verification-smoke.md`。

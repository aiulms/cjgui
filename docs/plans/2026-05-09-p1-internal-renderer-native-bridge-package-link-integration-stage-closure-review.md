# P1 内部渲染器 native bridge package link integration 阶段复核

日期：2026-05-09

状态：closure review / package-adjacent probe passed

## 文件定位

本 closure 记录 package link integration stage 的实际写集、GitNexus 影响分析、package-adjacent probe 结果与边界。

本 closure 不表示 runtime package link 已接入，不表示 runtime FFI call 可用，不表示 backend ready。

## 实际写集

- `runtime/cjgui/native/scripts/verify_native_bridge_package_link_probe.sh`
- `runtime/cjgui/src/runtime_renderer_native_bridge_package_link.cj`
- `docs/plans/2026-05-09-p1-renderer-native-bridge-package-link-integration-preflight-decision.md`

## 旁路链接探针

新增脚本 [verify_native_bridge_package_link_probe.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_native_bridge_package_link_probe.sh) 在 `runtime/cjgui` 语境中执行以下动作：

- 确认 `runtime/cjgui/cjpm.toml` 未声明 `[ffi.c]`，未写入 `cjgui_native_bridge`、`link-option` 或 `compile-option`。
- 编译 `runtime/cjgui/native/cjgui_native_bridge.m` 为临时 object。
- 生成临时 static archive。
- 生成临时仓颉 `foreign func` caller。
- 使用 direct `cjc -L ... -l ...` 链接 no-resource callable。
- 输出脱水 summary，并确认 `runtime_package_config_modified=false`。

本脚本不修改 source，不修改 build config，不执行 app，不调用 resource callable，不创建 native object。

## 运行时 owner

新增 [runtime_renderer_native_bridge_package_link.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_native_bridge_package_link.cj)。

- Runtime input：`CjguiInternalRendererNoNativeBridgeFfiLinkReadiness`
- Canonical endpoint：`CjguiInternalRendererNoNativeBridgePackageLinkReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererNativeBridgePackageLinkDraft()`
- Truth：native bridge package link integration intent、macOS-only package link gate、package-adjacent probe evidence policy、runtime package config admission / fallback policy、no-resource callable link boundary、no-native-bridge-package-link readiness facts。

## GitNexus 影响分析

编辑 runtime symbol 前，已对上游入口运行 impact：

- `CjguiInternalRendererNoNativeBridgeFfiLinkReadiness`：GitNexus 返回 `UNKNOWN / not found`，`impactedCount=0`。
- `cjguiInternalExecuteDefaultRendererNativeBridgeFfiLinkDraft`：GitNexus 返回 `UNKNOWN / not found`，`impactedCount=0`。

解释：该上游 owner 是近期新增文件，当前 GitNexus index 尚未捕获；本轮按项目规则记录 UNKNOWN，并用源码、probe、`cjpm build` 与最终 `detect_changes` 兜底。没有 HIGH / CRITICAL 风险返回。

## 已执行证据

- `runtime/cjgui/native/scripts/verify_native_bridge_package_link_probe.sh` 已通过，输出 `native_object_built=true`、`no_resource_symbols_linked=true`、`runtime_package_config_modified=false`、`success=true reason=none`。
- `cjpm build --target-dir /tmp/cjgui-renderer-native-bridge-package-link-stage-target --skip-script` 已通过，只有既有 unused warnings。

最终统一验证仍在 manifest stabilization 后执行。

## 边界保持

- 未修改 `runtime/cjgui/cjpm.toml`。
- 未修改 package / build config。
- 未接入 production `.m` 到 `cjpm build`。
- 未新增 runtime FFI call。
- 未新增 public API / diagnostics。
- 未调用 resource callable。
- 未创建 native object、native handle、raw pointer。
- 未返回 native pointer。
- 未导入 Cocoa / Metal / QuartzCore 到 production bridge。
- 未修改 smoke native files。
- 未修改 `runtime/cjgui/src/runtime_state.cj`。
- 未写 renderer state。
- 未创建 backend-ready truth。

## 同形边界刹车

不得把 package-adjacent probe success、owner endpoint、direct `cjc` link evidence 或 no-resource callable facts 包装成 `cjpm` package integration permission、runtime FFI call permission、native object permission、Metal / AppKit permission、backend-ready permission、public API permission、receipt、record 或 publication。

## 设计意图出口自检

- 本轮是否改变主题状态：是，native bridge package link integration stage 已完成 package-adjacent probe 与 value boundary。
- 本轮是否改变 canonical tail / endpoint：是，新增 `CjguiInternalRendererNoNativeBridgePackageLinkReadiness`。
- 本轮是否改变 owner / truth / stop-line：是，新增 package link planning owner；truth 仅限 package-adjacent link route evidence 与 package config fallback；stop-line 继续禁止 runtime FFI call、public API 与 native resource。
- 本轮是否改变唯一 next opening：是，后续将由 next-boundary decision 固定。
- 是否同步 topic manifest：是，本阶段 manifest stabilization 后统一同步。
- 已同步哪些 topic manifest：将在 stage manifest stabilization 后同步 `docs/plans/topic-manifests/renderer-implementation-admission-chain.md`、`docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md`、`docs/plans/topic-manifests/macos-bridge-verification-smoke.md`。

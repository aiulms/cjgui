# P1 渲染器 native bridge runtime FFI declaration 阶段收口复核

日期：2026-05-09

状态：closure review / internal value boundary / no actual FFI

## 本轮完成

本阶段新增 [runtime_renderer_native_bridge_ffi_declaration.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_native_bridge_ffi_declaration.cj)，只消费 `CjguiInternalRendererNoCallableCAbiReadiness`，并固定 `CjguiInternalRendererNoNativeBridgeFfiDeclarationReadiness` / `cjguiInternalExecuteDefaultRendererNativeBridgeFfiDeclarationDraft()`。

本阶段未新增真实仓颉 FFI declaration。当前 owner 只记录 internal declaration intent、no-resource callable allowlist、link separation / fallback policy、no-public-surface policy 与 no-native-bridge-FFI-declaration readiness facts。

## 符号探针

新增 [verify_native_bridge_no_resource_symbols.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_native_bridge_no_resource_symbols.sh)。

该 probe 独立编译 `runtime/cjgui/native/cjgui_native_bridge.m` 到 `/tmp/cjgui-native-bridge-no-resource-*`，再用 `nm` 确认以下四个符号存在且没有超出 allowlist：

- `cjgui_native_bridge_surface_version`
- `cjgui_native_bridge_surface_capabilities`
- `cjgui_native_bridge_status_ok`
- `cjgui_native_bridge_no_resource_admission`

该 probe 不修改 source，不修改 build config，不接 `cjpm` / FFI，不执行 callable，不创建 native object。

## 未做事项

- 未写真实 `foreign` / FFI declaration。
- 未新增 runtime FFI call。
- 未新增 runtime `.cj` public API。
- 未修改 `runtime/cjgui/cjpm.toml`。
- 未接入 production `.m` 到 `cjpm`。
- 未修改 production native callable 行为。
- 未修改 smoke native files。
- 未创建 native object、native handle、raw pointer、Metal / AppKit resource。
- 未写 renderer state，未触碰 `runtime_state.cj`。

## GitNexus 记录

GitNexus CLI 本轮因本地 `@ladybugdb/core/lbugjs.node` 缺失无法加载。改用 GitNexus MCP：

- `CjguiInternalRendererNoCallableCAbiReadiness` impact：target not found，risk `UNKNOWN`，impactedCount `0`。
- `cjguiInternalExecuteDefaultRendererCallableCAbiDraft` impact：target not found，risk `UNKNOWN`，impactedCount `0`。
- `detect_changes(scope=unstaged)` 基线：risk `low`，affected_count `0`。

这些 UNKNOWN 来自近期新增 owner 尚未被索引，未出现 HIGH / CRITICAL risk。本轮用源码阅读、`cjpm build`、native probe 与 forbidden scan 兜底。

## 同形边界刹车

`CjguiInternalRendererNoNativeBridgeFfiDeclarationReadiness` 不得被包装成 FFI-ready、runtime-call-ready、native-bridge-ready、native-handle-ready、Metal / AppKit-ready、backend-ready、public diagnostics-ready、receipt、record 或 publication。

## 下游阶段

下游 [native bridge FFI syntax / link stage manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-ffi-syntax-link-stage-manifest.md) 已完成，新增 `CjguiInternalRendererNoNativeBridgeFfiLinkReadiness` / `cjguiInternalExecuteDefaultRendererNativeBridgeFfiLinkDraft()`。该 downstream 只把本阶段 endpoint 作为 runtime input，并记录 isolated `foreign func` / direct `cjc` link evidence；它不授权 runtime package link、runtime FFI call、native object、Metal / AppKit、renderer state write 或 public API。

## 设计意图出口自检

- 本轮是否改变主题状态：是，runtime integration stage 从 callable native surface 推进到 FFI declaration planning value boundary。
- 本轮是否改变 canonical tail / endpoint：是，新增 `CjguiInternalRendererNoNativeBridgeFfiDeclarationReadiness` / `cjguiInternalExecuteDefaultRendererNativeBridgeFfiDeclarationDraft()`。
- 本轮是否改变 owner / truth / stop-line：是，新增 `runtime_renderer_native_bridge_ffi_declaration.cj`；truth 仅限 planning facts；stop-line 继续禁止真实 FFI / public API / native object。
- 本轮是否改变唯一 next opening：是，阶段 next-boundary 将选择 FFI syntax / link preflight。
- 是否同步 topic manifest：是。
- 已同步的 topic manifest：`docs/plans/topic-manifests/renderer-implementation-admission-chain.md`、`docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md`、`docs/plans/topic-manifests/macos-bridge-verification-smoke.md`。

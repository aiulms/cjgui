# P1 内部渲染器 native bridge no-resource FFI call verification 清单稳定化复核

日期：2026-05-09

状态：manifest stabilization closure / stop after manifest

## 封账结论

[no-resource FFI call verification manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-no-resource-ffi-call-verification-manifest.md) 已封账。

本阶段采用 runtime-adjacent probe route，而不是 runtime owner call route。新增 probe 已把四个 no-resource C ABI 的实际调用结果转成脱水 observed facts，同时保持 `runtime/cjgui` 主包不接 native package link、不新增 public surface、不创建 resource。

## 固定事实

- Probe：`runtime/cjgui/native/scripts/verify_native_bridge_no_resource_call_probe.sh`
- Runtime declaration owner：`runtime/cjgui/src/runtime_renderer_native_bridge_runtime_ffi_declaration.cj`
- Current declaration endpoint：`CjguiInternalRendererNoNativeBridgeRuntimeFfiCallReadiness`
- Current declaration default draft：`cjguiInternalExecuteDefaultRendererNativeBridgeRuntimeFfiDeclarationDraft()`
- Actual route：runtime-adjacent probe。
- Runtime owner call：未新增。
- Package config：`runtime/cjgui/cjpm.toml` 未修改。

## 已观察 callable

- `cjgui_native_bridge_surface_version`
- `cjgui_native_bridge_surface_capabilities`
- `cjgui_native_bridge_status_ok`
- `cjgui_native_bridge_no_resource_admission`

四个 callable 只返回 deterministic integer facts；当前 observation 不产生 state write、不发布 public diagnostics、不创建 native object。

## 固定边界

- 未新增 public API。
- 未新增 resource callable。
- 未新增 native object、native handle、raw pointer 或 native pointer return。
- 未导入 Cocoa / Metal / QuartzCore。
- 未修改 smoke native files。
- 未修改 `runtime_state.cj`。
- 未修改 `runtime/cjgui/cjpm.toml`。
- 未发布 backend-ready truth。

## 同形边界刹车

不得把本 manifest、runtime-adjacent probe、observed facts、runtime declaration owner 或 package link probe 包装成 runtime package call support、public API permission、resource callable permission、native object permission、Metal / AppKit permission、backend-ready permission、GPU-submission permission、render permission、renderer-state-write permission、receipt、record 或 publication。

## 后续入口

已由 `P1 internal Renderer native bridge runtime package link call support preflight decision` 接续并封账到 [runtime package link call support manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-runtime-package-link-call-support-manifest.md)。

当前后续入口已转为 `P1 internal Renderer native bridge package config link implementation preflight decision`。下一步应先判断是否、如何把 no-resource native bridge archive 以 macOS-only / non-macOS fallback 接入 `runtime/cjgui` package config；不得直接进入 resource callable、native object、Metal / AppKit、public API 或 backend-ready truth。

## 设计意图出口自检

- 本轮是否改变主题状态：是，no-resource FFI call verification 已 manifest stabilization。
- 本轮是否改变 canonical tail / endpoint：否，本轮没有新增 runtime endpoint；当前 declaration endpoint 不变。
- 本轮是否改变 owner / truth / stop-line：是，新增 runtime-adjacent probe；truth 固定为 observed call facts；stop-line 不变。
- 本轮是否改变唯一 next opening：是，转为 `P1 internal Renderer native bridge runtime package link call support preflight decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`docs/plans/topic-manifests/renderer-implementation-admission-chain.md`、`docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md`、`docs/plans/topic-manifests/macos-bridge-verification-smoke.md`。

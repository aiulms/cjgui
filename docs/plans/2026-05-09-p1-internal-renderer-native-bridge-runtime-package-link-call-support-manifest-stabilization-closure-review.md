# P1 内部渲染器 native bridge runtime package link call support 清单稳定化复核

日期：2026-05-09

状态：manifest stabilization closure / stop after manifest

## 封账结论

[runtime package link call support manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-runtime-package-link-call-support-manifest.md) 已封账。

本阶段采用 internal value boundary route，而不是 runtime owner call route。新增 owner 固定了主包 package call support 的条件、证据来源与阻塞点，同时保持 no-resource C ABI 仍只在 runtime-adjacent probe 中被调用。

## 固定事实

- Owner：`runtime/cjgui/src/runtime_renderer_native_bridge_package_call_support.cj`
- Endpoint：`CjguiInternalRendererNoNativeBridgePackageCallSupportReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererNativeBridgePackageCallSupportDraft()`
- Runtime input：`CjguiInternalRendererNoNativeBridgeRuntimeFfiCallReadiness`
- Actual route：internal value boundary。
- Runtime owner call：未新增。
- Package config：`runtime/cjgui/cjpm.toml` 未修改。
- Package call support：仍 blocked，等待 package config link implementation preflight。

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

不得把本 manifest、package call support owner、runtime-adjacent probe、package link evidence 或 internal FFI declaration owner 包装成 actual runtime FFI call permission、public API permission、resource callable permission、native object permission、Metal / AppKit permission、backend-ready permission、GPU-submission permission、render permission、renderer-state-write permission、receipt、record 或 publication。

## 后续入口

`P1 internal Renderer native bridge package config link implementation preflight decision`

下一步应先判断 `runtime/cjgui` 主包 package config 是否、如何接入 no-resource native bridge archive；不得直接进入 public API、resource callable、native object、Metal / AppKit、renderer state write 或 backend-ready truth。

## 下游接续记录

下游 [package config link implementation stage manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-package-config-link-implementation-stage-manifest.md) 已完成，并将唯一后续入口推进为 `P1 internal Renderer native bridge package config link route reconciliation scan`。该下游仍未修改 `runtime/cjgui/cjpm.toml`，未新增 actual runtime FFI call，也未接入 resource callable、native object、Metal / AppKit、renderer state write 或 public API。

## 设计意图出口自检

- 本轮是否改变主题状态：是，runtime package link call support 已 manifest stabilization。
- 本轮是否改变 canonical tail / endpoint：是，新增并固定 `CjguiInternalRendererNoNativeBridgePackageCallSupportReadiness`。
- 本轮是否改变 owner / truth / stop-line：是，新增 owner；truth 固定为 package call support / blocker facts；stop-line 不变。
- 本轮是否改变唯一 next opening：是，转为 `P1 internal Renderer native bridge package config link implementation preflight decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`docs/plans/topic-manifests/renderer-implementation-admission-chain.md`、`docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md`、`docs/plans/topic-manifests/macos-bridge-verification-smoke.md`。

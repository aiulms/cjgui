# P1 内部渲染器 native bridge package config link implementation 清单稳定化复核

日期：2026-05-09

状态：manifest stabilization closure / stop after manifest

## 封账结论

[package config link implementation stage manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-package-config-link-implementation-stage-manifest.md) 已封账。

本阶段采用 script-managed link route stabilization，而不是 `runtime/cjgui/cjpm.toml` mutation route。新增 owner 固定了主包 package config 仍 deferred、artifact 生成仍由 probe 管理、`--skip-script` 不依赖 native archive 的事实。

## 固定事实

- Owner：`runtime/cjgui/src/runtime_renderer_native_bridge_package_config_link.cj`
- Endpoint：`CjguiInternalRendererNoNativeBridgePackageConfigLinkReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererNativeBridgePackageConfigLinkDraft()`
- Runtime input：`CjguiInternalRendererNoNativeBridgePackageCallSupportReadiness`
- Actual route：script-managed link route stabilization。
- Package config：`runtime/cjgui/cjpm.toml` 未修改。
- Runtime owner call：未新增。

## 固定边界

- 未新增 actual runtime FFI call。
- 未新增 public API。
- 未新增 resource callable。
- 未新增 native object、native handle、raw pointer 或 native pointer return。
- 未导入 Cocoa / Metal / QuartzCore。
- 未修改 smoke native files。
- 未修改 `runtime_state.cj`。
- 未发布 backend-ready truth。

## 同形边界刹车

不得把本 manifest、package config link owner、script-managed route、runtime-adjacent call probe、package link evidence 或 internal FFI declarations 包装成 actual runtime FFI call permission、public API permission、resource callable permission、native object permission、Metal / AppKit permission、backend-ready permission、GPU-submission permission、render permission、renderer-state-write permission、receipt、record 或 publication。

## 后续入口

`P1 internal Renderer native bridge package config link route reconciliation scan`

下一步应先对 package config still-deferred facts 与 script-managed route 是否已经足够做 reconciliation scan；不得直接进入 public API、resource callable、native object、Metal / AppKit、renderer state write 或 backend-ready truth。

## 下游接续

下游 [package config link route reconciliation scan](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-package-config-link-route-reconciliation-scan.md) 已完成。该 scan 确认本 closure 封账的 package config still-deferred facts 与 script-managed route 没有被误读为 `runtime/cjgui/cjpm.toml` integration、actual runtime FFI call、public API、resource callable、native object、Metal / AppKit、renderer state write 或 backend-ready truth。再下游 [no-resource runtime FFI call owner manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-no-resource-runtime-ffi-call-owner-manifest.md) 已新增 internal owner call endpoint，但仍保留本 closure 的 package config deferred stop-line。

## 设计意图出口自检

- 本轮是否改变主题状态：是，package config link implementation stage 已 manifest stabilization。
- 本轮是否改变 canonical tail / endpoint：是，新增并固定 `CjguiInternalRendererNoNativeBridgePackageConfigLinkReadiness`。
- 本轮是否改变 owner / truth / stop-line：是，新增 owner；truth 固定为 package config deferred / script-managed fallback facts；stop-line 不变。
- 本轮是否改变唯一 next opening：是，转为 `P1 internal Renderer native bridge package config link route reconciliation scan`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`docs/plans/topic-manifests/renderer-implementation-admission-chain.md`、`docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md`、`docs/plans/topic-manifests/macos-bridge-verification-smoke.md`。

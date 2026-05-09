# P1 内部渲染器 native bridge cjpm package link implementation 阶段清单稳定化复核

日期：2026-05-09

状态：closure review / manifest stabilization

## 文件定位

本 closure 确认 native bridge `cjpm` package link implementation stage manifest 已封账，并记录同步、边界与设计意图出口自检。

## 封账内容

- Script-managed `cjpm` package link probe 已新增并通过。
- Runtime planning owner 已新增并通过 `cjpm build`。
- Manifest 已固定 actual route、write set、owner、runtime input、canonical endpoint、default draft、allowed callable list、forbidden callable list、package config status 与 stop-line。
- 唯一后续入口已改为 `P1 internal Renderer native bridge runtime internal FFI declaration first implementation bundle`。
- 下游 [runtime internal FFI declaration first implementation manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-runtime-internal-ffi-declaration-first-implementation-manifest.md) 已完成，`CjguiInternalRendererNoNativeBridgeCjpmPackageLinkReadiness` 只作为下游 runtime input；当前唯一后续入口已转为 `P1 internal Renderer native bridge internal no-resource FFI call verification bundle`。

## 关键证据

- `runtime/cjgui/native/scripts/verify_native_bridge_cjpm_package_link_probe.sh` 通过。
- `runtime/cjgui/native/scripts/verify_native_bridge_package_link_probe.sh` 通过。
- `runtime/cjgui/src/runtime_renderer_native_bridge_cjpm_package_link.cj` 通过 `cjpm build --skip-script`。
- `runtime/cjgui/cjpm.toml` 未修改，当前 `runtime/cjgui` package link 仍未直接接入 production `.m`，这是本阶段预期边界。

## 边界保持

- 未新增 public API / diagnostics。
- 未新增 runtime FFI call。
- 未修改 `runtime/cjgui/cjpm.toml`。
- 未修改 runtime package / build config。
- 未修改 production no-resource callable behavior。
- 未修改 smoke native files。
- 未新增 resource callable。
- 未创建 native object、native handle、raw pointer。
- 未返回 native pointer。
- 未导入 Cocoa / Metal / QuartzCore 到 production bridge。
- 未提交 GPU work、未执行 render、未写 renderer state。
- 未修改 `runtime/cjgui/src/runtime_state.cj`。
- 未创建 backend-ready truth。

## 已同步范围

- `README.md`
- `GUI_TASK_TRACKER.md`
- `docs/plans/README.md`
- `runtime/cjgui/README.md`
- `docs/plans/DESIGN_INTENT_INDEX.md`
- `docs/plans/topic-manifests/renderer-implementation-admission-chain.md`
- `docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md`
- `docs/plans/topic-manifests/macos-bridge-verification-smoke.md`
- 上游 package link integration stage manifest 与 manifest closure。

## 同形边界刹车

不得把本 manifest、script-managed `cjpm` package link probe success、runtime planning endpoint、temporary package success、direct `cjc` evidence 或 no-resource callable facts 包装成 runtime FFI call permission、public API permission、resource callable permission、native object permission、Metal / AppKit permission、backend-ready permission、receipt、record 或 publication。

## 设计意图出口自检

- 本轮是否改变主题状态：是，native bridge `cjpm` package link implementation stage 已完成 manifest stabilization。
- 本轮是否改变 canonical tail / endpoint：是，当前 endpoint 固定为 `CjguiInternalRendererNoNativeBridgeCjpmPackageLinkReadiness`。
- 本轮是否改变 owner / truth / stop-line：是，owner 为 `runtime/cjgui/src/runtime_renderer_native_bridge_cjpm_package_link.cj`；truth 仅限 script-managed package link route 与 package config fallback；stop-line 继续禁止 runtime FFI call、public API、native resource、renderer state write 与 backend-ready truth。
- 本轮是否改变唯一 next opening：是，改为 `P1 internal Renderer native bridge runtime internal FFI declaration first implementation bundle`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`docs/plans/topic-manifests/renderer-implementation-admission-chain.md`、`docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md`、`docs/plans/topic-manifests/macos-bridge-verification-smoke.md`。

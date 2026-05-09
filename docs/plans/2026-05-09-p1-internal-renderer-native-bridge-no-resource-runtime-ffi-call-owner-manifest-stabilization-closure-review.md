# P1 内部渲染器 native bridge no-resource runtime FFI call owner 清单稳定化复核

日期：2026-05-09

状态：manifest stabilization closure / stop after manifest

## 封账结论

[no-resource runtime FFI call owner manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-no-resource-runtime-ffi-call-owner-manifest.md) 已封账。

当前 canonical endpoint：

`CjguiInternalRendererNoNativeBridgeNoResourceRuntimeCallReadiness`

当前 default draft：

`cjguiInternalExecuteDefaultRendererNativeBridgeNoResourceRuntimeCallDraft()`

## 固定现实

- Actual internal owner 已存在，并调用四个 no-resource C ABI。
- Actual C ABI execution evidence 仍由 script-managed temporary package probe 提供。
- `runtime/cjgui/cjpm.toml` 未修改。
- Production native `.m` 未正式接入主包 package config。
- No-resource call facts 只在 internal owner 中脱水，不进入 public surface。

## 固定边界

- 未新增 public API / diagnostics。
- 未调用 resource callable。
- 未创建 native object、native handle、raw pointer 或 native pointer return。
- 未导入 Cocoa / Metal / QuartzCore。
- 未调用 retain / release / destroy。
- 未提交 GPU work，未执行 render，未写 renderer state。
- 未修改 `runtime/cjgui/src/runtime_state.cj`。
- 未修改 smoke native files。
- 未创建 backend-ready truth。

## 同形边界刹车

不得把 no-resource runtime call owner、script-managed link route、runtime internal declaration、runtime-adjacent probe、static package build 或 no-resource C ABI 包装成 public API permission、resource callable permission、native object permission、Metal / AppKit permission、backend-ready permission、GPU-submission permission、render permission、renderer-state-write permission、receipt、record 或 publication。

## 后续入口

`P1 internal Renderer native bridge main-thread no-resource callable preflight decision`

下一轮若进入该入口，必须重新评估 platform import、main-thread classification strategy、macOS-only gate 与 non-macOS fallback；不得直接新增 resource callable、native object、Metal / AppKit 或 public API。

## 下游接续

下游 [main-thread no-resource callable manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-main-thread-no-resource-callable-manifest.md) 已完成，并新增 `CjguiInternalRendererNoNativeBridgeMainThreadCallReadiness` / `cjguiInternalExecuteDefaultRendererNativeBridgeMainThreadCallDraft()` 作为当前 main-thread no-resource endpoint。该接续只增加 current-thread classification facts，不把本 closure 的 no-resource FFI call facts 升格为 public API、resource callable、native object、Metal / AppKit 或 backend-ready truth。

## 设计意图出口自检

- 本轮是否改变主题状态：是，no-resource runtime FFI call owner 已完成 manifest 封账。
- 本轮是否改变 canonical tail / endpoint：是，tail 转为 `CjguiInternalRendererNoNativeBridgeNoResourceRuntimeCallReadiness` / `cjguiInternalExecuteDefaultRendererNativeBridgeNoResourceRuntimeCallDraft()`。
- 本轮是否改变 owner / truth / stop-line：是，owner 固定为 `runtime_renderer_native_bridge_no_resource_call.cj`；truth 固定为 no-resource observed facts；stop-line 不变。
- 本轮是否改变唯一 next opening：是，转为 `P1 internal Renderer native bridge main-thread no-resource callable preflight decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`docs/plans/topic-manifests/renderer-implementation-admission-chain.md`、`docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md`、`docs/plans/topic-manifests/macos-bridge-verification-smoke.md`。

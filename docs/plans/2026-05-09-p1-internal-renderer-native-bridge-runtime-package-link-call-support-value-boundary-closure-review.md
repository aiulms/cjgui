# P1 内部渲染器 native bridge runtime package link call support value boundary 复核

日期：2026-05-09

状态：value boundary closure / no runtime call

## 封账结论

已新增 internal owner：

- `runtime/cjgui/src/runtime_renderer_native_bridge_package_call_support.cj`

该 owner 只消费 `CjguiInternalRendererNoNativeBridgeRuntimeFfiCallReadiness`，记录 runtime-adjacent no-resource call evidence、runtime package config deferred facts、package call support blocker、macOS-only gate 与 no-runtime-package-call-support readiness facts。

## 新增 endpoint

- Endpoint：`CjguiInternalRendererNoNativeBridgePackageCallSupportReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererNativeBridgePackageCallSupportDraft()`
- Runtime input：`CjguiInternalRendererNoNativeBridgeRuntimeFfiCallReadiness`

## 固定事实

- Existing runtime-adjacent probe 已观察四个 no-resource callable。
- Existing script-managed `cjpm` package link probe 证明 temporary package route 可调用。
- `runtime/cjgui/cjpm.toml` 仍未修改。
- production `.m` 仍未接入 `runtime/cjgui` 主包。
- 主包 actual runtime FFI call 仍未打开。

## 未新增内容

- 未新增 runtime package-call-support probe。
- 未修改 build config / package config。
- 未修改 production native C ABI 行为。
- 未新增 public API。
- 未调用 FFI。
- 未创建 native object、native handle、raw pointer。

## GitNexus 影响记录

对上游入口运行 impact：

- `CjguiInternalRendererNoNativeBridgeRuntimeFfiCallReadiness`：UNKNOWN / not found，按近期新增 owner 未索引处理。
- `cjguiInternalExecuteDefaultRendererNativeBridgeRuntimeFfiDeclarationDraft`：UNKNOWN / not found，按近期新增 owner 未索引处理。

未收到 HIGH / CRITICAL 风险；继续以源码、build、probe 与 scans 兜底。

## 停止线

- no actual runtime FFI call。
- no public API / diagnostics。
- no resource callable。
- no native object / handle / pointer。
- no Cocoa / Metal / QuartzCore。
- no AppKit / Metal object creation。
- no retain / release / destroy。
- no renderer state write。
- no `runtime_state.cj` modification。
- no backend-ready truth。

## 同形边界刹车

不得把 `CjguiInternalRendererNoNativeBridgePackageCallSupportReadiness`、runtime-adjacent call evidence、package link evidence 或 owner facts 包装成 runtime FFI call permission、public API permission、resource callable permission、native object permission、Metal / AppKit permission、backend-ready permission、GPU-submission permission、render permission、renderer-state-write permission、receipt、record 或 publication。

## 设计意图出口自检

- 本轮是否改变主题状态：是，新增 runtime package link call support value boundary。
- 本轮是否改变 canonical tail / endpoint：是，新增 `CjguiInternalRendererNoNativeBridgePackageCallSupportReadiness` / `cjguiInternalExecuteDefaultRendererNativeBridgePackageCallSupportDraft()`。
- 本轮是否改变 owner / truth / stop-line：是，新增 package call support owner；truth 固定为 call support / blocker facts；stop-line 继续禁止 runtime call、public API、resource callable、native object、Metal / AppKit 与 state write。
- 本轮是否改变唯一 next opening：是，后续进入 manifest stabilization，然后转 package config link implementation preflight。
- 是否同步 topic manifest：待 manifest stabilization 同步。
- 已同步哪些 topic manifest：本 closure 尚未同步，后续 manifest 同步 `renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。

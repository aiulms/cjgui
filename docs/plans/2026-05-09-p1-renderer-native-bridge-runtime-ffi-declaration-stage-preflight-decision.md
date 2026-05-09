# P1 渲染器 native bridge no-resource callable runtime 接入阶段预检

日期：2026-05-09

状态：preflight / stage runway / internal-only

## 文件定位

本文件判断是否可以把已存在的 no-resource callable `C ABI` 纳入 runtime 内部可验证范围。

本文件不批准 public API，不批准 public diagnostics，不批准 native object、native handle、raw pointer、Metal / AppKit、renderer state write 或 backend-ready truth。

## 上游证据

- [callable C ABI first implementation manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-callable-c-abi-first-implementation-manifest.md) 已固定四个 no-resource callable。
- [callable C ABI planning manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-callable-c-abi-planning-manifest.md) 已要求 native callable 与 runtime FFI declaration 分阶段。
- [cjpm integration first implementation manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-cjpm-integration-first-implementation-manifest.md) 仍固定 `cjpm build` 与 production skeleton isolated compile 分离。
- `runtime/cjgui/cjpm.toml` 当前没有 `[ffi.c]`，也没有 production native source wiring。

## 结论

可以打开 runtime internal FFI declaration runway，但本阶段只能落 internal declaration planning value boundary，不写真实仓颉 FFI declaration。

理由是：production native skeleton 已有 side-effect-free no-resource callable，且 object-level symbol probe 可以验证四个符号存在；但 `cjpm` package 仍未链接 production `.m`，仓颉 FFI declaration 语法与 link path 仍缺少本仓库内可复用 precedent。直接写 `foreign` declaration 会把语法和 link 两个风险合并，超过本阶段 stop-line。

## 允许落点

- 新增 internal owner：`runtime/cjgui/src/runtime_renderer_native_bridge_ffi_declaration.cj`
- canonical endpoint：`CjguiInternalRendererNoNativeBridgeFfiDeclarationReadiness`
- default draft：`cjguiInternalExecuteDefaultRendererNativeBridgeFfiDeclarationDraft()`
- runtime input：`CjguiInternalRendererNoCallableCAbiReadiness`
- 新增 native symbol probe：`runtime/cjgui/native/scripts/verify_native_bridge_no_resource_symbols.sh`

该 owner 只表达 native bridge FFI declaration intent、internal-only callable declaration policy、no-resource callable allowlist、link separation / fallback policy、no-public-surface policy 与 no-native-bridge-FFI-declaration readiness facts。

## 暂缓项

- 真实仓颉 FFI declaration。
- runtime FFI call。
- build config / `runtime/cjgui/cjpm.toml` 修改。
- production `.m` 接入 `cjpm` package link。
- internal no-resource runtime call verification owner。

## 候选取舍

- 选择：进入 `P1 internal Renderer native bridge no-resource callable runtime integration stage bundle`，但实现范围收敛为 planning value boundary + native symbol probe。
- 暂缓：真实 runtime FFI declaration，等待 `P1 internal Renderer native bridge runtime FFI syntax / link preflight decision`。
- 拒绝：public API、native object、Metal / AppKit、resource callable、backend-ready truth、renderer state write。

## 同形边界刹车

不得把 no-resource callable `C ABI`、runtime declaration planning、symbol probe、build boundary 或 internal value facts 包装成 public API permission、native object permission、Metal / AppKit permission、backend-ready permission、GPU-submission permission、render permission、renderer-state-write permission、receipt、record 或 publication。

## 停止线

- no public API。
- no public diagnostics。
- no `runtime_state.cj` modification。
- no actual runtime FFI declaration。
- no runtime FFI call。
- no `runtime/cjgui/cjpm.toml` modification。
- no package / build config modification。
- no native handle / raw pointer。
- no native pointer return。
- no `NSWindow` / `NSView` / `CAMetalLayer`。
- no `MTLDevice` / `MTLCommandQueue`。
- no Cocoa / Metal / QuartzCore import in production bridge。
- no retain / release / destroy。
- no drawable / `nextDrawable`。
- no command buffer / `commandBuffer`。
- no `commit` / `present`。
- no GPU submission。
- no render execution。
- no renderer state write。
- no smoke native edits。
- no module-level mutable runtime state。
- no backend-ready truth。

## 设计意图出口自检

- 本轮是否改变主题状态：是，进入 no-resource callable runtime integration stage。
- 本轮是否改变 canonical tail / endpoint：是，新增阶段 endpoint `CjguiInternalRendererNoNativeBridgeFfiDeclarationReadiness`。
- 本轮是否改变 owner / truth / stop-line：是，新增 owner candidate 与 declaration planning truth；stop-line 继续禁止真实 FFI / public API / native object。
- 本轮是否改变唯一 next opening：是，阶段内下一步进入 value boundary 与 symbol probe。
- 是否同步 topic manifest：是。
- 已同步的 topic manifest：本阶段结束同步 `docs/plans/topic-manifests/renderer-implementation-admission-chain.md`、`docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md`、`docs/plans/topic-manifests/macos-bridge-verification-smoke.md`。


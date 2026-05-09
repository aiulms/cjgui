# P1 渲染器 native bridge runtime FFI 语法与链接预检判断

日期：2026-05-09

状态：preflight / docs-only decision

## 文件定位

本文件判断是否可以打开 no-resource `C ABI` 到仓颉 runtime 的 FFI 语法与链接验证 runway。

本轮不新增 public API，不新增 public diagnostics，不修改 `runtime/cjgui/cjpm.toml`，不修改 `runtime_state.cj`，不创建 native object、native handle、raw pointer、Metal / AppKit resource，不执行 render，不提交 GPU work，不写 renderer state。

## 上游证据

- `runtime/cjgui/native/cjgui_native_bridge.h` 与 `runtime/cjgui/native/cjgui_native_bridge.m` 已存在四个 no-resource callable：`cjgui_native_bridge_surface_version`、`cjgui_native_bridge_surface_capabilities`、`cjgui_native_bridge_status_ok`、`cjgui_native_bridge_no_resource_admission`。
- `runtime/cjgui/native/scripts/verify_native_bridge_no_resource_symbols.sh` 已能验证四个 symbol presence，但它不验证仓颉侧 FFI declaration 或 link。
- `runtime_renderer_native_bridge_ffi_declaration.cj` 只固定 declaration planning facts，不写真实 FFI declaration，不调用 native callable。
- 本地 `cffi` 文档与 `labs/cffi_smoke` 证明仓颉使用 `foreign func` 声明 C 函数，并可通过 direct `cjc -L ... -l ...` 链接本地 native 库。

## 判断结论

可以打开 isolated no-resource `C ABI` FFI probe runway。理由是当前生产 skeleton 已有 side-effect-free callable，仓库内已有 `cffi` smoke 可参考，且 direct `cjc` link 可以在隔离 lab 中验证，不需要先污染 `runtime/cjgui` 主包。

不直接进入 runtime/cjgui internal FFI declaration implementation。原因是 `runtime/cjgui` package 尚未接入 production `.m` 的 package link，`runtime/cjgui/cjpm.toml` 也没有 `[ffi.c]` 或等价 native source / linker wiring。直接写 runtime FFI declaration 会把 syntax、package link、runtime call 三件事合并。

## 候选取舍

- A 选择：`P1 internal Renderer isolated no-resource C ABI FFI probe bundle`。
- B 暂缓：`P1 internal Renderer runtime FFI syntax link planning value boundary bundle`。
- C 暂缓：直接 runtime/cjgui internal FFI declaration implementation。
- D 拒绝：public API / resource callable / native object / Metal / AppKit。

选择 A 的理由：isolated probe 能验证 `foreign func` 语法、no-resource callable direct link 与 deterministic result，而不修改 runtime package config、不新增 public API、不创建 native object。

## 允许范围

- 可新增 `labs/native_bridge_ffi_probe/` 作为隔离 lab。
- 可新增或修改 probe script，仅用于 no-resource callable FFI syntax / link evidence。
- 可新增 runtime planning owner 记录 syntax / link evidence 与 runtime package link fallback。
- 可继续运行现有 skeleton compile、symbol probe、`cjpm build` 与 smoke guard。

## 停止线

- no public API。
- no public diagnostics。
- no runtime FFI call。
- no runtime package link modification。
- no `runtime/cjgui/cjpm.toml` modification。
- no resource callable。
- no native object / native handle / raw pointer。
- no native pointer return。
- no Cocoa / Metal / QuartzCore import in production bridge。
- no AppKit / Metal object creation。
- no retain / release / destroy。
- no GPU submission。
- no render execution。
- no renderer state write。
- no `runtime_state.cj` modification。
- no smoke native edits。
- no backend-ready truth。

## 同形边界刹车

不得把 no-resource `C ABI`、symbol probe、`foreign func` syntax evidence、direct `cjc` link evidence 或 planning facts 包装成 public API permission、resource callable permission、native object permission、Metal / AppKit permission、backend-ready permission、GPU-submission permission、render permission、renderer-state-write permission、receipt、record 或 publication。

FFI syntax / link 只证明 no-resource interop feasibility，不证明 GUI backend ready。

## 后续入口

`P1 internal Renderer isolated no-resource C ABI FFI probe bundle`

## 设计意图出口自检

- 本轮是否改变主题状态：是，runtime FFI syntax / link 从待判断进入 isolated probe runway。
- 本轮是否改变 canonical tail / endpoint：否，preflight 本身不新增 endpoint。
- 本轮是否改变 owner / truth / stop-line：否，preflight 只定义允许写集与 stop-line。
- 本轮是否改变唯一 next opening：是，进入 `P1 internal Renderer isolated no-resource C ABI FFI probe bundle`。
- 是否同步 topic manifest：是，本阶段结束时统一同步。
- 已同步哪些 topic manifest：`docs/plans/topic-manifests/renderer-implementation-admission-chain.md`、`docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md`、`docs/plans/topic-manifests/macos-bridge-verification-smoke.md`。

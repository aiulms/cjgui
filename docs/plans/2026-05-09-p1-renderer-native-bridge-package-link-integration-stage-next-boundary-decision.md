# P1 渲染器 native bridge package link integration 阶段后续边界结论

日期：2026-05-09

状态：docs-only next-boundary / 选择 manifest stabilization

## 文件定位

本文件确认 `CjguiInternalRendererNoNativeBridgePackageLinkReadiness` / `cjguiInternalExecuteDefaultRendererNativeBridgePackageLinkDraft()` 是否足够作为当前 no-native-bridge-package-link planning endpoint，并选择下一步。

## 当前端点判断

`CjguiInternalRendererNoNativeBridgePackageLinkReadiness` 足够作为当前 package link integration planning endpoint。

它只表达：

- native bridge package link integration intent。
- macOS-only package link gate。
- package-adjacent probe evidence policy。
- runtime package config admission / fallback policy。
- no-resource callable link boundary。
- no-native-bridge-package-link readiness facts。

它不表达：

- runtime FFI call permission。
- `cjpm` package config integration permission。
- public API permission。
- resource callable permission。
- native object / native handle / raw pointer permission。
- Metal / AppKit permission。
- backend-ready truth。

## 候选取舍

- A 暂缓：`P1 internal Renderer native bridge runtime internal FFI declaration first implementation bundle`。
- B 选择：`P1 internal Renderer native bridge cjpm package link implementation preflight decision`。
- C 暂缓：`P1 internal Renderer native bridge package link blocker follow-up`。
- D 拒绝：public API。
- E 拒绝：resource callable / native object / Metal / AppKit。

选择 B 的理由：

- 本轮只完成 package-adjacent direct `cjc` link probe，没有修改 `runtime/cjgui/cjpm.toml`。
- `runtime/cjgui` package build 仍没有 `[ffi.c]` 或 native object wiring。
- 在真正 package config 语义被 preflight 前，直接进入 runtime FFI declaration implementation 容易把 probe evidence 误读成 package integration permission。
- 下一步应先 docs-only 判断是否、如何以 macOS-only / non-macOS fallback 的方式进入 `cjpm` package link first implementation。

## 同形边界刹车

不得把 package-adjacent probe、package link planning endpoint、direct `cjc` link evidence、symbol probe 或 no-resource callable 包装成 runtime FFI call permission、public API permission、resource callable permission、native object permission、backend-ready permission、receipt、record 或 publication。

## 后续入口

`P1 internal Renderer native bridge cjpm package link implementation preflight decision`

## 设计意图出口自检

- 本轮是否改变主题状态：是，package link integration stage 从 probe/value boundary 转入 manifest stabilization 与后续 `cjpm` package link preflight。
- 本轮是否改变 canonical tail / endpoint：是，当前 endpoint 为 `CjguiInternalRendererNoNativeBridgePackageLinkReadiness`。
- 本轮是否改变 owner / truth / stop-line：是，owner 为 `runtime/cjgui/src/runtime_renderer_native_bridge_package_link.cj`；truth 仅限 package-adjacent link planning；stop-line 继续禁止 runtime FFI call、public API、native object 与 package config mutation。
- 本轮是否改变唯一 next opening：是，转为 `P1 internal Renderer native bridge cjpm package link implementation preflight decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`docs/plans/topic-manifests/renderer-implementation-admission-chain.md`、`docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md`、`docs/plans/topic-manifests/macos-bridge-verification-smoke.md`。

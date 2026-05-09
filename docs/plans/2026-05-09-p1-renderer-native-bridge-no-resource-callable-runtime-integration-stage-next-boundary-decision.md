# P1 渲染器 native bridge no-resource callable runtime 接入阶段后续边界判断

日期：2026-05-09

状态：next-boundary / docs-only decision

## 当前判断

`CjguiInternalRendererNoNativeBridgeFfiDeclarationReadiness` / `cjguiInternalExecuteDefaultRendererNativeBridgeFfiDeclarationDraft()` 足够作为当前 no-native-bridge-FFI-declaration planning endpoint。

它只代表 internal declaration intent、no-resource callable allowlist、link separation / fallback policy、native symbol probe requirement、no-public-surface policy 与 no-actual-FFI-declaration facts。

它不是 runtime FFI declaration、runtime callable permission、native bridge implementation permission、native object permission、native handle permission、Metal / AppKit permission、backend-ready truth、renderer state write permission 或 public API permission。

## 候选取舍

- A 选择：`P1 internal Renderer native bridge runtime FFI syntax / link preflight decision`
- B 暂缓：`P1 internal Renderer native bridge no-resource callable runtime verification manifest stabilization bundle`
- C 暂缓：`P1 internal Renderer native bridge no-resource callable runtime call first implementation preflight decision`
- D 拒绝：public API。
- E 拒绝：native object / Metal / AppKit。
- F 拒绝：resource callable。

选择 A 的理由：本阶段新增了 planning owner 与 native symbol probe，但真实仓颉 FFI declaration 语法、`cjpm` link path、production `.m` 是否接入 package link 仍未完成 preflight。继续进入 runtime call 或 verification owner 会把 declaration、link、call 三件事合并，风险过宽。

## 下一步入口

`P1 internal Renderer native bridge runtime FFI syntax / link preflight decision`

## 停止线

- no actual FFI declaration。
- no runtime FFI call。
- no public API / diagnostics。
- no `runtime/cjgui/cjpm.toml` modification without preflight。
- no production native resource callable。
- no native object / handle / raw pointer。
- no Metal / AppKit import or object creation。
- no renderer state write。
- no backend-ready truth。

## 设计意图出口自检

- 本轮是否改变主题状态：是，no-resource callable runtime integration stage 已收束为 FFI declaration planning + symbol probe。
- 本轮是否改变 canonical tail / endpoint：是，当前阶段 endpoint 为 `CjguiInternalRendererNoNativeBridgeFfiDeclarationReadiness`。
- 本轮是否改变 owner / truth / stop-line：是，owner / truth 已新增；stop-line 继续禁止真实 FFI、runtime call、public API 与 native object。
- 本轮是否改变唯一 next opening：是，改为 `P1 internal Renderer native bridge runtime FFI syntax / link preflight decision`。
- 是否同步 topic manifest：是。
- 已同步的 topic manifest：`docs/plans/topic-manifests/renderer-implementation-admission-chain.md`、`docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md`、`docs/plans/topic-manifests/macos-bridge-verification-smoke.md`。


# P1 渲染器 native bridge FFI 语法与链接阶段后续边界判断

日期：2026-05-09

状态：next-boundary / docs-only decision

## 当前判断

`CjguiInternalRendererNoNativeBridgeFfiLinkReadiness` / `cjguiInternalExecuteDefaultRendererNativeBridgeFfiLinkDraft()` 足够作为当前 no-native-bridge-FFI-link planning endpoint。

它只代表 FFI syntax / link intent、isolated probe evidence policy、no-resource callable link admission policy、runtime package link denial / fallback policy、public surface denial policy 与 no-native-bridge-FFI-link readiness facts。

它不是真实 runtime FFI call，不是 package integration permission，不是 native bridge implementation permission，不是 native object permission，不是 Metal / AppKit permission，不是 backend-ready truth，也不是 public API permission。

## 候选取舍

- A 暂缓：`P1 internal Renderer native bridge runtime internal FFI declaration implementation preflight decision`。
- B 拒绝：`P1 internal Renderer native bridge FFI syntax/link blocker follow-up`。
- C 选择：`P1 internal Renderer native bridge package link integration preflight decision`。
- D 拒绝：public API。
- E 拒绝：resource callable / native object / Metal / AppKit。

选择 C 的理由：isolated FFI probe 已证明 `foreign func` 语法与 direct `cjc` link 可行；但 `runtime/cjgui` package 仍未接入 production `.m` 的 package link。下一阶段应先定义 package link integration 的允许写集、macOS-only gating、non-macOS fallback 与 rollback strategy，再考虑 runtime internal FFI declaration implementation。

## 停止线

- no runtime FFI call。
- no public API / diagnostics。
- no resource callable。
- no native object / handle / raw pointer。
- no native pointer return。
- no Metal / AppKit object creation。
- no GPU submission。
- no render execution。
- no renderer state write。
- no `runtime_state.cj` modification。
- no backend-ready truth。

## 后续入口

`P1 internal Renderer native bridge package link integration preflight decision`

## 设计意图出口自检

- 本轮是否改变主题状态：是，FFI syntax / link stage 已从 preflight / probe 推进到 next-boundary。
- 本轮是否改变 canonical tail / endpoint：是，当前 planning endpoint 为 `CjguiInternalRendererNoNativeBridgeFfiLinkReadiness`。
- 本轮是否改变 owner / truth / stop-line：是，owner 与 truth 已固定；stop-line 继续禁止 runtime call、native object 与 public API。
- 本轮是否改变唯一 next opening：是，转为 `P1 internal Renderer native bridge package link integration preflight decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`docs/plans/topic-manifests/renderer-implementation-admission-chain.md`、`docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md`、`docs/plans/topic-manifests/macos-bridge-verification-smoke.md`。

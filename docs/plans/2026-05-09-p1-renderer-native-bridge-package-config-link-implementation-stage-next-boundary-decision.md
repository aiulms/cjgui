# P1 渲染器 native bridge package config link implementation 后续走向结论

日期：2026-05-09

状态：docs-only next-boundary / manifest stabilization selected

## 当前阶段判断

`CjguiInternalRendererNoNativeBridgePackageConfigLinkReadiness` / `cjguiInternalExecuteDefaultRendererNativeBridgePackageConfigLinkDraft()` 足够作为当前 package config link stage 的 internal value endpoint。

该 endpoint 只代表 package config link implementation intent、no-resource native artifact policy、macOS-only package config gate、non-macOS fallback policy、script-managed route fallback policy 与 no-package-config-link readiness facts。

它不是 actual runtime FFI call、public API、resource callable、native object、Metal / AppKit、backend-ready truth 或 renderer state write permission。

## 候选比较

候选 A：`P1 internal Renderer native bridge internal no-resource runtime FFI call owner preflight decision`。

暂缓。script-managed route 已稳定，但主包 package config 仍未真实接入 no-resource archive；直接进入 runtime owner call preflight 容易把 probe evidence 包装成主包 call support permission。

候选 B：`P1 internal Renderer native bridge package config link blocker follow-up`。

暂缓。当前不是硬 blocker；临时 `cjpm` package route 与 script-managed probe 仍可作为稳定证据链。

候选 C：`P1 internal Renderer native bridge package config link manifest stabilization bundle`。

本轮选择 C。先封账实际路线、owner、endpoint、artifact policy、package config status 与 stop-line，再等待复核。

候选 D：public API。

拒绝。

候选 E：resource callable / native object / Metal / AppKit。

拒绝。

## 后续入口

本阶段 manifest 完成后的唯一建议入口：

`P1 internal Renderer native bridge package config link route reconciliation scan`

该入口应先对 script-managed route、package config still-deferred facts、runtime-adjacent call facts 与主包 call owner 条件做对账，避免继续用同形 value wrapper 堆叠。

## 同形边界刹车

不得把 package config link next-boundary、script-managed route、package call support facts、temporary package success 或 no-resource callable 包装成 runtime FFI call permission、public API permission、resource callable permission、native object permission、Metal / AppKit permission、backend-ready permission、GPU-submission permission、render permission、renderer-state-write permission、receipt、record 或 publication。

## 设计意图出口自检

- 本轮是否改变主题状态：是，package config link stage 进入 manifest stabilization。
- 本轮是否改变 canonical tail / endpoint：是，固定 `CjguiInternalRendererNoNativeBridgePackageConfigLinkReadiness`。
- 本轮是否改变 owner / truth / stop-line：是，owner / truth 固定到 package config link value boundary；stop-line 不放宽。
- 本轮是否改变唯一 next opening：是，转为 `P1 internal Renderer native bridge package config link route reconciliation scan`。
- 是否同步 topic manifest：将同步。
- 已同步哪些 topic manifest：将在 manifest closure 中列出。

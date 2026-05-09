# P1 渲染器 native bridge 构建 probe 后续边界判断

日期：2026-05-09

状态：docs-only next-boundary / no package integration

## 文件定位

本文件确认 isolated build probe 是否足够作为当前 skeleton compile feasibility evidence，并选择下一步是否进入 manifest stabilization。

## 端点确认

本轮没有新增 runtime owner，也没有新增 runtime endpoint。当前上游 planning endpoint 仍是 `CjguiInternalRendererNoNativeBridgeBuildIntegrationReadiness` / `cjguiInternalExecuteDefaultRendererNativeBridgeBuildIntegrationDraft()`。

新增 probe script 只提供 build feasibility evidence，不是 canonical runtime tail，不是 `cjpm` integration truth，也不是 callable C ABI truth。

## 候选比较

A 选择：`P1 internal Renderer native bridge build probe manifest stabilization bundle implementation`。

该路线只固定 probe script path、probe scope、temporary output policy、no `cjpm` integration、no callable C ABI / FFI、no runtime bridge readiness 与 stop-line。

B 暂缓：native bridge build system integration implementation preflight。该入口应在 probe manifest 封账后再打开。

C 暂缓：native bridge callable C ABI implementation preflight。当前缺少 package integration preflight，不允许直接打开 callable surface。

D 拒绝：直接接入 `cjpm` / FFI / runtime callable surface。

## 同形边界刹车

不得把 probe success、skeleton compile、C ABI surface contract、build integration planning、smoke evidence 或 manifest closure 包装成 `cjpm` integration permission、callable C ABI permission、FFI permission、native bridge implementation permission、Metal / AppKit permission、backend-ready permission、public API permission、receipt、record 或 publication。

## 停止线

- no `runtime/cjgui/cjpm.toml` modification。
- no package config modification。
- no production `.m` `cjpm` integration。
- no callable C ABI implementation。
- no FFI declaration。
- no runtime `.cj` FFI declaration。
- no native handle / raw pointer。
- no raw pointer return。
- no AppKit / Metal object creation。
- no retain / release / destroy。
- no GPU submission。
- no render execution。
- no renderer state write。
- no `runtime_state.cj` modification。
- no public diagnostics / API。
- no smoke native modification。

## 设计意图出口自检

- 本轮是否改变主题状态：是。build probe 已从 closure 进入 manifest stabilization。
- 本轮是否改变 canonical tail / endpoint：否。没有新增 runtime endpoint。
- 本轮是否改变 owner / truth / stop-line：否。probe script truth / stop-line 不变。
- 本轮是否改变唯一 next opening：是，改为 `P1 internal Renderer native bridge build probe manifest stabilization bundle implementation`。
- 是否同步 topic manifest：是。
- 已同步的 topic manifest：`docs/plans/topic-manifests/renderer-implementation-admission-chain.md`、`docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md`、`docs/plans/topic-manifests/macos-bridge-verification-smoke.md`。

## 唯一后续入口

`P1 internal Renderer native bridge build probe manifest stabilization bundle implementation`

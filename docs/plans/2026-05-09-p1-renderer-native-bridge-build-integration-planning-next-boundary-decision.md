# P1 渲染器 native bridge 构建接入规划后续边界判断

日期：2026-05-09

状态：docs-only next-boundary / no build config change

## 文件定位

本文件复核 `CjguiInternalRendererNoNativeBridgeBuildIntegrationReadiness` / `cjguiInternalExecuteDefaultRendererNativeBridgeBuildIntegrationDraft()` 是否足够作为当前 no-native-bridge-build-integration endpoint，并决定下一步是否进入 manifest stabilization。

## 端点确认

当前 endpoint 足够作为本阶段构建接入规划端点。它只代表 build integration planning intent、macOS-only build gating、Objective-C compile / link admission、framework link policy、production bridge build probe policy 与 no-native-bridge-build-integration readiness facts。

它不是 `cjpm.toml` 修改许可，不是 build script 修改许可，不是 production `.m` 编译接入许可，不是 callable C ABI / FFI 许可，不是 native handle / raw pointer 许可，不是 AppKit / Metal object 许可，不是 backend-ready truth，不是 renderer state write 或 public API permission。

## 候选比较

A 选择：`P1 internal Renderer native bridge build integration planning manifest stabilization bundle implementation`。

选择原因：owner 已编译通过，当前 truth 与 stop-line 已足够封账；下一步应固定 owner / runtime input / endpoint / default draft / truth / stop-line，避免后续误把 build planning facts 解读成 build config permission。

B 暂缓：`P1 internal Renderer native bridge build probe preflight decision`。该入口应在 manifest stabilization 后再打开。

C 拒绝：直接修改 `runtime/cjgui/cjpm.toml` 或 build script。当前仍缺 build probe preflight。

D 拒绝：直接接入 production `.m` 或实现 callable C ABI / FFI。

E 拒绝：继续新增 build-ready / bridge-ready / C-ABI-ready wrapper。

## 同形边界刹车

不得把 `CjguiInternalRendererNoNativeBridgeBuildIntegrationReadiness` 包装成 build integration permission、C ABI implementation permission、FFI permission、native-handle permission、Metal / AppKit permission、backend-ready permission、public diagnostics permission、public API permission、receipt、record 或 publication。

下一步只能做 manifest 封账，不新增 tail wrapper。

## 停止线

- no `runtime/cjgui/cjpm.toml` modification。
- no build script / package config modification。
- no production `.m` compile integration。
- no native skeleton modification。
- no smoke lab native modification。
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
- no public diagnostics。
- no public API。

## 设计意图出口自检

- 本轮是否改变主题状态：是。build integration planning value boundary 已完成，下一步进入 manifest stabilization。
- 本轮是否改变 canonical tail / endpoint：否。当前 endpoint 仍是 `CjguiInternalRendererNoNativeBridgeBuildIntegrationReadiness` / `cjguiInternalExecuteDefaultRendererNativeBridgeBuildIntegrationDraft()`。
- 本轮是否改变 owner / truth / stop-line：否。只复核已新增 owner 与 truth / stop-line。
- 本轮是否改变唯一 next opening：是，改为 `P1 internal Renderer native bridge build integration planning manifest stabilization bundle implementation`。
- 是否同步 topic manifest：是。
- 已同步的 topic manifest：`docs/plans/topic-manifests/renderer-implementation-admission-chain.md`、`docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md`、`docs/plans/topic-manifests/macos-bridge-verification-smoke.md`。

## 唯一后续入口

`P1 internal Renderer native bridge build integration planning manifest stabilization bundle implementation`

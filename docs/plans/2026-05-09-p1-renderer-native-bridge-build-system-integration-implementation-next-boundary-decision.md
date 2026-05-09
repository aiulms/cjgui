# P1 渲染器 native bridge 构建系统接入实现后续边界判断

日期：2026-05-09

状态：docs-only next-boundary / no build config change

## 文件定位

本文件复核 `CjguiInternalRendererNoNativeBridgeBuildSystemImplementationReadiness` / `cjguiInternalExecuteDefaultRendererNativeBridgeBuildSystemAdmissionDraft()` 是否足够作为当前 no-native-bridge-build-system-implementation endpoint，并决定下一步是否进入 manifest stabilization。

## 端点确认

当前 endpoint 足够作为本阶段 build system integration implementation admission endpoint。它只代表 build system implementation intent、macOS-only build gate admission、native source inclusion denial proof、Objective-C compile / link admission policy、framework link denial proof、build failure classification 与 no-native-bridge-build-system-implementation readiness facts。

它不是 `runtime/cjgui/cjpm.toml` 修改许可，不是 package / build config 修改许可，不是 production `.m` 编译接入许可，不是 callable C ABI / FFI 许可，不是 native handle / raw pointer 许可，不是 AppKit / Metal object 许可，不是 backend-ready truth，不是 renderer state write 或 public API permission。

## 候选比较

A 选择：`P1 internal Renderer native bridge build system integration implementation manifest stabilization bundle`。

选择原因：owner 已足够表达当前 implementation admission facts；下一步应固定 owner / runtime input / endpoint / default draft / truth / stop-line，避免后续误把 build system admission facts 解读成 build config permission。

B 暂缓：`P1 internal Renderer native bridge cjpm integration first implementation preflight decision`。该入口应在 manifest stabilization 后再打开。

C 拒绝：直接修改 `runtime/cjgui/cjpm.toml` 或 build scripts。

D 拒绝：直接接入 production `.m`、实现 callable C ABI / FFI 或新增 runtime `.cj` FFI declaration。

E 拒绝：创建 AppKit / Metal object、native handle、backend-ready truth、renderer state write 或 public API。

F 拒绝：继续新增 build-ready / bridge-ready / receipt / record / publication wrapper。

## 同形边界刹车

不得把 `CjguiInternalRendererNoNativeBridgeBuildSystemImplementationReadiness` 包装成 `cjpm` integration permission、callable C ABI permission、FFI permission、native bridge implementation permission、Metal / AppKit permission、backend-ready permission、public diagnostics permission、public API permission、receipt、record 或 publication。

下一步只能做 manifest 封账，不新增 tail wrapper。

## 停止线

- no `runtime/cjgui/cjpm.toml` modification。
- no package config / build config modification。
- no production `.m` `cjpm build` integration。
- no production skeleton modification。
- no probe script modification。
- no smoke native modification。
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

## 设计意图出口自检

- 本轮是否改变主题状态：是。build system integration implementation value boundary 已完成，下一步进入 manifest stabilization。
- 本轮是否改变 canonical tail / endpoint：否。当前 endpoint 仍是 `CjguiInternalRendererNoNativeBridgeBuildSystemImplementationReadiness` / `cjguiInternalExecuteDefaultRendererNativeBridgeBuildSystemAdmissionDraft()`。
- 本轮是否改变 owner / truth / stop-line：否。只复核已新增 owner 与 truth / stop-line。
- 本轮是否改变唯一 next opening：是，改为 `P1 internal Renderer native bridge build system integration implementation manifest stabilization bundle`。
- 是否同步 topic manifest：是。
- 已同步的 topic manifest：`docs/plans/topic-manifests/renderer-implementation-admission-chain.md`、`docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md`、`docs/plans/topic-manifests/macos-bridge-verification-smoke.md`。

## 唯一后续入口

`P1 internal Renderer native bridge build system integration implementation manifest stabilization bundle`

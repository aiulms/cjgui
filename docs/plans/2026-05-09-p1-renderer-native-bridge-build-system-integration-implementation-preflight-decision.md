# P1 渲染器 native bridge 构建系统接入实现预检判断

日期：2026-05-09

状态：docs-only preflight / no build config change

## 文件定位

本文件判断 isolated native bridge build probe 通过后，是否可以打开 native bridge build system integration implementation runway。

本轮不修改 `.cj` 之外的 build config，不修改 `runtime/cjgui/cjpm.toml`，不把 production `.m` 接入 `cjpm build`，不修改 production skeleton `.h` / `.m` 或 probe script，不实现 callable C ABI / FFI，也不新增 runtime `.cj` FFI declaration。

## 上游事实

native bridge build integration planning manifest 已固定 `runtime/cjgui/src/runtime_renderer_native_bridge_build_integration.cj`：

- runtime input：`CjguiInternalRendererNoNativeBridgeTeardownImplementationReadiness`
- canonical endpoint：`CjguiInternalRendererNoNativeBridgeBuildIntegrationReadiness`
- default draft：`cjguiInternalExecuteDefaultRendererNativeBridgeBuildIntegrationDraft()`
- current truth：native bridge build integration planning intent / macOS-only build gating policy / Objective-C compile-link admission policy / framework link policy / production bridge build probe policy / no-native-bridge-build-integration readiness facts

native bridge build probe manifest 已固定 `runtime/cjgui/native/scripts/verify_native_bridge_skeleton_compile.sh`。probe 只证明 `runtime/cjgui/native/cjgui_native_bridge.m` 可以被隔离编译到 `/tmp/cjgui-native-bridge-build-probe-*`，不表示 `cjpm` integration、callable C ABI、FFI 或 runtime bridge ready。

## 判断结果

可以打开 build system integration implementation runway，但第一切片仍必须是 internal value boundary，而不是修改 `runtime/cjgui/cjpm.toml` 或接入 production `.m`。

必须先把真正接入前的实现准入 facts 固定下来：

- macOS-only build gate admission。
- optional native source inclusion denial proof。
- Objective-C compiler / linker path admission。
- `SDKROOT` discovery 与 deployment target policy。
- framework link denial / future explicit framework list policy。
- non-macOS fallback 与 CI / headless behavior。
- probe-vs-production-build separation。
- build failure classification 与 fail-closed posture。

这些 facts 只能作为 implementation admission，不是 build config permission。

## 候选比较

A 选择：`P1 internal Renderer native bridge build system integration implementation value boundary bundle`。

选择原因：isolated probe 与 build integration planning 已足够支持下一步 value owner；但直接改 `cjpm.toml`、接入 `.m` 或声明 FFI 仍过早。

B 暂缓：直接 `cjpm` integration first implementation。当前还未把 source inclusion denial、framework link denial 与 failure classification 固定为 runtime facts。

C 暂缓：callable C ABI implementation preflight。当前仍未进入 callable surface。

D 拒绝：直接修改 `runtime/cjgui/cjpm.toml`、build scripts 或 package config。

E 拒绝：直接接入 production `.m`、新增 runtime `.cj` FFI declaration 或实现 C ABI / FFI。

F 拒绝：创建 AppKit / Metal object、native handle、raw pointer、backend-ready truth、renderer state write 或 public API。

G 拒绝：继续新增 build-ready / bridge-ready / receipt / record / publication wrapper。

## 同形边界刹车

不得把 isolated probe、build planning facts、skeleton compile、C ABI surface contract 或 smoke evidence 包装成 `cjpm` integration permission、callable C ABI permission、FFI permission、native bridge implementation permission、Metal / AppKit permission、backend-ready permission、public API permission、receipt、record 或 publication。

若选择 A，下一轮必须新增 build system implementation admission、source inclusion denial、framework link denial 与 failure classification 语义，而不是薄包装。

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

- 本轮是否改变主题状态：是。主题从 build probe manifest 推进到 build system integration implementation preflight。
- 本轮是否改变 canonical tail / endpoint：否。当前 runtime endpoint 仍是 `CjguiInternalRendererNoNativeBridgeBuildIntegrationReadiness` / `cjguiInternalExecuteDefaultRendererNativeBridgeBuildIntegrationDraft()`。
- 本轮是否改变 owner / truth / stop-line：是。preflight 选择下一步新增 build system implementation admission value boundary，并固定新的 stop-line。
- 本轮是否改变唯一 next opening：是，改为 `P1 internal Renderer native bridge build system integration implementation value boundary bundle`。
- 是否同步 topic manifest：是。
- 已同步的 topic manifest：`docs/plans/topic-manifests/renderer-implementation-admission-chain.md`、`docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md`、`docs/plans/topic-manifests/macos-bridge-verification-smoke.md`。

## 唯一后续入口

`P1 internal Renderer native bridge build system integration implementation value boundary bundle`

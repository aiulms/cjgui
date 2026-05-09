# P1 渲染器 native bridge 构建 probe 预检判断

日期：2026-05-09

状态：docs-only preflight / no build config change / no callable C ABI

## 文件定位

本文件判断是否可以从 native bridge build integration planning manifest 进入 isolated native bridge build probe runway。

本轮只允许定义隔离 probe 的范围与停止线，不批准修改 `runtime/cjgui/cjpm.toml`、package config、production native skeleton contract、smoke native 文件、runtime `.cj` FFI declaration 或 public API。

## 上游事实

已完成 [native bridge build integration planning manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-build-integration-planning-manifest.md)。其 endpoint `CjguiInternalRendererNoNativeBridgeBuildIntegrationReadiness` / `cjguiInternalExecuteDefaultRendererNativeBridgeBuildIntegrationDraft()` 只表达 build integration planning intent、macOS-only build gating、Objective-C compile-link admission、framework link policy 与 production bridge build probe policy。

production skeleton 已存在：

- `runtime/cjgui/native/cjgui_native_bridge.h`
- `runtime/cjgui/native/cjgui_native_bridge.m`

该 skeleton 未接入 `cjpm` build，未实现 callable C ABI，未接 FFI，未导入 AppKit / Metal / QuartzCore，当前仍只是 production write-set 落点与 status taxonomy evidence。

## 判断结果

可以打开 isolated native bridge build probe runway，但第一刀只能新增隔离 probe script。probe 只验证 production skeleton `.m` 在本机 Objective-C 工具链下可以独立编译到临时输出目录；它必须继续与 `cjpm` 集成分离。

probe 可以读取 `SDKROOT`、`xcrun` 与 `clang`，并使用 `/tmp/cjgui-native-bridge-build-probe-*` 作为输出目录。probe 不修改项目配置，不修改 source，不链接 AppKit / Metal / QuartzCore，不执行 app，不调用 C ABI，不返回 native pointer。

当前 skeleton 不参与 `cjpm build` 仍属于预期边界。probe 成功只能说明 skeleton compile feasibility，不表示 runtime bridge integrated、C ABI callable、FFI wired、backend-ready 或 public API ready。

## 候选比较

A 选择：`P1 internal Renderer native bridge isolated build probe bundle`。

该路线只新增隔离 probe script 与 docs，不修改 `runtime/cjgui/cjpm.toml`，不把 production `.m` 接入 `cjpm`，不实现 C ABI / FFI，不创建 native object。

B 暂缓：native bridge build system integration implementation preflight。该入口应在 probe manifest 封账后再判断是否允许靠近 package integration。

C 暂缓：native bridge callable C ABI implementation preflight。当前仍未允许 callable surface。

D 拒绝：直接接入 `cjpm` / FFI / runtime callable surface。

## 同形边界刹车

不得把 build probe、skeleton compile、C ABI surface contract、build integration planning 或 smoke evidence 包装成 `cjpm` integration permission、C ABI callable permission、FFI permission、native bridge implementation permission、Metal / AppKit permission、backend-ready permission、public API permission、receipt、record 或 publication。

若下一步选择 A，新增的是 isolated build probe 证据，不是 runtime truth。

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
- no module-level mutable `var`。

## 设计意图出口自检

- 本轮是否改变主题状态：是。build integration planning 后续入口进入 isolated build probe bundle。
- 本轮是否改变 canonical tail / endpoint：否。仍以 `CjguiInternalRendererNoNativeBridgeBuildIntegrationReadiness` / `cjguiInternalExecuteDefaultRendererNativeBridgeBuildIntegrationDraft()` 作为上游 planning endpoint。
- 本轮是否改变 owner / truth / stop-line：否。本文件只做 docs-only preflight，不新增 owner。
- 本轮是否改变唯一 next opening：是，改为 `P1 internal Renderer native bridge isolated build probe bundle`。
- 是否同步 topic manifest：是。
- 已同步的 topic manifest：`docs/plans/topic-manifests/renderer-implementation-admission-chain.md`、`docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md`、`docs/plans/topic-manifests/macos-bridge-verification-smoke.md`。

## 唯一后续入口

`P1 internal Renderer native bridge isolated build probe bundle`

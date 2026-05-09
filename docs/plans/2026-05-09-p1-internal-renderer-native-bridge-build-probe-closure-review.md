# P1 渲染器 native bridge 构建 probe 收口复核

日期：2026-05-09

状态：closure review / isolated probe / no runtime truth

## 文件定位

本 closure 记录 isolated native bridge build probe bundle 的实际落点。它只证明 production skeleton 可以被隔离 probe 编译检查，不改变 `cjpm` package integration，不实现 C ABI / FFI，也不把 production bridge 升格为 runtime truth。

## 新增 probe

新增脚本：

- [verify_native_bridge_skeleton_compile.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_native_bridge_skeleton_compile.sh)

脚本范围：

- 只编译 `runtime/cjgui/native/cjgui_native_bridge.m`。
- 输出到 `/tmp/cjgui-native-bridge-build-probe-*`。
- 读取 `SDKROOT` / `xcrun` / `clang`。
- 不修改 source。
- 不修改 `runtime/cjgui/cjpm.toml` 或 package config。
- 不把 `.m` 接入 `cjpm`。
- 不依赖 `labs/macos_bridge_smoke/native/*`。
- 不执行 app，不调用 C ABI，不接 FFI，不链接 AppKit / Metal / QuartzCore。

## 当前事实

probe 只验证 skeleton compile / syntax feasibility。它不表示 C ABI callable、FFI integrated、`cjpm` integrated、runtime bridge ready、native handle ready、Metal / AppKit ready、backend-ready、renderer state write ready 或 public API ready。

production skeleton 当前未参与 `cjpm build` 仍是预期边界，不是漏测。

## 验证记录

- `runtime/cjgui/native/scripts/verify_native_bridge_skeleton_compile.sh`：通过。输出目录为 `/tmp/cjgui-native-bridge-build-probe-grLQzI`，只生成隔离 object，未修改 source，未接入 `cjpm`，未调用 C ABI / FFI。
- `cjpm build --target-dir /tmp/cjgui-renderer-native-bridge-build-probe-target --skip-script`：通过，保留既有 unused warnings，最终输出 `cjpm build success`。
- `labs/macos_bridge_smoke/scripts/verify_auto_close.sh`：通过，auto-close log assertions passed，destroy complete 路径仍由 smoke lab 自身验证。
- 其余最终验证记录见本宏包 manifest stabilization closure。

## 同形边界刹车

本轮没有把 probe、skeleton compile、build integration planning、C ABI surface contract 或 smoke evidence 包装成 `cjpm` integration permission、callable C ABI permission、FFI permission、native bridge implementation permission、Metal / AppKit permission、backend-ready permission、public API permission、receipt、record 或 publication。

## 设计意图出口自检

- 本轮是否改变主题状态：是。native bridge build probe 已形成 isolated probe evidence。
- 本轮是否改变 canonical tail / endpoint：否。未新增 runtime endpoint，仍以上游 `CjguiInternalRendererNoNativeBridgeBuildIntegrationReadiness` 作为 planning endpoint。
- 本轮是否改变 owner / truth / stop-line：是。新增 probe script truth / stop-line，但不新增 runtime owner。
- 本轮是否改变唯一 next opening：是，改为 `P1 internal Renderer native bridge build probe closure / next boundary decision`。
- 是否同步 topic manifest：是。
- 已同步的 topic manifest：`docs/plans/topic-manifests/renderer-implementation-admission-chain.md`、`docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md`、`docs/plans/topic-manifests/macos-bridge-verification-smoke.md`。

## 唯一后续入口

`P1 internal Renderer native bridge build probe closure / next boundary decision`

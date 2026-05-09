# P1 渲染器 native bridge cjpm 接入第一实现收口复核

日期：2026-05-09

状态：implementation closure / build glue only

## 文件定位

本 closure 记录 native bridge `cjpm` integration first implementation 已按 B 路线完成：新增一个内部 build boundary probe script，串联 `cjpm build --skip-script` 与 production skeleton isolated compile。

本轮没有修改 `runtime/cjgui/cjpm.toml`，没有把 production `.m` 接入 `cjpm build`，没有实现 callable C ABI / FFI，没有新增 runtime `.cj` FFI declaration，也没有修改 production skeleton 或 smoke native 文件。

## 新增脚本

新增：

- [verify_native_bridge_cjpm_integration_boundary.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_native_bridge_cjpm_integration_boundary.sh)

脚本只执行以下检查：

- 确认 `runtime/cjgui/cjpm.toml` 没有 `[ffi.c]`、native skeleton wiring、`compile-option` 或 `link-option`。
- 确认 production skeleton `.m` 没有 Cocoa / Metal / QuartzCore import，也没有 forbidden native object / GPU token。
- 确认 `.h` / `.m` 没有 lowercase `cjgui_*` callable C ABI symbol。
- 运行 `cjpm build --target-dir <tmp> --skip-script`。
- 运行既有 `verify_native_bridge_skeleton_compile.sh`。

## GitNexus 记录

本轮未编辑 runtime symbol。实现前已记录 GitNexus `detect_changes(scope=unstaged, repo=/Users/jiangxuanyang/Desktop/cangjie)` baseline：risk `low`，affected_count `0`，affected_processes `[]`。

## 边界确认

本轮未修改：

- `runtime/cjgui/cjpm.toml`
- `runtime/cjgui/native/cjgui_native_bridge.h`
- `runtime/cjgui/native/cjgui_native_bridge.m`
- `labs/macos_bridge_smoke/native/*`
- runtime `.cj` FFI declaration
- public API files
- `runtime/cjgui/src/runtime_state.cj`

本轮未创建 native handle / raw pointer，未返回 native pointer，未 import / use Cocoa / Metal / QuartzCore in production skeleton，未调用 retain / release / destroy，未提交 GPU work，未执行 render，未写 renderer state，未新增 public diagnostics，也未新增 module-level mutable `var`。

## 验证记录

- `runtime/cjgui/native/scripts/verify_native_bridge_cjpm_integration_boundary.sh`：通过。脚本先运行 `cjpm build --target-dir /tmp/cjgui-native-bridge-cjpm-boundary-target --skip-script`，结果为 `cjpm build success`，并保留既有 `230 warnings generated, 230 warnings printed.`；随后运行 isolated production skeleton compile，通过并输出 `no cjpm integration, no FFI, no callable C ABI`。
- `runtime/cjgui/native/scripts/verify_native_bridge_skeleton_compile.sh`：通过，输出 object 到 `/tmp/cjgui-native-bridge-build-probe-*`，并确认 `no cjpm integration, no FFI, no callable C ABI`。
- `cjpm build --target-dir /tmp/cjgui-renderer-native-bridge-cjpm-integration-target --skip-script`：通过，结果为 `cjpm build success`，仅保留既有 `230 warnings generated, 230 warnings printed.`。
- `labs/macos_bridge_smoke/scripts/verify_auto_close.sh`：通过，日志断言包含 auto-close、main-thread drain、destroy complete 与返回码 `0`；该 smoke 仍只作为既有 lab evidence，不升格为 production bridge truth。
- `git diff --check`：通过。
- 新脚本与本轮新增文档 no-index whitespace check：通过，无 whitespace error 输出。
- 其余最终验证记录见本宏包 manifest stabilization closure。

## 同形边界刹车

本轮没有把 build glue、`cjpm build` success、skeleton compile success、C ABI surface contract 或 smoke evidence 包装成 callable C ABI permission、FFI permission、native bridge implementation permission、Metal / AppKit permission、backend-ready permission、public API permission、receipt、record 或 publication。

新增脚本只是可重复验证入口，不是 runtime bridge truth。

## 设计意图出口自检

- 本轮是否改变主题状态：是。native bridge `cjpm` integration first implementation 已完成 build glue implementation。
- 本轮是否改变 canonical tail / endpoint：否。没有新增 runtime endpoint。
- 本轮是否改变 owner / truth / stop-line：是。新增 build glue script truth / stop-line；runtime owner 不变。
- 本轮是否改变唯一 next opening：是，改为 `P1 internal Renderer native bridge cjpm integration first implementation closure / next boundary decision`。
- 是否同步 topic manifest：是。
- 已同步的 topic manifest：`docs/plans/topic-manifests/renderer-implementation-admission-chain.md`、`docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md`、`docs/plans/topic-manifests/macos-bridge-verification-smoke.md`。

## 下游后续入口

`P1 internal Renderer native bridge cjpm integration first implementation closure / next boundary decision`

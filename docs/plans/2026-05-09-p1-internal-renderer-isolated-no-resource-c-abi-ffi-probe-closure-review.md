# P1 内部渲染器 isolated no-resource C ABI FFI probe 收口复核

日期：2026-05-09

状态：closure review / isolated probe passed

## 文件定位

本 closure 封账 isolated no-resource `C ABI` FFI probe。该 probe 只验证仓颉 `foreign func` 语法、direct `cjc` link 与四个 no-resource callable 的脱水结果。

本 closure 不表示 runtime/cjgui 已接入 FFI，不表示 public API，不表示 native bridge ready，不表示 backend ready。

## 新增文件

- `labs/native_bridge_ffi_probe/README.md`
- `labs/native_bridge_ffi_probe/src/main.cj`
- `labs/native_bridge_ffi_probe/scripts/env.sh`
- `labs/native_bridge_ffi_probe/scripts/build_and_run.sh`

## 探针行为

`src/main.cj` 只声明并调用以下 no-resource callable：

- `cjgui_native_bridge_surface_version`
- `cjgui_native_bridge_surface_capabilities`
- `cjgui_native_bridge_status_ok`
- `cjgui_native_bridge_no_resource_admission`

`build_and_run.sh` 只编译 production skeleton object，生成临时 static lib，并通过 direct `cjc` link 运行 isolated caller。输出目录使用 `/tmp/cjgui-native-bridge-ffi-probe-*`。

## 实际验证结果

已运行：

`labs/native_bridge_ffi_probe/scripts/build_and_run.sh`

结果通过，输出摘要：

```text
cjgui native bridge ffi probe: surface_version_observed=true
cjgui native bridge ffi probe: capabilities_observed=true
cjgui native bridge ffi probe: status_ok_observed=true
cjgui native bridge ffi probe: no_resource_admission_observed=true
cjgui native bridge ffi probe: success=true reason=none
```

首次运行时曾因 `xcrun` 选择 `MacOSX26.4.sdk` 导致 `cjc` link 失败；已在 isolated probe 自身的 `env.sh` 中改为优先使用仓颉现有 smoke 已验证过的 `MacOSX15.4.sdk`，不修改 runtime package config，也不修改 production native callable implementation。

## 边界确认

- 未修改 `runtime/cjgui/cjpm.toml`。
- 未修改 package / build config。
- 未修改 `runtime/cjgui/src/runtime_state.cj`。
- 未修改 smoke native files。
- 未新增 public API / diagnostics。
- 未创建 native object。
- 未创建 native handle / raw pointer。
- 未返回 native pointer。
- 未导入 Cocoa / Metal / QuartzCore 到 production bridge。
- 未调用 resource callable。
- 未提交 GPU work、未执行 render、未写 renderer state。

## 证据含义

该 probe 证明：

- 仓颉 `foreign func` 语法可声明当前 no-resource `C ABI`。
- production skeleton object 可被隔离 static lib 链接。
- direct `cjc -L ... -l ...` link 可调用四个 no-resource callable。
- no-resource callable 返回 deterministic integer facts。

该 probe 不证明：

- `runtime/cjgui` package 已接入 production `.m`。
- `runtime/cjgui` 已存在真实 FFI declaration。
- runtime 可以直接 call native bridge。
- native bridge 已可创建 native object。
- GUI backend 已 ready。

## 同形边界刹车

不得把 isolated FFI probe success 包装成 runtime FFI permission、runtime callable permission、native bridge implementation permission、native object permission、native handle permission、Metal / AppKit permission、backend-ready permission、GPU-submission permission、render permission、renderer-state-write permission、public API permission、receipt、record 或 publication。

## 后续入口

继续进入 `P1 internal Renderer native bridge FFI syntax/link planning value boundary bundle`，用 runtime planning owner 记录 isolated probe evidence、runtime package link fallback 与 no-public-surface stop-line。

## 设计意图出口自检

- 本轮是否改变主题状态：是，isolated no-resource `C ABI` FFI probe 已通过。
- 本轮是否改变 canonical tail / endpoint：否，本 closure 只封账 lab evidence。
- 本轮是否改变 owner / truth / stop-line：是，新增 isolated lab artifact truth；stop-line 继续禁止 runtime FFI call、public API 与 native object。
- 本轮是否改变唯一 next opening：是，进入 runtime FFI syntax / link planning value boundary。
- 是否同步 topic manifest：是，本阶段结束时统一同步。
- 已同步哪些 topic manifest：`docs/plans/topic-manifests/renderer-implementation-admission-chain.md`、`docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md`、`docs/plans/topic-manifests/macos-bridge-verification-smoke.md`。

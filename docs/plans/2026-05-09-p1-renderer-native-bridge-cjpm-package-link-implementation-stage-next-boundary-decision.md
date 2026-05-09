# P1 渲染器 native bridge cjpm package link implementation 阶段后续边界结论

日期：2026-05-09

状态：docs-only next-boundary / choose runtime internal FFI declaration first implementation

## 文件定位

本文件确认 `CjguiInternalRendererNoNativeBridgeCjpmPackageLinkReadiness` / `cjguiInternalExecuteDefaultRendererNativeBridgeCjpmPackageLinkDraft()` 是否足够作为当前 no-native-bridge-cjpm-package-link endpoint，并选择下一步入口。

## 当前 endpoint 语义

该 endpoint 只代表：

- native bridge `cjpm` package link implementation intent。
- script-managed temporary `cjpm` package link route evidence。
- macOS-only `cjpm` package link gate。
- runtime package config admission / fallback policy。
- no-resource native object link policy。
- no-native-bridge-cjpm-package-link readiness facts。

它不代表 runtime FFI call、public API、resource callable、native object、native handle、raw pointer、Metal / AppKit、backend-ready truth、GPU submission、render 或 renderer state write permission。

## 候选比较

- A 选择：`P1 internal Renderer native bridge runtime internal FFI declaration first implementation bundle`。
- B 暂缓：`P1 internal Renderer native bridge cjpm package link blocker follow-up`。
- C 暂缓：`P1 internal Renderer native bridge package link route stabilization follow-up`。
- D 拒绝：public API。
- E 拒绝：resource callable / native object / Metal / AppKit。

## 选择理由

选择 A。新增 `verify_native_bridge_cjpm_package_link_probe.sh` 已通过临时仓颉 package 的 `compile-option` / `link-option` 路线证明 no-resource static archive 能被 `cjpm run --skip-script` 链接和调用；`runtime/cjgui/cjpm.toml` 仍未修改，这是本阶段刻意的 fail-closed 边界。下一步可以评估 runtime internal FFI declaration first implementation，但该后续仍必须先 preflight，并且不得把 declaration 直接升级为 runtime FFI call 或 public API。

## 同形边界刹车

不得把 script-managed link route、temporary package success、package link owner endpoint、package-adjacent probe、direct `cjc` probe 或 no-resource callable 包装成 runtime FFI call permission、public API permission、resource callable permission、native object permission、Metal / AppKit permission、backend-ready permission、receipt、record 或 publication。

## 唯一后续入口

`P1 internal Renderer native bridge runtime internal FFI declaration first implementation bundle`

## 设计意图出口自检

- 本轮是否改变主题状态：是，`cjpm` package link implementation stage 已完成后续边界判断。
- 本轮是否改变 canonical tail / endpoint：是，当前 tail 固定为 `CjguiInternalRendererNoNativeBridgeCjpmPackageLinkReadiness`。
- 本轮是否改变 owner / truth / stop-line：是，owner 为 `runtime/cjgui/src/runtime_renderer_native_bridge_cjpm_package_link.cj`；truth 仅限 script-managed package link facts；stop-line 继续禁止 runtime FFI call、public API、native object、Metal / AppKit 与 backend-ready truth。
- 本轮是否改变唯一 next opening：是，转为 `P1 internal Renderer native bridge runtime internal FFI declaration first implementation bundle`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`docs/plans/topic-manifests/renderer-implementation-admission-chain.md`、`docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md`、`docs/plans/topic-manifests/macos-bridge-verification-smoke.md`。

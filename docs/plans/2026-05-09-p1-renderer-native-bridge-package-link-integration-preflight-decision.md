# P1 渲染器 native bridge package link integration 预检结论

日期：2026-05-09

状态：docs-only preflight / 选择 package-adjacent probe

## 文件定位

本预检判断 isolated direct `cjc` link 证据是否足够推进到 `runtime/cjgui` package link integration 路线。

本文件不批准 public API，不批准 runtime FFI call，不批准 resource callable，不批准 native object，不批准 Metal / AppKit，不批准 backend-ready truth。

## 已读取证据

- [设计意图导航索引](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/DESIGN_INTENT_INDEX.md)
- [Renderer implementation admission chain topic manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/renderer-implementation-admission-chain.md)
- [Renderer backend readiness runway topic manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md)
- [macOS bridge verification smoke topic manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/macos-bridge-verification-smoke.md)
- [设计意图导航出口协议](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-design-intent-navigation-exit-protocol.md)
- [native bridge FFI syntax / link stage manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-ffi-syntax-link-stage-manifest.md)
- [native bridge FFI syntax / link stage closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-internal-renderer-native-bridge-ffi-syntax-link-stage-manifest-stabilization-closure-review.md)
- [isolated FFI probe README](/Users/jiangxuanyang/Desktop/cangjie/labs/native_bridge_ffi_probe/README.md)
- [isolated FFI probe main](/Users/jiangxuanyang/Desktop/cangjie/labs/native_bridge_ffi_probe/src/main.cj)
- [isolated FFI probe build script](/Users/jiangxuanyang/Desktop/cangjie/labs/native_bridge_ffi_probe/scripts/build_and_run.sh)
- [production native bridge header](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/cjgui_native_bridge.h)
- [production native bridge source](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/cjgui_native_bridge.m)
- [runtime package config](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/cjpm.toml)
- [FFI syntax / link planning owner](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_native_bridge_ffi_link.cj)
- 仓颉 `foreign func` 与 `cjpm` FFI 文档、现有 `labs/cffi_smoke` 证据。

## 预检判断

isolated direct `cjc` link 证据足够推进到 package-adjacent probe，但不足以直接修改 `runtime/cjgui/cjpm.toml`。

当前 `cjpm.toml` 只声明 `runtime/cjgui` 的 static package 元数据，没有 `[ffi.c]`、`link-option`、`compile-option` 或 production native skeleton wiring。仓颉工具链文档说明 `[ffi.c]` 可指向 C 库目录，`link-option` 可传递链接选项，但本项目尚未证明这些配置能以 macOS-only / non-macOS fallback 的方式安全承载 Objective-C skeleton object。因此本轮不直接改 package config。

本轮第一刀选择 package-adjacent probe：在 `runtime/cjgui` 语境中构建 production skeleton object / static archive，并用临时仓颉 `foreign func` caller 通过 direct `cjc -L ... -l ...` 链接验证四个 no-resource callable。该 probe 证明 package 附近的 link route 可复核，但不等同于 `cjpm` package integration。

## 候选取舍

- A 选择：`P1 internal Renderer native bridge package link probe bundle`。
- B 暂缓：`P1 internal Renderer native bridge package link first integration bundle`。
- C 暂缓：`P1 internal Renderer native bridge package link blocker follow-up`。
- D 拒绝：public API / resource callable / native object / Metal / AppKit。

选择 A 的理由：

- direct `cjc` evidence 已证明 no-resource callable 可以被仓颉 `foreign func` 调用。
- runtime package config 的 macOS-only / non-macOS fallback 仍需下一步单独 preflight。
- package-adjacent probe 可以在不改 `cjpm.toml` 的前提下证明 object / archive / link route。
- 本轮仍保持 internal-only，不新增 runtime FFI call，也不把 package link 解释成 backend-ready。

## 允许写集

- 新增 `runtime/cjgui/native/scripts/verify_native_bridge_package_link_probe.sh`。
- 新增 `runtime/cjgui/src/runtime_renderer_native_bridge_package_link.cj`。
- 新增本阶段 docs、closure、manifest 与 topic manifest 同步。

## 禁止写集

- 不修改 `runtime/cjgui/cjpm.toml`。
- 不修改 package / build config。
- 不修改 production native callable behavior。
- 不修改 `labs/macos_bridge_smoke/native/*`。
- 不修改 `runtime/cjgui/src/runtime_state.cj`。
- 不新增 public API / diagnostics。
- 不新增 runtime FFI call。

## 同形边界刹车

不得把 package-adjacent probe、direct `cjc` evidence、FFI syntax evidence、no-resource callable、symbol probe 或 planning facts 包装成 public API permission、resource callable permission、native object permission、Metal / AppKit permission、backend-ready permission、GPU-submission permission、render permission、renderer-state-write permission、receipt、record 或 publication。

Package link route evidence 只证明 no-resource native bridge linkage path 可复核，不证明 GUI backend ready。

## 后续入口

若 package-adjacent probe 与 owner build 通过，本阶段继续进入 stage closure、next-boundary decision 与 manifest stabilization。预计下一步不直接进入 public API 或 resource callable，而是判断是否需要真正的 `cjpm` package link implementation preflight。

## 设计意图出口自检

- 本轮是否改变主题状态：是，native bridge package link integration 从 preflight opening 推进到 package-adjacent probe 路线。
- 本轮是否改变 canonical tail / endpoint：预检本身不新增 endpoint；后续 value boundary 会新增 package link planning endpoint。
- 本轮是否改变 owner / truth / stop-line：预检确认下一步允许新增 package link planning owner；truth 仅限 package-adjacent probe evidence；stop-line 继续禁止 runtime FFI call、public API 与 native resource。
- 本轮是否改变唯一 next opening：是，本阶段先进入 package link probe / value boundary。
- 是否同步 topic manifest：是，本阶段后续统一同步。
- 已同步哪些 topic manifest：将在 stage manifest stabilization 后同步 `docs/plans/topic-manifests/renderer-implementation-admission-chain.md`、`docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md`、`docs/plans/topic-manifests/macos-bridge-verification-smoke.md`。

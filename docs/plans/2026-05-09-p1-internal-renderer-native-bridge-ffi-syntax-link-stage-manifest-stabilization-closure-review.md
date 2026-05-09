# P1 内部渲染器 native bridge FFI 语法与链接阶段清单稳定化复核

日期：2026-05-09

状态：closure review / manifest stabilization

## 文件定位

本复核确认 native bridge FFI syntax / link stage 清单已封账，并记录验证、边界与设计意图出口自检。

## 封账内容

- Isolated FFI probe 已新增并通过。
- Runtime planning owner 已新增并通过 `cjpm build`。
- 清单已固定 owner、runtime input、canonical endpoint、default draft、allowed callable list、forbidden callable list、runtime package link status 与 stop-line。
- 唯一后续入口已改为 `P1 internal Renderer native bridge package link integration preflight decision`。

## 关键证据

- `labs/native_bridge_ffi_probe/scripts/build_and_run.sh` 通过。
- `runtime/cjgui/src/runtime_renderer_native_bridge_ffi_link.cj` 编译通过。
- 当前 runtime package link 仍未接入 production `.m`，这是预期边界，不是漏测。

## 边界保持

- 未新增 public API / diagnostics。
- 未修改 `runtime/cjgui/cjpm.toml`。
- 未修改 package / build config。
- 未修改 `runtime/cjgui/src/runtime_state.cj`。
- 未修改 smoke native files。
- 未新增 resource callable。
- 未创建 native object、native handle、raw pointer。
- 未返回 native pointer。
- 未导入 Cocoa / Metal / QuartzCore 到 production bridge。
- 未提交 GPU work、未执行 render、未写 renderer state。
- 未创建 backend-ready truth。

## 后续风险

下一阶段需要单独判断 package link integration：

- 是否使用 `cjpm.toml` 的 `[ffi.c]`。
- 是否需要独立 native build artifact。
- macOS-only gating 如何表达。
- non-macOS fallback 如何保持 clean。
- runtime internal FFI declaration 是否必须等 package link 完成后再写。

## 下游接续

下游 [native bridge package link integration stage manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-package-link-integration-stage-manifest.md) 与 [manifest 稳定化复核](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-internal-renderer-native-bridge-package-link-integration-stage-manifest-stabilization-closure-review.md) 已完成。该下游只把 isolated FFI probe 的 direct `cjc` link 证据推进为 `runtime/cjgui` 语境旁路 package-adjacent probe，不修改 `runtime/cjgui/cjpm.toml`，不接入 production `.m` 到 `cjpm build`，不新增 runtime FFI call、native object、native handle、raw pointer、renderer state write 或 public API。

当前唯一后续入口已由下游改为 `P1 internal Renderer native bridge cjpm package link implementation preflight decision`。

## 同形边界刹车

不得把本 manifest、isolated probe success、`foreign func` syntax evidence、direct `cjc` link evidence、runtime planning endpoint 或 no-resource callable 包装成 public API permission、runtime FFI call permission、package integration permission、resource callable permission、native object permission、Metal / AppKit permission、backend-ready permission、receipt、record 或 publication。

## 设计意图出口自检

- 本轮是否改变主题状态：是，FFI syntax / link stage 已完成 manifest stabilization。
- 本轮是否改变 canonical tail / endpoint：是，当前 endpoint 固定为 `CjguiInternalRendererNoNativeBridgeFfiLinkReadiness`。
- 本轮是否改变 owner / truth / stop-line：是，owner 为 `runtime/cjgui/src/runtime_renderer_native_bridge_ffi_link.cj`；truth 仅限 syntax / link planning 与 fallback；stop-line 继续禁止 runtime call、public API 与 native resource。
- 本轮是否改变唯一 next opening：是，改为 `P1 internal Renderer native bridge package link integration preflight decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`docs/plans/topic-manifests/renderer-implementation-admission-chain.md`、`docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md`、`docs/plans/topic-manifests/macos-bridge-verification-smoke.md`。

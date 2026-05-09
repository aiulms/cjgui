# P1 内部渲染器 native bridge runtime internal FFI declaration 第一实现清单稳定化复核

日期：2026-05-09

状态：manifest stabilization closure / stop after manifest

## 封账结论

[runtime internal FFI declaration first implementation manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-runtime-internal-ffi-declaration-first-implementation-manifest.md) 已封账。

本阶段只新增 internal `foreign func` declaration owner，不新增 runtime FFI call，不修改 package config，不修改 production native behavior，不新增 public API，不创建 native object。

本阶段同时对 package-adjacent probe 脚本补充 probe-only `libcangjie-runtime.dylib` 搜索路径，避免临时 direct `cjc` probe 执行时因运行期库缺失而误报。该改动不修改 `runtime/cjgui/cjpm.toml`，不改变 production native callable 行为，也不进入 runtime 主包 link。

## 固定 endpoint

- Owner：`runtime/cjgui/src/runtime_renderer_native_bridge_runtime_ffi_declaration.cj`
- Runtime input：`CjguiInternalRendererNoNativeBridgeCjpmPackageLinkReadiness`
- Endpoint：`CjguiInternalRendererNoNativeBridgeRuntimeFfiCallReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererNativeBridgeRuntimeFfiDeclarationDraft()`

## 固定边界

- 已声明四个 no-resource `foreign func`。
- 未调用这些 `foreign func`。
- `runtime/cjgui/cjpm.toml` 未修改。
- production native `.h` / `.m` 行为未修改。
- `verify_native_bridge_package_link_probe.sh` 只修 probe runtime library path。
- smoke native files 未修改。
- public API allowlist 不变。
- `runtime_state.cj` 未触碰。

## 后续入口

`P1 internal Renderer native bridge internal no-resource FFI call verification bundle`

下一步必须单独证明 internal no-resource call verification owner、package link route、failure classification 与 no-public-surface 仍然成立；不得直接进入 resource callable、native object、Metal / AppKit 或 public API。

## 下游接续记录

下游 [no-resource FFI call verification manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-no-resource-ffi-call-verification-manifest.md) 与 [manifest closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-internal-renderer-native-bridge-no-resource-ffi-call-verification-manifest-stabilization-closure-review.md) 已完成。该下游选择 runtime-adjacent probe route，未新增 runtime owner call，未修改 `runtime/cjgui/cjpm.toml`，并把唯一后续入口改为 `P1 internal Renderer native bridge runtime package link call support preflight decision`。

## 同形边界刹车

不得把本 manifest、internal declaration、script-managed package link evidence、isolated FFI probe 或 symbol probe 包装成 runtime FFI call permission、public API permission、resource callable permission、native object permission、Metal / AppKit permission、backend-ready permission、GPU-submission permission、render permission、renderer-state-write permission、receipt、record 或 publication。

## 设计意图出口自检

- 本轮是否改变主题状态：是，runtime internal FFI declaration first implementation 已封账。
- 本轮是否改变 canonical tail / endpoint：是，当前 latest endpoint 为 `CjguiInternalRendererNoNativeBridgeRuntimeFfiCallReadiness`。
- 本轮是否改变 owner / truth / stop-line：是，新增 owner；truth 限于 internal declaration / no-call facts；stop-line 不变。
- 本轮是否改变唯一 next opening：是，转为 `P1 internal Renderer native bridge internal no-resource FFI call verification bundle`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`docs/plans/topic-manifests/renderer-implementation-admission-chain.md`、`docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md`、`docs/plans/topic-manifests/macos-bridge-verification-smoke.md`。

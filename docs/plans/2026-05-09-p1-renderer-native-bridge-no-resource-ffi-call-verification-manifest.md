# P1 渲染器 native bridge no-resource FFI call verification 清单

日期：2026-05-09

状态：manifest stabilization / runtime-adjacent observed call evidence

## 文件定位

本 manifest 固定 internal no-resource FFI call verification stage 的 actual route、actual write set、called function list、observed facts、package link status、truth 与 stop-line。

本 manifest 不批准 public API，不批准 runtime owner call，不批准 resource callable，不批准 native object，不批准 Metal / AppKit，不批准 renderer state write，也不批准 backend-ready truth。

## 实际路线

Actual route：runtime-adjacent probe。

本阶段没有新增 `runtime_renderer_native_bridge_no_resource_call.cj`，也没有把 FFI call 写进 `runtime/cjgui` 主包 owner。原因是 `runtime/cjgui/cjpm.toml` 仍未接入 production native static archive，主包尚无真实 package call support。

本阶段新增 probe：

- `runtime/cjgui/native/scripts/verify_native_bridge_no_resource_call_probe.sh`

该 probe 先检查 runtime declaration owner，再运行 script-managed temporary `cjpm` package link probe，实际调用四个 no-resource C ABI，并解析 observed facts。

## 实际写集

- `runtime/cjgui/native/scripts/verify_native_bridge_no_resource_call_probe.sh`
- `docs/plans/2026-05-09-p1-renderer-native-bridge-internal-no-resource-ffi-call-verification-preflight-decision.md`
- `docs/plans/2026-05-09-p1-internal-renderer-native-bridge-no-resource-ffi-call-verification-closure-review.md`
- `docs/plans/2026-05-09-p1-renderer-native-bridge-no-resource-ffi-call-verification-next-boundary-decision.md`

## 被调用 callable

runtime-adjacent probe 实际调用：

- `cjgui_native_bridge_surface_version`
- `cjgui_native_bridge_surface_capabilities`
- `cjgui_native_bridge_status_ok`
- `cjgui_native_bridge_no_resource_admission`

## 观察事实

本阶段允许记录的 observed facts：

- `runtime_foreign_declarations_observed=true`
- `runtime_adjacent_probe_route=true`
- `runtime_owner_call=false`
- `surface_version_observed=true`
- `capabilities_observed=true`
- `status_ok_observed=true`
- `no_resource_admission_observed=true`
- `runtime_package_config_modified=false`
- `public_api_modified=false`
- `resource_callable_invoked=false`
- `native_object_created=false`

这些 facts 只能用于证明 side-effect-free no-resource interop 可复核。它们不证明 `runtime/cjgui` 主包可直接执行 FFI call。

## 当前 runtime endpoint

本阶段没有新增 runtime endpoint。

- 当前 declaration endpoint：`CjguiInternalRendererNoNativeBridgeRuntimeFfiCallReadiness`
- 当前 declaration default draft：`cjguiInternalExecuteDefaultRendererNativeBridgeRuntimeFfiDeclarationDraft()`
- 当前 runtime input：`CjguiInternalRendererNoNativeBridgeCjpmPackageLinkReadiness`

## Package link 状态

- `runtime/cjgui/cjpm.toml` 未修改。
- production `.m` 未接入 `runtime/cjgui` 主包。
- no-resource callable 通过 temporary `cjpm` package link probe 调用。
- 主包 runtime package call support 尚未打开。

## 停止线

- no public API。
- no public diagnostics。
- no runtime owner FFI call。
- no resource callable。
- no native object / handle / raw pointer。
- no native pointer return。
- no Cocoa / Metal / QuartzCore import in production bridge。
- no AppKit / Metal object creation。
- no retain / release / destroy。
- no drawable / command buffer / `commit` / `present`。
- no GPU submission。
- no render execution。
- no renderer state write。
- no `runtime_state.cj` modification。
- no smoke native edits。
- no backend-ready truth。

## 同形边界刹车

不得把 no-resource FFI call verification probe、observed facts、runtime declaration owner、package link probe 或 native symbol probe 包装成 runtime package call support、public API permission、resource callable permission、native object permission、Metal / AppKit permission、backend-ready permission、GPU-submission permission、render permission、renderer-state-write permission、receipt、record 或 publication。

No-resource call verification 只证明 runtime-adjacent side-effect-free interop，不证明 GUI backend ready。

## 后续入口

`P1 internal Renderer native bridge runtime package link call support preflight decision`

## 下游接续

已由 [runtime package link call support manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-runtime-package-link-call-support-manifest.md) 接续。下游新增 `CjguiInternalRendererNoNativeBridgePackageCallSupportReadiness` / `cjguiInternalExecuteDefaultRendererNativeBridgePackageCallSupportDraft()`，但仍只表达 package call support / blocker facts，不做 actual runtime FFI call，不修改 `runtime/cjgui/cjpm.toml`，不接入 production `.m` 到主包。

后续若要把 no-resource call 从 runtime-adjacent probe 推进到 runtime owner call，仍必须先证明 `runtime/cjgui` package config link support、macOS-only fallback、non-macOS fail-closed、failure classification 与 no-public-surface 均可维持。

## 设计意图出口自检

- 本轮是否改变主题状态：是，no-resource FFI call verification 已完成 runtime-adjacent observed call evidence 并 manifest stabilization。
- 本轮是否改变 canonical tail / endpoint：否，本轮不新增 runtime endpoint；`CjguiInternalRendererNoNativeBridgeRuntimeFfiCallReadiness` 仍是 declaration endpoint。
- 本轮是否改变 owner / truth / stop-line：是，新增 probe script；truth 增加 runtime-adjacent observed call facts；stop-line 继续禁止 public API、resource callable、native object、Metal / AppKit、renderer state write 与 backend-ready truth。
- 本轮是否改变唯一 next opening：是，转为 `P1 internal Renderer native bridge runtime package link call support preflight decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`docs/plans/topic-manifests/renderer-implementation-admission-chain.md`、`docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md`、`docs/plans/topic-manifests/macos-bridge-verification-smoke.md`。

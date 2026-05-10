# P1 渲染器 native bridge package config link 路线对账扫描

日期：2026-05-09

状态：docs-only reconciliation scan / no runtime edits

## 文件定位

本扫描对 native bridge no-resource callable、FFI declaration、FFI syntax / link、runtime-adjacent call probe、package call support 与 package config link 这一段做阶段性对账。

本扫描不修改 `.cj`、native files、scripts 或 `runtime/cjgui/cjpm.toml`，不运行 `cjpm build` / smoke，不触碰 protected paths，不改变 runtime truth，也不批准 actual runtime FFI call、public API、resource callable、native object、Metal / AppKit 或 backend-ready truth。

## 完整证据链

从 callable `C ABI` 到 package config link 的当前证据链如下：

1. no-resource callable `C ABI` 已在 production native skeleton 中实现，只包含 `cjgui_native_bridge_surface_version`、`cjgui_native_bridge_surface_capabilities`、`cjgui_native_bridge_status_ok` 与 `cjgui_native_bridge_no_resource_admission` 四个 deterministic `uint32_t` 函数。
2. symbol probe 已验证四个 no-resource callable 的 object-level symbol presence，并确认 forbidden symbol / forbidden import 未出现。
3. isolated FFI probe 已证明仓颉 `foreign func` 语法可声明并通过 direct `cjc` link 调用这四个 no-resource callable。
4. package-adjacent link probe 已证明 production no-resource native bridge object / static archive 可在 `runtime/cjgui` 语境旁路 direct `cjc` link 调用。
5. script-managed temporary `cjpm` package link probe 已证明 no-resource static archive 可由临时仓颉 package 的 `compile-option` / `link-option` 通过 `cjpm run --skip-script` 链接调用。
6. runtime internal FFI declaration owner 已存在，并在 `runtime_renderer_native_bridge_runtime_ffi_declaration.cj` 中声明四个 internal-only no-resource `foreign func`。
7. runtime-adjacent no-resource call probe 已通过临时 package 调用四个 no-resource callable，并观察到 `surface_version_observed`、`capabilities_observed`、`status_ok_observed` 与 `no_resource_admission_observed` facts。
8. package call support facts 已由 `CjguiInternalRendererNoNativeBridgePackageCallSupportReadiness` 固定，明确主包 actual runtime call 仍 blocked，证据仍是 runtime-adjacent route。
9. package config link facts 已由 `CjguiInternalRendererNoNativeBridgePackageConfigLinkReadiness` 固定，当前路线是 script-managed route stabilization，`runtime/cjgui/cjpm.toml` 仍 deferred。

## 当前未落地事实

本扫描确认当前没有以下能力或权限：

- 没有 actual runtime FFI call owner。
- 没有 public API。
- 没有 public diagnostics。
- 没有 resource callable。
- 没有 native object / handle / raw pointer。
- 没有 native pointer return。
- 没有 Metal / AppKit / Cocoa / QuartzCore import 或对象创建。
- 没有 retain / release / destroy。
- 没有 drawable / command buffer / `commit` / `present`。
- 没有 GPU submission。
- 没有 render execution。
- 没有 renderer state write。
- 没有 `runtime_state.cj` write。
- 没有 `runtime/cjgui/cjpm.toml` package config integration。
- 没有 production `.m` 接入 `runtime/cjgui` 主包。
- 没有 backend-ready truth。

## 端点链对账

当前 endpoint chain 一致，未发现命名冲突或同一 truth 被两个 endpoint 重复拥有：

1. `CjguiInternalRendererNoCallableCAbiReadiness`：callable naming / status-capability admission / no-resource callable guard / FFI separation facts。
2. `CjguiInternalRendererNoNativeBridgeFfiDeclarationReadiness`：旧 runtime integration stage 的 FFI declaration planning facts 与 no-resource callable allowlist，不是真实 declaration permission。
3. `CjguiInternalRendererNoNativeBridgeFfiLinkReadiness`：isolated FFI syntax / direct link evidence，不是 runtime package link permission。
4. `CjguiInternalRendererNoNativeBridgePackageLinkReadiness`：package-adjacent link evidence，不是 `cjpm.toml` mutation permission。
5. `CjguiInternalRendererNoNativeBridgeCjpmPackageLinkReadiness`：script-managed temporary `cjpm` package link evidence，不是 runtime FFI call permission。
6. `CjguiInternalRendererNoNativeBridgeRuntimeFfiCallReadiness`：internal-only `foreign func` declarations 与 no-runtime-call facts，不是 actual runtime FFI call permission。
7. `CjguiInternalRendererNoNativeBridgePackageCallSupportReadiness`：runtime-adjacent observed call evidence 与 package call support blocker facts，不是 runtime package call support readiness。
8. `CjguiInternalRendererNoNativeBridgePackageConfigLinkReadiness`：script-managed route、artifact policy、package config still-deferred facts，不是 package config integration permission。

`CjguiInternalRendererNoNativeBridgePackageConfigLinkReadiness` 是当前 docs / owner 链的最新 tail，但它只表达 route stabilization 和 blocker facts，不改变真实 native resource bridge tail，也不创建 runtime bridge ready truth。

## 重复包装扫描

本扫描未发现以下问题：

- 未发现 duplicate truth：每个 endpoint 对应的 truth 层级仍然不同，分别覆盖 callable、declaration planning、syntax / link evidence、package-adjacent link、temporary `cjpm` link、internal declaration、package call support blocker 与 package config deferred facts。
- 未发现 self-wrapping：`package config link` owner 消费 `package call support` facts，没有再次消费自己或把自身结果包装成新 readiness。
- 未发现 same-shape wrapper：最新 owner 新增的是 package config still-deferred、script-managed fallback、artifact policy 与 skip-script artifact risk 语义，不是薄包装上一轮 package call support。
- 未发现 receipt / record / publication 误写：manifest 与 topic manifest 均明确这些 facts 不是 public API、runtime call、backend-ready 或 runtime bridge ready truth。

仍需注意：旧文档中 `package config link` 字样容易被误读成正式 package config integration；本扫描将其收束为 script-managed route stabilization，而不是 `runtime/cjgui/cjpm.toml` mutation。

## 导航一致性

本轮同步前，README、tracker、plans README、runtime README、`DESIGN_INTENT_INDEX.md` 与 topic manifests 的唯一 next opening 均指向：

`P1 internal Renderer native bridge package config link route reconciliation scan`

本轮同步后，唯一 next opening 应统一转为：

`P1 internal Renderer native bridge internal no-resource runtime FFI call owner preflight decision`

该入口只是下一轮 docs-first preflight，不批准直接实现 runtime call owner。下一轮必须重新判断 package link、dylib / object path、`runtime/cjgui/cjpm.toml` 是否仍是 blocker；若主包 link 不足，必须停在 blocker / follow-up，不得硬写 actual runtime call。

## 候选结论

结论选择 A：

`P1 internal Renderer native bridge internal no-resource runtime FFI call owner preflight decision`

选择理由：

- 证据链从 no-resource callable 到 package config still-deferred facts 已完整。
- 当前 remaining risk 已被窄化为 actual runtime owner call 的 link / package config / platform fallback 问题。
- script-managed route 与 package config integration 的边界已被明确区分。
- 没有发现 duplicate truth、self-wrapping、same-shape wrapper 或 next opening 分歧。
- 继续新增 link-readiness wrapper 会变成同构 wrapper，应拒绝。

保留限制：

- A 不是 implementation permission。
- A 不批准 public API。
- A 不批准 resource callable。
- A 不批准 native object / handle / pointer。
- A 不批准 Metal / AppKit。
- A 不批准 backend-ready truth。
- A 不批准 renderer state write。
- A 不批准现在修改 `runtime/cjgui/cjpm.toml`。

## 停止线

- 不把 script-managed link route 包装成 package config integration。
- 不把 runtime-adjacent call probe 包装成 actual runtime FFI call。
- 不把 internal `foreign func` declaration 包装成 runtime bridge ready。
- 不把 package call support facts 包装成 public API、resource callable、native object、Metal / AppKit、backend-ready 或 renderer-state-write permission。
- 不继续新增同构 link-readiness wrapper。

## 设计意图出口自检

- 本轮是否改变主题状态：是，package config link route reconciliation 已完成，证据链从 callable `C ABI` 到 package config still-deferred facts 对账一致。
- 本轮是否改变 canonical tail / endpoint：否，当前 tail 仍是 `CjguiInternalRendererNoNativeBridgePackageConfigLinkReadiness` / `cjguiInternalExecuteDefaultRendererNativeBridgePackageConfigLinkDraft()`。
- 本轮是否改变 owner / truth / stop-line：否，没有新增 runtime owner；truth 仍限于 script-managed route、package config still-deferred、runtime-adjacent evidence 与 no-runtime-call facts；stop-line 继续禁止 runtime call、public API、resource callable、native object、Metal / AppKit、renderer state write 与 backend-ready truth。
- 本轮是否改变唯一 next opening：是，转为 `P1 internal Renderer native bridge internal no-resource runtime FFI call owner preflight decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`docs/plans/topic-manifests/renderer-implementation-admission-chain.md`、`docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md`、`docs/plans/topic-manifests/macos-bridge-verification-smoke.md`。

## 下游接续

下游 [no-resource runtime FFI call owner manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-no-resource-runtime-ffi-call-owner-manifest.md) 已完成。该阶段新增 `runtime/cjgui/src/runtime_renderer_native_bridge_no_resource_call.cj`，将 canonical endpoint 推进为 `CjguiInternalRendererNoNativeBridgeNoResourceRuntimeCallReadiness` / `cjguiInternalExecuteDefaultRendererNativeBridgeNoResourceRuntimeCallDraft()`，并只把四个 no-resource C ABI 的返回值脱水成 internal facts。该下游不改变本扫描的历史结论：script-managed package config route 不等于 `runtime/cjgui/cjpm.toml` integration，不等于 public API、resource callable、native object、Metal / AppKit、renderer state write 或 backend-ready truth。

下游 [NSView runtime FFI call owner manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-platform-object-nsview-runtime-ffi-call-owner-manifest.md) 也已完成。该阶段继续沿用 script-managed / runtime-adjacent package link evidence 复核 token-backed `NSView` C ABI，不修改 `runtime/cjgui/cjpm.toml`，不把 package config link route 解释成 public API、pointer surface、window / layer / Metal、renderer state write 或 backend-ready truth。

后续 [main-thread no-resource callable manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-main-thread-no-resource-callable-manifest.md) 也已完成，将 endpoint 推进为 `CjguiInternalRendererNoNativeBridgeMainThreadCallReadiness` / `cjguiInternalExecuteDefaultRendererNativeBridgeMainThreadCallDraft()`。该阶段仍沿用 no-resource / script-managed evidence 边界，只增加 current-thread classification facts，不改变本扫描对 package config route 的判断。

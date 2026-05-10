# P1 渲染器 platform object NSView runtime FFI call owner 清单

日期：2026-05-10

状态：manifest stabilization / first slice

## 清单结论

`NSView` runtime FFI call owner first slice 已封账。Actual route 是 runtime internal owner + runtime-adjacent probe：owner 复用同 package 已存在且已通过 build 的 `foreign func` declarations，执行局部 `NSView` create / classify / destroy lifecycle，并把结果脱水成 internal-only facts。

该清单不改变 `runtime/cjgui/cjpm.toml`。Package config link 仍是 script-managed / runtime-adjacent 证据，不是 `cjpm.toml` package config integration。

## Runtime owner

- Owner：`runtime/cjgui/src/runtime_renderer_platform_object_nsview_runtime_call.cj`
- Endpoint：`CjguiInternalRendererNoPlatformObjectNsViewRuntimeCallReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererPlatformObjectNsViewRuntimeCallDraft()`
- Runtime input：`CjguiInternalRendererNoPlatformObjectNsViewCreateDestroyReadiness`

## Reused C ABI declarations

本轮不新增重复 declaration，复用上游 owner 内同 package declarations：

- `cjgui_native_bridge_nsview_create(outToken: CPointer<UInt64>): Int32`
- `cjgui_native_bridge_nsview_destroy(token: UInt64): Int32`
- `cjgui_native_bridge_nsview_token_classify(token: UInt64): Int32`
- `cjgui_native_bridge_nsview_table_occupied_count(): UInt32`
- `cjgui_native_bridge_nsview_double_destroy_classify(token: UInt64): Int32`
- `cjgui_native_bridge_nsview_destroy_requires_main_thread(): Int32`

## Observed facts

- create observed。
- opaque token observed and stayed function-local。
- classify valid observed。
- occupied count lifecycle `0 -> 1 -> 0` observed。
- destroy observed。
- destroyed token stale observed。
- double destroy fail-closed observed。
- invalid token fail-closed observed。
- destroy requires main thread classification observed。
- no pointer / handle / `id` / `Class` return observed by source/probe scan。
- no `NSWindow` / `NSApplication` / `CALayer` / `CAMetalLayer` observed by source/probe scan。
- no Metal / QuartzCore observed by source/probe scan。
- no public surface and no renderer state write。

## Probe scripts

本轮新增：

- `runtime/cjgui/native/scripts/verify_native_bridge_nsview_runtime_call.sh`

该 probe 通过 temporary `cjpm` package 调用 production native bridge static archive，并复核 create / classify / destroy / occupied-count / stale / double-destroy / invalid-token / main-thread-destroy-gate facts。它不修改 `runtime/cjgui/cjpm.toml`，不把 temporary package route 解释成 package config integration。

本阶段仍要求继续通过上游 probes：

- `runtime/cjgui/native/scripts/verify_native_bridge_nsview_create_destroy.sh`
- `runtime/cjgui/native/scripts/verify_native_bridge_nsview_object_table.sh`
- `runtime/cjgui/native/scripts/verify_native_bridge_nsview_allocation_feasibility.sh`
- `runtime/cjgui/native/scripts/verify_native_bridge_platform_object_no_object_creation.sh`
- `runtime/cjgui/native/scripts/verify_native_bridge_appkit_import.sh`
- `runtime/cjgui/native/scripts/verify_native_bridge_appkit_class_availability.sh`
- `runtime/cjgui/native/scripts/verify_native_bridge_appkit_main_thread_admission.sh`
- `runtime/cjgui/native/scripts/verify_native_bridge_teardown_admission.sh`
- `runtime/cjgui/native/scripts/verify_native_bridge_token_issue_revoke.sh`
- `runtime/cjgui/native/scripts/verify_native_bridge_no_resource_call_probe.sh`
- `runtime/cjgui/native/scripts/verify_native_bridge_package_link_probe.sh`
- `runtime/cjgui/native/scripts/verify_native_bridge_cjpm_package_link_probe.sh`
- `runtime/cjgui/native/scripts/verify_native_bridge_skeleton_compile.sh`
- `runtime/cjgui/native/scripts/verify_native_bridge_no_resource_symbols.sh`
- `runtime/cjgui/native/scripts/verify_native_bridge_cjpm_integration_boundary.sh`

## 固定边界

- no public API / diagnostics。
- no token public exposure。
- no persistent token storage。
- no pointer / handle / `id` / `Class` return。
- no `NSWindow` / `NSApplication` / `CALayer` / `CAMetalLayer`。
- no Metal / QuartzCore。
- no renderer state write。
- no `runtime_state.cj` touch。
- no `runtime/cjgui/cjpm.toml` mutation。
- no smoke native edits。
- no backend-ready truth。
- no GPU submission / render execution。

## 文档链

- [preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-platform-object-nsview-runtime-ffi-call-owner-preflight-decision.md)
- [closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-internal-renderer-platform-object-nsview-runtime-ffi-call-owner-stage-closure-review.md)
- [next-boundary](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-platform-object-nsview-runtime-ffi-call-owner-next-boundary-decision.md)
- [NSView create/destroy manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-platform-object-token-backed-nsview-create-destroy-first-slice-manifest.md)
- [NSView object table manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-platform-object-token-backed-nsview-object-table-manifest.md)
- [runtime internal FFI declaration manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-runtime-internal-ffi-declaration-first-implementation-manifest.md)
- [package config link route reconciliation scan](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-package-config-link-route-reconciliation-scan.md)

## 后续入口

唯一后续入口：

`P1 internal Renderer platform object NSView renderer backend shell integration preflight decision`

## 下游接续

下游 [NSView backend shell integration manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-platform-object-nsview-backend-shell-integration-manifest.md) 已完成。该阶段新增 [runtime_renderer_backend_nsview_platform_integration.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_backend_nsview_platform_integration.cj)，固定 `CjguiInternalRendererNoBackendNsViewPlatformIntegrationReadiness` / `cjguiInternalExecuteDefaultRendererBackendNsViewPlatformIntegrationDraft()`，只把本清单的 runtime-call facts 接入 backend shell integration facts。该下游不新增 native C ABI，不修改 `runtime/cjgui/cjpm.toml`，不创建 `CAMetalLayer` / `CALayer` / Metal resource，不写 renderer state，不新增 public API，也不创建 backend-ready truth；最新唯一 next opening 转为 `P1 internal Renderer CAMetalLayer attachment planning preflight decision`。

## 设计意图出口自检

- 本轮是否改变主题状态：是，新增 runtime internal `NSView` FFI call owner first slice。
- 本轮是否改变 canonical tail / endpoint：是，固定 `CjguiInternalRendererNoPlatformObjectNsViewRuntimeCallReadiness` / `cjguiInternalExecuteDefaultRendererPlatformObjectNsViewRuntimeCallDraft()`。
- 本轮是否改变 owner / truth / stop-line：是，owner 固定为 `runtime_renderer_platform_object_nsview_runtime_call.cj`；truth 固定为 internal runtime-call dehydrated facts；stop-line 固定为 no public / no pointer / no window / no layer / no Metal / no renderer state / no backend-ready。
- 本轮是否改变唯一 next opening：是，转为 `P1 internal Renderer platform object NSView renderer backend shell integration preflight decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。

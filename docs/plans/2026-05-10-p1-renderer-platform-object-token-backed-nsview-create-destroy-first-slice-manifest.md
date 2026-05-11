# P1 内部渲染器 platform object token-backed NSView create destroy 首片清单

日期：2026-05-10

状态：manifest stabilization / first slice

## 清单结论

token-backed `NSView` create / destroy first slice 已封账，actual route 是 production native C ABI + runtime internal owner + probe/link evidence。Production bridge 现在可以在 main thread 创建固定容量 table 内的 `NSView`，通过 opaque token 分类并销毁；仓颉层不接收 pointer、handle、`id` 或 `Class`。

该清单不批准 `NSWindow` / `NSApplication` / `CALayer` / `CAMetalLayer`，不批准 Metal / QuartzCore，不批准 public API，不批准 renderer state write，不批准 render execution，不批准 backend-ready truth。

## Native callable list

- `cjgui_native_bridge_nsview_create(uint64_t* out_token)` -> `int32_t`
- `cjgui_native_bridge_nsview_destroy(uint64_t token)` -> `int32_t`
- `cjgui_native_bridge_nsview_token_classify(uint64_t token)` -> `int32_t`
- `cjgui_native_bridge_nsview_table_occupied_count(void)` -> `uint32_t`
- `cjgui_native_bridge_nsview_double_destroy_classify(uint64_t token)` -> `int32_t`
- `cjgui_native_bridge_nsview_destroy_requires_main_thread(void)` -> `int32_t`

## Runtime owner

- Owner：`runtime/cjgui/src/runtime_renderer_platform_object_nsview_create_destroy.cj`
- Endpoint：`CjguiInternalRendererNoPlatformObjectNsViewCreateDestroyReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererPlatformObjectNsViewCreateDestroyDraft()`
- Runtime input：`CjguiInternalRendererNoPlatformObjectNsViewObjectTableReadiness`
- Actual route：internal runtime owner 调用 production C ABI 并脱水为 facts。

Observed facts：

- main-thread create observed。
- token classify valid observed。
- occupied count `0 -> 1 -> 0` observed。
- destroy observed。
- destroyed token stale observed。
- double destroy fail-closed observed。
- invalid token fail-closed observed。
- destroy requires main thread classification observed。
- token not pointer observed。
- no pointer / handle / `id` / `Class` return observed by source/probe scan。

## Probe scripts

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

## Actual write set

- `runtime/cjgui/native/cjgui_native_bridge.h`
- `runtime/cjgui/native/cjgui_native_bridge.m`
- `runtime/cjgui/src/runtime_renderer_platform_object_nsview_create_destroy.cj`
- `runtime/cjgui/native/scripts/verify_native_bridge_nsview_create_destroy.sh`
- Native probe allowlist / link compatibility / package link / no-resource call scripts
- README / tracker / plans README / runtime README / design intent index / topic manifests
- 本阶段 preflight、closure、next-boundary、manifest 与 manifest closure

`runtime/cjgui/cjpm.toml` 未修改。Smoke native files 未修改。`runtime_state.cj` 未修改。

## 固定边界

- token 只是不透明整数，不编码 native pointer。
- fixed capacity 为 `4`。
- create / destroy 只允许 main thread。
- stale / double-destroy / invalid-token fail-closed。
- no pointer / handle / `id` / `Class` return。
- no `NSWindow` / `NSApplication` / `CALayer` / `CAMetalLayer`。
- no Metal / QuartzCore import。
- no layer binding / drawable / command buffer / GPU submission。
- no renderer state write。
- no public API / diagnostics。
- no backend-ready truth。

## 文档链

- [preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-platform-object-token-backed-nsview-create-destroy-first-slice-preflight-decision.md)
- [closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-internal-renderer-platform-object-token-backed-nsview-create-destroy-first-slice-closure-review.md)
- [next-boundary](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-platform-object-token-backed-nsview-create-destroy-first-slice-next-boundary-decision.md)
- [NSView object table manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-platform-object-token-backed-nsview-object-table-manifest.md)
- [NSView feasibility manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-platform-object-real-nsview-allocation-manifest.md)
- [no-object creation manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-platform-object-no-object-creation-callable-manifest.md)
- [token issue/revoke manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-native-token-table-no-resource-issue-revoke-manifest.md)
- [teardown admission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-native-bridge-teardown-callable-implementation-manifest.md)

## 后续入口

唯一后续入口：

`P1 internal Renderer platform object NSView runtime FFI call owner preflight decision`

该入口必须继续保持 internal-only，不得扩 public API，不得返回 native identity，不得创建 window/layer/Metal，不得写 renderer state。

## 下游接续

下游 [NSView runtime FFI call owner manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-platform-object-nsview-runtime-ffi-call-owner-manifest.md) 已完成。该阶段新增 [runtime_renderer_platform_object_nsview_runtime_call.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_platform_object_nsview_runtime_call.cj) 与 [verify_native_bridge_nsview_runtime_call.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_native_bridge_nsview_runtime_call.sh)，固定 `CjguiInternalRendererNoPlatformObjectNsViewRuntimeCallReadiness` / `cjguiInternalExecuteDefaultRendererPlatformObjectNsViewRuntimeCallDraft()`，并只把 runtime internal `NSView` create / classify / destroy / occupied-count / stale / double-destroy fail-closed facts 脱水为 internal facts。后续 `NSView` backend integration、`CAMetalLayer` attachment 与 [CAMetalLayer runtime attachment FFI call owner manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-cametallayer-runtime-attachment-ffi-call-owner-manifest.md) 已完成；最新唯一 next opening 转为 `P1 internal Renderer Metal device binding planning preflight decision`。这些下游不改变本清单 stop-line：不授权 public API、pointer / handle / `Class` / `id` return、`NSWindow` / `NSApplication` / Metal resource、renderer state write、GPU submission、render execution 或 backend-ready truth。

## 设计意图出口自检

- 本轮是否改变主题状态：是，token-backed `NSView` create / destroy first slice 已 manifest stabilization。
- 本轮是否改变 canonical tail / endpoint：是，固定 `CjguiInternalRendererNoPlatformObjectNsViewCreateDestroyReadiness` / `cjguiInternalExecuteDefaultRendererPlatformObjectNsViewCreateDestroyDraft()`。
- 本轮是否改变 owner / truth / stop-line：是，owner 固定为 `runtime_renderer_platform_object_nsview_create_destroy.cj`；truth 固定为 token-backed `NSView` lifecycle facts；stop-line 固定为 no pointer / public / window / layer / Metal / renderer state / backend-ready。
- 本轮是否改变唯一 next opening：是，转为 `P1 internal Renderer platform object NSView runtime FFI call owner preflight decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。

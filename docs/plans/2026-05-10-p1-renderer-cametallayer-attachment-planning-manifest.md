# P1 渲染器 CAMetalLayer attachment planning 清单

日期：2026-05-10

状态：manifest stabilization / no-attach value owner

## 清单结论

`CAMetalLayer` attachment planning 已封账。Actual route 是 internal runtime value owner：只消费 `NSView` backend shell integration readiness，固定 `CAMetalLayer` attachment 的前置边界与 fail-closed 分类，但不新增 native C ABI，不 import QuartzCore，不创建或 attach layer，不创建 Metal device，不执行 render。

本 manifest 不把 `NSView` runtime-call evidence、backend shell integration facts 或 layer planning facts 升格为 backend-ready truth。

## Runtime owner

- Owner：`runtime/cjgui/src/runtime_renderer_cametallayer_attachment_planning.cj`
- Endpoint：`CjguiInternalRendererNoCAMetalLayerAttachmentReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererCAMetalLayerAttachmentDraft()`
- Runtime input：`CjguiInternalRendererNoBackendNsViewPlatformIntegrationReadiness`

## 固定 facts

- `CAMetalLayer` attachment intent fixed。
- QuartzCore import requires later preflight。
- QuartzCore import remains blocked in this stage。
- `CAMetalLayer` class availability observation policy fixed。
- class availability probe remains optional and future gated。
- `NSView.layer` attachment still blocked。
- `wantsLayer` mutation still blocked。
- no `CAMetalLayer` / `CALayer` creation。
- no Metal device binding。
- no drawable acquisition。
- main-thread attachment gate preserved。
- detach-before-destroy dependency fixed。
- class unavailable / background thread / invalid `NSView` token / attachment blocked failure classification fixed。
- no public surface / diagnostics。
- no renderer state write。
- no backend-ready truth。

## 上游证据

- [NSView backend shell integration manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-platform-object-nsview-backend-shell-integration-manifest.md)
- [NSView runtime FFI call owner manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-platform-object-nsview-runtime-ffi-call-owner-manifest.md)
- [NSView create/destroy manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-platform-object-token-backed-nsview-create-destroy-first-slice-manifest.md)
- [NSView object table manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-platform-object-token-backed-nsview-object-table-manifest.md)
- [real Metal device-layer shell manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-real-metal-device-layer-first-implementation-slice-manifest.md)
- [teardown admission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-native-bridge-teardown-callable-implementation-manifest.md)
- [token issue/revoke manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-native-token-table-no-resource-issue-revoke-manifest.md)

## Probe 与验证角色

本阶段不新增 CAMetalLayer probe，因为没有新增 no-attach native C ABI。验证沿用上游 probe 矩阵，并通过 `cjpm build --skip-script` 证明新 owner 可被主包编译：

- `runtime/cjgui/native/scripts/verify_native_bridge_nsview_runtime_call.sh`
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

- no production native bridge edit。
- no `runtime/cjgui/cjpm.toml` mutation。
- no smoke native edits。
- no public API / diagnostics。
- no QuartzCore / Metal import in this stage。
- no `CAMetalLayer` / `CALayer` creation。
- no `NSView.layer` attachment。
- no `wantsLayer` mutation。
- no `MTLDevice` / `MTLCommandQueue`。
- no drawable / command buffer / GPU submission。
- no renderer state write。
- no `runtime_state.cj` touch。
- no backend-ready truth。
- no render permission。

## 文档链

- [preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-cametallayer-attachment-planning-preflight-decision.md)
- [closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-internal-renderer-cametallayer-attachment-planning-stage-closure-review.md)
- [next-boundary](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-cametallayer-attachment-planning-next-boundary-decision.md)
- [manifest closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-internal-renderer-cametallayer-attachment-planning-manifest-stabilization-closure-review.md)

## 下游接续

- [CAMetalLayer no-attach class/runtime FFI call owner manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-cametallayer-no-attach-class-runtime-ffi-call-owner-manifest.md)
- [CAMetalLayer no-attach class/runtime FFI call owner closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-internal-renderer-cametallayer-no-attach-class-runtime-ffi-call-owner-stage-closure-review.md)

## 后续入口

唯一后续入口：

`P1 internal Renderer CAMetalLayer no-attach class/runtime FFI call owner preflight decision`

## 设计意图出口自检

- 本轮是否改变主题状态：是，`CAMetalLayer` attachment planning no-attach value owner 已 manifest stabilization。
- 本轮是否改变 canonical tail / endpoint：是，固定 `CjguiInternalRendererNoCAMetalLayerAttachmentReadiness` / `cjguiInternalExecuteDefaultRendererCAMetalLayerAttachmentDraft()`。
- 本轮是否改变 owner / truth / stop-line：是，owner 固定为 `runtime_renderer_cametallayer_attachment_planning.cj`；truth 固定为 no-attach planning facts；stop-line 固定为 no native C ABI / no QuartzCore import / no layer creation / no attachment / no Metal / no state write / no public。
- 本轮是否改变唯一 next opening：是，转为 `P1 internal Renderer CAMetalLayer no-attach class/runtime FFI call owner preflight decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。

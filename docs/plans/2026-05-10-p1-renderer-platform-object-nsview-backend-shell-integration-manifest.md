# P1 渲染器 platform object NSView backend shell integration 清单

日期：2026-05-10

状态：manifest stabilization / value owner

## 清单结论

`NSView` backend shell integration value owner 已封账。Actual route 是 internal runtime owner：把上游 `NSView` runtime-call evidence 接入 renderer backend shell planning facts，同时明确 no renderer state write、no Metal layer binding、no backend-ready truth。

该清单不新增 native C ABI，不修改 production native bridge，不修改 `runtime/cjgui/cjpm.toml`，不新增 probe，不改变 public API。

## Runtime owner

- Owner：`runtime/cjgui/src/runtime_renderer_backend_nsview_platform_integration.cj`
- Endpoint：`CjguiInternalRendererNoBackendNsViewPlatformIntegrationReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererBackendNsViewPlatformIntegrationDraft()`
- Runtime input：`CjguiInternalRendererNoPlatformObjectNsViewRuntimeCallReadiness`

## 固定 facts

- `NSView` runtime call evidence accepted。
- backend shell platform candidate intent fixed。
- token locality preserved。
- no renderer-state-write proof fixed。
- no Metal layer binding proof fixed。
- no backend-ready truth proof fixed。
- teardown-before-backend-ready dependency fixed。
- main-thread backend platform admission guard fixed。
- invalid token / destroyed token / background thread / table unavailable failure classification fixed。
- no public surface and no diagnostics publication。

## 上游证据

- [NSView runtime FFI call owner manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-platform-object-nsview-runtime-ffi-call-owner-manifest.md)
- [NSView create/destroy manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-platform-object-token-backed-nsview-create-destroy-first-slice-manifest.md)
- [NSView object table manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-platform-object-token-backed-nsview-object-table-manifest.md)
- [real backend platform object shell manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-real-backend-platform-object-first-implementation-slice-manifest.md)
- [real backend readiness final shell manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-renderer-real-backend-readiness-final-shell-manifest.md)
- [backend readiness branch reconciliation scan](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-renderer-real-backend-readiness-shell-branch-reconciliation-scan.md)
- [teardown admission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-native-bridge-teardown-callable-implementation-manifest.md)

## Probe 与验证角色

本阶段不新增 probe。验证沿用上游 probe 矩阵，并额外通过 `cjpm build --skip-script` 证明新 owner 可被主包编译：

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

- no public API / diagnostics。
- no renderer state write。
- no `runtime_state.cj` touch。
- no native C ABI addition。
- no production native bridge edit。
- no `runtime/cjgui/cjpm.toml` mutation。
- no smoke native edits。
- no token / pointer / handle / `id` / `Class` public exposure。
- no module-level mutable token storage。
- no `CAMetalLayer` / `CALayer` / `MTLDevice` / `MTLCommandQueue`。
- no Metal / QuartzCore import。
- no backend-ready truth。
- no GPU submission / render execution。

## 文档链

- [preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-platform-object-nsview-backend-shell-integration-preflight-decision.md)
- [closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-internal-renderer-platform-object-nsview-backend-shell-integration-stage-closure-review.md)
- [next-boundary](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-platform-object-nsview-backend-shell-integration-next-boundary-decision.md)
- [manifest closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-internal-renderer-platform-object-nsview-backend-shell-integration-manifest-stabilization-closure-review.md)

## 后续入口

唯一后续入口：

`P1 internal Renderer CAMetalLayer attachment planning preflight decision`

## 下游 CAMetalLayer attachment planning 已完成

本 manifest 的后续入口已由 [CAMetalLayer attachment planning manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-cametallayer-attachment-planning-manifest.md) 接续。下游新增 [runtime_renderer_cametallayer_attachment_planning.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_cametallayer_attachment_planning.cj)，canonical endpoint 为 `CjguiInternalRendererNoCAMetalLayerAttachmentReadiness` / `cjguiInternalExecuteDefaultRendererCAMetalLayerAttachmentDraft()`。该 downstream 只消费本 manifest 固定的 `CjguiInternalRendererNoBackendNsViewPlatformIntegrationReadiness`，并固定 QuartzCore import admission policy、`CAMetalLayer` class availability observation policy、`NSView.layer` attachment still blocked、no layer creation、no Metal device binding 与 no drawable acquisition；它不新增 native C ABI，不 import QuartzCore / Metal，不创建或 attach layer，不写 renderer state，不发布 backend-ready truth。

## 设计意图出口自检

- 本轮是否改变主题状态：是，`NSView` backend shell integration value owner 已 manifest stabilization。
- 本轮是否改变 canonical tail / endpoint：是，固定 `CjguiInternalRendererNoBackendNsViewPlatformIntegrationReadiness` / `cjguiInternalExecuteDefaultRendererBackendNsViewPlatformIntegrationDraft()`。
- 本轮是否改变 owner / truth / stop-line：是，owner 固定为 `runtime_renderer_backend_nsview_platform_integration.cj`；truth 固定为 backend shell integration facts；stop-line 固定为 no public / no state write / no layer / no Metal / no backend-ready。
- 本轮是否改变唯一 next opening：是，转为 `P1 internal Renderer CAMetalLayer attachment planning preflight decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。

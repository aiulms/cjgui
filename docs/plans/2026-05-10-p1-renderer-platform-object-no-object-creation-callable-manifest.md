# P1 内部渲染器 platform object no-object creation callable 清单

日期：2026-05-10

状态：manifest stabilization / no-object callable first implementation

## 清单结论

platform object no-object creation callable stage 已封账，actual route 是 production no-object C ABI + runtime internal owner。Production native bridge 现在可以暴露 platform object creation entry 仍被阻断的 integer facts，但仍不创建任何 AppKit / QuartzCore / Metal object，不返回 `Class` / `id` / native pointer / handle，不实现 object table，不把 token 绑定到真实 native object。

该清单不批准 platform object creation，不批准 `NSView` / `NSWindow` allocation，不批准 AppKit object permission，不批准 native handle / raw pointer，不批准 Metal / QuartzCore，不批准 public API，不批准 renderer state write，不批准 backend-ready truth。

## Native callable list

- `cjgui_native_bridge_platform_object_create_no_object_admission(void)` -> `int32_t`
- `cjgui_native_bridge_platform_object_create_requires_main_thread(void)` -> `int32_t`
- `cjgui_native_bridge_platform_object_create_requires_token_contract(void)` -> `int32_t`
- `cjgui_native_bridge_platform_object_create_allocation_blocked(void)` -> `int32_t`

Return contract：

- `27`：no-object creation admission。
- `28`：creation requires main-thread gate。
- `29`：creation requires token contract。
- `-24`：allocation remains blocked。

## Runtime owner

- Owner：`runtime/cjgui/src/runtime_renderer_platform_object_no_object_creation_call.cj`
- Endpoint：`CjguiInternalRendererNoPlatformObjectNoObjectCreationCallReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererPlatformObjectNoObjectCreationCallDraft()`
- Runtime input：`CjguiInternalRendererNoPlatformObjectTokenBackedCreationReadiness`
- Actual route：internal no-object FFI call owner
- Observed facts：no-object admission、main-thread requirement、token contract requirement、allocation blocked、creation entry fail-closed、no `Class` / `id` / pointer / handle、no AppKit object allocation、no Metal / QuartzCore、no object table、no token binding、no public surface、no renderer state write、no backend-ready truth。

## Probe scripts

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

这些 scripts 只验证 no-object callable presence / link / call / classification，不修改 source，不修改 package config，不执行 native lifecycle。

## Actual write set

- `runtime/cjgui/native/cjgui_native_bridge.h`
- `runtime/cjgui/native/cjgui_native_bridge.m`
- `runtime/cjgui/src/runtime_renderer_platform_object_no_object_creation_call.cj`
- `runtime/cjgui/native/scripts/verify_native_bridge_platform_object_no_object_creation.sh`
- Native probe allowlist / package link / no-resource call scripts
- README / tracker / plans README / runtime README / design intent index / topic manifests
- 本阶段 preflight、closure、next-boundary、manifest 与 manifest closure

`runtime/cjgui/cjpm.toml` 未修改。Smoke native files 未修改。`runtime_state.cj` 未修改。

## 固定边界

- no `NSWindow` / `NSView` / `NSApplication` allocation。
- no `CALayer` / `CAMetalLayer` creation。
- no `MTLDevice` / `MTLCommandQueue` creation。
- no `alloc` / `init` / `new` object path。
- no Metal / QuartzCore import。
- no `Class` / `id` / native pointer / native handle return。
- no class object storage。
- no native object storage。
- no object table implementation。
- no token-to-resource binding。
- no raw pointer storage。
- no retain / release / destroy。
- no drawable / command buffer / `commit` / `present`。
- no GPU submission。
- no render execution。
- no renderer state write。
- no `runtime_state.cj` modification。
- no public API / diagnostics。
- no smoke native edits。
- no backend-ready truth。

## 文档链

- [preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-platform-object-no-object-creation-callable-preflight-decision.md)
- [closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-internal-renderer-platform-object-no-object-creation-callable-stage-closure-review.md)
- [next-boundary](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-platform-object-no-object-creation-callable-next-boundary-decision.md)
- [token-backed creation planning manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-platform-object-token-backed-creation-planning-manifest.md)
- [AppKit main-thread admission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-platform-object-appkit-main-thread-admission-manifest.md)
- [native token table issue/revoke manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-native-token-table-no-resource-issue-revoke-manifest.md)
- [teardown admission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-native-bridge-teardown-callable-implementation-manifest.md)

## 后续入口

唯一后续入口：

该入口已由 [real NSView allocation feasibility manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-platform-object-real-nsview-allocation-manifest.md)、[token-backed NSView object table manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-platform-object-token-backed-nsview-object-table-manifest.md) 与 [token-backed NSView create/destroy first slice manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-platform-object-token-backed-nsview-create-destroy-first-slice-manifest.md) 接续。当前唯一后续入口转为：

`P1 internal Renderer platform object NSView runtime FFI call owner preflight decision`

该入口必须重新做 docs-only preflight，明确是否可创建真实 `NSView`、是否必须有 object table / token binding / teardown destroy path、是否需要更强 main-thread confinement、是否仍能保持 no pointer / no public API / no renderer state stop-line。不得从本 manifest 直接进入 object allocation。

## 设计意图出口自检

- 本轮是否改变主题状态：是，platform object no-object creation callable 已 manifest stabilization。
- 本轮是否改变 canonical tail / endpoint：是，固定 `CjguiInternalRendererNoPlatformObjectNoObjectCreationCallReadiness` / `cjguiInternalExecuteDefaultRendererPlatformObjectNoObjectCreationCallDraft()`。
- 本轮是否改变 owner / truth / stop-line：是，owner 固定为 `runtime_renderer_platform_object_no_object_creation_call.cj`；truth 固定为 no-object creation fail-closed facts；stop-line 固定为 no AppKit object allocation / no Metal / no pointer / no public / no renderer state。
- 本轮是否改变唯一 next opening：是，当时转为 `P1 internal Renderer platform object real NSView allocation preflight decision`；当前已由 real `NSView` allocation feasibility stage 接续，唯一后续入口转为 `P1 internal Renderer platform object token-backed NSView object table preflight decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。

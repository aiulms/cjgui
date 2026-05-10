# P1 内部渲染器 platform object token-backed NSView object table 清单

日期：2026-05-10

状态：manifest stabilization / no-allocation table shell

## 清单结论

token-backed `NSView` object table stage 已封账，actual route 是 production no-allocation C ABI + runtime internal owner。Production native bridge 现在可以暴露一个极窄、固定容量、main-thread confined 的 `NSView` table shell，并用 opaque token 做 fail-closed classification，但不创建、不保存、不返回任何 AppKit object。

该清单不批准 `NSView` retention，不批准 platform object creation，不批准 resource object table，不批准 native pointer / handle / `id` / `Class` return，不批准 Metal / QuartzCore，不批准 public API，不批准 renderer state write，不批准 backend-ready truth。

## Native callable list

- `cjgui_native_bridge_nsview_table_capacity(void)` -> `uint32_t`
- `cjgui_native_bridge_nsview_table_enabled(void)` -> `uint32_t`
- `cjgui_native_bridge_nsview_table_empty(void)` -> `int32_t`
- `cjgui_native_bridge_nsview_table_token_classify(uint64_t token)` -> `int32_t`
- `cjgui_native_bridge_nsview_table_allocation_still_blocked(void)` -> `int32_t`
- `cjgui_native_bridge_nsview_table_destroy_still_blocked(void)` -> `int32_t`

Return contract：

- `4`：固定小容量。
- `1`：table shell enabled。
- `30`：table shell empty。
- `-30`：token 已由 opaque token table issue，但未绑定 `NSView`。
- `-31`：allocation still blocked。
- `-32`：destroy still blocked。

## Runtime owner

- Owner：`runtime/cjgui/src/runtime_renderer_platform_object_nsview_object_table.cj`
- Endpoint：`CjguiInternalRendererNoPlatformObjectNsViewObjectTableReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererPlatformObjectNsViewObjectTableDraft()`
- Runtime input：`CjguiInternalRendererNoPlatformObjectNsViewAllocationReadiness`
- Actual route：internal no-allocation table shell FFI owner。
- Observed facts：fixed capacity、enabled、empty、invalid token fail-closed、issued token not-bound、allocation blocked、destroy blocked、main-thread confinement policy、no `NSView` allocation / storage、no token-to-object binding、no pointer / handle / `id` / `Class`、no Metal / QuartzCore、no public surface、no renderer state write、no backend-ready truth。

## Probe scripts

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

这些 scripts 只验证 no-allocation callable presence / link / call / classification，不修改 source，不修改 package config，不执行 native lifecycle。

## Actual write set

- `runtime/cjgui/native/cjgui_native_bridge.h`
- `runtime/cjgui/native/cjgui_native_bridge.m`
- `runtime/cjgui/src/runtime_renderer_platform_object_nsview_object_table.cj`
- `runtime/cjgui/native/scripts/verify_native_bridge_nsview_object_table.sh`
- Native probe allowlist / package link / no-resource call scripts
- README / tracker / plans README / runtime README / design intent index / topic manifests
- 本阶段 preflight、closure、next-boundary、manifest 与 manifest closure

`runtime/cjgui/cjpm.toml` 未修改。Smoke native files 未修改。`runtime_state.cj` 未修改。

## 固定边界

- no production `NSView` allocation。
- no long-lived `NSView` storage。
- no `NSWindow` / `NSApplication` / `CALayer` / `CAMetalLayer`。
- no Metal / QuartzCore import。
- no native pointer / handle / `id` / `Class` return。
- no token binding to real native object。
- no object retention table。
- no real destroy / retain / release。
- no drawable / command buffer / `commit` / `present`。
- no GPU submission。
- no render execution。
- no renderer state write。
- no `runtime_state.cj` modification。
- no public API / diagnostics。
- no smoke native edits。
- no backend-ready truth。

## 文档链

- [preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-platform-object-token-backed-nsview-object-table-preflight-decision.md)
- [closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-internal-renderer-platform-object-token-backed-nsview-object-table-stage-closure-review.md)
- [next-boundary](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-platform-object-token-backed-nsview-object-table-next-boundary-decision.md)
- [real NSView allocation feasibility manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-platform-object-real-nsview-allocation-manifest.md)
- [no-object creation callable manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-platform-object-no-object-creation-callable-manifest.md)
- [token-backed creation planning manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-platform-object-token-backed-creation-planning-manifest.md)
- [AppKit main-thread admission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-platform-object-appkit-main-thread-admission-manifest.md)
- [teardown admission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-native-bridge-teardown-callable-implementation-manifest.md)
- [token issue/revoke manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-native-token-table-no-resource-issue-revoke-manifest.md)

## 后续入口

下游接续：

该入口已由 [token-backed NSView create/destroy first slice manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-platform-object-token-backed-nsview-create-destroy-first-slice-manifest.md) 和 [NSView runtime FFI call owner manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-platform-object-nsview-runtime-ffi-call-owner-manifest.md) 接续并封账。当前唯一后续入口转为：

`P1 internal Renderer platform object NSView renderer backend shell integration preflight decision`

该入口必须重新评估是否允许 production create / destroy probe、是否需要 true retention table、是否有充分 teardown / revoke-before-destroy / double-destroy 证据、是否仍保持 main-thread confinement 与 no pointer / no public / no renderer state stop-line。不得从本 manifest 直接进入 long-lived `NSView` retention。

## 设计意图出口自检

- 本轮是否改变主题状态：是，token-backed `NSView` object table 已 manifest stabilization。
- 本轮是否改变 canonical tail / endpoint：是，固定 `CjguiInternalRendererNoPlatformObjectNsViewObjectTableReadiness` / `cjguiInternalExecuteDefaultRendererPlatformObjectNsViewObjectTableDraft()`。
- 本轮是否改变 owner / truth / stop-line：是，owner 固定为 `runtime_renderer_platform_object_nsview_object_table.cj`；truth 固定为 no-allocation table shell facts；stop-line 固定为 no `NSView` allocation / storage / pointer / public / renderer state / backend-ready。
- 本轮是否改变唯一 next opening：是，转为 `P1 internal Renderer platform object token-backed NSView create/destroy first slice preflight decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。

# P1 内部渲染器 platform object 真实 NSView allocation 清单

日期：2026-05-10

状态：manifest stabilization / isolated feasibility + planning

## 清单结论

真实 `NSView` allocation feasibility stage 已封账，actual route 是 isolated feasibility probe + runtime planning owner。Probe 只在 temporary Objective-C executable 中主线程创建零尺寸 `NSView` 并由 autorelease pool 清理；runtime owner 只固定 feasibility facts 与 production retention blocked facts。

该清单不批准 production `NSView` allocation callable，不批准保存 `NSView`，不批准 object table，不批准 pointer / handle / `id` / `Class` return，不批准 public API，不批准 renderer state write，不批准 backend-ready truth。

## Runtime owner

- Owner：`runtime/cjgui/src/runtime_renderer_platform_object_nsview_allocation_planning.cj`
- Endpoint：`CjguiInternalRendererNoPlatformObjectNsViewAllocationReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererPlatformObjectNsViewAllocationDraft()`
- Runtime input：`CjguiInternalRendererNoPlatformObjectNoObjectCreationCallReadiness`
- Actual route：planning value boundary + isolated feasibility evidence

## Probe

- Script：`runtime/cjgui/native/scripts/verify_native_bridge_nsview_allocation_feasibility.sh`
- Output：`/tmp/cjgui-native-bridge-nsview-allocation-feasibility-*`
- Probe route：isolated temporary Objective-C executable。
- Observed facts：main thread observed、`NSView` allocation observed、immediate cleanup observed、background-thread allocation denied、pointer returned false、native handle returned false、`NSView` saved false、window / application / layer created false、Metal / QuartzCore imported false。

## Production native 状态

- `runtime/cjgui/native/cjgui_native_bridge.h` 未新增 `NSView` allocation callable。
- `runtime/cjgui/native/cjgui_native_bridge.m` 未新增 `NSView` allocation implementation。
- `runtime/cjgui/cjpm.toml` 未修改。
- Smoke native files 未修改。
- Production bridge 仍只保留 no-object / fail-closed creation facts。

## 固定边界

- no production allocation C ABI。
- no long-lived `NSView`。
- no object table implementation。
- no token binding to native object。
- no native pointer / handle / `id` / `Class` return。
- no `NSWindow` / `NSApplication` / `CALayer` / `CAMetalLayer`。
- no Metal / QuartzCore。
- no retain / release / destroy in production bridge。
- no public API / diagnostics。
- no renderer state write。
- no backend-ready truth。

## 文档链

- [preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-platform-object-real-nsview-allocation-preflight-decision.md)
- [closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-internal-renderer-platform-object-real-nsview-allocation-feasibility-closure-review.md)
- [next-boundary](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-platform-object-real-nsview-allocation-next-boundary-decision.md)
- [no-object creation callable manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-platform-object-no-object-creation-callable-manifest.md)
- [token-backed creation planning manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-platform-object-token-backed-creation-planning-manifest.md)
- [AppKit main-thread admission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-platform-object-appkit-main-thread-admission-manifest.md)
- [teardown admission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-native-bridge-teardown-callable-implementation-manifest.md)
- [token issue/revoke manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-native-token-table-no-resource-issue-revoke-manifest.md)

## 后续入口

该入口已由 [token-backed NSView object table manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-platform-object-token-backed-nsview-object-table-manifest.md) 与 [token-backed NSView create/destroy first slice manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-platform-object-token-backed-nsview-create-destroy-first-slice-manifest.md) 接续。当前唯一后续入口转为：

`P1 internal Renderer platform object NSView runtime FFI call owner preflight decision`

该入口必须先评估 object table shell 是否足以支撑 create / destroy probe、token binding 是否仍禁止或如何 fail-closed、destroy / revoke ordering、double-destroy failure、main-thread confinement 与 pointer denial；不得直接返回 native pointer / handle / `id` / `Class`，不得直接写 renderer state 或 public API。

## 设计意图出口自检

- 本轮是否改变主题状态：是，真实 `NSView` allocation feasibility 已 manifest stabilization。
- 本轮是否改变 canonical tail / endpoint：是，固定 `CjguiInternalRendererNoPlatformObjectNsViewAllocationReadiness` / `cjguiInternalExecuteDefaultRendererPlatformObjectNsViewAllocationDraft()`。
- 本轮是否改变 owner / truth / stop-line：是，owner 固定为 `runtime_renderer_platform_object_nsview_allocation_planning.cj`；truth 固定为 isolated feasibility、main-thread gate、immediate cleanup 与 retention blocked facts；stop-line 固定为 no production allocation callable / no long-lived object / no pointer / no public / no renderer state。
- 本轮是否改变唯一 next opening：是，转为 `P1 internal Renderer platform object token-backed NSView object table preflight decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。

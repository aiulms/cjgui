# P1 内部渲染器 platform object 真实 NSView allocation 可行性收口复核

日期：2026-05-10

状态：closure review / feasibility route

## 收口结论

本轮按 preflight 选择 A 完成 isolated feasibility + planning owner。新增 isolated probe 验证主线程临时零尺寸 `NSView` allocation 可以在 autorelease pool 内完成并清理；新增 runtime planning owner 固定该证据只能作为 feasibility facts，不进入 production allocation callable，不保存对象，不返回 pointer / handle / `id` / `Class`。

该 closure 不批准 production `NSView` retention，不批准 object table，不批准 platform object creation permission，不批准 backend-ready truth。

## 实际写集

- `runtime/cjgui/native/scripts/verify_native_bridge_nsview_allocation_feasibility.sh`
- `runtime/cjgui/src/runtime_renderer_platform_object_nsview_allocation_planning.cj`
- 本阶段 preflight、closure、next-boundary、manifest、manifest closure
- README / tracker / plans README / runtime README / DESIGN_INTENT_INDEX / 三个 topic manifest
- 上游 no-object creation、token-backed creation、AppKit main-thread、teardown admission、token issue/revoke 相关文档 downstream 指向

未修改：

- `runtime/cjgui/native/cjgui_native_bridge.h`
- `runtime/cjgui/native/cjgui_native_bridge.m`
- `runtime/cjgui/cjpm.toml`
- smoke native files
- `runtime/cjgui/src/runtime_state.cj`

## Feasibility 事实

- isolated probe route：`verify_native_bridge_nsview_allocation_feasibility.sh`
- allocation 位置：temporary Objective-C executable，不在 production bridge。
- allocation 条件：主线程。
- cleanup：`@autoreleasepool` 作用域内清理。
- background thread：只验证 denied classification，不执行 allocation。
- `NSWindow` / `NSApplication` / `CALayer` / `CAMetalLayer`：未创建。
- Metal / QuartzCore：未导入。
- pointer / handle / `id` / `Class`：未返回、未保存。

## Runtime owner

- Owner：`runtime/cjgui/src/runtime_renderer_platform_object_nsview_allocation_planning.cj`
- Endpoint：`CjguiInternalRendererNoPlatformObjectNsViewAllocationReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererPlatformObjectNsViewAllocationDraft()`
- Runtime input：`CjguiInternalRendererNoPlatformObjectNoObjectCreationCallReadiness`
- Truth：`NSView` allocation feasibility intent、main-thread allocation gate、immediate-release probe policy、token-backed retention still blocked、object table still absent、destroy / revoke dependency still required、no production allocation callable、no long-lived `NSView` storage facts。

## 停止线

- no production allocation C ABI。
- no long-lived `NSView` storage。
- no token binding to native object。
- no object table implementation。
- no native pointer / handle / `id` / `Class` return。
- no `NSWindow` / `NSApplication` / `CALayer` / `CAMetalLayer`。
- no Metal / QuartzCore。
- no public API / diagnostics。
- no renderer state write。
- no backend-ready truth。

## 下游接续

本 closure 的下一段入口已由 [token-backed NSView object table manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-platform-object-token-backed-nsview-object-table-manifest.md) 接续。当前 downstream tail 是 `CjguiInternalRendererNoPlatformObjectNsViewObjectTableReadiness` / `cjguiInternalExecuteDefaultRendererPlatformObjectNsViewObjectTableDraft()`，唯一后续入口转为 `P1 internal Renderer platform object token-backed NSView create/destroy first slice preflight decision`。

## 设计意图出口自检

- 本轮是否改变主题状态：是，真实 `NSView` allocation 从 no-object creation callable 后续入口推进到 feasibility + planning closure。
- 本轮是否改变 canonical tail / endpoint：是，新增 `CjguiInternalRendererNoPlatformObjectNsViewAllocationReadiness` / `cjguiInternalExecuteDefaultRendererPlatformObjectNsViewAllocationDraft()`。
- 本轮是否改变 owner / truth / stop-line：是，owner 固定为 `runtime_renderer_platform_object_nsview_allocation_planning.cj`；truth 只限 isolated feasibility 与 production retention blocked facts；stop-line 继续禁止 object table、long-lived `NSView`、pointer return、public API 与 renderer state write。
- 本轮是否改变唯一 next opening：是，转为 `P1 internal Renderer platform object token-backed NSView object table preflight decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。

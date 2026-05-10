# P1 内部渲染器 platform object 真实 NSView allocation 预检结论

日期：2026-05-10

状态：preflight / feasibility-first

## 预检结论

本轮可以打开真实 `NSView` allocation 的 feasibility runway，但不能进入 production retention 或 production allocation callable first implementation。当前证据足以做 isolated probe：在主线程临时创建零尺寸 `NSView`，由 `@autoreleasepool` 清理，不返回 pointer，不保存对象，不创建 window / application / layer，不导入 Metal / QuartzCore。

本轮选择 A：isolated feasibility + planning owner。原因是 token-backed object table 仍不存在，production destroy / revoke-before-destroy 只停在 fail-closed admission callable，尚不能承载 long-lived `NSView` retention。若直接把 allocation callable 放进 production bridge，会把 feasibility 误读成 platform object permission。

## 问题回答

- 是否只做 isolated feasibility probe：是，本轮只允许 isolated temporary program allocation probe。
- 是否允许 production native 新增 allocation callable：否，本轮不新增 `cjgui_native_bridge_nsview_allocation_*` production C ABI。
- 如果 allocation callable 创建 `NSView`，对象是否立即释放：本轮没有 production allocation callable；isolated probe 里 `NSView` 只在 autorelease pool 内存在，并立即离开作用域清理。
- 是否已有 token-backed object table 能保存它：没有。当前只有 no-resource token issue / revoke mechanics，没有 native object table。
- destroy / revoke-before-destroy / double-destroy 失败分类是否足够：只足够做 fail-closed planning，不足以管理真实 `NSView` lifecycle。
- background thread 是否 fail-closed：是，probe 只在 main thread 分配；background thread 只验证 denied classification，不执行 allocation。
- 是否需要 autorelease pool：是，isolated probe 使用 `@autoreleasepool` 包住临时 `NSView`。
- 是否需要 `NSApplication`：不需要；若后续需要 `NSApplication` 才能稳定分配，必须停止到 blocker。
- 是否会触碰 `CALayer` / `CAMetalLayer` / Metal / QuartzCore：不会，本轮禁止 layer / Metal / QuartzCore。

## GitNexus 影响

对上游 endpoint / default draft 运行 impact：

- `CjguiInternalRendererNoPlatformObjectNoObjectCreationCallReadiness`：GitNexus 返回 not found / UNKNOWN，`impactedCount=0`。
- `cjguiInternalExecuteDefaultRendererPlatformObjectNoObjectCreationCallDraft`：GitNexus 返回 not found / UNKNOWN，`impactedCount=0`。

处理方式：按近期新增 owner 尚未索引记录，继续使用源码、`cjpm build`、probe 与 forbidden scan 兜底。未发现 HIGH / CRITICAL 风险。

## 准入路线

本轮允许新增：

- `runtime/cjgui/native/scripts/verify_native_bridge_nsview_allocation_feasibility.sh`
- `runtime/cjgui/src/runtime_renderer_platform_object_nsview_allocation_planning.cj`

本轮不允许：

- 修改 `runtime/cjgui/cjpm.toml`。
- 修改 smoke native files。
- 新增 production `NSView` allocation C ABI。
- 保存 `NSView`，返回 pointer / handle / `id` / `Class`。
- 创建 `NSWindow` / `NSApplication` / `CALayer` / `CAMetalLayer`。
- 导入 Metal / QuartzCore。
- 新增 public API / public diagnostics。
- 触碰 `runtime_state.cj`。

## 设计意图出口自检

- 本轮是否改变主题状态：是，打开真实 `NSView` allocation feasibility runway，但只批准 isolated feasibility + planning owner。
- 本轮是否改变 canonical tail / endpoint：预期改变为 `CjguiInternalRendererNoPlatformObjectNsViewAllocationReadiness` / `cjguiInternalExecuteDefaultRendererPlatformObjectNsViewAllocationDraft()`。
- 本轮是否改变 owner / truth / stop-line：预期新增 planning owner；truth 限于 isolated feasibility、main-thread gate、immediate cleanup、retention blocked、object table absent 与 destroy / revoke dependency facts；stop-line 继续禁止 production retention、pointer return、public API 与 renderer state write。
- 本轮是否改变唯一 next opening：预期转为 `P1 internal Renderer platform object token-backed NSView object table preflight decision`。
- 是否同步 topic manifest：预期同步。
- 已同步哪些 topic manifest：将在 closure / manifest 中同步 `renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。

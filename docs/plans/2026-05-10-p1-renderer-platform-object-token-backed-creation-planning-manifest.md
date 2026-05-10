# P1 内部渲染器 platform object token-backed creation planning 清单

日期：2026-05-10

状态：manifest stabilization / planning value boundary

## 清单结论

platform object token-backed creation planning stage 已封账，actual route 是 internal runtime planning value boundary。该阶段只定义 future AppKit platform object creation 的 token-backed identity 与 admission contract，不创建 native object，不新增 native platform object C ABI，不实现 object table，不把 token 绑定到真实 native object。

该清单不批准 platform object creation，不批准 AppKit object permission，不批准 native handle / raw pointer，不批准 public API，不批准 renderer state write，不批准 backend-ready truth。

## 固定对象

- Owner：`runtime/cjgui/src/runtime_renderer_platform_object_token_backed_creation.cj`
- Endpoint：`CjguiInternalRendererNoPlatformObjectTokenBackedCreationReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererPlatformObjectTokenBackedCreationDraft()`
- Runtime input：`CjguiInternalRendererNoPlatformObjectAppKitMainThreadAdmissionReadiness`
- Actual route：planning value boundary
- Native callable list：无新增

## 准入合同

- Future platform object creation 必须先通过 AppKit class availability 与 main-thread admission。
- Future identity 只能是 token-backed object identity，不得返回 pointer / handle / `Class` / `id`。
- Token issue-before-bind 当前必须 denial，避免无 object token 被误解成 resource token。
- Revoke-before-destroy requirement 必须保留，且不得被解释成 destroy implementation。
- Allocation still blocked proof 必须继续存在，直到下一阶段明确批准 no-object creation callable 或 object creation runway。

## 失败分类

本阶段固定 fail-closed classification policy：

- class-unavailable failure。
- background-thread failure。
- allocation-blocked failure。
- token-table-disabled failure。

这些分类只作为 internal facts，不输出 public diagnostics。

## 停止线

- no native platform object C ABI。
- no `NSWindow` / `NSView` / `NSApplication` / `CALayer` / `CAMetalLayer`。
- no `MTLDevice` / `MTLCommandQueue`。
- no Metal / QuartzCore import。
- no `Class` / `id` / pointer / handle return。
- no native object storage。
- no object table implementation。
- no token binding to real native object。
- no retain / release / destroy。
- no public API / diagnostics。
- no `runtime/cjgui/cjpm.toml` mutation。
- no smoke native edits。
- no `runtime_state.cj` modification。
- no renderer state write。
- no backend-ready truth。

## 文档链

- [preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-platform-object-token-backed-creation-planning-preflight-decision.md)
- [closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-internal-renderer-platform-object-token-backed-creation-planning-value-boundary-closure-review.md)
- [next-boundary](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-platform-object-token-backed-creation-planning-next-boundary-decision.md)
- [AppKit main-thread admission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-platform-object-appkit-main-thread-admission-manifest.md)
- [AppKit class availability manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-platform-object-appkit-class-availability-manifest.md)
- [AppKit import manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-platform-object-appkit-import-manifest.md)
- [native token table issue/revoke manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-native-token-table-no-resource-issue-revoke-manifest.md)
- [platform object native callable manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-platform-object-native-callable-manifest.md)
- [teardown admission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-native-bridge-teardown-callable-implementation-manifest.md)

## 后续入口

唯一后续入口：

该入口已由 [real NSView allocation feasibility manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-platform-object-real-nsview-allocation-manifest.md) 与 [token-backed NSView object table manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-platform-object-token-backed-nsview-object-table-manifest.md) 接续。当前唯一后续入口转为：

`P1 internal Renderer platform object token-backed NSView create/destroy first slice preflight decision`

该入口已由 no-object creation callable stage 接续并转入 real `NSView` allocation preflight。下一步只能先评估真实 `NSView` allocation 的前置条件；不得直接创建 `NSWindow` / `NSView` / `NSApplication` / `CALayer` / `CAMetalLayer`，不得返回 native pointer / handle / `Class` / `id`，不得新增 public API，不得写 renderer state，不得创建 backend-ready truth。

## 设计意图出口自检

- 本轮是否改变主题状态：是，token-backed object creation planning 已 manifest stabilization。
- 本轮是否改变 canonical tail / endpoint：是，固定 `CjguiInternalRendererNoPlatformObjectTokenBackedCreationReadiness` / `cjguiInternalExecuteDefaultRendererPlatformObjectTokenBackedCreationDraft()`。
- 本轮是否改变 owner / truth / stop-line：是，owner 固定为 `runtime_renderer_platform_object_token_backed_creation.cj`；truth 固定为 token-backed creation planning facts；stop-line 固定为 no object creation / no pointer / no public / no renderer state。
- 本轮是否改变唯一 next opening：是，当时转为 `P1 internal Renderer platform object no-object creation callable preflight decision`；当前已由 no-object creation callable manifest 与 real `NSView` allocation feasibility stage 接续，唯一后续入口转为 `P1 internal Renderer platform object token-backed NSView object table preflight decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。

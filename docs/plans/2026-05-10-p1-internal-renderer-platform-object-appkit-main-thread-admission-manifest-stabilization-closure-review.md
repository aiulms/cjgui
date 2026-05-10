# P1 内部渲染器 platform object AppKit main-thread admission 清单封账复核

日期：2026-05-10

状态：manifest stabilization closure / no-object main-thread admission

## 封账结论

AppKit main-thread admission stage 已完成 manifest stabilization。当前 canonical tail 固定为：

- Endpoint：`CjguiInternalRendererNoPlatformObjectAppKitMainThreadAdmissionReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererPlatformObjectAppKitMainThreadAdmissionDraft()`
- Owner：`runtime/cjgui/src/runtime_renderer_platform_object_appkit_main_thread_admission.cj`
- Runtime input：`CjguiInternalRendererNoPlatformObjectAppKitClassAvailabilityReadiness`

本阶段只证明 production bridge 可以在 no-object 范围观察 AppKit platform object main-thread admission facts，不证明 platform object exists，不批准 native object creation。

## 固定事实

- `cjgui_native_bridge_appkit_platform_object_main_thread_required` 返回 main-thread required fact。
- `cjgui_native_bridge_appkit_platform_object_main_thread_admitted` 返回 current-thread admitted / denied classification。
- `cjgui_native_bridge_appkit_platform_object_background_thread_denied` 返回 background-thread denied classification。
- `cjgui_native_bridge_appkit_platform_object_creation_still_blocked` 返回 creation still-blocked classification。
- Runtime owner 只把这些值脱水成 internal facts。
- `runtime/cjgui/cjpm.toml` 未修改。
- Smoke native files 未修改。
- `runtime_state.cj` 未修改。

## 停止线

- 不创建 `NSWindow` / `NSView` / `NSApplication`。
- 不创建 `CALayer` / `CAMetalLayer`。
- 不创建 `MTLDevice` / `MTLCommandQueue`。
- 不导入 Metal / QuartzCore。
- 不返回 `Class` / `id` / pointer / handle。
- 不保存 native object / class object。
- 不新增 public API / diagnostics。
- 不写 renderer state。
- 不声明 backend-ready truth。

## 封账验证

- AppKit import probe、AppKit class availability probe、AppKit main-thread admission probe、teardown admission probe、token issue/revoke probe、no-resource call probe、isolated FFI probe、package link probe、`cjpm` package link probe、skeleton compile、symbol probe 与 `cjpm` boundary 均通过。
- `cjpm build --target-dir /tmp/cjgui-renderer-platform-object-appkit-main-thread-admission-target --skip-script` 通过；仅保留既有 unused warning。
- `labs/macos_bridge_smoke/scripts/verify_auto_close.sh` 通过。
- `git diff --check`、Markdown absolute link missing target check、README / tracker / plans README / runtime README reachability、中文标题正文抽查、comment-aware public declaration scan、native forbidden scan 与 owner header / stop-line scan 通过。
- `runtime_state.cj` 行数仍为 `10065`，且 `runtime/cjgui/cjpm.toml`、smoke native files、`runtime_state.cj` 均无 diff。
- GitNexus upstream impact 对上游 endpoint / default draft 返回 not found / UNKNOWN、`impactedCount=0`，无 HIGH / CRITICAL；`detect-changes --scope unstaged --repo /Users/jiangxuanyang/Desktop/cangjie` 返回 `Risk level: low`、`Affected processes: 0`。

## 下游指向

本 closure 的原始唯一后续入口已被 downstream token-backed creation planning stage 接续：

`P1 internal Renderer platform object token-backed object creation planning preflight decision`

当前 canonical tail 以 [real NSView allocation feasibility manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-platform-object-real-nsview-allocation-manifest.md) 为准，唯一后续入口转为 `P1 internal Renderer platform object token-backed NSView object table preflight decision`。不得跳过 token-backed `NSView` object table preflight 直接保存 AppKit object。

## 设计意图出口自检

- 本轮是否改变主题状态：是，AppKit main-thread admission 从 implementation closure 进入 manifest stabilization closure。
- 本轮是否改变 canonical tail / endpoint：是，tail 固定为 `CjguiInternalRendererNoPlatformObjectAppKitMainThreadAdmissionReadiness` / `cjguiInternalExecuteDefaultRendererPlatformObjectAppKitMainThreadAdmissionDraft()`。
- 本轮是否改变 owner / truth / stop-line：是，owner 固定为 `runtime_renderer_platform_object_appkit_main_thread_admission.cj`；truth 固定为 no-object main-thread admission facts；stop-line 继续禁止 AppKit object、Metal / QuartzCore、`Class` / `id` / pointer / handle、public API、renderer state write 与 backend-ready truth。
- 本轮是否改变唯一 next opening：是，历史固定为 `P1 internal Renderer platform object token-backed object creation planning preflight decision`；当前已由 downstream manifest 与 real `NSView` allocation feasibility stage 接续为 `P1 internal Renderer platform object token-backed NSView object table preflight decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。

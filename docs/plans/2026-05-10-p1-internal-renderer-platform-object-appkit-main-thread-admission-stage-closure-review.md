# P1 内部渲染器 platform object AppKit main-thread admission 阶段复核

日期：2026-05-10

状态：implementation closure / no-object main-thread admission callable

## 实现结论

本轮按 preflight 选择 `P1 internal Renderer platform object no-object AppKit main-thread admission first implementation bundle`，完成 production native bridge 的 no-object AppKit main-thread admission first slice。新增 callable 只返回 `int32_t` classification facts，表达 future AppKit platform object creation 必须受 main-thread gate 约束，并且当前 platform object creation 仍 blocked。

本轮未创建 `NSWindow`、`NSView`、`NSApplication`、`CALayer`、`CAMetalLayer`、`MTLDevice` 或 `MTLCommandQueue`；未返回 `Class`、`id`、native pointer 或 native handle；未保存 native object 或 class object；未导入 Metal / QuartzCore；未新增 public API；未写 renderer state。

## 实际写集

- `runtime/cjgui/native/cjgui_native_bridge.h`
- `runtime/cjgui/native/cjgui_native_bridge.m`
- `runtime/cjgui/src/runtime_renderer_platform_object_appkit_main_thread_admission.cj`
- `runtime/cjgui/native/scripts/verify_native_bridge_appkit_main_thread_admission.sh`
- AppKit import、class availability、package link、temporary `cjpm` package link、symbol、skeleton、no-resource call 与 related probe allowlist scripts
- README、tracker、plans README、runtime README、设计意图索引、topic manifests
- 本阶段 preflight、closure、next-boundary、manifest 与 manifest closure 文档

`runtime/cjgui/cjpm.toml` 未修改，smoke native files 未修改，`runtime_state.cj` 未修改。

## 新增 callable

- `cjgui_native_bridge_appkit_platform_object_main_thread_required(void)`：返回 main-thread gate required fact。
- `cjgui_native_bridge_appkit_platform_object_main_thread_admitted(void)`：在当前主线程返回 admitted fact；非主线程返回 background denied fact。
- `cjgui_native_bridge_appkit_platform_object_background_thread_denied(void)`：返回 background-thread denied classification。
- `cjgui_native_bridge_appkit_platform_object_creation_still_blocked(void)`：返回 platform object creation still-blocked classification。

这些 callable 不返回 token、`Class`、`id`、native pointer 或 native handle，不创建或保存 native object。

## Runtime owner

- Owner：`runtime/cjgui/src/runtime_renderer_platform_object_appkit_main_thread_admission.cj`
- Runtime input：`CjguiInternalRendererNoPlatformObjectAppKitClassAvailabilityReadiness`
- Endpoint：`CjguiInternalRendererNoPlatformObjectAppKitMainThreadAdmissionReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererPlatformObjectAppKitMainThreadAdmissionDraft()`
- Truth：main-thread required observed、main-thread admitted observed、background-thread denied observed、platform object creation still blocked observed、main-thread gate required、no `Class` / `id` / pointer / handle return、no AppKit object allocation、no Metal / QuartzCore、no public surface、no renderer state write、no backend-ready truth。

该 owner 只在 internal-only 范围调用 no-object AppKit main-thread admission C ABI 并脱水 facts，不扩 runtime public surface。

## 验证记录

本阶段验证已执行并通过：

- `runtime/cjgui/native/scripts/verify_native_bridge_appkit_main_thread_admission.sh`
- `runtime/cjgui/native/scripts/verify_native_bridge_appkit_class_availability.sh`
- `runtime/cjgui/native/scripts/verify_native_bridge_appkit_import.sh`
- `runtime/cjgui/native/scripts/verify_native_bridge_no_resource_call_probe.sh`
- `runtime/cjgui/native/scripts/verify_native_bridge_package_link_probe.sh`
- `runtime/cjgui/native/scripts/verify_native_bridge_cjpm_package_link_probe.sh`
- `runtime/cjgui/native/scripts/verify_native_bridge_teardown_admission.sh`
- `runtime/cjgui/native/scripts/verify_native_bridge_token_issue_revoke.sh`
- `labs/native_bridge_ffi_probe/scripts/build_and_run.sh`
- `runtime/cjgui/native/scripts/verify_native_bridge_skeleton_compile.sh`
- `runtime/cjgui/native/scripts/verify_native_bridge_no_resource_symbols.sh`
- `runtime/cjgui/native/scripts/verify_native_bridge_cjpm_integration_boundary.sh`
- `cjpm build --target-dir /tmp/cjgui-renderer-platform-object-appkit-main-thread-admission-target --skip-script`
- `labs/macos_bridge_smoke/scripts/verify_auto_close.sh`
- `git diff --check`
- Markdown absolute link missing target check、README / tracker / plans README / runtime README reachability check、中文标题正文抽查、protected path scan、comment-aware public declaration scan、native forbidden scan、owner header / stop-line scan。

新增 probe 预期观测 `main_thread_required_observed=true`、`main_thread_admitted_observed=true`、`background_thread_denied_observed=true`、`platform_object_creation_still_blocked_observed=true`，同时确认 `appkit_object_allocated=false`、`class_pointer_returned=false`、`native_pointer_returned=false`、`metal_quartzcore_imported=false`、`public_api_modified=false`。

`cjpm build` 与 `cjpm` boundary 均通过；输出保留既有 unused warning，不是本阶段新增 blocker。`runtime_state.cj` 行数仍为 `10065`。Comment-aware public declaration scan 仍只发现 `cjguiExperimentalQueueSubmitShellReady(): Bool`。GitNexus `detect-changes --scope unstaged --repo /Users/jiangxuanyang/Desktop/cangjie` 返回 `Risk level: low`、`Affected processes: 0`；新增 owner / docs 仍以源码、build、probe 与 scan 兜底。

## 停止线复核

- no `NSWindow` / `NSView` / `NSApplication` allocation。
- no `CALayer` / `CAMetalLayer` creation。
- no `MTLDevice` / `MTLCommandQueue` creation。
- no Metal / QuartzCore import。
- no `Class` / `id` / native pointer / native handle return。
- no class object storage。
- no token-to-resource binding。
- no retain / release / destroy。
- no drawable / command buffer / `commit` / `present`。
- no GPU submission。
- no render execution。
- no renderer state write。
- no `runtime_state.cj` modification。
- no public API / diagnostics。
- no smoke native edits。
- no backend-ready truth。

## GitNexus 记录

编辑 runtime / native symbols 前已对 `CjguiInternalRendererNoPlatformObjectAppKitClassAvailabilityReadiness`、`cjguiInternalExecuteDefaultRendererPlatformObjectAppKitClassAvailabilityDraft` 与 `cjgui_native_bridge_surface_capabilities` 运行 upstream impact。GitNexus 返回 not found / UNKNOWN，`impactedCount=0`，未出现 HIGH / CRITICAL；本轮以源码、build、probe 与 forbidden scan 兜底。

## 设计意图出口自检

- 本轮是否改变主题状态：是，platform object AppKit class availability 后续入口进入 no-object main-thread admission implementation。
- 本轮是否改变 canonical tail / endpoint：是，新增 `CjguiInternalRendererNoPlatformObjectAppKitMainThreadAdmissionReadiness` / `cjguiInternalExecuteDefaultRendererPlatformObjectAppKitMainThreadAdmissionDraft()`。
- 本轮是否改变 owner / truth / stop-line：是，owner 固定为 `runtime_renderer_platform_object_appkit_main_thread_admission.cj`；truth 固定为 AppKit platform object main-thread gate 与 creation still-blocked facts；stop-line 继续禁止 AppKit object、Metal / QuartzCore、`Class` / `id` / pointer / handle、public API、renderer state write 与 backend-ready truth。
- 本轮是否改变唯一 next opening：是，closure 后进入 manifest stabilization，再转向 `P1 internal Renderer platform object token-backed object creation planning preflight decision`；当前已由 downstream token-backed creation planning、no-object creation callable 与 real `NSView` allocation feasibility stage 接续为 `P1 internal Renderer platform object token-backed NSView object table preflight decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。

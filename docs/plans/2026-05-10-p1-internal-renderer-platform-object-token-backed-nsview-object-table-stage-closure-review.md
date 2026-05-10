# P1 内部渲染器 platform object token-backed NSView object table 阶段收口复核

日期：2026-05-10

状态：closure review / B 路线完成

## 收口结论

本轮按 preflight 选择 B 完成 production `NSView` object table first slice，但不创建 `NSView`。实际落点是固定容量、main-thread confined、no-allocation 的 table shell / token classification callable 与 runtime internal owner。

该阶段只证明 production bridge 可以暴露 `NSView` object table shell 的整数事实：capacity、enabled、empty、token-not-bound、allocation still blocked 与 destroy still blocked。它不批准 long-lived `NSView` storage，不批准 token 绑定真实 AppKit object，不批准 native pointer / handle / `id` / `Class` return，不批准 backend-ready truth。

## 实际写集

- `runtime/cjgui/native/cjgui_native_bridge.h`
- `runtime/cjgui/native/cjgui_native_bridge.m`
- `runtime/cjgui/native/scripts/verify_native_bridge_nsview_object_table.sh`
- `runtime/cjgui/src/runtime_renderer_platform_object_nsview_object_table.cj`
- Native probe allowlist / symbol list / package link probe / no-resource call probe 维护
- 本阶段 preflight、closure、next-boundary、manifest、manifest closure
- README / tracker / plans README / runtime README / DESIGN_INTENT_INDEX / 三个 topic manifest
- NSView feasibility、no-object creation、token-backed creation、token issue/revoke 与 teardown admission 相关文档 downstream 指向

未修改：

- `runtime/cjgui/cjpm.toml`
- smoke native files
- `runtime/cjgui/src/runtime_state.cj`

## Native callable

- `cjgui_native_bridge_nsview_table_capacity(void)` -> `uint32_t`
- `cjgui_native_bridge_nsview_table_enabled(void)` -> `uint32_t`
- `cjgui_native_bridge_nsview_table_empty(void)` -> `int32_t`
- `cjgui_native_bridge_nsview_table_token_classify(uint64_t token)` -> `int32_t`
- `cjgui_native_bridge_nsview_table_allocation_still_blocked(void)` -> `int32_t`
- `cjgui_native_bridge_nsview_table_destroy_still_blocked(void)` -> `int32_t`

返回契约：

- `4`：固定小容量。
- `1`：table shell enabled。
- `30`：table shell 当前 empty。
- `-30`：opaque token 存在但未绑定 `NSView`。
- `-31`：`NSView` allocation 仍被阻断。
- `-32`：`NSView` destroy / retention path 仍被阻断。

## Runtime owner

- Owner：`runtime/cjgui/src/runtime_renderer_platform_object_nsview_object_table.cj`
- Endpoint：`CjguiInternalRendererNoPlatformObjectNsViewObjectTableReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererPlatformObjectNsViewObjectTableDraft()`
- Runtime input：`CjguiInternalRendererNoPlatformObjectNsViewAllocationReadiness`
- Truth：fixed-capacity table shell、enabled、empty、invalid token fail-closed、issued token not-bound、allocation blocked、destroy blocked、no `NSView` allocation / storage、no token-to-object binding、no pointer / handle / `id` / `Class` return、no Metal / QuartzCore、no public surface、no renderer state write。

## Probe 证据

- 新 probe：`runtime/cjgui/native/scripts/verify_native_bridge_nsview_object_table.sh`
- 输出目录：`/tmp/cjgui-native-bridge-nsview-object-table-*`
- 已观察：`table_capacity_observed=true`、`table_enabled_observed=true`、`table_empty_observed=true`、`invalid_token_fail_closed_observed=true`、`token_not_bound_observed=true`、`allocation_blocked_observed=true`、`destroy_blocked_observed=true`、`revoke_observed=true`。
- 已确认：`nsview_allocated=false`、`nsview_saved=false`、`pointer_returned=false`、`native_handle_returned=false`、`metal_quartzcore_imported=false`。
- 结果：`success=true reason=none`。

## 验证补账

- `NSView` feasibility、no-object creation、AppKit import、AppKit class availability、AppKit main-thread admission、teardown admission、token issue/revoke、no-resource call、isolated FFI、package link 与 `cjpm` package link probes 均通过。
- skeleton compile、symbol probe、`cjpm` boundary 与 `cjpm build --target-dir /tmp/cjgui-renderer-platform-object-nsview-object-table-target --skip-script` 均通过；既有 unused warnings 不构成失败。
- macOS smoke auto-close 通过；`git diff --check`、Markdown absolute link / reachability / 中文标题正文抽查、comment-aware public declaration scan、native forbidden scan、protected path scan 与 GitNexus `detect_changes` 均通过。

## 停止线

- no `NSView` allocation。
- no long-lived `NSView` storage。
- no token binding to native object。
- no native pointer / handle / `id` / `Class` return。
- no `NSWindow` / `NSApplication` / `CALayer` / `CAMetalLayer`。
- no Metal / QuartzCore。
- no real destroy / retain / release。
- no public API / diagnostics。
- no renderer state write。
- no backend-ready truth。

## 设计意图出口自检

- 本轮是否改变主题状态：是，token-backed `NSView` object table 从 preflight 推进到 no-allocation table shell first slice。
- 本轮是否改变 canonical tail / endpoint：是，新增并固定为 `CjguiInternalRendererNoPlatformObjectNsViewObjectTableReadiness` / `cjguiInternalExecuteDefaultRendererPlatformObjectNsViewObjectTableDraft()`。
- 本轮是否改变 owner / truth / stop-line：是，owner 固定为 `runtime_renderer_platform_object_nsview_object_table.cj`；truth 只限 table shell / no-allocation / fail-closed facts；stop-line 继续禁止 long-lived `NSView`、pointer / handle / `id` / `Class`、Metal / QuartzCore、public API、renderer state write 与 backend-ready truth。
- 本轮是否改变唯一 next opening：是，转为 `P1 internal Renderer platform object token-backed NSView create/destroy first slice preflight decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。
